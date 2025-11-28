/**
 * @fileoverview Sidebar Active Highlighting Module - ES6 Module for highlighting active sidebar items and expanding parent folders
 *
 * @description
 * This module provides functionality for:
 * - Finding and highlighting active sidebar links based on current route
 * - Expanding parent folders to show active items
 * - Managing automatic folder expansion and cleanup
 * - Coordinating with navigation systems
 *
 * Features:
 * - Route-based active link detection with multiple matching strategies
 * - Automatic parent folder expansion with chevron system integration
 * - Smart cleanup of automatic expansions
 * - Navigation coordinator integration
 * - Fallback event handling for standalone operation
 *
 * @author Edge AI Team
 * @since 2025-08-01
 * @version 2.0.0
 */

import { ErrorHandler } from '../core/error-handler.js';
import { DOMUtils } from '../utils/dom-utils.js';

/**
 * Sidebar Active Highlighting class for managing active states and folder expansion
 */
export class SidebarActiveHighlighting {
  /**
   * Constructor for SidebarActiveHighlighting
   * @param {Object} dependencies - Dependencies object
   * @param {ErrorHandler} dependencies.errorHandler - Error handler instance
   * @param {DOMUtils} dependencies.domUtils - DOM utilities instance
   * @param {Object} dependencies.debugHelper - Debug helper (optional)
   */
  constructor({ errorHandler, domUtils, debugHelper } = {}) {
    this.errorHandler = errorHandler || new ErrorHandler('sidebar-highlighting');
    this.domUtils = domUtils || new DOMUtils();
    this.debugHelper = debugHelper || null; // Disable debug logging by default

    this.isInitialized = false;
    this.abortController = null;
    this.fallbackListenersSet = false;

    // Timer tracking for cleanup
    this.timers = new Set();

    // Configuration
    this.config = {
      debounceMs: 100,
      highlightTimeout: 50,
      coordinatorWaitMs: 50
    };
  }

  /**
   * Create and track a timer for cleanup
   * @param {Function} callback - Function to execute
   * @param {number} delay - Delay in milliseconds
   * @returns {number} Timer ID
   */
  createTimer(callback, delay) {
    if (typeof window === 'undefined') {
      return null; // Don't create timers if window is not available
    }

    const timerId = setTimeout(() => {
      this.timers.delete(timerId);
      callback();
    }, delay);

    this.timers.add(timerId);
    return timerId;
  }

  /**
   * Clear all timers for cleanup
   */
  clearAllTimers() {
    for (const timerId of this.timers) {
      clearTimeout(timerId);
    }
    this.timers.clear();
  }

  /**
   * Find all parent folder elements that contain the active link
   * @param {HTMLElement} activeLink - The active sidebar link
   * @returns {Array} Array of parent folder elements that should be expanded
   */
  findParentFolders(activeLink) {
    const parentFolders = [];

    if (!activeLink) {
      return parentFolders;
    }

    // Start from the active link's parent li and traverse up the DOM hierarchy
    let currentLi = activeLink.closest('li');

    while (currentLi && currentLi !== document.body) {
      // Move up to the parent ul
      const parentUl = currentLi.parentElement;

      if (!parentUl || parentUl.tagName !== 'UL') {
        break; // No parent ul found
      }

      // Move up to the parent li that contains this ul
      const parentLi = parentUl.parentElement;

      if (!parentLi || parentLi.tagName !== 'LI') {
        break; // No parent li found, reached root
      }

      // Check if this parent li has a nested ul (indicating it's a folder)
      // Try multiple approaches to find nested UL
      let nestedUl = parentLi.querySelector(':scope > ul');
      if (!nestedUl) {
        // Fallback: check direct children
        nestedUl = Array.from(parentLi.children).find(child => child.tagName === 'UL');
      }

      if (nestedUl) {
        // This is a folder that contains nested items
        const folderLink = parentLi.querySelector(':scope > a') || parentLi.querySelector('a');
        const _folderName = folderLink?.textContent?.trim() || 'Unknown folder';
        parentFolders.push(parentLi);
      }

      // Continue up the hierarchy
      currentLi = parentLi;
    }

    // Reverse the array so we expand from root to leaf
    parentFolders.reverse();

    return parentFolders;
  }

