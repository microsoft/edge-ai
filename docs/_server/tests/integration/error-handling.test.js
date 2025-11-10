import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

describe('Error Handling Integration Tests', () => {
  let app;
  let testProgressDir;

  beforeAll(async () => {
    // Set up test environment BEFORE any imports
    process.env.NODE_ENV = 'test';
    process.env.SKIP_FILE_WATCHER = 'true';

    // Set up test progress directory
    testProgressDir = path.join(__dirname, '../../test-progress-error');
    process.env.PROGRESS_DIR = testProgressDir;

    try {
      await fs.mkdir(testProgressDir, { recursive: true });
    } catch {
      // Directory might already exist
    }

    // Import the app
    const appModule = await import('../../app.js');
    app = appModule.default;
  }, 30000);

  afterAll(async () => {
    // Clean up test directory
    try {
      await fs.rm(testProgressDir, { recursive: true, force: true });
    } catch {
      // Directory might not exist
    }
  });
  describe('Route Error Handling', () => {
    it('should return 404 for non-existent routes', async () => {
      const response = await request(app)
        .get('/api/non-existent-endpoint')
        .expect(404);

      expect(response.body).toHaveProperty('error');
    });

    it('should handle missing required fields in progress endpoint', async () => {
      const response = await request(app)
        .post('/api/progress/save')
        .send({}) // Missing required fields
        .expect(400); // Validation error due to missing required fields

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Progress data validation failed');
    });

    it('should handle invalid data types in progress endpoint', async () => {
      const response = await request(app)
        .post('/api/progress/save')
        .send({
          assessmentId: 123, // Should be string
          taskId: null, // Should be string
          categories: 'invalid' // Should be array
        })
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Progress data validation failed');
    });
  });

  describe('Middleware Error Handling', () => {
    it('should handle CORS preflight requests gracefully', async () => {
      const response = await request(app)
        .options('/api/progress/save')
        .set('Origin', 'http://test-site.com')
        .expect(204); // CORS preflight returns 204

      expect(response.headers).toHaveProperty('access-control-allow-origin');
    });
  });

  describe('Server Error Handling', () => {
    it('should handle health endpoint correctly', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body).toHaveProperty('status');
      expect(response.body.status).toBe('healthy');
    });

    it('should not expose sensitive information in errors', async () => {
      const response = await request(app)
        .post('/api/progress/save')
        .send({ invalid: 'data' })
        .expect(400);

      expect(response.body.error).not.toContain('stack');
      expect(response.body.error).not.toContain('password');
      expect(response.body.error).not.toContain('secret');
    });
  });

  describe('Error Recovery', () => {
    it('should continue serving after errors', async () => {
      // Trigger an error
      await request(app)
        .post('/api/progress/save')
        .send({ invalid: 'data' })
        .expect(400);

      // Verify server still responds to valid requests
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body.status).toBe('healthy');
    });

    it('should handle concurrent error scenarios', async () => {
      // Trigger multiple errors concurrently
      const errorRequests = Array(3).fill(null).map(() =>
        request(app)
          .post('/api/progress/save')
          .send({ invalid: 'data' })
          .expect(400)
      );

      await Promise.all(errorRequests);

      // Verify server still responds to valid requests
      const healthResponse = await request(app)
        .get('/health')
        .expect(200);

      expect(healthResponse.body.status).toBe('healthy');
    });
  });
});
