/**
 * KataCatalog - Curated kata list management and recommendations
 *
 * Responsible for:
 * - Parsing kata directory structure and metadata
 * - Building searchable kata database
 * - Providing personalized recommendations
 * - Managing curated learning paths
 *
 * Features:
 * - Real-time kata discovery and indexing
 * - Intelligent recommendation engine
 * - Custom learning path creation
 * - Progress-based adaptive suggestions
 * - Category-based organization
 *
 * @class KataCatalog
 * @author Edge AI Team
 * @version 2.1.0
 * @since 1.0.0
 * @example
 * ```javascript
 * const dependencies = {
 *   errorHandler: globalThis.ErrorHandler || defaultErrorHandler,
 *   debugHelper: globalThis.DebugHelper || defaultDebugHelper,
 *   storageManager: globalThis.StorageManager || defaultStorageManager
 * };
 * const catalog = new KataCatalog(dependencies);
 * await catalog.initialize();
 *
 * const recommendations = catalog.getRecommendations(userProgress);
 * const allKatas = catalog.getAllKatas();
 * const customPath = catalog.createCustomPath('My Path', kataList);
 * ```
 */
export class KataCatalog {
    /**
     * Create a KataCatalog instance with dependency injection
     * @param {Object} dependencies - Injected dependencies
     * @param {Object} [dependencies.errorHandler] - Error handling service
     * @param {Object} [dependencies.debugHelper] - Debug logging service
     * @param {Object} [dependencies.storageManager] - Storage management service
     * @throws {Error} When localStorage is not available and persistence is required
     */
    constructor(dependencies = {}) {
        // Inject dependencies with safe fallbacks
        this.errorHandler = dependencies.errorHandler;
        this.debugHelper = dependencies.debugHelper;
        this.storageManager = dependencies.storageManager;

        // Initialize configuration
        this.config = {
            cacheExpiry: 3600000, // 1 hour
            maxRetries: 3,
            enableRecommendations: true,
            ...dependencies.config
        };

        // Initialize catalog data structures
        this.katas = new Map();
        this.categories = new Map();
        this.learningPaths = new Map();
        this.userPreferences = this.loadUserPreferences();
        this.isInitialized = false;

        // Safe initialization with error handling
        if (this.errorHandler) {
            this.errorHandler.safeExecute(() => {
                this.initializeBuiltInPaths();
            }, 'KataCatalog.constructor', () => {
                if (this.debugHelper) {
                    this.debugHelper.warn('KataCatalog: Failed to initialize built-in paths, continuing with empty catalog');
                }
            });
        } else {
            try {
                this.initializeBuiltInPaths();
            } catch {
                // Built-in paths initialization failed - continue with empty state
            }
        }
    }

    /**
     * Initialize the kata catalog by parsing the directory structure
     * @returns {Promise<void>}
     * @throws {Error} When kata directory loading or indexing fails
     */
    async initialize() {
        if (this.isInitialized) {return;}

        return this.errorHandler ?
            this.errorHandler.safeExecute(() => {
                this.loadKataDirectory();
                this.indexKataMetadata();
                this.isInitialized = true;

                if (this.debugHelper) {
                    this.debugHelper?.log?.('KataCatalog initialized successfully', {
                        kataCount: this.katas.size,
                        categoryCount: this.categories.size,
                        pathCount: this.learningPaths.size
                    });
                }
            }, 'KataCatalog.initialize', () => {
                if (this.debugHelper) {
                    this.debugHelper.error('Failed to initialize KataCatalog');
                }
                throw new Error('Failed to initialize KataCatalog');
            }) :
            this._initializeWithoutErrorHandler();
    }

    /**
     * Initialize without error handler (fallback method)
     * @returns {Promise<void>}
     * @private
     */
    async _initializeWithoutErrorHandler() {
        this.loadKataDirectory();
        this.indexKataMetadata();
        this.isInitialized = true;
    }

