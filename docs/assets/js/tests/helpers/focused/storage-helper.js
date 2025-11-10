/**
 * Focused Storage Helper
 * Lightweight localStorage mocking without other API dependencies
 *
 * @description Provides targeted localStorage mocking functionality
 * - Mock localStorage with no other API dependencies
 * - Proper restoration and cleanup
 * - Memory efficient implementation
 * - Storage event simulation for realistic testing
 * @version 1.0.0
 */

/**
 * Create a lightweight storage helper with focused functionality
 * @param {Object} options - Configuration options
 * @param {boolean} options.withEvents - Whether to simulate storage events
 * @param {Object} options.initialData - Initial data to populate storage with
 * @returns {Object} Object containing storage mock and cleanup function
 */
export function createStorageHelper(options = {}) {
  const { withEvents = false, initialData = {} } = options;

  // Store original localStorage for restoration
  const originalLocalStorage = globalThis.localStorage;
  const storageData = new Map();

  // Initialize with any provided data
  Object.entries(initialData).forEach(([key, value]) => {
    storageData.set(key, String(value));
  });

  /**
   * Create localStorage mock implementation
   */
  const mockLocalStorage = {
    getItem: (key) => {
      const value = storageData.get(key);
      return value !== undefined ? value : null;
    },

    setItem: (key, value) => {
      const oldValue = storageData.get(key) || null;
      const newValue = String(value);
      storageData.set(key, newValue);

      // Trigger storage event if enabled and window is available
      if (withEvents && globalThis.window && globalThis.window.dispatchEvent) {
        try {
          const event = new globalThis.window.StorageEvent('storage', {
            key,
            newValue,
            oldValue,
            storageArea: mockLocalStorage,
            url: globalThis.window.location?.href || 'http://localhost:3000'
          });
          globalThis.window.dispatchEvent(event);
        } catch {
          // Ignore event dispatch errors in test environment
        }
      }
    },

    removeItem: (key) => {
      const oldValue = storageData.get(key) || null;
      storageData.delete(key);

      // Trigger storage event if enabled and window is available
      if (withEvents && globalThis.window && globalThis.window.dispatchEvent) {
        try {
          const event = new globalThis.window.StorageEvent('storage', {
            key,
            newValue: null,
            oldValue,
            storageArea: mockLocalStorage,
            url: globalThis.window.location?.href || 'http://localhost:3000'
          });
          globalThis.window.dispatchEvent(event);
        } catch {
          // Ignore event dispatch errors in test environment
        }
      }
    },

    clear: () => {
      storageData.clear();

      // Trigger storage event if enabled and window is available
      if (withEvents && globalThis.window && globalThis.window.dispatchEvent) {
        try {
          const event = new globalThis.window.StorageEvent('storage', {
            key: null,
            newValue: null,
            oldValue: null,
            storageArea: mockLocalStorage,
            url: globalThis.window.location?.href || 'http://localhost:3000'
          });
          globalThis.window.dispatchEvent(event);
        } catch {
          // Ignore event dispatch errors in test environment
        }
      }
    },

    get length() {
      return storageData.size;
    },

    key: (_index) => {
      const keys = Array.from(storageData.keys());
      return keys[_index] || null;
    },

    // Test helper methods
    _getData: () => Object.fromEntries(storageData),
    _setData: (data) => {
      storageData.clear();
      Object.entries(data).forEach(([key, value]) => {
        storageData.set(key, String(value));
      });
    }
  };

  // Replace global localStorage
  globalThis.localStorage = mockLocalStorage;

  /**
   * Get current storage state as object
   * @returns {Object} Current storage data
   */
  function getStorageState() {
    return Object.fromEntries(storageData);
  }

  /**
   * Set storage state from object
   * @param {Object} data - Data to set in storage
   */
  function setStorageState(data) {
    storageData.clear();
    Object.entries(data).forEach(([key, value]) => {
      storageData.set(key, String(value));
    });
  }

  /**
   * Clear all storage data
   */
  function clearStorage() {
    storageData.clear();
  }

  /**
   * Check if a key exists in storage
   * @param {string} key - Key to check
   * @returns {boolean} Whether key exists
   */
  function hasKey(key) {
    return storageData.has(key);
  }

  /**
   * Get all storage keys
   * @returns {Array} Array of all keys
   */
  function getKeys() {
    return Array.from(storageData.keys());
  }

  /**
   * Cleanup function that restores original localStorage
   */
  function cleanup() {
    try {
      globalThis.localStorage = originalLocalStorage;
    } catch {
      // Ignore restoration errors
    }
  }

  // Return only essential storage utilities - no bloat
  return {
    localStorage: mockLocalStorage,
    getStorageState,
    setStorageState,
    clearStorage,
    hasKey,
    getKeys,
    cleanup
  };
}

/**
 * Create a basic storage helper without events
 * For tests that need minimal overhead
 * @param {Object} initialData - Initial storage data
 * @returns {Object} Object containing basic storage mock
 */
export function createBasicStorageHelper(initialData = {}) {
  return createStorageHelper({ withEvents: false, initialData });
}

/**
 * Create a storage helper with event simulation
 * For tests that need to respond to storage events
 * @param {Object} initialData - Initial storage data
 * @returns {Object} Object containing storage mock with events
 */
export function createEventfulStorageHelper(initialData = {}) {
  return createStorageHelper({ withEvents: true, initialData });
}

export default createStorageHelper;
