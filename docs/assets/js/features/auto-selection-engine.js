/**
 * Auto-Selection Engine
 * Intelligent auto-selection logic for learning paths and related items
 *
 * Provides sophisticated algorithms for:
 * - Learning path auto-selection of related katas and labs
 * - Smart dependency handling for prerequisite items
 * - Conflict resolution for overlapping path selections
 * - Relationship mapping and path structure validation
 *
 * @class AutoSelectionEngine
 * @author Edge AI Team
 * @version 1.0.0
 */

/**
 * AutoSelectionEngine manages intelligent auto-selection of learning paths and items
 *
 * Features:
 * - Path relationship discovery and mapping
 * - Dependency chain resolution with cycle detection
 * - Conflict resolution based on user level and preferences
 * - Performance-optimized with caching and batch operations
 * - Integration with Learning Path Manager for real-time updates
 *
 * @example
 * ```javascript
 * const autoEngine = new AutoSelectionEngine({
 *   learningPathManager: pathManager,
 *   errorHandler: errorHandler,
 *   debugHelper: debugHelper,
 *   pathRelationships: relationships
 * });
 *
 * const result = autoEngine.processPathSelection(
 *   ['foundation-ai-engineering'],
 *   {},
 *   'Beginner'
 * );
 * ```
 */
export class AutoSelectionEngine {
  /**
   * Create an AutoSelectionEngine instance
   * @param {Object} dependencies - Required dependencies
   * @param {Object} dependencies.learningPathManager - Learning path manager instance
   * @param {Object} dependencies.errorHandler - Error handler instance
   * @param {Object} dependencies.debugHelper - Debug helper instance (optional)
   * @param {Object} dependencies.pathRelationships - Path relationship data (optional)
   * @param {Object} dependencies.config - Custom configuration (optional)
   * @throws {Error} When required dependencies are missing
   */
  constructor({ learningPathManager, errorHandler, debugHelper, pathRelationships, config }) {
    this._validateDependencies(learningPathManager, errorHandler);
    this._initializeComponents(learningPathManager, errorHandler, debugHelper);
    this._initializeConfiguration(pathRelationships, config);
    this._initializeState();
    this._initializeDerivedData();
  }

  /**
   * Validates required dependencies during construction
   * @param {Object} learningPathManager - Learning path manager instance
   * @param {Object} errorHandler - Error handler instance
   * @throws {Error} When required dependencies are missing
   * @private
   */
  _validateDependencies(learningPathManager, errorHandler) {
    if (!learningPathManager) {
      throw new Error('AutoSelectionEngine requires learningPathManager dependency');
    }
    if (!errorHandler || typeof errorHandler.safeExecute !== 'function') {
      throw new Error('AutoSelectionEngine requires errorHandler dependency');
    }
  }

  /**
   * Initializes core components and dependencies
   * @param {Object} learningPathManager - Learning path manager instance
   * @param {Object} errorHandler - Error handler instance
   * @param {Object} debugHelper - Debug helper instance (optional)
   * @private
   */
  _initializeComponents(learningPathManager, errorHandler, debugHelper) {
    this.learningPathManager = learningPathManager;
    this.errorHandler = errorHandler;
    this.debugHelper = debugHelper || this._createDefaultDebugHelper();
  }

  /**
   * Initializes configuration and path relationships
   * @param {Object} pathRelationships - Path relationship data (optional)
   * @param {Object} config - Custom configuration (optional)
   * @private
   */
  _initializeConfiguration(pathRelationships, config) {
    this.pathRelationships = pathRelationships || this._getDefaultPathRelationships();
    this.config = this._mergeConfig(config);
  }

  /**
   * Initializes internal state and caches
   * @private
   */
  _initializeState() {
    this.isDestroyed = false;
    this._relatedPathsCache = new Map();
    this._dependencyCache = new Map();
    this._registeredComponents = {
      checkbox: null,
      annotations: null,
      coach: null
    };
  }

  /**
   * Process path selection and generate auto-selections
   * @param {Array<string>|Object} selectedPathsOrOptions - Selected path IDs or options object
   * @param {Object} [currentProgress] - Current user progress (when using separate parameters)
   * @param {string} [userLevel] - User's skill level (when using separate parameters)
   * @returns {Object} Processing result
   */
  processPathSelection(selectedPathsOrOptions, currentProgress, userLevel) {
    if (this.isDestroyed) {
      throw new Error('AutoSelectionEngine has been destroyed');
    }

    try {
      const { selectedPaths, progress, level } = this._parseSelectionParameters(
        selectedPathsOrOptions,
        currentProgress,
        userLevel
      );

      const result = this._initializeResult();
      const validPaths = this._validateSelectedPaths(selectedPaths, result);

      if (validPaths.length === 0) {
        return result;
      }

      // Process conflicts and auto-selections
      result.conflicts = this._detectConflicts(validPaths, level);
      this._processAutoSelections(validPaths, progress, level, result);

      return this._finalizeResult(result);
    } catch (error) {
      this.errorHandler.recordError('AutoSelectionEngine.processPathSelection', error);
      throw error;
    }
  }

  /**
   * Parses and validates input parameters for path selection
   * @param {Array<string>|Object} selectedPathsOrOptions - Input parameter
   * @param {Object} currentProgress - Progress data
   * @param {string} userLevel - User skill level
   * @returns {Object} Parsed parameters
   * @private
   */
  _parseSelectionParameters(selectedPathsOrOptions, currentProgress, userLevel) {
    let selectedPaths, progress, level;

    if (Array.isArray(selectedPathsOrOptions)) {
      // Called with separate parameters (test style)
      selectedPaths = selectedPathsOrOptions;
      progress = currentProgress;
      level = userLevel || 'Beginner';
    } else if (typeof selectedPathsOrOptions === 'object' && selectedPathsOrOptions !== null) {
      // Called with options object
      const options = selectedPathsOrOptions;
      selectedPaths = options.selectedPaths;
      progress = options.currentProgress;
      level = options.userLevel || 'Beginner';
    } else {
      throw new Error('First parameter must be an array of selectedPaths or an options object');
    }

    // Progress must be provided for sync operation
    // Use processPathSelectionWithProgress() for async progress fetching
    if (!progress) {
      progress = {};
    }

    // Validate progress data
    this._validateProgressDataIfPresent(progress);

    if (!Array.isArray(selectedPaths)) {
      throw new Error('selectedPaths must be an array');
    }

    return { selectedPaths, progress, level };
  }

  /**
   * Initializes the result object structure
   * @returns {Object} Initialized result object
   * @private
   */
  _initializeResult() {
    return {
      autoSelectedItems: [],
      suggestedRelated: [],
      conflicts: [],
      warnings: [],
      errors: []
    };
  }

  /**
   * Validates selected paths and filters out invalid ones
   * @param {Array<string>} selectedPaths - Path IDs to validate
   * @param {Object} result - Result object to add warnings to
   * @returns {Array<string>} Valid path IDs
   * @private
   */
  _validateSelectedPaths(selectedPaths, result) {
    const validPaths = [];

    for (const pathId of selectedPaths) {
      const pathData = this.pathRelationships[pathId];
      if (!pathData) {
        result.warnings.push({
          type: 'invalid_path_id',
          message: `Path "${pathId}" not found`,
          pathId
        });
        continue;
      }

      // Check for incomplete path data
      if (!this._isPathDataComplete(pathData)) {
        result.warnings.push({
          type: 'incomplete_path_data',
          message: `Path "${pathId}" has incomplete data`,
          pathId
        });
      }

      validPaths.push(pathId);
    }

    // Check for circular dependencies
    for (const pathId of validPaths) {
      const circularCheck = this._checkPathCircularDependencies(pathId);
      if (circularCheck.hasCircular && circularCheck.circularPaths.length > 0) {
        result.errors.push({
          type: 'circular_dependency',
          message: 'Circular dependency detected',
          paths: circularCheck.circularPaths
        });
        break; // Only report the first circular dependency found
      }
    }

    return validPaths;
  }

  /**
   * Validates progress data if present
   * @param {Object} progress - Progress data to validate
   * @private
   */
  _validateProgressDataIfPresent(progress) {
    if (progress && typeof progress === 'object') {
      try {
        this._validateProgressData(progress);
      } catch (error) {
        this.errorHandler.recordError?.('malformed_progress_data', {
          error: error.message,
          progress: progress
        });
      }
    }
  }

  /**
   * Processes auto-selections for valid paths
   * @param {Array<string>} validPaths - Valid path IDs
   * @param {Object} progress - User progress data
   * @param {string} level - User skill level
   * @param {Object} result - Result object to populate
   * @private
   */
  _processAutoSelections(validPaths, progress, level, result) {
    for (const pathId of validPaths) {
      if (!this._isAutoSelectionEnabled()) {
        continue;
      }

      // Validate path data completeness
      const pathData = this.pathRelationships[pathId];
      if (!pathData || !this._isPathDataComplete(pathData)) {
        result.warnings.push({
          type: 'incomplete_path_data',
          pathId: pathId,
          message: `Path "${pathId}" has incomplete relationship data`
        });
        continue;
      }

      // Check for circular dependencies
      const circularCheck = this._checkPathCircularDependencies(pathId);
      if (circularCheck.hasCircular) {
        result.errors = result.errors || [];
        result.errors.push({
          type: 'circular_dependency',
          paths: circularCheck.circularPaths,
          message: `Circular dependency detected involving path "${pathId}"`
        });
        continue;
      }

      // Validate prerequisites
      if (!this._validatePathPrerequisites(pathId, progress, result)) {
        continue;
      }

      // Auto-select items and get suggestions
      const autoSelected = this._getAutoSelectedItems(pathId, progress, level);
      const related = this._getSuggestedRelated(pathId, validPaths, level);

      result.autoSelectedItems.push(...autoSelected);
      result.suggestedRelated.push(...related);
    }
  }

