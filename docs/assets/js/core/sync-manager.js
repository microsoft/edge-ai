/**
 * Sync Manager Module
 * Handles server synchronization for progress tracking data
 * with fallback mechanisms and error handling.
 *
 * Features:
 * - Asynchronous server synchronization
 * - Source tracking for circular update prevention
 * - Fallback mechanisms for offline operation
 * - Comprehensive error handling and retry logic
 *
 * @module core/sync-manager
 * @version 1.0.0
 * @since 1.0.0
 * @author Edge AI Team
 */

// Import default error handler for fallback
import { defaultErrorHandler } from './error-handler.js';

/**
 * Sync Manager for server synchronization operations
 * Handles saving and retrieving progress data from server endpoints
 * with comprehensive error handling and fallback mechanisms.
 *
 * @class SyncManager
 * @example
 * ```javascript
 * const syncManager = new SyncManager({
 *   debugHelper,
 *   errorHandler,
 *   serverUrl: 'http://localhost:3002'
 * });
 *
 * const result = await syncManager.saveToServer(progressData, 'ui');
 * const data = await syncManager.loadFromServer('kata-1');
 * ```
 */
export class SyncManager {
  /**
   * Create a SyncManager instance
   * @param {Object} dependencies - Required dependencies
   * @param {Object} dependencies.debugHelper - Debug helper instance
   * @param {Object} dependencies.errorHandler - Error handler instance
   * @param {string} dependencies.serverUrl - Server URL for API calls
   * @throws {Error} When required dependencies are missing or invalid
   */
  constructor({ debugHelper, errorHandler, serverUrl } = {}) {
    // Use fallback error handler if none provided
    this.errorHandler = errorHandler || defaultErrorHandler;

    // Validate error handler has required methods
    if (!this.errorHandler || typeof this.errorHandler.safeExecute !== 'function') {
      throw new Error('SyncManager requires errorHandler with safeExecute method');
    }

    // Assign dependencies with fallbacks
    this.debugHelper = debugHelper || {
      debug: () => {},
      info: () => {},
      warn: () => {},
      error: () => {}
    };

    // Server configuration
    this.serverUrl = serverUrl || this._getDefaultServerUrl();

    // Source tracking for circular update prevention
    this._updateSourceTracker = new Map();
    this._isDestroyed = false;

    // Retry configuration
    this._maxRetries = 3;
    this._retryDelay = 1000; // 1 second base delay

    this.debugHelper.info('SyncManager initialized with server:', this.serverUrl);
  }

  /**
   * Get default server URL from configuration
   * @private
   * @returns {string} Default server URL
   */
  _getDefaultServerUrl() {
    try {
      const config = typeof window !== 'undefined' ? window.KataProgressConfig : {};
      return config?.progressServerUrl || 'http://localhost:3002';
    } catch {
      return 'http://localhost:3002';
    }
  }

  /**
   * Save progress data to server asynchronously with source tracking
   * @param {Object} progressData - Progress data to save
   * @param {string} source - Source of the update (ui, coach, file-watcher, server, import, manual)
   * @returns {Promise<Object|null>} Server response or null on failure
   */
  async saveToServer(progressData, source = 'ui') {
    return this.errorHandler.safeExecute(async () => {
      // Track update source for circular update prevention
      this.trackUpdateSource(progressData.kataId || progressData.pathId, source, Date.now());

      const payload = {
        ...progressData,
        updateSource: source,
        serverTimestamp: Date.now()
      };

      const response = await this._makeApiCall('POST', '/api/progress/save', payload);

      if (response) {
        this.debugHelper.info(`Successfully saved ${progressData.kataId || progressData.pathId} to server`);
      }

      return response;
    }, 'saveToServer', null);
  }

  /**
   * Load progress data from server
   * @param {string} id - Progress identifier (kataId or pathId)
   * @param {string} type - Type of progress ('kata' or 'path')
   * @returns {Promise<Object|null>} Progress data or null on failure
   */
  async loadFromServer(id, type = 'kata') {
    return this.errorHandler.safeExecute(async () => {
      // Convert type to backend format
      const backendType = type === 'kata' ? 'kata-progress' : 'lab-progress';
      const response = await this._makeApiCall('GET', `/api/progress/load/${backendType}/${encodeURIComponent(id)}`);

      if (response && response.success && response.data) {
        this.debugHelper.info(`Successfully loaded ${id} from server`);
        return response.data;
      }

      return response;
    }, 'loadFromServer', null);
  }

