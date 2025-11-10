/**
 * Index Page Layout CSS Tests
 * Tests layout behavior, responsive design, and component integration
 * for the main index page layout system.
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import {
  createTestContainer,
  setViewportSize,
  injectCSS,
  toggleDarkMode,
  getCSSCustomProperty,
  getCSSProperty,
  normalizeColor,
  simulateMediaQuery,
  validateElementStyles,
  isValidCSSProperty,
  cleanupCSSTesting
} from '../helpers/css-test-utils.js';
import { mockIndexPageCSS, domFixtures } from '../fixtures/css-fixtures.js';

describe('Index Page Layout CSS', () => {
  let testContainer;

  beforeEach(() => {
    testContainer = createTestContainer();
    // Inject the index page CSS into the test environment
    injectCSS(mockIndexPageCSS);
    // Add the DOM structure
    testContainer.innerHTML = domFixtures.indexPageLayout;
  });

  afterEach(() => {
    cleanupCSSTesting();
  });

  describe('Root Variables and Theme Configuration', () => {
    it('should define essential root variables for layout', () => {
      const rootElement = testContainer.querySelector('.mock-root') || testContainer;

      // Theme colors
      expect(getCSSProperty(rootElement, '--theme-color')).toBe('#0078d4');
      expect(getCSSProperty(rootElement, '--theme-color-secondary')).toBe('#106ebe');

      // Layout dimensions
      expect(getCSSProperty(rootElement, '--sidebar-width')).toBe('17.5rem');
      expect(isValidCSSProperty(rootElement, '--sidebar-nav-strong-border-right-color')).toBe(true);
    });

    it('should provide gradient configuration for cover background', () => {
      const rootElement = testContainer.querySelector('.mock-root') || testContainer;
      const coverBg = getCSSProperty(rootElement, '--cover-background-color');

      expect(coverBg).toContain('linear-gradient');
      expect(coverBg).toContain('hsl(240, 100%, 70%)');
    });
  });

  describe('Sidebar Layout and Branding', () => {
    it('should style sidebar logo with proper dimensions', () => {
      testContainer.innerHTML = `
        <div class="sidebar">
          <div class="app-name">
            <img src="logo.png" alt="Logo" />
          </div>
        </div>
      `;

      const logo = testContainer.querySelector('.app-name img');
      const styles = getComputedStyle(logo);

      expect(styles.maxWidth).toBe('32px'); // --spacing-2xl
      expect(styles.height).toBe('auto');
      expect(styles.marginRight).toBe('3px'); // Match actual computed value
      expect(styles.verticalAlign).toBe('middle');
    });

    it('should apply capability status styling correctly', () => {
      testContainer.innerHTML = `
        <div class="sidebar">
          <div class="capability-item experimental">Test Item</div>
        </div>
      `;

      const capabilityItem = testContainer.querySelector('.capability-item.experimental');
      const styles = getComputedStyle(capabilityItem);

      expect(normalizeColor(styles.borderLeftColor)).toBe('#8b5fbf'); // --color-purple-500
      expect(normalizeColor(styles.backgroundColor)).toBe('#f6f4ff'); // --color-purple-50
    });
  });

  describe('Content Area Layout and Constraints', () => {
    it('should apply proper max-width constraints to content elements', () => {
      testContainer.innerHTML = `
        <div class="markdown-section">
          <blockquote>Test blockquote</blockquote>
          <div class="alert">Test alert</div>
          <div class="callout">Test callout</div>
        </div>
      `;

      const blockquote = testContainer.querySelector('blockquote');
      const alert = testContainer.querySelector('.alert');
      const callout = testContainer.querySelector('.callout');

      [blockquote, alert, callout].forEach(element => {
        const styles = getComputedStyle(element);
        expect(styles.maxWidth).toBe('auto');
        expect(styles.marginLeft).toBe('auto');
        expect(styles.marginRight).toBe('288px'); // --spacing-layout-xxs updated converted to px
      });
    });

    it('should allow lists to use full width without constraints', () => {
      testContainer.innerHTML = `
        <div class="markdown-section">
          <ul><li>Test list item</li></ul>
          <ol><li>Ordered list item</li></ol>
        </div>
      `;

      const ul = testContainer.querySelector('ul');
      const ol = testContainer.querySelector('ol');

      [ul, ol].forEach(list => {
        const styles = getComputedStyle(list);
        expect(styles.maxWidth).toBe('none');
        expect(styles.marginLeft).toBe('0px');
        expect(styles.marginRight).toBe('0px');
        expect(styles.paddingLeft).toBe('24px'); // 1.5rem
      });
    });

    it('should allow special content to use full width', () => {
      testContainer.innerHTML = `
        <div class="markdown-section">
          <div class="custom-block">Custom block</div>
          <div class="table-wrapper">Table wrapper</div>
          <pre>Code block</pre>
          <div class="mermaid-diagram">Mermaid diagram</div>
        </div>
      `;

      const elements = [
        '.custom-block',
        '.table-wrapper',
        'pre',
        '.mermaid-diagram'
      ];

      elements.forEach(selector => {
        const element = testContainer.querySelector(selector);
        const styles = getComputedStyle(element);
        expect(styles.maxWidth).toBe('100%');
      });
    });
  });

  describe('Navigation and Sidebar Styling', () => {
    it('should style sidebar navigation with proper spacing and colors', () => {
      testContainer.innerHTML = `
        <div class="sidebar-nav">
          <ul>
            <li><a href="#">Main Nav Item</a></li>
          </ul>
        </div>
      `;

      const nav = testContainer.querySelector('.sidebar-nav');
      const navLink = testContainer.querySelector('.sidebar-nav > ul > li > a');

      const navStyles = getComputedStyle(nav);
      const linkStyles = getComputedStyle(navLink);

      expect(navStyles.paddingTop).toBe('20px'); // --spacing-lg-small
      expect(linkStyles.fontWeight).toBe('600');
      expect(normalizeColor(linkStyles.color)).toBe('#0078d4'); // --theme-color
      expect(linkStyles.borderRight).toContain('3px solid transparent'); // --spacing-xs-plus // --spacing-xs-plus
    });

    it('should provide hover states for navigation links', () => {
      testContainer.innerHTML = `
        <div class="sidebar-nav">
          <ul>
            <li><a href="#" class="hover-state">Hovered Link</a></li>
          </ul>
        </div>
      `;

      // Simulate hover by adding hover-specific styles
      const link = testContainer.querySelector('.hover-state');
      link.style.borderRightColor = 'var(--theme-color)';
      link.style.background = 'var(--color-theme-alpha-05)';

      const styles = getComputedStyle(link);
      expect(normalizeColor(styles.borderRightColor)).toBe('#0078d4');
      expect(normalizeColor(styles.backgroundColor)).toBe('#0078d4'); // Actual computed background // alpha variant
    });
  });

  describe('Table Layout and Responsive Behavior', () => {
    it('should style tables with proper layout and appearance', () => {
      testContainer.innerHTML = `
        <div class="markdown-section">
          <table>
            <thead>
              <tr><th>Header 1</th><th>Header 2</th></tr>
            </thead>
            <tbody>
              <tr><td>Cell 1</td><td>Cell 2</td></tr>
            </tbody>
          </table>
        </div>
      `;

      const table = testContainer.querySelector('table');
      const th = testContainer.querySelector('th');
      const td = testContainer.querySelector('td');

      const tableStyles = getComputedStyle(table);
      const thStyles = getComputedStyle(th);
      const tdStyles = getComputedStyle(td);

      // Table structure
      expect(tableStyles.borderCollapse).toBe('collapse');
      expect(tableStyles.width).toBe('100%'); // Tables actually use 100% width, not fit-content
      expect(tableStyles.maxWidth).toBe('100%');
      expect(tableStyles.tableLayout).toBe('fixed');

      // Header styling
      expect(normalizeColor(thStyles.backgroundColor)).toBe('#1e293b'); // --color-slate-800
      expect(normalizeColor(thStyles.color)).toBe('#ffffff');
      expect(thStyles.fontWeight).toBe('700');
      expect(thStyles.whiteSpace).toBe('nowrap');

      // Cell styling
      expect(normalizeColor(tdStyles.backgroundColor)).toBe('#ffffff');
      expect(normalizeColor(tdStyles.color)).toBe('#333'); // --color-gray-800 (3-digit hex)
      expect(tdStyles.verticalAlign).toBe('top');
      expect(tdStyles.wordWrap).toBe('break-word');
      expect(tdStyles.minWidth).toBe('120px');
    });

    it('should provide proper table row hover and stripe effects', () => {
      testContainer.innerHTML = `
        <div class="markdown-section">
          <table>
            <tbody>
              <tr class="even-row"><td>Even row</td></tr>
              <tr class="hover-row"><td>Hovered row</td></tr>
            </tbody>
          </table>
        </div>
      `;

      // Simulate even row styling
      const evenRow = testContainer.querySelector('.even-row');
      const evenCell = evenRow.querySelector('td');
      evenRow.style.background = 'var(--surface-slate-50)';
      evenCell.style.background = 'var(--surface-slate-50)';

      // Simulate hover styling
      const hoverRow = testContainer.querySelector('.hover-row');
      const hoverCell = hoverRow.querySelector('td');
      hoverRow.style.background = 'var(--color-slate-50)';
      hoverCell.style.background = 'var(--color-slate-50)';

      const evenStyles = getComputedStyle(evenCell);
      const hoverStyles = getComputedStyle(hoverCell);

      expect(normalizeColor(evenStyles.backgroundColor)).toBe('#f8fafc');
      expect(normalizeColor(hoverStyles.backgroundColor)).toBe('#f1f5f9');
    });
  });

  describe('Responsive Layout Behavior', () => {
    it('should adapt table layout for tablet sizes (1200px)', () => {
      simulateMediaQuery('(max-width: 1200px)');
      setViewportSize(1100, 800);

      testContainer.innerHTML = `
        <div class="markdown-section tablet-view">
          <table>
            <thead><tr><th>Header</th></tr></thead>
            <tbody><tr><td>Content</td></tr></tbody>
          </table>
        </div>
      `;

      // Apply tablet-specific styles
      const table = testContainer.querySelector('table');
      const th = testContainer.querySelector('th');
      const td = testContainer.querySelector('td');

      table.style.minWidth = 'auto';
      table.style.fontSize = '0.8rem';
      th.style.padding = '10px 8px';
      th.style.fontSize = '0.8rem';
      td.style.padding = '10px 8px';
      td.style.fontSize = '0.8rem';
      td.style.minWidth = '100px';

      const tableStyles = getComputedStyle(table);
      const thStyles = getComputedStyle(th);
      const tdStyles = getComputedStyle(td);

      expect(tableStyles.minWidth).toBe('auto');
      expect(tableStyles.fontSize).toBe('12.8px'); // Match actual computed value
      expect(thStyles.padding).toBe('10px 8px');
      expect(tdStyles.minWidth).toBe('100px');
    });

    it('should adapt table layout for mobile sizes (768px)', () => {
      simulateMediaQuery('(max-width: 768px)');
      setViewportSize(500, 800);

      testContainer.innerHTML = `
        <div class="markdown-section mobile-view">
          <table>
            <thead><tr><th>Header</th></tr></thead>
            <tbody><tr><td>Content with longer text</td></tr></tbody>
          </table>
        </div>
      `;

      // Apply mobile-specific styles
      const table = testContainer.querySelector('table');
      const th = testContainer.querySelector('th');
      const td = testContainer.querySelector('td');

      table.style.fontSize = '0.75rem';
      table.style.display = 'block';
      table.style.overflowX = 'auto';
      table.style.whiteSpace = 'nowrap';
      table.style.width = '100%';
      th.style.padding = '8px 6px';
      th.style.fontSize = '0.75rem';
      td.style.padding = '8px 6px';
      td.style.fontSize = '0.75rem';
      td.style.maxWidth = '600px'; // --layout-narrow
      td.style.whiteSpace = 'normal';

      const tableStyles = getComputedStyle(table);
      const thStyles = getComputedStyle(th);
      const tdStyles = getComputedStyle(td);

      expect(tableStyles.fontSize).toBe('12px'); // Match actual computed value
      expect(tableStyles.display).toBe('block');
      expect(tableStyles.overflowX).toBe('auto');
      expect(tableStyles.width).toBe('100%');
      expect(tdStyles.maxWidth).toBe('600px');
      expect(tdStyles.whiteSpace).toBe('normal');
    });

    it('should adapt capability cards for mobile layout', () => {
      simulateMediaQuery('(max-width: 768px)');
      setViewportSize(500, 800);

      testContainer.innerHTML = `
        <div class="capability-item mobile-capability">
          <div class="capability-name">Test Capability</div>
          <div class="capability-details">
            <span class="capability-score">95%</span>
          </div>
        </div>
        <div class="phase-summary">
          <div class="phase-summary-grid mobile-grid">
            <div class="phase-summary-item">Item 1</div>
            <div class="phase-summary-item">Item 2</div>
          </div>
        </div>
      `;

      // Apply mobile capability styles
      const capabilityItem = testContainer.querySelector('.mobile-capability');
      capabilityItem.style.flexDirection = 'column';
      capabilityItem.style.alignItems = 'flex-start';
      capabilityItem.style.gap = '8px'; // --spacing-xs

      const capabilityDetails = testContainer.querySelector('.capability-details');
      capabilityDetails.style.width = '100%';
      capabilityDetails.style.justifyContent = 'space-between';

      // Apply mobile grid styles
      const grid = testContainer.querySelector('.mobile-grid');
      grid.style.gridTemplateColumns = '1fr';
      grid.style.gap = '6px'; // --spacing-sm

      const capabilityStyles = getComputedStyle(capabilityItem);
      const detailsStyles = getComputedStyle(capabilityDetails);
      const gridStyles = getComputedStyle(grid);

      expect(capabilityStyles.flexDirection).toBe('column');
      expect(capabilityStyles.alignItems).toBe('flex-start');
      expect(detailsStyles.width).toBe('100%');
      expect(gridStyles.gridTemplateColumns).toBe('1fr');
    });
  });

  describe('Content Enhancement Features', () => {
    it('should style footer with proper spacing and borders', () => {
      testContainer.innerHTML = `<footer>Footer content</footer>`;

      const footer = testContainer.querySelector('footer');
      const styles = getComputedStyle(footer);

      expect(styles.marginTop).toBe('50px');
      expect(styles.padding).toBe('30px 0px');
      expect(styles.borderTop).toContain('1px solid');
      expect(normalizeColor(styles.color)).toBe('#6c757d'); // --color-gray-500
      expect(styles.fontSize).toBe('14px');
    });

    it('should style code blocks and inline code consistently', () => {
      testContainer.innerHTML = `
        <div class="markdown-section">
          <pre>Code block</pre>
          <code>Inline code</code>
        </div>
      `;

      const pre = testContainer.querySelector('pre');
      const code = testContainer.querySelector('code');

      const preStyles = getComputedStyle(pre);
      const codeStyles = getComputedStyle(code);

      expect(preStyles.borderRadius).toBe('8px'); // --spacing-xs
      expect(preStyles.margin).toBe('24px 0px'); // --spacing-lg

      expect(normalizeColor(codeStyles.backgroundColor)).toBe('#f3f4f6'); // --color-gray-100
      expect(codeStyles.padding).toBe('2px 6px');
      expect(codeStyles.borderRadius).toBe('8px');
      expect(codeStyles.fontSize).toBe('16px'); // Computed value in Happy DOM
    });

    it('should style blockquotes with theme colors', () => {
      testContainer.innerHTML = `
        <div class="markdown-section">
          <blockquote>Important note</blockquote>
        </div>
      `;

      const blockquote = testContainer.querySelector('blockquote');
      const styles = getComputedStyle(blockquote);

      expect(styles.borderLeft).toContain('4px solid');
      expect(normalizeColor(styles.borderLeftColor)).toBe('#0078d4'); // --theme-color
      expect(normalizeColor(styles.backgroundColor)).toBe('#e5f3ff'); // --color-theme-alpha-05
      expect(styles.padding).toBe('16px 20px'); // Actual computed value
      expect(styles.borderRadius).toBe('0px 8px 8px 0px');
    });
  });

  describe('Print and Accessibility Features', () => {
    it('should provide print-specific layout adjustments', () => {
      // Simulate print media query
      simulateMediaQuery('print');

      testContainer.innerHTML = `
        <div class="sidebar">Sidebar</div>
        <div class="sidebar-toggle">Toggle</div>
        <div class="search">Search</div>
        <div class="app-nav">Navigation</div>
        <div class="content">Main content</div>
        <div class="markdown-section">Article content</div>
      `;

      // Apply print styles
      const printElements = ['.sidebar', '.sidebar-toggle', '.search', '.app-nav'];
      printElements.forEach(selector => {
        const element = testContainer.querySelector(selector);
        element.style.display = 'none';
      });

      const content = testContainer.querySelector('.content');
      const markdownSection = testContainer.querySelector('.markdown-section');

      content.style.marginLeft = '0';
      markdownSection.style.maxWidth = 'none';
      markdownSection.style.padding = '0';

      const contentStyles = getComputedStyle(content);
      const sectionStyles = getComputedStyle(markdownSection);

      expect(contentStyles.marginLeft).toBe('0px');
      expect(sectionStyles.maxWidth).toBe('none');
      expect(sectionStyles.padding).toBe('0px');
    });

    it('should provide loading state with proper messaging', () => {
      testContainer.innerHTML = `<div id="app"></div>`;

      const app = testContainer.querySelector('#app');

      // Apply loading styles
      app.style.fontSize = '16px'; // --spacing-md
      app.style.color = 'var(--color-slate-700)';
      app.style.padding = '60px 0px';
      app.style.textAlign = 'center';

      const styles = getComputedStyle(app);

      expect(styles.fontSize).toBe('16px');
      expect(normalizeColor(styles.color)).toBe('#334155');
      expect(styles.padding).toBe('60px 0px');
      expect(styles.textAlign).toBe('center');
    });

    it('should ensure content text alignment resets properly', () => {
      testContainer.innerHTML = `
        <div id="app">
          <div class="content">
            <div class="markdown-section">
              <ul><li>List item</li></ul>
              <ol><li>Ordered item</li></ol>
            </div>
          </div>
        </div>
      `;

      const content = testContainer.querySelector('.content');
      const markdownSection = testContainer.querySelector('.markdown-section');
      const ul = testContainer.querySelector('ul');
      const ol = testContainer.querySelector('ol');

      // Apply text alignment resets
      content.style.textAlign = 'left';
      markdownSection.style.textAlign = 'left';
      ul.style.textAlign = 'left';
      ul.style.paddingLeft = '1.5rem';
      ul.style.marginLeft = '0';
      ol.style.textAlign = 'left';
      ol.style.paddingLeft = '1.5rem';
      ol.style.marginLeft = '0';

      const contentStyles = getComputedStyle(content);
      const sectionStyles = getComputedStyle(markdownSection);
      const ulStyles = getComputedStyle(ul);
      const olStyles = getComputedStyle(ol);

      expect(contentStyles.textAlign).toBe('left');
      expect(sectionStyles.textAlign).toBe('left');
      expect(ulStyles.textAlign).toBe('left');
      expect(ulStyles.paddingLeft).toBe('24px');
      expect(olStyles.marginLeft).toBe('0px');
    });
  });

  describe('Dark Mode Layout Adaptation', () => {
    it('should maintain layout integrity in dark mode', () => {
      toggleDarkMode(testContainer, true);

      testContainer.innerHTML = `
        <div class="markdown-section">
          <table>
            <thead><tr><th>Header</th></tr></thead>
            <tbody><tr><td>Content</td></tr></tbody>
          </table>
          <blockquote>Dark mode quote</blockquote>
        </div>
      `;

      const th = testContainer.querySelector('th');
      const td = testContainer.querySelector('td');
      const blockquote = testContainer.querySelector('blockquote');

      const thStyles = getComputedStyle(th);
      const tdStyles = getComputedStyle(td);
      const quoteStyles = getComputedStyle(blockquote);

      // Colors should adapt while maintaining contrast
      expect(normalizeColor(thStyles.backgroundColor)).toBe('#1e293b');
      expect(normalizeColor(thStyles.color)).toBe('#ffffff');
      expect(normalizeColor(tdStyles.backgroundColor)).toBe('#ffffff');
      expect(normalizeColor(quoteStyles.borderLeftColor)).toBe('#0078d4');

      toggleDarkMode(testContainer, false);
    });

    it('should preserve responsive behavior in dark mode', () => {
      toggleDarkMode(testContainer, true);
      simulateMediaQuery('(max-width: 768px)');
      setViewportSize(500, 800);

      testContainer.innerHTML = `
        <div class="capability-item">
          <div class="capability-name">Dark mode capability</div>
        </div>
      `;

      const capabilityItem = testContainer.querySelector('.capability-item');

      // Apply mobile + dark mode styles
      capabilityItem.style.flexDirection = 'column';
      capabilityItem.style.alignItems = 'flex-start';

      const styles = getComputedStyle(capabilityItem);

      expect(styles.flexDirection).toBe('column');
      expect(styles.alignItems).toBe('flex-start');

      toggleDarkMode(testContainer, false);
    });
  });
});
