import { useState, type KeyboardEvent } from 'react'
import { makeStyles, tokens, Input, Button, Tooltip } from '@fluentui/react-components'
import { Send24Filled } from '@fluentui/react-icons'

interface TextInputProps {
  onSend: (text: string) => void
  disabled: boolean
}

const useStyles = makeStyles({
  wrapper: {
    flex: '1',
    display: 'flex',
    gap: tokens.spacingHorizontalS,
  },
})

export function TextInput({ onSend, disabled }: TextInputProps) {
  const styles = useStyles()
  const [value, setValue] = useState('')

  const handleSend = () => {
    const trimmed = value.trim()
    if (!trimmed || disabled) return
    onSend(trimmed)
    setValue('')
  }

  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  return (
    <div className={styles.wrapper}>
      <Input
        style={{ flex: 1 }}
        placeholder="Type a message..."
        value={value}
        onChange={(_e, data) => setValue(data.value)}
        onKeyDown={handleKeyDown}
        disabled={disabled}
      />
      <Tooltip content="Send message" relationship="label">
        <Button
          icon={<Send24Filled />}
          appearance="primary"
          onClick={handleSend}
          disabled={disabled || !value.trim()}
          aria-label="Send message"
        />
      </Tooltip>
    </div>
  )
}
