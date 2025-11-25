/**
 * DOM fixture management utility
 */
import { createEnhancedLocalStorage } from './browser-mocks.js';

export class DOMFixtures {
  constructor() {
    this.fixtures = new Map();
    this.containers = new Set();
  }

  /**
   * Create a test container element
   * @param {string} [id] - Container ID
   * @param {string} [className] - Container CSS class
   * @returns {HTMLElement} Container element
   */
  createContainer(id = null, className = 'test-container') {
    const container = document.createElement('div');

    if (id) {
      container.id = id;
    }

    if (className) {
      container.className = className;
    }

    // Track containers for cleanup
    this.containers.add(container);

    // Add to DOM if we're in browser environment
    if (document.body) {
      document.body.appendChild(container);
    }

    return container;
  }

  /**
   * Create progress bar HTML fixture
   * @param {Object} [options={}] - Configuration options
   * @param {string} [options.progressId='test-progress'] - Progress bar ID
   * @param {Array} [options.tasks=[]] - Array of task objects
   * @param {number} [options.completedTasks=0] - Number of completed tasks
   * @returns {HTMLElement} Container with progress bar HTML
   */
  createProgressBarFixture(options = {}) {
    const {
      progressId = 'test-progress',
      tasks = [
        { id: 'task-1', label: 'Task 1', completed: true },
        { id: 'task-2', label: 'Task 2', completed: false },
        { id: 'task-3', label: 'Task 3', completed: false }
      ],
      completedTasks = tasks.filter(t => t.completed).length
    } = options;

    const container = this.createContainer(`${progressId}-container`);

    // Create progress bar structure
    const progressHTML = `
      <div class="progress-container" data-progress-id="${progressId}">
        <div class="progress-header">
          <span class="progress-title">Progress Tracker</span>
          <span class="progress-text">${completedTasks} of ${tasks.length} completed</span>
        </div>
        <div class="progress-bar">
          <div class="progress-fill" style="width: ${Math.round((completedTasks / tasks.length) * 100)}%"></div>
        </div>
      </div>
      <div class="tasks-container">
        ${tasks.map(task => `
          <div class="task-item">
            <input type="checkbox" id="${task.id}" ${task.completed ? 'checked' : ''}>
            <label for="${task.id}">${task.label}</label>
          </div>
        `).join('')}
      </div>
    `;

    container.innerHTML = progressHTML;

    // Store fixture for reference
    this.fixtures.set(progressId, {
      container,
      progressId,
      tasks,
      completedTasks
    });

    return container;
  }

  /**
   * Create category selector fixture with checkboxes for categories and learning items
   * @param {string} [containerId='category-selector'] - Container ID
   * @param {Array} [categories=['adr-creation', 'prompt-engineering']] - Categories to create
   * @returns {Object} Fixture object with container and helper methods
   */
  createCategorySelectorFixture(containerId = 'category-selector', categories = ['adr-creation', 'prompt-engineering']) {
    const container = this.createContainer(containerId, 'category-selector-fixture');

    // Create category checkboxes and learning items
    const html = categories.map(category => `
      <div class="category-section" data-category="${category}">
        <div class="category-header">
          <input type="checkbox"
                 id="category-${category}"
                 class="category-checkbox"
                 data-category="${category}">
          <label for="category-${category}">${category.replace('-', ' ').toUpperCase()}</label>
        </div>
        <ul class="learning-items">
          <li class="learning-item" data-category="${category}">
            <input type="checkbox" id="item-${category}-1" class="learning-checkbox">
            <a href="/learning/${category}/item-1">Learning Item 1</a>
          </li>
          <li class="learning-item" data-category="${category}">
            <input type="checkbox" id="item-${category}-2" class="learning-checkbox">
            <a href="/learning/${category}/item-2">Learning Item 2</a>
          </li>
          <li class="learning-item" data-category="${category}">
            <input type="checkbox" id="item-${category}-3" class="learning-checkbox">
            <a href="/learning/${category}/item-3">Learning Item 3</a>
          </li>
        </ul>
      </div>
    `).join('');

    container.innerHTML = html;

    // Create fixture object with helper methods
    const fixture = {
      container,
      categories,

      getCategoryCheckbox(category) {
        return container.querySelector(`[data-category="${category}"].category-checkbox`);
      },

      getLearningItems(category) {
        return Array.from(container.querySelectorAll(`li.learning-item[data-category="${category}"]`));
      },

      getLearningCheckboxes(category) {
        return Array.from(container.querySelectorAll(`li.learning-item[data-category="${category}"] input[type="checkbox"]`));
      },

      getAllCategoryCheckboxes() {
        return Array.from(container.querySelectorAll('.category-checkbox'));
      },

      getAllLearningCheckboxes() {
        return Array.from(container.querySelectorAll('.learning-checkbox'));
      }
    };

    this.fixtures.set(containerId, fixture);

    return fixture;
  }