  /**
   * Validates prerequisites for a single path
   * @param {string} pathId - Path ID to validate
   * @param {Object} progress - User progress data
   * @param {Object} result - Result object to add warnings to
   * @returns {boolean} True if prerequisites are valid
   * @private
   */
  _validatePathPrerequisites(pathId, progress, result) {
    const prerequisiteValidation = this._validatePrerequisites(pathId, progress);
    if (!prerequisiteValidation.isValid) {
      result.warnings.push({
        type: 'missing_prerequisite',
        message: `Path "${pathId}" requires prerequisite path "${prerequisiteValidation.missingPrerequisites[0]}"`,
        pathId,
        missingPrerequisite: prerequisiteValidation.missingPrerequisites[0]
      });
      return false;
    }
    return true;
  }

  /**
   * Finalizes the result by removing duplicates
   * @param {Object} result - Result object to finalize
   * @returns {Object} Finalized result
   * @private
   */
  _finalizeResult(result) {
    result.autoSelectedItems = [...new Set(result.autoSelectedItems)];
    result.suggestedRelated = [...new Set(result.suggestedRelated)];
    return result;
  }

  /**
   * Detect conflicts between selected paths
   * @private
   * @param {Array<string>} selectedPaths - Selected path IDs
   * @param {string} userLevel - User level
   * @returns {Array<Object>} Array of conflicts
   */
  _detectConflicts(selectedPaths, userLevel) {
    const conflicts = [];

    // Check for conflicts between each pair of selected paths
    for (let i = 0; i < selectedPaths.length; i++) {
      for (let j = i + 1; j < selectedPaths.length; j++) {
        const conflictResult = this._checkPathPairConflict(
          selectedPaths[i],
          selectedPaths[j],
          userLevel
        );

        if (conflictResult) {
          conflicts.push(conflictResult);
        }
      }
    }

    return conflicts;
  }

  /**
   * Check if two specific paths conflict with each other
   * @private
   * @param {string} pathIdA - First path ID
   * @param {string} pathIdB - Second path ID
   * @param {string} userLevel - User level
   * @returns {Object|null} Conflict object or null if no conflict
   */
  _checkPathPairConflict(pathIdA, pathIdB, userLevel) {
    const pathDataA = this.pathRelationships[pathIdA];
    const pathDataB = this.pathRelationships[pathIdB];

    // Skip if either path data is missing
    if (!pathDataA || !pathDataB) {
      return null;
    }

    // Check if these paths conflict with each other
    const isConflict = this._checkPathsConflict(pathDataA, pathDataB, userLevel);

    if (isConflict) {
      return {
        type: 'level_conflict',
        message: `Path "${pathIdA}" (${pathDataA.level}) conflicts with "${pathIdB}" (${pathDataB.level})`,
        conflictingPaths: [pathIdA, pathIdB]
      };
    }

    return null;
  }

  /**
   * Check if two paths conflict with each other
   * @private
   * @param {Object} pathDataA - First path data
   * @param {Object} pathDataB - Second path data
   * @param {string} userLevel - User level
   * @returns {boolean} True if paths conflict
   */
  _checkPathsConflict(pathDataA, pathDataB, userLevel) {
    // Check for level conflicts (Beginner vs Advanced)
    if (this._isLevelConflict(pathDataA.level, pathDataB.level, userLevel)) {
      return true;
    }

    // Check for explicit conflicts in path data
    return this._hasExplicitConflict(pathDataA, pathDataB);
  }

  /**
   * Check if paths have explicit conflict definitions
   * @private
   * @param {Object} pathDataA - First path data
   * @param {Object} pathDataB - Second path data
   * @returns {boolean} True if explicit conflict exists
   */
  _hasExplicitConflict(pathDataA, pathDataB) {
    // Check if path A explicitly conflicts with path B
    if (pathDataA.conflicts && pathDataA.conflicts.includes(pathDataB.id)) {
      return true;
    }

    // Check if path B explicitly conflicts with path A
    if (pathDataB.conflicts && pathDataB.conflicts.includes(pathDataA.id)) {
      return true;
    }

    return false;
  }

  /**
   * Get auto-selected items for a specific path
   * @private
   * @param {string} pathId - Path ID
   * @param {Object} currentProgress - Current progress data
   * @param {string} userLevel - User level
   * @returns {Array<string>} Auto-selected items
   */
  _getAutoSelectedItems(pathId, currentProgress, _userLevel) {
    const pathData = this.pathRelationships[pathId];

    // Early return if no auto-select items
    if (!this._hasAutoSelectItems(pathData)) {
      return [];
    }

    // Filter out already completed or in-progress items
    return this._filterAvailableItems(pathData.autoSelectItems, currentProgress);
  }

  /**
   * Checks if path data has auto-select items
   * @param {Object} pathData - Path data object
   * @returns {boolean} True if path has auto-select items
   * @private
   */
  _hasAutoSelectItems(pathData) {
    return pathData &&
           pathData.autoSelectItems &&
           Array.isArray(pathData.autoSelectItems) &&
           pathData.autoSelectItems.length > 0;
  }

  /**
   * Filters out completed or in-progress items
   * @param {Array<string>} items - Items to filter
   * @param {Object} currentProgress - Current progress data
   * @returns {Array<string>} Available items
   * @private
   */
  _filterAvailableItems(items, currentProgress) {
    return items.filter(item => {
      const progress = currentProgress[item];
      return !progress || (!progress.completed && !progress.inProgress);
    });
  }

  /**
   * Get suggested related paths
   * @private
   * @param {string} pathId - Path ID
   * @param {Array<string>} selectedPaths - Already selected paths
   * @param {string} userLevel - User level
   * @returns {Array<string>} Suggested related paths
   */
  _getSuggestedRelated(pathId, selectedPaths, userLevel) {
    const pathData = this.pathRelationships[pathId];
    if (!pathData || !pathData.relatedPaths) {
      return [];
    }

    // Filter out already selected paths and inappropriate level paths
    return pathData.relatedPaths.filter(relatedPath => {
      if (selectedPaths.includes(relatedPath)) {
        return false;
      }

      const relatedData = this.pathRelationships[relatedPath];
      if (!relatedData) {
        return false;
      }

      return this._isPathAppropriateForLevel(relatedData, userLevel);
    });
  } /**
   * Validate prerequisites for a single path
   * @private
   * @param {string} pathId - Path ID to validate
   * @param {Object} currentProgress - Current progress data
   * @returns {Object} Validation result
   */
  _validatePrerequisites(pathId, currentProgress) {
    const pathData = this.pathRelationships[pathId];

    // Early return if no prerequisites
    if (!this._hasPrerequisites(pathData)) {
      return { isValid: true, missingPrerequisites: [] };
    }

    const missingPrerequisites = this._findMissingPrerequisites(
      pathData.prerequisites,
      currentProgress
    );

    return {
      isValid: missingPrerequisites.length === 0,
      missingPrerequisites
    };
  }

  /**
   * Checks if path data has prerequisites
   * @param {Object} pathData - Path data object
   * @returns {boolean} True if path has prerequisites
   * @private
   */
  _hasPrerequisites(pathData) {
    return pathData &&
           pathData.prerequisites &&
           Array.isArray(pathData.prerequisites) &&
           pathData.prerequisites.length > 0;
  }

  /**
   * Finds missing prerequisites from a list
   * @param {Array<string>} prerequisites - Prerequisites to check
   * @param {Object} currentProgress - Current progress data
   * @returns {Array<string>} Missing prerequisite IDs
   * @private
   */
  _findMissingPrerequisites(prerequisites, currentProgress) {
    const missingPrerequisites = [];

    for (const prerequisite of prerequisites) {
      if (!this._isPrerequisiteSatisfied(prerequisite, currentProgress)) {
        missingPrerequisites.push(prerequisite);
      }
    }

    return missingPrerequisites;
  }

