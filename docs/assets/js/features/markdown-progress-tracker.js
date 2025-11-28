/**
 * Custom error class for MarkdownProgressTracker operations
 * @class MarkdownProgressTrackerError
 * @extends Error
 */
export class MarkdownProgressTrackerError extends Error {
  /**
   * Creates a new MarkdownProgressTrackerError
   * @param {string} message - Error message
   * @param {string|null} operation - Operation that caused the error
   * @param {Error|null} cause - Original error that caused this error
   */
  constructor(message, operation = null, cause = null) {
    super(message);
    this.name = 'MarkdownProgressTrackerError';
    this.operation = operation;
    this.cause = cause;

    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, MarkdownProgressTrackerError);
    }
  }
}

/**
 * Markdown Progress Tracker - Enhanced progress feedback for learning paths
 *
 * Provides enhanced markdown-based progress feedback for learning paths with:
 * - Overall progress percentage display
 * - Path completion statistics
 * - Milestone achievement indicators
 * - Seamless Docsify integration
 *
 * @class MarkdownProgressTracker
 */
export class MarkdownProgressTracker {
  /**
   * Creates an instance of MarkdownProgressTracker
   * @param {Object} dependencies - Required dependencies
   * @param {Object} dependencies.domUtils - DOM utility functions
   * @param {Object} dependencies.learningPathManager - Learning path management system
   * @param {Object} dependencies.errorHandler - Error handling system
   * @param {Object} [config={}] - Configuration options
   */
  constructor(dependencies, config = {}) {
    this._validateDependencies(dependencies);

    this.domUtils = dependencies.domUtils;
    this.learningPathManager = dependencies.learningPathManager;
    this.errorHandler = dependencies.errorHandler;

    // Default configuration
    this.config = {
      selectors: {
        progressContainer: '[data-progress-container]',
        progressText: '[data-progress-text]',
        statisticsContainer: '[data-statistics-container]',
        milestonesContainer: '[data-milestones-container]'
      },
      features: {
        overallProgress: true,
        pathStatistics: true,
        milestoneIndicators: true,
        achievementBadges: true
      },
      formatting: {
        percentageDecimals: 1,
        showPathNames: true,
        showKataCount: true,
        highlightMilestones: true
      },
      updateInterval: 1000,
      ...config
    };

    // Support legacy configuration format
    if (config.progressContainerSelector) {
      this.config.selectors.progressContainer = config.progressContainerSelector;
    }
    if (config.statisticsContainerSelector) {
      this.config.selectors.statisticsContainer = config.statisticsContainerSelector;
    }
    if (config.milestonesContainerSelector) {
      this.config.selectors.milestonesContainer = config.milestonesContainerSelector;
    }
    if (config.enableProgressDisplay !== undefined) {
      this.config.features.overallProgress = config.enableProgressDisplay;
    }
    if (config.enableStatistics !== undefined) {
      this.config.features.pathStatistics = config.enableStatistics;
    }
    if (config.enableMilestones !== undefined) {
      this.config.features.milestoneIndicators = config.enableMilestones;
    }

    // Support custom selectors configuration
    if (config.selectors) {
      if (config.selectors.progressContainer) {
        this.config.selectors.progressContainer = config.selectors.progressContainer;
      }
      if (config.selectors.statisticsContainer) {
        this.config.selectors.statisticsContainer = config.selectors.statisticsContainer;
      }
      if (config.selectors.milestonesContainer) {
        this.config.selectors.milestonesContainer = config.selectors.milestonesContainer;
      }
    }

    this._isDestroyed = false;
    this._eventListeners = new Map();
    this._createdElements = new Set();
    this._isUpdating = false;
  }

  /**
   * Gets the destroyed state of the tracker
   * @returns {boolean} True if the tracker has been destroyed
   */
  get isDestroyed() {
    return this._isDestroyed;
  }

  /**
   * Validates required dependencies
   * @private
   * @param {Object} dependencies - Dependencies object to validate
   * @throws {MarkdownProgressTrackerError} When required dependencies are missing
   */
  _validateDependencies(dependencies) {
    if (!dependencies?.domUtils) {
      throw new MarkdownProgressTrackerError('MarkdownProgressTracker requires domUtils dependency');
    }
    if (!dependencies?.learningPathManager) {
      throw new MarkdownProgressTrackerError('MarkdownProgressTracker requires learningPathManager dependency');
    }
    if (!dependencies?.errorHandler) {
      throw new MarkdownProgressTrackerError('MarkdownProgressTracker requires errorHandler dependency');
    }
  }

