/**
 * Learning Path Synchronization Factory
 *
 * Factory module for creating and configuring learning path synchronization components.
 * Handles dependency injection, initialization, and provides a unified interface
 * for all synchronization-related functionality.
 *
 * Features:
 * - Dependency injection and component initialization
 * - Configuration management with defaults
 * - Error handling and graceful fallbacks
 * - Development mode support with mock components
 * - Memory management and cleanup
 */

import { LearningPathSync, SyncError } from './learning-path-sync.js';
import { StorageManager, StorageError } from './storage-manager.js';
import { logger } from '../utils/index.js';

/**
 * Default configuration for synchronization components
 */
const DEFAULT_CONFIG = {
  // Storage configuration
  storage: {
    preferredBackends: ['IndexedDB', 'localStorage', 'sessionStorage', 'Memory'],
    maxRetries: 3,
    retryDelay: 1000,
    autoCleanup: true,
    cleanupInterval: 24 * 60 * 60 * 1000, // 24 hours
    maxAge: 30 * 24 * 60 * 60 * 1000 // 30 days
  },

  // Synchronization configuration
  sync: {
    syncInterval: 30000, // 30 seconds
    conflictResolutionStrategy: 'merge',
    maxBackupCount: 5,
    compressionEnabled: true,
    encryptionEnabled: false,
    validationEnabled: true
  },

  // Development mode settings
  development: {
    enableLogging: true,
    mockDependencies: false,
    skipInitialization: false
  }
};

/**
 * Logger interface for development and debugging
 */
class SyncLogger {
  constructor(options = {}) {
    this.enabled = options.enabled !== false;
    this.prefix = options.prefix || '[LearningPathSync]';
    this.level = options.level || 'info';
  }

  debug(...args) {
    if (this.enabled && (this.level === 'debug' || this.level === 'all')) {
      logger.debug(this.prefix, ...args);
    }
  }

  info(...args) {
    if (this.enabled && ['info', 'debug', 'all'].includes(this.level)) {
      logger.info(this.prefix, ...args);
    }
  }

  warn(...args) {
    if (this.enabled) {
      logger.warn(this.prefix, ...args);
    }
  }

  error(...args) {
    if (this.enabled) {
      logger.error(this.prefix, ...args);
    }
  }
}

/**
 * Mock learning path manager for testing and development
 */
class MockLearningPathManager {
  constructor() {
    this.pathSelections = {};
    this.progressData = {};
  }

  async updatePathSelection(selections) {
    if (Array.isArray(selections)) {
      this.pathSelections = {};
      selections.forEach(path => {
        this.pathSelections[path] = true;
      });
    }
    return true;
  }

  async getProgress() {
    return {
      pathSelections: this.pathSelections,
      progressData: this.progressData,
      timestamp: new Date().toISOString()
    };
  }

  async syncProgress(progressData) {
    if (progressData.pathSelections) {
      this.pathSelections = { ...progressData.pathSelections };
    }
    if (progressData.progressData) {
      this.progressData = { ...progressData.progressData };
    }
    return true;
  }
}

/**
 * Synchronization Factory Class
 * Creates and manages synchronization component instances
 */
export class SyncFactory {
  /**
   * Creates a new SyncFactory instance
   * @param {Object} config - Factory configuration
   */
  constructor(config = {}) {
    this.config = this._mergeConfig(DEFAULT_CONFIG, config);
    this.logger = new SyncLogger({
      enabled: this.config.development.enableLogging,
      level: this.config.development.logLevel || 'info'
    });

    this.instances = {
      storageManager: null,
      syncManager: null
    };

    this.isInitialized = false;
    this._isDestroyed = false;
  }

  /**
   * Creates and initializes a complete synchronization system
   * @param {Object} dependencies - External dependencies
   * @param {Object} dependencies.learningPathManager - Learning path manager instance
   * @param {Object} [options] - Additional options
   * @returns {Promise<Object>} Initialized synchronization system
   */
  async createSyncSystem(dependencies = {}, options = {}) {
    if (this._isDestroyed) {
      throw new SyncError('Factory has been destroyed', 'FACTORY_DESTROYED');
    }

    try {
      this.logger.info('Creating synchronization system...');

      // Create storage manager
      const storageManager = await this.createStorageManager(options.storage);

      // Create synchronization manager
      const syncManager = await this.createSyncManager({
        ...dependencies,
        storageManager
      }, options.sync);

      // Store instances for cleanup
      this.instances.storageManager = storageManager;
      this.instances.syncManager = syncManager;

      this.isInitialized = true;
      this.logger.info('Synchronization system created successfully');

      return {
        storageManager,
        syncManager,
        config: this.config,
        logger: this.logger
      };
    } catch (_error) {
      this.logger.error('Failed to create synchronization system:', _error);
      throw new SyncError('System creation failed', 'CREATION_ERROR', _error);
    }
  }

  /**
   * Creates and initializes a storage manager
   * @param {Object} [options] - Storage manager options
   * @returns {Promise<StorageManager>} Initialized storage manager
   */
  async createStorageManager(options = {}) {
    try {
      this.logger.debug('Creating storage manager...');

      const config = {
        ...this.config.storage,
        ...options,
        logger: this.logger
      };

      const storageManager = new StorageManager(config);
      await storageManager.initialize();

      this.logger.debug('Storage manager created and initialized');
      return storageManager;
    } catch (_error) {
      this.logger.error('Failed to create storage manager:', _error);
      throw new StorageError('Storage manager creation failed', 'CREATION_ERROR', _error);
    }
  }

