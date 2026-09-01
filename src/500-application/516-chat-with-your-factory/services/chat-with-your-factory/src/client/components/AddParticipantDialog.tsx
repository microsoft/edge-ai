import { useState } from 'react'
import {
  Button,
  MessageBar,
  MessageBarActions,
  MessageBarBody,
  MessageBarTitle,
} from '@fluentui/react-components'
import { DismissRegular, PersonAdd24Regular } from '@fluentui/react-icons'
import * as microsoftTeams from '@microsoft/teams-js'
import {
  addParticipantErrorUserMessage,
  isAddParticipantError,
} from '../../shared/addParticipantErrors.js'

interface AddToSessionDialogProps {
  disabled?: boolean
  // Required: without a handler the picker would open and silently discard
  // selections. Callers that have nothing to do with the result should not
  // render this component at all.
  //
  // Returns a Promise so the dialog can keep the button disabled while the
  // network request is in flight (preventing double-clicks and concurrent
  // adds) and so per-person failures can be surfaced in the inline
  // MessageBar instead of being swallowed by a fire-and-forget call.
  onAdd: (userId: string, displayName: string) => Promise<void>
}

export function AddToSessionDialog({ disabled, onAdd }: AddToSessionDialogProps) {
  const [isAdding, setIsAdding] = useState(false)
  // Surfaced inline as a Fluent UI MessageBar instead of `window.alert`,
  // which is a blocking modal that's awkward inside a Teams iframe (and
  // sometimes suppressed by the host). The bar is dismissable and doesn't
  // interrupt the user's flow.
  const [skippedNames, setSkippedNames] = useState<string[]>([])
  const [failedNames, setFailedNames] = useState<string[]>([])
  const [failedDetails, setFailedDetails] = useState<string[]>([])

  const handleClick = async () => {
    setIsAdding(true)
    setSkippedNames([])
    setFailedNames([])
    setFailedDetails([])
    try {
      const selected = await microsoftTeams.people.selectPeople({
        singleSelect: false,
      })

      if (selected.length === 0) return

      // Server-side ACL checks compare the caller's AAD object ID (oid claim)
      // against session.participants, so we MUST add an objectId here. Falling
      // back to email would silently add an entry the server can never match,
      // producing "added but can't join" behavior. Skip any picked person that
      // lacks an objectId (typically unresolved external contacts) and surface
      // the names so the user knows they were not added.
      const skipped: string[] = []
      const toAdd: Array<{ userId: string; displayName: string }> = []
      for (const person of selected) {
        const userId = person.objectId
        const displayName = person.displayName || person.email || ''
        if (!userId) {
          skipped.push(displayName || person.email || 'Unknown user')
          continue
        }
        toAdd.push({ userId, displayName })
      }

      if (skipped.length > 0) {
        setSkippedNames(skipped)
      }

      // Issue all adds concurrently and collect per-person failures so a
      // single failure doesn't mask the rest. We await before clearing
      // isAdding so the button stays disabled until every request settles.
      const results = await Promise.allSettled(
        toAdd.map(p => onAdd(p.userId, p.displayName)),
      )
      const failed: string[] = []
      const details: string[] = []
      results.forEach((result, i) => {
        if (result.status === 'rejected') {
          console.error('Add participant failed:', result.reason)
          const displayName = toAdd[i].displayName || toAdd[i].userId
          failed.push(displayName)
          if (isAddParticipantError(result.reason)) {
            details.push(`${displayName}: ${addParticipantErrorUserMessage(result.reason)}`)
          } else {
            details.push(`${displayName}: Unexpected error while adding participant.`)
          }
        }
      })
      if (failed.length > 0) {
        setFailedNames(failed)
        setFailedDetails(details)
      }
    } catch {
      // User cancelled the picker
    } finally {
      setIsAdding(false)
    }
  }

  return (
    <>
      <Button
        icon={<PersonAdd24Regular />}
        appearance="subtle"
        onClick={handleClick}
        disabled={disabled || isAdding}
        aria-label="Add to session"
        title="Add someone to this session"
      />
      {skippedNames.length > 0 && (
        <MessageBar intent="warning" politeness="polite">
          <MessageBarBody>
            <MessageBarTitle>
              {"Couldn't"} add {skippedNames.length === 1 ? 'this person' : 'these people'}
            </MessageBarTitle>
            {' '}
            No Microsoft Entra account was resolved for: {skippedNames.join(', ')}.
          </MessageBarBody>
          <MessageBarActions
            containerAction={
              <Button
                aria-label="Dismiss"
                appearance="transparent"
                icon={<DismissRegular />}
                onClick={() => setSkippedNames([])}
              />
            }
          />
        </MessageBar>
      )}
      {failedNames.length > 0 && (
        <MessageBar intent="error" politeness="polite">
          <MessageBarBody>
            <MessageBarTitle>
              Failed to add {failedNames.length === 1 ? 'participant' : 'participants'}
            </MessageBarTitle>
            {' '}
            The server rejected: {failedNames.join(', ')}.
            {failedDetails.length > 0 && (
              <>
                {' '}
                Details: {failedDetails.join(' | ')}.
              </>
            )}
          </MessageBarBody>
          <MessageBarActions
            containerAction={
              <Button
                aria-label="Dismiss"
                appearance="transparent"
                icon={<DismissRegular />}
                onClick={() => {
                  setFailedNames([])
                  setFailedDetails([])
                }}
              />
            }
          />
        </MessageBar>
      )}
    </>
  )
}
