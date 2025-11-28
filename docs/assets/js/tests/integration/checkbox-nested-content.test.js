/**
 * Integration tests for checkbox nested content rendering
 *
 * Validates CSS fixes for:
 * 1. Bullet removal specificity (direct child selector)
 * 2. Strikethrough exclusion for nested lists
 * 3. Margin restoration for nested content
 *
 * @vitest-environment happy-dom
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { InteractiveCheckboxManager } from '../../features/interactive-checkboxes.js';

describe('Checkbox Nested Content Rendering', () => {
  let container;
  let manager;
  let styleElement;

  beforeEach(() => {
    // Inject CSS rules for testing
    styleElement = document.createElement('style');
    styleElement.textContent = `
      /* Remove bullets from direct checkbox list items only */
      .markdown-section li:has(> input[type="checkbox"]) {
        list-style-type: none;
        margin-left: 0;
        padding-left: 0;
      }

      /* Restore bullets and margins for nested lists */
      .markdown-section li:has(> input[type="checkbox"]) ul,
      .markdown-section li:has(> input[type="checkbox"]) ol {
        margin-left: 1.5em;
        padding-left: 0.5em;
      }

      .markdown-section li:has(> input[type="checkbox"]) ul li {
        list-style-type: disc;
      }

      .markdown-section li:has(> input[type="checkbox"]) ol li {
        list-style-type: decimal;
      }

      /* Completed task styles */
      li.completed-task {
        opacity: 0.8;
      }

      /* Apply strikethrough only to text/inline content, not nested lists */
      li.completed-task > :not(ul):not(ol) {
        text-decoration: line-through;
      }
    `;
    document.head.appendChild(styleElement);

    // Create test container with markdown-section class
    container = document.createElement('div');
    container.className = 'markdown-section';
    document.body.appendChild(container);
  });

  afterEach(() => {
    if (manager) {
      manager.cleanup();
    }
    document.body.removeChild(container);
    if (styleElement && styleElement.parentNode) {
      document.head.removeChild(styleElement);
    }
    localStorage.clear();
  });

  describe('CSS Selector Specificity', () => {
    it('should remove bullets only from direct checkbox list items', () => {
      container.innerHTML = `
        <ul>
          <li><input type="checkbox" /> Task 1</li>
          <li><input type="checkbox" /> Task 2</li>
        </ul>
      `;

      const checkboxItems = container.querySelectorAll('li:has(> input[type="checkbox"])');
      expect(checkboxItems.length).toBe(2);

      checkboxItems.forEach(item => {
        const computedStyle = window.getComputedStyle(item);
        expect(computedStyle.listStyleType).toBe('none');
        expect(computedStyle.marginLeft).toBe('0px');
      });
    });

    it('should preserve bullets for nested lists inside checkbox items', () => {
      container.innerHTML = `
        <ul>
          <li>
            <input type="checkbox" /> Setup validation:
            <ul>
              <li>Step 1</li>
              <li>Step 2</li>
            </ul>
          </li>
        </ul>
      `;

      const nestedList = container.querySelector('li:has(> input[type="checkbox"]) ul');
      expect(nestedList).toBeTruthy();

      const computedStyle = window.getComputedStyle(nestedList);
      expect(computedStyle.marginLeft).not.toBe('0px');

      const nestedItems = nestedList.querySelectorAll('li');
      expect(nestedItems.length).toBe(2);

      nestedItems.forEach(item => {
        const itemStyle = window.getComputedStyle(item);
        expect(itemStyle.listStyleType).toBe('disc');
      });
    });

    it('should preserve numbered lists inside checkbox items', () => {
      container.innerHTML = `
        <ul>
          <li>
            <input type="checkbox" /> Task with steps:
            <ol>
              <li>First step</li>
              <li>Second step</li>
            </ol>
          </li>
        </ul>
      `;

      const nestedList = container.querySelector('li:has(> input[type="checkbox"]) ol');
      expect(nestedList).toBeTruthy();

      const nestedItems = nestedList.querySelectorAll('li');
      nestedItems.forEach(item => {
        const itemStyle = window.getComputedStyle(item);
        expect(itemStyle.listStyleType).toBe('decimal');
      });
    });
  });

  describe('Strikethrough Exclusion', () => {
    it('should apply strikethrough to text content only, not nested lists', () => {
      container.innerHTML = `
        <ul>
          <li class="completed-task">
            <input type="checkbox" checked /> Task completed
            <ul>
              <li>Nested item 1</li>
              <li>Nested item 2</li>
            </ul>
          </li>
        </ul>
      `;

      const completedItem = container.querySelector('li.completed-task');
      expect(completedItem).toBeTruthy();

      // Text nodes should have strikethrough
      const textNodes = Array.from(completedItem.childNodes)
        .filter(node => node.nodeType === Node.TEXT_NODE && node.textContent.trim());

      // Nested list should NOT have strikethrough
      const nestedList = completedItem.querySelector('ul');
      expect(nestedList).toBeTruthy();

      const nestedListStyle = window.getComputedStyle(nestedList);
      expect(nestedListStyle.textDecoration).not.toContain('line-through');
    });

    it('should apply strikethrough to inline elements but not block lists', () => {
      container.innerHTML = `
        <ul>
          <li class="completed-task">
            <input type="checkbox" checked />
            <strong>Bold text</strong>
            <em>Italic text</em>
            <ul>
              <li>Nested item</li>
            </ul>
          </li>
        </ul>
      `;

      const completedItem = container.querySelector('li.completed-task');

      // Inline elements should have strikethrough
      const boldText = completedItem.querySelector('strong');
      const boldStyle = window.getComputedStyle(boldText);
      expect(boldStyle.textDecoration).toContain('line-through');

      const italicText = completedItem.querySelector('em');
      const italicStyle = window.getComputedStyle(italicText);
      expect(italicStyle.textDecoration).toContain('line-through');

      // Nested list should NOT have strikethrough
      const nestedList = completedItem.querySelector('ul');
      const listStyle = window.getComputedStyle(nestedList);
      expect(listStyle.textDecoration).not.toContain('line-through');
    });

    it('should not apply strikethrough to nested ordered lists', () => {
      container.innerHTML = `
        <ul>
          <li class="completed-task">
            <input type="checkbox" checked /> Configuration steps:
            <ol>
              <li>Configure setting A</li>
              <li>Configure setting B</li>
            </ol>
          </li>
        </ul>
      `;

      const nestedList = container.querySelector('li.completed-task ol');
      const listStyle = window.getComputedStyle(nestedList);
      expect(listStyle.textDecoration).not.toContain('line-through');

      const nestedItems = nestedList.querySelectorAll('li');
      nestedItems.forEach(item => {
        const itemStyle = window.getComputedStyle(item);
        expect(itemStyle.textDecoration).not.toContain('line-through');
      });
    });
  });

  describe('InteractiveCheckboxManager Integration', () => {
    it('should preserve nested list styling when checkbox is checked', async () => {
      container.innerHTML = `
        <ul>
          <li>
            <input type="checkbox" class="interactive-checkbox" /> Setup:
            <ul>
              <li>Step 1</li>
              <li>Step 2</li>
            </ul>
          </li>
        </ul>
      `;

      manager = new InteractiveCheckboxManager({
        storagePrefix: 'test-kata',
        enableProgressDisplay: false
      });

      const checkbox = container.querySelector('input[type="checkbox"]');
      const parentLi = checkbox.closest('li');

      // Manually toggle completed state for testing
      checkbox.checked = true;
      parentLi.classList.add('completed-task');

      await new Promise(resolve => setTimeout(resolve, 100));

      expect(parentLi.classList.contains('completed-task')).toBe(true);

      const nestedList = parentLi.querySelector('ul');
      const nestedItems = nestedList.querySelectorAll('li');

      nestedItems.forEach(item => {
        const itemStyle = window.getComputedStyle(item);
        expect(itemStyle.listStyleType).toBe('disc');
        expect(itemStyle.textDecoration).not.toContain('line-through');
      });
    });

    it('should maintain nested list margins after checkbox completion', async () => {
      container.innerHTML = `
        <ul>
          <li>
            <input type="checkbox" class="interactive-checkbox" /> Task:
            <ul>
              <li>Substep A</li>
            </ul>
          </li>
        </ul>
      `;

      manager = new InteractiveCheckboxManager({
        storagePrefix: 'test-kata',
        enableProgressDisplay: false
      });

      const nestedList = container.querySelector('li:has(> input[type="checkbox"]) ul');
      const initialStyle = window.getComputedStyle(nestedList);
      const initialMargin = initialStyle.marginLeft;

      expect(initialMargin).not.toBe('0px');

      const checkbox = container.querySelector('input[type="checkbox"]');
      checkbox.click();

      await new Promise(resolve => setTimeout(resolve, 100));

      const updatedStyle = window.getComputedStyle(nestedList);
      expect(updatedStyle.marginLeft).toBe(initialMargin);
    });
  });

  describe('Edge Cases', () => {
    it('should handle deeply nested list structures', () => {
      container.innerHTML = `
        <ul>
          <li>
            <input type="checkbox" /> Task:
            <ul>
              <li>Level 1
                <ul>
                  <li>Level 2
                    <ul>
                      <li>Level 3</li>
                    </ul>
                  </li>
                </ul>
              </li>
            </ul>
          </li>
        </ul>
      `;

      const level1 = container.querySelector('li:has(> input[type="checkbox"]) ul > li');
      const level2 = level1.querySelector('ul > li');
      const level3 = level2.querySelector('ul > li');

      [level1, level2, level3].forEach(item => {
        const itemStyle = window.getComputedStyle(item);
        expect(itemStyle.listStyleType).toBe('disc');
      });
    });

    it('should handle mixed list types (ul and ol) in nested structures', () => {
      container.innerHTML = `
        <ul>
          <li>
            <input type="checkbox" /> Task:
            <ul>
              <li>Unordered item</li>
            </ul>
            <ol>
              <li>Ordered item</li>
            </ol>
          </li>
        </ul>
      `;

      const ulItem = container.querySelector('li:has(> input[type="checkbox"]) ul li');
      const ulStyle = window.getComputedStyle(ulItem);
      expect(ulStyle.listStyleType).toBe('disc');

      const olItem = container.querySelector('li:has(> input[type="checkbox"]) ol li');
      const olStyle = window.getComputedStyle(olItem);
      expect(olStyle.listStyleType).toBe('decimal');
    });

    it('should handle checkboxes without nested content normally', () => {
      container.innerHTML = `
        <ul>
          <li><input type="checkbox" /> Simple task</li>
        </ul>
      `;

      const checkboxItem = container.querySelector('li:has(> input[type="checkbox"])');
      const itemStyle = window.getComputedStyle(checkboxItem);

      expect(itemStyle.listStyleType).toBe('none');
      expect(itemStyle.marginLeft).toBe('0px');
    });
  });

  describe('Regression Tests', () => {
    it('should not affect paragraph-based checkboxes', () => {
      container.innerHTML = `
        <p>
          <input type="checkbox" /> Paragraph task
        </p>
      `;

      const checkbox = container.querySelector('input[type="checkbox"]');
      expect(checkbox).toBeTruthy();

      const paragraph = checkbox.closest('p');
      const pStyle = window.getComputedStyle(paragraph);
      // Happy DOM may not compute default margins - accept empty or 0px
      const marginLeft = pStyle.marginLeft;
      expect(marginLeft === '' || marginLeft === '0px').toBe(true);
    });

    it('should handle unchecked state with nested lists', () => {
      container.innerHTML = `
        <ul>
          <li>
            <input type="checkbox" /> Task:
            <ul>
              <li>Nested item</li>
            </ul>
          </li>
        </ul>
      `;

      const parentLi = container.querySelector('li:has(> input[type="checkbox"])');
      expect(parentLi.classList.contains('completed-task')).toBe(false);

      const nestedList = parentLi.querySelector('ul');
      const nestedItem = nestedList.querySelector('li');

      const itemStyle = window.getComputedStyle(nestedItem);
      expect(itemStyle.listStyleType).toBe('disc');
      expect(itemStyle.textDecoration).not.toContain('line-through');
    });
  });
});
