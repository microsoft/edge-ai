import type { Request, Response } from 'express'
import { isOutputOfType } from '@azure/ai-agents'
import type {
  RunStatus,
  SubmitToolOutputsAction,
  RequiredFunctionToolCall,
  ToolOutput,
} from '@azure/ai-agents'
import { cleanLogging } from '../shared/logging.js'
import * as directLine from './directLineClient.js'
import { getAuthorizedSession } from './aclHelper.js'
import { handleFactoryTool } from './factoryTool.js'
import { sessionStore } from './sessionStore.js'
import { sseRegistry } from './sseRegistry.js'

const AGENT_BACKEND = process.env.AGENT_BACKEND || 'foundry'

// Foundry run states that warrant continued polling. Module-scoped and frozen
// so it isn't rebuilt per request and can't be mutated.
const POLL_STATUSES: ReadonlySet<RunStatus> = new Set([
  'queued',
  'in_progress',
  'requires_action',
  'cancelling',
])
const CANCELLABLE_STATUSES: ReadonlySet<RunStatus> = new Set([
  'queued',
  'in_progress',
  'requires_action',
])
// Hard cap on the run-polling loop. Express 5 has no request timeout, so an
// upstream stall (quota pause, hung run) would otherwise hold the HTTP socket
// and a worker open indefinitely.
const MAX_POLL_MS = 120_000

export interface DispatchContext {
  userId: string
  displayName?: string
  ssoToken?: string
  source?: 'voice' | 'text' | 'teams'
  skipUserMessage?: boolean
  clientMessageId?: string
  onAssistantCompleted?: (markdown: string) => void
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

function publishAssistantMessage(
  sessionId: string,
  message: {
    id: string
    role: 'assistant'
    text: string
    timestamp: string
    source: 'agent'
    turnId?: string
  },
  onAssistantCompleted?: (markdown: string) => void,
): void {
  sessionStore.addMessage(sessionId, message)
  sseRegistry.broadcast(sessionId, message)
  try {
    onAssistantCompleted?.(message.text)
  } catch (error) {
    cleanLogging.Warn('Chat', 'Assistant completion callback failed', error)
  }
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
      id: ctx.clientMessageId ?? crypto.randomUUID(),
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
      publishAssistantMessage(sessionId, message, ctx.onAssistantCompleted)
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
    let run = await agentsClient.runs.create(threadId, agentId)

    const pollDeadline = Date.now() + MAX_POLL_MS
    try {
      while (POLL_STATUSES.has(run.status)) {
        if (Date.now() > pollDeadline) {
          throw new Error(`Agent run timed out after ${MAX_POLL_MS / 1000} s`)
        }
        await new Promise(r => setTimeout(r, 1000))
        run = await agentsClient.runs.get(threadId, run.id)

        if (
          run.status === 'requires_action' &&
          run.requiredAction &&
          isOutputOfType<SubmitToolOutputsAction>(run.requiredAction, 'submit_tool_outputs')
        ) {
          const toolOutputs: ToolOutput[] = []
          for (const toolCall of run.requiredAction.submitToolOutputs.toolCalls) {
            if (isOutputOfType<RequiredFunctionToolCall>(toolCall, 'function')) {
              let result: unknown
              try {
                const args = toolCall.function.arguments
                  ? JSON.parse(toolCall.function.arguments)
                  : {}
                result = toolCall.function.name === 'query_factory_ontology'
                  ? await handleFactoryTool(args)
                  : { error: `unknown tool: ${toolCall.function.name}` }
              } catch (error) {
                cleanLogging.Warn('Chat', 'Agent tool execution failed', {
                  toolName: toolCall.function.name,
                  error,
                })
                result = {
                  error: 'The factory ontology is temporarily unavailable. Confirm that the Fabric capacity is active and retry.',
                }
              }
              toolOutputs.push({ toolCallId: toolCall.id, output: JSON.stringify(result ?? null) })
            }
          }
          if (toolOutputs.length) {
            await agentsClient.runs.submitToolOutputs(threadId, run.id, toolOutputs)
          }
        }

      }
    } catch (error) {
      if (CANCELLABLE_STATUSES.has(run.status)) {
        try {
          await agentsClient.runs.cancel(threadId, run.id)
        } catch (cancelError) {
          cleanLogging.Warn('Chat', 'Failed to cancel active agent run', cancelError)
        }
      }
      throw error
    }

    if (run.status !== 'completed') {
      if (run.status === 'failed') {
        const code = String(run.lastError?.code ?? 'unknown').slice(0, 128)
        const message = String(run.lastError?.message ?? 'No error details provided').slice(0, 500)
        throw new Error(`Agent run failed: ${code} ${message}`)
      }
      if (run.status === 'cancelled') throw new Error('Agent run was cancelled')
      if (run.status === 'expired') throw new Error('Agent run expired')
      throw new Error(`Agent run ended without completion: ${String(run.status).slice(0, 64)}`)
    }

    const messages = agentsClient.messages.list(threadId, {
      order: 'desc',
      limit: 1,
      runId: run.id,
    })

    let responseText: string | undefined
    for await (const msg of messages) {
      if (
        msg.role === 'assistant' &&
        msg.runId === run.id &&
        (msg.status === undefined || msg.status === 'completed')
      ) {
        const textBlocks: string[] = []
        for (const block of msg.content) {
          if (block.type === 'text') {
            textBlocks.push((block as MessageTextContent).text.value)
          }
        }
        if (textBlocks.length > 0) responseText = textBlocks.join('\n')
      }
      break
    }

    if (responseText === undefined) {
      throw new Error(`Agent run ${run.id} completed without a completed assistant message`)
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
    publishAssistantMessage(sessionId, agentMessage, ctx.onAssistantCompleted)

    return { text: responseText, messageId: agentMessage.id, title: generatedTitle }
  }
}

export async function chatHandler(req: Request, res: Response): Promise<void> {
  const { text, sessionId, source, messageId } = req.body

  if (!text || typeof text !== 'string') {
    res.status(400).json({ error: 'Missing or invalid "text" field' })
    return
  }
  if (!sessionId || typeof sessionId !== 'string') {
    res.status(400).json({ error: 'Missing or invalid "sessionId" field' })
    return
  }
  const clientMessageId = typeof messageId === 'string'
    && messageId.trim().length > 0
    && messageId.length <= 128
    ? messageId.trim()
    : undefined
  const { userId } = req.user

  const session = getAuthorizedSession(res, sessionId, userId)
  if (!session) return

  try {
    const result = await dispatchChat(sessionId, text, {
      userId,
      displayName: req.user.displayName,
      ssoToken: req.ssoToken,
      source: source as 'voice' | 'text' | 'teams' | undefined,
      clientMessageId,
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
    cleanLogging.Error('Chat', 'Chat handler error', error)
    const message = error instanceof Error ? error.message : 'Failed to generate response'
    if (message.includes('SSO token required')) {
      res.status(401).json({ error: message })
    } else {
      res.status(500).json({ error: 'Failed to generate response' })
    }
  }
}
