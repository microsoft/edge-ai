/**
 * Progress Management Integration
 * Initializes progress export and clear functionality and integrates with existing systems
 * @version 1.1.0
 */

import { ProgressExportManagerSingleton } from './progress-export-manager.js';
import { initializeProgressClearManager } from './progress-clear-manager.js';
import { StorageManager } from '../core/storage-manager.js';
import { LearningPathManager } from '../core/learning-path-manager.js';
import { defaultErrorHandler } from '../core/error-handler.js';
import { defaultDebugHelper } from '../core/debug-helper.js';

/**
 * Progress Management Integration Manager
 * Handles initialization and integration of progress export and clear functionality
 */
export class ProgressManagementIntegration {
  constructor() {
    this.isInitialized = false;
    this.storageManager = null;
    this.learningPathManager = null;
    this.exportManager = null;
    this.clearManager = null;
  }

  /**
   * Initialize progress management integration
   */
  async initialize() {
    if (this.isInitialized) {
      return;
    }

    try {
      // Initialize storage manager
      this.storageManager = new StorageManager({
        debugHelper: defaultDebugHelper,
        errorHandler: defaultErrorHandler
      });

      // Initialize learning path manager with dependencies
      this.learningPathManager = new LearningPathManager({
        debugHelper: defaultDebugHelper,
        errorHandler: defaultErrorHandler,
        storageManager: this.storageManager
      });

      // Initialize export manager singleton
      const exportManagerSingleton = new ProgressExportManagerSingleton();
      this.exportManager = exportManagerSingleton.initialize(
        this.storageManager,
        this.learningPathManager
      );

      // Initialize clear manager
      this.clearManager = initializeProgressClearManager();

      this.isInitialized = true;

      // Add initialization indicator for debugging
      if (defaultDebugHelper) {
        defaultDebugHelper.log('Progress management integration initialized (export + clear)');
      }

    } catch (_error) {
      if (defaultErrorHandler) {
        defaultErrorHandler.recordError('initProgressManagement', _error);
      }
    }
  }

  /**
   * Get clear manager instance
   * @returns {ProgressClearManager|null} Clear manager or null if not initialized
   */
  getClearManager() {
    return this.clearManager;
  }

  /**
   * Get export manager instance
   * @returns {ProgressExportManager|null} Export manager or null if not initialized
   */
  getExportManager() {
    return this.exportManager;
  }

  /**
   * Get storage manager instance
   * @returns {StorageManager|null} Storage manager or null if not initialized
   */
  getStorageManager() {
    return this.storageManager;
  }

  /**
   * Get learning path manager instance
   * @returns {LearningPathManager|null} Learning path manager or null if not initialized
   */
  getLearningPathManager() {
    return this.learningPathManager;
  }

  /**
   * Check if integration is ready
   * @returns {boolean} Ready status
   */
  isReady() {
    return this.isInitialized && this.exportManager && this.clearManager && this.storageManager;
  }

  /**
   * Destroy integration and clean up resources
   */
  destroy() {
    if (this.exportManager) {
      this.exportManager.destroy();
    }
    if (this.clearManager) {
      this.clearManager.destroy();
    }
    if (this.storageManager) {
      this.storageManager.destroy();
    }

    this.exportManager = null;
    this.clearManager = null;
    this.storageManager = null;
    this.learningPathManager = null;
    this.isInitialized = false;
  }
}

// Auto-initialize when DOM is ready
let globalIntegration = null;

/**
 * Initialize progress management integration when DOM is ready
 */
function initializeWhenReady() {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      initializeProgressManagement();
    });
  } else {
    initializeProgressManagement();
  }
}

/**
 * Initialize global progress management integration
 */
async function initializeProgressManagement() {
  if (globalIntegration) {
    return globalIntegration;
  }

  globalIntegration = new ProgressManagementIntegration();
  await globalIntegration.initialize();

  // Make it globally available for debugging
  if (typeof window !== 'undefined') {
    window.progressManagementIntegration = globalIntegration;
  }

  return globalIntegration;
}

/**
 * Get global progress management integration instance
 * @returns {ProgressManagementIntegration} Global integration instance
 */
export function getProgressManagementIntegration() {
  return globalIntegration;
}

// Auto-initialize
initializeWhenReady();
