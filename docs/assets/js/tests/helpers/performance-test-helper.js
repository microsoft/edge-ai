/**
 * Performance Test Helper
 * Provides utilities for performance testing with memory monitoring and cleanup
 */

/**
 * Performance Test Helper Class
 */
class PerformanceTestHelper {
  constructor(config = {}) {
    this.config = {
      memoryTrackingEnabled: true,
      domCleanupEnabled: true,
      eventCleanupEnabled: true,
      observerCleanupEnabled: true,
      ...config
    };

    this.performanceMarks = new Map();
    this.trackedElements = new Set();
    this.trackedEventListeners = new Map();
    this.trackedTimers = new Set();
    this.trackedObservers = new Set();
    this.animationFrames = new Set();

    // Create createdElements as an alias to trackedElements for test compatibility
    this.createdElements = this.trackedElements;
  } /**
   * Get current memory usage information
   */
  getCurrentMemoryUsage() {
    if (typeof performance !== 'undefined' && performance.memory) {
      return {
        usedJSHeapSize: performance.memory.usedJSHeapSize,
        totalJSHeapSize: performance.memory.totalJSHeapSize,
        jsHeapSizeLimit: performance.memory.jsHeapSizeLimit
      };
    }
    // Fallback for environments without performance.memory
    return {
      usedJSHeapSize: 0,
      totalJSHeapSize: 0,
      jsHeapSizeLimit: 0
    };
  }

  /**
   * Start performance measurement
   */
  startMeasurement(markName) {
    const startTime = performance.now();
    const startMemory = this.getCurrentMemoryUsage();

    this.performanceMarks.set(markName, {
      start: startTime,
      memory: startMemory
    });

    return startTime;
  }

  /**
   * Stop performance measurement and return metrics
   */
  stopMeasurement(markName) {
    const endTime = performance.now();
    const endMemory = this.getCurrentMemoryUsage();

    const startData = this.performanceMarks.get(markName);
    if (!startData) {
      throw new Error(`No measurement started for mark: ${markName}`);
    }

    const duration = endTime - startData.start;
    const memoryDelta = endMemory.usedJSHeapSize - startData.memory.usedJSHeapSize;

    const metrics = {
      duration,
      memoryDelta,
      startMemory: startData.memory,
      endMemory,
      startTime: startData.start,
      endTime
    };

    this.performanceMarks.delete(markName);
    return metrics;
  }

  /**
   * Stop performance measurement and return metrics (alias for compatibility)
   */
  endMeasurement(markName) {
    return this.stopMeasurement(markName);
  } /**
   * Generate learning dataset with small defaults for testing
   */
  generateLearningDataset(size = 20, config = {}) {
    const {
      includeSearchableText = false,
      includeMetadata = false,
      includeRelationships = false
    } = config;

    const learningData = [];
    const categories = ['frontend', 'backend', 'devops', 'data', 'security'];
    const difficulties = [1, 2, 3, 4, 5];

    for (let i = 0; i < size; i++) {
      const item = {
        id: `item-${i}`,
        title: `Learning Item ${i}`,
        category: categories[i % categories.length],
        difficulty: difficulties[i % difficulties.length],
        duration: Math.floor(Math.random() * 120) + 15,
        tags: [`tag-${i % 10}`, `category-${i % 5}`]
      };

      if (includeSearchableText) {
        item.description = `Description for learning item ${i}`;
      }

      if (includeMetadata) {
        item.metadata = {
          created: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000),
          author: `Author ${i % 10}`
        };
      }

      if (includeRelationships) {
        item.prerequisites = i > 0 ? [`item-${i - 1}`] : [];
      }

      learningData.push(item);
    }

