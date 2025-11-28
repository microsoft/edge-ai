/**
 * Simple test for FloatingProgressBar Component
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { FloatingProgressBar, ProgressBarManager } from '../../features/interactive-progress.js';

// Mock confirm dialog
global.confirm = vi.fn();

describe('FloatingProgressBar - Basic', () => {
  let progressBar;

  beforeEach(() => {
    // Reset DOM
    document.body.innerHTML = '';
    document.body.className = '';

    // Create fresh progress bar instance
    progressBar = new FloatingProgressBar();

    // Reset mocks
    vi.clearAllMocks();
    global.confirm.mockReturnValue(true);
  });

  afterEach(() => {
    if (progressBar) {
      progressBar.destroy();
    }
  });

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
  });
});

describe('ProgressBarManager - Basic', () => {
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

  it('should return the same instance', () => {
    const manager1 = new ProgressBarManager();
    const manager2 = new ProgressBarManager();

    expect(manager1).toBe(manager2);
  });

  it('should initialize progress bar', () => {
    const progressBar = manager.initialize();

    expect(progressBar).toBeInstanceOf(FloatingProgressBar);
    expect(manager.isInitialized).toBe(true);
    expect(manager.getProgressBar()).toBe(progressBar);
  });
});
