/* eslint-env browser */
/* global indexedDB */
import { logger } from '../utils/index.js';

/**
 * Storage Manager for Learning Path Data
 *
 * Provides a unified interface for storing and retrieving learning path data
 * using various browser storage mechanisms (localStorage, sessionStorage, IndexedDB).
 * Includes automatic fallback, capacity management, and error handling.
 *
 * Features:
 * - Multi-storage backend support (localStorage, sessionStorage, IndexedDB)
 * - Automatic fallback when storage is unavailable
 * - Capacity monitoring and management
 * - Data expiration and cleanup
 * - Error handling and recovery
 * - Cross-browser compatibility
 */

/**
 * Custom error class for storage operations
 */
export class StorageError extends Error {
  constructor(message, code = 'STORAGE_ERROR', details = null) {
    super(message);
    this.name = 'StorageError';
    this.code = code;
    this.details = details;
    this.timestamp = new Date().toISOString();
  }
}

/**
 * Storage backend interface
 */
class StorageBackend {
  async initialize() { throw new Error('Not implemented'); }
  async getItem(_key) { throw new Error('Not implemented'); }
  async setItem(_key, _value) { throw new Error('Not implemented'); }
  async removeItem(_key) { throw new Error('Not implemented'); }
  async getAllKeys() { throw new Error('Not implemented'); }
  async clear() { throw new Error('Not implemented'); }
  getCapacityInfo() { throw new Error('Not implemented'); }
  isAvailable() { throw new Error('Not implemented'); }
}

/**
 * localStorage backend implementation
 */
class LocalStorageBackend extends StorageBackend {
  constructor() {
    super();
    this.name = 'localStorage';
    this.keyPrefix = 'lps_'; // Learning Path Storage prefix
  }

  async initialize() {
    // Test localStorage availability
    if (!this.isAvailable()) {
      throw new StorageError('localStorage not available', 'UNAVAILABLE');
    }
    return true;
  }

  async getItem(key) {
    try {
      const prefixedKey = this.keyPrefix + key;
      const item = localStorage.getItem(prefixedKey);
      return item ? JSON.parse(item) : null;
    } catch (_error) {
      throw new StorageError(`Failed to get item: ${key}`, 'GET_ERROR', _error);
    }
  }

  async setItem(key, value) {
    try {
      const prefixedKey = this.keyPrefix + key;
      const serializedValue = JSON.stringify(value);
      localStorage.setItem(prefixedKey, serializedValue);
      return true;
    } catch (_error) {
      if (_error.name === 'QuotaExceededError') {
        throw new StorageError('Storage quota exceeded', 'QUOTA_EXCEEDED', _error);
      }
      throw new StorageError(`Failed to set item: ${key}`, 'SET_ERROR', _error);
    }
  }

  async removeItem(key) {
    try {
      const prefixedKey = this.keyPrefix + key;
      localStorage.removeItem(prefixedKey);
      return true;
    } catch (_error) {
      throw new StorageError(`Failed to remove item: ${key}`, 'REMOVE_ERROR', _error);
    }
  }

  async getAllKeys() {
    try {
      const keys = [];
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith(this.keyPrefix)) {
          keys.push(key.substring(this.keyPrefix.length));
        }
      }
      return keys;
    } catch (_error) {
      throw new StorageError('Failed to get all keys', 'KEYS_ERROR', _error);
    }
  }

  async clear() {
    try {
      const keys = await this.getAllKeys();
      for (const key of keys) {
        await this.removeItem(key);
      }
      return true;
    } catch (_error) {
      throw new StorageError('Failed to clear storage', 'CLEAR_ERROR', _error);
    }
  }

  getCapacityInfo() {
    try {
      // Estimate localStorage usage
      let usedSpace = 0;
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith(this.keyPrefix)) {
          const value = localStorage.getItem(key);
          usedSpace += key.length + (value ? value.length : 0);
        }
      }

      return {
        used: usedSpace,
        available: 5 * 1024 * 1024 - usedSpace, // Assume 5MB limit
        total: 5 * 1024 * 1024,
        unit: 'bytes'
      };
    } catch (_error) {
      return { used: 0, available: 0, total: 0, unit: 'bytes', error: _error.message };
    }
  }

  isAvailable() {
    try {
      const testKey = '__lps_test__';
      localStorage.setItem(testKey, 'test');
      localStorage.removeItem(testKey);
      return true;
    } catch (_error) {
      return false;
    }
  }
}

/**
 * sessionStorage backend implementation
 */
class SessionStorageBackend extends StorageBackend {
  constructor() {
    super();
    this.name = 'sessionStorage';
    this.keyPrefix = 'lps_session_';
  }

  async initialize() {
    if (!this.isAvailable()) {
      throw new StorageError('sessionStorage not available', 'UNAVAILABLE');
    }
    return true;
  }