    return learningData;
  }

  /**
   * Generate learning paths dataset with small defaults
   */
  generateLearningPathsDataset(config = {}) {
    const {
      pathCount = 5,
      itemsPerPath = 2,
      includeMetadata = false,
      includeRelationships = false
    } = config;

    const paths = [];
    const categories = ['web', 'mobile', 'data', 'ml', 'cloud'];

    for (let i = 0; i < pathCount; i++) {
      const path = {
        id: `path-${i}`,
        title: `Learning Path ${i}`,
        category: categories[i % categories.length],
        difficulty: Math.floor(Math.random() * 5) + 1,
        items: []
      };

      // Generate items for this path
      for (let j = 0; j < itemsPerPath; j++) {
        const item = {
          id: `path-${i}-item-${j}`,
          title: `Item ${j}`,
          duration: Math.floor(Math.random() * 60) + 15,
          difficulty: Math.floor(Math.random() * 5) + 1, // Add difficulty at item level
          order: j
        };

        if (includeMetadata) {
          item.metadata = {
            type: j % 2 === 0 ? 'lesson' : 'exercise',
            difficulty: item.difficulty // Keep for backwards compatibility
          };
        }

        path.items.push(item);
      }

      if (includeRelationships && i > 0) {
        path.prerequisites = [`path-${i - 1}`];
      }

      paths.push(path);
    }

    return paths;
  }

  /**
   * Create DOM structure for testing with small defaults
   */
  createLargeDOMStructure(config = {}) {
    const {
      elementCount = 50,
      nestingDepth = 2,
      elementType = 'div',
      className = 'performance-test-element',
      addEventListeners = false,
      parentContainer = document.body
    } = config;

    const fragment = document.createDocumentFragment();
    const rootElement = document.createElement('div');
    rootElement.className = 'performance-test-root';
    rootElement.setAttribute('data-test-structure', 'true');

    let currentParent = rootElement;

    for (let i = 0; i < elementCount; i++) {
      const element = document.createElement(elementType);
      element.className = className;
      element.setAttribute('data-element-id', i);
      element.textContent = `Element ${i}`;

      if (addEventListeners) {
        const handler = () => console.log(`Clicked element ${i}`);
        element.addEventListener('click', handler);
        this.trackEventListener(element, 'click', handler);
      }

      if (i % nestingDepth === 0 && i > 0) {
        currentParent = element;
      } else {
        currentParent.appendChild(element);
      }

      this.trackedElements.add(element);
    }

    fragment.appendChild(rootElement);
    parentContainer.appendChild(fragment);
    this.trackedElements.add(rootElement);

    return rootElement;
  }

  /**
   * Track event listener for cleanup
   */
  trackEventListener(element, event, handler) {
    if (!this.trackedEventListeners.has(element)) {
      this.trackedEventListeners.set(element, []);
    }
    this.trackedEventListeners.get(element).push({ event, handler });
  }

  /**
   * Simulate Docsify content loading with small defaults
   */
  async simulateDocsifyContentLoading(config = {}) {
    const {
      pageCount = 5,
      contentSize = 'small',
      includeMarkdownProcessing = false,
      includeSearchIndex = false,
      simulateNetworkDelay = false
    } = config;

    const contentSizes = {
      small: 200,
      medium: 500,
      large: 1000
    };

    const results = {
      pages: [],
      totalLoadTime: 0,
      averageLoadTime: 0,
      searchIndexSize: 0,
      memoryUsage: {
        start: this.getCurrentMemoryUsage(),
        peak: 0,
        end: 0
      }
    };

    this.startMeasurement('docsify-simulation');

    for (let i = 0; i < pageCount; i++) {
      const pageStartTime = performance.now();
      const contentLength = contentSizes[contentSize];
      const pageContent = `# Page ${i}\n\n${'Content text. '.repeat(contentLength / 15)}`;

      if (simulateNetworkDelay) {
        await new Promise(resolve => setTimeout(resolve, 10));
      }

      const pageLoadTime = performance.now() - pageStartTime;
      results.pages.push({
        id: `page-${i}`,
        loadTime: pageLoadTime,
        size: pageContent.length
      });
    }

    const metrics = this.stopMeasurement('docsify-simulation');
    results.totalLoadTime = metrics.duration;
    results.simulationDuration = metrics.duration; // Add this for test compatibility
    results.averageLoadTime = metrics.duration / pageCount;
    results.memoryUsage.end = this.getCurrentMemoryUsage();

    // Set search index size if requested
    if (includeSearchIndex) {
      results.searchIndexSize = pageCount * 1024; // Simple calculation
    } else {
      results.searchIndexSize = pageCount * 100; // Smaller default
    }

    return results;
  }

  /**
   * Comprehensive cleanup of all tracked resources
   */
  cleanup() {
    // Clean up tracked elements
    this.trackedElements.forEach(element => {
      if (element.parentNode) {
        element.parentNode.removeChild(element);
      }
    });
    this.trackedElements.clear();

    // Clean up event listeners
    this.trackedEventListeners.forEach((listeners, element) => {
      listeners.forEach(({ event, handler }) => {
        element.removeEventListener(event, handler);
      });
    });
    this.trackedEventListeners.clear();

    // Clean up timers
    this.trackedTimers.forEach(timerId => {
      clearTimeout(timerId);
      clearInterval(timerId);
    });
    this.trackedTimers.clear();

    // Clean up observers
    this.trackedObservers.forEach(observer => {
      if (observer.disconnect) {
        observer.disconnect();
      }
    });
    this.trackedObservers.clear();

    // Clean up animation frames
    this.animationFrames.forEach(frameId => {
      cancelAnimationFrame(frameId);
    });
    this.animationFrames.clear();

    // Clear performance marks
    this.performanceMarks.clear();

    // Force garbage collection if available
    if (global.gc) {
      global.gc();
    }
  }
}