    /**
     * Load kata directory structure from learning
     * @returns {void}
     * @private
     */
    loadKataDirectory() {
        // Define the actual kata structure based on the workspace
        const kataStructure = {
            'ai-assisted-engineering': [
                '01-ai-development-fundamentals',
                '02-getting-started-basics',
                '03-getting-started-advanced'
            ],
            'task-planning': [
                '01-edge-documentation-planning',
                '02-repository-analysis-planning',
                '03-advanced-capability-integration',
                '04-pr-generation'
            ],
            'prompt-engineering': [
                '01-prompt-creation-and-refactoring-workflow',
                '02-basic-prompt-structure'
            ],
            'edge-deployment': [
                '01-deployment-basics',
                '05-deployment-expert'
            ],
            'adr-creation': [
                '01-basic-messaging-architecture',
                '02-advanced-observability-stack',
                '03-service-mesh-selection'
            ]
        };

        // Build kata catalog from structure
        for (const [category, kataList] of Object.entries(kataStructure)) {
            this.categories.set(category, {
                name: this.formatCategoryName(category),
                katas: kataList,
                description: this.getCategoryDescription(category)
            });

            // Create kata entries
            kataList.forEach((kataId, index) => {
                const kata = {
                    id: kataId,
                    category: category,
                    title: this.formatKataTitle(kataId),
                    sequence: index + 1,
                    path: `/learning/katas/${category}/${kataId}.md`,
                    // Default metadata - will be enriched by parsing
                    difficulty: this.inferDifficulty(kataId, index),
                    estimatedTime: this.inferEstimatedTime(kataId),
                    keywords: this.inferKeywords(kataId, category),
                    prerequisites: this.inferPrerequisites(kataId, index),
                    learningObjectives: []
                };

                this.katas.set(`${category}/${kataId}`, kata);
            });
        }
    }

    /**
     * Index kata metadata by parsing frontmatter (simulated for now)
     * @returns {void}
     * @private
     */
    indexKataMetadata() {
        // In a real implementation, this would fetch and parse the actual markdown files
        // For now, we'll enhance the existing entries with inferred metadata

        for (const [_key, kata] of this.katas) {
            // Enhance with more detailed metadata
            kata.tags = this.generateTags(kata);
            kata.nextKatas = this.findNextKatas(kata);
            kata.relatedKatas = this.findRelatedKatas(kata);
        }
    }

    /**
     * Get personalized kata recommendations based on user progress
     * @param {Object} userProgress - User's kata completion and rating data
     * @param {number} maxResults - Maximum number of recommendations to return
     * @returns {Array<Object>} Array of recommendation objects with kata and metadata
     */
    getRecommendations(userProgress = {}, maxResults = 5) {
        if (!this.isInitialized) {
            const warningMessage = 'KataCatalog not initialized. Call initialize() first.';
            if (this.debugHelper) {
                this.debugHelper.warn(warningMessage);
            }
            return [];
        }

        return this.errorHandler ?
            this.errorHandler.safeExecute(() => {
                return this._generateRecommendations(userProgress, maxResults);
            }, 'KataCatalog.getRecommendations', () => {
                if (this.debugHelper) {
                    this.debugHelper.error('Failed to generate recommendations');
                }
                return [];
            }) :
            this._generateRecommendationsSafe(userProgress, maxResults);
    }

    /**
     * Generate recommendations with error handling
     * @param {Object} userProgress - User's kata completion and rating data
     * @param {number} maxResults - Maximum number of recommendations to return
     * @returns {Array<Object>} Array of recommendation objects
     * @private
     */
    _generateRecommendations(userProgress, maxResults) {
        const recommendations = [];
        const completedKatas = new Set(Object.keys(userProgress));

        // Strategy 1: Next in sequence
        const sequenceRecommendations = this.getSequenceBasedRecommendations(completedKatas);
        recommendations.push(...sequenceRecommendations);

        // Strategy 2: Similar difficulty/topic
        const similarRecommendations = this.getSimilarKataRecommendations(userProgress);
        recommendations.push(...similarRecommendations);

        // Strategy 3: Fill knowledge gaps
        const gapRecommendations = this.getKnowledgeGapRecommendations(completedKatas);
        recommendations.push(...gapRecommendations);

        // Remove duplicates and limit results
        const uniqueRecommendations = this.deduplicateRecommendations(recommendations);
        return uniqueRecommendations.slice(0, maxResults);
    }

    /**
     * Generate recommendations with built-in error handling
     * @param {Object} userProgress - User's kata completion and rating data
     * @param {number} maxResults - Maximum number of recommendations to return
     * @returns {Array<Object>} Array of recommendation objects
     * @private
     */
    _generateRecommendationsSafe(userProgress, maxResults) {
        try {
            return this._generateRecommendations(userProgress, maxResults);
        } catch {
            // Failed to generate recommendations
            return [];
        }
    }

