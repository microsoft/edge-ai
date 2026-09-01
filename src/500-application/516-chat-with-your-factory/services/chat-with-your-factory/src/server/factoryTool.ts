import { ToolUtility } from '@azure/ai-agents'
import type { FunctionToolDefinition } from '@azure/ai-agents'
import { getRobotPose, listRobots } from './ontologyClient.js'

export const factoryTool: FunctionToolDefinition = ToolUtility.createFunctionTool({
  name: 'query_factory_ontology',
  description: 'Query the factory robotics ontology for robots and their latest pose.',
  parameters: {
    type: 'object',
    properties: {
      intent: {
        type: 'string',
        enum: ['list_robots', 'robot_position'],
        description: 'The ontology query to run.',
      },
      robotName: {
        type: 'string',
        description: "Robot display name, e.g. 'KUKA KR 16'. Required when intent is robot_position.",
      },
    },
    required: ['intent'],
  },
}).definition

export interface FactoryToolArgs {
  intent?: string
  robotName?: string
}

export async function handleFactoryTool(args: FactoryToolArgs): Promise<unknown> {
  switch (args.intent) {
    case 'list_robots':
      return await listRobots()
    case 'robot_position': {
      if (!args.robotName) {
        return { error: "robotName is required when intent is 'robot_position'" }
      }
      return await getRobotPose(args.robotName)
    }
    default:
      return { error: `Unknown intent: ${String(args.intent)}` }
  }
}
