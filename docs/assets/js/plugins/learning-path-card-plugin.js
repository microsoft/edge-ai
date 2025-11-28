/**
 * Learning Path Card Plugin
 * Manages learning path cards with progress tracking, completion stats, and interactive features
 */

class LearningPathCard {
  constructor(container, config = {}) {
    // Handle both selector strings and DOM elements
    if (typeof container === 'string') {
      this.container = document.querySelector(container);
      if (!this.container) {
        throw new Error('Container element not found');
      }
    } else if (container instanceof Element) {
      this.container = container;
    } else {
      throw new Error('Container must be a DOM element or selector string');
    }

    // Default configuration
    this.config = {
      showProgress: true,
      showBadges: true,
      enableFiltering: true,
      enableSorting: true,
      layout: 'grid',
      ...config
    };

    // Initialize data structures
    this.paths = [];
    this.filteredPaths = [];
    this.currentFilter = null;
    this.currentSort = { field: null, direction: 'asc' };
    this.eventListeners = {};

    // Initialize plugin
    this.init();
  }

  init() {
    // Set up container
    this.setupContainer();

    // Create ARIA live region for announcements
    this.createAriaLiveRegion();

    // Bind events
    this.bindEvents();
  }

  setupContainer() {
    // Add necessary classes for styling
    this.container.classList.add('learning-paths-container');
    this.container.classList.add(`layout-${this.config.layout}`);
  }

  createAriaLiveRegion() {
    // Create ARIA live region for screen reader announcements
    const ariaLive = document.createElement('div');
    ariaLive.setAttribute('aria-live', 'polite');
    ariaLive.setAttribute('aria-atomic', 'true');
    ariaLive.className = 'sr-only';
    ariaLive.style.cssText = 'position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0, 0, 0, 0); white-space: nowrap; border: 0;';
    this.container.appendChild(ariaLive);
    this.ariaLive = ariaLive;
  }

  loadPaths(paths) {
    // Validate and filter paths
    this.paths = paths.filter(path => this.validatePath(path));
    this.filteredPaths = [...this.paths];

    // Load progress from localStorage
    this.loadProgress();
  }

  validatePath(path) {
    // Basic validation for path data
    return (
      path &&
      typeof path.id === 'string' &&
      path.id.trim() !== '' &&
      typeof path.title === 'string' &&
      path.title.trim() !== '' &&
      Array.isArray(path.steps)
    );
  }

  getPath(pathId) {
    return this.paths.find(path => path.id === pathId);
  }

  calculateProgress(pathId) {
    const path = this.getPath(pathId);
    if (!path || !path.steps) {
      return { completed: 0, total: 0, percentage: 0 };
    }

    const completed = path.steps.filter(step => step.completed).length;
    const total = path.steps.length;
    const percentage = total > 0 ? Math.round((completed / total) * 100) : 0;

    return { completed, total, percentage };
  }

  updateStepCompletion(pathId, stepId, completed) {
    const path = this.getPath(pathId);
    if (!path || !path.steps) return;

    const step = path.steps.find(s => s.id === stepId);
    if (!step) return;

    step.completed = completed;

    // Save progress
    this.saveProgress();

    // Calculate updated progress
    const progress = this.calculateProgress(pathId);

    // Emit event
    this.emit('progressUpdate', {
      pathId,
      stepId,
      completed,
      progress
    });

    // Announce to screen readers
    this.announceProgress(pathId, progress);

    // Re-render to reflect changes
    this.render();

    // Re-render to update visual state
    this.render();
  }  saveProgress() {
    try {
      const progressData = {};
      this.paths.forEach(path => {
        progressData[path.id] = {
          steps: path.steps.map(step => ({
            id: step.id,
            completed: step.completed
          }))
        };
      });
      localStorage.setItem('learning-paths-progress', JSON.stringify(progressData));
    } catch (error) {
      console.warn('Failed to save progress to localStorage:', error);
    }
  }

  loadProgress() {
    try {
      const progressData = JSON.parse(localStorage.getItem('learning-paths-progress') || '{}');

      this.paths.forEach(path => {
        const pathProgress = progressData[path.id];
        if (pathProgress && pathProgress.steps) {
          path.steps.forEach(step => {
            const stepProgress = pathProgress.steps.find(s => s.id === step.id);
            if (stepProgress) {
              step.completed = stepProgress.completed;
            }
          });
        }
      });
    } catch (error) {
      console.warn('Failed to load progress from localStorage:', error);
    }
  }

  render() {
    // Apply current layout
    this.container.className = this.container.className
      .replace(/layout-\w+/g, '');

    this.container.classList.add(`layout-${this.config.layout}`);

    // Clear existing cards (but preserve ARIA live region)
    const existingCards = this.container.querySelectorAll('.learning-path-card');
    existingCards.forEach(card => card.remove());

    // Render filtered paths
    this.filteredPaths.forEach(path => {
      const cardElement = this.createPathCard(path);
      this.container.appendChild(cardElement);
    });
  }

