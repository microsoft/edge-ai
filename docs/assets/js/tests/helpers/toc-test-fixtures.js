/**
 * TOC Test Fixtures
 * Specialized test data and DOM structures for TOC architecture testing
 *
 * @description Provides standardized test fixtures for:
 * - DOM structures with realistic header hierarchies
 * - Test data for TOC generation and processing
 * - Mock configurations for different TOC scenarios
 * - Performance test data sets
 * @version 1.0.0
 */

/**
 * Header Test Data
 * Predefined header structures for testing TOC generation
 */
export const headerTestData = {
  /**
   * Simple flat header structure
   */
  simple: [
    { level: 1, text: 'Introduction', id: 'introduction' },
    { level: 1, text: 'Getting Started', id: 'getting-started' },
    { level: 1, text: 'Conclusion', id: 'conclusion' }
  ],

  /**
   * Nested header structure with multiple levels
   */
  nested: [
    { level: 1, text: 'Chapter 1: Overview', id: 'chapter-1-overview' },
    { level: 2, text: 'What is TOC?', id: 'what-is-toc' },
    { level: 3, text: 'Benefits', id: 'benefits' },
    { level: 3, text: 'Use Cases', id: 'use-cases' },
    { level: 2, text: 'Architecture', id: 'architecture' },
    { level: 1, text: 'Chapter 2: Implementation', id: 'chapter-2-implementation' },
    { level: 2, text: 'Setup', id: 'setup' },
    { level: 3, text: 'Prerequisites', id: 'prerequisites' },
    { level: 3, text: 'Installation', id: 'installation' },
    { level: 4, text: 'Package Manager', id: 'package-manager' },
    { level: 4, text: 'Manual Installation', id: 'manual-installation' },
    { level: 2, text: 'Configuration', id: 'configuration' }
  ],

  /**
   * Complex nested structure with gaps and edge cases
   */
  complex: [
    { level: 1, text: 'Title', id: 'title' },
    { level: 3, text: 'Subsection (skipped h2)', id: 'subsection' }, // Skipped level
    { level: 2, text: 'Proper h2', id: 'proper-h2' },
    { level: 4, text: 'Deep nesting', id: 'deep-nesting' },
    { level: 1, text: 'Another Title', id: 'another-title' },
    { level: 2, text: 'Section A', id: 'section-a' },
    { level: 2, text: 'Section B', id: 'section-b' },
    { level: 5, text: 'Very deep', id: 'very-deep' }, // Very deep nesting
    { level: 1, text: 'Final Title', id: 'final-title' }
  ],

  /**
   * Headers without IDs (edge case)
   */
  noIds: [
    { level: 1, text: 'Header Without ID' },
    { level: 2, text: 'Another Header Without ID' },
    { level: 1, text: 'Third Header Without ID' }
  ],

  /**
   * Large dataset for performance testing
   */
  large: (() => {
    const headers = [];
    for (let i = 1; i <= 100; i++) {
      headers.push({
        level: (i % 3) + 1, // Cycle through h1, h2, h3
        text: `Performance Test Header ${i}`,
        id: `perf-header-${i}`
      });
    }
    return headers;
  })(),

  /**
   * Edge cases and special characters
   */
  edgeCases: [
    { level: 1, text: 'Header with "quotes"', id: 'header-with-quotes' },
    { level: 2, text: 'Header with <HTML> tags', id: 'header-with-html' },
    { level: 3, text: 'Header with émojis 🎉', id: 'header-with-emojis' },
    { level: 1, text: 'Header with & special characters', id: 'header-with-special' },
    { level: 2, text: '', id: 'empty-header' }, // Empty text
    { level: 1, text: 'Very long header text that exceeds normal expectations and contains multiple sentences with various punctuation marks, numbers like 123, and symbols like @ # $ % to test edge cases in TOC generation.', id: 'very-long-header' }
  ],

  /**
   * Real-world documentation structure
   */
  documentation: [
    { level: 1, text: 'API Documentation', id: 'api-documentation' },
    { level: 2, text: 'Authentication', id: 'authentication' },
    { level: 3, text: 'API Keys', id: 'api-keys' },
    { level: 3, text: 'OAuth 2.0', id: 'oauth-2-0' },
    { level: 4, text: 'Authorization Code Flow', id: 'authorization-code-flow' },
    { level: 4, text: 'Client Credentials Flow', id: 'client-credentials-flow' },
    { level: 2, text: 'Endpoints', id: 'endpoints' },
    { level: 3, text: 'Users', id: 'users' },
    { level: 4, text: 'GET /users', id: 'get-users' },
    { level: 4, text: 'POST /users', id: 'post-users' },
    { level: 4, text: 'PUT /users/:id', id: 'put-users-id' },
    { level: 4, text: 'DELETE /users/:id', id: 'delete-users-id' },
    { level: 3, text: 'Projects', id: 'projects' },
    { level: 4, text: 'GET /projects', id: 'get-projects' },
    { level: 4, text: 'POST /projects', id: 'post-projects' },
    { level: 2, text: 'Error Handling', id: 'error-handling' },
    { level: 3, text: 'Error Codes', id: 'error-codes' },
    { level: 3, text: 'Error Response Format', id: 'error-response-format' },
    { level: 2, text: 'Rate Limiting', id: 'rate-limiting' },
    { level: 2, text: 'SDKs', id: 'sdks' },
    { level: 3, text: 'JavaScript SDK', id: 'javascript-sdk' },
    { level: 3, text: 'Python SDK', id: 'python-sdk' },
    { level: 3, text: 'Go SDK', id: 'go-sdk' }
  ]
};

