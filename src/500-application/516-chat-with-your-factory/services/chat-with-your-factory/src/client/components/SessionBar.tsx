import {
  makeStyles,
  tokens,
  Dropdown,
  Option,
  Button,
  type OptionOnSelectData,
} from '@fluentui/react-components'
import { Add24Regular } from '@fluentui/react-icons'
import { AddToSessionDialog } from './AddParticipantDialog.js'
import type { Session } from '../../shared/types.js'

interface SessionBarProps {
  sessions: Session[]
  activeSessionId: string | null
  onSessionSelect: (sessionId: string) => void
  onNewSession: () => void
  onAddParticipant?: (userId: string, displayName: string) => Promise<void>
}

const useStyles = makeStyles({
  bar: {
    display: 'flex',
    alignItems: 'center',
    gap: tokens.spacingHorizontalM,
    padding: `${tokens.spacingVerticalS} ${tokens.spacingHorizontalL}`,
    borderBottom: `1px solid ${tokens.colorNeutralStroke2}`,
    backgroundColor: tokens.colorNeutralBackground2,
    flexWrap: 'wrap',
  },
  sessionPicker: {
    flex: '1',
    minWidth: '200px',
  },
  participants: {
    fontSize: tokens.fontSizeBase200,
    color: tokens.colorNeutralForeground2,
    whiteSpace: 'nowrap',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    maxWidth: '300px',
  },
})

export function SessionBar({
  sessions,
  activeSessionId,
  onSessionSelect,
  onNewSession,
  onAddParticipant,
}: SessionBarProps) {
  const styles = useStyles()

  const handleSessionSelect = (_e: unknown, data: OptionOnSelectData) => {
    if (data.optionValue) {
      onSessionSelect(data.optionValue)
    }
  }

  const activeSession = sessions.find(s => s.id === activeSessionId)

  return (
    <div className={styles.bar}>
      <Dropdown
        className={styles.sessionPicker}
        value={activeSession?.title ?? 'Select a session'}
        selectedOptions={activeSessionId ? [activeSessionId] : []}
        onOptionSelect={handleSessionSelect}
        aria-label="Select session"
      >
        {sessions.map(session => (
          <Option key={session.id} value={session.id}>
            {session.status === 'archived' ? `📁 ${session.title}` : session.title}
          </Option>
        ))}
      </Dropdown>
      <Button
        icon={<Add24Regular />}
        appearance="primary"
        onClick={onNewSession}
        aria-label="New conversation"
      >
        New
      </Button>
      {activeSessionId && (
        <>
          <span className={styles.participants}>
            {activeSession ? Object.values(activeSession.participantNames).join(', ') : ''}
          </span>
          {onAddParticipant && (
            <AddToSessionDialog disabled={!activeSessionId} onAdd={onAddParticipant} />
          )}
        </>
      )}
    </div>
  )
}
