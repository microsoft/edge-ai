/**
 * Helper Composition System
 * Allows mixing and matching focused helpers for test isolation
 * @module tests/helpers/focused/compose-helpers
 */

import { createMockHelper, cleanup as _cleanupVitest } from './vitest-helper.js';
import { createDOMHelper } from './dom-helper.js';
import { createStorageHelper, cleanup as _cleanupStorage } from './storage-helper.js';
import { createErrorHandler, createSpyErrorHandler, cleanup as cleanupError } from './error-helper.js';

/**
 * Compose multiple focused helpers into a unified test context
 * @param {Object} config - Configuration for which helpers to include
 * @param {boolean} config.sinon - Include Sinon sandbox
 * @param {boolean|string} config.dom - Include DOM helpers ('container', 'form', 'nav', or true for container)
 * @param {boolean|Object} config.storage - Include localStorage mocking (true or options object)
 * @param {boolean|Object} config.errorHandler - Include error handler stubs (true or options object)
 * @returns {Object} Composed test context with all requested helpers
 */
export function composeHelpers(config = {}) {
  const context = {};
  const cleanupFunctions = [];

  // Vitest mock utilities
  if (config.mockUtils || config.sinon) {
    const { mockUtils, cleanup } = createMockHelper();
    context.sandbox = mockUtils;
    context.sinon = mockUtils; // Alias for compatibility
    context.mockUtils = mockUtils; // Preferred name
    cleanupFunctions.push(cleanup);
  }

  // DOM helpers
  if (config.dom) {
    const domHelper = createDOMHelper();
    let domContext;

    if (config.dom === 'form') {
      domContext = domHelper.createForm();
    } else if (config.dom === 'nav') {
      domContext = domHelper.createNavigation();
    } else if (config.dom === 'checkbox') {
      domContext = domHelper.createCheckboxList();
    } else {
      // Default to container for any truthy value
      domContext = domHelper.createContainer();
    }

    context.dom = domContext;
    context.container = domContext; // Common access pattern
    cleanupFunctions.push(() => domHelper.cleanup());
  }

  // Storage mocking
  if (config.storage) {
    const storageOptions = config.storage === true ? {} : config.storage;
    const storageHelper = createStorageHelper(storageOptions);
    context.localStorage = storageHelper.localStorage;
    context.storage = storageHelper.localStorage; // Alias
    // Expose all storage helper methods
    context.clearStorage = storageHelper.clearStorage;
    context.setStorageState = storageHelper.setStorageState;
    context.getStorageState = storageHelper.getStorageState;
    context.hasKey = storageHelper.hasKey;
    context.getKeys = storageHelper.getKeys;
    cleanupFunctions.push(storageHelper.cleanup);
  }

  // Error handler stubs
  if (config.errorHandler) {
    const errorOptions = config.errorHandler === true ? {} : config.errorHandler;

    // Use spy version if mockUtils sandbox is available
    if (context.sandbox && !errorOptions.noSpy) {
      context.errorHandler = createSpyErrorHandler(context.sandbox, errorOptions);
    } else {
      context.errorHandler = createErrorHandler(errorOptions);
    }

    cleanupFunctions.push(() => cleanupError());
  }

  // Add global cleanup method
  context.cleanup = () => {
    // Run cleanup functions in reverse order (LIFO)
    cleanupFunctions.reverse().forEach(cleanup => {
      try {
        cleanup();
      } catch (_error) {
        console.warn('Cleanup function failed:', _error);
      }
    });
  };

  // Add beforeEach/afterEach compatibility
  context.beforeEach = () => {
    // Most setup is done during composition, this is for any per-test initialization
  };

  context.afterEach = () => {
    context.cleanup();
  };

  // Add legacy-compatible mocks
  context.mocks = {};

  if (context.errorHandler) {
    context.mocks.errorHandler = context.errorHandler;
  }

  if (context.storage) {
    // Wrap storage methods with Vitest spies for test assertions
    if (context.sandbox) {
      context.mocks.storage = {
        getItem: context.sandbox.fn(context.storage.getItem.bind(context.storage)),
        setItem: context.sandbox.fn(context.storage.setItem.bind(context.storage)),
        removeItem: context.sandbox.fn(context.storage.removeItem.bind(context.storage)),
        clear: context.sandbox.fn(context.storage.clear.bind(context.storage)),
        key: context.sandbox.fn(context.storage.key.bind(context.storage)),
        get length() { return context.storage.length; }
      };
    } else {
      context.mocks.storage = context.storage;
    }
  }

  // Add basic utility mocks if mockUtils is available
  if (context.sandbox) {
    context.mocks.domUtils = {
      validateElement: context.sandbox.fn(() => true),
      findElement: context.sandbox.fn(),
      createElement: context.sandbox.fn(),
      querySelector: context.sandbox.fn(),
      querySelectorAll: context.sandbox.fn(() => []), // Return empty array by default
      getElementBounds: context.sandbox.fn().mockReturnValue({ width: 100, height: 50 }),
      scrollToElement: context.sandbox.fn().mockReturnValue(Promise.resolve())
    };

    context.mocks.debugHelper = {
      log: context.sandbox.fn(),
      warn: context.sandbox.fn(),
      error: context.sandbox.fn(),
      group: context.sandbox.fn(),
      groupEnd: context.sandbox.fn()
    };
  }

  return context;
}

