/**
 * Learning Path Manager
 * Manages kata category progress and training lab tracking based on real learning structure
 *
 * @class LearningPathManager
 * @author Edge AI Team
 * @version 3.1.0
 * @since 1.0.0
 */

/**
 * Learning Path Manager
 * Manages progression through real learning kata categories and training labs.
 * Provides comprehensive progress tracking, recommendations, and analytics for learning paths.
 *
 * Features:
 * - Real-time progress tracking for kata categories and training labs
 * - Intelligent recommendation engine for next learning activities
 * - Comprehensive analytics and reporting capabilities
 * - Dependency injection for testability and modularity
 * - Memory management with proper cleanup patterns
 *
 * @class LearningPathManager
 * @example
 * ```javascript
 * const manager = new LearningPathManager({
 *   debugHelper,
 *   errorHandler,
 *   storageManager,
 *   kataDetection
 * });
 *
 * const context = manager.getCurrentContext();
 * const progress = manager.getOverallProgress();
 * const recommendations = manager.getRecommendations();
 * ```
 */
export class LearningPathManager {
  /**
   * Create a LearningPathManager instance
   * @param {Object} dependencies - Required dependencies
   * @param {Object} dependencies.debugHelper - Debug helper instance
   * @param {Object} dependencies.errorHandler - Error handler instance
   * @param {Object} dependencies.storageManager - Storage manager instance
   * @param {Object} dependencies.kataDetection - Kata detection instance (optional for testing)
   * @param {Object} dependencies.config - Custom configuration
   * @throws {Error} When required dependencies are missing or invalid
   */
  constructor({ debugHelper, errorHandler, storageManager, kataDetection, config }) {
    // Validate required dependencies
    if (!errorHandler || typeof errorHandler.safeExecute !== 'function') {
      throw new Error('LearningPathManager requires errorHandler with safeExecute method');
    }

    if (!storageManager) {
      throw new Error('LearningPathManager requires storageManager dependency');
    }

    // kataDetection is optional for testing
    if (!kataDetection) {
      // Note: Warning for development - should use proper logging in production
      // eslint-disable-next-line no-console
      console.warn('LearningPathManager: kataDetection dependency not provided (testing mode)');
    }

    // Assign dependencies
    this.debugHelper = debugHelper;
    this.errorHandler = errorHandler;
    this.storage = storageManager;
    this.detection = kataDetection;

    // Initialize state
    this.isInitialized = false;
    this._isDestroyed = false;
    this._config = config ? { ...this.getDefaultConfig(), ...config } : this.getDefaultConfig();

    // UI-specific state for checkbox selections
    this._pathSelections = {};

    // Simple in-memory cache for API progress data
    this._progressCache = new Map();
  }

  /**
   * Get current learning context (category or lab)
   * @returns {Object|null} Current context information
   */
  getCurrentContext() {
    return this.errorHandler.safeExecute(() => {
      const contentType = this.detection.getContentType();

      if (contentType === 'kata') {
        const categoryId = this.detection.extractKataCategory();
        const kataId = this.detection.extractKataId();
        const category = this.detection.getKataCategory(categoryId);

        return {
          type: 'kata',
          categoryId,
          kataId,
          category,
          fullKataId: kataId // e.g., "ai-assisted-engineering/01-ai-development-fundamentals"
        };
      } else if (contentType === 'lab') {
        const labId = this.detection.extractLabId();
        const lab = this.detection.getTrainingLab(labId);

        return {
          type: 'lab',
          labId,
          lab
        };
      }

      return null;
    }, 'getCurrentContext', null);
  }

  /**
   * Get kata category progress
   * @param {string} categoryId - Category identifier
   * @returns {Object} Category progress data
   */
  getCategoryProgress(categoryId) {
    return this.errorHandler.safeExecute(() => {
      const category = this.detection.getKataCategory(categoryId);
      if (!category) {
        return { error: 'Category not found', categoryId };
      }

      // Get individual kata progress
      const kataProgress = category.katas.map(kataId => {
        const fullKataId = `${categoryId}/${kataId}`;
        return this.getKataProgress(fullKataId);
      });

      // Calculate overall progress
      const totalKatas = category.katas.length;
      const completedKatas = kataProgress.filter(p => p.completionPercentage === 100).length;
      const overallCompletion = totalKatas > 0 ? Math.round((completedKatas / totalKatas) * 100) : 0;

      // Calculate total time spent
      const totalTimeSpent = kataProgress.reduce((sum, p) => sum + (p.timeSpent || 0), 0);

      return {
        categoryId,
        category,
        totalKatas,
        completedKatas,
        overallCompletion,
        completionPercentage: overallCompletion, // Alias for compatibility
        totalTimeSpent,
        kataProgress,
        isCompleted: overallCompletion === 100,
        lastUpdated: Math.max(...kataProgress.map(p => p.lastUpdated || 0))
      };
    }, 'getCategoryProgress', {});
  }

