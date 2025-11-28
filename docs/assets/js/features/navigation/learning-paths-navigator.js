/**
 * Learning Paths Navigator Enhancement
 * Provides advanced filtering, search, and navigation for learning paths
 *
 * @class LearningPathsNavigator
 * @author Edge AI Team
 * @version 1.0.0
 */

import { LEARNING_PATH_CONSTANTS } from '../../core/learning-path-constants.js';
const { DIFFICULTY } = LEARNING_PATH_CONSTANTS;

/**
 * Enhanced navigation and filtering for learning paths
 */
export class LearningPathsNavigator {
  /**
   * Create a LearningPathsNavigator instance
   * @param {Object} options - Configuration options
   * @param {Object} [options.errorHandler] - Error handler instance
   * @param {boolean} [options.debug=false] - Enable debug logging
   */
  constructor(options = {}) {
    this.errorHandler = options.errorHandler || null;
    this.debug = options.debug || false;

    // Navigation state
    this.isInitialized = false;
    this.currentFilters = {
      level: 'all',
      focus: 'all',
      role: 'all',
      search: ''
    };

    // Path data
    this.pathsData = new Map();
    this.filteredPaths = [];

    // Event handlers for cleanup
    this.boundHandlers = new Map();
  }

  /**
   * Initialize the navigator
   * @returns {Promise<boolean>} Success status
   */
  async initialize() {
    try {
      this.log('Initializing learning paths navigator');

      // Extract path data from DOM
      this.extractPathsData();

      // Enhance existing UI
      this.enhanceNavigationUI();

      // Set up event listeners
      this.setupEventListeners();

      // Apply initial filters
      this.applyFilters();

      this.isInitialized = true;
      this.log('Learning paths navigator initialized successfully');
      return true;
    } catch (_error) {
      this.handleError('Failed to initialize navigator', _error);
      return false;
    }
  }

  /**
   * Extract path data from DOM
   */
  extractPathsData() {
    try {
      this.log('Extracting paths data from DOM');

      // Find all path links in the document
      const pathLinks = document.querySelectorAll('a[href*="paths/"]');

      pathLinks.forEach(link => {
        const href = link.getAttribute('href');
        const text = link.textContent.trim();
        const parentSection = this.findParentSection(link);

        if (href && text) {
          const pathId = this.extractPathId(href);
          const pathData = {
            id: pathId,
            title: text,
            href: href,
            level: this.extractLevel(parentSection),
            focus: this.extractFocus(text, href),
            role: this.extractRole(href),
            element: link.closest('tr, li, div') || link.parentElement,
            description: this.extractDescription(link)
          };

          this.pathsData.set(pathId, pathData);
        }
      });

      this.log(`Extracted ${this.pathsData.size} paths`);
    } catch (_error) {
      this.handleError('Failed to extract paths data', _error);
    }
  }

  /**
   * Extract path ID from href
   * @param {string} href - Path href
   * @returns {string} Path ID
   */
  extractPathId(href) {
    const match = href.match(/paths\/([^/]+)\/([^/]+)\.md/);
    return match ? `${match[1]}-${match[2]}` : href;
  }

  /**
   * Find parent section for context
   * @param {HTMLElement} element - Element to find parent for
   * @returns {HTMLElement|null} Parent section
   */
  findParentSection(element) {
    let current = element;
    while (current && current !== document.body) {
      if (current.tagName && ['H2', 'H3', 'SECTION'].includes(current.tagName)) {
        return current;
      }
      current = current.parentElement;
    }
    return null;
  }

  /**
   * Extract level from section context
   * @param {HTMLElement} section - Section element
   * @returns {string} Level identifier
   */
  extractLevel(section) {
    if (!section) {return DIFFICULTY.BEGINNER;}

    const text = section.textContent.toLowerCase();
    if (text.includes('foundation') || text.includes('beginner')) {return DIFFICULTY.BEGINNER;}
    if (text.includes('intermediate') || text.includes('skill developer')) {return DIFFICULTY.INTERMEDIATE;}
    if (text.includes('expert') || text.includes('advanced')) {return DIFFICULTY.ADVANCED;}
    if (text.includes('role-based') || text.includes('career-tracks')) {return 'role-based';}

    return DIFFICULTY.BEGINNER;
  }

