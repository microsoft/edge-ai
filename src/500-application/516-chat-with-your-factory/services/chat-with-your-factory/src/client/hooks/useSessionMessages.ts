import { useEffect, useRef, useCallback } from 'react'
import type { TranscriptMessage } from '../../shared/types.js'
import { apiFetch } from '../utils/apiFetch.js'

function debugEnabled(): boolean {
  try {
    return typeof localStorage !== 'undefined' &&
      localStorage.getItem('sse:debug') === 'true'
  } catch {
    return false
  }
}

interface UseSessionMessagesOptions {
  sessionId: string | null
  onMessage: (message: TranscriptMessage) => void
}

export function useSessionMessages({ sessionId, onMessage }: UseSessionMessagesOptions): void {
  const onMessageRef = useRef(onMessage)
  onMessageRef.current = onMessage
  const eventSourceRef = useRef<EventSource | null>(null)
  const retryTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const reconnectAttemptRef = useRef(0)
  const connectGenRef = useRef(0)

  const clearRetryTimer = useCallback(() => {
    if (retryTimerRef.current) {
      clearTimeout(retryTimerRef.current)
      retryTimerRef.current = null
    }
  }, [])

  const connect = useCallback(async (sid: string) => {
    clearRetryTimer()
    const connectGen = ++connectGenRef.current

    // Close any existing connection and detach handlers to avoid scheduling
    // reconnects from stale EventSource instances.
    if (eventSourceRef.current) {
      eventSourceRef.current.onopen = null
      eventSourceRef.current.onerror = null
      eventSourceRef.current.close()
      eventSourceRef.current = null
    }

    // Mint a short-lived one-time ticket so EventSource does not put bearer
    // tokens in the URL query string.
    const ticketRes = await apiFetch(`/api/sessions/${sid}/sse-ticket`, {
      method: 'POST',
    })
    if (connectGen !== connectGenRef.current) return
    if (!ticketRes.ok) {
      console.warn('[SSE] Failed to mint SSE ticket:', ticketRes.status)
      const attempt = Math.min(reconnectAttemptRef.current + 1, 6)
      reconnectAttemptRef.current = attempt
      const delayMs = Math.min(1000 * (2 ** (attempt - 1)), 15_000)
      retryTimerRef.current = setTimeout(() => {
        void connect(sid)
      }, delayMs)
      return
    }
    const { ticket } = (await ticketRes.json()) as { ticket: string }
    if (connectGen !== connectGenRef.current) return
    const url = `/api/sessions/${sid}/events?sseTicket=${encodeURIComponent(ticket)}`

    console.log('[SSE] Connecting to', url.split('?')[0], '| hasTicket:', true)
    const es = new EventSource(url, { withCredentials: true })

    es.addEventListener('message', (event) => {
      if (debugEnabled()) {
        console.log('[SSE] Received message event')
      }
      try {
        const msg: TranscriptMessage = JSON.parse(event.data)
        onMessageRef.current(msg)
      } catch {
        console.warn('[SSE] Failed to parse message:', event.data)
      }
    })

    es.onopen = () => {
      reconnectAttemptRef.current = 0
      console.log('[SSE] Connection opened')
    }

    es.onerror = (e) => {
      console.warn('[SSE] Connection error, readyState:', es.readyState, e)
      // One-time SSE tickets are consumed on first connect. Browser-native
      // EventSource retries re-use the same URL (same spent ticket), so we
      // force-close and reconnect with a freshly minted ticket.
      if (eventSourceRef.current !== es) return
      es.onopen = null
      es.onerror = null
      es.close()
      eventSourceRef.current = null

      const attempt = Math.min(reconnectAttemptRef.current + 1, 6)
      reconnectAttemptRef.current = attempt
      const delayMs = Math.min(1000 * (2 ** (attempt - 1)), 15_000)
      retryTimerRef.current = setTimeout(() => {
        void connect(sid)
      }, delayMs)
    }

    eventSourceRef.current = es
  }, [clearRetryTimer])

  useEffect(() => {
    if (!sessionId) {
      clearRetryTimer()
      eventSourceRef.current?.close()
      eventSourceRef.current = null
      reconnectAttemptRef.current = 0
      return
    }

    reconnectAttemptRef.current = 0
    void connect(sessionId)

    return () => {
      clearRetryTimer()
      eventSourceRef.current?.close()
      eventSourceRef.current = null
      reconnectAttemptRef.current = 0
    }
  }, [sessionId, connect, clearRetryTimer])
}
