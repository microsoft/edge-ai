/**
 * Docsify Interactive Progress Tracking Plugin
 * Enables persistent checkbox states and progress tracking for kata exercises
 * Version: 1.0.0
 *
 * This plugin transforms static markdown checkboxes into interactive progress tracking
 * elements with localStorage persistence and real-time progress visualization.
 */
(function() {
  'use strict';

  // Plugin configuration
  const PLUGIN_CONFIG = {
    name: 'interactive-progress',
    version: '1.0.0',
    storagePrefix: 'kata-progress-',
    debugMode: true, // Set to true for development
    errorTracking: true, // Track errors for debugging
    performanceTracking: false // Track performance metrics
  };

  /**
   * Error Handling and Debug System
   * Provides comprehensive error tracking and debugging capabilities
   */
  class ErrorHandler {
    constructor() {
      this.errors = [];
      this.performanceMetrics = {};
      this.initialized = false;
    }

    /**
     * Initialize error handling system
     */
    init() {
      if (this.initialized) return;

      this.setupGlobalErrorHandling();
      this.setupPerformanceTracking();
      this.initialized = true;

      this.log('Error handling system initialized');
    }

    /**
     * Setup global error handling for plugin
     */
    setupGlobalErrorHandling() {
      if (!PLUGIN_CONFIG.errorTracking) return;

      // Capture unhandled plugin errors
      const originalConsoleError = console.error;
      console.error = (...args) => {
        // Check if this is a plugin-related error
        const errorMessage = args.join(' ');
        if (errorMessage.includes(PLUGIN_CONFIG.name) || errorMessage.includes('kata-progress') || errorMessage.includes('interactive-progress')) {
          this.recordError('console.error', new Error(errorMessage), { args });
        }
        originalConsoleError.apply(console, args);
      };
    }

    /**
     * Setup performance tracking
     */
    setupPerformanceTracking() {
      if (!PLUGIN_CONFIG.performanceTracking) return;

      this.performanceMetrics = {
        pageProcessingTime: [],
        storageOperationTime: [],
        floatingBarUpdateTime: [],
        checkboxEnhancementTime: []
      };
    }

    /**
     * Record an error with context
     * @param {string} operation - Operation that failed
     * @param {Error} error - Error object
     * @param {Object} context - Additional context
     */
    recordError(operation, error, context = {}) {
      const errorRecord = {
        timestamp: Date.now(),
        operation,
        message: error.message,
        stack: error.stack,
        context,
        url: window.location.href,
        userAgent: navigator.userAgent
      };

      this.errors.push(errorRecord);

      // Keep only last 50 errors to prevent memory bloat
      if (this.errors.length > 50) {
        this.errors = this.errors.slice(-50);
      }

      this.log('Error recorded:', operation, error.message);

      // If in debug mode, show detailed error
      if (PLUGIN_CONFIG.debugMode) {
        console.group(`[${PLUGIN_CONFIG.name}] Error in ${operation}`);
        console.error('Error:', error);
        console.log('Context:', context);
        console.log('All errors:', this.errors);
        console.groupEnd();
      }
    }

    /**
     * Start performance measurement
     * @param {string} operation - Operation name
     * @returns {function} End measurement function
     */
    startPerformanceMeasurement(operation) {
      if (!PLUGIN_CONFIG.performanceTracking) {
        return () => {}; // No-op if performance tracking disabled
      }

      const startTime = performance.now();

      return () => {
        const endTime = performance.now();
        const duration = endTime - startTime;

        if (this.performanceMetrics[operation]) {
          this.performanceMetrics[operation].push(duration);

          // Keep only last 100 measurements
          if (this.performanceMetrics[operation].length > 100) {
            this.performanceMetrics[operation] = this.performanceMetrics[operation].slice(-100);
          }
        }

        this.log(`Performance: ${operation} took ${duration.toFixed(2)}ms`);
      };
    }

    /**
     * Safe function execution with error handling
     * @param {function} fn - Function to execute
     * @param {string} operation - Operation name for error context
     * @param {*} defaultReturn - Default return value on error
     * @returns {*} Function result or default value
     */
    safeExecute(fn, operation, defaultReturn = null) {
      try {
        const endPerf = this.startPerformanceMeasurement(operation);
        const result = fn();
        endPerf();
        return result;
      } catch (error) {
        this.recordError(operation, error);
        return defaultReturn;
      }
    }

    /**
     * Safe async function execution with error handling
     * @param {function} fn - Async function to execute
     * @param {string} operation - Operation name for error context
     * @param {*} defaultReturn - Default return value on error
     * @returns {Promise<*>} Function result or default value
     */
    async safeExecuteAsync(fn, operation, defaultReturn = null) {
      try {
        const endPerf = this.startPerformanceMeasurement(operation);
        const result = await fn();
        endPerf();
        return result;
      } catch (error) {
        this.recordError(operation, error);
        return defaultReturn;
      }
    }

    /**
     * Validate DOM element exists and is accessible
     * @param {string} selector - CSS selector
     * @param {string} context - Context for error reporting
     * @returns {HTMLElement|null} Element or null if not found
     */
    validateElement(selector, context) {
      try {
        const element = document.querySelector(selector);
        if (!element) {
          this.recordError('DOM element not found', new Error(`Element not found: ${selector}`), { selector, context });
        }
        return element;
      } catch (error) {
        this.recordError('DOM query failed', error, { selector, context });
        return null;
      }
    }

    /**
     * Get error summary for debugging
     * @returns {Object} Error summary
     */
    getErrorSummary() {
      const errorsByOperation = {};
      this.errors.forEach(error => {
        if (!errorsByOperation[error.operation]) {
          errorsByOperation[error.operation] = [];
        }
        errorsByOperation[error.operation].push(error);
      });

      return {
        totalErrors: this.errors.length,
        errorsByOperation,
        recentErrors: this.errors.slice(-10),
        performanceMetrics: PLUGIN_CONFIG.performanceTracking ? this.performanceMetrics : null
      };
    }

    /**
     * Debug logging
     * @param {string} message - Debug message
     * @param {...any} args - Additional arguments
     */
    log(message, ...args) {
      if (PLUGIN_CONFIG.debugMode) {
        console.log(`[${PLUGIN_CONFIG.name}] ${message}`, ...args);
      }
    }

    /**
     * Check system health and compatibility
     * @returns {Object} Health check results
     */
    checkSystemHealth() {
      const results = {
        domReady: document.readyState === 'complete' || document.readyState === 'interactive',
        docsifyPresent: !!window.$docsify,
        contentContainer: !!this.validateElement('.content', 'health check'),
        errorCount: this.errors.length,
        healthy: true
      };

      // Determine overall health
      results.healthy = results.domReady && results.docsifyPresent && results.contentContainer && results.errorCount < 10;

      this.log('System health check:', results);
      return results;
    }
  }

  /**
   * Minimal Debug Helper
   * Simple debug logging without storage dependencies
   */
  class DebugHelper {
    /**
     * Debug logging
     * @param {string} message - Debug message
     * @param {...any} args - Additional arguments
     */
    debug(message, ...args) {
      if (PLUGIN_CONFIG.debugMode) {
        console.log(`[${PLUGIN_CONFIG.name}] ${message}`, ...args);
      }
    }
  }

  /**
   * Minimal read-only checkbox processor for kata progress tracking
   * Only calculates and displays progress without user interaction
   */
  class CheckboxEnhancer {
    constructor(debugHelper) {
      this.debugHelper = debugHelper;
      this.currentKataId = null;
      this.progressData = null;
      this.errorHandler = errorHandler;
    }

    /**
     * Determine if progress tracking should be activated based on current page
     * @returns {boolean} True if progress tracking should be active
     */
    shouldActivateProgressTracking() {
      return this.errorHandler.safeExecute(() => {
        const path = window.location.hash;
        const isKataPage = this.isKataPage();
        const isLabPage = this.isLabPage();

        this.debugHelper.debug('Progress tracking check:', {
          path,
          isKataPage,
          isLabPage,
          shouldActivate: isKataPage || isLabPage
        });

        return isKataPage || isLabPage;
      }, 'shouldActivateProgressTracking', false);
    }

    /**
     * Check if current page is a kata
     * @returns {boolean} True if current page is a kata
     */
    isKataPage() {
      return this.errorHandler.safeExecute(() => {
        const path = window.location.hash;
        const url = window.location.href;

        // Check various kata URL patterns - EXCLUDE README pages
        const isKata = (
                      /\/katas\/[^\/]+\/kata\.md/.test(path) ||
                      /\/katas\/[^\/]+\/[^\/]+\/?$/.test(path) ||  // Support /katas/category/specific-kata
                      /#!\/praxisworx\/katas\/[^\/]+\/[^\/]+\/?$/.test(path) ||  // Support hash-based praxisworx kata paths with specific kata
                      (document.querySelector('main article')?.textContent || '').includes('## Kata Overview') ||
                      (document.querySelector('.content')?.textContent || '').includes('## Kata Overview')
                    ) &&
                    // EXCLUDE README and index pages
                    !path.includes('README') &&
                    !path.includes('readme') &&
                    !path.includes('index') &&
                    !path.endsWith('/katas/') &&
                    !path.endsWith('/katas') &&
                    !/#!\/praxisworx\/katas\/?$/.test(path);

        this.debugHelper.debug('Kata page check:', { path, url, isKata });
        return isKata;
      }, 'isKataPage', false);
    }

    /**
     * Check if current page is a lab
     * @returns {boolean} True if current page is a lab
     */
    isLabPage() {
      return this.errorHandler.safeExecute(() => {
        const path = window.location.hash;
        const isLab = /\/training-labs\/[^\/]+\/lab\.md/.test(path) ||
                     /\/training-labs\/[^\/]+\/?$/.test(path) ||
                     (document.querySelector('main article')?.textContent || '').includes('## Lab Overview');

        this.debugHelper.debug('Lab page check:', { path, isLab });
        return isLab;
      }, 'isLabPage', false);
    }

    /**
     * Get content type (kata or lab)
     * @returns {string} Content type
     */
    getContentType() {
      return this.errorHandler.safeExecute(() => {
        if (this.isKataPage()) return 'kata';
        if (this.isLabPage()) return 'lab';
        return 'unknown';
      }, 'getContentType', 'unknown');
    }

    /**
     * Extract kata ID from current URL or content
     * @returns {string|null} Kata ID or null if not found
     */
    extractKataId() {
      return this.errorHandler.safeExecute(() => {
        const path = window.location.hash;

        // Try to extract from URL path
        let match = path.match(/\/katas\/([^\/]+)/);
        if (match) {
          return match[1];
        }

        // Try training labs
        match = path.match(/\/training-labs\/([^\/]+)/);
        if (match) {
          return `lab-${match[1]}`;
        }

        // Try to extract from page title or content
        const titleElement = document.querySelector('h1');
        if (titleElement) {
          const title = titleElement.textContent.trim();
          return title.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
        }

        return null;
      }, 'extractKataId', null);
    }

    /**
     * Main processing function to calculate progress on current page
     */
    processPage() {
      const endPerf = this.errorHandler.startPerformanceMeasurement('checkboxProcessingTime');

      this.errorHandler.safeExecute(() => {
        if (!this.shouldActivateProgressTracking()) {
          this.debugHelper.debug('Progress tracking not activated for current page');
          return;
        }

        this.currentKataId = this.extractKataId();
        if (!this.currentKataId) {
          this.debugHelper.debug('Could not extract kata ID');
          return;
        }

        this.debugHelper.debug('Processing page for kata:', this.currentKataId);

        // Calculate current progress from existing checkboxes
        this.updateProgress();

        this.debugHelper.debug('Page processing completed for kata:', this.currentKataId);
      }, 'processPage');

      endPerf();
    }

    /**
     * Update overall progress statistics (read-only calculation)
     */
    updateProgress() {
      this.errorHandler.safeExecute(() => {
        if (!this.currentKataId) return;

        const checkboxes = document.querySelectorAll('input[type="checkbox"]');
        const totalTasks = checkboxes.length;
        const completedTasks = Array.from(checkboxes).filter(cb => cb.checked).length;

        const completionPercentage = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;

        // Create read-only progress data
        this.progressData = {
          checkboxes: {},
          metadata: {
            totalTasks,
            completedTasks,
            completionPercentage,
            lastCalculated: new Date().toISOString(),
            kataId: this.currentKataId
          }
        };

        this.debugHelper.debug('Progress calculated:', {
          kataId: this.currentKataId,
          totalTasks,
          completedTasks,
          completionPercentage
        });
      }, 'updateProgress');
    }

    /**
     * Get current progress data
     * @returns {Object|null} Current progress data
     */
    getCurrentProgress() {
      return this.progressData;
    }
  }

  /**
   * Floating Progress Bar System
   * Provides persistent progress visibility at bottom of viewport
   */
  class FloatingProgressBar {
    constructor(debugHelper, enhancer) {
      this.debugHelper = debugHelper;
      this.enhancer = enhancer;
      this.container = null;
      this.isMinimized = false;
      this.isHidden = false;
      this.settings = this.getDefaultFloatingSettings();
      this.errorHandler = errorHandler;
    }

    /**
     * Create and initialize floating progress bar
     */
    create() {
      this.errorHandler.safeExecute(() => {
        if (!this.enhancer.shouldActivateProgressTracking()) {
          return;
        }

        this.container = this.createFloatingContainer();
        if (!this.container) {
          throw new Error('Failed to create floating container');
        }

        this.attachEventListeners();
        this.updateContent();

        this.debugHelper.debug('Floating progress bar created');
      }, 'createFloatingBar');
    }

    /**
     * Create floating container HTML
     * @returns {HTMLElement} Floating container element
     */
    createFloatingContainer() {
      return this.errorHandler.safeExecute(() => {
        const contentType = this.enhancer.getContentType();
        const typeClass = contentType === 'lab' ? 'lab-progress' : 'kata-progress';

        const floatingHtml = `
          <div class="floating-progress-container ${typeClass} appearing" id="floating-progress">
            <div class="floating-progress-header" role="button" tabindex="0" aria-label="Toggle progress bar">
              <h3 class="floating-progress-title">${this.getProgressTitle()}</h3>
              <div class="floating-progress-controls">
                <button class="floating-progress-btn" id="minimize-btn" title="Minimize" aria-label="Minimize progress bar">
                  <span>−</span>
                </button>
                <button class="floating-progress-btn" id="close-btn" title="Hide" aria-label="Hide progress bar">
                  <span>×</span>
                </button>
              </div>
            </div>
            <div class="floating-progress-content">
              <div class="floating-progress-bar" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0">
                <div class="floating-progress-fill"></div>
              </div>
              <div class="floating-progress-stats">
                <span class="floating-progress-percentage">0%</span>
                <span class="floating-progress-tasks">0 of 0 tasks completed</span>
              </div>
              <div class="floating-progress-summary" style="display: none;">
                <div class="floating-progress-sections"></div>
              </div>
            </div>
          </div>
        `;

        document.body.insertAdjacentHTML('beforeend', floatingHtml);
        const container = document.getElementById('floating-progress');

        if (!container) {
          throw new Error('Failed to create floating progress container in DOM');
        }

        return container;
      }, 'createFloatingContainer', null);
    }

    /**
     * Get default floating bar settings
     * @returns {Object} Default settings
     */
    getDefaultFloatingSettings() {
      return {
        isMinimized: false,
        isHidden: false,
        showSectionBreakdown: false
      };
    }

    /**
     * Get progress title based on content type
     * @returns {string} Progress title
     */
    getProgressTitle() {
      const contentType = this.enhancer.getContentType();
      return contentType === 'lab' ? 'Lab Progress' : 'Kata Progress';
    }

    /**
     * Attach event listeners for floating bar controls
     */
    attachEventListeners() {
      this.errorHandler.safeExecute(() => {
        if (!this.container) return;

        const minimizeBtn = this.container.querySelector('#minimize-btn');
        const closeBtn = this.container.querySelector('#close-btn');
        const header = this.container.querySelector('.floating-progress-header');

        if (minimizeBtn) {
          minimizeBtn.addEventListener('click', () => this.toggleMinimized());
        }

        if (closeBtn) {
          closeBtn.addEventListener('click', () => this.hide());
        }

        if (header) {
          header.addEventListener('click', () => this.toggleMinimized());
        }
      }, 'attachEventListeners');
    }

    /**
     * Apply stored settings to floating bar
     */
    applyStoredSettings() {
      // No persistence in minimal version - use defaults
    }

    /**
     * Create scroll-to-top button (minimal implementation)
     */
    createScrollToTopButton() {
      // Minimal implementation - not needed for read-only version
    }

    /**
     * Show completion celebration effect
     */
    showCompletionCelebration() {
      this.errorHandler.safeExecute(() => {
        if (!this.container) return;

        // Add temporary celebration class
        this.container.classList.add('celebration');

        setTimeout(() => {
          this.container.classList.remove('celebration');
        }, 2000);
      }, 'showCompletionCelebration');
    }

    /**
     * Toggle minimized state
     */
    toggleMinimized() {
      this.errorHandler.safeExecute(() => {
        this.isMinimized = !this.isMinimized;
        if (this.isMinimized) {
          this.minimize();
        } else {
          this.expand();
        }
      }, 'toggleMinimized');
    }

    /**
     * Minimize floating bar
     */
    minimize() {
      this.errorHandler.safeExecute(() => {
        if (this.container) {
          this.container.classList.add('minimized');
          this.isMinimized = true;
        }
      }, 'minimize');
    }

    /**
     * Expand floating bar
     */
    expand() {
      this.errorHandler.safeExecute(() => {
        if (this.container) {
          this.container.classList.remove('minimized');
          this.isMinimized = false;
        }
      }, 'expand');
    }

    /**
     * Hide floating bar
     */
    hide() {
      this.errorHandler.safeExecute(() => {
        if (this.container) {
          this.container.classList.add('hidden');
          this.isHidden = true;
        }
      }, 'hide');
    }

    /**
     * Show floating bar
     */
    show() {
      this.errorHandler.safeExecute(() => {
        if (this.container) {
          this.container.classList.remove('hidden');
          this.isHidden = false;
        }
      }, 'show');
    }

    /**
     * Destroy floating bar and clean up
     */
    destroy() {
      this.errorHandler.safeExecute(() => {
        if (this.container) {
          this.container.remove();
          this.container = null;
        }
        this.isMinimized = false;
        this.isHidden = false;
      }, 'destroy');
    }

    /**
     * Update floating bar content with current progress
     */
    updateContent() {
      const endPerf = this.errorHandler.startPerformanceMeasurement('floatingBarUpdateTime');

      this.errorHandler.safeExecute(() => {
        if (!this.container || this.isHidden) return;

        // Get progress from enhancer instead of storage
        const progress = this.enhancer.getCurrentProgress();
        if (!progress || !progress.metadata) return;

        const progressFill = this.container.querySelector('.floating-progress-fill');
        const percentageEl = this.container.querySelector('.floating-progress-percentage');
        const tasksEl = this.container.querySelector('.floating-progress-tasks');
        const progressBar = this.container.querySelector('.floating-progress-bar');

        const percentage = progress.metadata.completionPercentage || 0;

        if (progressFill) {
          progressFill.style.width = `${percentage}%`;
        }

        if (progressBar) {
          progressBar.setAttribute('aria-valuenow', percentage);
          progressBar.setAttribute('aria-label', `Progress: ${percentage}% complete`);
        }

        if (percentageEl) {
          percentageEl.textContent = `${percentage}%`;
        }

        if (tasksEl) {
          tasksEl.textContent = `${progress.metadata.completedTasks || 0} of ${progress.metadata.totalTasks || 0} tasks completed`;
        }

        // Add celebration effect for completion
        if (percentage === 100) {
          this.showCompletionCelebration();
        }
      }, 'updateFloatingBarContent');

      endPerf();
    }
  }

  // Initialize global error handler
  const errorHandler = new ErrorHandler();
  errorHandler.init();

  /**
   * Main plugin function
   * @param {Object} hook - Docsify hook object
   * @param {Object} vm - Docsify VM object
   */
  function interactiveProgressPlugin(hook, vm) {
    const debugHelper = new DebugHelper();
    const enhancer = new CheckboxEnhancer(debugHelper);
    let floatingBar = null;

    // Check system health before initialization
    const healthCheck = errorHandler.checkSystemHealth();
    if (!healthCheck.healthy) {
      console.warn(`[${PLUGIN_CONFIG.name}] System health check failed:`, healthCheck);
    }

    hook.init(() => {
      errorHandler.safeExecute(() => {
        console.log(`[${PLUGIN_CONFIG.name}] Plugin initialized v${PLUGIN_CONFIG.version}`);

        // Expose debug API to global scope for development
        if (PLUGIN_CONFIG.debugMode) {
          window.KataProgressDebug = {
            config: PLUGIN_CONFIG,
            errorHandler,
            debugHelper,
            enhancer,
            floatingBar: () => floatingBar,
            enableDebug: () => {
              PLUGIN_CONFIG.debugMode = true;
              console.log('Debug mode enabled');
            },
            disableDebug: () => {
              PLUGIN_CONFIG.debugMode = false;
              console.log('Debug mode disabled');
            },
            getErrors: () => errorHandler.getErrorSummary(),
            checkHealth: () => errorHandler.checkSystemHealth(),
            clearErrors: () => {
              errorHandler.errors = [];
              console.log('Error log cleared');
            }
          };
          console.log('KataProgressDebug API available in global scope');
        }
      }, 'pluginInit');
    });

    hook.mounted(() => {
      errorHandler.safeExecute(() => {
        console.log(`[${PLUGIN_CONFIG.name}] Plugin mounted`);

        // Initialize floating bar
        floatingBar = new FloatingProgressBar(debugHelper, enhancer);
      }, 'pluginMounted');
    });

    hook.doneEach(() => {
      // Small delay to ensure DOM is fully rendered
      setTimeout(() => {
        errorHandler.safeExecute(() => {
          // Process page for checkbox enhancement
          enhancer.processPage();

          // Create or update floating bar if needed
          if (floatingBar) {
            if (enhancer.shouldActivateProgressTracking()) {
              // Destroy existing floating bar if content type changed
              if (floatingBar.container &&
                  floatingBar.enhancer.getContentType() !== enhancer.getContentType()) {
                floatingBar.destroy();
                floatingBar = new FloatingProgressBar(debugHelper, enhancer);
              }

              // Create floating bar if it doesn't exist
              if (!floatingBar.container) {
                floatingBar.enhancer = enhancer; // Update enhancer reference
                floatingBar.create();
              } else {
                // Update existing floating bar
                floatingBar.updateContent();
              }
            } else {
              // Hide floating bar for non-kata/lab content
              if (floatingBar.container) {
                floatingBar.destroy();
              }
            }
          }
        }, 'pluginDoneEach');
      }, 100);
    });

    hook.beforeEach((content) => {
      // Can be used to modify content before rendering if needed
      return content;
    });
  }

  // Register plugin with docsify
  window.$docsify = window.$docsify || {};
  window.$docsify.plugins = [interactiveProgressPlugin, ...(window.$docsify.plugins || [])];

  // Export for external access if needed
  window.KataProgressAPI = {
    DebugHelper,
    CheckboxEnhancer,
    FloatingProgressBar,
    ErrorHandler,
    errorHandler: errorHandler
  };

  // Log successful plugin loading
  console.log(`[${PLUGIN_CONFIG.name}] Plugin loaded successfully v${PLUGIN_CONFIG.version}`);

})();
