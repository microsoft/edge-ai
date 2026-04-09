/**
 * Interactive Progress Docsify Integration Plugin
 * Registers all interactive progress components with Docsify lifecycle
 * Ensures components are properly initialized and updated on page navigation
 * @version 1.0.0
 */

// Access progress components from global objects
// These are loaded as separate script tags before this integration runs

/**
 * Interactive Progress Docsify Integration
 * Manages the lifecycle of all interactive progress components in Docsify
 */
class InteractiveProgressDocsifyIntegration {
  constructor() {
    this.components = new Map();
    this.isInitialized = false;
    this.debugMode = this._detectDebugMode();
    this.logger = {
      log: (...args) => {
        if (this.debugMode) {
          console.log('[Interactive Progress Integration]', ...args);
        }
      },
      error: (...args) => console.error('[Interactive Progress Integration]', ...args),
      warn: (...args) => console.warn('[Interactive Progress Integration]', ...args)
    };
  }

  /**
   * Detect if debug mode is enabled
   * @private
   */
  _detectDebugMode() {
    try {
      // Check URL parameters
      if (typeof window !== 'undefined' && window.location) {
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.get('debug') === 'true') {
          return true;
        }
      }
      // Check localStorage
      if (typeof localStorage !== 'undefined') {
        if (localStorage.getItem('debugMode') === 'true') {
          return true;
        }
      }
      return false;
    } catch {
      return false;
    }
  }

  /**
   * Initialize the integration system
   */
  initialize() {
    this.logger.log('Initializing interactive progress integration...');

    // Set up Docsify hooks for lifecycle management
    // Note: Components are registered in doneEach() when DOM is ready, not here
    this.setupDocsifyHooks();

    this.isInitialized = true;
    this.logger.log('Interactive progress integration initialized successfully');
  }

  registerComponent(name, component) {
    this.components.set(name, {
      instance: component,
      isActive: false,
      lastUpdate: null
    });

    this.logger.log(`Registered component: ${name}`);
  }

  /**
   * Register default components that should be available on most pages
   */
  registerDefaultComponents() {
    // Check if dashboard already exists and if its containers are still in DOM
    const existingDashboard = this.components.get('LearningPathDashboard');
    if (existingDashboard) {
      const containersStillExist = existingDashboard.instance?.containers?.length > 0 &&
                                   existingDashboard.instance.containers.every(c => document.contains(c));

      if (containersStillExist) {
        this.logger.log('LearningPathDashboard already initialized with valid containers, skipping');
        return;
      } else {
        this.logger.log('LearningPathDashboard exists but containers are gone, recreating...');
        // Destroy old instance and remove from registry
        if (existingDashboard.instance && typeof existingDashboard.instance.destroy === 'function') {
          existingDashboard.instance.destroy();
        }
        this.components.delete('LearningPathDashboard');
      }
    }

    // Auto-insert dashboard container if needed (based on frontmatter)
    if (window.LearningDashboardAutoInsert) {
      try {
        const autoInsert = new window.LearningDashboardAutoInsert();
        autoInsert.initialize();
      } catch (error) {
        this.logger.error('Failed to auto-insert dashboard:', error);
      }
    }

    // Wait for ES6 module to load and expose window.LearningPathDashboard
    const waitForDashboard = (attempts = 0) => {
      if (window.LearningPathDashboard) {
        this.logger.log('LearningPathDashboard module loaded, initializing...');

        const containers = document.querySelectorAll('[data-need-progress]');
        if (containers.length > 0) {
          // Create dashboard instance with server sync enabled
          try {
            const dashboard = new window.LearningPathDashboard(Array.from(containers), {
              enableServerSync: true,
              debug: this.debugMode
            });

            // Load paths from manifest endpoint (no arguments = fetch from backend)
            setTimeout(() => {
              dashboard.loadPaths().then(() => {
                this.logger.log('Dashboard loaded paths from manifest endpoint');
              }).catch(error => {
                this.logger.error('Dashboard manifest loading failed:', error);
                // Announce error to screen readers
                if (dashboard.announceError) {
                  dashboard.announceError('Failed to load learning paths. Please refresh the page.');
                }
              });
            }, 100);

            // Register the actual dashboard instance, not a factory
            this.registerComponent('LearningPathDashboard', dashboard);

          } catch (error) {
            this.logger.error('Failed to create LearningPathDashboard:', error);
          }
        } else {
          this.logger.log('No dashboard containers found, skipping LearningPathDashboard registration');
        }
      } else if (attempts < 50) {
        // ES6 module hasn't loaded yet, wait 100ms and try again (max 5 seconds)
        this.logger.log(`Waiting for LearningPathDashboard module... (attempt ${attempts + 1}/50)`);
        setTimeout(() => waitForDashboard(attempts + 1), 100);
      } else {
        this.logger.error('Timeout waiting for LearningPathDashboard module to load');
      }
    };

    // Start waiting for the module
    waitForDashboard();

    // Register other components as they become available
    if (window.LearningPathCard) {
      this.registerComponent('LearningPathCard', window.LearningPathCard);
    }

    if (window.LearningPathProgress) {
      this.registerComponent('LearningPathProgress', window.LearningPathProgress);
    }

    if (window.SkillAssessment) {
      this.registerComponent('SkillAssessment', window.SkillAssessment);
    }

    // Register interactive learning path checkboxes (always register if available)
    if (window.interactiveLearningPathCheckboxes) {
      this.registerComponent('InteractiveLearningPathCheckboxes', window.interactiveLearningPathCheckboxes);
    }
  }

  /**
   * Set up Docsify lifecycle hooks
   */
  setupDocsifyHooks() {
    // Ensure Docsify plugin system is available
    if (typeof window.$docsify === 'undefined') {
      window.$docsify = {};
    }

    if (!window.$docsify.plugins) {
      window.$docsify.plugins = [];
    }

    // Add our plugin to Docsify
    const self = this; // Preserve context for callbacks
    window.$docsify.plugins.push((hook) => {
      // Hook into page initialization
      hook.init(() => {
        self.logger.log('Docsify init - setting up interactive progress components');
        // Don't register components here - DOM isn't ready yet
      });

      // Hook into DOM ready - register and initialize components when DOM is ready
      hook.doneEach(() => {
        self.logger.log('Docsify doneEach - registering and updating interactive progress components');
        // Register components now that DOM is ready
        self.registerDefaultComponents();
        self.initializeAllComponents();
        self.updateAllComponents();
      });

      // Hook into route changes
      hook.beforeEach((content, next) => {
        self.logger.log('Docsify beforeEach - preparing for page change');
        self.prepareForPageChange();
        next(content);
      });
    });

    this.logger.log('Docsify hooks registered');
  }

  /**
   * Initialize all registered components
   */
  initializeAllComponents() {
    this.logger.log(`Initializing ${this.components.size} components...`);
    this.components.forEach((componentData, name) => {
      try {
      // Skip InteractiveLearningPathCheckboxes if on catalog page (handled by catalog-hydration.js)
      if (name === 'InteractiveLearningPathCheckboxes') {
        const hash = window.location.hash;
        const isCatalogPage = hash === '#/learning/paths/' ||
                              hash === '#/learning/paths/README' ||
                              hash === '#/learning/catalog';
        if (isCatalogPage) {
          this.logger.log(`Skipping ${name} - catalog page handled by catalog-hydration.js`);
          return;
        }
        // Only run on individual learning path content pages
        const isIndividualPathPage = hash.includes('/learning/paths/') &&
                                     hash !== '#/learning/paths/' &&
                                     hash !== '#/learning/paths/README';
        if (!isIndividualPathPage) {
          this.logger.log(`Skipping ${name} - not on an individual learning path page`);
          return;
        }
      }        if (componentData.instance && typeof componentData.instance.initialize === 'function') {
          componentData.instance.initialize();
          componentData.isActive = true;
          componentData.lastUpdate = Date.now();
          this.logger.log(`Successfully initialized component: ${name}`);
        } else if (typeof componentData.instance === 'object' && typeof componentData.instance.renderCards === 'function') {
          // Handle dashboard component which doesn't have initialize but has renderCards
          // Only render if we're on the learning paths page to prevent clearing on navigation
          const isLearningPathsPage = window.location.hash.includes('learning/paths') ||
                                     window.location.hash.includes('learning/README');
          if (isLearningPathsPage && componentData.instance.filteredPaths && componentData.instance.filteredPaths.length > 0) {
            componentData.instance.renderCards();
            this.logger.log(`Successfully activated dashboard component: ${name}`);
          } else {
            this.logger.log(`Skipping dashboard render - not on learning paths page or no paths loaded`);
          }
          componentData.isActive = true;
          componentData.lastUpdate = Date.now();
        } else {
          componentData.isActive = true;
          componentData.lastUpdate = Date.now();
        }
      } catch (error) {
        this.logger.error(`Failed to initialize component ${name}:`, error);
      }
    });
  }

  updateAllComponents() {
    this.components.forEach((componentData, name) => {
      try {
      // Skip InteractiveLearningPathCheckboxes if on catalog page (handled by catalog-hydration.js)
      if (name === 'InteractiveLearningPathCheckboxes') {
        const hash = window.location.hash;
        const isCatalogPage = hash === '#/learning/paths/' ||
                              hash === '#/learning/paths/README' ||
                              hash === '#/learning/catalog';
        if (isCatalogPage) {
          this.logger.log(`Skipping ${name} update - catalog page handled by catalog-hydration.js`);
          return;
        }
        // Only run on individual learning path content pages
        const isIndividualPathPage = hash.includes('/learning/paths/') &&
                                     hash !== '#/learning/paths/' &&
                                     hash !== '#/learning/paths/README';
        if (!isIndividualPathPage) {
          this.logger.log(`Skipping ${name} update - not on an individual learning path page`);
          return;
        }
      }        if (componentData.isActive && componentData.instance) {
          // Call update method if available
          if (typeof componentData.instance.update === 'function') {
            componentData.instance.update();
          }
          // Call reinitialize method if available
          else if (typeof componentData.instance.reinitialize === 'function') {
            componentData.instance.reinitialize();
          }
          // Call initialize method as fallback
          else if (typeof componentData.instance.initialize === 'function') {
            componentData.instance.initialize();
          }

          componentData.lastUpdate = Date.now();
          this.logger.log(`Updated component: ${name}`);
        }
      } catch (error) {
        this.logger.error(`Failed to update component ${name}:`, error);
      }
    });
  }

  prepareForPageChange() {
    this.components.forEach((componentData, name) => {
      try {
        if (componentData.isActive && componentData.instance) {
          // Call cleanup method if available
          if (typeof componentData.instance.cleanup === 'function') {
            componentData.instance.cleanup();
          }
          // Call destroy method if available
          else if (typeof componentData.instance.destroy === 'function') {
            componentData.instance.destroy();
          }

          this.logger.log(`Prepared component for page change: ${name}`);
        }
      } catch (error) {
        this.logger.error(`Failed to prepare component ${name} for page change:`, error);
      }
    });
  }

  /**
   * Get component by name
   * @param {string} name - Component name
   * @returns {Object|null} Component instance or null
   */
  getComponent(name) {
    const componentData = this.components.get(name);
    return componentData ? componentData.instance : null;
  }

  /**
   * Get all active components
   * @returns {Map} Map of active components
   */
  getActiveComponents() {
    const active = new Map();
    this.components.forEach((componentData, name) => {
      if (componentData.isActive) {
        active.set(name, componentData.instance);
      }
    });
    return active;
  }

  /**
   * Enable a component
   * @param {string} name - Component name
   */
  enableComponent(name) {
    const componentData = this.components.get(name);
    if (componentData) {
      componentData.isActive = true;
      this.logger.log(`Enabled component: ${name}`);
    }
  }

  /**
   * Disable a component
   * @param {string} name - Component name
   */
  disableComponent(name) {
    const componentData = this.components.get(name);
    if (componentData) {
      componentData.isActive = false;
      this.logger.log(`Disabled component: ${name}`);
    }
  }

  /**
   * Get integration status
   * @returns {Object} Status information
   */
  getStatus() {
    return {
      isInitialized: this.isInitialized,
      componentCount: this.components.size,
      activeComponents: Array.from(this.components.entries())
        .filter(([, data]) => data.isActive)
        .map(([name]) => name),
      components: Array.from(this.components.keys())
    };
  }

  /**
   * Initialize dashboard instances for containers found on the page
   */
  initializeDashboard() {
    this.logger.log('initializeDashboard method called');

    // Check if LearningPathDashboard is available
    if (!window.LearningPathDashboard) {
      this.logger.error('LearningPathDashboard not found on window object');
      return;
    }

    // Find dashboard containers - use same selector as registerDefaultComponents
    const containers = document.querySelectorAll('[data-need-progress]');
    this.logger.log(`Found ${containers.length} dashboard containers`);

    if (containers.length > 0) {
      try {
        // Destroy existing dashboard if any
        if (this.dashboardInstance) {
          this.dashboardInstance.destroy();
        }

        // Create new dashboard instance
        this.dashboardInstance = new window.LearningPathDashboard(containers);
        this.logger.log(`Initialized dashboard with ${containers.length} containers`);
      } catch (error) {
        this.logger.error('Failed to initialize dashboard:', error);
      }
    } else {
      this.logger.log('No dashboard containers found on this page');
    }
  }  /**
   * Update dashboard for new page content
   */
  updateDashboard() {
    // Re-initialize dashboard to pick up new containers
    this.initializeDashboard();
  }
}

// Create global instance
const interactiveProgressIntegration = new InteractiveProgressDocsifyIntegration();

// Initialize immediately on learning pages
const conditionalInitialize = () => {
  // Check if we're on a learning page
  const isLearningPage = (window.location?.pathname?.includes('/learning/')) ||
                        (window.location?.hash?.includes('#/learning/')) ||
                        document.querySelector('[data-need-progress]');

  if (isLearningPage) {
    // Initialize the integration which will set up Docsify hooks
    interactiveProgressIntegration.initialize();
  }
};

// Initialize immediately if we're already on a learning page
conditionalInitialize();

// Listen for route changes to initialize on learning pages
window.addEventListener('hashchange', conditionalInitialize);

// Global access for debugging and E2E tests
window.interactiveProgressIntegration = interactiveProgressIntegration;
window.InteractiveProgressDocsifyIntegration = InteractiveProgressDocsifyIntegration;

// Also export to globalThis for consistent test access
globalThis.interactiveProgressIntegration = interactiveProgressIntegration;
globalThis.InteractiveProgressDocsifyIntegration = InteractiveProgressDocsifyIntegration;
