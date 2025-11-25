/**
 * Simple Progress Bar Enhancement
 * Adds visual feedback and event integration to existing progress bars
 * Does NOT duplicate save/API functionality - only enhances existing behavior
 * @version 2.0.0
 */

import { ProgressClearManager } from './progress-clear-manager.js';
import { EnhancedProgressDataModel } from './enhanced-progress-data-model.js';

/**
 * SimpleProgressBarEnhancement - Lightweight enhancement for existing progress bars
 * Provides visual feedback and event integration without duplicating existing save logic
 */
export class SimpleProgressBarEnhancement {
  constructor() {
    this.isInitialized = false;
    this.progressContainer = null;
    this.saveButton = null;
    this.resetButton = null;
    this.lastProgressData = null;
    this.progressClearManager = null;

    // Only initialize if we're in a browser environment
    if (typeof document !== 'undefined') {
      this.init();
    }
  }

  /**
   * Initialize the enhancement on existing progress bars
   */
  init() {
    if (typeof window === 'undefined') {
      return;
    }

    // Only initialize on learning paths pages
    if (!this.isLearningPathsPage()) {
      return;
    }

    this.findProgressContainer();

    // If no progress container found, create one
    if (!this.progressContainer) {
      this.createProgressBarIfNeeded();
      this.findProgressContainer(); // Try to find elements again after creation
    }

    // If we still don't have a progress container, force create one
    if (!this.progressContainer) {
      this.forceCreateProgressBar();
      this.findProgressContainer();
    }

    if (this.progressContainer) {
      // Initialize enhanced progress data model and clear manager
      try {
        this.enhancedProgressDataModel = new EnhancedProgressDataModel();
        this.progressClearManager = new ProgressClearManager({
          enhancedProgressDataModel: this.enhancedProgressDataModel
        });
      } catch (error) {
        // eslint-disable-next-line no-console
        console.warn('Failed to initialize progress modules:', error);
      }

      this.attachEventListeners();
      this.extractAndDisplayProgress();
      this.isInitialized = true;

      // Listen for plugin events
      this.listenForPluginEvents();
    }

    // Always expose to window for debugging
    if (typeof window !== 'undefined') {
      window.SimpleProgressBarExtension = this;
    }
  }

  /**
   * Update enhanced progress bar if it exists
   */
  updateEnhancedProgressBar() {
    // Check if there's an enhanced progress bar component on the page
    const enhancedProgressBar = window.enhancedProgressBarComponent;
    if (enhancedProgressBar && enhancedProgressBar.updateProgress) {
      const progressData = this.extractProgressData();
      if (progressData) {
        // Count checkboxes by their action type for more accurate stats
        const addToPathCheckboxes = document.querySelectorAll('input[data-action="add-to-path"]');
        const completedCheckboxes = document.querySelectorAll('input[data-action="mark-completed"]');

        const pathItems = Array.from(addToPathCheckboxes).filter(cb => cb.checked).length;
        const completedItems = Array.from(completedCheckboxes).filter(cb => cb.checked).length;

        enhancedProgressBar.updateProgress(completedItems, pathItems, {
          isRecentActivity: true
        });
      }
    }
  }

  /**
   * Extract progress data and update display
   */
  extractAndDisplayProgress() {
    const progressData = this.extractProgressData();

    if (progressData) {
      this.updateProgressDisplay(progressData.completionPercentage, progressData.progressText);
    }
  }

  /**
   * Listen for events from the main progress plugin
   */
  listenForPluginEvents() {
    // Listen for checkbox changes to update progress
    document.addEventListener('change', (_event) => {
      if (_event.target.type === 'checkbox') {
        // Update progress display when checkboxes change
        setTimeout(() => {
          this.extractAndDisplayProgress();
          this.updateEnhancedProgressBar();
        }, 100); // Small delay to ensure DOM is updated
      }
    });

    // Listen for plugin events if they exist
    document.addEventListener('progressUpdated', (_event) => {
      this.extractAndDisplayProgress();
      this.updateEnhancedProgressBar();
    });
  }

