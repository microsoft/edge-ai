import { describe, expect, it, vi } from 'vitest'

import {
  calculatePlaybackSchedule,
  clearPlaybackSources,
  decodeBase64Pcm16,
} from './pcmPlayback.js'

function encodeBytes(bytes: number[]): string {
  return Buffer.from(bytes).toString('base64')
}

describe('decodeBase64Pcm16', () => {
  it('decodes signed little-endian PCM16 boundary values', () => {
    const samples = decodeBase64Pcm16(encodeBytes([0x00, 0x80, 0x00, 0x00, 0xff, 0x7f]))

    expect(Array.from(samples)).toEqual([-1, 0, 1])
  })

  it('scales negative and positive samples independently', () => {
    const samples = decodeBase64Pcm16(encodeBytes([0x00, 0xc0, 0x00, 0x40]))

    expect(samples[0]).toBe(-0.5)
    expect(samples[1]).toBeCloseTo(16384 / 32767)
  })

  it('ignores an incomplete trailing byte', () => {
    const samples = decodeBase64Pcm16(encodeBytes([0x01, 0x00, 0xff]))

    expect(samples).toHaveLength(1)
    expect(samples[0]).toBeCloseTo(1 / 32767)
  })
})

describe('calculatePlaybackSchedule', () => {
  it('starts immediately when no prior audio remains scheduled', () => {
    expect(calculatePlaybackSchedule(10, 8, 24_000, 24_000)).toEqual({
      startTime: 10,
      endTime: 11,
    })
  })

  it('queues audio after the prior scheduled segment', () => {
    expect(calculatePlaybackSchedule(10, 12, 12_000, 24_000)).toEqual({
      startTime: 12,
      endTime: 12.5,
    })
  })
})

describe('clearPlaybackSources', () => {
  it('stops, disconnects, and clears every source before resetting the schedule', () => {
    const first = { stop: vi.fn(), disconnect: vi.fn() }
    const second = {
      stop: vi.fn(() => { throw new Error('already stopped') }),
      disconnect: vi.fn(() => { throw new Error('already disconnected') }),
    }
    const sources = new Set([first, second])
    const resetSchedule = vi.fn()

    clearPlaybackSources(sources, resetSchedule)

    expect(first.stop).toHaveBeenCalledOnce()
    expect(first.disconnect).toHaveBeenCalledOnce()
    expect(second.stop).toHaveBeenCalledOnce()
    expect(second.disconnect).toHaveBeenCalledOnce()
    expect(sources.size).toBe(0)
    expect(resetSchedule).toHaveBeenCalledOnce()
  })
})