/**
 * DOM Fixture Factory
 * Creates DOM structures for testing TOC functionality
 */
export class TOCDOMFixtureFactory {
  constructor() {
    this.createdElements = new Set();
  }

  /**
   * Create HTML document structure with headers
   * @param {Array} headerData - Header data array
   * @param {Object} [options={}] - Creation options
   * @returns {HTMLElement} Container element with headers
   */
  createDocumentStructure(headerData, options = {}) {
    const {
      containerId = 'test-document',
      addContent = true,
      addTOCContainer = true,
      contentLength = 'short'
    } = options;

    const container = document.createElement('div');
    container.id = containerId;
    container.className = 'test-document-container';

    // Add TOC container if requested
    if (addTOCContainer) {
      const tocContainer = document.createElement('div');
      tocContainer.id = 'toc-container';
      tocContainer.className = 'toc-container';
      container.appendChild(tocContainer);
    }

    // Add content container
    const contentContainer = document.createElement('div');
    contentContainer.id = 'content-container';
    contentContainer.className = 'content-container';

    // Create headers and content
    headerData.forEach((headerInfo) => {
      // Create header element
      const header = document.createElement(`h${headerInfo.level}`);
      header.textContent = headerInfo.text;

      if (headerInfo.id) {
        header.id = headerInfo.id;
      }

      contentContainer.appendChild(header);

      // Add content after header if requested
      if (addContent) {
        const content = this.createContentForHeader(headerInfo, contentLength);
        contentContainer.appendChild(content);
      }
    });

    container.appendChild(contentContainer);
    this.createdElements.add(container);

    return container;
  }

  /**
   * Create content section for a header
   * @param {Object} headerInfo - Header information
   * @param {string} contentLength - Content length ('short', 'medium', 'long')
   * @returns {HTMLElement} Content element
   */
  createContentForHeader(headerInfo, contentLength = 'short') {
    const content = document.createElement('div');
    content.className = 'header-content';

    const contentSizes = {
      short: 1,
      medium: 3,
      long: 5
    };

    const paragraphCount = contentSizes[contentLength] || 1;

    for (let i = 0; i < paragraphCount; i++) {
      const paragraph = document.createElement('p');
      paragraph.textContent = `This is content for "${headerInfo.text}". This paragraph provides context and information related to the section header. Paragraph ${i + 1} of ${paragraphCount}.`;
      content.appendChild(paragraph);
    }

    return content;
  }

