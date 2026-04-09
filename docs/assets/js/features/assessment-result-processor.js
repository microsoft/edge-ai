/**
 * Assessment Result Processor
 * Processes assessment results and integrates with learning path dashboard
 *
 * @description This module handles the integration between skill assessment
 * completion and learning path dashboard population. It processes assessment
 * scores, generates path recommendations, and automatically populates the
 * dashboard with recommended learning items.
 *
 * @version 1.0.0
 * @since 2025-09-03
 */

import { DOMUtils } from '../utils/dom-utils.js';
import { ErrorHandler } from '../core/error-handler.js';
import { LearningPathManager } from '../core/learning-path-manager.js';
import { LEARNING_PATH_CONSTANTS } from '../core/learning-path-constants.js';

const { SKILL_LEVELS, SCORE_THRESHOLDS } = LEARNING_PATH_CONSTANTS;

/**
 * Assessment Result Processor Class
 * Handles assessment completion and dashboard integration
 *
 * @class AssessmentResultProcessor
 * @description Processes assessment results and populates learning paths
 */
export class AssessmentResultProcessor {
  /**
   * Create an AssessmentResultProcessor instance
   *
   * @param {Object} [dependencies={}] - Dependency injection object
   * @param {DOMUtils} [dependencies.domUtils] - DOM utility instance
   * @param {ErrorHandler} [dependencies.errorHandler] - Error handler instance
   * @param {LearningPathManager} [dependencies.learningPathManager] - Learning path manager
   */
  constructor(dependencies = {}) {
    this.domUtils = dependencies.domUtils || new DOMUtils();
    this.errorHandler = dependencies.errorHandler || new ErrorHandler('assessment-result-processor');
    this.learningPathManager = dependencies.learningPathManager || new LearningPathManager();

    // Configuration
    this.storageKey = 'assessmentResultProcessor';
    this.dashboardSelectors = {
      learningPaths: '.learning-path-item',
      dualCheckboxes: '.dual-checkbox-container',
      pathCheckbox: 'input[type="checkbox"][data-type="path"]',
      completedCheckbox: 'input[type="checkbox"][data-type="completed"]'
    };

    // Assessment scoring configuration
    this.scoringThresholds = {
      beginner: { min: 1, max: 2 },
      intermediate: { min: 2.5, max: 3.5 },
      advanced: { min: 4, max: 5 }
    };

    // Path mapping configuration
    this.pathMappings = this.initializePathMappings();

    // State tracking
    this.isInitialized = false;
    this.currentAssessment = null;
    this.processingState = {
      isProcessing: false,
      processedAt: null,
      results: null
    };

    this.init();
  }

  /**
   * Initialize the assessment result processor
   *
   * @async
   * @public
   */
  async init() {
    return this.errorHandler.safeExecute(async () => {
      if (this.isInitialized) {
        return;
      }

      // Listen for assessment completion events
      this.setupEventListeners();

      // Check for any pending assessment results
      await this.checkPendingResults();

      this.isInitialized = true;
      this.errorHandler.logInfo('Assessment result processor initialized');
    }, 'AssessmentResultProcessor initialization');
  }

  /**
   * Initialize path mapping configuration
   *
   * @private
   * @returns {Object} Path mapping configuration
   */
  initializePathMappings() {
    return {
      // Beginner paths (scores 1-2)
      beginner: {
        'ai-assisted-engineering': [
          'getting-started/ai-assisted-development-basics',
          'getting-started/prompt-engineering-fundamentals',
          'getting-started/code-generation-basics'
        ],
        'edge-deployment': [
          'getting-started/containerization-basics',
          'getting-started/edge-computing-introduction',
          'getting-started/deployment-fundamentals'
        ],
        'project-planning': [
          'getting-started/technical-planning-basics',
          'getting-started/project-management-fundamentals',
          'getting-started/agile-methodologies'
        ],
        'system-troubleshooting': [
          'getting-started/debugging-fundamentals',
          'getting-started/log-analysis-basics',
          'getting-started/problem-solving-methods'
        ]
      },
      // Intermediate paths (scores 2.5-3.5)
      intermediate: {
        'ai-assisted-engineering': [
          'intermediate/advanced-prompt-engineering',
          'intermediate/ai-code-review-techniques',
          'intermediate/automated-testing-with-ai'
        ],
        'edge-deployment': [
          'intermediate/kubernetes-edge-deployment',
          'intermediate/iot-integration-patterns',
          'intermediate/edge-security-implementation'
        ],
        'project-planning': [
          'intermediate/technical-architecture-planning',
          'intermediate/risk-management-strategies',
          'intermediate/stakeholder-communication'
        ],
        'system-troubleshooting': [
          'intermediate/advanced-debugging-techniques',
          'intermediate/performance-optimization',
          'intermediate/incident-response-procedures'
        ]
      },
      // Advanced paths (scores 4-5)
      advanced: {
        'ai-assisted-engineering': [
          'advanced/ai-architecture-design',
          'advanced/custom-ai-tool-development',
          'advanced/ai-engineering-leadership'
        ],
        'edge-deployment': [
          'advanced/edge-orchestration-platforms',
          'advanced/edge-ai-deployment',
          'advanced/edge-infrastructure-automation'
        ],
        'project-planning': [
          'advanced/enterprise-architecture-planning',
          'advanced/cross-functional-team-leadership',
          'advanced/technical-strategy-development'
        ],
        'system-troubleshooting': [
          'advanced/complex-system-analysis',
          'advanced/troubleshooting-methodology-design',
          'advanced/system-reliability-engineering'
        ]
      }
    };
  }