  /**
   * Expand parent folders to show the active item
   * @param {HTMLElement} activeLink - The active sidebar link
   */
  expandParentFolders(activeLink) {
    if (!activeLink) {
      return;
    }

    const parentFolders = this.findParentFolders(activeLink);

    if (parentFolders.length === 0) {
      return;
    }

    // Check if chevron functionality is available
    if (!window.sidebarChevrons || !window.sidebarChevrons.expandFolder) {
      return;
    }

    // Expand each parent folder
    parentFolders.forEach((folder, index) => {
      const folderLink = folder.querySelector('a');
      const _folderName = folderLink?.textContent?.trim() || `Folder ${index + 1}`;

      // Call the chevron system to expand this folder (marked as automatic)
      window.sidebarChevrons.expandFolder(folder, true);
    });
  }

  /**
   * Clean up automatic expansions that are no longer needed
   */
  cleanupAutoExpansions() {
    // First, collapse ALL previously auto-expanded folders
    const allAutoExpanded = document.querySelectorAll('[data-auto-expanded="true"]');

    allAutoExpanded.forEach(folder => {
      const _folderName = folder.querySelector(':scope > a')?.textContent?.trim() || 'Unknown folder';

      // Remove the auto-expanded marker
      folder.removeAttribute('data-auto-expanded');

      // Check if this folder was manually expanded
      const folderKey = this.getFolderKey(folder);
      const isManuallyExpanded = folderKey &&
        window.sidebarChevrons &&
        window.sidebarChevrons.expandedFolders &&
        window.sidebarChevrons.expandedFolders.has(folderKey);

      if (!isManuallyExpanded) {
        // Collapse the folder
        const chevron = folder.querySelector('.chevron');
        if (chevron) {
          folder.classList.remove('expanded');
          folder.classList.add('collapsed');
          chevron.classList.remove('expanded');
          chevron.classList.add('collapsed');
          chevron.setAttribute('aria-expanded', 'false');
        }
      }
    });
  }

  /**
   * Helper function to get folder key (if available from chevron system)
   * @param {HTMLElement} folderElement - The folder element
   * @returns {string|null} The folder key or null
   */
  getFolderKey(folderElement) {
    // Try to use the chevron system's getFolderKey if available
    if (window.sidebarChevrons && window.sidebarChevrons.getFolderKey) {
      return window.sidebarChevrons.getFolderKey(folderElement);
    }

    // Fallback logic
    const folderLink = folderElement.querySelector(':scope > a') || folderElement.querySelector('a');
    if (folderLink) {
      const href = folderLink.getAttribute('href');
      const textContent = folderLink.textContent?.trim();
      const result = href || textContent;
      return result;
    }

    return null;
  }

  /**
   * Validate the parent folder expansion feature
   * @returns {boolean} True if all validations pass
   */
  validateParentExpansion() {
    const validationResults = {
      sidebarExists: false,
      chevronSystemAvailable: false,
      nestedStructureExists: false,
      activeHighlightingWorks: false,
      parentExpansionWorks: false
    };

    // Check if sidebar exists
    const sidebar = document.querySelector('.sidebar');
    validationResults.sidebarExists = !!sidebar;

    // Check if chevron system is available
    validationResults.chevronSystemAvailable = !!(window.sidebarChevrons && window.sidebarChevrons.expandFolder);

    // Check if nested structure exists
    if (sidebar) {
      const nestedItems = sidebar.querySelectorAll('li ul');
      validationResults.nestedStructureExists = nestedItems.length > 0;
    }

    // Check if active highlighting works
    const activeElements = sidebar?.querySelectorAll('.active');
    validationResults.activeHighlightingWorks = activeElements && activeElements.length > 0;

    // Check if parent expansion works with a test
    if (validationResults.sidebarExists && validationResults.chevronSystemAvailable) {
      const testLink = sidebar.querySelector('li ul a'); // Find a deeply nested link
      if (testLink) {
        const parentFolders = this.findParentFolders(testLink);
        validationResults.parentExpansionWorks = parentFolders.length > 0;
      }
    }

    // Overall validation result
    const allValid = Object.values(validationResults).every(result => result === true);

    return allValid;
  }

