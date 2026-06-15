import { useState, useCallback, useRef, useEffect } from 'react'
import { FluentProvider, makeStyles, tokens } from '@fluentui/react-components'
import { ChatPanel } from './components/ChatPanel.js'
import { VoiceInput } from './components/VoiceInput.js'
import { TextInput } from './components/TextInput.js'
import { SessionBar } from './components/SessionBar.js'
import { useTeamsTheme } from './hooks/useTeamsTheme.js'
import { useTeamsUser } from './hooks/useTeamsUser.js'
import { useSessionMessages } from './hooks/useSessionMessages.js'
import type { Session, TranscriptMessage } from '../shared/types.js'
import {
  addParticipantErrorCodeFromStatus,
  isAddParticipantError,
  toAddParticipantError,
} from '../shared/addParticipantErrors.js'
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
})

export function App() {
  const theme = useTeamsTheme()
  const styles = useStyles()
  const [messages, setMessages] = useState<Message[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const bottomRef = useRef<HTMLDivElement>(null)

  // Real Teams identity
  const currentUser = useTeamsUser()
  const [sessions, setSessions] = useState<Session[]>([])
  const [activeSessionId, setActiveSessionId] = useState<string | null>(null)

  // Fetch sessions when user resolves
  useEffect(() => {
    if (!currentUser) return

    // If we're in a Teams chat, check for a session linked to this chatId first
    const chatIdParam = currentUser.chatId ? `?chatId=${encodeURIComponent(currentUser.chatId)}` : ''
    apiFetch(`/api/sessions${chatIdParam}`)
      .then(r => { if (!r.ok) throw new Error(`HTTP ${r.status}`); return r.json() })
      .then((data: Session[]) => {
        setSessions(data)
        const active = data.find(s => s.status === 'active')
        setActiveSessionId(active?.id ?? data[0]?.id ?? null)
      })
      .catch(console.error)
  }, [currentUser])

  // Load transcript when active session changes
  useEffect(() => {
    if (!activeSessionId) {
      setMessages([])
      return
    }
    apiFetch(`/api/transcript/${activeSessionId}`)
      .then(r => { if (!r.ok) throw new Error(`HTTP ${r.status}`); return r.json() })
      .then((data: TranscriptMessage[]) => {
        setMessages(data.map(m => ({
          id: m.id,
          role: m.role,
          text: m.text,
          source: m.source ?? 'text',
          timestamp: new Date(m.timestamp).getTime(),
          displayName: m.displayName,
          userId: m.userId,
        })))
      })
      .catch(console.error)
  }, [activeSessionId, currentUser])

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
    }, [currentUser?.userId]),
  })

  // Auto-scroll
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const handleNewSession = useCallback(async (): Promise<string | null> => {
    if (!currentUser) return null
    try {
      const resp = await apiFetch('/api/sessions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ chatId: currentUser.chatId }),
      })
      const session: Session = await resp.json()
      setSessions(prev => [session, ...prev])
      setActiveSessionId(session.id)
      setMessages([])
      return session.id
    } catch (err) {
      console.error('Failed to create session:', err)
      return null
    }
  }, [currentUser])

  const handleAddParticipant = useCallback(async (userId: string, displayName: string): Promise<void> => {
    if (!activeSessionId) {
      throw toAddParticipantError('NO_ACTIVE_SESSION', 'No active session')
    }

    try {
      const resp = await apiFetch(`/api/sessions/${activeSessionId}/participants`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, displayName }),
      })

      if (!resp.ok) {
        let serverMessage = 'Failed to add participant'
        try {
          const body = await resp.json() as { error?: string }
          if (typeof body?.error === 'string' && body.error.trim().length > 0) {
            serverMessage = body.error
          }
        } catch {
          // non-JSON response, keep default message
        }

        const code = addParticipantErrorCodeFromStatus(resp.status)

        throw toAddParticipantError(code, serverMessage, resp.status)
      }

      const updated: Session = await resp.json()
      setSessions(prev => prev.map(s => s.id === updated.id ? updated : s))
    } catch (err) {
      if (isAddParticipantError(err)) {
        throw err
      }
      throw toAddParticipantError('NETWORK', 'Network error while adding participant')
    }
  }, [activeSessionId, currentUser])

  const sendMessage = useCallback(async (text: string, source: 'voice' | 'text') => {
    const trimmed = text.trim()
    if (!trimmed || isLoading) return

    // In voicelive mode, voice turns are handled by the bridge — skip /api/chat POST
    if (__SPEECH_PROVIDER__ === 'voicelive' && source === 'voice') return

    // Auto-create a session if none exists
    let sessionId = activeSessionId
    if (!sessionId) {
      if (!currentUser) return
      try {
        const resp = await apiFetch('/api/sessions', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ chatId: currentUser.chatId }),
        })
        const session: Session = await resp.json()
        setSessions(prev => [session, ...prev])
        setActiveSessionId(session.id)
        sessionId = session.id
      } catch (err) {
        console.error('Failed to create session:', err)
        return
      }
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
    setIsLoading(true)

    try {
      const resp = await apiFetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: trimmed, sessionId, source, chatId: currentUser?.chatId }),
      })

      if (!resp.ok) throw new Error(`Server error: ${resp.status}`)

      const data = await resp.json()

      // Update session title if auto-generated by server
      if (data.title) {
        setSessions(prev => prev.map(s =>
          s.id === sessionId ? { ...s, title: data.title } : s
        ))
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
  }, [activeSessionId, isLoading, currentUser])

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
        <ChatPanel messages={messages} isLoading={isLoading} bottomRef={bottomRef} onSend={(text) => sendMessage(text, 'text')} />
        <div className={styles.inputBar}>
          <VoiceInput onResult={(text) => sendMessage(text, 'voice')} disabled={isLoading} sessionId={activeSessionId} onEnsureSession={ensureSession} onDispatch={handleVoiceDispatch} onDispatchError={handleVoiceDispatchError} />
          <TextInput onSend={(text) => sendMessage(text, 'text')} disabled={isLoading} />
        </div>
      </div>
    </FluentProvider>
  )
}