    /**
     * Get katas that should come next in learning sequences
     * @param {Set<string>} completedKatas - Set of completed kata keys
     * @returns {Array<Object>} Array of sequence-based recommendations
     * @private
     */
    getSequenceBasedRecommendations(completedKatas) {
        const recommendations = [];

        for (const [category, categoryData] of this.categories) {
            const categoryKatas = categoryData.katas;

            // Find the last completed kata in this category
            let lastCompleted = -1;
            for (let i = 0; i < categoryKatas.length; i++) {
                const kataKey = `${category}/${categoryKatas[i]}`;
                if (completedKatas.has(kataKey)) {
                    lastCompleted = i;
                }
            }

            // Recommend the next kata in sequence
            if (lastCompleted >= 0 && lastCompleted < categoryKatas.length - 1) {
                const nextKataId = categoryKatas[lastCompleted + 1];
                const nextKata = this.katas.get(`${category}/${nextKataId}`);
                if (nextKata) {
                    recommendations.push({
                        kata: nextKata,
                        reason: 'Next in sequence',
                        priority: 10,
                        category: 'sequence'
                    });
                }
            }
        }

        return recommendations;
    }

    /**
     * Find katas similar to those the user has completed and enjoyed
     * @param {Object} userProgress - User's kata completion and rating data
     * @returns {Array<Object>} Array of similarity-based recommendations
     * @private
     */
    getSimilarKataRecommendations(userProgress) {
        const recommendations = [];

        // Find highly rated completed katas
        const favoriteKatas = Object.entries(userProgress)
            .filter(([_, progress]) => progress.rating >= 4)
            .map(([kataKey, _]) => this.katas.get(kataKey))
            .filter(kata => kata);

        // Find similar katas
        favoriteKatas.forEach(favoriteKata => {
            const similar = this.findSimilarKatas(favoriteKata);
            similar.forEach(similarKata => {
                recommendations.push({
                    kata: similarKata,
                    reason: `Similar to ${favoriteKata.title}`,
                    priority: 7,
                    category: 'similar'
                });
            });
        });

        return recommendations;
    }

    /**
     * Identify knowledge gaps and recommend katas to fill them
     * @param {Set<string>} completedKatas - Set of completed kata keys
     * @returns {Array<Object>} Array of gap-filling recommendations
     * @private
     */
    getKnowledgeGapRecommendations(completedKatas) {
        const recommendations = [];

        // Check for incomplete categories
        for (const [category, categoryData] of this.categories) {
            const categoryCompletion = this.getCategoryCompletion(category, completedKatas);

            if (categoryCompletion > 0 && categoryCompletion < 0.5) {
                // User started this category but hasn't made significant progress
                const nextKata = this.getNextKataInCategory(category, completedKatas);
                if (nextKata) {
                    recommendations.push({
                        kata: nextKata,
                        reason: `Continue ${categoryData.name} learning path`,
                        priority: 8,
                        category: 'gap-filling'
                    });
                }
            }
        }

        return recommendations;
    }

    /**
     * Create a custom learning path
     * @param {string} pathName - Name for the custom learning path
     * @param {Array<string>} kataList - Array of kata keys to include
     * @param {string} description - Optional description for the path
     * @returns {Object} Created learning path object
     * @throws {Error} When pathName is invalid or kataList is empty
     */
    createCustomPath(pathName, kataList, description = '') {
        // Input validation
        if (!pathName || typeof pathName !== 'string' || pathName.trim().length === 0) {
            const error = new Error('Invalid path name: must be a non-empty string');
            if (this.debugHelper) {
                this.debugHelper.error('KataCatalog.createCustomPath: Invalid path name', { pathName });
            }
            throw error;
        }

        if (!Array.isArray(kataList) || kataList.length === 0) {
            const error = new Error('Invalid kata list: must be a non-empty array');
            if (this.debugHelper) {
                this.debugHelper.error('KataCatalog.createCustomPath: Invalid kata list', { kataList });
            }
            throw error;
        }

        return this.errorHandler ?
            this.errorHandler.safeExecute(() => {
                return this._createCustomPathInternal(pathName, kataList, description);
            }, 'KataCatalog.createCustomPath', (error) => {
                if (this.debugHelper) {
                    this.debugHelper.error('Failed to create custom path', { pathName, error });
                }
                throw error;
            }) :
            this._createCustomPathSafe(pathName, kataList, description);
    }

    /**
     * Internal method to create custom path
     * @param {string} pathName - Name for the custom learning path
     * @param {Array<string>} kataList - Array of kata keys to include
     * @param {string} description - Optional description for the path
     * @returns {Object} Created learning path object
     * @private
     */
    _createCustomPathInternal(pathName, kataList, description) {
        const path = {
            id: this.generatePathId(pathName),
            name: pathName,
            description: description,
            katas: kataList,
            isCustom: true,
            createdAt: Date.now(),
            estimatedDuration: this.calculatePathDuration(kataList)
        };

        this.learningPaths.set(path.id, path);
        this.saveUserPreferences();

        if (this.debugHelper) {
            this.debugHelper?.log?.('Custom learning path created', {
                pathId: path.id,
                kataCount: kataList.length
            });
        }

        return path;
    }

