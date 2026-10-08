/**
 * AudioWorklet processor for Voice Live — captures mic audio, resamples to
 * 24 kHz mono PCM16 (Int16), and posts frames to the main thread.
 *
 * The AudioContext runs at the system default sample rate (typically 48 kHz).
 * This processor downsamples to 24 kHz using linear interpolation before
 * converting to PCM16.
 *
 * Loaded at runtime via: audioContext.audioWorklet.addModule('/voice-live-worklet.js')
 */
// Fixed-size scratch buffer for accumulating input samples between callbacks.
// AudioWorklet delivers 128 samples per process() call. At 48 kHz input the
// per-callback leftover after resampling to 24 kHz is < ratio (~2) samples,
// so a few hundred slots is more than enough; 2048 leaves generous headroom
// for higher input rates or missed callbacks without ever reallocating.
const RESAMPLE_BUFFER_SIZE = 2048

class VoiceLiveProcessor extends AudioWorkletProcessor {
  constructor() {
    super()
    // Pre-allocated typed-array scratch buffer + write index. Avoids the
    // per-callback allocations / array growth / slice() copies that the
    // previous implementation incurred at audio rates.
    this._resampleBuffer = new Float32Array(RESAMPLE_BUFFER_SIZE)
    this._resampleLen = 0
  }

  process(inputs) {
    const input = inputs[0]
    if (!input || !input[0] || input[0].length === 0) return true

    const float32 = input[0] // mono channel
    const inputRate = sampleRate // AudioWorklet global: actual context sample rate
    const outputRate = 24000

    // If already at 24 kHz, pass through directly
    if (inputRate === outputRate) {
      const int16 = new Int16Array(float32.length)
      for (let i = 0; i < float32.length; i++) {
        const s = Math.max(-1, Math.min(1, float32[i]))
        int16[i] = s < 0 ? s * 0x8000 : s * 0x7fff
      }
      this.port.postMessage(int16.buffer, [int16.buffer])
      return true
    }

    // Downsample: accumulate input samples in the fixed scratch buffer, then
    // emit output at 24 kHz rate using linear interpolation.
    const ratio = inputRate / outputRate
    const buffer = this._resampleBuffer
    let writeIdx = this._resampleLen

    // Defensive guard: if upstream ever delivers more samples than headroom,
    // drop the oldest to keep the buffer bounded rather than reallocating.
    if (writeIdx + float32.length > buffer.length) {
      const overflow = writeIdx + float32.length - buffer.length
      buffer.copyWithin(0, overflow, writeIdx)
      writeIdx -= overflow
    }
    buffer.set(float32, writeIdx)
    writeIdx += float32.length

    // We need `ratio` input samples per output sample
    const outputLen = Math.floor(writeIdx / ratio)
    if (outputLen === 0) {
      this._resampleLen = writeIdx
      return true
    }

    const int16 = new Int16Array(outputLen)
    for (let i = 0; i < outputLen; i++) {
      const srcIdx = i * ratio
      const idx = srcIdx | 0
      const frac = srcIdx - idx
      const a = buffer[idx]
      const b = idx + 1 < writeIdx ? buffer[idx + 1] : a
      const sample = a + frac * (b - a)
      const s = sample < -1 ? -1 : sample > 1 ? 1 : sample
      int16[i] = s < 0 ? s * 0x8000 : s * 0x7fff
    }

    // Shift unconsumed samples to the front of the scratch buffer in place
    // (no allocation, no slice()).
    const consumed = Math.floor(outputLen * ratio)
    const remaining = writeIdx - consumed
    if (remaining > 0) {
      buffer.copyWithin(0, consumed, writeIdx)
    }
    this._resampleLen = remaining

    this.port.postMessage(int16.buffer, [int16.buffer])
    return true
  }
}

registerProcessor('voice-live-processor', VoiceLiveProcessor)