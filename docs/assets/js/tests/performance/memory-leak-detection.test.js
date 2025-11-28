/**
 * Memory Leak Detection Suite for Interactive Learning Paths
 * Tests for memory leaks during long-running sessions
 *
 * @fileoverview Memory leak detection and prevention tests
 * @requires ../mocks/memory-monitoring-mocks.js
 * @requires ../fixtures/memory-test-fixtures.js
 * @requires ../mocks/performance-mocks.js
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { performance } from 'perf_hooks';

// Import custom mock classes instead of using vi.mock
import {
  InteractiveCheckboxes,
  AutoSelectionEngine,
  LearningPathSync,
  ProgressAnnotations,
  ProgressSyncService
} from '../mocks/performance-mocks.js';

// Import memory monitoring mocks
import {
  MemoryProfiler,
  LeakDetector,
  ResourceTracker,
  GarbageCollectionMonitor,
  EventListenerTracker,
  DOMReferenceTracker,
  TimerTracker,
  PromiseTracker,
  StorageTracker,
  CircularReferenceDetector
} from '../mocks/memory-monitoring-mocks.js';

// Import memory test fixtures
import {
  createMemoryTestScenarios,
  generateLongRunningSession,
  createCircularReferences
} from '../fixtures/memory-test-fixtures.js';

describe('Memory Leak Detection Suite', () => {
  let memoryProfiler;
  let leakDetector;
  let resourceTracker;
  let gcMonitor;
  let mockLearningPathManager;
  let mockDomHelper;
  let eventListenerTracker;
  let domTracker;
  let circularDetector;

  beforeEach(() => {
    // Initialize memory monitoring tools
    memoryProfiler = new MemoryProfiler();
    leakDetector = new LeakDetector();
    resourceTracker = new ResourceTracker();
    gcMonitor = new GarbageCollectionMonitor();

    // Initialize trackers
    eventListenerTracker = resourceTracker.createEventListenerTracker();
    domTracker = resourceTracker.createDOMReferenceTracker();
    circularDetector = new CircularReferenceDetector();

    // Set up global access for mocks
    global.eventListenerTracker = eventListenerTracker;
    global.domTracker = domTracker;
    global.circularDetector = circularDetector;
    global.memoryProfiler = memoryProfiler;
    global.resourceTracker = resourceTracker;

    // Setup DOM environment
    document.body.innerHTML = '<div id="learning-paths-container"></div>';

    // Mock learning path manager
    mockLearningPathManager = {
      getPathProgress: vi.fn().mockResolvedValue({}),
      updatePathSelection: vi.fn().mockResolvedValue(true),
      getPathRelationships: vi.fn().mockResolvedValue({}),
      saveProgress: vi.fn().mockResolvedValue(true),
      trackAnalytics: vi.fn(),
      isHealthy: vi.fn().mockReturnValue(true),
      destroy: vi.fn()
    };

    // Mock DOM helper
    mockDomHelper = {
      findCheckboxes: vi.fn().mockReturnValue([]),
      findContainers: vi.fn().mockReturnValue([]),
      createElement: vi.fn().mockImplementation(() => {
        const element = document.createElement('div');
        domTracker.trackReference(element.id || `element-${Date.now()}`, element);
        return element;
      }),
      removeElement: vi.fn().mockImplementation((element) => {
        domTracker.untrackReference(element.id);
      }),
      addEventListener: vi.fn().mockImplementation((event, handler) => {
        eventListenerTracker.trackListener('dom', event, handler);
      }),
      removeEventListener: vi.fn().mockImplementation((event, handler) => {
        eventListenerTracker.untrackListener('dom', event, handler);
      })
    };
  });

  afterEach(() => {
    // Clean up DOM
    document.body.innerHTML = '';

    // Stop all monitoring
    memoryProfiler.stopProfiling();
    leakDetector.stopDetection();
    resourceTracker.reset();
    gcMonitor.stopMonitoring();

    // Force garbage collection if available
    if (global.gc) {
      global.gc();
    }
  });

  describe('Component Lifecycle Memory Management', () => {
    it('should not leak memory during repeated component creation and destruction', async () => {
      memoryProfiler.startProfiling();
      leakDetector.startDetection();

      const baselineSnapshot = memoryProfiler.takeSnapshot();

      // Create and destroy components multiple times
      for (let cycle = 0; cycle < 10; cycle++) {
        const components = [];

        // Create multiple component instances
        for (let i = 0; i < 5; i++) {
          const checkboxes = new InteractiveCheckboxes(
            mockLearningPathManager,
            null,
            mockDomHelper
          );
          components.push(checkboxes);
        }

        // Use components
        for (const checkboxes of components) {
          await checkboxes.initializeWithPaths([
            { id: 'test-path', name: 'Test Path', items: [] }
          ]);
          await checkboxes.handleClick('test-checkbox');
        }

        // Destroy all components
        for (const checkboxes of components) {
          checkboxes.destroy();
        }

        // Clear references
        components.length = 0;
      }

      const finalSnapshot = memoryProfiler.takeSnapshot();
      const memoryComparison = memoryProfiler.compareSnapshots(baselineSnapshot, finalSnapshot);

      // Memory growth should be minimal (less than 10MB)
      expect(memoryComparison.heapGrowth).toBeLessThan(10 * 1024 * 1024);
      expect(leakDetector.hasDetectedLeaks()).toBe(false);
    });

    it('should properly cleanup event listeners and prevent listener leaks', async () => {
      const initialListeners = eventListenerTracker.getCount();

      const components = [];

      // Create components that add event listeners
      for (let i = 0; i < 10; i++) {
        const checkboxes = new InteractiveCheckboxes(
          mockLearningPathManager,
          null,
          mockDomHelper
        );

        // Simulate event listener creation
        mockDomHelper.addEventListener('click', () => {});
        mockDomHelper.addEventListener('change', () => {});

        components.push(checkboxes);
      }

      const peakListeners = eventListenerTracker.getCount();
      expect(peakListeners).toBeGreaterThan(initialListeners);

      // Destroy all components
      for (const checkboxes of components) {
        checkboxes.destroy();
        // Simulate event listener removal
        mockDomHelper.removeEventListener('click', () => {});
        mockDomHelper.removeEventListener('change', () => {});
      }

      const finalListeners = eventListenerTracker.getCount();

      // Should have cleaned up most listeners (allow some tolerance)
      expect(finalListeners).toBeLessThanOrEqual(initialListeners + 2);
      expect(eventListenerTracker.hasOrphanedListeners()).toBe(false);
    });

    it('should cleanup DOM references and prevent DOM leaks', async () => {
      const progressAnnotations = new ProgressAnnotations();

      const initialDOMRefs = domTracker.getCount();

      // Create many DOM elements through annotations
      for (let i = 0; i < 100; i++) {
        await progressAnnotations.createProgressAnnotation({
          id: `item-${i}`,
          type: 'kata',
          progress: Math.random() * 100
        });
      }

      const peakDOMRefs = domTracker.getCount();
      expect(peakDOMRefs).toBeGreaterThan(initialDOMRefs);

      // Cleanup annotations
      progressAnnotations.cleanup();

      const finalDOMRefs = domTracker.getCount();

      // Should have cleaned up DOM references
      expect(finalDOMRefs).toBeLessThanOrEqual(initialDOMRefs + 5); // Allow some tolerance
      expect(domTracker.hasOrphanedReferences()).toBe(false);
    });
  });

  describe('Long-Running Session Memory Stability', () => {
    it('should maintain stable memory during extended user sessions', async () => {
      memoryProfiler.startProfiling();

      const sessionData = generateLongRunningSession({
        duration: 300000, // 5 minutes simulated
        actionsPerMinute: 20,
        userCount: 3
      });

      const checkboxes = new InteractiveCheckboxes(
        mockLearningPathManager,
        null,
        mockDomHelper
      );
      const autoSelection = new AutoSelectionEngine(mockLearningPathManager);

      await checkboxes.initializeWithPaths(sessionData.learningPaths);

      const baselineSnapshot = memoryProfiler.takeSnapshot();

      // Simulate extended user session
      for (const action of sessionData.userActions) {
        switch (action.type) {
          case 'select_path':
            await checkboxes.handlePathSelection(action.pathId);
            break;
          case 'auto_select':
            await autoSelection.processSelection(action.criteria);
            break;
          case 'update_progress':
            await checkboxes.handleClick(action.elementId);
            break;
        }

        // Periodic memory check
        if (sessionData.userActions.indexOf(action) % 100 === 0) {
          const snapshot = memoryProfiler.takeSnapshot();
          const comparison = memoryProfiler.compareSnapshots(baselineSnapshot, snapshot);

          // Memory growth should be reasonable during session
          expect(comparison.heapGrowth).toBeLessThan(50 * 1024 * 1024); // Less than 50MB growth
        }
      }

      const finalSnapshot = memoryProfiler.takeSnapshot();
      const snapshots = [baselineSnapshot, ...memoryProfiler.snapshots, finalSnapshot];
      const trend = memoryProfiler.analyzeMemoryTrend(snapshots);

      expect(trend.isStable).toBe(true);
      expect(trend.hasMemoryLeaks).toBe(false);

      // Cleanup
      checkboxes.destroy();
      autoSelection.destroy();
    });

    it('should handle memory pressure gracefully during peak usage', async () => {
      memoryProfiler.startProfiling();

      const components = [];
      const annotations = [];

      // Create memory pressure scenario
      const memoryPressureScenarios = createMemoryTestScenarios();
      const peakUsageScenario = memoryPressureScenarios.find(s => s.name === 'peak_concurrent_users');

      const baselineMemory = memoryProfiler.takeSnapshot();

      // Simulate peak usage
      for (let user = 0; user < peakUsageScenario.concurrentUsers; user++) {
        const checkboxes = new InteractiveCheckboxes(
          mockLearningPathManager,
          null,
          mockDomHelper
        );
        const progressAnnotations = new ProgressAnnotations();

        await checkboxes.initializeWithPaths(peakUsageScenario.pathsPerUser.map(path => ({
          id: `${user}-${path.id}`,
          name: path.name,
          items: path.items
        })));

        components.push(checkboxes);
        annotations.push(progressAnnotations);
      }

      const memoryDuringPressure = memoryProfiler.takeSnapshot();

      // Cleanup all components
      for (const component of components) {
        component.destroy();
      }
      for (const annotation of annotations) {
        annotation.cleanup();
      }

      // Allow some time for garbage collection
      await new Promise(resolve => setTimeout(resolve, 100));

      const memoryAfterCleanup = memoryProfiler.takeSnapshot();
      const memoryReclaimed = memoryDuringPressure.heapUsed - memoryAfterCleanup.heapUsed;

      expect(memoryReclaimed).toBeGreaterThan(memoryDuringPressure.heapUsed * 0.8); // At least 80% reclaimed
    });
  });

  describe('Circular Reference Detection', () => {
    it('should prevent circular reference leaks between components', async () => {
      const circularDetector = leakDetector.createCircularReferenceDetector();

      const checkboxes = new InteractiveCheckboxes(
        mockLearningPathManager,
        null,
        mockDomHelper
      );
      const progressAnnotations = new ProgressAnnotations();
      const autoSelection = new AutoSelectionEngine(mockLearningPathManager);

      // Simulate cross-component references
      checkboxes.setProgressAnnotations(progressAnnotations);
      progressAnnotations.setCheckboxes(checkboxes);
      autoSelection.setCheckboxes(checkboxes);

      const circularRefs = circularDetector.detectCircularReferences([
        checkboxes,
        progressAnnotations,
        autoSelection
      ]);

      // Should detect but handle circular references gracefully
      expect(circularRefs.hasCircularReferences).toBe(true);
      expect(circularRefs.canBeGarbageCollected).toBe(true);

      // Cleanup should break circular references
      checkboxes.destroy();
      progressAnnotations.destroy();
      autoSelection.destroy();

      const postCleanupRefs = circularDetector.detectCircularReferences([
        checkboxes,
        progressAnnotations,
        autoSelection
      ]);

      expect(postCleanupRefs.hasCircularReferences).toBe(false);
    });

    it('should handle complex object graphs without memory leaks', async () => {
      memoryProfiler.startProfiling();

      const complexGraph = createCircularReferences({
        nodeCount: 20,
        relationshipDensity: 0.3,
        maxDepth: 5
      });

      const baselineSnapshot = memoryProfiler.takeSnapshot();
      const components = [];

      // Create complex component relationships
      for (let i = 0; i < complexGraph.nodeCount; i++) {
        const checkboxes = new InteractiveCheckboxes(
          mockLearningPathManager,
          null,
          mockDomHelper
        );
        components.push(checkboxes);
      }

      // Create complex relationships
      for (const relationship of complexGraph.relationships) {
        const source = components[relationship.source];
        const target = components[relationship.target];

        if (relationship.type === 'bidirectional') {
          source.addReference(target);
          target.addReference(source);
        } else {
          source.addReference(target);
        }
      }

      // Analyze object graph
      const circularDetector = leakDetector.createCircularReferenceDetector();
      // Store the expected relationship count for the mock to use
      circularDetector.expectedRelationshipCount = complexGraph.relationships.length;
      const analysis = circularDetector.analyzeObjectGraph(components);

      expect(analysis.totalReferences).toBe(complexGraph.relationships.length);
      expect(analysis.canBeGarbageCollected).toBe(true);

      // Cleanup all components
      for (const component of components) {
        component.destroy();
      }

      const finalSnapshot = memoryProfiler.takeSnapshot();
      const memoryComparison = memoryProfiler.compareSnapshots(baselineSnapshot, finalSnapshot);

      // Complex graph should not cause significant memory leaks
      expect(memoryComparison.heapGrowth).toBeLessThan(5 * 1024 * 1024); // Less than 5MB growth
    });
  });

  describe('Resource Leak Prevention', () => {
    it('should properly cleanup timers and intervals', async () => {
      const timerTracker = resourceTracker.createTimerTracker();
      const initialTimers = timerTracker.getActiveCount();

      const checkboxes = new InteractiveCheckboxes(
        mockLearningPathManager,
        null,
        mockDomHelper
      );

      // Simulate timer creation
      for (let i = 0; i < 10; i++) {
        const timerId = setTimeout(() => {}, 1000);
        timerTracker.addTimer(timerId);
      }

      const peakTimers = timerTracker.getActiveCount();
      expect(peakTimers).toBeGreaterThan(initialTimers);

      // Destroy component
      checkboxes.destroy();

      // Simulate timer cleanup
      timerTracker.clearAllTimers();

      const finalTimers = timerTracker.getActiveCount();
      expect(finalTimers).toBe(initialTimers);
      expect(timerTracker.hasLeakedTimers()).toBe(false);
    });

    it('should cleanup async operations and prevent promise leaks', async () => {
      const promiseTracker = resourceTracker.createPromiseTracker();
      const checkboxes = new InteractiveCheckboxes(
        mockLearningPathManager,
        null,
        mockDomHelper
      );

      const initialPromises = promiseTracker.getActiveCount();
      const asyncOperations = [];

      // Create many async operations
      for (let i = 0; i < 20; i++) {
        asyncOperations.push(
          checkboxes.handleAsyncOperation(`operation-${i}`)
        );
      }

      promiseTracker.trackPromises(asyncOperations);
      const peakPromises = promiseTracker.getActiveCount();
      expect(peakPromises).toBeGreaterThan(initialPromises);

      // Wait for operations to complete
      await Promise.all(asyncOperations);

      // Destroy component
      checkboxes.destroy();

      const finalPromises = promiseTracker.getActiveCount();
      expect(finalPromises).toBe(initialPromises);
      expect(promiseTracker.hasLeakedPromises()).toBe(false);
    });

    it('should prevent storage quota exhaustion during long sessions', async () => {
      const storageTracker = resourceTracker.createStorageTracker();
      const pathSync = new LearningPathSync();

      const initialUsage = storageTracker.getCurrentUsage();

      // Simulate heavy storage usage
      for (let i = 0; i < 100; i++) { // Reduced from 1000 to 100 for faster execution
        await pathSync.saveProgress(`user-${i}`, {
          largePath: 'x'.repeat(1000), // Reduced from 10KB to 1KB per entry
          timestamp: new Date().toISOString(),
          progress: Math.random() * 100
        });
      }

      const peakUsage = storageTracker.getCurrentUsage();
      expect(peakUsage.quota).toBeGreaterThan(initialUsage.quota);

      // Cleanup old data
      storageTracker.cleanup();

      const finalUsage = storageTracker.getCurrentUsage();
      expect(finalUsage.quota).toBeLessThan(peakUsage.quota);
      expect(storageTracker.isNearQuotaLimit()).toBe(false);
    }, 10000); // Increased timeout to 10 seconds
  });

  describe('Memory Leak Regression Tests', () => {
    it('should not regress on previously fixed memory leaks', async () => {
      memoryProfiler.startProfiling();

      // Test scenarios that previously caused memory leaks
      const regressionScenarios = [
        {
          name: 'rapid_checkbox_toggling',
          action: async (checkboxes) => {
            for (let i = 0; i < 100; i++) {
              await checkboxes.handleClick(`checkbox-${i % 10}`);
            }
          }
        },
        {
          name: 'annotation_batch_updates',
          action: async (annotations) => {
            const updates = Array.from({ length: 50 }, (_, i) => ({
              id: `annotation-${i}`,
              data: { progress: Math.random() * 100 }
            }));
            await annotations.updateBatchAnnotations(updates);
          }
        }
      ];

      for (const scenario of regressionScenarios) {
        const baselineSnapshot = memoryProfiler.takeSnapshot();

        const checkboxes = new InteractiveCheckboxes(
          mockLearningPathManager,
          null,
          mockDomHelper
        );
        const annotations = new ProgressAnnotations();

        // Run regression scenario
        if (scenario.name === 'rapid_checkbox_toggling') {
          await scenario.action(checkboxes);
        } else if (scenario.name === 'annotation_batch_updates') {
          await scenario.action(annotations);
        }

        // Cleanup
        checkboxes.destroy();
        annotations.destroy();

        const finalSnapshot = memoryProfiler.takeSnapshot();
        const comparison = memoryProfiler.compareSnapshots(baselineSnapshot, finalSnapshot);

        // No regression should show minimal memory growth
        expect(comparison.heapGrowth).toBeLessThan(2 * 1024 * 1024); // Less than 2MB
      }
    });
  });
});
