/**
 * Enhanced Anchor Links
 * Provides enhanced anchor link functionality for Docsify documentation
 * @class EnhancedAnchorLinks
 * @author Edge AI Team
 * @version 3.0.0 - ES6 Module with improved navigation and scrolling
 */

import { ErrorHandler } from '../core/error-handler.js';
import { DOMUtils } from '../utils/dom-utils.js';
import { logger } from '../utils/index.js';
import { AutoScrollTop } from './auto-scroll-top.js';
import { docsifyIntegration } from '../core/docsify-integration.js';

/**
 * Enhanced Anchor Links
 * Provides enhanced anchor link functionality including smooth scrolling,
 * better clickable areas for headers, visual feedback, and auto-scroll offset
 * @class EnhancedAnchorLinks
 */
export class EnhancedAnchorLinks {
  /**
   * Create an enhanced anchor links manager
   * @param {Object} config - Configuration options
   * @param {number} config.scrollOffset - Offset for fixed headers (default: 80)
   * @param {number} config.scrollDuration - Smooth scroll duration in ms (default: 600)
   * @param {number} config.retryAttempts - Max attempts for anchor detection (default: 12)
   * @param {boolean} config.debug - Enable debug logging
   * @param {ErrorHandler} config.errorHandler - Error handler instance
   * @param {DOMUtils} config.domUtils - DOM utilities instance
   */
  constructor(config = {}) {
    this.config = {
      scrollOffset: config.scrollOffset || 80,
      scrollDuration: config.scrollDuration || 600,
      retryAttempts: config.retryAttempts || 12,
      debug: config.debug !== undefined ? config.debug : this._detectDebugMode(),
      ...config
    };

    // Dependencies
    this.errorHandler = config.errorHandler || new ErrorHandler('enhanced-anchor-links');
    this.domUtils = config.domUtils || new DOMUtils();

    // Auto-scroll functionality
    this.autoScrollTop = new AutoScrollTop({
      errorHandler: this.errorHandler,
      debug: this.config.debug,
      enabled: config.autoScrollEnabled !== false
    });

    // State tracking
    this.previousHash = '';
    this.isInitialized = false;
    this.navigationTimeout = null;
    this.mutationObserver = null;
    this.anchorHandlingInProgress = false;
    this.docsifyContentLoading = false;
    this.lastProcessedRoute = null; // Track route changes for scroll-to-top

    // Bind methods for event listeners
    this.handleAnchorClick = this.handleAnchorClick.bind(this);
    this.handleHashChange = this.handleHashChange.bind(this);
    this.handlePopState = this.handlePopState.bind(this);
  }

  /**
   * Detect if debug mode is enabled via URL parameter or localStorage
   * @private
   * @returns {boolean} True if debug mode is enabled
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
   * Debug logging that only outputs when debug mode is enabled
   * @private
   * @param {...any} args - Arguments to log
   */
  debugLog(...args) {
    if (this.config.debug) {
      console.log('[Enhanced Anchor Links]', ...args);
    }
  }

  /**
   * Initialize enhanced anchor links with Docsify integration
   */
  initialize() {
    this.errorHandler.safeExecute(() => {
      if (this.isInitialized) {
        this.debugLog('Already initialized, skipping...');
        return;
      }

      this.debugLog('Initializing enhanced anchor links...');

      this.setupEventListeners();
      this.enhanceHeaderLinks();
      this.setupTOCClickHandlers();
      this.handleInitialHash();

      // Initialize auto-scroll functionality
      this.autoScrollTop.initialize();

      // Register with Docsify integration system for lifecycle management
      this.registerWithDocsifyIntegration();

      this.isInitialized = true;
      this.debugLog('Enhanced anchor links initialized successfully');
    }, 'EnhancedAnchorLinks.initialize');
  }

  /**
   * Register with the Docsify integration system for proper lifecycle management
   * @private
   */
  registerWithDocsifyIntegration() {
    this.errorHandler.safeExecute(() => {
      if (docsifyIntegration && typeof docsifyIntegration.registerComponent === 'function') {
        docsifyIntegration.registerComponent('enhanced-anchor-links', {
          initialize: () => this.reinitializeAfterContentChange(),
          destroy: () => this.destroy(),
          name: 'Enhanced Anchor Links',
          // Expose the instance for access to autoScrollTop and other properties
          instance: this,
          autoScrollTop: this.autoScrollTop,
          config: this.config
        });

        // Add hook for doneEach to ensure proper timing
        docsifyIntegration.addHook('doneEach', (vm) => {
          this.debugLog('Docsify integration doneEach hook triggered');

          // Also handle scroll-to-top logic here since this hook is actually working
          const currentRoute = vm?.route?.path || '';
          const currentHash = window.location.hash;

          this.debugLog('Integration hook - route check:', {
            route: currentRoute,
            hash: currentHash,
            previousRoute: this.lastProcessedRoute
          });

          // Check if this is a route change
          const routeChanged = this.lastProcessedRoute && this.lastProcessedRoute !== currentRoute;

          if (routeChanged) {
            this.debugLog('Integration hook detected route change - triggering scroll to top');
            setTimeout(() => {
              this.scheduleScrollToTop('integration-route-change');
            }, 100);
          }

          // Update last processed route
          this.lastProcessedRoute = currentRoute;

          setTimeout(() => {
            this.enhanceHeaderLinks();
            this.setupTOCClickHandlers();
          }, 50);
        });

        this.debugLog('Registered with Docsify integration system');
      } else {
        this.debugLog('Docsify integration not available, using standalone mode');
      }
    }, 'EnhancedAnchorLinks.registerWithDocsifyIntegration');
  }

  /**
   * Reinitialize after content changes (called by Docsify integration)
   * @private
   */
  reinitializeAfterContentChange() {
    this.errorHandler.safeExecute(() => {
      this.debugLog('Reinitializing after content change');

      // Re-enhance links and setup handlers for new content
      this.enhanceHeaderLinks();
      this.setupTOCClickHandlers();

      // Handle any anchor in the current URL
      const currentHash = window.location.hash;
      if (currentHash && currentHash.includes('?id=')) {
        this.debugLog('Content change with anchor - handling navigation');
        setTimeout(() => {
          this.handleNavigation(currentHash, null);
        }, 100);
      } else {
        // No anchor in URL - this is a route change, scroll to top
        this.debugLog('Content change without anchor - triggering scroll to top');
        setTimeout(() => {
          this.scheduleScrollToTop('reinit-route-change');
        }, 100);
      }

      this.debugLog('Reinitialization complete');
    }, 'EnhancedAnchorLinks.reinitializeAfterContentChange');
  }

  /**
   * Setup event listeners for anchor navigation
   * @private
   */
  setupEventListeners() {
    this.errorHandler.safeExecute(() => {
      // Document-wide click handler for anchor links
      document.addEventListener('click', this.handleAnchorClick);

      // Navigation event listeners
      window.addEventListener('hashchange', this.handleHashChange);
      window.addEventListener('popstate', this.handlePopState);

      this.previousHash = window.location.hash;
      this.debugLog('Event listeners setup complete');
    }, 'EnhancedAnchorLinks.setupEventListeners');
  }

