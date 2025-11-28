/**
 * Common Test Utilities
 * Comprehensive testing utilities for consistent test setup and cleanup across all test files
 *
 * @description Provides standardized solutions for common testing patterns:
 * - File path resolution
 * - Timer and resource cleanup
 * - Global variable isolation
 * - Happy DOM safety enhancements
 * - DOM method mocking
 * - Mock data generation
 * - DOM element creation and management
 * - Event simulation
 * @version 2.0.0
 */

import path from 'path';
import { fileURLToPath } from 'url';
import { vi } from 'vitest';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * DOM Testing Utilities
 * Enhanced DOM manipulation and testing utilities
 */
export class DOMTestUtils {
  constructor() {
    this.createdElements = new Set();
    this.addedStyles = new Set();
    this.eventListeners = new WeakMap();
  }

  /**
   * Create a DOM element with optional attributes and content
   * @param {string} tagName - HTML tag name
   * @param {Object} attributes - Element attributes
   * @param {string} content - Inner HTML content
   * @returns {HTMLElement} Created element
   */
  createElement(tagName, attributes = {}, content = '') {
    const element = document.createElement(tagName);

    // Set attributes
    Object.entries(attributes).forEach(([key, value]) => {
      if (key === 'className') {
        element.className = value;
      } else if (key === 'dataset') {
        Object.entries(value).forEach(([dataKey, dataValue]) => {
          element.dataset[dataKey] = dataValue;
        });
      } else {
        element.setAttribute(key, value);
      }
    });

    // Set content
    if (content) {
      element.innerHTML = content;
    }

    // Track created element for cleanup
    this.createdElements.add(element);

    return element;
  }

  /**
   * Create a test container with specified ID and content
   * @param {string} id - Container ID
   * @param {string} content - Container content
   * @returns {HTMLElement} Container element
   */
  createContainer(id = 'test-container', content = '') {
    // Remove existing container
    const existing = document.getElementById(id);
    if (existing) {
      existing.remove();
    }

    const container = this.createElement('div', { id }, content);
    document.body.appendChild(container);

    return container;
  }

  /**
   * Create progress banner DOM structure for testing
   * @param {Object} options - Banner configuration options
   * @returns {HTMLElement} Banner container element
   */
  createProgressBannerDOM(options = {}) {
    const {
      id = 'progress-banner',
      totalSteps = 12,
      currentStep = 1,
      showPercentage = true,
      showStepInfo = true
    } = options;

    const bannerHTML = `
      <div class="progress-banner" id="${id}">
        <div class="progress-banner-content">
          <div class="progress-info">
            ${showStepInfo ? `<span class="step-info">Step ${currentStep} of ${totalSteps}</span>` : ''}
            ${showPercentage ? `<span class="progress-percentage">${Math.round((currentStep / totalSteps) * 100)}%</span>` : ''}
          </div>
          <div class="progress-bar">
            <div class="progress-fill" style="width: ${(currentStep / totalSteps) * 100}%"></div>
          </div>
        </div>
      </div>
    `;

    return this.createElement('div', { className: 'progress-banner-container' }, bannerHTML);
  }

