import { createRemoteJWKSet, jwtVerify } from 'jose'
import type { Request, Response, NextFunction } from 'express'
import { sanitizeDisplayName } from './sessionsHandler.js'
import { consumeSseTicket } from './sseTicketStore.js'

const AUTH_AUDIENCES = (process.env.TEAMS_AUTH_AUDIENCES || '')
  .split(',')
  .map((value) => value.trim())
  .filter(Boolean)

function isLocalHost(host: string | undefined): boolean {
  if (!host) return false
  const normalized = host.toLowerCase()
  return normalized === 'localhost' || normalized === '127.0.0.1' || normalized === '::1'
}

function isLoopbackAddress(addr: string | undefined): boolean {
  if (!addr) return false
  return addr === '127.0.0.1' || addr === '::1' || addr === '::ffff:127.0.0.1'
}

function isHostedRuntime(): boolean {
  if (process.env.WEBSITE_SITE_NAME || process.env.WEBSITE_INSTANCE_ID) {
    return true
  }

  const appHostname = process.env.APP_HOSTNAME?.toLowerCase()
  if (!appHostname) return false
  return !isLocalHost(appHostname)
}

function allowLocalAuthBypass(req: Request): boolean {
  if (process.env.SKIP_AUTH !== 'true') return false
  if (isHostedRuntime()) return false
  return isLocalHost(req.hostname) && isLoopbackAddress(req.socket.remoteAddress)
}

// Explicit standalone mode. Synthesizes a dev user for ALL requests regardless
// of origin. Insecure by design — only for development/demo deployments that run
// without Teams/AAD (for example docker-compose or an isolated edge cluster).
function allowStandaloneAuth(): boolean {
  return process.env.AUTH_REQUIRED === 'false'
}

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
        audience: AUTH_AUDIENCES,
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

  // Explicit standalone mode (AUTH_REQUIRED=false): synthesize a dev user for
  // all requests. Used for Teams-less development and demo deployments.
  if (allowStandaloneAuth()) {
    req.user = {
      userId: (req.headers['x-user-id'] as string) || 'dev-user',
      displayName: sanitizeDisplayName(req.headers['x-user-name'] as string, 'Dev User'),
    }
    next()
    return
  }

  // Local-only dev bypass. Hosted runtimes fail closed even if SKIP_AUTH is set.
  if (allowLocalAuthBypass(req)) {
    req.user = {
      userId: (req.headers['x-user-id'] as string) || 'dev-user',
      displayName: sanitizeDisplayName(req.headers['x-user-name'] as string, 'Dev User'),
    }
    next()
    return
  }

  if (process.env.SKIP_AUTH === 'true') {
    res.status(401).json({
      error:
        'Authentication required: SKIP_AUTH is only allowed for true loopback (localhost) traffic.',
    })
    return
  }

  res.status(401).json({ error: 'Authentication required' })
}
