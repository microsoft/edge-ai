/**
 * Dark Mode Toggle Implementation
 * Provides dark/light theme switching functionality with accessibility support
 * Version: 3.0.0
 */

(function() {
  'use strict';

  /**
   * Dark Mode Manager Class
   * Handles theme state management and persistence
   */
  class DarkModeManager {
    /**
     * Initialize dark mode manager
     */
    constructor() {
      this.isDark = false;
      this.button = null;
      this.storageKey = 'docsify-dark-mode';
      this.themes = {
        light: { icon: '🌙', label: 'Switch to dark mode' },
        dark: { icon: '☀️', label: 'Switch to light mode' }
      };
    }

    /**
     * Initialize the dark mode toggle
     * @returns {boolean} Success status
     */
    initialize() {
      try {
        this.loadSavedTheme();
        this.createToggleButton();
        this.applyTheme();
        this.setupEventListeners();
        return true;
      } catch (error) {
        // eslint-disable-next-line no-console
        console.warn('Dark mode initialization failed:', error);
        return false;
      }
    }

    /**
     * Load theme preference from localStorage
     * @private
     */
    loadSavedTheme() {
      try {
        const savedTheme = localStorage.getItem(this.storageKey);
        this.isDark = savedTheme === 'dark';
      } catch (error) {
        // eslint-disable-next-line no-console
        console.warn('Failed to load theme from localStorage:', error);
        this.isDark = false; // Default to light mode
      }
    }

    /**
     * Save theme preference to localStorage
     * @private
     */
    saveTheme() {
      try {
        const theme = this.isDark ? 'dark' : 'light';
        localStorage.setItem(this.storageKey, theme);
      } catch (error) {
        // eslint-disable-next-line no-console
        console.warn('Failed to save theme to localStorage:', error);
      }
    }

    /**
     * Create the dark mode toggle button with accessibility features
     * @private
     */
    createToggleButton() {
      this.button = document.createElement('button');
      this.button.className = 'dark-mode-toggle';
      this.button.type = 'button';

      // Set accessibility attributes
      this.button.setAttribute('aria-live', 'polite');
      this.button.setAttribute('role', 'switch');
      this.button.setAttribute('tabindex', '0');

      // Add to DOM
      document.body.appendChild(this.button);

      // Request layout coordination after button is created
      this.requestLayoutCoordination();
    }

    /**
     * Apply current theme to document and update button
     * @private
     */
    applyTheme() {
      if (!this.button) {return;}

      const currentTheme = this.isDark ? this.themes.dark : this.themes.light;

      // Update document theme
      if (this.isDark) {
        document.body.classList.add('dark');
        document.body.setAttribute('data-theme', 'dark');
      } else {
        document.body.classList.remove('dark');
        document.body.setAttribute('data-theme', 'light');
      }

      // Update button content and accessibility
      this.button.innerHTML = currentTheme.icon;
      this.button.setAttribute('aria-label', currentTheme.label);
      this.button.setAttribute('aria-checked', this.isDark.toString());
      this.button.title = currentTheme.label;

      // Request LayoutCoordinator to position the toggle if available
      this.requestLayoutCoordination();
    }

    /**
     * Request LayoutCoordinator to handle toggle positioning
     * @private
     */
    requestLayoutCoordination() {
      // Wait for LayoutCoordinator to be available and coordinate toggle positioning
      const checkForLayoutCoordinator = () => {
        if (window.LayoutCoordinator && typeof window.LayoutCoordinator.coordinateDarkModeElement === 'function') {
          try {
            // Find the header right section to coordinate toggle positioning
            const headerRight = document.querySelector('.header-row .header-right, .app-nav');
            if (headerRight) {
              window.LayoutCoordinator.coordinateDarkModeElement(headerRight);
            }
          } catch (_error) {
            // LayoutCoordinator integration failed - continue without it
          }
        } else {
          // If LayoutCoordinator isn't ready yet, check again in a moment
          setTimeout(checkForLayoutCoordinator, 100);
        }
      };

      checkForLayoutCoordinator();
    }

    /**
     * Toggle between dark and light themes
     * @private
     */
    toggleTheme() {
      this.isDark = !this.isDark;
      this.applyTheme();
      this.saveTheme();

      // Announce theme change to screen readers
      const announcement = `Theme switched to ${this.isDark ? 'dark' : 'light'} mode`;
      this.announceToScreenReader(announcement);
    }

    /**
     * Announce message to screen readers
     * @param {string} message - Message to announce
     * @private
     */
    announceToScreenReader(message) {
      const announcement = document.createElement('div');
      announcement.setAttribute('aria-live', 'assertive');
      announcement.setAttribute('aria-atomic', 'true');
      announcement.className = 'sr-only';
      announcement.textContent = message;

      document.body.appendChild(announcement);

      // Remove after announcement
      setTimeout(() => {
        if (announcement.parentNode) {
          announcement.parentNode.removeChild(announcement);
        }
      }, 1000);
    }

    /**
     * Set up event listeners for the toggle button
     * @private
     */
    setupEventListeners() {
      if (!this.button) {return;}

      // Click handler
      this.button.addEventListener('click', () => {
        this.toggleTheme();
      });

      // Keyboard accessibility
      this.button.addEventListener('keydown', (event) => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          this.toggleTheme();
        }
      });

      // Hover effects (non-touch devices)
      if (!('ontouchstart' in window)) {
        this.button.addEventListener('mouseenter', () => {
          this.button.style.transform = 'scale(1.1)';
        });

        this.button.addEventListener('mouseleave', () => {
          this.button.style.transform = 'scale(1)';
        });
      }
    }

    /**
     * Clean up resources and event listeners
     */
    destroy() {
      if (this.button && this.button.parentNode) {
        this.button.parentNode.removeChild(this.button);
        this.button = null;
      }
    }

    /**
     * Get current theme state
     * @returns {string} Current theme ('dark' or 'light')
     */
    getCurrentTheme() {
      return this.isDark ? 'dark' : 'light';
    }

    /**
     * Set theme programmatically
     * @param {string} theme - Theme to set ('dark' or 'light')
     * @returns {boolean} Success status
     */
    setTheme(theme) {
      if (theme !== 'dark' && theme !== 'light') {
        // eslint-disable-next-line no-console
        console.warn('Invalid theme specified:', theme);
        return false;
      }

      this.isDark = theme === 'dark';
      this.applyTheme();
      this.saveTheme();
      return true;
    }
  }

  /**
   * Initialize dark mode functionality
   * @returns {DarkModeManager|null} Dark mode manager instance or null if failed
   */
  function initializeDarkMode() {
    try {
      const darkModeManager = new DarkModeManager();
      const success = darkModeManager.initialize();

      if (success) {
        // Expose manager globally for external access
        window.darkModeManager = darkModeManager;
        return darkModeManager;
      } else {
        return null;
      }
    } catch {
      return null;
    }
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeDarkMode);
  } else {
    initializeDarkMode();
  }

  // Export for testing (when module system is available)
  if (typeof window !== 'undefined') {
    window.DarkModeManager = DarkModeManager;
  }
})();