  /**
   * Create progress bar elements if they don't exist
   */
  createProgressBarIfNeeded() {
    // Only create on learning paths pages
    if (!this.isLearningPathsPage()) {
      return;
    }

    // Check if we have learning path items (indicating this is a trackable page)
    const checkboxes = document.querySelectorAll('input[type="checkbox"]');
    const _learningPathItems = document.querySelectorAll('.learning-path-item');
    const _pathItems = document.querySelectorAll('[class*="path-item"]');

    if (checkboxes.length === 0) {
      return;
    }

    return this.forceCreateProgressBar();
  }

  /**
   * Force create a progress bar regardless of existing elements
   */
  forceCreateProgressBar() {
    // Create the progress bar HTML using the same structure as the plugin
    const progressBarHTML = `
      <div id="learning-progress-banner" class="kata-progress-bar-container">
        <div class="kata-progress-content">
          <div class="kata-progress-left">
            <div class="kata-progress-label">📚 Learning Paths Progress</div>
            <div class="kata-progress-bar-track">
              <div class="kata-progress-bar-fill" style="width: 0%"></div>
            </div>
            <div class="kata-progress-percentage">0% Complete (0/0 paths selected)</div>
          </div>
          <div class="kata-progress-actions">
            <button class="kata-progress-btn kata-progress-btn-save" type="button" title="Save Learning Path Selections">
              💾 Save
            </button>
            <button class="kata-progress-btn kata-progress-btn-reset" type="button" title="Clear Learning Path Selections">
              🗑️ Clear
            </button>
          </div>
          <div class="kata-progress-status" style="display: none;"></div>
        </div>
      </div>
    `;

    // Insert at the top of the main content area
    const contentArea = document.querySelector('#main') ||
                       document.querySelector('.content') ||
                       document.querySelector('main') ||
                       document.body;

    if (contentArea) {
      contentArea.insertAdjacentHTML('afterbegin', progressBarHTML);
      return true;
    } else {
      return false;
    }
  }

  /**
   * Check if current page is a learning paths page
   */
  isLearningPathsPage() {
    const currentPath = window.location.hash || window.location.pathname;

    // Check for learning paths URL patterns
    const isLearningPathsPage = currentPath.includes('/learning-paths') ||
                               currentPath.includes('/learning/learning-paths') ||
                               currentPath.includes('learning-paths');

    // Also check for learning paths content indicators
    const hasLearningPathsContent = document.querySelector('.learning-paths-dashboard') ||
                                   document.querySelector('[class*="learning-path"]') ||
                                   document.title.toLowerCase().includes('learning path') ||
                                   document.querySelector('h1, h2, h3')?.textContent.toLowerCase().includes('learning path');

    return isLearningPathsPage || hasLearningPathsContent;
  }

  /**
   * Get learning path label for a checkbox
   */
  getLearningPathLabel(checkbox) {
    // Try to find the associated label or nearby text
    const label = checkbox.closest('label') ||
                 document.querySelector(`label[for="${checkbox.id}"]`) ||
                 checkbox.parentElement;

    if (label && label.textContent) {
      return label.textContent.trim();
    }

    // Try to find nearby text content
    const nearbyText = checkbox.nextSibling?.textContent ||
                      checkbox.parentElement?.textContent ||
                      checkbox.value ||
                      checkbox.name ||
                      'Unknown Path';

    return nearbyText.trim();
  }

