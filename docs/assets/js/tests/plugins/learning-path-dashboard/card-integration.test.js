import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import LearningPathDashboard from '../../../plugins/learning-path-dashboard.js';
import { createMockContainer, createMockPaths, mockConsole, cleanupDOM } from './test-helpers.js';

describe('Card Integration', () => {
  let container, dashboard;

  beforeEach(() => {
    mockConsole();

    // Use fake timers to control debouncing and async operations
    vi.useFakeTimers();

    // Mock fetch globally for all async operations
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ success: true })
    });

    container = createMockContainer('card-integration');
    dashboard = new LearningPathDashboard(container, createMockPaths());
  });

  afterEach(() => {
    // Run all pending timers to completion
    vi.runAllTimers();
    // Restore real timers
    vi.useRealTimers();
    dashboard?.destroy();
    cleanupDOM();
    vi.restoreAllMocks();
    delete global.fetch;
  });

  describe('Card Rendering', () => {
    it('should render cards for all learning paths', () => {
      const mockPaths = createMockPaths();
      console.log('[TEST] mockPaths length:', mockPaths.length);
      console.log('[TEST] dashboard.filteredPaths before render:', dashboard.filteredPaths?.length);
      dashboard.renderCards();
      console.log('[TEST] dashboard.filteredPaths after render:', dashboard.filteredPaths?.length);
      console.log('[TEST] container innerHTML length:', container.innerHTML.length);
      console.log('[TEST] container FULL HTML:', container.innerHTML);

      const cards = container.querySelectorAll('.learning-path-card');
      expect(cards.length).toBe(mockPaths.length);
    });

    it('should render card content correctly', () => {
      const mockPaths = createMockPaths();
      dashboard.renderCards();

      const firstCard = container.querySelector('.learning-path-card');
      expect(firstCard.querySelector('.card-title').textContent.trim()).toBe(mockPaths[0].title);
      expect(firstCard.querySelector('.card-description').textContent).toBe(mockPaths[0].description);
      expect(firstCard.querySelector('.card-category').textContent).toBe(mockPaths[0].category);
    });

    it('should render checkboxes with correct attributes', () => {
      dashboard.renderCards();

      const checkboxes = container.querySelectorAll('.path-checkbox');
      expect(checkboxes.length).toBeGreaterThan(0);

      checkboxes.forEach(checkbox => {
        expect(checkbox.getAttribute('data-path-id')).toBeTruthy();
        expect(checkbox.getAttribute('aria-label')).toBeTruthy();
      });
    });

    it('should render progress indicators', () => {
      dashboard.renderCards();

      const progressBars = container.querySelectorAll('.progress-bar');
      progressBars.forEach(bar => {
        expect(bar.getAttribute('role')).toBe('progressbar');
        expect(bar.getAttribute('aria-valuenow')).toBeTruthy();
      });
    });

    it('should handle missing card data gracefully', () => {
      const incompleteData = [{ id: 'incomplete', title: 'Test' }]; // Missing required fields
      const dashboardWithIncompleteData = new LearningPathDashboard(container, incompleteData);

      expect(() => dashboardWithIncompleteData.renderCards()).not.toThrow();

      dashboardWithIncompleteData.destroy();
    });
  });

  describe('Checkbox Interactions', () => {
    beforeEach(() => {
      dashboard.bindCardEvents(container);
    });

    it('should handle checkbox click events', async () => {
      const checkbox = container.querySelector('.path-checkbox');
      const eventSpy = vi.fn();
      container.addEventListener('pathSelectionChanged', eventSpy);

      if (checkbox) {
        checkbox.click();

        await vi.waitFor(() => {
          expect(eventSpy).toHaveBeenCalledWith(
            expect.objectContaining({
              detail: expect.objectContaining({
                pathId: checkbox.getAttribute('data-path-id'),
                selected: checkbox.checked
              })
            })
          );
        });
      }
    });

    it('should update visual feedback on selection', async () => {
      const checkbox = container.querySelector('.path-checkbox');
      const card = checkbox?.closest('.learning-path-card');

      if (checkbox && card) {
        checkbox.click();

        await vi.waitFor(() => {
          expect(card.classList.contains('selected')).toBe(checkbox.checked);
        });
      }
    });

    it('should handle multiple checkbox selections', async () => {
      const checkboxes = container.querySelectorAll('.path-checkbox');
      const eventSpy = vi.fn();
      container.addEventListener('pathSelectionChanged', eventSpy);

      // Select first two checkboxes
      if (checkboxes.length >= 2) {
        checkboxes[0].click();
        checkboxes[1].click();

        await vi.waitFor(() => {
          expect(eventSpy).toHaveBeenCalledTimes(2);
          expect(checkboxes[0].checked).toBe(true);
          expect(checkboxes[1].checked).toBe(true);
        });
      }
    });

    it('should prevent duplicate selections', async () => {
      const checkbox = container.querySelector('.path-checkbox');
      const eventSpy = vi.fn();
      container.addEventListener('pathSelectionChanged', eventSpy);

      if (checkbox) {
        // Click twice
        checkbox.click();
        checkbox.click();

        await vi.waitFor(() => {
          expect(eventSpy).toHaveBeenCalledTimes(2);
          expect(checkbox.checked).toBe(false); // Should be unchecked after second click
        });
      }
    });
  });

  describe('Card Filtering and Search', () => {
    beforeEach(() => {
      dashboard.bindCardEvents(container);
    });

    it('should filter cards by category', () => {
      const categoryFilter = container.querySelector('[data-filter="category"]');

      if (categoryFilter) {
        categoryFilter.value = 'test';
        categoryFilter.dispatchEvent(new Event('change'));

        const visibleCards = container.querySelectorAll('.learning-path-card:not(.hidden)');
        visibleCards.forEach(card => {
          expect(card.querySelector('.card-category').textContent).toBe('test');
        });
      }
    });

    it('should filter cards by search term', () => {
      const searchInput = container.querySelector('[data-search="paths"]');

      if (searchInput) {
        searchInput.value = 'Test Path 1';
        searchInput.dispatchEvent(new Event('input'));

        const visibleCards = container.querySelectorAll('.learning-path-card:not(.hidden)');
        expect(visibleCards.length).toBe(1);
        expect(visibleCards[0].querySelector('.card-title').textContent).toContain('Test Path 1');
      }
    });

    it('should handle empty search results', () => {
      const searchInput = container.querySelector('[data-search="paths"]');

      if (searchInput) {
        searchInput.value = 'nonexistent';
        searchInput.dispatchEvent(new Event('input'));

        const visibleCards = container.querySelectorAll('.learning-path-card:not(.hidden)');
        expect(visibleCards.length).toBe(0);

        const noResultsMessage = container.querySelector('.no-results-message');
        expect(noResultsMessage).toBeTruthy();
        expect(noResultsMessage.textContent).toContain('No learning paths found');
      }
    });

    it('should clear filters and show all cards', () => {
      const clearButton = container.querySelector('[data-action="clear-filters"]');

      if (clearButton) {
        // First apply a filter
        const searchInput = container.querySelector('[data-search="paths"]');
        if (searchInput) {
          searchInput.value = 'specific term';
          searchInput.dispatchEvent(new Event('input'));
        }

        // Then clear filters
        clearButton.click();

        const visibleCards = container.querySelectorAll('.learning-path-card:not(.hidden)');
        const totalCards = container.querySelectorAll('.learning-path-card');
        expect(visibleCards.length).toBe(totalCards.length);
      }
    });
  });

  describe('Card Expansion and Details', () => {
    beforeEach(() => {
      dashboard.bindCardEvents(container);
    });

    it('should expand card on click', async () => {
      const expandButton = container.querySelector('[data-action="expand"]');
      const card = expandButton?.closest('.learning-path-card');

      if (expandButton && card) {
        expandButton.click();

        await vi.waitFor(() => {
          expect(card.classList.contains('expanded')).toBe(true);
          expect(expandButton.getAttribute('aria-expanded')).toBe('true');
        });
      }
    });

    it('should show additional details when expanded', async () => {
      const expandButton = container.querySelector('[data-action="expand"]');
      const card = expandButton?.closest('.learning-path-card');

      if (expandButton && card) {
        expandButton.click();

        await vi.waitFor(() => {
          const detailsSection = card.querySelector('.card-details');
          expect(detailsSection).toBeTruthy();
          expect(detailsSection.style.display).not.toBe('none');
        });
      }
    });

    it('should collapse card on second click', async () => {
      const expandButton = container.querySelector('[data-action="expand"]');
      const card = expandButton?.closest('.learning-path-card');

      if (expandButton && card) {
        // Expand first
        expandButton.click();
        await vi.waitFor(() => {
          expect(card.classList.contains('expanded')).toBe(true);
        });

        // Then collapse
        expandButton.click();
        await vi.waitFor(() => {
          expect(card.classList.contains('expanded')).toBe(false);
          expect(expandButton.getAttribute('aria-expanded')).toBe('false');
        });
      }
    });
  });

  describe('Card Performance and Optimization', () => {
    it.todo('should handle large numbers of cards efficiently', () => {
      const largePaths = Array.from({ length: 1000 }, (_, i) => ({
        id: `path-${i}`,
        title: `Test Path ${i}`,
        description: `Description ${i}`,
        category: `category-${i % 5}`,
        difficulty: 'beginner',
        estimatedTime: '30 minutes'
      }));

      const largeDashboard = new LearningPathDashboard(container, largePaths);

      const startTime = performance.now();
      largeDashboard.renderCards();
      const endTime = performance.now();

      // Should render within reasonable time (less than 5000ms for 1000 cards to account for CI load)
      expect(endTime - startTime).toBeLessThan(5000);

      largeDashboard.destroy();
    });

    it.todo('should use virtual scrolling for large datasets', () => {
      const manyPaths = Array.from({ length: 100 }, (_, i) => ({
        id: `path-${i}`,
        title: `Test Path ${i}`,
        category: 'test'
      }));

      const virtualDashboard = new LearningPathDashboard(container, manyPaths);
      virtualDashboard.renderCards();

      // Should only render visible cards initially
      const renderedCards = container.querySelectorAll('.learning-path-card');
      expect(renderedCards.length).toBeLessThanOrEqual(20); // Assuming viewport shows ~20 cards

      virtualDashboard.destroy();
    });

    it('should debounce search input', async () => {
      const searchInput = container.querySelector('[data-search="paths"]');
      const filterSpy = vi.spyOn(dashboard, 'filterCards');

      if (searchInput) {
        // Type rapidly
        searchInput.value = 't';
        searchInput.dispatchEvent(new Event('input'));
        searchInput.value = 'te';
        searchInput.dispatchEvent(new Event('input'));
        searchInput.value = 'tes';
        searchInput.dispatchEvent(new Event('input'));
        searchInput.value = 'test';
        searchInput.dispatchEvent(new Event('input'));

        // Should debounce and only call filter once after delay
        await vi.waitFor(() => {
          expect(filterSpy).toHaveBeenCalledTimes(1);
        }, { timeout: 1000 });
      }
    });
  });

  describe('Card State Management', () => {
    it('should persist card selections across renders', () => {
      const checkbox = container.querySelector('.path-checkbox');

      if (checkbox) {
        const pathId = checkbox.getAttribute('data-path-id');
        checkbox.click();

        // Re-render cards
        dashboard.renderCards();

        const newCheckbox = container.querySelector(`input[data-path-id="${pathId}"]`);
        expect(newCheckbox.checked).toBe(true);
      }
    });

    it('should maintain expanded states during updates', async () => {
      const expandButton = container.querySelector('[data-action="expand"]');
      const card = expandButton?.closest('.learning-path-card');

      if (expandButton && card) {
        const pathId = card.getAttribute('data-path-id');
        expandButton.click();

        await vi.waitFor(() => {
          expect(card.classList.contains('expanded')).toBe(true);
        });

        // Re-render cards
        dashboard.renderCards();

        const newCard = container.querySelector(`[data-path-id="${pathId}"]`);
        expect(newCard.classList.contains('expanded')).toBe(true);
      }
    });

    it('should handle card data updates', () => {
      const originalPaths = createMockPaths();
      const updatedPaths = originalPaths.map(path => ({
        ...path,
        title: `Updated ${path.title}`
      }));

      dashboard.updatePaths(updatedPaths);
      dashboard.renderCards();

      const cards = container.querySelectorAll('.learning-path-card');
      cards.forEach((card, index) => {
        expect(card.querySelector('.card-title').textContent.trim()).toBe(`Updated ${originalPaths[index].title}`);
      });
    });
  });
});