  /**
   * Find and highlight the active sidebar item based on current route
   */
  updateSidebarActiveHighlighting() {

    // Remove all existing active classes from sidebar
    const sidebar = document.querySelector('.sidebar');
    if (!sidebar) {
      return;
    }

    // Clean up previous automatic expansions first
    this.cleanupAutoExpansions();

    // Clear all active states
    sidebar.querySelectorAll('.active').forEach(element => {
      element.classList.remove('active');
    });

    // Get current path
    const currentHash = window.location.hash || '#/';
    const currentPath = currentHash.replace('#', '') || '/';

    // Find the matching sidebar link
    const sidebarLinks = sidebar.querySelectorAll('a');
    let foundMatch = false;

    for (const link of sidebarLinks) {
      const href = link.getAttribute('href');
      if (!href) {continue;}

      // Clean up href for comparison - remove hash and normalize
      const cleanHref = href.replace('#/', '').replace('#', '');
      const cleanCurrentPath = currentPath.replace('/', '');

      // Also create versions without .md extension for comparison
      const hrefWithoutMd = cleanHref.replace('.md', '');
      const currentPathWithoutMd = cleanCurrentPath.replace('.md', '');

      // Check for exact match with multiple variations
      const isMatch = cleanHref === cleanCurrentPath ||
                     href === currentHash ||
                     href === currentPath ||
                     hrefWithoutMd === currentPathWithoutMd ||
                     hrefWithoutMd === cleanCurrentPath ||
                     cleanHref === currentPathWithoutMd ||
                     (cleanHref && cleanCurrentPath && cleanCurrentPath.startsWith(cleanHref) && cleanHref !== '');

      if (isMatch) {
        // Add active class to the link
        link.classList.add('active');

        // Also add active class to parent li if it exists
        const parentLi = link.closest('li');
        if (parentLi) {
          parentLi.classList.add('active');
        }

        // Expand parent folders to show the active item
        this.expandParentFolders(link);

        foundMatch = true;
        break;
      }
    }

    if (!foundMatch) {
      // Try to find a partial match for nested pages
      const pathParts = currentPath.split('/').filter(part => part && part !== 'index');

      for (let i = pathParts.length; i > 0; i--) {
        const partialPath = pathParts.slice(0, i).join('/');

        for (const link of sidebarLinks) {
          const href = link.getAttribute('href');
          if (!href) {continue;}

          const cleanHref = href.replace('#/', '').replace('#', '');

          if (cleanHref === partialPath || cleanHref.endsWith(`/${ partialPath}`)) {
            link.classList.add('active');
            const parentLi = link.closest('li');
            if (parentLi) {
              parentLi.classList.add('active');
            }

            // Expand parent folders for partial matches too
            this.expandParentFolders(link);

            foundMatch = true;
            break;
          }
        }

        if (foundMatch) {break;}
      }
    }

    if (!foundMatch) {
      // No match found, which is okay for some routes
    }
  }

  /**
   * Setup integration with navigation coordinator
   */
  setupCoordinationIntegration() {
    // Listen for coordinator events (primary method)
    window.addEventListener('navigation:coordinator-highlight', (event) => {
      const _route = event.detail?.route;
      this.updateSidebarActiveHighlighting();
    });

    // Check if coordinator is available and integrate
    const waitForCoordinator = () => {
      // Safety check for window existence (test environment compatibility)
      if (typeof window === 'undefined') {
        return;
      }

      if (window.navigationCoordinator && window.navigationCoordinator.isInitialized()) {
        // Notify coordinator that sidebar is ready
        window.navigationCoordinator.notifySidebarHighlighted('system-ready');
        return;
      }

      // Coordinator not ready yet, use fallback listeners temporarily
      if (!this.fallbackListenersSet) {
        this.setupFallbackListeners();
        this.fallbackListenersSet = true;
      }

      this.createTimer(waitForCoordinator, this.config.coordinatorWaitMs);
    };

    waitForCoordinator();
  }

