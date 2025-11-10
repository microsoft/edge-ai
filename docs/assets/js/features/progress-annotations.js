/**
 * Progress Annotations for Learning Path Items
 *
 * Provides visual progress indicators and status badges for learning path items.
 * Integrates with the Learning Path Manager to display progress states,
 * completion scores, and interactive progress bars.
 *
 * @class ProgressAnnotations
 * @example
 * const progressAnnotations = new ProgressAnnotations({
 *   errorHandler: errorHandlerService,
 *   learningPathManager: learningPathManagerService,
 *   domUtils: domUtilsService
 * }, {
 *   features: { badges: true, progressBars: true },
 *   performance: { batchProcessing: true }
 * });
 *
 * progressAnnotations.processLearningPathItems(containerElement);
 *
 * Features:
 * - Progress state detection (on-your-path, in-progress, completed, not-selected)
 * - Visual annotations (badges, icons, progress bars, score displays)
 * - Batch processing for performance optimization
 * - Accessibility support (ARIA labels, keyboard navigation, high contrast)
 * - Memory management and cleanup
 * - Error handling and graceful degradation
 * - Progressive enhancement maintaining markdown-first approach
 */

/**
 * Custom error class for ProgressAnnotations-specific errors
 * @class ProgressAnnotationsError
 * @extends Error
 */
export class ProgressAnnotationsError extends Error {
  /**
   * Create a ProgressAnnotationsError
   * @param {string} message - Error message
   * @param {string} code - Error code for categorization
   * @param {Error} [originalError] - Original error that caused this error
   */
  constructor(message, code, originalError = null) {
    super(message);
    this.name = 'ProgressAnnotationsError';
    this.code = code;
    this.originalError = originalError;
  }
}

export class ProgressAnnotations {
  /**
   * Default configuration for progress annotations
   * @static
   * @readonly
   * @type {Object}
   */
  static DEFAULT_CONFIG = {
    // Animation settings
    animations: {
      enabled: true,
      duration: 300,
      easing: 'ease-in-out'
    },

    // CSS class configuration - ensures separation of styling from JavaScript
    cssClasses: {
      progressBadge: 'progress-badge',
      progressIcon: 'progress-icon',
      progressBar: 'progress-bar-container',
      scoreDisplay: 'score-display',
      loadingState: 'loading',
      highContrast: 'high-contrast-support'
    },

    // Feature toggles for flexible functionality
    features: {
      badges: true,
      icons: true,
      progressBars: true,
      scoreDisplays: true,
      animations: true
    },

    // Accessibility settings following WCAG 2.1 AA standards
    accessibility: {
      announceChanges: true,
      keyboardNavigation: true,
      highContrastSupport: true
    },

    // Performance optimization settings
    performance: {
      batchProcessing: true,
      debounceMs: 100,
      maxBatchSize: 10
    }
  };

  /**
   * Create a new ProgressAnnotations instance
   * @param {Object} dependencies - Required dependencies (dependency injection pattern)
   * @param {Object} dependencies.errorHandler - Error handling service with handleError method
   * @param {Object} dependencies.learningPathManager - Learning path management service
   * @param {Object} dependencies.domUtils - DOM utility service for safe DOM manipulation
   * @param {Object} [config={}] - Optional configuration overrides
   * @throws {ProgressAnnotationsError} When required dependencies are missing
   */
  constructor(dependencies, config = {}) {
    this._validateDependencies(dependencies);

    // Store dependencies using dependency injection pattern
    this.errorHandler = dependencies.errorHandler;
    this.learningPathManager = dependencies.learningPathManager;
    this.domUtils = dependencies.domUtils;

    // Merge configuration using optimized deep merge
    this.config = this._mergeConfiguration(config);

    // Initialize instance state with proper defaults
    this._initializeState();

    // Set up integration with learning path manager
    this._setupLearningPathIntegration();
  }

  /**
   * Detect the progress state for a given kata ID
   * @param {string} kataId - The kata identifier
   * @returns {string} Progress state: 'on-your-path', 'in-progress', 'completed', 'not-selected'
   * @throws {ProgressAnnotationsError} When instance is destroyed or kata ID is invalid
   */
  async detectProgressState(kataId) {
    if (!this._ensureNotDestroyed('detectProgressState')) {
      return 'not-selected'; // Silent failure with safe fallback
    }

    if (!kataId || typeof kataId !== 'string') {
      this._handleError(
        new ProgressAnnotationsError('Invalid kata ID provided', 'INVALID_KATA_ID'),
        'detectProgressState'
      );
      return 'not-selected';
    }

    try {
      // Check if kata is on the user's learning path
      if (this.learningPathManager.isKataOnPath(kataId)) {
        // Get progress data for the kata
        const progressData = await this.learningPathManager.getKataProgress(kataId);

        if (progressData?.completed) {
          return 'completed';
        } else if (progressData?.started || progressData?.progress > 0) {
          return 'in-progress';
        } else {
          return 'on-your-path';
        }
      }

      return 'not-selected';
    } catch (_error) {
      this._handleError(
        new ProgressAnnotationsError('Failed to detect progress state', 'STATE_DETECTION_ERROR', _error),
        'detectProgressState'
      );
      return 'not-selected'; // Safe fallback
    }
  }

