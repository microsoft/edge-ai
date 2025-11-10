/**
 * TOC Chevron Manager Test Suite
 *
 * Basic integration tests for the TOC Chevron Manager functionality
 * These tests can be run in the browser console or integrated with testing frameworks
 *
 * @version 1.0.0
 * @since 2025-08-27
 */

/**
 * Test suite for TOC Chevron Manager
 */
class TOCChevronManagerTests {
  constructor() {
    this.manager = null;
    this.testResults = [];
    this.originalConsoleLog = console.log;
    this.capturedLogs = [];
  }

  /**
   * Initialize test environment
   */
  async init() {
    console.log('🚀 Starting TOC Chevron Manager Tests');

    // Wait for manager to be available
    if (typeof window.tocManager !== 'undefined') {
      this.manager = window.tocManager;
    } else if (typeof window.TOCChevronManager !== 'undefined') {
      this.manager = new window.TOCChevronManager({ debug: true });
    } else {
      throw new Error('TOC Chevron Manager not found. Make sure it is loaded.');
    }

    // Enable debug mode for testing
    this.manager.setDebug(true);

    console.log('✅ Test environment initialized');
    return this;
  }

  /**
   * Capture console logs for testing
   */
  startLogCapture() {
    this.capturedLogs = [];
    console.log = (...args) => {
      this.capturedLogs.push(args.join(' '));
      this.originalConsoleLog(...args);
    };
  }

  /**
   * Stop capturing console logs
   */
  stopLogCapture() {
    console.log = this.originalConsoleLog;
    return this.capturedLogs;
  }

  /**
   * Assert helper
   */
  assert(condition, message) {
    if (condition) {
      this.testResults.push({ test: message, result: '✅ PASS' });
      console.log(`✅ ${message}`);
    } else {
      this.testResults.push({ test: message, result: '❌ FAIL' });
      console.error(`❌ ${message}`);
    }
    return condition;
  }

  /**
   * Test 1: Manager initialization
   */
  testInitialization() {
    console.log('\n📋 Test 1: Manager Initialization');

    const state = this.manager.getState();
    this.assert(state.isInitialized, 'Manager should be initialized');
    this.assert(!state.isDestroyed, 'Manager should not be destroyed');
    this.assert(state.debug, 'Debug mode should be enabled');
    this.assert(state.tocItemsCount > 0, 'Should find TOC items');
    this.assert(state.headersCount > 0, 'Should find headers');
    this.assert(state.mappingsCount > 0, 'Should create header-TOC mappings');
  }

  /**
   * Test 2: Debug functionality
   */
  testDebugFunctionality() {
    console.log('\n📋 Test 2: Debug Functionality');

    // Reset stats for clean test
    this.manager.resetDebugStats();

    const initialStats = this.manager.getDebugStats();
    this.assert(initialStats.intersectionEvents === 0, 'Initial intersection events should be 0');
    this.assert(initialStats.activeChanges === 0, 'Initial active changes should be 0');

    // Test logging
    this.startLogCapture();
    this.manager.logDebugStats();
    const logs = this.stopLogCapture();
    this.assert(logs.length > 0, 'Debug stats logging should produce output');
  }

  /**
   * Test 3: Highlight testing
   */
  testHighlightFunctionality() {
    console.log('\n📋 Test 3: Highlight Functionality');

    const state = this.manager.getState();
    if (state.headersCount > 0) {
      // Test highlighting first section
      this.startLogCapture();
      this.manager.testHighlight(0);
      const logs = this.stopLogCapture();

      this.assert(logs.some(log => log.includes('Testing highlight')), 'Should log highlight test');

      // Check if stats increased
      const stats = this.manager.getDebugStats();
      this.assert(stats.activeChanges > 0, 'Active changes count should increase');
    }
  }

  /**
   * Test 4: Auto-scroll testing
   */
  testAutoScrollFunctionality() {
    console.log('\n📋 Test 4: Auto-scroll Functionality');

    const state = this.manager.getState();
    if (state.tocItemsCount > 0) {
      // Test auto-scroll to first TOC item
      this.startLogCapture();
      this.manager.testAutoScroll(0);
      const logs = this.stopLogCapture();

      this.assert(logs.some(log => log.includes('Testing auto-scroll')), 'Should log auto-scroll test');

      // Check if stats increased
      const stats = this.manager.getDebugStats();
      this.assert(stats.scrollSyncs > 0, 'Scroll syncs count should increase');
    }
  }

  /**
   * Test 5: Performance monitoring
   */
  testPerformanceMonitoring() {
    console.log('\n📋 Test 5: Performance Monitoring');

    const stats = this.manager.getDebugStats();
    this.assert(typeof stats.runtime === 'string', 'Runtime should be a formatted string');
    this.assert(typeof stats.performanceMetrics === 'object', 'Performance metrics should be available');
    this.assert(Object.prototype.hasOwnProperty.call(stats.performanceMetrics, 'lastUpdate'), 'Should track last update time');
    this.assert(Object.prototype.hasOwnProperty.call(stats.performanceMetrics, 'frameCount'), 'Should track frame count');
    this.assert(Object.prototype.hasOwnProperty.call(stats.performanceMetrics, 'queueSize'), 'Should track queue size');
  }

  /**
   * Test 6: State management
   */
  testStateManagement() {
    console.log('\n📋 Test 6: State Management');

    // Test debug toggle
    this.manager.setDebug(false);
    let state = this.manager.getState();
    this.assert(!state.debug, 'Debug mode should be disabled');

    this.manager.setDebug(true);
    state = this.manager.getState();
    this.assert(state.debug, 'Debug mode should be re-enabled');

    // Test reinit
    this.manager.reinit();
    state = this.manager.getState();
    this.assert(state.isInitialized, 'Manager should be re-initialized');
  }

  /**
   * Run all tests
   */
  async runAllTests() {
    try {
      await this.init();

      this.testInitialization();
      this.testDebugFunctionality();
      this.testHighlightFunctionality();
      this.testAutoScrollFunctionality();
      this.testPerformanceMonitoring();
      this.testStateManagement();

      this.printSummary();

    } catch (_error) {
      console.error('❌ Test suite failed:', _error);
    }
  }

  /**
   * Print test summary
   */
  printSummary() {
    console.log('\n📊 Test Summary');
    console.log('================');

    const passed = this.testResults.filter(r => r.result.includes('PASS')).length;
    const failed = this.testResults.filter(r => r.result.includes('FAIL')).length;
    const total = this.testResults.length;

    console.log(`Total Tests: ${total}`);
    console.log(`Passed: ${passed} ✅`);
    console.log(`Failed: ${failed} ❌`);
    console.log(`Success Rate: ${Math.round((passed / total) * 100)}%`);

    if (failed > 0) {
      console.log('\n❌ Failed Tests:');
      this.testResults
        .filter(r => r.result.includes('FAIL'))
        .forEach(r => console.log(`  - ${r.test}`));
    }

    console.table(this.testResults);
  }
}

// Auto-run tests if in browser environment
if (typeof window !== 'undefined' && window.location) {
  // Make test suite available globally
  window.TOCChevronManagerTests = TOCChevronManagerTests;

  // Auto-run tests when debug parameter is present
  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.get('test-toc') === 'true') {
    document.addEventListener('DOMContentLoaded', async () => {
      // Wait a bit for everything to load
      setTimeout(async () => {
        const tests = new TOCChevronManagerTests();
        await tests.runAllTests();
      }, 2000);
    });
  }
}

// Export for use as ES6 module
if (typeof module !== 'undefined' && module.exports) {
  module.exports = TOCChevronManagerTests;
}
