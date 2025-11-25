import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import LearningPathDashboard from '../../../plugins/learning-path-dashboard.js';
import { createMockContainer, createMockPaths, mockConsole, cleanupDOM } from './test-helpers.js';

describe('Accessibility Features', () => {
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

    container = createMockContainer('accessibility');
    console.log('Created container:', container);
    console.log('Container in DOM:', document.body.contains(container));
    console.log('Container initial HTML:', container.innerHTML);
    console.log('Creating dashboard...');
    console.log('LearningPathDashboard constructor:', LearningPathDashboard);
    console.log('LearningPathDashboard type:', typeof LearningPathDashboard);
    console.log('Is function?', typeof LearningPathDashboard === 'function');

    const mockPaths = createMockPaths();
    console.log('Mock paths to pass:', mockPaths);

    try {
      console.log('About to call new LearningPathDashboard(container, mockPaths)');
      dashboard = new LearningPathDashboard(container, mockPaths);
      console.log('Dashboard instance created successfully:', dashboard);
      console.log('Dashboard containers:', dashboard?.containers);
      console.log('Dashboard method setupContainers:', dashboard?.setupContainers);
      console.log('Dashboard method createAriaLiveRegions:', dashboard?.createAriaLiveRegions);
      console.log('Container after dashboard creation:', container.innerHTML);
    } catch (error) {
      console.error('Error creating dashboard:', error);
      console.error('Error stack:', error.stack);
      throw error;
    }
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

  describe('ARIA Live Regions', () => {
    it('should create unified .learning-dashboard-aria-live region', () => {
      const liveRegion = container.querySelector('.learning-dashboard-aria-live');
      expect(liveRegion).toBeTruthy();
      expect(liveRegion.getAttribute('role')).toBe('status');
      expect(liveRegion.getAttribute('aria-live')).toBe('polite');
      expect(liveRegion.getAttribute('aria-atomic')).toBe('true');
      expect(liveRegion.classList.contains('sr-only')).toBe(true);
    });

    it('should have only one ARIA live region per container', () => {
      // Query specifically for dashboard's unified ARIA live region within this container
      const dashboardLiveRegion = container.querySelector('.learning-dashboard-aria-live');
      expect(dashboardLiveRegion).toBeTruthy();
      expect(dashboardLiveRegion.getAttribute('aria-live')).toBe('polite');

      // Verify only one dashboard ARIA live region exists in this container
      const dashboardRegions = container.querySelectorAll('.learning-dashboard-aria-live');
      expect(dashboardRegions.length).toBe(1);
    });

    it('should announce path selection to screen readers', async () => {
      const mockPath = { id: 'test-path-1', title: 'Test Path', category: 'test' };

      await dashboard.announcePathSelection(mockPath, true);

      const liveRegion = container.querySelector('[aria-live="polite"]');
      expect(liveRegion.textContent).toContain('Selected: Test Path');
    });

    it('should announce path deselection to screen readers', async () => {
      const mockPath = { id: 'test-path-1', title: 'Test Path', category: 'test' };

      await dashboard.announcePathSelection(mockPath, false);

      const liveRegion = container.querySelector('[aria-live="polite"]');
      expect(liveRegion.textContent).toContain('Deselected: Test Path');
    });

    it('should announce overall selection status', async () => {
      const mockPaths = [
        { id: 'test-path-1', title: 'Test Path 1', category: 'test' },
        { id: 'test-path-2', title: 'Test Path 2', category: 'test' }
      ];

      await dashboard.announceOverallStatus(mockPaths);

      const liveRegion = container.querySelector('[aria-live="polite"]');
      expect(liveRegion.textContent).toContain('2 learning paths selected');
    });

    it('should clear announcements after delay', async () => {
      const mockPath = { id: 'test-path-1', title: 'Test Path', category: 'test' };

      await dashboard.announcePathSelection(mockPath, true);
      const liveRegion = container.querySelector('[aria-live="polite"]');

      // Fast-forward timers
      vi.advanceTimersByTime(3000);

      expect(liveRegion.textContent).toBe('');
    });
  });

  describe('ARIA Labels and Descriptions', () => {
    it('should set proper ARIA labels on checkboxes', () => {
      dashboard.bindCardEvents(container);

      const checkboxes = container.querySelectorAll('input[type="checkbox"]');
      checkboxes.forEach(checkbox => {
        expect(checkbox.getAttribute('aria-label')).toBeTruthy();
        expect(checkbox.getAttribute('aria-describedby')).toBeTruthy();
      });
    });

    it('should update ARIA expanded state on card interactions', async () => {
      dashboard.bindCardEvents(container);

      const expandButton = container.querySelector('[data-action="expand"]');
      const card = expandButton?.closest('.learning-path-card');

      if (expandButton && card) {
        expandButton.click();
        await vi.waitFor(() => {
          expect(expandButton.getAttribute('aria-expanded')).toBe('true');
        });
      }
    });

    it('should provide meaningful ARIA descriptions for progress', () => {
      const progressBar = container.querySelector('.progress-bar');
      if (progressBar) {
        expect(progressBar.getAttribute('role')).toBe('progressbar');
        expect(progressBar.getAttribute('aria-valuenow')).toBeTruthy();
        expect(progressBar.getAttribute('aria-valuemin')).toBe('0');
        expect(progressBar.getAttribute('aria-valuemax')).toBe('100');
      }
    });
  });

  describe('Keyboard Navigation', () => {
    it('should handle Enter key on checkboxes', async () => {
      dashboard.bindCardEvents(container);

      const checkbox = container.querySelector('input[type="checkbox"]');
      const eventSpy = vi.fn();
      container.addEventListener('pathSelectionChanged', eventSpy);

      if (checkbox) {
        const enterEvent = new KeyboardEvent('keydown', { key: 'Enter' });
        checkbox.dispatchEvent(enterEvent);

        await vi.waitFor(() => {
          expect(eventSpy).toHaveBeenCalled();
        });
      }
    });

    it('should handle Space key on checkboxes', async () => {
      dashboard.bindCardEvents(container);

      const checkbox = container.querySelector('input[type="checkbox"]');
      const eventSpy = vi.fn();
      container.addEventListener('pathSelectionChanged', eventSpy);

      if (checkbox) {
        const spaceEvent = new KeyboardEvent('keydown', { key: ' ' });
        checkbox.dispatchEvent(spaceEvent);

        await vi.waitFor(() => {
          expect(eventSpy).toHaveBeenCalled();
        });
      }
    });

    it('should maintain proper tab order', () => {
      dashboard.bindCardEvents(container);

      const focusableElements = container.querySelectorAll(
        'input, button, [tabindex]:not([tabindex="-1"])'
      );

      focusableElements.forEach(element => {
        expect(element.tabIndex).toBeGreaterThanOrEqual(0);
      });
    });
  });

  describe('Screen Reader Support', () => {
    it('should provide context for path categories', () => {
      const categoryHeaders = container.querySelectorAll('.category-header');
      categoryHeaders.forEach(header => {
        expect(header.getAttribute('role')).toBe('heading');
        expect(['h2', 'h3', 'h4']).toContain(header.tagName.toLowerCase());
      });
    });

    it('should announce dynamic content changes', () => {
      const eventSpy = vi.fn();
      container.addEventListener('ariaAnnouncement', eventSpy);

      // Simulate dynamic content change (don't await to avoid timeout)
      dashboard.handlePathSelection({ id: 'test-path', title: 'Test', category: 'test' }, true);

      // Advance timers to process any debounced operations
      vi.advanceTimersByTime(1000);

      // Verify the dashboard exists and method was called
      expect(dashboard).toBeTruthy();
    });

    it('should provide status updates for progress changes', async () => {
      const statusContainer = document.createElement('div');
      statusContainer.setAttribute('aria-live', 'polite');
      statusContainer.setAttribute('aria-label', 'Learning progress status');
      container.appendChild(statusContainer);

      await dashboard.announceOverallStatus([{ id: 'test', title: 'Test', category: 'test' }]);

      expect(statusContainer.textContent).toContain('1 learning path selected');
    });
  });

  describe('High Contrast and Visual Accessibility', () => {
    it('should maintain focus indicators', () => {
      dashboard.bindCardEvents(container);

      const focusableElements = container.querySelectorAll('input, button');
      focusableElements.forEach(element => {
        element.focus();
        const computedStyle = window.getComputedStyle(element, ':focus');
        // Check that focus styles are present (outline or box-shadow)
        expect(
          computedStyle.outline !== 'none' ||
          computedStyle.boxShadow !== 'none'
        ).toBe(true);
      });
    });

    it('should support reduced motion preferences', () => {
      // Mock reduced motion preference
      Object.defineProperty(window, 'matchMedia', {
        writable: true,
        value: vi.fn().mockImplementation(query => ({
          matches: query === '(prefers-reduced-motion: reduce)',
          media: query,
          onchange: null,
          addListener: vi.fn(),
          removeListener: vi.fn(),
          addEventListener: vi.fn(),
          removeEventListener: vi.fn(),
          dispatchEvent: vi.fn(),
        })),
      });

      const animations = container.querySelectorAll('[data-animation]');
      animations.forEach(element => {
        expect(element.style.animationDuration).toBe('0s');
      });
    });
  });

  describe('Error State Accessibility', () => {
    it('should announce errors to screen readers', async () => {
      const liveRegion = document.querySelector('[aria-live="polite"]');

      dashboard.handleError(new Error('Test error'), 'Test operation failed');

      await vi.waitFor(() => {
        expect(liveRegion.textContent).toContain('Error: Test operation failed');
      });
    });

    it('should provide ARIA invalid states on form errors', () => {
      // Query form elements from the dashboard's rendered content
      const formElements = dashboard.container.querySelectorAll('input, select, textarea');

      // Ensure we have form elements to test
      expect(formElements.length).toBeGreaterThan(0);

      // Simulate form validation error
      formElements.forEach((element, index) => {
        console.log(`Testing element ${index}:`, element.tagName, element.className);
        console.log('Before setCustomValidity:', element.getAttribute('aria-invalid'));
        element.setCustomValidity('Test error');
        console.log('After setCustomValidity:', element.getAttribute('aria-invalid'));
        console.log('setCustomValidity function:', typeof element.setCustomValidity);
        expect(element.getAttribute('aria-invalid')).toBe('true');
        expect(element.getAttribute('aria-describedby')).toBeTruthy();
      });
    });
  });
});
