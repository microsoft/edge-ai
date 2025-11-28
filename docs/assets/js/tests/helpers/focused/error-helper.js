/**
 * Error Handler Stubs for Testing
 * Provides minimal error handler stubs for testing without full error tracking overhead
 * @module tests/helpers/focused/error-helper
 */

/**
 * Create a minimal error handler stub for testing
 * Provides basic safeExecute functionality without tracking/recording overhead
 * @param {Object} options - Configuration options
 * @param {boolean} options.shouldThrow - If true, safeExecute will re-throw errors instead of catching them
 * @param {*} options.defaultReturn - Default value to return from safeExecute on error
 * @returns {Object} Minimal error handler stub
 */
export function createErrorHandler(options = {}) {
  const {
    shouldThrow = false,
    defaultReturn = null
  } = options;

  return {
    /**
     * Minimal safeExecute implementation for testing
     * @param {Function} fn - Function to execute safely
     * @param {string} operation - Operation name (for compatibility)
     * @param {*} fallback - Fallback value on error
     * @returns {*} Function result or fallback
     */
    async safeExecute(fn, operation, fallback = defaultReturn) {
      try {
        const result = fn();
        // If the result is a Promise, await it
        if (result && typeof result.then === 'function') {
          return await result;
        }
        return result;
      } catch (_error) {
        if (shouldThrow) {
          throw _error;
        }
        return fallback;
      }
    },

    /**
     * Stub methods for compatibility with full error handler interface
     */
    recordError() {
      // No-op for testing
    },

    init() {
      // No-op for testing
    },

    log() {
      // No-op for testing
    },

    logWarning() {
      // No-op for testing
    },

    logError() {
      // No-op for testing
    },

    checkSystemHealth() {
      return { healthy: true };
    }
  };
}

/**
 * Create a spy-enabled error handler for testing
 * All methods are spies that can be used for verification in tests
 * @param {Object} mockUtils - Mock utilities from Vitest (vi object)
 * @param {Object} options - Configuration options (same as createErrorHandler)
 * @returns {Object} Error handler with spy methods
 */
export function createSpyErrorHandler(mockUtils, options = {}) {
  const handler = createErrorHandler(options);

  return {
    safeExecute: mockUtils.spyOn(handler, 'safeExecute'),
    recordError: mockUtils.fn(),
    init: mockUtils.fn(),
    log: mockUtils.fn(),
    logWarning: mockUtils.fn(),
    logError: mockUtils.fn(),
    checkSystemHealth: mockUtils.spyOn(handler, 'checkSystemHealth')
  };
}

/**
 * Clean up any error handler resources
 * Currently a no-op but provides consistent API
 */
export function cleanup() {
  // No cleanup needed for minimal stubs
}
