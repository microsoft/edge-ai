import WebSocket from 'ws'

const DL_BASE = process.env.DIRECT_LINE_ENDPOINT || 'https://directline.botframework.com'
const DL_SECRET = process.env.DIRECT_LINE_SECRET

export interface DirectLineActivity {
  type: string
  id?: string
  timestamp?: string
  from: { id: string; name?: string; role?: string }
  text?: string
  replyToId?: string
  attachments?: Array<{ contentType: string; content: unknown; contentUrl?: string; name?: string }>
  channelData?: Record<string, unknown>
}

interface ActivitySet {
  activities: DirectLineActivity[]
  watermark: string
}

interface ConversationState {
  conversationId: string
  ws: WebSocket | null
  watermark: string
  userId: string
  onActivity: (activity: DirectLineActivity) => void
  reconnectAttempts: number
  closed: boolean
  /** Maps the activity ID returned by `sendActivity` to a voicelive
   *  turnId. Bot replies arrive asynchronously over the Direct Line WS
   *  with `replyToId` set to the original activity ID, which lets us
   *  stamp the correct turnId on the broadcast and clear the matching
   *  pending-turn spinner on the originating client. */
  pendingTurns: Map<string, { turnId: string; expiresAt: number }>
}

const PENDING_TURN_TTL_MS = 5 * 60_000

function sweepExpiredTurns(state: ConversationState): void {
  const now = Date.now()
  for (const [k, v] of state.pendingTurns) {
    if (v.expiresAt <= now) state.pendingTurns.delete(k)
  }
}

const conversations = new Map<string, ConversationState>()

function ensureSecret(): string {
  if (!DL_SECRET) {
    throw new Error('DIRECT_LINE_SECRET is required when AGENT_BACKEND=directline')
  }
  return DL_SECRET
}

function connectWebSocket(sessionId: string, streamUrl: string): void {
  const state = conversations.get(sessionId)
  if (!state || state.closed) return

  const ws = new WebSocket(streamUrl)
  state.ws = ws

  ws.on('open', () => {
    console.log(`[DirectLine] WebSocket connected for session ${sessionId}`)
    state.reconnectAttempts = 0
  })

  ws.on('message', (data: WebSocket.RawData) => {
    const text = data.toString()
    if (!text) return // empty keepalive frame

    let activitySet: ActivitySet
    try {
      activitySet = JSON.parse(text)
    } catch {
      console.error(`[DirectLine] Failed to parse WebSocket frame for session ${sessionId}`)
      return
    }

    if (!activitySet.activities?.length) return

    if (activitySet.watermark) {
      state.watermark = activitySet.watermark
    }

    for (const activity of activitySet.activities) {
      // Only forward bot activities (skip user's own messages)
      if (activity.from.id === state.userId) continue
      state.onActivity(activity)
    }
  })

  ws.on('close', () => {
    if (state.closed) return
    console.log(`[DirectLine] WebSocket closed for session ${sessionId}, reconnecting...`)
    reconnect(sessionId)
  })

  ws.on('error', (err) => {
    console.error(`[DirectLine] WebSocket error for session ${sessionId}:`, err.message)
    ws.close()
  })
}

const MAX_RECONNECT_ATTEMPTS = 10

async function reconnect(sessionId: string): Promise<void> {
  const state = conversations.get(sessionId)
  if (!state || state.closed) return

  if (state.reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
    console.error(`[DirectLine] Max reconnect attempts reached for session ${sessionId}, closing`)
    state.closed = true
    state.ws?.close()
    conversations.delete(sessionId)
    return
  }

  const secret = ensureSecret()
  const delay = Math.min(1000 * Math.pow(2, state.reconnectAttempts), 30000)
  state.reconnectAttempts++

  console.log(`[DirectLine] Reconnecting session ${sessionId} in ${delay}ms (attempt ${state.reconnectAttempts})`)

  await new Promise(resolve => setTimeout(resolve, delay))

  if (state.closed) return

  try {
    const url = `${DL_BASE}/v3/directline/conversations/${state.conversationId}?watermark=${encodeURIComponent(state.watermark)}`
    const resp = await fetch(url, {
      headers: { Authorization: `Bearer ${secret}` },
    })

    if (!resp.ok) {
      console.error(`[DirectLine] Reconnect failed for session ${sessionId}: ${resp.status}`)
      reconnect(sessionId)
      return
    }

    const body = (await resp.json()) as { streamUrl: string }
    connectWebSocket(sessionId, body.streamUrl)
  } catch (err) {
    console.error(`[DirectLine] Reconnect error for session ${sessionId}:`, err)
    reconnect(sessionId)
  }
}

