/**
 * Storage APIs Mock Module
 *
 * Comprehensive mocks for browser storage APIs including localStorage, sessionStorage,
 * IndexedDB, and related web storage technologies. These mocks simulate real browser
 * storage behavior including errors, quotas, and cross-browser quirks.
 *
 * Used for testing storage persistence, synchronization, and fallback mechanisms
 * without relying on actual browser storage APIs.
 */

import { vi } from 'vitest';

/**
 * Create a mock localStorage/sessionStorage object
 * @param {Object} options - Configuration options for the mock
 * @returns {Object} Mock storage object
 */
export function createMockWebStorage(options = {}) {
  const {
    shouldThrowOnSetItem = false,
    shouldThrowOnGetItem = false,
    quotaExceeded = false,
    maxStorageSize = 5 * 1024 * 1024, // 5MB default
    initialData = {}
  } = options;

  const storage = new Map(Object.entries(initialData));
  let currentSize = 0;

  // Calculate initial size
  for (const [key, value] of storage.entries()) {
    currentSize += new Blob([key + value]).size;
  }

  const mockStorage = {
    // Core storage methods
    getItem: vi.fn((key) => {
      if (shouldThrowOnGetItem) {
        const error = new Error('SecurityError: Access denied');
        error.name = 'SecurityError';
        throw error;
      }
      return storage.get(key) || null;
    }),

    setItem: vi.fn((key, value) => {
      if (shouldThrowOnSetItem) {
        const error = new Error('SecurityError: Access denied');
        error.name = 'SecurityError';
        throw error;
      }

      const itemSize = new Blob([key + value]).size;
      const existingItem = storage.get(key);
      const existingSize = existingItem ? new Blob([key + existingItem]).size : 0;
      const newSize = currentSize - existingSize + itemSize;

      if (quotaExceeded || newSize > maxStorageSize) {
        const error = new Error('QuotaExceededError: Storage quota exceeded');
        error.name = 'QuotaExceededError';
        throw error;
      }

      storage.set(key, value);
      currentSize = newSize;
    }),

    removeItem: vi.fn((key) => {
      const existingItem = storage.get(key);
      if (existingItem) {
        const itemSize = new Blob([key + existingItem]).size;
        currentSize -= itemSize;
        storage.delete(key);
      }
    }),

    clear: vi.fn(() => {
      storage.clear();
      currentSize = 0;
    }),

    key: vi.fn((_index) => {
      const keys = Array.from(storage.keys());
      return keys[_index] || null;
    }),

    // Properties
    get length() {
      return storage.size;
    },

    // Mock-specific utilities
    _getMockData: () => Object.fromEntries(storage.entries()),
    _getCurrentSize: () => currentSize,
    _getMaxSize: () => maxStorageSize,
    _simulateQuotaExceeded: (exceeded = true) => {
      // Note: reassigning parameters would cause const issues
      // Instead, we update the behavior directly in setItem
      mockStorage.setItem.mockImplementation((key, value) => {
        if (exceeded || shouldThrowOnSetItem) {
          const error = new Error('QuotaExceededError: The quota has been exceeded.');
          error.name = 'QuotaExceededError';
          throw error;
        }
        storage.set(key, value);
      });
    },
    _reset: () => {
      storage.clear();
      currentSize = 0;
      mockStorage.getItem.mockClear();
      mockStorage.setItem.mockClear();
      mockStorage.removeItem.mockClear();
      mockStorage.clear.mockClear();
      mockStorage.key.mockClear();
    }
  };

  return mockStorage;
}

/**
 * Create a mock IndexedDB object
 * @param {Object} options - Configuration options for the mock
 * @returns {Object} Mock IndexedDB object
 */
