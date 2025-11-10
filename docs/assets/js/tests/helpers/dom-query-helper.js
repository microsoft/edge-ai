/**
 * DOM Query Helper - Reliable DOM element selection and interaction utilities
 *
 * Provides consistent, stable DOM query patterns with proper waiting,
 * retries, and validation for test environments and dynamic content loading.
 */

/**
 * Configuration for DOM query operations
 */
const DOM_QUERY_CONFIG = {
  // Default timeout for waiting operations (ms)
  defaultTimeout: 5000,

  // Poll interval for waiting operations (ms)
  pollInterval: 50,

  // Maximum retry attempts for unstable operations
  maxRetries: 3,

  // Delay between retry attempts (ms)
  retryDelay: 100
};

/**
 * Wait for an element to be available in the DOM with proper timeout handling
 * @param {string|Function} selector - CSS selector string or function that returns element
 * @param {Object} options - Configuration options
 * @param {number} options.timeout - Maximum wait time in milliseconds
 * @param {Document} options.context - Document context (defaults to global document)
 * @param {boolean} options.visible - Whether element should be visible
 * @returns {Promise<Element>} The found element
 * @throws {Error} If element is not found within timeout
 */
export async function waitForElement(selector, options = {}) {
  const {
    timeout = DOM_QUERY_CONFIG.defaultTimeout,
    context = document,
    visible = false
  } = options;

  const startTime = Date.now();

  return new Promise((resolve, reject) => {
    const poll = () => {
      try {
        let element;

        if (typeof selector === 'function') {
          element = selector();
        } else {
          element = context.querySelector(selector);
        }

        if (element) {
          // Check visibility if required
          if (visible) {
            const style = window.getComputedStyle(element);
            const isVisible = style.display !== 'none' &&
                            style.visibility !== 'hidden' &&
                            style.opacity !== '0';

            if (!isVisible) {
              element = null;
            }
          }

          if (element) {
            resolve(element);
            return;
          }
        }

        // Check timeout
        if (Date.now() - startTime >= timeout) {
          reject(new Error(`Element not found: ${selector} (timeout: ${timeout}ms)`));
          return;
        }

        // Continue polling
        setTimeout(poll, DOM_QUERY_CONFIG.pollInterval);
      } catch (_error) {
        reject(_error);
      }
    };

    poll();
  });
}

/**
 * Wait for multiple elements to be available
 * @param {Array<string|Function>} selectors - Array of selectors
 * @param {Object} options - Configuration options
 * @returns {Promise<Array<Element>>} Array of found elements
 */
export async function waitForElements(selectors, options = {}) {
  const promises = selectors.map(selector => waitForElement(selector, options));
  return Promise.all(promises);
}

/**
 * Safely query element with built-in retries and validation
 * @param {string} selector - CSS selector
 * @param {Object} options - Configuration options
 * @param {Document} options.context - Document context
 * @param {boolean} options.required - Whether element is required (throws if not found)
 * @param {number} options.retries - Number of retry attempts
 * @returns {Element|null} The found element or null
 */
export function safeQuerySelector(selector, options = {}) {
  const {
    context = document,
    required = false,
    retries = DOM_QUERY_CONFIG.maxRetries
  } = options;

  let lastError;

  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const element = context.querySelector(selector);

      if (element || !required) {
        return element;
      }

      lastError = new Error(`Required element not found: ${selector}`);

      // Wait before retry (except on last attempt)
      if (attempt < retries) {
        // Synchronous delay for retry
        const start = Date.now();
        while (Date.now() - start < DOM_QUERY_CONFIG.retryDelay) {
          // Busy wait for short delay
        }
      }
    } catch (_error) {
      lastError = _error;

      if (attempt < retries) {
        // Wait before retry
        const start = Date.now();
        while (Date.now() - start < DOM_QUERY_CONFIG.retryDelay) {
          // Busy wait for short delay
        }
      }
    }
  }

  if (required) {
    throw lastError || new Error(`Element not found after ${retries} retries: ${selector}`);
  }

  return null;
}

/**
 * Query all elements with built-in validation
 * @param {string} selector - CSS selector
 * @param {Object} options - Configuration options
 * @returns {NodeList|Array} Found elements
 */
export function safeQuerySelectorAll(selector, options = {}) {
  const {
    context = document,
    minCount = 0,
    maxCount = Infinity,
    throwOnError = true
  } = options;

  try {
    const elements = context.querySelectorAll(selector);

    if (elements.length < minCount) {
      const _error = new Error(`Expected at least ${minCount} elements for ${selector}, found ${elements.length}`);
      if (throwOnError) {
        throw _error;
      } else {
        console.warn(`Query error for selector ${selector}:`, _error);
        return [];
      }
    }

    if (elements.length > maxCount) {
      const _error = new Error(`Expected at most ${maxCount} elements for ${selector}, found ${elements.length}`);
      if (throwOnError) {
        throw _error;
      } else {
        console.warn(`Query error for selector ${selector}:`, _error);
        return [];
      }
    }

    return elements;
  } catch (_error) {
    if (throwOnError && (_error.message.includes('Expected at least') || _error.message.includes('Expected at most'))) {
      throw _error;
    }
    console.warn(`Query error for selector ${selector}:`, _error);
    return [];
  }
}

