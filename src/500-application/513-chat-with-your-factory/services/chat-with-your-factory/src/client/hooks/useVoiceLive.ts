import { useState, useRef, useCallback, useEffect } from 'react'
import type { UseSpeechRecognitionResult } from './useSpeechRecognition.js'

/**
 * Browser-side debug gate. Audio device labels and IDs are PII-adjacent
 * (machine fingerprinting, externally-facing in shared/casted browser
 * sessions), so we don't log them in production. Devs can flip the gate
 * at runtime in DevTools without a rebuild:
 *
 *   localStorage.setItem('voicelive:debug', 'true')
 *
 * Wrapped in try/catch so a hardened storage policy (private mode,
 * site-data blocked) can't break the hook.
 */
function debugEnabled(): boolean {
  try {
    return typeof localStorage !== 'undefined' &&
      localStorage.getItem('voicelive:debug') === 'true'
  } catch {
    return false
  }
}

interface UseVoiceLiveOptions {
  onFinalResult: (text: string) => void
  sessionId?: string | null
  onEnsureSession?: () => Promise<string | null>
  onDispatch?: (turnId: string) => void
  /** Called when the bridge reports a server-side dispatch failure so the
   *  caller can release its pending-dispatch counter / loading spinner. */
  onDispatchError?: (turnId: string, message: string) => void
}

/**
 * Voice Live hook — connects to the server bridge at `/api/voice-live` via WebSocket,
 * captures mic audio as 24 kHz mono PCM16 via AudioWorklet, and proxies frames
 * to the bridge for STT/VAD. Transcripts and agent responses arrive via SSE.
 *
 * Matches `UseSpeechRecognitionResult` for drop-in use with `VoiceInput.tsx`.
 */
