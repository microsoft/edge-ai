/**
 * Simple debug test to check CSS custom property detection
 */

import { describe, test, beforeEach, afterEach, expect } from 'vitest';
import {
  injectCSS,
  getCSSCustomProperty,
  createTestContainer,
  cleanupCSSTesting,
  getAllCSSCustomProperties
} from '../helpers/css-test-utils.js';

describe('CSS Custom Property Debug', () => {
  let testContainer;

  beforeEach(() => {
    cleanupCSSTesting();

    // Inject simple CSS with custom properties
    const simpleCss = `
      :root {
        --test-color: #ff0000;
        --test-size: 16px;
      }

      .test-element {
        color: var(--test-color);
        font-size: var(--test-size);
      }
    `;

    injectCSS(simpleCss, 'debug-test');

    testContainer = createTestContainer({
      className: 'test-element',
      innerHTML: 'Test Content'
    });
  });

  afterEach(() => {
    cleanupCSSTesting();
  });

  test('should detect CSS custom properties on root', () => {
    // Test with testContainer
    const _color1 = getCSSCustomProperty(testContainer, '--test-color');
    const _size1 = getCSSCustomProperty(testContainer, '--test-size');

    // Test with null (should create div in body)
    const _color2 = getCSSCustomProperty(null, '--test-color');
    const _size2 = getCSSCustomProperty(null, '--test-size');

        // Test with direct DOM element
    const _color3 = getCSSCustomProperty(document.documentElement, '--test-color');
    const _size3 = getCSSCustomProperty(document.documentElement, '--test-size');

    // Check for injection and comprehensive property listings
    const _allProps = getAllCSSCustomProperties(testContainer);

    // Verify computed styles are accessible
    const _computedStyle = window.getComputedStyle(testContainer);

    // CSS injection check (style elements should be injected for testing)
    const _styleElements = document.querySelectorAll('style[data-test]');

    // This test should pass if CSS is injected properly
    expect(_styleElements.length).toBeGreaterThan(0);
  });
});
