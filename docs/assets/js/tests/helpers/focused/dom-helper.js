/**
 * Focused DOM Element Helper
 * Lightweight DOM creation without full overhead
 *
 * @description Provides targeted DOM structure creation on demand
 * - Creates specific DOM structures as needed
 * - Minimal test environment overhead
 * - Clean, efficient teardown
 * - Memory efficient implementation
 * @version 1.0.0
 */

/**
 * Create a lightweight DOM helper with focused functionality
 * @param {Object} options - Configuration options
 * @param {boolean} options.autoCleanup - Whether to auto-track elements for cleanup
 * @returns {Object} Object containing DOM utilities and cleanup function
 */
export function createDOMHelper(options = {}) {
  // Use global document from Vitest's happy-dom environment
  // Ensure we have a valid document object
  let doc;
  if (typeof globalThis !== 'undefined' && globalThis.document) {
    doc = globalThis.document;
  } else if (typeof document !== 'undefined') {
    doc = document;
  } else {
    throw new Error('DOM environment not available. Ensure happy-dom is properly configured in vitest.config.js');
  }

  // Ensure createElement is available
  if (!doc.createElement) {
    throw new Error('Document object does not have createElement method');
  }

  const { autoCleanup = true } = options;
  const trackedElements = new Set();

  /**
   * Create a test container element
   * @param {Object} config - Container configuration
   * @param {string} config.id - Container ID
   * @param {string} config.className - Container CSS classes
   * @param {string} config.innerHTML - Initial HTML content
   * @returns {HTMLElement} Created container element
   */
  function createContainer({ id = null, className = 'test-container', innerHTML = '' } = {}) {
    const container = doc.createElement('div');

    if (id) {
      container.id = id;
    }

    if (className) {
      container.className = className;
    }

    if (innerHTML) {
      container.innerHTML = innerHTML;
    }

    // Track for cleanup if auto-tracking is enabled
    if (autoCleanup) {
      trackedElements.add(container);
    }

    // Add to DOM if available
    if (doc.body) {
      doc.body.appendChild(container);
    }

    return container;
  }

  /**
   * Create a simple element with attributes
   * @param {string} tagName - Element tag name
   * @param {Object} attributes - Element attributes
   * @param {string} textContent - Element text content
   * @returns {HTMLElement} Created element
   */
  function createElement(tagName, attributes = {}, textContent = '') {
    const element = doc.createElement(tagName);

    // Set attributes
    Object.entries(attributes).forEach(([key, value]) => {
      if (key === 'className') {
        element.className = value;
      } else if (key === 'innerHTML') {
        element.innerHTML = value;
      } else {
        element.setAttribute(key, value);
      }
    });

    // Set text content if provided
    if (textContent) {
      element.textContent = textContent;
    }

    // Track for cleanup if auto-tracking is enabled
    if (autoCleanup) {
      trackedElements.add(element);
    }

    return element;
  }

  /**
   * Create a form with specified fields
   * @param {Array} fields - Array of field configurations
   * @param {Object} formAttributes - Form element attributes
   * @returns {HTMLElement} Created form element
   */
  function createForm(fields = [], formAttributes = {}) {
    const form = createElement('form', formAttributes);

    fields.forEach(field => {
      const fieldContainer = createElement('div', { className: 'field-container' });

      // Create label if specified
      if (field.label) {
        const label = createElement('label', {
          for: field.id || field.name
        }, field.label);
        fieldContainer.appendChild(label);
      }

      // Create input element
      const input = createElement('input', {
        type: field.type || 'text',
        id: field.id || field.name,
        name: field.name,
        ...(field.required && { required: true }),
        ...(field.value && { value: field.value }),
        ...(field.placeholder && { placeholder: field.placeholder })
      });

      fieldContainer.appendChild(input);
      form.appendChild(fieldContainer);
    });

    return form;
  }

  /**
   * Create a list of checkboxes
   * @param {Array} checkboxes - Array of checkbox configurations
   * @param {Object} containerAttributes - Container attributes
   * @returns {HTMLElement} Container with checkboxes
   */
  function createCheckboxList(checkboxes = [], containerAttributes = {}) {
    const container = createElement('div', {
      className: 'checkbox-list',
      ...containerAttributes
    });

    checkboxes.forEach(checkbox => {
      const checkboxContainer = createElement('div', { className: 'checkbox-item' });

      const input = createElement('input', {
        type: 'checkbox',
        id: checkbox.id,
        name: checkbox.name || checkbox.id,
        value: checkbox.value || checkbox.id,
        ...(checkbox.checked && { checked: true }),
        ...(checkbox.disabled && { disabled: true }),
        ...(checkbox.dataAttributes && checkbox.dataAttributes)
      });

      const label = createElement('label', {
        for: checkbox.id
      }, checkbox.label || checkbox.id);

      checkboxContainer.appendChild(input);
      checkboxContainer.appendChild(label);
      container.appendChild(checkboxContainer);
    });

    return container;
  }

  /**
   * Create a navigation structure
   * @param {Array} navItems - Array of navigation item configurations
   * @param {Object} navAttributes - Navigation element attributes
   * @returns {HTMLElement} Created navigation element
   */
  function createNavigation(navItems = [], navAttributes = {}) {
    const nav = createElement('nav', {
      className: 'test-navigation',
      ...navAttributes
    });

    const ul = createElement('ul', { className: 'nav-list' });

    navItems.forEach(item => {
      const li = createElement('li', { className: 'nav-item' });
      const a = createElement('a', {
        href: item.href || '#',
        className: item.className || 'nav-link',
        ...(item.id && { id: item.id })
      }, item.text || item.label);

      li.appendChild(a);
      ul.appendChild(li);
    });

    nav.appendChild(ul);
    return nav;
  }

  /**
   * Query elements safely with fallback
   * @param {string} selector - CSS selector
   * @param {Element} root - Root element to search from
   * @returns {Element|null} Found element or null
   */
  function querySelector(selector, root = document) {
    try {
      return root.querySelector(selector);
    } catch {
      return null;
    }
  }

  /**
   * Query multiple elements safely with fallback
   * @param {string} selector - CSS selector
   * @param {Element} root - Root element to search from
   * @returns {Array} Array of found elements
   */
  function querySelectorAll(selector, root = document) {
    try {
      return Array.from(root.querySelectorAll(selector));
    } catch {
      return [];
    }
  }

  /**
   * Remove a specific element
   * @param {HTMLElement} element - Element to remove
   */
  function removeElement(element) {
    if (element && element.parentNode) {
      element.parentNode.removeChild(element);
      trackedElements.delete(element);
    }
  }

  /**
   * Cleanup function that removes all tracked elements
   */
  function cleanup() {
    // Remove all tracked elements
    trackedElements.forEach(element => {
      try {
        if (element && element.parentNode) {
          element.parentNode.removeChild(element);
        }
      } catch {
        // Ignore cleanup errors
      }
    });

    // Clear tracking
    trackedElements.clear();
  }

  // Return only essential DOM utilities - no bloat
  return {
    createContainer,
    createElement,
    createForm,
    createCheckboxList,
    createNavigation,
    querySelector,
    querySelectorAll,
    removeElement,
    cleanup
  };
}

/**
 * Create a minimal DOM helper without auto-tracking
 * For tests that need minimal overhead
 * @returns {Object} Object containing basic DOM utilities
 */
export function createBasicDOMHelper() {
  return createDOMHelper({ autoCleanup: false });
}

export default createDOMHelper;
