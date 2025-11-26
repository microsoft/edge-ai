import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { LearningPathManager } from '../../core/learning-path-manager.js';

describe('LearningPathManager', () => {
  let learningPathManager;
  let mockErrorHandler;
  let mockStorageManager;
  let mockDomUtils;
  let mockDebugHelper;
  let mockKataDetection;

  beforeEach(() => {
    // Mock error handler
    mockErrorHandler = {
      safeExecute: vi.fn().mockImplementation((fn, context, defaultValue) => {
        try {
          return fn();
        } catch {
          return defaultValue;
        }
      }),
      recordError: vi.fn(),
      log: vi.fn()
    };

    // Mock storage manager
    mockStorageManager = {
      getKataProgress: vi.fn(),
      setKataProgress: vi.fn(),
      getLabProgress: vi.fn(),
      setLabProgress: vi.fn(),
      getAllProgress: vi.fn(),
      clearProgress: vi.fn(),
      getItem: vi.fn().mockResolvedValue(null),
      setItem: vi.fn().mockResolvedValue(undefined)
    };

    // Mock kata detection
    mockKataDetection = {
      getCurrentContext: vi.fn().mockReturnValue({ type: 'category', value: 'test-category' }),
      detectKataFromUrl: vi.fn(),
      isInKataContext: vi.fn().mockReturnValue(true),
      getKataMetadata: vi.fn()
    };

    // Mock DOM utilities
    mockDomUtils = {
      querySelector: vi.fn().mockImplementation((selector) => {
        return document.querySelector(selector) || document.createElement('div');
      }),
      querySelectorAll: vi.fn().mockImplementation((selector) => {
        return Array.from(document.querySelectorAll(selector));
      }),
      createElement: vi.fn().mockImplementation((tagName) => {
        return document.createElement(tagName);
      }),
      addClass: vi.fn().mockReturnValue(true),
      removeClass: vi.fn().mockReturnValue(true)
    };

    // Mock debug helper
    mockDebugHelper = {
      log: vi.fn(),
      warn: vi.fn(),
      error: vi.fn()
    };

    // Create LearningPathManager instance with mocked dependencies
    learningPathManager = new LearningPathManager({
      errorHandler: mockErrorHandler,
      storageManager: mockStorageManager,
      domUtils: mockDomUtils,
      debugHelper: mockDebugHelper,
      kataDetection: mockKataDetection
    });
  });

  afterEach(() => {
    vi.clearAllMocks();

    if (typeof window !== 'undefined') {
      vi.restoreAllMocks();
    }
  });

  describe('initialization', () => {
    it('should initialize with default settings', () => {
      expect(learningPathManager.isInitialized).toBe(false);
      expect(learningPathManager.config).toBeDefined();
    });

    it('should require errorHandler with safeExecute method', () => {
      expect(() => {
        new LearningPathManager({
          errorHandler: { wrongMethod: () => {} },
          storageManager: mockStorageManager,
          domUtils: mockDomUtils,
          debugHelper: mockDebugHelper
        });
      }).toThrow('LearningPathManager requires errorHandler with safeExecute method');
    });

    it('should accept custom configuration', () => {
      const customConfig = {
        maxRetries: 5,
        timeout: 10000
      };

      const customManager = new LearningPathManager({
        errorHandler: mockErrorHandler,
        storageManager: mockStorageManager,
        domUtils: mockDomUtils,
        debugHelper: mockDebugHelper,
        config: customConfig
      });

      expect(customManager.config.maxRetries).toBe(5);
      expect(customManager.config.timeout).toBe(10000);
    });
  });

  describe('learning path management', () => {
    beforeEach(async () => {
      await learningPathManager.init();
    });

    it('should initialize learning path management', () => {
      expect(learningPathManager.isInitialized).toBe(true);
    });

    it('should load learning paths from storage', () => {
      const mockPaths = [
        {
          id: 'path-1',
          title: 'Introduction to AI',
          katas: ['01-fundamentals', '02-advanced']
        }
      ];

      mockStorageManager.getAllProgress.mockReturnValue(mockPaths);

      const paths = learningPathManager.loadLearningPaths();

      expect(mockStorageManager.getAllProgress).toHaveBeenCalled();
      expect(paths).toEqual(mockPaths);
    });

    it('should handle storage loading errors gracefully', () => {
      mockStorageManager.getAllProgress.mockImplementation(() => {
        throw new Error('Storage error');
      });

      const paths = learningPathManager.loadLearningPaths();

      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
      expect(paths).toEqual([]);
    });

    it('should save learning path progress', () => {
      const pathData = {
        id: 'path-1',
        progress: 50,
        completedKatas: ['01-fundamentals']
      };

      learningPathManager.saveProgress(pathData);

      expect(mockStorageManager.setKataProgress).toHaveBeenCalledWith(
        pathData.id,
        pathData
      );
    });

    it('should update kata progress within learning paths', () => {
      const kataId = '01-fundamentals';
      const progress = {
        completed: true,
        score: 85,
        timeSpent: 45
      };

      learningPathManager.updateKataProgress(kataId, progress);

      expect(mockStorageManager.setKataProgress).toHaveBeenCalledWith(
        kataId,
        progress
      );
    });
  });

  describe('progress tracking', () => {
    it('should calculate overall progress for a learning path', () => {
      const pathData = {
        id: 'path-1',
        katas: ['kata-1', 'kata-2', 'kata-3'],
        completedKatas: ['kata-1', 'kata-2']
      };

      const progress = learningPathManager.calculateProgress(pathData);

      expect(progress).toBeCloseTo(66.67, 1);
    });

    it('should handle empty learning paths', () => {
      const pathData = {
        id: 'empty-path',
        katas: [],
        completedKatas: []
      };

      const progress = learningPathManager.calculateProgress(pathData);

      expect(progress).toBe(0);
    });

    it('should get next recommended kata', () => {
      const pathData = {
        id: 'path-1',
        katas: ['kata-1', 'kata-2', 'kata-3'],
        completedKatas: ['kata-1']
      };

      const nextKata = learningPathManager.getNextKata(pathData);

      expect(nextKata).toBe('kata-2');
    });

    it('should return null when all katas are completed', () => {
      const pathData = {
        id: 'path-1',
        katas: ['kata-1', 'kata-2'],
        completedKatas: ['kata-1', 'kata-2']
      };

      const nextKata = learningPathManager.getNextKata(pathData);

      expect(nextKata).toBeNull();
    });
  });

  describe('learning path validation', () => {
    it('should validate learning path structure', () => {
      const validPath = {
        id: 'valid-path',
        title: 'Valid Learning Path',
        katas: ['kata-1', 'kata-2'],
        description: 'A valid learning path'
      };

      const isValid = learningPathManager.validatePath(validPath);

      expect(isValid).toBe(true);
    });

    it('should reject invalid learning paths', () => {
      const invalidPath = {
        // Missing required fields
        title: 'Invalid Path'
      };

      const isValid = learningPathManager.validatePath(invalidPath);

      expect(isValid).toBe(false);
    });

    it('should validate kata dependencies', () => {
      const pathWithDependencies = {
        id: 'dependent-path',
        katas: [
          { id: 'kata-1', dependencies: [] },
          { id: 'kata-2', dependencies: ['kata-1'] }
        ]
      };

      const isValid = learningPathManager.validateDependencies(pathWithDependencies);

      expect(isValid).toBe(true);
    });
  });

  describe('error handling', () => {
    it('should handle initialization errors gracefully', () => {
      mockStorageManager.getAllProgress.mockImplementation(() => {
        throw new Error('Storage initialization error');
      });

      expect(() => {
        learningPathManager.init();
      }).not.toThrow();

      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });

    it('should handle progress save errors', () => {
      mockStorageManager.setKataProgress.mockImplementation(() => {
        throw new Error('Storage save error');
      });

      const pathData = { id: 'test-path', progress: 50 };

      expect(() => {
        learningPathManager.saveProgress(pathData);
      }).not.toThrow();

      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });
  });

  describe('learning path recommendations', () => {
    it('should recommend learning paths based on user progress', () => {
      const userProgress = {
        completedKatas: ['basic-kata-1', 'basic-kata-2'],
        skillLevel: 'beginner'
      };

      const recommendations = learningPathManager.getRecommendations(userProgress);

      expect(Array.isArray(recommendations)).toBe(true);
      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });

    it('should filter recommendations by difficulty', () => {
      const difficulty = 'intermediate';

      const recommendations = learningPathManager.getRecommendationsByDifficulty(difficulty);

      expect(Array.isArray(recommendations)).toBe(true);
    });
  });

  // ========================================
  // DUAL CHECKBOX STATE TRACKING TESTS (TDD Phase A - Red)
  // ========================================

  describe('dual checkbox state tracking', () => {
    beforeEach(() => {
      learningPathManager.init();

      // Mock localStorage for dual checkbox state storage
      mockStorageManager.getItem = vi.fn();
      mockStorageManager.setItem = vi.fn();

      // Initialize with empty state
      mockStorageManager.getItem.mockReturnValue(null);
    });

    describe('learning path selection state (📚 Add to Path)', () => {
      it('should track learning path selection state independently', () => {
        const kataId = 'ai-assisted-engineering/01-ai-development-fundamentals';

        // Test adding to path without completion
        const result = learningPathManager.updatePathSelection(kataId, true);

        expect(result).toBe(true);
        expect(mockStorageManager.setItem).toHaveBeenCalledWith(
          'learning-path-selections',
          expect.objectContaining({ [kataId]: true })
        );
      });

      it('should handle bulk path selection updates', () => {
        const selectedKatas = [
          'ai-assisted-engineering/01-ai-development-fundamentals',
          'ai-assisted-engineering/02-prompt-engineering',
          'project-planning/01-basic-prompt-usage'
        ];

        const result = learningPathManager.updatePathSelection(selectedKatas);

        expect(result).toBe(true);
        expect(mockStorageManager.setItem).toHaveBeenCalledWith(
          'learning-path-selections',
          expect.objectContaining({
            'ai-assisted-engineering/01-ai-development-fundamentals': true,
            'ai-assisted-engineering/02-prompt-engineering': true,
            'project-planning/01-basic-prompt-usage': true
          })
        );
      });

      it('should remove kata from path selection when deselected', () => {
        const kataId = 'ai-assisted-engineering/01-ai-development-fundamentals';

        // First add to path
        learningPathManager.updatePathSelection(kataId, true);

        // Then remove from path
        const result = learningPathManager.updatePathSelection(kataId, false);

        expect(result).toBe(true);
        expect(mockStorageManager.setItem).toHaveBeenLastCalledWith(
          'learning-path-selections',
          expect.objectContaining({ [kataId]: false })
        );
      });

      it('should load path selections from storage on initialization', async () => {
        const storedSelections = {
          'ai-assisted-engineering/01-ai-development-fundamentals': true,
          'project-planning/01-basic-prompt-usage': true
        };

        // Mock API fetch failure to trigger localStorage fallback
        global.fetch = vi.fn().mockRejectedValue(new Error('Network error'));
        mockStorageManager.getItem.mockReturnValue(storedSelections);

        const result = await learningPathManager.loadPathSelections();

        expect(result).toBe(true);
        expect(mockStorageManager.getItem).toHaveBeenCalledWith('learning-path-selections');
        expect(learningPathManager.getPathSelections()).toEqual(storedSelections);
      });
    });

    describe('completion state (✅ Completed)', () => {
      it('should track completion state independently of selection state', () => {
        const kataId = 'ai-assisted-engineering/01-ai-development-fundamentals';
        const completionData = {
          completed: true,
          completionPercentage: 100,
          score: 95,
          timestamp: Date.now()
        };

        const result = learningPathManager.updateKataProgress(kataId, completionData);

        expect(result).toBe(true);
        expect(mockStorageManager.setKataProgress).toHaveBeenCalledWith(
          kataId,
          completionData
        );
      });

      it('should handle completion without requiring path selection', () => {
        const kataId = 'ai-assisted-engineering/01-ai-development-fundamentals';
        const completionData = {
          completed: true,
          completionPercentage: 100,
          timeSpent: 45
        };

        // Complete kata without adding to path first
        const result = learningPathManager.updateKataProgress(kataId, completionData);

        expect(result).toBe(true);
        expect(mockStorageManager.setKataProgress).toHaveBeenCalledWith(
          kataId,
          completionData
        );

        // Verify path selection state is independent
        expect(learningPathManager.getPathSelections()[kataId]).toBeUndefined();
      });

      it('should maintain completion state when path selection changes', () => {
        const kataId = 'ai-assisted-engineering/01-ai-development-fundamentals';

        // Mock existing completion state
        mockStorageManager.getKataProgress = vi.fn().mockReturnValue({
          completed: true,
          completionPercentage: 100,
          score: 85
        });

        // Add to path (should not affect completion)
        learningPathManager.updatePathSelection(kataId, true);

        // Remove from path (should not affect completion)
        learningPathManager.updatePathSelection(kataId, false);

        // Verify completion state is unchanged
        const progress = mockStorageManager.getKataProgress(kataId);
        expect(progress.completed).toBe(true);
        expect(progress.completionPercentage).toBe(100);
      });
    });

    describe('dual state synchronization', () => {
      it('should provide dual state summary for UI synchronization', () => {
        const kataId = 'ai-assisted-engineering/01-ai-development-fundamentals';

        // Setup mock states
        mockStorageManager.getItem.mockImplementation((key) => {
          if (key === 'learning-path-selections') {
            return { [kataId]: true };
          }
          return null;
        });

        mockStorageManager.getKataProgress = vi.fn().mockReturnValue({
          completed: true,
          completionPercentage: 100
        });

        const progress = learningPathManager.getProgress();

        expect(progress).toEqual({
          pathSelections: { [kataId]: true },
          progressData: expect.any(Object),
          timestamp: expect.any(String)
        });
      });

      it('should handle dual state combinations correctly', () => {
        const testCases = [
          {
            name: 'not selected, not completed',
            pathSelected: false,
            completed: false,
            expectedState: { addToPath: false, completed: false }
          },
          {
            name: 'selected but not completed',
            pathSelected: true,
            completed: false,
            expectedState: { addToPath: true, completed: false }
          },
          {
            name: 'completed but not in path',
            pathSelected: false,
            completed: true,
            expectedState: { addToPath: false, completed: true }
          },
          {
            name: 'selected and completed',
            pathSelected: true,
            completed: true,
            expectedState: { addToPath: true, completed: true }
          }
        ];

        testCases.forEach(({ name, pathSelected, completed, expectedState }) => {
          const kataId = `test-kata-${name.replace(/\s+/g, '-')}`;

          // Setup path selection state
          if (pathSelected) {
            learningPathManager.updatePathSelection(kataId, true);
          }

          // Setup completion state
          if (completed) {
            learningPathManager.updateKataProgress(kataId, {
              completed: true,
              completionPercentage: 100
            });
          }

          // Verify independent state tracking
          const pathSelections = learningPathManager.getPathSelections();
          const isInPath = Boolean(pathSelections[kataId]);

          expect(isInPath).toBe(expectedState.addToPath);

          if (completed) {
            expect(mockStorageManager.setKataProgress).toHaveBeenCalledWith(
              kataId,
              expect.objectContaining({ completed: true })
            );
          }
        });
      });

      it('should sync progress data from external source', async () => {
        const externalProgressData = {
          pathSelections: {
            'ai-assisted-engineering/01-ai-development-fundamentals': true,
            'project-planning/01-basic-prompt-usage': true
          },
          progressData: {
            'kata-progress-ai-assisted-engineering/01-ai-development-fundamentals': {
              completed: true,
              completionPercentage: 100
            }
          }
        };

        const result = await learningPathManager.syncProgress(externalProgressData);

        expect(result).toBe(true);
        expect(mockStorageManager.setItem).toHaveBeenCalledWith(
          'learning-path-selections',
          externalProgressData.pathSelections
        );
        expect(mockStorageManager.setItem).toHaveBeenCalledWith(
          'learning_progress_data',
          externalProgressData.progressData
        );
      });

      it('should handle dual state validation errors', () => {
        // Test invalid path selection data
        const invalidResult = learningPathManager.updatePathSelection(null, true);
        expect(invalidResult).toBe(false);

        const emptyResult = learningPathManager.updatePathSelection('', true);
        expect(emptyResult).toBe(false);

        // Test invalid completion data
        const invalidCompletionResult = learningPathManager.updateKataProgress('valid-kata', null);
        expect(invalidCompletionResult).toBe(false);
      });
    });

    describe('dual checkbox progress calculations', () => {
      it('should calculate progress considering both selection and completion states', () => {
        const categoryId = 'ai-assisted-engineering';
        const mockCategory = {
          name: 'AI Assisted Engineering',
          katas: ['01-ai-development-fundamentals', '02-prompt-engineering', '03-advanced-techniques']
        };

        // Mock detection to return category
        mockKataDetection.getKataCategory = vi.fn().mockReturnValue(mockCategory);

        // Mock LearningPathManager's async getKataProgress method (server-first architecture)
        vi.spyOn(learningPathManager, 'getKataProgress').mockImplementation((fullKataId) => {
          if (fullKataId === 'ai-assisted-engineering/01-ai-development-fundamentals') {
            return { completionPercentage: 100, completed: true, timeSpent: 30, lastUpdated: Date.now() };
          } else if (fullKataId === 'ai-assisted-engineering/02-prompt-engineering') {
            return { completionPercentage: 50, completed: false, timeSpent: 15, lastUpdated: Date.now() };
          } else {
            return { completionPercentage: 0, completed: false, timeSpent: 0, lastUpdated: Date.now() };
          }
        });

        const categoryProgress = learningPathManager.getCategoryProgress(categoryId);

        expect(categoryProgress).toEqual({
          categoryId,
          category: mockCategory,
          totalKatas: 3,
          completedKatas: 1,
          overallCompletion: 33, // 1 of 3 completed = 33%
          completionPercentage: 33,
          totalTimeSpent: 45,
          kataProgress: expect.any(Array),
          isCompleted: false,
          lastUpdated: expect.any(Number)
        });
      });

      it('should provide separate tracking for path selection vs completion metrics', () => {
        const pathSelections = {
          'ai-assisted-engineering/01-ai-development-fundamentals': true,
          'ai-assisted-engineering/02-prompt-engineering': true,
          'project-planning/01-basic-prompt-usage': true
        };

        const completionData = {
          'ai-assisted-engineering/01-ai-development-fundamentals': { completed: true },
          'project-planning/01-basic-prompt-usage': { completed: true }
        };

        // Setup mock return values
        mockStorageManager.getItem.mockImplementation((key) => {
          if (key === 'learning-path-selections') {
            return pathSelections;
          }
          return null;
        });

        mockStorageManager.getKataProgress = vi.fn().mockImplementation((kataId) => {
          return completionData[kataId] || { completed: false };
        });

        const progress = learningPathManager.getProgress();

        // Verify separate tracking
        expect(progress.pathSelections).toEqual(pathSelections);
        expect(Object.keys(progress.pathSelections)).toHaveLength(3); // 3 selected
        expect(Object.keys(completionData)).toHaveLength(2); // 2 completed
      });
    });
  });

  describe('cleanup', () => {
    it('should clean up resources on destroy', async () => {
      await learningPathManager.init();
      expect(learningPathManager.isInitialized).toBe(true);

      learningPathManager.destroy();

      expect(learningPathManager.isInitialized).toBe(false);
    });

    it('should handle cleanup errors gracefully', () => {
      mockStorageManager.clearProgress.mockImplementation(() => {
        throw new Error('Cleanup error');
      });

      expect(() => {
        learningPathManager.destroy();
      }).not.toThrow();

      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });
  });

  describe('configuration management', () => {
    it('should allow runtime configuration updates', () => {
      const newConfig = {
        maxRetries: 10,
        timeout: 15000
      };

      learningPathManager.updateConfig(newConfig);

      expect(learningPathManager.config.maxRetries).toBe(10);
      expect(learningPathManager.config.timeout).toBe(15000);
    });

    it('should merge configuration updates with existing config', () => {
      const originalTimeout = learningPathManager.config.timeout;

      learningPathManager.updateConfig({
        maxRetries: 8
      });

      expect(learningPathManager.config.timeout).toBe(originalTimeout);
      expect(learningPathManager.config.maxRetries).toBe(8);
    });
  });
});
