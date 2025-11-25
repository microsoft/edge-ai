/**
 * @fileoverview Sidebar Chevrons Simple Module - ES6 Module for managing collapsible sidebar folder navigation
 *
 * @description
 * This module provides functionality for:
 * - Managing collapsible sidebar folders with chevron icons
 * - Tracking folder expansion states with localStorage persistence
 * - Automatic and manual folder expansion modes
 * - Event-driven folder state management
 * - Integration with active highlighting system
 *
 * Features:
 * - Click-to-toggle folder expansion/collapse
 * - Persistent folder states across sessions
 * - Automatic expansion marking for cleanup
 * - Chevron rotation animations
 * - ARIA accessibility attributes
 * - Event emission for state changes
 *
 * @author Edge AI Team
 * @since 2025-08-01
 * @version 2.0.0
 */

import { ErrorHandler } from '../core/error-handler.js';
import { DOMUtils } from '../utils/dom-utils.js';
import { logger } from '../utils/index.js';

/**
 * Sidebar Chevrons class for managing collapsible folder navigation
 */
export class SidebarChevrons {
  /**
   * Constructor for SidebarChevrons
   * @param {Object} dependencies - Dependencies object
   * @param {ErrorHandler} dependencies.errorHandler - Error handler instance
   * @param {DOMUtils} dependencies.domUtils - DOM utilities instance
   * @param {Object} dependencies.debugHelper - Debug helper (optional)
   * @param {boolean} dependencies.debug - Debug mode flag (optional)
   */
  constructor({ errorHandler, domUtils, debugHelper, debug = false, storageKey = 'sidebar-expanded-folders' } = {}) {
    this.errorHandler = errorHandler === null ? null : (errorHandler || new ErrorHandler('sidebar-chevrons'));
    this.domUtils = domUtils || new DOMUtils();
    this.debugHelper = debugHelper || console;
    this.debug = debug;

    this.isInitialized = false;
    this.expandedFolders = new Set();
    this.abortController = null;
    this.isReinitializing = false; // Flag to prevent infinite reinitialize loops

    // Configuration properties for test compatibility
    this.storageKey = storageKey;
    this.config = {
      storageKey: storageKey,
      debug: debug,
      chevronClass: 'chevron',
      expandedClass: 'expanded',
      collapsedClass: 'collapsed'
    };

    // Additional test-expected properties
    this.dependencies = { errorHandler, domUtils, debugHelper };
    this.boundHandlers = new Map();
    this.automaticExpansions = new Set();
    this.chevronStyles = {
      display: 'inline-block',
      marginRight: '6px',
      transition: 'transform 0.3s ease',
      cursor: 'pointer'
    };
  }

  /**
   * Get a unique key for a folder element
   * @param {HTMLElement} folderElement - The folder li element
   * @returns {string} Unique folder key
   */
  getFolderKey(folderElement) {
    if (!folderElement) {
      return 'unknown-folder';
    }

    // Look for direct child link or any link within the folder
    const folderLink = folderElement.querySelector('a');
    if (folderLink) {
      const href = folderLink.getAttribute('href');
      if (href) {
        return href; // Return full href as expected by tests
      }
      const textContent = folderLink.textContent?.trim();
      if (textContent) {
        return textContent;
      }
    }

    return 'unknown-folder';
  }

  /**
   * Load expanded state from localStorage
   * @private
   */
  loadExpandedStates() {
    try {
      const saved = localStorage.getItem(this.storageKey);
      if (saved) {
        const savedStates = JSON.parse(saved);
        if (Array.isArray(savedStates)) {
          savedStates.forEach(folderKey => {
            this.expandedFolders.add(folderKey);
          });
        }
        return true;
      }
      return false;
    } catch (_error) {
      this.handleError('Failed to load expanded states', _error);
      return false;
    }
  }

  /**
   * Save expanded state to localStorage
   * @private
   */
  saveExpandedStates() {
    try {
      const expandedArray = Array.from(this.expandedFolders);
      localStorage.setItem(this.storageKey, JSON.stringify(expandedArray));
      return true;
    } catch (_error) {
      this.handleError('Failed to save expanded states', _error);
      return false;
    }
  }

