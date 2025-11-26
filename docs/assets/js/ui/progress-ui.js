/**
 * Progress UI - Unified Progress Visualization Components
 * Consolidates progress-dashboard.js, advanced-progress-visualizer.js, and progress-bar-manager.js
 * Single responsibility:    } catch (error) {
      this.handleError(`Failed to update progress bar ${id}`, error);
    }l progress UI components and visualizations
 * Version: 3.0.0
 */

import { logger } from '../utils/index.js';

/**
 * Unified progress UI system with comprehensive visualization components
 * Handles all progr    } catch (error) {
      this.handleError('Failed to hide dashboard', error);
    } displays, dashboards, charts, and interactive elements
 *
 * @class ProgressUI
 * @module ui/progress-ui
 * @example
 * const progressUI = new ProgressUI({
 *   progressCore: progressCoreInstance,
 *   errorHandler: errorHandlerInstance,
 *   domUtils: domUtilsInstance
 * });
 */
export class ProgressUI {
  /**
   * Initialize unified progress UI system
   * @param {Object} dependencies - Required dependencies
   * @param {Object} dependencies.progressCore - Core progress tracking instance
   * @param {Object} dependencies.errorHandler - Error handling service
   * @param {Object} dependencies.domUtils - DOM utilities service
   * @param {Object} config - Configuration options
   */
  constructor(dependencies = {}, config = {}) {
    this.validateDependencies(dependencies);

    // Core dependencies
    this.progressCore = dependencies.progressCore;
    this.errorHandler = dependencies.errorHandler;
    this.domUtils = dependencies.domUtils;

    // Optional dependencies with fallbacks
    this.kataCatalog = dependencies.kataCatalog || null;
    this.learningPathManager = dependencies.learningPathManager || null;

    // Configuration with deep merge for nested objects
    const defaultConfig = {
      animationDuration: 300,
      updateInterval: 1000,
      chartColors: {
        primary: '#007acc',
        secondary: '#28a745',
        warning: '#ffc107',
        danger: '#dc3545',
        info: '#17a2b8'
      },
      progressBarHeight: 6,
      showAnimations: true,
      enableTooltips: true
    };

    this.config = {
      ...defaultConfig,
      ...config,
      chartColors: {
        ...defaultConfig.chartColors,
        ...(config.chartColors || {})
      }
    };

    // UI state management
    this.activeComponents = new Map();
    this.eventListeners = new Map();
    this.updateIntervals = new Map();
    this.isInitialized = false;

    // Progress bar management
    this.progressBars = new Map();
    this.progressContainers = new Map();

    // Dashboard state
    this.dashboardVisible = false;
    this.currentDashboardData = null;

    // Visualization components
    this.charts = new Map();
    this.visualizers = new Map();

    // Global reference for compatibility
    if (typeof window !== 'undefined') {
      window.progressUI = this;
    }
  }

  /**
   * Validate required dependencies
   * @param {Object} dependencies - Dependencies to validate
   * @private
   */
  validateDependencies(dependencies) {
    const required = ['progressCore', 'errorHandler', 'domUtils'];

    for (const dep of required) {
      if (!dependencies[dep]) {
        throw new Error(`ProgressUI requires ${dep} dependency`);
      }
    }
  }

  /**
   * Initialize the progress UI system
   * @returns {Promise<boolean>} Success status
   */
  async init() {
    if (this.isInitialized) {
      return true;
    }

    try {
      await this.setupProgressBars();
      await this.setupDashboard();
      await this.setupVisualizers();
      this.setupEventListeners();

      this.isInitialized = true;
      return true;
    } catch (error) {
      this.handleError('Initialization failed', error);
      return false;
    }
  }

  /**
   * Setup progress bar system
   * @private
   */
  async setupProgressBars() {
    // Find all existing progress containers
    const containers = this.domUtils.querySelectorAll('[data-progress-container]');

    containers.forEach(container => {
      const id = container.getAttribute('data-progress-container');
      this.progressContainers.set(id, container);
      this.createProgressBar(id, container);
    });
  }

