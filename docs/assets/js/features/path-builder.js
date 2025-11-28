/**
 * Path Builder Feature
 * Provides learning path construction and customization functionality for creating personalized learning journeys
 * @version 2.0.0
 */

/**
 * Path Builder Manager
 * Handles learning path construction, management, validation, and customization
 */
export class PathBuilder {
  /**
   * Creates a new PathBuilder instance
   * @param {Object} dependencies - Injected dependencies
   * @param {Object} dependencies.errorHandler - Error handling service
   * @param {Object} dependencies.domUtils - DOM manipulation utilities
   * @param {Object} dependencies.debugHelper - Debug logging helper
   */
  constructor(dependencies = {}) {
    this.errorHandler = dependencies.errorHandler || this.createDefaultErrorHandler();
    this.domUtils = dependencies.domUtils || this.createDefaultDomUtils();
    this.debugHelper = dependencies.debugHelper || this.createDefaultDebugHelper();

    // Initialize configuration
    this.config = this.loadConfiguration();
    this.pathTemplates = new Map();
    this.activePaths = new Map();
    this.pathData = new Map();
    this.pathValidators = new Map();
    this.currentPath = null;
    this.isInitialized = false;

    this.initialize();
  }

  /**
   * Load configuration settings
   * @private
   * @returns {Object} Configuration object
   */
  loadConfiguration() {
    return {
      defaultPathTemplate: 'basic-path',
      maxPathComponents: 20,
      maxPathLength: 50,
      minPathLength: 1,
      autoSave: true,
      validationRules: {
        minTitle: 3,
        maxTitle: 100,
        minDescription: 10,
        maxDescription: 500
      },
      categories: ['programming', 'design', 'data-science', 'devops'],
      templateCategories: ['programming', 'web-development', 'data-science', 'design', 'devops'],
      difficulties: ['beginner', 'intermediate', 'advanced'],
      storageKey: 'path-builder-data',
      validationStrict: false
    };
  }

  /**
   * Display error message to user
   * @private
   * @param {Error} _error - Error object
   */
  displayPathBuildError(_error) {
    const messageContainer = this.domUtils.querySelector('#path-builder-messages');
    if (messageContainer) {
      messageContainer.innerHTML = `
        <div class="error-message">
          <h3>Path Creation Failed</h3>
          <p>${_error.message}</p>
        </div>`;
    }
  }

  /**
   * Create default error handler
   * @private
   * @returns {Object} Default error handler
   */
  /**
   * Create default error handler
   * @private
   * @returns {Object} Default error handler
   */
  createDefaultErrorHandler() {
    return {
      safeExecute: (fn) => {
        try {
          return fn();
        } catch {
          // Error in PathBuilder operation - logged for debugging
          return null;
        }
      }
    };
  }

  /**
   * Create default DOM utilities
   * @private
   * @returns {Object} Default DOM utilities
   */
  createDefaultDomUtils() {
    return {
      querySelector: (selector) => {
        if (typeof document !== 'undefined' && document.querySelector) {
          return document.querySelector(selector);
        }
        return null;
      },
      querySelectorAll: (selector) => {
        if (typeof document !== 'undefined' && document.querySelectorAll) {
          return document.querySelectorAll(selector);
        }
        return [];
      },
      createElement: (tag) => {
        if (typeof document !== 'undefined' && document.createElement) {
          return document.createElement(tag);
        }
        return null;
      },
      addClass: (element, className) => element?.classList.add(className),
      removeClass: (element, className) => element?.classList.remove(className)
    };
  }

  /**
   * Create default debug helper
   * @private
   * @returns {Object} Default debug helper
   */
  createDefaultDebugHelper() {
    return {
      log: (..._args) => {
        // PathBuilder debug logging disabled for production
      }
    };
  }

  /**
   * Initialize the path builder system
   * @returns {boolean} Success status
   */
  initialize() {
    return this.errorHandler.safeExecute(() => {
      if (this.isInitialized) {
        this.debugHelper?.log?.('Already initialized');
        return true;
      }

      this.debugHelper?.log?.('Initializing path builder...');

      this.abortController = new AbortController();

      // Set up event listeners for path building interface
      this.setupEventListeners();

      // Initialize path templates
      this.initializePathTemplates();

      // Load saved path data
      this.loadSavedData();

      // Initialize path building UI if present
      this.initializePathBuilderUI();

      this.isInitialized = true;
      this.debugHelper?.log?.('Path builder initialized successfully');
      return true;
    }) || false;
  }

