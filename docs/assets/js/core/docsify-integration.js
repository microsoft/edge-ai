/**
 * Docsify Integration Core
 *
 * Provides seamless integration between interactive learning path components
 * and Docsify's router, content loading, and lifecycle events.
 *
 * Ensures progressive enhancement without modifying markdown content.
 *
 * @version 1.0.0
 * @author Interactive Learning Path System
 */

import { ErrorHandler } from './error-handler.js';

export class DocsifyIntegration {
  constructor() {
    this.errorHandler = new ErrorHandler('DocsifyIntegration');
    this.components = new Map();
    this.isInitialized = false;
    this.currentRoute = null;
    this.contentObserver = null;
    this.routeChangeHandlers = new Set();

    // Docsify lifecycle hooks
    this.hooks = {
      beforeEach: new Set(),
      afterEach: new Set(),
      doneEach: new Set(),
      mounted: new Set()
    };
  }

  /**
   * Initialize Docsify integration
   * Sets up hooks, event listeners, and component coordination
   */
  async initialize() {
    return this.errorHandler.safeExecute(async () => {
      if (this.isInitialized) {
        return false;
      }

      // console.log('Initializing Docsify integration...');

      // Wait for Docsify to be available
      await this.waitForDocsify();

      // Set up Docsify lifecycle hooks
      this.setupDocsifyHooks();

      // Set up route change detection
      this.setupRouteChangeDetection();

      // Set up content change observation
      this.setupContentObserver();

      // Register with global window for E2E testing
      this.registerGlobalInterface();

      this.isInitialized = true;
      // console.log('Docsify integration initialized successfully');

      // Emit integration ready event
      this.emitEvent('docsify-integration:ready', {
        timestamp: Date.now(),
        components: Array.from(this.components.keys())
      });

      return true;
    }, 'DocsifyIntegration.initialize', false);
  }

  /**
   * Wait for Docsify to be available
   * Handles timing issues with Docsify loading
   */
  async waitForDocsify(timeout = 10000) {
    return new Promise((resolve) => {
      const startTime = Date.now();

      const checkDocsify = () => {
        const elapsed = Date.now() - startTime;

        if (window.$docsify || window.Docsify) {
          // console.log('Docsify detected, proceeding with integration');
          resolve(true);
          return;
        }

        if (elapsed >= timeout) {
          resolve(false);
          return;
        }

        setTimeout(checkDocsify, 100);
      };

      checkDocsify();
    });
  }

  /**
   * Set up Docsify lifecycle hooks
   * Integrates with Docsify's plugin system
   */
  setupDocsifyHooks() {
    return this.errorHandler.safeExecute(() => {
      // Register as Docsify plugin if Docsify is available
      if (window.$docsify) {
        window.$docsify.plugins = window.$docsify.plugins || [];

        const integrationPlugin = (hook, vm) => {
          // Before each route change
          hook.beforeEach((html, next) => {
            this.handleBeforeEach(html, vm).then(next);
          });

          // After each route change (HTML processed)
          hook.afterEach((html, next) => {
            this.handleAfterEach(html, vm).then(next);
          });

          // After each route is completely rendered
          hook.doneEach(() => {
            this.handleDoneEach(vm);
          });

          // After initial mount
          hook.mounted(() => {
            this.handleMounted(vm);
          });
        };

        window.$docsify.plugins.push(integrationPlugin);
        // console.log('Registered Docsify integration plugin');
      } else {
        // console.log('Docsify not available, setting up fallback integration');
        this.setupFallbackIntegration();
      }
    }, 'DocsifyIntegration.setupDocsifyHooks');
  }