  /**
   * Create a progress bar in the specified container
   * @param {string} id - Progress bar identifier
   * @param {HTMLElement} container - Container element
   */
  createProgressBar(id, container) {
    try {
      // Create progress bar structure
      const progressWrapper = this.domUtils.createElement('div');
      progressWrapper.className = 'progress-wrapper';

      const progressBar = this.domUtils.createElement('div');
      progressBar.className = 'progress-bar';
      progressBar.style.height = `${this.config.progressBarHeight}px`;

      const progressFill = this.domUtils.createElement('div');
      progressFill.className = 'progress-fill';
      progressFill.style.width = '0%';
      progressFill.style.backgroundColor = this.config.chartColors.primary;
      progressFill.style.transition = this.config.showAnimations ?
        `width ${this.config.animationDuration}ms ease-in-out` : 'none';

      const progressText = this.domUtils.createElement('div');
      progressText.className = 'progress-text';
      progressText.style.display = 'none';

      // Assemble structure
      progressBar.appendChild(progressFill);
      progressWrapper.appendChild(progressBar);
      progressWrapper.appendChild(progressText);
      container.appendChild(progressWrapper);

      // Store references
      this.progressBars.set(id, {
        container,
        wrapper: progressWrapper,
        bar: progressBar,
        fill: progressFill,
        text: progressText,
        value: 0,
        max: 100,
        visible: true
      });
    } catch (error) {
      this.handleError(`Failed to create progress bar ${id}`, error);
    }
  }

  /**
   * Update progress bar value
   * @param {string} id - Progress bar identifier
   * @param {number} value - Progress value (0-100)
   * @param {Object} options - Update options
   */
  updateProgressBar(id, value, options = {}) {
    try {
      const progressBar = this.progressBars.get(id);
      if (!progressBar) {
        logger.warn(`[ProgressUI] Progress bar not found: ${id}`);
        return false;
      }

      // Clamp value between 0 and max
      const clampedValue = Math.max(0, Math.min(value, progressBar.max));
      const percentage = (clampedValue / progressBar.max) * 100;

      // Update visual elements
      progressBar.fill.style.width = `${percentage}%`;
      progressBar.value = clampedValue;

      // Update text if provided
      if (options.text || options.showPercentage) {
        const text = options.text || `${Math.round(percentage)}%`;
        progressBar.text.textContent = text;
        progressBar.text.style.display = 'block';
      }

      // Update color based on percentage
      if (options.autoColor !== false) {
        progressBar.fill.style.backgroundColor = this.getProgressColor(percentage);
      }

      // Custom color override
      if (options.color) {
        progressBar.fill.style.backgroundColor = options.color;
      }
      return true;
    } catch (error) {
      this.handleError(`Failed to update progress bar ${id}`, error);
      return false;
    }
  }

  /**
   * Get appropriate color for progress percentage
   * @param {number} percentage - Progress percentage
   * @returns {string} Color value
   * @private
   */
  getProgressColor(percentage) {
    if (percentage < 25) {return this.config.chartColors.danger;}
    if (percentage < 50) {return this.config.chartColors.warning;}
    if (percentage < 75) {return this.config.chartColors.info;}
    return this.config.chartColors.secondary;
  }

  /**
   * Setup dashboard system
   * @private
   */
  async setupDashboard() {
    // Create dashboard container if it doesn't exist
    let dashboardContainer = this.domUtils.querySelector('#progress-dashboard');

    if (!dashboardContainer) {
      dashboardContainer = this.domUtils.createElement('div');
      dashboardContainer.id = 'progress-dashboard';
      dashboardContainer.className = 'progress-dashboard hidden';
      dashboardContainer.innerHTML = this.getDashboardHTML();

      // Append to body or designated container
      const target = this.domUtils.querySelector('[data-dashboard-mount]') || document.body;
      target.appendChild(dashboardContainer);
    }

    this.activeComponents.set('dashboard', dashboardContainer);
  }

  /**
   * Get dashboard HTML structure
   * @returns {string} Dashboard HTML
   * @private
   */
  getDashboardHTML() {
    return `
      <div class="dashboard-header">
        <h2>Learning Progress Dashboard</h2>
        <button class="dashboard-close" aria-label="Close dashboard">×</button>
      </div>
      <div class="dashboard-content">
        <div class="dashboard-stats">
          <div class="stat-card" data-stat="total-progress">
            <h3>Overall Progress</h3>
            <div class="stat-value">0%</div>
            <div class="stat-bar"></div>
          </div>
          <div class="stat-card" data-stat="completed-katas">
            <h3>Completed Katas</h3>
            <div class="stat-value">0</div>
          </div>
          <div class="stat-card" data-stat="active-paths">
            <h3>Active Paths</h3>
            <div class="stat-value">0</div>
          </div>
          <div class="stat-card" data-stat="time-spent">
            <h3>Time Invested</h3>
            <div class="stat-value">0h</div>
          </div>
        </div>
        <div class="dashboard-charts">
          <div class="chart-container" data-chart="progress-timeline">
            <h3>Progress Timeline</h3>
            <div class="chart-placeholder">Chart will be rendered here</div>
          </div>
          <div class="chart-container" data-chart="kata-breakdown">
            <h3>Kata Completion Breakdown</h3>
            <div class="chart-placeholder">Chart will be rendered here</div>
          </div>
        </div>
        <div class="dashboard-details">
          <div class="recent-activity">
            <h3>Recent Activity</h3>
            <div class="activity-list"></div>
          </div>
          <div class="next-steps">
            <h3>Recommended Next Steps</h3>
            <div class="recommendations-list"></div>
          </div>
        </div>
      </div>
    `;
  }