  /**
   * Initialize path templates
   * @private
   */
  initializePathTemplates() {
    // Programming path template
    this.pathTemplates.set('programming-fundamentals', {
      id: 'programming-fundamentals',
      title: 'Programming Fundamentals',
      category: 'programming',
      description: 'Essential programming concepts and skills',
      estimatedWeeks: 12,
      difficulty: 'beginner',
      components: [
        { id: 'intro-programming', title: 'Introduction to Programming', type: 'lesson', weeks: 2 },
        { id: 'variables-datatypes', title: 'Variables and Data Types', type: 'lesson', weeks: 1 },
        { id: 'control-structures', title: 'Control Structures', type: 'lesson', weeks: 2 },
        { id: 'functions', title: 'Functions and Procedures', type: 'lesson', weeks: 2 },
        { id: 'data-structures', title: 'Basic Data Structures', type: 'lesson', weeks: 2 },
        { id: 'debugging', title: 'Debugging Techniques', type: 'lesson', weeks: 1 },
        { id: 'final-project', title: 'Final Project', type: 'project', weeks: 2 }
      ]
    });

    // Web development path template
    this.pathTemplates.set('web-development-complete', {
      id: 'web-development-complete',
      title: 'Complete Web Development',
      category: 'web-development',
      description: 'Full-stack web development skills',
      estimatedWeeks: 20,
      difficulty: 'intermediate',
      components: [
        { id: 'html-css', title: 'HTML & CSS Fundamentals', type: 'lesson', weeks: 3 },
        { id: 'javascript-basics', title: 'JavaScript Basics', type: 'lesson', weeks: 3 },
        { id: 'responsive-design', title: 'Responsive Design', type: 'lesson', weeks: 2 },
        { id: 'frontend-frameworks', title: 'Frontend Frameworks', type: 'lesson', weeks: 4 },
        { id: 'backend-basics', title: 'Backend Development', type: 'lesson', weeks: 4 },
        { id: 'databases', title: 'Database Integration', type: 'lesson', weeks: 2 },
        { id: 'deployment', title: 'Deployment and DevOps', type: 'lesson', weeks: 2 }
      ]
    });

    // Data science path template
    this.pathTemplates.set('data-science-intro', {
      id: 'data-science-intro',
      title: 'Introduction to Data Science',
      category: 'data-science',
      description: 'Data science fundamentals and analysis',
      estimatedWeeks: 16,
      difficulty: 'intermediate',
      components: [
        { id: 'python-data', title: 'Python for Data Science', type: 'lesson', weeks: 3 },
        { id: 'statistics', title: 'Statistics and Probability', type: 'lesson', weeks: 3 },
        { id: 'data-manipulation', title: 'Data Manipulation', type: 'lesson', weeks: 2 },
        { id: 'visualization', title: 'Data Visualization', type: 'lesson', weeks: 2 },
        { id: 'machine-learning', title: 'Machine Learning Basics', type: 'lesson', weeks: 4 },
        { id: 'projects', title: 'Capstone Projects', type: 'project', weeks: 2 }
      ]
    });
  }

  /**
   * Set up event listeners for path builder interface
   * @private
   */
  setupEventListeners() {
    const signal = this.abortController.signal;

    // Path creation form
    const pathForm = this.domUtils.querySelector('#path-builder-form');
    if (pathForm) {
      pathForm.addEventListener('submit', (event) => {
        event.preventDefault();
        this.handlePathFormSubmit(event);
      }, { signal });
    }

    // Component addition buttons
    const addComponentBtns = this.domUtils.querySelectorAll('.add-component-btn');
    addComponentBtns.forEach(btn => {
      btn.addEventListener('click', (event) => {
        this.handleAddComponent(event);
      }, { signal });
    });

    // Template selection
    const templateSelect = this.domUtils.querySelector('#path-template-select');
    if (templateSelect) {
      templateSelect.addEventListener('change', (event) => {
        this.handleTemplateSelection(event);
      }, { signal });
    }

    // Path validation
    const validateBtn = this.domUtils.querySelector('#validate-path-btn');
    if (validateBtn) {
      validateBtn.addEventListener('click', (event) => {
        this.handlePathValidation(event);
      }, { signal });
    }

    // Save and load buttons
    const saveBtn = this.domUtils.querySelector('#save-path-btn');
    if (saveBtn) {
      saveBtn.addEventListener('click', (event) => {
        this.handleSavePath(event);
      }, { signal });
    }

    const loadBtn = this.domUtils.querySelector('#load-path-btn');
    if (loadBtn) {
      loadBtn.addEventListener('click', (event) => {
        this.handleLoadPath(event);
      }, { signal });
    }
  }

