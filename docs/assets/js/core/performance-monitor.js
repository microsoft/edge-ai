/**
 * Performance Monitoring System
 * Dedicated module for tracking and measuring performance metrics
 * @module core/performance-monitor
 * @version 1.0.0
 * @since 1.0.0
 * @author Edge AI Team
 */

/**
 * Performance Monitoring System
 * Handles performance measurement and tracking without error handling complexity
 * @class PerformanceMonitor
 */
export class PerformanceMonitor {
  constructor() {
    this.performanceMetrics = {};
    this.initialized = false;
    this.maxMetrics = 100;
  }

  /**
   * Get test environment info - safe access to globals for testing
   * @returns {Object} Test environment information
   */
  getTestEnvironmentInfo() {
    const safeWindow = (typeof window !== 'undefined') ? window : {};
    return {
      window: safeWindow
    };
  }

  /**
   * Initialize performance monitoring system
   */
  init() {
    if (this.initialized) {return;}

    this.setupPerformanceTracking();
    this.initialized = true;
  }

  /**
   * Setup performance tracking
   */
  setupPerformanceTracking() {
    const env = this.getTestEnvironmentInfo();
    const PLUGIN_CONFIG = env.window.KataProgressConfig || { performanceTracking: false };

    if (!PLUGIN_CONFIG.performanceTracking) {return;}

    this.performanceMetrics = {
      pageProcessingTime: [],
      storageOperationTime: [],
      floatingBarUpdateTime: [],
      checkboxEnhancementTime: []
    };
  }

  /**
   * Start performance measurement
   * @param {string} metricName - Name of the metric
   * @returns {Function} Function to end measurement
   */
  startPerformanceMeasurement(metricName) {
    const env = this.getTestEnvironmentInfo();
    const PLUGIN_CONFIG = env.window.KataProgressConfig || { performanceTracking: true }; // Default to true for testing

    if (!PLUGIN_CONFIG.performanceTracking) {
      return () => {}; // No-op function
    }

    const startTime = performance.now();
    let hasEnded = false;

    return () => {
      if (hasEnded) {
        return undefined; // Already ended, return undefined
      }

      hasEnded = true;
      const endTime = performance.now();
      const duration = endTime - startTime;

      if (!this.performanceMetrics[metricName]) {
        this.performanceMetrics[metricName] = [];
      }

      this.performanceMetrics[metricName].push(duration);

      // Keep only last maxMetrics measurements
      if (this.performanceMetrics[metricName].length > this.maxMetrics) {
        this.performanceMetrics[metricName] = this.performanceMetrics[metricName].slice(-this.maxMetrics);
      }

      return duration; // Return the duration value
    };
  }

  /**
   * Get performance metrics summary
   * @returns {Object} Performance metrics data
   */
  getPerformanceMetrics() {
    const env = this.getTestEnvironmentInfo();
    const PLUGIN_CONFIG = env.window.KataProgressConfig || { performanceTracking: true }; // Default to true for testing

    if (!PLUGIN_CONFIG.performanceTracking) {
      return null;
    }

    return Object.keys(this.performanceMetrics).reduce((summary, metricName) => {
      const metrics = this.performanceMetrics[metricName];
      if (metrics.length === 0) {return summary;}

      const sum = metrics.reduce((a, b) => a + b, 0);
      summary[metricName] = {
        count: metrics.length,
        total: sum,
        average: sum / metrics.length,
        min: Math.min(...metrics),
        max: Math.max(...metrics),
        latest: metrics[metrics.length - 1]
      };

      return summary;
    }, {});
  }

  /**
   * Alias for getPerformanceMetrics for backward compatibility
   * @returns {Object} Performance metrics data - returns raw arrays for each metric
   */
  getMetrics() {
    // For backward compatibility, return raw metric arrays
    return { ...this.performanceMetrics };
  }

  /**
   * Get raw metric measurements for a specific metric
   * @param {string} metricName - Name of the metric
   * @returns {Array} Array of measurement values
   */
  getMetric(metricName) {
    if (!this.performanceMetrics[metricName]) {
      return [];
    }
    return this.performanceMetrics[metricName];
  }

  /**
   * Get average performance for a specific metric
   * @param {string} metricName - Name of the metric
   * @returns {number} Average performance value
   */
  getAveragePerformance(metricName) {
    const measurements = this.getMetric(metricName);
    if (measurements.length === 0) {
      return 0;
    }
    return measurements.reduce((sum, val) => sum + val, 0) / measurements.length;
  }

  /**
   * Get performance statistics for a specific metric
   * @param {string} metricName - Name of the metric
   * @returns {Object} Statistics (min, max, avg, count)
   */
  getMetricStatistics(metricName) {
    const env = this.getTestEnvironmentInfo();
    const PLUGIN_CONFIG = env.window.KataProgressConfig || { performanceTracking: false };

    if (!PLUGIN_CONFIG.performanceTracking || !this.performanceMetrics[metricName]) {
      return null;
    }

    const measurements = this.performanceMetrics[metricName];
    if (measurements.length === 0) {
      return { min: 0, max: 0, avg: 0, count: 0 };
    }

    const min = Math.min(...measurements);
    const max = Math.max(...measurements);
    const avg = measurements.reduce((sum, val) => sum + val, 0) / measurements.length;

    return {
      min: Math.round(min * 100) / 100,
      max: Math.round(max * 100) / 100,
      avg: Math.round(avg * 100) / 100,
      count: measurements.length
    };
  }

  /**
   * Clear performance metrics
   * @param {string} metricName - Optional specific metric to clear, or all if not provided
   */
  clearMetrics(metricName = null) {
    if (metricName) {
      if (this.performanceMetrics[metricName]) {
        this.performanceMetrics[metricName] = [];
      }
    } else {
      Object.keys(this.performanceMetrics).forEach(key => {
        this.performanceMetrics[key] = [];
      });
    }
  }

  /**
   * Add a custom performance metric
   * @param {string} metricName - Name of the metric
   * @param {number} value - Performance value to record
   */
  recordMetric(metricName, value) {
    const env = this.getTestEnvironmentInfo();
    const PLUGIN_CONFIG = env.window.KataProgressConfig || { performanceTracking: true }; // Default to true for testing

    if (!PLUGIN_CONFIG.performanceTracking) {return;}

    if (!this.performanceMetrics[metricName]) {
      this.performanceMetrics[metricName] = [];
    }

    this.performanceMetrics[metricName].push(value);

    // Keep only last maxMetrics measurements
    if (this.performanceMetrics[metricName].length > this.maxMetrics) {
      this.performanceMetrics[metricName] = this.performanceMetrics[metricName].slice(-this.maxMetrics);
    }
  }

  /**
   * Check if performance tracking is enabled
   * @returns {boolean} True if performance tracking is enabled
   */
  isTrackingEnabled() {
    const env = this.getTestEnvironmentInfo();
    const PLUGIN_CONFIG = env.window.KataProgressConfig || { performanceTracking: false };
    return !!PLUGIN_CONFIG.performanceTracking;
  }
}

// Export default instance for convenience
export const defaultPerformanceMonitor = new PerformanceMonitor();

// Export alias for backward compatibility
export const performanceMonitor = defaultPerformanceMonitor;

// Export convenience functions
export const startMeasurement = (...args) => defaultPerformanceMonitor.startPerformanceMeasurement(...args);
export const getMetrics = (...args) => defaultPerformanceMonitor.getMetrics(...args);
export const recordMetric = (...args) => defaultPerformanceMonitor.recordMetric(...args);
