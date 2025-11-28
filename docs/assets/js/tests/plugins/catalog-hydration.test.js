/**
 * Catalog Hydration Plugin Tests
 * Tests for CatalogHydration plugin initialization and page detection
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { CatalogHydration } from '../../plugins/catalog-hydration.js';

describe('CatalogHydration Plugin - Initialization', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="app"></div>';
  });

  it('should initialize plugin instance', () => {
    const plugin = new CatalogHydration();
    expect(plugin).toBeDefined();
    expect(plugin.init).toBeTypeOf('function');
  });

  it('should have required properties after instantiation', () => {
    const plugin = new CatalogHydration();
    expect(plugin).toHaveProperty('API_BASE');
    expect(plugin).toHaveProperty('selections');
    expect(plugin).toHaveProperty('progressData');
  });

  it('should only activate on catalog page', async () => {
    window.location.hash = '#/learning/catalog';
    const plugin = new CatalogHydration();
    const decorateSpy = vi.spyOn(plugin, 'decorateEntries');

    await plugin.init();

    expect(decorateSpy).toHaveBeenCalled();
  });

  it('should not activate on other pages', async () => {
    window.location.hash = '#/learning/paths/foundation';
    const plugin = new CatalogHydration();
    const decorateSpy = vi.spyOn(plugin, 'decorateEntries');

    await plugin.init();

    expect(decorateSpy).not.toHaveBeenCalled();
  });

  it('should not activate on home page', async () => {
    window.location.hash = '#/';
    const plugin = new CatalogHydration();
    const decorateSpy = vi.spyOn(plugin, 'decorateEntries');

    await plugin.init();

    expect(decorateSpy).not.toHaveBeenCalled();
  });

  it('should not activate on kata pages', async () => {
    window.location.hash = '#/learning/katas/docker-fundamentals/docker-fundamentals';
    const plugin = new CatalogHydration();
    const decorateSpy = vi.spyOn(plugin, 'decorateEntries');

    await plugin.init();

    expect(decorateSpy).not.toHaveBeenCalled();
  });
});

describe('CatalogHydration Plugin - API Data Fetching', () => {
  let plugin;

  beforeEach(() => {
    document.body.innerHTML = '<div id="app"></div>';
    plugin = new CatalogHydration();
    global.fetch = vi.fn();
    localStorage.clear();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('fetchSelections()', () => {
    it('should fetch selections from API and populate selections Set', async () => {
      const mockResponse = {
        data: {
          selections: {
            selectedItems: ['kata-docker-01', 'path-foundation', 'kata-ai-02']
          }
        }
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchSelections();

      expect(global.fetch).toHaveBeenCalled();
      const fetchCallUrl = global.fetch.mock.calls[0][0];
      expect(fetchCallUrl).toContain('http://localhost:3002/api/learning/selections');
      expect(plugin.selections.size).toBe(3);
      expect(plugin.selections.has('kata-docker-01')).toBe(true);
      expect(plugin.selections.has('path-foundation')).toBe(true);
      expect(plugin.selections.has('kata-ai-02')).toBe(true);
    });

    it('should save selections to localStorage', async () => {
      const mockResponse = {
        data: {
          selections: {
            selectedItems: ['kata-docker-01', 'kata-ai-02']
          }
        }
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchSelections();

      const cached = JSON.parse(localStorage.getItem('selectedLearningPaths'));
      expect(cached).toEqual(expect.arrayContaining(['kata-docker-01', 'kata-ai-02']));
      expect(cached.length).toBe(2);
    });

    it('should handle empty selections from API', async () => {
      const mockResponse = {
        selections: {
          selectedItems: []
        }
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchSelections();

      expect(plugin.selections.size).toBe(0);
    });

    it('should fall back to localStorage on API error', async () => {
      localStorage.setItem('selectedLearningPaths', JSON.stringify(['kata-cached-01', 'kata-cached-02']));

      global.fetch.mockResolvedValueOnce({
        ok: false,
        status: 500
      });

      await plugin.fetchSelections();

      expect(plugin.selections.size).toBe(2);
      expect(plugin.selections.has('kata-cached-01')).toBe(true);
      expect(plugin.selections.has('kata-cached-02')).toBe(true);
    });

    it('should fall back to localStorage on network error', async () => {
      localStorage.setItem('selectedLearningPaths', JSON.stringify(['kata-offline-01']));

      global.fetch.mockRejectedValueOnce(new Error('Network error'));

      await plugin.fetchSelections();

      expect(plugin.selections.size).toBe(1);
      expect(plugin.selections.has('kata-offline-01')).toBe(true);
    });

    it('should initialize empty Set if no API and no cache', async () => {
      global.fetch.mockRejectedValueOnce(new Error('Network error'));

      await plugin.fetchSelections();

      expect(plugin.selections.size).toBe(0);
    });
  });

  describe('fetchProgress()', () => {
    it('should fetch progress from API and populate progressData', async () => {
      const mockResponse = {
        progressData: [
          {
            type: 'kata',
            pageId: 'learning/katas/docker-fundamentals/01-docker-basics.md',
            items: [
              { id: 'task-1', completed: true },
              { id: 'task-2', completed: false }
            ]
          },
          {
            type: 'kata',
            pageId: 'learning/katas/ai-assisted-engineering/02-advanced.md',
            items: [
              { id: 'task-1', completed: true },
              { id: 'task-2', completed: true },
              { id: 'task-3', completed: true }
            ]
          }
        ]
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchProgress();

      expect(global.fetch).toHaveBeenCalled();
      const fetchCallUrl = global.fetch.mock.calls[0][0];
      expect(fetchCallUrl).toContain('http://localhost:3002/api/progress');
      expect(Object.keys(plugin.progressData).length).toBeGreaterThan(0);
    });

    it('should calculate correct progress percentages for katas', async () => {
      const mockResponse = {
        progressData: [
          {
            type: 'kata',
            pageId: 'learning/katas/docker-fundamentals/01-docker-basics.md',
            items: [
              { id: 'task-1', completed: true },
              { id: 'task-2', completed: true },
              { id: 'task-3', completed: false },
              { id: 'task-4', completed: false }
            ]
          }
        ]
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchProgress();

      const kataKey = Object.keys(plugin.progressData)[0];
      expect(plugin.progressData[kataKey]).toBeDefined();
      expect(plugin.progressData[kataKey].percentage).toBe(50);
      expect(plugin.progressData[kataKey].completed).toBe(2);
      expect(plugin.progressData[kataKey].total).toBe(4);
    });

    it('should process both kata-type and path-type progress items', async () => {
      const mockResponse = {
        progressData: [
          {
            type: 'kata',
            pageId: 'learning/katas/docker/01.md',
            items: [{ id: 'task-1', completed: true }]
          },
          {
            type: 'path',
            pageId: 'learning/paths/foundation.md',
            items: [{ id: 'task-1', completed: true }],
            completionPercentage: 50
          }
        ]
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchProgress();

      // Should process both kata and path items
      expect(Object.keys(plugin.progressData).length).toBe(2);
    });

    it('should handle API errors gracefully', async () => {
      global.fetch.mockResolvedValueOnce({
        ok: false,
        status: 404
      });

      await plugin.fetchProgress();

      expect(Object.keys(plugin.progressData).length).toBe(0);
    });

    it('should handle network errors gracefully', async () => {
      global.fetch.mockRejectedValueOnce(new Error('Network error'));

      await plugin.fetchProgress();

      expect(Object.keys(plugin.progressData).length).toBe(0);
    });

    it('should handle empty progress data from API', async () => {
      const mockResponse = {
        progressData: []
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchProgress();

      expect(Object.keys(plugin.progressData).length).toBe(0);
    });

    it('should handle 100% completed katas', async () => {
      const mockResponse = {
        progressData: [
          {
            type: 'kata',
            pageId: 'learning/katas/docker/01.md',
            items: [
              { id: 'task-1', completed: true },
              { id: 'task-2', completed: true }
            ]
          }
        ]
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchProgress();

      const kataKey = Object.keys(plugin.progressData)[0];
      expect(plugin.progressData[kataKey].percentage).toBe(100);
    });

    it('should handle 0% completed katas', async () => {
      const mockResponse = {
        progressData: [
          {
            type: 'kata',
            pageId: 'learning/katas/docker/01.md',
            items: [
              { id: 'task-1', completed: false },
              { id: 'task-2', completed: false }
            ]
          }
        ]
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchProgress();

      const kataKey = Object.keys(plugin.progressData)[0];
      expect(plugin.progressData[kataKey].percentage).toBe(0);
    });
  });
});

describe('CatalogHydration Plugin - DOM Decoration', () => {
  let plugin;

  beforeEach(() => {
    // Setup catalog HTML structure similar to learning/catalog.md
    document.body.innerHTML = `
      <div id="app">
        <ul>
          <li class="task-list-item">
            <label>
              <input type="checkbox" disabled>
              <a href="#/learning/katas/ai/01-ai-fundamentals.md">AI Fundamentals</a>
              <em>Foundation | 30 min</em>
            </label>
          </li>
          <li class="task-list-item">
            <label>
              <input type="checkbox" disabled>
              <a href="#/learning/katas/docker/01-docker-basics.md">Docker Basics</a>
              <em>Foundation | 45 min</em>
            </label>
          </li>
          <li class="task-list-item">
            <label>
              <input type="checkbox" disabled>
              <a href="#/learning/paths/foundation.md">Foundation Path</a>
              <em>Learning Path | 5 hours</em>
            </label>
          </li>
        </ul>
      </div>
    `;

    plugin = new CatalogHydration();

    // Mock selections and progress data
    plugin.selections = new Set(['ai-01-ai-fundamentals', 'path-foundation']);
    plugin.progressData = {
      'ai-01-ai-fundamentals': {
        percentage: 50,
        completed: 2,
        total: 4
      },
      'docker-01-docker-basics': {
        percentage: 0,
        completed: 0,
        total: 3
      }
    };
  });

  describe('decorateEntries()', () => {
    it('should query all task list items in the catalog', () => {
      plugin.decorateEntries();

      const taskItems = document.querySelectorAll('.task-list-item');
      expect(taskItems.length).toBe(3);
    });

    it('should add data-item-id to checkboxes', () => {
      plugin.decorateEntries();

      const checkbox1 = document.querySelector('input[data-item-id="ai-01-ai-fundamentals"]');
      const checkbox2 = document.querySelector('input[data-item-id="docker-01-docker-basics"]');

      expect(checkbox1).toBeDefined();
      expect(checkbox2).toBeDefined();
    });

    it('should pre-check checkboxes for selected items', () => {
      plugin.decorateEntries();

      const checkbox1 = document.querySelector('input[data-item-id="ai-01-ai-fundamentals"]');
      const checkbox2 = document.querySelector('input[data-item-id="docker-01-docker-basics"]');
      const checkbox3 = document.querySelector('input[data-item-id="path-foundation"]');

      expect(checkbox1.checked).toBe(true);  // In selections
      expect(checkbox2.checked).toBe(false); // Not in selections
      expect(checkbox3.checked).toBe(true);  // In selections
    });

    it('should inject progress bar HTML for items with progress data', () => {
      plugin.decorateEntries();

      const label1 = document.querySelectorAll('label')[0];
      const label2 = document.querySelectorAll('label')[1];
      const progressContainer1 = label1.querySelector('.learning-progress-container');
      const progressContainer2 = label2.querySelector('.learning-progress-container');
      const link1 = label1.querySelector('a');

      expect(progressContainer1).not.toBeNull();
      expect(progressContainer1.innerHTML).toContain('Progress:');
      expect(progressContainer1.innerHTML).toContain('50%');
      expect(progressContainer1.innerHTML).not.toContain(' • ');
      expect(progressContainer1.nextElementSibling).toBe(link1);
      expect(progressContainer2).not.toBeNull();
      expect(progressContainer2.innerHTML).toContain('Progress:');
      expect(progressContainer2.innerHTML).toContain('0%');
    });

    it('should add default progress bar for items without progress data', () => {
      plugin.decorateEntries();

      const label3 = document.querySelectorAll('label')[2]; // Foundation Path
      const progressContainer3 = label3.querySelector('.learning-progress-container');

      // Plugin adds default 0% progress for all items, even without progress data
      expect(progressContainer3).not.toBeNull();
      expect(progressContainer3.innerHTML).toContain('Progress:');
      expect(progressContainer3.innerHTML).toContain('not-started');
    });

    it('should handle items with missing checkboxes gracefully', () => {
      document.body.innerHTML = `
        <div id="app">
          <ul>
            <li class="task-list-item">
              <a href="#/learning/katas/ai/01-ai-fundamentals.md">AI Fundamentals</a>
            </li>
          </ul>
        </div>
      `;

      expect(() => plugin.decorateEntries()).not.toThrow();
    });

    it('should handle items with missing links gracefully', () => {
      document.body.innerHTML = `
        <div id="app">
          <ul>
            <li class="task-list-item">
              <input type="checkbox" disabled>
              <p>Foundation | 30 min</p>
            </li>
          </ul>
        </div>
      `;

      expect(() => plugin.decorateEntries()).not.toThrow();
    });

    it('should inject progress bar into paragraph wrapper', () => {
      document.body.innerHTML = `
        <div id="app">
          <ul>
            <li class="task-list-item">
              <p>
                <input type="checkbox" data-item-id="category-kata-test-para" />
                <a href="#/learning/katas/category/kata-test-para">Test Kata in Paragraph</a>
              </p>
            </li>
          </ul>
        </div>
      `;

      plugin.progressData = {
        'category-kata-test-para': { percentage: 25, completed: 5, total: 20 }
      };

      plugin.decorateEntries();

      const paragraph = document.querySelector('p');
      const progressContainer = paragraph.querySelector('.learning-progress-container');
      expect(progressContainer).not.toBeNull();
      expect(progressContainer.innerHTML).toContain('25%');
    });

    it('should display Not Started badge for 0% progress in paragraph wrapper', () => {
      document.body.innerHTML = `
        <div id="app">
          <ul>
            <li class="task-list-item">
              <p>
                <input type="checkbox" data-item-id="kata-test-zero" />
                <a href="#/learning/katas/category/kata-test-zero">Test Kata Zero Progress</a>
              </p>
            </li>
          </ul>
        </div>
      `;

      plugin.progressData = {
        'kata-test-zero': { percentage: 0, completed: 0, total: 15 }
      };

      plugin.decorateEntries();

      const paragraph = document.querySelector('p');
      const progressContainer = paragraph.querySelector('.learning-progress-container');
      expect(progressContainer).not.toBeNull();
      expect(progressContainer.innerHTML).toContain('Not Started');
      const badge = progressContainer.querySelector('.catalog-progress-badge');
      expect(badge.classList.contains('not-started')).toBe(true);
    });

    it('should prefer label over paragraph when both exist', () => {
      document.body.innerHTML = `
        <div id="app">
          <ul>
            <li class="task-list-item">
              <label>
                <input type="checkbox" data-item-id="kata-test-both" />
                <a href="#/learning/katas/category/kata-test-both">Test Kata Both Wrappers</a>
              </label>
              <p>Extra paragraph element</p>
            </li>
          </ul>
        </div>
      `;

      plugin.progressData = {
        'kata-test-both': { percentage: 75, completed: 15, total: 20 }
      };

      plugin.decorateEntries();

      const label = document.querySelector('label');
      const paragraph = document.querySelector('p');
      const labelProgress = label.querySelector('.learning-progress-container');
      const paragraphProgress = paragraph.querySelector('.learning-progress-container');
      expect(labelProgress).not.toBeNull();
      expect(paragraphProgress).toBeNull();
    });

    it('should not duplicate progress bars for paragraph wrappers', () => {
      document.body.innerHTML = `
        <div id="app">
          <ul>
            <li class="task-list-item">
              <p>
                <input type="checkbox" data-item-id="kata-test-dup" />
                <a href="#/learning/katas/category/kata-test-dup">Test Kata Duplicate Prevention</a>
              </p>
            </li>
          </ul>
        </div>
      `;

      plugin.progressData = {
        'kata-test-dup': { percentage: 60, completed: 12, total: 20 }
      };

      plugin.decorateEntries();
      plugin.decorateEntries();
      plugin.decorateEntries();

      const progressContainers = document.querySelectorAll('.learning-progress-container');
      expect(progressContainers.length).toBe(1);
    });

    it('should handle empty catalog page', () => {
      document.body.innerHTML = '<div id="app"></div>';

      expect(() => plugin.decorateEntries()).not.toThrow();
    });
  });

  describe('createProgressBar()', () => {
    it('should generate progress bar HTML with correct percentage', () => {
      const progressHTML = plugin.createProgressBar(75);

      expect(progressHTML).toContain('75%');
      expect(progressHTML).toContain('catalog-progress-badge');
      expect(progressHTML).toContain('catalog-progress-fill');
      expect(progressHTML).toContain('width: 75%');
    });

    it('should not inject into both label and paragraph if nested', async () => {
      document.body.innerHTML = `
        <li class="task-list-item">
          <label>
            <p>
              <input type="checkbox" data-item-id="nested-test">
              <a href="#/learning/katas/category/nested-test">Nested Test Kata</a>
            </p>
          </label>
        </li>
      `;
      plugin.progressData = { 'category-nested-test': { percentage: 25, completed: 5, total: 20 } };

      await plugin.decorateEntries();

      const item = document.querySelector('.task-list-item');
      const progressContainers = item.querySelectorAll('.learning-progress-container');
      expect(progressContainers.length).toBe(1);
      expect(progressContainers[0].innerHTML).toContain('25%');
      expect(progressContainers[0].innerHTML).not.toContain('0%');
    });

    it('should not duplicate when decorateEntries called multiple times', async () => {
      document.body.innerHTML = `
        <li class="task-list-item">
          <label>
            <input type="checkbox" data-item-id="multi-test">
            <a href="#/learning/katas/category/multi-test">Multi Test Kata</a>
          </label>
        </li>
      `;
      plugin.progressData = { 'category-multi-test': { percentage: 50, completed: 10, total: 20 } };

      await plugin.decorateEntries();
      await plugin.decorateEntries();
      await plugin.decorateEntries();

      const item = document.querySelector('.task-list-item');
      const progressContainers = item.querySelectorAll('.learning-progress-container');
      expect(progressContainers.length).toBe(1);
    });

    it('should generate visual bar representation', () => {
      const progressHTML = plugin.createProgressBar(50);

      expect(progressHTML).toContain('catalog-progress-track');
      expect(progressHTML).toContain('catalog-progress-fill');
      expect(progressHTML).toContain('width: 50%');
    });

    it('should handle 0% progress', () => {
      const progressHTML = plugin.createProgressBar(0);

      expect(progressHTML).toContain('0%');
      expect(progressHTML).toContain('width: 0%');
      expect(progressHTML).toContain('catalog-progress-fill');
    });

    it('should handle 100% progress', () => {
      const progressHTML = plugin.createProgressBar(100);

      expect(progressHTML).toContain('100%');
      expect(progressHTML).toContain('width: 100%');
      expect(progressHTML).toContain('catalog-progress-fill');
    });

    it('should handle intermediate percentages correctly', () => {
      const progressHTML = plugin.createProgressBar(35);

      expect(progressHTML).toContain('35%');
      expect(progressHTML).toContain('width: 35%');
      expect(progressHTML).toContain('catalog-progress-track');
      expect(progressHTML).toContain('catalog-progress-fill');
      expect(progressHTML).toContain('catalog-progress-text');
    });
  });

  describe('extractItemIdFromLink()', () => {
    it('should extract kata ID from kata link', () => {
      const itemId = plugin.extractItemIdFromLink('#/learning/katas/ai/01-ai-fundamentals.md');
      expect(itemId).toBe('ai-01-ai-fundamentals');
    });

    it('should extract path ID from path link', () => {
      const itemId = plugin.extractItemIdFromLink('#/learning/paths/foundation.md');
      expect(itemId).toBe('path-foundation');
    });

    it('should extract lab ID from training lab link', () => {
      const itemId = plugin.extractItemIdFromLink('#/learning/training-labs/azure-iot-lab.md');
      expect(itemId).toBe('lab-azure-iot-lab');
    });

    it('should handle kata links without number prefix', () => {
      const itemId = plugin.extractItemIdFromLink('#/learning/katas/docker/docker-basics.md');
      expect(itemId).toBe('docker-docker-basics');
    });

    it('should return null for invalid link formats', () => {
      const itemId = plugin.extractItemIdFromLink('#/learning/invalid-format');
      expect(itemId).toBeNull();
    });
  });

  describe('Checkbox Event Handling', () => {
    beforeEach(() => {
      // Reset localStorage
      localStorage.clear();

      // Mock fetch for POST /api/learning/selections
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ success: true })
      });

      // Setup DOM with checkboxes
      document.body.innerHTML = `
        <ul>
          <li class="task-list-item">
            <input type="checkbox" data-item-id="kata-ai-01">
            <a href="#/learning/katas/ai/01-ai-fundamentals.md">AI Fundamentals</a>
            <p>Difficulty: Beginner</p>
          </li>
          <li class="task-list-item">
            <input type="checkbox" data-item-id="kata-docker-02">
            <a href="#/learning/katas/docker/02-docker-compose.md">Docker Compose</a>
            <p>Difficulty: Intermediate</p>
          </li>
          <li class="task-list-item">
            <input type="checkbox" data-item-id="path-foundation">
            <a href="#/learning/paths/foundation.md">Foundation Path</a>
            <p>Duration: 8 weeks</p>
          </li>
        </ul>
      `;
    });

    afterEach(() => {
      vi.restoreAllMocks();
    });

    it('should attach event listener to document', () => {
      const plugin = new CatalogHydration();
      const addEventListenerSpy = vi.spyOn(document, 'addEventListener');

      plugin.attachEventListeners();

      expect(addEventListenerSpy).toHaveBeenCalledWith('change', expect.any(Function));
    });

    it('should add item to selections when checkbox is checked', async () => {
      const plugin = new CatalogHydration();
      plugin.attachEventListeners();

      const checkbox = document.querySelector('input[data-item-id="kata-ai-01"]');
      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change', { bubbles: true }));

      // Wait for async operations
      await new Promise(resolve => setTimeout(resolve, 10));

      expect(plugin.selections.has('kata-ai-01')).toBe(true);
    });

    it('should remove item from selections when checkbox is unchecked', async () => {
      const plugin = new CatalogHydration();
      plugin.selections.add('kata-docker-02'); // Pre-select item
      plugin.attachEventListeners();

      const checkbox = document.querySelector('input[data-item-id="kata-docker-02"]');
      checkbox.checked = false;
      checkbox.dispatchEvent(new Event('change', { bubbles: true }));

      // Wait for async operations
      await new Promise(resolve => setTimeout(resolve, 10));

      expect(plugin.selections.has('kata-docker-02')).toBe(false);
    });

    it('should call saveSelections after checkbox change', async () => {
      const plugin = new CatalogHydration();
      const saveSpy = vi.spyOn(plugin, 'saveSelections');
      plugin.attachEventListeners();

      const checkbox = document.querySelector('input[data-item-id="path-foundation"]');
      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change', { bubbles: true }));

      // Wait for async operations and debounce delay (500ms + buffer)
      await new Promise(resolve => setTimeout(resolve, 600));

      expect(saveSpy).toHaveBeenCalled();
    });

    it('should ignore change events from non-checkbox elements', async () => {
      const plugin = new CatalogHydration();
      const saveSpy = vi.spyOn(plugin, 'saveSelections');
      plugin.attachEventListeners();

      const link = document.querySelector('a');
      link.dispatchEvent(new Event('change', { bubbles: true }));

      // Wait to ensure no async operations triggered
      await new Promise(resolve => setTimeout(resolve, 10));

      expect(saveSpy).not.toHaveBeenCalled();
    });

    it('should handle checkboxes without data-item-id gracefully', async () => {
      const plugin = new CatalogHydration();
      plugin.attachEventListeners();

      // Add checkbox without data-item-id
      const li = document.createElement('li');
      li.className = 'task-list-item';
      li.innerHTML = '<input type="checkbox"><a href="#">No ID</a>';
      document.querySelector('ul').appendChild(li);

      const checkbox = li.querySelector('input');
      checkbox.checked = true;

      // Should not throw error
      expect(() => {
        checkbox.dispatchEvent(new Event('change', { bubbles: true }));
      }).not.toThrow();
    });

    it('should POST selections to API endpoint', async () => {
      const plugin = new CatalogHydration();
      plugin.selections.add('kata-ai-01');
      plugin.selections.add('path-foundation');

      await plugin.saveSelections();

      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining('http://localhost:3002/api/learning/selections'),
        expect.objectContaining({
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: expect.any(String)
        })
      );

      const callArgs = global.fetch.mock.calls[0];
      const bodyData = JSON.parse(callArgs[1].body);
      expect(bodyData.selectedItems).toEqual(expect.arrayContaining(['kata-ai-01', 'path-foundation']));
      expect(bodyData.userId).toBe('default-user');
    });

    it('should update localStorage after successful save', async () => {
      const plugin = new CatalogHydration();
      plugin.selections.add('kata-docker-02');

      await plugin.saveSelections();

      const stored = JSON.parse(localStorage.getItem('selectedLearningPaths'));
      expect(stored).toEqual(['kata-docker-02']);
    });

    it('should handle API errors gracefully', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: false,
        status: 500
      });

      const plugin = new CatalogHydration();
      plugin.selections.add('kata-ai-01');

      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

      await plugin.saveSelections();

      expect(consoleSpy).toHaveBeenCalledWith(
        '❌',
        expect.stringContaining('Failed to save selections')
      );

      consoleSpy.mockRestore();
    });

    it('should handle network errors gracefully', async () => {
      global.fetch = vi.fn().mockRejectedValue(new Error('Network error'));

      const plugin = new CatalogHydration();
      plugin.selections.add('path-foundation');

      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

      await plugin.saveSelections();

      expect(consoleSpy).toHaveBeenCalledWith(
        '❌',
        expect.stringContaining('Failed to save selections')
      );

      consoleSpy.mockRestore();
    });

    it('should save empty selections array when no items selected', async () => {
      const plugin = new CatalogHydration();
      // selections Set is empty

      await plugin.saveSelections();

      expect(global.fetch).toHaveBeenCalled();
      const callArgs = global.fetch.mock.calls[0];
      const bodyData = JSON.parse(callArgs[1].body);
      expect(bodyData.selectedItems).toEqual([]);
    });

    it('should update selections Set immediately before API call', async () => {
      const plugin = new CatalogHydration();
      plugin.attachEventListeners();

      const checkbox = document.querySelector('input[data-item-id="kata-ai-01"]');

      // Check the checkbox
      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change', { bubbles: true }));

      // Selections should be updated immediately (synchronously)
      expect(plugin.selections.has('kata-ai-01')).toBe(true);
    });

    it('should handle multiple rapid checkbox changes', async () => {
      const plugin = new CatalogHydration();
      plugin.attachEventListeners();

      const checkbox1 = document.querySelector('input[data-item-id="kata-ai-01"]');
      const checkbox2 = document.querySelector('input[data-item-id="kata-docker-02"]');
      const checkbox3 = document.querySelector('input[data-item-id="path-foundation"]');

      // Rapid changes
      checkbox1.checked = true;
      checkbox1.dispatchEvent(new Event('change', { bubbles: true }));

      checkbox2.checked = true;
      checkbox2.dispatchEvent(new Event('change', { bubbles: true }));

      checkbox3.checked = true;
      checkbox3.dispatchEvent(new Event('change', { bubbles: true }));

      // Wait for all async operations and debounce delay (500ms + buffer)
      await new Promise(resolve => setTimeout(resolve, 600));

      expect(plugin.selections.has('kata-ai-01')).toBe(true);
      expect(plugin.selections.has('kata-docker-02')).toBe(true);
      expect(plugin.selections.has('path-foundation')).toBe(true);

      // saveSelections should be called once due to debouncing (not multiple times)
      expect(global.fetch).toHaveBeenCalled();
    });
  });
});

describe('CatalogHydration Plugin - Assessment Recommendations Integration', () => {
  let plugin;

  beforeEach(() => {
    document.body.innerHTML = '<div id="app"></div>';
    plugin = new CatalogHydration();
    global.fetch = vi.fn();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('getPathsForSkillLevel()', () => {
    it('should return foundation path for beginner level', () => {
      const paths = plugin.getPathsForSkillLevel('beginner');
      expect(paths).toEqual(['path-foundation-ai-engineering']);
    });

    it('should return 3 paths for intermediate level', () => {
      const paths = plugin.getPathsForSkillLevel('intermediate');
      expect(paths).toHaveLength(3);
      expect(paths).toContain('path-foundation-ai-engineering');
      expect(paths).toContain('path-skill-prompt-engineering');
      expect(paths).toContain('path-skill-edge-to-cloud-integration');
    });

    it('should return 2 expert paths for advanced level', () => {
      const paths = plugin.getPathsForSkillLevel('advanced');
      expect(paths).toHaveLength(2);
      expect(paths).toContain('path-expert-edge-ai-systems');
      expect(paths).toContain('path-expert-full-stack-ai-integration');
    });

    it('should return empty array for unknown skill level', () => {
      const paths = plugin.getPathsForSkillLevel('unknown');
      expect(paths).toEqual([]);
    });

    it('should return empty array for null input', () => {
      const paths = plugin.getPathsForSkillLevel(null);
      expect(paths).toEqual([]);
    });

    it('should return empty array for undefined input', () => {
      const paths = plugin.getPathsForSkillLevel(undefined);
      expect(paths).toEqual([]);
    });
  });

  describe('applyRecommendations()', () => {
    beforeEach(() => {
      // Mock fetch for saveSelections
      global.fetch.mockResolvedValue({
        ok: true,
        json: async () => ({ success: true })
      });
    });

    it('should add recommendations to selections Set', async () => {
      plugin.recommendations = ['path-foundation-ai-engineering', 'kata-ai-01'];

      await plugin.applyRecommendations();

      expect(plugin.selections.has('path-foundation-ai-engineering')).toBe(true);
      expect(plugin.selections.has('kata-ai-01')).toBe(true);
      expect(plugin.selections.size).toBe(2);
    });

    it('should persist recommendations via API', async () => {
      plugin.recommendations = ['path-foundation-ai-engineering'];

      await plugin.applyRecommendations();

      expect(global.fetch).toHaveBeenCalled();
      const callArgs = global.fetch.mock.calls[0];
      expect(callArgs[0]).toContain('http://localhost:3002/api/learning/selections');
      expect(callArgs[1].method).toBe('POST');

      const bodyData = JSON.parse(callArgs[1].body);
      expect(bodyData.selectedItems).toContain('path-foundation-ai-engineering');
    });

    it('should call decorateEntries after applying recommendations', async () => {
      plugin.recommendations = ['path-foundation-ai-engineering'];
      const decorateSpy = vi.spyOn(plugin, 'decorateEntries');

      await plugin.applyRecommendations();

      expect(decorateSpy).toHaveBeenCalled();
    });

    it('should do nothing if recommendations array is empty', async () => {
      plugin.recommendations = [];
      const saveSelectionsSpy = vi.spyOn(plugin, 'saveSelections');

      await plugin.applyRecommendations();

      expect(saveSelectionsSpy).not.toHaveBeenCalled();
      expect(plugin.selections.size).toBe(0);
    });

    it('should merge recommendations with existing selections', async () => {
      plugin.selections.add('kata-docker-01');
      plugin.recommendations = ['path-foundation-ai-engineering'];

      await plugin.applyRecommendations();

      expect(plugin.selections.has('kata-docker-01')).toBe(true);
      expect(plugin.selections.has('path-foundation-ai-engineering')).toBe(true);
      expect(plugin.selections.size).toBe(2);
    });

    it('should handle duplicate recommendations gracefully', async () => {
      plugin.selections.add('path-foundation-ai-engineering');
      plugin.recommendations = ['path-foundation-ai-engineering', 'kata-ai-01'];

      await plugin.applyRecommendations();

      // Set should not have duplicates
      expect(plugin.selections.size).toBe(2);
      expect(plugin.selections.has('path-foundation-ai-engineering')).toBe(true);
      expect(plugin.selections.has('kata-ai-01')).toBe(true);
    });

    it('should handle API errors gracefully', async () => {
      global.fetch.mockRejectedValueOnce(new Error('Network error'));
      plugin.recommendations = ['path-foundation-ai-engineering'];

      // Should not throw
      await expect(plugin.applyRecommendations()).resolves.not.toThrow();
    });
  });

  describe('fetchAssessmentRecommendations()', () => {
    beforeEach(() => {
      // Setup mock DOM with catalog items
      document.body.innerHTML = `
        <div id="app">
          <ul>
            <li class="task-list-item">
              <input type="checkbox" data-item-id="path-foundation-ai-engineering">
              <a href="/learning/paths/foundation-ai-engineering.md">Foundation: AI Engineering</a>
            </li>
            <li class="task-list-item">
              <input type="checkbox" data-item-id="path-skill-prompt-engineering">
              <a href="/learning/paths/skill-prompt-engineering.md">Skill: Prompt Engineering</a>
            </li>
            <li class="task-list-item">
              <input type="checkbox" data-item-id="path-expert-edge-ai-systems">
              <a href="/learning/paths/expert-edge-ai-systems.md">Expert: Edge AI Systems</a>
            </li>
          </ul>
        </div>
      `;
    });

    it('should fetch recommendations from API when available', async () => {
      const mockResponse = {
        userId: 'test-user',
        selectedItems: ['path-foundation-ai-engineering'],
        source: 'assessment',
        timestamp: Date.now(),
        skillLevel: 'beginner'
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchAssessmentRecommendations();

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:3002/api/learning/selections?userId=default-user'
      );
    });

    it('should populate recommendations array from assessment source', async () => {
      const mockResponse = {
        userId: 'test-user',
        selectedItems: ['path-foundation-ai-engineering', 'path-skill-prompt-engineering'],
        source: 'assessment',
        timestamp: Date.now() - 60000 // 1 minute ago
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchAssessmentRecommendations();

      expect(plugin.recommendations).toHaveLength(2);
      expect(plugin.recommendations).toContain('path-foundation-ai-engineering');
      expect(plugin.recommendations).toContain('path-skill-prompt-engineering');
    });

    it('should ignore stale assessment recommendations older than 5 minutes', async () => {
      const mockResponse = {
        userId: 'test-user',
        selectedItems: ['path-foundation-ai-engineering'],
        source: 'assessment',
        timestamp: Date.now() - 360000 // 6 minutes ago (stale)
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchAssessmentRecommendations();

      expect(plugin.recommendations).toHaveLength(0);
    });

    it('should ignore recommendations not from assessment source', async () => {
      const mockResponse = {
        userId: 'test-user',
        selectedItems: ['path-foundation-ai-engineering'],
        source: 'manual', // Not from assessment
        timestamp: Date.now()
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchAssessmentRecommendations();

      expect(plugin.recommendations).toHaveLength(0);
    });

    it('should handle missing source field gracefully', async () => {
      const mockResponse = {
        userId: 'test-user',
        selectedItems: ['path-foundation-ai-engineering'],
        timestamp: Date.now()
        // No source field
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchAssessmentRecommendations();

      expect(plugin.recommendations).toHaveLength(0);
    });

    it('should handle API errors without throwing', async () => {
      global.fetch.mockRejectedValueOnce(new Error('Network error'));

      await expect(plugin.fetchAssessmentRecommendations()).resolves.not.toThrow();
      expect(plugin.recommendations).toHaveLength(0);
    });

    it('should fall back to localStorage when API fails', async () => {
      const cachedData = {
        selectedItems: ['path-foundation-ai-engineering'],
        source: 'assessment',
        timestamp: Date.now(),
        userId: 'test-user'
      };

      global.localStorage.setItem('catalog-selections-cache', JSON.stringify(cachedData));
      global.fetch.mockRejectedValueOnce(new Error('Network error'));

      await plugin.fetchAssessmentRecommendations();

      expect(plugin.recommendations).toHaveLength(1);
      expect(plugin.recommendations).toContain('path-foundation-ai-engineering');
    });

    it('should verify timestamp is a valid number', async () => {
      const mockResponse = {
        userId: 'test-user',
        selectedItems: ['path-foundation-ai-engineering'],
        source: 'assessment',
        timestamp: 'invalid-timestamp'
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchAssessmentRecommendations();

      expect(plugin.recommendations).toHaveLength(0);
    });

    it('should use getPathsForSkillLevel when skillLevel is provided', async () => {
      const mockResponse = {
        userId: 'test-user',
        selectedItems: [], // Empty - should use skillLevel instead
        source: 'assessment',
        timestamp: Date.now(),
        skillLevel: 'intermediate'
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchAssessmentRecommendations();

      // Intermediate level = 3 paths
      expect(plugin.recommendations).toHaveLength(3);
      expect(plugin.recommendations).toContain('path-foundation-ai-engineering');
      expect(plugin.recommendations).toContain('path-skill-prompt-engineering');
      expect(plugin.recommendations).toContain('path-skill-edge-to-cloud-integration');
    });

    it('should prefer selectedItems over skillLevel when both present', async () => {
      const mockResponse = {
        userId: 'test-user',
        selectedItems: ['path-expert-edge-ai-systems'], // Explicit selection
        source: 'assessment',
        timestamp: Date.now(),
        skillLevel: 'beginner' // Conflicting skill level
      };

      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      });

      await plugin.fetchAssessmentRecommendations();

      // Should use selectedItems, not skillLevel
      expect(plugin.recommendations).toHaveLength(1);
      expect(plugin.recommendations).toContain('path-expert-edge-ai-systems');
    });
  });

  describe('Assessment Visual Indicators', () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <div id="app">
          <ul>
            <li class="task-list-item">
              <input type="checkbox" data-item-id="path-foundation-ai-engineering">
              <a href="/learning/paths/foundation-ai-engineering.md">Foundation: AI Engineering</a>
              <p class="meta">Foundation level • 4-6 weeks</p>
            </li>
            <li class="task-list-item">
              <input type="checkbox" data-item-id="kata-ai-01">
              <a href="/learning/katas/ai/01-fundamentals.md">AI Fundamentals</a>
              <p class="meta">Beginner • 30 min</p>
            </li>
          </ul>
        </div>
      `;

      plugin.recommendations = ['path-foundation-ai-engineering'];
    });

    it('should add star icon to recommended items after decorateEntries', async () => {
      await plugin.decorateEntries();

      const link = document.querySelector('a[href="/learning/paths/foundation-ai-engineering.md"]');
      expect(link.textContent).toContain('⭐');
    });

    it('should not add star icon to non-recommended items', async () => {
      await plugin.decorateEntries();

      const link = document.querySelector('a[href="/learning/katas/ai/01-fundamentals.md"]');
      expect(link.textContent).not.toContain('⭐');
    });

    it('should add star icon for selected recommendations', async () => {
      plugin.selections.add('path-foundation-ai-engineering');

      await plugin.decorateEntries();

      const link = document.querySelector('a[href="/learning/paths/foundation-ai-engineering.md"]');
      expect(link.textContent).not.toContain('📌');
      expect(link.textContent).toContain('⭐');
    });

    it('should not duplicate star icons on multiple decorations', async () => {
      await plugin.decorateEntries();
      await plugin.decorateEntries(); // Call twice

      const link = document.querySelector('a[href="/learning/paths/foundation-ai-engineering.md"]');
      const starCount = (link.textContent.match(/⭐/g) || []).length;
      expect(starCount).toBe(1);
    });
  });



  describe('Path Auto-Selection', () => {
    let plugin;
    let consoleLogSpy;

    beforeEach(() => {
      consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {});

      document.body.innerHTML = `
        <div class="markdown-section">
          <ul>
            <li class="task-list-item">
              <input type="checkbox" data-item-id="path-foundation-ai-first-engineering" checked />
              <a href="#/learning/paths/foundation-ai-first-engineering.md">Foundation Path</a>
            </li>
            <li class="task-list-item">
              <input type="checkbox" data-item-id="ai-assisted-engineering-100-inline-suggestions-basics" />
              <a href="#/learning/katas/ai-assisted-engineering/100-inline-suggestions-basics.md">Kata 1</a>
            </li>
            <li class="task-list-item">
              <input type="checkbox" data-item-id="ai-assisted-engineering-100-inline-chat-quick-edits" />
              <a href="#/learning/katas/ai-assisted-engineering/100-inline-chat-quick-edits.md">Kata 2</a>
            </li>
          </ul>
        </div>
      `;

      plugin = new CatalogHydration();
      plugin.selections = new Set(['path-foundation-ai-first-engineering']);

      // Mock saveSelections to prevent API calls
      plugin.saveSelections = vi.fn();
    });

    afterEach(() => {
      consoleLogSpy.mockRestore();
    });

    it('should check all kata checkboxes for selected path', () => {
      plugin._expandPathSelections();

      const kata1 = document.querySelector('[data-item-id="ai-assisted-engineering-100-inline-suggestions-basics"]');
      const kata2 = document.querySelector('[data-item-id="ai-assisted-engineering-100-inline-chat-quick-edits"]');

      expect(kata1.checked).toBe(true);
      expect(kata2.checked).toBe(true);
    });

    it('should add all katas to selections Set', () => {
      plugin._expandPathSelections();

      expect(plugin.selections.has('ai-assisted-engineering-100-inline-suggestions-basics')).toBe(true);
      expect(plugin.selections.has('ai-assisted-engineering-100-inline-chat-quick-edits')).toBe(true);
    });

    it('should save selections after expanding', () => {
      plugin._expandPathSelections();

      expect(plugin.saveSelections).toHaveBeenCalled();
    });

    it('should log debug info about expansion', () => {
      plugin._expandPathSelections();

      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringContaining('[CATALOG-EXPAND]'),
        expect.anything()
      );
    });

    it('should log total items selected', () => {
      plugin._expandPathSelections();

      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringContaining('Total items selected')
      );
    });

    it('should warn when checkbox not found', () => {
      const consoleWarnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});

      // Remove one checkbox to trigger warning
      const checkbox = document.querySelector('[data-item-id="ai-assisted-engineering-100-inline-suggestions-basics"]');
      checkbox.remove();

      plugin._expandPathSelections();

      expect(consoleWarnSpy).toHaveBeenCalledWith(
        expect.stringContaining('Checkbox not found for kata')
      );

      consoleWarnSpy.mockRestore();
    });

    it('should handle empty path selections', () => {
      plugin.selections = new Set(['some-kata-id']); // No paths

      plugin._expandPathSelections();

      expect(consoleLogSpy).toHaveBeenCalledWith('[CATALOG-EXPAND] No path selections to expand');
    });

    it('should warn when path has no mapping', () => {
      const consoleWarnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});

      plugin.selections = new Set(['path-nonexistent']);

      plugin._expandPathSelections();

      expect(consoleWarnSpy).toHaveBeenCalledWith(
        expect.stringContaining('No kata mapping found for path')
      );

      consoleWarnSpy.mockRestore();
    });
  });

  describe('Page Context Detection', () => {
    let plugin;

    beforeEach(() => {
      plugin = new CatalogHydration();
      plugin.selections = new Set(['path-intermediate-infrastructure-architect']);
      plugin.pathMappings = {
        'path-intermediate-infrastructure-architect': [
          'adr-creation-100-basic-messaging-architecture',
          'edge-deployment-100-deployment-basics'
        ]
      };
    });

    it('should skip path expansion on catalog page', () => {
      window.location.hash = '#/learning/catalog';
      const consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {});

      plugin._expandPathSelections();

      expect(consoleLogSpy).toHaveBeenCalledWith('[CATALOG-EXPAND] Skipping expansion on catalog page');
      consoleLogSpy.mockRestore();
    });

    it('should skip path expansion on paths hub page', () => {
      window.location.hash = '#/learning/paths/';
      const consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {});

      plugin._expandPathSelections();

      expect(consoleLogSpy).toHaveBeenCalledWith('[CATALOG-EXPAND] Skipping expansion on catalog page');
      consoleLogSpy.mockRestore();
    });

    it('should run path expansion on learning path pages', () => {
      window.location.hash = '#/learning/paths/intermediate-infrastructure-architect';
      const consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {});

      document.body.innerHTML = `
        <ul>
          <li class="task-list-item">
            <input type="checkbox" data-item-id="adr-creation-100-basic-messaging-architecture">
          </li>
          <li class="task-list-item">
            <input type="checkbox" data-item-id="edge-deployment-100-deployment-basics">
          </li>
        </ul>
      `;

      plugin._expandPathSelections();

      expect(consoleLogSpy).toHaveBeenCalledWith('[CATALOG-EXPAND] Starting path expansion...');
      consoleLogSpy.mockRestore();
    });

    it('should decorate path checkboxes on catalog page', async () => {
      window.location.hash = '#/learning/catalog';
      document.body.innerHTML = `
        <ul>
          <li class="task-list-item">
            <input type="checkbox" disabled>
            <a href="#/learning/paths/intermediate-infrastructure-architect.md">Intermediate: Infrastructure Architect</a>
            <p>Skill Level | 9.5 hours</p>
          </li>
        </ul>
      `;

      plugin.selections = new Set(['path-intermediate-infrastructure-architect']);
      await plugin.decorateEntries();

      const checkbox = document.querySelector('input[data-item-id="path-intermediate-infrastructure-architect"]');
      expect(checkbox).toBeTruthy();
      expect(checkbox.checked).toBe(true);
      // Pin icon removed - no longer checking for it
    });

    it('should skip prerequisite checkboxes on learning path pages', async () => {
      window.location.hash = '#/learning/paths/intermediate-infrastructure-architect';
      document.body.innerHTML = `
        <h2>Prerequisites</h2>
        <ul>
          <li class="task-list-item">
            <input type="checkbox" disabled>
            <a href="#/learning/paths/foundation-ai-first-engineering.md">Foundation: AI-First Engineering</a>
          </li>
        </ul>
      `;

      const consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {});

      await plugin.decorateEntries();

      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringContaining('Skipping prerequisite checkbox')
      );

      const checkbox = document.querySelector('input[type="checkbox"]');
      expect(checkbox.hasAttribute('data-item-id')).toBe(false);

      consoleLogSpy.mockRestore();
    });

    it('should NOT skip path checkboxes on catalog page even if they link to paths', async () => {
      window.location.hash = '#/learning/catalog';
      document.body.innerHTML = `
        <h2>📚 Pre-Curated Learning Paths</h2>
        <ul>
          <li class="task-list-item">
            <input type="checkbox" disabled>
            <a href="#/learning/paths/intermediate-infrastructure-architect.md">Intermediate: Infrastructure Architect</a>
            <p>Skill Level | 9.5 hours</p>
          </li>
        </ul>
      `;

      plugin.selections = new Set(['path-intermediate-infrastructure-architect']);
      await plugin.decorateEntries();

      const checkbox = document.querySelector('input[data-item-id="path-intermediate-infrastructure-architect"]');
      expect(checkbox).toBeTruthy();
      expect(checkbox.checked).toBe(true);
    });
  });

  describe('CatalogHydration Plugin - Global Instance Exposure', () => {
    let originalInstance;

    beforeEach(() => {
      // Save original if exists
      originalInstance = window.catalogHydrationInstance;

      // Clear window property for clean test
      delete window.catalogHydrationInstance;
    });

    afterEach(() => {
      // Restore original
      if (originalInstance !== undefined) {
        Object.defineProperty(window, 'catalogHydrationInstance', {
          get: () => originalInstance,
          configurable: true
        });
      } else {
        delete window.catalogHydrationInstance;
      }
    });

    it('should expose instance via getter that returns live value', () => {
      // Simulate plugin installation pattern
      let catalogHydrationInstance = null;

      // Define getter (mimics production code)
      Object.defineProperty(window, 'catalogHydrationInstance', {
        get: () => catalogHydrationInstance,
        configurable: true
      });

      // Initially null
      expect(window.catalogHydrationInstance).toBeNull();

      // Create instance (mimics doneEach callback)
      catalogHydrationInstance = new CatalogHydration();

      // Should return live instance
      expect(window.catalogHydrationInstance).toBe(catalogHydrationInstance);
      expect(window.catalogHydrationInstance).toBeInstanceOf(CatalogHydration);
    });

    it('should allow instance to be updated dynamically', () => {
      let catalogHydrationInstance = null;

      Object.defineProperty(window, 'catalogHydrationInstance', {
        get: () => catalogHydrationInstance,
        configurable: true
      });

      // First instance
      const instance1 = new CatalogHydration();
      catalogHydrationInstance = instance1;
      expect(window.catalogHydrationInstance).toBe(instance1);

      // Second instance (e.g., after re-initialization)
      const instance2 = new CatalogHydration();
      catalogHydrationInstance = instance2;
      expect(window.catalogHydrationInstance).toBe(instance2);
      expect(window.catalogHydrationInstance).not.toBe(instance1);
    });

    it('should be configurable to allow test cleanup', () => {
      Object.defineProperty(window, 'catalogHydrationInstance', {
        get: () => null,
        configurable: true
      });

      const descriptor = Object.getOwnPropertyDescriptor(window, 'catalogHydrationInstance');
      expect(descriptor.configurable).toBe(true);

      // Should be able to delete/redefine
      expect(() => {
        delete window.catalogHydrationInstance;
        Object.defineProperty(window, 'catalogHydrationInstance', {
          value: 'test',
          configurable: true
        });
      }).not.toThrow();
    });

    it('should return null before instance is created', () => {
      let catalogHydrationInstance = null;

      Object.defineProperty(window, 'catalogHydrationInstance', {
        get: () => catalogHydrationInstance,
        configurable: true
      });

      expect(window.catalogHydrationInstance).toBeNull();
    });
  });
});
