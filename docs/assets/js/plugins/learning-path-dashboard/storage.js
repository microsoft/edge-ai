/**
 * Storage Mixin
 * Provides localStorage persistence for selected paths and preferences with resilience features
 *
 * @mixin storageMixin
 */

export const storageMixin = {
  /**
   * Initialize storage-related state
   */
  _initStorage() {
    this._memoryStorage = {
      selectedPaths: [],
      preferences: {},
      progress: {}
    };
    this._storageCache = new Map();
    this._storageBatchTimeout = null;
    this._storageRetryAttempts = 3;
    this._storageRetryDelay = 100;
    this.STORAGE_VERSION = 2;
    this._debounceTimeout = null;
    this._saveCount = 0;

    this._setupCrossTabSync();
    // cleanupExpiredData removed - no localStorage to clean
  },

  /**
   * Setup cross-tab synchronization listener
   */
  _setupCrossTabSync() {
    if (typeof window !== 'undefined') {
      this._storageEventHandler = (event) => this.handleExternalStorageChange(event);
      window.addEventListener('storage', this._storageEventHandler);
    }
  },

  /**
   * Cleanup storage resources and listeners
   */
  _cleanupStorage() {
    if (typeof window !== 'undefined' && this._storageEventHandler) {
      window.removeEventListener('storage', this._storageEventHandler);
      this._storageEventHandler = null;
    }

    if (this._debounceTimeout) {
      clearTimeout(this._debounceTimeout);
      this._debounceTimeout = null;
    }

    if (this._storageBatchTimeout) {
      clearTimeout(this._storageBatchTimeout);
      this._storageBatchTimeout = null;
    }

    if (this._storageCache) {
      this._storageCache.clear();
    }

    if (this._batchQueue) {
      this._batchQueue = [];
    }
  },

  /**
   * Handle external storage changes from other tabs
   * @param {StorageEvent} event - Storage event from other tab
   */
  handleExternalStorageChange(event) {
    // Only handle changes to selectedLearningPaths
    if (event.key !== 'selectedLearningPaths') {
      return;
    }

    try {
      // Parse old and new values
      const oldPaths = event.oldValue ? JSON.parse(event.oldValue) : [];
      const newPaths = event.newValue ? JSON.parse(event.newValue) : [];

      // Calculate diff
      const oldSet = new Set(oldPaths);
      const newSet = new Set(newPaths);

      const added = newPaths.filter(path => !oldSet.has(path));
      const removed = oldPaths.filter(path => !newSet.has(path));

      // Update local state
      this.selectedPaths = newSet;

      // Invalidate cache
      this._storageCache.delete('selectedPaths');

      // Emit cross-tab sync event
      const syncEvent = new CustomEvent('crossTabSync', {
        detail: {
          key: event.key,
          changes: {
            added,
            removed
          }
        }
      });

      // Dispatch to all containers (dashboard may have multiple)
      const containers = this.containers || (this.container ? [this.container] : []);
      containers.forEach(container => {
        if (container) {
          container.dispatchEvent(syncEvent);
        }
      });

      // Emit path selection changed event
      const selectionEvent = new CustomEvent('pathSelectionChanged', {
        detail: {
          selectedPaths: Array.from(this.selectedPaths),
          source: 'externalStorage'
        }
      });

      // Dispatch to all containers
      containers.forEach(container => {
        if (container) {
          container.dispatchEvent(selectionEvent);
        }
      });

      // Update path.selected property on all paths
      if (this.paths && Array.isArray(this.paths)) {
        this.paths.forEach(path => {
          if (path && path.id) {
            path.selected = this.selectedPaths.has(path.id);
          }
        });
      }

      this.log('debug', 'External storage change processed', { added, removed });
    } catch (error) {
      this.logError('Failed to process external storage change:', error);
    }
  },

  /**
   * Calculate checksum for data integrity
   * @param {string} data - Data to checksum
   * @returns {string} Checksum value
   */
  _calculateChecksum(data) {
    let hash = 0;
    for (let i = 0; i < data.length; i++) {
      const char = data.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return hash.toString(36);
  },

  /**
   * Compress data for storage
   * @param {string} data - Data to compress
   * @returns {string} Compressed data
   */
  _compressData(data) {
    try {
      return btoa(encodeURIComponent(data).replace(/%([0-9A-F]{2})/g, (match, p1) => {
        return String.fromCharCode('0x' + p1);
      }));
    } catch (error) {
      this.logError('Compression failed, using uncompressed:', error);
      return data;
    }
  },

  /**
   * Decompress stored data
   * @param {string} data - Compressed data
   * @returns {string} Decompressed data
   */
  _decompressData(data) {
    try {
      return decodeURIComponent(atob(data).split('').map((c) => {
        return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
      }).join(''));
    } catch (error) {
      this.logError('Decompression failed, using as-is:', error);
      return data;
    }
  },

  /**
   * Retry storage operation with exponential backoff
   * @param {Function} operation - Storage operation to retry
   * @param {number} attempts - Number of retry attempts
   * @returns {Promise<any>} Operation result
   */
  async _retryStorageOperation(operation, attempts = this._storageRetryAttempts) {
    let lastError;
    for (let i = 0; i < attempts; i++) {
      try {
        const result = await operation();
        return result;
      } catch (error) {
        lastError = error;
        if (i === attempts - 1) {
          throw error;
        }
        await new Promise(resolve => setTimeout(resolve, this._storageRetryDelay * Math.pow(2, i)));
      }
    }
    throw lastError;
  },

  /**
   * Emit storage error event
   * @param {Error} error - The error that occurred
   * @param {string} operation - The operation that failed
   * @private
   */
  _emitStorageError(error, operation) {
    console.log('[DEBUG _emitStorageError] ENTRY - error:', error, 'operation:', operation);
    console.log('[DEBUG _emitStorageError] this.container:', this.container);
    console.log('[DEBUG _emitStorageError] this.containers:', this.containers);

    const event = new CustomEvent('storageError', {
      detail: { error, operation }
    });
    console.log('[DEBUG _emitStorageError] Created event:', event);

    // Support both single container and multi-container architecture
    const containers = this.containers || (this.container ? [this.container] : []);
    console.log('[DEBUG _emitStorageError] containers array:', containers, 'length:', containers.length);

    containers.forEach((container, index) => {
      console.log(`[DEBUG _emitStorageError] Processing container ${index}:`, container);
      console.log(`[DEBUG _emitStorageError] Container ${index} has dispatchEvent:`, typeof container.dispatchEvent);
      if (container && typeof container.dispatchEvent === 'function') {
        console.log(`[DEBUG _emitStorageError] Dispatching event on container ${index}`);
        container.dispatchEvent(event);
        console.log(`[DEBUG _emitStorageError] Event dispatched on container ${index}`);
      }
    });
    this.log('error', 'Storage operation failed:', { error, operation });
  },

  /**
   * Get memory storage (fallback)
   * @returns {Object} Memory storage object
   */
  getMemoryStorage() {
    return this._memoryStorage;
  },

  /**
   * Load selected paths from localStorage (and server if enabled)
   */
  async loadSelectedPathsFromStorage() {
    const cacheKey = 'selectedPaths';

    // Server-only - no localStorage fallback
    try {
      const serverPaths = await this.loadSelectionsFromServer();
      if (serverPaths && serverPaths.length > 0) {
        this.selectedPaths = new Set(serverPaths);
        this._storageCache.set(cacheKey, serverPaths);

          // Update path.selected property on all path references
          [this.paths, this.learningPaths, this.filteredPaths].forEach(pathArray => {
            if (pathArray) {
              pathArray.forEach(path => {
                path.selected = this.selectedPaths.has(path.id);
              });
            }
          });

        this.log('debug', `Loaded ${serverPaths.length} selected paths from server`);
        return serverPaths;
      }

      // No server data, return empty
      this.selectedPaths = new Set();
      this._storageCache.set(cacheKey, []);
      return [];
    } catch (error) {
      this.logError('Failed to load selected paths from server:', error);
      throw new Error('❌ Failed to load selections. Check API server connection.');
    }
  },

  /**
   * Save selected paths to localStorage
   */
  saveSelectedPathsToStorage() {
    console.log('[DEBUG saveSelectedPathsToStorage] ENTRY - selectedPaths:', this.selectedPaths);
    console.log('[DEBUG saveSelectedPathsToStorage] container:', this.container);
    console.log('[DEBUG saveSelectedPathsToStorage] containers:', this.containers);

    const selectedArray = Array.from(this.selectedPaths);
    this._memoryStorage.selectedPaths = selectedArray;
    this._storageCache.set('selectedPaths', selectedArray);

    // If in batch mode, collect the write instead of executing it
    if (this._isBatchMode && this._batchWrites) {
      this._batchWrites.set('selectedLearningPaths', JSON.stringify(selectedArray));
      this.log('debug', `Queued ${selectedArray.length} selected paths for batch write`);
      return;
    }

    console.log('[DEBUG saveSelectedPathsToStorage] About to call server API');
    try {
      // Server-only save - no localStorage
      this._saveSelectionsToServer(selectedArray);
      console.log('[DEBUG saveSelectedPathsToStorage] Server save initiated');
      this.log('debug', `Saved ${selectedArray.length} selected paths to server`);
    } catch (error) {
      console.log('[DEBUG saveSelectedPathsToStorage] Caught error:', error);
      this._emitStorageError(error, 'save');
      this.logError('Failed to save selected paths:', error);
      throw error;
    }
  },

  /**
   * Save selected paths to API server
   * @param {Array} selectedArray - Array of selected path IDs
   * @private
   */
  async _saveSelectionsToServer(selectedArray) {
    try {
      const userId = this.config?.userId || 'default-user';
      const response = await fetch('http://localhost:3002/api/learning/selections', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          selectedPaths: selectedArray,
          userId: userId
        })
      });

      if (!response) {
        throw new Error('No response from server');
      }

      if (!response.ok) {
        throw new Error(`Server returned ${response.status}: ${response.statusText}`);
      }

      const result = await response.json();

      if (result.success) {
        this.log('debug', `Saved ${selectedArray.length} selected paths to server: ${result.filename}`);
      } else {
        this.logError('Server rejected selection save:', result.error);
        throw new Error(`Server rejected save: ${result.error}`);
      }
    } catch (error) {
      this.logError('Failed to save selections to server:', error);
      throw error;
    }
  },

  /**
   * Load selected paths from API server
   * @returns {Promise<Array>} Selected paths array
   */
  async loadSelectionsFromServer() {
    try {
      const userId = this.config?.userId || 'default-user';
      const response = await fetch(`http://localhost:3002/api/learning/selections?userId=${userId}`);

      if (!response) {
        throw new Error('No response from server');
      }

      if (!response.ok) {
        throw new Error(`Server returned ${response.status}: ${response.statusText}`);
      }

      const result = await response.json();

      if (result.success && result.selections) {
        this.log('debug', `Loaded ${result.selections.selectionCount} selected paths from server`);
        return result.selections.selectedPaths || [];
      }

      return [];
    } catch (error) {
      this.logError('Failed to load selections from server:', error);
      return [];
    }
  },

  /**
   * Save selected paths to localStorage with retry logic
   */
  async saveSelectedPathsToStorageWithRetry() {
    const selectedArray = Array.from(this.selectedPaths);
    this._memoryStorage.selectedPaths = selectedArray;
    this._storageCache.set('selectedPaths', selectedArray);

    return this._retryStorageOperation(() => {
      // Server-only save
      this._saveSelectionsToServer(selectedArray);
      this.log('debug', `Saved ${selectedArray.length} selected paths to server`);
    });
  },

  /**
   * Save dashboard preferences to localStorage
   * @param {Object} preferences - Preferences object to save
   */
  savePreferences(preferences) {
    // Preferences not persisted - session only
    this.log('debug', 'Dashboard preferences not persisted (session only)');
  },

  /**
   * Load dashboard preferences from localStorage
   * @returns {Object} Preferences object or empty object if none found
   */
  loadPreferences() {
    // Preferences not persisted - return defaults
    return {};
  },

  /**
   * Save progress data to localStorage
   * @param {Object} [progress] - Progress object to save (defaults to empty object)
   */
  saveProgress(progress = {}) {
    // If in batch mode, collect the write instead of executing it
    if (this._isBatchMode && this._batchWrites) {
      this._batchWrites.set('dashboardProgress', JSON.stringify(progress));
      this.log('debug', 'Queued dashboard progress for batch write');
      return;
    }

    try {
      localStorage.setItem('dashboardProgress', JSON.stringify(progress));
      this.log('debug', 'Saved dashboard progress to storage');
    } catch (error) {
      this.logError('Failed to save progress:', error);
    }
  },

  /**
   * Save selected paths to localStorage with integrity checking
   * @param {Array} [data] - Optional data array to save (defaults to this.selectedPaths)
   */
  async saveSelectedPathsToStorageWithIntegrity(data) {
    const selectedArray = data ? Array.from(data) : Array.from(this.selectedPaths);
    const timestamp = Date.now();
    const dataStr = JSON.stringify(selectedArray);
    const checksum = this._calculateChecksum(dataStr);

    const integrityData = {
      data: selectedArray,
      checksum,
      timestamp,
      version: this.STORAGE_VERSION
    };

    this._memoryStorage.selectedPaths = selectedArray;
    this._storageCache.set('selectedPaths', selectedArray);

    try {
      await this._retryStorageOperation(() => {
        // Server-only save with integrity data
        this._saveSelectionsToServer(selectedArray);
      });
      this.log('debug', `Saved ${selectedArray.length} selected paths to server with integrity`);
    } catch (error) {
      this.logError('Failed to save selected paths with integrity:', error);
      this._emitStorageError(error, 'saveWithIntegrity');
      throw error;
    }
  },

  /**
   * Load selected paths from localStorage with integrity checking
   * @returns {Array} Selected paths array
   */
  async loadSelectedPathsFromStorageWithIntegrity() {
    // Load from server only - no localStorage
    try {
      const serverPaths = await this.loadSelectionsFromServer();
      this.selectedPaths = new Set(serverPaths || []);
      return serverPaths || [];
    } catch (error) {
      this.logError('Failed to load paths with integrity check:', error);
      throw error;
    }
  },

  /**
   * Migrate storage data from old format to new format
   */
  migrateStorageData() {
    // No localStorage migration needed - server is source of truth
    return [];
  },

  /**
   * Perform migration logic
   * @returns {boolean} Whether migration was performed
   */
  performMigration() {
    // No localStorage migration needed - server is source of truth
    return false;
  },

  /**
   * Batch storage updates to minimize write operations
   * @param {Function} updateFn - Function that performs storage updates
   */
  batchStorageUpdates(updateFn) {
    // No localStorage batch operations - server handles persistence
    this._isBatchMode = false;
    this._batchWrites = null;

    // Execute the update function if provided
    if (typeof updateFn === 'function') {
      updateFn();
    }

    this.log('debug', 'Batch mode disabled (localStorage removed)');
  },

  /**
   * Clean up expired data from localStorage (no-op, localStorage removed)
   * @param {number} maxAge - Maximum age in milliseconds (default: 30 days)
   */
  cleanupExpiredData(maxAge = 30 * 24 * 60 * 60 * 1000) {
    // No localStorage cleanup needed - server manages data lifecycle
    this.log('debug', 'Skipping localStorage cleanup (removed)');
  },

  /**
   * Enforce storage size limits (no-op, localStorage removed)
   * @param {number} maxSize - Maximum size in bytes
   */
  enforceStorageLimit(maxSize = 5 * 1024 * 1024) {
    // No localStorage limit enforcement needed - server manages storage
    this.log('debug', 'Skipping storage limit enforcement (localStorage removed)');
  }
};
