import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('./ontologyClient.js', () => ({
  listRobots: vi.fn(),
  getRobotPose: vi.fn(),
}))

import { getRobotPose, listRobots } from './ontologyClient.js'
import { factoryTool, handleFactoryTool } from './factoryTool.js'

const listRobotsMock = vi.mocked(listRobots)
const getRobotPoseMock = vi.mocked(getRobotPose)

const seedRobots = [
  { Id: 'robot1', Name: 'ABB IRB 6700', Description: 'ABB robot' },
  { Id: 'robot2', Name: 'KUKA KR 16', Description: 'KUKA robot' },
  { Id: 'robot3', Name: 'Fanuc M-20iA', Description: 'Fanuc robot' },
]

const seedPose = { Robot: 'KUKA KR 16', X: 4.5, Y: 2.0, Z: 0.6, Roll: 0, Pitch: 0, Yaw: 0, Timestamp: '2026-01-08T00:00:00Z' }

describe('factoryTool definition', () => {
  it('exposes the query_factory_ontology function tool', () => {
    expect(factoryTool.type).toBe('function')
    expect(factoryTool.function.name).toBe('query_factory_ontology')
  })

  it('declares both intents and requires intent', () => {
    const params = factoryTool.function.parameters as {
      properties: { intent: { enum: string[] } }
      required: string[]
    }
    expect(params.properties.intent.enum).toEqual(['list_robots', 'robot_position'])
    expect(params.required).toContain('intent')
  })
})

describe('handleFactoryTool dispatch', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    listRobotsMock.mockResolvedValue(seedRobots)
    getRobotPoseMock.mockResolvedValue(seedPose)
  })

  it('routes list_robots to listRobots', async () => {
    const result = await handleFactoryTool({ intent: 'list_robots' })
    expect(listRobotsMock).toHaveBeenCalledOnce()
    expect(result).toEqual(seedRobots)
  })

  it('routes robot_position to getRobotPose with the robot name', async () => {
    const result = await handleFactoryTool({ intent: 'robot_position', robotName: 'KUKA KR 16' })
    expect(getRobotPoseMock).toHaveBeenCalledWith('KUKA KR 16')
    expect(result).toEqual(seedPose)
  })

  it('returns an error when robot_position is missing robotName', async () => {
    const result = await handleFactoryTool({ intent: 'robot_position' })
    expect(getRobotPoseMock).not.toHaveBeenCalled()
    expect(result).toEqual({ error: "robotName is required when intent is 'robot_position'" })
  })

  it('returns an error for an unknown intent', async () => {
    const result = await handleFactoryTool({ intent: 'teleport_robot' })
    expect(result).toEqual({ error: 'Unknown intent: teleport_robot' })
  })
})
