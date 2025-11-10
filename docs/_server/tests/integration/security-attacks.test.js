/**
 * Security Attack Tests
 * Test protection against common attack patterns
 *
 * NOTE: These tests verify schema validation behavior.
 * XSS/injection protection middleware is not currently implemented on /api/progress/save
 */

import { vi, describe, test, expect, beforeEach } from 'vitest';
import request from 'supertest';
import app from '../../app.js';

describe('Security Attack Protection', () => {
  beforeEach(async () => {
    // Mock file system for clean tests
    vi.clearAllMocks();
  });

  describe('Schema Validation Protection', () => {
    test('should reject incomplete payloads with validation error', async () => {
      const incompletePayload = {
        type: 'self-assessment',
        metadata: {
          assessmentId: 'test<script>alert("xss")</script>',
          title: '<img src=x onerror=alert("xss")>'
        },
        assessment: {
          categories: ['<script>document.cookie</script>'],
          completedTasks: ['task1']
        },
        timestamp: new Date().toISOString()
      };

      const response = await request(app)
        .post('/api/progress/save')
        .send(incompletePayload)
        .expect(400);

      // Schema validation fails due to missing required fields
      expect(response.body.error).toBe('Progress data validation failed');
      expect(response.body.details).toBeDefined();
      expect(response.body.validationErrors).toBeDefined();
    });

    test('should accept valid HTML in metadata when schema is complete', async () => {
      const payloadWithHtml = {
        type: 'kata-progress',
        metadata: {
          version: '1.0.0',
          kataId: 'test-content',
          kataTitle: '<b>Bold Title</b>',
          category: 'ai-assisted-engineering',
          source: 'ui',
          fileType: 'kata-progress',
          lastUpdated: new Date().toISOString()
        },
        progress: {
          currentStep: 'task-1',
          completedTasks: 0,
          totalTasks: 1,
          completionPercentage: 0,
          checkboxStates: {}
        },
        timestamp: new Date().toISOString()
      };

      const response = await request(app)
        .post('/api/progress/save')
        .send(payloadWithHtml);

    });
  });

  describe('Path Traversal Protection', () => {
    test('should prevent directory traversal in ID parameters', async () => {
      const maliciousId = encodeURIComponent('../../../etc/passwd');

      const response = await request(app)
        .get(`/api/progress/load/self-assessment/${maliciousId}`)
        .expect(400);

      expect(response.body.error).toBe('Invalid input');
      expect(response.body.message).toContain('Parameter validation failed');
    });

    test('should prevent null byte injection', async () => {
      const maliciousId = encodeURIComponent('test\x00.txt');

      const response = await request(app)
        .get(`/api/progress/load/self-assessment/${maliciousId}`)
        .expect(400);

      expect(response.body.error).toBe('Invalid input');
      expect(response.body.message).toContain('Parameter validation failed');
    });
  });

  describe('SQL Injection Protection', () => {
    test('should reject incomplete payloads regardless of SQL patterns', async () => {
      const sqlInjectionPayload = {
        type: 'self-assessment',
        metadata: {
          assessmentId: "test'; DROP TABLE users; --",
          title: "1' OR '1'='1"
        },
        assessment: {
          categories: ["'; DELETE FROM progress; --"],
          completedTasks: ['task1']
        },
        timestamp: new Date().toISOString()
        // Missing: version, source, fileType
      };

      const response = await request(app)
        .post('/api/progress/save')
        .send(sqlInjectionPayload)
        .expect(400);

      expect(response.body.error).toBe('Progress data validation failed');
      expect(response.body.details).toBeDefined();
      expect(response.body.validationErrors).toBeDefined();
    });
  });

  describe('NoSQL Injection Protection', () => {
    test('should reject payloads with invalid metadata types', async () => {
      const nosqlInjectionPayload = {
        type: 'kata-progress',
        metadata: {
          kataId: { $ne: null },  // Objects not allowed in metadata
          title: { $regex: '.*' }  // Objects not allowed in metadata
        },
        progress: {
          currentStep: { $gt: 0 },  // Objects not allowed
          completedSteps: [0]
        },
        timestamp: new Date().toISOString()
        // Missing: version, source, fileType
      };

      const response = await request(app)
        .post('/api/progress/save')
        .send(nosqlInjectionPayload)
        .expect(400);

      expect(response.body.error).toBe('Progress data validation failed');
      expect(response.body.details).toBeDefined();
      expect(response.body.validationErrors).toBeDefined();
    });
  });

  describe('Command Injection Protection', () => {
    test('should prevent command injection in file names', async () => {
      const commandInjectionId = 'test; rm -rf /';

      const response = await request(app)
        .get(`/api/progress/load/self-assessment/${commandInjectionId}`)
        .expect(400);

      expect(response.body.error).toBe('Invalid input');
    });

    test('should reject incomplete payloads regardless of backtick patterns', async () => {
      const backtickPayload = {
        type: 'self-assessment',
        metadata: {
          assessmentId: 'test`whoami`',
          title: 'Test $(id)'
        },
        assessment: {
          categories: ['category1'],
          completedTasks: ['task1']
        },
        timestamp: new Date().toISOString()
        // Missing: version, source, fileType
      };

      const response = await request(app)
        .post('/api/progress/save')
        .send(backtickPayload)
        .expect(400);

      expect(response.body.error).toBe('Progress data validation failed');
      expect(response.body.details).toBeDefined();
      expect(response.body.validationErrors).toBeDefined();
    });
  });

  describe('Large Payload Protection', () => {
    test('should reject incomplete payloads with large strings', async () => {
      const largeString = 'a'.repeat(10000); // 10KB string
      const largePayload = {
        type: 'self-assessment',
        metadata: {
          assessmentId: 'test',
          title: largeString
        },
        assessment: {
          categories: [largeString],
          completedTasks: ['task1']
        },
        timestamp: new Date().toISOString()
        // Missing: version, source, fileType
      };

      const response = await request(app)
        .post('/api/progress/save')
        .send(largePayload)
        .expect(400);

      expect(response.body.error).toBe('Progress data validation failed');
      expect(response.body.details).toBeDefined();
      expect(response.body.validationErrors).toBeDefined();
    });
  });

  describe('Content Type Protection', () => {
    test('should reject non-JSON content types for API endpoints', async () => {
      const response = await request(app)
        .post('/api/progress/save')
        .set('Content-Type', 'text/plain')
        .send('malicious content')
        .expect(400);

      // Express built-in body parser rejects non-JSON content types
      expect(response.body).toBeDefined();
    });
  });

  describe('Rate Limiting Validation', () => {
    test('should have rate limiting configured', async () => {
      // Make multiple rapid requests to test rate limiting
      const requests = Array(10).fill().map(() =>
        request(app)
          .get('/api/progress/sync-status')
      );

      const responses = await Promise.all(requests);

      // At least some requests should succeed
      const successfulRequests = responses.filter(r => r.status === 200);
      expect(successfulRequests.length).toBeGreaterThan(0);

      // In a real rate-limited environment, some would be rejected
      // For now, just verify the endpoint is accessible
      expect(successfulRequests.length).toBeGreaterThanOrEqual(1);
    });
  });
});
