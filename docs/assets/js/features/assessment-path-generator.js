/**
 * Assessment-Driven Path Generator
 * Creates personalized learning paths based on user assessment results
 *
 * @description This module provides a comprehensive skill assessment interface
 * that generates personalized learning paths based on user responses across
 * multiple skill categories including ADR creation, AI-assisted engineering,
 * edge deployment, project planning, prompt engineering, and task planning.
 *
 * @version 1.0.0
 * @since 2025-01-01
 */

import { DOMUtils } from '../utils/dom-utils.js';
import { ErrorHandler } from '../core/error-handler.js';
import { LEARNING_PATH_CONSTANTS } from '../core/learning-path-constants.js';

const { DIFFICULTY, RECOMMENDATION_RULES } = LEARNING_PATH_CONSTANTS;

/**
 * Assessment-Driven Path Generator Class
 * Analyzes user skills and creates tailored learning paths
 *
 * @class AssessmentPathGenerator
 * @description Provides a modal interface for skill assessment and path generation
 */
export class AssessmentPathGenerator {
  /**
   * Create an AssessmentPathGenerator instance
   *
   * @param {Object} [dependencies={}] - Dependency injection object
   * @param {DOMUtils} [dependencies.domUtils] - DOM utility instance
   * @param {ErrorHandler} [dependencies.errorHandler] - Error handler instance
   */
  constructor(dependencies = {}) {
    this.domUtils = dependencies.domUtils || new DOMUtils();
    this.errorHandler = dependencies.errorHandler || new ErrorHandler('assessment-path-generator');

    // Assessment state
    this.assessmentData = null;
    this.skillAssessments = {};
    this.pathRecommendations = {};
    this.currentCategoryIndex = 0;

    // UI elements
    this.containerElement = null;
    this.modalElement = null;
    this.isVisible = false;

    // Configuration
    this.skillCategories = this.initializeSkillCategories();
    this.pathTemplates = this.initializePathTemplates();
    this.storageKey = 'assessmentPathGenerator';

    // State tracking
    this.isInitialized = false;
    this.abortController = null;
    this.currentPath = null;

    this.initPromise = null;
  }

  /**
   * Initialize skill categories configuration
   *
   * @private
   * @returns {Object} Skill categories configuration
   */
  initializeSkillCategories() {
    return {
      'adr-creation': {
        name: 'Architecture Decision Records',
        description: 'Create and maintain architectural decision documentation',
        levels: [DIFFICULTY.BEGINNER, DIFFICULTY.INTERMEDIATE, DIFFICULTY.ADVANCED, DIFFICULTY.EXPERT],
        assessmentQuestions: [
          'How familiar are you with documenting architectural decisions?',
          'Have you used ADR templates or frameworks before?',
          'Do you regularly review and update architectural decisions?'
        ]
      },
      'ai-assisted-engineering': {
        name: 'AI-Assisted Development',
        description: 'Leverage AI tools for software development',
        levels: [DIFFICULTY.BEGINNER, DIFFICULTY.INTERMEDIATE, DIFFICULTY.ADVANCED, DIFFICULTY.EXPERT],
        assessmentQuestions: [
          'How often do you use AI coding assistants?',
          'Are you familiar with prompt engineering for code generation?',
          'Do you know how to debug AI-generated code effectively?'
        ]
      },
      'edge-deployment': {
        name: 'Edge Computing & Deployment',
        description: 'Deploy and manage edge computing solutions',
        levels: [DIFFICULTY.BEGINNER, DIFFICULTY.INTERMEDIATE, DIFFICULTY.ADVANCED, DIFFICULTY.EXPERT],
        assessmentQuestions: [
          'How experienced are you with containerization technologies?',
          'Have you deployed applications to edge devices?',
          'Are you familiar with IoT integration patterns?'
        ]
      },
      'project-planning': {
        name: 'Technical Project Planning',
        description: 'Plan and execute technical projects effectively',
        levels: [DIFFICULTY.BEGINNER, DIFFICULTY.INTERMEDIATE, DIFFICULTY.ADVANCED, DIFFICULTY.EXPERT],
        assessmentQuestions: [
          'How do you typically break down complex technical projects?',
          'Are you familiar with agile planning methodologies?',
          'Do you regularly track and adjust project milestones?'
        ]
      },
      'prompt-engineering': {
        name: 'AI Prompt Engineering',
        description: 'Design effective prompts for AI systems',
        levels: [DIFFICULTY.BEGINNER, DIFFICULTY.INTERMEDIATE, DIFFICULTY.ADVANCED, DIFFICULTY.EXPERT],
        assessmentQuestions: [
          'How comfortable are you with designing AI prompts?',
          'Do you understand context optimization techniques?',
          'Have you created complex multi-step prompting workflows?'
        ]
      },
      'task-planning': {
        name: 'Technical Task Planning',
        description: 'Decompose and plan technical tasks',
        levels: [DIFFICULTY.BEGINNER, DIFFICULTY.INTERMEDIATE, DIFFICULTY.ADVANCED, DIFFICULTY.EXPERT],
        assessmentQuestions: [
          'How do you approach breaking down complex technical tasks?',
          'Are you familiar with dependency mapping techniques?',
          'Do you regularly use task planning frameworks or tools?'
        ]
      },
      'data-analytics': {
        name: 'Data & Analytics Integration',
        description: 'Microsoft Fabric, Real-Time Intelligence, KQL, data pipelines',
        levels: [DIFFICULTY.BEGINNER, DIFFICULTY.INTERMEDIATE, DIFFICULTY.ADVANCED, DIFFICULTY.EXPERT],
        relatedTags: ['fabric', 'kql', 'real-time-intelligence', 'data-pipelines', 'eventstream'],
        assessmentQuestions: [
          'How experienced are you with designing data pipelines and ETL processes?',
          'Are you proficient with analytics tools like KQL, Power BI, and real-time dashboards?',
          'Can you implement edge-to-cloud data integration patterns including Fabric?'
        ],
        pathMapping: {
          [DIFFICULTY.BEGINNER]: ['100-level katas'],
          [DIFFICULTY.INTERMEDIATE]: ['200-level katas'],
          [DIFFICULTY.ADVANCED]: ['300-400 level katas']
        }
      },
      'system-troubleshooting': {
        name: 'System Troubleshooting & Debugging',
        description: 'Diagnose and resolve technical issues effectively',
        levels: [DIFFICULTY.BEGINNER, DIFFICULTY.INTERMEDIATE, DIFFICULTY.ADVANCED, DIFFICULTY.EXPERT],
        assessmentQuestions: [
          'How comfortable are you debugging complex technical issues?',
          'Do you use systematic approaches to troubleshooting?',
          'Can you diagnose and resolve distributed system problems?'
        ],
        pathMapping: {
          [DIFFICULTY.BEGINNER]: ['100-level katas'],
          [DIFFICULTY.INTERMEDIATE]: ['200-level katas'],
          [DIFFICULTY.ADVANCED]: ['300-400 level katas']
        }
      }
    };
  }