  /**
   * Create a minimal TOC container
   * @param {string} [id='toc-container'] - Container ID
   * @returns {HTMLElement} TOC container element
   */
  createTOCContainer(id = 'toc-container') {
    const container = document.createElement('div');
    container.id = id;
    container.className = 'toc-container';

    // Add common TOC structure
    const title = document.createElement('h3');
    title.textContent = 'Table of Contents';
    title.className = 'toc-title';

    const list = document.createElement('ul');
    list.className = 'toc-list';

    container.appendChild(title);
    container.appendChild(list);

    this.createdElements.add(container);
    return container;
  }

  /**
   * Create a TOC item element
   * @param {Object} headerInfo - Header information
   * @param {Object} [options={}] - Creation options
   * @returns {HTMLElement} TOC item element
   */
  createTOCItem(headerInfo, options = {}) {
    const {
      includeLink = true,
      includeNestedList = false,
      addClasses = true
    } = options;

    const listItem = document.createElement('li');

    if (addClasses) {
      listItem.className = `toc-item toc-level-${headerInfo.level}`;
    }

    if (includeLink && headerInfo.id) {
      const link = document.createElement('a');
      link.href = `#${headerInfo.id}`;
      link.textContent = headerInfo.text;
      link.className = 'toc-link';
      listItem.appendChild(link);
    } else {
      listItem.textContent = headerInfo.text;
    }

    if (includeNestedList) {
      const nestedList = document.createElement('ul');
      nestedList.className = 'toc-nested-list';
      listItem.appendChild(nestedList);
    }

    return listItem;
  }

  /**
   * Create a complete TOC structure from header data
   * @param {Array} headerData - Header data array
   * @param {Object} [options={}] - Creation options
   * @returns {HTMLElement} Complete TOC structure
   */
  createTOCStructure(headerData, options = {}) {
    const container = this.createTOCContainer(options.containerId);
    const list = container.querySelector('.toc-list');

    const tocItems = headerData.map(headerInfo =>
      this.createTOCItem(headerInfo, options)
    );

    tocItems.forEach(item => list.appendChild(item));

    return container;
  }

  /**
   * Create responsive test viewport
   * @param {string} size - Viewport size ('mobile', 'tablet', 'desktop')
   * @returns {Object} Viewport configuration
   */
  createTestViewport(size = 'desktop') {
    const viewportSizes = {
      mobile: { width: 375, height: 667 },
      tablet: { width: 768, height: 1024 },
      desktop: { width: 1920, height: 1080 }
    };

    const viewport = viewportSizes[size];

    // Apply viewport to test environment
    if (global.window && global.window.innerWidth !== undefined) {
      Object.defineProperty(global.window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: viewport.width
      });

      Object.defineProperty(global.window, 'innerHeight', {
        writable: true,
        configurable: true,
        value: viewport.height
      });
    }

    return viewport;
  }

  /**
   * Clean up all created elements
   */
  cleanup() {
    for (const element of this.createdElements) {
      if (element.parentNode) {
        element.parentNode.removeChild(element);
      }
    }
    this.createdElements.clear();
  }
}

/**
 * Configuration Test Data
 * Predefined configurations for testing different TOC scenarios
 */