  /**
   * Creates and initializes a synchronization manager
   * @param {Object} dependencies - Required dependencies
   * @param {Object} [options] - Sync manager options
   * @returns {Promise<LearningPathSync>} Initialized sync manager
   */
  async createSyncManager(dependencies = {}, options = {}) {
    try {
      this.logger.debug('Creating synchronization manager...');

      // Validate or create learning path manager
      let learningPathManager = dependencies.learningPathManager;
      if (!learningPathManager) {
        if (this.config.development.mockDependencies) {
          this.logger.warn('Using mock learning path manager for development');
          learningPathManager = new MockLearningPathManager();
        } else {
          throw new SyncError('Learning path manager is required', 'MISSING_DEPENDENCY');
        }
      }

      // Validate storage manager
      if (!dependencies.storageManager) {
        throw new SyncError('Storage manager is required', 'MISSING_DEPENDENCY');
      }

      const config = {
        ...this.config.sync,
        ...options
      };

      const syncManager = new LearningPathSync({
        learningPathManager,
        storageManager: dependencies.storageManager,
        logger: this.logger
      }, config);

      if (!this.config.development.skipInitialization) {
        await syncManager.initialize();
      }

      this.logger.debug('Synchronization manager created and initialized');
      return syncManager;
    } catch (_error) {
      this.logger.error('Failed to create synchronization manager:', _error);
      throw new SyncError('Sync manager creation failed', 'CREATION_ERROR', _error);
    }
  }

  /**
   * Creates a minimal sync system for testing
   * @param {Object} [testConfig] - Test-specific configuration
   * @returns {Promise<Object>} Test sync system
   */
  async createTestSyncSystem(testConfig = {}) {
    const config = {
      development: {
        enableLogging: false,
        mockDependencies: true,
        skipInitialization: false
      },
      storage: {
        preferredBackends: ['Memory'], // Use in-memory storage for tests
        autoCleanup: false
      },
      sync: {
        syncInterval: 0, // Disable periodic sync in tests
        validationEnabled: false
      },
      ...testConfig
    };

    const testFactory = new SyncFactory(config);
    return await testFactory.createSyncSystem();
  }

  /**
   * Gets the current configuration
   * @returns {Object} Current configuration
   */
  getConfig() {
    return { ...this.config };
  }

  /**
   * Updates the factory configuration
   * @param {Object} updates - Configuration updates
   * @returns {boolean} Success status
   */
  updateConfig(updates) {
    try {
      this.config = this._mergeConfig(this.config, updates);
      this.logger.debug('Configuration updated');
      return true;
    } catch (_error) {
      this.logger.error('Failed to update configuration:', _error);
      return false;
    }
  }

  /**
   * Gets initialization status
   * @returns {Object} Status information
   */
  getStatus() {
    return {
      isInitialized: this.isInitialized,
      isDestroyed: this._isDestroyed,
      hasStorageManager: !!this.instances.storageManager,
      hasSyncManager: !!this.instances.syncManager,
      config: this.config
    };
  }

  /**
   * Destroys the factory and cleans up all instances
   */
  destroy() {
    try {
      this.logger.debug('Destroying sync factory...');

      // Destroy sync manager
      if (this.instances.syncManager) {
        this.instances.syncManager.destroy();
        this.instances.syncManager = null;
      }

      // Destroy storage manager
      if (this.instances.storageManager) {
        this.instances.storageManager.destroy();
        this.instances.storageManager = null;
      }

      // Clear state
      this.isInitialized = false;
      this._isDestroyed = true;

      this.logger.info('Sync factory destroyed');
    } catch (_error) {
      logger.warn('Error during sync factory cleanup:', _error);
    }
  }

  /**
   * Private method to merge configurations
   * @private
   */
  _mergeConfig(base, updates) {
    const merged = { ...base };

    Object.keys(updates).forEach(key => {
      if (updates[key] && typeof updates[key] === 'object' && !Array.isArray(updates[key])) {
        merged[key] = { ...base[key], ...updates[key] };
      } else {
        merged[key] = updates[key];
      }
    });

    return merged;
  }
}

/**
 * Singleton instance for global access
 */
let globalSyncFactory = null;

/**
 * Gets or creates the global sync factory instance
 * @param {Object} [config] - Factory configuration (only used on first call)
 * @returns {SyncFactory} Global factory instance
 */
export function getSyncFactory(config = {}) {
  if (!globalSyncFactory || globalSyncFactory._isDestroyed) {
    globalSyncFactory = new SyncFactory(config);
  }
  return globalSyncFactory;
}

/**
 * Destroys the global sync factory instance
 */
export function destroyGlobalSyncFactory() {
  if (globalSyncFactory) {
    globalSyncFactory.destroy();
    globalSyncFactory = null;
  }
}

/**
 * Convenience function to create a complete sync system
 * @param {Object} dependencies - Required dependencies
 * @param {Object} [config] - Configuration options
 * @returns {Promise<Object>} Initialized sync system
 */
export async function createSyncSystem(dependencies, config = {}) {
  const factory = getSyncFactory(config);
  return await factory.createSyncSystem(dependencies);
}

// Export error classes for external use
export { SyncError, StorageError };

export default SyncFactory;
