/**
 * Modular Test Infrastructure for TOC Architecture
 * Specialized test utilities and patterns for Test-Driven Development (TDD)
 * of the modular TOC system components
 *
 * @description Provides standardized TDD utilities for:
 * - Module dependency injection and mocking
 * - TOC-specific DOM setup and teardown
 * - Module lifecycle testing patterns
 * - Integration testing for modular architecture
 * - Performance testing utilities for TOC operations
 * @version 1.0.0
 */

import { vi } from 'vitest';
import { globalUtils, timerUtils } from './common-test-utils.js';

/**
 * Module Mock Factory for TOC Architecture
 * Creates standardized mocks for all TOC module interfaces
 */
export class ModuleMockFactory {
  constructor() {
    this.mocks = new Map();
    this.createdMocks = new Set();
  }

  /**
   * Create mock TOC Generator module
   * @param {Object} [overrides={}] - Custom mock implementations
   * @returns {Object} Mock TOC Generator
   */
  createTOCGeneratorMock(overrides = {}) {
    const mock = {
      // Core functionality
      generateTOC: vi.fn().mockReturnValue({
        structure: [],
        metadata: { totalHeaders: 0, maxLevel: 0, minLevel: 1 }
      }),
      discoverHeaders: vi.fn().mockReturnValue([]),
      buildStructure: vi.fn().mockReturnValue([]),
      generateDOM: vi.fn().mockReturnValue(document.createElement('div')),

      // Configuration
      setOptions: vi.fn(),
      getOptions: vi.fn().mockReturnValue({}),

      // Cache management
      clearCache: vi.fn(),
      getCacheStats: vi.fn().mockReturnValue({ hits: 0, misses: 0 }),

      // Error handling
      validateOptions: vi.fn().mockReturnValue(true),

      // Cleanup
      destroy: vi.fn(),

      // Override with custom implementations
      ...overrides
    };

    this.mocks.set('toc-generator', mock);
    this.createdMocks.add(mock);
    return mock;
  }

  /**
   * Create mock Scroll Manager module
   * @param {Object} [overrides={}] - Custom mock implementations
   * @returns {Object} Mock Scroll Manager
   */
  createScrollManagerMock(overrides = {}) {
    const mock = {
      // Core functionality
      initialize: vi.fn().mockResolvedValue(true),
      scrollToHeader: vi.fn().mockResolvedValue(true),
      getActiveHeader: vi.fn().mockReturnValue(null),
      updateActiveHeader: vi.fn(),

      // Event management
      startTracking: vi.fn(),
      stopTracking: vi.fn(),

      // Configuration
      setOptions: vi.fn(),
      getOptions: vi.fn().mockReturnValue({}),

      // Intersection Observer
      observeHeaders: vi.fn(),
      unobserveHeaders: vi.fn(),

      // Position management
      getCurrentPosition: vi.fn().mockReturnValue({ x: 0, y: 0 }),
      cachePosition: vi.fn(),

      // Cleanup
      destroy: vi.fn(),

      // Override with custom implementations
      ...overrides
    };

    this.mocks.set('scroll-manager', mock);
    this.createdMocks.add(mock);
    return mock;
  }

  /**
   * Create mock Event Coordinator module
   * @param {Object} [overrides={}] - Custom mock implementations
   * @returns {Object} Mock Event Coordinator
   */
  createEventCoordinatorMock(overrides = {}) {
    const mock = {
      // Core functionality
      on: vi.fn().mockReturnThis(),
      off: vi.fn().mockReturnThis(),
      emit: vi.fn().mockReturnThis(),
      once: vi.fn().mockReturnThis(),

      // Namespace management
      namespace: vi.fn().mockReturnValue('test-namespace'),
      removeNamespace: vi.fn(),

      // DOM integration
      onDOM: vi.fn().mockReturnThis(),
      offDOM: vi.fn().mockReturnThis(),

      // Statistics
      getStats: vi.fn().mockReturnValue({ listeners: 0, events: 0 }),
      getDebugInfo: vi.fn().mockReturnValue([]),

      // Cleanup
      destroy: vi.fn(),

      // Override with custom implementations
      ...overrides
    };

    this.mocks.set('event-coordinator', mock);
    this.createdMocks.add(mock);
    return mock;
  }

