import { AgentsClient } from '@azure/ai-agents'
import { DefaultAzureCredential } from '@azure/identity'
import { factoryTool } from '../server/factoryTool.js'

// Reproducible provisioning for the Chat With Factory Foundry agent.
//
// This is a deploy-time tool, not application runtime code. Foundry persistent
// agents are data-plane objects (not ARM resources), so the 085-ai-foundry
// Terraform component cannot create them. This entry creates (or updates) the
// agent against an existing Foundry project. It is idempotent: an agent matching
// FOUNDRY_AGENT_NAME is reused and updated in place rather than duplicated.
//
// Narration goes to stderr; the resolved agent id is the only stdout output, so
// callers can capture it with `AGENT_ID=$(node provisionAgent.js)`.

const DEFAULT_AGENT_NAME = 'chat-with-your-factory'

const DEFAULT_INSTRUCTIONS = [
  'You are the Chat With Factory assistant for an industrial edge environment.',
  'Answer questions about factory assets, line status, and telemetry concisely and accurately.',
  'Use the query_factory_ontology tool whenever a question concerns robots or their state in the factory.',
  'Call it with intent "list_robots" to enumerate the robots on the line, or intent "robot_position" with the robotName to report a specific robot\'s current pose.',
  'Ground every robot answer in the tool result; do not invent robots, names, or positions.',
  'When the tool returns an error or no data, say so plainly rather than guessing.',
].join(' ')

function requireEnv(name: string): string {
  const value = process.env[name]
  if (!value) {
    throw new Error(`${name} is required`)
  }
  return value
}

async function findAgentIdByName(client: AgentsClient, name: string): Promise<string | undefined> {
  for await (const agent of client.listAgents()) {
    if (agent.name === name) {
      return agent.id
    }
  }
  return undefined
}

async function main(): Promise<void> {
  const endpoint = requireEnv('FOUNDRY_ENDPOINT')
  const model = requireEnv('FOUNDRY_MODEL_DEPLOYMENT')
  const name = process.env.FOUNDRY_AGENT_NAME || DEFAULT_AGENT_NAME
  const instructions = process.env.FOUNDRY_AGENT_INSTRUCTIONS || DEFAULT_INSTRUCTIONS

  const credential = new DefaultAzureCredential({
    tenantId: process.env.AZURE_TENANT_ID,
  })
  const client = new AgentsClient(endpoint, credential)

  const existingId = await findAgentIdByName(client, name)

  let agentId: string
  if (existingId) {
    const updated = await client.updateAgent(existingId, { model, name, instructions, tools: [factoryTool] })
    agentId = updated.id
    console.error(`Updated existing agent "${name}" (${agentId}).`)
  } else {
    const created = await client.createAgent(model, { name, instructions, tools: [factoryTool] })
    agentId = created.id
    console.error(`Created agent "${name}" (${agentId}).`)
  }

  console.log(agentId)
}

main().catch((error: unknown) => {
  console.error('Failed to provision Foundry agent:', error instanceof Error ? error.message : error)
  process.exitCode = 1
})
