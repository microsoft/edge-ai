/**
 * Learning Path Dashboard Plugin
 * Consolidates all learning dashboard functionality into a single component
 * with comprehensive container validation and error handling
 *
 * @class LearningPathDashboard
 * @author Edge AI Team
 * @version 3.0.0
 */

import { loggingMixin } from './learning-path-dashboard/logging.js';
import { eventBusMixin } from './learning-path-dashboard/event-bus.js';
import { containerUtilitiesMixin } from './learning-path-dashboard/container-utils.js';
import { cardsMixin } from './learning-path-dashboard/cards.js';
import { progressMixin } from './learning-path-dashboard/progress.js';
import { eventsMixin } from './learning-path-dashboard/events.js';
import { storageMixin } from './learning-path-dashboard/storage.js';

class LearningPathDashboard {
  constructor(containers, pathsOrConfig = {}, additionalConfig = {}) {
    // Compose all mixins into this instance FIRST (before any initialization)
    Object.assign(this,
      loggingMixin,
      eventBusMixin,
      containerUtilitiesMixin,
      cardsMixin,
      progressMixin,
      eventsMixin,
      storageMixin
    );

    // Determine if second argument is paths array or config object
    let paths = [];
    let config = {};

    if (Array.isArray(pathsOrConfig)) {
      paths = pathsOrConfig;
      config = additionalConfig;
    } else {
      config = pathsOrConfig;
      paths = config.initialPaths || [];
    }

    // Initialize configuration (needed for logging)
    this.config = {
      showProgress: true,
      enableAnimations: true,
      defaultSort: 'progress',
      enableProgressTracking: true,
      enableServerSync: true,
      enableLocalStorage: true,
      userId: 'current-user',
      ...config
    };

    // Initialize core properties
    this.paths = [];
    this.filteredPaths = [];
    this.loadedPaths = [];
    this.learningPaths = [];
    this.initialPaths = paths;
    this.selectedPaths = new Set();
    this.errors = [];
    this.isDestroyed = false;
    this.serverConnected = false;
    this.progressData = {};
    this.progressTracker = null;

    // SSE connection properties
    this.eventSource = null;
    this.sseReconnectAttempts = 0;
    this.sseMaxReconnectAttempts = 5;
    this.sseReconnectDelay = 1000;
    this.manifestChecksum = null;

    // Initialize event system (now mixins are composed, so methods exist)
    this._initializeEventBus();

    // Validate and normalize containers
    const validationResult = this.validateAndNormalizeContainers(containers);
    if (!validationResult.isValid) {
      this.logError('Container validation failed:', validationResult.errors);
      throw new Error(`Invalid containers: ${validationResult.errors.join(', ')}`);
    }
    this.containers = validationResult.containers;

    // Define container getter (Object.assign doesn't preserve getters from mixins)
    Object.defineProperty(this, 'container', {
      get() {
        return this.containers?.[0] || null;
      },
      enumerable: true,
      configurable: true
    });

    // Initialize ARIA live region for accessibility
    this._initializeAriaLiveRegion();

    // Initialize mixin-specific state
    this._initializeProgressCache();
    this._initializeSortState();
    this._initStorage();

    // Initialize SSE connection if server sync is enabled
    if (this.config.enableServerSync) {
      this._connectToSSE();
    }

    // Load initial paths if provided
    if (paths.length > 0) {
      this.loadPaths(paths);
    }

    // Log successful initialization
    this.log('debug', 'Learning Path Dashboard initialized', {
      containerCount: this.containers.length,
      config: this.config
    });
  }

    /**
   * Load paths data and prepare for rendering
   * @param {Array} paths - Optional array of learning path objects. If omitted, fetches from backend.
   */
  async loadPaths(paths = null) {
    // If no paths provided and server sync is enabled, fetch from backend
    if (!paths && this.config.enableServerSync) {
      return await this.fetchManifest();
    }

    if (!Array.isArray(paths)) {
      this.logError('loadPaths: paths must be an array or null');
      return false;
    }

    // Validate each path
    const validPaths = paths.filter(path => this.validatePath(path));

    if (validPaths.length === 0) {
      this.logError('loadPaths: no valid paths found');
      return false;
    }

    this.paths = validPaths;
    this.learningPaths = validPaths;
    this.loadedPaths = validPaths;
    this.filteredPaths = validPaths;

    this.log('debug', `Loaded ${validPaths.length} valid paths`);

    // Load selected paths from storage (and server if enabled)
    await this.loadSelectedPathsFromStorage();

    // Render cards immediately (before async operations for test synchronization)
    this.renderCards();

    // Initialize progress tracking (async, but cards are already rendered)
    await this.initializeProgressTracker();

    // Emit loaded event
    this.emit('paths-loaded', {
      totalPaths: validPaths.length,
      containers: this.containers.length
    });

    return true;
  }

