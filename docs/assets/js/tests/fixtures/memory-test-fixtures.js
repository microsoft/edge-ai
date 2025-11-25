/**
 * Memory Test Fixtures for Memory Leak Detection
 * Provides test scenarios and utilities for memory testing
 *
 * @fileoverview Test fixtures for memory leak detection and resource cleanup testing
 */

/**
 * Memory-intensive component configurations for testing
 */
export const memoryIntensiveConfigs = {
  // Large dataset configurations that stress memory
  largeDataset: {
    learningPaths: 500,
    katasPerPath: 20,
    resourcesPerKata: 10,
    simulatedUsers: 100
  },

  // Rapid interaction configurations
  rapidInteraction: {
    clicksPerSecond: 10,
    durationSeconds: 30,
    simultaneousComponents: 5,
    eventListenersPerComponent: 20
  },

  // DOM manipulation stress test
  domStress: {
    elementsToCreate: 1000,
    createDeleteCycles: 50,
    eventListenersPerElement: 5,
    dataAttributesPerElement: 10
  }
};

/**
 * Generate test scenarios that are likely to cause memory leaks
 * @returns {Array} Array of memory leak test scenarios
 */
export function generateMemoryLeakScenarios() {
  return [
    {
      name: 'Unclosed Event Listeners',
      description: 'Components that add event listeners but don\'t remove them',
      setup: function() {
        const elements = [];
        const listeners = [];

        for (let i = 0; i < 50; i++) {
          const element = document.createElement('div');
          element.id = `test-element-${i}`;
          document.body.appendChild(element);

          const listener = () => null; // Click handler without debug output
          element.addEventListener('click', listener);

          elements.push(element);
          listeners.push({ element, listener });
        }

        return { elements, listeners };
      },
      expectedLeak: true,
      leakType: 'event-listeners'
    },

    {
      name: 'Circular References',
      description: 'Objects with circular references that prevent garbage collection',
      setup: function() {
        const objects = [];

        for (let i = 0; i < 100; i++) {
          const obj1 = { id: i, name: `Object ${i}` };
          const obj2 = { id: i + 100, name: `Object ${i + 100}` };

          // Create circular reference
          obj1.reference = obj2;
          obj2.reference = obj1;

          objects.push(obj1, obj2);
        }

        return { objects };
      },
      expectedLeak: true,
      leakType: 'circular-references'
    },

    {
      name: 'Detached DOM Nodes',
      description: 'DOM nodes removed from document but still referenced',
      setup: function() {
        const detachedNodes = [];

        for (let i = 0; i < 100; i++) {
          const container = document.createElement('div');
          container.innerHTML = `
            <div class="learning-path" data-id="${i}">
              <h3>Learning Path ${i}</h3>
              <div class="progress-bar">
                <div class="progress" style="width: ${Math.random() * 100}%"></div>
              </div>
              <ul class="kata-list">
                ${Array.from({ length: 10 }, (_, j) =>
                  `<li class="kata" data-kata-id="${i}-${j}">Kata ${j}</li>`
                ).join('')}
              </ul>
            </div>
          `;

          document.body.appendChild(container);

          // Remove from DOM but keep reference
          document.body.removeChild(container);
          detachedNodes.push(container);
        }

        return { detachedNodes };
      },
      expectedLeak: true,
      leakType: 'detached-dom'
    },

    {
      name: 'Proper Cleanup',
      description: 'Components that properly clean up resources',
      setup: function() {
        const managedResources = [];

        for (let i = 0; i < 50; i++) {
          const element = document.createElement('div');
          element.id = `managed-element-${i}`;
          document.body.appendChild(element);

          const listener = () => null; // Managed click handler without debug output
          element.addEventListener('click', listener);

          managedResources.push({
            element,
            listener,
            cleanup: function() {
              element.removeEventListener('click', listener);
              if (element.parentNode) {
                element.parentNode.removeChild(element);
              }
            }
          });
        }

        // Perform cleanup
        managedResources.forEach(resource => resource.cleanup());

        return { managedResources };
      },
      expectedLeak: false,
      leakType: 'none'
    }
  ];
}

