/**
 * Interactive Checkbox Module
 * Makes kata checkboxes clickable with localStorage persistence and progress tracking
 * Version: 1.0.0
 */

// Import dependencies
import { errorHandler } from '../core/error-handler.js';
import { calculateCompletion } from '../utils/completion-calculator.js';

/**
 * Interactive Checkbox Manager
 * Handles interactive checkbox functionality for kata and lab pages
 */
export class InteractiveCheckboxManager {
  constructor(dependencies = {}) {
    this.errorHandler = dependencies.errorHandler || errorHandler;
    this.progressCore = dependencies.progressCore || null;
    this.progressBarManager = dependencies.progressBarManager || null;
    this.debugHelper = dependencies.debugHelper || { debug: () => {} }; // Default no-op debug

    this.storagePrefix = 'kata-progress-';
    this.isInitialized = false;
    this.currentKataId = null;
    this.checkboxElements = new Map();
    this.progressContainer = null;

    // Debounce settings
    this.updateDebounceTimeout = null;
    this.updateDebounceDelay = 300;

    // Progress display elements
    this.progressBar = null;
    this.progressText = null;
    this.progressPercentage = null;
    this.progressTasks = null;
  }

  /**
   * Initialize the interactive checkbox system
   * @returns {boolean} Success status
   */
  init() {
    return this.errorHandler.safeExecute(() => {
      if (this.isInitialized) {
        this.debugHelper.debug('Interactive checkboxes already initialized');
        return true;
      }

      this.debugHelper.debug('Initializing interactive checkboxes');

      // Set up automatic detection when page changes
      this.setupPageChangeDetection();

      // Process current page
      this.processCurrentPage();

      this.isInitialized = true;
      return true;
    }, 'InteractiveCheckboxManager.init', false);
  }