  /**
   * Create learning path card DOM structure for testing
   * @param {Object} options - Card configuration options
   * @returns {HTMLElement} Card container element
   */
  createLearningPathCardDOM(options = {}) {
    const {
      pathId = 'default-path',
      title = 'Learning Path',
      description = 'Description of the learning path',
      totalSteps = 8,
      completedSteps = 0,
      showProgress = true,
      showBadges = true,
      skillLevel = 'intermediate',
      estimatedTime = '2 hours',
      cardLayout = 'default'
    } = options;

    const progressPercentage = Math.round((completedSteps / totalSteps) * 100);
    const state = completedSteps === 0 ? 'not-started' :
                  completedSteps === totalSteps ? 'completed' : 'in-progress';

    const badgesHTML = showBadges ? `
      <div class="achievement-badges">
        ${progressPercentage >= 25 ? '<span class="badge first-steps">🎯</span>' : ''}
        ${progressPercentage >= 50 ? '<span class="badge halfway">⭐</span>' : ''}
        ${progressPercentage === 100 ? '<span class="badge completed">🏆</span>' : ''}
      </div>
    ` : '';

    const progressHTML = showProgress ? `
      <div class="card-progress">
        <div class="progress-stats">
          <span class="progress-text">${completedSteps}/${totalSteps} steps</span>
          <span class="progress-percentage">${progressPercentage}%</span>
        </div>
        <div class="progress-bar">
          <div class="progress-fill" style="width: ${progressPercentage}%"></div>
        </div>
      </div>
    ` : '';

    const actionButton = state === 'not-started' ? 'Start' :
                        state === 'in-progress' ? 'Continue' : 'Review';

    const cardHTML = `
      <article class="learning-path-card ${cardLayout}" data-path-id="${pathId}" data-state="${state}">
        <div class="card-header">
          <div class="card-meta">
            <span class="skill-level">${skillLevel}</span>
            <span class="estimated-time">${estimatedTime}</span>
          </div>
          ${badgesHTML}
        </div>

        <div class="card-content">
          <h3 class="card-title">${title}</h3>
          <p class="card-description">${description}</p>
        </div>

        ${progressHTML}

        <div class="card-actions">
          <button class="action-button primary" data-action="${actionButton.toLowerCase()}">
            ${actionButton}
          </button>
          <button class="action-button secondary" data-action="bookmark">
            Bookmark
          </button>
        </div>
      </article>
    `;

    const container = this.createElement('div', {
      className: 'learning-path-card-container',
      dataset: { testId: 'learning-path-card' }
    }, cardHTML);

    this.createdElements.add(container);
    return container;
  }

  /**
   * Create progress indicator DOM structure for testing
   * @deprecated Badge system removed
   * @param {Object} options - Configuration options
   * @returns {HTMLElement} Container element
   */
  /**
   * @deprecated Badge system removed
   * @returns {HTMLElement} Empty container for backwards compatibility
   */
  createCompletionBadgeDOM(options = {}) {
    const container = document.createElement('div');
    container.className = 'progress-indicator';
    this.createdElements.add(container);
    return container;
  }

  /**
   * Inject CSS styles into the test document
   * @param {string} cssContent - CSS content to inject
   * @param {string} id - Style element ID
   * @returns {HTMLStyleElement} Style element
   */
  injectCSS(cssContent, id = 'test-styles') {
    // Remove existing styles
    const existing = document.getElementById(id);
    if (existing) {
      existing.remove();
    }

    const style = document.createElement('style');
    style.id = id;
    style.textContent = cssContent;
    document.head.appendChild(style);

    // Track for cleanup
    this.addedStyles.add(style);

    return style;
  }

  /**
   * Simulate user events on elements
   * @param {HTMLElement} element - Target element
   * @param {string} eventType - Event type to simulate
   * @param {Object} options - Event options
   */
  simulateEvent(element, eventType, options = {}) {
    let event;

    switch (eventType) {
      case 'click':
        event = new MouseEvent('click', {
          bubbles: true,
          cancelable: true,
          view: window,
          ...options
        });
        break;

      case 'keydown':
      case 'keyup':
        event = new KeyboardEvent(eventType, {
          bubbles: true,
          cancelable: true,
          ...options
        });
        break;

      case 'scroll':
        element.scrollTop = options.scrollTop || 0;
        element.scrollLeft = options.scrollLeft || 0;
        event = new Event('scroll', {
          bubbles: true,
          cancelable: true
        });
        break;

      case 'resize':
        Object.defineProperty(window, 'innerWidth', {
          value: options.width || 1024,
          configurable: true
        });
        Object.defineProperty(window, 'innerHeight', {
          value: options.height || 768,
          configurable: true
        });
        event = new Event('resize');
        break;

      default:
        event = new Event(eventType, {
          bubbles: true,
          cancelable: true,
          ...options
        });
    }

    element.dispatchEvent(event);
    return event;
  }

  /**
   * Wait for DOM mutations or animations to complete
   * @param {number} timeout - Timeout in milliseconds
   * @returns {Promise} Promise that resolves after timeout
   */
  async waitForDOM(timeout = 100) {
    return new Promise(resolve => setTimeout(resolve, timeout));
  }

