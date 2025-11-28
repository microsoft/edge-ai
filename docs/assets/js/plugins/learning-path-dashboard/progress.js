export const progressMixin = {
  /**
   * Initialize progress tracking cache
   */
  _initializeProgressCache() {
    this.progressCache = new Map();
    this.progressSummaryElements = new Map();
    this.progressMilestones = [25, 50, 75];
    this.progressMilestonesReached = new Map();
  },

  /**
   * Get progress percentage for a path
   * @param {string} pathId - Path ID
   * @returns {number} Progress percentage (0-100)
   */
  getPathProgress(pathId) {
    // Check cache first
    if (this.progressCache && this.progressCache.has(pathId)) {
      return this.progressCache.get(pathId);
    }

    // Calculate progress
    const path = this.learningPaths?.find(p => p.id === pathId);
    if (!path || !Array.isArray(path.steps)) {
      return 0;
    }

    const completedSteps = path.steps.filter(step => step.completed || step.done).length;
    const progress = Math.round((completedSteps / path.steps.length) * 100);

    // Cache the result
    if (this.progressCache) {
      this.progressCache.set(pathId, progress);
    }

    return progress;
  },

  calculatePathProgress(pathOrPathId) {
    return this.calculateProgress(pathOrPathId);
  },

  calculateOverallProgress() {
    const paths = Array.isArray(this.paths) ? this.paths : [];
    if (paths.length === 0) {
      return 0;
    }

    const totalPercentage = paths.reduce((sum, path) => {
      const progress = this.calculateProgress(path);
      return sum + progress.percentage;
    }, 0);

    return this.normalizeProgressValue(totalPercentage / paths.length);
  },

  calculateSelectedProgress() {
    const paths = Array.isArray(this.paths) ? this.paths : [];
    const selected = paths.filter(path => {
      if (!path) {
        return false;
      }

      if (path.selected) {
        return true;
      }

      if (this.selectedPaths instanceof Set) {
        return this.selectedPaths.has(path.id);
      }

      return false;
    });

    if (selected.length === 0) {
      return 0;
    }

    const totalPercentage = selected.reduce((sum, path) => {
      const progress = this.calculateProgress(path);
      return sum + progress.percentage;
    }, 0);

    return this.normalizeProgressValue(totalPercentage / selected.length);
  },

  calculateStepProgress(pathOrPathId) {
    const path = typeof pathOrPathId === 'string' ? this.resolvePath(pathOrPathId) : pathOrPathId;

    if (!path) {
      return 0;
    }

    if (!Array.isArray(path.steps) || path.steps.length === 0) {
      const completion = typeof path.completion === 'number' ? path.completion : 0;
      return this.normalizeProgressValue(completion);
    }

    const totalSteps = path.steps.length;
    const completedSteps = path.steps.filter(step => step?.completed).length;
    const percentage = totalSteps > 0 ? (completedSteps / totalSteps) * 100 : 0;

    return this.normalizeProgressValue(percentage);
  },

  formatProgressText(pathLike, progressData = null) {
    const progress = progressData || this.calculateProgress(pathLike);
    const percentage = this.normalizeProgressValue(progress?.percentage ?? 0);
    const total = Number.isFinite(progress?.total) ? progress.total : null;
    const completed = Number.isFinite(progress?.completed) ? progress.completed : null;

    if (total && completed !== null) {
      return `${percentage}% complete (${completed} of ${total} activities)`;
    }

    return `${percentage}% complete`;
  },

  renderProgressSummary() {
    if (!Array.isArray(this.containers) || this.containers.length === 0) {
      return null;
    }

    const selectedPaths = this.getSelectedPaths();
    const selectedCount = selectedPaths.length;
    const stats = this.getProgressStatistics();
    const percentage = selectedCount > 0 ? this.calculateSelectedProgress() : this.calculateOverallProgress();
    const formattedPercentage = this.formatPercentage(percentage);
    const contextCount = selectedCount > 0 ? selectedCount : stats.total;
    const contextLabel = selectedCount > 0 ? 'selected' : 'available';
    const summaryText = `${formattedPercentage} – ${contextCount} path${contextCount === 1 ? '' : 's'} ${contextLabel}. ${stats.completed} completed, ${stats.inProgress} in progress, ${stats.notStarted} not started.`;

    const detail = {
      percentage,
      selectedPaths: selectedCount,
      totalPaths: stats.total,
      completed: stats.completed,
      inProgress: stats.inProgress,
      notStarted: stats.notStarted
    };

            // First pass: Remove all existing progress summaries
    this.containers.forEach(container => {
      const existingSummaries = container.querySelectorAll('.progress-summary-card');
      existingSummaries.forEach(summary => summary.remove());
      this.progressSummaryElements.delete(container);
    });

    // Second pass: Create fresh progress summaries
    this.containers.forEach(container => {
      if (!container) {
        return;
      }

      const progressDiv = document.createElement('div');
      progressDiv.className = 'progress-summary-card';
      progressDiv.setAttribute('role', 'status');
      progressDiv.setAttribute('aria-live', 'polite');

      // Create card structure with stats
      progressDiv.innerHTML = `
        <div class="progress-summary-header">
          <span class="progress-percentage">${stats.overallPercentage || 0}%</span>
          <span class="progress-label">Overall Progress</span>
        </div>
        <div class="progress-summary-stats">
          <div class="stat-item stat-selected">
            <span class="stat-number">${stats.selectedCount} of ${stats.total}</span>
            <span class="stat-label">Selected</span>
          </div>
          <div class="stat-item stat-completed">
            <span class="stat-number">${stats.completed}</span>
            <span class="stat-label">🎉 Completed</span>
          </div>
          <div class="stat-item stat-inprogress">
            <span class="stat-number">${stats.inProgress}</span>
            <span class="stat-label">In Progress</span>
          </div>
        </div>
      `;

      // Insert before cards container or at beginning
      const cardsContainer = container.querySelector('.learning-cards-container');
      if (cardsContainer) {
        container.insertBefore(progressDiv, cardsContainer);
      } else {
        container.insertBefore(progressDiv, container.firstChild);
      }

      // Cache the reference
      this.progressSummaryElements.set(container, progressDiv);
    });

    this.emit('progressSummaryUpdated', detail);
    return detail;
  },

  getProgressStatistics() {
    const paths = Array.isArray(this.paths) ? this.paths : [];
    const selectedPaths = this.getSelectedPaths();
    const selectedCount = selectedPaths.length;

    let completed = 0;
    let inProgress = 0;
    let notStarted = 0;

    // Calculate stats for selected paths only
    selectedPaths.forEach(path => {
      if (!path) {
        return;
      }

      const progress = this.calculateProgress(path);
      if (progress.percentage >= 100) {
        completed += 1;
      } else if (progress.percentage > 0) {
        inProgress += 1;
      } else {
        notStarted += 1;
      }
    });

    const total = paths.length;
    const completionRate = selectedCount > 0 ? this.normalizeProgressValue((completed / selectedCount) * 100) : 0;
    const overallPercentage = selectedCount > 0 ?
      this.normalizeProgressValue(this.calculateSelectedProgress()) :
      this.normalizeProgressValue(this.calculateOverallProgress());

    return {
      completed,
      inProgress,
      notStarted,
      total,
      selectedCount,
      completionRate,
      overallPercentage
    };
  },

  getTimeStatistics() {
    const paths = Array.isArray(this.paths) ? this.paths : [];
    let totalEstimated = 0;
    let completed = 0;
    let remaining = 0;

    paths.forEach(path => {
      if (!path) {
        return;
      }

      const estimatedHours = this.parseEstimatedTimeToHours(path.estimatedTime);
      const progress = this.calculateProgress(path);
      const fractionComplete = progress.percentage / 100;

      totalEstimated += estimatedHours;
      if (progress.percentage >= 100) {
        completed += estimatedHours;
      } else if (progress.percentage > 0) {
        remaining += estimatedHours;
        remaining += estimatedHours * (1 - fractionComplete);
      } else {
        remaining += estimatedHours;
      }
    });

    return {
      totalEstimated: this.roundToTwo(totalEstimated),
      completed: this.roundToTwo(completed),
      remaining: this.roundToTwo(remaining)
    };
  },

  generateProgressReport() {
    const paths = Array.isArray(this.paths) ? this.paths : [];
    const byCategory = {};

    paths.forEach(path => {
      if (!path) {
        return;
      }

      const category = path.category || 'General';
      const categoryData = byCategory[category] || { completed: 0, inProgress: 0, notStarted: 0, percentages: [] };
      const progress = this.calculateProgress(path);

      if (progress.percentage >= 100) {
        categoryData.completed += 1;
      } else if (progress.percentage > 0) {
        categoryData.inProgress += 1;
      } else {
        categoryData.notStarted += 1;
      }

      categoryData.percentages.push(progress.percentage);
      byCategory[category] = categoryData;
    });

    Object.keys(byCategory).forEach(category => {
      const data = byCategory[category];
      const average = data.percentages.length > 0
        ? this.normalizeProgressValue(data.percentages.reduce((sum, value) => sum + value, 0) / data.percentages.length)
        : 0;

      const result = {
        completed: data.completed,
        inProgress: data.inProgress,
        averageProgress: average
      };

      if (data.notStarted > 0) {
        result.notStarted = data.notStarted;
      }

      byCategory[category] = result;
    });

    return {
      byCategory,
      overall: this.getProgressStatistics()
    };
  },

  saveProgress() {
    const paths = Array.isArray(this.paths) ? this.paths : [];
    const progressData = {};

    paths.forEach(path => {
      if (!path || !path.id) {
        return;
      }

      const progress = this.calculateProgress(path);
      progressData[path.id] = this.normalizeProgressValue(progress.percentage);
    });

    try {
      localStorage.setItem('learningPathProgress', JSON.stringify(progressData));
    } catch (error) {
      this.logError('Failed to save progress to localStorage:', error);
    }

    return progressData;
  },

  loadProgress() {
    let stored = {};

    try {
      const raw = localStorage.getItem('learningPathProgress');
      stored = raw ? JSON.parse(raw) : {};
    } catch (error) {
      this.logWarning('Failed to parse saved progress data. Resetting progress.', error);
      stored = {};
    }

    const paths = Array.isArray(this.paths) ? this.paths : [];
    this.invalidateProgressCache();

    paths.forEach(path => {
      if (!path || !path.id) {
        return;
      }

      const savedValue = typeof stored[path.id] === 'number' ? stored[path.id] : 0;
      const normalized = this.normalizeProgressValue(savedValue);
      path.completion = normalized;

      if (Array.isArray(path.steps) && path.steps.length > 0) {
        const stepsToComplete = Math.round((normalized / 100) * path.steps.length);
        path.steps.forEach((step, index) => {
          if (step) {
            step.completed = index < stepsToComplete;
          }
        });
      }

      const progress = this.calculateProgress(path);
      this.updateProgressDisplay(path.id, progress);
    });

    Object.keys(stored).forEach(pathId => {
      if (!paths.find(path => path.id === pathId)) {
        const normalized = this.normalizeProgressValue(stored[pathId]);
        const newPath = {
          id: pathId,
          title: pathId,
          description: '',
          steps: [],
          completion: normalized
        };

        this.paths.push(newPath);
        this.loadedPaths.push(newPath);
        this.filteredPaths.push(newPath);
        this.updateProgressDisplay(pathId, {
          completed: normalized,
          total: 100,
          percentage: normalized
        });
      }
    });

    this.renderProgressSummary();
    return paths;
  },

  updateProgress(pathId, value) {
    if (typeof value !== 'number' || Number.isNaN(value)) {
      throw new Error('Progress value must be a number');
    }

    if (value < 0 || value > 100) {
      throw new RangeError('Progress value must be between 0 and 100');
    }

    let path = this.resolvePath(pathId);
    if (!path) {
      this.logWarning(`Path not found: ${pathId}`);
      const fallbackPath = {
        id: pathId,
        title: pathId,
        description: '',
        steps: [],
        completion: 0
      };

      if (!Array.isArray(this.paths)) {
        this.paths = [];
      }

      this.paths.push(fallbackPath);
      this.loadedPaths = Array.isArray(this.loadedPaths) ? [...this.paths] : [...this.paths];
      this.filteredPaths = Array.isArray(this.filteredPaths) ? [...this.paths] : [...this.paths];
      path = fallbackPath;
    }

    const normalized = this.normalizeProgressValue(value);
    path.completion = normalized;

    if (Array.isArray(path.steps) && path.steps.length > 0) {
      const stepsToComplete = Math.round((normalized / 100) * path.steps.length);
      path.steps.forEach((step, index) => {
        if (step) {
          step.completed = index < stepsToComplete;
        }
      });
    }

    this.invalidateProgressCache();
    const progress = this.calculateProgress(path);
    this.updateProgressDisplay(path.id, progress);
    this.renderProgressSummary();
    this.saveProgress();

    const detail = {
      pathId,
      progress: normalized,
      completed: normalized === 100
    };

    this.dispatchContainerEvent('progressChanged', detail);
    this.emit('progressChanged', detail);

    if (normalized === 100) {
      const completionDetail = { pathId, completed: true };
      this.dispatchContainerEvent('pathCompleted', completionDetail);
      this.emit('pathCompleted', completionDetail);
    }

    const milestone = this.detectProgressMilestone(pathId, normalized);
    if (milestone !== null) {
      const milestoneDetail = { pathId, milestone };
      this.dispatchContainerEvent('milestoneReached', milestoneDetail);
      this.emit('milestoneReached', milestoneDetail);
    }

    return progress;
  },

  detectProgressMilestone(pathId, percentage) {
    if (!pathId || !Array.isArray(this.progressMilestones)) {
      return null;
    }

    const reached = new Set(this.progressMilestonesReached.get(pathId) || []);
    Array.from(reached).forEach(value => {
      if (value > percentage) {
        reached.delete(value);
      }
    });

    const milestone = this.progressMilestones.find(value => Math.abs(percentage - value) < 0.01 && !reached.has(value));
    if (milestone === undefined) {
      this.progressMilestonesReached.set(pathId, reached);
      return null;
    }

    reached.add(milestone);
    this.progressMilestonesReached.set(pathId, reached);
    return milestone;
  },

  calculateProgress(pathOrPathId) {
    let path;
    let pathId;
    if (typeof pathOrPathId === 'string') {
      pathId = pathOrPathId;
      path = this.loadedPaths?.find(p => p.id === pathId);
    } else {
      path = pathOrPathId;
      pathId = path?.id;
    }

    if (!path) {
      return { completed: 0, total: 0, percentage: 0 };
    }

    const cacheKey = `${pathId || 'unknown'}_${this.progressCacheTimestamp}`;
    if (this.progressCache.has(cacheKey)) {
      const cached = this.progressCache.get(cacheKey);
      return cached;
    }

    let result;

    if (Array.isArray(path.steps) && path.steps.length > 0) {
      const total = path.steps.length;
      const completed = path.steps.filter(step => {
        const isCompleted = this.isStepCompleted(pathId, step.id);
        return isCompleted;
      }).length;

      result = {
        completed,
        total,
        percentage: this.normalizeProgressValue(total > 0 ? (completed / total) * 100 : 0)
      };
    } else {
      const percentage = this.normalizeProgressValue(typeof path.completion === 'number' ? path.completion : 0);
      result = {
        completed: percentage,
        total: 100,
        percentage
      };
    }

    this.progressCache.set(cacheKey, result);

    return result;
  },

  normalizeProgressValue(value) {
    if (value === null || value === undefined) {
      return 0;
    }

    const numeric = Number(value);
    if (Number.isNaN(numeric) || !Number.isFinite(numeric)) {
      return 0;
    }

    const clamped = Math.min(Math.max(numeric, 0), 100);
    return Math.round(clamped * 100) / 100;
  },

  formatPercentage(value) {
    const normalized = this.normalizeProgressValue(value);
    if (Number.isInteger(normalized)) {
      return `${normalized}%`;
    }

    const trimmed = normalized.toFixed(2).replace(/0+$/, '').replace(/\.$/, '');
    return `${trimmed}%`;
  },

  shouldReduceMotion() {
    if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') {
      return false;
    }

    try {
      return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    } catch (error) {
      this.log('debug', 'matchMedia error while checking reduced motion preference', error);
      return false;
    }
  },

  parseEstimatedTimeToHours(estimate) {
    if (estimate === null || estimate === undefined) {
      return 0;
    }

    if (typeof estimate === 'number' && Number.isFinite(estimate)) {
      return estimate;
    }

    const value = String(estimate).trim().toLowerCase();
    const match = value.match(/([0-9]*\.?[0-9]+)/);
    if (!match) {
      return 0;
    }

    const amount = parseFloat(match[1]);
    if (Number.isNaN(amount)) {
      return 0;
    }

    if (value.includes('day')) {
      return amount * 24;
    }

    if (value.includes('week')) {
      return amount * 24 * 7;
    }

    if (value.includes('min')) {
      return amount / 60;
    }

    return amount;
  },

  roundToTwo(value) {
    if (!Number.isFinite(value)) {
      return 0;
    }

    return Math.round(value * 100) / 100;
  },

  invalidateProgressCache() {
    this.progressCacheTimestamp = Date.now();
    this.progressCache.clear();
  },

  isStepCompleted(pathId, stepId) {
    try {
      const progress = JSON.parse(localStorage.getItem('learning-progress') || '{}');
      if (progress[pathId] && typeof progress[pathId][stepId] === 'boolean') {
        return progress[pathId][stepId];
      }
    } catch (error) {
      // Ignore localStorage errors and continue fallback checks
    }

    // Check kata completion storage (kata-{id} keys with completionPercentage)
    try {
      const kataData = localStorage.getItem(`kata-${stepId}`);
      if (kataData) {
        const parsed = JSON.parse(kataData);
        if (typeof parsed.completionPercentage === 'number') {
          return parsed.completionPercentage === 100;
        }
      }
    } catch (error) {
      // Ignore kata storage parsing errors
    }

    const path = this.loadedPaths?.find(p => p.id === pathId);
    if (path && path.steps) {
      const step = path.steps.find(s => s.id === stepId);
      if (step && typeof step.completed === 'boolean') {
        return step.completed;
      }
    }

    return false;
  },

  getStepCurrentState(pathId, stepId) {
    const checkbox = document.querySelector(`[data-path-id="${pathId}"][data-step-id="${stepId}"]`);
    if (checkbox) {
      return checkbox.checked;
    }

    try {
      const progress = JSON.parse(localStorage.getItem('learning-progress') || '{}');
      if (progress[pathId] && typeof progress[pathId][stepId] === 'boolean') {
        return progress[pathId][stepId];
      }
    } catch (error) {
      // Ignore localStorage errors and continue fallback checks
    }

    const path = this.loadedPaths?.find(p => p.id === pathId);
    if (path && path.steps) {
      const step = path.steps.find(s => s.id === stepId);
      if (step && typeof step.completed === 'boolean') {
        return step.completed;
      }
    }

    return false;
  },

  updateProgressDisplay(pathId, progressData = null) {
    if (!pathId) return;

    const progress = progressData || this.calculateProgress(pathId);

    this.containers.forEach(container => {
      const pathCard = container.querySelector(`[data-path-id="${pathId}"]`);
      if (!pathCard) return;

      this.updateProgressElements(pathCard, progress);
    });

    this.emit('progressUpdated', {
      pathId,
      stepId: 'progress-update',
      completed: progress.completed,
      total: progress.total,
      percentage: progress.percentage
    });

    this.renderProgressSummary();
  },

  updateProgressElements(card, progress) {
    const progressBar = card.querySelector('.progress-bar');
    const progressFill = card.querySelector('.progress-fill');
    const progressText = card.querySelector('.progress-text');
    const reduceMotion = this.shouldReduceMotion();

    if (progressBar) {
      if (!progressBar.dataset.originalTransition) {
        progressBar.dataset.originalTransition = progressBar.style.transition || 'width 0.4s ease';
      }
      progressBar.setAttribute('aria-valuenow', progress.percentage.toString());
      progressBar.style.transition = reduceMotion ? 'none' : (progressBar.dataset.originalTransition || 'width 0.4s ease');
      progressBar.style.width = `${progress.percentage}%`;
    }

    if (progressFill) {
      if (!progressFill.dataset.originalTransition) {
        progressFill.dataset.originalTransition = progressFill.style.transition || 'width 0.4s ease';
      }
      progressFill.style.transition = reduceMotion ? 'none' : progressFill.dataset.originalTransition;
      progressFill.style.width = `${progress.percentage}%`;
    }

    if (progressText) {
      progressText.textContent = this.formatProgressText(null, progress);
    }
  },

  announceProgressUpdate(pathId) {
    const progress = this.calculateProgress(pathId);
    const path = this.loadedPaths?.find(p => p.id === pathId);
    const pathTitle = path ? path.title : 'Unknown Path';

    this.announceStatus(`Progress updated for ${pathTitle}. ${progress.completed} of ${progress.total} completed.`);
  },

  updateProgressInLocalStorage(pathId, progress) {
    try {
      const allProgress = JSON.parse(localStorage.getItem('learning-progress') || '{}');

      if (!allProgress[pathId]) {
        allProgress[pathId] = {};
      }

      Object.assign(allProgress[pathId], progress);

      localStorage.setItem('learning-progress', JSON.stringify(allProgress));
    } catch (error) {
      this.logError('Failed to update progress in localStorage:', error);
    }
  },



  recalculateProgress() {
    this.paths.forEach(path => {
      const progress = this.calculateProgress(path.id);
      this.updateProgressDisplay(path.id, progress);
    });
  }
};
