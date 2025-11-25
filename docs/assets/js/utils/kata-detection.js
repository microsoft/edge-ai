/**
 * @fileoverview Kata Detection Utilities
 * Content detection and learning path identification for learning system
 * @version 2.1.0
 */

/**
 * Kata Detection and Content Analysis
 * Identifies learning content types and paths based on actual learning structure
 * @class KataDetection
 */
export class KataDetection {
  /**
   * Creates a new KataDetection instance
   * @param {Object} [debugHelper] - Debug helper with logging methods
   * @param {Object} [errorHandler] - Error handler with safeExecute method
   */
  constructor(debugHelper, errorHandler) {
    // Use simple fallbacks to avoid circular dependencies during initialization
    this.debugHelper = debugHelper || { debug: () => {}, info: () => {}, warn: () => {}, error: () => {} };
    this.errorHandler = errorHandler || { safeExecute: (fn, name, fallback) => { try { return fn(); } catch { return fallback; } } };

    // Real learning structure based on actual directories
    this.kataCategories = {
      'ai-assisted-engineering': {
        name: 'AI-Assisted Engineering',
        description: 'Become proficient in AI-powered development workflows and patterns',
        katas: [
          '01-ai-development-fundamentals',
          '02-getting-started-basics',
          '03-getting-started-advanced'
        ],
        estimatedHours: 6
      },
      'task-planning': {
        name: 'Task Planning',
        description: 'Systematic project planning with edge computing scenarios',
        katas: [
          '01-edge-documentation-planning',
          '02-repository-analysis-planning',
          '03-advanced-capability-integration',
          '04-pr-generation'
        ],
        estimatedHours: 8
      },
      'prompt-engineering': {
        name: 'Prompt Engineering',
        description: 'Effective AI prompt creation and refinement techniques',
        katas: [
          '01-prompt-creation-and-refactoring-workflow',
          '02-basic-prompt-structure'
        ],
        estimatedHours: 4
      },
      'edge-deployment': {
        name: 'Edge Deployment',
        description: 'Deploy and manage edge computing solutions',
        katas: [
          '01-deployment-basics',
          '02-intermediate-deployment',
          '03-advanced-deployment',
          '04-expert-deployment',
          '05-deployment-expert'
        ],
        estimatedHours: 10
      },
      'adr-creation': {
        name: 'Architecture Decision Records',
        description: 'Create and manage architectural decision documentation',
        katas: [
          '01-basic-messaging-architecture',
          '02-advanced-observability-stack',
          '03-service-mesh-selection'
        ],
        estimatedHours: 6
      }
    };

    this.trainingLabs = {
      '01-ai-assisted-engineering': {
        name: 'AI-Assisted Engineering Lab',
        description: 'Comprehensive AI-assisted development training',
        estimatedHours: 40
      },
      '02-edge-to-cloud-systems': {
        name: 'Edge-to-Cloud Systems Lab',
        description: 'Build production-ready edge AI systems',
        estimatedHours: 80
      }
    };
  }

  /**
   * Detect if current page is a kata
   * @returns {boolean} True if current page is a kata
   */
  isKataPage() {
    return this.errorHandler.safeExecute(() => {
      // Simply use the existing extractKataId logic
      // If it can extract a valid kata ID, we're on a kata page
      const kataId = this.extractKataId();
      return kataId !== null;
    }, 'isKataPage', false);
  }

  /**
   * Detect if current page is a training lab
   * @returns {boolean} True if current page is a training lab
   */
  isLabPage() {
    return this.errorHandler.safeExecute(() => {
      // Check if window and location exist
      if (typeof window === 'undefined' || !window.location) {
        return false;
      }

      // Get both hash and pathname to handle test environments
      const hash = window.location.hash || '';
      const pathname = window.location.pathname || '';
      const fullPath = pathname + hash;

      // Check URL pattern for training labs - handle both #/learning and /learning patterns
      if (fullPath.includes('learning/training-labs/')) {
        return true;
      }

      // Check content for lab indicators
      if (typeof document !== 'undefined') {
        const content = document.querySelector('.content');
        if (content) {
          const text = content.textContent || '';
          return text.includes('training lab') || text.includes('Training Lab') ||
                 text.includes('comprehensive learning') || text.includes('hands-on training');
        }
      }

      return false;
    }, 'isLabPage', false);
  }

