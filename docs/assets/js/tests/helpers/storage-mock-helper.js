/**
 * Storage Mock Helper
 * Comprehensive storage API mocking utilities for test isolation
 * Provides robust mocking for localStorage, sessionStorage, and IndexedDB
 *
 * @description Ensures complete storage state isolation between tests
 * @version 1.0.0
 */

import { vi } from 'vitest';

/**
 * Storage Mock Helper Class
 * Manages storage API mocks with comprehensive state isolation
 */
export class StorageMockHelper {
  constructor() {
    this.originalLocalStorage = global.localStorage;
    this.originalSessionStorage = global.sessionStorage;
    this.originalIndexedDB = global.indexedDB;

    // Track active mocks for cleanup
    this.activeMocks = new Set();
    this.storageData = new Map();
  }

  /**
   * Create comprehensive localStorage mock with full API support
   * @param {Object} initialData - Initial storage data
   * @returns {Object} Mock localStorage object
   */
  createLocalStorageMock(initialData = {}) {
    const data = new Map(Object.entries(initialData));

    const mock = {
      getItem: vi.fn((key) => {
        return data.get(key) || null;
      }),

      setItem: vi.fn((key, value) => {
        if (typeof key !== 'string' || typeof value !== 'string') {
          throw new Error('Storage keys and values must be strings');
        }
        data.set(key, value);
      }),

      removeItem: vi.fn((key) => {
        data.delete(key);
      }),

      clear: vi.fn(() => {
        data.clear();
      }),

      key: vi.fn((index) => {
        const keys = Array.from(data.keys());
        return keys[index] || null;
      }),

      get length() {
        return this._length !== undefined ? this._length : data.size;
      },

      set length(value) {
        this._length = value;
      },

      // Internal method for direct data access in tests
      _getData: () => data,
      _setData: (newData) => {
        data.clear();
        Object.entries(newData).forEach(([key, value]) => {
          data.set(key, value);
        });
      }
    };

    // Track for cleanup
    this.activeMocks.add(mock);
    this.storageData.set(mock, data);

    return mock;
  }

  /**
   * Create comprehensive sessionStorage mock with full API support
   * @param {Object} initialData - Initial storage data
   * @returns {Object} Mock sessionStorage object
   */
  createSessionStorageMock(initialData = {}) {
    return this.createLocalStorageMock(initialData);
  }

  /**
   * Create IndexedDB mock with essential operations
   * @returns {Object} Mock IndexedDB object
   */
  createIndexedDBMock() {
    const databases = new Map();

    const mock = {
      open: vi.fn((name, version = 1) => {
        return new Promise((resolve, reject) => {
          setTimeout(() => {
            if (!databases.has(name)) {
              databases.set(name, { version, objectStores: new Map() });
            }

            const db = {
              name,
              version,
              objectStoreNames: Array.from(databases.get(name).objectStores.keys()),

              createObjectStore: vi.fn((storeName, options = {}) => {
                const objectStore = {
                  name: storeName,
                  add: vi.fn(),
                  put: vi.fn(),
                  get: vi.fn(),
                  delete: vi.fn(),
                  clear: vi.fn(),
                  count: vi.fn()
                };
                databases.get(name).objectStores.set(storeName, objectStore);
                return objectStore;
              }),

              transaction: vi.fn((storeNames, mode = 'readonly') => {
                return {
                  objectStore: vi.fn((storeName) => {
                    return databases.get(name).objectStores.get(storeName);
                  }),
                  oncomplete: null,
                  onerror: null,
                  onabort: null
                };
              }),

              close: vi.fn(),
              deleteObjectStore: vi.fn()
            };

            resolve(db);
          }, 0);
        });
      }),

      deleteDatabase: vi.fn((name) => {
        return new Promise((resolve) => {
          setTimeout(() => {
            databases.delete(name);
            resolve();
          }, 0);
        });
      }),

      // Internal methods for testing
      _getDatabases: () => databases,
      _clearDatabases: () => databases.clear()
    };

    this.activeMocks.add(mock);
    return mock;
  }