  /**
   * Create checkbox list fixture
   * @param {Array} checkboxes - Array of checkbox configurations
   * @param {string} [containerId] - Container ID
   * @returns {HTMLElement} Container with checkboxes
   */
  createCheckboxListFixture(checkboxes, containerId = null) {
    const container = this.createContainer(containerId, 'checkbox-list-container');

    const checkboxHTML = checkboxes.map(checkbox => `
      <div class="checkbox-item">
        <input type="checkbox"
               id="${checkbox.id}"
               ${checkbox.checked ? 'checked' : ''}
               ${checkbox.disabled ? 'disabled' : ''}
               data-group="${checkbox.group || ''}"
               data-value="${checkbox.value || checkbox.id}">
        <label for="${checkbox.id}">${checkbox.label}</label>
      </div>
    `).join('');

    container.innerHTML = checkboxHTML;

    return container;
  }

  /**
   * Create form fixture with various input types
   * @param {Object} [options={}] - Form configuration
   * @returns {HTMLElement} Form element
   */
  createFormFixture(options = {}) {
    const {
      formId = 'test-form',
      fields = [
        { type: 'text', name: 'username', label: 'Username', required: true },
        { type: 'email', name: 'email', label: 'Email', required: true },
        { type: 'password', name: 'password', label: 'Password', required: true }
      ]
    } = options;

    const container = this.createContainer();
    const form = document.createElement('form');

    form.id = formId;
    form.className = 'test-form';

    const fieldsHTML = fields.map(field => {
      const fieldId = `${formId}-${field.name}`;
      return `
        <div class="form-field">
          <label for="${fieldId}">${field.label}</label>
          <input type="${field.type}"
                 id="${fieldId}"
                 name="${field.name}"
                 ${field.required ? 'required' : ''}
                 ${field.placeholder ? `placeholder="${field.placeholder}"` : ''}>
        </div>
      `;
    }).join('');

    form.innerHTML = `${fieldsHTML }<button type="submit">Submit</button>`;
    container.appendChild(form);

    return container;
  }

  /**
   * Create modal dialog fixture
   * @param {Object} [options={}] - Modal configuration
   * @returns {HTMLElement} Modal element
   */
  createModalFixture(options = {}) {
    const {
      modalId = 'test-modal',
      title = 'Test Modal',
      content = 'This is test content',
      hasCloseButton = true,
      hasActionButtons = true
    } = options;

    const container = this.createContainer();

    const modalHTML = `
      <div class="modal" id="${modalId}" style="display: none;">
        <div class="modal-backdrop"></div>
        <div class="modal-dialog">
          <div class="modal-header">
            <h3 class="modal-title">${title}</h3>
            ${hasCloseButton ? '<button class="modal-close" type="button">&times;</button>' : ''}
          </div>
          <div class="modal-body">
            ${content}
          </div>
          ${hasActionButtons ? `
            <div class="modal-footer">
              <button class="btn btn-cancel" type="button">Cancel</button>
              <button class="btn btn-confirm" type="button">Confirm</button>
            </div>
          ` : ''}
        </div>
      </div>
    `;

    container.innerHTML = modalHTML;

    return container;
  }