  /**
   * Handle anchor link clicks with enhanced behavior
   * @param {Event} event - Click event
   * @private
   */
  handleAnchorClick(event) {
    this.errorHandler.safeExecute(() => {
      const link = event.target.closest('a');
      if (!link) {return;}

      const href = link.getAttribute('href');
      if (!href || !href.startsWith('#')) {return;}

      // Skip Docsify route links WITHOUT anchors (e.g., #/path/to/page)
      // But handle Docsify anchor links (e.g., #/path/to/page?id=anchor-id)
      if (href.startsWith('#/') && !href.includes('?id=')) {return;}

      // Extract anchor: either from ?id=anchor or #anchor format
      let anchor;
      if (href.includes('?id=')) {
        anchor = href.split('?id=')[1];
      } else {
        anchor = href.substring(1);
      }
      if (!anchor) {return;}

      this.debugLog('Anchor click detected:', anchor);

      // Check if this is a TOC click
      const isTOCClick = link.closest('.page_toc');
      const target = this.findTargetElement(anchor, isTOCClick);

      if (!target) {
        this.debugLog('Target not found for anchor:', anchor);
        return;
      }

      // Prevent default navigation
      event.preventDefault();

      // Update URL without triggering navigation
      this.updateURL(anchor);

      // Smooth scroll to target
      this.smoothScrollToElement(target);

      // Add visual highlight
      this.highlightTarget(target);

      if (isTOCClick) {
        this.debugLog('TOC link processed successfully');
      }
    }, 'EnhancedAnchorLinks.handleAnchorClick');
  }

  /**
   * Handle hash change events
   * @param {Event} event - Hash change event
   * @private
   */
  handleHashChange(event) {
    this.errorHandler.safeExecute(() => {
      const newHash = window.location.hash;
      const oldHash = event.oldURL ? `#${ event.oldURL.split('#')[1] || ''}` : '';

      this.debugLog('Hash change detected:', oldHash, '->', newHash);

      // Small delay to ensure content is loaded
      clearTimeout(this.navigationTimeout);
      this.navigationTimeout = setTimeout(() => {
        this.handleNavigation(newHash, oldHash);
        this.previousHash = newHash;
      }, 100);
    }, 'EnhancedAnchorLinks.handleHashChange');
  }

  /**
   * Handle popstate events (back/forward navigation)
   * @private
   */
  handlePopState() {
    this.errorHandler.safeExecute(() => {
      this.debugLog('Popstate navigation detected');

      clearTimeout(this.navigationTimeout);
      this.navigationTimeout = setTimeout(() => {
        this.handleNavigation(window.location.hash, this.previousHash);
        this.previousHash = window.location.hash;
      }, 100);
    }, 'EnhancedAnchorLinks.handlePopState');
  }

  /**
   * Discover anchor links in the current document
   * @returns {Array} Array of anchor elements
   */
  discoverAnchorLinks() {
    return this.errorHandler.safeExecute(() => {
      const anchors = Array.from(document.querySelectorAll('a[href^="#"]'));
      this.debugLog(`Discovered ${anchors.length} anchor links`);
      return anchors;
    }, 'EnhancedAnchorLinks.discoverAnchorLinks') || [];
  }

  /**
   * Smooth scroll to target element
   * @param {Element|string} target - Target element or selector
   * @param {Object} options - Scroll options
   */
  smoothScrollToTarget(target, options = {}) {
    return this.errorHandler.safeExecute(() => {
      const element = typeof target === 'string' ? document.querySelector(target) : target;
      if (!element) {
        this.debugLog(`Target not found for smooth scroll: ${target}`);
        return false;
      }

      const scrollOptions = {
        behavior: 'smooth',
        block: 'start',
        inline: 'nearest',
        ...options
      };

      element.scrollIntoView(scrollOptions);
      this.debugLog(`Smooth scrolled to target: ${element.tagName}#${element.id || 'unnamed'}`);
      return true;
    }, 'EnhancedAnchorLinks.smoothScrollToTarget') || false;
  }

  /**
   * Find anchor element by ID or name
   * @param {string} anchorId - Anchor identifier
   * @returns {Element|null} Found element
   */
  findAnchorElement(anchorId) {
    return this.errorHandler.safeExecute(() => {
      if (!anchorId) {return null;}

      // Try ID first
      let element = document.getElementById(anchorId);
      if (element) {return element;}

      // Try name attribute
      element = document.querySelector(`[name="${anchorId}"]`);
      if (element) {return element;}

      // Try data-id attribute
      element = document.querySelector(`[data-id="${anchorId}"]`);

      this.debugLog(`Found anchor element for "${anchorId}": ${element ? 'yes' : 'no'}`);
      return element;
    }, 'EnhancedAnchorLinks.findAnchorElement') || null;
  }

  /**
   * Update document title based on anchor
   * @param {string} anchorId - Anchor identifier
   * @param {string} title - New title
   */
  updateDocumentTitle(anchorId, title) {
    this.errorHandler.safeExecute(() => {
      if (!title) {return;}

      const originalTitle = document.title;
      const newTitle = `${title} - ${originalTitle.replace(/ - .*$/, '')}`;

      if (document.title !== newTitle) {
        document.title = newTitle;
        this.debugLog(`Updated document title to: ${newTitle}`);
      }
    }, 'EnhancedAnchorLinks.updateDocumentTitle');
  }

  /**
   * Apply highlighting to target element
   * @param {Element} element - Element to highlight
   * @param {Object} options - Highlighting options
   */
  applyHighlighting(element, options = {}) {
    this.errorHandler.safeExecute(() => {
      if (!element) {return;}

      const className = options.className || 'enhanced-anchor-highlight';
      element.classList.add(className);

      if (options.duration) {
        setTimeout(() => {
          this.removeHighlighting(element, options);
        }, options.duration);
      }

      this.debugLog(`Applied highlighting to element: ${element.tagName}#${element.id || 'unnamed'}`);
    }, 'EnhancedAnchorLinks.applyHighlighting');
  }

  /**
   * Remove highlighting from target element
   * @param {Element} element - Element to remove highlighting from
   * @param {Object} options - Highlighting options
   */
  removeHighlighting(element, options = {}) {
    this.errorHandler.safeExecute(() => {
      if (!element) {return;}

      const className = options.className || 'enhanced-anchor-highlight';
      element.classList.remove(className);

      this.debugLog(`Removed highlighting from element: ${element.tagName}#${element.id || 'unnamed'}`);
    }, 'EnhancedAnchorLinks.removeHighlighting');
  }

  /**
   * Generate table of contents from anchors
   * @param {Object} options - TOC generation options
   * @returns {Object} Generated TOC data
   */
  generateTableOfContents(options = {}) {
    return this.errorHandler.safeExecute(() => {
      const headings = document.querySelectorAll(options.selector || 'h1, h2, h3, h4, h5, h6');
      const toc = [];

      headings.forEach((heading, _index) => {
        if (!heading.id) {
          heading.id = `heading-${_index}`;
        }

        toc.push({
          id: heading.id,
          text: heading.textContent.trim(),
          level: parseInt(heading.tagName.substring(1)),
          element: heading
        });
      });

      this.debugLog(`Generated TOC with ${toc.length} items`);
      return { items: toc, count: toc.length };
    }, 'EnhancedAnchorLinks.generateTableOfContents') || { items: [], count: 0 };
  }