  /**
   * Clean up all created test elements and styles
   */
  cleanup() {
    // Remove all created elements
    this.createdElements.forEach(element => {
      if (element.parentNode) {
        element.parentNode.removeChild(element);
      }
    });
    this.createdElements.clear();

    // Remove all added styles
    this.addedStyles.forEach(style => {
      if (style.parentNode) {
        style.parentNode.removeChild(style);
      }
    });
    this.addedStyles.clear();

    // Clear event listeners tracking
    this.eventListeners = new WeakMap();

    // Clean up any remaining test elements
    const testElements = document.querySelectorAll('[id*="test"], [class*="test"]');
    testElements.forEach(element => element.remove());

    // Reset document body
    if (document.body) {
      document.body.innerHTML = '';
      document.body.className = '';
      document.body.style.cssText = '';
    }
  }
}

/**
 * Mock Data Generator Class
 * Enhanced data generation for testing scenarios
 */
export class MockDataGenerator {
  /**
   * Generate progress data for testing
   * @param {Object} options - Generation options
   * @returns {Object} Progress data
   */
  static generateProgressData(options = {}) {
    const {
      totalSteps = 12,
      completedSteps = 3,
      stepNames = null
    } = options;

    const steps = stepNames || Array.from(
      { length: totalSteps },
      (_, i) => `Step ${i + 1}`
    );

    return {
      totalSteps,
      completedSteps,
      currentStep: Math.min(completedSteps + 1, totalSteps),
      percentage: Math.round((completedSteps / totalSteps) * 100),
      steps,
      isComplete: completedSteps === totalSteps
    };
  }

  /**
   * Generate skill assessment data for testing
   * @param {Object} options - Generation options
   * @returns {Object} Assessment data
   */
  static generateAssessmentData(options = {}) {
    const {
      totalQuestions = 12,
      currentQuestion = 1,
      answers = {}
    } = options;

    return {
      totalQuestions,
      currentQuestion,
      answers,
      progress: Math.round((Object.keys(answers).length / totalQuestions) * 100),
      isComplete: Object.keys(answers).length === totalQuestions
    };
  }

  /**
   * Generate learning path data for testing (alias for generateLearningPathData)
   * @param {Object} options - Generation options
   * @returns {Object} Learning path data
   */
  static generatePathData(options = {}) {
    return this.generateLearningPathData(options);
  }

  /**
   * Generate learning path data for testing
   * @param {Object} options - Generation options
   * @returns {Object} Learning path data
   */
  static generateLearningPathData(options = {}) {
    const {
      pathId = 'default-path',
      title = 'Learning Path',
      description = 'A comprehensive learning path',
      totalSteps = 8,
      completedSteps = 0,
      skillLevel = 'intermediate',
      estimatedTime = '2 hours',
      category = 'general',
      tags = ['learning', 'tutorial'],
      state = null,
      timeSpent = 0,
      lastAccessed = null,
      progressPercentage = null
    } = options;

    // Calculate derived values
    const calculatedProgress = progressPercentage !== null ?
      progressPercentage : Math.round((completedSteps / totalSteps) * 100);

    const derivedState = state || (
      completedSteps === 0 ? 'not-started' :
      completedSteps === totalSteps ? 'completed' : 'in-progress'
    );

    // Generate achievement badges based on progress
    const badges = [];
    if (calculatedProgress >= 25) badges.push('first-steps');
    if (calculatedProgress >= 50) badges.push('halfway');
    if (calculatedProgress === 100) badges.push('completed');
    if (timeSpent > 3600000) badges.push('dedicated-learner'); // 1 hour+

    return {
      pathId,
      title,
      description,
      totalSteps,
      completedSteps,
      progressPercentage: calculatedProgress,
      state: derivedState,
      skillLevel,
      estimatedTime,
      category,
      tags,
      badges,
      timeSpent,
      lastAccessed: lastAccessed || Date.now(),
      isComplete: derivedState === 'completed',
      nextStep: completedSteps < totalSteps ? completedSteps + 1 : null,
      completionDate: derivedState === 'completed' ? Date.now() : null
    };
  }

  /**
   * Generate badge data for testing
   * @deprecated Badge system removed
   * @param {Object} options - Badge configuration options
   * @returns {Object} Empty badge data
   */
  static generateBadgeData(options = {}) {
    // Badge system removed - return minimal data for backwards compatibility
    return {
      id: options.id || 'deprecated',
      name: 'Badge system removed',
      isUnlocked: false
    };
  }

