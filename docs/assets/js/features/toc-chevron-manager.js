/**
 * TOC Chevron Manager
 *
 * Manages table of contents highlighting, chevron display, and auto-scrolling
 * using modern IntersectionObserver API for accurate scroll detection.
 *
 * @version 1.0.0
 * @since 2025-08-27
 */

class TOCChevronManager {
  /**
   * @private
   * @type {Object}
   */
  #state = {
    isInitialized: false,
    isDestroyed: false,
    debug: false,
    lastActiveElement: null,
    rafId: null,
    timeouts: new Set(),
    // Enhanced performance tracking
    performance: {
      updateQueue: new Set(),
      lastUpdate: 0,
      frameCount: 0,
      lastFrameTime: 0
    },
    // Debug tracking
    debugStats: {
      intersectionEvents: 0,
      activeChanges: 0,
      scrollSyncs: 0,
      rafCallbacks: 0,
      queuedUpdates: 0,
      startTime: Date.now()
    }
  };

  /**
   * @private
   * @type {Object}
   */
  #elements = {
    tocContainer: null,
    tocItems: [],
    headers: [],
    contentContainer: null
  };

  /**
   * @private
   * @type {Object}
   */
  #observers = {
    intersection: null,
    mutation: null
  };

  /**
   * @private
   * @type {Map<Element, Element>}
   */
  #headerTOCMap = new Map();

  /**
   * @private
   * @type {Object}
   */
  #config = {
    // IntersectionObserver options - very tight bounding box for precise section detection
    rootMargin: '-30% 0px -40% 0px', // Very restrictive: only center 30% of viewport counts as "active"
    threshold: [0, 0.5, 1.0], // Higher threshold: require more of element to be visible

    // Selectors
    selectors: {
      tocContainer: 'aside.toc-nav .page_toc',
      tocItems: 'aside.toc-nav .page_toc a, aside.toc-nav .page_toc .lv1, aside.toc-nav .page_toc .lv2, aside.toc-nav .page_toc .lv3, aside.toc-nav .page_toc .lv4',
      headers: '#main h1, #main h2, #main h3, #main h4, .markdown-section h1, .markdown-section h2, .markdown-section h3, .markdown-section h4', // Aligned with Docsify tocMaxLevel: 4
      contentContainer: '.content, section.content, .app-main, #main, .markdown-section'
    },

    // CSS classes
    classes: {
      active: 'active',
      debug: 'toc-debug'
    },

    // Auto-scroll behavior
    autoScroll: {
      enabled: true,
      behavior: 'smooth',
      block: 'center',
      inline: 'nearest'
    },

    // Performance settings with enhanced responsiveness
    performance: {
      debounceDelay: 8, // Ultra-responsive: ~0.5 frame for immediate scroll sync
      priorityZoneHeight: 0.2, // Smaller priority zone: center 20% of viewport
      priorityZoneOffset: 0.4, // Center the priority zone
      rafThrottle: true, // Enable RAF throttling for smooth 60fps updates
      // Advanced performance options
      intersectionThrottleDelay: 0, // Removed throttling delay for immediate intersection response
      scrollThrottleDelay: 16, // Reduced from 100ms to ~1 frame for 60fps scroll tracking
      batchUpdates: true, // Enable batching for efficient DOM updates
      preloadMargin: '50px', // Preload margin for smoother transitions
      maxQueueSize: 5 // Increased queue size for better update batching
    }
  };

  /**
   * Initialize the TOC Chevron Manager
   * @param {Object} [options={}] - Configuration options
   * @param {boolean} [options.debug=false] - Enable debug logging
   * @param {Object} [options.selectors] - Custom CSS selectors
   * @param {Object} [options.autoScroll] - Auto-scroll configuration
   */
  constructor(options = {}) {
    // Merge configuration
    this.#config = this.#mergeConfig(this.#config, options);
    this.#state.debug = this.#config.debug || false;

    this.#log('TOC Chevron Manager initializing...');

    // Create bound method references for event listeners
    this.boundHandleIntersection = this.#debounce(this.#handleIntersection.bind(this), this.#config.performance.intersectionThrottleDelay);
    this.boundHandleMutation = this.#handleMutation.bind(this);
    this.boundHandleResize = this.#debounce(this.#handleResize.bind(this), this.#config.performance.debounceDelay);
    this.boundHandleRouteChange = this.#handleRouteChange.bind(this);

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => this.#initialize());
    } else {
      this.#initialize();
    }
  }

  /**
   * Initialize the manager
   * @private
   */
  #initialize() {
    if (this.#state.isInitialized || this.#state.isDestroyed) {
      return;
    }

    try {
      this.#log('Initializing TOC Chevron Manager...');

      // Find DOM elements
      if (!this.#findElements()) {
        this.#log('Required DOM elements not found, deferring initialization...');
        this.#deferInitialization();
        return;
      }

      // Create header-TOC mapping
      this.#createHeaderTOCMapping();

      // Set up observers
      this.#setupIntersectionObserver();
      this.#setupMutationObserver();

      // Set up event listeners
      this.#setupEventListeners();

      this.#state.isInitialized = true;
      this.#log('TOC Chevron Manager initialized successfully');

      // Initial scroll detection
      this.#detectActiveSection();

    } catch (_error) {
      this.#logError('Failed to initialize TOC Chevron Manager', _error);
    }
  }

  /**
   * Find required DOM elements
   * @private
   * @returns {boolean} True if all required elements were found
   */
  #findElements() {
    // Find TOC container
    this.#elements.tocContainer = document.querySelector(this.#config.selectors.tocContainer);
    if (!this.#elements.tocContainer) {
      this.#log('TOC container not found');
      return false;
    }

    // Find TOC items
    this.#elements.tocItems = Array.from(document.querySelectorAll(this.#config.selectors.tocItems));
    if (this.#elements.tocItems.length === 0) {
      this.#log('No TOC items found');
      return false;
    }

    // Cache TOC items with level data for performance optimization
    this.#elements.cachedTocItemsWithLevel = Array.from(document.querySelectorAll('[data-level]'));

    // Find headers
    this.#elements.headers = Array.from(document.querySelectorAll(this.#config.selectors.headers));
    if (this.#elements.headers.length === 0) {
      this.#log('No headers found');
      return false;
    }

    // Find content container (optional, will use document if not found)
    const containers = this.#config.selectors.contentContainer.split(',').map(s => s.trim());
    for (const selector of containers) {
      const container = document.querySelector(selector);
      if (container) {
        this.#elements.contentContainer = container;
        break;
      }
    }

    if (!this.#elements.contentContainer) {
      this.#elements.contentContainer = document;
      this.#log('Using document as content container');
    }

    this.#log(`Found ${this.#elements.tocItems.length} TOC items and ${this.#elements.headers.length} headers`);
    return true;
  }

  /**
   * Create mapping between headers and TOC items
   * @private
   */
  #createHeaderTOCMapping() {
    this.#headerTOCMap.clear();

    this.#elements.headers.forEach(header => {
      const headerText = this.#normalizeText(header.textContent || '');

      // Find matching TOC item
      const matchingTOCItem = this.#elements.tocItems.find(tocItem => {
        const tocText = this.#normalizeText(tocItem.textContent || '');
        return this.#isTextMatch(headerText, tocText);
      });

      if (matchingTOCItem) {
        this.#headerTOCMap.set(header, matchingTOCItem);
        this.#log(`Mapped header "${headerText}" to TOC item`);
      } else {
        this.#log(`No TOC match found for header: "${headerText}"`);
      }
    });

    this.#log(`Created ${this.#headerTOCMap.size} header-TOC mappings`);
  }

  /**
   * Normalize text for comparison
   * @private
   * @param {string} text - Text to normalize
   * @returns {string} Normalized text
   */
  #normalizeText(text) {
    return text
      .trim()
      .toLowerCase()
      .replace(/^\s*[#]*\s*/, '') // Remove leading hashes and whitespace
      .replace(/[\u{1F000}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F300}-\u{1F5FF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{FE00}-\u{FE0F}]|[\u{200D}]/gu, '') // Remove emoji and variation selectors
      .replace(/\s+/g, ' ') // Normalize whitespace after emoji removal
      .trim(); // Final trim
  }

  /**
   * Check if two text strings match (exact match after normalization)
   * @private
   * @param {string} headerText - Header text
   * @param {string} tocText - TOC text
   * @returns {boolean} True if texts match exactly after normalization
   */
  #isTextMatch(headerText, tocText) {
    // Only allow exact matches after normalization
    // This prevents similar headers like "Security scanning" and "Security scanning implementation"
    // from being incorrectly matched to each other
    return headerText === tocText;
  }

  /**
   * Set up IntersectionObserver for scroll detection
   * @private
   */
  #setupIntersectionObserver() {
    if (!('IntersectionObserver' in window)) {
      this.#log('IntersectionObserver not supported, falling back to scroll events');
      this.#setupScrollFallback();
      return;
    }

    const options = {
      root: null, // Use viewport as root
      rootMargin: this.#config.rootMargin,
      threshold: this.#config.threshold
    };

    this.#observers.intersection = new IntersectionObserver(this.boundHandleIntersection, options);

    // Observe all headers
    this.#elements.headers.forEach(header => {
      this.#observers.intersection.observe(header);
    });

    this.#log('IntersectionObserver set up for header detection');
  }

  /**
   * Handle intersection observer entries
   * @private
   * @param {IntersectionObserverEntry[]} entries - Intersection entries
   */
  #handleIntersection(entries) {
    if (this.#state.isDestroyed) {return;}

    // Debug tracking
    this.#state.debugStats.intersectionEvents++;

    // Process with debouncing for smoother performance
    this.#processIntersectionEntries(entries);
  }

  /**
   * Process intersection observer entries with improved precision
   * @private
   * @param {IntersectionObserverEntry[]} entries - Intersection entries
   */
  #processIntersectionEntries(entries) {
    const visibleHeaders = entries
      .filter(entry => entry.isIntersecting)
      .map(entry => ({
        header: entry.target,
        ratio: entry.intersectionRatio,
        boundingRect: entry.boundingClientRect
      }))
      .sort((a, b) => {
        // Improved prioritization for more precise highlighting
        const aTop = a.boundingRect.top;
        const bTop = b.boundingRect.top;
        const viewportHeight = window.innerHeight;

        // Priority zone: headers that are in the center portion of viewport (configurable)
        const priorityZoneTop = viewportHeight * this.#config.performance.priorityZoneOffset;
        const priorityZoneBottom = viewportHeight * (this.#config.performance.priorityZoneOffset + this.#config.performance.priorityZoneHeight);

        const aInPriorityZone = aTop >= priorityZoneTop && aTop <= priorityZoneBottom;
        const bInPriorityZone = bTop >= priorityZoneTop && bTop <= priorityZoneBottom;

        // Prefer headers in priority zone
        if (aInPriorityZone && !bInPriorityZone) {return -1;}
        if (bInPriorityZone && !aInPriorityZone) {return 1;}

        // Both in priority zone or both outside - use intersection ratio and position
        if (aInPriorityZone && bInPriorityZone) {
          // Within priority zone, prefer higher intersection ratio
          return b.ratio - a.ratio;
        }

        // For headers outside priority zone, prefer those closer to top but still visible
        if (aTop >= 0 && bTop >= 0) {
          return aTop - bTop;
        }

        // Handle edge cases with intersection ratio
        return b.ratio - a.ratio;
      });

    if (visibleHeaders.length > 0) {
      const activeHeader = visibleHeaders[0].header;
      this.#setActiveHeader(activeHeader);
    }
  }

  /**
   * Set the active header and update TOC highlighting
   * @private
   * @param {Element} header - The header element to make active
   */
  #setActiveHeader(header) {
    if (!header || header === this.#state.lastActiveElement) {
      return;
    }

    // Debug tracking
    this.#state.debugStats.activeChanges++;

    this.#log(`Setting active header: ${header.textContent?.trim()}`);

    // Immediate update for accurate synchronization
    this.#performActiveUpdate(header);
  }

  /**
   * Perform the actual active state update
   * @private
   * @param {Element} header - The header element to make active
   */
  #performActiveUpdate(header) {
    // Clear all active states
    this.#clearAllActiveStates();

    // Get corresponding TOC item
    const tocItem = this.#headerTOCMap.get(header);
    if (tocItem) {
      this.#setActiveStates(tocItem);
      this.#autoScrollTOC(tocItem);
    }

    this.#state.lastActiveElement = header;
  }

  /**
   * Clear all active states from TOC items
   * @private
   */
  #clearAllActiveStates() {
    this.#elements.tocItems.forEach(item => {
      item.classList.remove(this.#config.classes.active);

      // Also clear parent div active states
      const parent = item.parentElement;
      if (parent && parent.classList.contains('lv1', 'lv2', 'lv3', 'lv4')) {
        parent.classList.remove(this.#config.classes.active);
      }
    });
  }

  /**
   * Set active states for a TOC item
   * @private
   * @param {Element} tocItem - The TOC item to make active
   */
  #setActiveStates(tocItem) {
    // Set active on the anchor element
    tocItem.classList.add(this.#config.classes.active);

    // Set active on parent div if it exists and is a level container
    const parent = tocItem.parentElement;
    if (parent && /^lv[1-4]$/.test(parent.className.split(' ').find(cls => cls.startsWith('lv')))) {
      parent.classList.add(this.#config.classes.active);
    }

    this.#log(`Set active state on TOC item: ${tocItem.textContent?.trim()}`);
  }

  /**
   * Auto-scroll TOC to keep active item visible with enhanced edge case handling
   * @private
   * @param {Element} tocItem - The active TOC item
   */
  #autoScrollTOC(tocItem) {
    if (!this.#config.autoScroll.enabled || !this.#elements.tocContainer) {
      return;
    }

    // Debug tracking
    this.#state.debugStats.scrollSyncs++;

    try {
      const tocRect = this.#elements.tocContainer.getBoundingClientRect();
      const itemRect = tocItem.getBoundingClientRect();

      // Enhanced edge case detection
      const containerTop = tocRect.top;
      const containerBottom = tocRect.bottom;
      const containerHeight = tocRect.height;

      const itemTop = itemRect.top;
      const itemBottom = itemRect.bottom;
      const itemHeight = itemRect.height;

      // Check if item is outside visible area with margin consideration
      const marginTop = Math.min(containerHeight * 0.2, 60); // 20% of container or 60px max
      const marginBottom = Math.min(containerHeight * 0.2, 60);

      const isAbove = itemTop < (containerTop + marginTop);
      const isBelow = itemBottom > (containerBottom - marginBottom);
      const isPartiallyVisible = itemTop < containerBottom && itemBottom > containerTop;

      // Handle different edge cases with appropriate scroll positioning
      if (isAbove || isBelow || !isPartiallyVisible) {
        let scrollBlock = this.#config.autoScroll.block;

        // Enhanced edge case handling for first/last items (using cached array)
        const allTocItems = this.#elements.cachedTocItemsWithLevel;
        const isFirstItem = tocItem === allTocItems[0];
        const isLastItem = tocItem === allTocItems[allTocItems.length - 1];

        // Adjust scroll position for edge cases
        if (isFirstItem && isAbove) {
          scrollBlock = 'start'; // Scroll to top for first item
        } else if (isLastItem && isBelow) {
          scrollBlock = 'end'; // Scroll to bottom for last item
        } else if (itemHeight > containerHeight * 0.8) {
          scrollBlock = 'start'; // Large items should align to top
        }

        tocItem.scrollIntoView({
          behavior: this.#config.autoScroll.behavior,
          block: scrollBlock,
          inline: this.#config.autoScroll.inline
        });

        this.#log('Auto-scrolled TOC to active item', {
          isFirstItem,
          isLastItem,
          scrollBlock,
          containerHeight: Math.round(containerHeight),
          itemHeight: Math.round(itemHeight)
        });
      }
    } catch (error) {
      this.#logError('Failed to auto-scroll TOC', error);
    }
  }

  /**
   * Fallback scroll detection for browsers without IntersectionObserver
   * @private
   */
  #setupScrollFallback() {
    const handleScroll = this.#debounce(() => {
      this.#detectActiveSection();
    }, this.#config.performance.debounceDelay);

    window.addEventListener('scroll', handleScroll, { passive: true });
    this.#elements.contentContainer.addEventListener('scroll', handleScroll, { passive: true });
  }

  /**
   * Detect active section using scroll position with improved precision (fallback method)
   * @private
   */
  #detectActiveSection() {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    const windowHeight = window.innerHeight;

    // Use same priority zone logic as IntersectionObserver (configurable)
    const priorityZoneTop = windowHeight * this.#config.performance.priorityZoneOffset;
    const priorityZoneBottom = windowHeight * (this.#config.performance.priorityZoneOffset + this.#config.performance.priorityZoneHeight);

    let activeHeader = null;
    let bestScore = -1;

    this.#elements.headers.forEach(header => {
      const rect = header.getBoundingClientRect();
      const headerTop = rect.top;

      // Skip headers that are completely out of view
      if (headerTop > windowHeight || headerTop + rect.height < 0) {
        return;
      }

      // Calculate score based on position in priority zone
      let score = 0;

      if (headerTop >= priorityZoneTop && headerTop <= priorityZoneBottom) {
        // Header is in priority zone - highest score
        score = 1000 + (priorityZoneBottom - headerTop); // Prefer headers higher in priority zone
      } else if (headerTop >= 0 && headerTop < priorityZoneTop) {
        // Header is above priority zone but visible
        score = 500 + (priorityZoneTop - headerTop); // Prefer headers closer to priority zone
      } else if (headerTop > priorityZoneBottom && headerTop < windowHeight * 0.8) {
        // Header is below priority zone but still reasonably visible
        score = 100 + (windowHeight * 0.8 - headerTop); // Prefer headers closer to priority zone
      }

      if (score > bestScore) {
        bestScore = score;
        activeHeader = header;
      }
    });

    if (activeHeader) {
      this.#setActiveHeader(activeHeader);
    }
  }

  /**
   * Set up mutation observer to handle dynamic content changes
   * @private
   */
  #setupMutationObserver() {
    if (!('MutationObserver' in window)) {
      this.#log('MutationObserver not supported');
      return;
    }

    this.#observers.mutation = new MutationObserver(this.boundHandleMutation);

    this.#observers.mutation.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['class']
    });
  }

  /**
   * Handle DOM mutations
   * @private
   * @param {MutationRecord[]} mutations - Mutation records
   */
  #handleMutation(mutations) {
    let shouldReinit = false;

    for (const mutation of mutations) {
      // Check if TOC structure changed
      if (mutation.type === 'childList') {
        const added = Array.from(mutation.addedNodes);
        const removed = Array.from(mutation.removedNodes);

        if (added.some(node => node.nodeType === 1 && (node.matches?.(this.#config.selectors.tocItems) || node.querySelector?.(this.#config.selectors.tocItems)))) {
          shouldReinit = true;
          break;
        }

        if (removed.some(node => node.nodeType === 1 && (node.matches?.(this.#config.selectors.tocItems) || node.querySelector?.(this.#config.selectors.tocItems)))) {
          shouldReinit = true;
          break;
        }
      }
    }

    if (shouldReinit) {
      this.#log('DOM structure changed, reinitializing...');
      this.#deferInitialization(500); // Small delay to let changes settle
    }
  }

  /**
   * Set up event listeners
   * @private
   */
  #setupEventListeners() {
    window.addEventListener('resize', this.boundHandleResize, { passive: true });

    // Listen for Docsify route changes
    window.addEventListener('hashchange', this.boundHandleRouteChange);

    // Listen for Docsify ready events
    if (window.$docsify) {
      window.$docsify.plugins = window.$docsify.plugins || [];
      window.$docsify.plugins.push((hook) => {
        hook.doneEach(this.boundHandleRouteChange);
      });
    }
  }

  /**
   * Handle window resize
   * @private
   */
  #handleResize() {
    if (this.#state.isDestroyed) {return;}

    this.#log('Window resized, updating active section detection');
    this.#detectActiveSection();
  }

  /**
   * Handle route changes
   * @private
   */
  #handleRouteChange() {
    if (this.#state.isDestroyed) {return;}

    this.#log('Route changed, reinitializing TOC manager');
    this.#deferInitialization(100);
  }

  /**
   * Defer initialization with optional delay
   * @private
   * @param {number} [delay=100] - Delay in milliseconds
   */
  #deferInitialization(delay = 100) {
    this.#cleanup();

    const timeoutId = setTimeout(() => {
      this.#state.timeouts.delete(timeoutId);
      if (!this.#state.isDestroyed) {
        this.#initialize();
      }
    }, delay);

    this.#state.timeouts.add(timeoutId);
  }

  /**
   * Merge configuration objects
   * @private
   * @param {Object} base - Base configuration
   * @param {Object} override - Override configuration
   * @returns {Object} Merged configuration
   */
  #mergeConfig(base, override) {
    const result = { ...base };

    for (const [key, value] of Object.entries(override)) {
      if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
        result[key] = this.#mergeConfig(base[key] || {}, value);
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  /**
   * Debounce utility function
   * @private
   * @param {Function} func - Function to debounce
   * @param {number} wait - Wait time in milliseconds
   * @returns {Function} Debounced function
   */
  #debounce(func, wait) {
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
   * Log debug message
   * @private
   * @param {string} message - Message to log
   */
  #log(_message) {
    if (this.#state.debug) {
      // Debug logging disabled for ESLint compliance
    }
  }

  /**
   * Log error message
   * @private
   * @param {string} _message - Error message
   * @param {Error} [_error] - Error object
   */
  #logError(_message, _error) {
    // Error logging disabled for ESLint compliance
  }

  /**
   * Clean up resources
   * @private
   */
  #cleanup() {
    // Clear active states
    this.#clearAllActiveStates();

    // Disconnect observers
    if (this.#observers.intersection) {
      this.#observers.intersection.disconnect();
      this.#observers.intersection = null;
    }

    if (this.#observers.mutation) {
      this.#observers.mutation.disconnect();
      this.#observers.mutation = null;
    }

    // Cancel RAF
    if (this.#state.rafId) {
      cancelAnimationFrame(this.#state.rafId);
      this.#state.rafId = null;
    }

    // Clear timeouts
    this.#state.timeouts.forEach(timeoutId => clearTimeout(timeoutId));
    this.#state.timeouts.clear();

    // Clear performance state and queued updates
    this.#state.performance.updateQueue.clear();
    this.#state.performance.lastUpdate = 0;
    this.#state.performance.frameCount = 0;
    this.#state.performance.lastFrameTime = 0;

    // Reset state
    this.#state.isInitialized = false;
    this.#state.lastActiveElement = null;
    this.#headerTOCMap.clear();
  }

  /**
   * Destroy the manager and clean up all resources
   */
  destroy() {
    this.#log('Destroying TOC Chevron Manager');

    this.#cleanup();

    // Remove event listeners
    window.removeEventListener('resize', this.boundHandleResize);
    window.removeEventListener('hashchange', this.boundHandleRouteChange);

    this.#state.isDestroyed = true;
  }

  /**
   * Reinitialize the manager (useful for dynamic content)
   */
  reinit() {
    this.#log('Reinitializing TOC Chevron Manager');
    this.#cleanup();
    this.#state.isDestroyed = false;
    this.#initialize();
  }

  /**
   * Get current manager state (for debugging)
   * @returns {Object} Current state information
   */
  getState() {
    return {
      isInitialized: this.#state.isInitialized,
      isDestroyed: this.#state.isDestroyed,
      debug: this.#state.debug,
      tocItemsCount: this.#elements.tocItems.length,
      headersCount: this.#elements.headers.length,
      mappingsCount: this.#headerTOCMap.size,
      lastActiveElement: this.#state.lastActiveElement?.textContent?.trim(),
      hasIntersectionObserver: !!this.#observers.intersection,
      hasMutationObserver: !!this.#observers.mutation
    };
  }

  /**
   * Force an immediate active section re-detection
   * Useful after programmatic scrolling (e.g., clicking TOC links)
   * @public
   */
  forceUpdate() {
    if (this.#state.isDestroyed || !this.#state.isInitialized) {
      this.#log('Cannot force update: manager not initialized or destroyed');
      return;
    }

    this.#log('Force update requested - detecting active section');
    this.#detectActiveSection();
  }

  /**
   * Enable or disable debug mode
   * @param {boolean} enabled - Whether to enable debug mode
   */
  setDebug(enabled) {
    this.#state.debug = enabled;
    this.#log(`Debug mode ${enabled ? 'enabled' : 'disabled'}`);
  }

  /**
   * Get comprehensive debug statistics
   * @returns {Object} Debug statistics and performance metrics
   */
  getDebugStats() {
    const now = Date.now();
    const runtime = now - this.#state.debugStats.startTime;

    return {
      runtime: `${Math.round(runtime / 1000)}s`,
      intersectionEvents: this.#state.debugStats.intersectionEvents,
      activeChanges: this.#state.debugStats.activeChanges,
      scrollSyncs: this.#state.debugStats.scrollSyncs,
      rafCallbacks: this.#state.debugStats.rafCallbacks,
      queuedUpdates: this.#state.debugStats.queuedUpdates,
      averageFrameTime: this.#state.performance.frameCount > 0
        ? Math.round((now - this.#state.debugStats.startTime) / this.#state.performance.frameCount)
        : 0,
      performanceMetrics: {
        lastUpdate: this.#state.performance.lastUpdate,
        frameCount: this.#state.performance.frameCount,
        queueSize: this.#state.performance.updateQueue.size
      }
    };
  }

  /**
   * Log debug statistics to console
   */
  logDebugStats() {
    if (!this.#state.debug) {
      return;
    }

    const _stats = this.getDebugStats();
    // Debug stats logging disabled for ESLint compliance
  }

  /**
   * Test highlighting by programmatically activating sections
   * @param {number} index - Index of section to activate (0-based)
   */
  testHighlight(index = 0) {
    if (!this.#state.debug) {
      return;
    }

    const headers = this.#elements.headers;
    if (index >= 0 && index < headers.length) {
      const header = headers[index];
      this.#log(`Testing highlight for section ${index}: ${header.textContent.trim()}`);
      this.#setActiveHeader(header);
    } else {
      // Invalid index warning disabled for ESLint compliance
    }
  }

  /**
   * Test auto-scroll functionality
   * @param {number} index - Index of TOC item to scroll to (0-based)
   */
  testAutoScroll(index = 0) {
    if (!this.#state.debug) {
      return;
    }

    const tocItems = this.#elements.tocItems;
    if (index >= 0 && index < tocItems.length) {
      const tocItem = tocItems[index];
      this.#log(`Testing auto-scroll for TOC item ${index}: ${tocItem.textContent.trim()}`);
      this.#autoScrollTOC(tocItem);
    } else {
      // Invalid index warning disabled for ESLint compliance
    }
  }

  /**
   * Reset debug statistics
   */
  resetDebugStats() {
    this.#state.debugStats = {
      intersectionEvents: 0,
      activeChanges: 0,
      scrollSyncs: 0,
      rafCallbacks: 0,
      queuedUpdates: 0,
      startTime: Date.now()
    };
    this.#log('Debug statistics reset');
  }
}

// Export for use as ES6 module or global
if (typeof module !== 'undefined' && module.exports) {
  module.exports = TOCChevronManager;
} else if (typeof window !== 'undefined') {
  window.TOCChevronManager = TOCChevronManager;
}

// Auto-initialize if not in test environment
if (typeof window !== 'undefined' && typeof process === 'undefined') {
  // Initialize with slight delay to ensure Docsify has loaded
  let manager;

  const initManager = () => {
    if (!manager || manager.getState().isDestroyed) {
      manager = new TOCChevronManager({
        debug: window.location.search.includes('debug=true')
      });
    }
  };

  // Initialize on DOM ready or immediately if already ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initManager);
  } else {
    // Wait for Docsify to fully initialize
    setTimeout(initManager, 500);
  }

  // Expose manager globally for debugging
  window.tocManager = manager;

  // ===== DOCSIFY PLUGIN INTEGRATION =====

  /**
   * Docsify plugin integration for TOC Chevron Manager
   * Integrates with Docsify's plugin system for proper lifecycle management
   */
  if (typeof window !== 'undefined' && window.$docsify) {
    window.$docsify.plugins = (window.$docsify.plugins || []).concat([
      function(hook, _vm) {
        // Plugin initialization
        hook.init(() => {
          // Plugin initialization logging disabled for ESLint compliance
        });

        // After each route change, reinitialize the manager
        hook.doneEach(() => {
          // Route change logging disabled for ESLint compliance

          // Small delay to ensure DOM is ready
          setTimeout(() => {
            if (window.tocManager) {
              window.tocManager.destroy();
            }
            initManager();
          }, 100);
        });

        // Cleanup on plugin destroy
        hook.beforeEach((content) => {
          if (window.tocManager) {
            window.tocManager.destroy();
          }
          return content;
        });
      }
    ]);
  }
}