  /**
   * Fetch learning path manifest from backend API
   * @returns {Promise<boolean>} Success status
   */
  async fetchManifest() {
    try {
      this.log('debug', 'Fetching manifest from backend...');

      const response = await fetch('http://localhost:3002/api/learning/manifest');

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const manifest = await response.json();

      // Validate manifest structure
      if (!manifest.descriptors || !Array.isArray(manifest.descriptors)) {
        throw new Error('Invalid manifest structure: missing descriptors array');
      }

      // Store checksum for change detection
      const newChecksum = manifest.checksum || manifest.generatedAt;
      if (newChecksum === this.manifestChecksum) {
        this.log('debug', 'Manifest unchanged (checksum match)');
        return true;
      }

      this.manifestChecksum = newChecksum;
      this.serverConnected = true;

      // Load the paths from manifest descriptors
      const paths = manifest.descriptors;
      this.paths = paths;
      this.learningPaths = paths;
      this.loadedPaths = paths;
      this.filteredPaths = paths;

      this.log('debug', `Loaded ${paths.length} paths from manifest (checksum: ${newChecksum})`);

      // Load selected paths from storage
      this.loadSelectedPathsFromStorage();

      // Initialize progress tracking
      await this.initializeProgressTracker();

      // Render cards
      this.renderCards();

      // Emit loaded event
      this.emit('manifest-loaded', {
        totalPaths: paths.length,
        checksum: newChecksum,
        generatedAt: manifest.generatedAt
      });

      return true;
    } catch (error) {
      this.logError('Failed to fetch manifest:', error);
      this.serverConnected = false;

      // Show offline indicator if we're in server sync mode
      if (this.config.enableServerSync) {
        this.createOfflineIndicator();
      }

      this.emit('manifest-error', { error: error.message });
      return false;
    }
  }

  /**
   * Connect to Server-Sent Events (SSE) stream for real-time updates
   * @private
   */
  _connectToSSE() {
    if (this.eventSource) {
      this.log('debug', 'SSE already connected');
      return;
    }

    try {
      this.log('debug', 'Connecting to SSE stream...');
            this.eventSource = new EventSource('http://localhost:3002/api/progress/events');

      // Connection opened
      this.eventSource.addEventListener('open', () => {
        this.log('debug', 'SSE connection established');
        this.serverConnected = true;
        this.sseReconnectAttempts = 0;
        this.emit('sse-connected');
      });

      // Listen for manifest-updated events
      this.eventSource.addEventListener('manifest-updated', async (event) => {
        try {
          const data = JSON.parse(event.data);
          this.log('debug', 'Received manifest-updated event:', data);

          // Check if checksum changed
          if (data.checksum && data.checksum !== this.manifestChecksum) {
            this.log('debug', 'Manifest changed, reloading...');
            await this.fetchManifest();
          }
        } catch (error) {
          this.logError('Error processing manifest-updated event:', error);
        }
      });

      // Connection error
      this.eventSource.addEventListener('error', (error) => {
        this.logError('SSE connection error:', error);
        this.serverConnected = false;
        this.emit('sse-error', { error });

        // Attempt reconnection with exponential backoff
        this._handleSSEReconnect();
      });

    } catch (error) {
      this.logError('Failed to establish SSE connection:', error);
      this.serverConnected = false;
    }
  }

  /**
   * Handle SSE reconnection with exponential backoff
   * @private
   */
  _handleSSEReconnect() {
    if (this.eventSource) {
      this.eventSource.close();
      this.eventSource = null;
    }

    if (this.sseReconnectAttempts >= this.sseMaxReconnectAttempts) {
      this.logError(`SSE reconnection failed after ${this.sseMaxReconnectAttempts} attempts`);
      this.createOfflineIndicator();
      return;
    }

    this.sseReconnectAttempts++;
    const delay = this.sseReconnectDelay * Math.pow(2, this.sseReconnectAttempts - 1);

    this.log('debug', `SSE reconnecting in ${delay}ms (attempt ${this.sseReconnectAttempts}/${this.sseMaxReconnectAttempts})`);

    setTimeout(() => {
      if (!this.isDestroyed) {
        this._connectToSSE();
      }
    }, delay);
  }

