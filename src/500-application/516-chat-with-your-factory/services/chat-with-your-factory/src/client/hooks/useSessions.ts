import { useCallback, useEffect, useRef, useState } from 'react'
import type { Dispatch, SetStateAction } from 'react'
import type {
  DeviceContinuityState,
  Session,
  TranscriptMessage,
  UserContext,
} from '../../shared/types.js'
import {
  addParticipantErrorCodeFromStatus,
  isAddParticipantError,
  toAddParticipantError,
} from '../../shared/addParticipantErrors.js'
import { cleanLogging } from '../../shared/logging.js'
import { IndexedDbSessionStore } from '../storage/indexedDbSessionStore.js'
import { apiFetch } from '../utils/apiFetch.js'

function timestampToMilliseconds(value: unknown): number {
  if (typeof value === 'number') return value
  if (typeof value !== 'string') return 0
  const parsed = Date.parse(value)
  if (!Number.isNaN(parsed)) return parsed
  const numeric = Number(value)
  return Number.isFinite(numeric) ? numeric : 0
}

function mergeSessions(local: Session[], server: Session[]): Session[] {
  const sessions = new Map(local.map(session => [session.id, session]))
  for (const session of server) sessions.set(session.id, session)
  return [...sessions.values()].sort((left, right) =>
    timestampToMilliseconds(right.lastActivityAt) - timestampToMilliseconds(left.lastActivityAt),
  )
}

function mergeMessages(local: TranscriptMessage[], server: TranscriptMessage[]): TranscriptMessage[] {
  const messages = new Map(local.map(message => [message.id, message]))
  for (const message of server) messages.set(message.id, message)
  return [...messages.values()].sort((left, right) =>
    timestampToMilliseconds(left.timestamp) - timestampToMilliseconds(right.timestamp),
  )
}

export interface UseSessionsResult {
  sessions: Session[]
  setSessions: Dispatch<SetStateAction<Session[]>>
  activeSessionId: string | null
  setActiveSessionId: Dispatch<SetStateAction<string | null>>
  continuityState: DeviceContinuityState
  loadTranscript: (
    sessionId: string,
    onLocal: (messages: TranscriptMessage[]) => void,
  ) => Promise<TranscriptMessage[]>
  createSession: (chatId?: string | null) => Promise<Session | null>
  addParticipant: (sessionId: string, userId: string, displayName: string) => Promise<Session>
  persistMessage: (sessionId: string, message: TranscriptMessage) => void
  persistSession: (session: Session) => void
  deleteLocalSession: (sessionId: string) => Promise<void>
  clearLocalData: () => Promise<void>
}

