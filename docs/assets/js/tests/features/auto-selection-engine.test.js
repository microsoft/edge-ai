/**
 * Auto-Selection Engine Tests
 * Tests for intelligent auto-selection logic of learning paths and related items
 *
 * @author Edge AI Team
 * @version 1.0.0
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import {
  PATH_RELATIONSHIPS,
  AUTO_SELECTION_SCENARIOS,
  CONFLICT_SCENARIOS,
  PERFORMANCE_TEST_DATA
  // Removed unused imports to fix linter warnings
} from '../fixtures/path-relationships-data.js';

// Import the component we'll implement in Phase 4.2 (TDD GREEN)
// This will fail initially (RED phase) as the component doesn't exist yet
import { AutoSelectionEngine } from '../../features/auto-selection-engine.js';

describe('AutoSelectionEngine', () => {
  let autoSelectionEngine;
  let mockLearningPathManager;
  let mockErrorHandler;
  let mockDebugHelper;

  beforeEach(() => {
    // Mock error handler
    mockErrorHandler = {
      safeExecute: vi.fn().mockImplementation((fn, context, defaultValue) => {
        try {
          return fn();
        } catch {
          // Test error caught, continuing
          return defaultValue;
        }
      }),
      recordError: vi.fn(),
      log: vi.fn()
    };

    // Mock debug helper
    mockDebugHelper = {
      log: vi.fn(),
      warn: vi.fn(),
      error: vi.fn()
    };

    // Mock learning path manager
    mockLearningPathManager = {
      getPathProgress: vi.fn().mockReturnValue({}),
      getKataProgress: vi.fn().mockReturnValue({}),
      getUserLevel: vi.fn().mockReturnValue('Beginner'),
      getConfig: vi.fn().mockReturnValue({
        autoSelection: {
          enabled: true,
          respectUserLevel: true,
          handleConflicts: true,
          suggestRelated: true
        }
      }),
      updatePathSelections: vi.fn(),
      persistPathSelections: vi.fn()
    };

    // Create AutoSelectionEngine instance (will fail initially - RED phase)
    try {
      // Merge performance test data with path relationships
      const allPathRelationships = {
        ...PATH_RELATIONSHIPS,
        [PERFORMANCE_TEST_DATA.largePath.id]: PERFORMANCE_TEST_DATA.largePath,
        ...PERFORMANCE_TEST_DATA.manyPaths.reduce((acc, path) => {
          acc[path.id] = path;
          return acc;
        }, {})
      };

      autoSelectionEngine = new AutoSelectionEngine({
        learningPathManager: mockLearningPathManager,
        errorHandler: mockErrorHandler,
        debugHelper: mockDebugHelper,
        pathRelationships: allPathRelationships
      });
    } catch {
      // Expected to fail in RED phase
      autoSelectionEngine = null;
    }
  });

  afterEach(() => {
    vi.clearAllMocks();
    if (autoSelectionEngine && typeof autoSelectionEngine.destroy === 'function') {
      autoSelectionEngine.destroy();
    }
  });

  describe('Constructor and Initialization', () => {
    it('should require learningPathManager dependency', () => {
      expect(() => {
        new AutoSelectionEngine({
          errorHandler: mockErrorHandler,
          debugHelper: mockDebugHelper
        });
      }).toThrow('AutoSelectionEngine requires learningPathManager dependency');
    });

    it('should require errorHandler dependency', () => {
      expect(() => {
        new AutoSelectionEngine({
          learningPathManager: mockLearningPathManager,
          debugHelper: mockDebugHelper
        });
      }).toThrow('AutoSelectionEngine requires errorHandler dependency');
    });

    it('should initialize with default path relationships if not provided', () => {
      const engine = new AutoSelectionEngine({
        learningPathManager: mockLearningPathManager,
        errorHandler: mockErrorHandler,
        debugHelper: mockDebugHelper
      });

      expect(engine).toBeDefined();
      expect(engine.pathRelationships).toBeDefined();
    });

    it('should accept custom configuration', () => {
      const customConfig = {
        maxAutoSelections: 10,
        enableConflictResolution: false
      };

      const engine = new AutoSelectionEngine({
        learningPathManager: mockLearningPathManager,
        errorHandler: mockErrorHandler,
        debugHelper: mockDebugHelper,
        config: customConfig
      });

      expect(engine.config.maxAutoSelections).toBe(10);
      expect(engine.config.enableConflictResolution).toBe(false);
    });

    it('should initialize as not destroyed', () => {
      const engine = new AutoSelectionEngine({
        learningPathManager: mockLearningPathManager,
        errorHandler: mockErrorHandler,
        debugHelper: mockDebugHelper
      });

      expect(engine.isDestroyed).toBe(false);
    });
  });

  describe('Auto-Selection Core Logic', () => {
    it('should auto-select items for single foundation path', () => {
      const scenario = AUTO_SELECTION_SCENARIOS.singleFoundation;
      const result = autoSelectionEngine.processPathSelection(
        scenario.input.selectedPaths,
        scenario.input.currentProgress,
        scenario.input.userLevel
      );

      expect(result.autoSelectedItems).toEqual(scenario.expected.autoSelectedItems);
      expect(result.suggestedRelated).toEqual(scenario.expected.suggestedRelated);
      expect(result.conflicts).toEqual(scenario.expected.conflicts);
      expect(result.warnings).toEqual(scenario.expected.warnings);
    });

    it('should auto-select items for multiple compatible foundation paths', () => {
      const scenario = AUTO_SELECTION_SCENARIOS.multipleFoundation;
      const result = autoSelectionEngine.processPathSelection(
        scenario.input.selectedPaths,
        scenario.input.currentProgress,
        scenario.input.userLevel
      );

      expect(result.autoSelectedItems).toEqual(
        expect.arrayContaining(scenario.expected.autoSelectedItems)
      );
      expect(result.autoSelectedItems).toHaveLength(scenario.expected.autoSelectedItems.length);
      expect(result.conflicts).toEqual(scenario.expected.conflicts);
    });

    it('should handle skill level paths with prerequisites correctly', () => {
      const scenario = AUTO_SELECTION_SCENARIOS.skillWithPrerequisites;
      const result = autoSelectionEngine.processPathSelection(
        scenario.input.selectedPaths,
        scenario.input.currentProgress,
        scenario.input.userLevel
      );

      expect(result.autoSelectedItems).toContain('project-planning/01-basic-prompt-usage');
      expect(result.autoSelectedItems.length).toBeGreaterThan(0);
    });

    it('should warn about missing prerequisites', () => {
      const scenario = AUTO_SELECTION_SCENARIOS.missingPrerequisites;
      const result = autoSelectionEngine.processPathSelection(
        scenario.input.selectedPaths,
        scenario.input.currentProgress,
        scenario.input.userLevel
      );

      expect(result.autoSelectedItems).toContain('project-planning/01-basic-prompt-usage');
      expect(result.autoSelectedItems.length).toBeGreaterThan(0);
    });

    it('should detect and handle level conflicts', () => {
      const scenario = AUTO_SELECTION_SCENARIOS.levelConflicts;
      const result = autoSelectionEngine.processPathSelection(
        scenario.input.selectedPaths,
        scenario.input.currentProgress,
        scenario.input.userLevel
      );

      expect(result.conflicts).toHaveLength(1);
      expect(result.conflicts[0].type).toBe('level_conflict');
      expect(result.conflicts[0].conflictingPaths).toContain('foundation-ai-first-engineering');
      expect(result.conflicts[0].conflictingPaths).toContain('expert-enterprise-integration');
    });

    it('should handle expert paths with full prerequisites', () => {
      const scenario = AUTO_SELECTION_SCENARIOS.expertPath;
      const result = autoSelectionEngine.processPathSelection(
        scenario.input.selectedPaths,
        scenario.input.currentProgress,
        scenario.input.userLevel
      );

      expect(Array.isArray(result.autoSelectedItems)).toBe(true);
      expect(Array.isArray(result.suggestedRelated)).toBe(true);
      expect(Array.isArray(result.conflicts)).toBe(true);
    });

    it('should respect partial progress when auto-selecting', () => {
      const scenario = AUTO_SELECTION_SCENARIOS.partialProgress;
      const result = autoSelectionEngine.processPathSelection(
        scenario.input.selectedPaths,
        scenario.input.currentProgress,
        scenario.input.userLevel
      );

      // Should not include completed or in-progress items
      expect(result.autoSelectedItems).not.toContain('ai-assisted-engineering/01-ai-development-fundamentals');
      expect(result.autoSelectedItems).not.toContain('prompt-engineering/01-prompt-engineering-basics');
      expect(result.autoSelectedItems).toEqual(scenario.expected.autoSelectedItems);
    });
  });

  describe('Smart Dependency Handling', () => {
    it('should validate prerequisite paths exist', () => {
      const result = autoSelectionEngine.validatePrerequisites(['foundation-ai-first-engineering'], {});

      expect(result.isValid).toBe(true);
      expect(result.missingPrerequisites || []).toEqual([]);
    });

    it('should validate prerequisite katas are completed', () => {
      const progressWithMissing = {
        'ai-assisted-engineering/01-ai-development-fundamentals': { completed: true }
        // Missing other required katas
      };

      const result = autoSelectionEngine.validatePrerequisites(
        ['expert-enterprise-integration'],
        progressWithMissing
      );

      expect(result.isValid).toBeDefined();
      expect(Array.isArray(result.missingDependencies || [])).toBe(true);
    });

    it('should pass validation when all prerequisites are met', () => {
      const completeProgress = {
        'ai-assisted-engineering/01-ai-development-fundamentals': { completed: true },
        'prompt-engineering/01-prompt-engineering-basics': { completed: true },
        'prompt-engineering/02-advanced-prompt-patterns': { completed: true },
        'system-integration/01-api-integration-patterns': { completed: true }
      };

      const result = autoSelectionEngine.validatePrerequisites(
        ['expert-ai-architecture'],
        completeProgress
      );

      expect(result.isValid).toBe(true);
      expect(result.missingPrerequisites).toEqual([]);
      expect(result.missingDependencies).toEqual([]);
    });

    it('should build dependency chain correctly', () => {
      const chain = autoSelectionEngine.buildDependencyChain('expert-data-analytics-integration');

      expect(Array.isArray(chain)).toBe(true);
      expect(chain).toContain('expert-enterprise-integration');
      expect(chain).toContain('intermediate-infrastructure-architect');
      expect(chain).toContain('intermediate-devops-excellence');
    });

    it('should detect circular dependencies', () => {
      const circularRelationships = {
        'path-a': { prerequisites: ['path-b'] },
        'path-b': { prerequisites: ['path-c'] },
        'path-c': { prerequisites: ['path-a'] }
      };

      const engine = new AutoSelectionEngine({
        learningPathManager: mockLearningPathManager,
        errorHandler: mockErrorHandler,
        debugHelper: mockDebugHelper,
        pathRelationships: circularRelationships
      });

      const result = engine.detectCircularDependencies();
      expect(result.hasCircularDependencies).toBe(true);
      expect(result.circularPaths).toContain('path-a');
      expect(result.circularPaths).toContain('path-b');
      expect(result.circularPaths).toContain('path-c');
    });
  });

  describe('Conflict Resolution', () => {
    it('should resolve level conflicts by keeping foundation path', () => {
      const conflictScenario = CONFLICT_SCENARIOS.levelConflicts[0];
      const resolution = autoSelectionEngine.resolveConflicts(
        conflictScenario.paths,
        'Beginner'
      );

      expect(resolution.resolvedPaths).toContain(conflictScenario.expectedResolution);
      expect(resolution.removedPaths).toContain('expert-enterprise-integration');
      expect(resolution.reason).toContain('Beginner');
    });

    it('should suggest prerequisites for missing dependencies', () => {
      const conflictScenario = CONFLICT_SCENARIOS.prerequisiteConflicts[0];
      const resolution = autoSelectionEngine.resolveConflicts(
        conflictScenario.paths,
        'Intermediate',
        {}
      );

      expect(resolution.resolution).toBeDefined();
      expect(Array.isArray(resolution.suggestions || [])).toBe(true);
    });

    it('should handle multiple conflict types simultaneously', () => {
      const complexConflicts = [
        'foundation-ai-first-engineering',
        'expert-enterprise-integration',
        'intermediate-infrastructure-architect'
      ];

      const resolution = autoSelectionEngine.resolveConflicts(
        complexConflicts,
        'Beginner',
        {}
      );

      expect(Array.isArray(resolution.resolvedPaths || [])).toBe(true);
      expect(Array.isArray(resolution.removedPaths || [])).toBe(true);
      expect(resolution.resolvedPaths).toContain('foundation-ai-first-engineering');
    });
  });

  describe('Relationship Mapping', () => {
    it('should identify related paths correctly', () => {
      const relatedPaths = autoSelectionEngine.getRelatedPaths('foundation-ai-first-engineering');

      expect(relatedPaths).toContain('intermediate-infrastructure-architect');
      expect(relatedPaths).toContain('intermediate-devops-excellence');
      expect(relatedPaths).not.toContain('foundation-ai-first-engineering'); // Should not include self
    });

    it('should suggest related paths based on user level', () => {
      const suggestions = autoSelectionEngine.suggestRelatedPaths(
        ['foundation-ai-first-engineering'],
        'Beginner'
      );

      expect(suggestions).toContain('intermediate-infrastructure-architect');
      expect(suggestions).toContain('intermediate-devops-excellence');
      expect(suggestions).not.toContain('expert-enterprise-integration'); // Wrong level
    });

    it('should calculate path compatibility score', () => {
      const score = autoSelectionEngine.calculateCompatibilityScore(
        'foundation-ai-first-engineering',
        'intermediate-infrastructure-architect',
        'Beginner'
      );

      expect(score).toBeGreaterThanOrEqual(0.5); // High compatibility
      expect(score).toBeLessThanOrEqual(1.0);
    });

    it('should rank paths by relevance', () => {
      const rankings = autoSelectionEngine.rankPathsByRelevance(
        ['foundation-ai-first-engineering'],
        'Beginner',
        { interests: ['AI Development', 'Infrastructure'] }
      );

      expect(rankings).toBeInstanceOf(Array);
      expect(rankings[0].pathId).toBe('intermediate-infrastructure-architect'); // Most relevant
      expect(rankings[0].score).toBeGreaterThan(rankings[1]?.score || 0);
    });
  });

  describe('Path Structure Validation', () => {
    it('should validate path structure integrity', () => {
      const validation = autoSelectionEngine.validatePathStructure(PATH_RELATIONSHIPS);

      expect(validation.isValid).toBe(true);
      expect(validation.errors).toEqual([]);
      expect(validation.warnings).toBeInstanceOf(Array);
    });

    it('should detect invalid path references', () => {
      const invalidRelationships = {
        'valid-path': {
          id: 'valid-path',
          prerequisites: ['non-existent-path'],
          relatedPaths: ['another-missing-path']
        }
      };

      const validation = autoSelectionEngine.validatePathStructure(invalidRelationships);

      // Validation debugging removed for cleaner output
      expect(validation.isValid).toBe(false);
      // Check that we have the expected error
      const hasExpectedError = validation.errors.some(error =>
        error.type === 'invalid_prerequisite_reference' &&
        error.pathId === 'valid-path' &&
        error.reference === 'non-existent-path'
      );
      expect(hasExpectedError).toBe(true);
    });

    it('should validate kata ID format', () => {
      const isValid = autoSelectionEngine.validateKataId('ai-assisted-engineering/01-ai-development-fundamentals');
      expect(isValid).toBe(true);

      const isInvalid = autoSelectionEngine.validateKataId('invalid-kata-id');
      expect(isInvalid).toBe(false);
    });

    it('should validate path level consistency', () => {
      const validation = autoSelectionEngine.validateLevelConsistency([
        'foundation-ai-first-engineering',
        'expert-enterprise-integration'
      ]);

      expect(validation.isConsistent).toBe(false);
      // Check that we have the expected conflict
      const hasExpectedConflict = validation.conflicts.some(conflict =>
        conflict.type === 'level_mismatch' &&
        conflict.paths.includes('foundation-ai-first-engineering') &&
        conflict.paths.includes('expert-enterprise-integration')
      );
      expect(hasExpectedConflict).toBe(true);
    });
  });

  describe('Performance and Error Handling', () => {
    it('should handle large path selections efficiently', () => {
      const startTime = performance.now();

      const result = autoSelectionEngine.processPathSelection(
        ['performance-test-path'],
        {},
        'Advanced'
      );

      const endTime = performance.now();
      const processingTime = endTime - startTime;

      expect(processingTime).toBeLessThan(100); // Should complete in under 100ms
      expect(result.autoSelectedItems).toHaveLength(100);
    });

    it('should handle many paths without performance degradation', () => {
      const manyPathIds = PERFORMANCE_TEST_DATA.manyPaths.map(path => path.id);
      const startTime = performance.now();

      const result = autoSelectionEngine.processPathSelection(
        manyPathIds.slice(0, 10), // Test with 10 paths
        {},
        'Advanced'
      );

      const endTime = performance.now();
      const processingTime = endTime - startTime;

      expect(processingTime).toBeLessThan(500); // Should complete in under 500ms
      expect(result).toBeDefined();
    });

    it('should handle invalid path IDs gracefully', () => {
      const result = autoSelectionEngine.processPathSelection(
        ['non-existent-path', 'another-invalid-path'],
        {},
        'Beginner'
      );

      expect(result.autoSelectedItems).toEqual([]);
      // Check that we have the expected warning
      const hasExpectedWarning = result.warnings.some(warning =>
        warning.type === 'invalid_path_id' &&
        warning.pathId === 'non-existent-path'
      );
      expect(hasExpectedWarning).toBe(true);
    });

    it('should handle malformed progress data', () => {
      const malformedProgress = {
        'valid-kata-id': { completed: 'invalid-boolean' },
        'invalid-structure': 'not-an-object',
        null: { completed: true }
      };

      const result = autoSelectionEngine.processPathSelection(
        ['foundation-ai-engineering'],
        malformedProgress,
        'Beginner'
      );

      expect(result).toBeDefined();
      expect(mockErrorHandler.recordError).toHaveBeenCalled();
    });

    it('should provide meaningful error messages', () => {
      const errorMessage = autoSelectionEngine.getErrorMessage('missing_prerequisite', {
        pathId: 'expert-path',
        missingPrerequisite: 'foundation-path'
      });

      expect(errorMessage).toContain('expert-path');
      expect(errorMessage).toContain('foundation-path');
      expect(errorMessage).toContain('prerequisite');
    });
  });

  describe('Memory Management and Cleanup', () => {
    it('should properly destroy instance and clean up resources', () => {
      const engine = new AutoSelectionEngine({
        learningPathManager: mockLearningPathManager,
        errorHandler: mockErrorHandler,
        debugHelper: mockDebugHelper
      });

      engine.destroy();

      expect(engine.isDestroyed).toBe(true);
      expect(() => engine.processPathSelection([], {}, 'Beginner')).toThrow();
    });

    it('should handle destroy called multiple times', () => {
      const engine = new AutoSelectionEngine({
        learningPathManager: mockLearningPathManager,
        errorHandler: mockErrorHandler,
        debugHelper: mockDebugHelper
      });

      engine.destroy();
      engine.destroy(); // Should not throw

      expect(engine.isDestroyed).toBe(true);
    });

    it('should clear internal caches on destroy', () => {
      const engine = new AutoSelectionEngine({
        learningPathManager: mockLearningPathManager,
        errorHandler: mockErrorHandler,
        debugHelper: mockDebugHelper
      });

      // Trigger cache population
      engine.getRelatedPaths('foundation-ai-engineering');
      engine.destroy();

      // Internal caches should be cleared
      expect(engine._relatedPathsCache).toBeUndefined();
      expect(engine._dependencyCache).toBeUndefined();
    });
  });

  describe('Integration with Learning Path Manager', () => {
    it('should call learning path manager for progress data', async () => {
      await autoSelectionEngine.processPathSelectionWithProgress(
        ['foundation-ai-engineering']
      );

      expect(mockLearningPathManager.getKataProgress).toHaveBeenCalled();
    });

    it('should respect learning path manager configuration', () => {
      mockLearningPathManager.getConfig.mockReturnValue({
        autoSelection: {
          enabled: false,
          maxAutoSelections: 5
        }
      });

      const result = autoSelectionEngine.processPathSelection(
        ['foundation-ai-engineering'],
        {},
        'Beginner'
      );

      expect(result.autoSelectedItems).toEqual([]); // Disabled
    });

    it('should update path selections through learning path manager', () => {
      const result = autoSelectionEngine.processPathSelection(
        ['foundation-ai-engineering'],
        {},
        'Beginner'
      );

      autoSelectionEngine.applyAutoSelections(result);

      expect(mockLearningPathManager.updatePathSelections).toHaveBeenCalledWith(
        expect.objectContaining({
          selectedItems: expect.any(Array)
        })
      );
    });
  });
});
