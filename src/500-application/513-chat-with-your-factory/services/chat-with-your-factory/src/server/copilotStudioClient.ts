import { ConfidentialClientApplication } from '@azure/msal-node'
import { ConnectionSettings, CopilotStudioClient } from '@microsoft/agents-copilotstudio-client'
import { Activity } from '@microsoft/agents-activity'

// --- Configuration ---
const CPS_ENVIRONMENT_ID = process.env.CPS_ENVIRONMENT_ID
const CPS_AGENT_IDENTIFIER = process.env.CPS_AGENT_IDENTIFIER
const CPS_DIRECT_CONNECT_URL = process.env.CPS_DIRECT_CONNECT_URL
const TEAMS_APP_ID = process.env.TEAMS_APP_ID!
const TEAMS_APP_CLIENT_SECRET = process.env.TEAMS_APP_CLIENT_SECRET

// --- MSAL Singleton ---
// Per-tenant CCA instances: MSAL requires tenant-specific authority for OBO.
// Each CCA handles multi-user token caching (keyed by OBO assertion hash).
const ccaCache = new Map<string, ConfidentialClientApplication>()

function getCCA(tenantId: string): ConfidentialClientApplication {
  let cca = ccaCache.get(tenantId)
  if (!cca) {
    cca = new ConfidentialClientApplication({
      auth: {
        clientId: TEAMS_APP_ID,
        authority: `https://login.microsoftonline.com/${tenantId}`,
        clientSecret: TEAMS_APP_CLIENT_SECRET,
      },
    })
    ccaCache.set(tenantId, cca)
  }
  return cca
}

// --- OBO Token Exchange ---
async function exchangeToken(ssoToken: string, tenantId: string): Promise<string> {
  const cca = getCCA(tenantId)
  const result = await cca.acquireTokenOnBehalfOf({
    oboAssertion: ssoToken,
    scopes: ['https://api.powerplatform.com/.default'],
  })
  if (!result?.accessToken) {
    throw new Error('OBO token exchange failed: no access token returned')
  }
  return result.accessToken
}

// --- ConnectionSettings Builder ---
function buildConnectionSettings(): ConnectionSettings {
  if (CPS_DIRECT_CONNECT_URL) {
    return new ConnectionSettings({ directConnectUrl: CPS_DIRECT_CONNECT_URL })
  }
  if (!CPS_ENVIRONMENT_ID || !CPS_AGENT_IDENTIFIER) {
    throw new Error(
      'CPS_ENVIRONMENT_ID and CPS_AGENT_IDENTIFIER are required when AGENT_BACKEND=copilotstudio (or provide CPS_DIRECT_CONNECT_URL)',
    )
  }
  return new ConnectionSettings({
    environmentId: CPS_ENVIRONMENT_ID,
    schemaName: CPS_AGENT_IDENTIFIER,
    enableDiagnostics: false,
  })
}

// --- Per-Session Client State ---
interface CpsSessionState {
  client: CopilotStudioClient
  conversationId: string
}

const sessions = new Map<string, CpsSessionState>()

// --- Exports (mirror directLineClient.ts pattern) ---

/**
 * Start a Copilot Studio conversation for the given session.
 * Performs OBO exchange, creates CopilotStudioClient, calls startConversationStreaming,
 * and broadcasts greeting activities via the onActivity callback.
 */
export async function startConversation(
  sessionId: string,
  ssoToken: string,
  tenantId: string,
  onActivity: (activity: { text?: string; id?: string; timestamp?: string }) => void,
): Promise<string> {
  if (!TEAMS_APP_CLIENT_SECRET) {
    throw new Error('TEAMS_APP_CLIENT_SECRET is required when AGENT_BACKEND=copilotstudio')
  }

  const ppToken = await exchangeToken(ssoToken, tenantId)
  const settings = buildConnectionSettings()
  const client = new CopilotStudioClient(settings, ppToken)

  let conversationId = ''

  // Start conversation and consume greeting activities
  for await (const activity of client.startConversationStreaming()) {
    if (activity.conversation?.id) {
      conversationId = activity.conversation.id
    }
    if (activity.type === 'message' && activity.text) {
      onActivity({
        text: activity.text,
        id: activity.id,
        timestamp: activity.timestamp instanceof Date ? activity.timestamp.toISOString() : activity.timestamp,
      })
    }
  }

  sessions.set(sessionId, { client, conversationId })
  return conversationId
}

/**
 * Send a user message and stream back agent responses via onActivity callback.
 * Returns after all streaming activities have been consumed.
 */
export async function sendActivity(
  sessionId: string,
  text: string,
  onActivity: (activity: { text?: string; id?: string; timestamp?: string }) => void,
): Promise<void> {
  const state = sessions.get(sessionId)
  if (!state) {
    throw new Error(`No Copilot Studio conversation found for session ${sessionId}`)
  }

  const activity = new Activity('message')
  activity.text = text

  for await (const reply of state.client.sendActivityStreaming(activity, state.conversationId)) {
    // Update conversationId if returned in response
    if (reply.conversation?.id) {
      state.conversationId = reply.conversation.id
    }
    if (reply.type === 'message' && reply.text) {
      onActivity({
        text: reply.text,
        id: reply.id,
        timestamp: reply.timestamp instanceof Date ? reply.timestamp.toISOString() : reply.timestamp,
      })
    }
  }
}

/**
 * Close and clean up a session's CopilotStudioClient.
 */
export function closeConversation(sessionId: string): void {
  sessions.delete(sessionId)
}

/**
 * Close all active CPS sessions (for server shutdown).
 */
export function closeAll(): void {
  sessions.clear()
}
