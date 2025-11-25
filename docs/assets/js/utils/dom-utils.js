/**
 * DOM Utilities - Unified Implementation
 * Consolidated from dom-utils.js and dom-utils-clean.js
 * Provides comprehensive DOM operations with robust error handling
 * Version: 3.0.0 - Unified
 */

/**
 * Unified DOM manipulation utilities
 * Combines best practices from both implementations with enhanced error handling
 * Features: Browser compatibility, SSR support, comprehensive method coverage
 */
export class DOMUtils {
  constructor(errorHandler) {
    // Use simple fallback to avoid circular dependencies during initialization
    this.errorHandler = errorHandler || {
      safeExecute: (fn, name, fallback) => {
        try {
          return fn();
        } catch {
          // Error in DOM operation - logging disabled for production
          return fallback;
        }
      }
    };
  }

  /**
   * Safely query a single element
   * @param {string} selector - CSS selector
   * @param {Element} container - Container element (default: document)
   * @returns {Element|null} Found element or null
   */
  querySelector(selector, container = null) {
    try {
      return this.errorHandler.safeExecute(() => {
        // Use provided container or fallback to global document
        const queryContainer = container || (typeof document !== 'undefined' ? document : null);
        if (!queryContainer || !queryContainer.querySelector) {
          return null;
        }
        return queryContainer.querySelector(selector);
      }, 'querySelector', null);
    } catch {
      // Handle case where error handler itself fails - logging disabled for production
      return null;
    }
  }

  /**
   * Safely query multiple elements
   * @param {string} selector - CSS selector
   * @param {Element} container - Container element (default: document)
   * @returns {NodeList|Array} Found elements or empty array
   */
  querySelectorAll(selector, container = null) {
    try {
      return this.errorHandler.safeExecute(() => {
        // Use provided container or fallback to global document
        const queryContainer = container || (typeof document !== 'undefined' ? document : null);
        if (!queryContainer || !queryContainer.querySelectorAll) {
          return [];
        }
        // Return as Array for consistency with clean implementation
        return Array.from(queryContainer.querySelectorAll(selector));
      }, 'querySelectorAll', []);
    } catch {
      // Handle case where error handler itself fails - logging disabled for production
      return [];
    }
  }

  /**
   * Create element with attributes and content
   * @param {string} tagName - HTML tag name
   * @param {Object} attributes - Element attributes
   * @param {string|Element} content - Element content
   * @returns {Element|null} Created element or null
   */
  createElement(tagName, attributes = {}, content = '') {
    return this.errorHandler.safeExecute(() => {
      // Browser compatibility check
      if (typeof document === 'undefined' || !document.createElement) {
        return null;
      }

      const element = document.createElement(tagName);

      // Set attributes
      for (const [key, value] of Object.entries(attributes)) {
        if (key === 'className') {
          element.className = value;
        } else {
          element.setAttribute(key, value);
        }
      }

      // Set content
      if (typeof content === 'string') {
        element.textContent = content;
      } else if (content instanceof Element) {
        element.appendChild(content);
      } else if (Array.isArray(content)) {
        content.forEach(child => {
          if (typeof child === 'string') {
            element.appendChild(document.createTextNode(child));
          } else if (child instanceof Element) {
            element.appendChild(child);
          }
        });
      }

      return element;
    }, 'createElement', null);
  }

  /**
   * Add event listener with safe error handling
   * @param {Element} element - Target element
   * @param {string} event - Event type
   * @param {Function} handler - Event handler function
   * @param {Object} options - Event listener options
   * @returns {boolean} Success status
   */
  addEventListener(element, event, handler, options = {}) {
    return this.errorHandler.safeExecute(() => {
      if (!element || typeof handler !== 'function') {
        return false;
      }

      // Wrap handler with error handling
      const safeHandler = (e) => {
        try {
          return handler(e);
        } catch {
          // Event handler error - logging disabled for production
        }
      };

      element.addEventListener(event, safeHandler, options);

      // Store reference to original handler for removal if needed
      if (!element._eventHandlers) {
        element._eventHandlers = new Map();
      }
      element._eventHandlers.set(handler, safeHandler);

      return true;
    }, 'addEventListener', false);
  }

  /**
   * Insert HTML content at specified position
   * @param {Element} element - Target element
   * @param {string} position - Position for insertion
   * @param {string} html - HTML content to insert
   * @returns {boolean} Success status
   */
  insertHTML(element, position, html) {
    return this.errorHandler.safeExecute(() => {
      if (!element || typeof html !== 'string') {
        return false;
      }

      const validPositions = ['beforebegin', 'afterbegin', 'beforeend', 'afterend'];
      if (!validPositions.includes(position)) {
        position = 'beforeend'; // Default fallback
      }

      element.insertAdjacentHTML(position, html);
      return true;
    }, 'insertHTML', false);
  }