  /**
   * Sync all local progress data to server
   * @param {Array} progressData - Array of progress objects
   * @returns {Promise<Object>} Sync results
   */
  async syncAllToServer(progressData) {
    return this.errorHandler.safeExecute(async () => {
      const results = {
        successful: 0,
        failed: 0,
        errors: []
      };

      for (const progress of progressData) {
        try {
          const result = await this.saveToServer(progress, 'sync');
          if (result) {
            results.successful++;
          } else {
            results.failed++;
          }
        } catch (error) {
          results.failed++;
          results.errors.push({
            id: progress.kataId || progress.pathId,
            error: error.message
          });
        }
      }

      this.debugHelper.info(`Sync completed: ${results.successful} successful, ${results.failed} failed`);
      return results;
    }, 'syncAllToServer', { successful: 0, failed: 0, errors: [] });
  }

  /**
   * Load all progress data from server
   * @param {string} type - Type of progress ('kata', 'path', or 'all')
   * @returns {Promise<Object|null>} All progress data or null on failure
   */
  async loadAllFromServer(type = 'all') {
    return this.errorHandler.safeExecute(async () => {
      const endpoint = type === 'all' ? '/api/progress/all' : `/api/progress/${type}/all`;
      const response = await this._makeApiCall('GET', endpoint);

      if (response) {
        this.debugHelper.info(`Successfully loaded all ${type} progress from server`);
      }

      return response;
    }, 'loadAllFromServer', null);
  }

  /**
   * Make API call with retry logic
   * @private
   * @param {string} method - HTTP method
   * @param {string} endpoint - API endpoint
   * @param {Object} data - Request data (for POST/PUT)
   * @returns {Promise<Object|null>} API response or null on failure
   */
  async _makeApiCall(method, endpoint, data = null) {
    let lastError = null;

    for (let attempt = 1; attempt <= this._maxRetries; attempt++) {
      try {
        const url = `${this.serverUrl}${endpoint}`;
        const options = {
          method,
          headers: {
            'Content-Type': 'application/json',
          }
        };

        if (data && (method === 'POST' || method === 'PUT')) {
          options.body = JSON.stringify(data);
        }

        const response = await fetch(url, options);

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const result = await response.json();
        return result;

      } catch (error) {
        lastError = error;
        this.debugHelper.warn(`API call attempt ${attempt}/${this._maxRetries} failed:`, error.message);

        // Wait before retrying (exponential backoff)
        if (attempt < this._maxRetries) {
          const delay = this._retryDelay * Math.pow(2, attempt - 1);
          await this._sleep(delay);
        }
      }
    }

    // All attempts failed
    this.debugHelper.error(`API call failed after ${this._maxRetries} attempts:`, lastError?.message);

    // Don't throw - this is a non-critical enhancement
    return null;
  }

  /**
   * Sleep for specified milliseconds
   * @private
   * @param {number} ms - Milliseconds to sleep
   * @returns {Promise} Sleep promise
   */
  _sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Track update source to prevent circular updates
   * @param {string} id - Identifier (kataId, pathId, etc.)
   * @param {string} source - Source of the update
   * @param {number} timestamp - Timestamp of the update
   */
  trackUpdateSource(id, source, timestamp) {
    try {
      if (!id) {return;}

      const trackingKey = `${source}-${id}`;
      this._updateSourceTracker.set(trackingKey, {
        id,
        source,
        timestamp,
        expires: timestamp + 10000 // Expire after 10 seconds
      });

      // Clean up expired entries
      this.cleanupExpiredTracking();

    } catch (error) {
      this.debugHelper.warn('Error tracking update source:', error);
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
      if (!this._updateSourceTracker || !id) {
        return false;
      }

      const now = Date.now();

      // Check for recent updates from UI that might cause circular updates
      if (source === 'file-watcher' || source === 'coach') {
        const uiTrackingKey = `ui-${id}`;
        const uiTracking = this._updateSourceTracker.get(uiTrackingKey);

        if (uiTracking && uiTracking.expires > now) {
          this.debugHelper.debug(`Ignoring ${source} update for ${id} - recent UI update detected`);
          return true;
        }
      }

      return false;

    } catch (error) {
      this.debugHelper.warn('Error checking update ignore status:', error);
      return false; // Default to not ignoring if there's an error
    }
  }

