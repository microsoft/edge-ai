/**
 * Error Handling System
 * Focused error tracking and debugging capabilities without performance monitoring
 * @module core/error-handler
 * @version 3.0.0
 * @since 1.0.0
 * @author Edge AI Team
 */

/**
 * Error Handling System
 * Provides focused error tracking and debugging capabilities
 * @class ErrorHandler
 */
export class ErrorHandler {
  constructor(componentName = 'system') {
    this.errors = [];
    this.initialized = false;
    this.componentName = componentName;
  }

  /**
   * Get test environment info - safe access to globals for testing
   * @returns {Object} Test environment information
   */
  getTestEnvironmentInfo() {
    const safeWindow = (typeof window !== 'undefined') ? window : {};
    const safeNavigator = (typeof navigator !== 'undefined') ? navigator : {};
    const safeDocument = (typeof document !== 'undefined') ? document : {};

    // Use the test environment's location if available, with proper fallback
    const location = safeWindow.location ? {
      href: safeWindow.location.href || 'test://localhost',
      ...safeWindow.location
    } : { href: 'test://localhost' };

    return {
      window: safeWindow,
      navigator: safeNavigator,
      document: safeDocument,
      location: location,
      userAgent: safeNavigator.userAgent || 'test-environment'
    };
  }

  /**
   * Initialize error handling system
   */
  init() {
    if (this.initialized) {return;}

    this.setupGlobalErrorHandling();
    this.initialized = true;

    this.log('Error handling system initialized');
  }

  /**
   * Setup global error handling for plugin
   */
  setupGlobalErrorHandling() {
    const env = this.getTestEnvironmentInfo();
    const PLUGIN_CONFIG = env.window.KataProgressConfig || { name: this.componentName, errorTracking: true };

    if (!PLUGIN_CONFIG.errorTracking) {return;}

    // Capture unhandled plugin errors
    const originalConsoleError = window.console.error;
    window.console.error = (...args) => {
      // Check if this is a plugin-related error
      const errorMessage = args.join(' ');
      if (errorMessage.includes(PLUGIN_CONFIG.name) ||
          errorMessage.includes('kata-progress') ||
          errorMessage.includes(this.componentName)) {
        this.recordError('console.error', new Error(errorMessage), { args });
      }
      originalConsoleError.apply(console, args);
    };
  }

  /**
   * Record an error with context
   * @param {string} operation - Operation that failed
   * @param {Error} error - Error object
   * @param {Object} context - Additional context
   */
  recordError(operation, error, context = {}) {
    const env = this.getTestEnvironmentInfo();
    const errorRecord = {
      timestamp: Date.now(),
      operation,
      message: error && error.message ? error.message : 'Unknown error',
      stack: error && error.stack ? error.stack : 'No stack trace available',
      context,
      url: env.location.href,
      userAgent: env.userAgent
    };

    this.errors.push(errorRecord);

    // Keep only last 50 errors to prevent memory bloat
    if (this.errors.length > 50) {
      this.errors = this.errors.slice(-50);
    }

    this.log('Error recorded:', errorRecord);
  }

  /**
   * Handle error with component-friendly interface (delegates to recordError)
   * @param {Error} error - The error object
   * @param {string} operation - The operation context
   * @param {Object} context - Additional context (optional)
   */
  handleError(error, operation, context = {}) {
    this.recordError(operation, error, context);
  }

  /**
   * Safely execute a function with error handling
   * @param {Function} fn - Function to execute
   * @param {string} operation - Operation name for error tracking
   * @param {*} defaultValue - Default value to return on error
   * @returns {*} Function result or default value
   */
  safeExecute(fn, operation, defaultValue = null) {
    try {
      return fn();
    } catch (error) {
      this.recordError(operation, error);
      return defaultValue;
    }
  }

  /**
   * Validate DOM element exists
   * @param {string} selector - CSS selector
   * @param {string} context - Context for error reporting
   * @returns {HTMLElement|null} Element or null
   */
  validateElement(selector, context) {
    const env = this.getTestEnvironmentInfo();
    const element = env.document.querySelector ? env.document.querySelector(selector) : null;
    if (!element) {
      this.recordError('validateElement', new Error(`Element not found: ${selector}`), { selector, context });
    }
    return element;
  }

  /**
   * Get error summary for debugging
   * @returns {Object} Error summary
   */
  getErrorSummary() {
    const errorsByOperation = {};
    this.errors.forEach(error => {
      if (!errorsByOperation[error.operation]) {
        errorsByOperation[error.operation] = [];
      }
      errorsByOperation[error.operation].push(error);
    });

    return {
      totalErrors: this.errors.length,
      errorsByOperation,
      recentErrors: this.errors.slice(-10)
    };
  }

  /**
   * Debug logging
   * @param {string} message - Debug message
   * @param {...any} args - Additional arguments
   */
  log(message, ...args) {
    const env = this.getTestEnvironmentInfo();
    const PLUGIN_CONFIG = env.window.KataProgressConfig || { debugMode: false };

    if (PLUGIN_CONFIG.debugMode) {
      // Use eslint-disable for legitimate debug logging
      // eslint-disable-next-line no-console
      console.log(`[interactive-progress] ${message}`, ...args);
    }
  }

  /**
   * Warning logging
   * @param {string} message - Warning message
   * @param {...any} args - Additional arguments
   */
  logWarning(_message, ..._args) {
    const _env = this.getTestEnvironmentInfo();
    // Warning logging removed for production
  }

  /**
   * Error logging
   * @param {string} message - Error message
   * @param {...any} args - Additional arguments
   */
  logError(_message, ..._args) {
    const _env = this.getTestEnvironmentInfo();
    // Verbose logging disabled for tests
  }

  /**
   * Info logging
   * @param {string} message - Info message
   * @param {...any} args - Additional arguments
   */
  logInfo(_message, ..._args) {
    const _env = this.getTestEnvironmentInfo();
    // Info logging disabled for production
  }

  /**
   * Check system health and compatibility
   * @returns {Object} Health check results
   */
  checkSystemHealth() {
    const env = this.getTestEnvironmentInfo();
    const results = {
      domReady: env.document.readyState === 'complete' || env.document.readyState === 'interactive',
      docsifyPresent: !!env.window.$docsify,
      contentContainer: !!this.validateElement('.content', 'health check'),
      errorCount: this.errors.length,
      healthy: true
    };

    // Determine overall health
    results.healthy = results.domReady && results.docsifyPresent && results.contentContainer && results.errorCount < 10;

    this.log('System health check:', results);
    return results;
  }
}

// Export default instance for convenience
export const defaultErrorHandler = new ErrorHandler('system');

// Export alias for backward compatibility
export const errorHandler = defaultErrorHandler;

// Export convenience functions for backward compatibility
export const safeExecute = (...args) => defaultErrorHandler.safeExecute(...args);
export const recordError = (...args) => defaultErrorHandler.recordError(...args);
export const getHealthStatus = (...args) => defaultErrorHandler.checkSystemHealth(...args);
