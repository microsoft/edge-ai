import express from 'express'
import path from 'path'
import { DefaultAzureCredential } from '@azure/identity'
import { chatHandler } from './chatHandler.js'
import { listSessions, createSession, updateSession, addParticipant } from './sessionsHandler.js'
import { getTranscript } from './transcriptHandler.js'
import { requireAuth } from './authMiddleware.js'
import { sseHandler } from './sseHandler.js'
import { closeAll as closeDirectLineConnections } from './directLineClient.js'
import { closeAll as closeCpsConnections } from './copilotStudioClient.js'
import { attachVoiceLiveBridge } from './voiceLiveBridge.js'
import { mintTicket } from './wsTicketStore.js'
import { mintSseTicket } from './sseTicketStore.js'
import { getAuthorizedSession } from './aclHelper.js'

const app = express()
const PORT = parseInt(process.env.PORT || '3978', 10)

const credential = new DefaultAzureCredential()

app.use(express.json())

// Allow microphone and autoplay in cross-origin iframes (Teams tabs)
app.use((_req, res, next) => {
  res.setHeader('Permissions-Policy', 'microphone=(self), autoplay=(self)')
  next()
})

// Serve static frontend files
app.use(express.static(path.join(import.meta.dirname, '../../public')))

// Authenticate all other API requests
app.use('/api', requireAuth)

// Public client config (non-sensitive values)
app.get('/api/config', (_req, res) => {
  res.json({ teamsAppId: process.env.TEAMS_APP_ID || '' })
})

// Chat API endpoint
app.post('/api/chat', chatHandler)

// Session management
app.get('/api/sessions', listSessions)
app.post('/api/sessions', createSession)
app.patch('/api/sessions/:id', updateSession)
app.post('/api/sessions/:id/participants', addParticipant)

// Transcript retrieval
app.get('/api/transcript/:sessionId', getTranscript)

// SSE group message relay
app.get('/api/sessions/:sessionId/events', sseHandler)

// Mint a short-lived one-time SSE ticket so EventSource auth does not put
// bearer tokens in URL query strings.
app.post('/api/sessions/:sessionId/sse-ticket', (req, res) => {
  const user = req.user
  if (!user) {
    res.status(401).json({ error: 'Authentication required' })
    return
  }
  const sessionId = req.params.sessionId
  if (!sessionId) {
    res.status(400).json({ error: 'sessionId required' })
    return
  }
  const session = getAuthorizedSession(res, sessionId, user.userId)
  if (!session) return

  const ticket = mintSseTicket({
    userId: user.userId,
    displayName: user.displayName,
    tenantId: user.tenantId,
    ssoToken: req.ssoToken ?? '',
    expectedPath: `/sessions/${sessionId}/events`,
  })
  res.json({ ticket })
})

// Voice Live is gated by the same env vars used to attach the WS bridge
// below. We hoist the flag so the ticket-mint route can refuse early when
// the bridge isn't attached — otherwise authenticated callers could mint
// tickets that no upgrade handler will ever consume, leaving entries to
// accumulate in the in-memory map until TTL eviction.
const VOICE_LIVE_ENABLED =
  process.env.VOICE_PROVIDER === 'voicelive' && !!process.env.AZURE_VOICELIVE_RESOURCE

// Mint a single-use ticket for the Voice Live WebSocket upgrade.
// Avoids passing the SSO bearer token in the WS URL query string.
app.post('/api/voice-live/ticket', (req, res) => {
  if (!VOICE_LIVE_ENABLED) {
    // 503 (rather than 404) so clients can distinguish "feature disabled"
    // from "route doesn't exist" — the route exists, the backend just
    // isn't configured to serve it in this deployment.
    res.status(503).json({
      error: 'Voice Live is not enabled on this server. ' +
        'Set VOICE_PROVIDER=voicelive and AZURE_VOICELIVE_RESOURCE to enable.',
    })
    return
  }
  const user = req.user
  if (!user) {
    res.status(401).json({ error: 'Authentication required' })
    return
  }
  // Only the Copilot Studio backend requires a real bearer token to relay
  // user identity downstream. In SKIP_AUTH dev mode requireAuth synthesizes
  // a user without an SSO token, so a Voice Live dispatch against this
  // backend would fail inside the silence-debounced timer (see dispatchChat).
  // Reject ticket-mint up front with an actionable error for copilotstudio.
  // Other backends (for example directline/foundry) can run without SSO.
  const agentBackend = process.env.AGENT_BACKEND || 'copilotstudio'
  const ssoToken = req.ssoToken
  if (!ssoToken && agentBackend === 'copilotstudio') {
    res.status(400).json({
      error: `Voice Live requires an SSO token when AGENT_BACKEND=${agentBackend}. ` +
        'Either disable SKIP_AUTH and authenticate via Teams SSO, or set AGENT_BACKEND to a non-copilotstudio backend ' +
        'for local development without auth.',
    })
    return
  }
  const sessionId = (req.body as { sessionId?: unknown } | undefined)?.sessionId
  if (typeof sessionId !== 'string' || !sessionId) {
    res.status(400).json({ error: 'sessionId required' })
    return
  }
  // Enforce the session ACL here so callers cannot mint tickets for
  // sessions they don't participate in. Without this, anyone with a valid
  // bearer token could fill the in-memory ticket map with arbitrary
  // sessionIds (the upgrade handler would reject them later, but the
  // tickets still consume memory until they expire).
  const session = getAuthorizedSession(res, sessionId, user.userId)
  if (!session) return
  const ticket = mintTicket({
    userId: user.userId,
    displayName: user.displayName,
    tenantId: user.tenantId,
    sessionId,
    ssoToken: ssoToken ?? '',
  })
  res.json({ ticket })
})

