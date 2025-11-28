/**
 * Browser API Mocks for Testing
 * Provides comprehensive browser API simulation for test environment
 *
 * @description Enhanced browser API mocks to support Happy DOM test environment
 * @version 1.0.0
 */

/**
 * Enhanced localStorage mock that behaves like real localStorage
 * @returns {Object} localStorage-compatible object
 */
export function createEnhancedLocalStorage() {
  const storage = new Map();

  return {
    getItem: (key) => {
      const value = storage.get(key);
      return value !== undefined ? value : null;
    },
    setItem: (key, value) => {
      storage.set(key, String(value));
      // Trigger storage event for better simulation
      if (global.window && global.window.dispatchEvent) {
        const event = new global.window.StorageEvent('storage', {
          key,
          newValue: String(value),
          oldValue: storage.get(key) || null,
          storageArea: this,
          url: global.window.location?.href || 'http://localhost:3000'
        });
        global.window.dispatchEvent(event);
      }
    },
    removeItem: (key) => {
      const oldValue = storage.get(key) || null;
      storage.delete(key);
      // Trigger storage event
      if (global.window && global.window.dispatchEvent) {
        const event = new global.window.StorageEvent('storage', {
          key,
          newValue: null,
          oldValue,
          storageArea: this,
          url: global.window.location?.href || 'http://localhost:3000'
        });
        global.window.dispatchEvent(event);
      }
    },
    clear: () => {
      storage.clear();
      // Trigger storage event
      if (global.window && global.window.dispatchEvent) {
        const event = new global.window.StorageEvent('storage', {
          key: null,
          newValue: null,
          oldValue: null,
          storageArea: this,
          url: global.window.location?.href || 'http://localhost:3000'
        });
        global.window.dispatchEvent(event);
      }
    },
    get length() {
      return storage.size;
    },
    key: (_index) => {
      const keys = Array.from(storage.keys());
      return keys[_index] || null;
    }
  };
}

/**
 * Enhanced navigation mock for window.location
 * @param {string} [url='http://localhost:3000'] - Initial URL
 * @returns {Object} location-compatible object
 */
export function createEnhancedLocation(url = 'http://localhost:3000') {
  const urlObj = new URL(url);

  const location = {
    href: urlObj.href,
    protocol: urlObj.protocol,
    host: urlObj.host,
    hostname: urlObj.hostname,
    port: urlObj.port,
    pathname: urlObj.pathname,
    search: urlObj.search,
    hash: urlObj.hash,
    origin: urlObj.origin,

    assign: (newUrl) => {
      const newUrlObj = new URL(newUrl, urlObj);
      Object.assign(location, {
        href: newUrlObj.href,
        protocol: newUrlObj.protocol,
        host: newUrlObj.host,
        hostname: newUrlObj.hostname,
        port: newUrlObj.port,
        pathname: newUrlObj.pathname,
        search: newUrlObj.search,
        hash: newUrlObj.hash,
        origin: newUrlObj.origin
      });
      // Trigger navigation event
      if (global.window && global.window.dispatchEvent) {
        const event = new global.window.Event('popstate');
        global.window.dispatchEvent(event);
      }
    },

    replace: (newUrl) => {
      location.assign(newUrl); // Same behavior for testing
    },

    reload: () => {
      // Mock reload - no-op in tests
      if (global.window && global.window.dispatchEvent) {
        const event = new global.window.Event('beforeunload');
        global.window.dispatchEvent(event);
      }
    },

    toString: () => location.href
  };

  return location;
}

/**
 * Create AbortController polyfill for Happy DOM compatibility
 * @returns {Object} AbortController-compatible object
 */
export function createAbortControllerPolyfill() {
  class MockAbortSignal extends EventTarget {
    constructor() {
      super();
      this.aborted = false;
      this.reason = undefined;
    }

    throwIfAborted() {
      if (this.aborted) {
        throw new DOMException('The operation was aborted', 'AbortError');
      }
    }
  }

  class MockAbortController {
    constructor() {
      this.signal = new MockAbortSignal();
    }

    abort(reason) {
      if (this.signal.aborted) {return;}

      this.signal.aborted = true;
      this.signal.reason = reason;

      const event = new Event('abort');
      this.signal.dispatchEvent(event);
    }
  }

  return {
    AbortController: MockAbortController,
    AbortSignal: MockAbortSignal
  };
}

/**
 * Enhanced addEventListener wrapper that handles AbortController signals
 * @param {EventTarget} target - Event target
 * @param {string} type - Event type
 * @param {Function} listener - Event listener
 * @param {Object} [options={}] - Event options
 * @returns {Function} removeEventListener function
 */
export function addEventListenerWithSignal(target, type, listener, options = {}) {
  if (!target || typeof target.addEventListener !== 'function') {
    throw new Error('Invalid event target');
  }

  // Handle signal option
  if (options.signal) {
    // Check if signal is already aborted
    if (options.signal.aborted) {
      return () => {}; // No-op cleanup function
    }

    // Create abort handler
    const abortHandler = () => {
      target.removeEventListener(type, listener, options);
    };

    // Listen for abort signal
    options.signal.addEventListener('abort', abortHandler, { once: true });

    // Modify options to remove signal (Happy DOM doesn't support it)
    const testOptions = { ...options };
    delete testOptions.signal;

    // Add event listener with modified options
    target.addEventListener(type, listener, testOptions);

    // Return cleanup function
    return () => {
      target.removeEventListener(type, listener, testOptions);
      if (options.signal && !options.signal.aborted) {
        options.signal.removeEventListener('abort', abortHandler);
      }
    };
  }

  // Normal addEventListener without signal
  target.addEventListener(type, listener, options);
  return () => target.removeEventListener(type, listener, options);
}

/**
 * Setup enhanced browser APIs in global scope
 * @returns {void}
 */
export function setupEnhancedBrowserAPIs() {
  // Enhance AbortController support
  const { AbortController, AbortSignal } = createAbortControllerPolyfill();

  if (!global.AbortController) {
    global.AbortController = AbortController;
  }
  if (!global.AbortSignal) {
    global.AbortSignal = AbortSignal;
  }

  // Enhance window objects if available
  if (global.window) {
    if (!global.window.AbortController) {
      global.window.AbortController = AbortController;
    }
    if (!global.window.AbortSignal) {
      global.window.AbortSignal = AbortSignal;
    }

    // Enhanced localStorage
    if (!global.window.localStorage || typeof global.window.localStorage.getItem !== 'function') {
      global.window.localStorage = createEnhancedLocalStorage();
      global.localStorage = global.window.localStorage;
    }

    // Enhanced sessionStorage
    if (!global.window.sessionStorage || typeof global.window.sessionStorage.getItem !== 'function') {
      global.window.sessionStorage = createEnhancedLocalStorage();
      global.sessionStorage = global.window.sessionStorage;
    }

    // Enhanced location
    if (!global.window.location || typeof global.window.location.assign !== 'function') {
      global.window.location = createEnhancedLocation();
      global.location = global.window.location;
    }
  }

  // Enhanced browser APIs setup complete
}

/**
 * Cleanup enhanced browser APIs
 * @returns {void}
 */
export function cleanupEnhancedBrowserAPIs() {
  // Clean up storage
  if (global.localStorage && typeof global.localStorage.clear === 'function') {
    global.localStorage.clear();
  }
  if (global.sessionStorage && typeof global.sessionStorage.clear === 'function') {
    global.sessionStorage.clear();
  }

  // Enhanced browser APIs cleanup complete
}
