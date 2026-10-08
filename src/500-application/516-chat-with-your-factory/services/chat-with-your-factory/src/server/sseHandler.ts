import type { Request, Response } from 'express'
import { randomUUID } from 'crypto'
import { sseRegistry } from './sseRegistry.js'
import { getAuthorizedSession } from './aclHelper.js'

export function sseHandler(req: Request, res: Response): void {
  const sessionId = req.params.sessionId as string
  const userId = req.user?.userId
  console.log('[SSE] Handler hit | sessionId:', sessionId, '| userId:', userId)
  if (!userId) { res.status(401).json({ error: 'Unauthorized' }); return }

  // Enforce session ACL — only existing participants may subscribe
  const session = getAuthorizedSession(res, sessionId, userId)
  if (!session) return

  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'X-Accel-Buffering': 'no',
  })
  res.write('retry: 3000\n:ok\n\n')

  // Send heartbeat every 15 s to prevent HTTP/2 proxy idle-stream resets
  const heartbeat = setInterval(() => {
    try {
      res.write(':\n\n')
    } catch {
      clearInterval(heartbeat)
    }
  }, 15_000)

  const clientId = randomUUID()
  sseRegistry.addClient(sessionId, clientId, res)

  req.on('close', () => {
    clearInterval(heartbeat)
    sseRegistry.removeClient(sessionId, clientId)
  })
}
