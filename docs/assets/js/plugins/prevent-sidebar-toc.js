/**
 * Prevent App Sub-Sidebar Plugin
 *
 * Surgically prevents Docsify from adding app-sub-sidebar elements to the left sidebar
 * while preserving the right-side TOC functionality.
 *
 * @version 3.0.0
 * @since 1.0.0
 */
(function() {
  'use strict';

  /**
   * Plugin state management
   * @private
   */
  const state = {
    isInitialized: false,
    originalSubSidebar: null
  };

  /**
   * Logger utility for consistent error reporting only
   * @private
   */
  const logger = {
    /**
     * Log error message
     * @param {string} message - The error message
     * @param {Error} [_error] - The error object
     */
    error(message, _error) {
      if (_error) {
        // Silent error handling for production
      } else {
        // Silent error handling for production
      }
    }
  };

  /**
   * Check if we're currently in a context where left sidebar TOC should be prevented
   * @private
   * @returns {boolean} True if left sidebar TOC should be prevented
   */
  function shouldPreventLeftSidebarTOC() {
    try {
      // Check if there's an active element in the left sidebar navigation
      const activeEl = document.querySelector('.sidebar-nav .active');
      return activeEl !== null;
    } catch (_error) {
      logger.error('Error checking sidebar context', _error);
      return false;
    }
  }

  /**
   * Clean up any existing app-sub-sidebar elements from left sidebar
   * @private
   */
  function cleanupExistingElements() {
    try {
      const leftSidebarElements = document.querySelectorAll('.sidebar-nav .app-sub-sidebar');
      if (leftSidebarElements.length > 0) {
        leftSidebarElements.forEach((element) => {
          element.remove();
        });
      }
    } catch (_error) {
      logger.error('Error during cleanup of existing elements', _error);
    }
  }

  /**
   * Initialize the plugin manually (for testing)
   * @private
   */
  function initializeManually() {
    if (window.Docsify && window.Docsify.compiler && !state.isInitialized) {
      const originalSubSidebar = window.Docsify.compiler.subSidebar;

      if (originalSubSidebar) {
        // Override with our custom implementation
        window.Docsify.compiler.subSidebar = function(level) {
          // If called without level (cleanup call), proceed normally
          if (!level) {
            return originalSubSidebar.call(this, level);
          }

          // Check if we should prevent left sidebar TOC
          if (shouldPreventLeftSidebarTOC()) {
            // Return empty string to prevent left sidebar sub-navigation
            return '';
          }

          // For right-side TOC or other contexts, proceed normally
          return originalSubSidebar.call(this, level);
        };

        state.isInitialized = true;
        state.originalSubSidebar = originalSubSidebar;
      }
    }
  }

  /**
   * Initialize the plugin using proper Docsify plugin hooks
   * @private
   */
  function preventSidebarTOCPlugin(hook, _vm) {
    let originalSubSidebar = null;

    hook.ready(() => {
      // Initialize when Docsify is fully ready
      if (window.Docsify && window.Docsify.compiler) {
        originalSubSidebar = window.Docsify.compiler.subSidebar;

        if (originalSubSidebar) {
          // Override with our custom implementation
          window.Docsify.compiler.subSidebar = function(level) {
            // If called without level (cleanup call), proceed normally
            if (!level) {
              return originalSubSidebar.call(this, level);
            }

            // Check if we should prevent left sidebar TOC
            if (shouldPreventLeftSidebarTOC()) {
              // Return empty string to prevent left sidebar sub-navigation
              return '';
            }

            // For right-side TOC or other contexts, proceed normally
            return originalSubSidebar.call(this, level);
          };

          state.isInitialized = true;
          state.originalSubSidebar = originalSubSidebar;
        }
      }
    });

    hook.doneEach(() => {
      // Clean up any existing app-sub-sidebar elements from left sidebar
      cleanupExistingElements();

      // Ensure override persists on page changes
      if (!state.isInitialized && window.Docsify && window.Docsify.compiler && originalSubSidebar) {
        window.Docsify.compiler.subSidebar = originalSubSidebar;
      }
    });
  }

  /**
   * Clean up all plugin resources
   * @private
   */
  function cleanup() {
    try {
      // Restore original Docsify method if we have it
      if (state.originalSubSidebar && window.Docsify && window.Docsify.compiler) {
        window.Docsify.compiler.subSidebar = state.originalSubSidebar;
      }

      // Reset state
      state.isInitialized = false;
      state.originalSubSidebar = null;
    } catch (_error) {
      logger.error('Error during plugin cleanup', _error);
    }
  }

  /**
   * Reinitialize the plugin (cleanup and init)
   * @private
   */
  function reinitialize() {
    cleanup();
    initializeManually();
  }

  // Register as Docsify plugin using proper IIFE pattern
  if (typeof window !== 'undefined') {
    window.$docsify = window.$docsify || {};
    window.$docsify.plugins = window.$docsify.plugins || [];
    window.$docsify.plugins.push(preventSidebarTOCPlugin);

    // Expose debugging interface for testing
    window.PreventSidebarTOCPlugin = {
      cleanup,
      reinitialize,
      initialize: initializeManually,
      cleanupExistingElements,
      getState: () => ({ ...state })
    };
  }

  // For testing environments
  if (typeof globalThis !== 'undefined' && typeof globalThis.window !== 'undefined') {
    globalThis.window.PreventSidebarTOCPlugin = {
      cleanup,
      reinitialize,
      initialize: initializeManually,
      cleanupExistingElements,
      getState: () => ({ ...state })
    };
  }

})();