  /**
   * Create storage mock that simulates quota exceeded errors
   * @param {number} maxSize - Maximum storage size in bytes
   * @returns {Object} Mock storage with quota limits
   */
  createQuotaLimitedStorageMock(maxSize = 5 * 1024 * 1024) { // 5MB default
    let currentSize = 0;
    const data = new Map();

    const calculateSize = (key, value) => {
      return new Blob([key + value]).size;
    };

    const mock = {
      getItem: vi.fn((key) => {
        return data.get(key) || null;
      }),

      setItem: vi.fn((key, value) => {
        const itemSize = calculateSize(key, value);
        const existingSize = data.has(key) ? calculateSize(key, data.get(key)) : 0;
        const newSize = currentSize - existingSize + itemSize;

        if (newSize > maxSize) {
          const error = new Error('QuotaExceededError');
          error.name = 'QuotaExceededError';
          throw error;
        }

        currentSize = newSize;
        data.set(key, value);
      }),

      removeItem: vi.fn((key) => {
        if (data.has(key)) {
          const itemSize = calculateSize(key, data.get(key));
          currentSize -= itemSize;
          data.delete(key);
        }
      }),

      clear: vi.fn(() => {
        data.clear();
        currentSize = 0;
      }),

      key: vi.fn((index) => {
        const keys = Array.from(data.keys());
        return keys[index] || null;
      }),

      get length() {
        return data.size;
      },

      // Quota management methods
      _getCurrentSize: () => currentSize,
      _getMaxSize: () => maxSize,
      _getUsagePercentage: () => currentSize / maxSize,
      _type: 'quota-limited' // Add type identifier
    };

    this.activeMocks.add(mock);
    return mock;
  }

  /**
   * Create storage mock that simulates permission/security errors
   * @returns {Object} Mock storage that throws security errors
   */
  createSecurityRestrictedStorageMock() {
    const securityError = new Error('SecurityError: Access to storage is denied');
    securityError.name = 'SecurityError';

    const mock = {
      getItem: vi.fn(() => {
        throw securityError;
      }),
      setItem: vi.fn(() => {
        throw securityError;
      }),
      removeItem: vi.fn(() => {
        throw securityError;
      }),
      clear: vi.fn(() => {
        throw securityError;
      }),
      key: vi.fn(() => {
        throw securityError;
      }),
      length: 0
    };

    this.activeMocks.add(mock);
    return mock;
  }

  /**
   * Create storage mock that simulates private browsing mode limitations
   * @returns {Object} Mock storage with private browsing restrictions
   */
  createPrivateBrowsingStorageMock() {
    const mock = {
      getItem: vi.fn(() => null),

      setItem: vi.fn(() => {
        // Safari private browsing throws QuotaExceededError on setItem
        const error = new Error('QuotaExceededError');
        error.name = 'QuotaExceededError';
        throw error;
      }),

      removeItem: vi.fn(),
      clear: vi.fn(),
      key: vi.fn(() => null),
      length: 0,
      _type: 'private-browsing' // Add type identifier
    };

    this.activeMocks.add(mock);
    return mock;
  }

  /**
   * Apply storage mocks to global window object
   * @param {Object} options - Mock configuration
   * @param {Object} options.localStorage - localStorage mock
   * @param {Object} options.sessionStorage - sessionStorage mock
   * @param {Object} options.indexedDB - indexedDB mock
   */
  applyMocks({ localStorage, sessionStorage, indexedDB }) {
    if (localStorage) {
      Object.defineProperty(window, 'localStorage', {
        value: localStorage,
        writable: true,
        configurable: true
      });
    }

    if (sessionStorage) {
      Object.defineProperty(window, 'sessionStorage', {
        value: sessionStorage,
        writable: true,
        configurable: true
      });
    }

    if (indexedDB) {
      Object.defineProperty(window, 'indexedDB', {
        value: indexedDB,
        writable: true,
        configurable: true
      });
    }
  }

  /**
   * Setup complete storage environment for learning progress tracking
   * @param {Object} options - Configuration options
   * @returns {Object} All created mocks
   */
  setupLearningProgressMocks(options = {}) {
    const {
      initialProgress = {},
      enableQuotaLimits = false,
      maxQuotaSize = 5 * 1024 * 1024,
      simulatePrivateBrowsing = false,
      simulateSecurityRestrictions = false
    } = options;

    let localStorage, sessionStorage;

    if (simulateSecurityRestrictions) {
      localStorage = this.createSecurityRestrictedStorageMock();
      sessionStorage = this.createSecurityRestrictedStorageMock();
    } else if (simulatePrivateBrowsing) {
      localStorage = this.createPrivateBrowsingStorageMock();
      sessionStorage = this.createPrivateBrowsingStorageMock();
    } else if (enableQuotaLimits) {
      localStorage = this.createQuotaLimitedStorageMock(maxQuotaSize);
      sessionStorage = this.createQuotaLimitedStorageMock(maxQuotaSize);
    } else {
      localStorage = this.createLocalStorageMock(initialProgress);
      sessionStorage = this.createSessionStorageMock();
    }

    const indexedDB = this.createIndexedDBMock();

    this.applyMocks({ localStorage, sessionStorage, indexedDB });

    return { localStorage, sessionStorage, indexedDB };
  }