  /**
   * Initialize path builder UI components
   * @private
   */
  initializePathBuilderUI() {
    const pathBuilderContainer = this.domUtils.querySelector('#path-builder-container');
    if (!pathBuilderContainer) {return;}

    // Populate template dropdown
    this.populateTemplateDropdown();

    // Initialize drag and drop for component reordering
    this.initializeDragAndDrop();

    // Set up progress tracking
    this.setupProgressTracking();
  }

  /**
   * Populate template dropdown with available templates
   * @private
   */
  populateTemplateDropdown() {
    const templateSelect = this.domUtils.querySelector('#path-template-select');
    if (!templateSelect) {return;}

    // Clear existing options
    templateSelect.innerHTML = '<option value="">Select a template...</option>';

    // Group templates by category
    const templatesByCategory = new Map();
    this.pathTemplates.forEach(template => {
      if (!templatesByCategory.has(template.category)) {
        templatesByCategory.set(template.category, []);
      }
      templatesByCategory.get(template.category).push(template);
    });

    // Add options grouped by category
    templatesByCategory.forEach((templates, category) => {
      const optgroup = this.domUtils.createElement('optgroup');
      optgroup.label = category.replace('-', ' ').toUpperCase();

      templates.forEach(template => {
        const option = this.domUtils.createElement('option');
        option.value = template.id;
        option.textContent = `${template.title} (${template.estimatedWeeks} weeks)`;
        optgroup.appendChild(option);
      });

      templateSelect.appendChild(optgroup);
    });
  }

  /**
   * Build a custom learning path
   * @param {Array} components - Learning path components
   * @param {Object} metadata - Path metadata
   * @returns {Object} Built path configuration
   */
  buildPath(components = [], metadata = {}) {
    return this.errorHandler.safeExecute(() => {
      const pathId = metadata.id || `path-${Date.now()}`;

      const pathConfig = {
        id: pathId,
        title: metadata.title || 'Custom Learning Path',
        description: metadata.description || 'User-created learning path',
        category: metadata.category || 'custom',
        difficulty: metadata.difficulty || 'beginner',
        components: this.processComponents(components),
        estimatedWeeks: this.calculateEstimatedWeeks(components),
        createdAt: new Date().toISOString(),
        version: '1.0.0',
        metadata: {
          ...metadata,
          componentCount: components.length,
          hasPrerequisites: components.some(c => c.prerequisites?.length > 0),
          hasAssessments: components.some(c => c.type === 'assessment')
        }
      };

      // Validate the built path
      const validation = this.validatePath(pathConfig);
      if (!validation.isValid) {
        throw new Error(`Path validation failed: ${validation.errors.join(', ')}`);
      }

      // Store the path
      this.pathData.set(pathId, pathConfig);
      this.currentPath = pathConfig;

      // Auto-save if enabled
      if (this.config.autoSave) {
        this.savePath(pathConfig);
      }

      this.debugHelper?.log?.('Path built successfully:', pathConfig);
      return pathConfig;
    });
  }

  /**
   * Process and enhance path components
   * @private
   * @param {Array} components - Raw components
   * @returns {Array} Processed components
   */
  processComponents(components) {
    return components.map((component, _index) => ({
      ...component,
      id: component.id || `component-${_index}`,
      order: _index,
      type: component.type || 'lesson',
      duration: component.duration || component.weeks || 1,
      status: component.status || 'not-started',
      prerequisites: component.prerequisites || [],
      learningObjectives: component.learningObjectives || [],
      resources: component.resources || [],
      assessments: component.assessments || []
    }));
  }

  /**
   * Calculate estimated weeks for path completion
   * @private
   * @param {Array} components - Path components
   * @returns {number} Estimated weeks
   */
  calculateEstimatedWeeks(components) {
    return components.reduce((total, component) => {
      return total + (component.weeks || component.duration || 1);
    }, 0);
  }