  /**
   * Checks if a single prerequisite is satisfied
   * @param {string} prerequisite - Prerequisite path ID
   * @param {Object} currentProgress - Current progress data
   * @returns {boolean} True if prerequisite is satisfied
   * @private
   */
  _isPrerequisiteSatisfied(prerequisite, currentProgress) {
    const prerequisiteData = this.pathRelationships[prerequisite];

    if (!prerequisiteData) {
      return false;
    }

    // Check if any items from the prerequisite path are completed
    return prerequisiteData.autoSelectItems &&
           prerequisiteData.autoSelectItems.some(item =>
             currentProgress[item] && currentProgress[item].completed
           );
  } /**
   * Validate prerequisites for given paths
   * @param {Array<string>} pathIds - Path IDs to validate
   * @param {Object} progress - Current progress data
   * @returns {Object} Validation result with missing prerequisites and dependencies
   */
  validatePrerequisites(pathIds, progress) {
    return this.errorHandler.safeExecute(() => {
      const result = {
        isValid: true,
        missingPrerequisites: [],
        missingDependencies: [],
        warnings: []
      };

      for (const pathId of pathIds) {
        const pathData = this.pathRelationships[pathId];
        if (!pathData) {
          result.warnings.push(`Unknown path: ${pathId}`);
          continue;
        }

        // Check prerequisite paths
        if (pathData.prerequisites && pathData.prerequisites.length > 0) {
          for (const prereqPath of pathData.prerequisites) {
            if (!this.pathRelationships[prereqPath]) {
              result.missingPrerequisites.push(prereqPath);
              result.isValid = false;
            } else {
              // Check if prerequisite path has completed items in progress
              const prereqData = this.pathRelationships[prereqPath];
              const hasCompletedItems = prereqData.autoSelectItems &&
                prereqData.autoSelectItems.some(item =>
                  progress[item] && progress[item].completed
                );

              if (!hasCompletedItems) {
                result.missingPrerequisites.push(prereqPath);
                result.isValid = false;
              }
            }
          }
        }

        // Check dependency katas
        if (pathData.dependencies && pathData.dependencies.length > 0) {
          for (const depKata of pathData.dependencies) {
            if (!progress[depKata] || !progress[depKata].completed) {
              result.missingDependencies.push(depKata);
              result.isValid = false;
            }
          }
        }
      }

      return result;
    }, 'AutoSelectionEngine.validatePrerequisites', {
      isValid: false,
      missingPrerequisites: [],
      missingDependencies: [],
      warnings: ['Prerequisite validation failed']
    });
  }

  /**
   * Build dependency chain for a path
   * @param {string} pathId - Path ID to build chain for
   * @returns {Array<string>} Ordered dependency chain
   */
  buildDependencyChain(pathId) {
    return this.errorHandler.safeExecute(() => {
      const allDependencies = new Set();
      const visited = new Set();

      // First, collect all dependencies
      const collectDependencies = (currentPathId) => {
        if (visited.has(currentPathId)) {
          return; // Prevent infinite loops
        }
        visited.add(currentPathId);

        const pathData = this.pathRelationships[currentPathId];
        if (!pathData) {return;}

        allDependencies.add(currentPathId);

        // Add prerequisites
        if (pathData.prerequisites) {
          for (const prereq of pathData.prerequisites) {
            collectDependencies(prereq);
          }
        }
      };

      collectDependencies(pathId);

      // Sort dependencies by level and priority to maintain proper order
      const sortedPaths = Array.from(allDependencies).sort((a, b) => {
        const dataA = this.pathRelationships[a];
        const dataB = this.pathRelationships[b];

        if (!dataA || !dataB) {return 0;}

        // First sort by level (Beginner < Intermediate < Advanced)
        const levelA = this._getLevelValue(dataA.level);
        const levelB = this._getLevelValue(dataB.level);

        if (levelA !== levelB) {
          return levelA - levelB;
        }

        // Then sort by priority within same level
        const priorityA = dataA.priority || 999;
        const priorityB = dataB.priority || 999;

        return priorityA - priorityB;
      });

      return sortedPaths;
    }, 'AutoSelectionEngine.buildDependencyChain', []);
  }

  /**
   * Detect circular dependencies in path relationships
   * @returns {Object} Circular dependency detection result
   */
  detectCircularDependencies() {
    return this.errorHandler.safeExecute(() => {
      const visited = new Set();
      const recursionStack = new Set();
      const circularPaths = new Set();

      const detectCycle = (pathId, path) => {
        if (recursionStack.has(pathId)) {
          // Found a cycle
          const cycleStart = path.indexOf(pathId);
          const cyclePaths = path.slice(cycleStart);
          cyclePaths.forEach(p => circularPaths.add(p));
          return true;
        }

        if (visited.has(pathId)) {
          return false;
        }

        visited.add(pathId);
        recursionStack.add(pathId);
        path.push(pathId);

        const pathData = this.pathRelationships[pathId];
        if (pathData && pathData.prerequisites) {
          for (const prereq of pathData.prerequisites) {
            if (detectCycle(prereq, [...path])) {
              return true;
            }
          }
        }

        recursionStack.delete(pathId);
        return false;
      };

      // Check all paths for cycles
      for (const pathId of Object.keys(this.pathRelationships)) {
        if (!visited.has(pathId)) {
          detectCycle(pathId, []);
        }
      }

      return {
        hasCircularDependencies: circularPaths.size > 0,
        circularPaths: Array.from(circularPaths)
      };
    }, 'AutoSelectionEngine.detectCircularDependencies', {
      hasCircularDependencies: false,
      circularPaths: []
    });
  }

  /**
   * Resolve conflicts between selected paths
   * @param {Array<string>} conflictingPaths - Paths with conflicts
   * @param {string} userLevel - User's current level
   * @param {Object} progress - Current progress data
   * @returns {Object} Conflict resolution result
   */
  resolveConflicts(conflictingPaths, userLevel, progress = {}) {
    return this.errorHandler.safeExecute(() => {
      const resolution = {
        resolvedPaths: [],
        removedPaths: [],
        suggestions: [],
        reason: '',
        resolution: 'auto_resolve'
      };

      // Group paths by level for conflict resolution
      const pathsByLevel = this._groupPathsByLevel(conflictingPaths);

      // Resolution strategy based on user level
      if (userLevel === 'Beginner') {
        // Keep foundation paths, remove expert paths
        resolution.resolvedPaths = pathsByLevel.foundation || [];
        resolution.removedPaths = [...(pathsByLevel.expert || []), ...(pathsByLevel.skill || [])];

        // Suggest prerequisites for removed paths
        for (const removedPath of resolution.removedPaths) {
          const pathData = this.pathRelationships[removedPath];
          if (pathData && pathData.prerequisites) {
            resolution.suggestions.push(...pathData.prerequisites);
          }
        }

        if (resolution.suggestions.length > 0) {
          resolution.resolution = 'suggest_prerequisite';
          resolution.reason = 'Advanced paths removed - prerequisites suggested for Beginner level';
        } else {
          resolution.reason = 'Beginner path takes precedence over advanced paths for user level: Beginner';
        }
      } else if (userLevel === 'Intermediate') {
        // Keep foundation and skill paths, suggest prerequisites for expert
        resolution.resolvedPaths = [...(pathsByLevel.foundation || []), ...(pathsByLevel.skill || [])];
        resolution.removedPaths = pathsByLevel.expert || [];

        // Check for missing prerequisites in skill and expert paths
        const allPathsToCheck = [...(pathsByLevel.skill || []), ...(pathsByLevel.expert || [])];
        let hasMissingPrerequisites = false;

        for (const pathId of allPathsToCheck) {
          const pathData = this.pathRelationships[pathId];
          if (pathData && pathData.prerequisites) {
            for (const prereq of pathData.prerequisites) {
              // Check if prerequisite has any completed items
              const prereqData = this.pathRelationships[prereq];
              if (prereqData) {
                const hasCompletedItems = prereqData.autoSelectItems &&
                  prereqData.autoSelectItems.some(item =>
                    progress[item] && progress[item].completed
                  );

                if (!hasCompletedItems) {
                  resolution.suggestions.push(prereq);
                  hasMissingPrerequisites = true;
                }
              }
            }
          }
        }

        if (hasMissingPrerequisites) {
          resolution.resolution = 'suggest_prerequisite';
          resolution.reason = 'Missing prerequisites detected for selected paths';
        }
      } else {
        // Advanced users: prefer higher level paths
        resolution.resolvedPaths = [...(pathsByLevel.expert || []), ...(pathsByLevel.skill || [])];
        resolution.removedPaths = pathsByLevel.foundation || [];
        resolution.reason = 'Higher level paths preferred for Advanced users';
      }

      // Remove duplicates
      resolution.suggestions = [...new Set(resolution.suggestions)];

      return resolution;
    }, 'AutoSelectionEngine.resolveConflicts', {
      resolvedPaths: conflictingPaths,
      removedPaths: [],
      suggestions: [],
      reason: 'Conflict resolution failed',
      resolution: 'manual_required'
    });
  }

  /**
   * Get related paths for a given path
   * @param {string} pathId - Path ID to find related paths for
   * @returns {Array<string>} Array of related path IDs
   */
  getRelatedPaths(pathId) {
    return this.errorHandler.safeExecute(() => {
      // Check cache first
      if (this._relatedPathsCache.has(pathId)) {
        return this._relatedPathsCache.get(pathId);
      }

      const pathData = this.pathRelationships[pathId];
      if (!pathData) {
        return [];
      }

      const relatedPaths = [...(pathData.relatedPaths || [])];

      // Cache result
      this._relatedPathsCache.set(pathId, relatedPaths);

      return relatedPaths;
    }, 'AutoSelectionEngine.getRelatedPaths', []);
  }

