/**
 * @fileoverview Performance Monitor Utility
 * Collects and tracks application performance metrics
 */

import { performance } from 'perf_hooks';
import os from 'os';

/**
 * Active timers for measuring operation duration
 */
const activeTimers = new Map();

/**
 * Metrics storage
 */
const metrics = {
  counters: new Map(),
  histograms: new Map(),
  gauges: new Map()
};

/**
 * Performance thresholds for issue detection
 */
const PERFORMANCE_THRESHOLDS = {
  responseTime: 1000, // ms
  memoryUsage: 80, // percentage
  cpuUsage: 80, // percentage
  errorRate: 5 // percentage
};

/**
 * Start a timer for measuring operation duration
 * @param {string} operation - Operation name
 * @returns {string} Timer ID
 */
export function startTimer(operation) {
  const timerId = `${operation}-${Date.now()}-${Math.random()}`;
  activeTimers.set(timerId, {
    operation,
    startTime: performance.now()
  });
  return timerId;
}

/**
 * End a timer and return the duration
 * @param {string} timerId - Timer ID from startTimer
 * @returns {number} Duration in milliseconds
 */
export function endTimer(timerId) {
  const timer = activeTimers.get(timerId);
  if (!timer) {
    return -1;
  }

  const duration = performance.now() - timer.startTime;
  activeTimers.delete(timerId);

  return Math.round(duration * 100) / 100; // Round to 2 decimal places
}

/**
 * Get current system metrics
 * @returns {Promise<Object>} System metrics
 */
export async function getSystemMetrics() {
  const memoryUsage = process.memoryUsage();
  const cpuUsage = await getCpuUsage();
  const eventLoopLag = await getEventLoopLag();

  return {
    memory: {
      heapUsed: memoryUsage.heapUsed,
      heapTotal: memoryUsage.heapTotal,
      external: memoryUsage.external,
      rss: memoryUsage.rss
    },
    cpu: {
      usage: cpuUsage
    },
    uptime: {
      process: Math.round(process.uptime()),
      system: Math.round(os.uptime())
    },
    eventLoop: {
      lag: eventLoopLag
    }
  };
}

/**
 * Get current application metrics
 * @returns {Object} Application metrics
 */
export function getAppMetrics() {
  const countersObj = {};
  metrics.counters.forEach((value, key) => {
    countersObj[key] = value;
  });

  const histogramsObj = {};
  metrics.histograms.forEach((value, key) => {
    histogramsObj[key] = value;
  });

  const gaugesObj = {};
  metrics.gauges.forEach((value, key) => {
    gaugesObj[key] = value;
  });

  return {
    counters: countersObj,
    histograms: histogramsObj,
    gauges: gaugesObj,
    timestamp: new Date().toISOString()
  };
}

/**
 * Reset all metrics
 */
export function resetMetrics() {
  metrics.counters.clear();
  metrics.histograms.clear();
  metrics.gauges.clear();
}

/**
 * Performance Monitor class for object-oriented usage
 */
export class PerformanceMonitor {
  /**
   * Increment a counter metric
   * @param {string} name - Counter name
   * @param {number} value - Value to add (default: 1)
   */
  incrementCounter(name, value = 1) {
    const current = metrics.counters.get(name) || 0;
    metrics.counters.set(name, current + value);
  }

  /**
   * Record a value in a histogram
   * @param {string} name - Histogram name
   * @param {number} value - Value to record
   */
  recordHistogram(name, value) {
    const histogram = metrics.histograms.get(name) || {
      count: 0,
      sum: 0,
      min: Infinity,
      max: -Infinity,
      values: []
    };

    histogram.count++;
    histogram.sum += value;
    histogram.min = Math.min(histogram.min, value);
    histogram.max = Math.max(histogram.max, value);
    histogram.values.push(value);
    histogram.avg = histogram.sum / histogram.count;

    // Keep only last 1000 values to prevent memory issues
    if (histogram.values.length > 1000) {
      histogram.values = histogram.values.slice(-1000);
    }

    metrics.histograms.set(name, histogram);
  }

  /**
   * Set a gauge value
   * @param {string} name - Gauge name
   * @param {number} value - Value to set
   */
  setGauge(name, value) {
    metrics.gauges.set(name, value);
  }

  /**
   * Track HTTP request metrics
   * @param {string} method - HTTP method
   * @param {string} path - Request path
   * @param {number} statusCode - Response status code
   * @param {number} responseTime - Response time in ms
   */
  trackHttpRequest(method, path, statusCode, responseTime) {
    // Increment request counters
    this.incrementCounter('http.requests.total');
    this.incrementCounter(`http.requests.${method}`);

    // Track status codes
    this.incrementCounter(`http.status.${statusCode}`);

    // Track status code ranges
    const statusRange = Math.floor(statusCode / 100);
    this.incrementCounter(`http.status.${statusRange}xx`);

    // Record response time
    this.recordHistogram('http.request.duration.seconds', responseTime / 1000); // Convert ms to seconds
  }

