/**
 * Progress Export Manager Tests
 * Comprehensive test suite for progress export functionality
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { ProgressExportManager, ProgressExportManagerSingleton } from '../../features/progress-export-manager.js';

// Mock dependencies
const mockStorageManager = {
  getAllKataProgress: vi.fn(() => []),
  getAllPathProgress: vi.fn(() => []),
  getKataProgress: vi.fn(() => ({})),
  saveToServer: vi.fn()
};

const mockLearningPathManager = {
  getProgress: vi.fn(() => ({ selectionState: {} }))
};

// Mock DOM APIs
const mockBlob = vi.fn();
const mockURL = {
  createObjectURL: vi.fn(() => 'mock-url'),
  revokeObjectURL: vi.fn()
};

global.Blob = mockBlob;
global.URL = mockURL;

// Mock clipboard API
global.navigator = {
  ...global.navigator,
  clipboard: {
    writeText: vi.fn()
  }
};

describe('ProgressExportManager', () => {
  let exportManager;
  let eventSpy;

  beforeEach(() => {
    // Reset DOM
    document.body.innerHTML = '';

    // Create fresh export manager
    exportManager = new ProgressExportManager(mockStorageManager, mockLearningPathManager);

    // Mock event handling
    eventSpy = vi.spyOn(document, 'dispatchEvent');

    // Reset all mocks
    vi.clearAllMocks();
    mockBlob.mockImplementation((content, _options) => ({
      size: content[0].length
    }));
  });

  afterEach(() => {
    if (exportManager) {
      exportManager.destroy();
    }
    vi.restoreAllMocks();
  });

  describe('Initialization', () => {
    it('should initialize with storage and learning path managers', () => {
      expect(exportManager.storageManager).toBe(mockStorageManager);
      expect(exportManager.learningPathManager).toBe(mockLearningPathManager);
      expect(exportManager.isInitialized).toBe(true);
    });

    it('should initialize without dependencies', () => {
      const manager = new ProgressExportManager();
      expect(manager.storageManager).toBeNull();
      expect(manager.learningPathManager).toBeNull();
      expect(manager.isInitialized).toBe(true);
    });

    it('should set up event listeners', () => {
      const listenerSpy = vi.spyOn(document, 'addEventListener');
      const manager = new ProgressExportManager();

      expect(listenerSpy).toHaveBeenCalledWith('progressSaveRequested', expect.any(Function));
    });
  });

  describe('Save Request Handling', () => {
    it('should handle basic save request', async () => {
      const saveData = {
        kataId: 'test-kata',
        exportFormat: 'json',
        exportTarget: 'download'
      };

      await exportManager.handleSaveRequest(saveData);

      expect(eventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'progressSaveCompleted',
          detail: expect.objectContaining({
            success: true
          })
        })
      );
    });

    it('should handle save request with default options', async () => {
      const saveData = { kataId: 'test-kata' };

      await exportManager.handleSaveRequest(saveData);

      expect(eventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'progressSaveCompleted',
          detail: expect.objectContaining({
            success: true
          })
        })
      );
    });

    it('should handle errors in save request', async () => {
      // Mock error in save operation
      mockStorageManager.getAllKataProgress.mockImplementation(() => {
        throw new Error('Storage error');
      });

      const saveData = { kataId: 'test-kata' };

      await exportManager.handleSaveRequest(saveData);

      expect(eventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'progressSaveCompleted',
          detail: expect.objectContaining({
            success: false,
            result: expect.objectContaining({
              error: 'Storage error'
            })
          })
        })
      );
    });
  });

  describe('Progress Data Collection', () => {
    it('should collect comprehensive progress data', async () => {
      const mockKataProgress = [
        { kataId: 'kata-1', completedTasks: 5, totalTasks: 10, completionPercentage: 50 },
        { kataId: 'kata-2', completedTasks: 10, totalTasks: 10, completionPercentage: 100 }
      ];
      const mockPathProgress = [
        { pathId: 'path-1', completionPercentage: 75 }
      ];
      const mockSelections = { 'item-1': true, 'item-2': false };

      mockStorageManager.getAllKataProgress.mockReturnValue(mockKataProgress);
      mockStorageManager.getAllPathProgress.mockReturnValue(mockPathProgress);
      mockStorageManager.getKataProgress.mockReturnValue(mockKataProgress[0]);
      mockLearningPathManager.getProgress.mockReturnValue({ selectionState: mockSelections });

      const progressData = await exportManager.getComprehensiveProgressData('kata-1');

      expect(progressData).toEqual(expect.objectContaining({
        metadata: expect.objectContaining({
          exportedAt: expect.any(String),
          exportVersion: '1.0.0',
          sourceKata: 'kata-1'
        }),
        currentKata: mockKataProgress[0],
        allKataProgress: mockKataProgress,
        pathProgress: mockPathProgress,
        learningPathSelections: mockSelections,
        totalStats: expect.objectContaining({
          totalKatas: 2,
          completedKatas: 1,
          totalTasks: 20,
          completedTasks: 15,
          overallCompletionPercentage: 75
        })
      }));
    });

    it('should handle missing dependencies gracefully', async () => {
      const manager = new ProgressExportManager();
      const progressData = await manager.getComprehensiveProgressData('kata-1');

      expect(progressData).toEqual(expect.objectContaining({
        metadata: expect.any(Object),
        currentKata: {},
        allKataProgress: [],
        pathProgress: [],
        learningPathSelections: {},
        totalStats: expect.objectContaining({
          totalKatas: 0,
          completedKatas: 0,
          totalTasks: 0,
          completedTasks: 0,
          overallCompletionPercentage: 0
        })
      }));
    });
  });

  describe('Statistics Calculation', () => {
    it('should calculate accurate total statistics', () => {
      const progressData = {
        allKataProgress: [
          { kataId: 'kata-1', totalTasks: 10, completedTasks: 5, completionPercentage: 50 },
          { kataId: 'kata-2', totalTasks: 8, completedTasks: 8, completionPercentage: 100 },
          { kataId: 'kata-3', totalTasks: 12, completedTasks: 0, completionPercentage: 0 }
        ],
        pathProgress: [
          { pathId: 'path-1', completionPercentage: 100 },
          { pathId: 'path-2', completionPercentage: 50 }
        ]
      };

      const stats = exportManager.calculateTotalStats(progressData);

      expect(stats).toEqual({
        totalKatas: 3,
        completedKatas: 1,
        totalTasks: 30,
        completedTasks: 13,
        overallCompletionPercentage: 43,
        activeKatas: 2,
        totalPaths: 2,
        completedPaths: 1
      });
    });

    it('should handle empty progress data', () => {
      const progressData = {
        allKataProgress: [],
        pathProgress: []
      };

      const stats = exportManager.calculateTotalStats(progressData);

      expect(stats).toEqual({
        totalKatas: 0,
        completedKatas: 0,
        totalTasks: 0,
        completedTasks: 0,
        overallCompletionPercentage: 0,
        activeKatas: 0,
        totalPaths: 0,
        completedPaths: 0
      });
    });
  });

  describe('Download Export', () => {
    let mockLink;

    beforeEach(() => {
      mockLink = {
        href: '',
        download: '',
        click: vi.fn()
      };
      vi.spyOn(document, 'createElement').mockReturnValue(mockLink);
      vi.spyOn(document.body, 'appendChild').mockImplementation(() => {});
      vi.spyOn(document.body, 'removeChild').mockImplementation(() => {});
    });

    it('should save as JSON download', () => {
      const progressData = { test: 'data' };
      const result = exportManager.saveAsDownload(progressData, 'json');

      expect(mockBlob).toHaveBeenCalledWith(
        [JSON.stringify(progressData, null, 2)],
        { type: 'application/json' }
      );
      expect(mockLink.click).toHaveBeenCalled();
      expect(result).toEqual(expect.objectContaining({
        success: true,
        format: 'json',
        filename: expect.stringMatching(/learning-progress-.*\.json/)
      }));
    });

    it('should save as CSV download', () => {
      const progressData = {
        allKataProgress: [
          { kataId: 'kata-1', totalTasks: 10, completedTasks: 5, completionPercentage: 50 }
        ],
        totalStats: { totalKatas: 1, completedKatas: 0, totalTasks: 10, completedTasks: 5, overallCompletionPercentage: 50 }
      };

      const result = exportManager.saveAsDownload(progressData, 'csv');

      expect(mockBlob).toHaveBeenCalledWith(
        [expect.stringContaining('Kata ID,Total Tasks,Completed Tasks,Completion %,Last Updated')],
        { type: 'text/csv' }
      );
      expect(result.format).toBe('csv');
    });

    it('should save as text download', () => {
      const progressData = {
        metadata: { exportedAt: '2025-01-01T00:00:00Z', sourceKata: 'test-kata' },
        totalStats: { totalKatas: 1, completedKatas: 0, totalTasks: 10, completedTasks: 5, overallCompletionPercentage: 50 },
        allKataProgress: []
      };

      const result = exportManager.saveAsDownload(progressData, 'txt');

      expect(mockBlob).toHaveBeenCalledWith(
        [expect.stringContaining('Learning Progress Export')],
        { type: 'text/plain' }
      );
      expect(result.format).toBe('txt');
    });

    it('should throw error for unsupported format', () => {
      const progressData = { test: 'data' };

      expect(() => {
        exportManager.saveAsDownload(progressData, 'unsupported');
      }).toThrow('Unsupported format: unsupported');
    });
  });

  describe('LocalStorage Backup', () => {
    beforeEach(() => {
      // Mock localStorage
      global.localStorage = {
        setItem: vi.fn(),
        getItem: vi.fn(),
        removeItem: vi.fn(),
        length: 0,
        key: vi.fn()
      };
    });

    it('should save to localStorage backup', () => {
      const progressData = { test: 'data' };
      const result = exportManager.saveToLocalStorage(progressData);

      expect(localStorage.setItem).toHaveBeenCalledWith(
        expect.stringMatching(/progress-backup-\d+/),
        expect.stringContaining('"test":"data"')
      );
      expect(result).toEqual(expect.objectContaining({
        success: true,
        backupKey: expect.stringMatching(/progress-backup-\d+/)
      }));
    });
  });

  describe('Clipboard Export', () => {
    it('should save JSON to clipboard', async () => {
      const progressData = { test: 'data' };
      const result = await exportManager.saveToClipboard(progressData, 'json');

      expect(navigator.clipboard.writeText).toHaveBeenCalledWith(
        JSON.stringify(progressData, null, 2)
      );
      expect(result).toEqual(expect.objectContaining({
        success: true,
        destination: 'clipboard',
        format: 'json'
      }));
    });

    it('should save text to clipboard', async () => {
      const progressData = {
        metadata: { exportedAt: '2025-01-01T00:00:00Z', sourceKata: 'test-kata' },
        totalStats: { totalKatas: 1, completedKatas: 0, totalTasks: 10, completedTasks: 5, overallCompletionPercentage: 50 },
        allKataProgress: []
      };

      const result = await exportManager.saveToClipboard(progressData, 'txt');

      expect(navigator.clipboard.writeText).toHaveBeenCalledWith(
        expect.stringContaining('Learning Progress Export')
      );
      expect(result.format).toBe('txt');
    });
  });

  describe('Format Conversion', () => {
    it('should convert to CSV format correctly', () => {
      const progressData = {
        allKataProgress: [
          { kataId: 'kata-1', totalTasks: 10, completedTasks: 5, completionPercentage: 50, lastUpdated: '2025-01-01' },
          { kataId: 'kata-2', totalTasks: 8, completedTasks: 8, completionPercentage: 100, lastUpdated: '2025-01-02' }
        ],
        totalStats: { totalKatas: 2, completedKatas: 1, totalTasks: 18, completedTasks: 13, overallCompletionPercentage: 72 }
      };

      const csv = exportManager.convertToCSV(progressData);

      expect(csv).toContain('Kata ID,Total Tasks,Completed Tasks,Completion %,Last Updated');
      expect(csv).toContain('kata-1,10,5,50,2025-01-01');
      expect(csv).toContain('kata-2,8,8,100,2025-01-02');
      expect(csv).toContain('Total Katas,2');
      expect(csv).toContain('Overall Completion %,72');
    });

    it('should convert to text format correctly', () => {
      const progressData = {
        metadata: { exportedAt: '2025-01-01T00:00:00Z', sourceKata: 'test-kata' },
        totalStats: { totalKatas: 2, completedKatas: 1, totalTasks: 18, completedTasks: 13, overallCompletionPercentage: 72 },
        allKataProgress: [
          { kataId: 'kata-1', totalTasks: 10, completedTasks: 5, completionPercentage: 50 },
          { kataId: 'kata-2', totalTasks: 8, completedTasks: 8, completionPercentage: 100 }
        ]
      };

      const text = exportManager.convertToText(progressData);

      expect(text).toContain('Learning Progress Export');
      expect(text).toContain('Exported: 2025-01-01T00:00:00Z');
      expect(text).toContain('Source Kata: test-kata');
      expect(text).toContain('Total Katas: 2');
      expect(text).toContain('Overall Completion: 72%');
      expect(text).toContain('kata-1: 5/10 tasks (50%)');
      expect(text).toContain('kata-2: 8/8 tasks (100%)');
    });
  });

  describe('Backup Management', () => {
    beforeEach(() => {
      global.localStorage = {
        length: 3,
        key: vi.fn((index) => {
          const keys = ['progress-backup-1', 'other-key', 'progress-backup-2'];
          return keys[index];
        }),
        getItem: vi.fn((key) => {
          if (key === 'progress-backup-1') {
            return JSON.stringify({ backupInfo: { createdAt: '2025-01-01T00:00:00Z', type: 'manual-backup' } });
          }
          if (key === 'progress-backup-2') {
            return JSON.stringify({ backupInfo: { createdAt: '2025-01-02T00:00:00Z', type: 'manual-backup' } });
          }
          return null;
        }),
        removeItem: vi.fn()
      };
    });

    it('should get available backups', () => {
      const backups = exportManager.getAvailableBackups();

      expect(backups).toHaveLength(2);
      expect(backups[0]).toEqual(expect.objectContaining({
        key: 'progress-backup-2',
        createdAt: '2025-01-02T00:00:00Z',
        type: 'manual-backup'
      }));
      expect(backups[1]).toEqual(expect.objectContaining({
        key: 'progress-backup-1',
        createdAt: '2025-01-01T00:00:00Z',
        type: 'manual-backup'
      }));
    });

    it('should clean up old backups', () => {
      // Mock 7 backups (should keep 5, remove 2)
      localStorage.length = 7;
      localStorage.key = vi.fn((index) => `progress-backup-${index + 1}`);
      localStorage.getItem = vi.fn((key) => {
        const match = key.match(/progress-backup-(\d+)/);
        if (match) {
          const num = parseInt(match[1]);
          return JSON.stringify({
            backupInfo: {
              createdAt: `2025-01-0${num}T00:00:00Z`,
              type: 'manual-backup'
            }
          });
        }
        return null;
      });

      exportManager.cleanupOldBackups();

      // Should remove the 2 oldest backups
      expect(localStorage.removeItem).toHaveBeenCalledWith('progress-backup-1');
      expect(localStorage.removeItem).toHaveBeenCalledWith('progress-backup-2');
      expect(localStorage.removeItem).toHaveBeenCalledTimes(2);
    });
  });
});

describe('ProgressExportManagerSingleton', () => {
  let singleton;

  beforeEach(() => {
    // Reset singleton
    ProgressExportManagerSingleton.instance = null;
    singleton = new ProgressExportManagerSingleton();
  });

  afterEach(() => {
    if (singleton) {
      singleton.destroy();
    }
  });

  it('should return the same instance', () => {
    const singleton1 = new ProgressExportManagerSingleton();
    const singleton2 = new ProgressExportManagerSingleton();

    expect(singleton1).toBe(singleton2);
  });

  it('should initialize export manager', () => {
    const exportManager = singleton.initialize(mockStorageManager, mockLearningPathManager);

    expect(exportManager).toBeInstanceOf(ProgressExportManager);
    expect(singleton.isInitialized).toBe(true);
    expect(singleton.getExportManager()).toBe(exportManager);
  });

  it('should handle multiple initialization calls', () => {
    const manager1 = singleton.initialize(mockStorageManager, mockLearningPathManager);
    const manager2 = singleton.initialize();

    expect(manager1).toBe(manager2);
    expect(singleton.isInitialized).toBe(true);
  });
});