  /**
   * Suggest related paths based on user level
   * @param {Array<string>} selectedPaths - Currently selected paths
   * @param {string} userLevel - User's current level
   * @returns {Array<string>} Suggested related paths
   */
  suggestRelatedPaths(selectedPaths, userLevel) {
    return this.errorHandler.safeExecute(() => {
      const suggestions = new Set();

      for (const pathId of selectedPaths) {
        const relatedPaths = this.getRelatedPaths(pathId);

        for (const relatedPath of relatedPaths) {
          const relatedData = this.pathRelationships[relatedPath];

          // Filter by user level appropriateness
          if (relatedData && this._isPathAppropriateForLevel(relatedData, userLevel)) {
            suggestions.add(relatedPath);
          }
        }
      }

      // Remove already selected paths
      selectedPaths.forEach(path => suggestions.delete(path));

      return Array.from(suggestions);
    }, 'AutoSelectionEngine.suggestRelatedPaths', []);
  }

  /**
   * Calculate compatibility score between two paths
   * @param {string} pathA - First path ID
   * @param {string} pathB - Second path ID
   * @param {string} userLevel - User's current level
   * @returns {number} Compatibility score (0-1)
   */
  calculateCompatibilityScore(pathA, pathB, userLevel) {
    return this.errorHandler.safeExecute(() => {
      const dataA = this.pathRelationships[pathA];
      const dataB = this.pathRelationships[pathB];

      if (!dataA || !dataB) {return 0;}

      let score = 0;

      // Level compatibility (40% weight)
      if (dataA.level === dataB.level) {
        score += 0.4;
      } else {
        const levelDiff = Math.abs(this._getLevelValue(dataA.level) - this._getLevelValue(dataB.level));
        score += Math.max(0, 0.4 - (levelDiff * 0.2));
      }

      // Category compatibility (30% weight)
      if (dataA.category === dataB.category) {
        score += 0.3;
      }

      // Related path bonus (20% weight)
      if (dataA.relatedPaths && dataA.relatedPaths.includes(pathB)) {
        score += 0.2;
      }

      // User level appropriateness (10% weight)
      if (this._isPathAppropriateForLevel(dataA, userLevel) &&
          this._isPathAppropriateForLevel(dataB, userLevel)) {
        score += 0.1;
      }

      return Math.min(1.0, score);
    }, 'AutoSelectionEngine.calculateCompatibilityScore', 0);
  }

  /**
   * Rank paths by relevance to selected paths
   * @param {Array<string>} selectedPaths - Currently selected paths
   * @param {string} userLevel - User's current level
   * @param {Object} userPreferences - User preferences (optional)
   * @returns {Array<Object>} Ranked paths with scores
   */
  rankPathsByRelevance(selectedPaths, userLevel, userPreferences = {}) {
    return this.errorHandler.safeExecute(() => {
      const allPaths = Object.keys(this.pathRelationships);
      const unselectedPaths = allPaths.filter(path => !selectedPaths.includes(path));

      const rankings = unselectedPaths.map(pathId => {
        let totalScore = 0;
        let scoreCount = 0;

        // Calculate average compatibility with selected paths
        for (const selectedPath of selectedPaths) {
          const compatScore = this.calculateCompatibilityScore(selectedPath, pathId, userLevel);
          totalScore += compatScore;
          scoreCount++;
        }

        let averageScore = scoreCount > 0 ? totalScore / scoreCount : 0;

        // Apply user preference bonuses
        if (userPreferences.interests) {
          const pathData = this.pathRelationships[pathId];
          if (pathData && pathData.title) {
            for (const interest of userPreferences.interests) {
              if (pathData.title.toLowerCase().includes(interest.toLowerCase())) {
                averageScore += 0.1;
              }
            }
          }
        }

        return {
          pathId,
          score: Math.min(1.0, averageScore),
          title: this.pathRelationships[pathId]?.title || pathId
        };
      });

      // Sort by score (highest first)
      return rankings.sort((a, b) => b.score - a.score);
    }, 'AutoSelectionEngine.rankPathsByRelevance', []);
  }

  /**
   * Validate path structure integrity
   * @param {Object} pathRelationships - Path relationships to validate
   * @returns {Object} Validation result
   */
  validatePathStructure(pathRelationships) {
    return this.errorHandler.safeExecute(() => {
      const validation = {
        isValid: true,
        errors: [],
        warnings: []
      };

      const allPathIds = new Set(Object.keys(pathRelationships));

      for (const [pathId, pathData] of Object.entries(pathRelationships)) {
        // Validate prerequisites
        if (pathData.prerequisites) {
          for (const prereq of pathData.prerequisites) {
            if (!allPathIds.has(prereq)) {
              validation.errors.push({
                type: 'invalid_prerequisite_reference',
                pathId,
                reference: prereq
              });
              validation.isValid = false;
            }
          }
        }

        // Validate related paths
        if (pathData.relatedPaths) {
          for (const related of pathData.relatedPaths) {
            if (!allPathIds.has(related)) {
              validation.errors.push({
                type: 'invalid_related_path_reference',
                pathId,
                reference: related
              });
              validation.isValid = false;
            }
          }
        }

        // Validate required fields
        if (!pathData.id || !pathData.level) {
          validation.warnings.push({
            type: 'missing_required_fields',
            pathId,
            missingFields: [
              !pathData.id ? 'id' : null,
              !pathData.level ? 'level' : null
            ].filter(Boolean)
          });
        }
      }

      return validation;
    }, 'AutoSelectionEngine.validatePathStructure', {
      isValid: false,
      errors: [{ type: 'validation_error', message: 'Structure validation failed' }],
      warnings: []
    });
  }

  /**
   * Validate kata ID format
   * @param {string} kataId - Kata ID to validate
   * @returns {boolean} True if valid format
   */
  validateKataId(kataId) {
    return this.errorHandler.safeExecute(() => {
      // Expected format: "category/number-kata-name"
      const kataRegex = /^[a-z-]+\/\d{2}-[a-z-]+$/;
      return kataRegex.test(kataId);
    }, 'AutoSelectionEngine.validateKataId', false);
  }

  /**
   * Validate level consistency across paths
   * @param {Array<string>} pathIds - Path IDs to validate
   * @returns {Object} Level consistency validation result
   */
  validateLevelConsistency(pathIds) {
    return this.errorHandler.safeExecute(() => {
      const validation = {
        isConsistent: true,
        conflicts: []
      };

      const levels = pathIds.map(pathId => {
        const pathData = this.pathRelationships[pathId];
        return pathData ? pathData.level : null;
      }).filter(Boolean);

      const uniqueLevels = [...new Set(levels)];

      // Check for level conflicts (Foundation + Expert is problematic)
      if (uniqueLevels.includes('Beginner') && uniqueLevels.includes('Advanced')) {
        validation.isConsistent = false;
        validation.conflicts.push({
          type: 'level_mismatch',
          paths: pathIds.filter(pathId => {
            const pathData = this.pathRelationships[pathId];
            return pathData && (pathData.level === 'Beginner' || pathData.level === 'Advanced');
          })
        });
      }

      return validation;
    }, 'AutoSelectionEngine.validateLevelConsistency', {
      isConsistent: false,
      conflicts: [{ type: 'validation_error', paths: [] }]
    });
  }

  /**
   * Get error message for a specific error type
   * @param {string} errorType - Type of error
   * @param {Object} context - Error context
   * @returns {string} Human-readable error message
   */
  getErrorMessage(errorType, context) {
    const messages = {
      missing_prerequisite: `Path "${context.pathId}" requires prerequisite path "${context.missingPrerequisite}" to be completed first`,
      level_conflict: `Path "${context.pathId}" (${context.level}) conflicts with other selected paths`,
      invalid_path_id: `Path "${context.pathId}" does not exist or is not available`,
      circular_dependency: `Circular dependency detected involving paths: ${context.paths?.join(', ')}`,
      validation_error: `Validation failed for path "${context.pathId}": ${context.reason}`
    };

    return messages[errorType] || `Unknown error type: ${errorType}`;
  }

  // Integration methods

  /**
   * Process path selection with progress from learning path manager
   * @param {Array<string>} selectedPaths - Selected path IDs
   * @returns {Promise<Object>} Auto-selection result
   */
  async processPathSelectionWithProgress(selectedPaths) {
    if (this.isDestroyed) {
      throw new Error('AutoSelectionEngine has been destroyed');
    }

    const progress = await this._getProgressFromManager();
    const userLevel = this.learningPathManager.getUserLevel?.() || 'Beginner';
    return this.processPathSelection(selectedPaths, progress, userLevel);
  }

  /**
   * Apply auto-selections to learning path manager
   * @param {Object} selections - Selection result from processPathSelection
   */
  applyAutoSelections(selections) {
    return this.errorHandler.safeExecute(() => {
      if (this.learningPathManager.updatePathSelections) {
        this.learningPathManager.updatePathSelections({
          selectedItems: selections.autoSelectedItems,
          suggestedRelated: selections.suggestedRelated,
          pathId: selections.pathId
        });
      }
    }, 'AutoSelectionEngine.applyAutoSelections');
  }

  // Component registration methods

  /**
   * Register checkbox component for notifications
   * @param {Object} checkboxComponent - Checkbox component instance
   */
  registerCheckboxComponent(checkboxComponent) {
    this._registeredComponents.checkbox = checkboxComponent;
  }

  /**
   * Register annotations component for notifications
   * @param {Object} annotationsComponent - Annotations component instance
   */
  registerAnnotationsComponent(annotationsComponent) {
    this._registeredComponents.annotations = annotationsComponent;
  }

  /**
   * Register coach component for notifications
   * @param {Object} coachComponent - Coach component instance
   */
  registerCoachComponent(coachComponent) {
    this._registeredComponents.coach = coachComponent;
  }

