/**
 * Console Mock Helper for Frontend Tests
 *
 * Provides efficient console mocking for frontend test environments using Vitest
 * to improve performance while preserving essential error and warning testing.
 *
 * Usage:
 *   import { mockConsole, restoreConsole, expectConsoleCall } from './console-mock.js';
 *
 *   beforeEach(() => mockConsole());
 *   afterEach(() => restoreConsole());
 */

import { vi } from 'vitest';

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

// Vitest mock storage for test assertions
let consoleMocks = {};

/**
 * Mock console methods using Vitest spies for performance optimization
 * Preserves warn and error for essential testing with call tracking
 */
export function mockConsole() {
  // Create Vitest spies for performance-impacting methods (no-op implementation)
  consoleMocks.log = vi.spyOn(console, 'log').mockImplementation(() => {});
  consoleMocks.info = vi.spyOn(console, 'info').mockImplementation(() => {});
  consoleMocks.debug = vi.spyOn(console, 'debug').mockImplementation(() => {});
  consoleMocks.trace = vi.spyOn(console, 'trace').mockImplementation(() => {});
  consoleMocks.table = vi.spyOn(console, 'table').mockImplementation(() => {});
  consoleMocks.assert = vi.spyOn(console, 'assert').mockImplementation(() => {});

  // Create spies for warn and error with call tracking (for test assertions)
  consoleMocks.warn = vi.spyOn(console, 'warn').mockImplementation(() => {});
  consoleMocks.error = vi.spyOn(console, 'error').mockImplementation(() => {});
}

/**
 * Restore original console methods and clear mocks
 */
export function restoreConsole() {
  Object.values(consoleMocks).forEach(mock => {
    if (mock && typeof mock.mockRestore === 'function') {
      mock.mockRestore();
    }
  });
  consoleMocks = {};

  // Ensure original methods are restored
  Object.assign(console, originalConsole);
}

/**
 * Get the Vitest spy for a console method
 * @param {string} method - Console method name (log, warn, error, etc.)
 * @returns {import('vitest').MockInstance} Vitest spy instance
 */
export function getConsoleSpy(method) {
  return consoleMocks[method];
}

/**
 * Check if a console method was called (using Vitest assertions)
 * @param {string} method - Console method name
 * @param {number} times - Expected number of calls (optional)
 * @returns {import('vitest').MockInstance} Spy for further assertions
 */
export function expectConsoleCall(method, times = undefined) {
  const spy = consoleMocks[method];
  if (!spy) {
    throw new Error(`Console method '${method}' is not mocked. Call mockConsole() first.`);
  }

  if (times !== undefined) {
    expect(spy).toHaveBeenCalledTimes(times);
  } else {
    expect(spy).toHaveBeenCalled();
  }

  return spy;
}

/**
 * Check if console method was called with specific message
 * @param {string} method - Console method name
 * @param {string|RegExp} message - Expected message or pattern
 * @returns {import('vitest').MockInstance} Spy for further assertions
 */
export function expectConsoleCallWith(method, message) {
  const spy = consoleMocks[method];
  if (!spy) {
    throw new Error(`Console method '${method}' is not mocked. Call mockConsole() first.`);
  }

  if (message instanceof RegExp) {
    expect(spy).toHaveBeenCalledWith(expect.stringMatching(message));
  } else {
    expect(spy).toHaveBeenCalledWith(expect.stringContaining(message));
  }

  return spy;
}

/**
 * Check that console method was NOT called
 * @param {string} method - Console method name
 * @returns {import('vitest').MockInstance} Spy for further assertions
 */
export function expectConsoleNotCalled(method) {
  const spy = consoleMocks[method];
  if (!spy) {
    throw new Error(`Console method '${method}' is not mocked. Call mockConsole() first.`);
  }

  expect(spy).not.toHaveBeenCalled();
  return spy;
}

/**
 * Clear all console mock call history
 */
export function clearConsoleMocks() {
  Object.values(consoleMocks).forEach(mock => {
    if (mock && typeof mock.mockClear === 'function') {
      mock.mockClear();
    }
  });
}

/**
 * Create performance-optimized console mocks for specific methods only
 * @param {Array<string>} methods - Console methods to mock
 */
export function mockConsoleMethods(methods) {
  methods.forEach(method => {
    if (originalConsole[method] && !consoleMocks[method]) {
      consoleMocks[method] = vi.spyOn(console, method).mockImplementation(() => {});
    }
  });
}

/**
 * Silence all console output for performance-critical tests
 * This completely disables console output without tracking calls
 */
export function silenceConsole() {
  Object.keys(originalConsole).forEach(method => {
    if (!consoleMocks[method]) {
      consoleMocks[method] = vi.spyOn(console, method).mockImplementation(() => {});
    }
  });
}

/**
 * Allow specific console methods to pass through (for debugging tests)
 * @param {Array<string>} methods - Console methods to allow
 */
export function allowConsoleMethods(methods) {
  methods.forEach(method => {
    if (consoleMocks[method]) {
      consoleMocks[method].mockRestore();
      delete consoleMocks[method];
    }
  });
}
