/**
 * Storage Core Module
 * Handles basic localStorage operations for progress tracking and learning paths
 * with comprehensive error handling and data validation.
 *
 * This module focuses solely on core storage operations without quota management
 * or server synchronization - providing a clean, focused persistence layer.
 *
 * @module core/storage-core
 * @version 1.0.0
 * @since 1.0.0
 * @author Edge AI Team
 */

// Import default error handler for fallback
import { defaultErrorHandler } from './error-handler.js';

/**
 * Core Storage Manager for basic localStorage operations
 * Handles get/set/clear operations with comprehensive error handling and data validation.
 * Focused on pure storage operations without additional complexity.
 *
 * @class StorageCore
 * @example
 * ```javascript
 * const storageCore = new StorageCore({
 *   debugHelper,
 *   errorHandler
 * });
 *
 * const progress = storageCore.getKataProgress('kata-1');
 * const success = storageCore.saveKataProgress('kata-1', progressData);
 * ```
 */
export class StorageCore {
  /**
   * Create a StorageCore instance
   * @param {Object} dependencies - Required dependencies
   * @param {Object} dependencies.debugHelper - Debug helper instance
   * @param {Object} dependencies.errorHandler - Error handler instance
   * @throws {Error} When required dependencies are missing or invalid
   */
  constructor({ debugHelper, errorHandler } = {}) {
    // Use fallback error handler if none provided
    this.errorHandler = errorHandler || defaultErrorHandler;

    // Validate error handler has required methods
    if (!this.errorHandler || typeof this.errorHandler.safeExecute !== 'function') {
      throw new Error('StorageCore requires errorHandler with safeExecute method');
    }

    // Assign dependencies with fallbacks
    this.debugHelper = debugHelper || {
      debug: () => {},
      info: () => {},
      warn: () => {},
      error: () => {}
    };

    // Storage key prefixes
    this.kataPrefix = 'kata-progress-';
    this.pathPrefix = 'learning-path-';
    this.settingsPrefix = 'kata-settings-';

    this.debugHelper.info('StorageCore initialized');
  }

  /**
   * Get kata progress data (deprecated - use API instead)
   * @deprecated Use API fetch via LearningPathManager.getKataProgress()
   * @param {string} kataId - Kata identifier
   * @returns {Object} Default progress structure only
   */
  getKataProgress(kataId) {
    return this.errorHandler.safeExecute(() => {
      // Return default structure - no localStorage reads
      return {
        kataId,
        completedTasks: 0,
        totalTasks: 0,
        completionPercentage: 0,
        lastUpdated: null,
        sections: {},
        metadata: {}
      };
    }, 'getKataProgress', {});
  }

  /**
   * Save kata progress data (neutered - use API instead)
   * @deprecated All progress should be saved via API, not localStorage
   * @param {string} kataId - Kata identifier
   * @param {Object} progressData - Progress data to save
   * @param {string} source - Source of the update (ui, coach, file-watcher, server, import, manual)
   * @returns {boolean} Success status (always true for backward compatibility)
   */
  saveKataProgress(kataId, progressData, source = 'ui') {
    // Validate input parameters
    if (!kataId || typeof kataId !== 'string' || kataId.trim() === '') {
      return false;
    }
    if (!progressData || typeof progressData !== 'object') {
      return false;
    }

    // No localStorage operations - all saves should go to API
    // Return true for backward compatibility
    return true;
  }

  /**
   * Get learning path progress data
   * @param {string} pathId - Path identifier
   * @returns {Object} Path progress data
   */
  getPathProgress(pathId) {
    return this.errorHandler.safeExecute(() => {
      const storageKey = `${this.pathPrefix}${pathId}`;
      const stored = localStorage.getItem(storageKey);

      const defaultProgress = {
        pathId,
        startedAt: null,
        currentKata: null,
        completedKatas: [],
        totalKatas: 0,
        completionPercentage: 0,
        lastUpdated: null,
        timeSpent: 0
      };

      if (!stored) {
        return defaultProgress;
      }

      try {
        const progress = JSON.parse(stored);
        return { ...defaultProgress, ...progress };
      } catch (error) {
        this.errorHandler.recordError('parsePathProgress', error, { pathId, stored });
        return defaultProgress;
      }
    }, 'getPathProgress', {});
  }

  /**
   * Save learning path progress data (neutered - use API instead)
   * @deprecated All progress should be saved via API, not localStorage
   * @param {string} pathId - Path identifier
   * @param {Object} progressData - Progress data to save
   * @param {string} source - Source of the update
   * @returns {boolean} Success status (always true for backward compatibility)
   */
  savePathProgress(pathId, progressData, source = 'ui') {
    // No localStorage operations - all saves should go to API
    // Return true for backward compatibility
    return true;
  }

  /**
   * Get user settings
   * @param {string} settingKey - Setting identifier
   * @returns {*} Setting value or null
   */
  getSetting(settingKey) {
    return this.errorHandler.safeExecute(() => {
      const storageKey = `${this.settingsPrefix}${settingKey}`;
      const stored = localStorage.getItem(storageKey);

      if (!stored) {
        return null;
      }

      try {
        return JSON.parse(stored);
      } catch (error) {
        this.errorHandler.recordError('parseSetting', error, { settingKey, stored });
        return null;
      }
    }, 'getSetting', null);
  }

