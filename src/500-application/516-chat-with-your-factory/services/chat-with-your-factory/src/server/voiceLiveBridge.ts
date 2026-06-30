import type { Server, IncomingMessage } from 'http'
import type { Duplex } from 'stream'
import { WebSocketServer, WebSocket } from 'ws'
import { DefaultAzureCredential } from '@azure/identity'
import { getAuthorizedSessionFor } from './aclHelper.js'
import { dispatchChat } from './chatHandler.js'
import { sessionStore } from './sessionStore.js'
import { sseRegistry } from './sseRegistry.js'
import { consumeTicket } from './wsTicketStore.js'

const VOICELIVE_RESOURCE = process.env.AZURE_VOICELIVE_RESOURCE ?? ''
const VOICELIVE_MODEL = process.env.AZURE_VOICELIVE_MODEL ?? 'gpt-realtime'
const VOICELIVE_API_VERSION = process.env.AZURE_VOICELIVE_API_VERSION ?? '2025-10-01'
const UTTERANCE_SILENCE_MS = 2000
// When true, log raw transcript content to server logs. Off by default so
// production logs don't capture sensitive user speech in plaintext.
const VOICELIVE_DEBUG = process.env.VOICELIVE_DEBUG === 'true'

const credential = new DefaultAzureCredential()

/**
 * session.update — pure STT/VAD engine, no model responses.
 * User transcripts are accumulated and dispatched as a single turn
 * after a silence window, enabling natural speech corrections.
 */
function buildSessionUpdate() {
  return {
    type: 'session.update',
    session: {
      modalities: ['text'],
      input_audio_format: 'pcm16',
      input_audio_transcription: { model: 'azure-speech', language: 'en' },
      input_audio_noise_reduction: { type: 'azure_deep_noise_suppression' },
      turn_detection: { type: 'azure_semantic_vad', create_response: false },
    },
  }
}

/**
 * Attach the Voice Live WebSocket bridge to an existing HTTP server.
 * Only active when VOICE_PROVIDER=voicelive and AZURE_VOICELIVE_RESOURCE is set.
 */
export function attachVoiceLiveBridge(httpServer: Server): WebSocketServer {
  const wss = new WebSocketServer({ noServer: true })

  // NOTE: this listener is intentionally NOT async. The 'upgrade' event is
  // emitted by an EventEmitter, which doesn't await listener promises — any
  // unhandled rejection bubbles up to the process. The body below is fully
  // synchronous (consumeTicket / getAuthorizedSessionFor are sync;
  // wss.handleUpgrade is sync). Any throw is caught and turned into a
  // 400 + socket close so a malformed Host header / unparsable URL can't
  // take the server down.
  httpServer.on('upgrade', (req: IncomingMessage, socket: Duplex, head: Buffer) => {
    try {
      // Use a safe fallback host so a missing/garbled Host header doesn't
      // throw inside `new URL(...)`. The host portion is only used to
      // satisfy the WHATWG URL parser; we never read url.host downstream.
      const host = req.headers.host || 'localhost'
      const url = new URL(req.url ?? '', `http://${host}`)
      if (url.pathname !== '/api/voice-live') {
        // No other upgrade handlers are registered on this server, so an
        // upgrade request to any other path will hang the client socket
        // until it times out. Explicitly reject with a 404 + close so probes
        // and misrouted clients fail fast and don't accumulate sockets.
        socket.write('HTTP/1.1 404 Not Found\r\nConnection: close\r\n\r\n')
        socket.destroy()
        return
      }

      const sessionId = url.searchParams.get('sessionId')
      // Authenticate via single-use ticket minted by POST /api/voice-live/ticket.
      // We deliberately do NOT accept a raw SSO bearer token in the URL because
      // query strings are routinely captured by access logs, proxies, and
      // browser history.
      const ticketId = url.searchParams.get('ticket') ?? ''

      if (!sessionId) {
        socket.write('HTTP/1.1 400 Bad Request\r\n\r\n')
        socket.destroy()
        return
      }

      const ticket = consumeTicket(ticketId, sessionId)
      if (!ticket) {
        socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n')
        socket.destroy()
        return
      }

      const session = getAuthorizedSessionFor(sessionId, ticket.userId)
      if (!session) {
        socket.write('HTTP/1.1 403 Forbidden\r\n\r\n')
        socket.destroy()
        return
      }

      wss.handleUpgrade(req, socket, head, (clientWs) => {
        wss.emit('connection', clientWs, req)
        void handleConnection(clientWs, sessionId, ticket.userId, ticket.displayName, ticket.ssoToken)
          .catch((err) => {
            console.error('[VoiceLive] Unhandled connection error:', err)
            if (clientWs.readyState === WebSocket.OPEN) {
              clientWs.close(1011, 'Connection setup failed')
            }
          })
      })
    } catch (err) {
      console.error('[VoiceLive] Upgrade handler error:', err)
      try {
        socket.write('HTTP/1.1 400 Bad Request\r\nConnection: close\r\n\r\n')
      } catch {
        // Socket may already be in a bad state; fall through to destroy.
      }
      socket.destroy()
    }
  })

  return wss
}

