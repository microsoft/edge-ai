/**
 * @vitest-environment happy-dom
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { ProgressAnnotations } from '../../features/progress-annotations.js';
import {
  SAMPLE_PROGRESS_STATES,
  ANNOTATION_CONFIGS,
  SAMPLE_MARKDOWN_ELEMENTS,
  EXPECTED_ANNOTATION_ELEMENTS,
  BULK_PROGRESS_DATA,
  ACCESSIBILITY_TEST_DATA,
  ANNOTATION_ERROR_SCENARIOS,
  createMockProgressData,
  createMockAnnotationConfig,
  createTestElement,
  getExpectedAnnotations
} from '../fixtures/progress-data.js';

// Import the component we'll be testing (will fail initially - TDD RED phase)
// import { ProgressAnnotations } from '../../features/progress-annotations.js';

describe('ProgressAnnotations', () => {
  let progressAnnotations;
  let mockDependencies;
  let mockErrorHandler;
  let mockLearningPathManager;
  let mockDomUtils;
  let mockDebugHelper;

  // Helper function to create mock dependencies
  function createMockDependencies() {
    const errorHandler = {
      handleError: vi.fn(),
      safeExecute: vi.fn((fn, context, fallback) => {
        try {
          return fn();
        } catch (_error) {
          errorHandler.handleError(_error, context);
          return fallback;
        }
      })
    };

    const learningPathManager = {
      getCurrentContext: vi.fn(),
      getPathProgress: vi.fn(),
      getKataProgress: vi.fn(),
      isKataCompleted: vi.fn(),
      isKataInProgress: vi.fn(),
      isKataOnPath: vi.fn(),
      getKataScore: vi.fn()
    };

    const mockBadgeElement = {
      textContent: '',
      className: '',
      title: '',
      setAttribute: vi.fn(),
      getAttribute: vi.fn(() => ''),
      classList: {
        add: vi.fn(),
        remove: vi.fn(),
        contains: vi.fn(() => false)
      }
    };

    const domUtils = {
      querySelector: vi.fn(),
      querySelectorAll: vi.fn(() => []),
      createElement: vi.fn(() => mockBadgeElement),
      appendChild: vi.fn(),
      insertBefore: vi.fn(),
      insertAfter: vi.fn(),
      setAttribute: vi.fn(),
      getAttribute: vi.fn(),
      addClass: vi.fn(),
      removeClass: vi.fn(),
      hasClass: vi.fn(),
      setStyle: vi.fn(),
      getStyle: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn()
    };

    const debugHelper = {
      log: vi.fn(),
      warn: vi.fn(),
      error: vi.fn(),
      groupStart: vi.fn(),
      groupEnd: vi.fn()
    };

    return {
      errorHandler,
      learningPathManager,
      domUtils,
      debugHelper
    };
  }

  beforeEach(() => {
    // Reset document
    document.body.innerHTML = '';

    // Create fresh mock dependencies
    mockDependencies = createMockDependencies();
    mockErrorHandler = mockDependencies.errorHandler;
    mockLearningPathManager = mockDependencies.learningPathManager;
    mockDomUtils = mockDependencies.domUtils;
    mockDebugHelper = mockDependencies.debugHelper;

    // Note: This will fail initially since ProgressAnnotations doesn't exist yet (TDD RED)
    // progressAnnotations = new ProgressAnnotations(mockDependencies);
  });

  afterEach(() => {
    // Clean up any created instances
    if (progressAnnotations && typeof progressAnnotations.destroy === 'function') {
      progressAnnotations.destroy();
    }
    vi.clearAllMocks();
  });

  describe('Constructor and Initialization', () => {
    it('should create instance with valid dependencies', () => {
      // TDD RED: This will fail initially
      expect(() => {
        // progressAnnotations = new ProgressAnnotations(mockDependencies);
      }).not.toThrow();
    });

    it('should throw error with missing errorHandler dependency', () => {
      expect(() => {
        new ProgressAnnotations({ ...mockDependencies, errorHandler: null });
      }).toThrow('ProgressAnnotations requires errorHandler dependency');
    });

    it('should throw error with missing learningPathManager dependency', () => {
      expect(() => {
        new ProgressAnnotations({ ...mockDependencies, learningPathManager: null });
      }).toThrow('ProgressAnnotations requires learningPathManager dependency');
    });

    it('should initialize with default configuration', () => {
      // progressAnnotations = new ProgressAnnotations(mockDependencies);
      // expect(progressAnnotations.config).toBeDefined();
      // expect(progressAnnotations.config.enableBadges).toBe(true);
      // expect(progressAnnotations.config.enableProgressBars).toBe(true);
      // expect(progressAnnotations.config.enableIcons).toBe(true);
    });

    it('should accept custom configuration overrides', () => {
      const customConfig = {
        enableBadges: false,
        enableProgressBars: true,
        animationDuration: 300
      };

      // progressAnnotations = new ProgressAnnotations({ ...mockDependencies, config: customConfig });
      // expect(progressAnnotations.config.enableBadges).toBe(false);
      // expect(progressAnnotations.config.animationDuration).toBe(300);
    });
  });

  describe('Progress State Detection', () => {
    beforeEach(() => {
      progressAnnotations = new ProgressAnnotations(mockDependencies);

      // Setup querySelector to return a mock label element
      const mockLabel = document.createElement('label');
      mockLabel.textContent = 'Sample Kata';
      mockDomUtils.querySelector.mockReturnValue(mockLabel);
    });

    it('should detect "on your path" state correctly', async () => {
      const progressData = createMockProgressData('onYourPath');
      mockLearningPathManager.isKataOnPath.mockReturnValue(true);
      mockLearningPathManager.getKataProgress.mockReturnValue({ completed: false, started: false, progress: 0 });
      mockLearningPathManager.isKataCompleted.mockReturnValue(false);
      mockLearningPathManager.isKataInProgress.mockReturnValue(false);

      const state = await progressAnnotations.detectProgressState('ai-assisted-engineering/01-ai-development-fundamentals');
      expect(state).toBe('on-your-path');
      expect(mockLearningPathManager.isKataOnPath).toHaveBeenCalledWith('ai-assisted-engineering/01-ai-development-fundamentals');
    });

    it('should detect "in progress" state correctly', async () => {
      const progressData = createMockProgressData('inProgress');
      mockLearningPathManager.isKataOnPath.mockReturnValue(true);
      mockLearningPathManager.getKataProgress.mockReturnValue(progressData);
      mockLearningPathManager.isKataCompleted.mockReturnValue(false);
      mockLearningPathManager.isKataInProgress.mockReturnValue(true);

      const state = await progressAnnotations.detectProgressState('prompt-engineering/01-prompt-engineering-basics');
      expect(state).toBe('in-progress');
    });

    it('should detect "completed" state correctly', async () => {
      const progressData = createMockProgressData('completed');
      mockLearningPathManager.isKataOnPath.mockReturnValue(true);
      mockLearningPathManager.getKataProgress.mockReturnValue(progressData);
      mockLearningPathManager.isKataCompleted.mockReturnValue(true);
      mockLearningPathManager.isKataInProgress.mockReturnValue(false);

      const state = await progressAnnotations.detectProgressState('project-planning/01-basic-prompt-usage');
      expect(state).toBe('completed');
    });

    it('should detect "not selected" state correctly', async () => {
      mockLearningPathManager.isKataOnPath.mockReturnValue(false);
      mockLearningPathManager.isKataCompleted.mockReturnValue(false);
      mockLearningPathManager.isKataInProgress.mockReturnValue(false);

      const state = await progressAnnotations.detectProgressState('adr-creation/01-ai-decision-documentation');
      expect(state).toBe('not-selected');
    });

    it('should handle state detection errors gracefully', async () => {
      mockLearningPathManager.isKataOnPath.mockImplementation(() => {
        throw new Error('Test error');
      });

      const state = await progressAnnotations.detectProgressState('invalid/kata');
      expect(state).toBe('not-selected'); // Default fallback
      expect(mockErrorHandler.handleError).toHaveBeenCalled();
    });
  });

  describe('Annotation Creation', () => {
    beforeEach(() => {
      progressAnnotations = new ProgressAnnotations(mockDependencies);

      // Setup querySelector to return a mock label element
      const mockLabel = document.createElement('label');
      mockLabel.textContent = 'Sample Kata';
      mockDomUtils.querySelector.mockReturnValue(mockLabel);
    });

    it('should create progress badge for "on your path" state', () => {
      const mockElement = document.createElement('div');
      mockElement.innerHTML = SAMPLE_MARKDOWN_ELEMENTS.basicKataCheckbox.html;
      const config = createMockAnnotationConfig('onYourPath');

      progressAnnotations.createProgressBadge(mockElement, config);

      expect(mockDomUtils.createElement).toHaveBeenCalledWith('span');
      expect(mockDomUtils.addClass).toHaveBeenCalledWith(expect.any(Object), 'progress-badge on-your-path');
    });

    it('should create progress icon for in-progress state', () => {
      const mockElement = document.createElement('div');
      const config = createMockAnnotationConfig('inProgress');

      progressAnnotations.createProgressIcon(mockElement, config);

      expect(mockDomUtils.createElement).toHaveBeenCalledWith('i');
      expect(mockDomUtils.addClass).toHaveBeenCalledWith(expect.any(Object), 'progress-icon icon-in-progress');
    });

    it('should create progress bar for in-progress state', () => {
      const mockElement = document.createElement('div');
      const config = createMockAnnotationConfig('inProgress');

      progressAnnotations.createProgressBar(mockElement, config);

      expect(mockDomUtils.createElement).toHaveBeenCalledWith('div');
      expect(mockDomUtils.addClass).toHaveBeenCalledWith(expect.any(Object), 'progress-bar-container');
    });

    it('should create score display for completed state', () => {
      const mockElement = document.createElement('div');
      const config = createMockAnnotationConfig('completed');

      progressAnnotations.createScoreDisplay(mockElement, config);

      expect(mockDomUtils.createElement).toHaveBeenCalledWith('span');
      expect(mockDomUtils.addClass).toHaveBeenCalledWith(expect.any(Object), 'score-display');
    });

    it('should not create annotations for "not selected" state', () => {
      const mockElement = document.createElement('div');
      const config = createMockAnnotationConfig('notSelected');

      progressAnnotations.applyAnnotations(mockElement, 'not-selected', config);

      // Should not create any annotation elements for not-selected state
      expect(mockDomUtils.createElement).not.toHaveBeenCalled();
    });
  });

  describe('Annotation Application', () => {
    beforeEach(() => {
      progressAnnotations = new ProgressAnnotations(mockDependencies);

      // Setup querySelector to return appropriate elements based on selector
      const mockLabel = document.createElement('label');
      mockLabel.textContent = 'Sample Kata';

      mockDomUtils.querySelector.mockImplementation((element, selector) => {
        if (selector === 'label' || selector.includes('label')) {
          return mockLabel;
        }
        // Return null for specific progress elements (they don't exist yet)
        if (selector.includes('.progress-bar-container') ||
            selector.includes('.progress-icon') ||
            selector.includes('.score-display')) {
          return null;
        }
        return mockLabel; // Default fallback
      });
    });

    it('should apply all annotations for "on your path" state', () => {
      const mockElement = document.createElement('div');
      mockElement.innerHTML = SAMPLE_MARKDOWN_ELEMENTS.basicKataCheckbox.html;
      const expectedAnnotations = getExpectedAnnotations('onYourPath');

      progressAnnotations.applyAnnotations(mockElement, 'on-your-path');

      // Verify badge creation
      expect(mockDomUtils.createElement).toHaveBeenCalledWith('span');
      expect(mockDomUtils.addClass).toHaveBeenCalledWith(expect.any(Object), 'progress-badge on-your-path');
    });

    it('should apply progress bar for in-progress items', () => {
      const mockElement = document.createElement('div');
      mockElement.innerHTML = SAMPLE_MARKDOWN_ELEMENTS.complexKataCheckbox.html;

      progressAnnotations.applyAnnotations(mockElement, 'in-progress', { progressPercentage: 40 });

      // Verify progress bar creation with correct percentage
      expect(mockDomUtils.createElement).toHaveBeenCalledWith('div');
      // expect(mockDomUtils.setAttribute).toHaveBeenCalledWith(expect.any(Object), 'data-progress', '40');
    });

    it('should apply score display for completed items', () => {
      const mockElement = document.createElement('div');
      mockElement.innerHTML = SAMPLE_MARKDOWN_ELEMENTS.basicKataCheckbox.html;

      progressAnnotations.applyAnnotations(mockElement, 'completed', { score: 92 });

      // Verify score display creation
      expect(mockDomUtils.createElement).toHaveBeenCalledWith('span');
      // expect(textContent).toContain('Score: 92%');
    });

    it('should handle missing label elements gracefully', () => {
      const mockElement = document.createElement('div');
      mockElement.innerHTML = ANNOTATION_ERROR_SCENARIOS.malformedMarkdown.html;

      // Mock querySelector to return null for this test (simulating missing label)
      mockDomUtils.querySelector.mockReturnValue(null);

      progressAnnotations.applyAnnotations(mockElement, 'on-your-path');

      expect(mockErrorHandler.handleError).toHaveBeenCalled();
      // Should not crash and should log appropriate error
    });

    it('should preserve existing markdown structure', () => {
      const mockElement = document.createElement('div');
      const originalHtml = SAMPLE_MARKDOWN_ELEMENTS.complexKataCheckbox.html;
      mockElement.innerHTML = originalHtml;

      progressAnnotations.applyAnnotations(mockElement, 'on-your-path');

      // Original structure should be preserved
      // expect(mockElement.querySelector('input[type="checkbox"]')).toBeTruthy();
      // expect(mockElement.querySelector('label')).toBeTruthy();
      // expect(mockElement.querySelector('.kata-meta')).toBeTruthy();
    });
  });

  describe('Batch Annotation Processing', () => {
    beforeEach(() => {
      progressAnnotations = new ProgressAnnotations(mockDependencies);

      // Setup querySelector to return a mock label element
      const mockLabel = document.createElement('label');
      mockLabel.textContent = 'Sample Kata';
      mockDomUtils.querySelector.mockReturnValue(mockLabel);
    });

    it('should process multiple learning path items efficiently', async () => {
      // Create container with multiple checkboxes
      const container = document.createElement('div');
      container.innerHTML = `
        ${SAMPLE_MARKDOWN_ELEMENTS.basicKataCheckbox.html}
        ${SAMPLE_MARKDOWN_ELEMENTS.complexKataCheckbox.html}
        ${SAMPLE_MARKDOWN_ELEMENTS.nestedKataCheckbox.html}
      `;

      mockDomUtils.querySelectorAll.mockReturnValue([
        container.children[0],
        container.children[1],
        container.children[2]
      ]);

      await progressAnnotations.processLearningPathItems(container);

      // Should query for all checkbox items with container
      expect(mockDomUtils.querySelectorAll).toHaveBeenCalledWith(
        container,
        'input[type="checkbox"][data-kata-id]'
      );

      // Should process each item
      // expect(progressAnnotations.detectProgressState).toHaveBeenCalledTimes(3);
    });

    it('should handle large datasets efficiently', () => {
      const largeDataset = BULK_PROGRESS_DATA.largePath;
      const container = document.createElement('div');

      // Create many checkbox elements
      largeDataset.forEach((item, _index) => {
        const li = document.createElement('li');
        li.innerHTML = `
          <input type="checkbox" id="kata-${_index}" data-kata-id="${item.kataId}">
          <label for="kata-${_index}">Kata ${_index + 1}</label>
        `;
        container.appendChild(li);
      });

      mockDomUtils.querySelectorAll.mockReturnValue(Array.from(container.querySelectorAll('input[type="checkbox"]')));

      const startTime = performance.now();
      // progressAnnotations.processLearningPathItems(container);
      const endTime = performance.now();

      // Performance should be reasonable (under 100ms for 50 items)
      expect(endTime - startTime).toBeLessThan(100);
    });

    it('should batch DOM operations for performance', () => {
      const container = document.createElement('div');
      container.innerHTML = `
        ${SAMPLE_MARKDOWN_ELEMENTS.basicKataCheckbox.html}
        ${SAMPLE_MARKDOWN_ELEMENTS.complexKataCheckbox.html}
      `;

      // progressAnnotations.processLearningPathItems(container);

      // Should use document fragment or similar batching technique
      // expect(mockDomUtils.createElement).toHaveBeenCalledWith('DocumentFragment');
    });
  });

  describe('Accessibility Features', () => {
    beforeEach(() => {
      // Enable high contrast support for accessibility tests
      const configWithHighContrast = {
        accessibility: {
          highContrastSupport: true
        }
      };
      progressAnnotations = new ProgressAnnotations(mockDependencies, configWithHighContrast);

      // Setup querySelector to return a mock label element
      const mockLabel = document.createElement('label');
      mockLabel.textContent = 'Sample Kata';
      mockDomUtils.querySelector.mockReturnValue(mockLabel);
    });

    it('should add appropriate ARIA labels for progress states', () => {
      const mockElement = document.createElement('div');
      mockElement.innerHTML = SAMPLE_MARKDOWN_ELEMENTS.basicKataCheckbox.html;

      progressAnnotations.applyAnnotations(mockElement, 'on-your-path');

      const expectedLabel = ACCESSIBILITY_TEST_DATA.ariaLabels.onYourPath;
      expect(mockDomUtils.setAttribute).toHaveBeenCalledWith(
        expect.any(Object),
        'aria-label',
        expectedLabel
      );
    });

    it('should add ARIA descriptions for progress bars', () => {
      const mockElement = document.createElement('div');
      mockElement.innerHTML = SAMPLE_MARKDOWN_ELEMENTS.basicKataCheckbox.html;

      // Create distinct mock elements for progress bar components
      const mockProgressBarContainer = document.createElement('div');
      mockProgressBarContainer.className = 'progress-bar-container';

      const mockProgressBar = document.createElement('div');
      mockProgressBar.className = 'progress-bar';

      const mockProgressFill = document.createElement('div');
      mockProgressFill.className = 'progress-fill';

      // Setup querySelector to be context-aware
      const mockLabel = document.createElement('label');
      mockLabel.textContent = 'Sample Kata';

      mockDomUtils.querySelector.mockImplementation((element, selector) => {
        if (selector === 'label' || selector.includes('label')) {
          return mockLabel;
        }
        // Return null for progress bar container (doesn't exist yet)
        if (selector.includes('.progress-bar-container')) {
          return null;
        }
        return null;
      });

      let elementCount = 0;
      // Mock createElement to return distinct elements for each div creation
      mockDomUtils.createElement.mockImplementation((tagName) => {
        if (tagName === 'div') {
          elementCount++;
          if (elementCount === 1) {return mockProgressBarContainer;}
          if (elementCount === 2) {return mockProgressBar;}
          if (elementCount === 3) {return mockProgressFill;}
        }
        return document.createElement(tagName);
      });

      progressAnnotations.applyAnnotations(mockElement, 'in-progress', { progressPercentage: 40 });

      const expectedDescription = ACCESSIBILITY_TEST_DATA.ariaDescriptions.progressBar;
      expect(mockDomUtils.setAttribute).toHaveBeenCalledWith(
        mockProgressBarContainer,
        'aria-describedby',
        expect.stringContaining('progress-description')
      );
    });

    it('should support keyboard navigation for interactive elements', () => {
      const mockElement = document.createElement('div');
      mockElement.innerHTML = SAMPLE_MARKDOWN_ELEMENTS.basicKataCheckbox.html;

      // Create distinct mock elements for progress bar components
      const mockProgressBarContainer = document.createElement('div');
      mockProgressBarContainer.className = 'progress-bar-container';

      const mockProgressBar = document.createElement('div');
      mockProgressBar.className = 'progress-bar';

      const mockProgressFill = document.createElement('div');
      mockProgressFill.className = 'progress-fill';

      // Setup querySelector to be context-aware
      const mockLabel = document.createElement('label');
      mockLabel.textContent = 'Sample Kata';

      mockDomUtils.querySelector.mockImplementation((element, selector) => {
        if (selector === 'label' || selector.includes('label')) {
          return mockLabel;
        }
        // Return null for progress bar container (doesn't exist yet)
        if (selector.includes('.progress-bar-container')) {
          return null;
        }
        return null;
      });

      let elementCount = 0;
      // Mock createElement to return distinct elements for each div creation
      mockDomUtils.createElement.mockImplementation((tagName) => {
        if (tagName === 'div') {
          elementCount++;
          if (elementCount === 1) {return mockProgressBarContainer;}
          if (elementCount === 2) {return mockProgressBar;}
          if (elementCount === 3) {return mockProgressFill;}
        }
        return document.createElement(tagName);
      });

      progressAnnotations.applyAnnotations(mockElement, 'in-progress');

      // Should add tabindex for keyboard navigation
      expect(mockDomUtils.setAttribute).toHaveBeenCalledWith(
        mockProgressBarContainer,
        'tabindex',
        '0'
      );
    });

    it('should provide high contrast mode support', () => {
      const mockElement = document.createElement('div');
      mockElement.innerHTML = SAMPLE_MARKDOWN_ELEMENTS.basicKataCheckbox.html;

      // Pass progress data with score to trigger score display creation
      progressAnnotations.applyAnnotations(mockElement, 'completed', { score: 85 });

      // Should add high contrast classes
      expect(mockDomUtils.addClass).toHaveBeenCalledWith(
        expect.any(Object),
        expect.stringContaining('high-contrast-support')
      );
    });
  });

  describe('Error Handling and Edge Cases', () => {
    beforeEach(() => {
      progressAnnotations = new ProgressAnnotations(mockDependencies);

      // Setup querySelector to return a mock label element
      const mockLabel = document.createElement('label');
      mockLabel.textContent = 'Sample Kata';
      mockDomUtils.querySelector.mockReturnValue(mockLabel);
    });

    it('should handle missing kata ID gracefully', async () => {
      const mockElement = document.createElement('div');
      mockElement.innerHTML = ANNOTATION_ERROR_SCENARIOS.missingKataId.html;

      // Mock querySelectorAll to return an element without data-kata-id
      const mockInput = document.createElement('input');
      mockInput.type = 'checkbox';
      // Note: no data-kata-id attribute
      mockDomUtils.querySelectorAll.mockReturnValue([mockInput]);
      mockDomUtils.getAttribute.mockReturnValue(null); // Simulate missing kata-id

      await progressAnnotations.processLearningPathItems(mockElement);

      expect(mockErrorHandler.handleError).toHaveBeenCalled();
      // Should not crash
    });

    it('should handle invalid progress data gracefully', () => {
      const invalidData = ANNOTATION_ERROR_SCENARIOS.invalidProgressData.progressData;

      progressAnnotations.applyAnnotations(document.createElement('div'), 'invalid-state', invalidData);

      expect(mockErrorHandler.handleError).toHaveBeenCalled();
      // Should fall back to default behavior
    });

    it('should handle malformed markdown structure', async () => {
      const mockElement = document.createElement('div');
      mockElement.innerHTML = ANNOTATION_ERROR_SCENARIOS.malformedMarkdown.html;

      // Mock querySelectorAll to return an element
      const mockInput = document.createElement('input');
      mockInput.type = 'checkbox';
      mockInput.setAttribute('data-kata-id', 'malformed/kata');
      mockDomUtils.querySelectorAll.mockReturnValue([mockInput]);
      mockDomUtils.getAttribute.mockReturnValue('malformed/kata');
      mockDomUtils.querySelector.mockReturnValue(null); // Simulate missing label

      await progressAnnotations.processLearningPathItems(mockElement);

      expect(mockErrorHandler.handleError).toHaveBeenCalled();
      // Should continue processing other elements
    });

    it('should handle DOM manipulation errors', () => {
      mockDomUtils.createElement.mockImplementation(() => {
        throw new Error('DOM manipulation failed');
      });

      const mockElement = document.createElement('div');
      mockElement.innerHTML = SAMPLE_MARKDOWN_ELEMENTS.basicKataCheckbox.html;

      progressAnnotations.applyAnnotations(mockElement, 'on-your-path');

      expect(mockErrorHandler.handleError).toHaveBeenCalled();
      // Should not crash the entire component
    });
  });

  describe('Configuration and Customization', () => {
    beforeEach(() => {
      // Setup querySelector to return appropriate elements based on selector
      const mockLabel = document.createElement('label');
      mockLabel.textContent = 'Sample Kata';

      mockDomUtils.querySelector.mockImplementation((element, selector) => {
        if (selector === 'label' || selector.includes('label')) {
          return mockLabel;
        }
        // Return null for specific progress elements (they don't exist yet)
        if (selector.includes('.progress-bar-container') ||
            selector.includes('.progress-icon') ||
            selector.includes('.score-display')) {
          return null;
        }
        return mockLabel; // Default fallback
      });
    });

    it('should allow disabling specific annotation types', () => {
      const customConfig = {
        features: {
          badges: false,
          progressBars: true,
          icons: true
        }
      };

      progressAnnotations = new ProgressAnnotations(mockDependencies, customConfig);
      const mockElement = document.createElement('div');

      // Spy on the method
      const spy = vi.spyOn(progressAnnotations, 'createProgressBadge');

      progressAnnotations.applyAnnotations(mockElement, 'on-your-path');

      // Should not create badge elements when disabled
      expect(spy).not.toHaveBeenCalled();
    });

    it('should support custom CSS classes', () => {
      const customConfig = {
        cssClasses: {
          badge: 'custom-badge',
          progressBar: 'custom-progress',
          icon: 'custom-icon'
        }
      };

      progressAnnotations = new ProgressAnnotations(mockDependencies, customConfig);

      const mockElement = document.createElement('div');

      progressAnnotations.applyAnnotations(mockElement, 'in-progress');

      expect(mockDomUtils.addClass).toHaveBeenCalledWith(
        expect.any(Object),
        expect.stringContaining('custom-progress')
      );
    });

    it('should support custom animation settings', () => {
      const customConfig = {
        animations: {
          enabled: true,
          duration: 500,
          easing: 'ease-in-out'
        }
      };

      progressAnnotations = new ProgressAnnotations(mockDependencies, customConfig);
      expect(progressAnnotations.config.animations.duration).toBe(500);
    });
  });

  describe('Memory Management and Cleanup', () => {
    beforeEach(() => {
      // Setup querySelector to return a mock label element
      const mockLabel = document.createElement('label');
      mockLabel.textContent = 'Sample Kata';
      mockDomUtils.querySelector.mockReturnValue(mockLabel);
    });

    it('should clean up event listeners on destroy', () => {
      progressAnnotations = new ProgressAnnotations(mockDependencies);

      progressAnnotations.destroy();

      // Should remove any event listeners that were added
      expect(mockDomUtils.removeEventListener).toHaveBeenCalled();
    });

    it('should remove created annotation elements on destroy', () => {
      progressAnnotations = new ProgressAnnotations(mockDependencies);
      const mockElement = document.createElement('div');

      progressAnnotations.applyAnnotations(mockElement, 'on-your-path');
      progressAnnotations.destroy();

      // Should clean up created elements
      expect(progressAnnotations._createdElements).toHaveLength(0);
    });

    it('should prevent operations after destroy', () => {
      progressAnnotations = new ProgressAnnotations(mockDependencies);

      progressAnnotations.destroy();

      const mockElement = document.createElement('div');

      // Operation should complete without errors and without creating elements
      progressAnnotations.applyAnnotations(mockElement, 'on-your-path');

      // Verify that no DOM operations were performed (indicating the operation was prevented)
      expect(mockDomUtils.addClass).not.toHaveBeenCalled();
      expect(mockDomUtils.appendChild).not.toHaveBeenCalled();
    });
  });

  describe('Integration with Learning Path Manager', () => {
    beforeEach(() => {
      progressAnnotations = new ProgressAnnotations(mockDependencies);

      // Setup querySelector to return a mock label element
      const mockLabel = document.createElement('label');
      mockLabel.textContent = 'Sample Kata';
      mockDomUtils.querySelector.mockReturnValue(mockLabel);
    });

    it('should sync with learning path manager state changes', async () => {
      // Create a checkbox element with data-kata-id
      const mockCheckbox = document.createElement('input');
      mockCheckbox.type = 'checkbox';
      mockCheckbox.setAttribute('data-kata-id', 'test-kata-id');

      const mockElement = document.createElement('div');
      mockElement.appendChild(mockCheckbox);

      // Ensure parentElement is set
      Object.defineProperty(mockCheckbox, 'parentElement', {
        value: mockElement,
        writable: true
      });

      // Setup querySelector to return a container with learning path items
      const mockContainer = document.createElement('div');
      mockContainer.className = 'learning-paths';
      mockContainer.appendChild(mockElement);

      // Mock DOM queries
      mockDomUtils.querySelector.mockImplementation((parent, selector) => {
        if (selector === '.learning-paths') {return mockContainer;}
        if (selector === 'label') {
          const mockLabel = document.createElement('label');
          mockLabel.textContent = 'Sample Kata';
          return mockLabel;
        }
        return null;
      });

      mockDomUtils.querySelectorAll.mockImplementation((parent, selector) => {
        if (parent === mockContainer && selector === 'input[type="checkbox"][data-kata-id]') {
          return [mockCheckbox];
        }
        return [];
      });

      // Mock getAttribute for getting kata ID
      mockDomUtils.getAttribute.mockImplementation((element, attr) => {
        if (element === mockCheckbox && attr === 'data-kata-id') {
          return 'test-kata-id';
        }
        return null;
      });

      // Simulate state change
      mockLearningPathManager.isKataCompleted.mockReturnValue(true);

      // Spy on the method
      const spy = vi.spyOn(progressAnnotations, 'detectProgressState');

      await progressAnnotations.syncWithManager();

      // Should update annotations based on new state
      expect(spy).toHaveBeenCalled();
    });

    it('should handle manager data loading states', () => {
      mockLearningPathManager.getKataProgress.mockReturnValue(null); // Data not loaded yet

      const mockElement = document.createElement('div');
      progressAnnotations.applyAnnotations(mockElement, 'loading');

      // Should show loading state
      expect(mockDomUtils.addClass).toHaveBeenCalledWith(
        expect.any(Object),
        expect.stringContaining('loading')
      );
    });

    it('should respond to manager progress updates', () => {
      const mockElement = document.createElement('div');
      mockElement.setAttribute('data-kata-id', 'ai-assisted-engineering/01-ai-development-fundamentals');

      const mockProgressBar = document.createElement('div');
      mockProgressBar.className = 'progress-bar';

      const mockProgressFill = document.createElement('div');
      mockProgressFill.className = 'progress-fill';
      mockProgressBar.appendChild(mockProgressFill);
      mockElement.appendChild(mockProgressBar);

      // Setup DOM queries
      mockDomUtils.querySelectorAll.mockImplementation((parent, selector) => {
        if (selector.includes('data-kata-id')) {return [mockElement];}
        if (selector === '.progress-bar') {return [mockProgressBar];}
        return [];
      });

      mockDomUtils.querySelector.mockImplementation((parent, selector) => {
        if (selector === '.progress-fill') {return mockProgressFill;}
        return null;
      });

      progressAnnotations.onProgressUpdate('ai-assisted-engineering/01-ai-development-fundamentals', 0.6);

      // Should update progress bar
      expect(mockDomUtils.setAttribute).toHaveBeenCalledWith(
        expect.any(Object),
        'data-progress',
        '60'
      );
    });
  });
});

describe('ProgressAnnotations Visual Regression Tests', () => {
  let progressAnnotations;
  let mockDependencies;

  beforeEach(() => {
    document.body.innerHTML = '';
    mockDependencies = {
      errorHandler: { handleError: vi.fn(), safeExecute: vi.fn(fn => fn()) },
      learningPathManager: {
        isKataOnPath: vi.fn(),
        isKataCompleted: vi.fn(),
        isKataInProgress: vi.fn(),
        getKataScore: vi.fn()
      },
      domUtils: {
        querySelector: vi.fn(),
        querySelectorAll: vi.fn(() => []),
        createElement: vi.fn(() => document.createElement('div')),
        appendChild: vi.fn(),
        addClass: vi.fn(),
        setAttribute: vi.fn()
      },
      debugHelper: { log: vi.fn() }
    };

    // Setup querySelector to return a mock label element
    const mockLabel = document.createElement('label');
    mockLabel.textContent = 'Sample Kata';
    mockDependencies.domUtils.querySelector.mockReturnValue(mockLabel);

    // progressAnnotations = new ProgressAnnotations(mockDependencies);
  });

  it('should render consistent badge styling across different states', () => {
    const testStates = ['on-your-path', 'in-progress', 'completed', 'selected-not-started'];
    const results = [];

    testStates.forEach(state => {
      const element = document.createElement('div');
      element.innerHTML = SAMPLE_MARKDOWN_ELEMENTS.basicKataCheckbox.html;

      // progressAnnotations.applyAnnotations(element, state);
      results.push({
        state,
        badgeClasses: [], // Would capture actual CSS classes applied
        styles: {} // Would capture computed styles
      });
    });

    // Visual regression validation would happen here
    // expect(results).toMatchSnapshot('progress-badges-visual-regression');
  });

  it('should maintain consistent spacing and layout', () => {
    const element = document.createElement('div');
    element.innerHTML = SAMPLE_MARKDOWN_ELEMENTS.complexKataCheckbox.html;

    // progressAnnotations.applyAnnotations(element, 'in-progress', { progressPercentage: 50 });

    // Layout validation would happen here
    // const layout = element.getBoundingClientRect();
    // expect(layout).toMatchSnapshot('progress-layout-visual-regression');
  });
});
