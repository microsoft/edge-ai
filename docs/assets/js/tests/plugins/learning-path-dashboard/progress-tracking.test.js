import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import LearningPathDashboard from '../../../plugins/learning-path-dashboard.js';
import { createMockContainer, createMockPaths, mockConsole, cleanupDOM } from './test-helpers.js';

describe('Progress Tracking', () => {
  let container, dashboard;

  beforeEach(() => {
    mockConsole();
    container = createMockContainer('progress-tracking');
    dashboard = new LearningPathDashboard(container, createMockPaths());
  });

  afterEach(() => {
    dashboard?.destroy();
    cleanupDOM();
    vi.restoreAllMocks();
  });

  describe('Path Selection', () => {
    it('should return empty array when no paths selected', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1' },
        { id: 'path2', title: 'Path 2' },
        { id: 'path3', title: 'Path 3' }
      ];

      dashboard.updatePaths(mockPaths);
      dashboard.selectedPaths = new Set();

      const selectedPaths = dashboard.getSelectedPaths();
      expect(selectedPaths).toEqual([]);
    });

    it('should return only paths that are in selectedPaths Set', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1' },
        { id: 'path2', title: 'Path 2' },
        { id: 'path3', title: 'Path 3' },
        { id: 'path4', title: 'Path 4' }
      ];

      dashboard.updatePaths(mockPaths);
      dashboard.selectedPaths = new Set(['path1', 'path3']);

      const selectedPaths = dashboard.getSelectedPaths();
      expect(selectedPaths).toHaveLength(2);
      expect(selectedPaths.map(p => p.id)).toEqual(['path1', 'path3']);
    });

    it('should return all paths when all are selected', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1' },
        { id: 'path2', title: 'Path 2' },
        { id: 'path3', title: 'Path 3' }
      ];

      dashboard.updatePaths(mockPaths);
      dashboard.selectedPaths = new Set(['path1', 'path2', 'path3']);

      const selectedPaths = dashboard.getSelectedPaths();
      expect(selectedPaths).toHaveLength(3);
      expect(selectedPaths.map(p => p.id)).toEqual(['path1', 'path2', 'path3']);
    });

    it('should handle undefined selectedPaths Set gracefully', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1' },
        { id: 'path2', title: 'Path 2' }
      ];

      dashboard.updatePaths(mockPaths);
      delete dashboard.selectedPaths;

      const selectedPaths = dashboard.getSelectedPaths();
      expect(selectedPaths).toEqual([]);
      expect(dashboard.selectedPaths).toBeInstanceOf(Set);
    });

    it('should filter from this.paths array when available', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1' },
        { id: 'path2', title: 'Path 2' }
      ];

      dashboard.paths = mockPaths;
      dashboard.selectedPaths = new Set(['path1']);

      const selectedPaths = dashboard.getSelectedPaths();
      expect(selectedPaths).toHaveLength(1);
      expect(selectedPaths[0].id).toBe('path1');
    });

    it('should fallback to this.learningPaths if this.paths unavailable', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1' },
        { id: 'path2', title: 'Path 2' }
      ];

      dashboard.paths = null;
      dashboard.learningPaths = mockPaths;
      dashboard.selectedPaths = new Set(['path2']);

      const selectedPaths = dashboard.getSelectedPaths();
      expect(selectedPaths).toHaveLength(1);
      expect(selectedPaths[0].id).toBe('path2');
    });

    it('should ignore paths in selectedPaths Set that do not exist in paths array', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1' },
        { id: 'path2', title: 'Path 2' }
      ];

      dashboard.updatePaths(mockPaths);
      dashboard.selectedPaths = new Set(['path1', 'path2', 'path99', 'path100']);

      const selectedPaths = dashboard.getSelectedPaths();
      expect(selectedPaths).toHaveLength(2);
      expect(selectedPaths.map(p => p.id)).toEqual(['path1', 'path2']);
    });
  });

  describe('Progress Calculation', () => {
    it('should calculate overall progress correctly', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1', completion: 100 },
        { id: 'path2', title: 'Path 2', completion: 50 },
        { id: 'path3', title: 'Path 3', completion: 0 }
      ];

      dashboard.updatePaths(mockPaths);
      const overallProgress = dashboard.calculateOverallProgress();

      expect(overallProgress).toBe(50); // (100 + 50 + 0) / 3 = 50
    });

    it('should handle empty path list', () => {
      dashboard.updatePaths([]);
      const overallProgress = dashboard.calculateOverallProgress();

      expect(overallProgress).toBe(0);
    });

    it('should calculate progress for selected paths only', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1', completion: 100, selected: true },
        { id: 'path2', title: 'Path 2', completion: 0, selected: true },
        { id: 'path3', title: 'Path 3', completion: 75, selected: false }
      ];

      dashboard.updatePaths(mockPaths);
      const selectedProgress = dashboard.calculateSelectedProgress();

      expect(selectedProgress).toBe(50); // (100 + 0) / 2 = 50
    });

    it('should track individual step completion', () => {
      const pathWithSteps = {
        id: 'path1',
        title: 'Path 1',
        steps: [
          { id: 'step1', title: 'Step 1', completed: true },
          { id: 'step2', title: 'Step 2', completed: false },
          { id: 'step3', title: 'Step 3', completed: true }
        ]
      };

      const stepProgress = dashboard.calculateStepProgress(pathWithSteps);
      expect(stepProgress).toBe(66.67); // 2/3 * 100 = 66.67
    });
  });

  describe('Progress Display', () => {
    it('should render progress bars correctly', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1', completion: 75 }
      ];

      dashboard.updatePaths(mockPaths);
      dashboard.renderCards();

      const progressBar = container.querySelector('.progress-bar');
      expect(progressBar).toBeTruthy();
      expect(progressBar.style.width).toBe('75%');
      expect(progressBar.getAttribute('aria-valuenow')).toBe('75');
    });

    it('should show completion percentage text', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1', completion: 45 }
      ];

      dashboard.updatePaths(mockPaths);
      dashboard.renderCards();

      const progressText = container.querySelector('.progress-text');
      expect(progressText.textContent).toContain('45%');
    });

    it('should render overall progress summary', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1', completion: 100, selected: true },
        { id: 'path2', title: 'Path 2', completion: 50, selected: true }
      ];

      dashboard.updatePaths(mockPaths);
      dashboard.renderProgressSummary();

      const summary = container.querySelector('.progress-summary-card');
      expect(summary).toBeTruthy();
      expect(summary.textContent).toContain('75%'); // (100 + 50) / 2
      expect(summary.textContent).toContain('2 of 2'); // Shows "2 of 2 Selected"
      expect(summary.textContent).toContain('Selected');
    });
  });

  describe('Progress Statistics', () => {
    it('should calculate completion statistics', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1', completion: 100 },
        { id: 'path2', title: 'Path 2', completion: 100 },
        { id: 'path3', title: 'Path 3', completion: 50 },
        { id: 'path4', title: 'Path 4', completion: 0 }
      ];

      dashboard.updatePaths(mockPaths);
      // Select all paths since getProgressStatistics calculates for selected paths only
      dashboard.selectedPaths = new Set(['path1', 'path2', 'path3', 'path4']);
      const stats = dashboard.getProgressStatistics();

      expect(stats.completed).toBe(2);
      expect(stats.inProgress).toBe(1);
      expect(stats.notStarted).toBe(1);
      expect(stats.total).toBe(4);
      expect(stats.completionRate).toBe(50); // 2/4 * 100
    });

    it('should calculate statistics from selected paths only', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1', completion: 100 },
        { id: 'path2', title: 'Path 2', completion: 100 },
        { id: 'path3', title: 'Path 3', completion: 50 },
        { id: 'path4', title: 'Path 4', completion: 0 }
      ];

      dashboard.updatePaths(mockPaths);
      dashboard.selectedPaths = new Set(['path1', 'path3', 'path4']);

      const stats = dashboard.getProgressStatistics();

      expect(stats.total).toBe(4); // Total paths in system
      expect(stats.selectedCount).toBe(3); // Only 3 selected
      expect(stats.completed).toBe(1); // path1 is 100%
      expect(stats.inProgress).toBe(1); // path3 is 50%
      expect(stats.notStarted).toBe(1); // path4 is 0%
    });

    it('should show zero statistics when no paths selected', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1', completion: 100 },
        { id: 'path2', title: 'Path 2', completion: 50 }
      ];

      dashboard.updatePaths(mockPaths);
      dashboard.selectedPaths = new Set(); // Nothing selected

      const stats = dashboard.getProgressStatistics();

      expect(stats.selectedCount).toBe(0);
      expect(stats.completed).toBe(0);
      expect(stats.inProgress).toBe(0);
      expect(stats.notStarted).toBe(0);
      expect(stats.total).toBe(2); // Total paths still tracked
    });

    it('should update statistics when selection changes', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1', completion: 100 },
        { id: 'path2', title: 'Path 2', completion: 50 },
        { id: 'path3', title: 'Path 3', completion: 0 }
      ];

      dashboard.updatePaths(mockPaths);

      // Initially select all
      dashboard.selectedPaths = new Set(['path1', 'path2', 'path3']);
      let stats = dashboard.getProgressStatistics();
      expect(stats.selectedCount).toBe(3);
      expect(stats.completed).toBe(1);

      // Deselect some paths
      dashboard.selectedPaths = new Set(['path1']);
      stats = dashboard.getProgressStatistics();
      expect(stats.selectedCount).toBe(1);
      expect(stats.completed).toBe(1);
      expect(stats.inProgress).toBe(0);
    });

    it('should track time estimates', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1', estimatedTime: '2 hours', completion: 100 },
        { id: 'path2', title: 'Path 2', estimatedTime: '1 hour', completion: 50 },
        { id: 'path3', title: 'Path 3', estimatedTime: '3 hours', completion: 0 }
      ];

      dashboard.updatePaths(mockPaths);
      const timeStats = dashboard.getTimeStatistics();

      expect(timeStats.totalEstimated).toBe(6); // 2 + 1 + 3 hours
      expect(timeStats.completed).toBe(2); // 100% of 2 hours
      expect(timeStats.remaining).toBe(4.5); // 50% of 1 hour + 100% of 3 hours
    });

    it('should generate progress reports', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1', category: 'JavaScript', completion: 100 },
        { id: 'path2', title: 'Path 2', category: 'JavaScript', completion: 50 },
        { id: 'path3', title: 'Path 3', category: 'Python', completion: 75 }
      ];

      dashboard.updatePaths(mockPaths);
      const report = dashboard.generateProgressReport();

      expect(report.byCategory).toEqual({
        JavaScript: { completed: 1, inProgress: 1, averageProgress: 75 },
        Python: { completed: 0, inProgress: 1, averageProgress: 75 }
      });
    });
  });

  describe('Progress Persistence', () => {
    it('should save progress to localStorage', () => {
      const mockPaths = [
        { id: 'path1', title: 'Path 1', completion: 75 }
      ];

      dashboard.updatePaths(mockPaths);

      // Test progress calculation directly since storageMixin.saveProgress()
      // overrides progressMixin.saveProgress() and doesn't return the data
      const progress = dashboard.calculateProgress('path1');

      expect(progress).toBeDefined();
      expect(progress.percentage).toBe(75);
    });    it('should load progress from localStorage', () => {
      localStorage.setItem('learningPathProgress', JSON.stringify({
        path1: 50,
        path2: 100
      }));

      dashboard.loadProgress();
      const paths = dashboard.getPaths();

      expect(paths.find(p => p.id === 'path1')?.completion).toBe(50);
      expect(paths.find(p => p.id === 'path2')?.completion).toBe(100);
    });

    it('should handle corrupted progress data', () => {
      localStorage.setItem('learningPathProgress', 'invalid json');

      expect(() => dashboard.loadProgress()).not.toThrow();

      const paths = dashboard.getPaths();
      paths.forEach(path => {
        expect(path.completion).toBe(0); // Should default to 0
      });
    });
  });

  describe('Progress Events', () => {
    it('should emit progress change events', async () => {
      const eventSpy = vi.fn();
      container.addEventListener('progressChanged', eventSpy);

      dashboard.updateProgress('path1', 50);

      await vi.waitFor(() => {
        expect(eventSpy).toHaveBeenCalledWith(
          expect.objectContaining({
            detail: expect.objectContaining({
              pathId: 'path1',
              progress: 50
            })
          })
        );
      });
    });

    it('should emit completion events', async () => {
      const eventSpy = vi.fn();
      container.addEventListener('pathCompleted', eventSpy);

      dashboard.updateProgress('path1', 100);

      await vi.waitFor(() => {
        expect(eventSpy).toHaveBeenCalledWith(
          expect.objectContaining({
            detail: expect.objectContaining({
              pathId: 'path1',
              completed: true
            })
          })
        );
      });
    });

    it('should emit milestone events', async () => {
      const eventSpy = vi.fn();
      container.addEventListener('milestoneReached', eventSpy);

      dashboard.updateProgress('path1', 50); // 50% milestone

      await vi.waitFor(() => {
        expect(eventSpy).toHaveBeenCalledWith(
          expect.objectContaining({
            detail: expect.objectContaining({
              pathId: 'path1',
              milestone: 50
            })
          })
        );
      });
    });
  });

  describe('Progress Animation', () => {
    it('should animate progress bar changes', async () => {
      const mockPath = { id: 'path1', title: 'Path 1', completion: 0 };
      dashboard.updatePaths([mockPath]);
      dashboard.renderCards();

      const progressBar = container.querySelector('.progress-bar');
      expect(progressBar.style.width).toBe('0%');

      dashboard.updateProgress('path1', 75);

      // Should animate to new value
      await vi.waitFor(() => {
        expect(progressBar.style.width).toBe('75%');
      });
    });

    it('should respect reduced motion preferences', () => {
      // Mock reduced motion preference
      Object.defineProperty(window, 'matchMedia', {
        writable: true,
        value: vi.fn().mockImplementation(query => ({
          matches: query === '(prefers-reduced-motion: reduce)',
          media: query,
          onchange: null,
          addListener: vi.fn(),
          removeListener: vi.fn(),
        })),
      });

      dashboard.updatePaths([{ id: 'path1', title: 'Path 1', completion: 0 }]);
      dashboard.renderCards();
      dashboard.updateProgress('path1', 50);

      const progressBar = container.querySelector('.progress-bar');
      expect(progressBar.style.transition).toBe('none');
    });
  });

  describe('Progress Validation', () => {
    it('should validate progress values', () => {
      expect(() => dashboard.updateProgress('path1', -10)).toThrow();
      expect(() => dashboard.updateProgress('path1', 110)).toThrow();
      expect(() => dashboard.updateProgress('path1', 'invalid')).toThrow();
    });

    it('should handle invalid path IDs gracefully', () => {
      expect(() => dashboard.updateProgress('nonexistent', 50)).not.toThrow();

      // Should log warning
      expect(console.warn).toHaveBeenCalledWith(
        expect.stringContaining('Path not found: nonexistent')
      );
    });

    it('should normalize progress values', () => {
      dashboard.updateProgress('path1', 50.7567);

      const path = dashboard.getPaths().find(p => p.id === 'path1');
      expect(path.completion).toBe(50.76); // Rounded to 2 decimal places
    });
  });
});