  /**
   * Verify complete storage state isolation
   * @returns {Array} Array of isolation issues found
   */
  verifyStorageIsolation() {
    const issues = [];

    // Check localStorage state
    if (window.localStorage && typeof window.localStorage.length !== 'undefined') {
      if (window.localStorage.length > 0) {
        issues.push(`localStorage contains ${window.localStorage.length} items after test`);
      }
    }

    // Check sessionStorage state
    if (window.sessionStorage && typeof window.sessionStorage.length !== 'undefined') {
      if (window.sessionStorage.length > 0) {
        issues.push(`sessionStorage contains ${window.sessionStorage.length} items after test`);
      }
    }

    // Check IndexedDB state (basic check)
    if (window.indexedDB && window.indexedDB._getDatabases) {
      const databases = window.indexedDB._getDatabases();
      if (databases.size > 0) {
        issues.push(`IndexedDB contains ${databases.size} databases after test`);
      }
    }

    return issues;
  }

  /**
   * Clean up all storage mocks and restore original APIs
   */
  cleanup() {
    // Clear all mock data
    this.activeMocks.forEach(mock => {
      if (mock._getData) {
        mock._getData().clear();
      }
      if (mock._clearDatabases) {
        mock._clearDatabases();
      }
    });

    this.activeMocks.clear();
    this.storageData.clear();

    // Restore original APIs
    if (typeof window !== 'undefined') {
      if (this.originalLocalStorage) {
        Object.defineProperty(window, 'localStorage', {
          value: this.originalLocalStorage,
          writable: true,
          configurable: true
        });
      }

      if (this.originalSessionStorage) {
        Object.defineProperty(window, 'sessionStorage', {
          value: this.originalSessionStorage,
          writable: true,
          configurable: true
        });
      }

      if (this.originalIndexedDB) {
        Object.defineProperty(window, 'indexedDB', {
          value: this.originalIndexedDB,
          writable: true,
          configurable: true
        });
      }
    }
  }

  /**
   * Reset all storage mock data without recreating mocks
   */
  resetMockData() {
    this.activeMocks.forEach(mock => {
      if (mock._getData) {
        mock._getData().clear();
      }
      if (mock.clear) {
        mock.clear();
      }
    });
  }

  /**
   * Simulate learning progress storage scenarios
   * @param {string} scenario - Scenario type
   * @returns {Object} Scenario-specific mocks
   */
  simulateLearningScenario(scenario) {
    switch (scenario) {
      case 'normal-progress':
        return this.setupLearningProgressMocks({
          initialProgress: {
            'learning-path-progress': JSON.stringify({
              'ai-fundamentals': { completed: 3, total: 10 },
              'prompt-engineering': { completed: 1, total: 5 }
            })
          }
        });

      case 'storage-full':
        return this.setupLearningProgressMocks({
          enableQuotaLimits: true,
          maxQuotaSize: 1024 // Very small quota
        });

      case 'private-browsing':
        return this.setupLearningProgressMocks({
          simulatePrivateBrowsing: true
        });

      case 'security-restricted':
        return this.setupLearningProgressMocks({
          simulateSecurityRestrictions: true
        });

      default:
        return this.setupLearningProgressMocks();
    }
  }
}

/**
 * Global storage mock helper instance
 */
export const storageMockHelper = new StorageMockHelper();

/**
 * Utility functions for quick setup
 */

/**
 * Setup storage mocks for learning progress tests
 * @param {Object} options - Configuration options
 * @returns {Object} Created mocks
 */
export function setupProgressStorageMocks(options = {}) {
  return storageMockHelper.setupLearningProgressMocks(options);
}

/**
 * Clean up storage mocks and verify isolation
 * @returns {Array} Any isolation issues found
 */
export function cleanupStorageMocks() {
  const issues = storageMockHelper.verifyStorageIsolation();
  storageMockHelper.cleanup();
  return issues;
}

/**
 * Reset storage mock data between tests
 */
export function resetStorageData() {
  storageMockHelper.resetMockData();
}

/**
 * Simulate specific learning platform storage scenario
 * @param {string} scenario - Scenario type
 * @returns {Object} Scenario mocks
 */
export function simulateStorageScenario(scenario) {
  return storageMockHelper.simulateLearningScenario(scenario);
}
