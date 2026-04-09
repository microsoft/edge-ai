/**
 * Interactive Learning Path Checkboxes Component
 *
 * Provides assessment-driven interactive checkbox functionality for learning paths
 * while maintaining Docsify's markdown-first approach and progressive enhancement.
 */

import { ErrorHandler } from '../core/error-handler.js';
import { LearningPathManager } from '../core/learning-path-manager.js';
import { DOMUtils } from '../utils/dom-utils.js';
import { StorageManager } from '../core/storage-manager.js';
import { KataDetection } from '../utils/kata-detection.js';
import { defaultDebugHelper } from '../utils/debug-helper.js';

export class InteractiveLearningPathCheckboxes {
  constructor(dependencies) {
    this.validateDependencies(dependencies);

    this.errorHandler = dependencies.errorHandler;
    this.learningPathManager = dependencies.learningPathManager;
    this.domUtils = dependencies.domUtils;
    this.debugHelper = dependencies.debugHelper;

    this.eventListeners = [];
    this.debounceTimeout = null;
    this.isInitialized = false;
  }

  validateDependencies(dependencies) {
    if (!dependencies?.errorHandler) {
      throw new Error('InteractiveLearningPathCheckboxes requires errorHandler dependency');
    }
    if (!dependencies?.learningPathManager) {
      throw new Error('InteractiveLearningPathCheckboxes requires learningPathManager dependency');
    }
    if (!dependencies?.domUtils) {
      throw new Error('InteractiveLearningPathCheckboxes requires domUtils dependency');
    }
    if (!dependencies?.debugHelper) {
      throw new Error('InteractiveLearningPathCheckboxes requires debugHelper dependency');
    }
  }

  /**
   * Decorate learning path checkboxes with required data attributes
   * Extracts kata IDs from links and adds data-kata-id and data-checkbox-type
   * Must run before initializeEventListeners()
   *
   * @private
   * @returns {void}
   */
  decorateLearningPathCheckboxes() {
    return this.errorHandler.safeExecute(() => {
      // Find all list items with checkboxes in the learning path content
      const taskItems = this.domUtils.querySelectorAll('.markdown-section li, .content li, article li');
      this.debugHelper.log(`Found ${taskItems.length} list items to check for decoration`);

      let decoratedCount = 0;
      const decoratedIds = [];

      taskItems.forEach((item) => {
        const checkbox = item.querySelector('input[type="checkbox"]');
        const kataLink = item.querySelector('a[href*="/katas/"]');
        const pathLink = item.querySelector('a[href*="/paths/"]');

        if (!checkbox) return;

        // Skip if already decorated
        if (checkbox.hasAttribute('data-kata-id')) {
          this.debugHelper.log(`Checkbox already decorated, skipping`);
          return;
        }

        // If it's a path link, check if it's in Prerequisites section
        if (pathLink) {
          // Walk backwards through siblings to find the closest heading
          let currentElement = item.previousElementSibling;
          let foundPrerequisites = false;

          while (currentElement) {
            if (currentElement.tagName && /^H[1-6]$/.test(currentElement.tagName)) {
              // Found a heading - check if it's Prerequisites
              if (/prerequisite/i.test(currentElement.textContent)) {
                foundPrerequisites = true;
              }
              // Stop at the first heading we encounter
              break;
            }
            currentElement = currentElement.previousElementSibling;
          }

          // Skip prerequisite checkboxes - leave them as static informational elements
          if (foundPrerequisites) {
            this.debugHelper.log(`Skipping prerequisite checkbox - no completion tracking available`);
            return;
          }
        }

        // Only decorate kata checkboxes
        if (!kataLink) {
          this.debugHelper.log(`Skipping non-kata checkbox`);
          return;
        }

        // Extract kata ID from link href
        const itemId = this.extractItemIdFromLink(kataLink.href);
        if (!itemId) {
          this.debugHelper.warn(`Could not extract kata ID from link: ${kataLink.href}`);
          return;
        }

        // Add required data attributes for kata checkboxes only
        checkbox.setAttribute('data-kata-id', itemId);
        checkbox.setAttribute('data-checkbox-type', 'selection');

        // Add progress badge if progress exists
        this.addProgressBadgeToKata(item, itemId, kataLink);

        decoratedCount++;
        decoratedIds.push(itemId);
        this.debugHelper.log(`Decorated selection checkbox for kata: ${itemId}`);
      });

      this.debugHelper.log(`Decorated ${decoratedCount} checkboxes on learning path page:`, decoratedIds);
    }, 'InteractiveLearningPathCheckboxes.decorateLearningPathCheckboxes');
  }

  /**
   * Add progress badge to kata list item
   * @private
   * @param {HTMLElement} listItem - The list item containing the kata
   * @param {string} kataId - The kata ID
   * @param {HTMLElement} kataLink - The kata link element
   */
  async addProgressBadgeToKata(listItem, kataId, kataLink) {
    return this.errorHandler.safeExecute(async () => {
      // Get progress from learning path manager
      const progress = await this.learningPathManager.getKataProgress(kataId);

      const percentage = progress?.completionPercentage || 0;

      // Remove existing badge if present
      const existingBadge = listItem.querySelector('.kata-progress-badge');
      if (existingBadge) {
        existingBadge.remove();
      }

      // Create badge element
      const badge = document.createElement('span');
      badge.className = 'kata-progress-badge';
      const displayText = percentage === 0 ? 'Not Started' : `${percentage}%`;
      badge.textContent = displayText;
      badge.setAttribute('aria-label', percentage === 0 ? 'Progress: Not Started' : `Progress: ${percentage}% complete`);

      // Apply color class based on percentage
      if (percentage === 0) {
        badge.classList.add('not-started');
      } else if (percentage === 100) {
        badge.classList.add('complete');
      } else if (percentage >= 75) {
        badge.classList.add('near-complete');
      } else if (percentage >= 25) {
        badge.classList.add('progress');
      } else {
        badge.classList.add('started');
      }

      // Insert badge after the kata link
      if (kataLink.nextSibling) {
        kataLink.parentNode.insertBefore(badge, kataLink.nextSibling);
      } else {
        kataLink.parentNode.appendChild(badge);
      }

      this.debugHelper.log(`Added progress badge ${percentage}% for kata: ${kataId}`);
    }, 'InteractiveLearningPathCheckboxes.addProgressBadgeToKata');
  }