  /**
   * Get training lab progress
   * @param {string} labId - Lab identifier
   * @returns {Object} Lab progress data
   */
  getLabProgress(labId) {
    return this.errorHandler.safeExecute(() => {
      const lab = this.detection.getTrainingLab(labId);
      if (!lab) {
        return { error: 'Lab not found', labId };
      }

      // Get lab progress from storage
      const progress = this.storage.getPathProgress(`lab-${labId}`);

      return {
        labId,
        lab,
        ...progress,
        isCompleted: progress.completionPercentage === 100
      };
    }, 'getLabProgress', {});
  }

  /**
   * Update kata progress (completion state) independently of selection state
   * @param {string} kataId - Kata identifier
   * @param {Object} progressData - Progress data
   * @returns {boolean} Success status
   */
  updateKataProgress(kataId, progressData) {
    return this.errorHandler.safeExecute(() => {
      // Validate input parameters
      if (!kataId || typeof kataId !== 'string' || kataId.trim() === '') {
        return false;
      }
      if (!progressData || typeof progressData !== 'object') {
        return false;
      }

      // Call the storage manager to save progress
      if (this.storage && typeof this.storage.setKataProgress === 'function') {
        this.storage.setKataProgress(kataId, progressData);
      }

      // Also update legacy storage if available
      if (this.storage && typeof this.storage.saveKataProgress === 'function') {
        const success = this.storage.saveKataProgress(kataId, progressData);
        return success;
      }

      return true;
    }, 'updateKataProgress', false);
  }

  /**
   * Update category-level tracking
   * @param {string} categoryId - Category identifier
   * @returns {boolean} Success status
   */
  updateCategoryTracking(categoryId) {
    return this.errorHandler.safeExecute(() => {
      const categoryProgress = this.getCategoryProgress(categoryId);

      // Store category summary
      const categoryData = {
        categoryId,
        completedKatas: categoryProgress.completedKatas,
        totalKatas: categoryProgress.totalKatas,
        overallCompletion: categoryProgress.overallCompletion,
        totalTimeSpent: categoryProgress.totalTimeSpent,
        isCompleted: categoryProgress.isCompleted,
        lastActivity: Date.now()
      };

      return this.storage.savePathProgress(`category-${categoryId}`, categoryData);
    }, 'updateCategoryTracking', false);
  }

  /**
   * Update training lab progress
   * @param {string} labId - Lab identifier
   * @param {Object} progressData - Progress data
   * @returns {boolean} Success status
   */
  updateLabProgress(labId, progressData) {
    return this.errorHandler.safeExecute(() => {
      const success = this.storage.savePathProgress(`lab-${labId}`, progressData);

      return success;
    }, 'updateLabProgress', false);
  }

  /**
   * Get next recommended kata in current category
   * @param {string|Object} categoryIdOrPathData - Category identifier or path data object
   * @param {string} currentKataId - Current kata identifier (when first param is string)
   * @returns {Object|string|null} Next kata information or kata ID
   */
  getNextKata(categoryIdOrPathData, currentKataId) {
    return this.errorHandler.safeExecute(() => {
      // Handle pathData object signature
      if (typeof categoryIdOrPathData === 'object' && categoryIdOrPathData !== null) {
        const pathData = categoryIdOrPathData;
        if (!pathData.katas || !Array.isArray(pathData.katas)) {
          return null;
        }

        const completedKatas = pathData.completedKatas || [];
        const nextKata = pathData.katas.find(kata => !completedKatas.includes(kata));
        return nextKata || null;
      }

      // Handle original signature (categoryId, currentKataId)
      const categoryId = categoryIdOrPathData;
      const nextKataId = this.detection.getNextKataInCategory(categoryId, currentKataId);

      if (nextKataId) {
        const fullKataId = `${categoryId}/${nextKataId}`;
        const progress = this.getKataProgress(fullKataId);

        return {
          categoryId,
          kataId: nextKataId,
          fullKataId,
          progress,
          isCompleted: progress.completionPercentage === 100
        };
      }

      return null;
    }, 'getNextKata', null);
  }

  /**
   * Get all category progress summary
   * @returns {Array} Array of category progress objects
   */
  getAllCategoryProgress() {
    return this.errorHandler.safeExecute(() => {
      const categories = this.detection.getAllKataCategories();

      return Object.keys(categories).map(categoryId => {
        const progress = this.getCategoryProgress(categoryId);
        return {
          ...progress,
          status: this.getCategoryStatus(progress)
        };
      });
    }, 'getAllCategoryProgress', []);
  }

