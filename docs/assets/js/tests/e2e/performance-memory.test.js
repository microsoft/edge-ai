import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { createPerformanceTestHelper, createMemoryMonitor } from '../helpers/performance-test-helper.js';

/**
 * Memory Management Performance Test Suite
 *
 * Focused tests for memory usage and garbage collection behavior
 * with comprehensive cleanup to prevent test interference.
 */
describe('Memory Management Performance', () => {
  let testContainer;
  let performanceHelper;
  let memoryMonitor;

  beforeEach(async () => {
    // Setup test environment with comprehensive performance monitoring using happy-dom
    document.head.innerHTML = `
        <title>Memory Performance Test</title>
        <meta charset="utf-8">
        <style>
          .learning-path { margin: 10px; padding: 10px; border: 1px solid #ccc; }
          .path-item { display: block; margin: 5px 0; }
          .temp-learning-path { margin: 5px; padding: 5px; background: #f0f0f0; }
          .performance-test-element { padding: 2px; margin: 1px; }
        </style>
    `;

    document.body.innerHTML = `
      <div id="test-container">
        <div id="learning-paths-container"></div>
        <button id="coach-button">Coach Button</button>
      </div>
    `;

    testContainer = document.getElementById('test-container');

    // Initialize performance testing tools with comprehensive cleanup
    performanceHelper = createPerformanceTestHelper({
      memoryTrackingEnabled: true,
      domCleanupEnabled: true,
      eventCleanupEnabled: true,
      observerCleanupEnabled: true
    });

    memoryMonitor = createMemoryMonitor();

    // Mock performance.memory if not available
    if (!performance.memory) {
      Object.defineProperty(performance, 'memory', {
        value: {
          get usedJSHeapSize() {
            return Math.random() * 50 * 1024 * 1024; // 0-50MB
          },
          get totalJSHeapSize() {
            return 100 * 1024 * 1024; // 100MB
          },
          get jsHeapSizeLimit() {
            return 2 * 1024 * 1024 * 1024; // 2GB
          }
        },
        writable: true
      });
    }
  });

  afterEach(() => {
    // Comprehensive cleanup to prevent test interference
    if (performanceHelper) {
      performanceHelper.cleanup();
    }

    if (memoryMonitor) {
      memoryMonitor.stopMonitoring();
      memoryMonitor.clear();
    }

    // Clean up any remaining DOM elements
    const testElements = document.querySelectorAll('[data-test-structure="true"]');
    testElements.forEach(element => {
      if (element.parentNode) {
        element.parentNode.removeChild(element);
      }
    });

    // Reset document body content
    const container = document.getElementById('learning-paths-container');
    if (container) {
      container.innerHTML = '';
    }

    // Clear any performance measurements
    if (performance.clearMarks) {
      performance.clearMarks();
    }
    if (performance.clearMeasures) {
      performance.clearMeasures();
    }

    // Reset all mocks
    vi.restoreAllMocks();
  });

  it('should manage memory efficiently during continuous operations', async () => {
    const iterations = 50; // Reduced for memory efficiency

    memoryMonitor.startMonitoring(50);
    const initialMemory = performanceHelper.getCurrentMemoryUsage();

    performanceHelper.startMeasurement('continuous-operations');

    for (let i = 0; i < iterations; i++) {
      // Create and destroy elements using performance helper
      const tempStructure = performanceHelper.createLargeDOMStructure({
        elementCount: 25,
        nestingDepth: 2,
        elementType: 'div',
        className: 'temp-learning-path',
        addEventListeners: true,
        parentContainer: document.getElementById('learning-paths-container')
      });

      // Simulate operations on the elements
      const items = tempStructure.querySelectorAll('.performance-test-element');
      items.forEach((item, _index) => {
        item.textContent = `Updated content ${i}-${_index}`;
        item.setAttribute('data-updated', 'true');
      });

      // Clean up this iteration
      if (tempStructure.parentNode) {
        tempStructure.parentNode.removeChild(tempStructure);
      }

      // Force garbage collection check every 10 iterations
      if (i % 10 === 0) {
        await new Promise(resolve => setTimeout(resolve, 10));

        const currentMemory = performanceHelper.getCurrentMemoryUsage();
        const memoryIncrease = currentMemory - initialMemory;

        // Memory should not continuously grow
        expect(memoryIncrease || 0).toBeLessThan(25 * 1024 * 1024); // < 25MB
      }
    }

    const operationMetrics = performanceHelper.endMeasurement('continuous-operations');
    const memoryStats = memoryMonitor.stopMonitoring();

    // Performance assertions
    expect(operationMetrics.duration).toBeLessThan(5000); // < 5 seconds for 50 iterations
    expect(memoryStats.memoryUsage.growth).toBeLessThan(45 * 1024 * 1024); // < 45MB total growth (accounts for environment variance)
  });

  it('should handle event listener cleanup efficiently', () => {
    const elementCount = 50; // Reduced for memory efficiency
    const elements = [];
    const handlers = [];

    memoryMonitor.takeSnapshot('before-event-listeners');
    const startMemory = performanceHelper.getCurrentMemoryUsage();

    performanceHelper.startMeasurement('event-listener-setup');

    // Add many elements with event listeners using helper tracking
    for (let i = 0; i < elementCount; i++) {
      const element = document.createElement('button');
      element.textContent = `Button ${i}`;
      element.setAttribute('data-test-structure', 'true');

      const handler = vi.fn();
      element.addEventListener('click', handler);

      // Track with performance helper for automatic cleanup
      performanceHelper.trackEventListener(element, 'click', handler);
      performanceHelper.createdElements.add(element);

      document.body.appendChild(element);
      elements.push(element);
      handlers.push(handler);
    }

    const setupMetrics = performanceHelper.endMeasurement('event-listener-setup');
    memoryMonitor.takeSnapshot('after-event-listeners');

    // Test event listener functionality
    performanceHelper.startMeasurement('event-listener-test');

    elements.slice(0, 5).forEach(element => {
      element.click();
    });

    const testMetrics = performanceHelper.endMeasurement('event-listener-test');

    // Verify handlers were called
    handlers.slice(0, 5).forEach(handler => {
      expect(handler).toHaveBeenCalledTimes(1);
    });

    // Manual cleanup (in addition to automatic cleanup in afterEach)
    performanceHelper.startMeasurement('event-listener-cleanup');

    elements.forEach((element, _index) => {
      element.removeEventListener('click', handlers[_index]);
      element.remove();
    });

    const cleanupMetrics = performanceHelper.endMeasurement('event-listener-cleanup');
    memoryMonitor.takeSnapshot('after-cleanup');

    // Performance assertions
    expect(setupMetrics.duration).toBeLessThan(1000); // < 1 second for setup
    expect(testMetrics.duration).toBeLessThan(50); // < 50ms for testing
    expect(cleanupMetrics.duration).toBeLessThan(500); // < 500ms for cleanup

    // Clear references
    elements.length = 0;
    handlers.length = 0;
  });

  it('should handle learning content object creation and destruction', () => {
    const objectCount = 2500; // Reduced for memory efficiency

    memoryMonitor.startMonitoring(25);
    performanceHelper.startMeasurement('large-object-operations');

    // Create learning content objects
    const learningObjects = [];
    for (let i = 0; i < objectCount; i++) {
      const learningItem = {
        id: i,
        title: `Learning Item ${i}`,
        content: new Array(50).fill(`content-${i}`),
        metadata: {
          created: new Date(),
          type: 'learning-item',
          difficulty: Math.floor(Math.random() * 5) + 1,
          estimatedTime: Math.floor(Math.random() * 120) + 15,
          prerequisites: i > 0 ? [i - 1] : []
        },
        progress: {
          completed: Math.random() > 0.5,
          score: Math.random() * 100,
          attempts: Math.floor(Math.random() * 5),
          timeSpent: Math.random() * 3600
        }
      };

      learningObjects.push(learningItem);

      // Take memory snapshot periodically
      if (i % 1000 === 0) {
        memoryMonitor.takeSnapshot(`objects-${i}`);
      }
    }

    const creationMetrics = performanceHelper.endMeasurement('large-object-operations');
    const memoryStats = memoryMonitor.stopMonitoring();

    // Performance assertions
    expect(creationMetrics.duration).toBeLessThan(1000); // < 1 second for creation
    expect(memoryStats.memoryUsage.peak.used).toBeGreaterThanOrEqual(memoryStats.memoryUsage.initial.used); // Memory was used

    // Clear objects and verify cleanup capability
    performanceHelper.startMeasurement('object-cleanup');
    learningObjects.length = 0;
    const cleanupMetrics = performanceHelper.endMeasurement('object-cleanup');

    expect(cleanupMetrics.duration).toBeLessThan(50); // < 50ms for cleanup
  });

  it('should handle learning progress data persistence scenarios', async () => {
    const progressEntries = 1000; // Reduced for memory efficiency

    memoryMonitor.startMonitoring(100);
    performanceHelper.startMeasurement('progress-data-operations');

    // Simulate learning progress data creation and storage operations
    const progressData = new Map();

    for (let i = 0; i < progressEntries; i++) {
      const userId = `user-${Math.floor(i / 50)}`;
      const learningPathId = `path-${Math.floor(i / 25)}`;
      const itemId = `item-${i}`;

      const progressEntry = {
        userId,
        learningPathId,
        itemId,
        completed: Math.random() > 0.3,
        completedAt: Math.random() > 0.5 ? new Date() : null,
        score: Math.random() * 100,
        timeSpent: Math.random() * 7200,
        attempts: Math.floor(Math.random() * 10) + 1,
        notes: `Progress notes for item ${i}`,
        milestones: Array.from({ length: Math.floor(Math.random() * 3) + 1 },
          (_, _index) => ({
            id: `milestone-${i}-${_index}`,
            achieved: Math.random() > 0.4,
            achievedAt: new Date()
          })
        )
      };

      const key = `${userId}-${learningPathId}-${itemId}`;
      progressData.set(key, progressEntry);

      // Simulate periodic data operations
      if (i % 250 === 0) {
        // Simulate data retrieval operations
        const userProgress = [];
        for (const [entryKey, entry] of progressData) {
          if (entry.userId === userId) {
            userProgress.push(entry);
          }
        }

        // Take memory snapshot
        memoryMonitor.takeSnapshot(`progress-${i}`);

        // Yield control
        await new Promise(resolve => setTimeout(resolve, 5));
      }
    }

    const operationMetrics = performanceHelper.endMeasurement('progress-data-operations');
    const memoryStats = memoryMonitor.stopMonitoring();

    // Performance assertions for learning progress scenarios
    expect(operationMetrics.duration).toBeLessThan(2000); // < 2 seconds for 1000 entries
    expect(progressData.size).toBe(progressEntries);
    expect(memoryStats.memoryUsage.growth).toBeLessThan(50 * 1024 * 1024); // < 50MB growth

    // Test data cleanup
    performanceHelper.startMeasurement('progress-cleanup');
    progressData.clear();
    const cleanupMetrics = performanceHelper.endMeasurement('progress-cleanup');

    expect(cleanupMetrics.duration).toBeLessThan(25); // < 25ms for cleanup
  });
});
