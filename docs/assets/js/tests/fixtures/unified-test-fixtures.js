/**
 * Unified Test Fixtures for TOC Manager
 *
 * Consolidated fixture collection providing all DOM structures,
 * mock data, and test scenarios needed for comprehensive TOC Manager testing.
 *
 * @description Fixture Categories:
 * - DOM fixtures: HTML structures for various testing scenarios
 * - CSS fixtures: Styling and layout configurations
 * - Mock data: Simulated API responses and data structures
 * - Test scenarios: Pre-configured test cases and edge cases
 * - Performance fixtures: Large content for performance testing
 *
 * @architecture
 * This unified fixture system replaces and consolidates:
 * - css-fixtures.js (CSS and styling fixtures)
 * - Individual test data files
 * - Inline test HTML structures
 * - Mock data scattered across test files
 *
 * @version 2.0.0
 */

/**
 * DOM Fixtures - HTML structures for testing various scenarios
 */
const domFixtures = {
  // Simple header structure for basic testing
  simpleHeaders: `
    <h1 id="intro">Introduction</h1>
    <h2 id="getting-started">Getting Started</h2>
    <h3 id="installation">Installation</h3>
    <h2 id="usage">Usage</h2>
    <h3 id="basic-usage">Basic Usage</h3>
  `,

  // Mixed header levels with gaps
  mixedHeaders: `
    <h1 id="overview">Overview</h1>
    <h2 id="section-1">Section 1</h2>
    <h4 id="subsection-1">Subsection 1</h4>
    <h1 id="section-2">Section 2</h1>
    <h2 id="section-2-1">Section 2.1</h2>
    <h3 id="section-2-1-1">Section 2.1.1</h3>
  `,

  // Headers without IDs (for ID generation testing)
  headersWithoutIds: `
    <h1>Main Title</h1>
    <h2>First Section</h2>
    <h3>Subsection A</h3>
    <h3>Subsection B</h3>
    <h2>Second Section</h2>
  `,

  // Headers with existing IDs (for ID preservation testing)
  headersWithIds: `
    <h1 id="intro">Introduction</h1>
    <h2 id="getting-started">Getting Started</h2>
    <h3 id="advanced">Advanced Topics</h3>
  `,

  // Hierarchical structure for nesting tests
  hierarchicalHeaders: `
    <h1 id="chapter-1">Chapter 1</h1>
    <h2 id="section-1-1">Section 1.1</h2>
    <h3 id="section-1-1-1">Section 1.1.1</h3>
    <h2 id="section-1-2">Section 1.2</h2>
    <h1 id="chapter-2">Chapter 2</h1>
    <h2 id="section-2-1">Section 2.1</h2>
  `,

  // Irregular header structure (skipping levels)
  irregularHeaders: `
    <h1 id="title">Title</h1>
    <h3 id="skip-level">Skipped H2</h3>
    <h2 id="back-to-h2">Back to H2</h2>
    <h5 id="skip-to-h5">Skip to H5</h5>
    <h1 id="another-h1">Another H1</h1>
  `,

  // Scrollable content for scroll testing
  scrollableContent: `
    <div style="height: 200px; overflow-y: scroll;">
      <h1 id="section-1">Section 1</h1>
      <div style="height: 300px;">Content for section 1...</div>
      <h2 id="section-2">Section 2</h2>
      <div style="height: 300px;">Content for section 2...</div>
      <h2 id="section-3">Section 3</h2>
      <div style="height: 300px;">Content for section 3...</div>
    </div>
  `,

  // Nested scrollable content
  nestedScrollableContent: `
    <div style="height: 300px; overflow-y: scroll;">
      <h1 id="chapter-1">Chapter 1</h1>
      <div style="height: 200px;">Chapter 1 content...</div>
      <h2 id="section-1-1">Section 1.1</h2>
      <div style="height: 200px;">Section 1.1 content...</div>
      <h3 id="section-1-1-1">Section 1.1.1</h3>
      <div style="height: 200px;">Section 1.1.1 content...</div>
      <h2 id="section-1-2">Section 1.2</h2>
      <div style="height: 200px;">Section 1.2 content...</div>
    </div>
  `,

  // Complex headers with nested elements
  complexHeaders: `
    <h1 id="complex-1">
      <span class="icon">📚</span>
      <span class="text">Complex Header</span>
      <small class="subtitle">with subtitle</small>
    </h1>
    <h2 id="complex-2">
      <code>code</code> in header with <a href="#">link</a>
    </h2>
    <h3 id="complex-3">
      Header with <em>emphasis</em> and <strong>strong</strong> text
    </h3>
  `,

  // Docsify-specific content structure
  docsifyContent: `
    <div id="main">
      <h1 id="docsify-title">Docsify Document</h1>
      <h2 id="docsify-section-1">Section 1</h2>
      <h3 id="docsify-subsection-1">Subsection 1</h3>
      <h2 id="docsify-section-2">Section 2</h2>
    </div>
  `,

  // Malformed HTML for error testing
  malformedHTML: `
    <h1 id="unclosed">Unclosed Header
    <h2>Missing ID</h2>
    <h3 id="">Empty ID</h3>
    <h4 id="duplicate">Duplicate</h4>
    <h5 id="duplicate">Duplicate</h5>
  `,

  // Duplicate IDs for conflict resolution testing
  duplicateIds: `
    <h1 id="duplicate">First Header</h1>
    <h2 id="duplicate">Second Header</h2>
    <h3 id="duplicate">Third Header</h3>
  `,

  // Large content for performance testing
  largeContent: generateLargeContent(100),

  // Medium content for standard performance testing
  mediumContent: generateLargeContent(50)
};

