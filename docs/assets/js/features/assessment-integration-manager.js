/**
 * Assessment Integration Manager
 * Coordinates assessment completion with dashboard population
 *
 * @description This module integrates the assessment result processor with
 * existing systems including the learning path category selector, progress
 * tracking, and assessment path generator. It ensures seamless automatic
 * population of learning paths when assessments are completed.
 *
 * @version 1.0.0
 * @since 2025-09-03
 */

import { AssessmentResultProcessor } from './assessment-result-processor.js';
import { DOMUtils } from '../utils/dom-utils.js';
import { ErrorHandler } from '../core/error-handler.js';

/**
 * Assessment Integration Manager Class
 * Manages integration between assessment completion and dashboard systems
 *
 * @class AssessmentIntegrationManager
 * @description Coordinates assessment-driven learning path population
 */
export class AssessmentIntegrationManager {
  /**
   * Create an AssessmentIntegrationManager instance
   *
   * @param {Object} [dependencies={}] - Dependency injection object
   * @param {DOMUtils} [dependencies.domUtils] - DOM utility instance
   * @param {ErrorHandler} [dependencies.errorHandler] - Error handler instance
   * @param {AssessmentResultProcessor} [dependencies.assessmentProcessor] - Assessment processor
   * @param {LearningPathCategorySelector} [dependencies.categorySelector] - Category selector
   */
  constructor(dependencies = {}) {
    this.domUtils = dependencies.domUtils || new DOMUtils();
    this.errorHandler = dependencies.errorHandler || new ErrorHandler('assessment-integration-manager');

    // Initialize core components
    this.assessmentProcessor = dependencies.assessmentProcessor || new AssessmentResultProcessor({
      domUtils: this.domUtils,
      errorHandler: this.errorHandler
    });

    this.categorySelector = dependencies.categorySelector || null;

    // Integration state
    this.isInitialized = false;
    this.integrationConfig = {
      autoPopulateOnAssessment: true,
      showNotifications: true,
      updateProgressTracking: true,
      syncWithCategorySelector: true
    };

    // Event tracking
    this.eventHistory = [];
    this.maxHistoryItems = 50;

    // Integration hooks
    this.hooks = {
      beforeAssessmentProcessing: [],
      afterAssessmentProcessing: [],
      beforeDashboardPopulation: [],
      afterDashboardPopulation: []
    };

    this.init();
  }

  /**
   * Initialize the assessment integration manager
   *
   * @async
   * @public
   */
  async init() {
    return this.errorHandler.safeExecute(async () => {
      if (this.isInitialized) {
        return;
      }

      // Initialize assessment processor
      await this.assessmentProcessor.init();

      // Setup category selector integration if available
      await this.initializeCategorySelectorIntegration();

      // Setup event coordination
      this.setupEventCoordination();

      // Setup integration event listeners
      this.setupIntegrationListeners();

      // Check for assessment-related URL parameters
      this.handleUrlParameters();

      this.isInitialized = true;
      this.errorHandler.logInfo('Assessment integration manager initialized');

    }, 'AssessmentIntegrationManager initialization');
  }

  /**
   * Initialize integration with learning path category selector
   *
   * @async
   * @private
   */
  async initializeCategorySelectorIntegration() {
    return this.errorHandler.safeExecute(async () => {
      // Check for existing category selector instance
      if (!this.categorySelector && window.learningPathCategorySelector) {
        this.categorySelector = window.learningPathCategorySelector;
      }

      if (this.categorySelector && this.integrationConfig.syncWithCategorySelector) {
        // Integrate with category selector events
        this.setupCategorySelectorHooks();
        this.errorHandler.logInfo('Category selector integration initialized');
      }

    }, 'Category selector integration');
  }

  /**
   * Setup hooks for category selector integration
   *
   * @private
   */
  setupCategorySelectorHooks() {
    // Listen for section selection events from category selector
    document.addEventListener('sectionSelectionChanged', this.handleSectionSelectionChange.bind(this));

    // Listen for bulk operations
    document.addEventListener('bulkOperationCompleted', this.handleBulkOperationComplete.bind(this));

    // Listen for progress updates
    document.addEventListener('progressUpdated', this.handleProgressUpdate.bind(this));
  }

