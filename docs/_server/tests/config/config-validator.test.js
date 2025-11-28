/**
 * @fileoverview Configuration Validator Tests
 * Test environment variable validation and configuration management
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { validateConfig, getRequiredEnvVars, validateEnvVar, ConfigValidationError } from '../../config/config-validator.js';

describe('Configuration Validator', () => {
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

  describe('Environment Variable Validation', () => {
    it('should validate required environment variables are present', () => {
      process.env.NODE_ENV = 'test';
      process.env.PORT = '3002';

      const validation = validateConfig();

      expect(validation.valid).toBe(true);
      expect(validation.errors).toHaveLength(0);
      expect(validation.config).toMatchObject({
        nodeEnv: 'test',
        port: 3002
      });
    });

    it('should detect missing required environment variables', () => {
      delete process.env.NODE_ENV;
      delete process.env.PORT;

      const validation = validateConfig();

      expect(validation.valid).toBe(false);
      expect(validation.errors).toContain('NODE_ENV is required');
      expect(validation.errors).toContain('PORT is required');
    });

    it('should validate environment variable types', () => {
      process.env.NODE_ENV = 'development';
      process.env.PORT = 'not-a-number';
      process.env.ENABLE_CORS = 'maybe';

      const validation = validateConfig();

      expect(validation.valid).toBe(false);
      expect(validation.errors).toContain('PORT must be a valid number');
      expect(validation.errors).toContain('ENABLE_CORS must be true or false');
    });

    it('should validate environment variable ranges', () => {
      process.env.NODE_ENV = 'production';
      process.env.PORT = '99999';
      process.env.REQUEST_TIMEOUT = '-1';

      const validation = validateConfig();

      expect(validation.valid).toBe(false);
      expect(validation.errors).toContain('PORT must be between 1000 and 65535');
      expect(validation.errors).toContain('REQUEST_TIMEOUT must be greater than or equal to 1');
    });

    it('should validate NODE_ENV allowed values', () => {
      process.env.NODE_ENV = 'invalid-env';
      process.env.PORT = '3002';

      const validation = validateConfig();

      expect(validation.valid).toBe(false);
      expect(validation.errors).toContain('NODE_ENV must be one of: development, test, production');
    });
  });

  describe('Configuration Transformation', () => {
    it('should transform and normalize configuration values', () => {
      process.env.NODE_ENV = 'PRODUCTION';
      process.env.PORT = '  3002  ';
      process.env.ENABLE_CORS = 'true';
      process.env.LOG_LEVEL = 'INFO';

      const validation = validateConfig();

      expect(validation.valid).toBe(true);
      expect(validation.config).toMatchObject({
        nodeEnv: 'production',
        port: 3002,
        enableCors: true,
        logLevel: 'info'
      });
    });

    it('should apply default values for optional variables', () => {
      process.env.NODE_ENV = 'development';
      process.env.PORT = '3002';
      // Don't set optional variables

      const validation = validateConfig();

      expect(validation.valid).toBe(true);
      expect(validation.config).toMatchObject({
        enableCors: true,
        logLevel: 'info',
        requestTimeout: 30000,
        maxFileSize: 1048576
      });
    });

    it('should override defaults with provided values', () => {
      process.env.NODE_ENV = 'test';
      process.env.PORT = '3002';
      process.env.LOG_LEVEL = 'debug';
      process.env.REQUEST_TIMEOUT = '5000';

      const validation = validateConfig();

      expect(validation.valid).toBe(true);
      expect(validation.config).toMatchObject({
        logLevel: 'debug',
        requestTimeout: 5000
      });
    });
  });

  describe('Individual Variable Validation', () => {
    it('should validate string variables', () => {
      expect(validateEnvVar('test', 'string', { required: true })).toEqual({
        valid: true,
        value: 'test'
      });

      expect(validateEnvVar(undefined, 'string', { required: true })).toEqual({
        valid: false,
        error: 'is required'
      });

      expect(validateEnvVar('', 'string', { required: true })).toEqual({
        valid: false,
        error: 'cannot be empty'
      });
    });

    it('should validate number variables', () => {
      expect(validateEnvVar('42', 'number')).toEqual({
        valid: true,
        value: 42
      });

      expect(validateEnvVar('not-a-number', 'number')).toEqual({
        valid: false,
        error: 'must be a valid number'
      });

      expect(validateEnvVar('100', 'number', { min: 1, max: 50 })).toEqual({
        valid: false,
        error: 'must be between 1 and 50'
      });
    });

    it('should validate boolean variables', () => {
      expect(validateEnvVar('true', 'boolean')).toEqual({
        valid: true,
        value: true
      });

      expect(validateEnvVar('false', 'boolean')).toEqual({
        valid: true,
        value: false
      });

      expect(validateEnvVar('maybe', 'boolean')).toEqual({
        valid: false,
        error: 'must be true or false'
      });
    });

    it('should validate enum variables', () => {
      const options = { allowedValues: ['dev', 'prod', 'test'] };

      expect(validateEnvVar('dev', 'enum', options)).toEqual({
        valid: true,
        value: 'dev'
      });

      expect(validateEnvVar('invalid', 'enum', options)).toEqual({
        valid: false,
        error: 'must be one of: dev, prod, test'
      });
    });
  });

  describe('Configuration Error Handling', () => {
    it('should create ConfigValidationError with proper message', () => {
      const errors = ['PORT is required', 'NODE_ENV is invalid'];
      const error = new ConfigValidationError(errors);

      expect(error).toBeInstanceOf(Error);
      expect(error.name).toBe('ConfigValidationError');
      expect(error.message).toContain('Configuration validation failed');
      expect(error.message).toContain('PORT is required');
      expect(error.message).toContain('NODE_ENV is invalid');
      expect(error.errors).toEqual(errors);
    });

    it('should include validation details in error', () => {
      const errors = ['Multiple validation failures'];
      const error = new ConfigValidationError(errors);

      expect(error.errors).toEqual(errors);
      expect(error.toString()).toContain('ConfigValidationError');
    });
  });

  describe('Required Environment Variables List', () => {
    it('should return list of required environment variables', () => {
      const required = getRequiredEnvVars();

      expect(required).toBeInstanceOf(Array);
      expect(required).toContain('NODE_ENV');
      expect(required).toContain('PORT');
    });

    it('should include environment-specific requirements', () => {
      const required = getRequiredEnvVars('production');

      expect(required).toContain('NODE_ENV');
      expect(required).toContain('PORT');
      // Production might have additional requirements
    });
  });

  describe('Configuration Schema', () => {
    it('should validate against complete configuration schema', () => {
      const fullConfig = {
        NODE_ENV: 'production',
        PORT: '8080',
        ENABLE_CORS: 'true',
        LOG_LEVEL: 'warn',
        REQUEST_TIMEOUT: '10000',
        MAX_FILE_SIZE: '2097152'
      };

      // Set all environment variables
      Object.assign(process.env, fullConfig);

      const validation = validateConfig();

      expect(validation.valid).toBe(true);
      expect(validation.config).toMatchObject({
        nodeEnv: 'production',
        port: 8080,
        enableCors: true,
        logLevel: 'warn',
        requestTimeout: 10000,
        maxFileSize: 2097152
      });
    });

    it('should handle partial configuration gracefully', () => {
      process.env.NODE_ENV = 'development';
      process.env.PORT = '3000';
      // Leave other variables as defaults

      const validation = validateConfig();

      expect(validation.valid).toBe(true);
      expect(validation.config.nodeEnv).toBe('development');
      expect(validation.config.port).toBe(3000);
      expect(validation.config.enableCors).toBe(true); // default
      expect(validation.config.logLevel).toBe('info'); // default
    });
  });
});