  /**
   * Notify registered components of changes
   * @param {Object} result - Auto-selection result
   */
  notifyComponents(result) {
    return this.errorHandler.safeExecute(() => {
      const { checkbox, annotations, coach } = this._registeredComponents;

      if (checkbox && checkbox.updateSelections) {
        checkbox.updateSelections(result);
      }

      if (annotations && annotations.updateProgressBadges) {
        annotations.updateProgressBadges(result);
      }

      if (coach && coach.updateContext) {
        coach.updateContext(result);
      }
    }, 'AutoSelectionEngine.notifyComponents');
  }

  /**
   * Handle progress update from external sources
   * @param {Object} progressUpdate - Progress update data
   */
  handleProgressUpdate(_progressUpdate) {
    return this.errorHandler.safeExecute(() => {
      const { annotations } = this._registeredComponents;

      if (annotations) {
        if (annotations.updateProgressBadges) {
          annotations.updateProgressBadges();
        }
        if (annotations.updateStats) {
          annotations.updateStats();
        }
      }
    }, 'AutoSelectionEngine.handleProgressUpdate');
  }

  /**
   * Update coach context with current path state
   * @param {Object} pathState - Current path state
   */
  updateCoachContext(pathState) {
    return this.errorHandler.safeExecute(() => {
      const { coach } = this._registeredComponents;

      if (coach && coach.updateContext) {
        coach.updateContext({
          currentPath: pathState.selectedPaths?.[0],
          nextSteps: pathState.nextRecommended || [],
          completedItems: pathState.completedItems || [],
          suggestions: pathState.suggestedRelated || []
        });
      }
    }, 'AutoSelectionEngine.updateCoachContext');
  }

  /**
   * Cleanup and destroy the engine instance
   */
  destroy() {
    if (this.isDestroyed) {return;}

    this.isDestroyed = true;

    // Clear caches
    if (this._relatedPathsCache) {
      this._relatedPathsCache.clear();
      this._relatedPathsCache = undefined;
    }

    if (this._dependencyCache) {
      this._dependencyCache.clear();
      this._dependencyCache = undefined;
    }

    // Clear component registrations
    this._registeredComponents = {
      checkbox: null,
      annotations: null,
      coach: null
    };

    // Clear references
    this.learningPathManager = null;
    this.errorHandler = null;
    this.debugHelper = null;
    this.pathRelationships = null;
  }

  // Private helper methods

  /**
   * Initialize derived data structures
   * @private
   */
  _initializeDerivedData() {
    // Pre-calculate commonly used data structures
    this._pathsByCategory = this._buildPathsByCategory();
    this._pathsByLevel = this._buildPathsByLevel();
  }

  /**
   * Create default debug helper if not provided
   * @private
   * @returns {Object} Default debug helper
   */
  _createDefaultDebugHelper() {
    return {
      log: () => {}, // Silent in production
      warn: () => {},
      error: () => {}
    };
  }

  /**
   * Get default path relationships if not provided
   * @private
   * @returns {Object} Default path relationships
   */
  _getDefaultPathRelationships() {
    return {}; // Empty relationships - will be provided by caller
  }

  /**
   * Merge configuration with defaults
   * @private
   * @param {Object} customConfig - Custom configuration
   * @returns {Object} Merged configuration
   */
  _mergeConfig(customConfig) {
    const defaultConfig = {
      maxAutoSelections: 20,
      enableConflictResolution: true,
      cacheEnabled: true,
      performanceMode: false
    };

    return { ...defaultConfig, ...customConfig };
  }

  /**
   * Check if auto-selection is enabled
   * @private
   * @returns {boolean} True if enabled
   */
  _isAutoSelectionEnabled() {
    const config = this.learningPathManager.getConfig?.();
    return config?.autoSelection?.enabled !== false;
  }

  /**
   * Get progress from learning path manager
   * @private
   * @returns {Object} Progress data
   */
  async _getProgressFromManager() {
    return await this.learningPathManager.getKataProgress?.() || {};
  }

  /**
   * Validate path IDs
   * @private
   * @param {Array<string>} pathIds - Path IDs to validate
   * @returns {Array<string>} Valid path IDs
   */
  _validatePathIds(pathIds) {
    return pathIds.filter(pathId => {
      return typeof pathId === 'string' && this.pathRelationships[pathId];
    });
  }

  /**
   * Validate user level
   * @private
   * @param {string} userLevel - User level to validate
   * @returns {string} Valid user level
   */
  _validateUserLevel(userLevel) {
    const validLevels = ['Beginner', 'Intermediate', 'Advanced'];
    return validLevels.includes(userLevel) ? userLevel : 'Beginner';
  }

  /**
   * Process individual path
   * @private
   * @param {string} pathId - Path ID to process
   * @param {Object} progress - Current progress
   * @param {string} userLevel - User level
   * @returns {Object} Path processing result
   */
  _processIndividualPath(pathId, progress, userLevel) {
    const pathData = this.pathRelationships[pathId];
    if (!pathData) {
      return {
        autoSelectedItems: [],
        suggestedRelated: [],
        conflicts: [],
        warnings: [{ type: 'invalid_path_id', pathId, message: `Unknown path: ${pathId}` }]
      };
    }

    const result = {
      autoSelectedItems: [],
      suggestedRelated: [],
      conflicts: [],
      warnings: []
    };

    // Validate prerequisites
    const prereqValidation = this.validatePrerequisites([pathId], progress);
    if (!prereqValidation.isValid) {
      if (prereqValidation.missingPrerequisites.length > 0) {
        result.warnings.push({
          type: 'missing_prerequisite',
          pathId,
          missingPrerequisite: prereqValidation.missingPrerequisites[0],
          message: `Path "${pathId}" requires prerequisite path "${prereqValidation.missingPrerequisites[0]}"`
        });
        return result; // Don't auto-select if prerequisites missing
      }
    }

    // Check for level conflicts with other paths
    const levelConflicts = this._detectLevelConflicts(pathId, userLevel);
    if (levelConflicts.length > 0) {
      result.conflicts.push({
        type: 'level_conflict',
        conflictingPaths: [pathId, ...levelConflicts],
        message: `Path "${pathId}" (${pathData.level}) conflicts with "${levelConflicts[0]}" (${this.pathRelationships[levelConflicts[0]]?.level})`
      });
    }

    // Auto-select items from path (excluding completed ones)
    if (pathData.autoSelectItems) {
      const availableItems = pathData.autoSelectItems.filter(item => {
        return !progress[item] || (!progress[item].completed && !progress[item].inProgress);
      });
      result.autoSelectedItems.push(...availableItems);
    }

    // Suggest related paths
    const relatedSuggestions = this.suggestRelatedPaths([pathId], userLevel);
    result.suggestedRelated.push(...relatedSuggestions);

    return result;
  }

  /**
   * Merge path result into main result
   * @private
   * @param {Object} mainResult - Main result object
   * @param {Object} pathResult - Individual path result
   */
  _mergePathResult(mainResult, pathResult) {
    mainResult.autoSelectedItems.push(...pathResult.autoSelectedItems);
    mainResult.suggestedRelated.push(...pathResult.suggestedRelated);
    mainResult.conflicts.push(...pathResult.conflicts);
    mainResult.warnings.push(...pathResult.warnings);
  }

  /**
   * Apply conflict resolution to result
   * @private
   * @param {Object} result - Result object to modify
   * @param {Object} resolution - Conflict resolution
   */
  _applyConflictResolution(result, resolution) {
    // Filter out items from removed paths
    result.autoSelectedItems = result.autoSelectedItems.filter(item => {
      return !resolution.removedPaths.some(removedPath => {
        const removedPathData = this.pathRelationships[removedPath];
        return removedPathData && removedPathData.autoSelectItems &&
               removedPathData.autoSelectItems.includes(item);
      });
    });

    // Add suggestions
    result.suggestedRelated.push(...resolution.suggestions);
  }

  /**
   * Optimize selection by removing duplicates
   * @private
   * @param {Object} result - Result object to optimize
   */
  _optimizeSelection(result) {
    result.autoSelectedItems = [...new Set(result.autoSelectedItems)];
    result.suggestedRelated = [...new Set(result.suggestedRelated)];

    // Remove suggested items that are already auto-selected
    result.suggestedRelated = result.suggestedRelated.filter(item =>
      !result.autoSelectedItems.includes(item)
    );
  }

  /**
   * Detect level conflicts for a path
   * @private
   * @param {string} pathId - Path ID to check
   * @param {string} userLevel - User level
   * @returns {Array<string>} Conflicting path IDs
   */
  _detectLevelConflicts(pathId, userLevel) {
    const pathData = this.pathRelationships[pathId];
    if (!pathData || !pathData.conflicts) {return [];}

    return pathData.conflicts.filter(conflictPath => {
      const conflictData = this.pathRelationships[conflictPath];
      if (!conflictData) {return false;}

      // Check if the conflict is level-based
      return this._isLevelConflict(pathData.level, conflictData.level, userLevel);
    });
  }

  /**
   * Check if two levels conflict for a user
   * @private
   * @param {string} levelA - First level
   * @param {string} levelB - Second level
   * @param {string} userLevel - User's level
   * @returns {boolean} True if levels conflict
   */
  _isLevelConflict(levelA, levelB, _userLevel) {
    // Beginner + Advanced is always a conflict
    if ((levelA === 'Beginner' && levelB === 'Advanced') ||
        (levelA === 'Advanced' && levelB === 'Beginner')) {
      return true;
    }
    return false;
  }