  /**
   * Initialize chevrons for all sidebar folders
   */
  initializeChevrons() {
    const sidebar = document.querySelector('.sidebar');
    if (!sidebar) {
      logger.warn('SidebarChevrons: No .sidebar element found');
      return;
    }

    // Set flag to indicate we're modifying the DOM during initialization
    this.isReinitializing = true;

    // Find all folders (li elements that contain nested ul elements)
    const folders = sidebar.querySelectorAll('li');
    // Track folder count (unused in current implementation)
    // let _folderCount = 0;

    // console.log(`SidebarChevrons: Found ${folders.length} li elements to check`);

    folders.forEach((folder, _index) => {
      const nestedUl = folder.querySelector('ul');
      if (nestedUl) {
        // console.log(`SidebarChevrons: Initializing folder ${index + 1} with nested ul`);
        this.initializeFolder(folder);
        // _folderCount++;
      }
    });

    // console.log(`SidebarChevrons: Initialized ${folderCount} folders with chevrons`);

    // Clear the flag after a short delay to allow DOM to settle
    setTimeout(() => {
      this.isReinitializing = false;
    }, 100);
  }

  /**
   * Initialize a single folder with chevron functionality
   * @param {HTMLElement} folder - The folder li element
   */
  initializeFolder(folder) {
    // Look for direct child link or any link within the folder
    const folderLink = folder.querySelector('a');
    const nestedUl = folder.querySelector('ul');

    if (!folderLink || !nestedUl) {
      // console.log('SidebarChevrons: Skipping folder - missing link or nested ul');
      return;
    }

    const _folderText = folderLink.textContent?.trim();
    // console.log(`SidebarChevrons: Setting up folder "${folderText}"`);

    // Create chevron element if it doesn't exist
    let chevron = folderLink.querySelector(`.${this.config.chevronClass}`);
    if (!chevron) {
      chevron = document.createElement('span');
      chevron.className = this.config.chevronClass;
      chevron.innerHTML = '▶';
      chevron.setAttribute('aria-label', 'Toggle folder');
      chevron.style.cssText = `
        display: inline-block;
        margin-right: 8px;
        margin-left: 2px;
        cursor: pointer;
        font-size: 14px;
        color: var(--sidebar-nav-link-color, #42b883);
        opacity: 0.8;
        line-height: 1;
        vertical-align: middle;
        transition: all 0.3s ease;
        font-family: monospace;
        font-weight: bold;
        user-select: none;
      `;
      folderLink.insertBefore(chevron, folderLink.firstChild);
      // console.log(`SidebarChevrons: Added chevron to "${folderText}"`);
    }

    // Set initial state based on saved preferences
    const folderKey = this.getFolderKey(folder);
    const isExpanded = this.expandedFolders.has(folderKey);

    this.setFolderState(folder, isExpanded);

    // Add click listener and hover effects
    const clickHandler = (event) => {
      // Check if click was specifically on the chevron
      const isChevronClick = event.target.classList.contains(this.config.chevronClass);

      if (isChevronClick) {
        // Chevron click: only toggle, prevent navigation
        event.preventDefault();
        event.stopPropagation();
        this.toggleFolder(folder);
      } else {
        // Link text click: toggle folder AND allow browser navigation
        this.toggleFolder(folder);
      }
    };    // Add hover effects for better UX
    const mouseEnterHandler = () => {
      if (chevron) {
        chevron.style.opacity = '1';
        chevron.style.transform = 'scale(1.1)';
      }
    };

    const mouseLeaveHandler = () => {
      if (chevron) {
        const isExpanded = this.expandedFolders.has(this.getFolderKey(folder));
        chevron.style.opacity = isExpanded ? '1' : '0.7';
        chevron.style.transform = 'scale(1)';
      }
    };

    if (this.abortController && this.abortController.signal) {
      try {
        folderLink.addEventListener('click', clickHandler, { signal: this.abortController.signal });
        folderLink.addEventListener('mouseenter', mouseEnterHandler, { signal: this.abortController.signal });
        folderLink.addEventListener('mouseleave', mouseLeaveHandler, { signal: this.abortController.signal });
      } catch {
        // Fallback for environments without AbortController support
        folderLink.addEventListener('click', clickHandler);
        folderLink.addEventListener('mouseenter', mouseEnterHandler);
        folderLink.addEventListener('mouseleave', mouseLeaveHandler);
      }
    } else {
      folderLink.addEventListener('click', clickHandler);
      folderLink.addEventListener('mouseenter', mouseEnterHandler);
      folderLink.addEventListener('mouseleave', mouseLeaveHandler);
    }

    // console.log(`SidebarChevrons: Folder "${folderText}" setup complete`);
  }

