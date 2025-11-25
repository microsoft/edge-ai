/**
 * Interactive Progress Component
 * Provides floating progress bar with save/clear functionality for kata progress tracking
 * @version 2.0.0
 */

/**
 * FloatingProgressBar - Interactive progress display with action buttons
 * Displays progress state and provides save/clear functionality
 */
export class FloatingProgressBar {
  constructor(storageManager = null) {
    this.storageManager = storageManager;
    this.isVisible = false;
    this.isMinimized = false;
    this.currentProgress = {
      totalTasks: 0,
      completedTasks: 0,
      completionPercentage: 0,
      kataId: null
    };

    // DOM references
    this.containerElement = null;
    this.progressBarFill = null;
    this.progressText = null;
    this.progressPercentage = null;
    this.saveButton = null;
    this.clearButton = null;
    this.minimizeButton = null;

    this.initializeEventListeners();
  }

  /**
   * Initialize event listeners for progress updates
   */
  initializeEventListeners() {
    // Listen for progress updates from other components
    document.addEventListener('progressUpdated', (event) => {
      this.updateProgress(event.detail);
    });

    // Listen for kata navigation changes
    document.addEventListener('kataChanged', (event) => {
      this.handleKataChange(event.detail);
    });
  }

  /**
   * Create and inject the floating progress bar HTML
   */
  createProgressBar() {
    if (this.containerElement) {
      return; // Already created
    }

    const progressBarHTML = `
      <div class="kata-progress-bar-container" id="kata-progress-bar">
        <div class="kata-progress-content">
          <!-- Left side: label, progress bar, percentage -->
          <div class="kata-progress-left">
            <div class="kata-progress-label">
              <span class="kata-progress-title">Kata Progress</span>
              <span class="kata-progress-description" id="progress-description">0 of 0 tasks completed</span>
            </div>
            <div class="kata-progress-bar">
              <div class="kata-progress-bar-track">
                <div class="kata-progress-bar-fill" id="progress-bar-fill" style="width: 0%"></div>
              </div>
            </div>
            <div class="kata-progress-percentage" id="progress-percentage">0%</div>
          </div>

          <!-- Right side: action buttons -->
          <div class="kata-progress-actions">
            <button class="kata-progress-btn kata-progress-btn-save" id="save-progress-btn" title="Save progress to file">
              💾 Save
            </button>
            <button class="kata-progress-btn kata-progress-btn-clear" id="clear-progress-btn" title="Clear all progress">
              🗑️ Clear
            </button>
            <button class="kata-progress-btn kata-progress-btn-minimize" id="minimize-progress-btn" title="Minimize progress bar">
              ➖
            </button>
          </div>
        </div>
      </div>
    `;

    // Insert progress bar into DOM
    document.body.insertAdjacentHTML('beforeend', progressBarHTML);

    // Cache DOM references
    this.containerElement = document.getElementById('kata-progress-bar');
    this.progressBarFill = document.getElementById('progress-bar-fill');
    this.progressText = document.getElementById('progress-description');
    this.progressPercentage = document.getElementById('progress-percentage');
    this.saveButton = document.getElementById('save-progress-btn');
    this.clearButton = document.getElementById('clear-progress-btn');
    this.minimizeButton = document.getElementById('minimize-progress-btn');

    // Attach event listeners
    this.attachEventListeners();

    // Add content spacing adjustment
    document.body.classList.add('content-with-progress-bar');
  }

  /**
   * Attach event listeners to progress bar buttons
   */
  attachEventListeners() {
    if (this.saveButton) {
      this.saveButton.addEventListener('click', () => this.handleSave());
    }

    if (this.clearButton) {
      this.clearButton.addEventListener('click', () => this.handleClear());
    }

    if (this.minimizeButton) {
      this.minimizeButton.addEventListener('click', () => this.toggleMinimize());
    }
  }

  /**
   * Update progress display with new data
   * @param {Object} progressData - Progress information
   */
  updateProgress(progressData) {
    this.currentProgress = { ...progressData };

    if (!this.containerElement) {
      this.createProgressBar();
    }

    this.renderProgress();

    if (!this.isVisible && this.currentProgress.totalTasks > 0) {
      this.show();
    }
  }

