/**
 * Progress Export Manager
 * Handles progress save/export functionality for learning path progress tracking
 * @version 1.0.0
 */

/**
 * ProgressExportManager - Handles progress saving and export functionality
 * Integrates with StorageManager and provides multiple export formats
 */
export class ProgressExportManager {
  constructor(storageManager = null, learningPathManager = null) {
    this.storageManager = storageManager;
    this.learningPathManager = learningPathManager;
    this.isInitialized = false;

    this.initializeEventListeners();
  }

  /**
   * Initialize event listeners for save requests
   */
  initializeEventListeners() {
    document.addEventListener('progressSaveRequested', (event) => {
      this.handleSaveRequest(event.detail);
    });

    this.isInitialized = true;
  }

  /**
   * Handle progress save request from FloatingProgressBar
   * @param {Object} saveData - Save request data
   */
  async handleSaveRequest(saveData) {
    try {
      const { kataId, exportFormat = 'json', exportTarget = 'download' } = saveData;

      // Get comprehensive progress data
      const progressData = await this.getComprehensiveProgressData(kataId);

      // Perform save based on export target
      const result = await this.performSave(progressData, exportFormat, exportTarget);

      // Dispatch success event
      this.dispatchSaveResult(true, result);

    } catch (_error) {
      this.dispatchSaveResult(false, { error: _error.message });
    }
  }

  /**
   * Get comprehensive progress data for export
   * @param {string} kataId - Current kata identifier
   * @returns {Object} Comprehensive progress data
   */
  async getComprehensiveProgressData(kataId) {
    const progressData = {
      metadata: {
        exportedAt: new Date().toISOString(),
        exportVersion: '1.0.0',
        sourceKata: kataId,
        userAgent: navigator.userAgent
      },
      currentKata: {},
      allKataProgress: [],
      pathProgress: [],
      learningPathSelections: {},
      totalStats: {}
    };

    // Get current kata progress
    if (kataId && this.storageManager) {
      progressData.currentKata = this.storageManager.getKataProgress(kataId);
    }

    // Get all kata progress
    if (this.storageManager) {
      progressData.allKataProgress = this.storageManager.getAllKataProgress();
      progressData.pathProgress = this.storageManager.getAllPathProgress();
    }

    // Get learning path selections
    if (this.learningPathManager) {
      const learningPathData = this.learningPathManager.getProgress();
      progressData.learningPathSelections = learningPathData.selectionState || {};
    }

    // Calculate total statistics
    progressData.totalStats = this.calculateTotalStats(progressData);

    return progressData;
  }

  /**
   * Calculate total statistics across all progress
   * @param {Object} progressData - Complete progress data
   * @returns {Object} Total statistics
   */
  calculateTotalStats(progressData) {
    const stats = {
      totalKatas: progressData.allKataProgress.length,
      completedKatas: 0,
      totalTasks: 0,
      completedTasks: 0,
      overallCompletionPercentage: 0,
      activeKatas: 0,
      totalPaths: progressData.pathProgress.length,
      completedPaths: 0
    };

    // Calculate kata statistics
    progressData.allKataProgress.forEach(kata => {
      stats.totalTasks += kata.totalTasks || 0;
      stats.completedTasks += kata.completedTasks || 0;
      if (kata.completionPercentage === 100) {
        stats.completedKatas++;
      }
      if (kata.completedTasks > 0) {
        stats.activeKatas++;
      }
    });

    // Calculate path statistics
    progressData.pathProgress.forEach(path => {
      if (path.completionPercentage === 100) {
        stats.completedPaths++;
      }
    });

    // Calculate overall completion percentage
    if (stats.totalTasks > 0) {
      stats.overallCompletionPercentage = Math.round(
        (stats.completedTasks / stats.totalTasks) * 100
      );
    }

    return stats;
  }

  /**
   * Perform the actual save operation
   * @param {Object} progressData - Progress data to save
   * @param {string} exportFormat - Export format (json, csv, pdf)
   * @param {string} exportTarget - Export target (download, localStorage, server)
   * @returns {Object} Save result
   */
  async performSave(progressData, exportFormat, exportTarget) {
    switch (exportTarget) {
      case 'download':
        return this.saveAsDownload(progressData, exportFormat);
      case 'server':
        return this.saveToServer(progressData);
      case 'clipboard':
        return this.saveToClipboard(progressData, exportFormat);
      default:
        throw new Error(`Unknown export target: ${exportTarget}`);
    }
  }

