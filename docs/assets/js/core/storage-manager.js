/**
 * Storage Manager
 * Manages localStorage operations for progress tracking and learning paths with enhanced
 * error handling, performance optimizations, and comprehensive data management capabilities.
 *
 * Features:
 * - localStorage quota management and cleanup
 * - Source tracking for circular update prevention
 * - Memory-efficient data operations with cleanup patterns
 * - Server synchronization with fallback mechanisms
 * - Comprehensive error handling and validation
 * - Performance optimizations for storage operations
 *
 * @module core/storage-manager
 * @version 2.2.0
 * @since 1.0.0
 * @author Edge AI Team
 */

// Import default error handler for fallback
import { defaultErrorHandler } from './error-handler.js';

/**
 * Storage Manager for progress tracking data
 * Handles localStorage operations with comprehensive error handling, data validation,
 * and performance optimizations. Provides source tracking and server synchronization.
 *
 * @class StorageManager
 * @example
 * ```javascript
 * const storageManager = new StorageManager({
 *   debugHelper,
 *   errorHandler
 * });
 *
 * const progress = storageManager.getKataProgress('kata-1');
 * const success = storageManager.saveKataProgress('kata-1', progressData);
 * ```
 */
export class StorageManager {
  /**
   * Create a StorageManager instance
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
      throw new Error('StorageManager requires errorHandler with safeExecute method');
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

    // Memory management
    this._updateSourceTracker = new Map();
    this._quotaWarningThreshold = 5 * 1024 * 1024; // 5MB
    this._isDestroyed = false;

    // Performance optimization
    this._cacheEnabled = true;
    this._cache = new Map();
    this._maxCacheSize = 100;

    // Initialize storage quota monitoring
    this._initializeQuotaMonitoring();
  }

  /**
   * Initialize storage quota monitoring
   * Sets up monitoring for localStorage quota usage and warnings
   * @private
   */
  _initializeQuotaMonitoring() {
    try {
      // Check current localStorage usage
      this._checkStorageQuota();

      // Set up periodic quota checking (every 5 minutes)
      if (typeof window !== 'undefined') {
        this._quotaCheckInterval = setInterval(() => {
          this._checkStorageQuota();
        }, 5 * 60 * 1000);
      }
    } catch (error) {
      this.debugHelper.warn('Failed to initialize quota monitoring:', error);
    }
  }

  /**
   * Check current localStorage quota usage
   * @private
   */
  _checkStorageQuota() {
    try {
      let totalSize = 0;
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key) {
          const value = localStorage.getItem(key);
          totalSize += key.length + (value ? value.length : 0);
        }
      }

      // Convert to bytes (approximate)
      const sizeInBytes = totalSize * 2; // Each character is roughly 2 bytes in UTF-16

