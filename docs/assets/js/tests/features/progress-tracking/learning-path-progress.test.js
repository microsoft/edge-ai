/**
 * @file Tests for LearningPathProgress class
 * @description Comprehensive test suite for learning path progress tracking functionality
 */

import { beforeEach, afterEach, describe, it, expect, vi } from 'vitest';
import { LearningPathProgress } from '../../../features/progress-tracking/learning-path-progress.js';

describe('LearningPathProgress', () => {
  let progressTracker;
  let mockErrorHandler;
  let mockDebugHelper;

  // DOM setup helpers
  const createCheckbox = (id = null, name = null) => {
    const checkbox = document.createElement('input');
    checkbox.type = 'checkbox';
    if (id) {checkbox.id = id;}
    if (name) {checkbox.name = name;}
    return checkbox;
  };

  const createHeading = (level, text, id = null) => {
    const heading = document.createElement(`h${level}`);
    heading.textContent = text;
    if (id) {heading.id = id;}
    return heading;
  };

  const createLearningPathHTML = () => {
    const container = document.createElement('div');
    container.innerHTML = `
      <div>
        <h2 id="basic-path">Basic Learning Path</h2>
        <div>
          <label>
            <input type="checkbox" id="checkbox-1" /> Complete Module 1
          </label>
        </div>
        <div>
          <label>
            <input type="checkbox" name="checkbox-2" /> Complete Module 2
          </label>
        </div>
      </div>
      <div>
        <h3>Advanced Learning Track</h3>
        <div>
          <label>
            <input type="checkbox" /> Complete Advanced Module
          </label>
        </div>
      </div>
      <div>
        <h4 id="specialized-course">Specialized Course</h4>
        <div>
          <label>
            <input type="checkbox" id="spec-1" /> Specialized Topic 1
          </label>
        </div>
        <div>
          <label>
            <input type="checkbox" id="spec-2" /> Specialized Topic 2
          </label>
        </div>
        <div>
          <label>
            <input type="checkbox" id="spec-3" /> Specialized Topic 3
          </label>
        </div>
      </div>
    `;
    return container;
  };

  beforeEach(() => {
    // Reset DOM
    document.body.innerHTML = '';

    // Clear localStorage
    localStorage.clear();

    // Create mock dependencies
    mockErrorHandler = {
      safeExecute: vi.fn((fn) => fn())
    };

    mockDebugHelper = {
      log: vi.fn()
    };

    // Mock fetch for server connection test
    global.fetch = vi.fn((url) => {
      if (url.includes('/api/progress/sync-status')) {
        return Promise.resolve({ ok: true });
      }
      return Promise.reject(new Error('Not mocked'));
    });

    // Create fresh instance
    progressTracker = new LearningPathProgress({
      errorHandler: mockErrorHandler,
      debugHelper: mockDebugHelper,
      debug: true
    });

    // Clear all timers
    vi.clearAllTimers();
  });

  afterEach(() => {
    // Clean up
    if (progressTracker) {
      progressTracker.destroy();
    }
    localStorage.clear();
    document.body.innerHTML = '';
    vi.clearAllTimers();
  });

  describe('Constructor', () => {
    it('should create a new instance with default options', () => {
      const tracker = new LearningPathProgress();

      expect(tracker.errorHandler).toBeNull();
      expect(tracker.debugHelper).toBeNull();
      expect(tracker.debug).toBe(false);
      expect(tracker.storagePrefix).toBe('learningPathProgress_');
      expect(tracker.autoSaveDelay).toBe(1000);
      expect(tracker.progressData).toBeInstanceOf(Map);
      expect(tracker.checkboxRegistry).toBeInstanceOf(Map);
      expect(tracker.saveTimeouts).toBeInstanceOf(Map);
      expect(tracker.boundHandlers).toBeInstanceOf(Map);
    });

    it('should accept custom options', () => {
      expect(progressTracker.errorHandler).toBe(mockErrorHandler);
      expect(progressTracker.debugHelper).toBe(mockDebugHelper);
      expect(progressTracker.debug).toBe(true);
    });

    it('should initialize with empty data structures', () => {
      expect(progressTracker.progressData.size).toBe(0);
      expect(progressTracker.checkboxRegistry.size).toBe(0);
      expect(progressTracker.saveTimeouts.size).toBe(0);
      expect(progressTracker.boundHandlers.size).toBe(0);
    });
  });

  describe('initialize()', () => {
    it('should initialize successfully', async () => {
      const result = await progressTracker.initialize();

      expect(result).toBe(true);
    });

    it('should load existing progress and enhance checkboxes', async () => {
      // Add some DOM content
      document.body.appendChild(createLearningPathHTML());

      // Mock successful server load with existing progress
      global.fetch = vi.fn((url) => {
        if (url.includes('/api/progress/sync-status')) {
          return Promise.resolve({ ok: true });
        }
        if (url.includes('/api/progress/list')) {
          return Promise.resolve({
            ok: true,
            json: () => Promise.resolve({
              success: true,
              files: [{
                fileType: 'kata-progress',
                metadata: { kataId: 'basic-path' },
                filename: 'kata-basic-path.json'
              }]
            })
          });
        }
        if (url.includes('/api/progress/load/kata/basic-path')) {
          return Promise.resolve({
            ok: true,
            json: () => Promise.resolve({
              success: true,
              data: {
                checkboxes: { 'checkbox-1': true },
                timestamp: Date.now(),
                schema: 'unified-progress-v1'
              }
            })
          });
        }
        return Promise.reject(new Error('Not mocked'));
      });

      const result = await progressTracker.initialize();

      expect(result).toBe(true);
      expect(progressTracker.progressData.size).toBe(1);
      expect(progressTracker.progressData.has('basic-path')).toBe(true);
    });

    it('should handle initialization errors gracefully', async () => {
      // Mock loadAllProgress to throw an error
      vi.spyOn(progressTracker, 'loadAllProgress').mockImplementation(() => {
        throw new Error('Storage error');
      });

      const result = await progressTracker.initialize();

      expect(result).toBe(false);
      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });
  });

  describe('enhanceProgressCheckboxes()', () => {
    it('should enhance all checkboxes on the page', () => {
      document.body.appendChild(createLearningPathHTML());
      const spy = vi.spyOn(progressTracker, 'enhanceCheckbox');

      progressTracker.enhanceProgressCheckboxes();

      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      expect(spy).toHaveBeenCalledTimes(checkboxes.length);
    });

    it('should handle empty page gracefully', () => {
      const spy = vi.spyOn(progressTracker, 'enhanceCheckbox');

      progressTracker.enhanceProgressCheckboxes();

      expect(spy).not.toHaveBeenCalled();
    });
  });

  describe('enhanceCheckbox()', () => {
    it('should enhance checkbox with path ID', () => {
      const container = createLearningPathHTML();
      document.body.appendChild(container);

      const checkbox = container.querySelector('#checkbox-1');
      progressTracker.enhanceCheckbox(checkbox);

      expect(progressTracker.checkboxRegistry.has('basic-path')).toBe(true);
      expect(progressTracker.checkboxRegistry.get('basic-path').has('checkbox-1')).toBe(true);
    });

    it('should skip enhancement if no path ID found', () => {
      const checkbox = createCheckbox('orphan-checkbox');
      document.body.appendChild(checkbox);

      progressTracker.enhanceCheckbox(checkbox);

      expect(progressTracker.checkboxRegistry.size).toBe(0);
    });

    it('should skip enhancement if no checkbox ID generated', () => {
      const container = document.createElement('div');
      container.innerHTML = `
        <h2>Test Path</h2>
        <input type="checkbox" />
      `;
      document.body.appendChild(container);

      // Mock getCheckboxId to return null
      vi.spyOn(progressTracker, 'getCheckboxId').mockReturnValue(null);

      const checkbox = container.querySelector('input');
      progressTracker.enhanceCheckbox(checkbox);

      expect(progressTracker.checkboxRegistry.size).toBe(0);
    });

    it('should load and apply saved checkbox state', () => {
      // Set up progress data
      progressTracker.progressData.set('basic-path', {
        checkboxes: { 'checkbox-1': true },
        lastUpdated: Date.now(),
        schema: 'unified-progress-v1'
      });

      const container = createLearningPathHTML();
      document.body.appendChild(container);

      const checkbox = container.querySelector('#checkbox-1');
      expect(checkbox.checked).toBe(false); // Initially unchecked

      progressTracker.enhanceCheckbox(checkbox);

      expect(checkbox.checked).toBe(true); // Should be checked after enhancement
    });

    it('should add change event listener', () => {
      const container = createLearningPathHTML();
      document.body.appendChild(container);

      const checkbox = container.querySelector('#checkbox-1');
      const spy = vi.spyOn(checkbox, 'addEventListener');

      progressTracker.enhanceCheckbox(checkbox);

      expect(spy).toHaveBeenCalledWith('change', expect.any(Function));
    });

    it('should handle enhancement errors gracefully', () => {
      const checkbox = createCheckbox();

      // Mock findPathIdForCheckbox to throw an error
      vi.spyOn(progressTracker, 'findPathIdForCheckbox').mockImplementation(() => {
        throw new Error('Path finding error');
      });

      progressTracker.enhanceCheckbox(checkbox);

      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });
  });

  describe('handleCheckboxChange()', () => {
    it('should handle checkbox state change', () => {
      const pathId = 'test-path';
      const checkboxId = 'test-checkbox';
      const checkbox = createCheckbox(checkboxId);
      checkbox.checked = true;

      const event = { target: checkbox };
      const saveSpy = vi.spyOn(progressTracker, 'saveCheckboxProgress');
      const emitSpy = vi.spyOn(progressTracker, 'emitProgressUpdate');

      progressTracker.handleCheckboxChange(event, pathId, checkboxId);

      expect(saveSpy).toHaveBeenCalledWith(pathId, checkboxId, true);
      expect(emitSpy).toHaveBeenCalledWith(pathId);
    });

    it('should handle errors during checkbox change', () => {
      const event = { target: { checked: true } };

      // Mock saveCheckboxProgress to throw an error
      vi.spyOn(progressTracker, 'saveCheckboxProgress').mockImplementation(() => {
        throw new Error('Save error');
      });

      progressTracker.handleCheckboxChange(event, 'test-path', 'test-checkbox');

      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });
  });

  describe('saveCheckboxProgress()', () => {
    beforeEach(() => {
      vi.useFakeTimers();
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it('should save checkbox progress with debouncing', () => {
      const pathId = 'test-path';
      const checkboxId = 'test-checkbox';
      const checked = true;

      // Enable API sync and set server connected
      progressTracker.enableApiSync = true;
      progressTracker.isServerConnected = true;

      progressTracker.saveCheckboxProgress(pathId, checkboxId, checked);

      // Check in-memory data
      expect(progressTracker.progressData.has(pathId)).toBe(true);
      const pathProgress = progressTracker.progressData.get(pathId);
      expect(pathProgress.checkboxes[checkboxId]).toBe(checked);
      expect(pathProgress.schema).toBe('unified-progress-v1');

      // Check debounced save - use correct timeout key format (server timeout, not localStorage)
      const timeoutKey = `api_${pathId}_${checkboxId}`;
      expect(progressTracker.saveTimeouts.has(timeoutKey)).toBe(true);
    });

    it('should update existing path progress', () => {
      const pathId = 'test-path';

      // Set initial progress
      progressTracker.progressData.set(pathId, {
        checkboxes: { 'existing-checkbox': true },
        lastUpdated: 123456,
        schema: 'unified-progress-v1'
      });

      progressTracker.saveCheckboxProgress(pathId, 'new-checkbox', false);

      const pathProgress = progressTracker.progressData.get(pathId);
      expect(pathProgress.checkboxes['existing-checkbox']).toBe(true);
      expect(pathProgress.checkboxes['new-checkbox']).toBe(false);
      expect(pathProgress.lastUpdated).toBeGreaterThan(123456);
    });

    it('should clear existing timeout before setting new one', () => {
      const pathId = 'test-path';
      const checkboxId = 'test-checkbox';

      // Enable API sync and set server connected
      progressTracker.enableApiSync = true;
      progressTracker.isServerConnected = true;

      progressTracker.saveCheckboxProgress(pathId, checkboxId, true);
      const firstTimeoutId = progressTracker.saveTimeouts.get(`api_${pathId}_${checkboxId}`);

      progressTracker.saveCheckboxProgress(pathId, checkboxId, false);
      const secondTimeoutId = progressTracker.saveTimeouts.get(`api_${pathId}_${checkboxId}`);

      expect(firstTimeoutId).not.toBe(secondTimeoutId);
    });



    it('should handle save errors gracefully', () => {
      // Mock Date.now to throw an error
      const originalNow = Date.now;
      Date.now = vi.fn(() => {
        throw new Error('Date error');
      });

      progressTracker.saveCheckboxProgress('test-path', 'test-checkbox', true);

      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();

      Date.now = originalNow;
    });
  });







  describe('getCheckboxProgress()', () => {
    it('should return checkbox state when found', () => {
      progressTracker.progressData.set('test-path', {
        checkboxes: { 'cb1': true, 'cb2': false },
        lastUpdated: Date.now(),
        schema: 'unified-progress-v1'
      });

      expect(progressTracker.getCheckboxProgress('test-path', 'cb1')).toBe(true);
      expect(progressTracker.getCheckboxProgress('test-path', 'cb2')).toBe(false);
    });

    it('should return false for missing checkbox', () => {
      progressTracker.progressData.set('test-path', {
        checkboxes: {},
        lastUpdated: Date.now(),
        schema: 'unified-progress-v1'
      });

      expect(progressTracker.getCheckboxProgress('test-path', 'missing')).toBe(false);
    });

    it('should return null for missing path', () => {
      expect(progressTracker.getCheckboxProgress('missing-path', 'cb1')).toBeNull();
    });

    it('should return null for path without checkboxes', () => {
      progressTracker.progressData.set('test-path', {
        lastUpdated: Date.now(),
        schema: 'unified-progress-v1'
      });

      expect(progressTracker.getCheckboxProgress('test-path', 'cb1')).toBeNull();
    });
  });

  describe('calculatePathProgress()', () => {
    it('should calculate progress correctly', () => {
      const pathId = 'test-path';
      const checkboxMap = new Map();

      // Create mock checkboxes
      const cb1 = createCheckbox('cb1');
      const cb2 = createCheckbox('cb2');
      const cb3 = createCheckbox('cb3');

      cb1.checked = true;
      cb2.checked = true;
      cb3.checked = false;

      checkboxMap.set('cb1', cb1);
      checkboxMap.set('cb2', cb2);
      checkboxMap.set('cb3', cb3);

      progressTracker.checkboxRegistry.set(pathId, checkboxMap);

      const progress = progressTracker.calculatePathProgress(pathId);

      expect(progress.completed).toBe(2);
      expect(progress.total).toBe(3);
      expect(progress.percentage).toBe(67); // Math.round(2/3 * 100)
    });

    it('should handle missing path', () => {
      const progress = progressTracker.calculatePathProgress('missing-path');

      expect(progress.completed).toBe(0);
      expect(progress.total).toBe(0);
      expect(progress.percentage).toBe(0);
    });

    it('should handle empty checkbox registry', () => {
      progressTracker.checkboxRegistry.set('test-path', new Map());

      const progress = progressTracker.calculatePathProgress('test-path');

      expect(progress.completed).toBe(0);
      expect(progress.total).toBe(0);
      expect(progress.percentage).toBe(0);
    });

    it('should handle calculation errors', () => {
      // Create a mock that throws an error
      const pathId = 'test-path';
      const checkboxMap = new Map();
      checkboxMap.forEach = vi.fn(() => {
        throw new Error('Iteration error');
      });

      progressTracker.checkboxRegistry.set(pathId, checkboxMap);

      const progress = progressTracker.calculatePathProgress(pathId);

      expect(progress.completed).toBe(0);
      expect(progress.total).toBe(0);
      expect(progress.percentage).toBe(0);
      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });
  });

  describe('findPathIdForCheckbox()', () => {
    it('should find path ID from nearby heading', () => {
      const container = createLearningPathHTML();
      document.body.appendChild(container);

      const checkbox = container.querySelector('#checkbox-1');
      const pathId = progressTracker.findPathIdForCheckbox(checkbox);

      expect(pathId).toBe('basic-path');
    });

    it('should find path ID from heading with path-related text', () => {
      const container = document.createElement('div');
      container.innerHTML = `
        <h2>Learning Track Advanced</h2>
        <div>
          <label>
            <input type="checkbox" id="track-cb" />
          </label>
        </div>
      `;
      document.body.appendChild(container);

      const checkbox = container.querySelector('#track-cb');
      const pathId = progressTracker.findPathIdForCheckbox(checkbox);

      expect(pathId).toBe('learning-track-advanced');
    });

    it('should return null for checkbox without path context', () => {
      const container = document.createElement('div');
      container.innerHTML = `
        <h2>Regular Heading</h2>
        <div>
          <label>
            <input type="checkbox" id="orphan-cb" />
          </label>
        </div>
      `;
      document.body.appendChild(container);

      const checkbox = container.querySelector('#orphan-cb');
      const pathId = progressTracker.findPathIdForCheckbox(checkbox);

      expect(pathId).toBeNull();
    });

    it('should handle errors gracefully', () => {
      const checkbox = createCheckbox();
      document.body.appendChild(checkbox);

      // Mock the internal method that might cause issues
      vi.spyOn(progressTracker, 'getElementPosition').mockImplementation(() => {
        throw new Error('Position error');
      });

      const pathId = progressTracker.findPathIdForCheckbox(checkbox);

      expect(pathId).toBeNull();
      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });
  });

  describe('isPathHeading()', () => {
    it('should identify path headings by text content', () => {
      const pathHeading = createHeading(2, 'Learning Path: JavaScript');
      const trackHeading = createHeading(3, 'Advanced Track');
      const courseHeading = createHeading(4, 'Course Overview');
      const regularHeading = createHeading(2, 'Regular Section');

      expect(progressTracker.isPathHeading(pathHeading)).toBe(true);
      expect(progressTracker.isPathHeading(trackHeading)).toBe(true);
      expect(progressTracker.isPathHeading(courseHeading)).toBe(true);
      expect(progressTracker.isPathHeading(regularHeading)).toBe(false);
    });

    it('should identify path headings by ID', () => {
      const headingWithPathId = createHeading(2, 'Regular Text', 'learning-path-1');
      const headingWithTrackId = createHeading(3, 'Regular Text', 'skill-track-advanced');
      const headingWithRegularId = createHeading(2, 'Regular Text', 'normal-section');

      expect(progressTracker.isPathHeading(headingWithPathId)).toBe(true);
      expect(progressTracker.isPathHeading(headingWithTrackId)).toBe(true);
      expect(progressTracker.isPathHeading(headingWithRegularId)).toBe(false);
    });
  });

  describe('extractPathId()', () => {
    it('should use element ID when available', () => {
      const heading = createHeading(2, 'Some Text', 'existing-id');

      expect(progressTracker.extractPathId(heading)).toBe('existing-id');
    });

    it('should generate ID from text content', () => {
      const heading = createHeading(2, 'Learning Path: Advanced JavaScript!');

      expect(progressTracker.extractPathId(heading)).toBe('learning-path-advanced-javascript');
    });

    it('should handle special characters and spacing', () => {
      const heading = createHeading(2, '  Multiple   Spaces & Special@Characters!  ');

      expect(progressTracker.extractPathId(heading)).toBe('-multiple-spaces-specialcharacters-');
    });
  });

  describe('getCheckboxId()', () => {
    it('should use existing ID when available', () => {
      const checkbox = createCheckbox('existing-id');

      expect(progressTracker.getCheckboxId(checkbox)).toBe('existing-id');
    });

    it('should use name attribute when ID not available', () => {
      const checkbox = createCheckbox(null, 'checkbox-name');

      expect(progressTracker.getCheckboxId(checkbox)).toBe('checkbox-name');
    });

    it('should generate ID from label text', () => {
      const container = document.createElement('div');
      container.innerHTML = `
        <label>
          <input type="checkbox" /> Complete Module 1: Introduction
        </label>
      `;

      const checkbox = container.querySelector('input');
      const id = progressTracker.getCheckboxId(checkbox);

      expect(id).toBe('complete-module-1-introduction');
    });

    it('should fallback to position-based ID', () => {
      const container = document.createElement('div');
      container.innerHTML = `
        <div>First element</div>
        <div>Second element</div>
        <input type="checkbox" />
      `;
      document.body.appendChild(container);

      const checkbox = container.querySelector('input');
      const id = progressTracker.getCheckboxId(checkbox);

      expect(id).toBe('checkbox-2'); // Position in parent
    });
  });

  describe('emitProgressUpdate()', () => {
    it('should emit custom progress event', () => {
      const pathId = 'test-path';

      // Set up checkbox registry for progress calculation
      const checkboxMap = new Map();
      const cb1 = createCheckbox('cb1');
      cb1.checked = true;
      checkboxMap.set('cb1', cb1);
      progressTracker.checkboxRegistry.set(pathId, checkboxMap);

      const eventListener = vi.fn();
      document.addEventListener('learningPathProgressUpdate', eventListener);

      progressTracker.emitProgressUpdate(pathId);

      expect(eventListener).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: {
            pathId,
            progress: {
              completed: 1,
              total: 1,
              percentage: 100
            }
          }
        })
      );

      document.removeEventListener('learningPathProgressUpdate', eventListener);
    });

    it('should handle emit errors gracefully', () => {
      // Mock calculatePathProgress to throw an error
      vi.spyOn(progressTracker, 'calculatePathProgress').mockImplementation(() => {
        throw new Error('Progress calculation error');
      });

      progressTracker.emitProgressUpdate('test-path');

      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });
  });

  describe('getAllProgress()', () => {
    it('should return all progress data with calculations', () => {
      // Set up test data
      progressTracker.progressData.set('path1', {
        checkboxes: { 'cb1': true },
        lastUpdated: 123456,
        schema: 'unified-progress-v1'
      });

      const checkboxMap = new Map();
      const cb1 = createCheckbox('cb1');
      cb1.checked = true;
      checkboxMap.set('cb1', cb1);
      progressTracker.checkboxRegistry.set('path1', checkboxMap);

      const allProgress = progressTracker.getAllProgress();

      expect(allProgress).toEqual({
        path1: {
          checkboxes: { 'cb1': true },
          lastUpdated: 123456,
          schema: 'unified-progress-v1',
          calculated: {
            completed: 1,
            total: 1,
            percentage: 100
          }
        }
      });
    });

    it('should return empty object when no progress data', () => {
      const allProgress = progressTracker.getAllProgress();

      expect(allProgress).toEqual({});
    });
  });

  describe('clearAllProgress()', () => {
    it('should clear all progress data and reset checkboxes', () => {
      // Set up test data
      progressTracker.progressData.set('path1', { checkboxes: {} });
      progressTracker.progressData.set('path2', { checkboxes: {} });

      const checkboxMap = new Map();
      const cb1 = createCheckbox('cb1');
      cb1.checked = true;
      checkboxMap.set('cb1', cb1);
      progressTracker.checkboxRegistry.set('path1', checkboxMap);

      const removedCount = progressTracker.clearAllProgress();

      expect(removedCount).toBe(2);
      expect(progressTracker.progressData.size).toBe(0);
      expect(cb1.checked).toBe(false);
    });

    it('should handle clearing errors gracefully', () => {
      // Set up some in-memory data
      progressTracker.progressData.set('path1', { checkboxes: {} });
      progressTracker.progressData.set('path2', { checkboxes: {} });

      // Reset the spy calls before the test
      mockErrorHandler.safeExecute.mockClear();

      // Mock progressData.clear to throw an error
      const originalClear = progressTracker.progressData.clear;
      progressTracker.progressData.clear = vi.fn(() => {
        throw new Error('Data clearing error');
      });

      const removedCount = progressTracker.clearAllProgress();

      expect(removedCount).toBe(0);
      expect(mockErrorHandler.safeExecute).toHaveBeenCalledWith(expect.any(Function));

      progressTracker.progressData.clear = originalClear;
    });
  });

  describe('destroy()', () => {
    beforeEach(() => {
      vi.useFakeTimers();
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it('should clean up all resources', () => {
      // Set up data to be cleaned
      progressTracker.saveTimeouts.set('timeout1', setTimeout(() => {}, 1000));
      progressTracker.saveTimeouts.set('timeout2', setTimeout(() => {}, 1000));

      const checkbox = createCheckbox();
      const handler = vi.fn();
      const handlerMap = new Map();
      handlerMap.set('change', handler);
      progressTracker.boundHandlers.set(checkbox, handlerMap);

      progressTracker.progressData.set('path1', {});
      progressTracker.checkboxRegistry.set('path1', new Map());

      const removeListenerSpy = vi.spyOn(checkbox, 'removeEventListener');

      progressTracker.destroy();

      expect(progressTracker.saveTimeouts.size).toBe(0);
      expect(progressTracker.boundHandlers.size).toBe(0);
      expect(progressTracker.progressData.size).toBe(0);
      expect(progressTracker.checkboxRegistry.size).toBe(0);
      expect(removeListenerSpy).toHaveBeenCalledWith('change', handler);
    });

    it('should handle destruction errors gracefully', () => {
      // Mock clearTimeout to throw an error
      const originalClearTimeout = clearTimeout;
      window.clearTimeout = vi.fn(() => {
        throw new Error('Clear timeout error');
      });

      progressTracker.saveTimeouts.set('timeout1', 123);

      progressTracker.destroy();

      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();

      window.clearTimeout = originalClearTimeout;
    });
  });

  describe('Error Handling', () => {
    it('should handle errors with error handler', () => {
      progressTracker.handleError('Test error', new Error('Test'));

      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });

    it('should handle errors without error handler', () => {
      const tracker = new LearningPathProgress();
      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

      tracker.handleError('Test error', new Error('Test'));

      expect(consoleSpy).toHaveBeenCalledWith(
        '[LearningPathProgress] Test error:',
        expect.any(Error)
      );

      consoleSpy.mockRestore();
    });
  });

  describe('Debug Logging', () => {
    it('should not log debug messages (disabled for performance)', () => {
      const consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {});

      progressTracker.log('Test message', 'extra', 'args');

      // Debug logging is disabled for performance optimization
      expect(consoleSpy).not.toHaveBeenCalled();

      consoleSpy.mockRestore();
    });

    it('should not log when debug disabled', () => {
      const tracker = new LearningPathProgress({ debug: false });
      const consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {});

      tracker.log('Test message');

      expect(consoleSpy).not.toHaveBeenCalled();

      consoleSpy.mockRestore();
    });
  });


});
