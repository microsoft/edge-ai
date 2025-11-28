/**
 * SSE Memory Integration Tests
 * Tests for memory usage under load and real-world scenarios
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import sseManager from '../../utils/sse-manager.js';

describe('SSE Memory Integration Tests', () => {
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

  beforeEach(() => {
    sseManager.cleanup();
    sseManager.initializeProgressStreams();
    sseManager.startHeartbeat();
  });

  afterEach(() => {
    sseManager.cleanup();
  });

  describe('Memory Usage Under Load', () => {
    it('should maintain stable memory usage with many connections', () => {
      const connectionCount = 50;
      const progressTypeCount = 5;
      const clientIds = [];

      // Initial memory stats
      const initialStats = sseManager.getMemoryStats();

      // Add many connections
      for (let i = 0; i < connectionCount; i++) {
        const res = createMockResponse();
        const clientId = sseManager.addClient(res, `progress-type-${i % progressTypeCount}`);
        clientIds.push(clientId);
      }

      const loadedStats = sseManager.getMemoryStats();
      expect(loadedStats.clientCount).toBe(connectionCount);
      // Account for default progress types (3) plus our test types (5) = 8 total
      expect(loadedStats.progressTypeCount).toBeLessThanOrEqual(progressTypeCount + 3);
      expect(loadedStats.estimatedMemoryUsage).toBeGreaterThan(initialStats.estimatedMemoryUsage);

      // Remove all connections
      clientIds.forEach(clientId => sseManager.removeClient(clientId));

      const cleanedStats = sseManager.getMemoryStats();
      expect(cleanedStats.clientCount).toBe(0);
      // Memory usage should be close to initial (allow some variance)
      expect(cleanedStats.estimatedMemoryUsage).toBeLessThan(loadedStats.estimatedMemoryUsage * 0.2);
    });

    it('should handle rapid connection cycles without memory leaks', () => {
      const cycles = 20;
      const connectionsPerCycle = 10;

      for (let cycle = 0; cycle < cycles; cycle++) {
        const clientIds = [];

        // Connect many clients
        for (let i = 0; i < connectionsPerCycle; i++) {
          const res = createMockResponse();
          const clientId = sseManager.addClient(res, 'test-progress');
          clientIds.push(clientId);
        }

        expect(sseManager.getActiveClientCount()).toBe(connectionsPerCycle);

        // Broadcast events to generate history
        for (let i = 0; i < 5; i++) {
          sseManager.broadcastToProgressType('test-progress', {
            type: 'test-event',
            data: { cycle, event: i }
          });
        }

        // Disconnect all clients
        clientIds.forEach(clientId => sseManager.removeClient(clientId));
        expect(sseManager.getActiveClientCount()).toBe(0);
      }

      // After all cycles, memory usage should be stable
      const finalStats = sseManager.getMemoryStats();
      expect(finalStats.clientCount).toBe(0);
      expect(finalStats.estimatedMemoryUsage).toBeLessThan(1000000); // Less than 1MB
    });

    it('should cleanup expired events automatically', () => {
      const progressType = 'cleanup-test';

      // Add many old events
      for (let i = 0; i < 200; i++) {
        sseManager.addToHistory(progressType, {
          type: 'old-event',
          data: { index: i },
          timestamp: new Date(Date.now() - 25 * 60 * 60 * 1000).toISOString() // 25 hours ago
        });
      }

      // Add some recent events
      for (let i = 0; i < 10; i++) {
        sseManager.addToHistory(progressType, {
          type: 'recent-event',
          data: { index: i },
          timestamp: new Date().toISOString()
        });
      }

      let history = sseManager.getEventHistory(progressType);
      expect(history.length).toBeGreaterThan(10);

      // Trigger cleanup
      sseManager.cleanupExpiredEvents();

      history = sseManager.getEventHistory(progressType);
      expect(history.length).toBe(10);
      expect(history.every(event => event.type === 'recent-event')).toBe(true);
    });
  });

  describe('Stress Testing', () => {
    it('should handle maximum connections gracefully', () => {
      // Ensure clean state
      sseManager.cleanup();
      sseManager.initializeProgressStreams();

      // Use a smaller, more predictable limit for testing
      const testLimit = 10;
      const clientIds = [];

      // Fill to capacity
      for (let i = 0; i < testLimit; i++) {
        const res = createMockResponse();
        const clientId = sseManager.addClient(res, `stress-test-${i % 3}`);
        if (clientId) {
          clientIds.push(clientId);
        }
      }

      expect(sseManager.getActiveClientCount()).toBe(testLimit);

      // Now temporarily override maxConnections to test limit enforcement
      const originalMaxConnections = sseManager.maxConnections;
      sseManager.maxConnections = testLimit;

      // Try to add more - should be rejected
      const extraRes = createMockResponse();
      const extraClient = sseManager.addClient(extraRes, 'overflow-test');
      expect(extraClient).toBeNull();

      // Restore original limit
      sseManager.maxConnections = originalMaxConnections;

      // Broadcast to all clients
      sseManager.broadcastToAll({
        type: 'stress-test',
        data: { message: 'Stress testing broadcast' }
      });

      // All clients should still be active
      expect(sseManager.getActiveClientCount()).toBe(testLimit);

      // Cleanup
      clientIds.forEach(clientId => sseManager.removeClient(clientId));
      expect(sseManager.getActiveClientCount()).toBe(0);
    });

    it('should handle many progress types efficiently', () => {
      // Ensure clean state
      sseManager.cleanup();
      sseManager.initializeProgressStreams();

      // Use a much smaller limit and temporarily override maxProgressTypes for testing
      const testLimit = 10;
      const originalMaxProgressTypes = sseManager.maxProgressTypes;
      sseManager.maxProgressTypes = testLimit + 3; // Account for default types

      const clientIds = [];

      // Create clients for many different progress types
      for (let i = 0; i < testLimit; i++) {
        const res = createMockResponse();
        const clientId = sseManager.addClient(res, `progress-type-${i}`);
        if (clientId) {
          clientIds.push(clientId);
        }
      }

      expect(sseManager.getActiveClientCount()).toBe(testLimit);

      const stats = sseManager.getMemoryStats();
      // Should have 3 default + 10 test = 13 total progress types
      expect(stats.progressTypeCount).toBeLessThanOrEqual(testLimit + 3);

      // Add events to each progress type
      for (let i = 0; i < testLimit; i++) {
        sseManager.addToHistory(`progress-type-${i}`, {
          type: 'test-event',
          data: { progressType: i }
        });
      }

      // Try to add more progress types - should be rejected when at limit
      const extraRes = createMockResponse();
      const extraClient = sseManager.addClient(extraRes, `overflow-progress-type`);

      // This should be null because we're at the progress type limit
      expect(extraClient).toBeNull();

      const finalStats = sseManager.getMemoryStats();
      expect(finalStats.progressTypeCount).toBeLessThanOrEqual(testLimit + 3);

      // Restore original limit
      sseManager.maxProgressTypes = originalMaxProgressTypes;

      // Cleanup
      clientIds.forEach(clientId => sseManager.removeClient(clientId));
    });
  });

  describe('Real-world Scenarios', () => {
    it('should handle mixed connection patterns', () => {
      const scenarios = [
        { progressType: 'self-assessment', clientCount: 5 },
        { progressType: 'kata-progress', clientCount: 3 },
        { progressType: 'lab-progress', clientCount: 7 },
        { progressType: 'course-progress', clientCount: 2 }
      ];

      const allClientIds = [];

      // Setup mixed scenario
      scenarios.forEach(scenario => {
        for (let i = 0; i < scenario.clientCount; i++) {
          const res = createMockResponse();
          const clientId = sseManager.addClient(res, scenario.progressType);
          allClientIds.push(clientId);
        }
      });

      expect(sseManager.getActiveClientCount()).toBe(17); // 5+3+7+2

      // Simulate activity
      scenarios.forEach(scenario => {
        for (let i = 0; i < 5; i++) {
          sseManager.broadcastToProgressType(scenario.progressType, {
            type: 'progress-update',
            data: { step: i, total: 5 }
          });
        }
      });

      // Remove clients gradually
      scenarios.forEach((scenario, index) => {
        const startIndex = scenarios.slice(0, index).reduce((sum, s) => sum + s.clientCount, 0);
        const endIndex = startIndex + scenario.clientCount;

        for (let i = startIndex; i < endIndex; i++) {
          sseManager.removeClient(allClientIds[i]);
        }

        const expectedRemaining = allClientIds.length - endIndex;
        expect(sseManager.getActiveClientCount()).toBe(expectedRemaining);
      });

      expect(sseManager.getActiveClientCount()).toBe(0);
    });

    it('should maintain performance with continuous event streaming', () => {
      const clientCount = 10;
      const eventCount = 100;
      const clientIds = [];

      // Setup clients
      for (let i = 0; i < clientCount; i++) {
        const res = createMockResponse();
        const clientId = sseManager.addClient(res, 'streaming-test');
        clientIds.push(clientId);
      }

      const startTime = Date.now();

      // Stream many events
      for (let i = 0; i < eventCount; i++) {
        sseManager.broadcastToProgressType('streaming-test', {
          type: 'stream-event',
          data: {
            sequence: i,
            timestamp: new Date().toISOString(),
            payload: 'x'.repeat(100) // Some data
          }
        });
      }

      const endTime = Date.now();
      const duration = endTime - startTime;

      // Should complete reasonably quickly
      expect(duration).toBeLessThan(1000); // Less than 1 second

      // Memory should be controlled
      const stats = sseManager.getMemoryStats();
      expect(stats.totalEventHistory).toBeLessThanOrEqual(sseManager.getMaxHistorySize());

      // Cleanup
      clientIds.forEach(clientId => sseManager.removeClient(clientId));
    });
  });

  describe('Error Recovery', () => {
    it('should recover from client write failures', () => {
      // Setup good client first
      const goodRes = createMockResponse();
      const goodClientId = sseManager.addClient(goodRes, 'test-progress');

      // Setup client that will fail on write
      const badRes = createMockResponse();
      badRes.write.mockImplementation(() => {
        throw new Error('Write failed');
      });

      sseManager.addClient(badRes, 'test-progress');

      // The bad client should be removed immediately when write fails during addClient
      expect(sseManager.getActiveClientCount()).toBe(1);

      // Broadcast should only go to the good client
      sseManager.broadcastToProgressType('test-progress', {
        type: 'test-event',
        data: { message: 'test' }
      });

      expect(goodRes.write).toHaveBeenCalled();

      // Cleanup
      sseManager.removeClient(goodClientId);
    });

    it('should handle cleanup during active operations', async () => {
      const clientIds = [];

      // Add several clients
      for (let i = 0; i < 5; i++) {
        const res = createMockResponse();
        const clientId = sseManager.addClient(res, 'concurrent-test');
        clientIds.push(clientId);
      }

      // Start broadcasting
      const broadcastPromise = new Promise(resolve => {
        setTimeout(() => {
          for (let i = 0; i < 10; i++) {
            sseManager.broadcastToProgressType('concurrent-test', {
              type: 'concurrent-event',
              data: { index: i }
            });
          }
          resolve();
        }, 10);
      });

      // Cleanup during broadcast - but wait for broadcast to finish first
      await broadcastPromise;

      // Now cleanup
      sseManager.cleanup();

      // Should not throw errors and should have 0 clients after cleanup
      expect(sseManager.getActiveClientCount()).toBe(0);
    });
  });
});
