/**
 * @vitest-environment happy-dom
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { LearningPathManager } from '../../core/learning-path-manager.js';

describe('LearningPathManager - Interactive Checkbox Integration', () => {
  let learningPathManager;
  let mockDependencies;
  let mockDebugHelper;
  let mockErrorHandler;
  let mockStorageManager;
  let mockKataDetection;

  beforeEach(() => {
    // Create mock dependencies
    mockDebugHelper = {
      log: vi.fn(),
      warn: vi.fn(),
      error: vi.fn()
    };

    mockErrorHandler = {
      handleError: vi.fn(),
      safeExecute: vi.fn((fn, context, fallback) => {
        try {
          return fn();
        } catch (_error) {
          mockErrorHandler.handleError(_error, context);
          return fallback;
        }
      })
    };

    mockStorageManager = {
      getKataProgress: vi.fn(),
      setKataProgress: vi.fn(),
      saveKataProgress: vi.fn(),
      savePathProgress: vi.fn(),
      getAllProgress: vi.fn(),
      getItem: vi.fn(),
      setItem: vi.fn()
    };

    mockKataDetection = {
      getAllKataCategories: vi.fn(),
      getKataCategory: vi.fn(),
      getAllTrainingLabs: vi.fn(),
      getTrainingLab: vi.fn(),
      getContentType: vi.fn(),
      extractKataCategory: vi.fn(),
      extractKataId: vi.fn(),
      extractLabId: vi.fn(),
      getNextKataInCategory: vi.fn()
    };

    mockDependencies = {
      debugHelper: mockDebugHelper,
      errorHandler: mockErrorHandler,
      storageManager: mockStorageManager,
      kataDetection: mockKataDetection
    };

    learningPathManager = new LearningPathManager(mockDependencies);
  });

  afterEach(() => {
    if (learningPathManager) {
      learningPathManager.destroy();
    }
  });

  describe('UI Selection Management', () => {
    it('should update path selection state for a kata', () => {
      // Arrange
      const kataId = 'ai-assisted-engineering/01-ai-development-fundamentals';
      const isSelected = true;

      // Act
      const result = learningPathManager.updatePathSelection(kataId, isSelected);

      // Assert
      expect(result).toBe(true);
      expect(mockStorageManager.setItem).toHaveBeenCalledWith(
        'learning-path-selections',
        expect.objectContaining({
          [kataId]: isSelected
        })
      );
    });

    it('should handle deselection of a kata', () => {
      // Arrange
      const kataId = 'ai-assisted-engineering/02-prompt-engineering';
      const isSelected = false;

      // Act
      const result = learningPathManager.updatePathSelection(kataId, isSelected);

      // Assert
      expect(result).toBe(true);
      expect(mockStorageManager.setItem).toHaveBeenCalledWith(
        'learning-path-selections',
        expect.objectContaining({
          [kataId]: isSelected
        })
      );
    });

    it('should return false when storage operation fails', () => {
      // Arrange
      const kataId = 'test-kata';
      const isSelected = true;
      mockStorageManager.setItem.mockImplementation(() => {
        throw new Error('Storage error');
      });

      // Act
      const result = learningPathManager.updatePathSelection(kataId, isSelected);

      // Assert
      expect(result).toBe(false);
      expect(mockErrorHandler.handleError).toHaveBeenCalled();
    });
  });

  describe('Auto-Selection Logic', () => {
    it('should return related katas for a learning path', () => {
      // Arrange
      const pathName = 'Foundation Builder - AI Engineering';
      const expectedKatas = [
        'ai-assisted-engineering/01-ai-development-fundamentals',
        'ai-assisted-engineering/02-prompt-engineering',
        'ai-assisted-engineering/03-code-generation'
      ];

      mockKataDetection.getAllKataCategories.mockReturnValue({
        'ai-assisted-engineering': {
          name: 'AI-Assisted Engineering',
          katas: ['01-ai-development-fundamentals', '02-prompt-engineering', '03-code-generation'],
          pathMappings: {
            'Foundation Builder - AI Engineering': ['01-ai-development-fundamentals', '02-prompt-engineering']
          }
        }
      });

      // Act
      const result = learningPathManager.getAutoSelectionItems(pathName);

      // Assert
      expect(result).toEqual([
        'ai-assisted-engineering/01-ai-development-fundamentals',
        'ai-assisted-engineering/02-prompt-engineering'
      ]);
    });

    it('should return empty array for unknown learning path', () => {
      // Arrange
      const pathName = 'Unknown Path';
      mockKataDetection.getAllKataCategories.mockReturnValue({});

      // Act
      const result = learningPathManager.getAutoSelectionItems(pathName);

      // Assert
      expect(result).toEqual([]);
    });

    it('should handle categories without path mappings', () => {
      // Arrange
      const pathName = 'Test Path';
      mockKataDetection.getAllKataCategories.mockReturnValue({
        'test-category': {
          name: 'Test Category',
          katas: ['01-test-kata'],
          // No pathMappings property
        }
      });

      // Act
      const result = learningPathManager.getAutoSelectionItems(pathName);

      // Assert
      expect(result).toEqual([]);
    });
  });

  describe('Selection Persistence', () => {
    it('should persist current path selections to storage', () => {
      // Arrange
      const currentSelections = {
        'ai-assisted-engineering/01-ai-development-fundamentals': true,
        'ai-assisted-engineering/02-prompt-engineering': true,
        'project-planning/01-basic-prompt-usage': false
      };

      // Mock internal state
      learningPathManager._pathSelections = currentSelections;

      // Act
      const result = learningPathManager.persistPathSelections();

      // Assert
      expect(result).toBe(true);
      expect(mockStorageManager.setItem).toHaveBeenCalledWith(
        'learning-path-selections',
        currentSelections
      );
    });

    it('should handle persistence errors gracefully', () => {
      // Arrange
      mockStorageManager.setItem.mockImplementation(() => {
        throw new Error('Storage full');
      });

      // Act
      const result = learningPathManager.persistPathSelections();

      // Assert
      expect(result).toBe(false);
      expect(mockErrorHandler.handleError).toHaveBeenCalled();
    });

    it('should create empty selections object if none exist', () => {
      // Arrange - no existing selections

      // Act
      const result = learningPathManager.persistPathSelections();

      // Assert
      expect(result).toBe(true);
      expect(mockStorageManager.setItem).toHaveBeenCalledWith(
        'learning-path-selections',
        {}
      );
    });
  });

  describe('Progress State Retrieval', () => {
    it('should return current path progress for UI synchronization', () => {
      // Arrange
      const storedSelections = {
        'ai-assisted-engineering/01-ai-development-fundamentals': true,
        'ai-assisted-engineering/02-prompt-engineering': false,
        'project-planning/01-basic-prompt-usage': true
      };

      mockStorageManager.getItem.mockImplementation((key) => {
        if (key === 'learning-path-selections') {
          return storedSelections;
        }
        if (key === 'learning_progress_data') {
          return {};
        }
        return null;
      });

      // Act
      const result = learningPathManager.getProgress();

      // Assert
      expect(result).toEqual({
        pathSelections: storedSelections,
        progressData: {},
        timestamp: expect.any(String)
      });
      expect(mockStorageManager.getItem).toHaveBeenCalledWith('learning-path-selections');
      expect(mockStorageManager.getItem).toHaveBeenCalledWith('learning_progress_data');
    });

    it('should return empty object when no selections exist', () => {
      // Arrange
      mockStorageManager.getItem.mockReturnValue(null);

      // Act
      const result = learningPathManager.getProgress();

      // Assert
      expect(result).toEqual({
        pathSelections: {},
        progressData: {},
        timestamp: expect.any(String)
      });
    });

    it('should handle storage retrieval errors', () => {
      // Arrange
      mockStorageManager.getItem.mockImplementation(() => {
        throw new Error('Storage read error');
      });

      // Act
      const result = learningPathManager.getProgress();

      // Assert - when safeExecute catches error, it returns the default value {}
      expect(result).toEqual({});
      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });

    it('should merge progress with completion data', () => {
      // Arrange
      const storedSelections = {
        'ai-assisted-engineering/01-ai-development-fundamentals': true
      };
      const progressData = {
        'ai-assisted-engineering/01-ai-development-fundamentals': {
          completionPercentage: 100,
          completedAt: Date.now()
        }
      };

      mockStorageManager.getItem.mockImplementation((key) => {
        if (key === 'learning-path-selections') {
          return storedSelections;
        }
        if (key === 'learning_progress_data') {
          return progressData;
        }
        return null;
      });

      // Act
      const result = learningPathManager.getProgress();

      // Assert
      expect(result).toEqual({
        pathSelections: storedSelections,
        progressData: progressData,
        timestamp: expect.any(String)
      });
    });
  });

  describe('Integration with Existing Progress Tracking', () => {
    it('should sync UI selections with kata progress updates', () => {
      // Arrange
      const kataId = 'ai-assisted-engineering/01-ai-development-fundamentals';
      const progressData = {
        completionPercentage: 100,
        timeSpent: 3600,
        completedAt: Date.now()
      };

      // Act - Update kata progress (existing method)
      learningPathManager.updateKataProgress(kataId, progressData);

      // Then update UI selection
      learningPathManager.updatePathSelection(kataId, true);

      // Assert
      expect(mockStorageManager.setKataProgress).toHaveBeenCalledWith(kataId, progressData);
      expect(mockStorageManager.setItem).toHaveBeenCalledWith(
        'learning-path-selections',
        expect.objectContaining({ [kataId]: true })
      );
    });

    it('should provide recommendations based on current selections', () => {
      // Arrange
      const currentSelections = {
        'ai-assisted-engineering/01-ai-development-fundamentals': true,
        'ai-assisted-engineering/02-prompt-engineering': false
      };

      learningPathManager._pathSelections = currentSelections;

      mockKataDetection.getAllKataCategories.mockReturnValue({
        'ai-assisted-engineering': {
          name: 'AI-Assisted Engineering',
          katas: ['01-ai-development-fundamentals', '02-prompt-engineering', '03-code-generation']
        }
      });

      // Act
      const recommendations = learningPathManager.getRecommendations();

      // Assert
      expect(recommendations).toBeDefined();
      // Should recommend continuing with the next unselected kata
    });
  });

  describe('Cleanup and Memory Management', () => {
    it('should clear UI-related data on destroy', () => {
      // Arrange
      learningPathManager._pathSelections = { 'test-kata': true };

      // Act
      learningPathManager.destroy();

      // Assert - Internal state should be cleared
      expect(learningPathManager._pathSelections).toBeUndefined();
    });
  });
});