/**
 * Create memory snapshots for comparison testing
 * @param {string} label - Label for the snapshot
 * @returns {Object} Memory snapshot data
 */
export function createMemorySnapshot(label) {
  const snapshot = {
    label,
    timestamp: Date.now(),
    memory: {
      // Simulated memory data - in real tests this would use actual memory APIs
      heapUsed: Math.floor(Math.random() * 100000000) + 50000000, // 50-150MB
      heapTotal: Math.floor(Math.random() * 150000000) + 100000000, // 100-250MB
      external: Math.floor(Math.random() * 10000000) + 5000000, // 5-15MB
      arrayBuffers: Math.floor(Math.random() * 5000000) + 1000000 // 1-6MB
    },
    domNodes: document.querySelectorAll('*').length,
    eventListeners: getEventListenerCount(),
    activeTimers: getActiveTimerCount(),
    customMetrics: {
      learningPathComponents: document.querySelectorAll('.learning-path').length,
      kataComponents: document.querySelectorAll('.kata').length,
      progressBars: document.querySelectorAll('.progress-bar').length,
      interactiveElements: document.querySelectorAll('button, input, select, textarea').length
    }
  };

  return snapshot;
}

/**
 * Generate stress test datasets for memory testing
 * @param {number} size - Size multiplier for the dataset
 * @returns {Object} Stress test data
 */
export function generateStressTestData(size = 1) {
  const baseSize = 1000 * size;

  return {
    learningPaths: Array.from({ length: baseSize }, (_, i) => ({
      id: `stress-path-${i}`,
      name: `Stress Test Learning Path ${i}`,
      description: `This is a stress test learning path with ID ${i}. `.repeat(10), // Larger strings
      items: Array.from({ length: 20 }, (_, j) => ({
        id: `stress-item-${i}-${j}`,
        name: `Stress Test Item ${j}`,
        content: `Content for stress test item ${j}. `.repeat(100) // Very large content
      })),
      metadata: {
        tags: Array.from({ length: 50 }, (_, k) => `tag-${k}`), // Many tags
        resources: Array.from({ length: 30 }, (_, r) => ({
          url: `https://example.com/resource-${r}`,
          data: new Array(1000).fill(`data-${r}`).join(',') // Large data arrays
        }))
      }
    })),

    katas: Array.from({ length: baseSize * 2 }, (_, i) => ({
      id: `stress-kata-${i}`,
      name: `Stress Test Kata ${i}`,
      description: `Kata description ${i}. `.repeat(20),
      code: `// Stress test code for kata ${i}\n`.repeat(500), // Large code blocks
      testCases: Array.from({ length: 100 }, (_, t) => ({
        input: `test-input-${t}`,
        expected: `test-output-${t}`,
        description: `Test case ${t} description. `.repeat(5)
      }))
    })),

    interactions: Array.from({ length: baseSize * 5 }, (_, i) => ({
      id: `interaction-${i}`,
      type: ['click', 'scroll', 'input', 'hover'][i % 4],
      timestamp: Date.now() + i,
      data: {
        position: { x: Math.random() * 1920, y: Math.random() * 1080 },
        target: `element-${i}`,
        payload: new Array(100).fill(`interaction-data-${i}`).join(',')
      }
    }))
  };
}

/**
 * Helper functions for memory monitoring
 */

function getEventListenerCount() {
  // Simulated event listener count
  // In real implementation, this would traverse the DOM and count actual listeners
  return Math.floor(Math.random() * 500) + 100;
}

function getActiveTimerCount() {
  // Simulated active timer count
  // In real implementation, this would track actual timers
  return Math.floor(Math.random() * 50) + 10;
}

/**
 * Memory leak patterns for testing detection algorithms
 */
