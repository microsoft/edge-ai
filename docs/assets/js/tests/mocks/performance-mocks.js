/**
 * Performance Monitoring Mocks for Testing
 * Provides mock implementations for performance monitoring tools
 *
 * @fileoverview Mock implementations for performance testing infrastructure
 */

// Base class for resource tracking
export class ResourceBase {
  constructor() {
    this.resourceCount = 0;
  }

  allocateResource() {
    this.resourceCount++;
  }

  deallocateResource() {
    if (this.resourceCount > 0) {
      this.resourceCount--;
    }
  }

  getResourceCount() {
    return this.resourceCount;
  }
}

export class PerformanceMonitor {
  constructor() {
    this.isRunning = false;
    this.startTime = null;
    this.endTime = null;
    this.metrics = {
      processingTime: 0,
      memoryUsage: 0,
      operationsPerSecond: 0
    };
  }

  start() {
    this.isRunning = true;
    this.startTime = performance.now();
  }

  stop() {
    this.isRunning = false;
    this.endTime = performance.now();
    this.metrics.processingTime = this.endTime - this.startTime;
  }

  getMetrics() {
    return { ...this.metrics };
  }

  reset() {
    this.isRunning = false;
    this.startTime = null;
    this.endTime = null;
    this.metrics = {
      processingTime: 0,
      memoryUsage: 0,
      operationsPerSecond: 0
    };
  }
}

export class MemoryTracker {
  constructor() {
    this.tracking = false;
    this.baselineMemory = 50 * 1024 * 1024; // 50MB baseline
    this.currentMemory = this.baselineMemory;
    this.peakMemory = this.baselineMemory;
    this.memoryHistory = [];
  }

  startTracking() {
    this.tracking = true;
    this.memoryHistory = [];
  }

  stopTracking() {
    this.tracking = false;
  }

  getCurrentUsage() {
    // Simulate some memory fluctuation
    this.currentMemory = this.baselineMemory + Math.random() * 10 * 1024 * 1024;
    return this.currentMemory;
  }

  cleanup() {
    this.tracking = false;
    this.memoryHistory = [];
    this.currentMemory = this.baselineMemory;
  }

  detectLeaks() {
    return {
      detected: false,
      leakCount: 0,
      suspiciousObjects: []
    };
  }

  simulateMemoryPressure(size) {
    this.currentMemory += size;
    this.peakMemory = Math.max(this.peakMemory, this.currentMemory);
  }

  getCurrentMemoryUsage() {
    // Simulate realistic memory usage patterns
    if (this.tracking) {
      this.currentMemory += Math.random() * 1024 * 1024; // Random growth up to 1MB
      this.peakMemory = Math.max(this.peakMemory, this.currentMemory);
      this.memoryHistory.push({
        timestamp: Date.now(),
        usage: this.currentMemory
      });
    }
    return this.currentMemory;
  }

  hasMemoryLeaks() {
    if (this.memoryHistory.length < 10) {return false;}

    // Check for consistent upward trend (potential leak)
    const recent = this.memoryHistory.slice(-10);
    const trend = recent[recent.length - 1].usage - recent[0].usage;
    return trend > 20 * 1024 * 1024; // More than 20MB growth is suspicious
  }
}

export class BenchmarkRunner {
  constructor() {
    this.benchmarks = new Map();
  }

  createBenchmark(name) {
    const benchmark = new Benchmark(name);
    this.benchmarks.set(name, benchmark);
    return benchmark;
  }

  getBenchmark(name) {
    return this.benchmarks.get(name);
  }

  getAllBenchmarks() {
    return Array.from(this.benchmarks.values());
  }
}

class Benchmark {
  constructor(name) {
    this.name = name;
    this.startTime = null;
    this.endTime = null;
    this.iterations = [];
    this.peakMemory = 0;
    this.errorCount = 0;
    this.totalOperations = 0;
  }

  start() {
    this.startTime = performance.now();
  }

  stop() {
    this.endTime = performance.now();
    this.iterations.push({
      duration: this.endTime - this.startTime,
      timestamp: this.startTime
    });
  }

  getAverageTime() {
    if (this.iterations.length === 0) {return 0;}
    const total = this.iterations.reduce((sum, iter) => sum + iter.duration, 0);
    return total / this.iterations.length;
  }