  /**
   * Validate path configuration
   * @param {Object} pathConfig - Path configuration to validate
   * @returns {Object} Validation result with isValid and errors
   */
  validatePath(pathConfig) {
    const errors = [];

    // Basic structure validation
    if (!pathConfig || typeof pathConfig !== 'object') {
      errors.push('Path configuration must be an object');
      return { isValid: false, errors };
    }

    if (!pathConfig.id || typeof pathConfig.id !== 'string') {
      errors.push('Path must have a valid ID');
    }

    if (!pathConfig.title || typeof pathConfig.title !== 'string') {
      errors.push('Path must have a valid title');
    }

    if (!Array.isArray(pathConfig.components)) {
      errors.push('Path must have components array');
    } else if (pathConfig.components) {
      // Component validation - only if components is a valid array
      if (pathConfig.components.length < this.config.minPathLength) {
        errors.push(`Path must have at least ${this.config.minPathLength} component(s)`);
      }

      if (pathConfig.components.length > this.config.maxPathLength) {
        errors.push(`Path cannot have more than ${this.config.maxPathLength} components`);
      }

      // Validate individual components
      pathConfig.components.forEach((component, _index) => {
        if (!component.id) {
          errors.push(`Component at index ${_index} must have an ID`);
        }
        if (!component.title) {
          errors.push(`Component at index ${_index} must have a title`);
        }
        if (!['lesson', 'project', 'assessment', 'quiz', 'resource'].includes(component.type)) {
          errors.push(`Component at index ${_index} has invalid type: ${component.type}`);
        }
      });

      // Check for duplicate component IDs
      const componentIds = pathConfig.components.map(c => c.id);
      const uniqueIds = new Set(componentIds);
      if (componentIds.length !== uniqueIds.size) {
        errors.push('Components must have unique IDs');
      }
    }

    // Additional strict validation if enabled
    if (this.config.validationStrict) {
      if (!pathConfig.category || !this.config.templateCategories.includes(pathConfig.category)) {
        errors.push('Path must have a valid category');
      }

      if (!pathConfig.difficulty || !['beginner', 'intermediate', 'advanced'].includes(pathConfig.difficulty)) {
        errors.push('Path must have a valid difficulty level');
      }
    }

    return {
      isValid: errors.length === 0,
      errors,
      warnings: this.validatePathWarnings(pathConfig)
    };
  }

  /**
   * Check for path warnings (non-blocking issues)
   * @private
   * @param {Object} pathConfig - Path configuration
   * @returns {Array} Array of warning messages
   */
  validatePathWarnings(pathConfig) {
    const warnings = [];

    // Defensive check for malformed data
    if (!pathConfig || typeof pathConfig !== 'object') {
      return warnings;
    }

    if (pathConfig.estimatedWeeks > 24) {
      warnings.push('Path is quite long (>24 weeks) - consider breaking into smaller paths');
    }

    if (Array.isArray(pathConfig.components) && pathConfig.components.length > 20) {
      warnings.push('Path has many components - consider grouping into modules');
    }

    const hasAssessments = Array.isArray(pathConfig.components) && pathConfig.components.some(c => c.type === 'assessment');
    if (!hasAssessments) {
      warnings.push('Path has no assessments - consider adding progress checkpoints');
    }

    return warnings;
  }

  /**
   * Clone an existing path template
   * @param {string} templateId - Template ID to clone
   * @param {Object} customizations - Custom modifications
   * @returns {Object} Cloned and customized path
   */
  cloneTemplate(templateId, customizations = {}) {
    return this.errorHandler.safeExecute(() => {
      const template = this.pathTemplates.get(templateId);
      if (!template) {
        throw new Error(`Template not found: ${templateId}`);
      }

      const clonedPath = {
        ...JSON.parse(JSON.stringify(template)),
        id: `${template.id}-clone-${Date.now()}`,
        title: customizations.title || `${template.title} (Custom)`,
        ...customizations
      };

      // Apply component customizations
      if (customizations.components) {
        clonedPath.components = this.mergeComponents(clonedPath.components, customizations.components);
      }

      return this.buildPath(clonedPath.components, clonedPath);
    });
  }

  /**
   * Merge template components with customizations
   * @private
   * @param {Array} templateComponents - Original template components
   * @param {Array} customComponents - Custom component modifications
   * @returns {Array} Merged components
   */
  mergeComponents(templateComponents, customComponents) {
    const componentMap = new Map(templateComponents.map(c => [c.id, c]));

    customComponents.forEach(customComponent => {
      if (componentMap.has(customComponent.id)) {
        // Update existing component
        componentMap.set(customComponent.id, {
          ...componentMap.get(customComponent.id),
          ...customComponent
        });
      } else {
        // Add new component
        componentMap.set(customComponent.id, customComponent);
      }
    });

    return Array.from(componentMap.values());
  }

