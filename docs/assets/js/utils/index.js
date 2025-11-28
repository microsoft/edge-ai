/**
 * @fileoverview Central Utility Module Exports
 * Provides a clean, centralized import point for all utility modules
 * @version 1.0.0
 * @module utils
 */

// Import and re-export DOM utilities
import { DOMUtils } from './dom-utils.js';
export { DOMUtils };

// Debug helper utilities removed - using standard console methods

// Import and re-export Kata Detection utilities
import {
  KataDetection,
  defaultKataDetection as importedDefaultKataDetection,
  isKataPage,
  isLabPage,
  getCurrentLearningContext,
  getContentType,
  extractKataId
} from './kata-detection.js';

// Re-export the functions and class
export {
  KataDetection,
  isKataPage,
  isLabPage,
  getCurrentLearningContext,
  getContentType,
  extractKataId
};

/**
 * Re-export all utilities for convenience
 * This allows consumers to import either specific utilities or all at once
 *
 * @example
 * // Import specific utilities
 * import { DOMUtils, KataDetection } from './utils/index.js';
 *
 * @example
 * // Import convenience functions
 * import { isKataPage, getCurrentLearningContext } from './utils/index.js';
 *
 * @example
 * // Import everything
 * import * as Utils from './utils/index.js';
 */

/**
 * Create utility instances for convenience
 */
export const domUtils = new DOMUtils();
export const defaultKataDetection = new KataDetection();

/**
 * Conditional logger that respects debug mode
 * Only logs when debug mode is explicitly enabled
 */
export const logger = {
  _detectDebugMode() {
    try {
      // Check URL parameters
      if (typeof window !== 'undefined' && window.location) {
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.get('debug') === 'true') {
          return true;
        }
      }
      // Check localStorage
      if (typeof localStorage !== 'undefined') {
        if (localStorage.getItem('debugMode') === 'true') {
          return true;
        }
      }
      return false;
    } catch {
      return false;
    }
  },
  _enabled: null,
  get enabled() {
    if (this._enabled === null) {
      this._enabled = this._detectDebugMode();
    }
    return this._enabled;
  },
  log(message, ...args) {
    if (this.enabled) {
      console.log(message, ...args);
    }
  },
  info(message, ...args) {
    if (this.enabled) {
      console.info(message, ...args);
    }
  },
  warn(message, ...args) {
    // Always show warnings
    console.warn(message, ...args);
  },
  error(message, ...args) {
    // Always show errors
    console.error(message, ...args);
  }
};

/**
 * Export version information
 */
export const UTILS_VERSION = '1.0.0';

/**
 * Export utility metadata for debugging and development
 */
export const AVAILABLE_UTILITIES = {
  DOMUtils: {
    description: 'DOM manipulation and safety utilities',
    type: 'class',
    instance: 'domUtils'
  },
  KataDetection: {
    description: 'Learning content detection and path identification',
    type: 'class',
    instance: 'defaultKataDetection'
  }
};

/**
 * Utility function to get information about available utilities
 * @returns {Object} Information about all available utilities
 */
export function getUtilityInfo() {
  return {
    version: UTILS_VERSION,
    utilities: AVAILABLE_UTILITIES,
    count: Object.keys(AVAILABLE_UTILITIES).length
  };
}