export function useVoiceLive(options: UseVoiceLiveOptions): UseSpeechRecognitionResult {
  const [isListening, setIsListening] = useState(false)
  const [transcript, setTranscript] = useState('')
  const [error, setError] = useState<string | null>(null)

  const wsRef = useRef<WebSocket | null>(null)
  const audioCtxRef = useRef<AudioContext | null>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const workletRef = useRef<AudioWorkletNode | null>(null)
  const onFinalResultRef = useRef(options.onFinalResult)
  onFinalResultRef.current = options.onFinalResult

  const onEnsureSessionRef = useRef(options.onEnsureSession)
  onEnsureSessionRef.current = options.onEnsureSession

  const onDispatchRef = useRef(options.onDispatch)
  onDispatchRef.current = options.onDispatch

  const onDispatchErrorRef = useRef(options.onDispatchError)
  onDispatchErrorRef.current = options.onDispatchError

  const isSupported =
    typeof WebSocket !== 'undefined' &&
    typeof AudioWorkletNode !== 'undefined'

  const cleanup = useCallback(() => {
    workletRef.current?.disconnect()
    workletRef.current = null
    streamRef.current?.getTracks().forEach(t => t.stop())
    streamRef.current = null
    if (audioCtxRef.current?.state !== 'closed') {
      audioCtxRef.current?.close().catch(() => {})
    }
    audioCtxRef.current = null
    if (wsRef.current?.readyState === WebSocket.OPEN || wsRef.current?.readyState === WebSocket.CONNECTING) {
      wsRef.current.close()
    }
    wsRef.current = null
  }, [])

  // Cleanup on unmount
  useEffect(() => cleanup, [cleanup])

  // Tear down when session changes while listening.
  // Reconnect is user-driven via the mic toggle.
  const prevSessionIdRef = useRef(options.sessionId)
  useEffect(() => {
    if (prevSessionIdRef.current !== options.sessionId) {
      prevSessionIdRef.current = options.sessionId
      if (isListening) {
        // Session changed — stop current voice connection and clear local transcript.
        cleanup()
        setIsListening(false)
        setTranscript('')
      }
    }
  }, [options.sessionId]) // eslint-disable-line react-hooks/exhaustive-deps

  // Keep a ref that startListening can read without stale closures
  const sessionIdRef = useRef(options.sessionId)
  sessionIdRef.current = options.sessionId

  const startListening = useCallback(async () => {
    if (isListening) return
    setError(null)
    setTranscript('')

    try {
      // 1. Acquire mic — use a specific device if available to avoid
      // virtual audio devices that may mix in system/comms audio
      const devices = await navigator.mediaDevices.enumerateDevices()
      const audioInputs = devices.filter(d => d.kind === 'audioinput')
      if (debugEnabled()) {
        console.log('[VoiceLive] Audio input devices:', audioInputs.map(d => `${d.label} (${d.deviceId.slice(0, 8)})`))
      }

      // Prefer a non-default, non-communications device if one exists
      const preferred = audioInputs.find(d =>
        !d.label.toLowerCase().includes('virtual') &&
        !d.label.toLowerCase().includes('stereo mix') &&
        d.deviceId !== 'default' &&
        d.deviceId !== 'communications'
      )

      const audioConstraints: MediaTrackConstraints = {
        channelCount: 1,
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
      }
      if (preferred) {
        audioConstraints.deviceId = { exact: preferred.deviceId }
        if (debugEnabled()) {
          console.log(`[VoiceLive] Using mic: ${preferred.label}`)
        }
      }

      const stream = await navigator.mediaDevices.getUserMedia({ audio: audioConstraints })
      streamRef.current = stream

      // 2. Create AudioContext at system default sample rate
      const audioCtx = new AudioContext()
      audioCtxRef.current = audioCtx

      // Resume from user gesture (required for autoplay in Teams iframe)
      if (audioCtx.state === 'suspended') await audioCtx.resume()

      // 3. Load worklet and connect immediately
      await audioCtx.audioWorklet.addModule('/voice-live-worklet.js')
      const source = audioCtx.createMediaStreamSource(stream)
      const worklet = new AudioWorkletNode(audioCtx, 'voice-live-processor')
      workletRef.current = worklet
      source.connect(worklet)
      // Don't connect worklet output to destination — mic audio shouldn't echo

      // 4. Get active session ID — auto-create if needed
      let sessionId = sessionIdRef.current
      if (!sessionId && onEnsureSessionRef.current) {
        sessionId = await onEnsureSessionRef.current()
        if (sessionId) sessionIdRef.current = sessionId
      }
      if (!sessionId) {
        setError('No active session')
        cleanup()
        return
      }

      // 5. Mint a single-use ticket for the WebSocket upgrade. Avoids passing
      //    the SSO bearer token in the WS URL query string (which would be
      //    captured by access logs, proxies, and browser history).
      const { apiFetch } = await import('../utils/apiFetch.js')
      const ticketRes = await apiFetch('/api/voice-live/ticket', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ sessionId }),
      })
      if (!ticketRes.ok) {
        // Surface the server's specific reason (e.g. SKIP_AUTH +
        // copilotstudio backend) rather than a generic message. Falls
        // back to a generic message if the body isn't JSON.
        let reason = 'Failed to authorize voice session'
        try {
          const body = await ticketRes.json() as { error?: string }
          if (body?.error) reason = body.error
        } catch {
          // Non-JSON body — keep generic reason
        }
        setError(reason)
        cleanup()
        return
      }
      const { ticket } = (await ticketRes.json()) as { ticket: string }

      // 6. Open WebSocket to bridge
      const wsProtocol = location.protocol === 'https:' ? 'wss:' : 'ws:'
      const wsUrl = `${wsProtocol}//${location.host}/api/voice-live` +
        `?sessionId=${encodeURIComponent(sessionId)}` +
        `&ticket=${encodeURIComponent(ticket)}`

      const ws = new WebSocket(wsUrl)
      wsRef.current = ws
      let workletConnected = false

      ws.binaryType = 'arraybuffer'

      ws.onopen = () => {
        // Show connecting state — not fully listening until session.ready
        setTranscript('Connecting...')
      }

      // Only start sending audio after upstream is ready (bridge sends session.ready)
      ws.onmessage = (ev) => {
        try {
          const event = JSON.parse(ev.data as string)

          if (event.type === 'session.ready' && !workletConnected) {
            workletConnected = true
            setIsListening(true)
            setTranscript('')
            worklet.port.onmessage = (audioEv: MessageEvent<ArrayBuffer>) => {
              if (ws.readyState === WebSocket.OPEN) {
                ws.send(audioEv.data)
              }
            }
            return
          }

          if (event.type === 'dispatching') {
            const turnId = (event as { turnId?: string }).turnId
            if (turnId) onDispatchRef.current?.(turnId)
            return
          }

          if (event.type === 'dispatch.failed') {
            const message = (event as { error?: string }).error ?? 'Voice dispatch failed'
            const turnId = (event as { turnId?: string }).turnId
            setError(message)
            if (turnId) onDispatchErrorRef.current?.(turnId, message)
            return
          }

          handleVoiceLiveEvent(event)
        } catch {
          // Non-JSON frame — ignore
        }
      }

      ws.onerror = () => {
        // Ensure mic + AudioContext are torn down on connection failure;
        // otherwise the browser keeps the mic indicator on indefinitely.
        setError('Voice connection error')
        setIsListening(false)
        setTranscript('')
        cleanup()
      }

      ws.onclose = (ev) => {
        // Always release mic + AudioContext on close. Without this, a server
        // rejection on upgrade (401/403) or upstream failure (1011) leaves
        // the mic stream and AudioContext alive even though isListening
        // becomes false — the mic stays "stuck on" until full page refresh.
        setIsListening(false)
        setTranscript('')
        // Surface a user-visible error for abnormal close codes. 1000 (normal)
        // and 1005 (no status) happen on intentional stop/teardown and should
        // stay silent.
        if (ev.code !== 1000 && ev.code !== 1005) {
          const reason = ev.reason || (
            ev.code === 1008 ? 'Voice session not authorized' :
            ev.code === 1011 ? 'Voice service unavailable' :
            `Voice connection closed (${ev.code})`
          )
          setError(reason)
        }
        cleanup()
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to start voice'
      setError(message)
      cleanup()
    }
  }, [isListening, cleanup])

  const stopListening = useCallback(() => {
    cleanup()
    setIsListening(false)
    setTranscript('')
  }, [cleanup])

  const toggleListening = useCallback(() => {
    if (isListening) {
      stopListening()
    } else {
      startListening()
    }
  }, [isListening, startListening, stopListening])

  function handleVoiceLiveEvent(event: { type?: string; transcript?: string; delta?: string }) {
    switch (event.type) {
      case 'conversation.item.input_audio_transcription.delta':
        if (event.delta) setTranscript(prev => prev + event.delta)
        break

      case 'conversation.item.input_audio_transcription.completed':
        setTranscript('')
        if (event.transcript) onFinalResultRef.current(event.transcript)
        break

      case 'error':
        setError((event as { error?: { message?: string } }).error?.message ?? 'Voice Live error')
        break
    }
  }

  return { isListening, isSupported, transcript, error, startListening, stopListening, toggleListening }
}
