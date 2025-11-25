/**
 * DOM Testing Utilities for Markdown Interaction
 * Provides helper functions for testing DOM manipulation within markdown context
 *
 * @module DOMHelpers
 * @author Edge AI Team
 * @version 1.0.0
 */

import { vi } from 'vitest';

/**
 * Create mock DOM utilities for testing
 * @returns {Object} Mock DOM utilities object
 */
export function createMockDomUtils() {
  return {
    querySelector: vi.fn((selector) => {
      return document.querySelector(selector);
    }),

    querySelectorAll: vi.fn((selector) => {
      return Array.from(document.querySelectorAll(selector));
    }),

    createElement: vi.fn((tagName) => {
      return document.createElement(tagName);
    }),

    addEventListener: vi.fn((element, event, handler, _options) => {
      if (element && element.addEventListener) {
        element.addEventListener(event, handler, _options);
      }
    }),

    removeEventListener: vi.fn((element, event, handler, _options) => {
      if (element && element.removeEventListener) {
        element.removeEventListener(event, handler, _options);
      }
    }),

    setAttribute: vi.fn((element, name, value) => {
      if (element && element.setAttribute) {
        element.setAttribute(name, value);
      }
    }),

    getAttribute: vi.fn((element, name) => {
      return element && element.getAttribute ? element.getAttribute(name) : null;
    }),

    addClass: vi.fn((element, className) => {
      if (element && element.classList) {
        element.classList.add(className);
      }
    }),

    removeClass: vi.fn((element, className) => {
      if (element && element.classList) {
        element.classList.remove(className);
      }
    }),

    hasClass: vi.fn((element, className) => {
      return element && element.classList ? element.classList.contains(className) : false;
    }),

    toggleClass: vi.fn((element, className) => {
      if (element && element.classList) {
        element.classList.toggle(className);
      }
    })
  };
}

/**
 * Create mock learning path checkbox structure
 * @param {Array} paths - Array of path objects
 * @returns {string} HTML string for testing
 */
export function createMockLearningPathHTML(paths = []) {
  if (paths.length === 0) {
    paths = [
      {
        title: 'Foundation Builder - AI Engineering',
        items: [
          { id: 'ai-dev-fundamentals', kataId: 'ai-assisted-engineering/01-ai-development-fundamentals', label: 'AI Development Fundamentals' },
          { id: 'prompt-basics', kataId: 'prompt-engineering/01-prompt-engineering-basics', label: 'Prompt Engineering Basics' }
        ]
      },
      {
        title: 'Foundation Builder - Project Planning',
        items: [
          { id: 'basic-planning', kataId: 'project-planning/01-basic-prompt-usage', label: 'Basic Project Planning' }
        ]
      }
    ];
  }

  return `
    <div class="learning-paths-container">
      ${paths.map(path => `
        <h4>${path.title}</h4>
        <ul class="task-list">
          ${path.items.map(item => `
            <li class="task-list-item">
              <input type="checkbox" id="task-${item.id}" data-kata-id="${item.kataId}">
              <label for="task-${item.id}">${item.label}</label>
            </li>
          `).join('')}
        </ul>
      `).join('')}
    </div>
  `;
}

/**
 * Create mock checkbox element for testing
 * @param {string} id - Checkbox ID
 * @param {string} kataId - Associated kata ID
 * @param {boolean} checked - Initial checked state
 * @returns {HTMLInputElement} Mock checkbox element
 */
export function createMockCheckbox(id, kataId, checked = false) {
  const checkbox = document.createElement('input');
  checkbox.type = 'checkbox';
  checkbox.id = id;
  checkbox.setAttribute('data-kata-id', kataId);
  checkbox.checked = checked;

  return checkbox;
}

/**
 * Setup DOM environment for learning path testing
 * @param {string} html - Optional custom HTML
 * @returns {Object} Test environment object
 */
export function setupTestEnvironment(html = null) {
  // Clean up any existing content
  document.body.innerHTML = '';

  // Set up HTML structure
  const testHTML = html || createMockLearningPathHTML();
  document.body.innerHTML = testHTML;

  return {
    container: document.querySelector('.learning-paths-container'),
    checkboxes: Array.from(document.querySelectorAll('input[type="checkbox"]')),
    taskLists: Array.from(document.querySelectorAll('.task-list')),
    headings: Array.from(document.querySelectorAll('h4'))
  };
}

/**
 * Simulate checkbox interaction
 * @param {HTMLInputElement} checkbox - Checkbox element
 * @param {boolean} checked - Target checked state
 */
export function simulateCheckboxClick(checkbox, checked) {
  checkbox.checked = checked;
  checkbox.dispatchEvent(new Event('change', { bubbles: true }));
}

/**
 * Simulate multiple checkbox interactions
 * @param {Array} interactions - Array of {checkbox, checked} objects
 */
export function simulateMultipleClicks(interactions) {
  interactions.forEach(({ checkbox, checked }) => {
    simulateCheckboxClick(checkbox, checked);
  });
}

/**
 * Wait for DOM updates to complete
 * @returns {Promise} Promise that resolves after DOM updates
 */
export function waitForDOMUpdate() {
  return new Promise(resolve => setTimeout(resolve, 0));
}

/**
 * Assert markdown structure preservation
 * @param {Object} originalStructure - Original DOM structure counts
 * @param {Object} currentStructure - Current DOM structure counts
 */
export function assertMarkdownPreservation(originalStructure, currentStructure) {
  expect(currentStructure.taskLists).toBe(originalStructure.taskLists);
  expect(currentStructure.headings).toBe(originalStructure.headings);
  expect(currentStructure.checkboxes).toBe(originalStructure.checkboxes);
}

/**
 * Get current DOM structure counts
 * @returns {Object} Structure counts object
 */
export function getDOMStructureCounts() {
  return {
    taskLists: document.querySelectorAll('.task-list').length,
    headings: document.querySelectorAll('h4').length,
    checkboxes: document.querySelectorAll('input[type="checkbox"]').length
  };
}

/**
 * Clean up test environment
 */
export function cleanupTestEnvironment() {
  document.body.innerHTML = '';
  vi.clearAllMocks();
}