  /**
   * Create a progress badge element
   * @param {HTMLElement} targetElement - Element to attach badge to
   * @param {Object} config - Badge configuration
   * @param {string} config.state - Progress state (on-your-path, in-progress, completed, etc.)
   * @param {string} config.text - Badge text content
   * @param {string} config.ariaLabel - Accessibility label
   * @returns {HTMLElement|null} Created badge element or null if creation fails
   */
  createProgressBadge(targetElement, config) {
    if (!this._ensureNotDestroyed('createProgressBadge')) {
      return null; // Silent failure
    }

    try {
      const badge = this.domUtils.createElement('span');
      const classes = `${this.config.cssClasses.progressBadge} ${config.state}`;

      this._applyElementStyling(badge, classes, config.ariaLabel);
      badge.textContent = config.text;

      this._trackCreatedElement(badge);
      return badge;
    } catch (_error) {
      this._handleError(
        new ProgressAnnotationsError('Failed to create progress badge', 'BADGE_CREATION_ERROR', _error),
        'createProgressBadge'
      );
      return null;
    }
  }

  /**
   * Create a progress icon element
   * @param {HTMLElement} targetElement - Element to attach icon to
   * @param {Object} config - Icon configuration
   * @param {string} config.state - Progress state for icon styling
   * @param {string} config.ariaLabel - Accessibility label
   * @returns {HTMLElement|null} Created icon element or null if creation fails
   */
  createProgressIcon(targetElement, config) {
    if (!this._ensureNotDestroyed('createProgressIcon')) {
      return null; // Silent failure
    }

    try {
      const icon = this.domUtils.createElement('i');
      const classes = `${this.config.cssClasses.progressIcon} icon-${config.state}`;

      this._applyElementStyling(icon, classes, config.ariaLabel);
      this._trackCreatedElement(icon);

      return icon;
    } catch (_error) {
      this._handleError(
        new ProgressAnnotationsError('Failed to create progress icon', 'ICON_CREATION_ERROR', _error),
        'createProgressIcon'
      );
      return null;
    }
  }

  /**
   * Create a progress bar element
   * @param {HTMLElement} targetElement - Element to attach progress bar to
   * @param {Object} config - Progress bar configuration
   * @param {number} [config.progress=0] - Progress percentage (0-100)
   * @param {string} config.ariaDescribedBy - ARIA described-by attribute
   * @returns {HTMLElement|null} Created progress bar container or null if creation fails
   */
  createProgressBar(targetElement, config) {
    if (!this._ensureNotDestroyed('createProgressBar')) {
      return null; // Silent failure
    }

    try {
      const { container, progressBar, progressFill } = this._createProgressBarElements();
      const percentage = Math.round(Math.max(0, Math.min(100, config.progress || 0)));

      this._configureProgressBar(container, progressFill, percentage, config);
      this._assembleProgressBar(container, progressBar, progressFill);

      return container;
    } catch (_error) {
      this._handleError(
        new ProgressAnnotationsError('Failed to create progress bar', 'PROGRESS_BAR_CREATION_ERROR', _error),
        'createProgressBar'
      );
      return null;
    }
  }

  /**
   * Create a score display element
   * @param {HTMLElement} targetElement - Element to attach score display to
   * @param {Object} config - Score display configuration
   * @param {number} config.score - Score percentage to display
   * @param {string} config.ariaLabel - Accessibility label
   * @returns {HTMLElement|null} Created score display element or null if creation fails
   */
  createScoreDisplay(targetElement, config) {
    if (!this._ensureNotDestroyed('createScoreDisplay')) {
      return null; // Silent failure
    }

    try {
      const scoreDisplay = this.domUtils.createElement('span');
      const classes = this.config.cssClasses.scoreDisplay;

      this._applyElementStyling(scoreDisplay, classes, config.ariaLabel);
      scoreDisplay.textContent = `Score: ${Math.round(config.score)}%`;

      this._trackCreatedElement(scoreDisplay);
      return scoreDisplay;
    } catch (_error) {
      this._handleError(
        new ProgressAnnotationsError('Failed to create score display', 'SCORE_DISPLAY_CREATION_ERROR', _error),
        'createScoreDisplay'
      );
      return null;
    }
  }

