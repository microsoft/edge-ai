/**
 * PerformanceMonitor Test Suite
 * Comprehensive tests for performance monitoring and measurement capabilities
 * @module tests/core/performance-monitor
 */

import '../helpers/test-setup.js';
import { expect, describe, it, beforeEach, afterEach } from 'vitest';
import { testPresets } from '../helpers/focused/preset-compositions.js';
import { PerformanceMonitor, defaultPerformanceMonitor, startMeasurement, getMetrics, recordMetric } from '../../core/performance-monitor.js';

/**
 * PerformanceMonitor Test Suite
 * Tests performance measurement, tracking, and metrics collection
 */
describe('PerformanceMonitor', () => {

  let testHelper = testPresets.coreModule();
  let performanceMonitor;

  beforeEach(() => {
    testHelper = testPresets.integrationModule();
    // Mock configuration before creating PerformanceMonitor
    window.KataProgressConfig = {
      name: 'test-plugin',
      performanceTracking: true,
      debugMode: true
    };
    // Create fresh instance for each test
    performanceMonitor = new PerformanceMonitor();
  });

  afterEach(() => {
    testHelper.afterEach?.();
  });

  describe('initialization', () => {
    it('should initialize successfully', () => {
      expect(performanceMonitor.initialized).toBe(false);
      expect(performanceMonitor.performanceMetrics).toBeTypeOf('object');
    });

    it('should initialize with proper configuration', () => {
      performanceMonitor.init();
      expect(performanceMonitor.initialized).toBe(true);
      expect(performanceMonitor.maxMetrics).toBe(100);
    });

    it('should handle initialization without config', () => {
      delete window.KataProgressConfig;
      const monitor = new PerformanceMonitor();
      monitor.init();
      expect(monitor.initialized).toBe(true);
    });
  });

  describe('performance measurement', () => {
    beforeEach(() => {
      performanceMonitor.init();
    });

    it('should start and end measurements successfully', () => {
      const end = performanceMonitor.startPerformanceMeasurement('testMetric');
      expect(end).toBeTypeOf('function');

      const result = end();
      expect(result).toBeTypeOf('number');
      expect(performanceMonitor.performanceMetrics.testMetric).toHaveLength(1);
    });

    it('should record multiple measurements', () => {
      const end1 = performanceMonitor.startPerformanceMeasurement('testMetric');
      const end2 = performanceMonitor.startPerformanceMeasurement('testMetric');

      end1();
      end2();

      expect(performanceMonitor.performanceMetrics.testMetric).toHaveLength(2);
    });

    it('should respect maxMetrics limit', () => {
      // Record 150 measurements
      for (let i = 0; i < 150; i++) {
        const end = performanceMonitor.startPerformanceMeasurement('testMetric');
        end();
      }

      expect(performanceMonitor.performanceMetrics.testMetric).toHaveLength(100);
    });

    it('should handle multiple metrics independently', () => {
      const end1 = performanceMonitor.startPerformanceMeasurement('metric1');
      const end2 = performanceMonitor.startPerformanceMeasurement('metric2');

      end1();
      end2();

      expect(performanceMonitor.performanceMetrics.metric1).toHaveLength(1);
      expect(performanceMonitor.performanceMetrics.metric2).toHaveLength(1);
    });
  });

  describe('metrics retrieval', () => {
    beforeEach(() => {
      performanceMonitor.init();
    });

    it('should return all metrics', () => {
      const end = performanceMonitor.startPerformanceMeasurement('testMetric');
      end();

      const metrics = performanceMonitor.getMetrics();
      expect(metrics).toHaveProperty('testMetric');
      expect(metrics.testMetric).toHaveLength(1);
    });

    it('should return specific metric', () => {
      const end = performanceMonitor.startPerformanceMeasurement('testMetric');
      end();

      const metric = performanceMonitor.getMetric('testMetric');
      expect(metric).toHaveLength(1);
    });

    it('should return empty array for non-existent metric', () => {
      const metric = performanceMonitor.getMetric('nonExistent');
      expect(metric).toEqual([]);
    });

    it('should calculate average performance', () => {
      // Record multiple measurements
      for (let i = 0; i < 5; i++) {
        const end = performanceMonitor.startPerformanceMeasurement('testMetric');
        end();
      }

      const average = performanceMonitor.getAveragePerformance('testMetric');
      expect(average).toBeTypeOf('number');
      expect(average).toBeGreaterThan(0);
    });
  });

  describe('record metric', () => {
    beforeEach(() => {
      performanceMonitor.init();
    });

    it('should record custom metrics', () => {
      performanceMonitor.recordMetric('customMetric', 100);
      expect(performanceMonitor.performanceMetrics.customMetric).toHaveLength(1);
      expect(performanceMonitor.performanceMetrics.customMetric[0]).toBe(100);
    });

    it('should handle multiple custom metrics', () => {
      for (let i = 0; i < 5; i++) {
        performanceMonitor.recordMetric('customMetric', i);
      }

      expect(performanceMonitor.performanceMetrics.customMetric).toHaveLength(5);
    });
  });

  describe('error handling', () => {
    it('should handle measurement errors gracefully', () => {
      const end = performanceMonitor.startPerformanceMeasurement('testMetric');

      // Call end multiple times
      end();
      const result = end();

      expect(result).toBeUndefined();
    });

    it('should handle invalid metric names', () => {
      expect(() => {
        performanceMonitor.recordMetric('', 100);
      }).not.toThrow();
    });
  });

  describe('static methods', () => {
    beforeEach(() => {
      // Clear metrics before each test to avoid shared state
      defaultPerformanceMonitor.clearMetrics();
    });

    it('should have working startMeasurement function', () => {
      const end = startMeasurement('testMetric');
      expect(end).toBeTypeOf('function');

      const result = end();
      expect(result).toBeTypeOf('number');
    });

    it('should have working getMetrics function', () => {
      const end = startMeasurement('testMetric');
      end();

      const metrics = getMetrics();
      expect(metrics).toHaveProperty('testMetric');
    });

    it('should have working recordMetric function', () => {
      recordMetric('testMetric', 100);

      const metrics = getMetrics();
      expect(metrics.testMetric).toHaveLength(1);
      expect(metrics.testMetric[0]).toBe(100);
    });
  });

  describe('default instance', () => {
    beforeEach(() => {
      // Clear metrics before each test to avoid shared state
      defaultPerformanceMonitor.clearMetrics();
    });

    it('should have working default performance monitor', () => {
      recordMetric('testMetric', 100);

      const metrics = defaultPerformanceMonitor.getMetrics();
      expect(metrics.testMetric).toHaveLength(1);
    });
  });
});
