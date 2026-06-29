import { randomBytes } from 'crypto'

const TTL_MS = 30_000

interface SseTicketEntry {
  userId: string
  displayName: string
  tenantId?: string
  ssoToken: string
  expectedPath: string
  expiresAt: number
}

const tickets = new Map<string, SseTicketEntry>()

const sweepInterval = setInterval(() => {
  const now = Date.now()
  for (const [id, entry] of tickets) {
    if (entry.expiresAt <= now) tickets.delete(id)
  }
}, TTL_MS)
sweepInterval.unref()

export function mintSseTicket(entry: Omit<SseTicketEntry, 'expiresAt'>): string {
  const id = randomBytes(32).toString('base64url')
  tickets.set(id, { ...entry, expiresAt: Date.now() + TTL_MS })
  return id
}

export function consumeSseTicket(
  id: string,
  expectedPath: string,
): Omit<SseTicketEntry, 'expiresAt' | 'expectedPath'> | null {
  if (!id) return null
  const entry = tickets.get(id)
  if (!entry) return null
  tickets.delete(id)
  if (entry.expiresAt <= Date.now()) return null
  if (entry.expectedPath !== expectedPath) return null
  const { expiresAt: _expiresAt, expectedPath: _expectedPath, ...rest } = entry
  void _expiresAt
  void _expectedPath
  return rest
}
