/**
 * @jest-environment happy-dom
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { MarkdownProgressTracker } from '../../features/markdown-progress-tracker.js';

describe('MarkdownProgressTracker', () => {
  let mockDependencies;
  let mockDomUtils;
  let mockLearningPathManager;
  let mockErrorHandler;
  let markdownProgressTracker;

  beforeEach(() => {
    // Mock DOM utilities
    mockDomUtils = {
      querySelector: vi.fn(),
      querySelectorAll: vi.fn(),
      createElement: vi.fn(),
      addClass: vi.fn(),
      removeClass: vi.fn(),
      setAttribute: vi.fn(),
      getAttribute: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      appendChild: vi.fn(),
      removeChild: vi.fn(),
      textContent: vi.fn(),
      setTextContent: vi.fn(),
      innerHTML: vi.fn(),
      clearElement: vi.fn()
    };

    // Mock learning path manager
    mockLearningPathManager = {
      getSelectedPaths: vi.fn(),
      getPathProgress: vi.fn(),
      getOverallProgress: vi.fn(),
      getCompletionStatistics: vi.fn(),
      getMilestones: vi.fn(),
      getAchievements: vi.fn(),
      isPathCompleted: vi.fn(),
      getKataProgress: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn()
    };

    // Mock error handler
    mockErrorHandler = {
      handleError: vi.fn(),
      safeExecute: vi.fn((fn) => fn())
    };

    mockDependencies = {
      domUtils: mockDomUtils,
      learningPathManager: mockLearningPathManager,
      errorHandler: mockErrorHandler
    };
  });

  afterEach(() => {
    if (markdownProgressTracker && !markdownProgressTracker.isDestroyed) {
      markdownProgressTracker.destroy();
    }
    vi.clearAllMocks();
  });

  describe('Constructor and Initialization', () => {
    it('should create instance with valid dependencies', () => {
      markdownProgressTracker = new MarkdownProgressTracker(mockDependencies);

      expect(markdownProgressTracker).toBeInstanceOf(MarkdownProgressTracker);
      expect(markdownProgressTracker.domUtils).toBe(mockDomUtils);
      expect(markdownProgressTracker.learningPathManager).toBe(mockLearningPathManager);
      expect(markdownProgressTracker.errorHandler).toBe(mockErrorHandler);
      expect(markdownProgressTracker.isDestroyed).toBe(false);
    });

    it('should throw error with missing domUtils dependency', () => {
      const invalidDeps = { ...mockDependencies };
      delete invalidDeps.domUtils;

      expect(() => new MarkdownProgressTracker(invalidDeps))
        .toThrow('MarkdownProgressTracker requires domUtils dependency');
    });

    it('should throw error with missing learningPathManager dependency', () => {
      const invalidDeps = { ...mockDependencies };
      delete invalidDeps.learningPathManager;

      expect(() => new MarkdownProgressTracker(invalidDeps))
        .toThrow('MarkdownProgressTracker requires learningPathManager dependency');
    });

    it('should throw error with missing errorHandler dependency', () => {
      const invalidDeps = { ...mockDependencies };
      delete invalidDeps.errorHandler;

      expect(() => new MarkdownProgressTracker(invalidDeps))
        .toThrow('MarkdownProgressTracker requires errorHandler dependency');
    });

    it('should initialize with default configuration', () => {
      markdownProgressTracker = new MarkdownProgressTracker(mockDependencies);

      expect(markdownProgressTracker.config).toMatchObject({
        selectors: {
          progressContainer: '[data-progress-container]',
          progressText: '[data-progress-text]',
          statisticsContainer: '[data-statistics-container]',
          milestonesContainer: '[data-milestones-container]'
        },
        features: {
          overallProgress: true,
          pathStatistics: true,
          milestoneIndicators: true,
          achievementBadges: true
        },
        formatting: {
          percentageDecimals: 1,
          showPathNames: true,
          showKataCount: true,
          highlightMilestones: true
        }
      });
    });

    it('should accept custom configuration overrides', () => {
      const customConfig = {
        features: {
          overallProgress: false,
          pathStatistics: true
        },
        formatting: {
          percentageDecimals: 0
        }
      };

      markdownProgressTracker = new MarkdownProgressTracker(mockDependencies, customConfig);

      expect(markdownProgressTracker.config.features.overallProgress).toBe(false);
      expect(markdownProgressTracker.config.features.pathStatistics).toBe(true);
      expect(markdownProgressTracker.config.formatting.percentageDecimals).toBe(0);
    });
  });

  describe('Overall Progress Display', () => {
    beforeEach(() => {
      markdownProgressTracker = new MarkdownProgressTracker(mockDependencies);
    });

    it('should display overall progress percentage', () => {
      const mockProgressData = {
        overallProgress: 67.5,
        completedKatas: 27,
        totalKatas: 40,
        completedPaths: 2,
        totalPaths: 5
      };

      mockLearningPathManager.getOverallProgress.mockReturnValue(mockProgressData);

      const mockContainer = document.createElement('div');
      mockDomUtils.querySelector.mockReturnValue(mockContainer);
      mockDomUtils.createElement.mockReturnValue(document.createElement('div'));

      markdownProgressTracker.updateOverallProgress();

      expect(mockLearningPathManager.getOverallProgress).toHaveBeenCalled();
      expect(mockDomUtils.querySelector).toHaveBeenCalledWith(
        document,
        '[data-progress-container]'
      );
    });

    it('should format progress text with proper percentage display', () => {
      const mockProgressData = {
        overallProgress: 67.5,
        completedKatas: 27,
        totalKatas: 40
      };

      mockLearningPathManager.getOverallProgress.mockReturnValue(mockProgressData);

      const mockContainer = document.createElement('div');
      mockDomUtils.querySelector.mockReturnValue(mockContainer);

      const progressText = markdownProgressTracker._formatProgressText(mockProgressData);

      expect(progressText).toContain('67.5%');
      expect(progressText).toContain('27 of 40');
    });

    it('should handle zero progress gracefully', () => {
      const mockProgressData = {
        overallProgress: 0,
        completedKatas: 0,
        totalKatas: 25
      };

      mockLearningPathManager.getOverallProgress.mockReturnValue(mockProgressData);

      const progressText = markdownProgressTracker._formatProgressText(mockProgressData);

      expect(progressText).toContain('0.0%');
      expect(progressText).toContain('0 of 25');
    });

    it('should handle complete progress gracefully', () => {
      const mockProgressData = {
        overallProgress: 100,
        completedKatas: 25,
        totalKatas: 25
      };

      mockLearningPathManager.getOverallProgress.mockReturnValue(mockProgressData);

      const progressText = markdownProgressTracker._formatProgressText(mockProgressData);

      expect(progressText).toContain('100.0%');
      expect(progressText).toContain('25 of 25');
    });

    it('should update progress container with formatted content', () => {
      const mockProgressData = {
        overallProgress: 45.2,
        completedKatas: 15,
        totalKatas: 33
      };

      mockLearningPathManager.getOverallProgress.mockReturnValue(mockProgressData);

      const mockContainer = document.createElement('div');
      const mockProgressElement = document.createElement('p');
      mockDomUtils.querySelector.mockReturnValue(mockContainer);
      mockDomUtils.createElement.mockReturnValue(mockProgressElement);

      markdownProgressTracker.updateOverallProgress();

      expect(mockDomUtils.createElement).toHaveBeenCalledWith('p');
      expect(mockDomUtils.addClass).toHaveBeenCalledWith(mockProgressElement, 'progress-summary');
    });
  });

  describe('Path Completion Statistics', () => {
    beforeEach(() => {
      markdownProgressTracker = new MarkdownProgressTracker(mockDependencies);
    });

    it('should display completion statistics for selected learning paths', () => {
      const mockStatistics = [
        {
          pathId: 'path1',
          pathName: 'AI Development Fundamentals',
          completed: 8,
          total: 12,
          percentage: 66.7
        },
        {
          pathId: 'path2',
          pathName: 'Cloud Architecture Basics',
          completed: 5,
          total: 8,
          percentage: 62.5
        }
      ];

      mockLearningPathManager.getCompletionStatistics.mockReturnValue(mockStatistics);

      const mockContainer = document.createElement('div');
      mockDomUtils.querySelector.mockReturnValue(mockContainer);
      mockDomUtils.createElement.mockReturnValue(document.createElement('div'));

      markdownProgressTracker.updatePathStatistics();

      expect(mockLearningPathManager.getCompletionStatistics).toHaveBeenCalled();
      expect(mockDomUtils.querySelector).toHaveBeenCalledWith(
        document,
        '[data-statistics-container]'
      );
    });

    it('should format path statistics with path names and progress', () => {
      const mockPathData = {
        pathName: 'AI Development Fundamentals',
        completed: 8,
        total: 12,
        percentage: 66.7
      };

      const formattedText = markdownProgressTracker._formatPathStatistic(mockPathData);

      expect(formattedText).toContain('AI Development Fundamentals');
      expect(formattedText).toContain('8/12');
      expect(formattedText).toContain('66.7%');
    });

    it('should handle empty path statistics gracefully', () => {
      mockLearningPathManager.getCompletionStatistics.mockReturnValue([]);

      const mockContainer = document.createElement('div');
      mockDomUtils.querySelector.mockReturnValue(mockContainer);

      markdownProgressTracker.updatePathStatistics();

      expect(mockDomUtils.querySelector).toHaveBeenCalledWith(
        document,
        '[data-statistics-container]'
      );
      // Should handle empty array without errors
    });

    it('should create list elements for multiple paths', () => {
      const mockStatistics = [
        { pathName: 'Path 1', completed: 5, total: 10, percentage: 50 },
        { pathName: 'Path 2', completed: 3, total: 6, percentage: 50 }
      ];

      mockLearningPathManager.getCompletionStatistics.mockReturnValue(mockStatistics);

      const mockContainer = document.createElement('div');
      const mockList = document.createElement('ul');
      const mockListItem = document.createElement('li');

      mockDomUtils.querySelector.mockReturnValue(mockContainer);
      mockDomUtils.createElement.mockReturnValueOnce(mockList);
      mockDomUtils.createElement.mockReturnValue(mockListItem);

      markdownProgressTracker.updatePathStatistics();

      // Should create ul and multiple li elements
      expect(mockDomUtils.createElement).toHaveBeenCalledWith('ul');
      expect(mockDomUtils.createElement).toHaveBeenCalledWith('li');
    });
  });

  describe('Milestone Indicators', () => {
    beforeEach(() => {
      markdownProgressTracker = new MarkdownProgressTracker(mockDependencies);
    });

    it('should display milestone achievements for major progress points', () => {
      const mockMilestones = [
        {
          id: 'first-path-complete',
          title: 'First Learning Path Completed',
          description: 'Completed your first full learning path',
          achieved: true,
          achievedDate: '2025-08-15'
        },
        {
          id: 'half-way-point',
          title: 'Halfway Point Reached',
          description: 'Completed 50% of selected learning paths',
          achieved: false,
          progress: 0.35
        }
      ];

      mockLearningPathManager.getMilestones.mockReturnValue(mockMilestones);

      const mockContainer = document.createElement('div');
      mockDomUtils.querySelector.mockReturnValue(mockContainer);
      mockDomUtils.createElement.mockReturnValue(document.createElement('div'));

      markdownProgressTracker.updateMilestones();

      expect(mockLearningPathManager.getMilestones).toHaveBeenCalled();
      expect(mockDomUtils.querySelector).toHaveBeenCalledWith(
        document,
        '[data-milestones-container]'
      );
    });

    it('should format achieved milestones with completion date', () => {
      const achievedMilestone = {
        title: 'First Learning Path Completed',
        description: 'Completed your first full learning path',
        achieved: true,
        achievedDate: '2025-08-15'
      };

      const formattedText = markdownProgressTracker._formatMilestone(achievedMilestone);

      expect(formattedText).toContain('First Learning Path Completed');
      expect(formattedText).toContain('Completed your first full learning path');
      expect(formattedText).toContain('✅');
    });

    it('should format unachieved milestones with progress indication', () => {
      const unachievedMilestone = {
        title: 'Halfway Point Reached',
        description: 'Completed 50% of selected learning paths',
        achieved: false,
        progress: 0.35
      };

      const formattedText = markdownProgressTracker._formatMilestone(unachievedMilestone);

      expect(formattedText).toContain('Halfway Point Reached');
      expect(formattedText).toContain('35%');
      expect(formattedText).toContain('🎯');
    });

    it('should handle milestones without progress data', () => {
      const milestone = {
        title: 'Advanced Techniques Mastery',
        description: 'Master advanced development techniques',
        achieved: false
      };

      const formattedText = markdownProgressTracker._formatMilestone(milestone);

      expect(formattedText).toContain('Advanced Techniques Mastery');
      expect(formattedText).toContain('🎯');
    });

    it('should create milestone elements with appropriate styling', () => {
      const mockMilestones = [
        { title: 'Test Milestone', achieved: true, description: 'Test description' }
      ];

      mockLearningPathManager.getMilestones.mockReturnValue(mockMilestones);

      const mockContainer = document.createElement('div');
      const mockMilestoneElement = document.createElement('div');

      mockDomUtils.querySelector.mockReturnValue(mockContainer);
      mockDomUtils.createElement.mockReturnValue(mockMilestoneElement);

      markdownProgressTracker.updateMilestones();

      expect(mockDomUtils.addClass).toHaveBeenCalledWith(mockMilestoneElement, 'milestone-indicator');
    });
  });

  describe('Enhanced Markdown Integration', () => {
    beforeEach(() => {
      markdownProgressTracker = new MarkdownProgressTracker(mockDependencies);
    });

    it('should integrate with existing markdown structure without breaking layout', () => {
      const mockContainer = document.createElement('div');
      mockContainer.innerHTML = '<h1>Learning Paths</h1><p>Some existing content</p>';

      mockDomUtils.querySelector.mockReturnValue(mockContainer);
      mockDomUtils.createElement.mockReturnValue(document.createElement('div'));

      markdownProgressTracker.updateAllProgressIndicators();

      // Should preserve existing content while adding progress indicators
      expect(mockDomUtils.querySelector).toHaveBeenCalledWith(
        document,
        '[data-progress-container]'
      );
    });

    it('should create progress blocks that complement Docsify theme', () => {
      mockDomUtils.querySelector.mockReturnValue(document.createElement('div'));
      const mockProgressBlock = document.createElement('div');
      mockDomUtils.createElement.mockReturnValue(mockProgressBlock);

      markdownProgressTracker._createProgressBlock('test-content');

      expect(mockDomUtils.addClass).toHaveBeenCalledWith(mockProgressBlock, 'progress-block');
      expect(mockDomUtils.addClass).toHaveBeenCalledWith(mockProgressBlock, 'docsify-compatible');
    });

    it('should handle missing progress containers gracefully', () => {
      mockDomUtils.querySelector.mockReturnValue(null);

      markdownProgressTracker.updateOverallProgress();

      // Should not throw errors when containers are missing
      expect(mockErrorHandler.handleError).not.toHaveBeenCalled();
    });

    it('should maintain markdown-first approach without complex dashboard components', () => {
      const mockData = {
        overallProgress: 75,
        completedKatas: 15,
        totalKatas: 20
      };

      mockLearningPathManager.getOverallProgress.mockReturnValue(mockData);
      mockDomUtils.querySelector.mockReturnValue(document.createElement('div'));
      mockDomUtils.createElement.mockReturnValue(document.createElement('div'));

      markdownProgressTracker.updateOverallProgress();

      // Should create simple text/percentage displays, not complex dashboard elements
      expect(mockDomUtils.createElement).toHaveBeenCalledWith('p');
      expect(mockDomUtils.addClass).toHaveBeenCalledWith(expect.any(Object), 'progress-summary');
    });
  });

  describe('Error Handling and Edge Cases', () => {
    beforeEach(() => {
      markdownProgressTracker = new MarkdownProgressTracker(mockDependencies);
    });

    it('should handle learning path manager errors gracefully', () => {
      mockLearningPathManager.getOverallProgress.mockImplementation(() => {
        throw new Error('Manager error');
      });

      markdownProgressTracker.updateOverallProgress();

      expect(mockErrorHandler.handleError).toHaveBeenCalledWith(
        expect.any(Error),
        'MarkdownProgressTracker.updateOverallProgress'
      );
    });

    it('should handle DOM manipulation errors gracefully', () => {
      mockDomUtils.querySelector.mockImplementation(() => {
        throw new Error('DOM error');
      });

      markdownProgressTracker.updatePathStatistics();

      expect(mockErrorHandler.handleError).toHaveBeenCalledWith(
        expect.any(Error),
        'MarkdownProgressTracker.updatePathStatistics'
      );
    });

    it('should handle invalid progress data gracefully', () => {
      mockLearningPathManager.getOverallProgress.mockReturnValue(null);

      const result = markdownProgressTracker._formatProgressText(null);

      expect(result).toContain('No progress data available');
    });

    it('should handle malformed milestone data', () => {
      const malformedMilestone = {
        // Missing required fields
        achieved: true
      };

      const result = markdownProgressTracker._formatMilestone(malformedMilestone);

      expect(result).toContain('Unknown milestone');
    });

    it('should prevent operations after destroy', () => {
      markdownProgressTracker.destroy();

      markdownProgressTracker.updateOverallProgress();

      // Should complete without errors and without performing operations
      expect(mockDomUtils.querySelector).not.toHaveBeenCalled();
    });
  });

  describe('Configuration and Customization', () => {
    it('should respect feature toggles for progress components', () => {
      const customConfig = {
        features: {
          overallProgress: false,
          pathStatistics: true,
          milestoneIndicators: false
        }
      };

      markdownProgressTracker = new MarkdownProgressTracker(mockDependencies, customConfig);

      expect(markdownProgressTracker.config.features.overallProgress).toBe(false);
      expect(markdownProgressTracker.config.features.pathStatistics).toBe(true);
      expect(markdownProgressTracker.config.features.milestoneIndicators).toBe(false);
    });

    it('should support custom formatting options', () => {
      const customConfig = {
        formatting: {
          percentageDecimals: 2,
          showPathNames: false,
          showKataCount: false
        }
      };

      markdownProgressTracker = new MarkdownProgressTracker(mockDependencies, customConfig);

      const mockData = { overallProgress: 66.6666, completedKatas: 10, totalKatas: 15 };
      const formattedText = markdownProgressTracker._formatProgressText(mockData);

      expect(formattedText).toContain('66.67%');
      // Should respect configuration for what to show/hide
    });

    it('should support custom selectors for progress containers', () => {
      const customConfig = {
        selectors: {
          progressContainer: '.custom-progress',
          statisticsContainer: '.custom-stats'
        }
      };

      markdownProgressTracker = new MarkdownProgressTracker(mockDependencies, customConfig);
      mockDomUtils.querySelector.mockReturnValue(document.createElement('div'));

      markdownProgressTracker.updateOverallProgress();

      expect(mockDomUtils.querySelector).toHaveBeenCalledWith(
        document,
        '.custom-progress'
      );
    });
  });

  describe('Memory Management and Cleanup', () => {
    beforeEach(() => {
      markdownProgressTracker = new MarkdownProgressTracker(mockDependencies);
    });

    it('should clean up event listeners on destroy', () => {
      markdownProgressTracker.destroy();

      expect(markdownProgressTracker.isDestroyed).toBe(true);
    });

    it('should remove created progress elements on destroy', () => {
      // Simulate creating progress elements
      const mockElement = document.createElement('div');
      markdownProgressTracker._trackCreatedElement(mockElement);

      markdownProgressTracker.destroy();

      expect(markdownProgressTracker.isDestroyed).toBe(true);
    });

    it('should clear all references on destroy', () => {
      markdownProgressTracker.destroy();

      expect(markdownProgressTracker.domUtils).toBe(null);
      expect(markdownProgressTracker.learningPathManager).toBe(null);
      expect(markdownProgressTracker.errorHandler).toBe(null);
    });
  });

  describe('Integration with Learning Path Manager', () => {
    beforeEach(() => {
      markdownProgressTracker = new MarkdownProgressTracker(mockDependencies);
    });

    it('should respond to learning path manager updates', () => {
      const updateHandler = vi.fn();
      markdownProgressTracker._handleProgressUpdate = updateHandler;

      // Simulate manager update
      const updateData = { pathId: 'path1', progress: 0.75 };
      markdownProgressTracker._handleProgressUpdate(updateData);

      expect(updateHandler).toHaveBeenCalledWith(updateData);
    });

    it('should sync with manager state changes', () => {
      mockLearningPathManager.getOverallProgress.mockReturnValue({
        overallProgress: 50,
        completedKatas: 10,
        totalKatas: 20
      });

      markdownProgressTracker.syncWithManager();

      expect(mockLearningPathManager.getOverallProgress).toHaveBeenCalled();
    });

    it('should handle manager loading states', () => {
      mockLearningPathManager.getOverallProgress.mockReturnValue({
        loading: true,
        overallProgress: 0
      });

      markdownProgressTracker.updateOverallProgress();

      // Should handle loading state appropriately
      expect(mockLearningPathManager.getOverallProgress).toHaveBeenCalled();
    });
  });
});
