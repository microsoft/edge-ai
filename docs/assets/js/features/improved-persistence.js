/**
 * Improved Progress Persistence
 * Enhanced save/load functionality with optimistic updates, checks    if (!progressData || typeof progressData !== 'object') {
      return { success: false, error: 'Invalid progress data' };
    } and     if (!navigator.onLine) {
      this.offlineQueue.push({ data: progressData, timestamp: Date.now() });
      return { success: true, offline: true };
    }save
 */

// Simple hash function for browser environment (replaces crypto.createHash)
function createSimpleHash(data) {
  let hash = 0;
  if (data.length === 0) {return hash.toString();}
  for (let i = 0; i < data.length; i++) {
    const char = data.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32bit integer
  }
  return Math.abs(hash).toString(16);
}

/**
 * Enhanced persistence class with advanced features
 */
export class ImprovedPersistence {
  constructor(options = {}) {
    this.apiClient = options.apiClient;
    this.autoSaveInterval = options.autoSaveInterval || 30000; // 30 seconds default
    this.autoSaveTimer = null;
    this.dirtyData = new Map();
    this.cache = new Map();
    this.offlineQueue = [];
    this.isOffline = false;
    this.debounceTimeout = null;
    this.eventListeners = {
      uiUpdate: [],
      uiRevert: [],
      uiConfirm: [],
      autoSave: [],
      batchSave: [],
      debouncedSave: [],
      error: []
    };
    this.conflictResolver = null;
    this.retryConfig = {
      maxRetries: 3,
      baseDelay: 1000,
      maxDelay: 10000
    };
  }

  /**
   * Register event listeners
   */
  onUIUpdate(callback) {
    this.eventListeners.uiUpdate.push(callback);
  }

  onUIRevert(callback) {
    this.eventListeners.uiRevert.push(callback);
  }

  onUIConfirm(callback) {
    this.eventListeners.uiConfirm.push(callback);
  }

  onAutoSave(callback) {
    this.eventListeners.autoSave.push(callback);
  }

  onBatchSave(callback) {
    this.eventListeners.batchSave.push(callback);
  }

  onDebouncedSave(callback) {
    this.eventListeners.debouncedSave.push(callback);
  }

  onError(callback) {
    this.eventListeners.error.push(callback);
  }

  /**
   * Emit events to registered listeners
   */
  emit(eventType, data) {
    const listeners = this.eventListeners[eventType] || [];
    listeners.forEach(callback => {
      try {
        callback(data);
      } catch (_error) {
        // Error in listener ignored for production
      }
    });
  }

  /**
   * Save method for backward compatibility and debouncing tests
   */
  async save(taskId, progressData) {
    const data = typeof progressData === 'object' ? progressData : { taskId, ...progressData };
    return await this.saveProgress(data);
  }