  /**
   * Initialize path templates configuration
   *
   * @private
   * @returns {Object} Path templates configuration
   */
  initializePathTemplates() {
    return {
      [DIFFICULTY.BEGINNER]: {
        name: 'Foundation',
        description: 'Build core skills across essential areas',
        targetLevels: [DIFFICULTY.BEGINNER, DIFFICULTY.INTERMEDIATE],
        recommendedHours: { min: 15, max: 25 },
        focusAreas: ['fundamentals', 'hands-on-practice', 'guided-learning']
      },
      [DIFFICULTY.INTERMEDIATE]: {
        name: 'Intermediate',
        description: 'Enhance intermediate skills and learn advanced techniques',
        targetLevels: [DIFFICULTY.INTERMEDIATE, DIFFICULTY.ADVANCED],
        recommendedHours: { min: 20, max: 35 },
        focusAreas: ['intermediate-techniques', 'practical-application', 'peer-learning']
      },
      [DIFFICULTY.ADVANCED]: {
        name: 'Advanced',
        description: 'Master advanced concepts and lead technical initiatives',
        targetLevels: [DIFFICULTY.ADVANCED, DIFFICULTY.EXPERT],
        recommendedHours: { min: 25, max: 40 },
        focusAreas: ['advanced-patterns', 'leadership', 'innovation']
      },
      [DIFFICULTY.EXPERT]: {
        name: 'Expert',
        description: 'Lead technical excellence and innovation',
        targetLevels: [DIFFICULTY.EXPERT],
        recommendedHours: { min: 30, max: 50 },
        focusAreas: ['thought-leadership', 'innovation', 'mentorship']
      }
    };
  }

  /**
   * Initialize the assessment path generator
   *
   * @async
   * @returns {Promise<void>} Initialization promise
   * @throws {Error} If initialization fails
   */
  async initialize() {
    if (this.initPromise) {
      return this.initPromise;
    }

    this.initPromise = this.errorHandler.safeExecute(async () => {
      await this.performInitialization();
    }, 'AssessmentPathGenerator initialization');

    return this.initPromise;
  }

  /**
   * Perform the actual initialization
   *
   * @private
   * @async
   * @returns {Promise<void>}
   */
  async performInitialization() {
    this.createAssessmentInterface();
    await this.loadExistingAssessments();
    this.isInitialized = true;
    this.abortController = new AbortController();
    return true;
  }

  /**
   * Create the assessment interface UI
   *
   * @private
   */
  createAssessmentInterface() {
    this.createModal();
    this.createContainer();
    this.attachEventListeners();

    // Safely append modal to document.body if it exists
    if (typeof document !== 'undefined' && document.body) {
      document.body.appendChild(this.modalElement);
    }
  }

  /**
   * Create the modal overlay
   *
   * @private
   */
  createModal() {
    this.modalElement = this.domUtils.createElement('div', {
      className: 'assessment-modal'
    });
  }

  /**
   * Create the main container
   *
   * @private
   */
  createContainer() {
    this.containerElement = this.domUtils.createElement('div', {
      className: 'assessment-container'
    });

    const header = this.createHeader();
    const content = this.createContentArea();
    const footer = this.createFooter();

    this.containerElement.appendChild(header);
    this.containerElement.appendChild(content);
    this.containerElement.appendChild(footer);
    this.modalElement.appendChild(this.containerElement);
  }

  /**
   * Create header section
   *
   * @private
   * @returns {HTMLElement} Header element
   */
  createHeader() {
    const header = this.domUtils.createElement('div', {
      className: 'assessment-header'
    });

    const title = this.domUtils.createElement('h2', {
      textContent: 'Skill Assessment & Path Generator'
    });

    const closeBtn = this.domUtils.createElement('button', {
      innerHTML: '×',
      className: 'close-btn'
    });

    closeBtn.addEventListener('click', () => this.hide());

    header.appendChild(title);
    header.appendChild(closeBtn);

    return header;
  }

  /**
   * Create content area
   *
   * @private
   * @returns {HTMLElement} Content element
   */
  createContentArea() {
    const content = this.domUtils.createElement('div', {
      className: 'assessment-content'
    });

    this.showIntroduction(content);
    return content;
  }