export function createMockIndexedDB(options = {}) {
  const {
    shouldFailOnOpen = false,
    databases = new Map(),
    version = 1
  } = options;

  const mockIndexedDB = {
    open: vi.fn((name, version = 1) => {
      if (shouldFailOnOpen) {
        return Promise.reject(new Error('IndexedDB unavailable'));
      }

      const mockRequest = {
        result: null,
        error: null,
        readyState: 'pending',
        onsuccess: null,
        onerror: null,
        onupgradeneeded: null,

        // Simulate successful database opening
        _triggerSuccess: () => {
          const mockDB = createMockIDBDatabase(name, version);
          databases.set(name, mockDB);
          mockRequest.result = mockDB;
          mockRequest.readyState = 'done';
          if (mockRequest.onsuccess) {
            mockRequest.onsuccess({ target: mockRequest });
          }
        },

        // Simulate database upgrade needed
        _triggerUpgradeNeeded: () => {
          if (mockRequest.onupgradeneeded) {
            mockRequest.onupgradeneeded({ target: mockRequest });
          }
        },

        // Simulate error
        _triggerError: (error) => {
          mockRequest.error = error;
          mockRequest.readyState = 'done';
          if (mockRequest.onerror) {
            mockRequest.onerror({ target: mockRequest });
          }
        }
      };

      // Auto-trigger success by default
      setTimeout(() => {
        if (mockRequest.readyState === 'pending') {
          mockRequest._triggerSuccess();
        }
      }, 0);

      return mockRequest;
    }),

    deleteDatabase: vi.fn((name) => {
      const mockRequest = {
        result: undefined,
        error: null,
        readyState: 'pending',
        onsuccess: null,
        onerror: null
      };

      setTimeout(() => {
        databases.delete(name);
        mockRequest.readyState = 'done';
        if (mockRequest.onsuccess) {
          mockRequest.onsuccess({ target: mockRequest });
        }
      }, 0);

      return mockRequest;
    }),

    cmp: vi.fn((a, b) => {
      if (a < b) {return -1;}
      if (a > b) {return 1;}
      return 0;
    }),

    // Mock-specific utilities
    _getDatabases: () => databases,
    _reset: () => {
      databases.clear();
      mockIndexedDB.open.mockClear();
      mockIndexedDB.deleteDatabase.mockClear();
      mockIndexedDB.cmp.mockClear();
    }
  };

  return mockIndexedDB;
}

/**
 * Create a mock IDBDatabase object
 * @param {string} name - Database name
 * @param {number} version - Database version
 * @returns {Object} Mock IDBDatabase object
 */
function createMockIDBDatabase(name, version) {
  const objectStores = new Map();

  return {
    name,
    version,
    objectStoreNames: {
      contains: (name) => objectStores.has(name),
      item: (_index) => Array.from(objectStores.keys())[_index],
      get length() { return objectStores.size; }
    },

    createObjectStore: vi.fn((name, options = {}) => {
      const store = createMockIDBObjectStore(name, options);
      objectStores.set(name, store);
      return store;
    }),

    deleteObjectStore: vi.fn((name) => {
      objectStores.delete(name);
    }),

    transaction: vi.fn((storeNames, mode = 'readonly') => {
      return createMockIDBTransaction(objectStores, storeNames, mode);
    }),

    close: vi.fn(),

    // Events
    onabort: null,
    onclose: null,
    onerror: null,
    onversionchange: null,

    // Mock-specific utilities
    _getObjectStores: () => objectStores
  };
}

/**
 * Create a mock IDBObjectStore object
 * @param {string} name - Store name
 * @param {Object} options - Store options
 * @returns {Object} Mock IDBObjectStore object
 */
