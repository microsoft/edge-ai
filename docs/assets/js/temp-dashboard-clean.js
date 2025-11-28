/**
 * Learning Path Dashboard Plugin
 * Consolidates all learning dashboard functionality into a single component
 * with comprehensive container validation and error handling
 *
 * @class LearningPathDashboard
 * @author Edge AI Team
 * @version 2.0.0
 */

import { LearningPathProgress } from '../features/progress-tracking/learning-path-progress.js';

class LearningPathDashboard {
  constructor(containers, config = {}) {
    // Initialize configuration first (needed for logging)
    this.config = {
      showProgress: true,
      showBadges: true,
      enableFiltering: true,
      enableSorting: true,
      enableAssessment: true,
      enableAutoSelection: true,
      layout: 'grid',
      progressSync: true,
      apiSync: false,
      containerValidation: true,
      errorDisplay: true,
      animations: true,
      debug: false,
      ...config
    };

    // Initialize event system
    this.eventListeners = {};
    this.eventHandlers = new Map(); // For test compatibility
    this.isDestroyed = false;

    // Initialize error tracking
    this.errors = [];

    // Initialize bound handlers map for cleanup
    this.boundHandlers = new Map();

  // Initialize progress tracking properties
  this.progressTracker = null;
  this.serverConnected = false;
  this.progressData = {};

    // Strict container validation to prevent random number display bug
    this.containers = this.validateAndNormalizeContainers(containers);

    // Allow graceful initialization even without valid containers for testing
    if (this.containers.length === 0) {
      // Only log generic warning if no specific warnings were already logged
      this.logWarning('No valid containers found. Dashboard initialized with empty state.');
    }

    // Initialize data structures
    this.paths = [];
    this.filteredPaths = [];
    this.filterState = {
      category: null,
      difficulty: null
    };
    this.sortState = {
      field: null,
      direction: 'asc'
    };

    // Initialize containers if we have valid ones
    if (this.containers.length > 0) {
      this.setupContainers();
      this.createErrorContainers();
      this.createAriaLiveRegions();
      this.setupKeyboardNavigation();
    }

    // Initialize progress tracking if enabled
    if (this.config.progressSync && this.progressTracker) {
      this.setupProgressTracking();
    }

    // Emit initialized event first
    this.emit('dashboard:initialized', {
      containersFound: this.containers.length,
      config: this.config
    });

    // Emit ready event for integration
    setTimeout(() => {
      this.emit('dashboard:ready', {
        containersFound: this.containers.length,
        config: this.config
      });
    }, 0);
  }

  /**
   * Validate and normalize container inputs to DOM elements
   * Prevents invalid configurations and random display issues
   */
  validateAndNormalizeContainers(containers) {
    const validContainers = [];

    // Handle null/undefined
    if (!containers) {
      this.logWarning('validateAndNormalizeContainers: No containers provided');
      return validContainers;
    }

    // Convert to array for consistent processing
    const containerArray = Array.isArray(containers) ? containers : [containers];

    containerArray.forEach((container, index) => {
      try {
        const element = this.normalizeToElement(container);
        if (element && this.isValidElement(element)) {
          // Check for duplicates
          if (!validContainers.includes(element)) {
            validContainers.push(element);
          }
        } else {
          this.logWarning(`validateAndNormalizeContainers: Invalid container at index ${index}:`, container);
        }
      } catch (error) {
        this.logError(`validateAndNormalizeContainers: Error processing container at index ${index}:`, error);
      }
    });

    return validContainers;
  }

  /**
   * Normalize various input types to DOM elements
   */
  normalizeToElement(input) {
    if (!input) return null;

    // Already a DOM element
    if (input instanceof Element) {
      return input;
    }

    // String selector
    if (typeof input === 'string' && input.trim().length > 0) {
      try {
        return document.querySelector(input.trim());
      } catch (error) {
        this.logWarning('normalizeToElement: Invalid selector string:', input);
        return null;
      }
    }

    return null;
  }

  /**
   * Validate that an element is suitable as a dashboard container
   */
  isValidElement(element) {
    return element instanceof Element &&
           element.nodeType === Node.ELEMENT_NODE;
  }

  /**
   * Setup containers with initial structure
   */
  setupContainers() {
    this.containers.forEach(container => {
      // Add dashboard class if not present
      if (!container.classList.contains('learning-path-dashboard')) {
        container.classList.add('learning-path-dashboard');
      }
    });
  }

  /**
   * Create error display containers
   */
  createErrorContainers() {
    this.containers.forEach(container => {
      // Create or find error container
      let errorContainer = container.querySelector('.learning-dashboard-error');
      if (!errorContainer) {
        errorContainer = document.createElement('div');
        errorContainer.className = 'learning-dashboard-error';
        errorContainer.style.display = 'none';
        container.insertBefore(errorContainer, container.firstChild);
      }
    });
  }

