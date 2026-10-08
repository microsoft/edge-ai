import { describe, expect, it } from 'vitest'

import { toSpeechText } from './speechText.js'

describe('toSpeechText', () => {
  it('preserves ordinary text', () => {
    expect(toSpeechText('Robot 7 is ready.')).toBe('Robot 7 is ready.')
  })

  it('keeps descriptive link labels while removing URLs', () => {
    expect(toSpeechText('Open the [robot manual](https://example.com/manual).')).toBe(
      'Open the robot manual.',
    )
  })

  it('removes numeric citation links and references', () => {
    const markdown = 'Robot 7 is ready [1].\n\n[1]: https://example.com/status'

    expect(toSpeechText(markdown)).toBe('Robot 7 is ready.')
  })

  it('removes inline citation markers and raw URLs', () => {
    expect(toSpeechText('Robot 7 [2] is documented at https://example.com/robots')).toBe(
      'Robot 7 is documented at',
    )
  })

  it('removes zero-width formatting and normalizes whitespace', () => {
    expect(toSpeechText('  Robot\u200B\t7\r\n is   ready.  ')).toBe('Robot 7 is ready.')
  })

  it('removes empty delimiters without leaving punctuation gaps', () => {
    expect(toSpeechText('Ready ( ) [ ] { } , proceed!')).toBe('Ready, proceed!')
  })
})