  /**
   * Extract focus area from content
   * @param {string} text - Link text
   * @param {string} href - Link href
   * @returns {string} Focus area
   */
  extractFocus(text, href) {
    const content = (`${text } ${ href}`).toLowerCase();

    if (content.includes('ai') || content.includes('prompt')) {return 'ai';}
    if (content.includes('edge') || content.includes('cloud') || content.includes('iot')) {return 'edge';}
    if (content.includes('data') || content.includes('analytic')) {return 'data';}
    if (content.includes('security') || content.includes('secure')) {return 'security';}
    if (content.includes('ux') || content.includes('ui') || content.includes('design')) {return 'ux';}
    if (content.includes('devops') || content.includes('infrastructure')) {return 'devops';}
    if (content.includes('management') || content.includes('program')) {return 'management';}

    return 'general';
  }

  /**
   * Extract role from href
   * @param {string} href - Link href
   * @returns {string} Role identifier
   */
  extractRole(href) {
    if (href.includes('career-tracks/')) {
      const match = href.match(/career-tracks\/([^/]+)\.md/);
      return match ? match[1] : 'general';
    }
    return 'general';
  }

  /**
   * Extract description from link context
   * @param {HTMLElement} link - Link element
   * @returns {string} Description
   */
  extractDescription(link) {
    const parent = link.closest('tr, li, div');
    if (!parent) {return '';}

    // Look for description text after the link
    const text = parent.textContent;
    const linkText = link.textContent;
    const afterLink = text.substring(text.indexOf(linkText) + linkText.length);

    // Extract meaningful description (first sentence or up to 100 chars)
    const match = afterLink.match(/[-–—]\s*([^|]+)/);
    return match ? match[1].trim() : afterLink.trim().substring(0, 100);
  }

  /**
   * Enhance navigation UI
   */
  enhanceNavigationUI() {
    try {
      this.log('Enhancing navigation UI');

      // Find the path navigator container
      const navigator = document.getElementById('path-navigator');
      if (!navigator) {
        this.log('Path navigator container not found');
        return;
      }

      // Add enhanced controls
      const enhancedControls = document.createElement('div');
      enhancedControls.className = 'path-navigator-enhanced';
      enhancedControls.innerHTML = this.getEnhancedControlsHTML();

      // Insert after the existing filters
      navigator.appendChild(enhancedControls);

      // Apply styles
      this.applyNavigatorStyles();

      this.log('Navigation UI enhanced successfully');
    } catch (_error) {
      this.handleError('Failed to enhance navigation UI', _error);
    }
  }

  /**
   * Get enhanced controls HTML
   * @returns {string} Controls HTML
   */
  getEnhancedControlsHTML() {
    return `
      <div class="nav-controls-row">
        <div class="search-box-container">
          <input
            type="text"
            id="path-search"
            class="path-search-input"
            placeholder="🔍 Search learning paths..."
            autocomplete="off"
          >
          <button id="clear-search" class="clear-search-btn" title="Clear search">×</button>
        </div>
        <div class="filter-controls">
          <select id="level-filter" class="filter-select">
            <option value="all">All Levels</option>
            <option value="foundation">🌱 Foundation</option>
            <option value="intermediate">🔧 Intermediate</option>
            <option value="expert">🎯 Expert</option>
            <option value="role-based">👔 Role-Based</option>
          </select>
          <select id="focus-filter" class="filter-select">
            <option value="all">All Focus Areas</option>
            <option value="ai">🤖 AI Engineering</option>
            <option value="edge">☁️ Edge Computing</option>
            <option value="data">📊 Data & Analytics</option>
            <option value="security">🛡️ Security</option>
            <option value="ux">🎨 User Experience</option>
            <option value="devops">⚙️ DevOps</option>
            <option value="management">📋 Management</option>
          </select>
          <button id="reset-filters" class="reset-filters-btn">🔄 Reset</button>
        </div>
      </div>
      <div class="results-summary" id="results-summary">
        <span class="results-count">Showing all paths</span>
        <span class="view-toggle">
          <button id="view-list" class="view-btn active">📋 List</button>
          <button id="view-grid" class="view-btn">📱 Grid</button>
        </span>
      </div>
    `;
  }

