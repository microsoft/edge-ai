import { afterEach, describe, expect, it, vi } from 'vitest'

import { cleanLogging } from './logging.js'

afterEach(() => {
  vi.restoreAllMocks()
})

describe('cleanLogging', () => {
  it('removes control characters and repeated whitespace from labels', () => {
    const log = vi.spyOn(console, 'log').mockImplementation(() => undefined)

    cleanLogging.Log('voice\nbridge', 'queued\t  response')

    expect(log).toHaveBeenCalledWith('[voice bridge] queued response')
  })

  it('sanitizes nested values and circular references', () => {
    const log = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    const value: Record<string, unknown> = { status: 'ready\r\n now' }
    value.self = value

    cleanLogging.Warn('session', 'state', value)

    expect(log).toHaveBeenCalledWith('[session] state', {
      status: 'ready now',
      self: '[Circular]',
    })
  })

  it('truncates long strings to the configured bound', () => {
    const log = vi.spyOn(console, 'error').mockImplementation(() => undefined)

    cleanLogging.Error('session', 'failure', 'x'.repeat(600))

    const loggedValue = log.mock.calls[0][1] as string
    expect(loggedValue).toHaveLength(500)
    expect(loggedValue.endsWith('... [truncated]')).toBe(true)
  })

  it('bounds arrays and object properties', () => {
    const log = vi.spyOn(console, 'log').mockImplementation(() => undefined)
    const array = Array.from({ length: 21 }, (_, index) => index)
    const object = Object.fromEntries(Array.from({ length: 21 }, (_, index) => [`key${index}`, index]))

    cleanLogging.Log('limits', 'values', array, object)

    expect(log.mock.calls[0][1]).toEqual([...array.slice(0, 20), '[Truncated array items]'])
    expect(log.mock.calls[0][2]).toMatchObject({ '[Truncated object properties]': 1 })
    expect(Object.keys(log.mock.calls[0][2] as object)).toHaveLength(21)
  })

  it('bounds nested object depth', () => {
    const log = vi.spyOn(console, 'log').mockImplementation(() => undefined)

    cleanLogging.Log('limits', 'depth', { one: { two: { three: { four: true } } } })

    expect(log.mock.calls[0][1]).toEqual({
      one: { two: { three: '[Object depth truncated]' } },
    })
  })

  it('limits the number of logged arguments', () => {
    const log = vi.spyOn(console, 'log').mockImplementation(() => undefined)

    cleanLogging.Log('limits', 'arguments', ...Array.from({ length: 21 }, (_, index) => index))

    expect(log.mock.calls[0]).toHaveLength(22)
    expect(log.mock.calls[0].at(-1)).toBe('[Truncated log arguments]')
  })
})
