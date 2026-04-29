import { createRemoteJWKSet, jwtVerify } from 'jose'
import type { Request, Response, NextFunction } from 'express'
import { sanitizeDisplayName } from './sessionsHandler.js'
import { consumeSseTicket } from './sseTicketStore.js'

const CLIENT_ID = process.env.TEAMS_APP_ID!
const IDENTIFIER_URI = `api://${process.env.DEVTUNNEL_DOMAIN}/${CLIENT_ID}`

// Use the "common" JWKS endpoint so tokens from any AAD tenant are accepted.
const JWKS = createRemoteJWKSet(
  new URL('https://login.microsoftonline.com/common/discovery/v2.0/keys')
)

export async function requireAuth(req: Request, res: Response, next: NextFunction): Promise<void> {
  const authHeader = req.headers.authorization
  const sseTicketId = req.query.sseTicket as string | undefined
  const bearerToken = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : undefined

  // EventSource cannot set Authorization headers. Accept a short-lived,
  // single-use SSE ticket in the query string and recover user context from
  // server-side state instead of passing the bearer token in the URL.
  if (!bearerToken && sseTicketId) {
    const ticket = consumeSseTicket(sseTicketId, req.path)
    if (!ticket) {
      res.status(401).json({ error: 'Invalid or expired SSE ticket' })
      return
    }
    req.user = {
      userId: ticket.userId,
      displayName: ticket.displayName,
      tenantId: ticket.tenantId,
    }
    req.ssoToken = ticket.ssoToken
    next()
    return
  }

  if (bearerToken) {
    try {
      const { payload } = await jwtVerify(bearerToken, JWKS, {
        audience: [CLIENT_ID, IDENTIFIER_URI],
        clockTolerance: 30,
      })
      // Validate issuer dynamically — accept both v1.0 and v2.0 formats (tenant ID varies per user).
      const iss = payload.iss ?? ''
      const isV2 = /^https:\/\/login\.microsoftonline\.com\/[0-9a-f-]+\/v2\.0$/.test(iss)
      const isV1 = /^https:\/\/sts\.windows\.net\/[0-9a-f-]+\/$/.test(iss)
      if (!isV2 && !isV1) {
        throw new Error(`Unexpected issuer: ${iss}`)
      }
      req.user = {
        userId: payload.oid as string,
        displayName: (payload.name as string) || '',
        tenantId: payload.tid as string,
      }
      req.ssoToken = bearerToken
      next()
      return
    } catch (err) {
      console.error('Token validation failed:', err)
      res.status(401).json({ error: 'Invalid or expired token' })
      return
    }
  }

  // Dev bypass: when SKIP_AUTH=true and no Bearer token, synthesize a dev user
  if (process.env.SKIP_AUTH === 'true') {
    req.user = {
      userId: (req.headers['x-user-id'] as string) || 'dev-user',
      displayName: sanitizeDisplayName(req.headers['x-user-name'] as string, 'Dev User'),
    }
    next()
    return
  }

  res.status(401).json({ error: 'Authentication required' })
}