  /**
   * Calculate unlocked badges based on progress
   * @deprecated Badge system removed
   * @param {Object} options - Progress data
   * @returns {Array} Empty array
   */
  static calculateUnlockedBadges(options = {}) {
    // Badge system removed - return empty array for backwards compatibility
    return [];
  }

  /**
   * Generate localStorage data for testing
   * @param {Object} options - Generation options
   * @returns {Object} LocalStorage data
   */
  static generateStorageData(options = {}) {
    const {
      progressKey = 'skill-assessment-progress',
      progressData = null
    } = options;

    const data = progressData || this.generateProgressData();

    return {
      [progressKey]: JSON.stringify(data),
      [`${progressKey}-timestamp`]: Date.now().toString()
    };
  }
}

/**
 * Mock Environment Setup
 * Enhanced environment configuration
 */
export function createMockEnvironment(options = {}) {
  const {
    mockLocalStorage = true,
    mockConsole = true,
    injectCSS = true
  } = options;

  const mocks = {};

  // Setup localStorage mock
  if (mockLocalStorage) {
    const localStorageMock = {
      store: {},
      getItem: vi.fn((key) => localStorageMock.store[key] || null),
      setItem: vi.fn((key, value) => { localStorageMock.store[key] = value; }),
      removeItem: vi.fn((key) => { delete localStorageMock.store[key]; }),
      clear: vi.fn(() => { localStorageMock.store = {}; }),
      length: 0,
      key: vi.fn()
    };

    Object.defineProperty(window, 'localStorage', {
      value: localStorageMock,
      writable: true
    });

    mocks.localStorage = localStorageMock;
  }

  // Setup console mocks
  if (mockConsole) {
    const consoleMocks = {
      log: vi.spyOn(console, 'log').mockImplementation(() => {}),
      warn: vi.spyOn(console, 'warn').mockImplementation(() => {}),
      error: vi.spyOn(console, 'error').mockImplementation(() => {})
    };

    mocks.console = consoleMocks;
  }

  // Inject basic CSS for testing
  if (injectCSS) {
    const style = document.createElement('style');
    style.textContent = `
      .progress-banner {
        width: 100%;
        background: #f0f0f0;
        border-radius: 4px;
        padding: 8px;
      }

      .progress-bar {
        width: 100%;
        height: 20px;
        background: #e0e0e0;
        border-radius: 10px;
        overflow: hidden;
      }

      .progress-fill {
        height: 100%;
        background: #007acc;
        transition: width 0.3s ease;
      }

      .progress-info {
        display: flex;
        justify-content: space-between;
        margin-bottom: 4px;
        font-size: 14px;
      }
    `;
    document.head.appendChild(style);
  }

  return {
    mocks,
    mockLocalStorage: mocks.localStorage, // Export mockLocalStorage for direct access
    cleanup: () => {
      vi.restoreAllMocks();
      if (injectCSS) {
        const styles = document.querySelectorAll('style');
        styles.forEach(style => style.remove());
      }
    }
  };
}

/**
 * Create mock data generator instance
 * @returns {MockDataGenerator} Data generator instance
 */
export function createMockDataGenerator() {
  return MockDataGenerator;
}
export const pathUtils = {
  /**
   * Resolve path to implementation file from test file
   * @param {string} testFilePath - Current test file path (__filename)
   * @param {string} implementationPath - Relative path to implementation
   * @returns {string} Absolute path to implementation file
   */
  resolveImplementationPath(testFilePath, implementationPath) {
    const testDir = path.dirname(testFilePath);
    return path.resolve(testDir, implementationPath);
  },

  /**
   * Get common implementation paths from test directory structure
   * @param {string} testFilePath - Current test file path
   * @returns {Object} Common paths object
   */
  getCommonPaths(testFilePath) {
    const testDir = path.dirname(testFilePath);
    const assetsDir = path.resolve(testDir, '..');

    return {
      assets: assetsDir,
      plugins: path.resolve(assetsDir, 'plugins'),
      docsify: path.resolve(assetsDir, 'docsify'),
      utils: path.resolve(assetsDir, 'utils'),
      tests: testDir
    };
  },

  /**
   * Get absolute path synchronously from relative path (from test helpers directory)
   * @param {string} relativePath - Relative path from test helpers directory
   * @returns {string} Absolute path
   */
  getAbsolutePathSync(relativePath) {
    const testDir = new URL('../', import.meta.url).pathname;
    const cleanTestDir = testDir.startsWith('/') && process.platform === 'win32'
      ? testDir.slice(1)
      : testDir;

    return path.resolve(cleanTestDir, relativePath);
  }
};

