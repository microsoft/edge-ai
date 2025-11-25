#!/usr/bin/env node

/**
 * @fileoverview Benchmark Runner
 * Main script for running performance benchmarks
 */

import { BenchmarkSuite, PerformanceBenchmark as _PerformanceBenchmark, MemoryTracker } from './performance-utils.js';
import { app } from '../app.js';
import supertest from 'supertest';

/**
 * API response time benchmarks
 */
async function apiResponseTimeBenchmarks(benchmark) {
  const request = supertest(app);
  const iterations = 100;

  // Health endpoint benchmark
  benchmark.start('health-check');
  for (let i = 0; i < iterations; i++) {
    await request.get('/api/health').expect(200);
  }
  benchmark.end();

  // Progress API benchmark
  benchmark.start('progress-api');
  for (let i = 0; i < iterations / 2; i++) {
    await request.get('/api/progress').expect(200);
  }
  benchmark.end();

  // Write operations benchmark
  benchmark.start('write-operations');
  for (let i = 0; i < 20; i++) {
    await request
      .post('/api/progress/kata-progress')
      .send({
        category: 'benchmark-test',
        currentStep: String(i % 5 + 1),
        totalSteps: 5,
        checkboxStates: { [i % 5 + 1]: true }
      })
      .expect(200);
  }
  benchmark.end();
}

/**
 * Memory usage benchmarks
 */
async function memoryUsageBenchmarks(benchmark) {
  const request = supertest(app);
  const memoryTracker = new MemoryTracker();

  memoryTracker.snapshot('baseline');

  // Sustained load
  benchmark.start('sustained-load');
  for (let i = 0; i < 500; i++) {
    await request.get('/api/health').expect(200);

    if (i % 100 === 0) {
      memoryTracker.snapshot(`iteration-${i}`);

      // Force garbage collection if available
      if (global.gc) {
        global.gc();
      }
    }
  }
  benchmark.end();

  memoryTracker.snapshot('final');

  // Add memory metrics to benchmark
  const memoryReport = memoryTracker.getReport();
  benchmark.addMeasurement('memory-growth-heap',
    parseFloat(memoryReport.growth?.heapUsed?.replace('MB', '') || '0'), 'MB');
  benchmark.addMeasurement('memory-growth-rss',
    parseFloat(memoryReport.growth?.rss?.replace('MB', '') || '0'), 'MB');
}

/**
 * Concurrency benchmarks
 */
async function concurrencyBenchmarks(benchmark) {
  const request = supertest(app);

  // Low concurrency
  benchmark.start('concurrency-10');
  const promises10 = Array.from({ length: 10 }, () =>
    request.get('/api/health').expect(200)
  );
  await Promise.all(promises10);
  benchmark.end();

  // Medium concurrency
  benchmark.start('concurrency-50');
  const promises50 = Array.from({ length: 50 }, () =>
    request.get('/api/health').expect(200)
  );
  await Promise.all(promises50);
  benchmark.end();

  // High concurrency
  benchmark.start('concurrency-100');
  const promises100 = Array.from({ length: 100 }, () =>
    request.get('/api/health').expect(200)
  );
  await Promise.all(promises100);
  benchmark.end();
}

/**
 * File operation benchmarks
 */
async function fileOperationBenchmarks(benchmark) {
  const request = supertest(app);

  // Sequential file operations
  benchmark.start('sequential-file-ops');
  for (let i = 0; i < 50; i++) {
    await request
      .post('/api/progress/kata-progress')
      .send({
        category: 'file-benchmark',
        currentStep: String(i % 10 + 1),
        totalSteps: 10,
        checkboxStates: { [i % 10 + 1]: true }
      })
      .expect(200);

    // Read it back
    await request.get('/api/progress').expect(200);
  }
  benchmark.end();

  // Concurrent file operations
  benchmark.start('concurrent-file-ops');
  const writePromises = Array.from({ length: 20 }, (_, i) =>
    request
      .post('/api/progress/kata-progress')
      .send({
        category: 'concurrent-benchmark',
        currentStep: String(i % 5 + 1),
        totalSteps: 5,
        checkboxStates: { [i % 5 + 1]: true }
      })
      .expect(200)
  );

  await Promise.all(writePromises);
  benchmark.end();
}

/**
 * Data processing benchmarks
 */
async function dataProcessingBenchmarks(benchmark) {
  const request = supertest(app);

  // Large data processing
  benchmark.start('large-data-processing');

  // Create a larger payload
  const largeCheckboxStates = {};
  for (let i = 1; i <= 100; i++) {
    largeCheckboxStates[i] = i % 2 === 0;
  }

  for (let i = 0; i < 10; i++) {
    await request
      .post('/api/progress/kata-progress')
      .send({
        category: 'large-data-test',
        currentStep: String(i + 1),
        totalSteps: 100,
        checkboxStates: largeCheckboxStates
      })
      .expect(200);
  }
  benchmark.end();

  // Complex data retrieval
  benchmark.start('complex-data-retrieval');
  for (let i = 0; i < 30; i++) {
    const response = await request.get('/api/progress').expect(200);

    // Simulate processing the response
    const data = response.body;
    const processed = JSON.stringify(data);
    benchmark.addMeasurement('response-size', processed.length, 'bytes');
  }
  benchmark.end();
}

/**
 * Main benchmark runner
 */
async function main() {
  console.log('🎯 Starting comprehensive performance benchmarks...');

  const suite = new BenchmarkSuite('Docs Server Performance');

  suite
    .add('API Response Times', apiResponseTimeBenchmarks)
    .add('Memory Usage', memoryUsageBenchmarks)
    .add('Concurrency', concurrencyBenchmarks)
    .add('File Operations', fileOperationBenchmarks)
    .add('Data Processing', dataProcessingBenchmarks);

  try {
    const results = await suite.run();

    console.log('\n🏁 Benchmark Suite Complete!');
    console.log(`\n📊 Summary:`);

    for (const [name, result] of results) {
      if (result.error) {
        console.log(`   ❌ ${name}: ${result.error}`);
      } else {
        console.log(`   ✅ ${name}: ${result.measurementCount} measurements`);
      }
    }

    // Save detailed results
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `benchmark-results-${timestamp}.json`;

    const allResults = Object.fromEntries(results);
    await import('fs').then(fs => {
      fs.writeFileSync(filename, JSON.stringify(allResults, null, 2));
      console.log(`\n💾 Detailed results saved to: ${filename}`);
    });

  } catch(_error) {
    console.error(`❌ Benchmark suite failed: ${_error.message}`);
    process.exit(1);
  }
}

// Handle command line arguments
const args = process.argv.slice(2);
if (args.includes('--help') || args.includes('-h')) {
  console.log(`
📊 Benchmark Runner Usage:

  node benchmark-runner.js              # Run all benchmarks
  node benchmark-runner.js --help       # Show this help

Benchmarks included:
  - API Response Times: Health check and progress API performance
  - Memory Usage: Memory consumption and leak detection
  - Concurrency: Performance under concurrent load
  - File Operations: File I/O performance
  - Data Processing: Large data handling performance

Environment variables:
  NODE_ENV=test                         # Recommended for benchmarking
  --expose-gc                          # Enable garbage collection (optional)
`);
  process.exit(0);
}

// Run benchmarks
main().catch(error => {
  console.error(`Fatal error: ${error.message}`);
  process.exit(1);
});

export { main };
