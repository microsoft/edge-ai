/**
 * Progress Clear Manager
 * Handles clearing/resetting of learning progress data
 */

import { StorageManager } from '../core/storage-manager.js';
import { LearningPathManager } from '../core/learning-path-manager.js';
import { ErrorHandler } from '../core/error-handler.js';

export class ProgressClearManager {
  constructor(dependencies = {}) {
    this.storageManager = new StorageManager();
    this.errorHandler = new ErrorHandler();
    this.enhancedProgressDataModel = dependencies.enhancedProgressDataModel || null;

    // Create required dependencies for LearningPathManager
    const debugHelper = {
      log: () => {},
      warn: () => {},
      error: () => {}
    };

    // Initialize LearningPathManager with required dependencies
    try {
      this.learningPathManager = new LearningPathManager({
        debugHelper,
        errorHandler: this.errorHandler,
        storageManager: this.storageManager,
        config: {}
      });
    } catch (_error) {
      // Failed to initialize LearningPathManager - continue silently
      this.learningPathManager = null;
    }

    this.isClearing = false;

    // Bind methods
    this.handleClearRequest = this.handleClearRequest.bind(this);

    this.initialize();
    console.log('ProgressClearManager initialized');
  }

  /**
   * Initialize the clear manager
   */
  initialize() {
    // Listen for clear requests from FloatingProgressBar
    document.addEventListener('progressClearRequested', this.handleClearRequest);
  }

  /**
   * Handle clear request from progress bar
   * @param {CustomEvent} event - Clear request event
   */
  async handleClearRequest(event) {
    if (this.isClearing) {
      console.warn('Clear operation already in progress');
      return;
    }

    try {
      this.isClearing = true;
      const { kataId, _timestamp } = event.detail;

      // Determine clear scope
      const clearScope = await this.determineClearScope(kataId);

      // Perform the clear operation
      const result = await this.clearProgress(clearScope);

      // Notify listeners of completion
      this.notifyClearCompletion(result);

    } catch (error) {
      this.notifyClearError(error);
    } finally {
      this.isClearing = false;
    }
  }

  /**
   * Determine what scope of progress to clear
   * @param {string} kataId - Current kata ID
   * @returns {Object} Clear scope configuration
   */
  async determineClearScope(kataId) {
    const currentProgress = await this.storageManager.getKataProgress(kataId);
    const _allProgress = await this.storageManager.getAllKataProgress();

    return {
      kataId,
      currentKataOnly: true, // For now, only clear current kata
      includeAssessments: false, // Preserve assessment results
      includeSettings: false, // Preserve user settings
      progressToReset: currentProgress,
      totalItems: currentProgress ? Object.keys(currentProgress).length : 0
    };
  }

  /**
   * Clear progress based on scope configuration
   * @param {Object} clearScope - What to clear
   * @returns {Object} Clear operation results
   */
  async clearProgress(clearScope) {
    const { kataId, currentKataOnly, includeAssessments, includeSettings } = clearScope;
    const results = {
      clearedItems: 0,
      errors: [],
      timestamp: new Date().toISOString()
    };

    try {
      if (currentKataOnly) {
        // Clear current kata progress only
        await this.clearKataProgress(kataId);
        results.clearedItems = clearScope.totalItems;
        results.scope = 'current-kata';
      } else {
        // Clear all progress (future enhancement)
        results.scope = 'all-progress';
        results.clearedItems = await this.clearAllProgressWithOptions(includeAssessments, includeSettings);
      }

      // Reset UI states
      await this.resetUIStates(kataId);

    } catch (error) {
      results.errors.push({
        operation: 'clearProgress',
        error: error.message,
        timestamp: new Date().toISOString()
      });
      throw error;
    }

    return results;
  }

  /**
   * Clear progress for a specific kata
   * @param {string} kataId - Kata to clear
   */
  async clearKataProgress(kataId) {
    try {

      // Clear from storage manager (using correct method name)
      const result = await this.storageManager.clearKataProgress(kataId);

      // Clear enhanced data if available and integrated
      if (this.enhancedProgressDataModel) {
        try {
          // Clear enhanced progress data for the specific kata
          await this.enhancedProgressDataModel.clearData();
          // Enhanced progress data cleared
        } catch (_error) {
          // Failed to clear enhanced progress data - continue silently
        }
      }

      // Always notify completion and log success if no exception was thrown
      this.notifyClearCompletion(kataId, 'kata');
      console.log(`Cleared progress for kata: ${kataId}`);

      return result;
    } catch (error) {
      console.error(`Failed to clear kata progress for ${kataId}:`, error);
      this.errorHandler.handleError(error, 'clearKataProgress', { kataId });
      throw error;
    }
  }

