/**
 * Console Mock Helper for Backend Tests
 *
 * Provides efficient console mocking for test environments to improve performance
 * while preserving essential error and warning testing capabilities.
 *
 * Usage:
 *   import { mockConsole, restoreConsole, getConsoleCalls } from './helpers/console-mock.js';
 *
 *   beforeEach(() => mockConsole());
 *   afterEach(() => restoreConsole());
 */

// Store original console methods
const originalConsole = {
  log: console.log,
  info: console.info,
  debug: console.debug,
  trace: console.trace,
  table: console.table,
  assert: console.assert,
  warn: console.warn,
  error: console.error
};

// Mock storage for test assertions
const consoleCalls = {
  log: [],
  info: [],
  debug: [],
  trace: [],
  table: [],
  assert: [],
  warn: [],
  error: []
};

/**
 * Mock console methods for performance optimization
 * Preserves warn and error for essential testing
 */
export function mockConsole() {
  // Clear previous calls
  Object.keys(consoleCalls).forEach(method => {
    consoleCalls[method] = [];
  });

  // Mock performance-impacting methods with no-ops
  console.log = () => {};
  console.info = () => {};
  console.debug = () => {};
  console.trace = () => {};
  console.table = () => {};
  console.assert = () => {};

  // Mock warn and error with call tracking for testing
  console.warn = (...args) => {
    consoleCalls.warn.push(args);
    // Optionally call original for critical warnings
    // originalConsole.warn(...args);
  };

  console.error = (...args) => {
    consoleCalls.error.push(args);
    // Optionally call original for critical errors
    // originalConsole.error(...args);
  };
}

/**
 * Restore original console methods
 */
export function restoreConsole() {
  Object.assign(console, originalConsole);
}

/**
 * Get captured console calls for test assertions
 * @param {string} method - Console method name (log, warn, error, etc.)
 * @returns {Array} Array of captured calls
 */
export function getConsoleCalls(method) {
  return consoleCalls[method] || [];
}

/**
 * Check if a specific console method was called
 * @param {string} method - Console method name
 * @param {string|RegExp} message - Message to search for (optional)
 * @returns {boolean} True if method was called with message
 */
export function wasConsoleCalled(method, message = null) {
  const calls = consoleCalls[method] || [];

  if (!message) {
    return calls.length > 0;
  }

  return calls.some(args => {
    const firstArg = args[0];
    if (typeof firstArg !== 'string') {return false;}

    if (message instanceof RegExp) {
      return message.test(firstArg);
    }

    return firstArg.includes(message);
  });
}

/**
 * Clear all captured console calls
 */
export function clearConsoleCalls() {
  Object.keys(consoleCalls).forEach(method => {
    consoleCalls[method] = [];
  });
}

/**
 * Create a console mock for specific methods only
 * @param {Array<string>} methods - Console methods to mock
 */
export function mockConsoleMethods(methods) {
  methods.forEach(method => {
    if (originalConsole[method]) {
      console[method] = (...args) => {
        consoleCalls[method].push(args);
      };
    }
  });
}

/**
 * Silence all console output for performance-critical tests
 */
export function silenceConsole() {
  Object.keys(originalConsole).forEach(method => {
    console[method] = () => {};
  });
}