async function handleConnection(
  clientWs: WebSocket,
  sessionId: string,
  userId: string,
  displayName: string,
  ssoToken: string,
) {
  let upstreamWs: WebSocket | null = null

  // Accumulate transcripts and dispatch after a silence window.
  // Each transcript shows immediately in the chat, but the batch
  // is sent as one turn to Copilot Studio so corrections are coherent.
  const pendingUtterances: string[] = []
  let dispatchTimer: ReturnType<typeof setTimeout> | null = null

  function scheduleDispatch() {
    if (dispatchTimer) clearTimeout(dispatchTimer)
    dispatchTimer = setTimeout(() => {
      void (async () => {
        dispatchTimer = null
        if (pendingUtterances.length === 0) return
        const fullText = pendingUtterances.join(' ')
        const utteranceCount = pendingUtterances.length
        pendingUtterances.length = 0
        // Per-dispatch correlation ID. The client tracks outstanding turnIds
        // and only clears its spinner when the assistant reply for one of
        // its own dispatches arrives — preventing co-participants' replies
        // from prematurely clearing the local pending counter.
        const turnId = crypto.randomUUID()
        if (VOICELIVE_DEBUG) {
          console.log(`[VoiceLive] Dispatching session=${sessionId} turn=${turnId}: ${fullText}`)
        } else {
          console.log(`[VoiceLive] Dispatching session=${sessionId} turn=${turnId} utterances=${utteranceCount} chars=${fullText.length}`)
        }
        // Notify client that a dispatch is in flight
        if (clientWs.readyState === WebSocket.OPEN) {
          try {
            clientWs.send(JSON.stringify({ type: 'dispatching', turnId }))
          } catch (sendErr) {
            console.warn('[VoiceLive] Failed to send dispatching event:', sendErr)
          }
        }
        try {
          await dispatchChat(sessionId, fullText, {
            userId,
            displayName,
            ssoToken,
            source: 'voice',
            skipUserMessage: true,
            turnId,
          })
        } catch (err) {
          console.error('[VoiceLive] dispatchChat error:', err)
          // Tell the client the dispatch failed so it can clear its pending
          // counter / spinner. Without this, the UI stays stuck in a loading
          // state because it normally clears the counter on the assistant SSE
          // event that will never arrive.
          if (clientWs.readyState === WebSocket.OPEN) {
            const message = err instanceof Error ? err.message : 'Dispatch failed'
            try {
              clientWs.send(JSON.stringify({ type: 'dispatch.failed', error: message, turnId }))
            } catch (sendErr) {
              console.warn('[VoiceLive] Failed to send dispatch.failed event:', sendErr)
            }
          }
        }
      })().catch((err) => {
        console.error('[VoiceLive] Unhandled dispatch timer error:', err)
      })
    }, UTTERANCE_SILENCE_MS)
  }

  try {
    const tokenResponse = await credential.getToken('https://cognitiveservices.azure.com/.default')
    if (!tokenResponse?.token) {
      // DefaultAzureCredential returns null when no credential in the chain
      // can produce a token (e.g. missing managed identity, expired CLI login).
      // Fail fast with a clear close reason rather than letting a downstream
      // throw surface as a generic 1011.
      console.error('[VoiceLive] Failed to acquire AAD token for Cognitive Services')
      if (clientWs.readyState === WebSocket.OPEN) {
        clientWs.close(1011, 'Upstream auth unavailable')
      }
      return
    }

    const upstreamUrl =
      `wss://${VOICELIVE_RESOURCE}.services.ai.azure.com/voice-live/realtime` +
      `?api-version=${VOICELIVE_API_VERSION}&model=${VOICELIVE_MODEL}`

    upstreamWs = new WebSocket(upstreamUrl, {
      headers: { Authorization: `Bearer ${tokenResponse.token}` },
    })

    upstreamWs.on('open', () => {
      console.log(`[VoiceLive] Upstream connected for session ${sessionId}`)
      upstreamWs!.send(JSON.stringify(buildSessionUpdate()))
    })

    upstreamWs.on('message', async (data) => {
      try {
        // ws's RawData can be string | Buffer | ArrayBuffer | Buffer[]
        // depending on framing and binaryType. Normalize defensively so a
        // future change in upstream framing or socket options doesn't
        // throw inside the hot path.
        let raw: string
        if (typeof data === 'string') {
          raw = data
        } else if (Buffer.isBuffer(data)) {
          raw = data.toString('utf8')
        } else if (Array.isArray(data)) {
          raw = Buffer.concat(data).toString('utf8')
        } else if (data instanceof ArrayBuffer) {
          raw = Buffer.from(data).toString('utf8')
        } else {
          // Fallback for unexpected types (e.g. ArrayBufferView)
          raw = Buffer.from(data as ArrayBufferLike).toString('utf8')
        }
        const event = JSON.parse(raw)

        // Voice Live emits many non-`.delta` event types per session
        // (session.created, session.updated, transcription.completed,
        // input_audio_buffer.committed, response lifecycle, etc.). Logging
        // every one floods production logs, so gate behind VOICELIVE_DEBUG
        // (the same flag that controls raw transcript content logging).
        if (VOICELIVE_DEBUG && !event.type?.includes('.delta')) {
          console.log(`[VoiceLive] Upstream event: ${event.type}`)
        }

        // Signal client to start sending audio after session is configured
        if (event.type === 'session.updated') {
          if (clientWs.readyState === WebSocket.OPEN) {
            clientWs.send(JSON.stringify({ type: 'session.ready' }))
          }
        }

        // Forward to client for captions
        if (clientWs.readyState === WebSocket.OPEN) {
          clientWs.send(JSON.stringify(event))
        }

        // User transcript — show in chat immediately, accumulate for dispatch
        if (event.type === 'conversation.item.input_audio_transcription.completed') {
          const transcript = (event as { transcript?: string }).transcript ?? ''
          if (transcript.trim()) {
            if (VOICELIVE_DEBUG) {
              console.log(`[VoiceLive] User said (session=${sessionId}): ${transcript}`)
            } else {
              console.log(`[VoiceLive] Transcript completed session=${sessionId} chars=${transcript.trim().length}`)
            }
            const userMsg = {
              id: crypto.randomUUID(),
              role: 'user' as const,
              text: transcript.trim(),
              timestamp: new Date().toISOString(),
              userId,
              displayName,
              source: 'voice' as const,
            }
            sessionStore.addMessage(sessionId, userMsg)
            sseRegistry.broadcast(sessionId, userMsg)
            pendingUtterances.push(transcript.trim())
            scheduleDispatch()
          }
        }
      } catch (err) {
        console.error('[VoiceLive] Error handling upstream message:', err)
      }
    })

    upstreamWs.on('close', (code, reason) => {
      console.log(`[VoiceLive] Upstream closed: ${code} ${reason}`)
      if (dispatchTimer) clearTimeout(dispatchTimer)
      const clientCode = code === 1000 ? 1000 : 1011
      const clientReason = code === 1000 ? 'Upstream closed' : `Upstream failure (${code})`
      if (clientWs.readyState === WebSocket.OPEN) clientWs.close(clientCode, clientReason)
    })

    upstreamWs.on('error', (err) => {
      console.error('[VoiceLive] Upstream error:', err)
      if (clientWs.readyState === WebSocket.OPEN) clientWs.close(1011, 'Upstream error')
    })

    clientWs.on('message', (data, isBinary) => {
      if (!isBinary) return
      if (upstreamWs?.readyState === WebSocket.OPEN) {
        // Normalize ws's RawData (Buffer | Buffer[] | ArrayBuffer) into a
        // single Buffer. Browsers send a single binary frame today, but
        // ws can fragment into Buffer[] depending on framing/options, and
        // Buffer.from(arrayLike) would throw on Buffer[]. Defensive
        // normalization keeps the audio path crash-free across versions.
        let buffer: Buffer
        if (Buffer.isBuffer(data)) {
          buffer = data
        } else if (Array.isArray(data)) {
          buffer = Buffer.concat(data)
        } else if (data instanceof ArrayBuffer) {
          buffer = Buffer.from(data)
        } else {
          buffer = Buffer.from(data as ArrayBufferLike)
        }
        const base64 = buffer.toString('base64')
        upstreamWs.send(JSON.stringify({
          type: 'input_audio_buffer.append',
          audio: base64,
        }))
      }
    })

    clientWs.on('close', () => {
      console.log(`[VoiceLive] Client disconnected for session ${sessionId}`)
      if (dispatchTimer) clearTimeout(dispatchTimer)
      // Flush pending utterances on disconnect.
      // Each individual transcript was already persisted + broadcast as a
      // user message when its `...transcription.completed` event arrived
      // (see the upstream message handler above), so we MUST NOT add another
      // combined user message here — doing so produces duplicate entries in
      // the transcript (individual lines + a concatenated copy).
      if (pendingUtterances.length > 0) {
        const fullText = pendingUtterances.join(' ')
        pendingUtterances.length = 0
        // Mint a turnId for parity with the timer dispatch path. The
        // originating client is disconnecting, but other participants will
        // still receive the broadcast assistant reply via SSE — they'll
        // ignore the turnId since it isn't in their pending set, which is
        // the correct behavior.
        const turnId = crypto.randomUUID()
        // Best-effort `dispatching` event so the originating client (if
        // its socket flushes one more frame before close) can register
        // the turnId in its pending set; without this, a later
        // `dispatch.failed` carrying the same turnId can't correlate.
        if (clientWs.readyState === WebSocket.OPEN) {
          clientWs.send(JSON.stringify({ type: 'dispatching', turnId }))
        }
        dispatchChat(sessionId, fullText, { userId, displayName, ssoToken, source: 'voice', skipUserMessage: true, turnId })
          .catch(err => {
            console.error('[VoiceLive] Final dispatch error:', err)
            // Best-effort: client is already disconnecting, but if the socket
            // somehow flushes this in time the UI will clear its spinner.
            // Include turnId so the client can correlate to its pending set
            // (the timer-dispatch path does the same — see above).
            if (clientWs.readyState === WebSocket.OPEN) {
              const message = err instanceof Error ? err.message : 'Dispatch failed'
              clientWs.send(JSON.stringify({ type: 'dispatch.failed', error: message, turnId }))
            }
          })
      }
      if (upstreamWs?.readyState === WebSocket.OPEN) upstreamWs.close()
    })

    clientWs.on('error', (err) => {
      console.error('[VoiceLive] Client error:', err)
      if (upstreamWs?.readyState === WebSocket.OPEN) upstreamWs.close()
    })
  } catch (err) {
    console.error('[VoiceLive] Connection setup failed:', err)
    if (clientWs.readyState === WebSocket.OPEN) clientWs.close(1011, 'Setup failed')
    if (upstreamWs?.readyState === WebSocket.OPEN) upstreamWs.close()
  }
}