  getTotalTime() {
    return this.endTime - this.startTime;
  }

  getPeakMemory() {
    return this.peakMemory;
  }

  getMaxInteractionTime() {
    if (this.iterations.length === 0) {return 0;}
    return Math.max(...this.iterations.map(iter => iter.duration));
  }

  getErrorRate() {
    if (this.totalOperations === 0) {return 0;}
    return this.errorCount / this.totalOperations;
  }

  recordError() {
    this.errorCount++;
  }

  recordOperation() {
    this.totalOperations++;
  }

  getMetrics() {
    return {
      averageTime: this.getAverageTime(),
      totalTime: this.getTotalTime(),
      peakMemory: this.getPeakMemory(),
      memoryUsage: this.peakMemory,
      maxInteractionTime: this.getMaxInteractionTime(),
      errorRate: this.getErrorRate(),
      iterations: this.iterations.length,
      totalOperations: this.totalOperations
    };
  }
}

// Mock classes for the actual features being tested
// Performance monitoring mock classes
export class InteractiveCheckboxes extends ResourceBase {
  constructor(learningPathManager, progressManager, domHelper) {
    super();
    this.learningPathManager = learningPathManager;
    this.progressManager = progressManager;
    this.domHelper = domHelper;
    this.isInitialized = false;
    this.eventListeners = [];
    this.domReferences = [];
    this.references = [];
    this.allocatedResources = [];
    this.cleanupPerformed = false;
    this.progressAnnotations = null;
    this.timers = [];
    this.checkboxes = new Map(); // Initialize checkboxes as Map for clear() method

    // Get trackers from global context if available
    this.eventListenerTracker = global.eventListenerTracker;
    this.domTracker = global.domTracker;

    // Simulate resource allocation
    this.allocateResources();
  }

  allocateResources() {
    // Simulate memory allocation
    this.allocatedResources.push(new Array(1000).fill('resource'));
    this.allocatedResources.push({ large: new Array(500).fill('data') });

    // Notify memory profiler about allocation
    if (global.memoryProfiler) {
      global.memoryProfiler.allocateMemory(10 * 1024 * 1024); // 10MB per component for more visible memory pressure
    }
  }

  deallocateResources() {
    const allocatedSize = this.allocatedResources.length * 10 * 1024 * 1024; // 10MB per resource set
    this.allocatedResources.length = 0;

    // Notify memory profiler about deallocation
    if (global.memoryProfiler) {
      global.memoryProfiler.deallocateMemory(allocatedSize);
    }
  }

  init() {
    this.isInitialized = true;
    // Don't automatically create listeners here - let the test control this
    // Just track DOM elements
    const domElements = ['element1', 'element2', 'element3'];

    domElements.forEach(element => {
      this.domReferences.push(element);
      if (this.domTracker) {
        this.domTracker.trackReference(element, { id: element });
      }
    });

    return Promise.resolve();
  }

  async initializeWithPaths(paths) {
    await this.init();
    this.paths = paths;
    // Don't automatically create listeners here - let the test control this
    // Just track DOM references for paths
    for (const path of paths) {
      const domId = `dom-${path.id}`;
      this.domReferences.push(domId);

      if (this.domTracker) {
        this.domTracker.trackReference(domId, { id: domId });
      }
    }
    return Promise.resolve();
  }

  addReference(target) {
    this.references.push(target);
  }

  setProgressAnnotations(annotations) {
    this.progressAnnotations = annotations;
  }

  async handleClick(elementId) {
    // Simulate click handling
    return Promise.resolve();
  }

  async handlePathSelection(pathId) {
    // Simulate path selection handling
    return Promise.resolve({ pathId, selected: true });
  }

  async handleAsyncOperation(operation) {
    // Simulate async operation
    return new Promise(resolve => {
      const timer = setTimeout(() => {
        resolve(`completed-${operation}`);
      }, 10);
      this.timers.push(timer);
    });
  }

  destroy() {
    this.cleanup();
    // Clear timers
    this.timers.forEach(timer => clearTimeout(timer));
    this.timers.length = 0;
  }

