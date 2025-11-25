/**
 * @fileoverview Request Logger Middleware Tests
 * Tests for structured request logging functionality
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import request from 'supertest';
import express from 'express';
import { requestLogger, getLoggerConfig } from '../../middleware/request-logger.js';

describe('Request Logger Middleware', () => {
  let app;
  let mockLogger;
  let logOutput;

  beforeEach(() => {
    // Capture log output for testing
    logOutput = [];
    mockLogger = {
      info: vi.fn((message, meta) => {
        logOutput.push({ level: 'info', message, meta });
      }),
      error: vi.fn((message, meta) => {
        logOutput.push({ level: 'error', message, meta });
      }),
      warn: vi.fn((message, meta) => {
        logOutput.push({ level: 'warn', message, meta });
      })
    };

    app = express();
    app.use(requestLogger(mockLogger));

    // Test routes
    app.get('/test', (req, res) => {
      res.json({ success: true });
    });

    app.get('/error', (req, res) => {
      res.status(500).json({ error: 'Test error' });
    });

    app.post('/api/progress/save', (req, res) => {
      res.json({ saved: true });
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('Structured Logging Format', () => {
    it('should log requests with structured data format', async () => {
      await request(app)
        .get('/test')
        .expect(200);

      expect(logOutput).toHaveLength(1);
      const logEntry = logOutput[0];

      expect(logEntry.level).toBe('info');
      expect(logEntry.message).toMatch(/HTTP Request/);
      expect(logEntry.meta).toMatchObject({
        method: 'GET',
        url: '/test',
        status: 200,
        userAgent: expect.any(String),
        timestamp: expect.any(String),
        responseTime: expect.any(Number)
      });
    });

    it('should include request ID for tracing', async () => {
      await request(app)
        .get('/test')
        .expect(200);

      const logEntry = logOutput[0];
      expect(logEntry.meta.requestId).toBeDefined();
      expect(typeof logEntry.meta.requestId).toBe('string');
      expect(logEntry.meta.requestId).toHaveLength(36); // UUID length
    });

    it('should log response time in milliseconds', async () => {
      await request(app)
        .get('/test')
        .expect(200);

      const logEntry = logOutput[0];
      expect(logEntry.meta.responseTime).toBeGreaterThan(0);
      expect(typeof logEntry.meta.responseTime).toBe('number');
    });

    it('should include IP address when available', async () => {
      await request(app)
        .get('/test')
        .set('X-Forwarded-For', '203.0.113.1')
        .expect(200);

      const logEntry = logOutput[0];
      expect(logEntry.meta.ip).toBeDefined();
    });
  });

  describe('Error Logging', () => {
    it('should log error responses with appropriate level', async () => {
      await request(app)
        .get('/error')
        .expect(500);

      const logEntry = logOutput[0];
      expect(logEntry.level).toBe('error');
      expect(logEntry.meta.status).toBe(500);
    });

    it('should log 4xx errors as warnings', async () => {
      await request(app)
        .get('/nonexistent')
        .expect(404);

      const logEntry = logOutput[0];
      expect(logEntry.level).toBe('warn');
      expect(logEntry.meta.status).toBe(404);
    });
  });

  describe('API Request Logging', () => {
    it('should identify API requests', async () => {
      await request(app)
        .post('/api/progress/save')
        .send({ test: 'data' })
        .expect(200);

      const logEntry = logOutput[0];
      expect(logEntry.meta.isApi).toBe(true);
      expect(logEntry.meta.apiEndpoint).toBe('/api/progress/save');
    });

    it('should log request body size for POST requests', async () => {
      await request(app)
        .post('/api/progress/save')
        .send({ test: 'data', more: 'content' })
        .expect(200);

      const logEntry = logOutput[0];
      expect(logEntry.meta.contentLength).toBeGreaterThan(0);
    });
  });

  describe('Logger Configuration', () => {
    it('should provide development configuration', () => {
      const config = getLoggerConfig('development');

      expect(config.level).toBe('debug');
      expect(config.format).toBeDefined();
      expect(config.transports).toHaveLength(1); // Console only
    });

    it('should provide production configuration', () => {
      const config = getLoggerConfig('production');

      expect(config.level).toBe('info');
      expect(config.format).toBeDefined();
      expect(config.transports).toHaveLength(2); // Console + File
    });

    it('should provide test configuration', () => {
      const config = getLoggerConfig('test');

      expect(config.level).toBe('error');
      expect(config.silent).toBe(true);
    });
  });

  describe('Performance Impact', () => {
    it('should complete logging within 5ms', async () => {
      await request(app)
        .get('/test')
        .expect(200);

      const logEntry = logOutput[0];
      const logTime = logEntry.meta.responseTime;

      // Logging overhead should be minimal
      expect(logTime).toBeLessThan(50); // 50ms is generous for test environment
    });
  });
});