  /**
   * Apply navigator styles
   */
  applyNavigatorStyles() {
    try {
      // Check if styles already exist
      if (document.getElementById('navigator-styles')) {
        return;
      }

      const styles = document.createElement('style');
      styles.id = 'navigator-styles';
      styles.textContent = this.getNavigatorCSS();
      document.head.appendChild(styles);

      this.log('Navigator styles applied');
    } catch (_error) {
      this.handleError('Failed to apply navigator styles', _error);
    }
  }

  /**
   * Get navigator CSS styles
   * @returns {string} CSS styles
   */
  getNavigatorCSS() {
    return `
      .path-navigator-enhanced {
        background: #f8f9fa;
        border: 1px solid #e9ecef;
        border-radius: 8px;
        padding: 20px;
        margin: 20px 0;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      }

      .nav-controls-row {
        display: flex;
        gap: 20px;
        align-items: center;
        margin-bottom: 15px;
        flex-wrap: wrap;
      }

      .search-box-container {
        position: relative;
        flex: 1;
        min-width: 300px;
      }

      .path-search-input {
        width: 100%;
        padding: 12px 40px 12px 16px;
        border: 2px solid #dee2e6;
        border-radius: 6px;
        font-size: 1rem;
        transition: border-color 0.2s, box-shadow 0.2s;
        background: white;
      }

      .path-search-input:focus {
        outline: none;
        border-color: #007bff;
        box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.1);
      }

      .clear-search-btn {
        position: absolute;
        right: 8px;
        top: 50%;
        transform: translateY(-50%);
        background: none;
        border: none;
        font-size: 18px;
        color: #6c757d;
        cursor: pointer;
        padding: 4px 8px;
        border-radius: 3px;
        opacity: 0;
        transition: opacity 0.2s;
      }

      .path-search-input:not(:placeholder-shown) + .clear-search-btn {
        opacity: 1;
      }

      .clear-search-btn:hover {
        background: #f8f9fa;
        color: #495057;
      }

      .filter-controls {
        display: flex;
        gap: 12px;
        align-items: center;
        flex-wrap: wrap;
      }

      .filter-select {
        padding: 8px 12px;
        border: 1px solid #ced4da;
        border-radius: 4px;
        background: white;
        cursor: pointer;
        min-width: 140px;
      }

      .filter-select:focus {
        outline: none;
        border-color: #007bff;
        box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.1);
      }

      .reset-filters-btn {
        padding: 8px 16px;
        background: #6c757d;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        transition: background-color 0.2s;
      }

      .reset-filters-btn:hover {
        background: #545b62;
      }

      .results-summary {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding-top: 15px;
        border-top: 1px solid #e9ecef;
        font-size: 0.9rem;
      }

      .results-count {
        color: #6c757d;
        font-weight: 500;
      }

      .view-toggle {
        display: flex;
        gap: 4px;
      }

      .view-btn {
        padding: 6px 12px;
        background: #e9ecef;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        transition: all 0.2s;
        font-size: 0.85rem;
      }

      .view-btn.active {
        background: #007bff;
        color: white;
      }

      .view-btn:hover:not(.active) {
        background: #dee2e6;
      }

      /* Path highlighting for search results */
      .path-highlight {
        background: #fff3cd;
        border: 1px solid #ffeaa7;
        border-radius: 4px;
        padding: 2px 4px;
        animation: highlight-fade 2s ease-out;
      }

      @keyframes highlight-fade {
        0% { background: #fff3cd; }
        100% { background: transparent; }
      }

      /* Hidden paths */
      .path-hidden {
        display: none !important;
      }

      /* Grid view styles */
      .paths-grid-view .path-item {
        display: inline-block;
        width: calc(50% - 10px);
        margin: 0 5px 10px 5px;
        vertical-align: top;
      }

      /* Desktop optimizations */
      @media (min-width: 1200px) {
        .nav-controls-row {
          flex-wrap: nowrap;
        }

        .search-box-container {
          max-width: 400px;
        }

        .paths-grid-view .path-item {
          width: calc(33.333% - 14px);
          margin: 0 7px 14px 7px;
        }
      }

      @media (min-width: 1600px) {
        .paths-grid-view .path-item {
          width: calc(25% - 16px);
          margin: 0 8px 16px 8px;
        }
      }

      /* Compact desktop mode */
      .compact-mode .path-navigator-enhanced {
        padding: 15px;
      }

      .compact-mode .nav-controls-row {
        margin-bottom: 10px;
      }

      .compact-mode .filter-select,
      .compact-mode .path-search-input {
        padding: 6px 10px;
        font-size: 0.9rem;
      }
    `;
  }