  cleanup() {
    // Don't try to cleanup listeners we didn't create
    // The test handles listener cleanup via mockDomHelper directly

    this.domReferences.forEach(element => {
      if (this.domTracker) {
        this.domTracker.untrackReference(element);
      }
    });

    this.checkboxes.clear();
    this.references.length = 0;
    this.eventListeners.length = 0;
    this.domReferences.length = 0;
    this.deallocateResources(); // This will now notify the memory profiler
    this.cleanupPerformed = true;
  }

  handleSelectionChange() {
    return Promise.resolve();
  }

  updateDisplay() {
    return Promise.resolve();
  }
}

export class AutoSelectionEngine extends ResourceBase {
  constructor(learningPathManager) {
    super();
    this.learningPathManager = learningPathManager;
    this.selections = new Map();
    this.relationships = new Map();
    this.references = []; // Initialize references array for circular reference tracking
  }

  async processKataDataset(dataset) {
    return { processed: true, count: dataset.length };
  }

  async selectPath(pathId, relationships) {
    this.relationships.set(pathId, relationships);
    this.selections.set(pathId, { selected: true, timestamp: Date.now() });
    return { pathId, selected: true };
  }

  async buildRelationshipMap(relationships) {
    relationships.forEach(rel => {
      this.relationships.set(`${rel.source}-${rel.target}`, rel);
    });
    return { built: true, count: relationships.length };
  }

  async processSelection(criteria) {
    // Mock implementation for auto selection processing
    return { processed: true, criteria, selected: Math.random() > 0.5 };
  }

  setCheckboxes(checkboxes) {
    this.checkboxes = checkboxes;
  }

  cleanup() {
    this.selections.clear();
    this.relationships.clear();
    this.cleanupPerformed = true;
  }

  destroy() {
    this.cleanup();
  }

  isHealthy() {
    return true;
  }

  async processLargeKataDataset(dataset) {
    // Mock implementation for large dataset processing
    await new Promise(resolve => setTimeout(resolve, Math.random() * 50));
    return {
      processedCount: dataset.length,
      performance: 'optimized',
      status: 'success'
    };
  }
}

export class LearningPathSync extends ResourceBase {
  constructor(dependencies) {
    super();
    this.dependencies = dependencies;
    this.progressData = new Map();
    this.performanceMetrics = {
      syncTime: Math.random() * 200,
      memoryUsage: Math.random() * 8000000
    };
  }

  sync() {
    return Promise.resolve();
  }

  getPerformanceMetrics() {
    return { ...this.performanceMetrics };
  }

  async processRelationships(relationships) {
    // Mock implementation for processing relationships
    await new Promise(resolve => setTimeout(resolve, Math.random() * 100));
    return {
      processed: true,
      relationshipCount: relationships.relationships?.length || 0,
      nodeCount: relationships.nodeCount || 0
    };
  }

  isHealthy() {
    return true;
  }

  async saveProgress(userId, progressData) {
    // Simulate async storage operation (faster simulation)
    await new Promise(resolve => setTimeout(resolve, 1)); // Reduced from 10ms to 1ms

    this.progressData.set(userId, progressData);
    this.allocateResource();
  }
}

export class ProgressAnnotations extends ResourceBase {
  constructor() {
    super();
    this.annotations = new Map();
    this.domElements = new Map();
    this.references = []; // Initialize references array for circular reference tracking
  } async createAnnotation(item) {
    this.annotations.set(item.id, item);
    return { id: item.id, created: true };
  }

  async createProgressAnnotation(config) {
    const annotation = {
      id: config.id,
      type: config.type,
      progress: config.progress,
      element: document.createElement('div')
    };

    // Simulate DOM element creation and tracking
    annotation.element.id = config.id;
    annotation.element.className = 'progress-annotation';
    document.body.appendChild(annotation.element);

    // Track the DOM reference if tracker is available
    if (global.domTracker) {
      global.domTracker.trackReference(config.id, annotation.element);
    }

    this.annotations.set(config.id, annotation);
    this.allocateResource();

    // Notify memory profiler about allocation
    if (global.memoryProfiler) {
      global.memoryProfiler.allocateMemory(512 * 1024); // 512KB per annotation
    }

    return annotation;
  }

  async updateAnnotation(itemId, data) {
    this.annotations.set(itemId, data);
    return true;
  }

