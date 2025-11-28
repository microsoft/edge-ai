/**
 * Kata Completion Handler
 * Handles kata completion detection and evaluation triggers
 * Version: 2.0.0
 */

// Dependencies
import { errorHandler } from './error-handler.js';
import { defaultDebugHelper } from '../utils/debug-helper.js';

export class KataCompletionHandler {
  constructor(dependencies = {}) {
    this.debugHelper = dependencies.debugHelper || defaultDebugHelper;
    this.errorHandler = dependencies.errorHandler || errorHandler;
    this.storage = dependencies.storageManager || null;
    this.evaluationManager = dependencies.selfEvaluationManager || null;

    this.completionThreshold = 100; // Percentage for completion
    this.evaluationDelay = 1000; // Delay before showing evaluation prompt
  }

  /**
   * Check if kata is completed and trigger evaluation if needed
   * @param {Object} progressData - Current progress data
   * @param {Object} context - Learning context
   * @returns {boolean} Whether completion was triggered
   */
  checkCompletion(progressData, context) {
    return this.errorHandler.safeExecute(() => {
      if (!context || context.type !== 'kata') {
        return false;
      }

      const isCompleted = progressData.completionPercentage >= this.completionThreshold;
      const hasEvaluation = this.evaluationManager?.hasEvaluation(context.categoryId, context.kataId);

      this.debugHelper?.debug('Completion check:', {
        isCompleted,
        hasEvaluation,
        percentage: progressData.completionPercentage,
        context
      });

      if (isCompleted && !hasEvaluation) {
        // Show evaluation prompt after a delay to let progress update complete
        setTimeout(() => {
          this.showEvaluationPrompt(context);
        }, this.evaluationDelay);

        return true;
      }

      return false;
    }, 'checkCompletion', false);
  }

  /**
   * Show evaluation prompt for completed kata
   * @param {Object} context - Learning context
   * @returns {HTMLElement|null} Created notification element
   */
  showEvaluationPrompt(context) {
    return this.errorHandler.safeExecute(() => {
      // Remove any existing notification
      const existingNotification = document.querySelector('.kata-completion-notification');
      if (existingNotification && existingNotification.parentNode) {
        existingNotification.remove();
      }

      // Create notification element
      const notification = this.createNotificationElement(context);

      // Add notification styles if not present
      this.ensureNotificationStyles();

      // Add to DOM
      document.body.appendChild(notification);

      // Auto-remove after 30 seconds if no interaction
      setTimeout(() => {
        if (notification.parentNode) {
          notification.remove();
        }
      }, 30000);

      return notification;
    }, 'showEvaluationPrompt', null);
  }

  /**
   * Create the notification element for kata completion
   * @param {Object} context - Learning context
   * @returns {HTMLElement} Notification element
   */
  createNotificationElement(context) {
    const notification = document.createElement('div');
    notification.className = 'kata-completion-notification';

    const kataDisplayName = context.kataId.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase());

    notification.innerHTML = `
      <div class="notification-content">
        <h4>🎉 Kata Completed!</h4>
        <p>Great job completing <strong>${kataDisplayName}</strong>!</p>
        <p>Would you like to complete a quick self-evaluation to track your learning?</p>
        <div class="notification-actions">
          <button class="btn-primary" data-action="evaluate">
            Start Evaluation
          </button>
          <button class="btn-secondary" data-action="dismiss">
            Maybe Later
          </button>
        </div>
      </div>
    `;

    // Add event listeners
    const evaluateBtn = notification.querySelector('[data-action="evaluate"]');
    const dismissBtn = notification.querySelector('[data-action="dismiss"]');

    evaluateBtn?.addEventListener('click', () => {
      this.handleEvaluationStart(context);
      notification.remove();
    });

    dismissBtn?.addEventListener('click', () => {
      notification.remove();
    });

    // Apply inline styles
    notification.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
      color: white;
      padding: 20px;
      border-radius: 12px;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
      max-width: 350px;
      z-index: 1500;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      animation: slideInRight 0.3s ease-out;
    `;

    return notification;
  }

  /**
   * Handle evaluation start
   * @param {Object} context - Learning context
   */
  handleEvaluationStart(context) {
    this.errorHandler.safeExecute(() => {
      // Check if global evaluation function exists
      if (typeof window !== 'undefined' && typeof window.showKataEvaluation === 'function') {
        window.showKataEvaluation(context.categoryId, context.kataId);
      } else if (this.evaluationManager?.showEvaluation) {
        this.evaluationManager.showEvaluation(context.categoryId, context.kataId);
      } else {
        this.debugHelper?.error('No evaluation handler available');
      }
    }, 'handleEvaluationStart');
  }

  /**
   * Ensure notification styles are available
   */
  ensureNotificationStyles() {
    if (!document.querySelector('#kata-notification-styles')) {
      const styles = document.createElement('style');
      styles.id = 'kata-notification-styles';
      styles.textContent = `
        @keyframes slideInRight {
          from { transform: translateX(100%); opacity: 0; }
          to { transform: translateX(0); opacity: 1; }
        }