  /**
   * Apply annotations to an element based on its progress state
   * @param {HTMLElement} element - Target element
   * @param {string} progressState - Progress state to apply
   * @param {Object} [progressData={}] - Optional progress data
   * @throws {ProgressAnnotationsError} When element is invalid or annotations fail
   */
  applyAnnotations(element, progressState, progressData = {}) {
    if (!this._ensureNotDestroyed('applyAnnotations')) {
      return; // Silent failure for graceful cleanup
    }

    try {
      this._validateProgressState(progressState);
      const labelElement = this._findLabelElement(element);

      if (!labelElement) {
        this._handleError(
          new ProgressAnnotationsError('No label element found for progress annotation', 'MISSING_LABEL_ELEMENT'),
          'applyAnnotations'
        );
        return;
      }

      // Apply annotations based on state using the strategy pattern
      this._applyStateAnnotations(labelElement, progressState, progressData);
    } catch (_error) {
      this._handleError(
        new ProgressAnnotationsError('Failed to apply annotations', 'ANNOTATION_APPLICATION_ERROR', _error),
        'applyAnnotations'
      );
    }
  }

  /**
   * Process all learning path items in a container element
   * @param {HTMLElement} container - Container element to process
   * @throws {ProgressAnnotationsError} When container is invalid or processing fails
   */
  async processLearningPathItems(container) {
    if (!this._ensureNotDestroyed('processLearningPathItems')) {
      return; // Silent failure
    }

    if (!container || !container.querySelectorAll) {
      this._handleError(
        new ProgressAnnotationsError('Invalid container element provided', 'INVALID_CONTAINER'),
        'processLearningPathItems'
      );
      return;
    }

    try {
      // Find all checkbox items with kata IDs
      const checkboxItems = this.domUtils.querySelectorAll(
        container,
        'input[type="checkbox"][data-kata-id]'
      );

      if (checkboxItems.length === 0) {
        return; // No items to process, not an error
      }

      // Process items using optimized batch processing
      if (this.config.performance.batchProcessing) {
        await this._batchProcessItems(checkboxItems);
      } else {
        await this._processItemsSequentially(checkboxItems);
      }
    } catch (_error) {
      this._handleError(
        new ProgressAnnotationsError('Failed to process learning path items', 'ITEM_PROCESSING_ERROR', _error),
        'processLearningPathItems'
      );
    }
  }

  /**
   * Clean up resources and destroy the instance
   * Implements proper memory management and resource cleanup
   */
  destroy() {
    if (this.isDestroyed) {
      return; // Already destroyed, nothing to do
    }

    try {
      // Clean up event listeners to prevent memory leaks
      this._cleanupEventListeners();

      // Remove all created DOM elements
      this._cleanupCreatedElements();

      // Clear all references and mark as destroyed
      this._finalizeDestroy();
    } catch (_error) {
      // Best effort cleanup - ensure instance is marked as destroyed
      this.isDestroyed = true;

      // Try to log the error if errorHandler is still available
      if (this.errorHandler?.handleError) {
        this.errorHandler.handleError(
          new ProgressAnnotationsError('Error during cleanup', 'CLEANUP_ERROR', _error),
          'destroy'
        );
      }
    }
  }

  // Private helper methods

  /**
   * Validate required dependencies during construction
   * @param {Object} dependencies - Dependencies to validate
   * @throws {ProgressAnnotationsError} When required dependencies are missing
   * @private
   */
  _validateDependencies(dependencies) {
    const requiredDeps = ['errorHandler', 'learningPathManager', 'domUtils'];

    for (const dep of requiredDeps) {
      if (!dependencies?.[dep]) {
        throw new ProgressAnnotationsError(
          `ProgressAnnotations requires ${dep} dependency`,
          'MISSING_DEPENDENCY'
        );
      }
    }
  }

  /**
   * Initialize instance state with proper defaults
   * @private
   */
  _initializeState() {
    this.isDestroyed = false;
    this.eventListeners = [];
    this._createdElements = new Set();
  }

  /**
   * Check if the instance is destroyed
   * @param {string} operation - Name of the operation being performed
   * @returns {boolean} True if instance is destroyed, false otherwise
   * @private
   */
  _isDestroyed(_operation) {
    return this.isDestroyed;
  }

  /**
   * Ensure instance is not destroyed before performing operations
   * @param {string} operation - Name of the operation being performed
   * @returns {boolean} True if instance is valid, false if destroyed
   * @private
   */
  _ensureNotDestroyed(_operation) {
    return !this.isDestroyed;
  }

