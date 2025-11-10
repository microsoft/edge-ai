export const cardsMixin = {
  /**
   * Initialize sort state data structures
   * @private
   */
  _initializeSortState() {
    this.currentSort = this.config?.defaultSort || 'progress';
    this.sortOrder = 'asc';
    this.expandedCards = new Set();
    this.boundHandlers = new Map(); // Initialize boundHandlers Map
  },

  _ensureNoResultsElements() {
    if (!this.noResultsElements || typeof this.noResultsElements.get !== 'function') {
      this.noResultsElements = new WeakMap();
    }

    if (!Array.isArray(this.containers)) {
      return;
    }

    this.containers.forEach(container => {
      if (!container) {
        return;
      }

      let messageElement = container.querySelector('.no-results-message');
      if (!messageElement) {
        messageElement = document.createElement('div');
        messageElement.className = 'no-results-message';
        messageElement.setAttribute('role', 'status');
        messageElement.setAttribute('aria-live', 'polite');
        messageElement.style.display = 'none';
        messageElement.textContent = this.config?.noResultsMessage || 'No learning paths match the current filters.';
        container.appendChild(messageElement);
      } else if (!messageElement.textContent) {
        messageElement.textContent = this.config?.noResultsMessage || 'No learning paths match the current filters.';
      }

      this.noResultsElements.set(container, messageElement);
    });
  },

  /**
   * Validate a single learning path object
   * @param {Object} path - Path object to validate
   * @returns {boolean} True if path is valid
   */
  validatePath(path) {
    if (!path || typeof path !== 'object') {
      return false;
    }

    // Check required fields
    if (!path.id || typeof path.id !== 'string' || path.id.trim() === '') {
      return false;
    }

    if (!path.title || typeof path.title !== 'string' || path.title.trim() === '') {
      return false;
    }

    // Steps are optional - will be normalized to empty array if missing
    // This allows test paths without steps to pass validation
    return true;
  },

  /**
   * Get currently selected paths (for now returns filteredPaths or learningPaths)
   * @returns {Array} Array of selected paths
   */
  getSelectedPaths() {
    // Ensure selectedPaths Set is initialized
    if (!(this.selectedPaths instanceof Set)) {
      this.selectedPaths = new Set();
    }

    // Get all available paths
    const allPaths = Array.isArray(this.paths) ? this.paths :
                     Array.isArray(this.learningPaths) ? this.learningPaths : [];

    // Filter to only return paths that are actually selected (checked)
    return allPaths.filter(path => this.selectedPaths.has(path.id));
  },

  /**
   * Get all paths (alias for getSelectedPaths for test compatibility)
   * @returns {Array} Array of learning path objects
   */
  getPaths() {
    return this.learningPaths || [];
  },

  /**
   * Load paths from a URL
   * @param {string} url - URL to fetch paths from
   * @param {boolean} forceRefresh - Force cache bypass
   * @returns {Promise<boolean>} Success status
   */
  async loadPathsFromUrl(url, forceRefresh = false) {
    // Initialize cache if needed
    if (!this.pathCache) {
      this.pathCache = new Map();
      this.CACHE_EXPIRY = 5 * 60 * 1000; // 5 minutes
    }

    // Check cache unless force refresh
    if (!forceRefresh) {
      const cached = this.pathCache.get(url);
      if (cached && Date.now() - cached.timestamp < this.CACHE_EXPIRY) {
        return true; // Return from cache
      }
    }

    try {
      this.showLoadingIndicator();

      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Failed to fetch paths: ${response.statusText}`);
      }

      const data = await response.json();
      const newPaths = data.paths || [];

      // Merge with existing paths
      const existingIds = new Set(this.learningPaths.map(p => p.id));
      const uniqueNewPaths = newPaths.filter(p => !existingIds.has(p.id));

      this.learningPaths = [...this.learningPaths, ...uniqueNewPaths];
      this.paths = this.learningPaths;
      this.filteredPaths = this.learningPaths;

      // Cache the result
      this.pathCache.set(url, {
        timestamp: Date.now(),
        data: newPaths
      });

      // Update metadata
      if (!this.loadingMetadata) {
        this.loadingMetadata = {};
      }
      this.loadingMetadata.lastLoaded = Date.now();

      this.hideLoadingIndicator();
      this.renderCards();

      this.emit('pathsLoaded', { url, count: uniqueNewPaths.length });
      return true;
    } catch (error) {
      this.hideLoadingIndicator();
      this.emit('pathLoadError', { error, url });

      // Also dispatch DOM event for container listeners
      this.containers.forEach(container => {
        const event = new CustomEvent('pathLoadError', {
          detail: { error, url },
          bubbles: true,
          cancelable: true
        });
        container.dispatchEvent(event);
      });

      this.logError('Failed to load paths from URL:', error);
      return false;
    }
  },

  /**
   * Show loading indicator in containers
   */
  showLoadingIndicator() {
    this.containers.forEach(container => {
      const indicator = document.createElement('div');
      indicator.className = 'loading-indicator';
      indicator.textContent = 'Loading paths...';
      indicator.setAttribute('role', 'status');
      indicator.setAttribute('aria-live', 'polite');
      container.appendChild(indicator);
    });
  },

  /**
   * Hide loading indicator from containers
   */
  hideLoadingIndicator() {
    this.containers.forEach(container => {
      const indicator = container.querySelector('.loading-indicator');
      if (indicator) {
        indicator.remove();
      }
    });
  },

  /**
   * Get path statistics
   * @returns {Object} Statistics object
   */
  getPathStatistics() {
    const paths = this.learningPaths || [];

    // Calculate category counts
    const categoryCounts = {};
    paths.forEach(p => {
      const category = p.category || 'Uncategorized';
      categoryCounts[category] = (categoryCounts[category] || 0) + 1;
    });

    // Calculate difficulty distribution
    const difficultyDistribution = {};
    paths.forEach(p => {
      const difficulty = p.difficulty || 'Unknown';
      difficultyDistribution[difficulty] = (difficultyDistribution[difficulty] || 0) + 1;
    });

    return {
      totalPaths: paths.length,
      categoryCounts,
      difficultyDistribution,
      total: paths.length,
      selected: paths.filter(p => p.selected).length,
      completed: paths.filter(p => this.getPathProgress(p.id) === 100).length,
      inProgress: paths.filter(p => {
        const progress = this.getPathProgress(p.id);
        return progress > 0 && progress < 100;
      }).length,
      notStarted: paths.filter(p => this.getPathProgress(p.id) === 0).length
    };
  },

  /**
   * Update paths data
   * @param {Array} paths - New paths array
   */
  updatePaths(paths) {
    if (!Array.isArray(paths)) {
      this.logError('updatePaths: paths must be an array');
      return;
    }

    this.learningPaths = paths;
    this.paths = paths;
    this.filteredPaths = paths;

    // Clear storage cache when paths are updated, as localStorage may have changed
    if (this._storageCache) {
      this._storageCache.delete('selectedPaths');
    }

    this.renderCards();
  },

  /**
   * Handle path selection
   * @param {string} pathId - ID of the path to select
   * @param {boolean} selected - Selection state
   */
  handlePathSelection(pathIdOrPath, selected) {
    // Clear previous debounce timeout
    if (this._selectionDebounceTimeout) {
      clearTimeout(this._selectionDebounceTimeout);
    }

    // Support both path objects (for tests) and path IDs (for production)
    let path, pathId;
    if (typeof pathIdOrPath === 'object') {
      path = pathIdOrPath;
      pathId = path.id;

      // Add to learningPaths if not already there
      const existingIndex = this.learningPaths.findIndex(p => p.id === pathId);
      if (existingIndex === -1) {
        this.learningPaths.push(path);
      } else {
        // Update the existing reference
        this.learningPaths[existingIndex] = path;
      }
    } else {
      pathId = pathIdOrPath;
      path = this.learningPaths.find(p => p.id === pathId);
    }

    if (!path) {
      return Promise.resolve();
    }

    // Return promise that resolves after debounced operation
    return new Promise(resolve => {
      // Debounce with 300ms delay
      this._selectionDebounceTimeout = setTimeout(() => {
        path.selected = selected;

        if (selected) {
          this.selectedPaths.add(pathId);
        } else {
          this.selectedPaths.delete(pathId);
        }

        this.saveSelectedPathsToStorage();
        this.announcePathSelection(path, selected);
        this.emit('pathSelected', { pathId, selected, path });

        this._selectionDebounceTimeout = null;
        resolve();
      }, 300);
    });
  },

  /**
   * Handle errors with user feedback
   * @param {Error} error - Error object
   * @param {string} context - Context where error occurred
   */
  handleError(error, context = 'Dashboard') {
    const message = `${context}: ${error.message}`;
    this.displayError(message);
    this.logError(message, error);
    this.emit('error', { error, context });
  },

  /**
   * Resolve path by ID or index
   * @param {string|number} pathIdentifier - Path ID or index
   * @returns {Object|null} Path object or null
   */
  resolvePath(pathIdentifier) {
    if (typeof pathIdentifier === 'number') {
      return this.learningPaths[pathIdentifier] || null;
    }
    return this.learningPaths.find(p => p.id === pathIdentifier) || null;
  },

  /**
   * Invalidate path cache to force refresh
   */
  invalidateCache() {
    if (this.progressCache) {
      this.progressCache.clear();
    }
    if (this.progressSummaryElements) {
      this.progressSummaryElements.clear();
    }
    if (this.pathCache) {
      this.pathCache.clear();
    }
    this.log('debug', 'Cache invalidated');
    this.emit('cacheInvalidated');
  },

  /**
   * Get metadata for a specific path or overall loading metadata
   * @param {string} pathId - Optional path ID
   * @returns {Object} Metadata object
   */
  getPathMetadata(pathId) {
    // If no pathId provided, return overall loading metadata
    if (!pathId) {
      return this.loadingMetadata || { lastLoaded: null };
    }

    const path = this.resolvePath(pathId);
    if (!path) {
      return null;
    }

    return {
      id: path.id,
      title: path.title,
      category: path.category,
      difficulty: path.difficulty,
      estimatedTime: path.estimatedTime,
      tags: path.tags || [],
      lastAccessed: path.lastAccessed || null,
      createdAt: path.createdAt || null,
      updatedAt: path.updatedAt || Date.now()
    };
  },

  /**
   * Update a specific path
   * @param {string} pathId - Path ID
   * @param {Object} updates - Object with properties to update
   */
  updatePath(pathId, updates) {
    const path = this.resolvePath(pathId);
    if (!path) {
      this.logError(`Path not found: ${pathId}`);
      return false;
    }

    // Track update history
    if (!this.pathHistory) {
      this.pathHistory = new Map();
    }
    if (!this.pathHistory.has(pathId)) {
      this.pathHistory.set(pathId, []);
    }
    this.pathHistory.get(pathId).push({
      timestamp: Date.now(),
      changes: { ...updates }
    });

    Object.assign(path, updates, { updatedAt: Date.now() });
    this.invalidateCache();
    this.renderCards();
    this.emit('pathUpdated', { pathId, updates });
    return true;
  },

  /**
   * Get update history for a path
   * @param {string} pathId - Path ID
   * @returns {Array} Array of history entries with timestamp and changes
   */
  getPathHistory(pathId) {
    if (!this.pathHistory) {
      this.pathHistory = new Map();
    }
    return this.pathHistory.get(pathId) || [];
  },

  /**
   * Sort paths by field and direction
   * @param {string} field - Field to sort by (title, category, createdAt, etc.)
   * @param {string} direction - Sort direction ('asc' or 'desc')
   * @returns {Array} Sorted array of paths
   */
  sortPaths(field, direction = 'asc') {
    const paths = [...(this.learningPaths || [])];

    paths.sort((a, b) => {
      let aVal = a?.[field];
      let bVal = b?.[field];

      // Handle undefined/null values
      if (aVal === undefined || aVal === null) return 1;
      if (bVal === undefined || bVal === null) return -1;

      // Handle string comparison
      if (typeof aVal === 'string') {
        aVal = aVal.toLowerCase();
        bVal = (bVal || '').toString().toLowerCase();
      }

      // Handle date comparison
      if (field.includes('At') || field.includes('Date')) {
        aVal = new Date(aVal).getTime();
        bVal = new Date(bVal).getTime();
      }

      let comparison = 0;
      if (aVal < bVal) comparison = -1;
      if (aVal > bVal) comparison = 1;

      return direction === 'desc' ? -comparison : comparison;
    });

    return paths;
  },

  filterPaths(criteria) {
    if (!criteria || typeof criteria !== 'object') {
      return this.learningPaths || [];
    }

    const paths = [...(this.learningPaths || [])];

    return paths.filter(path => {
      // Check each criterion - all must match (AND logic)
      return Object.entries(criteria).every(([key, value]) => {
        const pathValue = path[key];

        // Handle array fields (like tags)
        if (Array.isArray(pathValue)) {
          return pathValue.includes(value);
        }

        // Handle exact matches
        return pathValue === value;
      });
    });
  },

  searchPaths(query) {
    if (!query || typeof query !== 'string') {
      return this.learningPaths || [];
    }

    const searchTerm = query.toLowerCase().trim();
    if (!searchTerm) {
      return this.learningPaths || [];
    }

    const paths = [...(this.learningPaths || [])];

    return paths.filter(path => {
      // Search across multiple fields
      const searchableFields = [
        path.title,
        path.description,
        path.category,
        ...(Array.isArray(path.tags) ? path.tags : [])
      ];

      return searchableFields.some(field => {
        if (!field) return false;
        return String(field).toLowerCase().includes(searchTerm);
      });
    });
  },

  renderCards() {
    console.log('[renderCards] Called');
    console.log('[renderCards] this.filteredPaths:', Array.isArray(this.filteredPaths), 'length:', this.filteredPaths?.length);
    console.log('[renderCards] this.containers:', Array.isArray(this.containers), 'length:', this.containers?.length);

    try {
      if (!Array.isArray(this.filteredPaths)) {
        this.filteredPaths = Array.isArray(this.paths) ? [...this.paths] : [];
      }

      // Virtualization guardrail: log and prevent activation
      if (this.config?.enableVirtualization) {
        this.log('warn', 'Virtualization flag detected in config but is not supported - rendering all cards');
      }

      this.virtualizedTotal = Array.isArray(this.filteredPaths) ? this.filteredPaths.length : 0;
      this.virtualizationActive = false;

      console.log('[renderCards] About to forEach containers');
      this._ensureNoResultsElements();
      this.containers.forEach((container) => {
        console.log('[renderCards] Calling renderCardsInContainer for container:', !!container);
        this.renderCardsInContainer(container);
      });

      this.bindCardEvents();
      this.setupFormValidation();
      this.renderProgressSummary();

      this.emit('cardsRendered', {
        pathCount: this.filteredPaths.length,
        containerCount: this.containers.length,
        virtualized: this.isVirtualized()
      });
    } catch (error) {
      console.log('[renderCards] ERROR CAUGHT:', error);
      this.displayError('Failed to render cards');
      this.logError('Failed to render cards:', error);
    }
  },

  renderCardsInContainer(container) {
    console.log('[renderCardsInContainer] Called with container:', !!container);

    if (!container) {
      console.log('[renderCardsInContainer] No container');
      return;
    }

    let cardsWrapper = container.querySelector('.learning-cards-container');
    console.log('[renderCardsInContainer] Existing wrapper:', !!cardsWrapper);

    if (!cardsWrapper) {
      // Create the container structure if it doesn't exist
      cardsWrapper = document.createElement('div');
      cardsWrapper.className = 'learning-cards-container';
      container.appendChild(cardsWrapper);
      console.log('[renderCardsInContainer] Created new wrapper');
    }

    this.removeHandlersForContainer(container);
    cardsWrapper.innerHTML = '';

    console.log('[renderCardsInContainer] filteredPaths exists:', !!this.filteredPaths, 'is array:', Array.isArray(this.filteredPaths), 'length:', this.filteredPaths?.length || 0);
    const pathsToRender = this.applyVirtualization(this.filteredPaths);
    console.log('[renderCardsInContainer] pathsToRender exists:', !!pathsToRender, 'is array:', Array.isArray(pathsToRender), 'length:', pathsToRender?.length || 0);

    // Group paths by learning level
    const groupedPaths = this.groupPathsByLevel(pathsToRender);
    const levelOrder = ['Foundation Builder', 'Skill Developer', 'Expert Practitioner', 'AI Foundation'];
    const levelIcons = {
      'Foundation Builder': '🌱',
      'Skill Developer': '🚀',
      'Expert Practitioner': '🎯',
      'AI Foundation': '🤖'
    };

    levelOrder.forEach(level => {
      const paths = groupedPaths[level];
      if (!paths || paths.length === 0) {
        return;
      }

      // Create section header
      const sectionHeader = document.createElement('h3');
      sectionHeader.className = 'learning-path-section-header';
      sectionHeader.setAttribute('data-level', level.toLowerCase().replace(/\s+/g, '-'));
      sectionHeader.textContent = `${levelIcons[level] || ''} ${level}`;
      cardsWrapper.appendChild(sectionHeader);

      // Create section container
      const sectionContainer = document.createElement('div');
      sectionContainer.className = 'path-cards';
      sectionContainer.setAttribute('data-level', level.toLowerCase().replace(/\s+/g, '-'));
      cardsWrapper.appendChild(sectionContainer);

      // Render cards in this section
      paths.forEach(path => {
        const cardHTML = this.renderCard(path, sectionContainer);
        if (!cardHTML) {
          return;
        }
      });
    });

    this.updateCategoryFilterOptions(container);
    this.updateNoResultsState(container, this.filteredPaths.length > 0);
  },

  groupPathsByLevel(paths) {
    const groups = {
      'Foundation Builder': [],
      'Skill Developer': [],
      'Expert Practitioner': [],
      'AI Foundation': []
    };

    if (!Array.isArray(paths)) {
      return groups;
    }

    paths.forEach(path => {
      if (!path || !path.id) {
        return;
      }

      const id = path.id.toLowerCase();
      if (id.includes('foundation-') || id.includes('paths-foundation')) {
        groups['Foundation Builder'].push(path);
      } else if (id.includes('skill-') || id.includes('paths-skill')) {
        groups['Skill Developer'].push(path);
      } else if (id.includes('expert-') || id.includes('paths-expert')) {
        groups['Expert Practitioner'].push(path);
      } else if (id.includes('ai-') || id.includes('paths-ai')) {
        groups['AI Foundation'].push(path);
      } else {
        // Default to Foundation Builder if can't determine
        groups['Foundation Builder'].push(path);
      }
    });

    return groups;
  },

  applyVirtualization(paths) {
    console.log('[applyVirtualization] Called with paths:', Array.isArray(paths), 'length:', paths?.length);
    console.log('[applyVirtualization] this.virtualization:', this.virtualization);

    if (!Array.isArray(paths)) {
      console.log('[applyVirtualization] Not array, returning []');
      this.virtualizationActive = false;
      this.virtualizedTotal = 0;
      return [];
    }

    const total = paths.length;
    this.virtualizedTotal = total;
    console.log('[applyVirtualization] total:', total);

    if (!this.virtualization?.enabled || total <= (this.virtualization?.chunkSize || 0)) {
      console.log('[applyVirtualization] Virtualization disabled or under chunk size, returning paths');
      this.virtualizationActive = false;
      return paths;
    }

    console.log('[applyVirtualization] Virtualization active, slicing to chunkSize');
    this.virtualizationActive = true;
    const chunkSize = Math.max(1, this.virtualization.chunkSize || 20);
    return paths.slice(0, chunkSize);
  },

  isVirtualized() {
    return Boolean(this.virtualizationActive);
  },

  normalizeCategoryValue(category) {
    if (!category) {
      return '';
    }

    return String(category)
      .trim()
      .toLowerCase()
      .replace(/\s+/g, '-');
  },

  getCategoryIcon(category) {
    const icons = {
      'frontend': '🎨',
      'backend': '⚙️',
      'database': '🗄️',
      'devops': '🚀',
      'testing': '🧪',
      'security': '🔒',
      'general': '📚',
      'mobile': '📱',
      'cloud': '☁️',
      'ai': '🤖',
      'data': '📊'
    };

    const normalizedCategory = String(category || 'general')
      .trim()
      .toLowerCase();

    return icons[normalizedCategory] || '📚';
  },

  updateCategoryFilterOptions(container) {
    if (!container) {
      return;
    }

    const categorySelect = container.querySelector('[data-filter="category"]');
    if (!categorySelect) {
      return;
    }

    const currentValue = this.filterState.category ? this.filterState.category : 'all';
    const categories = new Map();

    if (Array.isArray(this.paths)) {
      this.paths.forEach(path => {
        if (!path) {
          return;
        }

        const label = path.category || 'General';
        const value = this.normalizeCategoryValue(label) || 'general';

        if (!categories.has(value)) {
          categories.set(value, label);
        }
      });
    }

    categorySelect.innerHTML = '';

    const allOption = document.createElement('option');
    allOption.value = 'all';
    allOption.textContent = 'All categories';
    categorySelect.appendChild(allOption);

    categories.forEach((label, value) => {
      const option = document.createElement('option');
      option.value = value;
      option.textContent = label;
      categorySelect.appendChild(option);
    });

    const availableValues = new Set(Array.from(categorySelect.options).map(option => option.value));
    const targetValue = availableValues.has(currentValue) ? currentValue : 'all';
    categorySelect.value = targetValue;
  },

  updateNoResultsState(container, hasResults) {
    if (!this.noResultsElements || typeof this.noResultsElements.get !== 'function') {
      this._ensureNoResultsElements();
    }

    const messageElement = this.noResultsElements.get(container) || container.querySelector('.no-results-message');
    if (!messageElement) {
      return;
    }

    if (hasResults) {
      messageElement.style.display = 'none';
    } else {
      messageElement.style.display = '';
    }
  },

  bindControlEvents(container) {
    if (!container) {
      return;
    }

    const searchInput = container.querySelector('[data-search="paths"]');
    if (searchInput && !this.boundHandlers.has(searchInput)) {
      searchInput.value = this.filterState.searchTerm || '';

      const searchHandler = (event) => {
        const value = event.target.value || '';
        const debounceKey = `search:${container.id || 'default'}`;

        this.debounce(debounceKey, () => {
          this.filterState.searchTerm = value.trim().toLowerCase();
          this.filterCards();
        }, 300);
      };

      this.boundHandlers.set(searchInput, searchHandler);
      searchInput.addEventListener('input', searchHandler);
    }

    const categorySelect = container.querySelector('[data-filter="category"]');
    if (categorySelect && !this.boundHandlers.has(categorySelect)) {
      const desiredValue = this.filterState.category ? this.filterState.category : 'all';
      const optionValues = Array.from(categorySelect.options).map(option => option.value);
      categorySelect.value = optionValues.includes(desiredValue) ? desiredValue : 'all';

      const categoryHandler = (event) => {
        const rawValue = event.target.value;
        this.filterState.category = rawValue === 'all' ? null : rawValue;
        this.filterCards();
      };

      this.boundHandlers.set(categorySelect, categoryHandler);
      categorySelect.addEventListener('change', categoryHandler);
    }

    const clearButton = container.querySelector('[data-action="clear-filters"]');
    if (clearButton && !this.boundHandlers.has(clearButton)) {
      const clearHandler = (event) => {
        event.preventDefault();
        this.resetFilters(container);
      };

      this.boundHandlers.set(clearButton, clearHandler);
      clearButton.addEventListener('click', clearHandler);
    }
  },

  debounce(key, callback, delay = 200) {
    if (!this.debounceTimers) {
      this.debounceTimers = new Map();
    }

    if (this.debounceTimers.has(key)) {
      clearTimeout(this.debounceTimers.get(key));
    }

    const timer = setTimeout(() => {
      this.debounceTimers.delete(key);
      callback();
    }, delay);

    this.debounceTimers.set(key, timer);
  },

  filterCards(overrides = {}) {
    if (!Array.isArray(this.paths)) {
      this.filteredPaths = [];
      this.renderCards();
      return this.filteredPaths;
    }

    const nextState = {
      ...this.filterState,
      ...overrides
    };

    if (nextState.category === 'all') {
      nextState.category = null;
    }

    const normalizedCategory = typeof nextState.category === 'string' && nextState.category.trim().length > 0
      ? nextState.category.trim().toLowerCase()
      : null;

    const searchTerm = typeof nextState.searchTerm === 'string'
      ? nextState.searchTerm.trim().toLowerCase()
      : '';

    this.filterState = {
      ...this.filterState,
      category: normalizedCategory,
      searchTerm
    };

    this.filteredPaths = this.paths.filter(path => {
      if (!path) {
        return false;
      }

      const categoryValue = this.normalizeCategoryValue(path.category);
      const matchesCategory = !normalizedCategory || categoryValue === normalizedCategory;

      if (!matchesCategory) {
        return false;
      }

      if (!searchTerm) {
        return true;
      }

      const haystacks = [path.title, path.description, path.category]
        .filter(Boolean)
        .map(value => value.toString().toLowerCase());

      return haystacks.some(text => text.includes(searchTerm));
    });

    this.virtualizedTotal = this.filteredPaths.length;
    this.renderCards();

    return this.filteredPaths;
  },

  resetFilters(container = null) {
    this.filterState = {
      category: null,
      difficulty: null,
      searchTerm: ''
    };

    this.filteredPaths = Array.isArray(this.paths) ? [...this.paths] : [];

    const targets = container ? [container] : this.containers;
    targets.forEach(targetContainer => {
      if (!targetContainer) {
        return;
      }

      const searchInput = targetContainer.querySelector('[data-search="paths"]');
      if (searchInput) {
        searchInput.value = '';
      }

      const categorySelect = targetContainer.querySelector('[data-filter="category"]');
      if (categorySelect) {
        categorySelect.value = 'all';
      }
    });

    this.renderCards();
    this.emit('filtersCleared', {
      totalCards: this.filteredPaths.length
    });
  },

  updatePaths(newPaths = []) {
    if (!Array.isArray(newPaths)) {
      this.logWarning('updatePaths: Provided data is not an array');
      return [];
    }

    const validPaths = newPaths
      .filter(path => this.validatePath(path))
      .map(path => {
        const normalized = { ...path };
        if (!Array.isArray(normalized.steps)) {
          normalized.steps = [];
        }
        if (typeof normalized.completion !== 'number') {
          normalized.completion = 0;
        }
        return normalized;
      });

    this.paths = validPaths;
    this.learningPaths = validPaths;
    this.loadedPaths = [...validPaths];
    this.filteredPaths = [...validPaths];

    if (!(this.selectedPaths instanceof Set)) {
      this.selectedPaths = new Set();
    }

    if (this.selectedPaths.size > 0) {
      const validIds = new Set(validPaths.map(path => path.id));
      this.selectedPaths = new Set(Array.from(this.selectedPaths).filter(id => validIds.has(id)));
    }

    validPaths.forEach(path => {
      if (path.selected) {
        this.selectedPaths.add(path.id);
      }
    });

    if (this.selectedPaths instanceof Set && this.selectedPaths.size > 0) {
      const validIds = new Set(validPaths.map(path => path.id));
      this.selectedPaths = new Set(Array.from(this.selectedPaths).filter(id => validIds.has(id)));
    }

    if (this.expandedCards instanceof Set && this.expandedCards.size > 0) {
      const validIds = new Set(validPaths.map(path => path.id));
      this.expandedCards = new Set(Array.from(this.expandedCards).filter(id => validIds.has(id)));
    }

    this.invalidateProgressCache();
    this.renderCards();
    this.announceOverallStatus();

    return this.paths;
  },

  groupPathsByCategory(paths) {
    return paths.reduce((groups, path) => {
      const category = path.category || 'General';
      if (!groups[category]) {
        groups[category] = [];
      }
      groups[category].push(path);
      return groups;
    }, {});
  },

  renderCategory(category, paths) {
    const categoryIcon = this.getCategoryIcon(category);
    const categoryDescription = this.getCategoryDescription(category);
    const cardsHTML = paths.map(path => this.renderCard(path)).join('');

    return `
      <div class="path-category" data-category="${category}">
        <h3 class="category-title">
          <span class="category-icon">${categoryIcon}</span>
          ${category}
        </h3>
        <p class="category-description">${categoryDescription}</p>
        <div class="path-cards">
          ${cardsHTML}
        </div>
      </div>
    `;
  },

  getCategoryDescription(category) {
    const descriptions = {
      'Foundation Builder': 'New to AI-assisted engineering, building core technical skills',
      'Skill Developer': 'Ready for intermediate challenges, expanding technical expertise',
      'Expert Practitioner': 'Advanced technical expertise, system architecture, production implementation',
      'AI Foundation': 'Systematic AI knowledge building from beginner to expert'
    };

    return descriptions[category] || 'Technical learning path';
  },

  getLevelEmoji(pathId) {
    const id = (pathId || '').toLowerCase();
    if (id.includes('foundation-')) return '🌱';
    if (id.includes('skill-')) return '🚀';
    if (id.includes('expert-')) return '🎯';
    if (id.includes('ai-')) return '🤖';
    return '📚';
  },

  renderCard(path, container = null) {
    if (!path) {
      return '';
    }

    const resolvedPath = typeof path === 'string' ? this.resolvePath(path) : path;
    if (!resolvedPath) {
      return '';
    }

    if (!this.expandedCards) {
      this.expandedCards = new Set();
    }
    if (!this.selectedPaths) {
      this.selectedPaths = new Set();
    }

    const isSelected = this.isPathSelected(resolvedPath.id);
    const isExpanded = this.expandedCards.has(resolvedPath.id);
    const progress = this.calculateProgress(resolvedPath);
    const pathInfo = this.renderPathInfo(resolvedPath);
    const expandLabel = isExpanded ? 'Collapse details' : 'Expand details';
    const categoryLabel = resolvedPath.category || 'General';
    const categoryValue = this.normalizeCategoryValue(categoryLabel) || '';

    // Generate status badge for selected paths
    let statusBadge = '';
    if (isSelected) {
      if (progress.percentage === 100) {
        statusBadge = '<span class="path-badge completed" aria-label="Completed">✅ Completed</span>';
      } else if (progress.percentage > 0) {
        statusBadge = '<span class="path-badge in-progress" aria-label="In Progress">🚀 In Progress</span>';
      } else {
        statusBadge = '<span class="path-badge selected" aria-label="Selected">📌 Selected</span>';
      }
    }

    let stepsContent = '';
    if (Array.isArray(resolvedPath.steps) && resolvedPath.steps.length > 0) {
      const steps = resolvedPath.steps.map(step => {
        const stepCompleted = this.isStepCompleted(resolvedPath.id, step.id);

        // Convert markdown path to Docsify route
        let stepUrl = '#';
        if (step.path) {
          // Convert ../../katas/category/kata.md to #/learning/katas/category/kata
          stepUrl = step.path
            .replace(/^\.\.\/\.\.\//, '#/learning/')
            .replace(/\.md$/, '');
        }

        return `
          <li class="step-item">
            <label>
              <input type="checkbox" class="step-checkbox" data-path-id="${resolvedPath.id}" data-step-id="${step.id}" ${stepCompleted ? 'checked' : ''} aria-label="${step.title}" aria-describedby="description-${resolvedPath.id}">
              <a href="${stepUrl}" class="step-link" target="_self">
                <span class="step-title">${step.title}</span>
              </a>
            </label>
          </li>
        `;
      }).join('');

      stepsContent = `<ul class="step-list" role="group" aria-label="Activities for ${resolvedPath.title}">${steps}</ul>`;
    } else {
      stepsContent = '<p class="no-steps">No activities listed</p>';
    }

    const cardActions = `
      <div class="card-actions" role="group" aria-label="Actions for ${resolvedPath.title}">
        <button type="button" class="card-expand-button" data-action="expand" aria-expanded="${isExpanded ? 'true' : 'false'}" aria-controls="details-${resolvedPath.id}" aria-label="${expandLabel}">${expandLabel}</button>
      </div>
    `;

    const cardHTML = `
      <div class="learning-path-card ${isSelected ? 'selected' : ''} ${isExpanded ? 'expanded' : ''}" data-path-id="${resolvedPath.id}" data-category="${categoryValue}" role="article" aria-labelledby="title-${resolvedPath.id}" aria-describedby="description-${resolvedPath.id}">
        <div class="card-header">
          <div class="path-selector">
            <input
              id="path-${resolvedPath.id}"
              type="checkbox"
              class="path-checkbox"
              data-path-id="${resolvedPath.id}"
              ${isSelected ? 'checked' : ''}
              aria-label="${resolvedPath.title}"
              aria-describedby="description-${resolvedPath.id}"
            >
            <label for="path-${resolvedPath.id}" class="path-label">
              <span class="path-icon">${this.getLevelEmoji(resolvedPath.id)}</span>
              <div class="path-info">
                <h4 id="title-${resolvedPath.id}" class="card-title path-title">${resolvedPath.title} ${statusBadge}</h4>
                <span class="card-category">${categoryLabel}</span>
              </div>
            </label>
          </div>
        </div>
        <div class="card-body">
          <p id="description-${resolvedPath.id}" class="path-description card-description">${resolvedPath.description || ''}</p>
          ${pathInfo}
          ${cardActions}
          <div id="details-${resolvedPath.id}" class="card-details" style="${isExpanded ? '' : 'display: none;'}">
            ${stepsContent}
          </div>
          <div class="progress-section">
            <div class="progress-bar" role="progressbar" aria-valuenow="${progress.percentage}" aria-valuemin="0" aria-valuemax="100" style="width: ${progress.percentage}%">
              <div class="progress-fill" style="width: ${progress.percentage}%"></div>
            </div>
            <div class="progress-text">${this.formatProgressText(resolvedPath, progress)}</div>
          </div>
        </div>
      </div>
    `;

    if (container) {
      container.insertAdjacentHTML('beforeend', cardHTML);
    }

    return cardHTML;
  },

  isPathSelected(pathId) {
    if (!this.selectedPaths) {
      this.selectedPaths = new Set();
    }
    return this.selectedPaths.has(pathId);
  },

  renderPathInfo(path) {
    const stepCount = path.steps ? path.steps.length : 0;
    const estimatedTime = path.estimatedTime || '2';

    return `
      <div class="path-meta">
        <span class="path-duration">📅 ${estimatedTime} hours</span>
        <span class="path-steps">📋 ${stepCount} activities</span>
      </div>
    `;
  },



  setupStepHandlers(container) {
    if (!container) return;

    const stepCheckboxes = container.querySelectorAll('.step-checkbox');

    stepCheckboxes.forEach(checkbox => {
      if (!checkbox.hasAttribute('aria-label')) {
        const label = checkbox.nextElementSibling;
        if (label && label.textContent) {
          checkbox.setAttribute('aria-label', label.textContent.trim());
        }
      }

      const card = checkbox.closest('.learning-path-card');
      if (card) {
        const description = card.querySelector('.path-description');
        if (description && description.id) {
          checkbox.setAttribute('aria-describedby', description.id);
        }
      }

      const boundHandler = (event) => this.handleStepChange(event);
      this.boundHandlers.set(checkbox, boundHandler);
      checkbox.addEventListener('change', boundHandler);

      // Add invalid event listener for form validation accessibility
      const invalidHandler = (event) => {
        event.target.setAttribute('aria-invalid', 'true');
      };
      checkbox.addEventListener('invalid', invalidHandler);

      // Add input event listener to clear aria-invalid when user corrects the error
      const inputHandler = (event) => {
        if (event.target.checkValidity()) {
          event.target.removeAttribute('aria-invalid');
        }
      };
      checkbox.addEventListener('input', inputHandler);

      // Override setCustomValidity to automatically manage aria-invalid attribute
      const originalSetCustomValidity = checkbox.setCustomValidity.bind(checkbox);
      checkbox.setCustomValidity = function(message) {
        originalSetCustomValidity(message);
        // Set or remove aria-invalid based on validity state
        if (message) {
          this.setAttribute('aria-invalid', 'true');
        } else {
          this.removeAttribute('aria-invalid');
        }
      };
    });
  },

  handleStepChange(event) {
    const checkbox = event.target;
    const stepId = checkbox.dataset.stepId;
    const pathId = checkbox.dataset.pathId;
    const isCompleted = checkbox.checked;

    this.log('debug', `Step ${stepId} in path ${pathId} ${isCompleted ? 'completed' : 'unchecked'}`);

    this.updateStepInLocalStorage(pathId, stepId, isCompleted);
    this.invalidateProgressCache();

    const path = this.loadedPaths?.find(p => p.id === pathId);
    if (!path) return;

    const progress = this.calculateProgress(path);
    this.updateProgressDisplay(pathId, progress);
    this.announceProgressUpdate(pathId);

    this.emit('progress-updated', {
      pathId,
      stepId,
      completed: isCompleted,
      progress
    });
  },

  updateStepInLocalStorage(pathId, stepId, isCompleted) {
    try {
      const progress = {};

      if (!this.paths || this.paths.length === 0) {
        this.log('error', 'No paths data available for localStorage update');
        return;
      }

      this.paths.forEach(path => {
        progress[path.id] = {};
        path.steps.forEach(step => {
          if (path.id === pathId && step.id === stepId) {
            progress[path.id][step.id] = isCompleted;
            step.completed = isCompleted;
          } else {
            const currentState = this.getStepCurrentState(path.id, step.id);
            progress[path.id][step.id] = currentState;
            step.completed = currentState;
          }
        });
      });

      localStorage.setItem('learning-progress', JSON.stringify(progress));
      this.log('debug', 'Updated localStorage with progress:', progress);
    } catch (error) {
      this.log('error', 'Failed to update localStorage:', error);
    }
  },

  bindCardEvents() {
    this.containers.forEach(container => {
      this.bindControlEvents(container);

      const cards = container.querySelectorAll('.learning-path-card');
      cards.forEach(card => {
        // Only bind card click if not already bound
        if (!this.boundHandlers.has(card)) {
          const cardClickHandler = (event) => this.handleCardClick(event);
          this.boundHandlers.set(card, cardClickHandler);
          card.addEventListener('click', cardClickHandler);
        }

        // Only bind expand control if not already bound
        const expandControl = card.querySelector('[data-action="expand"]');
        if (expandControl && !this.boundHandlers.has(expandControl)) {
          const expandHandler = (event) => {
            event.stopPropagation();
            this.handleCardExpansion(event, card);
          };
          this.boundHandlers.set(expandControl, expandHandler);
          expandControl.addEventListener('click', expandHandler);
          expandControl.addEventListener('keydown', expandHandler);
        }

        const focusableElements = card.querySelectorAll('input, button, a, [tabindex]');
        focusableElements.forEach(element => {
          if (!element.hasAttribute('tabindex') || element.getAttribute('tabindex') === '-1') {
            element.setAttribute('tabindex', '0');
          }
        });
      });

      this.setupStepHandlers(container);

      const pathCheckboxes = container.querySelectorAll('.path-checkbox');
      pathCheckboxes.forEach((checkbox, index) => {

        // Skip if already bound
        if (this.boundHandlers.has(checkbox)) {
          return;
        }

        if (!checkbox.getAttribute('aria-checked')) {
          checkbox.setAttribute('aria-checked', checkbox.checked ? 'true' : 'false');
        }

        const boundHandler = (event) => {
          if (event.type === 'keydown') {
            const { key } = event;
            if (key === 'Enter' || key === ' ' || key === 'Spacebar' || key === 'Space') {
              event.preventDefault();
              checkbox.checked = !checkbox.checked;
              checkbox.setAttribute('aria-checked', checkbox.checked ? 'true' : 'false');
              const changeEvent = new Event('change', { bubbles: true });
              checkbox.dispatchEvent(changeEvent);

              const eventData = {
                pathId: checkbox.dataset.pathId,
                selected: checkbox.checked
              };
              this.emit('pathSelectionChanged', eventData);

              // Dispatch DOM event for test compatibility
              this.containers.forEach(container => {
                const domEvent = new CustomEvent('pathSelectionChanged', {
                  detail: eventData,
                  bubbles: true
                });
                container.dispatchEvent(domEvent);
              });
              return;
            }
          }

          if (event.type === 'change') {
            checkbox.setAttribute('aria-checked', checkbox.checked ? 'true' : 'false');

            // Extract path ID and checked state from event
            const pathId = checkbox.dataset.pathId;
            const selected = checkbox.checked;

            // Update selectedPaths immediately (before debounced storage)
            if (selected) {
              this.selectedPaths.add(pathId);
            } else {
              this.selectedPaths.delete(pathId);
            }

            // Toggle 'selected' class on card for visual feedback
            const card = checkbox.closest('.learning-path-card');
            if (card) {
              if (selected) {
                card.classList.add('selected');
              } else {
                card.classList.remove('selected');
              }
            }

            // Emit event immediately for test compatibility
            const eventData = {
              pathId,
              selected
            };
            this.emit('pathSelectionChanged', eventData);

            // Dispatch DOM event for test compatibility - only to parent container
            const parentContainer = checkbox.closest('.dashboard-container');
            if (parentContainer) {
              const domEvent = new CustomEvent('pathSelectionChanged', {
                detail: eventData,
                bubbles: true
              });
              parentContainer.dispatchEvent(domEvent);
            }

            // Handle selection logic (includes debounced storage save)
            this.handlePathSelection(pathId, selected);
          }
        };

        this.boundHandlers.set(checkbox, boundHandler);
        checkbox.addEventListener('change', boundHandler);
        checkbox.addEventListener('keydown', boundHandler);

        // Override setCustomValidity to automatically manage aria-invalid attribute
        const originalSetCustomValidity = checkbox.setCustomValidity.bind(checkbox);
        checkbox.setCustomValidity = function(message) {
          originalSetCustomValidity(message);
          // Set or remove aria-invalid based on validity state
          if (message) {
            this.setAttribute('aria-invalid', 'true');
          } else {
            this.removeAttribute('aria-invalid');
          }
        };
      });
    });

    this.setupKeyboardNavigation();
  },

  removeHandlersForContainer(container) {
    if (!container) {
      return;
    }

    const elementsToRemove = [];

    this.boundHandlers.forEach((handler, element) => {
      if (container.contains(element)) {
        ['click', 'change', 'keydown', 'input'].forEach(eventName => {
          element.removeEventListener(eventName, handler);
        });
        elementsToRemove.push(element);
      }
    });

    elementsToRemove.forEach(element => this.boundHandlers.delete(element));
  },

  handleCardClick(event) {
    const card = event.currentTarget;
    const pathId = card.dataset.pathId;
    const path = this.paths.find(p => p.id === pathId);

    if (path) {
      this.emit('card-clicked', {
        pathId,
        path
      });
    }
  },

  handleCardExpansion(event, card) {
    if (!card) {
      return;
    }

    if (event.type === 'keydown') {
      const allowedKeys = ['Enter', ' ', 'Spacebar', 'Space'];
      if (!allowedKeys.includes(event.key)) {
        return;
      }
      event.preventDefault();
    }

    event.stopPropagation();
    this.toggleCardExpansion(card);
  },

  toggleCardExpansion(card, forceState = null) {
    if (!card) {
      return false;
    }

    const pathId = card.dataset.pathId;
    const details = card.querySelector('.card-details');
    const expandControl = card.querySelector('[data-action="expand"]');
    const shouldExpand = forceState !== null ? forceState : !card.classList.contains('expanded');

    if (shouldExpand) {
      card.classList.add('expanded');
      card.setAttribute('aria-expanded', 'true');
      if (pathId) {
        this.expandedCards.add(pathId);
      }
    } else {
      card.classList.remove('expanded');
      card.setAttribute('aria-expanded', 'false');
      if (pathId) {
        this.expandedCards.delete(pathId);
      }
    }

    if (details) {
      details.style.display = shouldExpand ? '' : 'none';
    }

    if (expandControl) {
      const label = shouldExpand ? 'Collapse details' : 'Expand details';
      expandControl.setAttribute('aria-expanded', shouldExpand ? 'true' : 'false');
      expandControl.setAttribute('aria-label', label);
      expandControl.textContent = label;
    }

    if (pathId) {
      this.emit('card:expanded', {
        pathId,
        expanded: shouldExpand
      });
    }

    return shouldExpand;
  },

  filterByCategory(category) {
    this.log('debug', `Filtering cards by category: ${category}`);

    this.containers.forEach(container => {
      const cards = container.querySelectorAll('.learning-path-card');
      cards.forEach(card => {
        const cardCategory = card.dataset.category;
        const shouldShow = category === 'all' || cardCategory === category;

        if (shouldShow) {
          card.classList.remove('hidden');
          card.style.display = '';
        } else {
          card.classList.add('hidden');
          card.style.display = 'none';
        }
      });
    });

    this.emit('cardsFiltered', { category });
  },

  sortBy(field, direction = 'asc') {
    this.sortState.field = field;
    this.sortState.direction = direction;

    if (this.sortState.field) {
      this.filteredPaths.sort((a, b) => {
        let valueA, valueB;

        if (this.sortState.field === 'progress') {
          valueA = this.calculateProgress(a.id).percentage;
          valueB = this.calculateProgress(b.id).percentage;
        } else if (this.sortState.field === 'title') {
          valueA = a.title.toLowerCase();
          valueB = b.title.toLowerCase();
        } else {
          return 0;
        }

        const comparison = valueA < valueB ? -1 : valueA > valueB ? 1 : 0;
        const result = this.sortState.direction === 'desc' ? -comparison : comparison;
        return result;
      });
    }

    this.renderCards();

    this.emit('cardsSorted', { field, direction });
  },

  setupKeyboardNavigation() {
    this.containers.forEach(container => {
      const cards = container.querySelectorAll('.learning-path-card');

      cards.forEach(card => {
        const checkboxes = Array.from(card.querySelectorAll('.step-checkbox'));

        checkboxes.forEach((checkbox) => {
          const boundHandler = (event) => {
            if (event.key === 'ArrowDown' || event.key === 'ArrowRight') {
              event.preventDefault();
              const currentIndex = checkboxes.indexOf(checkbox);
              const nextIndex = (currentIndex + 1) % checkboxes.length;
              checkboxes[nextIndex].focus();
            } else if (event.key === 'ArrowUp' || event.key === 'ArrowLeft') {
              event.preventDefault();
              const currentIndex = checkboxes.indexOf(checkbox);
              const prevIndex = (currentIndex - 1 + checkboxes.length) % checkboxes.length;
              checkboxes[prevIndex].focus();
            } else if (event.key === 'Tab' && !event.shiftKey) {
              event.preventDefault();
              const currentIndex = checkboxes.indexOf(checkbox);
              const nextIndex = (currentIndex + 1) % checkboxes.length;
              checkboxes[nextIndex].focus();
            }
          };
          this.boundHandlers.set(checkbox, boundHandler);
          checkbox.addEventListener('keydown', boundHandler);
        });
      });
    });
  },

  _destroyCards() {
    // Remove all event listeners
    this.boundHandlers.forEach((handler, element) => {
      element.removeEventListener('click', handler);
      element.removeEventListener('change', handler);
      element.removeEventListener('keydown', handler);
    });

    // Clear the bound handlers map
    this.boundHandlers.clear();
    // Remove any other event listeners
    this.off('pathSelectionChanged');
    this.off('pathSelected');
    this.off('cardsRendered');
    this.off('cardsSorted');
    this.off('cardsFiltered');
  }
};