    /**
     * Create custom path with built-in error handling
     * @param {string} pathName - Name for the custom learning path
     * @param {Array<string>} kataList - Array of kata keys to include
     * @param {string} description - Optional description for the path
     * @returns {Object} Created learning path object
     * @private
     */
    _createCustomPathSafe(pathName, kataList, description) {
        return this._createCustomPathInternal(pathName, kataList, description);
    }

    /**
     * Initialize built-in learning paths
     * @private
     */
    initializeBuiltInPaths() {
        const paths = [
            {
                id: 'beginner-fundamentals',
                name: 'Beginner Fundamentals',
                description: 'Essential skills for AI-assisted development newcomers',
                katas: [
                    'ai-assisted-engineering/01-ai-development-fundamentals',
                    'ai-assisted-engineering/02-getting-started-basics',
                    'prompt-engineering/01-prompt-creation-and-refactoring-workflow'
                ],
                isCustom: false
            },
            {
                id: 'task-planning-mastery',
                name: 'Task Planning Mastery',
                description: 'Complete task planning and project management skills',
                katas: [
                    'task-planning/01-edge-documentation-planning',
                    'task-planning/02-repository-analysis-planning',
                    'task-planning/03-advanced-capability-integration',
                    'task-planning/04-pr-generation'
                ],
                isCustom: false
            },
            {
                id: 'deployment-specialist',
                name: 'Deployment Specialist',
                description: 'Master edge deployment and infrastructure management',
                katas: [
                    'edge-deployment/01-deployment-basics',
                    'adr-creation/01-basic-messaging-architecture',
                    'edge-deployment/05-deployment-expert'
                ],
                isCustom: false
            }
        ];

        paths.forEach(path => {
            path.estimatedDuration = this.calculatePathDuration(path.katas);
            this.learningPaths.set(path.id, path);
        });
    }

    /**
     * Utility methods for kata metadata inference
     */

    /**
     * Format category name for display
     * @param {string} category - Raw category name
     * @returns {string} Formatted category name
     * @private
     */
    formatCategoryName(category) {
        return category.split('-').map(word =>
            word.charAt(0).toUpperCase() + word.slice(1)
        ).join(' ');
    }

    /**
     * Format kata title for display
     * @param {string} kataId - Raw kata ID
     * @returns {string} Formatted kata title
     * @private
     */
    formatKataTitle(kataId) {
        return kataId.replace(/^\d+-/, '').split('-').map(word =>
            word.charAt(0).toUpperCase() + word.slice(1)
        ).join(' ');
    }

    /**
     * Get category description
     * @param {string} category - Category name
     * @returns {string} Category description
     * @private
     */
    getCategoryDescription(category) {
        const descriptions = {
            'ai-assisted-engineering': 'Master AI-assisted development workflows and hyper-velocity engineering',
            'task-planning': 'Learn systematic task planning and project management methodologies',
            'prompt-engineering': 'Develop advanced prompt engineering and AI interaction skills',
            'edge-deployment': 'Practice edge computing deployment and infrastructure management',
            'adr-creation': 'Master architectural decision records and system design documentation'
        };
        return descriptions[category] || 'Enhance your technical skills with hands-on practice';
    }

    inferDifficulty(kataId, sequence) {
        if (sequence === 0) {return 'beginner';}
        if (sequence <= 2) {return 'intermediate';}
        return 'advanced';
    }

    inferEstimatedTime(kataId) {
        if (kataId.includes('basic') || kataId.includes('fundamentals')) {return '25-35 minutes';}
        if (kataId.includes('advanced') || kataId.includes('expert')) {return '45-60 minutes';}
        return '30-40 minutes';
    }

    inferKeywords(kataId, category) {
        const baseKeywords = ['learning', category];
        const titleWords = kataId.replace(/^\d+-/, '').split('-');
        return [...baseKeywords, ...titleWords];
    }

    inferPrerequisites(kataId, sequence) {
        if (sequence === 0) {return ['Basic development concepts'];}
        return [`Previous katas in this category`];
    }

    generateTags(kata) {
        return [kata.difficulty, kata.category, ...kata.keywords.slice(0, 3)];
    }

    findNextKatas(kata) {
        const categoryData = this.categories.get(kata.category);
        if (!categoryData) {return [];}

        const currentIndex = categoryData.katas.indexOf(kata.id);
        if (currentIndex >= 0 && currentIndex < categoryData.katas.length - 1) {
            const nextId = categoryData.katas[currentIndex + 1];
            return [`${kata.category}/${nextId}`];
        }
        return [];
    }

