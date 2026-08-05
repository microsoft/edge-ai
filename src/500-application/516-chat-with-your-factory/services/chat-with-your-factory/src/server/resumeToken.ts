import { createHmac, timingSafeEqual } from 'crypto'

const RESUME_TOKEN_LIFETIME_MS = 30 * 24 * 60 * 60 * 1000
const MAX_TOKEN_LENGTH = 2048
const MAX_ENCODED_PAYLOAD_LENGTH = 1536
const MAX_POINTER_LENGTH = 512
const BASE64URL_RE = /^[A-Za-z0-9_-]+$/
const SECRET = process.env.RESUME_TOKEN_SECRET

if (!SECRET && process.env.NODE_ENV !== 'development') {
  throw new Error('RESUME_TOKEN_SECRET is required outside development')
}

const SIGNING_KEY = SECRET
  ? createHmac('sha256', SECRET).update('chat-with-your-factory:resume-token:v1').digest()
  : undefined

export interface ResumePointers {
  conversationId?: string
  threadId?: string
}

interface ResumePayload extends ResumePointers {
  expiresAt: number
  sessionId: string
  userId: string
}

function isBoundedPointer(value: unknown): value is string {
  return typeof value === 'string' && value.length > 0 && value.length <= MAX_POINTER_LENGTH
}

function encodePayload(payload: ResumePayload): string {
  return Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url')
}

function sign(encodedPayload: string): Buffer {
  return createHmac('sha256', SIGNING_KEY!).update(`${encodedPayload.length}:${encodedPayload}`).digest()
}

export function issueResumeToken(
  userId: string,
  sessionId: string,
  pointers: ResumePointers,
): string | undefined {
  if (!SIGNING_KEY) return undefined

  const payload: ResumePayload = {
    userId,
    sessionId,
    expiresAt: Date.now() + RESUME_TOKEN_LIFETIME_MS,
    ...(isBoundedPointer(pointers.conversationId) && { conversationId: pointers.conversationId }),
    ...(isBoundedPointer(pointers.threadId) && { threadId: pointers.threadId }),
  }
  const encodedPayload = encodePayload(payload)
  if (encodedPayload.length > MAX_ENCODED_PAYLOAD_LENGTH) return undefined
  const signature = sign(encodedPayload).toString('base64url')
  return `${encodedPayload}.${signature}`
}

export function verifyResumeToken(
  token: unknown,
  expectedUserId: string,
  expectedSessionId: string,
): ResumePointers | null {
  if (!SIGNING_KEY || typeof token !== 'string' || token.length === 0 || token.length > MAX_TOKEN_LENGTH) {
    return null
  }

  const parts = token.split('.')
  if (parts.length !== 2) return null
  const [encodedPayload, encodedSignature] = parts
  if (
    encodedPayload.length === 0 ||
    encodedPayload.length > MAX_ENCODED_PAYLOAD_LENGTH ||
    !BASE64URL_RE.test(encodedPayload) ||
    !BASE64URL_RE.test(encodedSignature)
  ) {
    return null
  }

  let providedSignature: Buffer
  try {
    providedSignature = Buffer.from(encodedSignature, 'base64url')
  } catch {
    return null
  }
  if (providedSignature.toString('base64url') !== encodedSignature) return null
  const expectedSignature = sign(encodedPayload)
  if (
    providedSignature.length !== expectedSignature.length ||
    !timingSafeEqual(providedSignature, expectedSignature)
  ) {
    return null
  }

  try {
    const decoded = Buffer.from(encodedPayload, 'base64url')
    if (decoded.toString('base64url') !== encodedPayload) return null
    const payload = JSON.parse(decoded.toString('utf8')) as Record<string, unknown>
    const allowedKeys = new Set(['userId', 'sessionId', 'expiresAt', 'conversationId', 'threadId'])
    if (Object.keys(payload).some(key => !allowedKeys.has(key))) return null
    if (
      payload.userId !== expectedUserId ||
      payload.sessionId !== expectedSessionId ||
      typeof payload.expiresAt !== 'number' ||
      !Number.isSafeInteger(payload.expiresAt) ||
      payload.expiresAt <= Date.now() ||
      (payload.conversationId !== undefined && !isBoundedPointer(payload.conversationId)) ||
      (payload.threadId !== undefined && !isBoundedPointer(payload.threadId))
    ) {
      return null
    }
    return {
      ...(payload.conversationId !== undefined && { conversationId: payload.conversationId }),
      ...(payload.threadId !== undefined && { threadId: payload.threadId }),
    }
  } catch {
    return null
  }
}