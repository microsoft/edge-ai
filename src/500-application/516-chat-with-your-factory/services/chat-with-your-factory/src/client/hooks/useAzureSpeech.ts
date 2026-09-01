import { useState, useRef, useEffect, useCallback } from 'react'
import type { UseSpeechRecognitionResult } from './useSpeechRecognition.js'
import { apiFetch } from '../utils/apiFetch.js'
import {
  SpeechConfig,
  AudioConfig,
  SpeechRecognizer,
  ResultReason,
  CancellationReason,
} from 'microsoft-cognitiveservices-speech-sdk'

interface UseAzureSpeechOptions {
  onFinalResult: (text: string) => void
}

async function fetchSpeechToken(): Promise<{ token: string; region: string }> {
  const res = await apiFetch('/api/speech-token')
  if (!res.ok) throw new Error('Failed to fetch speech token')
  return res.json()
}

export function useAzureSpeech(options: UseAzureSpeechOptions): UseSpeechRecognitionResult {
  const [isListening, setIsListening] = useState(false)
  const [transcript, setTranscript] = useState('')
  const [error, setError] = useState<string | null>(null)
  const recognizerRef = useRef<SpeechRecognizer | null>(null)
  const isListeningRef = useRef(false)
  const isStartingRef = useRef(false)
  const onFinalResultRef = useRef(options.onFinalResult)
  onFinalResultRef.current = options.onFinalResult

  // Token refresh interval ref
  const refreshTimerRef = useRef<ReturnType<typeof setInterval> | null>(null)

  useEffect(() => {
    return () => {
      if (refreshTimerRef.current) {
        clearInterval(refreshTimerRef.current)
      }
      recognizerRef.current?.close()
    }
  }, [])

  const startListening = useCallback(async () => {
    if (isListeningRef.current || isStartingRef.current) return
    setError(null)
    isStartingRef.current = true

    // Request mic permission explicitly — needed in iframes (Teams tabs)
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      stream.getTracks().forEach(t => t.stop())
    } catch {
      setError('Microphone access denied. Check browser permissions.')
      isStartingRef.current = false
      return
    }

    if (!isStartingRef.current) return

    let token: string
    let region: string
    try {
      const resp = await fetchSpeechToken()
      token = resp.token
      region = resp.region
    } catch {
      setError('Failed to get speech token from server.')
      isStartingRef.current = false
      return
    }

    if (!isStartingRef.current) return

    const speechConfig = SpeechConfig.fromAuthorizationToken(token, region)
    speechConfig.speechRecognitionLanguage = 'en-US'

    const audioConfig = AudioConfig.fromDefaultMicrophoneInput()
    const recognizer = new SpeechRecognizer(speechConfig, audioConfig)

    recognizer.recognizing = (_sender, event) => {
      if (event.result.text) {
        setTranscript(event.result.text)
      }
    }

    recognizer.recognized = (_sender, event) => {
      if (event.result.reason === ResultReason.RecognizedSpeech) {
        const finalText = event.result.text?.trim()
        if (finalText) {
          onFinalResultRef.current(finalText)
        }
        setTranscript('')
      }
    }

    recognizer.canceled = (_sender, event) => {
      if (event.reason === CancellationReason.Error) {
        console.error('[AzureSpeech] Error:', event.errorDetails)
        setError(`Speech error: ${event.errorDetails}`)
        isListeningRef.current = false
        setIsListening(false)
        setTranscript('')
      }
    }

    recognizer.sessionStopped = () => {
      if (isListeningRef.current) {
        // Unexpected stop — try restarting
        recognizer.startContinuousRecognitionAsync()
      }
    }

    recognizerRef.current = recognizer
    isListeningRef.current = true
    isStartingRef.current = false
    setIsListening(true)
    setTranscript('')

    recognizer.startContinuousRecognitionAsync(
      () => {
        console.log('[AzureSpeech] Recognition started')
      },
      (err) => {
        console.error('[AzureSpeech] Start failed:', err)
        setError('Failed to start speech recognition.')
        isListeningRef.current = false
        isStartingRef.current = false
        setIsListening(false)
      },
    )

    // Refresh token every 9 minutes (tokens last 10 min)
    refreshTimerRef.current = setInterval(async () => {
      try {
        const resp = await fetchSpeechToken()
        if (recognizerRef.current) {
          recognizerRef.current.authorizationToken = resp.token
        }
      } catch {
        console.warn('[AzureSpeech] Token refresh failed')
      }
    }, 9 * 60 * 1000)
  }, [])

  const stopListening = useCallback(() => {
    isListeningRef.current = false
    isStartingRef.current = false
    setIsListening(false)
    setTranscript('')
    if (refreshTimerRef.current) {
      clearInterval(refreshTimerRef.current)
    }
    refreshTimerRef.current = null

    const recognizer = recognizerRef.current
    if (recognizer) {
      recognizer.stopContinuousRecognitionAsync(
        () => recognizer.close(),
        () => recognizer.close(),
      )
      recognizerRef.current = null
    }
  }, [])

  const toggleListening = useCallback(() => {
    if (isListeningRef.current || isStartingRef.current) {
      stopListening()
    } else {
      startListening()
    }
  }, [startListening, stopListening])

  return { isListening, isSupported: true, transcript, error, startListening, stopListening, toggleListening }
}
