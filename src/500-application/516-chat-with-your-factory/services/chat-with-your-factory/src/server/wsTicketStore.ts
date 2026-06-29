import { randomBytes } from 'crypto'

/**
 * Short-lived, single-use tickets for authenticating WebSocket upgrades.
 *
 * Browsers can't set Authorization headers on `new WebSocket(...)`, and
 * passing the SSO bearer token in the query string leaks credentials into
 * server access logs, proxies, and browser history. Instead, the client
 * exchanges its bearer token (sent in a normal Authorization header on a
 * POST) for an opaque random ticket, then presents that ticket in the WS
 * URL. The bridge consumes the ticket exactly once and recovers the
 * original user context + SSO token from in-memory state.
 *
 * Tickets are:
 *   - high-entropy (256 bits) — unguessable
 *   - single-use — `consume` deletes on read
 *   - short-lived — TTL_MS, with periodic eviction of expired entries
 *   - session-bound — `consume` requires the caller to supply the
 *     expected sessionId, so a ticket minted for session A cannot be
 *     replayed against session B. The userId is recovered from the
 *     ticket itself (the WS upgrade handler has no other source of
 *     identity), so it isn't re-validated here; ACL enforcement at
 *     mint time guarantees the minting user was authorized for the
 *     bound session.
 */

const TTL_MS = 30_000

interface TicketEntry {
  userId: string
  displayName: string
  tenantId?: string
  sessionId: string
  ssoToken: string
  expiresAt: number
}

const tickets = new Map<string, TicketEntry>()

// Periodic eviction so abandoned tickets don't accumulate. Calling .unref()
// on the timer handle ensures it never holds the process open during
// shutdown (the timer remains active but doesn't keep the event loop alive).
const sweepInterval = setInterval(() => {
  const now = Date.now()
  for (const [id, entry] of tickets) {
    if (entry.expiresAt <= now) tickets.delete(id)
  }
}, TTL_MS)
sweepInterval.unref()

export function mintTicket(entry: Omit<TicketEntry, 'expiresAt'>): string {
  const id = randomBytes(32).toString('base64url')
  tickets.set(id, { ...entry, expiresAt: Date.now() + TTL_MS })
  return id
}

export function consumeTicket(
  id: string,
  expectedSessionId: string,
): Omit<TicketEntry, 'expiresAt'> | null {
  if (!id) return null
  const entry = tickets.get(id)
  if (!entry) return null
  // Always delete on first read — single-use semantics, even on validation
  // failure, to prevent brute-force enumeration of session bindings.
  tickets.delete(id)
  if (entry.expiresAt <= Date.now()) return null
  if (entry.sessionId !== expectedSessionId) return null
  const { expiresAt: _expiresAt, ...rest } = entry
  void _expiresAt
  return rest
}