/**
 * Quick composition for common test patterns
 */
export const compositions = {
  /**
   * Minimal test context - just Vitest mock utilities
   * @returns {Object} Test context with mockUtils only
   */
  minimal() {
    return composeHelpers({ sinon: true });
  },

  /**
   * DOM-focused tests - Vitest + DOM container
   * @param {string} domType - Type of DOM structure ('container', 'form', 'nav', 'checkbox')
   * @returns {Object} Test context with mockUtils and DOM
   */
  dom(domType = 'container') {
    return composeHelpers({
      sinon: true,
      dom: domType
    });
  },

  /**
   * Storage-focused tests - Vitest + localStorage mock
   * @param {Object} storageOptions - Storage configuration options
   * @returns {Object} Test context with mockUtils and storage
   */
  storage(storageOptions = {}) {
    return composeHelpers({
      sinon: true,
      storage: storageOptions
    });
  },

  /**
   * Component tests - Vitest + DOM + Error handling
   * @param {string} domType - Type of DOM structure
   * @param {Object} errorOptions - Error handler configuration
   * @returns {Object} Test context for component testing
   */
  component(domType = 'container', errorOptions = {}) {
    return composeHelpers({
      sinon: true,
      dom: domType,
      errorHandler: errorOptions
    });
  },

  /**
   * Full-featured tests - All helpers enabled
   * @param {Object} options - Configuration for all helpers
   * @returns {Object} Complete test context with all helpers
   */
  full(options = {}) {
    return composeHelpers({
      sinon: true,
      dom: options.dom || 'container',
      storage: options.storage || {},
      errorHandler: options.errorHandler || {}
    });
  }
};

/**
 * Legacy interface compatibility - matches module-test-helpers patterns
 * Creates test context similar to createCoreModuleTest/createFeatureModuleTest
 * @param {string} type - Type of test ('core', 'feature', 'component')
 * @param {Object} options - Configuration options
 * @returns {Object} Test context with legacy-compatible interface
 */
export function createTestContext(type = 'core', options = {}) {
  let config;

  switch (type) {
    case 'core':
      // Core modules typically need minimal setup
      config = { sinon: true, errorHandler: true };
      break;

    case 'feature':
      // Feature modules often need DOM and storage
      config = {
        sinon: true,
        dom: options.domType || 'container',
        storage: true,
        errorHandler: true
      };
      break;

    case 'component':
      // Components need full context
      config = {
        sinon: true,
        dom: options.domType || 'container',
        errorHandler: true
      };
      break;

    default:
      config = { sinon: true };
  }

  const context = composeHelpers(config);

  // Add legacy-compatible aliases
  if (context.errorHandler) {
    context.mocks = { errorHandler: context.errorHandler };
  }

  context.window = globalThis;
  context.document = document;

  return context;
}
