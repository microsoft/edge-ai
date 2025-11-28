/**
 * Tests for Custom Breadcrumb Plugin
 * Using Happy DOM test environment
 */

import { describe, test, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { testPresets } from '../helpers/focused/preset-compositions.js';
import '../../plugins/custom-breadcrumb-plugin.js';

describe('Custom Breadcrumb Plugin', () => {
  let _testContext;
  let mockConsole;
  let mockWindow;

  beforeEach(() => {
    // Set up test context with fresh DOM environment
    _testContext = testPresets.docsifyPlugin();
    mockWindow = window;

    // Set up global window properties needed by the plugin
    mockWindow.location = mockWindow.location || {};
    mockWindow.location.hash = '#/';

    // Mock addEventListener/removeEventListener
    mockWindow.addEventListener = vi.fn();
    mockWindow.removeEventListener = vi.fn();

    // Mock console methods to avoid test output pollution
    mockConsole = {
      log: vi.fn(),
      warn: vi.fn(),
      error: vi.fn()
    };
    vi.stubGlobal('console', mockConsole);

    // Mock Docsify
    mockWindow.$docsify = mockWindow.$docsify || { plugins: [] };

    // Reset plugin configuration to defaults
    if (globalThis.window.CustomBreadcrumbPlugin) {
      globalThis.window.CustomBreadcrumbPlugin.init();
    }
  });

  afterEach(() => {
    // Clean up event listeners and mocks
    vi.restoreAllMocks();

    // Clean up any active timers to prevent test environment issues
    if (globalThis.window && globalThis.window.CustomBreadcrumbPlugin && globalThis.window.CustomBreadcrumbPlugin.cleanup) {
      globalThis.window.CustomBreadcrumbPlugin.cleanup();
    }
  });

  describe('Plugin Registration', () => {
    it('should register the CustomBreadcrumbPlugin class globally', () => {
      expect(mockWindow.CustomBreadcrumbPlugin).toBeDefined();
      expect(typeof mockWindow.CustomBreadcrumbPlugin).toBe('object');
    });

    it('should register the customBreadcrumbPlugin function globally', () => {
      expect(mockWindow.customBreadcrumbPlugin).toBeDefined();
      expect(typeof mockWindow.customBreadcrumbPlugin).toBe('function');
    });

    it('should register the customBreadcrumbPluginInstance object globally', () => {
      expect(mockWindow.customBreadcrumbPluginInstance).toBeDefined();
      expect(typeof mockWindow.customBreadcrumbPluginInstance).toBe('object');
    });
  });

  describe('Plugin Functionality', () => {
    it('should initialize the plugin', () => {
      expect(() => {
        mockWindow.CustomBreadcrumbPlugin.init();
      }).not.toThrow();
    });

    it('should handle page changes', () => {
      expect(() => {
        mockWindow.CustomBreadcrumbPlugin.handlePageChange();
      }).not.toThrow();
    });

    it('should update breadcrumbs', () => {
      const mockRoute = { path: '/test' };
      expect(() => {
        mockWindow.CustomBreadcrumbPlugin.updateBreadcrumb(mockRoute);
      }).not.toThrow();
    });

    it('should cleanup correctly', () => {
      expect(() => {
        mockWindow.CustomBreadcrumbPlugin.cleanup();
      }).not.toThrow();
    });

    it('should provide state access', () => {
      const state = mockWindow.CustomBreadcrumbPlugin.getState();
      expect(state).toBeDefined();
      expect(typeof state).toBe('object');
    });

    it('should generate breadcrumb HTML', async () => {
      const route = { path: '/test' };
      const html = await mockWindow.customBreadcrumbPluginInstance.generateBreadcrumbHTML(route);
      expect(typeof html).toBe('string');
    });
  });

  describe('Breadcrumb Creation', () => {
    it('should generate HTML for simple route', async () => {
      const route = { path: '/docs' };
      const html = await mockWindow.customBreadcrumbPluginInstance.generateBreadcrumbHTML(route);

      expect(html).toContain('breadcrumb');
      expect(typeof html).toBe('string');
    });

    it('should handle configuration', () => {
      const config = mockWindow.customBreadcrumbPluginInstance.getConfig();
      expect(config).toBeDefined();
      expect(typeof config).toBe('object');
    });
  });

  describe('Integration with Docsify', () => {
    it('should integrate with Docsify configuration', () => {
      expect(mockWindow.$docsify).toBeDefined();
      expect(mockWindow.$docsify.plugins).toBeDefined();
    });

    it('should handle plugin hooks', () => {
      expect(() => {
        // Simulate calling plugin hooks
        mockWindow.customBreadcrumbPlugin({}, {});
      }).not.toThrow();
    });
  });

  describe('Plugin Registration', () => {
    test('should register plugin functions globally', () => {
      expect(globalThis.window.customBreadcrumbPlugin).toBeDefined();
      expect(globalThis.window.CustomBreadcrumbPlugin).toBeDefined();
      expect(globalThis.window.customBreadcrumbPluginInstance).toBeDefined();
    });

    test('should register with Docsify plugins array when docsify is available', () => {
      // Create $docsify mock if it doesn't exist
      if (!globalThis.window.$docsify) {
        globalThis.window.$docsify = { plugins: [] };
      }

      // Since plugin auto-registers during import, check if the function can be added
      expect(typeof globalThis.window.customBreadcrumbPlugin).toBe('function');

      // Manual registration test
      globalThis.window.$docsify.plugins.push(globalThis.window.customBreadcrumbPlugin);
      expect(globalThis.window.$docsify.plugins).toContain(globalThis.window.customBreadcrumbPlugin);
    });

    test('should rely on Docsify hooks for navigation updates', () => {
      // Verify that the plugin exposes the required functions for Docsify integration
      expect(typeof globalThis.window.CustomBreadcrumbPlugin.updateBreadcrumb).toBe('function');
      expect(typeof globalThis.window.CustomBreadcrumbPlugin.handlePageChange).toBe('function');

      // Verify that manual hashchange events don't trigger immediate updates
      const updateSpy = vi.spyOn(globalThis.window.CustomBreadcrumbPlugin, 'updateBreadcrumb');

      // Simulate hashchange
      globalThis.window.location.hash = '#/test';
      globalThis.window.dispatchEvent(new Event('hashchange'));

      // Breadcrumb should NOT update automatically (only via Docsify hooks)
      expect(updateSpy).not.toHaveBeenCalled();

      updateSpy.mockRestore();
    });
  });

  describe('Initialization', () => {
    test('should initialize with default configuration', () => {
      const config = globalThis.window.customBreadcrumbPluginInstance.getConfig();

      expect(config.showHome).toBe(true);
      expect(config.homeText).toBe('Home');
      expect(config.separator).toBe(' › ');
      expect(config.casing).toBe('capitalize');
    });

    test('should merge user configuration with defaults', () => {
      const customConfig = {
        showHome: false,
        homeText: 'Start',
        separator: ' / ',
        casing: 'uppercase'
      };

      globalThis.window.CustomBreadcrumbPlugin.init(customConfig);
      const config = globalThis.window.customBreadcrumbPluginInstance.getConfig();

      expect(config.showHome).toBe(false);
      expect(config.homeText).toBe('Start');
      expect(config.separator).toBe(' / ');
      expect(config.casing).toBe('uppercase');

      // Reset to defaults after testing custom config
      globalThis.window.CustomBreadcrumbPlugin.init({}, true);
    });
  });

  describe('Breadcrumb Generation', () => {
    test('should generate semantic HTML breadcrumb for home route', async () => {
      const route = { path: '/' };
      const html = await globalThis.window.customBreadcrumbPluginInstance.generateBreadcrumbHTML(route);

      expect(html).toContain('<nav class="breadcrumb-container" aria-label="Breadcrumb">');
      expect(html).toContain('<ol class="breadcrumb">');
      expect(html).toContain('<li class="breadcrumb-item">');
      expect(html).toContain('<span class="active" aria-current="page">Home</span>');
      expect(html).toContain('</ol>');
      expect(html).toContain('</nav>');
    });

    test('should generate semantic breadcrumb for nested route', async () => {
      // Reset to default configuration
      globalThis.window.CustomBreadcrumbPlugin.init({}, true);

      const route = { path: '/docs/getting-started' };
      const html = await globalThis.window.customBreadcrumbPluginInstance.generateBreadcrumbHTML(route);

      expect(html).toContain('<nav class="breadcrumb-container" aria-label="Breadcrumb">');
      expect(html).toContain('<ol class="breadcrumb">');
      expect(html).toContain('<li class="breadcrumb-item"><a href="#/">Home</a></li>');
      expect(html).toContain('<li class="breadcrumb-item"><a href="#/docs/">Documentation</a></li>');
      expect(html).toContain('<li class="breadcrumb-item"><span class="active" aria-current="page">Getting Started</span></li>');

      // Should NOT contain any inline styles or separator spans
      expect(html).not.toContain('style=');
      expect(html).not.toContain('<span class="breadcrumb-separator">');
    });

    test('should not contain any inline styles', async () => {
      const route = { path: '/docs/getting-started/installation' };
      const html = await globalThis.window.customBreadcrumbPluginInstance.generateBreadcrumbHTML(route);

      // Verify no inline styles are present
      expect(html).not.toContain('style=');
      expect(html).not.toContain('margin:');
      expect(html).not.toContain('color:');
      expect(html).not.toContain('rgba(');
    });

    test('should generate proper CSS classes for styling', async () => {
      const route = { path: '/docs/advanced/configuration' };
      const html = await globalThis.window.customBreadcrumbPluginInstance.generateBreadcrumbHTML(route);

      // Check for proper CSS class structure
      expect(html).toContain('class="breadcrumb-container"');
      expect(html).toContain('class="breadcrumb"');
      expect(html).toContain('class="breadcrumb-item"');
      expect(html).toContain('class="active"');

      // Count breadcrumb items (Home + Docs + Advanced + Configuration)
      const itemCount = (html.match(/class="breadcrumb-item"/g) || []).length;
      expect(itemCount).toBe(4);
    });

    test('should handle empty or invalid routes', async () => {
      expect(await globalThis.window.customBreadcrumbPluginInstance.generateBreadcrumbHTML(null)).toBe('');
      expect(await globalThis.window.customBreadcrumbPluginInstance.generateBreadcrumbHTML({})).toBe('');
      expect(await globalThis.window.customBreadcrumbPluginInstance.generateBreadcrumbHTML({ path: '' })).toBe('');
    });

    test('should apply different casing styles', async () => {
      // Test uppercase casing
      globalThis.window.CustomBreadcrumbPlugin.init({ casing: 'uppercase' });
      const route = { path: '/docs/getting-started' };
      let html = await globalThis.window.customBreadcrumbPluginInstance.generateBreadcrumbHTML(route);
      expect(html).toContain('DOCUMENTATION'); // "docs" becomes "Documentation" then uppercase
      expect(html).toContain('GETTING STARTED');

      // Test lowercase casing
      globalThis.window.CustomBreadcrumbPlugin.init({ casing: 'lowercase' });
      html = await globalThis.window.customBreadcrumbPluginInstance.generateBreadcrumbHTML(route);
      expect(html).toContain('documentation'); // "docs" becomes "Documentation" then lowercase
      expect(html).toContain('getting started');

      // Reset to default configuration
      globalThis.window.CustomBreadcrumbPlugin.init();
    });

    test('should filter out technical artifacts', async () => {
      // Reset to default configuration
      globalThis.window.CustomBreadcrumbPlugin.init({}, true);

      const route = { path: '/src/readme/index' };
      const html = await globalThis.window.customBreadcrumbPluginInstance.generateBreadcrumbHTML(route);

      expect(html).toContain('Source'); // "src" becomes "Source" in special cases
      expect(html).not.toContain('readme');
      expect(html).not.toContain('index');
    });

    test('should generate proper accessibility attributes', async () => {
      const route = { path: '/docs/guide' };
      const html = await globalThis.window.customBreadcrumbPluginInstance.generateBreadcrumbHTML(route);

      // Check for ARIA attributes
      expect(html).toContain('aria-label="Breadcrumb"');
      expect(html).toContain('aria-current="page"');

      // Only the active/current item should have aria-current
      const ariaCurrent = (html.match(/aria-current="page"/g) || []).length;
      expect(ariaCurrent).toBe(1);
    });

    test('should generate clean breadcrumb paths without README suffix', async () => {
      const route = { path: '/docs/build-cicd/azure-pipelines' };
      const html = await globalThis.window.customBreadcrumbPluginInstance.generateBreadcrumbHTML(route);

      expect(html).toContain('<li class="breadcrumb-item"><a href="#/docs/">Documentation</a></li>');
      expect(html).toContain('<li class="breadcrumb-item"><a href="#/docs/build-cicd/">Build Cicd</a></li>');
      expect(html).toContain('<li class="breadcrumb-item"><span class="active" aria-current="page">Azure Pipelines</span></li>');
    });

    test('should handle anchor fragments in route paths correctly', async () => {
      // Test route processing with anchor fragments
      globalThis.window.location.hash = '#/docs/guide?id=getting-started';
      globalThis.document.body.innerHTML = '<div class="markdown-section"></div>';

      const updateSpy = vi.spyOn(globalThis.window.CustomBreadcrumbPlugin, 'updateBreadcrumb');

      globalThis.window.CustomBreadcrumbPlugin.handlePageChange();

      // Should be called with path without anchor fragment
      expect(updateSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          path: '/docs/guide'
        })
      );

      updateSpy.mockRestore();
    });

    test('should strip various anchor fragment formats', async () => {
      // Test different anchor formats
      const testCases = [
        { hash: '#/docs/guide?id=section', expectedPath: '/docs/guide' },
        { hash: '#/docs/guide#anchor', expectedPath: '/docs/guide' },
        { hash: '#/docs/guide?id=section&param=value', expectedPath: '/docs/guide' },
        { hash: '#/docs/guide', expectedPath: '/docs/guide' }
      ];

      const updateSpy = vi.spyOn(globalThis.window.CustomBreadcrumbPlugin, 'updateBreadcrumb');

      for (const testCase of testCases) {
        globalThis.window.location.hash = testCase.hash;
        updateSpy.mockClear();

        globalThis.window.CustomBreadcrumbPlugin.handlePageChange();

        expect(updateSpy).toHaveBeenCalledWith(
          expect.objectContaining({
            path: testCase.expectedPath
          })
        );
      }

      updateSpy.mockRestore();
    });
  });

  describe('DOM Integration', () => {
    test('should insert breadcrumb into markdown section', async () => {
      // Set up DOM with markdown section
      globalThis.document.body.innerHTML = `
        <div class="markdown-section">
          <h1>Page Title</h1>
          <p>Content</p>
        </div>
      `;

      const route = { path: '/docs/guide' };
      await globalThis.window.CustomBreadcrumbPlugin.updateBreadcrumb(route);

      const breadcrumb = globalThis.document.querySelector('.breadcrumb-container');
      expect(breadcrumb).toBeDefined();

      const markdownSection = globalThis.document.querySelector('.markdown-section');
      expect(markdownSection.firstElementChild).toBe(breadcrumb);
    });

    test('should remove existing breadcrumbs before inserting new ones', async () => {
      // Set up DOM with existing breadcrumb
      globalThis.document.body.innerHTML = `
        <div class="markdown-section">
          <nav class="breadcrumb-container">Old breadcrumb</nav>
          <h1>Page Title</h1>
        </div>
      `;

      const route = { path: '/docs/guide' };
      await globalThis.window.CustomBreadcrumbPlugin.updateBreadcrumb(route);

      const breadcrumbs = globalThis.document.querySelectorAll('.breadcrumb-container');
      expect(breadcrumbs).toHaveLength(1);
      expect(breadcrumbs[0].textContent).not.toContain('Old breadcrumb');
    });

    test('should prefer frontmatter display area for insertion', async () => {
      // Set up DOM with both frontmatter and markdown sections
      globalThis.document.body.innerHTML = `
        <div class="frontmatter-display"></div>
        <div class="markdown-section">
          <h1>Page Title</h1>
        </div>
      `;

      const route = { path: '/docs/guide' };
      await globalThis.window.CustomBreadcrumbPlugin.updateBreadcrumb(route);

      const frontmatterDisplay = globalThis.document.querySelector('.frontmatter-display');
      const breadcrumb = globalThis.document.querySelector('.breadcrumb-container');

      expect(breadcrumb).toBeDefined();
      expect(frontmatterDisplay.firstElementChild).toBe(breadcrumb);
    });
  });

  describe('Page Change Handling', () => {
    test('should handle page change with hash route', () => {
      globalThis.window.location.hash = '#/docs/guide';
      globalThis.document.body.innerHTML = '<div class="markdown-section"></div>';

      // Mock the updateBreadcrumb method to verify it gets called
      const updateSpy = vi.spyOn(globalThis.window.CustomBreadcrumbPlugin, 'updateBreadcrumb');

      globalThis.window.CustomBreadcrumbPlugin.handlePageChange();

      expect(updateSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          path: '/docs/guide'
        })
      );

      updateSpy.mockRestore();
    });

    test('should handle page change with empty hash', () => {
      globalThis.window.location.hash = '';
      globalThis.document.body.innerHTML = '<div class="markdown-section"></div>';

      const updateSpy = vi.spyOn(globalThis.window.CustomBreadcrumbPlugin, 'updateBreadcrumb');

      globalThis.window.CustomBreadcrumbPlugin.handlePageChange();

      expect(updateSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          path: '/'
        })
      );

      updateSpy.mockRestore();
    });
  });

  describe('Cleanup', () => {
    test('should remove breadcrumbs from DOM', () => {
      // Set up DOM with breadcrumbs
      globalThis.document.body.innerHTML = `
        <nav class="breadcrumb-container">Breadcrumb 1</nav>
        <nav class="breadcrumb-container">Breadcrumb 2</nav>
        <div class="content">Content</div>
      `;

      globalThis.window.CustomBreadcrumbPlugin.cleanup();

      const breadcrumbs = globalThis.document.querySelectorAll('.breadcrumb-container');
      expect(breadcrumbs).toHaveLength(0);
    });

    test('should clear all active timers', () => {
      // Create some breadcrumbs with timers (indirectly)
      globalThis.document.body.innerHTML = `
        <nav class="breadcrumb-container">Test</nav>
      `;

      // Get state before cleanup
      const stateBefore = globalThis.window.CustomBreadcrumbPlugin.getState();

      // Execute cleanup
      globalThis.window.CustomBreadcrumbPlugin.cleanup();

      // Verify breadcrumb removed
      expect(globalThis.document.querySelector('.breadcrumb-container')).toBeNull();

      // Verify timers cleared
      const stateAfter = globalThis.window.CustomBreadcrumbPlugin.getState();
      expect(stateAfter.activeTimers.size).toBe(0);
    });

    test('should not throw errors when DOM is not available', () => {
      // Temporarily remove document to simulate cleanup without DOM
      const originalDocument = globalThis.document;
      delete globalThis.document;

      expect(() => {
        globalThis.window.CustomBreadcrumbPlugin.cleanup();
      }).not.toThrow();

      // Restore document
      globalThis.document = originalDocument;
    });
  });

  describe('Docsify Integration', () => {
    test('should handle docsify hook integration', () => {
      const mockHook = {
        init: vi.fn(),
        doneEach: vi.fn(),
        ready: vi.fn()
      };

      const mockVm = {
        route: { path: '/test' }
      };

      // Call the plugin function
      globalThis.window.customBreadcrumbPlugin(mockHook, mockVm);

      // Verify hooks were registered
      expect(mockHook.init).toHaveBeenCalled();
      expect(mockHook.doneEach).toHaveBeenCalled();
      expect(mockHook.ready).toHaveBeenCalled();
    });

    test('should update breadcrumb on docsify route change', () => {
      const updateSpy = vi.spyOn(globalThis.window.CustomBreadcrumbPlugin, 'updateBreadcrumb');

      const mockHook = {
        init: vi.fn((callback) => callback()),
        doneEach: vi.fn((callback) => callback()),
        ready: vi.fn((callback) => callback())
      };

      const mockVm = {
        route: { path: '/docs/guide' }
      };

      globalThis.window.customBreadcrumbPlugin(mockHook, mockVm);

      expect(updateSpy).toHaveBeenCalledWith(mockVm.route);

      updateSpy.mockRestore();
    });
  });

  describe('Error Handling', () => {
    test('should handle errors during breadcrumb generation gracefully', async () => {
      // Create a route that might cause issues
      const problematicRoute = { path: null };

      const html = await globalThis.window.customBreadcrumbPluginInstance.generateBreadcrumbHTML(problematicRoute);
      expect(html).toBe('');

      // Should not have thrown any errors
    });

    test('should handle DOM insertion errors gracefully', async () => {
      // Remove document to simulate DOM access issues
      const originalDocument = globalThis.document;
      delete globalThis.document;

      const route = { path: '/docs/guide' };

      // Should not throw
      await expect(globalThis.window.CustomBreadcrumbPlugin.updateBreadcrumb(route)).resolves.toBeUndefined();

      // Restore document
      globalThis.document = originalDocument;
    });
  });
});
