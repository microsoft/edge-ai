/**
 * @fileoverview Performance Benchmark Utilities
 * Utilities for measuring and reporting performance metrics
 */

import { performance } from 'perf_hooks';
import { writeFileSync, readFileSync as _readFileSync } from 'fs';
import { join as _join } from 'path';

/**
 * Performance benchmark class
 */
export class PerformanceBenchmark {
  constructor(name) {
    this.name = name;
    this.measurements = [];
    this.startTime = null;
    this.metadata = {
      nodeVersion: process.version,
      platform: process.platform,
      arch: process.arch,
      timestamp: new Date().toISOString()
    };
  }

  /**
   * Start timing a measurement
   */
  start(label = 'default') {
    this.startTime = performance.now();
    this.currentLabel = label;
    return this;
  }

  /**
   * End timing and record measurement
   */
  end(data = {}) {
    if (!this.startTime) {
      throw new Error('Must call start() before end()');
    }

    const endTime = performance.now();
    const duration = endTime - this.startTime;

    this.measurements.push({
      label: this.currentLabel,
      duration,
      timestamp: new Date().toISOString(),
      memory: process.memoryUsage(),
      cpu: process.cpuUsage(),
      ...data
    });

    this.startTime = null;
    return duration;
  }

  /**
   * Add measurement without timing
   */
  addMeasurement(label, value, unit = 'ms', data = {}) {
    this.measurements.push({
      label,
      value,
      unit,
      timestamp: new Date().toISOString(),
      memory: process.memoryUsage(),
      ...data
    });
  }

  /**
   * Get statistics for measurements with the same label
   */
  getStats(label = null) {
    const filtered = label
      ? this.measurements.filter(m => m.label === label)
      : this.measurements;

    if (filtered.length === 0) {
      return null;
    }

    const values = filtered.map(m => m.duration || m.value).filter(v => typeof v === 'number');

    if (values.length === 0) {
      return null;
    }

    values.sort((a, b) => a - b);

    return {
      count: values.length,
      min: Math.min(...values),
      max: Math.max(...values),
      average: values.reduce((a, b) => a + b) / values.length,
      median: values[Math.floor(values.length / 2)],
      p95: values[Math.floor(values.length * 0.95)],
      p99: values[Math.floor(values.length * 0.99)]
    };
  }

  /**
   * Generate performance report
   */
  getReport() {
    const labels = [...new Set(this.measurements.map(m => m.label))];
    const stats = {};

    labels.forEach(label => {
      stats[label] = this.getStats(label);
    });

    return {
      name: this.name,
      metadata: this.metadata,
      measurementCount: this.measurements.length,
      stats,
      rawMeasurements: this.measurements
    };
  }

  /**
   * Save report to file
   */
  saveReport(filename = null) {
    if (!filename) {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      filename = `benchmark-${this.name}-${timestamp}.json`;
    }

    const report = this.getReport();
    writeFileSync(filename, JSON.stringify(report, null, 2));
    return filename;
  }

  /**
   * Print report to console
   */
  printReport() {
    const report = this.getReport();

    console.log(`\n📊 Performance Report: ${report.name}`);
    console.log(`   Measurements: ${report.measurementCount}`);
    console.log(`   Platform: ${report.metadata.platform} ${report.metadata.arch}`);
    console.log(`   Node.js: ${report.metadata.nodeVersion}`);

    Object.entries(report.stats).forEach(([label, stats]) => {
      if (stats) {
        console.log(`\n   ${label}:`);
        console.log(`     Count: ${stats.count}`);
        console.log(`     Average: ${stats.average.toFixed(2)}ms`);
        console.log(`     Median: ${stats.median.toFixed(2)}ms`);
        console.log(`     Min: ${stats.min.toFixed(2)}ms`);
        console.log(`     Max: ${stats.max.toFixed(2)}ms`);
        console.log(`     P95: ${stats.p95.toFixed(2)}ms`);
        console.log(`     P99: ${stats.p99.toFixed(2)}ms`);
      }
    });
  }
}

/**
 * Memory usage tracker
 */
export class MemoryTracker {
  constructor() {
    this.snapshots = [];
    this.baseline = null;
  }

  /**
   * Take memory snapshot
   */
  snapshot(label = 'snapshot') {
    const usage = process.memoryUsage();
    const snapshot = {
      label,
      timestamp: new Date().toISOString(),
      ...usage
    };

    this.snapshots.push(snapshot);

    if (!this.baseline) {
      this.baseline = snapshot;
    }

    return snapshot;
  }

  /**
   * Get memory growth since baseline
   */
  getGrowth() {
    if (!this.baseline || this.snapshots.length === 0) {
      return null;
    }

    const latest = this.snapshots[this.snapshots.length - 1];

    return {
      heapUsed: latest.heapUsed - this.baseline.heapUsed,
      heapTotal: latest.heapTotal - this.baseline.heapTotal,
      external: latest.external - this.baseline.external,
      rss: latest.rss - this.baseline.rss
    };
  }

  /**
   * Get formatted memory report
   */
  getReport() {
    if (this.snapshots.length === 0) {
      return 'No memory snapshots taken';
    }

    const growth = this.getGrowth();
    const latest = this.snapshots[this.snapshots.length - 1];

    return {
      snapshots: this.snapshots.length,
      current: {
        heapUsed: `${(latest.heapUsed / 1024 / 1024).toFixed(2) }MB`,
        heapTotal: `${(latest.heapTotal / 1024 / 1024).toFixed(2) }MB`,
        external: `${(latest.external / 1024 / 1024).toFixed(2) }MB`,
        rss: `${(latest.rss / 1024 / 1024).toFixed(2) }MB`
      },
      growth: growth ? {
        heapUsed: `${(growth.heapUsed / 1024 / 1024).toFixed(2) }MB`,
        heapTotal: `${(growth.heapTotal / 1024 / 1024).toFixed(2) }MB`,
        external: `${(growth.external / 1024 / 1024).toFixed(2) }MB`,
        rss: `${(growth.rss / 1024 / 1024).toFixed(2) }MB`
      } : null
    };
  }

