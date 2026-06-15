import type { Request, Response } from 'express'
import * as directLine from './directLineClient.js'
import { sseRegistry } from './sseRegistry.js'
import { getAuthorizedSession } from './aclHelper.js'
import { sessionStore } from './sessionStore.js'

const AGENT_BACKEND = process.env.AGENT_BACKEND || 'foundry'

/** Strip control characters and limit displayName length for defense-in-depth. */
export function sanitizeDisplayName(raw: string | undefined, fallback = 'Unknown'): string {
  if (!raw || typeof raw !== 'string') return fallback
  const sanitized = Array.from(raw)
    .filter((ch) => {
      const code = ch.charCodeAt(0)
      return code >= 0x20 && !(code >= 0x7f && code <= 0x9f)
    })
    .join('')
    .trim()
  return sanitized.slice(0, 100) || fallback
}

export async function listSessions(req: Request, res: Response): Promise<void> {
  const { userId } = req.user
  const chatId = req.query.chatId as string | undefined

  console.log('[Sessions] listSessions | userId:', userId, '| chatId:', chatId)

  let sessions = sessionStore.listByUser(userId)

  // If a chatId is provided, include the session linked to that chat
  // (e.g., created by the bot) and auto-add the user as a participant
  if (chatId) {
    const chatSession = sessionStore.findByChatId(chatId)
    console.log('[Sessions] findByChatId result:', chatSession?.id ?? 'none')
    if (chatSession) {
      if (!chatSession.participants.includes(userId)) {
        sessionStore.addParticipant(chatSession.id, userId, req.user.displayName)
        sessions = sessionStore.listByUser(userId)
      }
    }
  }

  res.json(sessions)
}

export async function createSession(req: Request, res: Response): Promise<void> {
  const { userId, displayName: userName } = req.user

  try {
    if (AGENT_BACKEND === 'directline') {
      const session = sessionStore.createSession(
        userId,
        userName || 'Unknown',
        undefined,
        { title: req.body?.title, metadata: req.body?.metadata },
      )

      const onActivity = (activity: { text?: string; id?: string; timestamp?: string; replyToId?: string }) => {
        if (!activity.text) return
        const message = {
          id: activity.id || crypto.randomUUID(),
          role: 'assistant' as const,
          text: activity.text,
          timestamp: activity.timestamp || new Date().toISOString(),
          source: 'agent' as const,
          // Resolve the voicelive turnId previously recorded for this
          // bot reply's originating activity (replyToId). Falls back to
          // undefined for unsolicited bot activities (greetings, proactive
          // messages), which voicelive clients ignore for spinner state.
          turnId: directLine.consumeTurn(session.id, activity.replyToId),
        }
        sessionStore.addMessage(session.id, message)
        sseRegistry.broadcast(session.id, message)
      }

      const conversationId = await directLine.startConversation(session.id, onActivity)
      sessionStore.updateSession(session.id, { conversationId })

      const chatId = req.body?.chatId as string | undefined
      if (chatId) sessionStore.linkChatId(session.id, chatId)

      res.status(201).json(sessionStore.getSession(session.id))
    } 
    else if (AGENT_BACKEND === 'copilotstudio')
    {
      // Copilot Studio Agents SDK — dynamic import to avoid crash when CPS env vars absent
      if (!req.ssoToken || !req.user.tenantId) {
        res.status(401).json({ error: 'SSO token required for Copilot Studio backend' })
        return
      }

      const session = sessionStore.createSession(
        userId,
        userName || 'Unknown',
        undefined,
        { title: req.body?.title, metadata: req.body?.metadata },
      )

      const onActivity = (activity: { text?: string; id?: string; timestamp?: string }) => {
        if (!activity.text) return
        const message = {
          id: activity.id || crypto.randomUUID(),
          role: 'assistant' as const,
          text: activity.text,
          timestamp: activity.timestamp || new Date().toISOString(),
          source: 'agent' as const,
        }
        sessionStore.addMessage(session.id, message)
        sseRegistry.broadcast(session.id, message)
      }

      try {
        const cps = await import('./copilotStudioClient.js')
        const conversationId = await cps.startConversation(
          session.id,
          req.ssoToken,
          req.user.tenantId,
          onActivity,
        )
        sessionStore.updateSession(session.id, { conversationId })
      } catch (cpsError) {
        console.error('CPS startConversation failed:', cpsError)
        // Mark orphaned session so it's not usable
        sessionStore.updateSession(session.id, { status: 'archived' })
        throw cpsError
      }

      const chatId = req.body?.chatId as string | undefined
      if (chatId) sessionStore.linkChatId(session.id, chatId)

      res.status(201).json(sessionStore.getSession(session.id))
    }
    else 
    {
      // Foundry flow — dynamic import to avoid crash when Foundry env vars absent
      const { agentsClient } = await import('./agentsClient.js')
      const thread = await agentsClient.threads.create()
      const session = sessionStore.createSession(
        userId,
        userName || 'Unknown',
        thread.id,
        { title: req.body?.title, metadata: req.body?.metadata },
      )
      const chatId = req.body?.chatId as string | undefined
      if (chatId) sessionStore.linkChatId(session.id, chatId)
      res.status(201).json(session)
    }
  } catch (error) {
    console.error('Create session error:', error)
    res.status(500).json({ error: 'Failed to create session' })
  }
}

export async function updateSession(req: Request, res: Response): Promise<void> {
  const { userId } = req.user

  const session = getAuthorizedSession(res, req.params.id as string, userId)
  if (!session) return

  const { status, title } = req.body ?? {}
  if (status && status !== 'active' && status !== 'archived') {
    res.status(400).json({ error: "Invalid status: must be 'active' or 'archived'" })
    return
  }
  const updated = sessionStore.updateSession(session.id, {
    ...(status && { status }),
    ...(title && { title }),
  })
  res.json(updated)
}

export async function addParticipant(req: Request, res: Response): Promise<void> {
  const { userId } = req.user

  const session = getAuthorizedSession(res, req.params.id as string, userId)
  if (!session) return

  const { userId: newUserId, displayName: rawDisplayName } = req.body ?? {}
  if (!newUserId || typeof newUserId !== 'string') {
    res.status(400).json({ error: 'Missing or invalid "userId" in body' })
    return
  }

  const displayName = sanitizeDisplayName(rawDisplayName)

  const updated = sessionStore.addParticipant(session.id, newUserId, displayName)
  res.json(updated)
}