  /**
   * Handle errors using the error handler service
   * @param {Error} error - Error to handle
   * @param {string} context - Context where error occurred
   * @private
   */
  _handleError(error, context) {
    if (this.errorHandler?.handleError) {
      this.errorHandler.handleError(error, `ProgressAnnotations.${context}`);
    }
  }

  /**
   * Validate progress state values
   * @param {string} progressState - State to validate
   * @throws {ProgressAnnotationsError} When state is invalid
   * @private
   */
  _validateProgressState(progressState) {
    const validStates = ['on-your-path', 'in-progress', 'completed', 'not-selected', 'loading'];
    if (!validStates.includes(progressState)) {
      throw new ProgressAnnotationsError(
        `Invalid progress state: ${progressState}`,
        'INVALID_PROGRESS_STATE'
      );
    }
  }

  /**
   * Find the label element within a container
   * @param {HTMLElement} element - Container element
   * @returns {HTMLElement|null} Label element or null if not found
   * @private
   */
  _findLabelElement(element) {
    return this.domUtils.querySelector(element, 'label');
  }

  /**
   * Apply element styling including accessibility features
   * @param {HTMLElement} element - Element to style
   * @param {string} classes - CSS classes to apply
   * @param {string} ariaLabel - ARIA label for accessibility
   * @private
   */
  _applyElementStyling(element, classes, ariaLabel) {
    this.domUtils.addClass(element, classes);
    this.domUtils.setAttribute(element, 'aria-label', ariaLabel);

    if (this.config.accessibility.highContrastSupport) {
      this.domUtils.addClass(element, this.config.cssClasses.highContrast);
    }

    if (this.config.accessibility.keyboardNavigation) {
      this.domUtils.setAttribute(element, 'tabindex', '0');
    }
  }

  /**
   * Track created elements for cleanup
   * @param {HTMLElement} element - Element to track
   * @private
   */
  _trackCreatedElement(element) {
    this._createdElements.add(element);
  }

  /**
   * Create progress bar DOM elements
   * @returns {Object} Object containing container, progressBar, and progressFill elements
   * @private
   */
  _createProgressBarElements() {
    return {
      container: this.domUtils.createElement('div'),
      progressBar: this.domUtils.createElement('div'),
      progressFill: this.domUtils.createElement('div')
    };
  }

  /**
   * Configure progress bar with styling and accessibility
   * @param {HTMLElement} container - Progress bar container
   * @param {HTMLElement} progressFill - Progress fill element
   * @param {number} percentage - Progress percentage
   * @param {Object} config - Configuration object
   * @private
   */
  _configureProgressBar(container, progressFill, percentage, config) {
    this.domUtils.addClass(container, this.config.cssClasses.progressBar);
    this.domUtils.setAttribute(container, 'data-progress', percentage.toString());
    this.domUtils.setAttribute(progressFill, 'style', `width: ${percentage}%`);

    // Accessibility attributes following WCAG 2.1 AA standards
    this.domUtils.setAttribute(container, 'role', 'progressbar');
    this.domUtils.setAttribute(container, 'aria-valuenow', percentage.toString());
    this.domUtils.setAttribute(container, 'aria-valuemin', '0');
    this.domUtils.setAttribute(container, 'aria-valuemax', '100');

    if (config.ariaDescribedBy) {
      this.domUtils.setAttribute(container, 'aria-describedby', config.ariaDescribedBy);
    }

    if (this.config.accessibility.keyboardNavigation) {
      this.domUtils.setAttribute(container, 'tabindex', '0');
    }
  }

  /**
   * Assemble progress bar elements and track them
   * @param {HTMLElement} container - Progress bar container
   * @param {HTMLElement} progressBar - Progress bar element
   * @param {HTMLElement} progressFill - Progress fill element
   * @private
   */
  _assembleProgressBar(container, progressBar, progressFill) {
    this.domUtils.addClass(progressBar, 'progress-bar');
    this.domUtils.addClass(progressFill, 'progress-fill');

    this.domUtils.appendChild(progressBar, progressFill);
    this.domUtils.appendChild(container, progressBar);

    // Track all elements for cleanup
    this._trackCreatedElement(container);
    this._trackCreatedElement(progressBar);
    this._trackCreatedElement(progressFill);
  }

  /**
   * Apply annotations based on progress state using strategy pattern
   * @param {HTMLElement} labelElement - Label element to annotate
   * @param {string} progressState - Progress state
   * @param {Object} progressData - Progress data
   * @private
   */
  _applyStateAnnotations(labelElement, progressState, progressData) {
    const annotationStrategies = {
      'on-your-path': () => this._applyOnYourPathAnnotations(labelElement, progressData),
      'in-progress': () => this._applyInProgressAnnotations(labelElement, progressData),
      'completed': () => this._applyCompletedAnnotations(labelElement, progressData),
      'loading': () => this._applyLoadingAnnotations(labelElement),
      'not-selected': () => {} // No annotations for not-selected state
    };

    const strategy = annotationStrategies[progressState];
    if (strategy) {
      strategy();
    }
  }