  /**
   * Show introduction screen
   *
   * @private
   * @param {HTMLElement} container - Container element
   */
  showIntroduction(container) {
    container.innerHTML = `
      <div class="assessment-intro">
        <div class="intro-header">
          <div class="intro-icon">🎯</div>
          <h3 class="intro-title">Personalized Learning Path Generator</h3>
          <p class="intro-description">
            Take a quick skill assessment to receive a customized learning path that matches your current experience level and learning goals.
          </p>
        </div>

        <div class="assessment-benefits">
          <div class="benefit-item">
            <div class="benefit-icon">📊</div>
            <h4 class="benefit-title">Skill Assessment</h4>
            <p class="benefit-description">Evaluate your current skills across key technical areas</p>
          </div>

          <div class="benefit-item">
            <div class="benefit-icon">🛤️</div>
            <h4 class="benefit-title">Custom Path</h4>
            <p class="benefit-description">Get a personalized learning path based on your assessment</p>
          </div>

          <div class="benefit-item">
            <div class="benefit-icon">🎯</div>
            <h4 class="benefit-title">Targeted Learning</h4>
            <p class="benefit-description">Focus on areas that matter most for your growth</p>
          </div>
        </div>

        <div class="start-button-container">
          <button id="start-assessment-btn" class="btn btn-primary">
            Start Assessment
          </button>
        </div>
      </div>
    `;

    const startBtn = container.querySelector('#start-assessment-btn');
    if (startBtn) {
      startBtn.addEventListener('click', () => this.startAssessment());
    }
  }

  /**
   * Create footer section
   *
   * @private
   * @returns {HTMLElement} Footer element
   */
  createFooter() {
    const footer = this.domUtils.createElement('div', {
      className: 'assessment-footer'
    });

    const backBtn = this.domUtils.createElement('button', {
      textContent: 'Back',
      className: 'btn btn-secondary'
    });

    const nextBtn = this.domUtils.createElement('button', {
      textContent: 'Next',
      className: 'btn btn-primary'
    });

    backBtn.addEventListener('click', () => this.goBack());
    nextBtn.addEventListener('click', () => this.goNext());

    footer.appendChild(backBtn);
    footer.appendChild(nextBtn);

    return footer;
  }

  /**
   * Attach event listeners
   *
   * @private
   */
  attachEventListeners() {
    this.modalElement.addEventListener('click', (e) => {
      if (e.target === this.modalElement) {
        this.hide();
      }
    });
  }

  /**
   * Start the skill assessment
   *
   * @public
   */
  startAssessment() {
    this.currentCategoryIndex = 0;
    this.skillAssessments = {};

    const content = this.containerElement.querySelector('.assessment-content');
    this.showCategoryAssessment(content);
  }

  /**
   * Show category assessment interface
   *
   * @private
   * @param {HTMLElement} container - Container element
   */
  showCategoryAssessment(container) {
    const categories = Object.keys(this.skillCategories);
    const currentCategory = categories[this.currentCategoryIndex];
    const categoryData = this.skillCategories[currentCategory];

    const progressHtml = this.createProgressIndicator(categories.length);
    const categoryHtml = this.createCategoryInterface(categoryData);

    container.innerHTML = `
      <div class="category-assessment">
        ${progressHtml}
        ${categoryHtml}
      </div>
    `;

    this.setupRadioButtonStyling(container);
  }

  /**
   * Create progress indicator
   *
   * @private
   * @param {number} totalCategories - Total number of categories
   * @returns {string} Progress HTML
   */
  createProgressIndicator(totalCategories) {
    const progressPercentage = ((this.currentCategoryIndex + 1) / totalCategories) * 100;

    return `
      <div class="assessment-progress">
        <div class="progress-header">
          <span class="progress-label">Assessment Progress</span>
          <span class="progress-count">${this.currentCategoryIndex + 1} of ${totalCategories}</span>
        </div>
        <div class="progress-bar">
          <div class="progress-bar-fill" style="width: ${progressPercentage}%;"></div>
        </div>
      </div>
    `;
  }

  /**
   * Create category interface
   *
   * @private
   * @param {Object} categoryData - Category configuration
   * @returns {string} Category HTML
   */
  createCategoryInterface(categoryData) {
    const skillLevelsHtml = categoryData.levels.map(level => `
      <label class="skill-level-option">
        <input type="radio" name="skill-level" value="${level}">
        <div class="skill-level-title">${level}</div>
        <div class="skill-level-desc">${this.getSkillLevelDescription(level)}</div>
      </label>
    `).join('');

    const questionsHtml = categoryData.assessmentQuestions.map((question, _index) => `
      <div class="question-item">
        <div class="question-text">${question}</div>
        <div class="rating-scale">
          ${[1, 2, 3, 4, 5].map(rating => `
            <label class="rating-option">
              <input type="radio" name="question-${_index}" value="${rating}">
              <span>${rating}</span>
            </label>
          `).join('')}
        </div>
      </div>
    `).join('');

    return `
      <div class="category-header">
        <h3 class="category-title">${categoryData.name}</h3>
        <p class="category-description">${categoryData.description}</p>
      </div>

      <div class="skill-level-selection">
        <h4>Current Skill Level</h4>
        <div class="skill-levels">
          ${skillLevelsHtml}
        </div>
      </div>

      <div class="assessment-questions">
        <h4>Self-Assessment Questions</h4>
        <p>
          Rate yourself on the following aspects (1 = No experience, 5 = Expert level):
        </p>
        ${questionsHtml}
      </div>
    `;
  }

  /**
   * Get skill level description
   *
   * @private
   * @param {string} level - Skill level
   * @returns {string} Description
   */
  getSkillLevelDescription(level) {
    const descriptions = {
      'beginner': 'Little to no experience',
      'intermediate': 'Some experience, learning basics',
      'advanced': 'Comfortable with most concepts',
      'expert': 'Advanced skills, can teach others'
    };
    return descriptions[level] || '';
  }

