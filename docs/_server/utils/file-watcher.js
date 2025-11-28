/**
 * File Watcher Service
 * Monitors progress files for changes and triggers SSE events
 */

import chokidar from 'chokidar';
import path from 'path';
import { promises as fs } from 'fs';
import sseManager from './sse-manager.js';
import { detectProgressType } from '../schemas/index.js';
import { fileURLToPath } from 'url';
import { getDefaultConfig } from '../config/watcher-config.js';

// Get current directory for ES6 modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class FileWatcherService {
  constructor(options = {}) {
    this.watchPath = options.watchPath || process.env.PROGRESS_DIR || path.join(__dirname, '../../.copilot-tracking/learning');
    this.learningPathsDir = options.learningPathsDir || path.join(__dirname, '../../../learning/paths');
    this.debounceDelay = options.debounceDelay || 500;
    this.watcher = null;
    this.manifestWatcher = null;
    this.debounceTimers = new Map();
    this.manifestDebounceTimer = null;
    this.lastEvents = new Map();
    this.isEnabled = options.enabled !== false;

    // Get optimized configuration
    this.config = getDefaultConfig();
    this.debounceDelay = this.config.debounceDelay || this.debounceDelay;
  }

  /**
   * Get optimized configuration for current environment
   * @returns {Object} Optimized configuration
   */
  getOptimizedConfig() {
    return this.config;
  }

  /**
   * Check if using polling mode
   * @returns {boolean} True if using polling
   */
  isUsingPolling() {
    return this.config.usePolling === true;
  }

  /**
   * Start manifest watcher for learning paths
   * @param {Object} watchOptions - Watcher configuration
   */
  startManifestWatcher(watchOptions) {
    if (this.manifestWatcher) {
      return;
    }

    // Watch all markdown files in learning paths directory
    const manifestPattern = path.join(this.learningPathsDir, '*.md');

    this.manifestWatcher = chokidar.watch(manifestPattern, watchOptions);

    this.manifestWatcher
      .on('add', () => this.handleManifestChange())
      .on('change', () => this.handleManifestChange())
      .on('unlink', () => this.handleManifestChange())
      .on('error', (error) => {
        console.error('Manifest watcher error:', error);
        // Attempt to restart on error
        this.restartWatcher();
      });
  }

  /**
   * Handle manifest changes with debouncing
   */
  handleManifestChange() {
    if (this.manifestDebounceTimer) {
      clearTimeout(this.manifestDebounceTimer);
    }

    this.manifestDebounceTimer = setTimeout(async () => {
      await this.processManifestChange();
      this.manifestDebounceTimer = null;
    }, this.debounceDelay);
  }

  /**
   * Process manifest change and broadcast via SSE
   */
  async processManifestChange() {
    try {
      // Import manifest service dynamically to avoid circular dependency
      const { rebuildManifest } = await import('../services/learning-path-manifest.js');

      // Rebuild manifest
      const manifest = await rebuildManifest({ validate: true });

      // Broadcast manifest update via SSE with checksum for client-side change detection
      sseManager.broadcast('learning-path-manifest', {
        type: 'manifest-update',
        version: manifest.version,
        generatedAt: manifest.generatedAt,
        checksum: manifest.checksum,
        descriptorCount: manifest.descriptors.length
      });

      console.log(`[FileWatcher] Manifest updated and broadcast (${manifest.descriptors.length} descriptors, checksum: ${manifest.checksum})`);
    } catch (error) {
      console.error('[FileWatcher] Error processing manifest change:', error);

      // Broadcast error
      sseManager.broadcast('learning-path-manifest', {
        type: 'error',
        message: 'Failed to rebuild manifest',
        error: error.message
      });
    }
  }

  /**
   * Start file watcher
   */
  start() {
    if (!this.isEnabled) {
      return;
    }

    if (this.watcher) {
      return;
    }

    // Configure watcher options using optimized configuration
    const watchOptions = {
      ...this.config,
      // Override with any specific options for file watching
      persistent: true,
      ignoreInitial: true,
      followSymlinks: false,
      depth: 1,
      awaitWriteFinish: {
        stabilityThreshold: 100,
        pollInterval: 5000
      }
    };

    // Create watcher
    this.watcher = chokidar.watch(this.watchPath, watchOptions);

    // Create manifest watcher for learning paths directory
    this.startManifestWatcher(watchOptions);

    // Set up event handlers
    this.watcher
      .on('add', (filePath) => this.handleFileChange('add', filePath))
      .on('change', (filePath) => this.handleFileChange('change', filePath))
      .on('unlink', (filePath) => this.handleFileChange('unlink', filePath))
      .on('error', (error) => this.handleError(error))
      .on('ready', () => {
        // File watcher ready, monitoring silently
      });

    // SSE manager event handlers
    sseManager.on('clientConnected', () => {
      // Client connected silently
    });

    sseManager.on('clientDisconnected', () => {
      // Client disconnected silently
    });
  }

  /**
   * Stop file watcher
   */
  stop() {
    if (this.watcher) {
      this.watcher.close();
      this.watcher = null;
    }

    if (this.manifestWatcher) {
      this.manifestWatcher.close();
      this.manifestWatcher = null;
    }

    // Clear debounce timers
    this.debounceTimers.forEach(timer => clearTimeout(timer));
    this.debounceTimers.clear();

    if (this.manifestDebounceTimer) {
      clearTimeout(this.manifestDebounceTimer);
      this.manifestDebounceTimer = null;
    }
  }

  /**
   * Handle file change events with debouncing
   * @param {string} event - Event type (add, change, unlink)
   * @param {string} filePath - Path to the changed file
   */
  handleFileChange(event, filePath) {
    // Only process JSON files
    if (!filePath.endsWith('.json')) {
      return;
    }

    const fileName = path.basename(filePath);
    const debounceKey = `${event}:${fileName}`;

    // Clear existing debounce timer
    if (this.debounceTimers.has(debounceKey)) {
      clearTimeout(this.debounceTimers.get(debounceKey));
    }

    // Set new debounce timer
    const timer = setTimeout(() => {
      this.processFileChange(event, filePath);
      this.debounceTimers.delete(debounceKey);
    }, this.debounceDelay);

    this.debounceTimers.set(debounceKey, timer);
  }

  /**
   * Process file change event
   * @param {string} event - Event type
   * @param {string} filePath - Path to the changed file
   */
  async processFileChange(event, filePath) {
    try {
      const fileName = path.basename(filePath);
      const relativePath = path.relative(this.watchPath, filePath);

      let progressType = null;
      let fileData = null;

      // For add/change events, read and analyze the file
      if (event === 'add' || event === 'change') {
        try {
          const fileContent = await fs.readFile(filePath, 'utf8');
          fileData = JSON.parse(fileContent);
          progressType = detectProgressType(fileData);
        } catch(_error) {
          console.error(`Error reading file ${fileName}:`, _error.message);
          progressType = this.inferProgressTypeFromFilename(fileName);
        }
      } else {
        // For unlink events, infer type from filename
        progressType = this.inferProgressTypeFromFilename(fileName);
      }

      // Create SSE event
      const sseEvent = {
        type: 'file-change',
        data: {
          event,
          fileName,
          relativePath,
          progressType,
          timestamp: new Date().toISOString(),
          ...(fileData && {
            metadata: fileData.metadata,
            hasProgress: !!(fileData.assessment || fileData.progress)
          })
        }
      };

      // Broadcast to appropriate progress type
      if (progressType) {
        sseManager.broadcastToProgressType(progressType, sseEvent);
      } else {
        // Broadcast to all types if type cannot be determined
        sseManager.broadcastToAll(sseEvent);
      }

      // Store last event for debugging
      this.lastEvents.set(fileName, {
        event,
        timestamp: new Date().toISOString(),
        progressType
      });

    } catch(_error) {
      console.error(`Error processing file change for ${filePath}:`, _error);

      // Broadcast error event
      sseManager.broadcastToAll({
        type: 'file-error',
        data: {
          error: _error.message,
          fileName: path.basename(filePath),
          event,
          timestamp: new Date().toISOString()
        }
      });
    }
  }

  /**
   * Infer progress type from filename
   * @param {string} fileName - Name of the file
   * @returns {string|null} Inferred progress type
   */
  inferProgressTypeFromFilename(fileName) {
    if (fileName.includes('assessment')) {
      return 'self-assessment';
    }
    if (fileName.includes('kata') || /\d{2}-/.test(fileName)) {
      return 'kata-progress';
    }
    if (fileName.includes('lab')) {
      return 'lab-progress';
    }
    return null;
  }

  /**
   * Handle watcher errors
   * @param {Error} error - Error object
   */
  handleError(error) {
    console.error('File watcher error:', error);

    // Broadcast error event
    sseManager.broadcastToAll({
      type: 'watcher-error',
      data: {
        error: error.message,
        timestamp: new Date().toISOString()
      }
    });

    // Attempt to restart watcher after error (handles sleep/wake scenarios)
    this.restartWatcher();
  }

  /**
   * Restart file watcher after error or sleep/wake
   */
  restartWatcher() {
    console.log('[FileWatcher] Attempting to restart watcher...');

    // Stop existing watchers
    this.stop();

    // Wait a bit before restarting to avoid rapid restart loops
    setTimeout(() => {
      try {
        this.start();
        console.log('[FileWatcher] Successfully restarted');
      } catch (error) {
        console.error('[FileWatcher] Failed to restart:', error);
        // Try again after a longer delay
        setTimeout(() => this.restartWatcher(), 5000);
      }
    }, 1000);
  }

  /**
   * Get watcher status
   * @returns {Object} Status information
   */
  getStatus() {
    return {
      isEnabled: this.isEnabled,
      isRunning: !!this.watcher,
      watchPath: this.watchPath,
      debounceDelay: this.debounceDelay,
      activeTimers: this.debounceTimers.size,
      lastEvents: Array.from(this.lastEvents.entries()).map(([fileName, event]) => ({
        fileName,
        ...event
      }))
    };
  }

  /**
   * Manual trigger for file sync
   * @param {string} progressType - Progress type to sync
   */
  async triggerSync(progressType) {
    try {
      const files = await fs.readdir(this.watchPath);
      const jsonFiles = files.filter(file => file.endsWith('.json'));

      let syncedFiles = 0;

      for (const file of jsonFiles) {
        const filePath = path.join(this.watchPath, file);
        const fileType = this.inferProgressTypeFromFilename(file);

        if (!progressType || fileType === progressType) {
          await this.processFileChange('sync', filePath);
          syncedFiles++;
        }
      }

      return {
        syncedFiles,
        totalFiles: jsonFiles.length,
        progressType: progressType || 'all'
      };
    } catch (error) {
      console.error('Error triggering sync:', error);
      throw error;
    }
  }

  /**
   * Get list of currently watched files
   * @returns {Array} Array of watched file paths
   */
  getWatchedFiles() {
    if (!this.isEnabled || !this.watcher) {
      return [];
    }
    return Object.keys(this.watcher.getWatched()).reduce((files, dir) => {
      const dirFiles = this.watcher.getWatched()[dir];
      return files.concat(dirFiles.map(file => path.join(dir, file)));
    }, []);
  }

  /**
   * Check if a specific file is being watched
   * @param {string} filePath - Path to check
   * @returns {boolean} True if file is being watched
   */
  isWatching(filePath) {
    if (!this.isEnabled || !this.watcher) {
      return false;
    }
    const watched = this.watcher.getWatched();
    const dir = path.dirname(filePath);
    const file = path.basename(filePath);
    return watched[dir] && watched[dir].includes(file);
  }

  /**
   * Stop watching a specific file
   * @param {string} filePath - Path to stop watching
   */
  stopWatching(filePath) {
    if (this.isEnabled && this.watcher) {
      this.watcher.unwatch(filePath);
      return true;
    }
    return false;
  }

  /**
   * Start watching a specific file
   * @param {string} filePath - Path to watch
   * @param {Function} callback - Callback for file changes
   */
  watchFile(filePath, callback) {
    if (!this.isEnabled) {
      console.warn('File watcher is disabled, cannot watch file:', filePath);
      return false;
    }

    if (!this.watcher) {
      this.start();
    }

    // Handle case where watcher is still null (test environment)
    if (!this.watcher) {
      console.warn('File watcher failed to start, cannot watch file:', filePath);
      return false;
    }

    if (callback) {
      this.watcher.on('change', (changedPath) => {
        if (changedPath === filePath) {
          callback(changedPath);
        }
      });
    }

    this.watcher.add(filePath);
    return true;
  }
}

// Create singleton instance
const fileWatcher = new FileWatcherService({
  enabled: process.env.NODE_ENV !== 'test' || process.env.ENABLE_FILE_WATCHER === 'true' // Allow enabling in tests
});

export default fileWatcher;
export { FileWatcherService };