  /**
   * Detect performance issues from metrics
   * @param {Object} appMetrics - Application metrics
   * @returns {Array} Array of detected issues
   */
  detectPerformanceIssues(appMetrics) {
    const issues = [];

    // Check response time
    const responseTime = appMetrics.histograms['response.time'] || appMetrics.histograms['http.response.time'];
    if (responseTime && responseTime.avg > PERFORMANCE_THRESHOLDS.responseTime) {
      issues.push({
        type: 'slow_response_time',
        severity: 'warning',
        message: `Average response time is ${responseTime.avg}ms (threshold: ${PERFORMANCE_THRESHOLDS.responseTime}ms)`
      });
    }

    // Check memory usage
    const memoryUsed = appMetrics.gauges['memory.heap.used'];
    const memoryTotal = appMetrics.gauges['memory.heap.total'];
    if (memoryUsed && memoryTotal) {
      const memoryPercent = (memoryUsed / memoryTotal) * 100;
      if (memoryPercent > PERFORMANCE_THRESHOLDS.memoryUsage) {
        issues.push({
          type: 'high_memory_usage',
          severity: 'critical',
          message: `Memory usage is ${memoryPercent.toFixed(1)}% (threshold: ${PERFORMANCE_THRESHOLDS.memoryUsage}%)`
        });
      }
    }

    return issues;
  }

  /**
   * Export metrics in Prometheus format
   * @returns {string} Prometheus format metrics
   */
  exportPrometheus() {
    const lines = [];
    const timestamp = Date.now();

    // Export counters
    metrics.counters.forEach((value, name) => {
      const metricName = name.replace(/[.-]/g, '_');
      lines.push(`# HELP ${metricName} Counter metric`);
      lines.push(`# TYPE ${metricName} counter`);
      lines.push(`${metricName} ${value} ${timestamp}`);
    });

    // Export histograms
    metrics.histograms.forEach((histogram, name) => {
      const metricName = name.replace(/[.-]/g, '_');
      lines.push(`# HELP ${metricName} Histogram metric`);
      lines.push(`# TYPE ${metricName} histogram`);
      lines.push(`${metricName}_count ${histogram.count} ${timestamp}`);
      lines.push(`${metricName}_sum ${histogram.sum} ${timestamp}`);
    });

    // Export gauges
    metrics.gauges.forEach((value, name) => {
      const metricName = name.replace(/[.-]/g, '_');
      lines.push(`# HELP ${metricName} Gauge metric`);
      lines.push(`# TYPE ${metricName} gauge`);
      lines.push(`${metricName} ${value} ${timestamp}`);
    });

    // Add standard Node.js metrics
    const memoryUsage = process.memoryUsage();
    lines.push(`# HELP nodejs_memory_heap_used_bytes Node.js heap memory used`);
    lines.push(`# TYPE nodejs_memory_heap_used_bytes gauge`);
    lines.push(`nodejs_memory_heap_used_bytes ${memoryUsage.heapUsed} ${timestamp}`);

    return lines.join('\n');
  }

  /**
   * Export metrics in JSON format
   * @returns {string} JSON format metrics
   */
  exportJSON() {
    return JSON.stringify(getAppMetrics(), null, 2);
  }

  /**
   * Clean up old metric data to prevent memory leaks
   */
  cleanup() {
    // Clean up histogram values, keeping only recent data
    metrics.histograms.forEach((histogram, _name) => {
      if (histogram.values && histogram.values.length > 100) {
        const recentValues = histogram.values.slice(-100);
        histogram.values = recentValues;
        histogram.count = recentValues.length;
        histogram.sum = recentValues.reduce((sum, val) => sum + val, 0);
        histogram.avg = histogram.sum / histogram.count;
        histogram.min = Math.min(...recentValues);
        histogram.max = Math.max(...recentValues);
      }
    });
  }
}

/**
 * Get CPU usage percentage
 * @returns {Promise<number>} CPU usage percentage
 */
async function getCpuUsage() {
  return new Promise((resolve) => {
    const startTime = process.hrtime();
    const startUsage = process.cpuUsage();

    setTimeout(() => {
      const endTime = process.hrtime(startTime);
      const endUsage = process.cpuUsage(startUsage);

      const totalTime = endTime[0] * 1000000 + endTime[1] / 1000; // microseconds
      const totalUsage = (endUsage.user + endUsage.system) / 1000; // microseconds

      const usage = (totalUsage / totalTime) * 100;
      resolve(Math.min(100, Math.max(0, usage)));
    }, 100);
  });
}

/**
 * Get event loop lag
 * @returns {Promise<number>} Event loop lag in milliseconds
 */
async function getEventLoopLag() {
  return new Promise((resolve) => {
    const start = performance.now();
    setImmediate(() => {
      const lag = performance.now() - start;
      resolve(Math.round(lag * 100) / 100);
    });
  });
}