  /**
   * Update table of contents display
   * @param {Object} tocData - TOC data
   * @param {Element} container - Container element
   */
  updateToC(tocData, container) {
    this.errorHandler.safeExecute(() => {
      if (!container || !tocData) {return;}

      container.innerHTML = '';

      tocData.items.forEach(item => {
        const link = document.createElement('a');
        link.href = `#${item.id}`;
        link.textContent = item.text;
        link.className = `toc-level-${item.level}`;

        const listItem = document.createElement('li');
        listItem.appendChild(link);
        container.appendChild(listItem);
      });

      this.debugLog(`Updated TOC with ${tocData.count} items`);
    }, 'EnhancedAnchorLinks.updateToC');
  }

  /**
   * Highlight table of contents item
   * @param {string} anchorId - Active anchor ID
   * @param {Element} tocContainer - TOC container
   */
  highlightToCItem(anchorId, tocContainer) {
    this.errorHandler.safeExecute(() => {
      if (!tocContainer) {return;}

      // Remove previous highlights
      tocContainer.querySelectorAll('.active').forEach(item => {
        item.classList.remove('active');
      });

      // Add highlight to current item
      const activeLink = tocContainer.querySelector(`a[href="#${anchorId}"]`);
      if (activeLink) {
        activeLink.classList.add('active');
        this.debugLog(`Highlighted TOC item: ${anchorId}`);
      }
    }, 'EnhancedAnchorLinks.highlightToCItem');
  }

  /**
   * Validate anchor element
   * @param {string} anchorId - Anchor identifier
   * @returns {Object} Validation result
   */
  validateAnchor(anchorId) {
    return this.errorHandler.safeExecute(() => {
      const element = this.findAnchorElement(anchorId);
      const result = {
        valid: !!element,
        id: anchorId,
        element: element,
        errors: []
      };

      if (!element) {
        result.errors.push(`Anchor element not found: ${anchorId}`);
      }

      this.debugLog(`Validated anchor "${anchorId}": ${result.valid ? 'valid' : 'invalid'}`);
      return result;
    }, 'EnhancedAnchorLinks.validateAnchor') || { valid: false, id: anchorId, element: null, errors: ['Validation failed'] };
  }

  /**
   * Get anchor metrics and analytics
   * @param {string} anchorId - Anchor identifier
   * @returns {Object} Anchor metrics
   */
  getAnchorMetrics(anchorId) {
    return this.errorHandler.safeExecute(() => {
      const element = this.findAnchorElement(anchorId);
      if (!element) {return null;}

      const rect = element.getBoundingClientRect();
      const metrics = {
        id: anchorId,
        visible: rect.top >= 0 && rect.bottom <= window.innerHeight,
        position: {
          top: rect.top,
          left: rect.left,
          width: rect.width,
          height: rect.height
        },
        inViewport: rect.top < window.innerHeight && rect.bottom > 0
      };

      this.debugLog(`Retrieved metrics for anchor "${anchorId}"`);
      return metrics;
    }, 'EnhancedAnchorLinks.getAnchorMetrics') || null;
  }

  /**
   * Generate anchor report
   * @param {Object} options - Report options
   * @returns {Object} Anchor report
   */
  generateAnchorReport(_options = {}) {
    return this.errorHandler.safeExecute(() => {
      const anchors = this.discoverAnchorLinks();
      const report = {
        totalAnchors: anchors.length,
        validAnchors: 0,
        invalidAnchors: 0,
        details: []
      };

      anchors.forEach(anchor => {
        const href = anchor.getAttribute('href');
        if (href && href.startsWith('#')) {
          const anchorId = href.substring(1);
          const validation = this.validateAnchor(anchorId);

          if (validation.valid) {
            report.validAnchors++;
          } else {
            report.invalidAnchors++;
          }

          report.details.push(validation);
        }
      });

      this.debugLog(`Generated anchor report: ${report.validAnchors} valid, ${report.invalidAnchors} invalid`);
      return report;
    }, 'EnhancedAnchorLinks.generateAnchorReport') || { totalAnchors: 0, validAnchors: 0, invalidAnchors: 0, details: [] };
  }