export function useSessions(currentUser: UserContext | null): UseSessionsResult {
  const [sessions, setSessions] = useState<Session[]>([])
  const [activeSessionId, setActiveSessionId] = useState<string | null>(null)
  const [continuityState, setContinuityState] = useState<DeviceContinuityState>('loading')
  const localCacheReadyRef = useRef(false)
  const ownerMaintenanceRef = useRef<Promise<void>>(Promise.resolve())
  const storeRef = useRef<IndexedDbSessionStore | null>(null)
  if (!storeRef.current) storeRef.current = new IndexedDbSessionStore()
  const store = storeRef.current

  const persistSession = useCallback((session: Session) => {
    if (!localCacheReadyRef.current) return
    void store.saveSession(session).catch(error => {
      cleanLogging.Warn('device-continuity', 'Session write failed', error)
    })
  }, [store])

  const persistMessage = useCallback((sessionId: string, message: TranscriptMessage) => {
    if (!localCacheReadyRef.current) return
    void store.saveMessage(sessionId, message).catch(error => {
      cleanLogging.Warn('device-continuity', 'Message write failed', error)
    })
  }, [store])

  useEffect(() => {
    localCacheReadyRef.current = false
    setSessions([])
    setActiveSessionId(null)
    setContinuityState('loading')
    if (!currentUser) return

    let cancelled = false
    void (async () => {
      let localCacheReady = false
      const ownerMaintenance = ownerMaintenanceRef.current.then(async () => {
        await store.assertOwner(currentUser.userId)
        await store.purgeExpired()
      })
      ownerMaintenanceRef.current = ownerMaintenance.catch(() => {})
      try {
        await ownerMaintenance
        if (cancelled) return
        localCacheReady = true
        localCacheReadyRef.current = true
      } catch (error) {
        cleanLogging.Warn('device-continuity', 'Local maintenance failed', error)
      }
      if (cancelled) return

      let local: Session[] = []
      if (localCacheReady) {
        try {
          local = await store.list(currentUser.userId)
        } catch (error) {
          cleanLogging.Warn('device-continuity', 'Local session hydration failed', error)
        }
      }
      if (cancelled) return
      setSessions(local)
      setActiveSessionId(local.find(session => session.status === 'active')?.id ?? local[0]?.id ?? null)
      setContinuityState('local-fallback')

      const chatIdQuery = currentUser.chatId
        ? `?chatId=${encodeURIComponent(currentUser.chatId)}`
        : ''
      try {
        const response = await apiFetch(`/api/sessions${chatIdQuery}`)
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        const server = await response.json() as Session[]
        if (cancelled) return
        const serverIds = new Set(server.map(session => session.id))
        const resumable = local.filter(session =>
          !serverIds.has(session.id) &&
          Boolean(session.resumeToken) &&
          Boolean(session.threadId || session.conversationId),
        )
        const resumed: Session[] = []
        for (const session of resumable) {
          if (cancelled) return
          try {
            const resumeResponse = await apiFetch(`/api/sessions/${session.id}/resume`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ session }),
            })
            if (!resumeResponse.ok) continue
            const adopted = await resumeResponse.json() as Session
            if (cancelled) return
            resumed.push(adopted)
            persistSession(adopted)
          } catch (error) {
            cleanLogging.Warn('device-continuity', 'Cached session resume failed', error)
          }
        }
        if (cancelled) return
        const reconciledServer = mergeSessions(server, resumed)
        const reconciled = mergeSessions(local, reconciledServer)
        setSessions(reconciled)
        const serverActive = reconciledServer.find(session => session.status === 'active')
        setActiveSessionId(previous => serverActive?.id ?? previous ?? reconciled[0]?.id ?? null)
        for (const session of server) persistSession(session)
        setContinuityState('server-reconciled')
      } catch (error) {
        cleanLogging.Error('device-continuity', 'Server session reconciliation failed', error)
      }
    })()

    return () => { cancelled = true }
  }, [currentUser, persistSession, store])

  const loadTranscript = useCallback(async (
    sessionId: string,
    onLocal: (messages: TranscriptMessage[]) => void,
  ): Promise<TranscriptMessage[]> => {
    let local: TranscriptMessage[] = []
    try {
      local = mergeMessages(await store.getMessages(sessionId), [])
    } catch (error) {
      cleanLogging.Warn('device-continuity', 'Local transcript hydration failed', error)
    }
    onLocal(local)

    try {
      const response = await apiFetch(`/api/transcript/${sessionId}`)
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const server = await response.json() as TranscriptMessage[]
      for (const message of server) persistMessage(sessionId, message)
      setContinuityState('server-reconciled')
      return mergeMessages(local, server)
    } catch (error) {
      cleanLogging.Warn('device-continuity', 'Server transcript unavailable; using local cache', error)
      setContinuityState('local-fallback')
      return local
    }
  }, [persistMessage, store])

  const createSession = useCallback(async (chatId?: string | null): Promise<Session | null> => {
    try {
      const response = await apiFetch('/api/sessions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ chatId: chatId ?? null }),
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const session = await response.json() as Session
      persistSession(session)
      setSessions(previous => [session, ...previous.filter(item => item.id !== session.id)])
      setActiveSessionId(session.id)
      setContinuityState('server-reconciled')
      return session
    } catch (error) {
      cleanLogging.Error('device-continuity', 'Session creation failed', error)
      return null
    }
  }, [persistSession])

  const addParticipant = useCallback(async (
    sessionId: string,
    userId: string,
    displayName: string,
  ): Promise<Session> => {
    try {
      const response = await apiFetch(`/api/sessions/${sessionId}/participants`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, displayName }),
      })
      if (!response.ok) {
        let message = 'Failed to add participant'
        try {
          const body = await response.json() as { error?: string }
          if (typeof body.error === 'string' && body.error.trim().length > 0) message = body.error
        } catch {
          // Keep the default for non-JSON responses.
        }
        throw toAddParticipantError(
          addParticipantErrorCodeFromStatus(response.status),
          message,
          response.status,
        )
      }
      const updated = await response.json() as Session
      persistSession(updated)
      setSessions(previous => previous.map(session => session.id === updated.id ? updated : session))
      return updated
    } catch (error) {
      if (isAddParticipantError(error)) throw error
      throw toAddParticipantError('NETWORK', 'Network error while adding participant')
    }
  }, [persistSession])

  const deleteLocalSession = useCallback(async (sessionId: string): Promise<void> => {
    await store.deleteSession(sessionId)
  }, [store])

  const clearLocalData = useCallback(async (): Promise<void> => {
    await store.clearAll()
    setContinuityState('cleared')
  }, [store])

  return {
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
    deleteLocalSession,
    clearLocalData,
  }
}
