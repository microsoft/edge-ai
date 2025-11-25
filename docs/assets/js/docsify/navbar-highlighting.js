/**
 * Consolidated Navbar Highlighting System
 * Manages navbar active states with unified route detection and coordination support
 * Version: 2.0.0
 */

(function() {
  'use strict';

  // Configuration for route to navbar section mapping
  const ROUTE_NAVBAR_CONFIG = {
    'Home': {
      patterns: [
        /^\/$/,
        /^\/README$/,
        /^\/index$/,
        /^$/
      ],
      label: 'Home'
    },
    'Documentation': {
      patterns: [
        /^\/docs\//,
        /^\/docs$/,
        /^\/getting-started\//,
        /^\/accessibility/,
        /^\/roadmap/,
        /^\/tags/
      ],
      label: 'Documentation'
    },
    'Learning': {
      patterns: [
        /^\/learning\//,
        /^\/learning$/,
        /learning\//, // More flexible pattern to catch kata routes
        /\/katas\//, // Explicit kata pattern
        /\.md$.*learning/ // Match any .md file with learning in path
      ],
      label: 'Learning Platform'
    },
    'Blueprints': {
      patterns: [
        /^\/blueprints\//,
        /^\/blueprints$/
      ],
      label: 'Blueprints'
    },
    'Infrastructure': {
      patterns: [
        /^\/src\//,
        /^\/src$/,
        /^\/tests\//,
        /^\/tests$/,
        /^\/scripts\//,
        /^\/scripts$/
      ],
      label: 'Infrastructure'
    },
    'GitHub Copilot': {
      patterns: [
        /^\/copilot\//,
        /^\/copilot$/,
        /^\/\.github\//,
        /^\/\.github$/
      ],
      label: 'GitHub Copilot'
    }
  };

  /**
   * Plugin state management
   * @private
   */
  const state = {
    currentActiveSection: null,
    isInitialized: false,
    routeTimer: null,
    initTimer: null,
    doneEachTimer: null,
    eventListeners: []
  };

  /**
   * Normalize route for consistent processing
   * @param {string} route - Raw route string
   * @returns {string} Normalized route
   */
  function normalizeRoute(route) {
    if (!route || typeof route !== 'string') {return '/';}

    // Remove hash prefix if present
    let normalized = route.startsWith('#') ? route.substring(1) : route;

    // Ensure leading slash
    if (!normalized.startsWith('/')) {
      normalized = `/${ normalized}`;
    }

    // Handle empty or root cases
    if (normalized === '/' || normalized === '') {
      return '/';
    }

    return normalized;
  }

  /**
   * Detect the navbar section from the current route using pattern matching
   * @param {string} route - Current route
   * @returns {string} Section name that should be active
   */
  function detectActiveSection(route) {
    const normalizedRoute = normalizeRoute(route);

    // Special case: if route contains 'learning' anywhere, it's probably a learning page
    if (normalizedRoute.includes('/learning')) {
      return 'Learning';
    }

    // Check each section configuration
    for (const [sectionKey, config] of Object.entries(ROUTE_NAVBAR_CONFIG)) {
      for (const pattern of config.patterns) {
        if (pattern.test(normalizedRoute)) {
          return sectionKey;
        }
      }
    }

    // Default to Home if no match found
    return 'Home';
  }

  /**
   * Remove active class from all navbar items
   */
  function clearAllActiveStates() {
    try {
      const navbar = document.querySelector('.app-nav');
      if (!navbar) {return;}

      const activeElements = navbar.querySelectorAll('.active');
      activeElements.forEach(element => {
        element.classList.remove('active');
      });
    } catch {
      // Silent failure - navbar highlighting will skip this update
    }
  }

  /**
   * Find navbar item by section name
   * @param {string} sectionName - Name of the section to find
   * @returns {Element|null} Found navbar link element
   */
  function findNavbarItemBySection(sectionName) {
    try {
      const navbar = document.querySelector('.app-nav');
      if (!navbar) {
        return null;
      }

      const config = ROUTE_NAVBAR_CONFIG[sectionName];
      if (!config) {
        // Verbose logging disabled for tests
        return null;
      }

      // Find the navbar item that contains the section label
      const allLinks = navbar.querySelectorAll('a');

      for (const link of allLinks) {
        const text = link.textContent?.trim();
        if (!text) {continue;}

        // Clean text for comparison (remove emojis and extra whitespace)
        const cleanText = text.replace(/[^\w\s]/g, '').trim();
        const cleanLabel = config.label.replace(/[^\w\s]/g, '').trim();

        // Check for exact match or partial match for compound names
        if (cleanText === cleanLabel ||
            (cleanText.includes(cleanLabel) && cleanLabel.length > 3) ||
            (sectionName === 'GitHub Copilot' && cleanText.includes('Copilot'))) {
          return link;
        }
      }

      // Verbose logging disabled for tests
      return null;
    } catch {
      return null;
    }
  }

  /**
   * Set active class on the appropriate navbar section
   * @param {string} sectionName - Name of the section to make active
   */
  function setActiveSection(sectionName) {
    if (!sectionName) {
      return;
    }

    try {
      // Check if the visual state matches the logical state
      const expectedNavbarItem = findNavbarItemBySection(sectionName);
      const isVisuallyActive = expectedNavbarItem && expectedNavbarItem.classList.contains('active');

      if (state.currentActiveSection === sectionName && isVisuallyActive) {
        return; // Already active, skip
      }

      // Clear all current active states
      clearAllActiveStates();

      // Find and activate the appropriate navbar item
      const navbarItem = findNavbarItemBySection(sectionName);
      if (navbarItem) {
        // Add active class to the link
        navbarItem.classList.add('active');

        // Also add active class to parent li if it exists
        const parentLi = navbarItem.closest('li');
        if (parentLi) {
          parentLi.classList.add('active');
        }

        state.currentActiveSection = sectionName;

        // Notify coordination system if available
        if (typeof window !== 'undefined' && window.navigationCoordinator) {
          window.navigationCoordinator.notifyNavbarHighlighted(sectionName);
        }
      } else {
        // Verbose logging disabled for tests
      }
    } catch {
      // Silent failure - navbar highlighting will skip this update
    }
  }

  /**
   * Update navbar active state based on current route
   * @param {string} route - Current route
   */
  function updateNavbarActiveState(route) {
    if (!state.isInitialized) {
      return;
    }

    const activeSection = detectActiveSection(route);
    setActiveSection(activeSection);
  }

  /**
   * Handle route changes via event coordination
   */
  function handleRouteChange() {
    const currentRoute = getCurrentRoute();

    // Small delay to ensure docsify has processed the change
    if (state.routeTimer) {
      clearTimeout(state.routeTimer);
    }

    state.routeTimer = setTimeout(() => {
      updateNavbarActiveState(currentRoute);
    }, 50);
  }

  /**
   * Get the current route from multiple sources for reliability
   */
  function getCurrentRoute() {
    // Try to get route from docsify router first
    if (typeof window !== 'undefined' &&
        window.$docsify && window.$docsify.router) {
      const route = window.$docsify.router.getCurrentPath();
      if (route) {
        return route;
      }
    }

    // Fallback to hash
    const hashRoute = (typeof window !== 'undefined' && window.location.hash.replace('#', '')) || '/';
    return hashRoute;
  }

  /**
   * Initialize navbar highlighting system
   */
  function initializeNavbarHighlighting() {
    if (state.isInitialized) {
      return;
    }

    // Set initial active state
    const currentRoute = getCurrentRoute();
    updateNavbarActiveState(currentRoute);

    // Setup event listeners for coordination
    setupEventListeners();

    state.isInitialized = true;
  }

  /**
   * Setup event listeners for navigation coordination
   */
  function setupEventListeners() {
    if (typeof window === 'undefined') {return;}

    // Listen for coordinator events (preferred method)
    const coordinatorHandler = () => handleRouteChange();
    const hashHandler = () => handleRouteChange();
    const popstateHandler = () => handleRouteChange();

    window.addEventListener('navigation:coordinator-highlight', coordinatorHandler);
    window.addEventListener('hashchange', hashHandler);
    window.addEventListener('popstate', popstateHandler);

    // Store event listeners for cleanup
    state.eventListeners.push(
      { element: window, event: 'navigation:coordinator-highlight', handler: coordinatorHandler },
      { element: window, event: 'hashchange', handler: hashHandler },
      { element: window, event: 'popstate', handler: popstateHandler }
    );
  }

  /**
   * Docsify plugin function
   * @param {Object} hook - Docsify hook object
   * @param {Object} vm - Docsify VM object
   */
  function navbarHighlightingPlugin(hook, _vm) {
    // Initialize when docsify is ready
    hook.ready(() => {
      // Small delay to ensure navbar is fully rendered
      if (state.initTimer) {
        clearTimeout(state.initTimer);
      }

      state.initTimer = setTimeout(() => {
        initializeNavbarHighlighting();
      }, 100);
    });

    // Update active state on each route change
    hook.doneEach(() => {
      if (!state.isInitialized) {
        return;
      }

      const currentRoute = getCurrentRoute();

      // Small delay to ensure page has loaded
      if (state.doneEachTimer) {
        clearTimeout(state.doneEachTimer);
      }

      state.doneEachTimer = setTimeout(() => {
        updateNavbarActiveState(currentRoute);
      }, 50);
    });
  }

  /**
   * Cleanup function to remove event listeners and clear timers
   * @private - Currently unused but kept for future cleanup needs
   */
  function _cleanupUnused() {
    // Clear all timers
    if (state.routeTimer) {
      clearTimeout(state.routeTimer);
      state.routeTimer = null;
    }
    if (state.initTimer) {
      clearTimeout(state.initTimer);
      state.initTimer = null;
    }
    if (state.doneEachTimer) {
      clearTimeout(state.doneEachTimer);
      state.doneEachTimer = null;
    }

    // Remove event listeners
    state.eventListeners.forEach(({ element, event, handler }) => {
      if (element && typeof element.removeEventListener === 'function') {
        element.removeEventListener(event, handler);
      }
    });
    state.eventListeners = [];

    // Reset state
    state.isInitialized = false;
    state.currentActiveSection = null;
  }

  // Register plugin with docsify
  if (typeof window !== 'undefined') {
    window.$docsify = window.$docsify || {};
    window.$docsify.plugins = window.$docsify.plugins || [];

    // Add to plugins array
    window.$docsify.plugins.push(navbarHighlightingPlugin);

    // Note: Global API exposure removed for ES6 module compatibility
    // Use ES6 imports instead of window.NavbarHighlighting
  }

})();