  /**
   * Get stored fixture by ID
   * @param {string} fixtureId - Fixture identifier
   * @returns {Object|null} Fixture data or null if not found
   */
  getFixture(fixtureId) {
    return this.fixtures.get(fixtureId) || null;
  }

  /**
   * Update progress bar fixture to reflect new state
   * @param {string} progressId - Progress bar identifier
   * @param {number} completedTasks - Number of completed tasks
   * @param {number} totalTasks - Total number of tasks
   * @returns {boolean} True if updated successfully
   */
  updateProgressFixture(progressId, completedTasks, totalTasks) {
    const fixture = this.fixtures.get(progressId);
    if (!fixture) {
      return false;
    }

    const progressText = fixture.container.querySelector('.progress-text');
    const progressFill = fixture.container.querySelector('.progress-fill');

    if (progressText) {
      progressText.textContent = `${completedTasks} of ${totalTasks} completed`;
    }

    if (progressFill) {
      const percentage = Math.round((completedTasks / totalTasks) * 100);
      progressFill.style.width = `${percentage}%`;
    }

    // Update fixture data
    fixture.completedTasks = completedTasks;
    fixture.tasks = fixture.tasks.slice(0, totalTasks);

    return true;
  }

  /**
   * Simulate checkbox change event
   * @param {HTMLElement|string} checkboxOrId - Checkbox element or ID
   * @param {boolean} checked - New checked state
   * @returns {Event|null} The dispatched event or null if element not found
   */
  simulateCheckboxChange(checkboxOrId, checked) {
    const checkbox = typeof checkboxOrId === 'string'
      ? this.findElement(`#${checkboxOrId}`)
      : checkboxOrId;

    if (!checkbox) {
      return null;
    }

    checkbox.checked = checked;

    const event = new Event('change', { bubbles: true });

    if (checkbox.dispatchEvent) {
      checkbox.dispatchEvent(event);
    }

    return event;
  }

  /**
   * Simulate click event on element
   * @param {HTMLElement|string} elementOrSelector - Element or CSS selector
   * @returns {Event|null} The dispatched event or null if element not found
   */
  simulateClick(elementOrSelector) {
    const element = typeof elementOrSelector === 'string'
      ? this.findElement(elementOrSelector)
      : elementOrSelector;

    if (!element) {
      return null;
    }

    const event = new Event('click', { bubbles: true });

    if (element.dispatchEvent) {
      element.dispatchEvent(event);
    }

    return event;
  }

  /**
   * Find element in all fixtures
   * @param {string} selector - CSS selector
   * @returns {HTMLElement|null} Found element or null
   */
  findElement(selector) {
    // Try to find in document first
    if (document.querySelector) {
      const element = document.querySelector(selector);
      if (element) {
        return element;
      }
    }

    // Search in fixture containers
    for (const fixture of this.fixtures.values()) {
      if (fixture.container && fixture.container.querySelector) {
        const element = fixture.container.querySelector(selector);
        if (element) {
          return element;
        }
      }
    }

    return null;
  }

  /**
   * Find all matching elements in fixtures
   * @param {string} selector - CSS selector
   * @returns {Array<HTMLElement>} Array of found elements
   */
  findElements(selector) {
    const elements = [];

    // Try to find in document first
    if (document.querySelectorAll) {
      const documentElements = Array.from(document.querySelectorAll(selector));
      elements.push(...documentElements);
    }

    // Search in fixture containers
    for (const fixture of this.fixtures.values()) {
      if (fixture.container && fixture.container.querySelectorAll) {
        const fixtureElements = Array.from(fixture.container.querySelectorAll(selector));
        elements.push(...fixtureElements);
      }
    }

    return elements;
  }