  /**
   * Set up event listeners
   */
  setupEventListeners() {
    try {
      this.log('Setting up navigator event listeners');

      // Search input
      const searchInput = document.getElementById('path-search');
      if (searchInput) {
        const searchHandler = (e) => this.handleSearch(e);
        searchInput.addEventListener('input', searchHandler);
        this.boundHandlers.set(searchInput, new Map([['input', searchHandler]]));
      }

      // Clear search button
      const clearBtn = document.getElementById('clear-search');
      if (clearBtn) {
        const clearHandler = () => this.clearSearch();
        clearBtn.addEventListener('click', clearHandler);
        this.boundHandlers.set(clearBtn, new Map([['click', clearHandler]]));
      }

      // Filter selects
      const levelFilter = document.getElementById('level-filter');
      if (levelFilter) {
        const levelHandler = (e) => this.handleFilterChange('level', e.target.value);
        levelFilter.addEventListener('change', levelHandler);
        this.boundHandlers.set(levelFilter, new Map([['change', levelHandler]]));
      }

      const focusFilter = document.getElementById('focus-filter');
      if (focusFilter) {
        const focusHandler = (e) => this.handleFilterChange('focus', e.target.value);
        focusFilter.addEventListener('change', focusHandler);
        this.boundHandlers.set(focusFilter, new Map([['change', focusHandler]]));
      }

      // Reset filters button
      const resetBtn = document.getElementById('reset-filters');
      if (resetBtn) {
        const resetHandler = () => this.resetFilters();
        resetBtn.addEventListener('click', resetHandler);
        this.boundHandlers.set(resetBtn, new Map([['click', resetHandler]]));
      }

      // View toggle buttons
      const listViewBtn = document.getElementById('view-list');
      const gridViewBtn = document.getElementById('view-grid');

      if (listViewBtn) {
        const listHandler = () => this.setView('list');
        listViewBtn.addEventListener('click', listHandler);
        this.boundHandlers.set(listViewBtn, new Map([['click', listHandler]]));
      }

      if (gridViewBtn) {
        const gridHandler = () => this.setView('grid');
        gridViewBtn.addEventListener('click', gridHandler);
        this.boundHandlers.set(gridViewBtn, new Map([['click', gridHandler]]));
      }

      this.log('Navigator event listeners set up successfully');
    } catch (_error) {
      this.handleError('Failed to set up event listeners', _error);
    }
  }

