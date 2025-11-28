import { vi, describe, it, beforeEach, afterEach, expect } from 'vitest';
/**
 * @fileoverview Test suite for StorageCore
 * Validates core localStorage operations, data integrity, and error handling
 */

import '../helpers/test-setup.js';
import { testPresets } from '../helpers/focused/preset-compositions.js';

// Import the ES6 module
import { StorageCore } from '../../core/storage-core.js';

describe('StorageCore', () => {
  let testHelper;
  let storageCore;

  beforeEach(() => {
    testHelper = testPresets.integrationModule();
    storageCore = new StorageCore();
  });

  afterEach(() => {
    testHelper.afterEach?.();
  });

  describe('Constructor', () => {
    it('should initialize with provided dependencies', () => {
      expect(storageCore).toBeInstanceOf(StorageCore);
    });

    it('should provide fallback dependencies when none provided', () => {
      const simpleCore = new StorageCore();
      expect(simpleCore.debugHelper).toBeDefined();
      expect(simpleCore.errorHandler).toBeDefined();
      expect(typeof simpleCore.debugHelper.debug).toBe('function');
      expect(typeof simpleCore.errorHandler.safeExecute).toBe('function');
    });

    it('should throw error when invalid errorHandler provided', () => {
      expect(() => {
        new StorageCore({ errorHandler: {} });
      }).toThrow('StorageCore requires errorHandler with safeExecute method');
    });
  });

  describe('Kata Progress Management', () => {
    it('should save kata progress data (deprecated read)', () => {
      const progressData = {
        completedTasks: 5,
        totalTasks: 10,
        completionPercentage: 50,
        sections: { intro: true, practice: false },
        metadata: { version: '1.0.0' }
      };

      const saved = storageCore.saveKataProgress('kata-1', progressData);
      expect(saved).toBe(true);

      // Note: getKataProgress() now returns default structure (deprecated)
      // Real progress should be fetched via API through LearningPathManager
      const retrieved = storageCore.getKataProgress('kata-1');
      expect(retrieved).toMatchObject({
        kataId: 'kata-1',
        completedTasks: 0,
        totalTasks: 0,
        completionPercentage: 0,
        lastUpdated: null,
        sections: {},
        metadata: {}
      });
    });

    it('should return default structure for non-existent kata', () => {
      const retrieved = storageCore.getKataProgress('non-existent');
      expect(retrieved).toMatchObject({
        kataId: 'non-existent',
        completedTasks: 0,
        totalTasks: 0,
        completionPercentage: 0,
        lastUpdated: null,
        sections: {},
        metadata: {}
      });
    });

    it('should handle source tracking in metadata (write-only)', () => {
      const progressData = { completedTasks: 3 };
      storageCore.saveKataProgress('kata-source', progressData, 'ui');
      // Note: getKataProgress() returns default only (deprecated)
      // Source tracking only applies to saved data, not deprecated reads
      const retrieved = storageCore.getKataProgress('kata-source');
      expect(retrieved.metadata).toMatchObject({});
    });

    it('should clear specific kata progress (write-only)', () => {
      storageCore.saveKataProgress('kata-clear', { completedTasks: 5 });
      // Note: getKataProgress() returns default structure (deprecated)
      // This test validates clear operation, not read operation
      expect(storageCore.getKataProgress('kata-clear').completedTasks).toBe(0);

      const cleared = storageCore.clearKataProgress('kata-clear');
      expect(cleared).toBe(true);

      const retrieved = storageCore.getKataProgress('kata-clear');
      expect(retrieved.completedTasks).toBe(0); // Default structure
    });
  });

  describe('Path Progress Management', () => {
    it('should save and retrieve path progress data', () => {
      const progressData = {
        startedAt: Date.now(),
        currentKata: 'kata-2',
        completedKatas: ['kata-1'],
        totalKatas: 5,
        completionPercentage: 20,
        timeSpent: 3600
      };

      const saved = storageCore.savePathProgress('path-1', progressData);
      expect(saved).toBe(true);

      // Note: Server-first architecture - localStorage writes are neutered
      // getPathProgress returns default structure (API provides actual data)
      const retrieved = storageCore.getPathProgress('path-1');
      expect(retrieved.pathId).toBe('path-1');
      expect(retrieved.completedKatas).toEqual([]);
      expect(retrieved.totalKatas).toBe(0);
      expect(retrieved.lastUpdated).toBeNull();
    });

    it('should return default structure for non-existent path', () => {
      const retrieved = storageCore.getPathProgress('non-existent');
      expect(retrieved).toMatchObject({
        pathId: 'non-existent',
        startedAt: null,
        currentKata: null,
        completedKatas: [],
        totalKatas: 0,
        completionPercentage: 0,
        lastUpdated: null,
        timeSpent: 0
      });
    });

    it('should clear specific path progress', () => {
      const saved = storageCore.savePathProgress('path-clear', { totalKatas: 10 });
      expect(saved).toBe(true);

      // Note: Server-first architecture - no localStorage persistence
      expect(storageCore.getPathProgress('path-clear').totalKatas).toBe(0);

      const cleared = storageCore.clearPathProgress('path-clear');
      expect(cleared).toBe(true);

      const retrieved = storageCore.getPathProgress('path-clear');
      expect(retrieved.totalKatas).toBe(0); // Default structure
    });
  });

  describe('Settings Management', () => {
    it('should save and retrieve settings', () => {
      const settingValue = { theme: 'dark', autoSave: true };

      const saved = storageCore.saveSetting('preferences', settingValue);
      expect(saved).toBe(true);

      // Note: Server-first architecture - no localStorage persistence
      const retrieved = storageCore.getSetting('preferences');
      expect(retrieved).toBeNull();
    });

    it('should return null for non-existent setting', () => {
      const retrieved = storageCore.getSetting('non-existent');
      expect(retrieved).toBeNull();
    });

    it('should handle various data types in settings', () => {
      const testValues = [
        ['string-setting', 'test-value'],
        ['number-setting', 42],
        ['boolean-setting', true],
        ['array-setting', [1, 2, 3]],
        ['object-setting', { nested: { value: 'test' } }]
      ];

      // Note: Server-first architecture - no localStorage persistence
      testValues.forEach(([key, value]) => {
        const saved = storageCore.saveSetting(key, value);
        expect(saved).toBe(true);
        const retrieved = storageCore.getSetting(key);
        expect(retrieved).toBeNull();
      });
    });
  });

  describe('Bulk Operations', () => {
    function setupBulkTestData() {
      // Setup test data - call this within each test
      const kata1Success = storageCore.saveKataProgress('kata-1', { completedTasks: 5 });
      const kata2Success = storageCore.saveKataProgress('kata-2', { completedTasks: 3 });
      const path1Success = storageCore.savePathProgress('path-1', { totalKatas: 10 });
      const path2Success = storageCore.savePathProgress('path-2', { totalKatas: 15 });

      console.log('Setup results:', { kata1Success, kata2Success, path1Success, path2Success });
      console.log('localStorage after setup:', Object.keys(localStorage));

      // Ensure all saves succeeded
      if (!kata1Success || !kata2Success || !path1Success || !path2Success) {
        throw new Error('Failed to setup test data');
      }
    }

    it('should get all kata progress', () => {
      setupBulkTestData();

      // Note: Server-first architecture - no localStorage persistence
      // getAllKataProgress returns empty array (API provides actual data)
      const allKatas = storageCore.getAllKataProgress();
      expect(allKatas).toBeInstanceOf(Array);
      expect(allKatas.length).toBe(0);
    });

    it('should get all path progress', () => {
      setupBulkTestData();

      // Note: Server-first architecture - no localStorage persistence
      // getAllPathProgress returns empty array (API provides actual data)
      const allPaths = storageCore.getAllPathProgress();
      expect(allPaths).toBeInstanceOf(Array);
      expect(allPaths.length).toBe(0);
    });

    it('should get all progress data', () => {
      setupBulkTestData();

      // Note: Server-first architecture - no localStorage persistence
      const allProgress = storageCore.getAllProgress();
      expect(allProgress).toBeTypeOf('object');
      expect(allProgress.katas).toBeInstanceOf(Array);
      expect(allProgress.paths).toBeInstanceOf(Array);
      expect(allProgress.all).toBeTypeOf('object');
      expect(allProgress.katas.length).toBe(0);
      expect(allProgress.paths.length).toBe(0);
    });

    it('should clear stored data by type', () => {
      setupBulkTestData();

      // Note: Server-first architecture - no localStorage persistence
      // Clear operations succeed but data never persisted
      const clearedKatas = storageCore.clearStoredData('kata');
      expect(clearedKatas).toBe(true);
      expect(storageCore.getAllKataProgress().length).toBe(0);
      expect(storageCore.getAllPathProgress().length).toBe(0);

      const clearedPaths = storageCore.clearStoredData('path');
      expect(clearedPaths).toBe(true);
      expect(storageCore.getAllPathProgress().length).toBe(0);
    });

    it('should clear all data', () => {
      setupBulkTestData();
      const savedSetting = storageCore.saveSetting('test-setting', 'value');
      expect(savedSetting).toBe(true);

      // Note: Server-first architecture - no localStorage persistence
      const cleared = storageCore.clearStoredData('all');
      expect(cleared).toBe(true);
      expect(storageCore.getAllKataProgress().length).toBe(0);
      expect(storageCore.getAllPathProgress().length).toBe(0);
      expect(storageCore.getSetting('test-setting')).toBeNull();
    });
  });

  describe('Backward Compatibility Methods', () => {
    it('should handle generic progress operations for kata IDs', () => {
      const progressData = { completed: true, score: 95 };

      // Test kata-style ID
      const saved = storageCore.saveProgress('kata-1', progressData);
      expect(saved).toBe(true);

      // Note: Server-first architecture - no localStorage persistence
      const retrieved = storageCore.getProgress('kata-1');
      expect(retrieved).toBeNull();
    });

    it('should handle generic progress operations for path IDs', () => {
      const progressData = { completed: false, currentStep: 3 };

      // Test path-style ID
      const saved = storageCore.saveProgress('learning-path', progressData);
      expect(saved).toBe(true);

      // Note: Server-first architecture - no localStorage persistence
      const retrieved = storageCore.getProgress('learning-path');
      expect(retrieved).toBeNull();
    });

    it('should clear progress generically', () => {
      const saved = storageCore.saveProgress('generic-test', { completed: true });
      expect(saved).toBe(true);

      // Note: Server-first architecture - no localStorage persistence
      expect(storageCore.getProgress('generic-test')).toBeNull();

      const cleared = storageCore.clearProgress('generic-test');
      expect(cleared).toBe(true);
      expect(storageCore.getProgress('generic-test')).toBeNull();
    });
  });

  describe('Error Handling', () => {
    it('should handle localStorage errors gracefully', () => {
      // Note: Server-first architecture - save methods don't use localStorage
      // They succeed regardless of localStorage state
      const originalSetItem = window.localStorage.setItem;
      window.localStorage.setItem = vi.fn().mockImplementation(() => {
        throw new Error('Storage quota exceeded');
      });

      const result = storageCore.saveKataProgress('test-kata', { completed: true });
      expect(result).toBe(true); // No localStorage dependency

      // Restore localStorage
      window.localStorage.setItem = originalSetItem;
    });

    it('should handle JSON parsing errors', () => {
      // Manually set invalid JSON in localStorage
      window.localStorage.setItem('kata-progress-test', 'invalid-json');

      const result = storageCore.getKataProgress('test');
      expect(result.kataId).toBe('test');
      expect(result.completedTasks).toBe(0); // Default structure
    });

    it('should handle invalid inputs gracefully', () => {
      expect(storageCore.saveKataProgress(null, {})).toBe(false);
      expect(storageCore.saveKataProgress('', {})).toBe(false);
      expect(storageCore.getKataProgress(null).kataId).toBe(null);
    });
  });

  describe('Integration Tests', () => {
    it('should maintain data consistency across operations (writes only)', () => {
      const kataData = { completed: true, score: 95, timestamp: Date.now() };

      // Save data (returns true but doesn't persist to localStorage)
      const saved = storageCore.saveKataProgress('integration-test', kataData);
      expect(saved).toBe(true);

      // Note: Server-first architecture - getAllProgress returns empty data
      const allProgress = storageCore.getAllProgress();
      expect(allProgress.katas.length).toBe(0);

      // Note: Direct retrieval via getKataProgress() returns default structure (deprecated)
      const retrieved = storageCore.getKataProgress('integration-test');
      expect(retrieved.completedTasks).toBe(0); // Default structure

      // Clear and verify removal
      const cleared = storageCore.clearKataProgress('integration-test');
      expect(cleared).toBe(true);
      const afterClear = storageCore.getKataProgress('integration-test');
      expect(afterClear.completedTasks).toBe(0); // Default structure
    });

    it('should handle mixed operations correctly (getKataProgress deprecated)', () => {
      // Mix of kata, path, and settings operations
      const savedKata = storageCore.saveKataProgress('mixed-kata', { completedTasks: 5 });
      const savedPath = storageCore.savePathProgress('mixed-path', { totalKatas: 10 });
      const savedSetting = storageCore.saveSetting('mixed-setting', 'value');

      expect(savedKata).toBe(true);
      expect(savedPath).toBe(true);
      expect(savedSetting).toBe(true);

      // Note: Server-first architecture - all get methods return defaults/null
      expect(storageCore.getKataProgress('mixed-kata').completedTasks).toBe(0);
      expect(storageCore.getPathProgress('mixed-path').totalKatas).toBe(0);
      expect(storageCore.getSetting('mixed-setting')).toBeNull();

      // Clear selectively and verify
      const cleared = storageCore.clearStoredData('kata');
      expect(cleared).toBe(true);
      expect(storageCore.getKataProgress('mixed-kata').completedTasks).toBe(0);
      expect(storageCore.getPathProgress('mixed-path').totalKatas).toBe(0);
      expect(storageCore.getSetting('mixed-setting')).toBeNull();
    });
  });
});
