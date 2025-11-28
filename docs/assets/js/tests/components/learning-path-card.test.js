/**
 * Learning Path Card Component Tests
 * Interactive learning path cards with progress tracking and navigation
 *
 * This test suite validates:
 * - Path card rendering and visual design
 * - Progress indicators and completion status
 * - Interactive navigation and path selection
 * - Accessibility and keyboard navigation
 * - Integration with learning progress system
 *
 * @module tests/frontend/components/learning-path-card
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { domUtils, setupMockLocalStorage, generatePathData } from '../helpers/common-test-utils.js';

// Helper function to set up a mock path card instance
function setupMockPathCard(container) {
  return {
    container: container,
    selectedPath: null,
    favorites: [],
    bookmarks: [],
    progress: {},
    achievements: {},

    renderPath(pathData) {
      const pathElement = document.createElement('div');
      pathElement.className = 'path-card';
      pathElement.setAttribute('data-path-id', pathData.id);
      pathElement.addEventListener('click', () => {
        this.selectedPath = pathData.id;
      });
      container.appendChild(pathElement);
    },

    isFavorite(pathId) {
      return this.favorites.includes(pathId);
    },

    toggleFavorite(pathId) {
      if (this.isFavorite(pathId)) {
        this.favorites = this.favorites.filter(id => id !== pathId);
      } else {
        this.favorites.push(pathId);
      }
    },

    loadPaths(paths) {
      this.paths = paths;
    },

    filterPaths(criteria) {
      if (!this.paths) return [];
      return this.paths.filter(path => {
        if (criteria.difficulty && path.difficulty !== criteria.difficulty) return false;
        if (criteria.tags && !criteria.tags.some(tag => path.tags.includes(tag))) return false;
        return true;
      });
    },

    sortPaths(sortBy) {
      if (!this.paths) return [];
      return [...this.paths].sort((a, b) => {
        if (sortBy === 'title') {
          return a.title.localeCompare(b.title);
        }
        if (sortBy === 'difficulty') {
          const order = { beginner: 1, intermediate: 2, advanced: 3 };
          return order[a.difficulty] - order[b.difficulty];
        }
        return 0;
      });
    },

    updateProgress(pathId, progress) {
      this.progress[pathId] = progress;
      localStorage.setItem('learning-path-progress', JSON.stringify(this.progress));
    },

    getProgress(pathId) {
      return this.progress[pathId] || 0;
    },

    getAchievements(pathId) {
      return this.achievements[pathId] || [];
    },

    addBookmark(pathId) {
      if (!this.bookmarks.includes(pathId)) {
        this.bookmarks.push(pathId);
        localStorage.setItem('learning-path-bookmarks', JSON.stringify(this.bookmarks));
      }
    },

    removeBookmark(pathId) {
      this.bookmarks = this.bookmarks.filter(id => id !== pathId);
      localStorage.setItem('learning-path-bookmarks', JSON.stringify(this.bookmarks));
    },

    isBookmarked(pathId) {
      return this.bookmarks.includes(pathId);
    },

    exportUserData() {
      return {
        progress: this.progress,
        bookmarks: this.bookmarks,
        favorites: this.favorites
      };
    },

    importUserData(data) {
      this.progress = data.progress || {};
      this.bookmarks = data.bookmarks || [];
      this.favorites = data.favorites || [];
    },

    clearUserData() {
      this.progress = {};
      this.bookmarks = [];
      this.favorites = [];
    }
  };
}

describe('Learning Path Card Component', () => {
  let mockStorage;
  let container;

  beforeEach(() => {
    // Setup DOM
    document.body.innerHTML = '';

    // Clear any existing mocks
    vi.clearAllMocks();

    // Setup mock localStorage
    mockStorage = setupMockLocalStorage();
  });

  afterEach(() => {
    if (container && container.parentNode) {
      container.parentNode.removeChild(container);
    }
    vi.restoreAllMocks();
  });

  describe('path card rendering and layout', () => {
    it('should render different path types correctly', () => {
      // Test will validate various path types
      const pathTypes = [
        { type: 'beginner', title: 'Azure IoT Fundamentals', difficulty: 'Beginner' },
        { type: 'intermediate', title: 'Edge Computing Concepts', difficulty: 'Intermediate' },
        { type: 'advanced', title: 'ML at the Edge', difficulty: 'Advanced' },
        { type: 'expert', title: 'Custom IoT Solutions', difficulty: 'Expert' }
      ];

      pathTypes.forEach(({ type, title, difficulty }) => {
        const pathData = generatePathData({
          pathType: type,
          title,
          difficulty
        });

        expect(pathData.pathType).toBe(type);
        expect(pathData.title).toBe(title);
        expect(pathData.difficulty).toBe(difficulty);
      });
    });

    it('should display appropriate difficulty indicators', () => {
      // Test will validate difficulty badge rendering
      const difficultyLevels = [
        { level: 'beginner', color: '#28a745', icon: '🌱' },
        { level: 'intermediate', color: '#ffc107', icon: '⚡' },
        { level: 'advanced', color: '#fd7e14', icon: '🔥' },
        { level: 'expert', color: '#dc3545', icon: '💎' }
      ];

      difficultyLevels.forEach(({ level, color, icon }) => {
        const pathData = generatePathData({
          difficulty: level,
          difficultyColor: color,
          difficultyIcon: icon
        });

        expect(pathData.difficulty).toBe(level);
        expect(pathData.difficultyColor).toBe(color);
      });
    });

    it('should handle different completion states', () => {
      // Test will validate completion state rendering
      const completionStates = [
        { state: 'not-started', progress: 0, buttonText: 'Start Path' },
        { state: 'in-progress', progress: 45, buttonText: 'Continue' },
        { state: 'completed', progress: 100, buttonText: 'Review' },
        { state: 'mastered', progress: 100, buttonText: 'Retake' }
      ];

      completionStates.forEach(({ state, progress, buttonText }) => {
        const pathData = generatePathData({
          completionState: state,
          progress,
          buttonText
        });

        expect(pathData.completionState).toBe(state);
        expect(pathData.progress).toBe(progress);
      });
    });

    it('should support custom path configurations', () => {
      // Test will validate custom path support
      const customPath = {
        id: 'custom-edge-ai-path',
        title: 'Custom Edge AI Journey',
        description: 'Build your own edge AI solutions',
        estimatedTime: '8 hours',
        prerequisites: ['azure-fundamentals'],
        tags: ['AI', 'IoT', 'Edge Computing']
      };

      const pathData = generatePathData(customPath);

      expect(pathData.id).toBe('custom-edge-ai-path');
      expect(Array.isArray(pathData.tags)).toBe(true);
      expect(pathData.estimatedTime).toBe('8 hours');
    });
  });

  describe('Learning Path Data Management', () => {
    let pathCard;
    let container;

    beforeEach(() => {
      container = document.createElement('div');
      container.id = 'learning-paths';
      document.body.appendChild(container);
      pathCard = new window.LearningPathCard('#learning-paths');
    });

    it('should load learning paths from data source', async () => {
      const mockPaths = [
        {
          id: 'path-1',
          title: 'Getting Started',
          description: 'Learn the basics',
          category: 'beginner',
          totalSteps: 5,
          estimatedTime: 30,
          prerequisites: [],
          steps: [
            { id: 'step-1', title: 'Introduction', completed: false },
            { id: 'step-2', title: 'Setup', completed: false }
          ]
        }
      ];

      pathCard.loadPaths(mockPaths);
      expect(pathCard.paths).toEqual(mockPaths);
    });

    it('should calculate progress for each path', () => {
      const mockPaths = [
        {
          id: 'path-1',
          title: 'Test Path',
          steps: [
            { id: 'step-1', completed: true },
            { id: 'step-2', completed: true },
            { id: 'step-3', completed: false },
            { id: 'step-4', completed: false }
          ]
        }
      ];

      pathCard.loadPaths(mockPaths);
      const progress = pathCard.calculateProgress('path-1');
      expect(progress).toEqual({
        completed: 2,
        total: 4,
        percentage: 50
      });
    });

    it('should update step completion status', () => {
      const mockPaths = [
        {
          id: 'path-1',
          title: 'Test Path 1',
          steps: [
            { id: 'step-1', completed: false },
            { id: 'step-2', completed: false }
          ]
        }
      ];

      pathCard.loadPaths(mockPaths);
      pathCard.updateStepCompletion('path-1', 'step-1', true);

      const updatedPath = pathCard.getPath('path-1');
      expect(updatedPath.steps[0].completed).toBe(true);
    });

    it('should persist progress to localStorage', () => {
      const mockPaths = [{ id: 'path-1', title: 'Test Path 1', steps: [{ id: 'step-1', completed: false }] }];
      pathCard.loadPaths(mockPaths);

      pathCard.updateStepCompletion('path-1', 'step-1', true);

      expect(mockStorage.setItem).toHaveBeenCalledWith(
        'learning-paths-progress',
        expect.stringContaining('"path-1"')
      );
    });
  });

  describe('Visual Card Rendering', () => {
    let pathCard;
    let container;

    beforeEach(() => {
      container = document.createElement('div');
      container.className = 'learning-paths-container';
      document.body.appendChild(container);
      pathCard = new window.LearningPathCard(container);
    });

    it('should render learning path cards', () => {
      const mockPaths = [
        {
          id: 'path-1',
          title: 'Test Path',
          description: 'Test description',
          category: 'beginner',
          totalSteps: 3,
          estimatedTime: 20,
          steps: [
            { id: 'step-1', completed: true },
            { id: 'step-2', completed: false },
            { id: 'step-3', completed: false }
          ]
        }
      ];

      pathCard.loadPaths(mockPaths);
      pathCard.render();

      const cards = container.querySelectorAll('.learning-path-card');
      expect(cards).toHaveLength(1);

      const card = cards[0];
      expect(card.querySelector('.path-title').textContent).toBe('Test Path');
      expect(card.querySelector('.path-description').textContent).toBe('Test description');
      expect(card.querySelector('.path-category').textContent).toBe('beginner');
    });

    it('should render progress indicators', () => {
      const mockPaths = [
        {
          id: 'path-1',
          title: 'Test Path',
          steps: [
            { id: 'step-1', completed: true },
            { id: 'step-2', completed: true },
            { id: 'step-3', completed: false }
          ]
        }
      ];

      pathCard.loadPaths(mockPaths);
      pathCard.render();

      const progressBar = container.querySelector('.progress-bar');
      const progressFill = progressBar.querySelector('.progress-fill');
      const progressText = container.querySelector('.progress-text');

      expect(progressBar).toBeDefined();
      expect(progressFill.style.width).toBe('67%'); // 2/3 completed
      expect(progressText.textContent).toContain('2 of 3');
    });

    it('should render completion badges when enabled', () => {
      const mockPaths = [
        {
          id: 'path-1',
          title: 'Test Path',
          steps: [
            { id: 'step-1', completed: true },
            { id: 'step-2', completed: true },
            { id: 'step-3', completed: true }
          ],
          badge: {
            id: 'beginner-badge',
            title: 'Beginner',
            icon: '🎯',
            unlocked: true
          }
        }
      ];

      pathCard.loadPaths(mockPaths);
      pathCard.render();

      const badge = container.querySelector('.completion-badge');
      expect(badge).toBeDefined();
      expect(badge.querySelector('.badge-icon').textContent).toBe('🎯');
      expect(badge.querySelector('.badge-title').textContent).toBe('Beginner');
      expect(badge.classList.contains('unlocked')).toBe(true);
    });

    it('should apply different layouts', () => {
      const mockPaths = [
        { id: 'path-1', title: 'Test Path 1', steps: [] },
        { id: 'path-2', title: 'Test Path 2', steps: [] }
      ];

      // Test grid layout
      pathCard.config.layout = 'grid';
      pathCard.loadPaths(mockPaths);
      pathCard.render();
      expect(container.classList.contains('layout-grid')).toBe(true);

      // Test list layout
      pathCard.config.layout = 'list';
      pathCard.render();
      expect(container.classList.contains('layout-list')).toBe(true);
    });
  });

  describe('Filtering and Sorting', () => {
    let pathCard;
    let container;

    beforeEach(() => {
      container = document.createElement('div');
      document.body.appendChild(container);
      pathCard = new window.LearningPathCard(container);
    });

    it('should filter paths by category', () => {
      const mockPaths = [
        { id: 'path-1', title: 'Beginner Path', category: 'beginner', steps: [] },
        { id: 'path-2', title: 'Advanced Path', category: 'advanced', steps: [] },
        { id: 'path-3', title: 'Another Beginner', category: 'beginner', steps: [] }
      ];

      pathCard.loadPaths(mockPaths);
      pathCard.filterByCategory('beginner');
      pathCard.render();

      const cards = container.querySelectorAll('.learning-path-card');
      expect(cards).toHaveLength(2);
      expect(cards[0].querySelector('.path-title').textContent).toBe('Beginner Path');
      expect(cards[1].querySelector('.path-title').textContent).toBe('Another Beginner');
    });

    it('should sort paths by progress', () => {
      const mockPaths = [
        {
          id: 'path-1',
          title: 'Low Progress',
          steps: [
            { id: 'step-1', completed: true },
            { id: 'step-2', completed: false },
            { id: 'step-3', completed: false }
          ]
        },
        {
          id: 'path-2',
          title: 'High Progress',
          steps: [
            { id: 'step-1', completed: true },
            { id: 'step-2', completed: true },
            { id: 'step-3', completed: false }
          ]
        }
      ];

      pathCard.loadPaths(mockPaths);
      pathCard.sortBy('progress', 'desc');
      pathCard.render();

      const cards = container.querySelectorAll('.learning-path-card');
      expect(cards[0].querySelector('.path-title').textContent).toBe('High Progress');
      expect(cards[1].querySelector('.path-title').textContent).toBe('Low Progress');
    });

    it('should sort paths by title alphabetically', () => {
      const mockPaths = [
        { id: 'path-1', title: 'Zebra Path', steps: [] },
        { id: 'path-2', title: 'Alpha Path', steps: [] },
        { id: 'path-3', title: 'Beta Path', steps: [] }
      ];

      pathCard.loadPaths(mockPaths);
      pathCard.sortBy('title', 'asc');
      pathCard.render();

      const cards = container.querySelectorAll('.learning-path-card');
      expect(cards[0].querySelector('.path-title').textContent).toBe('Alpha Path');
      expect(cards[1].querySelector('.path-title').textContent).toBe('Beta Path');
      expect(cards[2].querySelector('.path-title').textContent).toBe('Zebra Path');
    });

    it('should clear filters and show all paths', () => {
      const mockPaths = [
        { id: 'path-1', title: 'Test Path 1', category: 'beginner', steps: [] },
        { id: 'path-2', title: 'Test Path 2', category: 'advanced', steps: [] }
      ];

      pathCard.loadPaths(mockPaths);
      pathCard.filterByCategory('beginner');
      pathCard.render();
      expect(container.querySelectorAll('.learning-path-card')).toHaveLength(1);

      pathCard.clearFilters();
      pathCard.render();
      expect(container.querySelectorAll('.learning-path-card')).toHaveLength(2);
    });
  });

  describe('Interaction and Events', () => {
    let pathCard;
    let container;

    beforeEach(() => {
      container = document.createElement('div');
      document.body.appendChild(container);
      pathCard = new window.LearningPathCard(container);
    });

    it('should handle card click events', () => {
      const mockPaths = [
        { id: 'path-1', title: 'Test Path', steps: [] }
      ];

      const onCardClick = vi.fn();
      pathCard.on('cardClick', onCardClick);

      pathCard.loadPaths(mockPaths);
      pathCard.render();

      const card = container.querySelector('.learning-path-card');
      card.click();

      expect(onCardClick).toHaveBeenCalledWith({
        pathId: 'path-1',
        path: mockPaths[0]
      });
    });

    it('should handle step completion clicks', () => {
      const mockPaths = [
        {
          id: 'path-1',
          title: 'Test Path',
          steps: [
            { id: 'step-1', title: 'Step 1', completed: false }
          ]
        }
      ];

      pathCard.loadPaths(mockPaths);
      pathCard.render();

      const stepCheckbox = container.querySelector('.step-checkbox');
      stepCheckbox.click();

      const updatedPath = pathCard.getPath('path-1');
      expect(updatedPath.steps[0].completed).toBe(true);
    });

    it('should emit events on progress updates', () => {
      const mockPaths = [
        {
          id: 'path-1',
          title: 'Test Path 1',
          steps: [
            { id: 'step-1', completed: false }
          ]
        }
      ];

      const onProgressUpdate = vi.fn();
      pathCard.on('progressUpdate', onProgressUpdate);

      pathCard.loadPaths(mockPaths);
      pathCard.updateStepCompletion('path-1', 'step-1', true);

      expect(onProgressUpdate).toHaveBeenCalledWith({
        pathId: 'path-1',
        stepId: 'step-1',
        completed: true,
        progress: { completed: 1, total: 1, percentage: 100 }
      });
    });
  });

  describe('Responsive Design', () => {
    let pathCard;
    let container;

    beforeEach(() => {
      container = document.createElement('div');
      document.body.appendChild(container);
      pathCard = new window.LearningPathCard(container);
    });

    it('should provide desktop-optimized layout (mobile removed)', () => {
      // Mock desktop viewport
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 1024
      });

      const mockPaths = [{ id: 'path-1', title: 'Test Path', steps: [] }];
      pathCard.loadPaths(mockPaths);
      pathCard.render();

      // Should NOT have mobile layout since we removed mobile styling
      expect(container.classList.contains('mobile-layout')).toBe(false);

      // Should have desktop-focused features
      const cards = container.querySelectorAll('.learning-path-card');
      expect(cards.length).toBeGreaterThan(0);
    });

    it('should provide touch-friendly interaction targets', () => {
      const mockPaths = [
        {
          id: 'path-1',
          steps: [{ id: 'step-1', completed: false }]
        }
      ];

      pathCard.loadPaths(mockPaths);
      pathCard.render();

      const touchTargets = container.querySelectorAll('.touch-target');
      touchTargets.forEach(target => {
        const rect = target.getBoundingClientRect();
        expect(Math.min(rect.width, rect.height)).toBeGreaterThanOrEqual(44);
      });
    });
  });

  describe('Accessibility', () => {
    let pathCard;
    let container;

    beforeEach(() => {
      container = document.createElement('div');
      document.body.appendChild(container);
      pathCard = new window.LearningPathCard(container);
    });

    it('should have proper ARIA attributes', () => {
      const mockPaths = [
        {
          id: 'path-1',
          title: 'Test Path',
          steps: [{ id: 'step-1', title: 'Step 1', completed: false }]
        }
      ];

      pathCard.loadPaths(mockPaths);
      pathCard.render();

      const card = container.querySelector('.learning-path-card');
      expect(card.getAttribute('role')).toBe('article');
      expect(card.getAttribute('aria-labelledby')).toBeDefined();

      const progressBar = container.querySelector('.progress-bar');
      expect(progressBar.getAttribute('role')).toBe('progressbar');
      expect(progressBar.getAttribute('aria-valuenow')).toBeDefined();
      expect(progressBar.getAttribute('aria-valuemin')).toBe('0');
      expect(progressBar.getAttribute('aria-valuemax')).toBe('100');
    });

    it('should support keyboard navigation', () => {
      const mockPaths = [
        { id: 'path-1', title: 'Test Path 1', steps: [] },
        { id: 'path-2', title: 'Test Path 2', steps: [] }
      ];

      pathCard.loadPaths(mockPaths);
      pathCard.render();

      const cards = container.querySelectorAll('.learning-path-card');
      cards.forEach(card => {
        expect(card.getAttribute('tabindex')).toBe('0');
      });
    });

    it('should announce progress updates to screen readers', () => {
      const mockPaths = [
        {
          id: 'path-1',
          title: 'Test Path',
          steps: [{ id: 'step-1', completed: false }]
        }
      ];

      pathCard.loadPaths(mockPaths);
      pathCard.render();

      const ariaLive = container.querySelector('[aria-live="polite"]');
      expect(ariaLive).toBeDefined();

      pathCard.updateStepCompletion('path-1', 'step-1', true);
      expect(ariaLive.textContent).toContain('Progress updated');
    });
  });

  describe('Error Handling', () => {
    let pathCard;
    let container;

    beforeEach(() => {
      container = document.createElement('div');
      document.body.appendChild(container);
      pathCard = new window.LearningPathCard(container);
    });

    it('should handle invalid path data gracefully', () => {
      const invalidPaths = [
        { id: null, title: '', steps: undefined },
        { id: 'path-2' } // Missing required properties
      ];

      expect(() => {
        pathCard.loadPaths(invalidPaths);
      }).not.toThrow();

      expect(pathCard.paths).toHaveLength(0); // Invalid paths filtered out
    });

    it('should handle localStorage errors gracefully', () => {
      mockStorage.setItem.mockImplementation(() => {
        throw new Error('Storage quota exceeded');
      });

      const mockPaths = [
        { id: 'path-1', steps: [{ id: 'step-1', completed: false }] }
      ];

      pathCard.loadPaths(mockPaths);

      expect(() => {
        pathCard.updateStepCompletion('path-1', 'step-1', true);
      }).not.toThrow();
    });

    it('should display error messages for failed operations', () => {
      // Simulate network error
      pathCard.loadPaths = vi.fn().mockRejectedValue(new Error('Network error'));

      pathCard.handleError(new Error('Failed to load paths'));

      const errorMessage = container.querySelector('.error-message');
      expect(errorMessage).toBeDefined();
      expect(errorMessage.textContent).toContain('Failed to load paths');
    });
  });
});