  /**
   * Create mock Plugin Registry module
   * @param {Object} [overrides={}] - Custom mock implementations
   * @returns {Object} Mock Plugin Registry
   */
  createPluginRegistryMock(overrides = {}) {
    const mock = {
      // Core functionality
      register: vi.fn().mockReturnValue(true),
      unregister: vi.fn().mockReturnValue(true),
      execute: vi.fn().mockResolvedValue([]),

      // Plugin management
      getPlugin: vi.fn().mockReturnValue(null),
      getPlugins: vi.fn().mockReturnValue([]),
      hasPlugin: vi.fn().mockReturnValue(false),

      // Execution control
      executePlugin: vi.fn().mockResolvedValue({}),
      executeByPriority: vi.fn().mockResolvedValue([]),

      // Options and configuration
      setPluginOptions: vi.fn(),
      getPluginOptions: vi.fn().mockReturnValue({}),

      // Debugging and stats
      getStats: vi.fn().mockReturnValue({ registered: 0, executed: 0 }),
      getDebugInfo: vi.fn().mockReturnValue([]),

      // Cleanup
      destroy: vi.fn(),

      // Override with custom implementations
      ...overrides
    };

    this.mocks.set('plugin-registry', mock);
    this.createdMocks.add(mock);
    return mock;
  }

  /**
   * Create mock Docsify Integration module
   * @param {Object} [overrides={}] - Custom mock implementations
   * @returns {Object} Mock Docsify Integration
   */
  createDocsifyIntegrationMock(overrides = {}) {
    const mock = {
      // Core functionality
      initialize: vi.fn().mockResolvedValue(true),
      registerHooks: vi.fn(),
      unregisterHooks: vi.fn(),

      // Hook management
      onReady: vi.fn(),
      onMounted: vi.fn(),
      onDoneEach: vi.fn(),

      // Router integration
      trackRoute: vi.fn(),
      getCurrentRoute: vi.fn().mockReturnValue('/'),

      // Content processing
      processContent: vi.fn().mockReturnValue('processed content'),
      extractHeaders: vi.fn().mockReturnValue([]),

      // Standalone mode
      enableStandalone: vi.fn(),
      disableStandalone: vi.fn(),

      // Configuration
      setOptions: vi.fn(),
      getOptions: vi.fn().mockReturnValue({}),

      // Cleanup
      destroy: vi.fn(),

      // Override with custom implementations
      ...overrides
    };

    this.mocks.set('docsify-integration', mock);
    this.createdMocks.add(mock);
    return mock;
  }

  /**
   * Create mock Highlighting Controller module
   * @param {Object} [overrides={}] - Custom mock implementations
   * @returns {Object} Mock Highlighting Controller
   */
  createHighlightingControllerMock(overrides = {}) {
    const mock = {
      // Core functionality
      initialize: vi.fn().mockResolvedValue(true),
      highlightHeader: vi.fn(),
      clearHighlights: vi.fn(),
      updateHighlight: vi.fn(),

      // CSS management
      applyHighlightCSS: vi.fn(),
      removeHighlightCSS: vi.fn(),

      // State management
      getCurrentHighlight: vi.fn().mockReturnValue(null),
      setActiveHeader: vi.fn(),

      // Animation control
      animateHighlight: vi.fn().mockResolvedValue(true),
      setAnimationOptions: vi.fn(),

      // Configuration
      setOptions: vi.fn(),
      getOptions: vi.fn().mockReturnValue({}),

      // Accessibility
      updateAriaLabels: vi.fn(),
      announceChange: vi.fn(),

      // Cleanup
      destroy: vi.fn(),

      // Override with custom implementations
      ...overrides
    };

    this.mocks.set('highlighting-controller', mock);
    this.createdMocks.add(mock);
    return mock;
  }

  /**
   * Create mock TOC Controller module
   * @param {Object} [overrides={}] - Custom mock implementations
   * @returns {Object} Mock TOC Controller
   */
  createTOCControllerMock(overrides = {}) {
    const mock = {
      // Core functionality
      initialize: vi.fn().mockResolvedValue(true),
      generate: vi.fn().mockResolvedValue(true),
      refresh: vi.fn().mockResolvedValue(true),

      // Module coordination
      getModule: vi.fn().mockReturnValue(null),
      setModule: vi.fn(),

      // Lifecycle management
      start: vi.fn().mockResolvedValue(true),
      stop: vi.fn().mockResolvedValue(true),
      restart: vi.fn().mockResolvedValue(true),

      // Configuration
      configure: vi.fn(),
      getConfiguration: vi.fn().mockReturnValue({}),

      // State management
      getState: vi.fn().mockReturnValue({ status: 'ready' }),
      setState: vi.fn(),

      // Performance monitoring
      getMetrics: vi.fn().mockReturnValue({ performance: {} }),
      resetMetrics: vi.fn(),

      // Error handling
      handleError: vi.fn(),
      getLastError: vi.fn().mockReturnValue(null),

      // Cleanup
      destroy: vi.fn(),

      // Override with custom implementations
      ...overrides
    };

    this.mocks.set('toc-controller', mock);
    this.createdMocks.add(mock);
    return mock;
  }

