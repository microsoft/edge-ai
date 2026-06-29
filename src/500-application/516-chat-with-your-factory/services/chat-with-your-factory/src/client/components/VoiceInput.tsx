import { makeStyles, tokens, Button, Tooltip } from '@fluentui/react-components'
import { Mic24Filled, MicOff24Filled } from '@fluentui/react-icons'
import { useSpeech as useSpeechRecognition } from '../hooks/useSpeech.js'

interface VoiceInputProps {
  onResult: (text: string) => void
  disabled: boolean
  sessionId?: string | null
  onEnsureSession?: () => Promise<string | null>
  onDispatch?: (turnId: string) => void
  onDispatchError?: (turnId: string, message: string) => void
}

const useStyles = makeStyles({
  indicator: {
    fontSize: tokens.fontSizeBase200,
    color: tokens.colorStatusDangerForeground1,
    paddingLeft: tokens.spacingHorizontalS,
    paddingRight: tokens.spacingHorizontalS,
    minHeight: '18px',
    whiteSpace: 'nowrap',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    maxWidth: '200px',
  },
  transcript: {
    fontSize: tokens.fontSizeBase200,
    color: tokens.colorNeutralForeground3,
    paddingLeft: tokens.spacingHorizontalS,
    paddingRight: tokens.spacingHorizontalS,
    minHeight: '18px',
    whiteSpace: 'nowrap',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    maxWidth: '200px',
  },
})

export function VoiceInput({ onResult, disabled, sessionId, onEnsureSession, onDispatch, onDispatchError }: VoiceInputProps) {
  const styles = useStyles()
  const { isListening, isSupported, transcript, error, toggleListening } = useSpeechRecognition({
    onFinalResult: onResult,
    sessionId,
    onEnsureSession,
    onDispatch,
    onDispatchError,
  })

  if (!isSupported) {
    return <span className={styles.indicator}>Voice input not supported in this browser</span>
  }

  return (
    <>
      <Tooltip
        content={isListening ? 'Stop listening' : 'Start listening'}
        relationship="label"
      >
        <Button
          icon={isListening ? <Mic24Filled /> : <MicOff24Filled />}
          shape="circular"
          size="large"
          appearance={isListening ? 'primary' : 'subtle'}
          onClick={toggleListening}
          // Keep stop available while loading so the mic cannot get "stuck on".
          disabled={disabled && !isListening}
          aria-label={isListening ? 'Stop listening' : 'Start listening'}
        />
      </Tooltip>
      {transcript && (
        <span className={styles.transcript}>{transcript}</span>
      )}
      {error && (
        <span className={styles.indicator}>{error}</span>
      )}
    </>
  )
}
