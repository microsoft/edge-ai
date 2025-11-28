/**
 * Security Middleware Tests
 * Test helmet CSP configuration across different environments
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import supertest from 'supertest';
import express from 'express';

// Test app factory to test different security configurations
const createTestApp = (securityMiddleware) => {
  const app = express();
  app.use(securityMiddleware);

  app.get('/test', (req, res) => {
    res.json({ message: 'test endpoint' });
  });

  return app;
};

describe('Security Middleware', () => {
  let originalEnv;

  beforeEach(() => {
    // Save original environment
    originalEnv = { ...process.env };
    // Clear the module cache to get fresh environment detection
    vi.resetModules();
  });

  afterEach(() => {
    // Restore original environment
    process.env = originalEnv;
  });

  describe('CSP Configuration', () => {
    it('should use strict CSP in production environment', async () => {
      // Set production environment
      process.env.NODE_ENV = 'production';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      // Import security module after setting environment
      const { default: createSecurityMiddleware } = await import('../../middleware/security.js');
      const securityMiddleware = createSecurityMiddleware();

      const app = createTestApp(securityMiddleware);
      const response = await supertest(app).get('/test');

      // Should have strict CSP headers
      expect(response.headers).toHaveProperty('content-security-policy');
      const csp = response.headers['content-security-policy'];

      // Production should be strict
      expect(csp).toContain("default-src 'self'");
      expect(csp).toContain("script-src 'self'");
      expect(csp).toContain("connect-src 'self'");
      expect(csp).not.toContain("'unsafe-inline'");
      expect(csp).not.toContain("'unsafe-eval'");
      expect(csp).not.toContain("http://localhost:");
    });

    it('should use development-friendly CSP in development environment', async () => {
      // Set development environment
      process.env.NODE_ENV = 'development';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const { default: createSecurityMiddleware } = await import('../../middleware/security.js');
      const securityMiddleware = createSecurityMiddleware();

      const app = createTestApp(securityMiddleware);
      const response = await supertest(app).get('/test');

      const csp = response.headers['content-security-policy'];

      // Development should allow dev tools
      expect(csp).toContain("'unsafe-inline'");
      expect(csp).toContain("http://localhost:*");
      expect(csp).toContain("ws://localhost:*");
      expect(csp).not.toContain("'unsafe-eval'"); // Should still not allow eval in development
    });

    it('should detect DevContainer environment and adjust CSP accordingly', async () => {
      // Set Codespaces environment
      process.env.NODE_ENV = 'development';
      process.env.CODESPACES = 'true';

      const { default: createSecurityMiddleware } = await import('../../middleware/security.js');
      const securityMiddleware = createSecurityMiddleware();

      const app = createTestApp(securityMiddleware);
      const response = await supertest(app).get('/test');

      const csp = response.headers['content-security-policy'];

      // Should include Codespaces origins
      expect(csp).toContain("https://*.github.dev");
      expect(csp).toContain("https://*.githubusercontent.com");
      expect(csp).toContain("wss://*.github.dev");
    });

    it('should detect Gitpod environment and adjust CSP accordingly', async () => {
      // Set Gitpod environment
      process.env.NODE_ENV = 'development';
      process.env.GITPOD_WORKSPACE_ID = 'test-workspace-123';

      const { default: createSecurityMiddleware } = await import('../../middleware/security.js');
      const securityMiddleware = createSecurityMiddleware();

      const app = createTestApp(securityMiddleware);
      const response = await supertest(app).get('/test');

      const csp = response.headers['content-security-policy'];

      // Should include Gitpod origins
      expect(csp).toContain("https://*.gitpod.io");
      expect(csp).toContain("wss://*.gitpod.io");
    });

    it('should use test-friendly CSP in test environment', async () => {
      // Set test environment
      process.env.NODE_ENV = 'test';

      const { default: createSecurityMiddleware } = await import('../../middleware/security.js');
      const securityMiddleware = createSecurityMiddleware();

      const app = createTestApp(securityMiddleware);
      const response = await supertest(app).get('/test');

      const csp = response.headers['content-security-policy'];

      // Test environment should be permissive
      expect(csp).toContain("'unsafe-inline'");
      expect(csp).toContain("'unsafe-eval'");
      expect(csp).toContain("http://localhost:*");
    });

    it('should include all required CSP directives', async () => {
      process.env.NODE_ENV = 'production';

      const { default: createSecurityMiddleware } = await import('../../middleware/security.js');
      const securityMiddleware = createSecurityMiddleware();

      const app = createTestApp(securityMiddleware);
      const response = await supertest(app).get('/test');

      const csp = response.headers['content-security-policy'];

      // Check for required directives
      expect(csp).toContain("default-src");
      expect(csp).toContain("script-src");
      expect(csp).toContain("style-src");
      expect(csp).toContain("img-src");
      expect(csp).toContain("connect-src");
      expect(csp).toContain("font-src");
      expect(csp).toContain("object-src");
      expect(csp).toContain("base-uri");
      expect(csp).toContain("form-action");
      expect(csp).toContain("frame-ancestors");
    });
  });

  describe('Environment Detection', () => {
    it('should correctly detect DevContainer environment', async () => {
      process.env.CODESPACES = 'true';

      const { detectEnvironment } = await import('../../middleware/security.js');
      const env = detectEnvironment();

      expect(env.isCodespaces).toBe(true);
      expect(env.isDevContainer).toBe(true);
    });

    it('should correctly detect Gitpod environment', async () => {
      process.env.GITPOD_WORKSPACE_ID = 'test-workspace-456';

      const { detectEnvironment } = await import('../../middleware/security.js');
      const env = detectEnvironment();

      expect(env.isGitpod).toBe(true);
      expect(env.isDevContainer).toBe(true);
    });

    it('should correctly detect local development', async () => {
      process.env.NODE_ENV = 'development';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const { detectEnvironment } = await import('../../middleware/security.js');
      const env = detectEnvironment();

      expect(env.isDevelopment).toBe(true);
      expect(env.isDevContainer).toBe(false);
      expect(env.isCodespaces).toBe(false);
      expect(env.isGitpod).toBe(false);
    });
  });
});