/**
 * Timer Management Utilities
 */
export const timerUtils = {
  _trackedTimers: new Set(),
  _originalSetTimeout: null,
  _originalSetInterval: null,
  _originalRequestAnimationFrame: null,

  /**
   * Start tracking timers for cleanup
   */
  startTracking() {
    if (this._originalSetTimeout) {return;} // Already tracking

    this._originalSetTimeout = global.setTimeout;
    this._originalSetInterval = global.setInterval;
    this._originalRequestAnimationFrame = global.requestAnimationFrame;

    const trackedTimers = this._trackedTimers;

    global.setTimeout = function(...args) {
      const id = timerUtils._originalSetTimeout.apply(this, args);
      trackedTimers.add({ type: 'timeout', id });
      return id;
    };

    global.setInterval = function(...args) {
      const id = timerUtils._originalSetInterval.apply(this, args);
      trackedTimers.add({ type: 'interval', id });
      return id;
    };

    if (global.requestAnimationFrame) {
      global.requestAnimationFrame = function(...args) {
        const id = timerUtils._originalRequestAnimationFrame.apply(this, args);
        trackedTimers.add({ type: 'raf', id });
        return id;
      };
    }
  },

  /**
   * Clear all tracked timers
   */
  clearAllTimers() {
    this._trackedTimers.forEach(timer => {
      try {
        switch (timer.type) {
          case 'timeout':
            clearTimeout(timer.id);
            break;
          case 'interval':
            clearInterval(timer.id);
            break;
          case 'raf':
            if (global.cancelAnimationFrame) {
              global.cancelAnimationFrame(timer.id);
            }
            break;
        }
      } catch {
        // Ignore cleanup errors
      }
    });
    this._trackedTimers.clear();
  },

  /**
   * Stop tracking and restore original timer functions
   */
  stopTracking() {
    this.clearAllTimers();

    if (this._originalSetTimeout) {
      global.setTimeout = this._originalSetTimeout;
      global.setInterval = this._originalSetInterval;
      if (this._originalRequestAnimationFrame) {
        global.requestAnimationFrame = this._originalRequestAnimationFrame;
      }

      this._originalSetTimeout = null;
      this._originalSetInterval = null;
      this._originalRequestAnimationFrame = null;
    }
  }
};

/**
 * Global utilities for test cleanup and setup
 */
/**
 * Global cleanup utilities
 */
export const globalUtils = {
  /**
   * Cleanup global variables and state
   */
  cleanupGlobals() {
    // Clear any global test state
    if (typeof window !== 'undefined') {
      // Remove test-specific globals
      delete window.testGlobal;
      delete window.testState;

      // Clear any plugin globals that might contaminate tests
      delete window.KataProgressMermaidIntegration;
      delete window.SearchIntegrationManager;
      delete window.NavbarHighlighting;
      delete window.DarkModeManager;

      // Reset location if it was modified - safely handle Happy DOM test environment
      try {
        if (window.location && typeof window.location.hash === 'string' && window.location.hash) {
          window.location.hash = '';
        }
      } catch {
        // Ignore Happy DOM location access errors during cleanup
      }
    }

    // Clear any document modifications - safely handle Happy DOM
    if (typeof document !== 'undefined' && document.querySelectorAll) {
      try {
        // Remove any test elements that might have been added to body
        const testElements = document.querySelectorAll('[data-test], .test-element, .mermaid-diagram');
        testElements.forEach(el => el.remove());

        // Reset document title
        if (document.title) {
          document.title = 'Test Document';
        }

        // Clear any custom CSS that might have been added
        const testStyles = document.querySelectorAll('style[data-test]');
        testStyles.forEach(style => style.remove());
      } catch {
        // Ignore DOM cleanup errors during teardown
      }
    }
  },

  /**
   * Setup clean test environment
   */
  setupCleanEnvironment() {
    this.cleanupGlobals();

    // Ensure clean timer state
    timerUtils.clearAllTimers();

    // Clean up global mock stubs to prevent contamination
    mockUtils.cleanupGlobalMocks();

    // Reset any console modifications
    if (typeof console !== 'undefined' && console.warn.restore) {
      console.warn.restore();
    }
    if (typeof console !== 'undefined' && console.error.restore) {
      console.error.restore();
    }
    if (typeof console !== 'undefined' && console.log.restore) {
      console.log.restore();
    }
  }
};

