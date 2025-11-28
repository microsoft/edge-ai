/**
 * Events Mixin
 * Provides accessibility event handling and screen reader announcements
 *
 * @module events
 * @author Edge AI Team
 * @version 1.0.0
 */

/**
 * Events mixin for managing accessibility announcements and ARIA live regions
 * @type {Object}
 */
export const eventsMixin = {
  /**
   * Initialize ARIA live region for screen reader announcements
   * @private
   */
  _initializeAriaLiveRegion() {
    if (!this.containers || this.containers.length === 0) {
      return;
    }

    this.containers.forEach(container => {
      let ariaLive = container.querySelector('.learning-dashboard-aria-live');

      if (!ariaLive) {
        ariaLive = document.createElement('div');
        ariaLive.className = 'sr-only learning-dashboard-aria-live';
        ariaLive.setAttribute('role', 'status');
        ariaLive.setAttribute('aria-live', 'polite');
        ariaLive.setAttribute('aria-atomic', 'true');
        ariaLive.style.position = 'absolute';
        ariaLive.style.left = '-10000px';
        ariaLive.style.width = '1px';
        ariaLive.style.height = '1px';
        ariaLive.style.overflow = 'hidden';
        container.appendChild(ariaLive);
      }
    });
  },

  /**
   * Announce status message to screen readers
   * @param {string} message - Message to announce
   * @param {string} priority - Priority level ('polite' or 'assertive')
   */
  announceStatus(message, priority = 'polite') {
    if (!message || typeof message !== 'string') {
      return;
    }

    if (!this.containers || this.containers.length === 0) {
      return;
    }

    this.containers.forEach(container => {
      // Find live region - prioritize test containers with aria-label, then dashboard's own region
      const ariaLive = container.querySelector('[aria-live][aria-label]') ||
                       container.querySelector('.learning-dashboard-aria-live') ||
                       container.querySelector('[aria-live="polite"]');

      if (ariaLive) {
        ariaLive.setAttribute('aria-live', priority);
        ariaLive.textContent = message;

        // Dispatch custom event for test compatibility
        const event = new CustomEvent('ariaAnnouncement', {
          detail: { message, priority },
          bubbles: true
        });
        container.dispatchEvent(event);

        // Clear message after announcement to allow repeated announcements
        setTimeout(() => {
          ariaLive.textContent = '';
        }, 2000);
      }
    });

    // Log announcement for debugging
    if (this.log) {
      this.log('debug', `Announced: ${message}`);
    }
  },

  /**
   * Announce progress update for a specific path
   * @param {string} pathId - Path identifier
   */
  announceProgressUpdate(pathId) {
    if (!pathId || !this.calculateProgress || !this.loadedPaths) {
      return;
    }

    const progress = this.calculateProgress(pathId);
    const path = this.loadedPaths.find(p => p.id === pathId);
    const pathTitle = path ? path.title : 'Unknown Path';

    const message = `Progress updated for ${pathTitle}. ${progress.completed} of ${progress.total} completed.`;
    this.announceStatus(message, 'polite');
  },

  /**
   * Announce error message to screen readers with assertive priority
   * @param {string} message - Error message to announce
   */
  announceError(message) {
    if (!message) {
      return;
    }

    this.announceStatus(`Error: ${message}`, 'assertive');
  },

  /**
   * Announce success message to screen readers
   * @param {string} message - Success message to announce
   */
  announceSuccess(message) {
    if (!message) {
      return;
    }

    this.announceStatus(message, 'polite');
  },

  /**
   * Set up form validation for search and filter forms
   * No-op placeholder for future implementation
   * @private
   */
  setupFormValidation() {
    // Placeholder for future form validation implementation
    // Currently no forms require validation
  },

  /**
   * Cleanup aria-live regions during destroy
   * @private
   */
  _cleanupAriaLiveRegion() {
    if (!this.containers) {
      return;
    }

    this.containers.forEach(container => {
      const ariaLive = container.querySelector('.learning-dashboard-aria-live');
      if (ariaLive) {
        ariaLive.remove();
      }
    });
  }
};