  /**
   * Save progress with optimistic UI updates
   */
  async saveProgress(progressData) {
    if (!progressData || typeof progressData !== 'object') {
      return { success: false, error: 'Invalid data' };
    }

    // Optimistic UI update
    this.emit('uiUpdate', progressData);

    // Handle offline mode
    if (this.isOffline) {
      this.offlineQueue.push(progressData);
      return { success: true, offline: true };
    }

    // Debounce rapid saves
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout);
    }

    return new Promise((resolve) => {
      this.debounceTimeout = setTimeout(async () => {
        this.emit('debouncedSave', progressData);

        try {
          const result = await this.performSaveWithRetry(progressData);

          if (result.success) {
            this.emit('uiConfirm', progressData);
            this.invalidateCache(progressData.taskId);
          } else {
            this.emit('uiRevert', progressData);
          }

          resolve(result);
        } catch (_error) {
          this.emit('error', {
            type: 'NETWORK_ERROR',
            message: _error.message,
            data: progressData
          });
          this.emit('uiRevert', progressData);
          resolve({ success: false, error: _error.message });
        }
      }, 250);
    });
  }

  /**
   * Perform save with retry logic
   */
  async performSaveWithRetry(progressData, retryCount = 0) {
    try {
      const result = await this.apiClient.save(progressData);
      return result;
    } catch (_error) {
      if (retryCount < this.retryConfig.maxRetries) {
        const delay = Math.min(
          this.retryConfig.baseDelay * Math.pow(2, retryCount),
          this.retryConfig.maxDelay
        );

        await new Promise(resolve => setTimeout(resolve, delay));
        return this.performSaveWithRetry(progressData, retryCount + 1);
      }
      throw _error;
    }
  }

  /**
   * Load progress with conflict detection
   */
  async loadProgress(taskId, options = {}) {
    if (!taskId) {
      return null;
    }

    // Check cache first
    if (this.cache.has(taskId)) {
      return this.cache.get(taskId);
    }

    try {
      // Load from localStorage
      const localStorageKey = `progress_${taskId}`;
      const localDataStr = localStorage.getItem(localStorageKey);
      let localData = null;
      let localChecksum = null;

      if (localDataStr) {
        try {
          const parsed = JSON.parse(localDataStr);
          localData = parsed.data;
          localChecksum = parsed.checksum;

          // Validate checksum
          if (!this.validateChecksum(localData, localChecksum)) {
            localData = null;
          }
        } catch (_error) {
          localData = null;
        }
      }

      // Load from API
      const remoteData = await this.apiClient.load(taskId);

      // Handle conflicts
      if (localData && remoteData) {
        const localModified = new Date(localData.lastModified || 0);
        const remoteModified = new Date(remoteData.lastModified || 0);

        if (localModified.getTime() !== remoteModified.getTime()) {
          if (options.autoResolve) {
            const resolvedData = localModified > remoteModified ? localData : remoteData;
            this.cache.set(taskId, resolvedData);
            return { ...resolvedData, hasConflict: false };
          }

          if (this.conflictResolver) {
            const resolution = await this.conflictResolver(localData, remoteData);
            const resolvedData = resolution === 'remote' ? remoteData : localData;
            this.cache.set(taskId, resolvedData);
            return resolvedData;
          }

          return {
            hasConflict: true,
            localData,
            remoteData
          };
        }
      }

      const resultData = remoteData || localData;

      if (resultData) {
        this.cache.set(taskId, resultData);
      }

      return resultData;
    } catch (_error) {
      this.emit('error', {
        type: 'LOAD_ERROR',
        message: _error.message,
        taskId
      });
      return null;
    }
  }

  /**
   * Generate checksum for data integrity
   */
  generateChecksum(data) {
    if (!data || typeof data !== 'object') {
      return '';
    }

    const dataString = JSON.stringify(data, Object.keys(data).sort());
    return createSimpleHash(dataString);
  }

  /**
   * Validate data checksum
   */
  validateChecksum(data, checksum) {
    if (!data || !checksum) {
      return false;
    }

    const expectedChecksum = this.generateChecksum(data);
    return expectedChecksum === checksum;
  }

  /**
   * Enable auto-save functionality
   */
  enableAutoSave() {
    if (this.autoSaveTimer) {
      return;
    }

    this.autoSaveTimer = setInterval(() => {
      this.performAutoSave();
    }, this.autoSaveInterval);

  }

  /**
   * Disable auto-save functionality
   */
  disableAutoSave() {
    if (this.autoSaveTimer) {
      clearInterval(this.autoSaveTimer);
      this.autoSaveTimer = null;
    }
  }

  /**
   * Mark data as dirty for auto-save
   */
  markDirty(taskId, data) {
    this.dirtyData.set(taskId, data);
  }

  /**
   * Perform auto-save of dirty data
   */
  async performAutoSave() {
    if (this.dirtyData.size === 0) {
      return;
    }

    const dirtyItems = Array.from(this.dirtyData.entries()).map(([taskId, data]) => ({
      taskId,
      data
    }));

    this.emit('autoSave', dirtyItems);

    if (dirtyItems.length === 1) {
      const item = dirtyItems[0];
      await this.saveProgress({ taskId: item.taskId, ...item.data });
    } else {
      this.emit('batchSave', dirtyItems);

      try {
        await this.apiClient.batchSync(dirtyItems.map(item => ({ taskId: item.taskId, ...item.data })));
        this.dirtyData.clear();
      } catch (_error) {
        this.emit('error', {
          type: 'BATCH_SAVE_ERROR',
          message: _error.message,
          items: dirtyItems
        });
      }
    }
  }

  /**
   * Set conflict resolver function
   */
  setConflictResolver(resolver) {
    this.conflictResolver = resolver;
  }

  /**
   * Set offline mode
   */
  setOfflineMode(offline) {
    this.isOffline = offline;

    if (!offline && this.offlineQueue.length > 0) {
      // Auto-sync when coming back online
      this.syncOfflineQueue();
    }
  }

  /**
   * Get offline queue
   */
  getOfflineQueue() {
    return [...this.offlineQueue];
  }

  /**
   * Sync offline queue
   */
  async syncOfflineQueue() {
    if (this.offlineQueue.length === 0) {
      return { success: true, synced: 0 };
    }

    try {
      const result = await this.apiClient.batchSync(this.offlineQueue);

      if (result.success) {
        this.offlineQueue = [];
        // Successfully synced offline queue items
        this.offlineQueue = [];
      }

      return result;
    } catch (_error) {
      this.emit('error', {
        type: 'OFFLINE_SYNC_ERROR',
        message: _error.message,
        queueSize: this.offlineQueue.length
      });
      return { success: false, error: _error.message };
    }
  }

  /**
   * Invalidate cache entry
   */
  invalidateCache(taskId) {
    this.cache.delete(taskId);
  }

  /**
   * Clear all cached data
   */
  clearCache() {
    this.cache.clear();
  }

  /**
   * Destroy the persistence instance
   */
  destroy() {
    this.disableAutoSave();

    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout);
    }

    this.cache.clear();
    this.dirtyData.clear();
    this.offlineQueue = [];

    // Clear event listeners
    Object.keys(this.eventListeners).forEach(key => {
      this.eventListeners[key] = [];
    });

  }
}

/**
 * Create a new improved persistence instance
 */
export function createImprovedPersistence(_options = {}) {
  return new ImprovedPersistence(_options);
}
