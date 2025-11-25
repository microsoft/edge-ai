/**
 * @fileoverview Debug Helper Utilities
 * Environment-aware logging and debug utilities
 * @version 1.0.0
 * @module utils/debug-helper
 */

/**
 * Debug Helper Class
 * Provides environment-aware logging and debug functionality
 */
export class DebugHelper {
  constructor(options = {}) {
    this.debugMode = options.debugMode || this.isDebugMode();
    this.prefix = options.prefix || '[DEBUG]';
    this.logLevel = options.logLevel || 'info';
  }

  /**
   * Check if debug mode is enabled
   * @returns {boolean} True if debug mode is enabled
   */
  isDebugMode() {
    return (
      typeof window !== 'undefined' &&
      (window.location.search.includes('debug=true') ||
       window.localStorage.getItem('debug') === 'true' ||
       window.location.hostname === 'localhost' ||
       window.location.hostname === '127.0.0.1')
    );
  }

  /**
   * Log debug message
   * @param {...any} args - Arguments to log
   */
  debug(...args) {
    if (this.debugMode && this.shouldLog('debug')) {
      console.debug(this.prefix, ...args);
    }
  }

  /**
   * Log info message
   * @param {...any} args - Arguments to log
   */
  info(...args) {
    if (this.shouldLog('info')) {
      console.info(this.prefix, ...args);
    }
  }

  /**
   * Log warning message
   * @param {...any} args - Arguments to log
   */
  warn(...args) {
    if (this.shouldLog('warn')) {
      console.warn(this.prefix, ...args);
    }
  }

  /**
   * Log error message
   * @param {...any} args - Arguments to log
   */
  error(...args) {
    if (this.shouldLog('error')) {
      console.error(this.prefix, ...args);
    }
  }

  /**
   * Log message (alias for info)
   * @param {...any} args - Arguments to log
   */
  log(...args) {
    this.info(...args);
  }

  /**
   * Check if message should be logged based on log level
   * @param {string} level - Log level to check
   * @returns {boolean} True if should log
   */
  shouldLog(level) {
    const levels = ['error', 'warn', 'info', 'debug'];
    const currentLevelIndex = levels.indexOf(this.logLevel);
    const messageLevelIndex = levels.indexOf(level);
    return messageLevelIndex <= currentLevelIndex;
  }

  /**
   * Create a scoped debug helper with a specific prefix
   * @param {string} scope - Scope prefix
   * @returns {DebugHelper} New scoped debug helper
   */
  scope(scope) {
    return new DebugHelper({
      debugMode: this.debugMode,
      prefix: `${this.prefix}[${scope}]`,
      logLevel: this.logLevel
    });
  }
}

/**
 * Default debug helper instance
 */
export const defaultDebugHelper = new DebugHelper({
  prefix: '[APP]',
  logLevel: 'info'
});

/**
 * Export convenience methods from default instance
 */
export const debug = (...args) => defaultDebugHelper.debug(...args);
export const info = (...args) => defaultDebugHelper.info(...args);
export const warn = (...args) => defaultDebugHelper.warn(...args);
export const error = (...args) => defaultDebugHelper.error(...args);
export const log = (...args) => defaultDebugHelper.log(...args);

/**
 * Create a scoped debug helper
 * @param {string} scope - Scope name
 * @returns {DebugHelper} Scoped debug helper
 */
export const createScopedDebugger = (scope) => defaultDebugHelper.scope(scope);