/**
 * Generate large content for performance testing
 */
function generateLargeContent(count) {
  let content = '';
  for (let i = 1; i <= count; i++) {
    content += `
      <h1 id="section-${i}">Section ${i}</h1>
      <p>Content for section ${i}...</p>
      <h2 id="subsection-${i}-1">Subsection ${i}.1</h2>
      <p>Subsection content...</p>
      <h3 id="subsubsection-${i}-1-1">Subsubsection ${i}.1.1</h3>
      <p>Detailed content...</p>
    `;
  }
  return content;
}

/**
 * CSS Fixtures - Styling and layout configurations
 */
const cssFixtures = {
  // Basic TOC styling
  basicTOCStyles: `
    #toc-container {
      position: fixed;
      top: 0;
      right: 0;
      width: 250px;
      height: 100vh;
      overflow-y: auto;
      background: #f5f5f5;
      border-left: 1px solid #ddd;
      padding: 20px;
    }

    #toc-container ul {
      list-style: none;
      padding-left: 0;
      margin: 0;
    }

    #toc-container li {
      margin: 5px 0;
    }

    #toc-container a {
      text-decoration: none;
      color: #333;
      display: block;
      padding: 5px 10px;
      border-radius: 3px;
      transition: background-color 0.2s;
    }

    #toc-container a:hover {
      background-color: #e0e0e0;
    }

    #toc-container a.active {
      background-color: #007acc;
      color: white;
    }
  `,

  // Responsive TOC styling
  responsiveTOCStyles: `
    @media (max-width: 768px) {
      #toc-container {
        position: relative;
        width: 100%;
        height: auto;
        max-height: 300px;
        margin-bottom: 20px;
      }
    }

    @media (max-width: 480px) {
      #toc-container {
        font-size: 14px;
      }

      #toc-container a {
        padding: 8px 12px;
      }
    }
  `,

  // High contrast styling
  highContrastStyles: `
    .high-contrast #toc-container {
      background: black;
      color: white;
      border-color: white;
    }

    .high-contrast #toc-container a {
      color: white;
      border: 1px solid transparent;
    }

    .high-contrast #toc-container a:hover {
      background-color: yellow;
      color: black;
    }

    .high-contrast #toc-container a.active {
      background-color: white;
      color: black;
      border-color: yellow;
    }
  `,

  // Animation styles
  animationStyles: `
    .toc-loading {
      opacity: 0.5;
      animation: pulse 1.5s ease-in-out infinite;
    }

    @keyframes pulse {
      0% { opacity: 0.5; }
      50% { opacity: 1; }
      100% { opacity: 0.5; }
    }

    .fade-in {
      animation: fadeIn 0.3s ease-in-out;
    }

    @keyframes fadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }

    .highlighted {
      background-color: yellow;
      transition: background-color 0.3s ease;
    }
  `,

  // Print styles
  printStyles: `
    @media print {
      #toc-container {
        position: static;
        width: 100%;
        height: auto;
        background: white;
        border: none;
        page-break-inside: avoid;
      }

      #toc-container a {
        color: black;
        text-decoration: underline;
      }
    }
  `
};