  /**
   * Setup radio button styling
   *
   * @private
   * @param {HTMLElement} container - Container element
   */
  setupRadioButtonStyling(container) {
    const options = container.querySelectorAll('.skill-level-option');

    options.forEach(option => {
      const radio = option.querySelector('input[type="radio"]');

      option.addEventListener('mouseenter', () => {
        if (!radio.checked) {
          option.classList.add('hover');
        }
      });

      option.addEventListener('mouseleave', () => {
        if (!radio.checked) {
          option.classList.remove('hover');
        }
      });

      radio.addEventListener('change', () => {
        options.forEach(opt => {
          opt.classList.remove('selected', 'hover');
        });

        option.classList.add('selected');
      });
    });
  }

  /**
   * Go to previous step
   *
   * @public
   */
  goBack() {
    if (this.currentCategoryIndex > 0) {
      this.currentCategoryIndex--;
      const content = this.containerElement.querySelector('.assessment-content');
      this.showCategoryAssessment(content);
    } else {
      const content = this.containerElement.querySelector('.assessment-content');
      this.showIntroduction(content);
    }
  }

  /**
   * Go to next step
   *
   * @public
   */
  goNext() {
    if (!this.validateCurrentAssessment()) {
      // eslint-disable-next-line no-alert
      alert('Please complete all required fields before continuing.');
      return;
    }

    this.saveCurrentAssessment();

    const categories = Object.keys(this.skillCategories);

    if (this.currentCategoryIndex < categories.length - 1) {
      this.currentCategoryIndex++;
      const content = this.containerElement.querySelector('.assessment-content');
      this.showCategoryAssessment(content);
    } else {
      this.generateLearningPath();
    }
  }

  /**
   * Validate current assessment form
   *
   * @private
   * @returns {boolean} Validation result
   */
  validateCurrentAssessment() {
    const container = this.containerElement.querySelector('.assessment-content');

    const skillLevel = container.querySelector('input[name="skill-level"]:checked');
    if (!skillLevel) {return false;}

    const questions = container.querySelectorAll('.question-item');
    for (let i = 0; i < questions.length; i++) {
      const answered = container.querySelector(`input[name="question-${i}"]:checked`);
      if (!answered) {return false;}
    }

    return true;
  }

  /**
   * Save current assessment data
   *
   * @private
   */
  saveCurrentAssessment() {
    const categories = Object.keys(this.skillCategories);
    const currentCategory = categories[this.currentCategoryIndex];
    const container = this.containerElement.querySelector('.assessment-content');

    const skillLevel = container.querySelector('input[name="skill-level"]:checked').value;

    const questions = container.querySelectorAll('.question-item');
    const ratings = [];
    for (let i = 0; i < questions.length; i++) {
      const rating = container.querySelector(`input[name="question-${i}"]:checked`).value;
      ratings.push(parseInt(rating));
    }

    const averageRating = ratings.reduce((sum, rating) => sum + rating, 0) / ratings.length;

    this.skillAssessments[currentCategory] = {
      skillLevel,
      ratings,
      averageRating,
      assessedAt: new Date().toISOString()
    };
  }

  /**
   * Generate learning path based on assessments
   *
   * @async
   * @private
   */
  async generateLearningPath() {
    const content = this.containerElement.querySelector('.assessment-content');

    // Show loading state
    content.innerHTML = `
      <div class="loading-container">
        <div class="loading-icon">⚡</div>
        <h3 class="loading-title">Generating Your Personalized Learning Path...</h3>
        <p class="loading-description">Analyzing your assessment results and creating recommendations</p>
        <div class="loading-progress">
          <div class="loading-bar-container">
            <div class="loading-bar"></div>
          </div>
        </div>
      </div>
    `;

    // Simulate processing time
    await new Promise(resolve => setTimeout(resolve, 2000));

    const pathRecommendations = this.analyzeAssessmentResults();
    this.showPathRecommendations(content, pathRecommendations);
  }

  /**
   * Analyze assessment results and generate path recommendations
   *
   * @private
   * @returns {Object} Path recommendations
   */
  analyzeAssessmentResults() {
    const assessments = this.skillAssessments;
    const recommendations = {
      overallLevel: this.calculateOverallLevel(assessments),
      recommendedPathType: null,
      priorityAreas: [],
      suggestedItems: [],
      estimatedDuration: { hours: 0, weeks: 0 },
      personalizedMessage: ''
    };

    // Determine recommended path type
    const levelCounts = { beginner: 0, intermediate: 0, advanced: 0, expert: 0 };
    Object.values(assessments).forEach(assessment => {
      levelCounts[assessment.skillLevel]++;
    });

    if (levelCounts.beginner >= RECOMMENDATION_RULES.foundation.minNovice || (levelCounts.beginner + levelCounts.intermediate) >= RECOMMENDATION_RULES.foundation.minNoviceAndCompetent) {
      recommendations.recommendedPathType = DIFFICULTY.BEGINNER;
    } else if (levelCounts.advanced >= RECOMMENDATION_RULES.intermediate.minProficient || levelCounts.intermediate >= RECOMMENDATION_RULES.intermediate.minCompetent) {
      recommendations.recommendedPathType = DIFFICULTY.INTERMEDIATE;
    } else {
      recommendations.recommendedPathType = DIFFICULTY.ADVANCED;
    }

    // Identify priority areas
    const categoryScores = Object.entries(assessments).map(([category, data]) => ({
      category,
      score: (data.averageRating / 5) * 0.7 + (this.getLevelScore(data.skillLevel) / 4) * 0.3,
      ...data
    })).sort((a, b) => a.score - b.score);

    recommendations.priorityAreas = categoryScores.slice(0, 3).map(item => item.category);
    recommendations.suggestedItems = this.generateSuggestedItems(categoryScores, recommendations.recommendedPathType);

    const pathTemplate = this.pathTemplates[recommendations.recommendedPathType];
    recommendations.estimatedDuration = {
      hours: Math.round((pathTemplate.recommendedHours.min + pathTemplate.recommendedHours.max) / 2),
      weeks: Math.ceil(((pathTemplate.recommendedHours.min + pathTemplate.recommendedHours.max) / 2) / 8)
    };

    recommendations.personalizedMessage = this.generatePersonalizedMessage(recommendations, categoryScores);

    return recommendations;
  }

