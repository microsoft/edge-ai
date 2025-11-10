/**
 * Learning Path Synchronization Component
 *
 * Handles persistence and synchronization of learning path selections and progress
 * across browser sessions and devices. Provides backup/restore functionality,
 * conflict resolution, and cross-device synchronization capabilities.
 *
 * Features:
 * - Session persistence using localStorage/sessionStorage
 * - Cross-device synchronization with conflict resolution
 * - Backup and restore functionality
 * - Data validation and integrity checks
 * - Error handling and recovery mechanisms
 * - Performance optimization for large datasets
 */

/**
 * Custom error class for synchronization operations
 */
export class SyncError extends Error {
  constructor(message, code = 'SYNC_ERROR', details = null) {
    super(message);
    this.name = 'SyncError';
    this.code = code;
    this.details = details;
    this.timestamp = new Date().toISOString();
  }
}

/**
 * Learning Path Synchronization Manager
 * Handles all aspects of learning path data persistence and synchronization
 */
export class LearningPathSync {
  /**
   * Creates a new LearningPathSync instance
   * @param {Object} dependencies - Required dependencies
   * @param {Object} dependencies.learningPathManager - Learning path manager instance
   * @param {Object} dependencies.storageManager - Storage manager for persistence
   * @param {Object} [dependencies.logger] - Logger instance for debugging
   * @param {Object} [options] - Configuration options
   */
  constructor(dependencies = {}, options = {}) {
    // Validate required dependencies
    if (!dependencies.learningPathManager) {
      throw new SyncError('Learning path manager is required', 'MISSING_DEPENDENCY');
    }
    if (!dependencies.storageManager) {
      throw new SyncError('Storage manager is required', 'MISSING_DEPENDENCY');
    }

    // Initialize dependencies
    this.learningPathManager = dependencies.learningPathManager;
    this.storageManager = dependencies.storageManager;
    this.logger = dependencies.logger || this._createDefaultLogger();

    // Configuration options with defaults
    this.options = {
      syncInterval: 30000, // 30 seconds
      conflictResolutionStrategy: 'merge', // 'merge', 'local', 'remote'
      maxBackupCount: 5,
      compressionEnabled: true,
      encryptionEnabled: false,
      validationEnabled: true,
      ...options
    };

    // Internal state
    this.isInitialized = false;
    this.syncInProgress = false;
    this.lastSyncTimestamp = null;
    this.syncTimer = null;
    this.eventListeners = new Map();

    // Bind methods to maintain context
    this._handleStorageEvent = this._handleStorageEvent.bind(this);
    this._handleVisibilityChange = this._handleVisibilityChange.bind(this);
    this._performPeriodicSync = this._performPeriodicSync.bind(this);

    this.logger.debug('LearningPathSync initialized with options:', this.options);
  }

  /**
   * Initializes the synchronization system
   * @returns {Promise<boolean>} Success status
   */
  async initialize() {
    if (this.isInitialized) {
      this.logger.warn('LearningPathSync already initialized');
      return true;
    }

    try {
      // Initialize storage manager
      await this.storageManager.initialize();

      // Load existing data
      await this._loadPersistedData();

      // Set up event listeners
      this._setupEventListeners();

      // Start periodic sync if enabled
      if (this.options.syncInterval > 0) {
        this._startPeriodicSync();
      }

      this.isInitialized = true;
      // this.logger.info('LearningPathSync initialized successfully');
      return true;
    } catch (_error) {
      this.logger.error('Failed to initialize LearningPathSync:', _error);
      throw new SyncError('Initialization failed', 'INIT_ERROR', _error);
    }
  }

  /**
   * Persists current learning path selections with enhanced validation
   * @param {Array<string|Object>} selectedPaths - Array of selected path IDs or path objects
   * @returns {Promise<boolean>} Success status
   */
  async persistPathSelections(selectedPaths) {
    if (!this.isInitialized) {
      throw new SyncError('Sync manager not initialized', 'NOT_INITIALIZED');
    }

    try {
      // Enhanced input validation
      const validatedPaths = this._validateAndNormalizePathSelections(selectedPaths);

      // Prepare data for persistence with enhanced metadata
      const persistenceData = {
        selectedPaths: validatedPaths,
        timestamp: new Date().toISOString(),
        version: '1.0',
        source: 'user_selection',
        metadata: {
          pathCount: validatedPaths.length,
          dataSize: JSON.stringify(validatedPaths).length,
          lastModified: new Date().toISOString()
        }
      };

      // Add validation checksum if enabled
      if (this.options.validationEnabled) {
        persistenceData.checksum = this._calculateChecksum(persistenceData);
      }

      // Store data with retry mechanism for storage failures
      await this._storeDataWithRetry('learning_path_selections', persistenceData);

      this.logger.debug('Path selections persisted successfully:', {
        count: validatedPaths.length,
        dataSize: persistenceData.metadata.dataSize
      });
      return true;
    } catch (_error) {
      this.logger.error('Failed to persist path selections:', _error);
      throw new SyncError('Failed to persist path selections', 'PERSIST_ERROR', _error);
    }
  }

