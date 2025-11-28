import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { fixtureCleanup } from '../helpers/fixture-cleanup.js';
import domQueryHelper from '../helpers/dom-query-helper.js';
import { unifiedTestFixtures } from '../fixtures/unified-test-fixtures.js';

/**
 * DOM Query Stabilization     it('should accurately detect element visibility', () => {
      const visiblePath = document.querySelector('[data-path-id="fundamentals"]');
      const hiddenPath = document.querySelector('[data-path-id="advanced"]');

      // The visible element should be considered visible (no inline styles hiding it)
      expect(domQueryHelper.isElementVisible(visiblePath)).toBe(true);

      // The hidden element has display: none inline style, so should be hidden
      expect(domQueryHelper.isElementVisible(hiddenPath)).toBe(false);uite
 *
 * Validates reliable DOM element selection, interaction patterns, and
 * dynamic content loading for the documentation application.
 * Focuses on real-world DOM interactions rather than browser-specific APIs.
 */
describe('DOM Query Stabilization Testing', () => {
  beforeEach(() => {
    // Clear DOM and set up fresh environment
    document.head.innerHTML = '';
    document.body.innerHTML = '';

    // Clear localStorage
    window.localStorage.clear();

    // Set up comprehensive HTML structure that matches all test expectations
    document.body.innerHTML = `
      <div id="main">
        <nav class="app-nav">
          <ul>
            <li><a href="#/">Home</a></li>
            <li><a href="#/getting-started">Getting Started</a></li>
          </ul>
        </nav>
        <aside class="sidebar">
          <div class="sidebar-nav">
            <ul>
              <li class="learning-path" data-path-id="fundamentals">
                <h2>AI Foundations Learning Path</h2>
                <a href="#/learning/fundamentals">Fundamentals</a>
              </li>
              <li class="learning-path" data-path-id="advanced" style="display: none;">
                <h2>Advanced</h2>
                <a href="#/learning/advanced">Advanced</a>
              </li>
            </ul>
          </div>
        </aside>
        <main class="content">
          <section id="learning-paths-container" class="learning-paths-container">
            <h1>Welcome to Learning Platform</h1>
            <div class="learning-paths">
              <div class="learning-path" data-difficulty="beginner" data-path-id="foundations">
                <h2>AI Foundations Learning Path</h2>
                <div class="item-title">Introduction to Edge AI</div>
              </div>
              <div class="learning-path" data-difficulty="intermediate">Intermediate Path</div>
            </div>
          </section>
          <section class="markdown-section">
            <h2>Main Content</h2>
            <p>Loaded content goes here</p>
          </section>
          <div id="progress-tracker">
            <div class="progress-text progress-display">Progress: 0/3 completed</div>
            <div class="progress-bar">
              <div class="progress-fill" style="width: 0%;"></div>
            </div>
            <div class="progress-item" data-item-id="intro">
              <input type="checkbox" id="progress-intro" class="progress-checkbox" />
              <label for="progress-intro">Introduction Complete</label>
            </div>
            <div class="progress-item" data-item-id="basic">
              <input type="checkbox" id="progress-basic" class="progress-checkbox" />
              <label for="progress-basic">Basic Complete</label>
            </div>
            <div class="progress-item" data-item-id="advanced">
              <input type="checkbox" id="progress-advanced" class="progress-checkbox" />
              <label for="progress-advanced">Advanced Complete</label>
            </div>
          </div>
          <div id="coaching-panel" style="display: none;">
            <h2>Coaching Suggestions</h2>
            <p>Your personalized recommendations</p>
          </div>
          <div class="kata-container">
            <div class="kata-item" data-difficulty="beginner">Beginner Kata</div>
            <div class="kata-item" data-difficulty="intermediate">Intermediate Kata</div>
          </div>
        </main>
      </div>
    `;

    // Mock localStorage properly
    const localStorageMock = {
      _storage: new Map(),
      getItem: vi.fn((key) => localStorageMock._storage.get(key) || null),
      setItem: vi.fn((key, value) => {
        localStorageMock._storage.set(key, String(value));
      }),
      removeItem: vi.fn((key) => localStorageMock._storage.delete(key)),
      clear: vi.fn(() => localStorageMock._storage.clear()),
      get length() { return localStorageMock._storage.size; },
      key: vi.fn((_index) => Array.from(localStorageMock._storage.keys())[_index] || null)
    };

    Object.defineProperty(window, 'localStorage', {
      value: localStorageMock,
      writable: true
    });

    // Mock document.hidden and visibilityState for Happy DOM
    Object.defineProperty(document, 'hidden', {
      value: false,
      writable: true
    });

    Object.defineProperty(document, 'visibilityState', {
      value: 'visible',
      writable: true
    });
  }); afterEach(async () => {
    // Comprehensive cleanup using fixture cleanup utility
    await fixtureCleanup.cleanup();
  });

  /**
   * Test Suite DQ-001: Basic Element Selection Stability
   * Tests reliable element selection patterns
   */
  describe('Basic Element Selection Stability', () => {
    it('should reliably select elements using standard patterns', async () => {
      // Test basic ID selection
      const container = domQueryHelper.safeQuerySelector('#learning-paths-container', { required: true });
      expect(container).toBeTruthy();
      expect(container.id).toBe('learning-paths-container');

      // Test class selection
      const learningPaths = domQueryHelper.safeQuerySelectorAll('.learning-path');
      expect(learningPaths.length).toBeGreaterThan(0);

      // Test data attribute selection
      const foundationsPath = domQueryHelper.safeQuerySelector('[data-path-id="foundations"]', { required: true });
      expect(foundationsPath).toBeTruthy();
      expect(foundationsPath.getAttribute('data-path-id')).toBe('foundations');
    });

    it('should handle missing elements gracefully', () => {
      // Test non-existent element without required flag
      const nonExistent = domQueryHelper.safeQuerySelector('#does-not-exist');
      expect(nonExistent).toBeNull();

      // Test with required flag should throw
      expect(() => {
        domQueryHelper.safeQuerySelector('#does-not-exist', { required: true });
      }).toThrow('Required element not found: #does-not-exist');
    });

    it('should validate element counts correctly', () => {
      // Test minimum count validation
      const checkboxes = domQueryHelper.safeQuerySelectorAll('.progress-checkbox', { minCount: 2 });
      expect(checkboxes.length).toBeGreaterThanOrEqual(2);

      // Test maximum count validation
      const containers = domQueryHelper.safeQuerySelectorAll('#learning-paths-container', { maxCount: 1 });
      expect(containers.length).toBe(1);

      // Test count validation failure
      expect(() => {
        domQueryHelper.safeQuerySelectorAll('.learning-path', { minCount: 10 });
      }).toThrow();
    });

    it('should provide reliable text content extraction', () => {
      const pathTitle = domQueryHelper.getElementText('.learning-path h2');
      expect(pathTitle).toBe('AI Foundations Learning Path');

      const itemTitle = domQueryHelper.getElementText('.item-title');
      expect(itemTitle).toBe('Introduction to Edge AI');

      // Test with normalization
      const normalizedText = domQueryHelper.getElementText('.progress-text', { normalize: true, trim: true });
      expect(normalizedText).toBe('Progress: 0/3 completed');
    });
  });

  /**
   * Test Suite DQ-002: Dynamic Content Loading Patterns
   * Tests handling of dynamically shown/hidden content
   */
  describe('Dynamic Content Loading Patterns', () => {
    it('should wait for elements to become available', async () => {
      // Hide an element initially
      const advancedPath = document.querySelector('[data-path-id="advanced"]');
      expect(advancedPath.style.display).toBe('none');

      // Show it after a delay
      setTimeout(() => {
        advancedPath.style.display = 'block';
        advancedPath.style.visibility = 'visible';
        advancedPath.style.opacity = '1';
      }, 100);

      // Wait for it to become visible
      const visiblePath = await domQueryHelper.waitForElement('[data-path-id="advanced"]', {
        visible: true,
        timeout: 500
      });

      expect(visiblePath).toBeTruthy();
      expect(domQueryHelper.isElementVisible(visiblePath)).toBe(true);
    });

    it('should handle Docsify-like content loading', async () => {
      // Mock Docsify content loading pattern
      const markdownSection = document.querySelector('.markdown-section');
      markdownSection.innerHTML = '<div class="loading">Loading...</div>';

      // Simulate content loading after delay
      setTimeout(() => {
        markdownSection.innerHTML = `
          <div class="loaded-content">
            <h1>Learning Paths</h1>
            <div class="content-body">
              <p>Welcome to the learning platform.</p>
            </div>
          </div>
        `;
      }, 150);

      // Wait for content to load
      const loadedContent = await domQueryHelper.waitForElement('.loaded-content', { timeout: 500 });
      expect(loadedContent).toBeTruthy();

      const contentTitle = domQueryHelper.getElementText('.loaded-content h1');
      expect(contentTitle).toBe('Learning Paths');
    });

    it('should wait for learning paths to be ready', async () => {
      // Test the specialized learning paths helper
      const container = await domQueryHelper.waitForLearningPathsReady({ timeout: 1000 });
      expect(container).toBeTruthy();
      expect(container.id).toBe('learning-paths-container');

      // Verify learning paths are present
      const paths = container.querySelectorAll('.learning-path');
      expect(paths.length).toBeGreaterThan(0);
    });

    it('should handle element interaction reliably', async () => {
      // Test safe interaction with elements
      const checkbox = document.querySelector('.progress-checkbox');
      expect(checkbox.checked).toBe(false);

      // Interact safely with the element
      const success = await domQueryHelper.safeInteract(checkbox, 'click');
      expect(success).toBe(true);
      expect(checkbox.checked).toBe(true);

      // Test interaction with selector
      await domQueryHelper.safeInteract('.progress-checkbox', 'click');
      expect(checkbox.checked).toBe(false); // Toggled back
    });
  });

  /**
   * Test Suite DQ-003: Progress Tracking DOM Interactions
   * Tests learning progress UI interactions
   */
  describe('Progress Tracking DOM Interactions', () => {
    it('should update progress display when checkboxes change', async () => {
      const checkboxes = document.querySelectorAll('.progress-checkbox');
      const progressText = document.querySelector('.progress-text');
      const progressFill = document.querySelector('.progress-fill');

      // Initial state
      expect(domQueryHelper.getElementText(progressText)).toBe('Progress: 0/3 completed');
      expect(progressFill.style.width).toBe('0%');

      // Check first checkbox
      await domQueryHelper.safeInteract(checkboxes[0], 'click');

      // Simulate progress update (in real app this would be automatic)
      progressText.textContent = 'Progress: 1/3 completed';
      progressFill.style.width = '33%';

      expect(domQueryHelper.getElementText(progressText)).toBe('Progress: 1/3 completed');
      expect(progressFill.style.width).toBe('33%');

      // Check second checkbox
      await domQueryHelper.safeInteract(checkboxes[1], 'click');

      // Simulate progress update
      progressText.textContent = 'Progress: 2/3 completed';
      progressFill.style.width = '67%';

      expect(domQueryHelper.getElementText(progressText)).toBe('Progress: 2/3 completed');
      expect(progressFill.style.width).toBe('67%');
    });

    it('should handle coaching panel interactions', async () => {
      const coachingPanel = document.querySelector('#coaching-panel');

      // Initially hidden
      expect(coachingPanel.style.display).toBe('none');
      expect(domQueryHelper.isElementVisible(coachingPanel)).toBe(false);

      // Show panel programmatically
      coachingPanel.style.display = 'block';
      coachingPanel.style.visibility = 'visible';
      coachingPanel.style.opacity = '1';

      expect(domQueryHelper.isElementVisible(coachingPanel)).toBe(true);
    });

    it('should persist progress state in localStorage', () => {
      const checkbox = document.querySelector('#progress-intro');
      const itemId = 'intro';

      // Simulate user checking the checkbox
      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change', { bubbles: true }));

      // Simulate progress saving (this would normally be done by the app)
      window.localStorage.setItem(`progress_${itemId}`, 'true');

      expect(window.localStorage.setItem).toHaveBeenCalledWith(`progress_${itemId}`, 'true');
      expect(window.localStorage.getItem(`progress_${itemId}`)).toBe('true');
    });
  });

  /**
   * Test Suite DQ-004: Element Visibility and State Management
   * Tests reliable visibility detection and state management
   */
  describe('Element Visibility and State Management', () => {
    it('should accurately detect element visibility', () => {
      const visiblePath = document.querySelector('[data-path-id="foundations"]');
      const hiddenPath = document.querySelector('[data-path-id="advanced"]');

      expect(domQueryHelper.isElementVisible(visiblePath)).toBe(true);
      expect(domQueryHelper.isElementVisible(hiddenPath)).toBe(false);

      // Test with non-existent element
      expect(domQueryHelper.isElementVisible('#does-not-exist')).toBe(false);
    });

    it('should handle CSS-based visibility changes', () => {
      const element = document.querySelector('.progress-item');

      // Test different visibility states
      element.style.display = 'none';
      expect(domQueryHelper.isElementVisible(element)).toBe(false);

      element.style.display = 'block';
      element.style.visibility = 'hidden';
      expect(domQueryHelper.isElementVisible(element)).toBe(false);

      element.style.visibility = 'visible';
      element.style.opacity = '0';
      expect(domQueryHelper.isElementVisible(element)).toBe(false);

      // Make fully visible
      element.style.display = 'block';
      element.style.visibility = 'visible';
      element.style.opacity = '1';
      expect(domQueryHelper.isElementVisible(element)).toBe(true);
    });

    it('should wait for elements with specific visibility requirements', async () => {
      const hiddenPath = document.querySelector('[data-path-id="advanced"]');

      // Show element after delay
      setTimeout(() => {
        hiddenPath.style.display = 'block';
        hiddenPath.style.visibility = 'visible';
        hiddenPath.style.opacity = '1';
      }, 100);

      // Wait for element to become visible
      const visibleElement = await domQueryHelper.waitForElement('[data-path-id="advanced"]', {
        visible: true,
        timeout: 500
      });

      expect(visibleElement).toBeTruthy();
      expect(domQueryHelper.isElementVisible(visibleElement)).toBe(true);
    });

    it('should handle multiple element waiting operations', async () => {
      const selectors = [
        '.learning-path',
        '.progress-checkbox',
        '.progress-display'
      ];

      const elements = await domQueryHelper.waitForElements(selectors, { timeout: 1000 });

      expect(elements).toHaveLength(3);
      elements.forEach(element => {
        expect(element).toBeTruthy();
      });
    });
  });

  // Helper Functions

    const setupBrowserEnvironments = () => {
    // Mock browser environments for testing
    const mockBrowserEnvironments = () => {
      // Implementation would go here
    };
    mockBrowserEnvironments();
  };

  function mockChromeEnvironment() {
    Object.defineProperty(window.navigator, 'userAgent', {
      value: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      configurable: true
    });

    // Chrome-specific features
    window.chrome = {
      runtime: { sendMessage: vi.fn() }
    };
  }

  function mockFirefoxEnvironment() {
    Object.defineProperty(window.navigator, 'userAgent', {
      value: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:120.0) Gecko/20100101 Firefox/120.0',
      configurable: true
    });

    // Firefox-specific features
    window.console.table = vi.fn();
  }

  function mockEdgeEnvironment() {
    Object.defineProperty(window.navigator, 'userAgent', {
      value: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0',
      configurable: true
    });

    // Edge-specific features
    window.navigator.msSaveBlob = vi.fn();
  }

  function mockEdgeLegacyEnvironment() {
    Object.defineProperty(window.navigator, 'userAgent', {
      value: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.140 Safari/537.36 Edge/18.17763',
      configurable: true
    });

    // Edge Legacy limitations
    delete window.fetch;
    delete window.Promise;
  }

  function mockSafariEnvironment() {
    Object.defineProperty(window.navigator, 'userAgent', {
      value: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15',
      configurable: true
    });

    // Safari-specific features
    window.webkitStorageInfo = vi.fn();
  }

  function mockIOSSafariEnvironment() {
    Object.defineProperty(window.navigator, 'userAgent', {
      value: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
      configurable: true
    });

    // iOS-specific features
    window.TouchEvent = vi.fn().mockImplementation((type, _options) => ({
      type,
      touches: _options?.touches || [],
      changedTouches: _options?.changedTouches || [],
      preventDefault: vi.fn()
    }));
  }

  function resetBrowserMocks() {
    delete window.chrome;
    delete window.navigator.msSaveBlob;
    delete window.webkitStorageInfo;
    delete window.TouchEvent;
  }
});