  /**
   * Get all available path templates
   * @param {string} category - Optional category filter
   * @returns {Array} Array of templates
   */
  getTemplates(category = null) {
    const templates = Array.from(this.pathTemplates.values());
    return category ? templates.filter(t => t.category === category) : templates;
  }

  /**
   * Save path to storage
   * @param {Object} pathConfig - Path to save
   * @returns {boolean} Success status
   */
  savePath(pathConfig) {
    return this.errorHandler.safeExecute(() => {
      const savedPaths = this.loadSavedData();
      savedPaths[pathConfig.id] = {
        ...pathConfig,
        lastModified: new Date().toISOString()
      };

      localStorage.setItem(this.config.storageKey, JSON.stringify(savedPaths));
      this.debugHelper?.log?.('Path saved:', pathConfig.id);
      return true;
    }) || false;
  }

  /**
   * Load path from storage
   * @param {string} pathId - Path ID to load
   * @returns {Object|null} Loaded path or null
   */
  loadPath(pathId) {
    return this.errorHandler.safeExecute(() => {
      const savedPaths = this.loadSavedData();
      const path = savedPaths[pathId];

      if (path) {
        this.pathData.set(pathId, path);
        this.currentPath = path;
        this.debugHelper?.log?.('Path loaded:', pathId);
        return path;
      }

      return null;
    });
  }

  /**
   * Load all saved path data
   * @private
   * @returns {Object} Saved paths object
   */
  loadSavedData() {
    try {
      const saved = localStorage.getItem(this.config.storageKey);
      return saved ? JSON.parse(saved) : {};
    } catch (_error) {
      this.debugHelper?.log?.('Error loading saved data:', _error);
      return {};
    }
  }

  /**
   * Delete a saved path
   * @param {string} pathId - Path ID to delete
   * @returns {boolean} Success status
   */
  deletePath(pathId) {
    return this.errorHandler.safeExecute(() => {
      const savedPaths = this.loadSavedData();
      delete savedPaths[pathId];

      localStorage.setItem(this.config.storageKey, JSON.stringify(savedPaths));
      this.pathData.delete(pathId);

      if (this.currentPath?.id === pathId) {
        this.currentPath = null;
      }

      this.debugHelper?.log?.('Path deleted:', pathId);
      return true;
    }) || false;
  }

  /**
   * Get all saved paths
   * @returns {Array} Array of saved paths
   */
  getSavedPaths() {
    const savedPaths = this.loadSavedData();
    return Object.values(savedPaths);
  }

  /**
   * Export path as JSON
   * @param {string} pathId - Path ID to export
   * @returns {string} JSON string
   */
  exportPath(pathId) {
    return this.errorHandler.safeExecute(() => {
      const path = this.pathData.get(pathId) || this.loadPath(pathId);
      if (!path) {
        throw new Error(`Path not found: ${pathId}`);
      }

      return JSON.stringify({
        ...path,
        exportedAt: new Date().toISOString(),
        version: '1.0.0'
      }, null, 2);
    });
  }

  /**
   * Import path from JSON
   * @param {string} jsonString - JSON string to import
   * @returns {Object} Imported path
   */
  importPath(jsonString) {
    return this.errorHandler.safeExecute(() => {
      const pathData = JSON.parse(jsonString);

      // Validate imported data
      const validation = this.validatePath(pathData);
      if (!validation.isValid) {
        throw new Error(`Invalid path data: ${validation.errors.join(', ')}`);
      }

      // Ensure unique ID
      pathData.id = `${pathData.id}-imported-${Date.now()}`;
      pathData.importedAt = new Date().toISOString();

      // Save and set as current
      this.pathData.set(pathData.id, pathData);
      this.currentPath = pathData;

      if (this.config.autoSave) {
        this.savePath(pathData);
      }

      this.debugHelper?.log?.('Path imported:', pathData.id);
      return pathData;
    });
  }