  async getItem(key) {
    try {
      const prefixedKey = this.keyPrefix + key;
      const item = sessionStorage.getItem(prefixedKey);
      return item ? JSON.parse(item) : null;
    } catch (_error) {
      throw new StorageError(`Failed to get item: ${key}`, 'GET_ERROR', _error);
    }
  }

  async setItem(key, value) {
    try {
      const prefixedKey = this.keyPrefix + key;
      const serializedValue = JSON.stringify(value);
      sessionStorage.setItem(prefixedKey, serializedValue);
      return true;
    } catch (_error) {
      if (_error.name === 'QuotaExceededError') {
        throw new StorageError('Storage quota exceeded', 'QUOTA_EXCEEDED', _error);
      }
      throw new StorageError(`Failed to set item: ${key}`, 'SET_ERROR', _error);
    }
  }

  async removeItem(key) {
    try {
      const prefixedKey = this.keyPrefix + key;
      sessionStorage.removeItem(prefixedKey);
      return true;
    } catch (_error) {
      throw new StorageError(`Failed to remove item: ${key}`, 'REMOVE_ERROR', _error);
    }
  }

  async getAllKeys() {
    try {
      const keys = [];
      for (let i = 0; i < sessionStorage.length; i++) {
        const key = sessionStorage.key(i);
        if (key && key.startsWith(this.keyPrefix)) {
          keys.push(key.substring(this.keyPrefix.length));
        }
      }
      return keys;
    } catch (_error) {
      throw new StorageError('Failed to get all keys', 'KEYS_ERROR', _error);
    }
  }

  async clear() {
    try {
      const keys = await this.getAllKeys();
      for (const key of keys) {
        await this.removeItem(key);
      }
      return true;
    } catch (_error) {
      throw new StorageError('Failed to clear storage', 'CLEAR_ERROR', _error);
    }
  }

  getCapacityInfo() {
    try {
      let usedSpace = 0;
      for (let i = 0; i < sessionStorage.length; i++) {
        const key = sessionStorage.key(i);
        if (key && key.startsWith(this.keyPrefix)) {
          const value = sessionStorage.getItem(key);
          usedSpace += key.length + (value ? value.length : 0);
        }
      }

      return {
        used: usedSpace,
        available: 5 * 1024 * 1024 - usedSpace,
        total: 5 * 1024 * 1024,
        unit: 'bytes'
      };
    } catch (_error) {
      return { used: 0, available: 0, total: 0, unit: 'bytes', error: _error.message };
    }
  }

  isAvailable() {
    try {
      const testKey = '__lps_session_test__';
      sessionStorage.setItem(testKey, 'test');
      sessionStorage.removeItem(testKey);
      return true;
    } catch (_error) {
      return false;
    }
  }
}

/**
 * IndexedDB backend implementation
 */
class IndexedDBBackend extends StorageBackend {
  constructor() {
    super();
    this.name = 'IndexedDB';
    this.dbName = 'LearningPathStorage';
    this.dbVersion = 1;
    this.storeName = 'learningPaths';
    this.db = null;
  }

  async initialize() {
    if (!this.isAvailable()) {
      throw new StorageError('IndexedDB not available', 'UNAVAILABLE');
    }

    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, this.dbVersion);

      request.onerror = () => {
        reject(new StorageError('Failed to open IndexedDB', 'DB_ERROR', request.error));
      };

      request.onsuccess = () => {
        this.db = request.result;
        resolve(true);
      };

      request.onupgradeneeded = (event) => {
        const db = event.target.result;
        if (!db.objectStoreNames.contains(this.storeName)) {
          const store = db.createObjectStore(this.storeName, { keyPath: 'key' });
          store.createIndex('timestamp', 'timestamp', { unique: false });
        }
      };
    });
  }

  async getItem(key) {
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.storeName], 'readonly');
      const store = transaction.objectStore(this.storeName);
      const request = store.get(key);

      request.onerror = () => {
        reject(new StorageError(`Failed to get item: ${key}`, 'GET_ERROR', request.error));
      };

      request.onsuccess = () => {
        const result = request.result;
        resolve(result ? result.value : null);
      };
    });
  }

  async setItem(key, value) {
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.storeName], 'readwrite');
      const store = transaction.objectStore(this.storeName);
      const data = {
        key: key,
        value: value,
        timestamp: new Date().toISOString()
      };
      const request = store.put(data);

      request.onerror = () => {
        reject(new StorageError(`Failed to set item: ${key}`, 'SET_ERROR', request.error));
      };

      request.onsuccess = () => {
        resolve(true);
      };
    });
  }

  async removeItem(key) {
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.storeName], 'readwrite');
      const store = transaction.objectStore(this.storeName);
      const request = store.delete(key);

      request.onerror = () => {
        reject(new StorageError(`Failed to remove item: ${key}`, 'REMOVE_ERROR', request.error));
      };

      request.onsuccess = () => {
        resolve(true);
      };
    });
  }

  async getAllKeys() {
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.storeName], 'readonly');
      const store = transaction.objectStore(this.storeName);
      const request = store.getAllKeys();

      request.onerror = () => {
        reject(new StorageError('Failed to get all keys', 'KEYS_ERROR', request.error));
      };

      request.onsuccess = () => {
        resolve(request.result || []);
      };
    });
  }

  async clear() {
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.storeName], 'readwrite');
      const store = transaction.objectStore(this.storeName);
      const request = store.clear();

      request.onerror = () => {
        reject(new StorageError('Failed to clear storage', 'CLEAR_ERROR', request.error));
      };

      request.onsuccess = () => {
        resolve(true);
      };
    });
  }

  getCapacityInfo() {
    // IndexedDB capacity is harder to determine
    return {
      used: 0,
      available: 50 * 1024 * 1024, // Assume 50MB available
      total: 50 * 1024 * 1024,
      unit: 'bytes',
      note: 'IndexedDB capacity estimation'
    };
  }

  isAvailable() {
    return 'indexedDB' in window && indexedDB !== null;
  }
}

