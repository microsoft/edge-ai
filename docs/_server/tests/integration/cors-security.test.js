/**
 * CORS Security Integration Tests
 * Tests to validate CORS policies block malicious origins and allow legitimate ones
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import supertest from 'supertest';

describe('CORS Security Integration', () => {
  let originalEnv;

  beforeEach(() => {
    originalEnv = { ...process.env };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  describe('Production CORS Security', () => {
    it('should block requests from unauthorized origins', async () => {
      process.env.NODE_ENV = 'production';
      process.env.PRODUCTION_ORIGINS = 'https://authorized.example.com';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: app } = await import('../../app.js');

      const response = await supertest(app)
        .options('/health')
        .set('Origin', 'https://malicious.example.com')
        .set('Access-Control-Request-Method', 'GET');

      // Should not include CORS headers for unauthorized origins
      expect(response.headers['access-control-allow-origin']).toBeUndefined();
    });

    it('should allow requests from authorized origins', async () => {
      process.env.NODE_ENV = 'production';
      process.env.PRODUCTION_ORIGINS = 'https://authorized.example.com,https://trusted.example.com';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: app } = await import('../../app.js');

      const response = await supertest(app)
        .options('/health')
        .set('Origin', 'https://authorized.example.com')
        .set('Access-Control-Request-Method', 'GET');

      expect(response.headers['access-control-allow-origin']).toBe('https://authorized.example.com');
      expect(response.headers['access-control-allow-credentials']).toBe('true');
    });

    it('should not allow wildcard origins with credentials in production', async () => {
      process.env.NODE_ENV = 'production';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: app } = await import('../../app.js');

      const response = await supertest(app)
        .options('/health')
        .set('Origin', 'https://random.example.com')
        .set('Access-Control-Request-Method', 'GET');

      // Should never return * with credentials
      if (response.headers['access-control-allow-credentials'] === 'true') {
        expect(response.headers['access-control-allow-origin']).not.toBe('*');
      }
    });
  });

  describe('Development CORS Security', () => {
    it('should allow local development origins', async () => {
      process.env.NODE_ENV = 'development';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: app } = await import('../../app.js');

      const localOrigins = [
        'http://localhost:8080',
        'http://localhost:3000',
        'http://127.0.0.1:8080'
      ];

      for (const origin of localOrigins) {
        const response = await supertest(app)
          .options('/health')
          .set('Origin', origin)
          .set('Access-Control-Request-Method', 'GET');

        expect(response.headers['access-control-allow-origin']).toBe(origin);
        expect(response.headers['access-control-allow-credentials']).toBe('true');
      }
    });

    it('should block non-local origins in development', async () => {
      process.env.NODE_ENV = 'development';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: app } = await import('../../app.js');

      const response = await supertest(app)
        .options('/health')
        .set('Origin', 'https://malicious.example.com')
        .set('Access-Control-Request-Method', 'GET');

      expect(response.headers['access-control-allow-origin']).toBeUndefined();
    });

    it('should allow Codespaces origins when in Codespaces', async () => {
      process.env.NODE_ENV = 'development';
      process.env.CODESPACES = 'true';
      process.env.CODESPACE_NAME = 'test-codespace';
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: app } = await import('../../app.js');

      const codespaceOrigin = 'https://test-codespace-8080.app.github.dev';
      const response = await supertest(app)
        .options('/health')
        .set('Origin', codespaceOrigin)
        .set('Access-Control-Request-Method', 'GET');

      expect(response.headers['access-control-allow-origin']).toBe(codespaceOrigin);
      expect(response.headers['access-control-allow-credentials']).toBe('true');
    });

    it('should allow Gitpod origins when in Gitpod', async () => {
      process.env.NODE_ENV = 'development';
      process.env.GITPOD_WORKSPACE_ID = 'test-workspace-123';
      process.env.GITPOD_WORKSPACE_URL = 'https://test-workspace-123.ws-eu45.gitpod.io';
      delete process.env.CODESPACES;

      const { default: app } = await import('../../app.js');

      const gitpodOrigin = 'https://8080-test-workspace-123.ws-eu45.gitpod.io';
      const response = await supertest(app)
        .options('/health')
        .set('Origin', gitpodOrigin)
        .set('Access-Control-Request-Method', 'GET');

      expect(response.headers['access-control-allow-origin']).toBe(gitpodOrigin);
      expect(response.headers['access-control-allow-credentials']).toBe('true');
    });
  });

  describe('Test Environment CORS Security', () => {
    it('should use restricted test origins without credentials', async () => {
      process.env.NODE_ENV = 'test';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: app } = await import('../../app.js');

      const response = await supertest(app)
        .options('/health')
        .set('Origin', 'http://localhost:8080')
        .set('Access-Control-Request-Method', 'GET');

      expect(response.headers['access-control-allow-origin']).toBe('http://localhost:8080');
      // When credentials are disabled, the header should not be present
      expect(response.headers['access-control-allow-credentials']).toBeUndefined();
    });

    it('should block unauthorized origins in test environment', async () => {
      process.env.NODE_ENV = 'test';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: app } = await import('../../app.js');

      const response = await supertest(app)
        .options('/health')
        .set('Origin', 'https://malicious.example.com')
        .set('Access-Control-Request-Method', 'GET');

      expect(response.headers['access-control-allow-origin']).toBeUndefined();
    });

    it('should never use wildcard with credentials in any environment', async () => {
      const environments = ['production', 'development', 'test'];

      for (const env of environments) {
        process.env.NODE_ENV = env;
        delete process.env.CODESPACES;
        delete process.env.GITPOD_WORKSPACE_ID;

        const { default: app } = await import('../../app.js');

        const response = await supertest(app)
          .options('/health')
          .set('Origin', 'http://localhost:8080')
          .set('Access-Control-Request-Method', 'GET');

        // Critical security check: never wildcard + credentials
        if (response.headers['access-control-allow-credentials'] === 'true') {
          expect(response.headers['access-control-allow-origin']).not.toBe('*');
        }
      }
    });
  });

  describe('CORS Headers Validation', () => {
    it('should include required CORS headers for valid requests', async () => {
      process.env.NODE_ENV = 'development';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: app } = await import('../../app.js');

      const response = await supertest(app)
        .options('/health')
        .set('Origin', 'http://localhost:8080')
        .set('Access-Control-Request-Method', 'GET')
        .set('Access-Control-Request-Headers', 'Content-Type,Authorization');

      expect(response.headers['access-control-allow-origin']).toBe('http://localhost:8080');
      expect(response.headers['access-control-allow-methods']).toContain('GET');
      expect(response.headers['access-control-allow-methods']).toContain('POST');
      expect(response.headers['access-control-allow-methods']).toContain('OPTIONS');
      expect(response.headers['access-control-allow-headers']).toContain('Content-Type');
      expect(response.headers['access-control-allow-headers']).toContain('Authorization');
      expect(response.headers['access-control-max-age']).toBeDefined();
    });

    it('should handle actual CORS requests properly', async () => {
      process.env.NODE_ENV = 'development';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: app } = await import('../../app.js');

      const response = await supertest(app)
        .get('/health')
        .set('Origin', 'http://localhost:8080');

      expect(response.headers['access-control-allow-origin']).toBe('http://localhost:8080');
      expect(response.headers['access-control-allow-credentials']).toBe('true');
    });
  });
});