  /**
   * Calculate overall skill level
   *
   * @private
   * @param {Object} assessments - Assessment data
   * @returns {string} Overall level
   */
  calculateOverallLevel(assessments) {
    const levels = Object.values(assessments).map(a => this.getLevelScore(a.skillLevel));
    const average = levels.reduce((sum, level) => sum + level, 0) / levels.length;

    if (average <= 1) {return 'novice';}
    if (average <= 2) {return 'competent';}
    if (average < 3) {return 'proficient';}
    return 'expert';
  }

  /**
   * Get numeric score for skill level
   *
   * @private
   * @param {string} level - Skill level
   * @returns {number} Numeric score
   */
  getLevelScore(level) {
    const scores = { novice: 0, competent: 1, proficient: 2, expert: 3 };
    return scores[level] || 0;
  }

  /**
   * Generate suggested learning items
   *
   * @private
   * @param {Array} categoryScores - Category scores
   * @param {string} pathType - Path type
   * @returns {Array} Suggested items
   */
  generateSuggestedItems(categoryScores, pathType) {
    const items = [];

    categoryScores.forEach(({ category, score, skillLevel }) => {
      // Defensive: Skip if category not defined
      if (!this.skillCategories[category]) {
        console.warn(`Category '${category}' not found in skillCategories, skipping`);
        return;
      }

      if (skillLevel === 'novice' || score < 0.4) {
        items.push({
          id: `${category}-01-fundamentals`,
          title: `${this.skillCategories[category].name} Fundamentals`,
          category,
          type: 'kata',
          difficulty: 'beginner',
          estimatedTime: 60,
          priority: 'high',
          reason: `Foundation building in ${this.skillCategories[category].name}`
        });
      }

      if (pathType !== DIFFICULTY.BEGINNER && score >= 0.3) {
        items.push({
          id: `${category}-02-practical-application`,
          title: `${this.skillCategories[category].name} Practical Application`,
          category,
          type: 'lab',
          difficulty: 'intermediate',
          estimatedTime: 90,
          priority: 'medium',
          reason: `Hands-on practice with ${this.skillCategories[category].name}`
        });
      }
    });

    return items.sort((a, b) => {
      const priorityOrder = { high: 0, medium: 1, low: 2 };
      return priorityOrder[a.priority] - priorityOrder[b.priority];
    }).slice(0, 8);
  }

  /**
   * Generate personalized message
   *
   * @private
   * @param {Object} recommendations - Recommendations data
   * @param {Array} categoryScores - Category scores
   * @returns {string} Personalized message
   */
  generatePersonalizedMessage(recommendations, categoryScores) {
    const pathType = recommendations.recommendedPathType;
    const strongestArea = categoryScores[categoryScores.length - 1];
    const weakestArea = categoryScores[0];

    let message = `Based on your assessment, we recommend the **${this.pathTemplates[pathType].name}** learning path. `;

    if (strongestArea.score > 0.7) {
      message += `You show strong skills in **${this.skillCategories[strongestArea.category].name}**, which is excellent! `;
    }

    message += `We've identified **${this.skillCategories[weakestArea.category].name}** as a key area for growth.`;

    return message;
  }

  /**
   * Show path recommendations
   *
   * @private
   * @param {HTMLElement} container - Container element
   * @param {Object} recommendations - Recommendations data
   */
  showPathRecommendations(container, recommendations) {
    container.innerHTML = `
      <div class="path-recommendations">
        <div class="results-container">
          <div class="results-icon">🎯</div>
          <h3>Your Personalized Learning Path</h3>
          <div class="results-success-message">
            <p>${recommendations.personalizedMessage}</p>
          </div>
        </div>

        <div class="action-buttons">
          <button id="create-path-btn" class="create-path-btn">
            Create Learning Path
          </button>

          <button id="retake-assessment-btn" class="retake-assessment-btn">
            Retake Assessment
          </button>
        </div>
      </div>
    `;

    const createBtn = container.querySelector('#create-path-btn');
    const retakeBtn = container.querySelector('#retake-assessment-btn');

    if (createBtn) {
      createBtn.addEventListener('click', () => this.createLearningPath(recommendations));
    }

    if (retakeBtn) {
      retakeBtn.addEventListener('click', () => this.retakeAssessment());
    }
  }

  /**
   * Create learning path from recommendations
   *
   * @async
   * @param {Object} recommendations - Recommendations data
   */
  async createLearningPath(recommendations) {
    try {
      const pathData = this.createSchemaCompliantPath(recommendations);
      await this.saveAssessmentBasedPath(pathData);

      // Show success through UI notification system instead of console
      this.hide();

      // Dispatch event for other components
      const event = new CustomEvent('learningPathCreated', {
        detail: { pathData, source: 'assessment' }
      });
      dispatchEvent(event);

    } catch (_error) {
      this.errorHandler.handleError(_error, 'Failed to create learning path');
      // Error already handled by errorHandler, no need for additional console.error
    }
  }

