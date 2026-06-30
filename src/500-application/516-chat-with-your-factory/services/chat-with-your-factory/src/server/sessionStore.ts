import type { Session, TranscriptMessage } from '../shared/types.js'

const sessions = new Map<string, Session>()
const chatIdToSession = new Map<string, string>() // chatId → sessionId
const sessionMessages = new Map<string, TranscriptMessage[]>()

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
