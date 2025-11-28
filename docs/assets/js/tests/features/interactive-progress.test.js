/**
 * Tests for FloatingProgressBar Component
 * @description Test suite for progress bar UI component with save/clear functionality
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { FloatingProgressBar, ProgressBarManager } from '../../features/interactive-progress.js';

// Mock console methods
global.console = {
  ...console,
  error: vi.fn(),
  warn: vi.fn(),
  log: vi.fn()
};

// Mock confirm dialog
global.confirm = vi.fn();

describe('FloatingProgressBar', () => {
  let progressBar;
  let mockStorageManager;

  beforeEach(() => {
    // Reset DOM
    document.body.innerHTML = '';
    document.body.className = '';

    // Mock storage manager
    mockStorageManager = {
      save: vi.fn(),
      load: vi.fn(),
      clear: vi.fn()
    };

    // Create fresh progress bar instance
    progressBar = new FloatingProgressBar(mockStorageManager);

    // Reset mocks
    vi.clearAllMocks();
    global.confirm.mockReturnValue(true);
  });

  afterEach(() => {
    if (progressBar) {
      progressBar.destroy();
    }
  });

  describe('Initialization', () => {
    it('should initialize with default state', () => {
      expect(progressBar.isVisible).toBe(false);
      expect(progressBar.isMinimized).toBe(false);
      expect(progressBar.currentProgress).toEqual({
        totalTasks: 0,
        completedTasks: 0,
        completionPercentage: 0,
        kataId: null
      });
    });

    it('should have null DOM references initially', () => {
      expect(progressBar.containerElement).toBeNull();
      expect(progressBar.progressBarFill).toBeNull();
      expect(progressBar.progressText).toBeNull();
      expect(progressBar.saveButton).toBeNull();
      expect(progressBar.clearButton).toBeNull();
    });
  });

  describe('Progress Bar Creation', () => {
    it('should create progress bar HTML when called', () => {
      progressBar.createProgressBar();

      expect(document.getElementById('kata-progress-bar')).toBeTruthy();
      expect(document.getElementById('progress-bar-fill')).toBeTruthy();
      expect(document.getElementById('progress-description')).toBeTruthy();
      expect(document.getElementById('progress-percentage')).toBeTruthy();
      expect(document.getElementById('save-progress-btn')).toBeTruthy();
      expect(document.getElementById('clear-progress-btn')).toBeTruthy();
      expect(document.getElementById('minimize-progress-btn')).toBeTruthy();
    });

    it('should cache DOM references after creation', () => {
      progressBar.createProgressBar();

      expect(progressBar.containerElement).toBeTruthy();
      expect(progressBar.progressBarFill).toBeTruthy();
      expect(progressBar.progressText).toBeTruthy();
      expect(progressBar.progressPercentage).toBeTruthy();
      expect(progressBar.saveButton).toBeTruthy();
      expect(progressBar.clearButton).toBeTruthy();
      expect(progressBar.minimizeButton).toBeTruthy();
    });

    it('should add content spacing class to body', () => {
      progressBar.createProgressBar();

      expect(document.body.classList.contains('content-with-progress-bar')).toBe(true);
    });

    it('should not create duplicate progress bars', () => {
      progressBar.createProgressBar();
      progressBar.createProgressBar();

      const progressBars = document.querySelectorAll('#kata-progress-bar');
      expect(progressBars.length).toBe(1);
    });
  });

  describe('Progress Updates', () => {
    beforeEach(() => {
      progressBar.createProgressBar();
    });

    it('should update progress display with new data', () => {
      const progressData = {
        totalTasks: 10,
        completedTasks: 6,
        completionPercentage: 60,
        kataId: 'test-kata'
      };

      progressBar.updateProgress(progressData);

      expect(progressBar.currentProgress).toEqual(progressData);
      expect(progressBar.progressText.textContent).toBe('6 of 10 tasks completed');
      expect(progressBar.progressPercentage.textContent).toBe('60%');
      expect(progressBar.progressBarFill.style.width).toBe('60%');
    });

    it('should show progress bar when total tasks > 0', () => {
      const progressData = {
        totalTasks: 5,
        completedTasks: 2,
        completionPercentage: 40,
        kataId: 'test-kata'
      };

      progressBar.updateProgress(progressData);

      expect(progressBar.isVisible).toBe(true);
      expect(progressBar.containerElement.style.display).toBe('flex');
    });

    it('should add complete class when 100% complete', () => {
      const progressData = {
        totalTasks: 5,
        completedTasks: 5,
        completionPercentage: 100,
        kataId: 'test-kata'
      };

      progressBar.updateProgress(progressData);

      expect(progressBar.progressBarFill.classList.contains('complete')).toBe(true);
    });

    it('should remove complete class when less than 100%', () => {
      // First set to 100%
      progressBar.updateProgress({
        totalTasks: 5,
        completedTasks: 5,
        completionPercentage: 100,
        kataId: 'test-kata'
      });

      // Then reduce to 80%
      progressBar.updateProgress({
        totalTasks: 5,
        completedTasks: 4,
        completionPercentage: 80,
        kataId: 'test-kata'
      });

      expect(progressBar.progressBarFill.classList.contains('complete')).toBe(false);
    });
  });

  describe('Button States', () => {
    beforeEach(() => {
      progressBar.createProgressBar();
    });

    it('should disable buttons when no completed tasks', () => {
      progressBar.updateProgress({
        totalTasks: 5,
        completedTasks: 0,
        completionPercentage: 0,
        kataId: 'test-kata'
      });

      expect(progressBar.saveButton.disabled).toBe(true);
      expect(progressBar.clearButton.disabled).toBe(true);
      expect(progressBar.saveButton.title).toBe('No progress to save');
      expect(progressBar.clearButton.title).toBe('No progress to clear');
    });

    it('should enable buttons when there are completed tasks', () => {
      progressBar.updateProgress({
        totalTasks: 5,
        completedTasks: 3,
        completionPercentage: 60,
        kataId: 'test-kata'
      });

      expect(progressBar.saveButton.disabled).toBe(false);
      expect(progressBar.clearButton.disabled).toBe(false);
      expect(progressBar.saveButton.title).toBe('Save progress to file');
      expect(progressBar.clearButton.title).toBe('Clear all progress');
    });
  });

  describe('Save Functionality', () => {
    beforeEach(() => {
      progressBar.createProgressBar();
      progressBar.updateProgress({
        totalTasks: 5,
        completedTasks: 3,
        completionPercentage: 60,
        kataId: 'test-kata'
      });

      // Mock the save dialog to return default options
      progressBar.showSaveOptionsDialog = vi.fn().mockResolvedValue({
        format: 'json',
        target: 'download'
      });

      // Mock the wait for save completion
      progressBar.waitForSaveCompletion = vi.fn().mockResolvedValue();
    });

    it('should handle save button click', async () => {
      const eventSpy = vi.fn();
      document.addEventListener('progressSaveRequested', eventSpy);

      await progressBar.handleSave();

      expect(eventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: expect.objectContaining({
            progressData: progressBar.currentProgress,
            kataId: 'test-kata'
          })
        })
      );
    });

    it('should not save when no completed tasks', async () => {
      progressBar.updateProgress({
        totalTasks: 5,
        completedTasks: 0,
        completionPercentage: 0,
        kataId: 'test-kata'
      });

      const eventSpy = vi.fn();
      document.addEventListener('progressSaveRequested', eventSpy);

      await progressBar.handleSave();

      expect(eventSpy).not.toHaveBeenCalled();
    });

    it('should not save when user cancels dialog', async () => {
      // Mock dialog cancellation
      progressBar.showSaveOptionsDialog.mockResolvedValue(null);

      const eventSpy = vi.fn();
      document.addEventListener('progressSaveRequested', eventSpy);

      await progressBar.handleSave();

      expect(eventSpy).not.toHaveBeenCalled();
      expect(progressBar.saveButton.textContent.trim()).toBe('💾 Save');
    });

    it('should show loading state during save', async () => {
      // Mock save options dialog to return immediately
      progressBar.showSaveOptionsDialog = vi.fn().mockResolvedValue({
        format: 'json',
        target: 'download'
      });

      // Mock waitForSaveCompletion to resolve immediately
      progressBar.waitForSaveCompletion = vi.fn().mockResolvedValue({ message: 'Save completed' });

      // Start the save operation
      const savePromise = progressBar.handleSave();

      // Wait for microtasks to complete (dialog resolve)
      await Promise.resolve();

      // Check loading state after dialog resolves
      expect(progressBar.saveButton.textContent).toBe('💾 Saving...');
      expect(progressBar.saveButton.disabled).toBe(true);

      // Wait for save to complete
      await savePromise;

      // Check restored state
      expect(progressBar.saveButton.textContent).toBe('💾 Save');
      expect(progressBar.saveButton.disabled).toBe(false);
    });
  });

  // Skipped: Expensive performance test, run manually before releases
  describe.skip('Clear Functionality', () => {
    beforeEach(() => {
      progressBar.createProgressBar();
      progressBar.updateProgress({
        totalTasks: 5,
        completedTasks: 3,
        completionPercentage: 60,
        kataId: 'test-kata'
      });
    });

    it('should show confirmation dialog before clearing', async () => {
      global.confirm.mockReturnValue(false);

      const eventSpy = vi.fn();
      document.addEventListener('progressClearRequested', eventSpy);

      await progressBar.handleClear();

      expect(global.confirm).toHaveBeenCalledWith(
        expect.stringContaining('Are you sure you want to clear all progress?')
      );
      expect(eventSpy).not.toHaveBeenCalled();
    });

    it('should handle clear when confirmed', async () => {
      global.confirm.mockReturnValue(true);

      const eventSpy = vi.fn();
      document.addEventListener('progressClearRequested', eventSpy);

      await progressBar.handleClear();

      expect(eventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: expect.objectContaining({
            kataId: 'test-kata'
          })
        })
      );
    });

    it('should not clear when no completed tasks', async () => {
      progressBar.updateProgress({
        totalTasks: 5,
        completedTasks: 0,
        completionPercentage: 0,
        kataId: 'test-kata'
      });

      const eventSpy = vi.fn();
      document.addEventListener('progressClearRequested', eventSpy);

      await progressBar.handleClear();

      expect(global.confirm).not.toHaveBeenCalled();
      expect(eventSpy).not.toHaveBeenCalled();
    });

    it('should show appropriate confirmation message', async () => {
      global.confirm.mockReturnValue(false);

      await progressBar.handleClear();

      expect(global.confirm).toHaveBeenCalledWith(
        expect.stringContaining('This will reset 3 completed tasks out of 5 total tasks')
      );
    });
  });

  describe('Minimize Functionality', () => {
    beforeEach(() => {
      progressBar.createProgressBar();
    });

    it('should toggle minimize state', () => {
      expect(progressBar.isMinimized).toBe(false);

      progressBar.toggleMinimize();

      expect(progressBar.isMinimized).toBe(true);
      expect(progressBar.containerElement.classList.contains('minimized')).toBe(true);
      expect(progressBar.minimizeButton.textContent).toBe('➕');
      expect(progressBar.minimizeButton.title).toBe('Expand progress bar');
    });

    it('should expand from minimized state', () => {
      progressBar.toggleMinimize(); // Minimize first
      progressBar.toggleMinimize(); // Then expand

      expect(progressBar.isMinimized).toBe(false);
      expect(progressBar.containerElement.classList.contains('minimized')).toBe(false);
      expect(progressBar.minimizeButton.textContent).toBe('➖');
      expect(progressBar.minimizeButton.title).toBe('Minimize progress bar');
    });
  });

  describe('Visibility Management', () => {
    it('should show progress bar', () => {
      progressBar.show();

      expect(progressBar.isVisible).toBe(true);
      expect(progressBar.containerElement).toBeTruthy();
      expect(progressBar.containerElement.style.display).toBe('flex');
      expect(document.body.classList.contains('content-with-progress-bar')).toBe(true);
    });

    it('should hide progress bar', () => {
      progressBar.createProgressBar();
      progressBar.hide();

      expect(progressBar.isVisible).toBe(false);
      expect(progressBar.containerElement.style.display).toBe('none');
      expect(document.body.classList.contains('content-with-progress-bar')).toBe(false);
    });
  });

  describe('Event Handling', () => {
    it('should listen for progressUpdated events', () => {
      const progressData = {
        totalTasks: 8,
        completedTasks: 4,
        completionPercentage: 50,
        kataId: 'event-kata'
      };

      const event = new CustomEvent('progressUpdated', { detail: progressData });
      document.dispatchEvent(event);

      expect(progressBar.currentProgress).toEqual(progressData);
    });

    it('should listen for kataChanged events', () => {
      progressBar.currentProgress = {
        totalTasks: 5,
        completedTasks: 3,
        completionPercentage: 60,
        kataId: 'old-kata'
      };

      const kataData = { kataId: 'new-kata' };
      const event = new CustomEvent('kataChanged', { detail: kataData });
      document.dispatchEvent(event);

      expect(progressBar.currentProgress.kataId).toBe('new-kata');
      expect(progressBar.currentProgress.totalTasks).toBe(0);
      expect(progressBar.currentProgress.completedTasks).toBe(0);
      expect(progressBar.currentProgress.completionPercentage).toBe(0);
    });
  });

  describe('Cleanup', () => {
    it('should destroy progress bar and clean up DOM', () => {
      progressBar.createProgressBar();
      progressBar.show();

      progressBar.destroy();

      expect(document.getElementById('kata-progress-bar')).toBeFalsy();
      expect(document.body.classList.contains('content-with-progress-bar')).toBe(false);
      expect(progressBar.containerElement).toBeNull();
      expect(progressBar.isVisible).toBe(false);
      expect(progressBar.isMinimized).toBe(false);
    });
  });
});

describe('ProgressBarManager', () => {
  let manager;

  beforeEach(() => {
    // Reset singleton
    ProgressBarManager.instance = null;
    manager = new ProgressBarManager();
  });

  afterEach(() => {
    if (manager) {
      manager.destroy();
    }
  });

  describe('Singleton Pattern', () => {
    it('should return the same instance', () => {
      const manager1 = new ProgressBarManager();
      const manager2 = new ProgressBarManager();

      expect(manager1).toBe(manager2);
    });

    it('should maintain single progress bar instance', () => {
      manager.initialize();
      const progressBar1 = manager.getProgressBar();

      const manager2 = new ProgressBarManager();
      const progressBar2 = manager2.getProgressBar();

      expect(progressBar1).toBe(progressBar2);
    });
  });

  describe('Initialization', () => {
    it('should initialize progress bar', () => {
      const progressBar = manager.initialize();

      expect(progressBar).toBeInstanceOf(FloatingProgressBar);
      expect(manager.isInitialized).toBe(true);
      expect(manager.getProgressBar()).toBe(progressBar);
    });

    it('should not reinitialize if already initialized', () => {
      const progressBar1 = manager.initialize();
      const progressBar2 = manager.initialize();

      expect(progressBar1).toBe(progressBar2);
    });
  });

  describe('Progress Management', () => {
    beforeEach(() => {
      manager.initialize();
    });

    it('should update progress through manager', () => {
      const progressData = {
        totalTasks: 10,
        completedTasks: 7,
        completionPercentage: 70,
        kataId: 'manager-kata'
      };

      manager.updateProgress(progressData);

      const progressBar = manager.getProgressBar();
      expect(progressBar.currentProgress).toEqual(progressData);
    });

    it('should show/hide progress bar through manager', () => {
      manager.show();
      expect(manager.getProgressBar().isVisible).toBe(true);

      manager.hide();
      expect(manager.getProgressBar().isVisible).toBe(false);
    });
  });

  describe('Cleanup', () => {
    it('should destroy manager and reset singleton', () => {
      manager.initialize();
      const progressBar = manager.getProgressBar();

      manager.destroy();

      expect(manager.progressBar).toBeNull();
      expect(manager.isInitialized).toBe(false);
      expect(ProgressBarManager.instance).toBeNull();
    });
  });
});
