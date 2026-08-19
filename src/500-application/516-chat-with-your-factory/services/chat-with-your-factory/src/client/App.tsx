import { useState, useCallback, useRef, useEffect } from 'react'
import { Button, FluentProvider, makeStyles, tokens } from '@fluentui/react-components'
import { DeleteRegular } from '@fluentui/react-icons'
import { ChatPanel } from './components/ChatPanel.js'
import { VoiceInput } from './components/VoiceInput.js'
import { TextInput } from './components/TextInput.js'
import { SessionBar } from './components/SessionBar.js'
import { useTeamsTheme } from './hooks/useTeamsTheme.js'
import { useTeamsUser } from './hooks/useTeamsUser.js'
import { useSessionMessages } from './hooks/useSessionMessages.js'
import { useSessions } from './hooks/useSessions.js'
import type { TranscriptMessage } from '../shared/types.js'
import { toAddParticipantError } from '../shared/addParticipantErrors.js'
import { apiFetch } from './utils/apiFetch.js'

declare const __SPEECH_PROVIDER__: string

export interface Message {
  id: string
  role: 'user' | 'assistant'
  text: string
  source: 'voice' | 'text' | 'teams' | 'agent'
  timestamp: number
  displayName?: string
  userId?: string
}

function toUiMessages(messages: TranscriptMessage[]): Message[] {
  return messages.map(message => ({
    id: message.id,
    role: message.role,
    text: message.text,
    source: message.source ?? 'text',
    timestamp: new Date(message.timestamp).getTime(),
    displayName: message.displayName,
    userId: message.userId,
  }))
}

function toTranscriptMessage(message: Message): TranscriptMessage {
  return {
    id: message.id,
    role: message.role,
    text: message.text,
    timestamp: new Date(message.timestamp).toISOString(),
    source: message.source,
    displayName: message.displayName,
    userId: message.userId,
  }
}

const useStyles = makeStyles({
  root: {
    display: 'flex',
    flexDirection: 'column',
    height: '100vh',
    maxWidth: '800px',
    marginLeft: 'auto',
    marginRight: 'auto',
    backgroundColor: tokens.colorNeutralBackground1,
    color: tokens.colorNeutralForeground1,
  },
  inputBar: {
    display: 'flex',
    alignItems: 'center',
    gap: tokens.spacingHorizontalS,
    padding: `${tokens.spacingVerticalM} ${tokens.spacingHorizontalL}`,
    borderTop: `1px solid ${tokens.colorNeutralStroke2}`,
    backgroundColor: tokens.colorNeutralBackground1,
  },
  continuityBar: {
    display: 'flex',
    alignItems: 'center',
    gap: tokens.spacingHorizontalS,
    padding: `${tokens.spacingVerticalXS} ${tokens.spacingHorizontalL}`,
    borderBottom: `1px solid ${tokens.colorNeutralStroke2}`,
    backgroundColor: tokens.colorNeutralBackground2,
    color: tokens.colorNeutralForeground2,
    fontSize: tokens.fontSizeBase200,
  },
  continuityStatus: {
    flexGrow: 1,
  },
})