  /**
   * Save progress as downloadable file
   * @param {Object} progressData - Progress data
   * @param {string} format - File format
   * @returns {Object} Download result
   */
  saveAsDownload(progressData, format) {
    const timestamp = new Date().toISOString().slice(0, 16).replace(/[:.]/g, '-');
    const filename = `learning-progress-${timestamp}.${format}`;

    let content, mimeType;

    switch (format) {
      case 'json':
        content = JSON.stringify(progressData, null, 2);
        mimeType = 'application/json';
        break;
      case 'csv':
        content = this.convertToCSV(progressData);
        mimeType = 'text/csv';
        break;
      case 'txt':
        content = this.convertToText(progressData);
        mimeType = 'text/plain';
        break;
      default:
        throw new Error(`Unsupported format: ${format}`);
    }

    // Create and trigger download
    const blob = new Blob([content], { type: mimeType });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    return {
      success: true,
      filename,
      size: blob.size,
      format,
      timestamp: new Date().toISOString()
    };
  }

  /**
   * Save progress to localStorage backup
   * @param {Object} progressData - Progress data
   * @returns {Object} Save result
   */
  saveToLocalStorage(progressData) {
    const backupKey = `progress-backup-${Date.now()}`;
    const backupData = {
      ...progressData,
      backupInfo: {
        createdAt: new Date().toISOString(),
        type: 'manual-backup',
        key: backupKey
      }
    };

    localStorage.setItem(backupKey, JSON.stringify(backupData));

    return {
      success: true,
      backupKey,
      size: JSON.stringify(backupData).length,
      timestamp: new Date().toISOString()
    };
  }

  /**
   * Save progress to server
   * @param {Object} progressData - Progress data
   * @returns {Object} Save result
   */
  async saveToServer(progressData) {
    if (!this.storageManager || !this.storageManager.saveToServer) {
      throw new Error('Server save not available');
    }

    const serverData = {
      ...progressData,
      serverInfo: {
        uploadedAt: new Date().toISOString(),
        type: 'manual-export'
      }
    };

    await this.storageManager.saveToServer(serverData, 'manual-export');

    return {
      success: true,
      destination: 'server',
      timestamp: new Date().toISOString()
    };
  }

  /**
   * Save progress to clipboard
   * @param {Object} progressData - Progress data
   * @param {string} format - Format for clipboard
   * @returns {Object} Save result
   */
  async saveToClipboard(progressData, format) {
    let content;

    switch (format) {
      case 'json':
        content = JSON.stringify(progressData, null, 2);
        break;
      case 'txt':
        content = this.convertToText(progressData);
        break;
      default:
        content = JSON.stringify(progressData, null, 2);
    }

    await navigator.clipboard.writeText(content);

    return {
      success: true,
      destination: 'clipboard',
      format,
      size: content.length,
      timestamp: new Date().toISOString()
    };
  }

  /**
   * Convert progress data to CSV format
   * @param {Object} progressData - Progress data
   * @returns {string} CSV content
   */
  convertToCSV(progressData) {
    const lines = [];

    // Header
    lines.push('Kata ID,Total Tasks,Completed Tasks,Completion %,Last Updated');

    // Kata progress rows
    progressData.allKataProgress.forEach(kata => {
      lines.push([
        kata.kataId || 'Unknown',
        kata.totalTasks || 0,
        kata.completedTasks || 0,
        kata.completionPercentage || 0,
        kata.lastUpdated || 'Never'
      ].join(','));
    });

    // Add summary section
    lines.push('');
    lines.push('Summary');
    lines.push(`Total Katas,${progressData.totalStats.totalKatas}`);
    lines.push(`Completed Katas,${progressData.totalStats.completedKatas}`);
    lines.push(`Total Tasks,${progressData.totalStats.totalTasks}`);
    lines.push(`Completed Tasks,${progressData.totalStats.completedTasks}`);
    lines.push(`Overall Completion %,${progressData.totalStats.overallCompletionPercentage}`);

    return lines.join('\n');
  }