  /**
   * Validates and normalizes path selections input
   * @private
   * @param {Array<string|Object>} selectedPaths - Input path selections
   * @returns {Array<Object>} Normalized path selections
   */
  _validateAndNormalizePathSelections(selectedPaths) {
    if (!Array.isArray(selectedPaths)) {
      throw new SyncError('Selected paths must be an array', 'INVALID_INPUT');
    }

    // Normalize different input formats
    return selectedPaths.map((path, _index) => {
      if (typeof path === 'string') {
        return {
          pathId: path,
          selected: true,
          timestamp: Date.now()
        };
      } else if (typeof path === 'object' && path !== null) {
        if (!path.pathId) {
          throw new SyncError(`Path object at index ${_index} missing pathId`, 'INVALID_INPUT');
        }
        return {
          pathId: path.pathId,
          selected: path.selected !== undefined ? path.selected : true,
          timestamp: path.timestamp || Date.now(),
          ...path // Preserve additional properties
        };
      } else {
        throw new SyncError(`Invalid path type at index ${_index}: ${typeof path}`, 'INVALID_INPUT');
      }
    });
  }

  /**
   * Stores data with retry mechanism for improved reliability
   * @private
   * @param {string} key - Storage key
   * @param {Object} data - Data to store
   * @param {number} maxRetries - Maximum retry attempts
   */
  async _storeDataWithRetry(key, data, maxRetries = this.options.retryAttempts || 3) {
    let lastError;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await this.storageManager.setItem(key, data);
        return; // Success
      } catch (_error) {
        lastError = _error;
        this.logger.warn(`Storage attempt ${attempt}/${maxRetries} failed for key ${key}:`, _error);

        if (attempt < maxRetries) {
          // Exponential backoff: wait 100ms, 200ms, 400ms...
          const delay = Math.min(1000 * Math.pow(2, attempt - 1), 5000);
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }
    }