  /**
   * Group paths by level
   * @private
   * @param {Array<string>} pathIds - Path IDs to group
   * @returns {Object} Paths grouped by level
   */
  _groupPathsByLevel(pathIds) {
    const groups = { foundation: [], skill: [], expert: [] };

    pathIds.forEach(pathId => {
      const pathData = this.pathRelationships[pathId];
      if (!pathData) {return;}

      const category = pathData.category || 'foundation';
      if (groups[category]) {
        groups[category].push(pathId);
      }
    });

    return groups;
  }

  /**
   * Check if path is appropriate for user level
   * @private
   * @param {Object} pathData - Path data
   * @param {string} userLevel - User level
   * @returns {boolean} True if appropriate
   */
  _isPathAppropriateForLevel(pathData, userLevel) {
    const userLevelValue = this._getLevelValue(userLevel);
    const pathLevelValue = this._getLevelValue(pathData.level);

    // Allow paths at or below user level, plus one level above
    return pathLevelValue <= userLevelValue + 1;
  }

  /**
   * Get numeric value for level
   * @private
   * @param {string} level - Level string
   * @returns {number} Numeric level value
   */
  _getLevelValue(level) {
    const levels = { 'Beginner': 0, 'Intermediate': 1, 'Advanced': 2 };
    return levels[level] || 0;
  }

  /**
   * Build paths by category lookup
   * @private
   * @returns {Object} Paths organized by category
   */
  _buildPathsByCategory() {
    const byCategory = {};

    Object.values(this.pathRelationships).forEach(pathData => {
      const category = pathData.category || 'uncategorized';
      if (!byCategory[category]) {
        byCategory[category] = [];
      }
      byCategory[category].push(pathData.id);
    });

    return byCategory;
  }

  /**
   * Build paths by level lookup
   * @private
   * @returns {Object} Paths organized by level
   */
  _buildPathsByLevel() {
    const byLevel = {};

    Object.values(this.pathRelationships).forEach(pathData => {
      const level = pathData.level || 'Beginner';
      if (!byLevel[level]) {
        byLevel[level] = [];
      }
      byLevel[level].push(pathData.id);
    });

    return byLevel;
  }

  /**
   * Check if path data is complete
   * @private
   * @param {Object} pathData - Path data to validate
   * @returns {boolean} True if path data is complete
   */
  _isPathDataComplete(pathData) {
    if (!pathData || typeof pathData !== 'object') {
      return false;
    }

    // Check for required fields
    const requiredFields = ['id', 'title', 'level', 'category'];
    return requiredFields.every(field => pathData[field] !== undefined);
  }

  /**
   * Check for circular dependencies involving a specific path
   * @private
   * @param {string} pathId - Path ID to check
   * @returns {Object} Circular dependency check result
   */
  _checkPathCircularDependencies(pathId) {
    const visited = new Set();
    const recursionStack = new Set();
    const circularPaths = [];

    const checkCycle = (currentPath, path) => {
      if (recursionStack.has(currentPath)) {
        // Found a cycle - add the cycle to circular paths
        const cycleStart = path.indexOf(currentPath);
        const cycle = path.slice(cycleStart);
        cycle.push(currentPath); // Complete the cycle
        circularPaths.push(...cycle);
        return true;
      }

      if (visited.has(currentPath)) {
        return false;
      }

      visited.add(currentPath);
      recursionStack.add(currentPath);

      const pathData = this.pathRelationships[currentPath];
      if (pathData && pathData.prerequisites) {
        for (const prereq of pathData.prerequisites) {
          if (checkCycle(prereq, [...path, currentPath])) {
            return true;
          }
        }
      }

      recursionStack.delete(currentPath);
      return false;
    };

    const hasCircular = checkCycle(pathId, []);
    return {
      hasCircular,
      circularPaths: [...new Set(circularPaths)]
    };
  }

  /**
   * Get paths by category
   * @param {string} category - Category to filter by
   * @returns {Array<string>} Path IDs in category
   */
  getPathsByCategory(category) {
    return this._pathsByCategory[category] || [];
  }

  /**
   * Get paths by level
   * @param {string} level - Level to filter by
   * @returns {Array<string>} Path IDs at level
   */
  getPathsByLevel(level) {
    return this._pathsByLevel[level] || [];
  }

  // Additional integration methods for complex scenarios

  /**
   * Process multiple path selections
   * @param {Array<string>} multiplePaths - Multiple path selections
   * @returns {Object} Combined selection result
   */
  processMultiplePathSelections(multiplePaths) {
    return this.errorHandler.safeExecute(() => {
      const results = multiplePaths.map(pathId =>
        this.processPathSelection([pathId], {}, 'Beginner')
      );

      const combined = {
        selections: results,
        conflicts: [],
        totalAutoSelectedItems: 0
      };

      // Combine results and detect cross-path conflicts
      results.forEach(result => {
        combined.conflicts.push(...result.conflicts);
        combined.totalAutoSelectedItems += result.autoSelectedItems.length;
      });

      return combined;
    }, 'AutoSelectionEngine.processMultiplePathSelections', {
      selections: [],
      conflicts: [],
      totalAutoSelectedItems: 0
    });
  }

  /**
   * Process path selection with conflict resolution
   * @param {Array<string>} conflictingPaths - Paths with conflicts
   * @param {string} userLevel - User level
   * @returns {Object} Resolution result
   */
  processPathSelectionWithConflictResolution(conflictingPaths, userLevel) {
    const resolution = this.resolveConflicts(conflictingPaths, userLevel);
    return {
      resolvedPaths: resolution.resolvedPaths,
      removedPaths: resolution.removedPaths,
      reason: resolution.reason
    };
  }

  /**
   * Update selections for progress changes
   * @param {Object} currentSelections - Current selections
   * @param {Object} progressUpdate - Progress updates
   * @returns {Object} Updated selections
   */
  updateSelectionsForProgress(currentSelections, progressUpdate) {
    return this.errorHandler.safeExecute(() => {
      const updated = { ...currentSelections };

      // Move completed items from auto-selected to completed
      updated.completedItems = updated.completedItems || [];
      updated.autoSelectedItems = updated.autoSelectedItems.filter(item => {
        if (progressUpdate[item] && progressUpdate[item].completed) {
          updated.completedItems.push(item);
          return false;
        }
        return true;
      });

      return updated;
    }, 'AutoSelectionEngine.updateSelectionsForProgress', currentSelections);
  }

  /**
   * Validate and update prerequisites
   * @param {Array<string>} pathIds - Path IDs to validate
   * @param {Object} progressUpdate - Progress update
   * @returns {Object} Validation and update result
   */
  validateAndUpdatePrerequisites(pathIds, progressUpdate) {
    return this.errorHandler.safeExecute(() => {
      const result = {
        canProceed: true,
        unlockedPaths: [],
        blockedPaths: []
      };

      pathIds.forEach(pathId => {
        const validation = this.validatePrerequisites([pathId], progressUpdate);
        if (validation.isValid) {
          result.unlockedPaths.push(pathId);
        } else {
          result.blockedPaths.push(pathId);
          result.canProceed = false;
        }
      });

      return result;
    }, 'AutoSelectionEngine.validateAndUpdatePrerequisites', {
      canProceed: false,
      unlockedPaths: [],
      blockedPaths: []
    });
  }

  /**
   * Categorize progress items by status
   * @param {Object} progress - Progress data
   * @returns {Object} Categorized progress items
   */
  categorizeProgressItems(progress) {
    return this.errorHandler.safeExecute(() => {
      const categories = {
        completed: [],
        inProgress: [],
        selected: []
      };

      Object.entries(progress).forEach(([itemId, itemProgress]) => {
        if (itemProgress.completed) {
          categories.completed.push(itemId);
        } else if (itemProgress.inProgress) {
          categories.inProgress.push(itemId);
        } else if (itemProgress.selected) {
          categories.selected.push(itemId);
        }
      });

      return categories;
    }, 'AutoSelectionEngine.categorizeProgressItems', {
      completed: [],
      inProgress: [],
      selected: []
    });
  }

  // Advanced dependency resolution methods

  /**
   * Resolve dependency chain for a path
   * @param {string} pathId - Path to resolve dependencies for
   * @returns {Array<string>} Complete dependency chain
   */
  resolveDependencyChain(pathId) {
    return this.buildDependencyChain(pathId);
  }

  /**
   * Resolve diamond dependencies
   * @param {Array<string>} pathIds - Paths with diamond dependencies
   * @returns {Object} Diamond dependency resolution
   */
  resolveDiamondDependencies(pathIds) {
    return this.errorHandler.safeExecute(() => {
      const allPrereqs = new Set();
      let convergencePath = null;

      // Find all prerequisites
      pathIds.forEach(pathId => {
        const pathData = this.pathRelationships[pathId];
        if (pathData && pathData.prerequisites) {
          pathData.prerequisites.forEach(prereq => allPrereqs.add(prereq));
        }
      });

      // Find convergence point (where paths meet)
      Object.keys(this.pathRelationships).forEach(pathId => {
        const pathData = this.pathRelationships[pathId];
        if (pathData && pathData.prerequisites) {
          const hasMultipleInputPaths = pathIds.every(inputPath => {
            return pathData.prerequisites.includes(inputPath) ||
                   this.buildDependencyChain(pathId).includes(inputPath);
          });
          if (hasMultipleInputPaths && !convergencePath) {
            convergencePath = pathId;
          }
        }
      });

      return {
        requiredPaths: Array.from(allPrereqs),
        convergencePath
      };
    }, 'AutoSelectionEngine.resolveDiamondDependencies', {
      requiredPaths: [],
      convergencePath: null
    });
  }