  /**
   * Show the progress dashboard
   * @param {Object} options - Display options
   */
  async showDashboard(_options = {}) {
    try {
      const dashboard = this.activeComponents.get('dashboard');
      if (!dashboard) {
        logger.warn('[ProgressUI] Dashboard not initialized');
        return false;
      }

      // Load current progress data
      await this.updateDashboardData();

      // Show dashboard
      dashboard.classList.remove('hidden');
      this.dashboardVisible = true;

      // Setup dashboard event listeners if not already done
      if (!this.eventListeners.has('dashboard')) {
        this.setupDashboardEvents(dashboard);
      }

      return true;
    } catch (error) {
      this.handleError('Failed to show dashboard', error);
      return false;
    }
  }

  /**
   * Hide the progress dashboard
   */
  hideDashboard() {
    try {
      const dashboard = this.activeComponents.get('dashboard');
      if (dashboard) {
        dashboard.classList.add('hidden');
        this.dashboardVisible = false;
        return true;
      }
      return false;
    } catch (error) {
      this.handleError('Failed to hide dashboard', error);
      return false;
    }
  }

  /**
   * Update dashboard with current progress data
   * @private
   */
  async updateDashboardData() {
    try {
      const allProgress = this.progressCore.getAllProgress();
      const stats = this.calculateProgressStats(allProgress);

      this.currentDashboardData = {
        stats,
        lastUpdated: new Date().toISOString(),
        progressData: allProgress
      };

      // Update stat cards
      this.updateStatCards(stats);

      // Update activity feed
      this.updateActivityFeed(allProgress);

      // Update recommendations
      this.updateRecommendations(stats);

    } catch (error) {
      this.handleError('Failed to update dashboard data', error);
    }
  }

  /**
   * Calculate comprehensive progress statistics
   * @param {Map} progressData - All progress data
   * @returns {Object} Calculated statistics
   * @private
   */
  calculateProgressStats(progressData) {
    let totalKatas = 0;
    let completedKatas = 0;
    let activePaths = 0;
    let totalTimeSpent = 0;

    for (const [_moduleKey, moduleData] of progressData) {
      const data = moduleData.data || {};

      // Count katas
      if (data.checkboxes) {
        const checkboxes = Object.values(data.checkboxes);
        totalKatas += checkboxes.length;
        completedKatas += checkboxes.filter(Boolean).length;
      }

      // Count active learning paths
      if (data.activePaths) {
        activePaths += Object.keys(data.activePaths).length;
      }

      // Sum time spent
      if (data.timeSpent) {
        totalTimeSpent += data.timeSpent;
      }
    }

    const overallProgress = totalKatas > 0 ? (completedKatas / totalKatas) * 100 : 0;

    return {
      overallProgress: Math.round(overallProgress),
      totalKatas,
      completedKatas,
      activePaths,
      timeSpent: Math.round(totalTimeSpent / 3600), // Convert to hours
      completionRate: overallProgress
    };
  }

  /**
   * Update dashboard stat cards
   * @param {Object} stats - Statistics to display
   * @private
   */
  updateStatCards(stats) {
    const statCards = {
      'total-progress': { value: `${stats.overallProgress}%`, hasBar: true },
      'completed-katas': { value: `${stats.completedKatas}/${stats.totalKatas}` },
      'active-paths': { value: stats.activePaths },
      'time-spent': { value: `${stats.timeSpent}h` }
    };

    for (const [statKey, statData] of Object.entries(statCards)) {
      const card = this.domUtils.querySelector(`[data-stat="${statKey}"]`);
      if (card) {
        const valueElement = card.querySelector('.stat-value');
        if (valueElement) {
          valueElement.textContent = statData.value;
        }

        // Update progress bar for total progress
        if (statData.hasBar) {
          const barElement = card.querySelector('.stat-bar');
          if (barElement) {
            barElement.style.width = `${stats.overallProgress}%`;
            barElement.style.backgroundColor = this.getProgressColor(stats.overallProgress);
          }
        }
      }
    }
  }

