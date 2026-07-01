import { useState, useEffect } from 'react'
import * as microsoftTeams from '@microsoft/teams-js'
import type { UserContext } from '../../shared/types.js'
import { decodeJwtPayload } from '../utils/jwtPayload.js'

async function fetchDisplayName(): Promise<string | null> {
  try {
    const token = await microsoftTeams.authentication.getAuthToken()
    const payload = decodeJwtPayload(token)
    return (payload.name as string) || null
  } catch {
    return null
  }
}

/**
 * Resolves the current user from the Teams context (AAD objectId + displayName).
 * Returns null while loading and a fallback anonymous user if not running inside Teams.
 */
export function useTeamsUser() {
  const [user, setUser] = useState<UserContext | null>(null)

  useEffect(() => {
    microsoftTeams.app.initialize().then(async () => {
      const context = await microsoftTeams.app.getContext()
      const id = context.user?.id || ''
      const tokenName = await fetchDisplayName()
      const name = tokenName || context.user?.displayName || context.user?.userPrincipalName || 'Unknown'
      const chatId = context.chat?.id ?? context.channel?.id ?? null
      setUser({
        userId: id,
        displayName: name,
        tenantId: context.user?.tenant?.id,
        chatId,
      })
    }).catch(() => {
      // Not running inside Teams — use a local fallback
      setUser({
        userId: 'local-user',
        displayName: 'Local User',
      })
    })
  }, [])

  return user
}