  /**
   * Setup event listeners for assessment completion
   *
   * @private
   */
  setupEventListeners() {
    // Store bound handlers for testing
    this._boundHandlers = {
      assessmentCompletion: this.handleAssessmentCompletion.bind(this),
      directAssessment: this.handleDirectAssessment.bind(this),
      storageChange: this.handleStorageChange.bind(this)
    };

    // Listen for learning path creation from assessment
    document.addEventListener('learningPathCreated', this._boundHandlers.assessmentCompletion);

    // Listen for custom assessment events
    document.addEventListener('assessmentCompleted', this._boundHandlers.directAssessment);

    // Listen for storage changes (assessment results saved elsewhere)
    window.addEventListener('storage', this._boundHandlers.storageChange);
  }

  /**
   * Handle assessment completion event
   *
   * @async
   * @private
   * @param {CustomEvent} event - Assessment completion event
   */
  async handleAssessmentCompletion(event) {
    return this.errorHandler.safeExecute(async () => {
      if (event.detail?.source !== 'assessment') {
        return; // Only handle assessment-generated paths
      }

      const pathData = event.detail.pathData;
      const assessmentData = pathData.metadata?.assessmentData;

      if (!assessmentData) {
        this.errorHandler.logWarning('No assessment data found in path creation event');
        return;
      }

      this.errorHandler.logInfo('Processing assessment completion', { pathData });

      // Process the assessment results
      await this.processAssessmentResults(assessmentData, pathData);

    }, 'Handling assessment completion');
  }

  /**
   * Handle direct assessment completion
   *
   * @async
   * @private
   * @param {CustomEvent} event - Direct assessment event
   */
  async handleDirectAssessment(event) {
    return this.errorHandler.safeExecute(async () => {
      const assessmentData = event.detail?.assessmentData;
      if (!assessmentData) {
        this.errorHandler.logWarning('No assessment data in direct assessment event');
        return;
      }

      // Analyze assessment scores first
      const analysisResults = this.analyzeAssessmentScores(assessmentData);

      // Generate path recommendations from analysis
      const pathRecommendations = this.generatePathRecommendations(analysisResults);

      // Create path data structure
      const pathData = this.createPathDataFromRecommendations(pathRecommendations, assessmentData);

      // Process the results
      await this.processAssessmentResults(assessmentData, pathData);

    }, 'Handling direct assessment');
  }

  /**
   * Handle storage changes for assessment results
   *
   * @private
   * @param {StorageEvent} event - Storage change event
   */
  handleStorageChange(event) {
    if (event.key && event.key.startsWith('skillAssessment_') && event.newValue) {
      this.errorHandler.safeExecute(() => {
        const assessmentData = JSON.parse(event.newValue);
        if (assessmentData.assessments && !assessmentData.processed) {
          // Mark as processed to avoid duplicate processing
          assessmentData.processed = true;
          localStorage.setItem(event.key, JSON.stringify(assessmentData));

          // Process the assessment
          this.handleDirectAssessment({
            detail: { assessmentData: assessmentData.assessments }
          });
        }
      }, 'Handling storage change');
    }
  }