  /**
   * Create ARIA live regions for accessibility
   */
  createAriaLiveRegions() {
    this.containers.forEach(container => {
      // Create or find ARIA live region
      let ariaLive = container.querySelector('.learning-dashboard-status[aria-live="polite"]');
      if (!ariaLive) {
        ariaLive = document.createElement('div');
        ariaLive.setAttribute('aria-live', 'polite');
        ariaLive.setAttribute('aria-atomic', 'true');
        ariaLive.className = 'learning-dashboard-status sr-only';
        container.appendChild(ariaLive);
      }
    });
  }

  /**
   * Update ARIA live region with status message
   */
  updateAriaLiveRegion(message) {
    this.containers.forEach(container => {
      const ariaLive = container.querySelector('.learning-dashboard-status[aria-live="polite"]');
      if (ariaLive) {
        ariaLive.textContent = message;
      }
    });
  }

  /**
   * Display error message to users
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

    this.logError('Dashboard Error:', message);
  }

  /**
   * Announce status to screen readers
   */
  announceStatus(message) {
    this.containers.forEach(container => {
      const ariaLive = container.querySelector('.learning-dashboard-status[aria-live="polite"]');
      if (ariaLive) {
        ariaLive.textContent = message;
      }
    });
  }

  /**
   * Event system methods
   */
  on(event, handler) {
    this.initializeEventStorage(event);
    this.eventListeners[event].push(handler);
    this.eventHandlers.get(event).push(handler);
  }

  off(event, handler) {
    if (handler) {
      this.removeSpecificHandler(event, handler);
    } else {
      this.removeAllHandlers(event);
    }
  }

  emit(event, data) {
    if (this.eventListeners[event]) {
      this.eventListeners[event].forEach(handler => {
        try {
          handler(data);
        } catch (error) {
          this.logError(`Error in event handler for ${event}:`, error);
        }
      });
    }
  }

  /**
   * Initialize event storage for a given event type
   * @private
   */
  initializeEventStorage(event) {
    if (!this.eventListeners[event]) {
      this.eventListeners[event] = [];
    }
    if (!this.eventHandlers.has(event)) {
      this.eventHandlers.set(event, []);
    }
  }

  /**
   * Remove a specific event handler
   * @private
   */
  removeSpecificHandler(event, handler) {
    // Remove from eventListeners
    if (this.eventListeners[event]) {
      const index = this.eventListeners[event].indexOf(handler);
      if (index > -1) {
        this.eventListeners[event].splice(index, 1);
      }
    }

    // Remove from eventHandlers
    if (this.eventHandlers.has(event)) {
    // Remove progress event listeners
    if (this.progressTracker && typeof this.progressTracker.off === 'function') {
      this.progressTracker.off('learningPathProgressUpdate', this.handleProgressUpdate);
    }

      const handlers = this.eventHandlers.get(event);
      const index = handlers.indexOf(handler);
      if (index > -1) {
        handlers.splice(index, 1);
        if (handlers.length === 0) {
          this.eventHandlers.delete(event);
        }
      }
    }
  }

  /**
   * Remove all handlers for an event
   * @private
   */
  removeAllHandlers(event) {
    if (this.eventListeners[event]) {
      delete this.eventListeners[event];
    }
    this.eventHandlers.delete(event);
  }

  /**
   * Add event handler (test compatibility)
   */
  addEventHandler(event, handler) {
    this.on(event, handler);
  }

  /**
   * Remove event handler (test compatibility)
   */
  removeEventHandler(event, handler) {
    this.removeSpecificHandler(event, handler);
  }

  /**
   * Remove all event handlers for an event
   */
  removeAllEventHandlers(event) {
    this.removeAllHandlers(event);
  }

  /**
   * Load learning paths data into the dashboard
   */
    loadPaths(paths) {
        this.log('Loading paths', paths);

        if (!Array.isArray(paths)) {
            this.logError('loadPaths: paths must be an array', { paths });
            this.displayError('Invalid paths data provided');
            return;
        }

        // Validate and filter paths
        const validPaths = paths.filter(path => this.validatePath(path));

        if (validPaths.length === 0) {
            this.logError('No valid paths found', { originalCount: paths.length });
            this.displayError('No valid learning paths found');
            return;
        }

        this.clearCards();
        this.paths = validPaths;
        this.filteredPaths = [...validPaths]; // Initialize filtered paths with all valid paths
        this.renderCards();
    }

    /**
     * Sort cards by progress percentage (descending)
     */
  sortCardsByProgress(paths) {
    if (!Array.isArray(paths)) return [];

    return [...paths].sort((a, b) => {
      const progressA = this.calculateProgress(a.id).percentage;
      const progressB = this.calculateProgress(b.id).percentage;
      return progressB - progressA; // Descending order
    });
  }