  async renderAnnotations(annotationData) {
    annotationData.forEach(item => {
      this.annotations.set(item.id, item);
      const element = { id: item.id, type: 'annotation', data: item };
      this.domElements.set(item.id, element);
    });
    return { rendered: true, count: annotationData.length };
  }

  async setProgressAnnotations(learningPaths) {
    // Mock implementation for setting progress annotations
    await new Promise(resolve => setTimeout(resolve, Math.random() * 100));
    learningPaths.forEach(path => {
      this.annotations.set(path.id, {
        id: path.id,
        progress: Math.random() * 100,
        completed: Math.random() > 0.5,
        annotated: true
      });
    });
    return {
      processed: true,
      count: learningPaths.length,
      timestamp: Date.now()
    };
  }

  async updateBatchAnnotations(updates) {
    updates.forEach(update => {
      this.annotations.set(update.id, update.data);
    });
    return { updated: true, count: updates.length };
  }

  setCheckboxes(checkboxes) {
    this.checkboxes = checkboxes;
  }

  destroy() {
    this.annotations.clear();
    this.domElements.clear();
    // Clear circular references to prevent detection after destruction
    this.references.length = 0;
    this.cleanupPerformed = true; // Mark as cleaned up
  }

  cleanup() {
    // Cleanup DOM references
    if (global.domTracker) {
      for (const [id, annotation] of this.annotations) {
        global.domTracker.untrackReference(id);
        // Remove DOM element
        if (annotation.element && annotation.element.parentNode) {
          annotation.element.parentNode.removeChild(annotation.element);
        }
      }
    }

    // Notify memory profiler about deallocation
    if (global.memoryProfiler) {
      const annotationCount = this.annotations.size;
      global.memoryProfiler.deallocateMemory(annotationCount * 512 * 1024); // 512KB per annotation
    }

    this.annotations.clear();
    this.domElements.clear();
    this.cleanupPerformed = true;
  }
}

export class ProgressSyncService {
  constructor() {
    this.syncQueue = [];
    this.progressData = new Map();
    this.storageData = new Map();
  }

  async sync(userId, data) {
    this.syncQueue.push({ userId, data, timestamp: Date.now() });
    return { synced: true, userId };
  }

  async syncProgress(userId, data) {
    this.progressData.set(userId, data);
    return { synced: true, userId, dataSize: JSON.stringify(data).length };
  }

  async saveProgress(userId, data) {
    this.storageData.set(userId, data);

    // Simulate storage usage increase by updating the global resource tracker
    if (global.resourceTracker) {
      const dataSize = JSON.stringify(data).length;
      global.resourceTracker.storageUsage += dataSize;
    }

    return { saved: true, userId, dataSize: JSON.stringify(data).length };
  }

  async batchSync(operations) {
    return Promise.all(operations.map(op => this.sync(op.userId, op.data)));
  }

  async syncProgressSession(progressData) {
    // Mock implementation for progress data sync
    await new Promise(resolve => setTimeout(resolve, Math.random() * 50));
    const dataSize = JSON.stringify(progressData).length;
    this.progressData.set('session', progressData);
    return {
      synced: true,
      dataSize,
      timestamp: Date.now()
    };
  }

  isHealthy() {
    return true;
  }

  getStorageUsage() {
    let totalSize = 0;
    this.storageData.forEach(data => {
      totalSize += JSON.stringify(data).length;
    });
    return { totalSize, itemCount: this.storageData.size };
  }

  cleanup() {
    this.syncQueue = [];
    this.progressData.clear();
    this.storageData.clear();
  }
}

export class CoachButton {
  constructor() {
    this.animations = new Map();
    this.isAnimating = false;
  }

  async triggerAnimation(type, duration) {
    this.isAnimating = true;
    const animationId = `${type}-${Date.now()}`;

    this.animations.set(animationId, {
      type,
      duration,
      startTime: performance.now()
    });

    // Simulate animation duration
    await new Promise(resolve => setTimeout(resolve, duration || 16));

    this.isAnimating = false;
    return animationId;
  }

  getAnimationState() {
    return {
      isAnimating: this.isAnimating,
      activeAnimations: this.animations.size
    };
  }

  destroy() {
    this.animations.clear();
    this.isAnimating = false;
  }
}