  /**
   * Handle search input
   * @param {Event} event - Input event
   */
  handleSearch(event) {
    try {
      this.currentFilters.search = event.target.value.toLowerCase().trim();
      this.applyFilters();
      this.log(`Search updated: "${this.currentFilters.search}"`);
    } catch (_error) {
      this.handleError('Failed to handle search', _error);
    }
  }

  /**
   * Clear search input
   */
  clearSearch() {
    try {
      const searchInput = document.getElementById('path-search');
      if (searchInput) {
        searchInput.value = '';
        this.currentFilters.search = '';
        this.applyFilters();
        searchInput.focus();
      }
      this.log('Search cleared');
    } catch (_error) {
      this.handleError('Failed to clear search', _error);
    }
  }

  /**
   * Handle filter changes
   * @param {string} filterType - Type of filter
   * @param {string} value - Filter value
   */
  handleFilterChange(filterType, value) {
    try {
      this.currentFilters[filterType] = value;
      this.applyFilters();
      this.log(`Filter updated: ${filterType} = ${value}`);
    } catch (_error) {
      this.handleError('Failed to handle filter change', _error);
    }
  }

  /**
   * Reset all filters
   */
  resetFilters() {
    try {
      this.currentFilters = {
        level: 'all',
        focus: 'all',
        role: 'all',
        search: ''
      };

      // Reset UI elements
      const searchInput = document.getElementById('path-search');
      const levelFilter = document.getElementById('level-filter');
      const focusFilter = document.getElementById('focus-filter');

      if (searchInput) {searchInput.value = '';}
      if (levelFilter) {levelFilter.value = 'all';}
      if (focusFilter) {focusFilter.value = 'all';}

      this.applyFilters();
      this.log('All filters reset');
    } catch (_error) {
      this.handleError('Failed to reset filters', _error);
    }
  }

  /**
   * Set view mode
   * @param {string} view - View mode ('list' or 'grid')
   */
  setView(view) {
    try {
      const listBtn = document.getElementById('view-list');
      const gridBtn = document.getElementById('view-grid');

      if (listBtn && gridBtn) {
        listBtn.classList.toggle('active', view === 'list');
        gridBtn.classList.toggle('active', view === 'grid');

        // Apply view to content area
        const contentArea = document.querySelector('.learning-paths-content') || document.body;
        contentArea.classList.toggle('paths-grid-view', view === 'grid');
      }

      this.log(`View changed to: ${view}`);
    } catch (_error) {
      this.handleError('Failed to set view', _error);
    }
  }

  /**
   * Apply current filters to paths
   */
  applyFilters() {
    try {
      this.log('Applying filters', this.currentFilters);

      let visibleCount = 0;

      this.pathsData.forEach((pathData, pathId) => {
        const element = pathData.element;
        if (!element) {return;}

        let visible = true;

        // Apply search filter
        if (this.currentFilters.search) {
          const searchTerm = this.currentFilters.search;
          const searchContent = (
            `${pathData.title } ${
            pathData.description } ${
            pathData.focus } ${
            pathData.level } ${
            pathData.role}`
          ).toLowerCase();

          visible = searchContent.includes(searchTerm);
        }

        // Apply level filter
        if (visible && this.currentFilters.level !== 'all') {
          visible = pathData.level === this.currentFilters.level;
        }

        // Apply focus filter
        if (visible && this.currentFilters.focus !== 'all') {
          visible = pathData.focus === this.currentFilters.focus;
        }

        // Apply visibility
        element.classList.toggle('path-hidden', !visible);

        if (visible) {
          visibleCount++;

          // Highlight search terms
          if (this.currentFilters.search) {
            this.highlightSearchTerms(element, this.currentFilters.search);
          } else {
            this.removeHighlights(element);
          }
        }
      });

      // Update results summary
      this.updateResultsSummary(visibleCount);

      this.log(`Filters applied, ${visibleCount} paths visible`);
    } catch (_error) {
      this.handleError('Failed to apply filters', _error);
    }
  }