  /**
   * Sort cards alphabetically by title
   */
  sortCardsByTitle(paths) {
    if (!Array.isArray(paths)) return [];

    return [...paths].sort((a, b) => {
      const titleA = (a.title || '').toLowerCase();
      const titleB = (b.title || '').toLowerCase();
      return titleA.localeCompare(titleB);
    });
  }

  /**
   * Validate a single learning path object
   */
  validatePath(path) {
    if (!path || typeof path !== 'object') {
      this.log('debug', 'validatePath failed: not an object', { path });
      return false;
    }

    // Check required fields
    if (!path.id || typeof path.id !== 'string' || path.id.trim() === '') {
      this.log('debug', 'validatePath failed: invalid id', { path });
      return false;
    }

    if (!path.title || typeof path.title !== 'string' || path.title.trim() === '') {
      this.log('debug', 'validatePath failed: invalid title', { path });
      return false;
    }

    if (!Array.isArray(path.steps)) {
      this.log('debug', 'validatePath failed: steps not array', { path });
      return false;
    }

    this.log('debug', 'validatePath passed', { pathId: path.id, title: path.title });
    return true;
  }

  /**
   * Clear existing cards from dashboard containers
   * @private
   */
  clearCards() {
    this.containers.forEach(container => {
      const existingCards = container.querySelectorAll('.learning-path-card');
      existingCards.forEach(card => card.remove());
    });
  }

  /**
   * Render cards in the dashboard containers
   */
  renderCards() {
    try {
      this.containers.forEach((container) => {
        this.renderCardsInContainer(container);
      });

      // Setup event handlers
      this.bindCardEvents();

      this.emit('cardsRendered', {
        pathCount: this.filteredPaths.length,
        containerCount: this.containers.length
      });

    } catch (error) {
      this.displayError('Failed to render cards');
      this.logError('Failed to render cards:', error);
    }
  }

  /**
   * Render cards in a specific container
   */
  renderCardsInContainer(container) {
    // Clear existing cards
    const existingCards = container.querySelectorAll('.learning-path-card');
    existingCards.forEach(card => card.remove());

    // Render filtered paths
    this.filteredPaths.forEach(path => {
      const cardHTML = this.renderCard(path);
      container.insertAdjacentHTML('beforeend', cardHTML);
    });

    // Enhance checkboxes with progress tracking after rendering
    this.enhanceCheckboxesWithProgressTracking();
  }

  /**
   * Render a single learning path card
   */
  renderCard(path) {
    const progress = this.calculateProgress(path.id);
    const badges = path.badge ? this.renderBadge(path.badge, path.id) : '';
    const steps = path.steps.map(step => this.renderStep(step, path.id)).join('');

    return `
      <div class="learning-path-card" data-path-id="${path.id}" data-category="${path.category || ''}" role="article" aria-labelledby="title-${path.id}">
        <div class="card-header">
          <h3 id="title-${path.id}" class="path-title">${path.title}</h3>
          <p class="path-description">${path.description || ''}</p>
          ${badges}
        </div>
        <div class="card-body">
          <div class="progress-section">
            <div class="progress-bar" role="progressbar" aria-valuenow="${progress.percentage}" aria-valuemin="0" aria-valuemax="100">
              <div class="progress-fill" style="width: ${progress.percentage}%"></div>
            </div>
            <div class="progress-text">${progress.completed} of ${progress.total} completed</div>
          </div>
          <div class="steps-section">
            ${steps}
          </div>
        </div>
      </div>
    `;
  }

  /**
   * Render a single step checkbox
   */
  renderStep(step, pathId) {
    const stepId = step.id || `step-${Math.random().toString(36).substr(2, 9)}`;
    const isCompleted = this.isStepCompleted(pathId, stepId);

    return `
      <div class="step-item">
        <input type="checkbox" class="step-checkbox" data-step-id="${stepId}" data-path-id="${pathId}" ${isCompleted ? 'checked' : ''}>
        <label for="${stepId}">${step.title || step.name}</label>
      </div>
    `;
  }

  /**
   * Render a badge
   */
  renderBadge(badge, pathId) {
    const progress = this.calculateProgress(pathId);
    const isUnlocked = badge.unlocked || progress.percentage === 100;
    const unlockedClass = isUnlocked ? ' unlocked' : '';

    return `
      <div class="completion-badge${unlockedClass}" data-badge-type="${badge.type || 'completion'}">
        <span class="badge-icon">${badge.icon || '🏆'}</span>
        <span class="badge-title">${badge.title || 'Completed'}</span>
      </div>
    `;
  }