  /**
   * Enable keyboard navigation for anchors
   * @param {Object} options - Keyboard navigation options
   */
  enableKeyboardNavigation(options = {}) {
    this.errorHandler.safeExecute(() => {
      const keyHandler = (event) => {
        if (options.keys && !options.keys.includes(event.key)) {return;}

        // Default: Arrow keys for navigation
        if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
          const anchors = this.discoverAnchorLinks();
          const currentIndex = anchors.findIndex(a => a.getAttribute('href') === window.location.hash);

          let nextIndex;
          if (event.key === 'ArrowDown') {
            nextIndex = (currentIndex + 1) % anchors.length;
          } else {
            nextIndex = currentIndex > 0 ? currentIndex - 1 : anchors.length - 1;
          }

          if (anchors[nextIndex]) {
            const href = anchors[nextIndex].getAttribute('href');
            if (href) {
              window.location.hash = href;
              event.preventDefault();
            }
          }
        }
      };

      document.addEventListener('keydown', keyHandler);
      this.keyboardHandler = keyHandler; // Store for cleanup

      this.debugLog('Enabled keyboard navigation for anchors');
    }, 'EnhancedAnchorLinks.enableKeyboardNavigation');
  }

  /**
   * Activate anchor element
   * @param {string} anchorId - Anchor identifier
   * @param {Object} options - Activation options
   */
  activateAnchor(anchorId, options = {}) {
    this.errorHandler.safeExecute(() => {
      const element = this.findAnchorElement(anchorId);
      if (!element) {return false;}

      // Apply activation styling
      element.classList.add('anchor-active');

      // Scroll if requested
      if (options.scroll !== false) {
        this.smoothScrollToTarget(element, options.scrollOptions);
      }

      // Update title if provided
      if (options.title) {
        this.updateDocumentTitle(anchorId, options.title);
      }

      // Apply highlighting
      if (options.highlight !== false) {
        this.applyHighlighting(element, options.highlightOptions);
      }

      this.debugLog(`Activated anchor: ${anchorId}`);
      return true;
    }, 'EnhancedAnchorLinks.activateAnchor') || false;
  }

  /**
   * Deactivate anchor element
   * @param {string} anchorId - Anchor identifier
   * @param {Object} options - Deactivation options
   */
  deactivateAnchor(anchorId, options = {}) {
    this.errorHandler.safeExecute(() => {
      const element = this.findAnchorElement(anchorId);
      if (!element) {return false;}

      // Remove activation styling
      element.classList.remove('anchor-active');

      // Remove highlighting
      this.removeHighlighting(element, options.highlightOptions);

      this.debugLog(`Deactivated anchor: ${anchorId}`);
      return true;
    }, 'EnhancedAnchorLinks.deactivateAnchor') || false;
  }

  /**
   * Perform scroll animation
   * @param {Element} target - Target element
   * @param {Object} options - Animation options
   */
  performScrollAnimation(target, options = {}) {
    return this.errorHandler.safeExecute(() => {
      if (!target) {return false;}

      const startTime = performance.now();
      const startScrollTop = window.pageYOffset;
      const targetScrollTop = target.offsetTop - (options.offset || 0);
      const distance = targetScrollTop - startScrollTop;
      const duration = options.duration || 500;

      const easeInOutQuad = (t) => t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;

      const animate = (currentTime) => {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        const easedProgress = easeInOutQuad(progress);

        window.scrollTo(0, startScrollTop + distance * easedProgress);

        if (progress < 1) {
          requestAnimationFrame(animate);
        } else if (options.callback) {
          options.callback();
        }
      };

      requestAnimationFrame(animate);
      this.debugLog(`Started scroll animation to target`);
      return true;
    }, 'EnhancedAnchorLinks.performScrollAnimation') || false;
  }

  /**
   * Handle intersection changes for anchor visibility
   * @param {Array} entries - Intersection observer entries
   */
  handleIntersectionChange(entries) {
    this.errorHandler.safeExecute(() => {
      entries.forEach(entry => {
        const target = entry.target;
        const anchorId = target.id;

        if (entry.isIntersecting) {
          this.debugLog(`Anchor in view: ${anchorId}`);
          // Update URL hash if configured
          if (this.config.updateHash) {
            window.history.replaceState(null, null, `#${anchorId}`);
          }
        }
      });
    }, 'EnhancedAnchorLinks.handleIntersectionChange');
  }

  /**
   * Bind scroll events for anchor tracking
   */
  bindScrollEvents() {
    this.errorHandler.safeExecute(() => {
      if (this.scrollHandler) {return;} // Already bound

      this.scrollHandler = throttle(() => {
        const _scrollTop = window.pageYOffset;
        const anchors = this.discoverAnchorLinks();

        // Find visible anchor
        let activeAnchor = null;
        anchors.forEach(anchor => {
          const href = anchor.getAttribute('href');
          if (href && href.startsWith('#')) {
            const element = this.findAnchorElement(href.substring(1));
            if (element) {
              const rect = element.getBoundingClientRect();
              if (rect.top <= 100 && rect.bottom > 0) {
                activeAnchor = href.substring(1);
              }
            }
          }
        });

        if (activeAnchor && activeAnchor !== this.activeAnchor) {
          this.activeAnchor = activeAnchor;
          this.debugLog(`Active anchor changed to: ${activeAnchor}`);
        }
      }, 100);

      window.addEventListener('scroll', this.scrollHandler);
      this.debugLog('Bound scroll events for anchor tracking');
    }, 'EnhancedAnchorLinks.bindScrollEvents');
  }

  /**
   * Unbind scroll events
   */
  unbindScrollEvents() {
    this.errorHandler.safeExecute(() => {
      if (this.scrollHandler) {
        window.removeEventListener('scroll', this.scrollHandler);
        this.scrollHandler = null;
        this.debugLog('Unbound scroll events');
      }
    }, 'EnhancedAnchorLinks.unbindScrollEvents');
  }

  /**
   * Handle navigation based on hash changes
   * @param {string} currentHash - Current hash
   * @param {string} previousHash - Previous hash
   * @private
   */
  handleNavigation(currentHash, previousHash) {
    this.errorHandler.safeExecute(() => {
      const navigation = this.determineNavigationType(currentHash, previousHash);
      this.debugLog('Navigation type determined:', navigation);

      // Emit coordination event for other plugins
      this.emitNavigationEvent(navigation, currentHash, previousHash);

      if (navigation.shouldScrollToTop) {
        this.autoScrollToTop();
      } else if (navigation.type === 'anchor' && navigation.anchor) {
        this.scrollToAnchorWithRetry(navigation.anchor);
      }
    }, 'EnhancedAnchorLinks.handleNavigation');
  }

  /**
   * Handle initial hash on page load
   * @private
   */
  handleInitialHash() {
    this.errorHandler.safeExecute(() => {
      const currentHash = window.location.hash;
      if (!currentHash) {return;}

      this.debugLog('Processing initial hash:', currentHash);

      const navigation = this.determineNavigationType(currentHash, null);
      if (navigation.type === 'anchor' && navigation.anchor) {
        // Delay to ensure content is loaded
        setTimeout(() => {
          this.scrollToAnchorWithRetry(navigation.anchor);
        }, 600);
      }
    }, 'EnhancedAnchorLinks.handleInitialHash');
  }

  /**
   * Determine navigation type from hash changes
   * @param {string} currentHash - Current hash
   * @param {string} previousHash - Previous hash
   * @returns {Object} Navigation information
   * @private
   */
  determineNavigationType(currentHash, previousHash) {
    const current = currentHash ? currentHash.substring(1) : '';
    const previous = previousHash ? previousHash.substring(1) : '';

    // Extract page paths from hashes
    const currentPage = current.startsWith('/') ? current.split('?')[0] : '';
    const previousPage = previous.startsWith('/') ? previous.split('?')[0] : '';

    // Determine navigation type
    if (!previous || previousPage !== currentPage) {
      return {
        type: 'article',
        shouldScrollToTop: true,
        page: currentPage,
        anchor: null
      };
    }

    // Same page - check for anchor
    if (!current.startsWith('/')) {
      return {
        type: 'anchor',
        shouldScrollToTop: false,
        page: currentPage,
        anchor: current
      };
    }

    // Check for anchor within page URL (e.g., #/docs/page?id=section)
    const anchorMatch = current.match(/[?&]id=([^&]+)/);
    if (anchorMatch) {
      return {
        type: 'anchor',
        shouldScrollToTop: false,
        page: currentPage,
        anchor: decodeURIComponent(anchorMatch[1])
      };
    }

    return {
      type: 'refresh',
      shouldScrollToTop: true,
      page: currentPage,
      anchor: null
    };
  }

  /**
   * Find target element for an anchor
   * @param {string} anchor - Anchor ID to find
   * @param {boolean} isTOCClick - Whether this is from TOC navigation
   * @returns {HTMLElement|null} Target element
   * @private
   */
  findTargetElement(anchor, isTOCClick = false) {
    this.debugLog('Finding target element for:', anchor, isTOCClick ? '(TOC)' : '');

    // Try direct ID match first
    let target = document.getElementById(anchor);
    if (target) {
      this.debugLog('Found target by ID');
      return target;
    }

    // Try URL decoding variations
    try {
      const decodedAnchor = decodeURIComponent(anchor);
      target = document.getElementById(decodedAnchor);
      if (target) {
        this.debugLog('Found target by decoded ID');
        return target;
      }
    } catch {
      // Continue with other methods if decoding fails
    }

    // Try name attribute variations
    target = document.querySelector(`[name="${anchor}"]`) ||
             document.querySelector(`a[name="${anchor}"]`);
    if (target) {
      this.debugLog('Found target by name attribute');
      return target;
    }

    // Try text-based matching for headers
    return this.findTargetByTextMatching(anchor);
  }

  /**
   * Find target element by text matching
   * @param {string} anchor - Anchor ID to find
   * @returns {HTMLElement|null} Target element
   * @private
   */
  findTargetByTextMatching(anchor) {
    const selectors = [
      '.markdown-section h1, .markdown-section h2, .markdown-section h3, .markdown-section h4, .markdown-section h5, .markdown-section h6',
      '#main h1, #main h2, #main h3, #main h4, #main h5, #main h6',
      '.content h1, .content h2, .content h3, .content h4, .content h5, .content h6',
      'article h1, article h2, article h3, article h4, article h5, article h6',
      'h1, h2, h3, h4, h5, h6'
    ];

    for (const selector of selectors) {
      const headers = document.querySelectorAll(selector);
      this.debugLog(`Checking ${headers.length} headers with selector: ${selector}`);

      for (const header of headers) {
        // Check if header already has the matching ID
        if (header.id === anchor) {
          this.debugLog('Found target by existing ID:', header.textContent.trim());
          return header;
        }

        // Generate potential anchor from header text
        const headerText = header.textContent.trim();
        const generatedAnchor = this.generateDocsifyAnchor(headerText);

        if (generatedAnchor === anchor ||
            encodeURIComponent(generatedAnchor) === anchor ||
            generatedAnchor === decodeURIComponent(anchor)) {
          this.debugLog('Found target by text matching:', headerText, '->', generatedAnchor);
          return header;
        }
      }
    }

    this.debugLog('Target not found with any method');
    return null;
  }

  /**
   * Generate anchor ID the way Docsify does it
   * @param {string} text - Header text
   * @returns {string} Generated anchor ID
   * @private
   */
  generateDocsifyAnchor(text) {
    return text
      .toLowerCase()
      .replace(/[^\w\s-]/g, '') // Remove special characters except spaces and hyphens
      .replace(/\s+/g, '-') // Replace spaces with hyphens
      .replace(/-+/g, '-') // Collapse multiple hyphens
      .replace(/^-|-$/g, ''); // Remove leading/trailing hyphens
  }

  /**
   * Scroll to anchor with retry logic
   * @param {string} anchor - Anchor to scroll to
   * @private
   */
  scrollToAnchorWithRetry(anchor) {
    this.errorHandler.safeExecute(() => {
      this.debugLog('Starting anchor scroll with retry for:', anchor);

      const tryScrollToAnchor = (attempt = 1) => {
        this.debugLog(`Attempt ${attempt}/${this.config.retryAttempts} for anchor:`, anchor);

        // Check if content is loaded
        const contentLoaded = this.checkContentLoaded();
        if (!contentLoaded && attempt <= 8) {
          this.debugLog(`Content not fully loaded on attempt ${attempt}, waiting...`);
          setTimeout(() => tryScrollToAnchor(attempt + 1), 400 * attempt);
          return;
        }

        // Find target element
        const target = this.findTargetElement(anchor);
        if (target) {
          this.debugLog(`Found target on attempt ${attempt}:`, target);
          this.smoothScrollToElement(target);
          this.highlightTarget(target);
          return;
        }

        // Debug available elements
        if (attempt === 1 || attempt === 4 || attempt === 8) {
          this.debugAvailableElements();
        }

        if (attempt < this.config.retryAttempts) {
          this.debugLog(`Target not found on attempt ${attempt}, retrying...`);
          setTimeout(() => tryScrollToAnchor(attempt + 1), 200 + (100 * attempt));
        } else {
          this.debugLog('Target not found after all attempts:', anchor);
        }
      };

      setTimeout(() => tryScrollToAnchor(), 600);
    }, 'EnhancedAnchorLinks.scrollToAnchorWithRetry');
  }

  /**
   * Check if content is fully loaded
   * @returns {boolean} Whether content is loaded
   * @private
   */
  checkContentLoaded() {
    const contentArea = document.querySelector('.markdown-section') ||
                       document.querySelector('#main') ||
                       document.querySelector('.content');

    if (!contentArea) {
      this.debugLog('Content area not found');
      return false;
    }

    const hasContent = contentArea.textContent.length > 100;
    const hasHeaders = document.querySelectorAll('h1, h2, h3, h4, h5, h6').length > 0;
    const isLoading = document.querySelector('.loading') ||
                     contentArea.textContent.includes('Loading') ||
                     contentArea.innerHTML.includes('loading');

    const isLoaded = hasContent && hasHeaders && !isLoading;

    this.debugLog('Content loading check:', {
      hasContent,
      hasHeaders,
      isLoading: !!isLoading,
      isLoaded
    });

    return isLoaded;
  }

  /**
   * Debug available elements in the document
   * @private
   */
  debugAvailableElements() {
    if (!this.config.debug) {return;}

    this.debugLog('Available IDs in document:');
    const allIds = Array.from(document.querySelectorAll('[id]')).map(el => el.id);
    this.debugLog('Available IDs:', allIds);

    this.debugLog('Available headers:');
    const headers = Array.from(document.querySelectorAll('h1, h2, h3, h4, h5, h6'));
    headers.forEach(h => {
      this.debugLog(`  - "${h.textContent.trim()}" (id: "${h.id || 'none'}")`);
    });
  }

  /**
   * Smooth scroll to element with offset
   * @param {HTMLElement} target - Target element
   * @param {number} offset - Scroll offset (optional)
   */
  smoothScrollToElement(target, offset = this.config.scrollOffset) {
    this.errorHandler.safeExecute(() => {
      if (!target) {return;}

      const targetPosition = target.getBoundingClientRect().top + window.pageYOffset - offset;

      window.scrollTo({
        top: targetPosition,
        behavior: 'smooth'
      });

      this.debugLog('Scrolled to element:', target);
    }, 'EnhancedAnchorLinks.smoothScrollToElement');
  }

  /**
   * Auto-scroll to top of page using dedicated AutoScrollTop class
   * @returns {Promise<boolean>} Promise resolving to success status
   */
  async autoScrollToTop() {
    return this.errorHandler.safeExecute(async () => {
      this.debugLog('=== Auto-scroll to top (using AutoScrollTop class) ===');

      let scrollSuccess = false;

      // Primary method: Use AutoScrollTop instance if available
      if (this.autoScrollTop && this.autoScrollTop.isEnabled()) {
        this.debugLog('Using AutoScrollTop instance');
        scrollSuccess = await this.autoScrollTop.scrollToTop();
      } else {
        this.debugLog('AutoScrollTop not available or disabled, using fallback methods');
      }

      // Fallback methods if AutoScrollTop fails or isn't available
      if (!scrollSuccess) {
        scrollSuccess = this.performDirectScrollToTop();
      }

      this.debugLog('Auto-scroll to top completed:', scrollSuccess ? 'success' : 'failed');
      return scrollSuccess;
    }, 'EnhancedAnchorLinks.autoScrollToTop');
  }

  /**
   * Perform direct scroll to top using multiple methods as fallback
   * @returns {boolean} Success status
   * @private
   */
  performDirectScrollToTop() {
    this.debugLog('Executing direct scroll to top fallback methods');

    let successCount = 0;

    // Method 1: Standard window.scrollTo
    try {
      if (window && typeof window.scrollTo === 'function') {
        window.scrollTo({
          top: 0,
          left: 0,
          behavior: 'auto'
        });
        successCount++;
        this.debugLog('Window scrollTo succeeded');
      }
    } catch (_error) {
      this.debugLog('Window scrollTo failed:', _error.message);
    }

    // Method 2: Direct property assignment
    try {
      if (window) {
        window.scrollY = 0;
        window.pageYOffset = 0;
        successCount++;
        this.debugLog('Direct property assignment succeeded');
      }
    } catch (_error) {
      this.debugLog('Direct property assignment failed:', _error.message);
    }

    // Method 3: Document element scroll
    try {
      if (document && document.documentElement) {
        document.documentElement.scrollTop = 0;
        document.documentElement.scrollLeft = 0;
        successCount++;
        this.debugLog('Document element scroll succeeded');
      }
    } catch (_error) {
      this.debugLog('Document element scroll failed:', _error.message);
    }

    // Method 4: Body element scroll
    try {
      if (document && document.body) {
        document.body.scrollTop = 0;
        document.body.scrollLeft = 0;
        successCount++;
        this.debugLog('Body element scroll succeeded');
      }
    } catch (_error) {
      this.debugLog('Body element scroll failed:', _error.message);
    }

    // Method 5: Container-specific scrolling
    const containerSelectors = [
      '.content',
      '.markdown-section',
      '#main',
      '.app',
      '#app'
    ];

    containerSelectors.forEach(selector => {
      try {
        const elements = document.querySelectorAll(selector);
        elements.forEach(element => {
          if (element && typeof element.scrollTo === 'function') {
            element.scrollTo(0, 0);
            successCount++;
            this.debugLog(`Container scroll succeeded for ${selector}`);
          } else if (element) {
            element.scrollTop = 0;
            element.scrollLeft = 0;
            successCount++;
            this.debugLog(`Container property scroll succeeded for ${selector}`);
          }
        });
      } catch (_error) {
        this.debugLog(`Container scroll failed for ${selector}:`, _error.message);
      }
    });

    const success = successCount > 0;
    this.debugLog(`Direct scroll to top completed with ${successCount} successful methods:`, success);
    return success;
  }

  /**
   * Highlight target element with visual feedback
   * @param {HTMLElement} target - Target element to highlight
   * @private
   */
  highlightTarget(target) {
    this.errorHandler.safeExecute(() => {
      if (!target) {return;}

      target.classList.add('anchor-highlight');

      setTimeout(() => {
        target.classList.remove('anchor-highlight');
      }, 2000);

      this.debugLog('Target highlighted:', target);
    }, 'EnhancedAnchorLinks.highlightTarget');
  }

  /**
   * Make header links more clickable
   * @private
   */
  enhanceHeaderLinks() {
    this.errorHandler.safeExecute(() => {
      const headers = document.querySelectorAll('.markdown-section h1, .markdown-section h2, .markdown-section h3, .markdown-section h4, .markdown-section h5, .markdown-section h6');

      headers.forEach(header => {
        if (!header.id) {return;}

        header.setAttribute('title', `Link to ${header.textContent.trim()}`);

        // Remove existing click handler to prevent duplicates
        const newHeader = header.cloneNode(true);
        header.parentNode.replaceChild(newHeader, header);

        // Add click handler to new header
        newHeader.addEventListener('click', (event) => {
          if (!event.target.closest('a')) {
            event.preventDefault();
            this.updateURL(newHeader.id);
            this.smoothScrollToElement(newHeader);
            this.highlightTarget(newHeader);
          }
        });
      });

      this.debugLog('Header links enhanced');
    }, 'EnhancedAnchorLinks.enhanceHeaderLinks');
  }

  /**
   * Setup TOC click handlers
   * @private
   */
  setupTOCClickHandlers() {
    this.errorHandler.safeExecute(() => {
      // Check if document is available (test environment compatibility)
      if (typeof document === 'undefined') {
        this.debugLog('Document not available, skipping TOC setup');
        return;
      }

      const tocContainer = document.querySelector('.page_toc');

      if (!tocContainer) {
        // TOC not ready, retry later
        setTimeout(() => this.setupTOCClickHandlers(), 500);
        return;
      }

      this.debugLog('Setting up TOC container click handlers');

      // Setup mutation observer for dynamic TOC content
      if (window.MutationObserver && !this.mutationObserver) {
        this.mutationObserver = new MutationObserver((mutations) => {
          mutations.forEach((mutation) => {
            if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
              this.debugLog('TOC content changed, updating handlers');
              setTimeout(() => this.setupTOCClickHandlers(), 100);
            }
          });
        });

        this.mutationObserver.observe(tocContainer, {
          childList: true,
          subtree: true
        });
      }
    }, 'EnhancedAnchorLinks.setupTOCClickHandlers');
  }

  /**
   * Update URL without triggering navigation
   * @param {string} anchor - Anchor ID
   * @private
   */
  updateURL(anchor) {
    this.errorHandler.safeExecute(() => {
      const currentHash = window.location.hash;
      let newHash;

      // If current URL has Docsify route (?id= pattern), preserve it
      if (currentHash.includes('?id=')) {
        const basePath = currentHash.split('?id=')[0];
        newHash = `${basePath}?id=${anchor}`;
      } else if (currentHash.startsWith('#/')) {
        // Current is a route, add anchor to it
        newHash = `${currentHash}?id=${anchor}`;
      } else {
        // Simple anchor format
        newHash = `#${anchor}`;
      }

      if (history.pushState) {
        history.pushState(null, null, newHash);
      } else {
        window.location.hash = newHash;
      }
    }, 'EnhancedAnchorLinks.updateURL');
  }

  /**
   * Emit navigation event for coordination with other plugins
   * @param {Object} navigation - Navigation information
   * @param {string} currentHash - Current hash
   * @param {string} previousHash - Previous hash
   * @private
   */
  emitNavigationEvent(navigation, currentHash, previousHash) {
    this.errorHandler.safeExecute(() => {
      if (window.sidebarCollapseSimple && window.sidebarCollapseSimple.emitNavigationEvent) {
        window.sidebarCollapseSimple.emitNavigationEvent('navigation-detected', {
          type: navigation.type,
          shouldScrollToTop: navigation.shouldScrollToTop,
          anchor: navigation.anchor,
          currentHash,
          previousHash
        });
      }
    }, 'EnhancedAnchorLinks.emitNavigationEvent');
  }

  /**
   * Debug logging helper
   * @param {...any} _args - Arguments to log
   * @private
   */
  debugLog(..._args) {
    if (this.config.debug) {
      logger.log('[EnhancedAnchorLinks]', ..._args);
    }
  }

  /**
   * Detect and handle navigation edge cases
   * @private
   */
  detectNavigationEdgeCases() {
    this.errorHandler.safeExecute(() => {
      this.debugLog('=== Navigation Edge Case Detection ===');

      // Edge Case 1: Detect if user is navigating from a different domain/page
      const referrer = document.referrer;
      const isExternalNavigation = referrer && !referrer.includes(window.location.hostname);

      // Edge Case 2: Detect if this is a browser back/forward navigation
      const isHistoryNavigation = window.performance &&
        window.performance.getEntriesByType &&
        window.performance.getEntriesByType('navigation')[0] &&
        window.performance.getEntriesByType('navigation')[0].type === 'back_forward';

      // Edge Case 3: Detect if page was refreshed
      const isPageRefresh = window.performance &&
        window.performance.getEntriesByType &&
        window.performance.getEntriesByType('navigation')[0] &&
        window.performance.getEntriesByType('navigation')[0].type === 'reload';

      // Edge Case 4: Detect if content height changed significantly (dynamic content)
      const currentContentHeight = document.documentElement.scrollHeight;
      const hasSignificantHeightChange = this.lastContentHeight &&
        Math.abs(currentContentHeight - this.lastContentHeight) > window.innerHeight;

      this.debugLog('Edge case analysis:', {
        isExternalNavigation,
        isHistoryNavigation,
        isPageRefresh,
        hasSignificantHeightChange,
        referrer,
        currentContentHeight,
        lastContentHeight: this.lastContentHeight
      });

      // Store current height for next comparison
      this.lastContentHeight = currentContentHeight;

      // Trigger additional scroll behavior for edge cases
      if (isExternalNavigation || isHistoryNavigation || isPageRefresh || hasSignificantHeightChange) {
        this.debugLog('Edge case detected - triggering additional scroll behavior');

        // Wait for content to stabilize, then force scroll
        setTimeout(() => {
          const currentScroll = window.pageYOffset || document.documentElement.scrollTop;
          if (currentScroll > 50) {
            this.debugLog('Edge case: Content not at top, forcing scroll');
            this.autoScrollToTop();
          }
        }, 250);

        // Additional long-term verification for edge cases
        setTimeout(() => {
          const finalScroll = window.pageYOffset || document.documentElement.scrollTop;
          if (finalScroll > 10) {
            this.debugLog('Edge case: Long-term verification failed, final force scroll');
            window.scrollTo(0, 0);
            document.documentElement.scrollTop = 0;
            document.body.scrollTop = 0;
          }
        }, 800);
      }
    }, 'EnhancedAnchorLinks.detectNavigationEdgeCases');
  }

  /**
   * Install as Docsify plugin with enhanced lifecycle hooks integration
   * @param {Function} hook - Docsify hook function
   * @param {Object} vm - Docsify VM
   */
  installDocsifyPlugin(hook, vm) {
    this.debugLog('Installing enhanced Docsify plugin with lifecycle hooks');

    let previousRoute = '';
    let contentRendered = false;
    let initialLoadComplete = false;

    // Initialize when Docsify is ready
    hook.ready(() => {
      this.debugLog('Docsify ready - initializing enhanced anchor links');
      this.initialize();
      previousRoute = vm.route.path || '';
      this.debugLog('Initial route set to:', `"${previousRoute}"`);
    });

    // Handle content preparation phase
    hook.beforeEach((content, next) => {
      this.debugLog('=== beforeEach: Content Preparation ===');
      this.docsifyContentLoading = true;
      contentRendered = false;

      // Reset anchor handling state for new content
      this.anchorHandlingInProgress = false;

      this.debugLog('Content loading started');
      next(content);
    });

    // Handle content processing phase
    hook.afterEach((html, next) => {
      this.debugLog('=== afterEach: Content Processing ===');
      this.docsifyContentLoading = false;
      contentRendered = true;

      this.debugLog('HTML content processed, content will be rendered soon');
      next(html);
    });

    // Handle content rendering completion - MAIN INTEGRATION POINT
    hook.doneEach(() => {
      this.debugLog('=== doneEach: Content Rendering Complete ===');

      const currentRoute = vm.route.path;
      const normalizedPrevious = previousRoute || '';
      const normalizedCurrent = currentRoute || '';
      const routeChanged = normalizedPrevious !== normalizedCurrent && normalizedCurrent !== '';
      const currentHash = window.location.hash;

      this.debugLog('Route detection:', {
        previous: `"${normalizedPrevious}"`,
        current: `"${normalizedCurrent}"`,
        changed: routeChanged,
        hash: currentHash,
        contentRendered,
        initialLoadComplete
      });

      // Set flag to prevent duplicate handling
      this.anchorHandlingInProgress = true;

      // Wait for DOM to settle after content rendering
      this.waitForContentStabilization().then(() => {
        this.debugLog('Content stabilized - processing navigation');

        // Always enhance links and TOC after content rendering
        this.enhanceHeaderLinks();
        this.setupTOCClickHandlers();

        // Handle navigation based on route change and hash
        this.processNavigationAfterRender(routeChanged, currentHash, normalizedPrevious, initialLoadComplete);

        // Update state
        previousRoute = normalizedCurrent;
        if (!initialLoadComplete) {
          initialLoadComplete = true;
          this.debugLog('Initial load complete');
        }

        // Clear anchor handling flag after processing
        setTimeout(() => {
          this.anchorHandlingInProgress = false;
          this.debugLog('Navigation processing complete, ready for new interactions');
        }, 200);
      });
    });

    // Handle initial mount
    hook.mounted(() => {
      this.debugLog('=== mounted: Docsify Initial Mount ===');
      initialLoadComplete = false;
      this.debugLog('Docsify mounted, waiting for first content render');
    });
  }

  /**
   * Wait for content to stabilize after rendering
   * @returns {Promise<void>} Resolves when content is stable
   * @private
   */
  async waitForContentStabilization() {
    return new Promise((resolve) => {
      // Multiple checks to ensure content is fully rendered and stable
      let stabilityChecks = 0;
      const maxChecks = 3;
      let lastContentHeight = 0;

      const checkStability = () => {
        const currentHeight = document.documentElement.scrollHeight;
        const contentArea = document.querySelector('.markdown-section') ||
                           document.querySelector('#main') ||
                           document.querySelector('.content');

        const hasContent = contentArea && contentArea.textContent.length > 50;
        const heightStable = currentHeight === lastContentHeight;

        this.debugLog(`Stability check ${stabilityChecks + 1}/${maxChecks}:`, {
          currentHeight,
          lastHeight: lastContentHeight,
          heightStable,
          hasContent: !!hasContent,
          contentLength: contentArea ? contentArea.textContent.length : 0
        });

        if (heightStable && hasContent && stabilityChecks > 0) {
          this.debugLog('Content stabilized');
          resolve();
          return;
        }

        lastContentHeight = currentHeight;
        stabilityChecks++;

        if (stabilityChecks >= maxChecks) {
          this.debugLog('Max stability checks reached, proceeding');
          resolve();
          return;
        }

        // Progressive delay: 50ms, 100ms, 150ms
        setTimeout(checkStability, 50 + (stabilityChecks * 50));
      };

      // Start stability checking
      setTimeout(checkStability, 50);
    });
  }

  /**
   * Process navigation after content rendering is complete
   * @param {boolean} routeChanged - Whether the route changed
   * @param {string} currentHash - Current URL hash
   * @param {string} previousRoute - Previous route
   * @param {boolean} initialLoadComplete - Whether initial load is complete
   * @private
   */
  processNavigationAfterRender(routeChanged, currentHash, previousRoute, initialLoadComplete) {
    this.debugLog('=== Processing Navigation After Render ===');

    // Handle route changes (new page loads)
    if (routeChanged) {
      this.debugLog('Route changed - new page loaded');

      if (currentHash && currentHash.includes('?id=')) {
        this.debugLog('New page with anchor - handling anchor navigation');
        this.handleNavigation(currentHash, previousRoute ? `#${previousRoute}` : null);
      } else {
        // New page without anchor - scroll to top
        const docsifyConfig = window.$docsify || {};
        this.debugLog('New page without anchor - using enhanced scroll to top');
        this.debugLog('Docsify auto2top setting:', docsifyConfig.auto2top, '(overriding with enhanced implementation)');

        // Always use our enhanced scroll-to-top for reliability
        // Use reliable timing for scroll-to-top after content render
        this.scheduleScrollToTop('route-change');
      }
    } else {
      // Same route - check for anchor navigation or hash changes
      this.debugLog('Same route - checking for anchor navigation');

      if (currentHash && currentHash.includes('?id=')) {
        this.debugLog('Anchor detected in same route - handling navigation');
        this.handleNavigation(currentHash, null);
      } else if (!initialLoadComplete && (!currentHash || currentHash.startsWith('#/'))) {
        // Initial load of page without anchor
        this.debugLog('Initial page load without anchor - ensuring scroll to top');
        this.scheduleScrollToTop('initial-load');
      }
    }

    // Always run edge case detection for robust scroll behavior
    this.detectNavigationEdgeCases();
  }

  /**
   * Schedule scroll to top with proper timing and fallbacks
   * @param {string} reason - Reason for scrolling (for debugging)
   * @private
   */
  scheduleScrollToTop(reason) {
    this.debugLog(`Scheduling scroll to top (${reason})`);

    // Immediate scroll attempt (often gets overridden by Docsify)
    setTimeout(async () => {
      this.debugLog(`Executing immediate scroll to top (${reason})`);
      try {
        await this.autoScrollToTop();
        this.debugLog(`Immediate scroll completed (${reason})`);
      } catch (_error) {
        this.debugLog(`Immediate scroll failed (${reason}):`, _error);
      }
    }, 50);

    // Early fallback for quick content loads
    setTimeout(async () => {
      const currentScroll = window.pageYOffset || document.documentElement.scrollTop;
      if (currentScroll > 10) {
        this.debugLog(`Early fallback scroll needed (${reason}) - current scroll: ${currentScroll}`);
        try {
          await this.autoScrollToTop();
          this.debugLog(`Early fallback scroll completed (${reason})`);
        } catch (_error) {
          this.debugLog(`Early fallback scroll failed (${reason}):`, _error);
        }
      } else {
        this.debugLog(`Early fallback not needed (${reason}) - already at top`);
      }
    }, 200);

    // Main verification and fix (after Docsify content rendering)
    setTimeout(async () => {
      const mainScroll = window.pageYOffset || document.documentElement.scrollTop;
      if (mainScroll > 10) {
        this.debugLog(`Main verification scroll needed (${reason}) - current scroll: ${mainScroll}`);
        try {
          await this.autoScrollToTop();
          this.debugLog(`Main verification scroll completed (${reason})`);

          // Double-check that it worked
          setTimeout(() => {
            const doubleCheckScroll = window.pageYOffset || document.documentElement.scrollTop;
            if (doubleCheckScroll > 10) {
              this.debugLog(`Double-check failed (${reason}) - forcing direct scroll from ${doubleCheckScroll}`);
              this.performDirectScrollToTop();
            } else {
              this.debugLog(`Double-check passed (${reason}) - page at top`);
            }
          }, 100);

        } catch (_error) {
          this.debugLog(`Main verification scroll failed (${reason}):`, _error);
          this.performDirectScrollToTop();
        }
      } else {
        this.debugLog(`Main verification passed (${reason}) - already at top`);
      }
    }, 500);

    // Final persistent verification (catches late DOM updates)
    setTimeout(() => {
      const finalScroll = window.pageYOffset || document.documentElement.scrollTop;
      if (finalScroll > 10) {
        this.debugLog(`PERSISTENT: Final scroll needed (${reason}) - current scroll: ${finalScroll}`);
        this.performDirectScrollToTop();

        // Ultra-persistent check for stubborn cases
        setTimeout(() => {
          const ultraFinalScroll = window.pageYOffset || document.documentElement.scrollTop;
          if (ultraFinalScroll > 10) {
            this.debugLog(`ULTRA-PERSISTENT: Forcing scroll (${reason}) - Docsify may be overriding scroll position`);
            // Multiple aggressive scroll attempts
            window.scrollTo(0, 0);
            document.documentElement.scrollTop = 0;
            document.body.scrollTop = 0;
            this.performDirectScrollToTop();
          } else {
            this.debugLog(`Ultra-final verification passed (${reason}) - page finally at top`);
          }
        }, 200);
      } else {
        this.debugLog(`Final verification passed (${reason}) - page at top`);
      }
    }, 800);
  }

  /**
   * Clean up resources and event listeners
   */
  destroy() {
    this.errorHandler.safeExecute(() => {
      // Remove event listeners
      document.removeEventListener('click', this.handleAnchorClick);
      window.removeEventListener('hashchange', this.handleHashChange);
      window.removeEventListener('popstate', this.handlePopState);

      // Clear timeouts
      if (this.navigationTimeout) {
        clearTimeout(this.navigationTimeout);
        this.navigationTimeout = null;
      }

      // Disconnect mutation observer
      if (this.mutationObserver) {
        this.mutationObserver.disconnect();
        this.mutationObserver = null;
      }

      // Destroy auto-scroll functionality
      if (this.autoScrollTop) {
        this.autoScrollTop.destroy();
      }

      // Reset state
      this.isInitialized = false;
      this.previousHash = '';

      this.debugLog('Enhanced anchor links destroyed');
    }, 'EnhancedAnchorLinks.destroy');
  }

  /**
   * Normalize route for comparison
   * @param {string} route - Route to normalize
   * @returns {string} Normalized route
   */
  normalizeRoute(route) {
    if (!route) {
      return '';
    }

    // Trim, convert to lowercase, and handle trailing slashes
    let normalized = route.trim().toLowerCase();

    // Remove trailing slash unless it's the root path
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.slice(0, -1);
    }

    return normalized;
  }

  /**
   * Compare two routes for differences
   * @param {string} prev - Previous route
   * @param {string} current - Current route
   * @returns {boolean} True if routes are different
   */
  compareRoutes(prev, current) {
    const normalizedPrev = this.normalizeRoute(prev);
    const normalizedCurrent = this.normalizeRoute(current);
    return normalizedPrev !== normalizedCurrent && normalizedCurrent !== '';
  }
}