    findRelatedKatas(kata) {
        const related = [];
        for (const [key, otherKata] of this.katas) {
            if (key !== `${kata.category}/${kata.id}` &&
                otherKata.difficulty === kata.difficulty) {
                related.push(key);
            }
        }
        return related.slice(0, 3);
    }

    findSimilarKatas(kata) {
        const similar = [];
        for (const [_, otherKata] of this.katas) {
            if (otherKata.id !== kata.id &&
                (otherKata.category === kata.category ||
                 otherKata.difficulty === kata.difficulty)) {
                similar.push(otherKata);
            }
        }
        return similar.slice(0, 3);
    }

    getCategoryCompletion(category, completedKatas) {
        const categoryData = this.categories.get(category);
        if (!categoryData) {return 0;}

        const completed = categoryData.katas.filter(kataId =>
            completedKatas.has(`${category}/${kataId}`)
        ).length;

        return completed / categoryData.katas.length;
    }

    getNextKataInCategory(category, completedKatas) {
        const categoryData = this.categories.get(category);
        if (!categoryData) {return null;}

        for (const kataId of categoryData.katas) {
            const kataKey = `${category}/${kataId}`;
            if (!completedKatas.has(kataKey)) {
                return this.katas.get(kataKey);
            }
        }
        return null;
    }

    deduplicateRecommendations(recommendations) {
        const seen = new Set();
        return recommendations.filter(rec => {
            const key = `${rec.kata.category}/${rec.kata.id}`;
            if (seen.has(key)) {return false;}
            seen.add(key);
            return true;
        }).sort((a, b) => b.priority - a.priority);
    }

    calculatePathDuration(kataList) {
        return kataList.length * 35; // Average 35 minutes per kata
    }

    generatePathId(pathName) {
        return `${pathName.toLowerCase().replace(/\s+/g, '-') }-${ Date.now()}`;
    }

    /**
     * Load user preferences from storage
     * @returns {Object} User preferences object
     * @private
     */
    loadUserPreferences() {
        if (this.storageManager) {
            return this.storageManager.safeGetLocalStorage('kata-catalog-preferences', {});
        }

        return this.errorHandler ?
            this.errorHandler.safeExecute(() => {
                const saved = localStorage.getItem('kata-catalog-preferences');
                return saved ? JSON.parse(saved) : {};
            }, 'KataCatalog.loadUserPreferences', () => {
                if (this.debugHelper) {
                    this.debugHelper.warn('Failed to load user preferences, using defaults');
                }
                return {};
            }) :
            this._loadUserPreferencesSafe();
    }

    /**
     * Load user preferences with built-in error handling
     * @returns {Object} User preferences object
     * @private
     */
    _loadUserPreferencesSafe() {
        try {
            const saved = localStorage.getItem('kata-catalog-preferences');
            return saved ? JSON.parse(saved) : {};
        } catch {
            // Failed to load user preferences
            return {};
        }
    }

    /**
     * Save user preferences to storage
     * @returns {boolean} True if saved successfully
     * @private
     */
    saveUserPreferences() {
        if (this.storageManager) {
            return this.storageManager.safeSetLocalStorage('kata-catalog-preferences', this.userPreferences);
        }

        return this.errorHandler ?
            this.errorHandler.safeExecute(() => {
                localStorage.setItem('kata-catalog-preferences', JSON.stringify(this.userPreferences));
                return true;
            }, 'KataCatalog.saveUserPreferences', () => {
                if (this.debugHelper) {
                    this.debugHelper.warn('Failed to save user preferences');
                }
                return false;
            }) :
            this._saveUserPreferencesSafe();
    }

    /**
     * Save user preferences with built-in error handling
     * @returns {boolean} True if saved successfully
     * @private
     */
    _saveUserPreferencesSafe() {
        try {
            localStorage.setItem('kata-catalog-preferences', JSON.stringify(this.userPreferences));
            return true;
        } catch {
            // Failed to save user preferences
            return false;
        }
    }

    /**
     * Public API methods
     */

    /**
     * Get all katas in the catalog
     * @returns {Array<Object>} Array of all kata objects
     */
    getAllKatas() {
        return Array.from(this.katas.values());
    }

    /**
     * Get all categories in the catalog
     * @returns {Array<Object>} Array of all category objects
     */
    getAllCategories() {
        return Array.from(this.categories.values());
    }