  /**
   * Calculate progress for a path
   */
  calculateProgress(pathId) {
    const path = this.paths.find(p => p.id === pathId);
    if (!path || !path.steps) {
      return { completed: 0, total: 0, percentage: 0 };
    }

    const total = path.steps.length;
    const completed = path.steps.filter(step =>
      this.isStepCompleted(pathId, step.id)
    ).length;

    return {
      completed,
      total,
      percentage: total > 0 ? Math.round((completed / total) * 100) : 0
    };
  }

  /**
   * Check if a step is completed
   */
  isStepCompleted(pathId, stepId) {
    // First check the original path data
    const path = this.paths.find(p => p.id === pathId);
    if (path && path.steps) {
      const step = path.steps.find(s => s.id === stepId);
      if (step && typeof step.completed === 'boolean') {
        return step.completed;
      }
    }

    // Check localStorage second (user progress overrides initial state)
    try {
      const progress = JSON.parse(localStorage.getItem('learning-progress') || '{}');
      if (progress[pathId] && typeof progress[pathId][stepId] === 'boolean') {
        return progress[pathId][stepId];
      }
    } catch (error) {
      // localStorage error, continue to DOM check
    }

    // Check DOM state last (as final fallback)
    const checkbox = document.querySelector(`[data-path-id="${pathId}"][data-step-id="${stepId}"]`);
    if (checkbox) {
      return checkbox.checked;
    }

    return false;
  }

  /**
   * Bind event handlers to cards
   */
  bindCardEvents() {
    this.containers.forEach(container => {
      // Card click events
      const cards = container.querySelectorAll('.learning-path-card');
      cards.forEach(card => {
        const boundHandler = (event) => this.handleCardClick(event);
        this.boundHandlers.set(card, boundHandler);
        card.addEventListener('click', boundHandler);
      });

      // Setup step checkbox handlers for this container
      this.setupStepHandlers(container);
      this.setupKeyboardNavigation();
    });
  }

  /**
   * Handle card click events
   */
  handleCardClick(event) {
    const card = event.currentTarget;
    const pathId = card.dataset.pathId;
    const path = this.paths.find(p => p.id === pathId);

    if (path) {
      this.emit('card-clicked', {
        pathId,
        path
      });
    }
  }

  /**
   * Handle step completion changes
   */
  handleStepChange(event) {
    const checkbox = event.target;
    const stepId = checkbox.dataset.stepId;
    const pathId = checkbox.dataset.pathId;
    const isCompleted = checkbox.checked;

    this.log('debug', `Step ${stepId} in path ${pathId} ${isCompleted ? 'completed' : 'unchecked'}`);

    // Update localStorage
    this.updateStepInLocalStorage(pathId, stepId, isCompleted);

    // Calculate new progress
    const progress = this.calculateProgress(pathId);

    // Update progress display
    this.updateProgressDisplay(pathId);

    // Check for badge unlock
    this.checkBadgeUnlock(pathId);

    // Announce to screen readers
    this.announceProgressUpdate(pathId);

    // Emit progress update event
    this.emit('progress-updated', {
      pathId,
      stepId,
      completed: isCompleted,
      progress
    });
  }

  /**
   * Update step completion in localStorage
   */
  updateStepInLocalStorage(pathId, stepId, isCompleted) {
    try {
      // Build complete progress state from current path data
      const progress = {};

      if (!this.paths || this.paths.length === 0) {
        this.log('error', 'No paths data available for localStorage update');
        return;
      }

      this.paths.forEach(path => {
        progress[path.id] = {};
        path.steps.forEach(step => {
          // For the step being changed, use the new value
          if (path.id === pathId && step.id === stepId) {
            progress[path.id][step.id] = isCompleted;
            // Also update the path data to keep it in sync
            step.completed = isCompleted;
          } else {
            // For other steps, use current completion state
            progress[path.id][step.id] = this.isStepCompleted(path.id, step.id);
          }
        });
      });

      localStorage.setItem('learning-progress', JSON.stringify(progress));
      this.log('debug', 'Updated localStorage with progress:', progress);
    } catch (error) {
      this.log('error', 'Failed to update localStorage:', error);
    }
  }  /**
   * Update progress display for a path
   */
  updateProgressDisplay(pathId) {
    if (!pathId) return;

    const progress = this.calculateProgress(pathId);

    this.containers.forEach(container => {
      const pathCard = container.querySelector(`[data-path-id="${pathId}"]`);
      if (!pathCard) return;

      this.updateProgressElements(pathCard, progress);
    });

    // Emit progress update event
    this.emit('progressUpdated', {
      pathId,
      stepId: 'progress-update',
      completed: progress.completed,
      total: progress.total,
      percentage: progress.percentage
    });
  }

  /**
   * Update progress elements within a card
   * @private
   */
  updateProgressElements(card, progress) {
    const progressBar = card.querySelector('.progress-bar');
    const progressFill = card.querySelector('.progress-fill');