  /**
   * Get all training lab progress summary
   * @returns {Array} Array of lab progress objects
   */
  getAllLabProgress() {
    return this.errorHandler.safeExecute(() => {
      const labs = this.detection.getAllTrainingLabs();

      return Object.keys(labs).map(labId => {
        const progress = this.getLabProgress(labId);
        return {
          ...progress,
          status: this.getLabStatus(progress)
        };
      });
    }, 'getAllLabProgress', []);
  }

  /**
   * Determine category status
   * @param {Object} categoryProgress - Category progress data
   * @returns {string} Status: 'not-started', 'in-progress', 'completed'
   */
  getCategoryStatus(categoryProgress) {
    if (categoryProgress.overallCompletion === 100) {return 'completed';}
    if (categoryProgress.completedKatas > 0) {return 'in-progress';}
    return 'not-started';
  }

  /**
   * Determine lab status
   * @param {Object} labProgress - Lab progress data
   * @returns {string} Status: 'not-started', 'in-progress', 'completed'
   */
  getLabStatus(labProgress) {
    if (labProgress.completionPercentage === 100) {return 'completed';}
    if (labProgress.startedAt) {return 'in-progress';}
    return 'not-started';
  }

  /**
   * Get learning analytics across all paths
   * @returns {Object} Comprehensive analytics
   */
  getLearningAnalytics() {
    return this.errorHandler.safeExecute(() => {
      const categoryProgress = this.getAllCategoryProgress();
      const labProgress = this.getAllLabProgress();

      // Category analytics
      const totalCategories = categoryProgress.length;
      const completedCategories = categoryProgress.filter(c => c.status === 'completed').length;
      const inProgressCategories = categoryProgress.filter(c => c.status === 'in-progress').length;

      // Lab analytics
      const totalLabs = labProgress.length;
      const completedLabs = labProgress.filter(l => l.status === 'completed').length;
      const inProgressLabs = labProgress.filter(l => l.status === 'in-progress').length;

      // Overall metrics
      const totalEstimatedHours = [
        ...Object.values(this.detection.getAllKataCategories()).map(c => c.estimatedHours),
        ...Object.values(this.detection.getAllTrainingLabs()).map(l => l.estimatedHours)
      ].reduce((sum, hours) => sum + hours, 0);

      const completedEstimatedHours = [
        ...categoryProgress.filter(c => c.status === 'completed').map(c => c.category.estimatedHours),
        ...labProgress.filter(l => l.status === 'completed').map(l => l.lab.estimatedHours)
      ].reduce((sum, hours) => sum + hours, 0);

      return {
        categories: {
          total: totalCategories,
          completed: completedCategories,
          inProgress: inProgressCategories,
          notStarted: totalCategories - completedCategories - inProgressCategories
        },
        labs: {
          total: totalLabs,
          completed: completedLabs,
          inProgress: inProgressLabs,
          notStarted: totalLabs - completedLabs - inProgressLabs
        },
        overall: {
          totalPaths: totalCategories + totalLabs,
          completedPaths: completedCategories + completedLabs,
          overallCompletion: Math.round(((completedCategories + completedLabs) / (totalCategories + totalLabs)) * 100),
          totalEstimatedHours,
          completedEstimatedHours,
          progressPercentage: Math.round((completedEstimatedHours / totalEstimatedHours) * 100)
        },
        categoryDetails: categoryProgress,
        labDetails: labProgress
      };
    }, 'getLearningAnalytics', {});
  }

  /**
   * Get recommended next learning activity
   * @returns {Object|null} Recommended activity
   */
  getRecommendedActivity() {
    return this.errorHandler.safeExecute(() => {
      const categoryProgress = this.getAllCategoryProgress();

      // Find in-progress categories first
      const inProgress = categoryProgress.filter(c => c.status === 'in-progress');
      if (inProgress.length > 0) {
        const category = inProgress[0];
        const nextKata = this.getNextUncompletedKata(category.categoryId);

        if (nextKata) {
          return {
            type: 'kata',
            categoryId: category.categoryId,
            categoryName: category.category.name,
            kataId: nextKata.kataId,
            fullKataId: nextKata.fullKataId,
            reason: 'Continue current learning path'
          };
        }
      }

      // Find not-started categories
      const notStarted = categoryProgress.filter(c => c.status === 'not-started');
      if (notStarted.length > 0) {
        const category = notStarted[0];
        const firstKata = category.category.katas[0];

        return {
          type: 'kata',
          categoryId: category.categoryId,
          categoryName: category.category.name,
          kataId: firstKata,
          fullKataId: `${category.categoryId}/${firstKata}`,
          reason: 'Start new learning path'
        };
      }

      return null;
    }, 'getRecommendedActivity', null);
  }