/**
 * Mock Data - Simulated API responses and data structures
 */
const mockData = {
  // TOC structure data
  tocStructures: {
    simple: [
      {
        id: 'intro',
        text: 'Introduction',
        level: 1,
        children: []
      },
      {
        id: 'getting-started',
        text: 'Getting Started',
        level: 2,
        children: [
          {
            id: 'installation',
            text: 'Installation',
            level: 3,
            children: []
          }
        ]
      }
    ],

    complex: [
      {
        id: 'chapter-1',
        text: 'Chapter 1',
        level: 1,
        children: [
          {
            id: 'section-1-1',
            text: 'Section 1.1',
            level: 2,
            children: [
              {
                id: 'section-1-1-1',
                text: 'Section 1.1.1',
                level: 3,
                children: []
              }
            ]
          }
        ]
      }
    ]
  },

  // Configuration presets
  configurations: {
    minimal: {
      selector: 'h1, h2',
      container: '#toc-container',
      smoothScroll: false,
      enableScrollSpy: false
    },

    full: {
      selector: 'h1, h2, h3, h4, h5, h6',
      container: '#toc-container',
      linkClass: 'toc-link',
      activeClass: 'active',
      smoothScroll: true,
      offset: 50,
      enableScrollSpy: true,
      enableHighlighting: true,
      enableResizeObserver: true,
      enableKeyboardNavigation: true,
      announceChanges: true
    },

    docsify: {
      enableDocsifyIntegration: true,
      standaloneMode: false,
      router: {
        mode: 'hash'
      }
    },

    performance: {
      enableCaching: true,
      enablePerformanceMonitoring: true,
      scrollThrottleMs: 100,
      enablePlugins: true
    }
  },

  // Performance metrics
  performanceMetrics: {
    fast: {
      generationTime: 45,
      headerCount: 10,
      cacheHitRate: 0.8,
      memoryUsage: 1024
    },

    slow: {
      generationTime: 650,
      headerCount: 100,
      cacheHitRate: 0.2,
      memoryUsage: 5120
    }
  },

  // Event data
  events: {
    initialized: {
      type: 'initialized',
      timestamp: Date.now(),
      details: { version: '2.0.0' }
    },

    generated: {
      type: 'generated',
      timestamp: Date.now(),
      details: { headerCount: 5, generationTime: 120 }
    },

    activeHeaderChanged: {
      type: 'activeHeaderChanged',
      timestamp: Date.now(),
      details: {
        previousId: 'section-1',
        currentId: 'section-2',
        element: null // Will be populated with actual element
      }
    }
  }
};

/**
 * Test Scenarios - Pre-configured test cases and edge cases
 */
