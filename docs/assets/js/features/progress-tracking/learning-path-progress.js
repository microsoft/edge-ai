/**
 * Learning Path Progress Tracking Module
 * Handles checkbox progress, storage, and progress calculations for learning paths
 *
 * @class LearningPathProgress
 * @author Edge AI Team
 * @version 1.0.0
 */

/**
 * Learning Path Progress Tracker
 * Manages progress tracking, storage, and calculations for learning path checkboxes
 */
export class LearningPathProgress {
  /**
   * Create a LearningPathProgress instance
   * @param {Object} options - Configuration options
   * @param {Object} [options.errorHandler] - Error handler instance
   * @param {Object} [options.debugHelper] - Debug helper instance
   * @param {boolean} [options.debug=false] - Enable debug logging
   * @param {string} [options.serverUrl] - Progress server URL
   * @param {boolean} [options.enableApiSync=true] - Enable API synchronization
   */
  constructor(options = {}) {
    this.errorHandler = options.errorHandler || null;
    this.debugHelper = options.debugHelper || null;
    this.debug = options.debug || false;

    // API Configuration
    this.serverUrl = options.serverUrl || 'http://localhost:3002';
    this.enableApiSync = options.enableApiSync !== false;
    this.isServerConnected = false;
    this.eventSource = null;

    // Configuration
    this.storagePrefix = 'learningPathProgress_';
    this.autoSaveDelay = 1000; // Debounce delay for auto-save
    this.saveTimeouts = new Map(); // Track save timeouts for cleanup

    // Progress tracking
    this.progressData = new Map();
    this.checkboxRegistry = new Map(); // Track checkboxes by path ID

    // Event handlers for cleanup
    this.boundHandlers = new Map();
  }

  /**
   * Initialize progress tracking
   * @returns {Promise<boolean>} Success status
   */
  async initialize() {
    try {
      this.log('Initializing learning path progress tracking');

      // Initialize API connection if enabled
      if (this.enableApiSync) {
        await this.initializeApiConnection();
      }

      // Load existing progress data
      await this.loadAllProgress();

      // Set up checkbox enhancement
      this.enhanceProgressCheckboxes();

      this.log('Learning path progress tracking initialized successfully');
      return true;
    } catch (_error) {
      this.handleError('Failed to initialize learning path progress', _error);
      return false;
    }
  }

  /**
   * Enhance all progress checkboxes on the page
   */
  enhanceProgressCheckboxes() {
    this.log('Enhancing progress checkboxes');

    const checkboxes = document.querySelectorAll('input[type="checkbox"]');
    checkboxes.forEach(checkbox => this.enhanceCheckbox(checkbox));
  }

  /**
   * Enhance a single checkbox with progress tracking
   * @param {HTMLElement} checkbox - Checkbox element to enhance
   */
  enhanceCheckbox(checkbox) {
    try {
      const pathId = this.findPathIdForCheckbox(checkbox);
      if (!pathId) {
        this.log('No path ID found for checkbox, skipping enhancement');
        return;
      }

      const checkboxId = this.getCheckboxId(checkbox);
      if (!checkboxId) {
        this.log('No checkbox ID generated, skipping enhancement');
        return;
      }

      // Register checkbox
      if (!this.checkboxRegistry.has(pathId)) {
        this.checkboxRegistry.set(pathId, new Map());
      }
      this.checkboxRegistry.get(pathId).set(checkboxId, checkbox);

      // Load saved state
      const savedState = this.getCheckboxProgress(pathId, checkboxId);
      if (savedState !== null) {
        checkbox.checked = savedState;
      }

      // Add change listener with cleanup tracking
      const handler = (event) => this.handleCheckboxChange(event, pathId, checkboxId);
      checkbox.addEventListener('change', handler);

      // Store handler for cleanup
      if (!this.boundHandlers.has(checkbox)) {
        this.boundHandlers.set(checkbox, new Map());
      }
      this.boundHandlers.get(checkbox).set('change', handler);

      this.log(`Enhanced checkbox ${checkboxId} for path ${pathId}`);
    } catch (_error) {
      this.handleError('Failed to enhance checkbox', _error);
    }
  }