  /**
   * Check for pending assessment results on initialization
   *
   * @async
   * @private
   */
  async checkPendingResults() {
    return this.errorHandler.safeExecute(async () => {
      // Check localStorage for unprocessed assessments
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith('skillAssessment_')) {
          const data = JSON.parse(localStorage.getItem(key) || '{}');
          if (data.assessments && !data.processed) {
            this.errorHandler.logInfo('Found pending assessment result', { key });
            await this.handleDirectAssessment({
              detail: { assessmentData: data.assessments }
            });
          }
        }
      }
    }, 'Checking pending results');
  }

  /**
   * Process assessment results and populate dashboard
   *
   * @async
   * @private
   * @param {Object} assessmentData - Assessment scores and data
   * @param {Object} pathData - Generated path data
   */
  async processAssessmentResults(assessmentData, pathData) {
    return this.errorHandler.safeExecute(async () => {
      this.processingState.isProcessing = true;
      this.currentAssessment = { assessmentData, pathData };

      // Analyze assessment scores
      const analysisResults = this.analyzeAssessmentScores(assessmentData);

      // Generate learning path recommendations
      const recommendations = this.generatePathRecommendations(analysisResults);

      // Populate dashboard with recommendations
      await this.populateDashboard(recommendations);

      // Notify coach system if available
      await this.notifyCoachSystem(assessmentData, recommendations);

      // Update processing state
      this.processingState = {
        isProcessing: false,
        processedAt: new Date().toISOString(),
        results: recommendations
      };

      // Dispatch completion event
      const event = new CustomEvent('assessmentResultsProcessed', {
        detail: {
          assessmentData,
          pathData,
          recommendations,
          processor: this
        }
      });
      document.dispatchEvent(event);

      this.errorHandler.logInfo('Assessment results processed successfully', {
        recommendations: recommendations.summary
      });

    }, 'Processing assessment results');
  }

  /**
   * Analyze assessment scores to determine skill levels
   *
   * @private
   * @param {Object} assessmentData - Raw assessment data
   * @returns {Object} Analysis results with skill levels and priorities
   */
  analyzeAssessmentScores(assessmentData) {
    // Input validation
    if (!assessmentData || typeof assessmentData !== 'object') {
      this.errorHandler.logWarning('Invalid assessment data provided', { assessmentData });
      return {
        skillLevels: {},
        overallLevel: 'intermediate',
        priorityAreas: [],
        strengthAreas: [],
        improvementAreas: [],
        overallScore: 3.0
      };
    }

    const analysis = {
      skillLevels: {},
      overallLevel: 'intermediate',
      priorityAreas: [],
      strengthAreas: [],
      improvementAreas: []
    };

    // Calculate average scores per skill category
    Object.entries(assessmentData).forEach(([skillArea, responses]) => {
      // Validate responses
      if (!responses || typeof responses !== 'object') {
        this.errorHandler.logWarning(`Invalid responses for skill area: ${skillArea}`);
        return;
      }

      const scores = Object.values(responses).map(response => {
        // Extract numeric score from response (assuming 1-5 scale)
        if (typeof response === 'number') {return response;}
        if (typeof response === 'string') {
          const match = response.match(/(\d+)/);
          return match ? parseInt(match[1], 10) : 3; // Default to middle score
        }
        return 3;
      });

      if (scores.length === 0) {
        this.errorHandler.logWarning(`No valid scores found for skill area: ${skillArea}`);
        return;
      }

      const averageScore = scores.reduce((sum, score) => sum + score, 0) / scores.length;
      analysis.skillLevels[skillArea] = {
        averageScore,
        level: this.determineSkillLevel(averageScore),
        scores
      };

      // Categorize areas based on scores
      if (averageScore >= 4) {
        analysis.strengthAreas.push(skillArea);
      } else if (averageScore < 2) {
        analysis.improvementAreas.push(skillArea);
      } else {
        analysis.priorityAreas.push(skillArea);
      }
    });

    // Determine overall level
    const skillLevelsArray = Object.values(analysis.skillLevels);
    const overallScore = skillLevelsArray.length > 0
      ? skillLevelsArray.reduce((sum, skill) => sum + skill.averageScore, 0) / skillLevelsArray.length
      : 3.0;

    analysis.overallLevel = this.determineSkillLevel(overallScore);
    analysis.overallScore = overallScore;

    return analysis;
  }

  /**
   * Determine skill level from numeric score
   *
   * @private
   * @param {number} score - Numeric score (1-5 scale)
   * @returns {string} Skill level (beginner, intermediate, advanced, expert)
   */
  determineSkillLevel(score) {
    if (score >= SCORE_THRESHOLDS.expert.min) return SKILL_LEVELS.EXPERT;
    if (score >= SCORE_THRESHOLDS.advanced.min) return SKILL_LEVELS.ADVANCED;
    if (score >= SCORE_THRESHOLDS.intermediate.min) return SKILL_LEVELS.INTERMEDIATE;
    return SKILL_LEVELS.BEGINNER;
  }

  /**
   * Generate learning path recommendations based on analysis
   *
   * @private
   * @param {Object} analysisResults - Assessment analysis results
   * @returns {Object} Path recommendations with items to populate
   */
  generatePathRecommendations(analysisResults) {
    const recommendations = {
      summary: {
        overallLevel: analysisResults.overallLevel,
        totalItems: 0,
        priorityCount: 0
      },
      itemsToAdd: [],
      focusAreas: [],
      estimatedDuration: { hours: 0, weeks: 0 }
    };

    // Generate recommendations for each skill area
    [...analysisResults.improvementAreas, ...analysisResults.priorityAreas].forEach(skillArea => {
      const skillLevel = analysisResults.skillLevels[skillArea];
      const pathItems = this.pathMappings[skillLevel.level]?.[skillArea] || [];

      pathItems.forEach((itemPath, _index) => {
        const recommendation = {
          itemPath,
          skillArea,
          level: skillLevel.level,
          priority: analysisResults.improvementAreas.includes(skillArea) ? 'high' : 'medium',
          order: recommendations.itemsToAdd.length + 1,
          estimatedTime: this.estimateItemTime(skillLevel.level),
          reason: this.generateRecommendationReason(skillArea, skillLevel)
        };

        recommendations.itemsToAdd.push(recommendation);
      });

      recommendations.focusAreas.push({
        area: skillArea,
        level: skillLevel.level,
        score: skillLevel.averageScore,
        itemCount: pathItems.length
      });
    });

    // Calculate totals
    recommendations.summary.totalItems = recommendations.itemsToAdd.length;
    recommendations.summary.priorityCount = recommendations.itemsToAdd
      .filter(item => item.priority === 'high').length;

    // Estimate duration
    const totalHours = recommendations.itemsToAdd
      .reduce((sum, item) => sum + item.estimatedTime, 0);
    recommendations.estimatedDuration = {
      hours: totalHours,
      weeks: Math.ceil(totalHours / 10) // Assuming 10 hours per week
    };

    return recommendations;
  }

  /**
   * Estimate time required for learning item based on level
   *
   * @private
   * @param {string} level - Skill level (beginner, intermediate, advanced)
   * @returns {number} Estimated hours
   */
  estimateItemTime(level) {
    const timeEstimates = {
      beginner: 4, // 4 hours for beginner items
      intermediate: 6, // 6 hours for intermediate items
      advanced: 8 // 8 hours for advanced items
    };
    return timeEstimates[level] || 5;
  }

  /**
   * Generate recommendation reason text
   *
   * @private
   * @param {string} skillArea - Skill area name
   * @param {Object} skillLevel - Skill level data
   * @returns {string} Recommendation reason
   */
  generateRecommendationReason(skillArea, skillLevel) {
    const areaNames = {
      'ai-assisted-engineering': 'AI-Assisted Development',
      'edge-deployment': 'Edge Deployment',
      'project-planning': 'Project Planning',
      'system-troubleshooting': 'System Troubleshooting'
    };

    const areaName = areaNames[skillArea] || skillArea;
    const score = skillLevel.averageScore.toFixed(1);

    if (skillLevel.level === 'beginner') {
      return `Based on your ${areaName} score (${score}/5), starting with foundational concepts will build a strong base.`;
    } else if (skillLevel.level === 'intermediate') {
      return `Your ${areaName} score (${score}/5) shows good fundamentals. These items will advance your skills.`;
    } else {
      return `With your advanced ${areaName} score (${score}/5), these items will help you master expert-level concepts.`;
    }
  }

  /**
   * Create path data structure from recommendations
   *
   * @private
   * @param {Object} recommendations - Path recommendations
   * @param {Object} assessmentData - Original assessment data
   * @returns {Object} Path data structure
   */
  createPathDataFromRecommendations(recommendations, assessmentData) {
    const timestamp = new Date().toISOString();
    const pathId = `assessment-path-${Date.now()}`;

    return {
      metadata: {
        version: "1.0.0",
        learningPathId: pathId,
        learningPathTitle: `Personalized Learning Path - ${recommendations.summary.overallLevel}`,
        pathType: recommendations.summary.overallLevel,
        source: "assessment-processor",
        fileType: "learning-path-progress",
        sessionId: `assessment-session-${Date.now()}`,
        lastUpdated: timestamp,
        assessmentData
      },
      timestamp,
      learningPath: {
        title: `Personalized Learning Path - ${recommendations.summary.overallLevel}`,
        description: `Customized learning path based on your skill assessment results. Focus areas: ${recommendations.focusAreas.map(f => f.area).join(', ')}.`,
        categories: recommendations.focusAreas.map(f => f.area),
        estimatedDuration: recommendations.estimatedDuration,
        difficultyLevel: recommendations.summary.overallLevel,
        items: recommendations.itemsToAdd.map(item => ({
          id: item.itemPath.replace(/[/-]/g, '_'),
          type: 'learning-item',
          title: item.itemPath.split('/').pop().replace(/-/g, ' '),
          category: item.skillArea,
          order: item.order,
          estimatedTime: item.estimatedTime,
          difficulty: item.level,
          isRequired: item.priority === 'high',
          path: item.itemPath,
          reason: item.reason
        }))
      }
    };
  }

  /**
   * Populate dashboard with learning path recommendations
   *
   * @async
   * @private
   * @param {Object} recommendations - Path recommendations
   */
  async populateDashboard(recommendations) {
    return this.errorHandler.safeExecute(async () => {
      this.errorHandler.logInfo('Populating dashboard with recommendations', {
        itemCount: recommendations.itemsToAdd.length
      });

      // Wait for DOM to be ready
      await this.domUtils.waitForElement('.learning-path-item');

      let populatedCount = 0;
      let notFoundCount = 0;

      // Process each recommendation
      for (const recommendation of recommendations.itemsToAdd) {
        try {
          const success = await this.populateItem(recommendation);
          if (success) {
            populatedCount++;
          } else {
            notFoundCount++;
          }
        } catch (_error) {
          this.errorHandler.logError('Error populating item', _error, { recommendation });
          notFoundCount++;
        }
      }

      // Show user notification
      this.showPopulationNotification(populatedCount, notFoundCount, recommendations);

      this.errorHandler.logInfo('Dashboard population completed', {
        populated: populatedCount,
        notFound: notFoundCount,
        total: recommendations.itemsToAdd.length
      });

    }, 'Populating dashboard');
  }

  /**
   * Populate individual learning item on dashboard
   *
   * @async
   * @private
   * @param {Object} recommendation - Item recommendation
   * @returns {boolean} Success status
   */
  async populateItem(recommendation) {
    return this.errorHandler.safeExecute(async () => {
      // Find the item on the dashboard by various selectors
      const selectors = [
        `[data-path="${recommendation.itemPath}"]`,
        `[href*="${recommendation.itemPath}"]`,
        `[data-id*="${recommendation.itemPath.split('/').pop()}"]`,
        `.learning-path-item:has(a[href*="${recommendation.itemPath.split('/').pop()}"])`
      ];

      let itemElement = null;
      for (const selector of selectors) {
        try {
          itemElement = document.querySelector(selector);
          if (itemElement) {break;}
        } catch {
          // Continue to next selector if this one fails
        }
      }

      // If not found by exact match, try partial text matching
      if (!itemElement) {
        const pathPart = recommendation.itemPath.split('/').pop().replace(/-/g, ' ');
        const allItems = document.querySelectorAll('.learning-path-item');

        for (const item of allItems) {
          const text = item.textContent.toLowerCase();
          if (text.includes(pathPart.toLowerCase())) {
            itemElement = item;
            break;
          }
        }
      }

      if (!itemElement) {
        this.errorHandler.logWarning('Learning item not found on dashboard', {
          itemPath: recommendation.itemPath
        });
        return false;
      }

      // Find the path checkbox (📚 Add to Path)
      const pathCheckbox = itemElement.querySelector(this.dashboardSelectors.pathCheckbox);
      if (pathCheckbox && !pathCheckbox.checked) {
        // Check the path checkbox to add to learning path
        pathCheckbox.checked = true;

        // Trigger change event to update any listeners
        const changeEvent = new Event('change', { bubbles: true });
        pathCheckbox.dispatchEvent(changeEvent);

        // Add visual indicator for auto-population
        this.addPopulationIndicator(itemElement, recommendation);
      }

      return true;
    }, 'Populating individual item', false);
  }

  /**
   * Add visual indicator for auto-populated items
   *
   * @private
   * @param {Element} itemElement - Learning item element
   * @param {Object} recommendation - Item recommendation
   */
  addPopulationIndicator(itemElement, recommendation) {
    // Add a subtle indicator that this was auto-populated
    const indicator = document.createElement('div');
    indicator.className = 'assessment-populated-indicator';
    indicator.innerHTML = `
      <span class="indicator-icon">🎯</span>
      <span class="indicator-text">Added from assessment</span>
      <div class="indicator-reason">${recommendation.reason}</div>
    `;

    // Add after checkbox container if available
    const checkboxContainer = itemElement.querySelector('.dual-checkbox-container');
    if (checkboxContainer) {
      checkboxContainer.appendChild(indicator);
    } else {
      itemElement.appendChild(indicator);
    }

    // Add CSS class for styling
    itemElement.classList.add('assessment-populated');
  }

  /**
   * Show notification about dashboard population
   *
   * @private
   * @param {number} populatedCount - Number of items populated
   * @param {number} notFoundCount - Number of items not found
   * @param {Object} recommendations - All recommendations
   */
  showPopulationNotification(populatedCount, notFoundCount, recommendations) {
    const notification = document.createElement('div');
    notification.className = 'assessment-population-notification';
    notification.innerHTML = `
      <div class="notification-header">
        <span class="notification-icon">🎯</span>
        <h4>Learning Path Updated from Assessment</h4>
      </div>
      <div class="notification-content">
        <p><strong>${populatedCount} items</strong> added to your learning path based on your assessment results.</p>
        ${notFoundCount > 0 ? `<p class="warning">${notFoundCount} recommended items were not found on this page.</p>` : ''}
        <div class="focus-areas">
          <strong>Focus Areas:</strong> ${recommendations.focusAreas.map(f => f.area.replace(/-/g, ' ')).join(', ')}
        </div>
        <div class="estimated-time">
          <strong>Estimated Duration:</strong> ${recommendations.estimatedDuration.hours} hours (${recommendations.estimatedDuration.weeks} weeks)
        </div>
      </div>
      <button class="notification-close" onclick="this.parentElement.remove()">×</button>
    `;

    // Add to page (look for existing notification container or create one)
    let container = document.querySelector('.learning-path-notifications');
    if (!container) {
      container = document.createElement('div');
      container.className = 'learning-path-notifications';
      document.body.appendChild(container);
    }

    container.appendChild(notification);

    // Auto-remove after 10 seconds
    setTimeout(() => {
      if (notification.parentElement) {
        notification.remove();
      }
    }, 10000);
  }

  /**
   * Notify coach system of assessment completion
   *
   * @async
   * @private
   * @param {Object} assessmentData - Assessment data
   * @param {Object} recommendations - Generated recommendations
   */
  async notifyCoachSystem(assessmentData, recommendations) {
    return this.errorHandler.safeExecute(async () => {
      // Check if coach system is available
      const coachEvent = new CustomEvent('assessmentResultsForCoach', {
        detail: {
          assessmentData,
          recommendations,
          timestamp: new Date().toISOString(),
          source: 'assessment-result-processor'
        }
      });

      document.dispatchEvent(coachEvent);

      // Also store for coach access
      const coachData = {
        assessmentScores: assessmentData,
        recommendations: recommendations.summary,
        focusAreas: recommendations.focusAreas,
        timestamp: new Date().toISOString()
      };

      localStorage.setItem('latestAssessmentForCoach', JSON.stringify(coachData));

      this.errorHandler.logInfo('Coach system notified of assessment completion');

    }, 'Notifying coach system');
  }

  /**
   * Get current processing state
   *
   * @public
   * @returns {Object} Current processing state
   */
  getProcessingState() {
    return {
      ...this.processingState,
      isInitialized: this.isInitialized,
      currentAssessment: this.currentAssessment ? {
        hasAssessmentData: !!this.currentAssessment.assessmentData,
        hasPathData: !!this.currentAssessment.pathData
      } : null
    };
  }

  /**
   * Manual processing trigger for testing
   *
   * @async
   * @public
   * @param {Object} assessmentData - Assessment data to process
   * @returns {Object} Processing results
   */
  async processManualAssessment(assessmentData) {
    return this.errorHandler.safeExecute(async () => {
      const analysisResults = this.analyzeAssessmentScores(assessmentData);
      const recommendations = this.generatePathRecommendations(analysisResults);
      const pathData = this.createPathDataFromRecommendations(recommendations, assessmentData);

      await this.processAssessmentResults(assessmentData, pathData);

      return {
        analysis: analysisResults,
        recommendations,
        pathData
      };
    }, 'Processing manual assessment');
  }
}

// Export for use in other modules
export default AssessmentResultProcessor;