const testScenarios = {
  // Basic functionality scenarios
  basic: {
    name: 'Basic TOC Generation',
    html: domFixtures.simpleHeaders,
    config: mockData.configurations.minimal,
    expectedHeaders: 5,
    expectedTOCLinks: 5
  },

  // Integration scenarios
  integration: {
    docsify: {
      name: 'Docsify Integration',
      html: domFixtures.docsifyContent,
      config: mockData.configurations.docsify,
      setup: () => {
        window.$docsify = { router: { mode: 'hash' } };
      },
      cleanup: () => {
        delete window.$docsify;
      }
    },

    scrollSpy: {
      name: 'Scroll Spy Integration',
      html: domFixtures.scrollableContent,
      config: { enableScrollSpy: true },
      simulateScroll: (targetId) => {
        const target = document.getElementById(targetId);
        if (target) {
          target.scrollIntoView();
        }
      }
    }
  },

  // Performance scenarios
  performance: {
    large: {
      name: 'Large Content Performance',
      html: domFixtures.largeContent,
      config: mockData.configurations.performance,
      expectedMaxTime: 1000,
      expectedMaxMemory: 5 * 1024 * 1024
    },

    stress: {
      name: 'Stress Test',
      html: generateLargeContent(500),
      config: mockData.configurations.full,
      expectedMaxTime: 2000
    }
  },

  // Error scenarios
  errors: {
    malformed: {
      name: 'Malformed HTML',
      html: domFixtures.malformedHTML,
      config: mockData.configurations.minimal,
      expectsError: false, // Should handle gracefully
      expectedHeaders: 5 // Should still process valid headers
    },

    missing: {
      name: 'Missing Container',
      html: domFixtures.simpleHeaders,
      config: { container: '#non-existent' },
      expectsError: false, // Should handle gracefully
      expectedTOCLinks: 0
    },

    duplicates: {
      name: 'Duplicate IDs',
      html: domFixtures.duplicateIds,
      config: mockData.configurations.minimal,
      expectsError: false,
      expectedUniqueIds: true
    }
  },

  // Accessibility scenarios
  accessibility: {
    keyboard: {
      name: 'Keyboard Navigation',
      html: domFixtures.simpleHeaders,
      config: {
        enableKeyboardNavigation: true,
        announceChanges: true
      },
      testKeys: ['Tab', 'Enter', 'Space', 'ArrowDown', 'ArrowUp']
    },

    screenReader: {
      name: 'Screen Reader Support',
      html: domFixtures.simpleHeaders,
      config: { announceChanges: true },
      expectedARIA: ['role', 'aria-label', 'aria-live']
    },

    highContrast: {
      name: 'High Contrast Mode',
      html: domFixtures.simpleHeaders,
      config: { enableHighContrast: true },
      mediaQuery: '(prefers-contrast: high)'
    }
  }
};

/**
 * Utility Functions for Fixture Management
 */