export function App() {
  const theme = useTeamsTheme()
  const styles = useStyles()
  const [messages, setMessages] = useState<Message[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const bottomRef = useRef<HTMLDivElement>(null)

  // Real Teams identity
  const currentUser = useTeamsUser()
  const {
    sessions,
    setSessions,
    activeSessionId,
    setActiveSessionId,
    continuityState,
    loadTranscript,
    createSession,
    addParticipant,
    persistMessage,
    persistSession,
    clearLocalData,
  } = useSessions(currentUser)

  // Render the local transcript before replacing it with the reconciled result.
  useEffect(() => {
    if (!activeSessionId) {
      setMessages([])
      return
    }
    let cancelled = false
    void loadTranscript(activeSessionId, local => {
      if (!cancelled) setMessages(toUiMessages(local))
    }).then(reconciled => {
      if (!cancelled) setMessages(toUiMessages(reconciled))
    })
    return () => { cancelled = true }
  }, [activeSessionId, loadTranscript])

  // Track pending dispatches for voice loading indicator. We use a Set of
  // turnIds (rather than a bare counter) so that when an assistant SSE
  // message arrives we only clear the spinner for replies that correspond
  // to one of THIS client's outstanding dispatches. Without correlation, a
  // co-participant's reply could prematurely clear our spinner in a
  // multi-participant session.
  const pendingTurnsRef = useRef<Set<string>>(new Set())
  const handleVoiceDispatch = useCallback((turnId: string) => {
    pendingTurnsRef.current.add(turnId)
    setIsLoading(true)
  }, [])
  // The bridge sends `dispatch.failed` when dispatchChat throws server-side.
  // Without this the spinner would stay on forever because the assistant SSE
  // event that normally clears it never arrives.
  const handleVoiceDispatchError = useCallback((turnId: string) => {
    pendingTurnsRef.current.delete(turnId)
    setIsLoading(pendingTurnsRef.current.size > 0)
  }, [])

  // SSE: listen for group messages from other participants
  useSessionMessages({
    sessionId: activeSessionId,
    onMessage: useCallback((msg: TranscriptMessage) => {
      if (activeSessionId) persistMessage(activeSessionId, msg)
      // Skip our own user messages — they're already in the list from sendMessage
      // Exception: in voicelive mode, voice user messages come only via SSE (bridge writes them)
      if (msg.role === 'user' && msg.userId === currentUser?.userId) {
        if (__SPEECH_PROVIDER__ !== 'voicelive' || msg.source !== 'voice') return
      }
      // Skip our own agent responses — sendMessage already adds them
      // Agent responses from our own sends come through /api/chat response
      // Only add agent responses from OTHER sources (e.g., bot chat)
      if (msg.role === 'assistant' && msg.source === 'agent') {
        // Spinner-clear policy:
        //   - turnId present  → only clear if it matches one of OUR
        //     outstanding voice dispatches; replies driven by another
        //     participant's voice turn must not affect our counter.
        //   - turnId absent   → typed (HTTP) dispatches don't carry a
        //     turnId. The HTTP path's only signal that the async backend
        //     finished is the assistant SSE event itself, so clear the
        //     spinner here — but ONLY if we don't currently have voice
        //     turns in flight, otherwise a co-participant's typed reply
        //     could prematurely clear our voice spinner. (Typed messages
        //     don't have correlation IDs, which is a pre-existing gap.)
        if (msg.turnId) {
          if (pendingTurnsRef.current.delete(msg.turnId)) {
            setIsLoading(pendingTurnsRef.current.size > 0)
          }
        } else if (pendingTurnsRef.current.size === 0) {
          setIsLoading(false)
        }
        setMessages(prev => {
          if (prev.some(m => m.id === msg.id)) return prev
          return [...prev, {
            id: msg.id,
            role: msg.role,
            text: msg.text,
            source: msg.source ?? 'text',
            timestamp: new Date(msg.timestamp).getTime(),
            displayName: msg.displayName,
            userId: msg.userId,
          }]
        })
        return
      }
      // Messages from other users (e.g., Teams chat via bot)
      setMessages(prev => {
        if (prev.some(m => m.id === msg.id)) return prev
        return [...prev, {
          id: msg.id,
          role: msg.role,
          text: msg.text,
          source: msg.source ?? 'text',
          timestamp: new Date(msg.timestamp).getTime(),
          displayName: msg.displayName,
          userId: msg.userId,
        }]
      })
    }, [activeSessionId, currentUser?.userId, persistMessage]),
  })

  // Auto-scroll
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const handleNewSession = useCallback(async (): Promise<string | null> => {
    if (!currentUser) return null
    const session = await createSession(currentUser.chatId)
    if (!session) return null
    setMessages([])
    return session.id
  }, [createSession, currentUser])

  const handleAddParticipant = useCallback(async (userId: string, displayName: string): Promise<void> => {
    if (!activeSessionId) {
      throw toAddParticipantError('NO_ACTIVE_SESSION', 'No active session')
    }

    await addParticipant(activeSessionId, userId, displayName)
  }, [activeSessionId, addParticipant])

  const sendMessage = useCallback(async (text: string, source: 'voice' | 'text') => {
    const trimmed = text.trim()
    if (!trimmed || isLoading) return

    // In voicelive mode, voice turns are handled by the bridge — skip /api/chat POST
    if (__SPEECH_PROVIDER__ === 'voicelive' && source === 'voice') return

    // Auto-create a session if none exists
    let sessionId = activeSessionId
    if (!sessionId) {
      if (!currentUser) return
      const session = await createSession(currentUser.chatId)
      if (!session) return
      sessionId = session.id
    }

    const userMessageId = crypto.randomUUID()
    const userMessage: Message = {
      id: userMessageId,
      role: 'user',
      text: trimmed,
      source,
      timestamp: Date.now(),
      displayName: currentUser?.displayName,
      userId: currentUser?.userId,
    }
    setMessages(prev => [...prev, userMessage])
    persistMessage(sessionId, toTranscriptMessage(userMessage))
    setIsLoading(true)

    try {
      const resp = await apiFetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          text: trimmed,
          sessionId,
          source,
          chatId: currentUser?.chatId,
          messageId: userMessageId,
        }),
      })

      if (!resp.ok) throw new Error(`Server error: ${resp.status}`)

      const data = await resp.json()

      // Update session title if auto-generated by server
      if (data.title) {
        setSessions(prev => prev.map(session => {
          if (session.id !== sessionId) return session
          const updated = { ...session, title: data.title }
          persistSession(updated)
          return updated
        }))
      }

      if (data.text) {
        const agentMessage: Message = {
          id: data.messageId || crypto.randomUUID(),
          role: 'assistant',
          text: data.text,
          source: 'text',
          timestamp: Date.now(),
        }
        setMessages(prev => {
          if (prev.some(m => m.id === agentMessage.id)) return prev
          return [...prev, agentMessage]
        })
        persistMessage(sessionId, toTranscriptMessage(agentMessage))
        setIsLoading(false)
      }
      // For async backends (DirectLine, Copilot Studio) isLoading stays true
      // until the SSE handler receives the assistant reply.
    } catch (err) {
      const errorMessage: Message = {
        id: crypto.randomUUID(),
        role: 'assistant',
        text: `Error: ${err instanceof Error ? err.message : 'Something went wrong'}`,
        source: 'text',
        timestamp: Date.now(),
      }
      setMessages(prev => [...prev, errorMessage])
      setIsLoading(false)
    }
  }, [activeSessionId, createSession, currentUser, isLoading, persistMessage, persistSession, setSessions])

  const continuityMessage = {
    loading: 'Device-local continuity: loading cache.',
    'local-fallback': 'Device-local continuity: showing cached data while server reconciliation is unavailable.',
    'server-reconciled': 'Device-local continuity: reconciled with the server.',
    cleared: 'Device-local continuity: device cache cleared. Server sessions were not deleted.',
  }[continuityState]

  const ensureSession = useCallback(async (): Promise<string | null> => {
    if (activeSessionId) return activeSessionId
    return handleNewSession()
  }, [activeSessionId, handleNewSession])

  return (
    <FluentProvider theme={theme} style={{ height: '100%' }}>
      <div className={styles.root}>
        <SessionBar
          sessions={sessions}
          activeSessionId={activeSessionId}
          onSessionSelect={setActiveSessionId}
          onNewSession={handleNewSession}
          onAddParticipant={handleAddParticipant}
        />
        <div className={styles.continuityBar} role="status" aria-live="polite">
          <span className={styles.continuityStatus}>{continuityMessage}</span>
          <Button
            appearance="subtle"
            size="small"
            icon={<DeleteRegular />}
            disabled={continuityState === 'loading'}
            onClick={() => { void clearLocalData() }}
          >
            Clear device data
          </Button>
        </div>
        <ChatPanel messages={messages} isLoading={isLoading} bottomRef={bottomRef} onSend={(text) => sendMessage(text, 'text')} />
        <div className={styles.inputBar}>
          <VoiceInput onResult={(text) => sendMessage(text, 'voice')} disabled={isLoading} sessionId={activeSessionId} onEnsureSession={ensureSession} onDispatch={handleVoiceDispatch} onDispatchError={handleVoiceDispatchError} />
          <TextInput onSend={(text) => sendMessage(text, 'text')} disabled={isLoading} />
        </div>
      </div>
    </FluentProvider>
  )
}
