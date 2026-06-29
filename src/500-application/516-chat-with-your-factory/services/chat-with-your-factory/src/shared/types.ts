export interface Session {
  id: string
  userId: string
  threadId?: string
  conversationId?: string
  title: string
  createdAt: string
  lastActivityAt: string
  status: 'active' | 'archived'
  participants: string[]
  participantNames: Record<string, string>
  metadata: {
    machineId?: string
    machineName?: string
  }
}

export interface TranscriptMessage {
  id: string
  role: 'user' | 'assistant'
  text: string
  timestamp: string
  userId?: string
  displayName?: string
  source?: 'voice' | 'text' | 'teams' | 'agent'
  // Voice Live / multi-turn metadata.
  //   turnId    — populated on assistant messages produced by dispatchChat
  //               (Copilot Studio + Foundry stamp it directly; Direct Line
  //               resolves it from the bot reply's replyToId via
  //               directLineClient.consumeTurn). Used by the voicelive
  //               client to correlate SSE replies to its outstanding
  //               dispatches so co-participants' turns don't clear its
  //               pending-turn spinner.
  //   partial   — reserved for future partial-transcript streaming; not
  //               currently populated.
  //   audioUrl  — reserved for future recorded-audio playback references;
  //               not currently populated.
  turnId?: string
  partial?: boolean
  audioUrl?: string
}

export interface UserContext {
  userId: string
  displayName: string
  tenantId?: string
  chatId?: string | null
}

export type AddParticipantErrorCode =
  | 'NO_ACTIVE_SESSION'
  | 'INVALID_INPUT'
  | 'UNAUTHORIZED'
  | 'FORBIDDEN'
  | 'NOT_FOUND'
  | 'SERVER'
  | 'NETWORK'
  | 'UNKNOWN'

export interface AddParticipantError {
  kind: 'add-participant-error'
  code: AddParticipantErrorCode
  message: string
  status?: number
}