  /**
   * Set up route change detection
   * Monitors URL changes and triggers component updates
   */
  setupRouteChangeDetection() {
    return this.errorHandler.safeExecute(() => {
      // Monitor hash changes for Docsify routing
      const handleHashChange = () => {
        const newRoute = this.getCurrentRoute();
        if (newRoute !== this.currentRoute) {
          const oldRoute = this.currentRoute;
          this.currentRoute = newRoute;
          this.handleRouteChange(oldRoute, newRoute);
        }
      };

      window.addEventListener('hashchange', handleHashChange);

      // Also monitor popstate for browser navigation
      window.addEventListener('popstate', handleHashChange);

      // Initial route detection
      this.currentRoute = this.getCurrentRoute();

      // console.log('Route change detection initialized');
    }, 'DocsifyIntegration.setupRouteChangeDetection');
  }

  /**
   * Set up content change observer
   * Monitors DOM changes for dynamic content updates
   */
  setupContentObserver() {
    return this.errorHandler.safeExecute(() => {
      if (!window.MutationObserver) {
        return;
      }

      this.contentObserver = new MutationObserver((mutations) => {
        let shouldReinitialize = false;

        mutations.forEach((mutation) => {
          // Check for added nodes that might contain checkboxes
          if (mutation.type === 'childList') {
            mutation.addedNodes.forEach((node) => {
              if (node.nodeType === 1 && node.querySelector) {
                const hasCheckboxes = node.querySelector('input[type="checkbox"]');
                const hasLearningPaths = node.querySelector('[data-kata-id]');

                if (hasCheckboxes || hasLearningPaths) {
                  shouldReinitialize = true;
                }
              }
            });
          }
        });

        if (shouldReinitialize) {
          // Debounce reinitialization
          clearTimeout(this.reinitTimeout);
          this.reinitTimeout = setTimeout(() => {
            this.reinitializeComponents();
          }, 250);
        }
      });

      // Observe the main content area
      const appElement = document.getElementById('app') || document.body;
      this.contentObserver.observe(appElement, {
        childList: true,
        subtree: true
      });

      // console.log('Content change observer initialized');
    }, 'DocsifyIntegration.setupContentObserver');
  }

  /**
   * Register component with the integration system
   */
  registerComponent(name, component) {
    return this.errorHandler.safeExecute(() => {
      if (!name || !component) {
        throw new Error('Component name and instance are required');
      }

      this.components.set(name, component);
      // console.log(`Registered component: ${name}`);

      // Emit component registered event
      this.emitEvent('docsify-integration:component-registered', {
        component: name,
        timestamp: Date.now()
      });

      return true;
    }, 'DocsifyIntegration.registerComponent', false);
  }

  /**
   * Unregister component from the integration system
   */
  unregisterComponent(name) {
    return this.errorHandler.safeExecute(() => {
      const component = this.components.get(name);
      if (component) {
        // Call destroy if it exists
        if (typeof component.destroy === 'function') {
          component.destroy();
        }

        const removed = this.components.delete(name);
        if (removed) {
          // console.log(`Unregistered component: ${name}`);

          this.emitEvent('docsify-integration:component-unregistered', {
            component: name,
            timestamp: Date.now()
          });
        }
        return removed;
      }
      return false;
    }, 'DocsifyIntegration.unregisterComponent', false);
  }

  /**
   * Handle Docsify beforeEach hook
   */
  async handleBeforeEach(html, vm) {
    return this.errorHandler.safeExecute(async () => {
      // console.log('Docsify beforeEach triggered');

      // Notify registered handlers
      for (const handler of this.hooks.beforeEach) {
        try {
          await handler(html, vm);
        } catch (_error) {
          // Error in beforeEach handler
        }
      }

      this.emitEvent('docsify-integration:before-each', { html, vm });
      return html;
    }, 'DocsifyIntegration.handleBeforeEach', html);
  }

  /**
   * Handle Docsify afterEach hook
   */
  async handleAfterEach(html, vm) {
    return this.errorHandler.safeExecute(async () => {
      // console.log('Docsify afterEach triggered');

      // Notify registered handlers
      for (const handler of this.hooks.afterEach) {
        try {
          await handler(html, vm);
        } catch (_error) {
          // Error in afterEach handler
        }
      }

      this.emitEvent('docsify-integration:after-each', { html, vm });
      return html;
    }, 'DocsifyIntegration.handleAfterEach', html);
  }

