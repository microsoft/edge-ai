import { vi, describe, it, beforeEach, afterEach, expect } from 'vitest';
/**
 * @fileoverview Test suite for StorageManager
 * Validates localStorage operations, data integrity, and error handling
 */

import '../helpers/test-setup.js';
import { testPresets } from '../helpers/focused/preset-compositions.js';

// Import the ES6 module
import { StorageManager } from '../../core/storage-manager.js';

describe('StorageManager', () => {
  let testHelper;
  let storageManager;

  beforeEach(() => {
    testHelper = testPresets.componentModule();
    storageManager = new StorageManager();
  });

  afterEach(() => {
    testHelper.afterEach?.();
  });

  describe('Constructor', () => {
    it('should initialize with provided dependencies', () => {
      expect(storageManager).toBeInstanceOf(StorageManager);
    });

    it('should provide fallback dependencies when none provided', () => {
      const simpleManager = new StorageManager();
      expect(simpleManager.debugHelper).toBeDefined();
      expect(simpleManager.errorHandler).toBeDefined();
      expect(typeof simpleManager.debugHelper.debug).toBe('function');
      expect(typeof simpleManager.errorHandler.safeExecute).toBe('function');
    });
  });

  describe('Progress Management', () => {
    it('should save and retrieve progress data', () => {
      const progressData = {
        completed: true,
        timestamp: Date.now(),
        steps: ['step1', 'step2']
      };

      const saved = storageManager.saveProgress('test-kata', progressData);
      expect(saved).toBe(true);

      const retrieved = storageManager.getProgress('test-kata');
      expect(retrieved).toMatchObject(progressData);
    });

    it('should handle invalid kata IDs gracefully', () => {
      const result = storageManager.saveProgress(null, { completed: true });
      expect(result).toBe(false);

      const retrieved = storageManager.getProgress('');
      expect(retrieved).toBeNull();
    });

    it('should clear progress data', () => {
      storageManager.saveProgress('test-kata', { completed: true });
      expect(storageManager.getProgress('test-kata')).not.toBeNull();

      const cleared = storageManager.clearProgress('test-kata');
      expect(cleared).toBe(true);
      expect(storageManager.getProgress('test-kata')).toBeNull();
    });

    it('should get all progress data', () => {
      storageManager.saveProgress('kata1', { completed: true });
      storageManager.saveProgress('kata2', { completed: false });

      const allProgress = storageManager.getAllProgress();
      expect(allProgress).toBeTypeOf('object');
      expect(Object.keys(allProgress).length).toBeGreaterThanOrEqual(2);
    });
  });

  describe('Error Handling', () => {
    it('should handle localStorage errors gracefully', () => {
      // Create a mock localStorage that throws an error on setItem
      const mockLocalStorage = {
        getItem: vi.fn(),
        setItem: vi.fn().mockImplementation(() => {
          throw new Error('Storage quota exceeded');
        }),
        removeItem: vi.fn(),
        clear: vi.fn(),
        key: vi.fn(),
        length: 0
      };

      // Stub the global localStorage
      vi.stubGlobal('localStorage', mockLocalStorage);

      const result = storageManager.saveProgress('test-kata', { completed: true });
      expect(result).toBe(false);

      // Restore globals
      vi.unstubAllGlobals();
    });

    it('should handle JSON parsing errors', () => {
      // Ensure localStorage is clean
      globalThis.localStorage.clear();

      // Manually set invalid JSON in localStorage
      globalThis.localStorage.setItem('kata-progress-test', 'invalid-json');

      const result = storageManager.getProgress('test');
      expect(result).toBeNull();

      // Clean up
      globalThis.localStorage.clear();
    });
  });

  // ========================================
  // DUAL CHECKBOX STATE PERSISTENCE TESTS (TDD Phase A - Red)
  // ========================================

  describe('dual checkbox state persistence', () => {
    beforeEach(() => {
      // Clear localStorage before each test
      if (typeof globalThis !== 'undefined' && globalThis.localStorage) {
        globalThis.localStorage.clear();
      }
    });

    describe('learning path selection storage (📚 Add to Path)', () => {
      it('should store and retrieve path selection states independently', () => {
        const selections = {
          'ai-assisted-engineering/01-ai-development-fundamentals': true,
          'ai-assisted-engineering/02-prompt-engineering': true,
          'project-planning/01-basic-prompt-usage': false
        };

        // Store selections
        const stored = storageManager.setItem('learning-path-selections', selections);
        expect(stored).toBe(true);

        // Retrieve selections
        const retrieved = storageManager.getItem('learning-path-selections');
        expect(retrieved).toEqual(selections);
      });

      it('should handle bulk path selection updates', () => {
        const initialSelections = {
          'ai-assisted-engineering/01-ai-development-fundamentals': true
        };

        const updatedSelections = {
          'ai-assisted-engineering/01-ai-development-fundamentals': true,
          'ai-assisted-engineering/02-prompt-engineering': true,
          'project-planning/01-basic-prompt-usage': true
        };

        // Store initial selections
        storageManager.setItem('learning-path-selections', initialSelections);

        // Update with bulk selections
        storageManager.setItem('learning-path-selections', updatedSelections);

        const retrieved = storageManager.getItem('learning-path-selections');
        expect(retrieved).toEqual(updatedSelections);
        expect(Object.keys(retrieved)).toHaveLength(3);
      });

      it('should maintain path selection state across storage operations', () => {
        const kataId = 'ai-assisted-engineering/01-ai-development-fundamentals';
        const selections = { [kataId]: true };

        // Store selection
        storageManager.setItem('learning-path-selections', selections);

        // Perform other storage operations (should not affect selections)
        storageManager.saveProgress('other-kata', { completed: false });
        storageManager.saveSetting('theme', 'dark');

        // Verify selection state is preserved
        const retrieved = storageManager.getItem('learning-path-selections');
        expect(retrieved).toEqual(selections);
      });
    });

    describe('completion state storage (✅ Completed)', () => {
      it('should store completion state independently of path selection', () => {
        const kataId = 'ai-assisted-engineering/01-ai-development-fundamentals';
        const completionData = {
          kataId,
          completed: true,
          completionPercentage: 100,
          score: 95,
          timeSpent: 45,
          timestamp: Date.now()
        };

        const stored = storageManager.saveProgress(kataId, completionData);
        expect(stored).toBe(true);

        const retrieved = storageManager.getProgress(kataId);
        expect(retrieved).toMatchObject(completionData);
      });

      it('should maintain completion data integrity during path selection changes', () => {
        const kataId = 'ai-assisted-engineering/01-ai-development-fundamentals';
        const completionData = {
          completed: true,
          completionPercentage: 100,
          score: 85
        };

        // Store completion data
        storageManager.saveProgress(kataId, completionData);

        // Change path selections (should not affect completion)
        storageManager.setItem('learning-path-selections', { [kataId]: true });
        storageManager.setItem('learning-path-selections', { [kataId]: false });

        // Verify completion data is unchanged
        const retrieved = storageManager.getProgress(kataId);
        expect(retrieved).toMatchObject(completionData);
      });

      it('should handle completion state updates with metadata', () => {
        const kataId = 'ai-assisted-engineering/01-ai-development-fundamentals';
        const completionData = {
          completed: true,
          completionPercentage: 100,
          metadata: {
            completionMethod: 'dual-checkbox',
            userAgent: 'test-suite',
            sessionId: 'test-session-123'
          }
        };

        const stored = storageManager.saveProgress(kataId, completionData);
        expect(stored).toBe(true);

        const retrieved = storageManager.getProgress(kataId);
        expect(retrieved.metadata).toMatchObject(completionData.metadata);
      });
    });

    describe('dual state persistence integration', () => {
      it('should handle simultaneous path selection and completion storage', () => {
        const kataId = 'ai-assisted-engineering/01-ai-development-fundamentals';

        // Store path selection
        const selections = { [kataId]: true };
        const selectionStored = storageManager.setItem('learning-path-selections', selections);

        // Store completion
        const completionData = { completed: true, completionPercentage: 100 };
        const completionStored = storageManager.saveProgress(kataId, completionData);

        expect(selectionStored).toBe(true);
        expect(completionStored).toBe(true);

        // Verify both states are independently accessible
        const retrievedSelections = storageManager.getItem('learning-path-selections');
        const retrievedCompletion = storageManager.getProgress(kataId);

        expect(retrievedSelections).toEqual(selections);
        expect(retrievedCompletion).toMatchObject(completionData);
      });

      it('should provide comprehensive dual state summary', () => {
        const kataIds = [
          'ai-assisted-engineering/01-ai-development-fundamentals',
          'ai-assisted-engineering/02-prompt-engineering',
          'project-planning/01-basic-prompt-usage'
        ];

        // Setup mixed dual states
        const selections = {
          [kataIds[0]]: true, // Selected and will be completed
          [kataIds[1]]: true, // Selected but not completed
          // kataIds[2] not selected but will be completed
        };

        const completions = [
          { kataId: kataIds[0], completed: true, completionPercentage: 100 },
          { kataId: kataIds[2], completed: true, completionPercentage: 100 }
        ];

        // Store selections
        storageManager.setItem('learning-path-selections', selections);

        // Store completions
        completions.forEach(completion => {
          storageManager.saveProgress(completion.kataId, completion);
        });

        // Verify independent access to all states
        const allProgress = storageManager.getAllProgress();
        const allSelections = storageManager.getItem('learning-path-selections');

        expect(allSelections).toEqual(selections);
        expect(Object.keys(allProgress)).toContain(kataIds[0]);
        expect(Object.keys(allProgress)).toContain(kataIds[2]);

        // Verify state combinations
        expect(allSelections[kataIds[0]]).toBe(true); // Selected
        expect(allProgress[kataIds[0]]).toMatchObject({ completed: true }); // And completed

        expect(allSelections[kataIds[1]]).toBe(true); // Selected
        expect(allProgress[kataIds[1]]).toBeFalsy(); // But not completed

        expect(allSelections[kataIds[2]]).toBeFalsy(); // Not selected
        expect(allProgress[kataIds[2]]).toMatchObject({ completed: true }); // But completed
      });

      it('should handle dual state cleanup operations', () => {
        const kataId = 'ai-assisted-engineering/01-ai-development-fundamentals';

        // Setup both states
        storageManager.setItem('learning-path-selections', { [kataId]: true });
        storageManager.saveProgress(kataId, { completed: true });

        // Clear only progress (selection should remain)
        const progressCleared = storageManager.clearProgress(kataId);
        expect(progressCleared).toBe(true);

        const remainingSelections = storageManager.getItem('learning-path-selections');
        const clearedProgress = storageManager.getProgress(kataId);

        expect(remainingSelections).toEqual({ [kataId]: true });
        expect(clearedProgress).toBeNull();
      });

      it('should handle storage errors gracefully for dual states', () => {
        // Mock localStorage to throw errors
        const mockLocalStorage = {
          getItem: vi.fn().mockImplementation(() => {
            throw new Error('Storage read error');
          }),
          setItem: vi.fn().mockImplementation(() => {
            throw new Error('Storage write error');
          }),
          removeItem: vi.fn(),
          clear: vi.fn(),
          key: vi.fn(),
          length: 0
        };

        vi.stubGlobal('localStorage', mockLocalStorage);

        // Test path selection storage error
        const selectionResult = storageManager.setItem('learning-path-selections', { 'test': true });
        expect(selectionResult).toBe(false);

        // Test completion storage error
        const completionResult = storageManager.saveProgress('test-kata', { completed: true });
        expect(completionResult).toBe(false);

        // Test retrieval error
        const retrievedSelections = storageManager.getItem('learning-path-selections');
        expect(retrievedSelections).toBeNull();

        vi.unstubAllGlobals();
      });
    });

    describe('dual state data migration', () => {
      it('should handle migration from single to dual checkbox format', () => {
        // Simulate old single checkbox format
        const legacyData = {
          'ai-assisted-engineering/01-ai-development-fundamentals': {
            selected: true,
            completed: true
          },
          'ai-assisted-engineering/02-prompt-engineering': {
            selected: true,
            completed: false
          }
        };

        // Store legacy format
        storageManager.setItem('legacy-checkbox-data', legacyData);

        // Simulate migration to dual format
        const pathSelections = {};
        const completionData = {};

        Object.entries(legacyData).forEach(([kataId, data]) => {
          pathSelections[kataId] = data.selected;
          if (data.completed) {
            completionData[kataId] = { completed: true, completionPercentage: 100 };
          }
        });

        // Store in dual format
        storageManager.setItem('learning-path-selections', pathSelections);
        Object.entries(completionData).forEach(([kataId, completion]) => {
          storageManager.saveProgress(kataId, completion);
        });

        // Verify migration
        const migratedSelections = storageManager.getItem('learning-path-selections');
        const migratedProgress = storageManager.getAllProgress();

        expect(migratedSelections).toEqual({
          'ai-assisted-engineering/01-ai-development-fundamentals': true,
          'ai-assisted-engineering/02-prompt-engineering': true
        });

        expect(migratedProgress['ai-assisted-engineering/01-ai-development-fundamentals']).toMatchObject({
          completed: true
        });
      });
    });
  });

  describe('Integration Tests', () => {
    it('should maintain data consistency across operations', () => {
      const kataData = { completed: true, score: 95, timestamp: Date.now() };

      // Save data
      storageManager.saveProgress('integration-test', kataData);

      // Verify it's in getAllProgress
      const allProgress = storageManager.getAllProgress();
      expect(allProgress['integration-test']).toMatchObject(kataData);

      // Verify direct retrieval
      const retrieved = storageManager.getProgress('integration-test');
      expect(retrieved).toMatchObject(kataData);

      // Clear and verify removal
      storageManager.clearProgress('integration-test');
      expect(storageManager.getProgress('integration-test')).toBeNull();
    });
  });
});