  /**
   * Get existing mock by name
   * @param {string} mockName - Name of the mock
   * @returns {Object|null} Mock object or null if not found
   */
  getMock(mockName) {
    return this.mocks.get(mockName) || null;
  }

  /**
   * Create complete mock suite for integration testing
   * @param {Object} [overrides={}] - Module-specific overrides
   * @returns {Object} Complete mock suite
   */
  createMockSuite(overrides = {}) {
    return {
      tocGenerator: this.createTOCGeneratorMock(overrides.tocGenerator),
      scrollManager: this.createScrollManagerMock(overrides.scrollManager),
      eventCoordinator: this.createEventCoordinatorMock(overrides.eventCoordinator),
      pluginRegistry: this.createPluginRegistryMock(overrides.pluginRegistry),
      docsifyIntegration: this.createDocsifyIntegrationMock(overrides.docsifyIntegration),
      highlightingController: this.createHighlightingControllerMock(overrides.highlightingController),
      tocController: this.createTOCControllerMock(overrides.tocController)
    };
  }

  /**
   * Clean up all created mocks
   */
  cleanup() {
    for (const mock of this.createdMocks) {
      // Reset all mock calls and implementations
      Object.values(mock).forEach(mockFn => {
        if (vi.isMockFunction(mockFn)) {
          mockFn.mockReset();
        }
      });
    }

    this.mocks.clear();
    this.createdMocks.clear();
  }
}

/**
 * Module Test Environment Manager
 * Manages complete test environment setup for modular TOC testing
 */
export class ModuleTestEnvironment {
  constructor() {
    this.mockFactory = new ModuleMockFactory();
    this.domElements = new Set();
    this.eventListeners = new Set();
    this.timers = new Set();
  }

  /**
   * Setup complete module test environment
   * @param {Object} [options={}] - Environment setup options
   * @returns {Promise<Object>} Environment setup result
   */
  async setup(options = {}) {
    const {
      dom = true,
      mocks = true,
      timers = true,
      events = true,
      performance = false
    } = options;

    const environment = {};

    // Setup DOM environment
    if (dom) {
      environment.dom = await this.setupDOM(options.domOptions);
    }

    // Setup mocks
    if (mocks) {
      environment.mocks = this.mockFactory.createMockSuite(options.mockOverrides);
    }

    // Setup timer tracking
    if (timers) {
      timerUtils.startTracking();
    }

    // Setup event tracking
    if (events) {
      this.setupEventTracking();
    }

    // Setup performance monitoring
    if (performance) {
      environment.performance = this.setupPerformanceMonitoring();
    }

    return environment;
  }

  /**
   * Setup DOM environment for TOC testing
   * @param {Object} [options={}] - DOM setup options
   * @returns {Promise<Object>} DOM environment
   */
  async setupDOM(options = {}) {
    const {
      container = true,
      headers = true,
      tocContainer = true,
      customHTML = null
    } = options;

    const dom = {};

    // Create main container
    if (container) {
      dom.container = document.createElement('div');
      dom.container.id = 'test-container';
      dom.container.className = 'toc-test-container';
      document.body.appendChild(dom.container);
      this.domElements.add(dom.container);
    }

    // Create TOC container
    if (tocContainer) {
      dom.tocContainer = document.createElement('div');
      dom.tocContainer.id = 'toc-container';
      dom.tocContainer.className = 'toc-container';

      if (dom.container) {
        dom.container.appendChild(dom.tocContainer);
      } else {
        document.body.appendChild(dom.tocContainer);
      }

      this.domElements.add(dom.tocContainer);
    }

    // Create test headers
    if (headers) {
      dom.headers = this.createTestHeaders(options.headerOptions);
      dom.headers.forEach(header => {
        if (dom.container) {
          dom.container.appendChild(header);
        } else {
          document.body.appendChild(header);
        }
        this.domElements.add(header);
      });
    }

    // Add custom HTML if provided
    if (customHTML) {
      const customContainer = document.createElement('div');
      customContainer.innerHTML = customHTML;

      if (dom.container) {
        dom.container.appendChild(customContainer);
      } else {
        document.body.appendChild(customContainer);
      }

      this.domElements.add(customContainer);
      dom.customContainer = customContainer;
    }

    return dom;
  }

