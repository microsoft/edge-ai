/**
 * Navigation Coordinator
 * Centralized system for coordinating navbar and sidebar highlighting
 * @module core/navigation-coordinator
 * @version 2.0.0
 * @author Edge AI Team
 */

/**
 * Navigation Coordinator Class
 * Coordinates navigation highlighting between navbar and sidebar systems
 * @class NavigationCoordinator
 */
export class NavigationCoordinator {
  /**
   * Create a NavigationCoordinator instance
   * @param {Object} dependencies - Required dependencies
   * @param {Object} dependencies.errorHandler - Error handler instance
   * @param {Object} dependencies.debugHelper - Debug helper instance
   */
  constructor({ errorHandler, debugHelper } = {}) {
    // Validate dependencies
    this.errorHandler = errorHandler;
    this.debugHelper = debugHelper;

    // State management
    this.isInitialized = false;
    this.currentRoute = null;
    this.currentNavbarSection = null;
    this.highlightingTimeout = null;

    // Configuration for highlighting timing
    this.highlightingConfig = {
      initialDelay: 100, // Delay before initial highlighting
      routeChangeDelay: 50, // Delay after route changes
      docsifyDelay: 75, // Delay after docsify page loads
      debounceDelay: 25 // Debounce delay for rapid changes
    };

    // Bind methods for event listeners
    this.handleRouteChange = this.debounce(this._handleRouteChangeInternal.bind(this), this.highlightingConfig.debounceDelay);
    this.handleDocsifyPageLoad = this.debounce(this._handleDocsifyPageLoadInternal.bind(this), this.highlightingConfig.debounceDelay);
  }

  /**
   * Debounced highlighting function to prevent excessive calls
   * @param {Function} fn - Function to debounce
   * @param {number} delay - Debounce delay in milliseconds
   * @returns {Function} Debounced function
   */
  debounce(fn, delay) {
    return (...args) => {
      clearTimeout(this.highlightingTimeout);
      this.highlightingTimeout = setTimeout(() => fn.apply(this, args), delay);
    };
  }

  /**
   * Get current route from various sources
   * @returns {string} Current route
   */
  getCurrentRoute() {
    return this.safeExecute(() => {
      // Try to get route from docsify VM if available
      if (typeof window !== 'undefined' && window.docsifyVM && window.docsifyVM.route && window.docsifyVM.route.path) {
        return window.docsifyVM.route.path;
      }

      // Fallback to window location hash
      if (typeof window !== 'undefined' && window.location) {
        return window.location.hash.replace('#', '') || '/';
      }

      return '/';
    }, 'getCurrentRoute', '/');
  }

  /**
   * Safe execution wrapper
   * @param {Function} fn - Function to execute
   * @param {string} context - Context for error reporting
   * @param {*} defaultValue - Default value on error
   * @returns {*} Function result or default value
   */
  safeExecute(fn, context, defaultValue) {
    if (this.errorHandler && typeof this.errorHandler.safeExecute === 'function') {
      return this.errorHandler.safeExecute(fn, context, defaultValue);
    }

    try {
      return fn();
    } catch (error) {
      if (this.debugHelper) {
        this.debugHelper.error(`[NavigationCoordinator] Error in ${context}:`, error);
      }
      return defaultValue;
    }
  }

  /**
   * Log debug message
   * @param {string} message - Debug message
   * @param {...*} args - Additional arguments
   */
  log(message, ...args) {
    if (this.debugHelper && typeof this.debugHelper.log === 'function') {
      this.debugHelper?.log?.(`🎯 [COORDINATOR] ${message}`, ...args);
    }
  }

  /**
   * Log warning message
   * @param {string} message - Warning message
   * @param {...*} args - Additional arguments
   */
  warn(message, ...args) {
    if (this.debugHelper && typeof this.debugHelper.warn === 'function') {
      this.debugHelper.warn(`⚠️ [COORDINATOR] ${message}`, ...args);
    }
  }

  /**
   * Coordinate highlighting between navbar and sidebar
   * @param {string} route - Current route to highlight for
   */
  coordinateHighlighting(route) {
    return this.safeExecute(() => {
      if (!this.isInitialized) {
        this.warn('Not initialized, skipping coordination');
        return;
      }

      const normalizedRoute = route || this.getCurrentRoute();
      if (normalizedRoute === this.currentRoute) {
        this.log('Route unchanged, skipping coordination');
        return;
      }

      this.log(`Coordinating highlighting for route: "${normalizedRoute}"`);
      this.currentRoute = normalizedRoute;

      // Step 1: Update navbar highlighting
      this.updateNavbarHighlighting(normalizedRoute);

      // Step 2: Update sidebar highlighting
      this.updateSidebarHighlighting(normalizedRoute);

      // Step 3: Emit coordination event
      this.emitCoordinationEvent(normalizedRoute);
    }, 'coordinateHighlighting');
  }

