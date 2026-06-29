import type { UseSpeechRecognitionResult } from './useSpeechRecognition.js'

declare const __SPEECH_PROVIDER__: string

interface UseSpeechOptions {
  onFinalResult: (text: string) => void
  sessionId?: string | null
  onEnsureSession?: () => Promise<string | null>
  onDispatch?: (turnId: string) => void
  onDispatchError?: (turnId: string, message: string) => void
}

let hook: (options: UseSpeechOptions) => UseSpeechRecognitionResult

if (__SPEECH_PROVIDER__ === 'webspeech') {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  hook = require('./useSpeechRecognition.js').useSpeechRecognition
} else if (__SPEECH_PROVIDER__ === 'voicelive') {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  hook = require('./useVoiceLive.js').useVoiceLive
} else {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  hook = require('./useAzureSpeech.js').useAzureSpeech
}

export function useSpeech(options: UseSpeechOptions): UseSpeechRecognitionResult {
  return hook(options)
}