      if (sizeInBytes > this._quotaWarningThreshold) {
        this.debugHelper.warn(`localStorage usage (${Math.round(sizeInBytes / 1024 / 1024)}MB) exceeds warning threshold`);
        this._performQuotaCleanup();
      }
    } catch (error) {
      this.debugHelper.warn('Error checking storage quota:', error);
    }
  }

  /**
   * Perform quota cleanup by removing oldest entries
   * @private
   */
  _performQuotaCleanup() {
    try {
      const entries = [];

      // Collect all storage entries with timestamps
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && (key.startsWith(this.kataPrefix) || key.startsWith(this.pathPrefix))) {
          const value = localStorage.getItem(key);
          try {
            const data = JSON.parse(value);
            entries.push({
              key,
              lastUpdated: data.lastUpdated || 0,
              size: key.length + value.length
            });
          } catch {
            // Remove corrupted entries
            localStorage.removeItem(key);
          }
        }
      }

      // Sort by lastUpdated (oldest first)
      entries.sort((a, b) => a.lastUpdated - b.lastUpdated);

      // Remove oldest 10% of entries
      const toRemove = Math.max(1, Math.floor(entries.length * 0.1));
      for (let i = 0; i < toRemove && i < entries.length; i++) {
        localStorage.removeItem(entries[i].key);
        this.debugHelper.info(`Removed old storage entry: ${entries[i].key}`);
      }
    } catch (error) {
      this.debugHelper.warn('Error during quota cleanup:', error);
    }
  }

  /**
   * Destroy the storage manager and clean up resources
   */
  destroy() {
    try {
      this._isDestroyed = true;

      // Clear quota check interval
      if (this._quotaCheckInterval) {
        clearInterval(this._quotaCheckInterval);
        this._quotaCheckInterval = null;
      }

      // Clear cache
      if (this._cache) {
        this._cache.clear();
      }

      // Clear source tracking
      this.resetSourceTracking();

      this.debugHelper.info('StorageManager destroyed');
    } catch (error) {
      this.debugHelper.warn('Error during StorageManager destruction:', error);
    }
  }

  /**
   * Get kata progress data
   * @param {string} kataId - Kata identifier
   * @returns {Object} Progress data or default structure
   */
  getKataProgress(kataId) {
    return this.errorHandler.safeExecute(() => {
      const storageKey = `${this.kataPrefix}${kataId}`;
      const stored = localStorage.getItem(storageKey);

      const defaultProgress = {
        kataId,
        completedTasks: 0,
        totalTasks: 0,
        completionPercentage: 0,
        lastUpdated: null,
        sections: {},
        metadata: {}
      };

      if (!stored) {
        return defaultProgress;
      }

      try {
        const progress = JSON.parse(stored);
        return { ...defaultProgress, ...progress };
      } catch (error) {
        this.errorHandler.recordError('parseKataProgress', error, { kataId, stored });
        return defaultProgress;
      }
    }, 'getKataProgress', {});
  }

  /**
   * Save kata progress data with source tracking
   * @param {string} kataId - Kata identifier
   * @param {Object} progressData - Progress data to save
   * @param {string} source - Source of the update (ui, coach, file-watcher, server, import, manual)
   * @returns {boolean} Success status
   */
  saveKataProgress(kataId, progressData, source = 'ui') {
    // Validate input parameters
    if (!kataId || typeof kataId !== 'string' || kataId.trim() === '') {
      return false;
    }
    if (!progressData || typeof progressData !== 'object') {
      return false;
    }

    return this.errorHandler.safeExecute(() => {
      const storageKey = `${this.kataPrefix}${kataId}`;
      const timestamp = Date.now();
      const dataToSave = {
        ...progressData,
        kataId,
        lastUpdated: timestamp,
        metadata: {
          ...progressData.metadata,
          lastUpdateSource: source,
          lastUpdateTimestamp: timestamp,
          version: progressData.metadata?.version || '1.0.0'
        }
      };

      // Save to localStorage for immediate access
      localStorage.setItem(storageKey, JSON.stringify(dataToSave));

      // Track source for circular update prevention
      this.trackUpdateSource(kataId, source, timestamp);

      // Also save to server for persistence (async, non-blocking)
      this.saveToServer(dataToSave, source).catch(() => {
        // Failed to save kata progress to server
      });

      return true;
    }, 'saveKataProgress', false);
  }

  /**
   * Save progress data to server asynchronously with source tracking
   * @param {Object} progressData - Progress data to save
   * @param {string} source - Source of the update
   * @returns {Promise} Server save promise
   */
  async saveToServer(progressData, source = 'ui') {
    try {
      // Get server URL from configuration
      const config = window.KataProgressConfig || {};
      const serverUrl = config.progressServerUrl || 'http://localhost:3002';

      const response = await fetch(`${serverUrl}/api/progress/save`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          ...progressData,
          updateSource: source,
          serverTimestamp: Date.now()
        })
      });

      if (!response.ok) {
        throw new Error(`Server save failed: ${response.status}`);
      }

      return await response.json();
    } catch {
      // Don't throw - this is a non-critical enhancement
      // Server save failed, progress still saved locally
      return null;
    }
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
   * Save learning path progress data with source tracking
   * @param {string} pathId - Path identifier
   * @param {Object} progressData - Progress data to save
   * @param {string} source - Source of the update
   * @returns {boolean} Success status
   */
  savePathProgress(pathId, progressData, source = 'ui') {
    // Validate input parameters
    if (!pathId || typeof pathId !== 'string' || pathId.trim() === '') {
      return false;
    }
    if (!progressData || typeof progressData !== 'object') {
      return false;
    }

    return this.errorHandler.safeExecute(() => {
      const storageKey = `${this.pathPrefix}${pathId}`;
      const timestamp = Date.now();
      const dataToSave = {
        ...progressData,
        pathId,
        lastUpdated: timestamp,
        metadata: {
          ...progressData.metadata,
          lastUpdateSource: source,
          lastUpdateTimestamp: timestamp
        }
      };

      localStorage.setItem(storageKey, JSON.stringify(dataToSave));

      // Track source for circular update prevention
      this.trackUpdateSource(pathId, source, timestamp);

      return true;
    }, 'savePathProgress', false);
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
   * Save user settings
   * @param {string} settingKey - Setting identifier
   * @param {*} value - Setting value
   * @returns {boolean} Success status
   */
  saveSetting(settingKey, value) {
    return this.errorHandler.safeExecute(() => {
      const storageKey = `${this.settingsPrefix}${settingKey}`;
      localStorage.setItem(storageKey, JSON.stringify(value));
      return true;
    }, 'saveSetting', false);
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
      const prefixes = [];

      switch (type) {
        case 'kata':
          prefixes.push(this.kataPrefix);
          break;
        case 'path':
          prefixes.push(this.pathPrefix);
          break;
        case 'settings':
          prefixes.push(this.settingsPrefix);
          break;
        default:
          prefixes.push(this.kataPrefix, this.pathPrefix, this.settingsPrefix);
      }

      for (let i = localStorage.length - 1; i >= 0; i--) {
        const key = localStorage.key(i);
        if (key && prefixes.some(prefix => key.startsWith(prefix))) {
          localStorage.removeItem(key);
        }
      }

      return true;
    }, 'clearStoredData', false);
  }

  // ========================================
  // SOURCE TRACKING AND CIRCULAR UPDATE PREVENTION
  // ========================================

  /**
   * Track update source to prevent circular updates
   * @param {string} id - Identifier (kataId, pathId, etc.)
   * @param {string} source - Source of the update
   * @param {number} timestamp - Timestamp of the update
   */
  trackUpdateSource(id, source, timestamp) {
    try {
      // Store source tracking info in memory (not localStorage to avoid conflicts)
      if (!this.sourceTracking) {
        this.sourceTracking = new Map();
      }

      const trackingKey = `${source}-${id}`;
      this.sourceTracking.set(trackingKey, {
        id,
        source,
        timestamp,
        expires: timestamp + 10000 // Expire after 10 seconds
      });

      // Clean up expired entries
      this.cleanupExpiredTracking();

    } catch {
      // Error tracking update source
    }
  }

  /**
   * Check if an update should be ignored to prevent circular updates
   * @param {string} id - Identifier to check
   * @param {string} source - Source to check against
   * @returns {boolean} Whether the update should be ignored
   */
  shouldIgnoreUpdate(id, source) {
    try {
      if (!this.sourceTracking) {
        return false;
      }

      const now = Date.now();

      // Check for recent updates from UI that might cause circular updates
      if (source === 'file-watcher' || source === 'coach') {
        const uiTrackingKey = `ui-${id}`;
        const uiTracking = this.sourceTracking.get(uiTrackingKey);

        if (uiTracking && uiTracking.expires > now) {
          // Ignoring update - recent UI update detected
          return true;
        }
      }

      return false;

    } catch {
      // Error checking update ignore status
      return false; // Default to not ignoring if there's an error
    }
  }

  /**
   * Clean up expired source tracking entries
   */
  cleanupExpiredTracking() {
    try {
      if (!this.sourceTracking) {
        return;
      }

      const now = Date.now();
      const expiredKeys = [];

      this.sourceTracking.forEach((tracking, key) => {
        if (tracking.expires <= now) {
          expiredKeys.push(key);
        }
      });

      expiredKeys.forEach(key => {
        this.sourceTracking.delete(key);
      });

    } catch {
      // Error cleaning up source tracking
    }
  }

  /**
   * Get current source tracking status (for debugging)
   * @returns {Array} Array of active tracking entries
   */
  getSourceTrackingStatus() {
    try {
      if (!this.sourceTracking) {
        return [];
      }

      const now = Date.now();
      const active = [];

      this.sourceTracking.forEach((tracking, key) => {
        if (tracking.expires > now) {
          active.push({
            key,
            ...tracking,
            remainingMs: tracking.expires - now
          });
        }
      });

      return active;

    } catch {
      // Error getting source tracking status
      return [];
    }
  }

  /**
   * Reset source tracking (for testing or cleanup)
   */
  resetSourceTracking() {
    try {
      if (this.sourceTracking) {
        this.sourceTracking.clear();
      }
    } catch {
      // Error resetting source tracking
    }
  }

  /**
   * Save data with explicit source and circular update prevention
   * @param {string} type - Type of data ('kata' or 'path')
   * @param {string} id - Identifier
   * @param {Object} data - Data to save
   * @param {string} source - Source of the update
   * @returns {boolean} Success status
   */
  saveWithSourceTracking(type, id, data, source) {
    // Check if we should ignore this update
    if (this.shouldIgnoreUpdate(id, source)) {
      return false; // Update ignored to prevent circular loop
    }

    // Proceed with the appropriate save method
    if (type === 'kata') {
      return this.saveKataProgress(id, data, source);
    } else if (type === 'path') {
      return this.savePathProgress(id, data, source);
    }

    return false;
  }

  /**
   * Get update source metadata for an item
   * @param {string} type - Type of data ('kata' or 'path')
   * @param {string} id - Identifier
   * @returns {Object|null} Source metadata or null
   */
  getUpdateSourceMetadata(type, id) {
    try {
      let data;
      if (type === 'kata') {
        data = this.getKataProgress(id);
      } else if (type === 'path') {
        data = this.getPathProgress(id);
      } else {
        return null;
      }

      return data.metadata ? {
        lastUpdateSource: data.metadata.lastUpdateSource,
        lastUpdateTimestamp: data.metadata.lastUpdateTimestamp,
        version: data.metadata.version
      } : null;

    } catch {
      return null;
    }
  }

  /**
   * Clear specific kata progress
   * @param {string} kataId - Kata identifier
   * @returns {boolean} Success status
   */
  clearKataProgress(kataId) {
    return this.errorHandler.safeExecute(() => {
      const storageKey = `${this.kataPrefix}${kataId}`;
      localStorage.removeItem(storageKey);
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
      const storageKey = `${this.pathPrefix}${pathId}`;
      localStorage.removeItem(storageKey);
      return true;
    }, 'clearPathProgress', false);
  }

  /**
   * Generic progress save method for backward compatibility
   * @param {string} id - Progress identifier
   * @param {Object} data - Progress data
   * @param {string} source - Source of the update
   * @returns {boolean} Success status
   */
  saveProgress(id, data, source = 'test') {
    return this.errorHandler.safeExecute(() => {
      // Try to determine if this is a kata or path based on ID format
      if (id && typeof id === 'string') {
        // If it looks like a kata ID (contains /), save as kata progress
        if (id.includes('/') || id.startsWith('kata-')) {
          return this.saveKataProgress(id, data, source);
        } else {
          // Otherwise save as path progress
          return this.savePathProgress(id, data, source);
        }
      }
      return false;
    }, 'saveProgress', false);
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
      if (id && typeof id === 'string') {
        // Try to determine the correct storage key format
        const kataKey = `${this.kataPrefix}${id}`;
        const pathKey = `${this.pathPrefix}${id}`;

        // Check which key exists and remove it
        let removed = false;
        if (localStorage.getItem(kataKey)) {
          localStorage.removeItem(kataKey);
          removed = true;
        }
        if (localStorage.getItem(pathKey)) {
          localStorage.removeItem(pathKey);
          removed = true;
        }

        return removed;
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
      const allProgress = {};

      // Iterate through localStorage to find all progress entries
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && (
          key.startsWith('kata-progress-') ||
          key.startsWith('learning-path-') ||
          key.startsWith('kata_progress_') ||
          key.startsWith('path_progress_')
        )) {
          try {
            const value = localStorage.getItem(key);
            if (value) {
              const progressData = JSON.parse(value);
              // Extract ID from key
              let id = key;
              if (key.startsWith('kata-progress-')) {
                id = key.replace('kata-progress-', '');
              } else if (key.startsWith('learning-path-')) {
                id = key.replace('learning-path-', '');
              } else if (key.startsWith('kata_progress_')) {
                id = key.replace('kata_progress_', '');
              } else if (key.startsWith('path_progress_')) {
                id = key.replace('path_progress_', '');
              }
              allProgress[id] = progressData;
            }
          } catch (_error) {
            // Skip invalid JSON entries
            continue;
          }
        }
      }

      return allProgress;
    }, 'getAllProgress', {});
  }

  /**
   * Generic storage setter with error handling
   * @param {string} key - Storage key
   * @param {*} value - Value to store (will be JSON stringified)
   * @returns {boolean} Success status
   */
  setItem(key, value) {
    return this.errorHandler.safeExecute(() => {
      if (!key || typeof key !== 'string') {
        return false;
      }

      const stringValue = typeof value === 'string' ? value : JSON.stringify(value);
      localStorage.setItem(key, stringValue);
      return true;
    }, 'setItem', false);
  }

  /**
   * Generic storage getter with error handling
   * @param {string} key - Storage key
   * @param {*} defaultValue - Default value if key not found
   * @returns {*} Stored value or default
   */
  getItem(key, defaultValue = null) {
    return this.errorHandler.safeExecute(() => {
      if (!key || typeof key !== 'string') {
        return defaultValue;
      }

      const value = localStorage.getItem(key);
      if (value === null) {
        return defaultValue;
      }

      // Try to parse as JSON, fall back to string
      try {
        return JSON.parse(value);
      } catch {
        return value;
      }
    }, 'getItem', defaultValue);
  }

  /**
   * Set kata progress with error handling
   * @param {string} kataId - Kata identifier
   * @param {Object} progressData - Progress data to store
   * @returns {boolean} Success status
   */
  setKataProgress(kataId, progressData) {
    return this.errorHandler.safeExecute(() => {
      if (!kataId || typeof kataId !== 'string') {
        return false;
      }
      if (!progressData || typeof progressData !== 'object') {
        return false;
      }

      const key = `kata_progress_${kataId}`;
      const stringValue = JSON.stringify(progressData);
      localStorage.setItem(key, stringValue);
      return true;
    }, 'setKataProgress', false);
  }
}
