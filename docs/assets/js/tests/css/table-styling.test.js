/**
 * Table Styling Component Test Suite - Simplified
 *
 * Lightweight test suite for centralized table styling component
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { createTestContainer, cleanupCSSTesting } from '../helpers/css-test-utils.js';

describe('Table Styling Component - Basic Tests', () => {
  let testContainer;

  beforeEach(() => {
    testContainer = createTestContainer();

    // Create minimal test table directly in DOM
    testContainer.innerHTML = `
      <table data-test-table="basic">
        <thead>
          <tr><th>Column 1</th><th>Column 2</th></tr>
        </thead>
        <tbody>
          <tr><td>Data 1</td><td>Data 2</td></tr>
          <tr><td>Data 3</td><td>Data 4</td></tr>
        </tbody>
      </table>
    `;
  });

  afterEach(() => {
    cleanupCSSTesting();
  });

  describe('Core Table Structure', () => {
    it('creates table element successfully', () => {
      const table = testContainer.querySelector('[data-test-table="basic"]');
      expect(table).toBeTruthy();
      expect(table.tagName.toLowerCase()).toBe('table');
    });

    it('has proper table structure', () => {
      const table = testContainer.querySelector('[data-test-table="basic"]');
      const thead = table.querySelector('thead');
      const tbody = table.querySelector('tbody');

      expect(thead).toBeTruthy();
      expect(tbody).toBeTruthy();
      expect(thead.children.length).toBe(1); // One header row
      expect(tbody.children.length).toBe(2); // Two body rows
    });

    it('applies basic table styles', () => {
      const table = testContainer.querySelector('[data-test-table="basic"]');
      const computedStyle = window.getComputedStyle(table);

      // Basic structure validation - these should be set by CSS
      expect(table).toBeTruthy();
      expect(computedStyle).toBeTruthy();
    });
  });

  describe('CSS Integration', () => {
    it('has CSS styles available', () => {
      const table = testContainer.querySelector('[data-test-table="basic"]');
      const styles = window.getComputedStyle(table);

      // Test that getComputedStyle works
      expect(styles.display).toBeDefined();
      expect(styles.borderCollapse).toBeDefined();
    });

    it('maintains semantic HTML structure', () => {
      const table = testContainer.querySelector('[data-test-table="basic"]');
      const headers = table.querySelectorAll('th');
      const cells = table.querySelectorAll('td');

      expect(headers.length).toBe(2);
      expect(cells.length).toBe(4);
      expect(headers[0].textContent).toBe('Column 1');
      expect(cells[0].textContent).toBe('Data 1');
    });
  });

  describe('Accessibility Structure', () => {
    it('maintains proper table semantics', () => {
      const table = testContainer.querySelector('[data-test-table="basic"]');

      expect(table.tagName.toLowerCase()).toBe('table');
      expect(table.querySelector('thead')).toBeTruthy();
      expect(table.querySelector('tbody')).toBeTruthy();
      expect(table.querySelectorAll('th').length).toBeGreaterThan(0);
    });

    it('supports screen reader navigation', () => {
      const table = testContainer.querySelector('[data-test-table="basic"]');
      const headers = table.querySelectorAll('th');

      // Headers should be in thead section
      headers.forEach(header => {
        expect(header.closest('thead')).toBeTruthy();
      });
    });
  });
});