  /**
   * Create test headers for TOC generation
   * @param {Object} [options={}] - Header creation options
   * @returns {HTMLElement[]} Array of header elements
   */
  createTestHeaders(options = {}) {
    const {
      levels = [1, 2, 3, 2, 1],
      baseName = 'Test Header',
      generateIds = true,
      addContent = true
    } = options;

    const headers = [];

    levels.forEach((level, _index) => {
      const header = document.createElement(`h${level}`);
      const headerText = `${baseName} ${_index + 1}`;

      header.textContent = headerText;

      if (generateIds) {
        header.id = `header-${_index + 1}`;
      }

      if (addContent) {
        // Add some content after each header
        const content = document.createElement('p');
        content.textContent = `Content for ${headerText}`;
        content.className = 'header-content';
        headers.push(header, content);
      } else {
        headers.push(header);
      }
    });

    return headers;
  }

  /**
   * Setup event tracking for cleanup
   */
  setupEventTracking() {
    const originalAddEventListener = EventTarget.prototype.addEventListener;
    const trackedListeners = this.eventListeners;

    EventTarget.prototype.addEventListener = function(type, listener, _options) {
      trackedListeners.add({ element: this, type, listener, options: _options });
      return originalAddEventListener.call(this, type, listener, _options);
    };
  }

  /**
   * Setup performance monitoring
   * @returns {Object} Performance monitoring utilities
   */
  setupPerformanceMonitoring() {
    const performanceMarks = new Map();
    const performanceMeasures = new Map();

    return {
      mark: (name) => {
        const timestamp = performance.now();
        performanceMarks.set(name, timestamp);
        return timestamp;
      },

      measure: (name, startMark, endMark) => {
        const startTime = performanceMarks.get(startMark);
        const endTime = performanceMarks.get(endMark) || performance.now();
        const duration = endTime - startTime;

        performanceMeasures.set(name, {
          startTime,
          endTime,
          duration
        });

        return duration;
      },

      getMarks: () => performanceMarks,
      getMeasures: () => performanceMeasures,

      clear: () => {
        performanceMarks.clear();
        performanceMeasures.clear();
      }
    };
  }

  /**
   * Complete environment cleanup
   */
  async cleanup() {
    // Clean up DOM elements
    for (const element of this.domElements) {
      if (element.parentNode) {
        element.parentNode.removeChild(element);
      }
    }
    this.domElements.clear();

    // Clean up event listeners
    for (const { element, type, listener, options: _options } of this.eventListeners) {
      try {
        element.removeEventListener(type, listener, _options);
      } catch {
        // Ignore cleanup errors
      }
    }
    this.eventListeners.clear();

    // Restore original addEventListener
    delete EventTarget.prototype.addEventListener;

    // Clean up timers
    timerUtils.clearAllTimers();
    timerUtils.stopTracking();

    // Clean up mocks
    this.mockFactory.cleanup();

    // Clean up globals
    globalUtils.cleanupGlobals();
  }
}

/**
 * TDD Test Pattern Utilities
 * Specialized utilities for Test-Driven Development patterns
 */
