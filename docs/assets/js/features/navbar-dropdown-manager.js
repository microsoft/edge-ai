/**
 * @fileoverview Navbar Dropdown Manager - Manages hover persistence for navbar dropdown menus
 * @description Provides enhanced dropdown behavior with hover persistence and keyboard navigation
 * @since 2025-01-01
 */

/**
 * Manages navbar dropdown menu behavior with hover persistence and accessibility
 * @class NavbarDropdownManager
 */
export class NavbarDropdownManager {
  /**
   * Creates a new NavbarDropdownManager instance
   * @param {Object} dependencies - Injected dependencies
   * @param {Object} dependencies.errorHandler - Error handling service
   * @param {Object} dependencies.debugHelper - Debug logging service
   * @param {Object} config - Configuration options
   * @param {number} config.hoverDelay - Delay before showing dropdown (ms)
   * @param {number} config.hideDelay - Delay before hiding dropdown (ms)
   * @param {boolean} config.enableKeyboardNav - Enable keyboard navigation
   * @param {boolean} config.enableTouchSupport - Enable touch device support
   */
  constructor(dependencies = {}, config = {}) {
    // Initialize dependencies with defaults
    this.errorHandler = dependencies.errorHandler || {
      safeExecute: (fn) => {
        try {
          return fn();
        } catch {
          // Silent error handling
          return null;
        }
      }
    };

    this.debugHelper = dependencies.debugHelper || {
      log: (_message) => { /* Silent debug helper */ }
    };

    // Configuration with defaults
    this.config = {
      hoverDelay: 150,
      hideDelay: 300,
      enableKeyboardNav: true,
      enableTouchSupport: true,
      ...config
    };

    // State management
    this.isInitialized = false;
    this.activeDropdown = null;
    this.hoverTimer = null;
    this.hideTimer = null;
    this.dropdownElements = new Map();
    this.eventListeners = [];
    this.abortController = new AbortController();

    // Bind methods to maintain context
    this.handleMouseEnter = this.handleMouseEnter.bind(this);
    this.handleMouseLeave = this.handleMouseLeave.bind(this);
    this.handleKeyDown = this.handleKeyDown.bind(this);
    this.handleFocus = this.handleFocus.bind(this);
    this.handleBlur = this.handleBlur.bind(this);
    this.handleClick = this.handleClick.bind(this);
    this.handleTouchStart = this.handleTouchStart.bind(this);
  }

  /**
   * Initializes the navbar dropdown manager
   * @returns {boolean} True if initialization successful, false otherwise
   */
  initialize() {
    return this.errorHandler.safeExecute(() => {
      if (this.isInitialized) {
        this.debugHelper?.log?.('Already initialized');
        return true;
      }

      this.setupDropdownElements();
      this.attachEventListeners();
      this.setupAccessibility();

      this.isInitialized = true;
      this.debugHelper?.log?.('Initialized successfully');
      return true;
    }) || false;
  }

  /**
   * Sets up dropdown elements and their relationships
   * @private
   */
  setupDropdownElements() {
    const dropdownTriggers = document.querySelectorAll('[data-dropdown-trigger]');

    dropdownTriggers.forEach(trigger => {
      const dropdownId = trigger.getAttribute('data-dropdown-trigger');
      const dropdown = document.querySelector(`[data-dropdown="${dropdownId}"]`);

      if (dropdown) {
        this.dropdownElements.set(trigger, {
          trigger,
          dropdown,
          id: dropdownId,
          isOpen: false
        });

        // Set initial ARIA attributes
        trigger.setAttribute('aria-haspopup', 'true');
        trigger.setAttribute('aria-expanded', 'false');
        dropdown.setAttribute('role', 'menu');
        dropdown.style.display = 'none';

        // Setup menu items
        const menuItems = dropdown.querySelectorAll('[role="menuitem"], a, button');
        menuItems.forEach((item, _index) => {
          item.setAttribute('tabindex', '-1');
          if (_index === 0) {
            item.setAttribute('data-first-item', 'true');
          }
          if (_index === menuItems.length - 1) {
            item.setAttribute('data-last-item', 'true');
          }
        });
      }
    });

    this.debugHelper?.log?.(`Found ${this.dropdownElements.size} dropdown elements`);
  }

