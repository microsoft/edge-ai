/**
 * Progress Core - Unified Progress Tracking Engine
 * Consolidates progress-system-manager.js and shared-progress-tracker.js
 * Single responsibility: Core progress tracking logic and data management
 * Version: 3.0.0
 */

/**
 * Core progress tracking engine with unified data management
 * Handles all progress state, persistence, and cross-module coordination
 *
 * @class ProgressCore
 * @module core/progress-core
 * @example
 * const progressCore = new ProgressCore({
 *   storagePrefix: 'kata-',
 *   autoSave: true,
 *   errorHandler: errorHandlerInstance
 * });
 */
export class ProgressCore {
  /**
   * Initialize progress tracking core
   * @param {Object} config - Configuration options
   * @param {string} config.storagePrefix - Prefix for localStorage keys
   * @param {string} config.serverUrl - Server URL for sync operations
   * @param {boolean} config.autoSave - Enable automatic saving
   * @param {number} config.saveDebounce - Debounce delay for saves (ms)
   * @param {Object} config.errorHandler - Error handling service
   */
  constructor(config = {}) {
    this.config = {
      storagePrefix: config.storagePrefix || 'progress-',
      serverUrl: config.serverUrl || 'http://localhost:3002',
      autoSave: config.autoSave !== false,
      saveDebounce: config.saveDebounce || 1000,
      maxRetries: config.maxRetries || 3,
      retryDelay: config.retryDelay || 1000,
      quotaLimit: config.quotaLimit || 2 * 1024 * 1024, // 2MB
      ...config
    };

    // Core state management
    this.progressData = new Map();
    this.moduleStates = new Map();
    this.dependencies = new Map();
    this.isInitialized = false;

    // Operation management
    this.saveTimeoutId = null;
    this.sourceTracker = new Set();
    this.lastSaveTime = 0;
    this.retryCount = 0;

    // Dependency injection
    this.errorHandler = config.errorHandler || null;

    // File monitoring
    this.fileWatcher = null;
    this.lastFileModification = new Map();
    this.updateDebounceTimeout = null;

    // Global singleton enforcement
    if (typeof window !== 'undefined') {
      if (window.progressCore && window.progressCore !== this) {
        this._log('warn', '[ProgressCore] Multiple instances detected. Returning existing instance.');
        return window.progressCore;
      }
      window.progressCore = this;
    }

    this.setupDependencyGraph();
  }

  /**
   * Internal logging utility - gates console output during tests
   * @private
   * @param {string} level - Log level (log, warn, error)
   * @param {string} message - Log message
   * @param {...any} args - Additional arguments
   */
  _log(level, message, ...args) {
    // Gate logging during tests or when specifically disabled
    if (typeof process !== 'undefined' && process.env?.NODE_ENV === 'test') {
      return;
    }
    if (typeof window !== 'undefined' && window.location?.search?.includes('test=true')) {
      return;
    }
    if (this.config?.debug === false) {
      return;
    }

    // Note: Console usage for development debugging - should be replaced with proper logging in production
    // eslint-disable-next-line no-console
    console[level]?.(message, ...args);
  }

  /**
   * Define module dependency graph for loading order
   * @private
   */
  setupDependencyGraph() {
    const deps = [
      ['error-handler', []],
      ['dom-utils', ['error-handler']],
      ['storage-manager', ['error-handler']],
      ['kata-detection', ['error-handler', 'dom-utils']],
      ['kata-catalog', ['error-handler', 'storage-manager']],
      ['learning-path-manager', ['error-handler', 'storage-manager', 'kata-detection']],
      ['completion-handler', ['error-handler', 'storage-manager']],
      ['notification-system', ['error-handler']]
    ];

    deps.forEach(([module, moduleDeps]) => {
      this.dependencies.set(module, moduleDeps);
    });
  }

  /**
   * Initialize the progress tracking system
   * @returns {Promise<boolean>} Success status
   */
  async init() {
    if (this.isInitialized) {
      return true;
    }

    try {
      await this.loadStoredProgress();
      this.setupFileWatcher();
      this.setupEventListeners();
      this.isInitialized = true;

      // Only log in development, not during tests
      if (!globalThis.vitest) {
        this._log('log', '[ProgressCore] Initialized successfully');
      }
      return true;
    } catch (error) {
      this.handleError('Initialization failed', error);
      return false;
    }
  }

  /**
   * Load existing progress data from localStorage
   * @private
   */
  async loadStoredProgress() {
    try {
      const keys = this.getStorageKeys();

      for (const key of keys) {
        const data = localStorage.getItem(key);
        if (data) {
          const parsed = JSON.parse(data);
          const moduleKey = key.replace(this.config.storagePrefix, '');
          this.progressData.set(moduleKey, parsed);
        }
      }

      this._log('log', `[ProgressCore] Loaded progress for ${this.progressData.size} modules`);
    } catch (error) {
      this.handleError('Failed to load stored progress', error);
    }
  }