  /**
   * Get next uncompleted kata in category
   * @param {string} categoryId - Category identifier
   * @returns {Object|null} Next uncompleted kata
   */
  getNextUncompletedKata(categoryId) {
    return this.errorHandler.safeExecute(() => {
      const category = this.detection.getKataCategory(categoryId);
      if (!category) {return null;}

      for (const kataId of category.katas) {
        const fullKataId = `${categoryId}/${kataId}`;
        const progress = this.getKataProgress(fullKataId);

        if (progress.completionPercentage < 100) {
          return {
            kataId,
            fullKataId,
            progress
          };
        }
      }

      return null;
    }, 'getNextUncompletedKata', null);
  }

  /**
   * Get overall progress across all categories and labs
   * @returns {Object} Overall progress statistics
   */
  getOverallProgress() {
    return this.errorHandler.safeExecute(() => {
      const categoryProgress = this.getAllCategoryProgress();
      const labProgress = this.getAllLabProgress();

      const totalCategories = categoryProgress.length;
      const completedCategories = categoryProgress.filter(cat => cat.status === 'completed').length;
      const totalLabs = labProgress.length;
      const completedLabs = labProgress.filter(lab => lab.status === 'completed').length;

      const overallPercentage = totalCategories > 0 ?
        Math.round((completedCategories / totalCategories) * 100) : 0;

      return {
        overallPercentage,
        kataProgress: categoryProgress,
        labProgress: labProgress,
        categories: {
          total: totalCategories,
          completed: completedCategories,
          inProgress: categoryProgress.filter(cat => cat.status === 'in-progress').length,
          completion: overallPercentage
        },
        labs: {
          total: totalLabs,
          completed: completedLabs,
          completion: totalLabs > 0 ? Math.round((completedLabs / totalLabs) * 100) : 0
        },
        overall: {
          completion: overallPercentage
        }
      };
    }, 'getOverallProgress', {
      overallPercentage: 0,
      kataProgress: [],
      labProgress: [],
      categories: { total: 0, completed: 0, inProgress: 0, completion: 0 },
      labs: { total: 0, completed: 0, completion: 0 },
      overall: { completion: 0 }
    });
  }

  /**
   * Get learning recommendations based on current progress
   * @returns {Array} Array of recommended actions
   */
  getRecommendations() {
    return this.errorHandler.safeExecute(() => {
      const overallProgress = this.getOverallProgress();
      const currentContext = this.getCurrentContext();
      const recommendations = [];

      // If no progress, recommend starting with fundamentals
      if (overallProgress.overall.completion === 0) {
        recommendations.push({
          type: 'start',
          category: 'fundamentals',
          message: 'Start with fundamentals to build a strong foundation',
          priority: 'high'
        });
        return recommendations;
      }

      // Check current context for specific recommendations
      if (currentContext && currentContext.type === 'kata') {
        const nextKata = this.getNextUncompletedKata(currentContext.categoryId);
        if (nextKata) {
          recommendations.push({
            type: 'continue',
            category: currentContext.categoryId,
            kataId: nextKata.kataId,
            message: `Continue with next kata in ${currentContext.categoryId}`,
            priority: 'medium'
          });
        }
      }

      // If fundamentals completed, recommend advanced topics
      const fundamentalsProgress = this.getCategoryProgress('fundamentals');
      if (fundamentalsProgress && fundamentalsProgress.status === 'completed') {
        recommendations.push({
          type: 'advance',
          category: 'advanced',
          message: 'Ready for advanced topics',
          priority: 'medium'
        });
      }

      return recommendations.length > 0 ? recommendations : null;
    }, 'getRecommendations', null);
  }

  /**
   * Update path selection state independently of completion state
   * @param {string|Array|Object} kataIdOrSelections - Full kata identifier, array of selections, or dual state object
   * @param {boolean} [isSelected] - Whether the kata is selected (when first param is string)
   * @returns {boolean} True if update successful
   */
  updatePathSelection(kataIdOrSelections, isSelected) {
    return this.errorHandler.safeExecute(() => {
      // Handle dual state object with both selection and completion states
      if (kataIdOrSelections && typeof kataIdOrSelections === 'object' && !Array.isArray(kataIdOrSelections)) {
        const { kataId, selected, completed } = kataIdOrSelections;

        if (!kataId) {return false;}

        // Update selection state if provided
        if (typeof selected === 'boolean') {
          this._pathSelections[kataId] = selected;
          this.storage.setItem('learning-path-selections', this._pathSelections);
        }

        // Update completion state if provided
        if (typeof completed === 'boolean') {
          const progressData = { completionPercentage: completed ? 100 : 0 };
          this.updateKataProgress(kataId, progressData);
        }

        return true;
      }

      // Handle array of selections (bulk update for synchronization)
      if (Array.isArray(kataIdOrSelections)) {
        this._pathSelections = {};
        kataIdOrSelections.forEach(kataId => {
          if (kataId && typeof kataId === 'string') {
            this._pathSelections[kataId] = true;
          }
        });

        // Persist to storage
        this.storage.setItem('learning-path-selections', this._pathSelections);
        return true;
      }

      // Handle single selection
      const kataId = kataIdOrSelections;
      if (!kataId || typeof kataId !== 'string') {
        return false;
      }

      // Update internal state
      this._pathSelections[kataId] = isSelected;

      // Persist to storage
      this.storage.setItem('learning-path-selections', this._pathSelections);
      return true;
    }, 'updatePathSelection', false);
  }

