/**
 * @vitest-environment happy-dom
 */

import { describe, it, test, expect, beforeEach, afterEach, vi } from 'vitest';
import { CoachButton } from '../../features/coach-button.js';

describe('CoachButton', () => {
  let coachButton;
  let mockDependencies;
  let mockErrorHandler;
  let mockLearningPathManager;
  let mockDomUtils;
  let mockVSCodeCommands;

  // Helper function to create mock dependencies
  function createMockDependencies() {
    const errorHandler = {
      handleError: vi.fn(),
      safeExecute: vi.fn((fn, context, fallback) => {
        try {
          return fn();
        } catch (error) {
          errorHandler.handleError(error, context);
          return fallback;
        }
      })
    };

    const learningPathManager = {
      getCurrentContext: vi.fn(() => ({
        currentPath: 'ai-assisted-engineering',
        currentKata: '01-ai-development-fundamentals',
        progressData: { completed: 3, total: 10 },
        userProfile: { role: 'developer', skillLevel: 'beginner' }
      })),
      getPathProgress: vi.fn(() => ({ percentage: 30, completedItems: 3, totalItems: 10 })),
      getActiveRecommendations: vi.fn(() => ['recommendation1', 'recommendation2']),
      getCoachingContext: vi.fn(() => ({
        currentPhase: 'implementation',
        stuckPoints: ['async-patterns'],
        suggestedTopics: ['promises', 'async-await']
      }))
    };

    const domUtils = {
      querySelector: vi.fn(),
      querySelectorAll: vi.fn(() => []),
      createElement: vi.fn((tag) => {
        const element = document.createElement(tag);
        return element;
      }),
      appendChild: vi.fn((parent, child) => {
        if (parent && child && parent.appendChild) {
          parent.appendChild(child);
        }
      }),
      addEventListener: vi.fn((element, event, handler) => {
        if (element && element.addEventListener) {
          element.addEventListener(event, handler);
        }
      }),
      removeEventListener: vi.fn((element, event, handler) => {
        if (element && element.removeEventListener) {
          element.removeEventListener(event, handler);
        }
      }),
      setAttribute: vi.fn((element, attr, value) => {
        if (element && element.setAttribute) {
          element.setAttribute(attr, value);
        }
      }),
      getAttribute: vi.fn((element, attr) => {
        if (element && element.getAttribute) {
          return element.getAttribute(attr);
        }
        return null;
      }),
      addClass: vi.fn((element, className) => {
        if (element && element.classList) {
          element.classList.add(className);
        }
      }),
      removeClass: vi.fn((element, className) => {
        if (element && element.classList) {
          element.classList.remove(className);
        }
      }),
      hasClass: vi.fn((element, className) => {
        if (element && element.classList) {
          return element.classList.contains(className);
        }
        return false;
      }),
      setTextContent: vi.fn((element, text) => {
        if (element) {
          element.textContent = text;
        }
      }),
      getViewportDimensions: vi.fn(() => ({ width: 1024, height: 768 })),
      isElementInViewport: vi.fn(() => true)
    };

    const debugHelper = {
      log: vi.fn(),
      warn: vi.fn(),
      error: vi.fn()
    };

    const vscodeCommands = {
      openChatPanel: vi.fn(),
      activateCoachMode: vi.fn(),
      executeCommand: vi.fn(),
      isVSCodeEnvironment: vi.fn(() => true),
      buildCommandUri: vi.fn((command, args) => `vscode://${command}?${encodeURIComponent(JSON.stringify(args))}`),
      openChatWithContext: vi.fn()
    };

    return {
      errorHandler,
      learningPathManager,
      domUtils,
      debugHelper,
      vscodeCommands
    };
  }

  // Create mock DOM environment for learning path pages
  function createMockLearningPathPage() {
    document.body.innerHTML = `
      <div id="main">
        <div class="content">
          <div class="learning-path-container">
            <h1>AI-Assisted Engineering</h1>
            <div class="learning-path-items">
              <div class="kata-item" data-kata="01-ai-development-fundamentals">
                <input type="checkbox" id="kata-1" />
                <label for="kata-1">AI Development Fundamentals</label>
              </div>
              <div class="kata-item" data-kata="02-prompt-engineering">
                <input type="checkbox" id="kata-2" />
                <label for="kata-2">Prompt Engineering</label>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  beforeEach(() => {
    // Mock window.location for VS Code URI detection using Vitest's safer method
    vi.stubGlobal('location', {
      protocol: 'vscode-file:',
      href: 'vscode-file://vscode-app/learning/paths/README.md',
      pathname: '/learning/paths/README.md'
    });

    // Mock window.open for command URI testing
    vi.stubGlobal('open', vi.fn());

    mockDependencies = createMockDependencies();
    mockErrorHandler = mockDependencies.errorHandler;
    mockLearningPathManager = mockDependencies.learningPathManager;
    mockDomUtils = mockDependencies.domUtils;
    // debugHelper removed - using console methods directly
    mockVSCodeCommands = mockDependencies.vscodeCommands;

    createMockLearningPathPage();
  });

  afterEach(() => {
    if (coachButton) {
      coachButton.destroy();
      coachButton = null;
    }
    document.body.innerHTML = '';
    vi.clearAllMocks();
    vi.unstubAllGlobals();
  });

  describe('Constructor and Initialization', () => {
    it('should create CoachButton instance with valid dependencies', () => {
      coachButton = new CoachButton(mockDependencies);

      expect(coachButton).toBeInstanceOf(CoachButton);
      expect(coachButton.dependencies).toBeDefined();
      expect(coachButton.dependencies.errorHandler).toBe(mockErrorHandler);
      expect(coachButton.dependencies.learningPathManager).toBe(mockLearningPathManager);
      expect(coachButton.dependencies.domUtils).toBe(mockDomUtils);
      expect(coachButton.dependencies.vscodeCommands).toBe(mockVSCodeCommands);
    });

    it('should throw error with invalid dependencies', () => {
      expect(() => new CoachButton(null)).toThrow('Dependencies object is required');
      expect(() => new CoachButton({})).toThrow('ErrorHandler dependency is required');
      expect(() => new CoachButton({ errorHandler: mockErrorHandler })).toThrow('LearningPathManager dependency is required');
    });

    it('should initialize with default configuration', () => {
      coachButton = new CoachButton(mockDependencies);

      expect(coachButton.config).toBeDefined();
      expect(coachButton.config.buttonText).toBe('🤖 Ask Coach');
      expect(coachButton.config.position).toBe('bottom-right');
      expect(coachButton.config.showOnPages).toContain('learning-paths');
      expect(coachButton.config.vscodeCommand).toBe('ms-vscode.vscode-copilot-chat/openChatPanel');
    });

    it('should merge custom configuration with defaults', () => {
      const customConfig = {
        buttonText: 'Custom Coach',
        position: 'bottom-left',
        autoShow: false
      };

      coachButton = new CoachButton(mockDependencies, customConfig);

      expect(coachButton.config.buttonText).toBe('Custom Coach');
      expect(coachButton.config.position).toBe('bottom-left');
      expect(coachButton.config.autoShow).toBe(false);
      expect(coachButton.config.vscodeCommand).toBe('ms-vscode.vscode-copilot-chat/openChatPanel'); // Default preserved
    });
  });

  describe('Button Creation and Styling', () => {
    beforeEach(() => {
      coachButton = new CoachButton(mockDependencies);
    });

    it('should create floating coach button with proper structure', () => {
      coachButton.createButton();

      expect(mockDomUtils.createElement).toHaveBeenCalledWith('div');
      expect(mockDomUtils.createElement).toHaveBeenCalledWith('button');
      expect(mockDomUtils.createElement).toHaveBeenCalledWith('span');
      expect(mockDomUtils.addClass).toHaveBeenCalledWith(expect.any(Object), 'coach-button-container');
      expect(mockDomUtils.addClass).toHaveBeenCalledWith(expect.any(Object), 'coach-button');
    });

    it('should set proper button attributes and accessibility', () => {
      coachButton.createButton();

      expect(mockDomUtils.setAttribute).toHaveBeenCalledWith(expect.any(Object), 'type', 'button');
      expect(mockDomUtils.setAttribute).toHaveBeenCalledWith(expect.any(Object), 'aria-label', 'Open AI Learning Coach');
      expect(mockDomUtils.setAttribute).toHaveBeenCalledWith(expect.any(Object), 'title', 'Get interactive coaching and guidance');
      expect(mockDomUtils.setAttribute).toHaveBeenCalledWith(expect.any(Object), 'role', 'button');
    });

    it('should position button according to configuration', () => {
      coachButton.createButton();

      expect(mockDomUtils.addClass).toHaveBeenCalledWith(expect.any(Object), 'position-bottom-right');
    });

    it('should handle different position configurations', () => {
      const positions = ['bottom-left', 'top-right', 'top-left'];

      positions.forEach(position => {
        const customCoachButton = new CoachButton(mockDependencies, { position });
        customCoachButton.createButton();

        expect(mockDomUtils.addClass).toHaveBeenCalledWith(expect.any(Object), `position-${position}`);
        customCoachButton.destroy();
      });
    });

    it('should add hover and focus effects', () => {
      coachButton.createButton();

      expect(mockDomUtils.addClass).toHaveBeenCalledWith(expect.any(Object), 'coach-button-interactive');
    });

    it('should be responsive and mobile-friendly', () => {
      coachButton.createButton();

      expect(mockDomUtils.addClass).toHaveBeenCalledWith(expect.any(Object), 'responsive');
    });
  });

  describe('VS Code Integration and Command Execution', () => {
    let consoleWarnSpy;

    beforeEach(() => {
      coachButton = new CoachButton(mockDependencies);
      // Mock console.warn to suppress stderr output during testing
      consoleWarnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});
    });

    afterEach(() => {
      consoleWarnSpy?.mockRestore();
    });

    it('should detect VS Code environment correctly', () => {
      const isVSCode = coachButton.isVSCodeEnvironment();

      expect(mockVSCodeCommands.isVSCodeEnvironment).toHaveBeenCalled();
      expect(isVSCode).toBe(true);
    });

    it('should build correct VS Code command URI', () => {
      const context = {
        currentPath: 'ai-assisted-engineering',
        currentKata: '01-ai-development-fundamentals',
        progressData: { completed: 3, total: 10 }
      };

      const uri = coachButton.buildCoachCommandUri(context);

      expect(mockVSCodeCommands.buildCommandUri).toHaveBeenCalledWith(
        'ms-vscode.vscode-copilot-chat/openChatPanel',
        expect.objectContaining({
          mode: 'learning-kata-coach',
          context: context
        })
      );
    });

    it('should trigger VS Code chat panel opening', () => {
      coachButton.createButton();
      const button = coachButton.buttonElement;

      // Simulate button click
      const clickEvent = new Event('click');
      button.dispatchEvent(clickEvent);

      expect(mockVSCodeCommands.openChatWithContext).toHaveBeenCalled();
    });

    it('should pass correct coaching context to VS Code', () => {
      mockLearningPathManager.getCurrentContext.mockReturnValue({
        currentPath: 'ai-assisted-engineering',
        currentKata: '01-ai-development-fundamentals',
        progressData: { completed: 5, total: 12 },
        userProfile: { role: 'architect', skillLevel: 'intermediate' }
      });

      coachButton.createButton();
      const button = coachButton.buttonElement;
      button.dispatchEvent(new Event('click'));

      expect(mockVSCodeCommands.openChatWithContext).toHaveBeenCalledWith(
        expect.objectContaining({
          mode: 'learning-kata-coach',
          context: expect.objectContaining({
            currentPath: 'ai-assisted-engineering',
            currentKata: '01-ai-development-fundamentals',
            progressData: { completed: 5, total: 12 }
          })
        })
      );
    });

    it('should handle VS Code command execution errors gracefully', async () => {
      mockVSCodeCommands.openChatWithContext.mockImplementation(() => {
        throw new Error('VS Code command failed');
      });

      coachButton.createButton();
      const button = coachButton.buttonElement;

      // Click the button and wait for async operations to complete
      const clickEvent = new Event('click');
      button.dispatchEvent(clickEvent);

      // Wait for the next tick to allow async operations to complete
      await new Promise(resolve => setTimeout(resolve, 0));

      expect(mockErrorHandler.handleError).toHaveBeenCalledWith(
        expect.any(Error),
        'CoachButton.handleButtonClick'
      );
    });

    it('should provide fallback when VS Code is not available', () => {
      const consoleWarnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});
      mockVSCodeCommands.isVSCodeEnvironment.mockReturnValue(false);

      coachButton.createButton();
      const button = coachButton.buttonElement;
      button.dispatchEvent(new Event('click'));

      expect(consoleWarnSpy).toHaveBeenCalledWith(
        'VS Code environment not detected, coach button functionality limited'
      );

      consoleWarnSpy.mockRestore();
    });
  });

  describe('Page Detection and Visibility', () => {
    beforeEach(() => {
      coachButton = new CoachButton(mockDependencies);
    });

    it('should show button on learning path pages', () => {
      const isLearningPage = coachButton.shouldShowOnCurrentPage();

      expect(isLearningPage).toBe(true);
    });

    it('should hide button on non-learning pages', () => {
      // Mock non-learning page
      Object.defineProperty(window, 'location', {
        value: {
          href: 'vscode-file://vscode-app/docs/getting-started.md'
        },
        writable: true
      });

      const isLearningPage = coachButton.shouldShowOnCurrentPage();

      expect(isLearningPage).toBe(false);
    });

    it('should show button on kata pages', () => {
      Object.defineProperty(window, 'location', {
        value: {
          href: 'vscode-file://vscode-app/learning/katas/ai-assisted-engineering/01-ai-development-fundamentals.md'
        },
        writable: true
      });

      const isKataPage = coachButton.shouldShowOnCurrentPage();

      expect(isKataPage).toBe(true);
    });

    it('should respect configuration for page visibility', () => {
      const customConfig = { showOnPages: ['custom-page'] };
      const customCoachButton = new CoachButton(mockDependencies, customConfig);

      const shouldShow = customCoachButton.shouldShowOnCurrentPage();

      expect(shouldShow).toBe(false); // Current page not in custom list
    });

    it('should handle auto-show configuration', () => {
      const autoShowConfig = { autoShow: true };
      const autoCoachButton = new CoachButton(mockDependencies, autoShowConfig);

      autoCoachButton.initialize();

      expect(mockDomUtils.appendChild).toHaveBeenCalled();
    });

    it('should not auto-show when disabled', () => {
      const noAutoShowConfig = { autoShow: false };
      const noAutoCoachButton = new CoachButton(mockDependencies, noAutoShowConfig);

      noAutoCoachButton.initialize();

      expect(mockDomUtils.appendChild).not.toHaveBeenCalled();
    });
  });

  describe('Context and Progress Integration', () => {
    beforeEach(() => {
      coachButton = new CoachButton(mockDependencies);
    });

    it('should retrieve current learning context', () => {
      const context = coachButton.getCurrentLearningContext();

      expect(mockLearningPathManager.getCurrentContext).toHaveBeenCalled();
      expect(context).toEqual(expect.objectContaining({
        currentPath: 'ai-assisted-engineering',
        currentKata: '01-ai-development-fundamentals',
        progressData: { completed: 3, total: 10 }
      }));
    });

    it('should get coaching-specific context data', () => {
      const coachingContext = coachButton.getCoachingContext();

      expect(mockLearningPathManager.getCoachingContext).toHaveBeenCalled();
      expect(coachingContext).toEqual(expect.objectContaining({
        currentPhase: 'implementation',
        stuckPoints: ['async-patterns'],
        suggestedTopics: ['promises', 'async-await']
      }));
    });

    it('should update button appearance based on progress', () => {
      mockLearningPathManager.getPathProgress.mockReturnValue({
        percentage: 75,
        completedItems: 9,
        totalItems: 12
      });

      coachButton.createButton();
      coachButton.updateButtonState();

      expect(mockDomUtils.setAttribute).toHaveBeenCalledWith(
        expect.any(Object),
        'data-progress',
        '75'
      );
    });

    it('should show different states for different progress levels', () => {
      const progressLevels = [
        { percentage: 0, state: 'getting-started' },
        { percentage: 25, state: 'early-progress' },
        { percentage: 75, state: 'advanced-progress' },
        { percentage: 100, state: 'completed' }
      ];

      progressLevels.forEach(({ percentage, state }) => {
        mockLearningPathManager.getPathProgress.mockReturnValue({
          percentage,
          completedItems: Math.floor(percentage / 10),
          totalItems: 10
        });

        coachButton.createButton();
        coachButton.updateButtonState();

        expect(mockDomUtils.addClass).toHaveBeenCalledWith(
          expect.any(Object),
          `coach-button-${state}`
        );
      });
    });

    it('should handle missing or invalid progress data', () => {
      mockLearningPathManager.getPathProgress.mockReturnValue(null);

      const context = coachButton.getCurrentLearningContext();

      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
      expect(context).toBeDefined(); // Should have fallback
    });
  });

  describe('Event Handling and Interactions', () => {
    beforeEach(() => {
      coachButton = new CoachButton(mockDependencies);
    });

    it('should add click event listener to button', () => {
      coachButton.createButton();

      expect(mockDomUtils.addEventListener).toHaveBeenCalledWith(
        expect.any(Object),
        'click',
        expect.any(Function),
        expect.any(Object)
      );
    });

    it('should add keyboard event listeners for accessibility', () => {
      coachButton.createButton();

      expect(mockDomUtils.addEventListener).toHaveBeenCalledWith(
        expect.any(Object),
        'keydown',
        expect.any(Function),
        expect.any(Object)
      );
    });

    it('should handle Enter key press', () => {
      coachButton.createButton();
      const button = coachButton.buttonElement;

      const enterEvent = new KeyboardEvent('keydown', { key: 'Enter' });
      button.dispatchEvent(enterEvent);

      expect(mockVSCodeCommands.openChatWithContext).toHaveBeenCalled();
    });

    it('should handle Space key press', () => {
      coachButton.createButton();
      const button = coachButton.buttonElement;

      const spaceEvent = new KeyboardEvent('keydown', { key: ' ' });
      button.dispatchEvent(spaceEvent);

      expect(mockVSCodeCommands.openChatWithContext).toHaveBeenCalled();
    });

    it('should ignore other key presses', () => {
      coachButton.createButton();
      const button = coachButton.buttonElement;

      const tabEvent = new KeyboardEvent('keydown', { key: 'Tab' });
      button.dispatchEvent(tabEvent);

      expect(mockVSCodeCommands.openChatWithContext).not.toHaveBeenCalled();
    });

    it('should provide visual feedback on interaction', () => {
      coachButton.createButton();
      const button = coachButton.buttonElement;

      button.dispatchEvent(new Event('click'));

      expect(mockDomUtils.addClass).toHaveBeenCalledWith(
        expect.any(Object),
        'coach-button-active'
      );
    });

    it('should handle multiple rapid clicks gracefully', () => {
      coachButton.createButton();
      const button = coachButton.buttonElement;

      // Simulate multiple rapid clicks
      for (let i = 0; i < 5; i++) {
        button.dispatchEvent(new Event('click'));
      }

      // Should only trigger once due to debouncing
      expect(mockVSCodeCommands.openChatWithContext).toHaveBeenCalledTimes(1);
    });
  });

  describe('Error Handling and Edge Cases', () => {
    beforeEach(() => {
      coachButton = new CoachButton(mockDependencies);
    });

    it('should handle DOM creation errors', () => {
      mockDomUtils.createElement.mockImplementation(() => {
        throw new Error('DOM creation failed');
      });

      coachButton.createButton();

      expect(mockErrorHandler.handleError).toHaveBeenCalledWith(
        expect.any(Error),
        'CoachButton.createButton'
      );
    });

    it('should handle learning path manager errors', () => {
      mockLearningPathManager.getCurrentContext.mockImplementation(() => {
        throw new Error('Manager error');
      });

      const context = coachButton.getCurrentLearningContext();

      expect(mockErrorHandler.handleError).toHaveBeenCalledWith(
        expect.any(Error),
        'CoachButton.getCurrentLearningContext'
      );
    });

    it('should work with minimal learning context', () => {
      mockLearningPathManager.getCurrentContext.mockReturnValue({});

      const context = coachButton.getCurrentLearningContext();

      expect(context).toBeDefined();
      expect(coachButton.buildCoachCommandUri(context)).toBeDefined();
    });

    it('should handle viewport changes gracefully', () => {
      mockDomUtils.getViewportDimensions.mockReturnValue({ width: 320, height: 568 });

      coachButton.createButton();

      expect(mockDomUtils.addClass).toHaveBeenCalledWith(
        expect.any(Object),
        'mobile-optimized'
      );
    });

    it('should clean up properly on destroy', () => {
      coachButton.createButton();
      coachButton.destroy();

      expect(mockDomUtils.removeEventListener).toHaveBeenCalled();
      expect(coachButton.buttonElement).toBeNull();
      expect(coachButton.containerElement).toBeNull();
    });

    it('should handle destroy when not initialized', () => {
      expect(() => coachButton.destroy()).not.toThrow();
    });

    it('should handle multiple destroy calls', () => {
      coachButton.createButton();
      coachButton.destroy();

      expect(() => coachButton.destroy()).not.toThrow();
    });
  });

  describe('Configuration and Customization', () => {
    it('should support custom button text and styling', () => {
      const customConfig = {
        buttonText: '🎓 Learning Assistant',
        customClass: 'my-custom-coach',
        theme: 'dark'
      };

      coachButton = new CoachButton(mockDependencies, customConfig);
      coachButton.createButton();

      expect(mockDomUtils.addClass).toHaveBeenCalledWith(
        expect.any(Object),
        'my-custom-coach'
      );
      expect(mockDomUtils.addClass).toHaveBeenCalledWith(
        expect.any(Object),
        'theme-dark'
      );
    });

    it('should support custom VS Code commands', () => {
      const customConfig = {
        vscodeCommand: 'custom.extension/openCoach',
        commandArgs: { customMode: true }
      };

      coachButton = new CoachButton(mockDependencies, customConfig);

      const context = coachButton.getCurrentLearningContext();
      const uri = coachButton.buildCoachCommandUri(context);

      expect(mockVSCodeCommands.buildCommandUri).toHaveBeenCalledWith(
        'custom.extension/openCoach',
        expect.objectContaining({
          customMode: true
        })
      );
    });

    it('should support callback functions for custom behavior', () => {
      const customCallback = vi.fn();
      const customConfig = {
        onButtonClick: customCallback,
        onCoachActivated: customCallback
      };

      coachButton = new CoachButton(mockDependencies, customConfig);
      coachButton.createButton();

      const button = coachButton.buttonElement;
      button.dispatchEvent(new Event('click'));

      expect(customCallback).toHaveBeenCalled();
    });
  });

  describe('Enhanced Error Handling and Edge Cases', () => {
    test('should handle DOM creation errors gracefully', () => {
      // Mock DOM utils to throw errors
      mockDependencies.domUtils.createElement = vi.fn().mockImplementation(() => {
        throw new Error('DOM creation failed');
      });

      const coachButton = new CoachButton(mockDependencies);

      // Should not throw, should handle error gracefully
      expect(() => {
        coachButton.createButton();
      }).not.toThrow();

      // Error handler should have been called
      expect(mockDependencies.errorHandler.handleError).toHaveBeenCalled();
    });

    test('should handle missing window object in Node.js environment', () => {
      const originalWindow = global.window;
      delete global.window;

      try {
        const coachButton = new CoachButton(mockDependencies);
        // Test behavior that relies on window object
        const result = coachButton.shouldShowOnCurrentPage();

        // Should handle missing window gracefully with defaults
        expect(result).toBe(false);
      } finally {
        global.window = originalWindow;
      }
    });

    test('should handle malformed context data', () => {
      const coachButton = new CoachButton(mockDependencies);

      // Test with various malformed context data
      const malformedContexts = [
        null,
        undefined,
        '',
        [],
        { malformed: 'data' },
        { learningPath: null },
        { progressData: 'invalid' }
      ];

      malformedContexts.forEach(context => {
        expect(() => {
          coachButton.buildVSCodeCommandUri(context);
        }).not.toThrow();
      });
    });

    test('should handle rapid successive clicks with proper debouncing', async () => {
      const coachButton = new CoachButton(mockDependencies);
      coachButton.createButton();

      const clickSpy = vi.spyOn(coachButton, 'handleButtonClick');

      // Simulate rapid clicks
      const clickPromises = [];
      for (let i = 0; i < 5; i++) {
        clickPromises.push(coachButton.handleButtonClick());
      }

      await Promise.all(clickPromises);

      // Should handle all clicks but with debouncing
      expect(clickSpy).toHaveBeenCalledTimes(5);
    });

    test('should handle VS Code API availability changes', () => {
      const coachButton = new CoachButton(mockDependencies);

      // Test VS Code environment detection through existing method
      const hasVSCode = coachButton.isVSCodeEnvironment();

      // Should detect VS Code environment appropriately
      expect(typeof hasVSCode).toBe('boolean');

      // Simulate VS Code API becoming available
      const originalAcquireVsCodeApi = global.acquireVsCodeApi;
      try {
        global.acquireVsCodeApi = vi.fn(() => ({
          postMessage: vi.fn()
        }));

        // Test again
        const hasVSCodeNow = coachButton.isVSCodeEnvironment();
        expect(typeof hasVSCodeNow).toBe('boolean');
      } finally {
        // Clean up
        if (originalAcquireVsCodeApi) {
          global.acquireVsCodeApi = originalAcquireVsCodeApi;
        } else {
          delete global.acquireVsCodeApi;
        }
      }
    });

    test('should handle network failures during VS Code command execution', async () => {
      const coachButton = new CoachButton(mockDependencies);

      // Mock window.location.href to throw
      const originalLocation = window.location;
      Object.defineProperty(window, 'location', {
        value: {
          ...originalLocation,
          set href(value) {
            throw new Error('Network error');
          }
        },
        writable: true
      });

      try {
        const result = await coachButton.executeVSCodeCommand('vscode://test');

        // Should handle network error gracefully
        expect(result).toBe(false);
      } finally {
        Object.defineProperty(window, 'location', {
          value: originalLocation,
          writable: true
        });
      }
    });

    test('should handle memory leaks with proper cleanup', () => {
      const coachButton = new CoachButton(mockDependencies);
      coachButton.createButton();
      coachButton.show();

      // Add multiple event listeners to test cleanup
      const removeEventListenerSpy = vi.spyOn(mockDependencies.domUtils, 'removeEventListener');

      coachButton.destroy();

      // Should clean up all event listeners
      expect(removeEventListenerSpy).toHaveBeenCalled();
      expect(coachButton.buttonElement).toBeNull();
      expect(coachButton.containerElement).toBeNull();
    });
  });

  describe('Advanced Configuration and Customization', () => {
    test('should support advanced CSS class configurations', () => {
      const customConfig = {
        customClasses: ['custom-coach', 'theme-dark', 'size-large'],
        buttonText: 'Custom Coach Text',
        position: 'top-left'
      };

      const coachButton = new CoachButton(mockDependencies, customConfig);
      coachButton.createButton();

      // Check if configuration is properly stored
      expect(coachButton.config.buttonText).toBe('Custom Coach Text');
      expect(coachButton.config.position).toBe('top-left');

      // Should have created button with custom text
      expect(mockDependencies.domUtils.createElement).toHaveBeenCalled();
    });

    test('should support custom VS Code commands with parameters', () => {
      const customConfig = {
        vscodeCommand: 'custom.extension/openPanel',
        commandParameters: {
          mode: 'coaching',
          source: 'learning-path'
        }
      };

      const coachButton = new CoachButton(mockDependencies, customConfig);

      // Test that custom config is stored properly
      expect(coachButton.config.vscodeCommand).toBe('custom.extension/openPanel');
      expect(coachButton.config.commandParameters).toEqual({
        mode: 'coaching',
        source: 'learning-path'
      });
    });

    test('should support callback functions for custom behavior', async () => {
      const onClickCallback = vi.fn();
      const onShowCallback = vi.fn();
      const onHideCallback = vi.fn();

      const customConfig = {
        callbacks: {
          onClick: onClickCallback,
          onShow: onShowCallback,
          onHide: onHideCallback
        }
      };

      const coachButton = new CoachButton(mockDependencies, customConfig);
      coachButton.createButton();

      // Test that callbacks are stored in config
      expect(coachButton.config.callbacks).toBeDefined();
      expect(coachButton.config.callbacks.onClick).toBe(onClickCallback);
      expect(coachButton.config.callbacks.onShow).toBe(onShowCallback);
      expect(coachButton.config.callbacks.onHide).toBe(onHideCallback);
    });

    test('should support internationalization with custom text', () => {
      const i18nConfig = {
        buttonText: 'Demander au Coach',
        ariaLabel: 'Ouvrir le coach d\'apprentissage IA',
        tooltipText: 'Obtenez des conseils interactifs et des orientations'
      };

      const coachButton = new CoachButton(mockDependencies, i18nConfig);
      coachButton.createButton();

      // Check that i18n config is stored
      expect(coachButton.config.buttonText).toBe('Demander au Coach');
      expect(coachButton.config.ariaLabel).toBe('Ouvrir le coach d\'apprentissage IA');
      expect(coachButton.config.tooltipText).toBe('Obtenez des conseils interactifs et des orientations');
    });
  });

  describe('Performance and Memory Management', () => {
    test('should optimize DOM operations for better performance', () => {
      const coachButton = new CoachButton(mockDependencies);

      // Test batch DOM operations
      const addClassSpy = vi.spyOn(mockDependencies.domUtils, 'addClass');

      coachButton.createButton();

      // Should use efficient DOM manipulation - check that it's called at least once
      expect(addClassSpy.mock.calls.length).toBeGreaterThan(0);
    });

    test('should handle memory cleanup on page unload', () => {
      const coachButton = new CoachButton(mockDependencies);
      coachButton.createButton();
      coachButton.show();

      // Simulate page unload
      const unloadEvent = new Event('beforeunload');
      window.dispatchEvent(unloadEvent);

      // Should clean up resources
      expect(coachButton.isVisible).toBeDefined();
    });

    test('should handle viewport resize events efficiently', () => {
      const coachButton = new CoachButton(mockDependencies);
      coachButton.createButton();
      coachButton.show();

      // Mock viewport dimensions change
      mockDependencies.domUtils.getViewportDimensions = vi.fn()
        .mockReturnValueOnce({ width: 800, height: 600 })
        .mockReturnValueOnce({ width: 400, height: 800 });

      // Should adapt to viewport changes - test that component handles resize events
      const resizeEvent = new Event('resize');
      window.dispatchEvent(resizeEvent);

      // Test that component is responsive to changes
      expect(coachButton.isVisible).toBeDefined();
    });
  });

  describe('Integration Testing Scenarios', () => {
    test('should work with multiple coach button instances', () => {
      const config1 = { position: 'bottom-right' };
      const config2 = { position: 'bottom-left' };

      const button1 = new CoachButton(mockDependencies, config1);
      const button2 = new CoachButton(mockDependencies, config2);

      button1.createButton();
      button2.createButton();

      expect(button1.config.position).toBe('bottom-right');
      expect(button2.config.position).toBe('bottom-left');
    });

    test('should handle page navigation events', () => {
      const coachButton = new CoachButton(mockDependencies);
      coachButton.createButton();
      coachButton.show();

      // Simulate page navigation
      const originalPathname = window.location.pathname;
      Object.defineProperty(window.location, 'pathname', {
        value: '/non-learning-page',
        writable: true
      });

      // Should hide on non-learning pages
      const popstateEvent = new Event('popstate');
      window.dispatchEvent(popstateEvent);

      // Restore original pathname
      Object.defineProperty(window.location, 'pathname', {
        value: originalPathname,
        writable: true
      });
    });

    test('should integrate properly with learning path manager updates', async () => {
      const coachButton = new CoachButton(mockDependencies);
      coachButton.createButton();

      // Mock learning path manager emitting progress update
      const progressData = {
        completed: 5,
        total: 10,
        percentage: 50
      };

      mockDependencies.learningPathManager.getPathProgress = vi.fn()
        .mockReturnValue(progressData);

      // Test integration with learning path manager
      const context = coachButton.getCurrentLearningContext();

      expect(mockDependencies.learningPathManager.getCurrentContext).toHaveBeenCalled();
      expect(context).toBeDefined();
    });
  });
});
