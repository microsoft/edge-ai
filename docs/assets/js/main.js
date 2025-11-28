/**
 * Main Application Entry Point
 * Initializes all ES6 modules and coordinates the application startup
 * Enhanced with E2E test support and performance monitoring
 * @version 1.1.0
 */

// Import all core modules
import { ErrorHandler } from './core/error-handler.js';
import { PerformanceMonitor } from './core/performance-monitor.js';
import { DOMUtils } from './utils/dom-utils.js';
import { docsifyIntegration } from './core/docsify-integration.js';
import { logger } from './utils/index.js';

// Import interactive progress plugins
import './plugins/interactive-progress-docsify-integration.js';

// Global instances
let globalErrorHandler = null;
let performanceMonitor = null;
const loadedModules = new Map();
let isE2EReady = false;

/**
 * Initialize and load all application modules dynamically
 * Loads ES6 modules that are part of the main application flow
 * Enhanced with E2E support and better error handling
 * @async
 * @function loadCompatibilityModules
 * @returns {Promise<void>} Resolves when all modules are loaded
 * @private
 */
async function loadCompatibilityModules() {
  const startTime = performance.now();

  // Core modules (must load first)
  const coreModules = [
    './core/storage-manager.js',
    './utils/kata-detection.js',
    './core/kata-catalog.js',
    './core/learning-path-manager.js',
    './core/kata-completion-handler.js',
    './core/coach-api-bridge.js',
    './core/unified-progress-schema-validator.js',
    './core/progress-core.js'
  ];

  // Feature modules (can load in parallel)
  const featureModules = [
    './features/skill-assessment-form.js',
    './features/self-evaluation-forms.js',
    './features/interactive-checkboxes.js',
    './features/interactive-learning-path-checkboxes.js', // E2E-enhanced component
    './features/progress-annotations.js',
    './features/coach-button.js',
    './features/learning-path-sync.js',
    './features/auto-selection-engine.js',
    './features/simple-progress-bar-extension.js', // Progress bar save/clear extension
    './features/assessment-completion-modal.js' // Modal dialog for assessment completion
  ];

  // UI modules
  const uiModules = [
    './ui/progress-ui.js',
    './features/assessment-path-generator.js',
    './plugins/learning-path-dashboard.js',
    './core/navigation-coordinator.js',
    './core/layout-coordinator.js',
    './features/navbar-dropdown-manager.js',
    './features/sidebar-active-highlighting.js',
    './features/sidebar-chevrons.js',
    './features/toc-chevron-manager.js'
  ];

  // Load core modules sequentially
  for (const url of coreModules) {
    await loadModule(url, 'core');
  }

  // Load feature modules in parallel for better performance
  const featurePromises = featureModules.map(url => loadModule(url, 'feature'));
  await Promise.allSettled(featurePromises);

  // Load UI modules in parallel
  const uiPromises = uiModules.map(url => loadModule(url, 'ui'));
  await Promise.allSettled(uiPromises);

  // Expose assessment path generator globally for modal dialog
  try {
    const assessmentPathGeneratorModule = await import('./features/assessment-path-generator.js');
    const generator = new assessmentPathGeneratorModule.AssessmentPathGenerator();
    await generator.initialize();
    window.assessmentPathGenerator = generator;
    logger.info('Assessment path generator loaded and exposed globally');
  } catch (error) {
    logger.error('Failed to load assessment path generator:', error);
  }

  const loadTime = performance.now() - startTime;
  if (performanceMonitor) {
    performanceMonitor.recordMetric('moduleLoadTime', loadTime);
  }

  // Log performance metrics (only in debug mode)
  logger.info(`Loaded ${loadedModules.size} modules in ${loadTime.toFixed(2)}ms`);
}

/**
 * Load a single module with enhanced error handling and tracking
 * @param {string} url - Module URL to load
 * @param {string} category - Module category for organization
 * @returns {Promise<boolean>} Success status
 */
async function loadModule(url, category = 'unknown') {
  try {
    const startTime = performance.now();
    const module = await import(url);
    const loadTime = performance.now() - startTime;

    loadedModules.set(url, {
      module,
      category,
      loadTime,
      loaded: true,
      error: null
    });

    return true;
  } catch (error) {
    // Track failed modules
    loadedModules.set(url, {
      module: null,
      category,
      loadTime: 0,
      loaded: false,
      error: error.message
    });

    // Use global error handler if available, otherwise fallback to console
    if (globalErrorHandler) {
      globalErrorHandler.logError(error, `Could not load module ${url}`);
    } else {
      logger.error(`Could not load module ${url}:`, error);
    }

    return false;
  }
}

/**
 * Set up E2E test interfaces and global access points
 */
