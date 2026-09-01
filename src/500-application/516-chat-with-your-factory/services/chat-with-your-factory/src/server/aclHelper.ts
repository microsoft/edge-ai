import type { Response } from 'express'
import type { Session } from '../shared/types.js'
import { sessionStore } from './sessionStore.js'

/**
 * Retrieves a session and checks that the given user is a participant.
 * Sends 404 or 403 and returns null if the check fails.
 */
export function getAuthorizedSession(
  res: Response,
  sessionId: string,
  userId: string,
): Session | null {
  const session = sessionStore.getSession(sessionId)
  if (!session) {
    res.status(404).json({ error: 'Session not found' })
    return null
  }
  if (!session.participants.includes(userId)) {
    res.status(403).json({ error: 'Not a participant of this session' })
    return null
  }
  return session
}

/**
 * Non-Express variant: returns the session if the user is a participant,
 * or null otherwise. Does not write to any HTTP response.
 */
export function getAuthorizedSessionFor(
  sessionId: string,
  userId: string,
): Session | null {
  const session = sessionStore.getSession(sessionId)
  if (!session) return null
  if (!session.participants.includes(userId)) return null
  return session
}
