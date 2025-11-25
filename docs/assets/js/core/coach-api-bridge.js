/**
 * Coach API Bridge
 * Provides API bridge for Kata Coach integration with progress tracking
 * Version: 3.0.0
 */

/**
 * Coach API Bridge
 * Provides comprehensive API bridge for Kata Coach integration with progress tracking
 * @class CoachApiBridge
 */
class CoachApiBridge {
  /**
   * Constructor with dependency injection
   * @param {Object} [dependencies={}] - Injected dependencies
   * @param {Object} [dependencies.debugHelper] - Debug logging service
   * @param {Object} [dependencies.errorHandler] - Error handling service
   * @param {Object} [dependencies.storageManager] - Storage management service
   * @param {Object} [dependencies.learningPathManager] - Learning path management service
   * @param {Object} [dependencies.progressBarManager] - Progress bar management service
   * @param {Object} [dependencies.completionHandler] - Completion handling service
   */
  constructor(dependencies = {}) {
    try {
      // Dependency injection - no global fallbacks
      this.debugHelper = dependencies.debugHelper || null;
      this.errorHandler = dependencies.errorHandler || null;
      this.storage = dependencies.storageManager || null;
      this.learningPath = dependencies.learningPathManager || null;
      this.progressBar = dependencies.progressBarManager || null;
      this.completion = dependencies.completionHandler || null;

      // Core state
      this.currentContext = null;

      this.logDebug('CoachApiBridge initialized successfully');
    } catch (error) {
      this.handleError('Failed to initialize CoachApiBridge', error);
      throw error;
    }
  }

  /**
   * Log debug message if debug helper is available
   * @param {string} message - Debug message
   * @param {*} [data] - Optional data to log
   * @private
   */
  logDebug(message, data = null) {
    if (this.debugHelper && typeof this.debugHelper.log === 'function') {
      this.debugHelper?.log?.(message, data);
    } else if (this.debugHelper && typeof this.debugHelper.debug === 'function') {
      this.debugHelper.debug(message, data);
    }
  }

  /**
   * Handle error with error handler if available
   * @param {string} message - Error message
   * @param {Error} error - Error object
   * @private
   */
  handleError(message, error) {
    if (this.errorHandler && typeof this.errorHandler.handleError === 'function') {
      this.errorHandler.handleError(error, {
        context: 'CoachApiBridge',
        operation: message
      });
    }
  }

  /**
   * Safe execution wrapper
   * @param {Function} fn - Function to execute safely
   * @param {string} operation - Operation name for error reporting
   * @param {*} defaultValue - Default value to return on error
   * @returns {*} Function result or default value
   * @private
   */
  safeExecute(fn, operation, defaultValue) {
    try {
      if (this.errorHandler && typeof this.errorHandler.safeExecute === 'function') {
        return this.errorHandler.safeExecute(fn, operation, defaultValue);
      } else {
        return fn();
      }
    } catch (error) {
      this.handleError(`Failed to execute ${operation}`, error);
      return defaultValue;
    }
  }

  /**
   * Set the current kata context
   * @param {Object} context - Learning context
   */
  setContext(context) {
    try {
      this.currentContext = context;
      this.logDebug('Context set', context);
    } catch (error) {
      this.handleError('Failed to set context', error);
    }
  }

  /**
   * Create the global Coach API for the current kata
   * @param {Object} context - Learning context
   * @returns {Object|null} Coach API object
   */
  createCoachAPI(context) {
    return this.safeExecute(() => {
      this.setContext(context);

      const api = {
        // Progress Control Methods
        markTaskComplete: (taskIndex) => this.markTaskComplete(taskIndex),
        setKataProgress: (percentage) => this.setKataProgress(percentage),
        incrementProgress: (amount = 10) => this.incrementProgress(amount),

        // Context and State Queries
        getCurrentContext: () => this.getCurrentContext(),
        getProgressState: () => this.getProgressState(),
        getCompletionStatus: () => this.getCompletionStatus(),

        // Coach Adaptation Methods
        getNextRecommendation: () => this.getNextRecommendation(),
        getSuggestedActions: () => this.getSuggestedActions(),
        getLearningSuggestions: () => this.getLearningSuggestions(),

        // Utility Methods
        refreshProgressBar: () => this.refreshProgressBar(),
        triggerEvaluation: () => this.triggerEvaluation(),
        resetProgress: () => this.resetProgress()
      };

      this.logDebug('Coach API created', { context, api });
      return api;
    }, 'createCoachAPI', null);
  }

