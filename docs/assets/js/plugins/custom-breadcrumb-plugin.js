/**
 * Custom Docsify Breadcrumb Plugin
 * Generates accessible breadcrumb navigation based on route path
 *
 * Features:
 * - Route-based breadcrumb generation
 * - Configurable via window.$docsify.breadcrumb
 * - Accessible HTML structure
 * - Clean, simplified implementation
 *
 * Architecture Note:
 * This plugin ONLY updates breadcrumbs via Docsify lifecycle hooks
 * (hook.ready and hook.doneEach) to ensure content is fully loaded
 * before breadcrumbs are displayed. Direct hashchange listeners are
 * intentionally NOT used to prevent race conditions with content loading.  /**
   * Handle page change events
   */
  function _handlePageChange() {
    const win = globalThis.window || window;

    if (typeof win !== 'undefined' && win.location) {
      // Get the current route from hash
      const hash = win.location.hash;
      const path = hash.startsWith('#/') ? hash.substring(1) : (hash.startsWith('#') ? hash.substring(1) : '/');

      const route = { path: path || '/' };

      // Call the exposed updateBreadcrumb method so tests can spy on it
      if (win.CustomBreadcrumbPlugin && typeof win.CustomBreadcrumbPlugin.updateBreadcrumb === 'function') {
        win.CustomBreadcrumbPlugin.updateBreadcrumb(route);
      }
      // Note: Internal updateBreadcrumb function will be called by the plugin lifecycle
    }
  }

/**
 * Custom Breadcrumb Plugin for Docsify
 * @author Edge AI Team
 * @version 2.0.0
 */
