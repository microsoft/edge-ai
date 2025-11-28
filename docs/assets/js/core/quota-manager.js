/**
 * Quota Manager Module
 * Handles localStorage quota monitoring, cleanup, and memory management
 * for progress tracking data storage.
 *
 * Features:
 * - localStorage quota monitoring and warnings
 * - Automatic cleanup of oldest entries when quota threshold exceeded
 * - Memory-efficient storage operations
 * - Performance optimizations for large datasets
 *
 * @module core/quota-manager
 * @version 1.0.0
 * @since 1.0.0
 * @author Edge AI Team
 */

// Import default error handler for fallback
import { defaultErrorHandler } from './error-handler.js';

/**
 * Quota Manager for localStorage operations
 * Monitors storage usage and performs cleanup when thresholds are exceeded.
 * Provides memory management and performance optimization for storage operations.
 *
 * @class QuotaManager
 * @example
 * ```javascript
 * const quotaManager = new QuotaManager({
 *   debugHelper,
 *   errorHandler,
 *   warningThreshold: 5 * 1024 * 1024 // 5MB
 * });
 *
 * quotaManager.checkStorageQuota();
 * quotaManager.performQuotaCleanup();
 * ```
 */
export class QuotaManager {
  /**
   * Create a QuotaManager instance
   * @param {Object} dependencies - Required dependencies
   * @param {Object} dependencies.debugHelper - Debug helper instance
   * @param {Object} dependencies.errorHandler - Error handler instance
   * @param {number} dependencies.warningThreshold - Warning threshold in bytes (default: 5MB)
   * @throws {Error} When required dependencies are missing or invalid
   */
  constructor({ debugHelper, errorHandler, warningThreshold = 5 * 1024 * 1024 } = {}) {
    // Use fallback error handler if none provided
    this.errorHandler = errorHandler || defaultErrorHandler;

    // Validate error handler has required methods
    if (!this.errorHandler || typeof this.errorHandler.safeExecute !== 'function') {
      throw new Error('QuotaManager requires errorHandler with safeExecute method');
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

    // Quota management settings
    this._quotaWarningThreshold = warningThreshold;
    this._isDestroyed = false;

    // Initialize storage quota monitoring
    this._initializeQuotaMonitoring();

    this.debugHelper.info('QuotaManager initialized');
  }

  /**
   * Initialize storage quota monitoring
   * Sets up monitoring for localStorage quota usage and warnings
   * @private
   */
  _initializeQuotaMonitoring() {
    try {
      // Check current localStorage usage
      this.checkStorageQuota();

      // Set up periodic quota checking (every 5 minutes)
      if (typeof window !== 'undefined') {
        this._quotaCheckInterval = setInterval(() => {
          this.checkStorageQuota();
        }, 5 * 60 * 1000);
      }
    } catch (error) {
      this.debugHelper.warn('Failed to initialize quota monitoring:', error);
    }
  }

  /**
   * Check current localStorage quota usage
   * @returns {Object} Storage usage statistics
   */
  checkStorageQuota() {
    return this.errorHandler.safeExecute(() => {
      let totalSize = 0;
      let kataEntries = 0;
      let pathEntries = 0;
      let settingsEntries = 0;
      let otherEntries = 0;

      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key) {
          const value = localStorage.getItem(key);
          const entrySize = key.length + (value ? value.length : 0);
          totalSize += entrySize;

          // Categorize entries
          if (key.startsWith(this.kataPrefix)) {
            kataEntries++;
          } else if (key.startsWith(this.pathPrefix)) {
            pathEntries++;
          } else if (key.startsWith(this.settingsPrefix)) {
            settingsEntries++;
          } else {
            otherEntries++;
          }
        }
      }

      // Convert to bytes (approximate)
      const sizeInBytes = totalSize * 2; // Each character is roughly 2 bytes in UTF-16
      const sizeInMB = Math.round(sizeInBytes / 1024 / 1024 * 100) / 100;

      const stats = {
        totalSize: sizeInBytes,
        totalSizeMB: sizeInMB,
        totalEntries: localStorage.length,
        kataEntries,
        pathEntries,
        settingsEntries,
        otherEntries,
        warningThreshold: this._quotaWarningThreshold,
        warningThresholdMB: Math.round(this._quotaWarningThreshold / 1024 / 1024 * 100) / 100,
        exceedsThreshold: sizeInBytes > this._quotaWarningThreshold
      };

      if (stats.exceedsThreshold) {
        this.debugHelper.warn(`localStorage usage (${sizeInMB}MB) exceeds warning threshold (${stats.warningThresholdMB}MB)`);
        this.performQuotaCleanup();
      }

      return stats;
    }, 'checkStorageQuota', {});
  }

  /**
   * Perform quota cleanup by removing oldest entries
   * @param {number} cleanupPercentage - Percentage of entries to remove (default: 10%)
   * @returns {Object} Cleanup results
   */
  performQuotaCleanup(cleanupPercentage = 10) {
    return this.errorHandler.safeExecute(() => {
      const entries = [];
      let removedCount = 0;
      let removedSize = 0;

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
            // Remove corrupted entries immediately
            localStorage.removeItem(key);
            removedCount++;
            this.debugHelper.info(`Removed corrupted storage entry: ${key}`);
          }
        }
      }

      if (entries.length === 0) {
        return { removedCount: 0, removedSize: 0, message: 'No entries to clean up' };
      }

      // Sort by lastUpdated (oldest first)
      entries.sort((a, b) => a.lastUpdated - b.lastUpdated);

      // Remove oldest entries based on cleanup percentage
      const toRemove = Math.max(1, Math.floor(entries.length * cleanupPercentage / 100));
      for (let i = 0; i < toRemove && i < entries.length; i++) {
        const entry = entries[i];
        localStorage.removeItem(entry.key);
        removedCount++;
        removedSize += entry.size * 2; // Convert to bytes
        this.debugHelper.info(`Removed old storage entry: ${entry.key}`);
      }

      const result = {
        removedCount,
        removedSize,
        removedSizeMB: Math.round(removedSize / 1024 / 1024 * 100) / 100,
        totalEntriesProcessed: entries.length,
        cleanupPercentage
      };

      this.debugHelper.info(`Quota cleanup completed: removed ${removedCount} entries (${result.removedSizeMB}MB)`);
      return result;
    }, 'performQuotaCleanup', { removedCount: 0, removedSize: 0 });
  }

  /**
   * Get storage usage breakdown by category
   * @returns {Object} Detailed storage usage breakdown
   */
  /**
   * Get storage breakdown with sizes by category
   * @returns {Object} Storage breakdown organized by category
   */
  getStorageBreakdown() {
    return this.errorHandler.safeExecute(() => {
      const breakdown = {
        total: 0,
        byType: {
          kata: 0,
          path: 0,
          settings: 0,
          other: 0
        },
        detailed: {
          kata: { count: 0, size: 0, entries: [] },
          path: { count: 0, size: 0, entries: [] },
          settings: { count: 0, size: 0, entries: [] },
          other: { count: 0, size: 0, entries: [] }
        }
      };

      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key) {
          const value = localStorage.getItem(key);
          const entrySize = (key.length + (value ? value.length : 0)) * 2; // Convert to bytes

          let category = 'other';
          if (key.startsWith(this.kataPrefix)) {
            category = 'kata';
          } else if (key.startsWith(this.pathPrefix)) {
            category = 'path';
          } else if (key.startsWith(this.settingsPrefix)) {
            category = 'settings';
          }

          breakdown.byType[category] += entrySize;
          breakdown.total += entrySize;

          breakdown.detailed[category].count++;
          breakdown.detailed[category].size += entrySize;
          breakdown.detailed[category].entries.push({
            key,
            size: entrySize,
            sizeMB: Math.round(entrySize / 1024 / 1024 * 1000) / 1000
          });
        }
      }

      return breakdown;
    }, 'getStorageBreakdown', { total: 0, byType: { kata: 0, path: 0, settings: 0, other: 0 } });
  }

  /**
   * Clean up entries older than specified age
   * @param {number} maxAgeMs - Maximum age in milliseconds
   * @returns {Object} Cleanup results
   */
  /**
   * Clean up old entries from localStorage
   * @param {string} type - Type of entries to clean (kata, path, settings)
   * @param {number} days - Number of days to keep
   * @returns {number} Number of entries cleaned
   */
  cleanupOldEntries(type, days = 30) {
    return this.errorHandler.safeExecute(() => {
      let cleaned = 0;
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - days);

      const prefixMap = {
        kata: this.kataPrefix,
        path: this.pathPrefix,
        settings: this.settingsPrefix
      };

      const prefix = prefixMap[type];
      if (!prefix) {
        return 0;
      }

      const keysToRemove = [];
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith(prefix)) {
          try {
            const value = localStorage.getItem(key);
            const data = JSON.parse(value);

            // Check if the entry has a timestamp and is old
            if (data && data.timestamp) {
              const entryDate = new Date(data.timestamp);
              if (entryDate < cutoffDate) {
                keysToRemove.push(key);
              }
            } else if (data && data.lastAccessed) {
              const entryDate = new Date(data.lastAccessed);
              if (entryDate < cutoffDate) {
                keysToRemove.push(key);
              }
            }
          } catch {
            // If we can't parse the data, consider it for cleanup if old enough
            keysToRemove.push(key);
          }
        }
      }

      keysToRemove.forEach(key => {
        localStorage.removeItem(key);
        cleaned++;
      });

      return cleaned;
    }, 'cleanupOldEntries', 0);
  }

  /**
   * Clean up corrupted entries
   * @returns {Object} Cleanup results
   */
  cleanupCorruptedEntries() {
    return this.errorHandler.safeExecute(() => {
      let removedCount = 0;
      let removedSize = 0;

      for (let i = localStorage.length - 1; i >= 0; i--) {
        const key = localStorage.key(i);
        if (key && (key.startsWith(this.kataPrefix) || key.startsWith(this.pathPrefix) || key.startsWith(this.settingsPrefix))) {
          const value = localStorage.getItem(key);
          try {
            JSON.parse(value); // Test if it's valid JSON
          } catch {
            const entrySize = (key.length + (value ? value.length : 0)) * 2;
            localStorage.removeItem(key);
            removedCount++;
            removedSize += entrySize;
            this.debugHelper.info(`Removed corrupted entry: ${key}`);
          }
        }
      }

      const result = {
        removedCount,
        removedSize,
        removedSizeMB: Math.round(removedSize / 1024 / 1024 * 100) / 100
      };

      this.debugHelper.info(`Corruption cleanup completed: removed ${removedCount} entries (${result.removedSizeMB}MB)`);
      return result;
    }, 'cleanupCorruptedEntries', { removedCount: 0, removedSize: 0 });
  }

  /**
   * Set quota warning threshold
   * @param {number} thresholdBytes - New threshold in bytes
   */
  setQuotaThreshold(thresholdBytes) {
    this._quotaWarningThreshold = thresholdBytes;
    this.debugHelper.info(`Quota threshold updated to ${Math.round(thresholdBytes / 1024 / 1024 * 100) / 100}MB`);
  }

  /**
   * Get quota status and recommendations
   * @returns {Object} Quota status with recommendations
   */
  getQuotaStatus() {
    return this.errorHandler.safeExecute(() => {
      const stats = this.checkStorageQuota();
      const breakdown = this.getStorageBreakdown();

      const recommendations = [];

      if (stats.exceedsThreshold) {
        recommendations.push('Consider running quota cleanup to remove old entries');
      }

      if (breakdown.detailed.kata.count > 100) {
        recommendations.push('Large number of kata entries - consider archiving completed katas');
      }

      if (breakdown.detailed.path.count > 20) {
        recommendations.push('Many learning paths stored - consider removing unused paths');
      }

      const usagePercentage = Math.round((stats.totalSize / this._quotaWarningThreshold) * 100);

      return {
        ...stats,
        breakdown,
        recommendations,
        usagePercentage,
        status: stats.exceedsThreshold ? 'warning' : usagePercentage > 75 ? 'caution' : 'ok'
      };
    }, 'getQuotaStatus', {});
  }

  /**
   * Get storage usage statistics (alias for checkStorageQuota)
   * @returns {Promise<Object>} Storage usage statistics
   */
  async getStorageUsage() {
    return Promise.resolve(this.checkStorageQuota());
  }

  /**
   * Get the size of localStorage in bytes
   * @returns {number} Size of localStorage in bytes
   */
  getLocalStorageSize() {
    return this.errorHandler.safeExecute(() => {
      let totalSize = 0;
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key) {
          const value = localStorage.getItem(key) || '';
          totalSize += key.length + value.length;
        }
      }
      return totalSize;
    }, 'getLocalStorageSize', 0);
  }

  /**
   * Check quota status (alias for getQuotaStatus)
   * @returns {Promise<Object>} Quota status information
   */
  async checkQuotaStatus() {
    return Promise.resolve(this.getQuotaStatus());
  }

  /**
   * Register a callback for quota warnings
   * @param {Function} callback - Function to call when quota warning is triggered
   */
  onQuotaWarning(callback) {
    if (typeof callback !== 'function') {
      throw new Error('Callback must be a function');
    }

    if (!this._warningCallbacks) {
      this._warningCallbacks = [];
    }
    this._warningCallbacks.push(callback);
  }

  /**
   * Register a callback for critical quota situations
   * @param {Function} callback - Function to call when quota is critical
   */
  onQuotaCritical(callback) {
    if (typeof callback !== 'function') {
      throw new Error('Callback must be a function');
    }

    if (!this._criticalCallbacks) {
      this._criticalCallbacks = [];
    }
    this._criticalCallbacks.push(callback);
  }

  /**
   * Trigger quota warning callbacks (for testing)
   * @param {Object} status - Status object to pass to callbacks
   * @private
   */
  _triggerQuotaWarning(status) {
    if (this._warningCallbacks) {
      this._warningCallbacks.forEach(callback => {
        try {
          callback(status);
        } catch (error) {
          this.debugHelper.warn('Error in quota warning callback:', error);
        }
      });
    }
  }

  /**
   * Trigger critical quota callbacks (for testing)
   * @param {Object} status - Status object to pass to callbacks
   * @private
   */
  _triggerQuotaCritical(status) {
    if (this._criticalCallbacks) {
      this._criticalCallbacks.forEach(callback => {
        try {
          callback(status);
        } catch (error) {
          this.debugHelper.warn('Error in critical quota callback:', error);
        }
      });
    }
  }

  /**
   * Clean up old data from localStorage
   * @param {number} days - Number of days to keep (default: 30)
   * @returns {number} Total number of entries cleaned
   */
  cleanupOldData(days = 30) {
    return this.errorHandler.safeExecute(() => {
      const katasCleaned = this.cleanupOldEntries('kata', days);
      const pathsCleaned = this.cleanupOldEntries('path', days);
      const settingsCleaned = this.cleanupOldEntries('settings', days);

      return katasCleaned + pathsCleaned + settingsCleaned;
    }, 'cleanupOldData', 0);
  }

  /**
   * Clean up data by type
   * @param {string} type - Type of data to clean up ('kata', 'path', etc.)
   * @returns {number} Number of items cleaned up
   */
  cleanupByType(type) {
    return this.errorHandler.safeExecute(() => {
      let prefix;
      switch (type) {
        case 'kata':
          prefix = this.kataPrefix;
          break;
        case 'path':
          prefix = this.pathPrefix;
          break;
        case 'settings':
          prefix = this.settingsPrefix;
          break;
        default:
          throw new Error(`Unknown cleanup type: ${type}`);
      }

      let cleaned = 0;
      for (let i = localStorage.length - 1; i >= 0; i--) {
        const key = localStorage.key(i);
        if (key && key.startsWith(prefix)) {
          localStorage.removeItem(key);
          cleaned++;
        }
      }

      this.debugHelper.info(`Cleaned up ${cleaned} items of type '${type}'`);
      return cleaned;
    }, 'cleanupByType', 0);
  }

  /**
   * Get cleanup recommendations
   * @returns {Promise<Array>} Array of cleanup recommendations
   */
  async getCleanupRecommendations() {
    return Promise.resolve(this.errorHandler.safeExecute(() => {
      const stats = this.checkStorageQuota();
      const breakdown = this.getStorageBreakdown();
      const recommendations = [];

      if (stats.exceedsThreshold) {
        recommendations.push({
          type: 'urgent',
          message: 'Storage quota exceeded - immediate cleanup required',
          action: 'performQuotaCleanup'
        });
      }

      if (breakdown.detailed.kata.count > 100) {
        recommendations.push({
          type: 'suggestion',
          message: 'Large number of kata entries - consider archiving completed katas',
          action: 'cleanupByType',
          params: ['kata']
        });
      }

      if (breakdown.detailed.path.count > 20) {
        recommendations.push({
          type: 'suggestion',
          message: 'Many learning paths stored - consider removing unused paths',
          action: 'cleanupByType',
          params: ['path']
        });
      }

      const usagePercentage = Math.round((stats.totalSize / this._quotaWarningThreshold) * 100);
      if (usagePercentage > 75) {
        recommendations.push({
          type: 'warning',
          message: 'Storage usage above 75% - cleanup recommended',
          action: 'cleanupOldData',
          params: [30 * 24 * 60 * 60 * 1000] // 30 days
        });
      }

      return recommendations;
    }, 'getCleanupRecommendations', []));
  }

  /**
   * Get storage health status
   * @returns {Promise<Object>} Storage health information
   */
  async getStorageHealth() {
    return Promise.resolve(this.errorHandler.safeExecute(() => {
      const stats = this.checkStorageQuota();
      const breakdown = this.getStorageBreakdown();
      const usagePercentage = Math.round((stats.totalSize / this._quotaWarningThreshold) * 100);

      let health = 'excellent';
      let score = 100;

      if (usagePercentage > 90) {
        health = 'critical';
        score = 10;
      } else if (usagePercentage > 75) {
        health = 'poor';
        score = 25;
      } else if (usagePercentage > 50) {
        health = 'fair';
        score = 50;
      } else if (usagePercentage > 25) {
        health = 'good';
        score = 75;
      }

      return {
        health,
        score,
        usagePercentage,
        totalSize: stats.totalSize,
        breakdown,
        recommendations: usagePercentage > 75 ? ['Consider cleanup'] : []
      };
    }, 'getStorageHealth', { health: 'unknown', score: 0 }));
  }

  /**
   * Destroy the quota manager and clean up resources
   */
  destroy() {
    try {
      this._isDestroyed = true;

      // Clear quota check interval
      if (this._quotaCheckInterval) {
        clearInterval(this._quotaCheckInterval);
        this._quotaCheckInterval = null;
      }

      this.debugHelper.info('QuotaManager destroyed');
    } catch (error) {
      this.debugHelper.warn('Error during QuotaManager destruction:', error);
    }
  }
}
