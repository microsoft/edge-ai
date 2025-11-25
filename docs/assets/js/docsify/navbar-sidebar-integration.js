/**
 * Navbar Sidebar Integration Plugin
 * Dynamically loads section-specific sidebars based on navbar navigation
 * Version: 1.0.0
 */

(function() {
  'use strict';

  // Configuration for navbar to sidebar mapping
  const NAVBAR_SIDEBAR_MAP = {
    'Home': 'docs/_parts/home-sidebar.md',
    'Documentation': 'docs/_parts/docs-sidebar.md',
    'Learning': 'docs/_parts/learning-sidebar.md',
    'Blueprints': 'docs/_parts/blueprints-sidebar.md',
    'Infrastructure': 'docs/_parts/infrastructure-sidebar.md',
    'GitHub Copilot': 'docs/_parts/copilot-sidebar.md'
  };

  // Track current section and sidebar cache
  let currentSection = null;
  const sidebarCache = new Map();
  let isInitialized = false;

  /**
   * Load sidebar content from URL
   * @param {string} sidebarUrl - URL to sidebar markdown file
   * @returns {Promise<string>} Sidebar content
   */
  async function loadSidebarContent(sidebarUrl) {
    try {
      // Check cache first
      if (sidebarCache.has(sidebarUrl)) {
        return sidebarCache.get(sidebarUrl);
      }

      const response = await fetch(sidebarUrl);
      if (!response.ok) {
        throw new Error(`Failed to load sidebar: ${response.status}`);
      }

      const content = await response.text();
      // Cache the content
      sidebarCache.set(sidebarUrl, content);
      return content;
    } catch {
      return null;
    }
  }

  /**
   * Filter out TOC content from sidebar HTML
   * @param {string} htmlContent - HTML content that may contain TOC elements
   * @returns {string} Filtered HTML content without TOC elements
   */
  function filterTOCContent(htmlContent) {
    if (!htmlContent || typeof htmlContent !== 'string') {
      return htmlContent;
    }

    try {
      // Create a temporary DOM element to parse and filter the content
      const tempDiv = document.createElement('div');
      tempDiv.innerHTML = htmlContent;

      // Remove TOC-related elements that shouldn't appear in left sidebar
      const tocSelectors = [
        '.toc-container',
        '.toc-nav',
        '.page_toc',
        '[class*="toc"]',
        '.dark-mode-toggle' // Also remove dark mode toggle if it appears
      ];

      tocSelectors.forEach(selector => {
        const elements = tempDiv.querySelectorAll(selector);
        elements.forEach(element => {
          // Only remove if it's actually a TOC element, not navigation
          if (element.textContent &&
              (element.textContent.toLowerCase().includes('table of contents') ||
               element.classList.contains('toc-nav') ||
               element.classList.contains('page_toc') ||
               element.classList.contains('toc-container'))) {
            element.remove();
          }
        });
      });

      return tempDiv.innerHTML;
    } catch {
      return htmlContent;
    }
  }

  /**
   * Update the sidebar with new content
   * @param {string} content - Markdown content for sidebar
   */
  function updateSidebar(content) {
    if (!content || typeof content !== 'string') {
      return;
    }

    try {
      // Find the sidebar element
      const sidebarElement = document.querySelector('.sidebar-nav');
      if (!sidebarElement) {
        return;
      }

      // Parse markdown content and update sidebar
      const parser = window.marked || (window.Docsify && window.Docsify.marked);
      if (parser && typeof parser === 'function') {
        try {
          const parsedContent = parser(content);
          if (parsedContent && typeof parsedContent === 'string') {
            // Filter out TOC content before injecting into left sidebar
            const filteredContent = filterTOCContent(parsedContent);
            sidebarElement.innerHTML = filteredContent;
          } else {
            // Fallback if parser returns invalid content
            const filteredContent = filterTOCContent(content);
            sidebarElement.innerHTML = filteredContent;
          }
        } catch {
          const filteredContent = filterTOCContent(content);
          sidebarElement.innerHTML = filteredContent;
        }
      } else {
        // Fallback: inject content directly with filtering
        const filteredContent = filterTOCContent(content);
        sidebarElement.innerHTML = filteredContent;
      }

      // Trigger docsify to re-process the sidebar safely
      try {
        if (window.Docsify && window.Docsify.dom && typeof window.Docsify.dom.getAndActive === 'function') {
          window.Docsify.dom.getAndActive(window.Docsify.router, '.sidebar-nav');
        }
      } catch {
        // Fallback if Docsify DOM method fails
      }

      // Wait for DOM updates, then emit event for other plugins
      setTimeout(() => {
        try {
          // Emit custom event for other plugins (like sidebar collapse)
          const sidebarReloadedEvent = new CustomEvent('sidebarReloaded', {
            detail: { content: content }
          });
          document.dispatchEvent(sidebarReloadedEvent);

        } catch {
          // Error emitting sidebarReloaded event
        }
      }, 50);

    } catch {
      // Error updating sidebar
    }
  }

  /**
   * Handle navbar section change
   * @param {string} sectionName - Name of the navbar section
   */
  async function handleSectionChange(sectionName) {
    if (!sectionName || typeof sectionName !== 'string') {
      return;
    }

    if (currentSection === sectionName) {return;}

    currentSection = sectionName;

    try {
      // Clean up any kata progress tracking when switching sections
      if (window.kataProgressComponents && typeof window.cleanupKataTracking === 'function') {
        window.cleanupKataTracking();
      } else {
        // Fallback cleanup if the main cleanup function isn't available
        const progressElements = document.querySelectorAll('.kata-progress-bar-container, .progress-bar-container, .kata-progress-bar, .kata-evaluation-form');
        progressElements.forEach(el => {
          if (el && el.parentNode) {
            el.remove();
          }
        });
      }

      const sidebarUrl = NAVBAR_SIDEBAR_MAP[sectionName];
      if (!sidebarUrl) {
        return;
      }

      // Add loading indicator
      const sidebarElement = document.querySelector('.sidebar-nav');
      if (sidebarElement) {
        sidebarElement.classList.add('loading');
      }

      try {
        const content = await loadSidebarContent(sidebarUrl);
        if (content) {
          updateSidebar(content);
        } else {
          // No content loaded for sidebar
        }
      } finally {
        // Remove loading indicator
        if (sidebarElement) {
          sidebarElement.classList.remove('loading');
        }
      }
    } catch {
      // Error in handleSectionChange
    }
  }

  /**
   * Extract section name from navbar link
   * @param {Element} navElement - Navbar element
   * @returns {string|null} Section name
   */
  function extractSectionName(navElement) {
    // Safety check for navElement
    if (!navElement || typeof navElement.textContent === 'undefined') {
      return null;
    }

    // Look for section title in various ways
    const textContent = navElement.textContent ? navElement.textContent.trim() : '';
    if (!textContent) {return null;}

    // Remove emoji and clean up text
    const cleanText = textContent.replace(/[^\w\s]/g, '').trim();

    // Map common variations to standard section names
    const sectionMappings = {
      'Home': 'Home',
      'Documentation': 'Documentation',
      'Learning': 'Learning',
      'Blueprints': 'Blueprints',
      'Infrastructure': 'Infrastructure',
      'GitHub Copilot': 'GitHub Copilot',
      'Copilot': 'GitHub Copilot'
    };

    // Check for exact matches first
    for (const [key, value] of Object.entries(sectionMappings)) {
      if (cleanText.includes(key)) {
        return value;
      }
    }

    return null;
  }

  /**
   * Initialize navbar click handlers
   */
  function initializeNavbarHandlers() {
    const navbar = document.querySelector('.app-nav');
    if (!navbar) {
      // Navbar not found, retrying in 500ms
      setTimeout(initializeNavbarHandlers, 500);
      return;
    }

    // Initialize dropdown hover management
    initializeDropdownHoverManagement();

    // Add click event listeners to navbar items
    navbar.addEventListener('click', (event) => {
      try {
        const target = event.target && event.target.closest ? event.target.closest('a') : null;
        if (!target) {return;}

        // Get parent list item to identify section
        const listItem = target.closest ? target.closest('li') : null;
        if (!listItem) {return;}

        // Check if this is a top-level section (not a subsection)
        const parentList = listItem.parentElement;
        if (!parentList ||
            (!parentList.classList.contains('app-nav') &&
             !(parentList.parentElement && parentList.parentElement.classList.contains('app-nav')))) {
          return; // This is a subsection, ignore
        }

        const sectionName = extractSectionName(target);
        if (sectionName) {
          // Delay the sidebar change to allow navigation to complete
          setTimeout(() => handleSectionChange(sectionName), 100);
        }
      } catch {
        // Error in navbar click handler
      }
    });

    isInitialized = true;
  }

  /**
   * Initialize dropdown hover management if available
   */
  function initializeDropdownHoverManagement() {
    try {
      if (window.NavbarDropdownManager && typeof window.NavbarDropdownManager.initialize === 'function') {
        const success = window.NavbarDropdownManager.initialize();
        if (!success) {
          // Navbar dropdown hover management failed to initialize
        }
      } else {
        // NavbarDropdownManager not available - dropdown hover persistence will not work
      }
    } catch {
      // Error initializing dropdown hover management
    }
  }

  /**
   * Cleanup function for route changes and reinitialization
   */
  function cleanupNavbarIntegration() {
    try {
      // Cleanup dropdown manager if available
      if (window.NavbarDropdownManager && typeof window.NavbarDropdownManager.cleanup === 'function') {
        window.NavbarDropdownManager.cleanup();
      }
    } catch {
      // Error during navbar integration cleanup
    }
  }

  /**
   * Detect section from current route
   * @param {string} route - Current docsify route
   * @returns {string|null} Detected section name
   */
  function detectSectionFromRoute(route) {
    if (!route || typeof route !== 'string') {return 'Home';}

    // Route-based section detection
    if (route.startsWith('/docs/')) {return 'Documentation';}
    if (route.startsWith('/learning/')) {return 'Learning';}
    if (route.startsWith('/blueprints/')) {return 'Blueprints';}
    if (route.startsWith('/src/') || route.startsWith('/tests/') || route.startsWith('/scripts/')) {return 'Infrastructure';}
    if (route.startsWith('/copilot/') || route.startsWith('/.github/')) {return 'GitHub Copilot';}

    return 'Home';
  }

  /**
   * Docsify plugin function
   * @param {Object} hook - Docsify hook object
   * @param {Object} vm - Docsify VM object
   */
  function navbarSidebarPlugin(hook, vm) {
    // Override sidebar loading before it happens
    hook.beforeEach((content, next) => {
      const routePath = vm && vm.route && vm.route.path ? vm.route.path : window.location.hash.replace('#', '') || '/';
      // Route path detection
      const section = detectSectionFromRoute(routePath);
      // Section detection

      // Override the sidebar if we're not on the home section
      if (section && section !== 'Home') {
        const sidebarUrl = NAVBAR_SIDEBAR_MAP[section];
        if (sidebarUrl) {
          // Loading sidebar for section
          // Load the appropriate sidebar content
          loadSidebarContent(sidebarUrl).then(sidebarContent => {
            if (sidebarContent) {
              // Update the sidebar immediately
              setTimeout(() => {
                updateSidebar(sidebarContent);
                currentSection = section;
              }, 100);
            }
          });
        }
      }

      next(content);
    });

    // Initialize when docsify is ready
    hook.ready(() => {
      // Navbar Sidebar Integration: Docsify ready
      initializeNavbarHandlers();

      // Set initial section based on current route with delay
      setTimeout(() => {
        const routePath = vm && vm.route && vm.route.path ? vm.route.path : window.location.hash.replace('#', '') || '/';
        // Initial route detection
        const initialSection = detectSectionFromRoute(routePath);
        // Detected initial section
        if (initialSection && initialSection !== 'Home') {
          // Setting initial section
          handleSectionChange(initialSection);
        }
      }, 500);
    });

    // Handle route changes
    hook.doneEach(() => {
      if (!isInitialized) {return;}

      const routePath = vm && vm.route && vm.route.path ? vm.route.path : window.location.hash.replace('#', '') || '/';
      // Route change detected
      const section = detectSectionFromRoute(routePath);
      // Detected section from route change
      if (section && section !== currentSection) {
        // Section changed
        handleSectionChange(section);
      }
    });
  }

  // Register plugin with docsify
  if (typeof window !== 'undefined') {
    window.$docsify = window.$docsify || {};
    window.$docsify.plugins = window.$docsify.plugins || [];

    // Add to the beginning of plugins array for early initialization
    window.$docsify.plugins.unshift(navbarSidebarPlugin);

    // Export for external access
    window.NavbarSidebarIntegration = {
      handleSectionChange,
      loadSidebarContent,
      updateSidebar,
      getCurrentSection: () => currentSection,
      clearCache: () => sidebarCache.clear(),
      cleanup: cleanupNavbarIntegration,
      reinitialize: () => {
        cleanupNavbarIntegration();
        setTimeout(() => initializeNavbarHandlers(), 100);
      }
    };
  }
})();
