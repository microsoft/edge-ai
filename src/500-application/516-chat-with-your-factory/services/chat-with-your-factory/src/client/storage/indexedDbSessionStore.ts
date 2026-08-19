import type { Session, TranscriptMessage } from '../../shared/types.js'
import { cleanLogging } from '../../shared/logging.js'

const DB_NAME = 'chat-with-your-factory-continuity'
const DB_VERSION = 1
const SESSIONS_STORE = 'sessions'
const MESSAGES_STORE = 'messages'
const META_STORE = 'meta'
const OWNER_KEY = 'owner'
const DEFAULT_RETENTION_MS = 30 * 24 * 60 * 60 * 1000
const MAX_CLOCK_SKEW_MS = 5 * 60 * 1000

interface OwnerRecord {
  key: string
  userId: string
}

interface StoredMessage extends TranscriptMessage {
  sessionId: string
}

function requestResult<T>(request: IDBRequest<T>): Promise<T> {
  return new Promise((resolve, reject) => {
    request.onsuccess = () => resolve(request.result)
    request.onerror = () => reject(request.error)
  })
}

function transactionDone(transaction: IDBTransaction): Promise<void> {
  return new Promise((resolve, reject) => {
    transaction.oncomplete = () => resolve()
    transaction.onerror = () => reject(transaction.error)
    transaction.onabort = () => reject(transaction.error)
  })
}

function timestampToMilliseconds(value: unknown): number {
  if (typeof value === 'number') return value
  if (typeof value !== 'string' || value.trim().length === 0) return Number.NaN
  const numeric = Number(value)
  return Number.isNaN(numeric) ? Date.parse(value) : numeric
}

function backfillParticipants(store: IDBObjectStore): void {
  const cursorRequest = store.openCursor()
  cursorRequest.onsuccess = () => {
    const cursor = cursorRequest.result
    if (!cursor) return
    const record = cursor.value as Partial<Session>
    const participants = Array.isArray(record.participants) ? record.participants : []
    if (typeof record.userId === 'string' && !participants.includes(record.userId)) {
      const updateRequest = cursor.update({ ...record, participants: [...participants, record.userId] })
      updateRequest.onerror = event => {
        cleanLogging.Warn('device-continuity', 'Participant repair failed', updateRequest.error)
        event.preventDefault()
      }
    } else if (!Array.isArray(record.participants)) {
      const updateRequest = cursor.update({ ...record, participants })
      updateRequest.onerror = event => {
        cleanLogging.Warn('device-continuity', 'Participant repair failed', updateRequest.error)
        event.preventDefault()
      }
    }
    cursor.continue()
  }
}

function messageRange(sessionId: string): IDBKeyRange {
  return IDBKeyRange.bound([sessionId, ''], [sessionId, '\uffff'])
}

export class IndexedDbSessionStore {
  private databasePromise: Promise<IDBDatabase> | undefined

  private open(): Promise<IDBDatabase> {
    if (!this.databasePromise) {
      this.databasePromise = new Promise((resolve, reject) => {
        const request = indexedDB.open(DB_NAME, DB_VERSION)
        request.onupgradeneeded = () => {
          const database = request.result
          const transaction = request.transaction as IDBTransaction
          const sessions = database.objectStoreNames.contains(SESSIONS_STORE)
            ? transaction.objectStore(SESSIONS_STORE)
            : database.createObjectStore(SESSIONS_STORE, { keyPath: 'id' })

          if (!sessions.indexNames.contains('participants')) {
            sessions.createIndex('participants', 'participants', { multiEntry: true })
          }
          if (sessions.indexNames.contains('userId')) {
            sessions.deleteIndex('userId')
          }
          backfillParticipants(sessions)

          const messages = database.objectStoreNames.contains(MESSAGES_STORE)
            ? transaction.objectStore(MESSAGES_STORE)
            : database.createObjectStore(MESSAGES_STORE, { keyPath: ['sessionId', 'id'] })
          if (!messages.indexNames.contains('sessionId')) {
            messages.createIndex('sessionId', 'sessionId')
          }
          if (!database.objectStoreNames.contains(META_STORE)) {
            database.createObjectStore(META_STORE, { keyPath: 'key' })
          }
        }
        request.onsuccess = () => {
          request.result.onversionchange = () => request.result.close()
          resolve(request.result)
        }
        request.onerror = () => reject(request.error)
        request.onblocked = () => reject(new Error('Device-local continuity database upgrade is blocked'))
      })
    }
    return this.databasePromise
  }