// GET /api/speech-token — issue short-lived Azure Speech auth token via AAD
app.get('/api/speech-token', async (_req, res) => {
  const speechRegion = process.env.AZURE_SPEECH_REGION
  const speechResourceId = process.env.AZURE_SPEECH_RESOURCE_ID
  if (!speechRegion) {
    res.status(500).json({ error: 'Azure Speech not configured' })
    return
  }

  try {
    // Get AAD token, then exchange it for a Speech-specific auth token via STS
    const aadToken = await credential.getToken('https://cognitiveservices.azure.com/.default')
    const stsUrl = speechResourceId
      ? `https://${speechResourceId}.cognitiveservices.azure.com/sts/v1.0/issueToken`
      : `https://${speechRegion}.api.cognitive.microsoft.com/sts/v1.0/issueToken`
    const stsRes = await fetch(stsUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${aadToken.token}`,
        'Content-Length': '0',
      },
    })
    if (!stsRes.ok) {
      const body = await stsRes.text()
      console.error('[Speech] STS token exchange failed:', stsRes.status, body)
      res.status(502).json({ error: 'Failed to obtain speech token' })
      return
    }
    const speechToken = await stsRes.text()
    res.json({ token: speechToken, region: speechRegion })
  } catch (err) {
    console.error('[Speech] Token acquisition failed:', err)
    res.status(502).json({ error: 'Failed to obtain speech token' })
  }
})

// SPA fallback — serve index.html for non-API routes
app.get('/{*splat}', (_req, res) => {
  res.sendFile(path.join(import.meta.dirname, '../../public/index.html'))
})

const httpServer = app.listen(PORT, () => {
  console.log(`Voice Agent Tab server running on http://localhost:${PORT}`)
})

// Conditionally attach the Voice Live WebSocket bridge
let voiceLiveWss: import('ws').WebSocketServer | undefined
if (VOICE_LIVE_ENABLED) {
  voiceLiveWss = attachVoiceLiveBridge(httpServer)
  console.log('[VoiceLive] Bridge attached at /api/voice-live')
}

const SHUTDOWN_TIMEOUT_MS = 10_000
let shuttingDown = false

function gracefulShutdown(signal: NodeJS.Signals) {
  if (shuttingDown) {
    // Second signal — operator wants to bail out now.
    console.log(`Received ${signal} during shutdown, forcing exit`)
    process.exit(1)
  }
  shuttingDown = true
  console.log(`Shutting down (${signal})...`)

  // Close upstream client connections (DirectLine / Copilot Studio sockets)
  // and the Voice Live WebSocket server first so they stop generating
  // traffic against the HTTP server while it drains.
  closeDirectLineConnections()
  closeCpsConnections()
  if (voiceLiveWss) {
    // Proactively close upgraded WS clients so shutdown does not depend on
    // peers disconnecting on their own.
    for (const ws of voiceLiveWss.clients) {
      try {
        ws.close(1001, 'Server shutting down')
      } catch {
        // Ignore per-socket close errors; fallback terminate handles stragglers.
      }
    }

    // Force-close any lingering sockets after a short grace period.
    setTimeout(() => {
      for (const ws of voiceLiveWss.clients) {
        try {
          ws.terminate()
        } catch {
          // Best-effort termination.
        }
      }
    }, 2_000).unref()

    voiceLiveWss.close()
  }

  // httpServer.close() stops accepting new connections and waits for existing
  // ones (including SSE streams) to finish before invoking the callback.
  // Exiting from the callback gives those connections a real chance to drain.
  httpServer.close((err) => {
    if (err) {
      console.error('Error during HTTP server close:', err)
      process.exit(1)
    }
    console.log('HTTP server closed cleanly')
    process.exit(0)
  })

  // Hard cap so a stuck SSE / WebSocket connection can't block exit forever.
  // .unref() so this timer alone doesn't keep the loop alive.
  setTimeout(() => {
    console.error(`Shutdown timed out after ${SHUTDOWN_TIMEOUT_MS}ms, forcing exit`)
    process.exit(1)
  }, SHUTDOWN_TIMEOUT_MS).unref()
}

process.on('SIGTERM', gracefulShutdown)
process.on('SIGINT', gracefulShutdown)