  /**
   * Setup event coordination between components
   *
   * @private
   */
  setupEventCoordination() {
    // Coordinate assessment results with other systems
    document.addEventListener('assessmentResultsProcessed', this.handleAssessmentResultsProcessed.bind(this));

    // Coordinate with existing learning path events
    document.addEventListener('learningPathUpdated', this.handleLearningPathUpdate.bind(this));

    // Handle progress synchronization
    document.addEventListener('progressSyncRequired', this.handleProgressSync.bind(this));
  }

  /**
   * Setup integration-specific event listeners
   *
   * @private
   */
  setupIntegrationListeners() {
    // Listen for assessment path generator events
    document.addEventListener('learningPathCreated', this.handleLearningPathCreated.bind(this));

    // Listen for manual integration requests
    document.addEventListener('requestAssessmentIntegration', this.handleManualIntegrationRequest.bind(this));

    // Listen for configuration changes
    document.addEventListener('assessmentIntegrationConfigChanged', this.handleConfigChange.bind(this));
  }

  /**
   * Handle URL parameters related to assessments
   *
   * @private
   */
  handleUrlParameters() {
    const urlParams = new URLSearchParams(window.location.search);

    // Check for assessment completion parameter
    if (urlParams.get('assessment') === 'completed') {
      this.handleAssessmentCompletionFromUrl();
    }

    // Check for auto-populate parameter
    if (urlParams.get('populate') === 'assessment') {
      this.handleAutoPopulateRequest();
    }
  }

  /**
   * Handle assessment completion from URL
   *
   * @async
   * @private
   */
  async handleAssessmentCompletionFromUrl() {
    return this.errorHandler.safeExecute(async () => {
      // Look for assessment data in localStorage or URL
      const assessmentData = this.findAssessmentDataFromUrl();

      if (assessmentData) {
        this.errorHandler.logInfo('Processing assessment from URL parameters');
        await this.assessmentProcessor.processManualAssessment(assessmentData);
      }

    }, 'Handling assessment from URL');
  }

  /**
   * Find assessment data from URL or storage
   *
   * @private
   * @returns {Object|null} Assessment data if found
   */
  findAssessmentDataFromUrl() {
    // Check URL parameters for assessment data
    const urlParams = new URLSearchParams(window.location.search);
    const assessmentId = urlParams.get('assessmentId');

    if (assessmentId) {
      const storedData = localStorage.getItem(`skillAssessment_${assessmentId}`);
      if (storedData) {
        try {
          return JSON.parse(storedData).assessments;
        } catch (_e) {
          this.errorHandler.logWarning('Failed to parse assessment data from URL', { assessmentId });
        }
      }
    }

    return null;
  }

  /**
   * Handle auto-populate request from URL
   *
   * @async
   * @private
   */
  async handleAutoPopulateRequest() {
    return this.errorHandler.safeExecute(async () => {
      // Look for latest assessment results
      const latestAssessment = this.findLatestAssessmentData();

      if (latestAssessment) {
        this.errorHandler.logInfo('Auto-populating from latest assessment');
        await this.assessmentProcessor.processManualAssessment(latestAssessment);
      } else {
        this.showNoAssessmentDataNotification();
      }

    }, 'Handling auto-populate request');
  }

