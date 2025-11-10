import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import sseManager from '../../utils/sse-manager.js';

describe('SSE Manager Utilities', () => {
  let mockResponse;

  beforeEach(() => {
    // Reset SSE manager state completely
    sseManager.cleanup();

    // Create mock response object that properly simulates Express response
    mockResponse = {
      writeHead: vi.fn(),
      write: vi.fn(),
      end: vi.fn(),
      on: vi.fn(),
      removeListener: vi.fn(),
      setHeader: vi.fn(),
      status: vi.fn().mockReturnThis(),
      send: vi.fn(),
      headersSent: false, // Key property for SSE manager to recognize as valid response
      // Add properties that make it look like a real Express response
      req: {},
      locals: {},
      socket: {
        destroyed: false
      }
    };
  });

  afterEach(() => {
    sseManager.cleanup();
    vi.restoreAllMocks();
  }); describe('addClient', () => {
    it('should add a client for a progress type', () => {
      const clientId = sseManager.addClient(mockResponse, 'self-assessment');

      expect(clientId).to.be.a('string');
      expect(clientId.length).to.be.greaterThan(0);
    });

    it('should send initial connection event to new client', () => {
      sseManager.addClient(mockResponse, 'self-assessment');

      expect(mockResponse.writeHead).toHaveBeenCalledTimes(1);
      expect(mockResponse.write).toHaveBeenCalled();
    });

    it('should setup client disconnect handlers', () => {
      const _clientId = sseManager.addClient(mockResponse, 'self-assessment');

      // Verify client was added successfully
      const count = sseManager.getClientCountByType('self-assessment');
      expect(count).to.equal(1);

      // Verify that the response has event listeners set up (for mock responses, this may be simulated)
      expect(mockResponse.on).toHaveBeenCalled();
    });

    it('should handle client without specific progress type', () => {
      const clientId = sseManager.addClient(mockResponse);

      expect(clientId).to.be.a('string');
      expect(clientId.length).to.be.greaterThan(0);
    });
  });

  describe('removeClient', () => {
    it('should remove a specific client', () => {
      const clientId = sseManager.addClient(mockResponse, 'self-assessment');

      // removeClient doesn't return a value, just test it doesn't throw
      expect(() => {
        sseManager.removeClient(clientId);
      }).to.not.throw();

      // Verify client was removed by checking count
      const count = sseManager.getClientCountByType('self-assessment');
      expect(count).to.equal(0);
    });

    it('should handle removal of non-existent client', () => {
      expect(() => {
        sseManager.removeClient('non-existent-id');
      }).to.not.throw();
    });
  });

  describe('cleanup', () => {
    it('should remove all clients', () => {
      sseManager.addClient(mockResponse, 'self-assessment');
      sseManager.addClient({ ...mockResponse }, 'kata-progress');

      sseManager.cleanup();
      const count = sseManager.getActiveClientCount();
      expect(count).to.equal(0);
    });
  });

  describe('broadcast functionality', () => {
    it('should broadcast to specific progress type', () => {
      sseManager.addClient(mockResponse, 'self-assessment');

      // broadcastToProgressType doesn't return a value, just test it doesn't throw
      expect(() => {
        sseManager.broadcastToProgressType('self-assessment', { data: 'test message' });
      }).to.not.throw();
    });

    it('should broadcast to all progress types', () => {
      sseManager.addClient(mockResponse, 'self-assessment');
      sseManager.addClient({ ...mockResponse }, 'kata-progress');

      expect(() => {
        sseManager.broadcastToAll({ data: 'test message' });
      }).to.not.throw();
    });

    it('should handle broadcast with no clients', () => {
      expect(() => {
        sseManager.broadcastToProgressType('self-assessment', { data: 'test message' });
      }).to.not.throw();
    });
  });

  describe('heartbeat functionality', () => {
    it('should send heartbeat to all clients at interval', () => {
      sseManager.addClient(mockResponse, 'self-assessment');

      // Manually trigger heartbeat
      expect(() => {
        sseManager.broadcastHeartbeat();
      }).to.not.throw();
    });

    it('should handle heartbeat with no clients', () => {
      expect(() => {
        sseManager.broadcastHeartbeat();
      }).to.not.throw();
    });
  });

  describe('client management', () => {
    it('should track clients by progress type', () => {
      sseManager.addClient(mockResponse, 'self-assessment');

      // Create a second mock response with proper structure
      const mockResponse2 = {
        writeHead: vi.fn(),
        write: vi.fn(),
        end: vi.fn(),
        on: vi.fn(),
        removeListener: vi.fn(),
        setHeader: vi.fn(),
        status: vi.fn().mockReturnThis(),
        send: vi.fn(),
        headersSent: false,
        req: {},
        locals: {},
        socket: {
          destroyed: false
        }
      };
      sseManager.addClient(mockResponse2, 'self-assessment');

      const count = sseManager.getClientCountByType('self-assessment');
      expect(count).to.equal(2);
    });

    it('should return 0 for unknown progress type', () => {
      const count = sseManager.getClientCountByType('unknown-type');
      expect(count).to.equal(0);
    });
  });

  describe('getClientCountByType', () => {
    it('should return correct client count by progress type', () => {
      sseManager.addClient(mockResponse, 'self-assessment');

      const count = sseManager.getClientCountByType('self-assessment');
      expect(count).to.equal(1);
    });

    it('should return 0 for unknown progress type', () => {
      const count = sseManager.getClientCountByType('unknown-type');
      expect(count).to.equal(0);
    });
  });

  describe('getClientStats', () => {
    it('should return client statistics', () => {
      sseManager.addClient(mockResponse, 'self-assessment');

      const stats = sseManager.getClientStats();
      expect(stats).to.be.an('object');
      expect(stats.totalClients).to.equal(1);
      expect(stats.clientsByType).to.be.an('object');
      expect(stats.clientsByType['self-assessment']).to.equal(1);
    });

    it('should return empty stats when no clients', () => {
      const stats = sseManager.getClientStats();
      expect(stats).to.be.an('object');
      expect(stats.totalClients).to.equal(0);
      expect(stats.clientsByType).to.be.an('object');
    });
  });

  describe('error handling', () => {
    it('should handle invalid response objects', () => {
      expect(() => {
        sseManager.addClient(null, 'self-assessment');
      }).to.not.throw();
    });

    it('should handle undefined parameters', () => {
      expect(() => {
        sseManager.addClient();
      }).to.not.throw();
    });
  });

  // Memory Leak Prevention Tests
  describe('Memory Leak Prevention', () => {
    const createMockResponse = () => ({
      writeHead: vi.fn(),
      write: vi.fn(),
      end: vi.fn(),
      on: vi.fn(),
      headersSent: false,
      req: {},
      locals: {},
      socket: { destroyed: false }
    });

    describe('Connection Limits', () => {
      it('should limit maximum number of concurrent connections', () => {
        const maxConnections = sseManager.getMaxConnections();
        expect(maxConnections).toBeGreaterThan(0);
        expect(maxConnections).toBeLessThanOrEqual(1000);
      });

      it('should reject new connections when at limit', () => {
        const maxConnections = sseManager.getMaxConnections();
        const responses = [];

        // Add clients up to the limit
        for (let i = 0; i < maxConnections; i++) {
          const res = createMockResponse();
          responses.push(res);
          const clientId = sseManager.addClient(res, 'test-progress');
          expect(clientId).toMatch(/^client_/);
        }

        // Try to add one more - should be rejected
        const extraRes = createMockResponse();
        const result = sseManager.addClient(extraRes, 'test-progress');
        expect(result).toBeNull();
        expect(sseManager.getActiveClientCount()).toBe(maxConnections);
      });

      it('should allow new connections after cleanup of old ones', () => {
        const maxConnections = Math.min(sseManager.getMaxConnections(), 10); // Use smaller number for test
        const clientIds = [];

        // Fill up to limit
        for (let i = 0; i < maxConnections; i++) {
          const res = createMockResponse();
          const clientId = sseManager.addClient(res, 'test-progress');
          clientIds.push(clientId);
        }

        // Remove half the clients
        const halfCount = Math.floor(maxConnections / 2);
        for (let i = 0; i < halfCount; i++) {
          sseManager.removeClient(clientIds[i]);
        }

        // Should be able to add new clients
        for (let i = 0; i < halfCount; i++) {
          const res = createMockResponse();
          const clientId = sseManager.addClient(res, 'test-progress');
          expect(clientId).toMatch(/^client_/);
        }

        expect(sseManager.getActiveClientCount()).toBe(maxConnections);
      });
    });

    describe('Event History Cleanup', () => {
      it('should limit event history per progress type', () => {
        const maxHistorySize = sseManager.getMaxHistorySize();
        expect(maxHistorySize).toBeGreaterThan(0);
        expect(maxHistorySize).toBeLessThanOrEqual(1000);

        // Add more events than the limit
        for (let i = 0; i < maxHistorySize + 50; i++) {
          sseManager.addToHistory('test-progress', {
            type: 'test',
            data: { counter: i },
            timestamp: new Date().toISOString()
          });
        }

        const history = sseManager.getEventHistory('test-progress');
        expect(history.length).toBeLessThanOrEqual(maxHistorySize);
      });

      it('should cleanup old events using time-based expiration', () => {
        const oldTimestamp = new Date(Date.now() - 25 * 60 * 60 * 1000).toISOString(); // 25 hours ago
        const recentTimestamp = new Date().toISOString();

        // Add old events
        for (let i = 0; i < 10; i++) {
          sseManager.addToHistory('test-progress', {
            type: 'old-test',
            data: { counter: i },
            timestamp: oldTimestamp
          });
        }

        // Add recent events
        for (let i = 0; i < 5; i++) {
          sseManager.addToHistory('test-progress', {
            type: 'recent-test',
            data: { counter: i },
            timestamp: recentTimestamp
          });
        }

        // Trigger cleanup
        sseManager.cleanupExpiredEvents();

        const history = sseManager.getEventHistory('test-progress');
        // Should only have recent events
        expect(history.length).toBe(5);
        expect(history.every(event => event.type === 'recent-test')).toBe(true);
      });
    });

    describe('Memory Usage Monitoring', () => {
      it('should provide memory usage statistics', () => {
        const stats = sseManager.getMemoryStats();

        expect(stats).toHaveProperty('clientCount');
        expect(stats).toHaveProperty('progressTypeCount');
        expect(stats).toHaveProperty('totalEventHistory');
        expect(stats).toHaveProperty('estimatedMemoryUsage');
        expect(stats).toHaveProperty('isHeartbeatActive');

        expect(typeof stats.clientCount).toBe('number');
        expect(typeof stats.progressTypeCount).toBe('number');
        expect(typeof stats.totalEventHistory).toBe('number');
        expect(typeof stats.estimatedMemoryUsage).toBe('number');
        expect(typeof stats.isHeartbeatActive).toBe('boolean');
      });
    });

    describe('Heartbeat Timer Management', () => {
      it('should properly cleanup heartbeat timer on shutdown', () => {
        sseManager.startHeartbeat();
        expect(sseManager.isHeartbeatActive()).toBe(true);

        sseManager.stopHeartbeat();
        expect(sseManager.isHeartbeatActive()).toBe(false);
      });

      it('should handle multiple cleanup calls gracefully', () => {
        sseManager.startHeartbeat();
        expect(sseManager.isHeartbeatActive()).toBe(true);

        expect(() => {
          sseManager.cleanup();
          sseManager.cleanup();
          sseManager.cleanup();
        }).not.toThrow();

        expect(sseManager.isHeartbeatActive()).toBe(false);
      });
    });

    describe('Stale Connection Detection', () => {
      it('should detect and remove stale connections', () => {
        const res = createMockResponse();

        // First, allow the client to be added successfully
        const clientId = sseManager.addClient(res, 'test-progress');
        expect(clientId).not.toBeNull();
        expect(sseManager.getActiveClientCount()).toBe(1);

        // Then set up the write method to fail for subsequent calls
        res.write.mockImplementation(() => {
          throw new Error('Connection lost');
        });

        // Trigger heartbeat - should detect stale connection
        sseManager.broadcastHeartbeat();

        // Client should be removed due to write failure
        expect(sseManager.getActiveClientCount()).toBe(0);
      });

      it('should timeout inactive connections', () => {
        const res = createMockResponse();
        const clientId = sseManager.addClient(res, 'test-progress');

        expect(sseManager.getActiveClientCount()).toBe(1);

        // Set last activity to be old enough to timeout (3 hours ago, timeout is 2 hours)
        const oldTime = Date.now() - (3 * 60 * 60 * 1000); // 3 hours ago
        sseManager.clients.get(clientId).lastActivity = oldTime;

        // Trigger timeout cleanup
        sseManager.cleanupStaleConnections();

        // Connection should be removed
        expect(sseManager.getActiveClientCount()).toBe(0);
        expect(sseManager.clients.has(clientId)).toBe(false);
      });
    });
  });
});