/**
 * Vitest Mock Utilities
 */
export const mockUtils = {
  /**
   * Global registry to track console mocks across all tests
   */
  _globalConsoleMocks: new Map(),

  /**
   * Safely mock a method, checking if it's already mocked
   * @param {Object} target - Target object
   * @param {string} method - Method name to mock
   * @param {Function} replacement - Optional replacement function
   * @returns {Object} Mock instance or existing mock
   */
  safeMock(target, method, replacement) {
    // Special handling for console methods to prevent cross-test conflicts
    if (target === console && ['log', 'warn', 'error', 'info', 'debug'].includes(method)) {
      const mockKey = `console.${method}`;

      // Check if there's already a global mock for this console method
      if (this._globalConsoleMocks.has(mockKey)) {
        const existingMock = this._globalConsoleMocks.get(mockKey);
        // Return the existing mock if it's still active
        if (existingMock && vi.isMockFunction(existingMock)) {
          return existingMock;
        }
        // Remove stale reference
        this._globalConsoleMocks.delete(mockKey);
      }

      // Create new console mock
      try {
        const mock = replacement ? vi.spyOn(target, method).mockImplementation(replacement) : vi.spyOn(target, method);
        this._globalConsoleMocks.set(mockKey, mock);
        return mock;
      } catch {
        // If mocking fails, try to restore first and retry
        if (vi.isMockFunction(target[method])) {
          try {
            target[method].mockRestore();
            const mock = replacement ? vi.spyOn(target, method).mockImplementation(replacement) : vi.spyOn(target, method);
            this._globalConsoleMocks.set(mockKey, mock);
            return mock;
          } catch {
            // Return a no-op function to prevent test failures
            return vi.fn();
          }
        }
        return vi.fn();
      }
    }

    // Check if method is already mocked
    if (vi.isMockFunction(target[method])) {
      return target[method];
    }

    // Create new mock
    try {
      if (replacement) {
        return vi.spyOn(target, method).mockImplementation(replacement);
      } else {
        return vi.spyOn(target, method);
      }
    } catch (_error) {
      // If mocking fails, return a basic mock
      console.warn('Failed to mock method, creating basic mock:', _error.message);
      return vi.fn();
    }
  },

  /**
   * Safely restore all mocks
   */
  safeRestore() {
    try {
      vi.restoreAllMocks();
    } catch {
      // Ignore restore errors
    }
  },

  /**
   * Clean up global console mock tracking
   */
  cleanupGlobalMocks() {
    // Restore any remaining console mocks
    for (const [_key, mock] of this._globalConsoleMocks.entries()) {
      try {
        if (mock && vi.isMockFunction(mock)) {
          mock.mockRestore();
        }
      } catch {
        // Ignore restore errors
      }
    }
    this._globalConsoleMocks.clear();
  },

  /**
   * Create a safe mock function that handles all edge cases
   * @returns {Object} Enhanced mock function
   */
  createSafeMock() {
    return vi.fn();
  }
};

/**
 * DOM Method Mocking Utilities
 */
