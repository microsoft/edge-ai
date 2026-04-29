import * as microsoftTeams from '@microsoft/teams-js'
import { decodeJwtPayload } from './jwtPayload.js'

let teamsContext: { userId: string; displayName: string } | null = null
let contextPromise: Promise<void> | null = null
let ssoToken: string | null = null

function resolveTeamsContext(): Promise<void> {
  if (!contextPromise) {
    contextPromise = microsoftTeams.app.initialize()
      .then(() => microsoftTeams.app.getContext())
      .then(async (ctx) => {
        let name = ctx.user?.displayName || ctx.user?.userPrincipalName || ''
        // Try to get the SSO token once during init
        try {
          ssoToken = await microsoftTeams.authentication.getAuthToken()
          const payload = decodeJwtPayload(ssoToken)
          if (typeof payload.name === 'string') name = payload.name
        } catch {
          // SSO unavailable — fall back to identity headers
        }
        teamsContext = {
          userId: ctx.user?.id || '',
          displayName: name,
        }
      })
      .catch(() => { /* Not in Teams */ })
  }
  return contextPromise
}

export async function apiFetch(url: string, init?: RequestInit): Promise<Response> {
  const headers = new Headers(init?.headers)

  await resolveTeamsContext()

  if (ssoToken) {
    headers.set('Authorization', `Bearer ${ssoToken}`)
  } else if (teamsContext) {
    // SSO unavailable — fall back to identity headers for SKIP_AUTH mode
    headers.set('x-user-id', teamsContext.userId)
    headers.set('x-user-name', teamsContext.displayName)
  }
  return fetch(url, { ...init, headers })
}

/** Returns the cached SSO token (or null). Resolves Teams context first if needed. */
export async function getSsoToken(): Promise<string | null> {
  await resolveTeamsContext()
  return ssoToken
}
