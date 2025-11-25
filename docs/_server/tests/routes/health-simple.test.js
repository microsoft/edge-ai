/**
 * @fileoverview Simple Health Check Endpoint Tests
 * Tests for health monitoring with minimal app setup
 */

import { describe, it, expect } from 'vitest';
import request from 'supertest';
import express from 'express';

// Create a minimal app just for health checks
function createTestApp() {
  const app = express();

  // Add response time header middleware
  app.use((req, res, next) => {
    const start = Date.now();

    const originalSend = res.send;
    res.send = function(data) {
      const duration = Date.now() - start;
      if (!res.headersSent) {
        res.set('x-response-time', `${duration}ms`);
      }
      return originalSend.call(this, data);
    };

    next();
  });

  // Basic health endpoint
  app.get('/health', (req, res) => {
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: '2.0.0',
      environment: process.env.NODE_ENV || 'test'
    });
  });

  // Detailed health endpoint
  app.get('/api/health', (req, res) => {
    const memUsage = process.memoryUsage();
    const totalMem = memUsage.heapTotal;
    const usedMem = memUsage.heapUsed;

    res.json({
      success: true,
      data: {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: {
          used: Math.round(usedMem / 1024 / 1024),
          total: Math.round(totalMem / 1024 / 1024),
          percentage: Math.round((usedMem / totalMem) * 100)
        }
      }
    });
  });

  return app;
}

describe('Simple Health Check Routes', () => {
  const app = createTestApp();

  describe('GET /health', () => {
    it('should return 200 and health status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('version', '2.0.0');
      expect(response.body).toHaveProperty('environment', 'test');
    });

    it('should respond quickly (under 100ms)', async () => {
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
});