  /**
   * Safely remove element from DOM
   * @param {Element} element - Element to remove
   * @returns {boolean} Success status
   */
  removeElement(element) {
    return this.errorHandler.safeExecute(() => {
      if (element && element.parentNode) {
        element.parentNode.removeChild(element);

        // Clean up stored event handlers
        if (element._eventHandlers) {
          element._eventHandlers.clear();
        }

        return true;
      }
      return false;
    }, 'removeElement', false);
  }

  /**
   * Get element's bounding rectangle with enhanced data
   * @param {Element} element - Target element
   * @returns {Object|null} Bounding rectangle data or null
   */
  getElementBounds(element) {
    return this.errorHandler.safeExecute(() => {
      if (!element) {return null;}

      const rect = element.getBoundingClientRect();

      // Enhanced bounds data
      return {
        ...rect,
        // Add computed styles that affect positioning
        isVisible: rect.width > 0 && rect.height > 0,
        inViewport: rect.top < window.innerHeight && rect.bottom > 0 &&
                   rect.left < window.innerWidth && rect.right > 0
      };
    }, 'getElementBounds', null);
  }

  /**
   * Check if element is visible (enhanced visibility detection)
   * @param {Element} element - Element to check
   * @returns {boolean} Visibility status
   */
  isElementVisible(element) {
    return this.errorHandler.safeExecute(() => {
      if (!element) {return false;}

      // Check multiple visibility factors
      const style = window.getComputedStyle(element);
      const rect = element.getBoundingClientRect();

      return (
        style.display !== 'none' &&
        style.visibility !== 'hidden' &&
        style.opacity !== '0' &&
        rect.width > 0 &&
        rect.height > 0 &&
        element.offsetParent !== null
      );
    }, 'isElementVisible', false);
  }

  /**
   * Scroll element into view with enhanced options
   * @param {Element} element - Element to scroll to
   * @param {Object} options - Scroll options
   * @returns {Promise<boolean>} Scroll completion promise
   */
  async scrollToElement(element, options = {}) {
    return this.errorHandler.safeExecute(async () => {
      if (!element) {return false;}

      const defaultOptions = {
        behavior: 'smooth',
        block: 'center',
        inline: 'nearest',
        offset: 0
      };

      const scrollOptions = { ...defaultOptions, ...options };

      // Apply offset if specified
      if (scrollOptions.offset !== 0) {
        const rect = element.getBoundingClientRect();
        const offsetTop = window.pageYOffset + rect.top + scrollOptions.offset;

        window.scrollTo({
          top: offsetTop,
          behavior: scrollOptions.behavior
        });
      } else {
        element.scrollIntoView({
          behavior: scrollOptions.behavior,
          block: scrollOptions.block,
          inline: scrollOptions.inline
        });
      }

      return true;
    }, 'scrollToElement', false);
  }

  /**
   * Add CSS class to element
   * @param {Element} element - Target element
   * @param {string} className - Class name to add
   * @returns {boolean} Success status
   */
  addClass(element, className) {
    return this.errorHandler.safeExecute(() => {
      if (element && className) {
        element.classList.add(className);
        return true;
      }
      return false;
    }, 'addClass', false);
  }

  /**
   * Remove CSS class from element
   * @param {Element} element - Target element
   * @param {string} className - Class name to remove
   * @returns {boolean} Success status
   */
  removeClass(element, className) {
    return this.errorHandler.safeExecute(() => {
      if (element && className) {
        element.classList.remove(className);
        return true;
      }
      return false;
    }, 'removeClass', false);
  }

  /**
   * Toggle CSS class on element
   * @param {Element} element - Target element
   * @param {string} className - Class name to toggle
   * @returns {boolean} New class state
   */
  toggleClass(element, className) {
    return this.errorHandler.safeExecute(() => {
      if (element && className) {
        return element.classList.toggle(className);
      }
      return false;
    }, 'toggleClass', false);
  }

  /**
   * Check if element has specific class
   * @param {Element} element - Target element
   * @param {string} className - Class name to check
   * @returns {boolean} Class presence status
   */
  hasClass(element, className) {
    return this.errorHandler.safeExecute(() => {
      if (element && className) {
        return element.classList.contains(className);
      }
      return false;
    }, 'hasClass', false);
  }

  /**
   * Set element styles
   * @param {Element} element - Target element
   * @param {Object} styles - Style properties
   * @returns {boolean} Success status
   */
  setStyles(element, styles) {
    return this.errorHandler.safeExecute(() => {
      if (!element || typeof styles !== 'object') {
        return false;
      }

      for (const [property, value] of Object.entries(styles)) {
        element.style[property] = value;
      }

      return true;
    }, 'setStyles', false);
  }

  /**
   * Get computed style property
   * @param {Element} element - Target element
   * @param {string} property - CSS property name
   * @returns {string|null} Property value or null
   */
  getStyle(element, property) {
    return this.errorHandler.safeExecute(() => {
      if (!element || !property) {return null;}

      const computed = window.getComputedStyle(element);
      return computed.getPropertyValue(property);
    }, 'getStyle', null);
  }
}
