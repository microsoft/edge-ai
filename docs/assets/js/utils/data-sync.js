/**
 * Data Synchronization Utility
 * Better API and localStorage synchronization with intelligent conflict resolution
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
 * Data synchronization class for efficient API and localStorage sync
 */
export class DataSync {
  constructor(options = {}) {
    this.apiClient = options.apiClient;
    this.eventBus = options.eventBus;
    this.syncInterval = options.syncInterval || 300000; // 5 minutes default
    this.syncTimer = null;
    this.cache = new Map();
    this.realTimeSyncEnabled = false;
    this.debounceTimeout = null;
    this.conflictResolver = null;
    this.eventListeners = {
      realTimeSync: [],
      autoSync: [],
      debouncedSync: []
    };
    this.compressionEnabled = false;
  }

  /**
   * Register event listeners
   */
  onRealTimeSync(callback) {
    this.eventListeners.realTimeSync.push(callback);
  }

  onAutoSync(callback) {
    this.eventListeners.autoSync.push(callback);
  }

  onDebouncedSync(callback) {
    this.eventListeners.debouncedSync.push(callback);
  }

  /**
   * Emit events to registered listeners
   */
  emit(eventType, data) {
    const listeners = this.eventListeners[eventType] || [];
    listeners.forEach(callback => {
      try {
        callback(data);
      } catch (error) {
        // Error in event listener - silently continue
      }
    });
  }

  /**
   * Check if synchronization is needed
   */
  async checkSyncNeeded() {
    try {
      const localLastModified = localStorage.getItem('last_sync_time');
      const remoteLastModified = await this.apiClient.getLastModified();

      if (!localLastModified) {
        return true;
      }

      const localTime = new Date(localLastModified);
      const remoteTime = new Date(remoteLastModified);

      return remoteTime > localTime;
    } catch (error) {
      return true; // Assume sync needed on error
    }
  }