  /**
   * Clear all progress data
   * @returns {Promise<boolean>} True if successful
   */
  async clearAllProgress() {
    return this.errorHandler.safeExecute(async () => {
      // Use correct StorageManager method - clearStoredData supports types
      const results = await Promise.all([
        this.storageManager.clearStoredData('kata'),
        this.storageManager.clearStoredData('path'),
        this.storageManager.clearStoredData('settings')
      ]);

      const success = results.every(result => result);

      if (success) {
        this.notifyClearCompletion('all', 'all');
      }

      return success;
    }, 'clearAllProgress', false);
  }

  /**
   * Clear all learning progress (future enhancement)
   * @param {boolean} includeAssessments - Whether to clear assessments
   * @param {boolean} includeSettings - Whether to clear settings
   * @returns {number} Number of items cleared
   */
  async clearAllProgressWithOptions(includeAssessments = false, includeSettings = false) {
    let clearedCount = 0;

    // Get all kata progress
    const allProgress = await this.storageManager.getAllKataProgress();

    // Clear each kata's progress
    for (const kataId of Object.keys(allProgress)) {
      await this.clearKataProgress(kataId);
      clearedCount += Object.keys(allProgress[kataId]).length;
    }

    // Optionally clear assessments
    if (includeAssessments) {
      await this.storageManager.clearAssessmentResults();
      clearedCount += 1; // Count assessments as 1 unit
    }

    // Optionally clear settings
    if (includeSettings) {
      await this.storageManager.clearUserSettings();
      clearedCount += 1; // Count settings as 1 unit
    }

    return clearedCount;
  }

  /**
   * Reset UI states after clearing progress
   * @param {string} kataId - Current kata ID
   */
  async resetUIStates(_kataId) {
    try {
      // Reset all checkboxes in the current page
      const checkboxes = document.querySelectorAll('input[type="checkbox"][data-kata-item]');
      checkboxes.forEach(checkbox => {
        checkbox.checked = false;
        checkbox.classList.remove('completed', 'in-progress');
      });

      // Reset progress displays
      const progressElements = document.querySelectorAll('.kata-progress-display');
      progressElements.forEach(element => {
        element.textContent = '0%';
        element.style.width = '0%';
      });

      // Reset any category selectors
      const categoryButtons = document.querySelectorAll('.kata-category-btn');
      categoryButtons.forEach(button => {
        button.classList.remove('selected', 'completed');
      });

    } catch (error) {
      // Log error through error handler
      console.error('Failed to reset UI states:', error);
      this.errorHandler.handleError(error, 'ui-reset', { message: 'Failed to reset UI states' });
      // Continue execution despite UI reset failure
    }
  }

  /**
   * Notify listeners that clear operation completed successfully
   * @param {Object} result - Clear operation results
   */
  notifyClearCompletion(result) {
    const event = new CustomEvent('progressClearCompleted', {
      detail: {
        success: true,
        clearedItems: result.clearedItems,
        scope: result.scope,
        timestamp: result.timestamp,
        errors: result.errors
      }
    });

    document.dispatchEvent(event);
  }

  /**
   * Notify listeners that clear operation failed
   * @param {Error} error - The error that occurred
   */
  notifyClearError(error) {
    const event = new CustomEvent('progressClearCompleted', {
      detail: {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      }
    });

    document.dispatchEvent(event);
  }

  /**
   * Get clearing status
   * @returns {boolean} Whether a clear operation is in progress
   */
  isCurrentlyClearing() {
    return this.isClearing;
  }

  /**
   * Cleanup the clear manager
   */
  destroy() {
    // Clean up event listeners and intervals
    document.removeEventListener('progressClearRequested', this.handleClearRequest);
    console.log('ProgressClearManager destroyed');
  }
}

// Singleton instance
let progressClearManagerInstance = null;

/**
 * Get or create the global Progress Clear Manager instance
 * @returns {ProgressClearManager} The singleton instance
 */
export function getProgressClearManager() {
  if (!progressClearManagerInstance) {
    progressClearManagerInstance = new ProgressClearManager();
  }
  return progressClearManagerInstance;
}

/**
 * Initialize progress clear manager (called by main application)
 */
export function initializeProgressClearManager() {
  return getProgressClearManager();
}