export const tddPatterns = {
  /**
   * Test module initialization pattern
   * @param {Function} ModuleClass - Module constructor
   * @param {Object} [options={}] - Test options
   * @returns {Function} Test function
   */
  testModuleInitialization(ModuleClass, options = {}) {
    return async function() {
      const { validOptions = {}, invalidOptions = [null, undefined, 'string'] } = options;

      // Test valid initialization
      const module = new ModuleClass(validOptions);
      expect(module).toBeDefined();
      expect(typeof module).toBe('object');

      // Test invalid initialization
      for (const invalidOption of invalidOptions) {
        expect(() => new ModuleClass(invalidOption)).toThrow();
      }

      // Test initialization with defaults
      const defaultModule = new ModuleClass();
      expect(defaultModule).toBeDefined();

      // Cleanup
      if (typeof module.destroy === 'function') {
        await module.destroy();
      }
      if (typeof defaultModule.destroy === 'function') {
        await defaultModule.destroy();
      }
    };
  },

  /**
   * Test module configuration pattern
   * @param {Object} module - Module instance
   * @param {Object} [options={}] - Test options
   * @returns {Function} Test function
   */
  testModuleConfiguration(module, options = {}) {
    return function() {
      const { validConfig = {}, invalidConfig = {} } = options;

      // Test setting valid configuration
      if (typeof module.setOptions === 'function') {
        expect(() => module.setOptions(validConfig)).not.toThrow();

        if (typeof module.getOptions === 'function') {
          const currentConfig = module.getOptions();
          expect(currentConfig).toMatchObject(validConfig);
        }
      }

      // Test setting invalid configuration
      if (Object.keys(invalidConfig).length > 0 && typeof module.setOptions === 'function') {
        expect(() => module.setOptions(invalidConfig)).toThrow();
      }
    };
  },

  /**
   * Test module cleanup pattern
   * @param {Object} module - Module instance
   * @returns {Function} Test function
   */
  testModuleCleanup(module) {
    return async function() {
      // Test cleanup method exists
      expect(typeof module.destroy).toBe('function');

      // Test cleanup executes without error
      await expect(module.destroy()).resolves.not.toThrow();

      // Test multiple cleanup calls are safe
      await expect(module.destroy()).resolves.not.toThrow();
    };
  },

  /**
   * Test module error handling pattern
   * @param {Object} module - Module instance
   * @param {Object} [options={}] - Test options
   * @returns {Function} Test function
   */
  testModuleErrorHandling(module, options = {}) {
    return function() {
      const { errorScenarios = [] } = options;

      for (const scenario of errorScenarios) {
        const { method, args, expectedError } = scenario;

        if (typeof module[method] === 'function') {
          if (expectedError) {
            expect(() => module[method](...args)).toThrow(expectedError);
          } else {
            expect(() => module[method](...args)).toThrow();
          }
        }
      }
    };
  }
};

/**
 * Integration Test Utilities
 * Utilities for testing module interactions and integration patterns
 */
export const integrationUtils = {
  /**
   * Test module communication pattern
   * @param {Object} moduleA - First module
   * @param {Object} moduleB - Second module
   * @param {Object} [options={}] - Test options
   * @returns {Function} Test function
   */
  testModuleCommunication(moduleA, moduleB, options = {}) {
    return function() {
      const { eventName = 'test-event', eventData = { test: true } } = options;

      // Setup communication test
      let receivedEvent = null;

      if (typeof moduleB.on === 'function') {
        moduleB.on(eventName, (data) => {
          receivedEvent = data;
        });
      }

      // Trigger communication
      if (typeof moduleA.emit === 'function') {
        moduleA.emit(eventName, eventData);
      }

      // Verify communication
      expect(receivedEvent).toEqual(eventData);
    };
  },

  /**
   * Test module dependency injection pattern
   * @param {Function} ModuleClass - Module constructor
   * @param {Object} dependencies - Required dependencies
   * @returns {Function} Test function
   */
  testModuleDependencyInjection(ModuleClass, dependencies) {
    return function() {
      // Test with valid dependencies
      const module = new ModuleClass(dependencies);
      expect(module).toBeDefined();

      // Test with missing dependencies
      const incompleteDependencies = { ...dependencies };
      delete incompleteDependencies[Object.keys(dependencies)[0]];

      expect(() => new ModuleClass(incompleteDependencies)).toThrow();
    };
  },

  /**
   * Test module lifecycle coordination
   * @param {Object[]} modules - Array of modules to test
   * @returns {Function} Test function
   */
  testModuleLifecycleCoordination(modules) {
    return async function() {
      // Test initialization order
      for (const module of modules) {
        if (typeof module.initialize === 'function') {
          await expect(module.initialize()).resolves.not.toThrow();
        }
      }

      // Test cleanup order (reverse)
      for (const module of modules.reverse()) {
        if (typeof module.destroy === 'function') {
          await expect(module.destroy()).resolves.not.toThrow();
        }
      }
    };
  }
};

// Export singleton instance for convenience
export const moduleTestSetup = new ModuleTestEnvironment();

// Export all utilities
export default {
  ModuleMockFactory,
  ModuleTestEnvironment,
  tddPatterns,
  integrationUtils,
  moduleTestSetup
};
