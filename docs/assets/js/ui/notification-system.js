/**
 * UI Notification System
 *
 * @description Comprehensive notification system for displaying user messages,
 *              alerts, prompts, and UI feedback with queue management, accessibility
 *              support, and customizable styling for enhanced user experience.
 *
 * @module ui/notification-system
 * @version 2.1.0
 * @author Edge AI Team
 * @since 1.0.0
 *
 * @example
 * // Initialize notification system
 * const notifications = new NotificationSystem(debugHelper, errorHandler);
 *
 * @example
 * // Show different types of notifications
 * notifications.show('Success!', 'success');
 * notifications.show('Warning message', 'warning');
 * notifications.show('Error occurred', 'error');
 */

/**
 * Notification System for displaying user messages and feedback
 *
 * @description Manages notification display, queuing, and lifecycle with support
 *              for multiple notification types, auto-dismissal, user interaction,
 *              and accessibility features including ARIA live regions.
 *
 * @class NotificationSystem
 * @since 1.0.0
 */
export class NotificationSystem {
  /**
   * Create a NotificationSystem instance with optional service dependencies
   *
   * @param {Object} [debugHelper] - Debug helper service for logging and diagnostics
   * @param {Function} [debugHelper.debug] - Debug level logging function
   * @param {Function} [debugHelper.info] - Info level logging function
   * @param {Function} [debugHelper.warn] - Warning level logging function
   * @param {Function} [debugHelper.error] - Error level logging function
   * @param {Object} [errorHandler] - Error handling service for safe operations
   * @param {Function} [errorHandler.safeExecute] - Safe function execution wrapper
   * @param {Function} errorHandler.safeExecute.fn - Function to execute safely
   * @param {string} errorHandler.safeExecute.name - Operation name for error context
   * @param {*} errorHandler.safeExecute.fallback - Fallback value on error
   * @param {Object} [document] - Document instance for DOM operations (for testing)
   *
   * @example
   * // Create with custom dependencies
   * const notifications = new NotificationSystem(
   *   new DebugHelper(),
   *   new ErrorHandler()
   * );
   *
   * @example
   * // Create with minimal setup (uses defaults)
   * const notifications = new NotificationSystem();
   *
   * @since 1.0.0
   */
  constructor(debugHelper, errorHandler, document, timerService) {
    // Handle Happy DOM environment where window might not be fully available
    const globalHelpers = (typeof window !== 'undefined') ? window : {};

    /**
     * Debug helper instance for logging and diagnostics
     * @type {Object}
     * @private
     * @since 1.0.0
     */
    this.debugHelper = debugHelper || globalHelpers.KataProgressDebugHelper || {
      debug: () => {},
      info: () => {},
      warn: () => {},
      error: () => {}
    };

    // Create a default error handler instance if needed
    const getDefaultErrorHandler = () => {
      if (globalHelpers.KataProgressErrorHandlerInstance) {
        return globalHelpers.KataProgressErrorHandlerInstance;
      } else if (globalHelpers.KataProgressErrorHandler) {
        return new globalHelpers.KataProgressErrorHandler();
      } else {
        return {
          safeExecute: (fn, name, fallback) => {
            try {
              return fn();
            } catch {
              // Silent error handling for production
              return fallback;
            }
          }
        };
      }
    };

    /**
     * Error handler instance for safe operation execution
     * @type {Object}
     * @private
     * @since 1.0.0
     */
    this.errorHandler = errorHandler || getDefaultErrorHandler();

    /**
     * Document instance for DOM operations
     * @type {Object}
     * @private
     * @since 1.0.0
     */
    this.document = document || (typeof globalThis !== 'undefined' && globalThis.document) || (typeof window !== 'undefined' && window.document) || null;

    /**
     * Timer service for auto-dismiss functionality (injectable for testing)
     * @type {Object}
     * @private
     * @since 1.0.0
     */
    this.timerService = timerService || {
      setTimeout: (callback, delay) => setTimeout(callback, delay),
      clearTimeout: (id) => clearTimeout(id)
    };

    /**
     * Active notifications map for tracking displayed notifications
     * @type {Map<string, Object>}
     * @private
     * @since 1.0.0
     */
    this.notifications = new Map();

    /**
     * Notification queue for managing display order and limits
     * @type {Array<Object>}
     * @private
     * @since 1.0.0
     */
    this.notificationQueue = [];

    /**
     * Maximum number of simultaneous notifications
     * @type {number}
     * @private
     * @since 1.0.0
     */
    this.maxNotifications = 2; // Reduced from 3
    this.defaultDuration = 3000; // Reduced from 5000ms to 3000ms
    this.rateLimitMap = new Map(); // Add rate limiting
    this.rateLimitWindow = 5000; // 5 second window for rate limiting

    this.ensureStyles();
  }

