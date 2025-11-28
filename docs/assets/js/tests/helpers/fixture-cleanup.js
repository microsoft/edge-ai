/**
 * Fixture Cleanup Helper
 * Dedicated utility for comprehensive test fixture cleanup and state management
 *
 * @description Provides enhanced cleanup mechanisms to prevent test interference
 * @version 1.0.0
 */

/**
 * Comprehensive fixture cleanup utility
 */
export class FixtureCleanup {
  constructor() {
    this.cleanupQueue = [];
    this.originalStates = new Map();
  }

  /**
   * Register cleanup function to be called during cleanup
   */
  registerCleanup(cleanupFn, description = 'cleanup function') {
    this.cleanupQueue.push({ fn: cleanupFn, description });
  }

  /**
   * Store original state for restoration
   */
  storeOriginalState(key, value) {
    if (!this.originalStates.has(key)) {
      this.originalStates.set(key, value);
    }
  }

  /**
   * Restore original state
   */
  restoreOriginalState(key) {
    if (this.originalStates.has(key)) {
      return this.originalStates.get(key);
    }
    return undefined;
  }

  /**
   * Clean DOM elements created during tests
   */
  cleanupDOM() {
    // Remove test-specific elements
    const testElements = document.querySelectorAll([
      '[data-test]',
      '[id*="test"]',
      '[class*="test"]',
      '.test-container',
      '.progress-tracker',
      '.learning-path',
      '#toc-container',
      '.page_toc',
      '.modal',
      '.tooltip',
      '.popup'
    ].join(', '));

    testElements.forEach(element => {
      try {
        element.remove();
      } catch {
        // Ignore removal errors
      }
    });

    // Remove test styles
    const testStyles = document.head.querySelectorAll([
      'style[id*="test"]',
      'style[data-test]',
      'style[class*="test"]'
    ].join(', '));

    testStyles.forEach(style => {
      try {
        style.remove();
      } catch (_e) {
        // Ignore removal errors
      }
    });

    // Reset body state
    if (document.body) {
      // Clear classes but preserve essential ones
      const preservedClasses = ['happy-dom-body']; // Classes that happy-dom might need
      const currentClasses = Array.from(document.body.classList);
      const classesToRemove = currentClasses.filter(cls =>
        !preservedClasses.includes(cls)
      );

      classesToRemove.forEach(cls => document.body.classList.remove(cls));

      // Reset styles
      document.body.style.cssText = '';

      // Clear custom attributes
      const customAttrs = Array.from(document.body.attributes).filter(attr =>
        attr.name.includes('test') || attr.name.includes('data-')
      );
      customAttrs.forEach(attr => document.body.removeAttribute(attr.name));
    }

    // Reset document title
    document.title = '';
  }

  /**
   * Clean window/global state
   */
  cleanupGlobalState() {
    // Clear test-related global variables
    const testGlobals = Object.keys(globalThis).filter(key =>
      key.includes('test') ||
      key.includes('Test') ||
      key.includes('mock') ||
      key.includes('Mock') ||
      key === '$docsify' ||
      key === 'axe'
    );

    testGlobals.forEach(key => {
      delete globalThis[key];
    });

    // Reset window properties if available
    if (typeof window !== 'undefined') {
      // Reset scroll position
      window.scrollX = 0;
      window.scrollY = 0;
      window.pageXOffset = 0;
      window.pageYOffset = 0;

      // Clear location hash
      if (window.location && window.location.hash) {
        try {
          window.location.hash = '';
        } catch (_e) {
          // Ignore errors in test environment
        }
      }

      // Clear any focus
      if (document.activeElement && document.activeElement.blur) {
        try {
          document.activeElement.blur();
        } catch (_e) {
          // Ignore blur errors
        }
      }
    }
  }