function createMockIDBObjectStore(name, options = {}) {
  const data = new Map();
  const { keyPath, autoIncrement = false } = options;

  return {
    name,
    keyPath,
    autoIncrement,
    indexNames: { length: 0 },

    add: vi.fn((value, key) => {
      return createMockIDBRequest(() => {
        if (data.has(key)) {
          throw new Error('ConstraintError: Key already exists');
        }
        data.set(key, value);
        return key;
      });
    }),

    put: vi.fn((value, key) => {
      return createMockIDBRequest(() => {
        data.set(key, value);
        return key;
      });
    }),

    get: vi.fn((key) => {
      return createMockIDBRequest(() => {
        return data.get(key);
      });
    }),

    delete: vi.fn((key) => {
      return createMockIDBRequest(() => {
        data.delete(key);
        return undefined;
      });
    }),

    clear: vi.fn(() => {
      return createMockIDBRequest(() => {
        data.clear();
        return undefined;
      });
    }),

    count: vi.fn(() => {
      return createMockIDBRequest(() => {
        return data.size;
      });
    }),

    openCursor: vi.fn(() => {
      return createMockIDBRequest(() => {
        // Simplified cursor implementation
        const entries = Array.from(data.entries());
        let index = 0;

        return entries.length > 0 ? {
          key: entries[index][0],
          value: entries[index][1],
          continue: () => {
            index++;
            return index < entries.length ? entries[index] : null;
          }
        } : null;
      });
    }),

    createIndex: vi.fn((name, keyPath, options = {}) => {
      return createMockIDBIndex(name, keyPath, options);
    }),

    deleteIndex: vi.fn((name) => {
      // Implementation for index deletion
    }),

    index: vi.fn((name) => {
      return createMockIDBIndex(name, 'mockKeyPath', {});
    }),

    // Mock-specific utilities
    _getData: () => Object.fromEntries(data.entries()),
    _reset: () => {
      data.clear();
    }
  };
}

/**
 * Create a mock IDBTransaction object
 * @param {Map} objectStores - Available object stores
 * @param {string|Array} storeNames - Store names for transaction
 * @param {string} mode - Transaction mode
 * @returns {Object} Mock IDBTransaction object
 */
function createMockIDBTransaction(objectStores, storeNames, mode) {
  const stores = Array.isArray(storeNames) ? storeNames : [storeNames];

  return {
    mode,
    objectStoreNames: stores,

    objectStore: vi.fn((name) => {
      if (objectStores.has(name)) {
        return objectStores.get(name);
      }
      throw new Error(`ObjectStore ${name} not found`);
    }),

    abort: vi.fn(),

    // Events
    onabort: null,
    oncomplete: null,
    onerror: null,

    // Mock completion simulation
    _complete: function() {
      if (this.oncomplete) {
        this.oncomplete({ target: this });
      }
    }
  };
}

/**
 * Create a mock IDBIndex object
 * @param {string} name - Index name
 * @param {string} keyPath - Key path
 * @param {Object} options - Index options
 * @returns {Object} Mock IDBIndex object
 */
function createMockIDBIndex(name, keyPath, _options = {}) {
  return {
    name,
    keyPath,
    unique: _options.unique || false,
    multiEntry: _options.multiEntry || false,

    get: vi.fn((key) => {
      return createMockIDBRequest(() => {
        // Simplified index lookup
        return { id: key, data: 'mock-indexed-data' };
      });
    }),

    getAll: vi.fn(() => {
      return createMockIDBRequest(() => {
        return [{ id: 1, data: 'mock-data-1' }, { id: 2, data: 'mock-data-2' }];
      });
    }),

    openCursor: vi.fn(() => {
      return createMockIDBRequest(() => {
        return null; // Simplified cursor
      });
    })
  };
}

/**
 * Create a mock IDBRequest object
 * @param {Function} operation - Operation to execute
 * @returns {Object} Mock IDBRequest object
 */
function createMockIDBRequest(operation) {
  const request = {
    result: null,
    error: null,
    readyState: 'pending',
    onsuccess: null,
    onerror: null,

    _triggerSuccess: (result) => {
      request.result = result;
      request.readyState = 'done';
      if (request.onsuccess) {
        request.onsuccess({ target: request });
      }
    },

    _triggerError: (error) => {
      request.error = error;
      request.readyState = 'done';
      if (request.onerror) {
        request.onerror({ target: request });
      }
    }
  };

  // Execute operation asynchronously
  setTimeout(() => {
    try {
      const result = operation();
      request._triggerSuccess(result);
    } catch (_error) {
      request._triggerError(_error);
    }
  }, 0);

  return request;
}

/**
 * Create a mock Storage API estimate
 * @param {Object} options - Configuration options
 * @returns {Object} Mock storage estimate
 */
