import { afterEach, describe, expect, it, vi } from 'vitest'

const SECRET = 'test-resume-token-secret'
const USER_ID = 'user-1'
const SESSION_ID = 'session-1'

async function importResumeToken(secret: string | undefined, nodeEnv = 'test') {
  vi.resetModules()
  vi.stubEnv('NODE_ENV', nodeEnv)
  if (secret === undefined) {
    vi.stubEnv('RESUME_TOKEN_SECRET', '')
  } else {
    vi.stubEnv('RESUME_TOKEN_SECRET', secret)
  }
  return import('./resumeToken.js')
}

afterEach(() => {
  vi.useRealTimers()
  vi.unstubAllEnvs()
})

describe('resume tokens', () => {
  it('issues and verifies a token bound to its user and session', async () => {
    const { issueResumeToken, verifyResumeToken } = await importResumeToken(SECRET)
    const pointers = { conversationId: 'conversation-1', threadId: 'thread-1' }

    const token = issueResumeToken(USER_ID, SESSION_ID, pointers)

    expect(token).toBeTypeOf('string')
    expect(verifyResumeToken(token, USER_ID, SESSION_ID)).toEqual(pointers)
  })

  it('rejects a tampered signature', async () => {
    const { issueResumeToken, verifyResumeToken } = await importResumeToken(SECRET)
    const token = issueResumeToken(USER_ID, SESSION_ID, { threadId: 'thread-1' })!
    const [payload, signature] = token.split('.')
    const replacement = signature.endsWith('A') ? 'B' : 'A'

    expect(verifyResumeToken(`${payload}.${signature.slice(0, -1)}${replacement}`, USER_ID, SESSION_ID)).toBeNull()
  })

  it('rejects an expired token', async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-01-01T00:00:00Z'))
    const { issueResumeToken, verifyResumeToken } = await importResumeToken(SECRET)
    const token = issueResumeToken(USER_ID, SESSION_ID, { threadId: 'thread-1' })!

    vi.advanceTimersByTime(30 * 24 * 60 * 60 * 1000 + 1)

    expect(verifyResumeToken(token, USER_ID, SESSION_ID)).toBeNull()
  })

  it('rejects tokens presented for a different user or session', async () => {
    const { issueResumeToken, verifyResumeToken } = await importResumeToken(SECRET)
    const token = issueResumeToken(USER_ID, SESSION_ID, { threadId: 'thread-1' })!

    expect(verifyResumeToken(token, 'user-2', SESSION_ID)).toBeNull()
    expect(verifyResumeToken(token, USER_ID, 'session-2')).toBeNull()
  })

  it.each([
    ['non-string', 42],
    ['empty', ''],
    ['missing signature', 'payload'],
    ['invalid characters', 'payload.signature!'],
    ['oversized', 'a'.repeat(2049)],
  ])('rejects %s tokens', async (_description: string, token: unknown) => {
    const { verifyResumeToken } = await importResumeToken(SECRET)

    expect(verifyResumeToken(token, USER_ID, SESSION_ID)).toBeNull()
  })

  it('disables token issue and verification without a secret in development', async () => {
    const { issueResumeToken, verifyResumeToken } = await importResumeToken(undefined, 'development')

    expect(issueResumeToken(USER_ID, SESSION_ID, { threadId: 'thread-1' })).toBeUndefined()
    expect(verifyResumeToken('payload.signature', USER_ID, SESSION_ID)).toBeNull()
  })

  it('requires a secret outside development', async () => {
    await expect(importResumeToken(undefined, 'production')).rejects.toThrow(
      'RESUME_TOKEN_SECRET is required outside development',
    )
  })
})
