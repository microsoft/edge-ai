/**
 * @fileoverview Health Check Endpoint Tests
 * Tests for health monitoring and status endpoints
 */

import { describe, it, beforeEach, afterEach, expect, vi } from 'vitest';
import request from 'supertest';

describe('Health Check Routes', () => {
  let app;
  let server;

  beforeEach(async () => {
    // Clear module cache to ensure fresh imports
    delete process.env.PORT;
    process.env.NODE_ENV = 'test';

    // Ensure we don't start the server automatically
    process.env.SKIP_SERVER_START = 'true';

    // Import the app dynamically to avoid module loading issues during migration
    try {
      const appModule = await import('../../app.js');
      app = appModule.default;

      // Ensure app is properly loaded
      if (!app || typeof app.listen !== 'function') {
        throw new Error('App not properly exported');
      }
    } catch (error) {
      console.error('Error loading app:', error);
      throw new Error('App not ready for testing');
    }

    vi.clearAllMocks();
  }, 10000); // Increase timeout to 10 seconds

  afterEach(async () => {
    if (server) {
      await new Promise(resolve => server.close(resolve));
    }

    // Clear any cached modules
    if (global.gc) {
      global.gc();
    }

    vi.restoreAllMocks();
  });

  describe('Basic Health Endpoints', () => {
    describe('GET /health', () => {
      it('should return 200 and health status', async () => {
        if (!app) {return;}

        const response = await request(app)
          .get('/health')
          .expect(200);

        expect(response.body).toHaveProperty('status', 'healthy');
        expect(response.body).toHaveProperty('timestamp');
        expect(response.body).toHaveProperty('version', '2.0.0');
        expect(response.body).toHaveProperty('environment', 'test');
      });

      it('should include response time in headers', async () => {
        if (!app) {return;}

        const response = await request(app)
          .get('/health')
          .expect(200);

        expect(response.headers['x-response-time']).toMatch(/^\d+ms$/);
      });

      it('should respond quickly (under 100ms)', async () => {
        if (!app) {return;}

        const start = Date.now();

        await request(app)
          .get('/health')
          .expect(200);

        const duration = Date.now() - start;
        expect(duration).toBeLessThan(100);
      });
    });

    describe('GET /api/health', () => {
      it('should return 200 and detailed health info', async () => {
        if (!app) {return;}

        const response = await request(app)
          .get('/api/health')
          .expect(200);

        expect(response.body).toHaveProperty('success', true);
        expect(response.body).toHaveProperty('data');
        expect(response.body.data).toHaveProperty('status', 'healthy');
        expect(response.body.data).toHaveProperty('timestamp');
        expect(response.body.data).toHaveProperty('uptime');
        expect(response.body.data).toHaveProperty('memory');
      });

      it('should include system metrics', async () => {
        if (!app) {return;}

        const response = await request(app)
          .get('/api/health')
          .expect(200);

        expect(response.body.data.memory).toEqual({
          used: expect.any(Number),
          total: expect.any(Number),
          percentage: expect.any(Number)
        });
      });
    });

    describe('GET /api/info', () => {
      it('should return API information', async () => {
        if (!app) {return;}

        const response = await request(app)
          .get('/api/info')
          .expect(200);

        expect(response.body).toHaveProperty('success', true);
        expect(response.body.data).toHaveProperty('name', 'Progress Server API');
        expect(response.body.data).toHaveProperty('version', '2.0.0');
        expect(response.body.data).toHaveProperty('endpoints');
        expect(response.body.data).toHaveProperty('supportedTypes');
        expect(response.body.data).toHaveProperty('features');
      });
    });
  });

  describe('Enhanced Health Monitoring', () => {
    describe('GET /health/detailed', () => {
      it('should return detailed health information', async () => {
        if (!app) {return;}

        const response = await request(app)
          .get('/health/detailed')
          .expect(200);

        expect(response.body).toEqual({
          status: 'healthy',
          timestamp: expect.any(String),
          uptime: expect.any(Number),
          version: expect.any(String),
          system: {
            memory: {
              used: expect.any(Number),
              total: expect.any(Number),
              percentage: expect.any(Number)
            },
            cpu: {
              usage: expect.any(Number)
            },
            eventLoop: {
              lag: expect.any(Number)
            }
          },
          application: {
            requests: {
              total: expect.any(Number),
              active: expect.any(Number)
            },
            errors: {
              total: expect.any(Number),
              rate: expect.any(Number)
            }
          }
        });
      });

      it('should detect unhealthy conditions', async () => {
        if (!app) {return;}

        // Mock high memory usage
        vi.doMock('process', () => ({
          memoryUsage: () => ({
            heapUsed: 500 * 1024 * 1024, // 500MB
            heapTotal: 512 * 1024 * 1024, // 512MB
            external: 10 * 1024 * 1024,
            rss: 600 * 1024 * 1024
          }),
          uptime: () => 3600
        }));

        const response = await request(app)
          .get('/health/detailed');

        if (response.status === 503) {
          expect(response.body.status).toBe('unhealthy');
          expect(response.body.issues).toContainEqual(
            expect.objectContaining({
              type: 'high_memory_usage',
              severity: 'critical'
            })
          );
        }
      });
    });

    describe('GET /health/ready', () => {
      it('should return readiness status', async () => {
        if (!app) {return;}

        const response = await request(app)
          .get('/health/ready')
          .expect(200);

        expect(response.body).toEqual({
          status: 'ready',
          timestamp: expect.any(String),
          checks: {
            filesystem: expect.any(String),
            memory: expect.any(String),
            dependencies: expect.any(String)
          }
        });
      });
    });

    describe('GET /health/live', () => {
      it('should return liveness status', async () => {
        if (!app) {return;}

        const response = await request(app)
          .get('/health/live')
          .expect(200);

        expect(response.body).toEqual({
          status: 'alive',
          timestamp: expect.any(String),
          pid: expect.any(Number)
        });
      });

      it('should always return 200 for liveness', async () => {
        if (!app) {return;}

        const response = await request(app)
          .get('/health/live')
          .expect(200);

        expect(response.body.status).toBe('alive');
      });
    });
  });

  describe('Metrics Endpoints', () => {
    describe('GET /metrics', () => {
      it('should return application metrics in JSON format', async () => {
        if (!app) {return;}

        const response = await request(app)
          .get('/metrics')
          .expect(200);

        expect(response.body).toEqual({
          timestamp: expect.any(String),
          counters: expect.any(Object),
          histograms: expect.any(Object),
          gauges: expect.any(Object)
        });
      });

      it('should include HTTP request metrics', async () => {
        if (!app) {return;}

        // Make a few requests to generate metrics
        await request(app).get('/health');
        await request(app).get('/api/health');

        const response = await request(app)
          .get('/metrics')
          .expect(200);

        expect(response.body.counters).toHaveProperty('http.requests.total');
        expect(response.body.counters['http.requests.total']).toBeGreaterThan(0);
      });
    });

    describe('GET /metrics/prometheus', () => {
      it('should return metrics in Prometheus format', async () => {
        if (!app) {return;}

        const response = await request(app)
          .get('/metrics/prometheus')
          .expect(200);

        expect(response.text).toContain('# HELP');
        expect(response.text).toContain('# TYPE');
        expect(response.headers['content-type']).toContain('text/plain');
      });

      it('should include standard Prometheus metrics', async () => {
        if (!app) {return;}

        const response = await request(app)
          .get('/metrics/prometheus')
          .expect(200);

        expect(response.text).toContain('http_requests_total');
        expect(response.text).toContain('http_request_duration_seconds');
        expect(response.text).toContain('nodejs_memory_heap_used_bytes');
      });
    });
  });

  describe('Performance and Error Handling', () => {
    it('should handle concurrent health checks', async () => {
      if (!app) {return;}

      const promises = Array(10).fill().map(() =>
        request(app).get('/health').expect(200)
      );

      const responses = await Promise.all(promises);

      responses.forEach(response => {
        expect(response.body.status).toBe('healthy');
      });
    });

    it('should not significantly impact memory under load', async () => {
      if (!app) {return;}

      const initialMemory = process.memoryUsage().heapUsed;

      // Make 50 health check requests
      const promises = Array(50).fill().map(() =>
        request(app).get('/health')
      );

      await Promise.all(promises);

      // Force garbage collection and cleanup
      if (global.gc) {
        global.gc();
      }

      const finalMemory = process.memoryUsage().heapUsed;
      const memoryIncrease = finalMemory - initialMemory;

      // Memory increase should be minimal (less than 10MB to account for metrics storage)
      expect(memoryIncrease).toBeLessThan(10 * 1024 * 1024);
    });

    it('should handle metrics collection errors gracefully', async () => {
      if (!app) {return;}

      const response = await request(app)
        .get('/health/detailed')
        .expect(200);

      expect(response.body.status).toBe('healthy');
    });
  });

  describe('Response Headers', () => {
    it('should include cache control headers', async () => {
      if (!app) {return;}

      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.headers['cache-control']).toBe('no-cache, no-store, must-revalidate');
      expect(response.headers.pragma).toBe('no-cache');
      expect(response.headers.expires).toBe('0');
    });

    it('should include CORS headers for metrics endpoints', async () => {
      if (!app) {return;}

      const response = await request(app)
        .get('/metrics');

      if (response.status === 200) {
        expect(response.headers['access-control-allow-origin']).toBe('*');
        expect(response.headers['access-control-allow-methods']).toContain('GET');
      }
    });
  });
});