  /**
   * Convert progress data to human-readable text
   * @param {Object} progressData - Progress data
   * @returns {string} Text content
   */
  convertToText(progressData) {
    const lines = [];

    lines.push('Learning Progress Export');
    lines.push('========================');
    lines.push(`Exported: ${progressData.metadata.exportedAt}`);
    lines.push(`Source Kata: ${progressData.metadata.sourceKata || 'N/A'}`);
    lines.push('');

    // Summary
    lines.push('Progress Summary:');
    lines.push(`• Total Katas: ${progressData.totalStats.totalKatas}`);
    lines.push(`• Completed Katas: ${progressData.totalStats.completedKatas}`);
    lines.push(`• Total Tasks: ${progressData.totalStats.totalTasks}`);
    lines.push(`• Completed Tasks: ${progressData.totalStats.completedTasks}`);
    lines.push(`• Overall Completion: ${progressData.totalStats.overallCompletionPercentage}%`);
    lines.push('');

    // Individual kata details
    if (progressData.allKataProgress.length > 0) {
      lines.push('Individual Kata Progress:');
      progressData.allKataProgress.forEach(kata => {
        lines.push(`• ${kata.kataId}: ${kata.completedTasks}/${kata.totalTasks} tasks (${kata.completionPercentage}%)`);
      });
    }

    return lines.join('\n');
  }

  /**
   * Dispatch save result event
   * @param {boolean} success - Success status
   * @param {Object} result - Save result details
   */
  dispatchSaveResult(success, result) {
    const event = new CustomEvent('progressSaveCompleted', {
      detail: {
        success,
        result,
        timestamp: new Date().toISOString()
      }
    });

    document.dispatchEvent(event);
  }

  /**
   * Get available backup files from localStorage
   * @returns {Array} Available backups
   */
  getAvailableBackups() {
    const backups = [];

    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && key.startsWith('progress-backup-')) {
        try {
          const backup = JSON.parse(localStorage.getItem(key));
          backups.push({
            key,
            createdAt: backup.backupInfo?.createdAt,
            type: backup.backupInfo?.type,
            size: JSON.stringify(backup).length
          });
        } catch (_error) {
          // Skip invalid backups
        }
      }
    }

    return backups.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  }

  /**
   * Clean up old backups (keep only last 5)
   */
  cleanupOldBackups() {
    const backups = this.getAvailableBackups();

    // Remove backups beyond the first 5
    backups.slice(5).forEach(backup => {
      localStorage.removeItem(backup.key);
    });
  }

  /**
   * Destroy the export manager and clean up resources
   */
  destroy() {
    this.storageManager = null;
    this.learningPathManager = null;
    this.isInitialized = false;
  }
}

/**
 * Progress Export Manager Singleton
 * Provides global access to progress export functionality
 */
export class ProgressExportManagerSingleton {
  static instance = null;

  constructor(storageManager = null, learningPathManager = null) {
    if (ProgressExportManagerSingleton.instance) {
      return ProgressExportManagerSingleton.instance;
    }

    this.exportManager = new ProgressExportManager(storageManager, learningPathManager);
    ProgressExportManagerSingleton.instance = this;
  }

  /**
   * Initialize the export manager
   * @param {Object} storageManager - Storage manager instance
   * @param {Object} learningPathManager - Learning path manager instance
   * @returns {ProgressExportManager} Export manager instance
   */
  initialize(storageManager = null, learningPathManager = null) {
    if (!this.exportManager.isInitialized) {
      this.exportManager.storageManager = storageManager;
      this.exportManager.learningPathManager = learningPathManager;
    }
    return this.exportManager;
  }

  /**
   * Get the export manager instance
   * @returns {ProgressExportManager} Export manager instance
   */
  getExportManager() {
    return this.exportManager;
  }

  /**
   * Check if export manager is initialized
   * @returns {boolean} Initialization status
   */
  get isInitialized() {
    return this.exportManager && this.exportManager.isInitialized;
  }

  /**
   * Destroy the export manager singleton
   */
  destroy() {
    if (this.exportManager) {
      this.exportManager.destroy();
    }
    ProgressExportManagerSingleton.instance = null;
  }
}
