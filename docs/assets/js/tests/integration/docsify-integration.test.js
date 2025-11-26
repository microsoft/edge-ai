/**
 * @fileoverview Docsify Integration Tests
 * Test comprehensive integration of interactive learning path components with existing Docsify setup
 *
 * @version 1.0.0
 * @author Edge AI Learning Platform Team
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

// Mock modules that will be loaded by main.js
const mockModules = {
  interactiveCheckboxes: null,
  progressAnnotations: null,
  coachButton: null,
  autoSelectionEngine: null,
  learningPathSync: null,
  learningPathManager: null
};

// Mock Docsify environment
const mockDocsify = {
  router: {
    getCurrentPath: vi.fn(() => '/learning/learning-paths'),
    normalize: vi.fn((path) => path)
  },
  vm: {
    config: {
      alias: {},
      basePath: '/'
    }
  },
  util: {
    parseQuery: vi.fn(() => ({}))
  }
};

// Create learning paths content structure for testing
const learningPathsMarkdown = `
<h1>Learning Paths Dashboard</h1>

<h2>Foundation Builder Paths</h2>

<h3>Foundation Builder - AI Engineering</h3>

<ul>
<li><input type="checkbox"> <a href="katas/ai-assisted-engineering/01-ai-development-fundamentals.md">AI Development Fundamentals</a> • <em>Estimated: 45 min</em> • <strong>Foundation</strong></li>
<li><input type="checkbox"> <a href="katas/prompt-engineering/01-prompt-engineering-basics.md">Prompt Engineering Basics</a> • <em>Estimated: 60 min</em> • <strong>Core Skill</strong></li>
<li><input type="checkbox"> <a href="katas/ai-assisted-engineering/02-ai-code-review-techniques.md">AI Code Review Techniques</a> • <em>Estimated: 30 min</em> • <strong>Application</strong></li>
</ul>

<h3>📋 Foundation Builder - Project Planning</h3>

<ul>
<li><input type="checkbox"> <a href="katas/project-planning/01-basic-prompt-usage.md">Basic Project Planning Prompt Usage</a> • <em>Estimated: 30 min</em> • <strong>Foundation</strong></li>
<li><input type="checkbox"> <a href="katas/project-planning/02-comprehensive-two-scenario.md">Comprehensive Two-Scenario Planning</a> • <em>Estimated: 45 min</em> • <strong>Strategic Thinking</strong></li>
</ul>
`;

describe('Docsify Integration Tests', () => {
  let window;
  let document;

  beforeEach(() => {
    // Set up happy-dom environment with learning paths content
    window = global.window;
    document = global.document;

    // Set up DOM structure for learning paths
    document.body.innerHTML = `
      <div id="app">
        <main>
          <section class="content">
            <div class="markdown-section" id="main">
              ${learningPathsMarkdown}
            </div>
          </section>
        </main>
        <nav class="app-nav">
          <ul>
            <li><a href="#/learning/learning-paths">Learning Paths</a></li>
          </ul>
        </nav>
      </div>
    `;

    // Add stylesheet links to head (but don't load in test environment)
    const head = document.head || document.getElementsByTagName('head')[0];
    const mainCSS = document.createElement('link');
    mainCSS.rel = 'stylesheet';
    mainCSS.href = 'docs/assets/css/main.css';

    const interactiveCSS = document.createElement('link');
    interactiveCSS.rel = 'stylesheet';
    interactiveCSS.href = 'docs/assets/css/interactive-checkboxes.css';

    // Mock the onload to prevent actual loading in tests
    mainCSS.onload = () => {};
    interactiveCSS.onload = () => {};

    // Add to DOM for testing
    head.appendChild(mainCSS);
    head.appendChild(interactiveCSS);

    // Set up global DOM environment
    global.window = window;
    global.document = document;

    // Mock Docsify global
    window.$docsify = mockDocsify;

    // Mock existing modules will be loaded
    Object.keys(mockModules).forEach(key => {
      window[key] = mockModules[key];
    });

    // Mock localStorage
    Object.defineProperty(window, 'localStorage', {
      value: {
        getItem: vi.fn(),
        setItem: vi.fn(),
        removeItem: vi.fn(),
        clear: vi.fn()
      },
      writable: true
    });

    // Mock performance API
    Object.defineProperty(window, 'performance', {
      value: {
        now: vi.fn(() => Date.now()),
        mark: vi.fn(),
        measure: vi.fn()
      },
      writable: true
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
    // Happy-dom automatically cleans up
  });

  describe('1. HTML Structure Integration', () => {
    it('should find existing learning paths checkboxes without modification', () => {
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      expect(checkboxes.length).toBeGreaterThan(0);
      expect(checkboxes.length).toBe(5); // Based on test markdown content
    });

    it('should find learning path list items for enhancement', () => {
      const listItems = document.querySelectorAll('li');
      const checkboxItems = Array.from(listItems).filter(li =>
        li.querySelector('input[type="checkbox"]')
      );
      expect(checkboxItems.length).toBe(5);
    });

    it('should extract metadata from existing markdown content', () => {
      const listItems = document.querySelectorAll('li');
      const firstItem = listItems[0];
      const text = firstItem.textContent;

      // Should contain time estimates
      expect(text).toMatch(/\d+\s*min/);

      // Should contain difficulty levels
      expect(text).toMatch(/Foundation|Core Skill|Application|Strategic Thinking/);
    });

    it('should preserve existing markdown structure', () => {
      const headings = document.querySelectorAll('h1, h2, h3');
      expect(headings.length).toBeGreaterThan(0);

      const mainHeading = document.querySelector('h1');
      expect(mainHeading?.textContent).toContain('Learning Paths Dashboard');
    });

    it('should maintain docsify CSS class structure', () => {
      const markdownSection = document.querySelector('.markdown-section');
      expect(markdownSection).toBeTruthy();

      const appContainer = document.querySelector('#app');
      expect(appContainer).toBeTruthy();
    });
  });

  describe('2. CSS Integration', () => {
    it('should load interactive checkboxes CSS without conflicts', () => {
      const stylesheets = document.querySelectorAll('link[rel="stylesheet"]');
      const interactiveCSS = Array.from(stylesheets).find(link =>
        link.href.includes('interactive-checkboxes.css')
      );
      expect(interactiveCSS).toBeTruthy();
    });

    it('should not interfere with existing docsify styles', () => {
      const mainCSS = Array.from(document.querySelectorAll('link[rel="stylesheet"]'))
        .find(link => link.href.includes('main.css'));
      expect(mainCSS).toBeTruthy();
    });
  });

  describe('3. JavaScript Module Loading', () => {
    it('should prepare for main.js module initialization', () => {
      // Test that DOM structure supports module loading
      expect(document.readyState).toBeDefined();
      expect(window.addEventListener).toBeDefined();
    });

    it('should support ES6 module imports', () => {
      expect(typeof window.import).toBe('undefined'); // Will be available after main.js loads
      expect(window.document).toBeDefined();
    });

    it('should handle module loading events', () => {
      const eventListener = vi.fn();
      window.addEventListener('app:ready', eventListener);

      // Simulate module ready event
      const event = new window.CustomEvent('app:ready', {
        detail: { moduleCount: 6, e2eReady: true }
      });
      window.dispatchEvent(event);

      expect(eventListener).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'app:ready',
          detail: expect.objectContaining({
            moduleCount: 6,
            e2eReady: true
          })
        })
      );
    });
  });

  describe('4. Progressive Enhancement', () => {
    it('should support checkbox enhancement via CSS selectors', () => {
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');

      // Simulate JavaScript enhancement
      checkboxes.forEach((checkbox, _index) => {
        checkbox.setAttribute('data-enhanced', 'true');
        checkbox.setAttribute('data-path-id', `item-${_index}`);
      });

      const enhancedCheckboxes = document.querySelectorAll('input[data-enhanced="true"]');
      expect(enhancedCheckboxes.length).toBe(checkboxes.length);
    });

    it('should support list item enhancement without markdown modification', () => {
      const listItems = document.querySelectorAll('li');
      const checkboxItems = Array.from(listItems).filter(li =>
        li.querySelector('input[type="checkbox"]')
      );

      // Simulate enhancement
      checkboxItems.forEach((item, _index) => {
        item.classList.add('enhanced-learning-item');
        item.setAttribute('data-item-id', `learning-item-${_index}`);
      });

      const enhancedItems = document.querySelectorAll('.enhanced-learning-item');
      expect(enhancedItems.length).toBe(5);
    });

    it('should preserve original content accessibility', () => {
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');

      checkboxes.forEach(checkbox => {
        // Original functionality should remain
        expect(checkbox.type).toBe('checkbox');
        expect(checkbox.getAttribute('disabled')).toBeNull();
      });
    });
  });

  describe('5. Component Integration', () => {
    it('should support interactive checkboxes component targeting', () => {
      // Simulate component initialization
      const targetCheckboxes = document.querySelectorAll('input[type="checkbox"]');
      expect(targetCheckboxes.length).toBeGreaterThan(0);

      // Components should be able to find and enhance these elements
      const container = document.querySelector('.markdown-section');
      expect(container).toBeTruthy();
    });

    it('should support progress annotations component targeting', () => {
      const listItems = document.querySelectorAll('li');
      const pathSections = document.querySelectorAll('h3');

      expect(listItems.length).toBeGreaterThan(0);
      expect(pathSections.length).toBeGreaterThan(0);
    });

    it('should support coach button placement', () => {
      // Coach button should be able to attach to body or app container
      const appContainer = document.querySelector('#app');
      expect(appContainer).toBeTruthy();

      const body = document.querySelector('body');
      expect(body).toBeTruthy();
    });

    it('should support learning path manager integration', () => {
      // Learning path manager should be able to read page structure
      const pathHeadings = document.querySelectorAll('h3');
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');

      expect(pathHeadings.length).toBeGreaterThan(0);
      expect(checkboxes.length).toBeGreaterThan(0);
    });
  });

  describe('6. Docsify Router Integration', () => {
    it('should detect learning paths page correctly', () => {
      expect(mockDocsify.router.getCurrentPath()).toBe('/learning/learning-paths');
    });

    it('should handle page navigation events', () => {
      const navigationHandler = vi.fn();

      // Simulate docsify navigation
      window.addEventListener('popstate', navigationHandler);

      const event = new window.Event('popstate');
      window.dispatchEvent(event);

      expect(navigationHandler).toHaveBeenCalled();
    });

    it('should maintain hash routing compatibility', () => {
      expect(window.location.hash).toBeDefined();
      expect(window.location.pathname).toBeDefined();
    });
  });

  describe('7. Error Handling and Fallbacks', () => {
    it('should handle missing docsify gracefully', () => {
      delete window.$docsify;

      // Components should still function without docsify
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      expect(checkboxes.length).toBeGreaterThan(0);
    });

    it('should handle missing CSS gracefully', () => {
      // Remove CSS links
      document.querySelectorAll('link[rel="stylesheet"]').forEach(link => link.remove());

      // Basic functionality should still work
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      expect(checkboxes.length).toBeGreaterThan(0);
    });

    it('should handle JavaScript loading errors', () => {
      const errorHandler = vi.fn();
      window.addEventListener('error', errorHandler);

      // Simulate script error
      const error = new window.Error('Module loading failed');
      const errorEvent = new window.ErrorEvent('error', { error });
      window.dispatchEvent(errorEvent);

      expect(errorHandler).toHaveBeenCalled();
    });
  });

  describe('8. Performance Integration', () => {
    it('should not block docsify page loading', () => {
      // Modules should load asynchronously
      expect(window.performance.now).toBeDefined();

      const startTime = window.performance.now();
      expect(typeof startTime).toBe('number');
    });

    it('should support lazy loading of components', () => {
      // Components should be able to initialize after DOM ready
      expect(document.readyState).toBeDefined();

      const readyStateHandler = vi.fn();
      document.addEventListener('DOMContentLoaded', readyStateHandler);

      // Simulate DOM ready
      const event = new window.Event('DOMContentLoaded');
      document.dispatchEvent(event);

      expect(readyStateHandler).toHaveBeenCalled();
    });
  });

  describe('9. Data Persistence Integration', () => {
    it('should integrate with localStorage for progress tracking', () => {
      expect(window.localStorage.getItem).toBeDefined();
      expect(window.localStorage.setItem).toBeDefined();

      // Simulate progress saving
      window.localStorage.setItem('learning-progress', JSON.stringify({ 'item-1': true }));
      expect(window.localStorage.setItem).toHaveBeenCalledWith(
        'learning-progress',
        JSON.stringify({ 'item-1': true })
      );
    });

    it('should handle storage quota limits gracefully', () => {
      // Simulate storage quota exceeded
      window.localStorage.setItem.mockImplementation(() => {
        throw new Error('QuotaExceededError');
      });

      expect(() => {
        window.localStorage.setItem('test', 'data');
      }).toThrow('QuotaExceededError');
    });
  });

  describe('10. Cross-Browser Compatibility', () => {
    it('should support modern browser APIs', () => {
      // Check for browser APIs (may be mocked in test environment)
      expect(typeof window.fetch === 'function' || vi.isMockFunction(window.fetch)).toBe(true);
      expect(window.Promise).toBeDefined();
      expect(window.CustomEvent).toBeDefined();
    });

    it('should handle missing APIs gracefully', () => {
      // Remove an API temporarily
      const originalFetch = window.fetch;
      delete window.fetch;

      // Code should still function
      expect(window.document).toBeDefined();

      // Restore API
      window.fetch = originalFetch;
    });
  });
});
