export const containerUtilitiesMixin = {
  /**
   * Get the first container (for backward compatibility with tests)
   * @returns {HTMLElement|null}
   */
  get container() {
    return this.containers?.[0] || null;
  },
  validateAndNormalizeContainers(containers) {
    const validContainers = [];
    const errors = [];

    if (!containers) {
      errors.push('No containers provided');
      return {
        isValid: false,
        containers: [],
        errors
      };
    }

    const containerArray = Array.isArray(containers) ? containers : [containers];

    containerArray.forEach((container, index) => {
      try {
        const element = this.normalizeToElement(container);
        if (element && this.isValidElement(element)) {
          if (!validContainers.includes(element)) {
            validContainers.push(element);
          }
        } else {
          const errorMsg = `Invalid container at index ${index}`;
          errors.push(errorMsg);
          this.logWarning(`validateAndNormalizeContainers: ${errorMsg}:`, container);
        }
      } catch (error) {
        const errorMsg = `Error processing container at index ${index}: ${error.message}`;
        errors.push(errorMsg);
        this.logError(`validateAndNormalizeContainers: ${errorMsg}`, error);
      }
    });

    return {
      isValid: validContainers.length > 0,
      containers: validContainers,
      errors
    };
  },

  normalizeToElement(input) {
    if (!input) return null;

    if (input instanceof Element) {
      return input;
    }

    if (typeof input === 'string' && input.trim().length > 0) {
      try {
        return document.querySelector(input.trim());
      } catch (error) {
        this.logWarning('normalizeToElement: Invalid selector string:', input);
        return null;
      }
    }

    return null;
  },

  isValidElement(element) {
    return element instanceof Element && element.nodeType === Node.ELEMENT_NODE;
  },

  /**
   * Display error message in container error elements
   * @param {string} message - Error message to display
   * @param {number} hideAfter - Milliseconds before hiding (0 = don't hide)
   */
  displayError(message, hideAfter = 5000) {
    this.errors.push({
      message,
      timestamp: Date.now()
    });

    this.containers.forEach(container => {
      const errorContainer = container.querySelector('.learning-dashboard-error');
      if (errorContainer) {
        errorContainer.textContent = message === null ? 'null' : String(message);
        errorContainer.style.display = 'block';

        if (hideAfter > 0) {
          setTimeout(() => {
            errorContainer.style.display = 'none';
          }, hideAfter);
        }
      }
    });

    // Also announce to screen readers via ARIA live region
    // Extract just the context part from "context: error.message" format
    const errorMessage = message.includes(':') ? message.split(':')[0] : message;
    this.announceStatus(`Error: ${errorMessage}`, 'assertive');

    this.logError('Dashboard Error:', message);
  },

  /**
   * Announce status to screen readers via ARIA live region
   * @param {string} message - Status message to announce
   * @param {string} priority - 'polite' or 'assertive' ARIA live priority
   */
  announceStatus(message, priority = 'polite') {
    this.containers.forEach(container => {
      // Query the unified live region with sr-only class
      const ariaLive = container.querySelector('.sr-only.learning-dashboard-aria-live');
      if (ariaLive) {
        ariaLive.setAttribute('aria-live', priority);
        ariaLive.textContent = message;
        // Clear message after announcement to allow repeated announcements
        setTimeout(() => {
          ariaLive.textContent = '';
        }, 1000);
      }
    });
  },

  /**
   * Announce path selection to screen readers
   * @param {Object|string} path - Path object or title string
   * @param {boolean} selected - Whether path was selected or deselected
   */
  announcePathSelection(path, selected) {
    const pathTitle = typeof path === 'object' ? path.title : path;
    const message = selected
      ? `Selected: ${pathTitle}`
      : `Deselected: ${pathTitle}`;
    this.announceStatus(message);
  },

  /**
   * Announce overall dashboard status
   * @param {Array|Object} status - Array of selected paths or status object with counts
   */
  announceOverallStatus(status) {
    let selectedCount, totalCount;

    if (Array.isArray(status)) {
      // If status is an array of selected paths
      selectedCount = status.length;
      totalCount = this.paths?.length || this.learningPaths?.length || 0;
    } else if (status && typeof status === 'object') {
      // If status is an object with counts
      selectedCount = status.selectedPaths || 0;
      totalCount = status.totalPaths || 0;
    } else {
      // If no status provided, calculate from current state
      selectedCount = this.selectedPaths?.size || 0;
      totalCount = this.paths?.length || this.learningPaths?.length || 0;
    }

    const message = selectedCount > 0
      ? `${selectedCount} learning path${selectedCount !== 1 ? 's' : ''} selected`
      : `${totalCount} paths available, 0 selected`;
    this.announceStatus(message);
  }
};
