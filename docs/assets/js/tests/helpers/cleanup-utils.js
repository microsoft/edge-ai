/**
 * Test Cleanup Utilities
 * Provides comprehensive cleanup functions to prevent test interference
 *
 * @description Cleans up timers, observers, listeners, and global state
 * @version 1.0.0
 */

/**
 * Clear all timers (simplified version)
 */
function clearAllTimers() {
  // Clear a much larger range of timer IDs to catch any stray timers
  for (let i = 1; i <= 10000; i++) {
    try {
      clearTimeout(i);
      clearInterval(i);
    } catch {
      // Ignore errors
    }
  }
}

/**
 * Simple cleanup function that doesn't hang
 * @param {Object} testCleanup - Test cleanup context
 */
function fullCleanup(testCleanup) {
  try {
    // Clear timers
    clearAllTimers();

    // Reset DOM if available
    if (testCleanup && testCleanup.document && testCleanup.document.body) {
      testCleanup.document.body.innerHTML = '';
    }

    // Clear some globals
    if (typeof window !== 'undefined') {
      if (window.docsify) {delete window.docsify;}
      if (window.Docsify) {delete window.Docsify;}
    }
  } catch (_error) {
    console.warn('Cleanup error:', _error);
  }
}

/**
 * Create a test cleanup context
 * @param {Object} testEnv - Test environment from createFreshDOMEnvironment
 * @returns {Object} Cleanup context
 */
function createTestCleanup(testEnv) {
  const cleanupTasks = [];

  return {
    document: testEnv ? testEnv.document : null,
    window: testEnv ? testEnv.window : null,

    /**
     * Add a cleanup task to be executed during cleanup
     * @param {Function} task - Cleanup task function
     */
    addCleanupTask(task) {
      if (typeof task === 'function') {
        cleanupTasks.push(task);
      }
    },

    /**
     * Execute all cleanup tasks
     */
    cleanup() {
      // Execute cleanup tasks in reverse order
      while (cleanupTasks.length > 0) {
        const task = cleanupTasks.pop();
        try {
          task();
        } catch (_error) {
          console.warn('Cleanup task error:', _error);
        }
      }

      // Basic cleanup
      fullCleanup(this);
    }
  };
}

export { fullCleanup, createTestCleanup, clearAllTimers };
