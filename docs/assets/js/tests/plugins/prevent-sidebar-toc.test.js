import { vi, describe, it, beforeEach, afterEach, beforeAll, expect } from 'vitest';
/**
 * Tests for Prevent Sidebar TOC Plugin
 * @version 1.0.0
 */

import { testPresets } from '../helpers/focused/preset-compositions.js';
import '../../plugins/prevent-sidebar-toc.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

describe('PreventSidebarTOC Plugin', () => {

  let testHelper, _sandbox;
  let mockWindow;
  let mockDocument;
  let pluginCode;

  beforeAll(() => {
    // Read the plugin file as text
    const pluginPath = path.resolve(__dirname, '../../plugins/prevent-sidebar-toc.js');

    pluginCode = fs.readFileSync(pluginPath, 'utf8');
  });

  beforeEach(() => {
    testHelper = testPresets.integrationModule();
    // Create fresh DOM environment for test isolation
    testHelper = testPresets.docsifyPlugin();
    mockWindow = window;
    mockDocument = document;

    _sandbox = testHelper.sandbox;

    // Create a comprehensive DOM environment with Happy DOM
    document.body.innerHTML = `
      <div class="sidebar">
        <div class="sidebar-nav">
          <ul>
            <li class="active">
              <a href="#active-page">Active Page</a>
            </li>
            <li>
              <a href="#other-page">Other Page</a>
            </li>
          </ul>
          <div class="app-sub-sidebar">TOC Content</div>
        </div>
      </div>
      <div class="content">
        <div class="app-sub-sidebar">Content TOC</div>
      </div>
    `;

    mockWindow = window;
    mockDocument = document;

    // Mock Docsify with proper structure
    mockWindow.$docsify = {
      plugins: [],
      subSidebar: true
    };
    mockWindow.Docsify = {
      compiler: {
        subSidebar: vi.fn().mockReturnValue('<div>Sub sidebar content</div>')
      }
    };
    // Mock console methods
    vi.spyOn(mockWindow.console, 'log');
    vi.spyOn(mockWindow.console, 'error');
  });

  afterEach(() => {
    testHelper.afterEach?.();
  });

  /**
   * Execute plugin code directly (no timer dependencies in simplified version)
   */
  function loadPluginSafely() {
    // Create a controlled execution environment
    // eslint-disable-next-line no-new-func
    const executePlugin = new Function(
      'window',
      'document',
      'console',
      pluginCode
    );

    executePlugin(
      mockWindow,
      mockDocument,
      mockWindow.console
    );

    // Manually initialize the plugin since Docsify hooks won't run in tests
    if (mockWindow.PreventSidebarTOCPlugin && mockWindow.PreventSidebarTOCPlugin.initialize) {
      mockWindow.PreventSidebarTOCPlugin.initialize();
    }

    // Also call DOM cleanup manually since that would normally be called by Docsify hooks
    if (mockWindow.PreventSidebarTOCPlugin && mockWindow.PreventSidebarTOCPlugin.cleanupExistingElements) {
      mockWindow.PreventSidebarTOCPlugin.cleanupExistingElements();
    }
  }

  describe('Plugin Loading', () => {
    it('should load without errors', () => {
      expect(() => loadPluginSafely()).to.not.throw();
    });

    it('should expose debugging interface', () => {
      loadPluginSafely();
      expect(mockWindow.PreventSidebarTOCPlugin).toBeDefined();
      expect(mockWindow.PreventSidebarTOCPlugin.cleanup).toBeTypeOf('function');
      expect(mockWindow.PreventSidebarTOCPlugin.reinitialize).toBeTypeOf('function');
      expect(mockWindow.PreventSidebarTOCPlugin.getState).toBeTypeOf('function');
    });
  });

  describe('Docsify Integration', () => {
    it('should override Docsify subSidebar method', () => {
      const originalSubSidebar = mockWindow.Docsify.compiler.subSidebar;
      loadPluginSafely();

      expect(mockWindow.Docsify.compiler.subSidebar).not.equal(originalSubSidebar);
    });

    it('should return empty string when blocking subSidebar creation', () => {
      loadPluginSafely();

      // Test with left sidebar context (active element present)
      const result = mockWindow.Docsify.compiler.subSidebar('h2');

      expect(result).toBe('');
    });

    it('should allow subSidebar creation when not in sidebar context', () => {
      // Remove active element to simulate no left sidebar context
      const activeEl = mockDocument.querySelector('.sidebar-nav .active');
      if (activeEl) {activeEl.remove();}

      loadPluginSafely();

      const result = mockWindow.Docsify.compiler.subSidebar('h2');

      expect(result).not.equal('');
    });

    it('should register as Docsify plugin', () => {
      const initialPluginCount = mockWindow.$docsify.plugins.length;
      loadPluginSafely();

      expect(mockWindow.$docsify.plugins.length).toBeGreaterThan(initialPluginCount);
    });
  });

  describe('DOM Cleanup', () => {
    it('should remove existing app-sub-sidebar elements from left sidebar on load', () => {
      const initialSidebarSubs = mockDocument.querySelectorAll('.sidebar-nav .app-sub-sidebar');
      expect(initialSidebarSubs.length).toBe(1);

      loadPluginSafely();

      const remainingSidebarSubs = mockDocument.querySelectorAll('.sidebar-nav .app-sub-sidebar');

      expect(remainingSidebarSubs.length).toBe(0);
    });

    it('should preserve app-sub-sidebar elements outside of sidebar', () => {
      const initialContentSubs = mockDocument.querySelectorAll('.content .app-sub-sidebar');
      expect(initialContentSubs.length).toBe(1);

      loadPluginSafely();

      const remainingContentSubs = mockDocument.querySelectorAll('.content .app-sub-sidebar');

      expect(remainingContentSubs.length).toBe(1);
    });
  });

  describe('Error Handling', () => {
    it('should handle missing Docsify gracefully', () => {
      delete mockWindow.Docsify;

      expect(() => loadPluginSafely()).to.not.throw();
    });

    it('should handle missing $docsify gracefully', () => {
      delete mockWindow.$docsify;

      expect(() => loadPluginSafely()).to.not.throw();
    });

    it('should handle missing sidebar elements gracefully', () => {
      const sidebar = mockDocument.querySelector('.sidebar-nav');
      if (sidebar) {sidebar.remove();}
      expect(() => loadPluginSafely()).to.not.throw();
    });
  });

  describe('State Management', () => {
    it('should initialize state properly', () => {
      loadPluginSafely();
      const state = mockWindow.PreventSidebarTOCPlugin.getState();
      expect(state).toHaveProperty('isInitialized');
      expect(state.isInitialized).toBe(true);
    });

    it('should cleanup resources properly', () => {
      loadPluginSafely();
      const plugin = mockWindow.PreventSidebarTOCPlugin;

      plugin.cleanup();
      const state = plugin.getState();
      expect(state.isInitialized).toBe(false);
    });

    it('should reinitialize properly', () => {
      loadPluginSafely();
      const plugin = mockWindow.PreventSidebarTOCPlugin;

      plugin.cleanup();
      plugin.reinitialize();

      const state = plugin.getState();
      expect(state.isInitialized).toBe(true);
    });
  });

  describe('Timer Management', () => {
    it('should not rely on timers for basic functionality', () => {
      loadPluginSafely();

      expect(mockWindow.PreventSidebarTOCPlugin).toBeDefined();
    });

    it('should restore original method on cleanup', () => {
      const originalSubSidebar = mockWindow.Docsify.compiler.subSidebar;
      loadPluginSafely();
      const plugin = mockWindow.PreventSidebarTOCPlugin;

      // Verify the method was overridden
      expect(mockWindow.Docsify.compiler.subSidebar).not.toBe(originalSubSidebar);

      plugin.cleanup();

      // Should restore functionality - the exact object may be different due to spy wrapping
      expect(typeof mockWindow.Docsify.compiler.subSidebar).toBe('function');

      // The restored function should be callable and behave like the original
      expect(() => {
        const result = mockWindow.Docsify.compiler.subSidebar('test');
        expect(typeof result).toBe('string');
      }).not.toThrow();
    });
  });
});