  /**
   * Handle Docsify doneEach hook
   */
  handleDoneEach(vm) {
    return this.errorHandler.safeExecute(() => {
      // console.log('Docsify doneEach triggered');

      // Reinitialize components after content is rendered
      setTimeout(() => {
        this.reinitializeComponents();
      }, 100);

      // Notify registered handlers
      for (const handler of this.hooks.doneEach) {
        try {
          handler(vm);
        } catch (_error) {
          // Error in doneEach handler
        }
      }

      this.emitEvent('docsify-integration:done-each', { vm });
    }, 'DocsifyIntegration.handleDoneEach');
  }

  /**
   * Handle Docsify mounted hook
   */
  handleMounted(vm) {
    return this.errorHandler.safeExecute(() => {
      // console.log('Docsify mounted triggered');

      // Initialize components after initial mount
      setTimeout(() => {
        this.reinitializeComponents();
      }, 100);

      // Notify registered handlers
      for (const handler of this.hooks.mounted) {
        try {
          handler(vm);
        } catch (_error) {
          // Error in mounted handler
          console.warn('Error in mounted handler:', _error);
        }
      }

      this.emitEvent('docsify-integration:mounted', { vm });
    }, 'DocsifyIntegration.handleMounted');
  }

  /**
   * Handle route changes
   */
  handleRouteChange(oldRoute, newRoute) {
    return this.errorHandler.safeExecute(() => {
      // console.log(`Route changed: ${oldRoute} → ${newRoute}`);

      // Check if we're on a learning paths page
      const isLearningPathsPage = this.isLearningPathsPage(newRoute);

      // Notify route change handlers
      for (const handler of this.routeChangeHandlers) {
        try {
          handler(oldRoute, newRoute, isLearningPathsPage);
        } catch (_error) {
          // Error in route change handler
          console.warn('Error in route change handler:', _error);
        }
      }

      this.emitEvent('docsify-integration:route-changed', {
        oldRoute,
        newRoute,
        isLearningPathsPage,
        timestamp: Date.now()
      });

      // Reinitialize components for new page content
      if (isLearningPathsPage) {
        setTimeout(() => {
          this.reinitializeComponents();
        }, 200);
      }
    }, 'DocsifyIntegration.handleRouteChange');
  }

  /**
   * Reinitialize all registered components
   */
  reinitializeComponents() {
    return this.errorHandler.safeExecute(() => {
      // console.log('Reinitializing components for new content');

      for (const [_name, component] of this.components) {
        try {
          if (component && typeof component.initialize === 'function') {
            component.initialize();
            // console.log(`Reinitialized component: ${name}`);
          }
        } catch (_error) {
          // Error reinitializing component
          console.warn('Error reinitializing component:', _error);
        }
      }

      this.emitEvent('docsify-integration:components-reinitialized', {
        componentCount: this.components.size,
        timestamp: Date.now()
      });
    }, 'DocsifyIntegration.reinitializeComponents');
  }

  /**
   * Set up fallback integration when Docsify is not available
   */
  setupFallbackIntegration() {
    return this.errorHandler.safeExecute(() => {
      // console.log('Setting up fallback integration');

      // Set up basic event listeners for standalone operation
      document.addEventListener('DOMContentLoaded', () => {
        setTimeout(() => {
          this.reinitializeComponents();
        }, 100);
      });

      // Monitor for dynamic content changes
      if (this.contentObserver) {
        this.contentObserver.observe(document.body, {
          childList: true,
          subtree: true
        });
      }
    }, 'DocsifyIntegration.setupFallbackIntegration');
  }

  /**
   * Get current route
   */
  getCurrentRoute() {
    const hash = window.location.hash;
    return hash ? hash.replace('#', '') : '/';
  }