    /**
     * Get all learning paths in the catalog
     * @returns {Array<Object>} Array of all learning path objects
     */
    getAllLearningPaths() {
        const uniquePaths = [];
        const seenKeys = new Set();

        for (const path of this.learningPaths.values()) {
            if (!path) {continue;}

            const dedupeKey = path.id ?? `${(path.name || '').toLowerCase()}::${(path.katas || []).join('|')}`;
            if (seenKeys.has(dedupeKey)) {continue;}

            seenKeys.add(dedupeKey);
            uniquePaths.push(path);
        }

        return uniquePaths;
    }

    /**
     * Get a specific kata by ID
     * @param {string} kataId - The kata ID to retrieve
     * @returns {Object|null} Kata object or null if not found
     */
    getKataById(kataId) {
        // First try direct lookup
        const kata = this.katas.get(kataId);
        if (kata) {return kata;}

        // Then search by kata.id property
        for (const [_, kata] of this.katas) {
            if (kata.id === kataId) {
                return kata;
            }
        }

        return null;
    }

    /**
     * Search katas by query and filters
     * @param {string} query - Search query string
     * @param {Object} filters - Optional filters (difficulty, category, maxDuration)
     * @returns {Array<Object>} Array of matching kata objects
     */
    searchKatas(query, filters = {}) {
        if (!this.isInitialized) {
            const warningMessage = 'KataCatalog not initialized. Call initialize() first.';
            if (this.debugHelper) {
                this.debugHelper.warn(warningMessage);
            }
            return [];
        }

        return this.errorHandler ?
            this.errorHandler.safeExecute(() => {
                return this._searchKatasInternal(query, filters);
            }, 'KataCatalog.searchKatas', []) :
            this._searchKatasSafe(query, filters);
    }

    /**
     * Internal search implementation
     * @param {string} query - Search query string
     * @param {Object} filters - Optional filters
     * @returns {Array<Object>} Array of matching kata objects
     * @private
     */
    _searchKatasInternal(query, filters) {
        const results = [];
        const searchTerm = query.toLowerCase();
        const safeFilters = filters || {};

        for (const kata of this.katas.values()) {
            // Text search
            const matchesText = kata.title.toLowerCase().includes(searchTerm) ||
                               (kata.keywords && kata.keywords.some(k => k.toLowerCase().includes(searchTerm))) ||
                               (kata.tags && kata.tags.some(t => t.toLowerCase().includes(searchTerm)));

            // Filter checks
            const matchesFilters = this.checkFilters(kata, safeFilters);

            if (matchesText && matchesFilters) {
                results.push(kata);
            }
        }

        return results;
    }

    /**
     * Search katas with built-in error handling
     * @param {string} query - Search query string
     * @param {Object} filters - Optional filters
     * @returns {Array<Object>} Array of matching kata objects
     * @private
     */
    _searchKatasSafe(query, filters) {
        try {
            return this._searchKatasInternal(query, filters);
        } catch {
            // Failed to search katas
            return [];
        }
    }

    /**
     * Check if kata matches the given filters
     * @param {Object} kata - Kata object to check
     * @param {Object} filters - Filter criteria
     * @returns {boolean} True if kata matches all filters
     * @private
     */
    checkFilters(kata, filters) {
        if (!filters) {return true;}

        if (filters.difficulty && kata.difficulty !== filters.difficulty) {return false;}
        if (filters.category && kata.category !== filters.category) {return false;}
        if (filters.maxDuration && this.parseDuration(kata.estimatedTime) > filters.maxDuration) {return false;}
        if (filters.tags && filters.tags.length > 0) {
            const hasMatchingTag = filters.tags.some(tag => kata.tags && kata.tags.includes(tag));
            if (!hasMatchingTag) {return false;}
        }
        return true;
    }

    /**
     * Parse duration string to minutes
     * @param {string} durationStr - Duration string (e.g., "25-35 minutes")
     * @returns {number} Duration in minutes
     * @private
     */
    parseDuration(durationStr) {
        const match = durationStr.match(/(\d+)/);
        return match ? parseInt(match[1]) : 30;
    }

    /**
     * Load katas from localStorage
     * @returns {Array<Object>} Array of kata objects from storage
     */
    loadKatas() {
        return this.errorHandler ?
            this.errorHandler.safeExecute(() => {
                const stored = localStorage.getItem('kata-catalog');
                return stored ? JSON.parse(stored) : [];
            }, 'KataCatalog.loadKatas', []) :
            this._loadKatasSafe();
    }

    /**
     * Load katas with built-in error handling
     * @returns {Array<Object>} Array of kata objects from storage
     * @private
     */
    _loadKatasSafe() {
        try {
            const stored = localStorage.getItem('kata-catalog');
            return stored ? JSON.parse(stored) : [];
        } catch {
            // Failed to load katas from storage
            return [];
        }
    }