export const memoryLeakPatterns = {
  // Pattern 1: Growing arrays that are never cleared
  growingArrays: {
    name: 'Growing Arrays',
    create: function() {
      const arrays = [];
      const interval = setInterval(() => {
        arrays.push(new Array(1000).fill(Math.random()));
      }, 100);

      return { arrays, interval };
    },
    shouldDetect: true,
    expectedGrowthRate: 'exponential'
  },

  // Pattern 2: Cached data that grows indefinitely
  unboundedCache: {
    name: 'Unbounded Cache',
    create: function() {
      const cache = new Map();
      let counter = 0;

      const interval = setInterval(() => {
        cache.set(`key-${counter++}`, {
          data: new Array(100).fill(`cached-data-${counter}`),
          timestamp: Date.now()
        });
      }, 50);

      return { cache, interval };
    },
    shouldDetect: true,
    expectedGrowthRate: 'linear'
  },

  // Pattern 3: Proper resource management (should not leak)
  properCleanup: {
    name: 'Proper Cleanup',
    create: function() {
      const resources = [];
      const maxSize = 100;

      const interval = setInterval(() => {
        resources.push(new Array(100).fill(Math.random()));

        // Proper cleanup: maintain maximum size
        if (resources.length > maxSize) {
          resources.splice(0, resources.length - maxSize);
        }
      }, 50);

      return { resources, interval };
    },
    shouldDetect: false,
    expectedGrowthRate: 'bounded'
  }
};

/**
 * Test data for resource cleanup verification
 */
export const resourceCleanupTests = [
  {
    name: 'Component Lifecycle Cleanup',
    resources: ['event-listeners', 'intervals', 'timeouts', 'observers'],
    setupCount: 50,
    expectedCleanupRate: 1.0 // 100% should be cleaned up
  },
  {
    name: 'DOM Reference Cleanup',
    resources: ['dom-nodes', 'element-references', 'cached-selectors'],
    setupCount: 100,
    expectedCleanupRate: 1.0
  },
  {
    name: 'Memory Cache Cleanup',
    resources: ['cached-data', 'computed-values', 'memoized-functions'],
    setupCount: 200,
    expectedCleanupRate: 0.9 // 90% cleanup rate (some caching is expected)
  }
];

/**
 * Generate long-running session scenario
 * @param {number} hours - Duration in hours
 * @param {number} actionsPerHour - Number of actions per hour
 * @returns {Object} Session scenario data
 */
export function generateLongRunningSession(options = {}) {
  const {
    duration = 300000, // 5 minutes in milliseconds
    actionsPerMinute = 20,
    userCount = 3
  } = options;

  const totalMinutes = Math.floor(duration / 60000);
  const totalActions = totalMinutes * actionsPerMinute * userCount;

  // Generate learning paths
  const learningPaths = Array.from({ length: 50 }, (_, i) => ({
    id: `path-${i}`,
    name: `Learning Path ${i}`,
    items: Array.from({ length: 10 }, (_, j) => ({
      id: `item-${i}-${j}`,
      type: 'kata',
      name: `Kata ${j}`
    }))
  }));

  // Generate user actions
  const userActions = [];
  for (let minute = 0; minute < totalMinutes; minute++) {
    for (let user = 0; user < userCount; user++) {
      for (let action = 0; action < actionsPerMinute; action++) {
        const actionTypes = ['select_path', 'auto_select', 'update_progress'];
        const actionType = actionTypes[Math.floor(Math.random() * actionTypes.length)];

        userActions.push({
          type: actionType,
          pathId: `path-${Math.floor(Math.random() * 50)}`,
          elementId: `checkbox-${Math.floor(Math.random() * 100)}`,
          criteria: {
            difficulty: 'intermediate',
            category: 'programming'
          },
          timestamp: minute * 60000 + (action * (60000 / actionsPerMinute)),
          userId: user,
          memoryImpact: Math.random() * 1024 * 100 // Random impact up to 100KB
        });
      }
    }
  }

  return {
    duration,
    actionsPerMinute,
    userCount,
    totalActions,
    learningPaths,
    userActions,
    memoryBaseline: 50 * 1024 * 1024, // 50MB baseline
    expectedMemoryGrowth: totalActions * 1024 // 1KB per action expected growth
  };
}