  /**
   * Handle checkbox change events
   * @param {Event} event - Change event
   * @param {string} pathId - Path identifier
   * @param {string} checkboxId - Checkbox identifier
   */
  handleCheckboxChange(event, pathId, checkboxId) {
    try {
      const checkbox = event.target;
      const checked = checkbox.checked;

      this.log(`Checkbox ${checkboxId} in path ${pathId} changed to ${checked}`);

      // Save progress with debouncing
      this.saveCheckboxProgress(pathId, checkboxId, checked);

      // Emit progress update event
      this.emitProgressUpdate(pathId);
    } catch (_error) {
      this.handleError('Failed to handle checkbox change', _error);
    }
  }

  /**
   * Initialize API connection and SSE for real-time sync
   * @returns {Promise<boolean>} Success status
   */
  async initializeApiConnection() {
    try {
      this.log('Initializing API connection');

      // Test server connection
      const isConnected = await this.testServerConnection();
      if (!isConnected) {
        this.log('Server not available, using localStorage only');
        return false;
      }

      // Setup SSE for real-time notifications
      await this.setupServerSentEvents();

      this.isServerConnected = true;
      this.log('API connection initialized successfully');
      return true;
    } catch (_error) {
      this.handleError('Failed to initialize API connection', _error);
      this.isServerConnected = false;
      return false;
    }
  }

  /**
   * Test server connection
   * @returns {Promise<boolean>} Connection status
   */
  async testServerConnection() {
    try {
      const response = await fetch(`${this.serverUrl}/api/progress/sync-status`, {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' }
      });

      return response.ok;
    } catch (_error) {
      this.log('Server connection test failed:', _error.message);
      return false;
    }
  }

  /**
   * Setup Server-Sent Events for real-time sync
   * @returns {Promise<void>}
   */
  async setupServerSentEvents() {
    try {
      if (this.eventSource) {
        this.eventSource.close();
      }

      this.eventSource = new window.EventSource(`${this.serverUrl}/api/progress/events`);

      this.eventSource.onopen = () => {
        this.log('SSE connection established');
      };

      this.eventSource.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          this.handleServerEvent(data);
        } catch (_error) {
          this.log('Failed to parse SSE event:', _error);
        }
      };

      this.eventSource.onerror = (error) => {
        this.log('SSE connection error:', error);
        this.isServerConnected = false;
      };