    /**
     * Save katas to localStorage
     * @returns {boolean} True if saved successfully
     * @private
     */
    _saveKatas() {
        return this.errorHandler ?
            this.errorHandler.safeExecute(() => {
                const katasArray = Array.from(this.katas.values());
                localStorage.setItem('kata-catalog', JSON.stringify(katasArray));
                return true;
            }, 'KataCatalog._saveKatas', () => {
                if (this.debugHelper) {
                    this.debugHelper.warn('Failed to save katas to storage');
                }
                return false;
            }) :
            this._saveKatasSafe();
    }

    /**
     * Save katas with built-in error handling
     * @returns {boolean} True if saved successfully
     * @private
     */
    _saveKatasSafe() {
        try {
            const katasArray = Array.from(this.katas.values());
            localStorage.setItem('kata-catalog', JSON.stringify(katasArray));
            return true;
        } catch {
            // Failed to save katas to storage
            return false;
        }
    }

    /**
     * Validate kata structure
     * @param {Object} kata - Kata object to validate
     * @returns {boolean} True if kata is valid
     * @private
     */
    _validateKata(kata) {
        const requiredFields = ['id', 'title'];
        return requiredFields.every(field => kata && typeof kata[field] === 'string' && kata[field].trim());
    }

    /**
     * Add a new kata to the catalog
     * @param {Object} kata - Kata object to add
     * @returns {boolean} True if added successfully
     */
    addKata(kata) {
        if (!this._validateKata(kata)) {
            if (this.errorHandler) {
                this.errorHandler.recordError(new Error('Invalid kata structure'), 'KataCatalog.addKata');
            }
            return false;
        }

        return this.errorHandler ?
            this.errorHandler.safeExecute(() => {
                const fullKey = kata.category ? `${kata.category}/${kata.id}` : kata.id;
                this.katas.set(fullKey, kata);
                this._saveKatas();
                return true;
            }, 'KataCatalog.addKata', () => {
                if (this.debugHelper) {
                    this.debugHelper.error('Failed to add kata', { kata });
                }
                return false;
            }) :
            this._addKataSafe(kata);
    }

    /**
     * Add kata with built-in error handling
     * @param {Object} kata - Kata object to add
     * @returns {boolean} True if added successfully
     * @private
     */
    _addKataSafe(kata) {
        try {
            const fullKey = kata.category ? `${kata.category}/${kata.id}` : kata.id;
            this.katas.set(fullKey, kata);
            this._saveKatas();
            return true;
        } catch {
            // Failed to add kata
            return false;
        }
    }

    /**
     * Update an existing kata in the catalog
     * @param {string} kataId - ID of the kata to update
     * @param {Object} updatedData - Updated kata data
     * @returns {boolean} True if updated successfully
     */
    updateKata(kataId, updatedData) {
        return this.errorHandler ?
            this.errorHandler.safeExecute(() => {
                // Find the kata by ID across all possible keys
                let kataKey = null;
                for (const [key, kata] of this.katas) {
                    if (kata.id === kataId || key === kataId) {
                        kataKey = key;
                        break;
                    }
                }

                if (kataKey) {
                    this.katas.set(kataKey, { ...this.katas.get(kataKey), ...updatedData });
                    this._saveKatas();
                    return true;
                }
                return false;
            }, 'KataCatalog.updateKata', () => {
                if (this.debugHelper) {
                    this.debugHelper.error('Failed to update kata', { kataId, updatedData });
                }
                return false;
            }) :
            this._updateKataSafe(kataId, updatedData);
    }

    /**
     * Update kata with built-in error handling
     * @param {string} kataId - ID of the kata to update
     * @param {Object} updatedData - Updated kata data
     * @returns {boolean} True if updated successfully
     * @private
     */
    _updateKataSafe(kataId, updatedData) {
        try {
            // Find the kata by ID across all possible keys
            let kataKey = null;
            for (const [key, kata] of this.katas) {
                if (kata.id === kataId || key === kataId) {
                    kataKey = key;
                    break;
                }
            }

            if (kataKey) {
                this.katas.set(kataKey, { ...this.katas.get(kataKey), ...updatedData });
                this._saveKatas();
                return true;
            }
            return false;
        } catch {
            // Failed to update kata
            return false;
        }
    }

    /**
     * Remove a kata from the catalog
     * @param {string} kataId - ID of the kata to remove
     * @returns {boolean} True if removed successfully
     */
    removeKata(kataId) {
        return this.errorHandler ?
            this.errorHandler.safeExecute(() => {
                // Find and remove the kata by ID across all possible keys
                let kataKey = null;
                for (const [key, kata] of this.katas) {
                    if (kata.id === kataId || key === kataId) {
                        kataKey = key;
                        break;
                    }
                }

                if (kataKey) {
                    this.katas.delete(kataKey);
                    this._saveKatas();
                    return true;
                }
                return false;
            }, 'KataCatalog.removeKata', () => {
                if (this.debugHelper) {
                    this.debugHelper.error('Failed to remove kata', { kataId });
                }
                return false;
            }) :
            this._removeKataSafe(kataId);
    }

