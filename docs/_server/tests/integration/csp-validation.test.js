/**
 * CSP Validation Integration Tests
 * Test CSP policies work correctly in browser-like scenarios
 */

import { describe, it, expect, beforeAll, afterAll, beforeEach, vi } from 'vitest';
import supertest from 'supertest';

describe('CSP Validation Integration', () => {
  let originalEnv;

  beforeAll(() => {
    // Save original environment
    originalEnv = { ...process.env };
  });

  afterAll(() => {
    // Restore original environment
    process.env = originalEnv;
  });

  beforeEach(() => {
    // Reset environment for each test
    process.env = { ...originalEnv };
    // Clear module cache to get fresh imports
    vi.resetModules();
  });

  describe('Production CSP Validation', () => {
    it('should block inline scripts in production', async () => {
      process.env.NODE_ENV = 'production';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      // Import fresh app instance after setting environment
      const { default: app } = await import('../../app.js');

      const response = await supertest(app)
        .get('/health')
        .expect(200);

      const csp = response.headers['content-security-policy'];

      // Production should NOT allow unsafe-inline for scripts
      expect(csp).toContain("script-src 'self'");
      expect(csp).not.toContain("script-src 'self' 'unsafe-inline'");
    });

    it('should block external script sources in production', async () => {
      process.env.NODE_ENV = 'production';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: app } = await import('../../app.js');

      const response = await supertest(app)
        .get('/health')
        .expect(200);

      const csp = response.headers['content-security-policy'];

      // Should not allow external scripts
      expect(csp).not.toContain('https://*');
      expect(csp).not.toContain('http://localhost:*');
    });

    it('should restrict connect-src in production', async () => {
      process.env.NODE_ENV = 'production';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: app } = await import('../../app.js');

      const response = await supertest(app)
        .get('/health')
        .expect(200);

      const csp = response.headers['content-security-policy'];

      // Should only allow self connections in production
      expect(csp).toContain("connect-src 'self'");
      expect(csp).not.toContain('http://localhost:*');
      expect(csp).not.toContain('ws://localhost:*');
    });
  });

  describe('Development CSP Validation', () => {
    it('should allow development tools in development', async () => {
      process.env.NODE_ENV = 'development';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: app } = await import('../../app.js');

      const response = await supertest(app)
        .get('/health')
        .expect(200);

      const csp = response.headers['content-security-policy'];

      // Development should allow unsafe-inline for hot reload
      expect(csp).toContain("'unsafe-inline'");

      // Should allow localhost connections for dev tools
      expect(csp).toContain('http://localhost:*');
      expect(csp).toContain('ws://localhost:*');
    });

    it('should maintain basic security in development', async () => {
      process.env.NODE_ENV = 'development';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: app } = await import('../../app.js');

      const response = await supertest(app)
        .get('/health')
        .expect(200);

      const csp = response.headers['content-security-policy'];

      // Should still have default-src 'self'
      expect(csp).toContain("default-src 'self'");

      // Should still restrict object-src
      expect(csp).toContain("object-src 'none'");
    });
  });

  describe('DevContainer CSP Validation', () => {
    it('should allow Codespaces-specific origins', async () => {
      process.env.NODE_ENV = 'development';
      process.env.CODESPACES = 'true';
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: app } = await import('../../app.js');

      const response = await supertest(app)
        .get('/health')
        .expect(200);

      const csp = response.headers['content-security-policy'];

      // Should allow Codespaces origins
      expect(csp).toContain('https://*.github.dev');
      expect(csp).toContain('https://*.githubusercontent.com');
      expect(csp).toContain('wss://*.github.dev');
    });

    it('should allow Gitpod-specific origins', async () => {
      process.env.NODE_ENV = 'development';
      process.env.GITPOD_WORKSPACE_ID = 'test-workspace-123';
      delete process.env.CODESPACES;

      const { default: app } = await import('../../app.js');

      const response = await supertest(app)
        .get('/health')
        .expect(200);

      const csp = response.headers['content-security-policy'];

      // Should allow Gitpod origins
      expect(csp).toContain('https://*.gitpod.io');
      expect(csp).toContain('wss://*.gitpod.io');
    });
  });

  describe('Test Environment CSP', () => {
    it('should be permissive for testing frameworks', async () => {
      process.env.NODE_ENV = 'test';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: app } = await import('../../app.js');

      const response = await supertest(app)
        .get('/health')
        .expect(200);

      const csp = response.headers['content-security-policy'];

      // Should allow testing frameworks
      expect(csp).toContain("'unsafe-eval'");
      expect(csp).toContain("'unsafe-inline'");
      expect(csp).toContain('data:');
    });
  });

  describe('SSE Compatibility', () => {
    it('should allow SSE connections in all environments', async () => {
      const environments = ['production', 'development', 'test'];

      for (const env of environments) {
        process.env.NODE_ENV = env;
        delete process.env.CODESPACES;
        delete process.env.GITPOD_WORKSPACE_ID;

        const { default: app } = await import('../../app.js');

        const response = await supertest(app)
          .get('/health')
          .expect(200);

        const csp = response.headers['content-security-policy'];

        // Should allow SSE connections
        expect(csp).toContain("connect-src 'self'");
      }
    });
  });
});