  /**
   * Get related katas for auto-selection based on learning path name
   * @param {string} pathName - Learning path name (e.g., "Foundation Builder - AI Engineering")
   * @returns {Array<string>} Array of full kata IDs for auto-selection
   */
  getAutoSelectionItems(pathName) {
    return this.errorHandler.safeExecute(() => {
      if (!pathName || typeof pathName !== 'string') {
        return [];
      }

      const categories = this.detection.getAllKataCategories();
      const relatedKatas = [];

      // Search through all categories for path mappings
      Object.entries(categories).forEach(([categoryId, category]) => {
        if (category.pathMappings && category.pathMappings[pathName]) {
          const kataIds = category.pathMappings[pathName];
          kataIds.forEach(kataId => {
            relatedKatas.push(`${categoryId}/${kataId}`);
          });
        }
      });

      return relatedKatas;
    }, 'getAutoSelectionItems', []);
  }

  /**
   * Persist current path selections to storage
   * @returns {boolean} True if persistence successful
   */
  persistPathSelections() {
    return this.errorHandler.safeExecute(() => {
      const selections = this._pathSelections || {};
      this.storage.setItem('learning-path-selections', selections);
      return true;
    }, 'persistPathSelections', false);
  }

  /**
   * Get current path progress for dual checkbox UI synchronization
   * @returns {Object} Dual state progress data (selection and completion states)
   */
  getProgress() {
    return this.errorHandler.safeExecute(() => {
      // Get stored selection data
      const storedSelections = this.storage && typeof this.storage.getItem === 'function'
        ? this.storage.getItem('learning-path-selections')
        : null;

      // Get stored progress data
      const progressData = this.storage && typeof this.storage.getItem === 'function'
        ? this.storage.getItem('learning_progress_data')
        : null;

      // Get all stored progress to build completion state (only if method exists)
      let allProgress = {};
      if (this.storage && typeof this.storage.getAllProgress === 'function') {
        try {
          allProgress = this.storage.getAllProgress();
        } catch {
          // If getAllProgress fails, continue with empty object
          allProgress = {};
        }
      }

      const completionState = {};
      if (allProgress && typeof allProgress === 'object') {
        Object.entries(allProgress).forEach(([id, progress]) => {
          if (progress && typeof progress.completionPercentage === 'number') {
            completionState[id] = progress.completionPercentage >= 100;
          }
        });
      }

      return {
        pathSelections: storedSelections || {},
        progressData: progressData || {},
        timestamp: new Date().toISOString()
      };
    }, 'getProgress', {});
  }

  /**
   * Synchronize progress data from external source
   * @param {Object} progressData - Progress data to synchronize
   * @returns {Promise<boolean>} Success status
   */
  async syncProgress(progressData) {
    return this.errorHandler.safeExecute(async () => {
      if (!progressData || typeof progressData !== 'object') {
        return false;
      }

      // Update path selections if provided
      if (progressData.pathSelections) {
        this._pathSelections = { ...progressData.pathSelections };
        this.storage.setItem('learning-path-selections', this._pathSelections);
      }

      // Update other progress data if provided
      if (progressData.progressData) {
        this.storage.setItem('learning_progress_data', progressData.progressData);
      }

      return true;
    }, 'syncProgress', false);
  }

  /**
   * Initialize the learning path manager
   * @async
   * @returns {Promise<boolean>} True if initialization successful
   */
  async init() {
    return this.errorHandler.safeExecute(async () => {
      await this.loadPathSelections();
      this.isInitialized = true;
      return true;
    }, 'init', false);
  }

  /**
   * Get default configuration
   * @returns {Object} Default configuration object
   */
  getDefaultConfig() {
    return {
      maxRetries: 3,
      timeout: 5000,
      enableDebug: false,
      storageKey: 'learning-paths'
    };
  }

  /**
   * Get default configuration
   * @returns {Object} Default configuration object
   */
  get config() {
    return this._config || this.getDefaultConfig();
  }