  /**
   * Style learning path metadata line (Level • Duration • Topics)
   * Finds paragraphs matching the pattern and wraps them in a styled container
   * @private
   * @returns {void}
   */
  styleLearningPathMetadata() {
    return this.errorHandler.safeExecute(() => {
      // Find all paragraphs in the markdown section
      const paragraphs = this.domUtils.querySelectorAll('.markdown-section > p');
      console.log('[Intro Styling] Found paragraphs:', paragraphs.length);

      let metadataParagraph = null;
      let descriptionParagraph = null;
      let perfectForParagraph = null;
      let recommendedForParagraph = null;
      let metadataIndex = -1;

      // Find all the intro section paragraphs
      paragraphs.forEach((p, index) => {
        const innerHTML = p.innerHTML || '';
        const text = p.textContent || '';

        // Metadata line: **Level**: ... • **Duration**: ... • **Topics**: ...
        if (!metadataParagraph && innerHTML.includes('<strong>Level</strong>') &&
            innerHTML.includes('<strong>Duration</strong>') &&
            innerHTML.includes('<strong>Topics</strong>')) {
          metadataParagraph = p;
          metadataIndex = index;
          console.log('[Intro Styling] Found metadata at index:', index);
        }
        // Description paragraph (right after metadata, no bold markers)
        else if (metadataParagraph && !descriptionParagraph &&
                 !innerHTML.includes('<strong>Perfect for</strong>') &&
                 !innerHTML.includes('<strong>Recommended for</strong>') &&
                 text.length > 20) {
          descriptionParagraph = p;
          console.log('[Intro Styling] Found description at index:', index);
        }
        // Perfect for line
        else if (innerHTML.includes('<strong>Perfect for</strong>')) {
          perfectForParagraph = p;
          console.log('[Intro Styling] Found Perfect for at index:', index);
        }
        // Recommended for line
        else if (innerHTML.includes('<strong>Recommended for</strong>')) {
          recommendedForParagraph = p;
          console.log('[Intro Styling] Found Recommended for at index:', index);
        }
      });

      // Only proceed if we found at least the metadata paragraph
      if (!metadataParagraph) {
        console.log('[Intro Styling] No metadata paragraph found');
        return;
      }

      // Check if already styled
      if (metadataParagraph.classList.contains('learning-path-intro-styled')) {
        console.log('[Intro Styling] Already styled, skipping');
        return;
      }

      // Create intro section container
      const introSection = document.createElement('div');
      introSection.className = 'learning-path-intro';

      // Parse and add metadata
      const text = metadataParagraph.textContent || '';
      const levelMatch = text.match(/Level:\s*([^•]+)/);
      const durationMatch = text.match(/Duration:\s*([^•]+)/);
      const topicsMatch = text.match(/Topics:\s*(.+?)$/);

      if (levelMatch && durationMatch && topicsMatch) {
        const metadataDiv = document.createElement('div');
        metadataDiv.className = 'learning-path-metadata';

        // Level
        const levelItem = document.createElement('div');
        levelItem.className = 'metadata-item';
        levelItem.innerHTML = `<span class="metadata-label">Level:</span><span class="metadata-value">${levelMatch[1].trim()}</span>`;
        metadataDiv.appendChild(levelItem);

        // Separator
        const sep1 = document.createElement('span');
        sep1.className = 'metadata-separator';
        sep1.textContent = '•';
        metadataDiv.appendChild(sep1);

        // Duration
        const durationItem = document.createElement('div');
        durationItem.className = 'metadata-item';
        durationItem.innerHTML = `<span class="metadata-label">Duration:</span><span class="metadata-value">${durationMatch[1].trim()}</span>`;
        metadataDiv.appendChild(durationItem);

        // Separator
        const sep2 = document.createElement('span');
        sep2.className = 'metadata-separator';
        sep2.textContent = '•';
        metadataDiv.appendChild(sep2);

        // Topics
        const topicsItem = document.createElement('div');
        topicsItem.className = 'metadata-item';
        topicsItem.innerHTML = `<span class="metadata-label">Topics:</span><span class="metadata-value">${topicsMatch[1].trim()}</span>`;
        metadataDiv.appendChild(topicsItem);

        introSection.appendChild(metadataDiv);
      }

      // Add description
      if (descriptionParagraph) {
        const descDiv = document.createElement('div');
        descDiv.className = 'learning-path-description';
        descDiv.innerHTML = descriptionParagraph.innerHTML;
        introSection.appendChild(descDiv);
      }

      // Add Perfect for
      if (perfectForParagraph) {
        const perfectDiv = document.createElement('div');
        perfectDiv.className = 'learning-path-audience';
        perfectDiv.innerHTML = perfectForParagraph.innerHTML;
        introSection.appendChild(perfectDiv);
      }

      // Add Recommended for
      if (recommendedForParagraph) {
        const recommendedDiv = document.createElement('div');
        recommendedDiv.className = 'learning-path-roles';
        recommendedDiv.innerHTML = recommendedForParagraph.innerHTML;
        introSection.appendChild(recommendedDiv);
      }

      // Mark as styled
      metadataParagraph.classList.add('learning-path-intro-styled');

      // Replace metadata paragraph with intro section
      metadataParagraph.parentNode.replaceChild(introSection, metadataParagraph);

      // Remove the other paragraphs we've incorporated
      if (descriptionParagraph && descriptionParagraph.parentNode) {
        descriptionParagraph.parentNode.removeChild(descriptionParagraph);
      }
      if (perfectForParagraph && perfectForParagraph.parentNode) {
        perfectForParagraph.parentNode.removeChild(perfectForParagraph);
      }
      if (recommendedForParagraph && recommendedForParagraph.parentNode) {
        recommendedForParagraph.parentNode.removeChild(recommendedForParagraph);
      }

      console.log('[Intro Styling] Successfully styled intro section');
      this.debugHelper.log('Styled learning path intro section');
    }, 'InteractiveLearningPathCheckboxes.styleLearningPathMetadata');
  }

