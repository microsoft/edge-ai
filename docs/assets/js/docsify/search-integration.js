/**
 * Search Integration
 * Enhanced search functionality for docsify with clickable tags
 * @version 3.0.0
 * @description Provides comprehensive search enhancements including keyboard shortcuts,
 *              auto-clear functionality, result counting, and tag-based search integration
 */

(function() {
  'use strict';

  /**
   * Search Integration Manager
   * Handles all search-related functionality with proper state management
   */
  class SearchIntegrationManager {
    constructor() {
      this.searchInput = null;
      this.searchContainer = null;
      this.observers = [];
      this.eventHandlers = new Map();
      this.initialized = false;
      this.debounceTimer = null; // For performance optimization
      this.searchState = {
        isKeywordSearchActive: false,
        lastClearTime: 0,
        attempts: 0,
        maxAttempts: 5
      };

      // DOM element cache for performance optimization
      this.domCache = {
        sidebar: null,
        searchBox: null,
        resultsPanel: null,
        resultsContainer: null,
        countElement: null
      };

      // Bind methods to maintain context
      this._handleTagClick = this._handleTagClick.bind(this);
      this._handleKeyboardShortcuts = this._handleKeyboardShortcuts.bind(this);
      this._handleSearchInput = this._handleSearchInput.bind(this);
      this._handleSearchBlur = this._handleSearchBlur.bind(this);
      this._handleDocumentClick = this._handleDocumentClick.bind(this);
      this._handleSearchResultClick = this._handleSearchResultClick.bind(this);
    }

    /**
     * Initialize the search integration manager
     * @returns {boolean} Success status
     */
    async initialize() {
      try {
        if (this.initialized) {
          return true;
        }

        // Initializing search integration manager

        // Wait for Docsify and search elements to be ready
        await this._waitForDocsifyReady();

        // Initialize search positioning
        this._ensureSearchAtTop();

        // Set up search input enhancements
        this._setupSearchInput();

        // Initialize event handlers
        this._setupEventHandlers();

        // Set up search result monitoring
        this._setupSearchResultMonitoring();

        // Register Docsify hooks
        this._registerDocsifyHooks();

        this.initialized = true;
        // Search integration manager initialized successfully
        return true;

      } catch {
        return false;
      }
    }

    /**
     * Clean up all resources and event listeners
     */
    destroy() {
      try {
        // Mark as not initialized immediately to prevent further operations
        this.initialized = false;

        // Remove all event listeners with proper error handling
        this.eventHandlers.forEach((handler, element) => {
          try {
            if (element && typeof element.removeEventListener === 'function') {
              element.removeEventListener(handler.event, handler.callback);
            }
          } catch (_error) {
            // Ignore individual cleanup errors but continue cleanup
          }
        });
        this.eventHandlers.clear();

        // Disconnect observers with proper error handling
        this.observers.forEach(observer => {
          try {
            if (observer && typeof observer.disconnect === 'function') {
              observer.disconnect();
            }
          } catch (_observerError) {
            // Ignore individual observer cleanup errors
          }
        });
        this.observers.length = 0; // Clear array

        // Clear debounce timer
        if (this.debounceTimer) {
          clearTimeout(this.debounceTimer);
          this.debounceTimer = null;
        }

        // Clear search state
        if (this.searchState) {
          this.searchState.isKeywordSearchActive = false;
          this.searchState.lastClearTime = 0;
          this.searchState.attempts = 0;
        }

        // Clear global flags
        if (typeof window !== 'undefined') {
          window.searchKeywordActive = false;
        }

        // Clear DOM references to prevent memory leaks
        this.searchInput = null;
        this.searchContainer = null;

        // Clear DOM cache to prevent memory leaks
        if (this.domCache) {
          this.domCache.sidebar = null;
          this.domCache.searchBox = null;
          this.domCache.resultsPanel = null;
          this.domCache.resultsContainer = null;
          this.domCache.countElement = null;
        }

        // Search integration manager destroyed
        return true;

      } catch (_cleanupError) {
        // Cleanup failed but continue with minimal cleanup
        this.initialized = false;
        this.searchInput = null;
        this.searchContainer = null;
        return false;
      }
    }

    /**
     * Perform search for the given term
     * @param {string} term - Search term
     * @returns {boolean} Success status
     */
    doSearch(term) {
      if (!term || typeof term !== 'string' || term.trim() === '') {
        return false;
      }

      try {
        const cleanTerm = term.trim();
        // Invalid search term - ignoring

        if (!this.searchInput) {
          this.searchInput = document.querySelector('.search input[type="search"]');
        }

        // Check if the search input is still connected to the DOM
        if (!this.searchInput || !this.searchInput.isConnected) {
          this.searchInput = document.querySelector('.search input[type="search"]');
          if (!this.searchInput) {
            return false;
          }
        }

        // Set keyword search flag
        this.searchState.isKeywordSearchActive = true;
        window.searchKeywordActive = true;

        // Clear existing value and trigger clear
        if (this.searchInput) {
          this.searchInput.value = '';
          this._dispatchEvent(this.searchInput, 'input');
        }

        // Small delay to ensure clearing is processed
        setTimeout(() => {
          // Guard against cleanup
          if (!this.searchInput) {return;}

          this.searchInput.value = cleanTerm;
          this.searchInput.focus();

          // Dispatch multiple events for compatibility
          this._dispatchEvent(this.searchInput, 'input');
          this._dispatchEvent(this.searchInput, 'keyup');
          this._dispatchEvent(this.searchInput, 'change');

          // Try manual Docsify search trigger
          this._triggerDocsifySearch(cleanTerm);

          // Verify results and scroll to them
          this._verifyAndScrollToResults();

          // Reset keyword search flag after operation
          setTimeout(() => {
            // Guard against cleanup
            if (!this.searchState) {return;}

            this.searchState.isKeywordSearchActive = false;
            window.searchKeywordActive = false;
          }, 1000);

        }, 100);

        return true;

      } catch {
        this.searchState.isKeywordSearchActive = false;
        window.searchKeywordActive = false;
        return false;
      }
    }

    /**
     * Clear search state and results
     */
    clearSearchState() {
      if (this.searchState.isKeywordSearchActive || window.searchKeywordActive) {
        // Skipping search clear - keyword search active
        return;
      }

      // Throttle clearing to prevent excessive operations
      const now = Date.now();
      if (now - this.searchState.lastClearTime < 100) {
        return;
      }
      this.searchState.lastClearTime = now;

      try {
        if (!this.searchInput) {
          this.searchInput = document.querySelector('.search input[type="search"]');
        }

        if (this.searchInput && this.searchInput.value) {
          this.searchInput.value = '';
          this._dispatchEvent(this.searchInput, 'input');

          if (document.activeElement === this.searchInput) {
            this.searchInput.blur();
          }
        }

        // Hide results panel gently
        this._hideSearchResults();

        // Search state cleared
      } catch {
        // Error clearing search state
      }
    }

    /**
     * Force search box to top of sidebar
     * @returns {boolean} Success status
     */
    forceSearchToTop() {
      try {
        // Use cached elements or refresh cache if needed
        let sidebar = this.domCache.sidebar;
        let searchBox = this.domCache.searchBox;

        if (!sidebar || !searchBox) {
          this._updateDomCache();
          sidebar = this.domCache.sidebar;
          searchBox = this.domCache.searchBox;
        }

        if (sidebar && searchBox && sidebar.firstChild !== searchBox) {
          sidebar.insertBefore(searchBox, sidebar.firstChild);
          // Search box moved to top of sidebar
          return true;
        }
        return searchBox !== null;
      } catch {
        return false;
      }
    }

    /**
     * Wait for Docsify and search elements to be ready
     * @private
     */
    async _waitForDocsifyReady() {
      return new Promise((resolve, reject) => {
        let attempts = 0;
        const maxAttempts = 50; // 25 seconds maximum wait

        const checkReady = () => {
          attempts++;

          if (window.$docsify && document.querySelector('.search')) {
            // Docsify and search elements ready
            resolve();
            return;
          }

          if (attempts >= maxAttempts) {
            reject(new Error('Timeout waiting for Docsify to be ready'));
            return;
          }

          setTimeout(checkReady, 500);
        };

        checkReady();
      });
    }

    /**
     * Ensure search box is positioned at top of sidebar
     * @private
     */
    _ensureSearchAtTop() {
      let attempts = 0;

      const tryPositioning = () => {
        attempts++;

        requestAnimationFrame(() => {
          if (this.forceSearchToTop()) {
            // Search positioning successful
            return;
          }

          if (attempts < this.searchState.maxAttempts) {
            setTimeout(() => requestAnimationFrame(tryPositioning), 25);
          } else {
            // Failed to position search box after maximum attempts
          }
        });
      };

      if (!this.forceSearchToTop()) {
        tryPositioning();
      }
    }

    /**
     * Update DOM element cache for performance optimization
     * @private
     */
    _updateDomCache() {
      // Cache frequently accessed DOM elements to avoid repeated queries
      this.domCache.sidebar = document.querySelector('.sidebar');
      this.domCache.searchBox = document.querySelector('.sidebar .search');
      this.domCache.resultsPanel = document.querySelector('.results-panel');
      this.domCache.resultsContainer = document.querySelector('.search ul, .results-panel');
      this.domCache.countElement = document.querySelector('.search-result-count');
    }

    /**
     * Set up search input enhancements
     * @private
     */
    _setupSearchInput() {
      // Update DOM cache first for performance
      this._updateDomCache();

      this.searchInput = document.querySelector('.search input[type="search"]');
      this.searchContainer = document.querySelector('.search');

      if (this.searchInput) {
        this.searchInput.placeholder = 'Search documentation...';
        // Search input enhancements applied
      } else {
        // Retry setup if input not found
        setTimeout(() => this._setupSearchInput(), 100);
      }
    }

    /**
     * Set up all event handlers
     * @private
     */
    _setupEventHandlers() {
      // Document-level event handlers
      this._addEventHandler(document, 'click', this._handleTagClick);
      this._addEventHandler(document, 'click', this._handleDocumentClick);
      this._addEventHandler(document, 'keydown', this._handleKeyboardShortcuts);

      // Search input specific handlers
      if (this.searchInput) {
        this._addEventHandler(this.searchInput, 'input', this._handleSearchInput);
        this._addEventHandler(this.searchInput, 'blur', this._handleSearchBlur);
      }
    }

    /**
     * Add event handler with cleanup tracking
     * @private
     */
    _addEventHandler(element, event, callback) {
      if (!element || typeof element.addEventListener !== 'function') {
        return;
      }

      element.addEventListener(event, callback);
      this.eventHandlers.set(element, { event, callback });
    }

    /**
     * Handle tag click events
     * @private
     */
    _handleTagClick(event) {
      try {
        const tagElement = event.target.closest('.keyword-tag, .clickable-tag');
        if (!tagElement) {return;}

        // Let frontmatter plugin handle keyword tags
        if (tagElement.classList.contains('keyword-tag')) {
          // Keyword tag detected - letting frontmatter plugin handle it
          return;
        }

        // Handle clickable tags
        if (tagElement.classList.contains('clickable-tag')) {
          event.preventDefault();
          const searchTerm = tagElement.textContent.trim();
          // Clickable tag clicked
          this.doSearch(searchTerm);
        }
      } catch {
        // Error handling tag click
      }
    }

    /**
     * Handle keyboard shortcuts
     * @private
     */
    _handleKeyboardShortcuts(event) {
      try {
        // Ctrl/Cmd + K to focus search
        if ((event.ctrlKey || event.metaKey) && event.key === 'k') {
          event.preventDefault();
          if (this.searchInput) {
            this.searchInput.focus();
          }
        }

        // Escape to clear search
        if (event.key === 'Escape' && this.searchInput &&
            document.activeElement === this.searchInput && this.searchInput.value) {
          this.searchInput.value = '';
          this._dispatchEvent(this.searchInput, 'input');
          this.searchInput.blur();
        }
      } catch {
        // Error handling keyboard shortcuts
      }
    }

    /**
     * Handle search input changes
     * @private
     */
    _handleSearchInput(event) {
      try {
        if (event.target && event.target.value === '') {
          // Search input emptied, hiding results
          this._hideSearchResults();
        }
      } catch {
        // Error handling search input
      }
    }

    /**
     * Handle search input blur
     * @private
     */
    _handleSearchBlur() {
      try {
        if (this.searchInput && this.searchInput.value === '') {
          // Search input blurred and empty, hiding results
          this._hideSearchResults();
        }
      } catch {
        // Error handling search blur
      }
    }

    /**
     * Handle document click events
     * @private
     */
    _handleDocumentClick(event) {
      try {
        const target = event.target;

        // Handle search result clicks
        if (target.tagName === 'A' && target.closest('.search, .results-panel, .matching-post, [class*="search"]')) {
          // Search result link clicked, will clear search after navigation
          setTimeout(() => {
            if (!this.searchState.isKeywordSearchActive && !window.searchKeywordActive) {
              this.clearSearchState();
            }
          }, 100);
        }
        // Clear search when clicking outside search area
        else if (!target.closest('.search, .sidebar, .keyword-tag, .clickable-tag, .frontmatter-metadata')) {
          if (!this.searchState.isKeywordSearchActive && !window.searchKeywordActive &&
              this.searchInput && this.searchInput.value) {
            // Clicked outside search area, clearing search
            setTimeout(() => {
              if (!this.searchState.isKeywordSearchActive && !window.searchKeywordActive) {
                this.clearSearchState();
              }
            }, 25);
          }
        }
      } catch {
        // Error handling document click
      }
    }

    /**
     * Handle search result click for clearing
     * @private
     */
    _handleSearchResultClick() {
      try {
        // Search result clicked, clearing search
        setTimeout(() => {
          if (!this.searchState.isKeywordSearchActive) {
            this.clearSearchState();
          }
        }, 100);
      } catch {
        // Error clearing search on result click
      }
    }

    /**
     * Set up search result monitoring with mutation observer
     * @private
     */
    _setupSearchResultMonitoring() {
      try {
        const observer = new MutationObserver((mutations) => {
          try {
            mutations.forEach((mutation) => {
              if (mutation.type === 'childList') {
                this._debouncedEnhanceSearchResults();
              }
            });
          } catch {
            // Error in search result mutation observer
          }
        });

        if (this.searchContainer) {
          observer.observe(this.searchContainer, {
            childList: true,
            subtree: true
          });
          this.observers.push(observer);
        }
      } catch {
        // Error setting up search result monitoring
      }
    }

    /**
     * Debounced version of _enhanceSearchResults to prevent performance issues
     * @private
     */
    _debouncedEnhanceSearchResults() {
      // Clear existing timer
      if (this.debounceTimer) {
        clearTimeout(this.debounceTimer);
      }

      // Set new timer with 100ms delay
      this.debounceTimer = setTimeout(() => {
        this._enhanceSearchResults();
        this.debounceTimer = null;
      }, 100);
    }

    /**
     * Enhance search results with count and click handlers
     * @private
     */
    _enhanceSearchResults() {
      try {
        // Use cached results panel or refresh cache if needed
        let resultsPanel = this.domCache.resultsPanel;
        if (!resultsPanel) {
          this._updateDomCache();
          resultsPanel = this.domCache.resultsPanel;
        }

        if (!resultsPanel || resultsPanel.children.length === 0) {
          return;
        }

        // Show search results (they may have been hidden by previous searches)
        this._showSearchResults();

        // Add result count
        this._addResultCount(resultsPanel);

        // Add click handlers to results
        const searchResults = resultsPanel.querySelectorAll('.matching-post');
        searchResults.forEach((result) => {
          result.removeEventListener('click', this._handleSearchResultClick);
          result.addEventListener('click', this._handleSearchResultClick);
        });
      } catch {
        // Error enhancing search results
      }
    }

    /**
     * Add result count to search results
     * @private
     */
    _addResultCount(resultsPanel) {
      try {
        const resultCount = resultsPanel.querySelectorAll('.matching-post').length;

        // Use cached count element or refresh cache if needed
        let countElement = this.domCache.countElement;
        if (!countElement) {
          this._updateDomCache();
          countElement = this.domCache.countElement;
        }

        if (!countElement) {
          countElement = document.createElement('div');
          countElement.className = 'search-result-count';
          // Update cache with new element
          this.domCache.countElement = countElement;
          resultsPanel.insertBefore(countElement, resultsPanel.firstChild);
        }

        countElement.textContent = `${resultCount} result${resultCount !== 1 ? 's' : ''} found`;
      } catch {
        // Error adding result count
      }
    }

    /**
     * Register Docsify navigation hooks
     * @private
     */
    _registerDocsifyHooks() {
      try {
        if (!window.$docsify) {
          return;
        }

        window.$docsify.plugins = window.$docsify.plugins || [];
        window.$docsify.plugins.push((hook) => {
          hook.beforeEach(() => {
            if (!this.searchState.isKeywordSearchActive && !window.searchKeywordActive) {
              // Docsify navigation detected, clearing search
              this.clearSearchState();
            }
          });

          hook.doneEach(() => {
            // Docsify page loaded, ensuring search is at top
            this._ensureSearchAtTop();
            setTimeout(() => {
              if (!this.searchState.isKeywordSearchActive && !window.searchKeywordActive) {
                this.clearSearchState();
              }
            }, 50);
          });

          hook.ready(() => {
            // Docsify ready, finalizing search setup
            this._ensureSearchAtTop();
            this._setupRouterHook();
          });
        });
      } catch {
        // Error registering Docsify hooks
      }
    }

    /**
     * Set up router hook for navigation clearing
     * @private
     */
    _setupRouterHook() {
      try {
        if (window.Docsify && window.Docsify.router) {
          const originalPush = window.Docsify.router.push;
          if (originalPush) {
            window.Docsify.router.push = (...args) => {
              if (!this.searchState.isKeywordSearchActive && !window.searchKeywordActive) {
                // Router navigation detected, clearing search
                this.clearSearchState();
              }
              return originalPush.apply(window.Docsify.router, args);
            };
          }
        }
      } catch {
        // Error setting up router hook
      }
    }

    /**
     * Dispatch event helper
     * @private
     */
    _dispatchEvent(element, eventType) {
      try {
        const event = new Event(eventType, { bubbles: true, cancelable: true });
        element.dispatchEvent(event);
      } catch {
        // Error dispatching event
      }
    }

    /**
     * Try to trigger Docsify search manually
     * @private
     */
    _triggerDocsifySearch(term) {
      try {
        if (window.Docsify && window.Docsify.search &&
            typeof window.Docsify.search.performSearch === 'function') {
          // Attempting manual Docsify search trigger
          window.Docsify.search.performSearch(term);
        }
      } catch {
        // Manual Docsify search trigger failed
      }
    }

    /**
     * Verify search results and scroll to them
     * @private
     */
    _verifyAndScrollToResults() {
      setTimeout(() => {
        try {
          const resultsContainer = document.querySelector('.search ul, .results-panel');
          if (resultsContainer) {
            const hasResults = resultsContainer.children.length > 0;
            // Search results verification

            if (hasResults) {
              setTimeout(() => {
                resultsContainer.scrollIntoView({ behavior: 'smooth' });
              }, 200);
            } else {
              // No search results found - might be due to indexing or configuration
            }
          }
        } catch {
          // Error verifying search results
        }
      }, 200);
    }

    /**
     * Hide search results panel
     * @private
     */
    _hideSearchResults() {
      try {
        // Use cached results panel or refresh cache if needed
        let resultsPanel = this.domCache.resultsPanel;
        if (!resultsPanel) {
          this._updateDomCache();
          resultsPanel = this.domCache.resultsPanel;
        }

        if (resultsPanel) {
          resultsPanel.classList.add('search-results-hidden');
          resultsPanel.classList.remove('search-results-visible');
        }

        const otherResults = document.querySelectorAll('.search .matching-post, .search ul:not(.app-sub-sidebar)');
        otherResults.forEach(result => {
          if (result && !result.classList.contains('search-result-hidden') && result.children && result.children.length > 0) {
            result.classList.add('search-result-hidden');
            result.classList.remove('search-result-visible');
          }
        });
      } catch {
        // Error hiding search results
      }
    }

    /**
     * Show search results panel
     * @private
     */
    _showSearchResults() {
      try {
        // Use cached results panel or refresh cache if needed
        let resultsPanel = this.domCache.resultsPanel;
        if (!resultsPanel) {
          this._updateDomCache();
          resultsPanel = this.domCache.resultsPanel;
        }

        if (resultsPanel) {
          resultsPanel.classList.add('search-results-visible');
          resultsPanel.classList.remove('search-results-hidden');
        }

        const otherResults = document.querySelectorAll('.search .matching-post, .search ul:not(.app-sub-sidebar)');
        otherResults.forEach(result => {
          if (result && result.children && result.children.length > 0) {
            result.classList.add('search-result-visible');
            result.classList.remove('search-result-hidden');
          }
        });
      } catch {
        // Error showing search results
      }
    }
  }

  // Initialize global search keyword flag
  window.searchKeywordActive = false;

  // Create global search manager instance
  let searchManager = null;

  /**
   * Initialize search integration
   */
  async function initializeSearchIntegration() {
    try {
      // Initializing search integration

      searchManager = new SearchIntegrationManager();
      const success = await searchManager.initialize();

      if (success) {
        // Search integration initialized successfully
        return searchManager;
      } else {
        // Search integration initialization failed
        return null;
      }
    } catch {
      // Failed to initialize search integration
      return null;
    }
  }

  // Initialize with delay to ensure Docsify has loaded
  // Skip initialization in test environments to prevent timer leaks and window/document access
  // Note: Automatic initialization disabled - coordination handled by main.js
  // Manual initialization available via initializeSearchIntegration() or window.doSearch()
  if (typeof window !== 'undefined' &&
      typeof window.mocha === 'undefined' &&
      typeof global === 'undefined' &&
      typeof process === 'undefined' &&
      // Check if manual initialization should be disabled
      !window.DISABLE_AUTO_SEARCH_INIT) {
    // Reduced delay and add coordination with main app
    setTimeout(() => {
      // Check if main app is ready first
      if (window.mainApp && window.mainApp.isE2EReady) {
        initializeSearchIntegration();
      } else {
        // Wait for main app ready event
        const handleAppReady = () => {
          initializeSearchIntegration();
          window.removeEventListener('app:ready', handleAppReady);
        };
        window.addEventListener('app:ready', handleAppReady);

        // Fallback timeout in case main app doesn't emit ready event
        setTimeout(initializeSearchIntegration, 1000);
      }
    }, 500); // Reduced from 2000ms to 500ms
  }

  // Export for external access
  if (typeof window !== 'undefined') {
    // Main export
    window.SearchIntegrationManager = SearchIntegrationManager;

    // Global doSearch function for external integrations (e.g., frontmatter plugin)
    window.doSearch = function(term) {
      if (searchManager && searchManager.initialized) {
        return searchManager.doSearch(term);
      } else {
        // Search manager not initialized yet, queuing search
        // Queue the search to run when manager is ready
        setTimeout(() => {
          if (searchManager && searchManager.initialized) {
            searchManager.doSearch(term);
          } else {
            // Search manager still not ready for term
          }
        }, 1000);
        return false;
      }
    };

    // Debug function
    window.debugSearch = function() {
      // Debug info available through dev tools if needed
      const searchInput = document.querySelector('.search input[type="search"]');
      const searchContainer = document.querySelector('.search');
      const searchResults = document.querySelector('.search ul, .results-panel');

      // Return debug object instead of logging
      return {
        searchManager: searchManager,
        searchInput: searchInput,
        searchContainer: searchContainer,
        searchResults: searchResults,
        docsifyConfig: window.$docsify?.search,
        pluginLoaded: !!window.Docsify?.search,
        inputValue: searchInput?.value,
        inputFocused: document.activeElement === searchInput,
        managerInitialized: searchManager?.initialized,
        eventHandlersCount: searchManager?.eventHandlers?.size,
        observersCount: searchManager?.observers?.length
      };
    };
  }
})();