  /**
   * Load learning paths from storage
   * @returns {Array} Array of learning paths
   */
  loadLearningPaths() {
    return this.errorHandler.safeExecute(() => {
      const paths = this.storage?.getAllProgress() || [];
      return Array.isArray(paths) ? paths : [];
    }, 'loadLearningPaths', []);
  }

  /**
   * Save progress for a learning path
   * @param {Object} pathData - Path progress data
   * @returns {boolean} True if save successful
   */
  saveProgress(pathData) {
    return this.errorHandler.safeExecute(() => {
      if (!pathData || !pathData.id) {return false;}

      return this.storage?.setKataProgress(pathData.id, pathData) || false;
    }, 'saveProgress', false);
  }

  /**
   * Validate learning path structure
   * @param {Object} path - Path to validate
   * @returns {boolean} True if valid
   */
  validatePath(path) {
    return this.errorHandler.safeExecute(() => {
      if (!path || typeof path !== 'object') {return false;}
      if (!path.id || typeof path.id !== 'string') {return false;}
      if (!path.title || typeof path.title !== 'string') {return false;}
      if (!Array.isArray(path.katas)) {return false;}

      return path.katas.every(kata => {
        // Handle both string IDs and objects with id property
        if (typeof kata === 'string') {
          return kata.length > 0;
        }
        return kata.id && typeof kata.id === 'string';
      });
    }, 'validatePath', false);
  }

  /**
   * Validate learning path dependencies
   * @param {Object} path - Path with dependencies to validate
   * @returns {boolean} True if dependencies are valid
   */
  validateDependencies(path) {
    return this.errorHandler.safeExecute(() => {
      if (!path || !path.katas) {return false;}

      // Simple validation - check that dependencies exist in the path
      return path.katas.every(kata => {
        if (!kata.dependencies) {return true;}
        return kata.dependencies.every(depId =>
          path.katas.some(k => k.id === depId)
        );
      });
    }, 'validateDependencies', false);
  }

  /**
   * Get recommendations filtered by difficulty
   * @param {string} difficulty - Difficulty level to filter by
   * @returns {Array} Filtered recommendations
   */
  getRecommendationsByDifficulty(difficulty) {
    return this.errorHandler.safeExecute(() => {
      const allRecommendations = this.getRecommendations() || [];
      return allRecommendations.filter(rec =>
        rec.difficulty === difficulty
      );
    }, 'getRecommendationsByDifficulty', []);
  }

  /**
   * Update configuration
   * @param {Object} newConfig - Configuration updates
   * @returns {boolean} True if update successful
   */
  updateConfig(newConfig) {
    return this.errorHandler.safeExecute(() => {
      if (!newConfig || typeof newConfig !== 'object') {return false;}

      this._config = { ...this.config, ...newConfig };
      return true;
    }, 'updateConfig', false);
  }

  /**
   * Calculate overall progress for a learning path
   * @param {Object} pathData - Learning path data
   * @returns {number} Progress percentage (0-100)
   */
  calculateProgress(pathData) {
    return this.errorHandler.safeExecute(() => {
      if (!pathData || !pathData.katas || !Array.isArray(pathData.katas)) {
        return 0;
      }

      if (pathData.katas.length === 0) {
        return 0;
      }

      const completedKatas = pathData.completedKatas || [];
      const progressPercentage = (completedKatas.length / pathData.katas.length) * 100;

      return Math.round(progressPercentage * 100) / 100; // Round to 2 decimal places
    }, 'calculateProgress', 0);
  }

  /**
   * Get current learning context for coach integration
   * @returns {Object} Current learning context with path, progress, and recommendations
   */
  getCoachContext() {
    return this.errorHandler.safeExecute(() => {
      const currentContext = this.getCurrentContext();
      const progress = this.getOverallProgress();
      const recommendations = this.getRecommendations();
      const pathSelections = this.getPathSelections();

      return {
        context: currentContext,
        progress: progress,
        recommendations: recommendations,
        selections: pathSelections,
        timestamp: new Date().toISOString()
      };
    }, 'getCoachContext', {});
  }

  /**
   * Format coach context for VS Code integration
   * @returns {string} Formatted context string for coach
   */
  formatCoachMessage() {
    return this.errorHandler.safeExecute(() => {
      const context = this.getCoachContext();

      let message = "Learning Path Assistant Context:\n\n";

      // Current learning activity
      if (context.context && context.context.currentKata) {
        message += `Current Activity: ${context.context.currentKata.title}\n`;
        message += `Category: ${context.context.currentKata.category}\n`;
        message += `Progress: ${context.context.currentKata.progress}%\n\n`;
      }

      // Overall progress
      if (context.progress) {
        message += `Overall Progress:\n`;
        message += `- Completed Katas: ${context.progress.completedKatas}\n`;
        message += `- Total Katas: ${context.progress.totalKatas}\n`;
        message += `- Progress: ${context.progress.percentage}%\n\n`;
      }

      // Selected learning paths
      if (context.selections && Object.keys(context.selections).length > 0) {
        message += `Selected Learning Paths:\n`;
        Object.entries(context.selections).forEach(([path, selected]) => {
          if (selected) {
            message += `- ${path}\n`;
          }
        });
        message += "\n";
      }

      // Recommendations
      if (context.recommendations && context.recommendations.length > 0) {
        message += `Recommended Next Steps:\n`;
        context.recommendations.slice(0, 3).forEach(rec => {
          message += `- ${rec.title} (${rec.category})\n`;
        });
      }

      return message;
    }, 'formatCoachMessage', 'No learning context available.');
  }

