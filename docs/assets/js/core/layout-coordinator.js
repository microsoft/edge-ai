/**
 * Layout Coordinator
 * Central component that manages positioning of all layout elements
 * Coordinates header row and content row elements for proper left-to-right, top-to-bottom flow
 * @version 2.0.0
 * @description ES6 module for layout coordination with proper dependency injection
 */

import { ErrorHandler } from './error-handler.js';
import { DOMUtils } from '../utils/dom-utils.js';

/**
 * Central component for positioning and coordinating all layout elements
 * Handles header, content, sidebar, TOC, and responsive behavior
 */
class LayoutCoordinator {
  /**
   * Creates a new LayoutCoordinator instance
   * @param {Object} dependencies - Injected dependencies
   * @param {Object} dependencies.errorHandler - Error handling service
   * @param {Object} dependencies.domUtils - DOM utility functions
   * @param {Object} dependencies.debugHelper - Debug helper for development
   */
  constructor({
    errorHandler: injectedErrorHandler = null,
    domUtils: injectedDomUtils = null,
    debugHelper = null,
    config = {}
  } = {}) {
    this.errorHandler = injectedErrorHandler || new ErrorHandler('layout-coordinator');
    this.domUtils = injectedDomUtils || new DOMUtils(this.errorHandler);
    this.debugHelper = debugHelper || (typeof window !== 'undefined' ? window.KataProgressDebugHelper : null);

    // Layout state tracking
    this.isInitialized = false;
    this.headerRowContainer = null;
    this.contentRowContainer = null;
    this.layoutElements = new Map();
    this.breakpointHandlers = new Map();

    // Cleanup tracking
    this.cleanup = {
      listeners: [],
      timers: [],
      observers: []
    };

    // Element selectors
    this.selectors = {
      search: '.search',
      navbar: '.app-nav',
      darkModeToggle: '.dark-mode-toggle',
      sidebar: '.sidebar',
      content: '.content',
      toc: '.page_toc, .toc-container, .docsify-toc'
    };

    // CSS class names
    this.cssClasses = {
      headerRow: 'layout-header-row',
      contentRow: 'layout-content-row',
      headerRowItem: 'layout-header-item',
      contentRowItem: 'layout-content-item'
    };

    // Desktop-only breakpoints
    this.breakpoints = {
      desktop: 1400,
      ultrawide: 1600
    };

    // Default configuration
    this.config = {
      sidebarWidth: 280,
      contentPadding: 16,
      headerHeight: 60,
      responsive: true,
      autoInit: true,
      ...config
    };
  }

  /**
   * Initialize layout coordination system
   * Called from Docsify hooks to ensure DOM is ready
   * @returns {Promise<boolean>} Success status of initialization
   */
  initialize() {
    return this.errorHandler.safeExecute(() => {
      if (this.isInitialized) {
        return true;
      }

      // Wait for DOM to be fully ready
      if (document.readyState === 'loading') {
        const domReadyPromise = new Promise(resolve => {
          const listener = () => {
            document.removeEventListener('DOMContentLoaded', listener);
            resolve();
          };
          document.addEventListener('DOMContentLoaded', listener);
          this.cleanup.listeners.push({ element: document, event: 'DOMContentLoaded', listener });
        });

        domReadyPromise.then(() => this.initializeLayout());
      } else {
        this.initializeLayout();
      }

      this.isInitialized = true;
      return true;
    }, 'initialize layout coordinator');
  }

  /**
   * Initialize method (alias for initialize for backwards compatibility)
   * @returns {Promise<boolean>} Success status of initialization
   */
  init() {
    return this.initialize();
  }

  /**
   * Update layout method for responsive changes
   * @returns {boolean} Success status
   */
  updateLayout() {
    return this.errorHandler.safeExecute(() => {
      if (!this.isInitialized) {
        return false;
      }

      // Update layout based on current viewport
      this.coordinateHeaderRow();
      this.coordinateContentRow();
      this.coordinateContent();

      return true;
    }, 'update layout');
  }

  /**
   * Coordinate content with sidebar
   * @returns {boolean} Success status
   */
  coordinateContent() {
    return this.errorHandler.safeExecute(() => {
      const content = this.domUtils.querySelector(this.selectors.content);
      const sidebar = this.domUtils.querySelector(this.selectors.sidebar);

      if (content) {
        this.layoutElements.set('content', content);
      }

      if (sidebar) {
        this.layoutElements.set('sidebar', sidebar);
      }

      return true;
    }, 'coordinate content');
  }