  /**
   * Process items sequentially without batching
   * @param {NodeList} items - Items to process
   * @private
   */
  async _processItemsSequentially(items) {
    for (const item of items) {
      await this._processSingleItem(item);
    }
  }

  /**
   * Clean up event listeners during destroy
   * @private
   */
  _cleanupEventListeners() {
    this.eventListeners.forEach(({ element, event, handler }) => {
      try {
        this.domUtils.removeEventListener(element, event, handler);
      } catch (_error) {
        // Continue cleanup even if individual listener removal fails
      }
    });
    this.eventListeners = [];
  }

  /**
   * Clean up created DOM elements during destroy
   * @private
   */
  _cleanupCreatedElements() {
    this._createdElements.forEach(element => {
      try {
        if (element.parentNode) {
          element.parentNode.removeChild(element);
        }
      } catch (_error) {
        // Continue cleanup even if individual element removal fails
      }
    });
    this._createdElements.clear();
  }

  /**
   * Finalize the destroy process
   * @private
   */
  _finalizeDestroy() {
    // Mark as destroyed first
    this.isDestroyed = true;

    // Clear all references to prevent memory leaks
    this.errorHandler = null;
    this.learningPathManager = null;
    this.domUtils = null;
    this.config = null;
  }

  /**
   * Merge user configuration with defaults using optimized deep merge
   * @param {Object} userConfig - User-provided configuration
   * @returns {Object} Merged configuration
   * @private
   */
  _mergeConfiguration(userConfig) {
    // Optimized configuration merging with proper deep merge for nested objects
    return {
      ...ProgressAnnotations.DEFAULT_CONFIG,
      ...userConfig,
      cssClasses: {
        ...ProgressAnnotations.DEFAULT_CONFIG.cssClasses,
        ...userConfig.cssClasses
      },
      features: {
        ...ProgressAnnotations.DEFAULT_CONFIG.features,
        ...userConfig.features
      },
      accessibility: {
        ...ProgressAnnotations.DEFAULT_CONFIG.accessibility,
        ...userConfig.accessibility
      },
      animations: {
        ...ProgressAnnotations.DEFAULT_CONFIG.animations,
        ...userConfig.animations
      },
      performance: {
        ...ProgressAnnotations.DEFAULT_CONFIG.performance,
        ...userConfig.performance
      }
    };
  }

  /**
   * Set up integration with the learning path manager
   * @private
   */
  _setupLearningPathIntegration() {
    try {
      // Listen for progress updates
      const progressUpdateHandler = (event) => {
        this._handleProgressUpdate(event.detail);
      };

      this.domUtils.addEventListener(
        this.learningPathManager,
        'progressUpdate',
        progressUpdateHandler
      );

      this.eventListeners.push({
        element: this.learningPathManager,
        event: 'progressUpdate',
        handler: progressUpdateHandler
      });

      // Listen for path changes
      const pathChangeHandler = (event) => {
        this._handlePathChange(event.detail);
      };

      this.domUtils.addEventListener(
        this.learningPathManager,
        'pathChange',
        pathChangeHandler
      );

      this.eventListeners.push({
        element: this.learningPathManager,
        event: 'pathChange',
        handler: pathChangeHandler
      });
    } catch (error) {
      this.errorHandler.handleError(error, 'ProgressAnnotations._setupLearningPathIntegration');
    }
  }

  /**
   * Apply annotations for "on your path" state
   * @param {HTMLElement} labelElement - Label element to annotate
   * @param {Object} progressData - Progress data
   * @private
   */
  _applyOnYourPathAnnotations(labelElement, _progressData) {
    if (this.config.features.badges) {
      const badge = this.createProgressBadge(labelElement, {
        state: 'on-your-path',
        text: 'On Your Path',
        ariaLabel: 'This kata is on your selected learning path'
      });

      if (badge) {
        this.domUtils.appendChild(labelElement, badge);
      }
    }

    if (this.config.features.icons) {
      const icon = this.createProgressIcon(labelElement, {
        state: 'on-your-path',
        ariaLabel: 'On your path icon'
      });

      if (icon) {
        this.domUtils.appendChild(labelElement, icon);
      }
    }
  }