  /**
   * Mark a specific task as complete
   * @param {number} taskIndex - Index of the task to mark complete
   * @returns {Object|null} Updated progress data
   */
  markTaskComplete(taskIndex) {
    return this.safeExecute(() => {
      if (!this.currentContext) {
        this.logDebug('No current context available for task completion');
        return null;
      }

      if (typeof taskIndex !== 'number' || taskIndex < 0) {
        throw new Error('Invalid task index provided');
      }

      const fullKataId = `${this.currentContext.categoryId}/${this.currentContext.kataId}`;
      const currentProgress = this.storage?.getKataProgress(fullKataId) || {
        completionPercentage: 0,
        completedTasks: 0,
        totalTasks: 10,
        timeSpent: 0
      };

      // Calculate new progress - simple increment approach
      const increment = 100 / (currentProgress.totalTasks || 10);
      const newPercentage = Math.min(100, currentProgress.completionPercentage + increment);

      const updatedProgress = {
        ...currentProgress,
        completionPercentage: Math.round(newPercentage),
        completedTasks: Math.min(currentProgress.totalTasks || 10, (currentProgress.completedTasks || 0) + 1),
        lastUpdated: Date.now(),
        timeSpent: (currentProgress.timeSpent || 0) + 5 // Add 5 minutes per task
      };

      // Save progress
      this.storage?.saveKataProgress(fullKataId, updatedProgress);

      // Update progress bar
      this.progressBar?.updateProgressBar(this.currentContext, updatedProgress);

      // Check for completion
      this.completion?.checkCompletion(updatedProgress, this.currentContext);

      this.logDebug('Task completion update:', {
        taskIndex,
        newPercentage: updatedProgress.completionPercentage,
        context: this.currentContext
      });

      return updatedProgress;
    }, 'markTaskComplete', null);
  }

  /**
   * Set kata progress to specific percentage
   * @param {number} percentage - Progress percentage (0-100)
   * @returns {Object|null} Updated progress data
   */
  setKataProgress(percentage) {
    return this.safeExecute(() => {
      if (!this.currentContext) {
        this.logDebug('No current context available for progress update');
        return null;
      }

      if (typeof percentage !== 'number') {
        throw new Error('Progress percentage must be a number');
      }

      const fullKataId = `${this.currentContext.categoryId}/${this.currentContext.kataId}`;
      const currentProgress = this.storage?.getKataProgress(fullKataId) || {
        completedTasks: 0,
        totalTasks: 10,
        timeSpent: 0
      };

      const clampedPercentage = Math.min(100, Math.max(0, percentage));
      const calculatedTasks = Math.round((clampedPercentage / 100) * (currentProgress.totalTasks || 10));

      const updatedProgress = {
        ...currentProgress,
        completionPercentage: Math.round(clampedPercentage),
        completedTasks: calculatedTasks,
        lastUpdated: Date.now()
      };

      // Save progress
      this.storage?.saveKataProgress(fullKataId, updatedProgress);

      // Update progress bar
      this.progressBar?.updateProgressBar(this.currentContext, updatedProgress);

      // Check for completion
      this.completion?.checkCompletion(updatedProgress, this.currentContext);

      this.logDebug('Kata progress set:', {
        percentage: clampedPercentage,
        context: this.currentContext
      });

      return updatedProgress;
    }, 'setKataProgress', null);
  }

  /**
   * Increment kata progress by amount
   * @param {number} amount - Amount to increment (default 10%)
   * @returns {Object|null} Updated progress data
   */
  incrementProgress(amount = 10) {
    return this.safeExecute(() => {
      if (!this.currentContext) {
        this.logDebug('No current context available for progress increment');
        return null;
      }

      if (typeof amount !== 'number') {
        throw new Error('Progress increment amount must be a number');
      }

      const fullKataId = `${this.currentContext.categoryId}/${this.currentContext.kataId}`;
      const currentProgress = this.storage?.getKataProgress(fullKataId) || { completionPercentage: 0 };

      const newPercentage = currentProgress.completionPercentage + amount;
      return this.setKataProgress(newPercentage);
    }, 'incrementProgress', null);
  }

  /**
   * Get current learning context
   * @returns {Object|null} Current context
   */
  getCurrentContext() {
    return this.currentContext;
  }

  /**
   * Get current progress state
   * @returns {Object|null} Progress state
   */
  getProgressState() {
    return this.safeExecute(() => {
      if (!this.currentContext || !this.storage) {
        return null;
      }

      const fullKataId = `${this.currentContext.categoryId}/${this.currentContext.kataId}`;
      return this.storage.getKataProgress(fullKataId);
    }, 'getProgressState', null);
  }

  /**
   * Get completion status
   * @returns {Object|null} Completion status
   */
  getCompletionStatus() {
    try {
      return this.completion?.getCompletionStatus(this.currentContext) || null;
    } catch (error) {
      this.handleError('Failed to get completion status', error);
      return null;
    }
  }

