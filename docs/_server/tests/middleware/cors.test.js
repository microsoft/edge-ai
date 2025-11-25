/**
 * CORS Middleware Tests
 * Tests for environment-aware CORS configuration
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { createCorsConfig } from '../../middleware/cors-config.js';

describe('CORS Configuration', () => {
  let originalEnv;

  beforeEach(() => {
    originalEnv = { ...process.env };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  describe('Production Environment', () => {
    it('should use strict origins in production', () => {
      process.env.NODE_ENV = 'production';
      process.env.PRODUCTION_ORIGINS = 'https://prod1.example.com,https://prod2.example.com';

      const corsConfig = createCorsConfig();

      expect(typeof corsConfig.origin).toBe('function');
      expect(corsConfig.credentials).toBe(true);

      // Test the origin function
      const testCallback = (err, allowed) => {
        expect(err).toBeNull();
        expect(allowed).toBe('https://prod1.example.com'); // Should echo back the specific origin
      };

      corsConfig.origin('https://prod1.example.com', testCallback);
    });

    it('should fallback to default production origins if env var not set', () => {
      process.env.NODE_ENV = 'production';
      delete process.env.PRODUCTION_ORIGINS;

      const corsConfig = createCorsConfig();

      expect(typeof corsConfig.origin).toBe('function');
      expect(corsConfig.credentials).toBe(true);

      // Test default origin
      const testCallback = (err, allowed) => {
        expect(err).toBeNull();
        expect(allowed).toBe('https://your-production-domain.com'); // Should echo back the specific origin
      };

      corsConfig.origin('https://your-production-domain.com', testCallback);
    });

    it('should not allow wildcard origins with credentials in production', () => {
      process.env.NODE_ENV = 'production';

      const corsConfig = createCorsConfig();

      expect(typeof corsConfig.origin).toBe('function');
      expect(corsConfig.credentials).toBe(true);

      // Test unauthorized origin
      const testCallback = (err, _allowed) => {
        expect(err).toBeInstanceOf(Error);
        expect(err.message).toBe('Not allowed by CORS');
      };

      corsConfig.origin('https://malicious.example.com', testCallback);
    });
  });

  describe('Development Environment', () => {
    it('should allow permissive origins in development', () => {
      process.env.NODE_ENV = 'development';

      const corsConfig = createCorsConfig();

      expect(typeof corsConfig.origin).toBe('function');
      expect(corsConfig.credentials).toBe(true);

      // Test development origins
      const testCallback = (err, allowed) => {
        expect(err).toBeNull();
        expect(allowed).toBe('http://localhost:8080'); // Should echo back the specific origin
      };

      corsConfig.origin('http://localhost:8080', testCallback);
    });

    it('should allow DevContainer/Codespaces/Gitpod origins', () => {
      process.env.NODE_ENV = 'development';

      const corsConfig = createCorsConfig();

      // Test GitHub Codespaces origin (matches *.github.dev pattern)
      const testDevCallback = (err, allowed) => {
        expect(err).toBeNull();
        expect(allowed).toBe('https://abc123-8080.app.github.dev'); // Should echo back the specific origin
      };

      corsConfig.origin('https://abc123-8080.app.github.dev', testDevCallback);

      // Test Gitpod origin (matches *.gitpod.io pattern)
      const testGitpodCallback = (err, allowed) => {
        expect(err).toBeNull();
        expect(allowed).toBe('https://8080-workspace-abc123.ws-us50.gitpod.io'); // Should echo back the specific origin
      };

      corsConfig.origin('https://8080-workspace-abc123.ws-us50.gitpod.io', testGitpodCallback);
    });

    it('should reject unauthorized origins even in development', () => {
      process.env.NODE_ENV = 'development';

      const corsConfig = createCorsConfig();

      const testCallback = (err, _allowed) => {
        expect(err).toBeInstanceOf(Error);
        expect(err.message).toBe('Not allowed by CORS');
      };

      corsConfig.origin('https://malicious-external.com', testCallback);
    });
  });

  describe('Test Environment', () => {
    it('should use restricted test origins instead of wildcard', () => {
      process.env.NODE_ENV = 'test';

      const corsConfig = createCorsConfig();

      // Should NOT use wildcard with credentials
      expect(corsConfig.origin).not.toBe('*');
      expect(typeof corsConfig.origin).toBe('function');
      expect(corsConfig.credentials).toBe(false); // Test environment should disable credentials

      // Test allowed origins
      const testCallback8080 = (err, allowed) => {
        expect(err).toBeNull();
        expect(allowed).toBe('http://localhost:8080'); // Should echo back the specific origin
      };

      const testCallback3000 = (err, allowed) => {
        expect(err).toBeNull();
        expect(allowed).toBe('http://localhost:3000'); // Should echo back the specific origin
      };

      corsConfig.origin('http://localhost:8080', testCallback8080);
      corsConfig.origin('http://localhost:3000', testCallback3000);
    });

    it('should disable credentials in test environment', () => {
      process.env.NODE_ENV = 'test';

      const corsConfig = createCorsConfig();

      expect(corsConfig.credentials).toBe(false); // Credentials should be disabled in test
      expect(typeof corsConfig.origin).toBe('function');

      // Test unauthorized origin rejection
      const testCallback = (err, _allowed) => {
        expect(err).toBeInstanceOf(Error);
        expect(err.message).toBe('Not allowed by CORS');
      };

      corsConfig.origin('https://unauthorized.example.com', testCallback);
    });
  });

  describe('Security Validation', () => {
    it('should never allow wildcard origin with credentials enabled', () => {
      const environments = ['production', 'development', 'test'];

      environments.forEach(env => {
        process.env.NODE_ENV = env;
        const corsConfig = createCorsConfig();

        if (corsConfig.credentials === true) {
          expect(corsConfig.origin).not.toBe('*');
        }
      });
    });

    it('should include required CORS headers', () => {
      process.env.NODE_ENV = 'development';

      const corsConfig = createCorsConfig();

      expect(corsConfig.methods).toContain('GET');
      expect(corsConfig.methods).toContain('POST');
      expect(corsConfig.methods).toContain('OPTIONS');
      expect(corsConfig.allowedHeaders).toContain('Content-Type');
      expect(corsConfig.allowedHeaders).toContain('Authorization');
    });

    it('should have reasonable preflight cache duration', () => {
      process.env.NODE_ENV = 'production';

      const corsConfig = createCorsConfig();

      expect(corsConfig.maxAge).toBeGreaterThan(0);
      expect(corsConfig.maxAge).toBeLessThanOrEqual(86400); // Max 24 hours
    });
  });

  describe('Environment Detection', () => {
    it('should correctly detect DevContainer environments', () => {
      // Test Codespaces detection
      process.env.NODE_ENV = 'development';
      process.env.CODESPACES = 'true';
      delete process.env.GITPOD_WORKSPACE_ID;

      const corsConfig = createCorsConfig();
      expect(typeof corsConfig.origin).toBe('function');

      // Test that GitHub Codespaces URLs are allowed
      const codespacesCallback = (err, allowed) => {
        expect(err).toBeNull();
        expect(allowed).toBe('https://test-8080.app.github.dev'); // Should echo back the specific origin
      };
      corsConfig.origin('https://test-8080.app.github.dev', codespacesCallback);

      // Test Gitpod detection
      delete process.env.CODESPACES;
      process.env.GITPOD_WORKSPACE_ID = 'test-workspace';

      const corsConfig2 = createCorsConfig();
      expect(typeof corsConfig2.origin).toBe('function');

      // Test that Gitpod URLs are allowed
      const gitpodCallback = (err, allowed) => {
        expect(err).toBeNull();
        expect(allowed).toBe('https://8080-test.ws-us50.gitpod.io'); // Should echo back the specific origin
      };
      corsConfig2.origin('https://8080-test.ws-us50.gitpod.io', gitpodCallback);
    });

    it('should fallback to local development when no DevContainer detected', () => {
      process.env.NODE_ENV = 'development';
      delete process.env.CODESPACES;
      delete process.env.GITPOD_WORKSPACE_ID;

      const corsConfig = createCorsConfig();
      expect(typeof corsConfig.origin).toBe('function');

      // Test that localhost URLs are allowed
      const localhostCallback8080 = (err, allowed) => {
        expect(err).toBeNull();
        expect(allowed).toBe('http://localhost:8080'); // Should echo back the specific origin
      };

      const localhostCallback3000 = (err, allowed) => {
        expect(err).toBeNull();
        expect(allowed).toBe('http://127.0.0.1:3000'); // Should echo back the specific origin
      };

      corsConfig.origin('http://localhost:8080', localhostCallback8080);
      corsConfig.origin('http://127.0.0.1:3000', localhostCallback3000);
    });
  });
});