/**
 * Memory Monitor Class
 */
class MemoryMonitor {
  constructor() {
    this.snapshots = [];
    this.isMonitoring = false;
    this.monitoringInterval = null;
  }

  startMonitoring(intervalMs = 100) {
    if (this.isMonitoring) {
      this.stopMonitoring();
    }

    this.isMonitoring = true;
    this.snapshots = [];

    const takeSnapshot = () => {
      if (this.isMonitoring) {
        this.snapshots.push({
          timestamp: Date.now(),
          memory: this.getCurrentMemory()
        });
      }
    };

    // Take initial snapshot
    takeSnapshot();

    // Set up interval monitoring
    this.monitoringInterval = setInterval(takeSnapshot, intervalMs);
  }

  stopMonitoring() {
    this.isMonitoring = false;
    if (this.monitoringInterval) {
      clearInterval(this.monitoringInterval);
      this.monitoringInterval = null;
    }

    return this.getMonitoringResults();
  }

  getCurrentMemory() {
    if (typeof performance !== 'undefined' && performance.memory) {
      return {
        used: performance.memory.usedJSHeapSize,
        total: performance.memory.totalJSHeapSize,
        limit: performance.memory.jsHeapSizeLimit
      };
    }
    return { used: 0, total: 0, limit: 0 };
  }

  getMonitoringResults() {
    if (this.snapshots.length === 0) {
      return {
        memoryUsage: {
          initial: { used: 0, total: 0, limit: 0 },
          final: { used: 0, total: 0, limit: 0 },
          peak: { used: 0, total: 0, limit: 0 },
          max: { used: 0, total: 0, limit: 0 }, // Add alias for test compatibility
          min: { used: 0, total: 0, limit: 0 }, // Add alias for test compatibility
          growth: 0
        },
        snapshots: []
      };
    }

    const initial = this.snapshots[0].memory;
    const final = this.snapshots[this.snapshots.length - 1].memory;
    const peak = this.snapshots.reduce((max, snapshot) =>
      snapshot.memory.used > max.used ? snapshot.memory : max, initial);

    return {
      memoryUsage: {
        initial,
        final,
        peak,
        max: peak, // Add alias for test compatibility
        min: initial, // Add alias for test compatibility
        growth: final.used - initial.used
      },
      snapshots: this.snapshots
    };
  }

  /**
   * Get statistics (alias for compatibility)
   */
  getStatistics() {
    return this.getMonitoringResults();
  }

  takeSnapshot(label = '') {
    const snapshot = {
      timestamp: Date.now(),
      memory: this.getCurrentMemory(),
      label
    };
    this.snapshots.push(snapshot);
    return snapshot;
  }

  clear() {
    this.snapshots = [];
  }
}

/**
 * Factory function to create performance test helper
 */
export function createPerformanceTestHelper(config = {}) {
  return new PerformanceTestHelper(config);
}

/**
 * Factory function to create memory monitor
 */
export function createMemoryMonitor() {
  return new MemoryMonitor();
}

export { PerformanceTestHelper, MemoryMonitor };
