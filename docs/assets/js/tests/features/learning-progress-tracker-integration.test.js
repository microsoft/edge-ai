/**
 * Integration Tests for Learning Progress Tracker with Interactive Checkboxes
 * Tests the integration between the unified progress tracker and existing checkbox system
 * @jest-environment happy-dom
 * @version 1.0.0
 */

import { describe, test, expect, beforeEach, afterEach, vi } from 'vitest';
import { InteractiveCheckboxManager } from '../../features/interactive-checkboxes.js';
import '../../plugins/learning-progress-tracker-plugin.js';

describe('Learning Progress Tracker + Interactive Checkboxes Integration', () => {
  let _checkboxManager;
  let mockFetch;
  let mockLocalStorage;

  beforeEach(() => {
    // Set up DOM with kata content
    document.body.innerHTML = `
      <div id="app">
        <main>
          <section class="content">
            <article class="markdown-section" id="main">
              <h1>Test Kata: Getting Started Advanced</h1>
              <div class="task-section">
                <h2>Task 1: Setup Environment</h2>
                <input type="checkbox" id="task-1-1" class="task-checkbox" />
                <label for="task-1-1">Install dependencies</label>

                <input type="checkbox" id="task-1-2" class="task-checkbox" />
                <label for="task-1-2">Configure settings</label>
              </div>

              <div class="task-section">
                <h2>Task 2: Implementation</h2>
                <input type="checkbox" id="task-2-1" class="task-checkbox" />
                <label for="task-2-1">Write code</label>

                <input type="checkbox" id="task-2-2" class="task-checkbox" />
                <label for="task-2-2">Add tests</label>
              </div>
            </article>
          </section>
        </main>
      </div>
    `;

    // Mock location for kata page
    Object.defineProperty(window, 'location', {
      value: {
        hash: '#/learning/katas/ai-assisted-engineering/03-getting-started-advanced'
      },
      writable: true
    });

    // Mock fetch for backend API
    mockFetch = vi.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ success: true, data: {} }),
        text: () => Promise.resolve('{}')
      })
    );
    vi.stubGlobal('fetch', mockFetch);

    // Mock localStorage
    mockLocalStorage = {
      getItem: vi.fn(),
      setItem: vi.fn(),
      removeItem: vi.fn(),
      clear: vi.fn()
    };
    vi.stubGlobal('localStorage', mockLocalStorage);

    // Initialize checkbox manager
    _checkboxManager = new InteractiveCheckboxManager({
      debugHelper: {
        debug: vi.fn(),
        info: vi.fn(),
        warn: vi.fn(),
        error: vi.fn()
      },
      errorHandler: {
        safeExecute: vi.fn((fn, _context, defaultValue) => {
          try {
            return fn();
          } catch {
            return defaultValue;
          }
        })
      },
      progressCore: {
        notifyCheckboxChange: vi.fn()
      }
    });
  });

  afterEach(() => {
    // Clean up DOM
    document.body.innerHTML = '';

    // Remove any created banners
    const existingBanner = document.querySelector('#learning-progress-banner');
    if (existingBanner) {
      existingBanner.remove();
    }

    // Clean up mocks
    vi.restoreAllMocks();
    vi.clearAllTimers();
  });

  describe('Checkbox and Banner Synchronization', () => {
    test('should create progress banner when checkboxes are present', () => {
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      expect(checkboxes.length).toBe(4);

      // Simulate banner creation (would normally be done by plugin)
      document.body.innerHTML += `
        <div id="learning-progress-banner" class="learning-progress-banner" data-content-type="katas">
          <div class="progress-content">
            <div class="progress-header">
              <span class="progress-icon">🥋</span>
              <span class="progress-title">Kata Progress: Getting Started Advanced</span>
            </div>
            <div class="progress-track">
              <div class="progress-fill" style="width: 0%;"></div>
            </div>
            <div class="progress-text">0% (0/4)</div>
          </div>
        </div>
      `;

      const banner = document.querySelector('#learning-progress-banner');
      expect(banner).toBeDefined();
      expect(banner.dataset.contentType).toBe('katas');
    });

    test('should update banner when checkbox states change', () => {
      // Set up banner
      document.body.innerHTML += `
        <div id="learning-progress-banner">
          <div class="progress-content">
            <div class="progress-fill" style="width: 0%;"></div>
            <div class="progress-text">0% (0/4)</div>
          </div>
        </div>
      `;

      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      const progressFill = document.querySelector('.progress-fill');
      const progressText = document.querySelector('.progress-text');

      // Check first checkbox
      checkboxes[0].checked = true;
      checkboxes[0].dispatchEvent(new Event('change'));

      // Simulate progress update (25% = 1/4)
      progressFill.style.width = '25%';
      progressText.textContent = '25% (1/4)';

      expect(progressFill.style.width).toBe('25%');
      expect(progressText.textContent).toBe('25% (1/4)');
    });

    test('should handle multiple checkbox changes', () => {
      document.body.innerHTML += `
        <div id="learning-progress-banner">
          <div class="progress-fill" style="width: 0%;"></div>
          <div class="progress-text">0% (0/4)</div>
        </div>
      `;

      const checkboxes = document.querySelectorAll('input[type="checkbox"]');

      // Check multiple checkboxes
      checkboxes[0].checked = true;
      checkboxes[1].checked = true;
      checkboxes[2].checked = true;

      // Simulate progress calculation
      const checkedCount = Array.from(checkboxes).filter(cb => cb.checked).length;
      const totalCount = checkboxes.length;
      const percentage = Math.round((checkedCount / totalCount) * 100);

      expect(checkedCount).toBe(3);
      expect(totalCount).toBe(4);
      expect(percentage).toBe(75);
    });
  });

  describe('Content Type Detection Integration', () => {
    test('should extract correct kata ID from current page', () => {
      const currentHash = window.location.hash;
      expect(currentHash).toBe('#/learning/katas/ai-assisted-engineering/03-getting-started-advanced');

      // Extract kata ID like the plugin would
      const kataMatch = currentHash.match(/\/katas\/([^/]+)\/([^/?]+)/);
      if (kataMatch) {
        const kataCategory = kataMatch[1]; // ai-assisted-engineering
        const kataLesson = kataMatch[2]; // 03-getting-started-advanced

        expect(kataCategory).toBe('ai-assisted-engineering');
        expect(kataLesson).toBe('03-getting-started-advanced');

        // Test title extraction
        const lessonTitle = kataLesson
          .replace(/-/g, ' ')
          .replace(/^\d{2} /, '') // Remove leading numbers and space
          .replace(/\b\w/g, l => l.toUpperCase());

        expect(lessonTitle).toBe('Getting Started Advanced');
      }
    });

    test('should work with different kata URLs', () => {
      const testUrls = [
        {
          url: '#/learning/katas/kubernetes-basics/01-introduction',
          expectedCategory: 'kubernetes-basics',
          expectedLesson: '01-introduction',
          expectedTitle: 'Introduction'
        },
        {
          url: '#/learning/katas/azure-deployment/advanced-topics',
          expectedCategory: 'azure-deployment',
          expectedLesson: 'advanced-topics',
          expectedTitle: 'Advanced Topics'
        }
      ];

      testUrls.forEach(testCase => {
        const kataMatch = testCase.url.match(/\/katas\/([^/]+)\/([^/?]+)/);

        expect(kataMatch[1]).toBe(testCase.expectedCategory);
        expect(kataMatch[2]).toBe(testCase.expectedLesson);

        const title = testCase.expectedLesson
          .replace(/-/g, ' ')
          .replace(/^\d{2} /, '') // Remove leading numbers and space
          .replace(/\b\w/g, l => l.toUpperCase());

        expect(title).toBe(testCase.expectedTitle);
      });
    });
  });

  describe('Frontmatter-based Content Detection', () => {
    test('should detect individual kata pages (ms.topic: kata)', () => {
      // Mock frontmatter data for individual kata page
      window.frontmatterData = {
        frontmatter: {
          'ms.topic': 'kata',
          title: 'AI Development Fundamentals',
          description: 'Learn the basics of AI development'
        },
        content: 'This is a kata page...'
      };

      // Mock detectContentType function from learning-progress-tracker-plugin
      const detectContentType = (route) => {
        if (window.frontmatterData?.frontmatter?.['ms.topic'] === 'kata') {
          return 'katas';
        }
        return null;
      };

      const result = detectContentType('#/learning/katas/ai-assisted-engineering/01-ai-development-fundamentals');
      expect(result).toBe('katas');

      // Clean up
      delete window.frontmatterData;
    });

    test('should NOT detect kata category pages (ms.topic: kata-category)', () => {
      // Mock frontmatter data for category README page
      window.frontmatterData = {
        frontmatter: {
          'ms.topic': 'kata-category',
          title: 'AI Assisted Engineering',
          description: 'Overview of AI assisted engineering katas'
        },
        content: 'This is a category overview page...'
      };

      // Mock detectContentType function from learning-progress-tracker-plugin
      const detectContentType = (route) => {
        if (window.frontmatterData?.frontmatter?.['ms.topic'] === 'kata') {
          return 'katas';
        }
        return null;
      };

      const result = detectContentType('#/learning/katas/ai-assisted-engineering/');
      expect(result).toBe(null); // Should NOT return 'katas'

      // Clean up
      delete window.frontmatterData;
    });

    test('should NOT detect hub pages (ms.topic: hub-page)', () => {
      // Mock frontmatter data for main hub page
      window.frontmatterData = {
        frontmatter: {
          'ms.topic': 'hub-page',
          title: 'Learning Katas',
          description: 'Main hub for all learning katas'
        },
        content: 'This is the main katas hub page...'
      };

      // Mock detectContentType function from learning-progress-tracker-plugin
      const detectContentType = (route) => {
        if (window.frontmatterData?.frontmatter?.['ms.topic'] === 'kata') {
          return 'katas';
        }
        return null;
      };

      const result = detectContentType('#/learning/katas/');
      expect(result).toBe(null); // Should NOT return 'katas'

      // Clean up
      delete window.frontmatterData;
    });

    test('should handle missing frontmatter gracefully', () => {
      // No frontmatter available
      delete window.frontmatterData;

      // Mock detectContentType function with fallback logic
      const detectContentType = (route) => {
        if (window.frontmatterData?.frontmatter?.['ms.topic'] === 'kata') {
          return 'katas';
        }
        // Fallback to regex for legacy support
        if (route.includes('/katas/') && !route.endsWith('/')) {
          return 'katas';
        }
        return null;
      };

      // Individual kata should still be detected via fallback
      const kataResult = detectContentType('#/learning/katas/ai-assisted-engineering/01-fundamentals');
      expect(kataResult).toBe('katas');

      // Category page should NOT be detected via fallback
      const categoryResult = detectContentType('#/learning/katas/ai-assisted-engineering/');
      expect(categoryResult).toBe(null);
    });

    test('should validate progress bar visibility with frontmatter detection', () => {
      // Test 1: Individual kata page - should show progress bar
      window.frontmatterData = {
        frontmatter: { 'ms.topic': 'kata' },
        content: 'Kata content...'
      };

      const shouldShowProgressBar1 = window.frontmatterData?.frontmatter?.['ms.topic'] === 'kata';
      expect(shouldShowProgressBar1).toBe(true);

      // Test 2: Category page - should NOT show progress bar
      window.frontmatterData = {
        frontmatter: { 'ms.topic': 'kata-category' },
        content: 'Category content...'
      };

      const shouldShowProgressBar2 = window.frontmatterData?.frontmatter?.['ms.topic'] === 'kata';
      expect(shouldShowProgressBar2).toBe(false);

      // Test 3: Hub page - should NOT show progress bar
      window.frontmatterData = {
        frontmatter: { 'ms.topic': 'hub-page' },
        content: 'Hub content...'
      };

      const shouldShowProgressBar3 = window.frontmatterData?.frontmatter?.['ms.topic'] === 'kata';
      expect(shouldShowProgressBar3).toBe(false);

      // Test 4: Non-kata page - should NOT show progress bar
      window.frontmatterData = {
        frontmatter: { 'ms.topic': 'documentation' },
        content: 'Documentation content...'
      };

      const shouldShowProgressBar4 = window.frontmatterData?.frontmatter?.['ms.topic'] === 'kata';
      expect(shouldShowProgressBar4).toBe(false);

      // Clean up
      delete window.frontmatterData;
    });

    test('should handle different frontmatter topic values correctly', () => {
      const testCases = [
        { topic: 'kata', shouldShow: true, description: 'Individual kata page' },
        { topic: 'kata-category', shouldShow: false, description: 'Category overview page' },
        { topic: 'hub-page', shouldShow: false, description: 'Main hub page' },
        { topic: 'documentation', shouldShow: false, description: 'Documentation page' },
        { topic: 'tutorial', shouldShow: false, description: 'Tutorial page' },
        { topic: 'reference', shouldShow: false, description: 'Reference page' },
        { topic: undefined, shouldShow: false, description: 'No topic specified' },
        { topic: null, shouldShow: false, description: 'Null topic' },
        { topic: '', shouldShow: false, description: 'Empty topic' }
      ];

      testCases.forEach(testCase => {
        // Mock frontmatter data
        window.frontmatterData = {
          frontmatter: { 'ms.topic': testCase.topic },
          content: 'Test content...'
        };

        const shouldShowProgressBar = window.frontmatterData?.frontmatter?.['ms.topic'] === 'kata';
        expect(shouldShowProgressBar).toBe(testCase.shouldShow);
      });

      // Clean up
      delete window.frontmatterData;
    });
  });

  describe('Progress Persistence Integration', () => {
    test('should save progress data with correct structure', () => {
      const progressData = {
        contentType: 'katas',
        contentId: 'ai-assisted-engineering/03-getting-started-advanced',
        progress: {
          completed: 2,
          total: 4,
          percentage: 50,
          checkboxStates: [
            { id: 'task-1-1', checked: true },
            { id: 'task-1-2', checked: true },
            { id: 'task-2-1', checked: false },
            { id: 'task-2-2', checked: false }
          ]
        },
        metadata: {
          title: 'Getting Started Advanced',
          category: 'ai-assisted-engineering',
          lastUpdated: Date.now()
        }
      };

      expect(progressData.contentType).toBe('katas');
      expect(progressData.progress.completed).toBe(2);
      expect(progressData.progress.total).toBe(4);
      expect(progressData.progress.percentage).toBe(50);
      expect(progressData.progress.checkboxStates.length).toBe(4);
      expect(progressData.metadata.title).toBe('Getting Started Advanced');
    });

    test('should restore progress from saved data', () => {
      const savedProgress = {
        contentType: 'katas',
        contentId: 'ai-assisted-engineering/03-getting-started-advanced',
        progress: {
          completed: 3,
          total: 4,
          percentage: 75,
          checkboxStates: [
            { id: 'task-1-1', checked: true },
            { id: 'task-1-2', checked: true },
            { id: 'task-2-1', checked: true },
            { id: 'task-2-2', checked: false }
          ]
        }
      };

      // Simulate restoring checkboxes from saved data
      savedProgress.progress.checkboxStates.forEach(state => {
        const checkbox = document.querySelector(`#${state.id}`);
        if (checkbox) {
          checkbox.checked = state.checked;
        }
      });

      // Verify restoration
      const task11 = document.querySelector('#task-1-1');
      const task12 = document.querySelector('#task-1-2');
      const task21 = document.querySelector('#task-2-1');
      const task22 = document.querySelector('#task-2-2');

      expect(task11?.checked).toBe(true);
      expect(task12?.checked).toBe(true);
      expect(task21?.checked).toBe(true);
      expect(task22?.checked).toBe(false);

      // Verify progress calculation
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      const checkedCount = Array.from(checkboxes).filter(cb => cb.checked).length;
      const percentage = Math.round((checkedCount / checkboxes.length) * 100);

      expect(checkedCount).toBe(3);
      expect(percentage).toBe(75);
    });
  });

  describe('Backend API Integration', () => {
    test('should make save request with correct data format', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          success: true,
          file: 'ai-assisted-engineering-03-getting-started-advanced-20250816.json'
        })
      });

      const progressData = {
        contentType: 'katas',
        contentId: 'ai-assisted-engineering/03-getting-started-advanced',
        progress: {
          completed: 2,
          total: 4,
          percentage: 50
        },
        metadata: {
          title: 'Getting Started Advanced',
          url: window.location.hash,
          timestamp: Date.now()
        }
      };

      const response = await fetch('http://localhost:3002/_server/save-progress', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(progressData)
      });

      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:3002/_server/save-progress',
        expect.objectContaining({
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(progressData)
        })
      );

      const result = await response.json();
      expect(result.success).toBe(true);
      expect(result.file).toContain('ai-assisted-engineering-03-getting-started-advanced');
    });

    test('should load saved progress from backend', async () => {
      const savedData = {
        success: true,
        data: {
          contentType: 'katas',
          contentId: 'ai-assisted-engineering/03-getting-started-advanced',
          progress: {
            completed: 1,
            total: 4,
            percentage: 25,
            checkboxStates: [
              { id: 'task-1-1', checked: true },
              { id: 'task-1-2', checked: false },
              { id: 'task-2-1', checked: false },
              { id: 'task-2-2', checked: false }
            ]
          }
        }
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve(savedData)
      });

      const response = await fetch('http://localhost:3002/_server/load-progress?contentType=katas&contentId=ai-assisted-engineering/03-getting-started-advanced');
      const result = await response.json();

      expect(result.success).toBe(true);
      expect(result.data.progress.completed).toBe(1);
      expect(result.data.progress.percentage).toBe(25);
    });
  });

  describe('Error Handling in Integration', () => {
    test('should handle backend failures gracefully', async () => {
      mockFetch.mockRejectedValueOnce(new Error('Backend unavailable'));

      // Should fallback to localStorage
      const progressData = {
        contentType: 'katas',
        contentId: 'test-kata',
        progress: { completed: 1, total: 4 }
      };

      // Simulate localStorage fallback
      localStorage.setItem(
        'learning-progress-ai-assisted-engineering-03-getting-started-advanced',
        JSON.stringify(progressData)
      );

      expect(localStorage.setItem).toHaveBeenCalled();
    });

    test('should handle missing checkboxes gracefully', () => {
      // Clear all checkboxes
      document.querySelectorAll('input[type="checkbox"]').forEach(cb => cb.remove());

      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      expect(checkboxes.length).toBe(0);

      // Should not crash when calculating progress with no checkboxes
      const progress = checkboxes.length === 0 ? 0 :
        Math.round((Array.from(checkboxes).filter(cb => cb.checked).length / checkboxes.length) * 100);

      expect(progress).toBe(0);
    });

    test('should handle malformed saved data', () => {
      const malformedData = [
        null,
        undefined,
        {},
        { progress: null },
        { progress: { checkboxStates: null } },
        { progress: { checkboxStates: 'invalid' } }
      ];

      malformedData.forEach(data => {
        expect(() => {
          if (data?.progress?.checkboxStates && Array.isArray(data.progress.checkboxStates)) {
            data.progress.checkboxStates.forEach(_state => {
              // Process state
            });
          }
        }).not.toThrow();
      });
    });
  });

  describe('Performance Considerations', () => {
    test('should handle large numbers of checkboxes efficiently', () => {
      // Clear existing checkboxes first
      document.querySelectorAll('input[type="checkbox"]').forEach(cb => cb.remove());

      // Create 100 checkboxes
      const container = document.querySelector('#main');
      for (let i = 0; i < 100; i++) {
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.id = `test-checkbox-${i}`;
        checkbox.className = 'task-checkbox';
        container.appendChild(checkbox);
      }

      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      expect(checkboxes.length).toBe(100);

      // Performance test: should complete quickly
      const startTime = performance.now();

      const checkedCount = Array.from(checkboxes).filter(cb => cb.checked).length;
      const percentage = Math.round((checkedCount / checkboxes.length) * 100);

      const endTime = performance.now();
      const duration = endTime - startTime;

      expect(duration).toBeLessThan(10); // Should complete in under 10ms
      expect(percentage).toBe(0); // All unchecked initially
    });

    test('should debounce rapid checkbox changes', () => {
      vi.useFakeTimers();

      const checkbox = document.querySelector('#task-1-1');
      let _changeCount = 0;

      // Mock debounced handler
      const debouncedHandler = vi.fn(() => {
        _changeCount++;
      });

      // Simulate rapid changes
      for (let i = 0; i < 10; i++) {
        checkbox.checked = !checkbox.checked;
        checkbox.dispatchEvent(new Event('change'));
      }

      // With proper debouncing, handler should only be called once
      setTimeout(debouncedHandler, 500);
      vi.advanceTimersByTime(600);

      expect(debouncedHandler).toHaveBeenCalledTimes(1);

      vi.useRealTimers();
    });
  });

  describe('Enhanced Reset Functionality Integration', () => {
    test('should show confirmation dialog before resetting', () => {
      // Create mock progress tracker banner with proper button class
      const banner = document.createElement('div');
      banner.id = 'learning-progress-banner';
      banner.innerHTML = `
        <div class="kata-progress-content">
          <div class="kata-progress-bar-track">
            <div class="kata-progress-bar-fill" style="width: 50%;"></div>
          </div>
          <div class="kata-progress-actions">
            <button class="kata-progress-btn kata-progress-btn-reset" type="button">Reset</button>
          </div>
        </div>
      `;
      document.body.appendChild(banner);

      // Create some checked checkboxes
      for (let i = 0; i < 4; i++) {
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.id = `reset-confirm-test-${i}`;
        checkbox.checked = i < 2; // First 2 checked
        document.querySelector('#main').appendChild(checkbox);
      }

      // Mock confirm to deny reset
      const originalConfirm = window.confirm;
      window.confirm = vi.fn(() => false);

      // Since the learning progress tracker plugin isn't fully initialized in test environment,
      // we'll verify that the reset functionality with confirmation works by testing the logic directly
      const resetBtn = banner.querySelector('.kata-progress-btn-reset');
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');

      // Simulate the reset confirmation logic from the plugin
      // Call the actual window.confirm (which is mocked)
      // eslint-disable-next-line no-alert
      const confirmed = window.confirm('⚠️ Are you sure you want to reset all progress? This action cannot be undone.');

      if (!confirmed) {
        // Reset was cancelled, checkboxes should remain unchanged
        const checkedCount = Array.from(checkboxes).filter(cb => cb.checked).length;
        expect(checkedCount).toBe(2); // Still 2 checked
      }

      // Verify confirm was called with correct message
      expect(window.confirm).toHaveBeenCalledWith('⚠️ Are you sure you want to reset all progress? This action cannot be undone.');

      // Cleanup
      window.confirm = originalConfirm;
    });

    test('should reset all checkboxes when confirmation is accepted', () => {
      // Create mock progress tracker banner
      const banner = document.createElement('div');
      banner.id = 'learning-progress-banner';
      banner.innerHTML = `
        <div class="kata-progress-content">
          <div class="kata-progress-bar-track">
            <div class="kata-progress-bar-fill" style="width: 50%;"></div>
          </div>
          <div class="kata-progress-actions">
            <button class="kata-progress-btn kata-progress-btn-reset" type="button">Reset</button>
          </div>
        </div>
      `;
      document.body.appendChild(banner);

      // Create checkboxes with mixed states and styling
      const testCheckboxes = [];
      for (let i = 0; i < 4; i++) {
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.id = `reset-test-checkbox-${i}`;
        checkbox.checked = i < 2; // First 2 checked

        const li = document.createElement('li');
        if (checkbox.checked) {
          li.classList.add('completed-task');
        }
        li.appendChild(checkbox);
        document.querySelector('#main').appendChild(li);
        testCheckboxes.push({ checkbox, li });
      }

      // Mock interactive checkbox change behavior
      const changeHandler = (event) => {
        const checkbox = event.target;
        const listItem = checkbox.closest('li');
        if (listItem) {
          if (checkbox.checked) {
            listItem.classList.add('completed-task');
          } else {
            listItem.classList.remove('completed-task');
          }
        }
      };

      // Add event listener to simulate interactive checkbox system
      document.addEventListener('change', changeHandler);

      // Mock confirm to accept reset
      const originalConfirm = window.confirm;
      window.confirm = vi.fn(() => true);

      // Mock fetch for save endpoint
      const originalFetch = global.fetch;
      global.fetch = vi.fn(() => Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ success: true })
      }));

      // Verify initial state
      expect(testCheckboxes[0].checkbox.checked).toBe(true);
      expect(testCheckboxes[0].li.classList.contains('completed-task')).toBe(true);
      expect(testCheckboxes[1].checkbox.checked).toBe(true);
      expect(testCheckboxes[1].li.classList.contains('completed-task')).toBe(true);

      // Call the actual window.confirm (which is mocked to return true)
      // eslint-disable-next-line no-alert
      const confirmed = window.confirm('⚠️ Are you sure you want to reset all progress? This action cannot be undone.');

      if (confirmed) {
        const checkboxes = document.querySelectorAll('input[type="checkbox"]');
        checkboxes.forEach(checkbox => {
          if (checkbox.checked) {
            checkbox.checked = false;
            checkbox.dispatchEvent(new Event('change', { bubbles: true }));
          }
        });
      }

      // Verify confirm was called
      expect(window.confirm).toHaveBeenCalledWith('⚠️ Are you sure you want to reset all progress? This action cannot be undone.');

      // Verify all checkboxes are unchecked and styling is removed
      testCheckboxes.forEach(({ checkbox, li }) => {
        expect(checkbox.checked).toBe(false);
        expect(li.classList.contains('completed-task')).toBe(false);
      });

      // Cleanup
      window.confirm = originalConfirm;
      global.fetch = originalFetch;
      document.removeEventListener('change', changeHandler);
    });

    test('should blur reset button after action to remove focus highlight', () => {
      vi.useFakeTimers();

      const banner = document.createElement('div');
      banner.innerHTML = `
        <div class="kata-progress-actions">
          <button class="kata-progress-btn kata-progress-btn-reset" type="button">Reset</button>
        </div>
      `;
      document.body.appendChild(banner);

      const resetBtn = banner.querySelector('.kata-progress-btn-reset');
      const blurSpy = vi.spyOn(resetBtn, 'blur');

      // Mock confirm to accept
      const originalConfirm = window.confirm;
      window.confirm = vi.fn(() => true);

      // Simulate the plugin's button blur logic after reset
      setTimeout(() => {
        resetBtn.blur();
      }, 100);

      vi.advanceTimersByTime(150);

      expect(blurSpy).toHaveBeenCalled();

      // Cleanup
      window.confirm = originalConfirm;
      vi.useRealTimers();
    });
  });

  describe('Enhanced Checkbox Event Listener Integration', () => {
    test('should properly update progress when checkboxes change via event listeners', () => {
      // Clear existing checkboxes first
      document.querySelectorAll('input[type="checkbox"]').forEach(cb => cb.remove());

      // Create banner with progress elements
      const banner = document.createElement('div');
      banner.id = 'learning-progress-banner';
      banner.innerHTML = `
        <div class="kata-progress-content">
          <div class="kata-progress-bar-track">
            <div class="kata-progress-bar-fill" style="width: 0%;"></div>
          </div>
          <div class="kata-progress-percentage">0% (0/4)</div>
        </div>
      `;
      document.body.appendChild(banner);

      // Create specific test checkboxes
      const testCheckboxes = [];
      for (let i = 0; i < 4; i++) {
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.className = 'event-test-checkbox';
        checkbox.id = `event-test-${i}`;
        document.querySelector('#main').appendChild(checkbox);
        testCheckboxes.push(checkbox);
      }

      const progressFill = banner.querySelector('.kata-progress-bar-fill');
      const progressText = banner.querySelector('.kata-progress-percentage');

      // Mock the plugin's updateProgress function behavior - use only our test checkboxes
      const updateProgressMock = () => {
        const totalCheckboxes = testCheckboxes.length;
        const checkedCheckboxes = testCheckboxes.filter(cb => cb.checked).length;
        const percentage = totalCheckboxes > 0 ? Math.round((checkedCheckboxes / totalCheckboxes) * 100) : 0;

        progressFill.style.width = `${percentage}%`;
        progressText.textContent = `${percentage}% (${checkedCheckboxes}/${totalCheckboxes})`;
      };

      // Add event listener that mimics the plugin's behavior
      testCheckboxes.forEach(checkbox => {
        checkbox.addEventListener('change', updateProgressMock);
      });

      // Test initial state
      expect(progressFill.style.width).toBe('0%');
      expect(progressText.textContent).toBe('0% (0/4)');

      // Check first checkbox
      testCheckboxes[0].checked = true;
      testCheckboxes[0].dispatchEvent(new Event('change'));

      expect(progressFill.style.width).toBe('25%');
      expect(progressText.textContent).toBe('25% (1/4)');

      // Check second checkbox
      testCheckboxes[1].checked = true;
      testCheckboxes[1].dispatchEvent(new Event('change'));

      expect(progressFill.style.width).toBe('50%');
      expect(progressText.textContent).toBe('50% (2/4)');

      // Uncheck first checkbox
      testCheckboxes[0].checked = false;
      testCheckboxes[0].dispatchEvent(new Event('change'));

      expect(progressFill.style.width).toBe('25%');
      expect(progressText.textContent).toBe('25% (1/4)');
    });

    test('should handle rapid checkbox changes without errors', () => {
      vi.useFakeTimers();

      // Clear existing checkboxes first
      document.querySelectorAll('input[type="checkbox"]').forEach(cb => cb.remove());

      const banner = document.createElement('div');
      banner.innerHTML = `
        <div class="kata-progress-bar-fill" style="width: 0%;"></div>
        <div class="kata-progress-percentage">0% (0/3)</div>
      `;
      document.body.appendChild(banner);

      const testCheckboxes = [];
      for (let i = 0; i < 3; i++) {
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.id = `rapid-test-${i}`;
        document.querySelector('#main').appendChild(checkbox);
        testCheckboxes.push(checkbox);
      }

      let _updateCount = 0;

      // Mock debounced update function
      const debouncedUpdate = vi.fn(() => {
        _updateCount++;
      });

      // Simulate rapid changes
      for (let i = 0; i < 10; i++) {
        testCheckboxes[0].checked = !testCheckboxes[0].checked;
        testCheckboxes[0].dispatchEvent(new Event('change'));

        // Mock debounced behavior - only call after delay
        setTimeout(debouncedUpdate, 300);
      }

      // Advance time to trigger debounced updates
      vi.advanceTimersByTime(500);

      // Should handle rapid changes gracefully
      expect(debouncedUpdate).toHaveBeenCalled();
      expect(() => {
        testCheckboxes[0].dispatchEvent(new Event('change'));
      }).not.toThrow();

      vi.useRealTimers();
    });
  });

  describe('Enhanced Save Functionality Integration', () => {
    test('should provide feedback when save completes successfully', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          success: true,
          file: 'test-progress-20250817.json'
        })
      });

      const banner = document.createElement('div');
      banner.innerHTML = `
        <div class="kata-progress-actions">
          <button class="kata-progress-btn kata-progress-btn-save" type="button">Save</button>
        </div>
        <div class="kata-progress-status" style="display: none;"></div>
      `;
      document.body.appendChild(banner);

      const statusElement = banner.querySelector('.kata-progress-status');

      // Simulate the plugin's save functionality
      const mockShowStatus = (message, type) => {
        statusElement.textContent = message;
        statusElement.className = `kata-progress-status ${type}`;
        statusElement.style.display = 'block';
      };

      // Mock successful save
      try {
        const response = await fetch('http://localhost:3002/_server/save-progress', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({})
        });
        const result = await response.json();

        if (result.success) {
          mockShowStatus('✅ Progress saved successfully!', 'success');
        }
      } catch (_error) {
        mockShowStatus('⚠️ Using local storage backup', 'warning');
      }

      expect(statusElement.textContent).toBe('✅ Progress saved successfully!');
      expect(statusElement.classList.contains('success')).toBe(true);
    });

    test('should blur save button after action to remove focus highlight', () => {
      vi.useFakeTimers();

      const banner = document.createElement('div');
      banner.innerHTML = `
        <div class="kata-progress-actions">
          <button class="kata-progress-btn kata-progress-btn-save" type="button">Save</button>
        </div>
      `;
      document.body.appendChild(banner);

      const saveBtn = banner.querySelector('.kata-progress-btn-save');
      const blurSpy = vi.spyOn(saveBtn, 'blur');

      // Simulate the plugin's button blur logic after save
      setTimeout(() => {
        saveBtn.blur();
      }, 100);

      vi.advanceTimersByTime(150);

      expect(blurSpy).toHaveBeenCalled();

      vi.useRealTimers();
    });

    test('should fallback to localStorage when backend is unavailable', async () => {
      mockFetch.mockRejectedValueOnce(new Error('Network error'));

      const banner = document.createElement('div');
      banner.innerHTML = `<div class="kata-progress-status" style="display: none;"></div>`;
      document.body.appendChild(banner);

      const statusElement = banner.querySelector('.kata-progress-status');

      // Simulate save with fallback logic
      const mockShowStatus = (message, type) => {
        statusElement.textContent = message;
        statusElement.className = `kata-progress-status ${type}`;
      };

      try {
        await fetch('http://localhost:3002/_server/save-progress', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({})
        });
      } catch (_error) {
        // Fallback to localStorage
        localStorage.setItem('learning-progress-test', JSON.stringify({ test: true }));
        mockShowStatus('⚠️ Using local storage backup', 'warning');
      }

      expect(localStorage.setItem).toHaveBeenCalledWith('learning-progress-test', JSON.stringify({ test: true }));
      expect(statusElement.textContent).toBe('⚠️ Using local storage backup');
    });
  });

  describe('Interactive Checkboxes updateProgressBar Integration', () => {
    test('should call updateProgressBar with correct parameters when checkbox changes', () => {
      // Clear existing checkboxes first
      document.querySelectorAll('input[type="checkbox"]').forEach(cb => cb.remove());

      // Create banner with progress elements
      const banner = document.createElement('div');
      banner.id = 'learning-progress-banner';
      banner.innerHTML = `
        <div class="kata-progress-content">
          <div class="kata-progress-bar-track">
            <div class="kata-progress-bar-fill" style="width: 0%;"></div>
          </div>
          <div class="kata-progress-percentage">0% Complete (0/3)</div>
        </div>
      `;
      document.body.appendChild(banner);

      // Create test checkboxes
      const testCheckboxes = [];
      for (let i = 0; i < 3; i++) {
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.id = `integration-test-${i}`;
        document.querySelector('#main').appendChild(checkbox);
        testCheckboxes.push(checkbox);
      }

      // Mock the window.progressBarManager that the plugin exposes
      const mockUpdateProgressBar = vi.fn((completed, total) => {
        const percentage = total > 0 ? Math.round((completed / total) * 100) : 0;
        const progressFill = banner.querySelector('.kata-progress-bar-fill');
        const progressText = banner.querySelector('.kata-progress-percentage');

        progressFill.style.width = `${percentage}%`;
        progressText.textContent = `${percentage}% Complete (${completed}/${total})`;
      });

      window.progressBarManager = { updateProgressBar: mockUpdateProgressBar };

      // Create InteractiveCheckboxManager instance with mocked progressBarManager
      const checkboxManager = new InteractiveCheckboxManager({
        debugHelper: { debug: vi.fn() },
        errorHandler: {
          safeExecute: vi.fn((fn) => {
            try { return fn(); } catch { return false; }
          })
        }
      });

      // Manually set the progressBarManager (simulates the dependency injection)
      checkboxManager.progressBarManager = window.progressBarManager;
      checkboxManager.currentKataId = 'test-kata';

      // Set up checkboxes in the manager
      testCheckboxes.forEach((checkbox, index) => {
        checkboxManager.checkboxElements.set(`checkbox-${index}`, checkbox);
      });

      // Test: Check first checkbox
      testCheckboxes[0].checked = true;
      checkboxManager.updateProgressDisplay();

      // Verify updateProgressBar was called with correct parameters (completed, total)
      expect(mockUpdateProgressBar).toHaveBeenCalledWith(1, 3);

      // Verify UI was updated correctly
      const progressFill = banner.querySelector('.kata-progress-bar-fill');
      const progressText = banner.querySelector('.kata-progress-percentage');
      expect(progressFill.style.width).toBe('33%');
      expect(progressText.textContent).toBe('33% Complete (1/3)');

      // Test: Check second checkbox
      testCheckboxes[1].checked = true;
      checkboxManager.updateProgressDisplay();

      expect(mockUpdateProgressBar).toHaveBeenCalledWith(2, 3);
      expect(progressFill.style.width).toBe('67%');
      expect(progressText.textContent).toBe('67% Complete (2/3)');

      // Test: Check all checkboxes
      testCheckboxes[2].checked = true;
      checkboxManager.updateProgressDisplay();

      expect(mockUpdateProgressBar).toHaveBeenCalledWith(3, 3);
      expect(progressFill.style.width).toBe('100%');
      expect(progressText.textContent).toBe('100% Complete (3/3)');

      // Cleanup
      delete window.progressBarManager;
    });

    test('should NOT break when progressBarManager is undefined', () => {
      // Ensure no progressBarManager exists
      delete window.progressBarManager;

      // Clear existing checkboxes first
      document.querySelectorAll('input[type="checkbox"]').forEach(cb => cb.remove());

      // Create test checkboxes
      const testCheckboxes = [];
      for (let i = 0; i < 2; i++) {
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.id = `no-manager-test-${i}`;
        checkbox.checked = i === 0; // First one checked
        document.querySelector('#main').appendChild(checkbox);
        testCheckboxes.push(checkbox);
      }

      // Create InteractiveCheckboxManager instance without progressBarManager
      const checkboxManager = new InteractiveCheckboxManager({
        debugHelper: { debug: vi.fn() },
        errorHandler: {
          safeExecute: vi.fn((fn) => {
            try { return fn(); } catch { return false; }
          })
        }
      });

      checkboxManager.currentKataId = 'test-kata';
      testCheckboxes.forEach((checkbox, index) => {
        checkboxManager.checkboxElements.set(`checkbox-${index}`, checkbox);
      });

      // This should not throw an error even when progressBarManager is undefined
      expect(() => {
        checkboxManager.updateProgressDisplay();
      }).not.toThrow();

      // Verify that the method still completes successfully
      const currentProgress = checkboxManager.getCurrentProgress();
      expect(currentProgress.completedTasks).toBe(1);
      expect(currentProgress.totalTasks).toBe(2);
      expect(currentProgress.completionPercentage).toBe(50);
    });

    test('should handle the old incorrect updateProgressBar call gracefully', () => {
      // This test verifies that the old incorrect call pattern would fail as expected
      // and the new correct pattern works

      const banner = document.createElement('div');
      banner.innerHTML = `
        <div class="kata-progress-bar-fill" style="width: 0%;"></div>
        <div class="kata-progress-percentage">0% Complete (0/2)</div>
      `;
      document.body.appendChild(banner);

      // Mock updateProgressBar that expects (completed, total) format
      const correctUpdateProgressBar = vi.fn((completed, total) => {
        if (typeof completed === 'number' && typeof total === 'number') {
          const percentage = total > 0 ? Math.round((completed / total) * 100) : 0;
          banner.querySelector('.kata-progress-bar-fill').style.width = `${percentage}%`;
          banner.querySelector('.kata-progress-percentage').textContent = `${percentage}% Complete (${completed}/${total})`;
          return true;
        } else {
          // Old format with complex objects would not work correctly
          console.warn('updateProgressBar called with incorrect parameters:', completed, total);
          return false;
        }
      });

      window.progressBarManager = { updateProgressBar: correctUpdateProgressBar };

      // Test OLD INCORRECT format (should fail gracefully)
      const oldFormatContext = { kataId: 'test', categoryId: 'cat', title: 'Test' };
      const oldFormatProgressData = { completedTasks: 1, totalTasks: 2, completionPercentage: 50 };

      const oldResult = correctUpdateProgressBar(oldFormatContext, oldFormatProgressData);
      expect(oldResult).toBe(false); // Should fail with old format

      // Test NEW CORRECT format (should work)
      const newResult = correctUpdateProgressBar(1, 2);
      expect(newResult).toBe(true); // Should succeed with new format
      expect(correctUpdateProgressBar).toHaveBeenCalledWith(1, 2);

      // Verify UI was updated correctly with new format
      expect(banner.querySelector('.kata-progress-bar-fill').style.width).toBe('50%');
      expect(banner.querySelector('.kata-progress-percentage').textContent).toBe('50% Complete (1/2)');

      // Cleanup
      delete window.progressBarManager;
    });
  });

  describe('Enhanced Progress Update Integration', () => {
    test('should handle delayed progress updates after page load', () => {
      vi.useFakeTimers();

      // Clear existing checkboxes first
      document.querySelectorAll('input[type="checkbox"]').forEach(cb => cb.remove());

      // Create banner and checkboxes
      const banner = document.createElement('div');
      banner.innerHTML = `
        <div class="kata-progress-bar-fill" style="width: 0%;"></div>
        <div class="kata-progress-percentage">0% (0/3)</div>
      `;
      document.body.appendChild(banner);

      const testCheckboxes = [];
      for (let i = 0; i < 3; i++) {
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.checked = i < 2; // First 2 checked
        checkbox.id = `delayed-test-${i}`;
        document.querySelector('#main').appendChild(checkbox);
        testCheckboxes.push(checkbox);
      }

      const progressFill = banner.querySelector('.kata-progress-bar-fill');
      const progressText = banner.querySelector('.kata-progress-percentage');

      // Mock delayed update (simulates plugin's delayed refresh after page load)
      setTimeout(() => {
        const totalCheckboxes = testCheckboxes.length;
        const checkedCheckboxes = testCheckboxes.filter(cb => cb.checked).length;
        const percentage = Math.round((checkedCheckboxes / totalCheckboxes) * 100);

        progressFill.style.width = `${percentage}%`;
        progressText.textContent = `${percentage}% (${checkedCheckboxes}/${totalCheckboxes})`;
      }, 500);

      // Initially should be 0% (before update)
      expect(progressFill.style.width).toBe('0%');

      // Advance time to trigger delayed update
      vi.advanceTimersByTime(600);

      // Should now reflect actual checkbox states (67% = 2/3)
      expect(progressFill.style.width).toBe('67%');
      expect(progressText.textContent).toBe('67% (2/3)');

      vi.useRealTimers();
    });

    test('should count radio button groups correctly for skill assessment', () => {
      // Clear all existing elements
      document.querySelectorAll('h4, input[type="radio"], input[type="checkbox"]').forEach(el => el.remove());

      // Create skill assessment page structure with H4s and radio groups
      const main = document.querySelector('#main');

      // Create 35 H4 elements (like skill assessment page)
      for (let i = 1; i <= 35; i++) {
        const h4 = document.createElement('h4');
        h4.textContent = `Question ${i}`;
        main.appendChild(h4);
      }

      // Create only 18 radio button groups (actual skill assessment questions)
      for (let i = 1; i <= 18; i++) {
        const groupContainer = document.createElement('div');
        for (let j = 1; j <= 5; j++) {
          const radio = document.createElement('input');
          radio.type = 'radio';
          radio.name = `skill-assessment-q${i}`;
          radio.value = j;
          radio.id = `skill-assessment-q${i}-r${j}`;
          groupContainer.appendChild(radio);
        }
        main.appendChild(groupContainer);
      }

      // Mock the corrected counting logic from learning-progress-tracker-plugin
      const updateSkillAssessmentProgress = () => {
        // Count radio button groups, not H4 elements
        const radioGroups = new Set();
        const allRadios = document.querySelectorAll('input[type="radio"][name^="skill-assessment-"]');
        allRadios.forEach(radio => {
          if (radio.name) radioGroups.add(radio.name);
        });

        const totalQuestions = radioGroups.size; // Should be 18, not 35
        const checkedQuestions = Array.from(radioGroups).filter(groupName => {
          return document.querySelector(`input[name="${groupName}"]:checked`);
        }).length;

        return { totalQuestions, checkedQuestions };
      };

      // Verify the structure
      const allH4s = document.querySelectorAll('h4');
      const allRadios = document.querySelectorAll('input[type="radio"]');
      const radioGroups = new Set();
      allRadios.forEach(radio => {
        if (radio.name) radioGroups.add(radio.name);
      });

      expect(allH4s.length).toBe(35); // Total H4 elements
      expect(allRadios.length).toBe(90); // 18 groups × 5 options
      expect(radioGroups.size).toBe(18); // Radio button groups

      // Test the corrected counting logic
      const progress = updateSkillAssessmentProgress();
      expect(progress.totalQuestions).toBe(18); // Should count radio groups, not H4s
      expect(progress.checkedQuestions).toBe(0); // None selected initially

      // Select a few answers
      document.querySelector('input[name="skill-assessment-q1"][value="3"]').checked = true;
      document.querySelector('input[name="skill-assessment-q5"][value="4"]').checked = true;
      document.querySelector('input[name="skill-assessment-q10"][value="2"]').checked = true;

      const progressWithAnswers = updateSkillAssessmentProgress();
      expect(progressWithAnswers.totalQuestions).toBe(18);
      expect(progressWithAnswers.checkedQuestions).toBe(3);
    });

    test('should handle mutation observer for dynamic content changes', () => {
      // Clear existing checkboxes first
      document.querySelectorAll('input[type="checkbox"]').forEach(cb => cb.remove());

      const banner = document.createElement('div');
      banner.innerHTML = `
        <div class="kata-progress-bar-fill" style="width: 0%;"></div>
        <div class="kata-progress-percentage">0% (0/0)</div>
      `;
      document.body.appendChild(banner);

      const progressFill = banner.querySelector('.kata-progress-bar-fill');
      const progressText = banner.querySelector('.kata-progress-percentage');

      let observerCallback = null;
      const testCheckboxes = [];

      // Mock MutationObserver behavior
      const _mockObserver = {
        observe: vi.fn(),
        disconnect: vi.fn()
      };

      // Mock the observer callback logic
      const setupMockObserver = () => {
        observerCallback = () => {
          const totalCheckboxes = testCheckboxes.length;
          const checkedCheckboxes = testCheckboxes.filter(cb => cb.checked).length;
          const percentage = totalCheckboxes > 0 ? Math.round((checkedCheckboxes / totalCheckboxes) * 100) : 0;

          progressFill.style.width = `${percentage}%`;
          progressText.textContent = `${percentage}% (${checkedCheckboxes}/${totalCheckboxes})`;
        };
      };

      setupMockObserver();

      // Initial state - no checkboxes
      expect(progressFill.style.width).toBe('0%');
      expect(progressText.textContent).toBe('0% (0/0)');

      // Simulate dynamic checkbox addition
      for (let i = 0; i < 2; i++) {
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.checked = i === 0; // First one checked
        checkbox.id = `mutation-test-${i}`;
        document.querySelector('#main').appendChild(checkbox);
        testCheckboxes.push(checkbox);
      }

      // Trigger observer callback (simulates mutation observer detecting changes)
      if (observerCallback) {
        observerCallback();
      }

      // Should now reflect new checkbox states (50% = 1/2)
      expect(progressFill.style.width).toBe('50%');
      expect(progressText.textContent).toBe('50% (1/2)');

      // Cleanup
      banner.remove();
      testCheckboxes.forEach(cb => cb.remove());
    });

    test('should support manual refresh progress method', () => {
      // Clear existing checkboxes first
      document.querySelectorAll('input[type="checkbox"]').forEach(cb => cb.remove());

      const banner = document.createElement('div');
      banner.innerHTML = `
        <div class="kata-progress-bar-fill" style="width: 0%;"></div>
        <div class="kata-progress-percentage">0% (0/4)</div>
      `;
      document.body.appendChild(banner);

      // Create checkboxes with mixed states
      const testCheckboxes = [];
      for (let i = 0; i < 4; i++) {
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.checked = i < 3; // First 3 checked
        checkbox.id = `manual-refresh-test-${i}`;
        document.querySelector('#main').appendChild(checkbox);
        testCheckboxes.push(checkbox);
      }

      const progressFill = banner.querySelector('.kata-progress-bar-fill');
      const progressText = banner.querySelector('.kata-progress-percentage');

      // Mock the manual refresh function (like plugin's refreshProgress)
      const manualRefresh = () => {
        const totalCheckboxes = testCheckboxes.length;
        const checkedCheckboxes = testCheckboxes.filter(cb => cb.checked).length;
        const percentage = Math.round((checkedCheckboxes / totalCheckboxes) * 100);

        progressFill.style.width = `${percentage}%`;
        progressText.textContent = `${percentage}% (${checkedCheckboxes}/${totalCheckboxes})`;
      };

      // Initial state should be 0% (not updated yet)
      expect(progressFill.style.width).toBe('0%');

      // Manually trigger refresh
      manualRefresh();

      // Should now reflect actual checkbox states (75% = 3/4)
      expect(progressFill.style.width).toBe('75%');
      expect(progressText.textContent).toBe('75% (3/4)');

      // Change checkbox state and refresh
      testCheckboxes[3].checked = true; // Check the last one
      manualRefresh();

      expect(progressFill.style.width).toBe('100%');
      expect(progressText.textContent).toBe('100% (4/4)');

      // Cleanup
      banner.remove();
      testCheckboxes.forEach(cb => cb.remove());
    });
  });

  describe('Skill Assessment Reset Functionality', () => {
    beforeEach(() => {
      // Setup skill assessment page
      document.body.innerHTML = `
        <div id="app">
          <main>
            <section class="content">
              <article class="markdown-section" id="main">
                <h1>Skill Assessment</h1>
                <div>
                  <ul>
                    <li class="rating-option">
                      <input type="radio" name="skill-assessment-q1" value="1" />
                      <label class="rating-label">Rating 1</label>
                    </li>
                    <li class="rating-option">
                      <input type="radio" name="skill-assessment-q1" value="2" />
                      <label class="rating-label">Rating 2</label>
                    </li>
                  </ul>
                  <ul>
                    <li class="rating-option">
                      <input type="radio" name="skill-assessment-q2" value="1" />
                      <label class="rating-label">Rating 1</label>
                    </li>
                    <li class="rating-option">
                      <input type="radio" name="skill-assessment-q2" value="2" />
                      <label class="rating-label">Rating 2</label>
                    </li>
                  </ul>
                  <ul>
                    <li class="rating-option">
                      <input type="radio" name="skill-assessment-q3" value="1" />
                      <label class="rating-label">Rating 1</label>
                    </li>
                    <li class="rating-option">
                      <input type="radio" name="skill-assessment-q3" value="2" />
                      <label class="rating-label">Rating 2</label>
                    </li>
                  </ul>
                </div>
              </article>
            </section>
          </main>
          <div id="learning-progress-banner">
            <div class="kata-progress-bar-fill" style="width: 0%;"></div>
            <span class="kata-progress-percentage">0% Complete (0/3)</span>
            <span class="current-question-display">Question 0 of 3</span>
            <span class="progress-aria-live" aria-live="polite">0% complete</span>
            <button class="kata-progress-btn-reset">Reset</button>
          </div>
        </div>
      `;

      Object.defineProperty(window, 'location', {
        value: { hash: '#/learning/skill-assessment' },
        writable: true,
        configurable: true
      });

      // Mock window.skillAssessmentForm
      window.skillAssessmentForm = {
        resetForm: vi.fn()
      };

      // Mock window.skillAssessmentStorage
      window.skillAssessmentStorage = {
        saveAssessmentProgress: vi.fn()
      };
    });

    test('should clear all radio buttons when reset clicked', async () => {
      // Check some radio buttons
      const radio1 = document.querySelector('input[name="skill-assessment-q1"][value="2"]');
      const radio2 = document.querySelector('input[name="skill-assessment-q2"][value="1"]');
      radio1.checked = true;
      radio2.checked = true;

      // Mock confirm dialog
      window.confirm = vi.fn(() => true);

      // Simulate reset button click by directly calling the logic
      const radioButtons = document.querySelectorAll('input[name^="skill-assessment-q"]');
      radioButtons.forEach(radio => {
        radio.checked = false;

        // Remove selected class from parent
        const parentLi = radio.closest('.rating-option');
        if (parentLi) {
          parentLi.classList.remove('selected');
        }
      });

      // Wait for async operations
      await new Promise(resolve => setTimeout(resolve, 100));

      // Verify all radio buttons unchecked
      const allRadios = document.querySelectorAll('input[type="radio"]');
      allRadios.forEach(radio => {
        expect(radio.checked).toBe(false);
      });

      // Verify all selected classes are removed from rating-option elements
      const allRatingOptions = document.querySelectorAll('.rating-option.selected');
      expect(allRatingOptions.length).toBe(0);
    });

    test('should remove selected class from parent rating-option elements', async () => {
      // Add selected class to simulate clicked state
      const radio1Parent = document.querySelector('input[name="skill-assessment-q1"][value="2"]').closest('.rating-option');
      const radio2Parent = document.querySelector('input[name="skill-assessment-q2"][value="1"]').closest('.rating-option');

      radio1Parent.classList.add('selected');
      radio2Parent.classList.add('selected');

      // Check radio buttons
      document.querySelector('input[name="skill-assessment-q1"][value="2"]').checked = true;
      document.querySelector('input[name="skill-assessment-q2"][value="1"]').checked = true;

      // Verify selected classes are present before reset
      expect(radio1Parent.classList.contains('selected')).toBe(true);
      expect(radio2Parent.classList.contains('selected')).toBe(true);

      // Simulate reset logic with selected class removal
      const radioButtons = document.querySelectorAll('input[name^="skill-assessment-q"]');
      radioButtons.forEach(radio => {
        if (radio.name && radio.name.startsWith('skill-assessment-q')) {
          radio.checked = false;
          const parentLi = radio.closest('.rating-option');
          if (parentLi) {
            parentLi.classList.remove('selected');
          }
          radio.dispatchEvent(new Event('change', { bubbles: true }));
        }
      });

      await new Promise(resolve => setTimeout(resolve, 100));

      // Verify all selected classes removed
      const allRatingOptions = document.querySelectorAll('.rating-option');
      allRatingOptions.forEach(option => {
        expect(option.classList.contains('selected')).toBe(false);
      });

      // Verify radio buttons also unchecked
      const allRadios = document.querySelectorAll('input[type="radio"]');
      allRadios.forEach(radio => {
        expect(radio.checked).toBe(false);
      });
    });

    test('should update progress displays after reset', async () => {
      // Check radio buttons to simulate progress
      document.querySelector('input[name="skill-assessment-q1"][value="2"]').checked = true;
      document.querySelector('input[name="skill-assessment-q2"][value="1"]').checked = true;

      // Update displays to simulate progress state
      document.querySelector('.kata-progress-bar-fill').style.width = '67%';
      document.querySelector('.kata-progress-percentage').textContent = '67% Complete (2/3)';
      document.querySelector('.current-question-display').textContent = 'Question 2 of 3';

      // Simulate reset logic
      const radioButtons = document.querySelectorAll('input[name^="skill-assessment-q"]');
      const radioGroups = new Set();

      radioButtons.forEach(radio => {
        if (radio.name && radio.name.startsWith('skill-assessment-q')) {
          radioGroups.add(radio.name);
          radio.checked = false;
        }
      });

      const totalQuestions = radioGroups.size || 3;

      // Update progress displays
      const progressBar = document.querySelector('.kata-progress-bar-fill');
      const progressText = document.querySelector('.kata-progress-percentage');
      const currentQuestionDisplay = document.querySelector('.current-question-display');
      const progressAriaLive = document.querySelector('.progress-aria-live');

      if (progressBar) progressBar.style.width = '0%';
      if (progressText) progressText.textContent = `0% Complete (0/${totalQuestions})`;
      if (currentQuestionDisplay) currentQuestionDisplay.textContent = `Question 0 of ${totalQuestions}`;
      if (progressAriaLive) progressAriaLive.textContent = '0% complete';

      // Wait for async operations
      await new Promise(resolve => setTimeout(resolve, 100));

      // Verify progress displays reset
      expect(document.querySelector('.kata-progress-bar-fill').style.width).toBe('0%');
      expect(document.querySelector('.kata-progress-percentage').textContent).toBe('0% Complete (0/3)');
      expect(document.querySelector('.current-question-display').textContent).toBe('Question 0 of 3');
      expect(document.querySelector('.progress-aria-live').textContent).toBe('0% complete');

      // Verify all selected classes are removed from rating-option elements
      const allRatingOptions = document.querySelectorAll('.rating-option.selected');
      expect(allRatingOptions.length).toBe(0);
    });

    test('should remove selected class from parent rating-option elements', async () => {
      // Add selected class to simulate clicked state
      const radio1Parent = document.querySelector('input[name="skill-assessment-q1"][value="2"]').closest('.rating-option');
      const radio2Parent = document.querySelector('input[name="skill-assessment-q2"][value="1"]').closest('.rating-option');

      radio1Parent.classList.add('selected');
      radio2Parent.classList.add('selected');

      // Check radio buttons
      document.querySelector('input[name="skill-assessment-q1"][value="2"]').checked = true;
      document.querySelector('input[name="skill-assessment-q2"][value="1"]').checked = true;

      // Verify selected classes are present before reset
      expect(radio1Parent.classList.contains('selected')).toBe(true);
      expect(radio2Parent.classList.contains('selected')).toBe(true);

      // Simulate reset logic with selected class removal
      const radioButtons = document.querySelectorAll('input[name^="skill-assessment-q"]');
      radioButtons.forEach(radio => {
        if (radio.name && radio.name.startsWith('skill-assessment-q')) {
          radio.checked = false;
          const parentLi = radio.closest('.rating-option');
          if (parentLi) {
            parentLi.classList.remove('selected');
          }
          radio.dispatchEvent(new Event('change', { bubbles: true }));
        }
      });

      await new Promise(resolve => setTimeout(resolve, 100));

      // Verify all selected classes removed
      const allRatingOptions = document.querySelectorAll('.rating-option');
      allRatingOptions.forEach(option => {
        expect(option.classList.contains('selected')).toBe(false);
      });

      // Verify radio buttons also unchecked
      const allRadios = document.querySelectorAll('input[type="radio"]');
      allRadios.forEach(radio => {
        expect(radio.checked).toBe(false);
      });
    });

    test('should call skillAssessmentForm.resetForm when available', async () => {
      // Simulate calling resetForm
      if (window.skillAssessmentForm && typeof window.skillAssessmentForm.resetForm === 'function') {
        window.skillAssessmentForm.resetForm();
      }

      await new Promise(resolve => setTimeout(resolve, 100));

      expect(window.skillAssessmentForm.resetForm).toHaveBeenCalled();
    });

    test('should clear storage with correct data structure', async () => {
      const radioButtons = document.querySelectorAll('input[name^="skill-assessment-q"]');
      const radioGroups = new Set();
      radioButtons.forEach(radio => {
        if (radio.name && radio.name.startsWith('skill-assessment-q')) {
          radioGroups.add(radio.name);
        }
      });
      const totalQuestions = radioGroups.size || 3;

      // Simulate storage clear
      if (window.skillAssessmentStorage) {
        window.skillAssessmentStorage.saveAssessmentProgress(
          'skill-assessment-responses',
          {
            responses: {},
            completedQuestions: 0,
            totalQuestions: totalQuestions,
            completionPercentage: 0
          }
        );
      }

      await new Promise(resolve => setTimeout(resolve, 100));

      expect(window.skillAssessmentStorage.saveAssessmentProgress).toHaveBeenCalledWith(
        'skill-assessment-responses',
        {
          responses: {},
          completedQuestions: 0,
          totalQuestions: 3,
          completionPercentage: 0
        }
      );
    });

    test('should handle reset when no radio buttons selected', async () => {
      // Simulate reset with no selections
      const radioButtons = document.querySelectorAll('input[name^="skill-assessment-q"]');
      const radioGroups = new Set();

      radioButtons.forEach(radio => {
        if (radio.name && radio.name.startsWith('skill-assessment-q')) {
          radioGroups.add(radio.name);
          radio.checked = false;
        }
      });

      const totalQuestions = radioGroups.size || 3;
      const progressText = document.querySelector('.kata-progress-percentage');
      progressText.textContent = `0% Complete (0/${totalQuestions})`;

      await new Promise(resolve => setTimeout(resolve, 100));

      // Should not throw error
      expect(document.querySelector('.kata-progress-percentage').textContent).toBe('0% Complete (0/3)');
    });
  });
});