  /**
   * Clean up expired source tracking entries
   */
  cleanupExpiredTracking() {
    try {
      if (!this._updateSourceTracker) {
        return;
      }

      const now = Date.now();
      const expiredKeys = [];

      this._updateSourceTracker.forEach((tracking, key) => {
        if (tracking.expires <= now) {
          expiredKeys.push(key);
        }
      });

      expiredKeys.forEach(key => {
        this._updateSourceTracker.delete(key);
      });

    } catch (error) {
      this.debugHelper.warn('Error cleaning up source tracking:', error);
    }
  }

  /**
   * Get current source tracking status (for debugging)
   * @returns {Array} Array of active tracking entries
   */
  getSourceTrackingStatus() {
    try {
      if (!this._updateSourceTracker) {
        return [];
      }

      const now = Date.now();
      const active = [];

      this._updateSourceTracker.forEach((tracking, key) => {
        if (tracking.expires > now) {
          active.push({
            key,
            ...tracking,
            remainingMs: tracking.expires - now
          });
        }
      });

      return active;

    } catch (error) {
      this.debugHelper.warn('Error getting source tracking status:', error);
      return [];
    }
  }

  /**
   * Reset source tracking (for testing or cleanup)
   */
  resetSourceTracking() {
    try {
      if (this._updateSourceTracker) {
        this._updateSourceTracker.clear();
      }
    } catch (error) {
      this.debugHelper.warn('Error resetting source tracking:', error);
    }
  }

  /**
   * Save data with explicit source and circular update prevention
   * @param {string} type - Type of data ('kata' or 'path')
   * @param {string} id - Identifier
   * @param {Object} data - Data to save
   * @param {string} source - Source of the update
   * @returns {Promise<boolean>} Success status
   */
  async saveWithSourceTracking(type, id, data, source) {
    // Check if we should ignore this update
    if (this.shouldIgnoreUpdate(id, source)) {
      return false; // Update ignored to prevent circular loop
    }

    // Proceed with the appropriate save method
    const result = await this.saveToServer(data, source);
    return result !== null;
  }

  /**
   * Get server connection status
   * @returns {Promise<Object>} Connection status
   */
  async getServerStatus() {
    return this.errorHandler.safeExecute(async () => {
      const startTime = Date.now();

      try {
        const response = await this._makeApiCall('GET', '/api/health');
        const responseTime = Date.now() - startTime;

        return {
          connected: true,
          serverUrl: this.serverUrl,
          responseTime,
          serverInfo: response
        };
      } catch (error) {
        return {
          connected: false,
          serverUrl: this.serverUrl,
          error: error.message,
          responseTime: Date.now() - startTime
        };
      }
    }, 'getServerStatus', { connected: false, error: 'Failed to check server status' });
  }

  /**
   * Configure server settings
   * @param {Object} config - Server configuration
   * @param {string} config.serverUrl - New server URL
   * @param {number} config.maxRetries - Maximum retry attempts
   * @param {number} config.retryDelay - Base retry delay in milliseconds
   */
  configureServer({ serverUrl, maxRetries, retryDelay } = {}) {
    if (serverUrl) {
      this.serverUrl = serverUrl;
      this.debugHelper.info('Server URL updated to:', serverUrl);
    }

    if (typeof maxRetries === 'number') {
      this._maxRetries = maxRetries;
      this.debugHelper.info('Max retries updated to:', maxRetries);
    }

    if (typeof retryDelay === 'number') {
      this._retryDelay = retryDelay;
      this.debugHelper.info('Retry delay updated to:', retryDelay, 'ms');
    }
  }

  /**
   * Get sync configuration
   * @returns {Object} Current sync configuration
   */
  getSyncConfig() {
    return {
      serverUrl: this.serverUrl,
      maxRetries: this._maxRetries,
      retryDelay: this._retryDelay,
      activeTracking: this.getSourceTrackingStatus().length
    };
  }

  /**
   * Destroy the sync manager and clean up resources
   */
  destroy() {
    try {
      this._isDestroyed = true;

      // Clear source tracking
      this.resetSourceTracking();

      this.debugHelper.info('SyncManager destroyed');
    } catch (error) {
      this.debugHelper.warn('Error during SyncManager destruction:', error);
    }
  }
}