  /**
   * Highlight search terms in element
   * @param {HTMLElement} element - Element to highlight
   * @param {string} searchTerm - Search term to highlight
   */
  highlightSearchTerms(element, searchTerm) {
    try {
      // Simple highlighting - wrap search terms in span
      const textNodes = this.getTextNodes(element);

      textNodes.forEach(node => {
        const text = node.textContent;
        if (text.toLowerCase().includes(searchTerm)) {
          const regex = new RegExp(`(${searchTerm})`, 'gi');
          const highlightedText = text.replace(regex, '<mark>$1</mark>');

          if (highlightedText !== text) {
            const wrapper = document.createElement('span');
            wrapper.innerHTML = highlightedText;
            node.parentNode.replaceChild(wrapper, node);
          }
        }
      });
    } catch (_error) {
      this.log('Failed to highlight search terms', _error);
    }
  }

  /**
   * Remove highlights from element
   * @param {HTMLElement} element - Element to remove highlights from
   */
  removeHighlights(element) {
    try {
      const marks = element.querySelectorAll('mark');
      marks.forEach(mark => {
        mark.replaceWith(mark.textContent);
      });
    } catch (_error) {
      this.log('Failed to remove highlights', _error);
    }
  }

  /**
   * Get text nodes from element
   * @param {HTMLElement} element - Element to get text nodes from
   * @returns {Node[]} Text nodes
   */
  getTextNodes(element) {
    const textNodes = [];
    const walker = document.createTreeWalker(
      element,
      window.NodeFilter.SHOW_TEXT,
      null,
      false
    );

    let node;
    while ((node = walker.nextNode())) {
      textNodes.push(node);
    }

    return textNodes;
  }

  /**
   * Update results summary
   * @param {number} visibleCount - Number of visible paths
   */
  updateResultsSummary(visibleCount) {
    try {
      const summary = document.getElementById('results-summary');
      const countElement = summary?.querySelector('.results-count');

      if (countElement) {
        const totalCount = this.pathsData.size;

        if (visibleCount === totalCount) {
          countElement.textContent = `Showing all ${totalCount} paths`;
        } else {
          countElement.textContent = `Showing ${visibleCount} of ${totalCount} paths`;
        }
      }
    } catch (_error) {
      this.handleError('Failed to update results summary', _error);
    }
  }

  /**
   * Destroy the navigator and clean up resources
   */
  destroy() {
    try {
      // Remove all event listeners
      this.boundHandlers.forEach((handlers, element) => {
        handlers.forEach((handler, event) => {
          element.removeEventListener(event, handler);
        });
      });
      this.boundHandlers.clear();

      // Remove enhanced UI
      const enhanced = document.querySelector('.path-navigator-enhanced');
      if (enhanced) {
        enhanced.remove();
      }

      // Remove styles
      const styles = document.getElementById('navigator-styles');
      if (styles) {
        styles.remove();
      }

      // Clear data
      this.pathsData.clear();
      this.filteredPaths = [];

      this.isInitialized = false;
      this.log('Learning paths navigator destroyed');
    } catch (_error) {
      this.handleError('Error destroying navigator', _error);
    }
  }

  /**
   * Log debug messages
   * @param {string} _message - Debug message
   * @param {...any} _args - Additional arguments
   * @private
   */
  log(_message, ..._args) {
    if (this.debug) {
      // Debug logging disabled in production
    }
  }

  /**
   * Handle errors with optional error handler
   * @param {string} message - Error message
   * @param {Error} error - Error object
   * @private
   */
  handleError(_message, _error) {
    if (this.errorHandler && typeof this.errorHandler.safeExecute === 'function') {
      this.errorHandler.safeExecute(() => {
        // Error handling - logging disabled in production
      });
    } else {
      // Error occurred - logging disabled in production
    }
  }
}

// ES6 Module Export
export default LearningPathsNavigator;