  /**
   * Set up page change detection for SPA navigation
   * @private
   */
  setupPageChangeDetection() {
    // Listen for hash changes (docsify navigation)
    window.addEventListener('hashchange', () => {
      setTimeout(() => this.processCurrentPage(), 100);
    });

    // Listen for DOM mutations to catch dynamically loaded content
    const observer = new MutationObserver((mutations) => {
      const hasRelevantChanges = mutations.some(mutation =>
        mutation.type === 'childList' &&
        mutation.addedNodes.length > 0 &&
        Array.from(mutation.addedNodes).some(node =>
          node.nodeType === Node.ELEMENT_NODE &&
          (node.querySelector?.('input[type="checkbox"]') || node.matches?.('input[type="checkbox"]'))
        )
      );

      if (hasRelevantChanges) {
        this.debounceUpdate(() => this.processCurrentPage());
      }
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  }

  /**
   * Debounce update operations
   * @private
   * @param {Function} callback - Function to execute
   */
  debounceUpdate(callback) {
    if (this.updateDebounceTimeout) {
      clearTimeout(this.updateDebounceTimeout);
    }
    this.updateDebounceTimeout = setTimeout(callback, this.updateDebounceDelay);
  }

  /**
   * Process the current page for interactive checkboxes
   * @returns {boolean} Success status
   */
  processCurrentPage() {
    return this.errorHandler.safeExecute(() => {
      const shouldActivate = this.shouldActivateForCurrentPage();

      if (!shouldActivate) {
        this.debugHelper.debug('Interactive checkboxes not activated for current page');
        this.cleanup();
        return false;
      }

      this.currentKataId = this.extractKataId();
      if (!this.currentKataId) {
        this.debugHelper.debug('Could not extract kata ID');
        this.cleanup();
        return false;
      }

      this.debugHelper.debug('Processing interactive checkboxes for kata:', this.currentKataId);

      // Set up checkboxes and progress display
      this.setupCheckboxes();
      this.setupProgressDisplay();
      this.loadSavedProgress();
      this.updateProgressDisplay();

      return true;
    }, 'InteractiveCheckboxManager.processCurrentPage', false);
  }

  /**
   * Check if interactive checkboxes should be activated for current page
   * @returns {boolean} Whether to activate
   */
  shouldActivateForCurrentPage() {
    return this.errorHandler.safeExecute(() => {
      const path = window.location.hash;

      // Check for kata pages - updated to match actual URL structure
      const isKata = /\/learning\/katas\/[^/]+\/[^/]+\/?$/.test(path) ||
                     /\/katas\/[^/]+\/kata\.md/.test(path) ||
                     /\/katas\/[^/]+\/[^/]+\/?$/.test(path) ||
                     (document.querySelector('main article')?.textContent || '').includes('Kata Overview');

      // Check for lab pages
      const isLab = /\/training-labs\/[^/]+\/lab\.md/.test(path) ||
                    /\/training-labs\/[^/]+\/?$/.test(path) ||
                    (document.querySelector('main article')?.textContent || '').includes('Lab Overview');

      return (isKata || isLab) &&
             !path.includes('README') &&
             !path.includes('readme') &&
             !path.includes('index');
    }, 'shouldActivateForCurrentPage', false);
  }

  /**
   * Extract kata ID from current page
   * @returns {string|null} Kata ID
   */
  extractKataId() {
    return this.errorHandler.safeExecute(() => {
      const path = window.location.hash;

      // Try kata path - capture the kata folder name, not the file
      let match = path.match(/\/learning\/katas\/([^/]+)/);
      if (match) {
        return match[1]; // Return the kata folder name
      }

      // Try old kata path format for backward compatibility
      match = path.match(/\/katas\/([^/]+)/);
      if (match) {
        return match[1];
      }

      // Try training labs - capture the lab folder name
      match = path.match(/\/training-labs\/([^/]+)/);
      if (match) {
        return `lab-${match[1]}`;
      }

      // Try to extract from page title
      const titleElement = document.querySelector('h1');
      if (titleElement) {
        const title = titleElement.textContent.trim();
        return title.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
      }

      return null;
    }, 'extractKataId', null);
  }

  /**
   * Set up interactive functionality for all checkboxes
   * @private
   */
  setupCheckboxes() {
    this.errorHandler.safeExecute(() => {
      // Clear existing checkbox tracking
      this.checkboxElements.clear();

      // Find all checkboxes in the content
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');

      checkboxes.forEach((checkbox, _index) => {
        const checkboxId = `checkbox-${_index}`;
        this.checkboxElements.set(checkboxId, checkbox);

        // Remove existing event listeners to prevent duplicates
        checkbox.removeEventListener('change', this.handleCheckboxChange);

        // Add interactive functionality
        checkbox.addEventListener('change', (event) => this.handleCheckboxChange(event, checkboxId));

        // Ensure checkbox is enabled
        checkbox.disabled = false;

        // Add visual feedback classes
        checkbox.classList.add('interactive-checkbox');

        // Store checkbox ID for reference
        checkbox.dataset.checkboxId = checkboxId;
      });

      this.debugHelper.debug(`Set up ${checkboxes.length} interactive checkboxes`);
    }, 'setupCheckboxes');
  }

  /**
   * Handle checkbox state changes
   * @private
   * @param {Event} event - Change event
   * @param {string} checkboxId - Checkbox identifier
   */
  handleCheckboxChange(event, checkboxId) {
    this.errorHandler.safeExecute(() => {
      const checkbox = event.target;
      const isChecked = checkbox.checked;

      this.debugHelper.debug(`Checkbox ${checkboxId} changed to:`, isChecked);

      // Add visual feedback
      this.addCheckboxAnimation(checkbox, isChecked);

      // Save progress
      this.saveCheckboxState(checkboxId, isChecked);

      // Update progress display
      this.debounceUpdate(() => this.updateProgressDisplay());

      // Trigger progress core update if available
      if (this.progressCore) {
        this.progressCore.notifyCheckboxChange(this.currentKataId, checkboxId, isChecked);
      }
    }, 'handleCheckboxChange');
  }

  /**
   * Add visual animation for checkbox interaction
   * @private
   * @param {HTMLElement} checkbox - Checkbox element
   * @param {boolean} isChecked - New checked state
   */
  addCheckboxAnimation(checkbox, isChecked) {
    if (isChecked) {
      checkbox.classList.add('checkbox-complete-animation');
      setTimeout(() => {
        checkbox.classList.remove('checkbox-complete-animation');
      }, 600);
    }

    // Update parent list item styling
    const listItem = checkbox.closest('li');
    if (listItem) {
      if (isChecked) {
        listItem.classList.add('completed-task');
      } else {
        listItem.classList.remove('completed-task');
      }
    }
  }

  /**
   * Set up progress display container
   * @private
   */
  setupProgressDisplay() {
    this.errorHandler.safeExecute(() => {
      // Remove existing progress container
      if (this.progressContainer) {
        this.progressContainer.remove();
      }

      // Legacy progress container creation disabled - now using unified progress tracker
      // The unified progress tracker handles all progress display in the footer
      // This avoids duplicate progress displays and provides consistent UX
      this.progressContainer = null;
      this.progressBar = null;
      this.progressPercentage = null;
      this.progressTasks = null;

      this.debugHelper.debug('Progress display container created');
    }, 'setupProgressDisplay');
  }

  /**
   * Update progress display
   * @private
   */
  updateProgressDisplay() {
    this.errorHandler.safeExecute(() => {
      if (!this.currentKataId) {
        return;
      }

      const checkboxes = Array.from(this.checkboxElements.values());
      const checkboxStates = Object.fromEntries(
        checkboxes.map((cb, idx) => [`task${idx}`, cb.checked])
      );
      const { total: totalTasks, completed: completedTasks, percentage: completionPercentage } = calculateCompletion(checkboxStates);

      // Update inline progress display if it exists
      if (this.progressContainer) {
        // Update progress bar
        if (this.progressBar) {
          this.progressBar.style.width = `${completionPercentage}%`;
        }

        // Update percentage text
        if (this.progressPercentage) {
          this.progressPercentage.textContent = `${completionPercentage}%`;
        }

        // Update task count text
        if (this.progressTasks) {
          this.progressTasks.textContent = `${completedTasks} of ${totalTasks} tasks completed`;
        }

        // Add completion animation if 100%
        if (completionPercentage === 100) {
          this.progressContainer.classList.add('kata-completed');

          // Trigger completion celebration
          setTimeout(() => {
            this.triggerCompletionCelebration();
          }, 500);
        } else {
          this.progressContainer.classList.remove('kata-completed');
        }
      }

      // Update progress bar manager banner if available
      if (this.progressBarManager) {
        // Call updateProgressBar with the correct parameters (completed, total)
        this.progressBarManager.updateProgressBar(completedTasks, totalTasks);
      }

      this.debugHelper.debug('Progress updated:', {
        totalTasks,
        completedTasks,
        completionPercentage
      });
    }, 'updateProgressDisplay');
  }

  /**
   * Save checkbox state to API
   * @private
   * @param {string} checkboxId - Checkbox identifier
   * @param {boolean} isChecked - Checked state
   */
  saveCheckboxState(checkboxId, isChecked) {
    this.errorHandler.safeExecute(() => {
      // Only save via API through progress tracker
      if (this.progressCore) {
        const progressData = { checkboxes: {} };
        progressData.checkboxes[checkboxId] = isChecked;
        progressData.lastUpdated = new Date().toISOString();

        this.progressCore.saveProgress(progressData);
        this.debugHelper.debug(`Saved checkbox state ${checkboxId}:`, isChecked);
      } else {
        throw new Error('No API available to save progress');
      }
    }, 'saveCheckboxState');
  }

  /**
   * Load saved progress from API
   * @private
   */
  async loadSavedProgress() {
    this.errorHandler.safeExecute(async () => {
      // Only load from API through progress tracker
      if (!this.progressCore) {
        this.debugHelper.debug('No API available to load progress');
        return;
      }

      try {
        const progressData = await this.progressCore.loadProgress(this.currentKataId);

        if (!progressData?.checkboxes) {
          this.debugHelper.debug('No saved progress found');
          return;
        }

        // Apply saved states to checkboxes
        Object.entries(progressData.checkboxes).forEach(([checkboxId, isChecked]) => {
          const checkbox = this.checkboxElements.get(checkboxId);
          if (checkbox) {
            checkbox.checked = isChecked;

            // Apply visual styling
            const listItem = checkbox.closest('li');
            if (listItem) {
              if (isChecked) {
                listItem.classList.add('completed-task');
              } else {
                listItem.classList.remove('completed-task');
              }
            }
          }
        });

        this.debugHelper.debug('Loaded saved progress:', progressData);
      } catch (error) {
        this.debugHelper.debug('Failed to load progress from API:', error);
      }
    }, 'loadSavedProgress');
  }

  /**
   * Trigger completion celebration
   * @private
   */
  triggerCompletionCelebration() {
    this.errorHandler.safeExecute(() => {
      // Check if unified progress tracker is available for animation
      const unifiedProgressContainer = document.querySelector('.kata-progress-bar-container');
      if (unifiedProgressContainer) {
        // Add celebration animation to unified progress container
        unifiedProgressContainer.classList.add('celebration-animation');

        // Remove animation class after animation completes
        setTimeout(() => {
          unifiedProgressContainer.classList.remove('celebration-animation');
        }, 2000);
      }

      // Fire custom event for other systems to listen to
      window.dispatchEvent(new CustomEvent('kataCompleted', {
        detail: {
          kataId: this.currentKataId,
          timestamp: new Date().toISOString()
        }
      }));

      this.debugHelper.debug('Kata completion celebration triggered');
    }, 'triggerCompletionCelebration');
  }

  /**
   * Get current progress data
   * @returns {Object|null} Progress data
   */
  getCurrentProgress() {
    return this.errorHandler.safeExecute(() => {
      if (!this.currentKataId || this.checkboxElements.size === 0) {
        return null;
      }

      const checkboxes = Array.from(this.checkboxElements.values());
      const totalTasks = checkboxes.length;
      const completedTasks = checkboxes.filter(cb => cb.checked).length;
      const completionPercentage = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;

      return {
        kataId: this.currentKataId,
        totalTasks,
        completedTasks,
        completionPercentage,
        checkboxStates: Object.fromEntries(
          Array.from(this.checkboxElements.entries()).map(([id, checkbox]) => [id, checkbox.checked])
        ),
        lastUpdated: new Date().toISOString()
      };
    }, 'getCurrentProgress', null);
  }

  /**
   * Extract category from current page path
   * @returns {string} Category identifier
   * @private
   */
  extractCategoryFromPath() {
    try {
      const path = window.location.hash || window.location.pathname;
      // Extract pattern like "/learning/katas/category/" or "#/learning/katas/category/"
      const categoryMatch = path.match(/\/learning\/katas\/([^/]+)/);
      return categoryMatch ? categoryMatch[1] : 'unknown';
    } catch {
      return 'unknown';
    }
  }

  /**
   * Extract title from current page
   * @returns {string} Page title
   * @private
   */
  extractTitleFromPage() {
    try {
      // Try to get title from h1 or h2, fall back to document title
      const heading = document.querySelector('h1, h2');
      if (heading) {
        return heading.textContent.trim();
      }

      // Extract from document title
      const title = document.title;
      if (title && title !== 'Loading...') {
        return title;
      }

      // Last resort: use kata ID
      return this.currentKataId ? this.currentKataId.replace(/-/g, ' ') : 'Unknown Kata';
    } catch {
      return 'Unknown Kata';
    }
  }

  /**
   * Cleanup interactive checkbox functionality
   * @private
   */
  cleanup() {
    this.errorHandler.safeExecute(() => {
      // Clear debounce timeout
      if (this.updateDebounceTimeout) {
        clearTimeout(this.updateDebounceTimeout);
        this.updateDebounceTimeout = null;
      }

      // Remove progress container
      if (this.progressContainer && this.progressContainer.parentNode) {
        this.progressContainer.remove();
        this.progressContainer = null;
      }

      // Remove event listeners from checkboxes
      this.checkboxElements.forEach((checkbox) => {
        checkbox.removeEventListener('change', this.handleCheckboxChange);
        checkbox.classList.remove('interactive-checkbox');
        delete checkbox.dataset.checkboxId;
      });

      // Clear references
      this.checkboxElements.clear();
      this.currentKataId = null;
      this.progressBar = null;
      this.progressText = null;
      this.progressPercentage = null;
      this.progressTasks = null;

      this.debugHelper.debug('Interactive checkboxes cleaned up');
    }, 'cleanup');
  }

  /**
   * Reset progress for current kata
   * @returns {boolean} Success status
   */
  resetProgress() {
    return this.errorHandler.safeExecute(() => {
      if (!this.currentKataId) {
        return false;
      }

      // Clear localStorage
      const storageKey = `${this.storagePrefix}${this.currentKataId}`;
      localStorage.removeItem(storageKey);

      // Uncheck all checkboxes
      this.checkboxElements.forEach((checkbox) => {
        checkbox.checked = false;

        const listItem = checkbox.closest('li');
        if (listItem) {
          listItem.classList.remove('completed-task');
        }
      });

      // Update progress display
      this.updateProgressDisplay();

      this.debugHelper.debug('Progress reset for kata:', this.currentKataId);
      return true;
    }, 'resetProgress', false);
  }

  /**
   * Get storage key for current kata
   * @returns {string|null} Storage key
   */
  getStorageKey() {
    return this.currentKataId ? `${this.storagePrefix}${this.currentKataId}` : null;
  }

  /**
   * Check if currently processing a kata page
   * @returns {boolean} Whether on kata page
   */
  isActive() {
    return !!this.currentKataId && this.checkboxElements.size > 0;
  }
}

// Create and initialize global instance
const interactiveCheckboxManager = new InteractiveCheckboxManager();

// Wire up dependency when progressBarManager becomes available
if (typeof window !== 'undefined') {
  // Check if progressBarManager is already available
  if (window.progressBarManager) {
    interactiveCheckboxManager.progressBarManager = window.progressBarManager;
  } else {
    // Listen for when it becomes available
    const checkForProgressBarManager = () => {
      if (window.progressBarManager && !interactiveCheckboxManager.progressBarManager) {
        interactiveCheckboxManager.progressBarManager = window.progressBarManager;
        this.debugHelper.debug('ProgressBarManager dependency wired');
      }
    };

    // Check periodically until it's available
    const dependencyChecker = setInterval(() => {
      if (window.progressBarManager) {
        checkForProgressBarManager();
        clearInterval(dependencyChecker);
      }
    }, 100);

    // Clear after 5 seconds to avoid infinite polling
    setTimeout(() => clearInterval(dependencyChecker), 5000);
  }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    interactiveCheckboxManager.init();
  });
} else {
  interactiveCheckboxManager.init();
}

// Export for module usage
export default interactiveCheckboxManager;

// Global access for debugging and integration
if (typeof window !== 'undefined') {
  window.interactiveCheckboxManager = interactiveCheckboxManager;
}