        .notification-content h4 {
          margin: 0 0 8px 0;
          font-size: 1.1rem;
          font-weight: 600;
        }

        .notification-content p {
          margin: 0 0 8px 0;
          font-size: 0.9rem;
          line-height: 1.4;
        }

        .notification-actions {
          display: flex;
          gap: 8px;
          margin-top: 12px;
        }

        .notification-actions .btn-primary {
          background: rgba(255, 255, 255, 0.2);
          color: white;
          border: 1px solid rgba(255, 255, 255, 0.3);
          padding: 8px 16px;
          border-radius: 6px;
          font-size: 0.85rem;
          cursor: pointer;
          transition: all 0.2s ease;
          font-weight: 500;
        }

        .notification-actions .btn-primary:hover {
          background: rgba(255, 255, 255, 0.3);
          border-color: rgba(255, 255, 255, 0.5);
        }

        .notification-actions .btn-secondary {
          background: transparent;
          color: rgba(255, 255, 255, 0.8);
          border: 1px solid rgba(255, 255, 255, 0.3);
          padding: 8px 16px;
          border-radius: 6px;
          font-size: 0.85rem;
          cursor: pointer;
          transition: all 0.2s ease;
        }

        .notification-actions .btn-secondary:hover {
          color: white;
          border-color: rgba(255, 255, 255, 0.5);
        }
      `;
      document.head.appendChild(styles);
    }
  }

  /**
   * Mark kata as completed manually
   * @param {Object} context - Learning context
   * @param {Object} progressData - Progress data to update
   * @returns {boolean} Success status
   */
  markCompleted(context, progressData = null) {
    return this.errorHandler.safeExecute(() => {
      const updatedProgress = progressData || {
        completionPercentage: 100,
        lastUpdated: Date.now(),
        completedTasks: progressData?.totalTasks || 1,
        totalTasks: progressData?.totalTasks || 1
      };

      updatedProgress.completionPercentage = 100;
      updatedProgress.lastUpdated = Date.now();

      // Save to storage
      if (this.storage) {
        const fullKataId = `${context.categoryId}/${context.kataId}`;
        this.storage.saveKataProgress(fullKataId, updatedProgress);
      }

      // Check for evaluation trigger
      this.checkCompletion(updatedProgress, context);

      return true;
    }, 'markCompleted', false);
  }

  /**
   * Check if kata has already been completed
   * @param {Object} context - Learning context
   * @returns {boolean} Whether kata is completed
   */
  isCompleted(context) {
    return this.errorHandler.safeExecute(() => {
      if (!this.storage || !context) {
        return false;
      }

      const fullKataId = `${context.categoryId}/${context.kataId}`;
      const progress = this.storage.getKataProgress(fullKataId);

      return progress && progress.completionPercentage >= this.completionThreshold;
    }, 'isCompleted', false);
  }

  /**
   * Get completion status and details
   * @param {Object} context - Learning context
   * @returns {Object|null} Completion details
   */
  getCompletionStatus(context) {
    return this.errorHandler.safeExecute(() => {
      if (!this.storage || !context) {
        return {
          isCompleted: false,
          completionPercentage: 0,
          hasEvaluation: false,
          completedDate: null,
          progress: null
        };
      }

      const fullKataId = `${context.categoryId}/${context.kataId}`;
      const progress = this.storage.getKataProgress(fullKataId);
      const hasEvaluation = this.evaluationManager?.hasEvaluation(context.categoryId, context.kataId);

      return {
        isCompleted: progress ? progress.completionPercentage >= this.completionThreshold : false,
        completionPercentage: progress?.completionPercentage || 0,
        hasEvaluation: hasEvaluation || false,
        completedDate: progress?.lastUpdated || null,
        progress: progress
      };
    }, 'getCompletionStatus', {
      isCompleted: false,
      completionPercentage: 0,
      hasEvaluation: false,
      completedDate: null,
      progress: null
    });
  }

  /**
   * Remove all completion notifications
   */
  clearNotifications() {
    return this.errorHandler.safeExecute(() => {
      const notifications = document.querySelectorAll('.kata-completion-notification');
      notifications.forEach(notification => {
        if (notification.parentNode) {
          notification.remove();
        }
      });
      return notifications.length; // Return count for testing
    }, 'clearNotifications', 0);
  }

  /**
   * Set completion threshold percentage
   * @param {number} threshold - Completion threshold (0-100)
   */
  setCompletionThreshold(threshold) {
    if (threshold >= 0 && threshold <= 100) {
      this.completionThreshold = threshold;
    }
  }

  /**
   * Set evaluation prompt delay
   * @param {number} delay - Delay in milliseconds
   */
  setEvaluationDelay(delay) {
    if (delay >= 0) {
      this.evaluationDelay = delay;
    }
  }

  /**
   * Cleanup handler
   */
  cleanup() {
    this.clearNotifications();
  }
}

// ES6 Export - single default export to avoid duplicates
export default KataCompletionHandler;
