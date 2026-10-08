type ConsoleLevel = 'log' | 'warn' | 'error'

const REPEATED_WHITESPACE = /\s{2,}/g
const MAX_STRING_LENGTH = 500
const MAX_KEY_LENGTH = 100
const MAX_DEPTH = 3
const MAX_LOG_ARGUMENTS = 20
const MAX_ARRAY_ITEMS = 20
const MAX_OBJECT_PROPERTIES = 20
const STRING_TRUNCATION_SENTINEL = '... [truncated]'
const ARRAY_TRUNCATION_SENTINEL = '[Truncated array items]'
const OBJECT_TRUNCATION_KEY = '[Truncated object properties]'

function cleanString(value: string, maxLength = MAX_STRING_LENGTH): string {
  const withoutControlCharacters = Array.from(value, character => {
    const codePoint = character.codePointAt(0) ?? 0
    return codePoint <= 0x1f || (codePoint >= 0x7f && codePoint <= 0x9f) ? ' ' : character
  }).join('')
  const normalized = withoutControlCharacters
    .replace(REPEATED_WHITESPACE, ' ')
    .trim()

  if (normalized.length <= maxLength) return normalized

  const contentLength = Math.max(0, maxLength - STRING_TRUNCATION_SENTINEL.length)
  return `${normalized.slice(0, contentLength)}${STRING_TRUNCATION_SENTINEL}`
}

function sanitizeForLog(value: unknown): unknown {
  const seen = new WeakSet<object>()

  function sanitize(currentValue: unknown, depth: number): unknown {
    try {
      if (currentValue == null) return currentValue

      switch (typeof currentValue) {
        case 'string':
          return cleanString(currentValue)
        case 'number':
        case 'boolean':
        case 'bigint':
          return currentValue
        case 'symbol':
          return cleanString(String(currentValue))
        case 'function':
          return '[Function]'
        case 'object':
          break
        default:
          return cleanString(String(currentValue))
      }

      if (currentValue instanceof Error) {
        return {
          name: cleanString(currentValue.name),
          message: cleanString(currentValue.message),
          stack: currentValue.stack ? cleanString(currentValue.stack) : undefined,
        }
      }

      if (currentValue instanceof Date) {
        return Number.isNaN(currentValue.getTime()) ? '[Invalid Date]' : currentValue.toISOString()
      }

      if (currentValue instanceof URL) return cleanString(currentValue.toString())

      if (seen.has(currentValue)) return '[Circular]'
      if (depth >= MAX_DEPTH) return Array.isArray(currentValue) ? '[Array depth truncated]' : '[Object depth truncated]'
      seen.add(currentValue)

      if (Array.isArray(currentValue)) {
        const result = currentValue
          .slice(0, MAX_ARRAY_ITEMS)
          .map(item => sanitize(item, depth + 1))
        if (currentValue.length > MAX_ARRAY_ITEMS) result.push(ARRAY_TRUNCATION_SENTINEL)
        return result
      }

      const prototype = Object.getPrototypeOf(currentValue)
      if (prototype !== Object.prototype && prototype !== null) return '[Object]'

      const keys = Object.keys(currentValue)
      const result: Record<string, unknown> = {}
      for (const key of keys.slice(0, MAX_OBJECT_PROPERTIES)) {
        const sanitizedKey = cleanString(key, MAX_KEY_LENGTH) || '[Empty key]'
        try {
          result[sanitizedKey] = sanitize((currentValue as Record<string, unknown>)[key], depth + 1)
        } catch {
          result[sanitizedKey] = '[Unserializable property]'
        }
      }
      if (keys.length > MAX_OBJECT_PROPERTIES) {
        result[OBJECT_TRUNCATION_KEY] = keys.length - MAX_OBJECT_PROPERTIES
      }
      return result
    } catch {
      return '[Unserializable value]'
    }
  }

  return sanitize(value, 0)
}

function writeCleanLog(level: ConsoleLevel, scope: string, message: string, ...args: unknown[]): void {
  const output: unknown[] = [`[${cleanString(scope)}] ${cleanString(message)}`]
  output.push(...args.slice(0, MAX_LOG_ARGUMENTS).map(sanitizeForLog))
  if (args.length > MAX_LOG_ARGUMENTS) output.push('[Truncated log arguments]')
  console[level](...output)
}

export const cleanLogging = {
  Log(scope: string, message: string, ...args: unknown[]): void {
    writeCleanLog('log', scope, message, ...args)
  },
  Warn(scope: string, message: string, ...args: unknown[]): void {
    writeCleanLog('warn', scope, message, ...args)
  },
  Error(scope: string, message: string, ...args: unknown[]): void {
    writeCleanLog('error', scope, message, ...args)
  },
}