  /**
   * Update navbar highlighting via the consolidated system
   * @param {string} route - Current route
   */
  updateNavbarHighlighting(route) {
    return this.safeExecute(() => {
      if (typeof window !== 'undefined' && window.NavbarHighlighting && window.NavbarHighlighting.isInitialized()) {
        this.log('Updating navbar highlighting...');
        window.NavbarHighlighting.updateNavbarActiveState(route);

        // Track current navbar section
        this.currentNavbarSection = window.NavbarHighlighting.detectActiveSection(route);
        this.log(`Navbar section: ${this.currentNavbarSection}`);
      } else {
        this.warn('Navbar highlighting system not available');
      }
    }, 'updateNavbarHighlighting');
  }

  /**
   * Update sidebar highlighting via the sidebar system
   * @param {string} _route - Current route (unused but kept for API compatibility)
   */
  updateSidebarHighlighting(_route) {
    return this.safeExecute(() => {
      if (typeof window !== 'undefined' && window.updateSidebarActiveHighlighting) {
        this.log('Updating sidebar highlighting...');
        window.updateSidebarActiveHighlighting();
        this.log('Sidebar highlighting updated');
      } else {
        this.warn('Sidebar highlighting function not available');
      }
    }, 'updateSidebarHighlighting');
  }

  /**
   * Emit coordination event for other systems to listen
   * @param {string} route - Current route
   */
  emitCoordinationEvent(route) {
    return this.safeExecute(() => {
      if (typeof window !== 'undefined') {
        const coordinationEvent = new CustomEvent('navigation:coordinator-highlight', {
          detail: {
            route: route,
            navbarSection: this.currentNavbarSection,
            timestamp: Date.now()
          }
        });

        window.dispatchEvent(coordinationEvent);
        this.log('Emitted coordination event');
      }
    }, 'emitCoordinationEvent');
  }

  /**
   * Internal route change handler
   * @private
   */
  _handleRouteChangeInternal() {
    const route = this.getCurrentRoute();
    this.log(`Route change detected: ${route}`);

    setTimeout(() => {
      this.coordinateHighlighting(route);
    }, this.highlightingConfig.routeChangeDelay);
  }

  /**
   * Internal docsify page load handler
   * @private
   */
  _handleDocsifyPageLoadInternal() {
    const route = this.getCurrentRoute();
    this.log(`Docsify page load detected: ${route}`);

    setTimeout(() => {
      this.coordinateHighlighting(route);
    }, this.highlightingConfig.docsifyDelay);
  }

  /**
   * Setup event listeners for navigation events
   */
  setupEventListeners() {
    return this.safeExecute(() => {
      if (typeof window === 'undefined') {return;}

      // Browser navigation events
      window.addEventListener('hashchange', this.handleRouteChange);
      window.addEventListener('popstate', this.handleRouteChange);

      // Manual coordination trigger
      window.addEventListener('navigation:manual-coordinate', (event) => {
        this.log('Manual coordination requested');
        const route = event.detail?.route || this.getCurrentRoute();
        this.coordinateHighlighting(route);
      });

      this.log('Event listeners configured');
    }, 'setupEventListeners');
  }

  /**
   * Wait for required systems to be available
   * @returns {Promise} Promise that resolves when systems are ready
   */
  waitForSystems() {
    return new Promise((resolve) => {
      const checkSystems = () => {
        if (typeof window === 'undefined') {
          resolve();
          return;
        }

        const navbarReady = window.NavbarHighlighting && window.NavbarHighlighting.isInitialized();
        const sidebarReady = window.updateSidebarActiveHighlighting;

        if (navbarReady && sidebarReady) {
          this.log('All required systems are ready');
          resolve();
        } else {
          this.log('Waiting for systems...', {
            navbar: navbarReady,
            sidebar: sidebarReady
          });
          setTimeout(checkSystems, 50);
        }
      };

      checkSystems();
    });
  }