  /**
   * Show a notification
   * @param {Object} options - Notification options
   * @returns {string|null} Notification ID
   */
  show(options = {}) {
    try {
      return this.errorHandler.safeExecute(() => {
        // Rate limiting - prevent duplicate notifications
        const messageKey = `${options.type || 'info'}-${options.message || ''}`;
        const now = Date.now();

        if (this.rateLimitMap.has(messageKey)) {
          const lastShown = this.rateLimitMap.get(messageKey);
          if (now - lastShown < this.rateLimitWindow) {
            return null; // Skip duplicate notification within rate limit window
          }
        }

        this.rateLimitMap.set(messageKey, now);

        const notification = {
          id: this.generateId(),
          type: options.type || 'info',
          title: options.title || '',
          message: options.message || '',
          duration: options.duration || this.defaultDuration,
          actions: options.actions || [],
          persistent: options.persistent || false,
          position: options.position || 'top-right',
          priority: options.priority || 'normal'
        };

        // Handle priority notifications
        if (notification.priority === 'high') {
          this.clearLowPriorityNotifications();
        }

        // Check if we need to queue
        if (this.notifications.size >= this.maxNotifications) {
          this.notificationQueue.push(notification);
          return notification.id;
        }

        // Always store the notification for state tracking
        this.notifications.set(notification.id, {
          ...notification,
          element: null,
          timestamp: Date.now()
        });

        // Set up auto-dismiss timer if needed (separated from DOM operations)
        if (!notification.persistent && notification.duration > 0) {
          this.scheduleAutoDismiss(notification.id, notification.duration);
        }

        // Display notification - handle failure case
        const success = this.displayNotification(notification);
        if (success === false) {
          // Remove from storage if display completely fails
          this.notifications.delete(notification.id);
          return null;
        }
        return notification.id;
      }, 'show', null);
    } catch {
      // Extra layer of protection - if error handler itself throws, handle gracefully
      return null;
    }
  }

  /**
   * Show success notification
   * @param {string} message - Success message
   * @param {Object} options - Additional options
   * @returns {string|null} Notification ID
   */
  success(message, options = {}) {
    return this.show({
      ...options,
      type: 'success',
      message,
      title: options.title || 'Success!'
    });
  }

  /**
   * Show error notification
   * @param {string} message - Error message
   * @param {Object} options - Additional options
   * @returns {string|null} Notification ID
   */
  error(message, options = {}) {
    return this.show({
      ...options,
      type: 'error',
      message,
      title: options.title || 'Error',
      duration: options.duration || 8000, // Longer for errors
      priority: 'high'
    });
  }

  /**
   * Show warning notification
   * @param {string} message - Warning message
   * @param {Object} options - Additional options
   * @returns {string|null} Notification ID
   */
  warning(message, options = {}) {
    return this.show({
      ...options,
      type: 'warning',
      message,
      title: options.title || 'Warning',
      duration: options.duration || 6000
    });
  }

  /**
   * Show info notification
   * @param {string} message - Info message
   * @param {Object} options - Additional options
   * @returns {string|null} Notification ID
   */
  info(message, options = {}) {
    return this.show({
      ...options,
      type: 'info',
      message,
      title: options.title || 'Info'
    });
  }

  /**
   * Schedule auto-dismiss for a notification (separated for testability)
   * @param {string} notificationId - ID of notification to dismiss
   * @param {number} duration - Delay in milliseconds
   * @private
   */
  scheduleAutoDismiss(notificationId, duration) {
    return this.errorHandler.safeExecute(() => {
      this.timerService.setTimeout(() => {
        this.dismiss(notificationId);
      }, duration);
    }, 'scheduleAutoDismiss', null);
  }