  /**
   * Set the visual state of a folder
   * @param {HTMLElement} folder - The folder li element
   * @param {boolean} isExpanded - Whether the folder should be expanded
   */
  setFolderState(folder, isExpanded) {
    if (!folder) {
      return;
    }

    const chevron = folder.querySelector(`.${this.config.chevronClass}`);
    const nestedUl = folder.querySelector('ul');
    const _folderName = this.extractFolderName(folder);

    // console.log(`SidebarChevrons: Setting folder "${folderName}" state to ${isExpanded ? 'expanded' : 'collapsed'}`);

    if (isExpanded) {
      folder.classList.add(this.config.expandedClass);
      folder.classList.remove(this.config.collapsedClass);
      if (chevron) {
        chevron.classList.add(this.config.expandedClass);
        chevron.classList.remove(this.config.collapsedClass);
        chevron.innerHTML = '▼'; // Down arrow for expanded
        chevron.setAttribute('aria-expanded', 'true');
        chevron.style.color = 'var(--sidebar-nav-link-color, #42b883)';
        chevron.style.opacity = '1';
        // Remove any conflicting transforms
        chevron.style.transform = '';
      }
      if (nestedUl) {
        nestedUl.style.display = 'block';
        nestedUl.style.opacity = '1';
        nestedUl.style.maxHeight = 'none';
      }
    } else {
      folder.classList.add(this.config.collapsedClass);
      folder.classList.remove(this.config.expandedClass);
      if (chevron) {
        chevron.classList.add(this.config.collapsedClass);
        chevron.classList.remove(this.config.expandedClass);
        chevron.innerHTML = '▶'; // Right arrow for collapsed
        chevron.setAttribute('aria-expanded', 'false');
        chevron.style.color = 'var(--sidebar-nav-link-color-hover, #369870)';
        chevron.style.opacity = '0.7';
        // Remove any conflicting transforms
        chevron.style.transform = '';
      }
      if (nestedUl) {
        nestedUl.style.display = 'none';
        nestedUl.style.opacity = '0';
        nestedUl.style.maxHeight = '0';
      }
    }
  }

  /**
   * Toggle a folder's expanded/collapsed state
   * @param {HTMLElement} folder - The folder li element
   */
  toggleFolder(folder) {
    const folderKey = this.getFolderKey(folder);
    const isCurrentlyExpanded = this.expandedFolders.has(folderKey);
    const newState = !isCurrentlyExpanded;
    const folderName = this.extractFolderName(folder);

    // console.log(`SidebarChevrons: Toggling "${folderName}" from ${isCurrentlyExpanded ? 'expanded' : 'collapsed'} to ${newState ? 'expanded' : 'collapsed'}`);

    // Accordion behavior: collapse other top-level folders when expanding one
    if (newState && this.isTopLevelFolder(folder)) {
      this.collapseOtherTopLevelFolders(folder);
    }

    this.setFolderState(folder, newState);

    if (newState) {
      this.expandedFolders.add(folderKey);
      // console.log(`SidebarChevrons: Added "${folderKey}" to expanded folders`);
    } else {
      this.expandedFolders.delete(folderKey);
      // console.log(`SidebarChevrons: Removed "${folderKey}" from expanded folders`);
    }

    this.saveExpandedStates();
    // console.log(`SidebarChevrons: Saved expanded states: [${Array.from(this.expandedFolders).join(', ')}]`);

    // Emit event for other components
    window.dispatchEvent(new CustomEvent('sidebar:folder-toggled', {
      detail: { folder, isExpanded: newState, folderKey, folderName }
    }));
  }

  /**
   * Expand a folder (used by active highlighting system)
   * @param {HTMLElement} folder - The folder li element
   * @param {boolean} isAutomatic - Whether this is an automatic expansion
   */
  expandFolder(folder, isAutomatic = false) {
    const folderKey = this.getFolderKey(folder);
    const folderName = this.extractFolderName(folder);

    this.setFolderState(folder, true);

    if (isAutomatic) {
      // Mark as automatically expanded for cleanup purposes
      folder.setAttribute('data-auto-expanded', 'true');
      // Don't save automatic expansions to localStorage
    } else {
      // Manual expansion - save to persistent state
      this.expandedFolders.add(folderKey);
      this.saveExpandedStates();
    }

    // Emit event
    window.dispatchEvent(new CustomEvent('sidebar:folder-expanded', {
      detail: { folder, isAutomatic, folderKey, folderName }
    }));
  }