  /**
   * Handle form submission events
   * @private
   * @param {Event} event - Form submit event
   */
  handlePathFormSubmit(event) {
    event.preventDefault();

    const formData = new FormData(event.target);
    const pathData = {
      title: formData.get('title'),
      description: formData.get('description'),
      category: formData.get('category'),
      difficulty: formData.get('difficulty')
    };

    // Collect components from the form
    const components = this.collectComponentsFromForm();

    try {
      const builtPath = this.buildPath(components, pathData);
      this.displayPathBuiltSuccess(builtPath);
    } catch (_error) {
      this.displayPathBuildError(_error);
    }
  }

  /**
   * Collect components from the path builder form
   * @private
   * @returns {Array} Array of components
   */
  collectComponentsFromForm() {
    const componentElements = this.domUtils.querySelectorAll('.path-component');
    return Array.from(componentElements).map((element, _index) => ({
      id: element.dataset.componentId || `component-${_index}`,
      title: element.querySelector('.component-title').value,
      type: element.querySelector('.component-type').value,
      duration: parseInt(element.querySelector('.component-duration').value) || 1,
      description: element.querySelector('.component-description')?.value || ''
    }));
  }

  /**
   * Display success message for path creation
   * @private
   * @param {Object} path - Created path
   */
  displayPathBuiltSuccess(path) {
    const messageContainer = this.domUtils.querySelector('#path-builder-messages');
    if (messageContainer) {
      messageContainer.innerHTML = `
        <div class="success-message">
          <h3>Path Created Successfully!</h3>
          <p><strong>${path.title}</strong> has been created with ${path.components.length} components.</p>
          <p>Estimated completion time: ${path.estimatedWeeks} weeks</p>
        </div>
      `;
    }
  }

  /**
   * Initialize drag and drop functionality
   * @private
   */
  initializeDragAndDrop() {
    // This would implement drag and drop for component reordering
    // Implementation depends on specific UI framework and requirements
    this.debugHelper?.log?.('Drag and drop functionality initialized');
  }

  /**
   * Set up progress tracking for path building
   * @private
   */
  setupProgressTracking() {
    // This would implement progress tracking for the path building process
    // Could integrate with other progress tracking systems
    this.debugHelper?.log?.('Progress tracking setup complete');
  }

  /**
   * Handle various UI events
   * @private
   */
  handleAddComponent(_event) {
    // Add new component to the path builder form
    this.debugHelper?.log?.('Adding component');
  }

  handleTemplateSelection(event) {
    const templateId = event.target.value;
    if (templateId) {
      const template = this.pathTemplates.get(templateId);
      this.populateFormWithTemplate(template);
    }
  }

  handlePathValidation(_event) {
    const components = this.collectComponentsFromForm();
    const pathData = this.collectPathMetadataFromForm();

    const tempPath = { ...pathData, components };
    const validation = this.validatePath(tempPath);

    this.displayValidationResults(validation);
  }

  handleSavePath(_event) {
    if (this.currentPath) {
      this.savePath(this.currentPath);
      this.displaySaveSuccess();
    }
  }

  handleLoadPath(_event) {
    // Implementation for path loading UI
    this.debugHelper?.log?.('Loading path');
  }

  /**
   * Populate form with template data
   * @private
   * @param {Object} template - Template to populate form with
   */
  populateFormWithTemplate(template) {
    // Implementation to populate the form with template data
    this.debugHelper?.log?.('Populating form with template:', template.id);
  }

  /**
   * Collect path metadata from form
   * @private
   * @returns {Object} Path metadata
   */
  collectPathMetadataFromForm() {
    // Implementation to collect metadata from form
    return {};
  }

  /**
   * Display validation results
   * @private
   * @param {Object} validation - Validation results
   */
  displayValidationResults(validation) {
    // Implementation to display validation results in UI
    this.debugHelper?.log?.('Validation results:', validation);
  }

  /**
   * Display save success message
   * @private
   */
  displaySaveSuccess() {
    // Implementation to show save success message
    this.debugHelper?.log?.('Path saved successfully');
  }

  /**
   * Clean up resources and event listeners
   */
  destroy() {
    return this.errorHandler.safeExecute(() => {
      if (this.abortController) {
        this.abortController.abort();
        this.abortController = null;
      }

      this.pathData.clear();
      this.pathTemplates.clear();
      this.pathValidators.clear();
      this.currentPath = null;
      this.isInitialized = false;

      this.debugHelper?.log?.('PathBuilder destroyed');
      return true;
    }) || false;
  }
}

export default PathBuilder;