  /**
   * Find latest assessment data from storage
   *
   * @private
   * @returns {Object|null} Latest assessment data
   */
  findLatestAssessmentData() {
    let latestData = null;
    let latestTimestamp = 0;

    // Search through localStorage for assessment data
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && key.startsWith('skillAssessment_')) {
        try {
          const data = JSON.parse(localStorage.getItem(key) || '{}');
          if (data.timestamp && data.timestamp > latestTimestamp && data.assessments) {
            latestTimestamp = data.timestamp;
            latestData = data.assessments;
          }
        } catch (_e) {
          // Skip invalid data
        }
      }
    }

    return latestData;
  }

  /**
   * Handle assessment results processed event
   *
   * @async
   * @private
   * @param {CustomEvent} event - Assessment results processed event
   */
  async handleAssessmentResultsProcessed(event) {
    return this.errorHandler.safeExecute(async () => {
      const { assessmentData, recommendations, processor } = event.detail;

      this.addEventToHistory({
        type: 'assessment-results-processed',
        timestamp: Date.now(),
        data: {
          itemCount: recommendations.itemsToAdd.length,
          overallLevel: recommendations.summary.overallLevel,
          focusAreas: recommendations.focusAreas.map(f => f.area)
        }
      });

      // Execute before hooks
      await this.executeHooks('afterAssessmentProcessing', {
        assessmentData,
        recommendations,
        processor
      });

      // Update category selector if integrated
      if (this.categorySelector && this.integrationConfig.syncWithCategorySelector) {
        await this.syncWithCategorySelector(recommendations);
      }

      // Update progress tracking
      if (this.integrationConfig.updateProgressTracking) {
        await this.updateProgressTracking(recommendations);
      }

      // Dispatch integration completed event
      const integrationEvent = new CustomEvent('assessmentIntegrationCompleted', {
        detail: {
          assessmentData,
          recommendations,
          integrationManager: this
        }
      });
      document.dispatchEvent(integrationEvent);

      this.errorHandler.logInfo('Assessment integration completed', {
        itemsProcessed: recommendations.itemsToAdd.length
      });

    }, 'Handling assessment results processed');
  }

  /**
   * Sync assessment results with category selector
   *
   * @async
   * @private
   * @param {Object} recommendations - Assessment recommendations
   */
  async syncWithCategorySelector(recommendations) {
    return this.errorHandler.safeExecute(async () => {
      if (!this.categorySelector) {
        return;
      }

      // Group recommendations by category/section
      const categoryGroups = {};
      recommendations.itemsToAdd.forEach(item => {
        const category = item.skillArea;
        if (!categoryGroups[category]) {
          categoryGroups[category] = [];
        }
        categoryGroups[category].push(item);
      });

      // Update category selector with assessment-driven selections
      for (const [category, items] of Object.entries(categoryGroups)) {
        if (this.categorySelector.updateCategorySelection) {
          await this.categorySelector.updateCategorySelection(category, items);
        }
      }

      // Refresh category selector display
      if (this.categorySelector.refreshDisplay) {
        await this.categorySelector.refreshDisplay();
      }

    }, 'Syncing with category selector');
  }

  /**
   * Update progress tracking with assessment results
   *
   * @async
   * @private
   * @param {Object} recommendations - Assessment recommendations
   */
  async updateProgressTracking(recommendations) {
    return this.errorHandler.safeExecute(async () => {
      const progressUpdate = {
        source: 'assessment-integration',
        timestamp: Date.now(),
        totalItems: recommendations.summary.totalItems,
        priorityItems: recommendations.summary.priorityCount,
        estimatedDuration: recommendations.estimatedDuration,
        focusAreas: recommendations.focusAreas
      };

      // Store progress update
      const progressKey = `assessmentProgress_${Date.now()}`;
      localStorage.setItem(progressKey, JSON.stringify(progressUpdate));

      // Dispatch progress update event
      const progressEvent = new CustomEvent('assessmentProgressUpdated', {
        detail: progressUpdate
      });
      document.dispatchEvent(progressEvent);

    }, 'Updating progress tracking');
  }

  /**
   * Handle section selection change from category selector
   *
   * @private
   * @param {CustomEvent} event - Section selection change event
   */
  handleSectionSelectionChange(event) {
    this.errorHandler.safeExecute(() => {
      const { section, selected, source } = event.detail;

      // Track integration-related selection changes
      if (source === 'assessment' || source === 'assessment-integration') {
        this.addEventToHistory({
          type: 'section-selection-changed',
          timestamp: Date.now(),
          data: { section, selected, source }
        });
      }

    }, 'Handling section selection change');
  }

  /**
   * Handle bulk operation completion
   *
   * @private
   * @param {CustomEvent} event - Bulk operation completed event
   */
  handleBulkOperationComplete(event) {
    this.errorHandler.safeExecute(() => {
      const { operation, itemCount, source } = event.detail;

      // Log bulk operations that may affect assessment integration
      this.addEventToHistory({
        type: 'bulk-operation-completed',
        timestamp: Date.now(),
        data: { operation, itemCount, source }
      });

      // Check if this affects our assessment-populated items
      if (operation === 'clearAll' || operation === 'selectAll') {
        this.handleBulkOperationImpact(operation, itemCount);
      }

    }, 'Handling bulk operation complete');
  }

  /**
   * Handle impact of bulk operations on assessment-populated items
   *
   * @private
   * @param {string} operation - The bulk operation performed
   * @param {number} itemCount - Number of items affected
   */
  handleBulkOperationImpact(operation, itemCount) {
    const assessmentItems = document.querySelectorAll('.learning-path-item.assessment-populated');

    if (assessmentItems.length > 0) {
      const notification = document.createElement('div');
      notification.className = 'assessment-integration-notice';
      notification.innerHTML = `
        <div class="notice-content">
          <span class="notice-icon">ℹ️</span>
          <span class="notice-text">
            ${operation === 'clearAll' ? 'Cleared' : 'Selected'} ${itemCount} items,
            including ${assessmentItems.length} assessment-recommended items.
          </span>
        </div>
      `;

      // Add to notifications container
      const container = document.querySelector('.learning-path-notifications') || document.body;
      container.appendChild(notification);

      // Auto-remove
      setTimeout(() => notification.remove(), 3000);
    }
  }

  /**
   * Handle learning path creation event
   *
   * @async
   * @private
   * @param {CustomEvent} event - Learning path created event
   */
  async handleLearningPathCreated(event) {
    return this.errorHandler.safeExecute(async () => {
      const { source, pathData } = event.detail;

      // Only handle non-assessment sources (assessment sources are handled by processor)
      if (source !== 'assessment' && source !== 'assessment-processor') {
        this.addEventToHistory({
          type: 'learning-path-created',
          timestamp: Date.now(),
          data: { source, pathId: pathData.metadata?.learningPathId }
        });

        // Check if this conflicts with assessment recommendations
        await this.checkForAssessmentConflicts(pathData);
      }

    }, 'Handling learning path created');
  }

  /**
   * Check for conflicts between manual paths and assessment recommendations
   *
   * @async
   * @private
   * @param {Object} pathData - Learning path data
   */
  async checkForAssessmentConflicts(pathData) {
    return this.errorHandler.safeExecute(async () => {
      // Get latest assessment recommendations
      const latestCoachData = localStorage.getItem('latestAssessmentForCoach');
      if (!latestCoachData) {
        return;
      }

      const coachData = JSON.parse(latestCoachData);
      const assessmentFocusAreas = coachData.focusAreas?.map(f => f.area) || [];
      const pathCategories = pathData.learningPath?.categories || [];

      // Check for overlaps
      const overlaps = assessmentFocusAreas.filter(area =>
        pathCategories.some(cat => cat.includes(area) || area.includes(cat))
      );

      if (overlaps.length > 0) {
        this.showConflictNotification(overlaps, pathData);
      }

    }, 'Checking assessment conflicts');
  }

  /**
   * Show notification about conflicts between manual and assessment paths
   *
   * @private
   * @param {Array} overlaps - Overlapping areas
   * @param {Object} pathData - Path data
   */
  showConflictNotification(overlaps, _pathData) {
    const notification = document.createElement('div');
    notification.className = 'assessment-conflict-notification';
    notification.innerHTML = `
      <div class="conflict-header">
        <span class="conflict-icon">⚠️</span>
        <h4>Assessment Recommendation Notice</h4>
      </div>
      <div class="conflict-content">
        <p>Your new learning path overlaps with assessment recommendations in:</p>
        <ul>${overlaps.map(area => `<li>${area.replace(/-/g, ' ')}</li>`).join('')}</ul>
        <p>Consider reviewing your assessment results for personalized recommendations.</p>
      </div>
      <button class="view-assessment-btn" onclick="this.dispatchEvent(new CustomEvent('viewAssessmentRecommendations', {bubbles: true}))">
        View Assessment Recommendations
      </button>
    `;

    const container = document.querySelector('.learning-path-notifications') || document.body;
    container.appendChild(notification);

    setTimeout(() => notification.remove(), 8000);
  }

  /**
   * Execute hooks for integration events
   *
   * @async
   * @private
   * @param {string} hookName - Name of the hook to execute
   * @param {Object} data - Data to pass to hooks
   */
  async executeHooks(hookName, data) {
    const hooks = this.hooks[hookName] || [];

    for (const hook of hooks) {
      try {
        await hook(data);
      } catch (error) {
        this.errorHandler.logError('Hook execution failed', { hookName, error });
      }
    }
  }

  /**
   * Add event to integration history
   *
   * @private
   * @param {Object} event - Event to add to history
   */
  addEventToHistory(event) {
    this.eventHistory.unshift(event);

    // Limit history size
    if (this.eventHistory.length > this.maxHistoryItems) {
      this.eventHistory = this.eventHistory.slice(0, this.maxHistoryItems);
    }
  }

  /**
   * Show notification when no assessment data is available
   *
   * @private
   */
  showNoAssessmentDataNotification() {
    const notification = document.createElement('div');
    notification.className = 'no-assessment-notification';
    notification.innerHTML = `
      <div class="notification-content">
        <span class="notification-icon">📝</span>
        <h4>No Assessment Data Found</h4>
        <p>Complete a skill assessment first to get personalized learning path recommendations.</p>
        <a href="learning/skill-assessment.md" class="assessment-link">Take Assessment</a>
      </div>
    `;

    const container = document.querySelector('.learning-path-notifications') || document.body;
    container.appendChild(notification);

    setTimeout(() => notification.remove(), 6000);
  }

  /**
   * Register a hook for integration events
   *
   * @public
   * @param {string} hookName - Name of the hook
   * @param {Function} callback - Callback function
   */
  registerHook(hookName, callback) {
    if (!this.hooks[hookName]) {
      this.hooks[hookName] = [];
    }
    this.hooks[hookName].push(callback);
  }

  /**
   * Update integration configuration
   *
   * @public
   * @param {Object} config - Configuration updates
   */
  updateConfig(config) {
    this.integrationConfig = { ...this.integrationConfig, ...config };

    const configEvent = new CustomEvent('assessmentIntegrationConfigChanged', {
      detail: { config: this.integrationConfig }
    });
    document.dispatchEvent(configEvent);
  }

  /**
   * Get integration status and statistics
   *
   * @public
   * @returns {Object} Integration status
   */
  getIntegrationStatus() {
    return {
      isInitialized: this.isInitialized,
      hasAssessmentProcessor: !!this.assessmentProcessor,
      hasCategorySelector: !!this.categorySelector,
      config: { ...this.integrationConfig },
      eventHistory: this.eventHistory.slice(0, 10), // Last 10 events
      processingState: this.assessmentProcessor?.getProcessingState() || null
    };
  }

  /**
   * Manually trigger assessment integration
   *
   * @async
   * @public
   * @param {Object} assessmentData - Assessment data to process
   * @returns {Object} Integration results
   */
  async triggerManualIntegration(assessmentData) {
    return this.errorHandler.safeExecute(async () => {
      this.errorHandler.logInfo('Triggering manual assessment integration');

      const results = await this.assessmentProcessor.processManualAssessment(assessmentData);

      this.addEventToHistory({
        type: 'manual-integration-triggered',
        timestamp: Date.now(),
        data: { itemCount: results.recommendations?.itemsToAdd?.length || 0 }
      });

      return results;
    }, 'Manual assessment integration');
  }
}

// Export for use in other modules
export default AssessmentIntegrationManager;