  /**
   * Initializes the markdown progress tracker with event listeners and initial update
   * @public
   * @throws {MarkdownProgressTrackerError} When initialization fails
   */
  initialize() {
    if (this._isDestroyed) {return;}

    try {
      this._setupEventListeners();
      this.updateAllProgressIndicators();
    } catch (error) {
      this.errorHandler.handleError(error, 'MarkdownProgressTracker.initialize');
    }
  }

  /**
   * Sets up event listeners for learning path updates with throttled handlers
   * @private
   */
  _setupEventListeners() {
    const pathUpdateHandler = () => this.updateAllProgressIndicators();

    this.learningPathManager.addEventListener('pathUpdated', pathUpdateHandler);
    this.learningPathManager.addEventListener('progressChanged', pathUpdateHandler);

    this._eventListeners.set('pathUpdated', pathUpdateHandler);
    this._eventListeners.set('progressChanged', pathUpdateHandler);
  }

  /**
   * Updates all progress indicators on the page
   * Refreshes overall progress, path statistics, and milestone displays
   * @public
   * @throws {MarkdownProgressTrackerError} When update operations fail
   */
  updateAllProgressIndicators() {
    if (this._isDestroyed || this._isUpdating) {return;}

    this._isUpdating = true;

    try {
      if (this.config.features.overallProgress) {
        this.updateOverallProgress();
      }

      if (this.config.features.pathStatistics) {
        this.updatePathStatistics();
      }

      if (this.config.features.milestoneIndicators) {
        this.updateMilestones();
      }
    } catch (error) {
      this.errorHandler.handleError(error, 'MarkdownProgressTracker.updateAllProgressIndicators');
    } finally {
      this._isUpdating = false;
    }
  }

  /**
   * Updates overall progress display
   */
  updateOverallProgress() {
    if (this._isDestroyed) {return;}

    try {
      const progressData = this.learningPathManager.getOverallProgress();
      const container = this.domUtils.querySelector(document, this.config.selectors.progressContainer);

      if (!container) {return;}

      const progressText = this._formatProgressText(progressData);
      const progressElement = this.domUtils.createElement('p');

      this.domUtils.addClass(progressElement, 'progress-summary');
      this.domUtils.setTextContent(progressElement, progressText);

      // Clear previous content and add new progress display
      this.domUtils.clearElement(container);
      this.domUtils.appendChild(container, progressElement);

      this._trackCreatedElement(progressElement);
    } catch (error) {
      this.errorHandler.handleError(error, 'MarkdownProgressTracker.updateOverallProgress');
    }
  }

  /**
   * Tracks a DOM element created by this tracker for cleanup
   * @private
   * @param {HTMLElement} element - Element to track
   */
  _trackCreatedElement(element) {
    if (element && !this._isDestroyed) {
      this._createdElements.add(element);
    }
  }

  /**
   * Updates path completion statistics
   */
  updatePathStatistics() {
    if (this._isDestroyed) {return;}

    try {
      const statisticsData = this.learningPathManager.getCompletionStatistics();
      const container = this.domUtils.querySelector(document, this.config.selectors.statisticsContainer);

      if (!container) {return;}

      // Clear previous content
      this.domUtils.clearElement(container);

      if (!statisticsData || statisticsData.length === 0) {
        const emptyMessage = this.domUtils.createElement('p');
        this.domUtils.setTextContent(emptyMessage, 'No learning path statistics available.');
        this.domUtils.appendChild(container, emptyMessage);
        this._trackCreatedElement(emptyMessage);
        return;
      }

      const statisticsList = this.domUtils.createElement('ul');
      this.domUtils.addClass(statisticsList, 'path-statistics');

      statisticsData.forEach(pathStat => {
        const listItem = this.domUtils.createElement('li');
        const statText = this._formatPathStatistic(pathStat);
        this.domUtils.setTextContent(listItem, statText);
        this.domUtils.appendChild(statisticsList, listItem);
        this._trackCreatedElement(listItem);
      });

      this.domUtils.appendChild(container, statisticsList);
      this._trackCreatedElement(statisticsList);
    } catch (error) {
      this.errorHandler.handleError(error, 'MarkdownProgressTracker.updatePathStatistics');
    }
  }