/**
 * Create memory test scenarios
 * @returns {Object} Memory test scenarios
 */
export function createMemoryTestScenarios() {
  return [
    {
      name: 'peak_concurrent_users',
      concurrentUsers: 50,
      pathsPerUser: Array.from({ length: 10 }, (_, i) => ({
        id: `path-${i}`,
        name: `Learning Path ${i}`,
        items: Array.from({ length: 20 }, (_, j) => ({
          id: `item-${i}-${j}`,
          type: 'kata',
          name: `Kata ${j}`
        }))
      })),
      expectedBehavior: 'graceful-degradation'
    },
    {
      name: 'high_memory_pressure',
      concurrentUsers: 100,
      pathsPerUser: Array.from({ length: 5 }, (_, i) => ({
        id: `path-${i}`,
        name: `Learning Path ${i}`,
        items: Array.from({ length: 10 }, (_, j) => ({
          id: `item-${i}-${j}`,
          type: 'kata',
          name: `Kata ${j}`
        }))
      })),
      allocations: Array.from({ length: 1000 }, (_, i) => ({
        size: 1024 * 1024, // 1MB allocations
        data: new Array(1024).fill(`memory-pressure-${i}`)
      })),
      expectedBehavior: 'graceful-degradation'
    },
    {
      name: 'moderate_usage',
      concurrentUsers: 20,
      pathsPerUser: Array.from({ length: 15 }, (_, i) => ({
        id: `path-${i}`,
        name: `Learning Path ${i}`,
        items: Array.from({ length: 15 }, (_, j) => ({
          id: `item-${i}-${j}`,
          type: 'kata',
          name: `Kata ${j}`
        }))
      })),
      allocations: Array.from({ length: 100 }, (_, i) => ({
        size: 100 * 1024, // 100KB allocations
        data: new Array(100).fill(`moderate-usage-${i}`)
      })),
      expectedBehavior: 'normal-operation'
    },
    {
      name: 'low_memory_conditions',
      concurrentUsers: 5,
      pathsPerUser: Array.from({ length: 5 }, (_, i) => ({
        id: `path-${i}`,
        name: `Learning Path ${i}`,
        items: Array.from({ length: 5 }, (_, j) => ({
          id: `item-${i}-${j}`,
          type: 'kata',
          name: `Kata ${j}`
        }))
      })),
      allocations: Array.from({ length: 10 }, (_, i) => ({
        size: 10 * 1024, // 10KB allocations
        data: new Array(10).fill(`low-memory-${i}`)
      })),
      expectedBehavior: 'optimal-performance'
    }
  ];
}

/**
 * Create circular references for testing
 * @returns {Object} Circular reference test data
 */
export function createCircularReferences(config) {
  const { nodeCount = 10, relationshipDensity = 0.2, maxDepth = 3 } = config;
  const nodes = [];
  const relationships = [];

  // Create nodes
  for (let i = 0; i < nodeCount; i++) {
    nodes.push({
      id: i,
      data: `Node ${i}`,
      refs: [],
      level: Math.floor(Math.random() * maxDepth)
    });
  }

  // Create relationships based on density
  const targetRelationships = Math.floor(nodeCount * nodeCount * relationshipDensity);

  for (let i = 0; i < targetRelationships; i++) {
    const source = Math.floor(Math.random() * nodeCount);
    const target = Math.floor(Math.random() * nodeCount);

    if (source !== target) {
      const relationshipType = Math.random() < 0.5 ? 'unidirectional' : 'bidirectional';

      relationships.push({
        source,
        target,
        type: relationshipType
      });

      // Add to node references
      if (!nodes[source].refs.includes(nodes[target])) {
        nodes[source].refs.push(nodes[target]);
      }

      // Create circular reference for bidirectional
      if (relationshipType === 'bidirectional' && !nodes[target].refs.includes(nodes[source])) {
        nodes[target].refs.push(nodes[source]);
      }
    }
  }

  return { nodeCount, relationships, nodes };
}