  /**
   * Create schema-compliant learning path from assessment
   *
   * @private
   * @param {Object} recommendations - Recommendations data
   * @returns {Object} Schema-compliant path data
   */
  createSchemaCompliantPath(recommendations) {
    const timestamp = new Date().toISOString();
    const pathId = `assessment-path-${Date.now()}`;
    const pathType = recommendations.recommendedPathType;

    return {
      metadata: {
        version: "1.0.0",
        learningPathId: pathId,
        learningPathTitle: `${this.pathTemplates[pathType].name} - Personalized Path`,
        pathType: pathType,
        source: "assessment",
        fileType: "learning-path-progress",
        sessionId: `assessment-session-${Date.now()}`,
        lastUpdated: timestamp,
        assessmentData: this.skillAssessments
      },
      timestamp: timestamp,
      learningPath: {
        title: `${this.pathTemplates[pathType].name} - Personalized Path`,
        description: `${this.pathTemplates[pathType].description} - Customized based on your skill assessment results.`,
        categories: recommendations.priorityAreas,
        estimatedDuration: {
          hours: recommendations.estimatedDuration.hours,
          weeks: recommendations.estimatedDuration.weeks
        },
        difficultyLevel: recommendations.overallLevel,
        items: recommendations.suggestedItems.map((item, _index) => ({
          id: item.id,
          type: item.type,
          title: item.title,
          category: item.category,
          order: _index + 1,
          estimatedTime: item.estimatedTime,
          difficulty: item.difficulty,
          isRequired: item.priority === 'high',
          dependencies: _index > 0 ? [recommendations.suggestedItems[_index - 1].id] : [],
          skills: [item.category]
        }))
      },
      progress: {
        itemProgress: {},
        overallProgress: {
          itemsCompleted: 0,
          totalItems: recommendations.suggestedItems.length,
          completionPercentage: 0
        }
      }
    };
  }

  /**
   * Save assessment-based path to storage
   *
   * @async
   * @private
   * @param {Object} pathData - Path data to save
   */
  async saveAssessmentBasedPath(pathData) {
    const storageKey = `assessmentLearningPath_${pathData.metadata.learningPathId}`;
    localStorage.setItem(storageKey, JSON.stringify(pathData, null, 2));

    const assessmentKey = `skillAssessment_${Date.now()}`;
    localStorage.setItem(assessmentKey, JSON.stringify({
      assessments: this.skillAssessments,
      completedAt: new Date().toISOString(),
      pathGenerated: pathData.metadata.learningPathId
    }, null, 2));
  }

  /**
   * Retake assessment
   *
   * @public
   */
  retakeAssessment() {
    // Clear assessment results and restart - simplified for production
    this.skillAssessments = {};
    this.currentCategoryIndex = 0;
    this.startAssessment();
  }

  /**
   * Load existing assessments from storage
   *
   * @async
   * @private
   */
  async loadExistingAssessments() {
    try {
      const assessmentKeys = Object.keys(localStorage).filter(key => key.startsWith('skillAssessment_'));

      if (assessmentKeys.length > 0) {
        const latestKey = assessmentKeys.sort().pop();
        const assessmentData = JSON.parse(localStorage.getItem(latestKey));

        if (assessmentData && assessmentData.assessments) {
          this.skillAssessments = assessmentData.assessments;
        }
      }
    } catch {
      // Silently handle assessment loading failures - non-critical
    }
  }

  /**
   * Show the assessment generator modal
   *
   * @public
   */
  show() {
    this.modalElement.classList.add('visible');
    this.isVisible = true;
  }

  /**
   * Hide the assessment generator modal
   *
   * @public
   */
  hide() {
    this.modalElement.classList.remove('visible');
    this.isVisible = false;
  }

  /**
   * Extract assessment data from form
   *
   * @public
   * @returns {Object} Extracted form data
   */
  extractAssessmentData() {
    return this.errorHandler.safeExecute(() => {
      const formData = {};
      const form = document.querySelector('#skill-assessment-form');
      if (!form) {return formData;}

      const formElements = form.querySelectorAll('input, select, textarea');
      formElements.forEach(element => {
        if (element.type === 'checkbox' || element.type === 'radio') {
          if (element.checked) {
            formData[element.name] = element.value;
          }
        } else if (element.type === 'range') {
          formData[element.name] = parseInt(element.value, 10);
        } else {
          formData[element.name] = element.value;
        }
      });

      return formData;
    }, 'Extracting assessment data');
  }

  /**
   * Validate assessment data
   *
   * @public
   * @param {Object} data - Assessment data to validate
   * @returns {Object} Validation results
   */
  validateAssessmentData(data) {
    return this.errorHandler.safeExecute(() => {
      const errors = [];
      const required = ['experience', 'timeCommitment', 'goals'];

      required.forEach(field => {
        if (!data[field] || data[field] === '') {
          errors.push(`${field} is required`);
        }
      });

      return {
        isValid: errors.length === 0,
        errors
      };
    }, 'Validating assessment data');
  }

  /**
   * Get checkbox values for a given name
   *
   * @public
   * @param {string} name - Checkbox group name
   * @returns {Array} Selected checkbox values
   */
  getCheckboxValues(name) {
    return this.errorHandler.safeExecute(() => {
      const checkboxes = document.querySelectorAll(`input[name="${name}"]:checked`);
      return Array.from(checkboxes).map(cb => cb.value);
    }, 'Getting checkbox values');
  }

  /**
   * Process assessment and generate path
   *
   * @public
   * @param {Object} assessmentData - Assessment data
   * @returns {Promise<Object>} Generated learning path
   */
  async processAssessment(assessmentData) {
    return this.errorHandler.safeExecute(async () => {
      this.assessmentData = assessmentData;

      // Generate path based on assessment
      const path = {
        modules: this.generateModules(assessmentData),
        timeEstimate: this.calculateTimeEstimate(assessmentData),
        difficulty: this.calculateDifficulty(assessmentData),
        customizations: this.getCustomizations(assessmentData)
      };

      this.pathRecommendations = path;
      return path;
    }, 'Processing assessment');
  }

  /**
   * Display validation errors
   *
   * @public
   * @param {Array} errors - Validation errors to display
   */
  displayValidationErrors(errors) {
    this.errorHandler.safeExecute(() => {
      const container = document.querySelector('#validation-errors');
      if (!container) {return;}

      container.innerHTML = '';
      if (errors.length === 0) {return;}

      const errorList = document.createElement('ul');
      errors.forEach(error => {
        const li = document.createElement('li');
        li.textContent = error;
        errorList.appendChild(li);
      });
      container.appendChild(errorList);
    }, 'Displaying validation errors');
  }

