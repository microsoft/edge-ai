import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import LearningPathDashboard from '../../../plugins/learning-path-dashboard.js';
import { createMockContainer, mockConsole, cleanupDOM } from './test-helpers.js';

describe('Manifest Loader', () => {
  let container;
  let dashboard;
  let mockFetch;

  beforeEach(() => {
    mockConsole();
    vi.useRealTimers();
    container = createMockContainer('manifest-loader');

    // Mock fetch globally
    mockFetch = vi.fn();
    global.fetch = mockFetch;

    // Mock EventSource for SSE
    global.EventSource = vi.fn(() => ({
      addEventListener: vi.fn(),
      close: vi.fn()
    }));
  });

  afterEach(() => {
    dashboard?.destroy();
    cleanupDOM();
    vi.restoreAllMocks();
    delete global.fetch;
    delete global.EventSource;
  });

  describe('Manifest Fetch Success', () => {
    it('should fetch manifest from /api/learning-paths/manifest endpoint', async () => {
      const mockManifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'abc123',
        descriptors: [
          {
            id: 'path-1',
            title: 'Test Path 1',
            description: 'Description 1',
            category: 'Frontend',
            path: '/learning/paths/test-path-1.md'
          },
          {
            id: 'path-2',
            title: 'Test Path 2',
            description: 'Description 2',
            category: 'Backend',
            path: '/learning/paths/test-path-2.md'
          }
        ],
        errors: []
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => mockManifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });
      const result = await dashboard.fetchManifest();

      expect(result).toBe(true);
      expect(mockFetch).toHaveBeenCalledWith('http://localhost:3002/api/learning/manifest');
      expect(dashboard.paths).toHaveLength(2);
      expect(dashboard.paths[0].title).toBe('Test Path 1');
      expect(dashboard.manifestChecksum).toBe('abc123');
    });

    it('should render cards after successful manifest load', async () => {
      const mockManifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'def456',
        descriptors: [
          {
            id: 'path-1',
            title: 'Test Path',
            description: 'Test Description',
            category: 'Testing',
            path: '/learning/paths/test.md'
          }
        ],
        errors: []
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockManifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });
      await dashboard.fetchManifest();

      const cards = container.querySelectorAll('.learning-path-card');
      expect(cards.length).toBeGreaterThan(0);
    });

    it('should emit manifest-loaded event with metadata', async () => {
      const mockManifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T12:00:00.000Z',
        checksum: 'xyz789',
        descriptors: [
          { id: 'path-1', title: 'Path 1', category: 'test', path: '/test.md' }
        ],
        errors: []
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockManifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });

      const eventSpy = vi.fn();
      dashboard.on('manifest-loaded', eventSpy);

      await dashboard.fetchManifest();

      expect(eventSpy).toHaveBeenCalledWith({
        totalPaths: 1,
        checksum: 'xyz789',
        generatedAt: '2025-10-06T12:00:00.000Z'
      });
    });

    it('should skip reload when checksum unchanged', async () => {
      const mockManifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'same-checksum',
        descriptors: [
          { id: 'path-1', title: 'Path 1', category: 'test', path: '/test.md' }
        ],
        errors: []
      };

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => mockManifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });

      // First fetch - loads data
      await dashboard.fetchManifest();
      const firstPathsLength = dashboard.paths.length;

      // Second fetch - should skip due to matching checksum
      const renderSpy = vi.spyOn(dashboard, 'renderCards');
      await dashboard.fetchManifest();

      // Verify no re-render occurred (checksum match means no changes)
      expect(renderSpy).not.toHaveBeenCalled();
      expect(dashboard.paths.length).toBe(firstPathsLength);
    });
  });

  describe('Manifest Fetch Errors', () => {
    it('should handle HTTP error responses', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 500,
        statusText: 'Internal Server Error'
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });

      const errorSpy = vi.fn();
      dashboard.on('manifest-error', errorSpy);

      const result = await dashboard.fetchManifest();

      expect(result).toBe(false);
      expect(dashboard.serverConnected).toBe(false);
      expect(errorSpy).toHaveBeenCalledWith({
        error: expect.stringContaining('HTTP 500')
      });
    });

    it('should handle network errors', async () => {
      mockFetch.mockRejectedValueOnce(new Error('Network failure'));

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });

      const errorSpy = vi.fn();
      dashboard.on('manifest-error', errorSpy);

      const result = await dashboard.fetchManifest();

      expect(result).toBe(false);
      expect(dashboard.serverConnected).toBe(false);
      expect(errorSpy).toHaveBeenCalledWith({
        error: 'Network failure'
      });
    });

    it('should handle invalid manifest structure', async () => {
      const invalidManifest = {
        success: true,
        version: '1.0.0'
        // Missing descriptors array
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => invalidManifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });

      const errorSpy = vi.fn();
      dashboard.on('manifest-error', errorSpy);

      const result = await dashboard.fetchManifest();

      expect(result).toBe(false);
      expect(errorSpy).toHaveBeenCalledWith({
        error: expect.stringContaining('Invalid manifest structure')
      });
    });

    it('should show offline indicator when manifest fails to load', async () => {
      mockFetch.mockRejectedValueOnce(new Error('Connection refused'));

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });
      await dashboard.fetchManifest();

      const offlineIndicator = container.querySelector('.offline-indicator');
      expect(offlineIndicator).toBeTruthy();
      expect(offlineIndicator.textContent).toContain('Offline');
    });
  });

  describe('Empty Manifest Handling', () => {
    it('should handle empty descriptors array', async () => {
      const emptyManifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'empty',
        descriptors: [],
        errors: []
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => emptyManifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });
      const result = await dashboard.fetchManifest();

      expect(result).toBe(true);
      expect(dashboard.paths).toHaveLength(0);

      // Should show no results message
      expect(container.textContent).toContain('No learning paths match the current filters');
    });

    it('should announce empty state to screen readers', async () => {
      const emptyManifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'empty',
        descriptors: [],
        errors: []
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => emptyManifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });
      await dashboard.fetchManifest();

      // Empty state announcement happens through renderCards
      const messageElement = container.querySelector('[role="status"]');
      expect(messageElement).toBeTruthy();
      expect(container.textContent).toContain('No learning paths match the current filters');
    });
  });

  describe('Manifest with Errors', () => {
    it('should load valid descriptors even when errors exist', async () => {
      const manifestWithErrors = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'has-errors',
        descriptors: [
          { id: 'path-1', title: 'Valid Path', category: 'test', path: '/valid.md' }
        ],
        errors: [
          {
            file: '/invalid-path.md',
            message: 'Missing required field: title',
            severity: 'error'
          }
        ]
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => manifestWithErrors
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });
      const result = await dashboard.fetchManifest();

      expect(result).toBe(true);
      expect(dashboard.paths).toHaveLength(1);
      expect(dashboard.paths[0].title).toBe('Valid Path');
    });
  });

  describe('Virtualization Guardrail', () => {
    it('should log warning when virtualization flag is detected', async () => {
      const warnSpy = vi.spyOn(console, 'warn');

      const mockManifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'test',
        descriptors: [
          { id: 'path-1', title: 'Test', category: 'test', path: '/test.md' }
        ],
        errors: []
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockManifest
      });

      // Create dashboard with virtualization enabled (should be prevented)
      dashboard = new LearningPathDashboard(container, {
        enableServerSync: true,
        enableVirtualization: true
      });

      await dashboard.fetchManifest();

      // Check that warning was logged about virtualization not being supported
      // logging.js formats as single string with timestamp and prefix
      expect(warnSpy).toHaveBeenCalledWith(
        expect.stringMatching(/\[.*\] \[LearningPathDashboard:WARN\] Virtualization flag detected.*not supported/)
      );
    });

    it('should never activate virtualization regardless of config', async () => {
      const mockManifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'test',
        descriptors: Array.from({ length: 100 }, (_, i) => ({
          id: `path-${i}`,
          title: `Path ${i}`,
          category: 'test',
          path: `/path-${i}.md`
        })),
        errors: []
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockManifest
      });

      dashboard = new LearningPathDashboard(container, {
        enableServerSync: true,
        enableVirtualization: true // Try to enable
      });

      await dashboard.fetchManifest();

      // Verify all cards are rendered (no virtualization)
      const cards = container.querySelectorAll('.learning-path-card');
      expect(cards.length).toBe(100);

      // Verify no virtual scrolling elements
      expect(container.querySelector('.virtual-scroller')).toBeNull();
    });
  });

  describe('ARIA Live Region Announcements', () => {
    it('should use shared .learning-dashboard-aria-live region', async () => {
      const mockManifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'test',
        descriptors: [
          { id: 'path-1', title: 'Test Path', category: 'test', path: '/test.md' }
        ],
        errors: []
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockManifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });
      await dashboard.fetchManifest();

      const liveRegion = container.querySelector('.learning-dashboard-aria-live');
      expect(liveRegion).toBeTruthy();
      expect(liveRegion.getAttribute('role')).toBe('status');
      expect(liveRegion.getAttribute('aria-live')).toBe('polite');
      expect(liveRegion.getAttribute('aria-atomic')).toBe('true');
      expect(liveRegion.classList.contains('sr-only')).toBe(true);
    });

    it('should emit manifest-loaded event on success', async () => {
      const mockManifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'test',
        descriptors: [
          { id: 'path-1', title: 'Path 1', category: 'test', path: '/test1.md' },
          { id: 'path-2', title: 'Path 2', category: 'test', path: '/test2.md' }
        ],
        errors: []
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockManifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });

      const eventSpy = vi.fn();
      dashboard.on('manifest-loaded', eventSpy);

      await dashboard.fetchManifest();

      expect(eventSpy).toHaveBeenCalledWith(expect.objectContaining({
        totalPaths: 2,
        checksum: 'test'
      }));
    });

    it('should emit manifest-error event on failure', async () => {
      mockFetch.mockRejectedValueOnce(new Error('Connection timeout'));

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });

      const errorEventSpy = vi.fn();
      dashboard.on('manifest-error', errorEventSpy);

      await dashboard.fetchManifest();

      expect(errorEventSpy).toHaveBeenCalledWith(expect.objectContaining({
        error: expect.stringContaining('Connection timeout')
      }));
    });
  });

  describe('loadPaths() with null argument', () => {
    it('should call fetchManifest() when paths argument is null', async () => {
      const mockManifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'abc123',
        descriptors: [
          {
            id: 'path-1',
            title: 'Test Path 1',
            description: 'Description 1',
            category: 'Frontend',
            path: '/learning/paths/test-path-1.md'
          }
        ],
        errors: []
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => mockManifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });
      await dashboard.loadPaths(null);

      expect(mockFetch).toHaveBeenCalledWith('http://localhost:3002/api/learning/manifest');
      expect(dashboard.paths).toHaveLength(1);
    });

    it('should load array of paths directly when provided', async () => {
      dashboard = new LearningPathDashboard(container, { enableServerSync: false });

      const mockPaths = [
        {
          id: 'path-1',
          title: 'Test Path 1',
          description: 'Description 1',
          category: 'Frontend',
          path: '/learning/paths/test-path-1.md'
        }
      ];

      // Mock fetch for selection loading (always called for selection sync)
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ selectedPaths: [] })
      });

      await dashboard.loadPaths(mockPaths);

      // Fetch is called once for selection loading
      expect(mockFetch).toHaveBeenCalledTimes(1);
      expect(dashboard.paths).toHaveLength(1);
      expect(dashboard.paths[0].id).toBe('path-1');
    });
  });
});