  /**
   * Print memory report
   */
  printReport() {
    const report = this.getReport();

    if (typeof report === 'string') {
      console.log(report);
      return;
    }

    console.log(`\n🧠 Memory Report:`);
    console.log(`   Snapshots: ${report.snapshots}`);
    console.log(`   Current Usage:`);
    console.log(`     Heap Used: ${report.current.heapUsed}`);
    console.log(`     Heap Total: ${report.current.heapTotal}`);
    console.log(`     External: ${report.current.external}`);
    console.log(`     RSS: ${report.current.rss}`);

    if (report.growth) {
      console.log(`   Growth Since Baseline:`);
      console.log(`     Heap Used: ${report.growth.heapUsed}`);
      console.log(`     Heap Total: ${report.growth.heapTotal}`);
      console.log(`     External: ${report.growth.external}`);
      console.log(`     RSS: ${report.growth.rss}`);
    }
  }
}

/**
 * CPU usage tracker
 */
export class CPUTracker {
  constructor() {
    this.measurements = [];
    this.startUsage = null;
  }

  /**
   * Start CPU measurement
   */
  start() {
    this.startUsage = process.cpuUsage();
    this.startTime = performance.now();
    return this;
  }

  /**
   * End CPU measurement
   */
  end(label = 'measurement') {
    if (!this.startUsage) {
      throw new Error('Must call start() before end()');
    }

    const endUsage = process.cpuUsage(this.startUsage);
    const endTime = performance.now();
    const wallTime = endTime - this.startTime;

    const measurement = {
      label,
      wallTime,
      userTime: endUsage.user / 1000, // Convert to ms
      systemTime: endUsage.system / 1000,
      totalCpuTime: (endUsage.user + endUsage.system) / 1000,
      cpuUtilization: ((endUsage.user + endUsage.system) / 1000 / wallTime) * 100,
      timestamp: new Date().toISOString()
    };

    this.measurements.push(measurement);
    this.startUsage = null;

    return measurement;
  }

  /**
   * Get CPU statistics
   */
  getStats() {
    if (this.measurements.length === 0) {
      return null;
    }

    const cpuUtilizations = this.measurements.map(m => m.cpuUtilization);
    const wallTimes = this.measurements.map(m => m.wallTime);
    const cpuTimes = this.measurements.map(m => m.totalCpuTime);

    return {
      count: this.measurements.length,
      avgCpuUtilization: cpuUtilizations.reduce((a, b) => a + b) / cpuUtilizations.length,
      maxCpuUtilization: Math.max(...cpuUtilizations),
      avgWallTime: wallTimes.reduce((a, b) => a + b) / wallTimes.length,
      avgCpuTime: cpuTimes.reduce((a, b) => a + b) / cpuTimes.length
    };
  }

  /**
   * Print CPU report
   */
  printReport() {
    const stats = this.getStats();

    if (!stats) {
      console.log('No CPU measurements taken');
      return;
    }

    console.log(`\n⚡ CPU Report:`);
    console.log(`   Measurements: ${stats.count}`);
    console.log(`   Average CPU Utilization: ${stats.avgCpuUtilization.toFixed(2)}%`);
    console.log(`   Max CPU Utilization: ${stats.maxCpuUtilization.toFixed(2)}%`);
    console.log(`   Average Wall Time: ${stats.avgWallTime.toFixed(2)}ms`);
    console.log(`   Average CPU Time: ${stats.avgCpuTime.toFixed(2)}ms`);
  }
}

/**
 * Comprehensive benchmark runner
 */
export class BenchmarkSuite {
  constructor(name) {
    this.name = name;
    this.benchmarks = new Map();
  }

  /**
   * Add benchmark
   */
  add(name, fn) {
    this.benchmarks.set(name, fn);
    return this;
  }

  /**
   * Run all benchmarks
   */
  async run() {
    console.log(`🚀 Running benchmark suite: ${this.name}`);

    const results = new Map();

    for (const [name, fn] of this.benchmarks) {
      console.log(`\n🔄 Running benchmark: ${name}`);

      const benchmark = new PerformanceBenchmark(name);
      const memoryTracker = new MemoryTracker();
      const cpuTracker = new CPUTracker();

      try {
        memoryTracker.snapshot('start');
        cpuTracker.start();

        await fn(benchmark);

        const cpuResult = cpuTracker.end();
        memoryTracker.snapshot('end');

        const report = benchmark.getReport();
        report.memory = memoryTracker.getReport();
        report.cpu = cpuResult;

        results.set(name, report);

        benchmark.printReport();
        memoryTracker.printReport();
        console.log(`   CPU Utilization: ${cpuResult.cpuUtilization.toFixed(2)}%`);

      } catch (error) {
        console.error(`❌ Benchmark ${name} failed: ${error.message}`);
        results.set(name, { error: error.message });
      }
    }

    return results;
  }
}

/**
 * Utility functions
 */
export function formatBytes(bytes) {
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  if (bytes === 0) {return '0 Bytes';}

  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return `${parseFloat((bytes / Math.pow(1024, i)).toFixed(2)) } ${ sizes[i]}`;
}

export function formatDuration(ms) {
  if (ms < 1000) {return `${ms.toFixed(2)}ms`;}
  if (ms < 60000) {return `${(ms / 1000).toFixed(2)}s`;}
  return `${(ms / 60000).toFixed(2)}m`;
}
