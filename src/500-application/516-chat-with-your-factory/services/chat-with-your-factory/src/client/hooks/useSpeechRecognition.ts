import { useState, useRef, useEffect, useCallback } from 'react'

interface SpeechRecognitionEvent {
  results: SpeechRecognitionResultList
  resultIndex: number
}

interface SpeechRecognitionErrorEvent {
  error: string
}

interface SpeechRecognitionInstance extends EventTarget {
  continuous: boolean
  interimResults: boolean
  lang: string
  start(): void
  stop(): void
  abort(): void
  onresult: ((event: SpeechRecognitionEvent) => void) | null
  onerror: ((event: SpeechRecognitionErrorEvent) => void) | null
  onend: (() => void) | null
}

declare global {
  interface Window {
    SpeechRecognition?: new () => SpeechRecognitionInstance
    webkitSpeechRecognition?: new () => SpeechRecognitionInstance
  }
}

interface UseSpeechRecognitionOptions {
  onFinalResult: (text: string) => void
}

export interface UseSpeechRecognitionResult {
  isListening: boolean
  isSupported: boolean
  transcript: string
  error: string | null
  startListening: () => void
  stopListening: () => void
  toggleListening: () => void
}

export function useSpeechRecognition(options: UseSpeechRecognitionOptions): UseSpeechRecognitionResult {
  const SpeechRecognitionCtor = typeof window !== 'undefined'
    ? (window.SpeechRecognition ?? window.webkitSpeechRecognition)
    : undefined
  const isSupported = !!SpeechRecognitionCtor

  const [isListening, setIsListening] = useState(false)
  const [transcript, setTranscript] = useState('')
  const [error, setError] = useState<string | null>(null)
  const recognitionRef = useRef<SpeechRecognitionInstance | null>(null)
  const isListeningRef = useRef(false)
  const isStartingRef = useRef(false)
  const onFinalResultRef = useRef(options.onFinalResult)
  onFinalResultRef.current = options.onFinalResult

  useEffect(() => {
    return () => {
      recognitionRef.current?.abort()
    }
  }, [])

  const startListening = useCallback(async () => {
    if (!SpeechRecognitionCtor || isListeningRef.current || isStartingRef.current) return
    setError(null)
    isStartingRef.current = true

    // Request mic permission explicitly — needed in iframes (Teams tabs)
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      stream.getTracks().forEach(t => t.stop())
    } catch {
      setError('Microphone access denied. Check browser permissions.')
      isStartingRef.current = false
      return
    }

    // User may have clicked stop while we were awaiting mic permission
    if (!isStartingRef.current) return

    const recognition = new SpeechRecognitionCtor()
    recognition.continuous = true
    recognition.interimResults = true
    recognition.lang = 'en-US'

    recognition.onresult = (event: SpeechRecognitionEvent) => {
      let interim = ''
      for (let i = event.resultIndex; i < event.results.length; i++) {
        const result = event.results[i]
        if (result.isFinal) {
          const finalText = result[0].transcript.trim()
          if (finalText) {
            onFinalResultRef.current(finalText)
          }
          setTranscript('')
        } else {
          interim += result[0].transcript
        }
      }
      if (interim) {
        setTranscript(interim)
      }
    }

    recognition.onerror = (event: SpeechRecognitionErrorEvent) => {
      console.error('Speech recognition error:', event.error)
      if (event.error === 'not-allowed') {
        setError('Microphone access denied. Check browser permissions.')
        isListeningRef.current = false
        setIsListening(false)
        setTranscript('')
      } else if (event.error !== 'no-speech') {
        setError(`Speech error: ${event.error}`)
        isListeningRef.current = false
        setIsListening(false)
        setTranscript('')
      }
    }

    recognition.onend = () => {
      // Auto-restart if user hasn't explicitly stopped
      if (isListeningRef.current) {
        try {
          recognition.start()
        } catch {
          isListeningRef.current = false
          setIsListening(false)
          setTranscript('')
        }
      }
    }

    recognitionRef.current = recognition
    isListeningRef.current = true
    isStartingRef.current = false
    setIsListening(true)
    setTranscript('')
    try {
      recognition.start()
    } catch {
      setError('Failed to start speech recognition.')
      isListeningRef.current = false
      isStartingRef.current = false
      setIsListening(false)
    }
  }, [SpeechRecognitionCtor])

  const stopListening = useCallback(() => {
    isListeningRef.current = false
    isStartingRef.current = false
    setIsListening(false)
    setTranscript('')
    recognitionRef.current?.abort()
    recognitionRef.current = null
  }, [])

  const toggleListening = useCallback(() => {
    if (isListeningRef.current || isStartingRef.current) {
      stopListening()
    } else {
      startListening()
    }
  }, [startListening, stopListening])

  return { isListening, isSupported, transcript, error, startListening, stopListening, toggleListening }
}
