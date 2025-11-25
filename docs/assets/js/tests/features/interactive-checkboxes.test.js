/**
 * Interactive Checkboxes Tests
 * Comprehensive test suite for interactive checkbox functionality
 * @jest-environment happy-dom
 * @version 1.0.0
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { InteractiveCheckboxManager } from '../../features/interactive-checkboxes.js';

describe('InteractiveCheckboxManager', () => {
  let manager;
  let mockDebugHelper;
  let mockErrorHandler;
  let mockProgressCore;

  beforeEach(() => {
    // Setup DOM
    document.body.innerHTML = '';
    window.location.hash = '';

    // Setup mocks
    mockDebugHelper = {
      debug: vi.fn(),
      info: vi.fn(),
      warn: vi.fn(),
      error: vi.fn()
    };

    mockErrorHandler = {
      safeExecute: vi.fn((fn, _context, defaultValue) => {
        try {
          return fn();
        } catch {
          return defaultValue;
        }
      })
    };

    mockProgressCore = {
      notifyCheckboxChange: vi.fn()
    };

    // Clear localStorage
    localStorage.clear();

    // Clear any existing timers
    vi.clearAllTimers();

    // Create manager instance
    manager = new InteractiveCheckboxManager({
      debugHelper: mockDebugHelper,
      errorHandler: mockErrorHandler,
      progressCore: mockProgressCore
    });
  });

  afterEach(() => {
    if (manager) {
      manager.cleanup();
    }
    vi.clearAllTimers();
    localStorage.clear();
    document.body.innerHTML = '';
  });

  describe('Initialization', () => {
    it('should initialize successfully', () => {
      const result = manager.init();
      expect(result).toBe(true);
      expect(manager.isInitialized).toBe(true);
    });

    it('should not initialize twice', () => {
      manager.init();
      const result = manager.init();
      expect(result).toBe(true);
      expect(mockDebugHelper.debug).toHaveBeenCalledWith('Interactive checkboxes already initialized');
    });

    it('should set up page change detection', () => {
      const addEventListenerSpy = vi.spyOn(window, 'addEventListener');
      manager.init();
      expect(addEventListenerSpy).toHaveBeenCalledWith('hashchange', expect.any(Function));
    });
  });

  describe('Page Detection', () => {
    it('should activate for kata pages', () => {
      window.location.hash = '#/learning/katas/my-kata/kata.md';
      const result = manager.shouldActivateForCurrentPage();
      expect(result).toBe(true);
    });

    it('should activate for training lab pages', () => {
      window.location.hash = '#/learning/training-labs/my-lab/lab.md';
      const result = manager.shouldActivateForCurrentPage();
      expect(result).toBe(true);
    });

    it('should not activate for README pages', () => {
      window.location.hash = '#/learning/katas/my-kata/README.md';
      const result = manager.shouldActivateForCurrentPage();
      expect(result).toBe(false);
    });

    it('should not activate for regular documentation pages', () => {
      window.location.hash = '#/docs/getting-started.md';
      const result = manager.shouldActivateForCurrentPage();
      expect(result).toBe(false);
    });

    it('should activate based on content detection', () => {
      window.location.hash = '#/some/path';
      document.body.innerHTML = `
        <main>
          <article>
            <h1>Test Kata</h1>
            <h2>Kata Overview</h2>
            <p>This is a kata page.</p>
          </article>
        </main>
      `;
      const result = manager.shouldActivateForCurrentPage();
      expect(result).toBe(true);
    });
  });

  describe('Kata ID Extraction', () => {
    it('should extract kata ID from kata path', () => {
      window.location.hash = '#/learning/katas/my-awesome-kata/kata.md';
      const kataId = manager.extractKataId();
      expect(kataId).toBe('my-awesome-kata');
    });

    it('should extract lab ID from training lab path', () => {
      window.location.hash = '#/learning/training-labs/advanced-lab/lab.md';
      const kataId = manager.extractKataId();
      expect(kataId).toBe('lab-advanced-lab');
    });

    it('should extract ID from page title', () => {
      window.location.hash = '#/some/random/path';
      document.body.innerHTML = '<h1>Advanced Data Processing Kata</h1>';
      const kataId = manager.extractKataId();
      expect(kataId).toBe('advanced-data-processing-kata');
    });

    it('should return null for invalid paths', () => {
      window.location.hash = '#/docs/regular-page';
      const kataId = manager.extractKataId();
      expect(kataId).toBeNull();
    });
  });

  describe('Checkbox Setup', () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <div>
          <ul>
            <li><input type="checkbox" /> Task 1</li>
            <li><input type="checkbox" /> Task 2</li>
            <li><input type="checkbox" /> Task 3</li>
          </ul>
        </div>
      `;
    });

    it('should set up interactive functionality for all checkboxes', () => {
      manager.setupCheckboxes();

      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      expect(checkboxes).toHaveLength(3);

      checkboxes.forEach((checkbox, _index) => {
        expect(checkbox.classList.contains('interactive-checkbox')).toBe(true);
        expect(checkbox.disabled).toBe(false);
        expect(checkbox.dataset.checkboxId).toBe(`checkbox-${_index}`);
      });
    });

    it('should track checkboxes in internal map', () => {
      manager.setupCheckboxes();
      expect(manager.checkboxElements.size).toBe(3);
      expect(manager.checkboxElements.has('checkbox-0')).toBe(true);
      expect(manager.checkboxElements.has('checkbox-1')).toBe(true);
      expect(manager.checkboxElements.has('checkbox-2')).toBe(true);
    });

    it('should clear existing checkbox tracking on re-setup', () => {
      manager.setupCheckboxes();
      expect(manager.checkboxElements.size).toBe(3);

      // Add more checkboxes
      document.body.innerHTML += '<input type="checkbox" /> Task 4';
      manager.setupCheckboxes();

      // Should track all checkboxes including new ones
      expect(manager.checkboxElements.size).toBe(4);
    });
  });

  describe('Progress Display', () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <main>
          <h1>Test Kata</h1>
          <ul>
            <li><input type="checkbox" /> Task 1</li>
            <li><input type="checkbox" /> Task 2</li>
          </ul>
        </main>
      `;
      manager.currentKataId = 'test-kata';
      manager.setupCheckboxes();
    });

    it('should not create progress display container (moved to unified tracker)', () => {
      manager.setupProgressDisplay();

      // Progress display has been moved to unified tracker system
      const container = document.querySelector('.kata-progress-container');
      expect(container).toBeNull(); // Should be null since it's disabled

      // Verify progress-related properties are null
      expect(manager.progressContainer).toBeNull();
      expect(manager.progressBar).toBeNull();
      expect(manager.progressPercentage).toBeNull();
      expect(manager.progressTasks).toBeNull();
    });

    it('should not update progress display (moved to unified tracker)', () => {
      manager.setupProgressDisplay();
      manager.updateProgressDisplay();

      // Progress display is now handled by unified tracker, not local display
      const percentage = document.querySelector('.progress-percentage');
      const tasks = document.querySelector('.progress-tasks');
      const progressBar = document.querySelector('.kata-progress-fill');

      // These elements should not exist since progress display is disabled
      expect(percentage).toBeNull();
      expect(tasks).toBeNull();
      expect(progressBar).toBeNull();
    });

    it('should not show checkbox progress (moved to unified tracker)', () => {
      manager.setupProgressDisplay();

      const checkbox = document.querySelector('input[type="checkbox"]');
      checkbox.checked = true;

      manager.updateProgressDisplay();

      // Progress display is now handled by unified tracker, not local display
      const percentage = document.querySelector('.progress-percentage');
      const tasks = document.querySelector('.progress-tasks');
      const progressBar = document.querySelector('.kata-progress-fill');

      // These elements should not exist since progress display is disabled
      expect(percentage).toBeNull();
      expect(tasks).toBeNull();
      expect(progressBar).toBeNull();
    });

    it('should not show completion styling (moved to unified tracker)', () => {
      manager.setupProgressDisplay();

      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      checkboxes.forEach(cb => cb.checked = true);

      manager.updateProgressDisplay();

      // Progress container doesn't exist since it's moved to unified tracker
      const container = document.querySelector('.kata-progress-container');
      expect(container).toBeNull();
    });
  });

  describe('Checkbox Interaction', () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <main>
          <h1>Test Kata</h1>
          <ul>
            <li><input type="checkbox" /> Task 1</li>
            <li><input type="checkbox" /> Task 2</li>
          </ul>
        </main>
      `;
      manager.currentKataId = 'test-kata';
      manager.setupCheckboxes();
      manager.setupProgressDisplay();
    });

    it('should handle checkbox changes', () => {
      const checkbox = document.querySelector('input[type="checkbox"]');
      checkbox.checked = true;

      const event = new Event('change');
      Object.defineProperty(event, 'target', {
        value: checkbox,
        writable: false
      });

      manager.handleCheckboxChange(event, 'checkbox-0');

      expect(mockProgressCore.notifyCheckboxChange).toHaveBeenCalledWith(
        'test-kata',
        'checkbox-0',
        true
      );
    });

    it('should add visual feedback for checked items', () => {
      const checkbox = document.querySelector('input[type="checkbox"]');
      const listItem = checkbox.closest('li');

      checkbox.checked = true;
      manager.addCheckboxAnimation(checkbox, true);

      expect(listItem.classList.contains('completed-task')).toBe(true);
      expect(checkbox.classList.contains('checkbox-complete-animation')).toBe(true);
    });

    it('should remove visual feedback for unchecked items', () => {
      const checkbox = document.querySelector('input[type="checkbox"]');
      const listItem = checkbox.closest('li');

      // First check it
      checkbox.checked = true;
      manager.addCheckboxAnimation(checkbox, true);
      expect(listItem.classList.contains('completed-task')).toBe(true);

      // Then uncheck it
      checkbox.checked = false;
      manager.addCheckboxAnimation(checkbox, false);
      expect(listItem.classList.contains('completed-task')).toBe(false);
    });
  });



  describe('Page Processing', () => {
    it('should process kata pages successfully', () => {
      window.location.hash = '#/learning/katas/test-kata/kata.md';
      document.body.innerHTML = `
        <main>
          <h1>Test Kata</h1>
          <ul>
            <li><input type="checkbox" /> Task 1</li>
          </ul>
        </main>
      `;

      const result = manager.processCurrentPage();
      expect(result).toBe(true);
      expect(manager.currentKataId).toBe('test-kata');
      expect(manager.checkboxElements.size).toBe(1);
    });

    it('should not process non-kata pages', () => {
      window.location.hash = '#/docs/regular-page';

      const result = manager.processCurrentPage();
      expect(result).toBe(false);
      expect(manager.currentKataId).toBeNull();
    });

    it('should cleanup when processing non-kata pages', () => {
      // First set up a kata page
      window.location.hash = '#/learning/katas/test-kata/kata.md';
      document.body.innerHTML = `
        <main>
          <h1>Test Kata</h1>
          <ul><li><input type="checkbox" /> Task 1</li></ul>
        </main>
      `;
      manager.processCurrentPage();
      expect(manager.currentKataId).toBe('test-kata');

      // Then switch to non-kata page
      window.location.hash = '#/docs/regular-page';
      const cleanupSpy = vi.spyOn(manager, 'cleanup');

      manager.processCurrentPage();
      expect(cleanupSpy).toHaveBeenCalled();
    });
  });

  describe('Progress Data API', () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <main>
          <h1>Test Kata</h1>
          <ul>
            <li><input type="checkbox" /> Task 1</li>
            <li><input type="checkbox" /> Task 2</li>
          </ul>
        </main>
      `;
      manager.currentKataId = 'test-kata';
      manager.setupCheckboxes();
    });

    it('should return current progress data', () => {
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      checkboxes[0].checked = true;

      const progress = manager.getCurrentProgress();

      expect(progress).toMatchObject({
        kataId: 'test-kata',
        totalTasks: 2,
        completedTasks: 1,
        completionPercentage: 50,
        checkboxStates: {
          'checkbox-0': true,
          'checkbox-1': false
        }
      });
      expect(progress.lastUpdated).toBeTruthy();
    });

    it('should return null when no kata is active', () => {
      manager.currentKataId = null;
      const progress = manager.getCurrentProgress();
      expect(progress).toBeNull();
    });

    it('should return storage key for current kata', () => {
      const key = manager.getStorageKey();
      expect(key).toBe('kata-progress-test-kata');
    });

    it('should return null storage key when no kata is active', () => {
      manager.currentKataId = null;
      const key = manager.getStorageKey();
      expect(key).toBeNull();
    });

    it('should indicate if currently active', () => {
      expect(manager.isActive()).toBe(true);

      manager.currentKataId = null;
      expect(manager.isActive()).toBe(false);
    });
  });

  describe('Progress Reset', () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <main>
          <h1>Test Kata</h1>
          <ul>
            <li><input type="checkbox" /> Task 1</li>
            <li><input type="checkbox" /> Task 2</li>
          </ul>
        </main>
      `;
      manager.currentKataId = 'test-kata';
      manager.setupCheckboxes();
      manager.setupProgressDisplay();
    });

    it('should reset all progress data', () => {
      // Set some progress first
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      checkboxes[0].checked = true;
      manager.saveCheckboxState('checkbox-0', true);

      // Reset progress
      const result = manager.resetProgress();

      expect(result).toBe(true);
      expect(localStorage.getItem('kata-progress-test-kata')).toBeNull();
      expect(checkboxes[0].checked).toBe(false);

      const listItem = checkboxes[0].closest('li');
      expect(listItem.classList.contains('completed-task')).toBe(false);
    });

    it('should return false when no kata is active', () => {
      manager.currentKataId = null;
      const result = manager.resetProgress();
      expect(result).toBe(false);
    });
  });

  describe('Cleanup', () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <main>
          <h1>Test Kata</h1>
          <ul>
            <li><input type="checkbox" /> Task 1</li>
          </ul>
        </main>
      `;
      manager.currentKataId = 'test-kata';
      manager.setupCheckboxes();
      manager.setupProgressDisplay();
    });

    it('should cleanup all interactive functionality', () => {
      manager.cleanup();

      expect(manager.currentKataId).toBeNull();
      expect(manager.checkboxElements.size).toBe(0);
      expect(manager.progressContainer).toBeNull();

      const checkbox = document.querySelector('input[type="checkbox"]');
      expect(checkbox.classList.contains('interactive-checkbox')).toBe(false);
      expect(checkbox.dataset.checkboxId).toBeUndefined();
    });

    it('should handle cleanup without progress container (moved to unified tracker)', () => {
      // Progress container no longer exists since it's moved to unified tracker
      expect(document.querySelector('.kata-progress-container')).toBeNull();

      manager.cleanup();

      // Should not throw errors during cleanup
      expect(document.querySelector('.kata-progress-container')).toBeNull();
    });
  });

  describe('Completion Celebration', () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <main>
          <h1>Test Kata</h1>
          <ul>
            <li><input type="checkbox" /> Task 1</li>
          </ul>
        </main>
      `;
      manager.currentKataId = 'test-kata';
      manager.setupCheckboxes();
      manager.setupProgressDisplay();
    });

    it('should trigger completion celebration', () => {
      const eventSpy = vi.spyOn(window, 'dispatchEvent');

      manager.triggerCompletionCelebration();

      // Note: Animation is handled by unified progress tracker
      // We only verify that the completion event is dispatched
      expect(eventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'kataCompleted',
          detail: expect.objectContaining({
            kataId: 'test-kata',
            timestamp: expect.any(String)
          })
        })
      );
    });
  });

  describe('Error Handling', () => {
    it('should handle errors gracefully during initialization', () => {
      const mockErrorHandler = {
        safeExecute: vi.fn((fn, context, _defaultValue) => {
          if (context === 'InteractiveCheckboxManager.init') {
            // Return default value instead of throwing
            return false;
          }
          return fn();
        })
      };

      const manager = new InteractiveCheckboxManager({
        errorHandler: mockErrorHandler
      });

      expect(() => manager.init()).not.toThrow();
      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });

    it('should handle DOM manipulation errors', () => {
      // Simulate DOM that gets removed during operation
      document.body.innerHTML = '<div></div>';
      manager.currentKataId = 'test-kata';

      // Remove the DOM element
      document.body.innerHTML = '';

      expect(() => manager.setupProgressDisplay()).not.toThrow();
      expect(() => manager.updateProgressDisplay()).not.toThrow();
    });
  });

  describe('Debouncing', () => {
    beforeEach(() => {
      vi.useFakeTimers();
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it('should debounce update operations', () => {
      const callback = vi.fn();

      manager.debounceUpdate(callback);
      manager.debounceUpdate(callback);
      manager.debounceUpdate(callback);

      expect(callback).not.toHaveBeenCalled();

      vi.advanceTimersByTime(300);

      expect(callback).toHaveBeenCalledTimes(1);
    });
  });
});