  /**
   * Get all localStorage keys with our prefix
   * @private
   * @returns {string[]} Array of matching keys
   */
  getStorageKeys() {
    const keys = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && key.startsWith(this.config.storagePrefix)) {
        keys.push(key);
      }
    }
    return keys;
  }

  /**
   * Update progress for a specific module/key
   * @param {string} moduleKey - Module identifier
   * @param {string} progressKey - Progress item key
   * @param {*} value - Progress value
   * @param {string} source - Source of the update
   * @returns {boolean} Success status
   */
  updateProgress(moduleKey, progressKey, value, source = 'unknown') {
    try {
      // Prevent circular updates
      const updateId = `${moduleKey}.${progressKey}.${source}`;
      if (this.sourceTracker.has(updateId)) {
        return false;
      }

      this.sourceTracker.add(updateId);
      setTimeout(() => this.sourceTracker.delete(updateId), 100);

      // Get or create module progress
      let moduleProgress = this.progressData.get(moduleKey);
      if (!moduleProgress) {
        moduleProgress = {
          timestamp: new Date().toISOString(),
          version: '3.0.0',
          data: {}
        };
        this.progressData.set(moduleKey, moduleProgress);
      }

      // Update the specific progress item
      moduleProgress.data[progressKey] = value;
      moduleProgress.timestamp = new Date().toISOString();

      // Trigger save if auto-save is enabled
      if (this.config.autoSave) {
        this.debouncedSave(moduleKey);
      }

      this._log('log', `[ProgressCore] Updated ${moduleKey}.${progressKey} from ${source}`);
      return true;
    } catch (error) {
      this.handleError(`Failed to update progress for ${moduleKey}.${progressKey}`, error);
      return false;
    }
  }

  /**
   * Get progress data for a module
   * @param {string} moduleKey - Module identifier
   * @returns {Object|null} Progress data or null if not found
   */
  getProgress(moduleKey) {
    return this.progressData.get(moduleKey) || null;
  }

  /**
   * Get specific progress value
   * @param {string} moduleKey - Module identifier
   * @param {string} progressKey - Progress item key
   * @returns {*} Progress value or undefined
   */
  getProgressValue(moduleKey, progressKey) {
    const moduleProgress = this.getProgress(moduleKey);
    return moduleProgress?.data?.[progressKey];
  }

  /**
   * Get all progress data
   * @returns {Map} Complete progress data map
   */
  getAllProgress() {
    return new Map(this.progressData);
  }

  /**
   * Save progress data to localStorage with quota protection
   * @param {string} moduleKey - Module to save (optional, saves all if not provided)
   * @private
   */
  async saveProgress(moduleKey = null) {
    try {
      const modulesToSave = moduleKey ? [moduleKey] : Array.from(this.progressData.keys());

      for (const key of modulesToSave) {
        const data = this.progressData.get(key);
        if (!data) {
          continue;
        }

        const storageKey = this.config.storagePrefix + key;
        const serialized = JSON.stringify(data);

        // Check size before saving
        if (serialized.length > this.config.quotaLimit) {
          this._log('warn', `[ProgressCore] Data too large for ${key}, creating reduced version`);
          const reduced = this.createReducedData(data);
          localStorage.setItem(storageKey, JSON.stringify(reduced));
        } else {
          localStorage.setItem(storageKey, serialized);
        }
      }

      this.lastSaveTime = Date.now();
      this._log('log', `[ProgressCore] Saved progress for ${modulesToSave.length} modules`);
    } catch (error) {
      if (error.name === 'QuotaExceededError') {
        await this.handleQuotaExceeded();
        this.retryCount++;

        if (this.retryCount < this.config.maxRetries) {
          setTimeout(() => this.saveProgress(moduleKey), this.config.retryDelay);
        }
      } else {
        this.handleError('Failed to save progress', error);
      }
    }
  }

  /**
   * Create reduced version of data when storage quota is exceeded
   * @param {Object} data - Original data
   * @returns {Object} Reduced data
   * @private
   */
  createReducedData(data) {
    return {
      timestamp: data.timestamp || new Date().toISOString(),
      version: data.version || '3.0.0',
      data: Object.fromEntries(
        Object.entries(data.data || {}).slice(0, 100) // Keep only first 100 items
      )
    };
  }

  /**
   * Handle localStorage quota exceeded
   * @private
   */
  async handleQuotaExceeded() {
    this._log('warn', '[ProgressCore] Storage quota exceeded, cleaning up old data');

    // Remove oldest entries
    const keys = this.getStorageKeys();
    const timestamps = keys.map(key => {
      try {
        const data = JSON.parse(localStorage.getItem(key));
        return { key, timestamp: data.timestamp || '1970-01-01' };
      } catch {
        return { key, timestamp: '1970-01-01' };
      }
    });

    // Sort by timestamp and remove oldest 20%
    timestamps.sort((a, b) => a.timestamp.localeCompare(b.timestamp));
    const toRemove = timestamps.slice(0, Math.floor(timestamps.length * 0.2));

    toRemove.forEach(({ key }) => {
      localStorage.removeItem(key);
      const moduleKey = key.replace(this.config.storagePrefix, '');
      this.progressData.delete(moduleKey);
    });

    this._log('log', `[ProgressCore] Removed ${toRemove.length} old progress entries`);
  }

  /**
   * Debounced save to prevent excessive localStorage writes
   * @param {string} moduleKey - Module to save
   * @private
   */
  debouncedSave(moduleKey) {
    if (this.saveTimeoutId) {
      clearTimeout(this.saveTimeoutId);
    }

    this.saveTimeoutId = setTimeout(() => {
      this.saveProgress(moduleKey);
      this.saveTimeoutId = null;
    }, this.config.saveDebounce);
  }

  /**
   * Setup file system watcher for external changes
   * @private
   */
  setupFileWatcher() {
    // File watcher setup would be here in a Node.js environment
    // Browser implementation would use different approach
    this._log('log', '[ProgressCore] File watcher setup completed');
  }

  /**
   * Setup global event listeners
   * @private
   */
  setupEventListeners() {
    if (typeof window !== 'undefined') {
      // Save progress before page unload
      window.addEventListener('beforeunload', () => {
        if (this.saveTimeoutId) {
          clearTimeout(this.saveTimeoutId);
          this.saveProgress(); // Immediate save
        }
      });

      // Handle storage events from other tabs
      window.addEventListener('storage', (event) => {
        if (event.key && event.key.startsWith(this.config.storagePrefix)) {
          this.handleExternalStorageChange(event);
        }
      });
    }
  }

  /**
   * Handle storage changes from other tabs/windows
   * @param {StorageEvent} event - Storage event
   * @private
   */
  handleExternalStorageChange(event) {
    try {
      const moduleKey = event.key.replace(this.config.storagePrefix, '');

      if (event.newValue) {
        const data = JSON.parse(event.newValue);
        this.progressData.set(moduleKey, data);
        this._log('log', `[ProgressCore] External update detected for ${moduleKey}`);
      } else {
        this.progressData.delete(moduleKey);
        this._log('log', `[ProgressCore] External deletion detected for ${moduleKey}`);
      }
    } catch (error) {
      this.handleError('Failed to handle external storage change', error);
    }
  }

  /**
   * Register a module with the progress system
   * @param {string} moduleKey - Module identifier
   * @param {Object} moduleInstance - Module instance
   * @returns {boolean} Success status
   */
  registerModule(moduleKey, moduleInstance) {
    try {
      this.moduleStates.set(moduleKey, {
        instance: moduleInstance,
        registered: new Date().toISOString(),
        dependencies: this.dependencies.get(moduleKey) || []
      });

      this._log('log', `[ProgressCore] Registered module: ${moduleKey}`);
      return true;
    } catch (error) {
      this.handleError(`Failed to register module ${moduleKey}`, error);
      return false;
    }
  }

  /**
   * Clear all progress data
   * @returns {boolean} Success status
   */
  clearAllProgress() {
    try {
      // Clear in-memory data
      this.progressData.clear();

      // Clear localStorage
      const keys = this.getStorageKeys();
      keys.forEach(key => localStorage.removeItem(key));

      this._log('log', '[ProgressCore] Cleared all progress data');
      return true;
    } catch (error) {
      this.handleError('Failed to clear progress data', error);
      return false;
    }
  }

  /**
   * Get system health information
   * @returns {Object} Health status
   */
  getSystemHealth() {
    return {
      initialized: this.isInitialized,
      modulesTracked: this.progressData.size,
      modulesRegistered: this.moduleStates.size,
      lastSaveTime: this.lastSaveTime,
      memoryUsage: this.getMemoryUsage(),
      storageUsage: this.getStorageUsage()
    };
  }

  /**
   * Get approximate memory usage
   * @returns {number} Memory usage in bytes
   * @private
   */
  getMemoryUsage() {
    try {
      return JSON.stringify(Array.from(this.progressData.entries())).length;
    } catch {
      return 0;
    }
  }

  /**
   * Get localStorage usage for our data
   * @returns {number} Storage usage in bytes
   * @private
   */
  getStorageUsage() {
    try {
      const keys = this.getStorageKeys();
      return keys.reduce((total, key) => {
        const item = localStorage.getItem(key);
        return total + (item ? item.length : 0);
      }, 0);
    } catch {
      return 0;
    }
  }

  /**
   * Handle errors with fallback logging
   * @param {string} message - Error message
   * @param {Error} error - Error object
   * @private
   */
  handleError(message, error) {
    if (this.errorHandler && typeof this.errorHandler.handleError === 'function') {
      this.errorHandler.handleError(error, message);
    } else {
      this._log('error', `[ProgressCore] ${message}:`, error);
    }
  }

  /**
   * Cleanup resources and event listeners
   */
  destroy() {
    // Clear any pending saves
    if (this.saveTimeoutId) {
      clearTimeout(this.saveTimeoutId);
      this.saveProgress(); // Final save
    }

    // Clear debounce timeout
    if (this.updateDebounceTimeout) {
      clearTimeout(this.updateDebounceTimeout);
    }

    // Clear global reference
    if (typeof window !== 'undefined' && window.progressCore === this) {
      window.progressCore = null;
    }

    this._log('log', '[ProgressCore] Cleanup completed');
  }
}

// Default export for backward compatibility
export default ProgressCore;