  /**
   * Update activity feed
   * @param {Map} progressData - Progress data
   * @private
   */
  updateActivityFeed(progressData) {
    const activityList = this.domUtils.querySelector('.activity-list');
    if (!activityList) {return;}

    const activities = [];

    // Extract recent activities from progress data
    for (const [moduleKey, moduleData] of progressData) {
      if (moduleData.timestamp) {
        activities.push({
          timestamp: moduleData.timestamp,
          module: moduleKey,
          type: 'progress_update',
          description: `Updated progress in ${moduleKey}`
        });
      }
    }

    // Sort by timestamp (most recent first)
    activities.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    // Display top 5 activities
    const recentActivities = activities.slice(0, 5);
    activityList.innerHTML = recentActivities.map(activity => `
      <div class="activity-item">
        <div class="activity-time">${this.formatTimestamp(activity.timestamp)}</div>
        <div class="activity-description">${activity.description}</div>
      </div>
    `).join('');
  }

  /**
   * Update recommendations
   * @param {Object} stats - Progress statistics
   * @private
   */
  updateRecommendations(stats) {
    const recommendationsList = this.domUtils.querySelector('.recommendations-list');
    if (!recommendationsList) {return;}

    const recommendations = [];

    // Generate recommendations based on stats
    if (stats.overallProgress < 25) {
      recommendations.push('Start with foundational katas to build momentum');
    } else if (stats.overallProgress < 50) {
      recommendations.push('Focus on completing current learning paths');
    } else if (stats.overallProgress < 75) {
      recommendations.push('Explore advanced topics and specializations');
    } else {
      recommendations.push('Consider mentoring others or contributing to the community');
    }

    if (stats.activePaths === 0) {
      recommendations.push('Choose a learning path to get structured guidance');
    }

    if (stats.timeSpent < 10) {
      recommendations.push('Set aside regular study time for consistent progress');
    }

    recommendationsList.innerHTML = recommendations.map(rec => `
      <div class="recommendation-item">
        <div class="recommendation-text">${rec}</div>
      </div>
    `).join('');
  }

  /**
   * Format timestamp for display
   * @param {string} timestamp - ISO timestamp
   * @returns {string} Formatted time
   * @private
   */
  formatTimestamp(timestamp) {
    try {
      if (!timestamp) {return 'Unknown';}

      const date = new Date(timestamp);
      if (isNaN(date.getTime())) {return 'Unknown';}

      const now = new Date(Date.now());
      const diff = now - date;

      if (diff < 60000) {return 'Just now';}
      if (diff < 3600000) {return `${Math.floor(diff / 60000)}m ago`;}
      if (diff < 86400000) {return `${Math.floor(diff / 3600000)}h ago`;}
      return `${Math.floor(diff / 86400000)}d ago`;
    } catch {
      return 'Unknown';
    }
  }

  /**
   * Setup dashboard event listeners
   * @param {HTMLElement} dashboard - Dashboard element
   * @private
   */
  setupDashboardEvents(dashboard) {
    const closeButton = dashboard.querySelector('.dashboard-close');
    if (closeButton) {
      closeButton.addEventListener('click', () => this.hideDashboard());
    }

    // ESC key to close
    const escapeHandler = (event) => {
      if (event.key === 'Escape' && this.dashboardVisible) {
        this.hideDashboard();
      }
    };

    document.addEventListener('keydown', escapeHandler);

    this.eventListeners.set('dashboard', {
      closeButton,
      escapeHandler
    });
  }

  /**
   * Setup visualization components
   * @private
   */
  async setupVisualizers() {
    // Basic visualization setup - can be expanded with chart libraries
  }

  /**
   * Setup global event listeners
   * @private
   */
  setupEventListeners() {
    // Auto-update intervals
    if (this.config.updateInterval > 0) {
      const updateInterval = setInterval(() => {
        if (this.dashboardVisible) {
          this.updateDashboardData();
        }
      }, this.config.updateInterval);

      this.updateIntervals.set('dashboard', updateInterval);
    }
  }

  /**
   * Handle errors with fallback logging
   * @param {string} message - Error message
   * @param {Error} error - Error object
   * @private
   */
  handleError(message, error) {
    if (this.errorHandler && typeof this.errorHandler.handleError === 'function') {
      this.errorHandler.handleError(error, message);
    } else {
      // Fallback to logger.error when no error handler
      logger.error(`[ProgressUI] ${message}:`, error);
    }
  }

  /**
   * Cleanup resources and event listeners
   */
  destroy() {
    // Clear update intervals
    for (const interval of this.updateIntervals.values()) {
      clearInterval(interval);
    }
    this.updateIntervals.clear();

    // Remove event listeners
    for (const [_key, listeners] of this.eventListeners.entries()) {
      if (listeners.escapeHandler) {
        document.removeEventListener('keydown', listeners.escapeHandler);
      }
    }
    this.eventListeners.clear();

    // Clear global reference
    if (typeof window !== 'undefined' && window.progressUI === this) {
      window.progressUI = null;
    }
  }
}

// Default export for backward compatibility
export default ProgressUI;