export function createMockStorageEstimate(options = {}) {
  const {
    quota = 10 * 1024 * 1024, // 10MB
    usage = 2 * 1024 * 1024, // 2MB
    usageDetails = {}
  } = options;

  return {
    quota,
    usage,
    usageDetails: {
      indexedDB: usageDetails.indexedDB || usage * 0.6,
      localStorage: usageDetails.localStorage || usage * 0.3,
      caches: usageDetails.caches || usage * 0.1,
      ...usageDetails
    }
  };
}

/**
 * Create a mock navigator.storage object
 * @param {Object} options - Configuration options
 * @returns {Object} Mock navigator.storage object
 */
export function createMockNavigatorStorage(options = {}) {
  const estimate = createMockStorageEstimate(options.estimate);

  return {
    estimate: vi.fn(() => Promise.resolve(estimate)),

    persist: vi.fn(() => Promise.resolve(options.persistent || false)),

    persisted: vi.fn(() => Promise.resolve(options.persistent || false)),

    // Mock-specific utilities
    _updateEstimate: (newEstimate) => {
      Object.assign(estimate, newEstimate);
    },

    _reset: function() {
      this.estimate.mockClear();
      this.persist.mockClear();
      this.persisted.mockClear();
    }
  };
}

/**
 * Mock browser storage APIs globally
 * @param {Object} options - Configuration options for all storage APIs
 */
export function mockBrowserStorageAPIs(options = {}) {
  const localStorage = createMockWebStorage(options.localStorage);
  const sessionStorage = createMockWebStorage(options.sessionStorage);
  const indexedDB = createMockIndexedDB(options.indexedDB);
  const navigatorStorage = createMockNavigatorStorage(options.navigatorStorage);

  // Mock global objects
  Object.defineProperty(window, 'localStorage', {
    value: localStorage,
    writable: true,
    configurable: true
  });

  Object.defineProperty(window, 'sessionStorage', {
    value: sessionStorage,
    writable: true,
    configurable: true
  });

  Object.defineProperty(window, 'indexedDB', {
    value: indexedDB,
    writable: true,
    configurable: true
  });

  Object.defineProperty(navigator, 'storage', {
    value: navigatorStorage,
    writable: true,
    configurable: true
  });

  return {
    localStorage,
    sessionStorage,
    indexedDB,
    navigatorStorage,

    // Utility to reset all mocks
    resetAll: () => {
      localStorage._reset();
      sessionStorage._reset();
      indexedDB._reset();
      navigatorStorage._reset();
    }
  };
}

/**
 * Simulate browser-specific storage behaviors
 */
export const browserStorageBehaviors = {
  // Safari private browsing mode
  safariPrivateBrowsing: {
    localStorage: {
      shouldThrowOnSetItem: true,
      quotaExceeded: true,
      maxStorageSize: 0
    }
  },

  // Chrome incognito mode
  chromeIncognito: {
    localStorage: {
      maxStorageSize: 10 * 1024 * 1024 // 10MB
    },
    sessionStorage: {
      maxStorageSize: 10 * 1024 * 1024
    }
  },

  // Firefox private browsing
  firefoxPrivate: {
    localStorage: {
      maxStorageSize: 10 * 1024 * 1024
    },
    indexedDB: {
      shouldFailOnOpen: true
    }
  },

  // Mobile Safari with limited storage
  mobileSafari: {
    localStorage: {
      maxStorageSize: 5 * 1024 * 1024 // 5MB
    },
    navigatorStorage: {
      estimate: {
        quota: 50 * 1024 * 1024, // 50MB
        usage: 10 * 1024 * 1024 // 10MB
      }
    }
  },

  // Older browser with limited IndexedDB support
  legacyBrowser: {
    indexedDB: {
      shouldFailOnOpen: true
    },
    localStorage: {
      maxStorageSize: 2 * 1024 * 1024 // 2MB
    }
  }
};

// Export default mock configuration
export default {
  createMockWebStorage,
  createMockIndexedDB,
  createMockStorageEstimate,
  createMockNavigatorStorage,
  mockBrowserStorageAPIs,
  browserStorageBehaviors
};
