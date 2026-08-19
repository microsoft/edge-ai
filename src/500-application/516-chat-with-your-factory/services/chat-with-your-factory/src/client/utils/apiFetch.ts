import * as microsoftTeams from '@microsoft/teams-js'
import { decodeJwtPayload } from './jwtPayload.js'

let teamsContext: { userId: string; displayName: string } | null = null
let contextPromise: Promise<void> | null = null
let cachedToken: { token: string; expMs: number } | null = null
let inFlightToken: Promise<string | null> | null = null

const TOKEN_REFRESH_BUFFER_MS = 120_000
const MALFORMED_EXPIRY_RETRY_MS = 300_000

function isLocalFallbackHost(): boolean {
  const hostname = window.location.hostname.toLowerCase()
  return (
    hostname === 'localhost' ||
    hostname === '127.0.0.1' ||
    hostname === '::1' ||
    hostname.endsWith('.use.devtunnels.ms')
  )
}

function resolveTeamsContext(): Promise<void> {
  if (!contextPromise) {
    contextPromise = microsoftTeams.app.initialize()
      .then(() => microsoftTeams.app.getContext())
      .then((ctx) => {
        teamsContext = {
          userId: ctx.user?.id || '',
          displayName: ctx.user?.displayName || ctx.user?.userPrincipalName || '',
        }
      })
      .catch(() => { /* Not in Teams */ })
  }
  return contextPromise
}

function tokenExpMs(token: string): number | null {
  try {
    const exp = decodeJwtPayload(token).exp
    if (typeof exp !== 'number' || !Number.isFinite(exp) || exp <= 0) return null

    const expMs = exp * 1000
    return Number.isFinite(expMs) && expMs > 0 ? expMs : null
  } catch {
    return null
  }
}

async function getFreshToken(): Promise<string | null> {
  if (cachedToken && Date.now() < cachedToken.expMs - TOKEN_REFRESH_BUFFER_MS) {
    return cachedToken.token
  }

  if (!inFlightToken) {
    inFlightToken = (async () => {
      try {
        const token = await microsoftTeams.authentication.getAuthToken()
        if (!token) {
          cachedToken = null
          return null
        }

        const now = Date.now()
        const parsedExpMs = tokenExpMs(token)
        if (parsedExpMs !== null && parsedExpMs <= now) {
          cachedToken = null
          return null
        }

        cachedToken = {
          token,
          expMs: parsedExpMs ?? now + MALFORMED_EXPIRY_RETRY_MS,
        }
        return token
      } catch {
        cachedToken = null
        return null
      } finally {
        inFlightToken = null
      }
    })()
  }

  return inFlightToken
}

export async function apiFetch(url: string, init?: RequestInit): Promise<Response> {
  const headers = new Headers(init?.headers)

  await resolveTeamsContext()

  const token = teamsContext ? await getFreshToken() : null
  if (token) {
    headers.set('Authorization', `Bearer ${token}`)
  } else if (teamsContext && isLocalFallbackHost()) {
    // SSO unavailable — allow fallback identity headers only for local/devtunnel hosts.
    headers.set('x-user-id', teamsContext.userId)
    headers.set('x-user-name', teamsContext.displayName)
  }
  return fetch(url, { ...init, headers })
}

/** Returns a fresh SSO token (or null). Resolves Teams context first if needed. */
export async function getSsoToken(): Promise<string | null> {
  await resolveTeamsContext()
  return teamsContext ? getFreshToken() : null
}