    /**
     * Remove kata with built-in error handling
     * @param {string} kataId - ID of the kata to remove
     * @returns {boolean} True if removed successfully
     * @private
     */
    _removeKataSafe(kataId) {
        try {
            // Find and remove the kata by ID across all possible keys
            let kataKey = null;
            for (const [key, kata] of this.katas) {
                if (kata.id === kataId || key === kataId) {
                    kataKey = key;
                    break;
                }
            }

            if (kataKey) {
                this.katas.delete(kataKey);
                this._saveKatas();
                return true;
            }
            return false;
        } catch {
            // Failed to remove kata
            return false;
        }
    }

    /**
     * Filter katas by difficulty level
     * @param {string} difficulty - Difficulty level to filter by
     * @returns {Array<Object>} Array of katas matching the difficulty
     */
    filterByDifficulty(difficulty) {
        return Array.from(this.katas.values()).filter(kata => kata.difficulty === difficulty);
    }

    /**
     * Filter katas by tag
     * @param {string} tag - Tag to filter by
     * @returns {Array<Object>} Array of katas containing the tag
     */
    filterByTag(tag) {
        return Array.from(this.katas.values()).filter(kata =>
            kata.tags && kata.tags.includes(tag)
        );
    }

    /**
     * Get all available categories
     * @returns {Array<string>} Array of category names
     */
    getCategories() {
        return Array.from(this.categories.keys());
    }

    /**
     * Get katas by category
     * @param {string} category - Category name
     * @returns {Array<Object>} Array of katas in the category
     */
    getKatasByCategory(category) {
        return Array.from(this.katas.values()).filter(kata => kata.category === category);
    }

    /**
     * Get catalog statistics
     * @returns {Object} Statistics object with totals and breakdowns
     */
    getStatistics() {
        const katas = Array.from(this.katas.values());
        const difficulties = {};
        const categories = {};

        katas.forEach(kata => {
            // Count difficulties
            if (kata.difficulty) {
                difficulties[kata.difficulty] = (difficulties[kata.difficulty] || 0) + 1;
            }

            // Count categories
            if (kata.category) {
                categories[kata.category] = (categories[kata.category] || 0) + 1;
            }
        });

        return {
            totalKatas: katas.length,
            difficulties,
            categories
        };
    }

    /**
     * Get most popular katas
     * @param {number} limit - Maximum number of katas to return
     * @returns {Array<Object>} Array of most popular katas
     */
    getMostPopular(limit = 10) {
        // For now, return katas sorted by title (in real implementation, this would be based on usage data)
        const katas = Array.from(this.katas.values());
        return katas
            .sort((a, b) => a.title.localeCompare(b.title))
            .slice(0, limit);
    }

    /**
     * Update configuration
     * @param {Object} newConfig - Configuration updates to apply
     * @returns {void}
     */
    updateConfig(newConfig) {
        this.config = { ...this.config, ...newConfig };

        if (this.debugHelper) {
            this.debugHelper.log('KataCatalog configuration updated', { config: this.config });
        }
    }

    /**
     * Destroy the catalog and clean up resources
     * @returns {void}
     */
    destroy() {
        return this.errorHandler ?
            this.errorHandler.safeExecute(() => {
                this.katas.clear();
                this.categories.clear();
                this.learningPaths.clear();
                this.userPreferences = {};
                this.isInitialized = false;

                if (this.debugHelper) {
                    this.debugHelper.log('KataCatalog destroyed and resources cleaned up');
                }
            }, 'KataCatalog.destroy', () => {
                if (this.debugHelper) {
                    this.debugHelper.error('Error during KataCatalog cleanup');
                }
            }) :
            this._destroySafe();
    }

    /**
     * Clear all katas from the catalog (for testing)
     * @returns {void}
     */
    clearKatas() {
        this.katas.clear();
        this.categories.clear();
    }

    /**
     * Destroy with built-in error handling
     * @returns {void}
     * @private
     */
    _destroySafe() {
        try {
            this.katas.clear();
            this.categories.clear();
            this.learningPaths.clear();
            this.userPreferences = {};
            this.isInitialized = false;
        } catch {
            // Error during KataCatalog cleanup
        }
    }
}

// ES6 Module Export
export default KataCatalog;