  /**
   * Fallback event listeners if coordinator is not available
   */
  setupFallbackListeners() {
    if (this.abortController) {
      this.abortController.abort();
    }

    this.abortController = new AbortController();

    // Listen for navigation changes with reduced timeout to minimize conflicts
    window.addEventListener('hashchange', () => {
      this.createTimer(() => this.updateSidebarActiveHighlighting(), this.config.highlightTimeout);
    }, { signal: this.abortController.signal });

    // Listen for popstate (back/forward navigation)
    window.addEventListener('popstate', () => {
      this.createTimer(() => this.updateSidebarActiveHighlighting(), this.config.highlightTimeout);
    }, { signal: this.abortController.signal });
  }

  /**
   * Wait for docsify to be ready and then initialize
   */
  waitForDocsify() {
    // Safety check for window existence (test environment compatibility)
    if (typeof window === 'undefined') {
      return;
    }

    if (window.$docsify) {
      // Add to docsify hooks - but don't directly call highlighting
      // Let the navigation coordinator handle the timing
      window.$docsify.plugins = window.$docsify.plugins || [];
      window.$docsify.plugins.push((hook) => {
        hook.doneEach(() => {
          // The navigation coordinator will handle this via its Docsify integration
        });
      });

      // Initialize immediately if docsify is already loaded
      if (document.querySelector('.sidebar')) {
        this.initialize();
      } else {
        // Wait for DOM to be ready
        this.createTimer(() => this.initialize(), 500);
      }
    } else {
      // Wait for docsify to load
      this.createTimer(() => this.waitForDocsify(), 100);
    }
  }

  /**
   * Initialize sidebar active highlighting with navigation coordination
   */
  initialize() {
    if (this.isInitialized) {
      return;
    }

    // Initial highlighting
    this.updateSidebarActiveHighlighting();

    // Setup coordination integration
    this.setupCoordinationIntegration();

    this.isInitialized = true;
  }

  /**
   * Destroy the sidebar highlighting instance and clean up resources
   */
  destroy() {

    if (this.abortController) {
      this.abortController.abort();
      this.abortController = null;
    }

    // Clear all timers to prevent post-test execution
    this.clearAllTimers();

    this.cleanupAutoExpansions();
    this.isInitialized = false;
    this.fallbackListenersSet = false;
  }

  /**
   * Test function for validating parent folder expansion
   * @param {string} linkSelector - CSS selector for the test link
   * @returns {boolean} True if test passes
   */
  testParentExpansion(linkSelector) {
    const link = document.querySelector(linkSelector);
    if (!link) {
      return false;
    }

    const _linkText = link.textContent?.trim();
    const _linkHref = link.getAttribute('href');

    // Clean up any previous automatic expansions first
    this.cleanupAutoExpansions();

    const parentFolders = this.findParentFolders(link);

    this.expandParentFolders(link);

    // Verify all parent folders are expanded
    let allExpanded = true;
    parentFolders.forEach((folder, index) => {
      const isExpanded = folder.classList.contains('expanded');
      const folderName = folder.querySelector(':scope > a')?.textContent?.trim() || `Folder ${index + 1}`;
      if (!isExpanded) {allExpanded = false;}
    });

    return allExpanded;
  }

  /**
   * Enhanced validation function for parent folder expansion
   * @param {string} linkSelector - CSS selector for the validation link
   * @returns {boolean} True if validation passes
   */
  validateParentExpansionForLink(linkSelector) {
    const link = document.querySelector(linkSelector);
    if (!link) {
      return false;
    }

    const _linkText = link.textContent?.trim();
    const _linkHref = link.getAttribute('href');

    const parentFolders = this.findParentFolders(link);

    // Validate that each parent folder is actually an ancestor
    let validationPassed = true;
    parentFolders.forEach((folder, index) => {
      const folderName = folder.querySelector(':scope > a')?.textContent?.trim() || `Folder ${index + 1}`;

      // Check if this folder actually contains the link
      const containsLink = folder.contains(link);

      if (!containsLink) {
        validationPassed = false;
      }
    });

    // Check for incorrectly expanded folders (siblings/cousins)
    const _allExpandedFolders = document.querySelectorAll('.sidebar li.expanded');
    const autoExpandedFolders = document.querySelectorAll('[data-auto-expanded="true"]');

    autoExpandedFolders.forEach(folder => {
      const _folderName = folder.querySelector(':scope > a')?.textContent?.trim() || 'Unknown folder';
      const containsLink = folder.contains(link);

      if (!containsLink) {
        validationPassed = false;
      }
    });

    return validationPassed;
  }