/**
 * Wait for Docsify content to be loaded and ready
 * @param {Object} options - Configuration options
 * @returns {Promise<void>}
 */
export async function waitForDocsifyReady(options = {}) {
  const { timeout = DOM_QUERY_CONFIG.defaultTimeout } = options;

  // Wait for Docsify to initialize
  await waitForElement(() => {
    return window.$docsify || document.querySelector('.app-nav, .sidebar, .content');
  }, { timeout });

  // Wait for initial content load
  await waitForElement('.markdown-section, .content > *', { timeout });

  // Additional wait for any dynamic content
  return new Promise(resolve => {
    setTimeout(resolve, 100);
  });
}

/**
 * Wait for learning path components to be loaded
 * @param {Object} options - Configuration options
 * @returns {Promise<Element>} The learning paths container
 */
export async function waitForLearningPathsReady(options = {}) {
  const { timeout = DOM_QUERY_CONFIG.defaultTimeout } = options;

  // Wait for learning paths container
  const container = await waitForElement('#learning-paths-container, .learning-paths-container', { timeout });

  // Wait for at least one learning path to be present
  await waitForElement('.learning-path, [data-path-id]', { timeout, context: container });

  return container;
}

/**
 * Safely interact with an element (click, focus, etc.)
 * @param {Element|string} elementOrSelector - Element or selector
 * @param {string} action - Action to perform ('click', 'focus', 'blur')
 * @param {Object} options - Configuration options
 * @returns {Promise<boolean>} Success status
 */
export async function safeInteract(elementOrSelector, action, options = {}) {
  const { timeout = 1000, retries = DOM_QUERY_CONFIG.maxRetries } = options;

  let element;

  if (typeof elementOrSelector === 'string') {
    element = await waitForElement(elementOrSelector, { timeout });
  } else {
    element = elementOrSelector;
  }

  if (!element) {
    throw new Error(`Cannot interact with element: ${elementOrSelector}`);
  }

  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      switch (action) {
        case 'click':
          element.click();
          break;
        case 'focus':
          element.focus();
          break;
        case 'blur':
          element.blur();
          break;
        default:
          throw new Error(`Unknown action: ${action}`);
      }

      return true;
    } catch (_error) {
      if (attempt === retries) {
        throw _error;
      }

      // Wait before retry
      await new Promise(resolve => setTimeout(resolve, DOM_QUERY_CONFIG.retryDelay));
    }
  }

  return false;
}

/**
 * Get element text content with proper normalization
 * @param {Element|string} elementOrSelector - Element or selector
 * @param {Object} options - Configuration options
 * @returns {string} Normalized text content
 */
export function getElementText(elementOrSelector, options = {}) {
  const { normalize = true, trim = true } = options;

  let element;

  if (typeof elementOrSelector === 'string') {
    element = safeQuerySelector(elementOrSelector, { required: true });
  } else {
    element = elementOrSelector;
  }

  if (!element) {
    return '';
  }

  let text = element.textContent || '';

  if (normalize) {
    // Normalize whitespace
    text = text.replace(/\s+/g, ' ');
  }

  if (trim) {
    text = text.trim();
  }

  return text;
}

/**
 * Check if element is visible and interactable
 * @param {Element|string} elementOrSelector - Element or selector
 * @returns {boolean} Whether element is visible and interactable
 */
export function isElementVisible(elementOrSelector) {
  let element;

  if (typeof elementOrSelector === 'string') {
    element = safeQuerySelector(elementOrSelector);
  } else {
    element = elementOrSelector;
  }

  if (!element) {
    return false;
  }

  // Check if element is in the DOM
  if (!document.contains(element)) {
    return false;
  }

  // In Happy DOM, focus on inline styles which are more reliable
  if (element.style.display === 'none' ||
      element.style.visibility === 'hidden' ||
      element.style.opacity === '0') {
    return false;
  }

  // Simple visibility check for Happy DOM - if element exists and isn't explicitly hidden, consider it visible
  // This is sufficient for a documentation site testing environment
  return true;
}/**
 * Cleanup function to reset DOM query helper state
 */
export function cleanupDOMQueryHelper() {
  // Clear any cached references or state
  // Currently no persistent state to clean

  // Could be extended to clear element caches, observers, etc.
}

export default {
  waitForElement,
  waitForElements,
  safeQuerySelector,
  safeQuerySelectorAll,
  waitForDocsifyReady,
  waitForLearningPathsReady,
  safeInteract,
  getElementText,
  isElementVisible,
  cleanupDOMQueryHelper,
  DOM_QUERY_CONFIG
};
