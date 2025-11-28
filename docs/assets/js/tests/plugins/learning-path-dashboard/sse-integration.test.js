import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import LearningPathDashboard from '../../../plugins/learning-path-dashboard.js';
import { createMockContainer, mockConsole, cleanupDOM } from './test-helpers.js';

describe('SSE Integration', () => {
  let container;
  let dashboard;
  let mockFetch;
  let mockEventSource;
  let eventSourceCallbacks;

  beforeEach(() => {
    mockConsole();
    vi.useRealTimers();
    container = createMockContainer('sse-integration');

    // Mock fetch globally
    mockFetch = vi.fn();
    global.fetch = mockFetch;

    // Mock EventSource with callback tracking
    eventSourceCallbacks = {
      open: [],
      error: [],
      'manifest-updated': []
    };

    mockEventSource = {
      addEventListener: vi.fn((event, callback) => {
        if (eventSourceCallbacks[event]) {
          eventSourceCallbacks[event].push(callback);
        }
      }),
      close: vi.fn()
    };

    global.EventSource = vi.fn(() => mockEventSource);
  });

  afterEach(() => {
    dashboard?.destroy();
    cleanupDOM();
    vi.restoreAllMocks();
    delete global.fetch;
    delete global.EventSource;
  });

  describe('SSE Connection Setup', () => {
    it('should establish SSE connection when enableServerSync is true', () => {
      const mockManifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'initial',
        descriptors: [],
        errors: []
      };

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => mockManifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });

      expect(global.EventSource).toHaveBeenCalledWith('http://localhost:3002/api/progress/events');
      expect(mockEventSource.addEventListener).toHaveBeenCalledWith('open', expect.any(Function));
      expect(mockEventSource.addEventListener).toHaveBeenCalledWith('manifest-updated', expect.any(Function));
      expect(mockEventSource.addEventListener).toHaveBeenCalledWith('error', expect.any(Function));
    });

    it('should not establish SSE connection when enableServerSync is false', () => {
      dashboard = new LearningPathDashboard(container, [], { enableServerSync: false });

      expect(global.EventSource).not.toHaveBeenCalled();
    });

    it('should emit sse-connected event when connection opens', () => {
      const mockManifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'initial',
        descriptors: [],
        errors: []
      };

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => mockManifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });

      const connectSpy = vi.fn();
      dashboard.on('sse-connected', connectSpy);

      // Simulate SSE connection open
      const openCallback = eventSourceCallbacks.open[0];
      openCallback();

      expect(connectSpy).toHaveBeenCalled();
      expect(dashboard.serverConnected).toBe(true);
    });
  });

  describe('Manifest Update Events', () => {
    it('should reload manifest when manifest-updated event received with different checksum', async () => {
      const initialManifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'checksum-v1',
        descriptors: [
          { id: 'path-1', title: 'Original Path', category: 'test', path: '/original.md' }
        ],
        errors: []
      };

      const updatedManifest = {
        success: true,
        version: '1.0.1',
        generatedAt: '2025-10-06T01:00:00.000Z',
        checksum: 'checksum-v2',
        descriptors: [
          { id: 'path-1', title: 'Updated Path', category: 'test', path: '/updated.md' },
          { id: 'path-2', title: 'New Path', category: 'test', path: '/new.md' }
        ],
        errors: []
      };

      // First fetch returns initial manifest
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => initialManifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });
      await dashboard.fetchManifest();

      expect(dashboard.paths).toHaveLength(1);
      expect(dashboard.manifestChecksum).toBe('checksum-v1');

      // Second fetch returns updated manifest
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => updatedManifest
      });

      // Simulate SSE manifest-updated event
      const manifestUpdateCallback = eventSourceCallbacks['manifest-updated'][0];
      await manifestUpdateCallback({
        data: JSON.stringify({
          checksum: 'checksum-v2',
          descriptorCount: 2,
          version: '1.0.1'
        })
      });

      // Wait for async manifest reload
      await new Promise(resolve => setTimeout(resolve, 100));

      expect(dashboard.paths).toHaveLength(2);
      expect(dashboard.manifestChecksum).toBe('checksum-v2');
      expect(dashboard.paths[0].title).toBe('Updated Path');
    });

    it('should skip reload when manifest-updated event has same checksum', async () => {
      const manifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'unchanged-checksum',
        descriptors: [
          { id: 'path-1', title: 'Test Path', category: 'test', path: '/test.md' }
        ],
        errors: []
      };

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => manifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });
      await dashboard.fetchManifest();

      const fetchCallCount = mockFetch.mock.calls.length;

      // Simulate SSE event with same checksum
      const manifestUpdateCallback = eventSourceCallbacks['manifest-updated'][0];
      await manifestUpdateCallback({
        data: JSON.stringify({
          checksum: 'unchanged-checksum',
          descriptorCount: 1
        })
      });

      await new Promise(resolve => setTimeout(resolve, 100));

      // Should not trigger additional fetch
      expect(mockFetch.mock.calls.length).toBe(fetchCallCount);
    });

    it('should preserve user selections across manifest refresh', async () => {
      const initialManifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'v1',
        descriptors: [
          { id: 'path-1', title: 'Path 1', category: 'test', path: '/path1.md' },
          { id: 'path-2', title: 'Path 2', category: 'test', path: '/path2.md' }
        ],
        errors: []
      };

      const updatedManifest = {
        success: true,
        version: '1.0.1',
        generatedAt: '2025-10-06T01:00:00.000Z',
        checksum: 'v2',
        descriptors: [
          { id: 'path-1', title: 'Path 1 Updated', category: 'test', path: '/path1.md' },
          { id: 'path-2', title: 'Path 2 Updated', category: 'test', path: '/path2.md' },
          { id: 'path-3', title: 'Path 3 New', category: 'test', path: '/path3.md' }
        ],
        errors: []
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => initialManifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });
      await dashboard.fetchManifest();

      // Select path-1
      dashboard.selectedPaths.add('path-1');

      // Mock server save for selection persistence
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ success: true, savedPaths: ['path-1'] })
      });

      dashboard.saveSelectedPathsToStorage();

      // Trigger manifest update - needs two fetch mocks:
      // 1. fetchManifest() fetches the manifest
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => updatedManifest
      });
      // 2. loadSelectedPathsFromStorage() during fetchManifest() loads selections
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ success: true, selections: { selectedPaths: ['path-1'], selectionCount: 1 } })
      });

      const manifestUpdateCallback = eventSourceCallbacks['manifest-updated'][0];
      await manifestUpdateCallback({
        data: JSON.stringify({
          checksum: 'v2',
          descriptorCount: 3
        })
      });

      // Wait for async manifest refresh to complete
      await new Promise(resolve => setTimeout(resolve, 500));

      // Verify selection persisted
      expect(dashboard.selectedPaths.has('path-1')).toBe(true);
      expect(dashboard.paths).toHaveLength(3);
    });

    it('should emit manifest-loaded event on successful refresh', async () => {
      const initialManifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'old',
        descriptors: [
          { id: 'path-1', title: 'Path 1', category: 'test', path: '/path1.md' }
        ],
        errors: []
      };

      const updatedManifest = {
        success: true,
        version: '1.0.1',
        generatedAt: '2025-10-06T01:00:00.000Z',
        checksum: 'new',
        descriptors: [
          { id: 'path-1', title: 'Path 1', category: 'test', path: '/path1.md' },
          { id: 'path-2', title: 'Path 2', category: 'test', path: '/path2.md' }
        ],
        errors: []
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => initialManifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });
      await dashboard.fetchManifest();

      const eventSpy = vi.fn();
      dashboard.on('manifest-loaded', eventSpy);

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => updatedManifest
      });

      // Trigger refresh
      const manifestUpdateCallback = eventSourceCallbacks['manifest-updated'][0];
      await manifestUpdateCallback({
        data: JSON.stringify({
          checksum: 'new',
          descriptorCount: 2
        })
      });

      await new Promise(resolve => setTimeout(resolve, 200));

      // Verify manifest-loaded event emitted with updated data
      expect(eventSpy).toHaveBeenCalledWith(expect.objectContaining({
        totalPaths: 2,
        checksum: 'new'
      }));
    });
  });

  describe('SSE Error Handling', () => {
    it('should emit sse-error event on connection error', () => {
      dashboard = new LearningPathDashboard(container, { enableServerSync: true });

      const errorSpy = vi.fn();
      dashboard.on('sse-error', errorSpy);

      // Simulate SSE error
      const errorCallback = eventSourceCallbacks.error[0];
      const mockError = new Error('Connection failed');
      errorCallback(mockError);

      expect(errorSpy).toHaveBeenCalledWith({ error: mockError });
      expect(dashboard.serverConnected).toBe(false);
    });

    it('should attempt reconnection with exponential backoff on error', () => {
      vi.useFakeTimers();

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });

      // Simulate first connection
      const initialEventSource = global.EventSource.mock.results[0].value;

      // Trigger error
      const errorCallback = eventSourceCallbacks.error[0];
      errorCallback(new Error('Connection lost'));

      // Verify close was called
      expect(initialEventSource.close).toHaveBeenCalled();

      // Fast-forward to first reconnect attempt (1000ms * 2^0 = 1000ms)
      vi.advanceTimersByTime(1000);

      // Should have attempted reconnection
      expect(global.EventSource).toHaveBeenCalledTimes(2);

      vi.useRealTimers();
    });

    it('should emit sse-error events on repeated connection failures', () => {
      vi.useFakeTimers();

      dashboard = new LearningPathDashboard(container, {
        enableServerSync: true
      });

      const errorSpy = vi.fn();
      dashboard.on('sse-error', errorSpy);

      // Trigger multiple errors to exceed max attempts
      const errorCallback = eventSourceCallbacks.error[0];

      for (let i = 0; i < 5; i++) {
        errorCallback(new Error('Connection failed'));

        // Advance by exponential backoff time
        const delay = 1000 * Math.pow(2, i);
        vi.advanceTimersByTime(delay + 100);

        // Reset callbacks for next attempt
        if (global.EventSource.mock.results[i + 1]) {
          const nextEventSource = global.EventSource.mock.results[i + 1].value;
          eventSourceCallbacks.error.push(errorCallback);
        }
      }

      // Verify error events emitted for reconnection attempts
      expect(errorSpy.mock.calls.length).toBeGreaterThanOrEqual(1);

      vi.useRealTimers();
    });

    it('should handle malformed manifest-updated event data', async () => {
      const manifest = {
        success: true,
        version: '1.0.0',
        generatedAt: '2025-10-06T00:00:00.000Z',
        checksum: 'test',
        descriptors: [],
        errors: []
      };

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => manifest
      });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });
      await dashboard.fetchManifest();

      const errorSpy = vi.spyOn(console, 'error');

      // Trigger manifest-updated with invalid JSON
      const manifestUpdateCallback = eventSourceCallbacks['manifest-updated'][0];
      await manifestUpdateCallback({
        data: 'invalid-json{{'
      });

      expect(errorSpy).toHaveBeenCalled();
    });
  });

  describe('SSE Connection Lifecycle', () => {
    it('should close SSE connection on dashboard destroy', () => {
      dashboard = new LearningPathDashboard(container, { enableServerSync: true });

      const eventSource = dashboard.eventSource;
      expect(eventSource).toBeTruthy();

      dashboard.destroy();

      expect(eventSource.close).toHaveBeenCalled();
    });

    it('should not reconnect after destroy', () => {
      vi.useFakeTimers();

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });

      // Trigger error to start reconnect
      const errorCallback = eventSourceCallbacks.error[0];
      errorCallback(new Error('Connection lost'));

      // Destroy dashboard before reconnect
      dashboard.destroy();

      const eventSourceCallCount = global.EventSource.mock.calls.length;

      // Advance timers past reconnect delay
      vi.advanceTimersByTime(5000);

      // Should not have attempted reconnection after destroy
      expect(global.EventSource.mock.calls.length).toBe(eventSourceCallCount);

      vi.useRealTimers();
    });

    it('should reset reconnect attempts on successful connection', () => {
      dashboard = new LearningPathDashboard(container, { enableServerSync: true });

      // Simulate failed connection
      const errorCallback = eventSourceCallbacks.error[0];
      errorCallback(new Error('Connection lost'));

      expect(dashboard.sseReconnectAttempts).toBeGreaterThan(0);

      // Simulate successful reconnection
      const openCallback = eventSourceCallbacks.open[0];
      openCallback();

      expect(dashboard.sseReconnectAttempts).toBe(0);
    });
  });

  describe('Multiple Clients Scenario', () => {
    it('should handle rapid manifest updates from multiple sources', async () => {
      const manifests = [
        {
          success: true,
          version: '1.0.0',
          checksum: 'v1',
          generatedAt: '2025-10-06T00:00:00.000Z',
          descriptors: [{ id: 'p1', title: 'Path 1', category: 'test', path: '/p1.md' }],
          errors: []
        },
        {
          success: true,
          version: '1.0.1',
          checksum: 'v2',
          generatedAt: '2025-10-06T00:01:00.000Z',
          descriptors: [
            { id: 'p1', title: 'Path 1', category: 'test', path: '/p1.md' },
            { id: 'p2', title: 'Path 2', category: 'test', path: '/p2.md' }
          ],
          errors: []
        },
        {
          success: true,
          version: '1.0.2',
          checksum: 'v3',
          generatedAt: '2025-10-06T00:02:00.000Z',
          descriptors: [
            { id: 'p1', title: 'Path 1', category: 'test', path: '/p1.md' },
            { id: 'p2', title: 'Path 2', category: 'test', path: '/p2.md' },
            { id: 'p3', title: 'Path 3', category: 'test', path: '/p3.md' }
          ],
          errors: []
        }
      ];

      mockFetch
        .mockResolvedValueOnce({ ok: true, json: async () => manifests[0] })
        .mockResolvedValueOnce({ ok: true, json: async () => manifests[1] })
        .mockResolvedValueOnce({ ok: true, json: async () => manifests[2] });

      dashboard = new LearningPathDashboard(container, { enableServerSync: true });
      await dashboard.fetchManifest();

      const manifestUpdateCallback = eventSourceCallbacks['manifest-updated'][0];

      // Rapid updates
      await manifestUpdateCallback({ data: JSON.stringify({ checksum: 'v2' }) });
      await manifestUpdateCallback({ data: JSON.stringify({ checksum: 'v3' }) });

      await new Promise(resolve => setTimeout(resolve, 200));

      expect(dashboard.manifestChecksum).toBe('v3');
      expect(dashboard.paths).toHaveLength(3);
    });
  });
});