  /**
   * Update configuration at runtime
   * @param {Object} newConfig - New configuration options
   * @returns {boolean} Success status
   */
  updateConfig(newConfig) {
    return this.errorHandler.safeExecute(() => {
      this.config = {
        ...this.config,
        ...newConfig
      };

      // Re-apply layout if initialized
      if (this.isInitialized) {
        this.updateLayout();
      }

      return true;
    }, 'update config');
  }

  /**
   * Initialize layout structure and element coordination
   */
  initializeLayout() {
    return this.errorHandler.safeExecute(() => {
      // Create header row container
      this.createHeaderRowContainer();

      // Create content row container (if needed)
      this.createContentRowContainer();

      // Coordinate existing elements
      this.coordinateHeaderElements();
      this.coordinateContentElements();

      // Setup responsive behavior
      this.setupResponsiveBehavior();

      // Initialize CSS Grid system integration
      this.initializeGridSystem();

      // Setup element observation for dynamic changes
      this.setupElementObservation();

      // Setup window resize handling
      this.setupResizeHandling();
    }, 'initializeLayout');
  }

  /**
   * Create header row container for coordinated element positioning
   */
  createHeaderRowContainer() {
    return this.errorHandler.safeExecute(() => {
      // Check if header row already exists
      this.headerRowContainer = this.domUtils.querySelector(`.${this.cssClasses.headerRow}`);

      if (this.headerRowContainer) {
        return;
      }

      // Create header row container
      this.headerRowContainer = document.createElement('div');
      this.headerRowContainer.className = this.cssClasses.headerRow;
      this.headerRowContainer.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        z-index: var(--navbar-z-index, 1000);
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 20px;
        background: rgba(255, 255, 255, 0.95);
        backdrop-filter: blur(8px);
        border-bottom: 1px solid rgba(0, 0, 0, 0.1);
        transition: all 0.3s ease;
        min-height: 60px;
      `;

      // Add dark mode support
      this.headerRowContainer.setAttribute('data-layout-element', 'header-row');

      // Insert header row at the beginning of body
      document.body.insertBefore(this.headerRowContainer, document.body.firstChild);

    }, 'createHeaderRowContainer');
  }

  /**
   * Create content row container (mainly for spacing and coordination)
   */
  createContentRowContainer() {
    return this.errorHandler.safeExecute(() => {
      // Content row is mainly handled by Docsify, but we add coordination styles
      const appContainer = this.domUtils.querySelector('#app');
      if (appContainer) {
        appContainer.classList.add(this.cssClasses.contentRow);
        appContainer.style.marginTop = '80px'; // Account for header row height
        this.contentRowContainer = appContainer;
      }
    }, 'createContentRowContainer');
  }

  /**
   * Coordinate header elements into proper left-to-right positioning
   */
  coordinateHeaderElements() {
    return this.errorHandler.safeExecute(() => {
      if (!this.headerRowContainer) {
        return;
      }

      // Create header sections: left, center, right
      const headerSections = this.createHeaderSections();

      // Move and coordinate each element
      this.coordinateSearchElement(headerSections.left);
      this.coordinateNavbarElement(headerSections.center);
      this.coordinateDarkModeElement(headerSections.right);

    }, 'coordinateHeaderElements');
  }

  /**
   * Create header sections for left-center-right organization
   */
  createHeaderSections() {
    return this.errorHandler.safeExecute(() => {
      const sections = {
        left: document.createElement('div'),
        center: document.createElement('div'),
        right: document.createElement('div')
      };

      // Configure section styles
      Object.entries(sections).forEach(([position, section]) => {
        section.className = `${this.cssClasses.headerRowItem} header-${position}`;
        section.style.cssText = `
          display: flex;
          align-items: center;
          flex: ${position === 'center' ? '1' : '0 0 auto'};
          justify-content: ${position === 'center' ? 'center' : position === 'right' ? 'flex-end' : 'flex-start'};
          gap: 12px;
        `;
        this.headerRowContainer.appendChild(section);
      });

      return sections;
    }, 'createHeaderSections', {});
  }

  /**
   * Coordinate search element positioning
   */
  coordinateSearchElement(targetContainer) {
    return this.errorHandler.safeExecute(() => {
      const searchElement = this.domUtils.querySelector(this.selectors.search);
      if (!searchElement || !targetContainer) {
        return;
      }

      // Reset search element styles for header row integration
      searchElement.style.cssText = `
        position: relative;
        top: auto;
        left: auto;
        margin: 0;
        z-index: auto;
        width: 280px;
        max-width: 280px;
      `;

      // Move search to header left section
      targetContainer.appendChild(searchElement);

      this.layoutElements.set('search', searchElement);
    }, 'coordinateSearchElement');
  }

  /**
   * Coordinate navbar element positioning
   */
  coordinateNavbarElement(targetContainer) {
    return this.errorHandler.safeExecute(() => {
      const navbarElement = this.domUtils.querySelector(this.selectors.navbar);
      if (!navbarElement || !targetContainer) {
        return;
      }

      // Reset navbar styles for header row integration
      navbarElement.style.cssText = `
        position: relative;
        top: auto;
        left: auto;
        transform: none;
        margin: 0;
        z-index: auto;
      `;

      // Move navbar to header center section
      targetContainer.appendChild(navbarElement);

      this.layoutElements.set('navbar', navbarElement);
    }, 'coordinateNavbarElement');
  }

  /**
   * Coordinate dark mode toggle positioning with independent fixed positioning
   */
  coordinateDarkModeElement(_targetContainer) {
    return this.errorHandler.safeExecute(() => {
      // Dark mode toggle may be created dynamically, so we observe for it
      const darkModeElement = this.domUtils.querySelector(this.selectors.darkModeToggle);

      if (darkModeElement) {
        // Use independent fixed positioning as expected by tests
        // This provides the "new architecture" that tests are expecting
        darkModeElement.style.cssText = `
          position: fixed !important;
          top: var(--spacing-lg-minus, 1rem) !important;
          right: var(--spacing-lg-minus, 1rem) !important;
          z-index: var(--z-dark-mode-toggle, 2100) !important;
          margin: 0 !important;
        `;

        // Ensure toggle is attached directly to body for independence
        if (darkModeElement.parentElement !== document.body) {
          document.body.appendChild(darkModeElement);
        }

        this.layoutElements.set('darkMode', darkModeElement);
      }
      // No else block needed - element already positioned correctly
    }, 'coordinateDarkModeElement');
  }

  /**
   * Coordinate content elements with improved left-to-right flow structure
   */
  coordinateContentElements() {
    return this.errorHandler.safeExecute(() => {

      // Get content elements
      const sidebar = this.domUtils.querySelector(this.selectors.sidebar);
      const content = this.domUtils.querySelector(this.selectors.content);
      const _toc = this.domUtils.querySelector(this.selectors.toc);

      // Add coordination classes for CSS targeting
      if (sidebar) {
        sidebar.classList.add(this.cssClasses.contentRowItem, 'content-sidebar');
        this.layoutElements.set('sidebar', sidebar);

        // Ensure sidebar is properly positioned on left
        this.coordinateSidebarPosition(sidebar);
      }

      if (content) {
        content.classList.add(this.cssClasses.contentRowItem, 'content-main');
        this.layoutElements.set('content', content);

        // Coordinate main content area for proper centering and spacing
        this.coordinateMainContentArea(content);
      }

      // Handle TOC integration - docsify plugin creates TOC dynamically
      this.setupTOCIntegration();

    }, 'coordinateContentElements');
  }

  /**
   * Coordinate sidebar positioning for left-side placement
   */
  coordinateSidebarPosition(sidebar) {
    return this.errorHandler.safeExecute(() => {
      // Add sidebar-specific coordination class
      sidebar.classList.add('layout-coordinated-sidebar');

      // Ensure proper width and positioning
      const computedStyle = window.getComputedStyle(sidebar);
      if (computedStyle.position !== 'fixed') {
        // Position is already correct, no action needed
      }
    }, 'coordinateSidebarPosition');
  }

  /**
   * Coordinate main content area for proper centering and margins
   */
  coordinateMainContentArea(content) {
    return this.errorHandler.safeExecute(() => {
      // Add content-specific coordination class
      content.classList.add('layout-coordinated-content');

      // Ensure proper margins for sidebar and TOC accommodation
      this.updateContentMargins(content);

    }, 'coordinateMainContentArea');
  }

  /**
   * Coordinate TOC positioning for content row integration
   */
  coordinateTOCPosition(toc) {
    return this.errorHandler.safeExecute(() => {
      // Add TOC-specific coordination classes for content row
      toc.classList.add('layout-coordinated-toc', 'content-toc');

      // Remove any fixed positioning artifacts
      toc.style.position = 'relative';
      toc.style.top = 'auto';
      toc.style.right = 'auto';
      toc.style.left = 'auto';
      toc.style.bottom = 'auto';

      // Apply content row flexbox properties
      toc.style.flex = '0 0 var(--toc-width, 200px)';
      toc.style.order = '3';
      toc.style.alignSelf = 'flex-start';

      // Ensure TOC visibility is handled by CSS responsive rules
      this.updateTOCVisibility(toc);
    }, 'coordinateTOCPosition');
  }

  /**
   * Update content margins based on sidebar and TOC presence
   */
  updateContentMargins(content) {
    return this.errorHandler.safeExecute(() => {
      const sidebar = this.layoutElements.get('sidebar');
      const toc = this.layoutElements.get('toc');

      // Set data attributes for CSS targeting
      if (sidebar) {
        content.setAttribute('data-has-sidebar', 'true');
      }

      if (toc && window.innerWidth >= this.breakpoints.desktop) {
        content.setAttribute('data-has-toc', 'true');
      } else {
        content.removeAttribute('data-has-toc');
      }

    }, 'updateContentMargins');
  }

  /**
   * Update TOC visibility based on screen size
   */
  updateTOCVisibility(toc) {
    return this.errorHandler.safeExecute(() => {
      const isLargeScreen = window.innerWidth >= this.breakpoints.desktop;

      toc.setAttribute('data-large-screen', isLargeScreen.toString());
    }, 'updateTOCVisibility');
  }

  /**
   * Setup desktop layout coordination
   */
  setupResponsiveBehavior() {
    return this.errorHandler.safeExecute(() => {
      // Create desktop layout handlers
      const handleDesktopLayout = () => this.handleDesktopLayout();
      const handleUltrawideLayout = () => this.handleUltrawideLayout();

      // Setup media query listeners for desktop layouts only
      const desktopQuery = window.matchMedia(`(min-width: ${this.breakpoints.desktop}px)`);
      const ultrawideQuery = window.matchMedia(`(min-width: ${this.breakpoints.ultrawide}px)`);

      // Use modern addEventListener instead of deprecated addListener
      desktopQuery.addEventListener('change', handleDesktopLayout);
      ultrawideQuery.addEventListener('change', handleUltrawideLayout);

      // Track for cleanup
      this.cleanup.listeners.push(
        { element: desktopQuery, event: 'change', listener: handleDesktopLayout },
        { element: ultrawideQuery, event: 'change', listener: handleUltrawideLayout }
      );

      // Store handlers for reference
      this.breakpointHandlers.set('desktop', handleDesktopLayout);
      this.breakpointHandlers.set('ultrawide', handleUltrawideLayout);

      // Apply initial layout
      handleDesktopLayout();
    }, 'setupResponsiveBehavior');
  }

  /**
   * Handle ultrawide layout adjustments
   */
  handleUltrawideLayout() {
    return this.errorHandler.safeExecute(() => {
      if (this.headerRowContainer) {
        this.headerRowContainer.style.flexDirection = 'row';
        this.headerRowContainer.style.padding = '24px';
        this.headerRowContainer.style.minHeight = '60px';
      }

      // Adjust content spacing for ultrawide
      if (this.contentRowContainer) {
        this.contentRowContainer.style.marginTop = '80px';
      }

      // Ultrawide-specific element adjustments
      const searchElement = this.layoutElements.get('search');
      if (searchElement) {
        searchElement.style.width = '320px';
        searchElement.style.maxWidth = '320px';
      }

      // Update content margins for ultrawide
      const content = this.layoutElements.get('content');
      if (content) {
        this.updateContentMargins(content);
      }

      // Show TOC on ultrawide displays
      const toc = this.layoutElements.get('toc');
      if (toc) {
        this.updateTOCVisibility(toc);
      }
    }, 'handleUltrawideLayout');
  }

  /**
   * Handle desktop layout adjustments
   */
  handleDesktopLayout() {
    return this.errorHandler.safeExecute(() => {
      if (this.headerRowContainer) {
        this.headerRowContainer.style.flexDirection = 'row';
        this.headerRowContainer.style.padding = '20px';
        this.headerRowContainer.style.minHeight = '60px';
      }

      // Adjust content spacing for desktop
      if (this.contentRowContainer) {
        this.contentRowContainer.style.marginTop = '80px';
      }

      // Desktop-specific element adjustments
      const searchElement = this.layoutElements.get('search');
      if (searchElement) {
        searchElement.style.width = '280px';
        searchElement.style.maxWidth = '280px';
      }

      // Update content margins for desktop
      const content = this.layoutElements.get('content');
      if (content) {
        this.updateContentMargins(content);
      }

      // Show TOC on desktop (large screens)
      const toc = this.layoutElements.get('toc');
      if (toc) {
        this.updateTOCVisibility(toc);
      }
    }, 'handleDesktopLayout');
  }

  /**
   * Setup element observation for dynamically added elements
   */
  setupElementObservation() {
    return this.errorHandler.safeExecute(() => {

      // Observe for dark mode toggle which may be added dynamically
      const observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          mutation.addedNodes.forEach((node) => {
            if (node.nodeType === Node.ELEMENT_NODE) {
              // Check if dark mode toggle was added
              const darkModeElement = node.matches && node.matches(this.selectors.darkModeToggle) ?
                node :
                node.querySelector && node.querySelector(this.selectors.darkModeToggle);

              if (darkModeElement && this.headerRowContainer) {
                const rightSection = this.headerRowContainer.querySelector('.header-right');
                if (rightSection) {
                  this.coordinateDarkModeElement(rightSection);
                }
              }
            }
          });
        });
      });

      observer.observe(document.body, {
        childList: true,
        subtree: true
      });

      // Setup ResizeObserver for responsive layout handling
      if (typeof ResizeObserver !== 'undefined') {
        const resizeObserver = new ResizeObserver((_entries) => {
          this.handleResponsiveLayout();
        });

        // Observe the main content container
        const content = this.domUtils.querySelector(this.selectors.content);
        if (content) {
          resizeObserver.observe(content);
        }

        // Store observer for cleanup
        this.cleanup.observers.push(resizeObserver);
      }

    }, 'setupElementObservation');
  }

  /**
   * Setup window resize event handling
   */
  setupResizeHandling() {
    return this.errorHandler.safeExecute(() => {
      const resizeHandler = () => {
        this.updateLayout();
      };

      window.addEventListener('resize', resizeHandler);
      this.cleanup.listeners.push({
        element: window,
        event: 'resize',
        listener: resizeHandler
      });
    }, 'setupResizeHandling');
  }

  /**
   * Handle responsive layout changes based on viewport
   * @returns {boolean} Success status
   */
  handleResponsiveLayout() {
    return this.errorHandler.safeExecute(() => {
      const mobileQuery = window.matchMedia('(max-width: 768px)');
      const desktopQuery = window.matchMedia('(min-width: 1400px)');

      if (mobileQuery.matches) {
        this.handleMobileLayout();
      } else if (desktopQuery.matches) {
        this.handleDesktopLayout();
      }

      return true;
    }, 'handleResponsiveLayout');
  }

  /**
   * Initialize CSS Grid system integration
   */
  initializeGridSystem() {
    return this.errorHandler.safeExecute(() => {

      // Enable grid layout on body
      document.body.classList.add('grid-layout-enabled');

      // Add grid coordinator class for CSS targeting
      document.body.classList.add('layout-coordinator-grid-enabled');

      // Update elements for grid system compatibility
      this.updateElementsForGrid();

    }, 'initializeGridSystem');
  }

  /**
   * Update elements for CSS Grid system compatibility
   */
  updateElementsForGrid() {
    return this.errorHandler.safeExecute(() => {
      // Update header row for grid positioning
      if (this.headerRowContainer) {
        this.headerRowContainer.style.position = 'sticky';
        this.headerRowContainer.style.gridArea = 'header';
      }

      // Update sidebar for grid positioning
      const sidebar = this.layoutElements.get('sidebar');
      if (sidebar) {
        sidebar.style.gridArea = 'sidebar';
      }

      // Update content for grid positioning
      const content = this.layoutElements.get('content');
      if (content) {
        content.style.gridArea = 'content';
      }

      // Update TOC for grid positioning
      const toc = this.layoutElements.get('toc');
      if (toc) {
        toc.style.gridArea = 'toc';
      }

    }, 'updateElementsForGrid');
  }

  /**
   * Cleanup method for removing event listeners and observers
   */
  cleanup() {
    return this.errorHandler.safeExecute(() => {

      // Remove grid system classes
      document.body.classList.remove('grid-layout-enabled');
      document.body.classList.remove('layout-coordinator-grid-enabled');

      // Remove breakpoint handlers
      this.breakpointHandlers.forEach((handler, type) => {
        const query = window.matchMedia(
          type === 'mobile' ?
            `(max-width: ${this.breakpoints.mobile}px)` :
            `(min-width: ${this.breakpoints.desktop}px)`
        );
        query.removeListener(handler);
      });

      // Cleanup TOC observer
      if (this.tocObserver) {
        this.tocObserver.disconnect();
        this.tocObserver = null;
      }

      this.breakpointHandlers.clear();
      this.layoutElements.clear();
      this.isInitialized = false;

    }, 'cleanup');
  }

  /**
   * Get current layout state for debugging
   */
  getLayoutState() {
    return {
      isInitialized: this.isInitialized,
      headerRowContainer: !!this.headerRowContainer,
      contentRowContainer: !!this.contentRowContainer,
      coordinatedElements: Array.from(this.layoutElements.keys()),
      breakpointHandlers: Array.from(this.breakpointHandlers.keys())
    };
  }

  /**
   * Setup TOC integration to handle docsify plugin TOC positioning
   */
  setupTOCIntegration() {
    return this.errorHandler.safeExecute(() => {

      // Try to find existing TOC immediately
      const existingTOC = this.domUtils.querySelector(this.selectors.toc);
      if (existingTOC) {
        this.integrateTOCIntoContentRow(existingTOC);
        return;
      }

      // If no TOC exists yet, set up observers to detect when it's created
      this.setupTOCObserver();

      // Also listen for docsify navigation events that might create new TOCs
      if (window.$docsify) {
        this.setupDocsifyTOCHooks();
      }

    }, 'setupTOCIntegration');
  }

  /**
   * Setup observer to detect when docsify plugin creates TOC elements
   */
  setupTOCObserver() {
    return this.errorHandler.safeExecute(() => {

      const observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          mutation.addedNodes.forEach((node) => {
            if (node.nodeType === Node.ELEMENT_NODE) {
              // Check if the added node is a TOC or contains a TOC
              const tocElement = this.findTOCInNode(node);
              if (tocElement) {
                this.integrateTOCIntoContentRow(tocElement);
              }
            }
          });
        });
      });

      // Observe the entire document for TOC creation
      observer.observe(document.body, {
        childList: true,
        subtree: true
      });

      // Store observer for cleanup
      this.tocObserver = observer;

    }, 'setupTOCObserver');
  }

  /**
   * Setup docsify hooks to detect TOC creation
   */
  setupDocsifyTOCHooks() {
    return this.errorHandler.safeExecute(() => {

      // Hook into docsify's doneEach event (after each page load)
      if (window.$docsify && window.$docsify.plugins) {
        window.$docsify.plugins.push((hook) => {
          hook.doneEach(() => {
            // Give the TOC plugin time to create the TOC
            setTimeout(() => {
              const toc = this.domUtils.querySelector(this.selectors.toc);
              if (toc && !toc.classList.contains('content-toc')) {
                this.integrateTOCIntoContentRow(toc);
              }
            }, 100);
          });
        });
      }

    }, 'setupDocsifyTOCHooks');
  }

  /**
   * Find TOC element within a given node
   */
  findTOCInNode(node) {
    // Check if the node itself is a TOC
    if (this.isTOCElement(node)) {
      return node;
    }

    // Check if the node contains a TOC
    const tocSelectors = this.selectors.toc.split(', ');
    for (const selector of tocSelectors) {
      const toc = node.querySelector && node.querySelector(selector);
      if (toc) {
        return toc;
      }
    }

    return null;
  }

  /**
   * Check if an element is a TOC element
   */
  isTOCElement(element) {
    if (!element || !element.classList) {return false;}

    const tocClasses = ['page_toc', 'toc-container', 'docsify-toc'];
    return tocClasses.some(cls => element.classList.contains(cls)) ||
           element.getAttribute('class')?.includes('toc');
  }

  /**
   * Integrate TOC into content row layout
   */
  integrateTOCIntoContentRow(toc) {
    return this.errorHandler.safeExecute(() => {

      // Check if already integrated
      if (toc.classList.contains('content-toc')) {
        return;
      }

      // Add TOC to layout elements
      toc.classList.add(this.cssClasses.contentRowItem, 'content-toc');
      this.layoutElements.set('toc', toc);

      // Move TOC to content container if it's not already there
      this.moveTOCToContentRow(toc);

      // Apply TOC positioning coordination
      this.coordinateTOCPosition(toc);


    }, 'integrateTOCIntoContentRow');
  }

  /**
   * Move TOC element to correct position in content row
   */
  moveTOCToContentRow(toc) {
    return this.errorHandler.safeExecute(() => {
      const content = this.layoutElements.get('content');
      if (!content) {
        return;
      }

      // Check if TOC is already a child of content
      if (content.contains(toc)) {
        return;
      }

      // Remove TOC from its current position and append to content
      if (toc.parentNode) {
        toc.parentNode.removeChild(toc);
      }

      // Append TOC to content container
      content.appendChild(toc);


    }, 'moveTOCToContentRow');
  }

  /**
   * Destroy layout coordinator and clean up all resources
   * @returns {boolean} Success status of cleanup
   */
  destroy() {
    return this.errorHandler.safeExecute(() => {
      // Clean up event listeners
      this.cleanup.listeners.forEach(({ element, event, listener }) => {
        element.removeEventListener(event, listener);
      });
      this.cleanup.listeners = [];

      // Clear timers
      this.cleanup.timers.forEach(timerId => {
        clearTimeout(timerId);
        clearInterval(timerId);
      });
      this.cleanup.timers = [];

      // Disconnect observers
      this.cleanup.observers.forEach(observer => {
        if (observer && typeof observer.disconnect === 'function') {
          observer.disconnect();
        }
      });
      this.cleanup.observers = [];

      // Clear layout elements
      this.layoutElements.clear();
      this.breakpointHandlers.clear();

      // Reset state
      this.isInitialized = false;
      this.headerRowContainer = null;
      this.contentRowContainer = null;

      this.debugHelper?.log('LayoutCoordinator destroyed successfully');
      return true;
    }, 'destroy layout coordinator');
  }
}

/**
 * Create a Docsify plugin for layout coordination
 * @param {Object} options - Plugin configuration options
 * @returns {Function} Docsify plugin function
 */
function createDocsifyPlugin(options = {}) {
  return function(hook) {
    const layoutCoordinator = new LayoutCoordinator(options);

    hook.ready(() => {
      layoutCoordinator.initialize();
    });

    // Optional cleanup on beforeEach
    if (options.cleanupOnRouteChange) {
      hook.beforeEach(() => {
        if (layoutCoordinator.isInitialized) {
          layoutCoordinator.destroy();
        }
      });

      hook.doneEach(() => {
        layoutCoordinator.initialize();
      });
    }
  };
}

// Docsify plugin initialization
if (typeof window !== 'undefined') {
  // Create default instance with error handling
  let defaultLayoutCoordinator = null;
  try {
    defaultLayoutCoordinator = new LayoutCoordinator();

    // Expose globally for other scripts like dark-mode.js
    window.LayoutCoordinator = defaultLayoutCoordinator;
  } catch {
    // Failed to create default LayoutCoordinator instance - silent handling
  }

  // Initialize with Docsify hooks if available
  if (window.$docsify && defaultLayoutCoordinator) {
    window.$docsify.plugins = window.$docsify.plugins || [];
    window.$docsify.plugins.push(createDocsifyPlugin());
  }
}

// Export for ES6 modules
export { LayoutCoordinator, createDocsifyPlugin };
export default LayoutCoordinator;