  /**
   * Show kata completion notification
   * @param {Object} context - Kata context
   * @returns {string|null} Notification ID
   */
  showKataCompletion(context) {
    return this.errorHandler.safeExecute(() => {
      if (!context || !context.kataId) {
        return this.show({
          type: 'error',
          title: 'Error',
          message: 'Invalid kata context provided',
          duration: 3000
        });
      }

      const kataDisplayName = context.kataId.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase());

      return this.show({
        type: 'completion',
        title: '🎉 Kata Completed!',
        message: `Great job completing ${kataDisplayName}!`,
        duration: 0, // Persistent until action
        persistent: true,
        priority: 'high',
        actions: [
          {
            label: 'Start Evaluation',
            type: 'primary',
            action: () => window.showKataEvaluation?.(context.categoryId, context.kataId)
          },
          {
            label: 'Maybe Later',
            type: 'secondary',
            action: (notificationId) => this.dismiss(notificationId)
          }
        ]
      });
    }, 'showKataCompletion', null);
  }

  /**
   * Display a notification element
   * @param {Object} notification - Notification data
   */
  displayNotification(notification) {
    return this.errorHandler.safeExecute(() => {
      // Check if DOM is available first
      if (!this.document) {
        return false;
      }

      const element = this.createNotificationElement(notification);
      if (!element) {
        return false;
      }

      // Add to DOM
      const container = this.getNotificationContainer(notification.position);
      if (!container) {
        return false;
      }

      container.appendChild(element);

      // Update stored reference with element
      const storedNotification = this.notifications.get(notification.id);
      if (storedNotification) {
        storedNotification.element = element;
      }

      // Add event listeners after element is in DOM
      this.addNotificationListeners(element, notification);

      // Trigger enter animation (auto-dismiss is now handled in show() method)
      const isTestEnvironment = (typeof process !== 'undefined' && process.env && process.env.NODE_ENV === 'test') ||
                               (typeof window !== 'undefined' && typeof window.happyDOM !== 'undefined');

      if (isTestEnvironment) {
        // Synchronous for tests
        element.classList.add('notification-enter');
      } else {
        // Async for real browsers
        requestAnimationFrame(() => {
          element.classList.add('notification-enter');
        });
      }

      return true;
    }, 'displayNotification', false);
  }

  /**
   * Create notification element
   * @param {Object} notification - Notification data
   * @returns {HTMLElement} Notification element
   */
  createNotificationElement(notification) {
    return this.errorHandler.safeExecute(() => {
      // Ensure DOM is available
      if (!this.document) {
        return null;
      }

      const element = this.document.createElement('div');
      element.className = `notification notification-${notification.type}`;
      element.setAttribute('data-notification-id', notification.id);

      const iconMap = {
        success: '✅',
        error: '❌',
        warning: '⚠️',
        info: 'ℹ️',
        completion: '🎉'
      };

      const icon = iconMap[notification.type] || 'ℹ️';

      element.innerHTML = `
        <div class="notification-icon">${icon}</div>
        <div class="notification-content">
          ${notification.title ? `<div class="notification-title">${notification.title}</div>` : ''}
          <div class="notification-message">${notification.message}</div>
          ${(notification.actions && notification.actions.length > 0) ? this.createActionsHTML(notification) : ''}
        </div>
        ${!notification.persistent ? '<button class="notification-close" aria-label="Close">×</button>' : ''}
      `;

      return element;
    }, 'createNotificationElement', null);
  }

  /**
   * Create actions HTML for notification
   * @param {Object} notification - Notification data
   * @returns {string} Actions HTML
   */
  createActionsHTML(notification) {
    if (!notification.actions.length) {return '';}

    const actionsHTML = notification.actions.map(action => {
      const buttonClass = `notification-action notification-action-${action.type || 'default'}`;
      return `<button class="${buttonClass}" data-action="${action.label}">${action.label}</button>`;
    }).join('');

    return `<div class="notification-actions">${actionsHTML}</div>`;
  }

  /**
   * Add event listeners to notification element
   * @param {HTMLElement} element - Notification element
   * @param {Object} notification - Notification data
   */
  addNotificationListeners(element, notification) {
    return this.errorHandler.safeExecute(() => {
      // Close button
      const closeBtn = element.querySelector('.notification-close');
      if (closeBtn) {
        closeBtn.addEventListener('click', () => this.dismiss(notification.id));
      }

      // Action buttons
      const actionBtns = element.querySelectorAll('.notification-action');
      actionBtns.forEach((btn, index) => {
        btn.addEventListener('click', () => {
          const action = notification.actions[index];
          if (action && action.action) {
            if (typeof action.action === 'function') {
              action.action(notification.id);
            }
          }
        });
      });

      // Hover listeners for non-persistent notifications
      if (!notification.persistent) {
        element.addEventListener('mouseenter', () => {
          // Pause auto-dismiss on hover
          if (element._dismissTimer) {
            clearTimeout(element._dismissTimer);
            element._dismissTimer = null;
          }
        });

        element.addEventListener('mouseleave', () => {
          // Resume auto-dismiss on mouse leave
          if (notification.duration > 0) {
            element._dismissTimer = setTimeout(() => {
              this.dismiss(notification.id);
            }, 1000); // Resume with shorter delay
          }
        });
      }
    }, 'addNotificationListeners');
  }

  /**
   * Get or create notification container
   * @param {string} position - Container position
   * @returns {HTMLElement} Container element
   */
  getNotificationContainer(position) {
    return this.errorHandler.safeExecute(() => {
      // Ensure DOM is available
      if (!this.document) {return null;}

      const containerId = `kata-notifications-${position}`;
      let container = this.document.getElementById(containerId);

      if (!container) {
        container = this.document.createElement('div');
        container.id = containerId;
        container.className = `notification-container notification-container-${position}`;
        this.document.body.appendChild(container);
      }

      return container;
    }, 'getNotificationContainer', null);
  }

  /**
   * Dismiss a notification
   * @param {string} notificationId - ID of notification to dismiss
   * @returns {boolean} Success status
   */
  dismiss(notificationId) {
    return this.errorHandler.safeExecute(() => {
      const notification = this.notifications.get(notificationId);
      if (!notification) {return false;}

      const element = notification.element;

      // Immediate cleanup for tests or Happy DOM environment
      const isTestEnvironment = (typeof process !== 'undefined' && process.env && process.env.NODE_ENV === 'test') ||
                               (typeof window !== 'undefined' && typeof window.happyDOM !== 'undefined');

      if (isTestEnvironment || !element) {
        // Immediate removal for tests or when element is not available
        if (element && element.parentNode) {
          element.parentNode.removeChild(element);
        }
        this.notifications.delete(notificationId);
        this.processQueue();
        return true;
      } else {
        // Trigger exit animation for real browser usage
        element.classList.add('notification-exit');

        // Remove after animation
        setTimeout(() => {
          if (element && element.parentNode) {
            element.parentNode.removeChild(element);
          }
          this.notifications.delete(notificationId);

          // Process queue
          this.processQueue();
        }, 300);
      }

      return true;
    }, 'dismiss', false);
  }

  /**
   * Hide a notification (alias for dismiss)
   * @param {string} notificationId - ID of notification to hide
   * @returns {boolean} Success status
   */
  hide(notificationId) {
    return this.dismiss(notificationId);
  }

  /**
   * Clear all notifications
   */
  clear() {
    return this.errorHandler.safeExecute(() => {
      this.notifications.forEach((notification, id) => {
        this.dismiss(id);
      });
      this.notificationQueue = [];

    }, 'clear');
  }

  /**
   * Clear all notifications (alias for clear)
   */
  clearAll() {
    return this.clear();
  }

  /**
   * Dismiss all notifications (alias for clear to match test expectations)
   */
  dismissAll() {
    return this.clear();
  }

  /**
   * Clear low priority notifications
   */
  clearLowPriorityNotifications() {
    return this.errorHandler.safeExecute(() => {
      // Only clear one low/normal priority notification to make room for high priority
      for (const [id, notification] of this.notifications) {
        if (notification.priority === 'low' || notification.priority === 'normal') {
          this.dismiss(id);
          break; // Only dismiss one to make room
        }
      }
    }, 'clearLowPriorityNotifications');
  }

  /**
   * Process notification queue
   */
  processQueue() {
    if (this.notificationQueue.length > 0 && this.notifications.size < this.maxNotifications) {
      const notification = this.notificationQueue.shift();

      // Store the notification first (same logic as show() method)
      this.notifications.set(notification.id, {
        ...notification,
        element: null,
        timestamp: Date.now()
      });

      // Schedule auto-dismiss if needed (same logic as show() method)
      if (!notification.persistent && notification.duration > 0) {
        this.scheduleAutoDismiss(notification.id, notification.duration);
      }

      // Then try to display it
      const success = this.displayNotification(notification);
      if (success === false) {
        // Remove from storage if display fails
        this.notifications.delete(notification.id);
      }
    }
  }

  /**
   * Set maximum number of notifications
   * @param {number} max - Maximum number of notifications
   */
  setMaxNotifications(max) {
    if (typeof max !== 'number' || max < 1) {
      return; // Invalid value, don't change
    }

    this.maxNotifications = max;

    // Dismiss excess notifications if current count exceeds new limit
    if (this.notifications.size > max) {
      const notificationsArray = Array.from(this.notifications.keys());
      const excessNotifications = notificationsArray.slice(max);
      excessNotifications.forEach(id => this.dismiss(id));
    }
  }

  /**
   * Get active notifications
   * @returns {Array} Array of active notifications
   */
  getActiveNotifications() {
    return Array.from(this.notifications.values()).map(notification => ({
      id: notification.id,
      type: notification.type,
      title: notification.title,
      message: notification.message,
      timestamp: notification.timestamp
    }));
  }

  /**
   * Get queue length
   * @returns {number} Number of queued notifications
   */
  getQueueLength() {
    return this.notificationQueue.length;
  }

  /**
   * Generate unique notification ID
   * @returns {string} Unique ID
   */
  generateId() {
    // Use a simple counter-based approach to match test expectations
    if (!this._idCounter) {
      this._idCounter = 1;
    }
    const id = `notification-${this._idCounter}`;
    this._idCounter++;
    return id;
  }

  /**
   * Ensure notification styles are loaded
   * Styles are now included via CSS import in main.css
   */
  ensureStyles() {
    return this.errorHandler.safeExecute(() => {
      // Check if styles are already injected
      if (!this.document) {
        // In test environment without document, just mark styles as ensured
        this._stylesEnsured = true;
        return;
      }

      const existingStyles = this.document.querySelector('style[data-notification-styles]') ||
                            (this.document.head && this.document.head.querySelector('style[data-notification-styles]'));
      if (existingStyles) {
        this._stylesEnsured = true;
        return;
      }

      // Styles are now loaded via external CSS files
      // Check if CSS is already loaded or load it dynamically
      this.loadNotificationStylesIfNeeded();

      this._stylesEnsured = true;
    }, 'ensureStyles');
  }

  /**
   * Load notification styles if not already loaded
   */
  loadNotificationStylesIfNeeded() {
    return this.errorHandler.safeExecute(() => {
      // Load all required CSS files for notifications
      const cssFiles = [
        '/assets/css/components/notifications.css',
        '/assets/css/components/single-action-interface.css'
      ];

      cssFiles.forEach(href => {
        const existingLink = this.document.querySelector(`link[href*="${href.split('/').pop()}"]`);
        if (!existingLink) {
          const link = this.document.createElement('link');
          link.rel = 'stylesheet';
          link.href = href;

          if (this.document.head) {
            this.document.head.appendChild(link);
          }
        }
      });
    }, 'loadNotificationStylesIfNeeded');
  }

  /**
   * Cleanup notification system
   */
  cleanup() {
    this.clear();

    // Remove containers
    const containers = this.document.querySelectorAll('[id^="notification-container-"]');
    containers.forEach(container => container.remove());

  }
}

// Export default instance for convenience
export const defaultNotificationSystem = new NotificationSystem();

// Export convenience functions
export const showNotification = (...args) => defaultNotificationSystem.show(...args);
export const hideNotification = (...args) => defaultNotificationSystem.hide(...args);
export const clearAllNotifications = (...args) => defaultNotificationSystem.clearAll(...args);
