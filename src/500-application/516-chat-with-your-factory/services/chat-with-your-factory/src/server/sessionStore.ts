import type { Session, TranscriptMessage } from '../shared/types.js'

const sessions = new Map<string, Session>()
const chatIdToSession = new Map<string, string>() // chatId → sessionId
const sessionMessages = new Map<string, TranscriptMessage[]>()
const SESSION_ID_RE = /^session-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
const CONTINUITY_WINDOW_MS = 30 * 24 * 60 * 60 * 1000
const MAX_CLOCK_SKEW_MS = 5 * 60 * 1000

export interface AdoptSessionInput {
  id: string
  title?: unknown
  createdAt?: unknown
  lastActivityAt?: unknown
  status?: unknown
  metadata?: unknown
}

export interface AdoptSessionIdentity {
  userId: string
  displayName: string
}

export interface AdoptSessionPointers {
  conversationId?: string
  threadId?: string
}

function sanitizeTitle(value: unknown): string {
  if (typeof value !== 'string') return 'Conversation'
  const sanitized = Array.from(value)
    .filter(character => {
      const code = character.charCodeAt(0)
      return code >= 0x20 && !(code >= 0x7f && code <= 0x9f)
    })
    .join('')
    .trim()
  return sanitized.slice(0, 200) || 'Conversation'
}

function sanitizeTimestamp(value: unknown, fallback: string): string {
  if (typeof value !== 'string' || value.length > 64) return fallback
  const milliseconds = Date.parse(value)
  const now = Date.now()
  if (
    !Number.isFinite(milliseconds) ||
    milliseconds < now - CONTINUITY_WINDOW_MS ||
    milliseconds > now + MAX_CLOCK_SKEW_MS
  ) {
    return fallback
  }
  return new Date(milliseconds).toISOString()
}

function sanitizeMetadata(value: unknown): Session['metadata'] {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return {}
  const incoming = value as Record<string, unknown>
  const metadata: Session['metadata'] = {}
  const sanitizeValue = (raw: unknown): string | undefined => {
    if (typeof raw !== 'string') return undefined
    const sanitized = Array.from(raw)
      .filter(character => {
        const code = character.charCodeAt(0)
        return code >= 0x20 && !(code >= 0x7f && code <= 0x9f)
      })
      .join('')
      .trim()
      .slice(0, 256)
    return sanitized || undefined
  }
  const machineId = sanitizeValue(incoming.machineId)
  const machineName = sanitizeValue(incoming.machineName)
  if (machineId) metadata.machineId = machineId
  if (machineName) metadata.machineName = machineName
  return metadata
}

export const sessionStore = {
  listByUser(userId: string): Session[] {
    return [...sessions.values()]
      .filter(s => s.participants.includes(userId))
      .sort((a, b) => b.lastActivityAt.localeCompare(a.lastActivityAt))
  },

  getSession(sessionId: string): Session | undefined {
    return sessions.get(sessionId)
  },

  createSession(
    userId: string,
    displayName: string,
    threadId?: string,
    opts?: { title?: string; metadata?: Session['metadata'] },
  ): Session {
    const now = new Date().toISOString()
    const session: Session = {
      id: `session-${crypto.randomUUID()}`,
      userId,
      threadId,
      title: opts?.title ?? 'New conversation',
      createdAt: now,
      lastActivityAt: now,
      status: 'active',
      participants: [userId],
      participantNames: { [userId]: displayName },
      metadata: opts?.metadata ?? {},
    }
    sessions.set(session.id, session)
    return session
  },

  adoptSession(
    incoming: AdoptSessionInput,
    identity: AdoptSessionIdentity,
    pointers: AdoptSessionPointers,
  ): Session | undefined {
    if (!SESSION_ID_RE.test(incoming.id)) return undefined
    const existing = sessions.get(incoming.id)
    if (existing) return existing

    const now = new Date().toISOString()
    const createdAt = sanitizeTimestamp(incoming.createdAt, now)
    const lastActivityAt = sanitizeTimestamp(incoming.lastActivityAt, createdAt)
    const session: Session = {
      id: incoming.id,
      userId: identity.userId,
      ...(pointers.threadId && { threadId: pointers.threadId }),
      ...(pointers.conversationId && { conversationId: pointers.conversationId }),
      title: sanitizeTitle(incoming.title),
      createdAt,
      lastActivityAt: lastActivityAt < createdAt ? createdAt : lastActivityAt,
      status: incoming.status === 'archived' ? 'archived' : 'active',
      participants: [identity.userId],
      participantNames: { [identity.userId]: identity.displayName },
      metadata: sanitizeMetadata(incoming.metadata),
    }
    sessions.set(session.id, session)
    return session
  },

  updateSession(
    sessionId: string,
    updates: Partial<Pick<Session, 'status' | 'title' | 'lastActivityAt' | 'threadId' | 'conversationId'>>,
  ): Session | undefined {
    const session = sessions.get(sessionId)
    if (!session) return undefined
    Object.assign(session, updates)
    return session
  },

  addParticipant(sessionId: string, userId: string, displayName?: string): Session | undefined {
    const session = sessions.get(sessionId)
    if (!session) return undefined
    if (!session.participants.includes(userId)) {
      session.participants.push(userId)
    }
    if (displayName) {
      session.participantNames[userId] = displayName
    }
    return session
  },

  findByChatId(chatId: string): Session | undefined {
    const sessionId = chatIdToSession.get(chatId)
    return sessionId ? sessions.get(sessionId) : undefined
  },

  linkChatId(sessionId: string, chatId: string): void {
    chatIdToSession.set(chatId, sessionId)
  },

  addMessage(sessionId: string, message: TranscriptMessage): void {
    let msgs = sessionMessages.get(sessionId)
    if (!msgs) {
      msgs = []
      sessionMessages.set(sessionId, msgs)
    }
    msgs.push(message)
  },

  getMessages(sessionId: string): TranscriptMessage[] {
    return sessionMessages.get(sessionId) ?? []
  },
}