(function() {
  'use strict';

  /**
   * Plugin state management
   * @private
   */
  const state = {
    isInitialized: false,
    config: {
      showHome: true,
      homeText: 'Home',
      casing: 'capitalize',
      separator: ' › ',
      linkColor: 'var(--theme-color, #42b983)',
      size: 'small'
    },
    fileExistenceCache: new Map(),
    activeTimers: new Set()
  };

  /**
   * Initialize the breadcrumb plugin with configuration
   * @param {Object} userConfig - User configuration options
   * @param {boolean} reset - If true, reset to defaults before applying config
   */
  function init(userConfig = {}, reset = false) {
    // Define default configuration
    const defaultConfig = {
      showHome: true,
      homeText: 'Home',
      separator: ' › ',
      casing: 'capitalize',
      excludePaths: ['README.md', 'index.md'],
      maxDepth: 6,
      size: 'small'
    };

    // Reset config to defaults if requested, or if this is first initialization
    if (reset || Object.keys(userConfig).length === 0) {
      state.config = { ...defaultConfig };
    }

    // Merge user config with current config (or defaults if reset)
    if (typeof window !== 'undefined' && window.$docsify && window.$docsify.breadcrumb) {
      state.config = { ...state.config, ...window.$docsify.breadcrumb, ...userConfig };
    } else {
      state.config = { ...state.config, ...userConfig };
    }

    state.isInitialized = true;
  }

  /**
   * Check if a file exists at the given path
   * @param {string} path - File path to check
   * @returns {Promise<boolean>} True if file exists
   * @private
   */
  async function _checkFileExists(path) {
    if (state.fileExistenceCache.has(path)) {
      return state.fileExistenceCache.get(path);
    }

    try {
      // In browser environment, we can't directly check file existence
      // This is a placeholder for the actual implementation
      // In a real scenario, this might involve a HEAD request or similar
      const exists = true; // Simplified for this implementation
      state.fileExistenceCache.set(path, exists);
      return exists;
    } catch {
      // Error checking file existence - logging disabled for production
      state.fileExistenceCache.set(path, false);
      return false;
    }
  }

  /**
   * Clean and format display name based on casing preference
   * @param {string} name - Raw name to clean
   * @param {string} casing - Casing style ('uppercase', 'lowercase', 'capitalize', or default title case)
   * @returns {string} Cleaned display name
   */
  function cleanDisplayName(name, casing = 'capitalize') {
    if (!name) {return '';}

    // Handle special cases
    const specialCases = {
      'src': 'Source',
      'docs': 'Documentation',
      'api': 'API',
      'ui': 'UI',
      'css': 'CSS',
      'js': 'JavaScript',
      'html': 'HTML'
    };

    // Check for special cases first (before any cleaning)
    if (specialCases[name.toLowerCase()]) {
      const specialCase = specialCases[name.toLowerCase()];
      switch (casing) {
        case 'uppercase':
          return specialCase.toUpperCase();
        case 'lowercase':
          return specialCase.toLowerCase();
        case 'capitalize':
        default:
          return specialCase;
      }
    }

    // Clean the name: replace hyphens/underscores with spaces
    const cleaned = name.replace(/[-_]/g, ' ');

    // Apply casing
    switch (casing) {
      case 'uppercase':
        return cleaned.toUpperCase();
      case 'lowercase':
        return cleaned.toLowerCase();
      case 'capitalize':
      default:
        // Title case: capitalize first letter of each word
        return cleaned.split(' ')
          .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
          .join(' ');
    }
  } /**
   * Generate breadcrumb HTML for a given route
   * @param {Object} route - Route object with path
   * @returns {string} Breadcrumb HTML
   */
  function generateBreadcrumbHTML(route) {
    if (!route || !route.path || route.path === '') {
      return '';
    }

    const config = state.config;

    const segments = route.path.split('/').filter(segment =>
      segment &&
      segment !== 'index' &&
      segment !== 'readme' &&
      segment.toLowerCase() !== 'readme' &&
      !segment.includes('.html') &&
      !segment.includes('.md')
    );

    // For home route, return simple Home breadcrumb
    if (route.path === '/' || segments.length === 0) {
      return `
      <nav class="breadcrumb-container" aria-label="Breadcrumb">
        <ol class="breadcrumb">
          <li class="breadcrumb-item">
            <span class="active" aria-current="page">Home</span>
          </li>
        </ol>
      </nav>
    `;
    }

    // Build breadcrumb items array starting with Home
    const breadcrumbItems = [
      { text: 'Home', href: '#/', isActive: false }
    ];

    // Add segments as breadcrumb items
    let currentPath = '';
    segments.forEach((segment, _index) => {
      currentPath += `/${segment}`;
      const isLast = _index === segments.length - 1;

      breadcrumbItems.push({
        text: cleanDisplayName(segment, config.casing),
        // Add trailing slash for folder paths so Docsify loads README.md
        href: isLast ? null : `#${currentPath}/`,
        isActive: isLast
      });
    });

    // Generate HTML with semantic structure
    const breadcrumbItemsHTML = breadcrumbItems.map((item, _index) => {
      const isLast = _index === breadcrumbItems.length - 1;

      if (item.isActive || isLast) {
        return `<li class="breadcrumb-item"><span class="active" aria-current="page">${item.text}</span></li>`;
      } else {
        return `<li class="breadcrumb-item"><a href="${item.href}">${item.text}</a></li>`;
      }
    }).join('');

    return `
      <nav class="breadcrumb-container" aria-label="Breadcrumb">
        <ol class="breadcrumb">
          ${breadcrumbItemsHTML}
        </ol>
      </nav>
    `;
  }

  /**
   * Insert breadcrumb HTML into the page
   * @param {string} breadcrumbHTML - Generated breadcrumb HTML
   * @private
   */
  function insertBreadcrumbIntoPage(breadcrumbHTML) {
    if (!breadcrumbHTML || typeof document === 'undefined') {
      return;
    }

    try {
      // Remove any existing breadcrumbs
      const existingBreadcrumbs = document.querySelectorAll('.breadcrumb-container');
      existingBreadcrumbs.forEach(el => el.remove());

      // Find insertion point - prefer frontmatter display area
      let insertionPoint = document.querySelector('.frontmatter-display');

      if (!insertionPoint) {
        // Fallback to content area
        insertionPoint = document.querySelector('.markdown-section');
      }

      if (!insertionPoint) {
        // Final fallback to main content
        insertionPoint = document.querySelector('main .content');
      }

      if (insertionPoint) {
        // Create breadcrumb element
        const breadcrumbElement = document.createElement('div');
        breadcrumbElement.innerHTML = breadcrumbHTML;

        // Insert at the beginning
        insertionPoint.insertBefore(breadcrumbElement.firstElementChild, insertionPoint.firstChild);

      } else {
        // No suitable insertion point found - fail silently
      }
    } catch {
      // Error inserting breadcrumb - logging disabled for production
    }
  }

  /**
   * Update breadcrumb for the current route
   * @param {Object} route - Docsify route object
   */
  async function updateBreadcrumb(route) {
    if (!state.isInitialized) {
      init();
    }

    try {
      const breadcrumbHTML = await generateBreadcrumbHTML(route);
      insertBreadcrumbIntoPage(breadcrumbHTML);
    } catch {
      // Error updating breadcrumb - logging disabled for production
    }
  }

  /**
   * Handle page change events (fallback when no route is available)
   */
  function handlePageChange() {
    try {
      const win = globalThis.window || window;
      if (typeof win !== 'undefined' && win && win.location && win.location.hash !== undefined) {
        // Extract path from hash, removing anchor fragments like ?id=section
        let rawPath = win.location.hash.replace('#', '') || '/';

        // Remove anchor fragments (anything after ? or #)
        const anchorIndex = rawPath.indexOf('?');
        if (anchorIndex !== -1) {
          rawPath = rawPath.substring(0, anchorIndex);
        }
        const hashIndex = rawPath.indexOf('#');
        if (hashIndex !== -1) {
          rawPath = rawPath.substring(0, hashIndex);
        }

        const route = {
          path: rawPath
        };

        // Call the exposed updateBreadcrumb method so tests can spy on it
        if (win.CustomBreadcrumbPlugin && typeof win.CustomBreadcrumbPlugin.updateBreadcrumb === 'function') {
          win.CustomBreadcrumbPlugin.updateBreadcrumb(route);
        } else {
          updateBreadcrumb(route);
        }
      }
    } catch {
      // Silently handle errors during test cleanup or when DOM is not available
      if (process && process.env && process.env.NODE_ENV !== 'test') {
        // Error during page change - logging disabled for production
      }
    }
  }

  /**
   * Cleanup function to remove event listeners and breadcrumb elements
   */
  function cleanup() {
    // Remove all breadcrumb containers
    if (typeof document !== 'undefined') {
      const containers = document.querySelectorAll('.breadcrumb-container');
      containers.forEach(container => {
        if (container && container.parentNode) {
          container.parentNode.removeChild(container);
        }
      });
    }

    // Clear active timers
    state.activeTimers.forEach(timerId => {
      clearTimeout(timerId);
    });
    state.activeTimers.clear();
  } /**
   * Docsify plugin function
   * @param {Object} hook - Docsify hook object
   * @param {Object} vm - Docsify VM object
   */
  function customBreadcrumbPlugin(hook, vm) {
    // If called without arguments or with empty objects, return a hook object (for testing)
    if (!hook || !vm || (typeof hook === 'object' && Object.keys(hook).length === 0)) {
      return {
        init: () => init(),
        doneEach: () => handlePageChange(),
        ready: () => handlePageChange()
      };
    }

    // Initialize on plugin load
    hook.init(() => {
      init();
    });

    // Update breadcrumb when page content is done
    hook.doneEach(() => {
      if (vm && vm.route) {
        // Call the exposed updateBreadcrumb method so tests can spy on it
        if (globalThis.window.CustomBreadcrumbPlugin && typeof globalThis.window.CustomBreadcrumbPlugin.updateBreadcrumb === 'function') {
          globalThis.window.CustomBreadcrumbPlugin.updateBreadcrumb(vm.route);
        } else {
          updateBreadcrumb(vm.route);
        }
      } else {
        // Fallback for when VM route is not available
        handlePageChange();
      }
    });

    // Handle initial page load
    hook.ready(() => {
      if (vm && vm.route) {
        // Call the exposed updateBreadcrumb method so tests can spy on it
        if (globalThis.window.CustomBreadcrumbPlugin && typeof globalThis.window.CustomBreadcrumbPlugin.updateBreadcrumb === 'function') {
          globalThis.window.CustomBreadcrumbPlugin.updateBreadcrumb(vm.route);
        } else {
          updateBreadcrumb(vm.route);
        }
      } else {
        // Fallback for when VM route is not available
        handlePageChange();
      }
    });
  }

  // Browser environment setup
  if (typeof window !== 'undefined' &&
      typeof window.addEventListener === 'function' &&
      typeof window.document !== 'undefined') {
    // Make plugin functions available globally for testing
    window.customBreadcrumbPlugin = customBreadcrumbPlugin;
    window.CustomBreadcrumbPlugin = {
      init,
      updateBreadcrumb,
      handlePageChange,
      cleanup,
      getState: () => ({ ...state })
    };

    // Create instance object for testing
    window.customBreadcrumbPluginInstance = {
      init: (userConfig) => {
        init(userConfig);
        // Update the instance config reference
        window.customBreadcrumbPluginInstance.config = state.config;
      },
      generateBreadcrumbHTML,
      updateBreadcrumb,
      cleanup,
      getConfig: () => ({ ...state.config }),
      handlePageChange,
      get config() { return state.config; },
      set config(newConfig) { state.config = newConfig; }
    };

    // Auto-register plugin with Docsify if available and in production
    if (typeof window.$docsify !== 'undefined' &&
        typeof window.addEventListener === 'function') {
      window.$docsify.plugins = window.$docsify.plugins || [];
      window.$docsify.plugins.push(customBreadcrumbPlugin);
    }
  }

  // For testing environments - expose to globalThis.window as well
  if (typeof globalThis !== 'undefined' &&
      typeof globalThis.window !== 'undefined' &&
      typeof globalThis.window === 'object') {
    // Copy the same exposure to globalThis.window
    globalThis.window.customBreadcrumbPlugin = customBreadcrumbPlugin;
    globalThis.window.CustomBreadcrumbPlugin = {
      init,
      updateBreadcrumb,
      handlePageChange,
      cleanup,
      getState: () => ({ ...state })
    };
    globalThis.window.customBreadcrumbPluginInstance = {
      init: (userConfig) => {
        init(userConfig);
        // Update the instance config reference
        globalThis.window.customBreadcrumbPluginInstance.config = state.config;
      },
      generateBreadcrumbHTML,
      updateBreadcrumb,
      cleanup,
      getConfig: () => ({ ...state.config }),
      handlePageChange,
      get config() { return state.config; },
      set config(newConfig) { state.config = newConfig; }
    };
  }

})();
