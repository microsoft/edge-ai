import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import LearningPathDashboard from '../../../plugins/learning-path-dashboard.js';
import { createMockContainer, createMockPaths, mockConsole, cleanupDOM } from './test-helpers.js';

describe('Path Loading', () => {
  let container;
  let dashboard;

  beforeEach(() => {
    mockConsole();
    vi.useRealTimers();
    container = createMockContainer('path-loading');
    dashboard = new LearningPathDashboard(container, createMockPaths());
  });

  afterEach(() => {
    dashboard?.destroy();
    cleanupDOM();
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  describe('Dynamic Path Loading', () => {
    it('should load paths from external source', async () => {
      const mockFetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({
          paths: [
            { id: 'remote1', title: 'Remote Path 1', category: 'remote' },
            { id: 'remote2', title: 'Remote Path 2', category: 'remote' }
          ]
        })
      });
      global.fetch = mockFetch;

      await dashboard.loadPathsFromUrl('/api/paths');

      const paths = dashboard.getPaths();
      expect(paths.some(p => p.id === 'remote1')).toBe(true);
      expect(paths.some(p => p.id === 'remote2')).toBe(true);
      expect(mockFetch).toHaveBeenCalledWith('/api/paths');
    });

    it('should handle loading errors gracefully', async () => {
      const mockFetch = vi.fn().mockRejectedValue(new Error('Network error'));
      global.fetch = mockFetch;

      const errorSpy = vi.fn();
      container.addEventListener('pathLoadError', errorSpy);

      await dashboard.loadPathsFromUrl('/api/paths');

      expect(errorSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: expect.objectContaining({
            error: expect.any(Error),
            url: '/api/paths'
          })
        })
      );
    });

    it('should show loading state during path loading', async () => {
      let resolvePromise;
      const loadingPromise = new Promise(resolve => {
        resolvePromise = resolve;
      });

      const mockFetch = vi.fn().mockReturnValue(loadingPromise);
      global.fetch = mockFetch;

      const loadPromise = dashboard.loadPathsFromUrl('/api/paths');

      expect(container.querySelector('.loading-indicator')).toBeTruthy();
      expect(container.querySelector('.loading-indicator').textContent).toContain('Loading paths...');

      resolvePromise({
        ok: true,
        json: () => Promise.resolve({ paths: [] })
      });

      await loadPromise;

      expect(container.querySelector('.loading-indicator')).toBeFalsy();
    });

    it('should merge loaded paths with existing ones', async () => {
      const initialPaths = dashboard.getPaths();
      const initialCount = initialPaths.length;

      const mockFetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({
          paths: [
            { id: 'new1', title: 'New Path 1', category: 'new' }
          ]
        })
      });
      global.fetch = mockFetch;

      await dashboard.loadPathsFromUrl('/api/paths');

      const updatedPaths = dashboard.getPaths();
      expect(updatedPaths.length).toBe(initialCount + 1);
      expect(updatedPaths.some(p => p.id === 'new1')).toBe(true);
    });
  });

  describe('Path Caching', () => {
    beforeEach(() => {
      vi.useFakeTimers();
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it('should cache loaded paths', async () => {
      const mockFetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({
          paths: [{ id: 'cached1', title: 'Cached Path' }]
        })
      });
      global.fetch = mockFetch;

      await dashboard.loadPathsFromUrl('/api/paths');
      expect(mockFetch).toHaveBeenCalledTimes(1);

      await dashboard.loadPathsFromUrl('/api/paths');
      expect(mockFetch).toHaveBeenCalledTimes(1);
    });

    it('should respect cache expiration', async () => {
      const mockFetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({
          paths: [{ id: 'expired1', title: 'Expired Path' }]
        })
      });
      global.fetch = mockFetch;

      await dashboard.loadPathsFromUrl('/api/paths');

      vi.advanceTimersByTime(dashboard.CACHE_EXPIRY + 1000);

      await dashboard.loadPathsFromUrl('/api/paths');
      expect(mockFetch).toHaveBeenCalledTimes(2);
    });

    it('should allow cache invalidation', async () => {
      const mockFetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({
          paths: [{ id: 'invalidated1', title: 'Invalidated Path' }]
        })
      });
      global.fetch = mockFetch;

      await dashboard.loadPathsFromUrl('/api/paths');
      dashboard.invalidateCache();
      await dashboard.loadPathsFromUrl('/api/paths');

      expect(mockFetch).toHaveBeenCalledTimes(2);
    });
  });

  describe('Path Metadata', () => {
    it('should track path loading timestamps', async () => {
      const beforeLoad = Date.now();

      const mockFetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ paths: [] })
      });
      global.fetch = mockFetch;

      await dashboard.loadPathsFromUrl('/mock/paths', true);

      const metadata = dashboard.getPathMetadata();
      expect(metadata.lastLoaded).toBeGreaterThanOrEqual(beforeLoad);
      expect(metadata.lastLoaded).toBeLessThanOrEqual(Date.now());
    });

    it('should track path update history', () => {
      const initialPaths = dashboard.getPaths();
      const pathId = initialPaths[0].id;

      dashboard.updatePath(pathId, { title: 'Updated Title' });
      dashboard.updatePath(pathId, { description: 'Updated Description' });

      const history = dashboard.getPathHistory(pathId);
      expect(history.length).toBe(2);
      expect(history[0].changes).toHaveProperty('title');
      expect(history[1].changes).toHaveProperty('description');
    });

    it('should provide path statistics', () => {
      const stats = dashboard.getPathStatistics();

      expect(stats).toHaveProperty('totalPaths');
      expect(stats).toHaveProperty('categoryCounts');
      expect(stats).toHaveProperty('difficultyDistribution');
      expect(stats.totalPaths).toBe(dashboard.getPaths().length);
    });
  });
});