  /**
   * Save assessment data to storage
   *
   * @public
   * @param {Object} data - Assessment data to save
   * @returns {boolean} Success status
   */
  saveAssessmentData(data) {
    return this.errorHandler.safeExecute(() => {
      const key = `skillAssessment_${Date.now()}`;
      localStorage.setItem(key, JSON.stringify(data));
      return true;
    }, 'Saving assessment data');
  }

  /**
   * Load saved assessment data
   *
   * @public
   * @returns {Object|null} Saved assessment data or null
   */
  loadSavedAssessment() {
    return this.errorHandler.safeExecute(() => {
      const keys = Object.keys(localStorage).filter(key => key.startsWith('skillAssessment_'));
      if (keys.length === 0) {return null;}

      const latestKey = keys.sort().pop();
      const data = localStorage.getItem(latestKey);
      return data ? JSON.parse(data) : null;
    }, 'Loading saved assessment');
  }

  /**
   * Restore form values from saved data
   *
   * @public
   * @param {Object} data - Saved assessment data
   */
  restoreFormValues(data) {
    this.errorHandler.safeExecute(() => {
      if (!data) {return;}

      Object.keys(data).forEach(key => {
        const element = document.querySelector(`[name="${key}"]`);
        if (element) {
          if (element.type === 'checkbox' || element.type === 'radio') {
            element.checked = element.value === data[key];
          } else {
            element.value = data[key];
          }
        }
      });
    }, 'Restoring form values');
  }

  /**
   * Save learning path to storage
   *
   * @public
   * @param {Object} path - Learning path to save
   * @returns {boolean} Success status
   */
  saveLearningPath(path) {
    return this.errorHandler.safeExecute(() => {
      const key = `learningPath_${Date.now()}`;
      localStorage.setItem(key, JSON.stringify(path));
      return true;
    }, 'Saving learning path');
  }

  /**
   * Export path as PDF
   *
   * @public
   * @param {Object} path - Learning path to export
   * @returns {string} PDF blob URL
   */
  exportPathAsPDF(path) {
    return this.errorHandler.safeExecute(() => {
      // Mock PDF generation - in real implementation would use a PDF library
      const content = JSON.stringify(path, null, 2);
      const blob = new Blob([content], { type: 'application/pdf' });
      return URL.createObjectURL(blob);
    }, 'Exporting path as PDF');
  }

  /**
   * Start learning journey
   *
   * @public
   * @param {Object} _path - Learning path to start (unused but kept for API compatibility)
   */
  startLearningJourney(_path) {
    this.errorHandler.safeExecute(() => {
      // Mock implementation - would redirect to first module
      // window.location.href = path.modules[0]?.url || '/learning/';
    }, 'Starting learning journey');
  }

  /**
   * Reset assessment form and data
   *
   * @public
   */
  resetAssessment() {
    this.errorHandler.safeExecute(() => {
      const form = document.querySelector('#skill-assessment-form');
      if (form) {
        form.reset();
      }

      this.assessmentData = null;
      this.skillAssessments = {};
      this.pathRecommendations = {};
      this.currentCategoryIndex = 0;
    }, 'Resetting assessment');
  }

  /**
   * Generate recommendations based on assessment results
   * Used by completion modal to show personalized learning path recommendations
   *
   * @public
   * @param {Object} assessmentResults - Assessment results from skill assessment form
   * @returns {Object|null} Recommendations object with path suggestions, or null if no valid data
   */
  generateRecommendations(assessmentResults) {
    return this.errorHandler.safeExecute(() => {
      // If no results provided, return null
      if (!assessmentResults) {
        return null;
      }

      // Handle different possible structures from skill assessment
      let transformedAssessments = {};

      // Case 1: assessmentResults has categoryScores (from calculateResults)
      if (assessmentResults.categoryScores) {
        Object.entries(assessmentResults.categoryScores).forEach(([category, data]) => {
          if (data.score !== undefined && data.questionsCount > 0) {
            // data.score is already the average rating (calculated by skill-assessment-form.js)
            const averageRating = data.score;

            // Use the skill level directly from assessment results (now standardized)
            const skillLevel = data.level || 'beginner';

            transformedAssessments[category] = {
              skillLevel,
              averageRating,
              responses: data.questions || []
            };
          }
        });
      }
      // Case 2: assessmentResults has responses array
      else if (assessmentResults.responses) {
        // Group responses by category
        const categorizedResponses = {};

        // Handle both array and object formats
        const responsesArray = Array.isArray(assessmentResults.responses)
          ? assessmentResults.responses
          : Object.values(assessmentResults.responses);

        responsesArray.forEach(response => {
          // Handle different response formats
          const rating = typeof response === 'number' ? response : response.rating || response.value || 0;
          const category = response.category || 'general';

          if (!categorizedResponses[category]) {
            categorizedResponses[category] = [];
          }
          categorizedResponses[category].push(rating);
        });

        // Calculate average rating and determine skill level for each category
        Object.entries(categorizedResponses).forEach(([category, ratings]) => {
          const averageRating = ratings.reduce((sum, r) => sum + r, 0) / ratings.length;

          // Determine skill level based on average rating (0-5 scale)
          let skillLevel = 'novice';
          if (averageRating >= 4) {
            skillLevel = 'expert';
          } else if (averageRating >= 3) {
            skillLevel = 'proficient';
          } else if (averageRating >= 2) {
            skillLevel = 'competent';
          }

          transformedAssessments[category] = {
            skillLevel,
            averageRating,
            responses: ratings
          };
        });
      }

      // If we have no valid assessments, return null
      if (Object.keys(transformedAssessments).length === 0) {
        return null;
      }

      // Temporarily set skillAssessments for analysis
      const previousAssessments = this.skillAssessments;
      this.skillAssessments = transformedAssessments;

      // Use existing analyzeAssessmentResults method
      const recommendations = this.analyzeAssessmentResults();

      // Restore previous assessments
      this.skillAssessments = previousAssessments;

      return recommendations;
    }, 'Generating recommendations', null);
  }