  /**
   * Initialize the navigation coordinator
   * @returns {Promise<void>}
   */
  async initialize() {
    if (this.isInitialized) {
      this.warn('Already initialized, skipping');
      return;
    }

    this.log('Initializing navigation coordinator...');

    // Wait for all required systems to be ready
    await this.waitForSystems();

    // Setup event listeners
    this.setupEventListeners();

    // Perform initial coordination
    setTimeout(() => {
      this.coordinateHighlighting(this.getCurrentRoute());
    }, this.highlightingConfig.initialDelay);

    this.isInitialized = true;
    this.log('Navigation coordinator initialized');
  }

  /**
   * Get current navbar section
   * @returns {string|null} Current navbar section
   */
  getCurrentNavbarSection() {
    return this.currentNavbarSection;
  }

  /**
   * Check if coordinator is initialized
   * @returns {boolean} Initialization status
   */
  getInitializationStatus() {
    return this.isInitialized;
  }

  /**
   * Trigger manual coordination
   * @param {string} route - Optional route to coordinate for
   */
  triggerManualCoordination(route) {
    return this.safeExecute(() => {
      if (typeof window !== 'undefined') {
        const coordinationEvent = new CustomEvent('navigation:manual-coordinate', {
          detail: { route: route || this.getCurrentRoute() }
        });
        window.dispatchEvent(coordinationEvent);
      }
    }, 'triggerManualCoordination');
  }

  /**
   * Notification that navbar has been highlighted
   * @param {string} section - Highlighted section
   */
  notifyNavbarHighlighted(section) {
    this.log(`Navbar highlighted: ${section}`);
    this.currentNavbarSection = section;
  }

  /**
   * Notification that sidebar has been highlighted
   * @param {string} item - Highlighted item
   */
  notifySidebarHighlighted(item) {
    this.log(`Sidebar highlighted: ${item}`);
  }

  /**
   * Cleanup resources
   */
  destroy() {
    return this.safeExecute(() => {
      if (typeof window !== 'undefined') {
        window.removeEventListener('hashchange', this.handleRouteChange);
        window.removeEventListener('popstate', this.handleRouteChange);
      }

      clearTimeout(this.highlightingTimeout);
      this.isInitialized = false;
      this.log('Navigation coordinator destroyed');
    }, 'destroy');
  }
}

/**
 * Create Docsify plugin function
 * @param {NavigationCoordinator} coordinator - Coordinator instance
 * @returns {Function} Docsify plugin function
 */
export function createDocsifyPlugin(coordinator) {
  return function coordinatorPlugin(hook, vm) {
    // Store docsify VM for route access
    if (typeof window !== 'undefined') {
      window.docsifyVM = vm;
    }

    // Initialize when docsify is ready
    hook.ready(() => {
      coordinator.log('Docsify ready');
      coordinator.initialize();
    });

    // Coordinate highlighting on each page load
    hook.doneEach(() => {
      if (!coordinator.getInitializationStatus()) {return;}

      coordinator.log('Docsify page loaded');
      coordinator._handleDocsifyPageLoadInternal();
    });
  };
}

// IIFE Compatibility Layer for existing integrations
(function() {
  'use strict';

  if (typeof window === 'undefined') {return;}

  // Create global instance with backwards compatibility
  const coordinator = new NavigationCoordinator();

  // Legacy global API
  const navigationCoordinator = {
    // Core coordination functions
    coordinateHighlighting: coordinator.coordinateHighlighting.bind(coordinator),
    updateNavbarHighlighting: coordinator.updateNavbarHighlighting.bind(coordinator),
    updateSidebarHighlighting: coordinator.updateSidebarHighlighting.bind(coordinator),

    // State accessors
    getCurrentRoute: coordinator.getCurrentRoute.bind(coordinator),
    getCurrentNavbarSection: coordinator.getCurrentNavbarSection.bind(coordinator),
    isInitialized: coordinator.getInitializationStatus.bind(coordinator),

    // Manual coordination triggers
    triggerManualCoordination: coordinator.triggerManualCoordination.bind(coordinator),

    // Notification functions for systems
    notifyNavbarHighlighted: coordinator.notifyNavbarHighlighted.bind(coordinator),
    notifySidebarHighlighted: coordinator.notifySidebarHighlighted.bind(coordinator)
  };

  // Register with docsify
  window.$docsify = window.$docsify || {};
  window.$docsify.plugins = window.$docsify.plugins || [];

  // Add to plugins array
  window.$docsify.plugins.push(createDocsifyPlugin(coordinator));

  // Export API globally for backwards compatibility
  window.navigationCoordinator = navigationCoordinator;
})();