  /**
   * Render current progress state to DOM
   */
  renderProgress() {
    if (!this.containerElement) {return;}

    const { totalTasks, completedTasks, completionPercentage } = this.currentProgress;

    // Update progress text
    if (this.progressText) {
      this.progressText.textContent = `${completedTasks} of ${totalTasks} tasks completed`;
    }

    // Update percentage display
    if (this.progressPercentage) {
      this.progressPercentage.textContent = `${Math.round(completionPercentage)}%`;
    }

    // Update progress bar fill
    if (this.progressBarFill) {
      this.progressBarFill.style.width = `${completionPercentage}%`;

      // Add complete class for 100% completion
      if (completionPercentage >= 100) {
        this.progressBarFill.classList.add('complete');
      } else {
        this.progressBarFill.classList.remove('complete');
      }
    }

    // Update button states
    this.updateButtonStates();
  }

  /**
   * Update button enabled/disabled states based on progress
   */
  updateButtonStates() {
    const _hasProgress = this.currentProgress.totalTasks > 0;
    const hasCompletedTasks = this.currentProgress.completedTasks > 0;

    if (this.saveButton) {
      this.saveButton.disabled = !hasCompletedTasks;
      this.saveButton.title = hasCompletedTasks ?
        'Save progress to file' :
        'No progress to save';
    }

    if (this.clearButton) {
      this.clearButton.disabled = !hasCompletedTasks;
      this.clearButton.title = hasCompletedTasks ?
        'Clear all progress' :
        'No progress to clear';
    }
  }

  /**
   * Handle save button click
   */
  async handleSave() {
    if (this.currentProgress.completedTasks === 0) {
      return;
    }

    try {
      // Show save options dialog
      const saveOptions = await this.showSaveOptionsDialog();
      if (!saveOptions) {
        return; // User cancelled
      }

      // Add loading state
      this.saveButton.textContent = '💾 Saving...';
      this.saveButton.disabled = true;

      // Dispatch save request with user-selected options
      const event = new CustomEvent('progressSaveRequested', {
        detail: {
          progressData: this.currentProgress,
          kataId: this.currentProgress.kataId,
          exportFormat: saveOptions.format,
          exportTarget: saveOptions.target,
          timestamp: new Date().toISOString()
        }
      });
      document.dispatchEvent(event);

      // Wait for save completion event
      await this.waitForSaveCompletion();

    } catch (_error) {
      await this.showTemporaryFeedback('❌ Save failed', 'error');
    } finally {
      // Restore button state
      this.saveButton.textContent = '💾 Save';
      this.saveButton.disabled = this.currentProgress.completedTasks === 0;
    }
  }

  /**
   * Handle clear button click with confirmation
   */
  async handleClear() {
    if (this.currentProgress.completedTasks === 0) {
      return;
    }

    // Show confirmation dialog
    const confirmed = await this.showClearConfirmation();
    if (!confirmed) {
      return;
    }

    try {
      // Add loading state
      this.clearButton.textContent = '🗑️ Clearing...';
      this.clearButton.disabled = true;

      // Set up one-time listener for clear completion
      const clearCompletionHandler = (event) => {
        const { success, clearedItems, error } = event.detail;
        if (success) {
          this.showTemporaryFeedback(`✅ Cleared ${clearedItems} items!`, 'success');
          // Reset progress display
          this.currentProgress = { completedTasks: 0, totalTasks: 0, completionPercentage: 0 };
          this.updateProgress();
        } else {
          this.showTemporaryFeedback(`❌ Clear failed: ${error}`, 'error');
        }

        // Restore button state
        this.clearButton.textContent = '🗑️ Clear';
        this.clearButton.disabled = this.currentProgress.completedTasks === 0;

        // Remove the one-time listener
        document.removeEventListener('progressClearCompleted', clearCompletionHandler);
      };

      // Add the completion listener
      document.addEventListener('progressClearCompleted', clearCompletionHandler);

      // Trigger clear functionality
      const event = new CustomEvent('progressClearRequested', {
        detail: {
          kataId: this.currentProgress.kataId,
          timestamp: new Date().toISOString()
        }
      });
      document.dispatchEvent(event);

    } catch (_error) {
      await this.showTemporaryFeedback('❌ Clear failed', 'error');

      // Restore button state on error
      this.clearButton.textContent = '🗑️ Clear';
      this.clearButton.disabled = this.currentProgress.completedTasks === 0;
    }
    // Note: Button state restoration is handled by the completion event listener
  }