/**
 * Memory backend for fallback (non-persistent)
 */
class MemoryBackend extends StorageBackend {
  constructor() {
    super();
    this.name = 'Memory';
    this.data = new Map();
  }

  async initialize() {
    // Memory storage is always available
    return true;
  }

  async getItem(key) {
    return this.data.get(key) || null;
  }

  async setItem(key, value) {
    this.data.set(key, value);
    return true;
  }

  async removeItem(key) {
    this.data.delete(key);
    return true;
  }

  async getAllKeys() {
    return Array.from(this.data.keys());
  }

  async clear() {
    this.data.clear();
    return true;
  }

  getCapacityInfo() {
    const used = this.data.size * 100; // Rough estimate
    return {
      used: used,
      available: Infinity,
      total: Infinity,
      unit: 'bytes',
      note: 'Memory storage (non-persistent)'
    };
  }

  isAvailable() {
    return true; // Memory is always available
  }
}

/**
 * Main Storage Manager class
 * Manages multiple storage backends with automatic fallback
 */
export class StorageManager {
  /**
   * Creates a new StorageManager instance
   * @param {Object} options - Configuration options
   */
  constructor(options = {}) {
    this.options = {
      preferredBackends: ['IndexedDB', 'localStorage', 'sessionStorage', 'Memory'],
      maxRetries: 3,
      retryDelay: 1000,
      autoCleanup: true,
      cleanupInterval: 24 * 60 * 60 * 1000, // 24 hours
      maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days
      ...options
    };

    // Initialize backends
    this.backends = {
      'localStorage': new LocalStorageBackend(),
      'sessionStorage': new SessionStorageBackend(),
      'IndexedDB': new IndexedDBBackend(),
      'Memory': new MemoryBackend()
    };

    this.activeBackend = null;
    this.isInitialized = false;
    this.cleanupTimer = null;

    this.logger = options.logger || this._createDefaultLogger();
  }

  /**
   * Initializes the storage manager
   * @returns {Promise<boolean>} Success status
   */
  async initialize() {
    if (this.isInitialized) {
      this.logger.warn('StorageManager already initialized');
      return true;
    }

    // Try to initialize backends in preference order
    for (const backendName of this.options.preferredBackends) {
      const backend = this.backends[backendName];
      if (!backend) {
        this.logger.warn(`Unknown backend: ${backendName}`);
        continue;
      }

      try {
        if (backend.isAvailable()) {
          await backend.initialize();
          this.activeBackend = backend;
          this.logger.info(`Storage backend initialized: ${backendName}`);
          break;
        } else {
          this.logger.debug(`Backend not available: ${backendName}`);
        }
      } catch (_error) {
        this.logger.warn(`Failed to initialize backend ${backendName}:`, _error);
      }
    }

    if (!this.activeBackend) {
      throw new StorageError('No storage backend available', 'NO_BACKEND');
    }

    // Start automatic cleanup if enabled
    if (this.options.autoCleanup) {
      this._startAutoCleanup();
    }

    this.isInitialized = true;
    this.logger.info('StorageManager initialized successfully');
    return true;
  }

  /**
   * Gets an item from storage
   * @param {string} key - Item key
   * @returns {Promise<any>} Item value or null if not found
   */
  async getItem(key) {
    this._ensureInitialized();
    return this._withRetry(async () => {
      const result = await this.activeBackend.getItem(key);

      // Check expiration if item has timestamp
      if (result && result.timestamp && this.options.maxAge > 0) {
        const age = Date.now() - new Date(result.timestamp).getTime();
        if (age > this.options.maxAge) {
          await this.removeItem(key);
          return null;
        }
      }

      return result;
    });
  }