  /**
   * Check if current route is a learning paths page
   */
  isLearningPathsPage(route = null) {
    const currentRoute = route || this.getCurrentRoute();
    return currentRoute.startsWith('/learning/') ||
           currentRoute.includes('learning-paths');
  }

  /**
   * Add hook handler
   */
  addHook(hookName, handler) {
    if (this.hooks[hookName]) {
      this.hooks[hookName].add(handler);
      return true;
    }
    return false;
  }

  /**
   * Remove hook handler
   */
  removeHook(hookName, handler) {
    if (this.hooks[hookName]) {
      return this.hooks[hookName].delete(handler);
    }
    return false;
  }

  /**
   * Add route change handler
   */
  addRouteChangeHandler(handler) {
    this.routeChangeHandlers.add(handler);
  }

  /**
   * Remove route change handler
   */
  removeRouteChangeHandler(handler) {
    return this.routeChangeHandlers.delete(handler);
  }

  /**
   * Emit custom event
   */
  emitEvent(eventName, detail = {}) {
    if (typeof document !== 'undefined' && document.dispatchEvent) {
      const event = new CustomEvent(eventName, { detail });
      document.dispatchEvent(event);
    }
  }

  /**
   * Register global interface for E2E testing
   */
  registerGlobalInterface() {
    if (typeof window !== 'undefined') {
      // Create or extend DocumentationSystem global interface
      window.DocumentationSystem = window.DocumentationSystem || {};
      window.DocumentationSystem.docsifyIntegration = this;

      // Legacy interface for backward compatibility
      window.docsifyIntegration = this;

      // Enhanced E2E interface
      window.e2eTestInterface = window.e2eTestInterface || {};
      window.e2eTestInterface.docsifyIntegration = {
        isInitialized: () => this.isInitialized,
        getCurrentRoute: () => this.getCurrentRoute(),
        isLearningPathsPage: () => this.isLearningPathsPage(),
        getRegisteredComponents: () => Array.from(this.components.keys()),
        reinitializeComponents: () => this.reinitializeComponents(),
        emitEvent: (name, detail) => this.emitEvent(name, detail)
      };
    }
  }

  /**
   * Get component by name
   */
  getComponent(name) {
    return this.components.get(name);
  }

  /**
   * Get all registered components
   */
  getAllComponents() {
    return new Map(this.components);
  }

  /**
   * Clean up integration
   */
  destroy() {
    return this.errorHandler.safeExecute(() => {
      // console.log('Destroying Docsify integration');

      // Clear all handlers
      this.hooks.beforeEach.clear();
      this.hooks.afterEach.clear();
      this.hooks.doneEach.clear();
      this.hooks.mounted.clear();
      this.routeChangeHandlers.clear();

      // Disconnect content observer
      if (this.contentObserver) {
        this.contentObserver.disconnect();
        this.contentObserver = null;
      }

      // Clear timeouts
      if (this.reinitTimeout) {
        clearTimeout(this.reinitTimeout);
      }

      // Destroy all registered components
      for (const [_componentName, component] of this.components) {
        if (typeof component.destroy === 'function') {
          try {
            component.destroy();
          } catch (_error) {
            // Error destroying component
            console.warn('Error destroying component:', _error);
          }
        }
      }

      // Clear components
      this.components.clear();

      // Remove global interface
      if (typeof window !== 'undefined') {
        delete window.docsifyIntegration;
        if (window.e2eTestInterface) {
          delete window.e2eTestInterface.docsifyIntegration;
        }
      }

      this.isInitialized = false;
      // console.log('Docsify integration destroyed');
    }, 'DocsifyIntegration.destroy');
  }
}

// Create and export global instance
export const docsifyIntegration = new DocsifyIntegration();

// Note: Initialization is handled by main.js to prevent double initialization
// No auto-initialization event listener here to avoid conflicts