  /**
   * Attaches event listeners to dropdown elements
   * @private
   */
  attachEventListeners() {
    const { signal } = this.abortController;

    this.dropdownElements.forEach(({ trigger, dropdown }) => {
      // Mouse events
      trigger.addEventListener('mouseenter', this.handleMouseEnter, { signal });
      trigger.addEventListener('mouseleave', this.handleMouseLeave, { signal });
      dropdown.addEventListener('mouseenter', this.handleMouseEnter, { signal });
      dropdown.addEventListener('mouseleave', this.handleMouseLeave, { signal });

      // Keyboard events
      if (this.config.enableKeyboardNav) {
        trigger.addEventListener('keydown', this.handleKeyDown, { signal });
        dropdown.addEventListener('keydown', this.handleKeyDown, { signal });
        trigger.addEventListener('focus', this.handleFocus, { signal });
        trigger.addEventListener('blur', this.handleBlur, { signal });
      }

      // Click events
      trigger.addEventListener('click', this.handleClick, { signal });

      // Touch events
      if (this.config.enableTouchSupport) {
        trigger.addEventListener('touchstart', this.handleTouchStart, { signal, passive: true });
      }
    });

    // Global click to close dropdowns
    document.addEventListener('click', (event) => {
      if (!this.isDropdownClick(event)) {
        this.closeAllDropdowns();
      }
    }, { signal });

    // Escape key to close dropdowns
    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape') {
        this.closeAllDropdowns();
        this.focusActiveTrigger();
      }
    }, { signal });
  }

  /**
   * Sets up accessibility features
   * @private
   */
  setupAccessibility() {
    // Add skip links for keyboard navigation
    const navbar = document.querySelector('.navbar, nav');
    if (navbar && !navbar.querySelector('.sr-only')) {
      const skipLink = document.createElement('a');
      skipLink.href = '#main-content';
      skipLink.className = 'sr-only';
      skipLink.textContent = 'Skip to main content';
      navbar.insertBefore(skipLink, navbar.firstChild);
    }
  }

  /**
   * Handles mouse enter events
   * @param {MouseEvent} event - The mouse event
   * @private
   */
  handleMouseEnter(event) {
    const element = event.currentTarget;
    const dropdownData = this.findDropdownData(element);

    if (dropdownData) {
      this.clearHideTimer();

      if (!dropdownData.isOpen) {
        this.clearHoverTimer();
        this.hoverTimer = setTimeout(() => {
          this.openDropdown(dropdownData);
        }, this.config.hoverDelay);
      }
    }
  }

  /**
   * Handles mouse leave events
   * @param {MouseEvent} event - The mouse event
   * @private
   */
  handleMouseLeave(event) {
    const element = event.currentTarget;
    const dropdownData = this.findDropdownData(element);

    if (dropdownData && dropdownData.isOpen) {
      this.clearHideTimer();
      this.hideTimer = setTimeout(() => {
        this.closeDropdown(dropdownData);
      }, this.config.hideDelay);
    }
  }

  /**
   * Handles keyboard events
   * @param {KeyboardEvent} event - The keyboard event
   * @private
   */
  handleKeyDown(event) {
    const element = event.currentTarget;
    const dropdownData = this.findDropdownData(element);

    if (!dropdownData) {return;}

    switch (event.key) {
      case 'Enter':
      case ' ':
        event.preventDefault();
        if (element === dropdownData.trigger) {
          this.toggleDropdown(dropdownData);
        }
        break;

      case 'ArrowDown':
        event.preventDefault();
        if (dropdownData.isOpen) {
          this.focusNextMenuItem(dropdownData.dropdown);
        } else {
          this.openDropdown(dropdownData);
        }
        break;

      case 'ArrowUp':
        event.preventDefault();
        if (dropdownData.isOpen) {
          this.focusPreviousMenuItem(dropdownData.dropdown);
        }
        break;

      case 'Tab':
        if (dropdownData.isOpen) {
          this.closeDropdown(dropdownData);
        }
        break;
    }
  }

  /**
   * Handles focus events
   * @param {FocusEvent} event - The focus event
   * @private
   */
  handleFocus(event) {
    const element = event.currentTarget;
    const dropdownData = this.findDropdownData(element);

    if (dropdownData && element === dropdownData.trigger) {
      // Add visual focus indicator
      element.classList.add('dropdown-focused');
    }
  }

  /**
   * Handles blur events
   * @param {FocusEvent} event - The blur event
   * @private
   */
  handleBlur(event) {
    const element = event.currentTarget;
    const dropdownData = this.findDropdownData(element);

    if (dropdownData && element === dropdownData.trigger) {
      element.classList.remove('dropdown-focused');

      // Close dropdown if focus moves outside
      setTimeout(() => {
        if (!this.isDropdownFocused(dropdownData)) {
          this.closeDropdown(dropdownData);
        }
      }, 100);
    }
  }

  /**
   * Handles click events
   * @param {MouseEvent} event - The click event
   * @private
   */
  handleClick(event) {
    const element = event.currentTarget;
    const dropdownData = this.findDropdownData(element);

    if (dropdownData && element === dropdownData.trigger) {
      event.preventDefault();
      this.toggleDropdown(dropdownData);
    }
  }

  /**
   * Handles touch start events
   * @param {TouchEvent} event - The touch event
   * @private
   */
  handleTouchStart(event) {
    const element = event.currentTarget;
    const dropdownData = this.findDropdownData(element);

    if (dropdownData) {
      // On touch devices, first touch opens dropdown, second navigates
      if (!dropdownData.isOpen) {
        event.preventDefault();
        this.openDropdown(dropdownData);
      }
    }
  }

  /**
   * Opens a dropdown menu
   * @param {Object} dropdownData - The dropdown data object
   */
  openDropdown(dropdownData) {
    if (dropdownData.isOpen) {return;}

    this.closeAllDropdowns();

    dropdownData.isOpen = true;
    dropdownData.dropdown.style.display = 'block';
    dropdownData.trigger.setAttribute('aria-expanded', 'true');
    dropdownData.trigger.classList.add('dropdown-open');

    this.activeDropdown = dropdownData;

    // Focus first menu item if opened via keyboard
    if (document.activeElement === dropdownData.trigger) {
      this.focusFirstMenuItem(dropdownData.dropdown);
    }

    // Emit custom event
    this.emitEvent('dropdown:opened', {
      trigger: dropdownData.trigger,
      dropdown: dropdownData.dropdown,
      id: dropdownData.id
    });

    this.debugHelper?.log?.(`Opened dropdown: ${dropdownData.id}`);
  }

  /**
   * Closes a dropdown menu
   * @param {Object} dropdownData - The dropdown data object
   */
  closeDropdown(dropdownData) {
    if (!dropdownData.isOpen) {return;}

    dropdownData.isOpen = false;
    dropdownData.dropdown.style.display = 'none';
    dropdownData.trigger.setAttribute('aria-expanded', 'false');
    dropdownData.trigger.classList.remove('dropdown-open');

    if (this.activeDropdown === dropdownData) {
      this.activeDropdown = null;
    }

    // Emit custom event
    this.emitEvent('dropdown:closed', {
      trigger: dropdownData.trigger,
      dropdown: dropdownData.dropdown,
      id: dropdownData.id
    });

    this.debugHelper?.log?.(`Closed dropdown: ${dropdownData.id}`);
  }

  /**
   * Toggles a dropdown menu
   * @param {Object} dropdownData - The dropdown data object
   */
  toggleDropdown(dropdownData) {
    if (dropdownData.isOpen) {
      this.closeDropdown(dropdownData);
    } else {
      this.openDropdown(dropdownData);
    }
  }

  /**
   * Closes all open dropdowns
   */
  closeAllDropdowns() {
    this.dropdownElements.forEach(dropdownData => {
      if (dropdownData.isOpen) {
        this.closeDropdown(dropdownData);
      }
    });
  }

  /**
   * Focuses the first menu item in a dropdown
   * @param {HTMLElement} dropdown - The dropdown element
   * @private
   */
  focusFirstMenuItem(dropdown) {
    const firstItem = dropdown.querySelector('[data-first-item="true"]');
    if (firstItem) {
      firstItem.focus();
    }
  }

  /**
   * Focuses the next menu item
   * @param {HTMLElement} dropdown - The dropdown element
   * @private
   */
  focusNextMenuItem(dropdown) {
    const menuItems = Array.from(dropdown.querySelectorAll('[role="menuitem"], a, button'));
    const currentIndex = menuItems.indexOf(document.activeElement);
    const nextIndex = (currentIndex + 1) % menuItems.length;
    menuItems[nextIndex]?.focus();
  }

  /**
   * Focuses the previous menu item
   * @param {HTMLElement} dropdown - The dropdown element
   * @private
   */
  focusPreviousMenuItem(dropdown) {
    const menuItems = Array.from(dropdown.querySelectorAll('[role="menuitem"], a, button'));
    const currentIndex = menuItems.indexOf(document.activeElement);
    const prevIndex = currentIndex <= 0 ? menuItems.length - 1 : currentIndex - 1;
    menuItems[prevIndex]?.focus();
  }

  /**
   * Focuses the active trigger element
   * @private
   */
  focusActiveTrigger() {
    if (this.activeDropdown) {
      this.activeDropdown.trigger.focus();
    }
  }

  /**
   * Finds dropdown data for an element
   * @param {HTMLElement} element - The element to find data for
   * @returns {Object|null} The dropdown data or null
   * @private
   */
  findDropdownData(element) {
    for (const [trigger, data] of this.dropdownElements) {
      if (trigger === element || data.dropdown === element) {
        return data;
      }
    }
    return null;
  }

  /**
   * Checks if a click is within a dropdown
   * @param {MouseEvent} event - The click event
   * @returns {boolean} True if click is within a dropdown
   * @private
   */
  isDropdownClick(event) {
    for (const dropdownData of this.dropdownElements.values()) {
      if (dropdownData.trigger.contains(event.target) ||
          dropdownData.dropdown.contains(event.target)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Checks if any dropdown element has focus
   * @param {Object} dropdownData - The dropdown data object
   * @returns {boolean} True if dropdown has focus
   * @private
   */
  isDropdownFocused(dropdownData) {
    return dropdownData.trigger.contains(document.activeElement) ||
           dropdownData.dropdown.contains(document.activeElement);
  }

  /**
   * Clears the hover timer
   * @private
   */
  clearHoverTimer() {
    if (this.hoverTimer) {
      clearTimeout(this.hoverTimer);
      this.hoverTimer = null;
    }
  }

  /**
   * Clears the hide timer
   * @private
   */
  clearHideTimer() {
    if (this.hideTimer) {
      clearTimeout(this.hideTimer);
      this.hideTimer = null;
    }
  }

  /**
   * Emits a custom event
   * @param {string} eventName - The event name
   * @param {Object} detail - The event detail data
   * @private
   */
  emitEvent(eventName, detail) {
    const event = new CustomEvent(eventName, {
      detail,
      bubbles: true,
      cancelable: true
    });
    document.dispatchEvent(event);
  }

  /**
   * Gets current dropdown state
   * @returns {Object} Current state information
   */
  getState() {
    const openDropdowns = [];
    this.dropdownElements.forEach(data => {
      if (data.isOpen) {
        openDropdowns.push(data.id);
      }
    });

    return {
      isInitialized: this.isInitialized,
      dropdownCount: this.dropdownElements.size,
      openDropdowns,
      activeDropdown: this.activeDropdown?.id || null
    };
  }

  /**
   * Updates configuration
   * @param {Object} newConfig - New configuration options
   * @returns {boolean} True if update successful
   */
  updateConfig(newConfig) {
    return this.errorHandler.safeExecute(() => {
      this.config = { ...this.config, ...newConfig };
      this.debugHelper?.log?.('Configuration updated');
      return true;
    }) || false;
  }

  /**
   * Destroys the dropdown manager and cleans up resources
   * @returns {boolean} True if destruction successful
   */
  destroy() {
    return this.errorHandler.safeExecute(() => {
      if (!this.isInitialized) {
        return true;
      }

      // Clear timers
      this.clearHoverTimer();
      this.clearHideTimer();

      // Close all dropdowns
      this.closeAllDropdowns();

      // Abort all event listeners
      this.abortController.abort();

      // Clear data structures
      this.dropdownElements.clear();
      this.activeDropdown = null;

      // Reset state
      this.isInitialized = false;

      this.debugHelper?.log?.('Destroyed successfully');
      return true;
    }) || false;
  }
}

// Create and export default instance
export const navbarDropdownManager = new NavbarDropdownManager();

// Export factory function for custom instances
export const createNavbarDropdownManager = (dependencies, config) => {
  return new NavbarDropdownManager(dependencies, config);
};
