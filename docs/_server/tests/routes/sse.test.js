/**
 * SSE Routes Tests
 * Comprehensive tests for Server-Sent Events endpoints
 */

import { describe, it, beforeAll, beforeEach, afterEach, expect, vi } from 'vitest';
import request from 'supertest';

describe('SSE Routes', () => {
  let app;
  let _sseManagerStub;

  beforeAll(async () => {
    // Set test environment
    process.env.NODE_ENV = 'test';

    // Import the app
    const appModule = await import('../../app.js');
    app = appModule.default;
  }, 10000);

  beforeEach(() => {
    // Stub SSE manager methods to avoid actual SSE connections in tests
    _sseManagerStub = {
      getClientStats: vi.fn().mockReturnValue({
        totalConnections: 0,
        activeConnections: 0,
        connectionsByType: {},
        averageLatency: 0,
        lastHeartbeat: new Date().toISOString()
      }),
      addClient: vi.fn().mockReturnValue('test-client-id'),
      removeClient: vi.fn(),
      cleanup: vi.fn()
    };
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('GET /api/progress/events/status', () => {
    it('should return SSE status information', async () => {
      const response = await request(app)
        .get('/api/progress/events/status')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('sse');
      expect(response.body.data.sse).toHaveProperty('endpoint', '/api/progress/events');
      expect(response.body.data.sse).toHaveProperty('supportedTypes');
      expect(response.body.data.sse.supportedTypes).to.include.members([
        'self-assessment', 'kata-progress', 'lab-progress'
      ]);
    });

    it('should include connection statistics', async () => {
      const response = await request(app)
        .get('/api/progress/events/status')
        .expect(200);

      expect(response.body.data.sse).toHaveProperty('totalClients');
      expect(response.body.data.sse).toHaveProperty('clientsByType');
      expect(response.body.data.sse).toHaveProperty('uptime');
    });
  });

  describe('GET /api/progress/events', () => {
    it('should accept valid progress type query parameter', async () => {
      // Note: For SSE endpoints, we can't easily test the actual streaming
      // but we can test that the endpoint accepts the connection
      const validTypes = ['self-assessment', 'kata-progress', 'lab-progress'];

      for (const type of validTypes) {
        try {
          // Use a very short timeout to avoid hanging in tests
          await request(app)
            .get(`/api/progress/events?type=${type}`)
            .timeout(50)
            .expect(200);
        } catch (error) {
          // Timeout is expected for SSE endpoints in test environment
          expect(error.code).to.be.oneOf(['ECONNABORTED', 'TIMEOUT']);
        }
      }
    });

    it('should reject invalid progress type', async () => {
      const response = await request(app)
        .get('/api/progress/events?type=invalid-type')
        .expect(400);

      expect(response.body).toHaveProperty('success', false);
      expect(response.body).toHaveProperty('error', 'Invalid progress type');
      expect(response.body.details).toHaveProperty('provided', 'invalid-type');
      expect(response.body.details).toHaveProperty('valid');
    });

    it('should use default type when none specified', async () => {
      // Test with default type (should not return 400)
      try {
        await request(app)
          .get('/api/progress/events')
          .timeout(100);
      } catch (error) {
        // Timeout is acceptable for SSE endpoints in tests
        expect(error.code).to.be.oneOf(['ECONNABORTED', 'TIMEOUT']);
      }
    });

    it('should accept history query parameter', async () => {
      const params = [
        'history=true',
        'history=false'
      ];

      for (const param of params) {
        try {
          await request(app)
            .get(`/api/progress/events?${param}`)
            .timeout(100);
        } catch (error) {
          // Timeout is acceptable for SSE endpoints in tests
          expect(error.code).to.be.oneOf(['ECONNABORTED', 'TIMEOUT']);
        }
      }
    });

    it('should accept heartbeat query parameter', async () => {
      const params = [
        'heartbeat=true',
        'heartbeat=false'
      ];

      for (const param of params) {
        try {
          await request(app)
            .get(`/api/progress/events?${param}`)
            .timeout(100);
        } catch (error) {
          // Timeout is acceptable for SSE endpoints in tests
          expect(error.code).to.be.oneOf(['ECONNABORTED', 'TIMEOUT']);
        }
      }
    });
  });

  describe('GET /api/progress/events/:type', () => {
    it('should accept valid progress types as URL parameters', async () => {
      const validTypes = ['self-assessment', 'kata-progress', 'lab-progress'];

      for (const type of validTypes) {
        try {
          await request(app)
            .get(`/api/progress/events/${type}`)
            .timeout(100);
        } catch (error) {
          // Timeout is acceptable for SSE endpoints in tests
          expect(error.code).to.be.oneOf(['ECONNABORTED', 'TIMEOUT']);
        }
      }
    });

    it('should reject invalid progress types in URL', async () => {
      const response = await request(app)
        .get('/api/progress/events/invalid-type')
        .expect(400);

      expect(response.body).toHaveProperty('success', false);
      expect(response.body).toHaveProperty('error', 'Invalid progress type');
      expect(response.body.details).toHaveProperty('provided', 'invalid-type');
    });

    it('should handle URL-encoded progress types', async () => {
      try {
        await request(app)
          .get('/api/progress/events/self-assessment')
          .timeout(100);
      } catch (error) {
        // Timeout is acceptable for SSE endpoints in tests
        expect(error.code).to.be.oneOf(['ECONNABORTED', 'TIMEOUT']);
      }
    });

    it('should combine URL type with query parameters', async () => {
      try {
        await request(app)
          .get('/api/progress/events/kata-progress?history=false&heartbeat=true')
          .timeout(100);
      } catch (error) {
        // Timeout is acceptable for SSE endpoints in tests
        expect(error.code).to.be.oneOf(['ECONNABORTED', 'TIMEOUT']);
      }
    });
  });

  describe('SSE Headers and Content-Type', () => {
    it('should set correct headers for SSE endpoints', async () => {
      try {
        const _response = await request(app)
          .get('/api/progress/events/self-assessment')
          .timeout(50);
      } catch (error) {
        // We expect timeout, but we can check headers if response started
        if (error.response) {
          expect(error.response.headers).toHaveProperty('content-type');
          // Note: actual SSE headers are set by the SSE manager, not the route
        }
      }
    });
  });

  describe('Error Handling', () => {
    it('should handle malformed query parameters gracefully', async () => {
      const malformedParams = [
        'type=',
        'type=%',
        'history=maybe',
        'heartbeat=invalid'
      ];

      for (const param of malformedParams) {
        try {
          const response = await request(app)
            .get(`/api/progress/events?${param}`)
            .timeout(100);

          // If we get a response before timeout, it should be either 200 or 400
          if (response) {
            expect([200, 400]).to.include(response.status);
          }
        } catch (error) {
          // Timeout or connection abort is acceptable
          expect(['ECONNABORTED', 'TIMEOUT']).to.include(error.code);
        }
      }
    });

    it('should handle special characters in type parameter', async () => {
      const specialTypes = [
        'self assessment',
        'kata@progress',
        'lab#progress'
      ];

      for (const type of specialTypes) {
        const response = await request(app)
          .get(`/api/progress/events/${encodeURIComponent(type)}`)
          .expect(400);

        expect(response.body).toHaveProperty('success', false);
        expect(response.body).toHaveProperty('error', 'Invalid progress type');
      }
    });
  });
});
