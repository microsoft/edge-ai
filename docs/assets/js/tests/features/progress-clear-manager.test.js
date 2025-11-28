/**
 * @fileoverview Tests for Progress Clear Manager
 * @version 1.0.0
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

// Import the class to test
import { ProgressClearManager, getProgressClearManager, initializeProgressClearManager } from '../../features/progress-clear-manager.js';

// Mock dependencies
vi.mock('../../core/storage-manager.js', () => ({
  StorageManager: vi.fn().mockImplementation(() => ({
    getKataProgress: vi.fn(),
    getAllKataProgress: vi.fn(),
    clearKataProgress: vi.fn(),
    clearAssessmentResults: vi.fn(),
    clearUserSettings: vi.fn()
  }))
}));

vi.mock('../../core/learning-path-manager.js', () => ({
  LearningPathManager: vi.fn().mockImplementation(() => ({
    clearCache: vi.fn(),
    resetKataState: vi.fn()
  }))
}));

vi.mock('../../core/user-manager.js', () => ({
  UserManager: vi.fn().mockImplementation(() => ({
    getCurrentKataId: vi.fn()
  }))
}));

describe('ProgressClearManager', () => {
  let clearManager;
  let mockStorageManager;
  let mockLearningPathManager;

  beforeEach(() => {
    // Setup clean document state
    document.body.innerHTML = '';

    // Mock console methods
    global.console = {
      log: vi.fn(),
      error: vi.fn(),
      warn: vi.fn()
    };

    // Create fresh instance for each test
    clearManager = new ProgressClearManager();

    // Replace methods with proper Vitest mocks
    clearManager.storageManager = {
      getKataProgress: vi.fn(),
      getAllKataProgress: vi.fn(),
      clearKataProgress: vi.fn(),
      clearAssessmentResults: vi.fn(),
      clearUserSettings: vi.fn(),
      clearStoredData: vi.fn()
    };

    clearManager.learningPathManager = {
      clearCache: vi.fn(),
      resetKataState: vi.fn()
    };

    // Store references for easy access in tests
    mockStorageManager = clearManager.storageManager;
    mockLearningPathManager = clearManager.learningPathManager;
  });

  afterEach(() => {
    if (clearManager) {
      clearManager.destroy();
    }
    vi.clearAllMocks();
  });

  describe('Initialization', () => {
    it('should initialize with correct default state', () => {
      expect(clearManager.isClearing).toBe(false);
      expect(clearManager.storageManager).toBeDefined();
      expect(clearManager.learningPathManager).toBeDefined();
    });

    it('should set up event listeners on initialization', () => {
      const addEventListenerSpy = vi.spyOn(document, 'addEventListener');
      const newClearManager = new ProgressClearManager();

      expect(addEventListenerSpy).toHaveBeenCalledWith(
        'progressClearRequested',
        expect.any(Function)
      );

      newClearManager.destroy();
    });

    it('should log initialization message', () => {
      expect(console.log).toHaveBeenCalledWith('ProgressClearManager initialized');
    });
  });

  describe('Clear Request Handling', () => {
    it('should handle clear request event', async () => {
      // Mock successful clear operation
      mockStorageManager.getKataProgress.mockResolvedValue({ item1: true, item2: false });
      mockStorageManager.clearKataProgress.mockResolvedValue();
      mockLearningPathManager.resetKataState.mockImplementation(() => {});
      mockLearningPathManager.clearCache.mockImplementation(() => {});

      const dispatchEventSpy = vi.spyOn(document, 'dispatchEvent');

      // Create clear request event
      const clearEvent = new CustomEvent('progressClearRequested', {
        detail: {
          kataId: 'test-kata',
          timestamp: '2025-09-03T12:00:00.000Z'
        }
      });

      // Trigger the event
      document.dispatchEvent(clearEvent);

      // Wait for async operations
      await new Promise(resolve => setTimeout(resolve, 10));

      // Verify completion event was dispatched
      expect(dispatchEventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'progressClearCompleted',
          detail: expect.objectContaining({
            success: true,
            clearedItems: 2,
            scope: 'current-kata'
          })
        })
      );
    });

    it('should prevent concurrent clear operations', async () => {
      clearManager.isClearing = true;

      const clearEvent = new CustomEvent('progressClearRequested', {
        detail: { kataId: 'test-kata', timestamp: new Date().toISOString() }
      });

      document.dispatchEvent(clearEvent);

      expect(console.warn).toHaveBeenCalledWith('Clear operation already in progress');
    });

    it('should handle errors in clear operation', async () => {
      // Mock error in storage operation
      mockStorageManager.getKataProgress.mockRejectedValue(new Error('Storage error'));

      const dispatchEventSpy = vi.spyOn(document, 'dispatchEvent');

      const clearEvent = new CustomEvent('progressClearRequested', {
        detail: { kataId: 'test-kata', timestamp: new Date().toISOString() }
      });

      document.dispatchEvent(clearEvent);

      // Wait for async operations
      await new Promise(resolve => setTimeout(resolve, 10));

      // Verify error event was dispatched
      expect(dispatchEventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'progressClearCompleted',
          detail: expect.objectContaining({
            success: false,
            error: 'Storage error'
          })
        })
      );
    });
  });

  describe('Clear Scope Determination', () => {
    it('should determine clear scope for current kata', async () => {
      const mockProgress = { item1: true, item2: false, item3: true };
      mockStorageManager.getKataProgress.mockResolvedValue(mockProgress);
      mockStorageManager.getAllKataProgress.mockResolvedValue({
        'test-kata': mockProgress
      });

      const scope = await clearManager.determineClearScope('test-kata');

      expect(scope).toEqual({
        kataId: 'test-kata',
        currentKataOnly: true,
        includeAssessments: false,
        includeSettings: false,
        progressToReset: mockProgress,
        totalItems: 3
      });
    });

    it('should handle kata with no progress', async () => {
      mockStorageManager.getKataProgress.mockResolvedValue(null);
      mockStorageManager.getAllKataProgress.mockResolvedValue({});

      const scope = await clearManager.determineClearScope('empty-kata');

      expect(scope.totalItems).toBe(0);
      expect(scope.progressToReset).toBeNull();
    });
  });

  describe('Progress Clearing Operations', () => {
    it('should clear current kata progress successfully', async () => {
      const clearScope = {
        kataId: 'test-kata',
        currentKataOnly: true,
        totalItems: 3
      };

      mockStorageManager.clearKataProgress.mockResolvedValue();
      mockLearningPathManager.resetKataState.mockImplementation(() => {});
      mockLearningPathManager.clearCache.mockImplementation(() => {});

      const result = await clearManager.clearProgress(clearScope);

      expect(result).toEqual(expect.objectContaining({
        clearedItems: 3,
        scope: 'current-kata',
        errors: []
      }));

      expect(mockStorageManager.clearKataProgress).toHaveBeenCalledWith('test-kata');
    });

    it('should handle errors during progress clearing', async () => {
      const clearScope = {
        kataId: 'test-kata',
        currentKataOnly: true,
        totalItems: 2
      };

      mockStorageManager.clearKataProgress.mockRejectedValue(new Error('Clear failed'));

      await expect(clearManager.clearProgress(clearScope)).rejects.toThrow('Clear failed');
    });
  });

  describe('Kata Progress Clearing', () => {
    it('should clear individual kata progress', async () => {
      mockStorageManager.clearKataProgress.mockResolvedValue();
      mockLearningPathManager.resetKataState.mockImplementation(() => {});

      await clearManager.clearKataProgress('test-kata');

      expect(mockStorageManager.clearKataProgress).toHaveBeenCalledWith('test-kata');
      expect(console.log).toHaveBeenCalledWith('Cleared progress for kata: test-kata');
    });

    it('should handle kata clear errors', async () => {
      mockStorageManager.clearKataProgress.mockRejectedValue(new Error('Remove failed'));

      await expect(clearManager.clearKataProgress('test-kata')).rejects.toThrow('Remove failed');
      expect(console.error).toHaveBeenCalledWith(
        'Failed to clear kata progress for test-kata:',
        expect.any(Error)
      );
    });
  });

  describe('All Progress Clearing', () => {
    it('should clear all progress without assessments or settings', async () => {
      const allProgress = {
        'kata1': { item1: true, item2: false },
        'kata2': { item3: true }
      };

      mockStorageManager.getAllKataProgress.mockResolvedValue(allProgress);
      mockStorageManager.clearKataProgress.mockResolvedValue();
      mockStorageManager.clearStoredData.mockResolvedValue(true);
      mockLearningPathManager.resetKataState.mockImplementation(() => {});

      const clearedCount = await clearManager.clearAllProgressWithOptions(false, false);

      expect(clearedCount).toBe(3); // 2 items from kata1 + 1 item from kata2
      expect(mockStorageManager.clearKataProgress).toHaveBeenCalledTimes(2);
      expect(mockStorageManager.clearAssessmentResults).not.toHaveBeenCalled();
      expect(mockStorageManager.clearUserSettings).not.toHaveBeenCalled();
    });

    it('should clear all progress including assessments and settings', async () => {
      const allProgress = {
        'kata1': { item1: true }
      };

      mockStorageManager.getAllKataProgress.mockResolvedValue(allProgress);
      mockStorageManager.clearKataProgress.mockResolvedValue();
      mockStorageManager.clearAssessmentResults.mockResolvedValue();
      mockStorageManager.clearUserSettings.mockResolvedValue();
      mockStorageManager.clearStoredData.mockResolvedValue(true);
      mockLearningPathManager.resetKataState.mockImplementation(() => {});

      const clearedCount = await clearManager.clearAllProgressWithOptions(true, true);

      expect(clearedCount).toBe(3); // 1 kata item + 1 assessment + 1 settings
      expect(mockStorageManager.clearAssessmentResults).toHaveBeenCalled();
      expect(mockStorageManager.clearUserSettings).toHaveBeenCalled();
    });
  });

  describe('UI State Reset', () => {
    it('should reset checkboxes and progress displays', async () => {
      // Setup DOM with checkboxes and progress elements
      document.body.innerHTML = `
        <input type="checkbox" data-kata-item="item1" checked class="completed">
        <input type="checkbox" data-kata-item="item2" checked class="in-progress">
        <div class="kata-progress-display" style="width: 75%;">75%</div>
        <button class="kata-category-btn selected completed">Category</button>
      `;

      await clearManager.resetUIStates('test-kata');

      // Verify checkboxes are reset
      const checkboxes = document.querySelectorAll('input[type="checkbox"][data-kata-item]');
      checkboxes.forEach(checkbox => {
        expect(checkbox.checked).toBe(false);
        expect(checkbox.classList.contains('completed')).toBe(false);
        expect(checkbox.classList.contains('in-progress')).toBe(false);
      });

      // Verify progress displays are reset
      const progressElements = document.querySelectorAll('.kata-progress-display');
      progressElements.forEach(element => {
        expect(element.textContent).toBe('0%');
        expect(element.style.width).toBe('0%');
      });

      // Verify category buttons are reset
      const categoryButtons = document.querySelectorAll('.kata-category-btn');
      categoryButtons.forEach(button => {
        expect(button.classList.contains('selected')).toBe(false);
        expect(button.classList.contains('completed')).toBe(false);
      });
    });

    it('should handle UI reset errors gracefully', async () => {
      // Mock querySelectorAll to throw an error
      const originalQuerySelectorAll = document.querySelectorAll;
      document.querySelectorAll = vi.fn().mockImplementation(() => {
        throw new Error('DOM error');
      });

      // Should not throw, just log error
      await expect(clearManager.resetUIStates('test-kata')).resolves.not.toThrow();
      expect(console.error).toHaveBeenCalledWith(
        'Failed to reset UI states:',
        expect.any(Error)
      );

      // Restore original method
      document.querySelectorAll = originalQuerySelectorAll;
    });
  });

  describe('Event Notifications', () => {
    it('should notify successful clear completion', () => {
      const dispatchEventSpy = vi.spyOn(document, 'dispatchEvent');
      const result = {
        clearedItems: 5,
        scope: 'current-kata',
        timestamp: '2025-09-03T12:00:00.000Z',
        errors: []
      };

      clearManager.notifyClearCompletion(result);

      expect(dispatchEventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'progressClearCompleted',
          detail: {
            success: true,
            clearedItems: 5,
            scope: 'current-kata',
            timestamp: '2025-09-03T12:00:00.000Z',
            errors: []
          }
        })
      );
    });

    it('should notify clear operation errors', () => {
      const dispatchEventSpy = vi.spyOn(document, 'dispatchEvent');
      const error = new Error('Clear operation failed');

      clearManager.notifyClearError(error);

      expect(dispatchEventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'progressClearCompleted',
          detail: expect.objectContaining({
            success: false,
            error: 'Clear operation failed'
          })
        })
      );
    });
  });

  describe('Utility Methods', () => {
    it('should report clearing status correctly', () => {
      expect(clearManager.isCurrentlyClearing()).toBe(false);

      clearManager.isClearing = true;
      expect(clearManager.isCurrentlyClearing()).toBe(true);
    });

    it('should clean up event listeners on destroy', () => {
      const removeEventListenerSpy = vi.spyOn(document, 'removeEventListener');

      clearManager.destroy();

      expect(removeEventListenerSpy).toHaveBeenCalledWith(
        'progressClearRequested',
        expect.any(Function)
      );
      expect(console.log).toHaveBeenCalledWith('ProgressClearManager destroyed');
    });
  });
});

describe('Singleton Functions', () => {
  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('getProgressClearManager', () => {
    it('should return singleton instance', () => {
      const instance1 = getProgressClearManager();
      const instance2 = getProgressClearManager();

      expect(instance1).toBe(instance2);
      expect(instance1).toBeInstanceOf(ProgressClearManager);

      instance1.destroy();
    });
  });

  describe('initializeProgressClearManager', () => {
    it('should initialize and return clear manager', () => {
      const instance = initializeProgressClearManager();

      expect(instance).toBeInstanceOf(ProgressClearManager);

      instance.destroy();
    });
  });
});
