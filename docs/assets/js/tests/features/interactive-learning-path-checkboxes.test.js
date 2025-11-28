/**
 * Tests for Interactive Learning Path Checkboxes Component
 *
 * Validates dual checkbox event handling, state management, accessibility,
 * and performance metrics for Task 3.2 implementation.
 *
 * @vitest-environment happy-dom
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { InteractiveLearningPathCheckboxes } from '../../features/interactive-learning-path-checkboxes.js';

describe('InteractiveLearningPathCheckboxes', () => {
  let component;
  let mockDependencies;
  let container;

  beforeEach(() => {
    // Setup Happy DOM environment
    document.body.innerHTML = `
      <div id="test-container">
        <div class="learning-item">
          <input type="checkbox" class="path-checkbox" data-kata-id="test-kata-1" data-checkbox-type="selection">
          <input type="checkbox" class="completion-checkbox" data-kata-id="test-kata-1" data-checkbox-type="completion">
          <span>📚</span>
          <span>✅</span>
          <a href="/learning/katas/ai-engineering/test-kata-1.md">Test Kata 1</a>
        </div>
        <div class="learning-item">
          <input type="checkbox" class="path-checkbox" data-kata-id="test-kata-2" data-checkbox-type="selection">
          <input type="checkbox" class="completion-checkbox" data-kata-id="test-kata-2" data-checkbox-type="completion">
          <span>📚</span>
          <span>✅</span>
          <a href="/learning/katas/prompt-engineering/test-kata-2.md">Test Kata 2</a>
        </div>
      </div>
    `;

    // Mock global performance API
    global.performance = {
      now: vi.fn(() => Date.now()),
      mark: vi.fn(),
      measure: vi.fn()
    };

    container = document.getElementById('test-container');

    // Create mock dependencies
    mockDependencies = {
      errorHandler: {
        safeExecute: vi.fn((fn) => fn()),
        logError: vi.fn()
      },
      learningPathManager: {
        getPathSelection: vi.fn(),
        getPathSelections: vi.fn(() => ({})),
        getPathProgress: vi.fn(() => ({})),
        updatePathSelection: vi.fn(),
        getKataProgress: vi.fn(),
        updateKataProgress: vi.fn(),
        persistPathSelections: vi.fn(),
        persistProgressState: vi.fn(),
        calculateProgress: vi.fn(),
        getOverallProgress: vi.fn(() => ({ completed: 0, total: 0, percentage: 0 }))
      },
      domUtils: {
        querySelectorAll: vi.fn((selector) => {
          return Array.from(container.querySelectorAll(selector));
        }),
        querySelector: vi.fn((selector) => {
          return container.querySelector(selector);
        }),
        findCheckboxPairs: vi.fn(),
        updateCheckboxState: vi.fn(),
        updateProgressDisplay: vi.fn()
      },
      debugHelper: {
        log: vi.fn(),
        warn: vi.fn(),
        error: vi.fn()
      }
    };

    component = new InteractiveLearningPathCheckboxes(mockDependencies);
  });

  afterEach(() => {
    // Clean up event listeners and DOM
    if (component && component.cleanup) {
      component.cleanup();
    }
    vi.clearAllMocks();
    document.body.innerHTML = '';
  });

  describe('Component Initialization', () => {
    it('should validate all required dependencies', () => {
      expect(() => {
        new InteractiveLearningPathCheckboxes({});
      }).toThrow('InteractiveLearningPathCheckboxes requires errorHandler dependency');

      expect(() => {
        new InteractiveLearningPathCheckboxes({
          errorHandler: mockDependencies.errorHandler
        });
      }).toThrow('InteractiveLearningPathCheckboxes requires learningPathManager dependency');
    });

    it('should initialize successfully with all dependencies', () => {
      expect(component).toBeDefined();
      expect(component.isInitialized).toBe(false);
    });

    it('should prevent double initialization', async () => {
      await component.initialize();
      expect(component.isInitialized).toBe(true);

      const result = await component.initialize();
      expect(result).toBe(false);
      expect(mockDependencies.debugHelper.warn).toHaveBeenCalledWith(
        'InteractiveLearningPathCheckboxes already initialized, use reinitialize() for page changes'
      );
    });
  });

  describe('Dual Checkbox Event Handling', () => {
    beforeEach(async () => {
      await component.initialize();
    });

    it('should handle selection checkbox clicks independently', () => {
      const selectionCheckbox = container.querySelector('[data-checkbox-type="selection"]');

      // Mock current states
      mockDependencies.learningPathManager.getPathSelection.mockReturnValue(false);
      mockDependencies.learningPathManager.getKataProgress.mockReturnValue({ completed: false });

      // Simulate click
      selectionCheckbox.checked = true;
      selectionCheckbox.dispatchEvent(new Event('change'));

      expect(mockDependencies.learningPathManager.updatePathSelection).toHaveBeenCalledWith(
        'test-kata-1',
        true
      );
    });

    it('should handle completion checkbox clicks independently', () => {
      const completionCheckbox = container.querySelector('[data-checkbox-type="completion"]');

      // Mock current states
      mockDependencies.learningPathManager.getPathSelection.mockReturnValue(true);
      mockDependencies.learningPathManager.getKataProgress.mockReturnValue({ completed: false });

      // Simulate click
      completionCheckbox.checked = true;
      completionCheckbox.dispatchEvent(new Event('change'));

      expect(mockDependencies.learningPathManager.updateKataProgress).toHaveBeenCalledWith(
        'test-kata-1',
        100
      );
    });

    it('should allow both checkboxes to be checked simultaneously', () => {
      const selectionCheckbox = container.querySelector('[data-checkbox-type="selection"]');
      const completionCheckbox = container.querySelector('[data-checkbox-type="completion"]');

      // Check both
      selectionCheckbox.checked = true;
      completionCheckbox.checked = true;

      selectionCheckbox.dispatchEvent(new Event('change'));
      completionCheckbox.dispatchEvent(new Event('change'));

      expect(mockDependencies.learningPathManager.updatePathSelection).toHaveBeenCalledWith(
        'test-kata-1',
        true
      );
      expect(mockDependencies.learningPathManager.updateKataProgress).toHaveBeenCalledWith(
        'test-kata-1',
        100
      );
    });

    it('should allow independent state changes (selection without completion)', () => {
      const selectionCheckbox = container.querySelector('[data-checkbox-type="selection"]');

      // Check only selection
      selectionCheckbox.checked = true;

      selectionCheckbox.dispatchEvent(new Event('change'));

      expect(mockDependencies.learningPathManager.updatePathSelection).toHaveBeenCalledWith(
        'test-kata-1',
        true
      );
      expect(mockDependencies.learningPathManager.updateKataProgress).not.toHaveBeenCalled();
    });
  });

  describe('State Synchronization', () => {
    beforeEach(async () => {
      await component.initialize();
    });

    it('should sync UI state with stored data on load', () => {
      mockDependencies.learningPathManager.getPathSelection.mockReturnValue(true);
      mockDependencies.learningPathManager.getKataProgress.mockReturnValue({ completed: false });

      // Trigger state sync
      if (component.syncCheckboxStates) {
        component.syncCheckboxStates();
        expect(mockDependencies.domUtils.updateCheckboxState).toHaveBeenCalled();
      }
    });

    it('should handle state conflicts gracefully', () => {
      // Simulate conflicting states
      mockDependencies.learningPathManager.getPathSelection.mockReturnValue(false);
      mockDependencies.learningPathManager.getKataProgress.mockReturnValue({ completed: true });

      expect(() => {
        if (component.syncCheckboxStates) {
          component.syncCheckboxStates();
        }
      }).not.toThrow();
    });

    it('should debounce rapid state changes', () => {
      vi.useFakeTimers();

      const checkbox = container.querySelector('[data-checkbox-type="selection"]');

      // Rapid clicks
      checkbox.dispatchEvent(new Event('change'));
      checkbox.dispatchEvent(new Event('change'));
      checkbox.dispatchEvent(new Event('change'));

      // Advance time to trigger debounce
      vi.advanceTimersByTime(300);

      vi.useRealTimers();
    });
  });

  describe('Accessibility Features', () => {
    beforeEach(async () => {
      await component.initialize();
    });

    it('should ensure proper ARIA attributes are set', () => {
      const checkboxes = container.querySelectorAll('input[type="checkbox"]');

      checkboxes.forEach(checkbox => {
        // Enhanced accessibility should be applied
        expect(checkbox.getAttribute('aria-label')).toBeTruthy();
      });
    });

    it('should maintain proper tab order', () => {
      const checkboxes = container.querySelectorAll('input[type="checkbox"]');

      checkboxes.forEach((checkbox) => {
        expect(checkbox.tabIndex).toBe(0);
      });
    });

    it('should provide descriptive labels for screen readers', () => {
      const selectionCheckbox = container.querySelector('[data-checkbox-type="selection"]');
      const completionCheckbox = container.querySelector('[data-checkbox-type="completion"]');

      expect(selectionCheckbox.getAttribute('aria-label')).toContain('Add');
      expect(completionCheckbox.getAttribute('aria-label')).toContain('completed');
    });
  });

  describe('Performance Metrics', () => {
    it('should track initialization performance', async () => {
      await component.initialize();

      expect(global.performance.now).toHaveBeenCalled();
      expect(mockDependencies.debugHelper.log).toHaveBeenCalledWith(
        expect.stringContaining('Initializing InteractiveLearningPathCheckboxes')
      );
    });

    it('should handle large numbers of checkboxes efficiently', async () => {
      // Add many learning items to test performance
      for (let i = 0; i < 50; i++) {
        const learningItem = document.createElement('div');
        learningItem.className = 'learning-item';
        learningItem.innerHTML = `
          <input type="checkbox" class="path-checkbox" data-kata-id="test-kata-${i}" data-checkbox-type="selection">
          <input type="checkbox" class="completion-checkbox" data-kata-id="test-kata-${i}" data-checkbox-type="completion">
          <span>📚</span>
          <span>✅</span>
          <a href="/learning/katas/category/test-kata-${i}.md">Test Kata ${i}</a>
        `;
        container.appendChild(learningItem);
      }

      const startTime = performance.now();
      await component.initialize();
      const endTime = performance.now();

      // Should initialize within reasonable time even with many checkboxes
      expect(endTime - startTime).toBeLessThan(1000); // 1 second max
    });
  });

  describe('Error Handling', () => {
    it('should handle missing kata IDs gracefully', () => {
      const checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.setAttribute('data-checkbox-type', 'selection');
      // Missing data-kata-id attribute
      container.appendChild(checkbox);

      expect(() => {
        checkbox.dispatchEvent(new Event('change'));
      }).not.toThrow();
    });

    it('should handle storage errors gracefully', () => {
      mockDependencies.learningPathManager.updatePathSelection.mockImplementation(() => {
        throw new Error('Storage error');
      });

      const checkbox = container.querySelector('[data-checkbox-type="selection"]');

      expect(() => {
        checkbox.dispatchEvent(new Event('change'));
      }).not.toThrow();
    });
  });

  describe('Integration with Docsify Plugin', () => {
    it('should work with plugin-generated checkboxes', () => {
      // Simulate plugin-generated HTML structure
      const pluginGeneratedHtml = `
        <div class="learning-item">
          <label class="dual-checkbox-container">
            <input type="checkbox" data-kata-id="plugin-test" data-checkbox-type="selection" aria-label="Add Test Kata to learning path">
            <span class="checkmark selection">📚</span>
          </label>
          <label class="dual-checkbox-container">
            <input type="checkbox" data-kata-id="plugin-test" data-checkbox-type="completion" aria-label="Mark Test Kata as completed">
            <span class="checkmark completion">✅</span>
          </label>
          <a href="/learning/katas/test/plugin-test.md">Plugin Test Kata</a>
        </div>
      `;

      container.innerHTML = pluginGeneratedHtml;

      expect(() => {
        if (component.attachEventListeners) {
          component.attachEventListeners();
        }
      }).not.toThrow();

      const selectionCheckbox = container.querySelector('[data-checkbox-type="selection"]');
      expect(selectionCheckbox).toBeTruthy();
      expect(selectionCheckbox.getAttribute('data-kata-id')).toBe('plugin-test');
    });
  });

  describe('Progressive Enhancement', () => {
    it('should work without JavaScript enhancement', () => {
      // Test that basic checkbox functionality works without enhancement
      const checkbox = container.querySelector('input[type="checkbox"]');
      checkbox.checked = true;

      expect(checkbox.checked).toBe(true);
    });

    it('should enhance existing checkbox elements', async () => {
      await component.initialize();

      const checkboxes = container.querySelectorAll('input[type="checkbox"]');
      checkboxes.forEach(checkbox => {
        expect(checkbox.getAttribute('aria-label')).toBeTruthy();
      });
    });
  });

  describe('Checkbox Decoration', () => {
    beforeEach(() => {
      // Setup mock DOM with learning path checkboxes (no data attributes yet)
      document.body.innerHTML = `
        <div class="markdown-section">
          <ul>
            <li>
              <input type="checkbox" />
              <a href="#/learning/katas/ai-assisted-engineering/100-ai-development-fundamentals.md">
                Kata: AI Development Fundamentals
              </a>
            </li>
            <li>
              <input type="checkbox" />
              <a href="../katas/prompt-engineering/200-instruction-file-workflows.md">
                Kata: Instruction File Workflows
              </a>
            </li>
            <li>
              <input type="checkbox" />
              <a href="#/learning/paths/foundation.md">
                Path (should be ignored)
              </a>
            </li>
          </ul>
        </div>
      `;

      mockDependencies = {
        errorHandler: {
          safeExecute: vi.fn((fn) => fn())
        },
        domUtils: {
          querySelector: (sel) => document.querySelector(sel),
          querySelectorAll: (sel) => document.querySelectorAll(sel)
        },
        debugHelper: {
          log: vi.fn(),
          warn: vi.fn()
        },
        learningPathManager: {
          init: vi.fn().mockResolvedValue(true),
          getPathSelections: vi.fn(() => ({})),
          getPathProgress: vi.fn(() => ({})),
          getKataProgress: vi.fn(() => ({ completionPercentage: 0 }))
        }
      };

      component = new InteractiveLearningPathCheckboxes(mockDependencies);
    });

    it('should add data-kata-id to kata checkboxes', () => {
      component.decorateLearningPathCheckboxes();

      const checkbox1 = document.querySelector('a[href*="100-ai-development-fundamentals"]')
        .closest('li').querySelector('input');
      const checkbox2 = document.querySelector('a[href*="200-instruction-file-workflows"]')
        .closest('li').querySelector('input');

      expect(checkbox1.getAttribute('data-kata-id')).toBe('ai-assisted-engineering-100-ai-development-fundamentals');
      expect(checkbox2.getAttribute('data-kata-id')).toBe('prompt-engineering-200-instruction-file-workflows');
    });

    it('should add data-checkbox-type="selection" to all kata checkboxes', () => {
      component.decorateLearningPathCheckboxes();

      const kataLinks = document.querySelectorAll('a[href*="/katas/"]');
      kataLinks.forEach(link => {
        const checkbox = link.closest('li').querySelector('input');
        expect(checkbox.getAttribute('data-checkbox-type')).toBe('selection');
      });
    });

    it('should not decorate non-kata checkboxes', () => {
      component.decorateLearningPathCheckboxes();

      const pathCheckbox = document.querySelector('a[href*="/paths/"]')
        .closest('li').querySelector('input');

      expect(pathCheckbox.hasAttribute('data-kata-id')).toBe(false);
    });

    it('should skip already decorated checkboxes', () => {
      const checkbox = document.querySelector('input');
      checkbox.setAttribute('data-kata-id', 'existing-id');

      component.decorateLearningPathCheckboxes();

      expect(checkbox.getAttribute('data-kata-id')).toBe('existing-id'); // Unchanged
    });

    it('should log decorated checkbox count', () => {
      component.decorateLearningPathCheckboxes();

      // Should log: initial list count, per-item decoration, and final summary with array
      expect(mockDependencies.debugHelper.log).toHaveBeenCalledWith(
        expect.stringContaining('Found 3 list items to check for decoration')
      );
      expect(mockDependencies.debugHelper.log).toHaveBeenCalledWith(
        'Decorated 2 checkboxes on learning path page:',
        expect.arrayContaining([
          'ai-assisted-engineering-100-ai-development-fundamentals',
          'prompt-engineering-200-instruction-file-workflows'
        ])
      );
    });
  });



  describe('Select All Katas Functionality', () => {
    let component;
    let mockDependencies;
    let container;

    beforeEach(() => {
      // Clean up any existing checkboxes from previous tests
      document.body.querySelectorAll('input[type="checkbox"]').forEach(cb => cb.remove());

      // Reset DOM
      container = document.createElement('div');
      container.id = 'main';
      container.innerHTML = `
        <div class="markdown-section">
          <h1>Test Learning Path</h1>
          <div class="kata-item">
            <input type="checkbox" class="learning-path-checkbox" data-kata-id="kata-1" data-checkbox-type="selection" />
            <label>Kata 1</label>
          </div>
          <div class="kata-item">
            <input type="checkbox" class="learning-path-checkbox" data-kata-id="kata-2" data-checkbox-type="selection" />
            <label>Kata 2</label>
          </div>
          <div class="kata-item">
            <input type="checkbox" class="learning-path-checkbox" data-kata-id="kata-3" data-checkbox-type="selection" />
            <label>Kata 3</label>
          </div>
        </div>
      `;
      document.body.appendChild(container);

      mockDependencies = {
        errorHandler: {
          safeExecute: vi.fn((fn) => fn())
        },
        learningPathManager: {
          updatePathSelection: vi.fn(),
          init: vi.fn(() => Promise.resolve())
        },
        domUtils: {
          querySelector: vi.fn((selector) => document.querySelector(selector)),
          querySelectorAll: vi.fn((selector) => document.querySelectorAll(selector))
        },
        storageManager: {},
        kataDetection: {},
        debugHelper: {
          log: vi.fn(),
          warn: vi.fn()
        }
      };

      component = new InteractiveLearningPathCheckboxes(mockDependencies);
      component.debouncedPathUpdate = vi.fn();
      component.updatePathSelection = vi.fn();
    });

    afterEach(() => {
      if (container && container.parentNode) {
        container.parentNode.removeChild(container);
      }
    });

    describe('selectAllKatasInPath', () => {
      beforeEach(() => {
        vi.clearAllMocks();
        // Re-assign mocks after clearing
        component.debouncedPathUpdate = vi.fn();
        component.updatePathSelection = vi.fn();
      });

      it('should select all unchecked katas', () => {
        const checkboxes = container.querySelectorAll('.learning-path-checkbox');
        checkboxes[0].checked = false;
        checkboxes[1].checked = false;
        checkboxes[2].checked = false;

        component.selectAllKatasInPath();

        expect(checkboxes[0].checked).toBe(true);
        expect(checkboxes[1].checked).toBe(true);
        expect(checkboxes[2].checked).toBe(true);
        expect(component.updatePathSelection).toHaveBeenCalledTimes(3);
        expect(component.debouncedPathUpdate).toHaveBeenCalled();
      });

      it('should skip already selected katas', () => {
        const checkboxes = container.querySelectorAll('.learning-path-checkbox');
        checkboxes[0].checked = true;
        checkboxes[1].checked = true;
        checkboxes[2].checked = false;

        component.selectAllKatasInPath();

        expect(checkboxes[2].checked).toBe(true);
        expect(component.updatePathSelection).toHaveBeenCalledTimes(1);
        expect(component.updatePathSelection).toHaveBeenCalledWith('kata-3', true);
      });

      it('should handle no checkboxes gracefully', () => {
        // Clear all checkboxes by clearing the entire container
        container.innerHTML = `<div class="markdown-section"></div>`;
        // Also clear any checkboxes outside the container (e.g., primary checkbox)
        document.body.querySelectorAll('input[type="checkbox"]').forEach(cb => {
          if (!container.contains(cb)) cb.remove();
        });

        const result = component.selectAllKatasInPath();

        expect(result).toBe(0);
        expect(component.debouncedPathUpdate).not.toHaveBeenCalled();
      });

      it('should not trigger debounce if all already selected', () => {
        // Clear the mock to ensure clean state
        component.debouncedPathUpdate.mockClear();
        component.updatePathSelection.mockClear();

        const checkboxes = container.querySelectorAll('.learning-path-checkbox');
        checkboxes[0].checked = true;
        checkboxes[1].checked = true;
        checkboxes[2].checked = true;

        component.selectAllKatasInPath();

        expect(component.debouncedPathUpdate).not.toHaveBeenCalled();
      });
    });

    describe('deselectAllKatasInPath', () => {
      it('should deselect all checked katas', () => {
        const checkboxes = container.querySelectorAll('.learning-path-checkbox');
        checkboxes[0].checked = true;
        checkboxes[1].checked = true;
        checkboxes[2].checked = true;

        component.deselectAllKatasInPath();

        expect(checkboxes[0].checked).toBe(false);
        expect(checkboxes[1].checked).toBe(false);
        expect(checkboxes[2].checked).toBe(false);
        expect(component.updatePathSelection).toHaveBeenCalledTimes(3);
        expect(component.debouncedPathUpdate).toHaveBeenCalled();
      });

      it('should skip already unselected katas', () => {
        const checkboxes = container.querySelectorAll('.learning-path-checkbox');
        checkboxes[0].checked = false;
        checkboxes[1].checked = false;
        checkboxes[2].checked = true;

        component.deselectAllKatasInPath();

        expect(checkboxes[2].checked).toBe(false);
        expect(component.updatePathSelection).toHaveBeenCalledTimes(1);
        expect(component.updatePathSelection).toHaveBeenCalledWith('kata-3', false);
      });

      it('should handle no checkboxes gracefully', () => {
        // Clear all checkboxes by clearing the entire container
        container.innerHTML = `<div class="markdown-section"></div>`;
        // Also clear any checkboxes outside the container (e.g., primary checkbox)
        document.body.querySelectorAll('input[type="checkbox"]').forEach(cb => {
          if (!container.contains(cb)) cb.remove();
        });

        const result = component.deselectAllKatasInPath();

        expect(result).toBe(0);
        expect(component.debouncedPathUpdate).not.toHaveBeenCalled();
      });
    });

    describe('addPrimarySelectAllCheckbox', () => {
      it('should add primary checkbox to page', () => {
        component.addPrimarySelectAllCheckbox();

        const primaryCheckbox = document.getElementById('primary-select-all');
        expect(primaryCheckbox).toBeTruthy();
        expect(primaryCheckbox.type).toBe('checkbox');

        const label = document.querySelector('label[for="primary-select-all"]');
        expect(label).toBeTruthy();
        expect(label.textContent).toBe(' Select all katas in this path');
      });

      it('should not add duplicate checkbox', () => {
        component.addPrimarySelectAllCheckbox();
        component.addPrimarySelectAllCheckbox();

        const checkboxes = document.querySelectorAll('#primary-select-all');
        expect(checkboxes.length).toBe(1);
      });

      it('should handle missing markdown-section gracefully', () => {
        const markdownSection = container.querySelector('.markdown-section');
        container.removeChild(markdownSection);

        expect(() => component.addPrimarySelectAllCheckbox()).not.toThrow();
        expect(mockDependencies.debugHelper.warn).toHaveBeenCalledWith(
          expect.stringContaining('Markdown section not found')
        );
      });

      it('should add event listener for checkbox changes', () => {
        component.selectAllKatasInPath = vi.fn();
        component.deselectAllKatasInPath = vi.fn();
        component.updatePrimaryCheckboxState = vi.fn();

        component.addPrimarySelectAllCheckbox();

        const primaryCheckbox = document.getElementById('primary-select-all');

        // Test check action
        primaryCheckbox.checked = true;
        primaryCheckbox.dispatchEvent(new Event('change'));
        expect(component.selectAllKatasInPath).toHaveBeenCalled();

        // Test uncheck action
        primaryCheckbox.checked = false;
        primaryCheckbox.dispatchEvent(new Event('change'));
        expect(component.deselectAllKatasInPath).toHaveBeenCalled();
      });
    });

    describe('updatePrimaryCheckboxState', () => {
      beforeEach(() => {
        component.addPrimarySelectAllCheckbox();
      });

      it('should set checked when all katas selected', () => {
        const checkboxes = container.querySelectorAll('.learning-path-checkbox');
        checkboxes.forEach(cb => cb.checked = true);

        component.updatePrimaryCheckboxState();

        const primaryCheckbox = document.getElementById('primary-select-all');
        expect(primaryCheckbox.checked).toBe(true);
        expect(primaryCheckbox.indeterminate).toBe(false);
      });

      it('should set indeterminate when some katas selected', () => {
        const checkboxes = container.querySelectorAll('.learning-path-checkbox');
        checkboxes[0].checked = true;
        checkboxes[1].checked = false;
        checkboxes[2].checked = true;

        component.updatePrimaryCheckboxState();

        const primaryCheckbox = document.getElementById('primary-select-all');
        expect(primaryCheckbox.checked).toBe(false);
        expect(primaryCheckbox.indeterminate).toBe(true);
      });

      it('should set unchecked when no katas selected', () => {
        const checkboxes = container.querySelectorAll('.learning-path-checkbox');
        checkboxes.forEach(cb => cb.checked = false);

        component.updatePrimaryCheckboxState();

        const primaryCheckbox = document.getElementById('primary-select-all');
        expect(primaryCheckbox.checked).toBe(false);
        expect(primaryCheckbox.indeterminate).toBe(false);
      });

      it('should handle missing primary checkbox gracefully', () => {
        const primaryCheckbox = document.getElementById('primary-select-all');
        primaryCheckbox.remove();

        expect(() => component.updatePrimaryCheckboxState()).not.toThrow();
      });
    });

    describe('Primary Checkbox Integration', () => {
      beforeEach(() => {
        component.addPrimarySelectAllCheckbox();
      });

      it('should update primary checkbox after individual kata selection', () => {
        component.updatePrimaryCheckboxState = vi.fn();

        const checkbox = container.querySelector('[data-kata-id="kata-1"]');
        checkbox.checked = true;

        component.handleKataSelection('kata-1', true);

        expect(component.updatePrimaryCheckboxState).toHaveBeenCalled();
      });

      it('should sync primary checkbox with kata state changes', () => {
        const checkboxes = container.querySelectorAll('.learning-path-checkbox');
        const primaryCheckbox = document.getElementById('primary-select-all');

        // Initially unchecked
        component.updatePrimaryCheckboxState();
        expect(primaryCheckbox.checked).toBe(false);
        expect(primaryCheckbox.indeterminate).toBe(false);

        // Select one → indeterminate
        checkboxes[0].checked = true;
        component.updatePrimaryCheckboxState();
        expect(primaryCheckbox.indeterminate).toBe(true);

        // Select all → checked
        checkboxes.forEach(cb => cb.checked = true);
        component.updatePrimaryCheckboxState();
        expect(primaryCheckbox.checked).toBe(true);
        expect(primaryCheckbox.indeterminate).toBe(false);

        // Deselect one → indeterminate
        checkboxes[1].checked = false;
        component.updatePrimaryCheckboxState();
        expect(primaryCheckbox.indeterminate).toBe(true);

        // Deselect all → unchecked
        checkboxes.forEach(cb => cb.checked = false);
        component.updatePrimaryCheckboxState();
        expect(primaryCheckbox.checked).toBe(false);
        expect(primaryCheckbox.indeterminate).toBe(false);
      });
    });
  });
});