  /**
   * Get path selections for coach integration
   * @returns {Object} Current path selections
   */
  getPathSelections() {
    return this.errorHandler.safeExecute(() => {
      return this._pathSelections || {};
    }, 'getPathSelections', {});
  }

  /**
   * Update multiple path selections from auto-selection engine
   * @param {Object} selectionUpdate - Auto-selection update object
   * @param {string} selectionUpdate.pathId - Main path ID
   * @param {Array<string>} selectionUpdate.autoSelectedItems - Auto-selected items
   * @param {Array<string>} selectionUpdate.suggestedRelated - Suggested related paths
   * @returns {boolean} Success state
   */
  updatePathSelections(selectionUpdate) {
    return this.errorHandler.safeExecute(() => {
      if (!selectionUpdate || !selectionUpdate.pathId) {
        return false;
      }

      const { pathId, autoSelectedItems, suggestedRelated } = selectionUpdate;

      // Update main path selection
      const mainResult = this.updatePathSelection(pathId, true);
      if (!mainResult) {
        return false;
      }

      // Store auto-selected items for this path
      if (!this._autoSelectedItems) {
        this._autoSelectedItems = {};
      }
      this._autoSelectedItems[pathId] = autoSelectedItems || [];

      // Store suggested related paths
      if (!this._suggestedPaths) {
        this._suggestedPaths = {};
      }
      this._suggestedPaths[pathId] = suggestedRelated || [];

      // Persist the auto-selection data
      if (this.storage) {
        this.storage.setItem('auto-selected-items', this._autoSelectedItems);
        this.storage.setItem('suggested-paths', this._suggestedPaths);
      }

      // Notify about auto-selection updates
      this._notifyAutoSelectionChange(pathId, autoSelectedItems, suggestedRelated);

      return true;
    }, 'updatePathSelections', false);
  }

  /**
   * Persist progress state to storage
   * @returns {boolean} Success state
   */
  persistProgressState() {
    return this.errorHandler.safeExecute(() => {
      if (!this.storage) {
        return false;
      }

      // Persist all kata progress to storage
      // The progress is already being saved individually via updateKataProgress
      // This method ensures bulk synchronization if needed
      return true;
    }, 'persistProgressState', false);
  }