    // All retries failed
    throw new SyncError(`Failed to store data after ${maxRetries} attempts`, 'STORAGE_ERROR', lastError);
  }

  /**
   * Loads persisted learning path selections with enhanced error handling (public API)
   * @returns {Promise<Array<Object>|null>} Array of selected path objects or null if none found
   */
  async loadPathSelections() {
    if (!this.isInitialized) {
      throw new SyncError('Sync manager not initialized', 'NOT_INITIALIZED');
    }

    return await this._loadPathSelectionsInternal();
  }

  /**
   * Internal method to load path selections without initialization check
   * Used during initialization and by public loadPathSelections method
   * @private
   * @returns {Promise<Array<Object>|null>} Array of selected path objects or null if none found
   */
  async _loadPathSelectionsInternal() {
    try {
      const persistedData = await this.storageManager.getItem('learning_path_selections');

      if (!persistedData) {
        this.logger.debug('No persisted path selections found');
        return null;
      }

      // Enhanced data validation
      const validationResult = this._validatePersistedData(persistedData);
      if (!validationResult.isValid) {
        this.logger.warn('Persisted data validation failed:', validationResult.error);
        return [];
      }

      // Validate data integrity if enabled
      if (this.options.validationEnabled && persistedData.checksum) {
        const isValid = this._validateChecksum(persistedData);
        if (!isValid) {
          this.logger.warn('Persisted data failed integrity check, discarding');
          return [];
        }
      }

      // Normalize legacy data formats for backward compatibility
      const normalizedSelections = this._normalizeLegacyDataFormat(persistedData.selectedPaths);

      this.logger.debug('Path selections loaded successfully:', {
        count: normalizedSelections.length,
        source: persistedData.source || 'unknown',
        timestamp: persistedData.timestamp
      });

      return normalizedSelections;
    } catch (_error) {
      this.logger.error('Failed to load path selections:', _error);
      throw new SyncError('Load failed', 'LOAD_ERROR', _error);
    }
  }

  /**
   * Validates persisted data structure and content
   * @private
   * @param {Object} data - Persisted data to validate
   * @returns {Object} Validation result with isValid flag and error details
   */
  _validatePersistedData(data) {
    if (!data || typeof data !== 'object') {
      return { isValid: false, error: 'Data is not an object' };
    }

    if (!data.selectedPaths) {
      return { isValid: false, error: 'Missing selectedPaths property' };
    }

    if (!Array.isArray(data.selectedPaths)) {
      return { isValid: false, error: 'selectedPaths is not an array' };
    }

    // Check for reasonable data size limits (prevent DoS attacks)
    const dataSize = JSON.stringify(data).length;
    const maxDataSize = 10 * 1024 * 1024; // 10MB limit
    if (dataSize > maxDataSize) {
      return { isValid: false, error: `Data size ${dataSize} exceeds limit ${maxDataSize}` };
    }

    return { isValid: true };
  }

  /**
   * Normalizes legacy data formats for backward compatibility
   * @private
   * @param {Array<string|Object>} selections - Path selections in various formats
   * @returns {Array<Object>} Normalized path selection objects
   */
  _normalizeLegacyDataFormat(selections) {
    if (!Array.isArray(selections)) {
      return [];
    }

    return selections.map(selection => {
      // Handle legacy string format
      if (typeof selection === 'string') {
        return {
          pathId: selection,
          selected: true,
          timestamp: Date.now()
        };
      }

      // Handle object format (current and future)
      if (typeof selection === 'object' && selection !== null) {
        return {
          pathId: selection.pathId,
          selected: selection.selected !== undefined ? selection.selected : true,
          timestamp: selection.timestamp || Date.now(),
          ...selection // Preserve additional properties
        };
      }

      // Invalid format - log warning and skip
      this.logger.warn('Skipping invalid path selection format:', selection);
      return null;
    }).filter(Boolean); // Remove null entries
  }

  /**
   * Synchronizes progress data across sessions/devices with enhanced conflict resolution
   * @param {Object} progressData - Progress data to synchronize
   * @returns {Promise<Object>} Synchronized progress data
   */
  async synchronizeProgress(progressData) {
    if (!this.isInitialized) {
      throw new SyncError('Sync manager not initialized', 'NOT_INITIALIZED');
    }

    if (this.syncInProgress) {
      this.logger.debug('Sync already in progress, skipping');
      return progressData;
    }

    this.syncInProgress = true;

    try {
      // Validate input data structure
      const validatedProgressData = this._validateProgressData(progressData);

      // Load existing progress from storage with fallback
      const existingProgress = await this._loadExistingProgressSafely();

      let synchronizedData;

      if (!existingProgress) {
        // No existing data, use current validated data
        synchronizedData = validatedProgressData;
      } else {
        // Resolve conflicts between existing and current data
        synchronizedData = await this._resolveProgressConflicts(existingProgress, validatedProgressData);
      }

      // Add enhanced metadata for tracking
      const persistenceData = {
        ...synchronizedData,
        lastSyncTimestamp: new Date().toISOString(),
        syncSource: 'auto',
        metadata: {
          syncVersion: '1.1',
          conflictResolutionStrategy: this.options.conflictResolutionStrategy,
          dataSize: JSON.stringify(synchronizedData).length,
          itemCount: this._calculateProgressItemCount(synchronizedData)
        }
      };

      // Add validation checksum if enabled
      if (this.options.validationEnabled) {
        persistenceData.checksum = this._calculateChecksum(persistenceData);
      }

      // Store with retry mechanism
      await this._storeDataWithRetry('learning_progress_data', persistenceData);

      this.lastSyncTimestamp = new Date().toISOString();
      this.logger.debug('Progress data synchronized successfully:', {
        itemCount: persistenceData.metadata.itemCount,
        dataSize: persistenceData.metadata.dataSize,
        strategy: persistenceData.metadata.conflictResolutionStrategy
      });

      return synchronizedData;
    } catch (_error) {
      this.logger.error('Failed to synchronize progress:', _error);
      throw new SyncError('Synchronization failed', 'SYNC_ERROR', _error);
    } finally {
      this.syncInProgress = false;
    }
  }

  /**
   * Validates progress data structure and content
   * @private
   * @param {Object} progressData - Progress data to validate
   * @returns {Object} Validated progress data
   */
  _validateProgressData(progressData) {
    if (!progressData || typeof progressData !== 'object') {
      throw new SyncError('Progress data must be an object', 'INVALID_PROGRESS_DATA');
    }

    // Check for circular references that could cause JSON.stringify issues
    try {
      JSON.stringify(progressData);
    } catch (_error) {
      throw new SyncError('Progress data contains circular references', 'INVALID_PROGRESS_DATA', _error);
    }

    // Create a safe copy to avoid mutations
    return JSON.parse(JSON.stringify(progressData));
  }

  /**
   * Safely loads existing progress data with error isolation
   * @private
   * @returns {Promise<Object|null>} Existing progress data or null
   */
  async _loadExistingProgressSafely() {
    try {
      const existingProgress = await this.storageManager.getItem('learning_progress_data');

      if (!existingProgress) {
        return null;
      }

      // Validate existing data integrity
      if (this.options.validationEnabled && existingProgress.checksum) {
        const isValid = this._validateChecksum(existingProgress);
        if (!isValid) {
          this.logger.warn('Existing progress data failed integrity check, treating as empty');
          return null;
        }
      }

      return existingProgress;
    } catch (_error) {
      this.logger.warn('Failed to load existing progress data safely:', _error);
      return null; // Treat as no existing data
    }
  }

  /**
   * Calculates the total number of progress items for metadata
   * @private
   * @param {Object} progressData - Progress data to analyze
   * @returns {number} Total count of progress items
   */
  _calculateProgressItemCount(progressData) {
    let count = 0;

    Object.values(progressData).forEach(value => {
      if (Array.isArray(value)) {
        count += value.length;
      } else if (typeof value === 'object' && value !== null) {
        count += Object.keys(value).length;
      } else {
        count += 1;
      }
    });

    return count;
  }

  /**
   * Creates a backup of current learning path data with enhanced compression and metadata
   * @param {string} [backupName] - Optional backup name
   * @returns {Promise<string>} Backup ID
   */
  async createBackup(backupName = null) {
    if (!this.isInitialized) {
      throw new SyncError('Sync manager not initialized', 'NOT_INITIALIZED');
    }

    try {
      // Generate backup ID with timestamp and random component
      const timestamp = Date.now();
      const randomSuffix = Math.random().toString(36).substr(2, 9);
      const backupId = backupName || `backup_${timestamp}_${randomSuffix}`;

      // Collect all learning path related data in parallel for performance
      const dataCollectionPromises = [
        this.loadPathSelections().catch(error => {
          this.logger.warn('Failed to load path selections for backup:', error);
          return null;
        }),
        this.storageManager.getItem('learning_progress_data').catch(error => {
          this.logger.warn('Failed to load progress data for backup:', error);
          return null;
        }),
        this.storageManager.getItem('learning_path_preferences').catch(error => {
          this.logger.warn('Failed to load preferences for backup:', error);
          return null;
        }),
        this.storageManager.getItem('learning_path_analytics').catch(error => {
          this.logger.warn('Failed to load analytics for backup:', error);
          return null;
        })
      ];

      const [pathSelections, progressData, preferences, analytics] = await Promise.all(dataCollectionPromises);

      // Create backup data structure
      const rawData = {
        pathSelections,
        progressData,
        preferences,
        analytics
      };

      // Calculate metadata before compression
      const rawDataString = JSON.stringify(rawData);
      const rawSize = rawDataString.length;

      const backupData = {
        id: backupId,
        timestamp: new Date().toISOString(),
        version: '1.1', // Updated version for enhanced format
        data: rawData,
        metadata: {
          totalPaths: pathSelections?.length || 0,
          rawDataSize: rawSize,
          compressed: this.options.compressionEnabled,
          createdBy: 'LearningPathSync',
          syncVersion: '1.1'
        }
      };

      // Compress data if enabled
      if (this.options.compressionEnabled) {
        try {
          backupData.data = this._compressData(rawData);
          backupData.metadata.compressedSize = JSON.stringify(backupData.data).length;
          backupData.metadata.compressionRatio = (backupData.metadata.compressedSize / rawSize).toFixed(3);
        } catch (compressionError) {
          this.logger.warn('Compression failed, storing uncompressed data:', compressionError);
          backupData.metadata.compressed = false;
        }
      }

      // Store backup with retry mechanism
      await this._storeDataWithRetry(`learning_path_backup_${backupId}`, backupData);

      // Manage backup count asynchronously to avoid blocking
      this._cleanupOldBackups().catch(error => {
        this.logger.warn('Background backup cleanup failed:', error);
      });

      this.logger.info('Backup created successfully:', {
        id: backupId,
        size: backupData.metadata.compressed ? backupData.metadata.compressedSize : rawSize,
        compressed: backupData.metadata.compressed,
        pathCount: backupData.metadata.totalPaths
      });

      return backupId;
    } catch (_error) {
      this.logger.error('Failed to create backup:', _error);
      throw new SyncError('Backup creation failed', 'BACKUP_ERROR', _error);
    }
  }

  /**
   * Restores learning path data from a backup with enhanced validation and recovery
   * @param {string} backupId - Backup ID to restore
   * @param {boolean} [overwriteExisting=false] - Whether to overwrite current data
   * @returns {Promise<boolean>} Success status
   */
  async restoreFromBackup(backupId, overwriteExisting = false) {
    if (!this.isInitialized) {
      throw new SyncError('Sync manager not initialized', 'NOT_INITIALIZED');
    }

    if (!backupId || typeof backupId !== 'string') {
      throw new SyncError('Invalid backup ID provided', 'INVALID_ARGUMENT');
    }

    try {
      // Load backup data
      const backupData = await this.storageManager.getItem(`learning_path_backup_${backupId}`);

      if (!backupData) {
        throw new SyncError(`Backup not found: ${backupId}`, 'BACKUP_NOT_FOUND');
      }

      // Validate backup data structure
      if (!this._validateBackupData(backupData)) {
        throw new SyncError('Invalid backup data structure', 'INVALID_BACKUP');
      }

      // Check if current data exists and whether to preserve it
      if (!overwriteExisting) {
        const currentData = await this.loadPathSelections().catch(() => null);
        if (currentData && currentData.length > 0) {
          throw new SyncError('Current data exists. Use overwriteExisting=true to replace', 'DATA_EXISTS');
        }
      }

      // Decompress data if needed
      let restoredData = backupData.data;
      if (backupData.metadata?.compressed && this.options.compressionEnabled) {
        try {
          restoredData = this._decompressData(restoredData);
        } catch (decompressionError) {
          this.logger.error('Decompression failed:', decompressionError);
          throw new SyncError('Failed to decompress backup data', 'DECOMPRESSION_ERROR', decompressionError);
        }
      }

      // Validate restored data integrity
      if (!this._validateRestoredData(restoredData)) {
        throw new SyncError('Restored data validation failed', 'INVALID_DATA');
      }

      // Create current data backup before restore (for rollback)
      let rollbackBackupId = null;
      try {
        rollbackBackupId = await this.createBackup(`pre_restore_${Date.now()}`);
      } catch (backupError) {
        this.logger.warn('Failed to create rollback backup:', backupError);
      }

      // Restore data in parallel for better performance
      const restorePromises = [];

      if (restoredData.pathSelections) {
        restorePromises.push(
          this.persistPathSelections(restoredData.pathSelections)
            .catch(error => ({ type: 'pathSelections', error }))
        );
      }

      if (restoredData.progressData) {
        restorePromises.push(
          this._storeDataWithRetry('learning_progress_data', restoredData.progressData)
            .catch(error => ({ type: 'progressData', error }))
        );
      }

      if (restoredData.preferences) {
        restorePromises.push(
          this._storeDataWithRetry('learning_path_preferences', restoredData.preferences)
            .catch(error => ({ type: 'preferences', error }))
        );
      }

      if (restoredData.analytics) {
        restorePromises.push(
          this._storeDataWithRetry('learning_path_analytics', restoredData.analytics)
            .catch(error => ({ type: 'analytics', error }))
        );
      }

      const results = await Promise.all(restorePromises);

      // Check for any failures
      const failures = results.filter(result => result && result.error);
      if (failures.length > 0) {
        this.logger.error('Partial restore failure:', failures);

        // Attempt rollback if we have a backup
        if (rollbackBackupId) {
          try {
            await this.restoreFromBackup(rollbackBackupId, true);
            await this.storageManager.removeItem(`learning_path_backup_${rollbackBackupId}`);
            this.logger.info('Rollback completed successfully');
          } catch (rollbackError) {
            this.logger.error('Rollback failed:', rollbackError);
          }
        }

        throw new SyncError('Restore operation failed partially', 'PARTIAL_RESTORE_FAILURE', { failures });
      }

      // Clean up rollback backup on successful restore
      if (rollbackBackupId) {
        try {
          await this.storageManager.removeItem(`learning_path_backup_${rollbackBackupId}`);
        } catch (cleanupError) {
          this.logger.warn('Failed to clean up rollback backup:', cleanupError);
        }
      }

      // Update sync timestamp
      this.lastSyncTimestamp = new Date().toISOString();

      this.logger.info('Backup restored successfully:', {
        backupId,
        version: backupData.version,
        timestamp: backupData.timestamp,
        pathCount: restoredData.pathSelections?.length || 0
      });

      return true;
    } catch (_error) {
      if (_error instanceof SyncError) {
        throw _error;
      }
      this.logger.error('Failed to restore from backup:', _error);
      throw new SyncError('Backup restore failed', 'RESTORE_ERROR', _error);
    }
  }

  /**
   * Lists available backups with enhanced metadata and sorting
   * @returns {Promise<Array<Object>>} Array of backup information
   */
  async listBackups() {
    if (!this.isInitialized) {
      throw new SyncError('Sync manager not initialized', 'NOT_INITIALIZED');
    }

    try {
      const backups = [];
      const keys = await this.storageManager.getAllKeys();

      // Filter and process backup keys in parallel
      const backupPromises = keys
        .filter(key => key.startsWith('learning_path_backup_'))
        .map(async (key) => {
          try {
            const backupData = await this.storageManager.getItem(key);
            if (backupData && this._validateBackupData(backupData)) {
              return {
                id: backupData.id,
                timestamp: backupData.timestamp,
                version: backupData.version || '1.0',
                metadata: {
                  totalPaths: backupData.metadata?.totalPaths || 0,
                  dataSize: backupData.metadata?.rawDataSize || backupData.metadata?.dataSize || 0,
                  compressed: backupData.metadata?.compressed || false,
                  compressedSize: backupData.metadata?.compressedSize,
                  compressionRatio: backupData.metadata?.compressionRatio,
                  createdBy: backupData.metadata?.createdBy || 'LearningPathSync'
                },
                isValid: true
              };
            }
            return null;
          } catch (_error) {
            this.logger.warn(`Failed to process backup ${key}:`, _error);
            return null;
          }
        });

      const backupResults = await Promise.all(backupPromises);
      backups.push(...backupResults.filter(backup => backup !== null));

      // Sort by timestamp (newest first)
      backups.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

      this.logger.debug('Listed backups:', { count: backups.length });
      return backups;
    } catch (_error) {
      this.logger.error('Failed to list backups:', _error);
      throw new SyncError('List backups failed', 'LIST_ERROR', _error);
    }
  }

  /**
   * Deletes a specific backup (internal use only for cleanup)
   * @param {string} backupId - Backup ID to delete
   * @returns {Promise<boolean>} Success status
   * @private
   */
  async deleteBackup(backupId) {
    try {
      // For internal cleanup, we control the ID format
      const storageKey = `learning_path_backup_${backupId}`;
      await this.storageManager.removeItem(storageKey);

      this.logger.debug('Backup deleted during cleanup:', backupId);
      return true;
    } catch (_error) {
      // Log but don't throw - cleanup should be resilient
      this.logger.warn('Failed to delete backup during cleanup:', backupId, _error);
      return false;
    }
  }

  /**
   * Gets current synchronization status with detailed information
   * @returns {Object} Sync status information
   */
  getSyncStatus() {
    const status = {
      isInitialized: this.isInitialized,
      syncInProgress: this.syncInProgress,
      lastSyncTimestamp: this.lastSyncTimestamp,
      syncInterval: this.options.syncInterval,
      periodicSyncEnabled: this.syncTimer !== null,
      errorCount: this.errorCount || 0,
      options: {
        compressionEnabled: this.options.compressionEnabled,
        conflictResolution: this.options.conflictResolution,
        maxBackups: this.options.maxBackups,
        retryAttempts: this.options.retryAttempts
      }
    };

    // Add time since last sync if available
    if (this.lastSyncTimestamp) {
      const lastSync = new Date(this.lastSyncTimestamp);
      const now = new Date();
      status.timeSinceLastSync = now - lastSync;
      status.lastSyncFormatted = lastSync.toLocaleString();
    }

    return status;
  }

  /**
   * Destroys the sync manager and cleans up resources
   */
  destroy() {
    try {
      // Clear periodic sync timer
      if (this.syncTimer) {
        clearInterval(this.syncTimer);
        this.syncTimer = null;
      }

      // Remove event listeners
      this._removeEventListeners();

      // Clear internal state
      this.isInitialized = false;
      this.syncInProgress = false;
      this.lastSyncTimestamp = null;
      this.eventListeners.clear();

      // Clear references
      this.learningPathManager = null;
      this.storageManager = null;
      this.logger = null;

      this.logger?.debug('LearningPathSync destroyed');
    } catch (_error) {
      // Silent failure after destroy
    }
  }

  /**
   * Private method to load persisted data during initialization
   * Implements defensive programming with proper error isolation
   * @private
   */
  async _loadPersistedData() {
    // Load operations in parallel for better performance
    const loadOperations = [];

    // Load path selections operation
    loadOperations.push(
      this._loadPathSelectionsOperation().catch(_error => {
        this.logger.warn('Failed to load path selections during initialization:', _error);
        return null; // Continue with other operations
      })
    );

    // Load progress data operation
    loadOperations.push(
      this._loadProgressDataOperation().catch(_error => {
        this.logger.warn('Failed to load progress data during initialization:', _error);
        return null; // Continue with other operations
      })
    );

    // Execute operations in parallel with error isolation
    await Promise.allSettled(loadOperations);
  }

  /**
   * Private method to handle path selections loading
   * @private
   * @returns {Promise<boolean>} Success status
   */
  async _loadPathSelectionsOperation() {
    const pathSelections = await this._loadPathSelectionsInternal();
    if (pathSelections && Array.isArray(pathSelections) && pathSelections.length > 0) {
      await this.learningPathManager.updatePathSelection(pathSelections);
      this.logger.debug('Persisted path selections applied:', pathSelections.length, 'selections');
      return true;
    }
    return false;
  }

  /**
   * Private method to handle progress data loading
   * @private
   * @returns {Promise<boolean>} Success status
   */
  async _loadProgressDataOperation() {
    const progressData = await this.storageManager.getItem('learning_progress_data');
    if (progressData && typeof progressData === 'object') {
      await this.learningPathManager.syncProgress(progressData);
      this.logger.debug('Persisted progress data loaded successfully');
      return true;
    }
    return false;
  }

  /**
   * Private method to set up event listeners
   * @private
   */
  _setupEventListeners() {
    // Listen for storage events (cross-tab synchronization)
    window.addEventListener('storage', this._handleStorageEvent);
    this.eventListeners.set('storage', this._handleStorageEvent);

    // Listen for visibility changes to sync when tab becomes active
    document.addEventListener('visibilitychange', this._handleVisibilityChange);
    this.eventListeners.set('visibilitychange', this._handleVisibilityChange);

    this.logger.debug('Event listeners set up');
  }

  /**
   * Private method to remove event listeners
   * @private
   */
  _removeEventListeners() {
    this.eventListeners.forEach((handler, event) => {
      if (event === 'storage') {
        window.removeEventListener('storage', handler);
      } else if (event === 'visibilitychange') {
        document.removeEventListener('visibilitychange', handler);
      }
    });
    this.eventListeners.clear();
  }

  /**
   * Private method to handle storage events
   * @private
   */
  async _handleStorageEvent(event) {
    if (event.key && event.key.startsWith('learning_path_')) {
      this.logger.debug('Cross-tab storage change detected:', event.key);

      try {
        // Reload data when other tabs make changes
        await this._loadPersistedData();
      } catch (_error) {
        this.logger.error('Failed to handle storage event:', _error);
      }
    }
  }

  /**
   * Private method to handle visibility changes
   * @private
   */
  async _handleVisibilityChange() {
    if (!document.hidden && this.isInitialized) {
      this.logger.debug('Tab became visible, performing sync');

      try {
        // Sync when tab becomes active
        const currentProgress = await this.learningPathManager.getProgress();
        await this.synchronizeProgress(currentProgress);
      } catch (_error) {
        this.logger.error('Failed to sync on visibility change:', _error);
      }
    }
  }

  /**
   * Private method to start periodic synchronization
   * @private
   */
  _startPeriodicSync() {
    if (this.syncTimer) {
      clearInterval(this.syncTimer);
    }

    this.syncTimer = setInterval(this._performPeriodicSync, this.options.syncInterval);
    this.logger.debug('Periodic sync started with interval:', this.options.syncInterval);
  }

  /**
   * Private method to perform periodic synchronization
   * @private
   */
  async _performPeriodicSync() {
    if (!this.isInitialized || this.syncInProgress) {
      return;
    }

    try {
      const currentProgress = await this.learningPathManager.getProgress();
      await this.synchronizeProgress(currentProgress);
      this.logger.debug('Periodic sync completed');
    } catch (_error) {
      this.logger.error('Periodic sync failed:', _error);
    }
  }

  /**
   * Private method to resolve conflicts between progress data
   * @private
   */
  async _resolveProgressConflicts(existingData, newData) {
    switch (this.options.conflictResolutionStrategy) {
      case 'local':
        return newData;

      case 'remote':
        return existingData;

      case 'merge':
      default:
        return this._mergeProgressData(existingData, newData);
    }
  }

  /**
   * Private method to merge progress data
   * @private
   */
  _mergeProgressData(existingData, newData) {
    // Merge strategy: take the most recent data for each path
    const merged = { ...existingData };

    Object.keys(newData).forEach(pathId => {
      const existingPath = merged[pathId];
      const newPath = newData[pathId];

      if (!existingPath || !existingPath.lastUpdated ||
          new Date(newPath.lastUpdated) > new Date(existingPath.lastUpdated)) {
        merged[pathId] = newPath;
      }
    });

    return merged;
  }

  /**
   * Private method to calculate data checksum
   * @private
   */
  _calculateChecksum(data) {
    // Simple checksum implementation
    const jsonString = JSON.stringify(data, Object.keys(data).sort());
    let hash = 0;
    for (let i = 0; i < jsonString.length; i++) {
      const char = jsonString.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.toString(36);
  }

  /**
   * Private method to validate data checksum
   * @private
   */
  _validateChecksum(data) {
    if (!data.checksum) {
      return true; // No checksum to validate
    }

    const dataWithoutChecksum = { ...data };
    delete dataWithoutChecksum.checksum;
    const calculatedChecksum = this._calculateChecksum(dataWithoutChecksum);

    return calculatedChecksum === data.checksum;
  }

  /**
   * Private method to compress data with error handling
   * @private
   */
  _compressData(data) {
    try {
      // Simple compression using JSON stringify
      // In a real implementation, you might use a compression library
      return JSON.stringify(data);
    } catch (_error) {
      this.logger.error('Data compression failed:', _error);
      throw new SyncError('Data compression failed', 'COMPRESSION_ERROR', _error);
    }
  }

  /**
   * Private method to decompress data with error handling
   * @private
   */
  _decompressData(compressedData) {
    try {
      // Simple decompression
      return JSON.parse(compressedData);
    } catch (_error) {
      this.logger.error('Data decompression failed:', _error);
      throw new SyncError('Data decompression failed', 'DECOMPRESSION_ERROR', _error);
    }
  }

  /**
   * Private method to validate backup data structure
   * @param {Object} backupData - Backup data to validate
   * @returns {boolean} Whether the backup data is valid
   * @private
   */
  _validateBackupData(backupData) {
    if (!backupData || typeof backupData !== 'object') {
      return false;
    }

    // Check required properties
    const requiredProps = ['id', 'timestamp', 'data'];
    for (const prop of requiredProps) {
      if (!(prop in backupData)) {
        return false;
      }
    }

    // Validate timestamp format
    if (!backupData.timestamp || isNaN(new Date(backupData.timestamp).getTime())) {
      return false;
    }

    // Validate data structure
    if (!backupData.data || (typeof backupData.data !== 'object' && typeof backupData.data !== 'string')) {
      return false;
    }

    return true;
  }

  /**
   * Private method to validate restored data integrity
   * @param {Object} restoredData - Restored data to validate
   * @returns {boolean} Whether the restored data is valid
   * @private
   */
  _validateRestoredData(restoredData) {
    if (!restoredData || typeof restoredData !== 'object') {
      return false;
    }

    // Validate path selections if present
    if (restoredData.pathSelections && !Array.isArray(restoredData.pathSelections)) {
      return false;
    }

    // Validate progress data if present
    if (restoredData.progressData && typeof restoredData.progressData !== 'object') {
      return false;
    }

    // Validate preferences if present
    if (restoredData.preferences && typeof restoredData.preferences !== 'object') {
      return false;
    }

    // Validate analytics if present
    if (restoredData.analytics && typeof restoredData.analytics !== 'object') {
      return false;
    }

    return true;
  }


  /**
   * Private method to cleanup old backups
   * @private
   */
  async _cleanupOldBackups() {
    try {
      const backups = await this.listBackups();

      if (backups.length > this.options.maxBackupCount) {
        const backupsToDelete = backups.slice(this.options.maxBackupCount);

        for (const backup of backupsToDelete) {
          await this.deleteBackup(backup.id);
        }

        this.logger.debug(`Cleaned up ${backupsToDelete.length} old backups`);
      }
    } catch (_error) {
      this.logger.warn('Failed to cleanup old backups:', _error);
    }
  }

  /**
   * Private method to create a default logger
   * @private
   */
  _createDefaultLogger() {
    return {
      debug: () => {}, // Silent by default
      info: () => {}, // Silent for ESLint compliance
      warn: () => {}, // Silent for ESLint compliance
      error: () => {} // Silent for ESLint compliance
    };
  }

  // ============================================================================
  // E2E Test Support Methods
  // ============================================================================

  /**
   * Ensure accessibility compliance for E2E testing
   * Note: This component is primarily data-focused, but may create notifications/dialogs
   * @returns {Object} Accessibility compliance report
   */
  ensureAccessibilityCompliance() {
    const report = {
      isCompliant: true,
      issues: [],
      checkedElements: 0,
      timestamp: Date.now()
    };

    try {
      // Check for any notification elements or dialogs created by this component
      const syncNotifications = document.querySelectorAll('[data-sync-notification], .sync-status, .sync-error');

      syncNotifications.forEach((element, _index) => {
        report.checkedElements++;

        // Check for ARIA attributes
        const ariaLabel = element.getAttribute('aria-label');
        const ariaDescribedBy = element.getAttribute('aria-describedby');

        if (!ariaLabel && !ariaDescribedBy && !element.textContent) {
          report.issues.push(`Sync notification ${_index} missing accessible text`);
        }

        // Check for role attributes where appropriate
        if (element.classList.contains('sync-error')) {
          const role = element.getAttribute('role');
          if (role !== 'alert') {
            report.issues.push(`Sync error notification ${_index} should have role="alert"`);
          }
        }

        // Check for live regions
        const ariaLive = element.getAttribute('aria-live');
        if (!ariaLive && (element.classList.contains('sync-status') || element.classList.contains('sync-error'))) {
          report.issues.push(`Sync status element ${_index} should have aria-live attribute`);
        }
      });

      report.isCompliant = report.issues.length === 0;
      return report;

    } catch (_error) {
      this.logger.error('Error during accessibility compliance check:', _error);
      return {
        isCompliant: false,
        issues: [`Error during accessibility check: ${_error.message}`],
        checkedElements: 0,
        timestamp: Date.now()
      };
    }
  }

  /**
   * Get all stored data for E2E testing
   * @returns {Object} Current stored state
   */
  getAllStoredData() {
    try {
      return {
        pathSelections: this.storageManager.get('pathSelections') || {},
        progressData: this.storageManager.get('progressData') || {},
        userPreferences: this.storageManager.get('userPreferences') || {},
        backups: this.storageManager.get('backups') || [],
        lastSyncTime: this.storageManager.get('lastSyncTime') || null,
        metadata: {
          version: this.options.version,
          maxBackupCount: this.options.maxBackupCount,
          syncInterval: this.options.syncInterval
        }
      };
    } catch (_error) {
      this.logger.error('Error getting stored data:', _error);
      return {};
    }
  }

  /**
   * Clear all stored data for E2E testing
   * @returns {boolean} Success status
   */
  clearAllStoredData() {
    try {
      const keys = ['pathSelections', 'progressData', 'userPreferences', 'backups', 'lastSyncTime'];

      keys.forEach(key => {
        this.storageManager.remove(key);
      });

      this.logger.debug('All stored data cleared for E2E testing');
      return true;
    } catch (_error) {
      this.logger.error('Error clearing stored data:', _error);
      return false;
    }
  }

  /**
   * Set test data for E2E testing
   * @param {Object} testData - Test data to set
   * @returns {boolean} Success status
   */
  setTestData(testData) {
    try {
      if (testData.pathSelections) {
        this.storageManager.set('pathSelections', testData.pathSelections);
      }
      if (testData.progressData) {
        this.storageManager.set('progressData', testData.progressData);
      }
      if (testData.userPreferences) {
        this.storageManager.set('userPreferences', testData.userPreferences);
      }
      if (testData.backups) {
        this.storageManager.set('backups', testData.backups);
      }

      this.logger.debug('Test data set successfully');
      return true;
    } catch (_error) {
      this.logger.error('Error setting test data:', _error);
      return false;
    }
  }

  /**
   * Force synchronization for E2E testing
   * @returns {Promise<boolean>} Success status
   */
  async forceSyncForTesting() {
    try {
      // Get current selections from learning path manager
      const currentSelections = this.learningPathManager.getSelectedPaths();

      // Persist the selections
      await this.persistPathSelections(currentSelections);

      // Create a backup
      const backupId = await this.createBackup('E2E Test Backup');

      this.logger.debug('Forced sync completed for E2E testing');
      return !!backupId;
    } catch (_error) {
      this.logger.error('Error during forced sync:', _error);
      return false;
    }
  }

  /**
   * Get performance metrics for E2E testing
   * @returns {Object} Performance metrics
   */
  getPerformanceMetrics() {
    const storedData = this.getAllStoredData();

    return {
      lastSyncTime: storedData.lastSyncTime,
      backupCount: (storedData.backups || []).length,
      dataSize: JSON.stringify(storedData).length,
      pathSelectionsCount: Object.keys(storedData.pathSelections || {}).length,
      progressDataCount: Object.keys(storedData.progressData || {}).length,
      storageUsage: this._calculateStorageUsage(),
      syncInterval: this.options.syncInterval,
      maxBackupCount: this.options.maxBackupCount
    };
  }

  /**
   * Validate component state for E2E testing
   * @returns {Object} Validation result
   */
  validateComponentState() {
    const validation = {
      isValid: true,
      issues: [],
      timestamp: Date.now()
    };

    try {
      // Check dependencies
      if (!this.learningPathManager) {
        validation.isValid = false;
        validation.issues.push('Missing learningPathManager dependency');
      }

      if (!this.storageManager) {
        validation.isValid = false;
        validation.issues.push('Missing storageManager dependency');
      }

      // Check logger
      if (!this.logger) {
        validation.issues.push('Missing logger (using default)');
      }

      // Check options
      if (!this.options) {
        validation.isValid = false;
        validation.issues.push('Missing options configuration');
      }

      // Test storage manager functionality
      try {
        const testKey = 'e2e-validation-test';
        const testValue = 'test-value';

        this.storageManager.set(testKey, testValue);
        const retrieved = this.storageManager.get(testKey);
        this.storageManager.remove(testKey);

        if (retrieved !== testValue) {
          validation.isValid = false;
          validation.issues.push('Storage manager not functioning correctly');
        }
      } catch (storageError) {
        validation.isValid = false;
        validation.issues.push(`Storage manager error: ${storageError.message}`);
      }

      // Check data integrity
      const storedData = this.getAllStoredData();
      if (storedData.pathSelections && typeof storedData.pathSelections !== 'object') {
        validation.issues.push('PathSelections data has incorrect type');
      }

      if (storedData.progressData && typeof storedData.progressData !== 'object') {
        validation.issues.push('ProgressData has incorrect type');
      }

      return validation;
    } catch (_error) {
      validation.isValid = false;
      validation.issues.push(`Validation error: ${_error.message}`);
      return validation;
    }
  }

  /**
   * Simulate error for E2E testing
   * @param {string} errorType - Type of error to simulate
   */
  simulateError(errorType) {
    switch (errorType) {
      case 'storage-failure':
        this.storageManager = {
          get: () => { throw new Error('Simulated storage failure'); },
          set: () => { throw new Error('Simulated storage failure'); },
          remove: () => { throw new Error('Simulated storage failure'); }
        };
        break;
      case 'learning-path-manager':
        this.learningPathManager = null;
        break;
      case 'sync-conflict':
        // Create conflicting data
        this.storageManager.set('pathSelections', { conflicted: true });
        break;
      case 'backup-failure':
        this.options.maxBackupCount = -1; // Invalid configuration
        break;
      default:
        throw new Error(`Unknown error type: ${errorType}`);
    }
  }

  /**
   * Calculate storage usage for performance monitoring
   * @returns {Object} Storage usage information
   * @private
   */
  _calculateStorageUsage() {
    try {
      const data = this.getAllStoredData();
      const serialized = JSON.stringify(data);

      return {
        totalBytes: new Blob([serialized]).size,
        totalCharacters: serialized.length,
        pathSelectionsSize: JSON.stringify(data.pathSelections || {}).length,
        progressDataSize: JSON.stringify(data.progressData || {}).length,
        backupsSize: JSON.stringify(data.backups || []).length,
        estimatedQuotaUsage: (new Blob([serialized]).size / (5 * 1024 * 1024)) * 100 // Percentage of 5MB quota
      };
    } catch (_error) {
      this.logger.error('Error calculating storage usage:', _error);
      return {
        totalBytes: 0,
        totalCharacters: 0,
        pathSelectionsSize: 0,
        progressDataSize: 0,
        backupsSize: 0,
        estimatedQuotaUsage: 0
      };
    }
  }
}

export default LearningPathSync;
