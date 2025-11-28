/**
 * @fileoverview Performance Monitor Tests
 * Tests for performance metrics collection and monitoring
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import {
  PerformanceMonitor,
  startTimer,
  endTimer,
  getSystemMetrics,
  getAppMetrics,
  resetMetrics
} from '../../utils/performance-monitor.js';

describe('Performance Monitor', () => {
  let monitor;

  beforeEach(() => {
    monitor = new PerformanceMonitor();
    resetMetrics();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('Timer Functions', () => {
    it('should measure execution time accurately', () => {
      const timerId = startTimer('test-operation');

      // Simulate some work
      const start = Date.now();
      while (Date.now() - start < 10) {
        // Busy wait for 10ms
      }

      const duration = endTimer(timerId);
      expect(duration).toBeGreaterThanOrEqual(9); // Allow for timing variance
      expect(duration).toBeLessThan(50); // Should be close to 10ms
    });

    it('should handle multiple concurrent timers', () => {
      const timer1 = startTimer('operation1');
      const timer2 = startTimer('operation2');

      // Add a small delay to ensure measurable time passes
      const startTime = Date.now();
      while (Date.now() - startTime < 1) {
        // Busy wait for 1ms
      }

      const duration1 = endTimer(timer1);
      const duration2 = endTimer(timer2);

      expect(duration1).toBeGreaterThan(0);
      expect(duration2).toBeGreaterThan(0);
    });

    it('should return -1 for invalid timer IDs', () => {
      const duration = endTimer('nonexistent-timer');
      expect(duration).toBe(-1);
    });
  });

  describe('System Metrics Collection', () => {
    it('should collect memory usage metrics', async () => {
      const metrics = await getSystemMetrics();

      expect(metrics.memory).toBeDefined();
      expect(metrics.memory.heapUsed).toBeGreaterThan(0);
      expect(metrics.memory.heapTotal).toBeGreaterThan(0);
      expect(metrics.memory.external).toBeGreaterThanOrEqual(0);
      expect(metrics.memory.rss).toBeGreaterThan(0);
    });

    it('should collect CPU usage metrics', async () => {
      const metrics = await getSystemMetrics();

      expect(metrics.cpu).toBeDefined();
      expect(metrics.cpu.usage).toBeGreaterThanOrEqual(0);
      expect(metrics.cpu.usage).toBeLessThanOrEqual(100);
    });

    it('should collect uptime metrics', async () => {
      const metrics = await getSystemMetrics();

      expect(metrics.uptime).toBeDefined();
      expect(metrics.uptime.process).toBeGreaterThan(0);
      expect(metrics.uptime.system).toBeGreaterThan(0);
    });

    it('should include event loop lag', async () => {
      const metrics = await getSystemMetrics();

      expect(metrics.eventLoop).toBeDefined();
      expect(metrics.eventLoop.lag).toBeGreaterThanOrEqual(0);
    });
  });

  describe('Application Metrics', () => {
    it('should track request counts', () => {
      monitor.incrementCounter('requests.total');
      monitor.incrementCounter('requests.total');
      monitor.incrementCounter('requests.api');

      const metrics = getAppMetrics();
      expect(metrics.counters['requests.total']).toBe(2);
      expect(metrics.counters['requests.api']).toBe(1);
    });

    it('should track response times', () => {
      monitor.recordHistogram('response.time', 150);
      monitor.recordHistogram('response.time', 200);
      monitor.recordHistogram('response.time', 100);

      const metrics = getAppMetrics();
      const responseMetrics = metrics.histograms['response.time'];

      expect(responseMetrics.count).toBe(3);
      expect(responseMetrics.min).toBe(100);
      expect(responseMetrics.max).toBe(200);
      expect(responseMetrics.avg).toBe(150);
    });

    it('should track gauge values', () => {
      monitor.setGauge('connections.active', 5);
      monitor.setGauge('connections.active', 8);
      monitor.setGauge('memory.heap.used', 1024 * 1024);

      const metrics = getAppMetrics();
      expect(metrics.gauges['connections.active']).toBe(8);
      expect(metrics.gauges['memory.heap.used']).toBe(1024 * 1024);
    });
  });

  describe('HTTP Metrics Integration', () => {
    it('should track HTTP request metrics', () => {
      monitor.trackHttpRequest('GET', '/api/progress/save', 200, 150);
      monitor.trackHttpRequest('POST', '/api/progress/save', 201, 250);
      monitor.trackHttpRequest('GET', '/health', 200, 50);

      const metrics = getAppMetrics();

      // Check request counters
      expect(metrics.counters['http.requests.total']).toBe(3);
      expect(metrics.counters['http.requests.GET']).toBe(2);
      expect(metrics.counters['http.requests.POST']).toBe(1);

      // Check status code counters
      expect(metrics.counters['http.status.200']).toBe(2);
      expect(metrics.counters['http.status.201']).toBe(1);

      // Check response time histogram
      const responseTime = metrics.histograms['http.request.duration.seconds'];
      expect(responseTime.count).toBe(3);
      expect(responseTime.min).toBe(50 / 1000); // Convert to seconds as implementation does
      expect(responseTime.max).toBe(250 / 1000); // Convert to seconds as implementation does
    });

    it('should track error rates', () => {
      monitor.trackHttpRequest('GET', '/api/test', 200, 100);
      monitor.trackHttpRequest('GET', '/api/test', 500, 200);
      monitor.trackHttpRequest('POST', '/api/test', 400, 150);

      const metrics = getAppMetrics();

      expect(metrics.counters['http.requests.total']).toBe(3);
      expect(metrics.counters['http.status.2xx']).toBe(1);
      expect(metrics.counters['http.status.4xx']).toBe(1);
      expect(metrics.counters['http.status.5xx']).toBe(1);
    });
  });

  describe('Performance Monitoring', () => {
    it('should detect performance issues', () => {
      // Record some slow operations
      monitor.recordHistogram('response.time', 1000);
      monitor.recordHistogram('response.time', 1500);
      monitor.recordHistogram('response.time', 2000);

      const metrics = getAppMetrics();
      const issues = monitor.detectPerformanceIssues(metrics);

      expect(issues).toHaveLength(1);
      expect(issues[0].type).toBe('slow_response_time');
      expect(issues[0].severity).toBe('warning');
    });

    it('should detect memory issues', () => {
      // Simulate high memory usage
      monitor.setGauge('memory.heap.used', 500 * 1024 * 1024); // 500MB
      monitor.setGauge('memory.heap.total', 512 * 1024 * 1024); // 512MB

      const metrics = getAppMetrics();
      const issues = monitor.detectPerformanceIssues(metrics);

      expect(issues.some(issue => issue.type === 'high_memory_usage')).toBe(true);
    });
  });

  describe('Metrics Export', () => {
    it('should export metrics in Prometheus format', () => {
      monitor.incrementCounter('requests.total');
      monitor.recordHistogram('response.time', 150);
      monitor.setGauge('connections.active', 5);

      const prometheus = monitor.exportPrometheus();

      expect(prometheus).toContain('requests_total 1');
      expect(prometheus).toContain('response_time_sum');
      expect(prometheus).toContain('connections_active 5');
    });

    it('should export metrics in JSON format', () => {
      monitor.incrementCounter('requests.total');
      monitor.recordHistogram('response.time', 150);

      const json = monitor.exportJSON();
      const data = JSON.parse(json);

      expect(data.counters['requests.total']).toBe(1);
      expect(data.histograms['response.time'].count).toBe(1);
      expect(data.timestamp).toBeDefined();
    });
  });

  describe('Memory Management', () => {
    it('should clean up old metric data', () => {
      // Add many data points
      for (let i = 0; i < 1000; i++) {
        monitor.recordHistogram('test.metric', i);
      }

      const beforeCleanup = getAppMetrics();
      expect(beforeCleanup.histograms['test.metric'].count).toBe(1000);

      // Trigger cleanup
      monitor.cleanup();

      const afterCleanup = getAppMetrics();
      // Should keep recent data but reduce memory usage
      expect(afterCleanup.histograms['test.metric'].count).toBeLessThan(1000);
    });
  });
});
