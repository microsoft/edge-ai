import { useEffect, type RefObject } from 'react'
import { makeStyles, mergeClasses, tokens } from '@fluentui/react-components'
import type { Message } from '../App.js'
import { renderAssistantContent } from '../utils/markdownRenderer.js'

interface ChatPanelProps {
  messages: Message[]
  isLoading: boolean
  bottomRef: RefObject<HTMLDivElement>
  onSend?: (text: string) => void
}

const STARTER_PROMPTS = [
  { label: 'Summarize open work orders', prompt: 'Summarize all open work orders across the fleet.' },
  { label: 'Recent alerts', prompt: 'What are the most recent alerts and maintenance events for M01 TruLaser 5030?' },
  { label: 'Compare machine downtime', prompt: 'Compare downtime across all machines this quarter. Which machine has the most downtime?' },
  { label: 'Draft a work order', prompt: 'Help me draft a corrective work order for a machine that needs maintenance.' },
]

function formatTime(timestamp: number): string {
  return new Date(timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

const useStyles = makeStyles({
  panel: {
    flex: '1',
    overflowY: 'auto',
    padding: tokens.spacingHorizontalL,
    display: 'flex',
    flexDirection: 'column',
    gap: tokens.spacingVerticalS,
  },
  empty: {
    flex: '1',
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    color: tokens.colorNeutralForeground3,
    fontSize: tokens.fontSizeBase300,
    textAlign: 'center' as const,
    padding: tokens.spacingHorizontalXXL,
    gap: tokens.spacingVerticalL,
  },
  starters: {
    display: 'flex',
    flexWrap: 'wrap',
    gap: tokens.spacingHorizontalS,
    justifyContent: 'center',
    padding: tokens.spacingHorizontalL,
  },
  starterPill: {
    border: `1px solid ${tokens.colorNeutralStroke1}`,
    borderRadius: tokens.borderRadiusXLarge,
    backgroundColor: tokens.colorNeutralBackground1,
    color: tokens.colorNeutralForeground1,
    padding: `${tokens.spacingVerticalXS} ${tokens.spacingHorizontalM}`,
    cursor: 'pointer',
    fontSize: tokens.fontSizeBase300,
    lineHeight: tokens.lineHeightBase300,
    transitionProperty: 'background-color, border-color',
    transitionDuration: '0.15s',
    ':hover': {
      backgroundColor: tokens.colorNeutralBackground1Hover,
      borderColor: tokens.colorBrandStroke1,
    },
    ':active': {
      backgroundColor: tokens.colorNeutralBackground1Pressed,
    },
    ':disabled': {
      opacity: 0.5,
      cursor: 'not-allowed',
    },
  },
  message: {
    maxWidth: '75%',
    padding: `${tokens.spacingVerticalS} ${tokens.spacingHorizontalM}`,
    borderRadius: tokens.borderRadiusXLarge,
    fontSize: tokens.fontSizeBase300,
    lineHeight: tokens.lineHeightBase300,
    overflowWrap: 'break-word',
  },
  messageUser: {
    alignSelf: 'flex-end',
    backgroundColor: tokens.colorBrandBackground,
    color: tokens.colorNeutralForegroundOnBrand,
    borderBottomRightRadius: tokens.borderRadiusSmall,
  },
  messageAgent: {
    alignSelf: 'flex-start',
    maxWidth: '95%',
    backgroundColor: tokens.colorNeutralBackground3,
    color: tokens.colorNeutralForeground1,
    borderBottomLeftRadius: tokens.borderRadiusSmall,
  },
  messageVoice: {
    fontStyle: 'italic',
  },
  timestamp: {
    fontSize: tokens.fontSizeBase200,
    opacity: 0.7,
    marginTop: tokens.spacingVerticalXS,
  },
  timestampUser: {
    textAlign: 'right' as const,
  },
  displayName: {
    fontSize: tokens.fontSizeBase200,
    fontWeight: tokens.fontWeightSemibold,
    marginBottom: tokens.spacingVerticalXXS,
  },
  typingBubble: {
    alignSelf: 'flex-start',
    backgroundColor: tokens.colorNeutralBackground3,
    borderRadius: tokens.borderRadiusXLarge,
    borderBottomLeftRadius: tokens.borderRadiusSmall,
    padding: `${tokens.spacingVerticalS} ${tokens.spacingHorizontalM}`,
    display: 'flex',
    alignItems: 'center',
    gap: '3px',
  },
  typingDot: {
    display: 'inline-block',
    width: '6px',
    height: '6px',
    borderRadius: '50%',
    backgroundColor: tokens.colorNeutralForeground3,
    animationName: {
      '0%, 80%, 100%': { opacity: 0.2 },
      '40%': { opacity: 1 },
    },
    animationDuration: '1.2s',
    animationIterationCount: 'infinite',
  },
  typingDot2: {
    animationDelay: '0.2s',
  },
  typingDot3: {
    animationDelay: '0.4s',
  },
  agentContent: {
    overflowX: 'auto',
    '& p': {
      margin: '4px 0',
    },
    '& strong': {
      fontWeight: tokens.fontWeightSemibold,
    },
    '& code': {
      fontFamily: tokens.fontFamilyMonospace,
      fontSize: tokens.fontSizeBase200,
      backgroundColor: tokens.colorNeutralBackground4,
      padding: '1px 4px',
      borderRadius: tokens.borderRadiusSmall,
    },
  },
})

export function ChatPanel({ messages, isLoading, bottomRef, onSend }: ChatPanelProps) {
  const styles = useStyles()

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, isLoading, bottomRef])

  return (
    <div className={styles.panel}>
      {messages.length === 0 && (
        <div className={styles.empty}>
          <div>Tap the mic and start talking, or try one of these:</div>
          {onSend && (
            <div className={styles.starters}>
              {STARTER_PROMPTS.map(sp => (
                <button
                  key={sp.label}
                  type="button"
                  className={styles.starterPill}
                  onClick={() => onSend(sp.prompt)}
                  disabled={isLoading}
                >
                  {sp.label}
                </button>
              ))}
            </div>
          )}
        </div>
      )}
      {messages.map(msg => (
        <div
          key={msg.id}
          className={mergeClasses(
            styles.message,
            msg.role === 'user' ? styles.messageUser : styles.messageAgent,
            msg.source === 'voice' ? styles.messageVoice : undefined,
          )}
        >
          {msg.role === 'user' && msg.displayName && (
            <div className={styles.displayName}>{msg.displayName}</div>
          )}
          <div className={msg.role === 'assistant' ? styles.agentContent : undefined}>
            {msg.role === 'assistant' ? renderAssistantContent(msg.text) : msg.text}
          </div>
          <div className={mergeClasses(
            styles.timestamp,
            msg.role === 'user' ? styles.timestampUser : undefined,
          )}>
            {formatTime(msg.timestamp)}
          </div>
        </div>
      ))}
      {isLoading && (
        <div className={styles.typingBubble}>
          <span className={styles.typingDot} />
          <span className={mergeClasses(styles.typingDot, styles.typingDot2)} />
          <span className={mergeClasses(styles.typingDot, styles.typingDot3)} />
        </div>
      )}
      <div ref={bottomRef} />
    </div>
  )
}