function setupE2EInterface() {
  // Global E2E test interface
  window.e2eTestInterface = {
    // Application state
    isReady: () => isE2EReady,
    getLoadedModules: () => Array.from(loadedModules.keys()),
    getModuleInfo: (url) => loadedModules.get(url),

    // Performance metrics
    getPerformanceMetrics: () => performanceMonitor?.getMetrics() || {},
    getLoadTime: () => {
      const modules = Array.from(loadedModules.values());
      return modules.reduce((total, mod) => total + mod.loadTime, 0);
    },

    // Component access (enhanced for E2E testing)
    getComponent: (name) => window[name],
    getAllComponents: () => ({
      interactiveCheckboxes: window.interactiveCheckboxes,
      progressAnnotations: window.progressAnnotations,
      coachButton: window.coachButton,
      learningPathSync: window.learningPathSync,
      autoSelectionEngine: window.autoSelectionEngine,
      assessmentPathGenerator: window.assessmentPathGenerator,
      AssessmentCompletionModal: window.AssessmentCompletionModal
    }),

    // State management for E2E tests
    getAllKataStates: () => {
      if (window.interactiveCheckboxes?.getAllKataStates) {
        return window.interactiveCheckboxes.getAllKataStates();
      }
      return {};
    },

    setAllKataStates: (states) => {
      if (window.interactiveCheckboxes?.setAllKataStates) {
        return window.interactiveCheckboxes.setAllKataStates(states);
      }
      return false;
    },

    // Component validation
    validateAllComponents: () => {
      const results = {};
      const components = ['interactiveCheckboxes', 'progressAnnotations', 'coachButton', 'learningPathSync', 'autoSelectionEngine'];

      components.forEach(name => {
        const component = window[name];
        if (component && component.validateComponentState) {
          results[name] = component.validateComponentState();
        } else {
          results[name] = {
            isValid: !!component,
            issues: component ? [] : ['Component not found']
          };
        }
      });

      return results;
    },

    // Error handling
    getErrors: () => globalErrorHandler?.getErrors() || [],
    clearErrors: () => globalErrorHandler?.clearErrors(),

    // Performance monitoring
    measureInteractionTime: async (action) => {
      const start = performance.now();
      await action();
      return performance.now() - start;
    },

    // Module management
    reloadModule: async (url) => {
      loadedModules.delete(url);
      return await loadModule(url, 'reload');
    }
  };

  // Global accessibility for debugging and E2E tests (only in debug mode)
  window.mainApp = {
    globalErrorHandler,
    performanceMonitor,
    loadedModules,
    isE2EReady
  };

  // Only enable E2E interface in debug mode
  if (logger.enabled) {
    isE2EReady = true;
    logger.log('E2E test interface ready');
  }
}

/**
 * Global application initialization handler
 * Sets up error handling, DOM utilities, and loads all modules
 * Enhanced with E2E support and better error recovery
 * @event DOMContentLoaded
 * @listens window#DOMContentLoaded
 */
window.addEventListener('DOMContentLoaded', async () => {
  const initStartTime = performance.now();

  try {
    // Initialize error handling first
    globalErrorHandler = new ErrorHandler('main');
    globalErrorHandler.init();

    // Initialize performance monitoring
    performanceMonitor = new PerformanceMonitor();
    performanceMonitor.init();

    // Initialize DOM utilities
    const _domUtils = new DOMUtils(globalErrorHandler);

    // Initialize Docsify integration
    await docsifyIntegration.initialize();

    // Set up global error handlers for E2E test reliability
    window.addEventListener('error', (event) => {
      globalErrorHandler.logError(event.error, 'Global window error');
    });

    window.addEventListener('unhandledrejection', (event) => {
      globalErrorHandler.logError(event.reason, 'Unhandled promise rejection');
    });

    // Load all modules
    await loadCompatibilityModules();

    // Register other components that may need Docsify lifecycle management
    if (window.progressAnnotations) {
      docsifyIntegration.registerComponent('progress-annotations', {
        initialize: () => window.progressAnnotations.reinitialize?.() || window.progressAnnotations.initialize?.(),
        name: 'Progress Annotations'
      });
    }

    if (window.coachButton) {
      docsifyIntegration.registerComponent('coach-button', {
        initialize: () => window.coachButton.reinitialize?.() || window.coachButton.initialize?.(),
        name: 'Coach Button'
      });
    }

    // Set up E2E test interface
    setupE2EInterface();

    // Calculate total initialization time
    const totalInitTime = performance.now() - initStartTime;
    if (performanceMonitor) {
      performanceMonitor.recordMetric('totalInitTime', totalInitTime);
    }

    // Emit global ready events for E2E tests
    const readyEvent = new CustomEvent('app:ready', {
      detail: {
        timestamp: Date.now(),
        initTime: totalInitTime,
        moduleCount: loadedModules.size,
        e2eReady: isE2EReady,
        loadedModules: Array.from(loadedModules.keys())
      }
    });
    window.dispatchEvent(readyEvent);

    // Legacy compatibility event
    const legacyEvent = new CustomEvent('learning-path-checkboxes:ready');
    window.dispatchEvent(legacyEvent);

    // Log successful initialization (only in debug mode)
    logger.info(`Application initialized successfully in ${totalInitTime.toFixed(2)}ms`);

  } catch (error) {
    // Use global error handler if available, otherwise fallback to console
    if (globalErrorHandler) {
      globalErrorHandler.logError(error, 'Application initialization failed');
    } else {
      logger.error('Application initialization failed:', error);
    }

    // Still set up E2E interface even if initialization partially failed
    setupE2EInterface();

    // Emit error event for E2E tests to handle gracefully
    const errorEvent = new CustomEvent('app:init-error', {
      detail: {
        error: error.message,
        timestamp: Date.now()
      }
    });
    window.dispatchEvent(errorEvent);
  }
});

// Export for ES6 module compatibility
export {
  loadCompatibilityModules,
  loadModule,
  setupE2EInterface
};