  /**
   * Apply annotations for "in progress" state
   * @param {HTMLElement} labelElement - Label element to annotate
   * @param {Object} progressData - Progress data
   * @private
   */
  _applyInProgressAnnotations(labelElement, progressData) {
    if (this.config.features.progressBars) {
      // Check for existing progress bar first
      let progressBar = this.domUtils.querySelector(labelElement, '.progress-bar-container');

      if (progressBar) {
        // Update existing progress bar
        const progressFill = this.domUtils.querySelector(progressBar, '.progress-fill');
        if (progressFill) {
          const percentage = Math.round(Math.max(0, Math.min(100, progressData.progress || 0)));
          this.domUtils.setAttribute(progressBar, 'data-progress', percentage.toString());
          this.domUtils.setAttribute(progressFill, 'style', `width: ${percentage}%`);
        }
      } else {
        // Create new progress bar
        progressBar = this.createProgressBar(labelElement, {
          progress: progressData.progress || 0,
          ariaDescribedBy: `progress-description-${Date.now()}`
        });

        if (progressBar) {
          this.domUtils.appendChild(labelElement, progressBar);
        }
      }
    }

    if (this.config.features.icons) {
      // Check for existing icon first
      let icon = this.domUtils.querySelector(labelElement, '.progress-icon');

      if (!icon) {
        icon = this.createProgressIcon(labelElement, {
          state: 'in-progress',
          ariaLabel: 'In progress icon'
        });

        if (icon) {
          this.domUtils.appendChild(labelElement, icon);
        }
      }
    }
  }

  /**
   * Apply annotations for "completed" state
   * @param {HTMLElement} labelElement - Label element to annotate
   * @param {Object} progressData - Progress data
   * @private
   */
  _applyCompletedAnnotations(labelElement, progressData) {
    if (this.config.features.scoreDisplays && progressData.score !== undefined) {
      const scoreDisplay = this.createScoreDisplay(labelElement, {
        score: progressData.score,
        ariaLabel: `Completed with score ${progressData.score}%`
      });

      if (scoreDisplay) {
        this.domUtils.appendChild(labelElement, scoreDisplay);
      }
    }
  }

  /**
   * Apply loading state annotations
   * @param {HTMLElement} labelElement - Label element to annotate
   * @private
   */
  _applyLoadingAnnotations(labelElement) {
    if (this.config.features.badges) {
      const badge = this.createProgressBadge(labelElement, {
        state: 'loading',
        text: 'Loading...',
        ariaLabel: 'Progress data is loading'
      });

      if (badge) {
        this.domUtils.addClass(badge, 'loading');
        this.domUtils.appendChild(labelElement, badge);
      }
    }
  }

  /**
   * Process items in batches for better performance
   * @param {NodeList} items - Items to process
   * @private
   */
  async _batchProcessItems(items) {
    const batchSize = 10;
    let currentIndex = 0;

    const processBatch = async () => {
      const endIndex = Math.min(currentIndex + batchSize, items.length);

      for (let i = currentIndex; i < endIndex; i++) {
        await this._processSingleItem(items[i]);
      }

      currentIndex = endIndex;

      if (currentIndex < items.length) {
        // Schedule next batch
        setTimeout(processBatch, 0);
      }
    };

    await processBatch();
  }

  /**
   * Process a single learning path item
   * @param {HTMLElement} item - Checkbox item to process
   * @private
   */
  async _processSingleItem(item) {
    try {
      const kataId = this.domUtils.getAttribute(item, 'data-kata-id');

      if (!kataId) {
        this.errorHandler.handleError(
          new Error('Missing kata ID for progress annotation'),
          'ProgressAnnotations._processSingleItem'
        );
        return;
      }

      const progressState = await this.detectProgressState(kataId);
      const progressData = await this.learningPathManager.getKataProgress(kataId);

      this.applyAnnotations(item.parentElement, progressState, progressData);
    } catch (error) {
      this.errorHandler.safeExecute(() => {
        this.errorHandler.handleError(error, 'ProgressAnnotations._processSingleItem');
      });
    }
  }

  /**
   * Handle progress updates from the learning path manager
   * @param {Object} updateData - Progress update data
   * @private
   */
  _handleProgressUpdate(updateData) {
    try {
      if (updateData.kataId) {
        // Find the checkbox for this kata and update its annotations
        const checkbox = this.domUtils.querySelector(
          document,
          `input[type="checkbox"][data-kata-id="${updateData.kataId}"]`
        );

        if (checkbox) {
          // Update progress bar if it exists
          const progressBar = this.domUtils.querySelector(
            checkbox.parentElement,
            '.progress-bar-container'
          );

          if (progressBar && updateData.progress !== undefined) {
            this.domUtils.setAttribute(progressBar, 'data-progress', updateData.progress.toString());

            const progressFill = this.domUtils.querySelector(progressBar, '.progress-fill');
            if (progressFill) {
              this.domUtils.setAttribute(progressFill, 'style', `width: ${updateData.progress}%`);
            }
          }
        }
      }
    } catch (error) {
      this.errorHandler.handleError(error, 'ProgressAnnotations._handleProgressUpdate');
    }
  }