  /**
   * Get next recommendation for learning
   * @returns {Object|null} Recommendation data
   */
  getNextRecommendation() {
    return this.safeExecute(() => {
      if (!this.currentContext || !this.learningPath) {
        return null;
      }

      const progress = this.getProgressState();
      const isCompleted = progress && progress.completionPercentage >= 100;

      if (isCompleted) {
        // Suggest next kata in the learning path
        const nextKata = this.learningPath.getNextKata(this.currentContext.categoryId, this.currentContext.kataId);

        if (nextKata) {
          return {
            type: 'next-kata',
            message: `Ready for the next challenge? Try "${nextKata.title}"`,
            action: {
              type: 'navigate',
              url: nextKata.url,
              kata: nextKata
            }
          };
        } else {
          return {
            type: 'category-complete',
            message: 'Congratulations! You\'ve completed this learning path. Consider exploring other categories.',
            action: {
              type: 'browse-categories'
            }
          };
        }
      } else {
        return {
          type: 'continue-current',
          message: `Continue working on "${this.currentContext.kataId.replace(/-/g, ' ')}" (${progress?.completionPercentage || 0}% complete)`,
          action: {
            type: 'focus-current'
          }
        };
      }
    }, 'getNextRecommendation', null);
  }

  /**
   * Get suggested actions based on current state
   * @returns {Array} Array of suggested actions
   */
  getSuggestedActions() {
    return this.safeExecute(() => {
      const progress = this.getProgressState();
      const suggestions = [];

      if (!progress || progress.completionPercentage === 0) {
        suggestions.push({
          type: 'start',
          message: 'Start working through the kata step by step',
          priority: 'high'
        });
      } else if (progress.completionPercentage < 50) {
        suggestions.push({
          type: 'continue',
          message: 'Keep going! You\'re making good progress',
          priority: 'medium'
        });
      } else if (progress.completionPercentage < 100) {
        suggestions.push({
          type: 'finish',
          message: 'You\'re almost done! Push through to complete this kata',
          priority: 'high'
        });
      } else {
        suggestions.push({
          type: 'evaluate',
          message: 'Complete a self-evaluation to reflect on your learning',
          priority: 'medium'
        });
      }

      return suggestions;
    }, 'getSuggestedActions', []);
  }

  /**
   * Get learning suggestions based on progress patterns
   * @returns {Array} Array of learning suggestions
   */
  getLearningSuggestions() {
    return this.safeExecute(() => {
      // This could be enhanced with AI/ML recommendations
      const suggestions = [
        'Take notes while working through the kata',
        'Try to understand the "why" behind each step',
        'Practice the concepts in a real project',
        'Discuss your learning with peers or mentors'
      ];

      return suggestions.map(suggestion => ({
        type: 'learning-tip',
        message: suggestion,
        priority: 'low'
      }));
    }, 'getLearningSuggestions', []);
  }

  /**
   * Refresh the progress bar display
   * @returns {boolean} Success status
   */
  refreshProgressBar() {
    return this.safeExecute(() => {
      if (!this.currentContext || !this.progressBar) {
        return false;
      }

      const progress = this.getProgressState();
      if (progress) {
        this.progressBar.updateProgressBar(this.currentContext, progress);
        return true;
      }

      return false;
    }, 'refreshProgressBar', false);
  }

  /**
   * Manually trigger evaluation prompt
   * @returns {boolean} Success status
   */
  triggerEvaluation() {
    return this.safeExecute(() => {
      if (!this.currentContext || !this.completion) {
        return false;
      }

      this.completion.showEvaluationPrompt(this.currentContext);
      return true;
    }, 'triggerEvaluation', false);
  }

  /**
   * Reset progress for current kata
   * @returns {boolean} Success status
   */
  resetProgress() {
    return this.safeExecute(() => {
      if (!this.currentContext || !this.storage) {
        return false;
      }

      const fullKataId = `${this.currentContext.categoryId}/${this.currentContext.kataId}`;
      const resetProgress = {
        completionPercentage: 0,
        completedTasks: 0,
        totalTasks: 10,
        timeSpent: 0,
        lastUpdated: Date.now()
      };

      this.storage.saveKataProgress(fullKataId, resetProgress);
      this.progressBar?.updateProgressBar(this.currentContext, resetProgress);

      this.logDebug('Progress reset for kata', { fullKataId });
      return true;
    }, 'resetProgress', false);
  }

  /**
   * Cleanup API
   */
  cleanup() {
    try {
      this.currentContext = null;
      this.logDebug('CoachApiBridge cleaned up');
    } catch (error) {
      this.handleError('Failed to cleanup CoachApiBridge', error);
    }
  }
}

// ES6 Module Export
export default CoachApiBridge;