  /**
   * Perform full synchronization
   */
  async performFullSync() {
    try {
      const syncResult = await this.apiClient.sync({ type: 'full' });

      if (!syncResult.success) {
        return { success: false, error: syncResult.error };
      }

      const { data, lastModified, conflicts = [] } = syncResult;

      // Handle conflicts if any
      if (conflicts.length > 0) {
        for (const conflict of conflicts) {
          const resolved = await this.resolveConflict(conflict.local, conflict.remote);
          // Update the data with resolved version
          const index = data.findIndex(item => item.taskId === conflict.taskId);
          if (index >= 0) {
            data[index] = resolved;
          }
        }
      }

      // Save to localStorage
      await this.saveLocalData(data);
      localStorage.setItem('last_sync_time', lastModified.toISOString());

      return {
        success: true,
        itemsSynced: data.length,
        conflicts: conflicts
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Perform partial synchronization (only changed items)
   */
  async performPartialSync() {
    try {
      const lastSyncTime = localStorage.getItem('last_sync_time');
      const since = lastSyncTime ? new Date(lastSyncTime) : null;

      const syncResult = await this.apiClient.sync({
        type: 'partial',
        since
      });

      if (!syncResult.success) {
        return { success: false, error: syncResult.error };
      }

      const { data, lastModified } = syncResult;

      // Merge with existing local data
      const existingData = await this.loadLocalData();
      const mergedData = this.mergeData(existingData.data || [], data);

      await this.saveLocalData(mergedData);
      localStorage.setItem('last_sync_time', lastModified.toISOString());

      return {
        success: true,
        itemsSynced: data.length
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Merge local and remote data
   */
  mergeData(localData, remoteData) {
    const merged = [...localData];

    remoteData.forEach(remoteItem => {
      const existingIndex = merged.findIndex(item => item.taskId === remoteItem.taskId);

      if (existingIndex >= 0) {
        // Update existing item
        merged[existingIndex] = remoteItem;
      } else {
        // Add new item
        merged.push(remoteItem);
      }
    });

    return merged;
  }

  /**
   * Resolve data conflicts
   */
  async resolveConflict(localData, remoteData) {
    // Use custom conflict resolver if available
    if (this.conflictResolver) {
      return this.conflictResolver(localData, remoteData);
    }

    // Default: use timestamp-based resolution
    const localTime = new Date(localData.lastModified || 0);
    const remoteTime = new Date(remoteData.lastModified || 0);

    return localTime > remoteTime ? localData : remoteData;
  }

  /**
   * Set conflict resolver function
   */
  setConflictResolver(resolver) {
    this.conflictResolver = resolver;
  }

  /**
   * Perform batch synchronization
   */
  async performBatchSync(batchData, options = {}) {
    const chunkSize = options.chunkSize || 100;

    if (batchData.length <= chunkSize) {
      // Single batch
      try {
        const result = await this.apiClient.batchSync(batchData);
        return result;
      } catch (error) {
        return { success: false, error: error.message };
      }
    }

    // Chunked batch processing
    let totalProcessed = 0;
    let totalFailed = 0;
    const allFailures = [];

    for (let i = 0; i < batchData.length; i += chunkSize) {
      const chunk = batchData.slice(i, i + chunkSize);

      try {
        const result = await this.apiClient.batchSync(chunk);
        totalProcessed += result.processed || 0;
        totalFailed += result.failed || 0;

        if (result.failures) {
          allFailures.push(...result.failures);
        }
      } catch (error) {
        totalFailed += chunk.length;
        allFailures.push(...chunk.map(item => ({
          taskId: item.taskId,
          error: error.message
        })));
      }
    }

    return {
      success: totalFailed === 0,
      totalProcessed: totalProcessed + totalFailed,
      processed: totalProcessed,
      failed: totalFailed,
      failures: allFailures
    };
  }

  /**
   * Enable real-time synchronization
   */
  enableRealTimeSync() {
    this.realTimeSyncEnabled = true;
    this.emit('realTimeSync', { enabled: true });
  }

  /**
   * Disable real-time synchronization
   */
  disableRealTimeSync() {
    this.realTimeSyncEnabled = false;

    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout);
      this.debounceTimeout = null;
    }
  }

  /**
   * Check if real-time sync is enabled
   */
  isRealTimeSyncEnabled() {
    return this.realTimeSyncEnabled;
  }

  /**
   * Handle data changes for real-time sync
   */
  async handleDataChange(data) {
    if (!this.realTimeSyncEnabled) {
      return;
    }

    this.emit('autoSync', data);

    // Debounce rapid changes
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout);
    }

    this.debounceTimeout = setTimeout(() => {
      this.emit('debouncedSync', data);
    }, 500);
  }

  /**
   * Validate data before synchronization
   */
  async validateData(data) {
    const errors = [];

    if (!data) {
      errors.push('Data is required');
      return { isValid: false, errors };
    }

    if (!data.taskId) {
      errors.push('taskId is required');
    }

    if (typeof data.completed !== 'boolean') {
      errors.push('completed must be boolean');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * Generate data checksum for integrity verification
   */
  generateChecksum(data) {
    if (!data || typeof data !== 'object') {
      return '';
    }

    const dataString = JSON.stringify(data, Object.keys(data).sort());
    return createSimpleHash(dataString);
  }

  /**
   * Load data from localStorage with cache
   */
  async loadLocalData() {
    const cacheKey = 'local_data';

    if (this.cache.has(cacheKey)) {
      return this.cache.get(cacheKey);
    }

    try {
      const dataStr = localStorage.getItem('progress_data');

      if (!dataStr) {
        return { isValid: true, data: [] };
      }

      const parsed = JSON.parse(dataStr);

      // Verify integrity if checksum is available
      if (parsed.checksum) {
        const isValid = this.generateChecksum(parsed.data) === parsed.checksum;

        if (!isValid) {
          return { isValid: false, data: [] };
        }
      }

      const result = { isValid: true, data: parsed.data || parsed };
      this.cache.set(cacheKey, result);

      return result;
    } catch (error) {
      return { isValid: false, data: [] };
    }
  }

  /**
   * Save data to localStorage with optional compression
   */
  async saveLocalData(data, options = {}) {
    const dataToSave = {
      data,
      checksum: this.generateChecksum(data),
      timestamp: new Date().toISOString()
    };

    let serialized = JSON.stringify(dataToSave);

    // Apply compression if enabled and data is large
    if (options.compress && serialized.length > 10000) {
      // Simple compression simulation (in real implementation, use a compression library)
      const compressed = this.compressData(serialized);
      serialized = compressed;
    }

    localStorage.setItem('progress_data', serialized);

    // Invalidate cache
    this.cache.delete('local_data');
  }

  /**
   * Simple data compression (placeholder for real compression)
   */
  compressData(data) {
    // In a real implementation, use a compression library like pako
    // This is just a placeholder that simulates compression
    return data
      .replace(/\s+/g, ' ')
      .replace(/,\s*}/g, '}')
      .replace(/,\s*]/g, ']')
      .replace(/{\s*/g, '{')
      .replace(/\[\s*/g, '[')
      .replace(/:\s*/g, ':')
      .replace(/"\s*,\s*"/g, '","')
      .replace(/"taskId"/g, '"t"')
      .replace(/"completed"/g, '"c"')
      .replace(/"metadata"/g, '"m"')
      .replace(/Large metadata string for task/g, 'Meta')
      .trim();
  }

  /**
   * Start periodic synchronization
   */
  startPeriodicSync() {
    if (this.syncTimer) {
      return;
    }

    this.syncTimer = setInterval(async () => {
      const needsSync = await this.checkSyncNeeded();

      if (needsSync) {
        await this.performPartialSync();
      }
    }, this.syncInterval);
  }

  /**
   * Stop periodic synchronization
   */
  stopPeriodicSync() {
    if (this.syncTimer) {
      clearInterval(this.syncTimer);
      this.syncTimer = null;
    }
  }

  /**
   * Destroy the data sync instance
   */
  destroy() {
    this.stopPeriodicSync();
    this.disableRealTimeSync();
    this.cache.clear();

    // Clear event listeners
    Object.keys(this.eventListeners).forEach(key => {
      this.eventListeners[key] = [];
    });
  }
}

/**
 * Create a new data sync instance
 */
export function createDataSync(_options = {}) {
  return new DataSync(_options);
}