  /**
   * Handle learning path changes
   * @param {Object} pathData - Path change data
   * @private
   */
  async _handlePathChange(_pathData) {
    try {
      // Re-process all items when the path changes
      const container = this.domUtils.querySelector(document, '.learning-paths');
      if (container) {
        await this.processLearningPathItems(container);
      }
    } catch (error) {
      this.errorHandler.handleError(error, 'ProgressAnnotations._handlePathChange');
    }
  }

  /**
   * Show loading state for elements
   * @param {HTMLElement} element - Element to show loading state for
   * @private
   */
  _showLoadingState(element) {
    this.domUtils.addClass(element, this.config.cssClasses.loadingState);
  }

  /**
   * Hide loading state for elements
   * @param {HTMLElement} element - Element to hide loading state for
   * @private
   */
  _hideLoadingState(element) {
    this.domUtils.removeClass(element, this.config.cssClasses.loadingState);
  }

  /**
   * Synchronize annotations with Learning Path Manager state
   * Updates all annotations based on current manager state
   */
  async syncWithManager() {
    if (this.isDestroyed) {return;}

    try {
      const container = this.domUtils.querySelector(document, '.learning-paths');
      if (container) {
        await this.processLearningPathItems(container);
      }
    } catch (error) {
      this.errorHandler.handleError(error, 'ProgressAnnotations.syncWithManager');
    }
  }

  /**
   * Handle progress updates from the Learning Path Manager
   * @param {string} kataId - ID of the kata being updated
   * @param {number} progress - New progress value (0-1)
   */
  onProgressUpdate(kataId, progress) {
    if (this.isDestroyed) {return;}

    try {
      // Find all elements related to this kata
      const elements = this.domUtils.querySelectorAll(document, `[data-kata-id="${kataId}"]`);

      elements.forEach(element => {
        const progressBars = this.domUtils.querySelectorAll(element, '.progress-bar');
        progressBars.forEach(bar => {
          const percentage = Math.round(progress * 100);
          this.domUtils.setAttribute(bar, 'data-progress', percentage.toString());

          const fill = this.domUtils.querySelector(bar, '.progress-fill');
          if (fill) {
            this.domUtils.setAttribute(fill, 'style', `width: ${percentage}%`);
          }
        });
      });
    } catch (error) {
      this.errorHandler.handleError(error, 'ProgressAnnotations.onProgressUpdate');
    }
  }

  // ============================================================================
  // E2E Test Support Methods
  // ============================================================================

  /**
   * Ensure accessibility compliance for E2E testing
   * Validates that all progress annotations meet WCAG 2.1 AA standards
   * @returns {Object} Accessibility compliance report
   */
  ensureAccessibilityCompliance() {
    if (this.isDestroyed) {
      return { isCompliant: false, issues: ['Component is destroyed'] };
    }

    const issues = [];
    const report = {
      isCompliant: true,
      issues: [],
      checkedElements: 0,
      timestamp: Date.now()
    };

    try {
      // Check all progress elements for accessibility
      const progressElements = this.domUtils.querySelectorAll(document,
        `.${this.config.cssClasses.progressBadge}, .${this.config.cssClasses.progressBar}, .${this.config.cssClasses.scoreDisplay}`
      );

      progressElements.forEach((element, index) => {
        report.checkedElements++;

        // Check for ARIA labels
        const ariaLabel = element.getAttribute('aria-label');
        const ariaDescribedBy = element.getAttribute('aria-describedby');

        if (!ariaLabel && !ariaDescribedBy) {
          issues.push(`Progress element ${index} missing ARIA label or description`);
        }

        // Check for role attributes where needed
        if (element.classList.contains(this.config.cssClasses.progressBar)) {
          const role = element.getAttribute('role');
          if (role !== 'progressbar') {
            issues.push(`Progress bar ${index} missing or incorrect role attribute`);
          }

          // Check for aria-valuenow, aria-valuemin, aria-valuemax
          const valueNow = element.getAttribute('aria-valuenow');
          const valueMin = element.getAttribute('aria-valuemin');
          const valueMax = element.getAttribute('aria-valuemax');

          if (!valueNow || !valueMin || !valueMax) {
            issues.push(`Progress bar ${index} missing required ARIA value attributes`);
          }
        }

        // Check color contrast (basic check)
        const computedStyle = window.getComputedStyle(element);
        const backgroundColor = computedStyle.backgroundColor;
        const _color = computedStyle.color;

        if (backgroundColor === 'rgba(0, 0, 0, 0)' || backgroundColor === 'transparent') {
          // Element relies on inherited background - check parent
          const parent = element.parentElement;
          if (parent) {
            const parentStyle = window.getComputedStyle(parent);
            if (parentStyle.backgroundColor === 'rgba(0, 0, 0, 0)') {
              issues.push(`Progress element ${index} may have insufficient color contrast`);
            }
          }
        }
      });

      report.issues = issues;
      report.isCompliant = issues.length === 0;

      return report;
    } catch (error) {
      this.errorHandler.handleError(error, 'ProgressAnnotations.ensureAccessibilityCompliance');
      return {
        isCompliant: false,
        issues: [`Error during accessibility check: ${error.message}`],
        checkedElements: 0,
        timestamp: Date.now()
      };
    }
  }