  /**
   * Show confirmation dialog for clear operation
   * @returns {Promise<boolean>} User confirmation result
   */
  showClearConfirmation() {
    return new Promise((resolve) => {
      const { completedTasks, totalTasks } = this.currentProgress;
      const message = `Are you sure you want to clear all progress?\n\nThis will reset ${completedTasks} completed task${completedTasks !== 1 ? 's' : ''} out of ${totalTasks} total tasks.\n\nThis action cannot be undone unless you have saved your progress.`;

      // Use custom modal instead of browser confirm
      const modal = document.createElement('div');
      modal.style.cssText = 'position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);background:white;padding:20px;border:1px solid #ccc;border-radius:8px;box-shadow:0 4px 6px rgba(0,0,0,0.1);z-index:10000';
      modal.innerHTML = `<p>${message}</p><button id="confirm-yes" style="margin-right:10px;padding:8px 16px;background:#007cba;color:white;border:none;border-radius:4px;cursor:pointer">Yes</button><button id="confirm-no" style="padding:8px 16px;background:#ccc;color:black;border:none;border-radius:4px;cursor:pointer">No</button>`;
      document.body.appendChild(modal);

      document.getElementById('confirm-yes').onclick = () => { document.body.removeChild(modal); resolve(true); };
      document.getElementById('confirm-no').onclick = () => { document.body.removeChild(modal); resolve(false); };
    });
  }