  /**
   * Save user settings (neutered - use API instead)
   * @deprecated All settings should be saved via API, not localStorage
   * @param {string} settingKey - Setting identifier
   * @param {*} value - Setting value
   * @returns {boolean} Success status (always true for backward compatibility)
   */
  saveSetting(settingKey, value) {
    // No localStorage operations - all saves should go to API
    // Return true for backward compatibility
    return true;
  }

  /**
   * Get all stored kata progress
   * @returns {Array} Array of kata progress objects
   */
  getAllKataProgress() {
    return this.errorHandler.safeExecute(() => {
      const kataProgress = [];

      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith(this.kataPrefix)) {
          const kataId = key.replace(this.kataPrefix, '');
          const progress = this.getKataProgress(kataId);
          if (progress.kataId) {
            kataProgress.push(progress);
          }
        }
      }

      return kataProgress;
    }, 'getAllKataProgress', []);
  }

  /**
   * Get all stored learning path progress
   * @returns {Array} Array of path progress objects
   */
  getAllPathProgress() {
    return this.errorHandler.safeExecute(() => {
      const pathProgress = [];

      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith(this.pathPrefix)) {
          const pathId = key.replace(this.pathPrefix, '');
          const progress = this.getPathProgress(pathId);
          if (progress.pathId) {
            pathProgress.push(progress);
          }
        }
      }

      return pathProgress;
    }, 'getAllPathProgress', []);
  }

  /**
   * Clear all stored data
   * @param {string} type - Type to clear ('kata', 'path', 'settings', 'all')
   * @returns {boolean} Success status
   */
  clearStoredData(type = 'all') {
    return this.errorHandler.safeExecute(() => {
      // Note: Server-first architecture - no localStorage operations
      // API handles actual data deletion
      return true;
    }, 'clearStoredData', false);
  }

  /**
   * Clear specific kata progress
   * @param {string} kataId - Kata identifier
   * @returns {boolean} Success status
   */
  clearKataProgress(kataId) {
    return this.errorHandler.safeExecute(() => {
      // Note: Server-first architecture - no localStorage operations
      // API handles actual progress deletion
      return true;
    }, 'clearKataProgress', false);
  }

  /**
   * Clear specific path progress
   * @param {string} pathId - Path identifier
   * @returns {boolean} Success status
   */
  clearPathProgress(pathId) {
    return this.errorHandler.safeExecute(() => {
      // Note: Server-first architecture - no localStorage operations
      // API handles actual progress deletion
      return true;
    }, 'clearPathProgress', false);
  }

  /**
   * Generic progress save method for backward compatibility (neutered)
   * @deprecated All progress should be saved via API, not localStorage
   * @param {string} id - Progress identifier
   * @param {Object} data - Progress data
   * @param {string} source - Source of the update
   * @returns {boolean} Success status (always true for backward compatibility)
   */
  saveProgress(id, data, source = 'test') {
    // No localStorage operations - all saves should go to API
    // Return true for backward compatibility
    return true;
  }

  /**
   * Generic progress get method for backward compatibility
   * @param {string} id - Progress identifier
   * @returns {Object|null} Progress data
   */
  getProgress(id) {
    return this.errorHandler.safeExecute(() => {
      if (id && typeof id === 'string') {
        const storageKey = id.includes('/') || id.startsWith('kata-')
          ? `${this.kataPrefix}${id}`
          : `${this.pathPrefix}${id}`;

        const stored = localStorage.getItem(storageKey);
        if (!stored) {
          return null;
        }

        try {
          const progress = JSON.parse(stored);
          return progress;
        } catch (error) {
          this.errorHandler.recordError('getProgress', error, { id, stored });
          return null;
        }
      }
      return null;
    }, 'getProgress', null);
  }

  /**
   * Generic clear progress method for backward compatibility
   * @param {string} id - Progress identifier
   * @returns {boolean} Success status
   */
  clearProgress(id) {
    return this.errorHandler.safeExecute(() => {
      // Note: Server-first architecture - no localStorage operations
      // API handles actual progress deletion
      if (id && typeof id === 'string') {
        return true;
      }
      return false;
    }, 'clearProgress', false);
  }

  /**
   * Get all progress data for backward compatibility
   * @returns {Object} All progress data
   */
  getAllProgress() {
    return this.errorHandler.safeExecute(() => {
      const kataProgress = this.getAllKataProgress();
      const pathProgress = this.getAllPathProgress();

      // Create a combined object by ID for easy access
      const allByID = {};

      // Add kata progress by ID
      kataProgress.forEach(progress => {
        if (progress.kataId) {
          allByID[progress.kataId] = progress;
        }
      });

      // Add path progress by ID
      pathProgress.forEach(progress => {
        if (progress.pathId) {
          allByID[progress.pathId] = progress;
        }
      });

      return {
        katas: kataProgress,
        paths: pathProgress,
        all: allByID
      };
    }, 'getAllProgress', {});
  }
}