  /**
   * Get content type (kata, lab, or unknown)
   * @returns {string} Content type
   */
  getContentType() {
    if (this.isKataPage()) {return 'kata';}
    if (this.isLabPage()) {return 'lab';}
    return 'unknown';
  }

  /**
   * Extract kata category from URL or content
   * @returns {string|null} Kata category identifier
   */
  extractKataCategory() {
    return this.errorHandler.safeExecute(() => {
      // Check if window and location exist
      if (typeof window === 'undefined' || !window.location) {
        return null;
      }

      // Get both hash and pathname to handle Happy DOM test environment
      const hash = window.location.hash || '';
      const pathname = window.location.pathname || '';
      const fullPath = pathname + hash;

      // Check URL for kata category - handle both #/learning and /learning patterns
      for (const categoryId of Object.keys(this.kataCategories)) {
        if (fullPath.includes(`/learning/katas/${categoryId}/`)) {
          return categoryId;
        }
      }

      // Check content for category indicators
      if (typeof document !== 'undefined') {
        const content = document.querySelector('.content');
        if (content) {
          const text = content.textContent || '';
          for (const [categoryId, categoryData] of Object.entries(this.kataCategories)) {
            if (text.includes(categoryData.name)) {
              return categoryId;
            }
          }
        }
      }

      return null;
    }, 'extractKataCategory', null);
  }