  /**
   * Get all progress states for E2E testing
   * @returns {Object} Map of kata IDs to their progress states
   */
  getAllProgressStates() {
    if (this.isDestroyed) {
      return {};
    }

    const states = {};

    try {
      const kataElements = this.domUtils.querySelectorAll(document, '[data-kata-id]');

      kataElements.forEach(element => {
        const kataId = element.getAttribute('data-kata-id');
        if (kataId) {
          states[kataId] = this.detectProgressState(kataId);
        }
      });

      return states;
    } catch (error) {
      this.errorHandler.handleError(error, 'ProgressAnnotations.getAllProgressStates');
      return {};
    }
  }

  /**
   * Force refresh all progress annotations for E2E testing
   * @returns {boolean} Success status
   */
  async refreshAllAnnotations() {
    if (this.isDestroyed) {
      return false;
    }

    try {
      const container = this.domUtils.querySelector(document, '.learning-paths');
      if (container) {
        await this.processLearningPathItems(container);
        return true;
      }
      return false;
    } catch (error) {
      this.errorHandler.handleError(error, 'ProgressAnnotations.refreshAllAnnotations');
      return false;
    }
  }

  /**
   * Get performance metrics for E2E testing
   * @returns {Object} Performance metrics
   */
  getPerformanceMetrics() {
    return {
      batchQueue: this.batchQueue?.length || 0,
      isProcessing: this.isProcessing || false,
      processedCount: this.processedCount || 0,
      errorCount: this.errorCount || 0,
      lastProcessTime: this.lastProcessTime || null,
      averageProcessTime: this.averageProcessTime || 0,
      memoryUsage: this._getMemoryUsage()
    };
  }

  /**
   * Validate component state for E2E testing
   * @returns {Object} Validation result
   */
  validateComponentState() {
    const validation = {
      isValid: true,
      issues: [],
      timestamp: Date.now()
    };

    try {
      // Check if component is properly initialized
      if (this.isDestroyed) {
        validation.isValid = false;
        validation.issues.push('Component is destroyed');
        return validation;
      }

      // Check dependencies
      if (!this.errorHandler) {
        validation.isValid = false;
        validation.issues.push('Missing errorHandler dependency');
      }

      if (!this.learningPathManager) {
        validation.isValid = false;
        validation.issues.push('Missing learningPathManager dependency');
      }

      if (!this.domUtils) {
        validation.isValid = false;
        validation.issues.push('Missing domUtils dependency');
      }

      // Check configuration
      if (!this.config) {
        validation.isValid = false;
        validation.issues.push('Missing configuration');
      }

      // Check if DOM elements are accessible
      const testContainer = this.domUtils.querySelector(document, 'body');
      if (!testContainer) {
        validation.isValid = false;
        validation.issues.push('Cannot access DOM');
      }

      // Check for memory leaks
      const memoryUsage = this._getMemoryUsage();
      if (memoryUsage.createdElements > 1000) {
        validation.issues.push('Potential memory leak: too many created elements');
      }

      return validation;
    } catch (_error) {
      validation.isValid = false;
      validation.issues.push(`Validation error: ${_error.message}`);
      return validation;
    }
  }

  /**
   * Simulate error for E2E testing
   * @param {string} errorType - Type of error to simulate
   */
  async simulateError(errorType) {
    switch (errorType) {
      case 'dom-access':
        this.domUtils = null;
        break;
      case 'learning-path-manager':
        this.learningPathManager = null;
        break;
      case 'invalid-state':
        this.config = null;
        break;
      case 'processing-error':
        await this.processLearningPathItems(null);
        break;
      default:
        throw new Error(`Unknown error type: ${errorType}`);
    }
  }

  /**
   * Get memory usage information for performance monitoring
   * @returns {Object} Memory usage data
   * @private
   */
  _getMemoryUsage() {
    return {
      createdElements: this.createdElements?.size || 0,
      batchQueueSize: this.batchQueue?.length || 0,
      configSize: JSON.stringify(this.config || {}).length,
      hasListeners: !!this.eventListeners && this.eventListeners.length > 0
    };
  }
}