  createPathCard(path) {
    const progress = this.calculateProgress(path.id);

    const card = document.createElement('div');
    card.className = 'learning-path-card';
    card.setAttribute('role', 'article');
    card.setAttribute('tabindex', '0');
    card.setAttribute('aria-labelledby', `path-title-${path.id}`);
    card.dataset.pathId = path.id;

    let badgeHTML = '';
    if (this.config.showBadges && path.badge && path.badge.unlocked) {
      badgeHTML = `
        <div class="completion-badge unlocked">
          <span class="badge-icon">${path.badge.icon}</span>
          <span class="badge-title">${path.badge.title}</span>
        </div>
      `;
    }

    let progressHTML = '';
    if (this.config.showProgress) {
      progressHTML = `
        <div class="progress-section">
          <div class="progress-bar" role="progressbar" aria-valuenow="${progress.percentage}" aria-valuemin="0" aria-valuemax="100">
            <div class="progress-fill" style="width: ${progress.percentage}%"></div>
          </div>
          <div class="progress-text">${progress.completed} of ${progress.total} completed</div>
        </div>
      `;
    }

    card.innerHTML = `
      <div class="card-header">
        <h3 class="path-title" id="path-title-${path.id}">${path.title}</h3>
        <span class="path-category">${path.category || ''}</span>
      </div>
      <div class="card-body">
        <p class="path-description">${path.description || ''}</p>
        ${progressHTML}
        ${badgeHTML}
      </div>
      <div class="card-actions">
        ${this.createStepsList(path)}
      </div>
    `;

    return card;
  }

  createStepsList(path) {
    if (!path.steps || path.steps.length === 0) {
      return '';
    }

    const stepsHTML = path.steps.map(step => `
      <div class="step-item">
        <input
          type="checkbox"
          class="step-checkbox"
          id="step-${step.id}"
          data-path-id="${path.id}"
          data-step-id="${step.id}"
          ${step.completed ? 'checked' : ''}
        >
        <label for="step-${step.id}" class="step-label">${step.title}</label>
      </div>
    `).join('');

    return `
      <div class="steps-list">
        ${stepsHTML}
      </div>
    `;
  }

  filterByCategory(category) {
    this.currentFilter = category;
    if (category) {
      this.filteredPaths = this.paths.filter(path => path.category === category);
    } else {
      this.filteredPaths = [...this.paths];
    }
    this.applySorting();
    // Re-render after filtering
    this.render();
  }

  sortBy(field, direction = 'asc') {
    this.currentSort = { field, direction };
    this.applySorting();
    // Re-render after sorting
    this.render();
  }

  applySorting() {
    if (!this.currentSort.field) return;

    this.filteredPaths.sort((a, b) => {
      let valueA, valueB;

      switch (this.currentSort.field) {
        case 'progress':
          valueA = this.calculateProgress(a.id).percentage;
          valueB = this.calculateProgress(b.id).percentage;
          break;
        case 'title':
          valueA = a.title.toLowerCase();
          valueB = b.title.toLowerCase();
          break;
        default:
          valueA = a[this.currentSort.field];
          valueB = b[this.currentSort.field];
      }

      if (valueA < valueB) {
        return this.currentSort.direction === 'asc' ? -1 : 1;
      }
      if (valueA > valueB) {
        return this.currentSort.direction === 'asc' ? 1 : -1;
      }
      return 0;
    });
  }

  clearFilters() {
    this.currentFilter = null;
    this.filteredPaths = [...this.paths];
    this.applySorting();
    // Re-render to show all paths
    this.render();
  }

  bindEvents() {
    // Handle card clicks
    this.container.addEventListener('click', (e) => {
      const card = e.target.closest('.learning-path-card');
      if (card && !e.target.closest('.step-checkbox')) {
        const pathId = card.dataset.pathId;
        const path = this.getPath(pathId);
        this.emit('cardClick', { pathId, path });
      }

      // Handle step completion
      if (e.target.classList.contains('step-checkbox')) {
        const pathId = e.target.dataset.pathId;
        const stepId = e.target.dataset.stepId;
        const completed = e.target.checked;
        this.updateStepCompletion(pathId, stepId, completed);
      }
    });

    // Handle keyboard navigation
    this.container.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        const card = e.target.closest('.learning-path-card');
        if (card && e.target === card) {
          e.preventDefault();
          card.click();
        }
      }
    });
  }

  announceProgress(pathId, progress) {
    const path = this.getPath(pathId);
    if (path && this.ariaLive) {
      this.ariaLive.textContent = `Progress updated for ${path.title}: ${progress.completed} of ${progress.total} steps completed`;
    }
  }

  handleError(error) {
    console.error('LearningPathCard error:', error);

    // Display error message to user
    const errorElement = document.createElement('div');
    errorElement.className = 'error-message';
    errorElement.textContent = error.message || 'An error occurred';
    errorElement.setAttribute('role', 'alert');

    // Remove existing error messages
    const existingErrors = this.container.querySelectorAll('.error-message');
    existingErrors.forEach(el => el.remove());

    // Add new error message
    this.container.insertBefore(errorElement, this.container.firstChild);

    // Auto-remove after 5 seconds
    setTimeout(() => {
      if (errorElement.parentNode) {
        errorElement.remove();
      }
    }, 5000);
  }

  // Event system
  on(event, callback) {
    if (!this.eventListeners[event]) {
      this.eventListeners[event] = [];
    }
    this.eventListeners[event].push(callback);
  }

  off(event, callback) {
    if (!this.eventListeners[event]) return;
    const index = this.eventListeners[event].indexOf(callback);
    if (index > -1) {
      this.eventListeners[event].splice(index, 1);
    }
  }

  emit(event, data) {
    if (!this.eventListeners[event]) return;
    this.eventListeners[event].forEach(callback => {
      try {
        callback(data);
      } catch (error) {
        console.error(`Error in event listener for ${event}:`, error);
      }
    });
  }

  // Cleanup
  destroy() {
    // Remove event listeners
    this.container.innerHTML = '';
    this.eventListeners = {};
  }
}

// Expose globally for backward compatibility and testing
if (typeof window !== 'undefined') {
  window.LearningPathCard = LearningPathCard;
}
if (typeof globalThis !== 'undefined') {
  globalThis.LearningPathCard = LearningPathCard;
}
