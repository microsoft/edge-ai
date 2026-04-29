import type { Request, Response } from 'express'
import * as directLine from './directLineClient.js'
import { getAuthorizedSession } from './aclHelper.js'
import { sessionStore } from './sessionStore.js'
import { sseRegistry } from './sseRegistry.js'

const AGENT_BACKEND = process.env.AGENT_BACKEND || 'copilotstudio'

export interface DispatchContext {
  userId: string
  displayName?: string
  ssoToken?: string
  source?: 'voice' | 'text' | 'teams'
  skipUserMessage?: boolean
  /** Optional correlation ID stamped onto the assistant reply broadcast.
   *  Used by voicelive clients to match replies to the dispatch they
   *  initiated, so a co-participant's reply doesn't clear this client's
   *  pending-dispatch spinner. */
  turnId?: string
}

export interface DispatchResult {
  text: string
  messageId: string
  title?: string
}

export async function dispatchChat(
  sessionId: string,
  text: string,
  ctx: DispatchContext,
): Promise<DispatchResult> {
  const session = sessionStore.getSession(sessionId)
  if (!session) {
    throw new Error(`Session not found: ${sessionId}`)
  }
  if (!session.participants.includes(ctx.userId)) {
    throw new Error(`User ${ctx.userId} is not a participant of session ${sessionId}`)
  }

  if (!ctx.skipUserMessage) {
    const userMessage = {
      id: crypto.randomUUID(),
      role: 'user' as const,
      text,
      timestamp: new Date().toISOString(),
      userId: ctx.userId,
      displayName: ctx.displayName,
      source: (ctx.source ?? 'text') as 'voice' | 'text' | 'teams',
    }
    sessionStore.addMessage(sessionId, userMessage)
    sseRegistry.broadcast(sessionId, userMessage)
  }

  let generatedTitle: string | undefined
  if (session.title === 'New conversation') {
    const maxLen = 60
    generatedTitle = text.length > maxLen
      ? text.slice(0, maxLen) + '...'
      : text
    sessionStore.updateSession(sessionId, { title: generatedTitle })
  }

  if (AGENT_BACKEND === 'directline') {
    const activityId = await directLine.sendActivity(sessionId, {
      type: 'message',
      from: { id: `dl_${sessionId}` },
      text,
    })
    // Record the turnId against the outgoing activity ID so the bot's
    // eventual async reply (which carries `replyToId === activityId`)
    // can be stamped with turnId in the Direct Line WS handler. Without
    // this the voicelive client's pending-turn spinner would never clear.
    if (ctx.turnId) {
      directLine.recordTurn(sessionId, activityId, ctx.turnId)
    }
    sessionStore.updateSession(sessionId, { lastActivityAt: new Date().toISOString() })
    return { text: '', messageId: '', title: generatedTitle }
  } else if (AGENT_BACKEND === 'copilotstudio') {
    if (!ctx.ssoToken) {
      throw new Error('SSO token required for Copilot Studio backend')
    }
    const cps = await import('./copilotStudioClient.js')

    let lastAssistantText = ''
    let lastAssistantId = ''

    const onActivity = (activity: { text?: string; id?: string; timestamp?: string }) => {
      if (!activity.text) return
      const message = {
        id: activity.id || crypto.randomUUID(),
        role: 'assistant' as const,
        text: activity.text,
        timestamp: activity.timestamp || new Date().toISOString(),
        source: 'agent' as const,
        turnId: ctx.turnId,
      }
      sessionStore.addMessage(sessionId, message)
      sseRegistry.broadcast(sessionId, message)
      lastAssistantText = activity.text
      lastAssistantId = message.id
    }

    await cps.sendActivity(sessionId, text, onActivity)
    sessionStore.updateSession(sessionId, { lastActivityAt: new Date().toISOString() })
    return { text: lastAssistantText, messageId: lastAssistantId, title: generatedTitle }
  } else {
    const { agentsClient, agentId } = await import('./agentsClient.js')
    type MessageTextContent = { type: 'text'; text: { value: string } }

    let threadId = session.threadId
    if (!threadId) {
      const thread = await agentsClient.threads.create()
      threadId = thread.id
      sessionStore.updateSession(sessionId, { threadId })
    }

    await agentsClient.messages.create(threadId, 'user', text)
    const run = await agentsClient.runs.createAndPoll(threadId, agentId)

    if (run.status !== 'completed') {
      console.error('Agent run failed:', run.status, run.lastError)
      throw new Error('Agent run did not complete')
    }

    const messages = agentsClient.messages.list(threadId, { order: 'desc', limit: 1 })

    let responseText = 'No response from agent.'
    for await (const msg of messages) {
      if (msg.role === 'assistant') {
        for (const block of msg.content) {
          if (block.type === 'text') {
            responseText = (block as MessageTextContent).text.value
          }
        }
      }
      break
    }

    sessionStore.updateSession(sessionId, { lastActivityAt: new Date().toISOString() })

    const agentMessage = {
      id: crypto.randomUUID(),
      role: 'assistant' as const,
      text: responseText,
      timestamp: new Date().toISOString(),
      source: 'agent' as const,
      turnId: ctx.turnId,
    }
    sessionStore.addMessage(sessionId, agentMessage)
    sseRegistry.broadcast(sessionId, agentMessage)

    return { text: responseText, messageId: agentMessage.id, title: generatedTitle }
  }
}

export async function chatHandler(req: Request, res: Response): Promise<void> {
  const { text, sessionId, source } = req.body

  if (!text || typeof text !== 'string') {
    res.status(400).json({ error: 'Missing or invalid "text" field' })
    return
  }
  if (!sessionId || typeof sessionId !== 'string') {
    res.status(400).json({ error: 'Missing or invalid "sessionId" field' })
    return
  }
  const { userId } = req.user

  const session = getAuthorizedSession(res, sessionId, userId)
  if (!session) return

  try {
    const result = await dispatchChat(sessionId, text, {
      userId,
      displayName: req.user.displayName,
      ssoToken: req.ssoToken,
      source: source as 'voice' | 'text' | 'teams' | undefined,
    })

    if (AGENT_BACKEND === 'directline' || AGENT_BACKEND === 'copilotstudio') {
      res.json({ sessionId, ...(result.title && { title: result.title }) })
    } else {
      res.json({
        sessionId,
        text: result.text,
        messageId: result.messageId,
        ...(result.title && { title: result.title }),
      })
    }
  } catch (error) {
    console.error('Chat handler error:', error)
    const message = error instanceof Error ? error.message : 'Failed to generate response'
    if (message.includes('SSO token required')) {
      res.status(401).json({ error: message })
    } else {
      res.status(500).json({ error: 'Failed to generate response' })
    }
  }
}