export const domMockUtils = {
  /**
   * Safely query all elements with fallback
   * @param {string} selector - CSS selector
   * @param {Document|Element} [root] - Root element to search from
   * @returns {Array} - Matching elements as array
   */
  safeQuerySelectorAll(selector, root) {
    const queryRoot = root || (typeof document !== 'undefined' ? document : null);
    try {
      if (!queryRoot || typeof queryRoot.querySelectorAll !== 'function') {
        return [];
      }
      return Array.from(queryRoot.querySelectorAll(selector));
    } catch {
      return [];
    }
  },

  /**
   * Safely query single element with fallback
   * @param {string} selector - CSS selector
   * @param {Document|Element} [root] - Root element to search from
   * @returns {Element|null} - Matching element
   */
  safeQuerySelector(selector, root) {
    const queryRoot = root || (typeof document !== 'undefined' ? document : null);
    try {
      if (!queryRoot || typeof queryRoot.querySelector !== 'function') {
        return null;
      }
      return queryRoot.querySelector(selector);
    } catch {
      return null;
    }
  },

  /**
   * Clean up elements with safe query
   * @param {string} selector - CSS selector for elements to remove
   * @param {Document|Element} [root] - Root element to search from
   */
  safeCleanupElements(selector, root) {
    try {
      const elements = this.safeQuerySelectorAll(selector, root);
      elements.forEach(el => {
        try {
          if (el && el.parentNode) {
            el.parentNode.removeChild(el);
          }
        } catch {
          // Ignore cleanup errors
        }
      });
    } catch {
      // Ignore cleanup errors
    }
  },

  /**
   * Setup common DOM method mocks for Happy DOM
   * @param {Window} window - Happy DOM window object
   */
  setupCommonMocks(window) {
    const { document: _document } = window;

    // Mock scrollIntoView if not present
    if (!window.Element.prototype.scrollIntoView) {
      window.Element.prototype.scrollIntoView = function(_options) {
        // Mock implementation that does nothing but is callable
        return Promise.resolve();
      };
    }

    // Mock getBoundingClientRect if not present
    if (!window.Element.prototype.getBoundingClientRect) {
      window.Element.prototype.getBoundingClientRect = function() {
        return {
          top: 0,
          left: 0,
          bottom: 0,
          right: 0,
          width: 0,
          height: 0,
          x: 0,
          y: 0
        };
      };
    }

    // Mock getComputedStyle if not present
    if (!window.getComputedStyle) {
      window.getComputedStyle = function(_element) {
        return {
          getPropertyValue: () => '',
          display: 'block',
          visibility: 'visible'
        };
      };
    }

    // Mock localStorage if not present
    if (!window.localStorage) {
      window.localStorage = {
        _data: {},
        getItem(key) { return this._data[key] || null; },
        setItem(key, value) { this._data[key] = String(value); },
        removeItem(key) { delete this._data[key]; },
        clear() { this._data = {}; },
        get length() { return Object.keys(this._data).length; },
        key(_index) { return Object.keys(this._data)[_index] || null; }
      };
    }

    // Mock sessionStorage if not present
    if (!window.sessionStorage) {
      window.sessionStorage = { ...window.localStorage };
    }

    return window;
  },

  /**
   * Create enhanced DOM environment with mocks using Happy DOM
   * @param {string} html - HTML template
   * @param {Object} _options - DOM options (for compatibility, but not used with Happy DOM)
   * @returns {Promise<Object>} Enhanced DOM instance
   */
  async createEnhancedDOM(html = '<!DOCTYPE html><html><body></body></html>', _options = {}) {
    // Use Happy DOM from the global environment instead of JSDOM
    // Reset the document body to the provided HTML
    document.body.innerHTML = html.includes('<body>')
      ? html.match(/<body[^>]*>(.*?)<\/body>/s)?.[1] || ''
      : html;

    this.setupCommonMocks(window);

    // Return a compatible object that mimics test DOM structure
    return {
      window,
      document: window.document
    };
  }
};

/**
 * Event Listener Cleanup Utilities
 */
export const eventUtils = {
  _trackedListeners: new Set(),

  /**
   * Add tracked event listener
   * @param {Element} element - Target element
   * @param {string} event - Event type
   * @param {Function} handler - Event handler
   * @param {Object} options - Event options
   */
  addTrackedListener(element, event, handler, _options) {
    element.addEventListener(event, handler, _options);
    this._trackedListeners.add({ element, event, handler, options: _options });
  },

  /**
   * Remove all tracked event listeners
   */
  removeAllTrackedListeners() {
    this._trackedListeners.forEach(listener => {
      try {
        listener.element.removeEventListener(
          listener.event,
          listener.handler,
          listener.options
        );
      } catch {
        // Ignore cleanup errors
      }
    });
    this._trackedListeners.clear();
  }
};

/**
 * Complete Test Environment Setup
 */