  /**
   * Optimize path order based on dependencies
   * @param {Array<string>} unorderedPaths - Unordered path list
   * @returns {Array<string>} Optimally ordered paths
   */
  optimizePathOrder(unorderedPaths) {
    return this.errorHandler.safeExecute(() => {
      const ordered = [];
      const remaining = [...unorderedPaths];

      while (remaining.length > 0) {
        // Find paths with no unmet prerequisites
        const readyPaths = remaining.filter(pathId => {
          const pathData = this.pathRelationships[pathId];
          if (!pathData || !pathData.prerequisites) {return true;}

          return pathData.prerequisites.every(prereq =>
            ordered.includes(prereq) || !unorderedPaths.includes(prereq)
          );
        });

        if (readyPaths.length === 0) {
          // Circular dependency or missing prerequisites - add remaining as-is
          ordered.push(...remaining);
          break;
        }

        // Add ready paths and remove from remaining
        ordered.push(...readyPaths);
        readyPaths.forEach(path => {
          const index = remaining.indexOf(path);
          if (index > -1) {remaining.splice(index, 1);}
        });
      }

      return ordered;
    }, 'AutoSelectionEngine.optimizePathOrder', unorderedPaths);
  }

  /**
   * Validate complex prerequisite scenarios
   * @param {Object} scenario - Complex prerequisite scenario
   * @returns {Object} Validation result with suggestions
   */
  validateComplexPrerequisites(scenario) {
    return this.errorHandler.safeExecute(() => {
      const { selectedPaths, completedKatas = [], missingKatas = [] } = scenario;

      const validation = {
        canProceed: true,
        blockedBy: [],
        suggestedActions: []
      };

      selectedPaths.forEach(pathId => {
        const pathData = this.pathRelationships[pathId];
        if (!pathData) {return;}

        // Check kata dependencies
        if (pathData.dependencies) {
          pathData.dependencies.forEach(depKata => {
            if (!completedKatas.includes(depKata)) {
              validation.canProceed = false;
              validation.blockedBy.push(depKata);
              validation.suggestedActions.push({
                action: 'complete_prerequisite',
                kataId: depKata
              });
            }
          });
        }

        // Also check missing katas specifically mentioned in scenario
        missingKatas.forEach(missingKata => {
          // Block by any missing kata that's relevant to the path selection
          validation.canProceed = false;
          if (!validation.blockedBy.includes(missingKata)) {
            validation.blockedBy.push(missingKata);
          }
          // Avoid duplicate actions
          const actionExists = validation.suggestedActions.some(action =>
            action.kataId === missingKata
          );
          if (!actionExists) {
            validation.suggestedActions.push({
              action: 'complete_prerequisite',
              kataId: missingKata
            });
          }
        });
      });

      return validation;
    }, 'AutoSelectionEngine.validateComplexPrerequisites', {
      canProceed: false,
      blockedBy: [],
      suggestedActions: []
    });
  }

  // Discovery and mapping methods

  /**
   * Discover all available learning paths
   * @returns {Array<string>} Available path IDs
   */
  discoverAvailablePaths() {
    return Object.keys(this.pathRelationships);
  }

  /**
   * Build relationship map
   * @returns {Map} Relationship map
   */
  buildRelationshipMap() {
    const map = new Map();

    Object.entries(this.pathRelationships).forEach(([pathId, pathData]) => {
      map.set(pathId, {
        relatedPaths: pathData.relatedPaths || [],
        conflicts: pathData.conflicts || [],
        prerequisites: pathData.prerequisites || [],
        category: pathData.category,
        level: pathData.level
      });
    });

    return map;
  }

  /**
   * Build dependency graph
   * @returns {Object} Dependency graph with nodes and edges
   */
  buildDependencyGraph() {
    const nodes = [];
    const edges = [];

    // Create nodes
    Object.values(this.pathRelationships).forEach(pathData => {
      const levelValue = this._getLevelValue(pathData.level);
      nodes.push({
        id: pathData.id,
        level: levelValue,
        category: pathData.category
      });
    });

    // Create edges
    Object.entries(this.pathRelationships).forEach(([pathId, pathData]) => {
      // Prerequisite edges
      if (pathData.prerequisites) {
        pathData.prerequisites.forEach(prereq => {
          edges.push({
            from: prereq,
            to: pathId,
            type: 'prerequisite'
          });
        });
      }

      // Related path edges
      if (pathData.relatedPaths) {
        pathData.relatedPaths.forEach(related => {
          edges.push({
            from: pathId,
            to: related,
            type: 'related'
          });
        });
      }
    });

    return { nodes, edges };
  }

  // Integration consistency validation

  /**
   * Validate integration state consistency
   * @param {Object} state - Integration state to validate
   * @returns {Object} Consistency validation result
   */
  validateIntegrationConsistency(state) {
    return this.errorHandler.safeExecute(() => {
      const validation = {
        isConsistent: true,
        mismatches: []
      };

      const { autoSelectionState, checkboxState, progressState } = state;

      // Check auto-selection vs checkbox state consistency
      if (autoSelectionState && checkboxState) {
        const autoSet = new Set(autoSelectionState);
        const checkboxSet = new Set(checkboxState);

        if (autoSet.size !== checkboxSet.size ||
            ![...autoSet].every(item => checkboxSet.has(item))) {
          validation.isConsistent = false;
          validation.mismatches.push({
            type: 'state_mismatch',
            components: ['autoSelection', 'checkbox'],
            autoSelectionItems: autoSelectionState,
            checkboxItems: checkboxState
          });
        }
      }

      // Check for unknown katas in progress state
      if (progressState) {
        const allKnownKatas = new Set();
        Object.values(this.pathRelationships).forEach(pathData => {
          if (pathData.autoSelectItems) {
            pathData.autoSelectItems.forEach(item => allKnownKatas.add(item));
          }
        });

        Object.keys(progressState).forEach(kataId => {
          if (!allKnownKatas.has(kataId)) {
            validation.isConsistent = false;
            validation.mismatches.push({
              type: 'unknown_kata',
              kataId,
              component: 'progress'
            });
          }
        });
      }

      return validation;
    }, 'AutoSelectionEngine.validateIntegrationConsistency', {
      isConsistent: false,
      mismatches: [{ type: 'validation_error', message: 'Consistency check failed' }]
    });
  }

  /**
   * Validate progress data structure
   * @private
   * @param {Object} progress - Progress data to validate
   * @throws {Error} When progress data is malformed
   */
  _validateProgressData(progress) {
    if (!progress || typeof progress !== 'object') {
      throw new Error('Progress data must be an object');
    }

    for (const [kataId, progressData] of Object.entries(progress)) {
      // Check kata ID is valid
      if (!kataId || typeof kataId !== 'string' || kataId === 'null') {
        throw new Error(`Invalid kata ID: ${kataId}`);
      }

      // Check progress data structure
      if (progressData !== null && typeof progressData !== 'object') {
        throw new Error(`Progress data for ${kataId} must be an object or null`);
      }

      // If progress data exists, validate completed field
      if (progressData && 'completed' in progressData) {
        if (typeof progressData.completed !== 'boolean') {
          throw new Error(`Completed field for ${kataId} must be boolean, got ${typeof progressData.completed}`);
        }
      }
    }
  }

  // ============================================================================
  // E2E Test Support Methods
  // ============================================================================

  /**
   * Ensure accessibility compliance for E2E testing
   * Note: This is primarily a logic component, but may trigger UI updates
   * @returns {Object} Accessibility compliance report
   */
  ensureAccessibilityCompliance() {
    const report = {
      isCompliant: true,
      issues: [],
      checkedElements: 0,
      timestamp: Date.now()
    };

    try {
      // Check for any auto-selection notifications or dialogs
      const autoSelectionElements = document.querySelectorAll(
        '[data-auto-selection], .auto-selection-notification, .conflict-resolution-dialog, .suggestion-dialog'
      );

      autoSelectionElements.forEach((element, _index) => {
        report.checkedElements++;

        // Check for ARIA attributes
        const ariaLabel = element.getAttribute('aria-label');
        const ariaDescribedBy = element.getAttribute('aria-describedby');

        if (!ariaLabel && !ariaDescribedBy && !element.textContent.trim()) {
          report.issues.push(`Auto-selection element ${_index} missing accessible text`);
        }

        // Check for role attributes for dialogs
        if (element.classList.contains('conflict-resolution-dialog') || element.classList.contains('suggestion-dialog')) {
          const role = element.getAttribute('role');
          if (role !== 'dialog') {
            report.issues.push(`Dialog element ${_index} should have role="dialog"`);
          }

          // Check for aria-modal
          const ariaModal = element.getAttribute('aria-modal');
          if (ariaModal !== 'true') {
            report.issues.push(`Modal dialog ${_index} should have aria-modal="true"`);
          }
        }

        // Check for live regions for notifications
        if (element.classList.contains('auto-selection-notification')) {
          const ariaLive = element.getAttribute('aria-live');
          if (!ariaLive) {
            report.issues.push(`Auto-selection notification ${_index} should have aria-live attribute`);
          }
        }
      });

      report.isCompliant = report.issues.length === 0;
      return report;

    } catch (error) {
      this.dependencies.errorHandler.handleError(error, 'AutoSelectionEngine.ensureAccessibilityCompliance');
      return {
        isCompliant: false,
        issues: [`Error during accessibility check: ${error.message}`],
        checkedElements: 0,
        timestamp: Date.now()
      };
    }
  }