  /**
   * Disconnect from SSE stream
   * @private
   */
  _disconnectFromSSE() {
    if (this.eventSource) {
      this.log('debug', 'Disconnecting from SSE stream');
      this.eventSource.close();
      this.eventSource = null;
      this.serverConnected = false;
      this.emit('sse-disconnected');
    }
  }

  /**
   * Get current step state, prioritizing DOM and localStorage over path data
   */
  getStepCurrentState(pathId, stepId) {
    // Check DOM state first (most current)
    const checkbox = document.querySelector(`[data-path-id="${pathId}"][data-step-id="${stepId}"]`);
    if (checkbox) {
      return checkbox.checked;
    }

    // Check localStorage second
    try {
      const progress = JSON.parse(localStorage.getItem('learning-progress') || '{}');
      if (progress[pathId] && typeof progress[pathId][stepId] === 'boolean') {
        return progress[pathId][stepId];
      }
    } catch (error) {
      // localStorage error, continue to path data check
    }

    // Check path data last (fallback)
    const path = this.loadedPaths?.find(p => p.id === pathId);
    if (path && path.steps) {
      const step = path.steps.find(s => s.id === stepId);
      if (step && typeof step.completed === 'boolean') {
        return step.completed;
      }
    }

    return false;
  }






  /**
   * Setup progress tracking integration
   * @private
   */
  async setupProgressTracking() {
    try {
      if (window.LearningProgressTracker) {
        await this.initializeProgressTracker();
      }
      this.on('step-completed', (data) => this.handleProgressUpdate(data));
      this.on('step-uncompleted', (data) => this.handleProgressUpdate(data));
    } catch (error) {
      this.logError('Failed to setup progress tracking:', error);
    }
  }

  /**
   * Initialize the progress tracker
   * @private
   */
  async initializeProgressTracker() {
    if (!window.LearningProgressTracker) return;

    try {
      // LearningProgressTracker is a utility object for individual content pages
      // The dashboard doesn't need to initialize it - just reference it for utility functions
      this.progressTracker = window.LearningProgressTracker;

      // Check server connection status (assume connected if not explicitly disconnected)
      this.serverConnected = true;

      this.log('debug', 'Progress tracker referenced');
    } catch (error) {
      this.logError('Failed to initialize progress tracker:', error);
    }
  }

  /**
   * Handle progress update from tracker or events
   * @private
   */
  handleProgressUpdate(data) {
    const { pathId, stepId, completed } = data;
    this.invalidateProgressCache();
    this.updateProgressDisplay(pathId);
    this.announceProgressUpdate(pathId);
    this.emit('progress-updated', { pathId, stepId, completed });
  }



  /**
   * Create offline indicator
   */
  createOfflineIndicator() {
    this.containers.forEach(container => {
      if (!container.querySelector('.offline-indicator')) {
        const indicator = document.createElement('div');
        indicator.className = 'offline-indicator';
        indicator.textContent = 'Offline - Progress saved locally';
        indicator.setAttribute('role', 'status');
        container.insertBefore(indicator, container.firstChild);
      }
    });
  }

  /**
   * Cleanup progress tracking
   * @private
   */
  cleanupProgressTracking() {
    if (this.progressTracker && typeof this.progressTracker.destroy === 'function') {
      this.progressTracker.destroy();
      this.progressTracker = null;
    }
  }

  /**
   * Cleanup and destroy dashboard instance
   */
  destroy() {
    this._disconnectFromSSE();
    this.cleanupProgressTracking();

    // Clean up aria-live region
    if (this.containers && Array.isArray(this.containers)) {
      for (let i = 0; i < this.containers.length; i++) {
        const container = this.containers[i];
        if (container && container.querySelector) {
          const ariaLive = container.querySelector('.learning-dashboard-aria-live');
          if (ariaLive && ariaLive.parentNode) {
            ariaLive.parentNode.removeChild(ariaLive);
          }
        }
      }
    }

    this._cleanupStorage();

    // Clean up card DOM elements
    if (this.containers) {
      this.containers.forEach(container => {
        const cardsWrapper = container.querySelector('.learning-paths-cards');
        if (cardsWrapper) {
          cardsWrapper.remove();
        }
      });
    }

    // Call cards mixin destroy
    if (typeof this._destroyCards === 'function') {
      this._destroyCards();
    }

    this.progressCache.clear();
    this.paths = [];
    this.filteredPaths = [];
    this.selectedPaths.clear();
    this.isDestroyed = true;
    this.emit('destroyed');
  }
}

// Export for ES6 modules and global access
if (typeof window !== 'undefined') {
  window.LearningPathDashboard = LearningPathDashboard;
}

export default LearningPathDashboard;