  /**
   * Load path selections from API (primary) or storage (fallback)
   * @async
   * @returns {Promise<boolean>} Success state
   */
  async loadPathSelections() {
    return this.errorHandler.safeExecute(async () => {
      if (!this.storage) {
        return false;
      }

      try {
        // Fetch from API (same endpoint as catalog page)
        const API_BASE = 'http://localhost:3002/api';
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000);

        const response = await fetch(`${API_BASE}/learning/selections?userId=default-user`, {
          signal: controller.signal
        });
        clearTimeout(timeoutId);

        if (response.ok) {
          const { data } = await response.json();
          const selectedItems = data?.selections?.selectedItems || [];

          // Convert array to object format {itemId: true}
          this._pathSelections = {};
          selectedItems.forEach(itemId => {
            this._pathSelections[itemId] = true;
          });

          // Cache to localStorage for offline use
          this.storage.setItem('learning-path-selections', this._pathSelections);

          if (this.debugHelper) {
            this.debugHelper.log(`Loaded ${selectedItems.length} selections from API`, 'PathManager');
          }

          return true;
        }
      } catch (error) {
        // Fallback to localStorage on fetch error
        if (this.debugHelper) {
          this.debugHelper.warn('Failed to load selections from API, using localStorage fallback', 'PathManager');
        }
      }

      // Fallback to localStorage
      const stored = this.storage.getItem('learning-path-selections');
      if (stored) {
        this._pathSelections = stored;
      } else {
        this._pathSelections = {};
      }

      return true;
    }, 'loadPathSelections', false);
  }

  /**
   * Get kata progress data for a specific kata
   * @async
   * @param {string} kataId - Kata identifier
   * @returns {Promise<Object>} Progress data with completion percentage, tasks, etc.
   */
  async getKataProgress(kataId) {
    return this.errorHandler.safeExecute(async () => {
      // Check cache first
      if (this._progressCache.has(kataId)) {
        return this._progressCache.get(kataId);
      }

      // Default progress structure
      const defaultProgress = {
        kataId,
        completedTasks: 0,
        totalTasks: 0,
        completionPercentage: 0,
        lastUpdated: null,
        sections: {},
        metadata: {}
      };

      try {
        // Fetch from API
        const API_BASE = 'http://localhost:3002/api';
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000);

        const response = await fetch(`${API_BASE}/progress/load/kata/${encodeURIComponent(kataId)}`, {
          signal: controller.signal
        });
        clearTimeout(timeoutId);

        if (response.ok) {
          const result = await response.json();
          const progressData = result.data || defaultProgress;

          // Cache the result
          this._progressCache.set(kataId, progressData);

          return progressData;
        }

        // API call failed, return default
        return defaultProgress;
      } catch (error) {
        if (this.debugHelper) {
          this.debugHelper.warn(`Failed to fetch progress for ${kataId}: ${error.message}`, 'PathManager');
        }
        return defaultProgress;
      }
    }, 'getKataProgress', {});
  }

  /**
   * Get all kata progress data
   * @returns {Array} Array of all kata progress objects
   */
  getAllKataProgress() {
    return this.errorHandler.safeExecute(() => {
      if (!this.storage || !this.storage.getAllKataProgress) {
        return [];
      }

      return this.storage.getAllKataProgress();
    }, 'getAllKataProgress', []);
  }

  /**
   * Internal method to notify path selection changes
   * @private
   * @param {string} pathId - Path identifier
   * @param {boolean} selected - Selection state
   */
  _notifyPathSelectionChange(pathId, selected) {
    // This would trigger any registered UI update callbacks
    // For now, just log the change for debugging
    if (this.debugHelper) {
      this.debugHelper.log(`Path selection changed: ${pathId} = ${selected}`, 'PathManager');
    }
  }

  /**
   * Notify about auto-selection changes
   * @private
   * @param {string} pathId - Path identifier
   * @param {Array<string>} autoSelectedItems - Auto-selected items
   * @param {Array<string>} suggestedRelated - Suggested related paths
   */
  _notifyAutoSelectionChange(pathId, autoSelectedItems, suggestedRelated) {
    // This would trigger any registered UI update callbacks
    // For now, just log the change for debugging
    if (this.debugHelper) {
      this.debugHelper.log(`Auto-selection for ${pathId}: ${autoSelectedItems?.length || 0} items, ${suggestedRelated?.length || 0} suggested`, 'PathManager');
    }
  }

  /**
   * Internal method to get related path items
   * @private
   * @param {string} pathId - Path identifier or path name
   * @returns {Array} Related items
   */
  _getRelatedPathItems(pathId) {
    // Try to get all kata categories and their path mappings
    if (this.detection && typeof this.detection.getAllKataCategories === 'function') {
      try {
        const allCategories = this.detection.getAllKataCategories();

        // Search through categories for path mappings
        for (const [categoryId, categoryData] of Object.entries(allCategories)) {
          if (categoryData.pathMappings && categoryData.pathMappings[pathId]) {
            // Found a mapping for this path name, return the full kata IDs
            return categoryData.pathMappings[pathId].map(kataId =>
              `${categoryId}/${kataId}`
            );
          }
        }
      } catch (_error) {
        // Fall back to static mapping if detection fails
      }
    }

    // Fallback to static relationship mapping
    const pathMappings = {
      'ai-assisted-engineering': [
        'ai-assisted-engineering/01-ai-development-fundamentals',
        'ai-assisted-engineering/02-prompt-engineering'
      ],
      'project-planning': [
        'project-planning/01-basic-prompt-usage',
        'project-planning/02-advanced-planning'
      ]
    };

    // Extract base path from full path ID
    const basePath = pathId.split('/')[0];

    return pathMappings[basePath] || [];
  }

  /**
   * Clean up resources and event listeners
   */
  destroy() {
    if (!this.errorHandler || typeof this.errorHandler.safeExecute !== 'function') {
      // If errorHandler is already null/cleared, do direct cleanup
      this.isInitialized = false;
      this._pathSelections = undefined;
      this.debugHelper = null;
      this.errorHandler = null;
      this.storage = null;
      this.detection = null;
      return true;
    }

    return this.errorHandler.safeExecute(() => {
      // Mark as not initialized
      this.isInitialized = false;

      // Clear UI-specific state
      this._pathSelections = undefined;

      // Clear any timers or intervals
      // Remove event listeners
      // Clean up references
      this.debugHelper = null;
      this.errorHandler = null;
      this.storage = null;
      this.detection = null;

      return true;
    }, 'destroy', false);
  }
}
