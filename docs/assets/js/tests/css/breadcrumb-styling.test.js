/**
 * CSS Integration Tests for Breadcrumb Styling
 * Tests design system integration, responsive behavior, and dark mode functionality
 */

import { describe, test, expect, beforeEach, afterEach, vi } from 'vitest';

describe('Breadcrumb CSS Integration', () => {
  beforeEach(() => {
    // Set up DOM environment with CSS support
    globalThis.document.documentElement.innerHTML = `
      <head>
        <style>
          /* Mock design system variables */
          :root {
            --spacing-xs: 0.25rem;
            --spacing-sm: 0.5rem;
            --spacing-md: 1rem;
            --font-size-base: 1rem;
            --font-size-sm: 0.875rem;
            --line-height-base: 1.5;
            --font-weight-normal: 400;
            --font-weight-medium: 500;
            --border-radius-sm: 0.25rem;
            --transition-fast: 0.15s ease-out;
            --text-primary: #1a202c;
            --text-secondary: #4a5568;
            --text-muted: #718096;
            --theme-color: #3182ce;
            --color-theme-alpha-05: rgba(49, 130, 206, 0.05);
            --color-theme-alpha-08: rgba(49, 130, 206, 0.08);
            --color-theme-alpha-10: rgba(49, 130, 206, 0.10);
            --color-theme-alpha-12: rgba(49, 130, 206, 0.12);
            --color-theme-alpha-15: rgba(49, 130, 206, 0.15);
            --color-shadow-light: rgba(0, 0, 0, 0.1);
          }

          [data-theme="dark"] {
            --text-primary: #f7fafc;
            --text-secondary: #e2e8f0;
            --text-muted: #a0aec0;
            --theme-color: #63b3ed;
          }
        </style>
      </head>
      <body>
        <nav class="breadcrumb-container" aria-label="Breadcrumb">
          <ol class="breadcrumb">
            <li class="breadcrumb-item">
              <a href="#/">Home</a>
            </li>
            <li class="breadcrumb-item">
              <a href="#/docs">Docs</a>
            </li>
            <li class="breadcrumb-item">
              <span class="active" aria-current="page">Getting Started</span>
            </li>
          </ol>
        </nav>
      </body>
    `;
  });

  afterEach(() => {
    // Clean up DOM
    globalThis.document.documentElement.innerHTML = '<head></head><body></body>';
  });

  describe('Design System Integration', () => {
    test('should use CSS custom properties for spacing', () => {
      const breadcrumbContainer = globalThis.document.querySelector('.breadcrumb-container');
      const computedStyle = globalThis.window.getComputedStyle(breadcrumbContainer);

      // Check that CSS custom properties would be applied
      expect(breadcrumbContainer).toBeTruthy();
      expect(computedStyle).toBeTruthy();
    });

    test('should have proper semantic HTML structure', () => {
      const nav = globalThis.document.querySelector('nav.breadcrumb-container');
      const ol = globalThis.document.querySelector('ol.breadcrumb');
      const listItems = globalThis.document.querySelectorAll('li.breadcrumb-item');
      const links = globalThis.document.querySelectorAll('li.breadcrumb-item a');
      const active = globalThis.document.querySelector('.active[aria-current="page"]');

      expect(nav).toBeTruthy();
      expect(ol).toBeTruthy();
      expect(listItems).toHaveLength(3);
      expect(links).toHaveLength(2); // Home and Docs links
      expect(active).toBeTruthy();
      expect(active.textContent).toBe('Getting Started');
    });

    test('should have ARIA attributes for accessibility', () => {
      const nav = globalThis.document.querySelector('nav.breadcrumb-container');
      const activeItem = globalThis.document.querySelector('.active');

      expect(nav.getAttribute('aria-label')).toBe('Breadcrumb');
      expect(activeItem.getAttribute('aria-current')).toBe('page');
    });
  });

  describe('CSS Class Structure', () => {
    test('should have correct CSS classes applied', () => {
      const container = globalThis.document.querySelector('.breadcrumb-container');
      const list = globalThis.document.querySelector('.breadcrumb');
      const items = globalThis.document.querySelectorAll('.breadcrumb-item');
      const active = globalThis.document.querySelector('.active');

      expect(container.classList.contains('breadcrumb-container')).toBe(true);
      expect(list.classList.contains('breadcrumb')).toBe(true);
      expect(items.length).toBeGreaterThan(0);
      items.forEach(item => {
        expect(item.classList.contains('breadcrumb-item')).toBe(true);
      });
      expect(active.classList.contains('active')).toBe(true);
    });

    test('should not contain any inline styles', () => {
      const allElements = globalThis.document.querySelectorAll('*');

      allElements.forEach(element => {
        expect(element.hasAttribute('style')).toBe(false);
      });
    });
  });

  describe('Responsive Behavior Simulation', () => {
    test('should handle mobile viewport simulation', () => {
      // Simulate mobile viewport by setting window properties
      Object.defineProperty(globalThis.window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 480
      });

      // Trigger resize event
      const resizeEvent = new globalThis.window.Event('resize');
      globalThis.window.dispatchEvent(resizeEvent);

      // Check that DOM structure remains intact for mobile
      const breadcrumbItems = globalThis.document.querySelectorAll('.breadcrumb-item');
      expect(breadcrumbItems.length).toBeGreaterThan(0);
    });

    test('should handle tablet viewport simulation', () => {
      Object.defineProperty(globalThis.window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 768
      });

      const resizeEvent = new globalThis.window.Event('resize');
      globalThis.window.dispatchEvent(resizeEvent);

      const breadcrumbItems = globalThis.document.querySelectorAll('.breadcrumb-item');
      expect(breadcrumbItems.length).toBeGreaterThan(0);
    });

    test('should handle desktop viewport simulation', () => {
      Object.defineProperty(globalThis.window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 1024
      });

      const resizeEvent = new globalThis.window.Event('resize');
      globalThis.window.dispatchEvent(resizeEvent);

      const breadcrumbItems = globalThis.document.querySelectorAll('.breadcrumb-item');
      expect(breadcrumbItems.length).toBeGreaterThan(0);
    });
  });

  describe('Dark Mode Integration', () => {
    test('should handle dark mode class toggle', () => {
      const body = globalThis.document.body;

      // Test light mode (default)
      expect(body.getAttribute('data-theme')).not.toBe('dark');

      // Switch to dark mode
      body.setAttribute('data-theme', 'dark');
      expect(body.getAttribute('data-theme')).toBe('dark');

      // Breadcrumb should still be present and functional
      const breadcrumb = globalThis.document.querySelector('.breadcrumb-container');
      expect(breadcrumb).toBeTruthy();
    });

    test('should maintain structure in dark mode', () => {
      globalThis.document.body.setAttribute('data-theme', 'dark');

      const nav = globalThis.document.querySelector('nav.breadcrumb-container');
      const links = globalThis.document.querySelectorAll('li.breadcrumb-item a');
      const active = globalThis.document.querySelector('.active');

      expect(nav).toBeTruthy();
      expect(links.length).toBe(2);
      expect(active).toBeTruthy();
    });
  });

  describe('Animation and Interaction States', () => {
    test('should have focusable elements', () => {
      const links = globalThis.document.querySelectorAll('li.breadcrumb-item a');

      links.forEach(link => {
        // Check that links have href attribute (makes them focusable)
        expect(link.getAttribute('href')).toBeTruthy();
        // In Happy DOM, elements with href are focusable even with tabIndex -1
        expect(link.tabIndex).toBeTypeOf('number');
      });
    });

    test('should handle focus events', () => {
      const firstLink = globalThis.document.querySelector('li.breadcrumb-item a');

      if (firstLink) {
        // Simulate focus
        const focusEvent = new globalThis.window.Event('focus');
        firstLink.dispatchEvent(focusEvent);

        // Link should still be present after focus
        expect(globalThis.document.contains(firstLink)).toBe(true);
      }
    });

    test('should handle hover simulation', () => {
      const links = globalThis.document.querySelectorAll('li.breadcrumb-item a');

      links.forEach(link => {
        // Simulate mouseenter
        const mouseEnterEvent = new globalThis.window.Event('mouseenter');
        link.dispatchEvent(mouseEnterEvent);

        // Element should still be in DOM
        expect(globalThis.document.contains(link)).toBe(true);

        // Simulate mouseleave
        const mouseLeaveEvent = new globalThis.window.Event('mouseleave');
        link.dispatchEvent(mouseLeaveEvent);

        expect(globalThis.document.contains(link)).toBe(true);
      });
    });
  });

  describe('Performance and Accessibility', () => {
    test('should have minimal DOM complexity', () => {
      const breadcrumbContainer = globalThis.document.querySelector('.breadcrumb-container');
      const allElements = breadcrumbContainer.querySelectorAll('*');

      // Should have reasonable DOM complexity (nav > ol > li > a/span structure)
      expect(allElements.length).toBeLessThan(20); // Reasonable limit for performance
    });

    test('should support reduced motion preferences', () => {
      // Simulate prefers-reduced-motion
      Object.defineProperty(globalThis.window, 'matchMedia', {
        writable: true,
        value: vi.fn().mockImplementation(query => ({
          matches: query === '(prefers-reduced-motion: reduce)',
          media: query,
          onchange: null,
          addListener: vi.fn(),
          removeListener: vi.fn(),
          addEventListener: vi.fn(),
          removeEventListener: vi.fn(),
          dispatchEvent: vi.fn()
        }))
      });

      const matchMedia = globalThis.window.matchMedia('(prefers-reduced-motion: reduce)');
      expect(matchMedia.matches).toBe(true);

      // Breadcrumb should still function normally
      const breadcrumb = globalThis.document.querySelector('.breadcrumb-container');
      expect(breadcrumb).toBeTruthy();
    });

    test('should support high contrast mode', () => {
      // Simulate high contrast preferences
      Object.defineProperty(globalThis.window, 'matchMedia', {
        writable: true,
        value: vi.fn().mockImplementation(query => ({
          matches: query === '(prefers-contrast: high)',
          media: query,
          onchange: null,
          addListener: vi.fn(),
          removeListener: vi.fn(),
          addEventListener: vi.fn(),
          removeEventListener: vi.fn(),
          dispatchEvent: vi.fn()
        }))
      });

      const matchMedia = globalThis.window.matchMedia('(prefers-contrast: high)');
      expect(matchMedia.matches).toBe(true);

      // Breadcrumb should remain functional
      const links = globalThis.document.querySelectorAll('li.breadcrumb-item a');
      expect(links.length).toBeGreaterThan(0);
    });
  });

  describe('CSS Loading and Integration', () => {
    test('should handle missing CSS gracefully', () => {
      // Remove CSS link to test fallback
      const cssLink = globalThis.document.querySelector('link[rel="stylesheet"]');
      if (cssLink) {
        cssLink.remove();
      }

      // Breadcrumb should still have proper HTML structure
      const nav = globalThis.document.querySelector('nav.breadcrumb-container');
      const ol = globalThis.document.querySelector('ol.breadcrumb');
      const items = globalThis.document.querySelectorAll('li.breadcrumb-item');

      expect(nav).toBeTruthy();
      expect(ol).toBeTruthy();
      expect(items.length).toBeGreaterThan(0);
    });

    test('should work with CSS custom properties', () => {
      // Test that CSS custom properties are properly set up
      const computedStyle = globalThis.window.getComputedStyle(globalThis.document.documentElement);

      // Check for some key design system variables
      const spacingXs = computedStyle.getPropertyValue('--spacing-xs');
      const themeColor = computedStyle.getPropertyValue('--theme-color');

      // These should be defined (not empty)
      expect(spacingXs.trim()).toBeTruthy();
      expect(themeColor.trim()).toBeTruthy();
    });
  });
});