/**
 * Throttle utility function
 * @param {Function} func - Function to throttle
 * @param {number} wait - Wait time in milliseconds
 * @returns {Function} Throttled function
 */
function throttle(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

/**
 * Factory function for creating EnhancedAnchorLinks instances
 * @param {Object} config - Configuration options
 * @returns {EnhancedAnchorLinks} New instance
 */
export function createEnhancedAnchorLinks(config = {}) {
  return new EnhancedAnchorLinks(config);
}

/**
 * Docsify plugin factory
 * @param {Object} config - Configuration options
 * @returns {Function} Docsify plugin function
 */
export function createDocsifyPlugin(config = {}) {
  const anchorLinks = new EnhancedAnchorLinks(config);

  return function(hook, vm) {
    anchorLinks.installDocsifyPlugin(hook, vm);
  };
}

// Auto-instantiate and register with docsifyIntegration when module loads
if (typeof window !== 'undefined') {
  // Create instance immediately for registration with docsifyIntegration
  const anchorLinks = new EnhancedAnchorLinks();

  // Register with Docsify integration system first
  if (typeof docsifyIntegration !== 'undefined') {
    anchorLinks.registerWithDocsifyIntegration();
  }

  // Also auto-install as Docsify plugin if available
  if (window.$docsify) {
    if (window.$docsify.plugins) {
      window.$docsify.plugins = [].concat(
        (hook, vm) => anchorLinks.installDocsifyPlugin(hook, vm),
        window.$docsify.plugins
      );
    } else {
      window.$docsify.plugins = [(hook, vm) => anchorLinks.installDocsifyPlugin(hook, vm)];
    }
  } else {
    // If Docsify isn't ready yet, register the plugin when it becomes available
    const checkDocsify = () => {
      if (window.$docsify) {
        if (window.$docsify.plugins) {
          window.$docsify.plugins = [].concat(
            (hook, vm) => anchorLinks.installDocsifyPlugin(hook, vm),
            window.$docsify.plugins
          );
        } else {
          window.$docsify.plugins = [(hook, vm) => anchorLinks.installDocsifyPlugin(hook, vm)];
        }
      } else {
        // Keep checking every 100ms for up to 5 seconds
        setTimeout(checkDocsify, 100);
      }
    };
    setTimeout(checkDocsify, 100);
  }

  // Expose globally for debugging and manual testing
  window.enhancedAnchorLinks = anchorLinks;
}
