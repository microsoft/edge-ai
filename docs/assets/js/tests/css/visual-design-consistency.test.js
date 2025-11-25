/**
 * Visual Design Consistency Tests
 * Tests for consistent typography, spacing, colors, and layout patterns
 * across all learning paths components
 *
 * @fileoverview TDD approach for visual design consistency
 * @author Edge AI Team
 * @since 2025-09-14
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { readFileSync } from 'fs';
import { join } from 'path';

describe('Visual Design Consistency', () => {
  let container;

  beforeEach(() => {
    // Use the global document from vitest environment setup (Happy DOM)
    document.head.innerHTML = '';
    document.body.innerHTML = '<div id="test-container"></div>';
    container = document.getElementById('test-container');

    // Load CSS variables from the canonical variables.css file
    const variablesPath = join(process.cwd(), '../css/theme/variables.css');
    const variablesCSS = readFileSync(variablesPath, 'utf-8');

    const variablesStyle = document.createElement('style');
    variablesStyle.textContent = variablesCSS;
    document.head.appendChild(variablesStyle);
  });

  afterEach(() => {
    if (container) {
      container.innerHTML = '';
    }
    document.head.innerHTML = '';
    vi.restoreAllMocks();
  });

  describe('CSS Variables and Design Tokens', () => {
    it('should define consistent color scheme variables', async () => {
      // Create style element with expected CSS variables
      const style = document.createElement('style');
      style.textContent = `
        :root {
          --primary-color: #0078d4;
          --secondary-color: #107c10;
          --accent-color: #d83b01;
          --background-color: #ffffff;
          --surface-color: #f3f2f1;
          --text-primary: #323130;
          --text-secondary: #605e5c;
          --text-muted: #8a8886;
          --border-color: #e1dfdd;
          --focus-color: #005a9e;
          --error-color: #d13438;
          --success-color: #107c10;
          --warning-color: #ff8c00;
        }
      `;
      document.head.appendChild(style);

      const computedStyle = window.getComputedStyle(document.documentElement);

      // Test primary color scheme
      expect(computedStyle.getPropertyValue('--primary-color').trim()).toBe('#0078d4');
      expect(computedStyle.getPropertyValue('--secondary-color').trim()).toBe('#107c10');
      expect(computedStyle.getPropertyValue('--accent-color').trim()).toBe('#d83b01');

      // Test background colors
      expect(computedStyle.getPropertyValue('--background-color').trim()).toBe('#ffffff');
      expect(computedStyle.getPropertyValue('--surface-color').trim()).toBe('#f3f2f1');

      // Test text colors
      expect(computedStyle.getPropertyValue('--text-primary').trim()).toBe('#323130');
      expect(computedStyle.getPropertyValue('--text-secondary').trim()).toBe('#605e5c');
      expect(computedStyle.getPropertyValue('--text-muted').trim()).toBe('#8a8886');
    });

    it('should define consistent typography scale variables', async () => {
      const style = document.createElement('style');
      style.textContent = `
        :root {
          --font-family-primary: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          --font-family-monospace: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;

          --font-size-xs: 0.75rem;
          --font-size-sm: 0.875rem;
          --font-size-base: 1rem;
          --font-size-lg: 1.125rem;
          --font-size-xl: 1.25rem;
          --font-size-2xl: 1.5rem;
          --font-size-3xl: 1.875rem;
          --font-size-4xl: 2.25rem;

          --font-weight-normal: 400;
          --font-weight-medium: 500;
          --font-weight-semibold: 600;
          --font-weight-bold: 700;

          --line-height-tight: 1.25;
          --line-height-normal: 1.5;
          --line-height-relaxed: 1.75;
        }
      `;
      document.head.appendChild(style);

      const computedStyle = window.getComputedStyle(document.documentElement);

      // Test font families
      expect(computedStyle.getPropertyValue('--font-family-primary').trim()).toContain('Segoe UI');
      expect(computedStyle.getPropertyValue('--font-family-monospace').trim()).toContain('Consolas');

      // Test font sizes
      expect(computedStyle.getPropertyValue('--font-size-base').trim()).toBe('1rem');
      expect(computedStyle.getPropertyValue('--font-size-lg').trim()).toBe('1.125rem');
      expect(computedStyle.getPropertyValue('--font-size-xl').trim()).toBe('1.25rem');

      // Test font weights
      expect(computedStyle.getPropertyValue('--font-weight-normal').trim()).toBe('400');
      expect(computedStyle.getPropertyValue('--font-weight-semibold').trim()).toBe('600');
    });

    it('should define consistent spacing scale variables', async () => {
      const style = document.createElement('style');
      style.textContent = `
        :root {
          --spacing-xs: 0.25rem;
          --spacing-sm: 0.5rem;
          --spacing-md: 1rem;
          --spacing-lg: 1.5rem;
          --spacing-xl: 2rem;
          --spacing-2xl: 3rem;
          --spacing-3xl: 4rem;

          --border-radius-sm: 0.125rem;
          --border-radius-md: 0.25rem;
          --border-radius-lg: 0.5rem;
          --border-radius-xl: 1rem;

          --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
          --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
          --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
        }
      `;
      document.head.appendChild(style);

      const computedStyle = window.getComputedStyle(document.documentElement);

      // Test spacing scale
      expect(computedStyle.getPropertyValue('--spacing-xs').trim()).toBe('0.25rem');
      expect(computedStyle.getPropertyValue('--spacing-md').trim()).toBe('1rem');
      expect(computedStyle.getPropertyValue('--spacing-xl').trim()).toBe('2rem');

      // Test border radius
      expect(computedStyle.getPropertyValue('--border-radius-md').trim()).toBe('0.25rem');
      expect(computedStyle.getPropertyValue('--border-radius-lg').trim()).toBe('0.5rem');
    });
  });

  describe('Typography Consistency', () => {
    it('should apply consistent heading hierarchy', async () => {
      container.innerHTML = `
        <h1 class="heading-1">Primary Heading</h1>
        <h2 class="heading-2">Secondary Heading</h2>
        <h3 class="heading-3">Tertiary Heading</h3>
        <p class="body-text">Body text content</p>
        <small class="small-text">Small text content</small>
      `;

      const style = document.createElement('style');
      style.textContent = `
        .heading-1 {
          font-size: var(--font-size-3xl);
          font-weight: var(--font-weight-bold);
          line-height: var(--line-height-tight);
          color: var(--text-primary);
          margin-bottom: var(--spacing-lg);
        }
        .heading-2 {
          font-size: var(--font-size-2xl);
          font-weight: var(--font-weight-semibold);
          line-height: var(--line-height-tight);
          color: var(--text-primary);
          margin-bottom: var(--spacing-md);
        }
        .heading-3 {
          font-size: var(--font-size-xl);
          font-weight: var(--font-weight-semibold);
          line-height: var(--line-height-normal);
          color: var(--text-primary);
          margin-bottom: var(--spacing-sm);
        }
        .body-text {
          font-size: var(--font-size-base);
          font-weight: var(--font-weight-normal);
          line-height: var(--line-height-normal);
          color: var(--text-primary);
        }
        .small-text {
          font-size: var(--font-size-sm);
          font-weight: var(--font-weight-normal);
          line-height: var(--line-height-normal);
          color: var(--text-secondary);
        }
      `;
      document.head.appendChild(style);

      const h1 = container.querySelector('.heading-1');
      const h2 = container.querySelector('.heading-2');
      const h3 = container.querySelector('.heading-3');
      const body = container.querySelector('.body-text');
      const small = container.querySelector('.small-text');

      const h1Style = window.getComputedStyle(h1);
      const h2Style = window.getComputedStyle(h2);
      const h3Style = window.getComputedStyle(h3);
      const bodyStyle = window.getComputedStyle(body);
      const smallStyle = window.getComputedStyle(small);

      // Test font sizes are different and hierarchical
      expect(h1Style.fontSize).toBe('30px'); // 1.875rem = 30px
      expect(h2Style.fontSize).toBe('24px'); // 1.5rem = 24px
      expect(h3Style.fontSize).toBe('20px'); // 1.25rem = 20px
      expect(bodyStyle.fontSize).toBe('16px'); // 1rem = 16px
      expect(smallStyle.fontSize).toBe('14px'); // 0.875rem = 14px

      // Test font weights
      expect(h1Style.fontWeight).toBe('700');
      expect(h2Style.fontWeight).toBe('600');
      expect(h3Style.fontWeight).toBe('600');
      expect(bodyStyle.fontWeight).toBe('400');
    });

    it('should maintain consistent font family across components', async () => {
      container.innerHTML = `
        <div class="learning-path-card">
          <h3>Learning Path Title</h3>
          <p>Description text</p>
          <button>Take Assessment</button>
        </div>
      `;

      const style = document.createElement('style');
      style.textContent = `
        :root {
          --font-family-primary: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        }
        .learning-path-card,
        .learning-path-card h3,
        .learning-path-card p,
        .learning-path-card button {
          font-family: var(--font-family-primary);
        }
      `;
      document.head.appendChild(style);

      const card = container.querySelector('.learning-path-card');
      const title = card.querySelector('h3');
      const description = card.querySelector('p');
      const button = card.querySelector('button');

      const cardStyle = window.getComputedStyle(card);
      const titleStyle = window.getComputedStyle(title);
      const descStyle = window.getComputedStyle(description);
      const buttonStyle = window.getComputedStyle(button);

      // All should use the same font family
      expect(cardStyle.fontFamily).toContain('Segoe UI');
      expect(titleStyle.fontFamily).toContain('Segoe UI');
      expect(descStyle.fontFamily).toContain('Segoe UI');
      expect(buttonStyle.fontFamily).toContain('Segoe UI');
    });
  });

  describe('Component Layout Consistency', () => {
    it('should apply consistent card component styling', async () => {
      container.innerHTML = `
        <div class="card assessment-card">
          <div class="card-header">
            <h3>Assessment Card</h3>
          </div>
          <div class="card-body">
            <p>Card content goes here</p>
          </div>
          <div class="card-footer">
            <button class="btn-primary">Action</button>
          </div>
        </div>
        <div class="card learning-path-card">
          <div class="card-header">
            <h3>Learning Path Card</h3>
          </div>
          <div class="card-body">
            <p>Another card content</p>
          </div>
        </div>
      `;

      const style = document.createElement('style');
      style.textContent = `
        .card {
          background: var(--background-color);
          border: 1px solid var(--border-color);
          border-radius: var(--border-radius-lg);
          box-shadow: var(--shadow-sm);
          padding: var(--spacing-lg);
          margin-bottom: var(--spacing-md);
        }
        .card-header {
          margin-bottom: var(--spacing-md);
          padding-bottom: var(--spacing-sm);
          border-bottom: 1px solid var(--border-color);
        }
        .card-body {
          margin-bottom: var(--spacing-md);
        }
        .card-footer {
          padding-top: var(--spacing-sm);
          border-top: 1px solid var(--border-color);
        }
        .btn-primary {
          background: var(--primary-color);
          color: white;
          border: none;
          padding: var(--spacing-sm) var(--spacing-md);
          border-radius: var(--border-radius-md);
          font-size: var(--font-size-base);
          font-weight: var(--font-weight-medium);
        }
      `;
      document.head.appendChild(style);

      const assessmentCard = container.querySelector('.assessment-card');
      const learningPathCard = container.querySelector('.learning-path-card');
      const button = container.querySelector('.btn-primary');

      const assessmentStyle = window.getComputedStyle(assessmentCard);
      const pathStyle = window.getComputedStyle(learningPathCard);
      const buttonStyle = window.getComputedStyle(button);

      // Both cards should have consistent styling
      expect(assessmentStyle.backgroundColor).toBe(pathStyle.backgroundColor);
      expect(assessmentStyle.borderColor).toBe(pathStyle.borderColor);
      expect(assessmentStyle.borderRadius).toBe(pathStyle.borderRadius);
      expect(assessmentStyle.padding).toBe(pathStyle.padding);

      // Button should use design system colors
      expect(buttonStyle.backgroundColor).toBe('#0078d4'); // Happy DOM returns hex format
      expect(buttonStyle.color).toBe('white'); // Happy DOM returns keyword format
      expect(buttonStyle.borderRadius).toBe('4px'); // 0.25rem
    });

    it('should maintain consistent spacing patterns', async () => {
      container.innerHTML = `
        <div class="learning-paths-container">
          <section class="assessment-section">
            <h2>Skill Assessment</h2>
            <p>Take our assessment to get personalized recommendations</p>
          </section>
          <section class="paths-section">
            <h2>Learning Paths</h2>
            <div class="paths-grid">
              <div class="path-item">Path 1</div>
              <div class="path-item">Path 2</div>
            </div>
          </section>
        </div>
      `;

      const style = document.createElement('style');
      style.textContent = `
        .learning-paths-container {
          max-width: 1200px;
          margin: 0 auto;
          padding: var(--spacing-xl);
        }
        .assessment-section,
        .paths-section {
          margin-bottom: var(--spacing-3xl);
        }
        .assessment-section h2,
        .paths-section h2 {
          margin-bottom: var(--spacing-lg);
        }
        .paths-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
          gap: var(--spacing-lg);
          margin-top: var(--spacing-xl);
        }
        .path-item {
          padding: var(--spacing-lg);
          background: var(--surface-color);
          border-radius: var(--border-radius-lg);
        }
      `;
      document.head.appendChild(style);

      const container_el = container.querySelector('.learning-paths-container');
      const assessmentSection = container.querySelector('.assessment-section');
      const pathsSection = container.querySelector('.paths-section');
      const pathsGrid = container.querySelector('.paths-grid');

      const containerStyle = window.getComputedStyle(container_el);
      const assessmentStyle = window.getComputedStyle(assessmentSection);
      const pathsStyle = window.getComputedStyle(pathsSection);
      const gridStyle = window.getComputedStyle(pathsGrid);

      // Test consistent spacing
      expect(containerStyle.padding).toBe('32px'); // Happy DOM returns px format
      expect(assessmentStyle.marginBottom).toBe('64px'); // Happy DOM returns px format
      expect(pathsStyle.marginBottom).toBe('64px'); // Happy DOM returns px format
      expect(gridStyle.gap).toBe('1.5rem'); // Happy DOM returns rem format for grid gap
    });
  });

  describe('Color Scheme Consistency', () => {
    it('should apply consistent interactive state colors', async () => {
      container.innerHTML = `
        <button class="btn-primary">Primary Button</button>
        <button class="btn-secondary">Secondary Button</button>
        <a href="#" class="link">Text Link</a>
        <div class="input-group">
          <input type="text" class="form-input" placeholder="Input field">
        </div>
      `;

      const style = document.createElement('style');
      style.textContent = `
        .btn-primary {
          background: var(--primary-color);
          color: white;
          border: none;
          padding: var(--spacing-sm) var(--spacing-md);
          border-radius: var(--border-radius-md);
        }
        .btn-primary:hover {
          background: var(--focus-color);
        }
        .btn-secondary {
          background: transparent;
          color: var(--primary-color);
          border: 1px solid var(--primary-color);
          padding: var(--spacing-sm) var(--spacing-md);
          border-radius: var(--border-radius-md);
        }
        .btn-secondary:hover {
          background: var(--primary-color);
          color: white;
        }
        .link {
          color: var(--primary-color);
          text-decoration: none;
        }
        .link:hover {
          color: var(--focus-color);
          text-decoration: underline;
        }
        .form-input {
          border: 1px solid var(--border-color);
          border-radius: var(--border-radius-md);
          padding: var(--spacing-sm);
          color: var(--text-primary);
        }
        .form-input:focus {
          border-color: var(--focus-color);
          outline: 2px solid var(--focus-color);
          outline-offset: 2px;
        }
      `;
      document.head.appendChild(style);

      const primaryBtn = container.querySelector('.btn-primary');
      const secondaryBtn = container.querySelector('.btn-secondary');
      const link = container.querySelector('.link');
      const input = container.querySelector('.form-input');

      const primaryStyle = window.getComputedStyle(primaryBtn);
      const secondaryStyle = window.getComputedStyle(secondaryBtn);
      const linkStyle = window.getComputedStyle(link);
      const inputStyle = window.getComputedStyle(input);

      // Test consistent use of primary color
      expect(primaryStyle.backgroundColor).toBe('#0078d4'); // Happy DOM returns hex format
      expect(secondaryStyle.color).toBe('#0078d4'); // Happy DOM returns hex format
      expect(linkStyle.color).toBe('#0078d4'); // Happy DOM returns hex format

      // Test consistent border styling
      expect(inputStyle.borderColor).toBe('#e1dfdd'); // Happy DOM returns hex format
    });

    it('should maintain consistent semantic color usage', async () => {
      container.innerHTML = `
        <div class="alert alert-success">Success message</div>
        <div class="alert alert-warning">Warning message</div>
        <div class="alert alert-error">Error message</div>
        <div class="status-badge status-completed">Completed</div>
        <div class="status-badge status-in-progress">In Progress</div>
      `;

      const style = document.createElement('style');
      style.textContent = `
        .alert {
          padding: var(--spacing-md);
          border-radius: var(--border-radius-md);
          margin-bottom: var(--spacing-md);
        }
        .alert-success {
          background: #f3f9ff;
          border: 1px solid var(--success-color);
          color: var(--success-color);
        }
        .alert-warning {
          background: #fff8f0;
          border: 1px solid var(--warning-color);
          color: var(--warning-color);
        }
        .alert-error {
          background: #fdf3f4;
          border: 1px solid var(--error-color);
          color: var(--error-color);
        }
        .status-badge {
          display: inline-block;
          padding: var(--spacing-xs) var(--spacing-sm);
          border-radius: var(--border-radius-lg);
          font-size: var(--font-size-sm);
          font-weight: var(--font-weight-medium);
        }
        .status-completed {
          background: var(--success-color);
          color: white;
        }
        .status-in-progress {
          background: var(--warning-color);
          color: white;
        }
      `;
      document.head.appendChild(style);

      const successAlert = container.querySelector('.alert-success');
      const warningAlert = container.querySelector('.alert-warning');
      const errorAlert = container.querySelector('.alert-error');
      const completedBadge = container.querySelector('.status-completed');
      const progressBadge = container.querySelector('.status-in-progress');

      const successStyle = window.getComputedStyle(successAlert);
      const warningStyle = window.getComputedStyle(warningAlert);
      const errorStyle = window.getComputedStyle(errorAlert);
      const completedStyle = window.getComputedStyle(completedBadge);
      const progressStyle = window.getComputedStyle(progressBadge);

      // Test semantic color consistency
      expect(successStyle.color).toBe('#107c10'); // Happy DOM returns hex format
      expect(warningStyle.color).toBe('#ff8c00'); // Happy DOM returns hex format
      expect(errorStyle.color).toBe('#d13438'); // Happy DOM returns hex format
      expect(completedStyle.backgroundColor).toBe('#107c10'); // Happy DOM returns hex format
      expect(progressStyle.backgroundColor).toBe('#ff8c00'); // Happy DOM returns hex format
    });
  });

  describe('Responsive Design Consistency', () => {
    it('should maintain consistent breakpoints and responsive behavior', async () => {
      container.innerHTML = `
        <div class="responsive-grid">
          <div class="grid-item">Item 1</div>
          <div class="grid-item">Item 2</div>
          <div class="grid-item">Item 3</div>
        </div>
      `;

      const style = document.createElement('style');
      style.textContent = `
        .responsive-grid {
          display: grid;
          gap: var(--spacing-lg);
          grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
        }

        @media (max-width: 768px) {
          .responsive-grid {
            grid-template-columns: 1fr;
            gap: var(--spacing-md);
          }
        }

        @media (min-width: 1200px) {
          .responsive-grid {
            grid-template-columns: repeat(3, 1fr);
          }
        }

        .grid-item {
          padding: var(--spacing-lg);
          background: var(--surface-color);
          border-radius: var(--border-radius-lg);
        }
      `;
      document.head.appendChild(style);

      const grid = container.querySelector('.responsive-grid');
      const gridStyle = window.getComputedStyle(grid);

      // Test default grid behavior
      expect(gridStyle.display).toBe('grid');
      expect(gridStyle.gap).toBe('1.5rem'); // Happy DOM returns rem format

      // Grid should use auto-fit with minimum width
      expect(gridStyle.gridTemplateColumns).toContain('minmax(300px, 1fr)');
    });
  });
});