const fixtureUtils = {
  /**
   * Inject CSS styles into the test document
   */
  injectCSS(cssContent, id = 'test-styles') {
    // Remove existing styles
    const existing = document.getElementById(id);
    if (existing) {
      existing.remove();
    }

    // Create and inject new styles
    const style = document.createElement('style');
    style.id = id;
    style.textContent = cssContent;
    document.head.appendChild(style);

    return style;
  },

  /**
   * Create a DOM container with specified content
   */
  createContainer(content, id = 'test-container') {
    // Remove existing container
    const existing = document.getElementById(id);
    if (existing) {
      existing.remove();
    }

    // Create new container
    const container = document.createElement('div');
    container.id = id;
    container.innerHTML = content;
    document.body.appendChild(container);

    return container;
  },

  /**
   * Create TOC container element
   */
  createTOCContainer(id = 'toc-container') {
    // Remove existing TOC container
    const existing = document.getElementById(id);
    if (existing) {
      existing.remove();
    }

    // Create new TOC container with proper nested structure
    const tocContainer = document.createElement('div');
    tocContainer.id = id;

    // Create inner page_toc element
    const pageToc = document.createElement('div');
    pageToc.className = 'page_toc';
    tocContainer.appendChild(pageToc);

    document.body.appendChild(tocContainer);

    return tocContainer;
  },

  /**
   * Setup complete test environment
   */
  setupEnvironment(scenario) {
    // Clean up existing environment
    this.cleanup();

    // Inject CSS if specified
    if (scenario.css || cssFixtures.basicTOCStyles) {
      this.injectCSS(scenario.css || cssFixtures.basicTOCStyles);
    }

    // Create containers
    const container = this.createContainer(scenario.html);
    const tocContainer = this.createTOCContainer();

    // Run setup if specified
    if (scenario.setup) {
      scenario.setup();
    }

    return { container, tocContainer };
  },

  /**
   * Cleanup test environment
   */
  cleanup() {
    // Remove test styles
    const styles = document.querySelectorAll('style[id*="test"]');
    styles.forEach(style => style.remove());

    // Remove test containers (including content containers used in tests)
    const containers = document.querySelectorAll('[id*="test"], [id*="toc"], #content');
    containers.forEach(container => container.remove());

    // Clear any global test state
    delete window.$docsify;

    // Enhanced cleanup - remove all test-related elements
    const testElements = document.querySelectorAll(
      '[data-test], [class*="test"], .test-container, .progress-tracker, .learning-path'
    );
    testElements.forEach(element => element.remove());

    // Reset document state
    if (document.body) {
      // Clear body classes that might have been added during testing
      document.body.className = '';

      // Reset any custom properties
      document.body.style.cssText = '';
    }

    // Clear any remaining event listeners by cloning and replacing body
    if (document.body && document.body.parentNode) {
      const oldBody = document.body;
      const newBody = document.createElement('body');

      // Copy essential attributes but not event listeners
      if (oldBody.id) {newBody.id = oldBody.id;}
      if (oldBody.className) {newBody.className = '';}

      oldBody.parentNode.replaceChild(newBody, oldBody);
    }

    // Clear global fixture state
    delete globalThis.fixtureData;
    delete globalThis.testFixtures;

    // Reset window properties that might affect tests
    if (typeof window !== 'undefined') {
      window.scrollX = 0;
      window.scrollY = 0;
      window.pageXOffset = 0;
      window.pageYOffset = 0;

      // Clear location hash if set
      if (window.location && window.location.hash) {
        try {
          window.location.hash = '';
        } catch (_e) {
          // Ignore errors in test environment
        }
      }
    }
  },

  /**
   * Wait for animation/transition to complete
   */
  async waitForTransition(element, property = 'all', timeout = 1000) {
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        reject(new Error('Transition timeout'));
      }, timeout);

      const handleTransitionEnd = (event) => {
        if (event.target === element && (property === 'all' || event.propertyName === property)) {
          clearTimeout(timer);
          element.removeEventListener('transitionend', handleTransitionEnd);
          resolve();
        }
      };

      element.addEventListener('transitionend', handleTransitionEnd);
    });
  },

  /**
   * Simulate user interactions
   */
  simulate: {
    click(element) {
      const event = new MouseEvent('click', {
        bubbles: true,
        cancelable: true,
        view: window
      });
      element.dispatchEvent(event);
    },

    keydown(element, key) {
      const event = new KeyboardEvent('keydown', {
        key,
        bubbles: true,
        cancelable: true
      });
      element.dispatchEvent(event);
    },

    scroll(element, scrollTop) {
      element.scrollTop = scrollTop;
      const event = new Event('scroll', {
        bubbles: true,
        cancelable: true
      });
      element.dispatchEvent(event);
    },

    resize(width, height) {
      Object.defineProperty(window, 'innerWidth', { value: width, configurable: true });
      Object.defineProperty(window, 'innerHeight', { value: height, configurable: true });
      window.dispatchEvent(new Event('resize'));
    }
  }
};

/**
 * Main Unified Test Fixtures Export
 */
export const unifiedTestFixtures = {
  // Fixture categories
  dom: domFixtures,
  css: cssFixtures,
  mock: mockData,
  scenarios: testScenarios,

  // Utility functions
  utils: fixtureUtils,

  // Convenience methods
  create(type = 'basic') {
    if (testScenarios[type]) {
      return fixtureUtils.setupEnvironment(testScenarios[type]);
    }
    return fixtureUtils.setupEnvironment({ html: domFixtures.simpleHeaders });
  },

  cleanup() {
    fixtureUtils.cleanup();
  },

  injectCSS(content, id) {
    return fixtureUtils.injectCSS(content, id);
  },

  // Preset configurations
  getConfig(name) {
    return mockData.configurations[name] || mockData.configurations.minimal;
  },

  // HTML generators
  generateHTML(type, ...args) {
    switch (type) {
      case 'large':
        return generateLargeContent(args[0] || 100);
      case 'simple':
        return domFixtures.simpleHeaders;
      case 'complex':
        return domFixtures.complexHeaders;
      default:
        return domFixtures.simpleHeaders;
    }
  }
};

export default unifiedTestFixtures;