export async function startConversation(
  sessionId: string,
  onActivity: (activity: DirectLineActivity) => void,
): Promise<string> {
  const secret = ensureSecret()
  const userId = `dl_${sessionId}`

  const resp = await fetch(`${DL_BASE}/v3/directline/conversations`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${secret}`,
      'Content-Type': 'application/json',
    },
  })

  if (!resp.ok) {
    const body = await resp.text()
    throw new Error(`Failed to start Direct Line conversation: ${resp.status} ${body}`)
  }

  const { conversationId, streamUrl } = (await resp.json()) as {
    conversationId: string
    streamUrl: string
  }

  const state: ConversationState = {
    conversationId,
    ws: null,
    watermark: '',
    userId,
    onActivity,
    reconnectAttempts: 0,
    closed: false,
    pendingTurns: new Map(),
  }
  conversations.set(sessionId, state)

  connectWebSocket(sessionId, streamUrl)

  // Send startConversation event to trigger Copilot Studio greeting. If this
  // bootstrap send fails, tear down the just-created conversation and socket so
  // a failed start can't leak a live session with open reconnect machinery.
  try {
    await sendActivity(sessionId, {
      type: 'event',
      name: 'startConversation',
      from: { id: userId },
    } as DirectLineActivity & { name: string })
  } catch (err) {
    closeConversation(sessionId)
    throw err
  }

  return conversationId
}

export async function sendActivity(
  sessionId: string,
  activity: Partial<DirectLineActivity> & { name?: string },
): Promise<string> {
  const secret = ensureSecret()
  const state = conversations.get(sessionId)
  if (!state) {
    throw new Error(`No Direct Line conversation found for session ${sessionId}`)
  }

  const resp = await fetch(
    `${DL_BASE}/v3/directline/conversations/${state.conversationId}/activities`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${secret}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(activity),
    },
  )

  if (!resp.ok) {
    const body = await resp.text()
    throw new Error(`Failed to send activity: ${resp.status} ${body}`)
  }

  const { id } = (await resp.json()) as { id: string }
  return id
}

/**
 * Record a voicelive turnId for an in-flight Direct Line activity. The
 * bot's eventual reply will carry `replyToId === activityId`, letting
 * the inbound handler resolve and stamp the turnId.
 */
export function recordTurn(sessionId: string, activityId: string, turnId: string): void {
  const state = conversations.get(sessionId)
  if (!state) return
  // Opportunistic eviction of expired entries to keep the map bounded
  // even if some bot replies never arrive.
  sweepExpiredTurns(state)
  state.pendingTurns.set(activityId, { turnId, expiresAt: Date.now() + PENDING_TURN_TTL_MS })
}

/**
 * Look up and remove the turnId previously recorded for `activityId`,
 * or return undefined if none was recorded (or it expired).
 */
export function consumeTurn(sessionId: string, activityId: string | undefined): string | undefined {
  if (!activityId) return undefined
  const state = conversations.get(sessionId)
  if (!state) return undefined
  // Sweep here too so that a one-off recorded turn whose bot reply never
  // arrives can't linger indefinitely just because no further turns are
  // recorded on this session — any subsequent inbound activity (even an
  // unrelated proactive message) will trigger cleanup.
  sweepExpiredTurns(state)
  const entry = state.pendingTurns.get(activityId)
  if (!entry) return undefined
  state.pendingTurns.delete(activityId)
  if (entry.expiresAt <= Date.now()) return undefined
  return entry.turnId
}

export function closeConversation(sessionId: string): void {
  const state = conversations.get(sessionId)
  if (!state) return
  state.closed = true
  if (state.ws) {
    state.ws.close()
    state.ws = null
  }
  conversations.delete(sessionId)
}

export function closeAll(): void {
  for (const [sessionId] of conversations) {
    closeConversation(sessionId)
  }
}