  /**
   * Collapse a folder
   * @param {HTMLElement} folder - The folder li element
   */
  collapseFolder(folder) {
    const folderKey = this.getFolderKey(folder);
    const folderName = this.extractFolderName(folder);

    this.setFolderState(folder, false);

    // Remove from persistent state
    this.expandedFolders.delete(folderKey);
    this.saveExpandedStates();

    // Remove auto-expansion marker
    folder.removeAttribute('data-auto-expanded');

    // Emit event
    window.dispatchEvent(new CustomEvent('sidebar:folder-collapsed', {
      detail: { folder, folderKey, folderName }
    }));
  }

  /**
   * Initialize the sidebar chevrons system
   */
  initialize() {
    if (this.isInitialized || this.isReinitializing) {
      return;
    }

    this.abortController = new AbortController();
    this.loadExpandedStates();
    this.initializeChevrons();

    this.isInitialized = true;
  }

  /**
   * Destroy the chevrons instance and clean up resources
   */
  destroy() {
    // console.log('SidebarChevrons: Destroying instance and cleaning up');

    if (this.abortController) {
      this.abortController.abort();
      this.abortController = null;
    }

    // Remove all chevron elements we added
    const chevrons = document.querySelectorAll(`.${this.config.chevronClass}`);
    chevrons.forEach(chevron => {
      if (chevron && chevron.parentNode) {
        chevron.remove();
      }
    });

    // Reset folder states
    const folders = document.querySelectorAll(`.${this.config.expandedClass}, .${this.config.collapsedClass}`);
    folders.forEach(folder => {
      folder.classList.remove(this.config.expandedClass, this.config.collapsedClass);
      const nestedUl = folder.querySelector('ul');
      if (nestedUl) {
        nestedUl.style.display = '';
        nestedUl.style.opacity = '';
        nestedUl.style.maxHeight = '';
      }
    });

    this.expandedFolders.clear();
    this.isInitialized = false;
    this.isReinitializing = false;

    // console.log('SidebarChevrons: Cleanup complete');
  }

  /**
   * Load expanded state (alias for loadExpandedStates for test compatibility)
   */
  loadExpandedState() {
    return this.loadExpandedStates();
  }

  /**
   * Save expanded state (alias for saveExpandedStates for test compatibility)
   */
  saveExpandedState() {
    return this.saveExpandedStates();
  }

  /**
   * Extract clean folder name without chevron symbols
   * @param {HTMLElement} folder - The folder li element
   * @returns {string} Clean folder name
   */
  extractFolderName(folder) {
    const folderLink = folder.querySelector('a');
    if (!folderLink) {
      return 'Unknown folder';
    }

    const rawText = folderLink.textContent?.trim() || 'Unknown folder';
    // Remove chevron symbols (▶ and ▼) from the beginning of the text
    return rawText.replace(/^[▶▼]\s*/, '');
  }

  /**
   * Extract folder key from URL or folder element
   * @param {string|HTMLElement} input - URL string or folder element
   * @returns {string} Folder key
   */
  extractFolderKey(input) {
    if (typeof input === 'string') {
      // Handle URL strings
      try {
        const url = new URL(input, window.location.origin);
        const pathParts = url.hash ? url.hash.slice(1).split('/') : url.pathname.split('/');
        const folderParts = pathParts.filter(part => part.length > 0);
        return folderParts.length > 0 ? folderParts[folderParts.length - 1].replace(/\.[^/.]+$/, '') : '';
      } catch {
        // Handle malformed URLs gracefully - fallback to simple extraction
        const cleanUrl = input.split('?')[0].split('#')[0];
        const pathParts = cleanUrl.split('/');
        const lastPart = pathParts[pathParts.length - 1];
        return lastPart.replace(/\.[^/.]+$/, '');
      }
    } else if (input && input.nodeType === Node.ELEMENT_NODE) {
      // Handle HTML elements
      return this.getFolderKey(input);
    }
    return '';
  }

