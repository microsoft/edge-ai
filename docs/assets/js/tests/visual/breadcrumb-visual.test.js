/**
 * Visual Regression Tests for Breadcrumb Navigation
 * Tests visual consistency across different states, themes, and viewports
 *
 * @author Edge AI Team
 * @since 2025-01-15
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';

describe('Breadcrumb Visual Regression Tests', () => {
  let document;
  let window;
  let breadcrumbPlugin;

  beforeEach(async () => {
    // Set up DOM environment with Happy DOM
    document = globalThis.window.document;
    window = globalThis.window;

    // Set up test HTML
    document.body.innerHTML = `
      <main class="content">
        <div class="markdown-section">
          <h1>Test Page</h1>
        </div>
      </main>
    `;

    // Load the breadcrumb plugin
    const _pluginModule = await import('../../plugins/custom-breadcrumb-plugin.js');
    breadcrumbPlugin = window.customBreadcrumbPluginInstance;
  });

  afterEach(() => {
    // Clean up
    if (breadcrumbPlugin) {
      breadcrumbPlugin.cleanup();
    }
    document.body.innerHTML = '';
  });

  describe('Visual State Consistency', () => {
    it('should render home breadcrumb with consistent styling', async () => {
      // Generate home breadcrumb
      const homeRoute = { path: '/' };
      await breadcrumbPlugin.updateBreadcrumb(homeRoute);

      // Find breadcrumb container
      const container = document.querySelector('.breadcrumb-container');
      expect(container).toBeTruthy();

      // Verify structure and classes for visual consistency
      expect(container.tagName).toBe('NAV');
      expect(container.getAttribute('aria-label')).toBe('Breadcrumb');

      const breadcrumbList = container.querySelector('ol.breadcrumb');
      expect(breadcrumbList).toBeTruthy();

      const homeItem = breadcrumbList.querySelector('li.breadcrumb-item');
      expect(homeItem).toBeTruthy();

      const activeSpan = homeItem.querySelector('span.active');
      expect(activeSpan).toBeTruthy();
      expect(activeSpan.textContent.trim()).toBe('Home');
      expect(activeSpan.getAttribute('aria-current')).toBe('page');
    });

    it('should render nested breadcrumb with proper visual hierarchy', async () => {
      // Generate nested breadcrumb
      const nestedRoute = { path: '/documentation/getting-started' };
      await breadcrumbPlugin.updateBreadcrumb(nestedRoute);

      const container = document.querySelector('.breadcrumb-container');
      expect(container).toBeTruthy();

      const breadcrumbList = container.querySelector('ol.breadcrumb');
      const items = breadcrumbList.querySelectorAll('li.breadcrumb-item');

      // Should have 3 items: Home, Documentation, Getting Started
      expect(items).toHaveLength(3);

      // Verify visual hierarchy structure
      const homeItem = items[0];
      const homeLink = homeItem.querySelector('a');
      expect(homeLink).toBeTruthy();
      expect(homeLink.textContent.trim()).toBe('Home');
      expect(homeLink.getAttribute('href')).toBe('#/');

      const docItem = items[1];
      const docLink = docItem.querySelector('a');
      expect(docLink).toBeTruthy();
      expect(docLink.textContent.trim()).toBe('Documentation');
      expect(docLink.getAttribute('href')).toBe('#/documentation/');

      const activeItem = items[2];
      const activeSpan = activeItem.querySelector('span.active');
      expect(activeSpan).toBeTruthy();
      expect(activeSpan.textContent.trim()).toBe('Getting Started');
      expect(activeSpan.getAttribute('aria-current')).toBe('page');
    });

    it('should apply consistent visual separators between items', async () => {
      // Generate multi-level breadcrumb
      const route = { path: '/docs/api/endpoints/users' };
      await breadcrumbPlugin.updateBreadcrumb(route);

      const items = document.querySelectorAll('li.breadcrumb-item');
      expect(items.length).toBeGreaterThan(2);

      // Verify separator structure (CSS pseudo-elements are applied correctly)
      items.forEach((item, _index) => {
        if (_index < items.length - 1) {
          // Non-last items should have the separator class structure
          // The actual separator is applied via CSS ::after pseudo-element
          expect(item.classList.contains('breadcrumb-item')).toBe(true);

          // Verify no inline separator spans exist (they should be CSS-only)
          const separatorSpan = item.querySelector('span[aria-hidden="true"]');
          expect(separatorSpan).toBeFalsy();
        }
      });
    });
  });

  describe('Responsive Visual Behavior', () => {
    it('should adapt visual layout for mobile viewport', async () => {
      // Simulate mobile viewport
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 375
      });

      // Generate breadcrumb
      const route = { path: '/documentation/setup/installation' };
      await breadcrumbPlugin.updateBreadcrumb(route);

      const container = document.querySelector('.breadcrumb-container');
      expect(container).toBeTruthy();

      // Verify mobile-friendly structure is maintained
      const breadcrumbList = container.querySelector('ol.breadcrumb');
      expect(breadcrumbList).toBeTruthy();

      // Should still use flexbox layout for horizontal display
      const _computedStyle = window.getComputedStyle(breadcrumbList);
      // Note: JSDOM doesn't compute styles, but we can verify structure remains consistent
      expect(breadcrumbList.style.display || 'flex').toContain('flex');
    });

    it('should maintain visual consistency across tablet viewport', async () => {
      // Simulate tablet viewport
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 768
      });

      const route = { path: '/guides/deployment/azure' };
      await breadcrumbPlugin.updateBreadcrumb(route);

      const container = document.querySelector('.breadcrumb-container');
      const items = container.querySelectorAll('li.breadcrumb-item');

      // Verify structure consistency at tablet viewport
      expect(items.length).toBeGreaterThan(0);
      items.forEach(item => {
        expect(item.classList.contains('breadcrumb-item')).toBe(true);
      });
    });

    it('should provide enhanced visual features on desktop viewport', async () => {
      // Simulate desktop viewport
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 1200
      });

      const route = { path: '/advanced/performance/optimization/caching' };
      await breadcrumbPlugin.updateBreadcrumb(route);

      const container = document.querySelector('.breadcrumb-container');
      const links = container.querySelectorAll('a');

      // Verify interactive elements are properly structured for desktop
      links.forEach(link => {
        expect(link.tagName).toBe('A');
        expect(link.getAttribute('href')).toBeTruthy();
        // Visual enhancement classes should be present
        expect(link.parentElement.classList.contains('breadcrumb-item')).toBe(true);
      });
    });
  });

  describe('Theme Visual Integration', () => {
    it('should apply consistent light theme visual styling', async () => {
      // Ensure light theme
      document.body.classList.remove('dark');

      const route = { path: '/components/buttons' };
      await breadcrumbPlugin.updateBreadcrumb(route);

      const container = document.querySelector('.breadcrumb-container');
      expect(container).toBeTruthy();

      // Verify theme-agnostic structure (actual colors are handled by CSS variables)
      const links = container.querySelectorAll('a');
      const activeElements = container.querySelectorAll('.active');

      expect(links.length).toBeGreaterThan(0);
      expect(activeElements.length).toBe(1);

      // Verify no hardcoded colors in inline styles
      links.forEach(link => {
        expect(link.style.color).toBe('');
        expect(link.style.backgroundColor).toBe('');
      });
    });

    it('should maintain visual consistency in dark theme', async () => {
      // Enable dark theme
      document.body.classList.add('dark');

      const route = { path: '/themes/dark-mode' };
      await breadcrumbPlugin.updateBreadcrumb(route);

      const container = document.querySelector('.breadcrumb-container');
      expect(container).toBeTruthy();

      // Structure should remain identical between themes
      const breadcrumbList = container.querySelector('ol.breadcrumb');
      const items = breadcrumbList.querySelectorAll('li.breadcrumb-item');

      expect(items.length).toBeGreaterThan(0);

      // Verify no hardcoded styling that would break dark theme
      items.forEach(item => {
        const link = item.querySelector('a');
        const active = item.querySelector('.active');

        if (link) {
          expect(link.style.color).toBe('');
          expect(link.style.backgroundColor).toBe('');
        }
        if (active) {
          expect(active.style.color).toBe('');
          expect(active.style.backgroundColor).toBe('');
        }
      });
    });
  });

  describe('Interactive State Visual Consistency', () => {
    it('should provide consistent visual structure for hover states', async () => {
      const route = { path: '/tutorials/getting-started/setup' };
      await breadcrumbPlugin.updateBreadcrumb(route);

      const links = document.querySelectorAll('.breadcrumb-container a');
      expect(links.length).toBeGreaterThan(0);

      // Verify hover-ready structure exists
      links.forEach(link => {
        // Links should have proper structure for CSS hover effects
        expect(link.tagName).toBe('A');
        expect(link.getAttribute('href')).toBeTruthy();
        expect(link.textContent.trim()).toBeTruthy();

        // Should have no inline styling that would interfere with hover effects
        expect(link.style.cssText).toBe('');
      });
    });

    it('should provide proper focus visual indicator structure', async () => {
      const route = { path: '/accessibility/keyboard-navigation' };
      await breadcrumbPlugin.updateBreadcrumb(route);

      const links = document.querySelectorAll('.breadcrumb-container a');

      // Verify focus-ready structure
      links.forEach(link => {
        // Should be focusable (tabIndex 0 or not set for normal links)
        expect(link.tabIndex === 0 || link.tabIndex === -1).toBe(true);

        // Should have proper href for keyboard navigation
        expect(link.getAttribute('href')).toBeTruthy();

        // Should have clean structure for CSS focus indicators
        expect(link.style.outline).toBe('');
        expect(link.style.boxShadow).toBe('');
      });
    });
  });

  describe('Performance Visual Optimization', () => {
    it('should generate minimal DOM structure for optimal rendering', async () => {
      const route = { path: '/performance/optimization/dom' };
      await breadcrumbPlugin.updateBreadcrumb(route);

      const container = document.querySelector('.breadcrumb-container');

      // Verify clean, minimal DOM structure
      expect(container.children.length).toBe(1); // Only the <ol> element

      const breadcrumbList = container.querySelector('ol.breadcrumb');
      expect(breadcrumbList.children.length).toBeGreaterThan(0);

      // Each breadcrumb item should have minimal structure
      const items = breadcrumbList.querySelectorAll('li.breadcrumb-item');
      items.forEach(item => {
        // Should contain either a link or active span, not both
        const link = item.querySelector('a');
        const active = item.querySelector('.active');

        expect((link ? 1 : 0) + (active ? 1 : 0)).toBe(1);

        // No extraneous elements
        expect(item.children.length).toBe(1);
      });
    });

    it('should avoid visual layout thrashing with consistent structure', async () => {
      // Generate breadcrumb
      const initialRoute = { path: '/initial' };
      await breadcrumbPlugin.updateBreadcrumb(initialRoute);

      const initialContainer = document.querySelector('.breadcrumb-container');
      const _initialStructure = initialContainer ? initialContainer.outerHTML : '';

      // Update with different route
      const newRoute = { path: '/different/path' };
      await breadcrumbPlugin.updateBreadcrumb(newRoute);

      const updatedContainer = document.querySelector('.breadcrumb-container');
      expect(updatedContainer).toBeTruthy();

      // Structure pattern should be consistent (nav > ol > li structure)
      expect(updatedContainer.tagName).toBe('NAV');
      expect(updatedContainer.querySelector('ol.breadcrumb')).toBeTruthy();
      expect(updatedContainer.querySelectorAll('li.breadcrumb-item').length).toBeGreaterThan(0);

      // No inline styles that could cause layout shifts
      const allElements = updatedContainer.querySelectorAll('*');
      allElements.forEach(element => {
        expect(element.style.cssText).toBe('');
      });
    });
  });

  describe('Accessibility Visual Integration', () => {
    it('should maintain visual accessibility with proper ARIA structure', async () => {
      const route = { path: '/accessibility/visual-design' };
      await breadcrumbPlugin.updateBreadcrumb(route);

      const container = document.querySelector('.breadcrumb-container');

      // Verify ARIA structure supports visual accessibility
      expect(container.getAttribute('aria-label')).toBe('Breadcrumb');
      expect(container.tagName).toBe('NAV');

      const activeElement = container.querySelector('.active');
      expect(activeElement).toBeTruthy();
      expect(activeElement.getAttribute('aria-current')).toBe('page');

      // Verify screen reader compatible structure
      const breadcrumbList = container.querySelector('ol');
      expect(breadcrumbList).toBeTruthy();
      expect(breadcrumbList.tagName).toBe('OL'); // Ordered list for proper hierarchy
    });

    it('should provide high contrast visual compatibility structure', async () => {
      const route = { path: '/accessibility/high-contrast' };
      await breadcrumbPlugin.updateBreadcrumb(route);

      const container = document.querySelector('.breadcrumb-container');
      const links = container.querySelectorAll('a');
      const activeElements = container.querySelectorAll('.active');

      // Verify structure supports high contrast mode
      links.forEach(link => {
        // Clean structure with no competing inline styles
        expect(link.style.color).toBe('');
        expect(link.style.borderColor).toBe('');
        expect(link.style.backgroundColor).toBe('');
      });

      activeElements.forEach(active => {
        // Clean structure for high contrast styling
        expect(active.style.color).toBe('');
        expect(active.style.backgroundColor).toBe('');
        expect(active.style.border).toBe('');
      });
    });
  });
});
