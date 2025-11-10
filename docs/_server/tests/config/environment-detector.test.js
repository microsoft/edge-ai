/**
 * @fileoverview Environment Detector Tests
 * Test runtime environment detection and environment-specific configuration
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import {
  detectEnvironment,
  isProduction,
  isDevelopment,
  isTest,
  getEnvironmentConfig,
  validateEnvironment,
  EnvironmentError
} from '../../config/environment-detector.js';

describe('Environment Detector', () => {
  let originalEnv;

  beforeEach(() => {
    // Store original environment
    originalEnv = { ...process.env };
  });

  afterEach(() => {
    // Restore original environment
    process.env = originalEnv;
    vi.clearAllMocks();
  });

  describe('Environment Detection', () => {
    it('should detect production environment', () => {
      process.env.NODE_ENV = 'production';

      const env = detectEnvironment();

      expect(env).toBe('production');
      expect(isProduction()).toBe(true);
      expect(isDevelopment()).toBe(false);
      expect(isTest()).toBe(false);
    });

    it('should detect development environment', () => {
      process.env.NODE_ENV = 'development';

      const env = detectEnvironment();

      expect(env).toBe('development');
      expect(isProduction()).toBe(false);
      expect(isDevelopment()).toBe(true);
      expect(isTest()).toBe(false);
    });

    it('should detect test environment', () => {
      process.env.NODE_ENV = 'test';

      const env = detectEnvironment();

      expect(env).toBe('test');
      expect(isProduction()).toBe(false);
      expect(isDevelopment()).toBe(false);
      expect(isTest()).toBe(true);
    });

    it('should default to development when NODE_ENV is not set', () => {
      delete process.env.NODE_ENV;

      const env = detectEnvironment();

      expect(env).toBe('development');
      expect(isDevelopment()).toBe(true);
    });

    it('should handle case-insensitive environment names', () => {
      process.env.NODE_ENV = 'PRODUCTION';

      const env = detectEnvironment();

      expect(env).toBe('production');
      expect(isProduction()).toBe(true);
    });

    it('should normalize whitespace in environment names', () => {
      process.env.NODE_ENV = '  production  ';

      const env = detectEnvironment();

      expect(env).toBe('production');
      expect(isProduction()).toBe(true);
    });
  });

  describe('Environment Validation', () => {
    it('should validate known environment names', () => {
      const validEnvs = ['development', 'test', 'production'];

      validEnvs.forEach(env => {
        process.env.NODE_ENV = env;
        expect(() => validateEnvironment()).not.toThrow();
      });
    });

    it('should reject invalid environment names', () => {
      process.env.NODE_ENV = 'invalid-environment';

      expect(() => validateEnvironment()).toThrow(EnvironmentError);
      expect(() => validateEnvironment()).toThrow('Unknown environment: invalid-environment');
    });

    it('should provide helpful error messages for invalid environments', () => {
      process.env.NODE_ENV = 'prod';

      expect(() => validateEnvironment()).toThrow(
        'Unknown environment: prod. Valid environments are: development, test, production'
      );
    });

    it('should validate environment consistency', () => {
      process.env.NODE_ENV = 'production';
      process.env.DEBUG = 'true';

      expect(() => validateEnvironment()).toThrow(
        'Invalid configuration: DEBUG should not be enabled in production'
      );
    });
  });

  describe('Environment-Specific Configuration', () => {
    it('should provide development configuration', () => {
      process.env.NODE_ENV = 'development';

      const config = getEnvironmentConfig();

      expect(config).toMatchObject({
        environment: 'development',
        debug: true,
        logLevel: 'debug',
        cors: {
          enabled: true,
          credentials: true
        },
        security: {
          strictMode: false,
          requireHttps: false
        },
        performance: {
          enableMetrics: true,
          enableProfiling: true
        }
      });
    });

    it('should provide test configuration', () => {
      process.env.NODE_ENV = 'test';

      const config = getEnvironmentConfig();

      expect(config).toMatchObject({
        environment: 'test',
        debug: false,
        logLevel: 'error',
        cors: {
          enabled: true,
          credentials: false
        },
        security: {
          strictMode: false,
          requireHttps: false
        },
        performance: {
          enableMetrics: false,
          enableProfiling: false
        }
      });
    });

    it('should provide production configuration', () => {
      process.env.NODE_ENV = 'production';

      const config = getEnvironmentConfig();

      expect(config).toMatchObject({
        environment: 'production',
        debug: false,
        logLevel: 'warn',
        cors: {
          enabled: false,
          credentials: false
        },
        security: {
          strictMode: true,
          requireHttps: true
        },
        performance: {
          enableMetrics: true,
          enableProfiling: false
        }
      });
    });

    it('should merge environment config with custom overrides', () => {
      process.env.NODE_ENV = 'development';
      const overrides = {
        logLevel: 'info',
        cors: {
          enabled: false
        }
      };

      const config = getEnvironmentConfig(overrides);

      expect(config.logLevel).toBe('info');
      expect(config.cors.enabled).toBe(false);
      expect(config.debug).toBe(true); // Still from development defaults
    });
  });

  describe('Environment Feature Detection', () => {
    it('should detect development features', () => {
      process.env.NODE_ENV = 'development';

      const config = getEnvironmentConfig();

      expect(config.features).toMatchObject({
        hotReload: true,
        debugEndpoints: true,
        verboseLogging: true,
        errorDetails: true
      });
    });

    it('should detect production features', () => {
      process.env.NODE_ENV = 'production';

      const config = getEnvironmentConfig();

      expect(config.features).toMatchObject({
        hotReload: false,
        debugEndpoints: false,
        verboseLogging: false,
        errorDetails: false
      });
    });

    it('should detect test features', () => {
      process.env.NODE_ENV = 'test';

      const config = getEnvironmentConfig();

      expect(config.features).toMatchObject({
        hotReload: false,
        debugEndpoints: true,
        verboseLogging: false,
        errorDetails: true
      });
    });
  });

  describe('Environment Error Handling', () => {
    it('should create EnvironmentError with proper message', () => {
      const error = new EnvironmentError('Test environment error');

      expect(error).toBeInstanceOf(Error);
      expect(error.name).toBe('EnvironmentError');
      expect(error.message).toBe('Test environment error');
    });

    it('should include environment context in errors', () => {
      process.env.NODE_ENV = 'invalid';

      try {
        validateEnvironment();
      } catch (error) {
        expect(error).toBeInstanceOf(EnvironmentError);
        expect(error.message).toContain('invalid');
      }
    });
  });

  describe('Runtime Environment Checks', () => {
    it('should detect CI environment', () => {
      process.env.CI = 'true';
      process.env.NODE_ENV = 'test';

      const config = getEnvironmentConfig();

      expect(config.runtime).toMatchObject({
        isCI: true,
        isContinuousIntegration: true
      });
    });

    it('should detect Docker environment', () => {
      process.env.DOCKER = 'true';
      process.env.NODE_ENV = 'production';

      const config = getEnvironmentConfig();

      expect(config.runtime).toMatchObject({
        isDocker: true,
        isContainerized: true
      });
    });

    it('should detect cloud platform environment', () => {
      process.env.CLOUD_PLATFORM = 'azure';
      process.env.NODE_ENV = 'production';

      const config = getEnvironmentConfig();

      expect(config.runtime).toMatchObject({
        cloudPlatform: 'azure',
        isCloud: true
      });
    });

    it('should provide default runtime configuration', () => {
      process.env.NODE_ENV = 'development';
      // Clear cloud/container indicators
      delete process.env.CI;
      delete process.env.DOCKER;
      delete process.env.CLOUD_PLATFORM;

      const config = getEnvironmentConfig();

      expect(config.runtime).toMatchObject({
        isCI: false,
        isDocker: false,
        isCloud: false,
        cloudPlatform: null
      });
    });
  });

  describe('Configuration Consistency Checks', () => {
    it('should validate production security requirements', () => {
      process.env.NODE_ENV = 'production';
      process.env.HTTPS_DISABLED = 'true';

      expect(() => validateEnvironment()).toThrow(
        'HTTPS is required in production environment'
      );
    });

    it('should validate development debug consistency', () => {
      process.env.NODE_ENV = 'development';
      process.env.DEBUG_DISABLED = 'true';

      // This should not throw - debug can be disabled in development
      expect(() => validateEnvironment()).not.toThrow();
    });

    it('should validate test environment isolation', () => {
      process.env.NODE_ENV = 'test';
      process.env.PRODUCTION_DB = 'true';

      expect(() => validateEnvironment()).toThrow(
        'Test environment should not connect to production resources'
      );
    });
  });
});