  /**
   * Find existing progress container and buttons
   */
  findProgressContainer() {
    // Look for existing progress container with proper priority
    this.progressContainer = document.querySelector('#learning-progress-banner') ||
                            document.querySelector('.kata-progress-bar-container') ||
                            document.querySelector('.progress-container') ||
                            document.querySelector('.progress-bar-container') ||
                            document.querySelector('#progress-container');

    // If we found a generic progress element that's not our expected structure, skip it
    if (!this.progressContainer) {
      const genericProgress = document.querySelector('.progress');
      if (genericProgress && !genericProgress.querySelector('.kata-progress-bar-fill')) {
        this.progressContainer = null;
      }
    }

    // If no progress container exists and we're on learning paths, create one
    if (!this.progressContainer && this.isLearningPathsPage()) {
      this.createProgressBarIfNeeded();
      // Try to find the progress container again after creation
      this.progressContainer = document.querySelector('#learning-progress-banner') ||
                              document.querySelector('.kata-progress-bar-container');
    }

    if (this.progressContainer) {
      // Find save/reset buttons - check for existing kata progress buttons first
      this.saveButton = this.progressContainer.querySelector('.kata-progress-btn-save') ||
                       document.getElementById('save-progress-btn') ||
                       document.querySelector('[data-action="save-progress"]') ||
                       document.querySelector('.save-progress');

      this.resetButton = this.progressContainer.querySelector('.kata-progress-btn-reset') ||
                        this.progressContainer.querySelector('.kata-progress-btn-clear') ||
                        document.getElementById('clear-progress-btn') ||
                        document.getElementById('reset-progress-btn') ||
                        document.querySelector('[data-action="reset-progress"]') ||
                        document.querySelector('[data-action="clear-progress"]') ||
                        document.querySelector('.reset-progress') ||
                        document.querySelector('.clear-progress');

      // Make sure the progress container is visible after finding it
      if (this.progressContainer) {
        this.progressContainer.style.opacity = '1';
        this.progressContainer.style.display = 'flex';
        this.progressContainer.style.visibility = 'visible';
      }
    }
  }

  /**
   * Attach event listeners to existing buttons
   */
  attachEventListeners() {
    // Listen for the existing plugin's save events (if plugin exists)
    document.addEventListener('progressSaveCompleted', (_event) => {
      this.handleExistingSaveEvent(_event);
    });

    document.addEventListener('progressClearCompleted', (_event) => {
      this.handleExistingClearEvent(_event);
    });

    // Listen for checkbox changes to update visual feedback
    document.addEventListener('change', (_event) => {
      if (_event.target.type === 'checkbox') {
        this.handleCheckboxChange(_event);
      }
    });

    // Add button click handlers
    if (this.saveButton) {
      this.saveButton.addEventListener('click', (_event) => this.handleSaveButtonClick(_event));
    }

    if (this.resetButton) {
      this.resetButton.addEventListener('click', (_event) => this.handleClearButtonClick(_event));
    }
  }

  /**
   * Handle existing plugin save events
   */
  handleExistingSaveEvent(_event) {
    this.showSuccessMessage('Progress saved successfully!');
  }

  /**
   * Handle existing plugin clear events
   */
  handleExistingClearEvent(_event) {
    this.showSuccessMessage('Progress cleared successfully!');
  }

  /**
   * Handle checkbox changes (visual feedback only)
   */
  handleCheckboxChange(_event) {
    // Update our internal state and provide visual feedback
    this.lastProgressData = this.extractProgressData();

    if (this.lastProgressData) {
      this.updateProgressVisualFeedback(this.lastProgressData);
    }
  }

  /**
   * Add visual feedback when save button is clicked
   */
  addSaveVisualFeedback(_event) {
    if (this.saveButton) {
      this.saveButton.classList.add('btn-loading');
      this.saveButton.disabled = true;

      // Remove loading state after a short delay (real save should complete quickly)
      setTimeout(() => {
        if (this.saveButton) {
          this.saveButton.classList.remove('btn-loading');
          this.saveButton.disabled = false;
        }
      }, 2000);
    }
  }

  /**
   * Add visual feedback when reset button is clicked
   */
  addResetVisualFeedback(_event) {
    if (this.resetButton) {
      this.resetButton.classList.add('btn-loading');
      this.resetButton.disabled = true;

      setTimeout(() => {
        if (this.resetButton) {
          this.resetButton.classList.remove('btn-loading');
          this.resetButton.disabled = false;
        }
      }, 1000);
    }
  }