  /**
   * Clean storage state
   */
  cleanupStorage() {
    // Clear localStorage if available
    if (typeof localStorage !== 'undefined' && localStorage.clear) {
      try {
        localStorage.clear();
      } catch (_e) {
        // Ignore storage errors
      }
    }

    // Clear sessionStorage if available
    if (typeof sessionStorage !== 'undefined' && sessionStorage.clear) {
      try {
        sessionStorage.clear();
      } catch (_e) {
        // Ignore storage errors
      }
    }

    // Clear IndexedDB databases (if any test databases were created)
    if (typeof indexedDB !== 'undefined') {
      // Note: In real implementation, would enumerate and delete test databases
      // For now, just ensure the interface is available
    }
  }

  /**
   * Run all registered cleanup functions
   */
  runCleanupQueue() {
    const errors = [];

    this.cleanupQueue.forEach(({ fn, description }) => {
      try {
        fn();
      } catch (_error) {
        errors.push({ description, error: _error });
      }
    });

    // Clear the queue
    this.cleanupQueue = [];

    return errors;
  }

  /**
   * Comprehensive cleanup of all test state
   */
  cleanup() {
    const issues = [];

    try {
      // Run custom cleanup functions first
      const cleanupErrors = this.runCleanupQueue();
      if (cleanupErrors.length > 0) {
        issues.push(`Cleanup queue errors: ${cleanupErrors.length}`);
      }

      // Clean DOM
      this.cleanupDOM();

      // Clean global state
      this.cleanupGlobalState();

      // Clean storage
      this.cleanupStorage();

    } catch (_error) {
      issues.push(`General cleanup error: ${_error.message}`);
    }

    return issues;
  }

  /**
   * Verify clean state after cleanup
   */
  verifyCleanState() {
    const issues = [];

    try {
      // Check for remaining test elements - with validation
      if (typeof document !== 'undefined' && document.querySelectorAll && typeof document.head !== 'undefined') {
        const remainingElements = document.querySelectorAll([
          '[data-test]',
          '[id*="test"]',
          '[class*="test"]',
          '.test-container'
        ].join(', '));

        if (remainingElements.length > 0) {
          issues.push(`Found ${remainingElements.length} remaining test elements`);
        }

        // Check for remaining test styles - with validation
        if (document.head && document.head.querySelectorAll) {
          const remainingStyles = document.head.querySelectorAll([
            'style[id*="test"]',
            'style[data-test]'
          ].join(', '));

          if (remainingStyles.length > 0) {
            issues.push(`Found ${remainingStyles.length} remaining test styles`);
          }
        }
      }

      // Check for test globals
      const testGlobals = Object.keys(globalThis).filter(key =>
        key.includes('test') || key.includes('Test') || key.includes('mock') || key.includes('Mock')
      );

      if (testGlobals.length > 0) {
        issues.push(`Found ${testGlobals.length} remaining global test variables: ${testGlobals.join(', ')}`);
      }

    } catch (_error) {
      issues.push(`State verification failed: ${_error.message}`);
    }

    return issues;
  }

  /**
   * Full cleanup with verification
   */
  cleanupWithVerification() {
    const cleanupIssues = this.cleanup();
    const verificationIssues = this.verifyCleanState();

    return [...cleanupIssues, ...verificationIssues];
  }

  /**
   * Reset cleanup state
   */
  reset() {
    this.cleanupQueue = [];
    this.originalStates.clear();
  }
}

// Global cleanup instance
export const fixtureCleanup = new FixtureCleanup();

// Convenience functions
export const registerCleanup = (fn, description) => fixtureCleanup.registerCleanup(fn, description);
export const cleanupFixtures = () => fixtureCleanup.cleanup();
export const cleanupWithVerification = () => fixtureCleanup.cleanupWithVerification();
export const verifyCleanState = () => fixtureCleanup.verifyCleanState();

// Auto-cleanup setup for vitest
export const setupAutoCleanup = () => {
  // This will be called from vitest setup files
  if (typeof beforeEach !== 'undefined' && typeof afterEach !== 'undefined') {
    afterEach(() => {
      const issues = fixtureCleanup.cleanupWithVerification();
      if (issues.length > 0) {
        console.warn('Fixture cleanup issues:', issues);
      }
    });
  }
};

export default fixtureCleanup;