  /**
   * Create a DOM element with attributes
   * @param {string} tagName - HTML tag name
   * @param {Object} [attributes={}] - Element attributes
   * @param {string} [innerHTML=''] - Element inner HTML
   * @returns {HTMLElement} Created element
   */
  createElement(tagName, attributes = {}, innerHTML = '') {
    const element = document.createElement(tagName);

    Object.keys(attributes).forEach(attr => {
      element.setAttribute(attr, attributes[attr]);
    });

    if (innerHTML) {
      element.innerHTML = innerHTML;
    }

    return element;
  }

  /**
   * Create a learning item (list item with checkbox and link)
   * @param {string} title - Learning item title
   * @param {string} href - Learning item URL
   * @param {Object} [options={}] - Additional options
   * @returns {HTMLElement} List item element with checkbox
   */
  createLearningItem(title, href, options = {}) {
    const {
      checked = false,
      estimated = '',
      level = '',
      description = ''
    } = options;

    const listItem = this.createElement('li');
    listItem.className = 'learning-item';

    const checkboxId = `checkbox-${Math.random().toString(36).substr(2, 9)}`;
    const checkbox = this.createElement('input', {
      type: 'checkbox',
      id: checkboxId
    });
    checkbox.checked = checked;

    const link = this.createElement('a', { href });
    link.textContent = title;

    // Create proper DOM structure
    listItem.appendChild(checkbox);
    listItem.appendChild(document.createTextNode(' '));
    listItem.appendChild(link);

    if (estimated) {
      const estimatedText = document.createTextNode(` • Estimated: ${estimated}`);
      listItem.appendChild(estimatedText);
    }

    if (level) {
      const levelText = document.createTextNode(` • ${level}`);
      listItem.appendChild(levelText);
    }

    if (description) {
      const descText = document.createTextNode(` - ${description}`);
      listItem.appendChild(descText);
    }

    return listItem;
  }

  /**
   * Create multiple checkboxes for testing
   * @param {number} count - Number of checkboxes to create
   * @param {Object} [options={}] - Checkbox options
   * @returns {HTMLInputElement[]} Array of checkbox elements
   */
  createCheckboxes(count, options = {}) {
    const checkboxes = [];

    for (let i = 0; i < count; i++) {
      const checkbox = this.createElement('input', {
        type: 'checkbox',
        id: options.idPrefix ? `${options.idPrefix}-${i}` : `checkbox-${i}`,
        name: options.name || 'test-checkbox',
        value: options.valuePrefix ? `${options.valuePrefix}-${i}` : `value-${i}`
      });

      if (options.checked) {
        checkbox.checked = true;
      }

      checkboxes.push(checkbox);
    }

    return checkboxes;
  }

  /**
   * Clean up all fixtures and containers
   * @returns {void}
   */
  cleanup() {
    // Remove containers from DOM
    for (const container of this.containers) {
      if (container.parentNode) {
        container.parentNode.removeChild(container);
      }
    }

    // Clear tracking
    this.containers.clear();
    this.fixtures.clear();
  }

  /**
   * Clean up specific fixture
   * @param {string} fixtureId - Fixture identifier
   * @returns {boolean} True if fixture was found and cleaned up
   */
  cleanupFixture(fixtureId) {
    const fixture = this.fixtures.get(fixtureId);
    if (!fixture) {
      return false;
    }

    if (fixture.container && fixture.container.parentNode) {
      fixture.container.parentNode.removeChild(fixture.container);
    }

    this.containers.delete(fixture.container);
    this.fixtures.delete(fixtureId);

    return true;
  }

  /**
   * Create enhanced localStorage mock for testing
   * @returns {Object} Enhanced localStorage mock
   */
  createEnhancedLocalStorage() {
    return createEnhancedLocalStorage();
  }
}

// Export singleton instance for convenience
export const domFixtures = new DOMFixtures();