  async assertOwner(userId: string): Promise<boolean> {
    const database = await this.open()
    const readTransaction = database.transaction(META_STORE, 'readonly')
    const owner = await requestResult(
      readTransaction.objectStore(META_STORE).get(OWNER_KEY),
    ) as OwnerRecord | undefined

    if (owner?.userId === userId) return false
    const ownerChanged = owner !== undefined
    if (ownerChanged) await this.clearAll()

    const writeTransaction = database.transaction(META_STORE, 'readwrite')
    const completion = transactionDone(writeTransaction)
    writeTransaction.objectStore(META_STORE).put({ key: OWNER_KEY, userId } satisfies OwnerRecord)
    await completion
    return ownerChanged
  }

  async list(userId: string): Promise<Session[]> {
    const database = await this.open()
    let sessions: Session[]
    try {
      const transaction = database.transaction(SESSIONS_STORE, 'readonly')
      sessions = await requestResult(
        transaction.objectStore(SESSIONS_STORE).index('participants').getAll(userId),
      ) as Session[]
    } catch (error) {
      cleanLogging.Warn('device-continuity', 'Participant index unavailable; scanning cache', error)
      const transaction = database.transaction(SESSIONS_STORE, 'readonly')
      const all = await requestResult(transaction.objectStore(SESSIONS_STORE).getAll()) as Session[]
      sessions = all.filter(session =>
        session.userId === userId || session.participants?.includes(userId),
      )
    }
    return sessions
      .filter(session => session && typeof session.id === 'string')
      .sort((left, right) =>
        timestampToMilliseconds(right.lastActivityAt) - timestampToMilliseconds(left.lastActivityAt),
      )
  }

  async saveSession(session: Session): Promise<void> {
    const database = await this.open()
    const transaction = database.transaction(SESSIONS_STORE, 'readwrite')
    const completion = transactionDone(transaction)
    transaction.objectStore(SESSIONS_STORE).put(session)
    await completion
  }

  async deleteSession(sessionId: string): Promise<void> {
    const database = await this.open()
    const transaction = database.transaction([SESSIONS_STORE, MESSAGES_STORE], 'readwrite')
    const completion = transactionDone(transaction)
    transaction.objectStore(SESSIONS_STORE).delete(sessionId)
    transaction.objectStore(MESSAGES_STORE).delete(messageRange(sessionId))
    await completion
  }

  async getMessages(sessionId: string): Promise<TranscriptMessage[]> {
    const database = await this.open()
    let records: StoredMessage[]
    try {
      const transaction = database.transaction(MESSAGES_STORE, 'readonly')
      records = await requestResult(
        transaction.objectStore(MESSAGES_STORE).index('sessionId').getAll(sessionId),
      ) as StoredMessage[]
    } catch (error) {
      cleanLogging.Warn('device-continuity', 'Message index unavailable; scanning cache', error)
      const transaction = database.transaction(MESSAGES_STORE, 'readonly')
      const all = await requestResult(transaction.objectStore(MESSAGES_STORE).getAll()) as StoredMessage[]
      records = all.filter(record => record.sessionId === sessionId)
    }
    return records.map(record => {
      const { sessionId, ...message } = record
      void sessionId
      return message
    })
  }

  async saveMessage(sessionId: string, message: TranscriptMessage): Promise<void> {
    const database = await this.open()
    const transaction = database.transaction(MESSAGES_STORE, 'readwrite')
    const completion = transactionDone(transaction)
    transaction.objectStore(MESSAGES_STORE).put({ ...message, sessionId } satisfies StoredMessage)
    await completion
  }

  async clearAll(): Promise<void> {
    const database = await this.open()
    const transaction = database.transaction([SESSIONS_STORE, MESSAGES_STORE], 'readwrite')
    const completion = transactionDone(transaction)
    transaction.objectStore(SESSIONS_STORE).clear()
    transaction.objectStore(MESSAGES_STORE).clear()
    await completion
  }

  async purgeExpired(retentionMs: number = DEFAULT_RETENTION_MS): Promise<void> {
    if (!Number.isFinite(retentionMs) || retentionMs < 0) {
      throw new RangeError('Retention duration must be finite and non-negative')
    }

    const now = Date.now()
    const cutoff = now - retentionMs
    const futureLimit = now + MAX_CLOCK_SKEW_MS
    const database = await this.open()
    const transaction = database.transaction([SESSIONS_STORE, MESSAGES_STORE], 'readwrite')
    const completion = transactionDone(transaction)
    const sessionsStore = transaction.objectStore(SESSIONS_STORE)
    const messagesStore = transaction.objectStore(MESSAGES_STORE)
    const sessions = await requestResult(sessionsStore.getAll()) as Session[]

    for (const session of sessions) {
      const lastActivity = timestampToMilliseconds(session.lastActivityAt)
      if (!Number.isFinite(lastActivity) || lastActivity < cutoff || lastActivity > futureLimit) {
        sessionsStore.delete(session.id)
        messagesStore.delete(messageRange(session.id))
      }
    }
    await completion
  }
}