  /**
   * Get last assessment results
   * Fallback method used by completion handler when skillAssessmentForm is not available
   *
   * @public
   * @returns {Object|null} Last assessment results or null
   */
  getLastResults() {
    return this.errorHandler.safeExecute(() => {
      // Return last stored assessment results if available
      return this.assessmentData || null;
    }, 'Getting last results', null);
  }

  // Helper methods for path generation
  generateModules(data) {
    // Mock module generation based on assessment data
    const modules = [];
    const experience = data.experience || 'beginner';
    const goals = data.goals || [];

    if (experience === 'beginner') {
      modules.push({ name: 'Fundamentals', duration: '2 weeks' });
    }
    if (goals.includes('ai-assisted')) {
      modules.push({ name: 'AI-Assisted Development', duration: '3 weeks' });
    }

    return modules;
  }

  calculateTimeEstimate(data) {
    const baseTime = 4; // weeks
    const timeCommitment = data.timeCommitment || 'moderate';
    const multiplier = timeCommitment === 'intensive' ? 0.7 : timeCommitment === 'light' ? 1.5 : 1;
    return Math.round(baseTime * multiplier);
  }

  calculateDifficulty(data) {
    const experience = data.experience || 'beginner';
    const challengeLevel = data.challengeLevel || 'moderate';

    if (experience === 'advanced' && challengeLevel === 'high') {
      return 'expert';
    } else if (experience === 'intermediate') {
      return 'intermediate';
    }
    return 'beginner';
  }

  getCustomizations(data) {
    return {
      technology: data.technology || [],
      focusAreas: data.goals || [],
      learningStyle: data.learningStyle || 'balanced'
    };
  }

  /**
   * Additional methods for test compatibility
   */
  selectPathTemplate(data) {
    return this.errorHandler.safeExecute(() => {
      const experience = data.experience || 'beginner';
      return this.pathTemplates[experience] || this.pathTemplates.beginner;
    }, 'Selecting path template');
  }

  calculateSkillWeights(data) {
    return this.errorHandler.safeExecute(() => {
      const weights = {};
      Object.keys(data).forEach(key => {
        if (typeof data[key] === 'number') {
          weights[key] = data[key] / 10; // normalize to 0-1
        }
      });
      return weights;
    }, 'Calculating skill weights');
  }

  filterAvailableModules(data) {
    return this.errorHandler.safeExecute(() => {
      // Mock filtering logic
      return this.generateModules(data);
    }, 'Filtering available modules');
  }

  adjustModuleDifficulty(modules, difficulty) {
    return this.errorHandler.safeExecute(() => {
      return modules.map(module => ({
        ...module,
        difficulty: difficulty
      }));
    }, 'Adjusting module difficulty');
  }

  sequenceModules(modules) {
    return this.errorHandler.safeExecute(() => {
      // Mock sequencing - sort by difficulty/prerequisites
      return modules.sort((a, b) => a.name.localeCompare(b.name));
    }, 'Sequencing modules');
  }

  submitToAPI(_data) {
    return this.errorHandler.safeExecute(async () => {
      // Mock API submission
      await new Promise(resolve => setTimeout(resolve, 100));
      return { success: true, id: 'mock-submission-id' };
    }, 'Submitting to API');
  }

  displayLearningPath(_path) {
    this.errorHandler.safeExecute(() => {
      // Display learning path
    }, 'Displaying learning path');
  }

  renderPathSummary(_path) {
    this.errorHandler.safeExecute(() => {
      // Render path summary
    }, 'Rendering path summary');
  }

  renderModulesList(_modules) {
    this.errorHandler.safeExecute(() => {
      // Render modules list
    }, 'Rendering modules list');
  }

  renderSkillProgression(_data) {
    this.errorHandler.safeExecute(() => {
      // Render skill progression
    }, 'Rendering skill progression');
  }

  renderNextSteps(_data) {
    this.errorHandler.safeExecute(() => {
      // Render next steps
    }, 'Rendering next steps');
  }

  displayPathProgress(_progress) {
    this.errorHandler.safeExecute(() => {
      // Display path progress
    }, 'Displaying path progress');
  }

  setupEventListeners() {
    this.errorHandler.safeExecute(() => {
      // Mock event listener setup
    }, 'Setting up event listeners');
  }

  /**
   * Destroy the assessment generator and clean up resources
   *
   * @public
   */
  destroy() {
    if (this.modalElement && this.modalElement.parentNode) {
      this.modalElement.parentNode.removeChild(this.modalElement);
    }

    this.assessmentData = null;
    this.skillAssessments = {};
    this.pathRecommendations = {};
    this.containerElement = null;
    this.modalElement = null;
    this.isVisible = false;
    this.isInitialized = false;

    // Clean up properties for test compatibility
    if (this.abortController) {
      try {
        this.abortController.abort();
      } catch {
        // Ignore abort errors during cleanup
      }
    }
    this.currentPath = null;
  }
}

/**
 * Factory function to create and initialize AssessmentPathGenerator
 *
 * @param {Object} [dependencies={}] - Dependency injection object
 * @returns {Promise<AssessmentPathGenerator>} Initialized instance
 */
export async function createAssessmentPathGenerator(dependencies = {}) {
  const generator = new AssessmentPathGenerator(dependencies);
  await generator.initialize();
  return generator;
}

export default AssessmentPathGenerator;