  /**
   * Update folder UI states for expanded folders
   * @param {Set|Array|HTMLElement|null} expandedFolders - Set/Array of expanded folder keys, HTMLElement, or null
   * @param {boolean} isExpanded - Optional: explicit expanded state for single folder update
   */
  updateFolderUI(expandedFolders = this.expandedFolders, isExpanded = null) {
    // Handle null case gracefully
    if (!expandedFolders) {
      return;
    }

    // Handle single folder element case
    if (expandedFolders instanceof HTMLElement) {
      const folder = expandedFolders;
      const actualIsExpanded = isExpanded !== null ? isExpanded : this.expandedFolders.has(this.getFolderKey(folder));

      const chevron = folder.querySelector('.folder-chevron');
      if (chevron) {
        chevron.textContent = actualIsExpanded ? '▼' : '▶';
      }

      if (actualIsExpanded) {
        folder.classList.add(this.config.expandedClass);
        folder.classList.remove(this.config.collapsedClass);
      } else {
        folder.classList.add(this.config.collapsedClass);
        folder.classList.remove(this.config.expandedClass);
      }

      // Update visibility of subfolder content
      const subfolders = folder.querySelector('.subfolder-content') || folder.querySelector('ul');
      if (subfolders) {
        subfolders.style.display = actualIsExpanded ? 'block' : 'none';
      }
      return;
    }

    // Convert to iterable if needed
    const foldersToUpdate = Array.isArray(expandedFolders) ? expandedFolders :
                           expandedFolders instanceof Set ? Array.from(expandedFolders) :
                           [expandedFolders];

    // Update UI for all folders based on their expanded state
    foldersToUpdate.forEach(folderKey => {
      const folder = document.querySelector(`[data-folder-key="${folderKey}"]`);
      if (folder) {
        const chevron = folder.querySelector('.folder-chevron');
        const subfolders = folder.querySelector('.subfolder-content') || folder.querySelector('ul');

        if (chevron) {
          chevron.textContent = '▼';
        }

        if (subfolders) {
          subfolders.style.display = 'block';
        }

        folder.classList.add(this.config.expandedClass);
      }
    });
  }

  /**
   * Handle errors with optional error handler delegation
   * @param {string} message - Error message
   * @param {Error} error - Error object
   */
  handleError(message, _error) {
    if (this.errorHandler && typeof this.errorHandler.handleError === 'function') {
      this.errorHandler.handleError(message, _error);
    } else {
      // Fallback to logger.error when no error handler
      logger.error(`[CHEVRONS] ${message}:`, _error);
    }
  }

  /**
   * Log debug messages (for test compatibility)
   * @param {string} message - Log message
   * @param {...any} args - Additional arguments
   */
  log(message, ...args) {
    if (this.debug && this.debugHelper && typeof this.debugHelper.log === 'function') {
      this.debugHelper?.log?.(`🔽 SidebarChevrons: ${message}`, ...args);
    }
  }

  /**
   * Check if a folder is a top-level folder (direct child of main sidebar)
   * @param {HTMLElement} folder - The folder li element
   * @returns {boolean} True if this is a top-level folder
   */
  isTopLevelFolder(folder) {
    if (!folder) {
      return false;
    }

    const parentUl = folder.parentElement;
    if (!parentUl || parentUl.tagName !== 'UL') {
      return false;
    }

    const grandParent = parentUl.parentElement;
    // Top-level folders are direct children of .sidebar-nav or .sidebar
    return grandParent && (grandParent.classList.contains('sidebar-nav') || grandParent.classList.contains('sidebar'));
  }

  /**
   * Collapse other top-level folders to implement accordion behavior
   * @param {HTMLElement} currentFolder - The folder being expanded
   */
  collapseOtherTopLevelFolders(currentFolder) {
    const sidebar = document.querySelector('.sidebar');
    if (!sidebar) {
      return;
    }

    const topLevelFolders = sidebar.querySelectorAll(':scope > ul > li, .sidebar-nav > ul > li');

    topLevelFolders.forEach(folder => {
      if (folder !== currentFolder && folder.querySelector('ul')) {
        const folderKey = this.getFolderKey(folder);
        const _folderName = folder.querySelector('a')?.textContent?.trim() || 'Unknown folder';

        // Only collapse if it's currently expanded (not auto-expanded)
        if (this.expandedFolders.has(folderKey)) {
          // console.log(`SidebarChevrons: Collapsing other top-level folder "${folderName}" for accordion behavior`);
          this.setFolderState(folder, false);
          this.expandedFolders.delete(folderKey);
        }
      }
    });

    // Don't save state here - let the calling method handle it
  }
}

