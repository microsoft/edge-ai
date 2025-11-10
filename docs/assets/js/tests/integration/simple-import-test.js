import { describe, it, expect, beforeEach, vi } from 'vitest';

describe('Simple Import Test', () => {
  beforeEach(() => {
    // Mock console methods
    vi.spyOn(console, 'log').mockImplementation(() => {});
    vi.spyOn(console, 'error').mockImplementation(() => {});
  });

  it('should be able to import ProgressExportManager', async () => {
    const { ProgressExportManager } = await import('../../features/progress-export-manager.js');
    expect(ProgressExportManager).toBeDefined();
    expect(typeof ProgressExportManager).toBe('function');
  });

  it('should be able to import ProgressClearManager', async () => {
    const { ProgressClearManager } = await import('../../features/progress-clear-manager.js');
    expect(ProgressClearManager).toBeDefined();
    expect(typeof ProgressClearManager).toBe('function');
  });

  it('should be able to import FloatingProgressBar', async () => {
    const { FloatingProgressBar } = await import('../../features/interactive-progress.js');
    expect(FloatingProgressBar).toBeDefined();
    expect(typeof FloatingProgressBar).toBe('function');
  });

  it('should be able to create instances with mocked dependencies', async () => {
    const mockStorageManager = {
      saveProgress: vi.fn().mockResolvedValue({ success: true }),
      clearProgress: vi.fn().mockResolvedValue({ success: true }),
      loadProgress: vi.fn().mockResolvedValue({ success: true }),
      exportProgress: vi.fn().mockResolvedValue({ success: true }),
      initialize: vi.fn().mockResolvedValue({ success: true }),
      isInitialized: vi.fn().mockReturnValue(true)
    };

    const { ProgressExportManager } = await import('../../features/progress-export-manager.js');
    const { ProgressClearManager } = await import('../../features/progress-clear-manager.js');
    const { FloatingProgressBar } = await import('../../features/interactive-progress.js');

    expect(() => new ProgressExportManager(mockStorageManager)).not.toThrow();
    expect(() => new ProgressClearManager(mockStorageManager)).not.toThrow();
    expect(() => new FloatingProgressBar()).not.toThrow();
  });
});