      this.log('SSE connection setup completed');
    } catch (_error) {
      this.handleError('Failed to setup SSE connection', _error);
    }
  }

  /**
   * Handle server events from SSE
   * @param {Object} eventData - Event data from server
   */
  handleServerEvent(eventData) {
    try {
      this.log('Received server event:', eventData.type);

      switch (eventData.type) {
        case 'file-change':
          this.handleFileChangeEvent(eventData);
          break;
        case 'connected':
          this.isServerConnected = true;
          break;
        case 'heartbeat':
          // Connection is alive
          break;
        default:
          this.log('Unknown server event type:', eventData.type);
      }
    } catch (_error) {
      this.handleError('Failed to handle server event', _error);
    }
  }

  /**
   * Handle file change events from server
   * @param {Object} eventData - File change event data
   */
  async handleFileChangeEvent(eventData) {
    try {
      const { filename, eventType } = eventData;

      if (eventType === 'change' && filename && filename.includes('kata-progress-')) {
        // Extract kata ID from filename
        const kataMatch = filename.match(/kata-progress-([^-]+)-/);
        if (kataMatch) {
          const kataId = kataMatch[1].replace(/_/g, '/');

          // Reload progress for this kata from server
          await this.loadProgressFromServer(kataId);

          // Update UI checkboxes
          this.updateCheckboxesFromData(kataId);

          // Emit progress update event
          this.emitProgressUpdate(kataId);
        }
      }
    } catch (_error) {
      this.handleError('Failed to handle file change event', _error);
    }
  }

  /**
   * Load progress from server for a specific path
   * @param {string} pathId - Path identifier
   * @returns {Promise<boolean>} Success status
   */
  async loadProgressFromServer(pathId) {
    try {
      if (!this.isServerConnected) {
        return false;
      }

      const sanitizedPathId = pathId.replace(/\//g, '_');
      const response = await fetch(`${this.serverUrl}/api/progress/load/kata/${sanitizedPathId}`);

      if (!response.ok) {
        return false;
      }

      const result = await response.json();
      if (result.success && result.data) {
        // Update in-memory progress data
        const progressData = {
          checkboxes: result.data.checkboxes || {},
          lastUpdated: result.data.timestamp || Date.now(),
          schema: 'unified-progress-v1'
        };

        this.progressData.set(pathId, progressData);
        this.log(`Loaded progress from server for path ${pathId}`);
        return true;
      }

      return false;
    } catch (_error) {
      this.handleError(`Failed to load progress from server for ${pathId}`, _error);
      return false;
    }
  }

  /**
   * Update checkbox states from loaded data
   * @param {string} pathId - Path identifier
   */
  updateCheckboxesFromData(pathId) {
    try {
      const pathCheckboxes = this.checkboxRegistry.get(pathId);
      const pathProgress = this.progressData.get(pathId);

      if (!pathCheckboxes || !pathProgress) {
        return;
      }

      pathCheckboxes.forEach((checkbox, checkboxId) => {
        const savedState = pathProgress.checkboxes[checkboxId];
        if (savedState !== undefined) {
          checkbox.checked = savedState;
        }
      });

      this.log(`Updated checkboxes for path ${pathId}`);
    } catch (_error) {
      this.handleError(`Failed to update checkboxes for ${pathId}`, _error);
    }
  }

  /**
   * Save progress to server
   * @param {string} pathId - Path identifier
   * @returns {Promise<boolean>} Success status
   */
  async saveProgressToServer(pathId) {
    try {
      if (!this.isServerConnected) {
        return false;
      }

      const pathProgress = this.progressData.get(pathId);
      if (!pathProgress) {
        return false;
      }

      const syncData = {
        metadata: {
          type: 'kata-progress',
          kataId: pathId,
          fileType: 'kata-progress',
          version: '1.0.0',
          lastUpdated: new Date().toISOString(),
          userId: 'user',
          source: 'learning-path-progress-tracker'
        },
        kataId: pathId,
        pathId: pathId,
        checkboxes: pathProgress.checkboxes || {},
        calculated: this.calculatePathProgress(pathId),
        timestamp: new Date().toISOString(),
        schema: 'learning-path-progress-v1'
      };

      const response = await fetch(`${this.serverUrl}/api/progress/save`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(syncData)
      });

      if (response.ok) {
        this.log(`Saved progress to server for path ${pathId}`);
        return true;
      } else {
        this.log(`Failed to save progress to server for path ${pathId}: ${response.status}`);
        return false;
      }
    } catch (_error) {
      this.handleError(`Failed to save progress to server for ${pathId}`, _error);
      return false;
    }
  }

  /**
   * Save checkbox progress with API sync only
   * @param {string} pathId - Path identifier
   * @param {string} checkboxId - Checkbox identifier
   * @param {boolean} checked - Checkbox state
   */
  saveCheckboxProgress(pathId, checkboxId, checked) {
    try {
      // Update in-memory progress
      if (!this.progressData.has(pathId)) {
        this.progressData.set(pathId, {
          checkboxes: {},
          lastUpdated: Date.now(),
          schema: 'unified-progress-v1'
        });
      }

      const pathProgress = this.progressData.get(pathId);
      pathProgress.checkboxes[checkboxId] = checked;
      pathProgress.lastUpdated = Date.now();

      // Debounced API save (if enabled and connected)
      if (this.enableApiSync && this.isServerConnected) {
        const apiTimeoutKey = `api_${pathId}_${checkboxId}`;

        // Clear existing API timeout
        if (this.saveTimeouts.has(apiTimeoutKey)) {
          clearTimeout(this.saveTimeouts.get(apiTimeoutKey));
        }

        // Set new timeout for API save
        const apiTimeoutId = setTimeout(async () => {
          await this.saveProgressToServer(pathId);
          this.saveTimeouts.delete(apiTimeoutKey);
        }, this.autoSaveDelay * 1.5); // Slightly longer delay for API

        this.saveTimeouts.set(apiTimeoutKey, apiTimeoutId);
      }

      this.log(`Scheduled dual save for ${pathId}:${checkboxId} = ${checked}`);
    } catch (_error) {
      this.handleError('Failed to save checkbox progress', _error);
    }
  }

  /**
   * Load all progress data from server
   */
  async loadAllProgress() {
    try {
      this.log('Loading all progress data from server');

      // Load from server if API is enabled and connected
      if (this.enableApiSync && this.isServerConnected) {
        await this.syncAllProgressFromServer();
      } else {
        this.log('Server not available, cannot load progress');
      }
    } catch (_error) {
      this.handleError('Failed to load progress data', _error);
    }
  }

  /**
   * Load progress data for a specific path
   * @param {string} pathId - Path identifier
   */
  async loadProgressForPath(pathId) {
    try {
      // Progress is now loaded from server only in syncAllProgressFromServer
      // This method serves as a placeholder for potential future direct path loading
      this.log(`loadProgressForPath called for ${pathId} - use syncAllProgressFromServer instead`);
    } catch (_error) {
      this.handleError(`Failed to load progress for path ${pathId}`, _error);
    }
  }

  /**
   * Get checkbox progress state
   * @param {string} pathId - Path identifier
   * @param {string} checkboxId - Checkbox identifier
   * @returns {boolean|null} Checkbox state or null if not found
   */
  getCheckboxProgress(pathId, checkboxId) {
    const pathProgress = this.progressData.get(pathId);
    if (!pathProgress || !pathProgress.checkboxes) {
      return null;
    }

    return pathProgress.checkboxes[checkboxId] || false;
  }

  /**
   * Calculate progress statistics for a path
   * @param {string} pathId - Path identifier
   * @returns {Object} Progress statistics
   */
  calculatePathProgress(pathId) {
    try {
      const pathCheckboxes = this.checkboxRegistry.get(pathId);
      if (!pathCheckboxes) {
        return { completed: 0, total: 0, percentage: 0 };
      }

      const total = pathCheckboxes.size;
      let completed = 0;

      pathCheckboxes.forEach((checkbox, _checkboxId) => {
        if (checkbox.checked) {
          completed++;
        }
      });

      const percentage = total > 0 ? Math.round((completed / total) * 100) : 0;

      return { completed, total, percentage };
    } catch (_error) {
      this.handleError(`Failed to calculate progress for path ${pathId}`, _error);
      return { completed: 0, total: 0, percentage: 0 };
    }
  }

  /**
   * Find the path ID for a checkbox element
   * @param {HTMLElement} checkbox - Checkbox element
   * @returns {string|null} Path ID or null if not found
   */
  findPathIdForCheckbox(checkbox) {
    try {
      // Traverse up to find the nearest heading with a path indicator
      let current = checkbox.parentElement;
      let attempts = 0;
      const maxAttempts = 20;

      while (current && current !== document.body && attempts < maxAttempts) {
        // Look for path headings (h2, h3, h4)
        const heading = current.querySelector('h2, h3, h4') ||
                       current.previousElementSibling?.matches?.('h2, h3, h4') && current.previousElementSibling;

        if (heading && this.isPathHeading(heading)) {
          return this.extractPathId(heading);
        }

        current = current.parentElement;
        attempts++;
      }

      // Fallback: look for any heading above the checkbox
      const allHeadings = Array.from(document.querySelectorAll('h2, h3, h4'));
      const checkboxPosition = this.getElementPosition(checkbox);

      for (let i = allHeadings.length - 1; i >= 0; i--) {
        const heading = allHeadings[i];
        const headingPosition = this.getElementPosition(heading);

        if (headingPosition < checkboxPosition && this.isPathHeading(heading)) {
          return this.extractPathId(heading);
        }
      }

      return null;
    } catch (_error) {
      this.handleError('Failed to find path ID for checkbox', _error);
      return null;
    }
  }

  /**
   * Check if a heading represents a learning path
   * @param {HTMLElement} heading - Heading element
   * @returns {boolean} True if it's a path heading
   */
  isPathHeading(heading) {
    const text = heading.textContent.toLowerCase();
    return text.includes('path') ||
           text.includes('track') ||
           text.includes('course') ||
           text.includes('learning') ||
           heading.id?.includes('path') ||
           heading.id?.includes('track');
  }

  /**
   * Extract path ID from heading element
   * @param {HTMLElement} heading - Heading element
   * @returns {string} Path identifier
   */
  extractPathId(heading) {
    // Use ID if available
    if (heading.id) {
      return heading.id;
    }

    // Generate ID from text content
    return heading.textContent
      .toLowerCase()
      .replace(/[^\w\s-]/g, '')
      .replace(/\s+/g, '-')
      .trim();
  }

  /**
   * Generate a unique ID for a checkbox
   * @param {HTMLElement} checkbox - Checkbox element
   * @returns {string} Checkbox identifier
   */
  getCheckboxId(checkbox) {
    // Use existing ID if available
    if (checkbox.id) {
      return checkbox.id;
    }

    // Use name attribute if available
    if (checkbox.name) {
      return checkbox.name;
    }

    // Generate ID from associated label or nearby text
    const label = checkbox.closest('label') ||
                  document.querySelector(`label[for="${checkbox.id}"]`);

    if (label) {
      const labelText = label.textContent.trim();
      if (labelText) {
        return labelText
          .toLowerCase()
          .replace(/[^\w\s-]/g, '')
          .replace(/\s+/g, '-')
          .substring(0, 50);
      }
    }

    // Fallback: generate based on position
    const position = this.getElementPosition(checkbox);
    return `checkbox-${position}`;
  }

  /**
   * Get approximate position of element in document
   * @param {HTMLElement} element - Element to get position for
   * @returns {number} Position value
   */
  getElementPosition(element) {
    let position = 0;
    let current = element;

    while (current && current.previousElementSibling) {
      current = current.previousElementSibling;
      position++;
    }

    return position;
  }

  /**
   * Emit progress update event
   * @param {string} pathId - Path identifier
   */
  emitProgressUpdate(pathId) {
    try {
      const progress = this.calculatePathProgress(pathId);

      const event = new CustomEvent('learningPathProgressUpdate', {
        detail: { pathId, progress },
        bubbles: true
      });

      document.dispatchEvent(event);
      this.log(`Emitted progress update for path ${pathId}:`, progress);
    } catch (_error) {
      this.handleError('Failed to emit progress update', _error);
    }
  }

  /**
   * Get all progress data
   * @returns {Object} All progress data
   */
  getAllProgress() {
    const result = {};
    this.progressData.forEach((progress, pathId) => {
      result[pathId] = {
        ...progress,
        calculated: this.calculatePathProgress(pathId)
      };
    });
    return result;
  }

  /**
   * Clear all progress data
   * @returns {number} Number of entries cleared
   */
  clearAllProgress() {
    try {
      // Clear in-memory data
      const clearedCount = this.progressData.size;
      this.progressData.clear();

      // Reset all checkboxes
      this.checkboxRegistry.forEach((checkboxes) => {
        checkboxes.forEach((checkbox) => {
          checkbox.checked = false;
        });
      });

      this.log(`Cleared ${clearedCount} progress entries`);
      return clearedCount;
    } catch (_error) {
      this.handleError('Failed to clear progress data', _error);
      return 0;
    }
  }

  /**
   * Sync all progress from server
   * @returns {Promise<number>} Number of paths synced
   */
  async syncAllProgressFromServer() {
    try {
      if (!this.isServerConnected) {
        return 0;
      }

      this.log('Syncing all progress from server');

      // Get list of available progress files from server
      const response = await fetch(`${this.serverUrl}/api/progress/list`);
      if (!response.ok) {
        return 0;
      }

      const result = await response.json();
      if (!result.success || !result.files) {
        return 0;
      }

      let syncedCount = 0;

      // Load progress for each kata found on server
      const kataFiles = result.files.filter(file => file.fileType === 'kata-progress');

      for (const file of kataFiles) {
        try {
          const kataId = file.metadata?.kataId || 'unknown';
          const loadSuccess = await this.loadProgressFromServer(kataId);
          if (loadSuccess) {
            syncedCount++;
            // Update UI checkboxes if they exist
            this.updateCheckboxesFromData(kataId);
          }
        } catch (_error) {
          this.log(`Failed to sync progress for file ${file.filename}:`, _error);
        }
      }

      this.log(`Synced progress from server for ${syncedCount} paths`);
      return syncedCount;
    } catch (_error) {
      this.handleError('Failed to sync all progress from server', _error);
      return 0;
    }
  }

  /**
   * Manually trigger sync with server
   * @returns {Promise<boolean>} Success status
   */
  async manualSync() {
    try {
      if (!this.enableApiSync) {
        this.log('API sync is disabled');
        return false;
      }

      // Test connection first
      if (!this.isServerConnected) {
        await this.initializeApiConnection();
      }

      if (!this.isServerConnected) {
        this.log('Cannot sync - server not connected');
        return false;
      }

      // Sync all local progress to server
      let syncedToServer = 0;
      for (const [pathId] of this.progressData) {
        const success = await this.saveProgressToServer(pathId);
        if (success) {
          syncedToServer++;
        }
      }

      // Sync all server progress to local
      const syncedFromServer = await this.syncAllProgressFromServer();

      this.log(`Manual sync completed: ${syncedToServer} sent to server, ${syncedFromServer} received from server`);

      // Emit progress update events for all paths
      this.progressData.forEach((_, pathId) => {
        this.emitProgressUpdate(pathId);
      });

      return true;
    } catch (_error) {
      this.handleError('Failed to perform manual sync', _error);
      return false;
    }
  }

  /**
   * Destroy the progress tracker and clean up resources
   */
  destroy() {
    try {
      // Close SSE connection
      if (this.eventSource) {
        this.eventSource.close();
        this.eventSource = null;
      }

      // Clear all save timeouts
      this.saveTimeouts.forEach(timeoutId => clearTimeout(timeoutId));
      this.saveTimeouts.clear();

      // Remove all event listeners
      this.boundHandlers.forEach((handlers, element) => {
        handlers.forEach((handler, event) => {
          element.removeEventListener(event, handler);
        });
      });
      this.boundHandlers.clear();

      // Clear data structures
      this.progressData.clear();
      this.checkboxRegistry.clear();

      // Reset connection state
      this.isServerConnected = false;

      this.log('Learning path progress tracker destroyed');
    } catch (_error) {
      this.handleError('Error destroying progress tracker', _error);
    }
  }

  /**
   * Log debug messages (disabled for performance)
   * @param {string} message - Debug message
   * @param {...any} args - Additional arguments
   * @private
   */
  log(_message, ..._args) {
    // Debug logging disabled for performance
  }

  /**
   * Handle errors with optional error handler
   * @param {string} message - Error message
   * @param {Error} error - Error object
   * @private
   */
  handleError(_message, _error) {
    if (this.errorHandler && typeof this.errorHandler.safeExecute === 'function') {
      this.errorHandler.safeExecute(() => {
        this.errorHandler.recordError?.(_message, _error);
      });
    } else {
      // Fallback to console.error when no error handler
      // eslint-disable-next-line no-console
      console.error(`[LearningPathProgress] ${_message}:`, _error);
    }
  }
}

// ES6 Module Export
export default LearningPathProgress;