  /**
   * Sets an item in storage
   * @param {string} key - Item key
   * @param {any} value - Item value
   * @returns {Promise<boolean>} Success status
   */
  async setItem(key, value) {
    this._ensureInitialized();
    return this._withRetry(async () => {
      // Add timestamp for expiration tracking
      const itemWithTimestamp = {
        ...value,
        timestamp: value.timestamp || new Date().toISOString()
      };

      return await this.activeBackend.setItem(key, itemWithTimestamp);
    });
  }

  /**
   * Removes an item from storage
   * @param {string} key - Item key
   * @returns {Promise<boolean>} Success status
   */
  async removeItem(key) {
    this._ensureInitialized();
    return this._withRetry(async () => {
      return await this.activeBackend.removeItem(key);
    });
  }

  /**
   * Gets all keys from storage
   * @returns {Promise<Array<string>>} Array of keys
   */
  async getAllKeys() {
    this._ensureInitialized();
    return this._withRetry(async () => {
      return await this.activeBackend.getAllKeys();
    });
  }

  /**
   * Clears all items from storage
   * @returns {Promise<boolean>} Success status
   */
  async clear() {
    this._ensureInitialized();
    return this._withRetry(async () => {
      return await this.activeBackend.clear();
    });
  }

  /**
   * Gets storage capacity information
   * @returns {Object} Capacity information
   */
  getCapacityInfo() {
    this._ensureInitialized();
    return this.activeBackend.getCapacityInfo();
  }

  /**
   * Gets current storage backend information
   * @returns {Object} Backend information
   */
  getBackendInfo() {
    return {
      active: this.activeBackend ? this.activeBackend.name : null,
      available: Object.keys(this.backends).filter(name =>
        this.backends[name].isAvailable()
      ),
      isInitialized: this.isInitialized
    };
  }

  /**
   * Performs manual cleanup of expired items
   * @returns {Promise<number>} Number of items cleaned up
   */
  async cleanup() {
    this._ensureInitialized();

    if (this.options.maxAge <= 0) {
      return 0; // No expiration configured
    }

    let cleanedCount = 0;
    const keys = await this.getAllKeys();

    for (const key of keys) {
      try {
        const item = await this.activeBackend.getItem(key);
        if (item && item.timestamp) {
          const age = Date.now() - new Date(item.timestamp).getTime();
          if (age > this.options.maxAge) {
            await this.removeItem(key);
            cleanedCount++;
          }
        }
      } catch (_error) {
        this.logger.warn(`Failed to cleanup item ${key}:`, _error);
      }
    }

    this.logger.info(`Cleaned up ${cleanedCount} expired items`);
    return cleanedCount;
  }

  /**
   * Destroys the storage manager and cleans up resources
   */
  destroy() {
    try {
      // Stop auto cleanup
      if (this.cleanupTimer) {
        clearInterval(this.cleanupTimer);
        this.cleanupTimer = null;
      }

      // Clear state
      this.activeBackend = null;
      this.isInitialized = false;

      this.logger.debug('StorageManager destroyed');
    } catch (_error) {
      logger.warn('Error during StorageManager cleanup:', _error);
    }
  }

  /**
   * Private method to ensure manager is initialized
   * @private
   */
  _ensureInitialized() {
    if (!this.isInitialized) {
      throw new StorageError('StorageManager not initialized', 'NOT_INITIALIZED');
    }
  }

  /**
   * Private method to execute operations with retry logic
   * @private
   */
  async _withRetry(operation) {
    let lastError;

    for (let attempt = 0; attempt < this.options.maxRetries; attempt++) {
      try {
        return await operation();
      } catch (_error) {
        lastError = _error;

        if (attempt < this.options.maxRetries - 1) {
          this.logger.warn(`Operation failed (attempt ${attempt + 1}), retrying:`, _error);
          await this._delay(this.options.retryDelay);
        }
      }
    }

    throw lastError;
  }

  /**
   * Private method to start automatic cleanup
   * @private
   */
  _startAutoCleanup() {
    if (this.cleanupTimer) {
      clearInterval(this.cleanupTimer);
    }

    this.cleanupTimer = setInterval(async () => {
      try {
        await this.cleanup();
      } catch (_error) {
        this.logger.error('Auto cleanup failed:', _error);
      }
    }, this.options.cleanupInterval);

    this.logger.debug('Auto cleanup started with interval:', this.options.cleanupInterval);
  }

  /**
   * Private method to create a delay
   * @private
   */
  _delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Private method to create a default logger
   * @private
   */
  _createDefaultLogger() {
    return {
      debug: () => {}, // Silent by default
      info: logger.info.bind(logger),
      warn: logger.warn.bind(logger),
      error: logger.error.bind(logger)
    };
  }
}

export default StorageManager;
