import type { Response } from 'express'
import type { TranscriptMessage } from '../shared/types.js'

const registry = new Map<string, Map<string, Response>>()

export const sseRegistry = {
  addClient(sessionId: string, clientId: string, res: Response): void {
    if (!registry.has(sessionId)) {
      registry.set(sessionId, new Map())
    }
    registry.get(sessionId)!.set(clientId, res)
    console.log(`[SSE] Client ${clientId} joined session ${sessionId} (${registry.get(sessionId)!.size} clients)`)
  },

  removeClient(sessionId: string, clientId: string): void {
    const clients = registry.get(sessionId)
    if (!clients) return
    clients.delete(clientId)
    if (clients.size === 0) registry.delete(sessionId)
    console.log(`[SSE] Client ${clientId} left session ${sessionId}`)
  },

  broadcast(sessionId: string, message: TranscriptMessage): void {
    const clients = registry.get(sessionId)
    if (!clients || clients.size === 0) return

    const payload = `event: message\ndata: ${JSON.stringify(message)}\n\n`
    for (const [clientId, res] of clients) {
      try {
        res.write(payload)
      } catch {
        clients.delete(clientId)
      }
    }
  },

  getClientCount(sessionId: string): number {
    return registry.get(sessionId)?.size ?? 0
  },
}