  /**
   * Get current auto-selection state for E2E testing
   * @returns {Object} Current state information
   */
  getAutoSelectionState() {
    try {
      const allPaths = this.dependencies.learningPathManager.getAllPaths();
      const currentSelections = this.dependencies.learningPathManager.getSelectedPaths();

      return {
        isEnabled: this.isEnabled(),
        totalPaths: allPaths.length,
        selectedPaths: currentSelections.length,
        availablePaths: allPaths.filter(path => !currentSelections.includes(path.id)),
        conflicts: this.detectConflicts(currentSelections),
        suggestions: this.getSuggestions(currentSelections, 'intermediate'), // Default level
        validation: this.validatePathSelections(currentSelections),
        lastAutoSelectionTime: this.lastAutoSelectionTime || null,
        performanceMetrics: this.getPerformanceMetrics()
      };
    } catch (error) {
      this.dependencies.errorHandler.handleError(error, 'AutoSelectionEngine.getAutoSelectionState');
      return {
        isEnabled: false,
        error: error.message,
        timestamp: Date.now()
      };
    }
  }

  /**
   * Test auto-selection with specific data for E2E testing
   * @param {Array<string>} pathIds - Path IDs to test
   * @param {string} userLevel - User level for testing
   * @returns {Object} Auto-selection result
   */
  testAutoSelection(pathIds, userLevel = 'intermediate') {
    try {
      const startTime = performance.now();

      // Validate inputs
      if (!Array.isArray(pathIds)) {
        throw new Error('pathIds must be an array');
      }

      // Get auto-selection recommendations
      const suggestions = this.getSuggestions(pathIds, userLevel);
      const conflicts = this.detectConflicts(pathIds);
      const validation = this.validatePathSelections(pathIds);

      const endTime = performance.now();

      return {
        success: true,
        suggestions,
        conflicts,
        validation,
        processingTime: endTime - startTime,
        testedPaths: pathIds.length,
        timestamp: Date.now()
      };
    } catch (error) {
      this.dependencies.errorHandler.handleError(error, 'AutoSelectionEngine.testAutoSelection');
      return {
        success: false,
        error: error.message,
        timestamp: Date.now()
      };
    }
  }

  /**
   * Force enable/disable auto-selection for E2E testing
   * @param {boolean} enabled - Whether to enable auto-selection
   * @returns {boolean} Success status
   */
  setEnabledForTesting(enabled) {
    try {
      if (enabled) {
        this.enable();
      } else {
        this.disable();
      }
      return this.isEnabled() === enabled;
    } catch (error) {
      this.dependencies.errorHandler.handleError(error, 'AutoSelectionEngine.setEnabledForTesting');
      return false;
    }
  }

  /**
   * Get performance metrics for E2E testing
   * @returns {Object} Performance metrics
   */
  getPerformanceMetrics() {
    return {
      isEnabled: this.isEnabled(),
      cacheSize: this.cache ? Object.keys(this.cache).length : 0,
      lastProcessingTime: this.lastProcessingTime || null,
      totalProcessedPaths: this.totalProcessedPaths || 0,
      averageProcessingTime: this.averageProcessingTime || 0,
      errorCount: this.errorCount || 0,
      lastErrorTime: this.lastErrorTime || null,
      memoryUsage: this._getMemoryUsage(),
      algorithmMetrics: {
        conflictDetectionCalls: this.conflictDetectionCalls || 0,
        suggestionCalls: this.suggestionCalls || 0,
        validationCalls: this.validationCalls || 0
      }
    };
  }

  /**
   * Validate component state for E2E testing
   * @returns {Object} Validation result
   */
  validateComponentState() {
    const validation = {
      isValid: true,
      issues: [],
      timestamp: Date.now()
    };

    try {
      // Check dependencies
      if (!this.dependencies) {
        validation.isValid = false;
        validation.issues.push('Missing dependencies object');
        return validation;
      }

      const requiredDeps = ['learningPathManager', 'errorHandler', 'debugHelper'];
      for (const dep of requiredDeps) {
        if (!this.dependencies[dep]) {
          validation.isValid = false;
          validation.issues.push(`Missing ${dep} dependency`);
        }
      }

      // Check configuration
      if (!this.config) {
        validation.isValid = false;
        validation.issues.push('Missing configuration');
      }

      // Test learning path manager functionality
      try {
        const paths = this.dependencies.learningPathManager.getAllPaths();
        if (!Array.isArray(paths)) {
          validation.issues.push('Learning path manager getAllPaths() should return array');
        }
      } catch (error) {
        validation.isValid = false;
        validation.issues.push(`Learning path manager error: ${error.message}`);
      }

      // Check for memory leaks
      const memoryUsage = this._getMemoryUsage();
      if (memoryUsage.cacheSize > 1000) {
        validation.issues.push('Potential memory leak: cache size too large');
      }

      // Validate algorithm state
      if (this.isEnabled()) {
        try {
          // Test with empty array to validate algorithm integrity
          const testResult = this.detectConflicts([]);
          if (!Array.isArray(testResult)) {
            validation.issues.push('Conflict detection algorithm not returning array');
          }
        } catch (error) {
          validation.issues.push(`Algorithm validation error: ${error.message}`);
        }
      }

      return validation;
    } catch (error) {
      validation.isValid = false;
      validation.issues.push(`Validation error: ${error.message}`);
      return validation;
    }
  }

  /**
   * Simulate error for E2E testing
   * @param {string} errorType - Type of error to simulate
   */
  simulateError(errorType) {
    switch (errorType) {
      case 'learning-path-manager':
        this.dependencies.learningPathManager = null;
        break;
      case 'invalid-path-data':
        // Override getAllPaths to return invalid data
        if (this.dependencies.learningPathManager) {
          this.dependencies.learningPathManager.getAllPaths = () => null;
        }
        break;
      case 'algorithm-failure':
        // Override core algorithm method to throw error
        this.detectConflicts = () => {
          throw new Error('Simulated algorithm failure');
        };
        break;
      case 'cache-corruption':
        this.cache = 'invalid-cache-data';
        break;
      case 'memory-leak':
        // Simulate memory leak by creating large cache
        this.cache = {};
        for (let i = 0; i < 10000; i++) {
          this.cache[`fake-path-${i}`] = { data: new Array(1000).fill('data') };
        }
        break;
      default:
        throw new Error(`Unknown error type: ${errorType}`);
    }
  }

  /**
   * Reset component to initial state for E2E testing
   * @returns {boolean} Success status
   */
  resetForTesting() {
    try {
      // Clear cache
      this.cache = {};

      // Reset counters
      this.totalProcessedPaths = 0;
      this.errorCount = 0;
      this.conflictDetectionCalls = 0;
      this.suggestionCalls = 0;
      this.validationCalls = 0;

      // Reset timing metrics
      this.lastProcessingTime = null;
      this.averageProcessingTime = 0;
      this.lastErrorTime = null;
      this.lastAutoSelectionTime = null;

      // Enable by default
      this.enable();

      return true;
    } catch (error) {
      this.dependencies.errorHandler.handleError(error, 'AutoSelectionEngine.resetForTesting');
      return false;
    }
  }

  /**
   * Get memory usage information for performance monitoring
   * @returns {Object} Memory usage data
   * @private
   */
  _getMemoryUsage() {
    return {
      cacheSize: this.cache ? Object.keys(this.cache).length : 0,
      cacheMemoryEstimate: this.cache ? JSON.stringify(this.cache).length : 0,
      configSize: this.config ? JSON.stringify(this.config).length : 0,
      dependenciesCount: this.dependencies ? Object.keys(this.dependencies).length : 0,
      isEnabled: this.isEnabled(),
      hasValidState: !!(this.dependencies && this.config)
    };
  }

  /**
   * Cleanup and destroy for E2E testing
   */
  destroyForTesting() {
    try {
      // Set destroyed flag
      this.isDestroyed = true;

      // Clear cache and internal caches
      this.cache = null;
      this._relatedPathsCache = undefined;
      this._dependencyCache = undefined;

      // Clear references
      this.dependencies = null;
      this.config = null;

      // Reset state
      this.enabled = false;

      // Clear metrics
      this.totalProcessedPaths = 0;
      this.errorCount = 0;
      this.lastProcessingTime = null;
      this.averageProcessingTime = 0;
      this.lastErrorTime = null;
      this.lastAutoSelectionTime = null;

      this.dependencies?.debugHelper?.log?.('AutoSelectionEngine destroyed');
    } catch (_error) {
      // Error during AutoSelectionEngine destruction - logged via debug helper
    }
  }
}