  /**
   * Updates milestone indicators
   */
  updateMilestones() {
    if (this._isDestroyed) {return;}

    try {
      const milestonesData = this.learningPathManager.getMilestones();
      const container = this.domUtils.querySelector(document, this.config.selectors.milestonesContainer);

      if (!container) {return;}

      // Clear previous content
      this.domUtils.clearElement(container);

      if (!milestonesData || milestonesData.length === 0) {
        return;
      }

      milestonesData.forEach(milestone => {
        const milestoneElement = this.domUtils.createElement('div');
        this.domUtils.addClass(milestoneElement, 'milestone-indicator');

        if (milestone.achieved) {
          this.domUtils.addClass(milestoneElement, 'milestone-achieved');
        } else {
          this.domUtils.addClass(milestoneElement, 'milestone-pending');
        }

        const milestoneText = this._formatMilestone(milestone);
        this.domUtils.setTextContent(milestoneElement, milestoneText);

        this.domUtils.appendChild(container, milestoneElement);
        this._trackCreatedElement(milestoneElement);
      });
    } catch (error) {
      this.errorHandler.handleError(error, 'MarkdownProgressTracker.updateMilestones');
    }
  }

  /**
   * Formats progress text with percentage
   * @private
   * @param {Object} progressData - Progress data from learning path manager
   * @returns {string} Formatted progress text
   */
  _formatProgressText(progressData) {
    if (!progressData) {return 'No progress data available';}

    const rawPercentage = progressData.overallProgress || progressData.percentage || 0;
    // Format to 2 decimal places, then remove trailing zeros
    let percentage = rawPercentage.toFixed(2);
    // Remove trailing zeros and decimal point if not needed
    percentage = percentage.replace(/\.?0+$/, '');
    // Ensure at least one decimal place for whole numbers
    if (!percentage.includes('.')) {
      percentage += '.0';
    }

    const completed = progressData.completedKatas || progressData.completed || 0;
    const total = progressData.totalKatas || progressData.total || 0;

    return `Progress: ${percentage}% (${completed} of ${total} completed)`;
  }

  /**
   * Formats path statistic information
   * @private
   * @param {Object} pathStat - Path statistic data
   * @returns {string} Formatted statistic text
   */
  _formatPathStatistic(pathStat) {
    const pathName = pathStat.pathName || pathStat.name || 'Unknown Path';
    const percentage = (pathStat.percentage || pathStat.progress || 0).toFixed(1);
    const completed = pathStat.completed || 0;
    const total = pathStat.total || 0;

    return `${pathName}: ${percentage}% (${completed}/${total})`;
  }

  /**
   * Creates a progress block element with Docsify-compatible styling
   * @private
   * @param {string} content - Content for the progress block
   * @returns {HTMLElement} Progress block element
   */
  _createProgressBlock(content) {
    const progressBlock = this.domUtils.createElement('div');
    this.domUtils.addClass(progressBlock, 'progress-block');
    this.domUtils.addClass(progressBlock, 'docsify-compatible');
    this.domUtils.setTextContent(progressBlock, content);

    this._trackCreatedElement(progressBlock);
    return progressBlock;
  }

  /**
   * Formats milestone information
   * @private
   * @param {Object} milestone - Milestone data
   * @returns {string} Formatted milestone text
   */
  _formatMilestone(milestone) {
    const title = milestone.title || 'Unknown milestone';
    const description = milestone.description || '';

    if (milestone.achieved) {
      const completedDate = milestone.completedDate
        ? new Date(milestone.completedDate).toLocaleDateString()
        : 'Recently';
      return `✅ ${title} - ${description} (Completed: ${completedDate})`;
    } else {
      const progress = milestone.progress ? `${(milestone.progress * 100).toFixed(0)}%` : '0%';
      return `🎯 ${title} - ${description} (Progress: ${progress})`;
    }
  }

  /**
   * Synchronizes the tracker with the learning path manager's current state
   * @public
   */
  syncWithManager() {
    if (this._isDestroyed) {return;}

    try {
      // Get latest state from manager and update all indicators
      this.updateAllProgressIndicators();
    } catch (error) {
      this.errorHandler.handleError(error, 'MarkdownProgressTracker.syncWithManager');
    }
  }

  /**
   * Destroys the markdown progress tracker and cleans up resources
   */
  destroy() {
    if (this._isDestroyed) {return;}

    try {
      // Remove event listeners
      this._eventListeners.forEach((handler, event) => {
        this.learningPathManager.removeEventListener(event, handler);
      });
      this._eventListeners.clear();

      // Remove created elements
      this._createdElements.forEach(element => {
        if (element && element.parentNode) {
          element.parentNode.removeChild(element);
        }
      });
      this._createdElements.clear();

      // Clear references
      this.domUtils = null;
      this.learningPathManager = null;
      this.errorHandler = null;
      this.config = null;

      this._isDestroyed = true;
    } catch (_error) {
      // Handle cleanup errors silently to prevent cascading issues
    }
  }
}

// ES6 Module Export
export default MarkdownProgressTracker;