export const testEnvironment = {
  /**
   * Setup complete test environment for a test suite
   * @param {Object} options - Setup options
   * @returns {Promise<Object>} Environment cleanup function and utilities
   */
  async setup(options = {}) {
    const {
      trackTimers = true,
      mockDOMMethods = true,
      isolateGlobals = [],
      domOptions = {}
    } = options;

    // Start timer tracking
    if (trackTimers) {
      timerUtils.startTracking();
    }

    // Save globals for isolation
    if (isolateGlobals.length > 0) {
      globalUtils.saveGlobals(isolateGlobals);
    }

    // Create enhanced DOM environment if needed
    let dom = null;
    if (mockDOMMethods && typeof document === 'undefined') {
      dom = await domMockUtils.createEnhancedDOM(undefined, domOptions);
      global.window = dom.window;
      global.document = dom.window.document;
    }

    // Return cleanup function and utilities
    return {
      dom,
      cleanup: () => this.cleanup(options),
      utils: {
        pathUtils,
        timerUtils,
        globalUtils,
        domMockUtils,
        eventUtils
      }
    };
  },

  /**
   * Complete test environment cleanup
   * @param {Object} options - Original setup options
   */
  cleanup(options = {}) {
    const {
      trackTimers = true,
      isolateGlobals = []
    } = options;

    // Clear all tracked timers
    if (trackTimers) {
      timerUtils.clearAllTimers();
      timerUtils.stopTracking();
    }

    // Remove all tracked event listeners
    eventUtils.removeAllTrackedListeners();

    // Restore isolated globals
    if (isolateGlobals.length > 0) {
      globalUtils.restoreGlobals();
    }

    // Clear DOM globals if we set them
    if (global.window && global.window.close) {
      global.window.close();
      delete global.window;
      delete global.document;
    }
  }
};

// Create instances for direct usage (matching root tests pattern)
export const mockDataGenerator = MockDataGenerator;
export const domUtils = new DOMTestUtils();

// Export mockLocalStorage setup function for compatibility
export function setupMockLocalStorage() {
  const localStorageMock = {
    store: {},
    getItem: vi.fn((key) => localStorageMock.store[key] || null),
    setItem: vi.fn((key, value) => { localStorageMock.store[key] = value; }),
    removeItem: vi.fn((key) => { delete localStorageMock.store[key]; }),
    clear: vi.fn(() => { localStorageMock.store = {}; }),
    length: 0,
    key: vi.fn()
  };

  Object.defineProperty(window, 'localStorage', {
    value: localStorageMock,
    writable: true
  });

  return localStorageMock;
}

/**
 * Generate mock path data for testing learning paths
 * @param {Object} options - Path configuration options
 * @returns {Object} Mock path data object
 */
function generatePathData(options = {}) {
  return {
    id: options.id || `path-${Math.random().toString(36).substr(2, 9)}`,
    title: options.title || 'Test Learning Path',
    description: options.description || 'A test learning path for unit testing',
    pathType: options.pathType || 'beginner',
    difficulty: options.difficulty || 'beginner',
    difficultyColor: options.difficultyColor || '#28a745',
    difficultyIcon: options.difficultyIcon || '🌱',
    completionState: options.completionState || 'not-started',
    progress: options.progress || 0,
    buttonText: options.buttonText || 'Start Path',
    estimatedTime: options.estimatedTime || '2 hours',
    prerequisites: options.prerequisites || [],
    tags: options.tags || ['test', 'learning'],
    steps: options.steps || [
      { id: 'step-1', title: 'Introduction', completed: false },
      { id: 'step-2', title: 'Setup', completed: false }
    ],
    badge: options.badge || null,
    label: options.label || options.title || 'Test Learning Path'
  };
}

// Export all utilities as default
export default {
  pathUtils,
  timerUtils,
  globalUtils,
  mockUtils,
  domMockUtils,
  eventUtils,
  testEnvironment,
  DOMTestUtils,
  MockDataGenerator,
  createMockEnvironment,
  createMockDataGenerator,
  mockDataGenerator,
  domUtils,
  setupMockLocalStorage,
  generatePathData
};

// Also export key utilities as named exports for easier importing
export {
  setupMockLocalStorage,
  generatePathData,
  domUtils
};
