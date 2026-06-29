import type { AddParticipantError, AddParticipantErrorCode } from './types.js'

export function toAddParticipantError(
  code: AddParticipantErrorCode,
  message: string,
  status?: number,
): AddParticipantError {
  return {
    kind: 'add-participant-error',
    code,
    message,
    ...(status !== undefined ? { status } : {}),
  }
}

export function addParticipantErrorCodeFromStatus(status: number): AddParticipantErrorCode {
  if (status === 400) return 'INVALID_INPUT'
  if (status === 401) return 'UNAUTHORIZED'
  if (status === 403) return 'FORBIDDEN'
  if (status === 404) return 'NOT_FOUND'
  if (status >= 500) return 'SERVER'
  return 'UNKNOWN'
}

export function isAddParticipantError(value: unknown): value is AddParticipantError {
  return Boolean(
    value &&
    typeof value === 'object' &&
    (value as { kind?: string }).kind === 'add-participant-error' &&
    typeof (value as { code?: unknown }).code === 'string' &&
    typeof (value as { message?: unknown }).message === 'string',
  )
}

export function addParticipantErrorUserMessage(error: AddParticipantError): string {
  switch (error.code) {
    case 'NO_ACTIVE_SESSION':
      return 'No active session is selected.'
    case 'INVALID_INPUT':
      return error.message || 'Participant data was invalid.'
    case 'UNAUTHORIZED':
      return 'Authentication is required. Please sign in again.'
    case 'FORBIDDEN':
      return 'You are not allowed to modify this session.'
    case 'NOT_FOUND':
      return 'Session not found. It may have been removed.'
    case 'SERVER':
      return error.message || 'Server error while adding participant.'
    case 'NETWORK':
      return 'Network error while adding participant.'
    default:
      return error.message || 'Unexpected error while adding participant.'
  }
}