export const configTestData = {
  /**
   * Default minimal configuration
   */
  minimal: {
    container: '#toc-container',
    selectors: 'h1, h2, h3, h4, h5, h6',
    autoGenerate: true
  },

  /**
   * Complete configuration with all options
   */
  complete: {
    container: '#toc-container',
    selectors: 'h1, h2, h3, h4, h5, h6',
    autoGenerate: true,
    smoothScroll: true,
    scrollOffset: 80,
    activeClass: 'active',
    expandActiveSection: true,
    collapseInactive: true,
    animationDuration: 300,
    generateIds: true,
    idPrefix: 'toc-',
    includeLevel: [1, 2, 3, 4, 5, 6],
    excludeSelectors: '.no-toc',
    plugins: [],
    debug: false,
    performance: {
      enableMetrics: true,
      cacheEnabled: true,
      cacheDuration: 5000
    }
  },

  /**
   * Performance-optimized configuration
   */
  performance: {
    container: '#toc-container',
    selectors: 'h1, h2, h3',
    autoGenerate: false,
    smoothScroll: false,
    scrollOffset: 0,
    activeClass: 'active',
    expandActiveSection: false,
    collapseInactive: false,
    animationDuration: 0,
    generateIds: false,
    includeLevel: [1, 2, 3],
    plugins: [],
    debug: false,
    performance: {
      enableMetrics: true,
      cacheEnabled: true,
      cacheDuration: 10000,
      throttleScroll: 16,
      debounceResize: 100
    }
  },

  /**
   * Accessibility-focused configuration
   */
  accessibility: {
    container: '#toc-container',
    selectors: 'h1, h2, h3, h4, h5, h6',
    autoGenerate: true,
    smoothScroll: true,
    scrollOffset: 100,
    activeClass: 'active',
    expandActiveSection: true,
    collapseInactive: false,
    animationDuration: 200,
    generateIds: true,
    idPrefix: 'section-',
    includeLevel: [1, 2, 3, 4, 5, 6],
    accessibility: {
      announceChanges: true,
      keyboardNavigation: true,
      ariaLabels: true,
      focusManagement: true,
      skipToContent: true
    },
    debug: false
  },

  /**
   * Plugin-heavy configuration for testing
   */
  withPlugins: {
    container: '#toc-container',
    selectors: 'h1, h2, h3, h4, h5, h6',
    autoGenerate: true,
    smoothScroll: true,
    scrollOffset: 80,
    activeClass: 'active',
    plugins: [
      {
        name: 'test-plugin-1',
        priority: 10,
        execute: () => ({ result: 'plugin-1-executed' })
      },
      {
        name: 'test-plugin-2',
        priority: 5,
        execute: () => ({ result: 'plugin-2-executed' })
      },
      {
        name: 'test-plugin-3',
        priority: 15,
        execute: () => ({ result: 'plugin-3-executed' })
      }
    ],
    debug: true
  },

  /**
   * Error-prone configuration for testing error handling
   */
  errorProne: {
    container: null, // Invalid container
    selectors: '', // Empty selectors
    autoGenerate: true,
    scrollOffset: 'invalid', // Invalid type
    includeLevel: [0, 7, 8], // Invalid levels
    invalidOption: 'should-cause-error' // Unknown option
  }
};

/**
 * Mock Data for Testing
 * Predefined mock responses and test data
 */
export const mockTestData = {
  /**
   * Mock event data for testing event coordination
   */
  events: {
    headerClick: {
      type: 'toc:header-click',
      detail: {
        headerId: 'test-header',
        headerText: 'Test Header',
        headerLevel: 2
      }
    },

    scrollUpdate: {
      type: 'toc:scroll-update',
      detail: {
        activeHeader: 'current-header',
        scrollPosition: 500,
        direction: 'down'
      }
    },

    tocGenerated: {
      type: 'toc:generated',
      detail: {
        structure: headerTestData.nested,
        metadata: {
          totalHeaders: 12,
          maxLevel: 4,
          minLevel: 1
        }
      }
    }
  },

  /**
   * Mock API responses for Docsify integration testing
   */
  docsifyResponses: {
    routeChange: {
      path: '/docs/getting-started',
      query: {},
      title: 'Getting Started'
    },

    contentLoaded: {
      content: '<h1>Test Content</h1><p>Test paragraph</p>',
      headers: headerTestData.simple
    }
  },

  /**
   * Mock performance data
   */
  performance: {
    metrics: {
      tocGeneration: 45,
      domUpdate: 12,
      scrollTracking: 8,
      eventProcessing: 3
    },

    thresholds: {
      tocGeneration: 100,
      domUpdate: 50,
      scrollTracking: 20,
      eventProcessing: 10
    }
  }
};

