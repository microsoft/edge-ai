/**
 * @fileoverview Load Testing Scripts
 * Scripts for load testing the docs server using autocannon
 */

import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { spawn } from 'child_process';
import { writeFileSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * Load test configuration
 */
const LOAD_TESTS = {
  health: {
    url: 'http://localhost:3002/api/health',
    connections: 100,
    duration: 30,
    description: 'Health endpoint load test'
  },
  progress: {
    url: 'http://localhost:3002/api/progress',
    connections: 50,
    duration: 30,
    description: 'Progress API load test'
  },
  concurrent: {
    url: 'http://localhost:3002/api/health',
    connections: 200,
    duration: 60,
    description: 'High concurrency test'
  },
  sustained: {
    url: 'http://localhost:3002/api/progress',
    connections: 25,
    duration: 120,
    description: 'Sustained load test'
  }
};

/**
 * Performance targets
 */
const PERFORMANCE_TARGETS = {
  maxLatency: 200, // ms
  minThroughput: 100, // requests/second
  maxErrorRate: 1, // percentage
  maxMemoryGrowth: 100 // MB
};

/**
 * Run autocannon load test
 */
function runLoadTest(testName, config) {
  return new Promise((resolve, reject) => {
    console.log(`\n🚀 Starting ${config.description}...`);
    console.log(`   URL: ${config.url}`);
    console.log(`   Connections: ${config.connections}`);
    console.log(`   Duration: ${config.duration}s`);

    const args = [
      '-c', config.connections.toString(),
      '-d', config.duration.toString(),
      '--json',
      config.url
    ];

    const child = spawn('npx', ['autocannon', ...args], {
      stdio: ['pipe', 'pipe', 'pipe']
    });

    let output = '';
    let errorOutput = '';

    child.stdout.on('data', (data) => {
      output += data.toString();
    });

    child.stderr.on('data', (data) => {
      errorOutput += data.toString();
    });

    child.on('close', (code) => {
      if (code !== 0) {
        console.error(`❌ Load test failed: ${errorOutput}`);
        reject(new Error(`Load test failed with code ${code}`));
        return;
      }

      try {
        const result = JSON.parse(output);
        const analysis = analyzeResults(testName, result);

        console.log(`✅ ${config.description} completed`);
        printResults(analysis);

        resolve(analysis);
      } catch (error) {
        reject(new Error(`Failed to parse results: ${error.message}`));
      }
    });

    child.on('error', (error) => {
      reject(new Error(`Failed to start load test: ${error.message}`));
    });
  });
}

/**
 * Analyze load test results
 */
function analyzeResults(testName, rawResults) {
  const analysis = {
    testName,
    timestamp: new Date().toISOString(),
    duration: rawResults.duration,
    requests: {
      total: rawResults.requests.total,
      average: rawResults.requests.average,
      min: rawResults.requests.min,
      max: rawResults.requests.max
    },
    latency: {
      average: rawResults.latency.average,
      min: rawResults.latency.min,
      max: rawResults.latency.max,
      p50: rawResults.latency.p50,
      p95: rawResults.latency.p95,
      p99: rawResults.latency.p99
    },
    throughput: {
      average: rawResults.throughput.average,
      min: rawResults.throughput.min,
      max: rawResults.throughput.max
    },
    errors: rawResults.errors || 0,
    timeouts: rawResults.timeouts || 0,
    passed: true,
    issues: []
  };

  // Check against performance targets
  if (analysis.latency.average > PERFORMANCE_TARGETS.maxLatency) {
    analysis.passed = false;
    analysis.issues.push(`Average latency ${analysis.latency.average}ms exceeds target ${PERFORMANCE_TARGETS.maxLatency}ms`);
  }

  if (analysis.throughput.average < PERFORMANCE_TARGETS.minThroughput) {
    analysis.passed = false;
    analysis.issues.push(`Average throughput ${analysis.throughput.average} RPS below target ${PERFORMANCE_TARGETS.minThroughput} RPS`);
  }

  const errorRate = (analysis.errors / analysis.requests.total) * 100;
  if (errorRate > PERFORMANCE_TARGETS.maxErrorRate) {
    analysis.passed = false;
    analysis.issues.push(`Error rate ${errorRate.toFixed(2)}% exceeds target ${PERFORMANCE_TARGETS.maxErrorRate}%`);
  }

  return analysis;
}

/**
 * Print formatted results
 */
function printResults(analysis) {
  console.log(`\n📊 Results for ${analysis.testName}:`);
  console.log(`   Duration: ${analysis.duration}s`);
  console.log(`   Total Requests: ${analysis.requests.total}`);
  console.log(`   Average RPS: ${analysis.requests.average}`);
  console.log(`   Average Latency: ${analysis.latency.average}ms`);
  console.log(`   P95 Latency: ${analysis.latency.p95}ms`);
  console.log(`   P99 Latency: ${analysis.latency.p99}ms`);
  console.log(`   Average Throughput: ${analysis.throughput.average} RPS`);
  console.log(`   Errors: ${analysis.errors}`);
  console.log(`   Timeouts: ${analysis.timeouts}`);

  if (analysis.passed) {
    console.log(`   Status: ✅ PASSED`);
  } else {
    console.log(`   Status: ❌ FAILED`);
    analysis.issues.forEach(issue => {
      console.log(`   Issue: ${issue}`);
    });
  }
}

/**
 * Save results to file
 */
function saveResults(results) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = join(__dirname, `load-test-results-${timestamp}.json`);

  writeFileSync(filename, JSON.stringify(results, null, 2));
  console.log(`\n💾 Results saved to: ${filename}`);
}

/**
 * Run all load tests
 */
async function runAllTests() {
  console.log('🎯 Starting comprehensive load testing...');
  console.log(`📋 Performance Targets:`);
  console.log(`   Max Latency: ${PERFORMANCE_TARGETS.maxLatency}ms`);
  console.log(`   Min Throughput: ${PERFORMANCE_TARGETS.minThroughput} RPS`);
  console.log(`   Max Error Rate: ${PERFORMANCE_TARGETS.maxErrorRate}%`);

  const results = [];

  try {
    for (const [testName, config] of Object.entries(LOAD_TESTS)) {
      const result = await runLoadTest(testName, config);
      results.push(result);

      // Brief pause between tests
      await new Promise(resolve => setTimeout(resolve, 2000));
    }

    // Overall summary
    console.log('\n🏁 Load Testing Summary:');
    const passed = results.filter(r => r.passed).length;
    const total = results.length;
    console.log(`   Tests Passed: ${passed}/${total}`);

    if (passed === total) {
      console.log('   Overall Status: ✅ ALL TESTS PASSED');
    } else {
      console.log('   Overall Status: ❌ SOME TESTS FAILED');
    }

    saveResults(results);

  } catch (error) {
    console.error(`❌ Load testing failed: ${error.message}`);
    process.exit(1);
  }
}

/**
 * Run specific test
 */
async function runSpecificTest(testName) {
  if (!LOAD_TESTS[testName]) {
    console.error(`❌ Unknown test: ${testName}`);
    console.log(`Available tests: ${Object.keys(LOAD_TESTS).join(', ')}`);
    process.exit(1);
  }

  try {
    const result = await runLoadTest(testName, LOAD_TESTS[testName]);
    saveResults([result]);
  } catch (error) {
    console.error(`❌ Test failed: ${error.message}`);
    process.exit(1);
  }
}

// CLI interface
const args = process.argv.slice(2);
const testName = args[0];

if (testName) {
  runSpecificTest(testName);
} else {
  runAllTests();
}

export { runLoadTest, analyzeResults, PERFORMANCE_TARGETS };