/**
 * Initialize when DOM is ready
 */
const initializeSidebarChevrons = () => {
  const sidebarChevrons = new SidebarChevrons({
    debug: false,
    storageKey: 'sidebar-expanded-folders'
  });

  const initialize = () => {
    // Wait for Docsify to render the sidebar
    const checkSidebar = () => {
      const sidebar = document.querySelector('.sidebar-nav');
      if (sidebar) {
        sidebarChevrons.initialize();
        // console.log('SidebarChevrons initialized successfully');
      } else {
        // Retry if sidebar not ready yet
        setTimeout(checkSidebar, 100);
      }
    };
    checkSidebar();
  };

  const reinitialize = () => {
    // Prevent infinite reinitialize loops
    if (sidebarChevrons.isReinitializing) {
      // console.log('SidebarChevrons: Skipping reinitialize - already in progress');
      return;
    }

    // console.log('SidebarChevrons: Reinitializing due to content change');
    sidebarChevrons.destroy();
    setTimeout(() => {
      sidebarChevrons.initialize();
    }, 50);
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize);
  } else {
    initialize();
  }

  // Listen for Docsify sidebar updates
  document.addEventListener('sidebarReloaded', () => {
    setTimeout(reinitialize, 100);
  });

  // Listen for Docsify route changes
  window.addEventListener('hashchange', () => {
    setTimeout(reinitialize, 200);
  });

  // Listen for custom Docsify integration events
  window.addEventListener('docsify-integration:after-each', () => {
    setTimeout(reinitialize, 150);
  });

  window.addEventListener('docsify-integration:done-each', () => {
    setTimeout(reinitialize, 100);
  });

  // Listen for general content changes
  if (typeof MutationObserver !== 'undefined') {
    const observer = new MutationObserver((mutations) => {
      // Skip if we're already reinitializing to prevent loops
      if (sidebarChevrons.isReinitializing) {
        return;
      }

      let shouldReinit = false;
      mutations.forEach((mutation) => {
        if (mutation.type === 'childList' && mutation.target.classList &&
            (mutation.target.classList.contains('sidebar-nav') ||
             mutation.target.closest('.sidebar-nav'))) {

          // Check if the mutation is adding/removing significant content, not just chevrons
          const addedNodes = Array.from(mutation.addedNodes);
          const removedNodes = Array.from(mutation.removedNodes);

          // Ignore mutations that only involve chevron elements
          const isChevronOnlyMutation =
            addedNodes.every(node =>
              node.nodeType !== Node.ELEMENT_NODE ||
              node.classList?.contains('chevron') ||
              node.querySelector?.('.chevron') === node
            ) &&
            removedNodes.every(node =>
              node.nodeType !== Node.ELEMENT_NODE ||
              node.classList?.contains('chevron') ||
              node.querySelector?.('.chevron') === node
            );

          if (!isChevronOnlyMutation) {
            shouldReinit = true;
          }
        }
      });

      if (shouldReinit) {
        clearTimeout(window.chevronReinitTimeout);
        window.chevronReinitTimeout = setTimeout(reinitialize, 100);
      }
    });

    // Observe the sidebar for changes
    let observerTimeout;
    const startObserving = () => {
      const sidebar = document.querySelector('.sidebar') || document.querySelector('.sidebar-nav');
      if (sidebar) {
        observer.observe(sidebar, {
          childList: true,
          subtree: true
        });
        // console.log('SidebarChevrons: Started observing sidebar changes');
      } else {
        observerTimeout = setTimeout(startObserving, 500);
      }
    };

    // Store cleanup function for the observer timeout
    if (!window.chevronObserverCleanup) {
      window.chevronObserverCleanup = () => {
        if (observerTimeout) {
          clearTimeout(observerTimeout);
          observerTimeout = null;
        }
        if (observer) {
          observer.disconnect();
        }
      };
    }

    startObserving();
  }

  // Make available globally for debugging and E2E tests
  window.sidebarChevrons = sidebarChevrons;

  return sidebarChevrons;
};

// Auto-initialize when module loads
const globalSidebarChevrons = initializeSidebarChevrons();

// Export the class, initialization function, and instance
export default SidebarChevrons;
export { initializeSidebarChevrons, globalSidebarChevrons };
