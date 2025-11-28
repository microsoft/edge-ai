import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { createPerformanceTestHelper, createMemoryMonitor } from '../helpers/performance-test-helper.js';

/**
 * Large Dataset Performance Test Suite
 *
 * Focused tests for handling large datasets and DOM structures
 * with comprehensive cleanup and memory management.
 *
 * NOTE: These tests are commented out due to timeout issues in CI environments.
 * They can be enabled for local performance testing if needed.
 */
// Skipped: Expensive performance tests with large datasets, run manually before releases
describe.skip('Large Dataset Performance', () => {
  let testContainer;
  let performanceHelper;
  let memoryMonitor;

  beforeEach(async () => {
    // Setup test environment with comprehensive performance monitoring using happy-dom
    document.head.innerHTML = `
        <title>Large Dataset Performance Test</title>
        <meta charset="utf-8">
        <style>
          .learning-path { margin: 10px; padding: 10px; border: 1px solid #ccc; }
          .path-item { display: block; margin: 5px 0; }
          .progress-bar { width: 100%; height: 20px; background: #f0f0f0; }
          .progress-fill { height: 100%; background: #4caf50; transition: width 0.3s ease; }
          .hierarchy-node { margin: 5px 0; padding: 5px; }
        </style>
    `;

    document.body.innerHTML = `
      <div id="test-container">
        <div id="learning-paths-container"></div>
        <button id="coach-button">Coach Button</button>
        <div id="search-container"></div>
        <div id="progress-display"></div>
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

    // Mock additional browser APIs for learning platform testing
    setupLearningPlatformMocks();
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

  it('should handle 75+ learning paths efficiently with comprehensive cleanup', async () => {
    const pathCount = 75; // Reduced for memory efficiency
    const itemsPerPath = 15; // Reduced for memory efficiency

    // Start comprehensive performance measurement
    performanceHelper.startMeasurement('large-dataset-render');
    memoryMonitor.startMonitoring(100);

    // Generate large dataset using helper
    const largePaths = performanceHelper.generateLearningPathsDataset({
      pathCount,
      itemsPerPath,
      includeProgress: true,
      includeMetadata: true,
      complexityVariation: true
    });

    // Create DOM structure with automatic tracking
    const domStructure = performanceHelper.createLargeDOMStructure({
      elementCount: pathCount * 3, // 3 elements per path
      nestingDepth: 2,
      addEventListeners: true,
      parentContainer: document.getElementById('learning-paths-container')
    });

    // Render paths to DOM with performance tracking
    await renderLearningPathsDataset(largePaths, domStructure);

    // End measurement and get metrics
    const renderMetrics = performanceHelper.endMeasurement('large-dataset-render');
    const memoryStats = memoryMonitor.stopMonitoring();

    // Performance assertions
    expect(renderMetrics.duration).toBeLessThan(3000); // < 3 seconds for 75 paths
    expect(renderMetrics.memoryDelta).toBeLessThan(50 * 1024 * 1024); // < 50MB memory increase

    // Verify DOM structure
    const renderedPaths = document.querySelectorAll('.learning-path');
    expect(renderedPaths.length).toBe(pathCount);

    // Test interaction performance with memory monitoring
    performanceHelper.startMeasurement('interaction-test');

    const firstCheckbox = document.querySelector('input[type="checkbox"]');
    if (firstCheckbox) {
      firstCheckbox.checked = true;
      firstCheckbox.dispatchEvent(new window.Event('change', { bubbles: true }));
    }

    const interactionMetrics = performanceHelper.endMeasurement('interaction-test');
    expect(interactionMetrics.duration).toBeLessThan(100); // < 100ms for interaction

    // Verify memory usage is reasonable
    const finalMemoryStats = memoryMonitor.getStatistics();
    expect(finalMemoryStats.memoryUsage.growth).toBeLessThan(75 * 1024 * 1024); // < 75MB total growth
  });

  it('should handle 600+ learning items efficiently with automatic cleanup', async () => {
    const itemCount = 600; // Reduced for memory efficiency

    performanceHelper.startMeasurement('large-items-render');
    memoryMonitor.startMonitoring(50);

    // Generate large item list with DOM tracking
    const container = document.getElementById('learning-paths-container');
    const fragment = document.createDocumentFragment();

    for (let i = 0; i < itemCount; i++) {
      const item = document.createElement('label');
      item.className = 'path-item';
      item.setAttribute('data-test-structure', 'true');
      item.innerHTML = `
        <input type="checkbox" data-item-id="item-${i}" />
        <span>Learning Item ${i}</span>
      `;

      // Track for cleanup
      performanceHelper.createdElements.add(item);
      fragment.appendChild(item);

      // Yield control periodically to maintain responsiveness
      if (i % 100 === 0) {
        await new Promise(resolve => setTimeout(resolve, 0));
      }
    }

    container.appendChild(fragment);

    const renderMetrics = performanceHelper.endMeasurement('large-items-render');

    // Performance assertions
    expect(renderMetrics.duration).toBeLessThan(1000); // < 1 second for 600 items

    // Test batch operations with memory tracking
    performanceHelper.startMeasurement('batch-operations');

    const checkboxes = document.querySelectorAll('input[type="checkbox"]');

    // Batch check every 10th item
    for (let i = 0; i < checkboxes.length; i += 10) {
      checkboxes[i].checked = true;
    }

    const batchMetrics = performanceHelper.endMeasurement('batch-operations');
    expect(batchMetrics.duration).toBeLessThan(250); // < 250ms for batch operations

    // Stop memory monitoring and verify usage
    const memoryStats = memoryMonitor.stopMonitoring();
    expect(memoryStats.memoryUsage.peak.used).toBeLessThan(100 * 1024 * 1024); // < 100MB peak usage
  });

  it('should handle deep learning path hierarchies with efficient cleanup', async () => {
    const depth = 6; // Reduced for memory efficiency
    const breadth = 4; // Reduced for memory efficiency

    performanceHelper.startMeasurement('deep-hierarchy-render');

    // Generate deep hierarchy with tracking
    const hierarchy = generateDeepHierarchy(depth, breadth);
    await renderHierarchy(hierarchy);

    const renderMetrics = performanceHelper.endMeasurement('deep-hierarchy-render');
    expect(renderMetrics.duration).toBeLessThan(10000); // < 10 seconds for deep hierarchy (increased for testing environment stability)

    // Test navigation performance
    performanceHelper.startMeasurement('hierarchy-navigation');

    const deepestElement = document.querySelector('[data-depth="5"]');
    if (deepestElement) {
      deepestElement.scrollIntoView();
    }

    const navigationMetrics = performanceHelper.endMeasurement('hierarchy-navigation');
    expect(navigationMetrics.duration).toBeLessThan(50); // < 50ms for navigation

    // Verify hierarchy structure integrity
    const hierarchyNodes = document.querySelectorAll('.hierarchy-node');
    expect(hierarchyNodes.length).toBeGreaterThan(depth * breadth);
  });

  it('should handle Docsify content loading simulation', async () => {
    // Test Docsify-specific performance scenarios
    const docsifyResults = await performanceHelper.simulateDocsifyContentLoading({
      pageCount: 15, // Reduced for memory efficiency
      contentSize: 'small', // Reduced for memory efficiency
      includeMarkdownProcessing: true,
      includeSearchIndex: true,
      simulateNetworkDelay: false // Disabled to improve test speed
    });

    // Performance assertions for Docsify scenarios
    expect(docsifyResults.averageLoadTime).toBeLessThan(200); // < 200ms average load time
    expect(docsifyResults.simulationDuration).toBeLessThan(3000); // < 3 seconds total
    expect(docsifyResults.pages.length).toBe(15);

    // Memory usage should be reasonable for content loading
    const memoryGrowth = docsifyResults.memoryUsage.end.used - docsifyResults.memoryUsage.start.used;
    expect(memoryGrowth || 0).toBeLessThan(25 * 1024 * 1024); // < 25MB for 15 pages

    // Search index should be appropriately sized
    expect(docsifyResults.searchIndexSize).toBeGreaterThan(0);
    expect(docsifyResults.searchIndexSize).toBeLessThan(5 * 1024 * 1024); // < 5MB search index
  });

  // Helper Functions

  /**
   * Setup learning platform specific mocks
   */
  function setupLearningPlatformMocks() {
    // Mock localStorage for learning progress
    const localStorageMock = {
      getItem: vi.fn((key) => {
        const mockData = {
          'learning-progress': JSON.stringify({
            'path-1': { completed: 3, total: 10 },
            'path-2': { completed: 7, total: 15 }
          }),
          'user-preferences': JSON.stringify({
            theme: 'light',
            language: 'en'
          })
        };
        return mockData[key] || null;
      }),
      setItem: vi.fn(),
      removeItem: vi.fn(),
      clear: vi.fn()
    };

    Object.defineProperty(window, 'localStorage', {
      value: localStorageMock,
      writable: true
    });

    // Mock sessionStorage for temporary data
    Object.defineProperty(window, 'sessionStorage', {
      value: { ...localStorageMock },
      writable: true
    });

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

    // Mock Intersection Observer for learning content visibility tracking
    global.IntersectionObserver = vi.fn().mockImplementation((callback) => ({
      observe: vi.fn(),
      unobserve: vi.fn(),
      disconnect: vi.fn()
    }));

    // Mock ResizeObserver for responsive learning content
    global.ResizeObserver = vi.fn().mockImplementation((callback) => ({
      observe: vi.fn(),
      unobserve: vi.fn(),
      disconnect: vi.fn()
    }));
  }

  /**
   * Render large learning paths dataset with performance optimizations
   * @param {Array} paths - Learning paths data
   * @param {HTMLElement} container - Container element
   */
  async function renderLearningPathsDataset(paths, container) {
    const fragment = document.createDocumentFragment();

    // Batch render paths for better performance
    const batchSize = 25; // Reduced batch size
    for (let i = 0; i < paths.length; i += batchSize) {
      const batch = paths.slice(i, i + batchSize);

      batch.forEach(path => {
        const pathElement = document.createElement('div');
        pathElement.className = 'learning-path';
        pathElement.setAttribute('data-path-id', path.id);
        pathElement.setAttribute('data-test-structure', 'true');

        const itemsHTML = path.items.map(item => `
          <label class="path-item">
            <input type="checkbox"
                   data-item-id="${item.id}"
                   data-item-type="${item.type}"
                   ${item.progress && item.progress.completed ? 'checked' : ''} />
            <span>${item.title}</span>
            ${item.progress ? `<span class="progress-indicator">${item.progress.score || 0}%</span>` : ''}
          </label>
        `).join('');

        pathElement.innerHTML = `
          <h3>${path.title}</h3>
          <div class="path-description">${path.description}</div>
          <div class="path-metadata">
            ${path.metadata ? `
              <span class="category">${path.metadata.category}</span>
              <span class="estimated-time">${path.metadata.estimatedHours}h</span>
            ` : ''}
          </div>
          <div class="path-items">${itemsHTML}</div>
        `;

        fragment.appendChild(pathElement);

        // Track for cleanup
        performanceHelper.createdElements.add(pathElement);
      });

      // Yield control between batches
      if (i > 0) {
        await new Promise(resolve => setTimeout(resolve, 0));
      }
    }

    const targetContainer = container || document.getElementById('learning-paths-container');
    targetContainer.appendChild(fragment);
  }

  function generateDeepHierarchy(depth, breadth) {
    function createLevel(currentDepth, parentPath = '') {
      const level = [];

      for (let i = 0; i < breadth; i++) {
        const path = `${parentPath}-${i}`;
        const node = {
          id: path,
          title: `Learning Module ${path}`,
          depth: currentDepth,
          type: currentDepth % 2 === 0 ? 'category' : 'content',
          estimatedTime: Math.floor(Math.random() * 60) + 15,
          children: currentDepth < depth - 1 ? createLevel(currentDepth + 1, path) : []
        };
        level.push(node);
      }

      return level;
    }

    return createLevel(0);
  }

  async function renderHierarchy(hierarchy) {
    const container = document.getElementById('learning-paths-container');
    const fragment = document.createDocumentFragment();

    function renderLevel(nodes, parentElement, level = 0) {
      nodes.forEach(node => {
        const element = document.createElement('div');
        element.className = 'hierarchy-node';
        element.setAttribute('data-depth', node.depth);
        element.setAttribute('data-node-id', node.id);
        element.setAttribute('data-test-structure', 'true');
        element.style.marginLeft = `${level * 20}px`;

        element.innerHTML = `
          <h${Math.min(node.depth + 2, 6)} class="node-title">
            ${node.title}
          </h${Math.min(node.depth + 2, 6)}>
          <div class="node-metadata">
            <span class="node-type">${node.type}</span>
            <span class="estimated-time">${node.estimatedTime}min</span>
          </div>
        `;

        if (node.children.length > 0) {
          const childrenContainer = document.createElement('div');
          childrenContainer.className = 'children';
          renderLevel(node.children, childrenContainer, level + 1);
          element.appendChild(childrenContainer);
        }

        parentElement.appendChild(element);

        // Track for cleanup
        performanceHelper.createdElements.add(element);
      });
    }

    renderLevel(hierarchy, fragment);
    container.appendChild(fragment);
  }
});
