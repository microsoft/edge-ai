export interface PlaybackSchedule {
  startTime: number
  endTime: number
}

export interface PlaybackSource {
  stop: () => void
  disconnect: () => void
}

export function clearPlaybackSources<T extends PlaybackSource>(
  sources: Set<T>,
  resetSchedule: () => void,
): void {
  const scheduledSources = Array.from(sources)
  sources.clear()

  for (const source of scheduledSources) {
    try {
      source.stop()
    } catch {
      // The source may already have ended or been stopped.
    }

    try {
      source.disconnect()
    } catch {
      // Disconnect is best-effort during repeated teardown.
    }
  }

  resetSchedule()
}

export function decodeBase64Pcm16(base64: string): Float32Array<ArrayBuffer> {
  const binary = atob(base64)
  const sampleCount = Math.floor(binary.length / 2)
  const samples = new Float32Array(sampleCount)

  for (let index = 0; index < sampleCount; index += 1) {
    const offset = index * 2
    const value = (binary.charCodeAt(offset) | (binary.charCodeAt(offset + 1) << 8)) << 16 >> 16
    samples[index] = value < 0 ? value / 32768 : value / 32767
  }

  return samples
}

export function calculatePlaybackSchedule(
  currentTime: number,
  priorScheduledEnd: number,
  sampleCount: number,
  sampleRate: number,
): PlaybackSchedule {
  const startTime = Math.max(currentTime, priorScheduledEnd)
  return {
    startTime,
    endTime: startTime + sampleCount / sampleRate,
  }
}