  /**
   * Show success message (non-intrusive)
   */
  showSuccessMessage(message) {
    // Create or update success indicator
    let indicator = document.querySelector('.progress-success-indicator');

    if (!indicator) {
      indicator = document.createElement('div');
      indicator.className = 'progress-success-indicator';
      indicator.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: #28a745;
        color: white;
        padding: 10px 15px;
        border-radius: 4px;
        z-index: 1000;
        font-size: 14px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        opacity: 0;
        transition: opacity 0.3s ease;
      `;
      document.body.appendChild(indicator);
    }

    indicator.textContent = message;
    indicator.style.opacity = '1';

    // Hide after 3 seconds
    setTimeout(() => {
      if (indicator) {
        indicator.style.opacity = '0';
        setTimeout(() => {
          if (indicator && indicator.parentNode) {
            indicator.parentNode.removeChild(indicator);
          }
        }, 300);
      }
    }, 3000);
  }

  /**
   * Update visual progress feedback
   */
  updateProgressVisualFeedback(progressData) {
    if (!this.progressContainer || !progressData) {return;}

    // Add subtle visual feedback for progress changes
    this.progressContainer.classList.add('progress-updated');

    setTimeout(() => {
      if (this.progressContainer) {
        this.progressContainer.classList.remove('progress-updated');
      }
    }, 500);

    // Update any progress displays if they exist
    const progressText = this.progressContainer.querySelector('.progress-text');
    if (progressText && progressData.progressText) {
      progressText.textContent = progressData.progressText;
    }
  }

  /**
   * Extract progress data from existing progress bar or checkboxes
   */
  extractProgressData() {
    if (!this.progressContainer) {return null;}

    // First, try to get data from learning path checkboxes
    const checkboxes = document.querySelectorAll('input[type="checkbox"]');
    if (checkboxes.length > 0) {
      const checkedCount = Array.from(checkboxes).filter(cb => cb.checked).length;
      const completionPercentage = Math.round((checkedCount / checkboxes.length) * 100);

      return {
        totalPaths: checkboxes.length,
        selectedPaths: checkedCount,
        completionPercentage,
        progressText: `${checkedCount} of ${checkboxes.length} paths selected`,
        timestamp: new Date().toISOString(),
        source: 'learning-paths-progress-bar',
        container: this.progressContainer.className || 'unknown',
        pathSelections: Array.from(checkboxes).map((cb, index) => ({
          index,
          selected: cb.checked,
          id: cb.id || null,
          name: cb.name || null,
          value: cb.value || null,
          label: this.getLearningPathLabel(cb)
        }))
      };
    }

    // Fallback: try to get data from progress bar visual elements
    const progressFill = this.progressContainer.querySelector('.progress-fill') ||
                        this.progressContainer.querySelector('[style*="width"]');

    const progressText = this.progressContainer.querySelector('.progress-text') ||
                        this.progressContainer.querySelector('.progress-label') ||
                        this.progressContainer.textContent;

    let completionPercentage = 0;

    if (progressFill) {
      const widthStyle = progressFill.style.width || progressFill.getAttribute('style') || '';
      const match = widthStyle.match(/(\d+)%/);
      if (match) {
        completionPercentage = parseInt(match[1]);
      }
    }

    return {
      completionPercentage,
      progressText: typeof progressText === 'string' ? progressText : progressText?.textContent || '',
      timestamp: new Date().toISOString(),
      source: 'enhanced-progress-bar',
      container: this.progressContainer.className || 'unknown'
    };
  }

  /**
   * Update progress display (visual enhancement only)
   */
  updateProgressDisplay(percentage, text) {
    if (!this.progressContainer) {return;}

    // Find progress elements using the specific structure we created
    const progressFill = this.progressContainer.querySelector('.kata-progress-bar-fill') ||
                        this.progressContainer.querySelector('.progress-fill') ||
                        this.progressContainer.querySelector('#progress-bar-fill');

    const progressText = this.progressContainer.querySelector('.kata-progress-description') ||
                        this.progressContainer.querySelector('.progress-text') ||
                        this.progressContainer.querySelector('#progress-description');

    const progressPercentage = this.progressContainer.querySelector('.kata-progress-percentage') ||
                              this.progressContainer.querySelector('.progress-percentage') ||
                              this.progressContainer.querySelector('#progress-percentage');

    if (progressFill) {
      progressFill.style.width = `${percentage}%`;
      progressFill.style.opacity = '1'; // Ensure visibility
      progressFill.style.minWidth = percentage > 0 ? '12px' : '0'; // Show at least 12px when there's progress
    }

    if (progressText) {
      progressText.textContent = text || `${percentage}% complete`;
    }

    if (progressPercentage) {
      progressPercentage.textContent = `${percentage}% Complete (${text || 'No selection'})`;
    }

    // Make sure the container is visible
    if (this.progressContainer) {
      this.progressContainer.style.opacity = '1';
      this.progressContainer.style.display = 'flex';
      this.progressContainer.style.visibility = 'visible';
    }

    // Add visual feedback
    this.updateProgressVisualFeedback({ progressText: text });
  }

  /**
   * Handle save button click
   */
  async handleSaveButtonClick(event) {
    event.preventDefault();

    if (!this.saveButton) {return;}

    // Show loading state
    const originalText = this.saveButton.textContent;
    this.saveButton.textContent = '💾 Saving...';
    this.saveButton.disabled = true;

    try {
      const progressData = this.extractProgressData();

      if (progressData.completionPercentage === 0) {
        this.showMessage('No learning paths selected yet!', 'warning');
        return;
      }

      // Try to save via API if available
      const saved = await this.saveProgressToAPI(progressData);

      if (saved) {
        this.showMessage(`Learning path selection saved! ${progressData.selectedPaths}/${progressData.totalPaths} paths selected`, 'success');
      } else {
        throw new Error('API save failed');
      }
    } catch (_error) {
      // Log error for debugging and tests
      this.showErrorMessage('Failed to save progress');
    } finally {
      // Restore button state
      this.saveButton.textContent = originalText;
      this.saveButton.disabled = false;
    }
  }

  /**
   * Handle clear button click
   */
  async handleClearButtonClick(event) {
    event.preventDefault();

    if (!this.resetButton) {return;}

    // Use ProgressClearManager for integrated clear functionality
    if (this.progressClearManager) {
      try {
        const success = await this.progressClearManager.handleClearRequest({
          type: 'all',
          confirmationRequired: true
        });

        if (success) {
          // Clear UI elements - checkboxes and local backup
          const checkboxes = document.querySelectorAll('input[type="checkbox"]');
          checkboxes.forEach(cb => cb.checked = false);

          // Update progress display
          this.updateProgressDisplay(0, '0 of 0 paths selected');

          this.showMessage('Learning path selection cleared successfully', 'success');
        } else {
          this.showErrorMessage('Clear operation was cancelled or failed');
        }
      } catch (error) {
        // eslint-disable-next-line no-console
        console.error('Clear operation failed:', error);
        this.showErrorMessage('Failed to clear progress');
      }
    } else {
      // Fallback to original logic if ProgressClearManager not available
      const confirmed = await this.showConfirmationModal();
      if (!confirmed) {return;}

      // Show loading state
      const originalText = this.resetButton.textContent;
      this.resetButton.textContent = '🗑️ Clearing...';
      this.resetButton.disabled = true;

      try {
        // Clear all checkboxes
        const checkboxes = document.querySelectorAll('input[type="checkbox"]');
        checkboxes.forEach(cb => cb.checked = false);

        // Update progress display
        this.updateProgressDisplay(0, '0 of 0 paths selected');

        // Try to clear via API if available
        await this.clearProgressFromAPI();

        // Clear localStorage
        localStorage.removeItem('learning-paths-selection-backup');

        this.showMessage('Learning path selection cleared successfully', 'success');
      } catch (_error) {
        this.showErrorMessage('Failed to clear progress');
      } finally {
        // Restore button state
        this.resetButton.textContent = originalText;
        this.resetButton.disabled = false;
      }
    }
  }

  /**
   * Save progress to API
   */
  async saveProgressToAPI(progressData) {
    try {
      const response = await fetch('/api/progress/save', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(progressData)
      });

      if (!response.ok) {
        throw new Error(`API save failed: ${response.status}`);
      }

      return true;
    } catch (error) {
      throw error;
    }
  }

  /**
   * Clear progress from API
   */
  async clearProgressFromAPI() {
    try {
      await fetch('/api/progress/clear', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          type: 'all' // Clear all progress data
        })
      });
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('API clear failed:', error);
      // API clear failed, but localStorage will be cleared anyway
    }
  }

  /**
   * Show confirmation modal for clear operation
   * @returns {Promise<boolean>} True if confirmed
   */
  async showConfirmationModal() {
    return new Promise(resolve => {
      const modal = document.createElement('div');
      modal.style.cssText = 'position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);background:white;padding:20px;border:1px solid #ccc;border-radius:8px;box-shadow:0 4px 6px rgba(0,0,0,0.1);z-index:10000';
      modal.innerHTML = '<p>Are you sure you want to clear all learning path selections? This action cannot be undone.</p><button id="clear-yes" style="margin-right:10px;padding:8px 16px;background:#007cba;color:white;border:none;border-radius:4px;cursor:pointer">Yes</button><button id="clear-no" style="padding:8px 16px;background:#ccc;color:black;border:none;border-radius:4px;cursor:pointer">No</button>';
      document.body.appendChild(modal);

      document.getElementById('clear-yes').onclick = () => { document.body.removeChild(modal); resolve(true); };
      document.getElementById('clear-no').onclick = () => { document.body.removeChild(modal); resolve(false); };
    });
  }

  /**
   * Show user message
   */
  showMessage(text, type = 'info') {
    // Create or update message display
    let messageEl = document.getElementById('progress-message');
    if (!messageEl) {
      messageEl = document.createElement('div');
      messageEl.id = 'progress-message';
      messageEl.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 10px 15px;
        border-radius: 4px;
        font-size: 14px;
        z-index: 10000;
        max-width: 300px;
      `;
      document.body.appendChild(messageEl);
    }

    // Set message style based on type
    const styles = {
      success: 'background: #d4edda; color: #155724; border: 1px solid #c3e6cb;',
      error: 'background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb;',
      warning: 'background: #fff3cd; color: #856404; border: 1px solid #ffeaa7;',
      info: 'background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb;'
    };

    messageEl.style.cssText += styles[type] || styles.info;
    messageEl.textContent = text;

    // Auto-hide after 3 seconds
    setTimeout(() => {
      if (messageEl.parentNode) {
        messageEl.parentNode.removeChild(messageEl);
      }
    }, 3000);
  }

  /**
   * Show error message
   */
  showErrorMessage(message) {
    this.showMessage(message, 'error');
  }

  /**
   * Destroy the enhancement
   */
  destroy() {
    // Remove our event listeners
    document.removeEventListener('progressSaveCompleted', this.handleExistingSaveEvent);
    document.removeEventListener('progressClearCompleted', this.handleExistingClearEvent);
    document.removeEventListener('change', this.handleCheckboxChange);

    if (this.saveButton) {
      this.saveButton.removeEventListener('click', this.addSaveVisualFeedback);
    }
    if (this.resetButton) {
      this.resetButton.removeEventListener('click', this.addResetVisualFeedback);
    }

    this.progressContainer = null;
    this.saveButton = null;
    this.resetButton = null;
    this.isInitialized = false;
  }
}

// Only auto-initialize when imported in a browser environment
let progressEnhancement = null;
if (typeof document !== 'undefined') {
  progressEnhancement = new SimpleProgressBarEnhancement();

  // Expose to window for debugging
  if (typeof window !== 'undefined') {
    window.progressEnhancement = progressEnhancement;
    window.SimpleProgressBarEnhancement = SimpleProgressBarEnhancement;
  }
}

// Export for external use
export default progressEnhancement;