  /**
   * Extract item ID from link href (supports both katas and paths)
   * Matches the format used by catalog-hydration.js extractItemIdFromLink()
   *
   * @private
   * @param {string} href - Link href (e.g., '#/learning/katas/ai-assisted-engineering/100-ai-development-fundamentals.md' or 'foundation-ai-first-engineering.md')
   * @returns {string|null} Item ID (e.g., 'ai-assisted-engineering-100-ai-development-fundamentals' or 'path-foundation-ai-first-engineering')
   */
  extractItemIdFromLink(href) {
    // Strip Docsify hash prefix if present (#/learning/katas/... → /learning/katas/...)
    const cleanHref = href.startsWith('#/') ? href.substring(1) : href;

    // Kata: katas/category/number-name(.md) → category-number-name
    // Also handles relative paths: ../katas/category/number-name.md
    const kataMatch = cleanHref.match(/katas\/([^\/]+)\/([^\/\.#]+)/);
    if (kataMatch) {
      return `${kataMatch[1]}-${kataMatch[2]}`;
    }

    // Path: paths/path-name(.md) → path-path-name
    // Also handles relative paths: ./foundation-ai-first-engineering.md or foundation-ai-first-engineering.md
    const pathMatch = cleanHref.match(/(?:paths\/)?([a-z0-9-]+)\.md/);
    if (pathMatch) {
      const pathName = pathMatch[1];
      // If it doesn't already start with 'path-', add it
      return pathName.startsWith('path-') ? pathName : `path-${pathName}`;
    }

    return null;
  }

  initialize() {
    return this.errorHandler.safeExecute(async () => {
      if (this.isInitialized) {
        this.debugHelper.warn('InteractiveLearningPathCheckboxes already initialized, use reinitialize() for page changes');
        return false;
      }

      this.debugHelper.log('Initializing InteractiveLearningPathCheckboxes');

      // Track initialization performance for E2E requirements
      const startTime = performance.now();

      // Ensure accessibility foundation is in place first
      await this.ensureAccessibilityCompliance();

      // Initialize learning path manager to load selections from API
      if (this.learningPathManager && typeof this.learningPathManager.init === 'function') {
        await this.learningPathManager.init();
      }

      // Decorate checkboxes with required data attributes FIRST
      this.decorateLearningPathCheckboxes();

      // Add primary select-all checkbox
      this.addPrimarySelectAllCheckbox();

      // Initialize event listeners with enhanced error handling
      this.initializeEventListeners();

      // Sync state from learning path manager
      this.syncStateFromManager();

      // Style learning path metadata
      this.styleLearningPathMetadata();

      // Set up E2E integration points
      await this.setupE2EIntegration();

      // Set up periodic save with enhanced error handling
      this.setupPeriodicSave();

      // Set up error recovery mechanisms
      this.setupErrorRecovery();

      // Track initialization performance for E2E tests
      const initTime = performance.now() - startTime;
      this.debugHelper.log('Initialization completed in:', initTime, 'ms');

      this.isInitialized = true;
      this.debugHelper.log('InteractiveLearningPathCheckboxes initialized successfully');
      return true;
    }, 'InteractiveLearningPathCheckboxes.initialize', false);
  }

  /**
   * Reinitialize component for page navigation
   * Re-decorates checkboxes and syncs state without full initialization
   * Used when navigating between learning path pages
   *
   * @returns {boolean} Success status
   */
  reinitialize() {
    return this.errorHandler.safeExecute(() => {
      this.debugHelper.log('Reinitializing InteractiveLearningPathCheckboxes for page change');

      // Re-decorate checkboxes on new page
      this.decorateLearningPathCheckboxes();

      // Re-add primary select-all checkbox
      this.addPrimarySelectAllCheckbox();

      // Sync state from learning path manager
      this.syncStateFromManager();

      // Style learning path metadata
      this.styleLearningPathMetadata();

      this.debugHelper.log('Reinitialization completed');
      return true;
    }, 'InteractiveLearningPathCheckboxes.reinitialize', false);
  }

  initializeEventListeners() {
    return this.errorHandler.safeExecute(() => {
      // Find all learning path selection checkboxes (📚)
      const selectionCheckboxes = this.domUtils.querySelectorAll('input[type="checkbox"][data-kata-id][data-checkbox-type="selection"]');

      // Find all learning path completion checkboxes (✅)
      const completionCheckboxes = this.domUtils.querySelectorAll('input[type="checkbox"][data-kata-id][data-checkbox-type="completion"]');

      // Handle selection checkbox changes
      selectionCheckboxes.forEach(checkbox => {
        const handleSelectionChange = (event) => {
          const kataId = event.target.getAttribute('data-kata-id');
          const isSelected = event.target.checked;

          if (kataId) {
            this.handleKataSelection(kataId, isSelected);
          }
        };

        checkbox.addEventListener('change', handleSelectionChange);
        this.eventListeners.push({
          element: checkbox,
          event: 'change',
          handler: handleSelectionChange
        });
      });

      // Handle completion checkbox changes
      completionCheckboxes.forEach(checkbox => {
        const handleCompletionChange = (event) => {
          const kataId = event.target.getAttribute('data-kata-id');
          const isCompleted = event.target.checked;

          if (kataId) {
            this.handleKataCompletion(kataId, isCompleted);
          }
        };

        checkbox.addEventListener('change', handleCompletionChange);
        this.eventListeners.push({
          element: checkbox,
          event: 'change',
          handler: handleCompletionChange
        });
      });

      this.debugHelper.log(`Initialized event listeners for ${selectionCheckboxes.length} selection and ${completionCheckboxes.length} completion checkboxes`);
    }, 'InteractiveLearningPathCheckboxes.initializeEventListeners');
  }

  handleKataSelection(kataId, isSelected) {
    return this.errorHandler.safeExecute(() => {
      this.debugHelper.log(`Handling kata selection: ${kataId} = ${isSelected}`);

      // Update the learning path manager for selection state
      this.learningPathManager.updatePathSelection(kataId, isSelected);

      // Debounced persistence
      this.debouncedPathUpdate();

      // Update primary checkbox state
      this.updatePrimaryCheckboxState();

    }, 'InteractiveLearningPathCheckboxes.handleKataSelection');
  }

  handleKataCompletion(kataId, isCompleted) {
    return this.errorHandler.safeExecute(() => {
      this.debugHelper.log(`Handling kata completion: ${kataId} = ${isCompleted}`);

      // Update the learning path manager for completion state
      this.learningPathManager.updateKataProgress(kataId, isCompleted ? 100 : 0);

      // Debounced persistence
      this.debouncedProgressUpdate();

    }, 'InteractiveLearningPathCheckboxes.handleKataCompletion');
  }

  debouncedPathUpdate() {
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout);
    }

    this.debounceTimeout = setTimeout(() => {
      this.errorHandler.safeExecute(() => {
        this.learningPathManager.persistPathSelections();
      }, 'InteractiveLearningPathCheckboxes.debouncedPathUpdate');
    }, 300);
  }

  debouncedProgressUpdate() {
    if (this.progressDebounceTimeout) {
      clearTimeout(this.progressDebounceTimeout);
    }

    this.progressDebounceTimeout = setTimeout(() => {
      this.errorHandler.safeExecute(() => {
        this.learningPathManager.persistProgressState();
      }, 'InteractiveLearningPathCheckboxes.debouncedProgressUpdate');
    }, 300);
  }

  handleAssessmentRecommendation(pathNames) {
    return this.errorHandler.safeExecute(() => {
      const paths = Array.isArray(pathNames) ? pathNames : [pathNames];

      paths.forEach(pathName => {
        this.autoSelectPath(pathName);
      });
    }, 'InteractiveLearningPathCheckboxes.handleAssessmentRecommendation');
  }

  autoSelectPath(pathName) {
    return this.errorHandler.safeExecute(() => {
      this.debugHelper.log(`Auto-selecting path: ${pathName}`);

      const pathItems = this.learningPathManager.getAutoSelectionItems(pathName);

      if (pathItems && pathItems.length > 0) {
        pathItems.forEach(kataId => {
          const checkbox = this.domUtils.querySelector(`input[data-kata-id="${kataId}"]`);
          if (checkbox) {
            checkbox.checked = true;
            this.learningPathManager.updatePathSelection(kataId, true);
          }
        });

        this.debouncedPathUpdate();
      }
    }, 'InteractiveLearningPathCheckboxes.autoSelectPath');
  }

  syncStateFromManager() {
    return this.errorHandler.safeExecute(() => {
      // Sync selection state for kata checkboxes only
      const pathSelections = this.learningPathManager.getPathSelections();
      this.debugHelper.log(`Syncing state - pathSelections:`, pathSelections);

      if (pathSelections) {
        const selectionKeys = Object.keys(pathSelections);
        this.debugHelper.log(`Found ${selectionKeys.length} selections to sync:`, selectionKeys);

        let syncedCount = 0;
        let notFoundCount = 0;

        Object.entries(pathSelections).forEach(([kataId, isSelected]) => {
          const selectionCheckbox = this.domUtils.querySelector(`input[data-kata-id="${kataId}"][data-checkbox-type="selection"]`);
          if (selectionCheckbox) {
            selectionCheckbox.checked = isSelected;
            syncedCount++;
            this.debugHelper.log(`✓ Synced selection for ${kataId}: ${isSelected}`);
          } else {
            notFoundCount++;
            this.debugHelper.warn(`✗ No selection checkbox found for kata: ${kataId}`);
          }
        });

        this.debugHelper.log(`Selection sync complete: ${syncedCount} synced, ${notFoundCount} not found`);
      } else {
        this.debugHelper.warn('No path selections found from manager');
      }

      // Sync completion state and progress badges for kata checkboxes
      const pathProgress = this.learningPathManager.getPathProgress();
      if (pathProgress) {
        Object.entries(pathProgress).forEach(([kataId, progress]) => {
          const completionCheckbox = this.domUtils.querySelector(`input[data-kata-id="${kataId}"][data-checkbox-type="completion"]`);
          if (completionCheckbox) {
            // Consider completed if progress is 100%
            const isCompleted = progress && (progress.completionPercentage === 100 || progress === true);
            completionCheckbox.checked = isCompleted;
          }

          // Update progress badge for selection checkboxes on learning paths
          const selectionCheckbox = this.domUtils.querySelector(`input[data-kata-id="${kataId}"][data-checkbox-type="selection"]`);
          if (selectionCheckbox) {
            const listItem = selectionCheckbox.closest('li');
            const kataLink = listItem ? listItem.querySelector('a[href*="/katas/"]') : null;
            if (listItem && kataLink) {
              this.addProgressBadgeToKata(listItem, kataId, kataLink);
            }
          }
        });
      }
    }, 'InteractiveLearningPathCheckboxes.syncStateFromManager');
  }

  getKataState(kataId) {
    return this.errorHandler.safeExecute(() => {
      const selectionCheckbox = this.domUtils.querySelector(`input[data-kata-id="${kataId}"][data-checkbox-type="selection"]`);
      const completionCheckbox = this.domUtils.querySelector(`input[data-kata-id="${kataId}"][data-checkbox-type="completion"]`);

      return {
        isSelected: selectionCheckbox ? selectionCheckbox.checked : false,
        isCompleted: completionCheckbox ? completionCheckbox.checked : false
      };
    }, 'InteractiveLearningPathCheckboxes.getKataState', { isSelected: false, isCompleted: false });
  }

  /**
   * Ensures accessibility compliance for WCAG 2.1 AA standards
   * Required for E2E accessibility tests
   */
  async ensureAccessibilityCompliance() {
    return this.errorHandler.safeExecute(async () => {
      const selectionCheckboxes = this.domUtils.querySelectorAll('input[type="checkbox"][data-kata-id][data-checkbox-type="selection"]');
      const completionCheckboxes = this.domUtils.querySelectorAll('input[type="checkbox"][data-kata-id][data-checkbox-type="completion"]');
      const allCheckboxes = [...selectionCheckboxes, ...completionCheckboxes];

      allCheckboxes.forEach(checkbox => {
        const label = checkbox.closest('label') || this.domUtils.querySelector(`label[for="${checkbox.id}"]`);
        const checkboxType = checkbox.getAttribute('data-checkbox-type');

        // Ensure proper label association
        if (label && !checkbox.id) {
          const uniqueId = `kata-checkbox-${checkboxType}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
          checkbox.id = uniqueId;
          label.setAttribute('for', uniqueId);
        }

        // Add ARIA attributes for screen readers
        checkbox.setAttribute('role', 'checkbox');
        checkbox.setAttribute('aria-describedby', `${checkbox.id}-description`);

        // Add keyboard navigation support
        checkbox.setAttribute('tabindex', '0');

        // Ensure proper contrast and high contrast support
        checkbox.classList.add('high-contrast-compliant');

        // Add aria-label if no visible label
        if (!label) {
          const kataId = checkbox.getAttribute('data-kata-id');
          const actionText = checkboxType === 'selection' ? 'Add to learning path' : 'Mark as completed';
          checkbox.setAttribute('aria-label', `${actionText} for ${kataId}`);
        }
      });

      this.debugHelper.log('Accessibility compliance ensured for', allCheckboxes.length, 'checkboxes');
    }, 'InteractiveLearningPathCheckboxes.ensureAccessibilityCompliance');
  }

  /**
   * Sets up E2E integration points with other components
   * Required for cross-component integration tests
   */
  async setupE2EIntegration() {
    return this.errorHandler.safeExecute(async () => {
      // Set up integration with Progress Annotations
      if (window.progressAnnotations) {
        this.progressAnnotations = window.progressAnnotations;
        this.debugHelper.log('Integrated with Progress Annotations');
      }

      // Set up integration with Coach Button
      if (window.coachButton) {
        this.coachButton = window.coachButton;
        this.debugHelper.log('Integrated with Coach Button');
      }

      // Set up integration with Learning Path Sync
      if (window.learningPathSync) {
        this.learningPathSync = window.learningPathSync;
        this.debugHelper.log('Integrated with Learning Path Sync');
      }

      // Set up integration with Auto Selection Engine
      if (window.autoSelectionEngine) {
        this.autoSelectionEngine = window.autoSelectionEngine;
        this.debugHelper.log('Integrated with Auto Selection Engine');
      }

      // Emit integration ready event for E2E tests
      if (typeof window !== 'undefined' && window.dispatchEvent) {
        const event = new CustomEvent('e2e:checkboxes-integrated', {
          detail: {
            timestamp: Date.now(),
            components: {
              progressAnnotations: !!this.progressAnnotations,
              coachButton: !!this.coachButton,
              learningPathSync: !!this.learningPathSync,
              autoSelectionEngine: !!this.autoSelectionEngine
            }
          }
        });
        window.dispatchEvent(event);
      }

      this.debugHelper.log('E2E integration setup complete');
    }, 'InteractiveLearningPathCheckboxes.setupE2EIntegration');
  }

  /**
   * Sets up periodic save functionality with enhanced error handling
   * Required for session persistence E2E tests
   */
  setupPeriodicSave() {
    return this.errorHandler.safeExecute(() => {
      // Clear any existing interval
      if (this.saveInterval) {
        clearInterval(this.saveInterval);
      }

      // Set up periodic save every 30 seconds
      this.saveInterval = setInterval(() => {
        this.errorHandler.safeExecute(() => {
          const currentState = this.getAllKataStates();
          this.learningPathManager.saveProgress(currentState);
          this.debugHelper.log('Periodic save completed');
        }, 'InteractiveLearningPathCheckboxes.periodicSave');
      }, 30000);

      // Set up page visibility API for immediate save on page hide
      if (typeof document !== 'undefined') {
        const handleVisibilityChange = () => {
          if (document.hidden) {
            this.errorHandler.safeExecute(() => {
              const currentState = this.getAllKataStates();
              this.learningPathManager.saveProgress(currentState);
              this.debugHelper.log('Visibility change save completed');
            }, 'InteractiveLearningPathCheckboxes.visibilityChangeSave');
          }
        };

        document.addEventListener('visibilitychange', handleVisibilityChange);
        this.eventListeners.push({
          element: document,
          event: 'visibilitychange',
          handler: handleVisibilityChange
        });
      }

      this.debugHelper.log('Periodic save setup complete');
    }, 'InteractiveLearningPathCheckboxes.setupPeriodicSave');
  }

  /**
   * Sets up error recovery mechanisms
   * Required for error handling E2E tests
   */
  setupErrorRecovery() {
    return this.errorHandler.safeExecute(() => {
      // Set up global error handling for the component
      if (typeof window !== 'undefined') {
        const handleGlobalError = (event) => {
          if (event.error && event.error.stack && event.error.stack.includes('InteractiveLearningPathCheckboxes')) {
            this.debugHelper.log('Recovering from global error in checkboxes:', event.error);

            // Attempt to reinitialize if not in a destroy state
            if (!this.isDestroyed) {
              setTimeout(() => {
                this.recoverFromError();
              }, 1000);
            }
          }
        };

        window.addEventListener('error', handleGlobalError);
        this.eventListeners.push({
          element: window,
          event: 'error',
          handler: handleGlobalError
        });
      }

      this.debugHelper.log('Error recovery setup complete');
    }, 'InteractiveLearningPathCheckboxes.setupErrorRecovery');
  }

  /**
   * Gets the current state of all kata checkboxes
   * Required for state management E2E tests
   */
  getAllKataStates() {
    return this.errorHandler.safeExecute(() => {
      const states = {};
      const selectionCheckboxes = this.domUtils.querySelectorAll('input[type="checkbox"][data-kata-id][data-checkbox-type="selection"]');
      const completionCheckboxes = this.domUtils.querySelectorAll('input[type="checkbox"][data-kata-id][data-checkbox-type="completion"]');

      // Get selection states
      selectionCheckboxes.forEach(checkbox => {
        const kataId = checkbox.getAttribute('data-kata-id');
        if (kataId) {
          if (!states[kataId]) {states[kataId] = {};}
          states[kataId].isSelected = checkbox.checked;
        }
      });

      // Get completion states
      completionCheckboxes.forEach(checkbox => {
        const kataId = checkbox.getAttribute('data-kata-id');
        if (kataId) {
          if (!states[kataId]) {states[kataId] = {};}
          states[kataId].isCompleted = checkbox.checked;
        }
      });

      return states;
    }, 'InteractiveLearningPathCheckboxes.getAllKataStates', {});
  }

  /**
   * Sets the state of all kata checkboxes
   * Required for state restoration E2E tests
   */
  setAllKataStates(states) {
    return this.errorHandler.safeExecute(() => {
      if (!states || typeof states !== 'object') {
        return false;
      }

      Object.entries(states).forEach(([kataId, state]) => {
        // Handle legacy format (boolean) for backward compatibility
        if (typeof state === 'boolean') {
          const completionCheckbox = this.domUtils.querySelector(`input[data-kata-id="${kataId}"][data-checkbox-type="completion"]`);
          if (completionCheckbox) {
            completionCheckbox.checked = state;
            const event = new Event('change', { bubbles: true });
            completionCheckbox.dispatchEvent(event);
          }
        } else if (typeof state === 'object') {
          // Handle new format with separate selection and completion states
          if ('isSelected' in state) {
            const selectionCheckbox = this.domUtils.querySelector(`input[data-kata-id="${kataId}"][data-checkbox-type="selection"]`);
            if (selectionCheckbox) {
              selectionCheckbox.checked = !!state.isSelected;
              const event = new Event('change', { bubbles: true });
              selectionCheckbox.dispatchEvent(event);
            }
          }

          if ('isCompleted' in state) {
            const completionCheckbox = this.domUtils.querySelector(`input[data-kata-id="${kataId}"][data-checkbox-type="completion"]`);
            if (completionCheckbox) {
              completionCheckbox.checked = !!state.isCompleted;
              const event = new Event('change', { bubbles: true });
              completionCheckbox.dispatchEvent(event);
            }
          }
        }
      });

      this.debugHelper.log('Set states for', Object.keys(states).length, 'katas');
      return true;
    }, 'InteractiveLearningPathCheckboxes.setAllKataStates', false);
  }

  /**
   * Recovers from errors by reinitializing components
   * Required for error recovery E2E tests
   */
  recoverFromError() {
    return this.errorHandler.safeExecute(() => {
      this.debugHelper.log('Attempting error recovery for InteractiveLearningPathCheckboxes');

      // Clear any corrupted state
      this.eventListeners = [];
      this.isInitialized = false;

      // Attempt to reinitialize
      setTimeout(() => {
        this.initialize();
      }, 100);

      return true;
    }, 'InteractiveLearningPathCheckboxes.recoverFromError', false);
  }

  /**
   * Gets performance metrics for E2E tests
   * Required for performance monitoring E2E tests
   */
  getPerformanceMetrics() {
    return this.errorHandler.safeExecute(() => {
      const selectionCheckboxes = this.domUtils.querySelectorAll('input[type="checkbox"][data-kata-id][data-checkbox-type="selection"]');
      const completionCheckboxes = this.domUtils.querySelectorAll('input[type="checkbox"][data-kata-id][data-checkbox-type="completion"]');
      const totalCheckboxes = selectionCheckboxes.length + completionCheckboxes.length;

      return {
        totalCheckboxes,
        selectionCheckboxes: selectionCheckboxes.length,
        completionCheckboxes: completionCheckboxes.length,
        checkedSelectionCheckboxes: Array.from(selectionCheckboxes).filter(cb => cb.checked).length,
        checkedCompletionCheckboxes: Array.from(completionCheckboxes).filter(cb => cb.checked).length,
        eventListeners: this.eventListeners.length,
        isInitialized: this.isInitialized,
        hasPeriodicSave: !!this.saveInterval,
        memoryUsage: {
          estimatedSize: JSON.stringify(this.getAllKataStates()).length,
          eventListenerCount: this.eventListeners.length
        }
      };
    }, 'InteractiveLearningPathCheckboxes.getPerformanceMetrics', {});
  }

  /**
   * Validates the component state for E2E tests
   * Required for component validation E2E tests
   */
  validateComponentState() {
    return this.errorHandler.safeExecute(() => {
      const issues = [];

      // Check if initialized
      if (!this.isInitialized) {
        issues.push('Component not initialized');
      }

      // Check for required dependencies
      if (!this.learningPathManager) {
        issues.push('Missing learningPathManager dependency');
      }

      if (!this.domUtils) {
        issues.push('Missing domUtils dependency');
      }

      if (!this.errorHandler) {
        issues.push('Missing errorHandler dependency');
      }

      if (!this.debugHelper) {
        issues.push('Missing debugHelper dependency');
      }

      // Check checkbox states
      const selectionCheckboxes = this.domUtils.querySelectorAll('input[type="checkbox"][data-kata-id][data-checkbox-type="selection"]');
      const completionCheckboxes = this.domUtils.querySelectorAll('input[type="checkbox"][data-kata-id][data-checkbox-type="completion"]');
      const totalCheckboxes = selectionCheckboxes.length + completionCheckboxes.length;

      if (totalCheckboxes === 0) {
        issues.push('No checkboxes found');
      }

      // Check accessibility compliance for both types
      [...selectionCheckboxes, ...completionCheckboxes].forEach((checkbox, _index) => {
        const checkboxType = checkbox.getAttribute('data-checkbox-type');

        if (!checkbox.getAttribute('aria-label') && !checkbox.closest('label')) {
          issues.push(`${checkboxType} checkbox ${_index} missing accessibility label`);
        }

        if (!checkbox.getAttribute('role')) {
          issues.push(`${checkboxType} checkbox ${_index} missing role attribute`);
        }
      });

      return {
        isValid: issues.length === 0,
        issues,
        checkboxCount: totalCheckboxes,
        selectionCheckboxCount: selectionCheckboxes.length,
        completionCheckboxCount: completionCheckboxes.length,
        timestamp: Date.now()
      };
    }, 'InteractiveLearningPathCheckboxes.validateComponentState', { isValid: false, issues: ['Validation failed'] });
  }

  /**
   * Select all katas in the current learning path
   * Iterates through all kata checkboxes and selects them if not already selected
   */
  selectAllKatasInPath() {
    return this.errorHandler.safeExecute(() => {
      this.debugHelper.log('Selecting all katas in path');

      const checkboxes = this.domUtils.querySelectorAll('input[type="checkbox"][data-kata-id][data-checkbox-type="selection"]');
      let selectedCount = 0;

      checkboxes.forEach((checkbox) => {
        if (!checkbox.checked) {
          checkbox.checked = true;
          const kataId = checkbox.getAttribute('data-kata-id');
          if (kataId) {
            this.updatePathSelection(kataId, true);
            selectedCount++;
          }
        }
      });

      this.debugHelper.log(`Selected ${selectedCount} katas`);

      // Trigger debounced path update if any selections were made
      if (selectedCount > 0) {
        this.debouncedPathUpdate();
      }

      return selectedCount;
    }, 'InteractiveLearningPathCheckboxes.selectAllKatasInPath', 0);
  }

  /**
   * Deselect all katas in the current learning path
   * Iterates through all kata checkboxes and deselects them if currently selected
   */
  deselectAllKatasInPath() {
    return this.errorHandler.safeExecute(() => {
      this.debugHelper.log('Deselecting all katas in path');

      const checkboxes = this.domUtils.querySelectorAll('input[type="checkbox"][data-kata-id][data-checkbox-type="selection"]');
      let deselectedCount = 0;

      checkboxes.forEach((checkbox) => {
        if (checkbox.checked) {
          checkbox.checked = false;
          const kataId = checkbox.getAttribute('data-kata-id');
          if (kataId) {
            this.updatePathSelection(kataId, false);
            deselectedCount++;
          }
        }
      });

      this.debugHelper.log(`Deselected ${deselectedCount} katas`);

      // Trigger debounced path update if any deselections were made
      if (deselectedCount > 0) {
        this.debouncedPathUpdate();
      }

      return deselectedCount;
    }, 'InteractiveLearningPathCheckboxes.deselectAllKatasInPath', 0);
  }

  /**
   * Add primary select-all checkbox to the page
   * Creates a checkbox that allows selecting/deselecting all katas at once
   */
  addPrimarySelectAllCheckbox() {
    return this.errorHandler.safeExecute(() => {
      this.debugHelper.log('Adding primary select-all checkbox');

      // Check if primary checkbox already exists
      if (this.domUtils.querySelector('.primary-select-all-container')) {
        this.debugHelper.warn('Primary select-all checkbox already exists');
        return;
      }

      // Find the markdown-section container
      const markdownSection = this.domUtils.querySelector('#main .markdown-section');
      if (!markdownSection) {
        this.debugHelper.warn('Markdown section not found, cannot add primary checkbox');
        return;
      }

      // Create checkbox container
      const container = document.createElement('div');
      container.className = 'primary-select-all-container';
      container.style.cssText = 'margin: 1rem 0; padding: 0.75rem; background: #f5f5f5; border-radius: 4px; border: 1px solid #ddd;';

      // Create checkbox
      const checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.id = 'primary-select-all';
      checkbox.className = 'primary-select-all-checkbox';
      checkbox.setAttribute('aria-label', 'Select all katas in this learning path');

      // Create label
      const label = document.createElement('label');
      label.htmlFor = 'primary-select-all';
      label.textContent = ' Select all katas in this path';
      label.style.cssText = 'cursor: pointer; user-select: none; font-weight: 500;';

      // Assemble components
      container.appendChild(checkbox);
      container.appendChild(label);

      // Insert at the top of markdown section
      markdownSection.insertBefore(container, markdownSection.firstChild);

      // Add event listener for checkbox changes
      const changeHandler = () => {
        if (checkbox.checked) {
          this.selectAllKatasInPath();
        } else {
          this.deselectAllKatasInPath();
        }
      };

      checkbox.addEventListener('change', changeHandler);
      this.eventListeners.push({
        element: checkbox,
        event: 'change',
        handler: changeHandler
      });

      this.debugHelper.log('Primary select-all checkbox added successfully');

      // Update initial state
      this.updatePrimaryCheckboxState();
    }, 'InteractiveLearningPathCheckboxes.addPrimarySelectAllCheckbox');
  }

  /**
   * Update the state of the primary select-all checkbox
   * Sets checked, unchecked, or indeterminate state based on kata selections
   */
  updatePrimaryCheckboxState() {
    return this.errorHandler.safeExecute(() => {
      const primaryCheckbox = this.domUtils.querySelector('.primary-select-all-checkbox');
      if (!primaryCheckbox) {
        return;
      }

      const checkboxes = this.domUtils.querySelectorAll('input[type="checkbox"][data-kata-id][data-checkbox-type="selection"]');
      const totalCheckboxes = checkboxes.length;

      if (totalCheckboxes === 0) {
        primaryCheckbox.checked = false;
        primaryCheckbox.indeterminate = false;
        return;
      }

      const checkedCount = Array.from(checkboxes).filter(cb => cb.checked).length;

      if (checkedCount === 0) {
        // None selected
        primaryCheckbox.checked = false;
        primaryCheckbox.indeterminate = false;
      } else if (checkedCount === totalCheckboxes) {
        // All selected
        primaryCheckbox.checked = true;
        primaryCheckbox.indeterminate = false;
      } else {
        // Some selected (indeterminate state)
        primaryCheckbox.checked = false;
        primaryCheckbox.indeterminate = true;
      }

      this.debugHelper.log(`Primary checkbox state updated: ${checkedCount}/${totalCheckboxes} selected`);
    }, 'InteractiveLearningPathCheckboxes.updatePrimaryCheckboxState');
  }

  destroy() {
    return this.errorHandler.safeExecute(() => {
      this.debugHelper.log('Destroying InteractiveLearningPathCheckboxes');

      // Clean up event listeners
      this.eventListeners.forEach(({ element, event, handler }) => {
        try {
          element.removeEventListener(event, handler);
        } catch (_error) {
          this.debugHelper.warn('Error removing event listener:', _error);
        }
      });
      this.eventListeners = [];

      // Clear debounce timeout
      if (this.debounceTimeout) {
        clearTimeout(this.debounceTimeout);
        this.debounceTimeout = null;
      }

      // Clear progress debounce timeout
      if (this.progressDebounceTimeout) {
        clearTimeout(this.progressDebounceTimeout);
        this.progressDebounceTimeout = null;
      }

      // Clear periodic save interval
      if (this.saveInterval) {
        clearInterval(this.saveInterval);
        this.saveInterval = null;
      }

      // Clear integration references
      this.progressAnnotations = null;
      this.coachButton = null;
      this.learningPathSync = null;
      this.autoSelectionEngine = null;

      // Mark as destroyed for error recovery
      this.isDestroyed = true;
      this.isInitialized = false;

      this.debugHelper.log('InteractiveLearningPathCheckboxes destroyed successfully');
    }, 'InteractiveLearningPathCheckboxes.destroy');
  }
}

// Module initialization - create singleton instances
const errorHandler = new ErrorHandler();
const storageManager = new StorageManager();
const domUtils = new DOMUtils();
const kataDetection = new KataDetection();
const learningPathManager = new LearningPathManager({ errorHandler, storageManager, kataDetection });

// Create component instance with dependencies
const interactiveLearningPathCheckboxes = new InteractiveLearningPathCheckboxes({
  learningPathManager,
  errorHandler,
  storageManager,
  domUtils,
  kataDetection,
  debugHelper: defaultDebugHelper,
});

// Export for ES6 module imports
export default interactiveLearningPathCheckboxes;

// Expose globally for Docsify plugin integration
if (typeof window !== 'undefined') {
  window.InteractiveLearningPathCheckboxes = InteractiveLearningPathCheckboxes;
  window.interactiveLearningPathCheckboxes = interactiveLearningPathCheckboxes;
  window.interactiveCheckboxes = interactiveLearningPathCheckboxes; // Alias for main.js compatibility
}