  /**
   * Show save options dialog
   * @returns {Promise<Object|null>} Save options or null if cancelled
   */
  showSaveOptionsDialog() {
    return new Promise((resolve) => {
      // Create modal overlay
      const overlay = document.createElement('div');
      overlay.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.7);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 10000;
      `;

      // Create modal dialog
      const dialog = document.createElement('div');
      dialog.style.cssText = `
        background: white;
        border-radius: 8px;
        padding: 24px;
        max-width: 400px;
        width: 90%;
        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2);
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      `;

      dialog.innerHTML = `
        <h3 style="margin: 0 0 16px 0; color: #333;">Save Progress</h3>
        <div style="margin-bottom: 16px;">
          <label style="display: block; margin-bottom: 8px; font-weight: 500; color: #555;">Format:</label>
          <select id="formatSelect" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;">
            <option value="json">JSON (complete data)</option>
            <option value="csv">CSV (spreadsheet format)</option>
            <option value="txt">Text (human readable)</option>
          </select>
        </div>
        <div style="margin-bottom: 20px;">
          <label style="display: block; margin-bottom: 8px; font-weight: 500; color: #555;">Save to:</label>
          <select id="targetSelect" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;">
            <option value="download">Download file</option>
            <option value="clipboard">Copy to clipboard</option>
            <option value="localStorage">Local backup</option>
          </select>
        </div>
        <div style="display: flex; gap: 12px; justify-content: flex-end;">
          <button id="cancelBtn" style="padding: 8px 16px; border: 1px solid #ddd; background: white; border-radius: 4px; cursor: pointer;">Cancel</button>
          <button id="saveBtn" style="padding: 8px 16px; border: none; background: #007bff; color: white; border-radius: 4px; cursor: pointer;">Save</button>
        </div>
      `;

      overlay.appendChild(dialog);
      document.body.appendChild(overlay);

      // Handle button clicks
      const formatSelect = dialog.querySelector('#formatSelect');
      const targetSelect = dialog.querySelector('#targetSelect');
      const cancelBtn = dialog.querySelector('#cancelBtn');
      const saveBtn = dialog.querySelector('#saveBtn');

      const cleanup = () => {
        document.body.removeChild(overlay);
      };

      cancelBtn.onclick = () => {
        cleanup();
        resolve(null);
      };

      saveBtn.onclick = () => {
        const options = {
          format: formatSelect.value,
          target: targetSelect.value
        };
        cleanup();
        resolve(options);
      };

      // Close on overlay click
      overlay.onclick = (e) => {
        if (e.target === overlay) {
          cleanup();
          resolve(null);
        }
      };

      // Focus the save button
      saveBtn.focus();
    });
  }

  /**
   * Wait for save completion event
   * @returns {Promise} Save completion promise
   */
  waitForSaveCompletion() {
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        document.removeEventListener('progressSaveCompleted', handleSaveCompleted);
        reject(new Error('Save operation timed out'));
      }, 30000); // 30 second timeout

      const handleSaveCompleted = (event) => {
        clearTimeout(timeout);
        document.removeEventListener('progressSaveCompleted', handleSaveCompleted);

        const { success, result } = event.detail;
        if (success) {
          this.showTemporaryFeedback('✅ Progress saved!', 'success');
          resolve(result);
        } else {
          this.showTemporaryFeedback('❌ Save failed', 'error');
          reject(new Error(result.error || 'Save failed'));
        }
      };

      document.addEventListener('progressSaveCompleted', handleSaveCompleted);
    });
  }

  /**
   * Show temporary feedback message
   * @param {string} message - Feedback message
   * @param {string} type - 'success' or 'error'
   */
  showTemporaryFeedback(message, type = 'success') {
    return new Promise((resolve) => {
      const originalText = this.progressText?.textContent || '';

      if (this.progressText) {
        this.progressText.textContent = message;
        this.progressText.style.color = type === 'success' ? '#28a745' : '#dc3545';
        this.progressText.style.fontWeight = '600';
      }

      setTimeout(() => {
        if (this.progressText) {
          this.progressText.textContent = originalText;
          this.progressText.style.color = '';
          this.progressText.style.fontWeight = '';
        }
        resolve();
      }, 2000);
    });
  }

  /**
   * Toggle minimize/expand state
   */
  toggleMinimize() {
    this.isMinimized = !this.isMinimized;

    if (this.isMinimized) {
      this.containerElement?.classList.add('minimized');
      if (this.minimizeButton) {
        this.minimizeButton.textContent = '➕';
        this.minimizeButton.title = 'Expand progress bar';
      }
    } else {
      this.containerElement?.classList.remove('minimized');
      if (this.minimizeButton) {
        this.minimizeButton.textContent = '➖';
        this.minimizeButton.title = 'Minimize progress bar';
      }
    }
  }

  /**
   * Show the progress bar
   */
  show() {
    if (!this.containerElement) {
      this.createProgressBar();
    }

    this.containerElement.style.display = 'flex';
    this.isVisible = true;

    // Add content spacing
    document.body.classList.add('content-with-progress-bar');
  }

  /**
   * Hide the progress bar
   */
  hide() {
    if (this.containerElement) {
      this.containerElement.style.display = 'none';
    }
    this.isVisible = false;

    // Remove content spacing
    document.body.classList.remove('content-with-progress-bar');
  }

  /**
   * Handle kata change (new kata loaded)
   * @param {Object} kataData - New kata information
   */
  handleKataChange(kataData) {
    // Reset progress for new kata
    this.currentProgress = {
      totalTasks: 0,
      completedTasks: 0,
      completionPercentage: 0,
      kataId: kataData.kataId || null
    };

    if (this.isVisible) {
      this.renderProgress();
    }
  }

  /**
   * Remove the progress bar from DOM
   */
  destroy() {
    if (this.containerElement) {
      this.containerElement.remove();
      this.containerElement = null;
    }

    // Remove content spacing
    document.body.classList.remove('content-with-progress-bar');

    // Reset state
    this.isVisible = false;
    this.isMinimized = false;
  }

  /**
   * Get current progress data
   * @returns {Object} Current progress information
   */
  getCurrentProgress() {
    return { ...this.currentProgress };
  }
}

/**
 * Progress Bar Manager - Singleton for managing FloatingProgressBar instance
 */
export class ProgressBarManager {
  constructor() {
    if (ProgressBarManager.instance) {
      return ProgressBarManager.instance;
    }

    this.progressBar = null;
    this.isInitialized = false;
    ProgressBarManager.instance = this;
  }

  /**
   * Initialize the progress bar system
   * @param {Object} storageManager - Storage manager instance
   */
  initialize(storageManager = null) {
    if (this.isInitialized) {
      return this.progressBar;
    }

    this.progressBar = new FloatingProgressBar(storageManager);
    this.isInitialized = true;

    return this.progressBar;
  }

  /**
   * Get the progress bar instance
   * @returns {FloatingProgressBar|null} Progress bar instance
   */
  getProgressBar() {
    return this.progressBar;
  }

  /**
   * Update progress data
   * @param {Object} progressData - Progress information
   */
  updateProgress(progressData) {
    if (this.progressBar) {
      this.progressBar.updateProgress(progressData);
    }
  }

  /**
   * Show the progress bar
   */
  show() {
    if (this.progressBar) {
      this.progressBar.show();
    }
  }

  /**
   * Hide the progress bar
   */
  hide() {
    if (this.progressBar) {
      this.progressBar.hide();
    }
  }

  /**
   * Clean up resources
   */
  destroy() {
    if (this.progressBar) {
      this.progressBar.destroy();
      this.progressBar = null;
    }
    this.isInitialized = false;
    ProgressBarManager.instance = null;
  }
}

// Default export for convenience
export default FloatingProgressBar;