  /**
   * Setup navigation integration with coordinator
   */
  setupNavigationIntegration() {
    this.setupCoordinationIntegration();
  }

  /**
   * Normalize URL for comparison
   * @param {string} url - URL to normalize
   * @returns {string} Normalized URL
   */
  normalizeURL(url) {
    if (!url) {return '';}

    try {
      // Keep hash-based URLs as-is, but normalize file paths
      if (url.startsWith('#/')) {
        return url; // Keep hash-based URLs intact
      }

      // For regular paths, remove query parameters, fragments, and normalize slashes
      return url.replace(/[?#].*$/, '').replace(/\/+/g, '/').replace(/\/$/, '') || '/';
    } catch (error) {
      this.debugHelper.log('❌ [SIDEBAR] Error normalizing URL:', error);
      return '';
    }
  }

  /**
   * Calculate URL match score
   * @param {string} currentURL - Current page URL
   * @param {string} linkURL - Link URL to compare
   * @returns {number} Match score (0-100)
   */
  calculateURLScore(currentURL, linkURL) {
    if (!currentURL || !linkURL) {return 0;}

    const normalizedCurrent = this.normalizeURL(currentURL);
    const normalizedLink = this.normalizeURL(linkURL);

    // Direct match
    if (normalizedCurrent === normalizedLink) {return 100;}

    // For hash-based vs path-based comparison, extract the path parts
    const getCurrentPath = (url) => {
      return url.replace(/^#\//, '/').replace(/^\//, '');
    };

    const currentPath = getCurrentPath(normalizedCurrent);
    const linkPath = getCurrentPath(normalizedLink);

    // Check if paths match after normalization
    if (currentPath === linkPath && currentPath) {return 100;}

    // Calculate partial match score
    const currentParts = currentPath.split('/').filter(Boolean);
    const linkParts = linkPath.split('/').filter(Boolean);

    let matchingParts = 0;
    const minLength = Math.min(currentParts.length, linkParts.length);

    for (let i = 0; i < minLength; i++) {
      if (currentParts[i] === linkParts[i]) {
        matchingParts++;
      } else {
        break;
      }
    }

    return minLength > 0 ? Math.round((matchingParts / minLength) * 80) : 0;
  }

  /**
   * Find active links based on current URL
   * @param {string} currentURL - Current page URL
   * @returns {Element[]} Array of active link elements
   */
  findActiveLinks(currentURL) {
    const links = document.querySelectorAll('.sidebar a');
    const scores = [];

    links.forEach(link => {
      const href = link.getAttribute('href');
      if (href) {
        const score = this.calculateURLScore(currentURL, href);
        if (score > 0) {
          scores.push({ element: link, score });
        }
      }
    });

    // Sort by score (highest first) and return elements
    return scores
      .sort((a, b) => b.score - a.score)
      .map(item => item.element);
  }

  /**
   * Handle error with logging
   * @param {string} message - Error message
   * @param {Error} error - Error object
   */
  handleError(message, error) {
    this.debugHelper.log(`❌ [SIDEBAR] ${message}:`, error);

    if (this.config.throwOnError) {
      throw error;
    }
  }
}

// Initialize when DOM is ready
const _initializeSidebarHighlighting = () => {
  const sidebarHighlighting = new SidebarActiveHighlighting();

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => sidebarHighlighting.waitForDocsify());
  } else {
    sidebarHighlighting.waitForDocsify();
  }

  return sidebarHighlighting;
};

// Export the class as default
export default SidebarActiveHighlighting;