  /**
   * Extract specific kata ID from URL or content
   * @returns {string|null} Kata ID
   */
  extractKataId() {
    return this.errorHandler.safeExecute(() => {
      // Check if window and location exist
      if (typeof window === 'undefined' || !window.location) {
        return null;
      }

      // Get both hash and pathname to handle Happy DOM test environment
      const hash = window.location.hash || '';
      const pathname = window.location.pathname || '';
      const fullPath = pathname + hash;

      // Extract from URL pattern: /learning/katas/category/kata-id (handles both hash and non-hash URLs)
      const kataMatch = fullPath.match(/[#/]?learning\/katas\/([^/]+)\/([^/]+)/);
      if (kataMatch) {
        const [, category, kataId] = kataMatch;

        // Exclude folder pages: README, index, _navbar, or anything ending with /
        if (kataId === 'README' || kataId === 'index' || kataId === '_navbar' ||
            kataId.endsWith('/') || fullPath.endsWith('/')) {
          return null;
        }

        // Valid kata pages typically start with numbers (01-, 02-, etc.)
        if (kataId.match(/^\d+/)) {
          return `${category}/${kataId}`;
        }

        return null;
      }

      // Try to extract from page title or headers
      if (typeof document !== 'undefined') {
        const titleElement = document.querySelector('h1, .content h1, .markdown-section h1');
        if (titleElement) {
          const title = titleElement.textContent || '';

          // Look for numbered kata patterns
          const numberedMatch = title.match(/(\d+)-(.+)/);
          if (numberedMatch) {
            const category = this.extractKataCategory();
            if (category) {
              return `${category}/${numberedMatch[0].toLowerCase().replace(/\s+/g, '-')}`;
            }
          }
        }
      }

      return null;
    }, 'extractKataId', null);
  }

  /**
   * Extract training lab ID from URL or content
   * @returns {string|null} Training lab ID
   */
  extractLabId() {
    return this.errorHandler.safeExecute(() => {
      // Check if window and location exist
      if (typeof window === 'undefined' || !window.location) {
        return null;
      }

      // Get both hash and pathname to handle test environments
      const hash = window.location.hash || '';
      const pathname = window.location.pathname || '';
      const fullPath = pathname + hash;

      // Extract from URL pattern: /learning/training-labs/lab-id
      const labMatch = fullPath.match(/learning\/training-labs\/([^/]+)/);
      if (labMatch) {
        const labId = labMatch[1];
        return labId;
      }

      // If URL doesn't contain lab ID, try to extract from page title
      if (typeof document !== 'undefined') {
        const titleElement = document.querySelector('h1');
        if (titleElement && titleElement.textContent) {
          const title = titleElement.textContent.toLowerCase();
          if (title.includes('ai-assisted engineering')) {
            return '01-ai-assisted-engineering';
          }
          // Add more lab title patterns as needed
        }
      }

      return null;
    }, 'extractLabId', null);
  }

  /**
   * Get kata category information
   * @param {string} categoryId - Category identifier
   * @returns {Object|null} Category information
   */
  getKataCategory(categoryId) {
    return this.kataCategories[categoryId] || null;
  }

  /**
   * Get training lab information
   * @param {string} labId - Lab identifier
   * @returns {Object|null} Lab information
   */
  getTrainingLab(labId) {
    return this.trainingLabs[labId] || null;
  }

  /**
   * Get current learning context (kata or lab information)
   * @returns {Object|null} Current learning context
   */
  getCurrentLearningContext() {
    return this.errorHandler.safeExecute(() => {
      const contentType = this.getContentType();

      if (contentType === 'kata') {
        const categoryId = this.extractKataCategory();
        const kataPath = this.extractKataId();

        if (categoryId && kataPath) {
          const kataId = kataPath.split('/')[1]; // Get just the kata part
          const category = this.getKataCategory(categoryId);

          const context = {
            type: 'kata',
            categoryId,
            categoryName: category ? category.name : null,
            kataId,
            fullKataId: kataPath,
            category
          };
          return context;
        }
      } else if (contentType === 'lab') {
        const labId = this.extractLabId();

        if (labId) {
          const lab = this.getTrainingLab(labId);

          const context = {
            type: 'lab',
            labId,
            lab
          };
          return context;
        }
      }

      return null;
    }, 'getCurrentLearningContext', null);
  }

  /**
   * Get all kata categories
   * @returns {Object} All kata categories
   */
  getAllKataCategories() {
    return this.kataCategories;
  }

  /**
   * Get all training labs
   * @returns {Object} All training labs
   */
  getAllTrainingLabs() {
    return this.trainingLabs;
  }

  /**
   * Check if specific kata exists in category
   * @param {string} categoryId - Category identifier
   * @param {string} kataId - Kata identifier
   * @returns {boolean} True if kata exists
   */
  kataExists(categoryId, kataId) {
    const category = this.getKataCategory(categoryId);
    if (!category) {return false;}

    return category.katas.includes(kataId);
  }

  /**
   * Get next kata in category progression
   * @param {string} categoryId - Category identifier
   * @param {string} currentKataId - Current kata identifier
   * @returns {string|null} Next kata ID or null
   */
  getNextKataInCategory(categoryId, currentKataId) {
    const category = this.getKataCategory(categoryId);
    if (!category) {return null;}

    const currentIndex = category.katas.indexOf(currentKataId);
    if (currentIndex === -1 || currentIndex === category.katas.length - 1) {
      return null;
    }

    return category.katas[currentIndex + 1];
  }

  /**
   * Get previous kata in category progression
   * @param {string} categoryId - Category identifier
   * @param {string} currentKataId - Current kata identifier
   * @returns {string|null} Previous kata ID or null
   */
  getPreviousKataInCategory(categoryId, currentKataId) {
    const category = this.getKataCategory(categoryId);
    if (!category) {return null;}

    const currentIndex = category.katas.indexOf(currentKataId);
    if (currentIndex <= 0) {
      return null;
    }

    return category.katas[currentIndex - 1];
  }

  /**
   * Calculate category completion percentage
   * @param {string} categoryId - Category identifier
   * @param {Array} completedKatas - Array of completed kata IDs
   * @returns {number} Completion percentage (0-100)
   */
  calculateCategoryCompletion(categoryId, completedKatas = []) {
    const category = this.getKataCategory(categoryId);
    if (!category) {return 0;}

    const totalKatas = category.katas.length;
    const completedInCategory = completedKatas.filter(kataId =>
      kataId.startsWith(`${categoryId }/`)
    ).length;

    return totalKatas > 0 ? Math.round((completedInCategory / totalKatas) * 100) : 0;
  }

  /**
   * Clean up resources and event listeners
   * @returns {void}
   */
  destroy() {
    // Clear any cached data
    this.debugHelper = null;
    this.errorHandler = null;
  }
}

/**
 * Create and export default instance for convenience
 * @type {KataDetection}
 */
export const defaultKataDetection = new KataDetection();

/**
 * Export individual convenience functions
 */
export const isKataPage = () => defaultKataDetection.isKataPage();
export const isLabPage = () => defaultKataDetection.isLabPage();
export const getCurrentLearningContext = () => defaultKataDetection.getCurrentLearningContext();
export const getContentType = () => defaultKataDetection.getContentType();
export const extractKataId = () => defaultKataDetection.extractKataId();


