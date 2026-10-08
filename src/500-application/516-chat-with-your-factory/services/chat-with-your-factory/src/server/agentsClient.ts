import { AgentsClient } from '@azure/ai-agents'
import { DefaultAzureCredential } from '@azure/identity'

export const endpoint = process.env.FOUNDRY_ENDPOINT
  ?? (() => { throw new Error('FOUNDRY_ENDPOINT is required') })()

export const agentId = process.env.FOUNDRY_AGENT_ID
  ?? (() => { throw new Error('FOUNDRY_AGENT_ID is required') })()

const credential = new DefaultAzureCredential({
  tenantId: process.env.AZURE_TENANT_ID,
})

export const agentsClient = new AgentsClient(endpoint, credential)
