/**
 * @fileoverview Monitoring Configuration Tests
 * Tests for monitoring and logging configuration
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import {
  MonitoringConfig,
  getConfig,
  updateConfig,
  validateConfig,
  getThresholds,
  getLogLevel
} from '../../config/monitoring-config.js';

describe('Monitoring Configuration', () => {
  let originalEnv;

  beforeEach(() => {
    originalEnv = { ...process.env };
  });

  afterEach(() => {
    process.env = originalEnv;
    vi.clearAllMocks();
  });

  describe('Configuration Loading', () => {
    it('should load default configuration', () => {
      const config = getConfig();

      expect(config).toBeDefined();
      expect(config.enabled).toBe(true);
      expect(config.logLevel).toBe('info');
      expect(config.metricsInterval).toBeGreaterThan(0);
      expect(config.retentionPeriod).toBeGreaterThan(0);
    });

    it('should load configuration from environment variables', () => {
      process.env.MONITORING_ENABLED = 'false';
      process.env.LOG_LEVEL = 'debug';
      process.env.METRICS_INTERVAL = '30000';
      process.env.RETENTION_PERIOD = '604800000'; // 7 days

      const config = getConfig();

      expect(config.enabled).toBe(false);
      expect(config.logLevel).toBe('debug');
      expect(config.metricsInterval).toBe(30000);
      expect(config.retentionPeriod).toBe(604800000);
    });

    it('should handle invalid environment values gracefully', () => {
      process.env.MONITORING_ENABLED = 'invalid';
      process.env.METRICS_INTERVAL = 'not-a-number';
      process.env.LOG_LEVEL = 'invalid-level';

      const config = getConfig();

      // Should fall back to defaults
      expect(config.enabled).toBe(true);
      expect(config.metricsInterval).toBeGreaterThan(0);
      expect(config.logLevel).toBe('info');
    });
  });

  describe('Configuration Validation', () => {
    it('should validate correct configuration', () => {
      const validConfig = {
        enabled: true,
        logLevel: 'info',
        metricsInterval: 5000,
        retentionPeriod: 86400000,
        thresholds: {
          responseTime: 1000,
          memoryUsage: 80,
          cpuUsage: 80,
          errorRate: 5
        }
      };

      const result = validateConfig(validConfig);
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should detect invalid log levels', () => {
      const invalidConfig = {
        logLevel: 'invalid-level'
      };

      const result = validateConfig(invalidConfig);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Invalid log level: invalid-level');
    });

    it('should detect invalid threshold values', () => {
      const invalidConfig = {
        thresholds: {
          responseTime: -100,
          memoryUsage: 150,
          cpuUsage: -10,
          errorRate: 101
        }
      };

      const result = validateConfig(invalidConfig);
      expect(result.valid).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
    });

    it('should detect invalid interval values', () => {
      const invalidConfig = {
        metricsInterval: 0,
        retentionPeriod: -1000
      };

      const result = validateConfig(invalidConfig);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Metrics interval must be positive');
      expect(result.errors).toContain('Retention period must be positive');
    });
  });

  describe('Configuration Updates', () => {
    it('should update configuration values', () => {
      const updates = {
        logLevel: 'debug',
        metricsInterval: 10000
      };

      updateConfig(updates);
      const config = getConfig();

      expect(config.logLevel).toBe('debug');
      expect(config.metricsInterval).toBe(10000);
    });

    it('should validate updates before applying', () => {
      const invalidUpdates = {
        logLevel: 'invalid'
      };

      expect(() => updateConfig(invalidUpdates)).toThrow();

      const config = getConfig();
      expect(config.logLevel).not.toBe('invalid');
    });

    it('should apply partial updates', () => {
      const originalConfig = getConfig();
      const updates = {
        logLevel: 'warn'
      };

      updateConfig(updates);
      const config = getConfig();

      expect(config.logLevel).toBe('warn');
      expect(config.metricsInterval).toBe(originalConfig.metricsInterval);
    });
  });

  describe('Threshold Configuration', () => {
    it('should return performance thresholds', () => {
      const thresholds = getThresholds();

      expect(thresholds.responseTime).toBeGreaterThan(0);
      expect(thresholds.memoryUsage).toBeGreaterThan(0);
      expect(thresholds.memoryUsage).toBeLessThanOrEqual(100);
      expect(thresholds.cpuUsage).toBeGreaterThan(0);
      expect(thresholds.cpuUsage).toBeLessThanOrEqual(100);
      expect(thresholds.errorRate).toBeGreaterThanOrEqual(0);
      expect(thresholds.errorRate).toBeLessThanOrEqual(100);
    });

    it('should allow threshold customization', () => {
      const customThresholds = {
        responseTime: 500,
        memoryUsage: 70,
        cpuUsage: 60,
        errorRate: 2
      };

      updateConfig({ thresholds: customThresholds });
      const thresholds = getThresholds();

      expect(thresholds.responseTime).toBe(500);
      expect(thresholds.memoryUsage).toBe(70);
      expect(thresholds.cpuUsage).toBe(60);
      expect(thresholds.errorRate).toBe(2);
    });
  });

  describe('Log Level Configuration', () => {
    it('should return current log level', () => {
      const logLevel = getLogLevel();
      expect(['error', 'warn', 'info', 'debug']).toContain(logLevel);
    });

    it('should respect log level hierarchy', () => {
      updateConfig({ logLevel: 'error' });
      expect(getLogLevel()).toBe('error');

      updateConfig({ logLevel: 'warn' });
      expect(getLogLevel()).toBe('warn');

      updateConfig({ logLevel: 'info' });
      expect(getLogLevel()).toBe('info');

      updateConfig({ logLevel: 'debug' });
      expect(getLogLevel()).toBe('debug');
    });
  });

  describe('MonitoringConfig Class', () => {
    it('should create instance with default values', () => {
      const config = new MonitoringConfig();

      expect(config.enabled).toBe(true);
      expect(config.logLevel).toBeDefined();
      expect(config.metricsInterval).toBeGreaterThan(0);
      expect(config.retentionPeriod).toBeGreaterThan(0);
      expect(config.thresholds).toBeDefined();
    });

    it('should create instance with custom values', () => {
      const customConfig = {
        enabled: false,
        logLevel: 'debug',
        metricsInterval: 15000,
        retentionPeriod: 172800000, // 2 days
        thresholds: {
          responseTime: 2000,
          memoryUsage: 90,
          cpuUsage: 85,
          errorRate: 10
        }
      };

      const config = new MonitoringConfig(customConfig);

      expect(config.enabled).toBe(false);
      expect(config.logLevel).toBe('debug');
      expect(config.metricsInterval).toBe(15000);
      expect(config.retentionPeriod).toBe(172800000);
      expect(config.thresholds.responseTime).toBe(2000);
    });

    it('should validate configuration on creation', () => {
      const invalidConfig = {
        logLevel: 'invalid',
        metricsInterval: -1
      };

      expect(() => new MonitoringConfig(invalidConfig)).toThrow();
    });

    it('should provide configuration serialization', () => {
      const config = new MonitoringConfig();
      const serialized = config.toJSON();

      expect(serialized).toEqual(
        expect.objectContaining({
          enabled: expect.any(Boolean),
          logLevel: expect.any(String),
          metricsInterval: expect.any(Number),
          retentionPeriod: expect.any(Number),
          thresholds: expect.any(Object)
        })
      );
    });
  });

  describe('Feature Flags', () => {
    it('should support feature flag configuration', () => {
      const config = getConfig();

      expect(config.features).toBeDefined();
      expect(config.features.requestLogging).toBeDefined();
      expect(config.features.performanceMonitoring).toBeDefined();
      expect(config.features.healthChecks).toBeDefined();
    });

    it('should allow feature flag updates', () => {
      updateConfig({
        features: {
          requestLogging: false,
          performanceMonitoring: true,
          healthChecks: true
        }
      });

      const config = getConfig();
      expect(config.features.requestLogging).toBe(false);
      expect(config.features.performanceMonitoring).toBe(true);
      expect(config.features.healthChecks).toBe(true);
    });
  });

  describe('Export Configuration', () => {
    it('should support export format configuration', () => {
      const config = getConfig();

      expect(config.export).toBeDefined();
      expect(config.export.formats).toContain('json');
      expect(config.export.endpoint).toBeDefined();
    });

    it('should validate export formats', () => {
      const invalidConfig = {
        export: {
          formats: ['invalid-format']
        }
      };

      const result = validateConfig(invalidConfig);
      expect(result.valid).toBe(false);
    });
  });
});