/**
 * Test Scenario Factory
 * Creates complete test scenarios with all required data
 */
export class TOCTestScenarioFactory {
  constructor() {
    this.domFactory = new TOCDOMFixtureFactory();
  }

  /**
   * Create simple TOC generation scenario
   * @param {Object} [options={}] - Scenario options
   * @returns {Object} Complete test scenario
   */
  createSimpleScenario(options = {}) {
    const headerData = options.headers || headerTestData.simple;
    const config = options.config || configTestData.minimal;

    return {
      name: 'Simple TOC Generation',
      description: 'Test basic TOC generation with simple header structure',
      headerData,
      config,
      dom: this.domFactory.createDocumentStructure(headerData),
      expectedOutput: {
        itemCount: headerData.length,
        levels: [...new Set(headerData.map(h => h.level))],
        structure: 'flat'
      }
    };
  }

  /**
   * Create nested TOC scenario
   * @param {Object} [options={}] - Scenario options
   * @returns {Object} Complete test scenario
   */
  createNestedScenario(options = {}) {
    const headerData = options.headers || headerTestData.nested;
    const config = options.config || configTestData.complete;

    return {
      name: 'Nested TOC Structure',
      description: 'Test TOC generation with complex nested header hierarchy',
      headerData,
      config,
      dom: this.domFactory.createDocumentStructure(headerData),
      expectedOutput: {
        itemCount: headerData.length,
        levels: [...new Set(headerData.map(h => h.level))],
        structure: 'nested',
        maxDepth: Math.max(...headerData.map(h => h.level))
      }
    };
  }

  /**
   * Create performance test scenario
   * @param {Object} [options={}] - Scenario options
   * @returns {Object} Complete test scenario
   */
  createPerformanceScenario(options = {}) {
    const headerData = options.headers || headerTestData.large;
    const config = options.config || configTestData.performance;

    return {
      name: 'Performance Test',
      description: 'Test TOC performance with large header dataset',
      headerData,
      config,
      dom: this.domFactory.createDocumentStructure(headerData, { addContent: false }),
      expectedOutput: {
        itemCount: headerData.length,
        performanceThresholds: mockTestData.performance.thresholds
      },
      performanceExpectations: {
        maxGenerationTime: 100,
        maxMemoryUsage: 1024 * 1024, // 1MB
        maxDOMOperations: headerData.length * 2
      }
    };
  }

  /**
   * Create error handling scenario
   * @param {Object} [options={}] - Scenario options
   * @returns {Object} Complete test scenario
   */
  createErrorScenario(options = {}) {
    const config = options.config || configTestData.errorProne;

    return {
      name: 'Error Handling Test',
      description: 'Test error handling with invalid configurations and edge cases',
      headerData: [],
      config,
      dom: document.createElement('div'), // Minimal DOM
      expectedErrors: [
        'Invalid container',
        'Empty selectors',
        'Invalid scroll offset',
        'Invalid header levels'
      ]
    };
  }

  /**
   * Clean up all created scenarios
   */
  cleanup() {
    this.domFactory.cleanup();
  }
}

// Export singleton instances for convenience
export const domFixtureFactory = new TOCDOMFixtureFactory();
export const testScenarioFactory = new TOCTestScenarioFactory();

// Export all test data and utilities
export default {
  headerTestData,
  configTestData,
  mockTestData,
  TOCDOMFixtureFactory,
  TOCTestScenarioFactory,
  domFixtureFactory,
  testScenarioFactory
};
