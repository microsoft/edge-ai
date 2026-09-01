import type { Request, Response } from 'express'
import { getAuthorizedSession } from './aclHelper.js'
import { sessionStore } from './sessionStore.js'

export async function getTranscript(req: Request, res: Response): Promise<void> {
  const { userId } = req.user

  const session = getAuthorizedSession(res, req.params.sessionId as string, userId)
  if (!session) return

  try {
    const messages = sessionStore.getMessages(session.id)
    res.json(messages)
  } catch (error) {
    console.error('Transcript retrieval error:', error)
    res.status(500).json({ error: 'Failed to retrieve transcript' })
  }
}
