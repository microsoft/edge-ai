/**
 * CSS Testing Utilities
 * Specialized helpers f/**
 * Load CSS file into test environment
 * @param {string} cssFilePath - Path to CSS file (relative to /assets/css/)
 * @param {string} [id='test-css-file'] - Optional ID for the link element
 * @returns {Promise<HTMLLinkElement>} Promise that resolves to the link element
 */
export async function loadCSSFile(cssFilePath, id = 'test-css-file') {
  return new Promise((resolve, reject) => {
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = `/assets/css/${cssFilePath}`;
    link.id = id;
    link.setAttribute('data-test', 'true');

    link.onload = () => resolve(link);
    link.onerror = () => reject(new Error(`Failed to load CSS: ${cssFilePath}`));

    document.head.appendChild(link);
  });
}

/**
 * CSS Testing Utilities for Vitest + Happy DOM
 * Provides utilities for testing CSS behavior, design tokens, and component styling
 */

/**
 * Load CSS content into the test DOM environment
 * @param {string} cssContent - CSS content to inject
 * @param {string} [id='test-styles'] - Optional ID for the style element
 * @returns {HTMLStyleElement} The created style element
 */

/**
 * Get all CSS custom properties from an element
 * @param {HTMLElement|null} element - Element to inspect, null creates test div in body
 * @returns {Object} Object with all custom properties
 */
export function getAllCSSCustomProperties(element) {
  // Always check documentElement first for :root properties
  const rootStyle = window.getComputedStyle(document.documentElement);
  const customProperties = {};

  // Get all custom properties from :root
  for (let i = 0; i < rootStyle.length; i++) {
    const property = rootStyle[i];
    if (property.startsWith('--')) {
      customProperties[property] = rootStyle.getPropertyValue(property).trim();
    }
  }

  // If element is provided and not documentElement, also check element-specific properties
  if (element && element !== document.documentElement) {
    const computedStyle = window.getComputedStyle(element);
    for (let i = 0; i < computedStyle.length; i++) {
      const property = computedStyle[i];
      if (property.startsWith('--')) {
        const value = computedStyle.getPropertyValue(property).trim();
        if (value) {
          customProperties[property] = value;
        }
      }
    }
  }

  return customProperties;
}

/**
 * Inject CSS into the test document
 * @param {string} cssContent - CSS content to inject
 * @param {string} [id='test-styles'] - Optional ID for the style element
 * @returns {HTMLStyleElement} The created style element
 */
export function injectCSS(cssContent, id = 'test-styles') {
  const styleElement = document.createElement('style');
  styleElement.type = 'text/css';
  styleElement.id = id;
  styleElement.setAttribute('data-test', 'true');
  styleElement.textContent = cssContent;
  document.head.appendChild(styleElement);
  return styleElement;
}

/**
 * Get computed CSS custom property value
 * @param {HTMLElement} element - Element to inspect
 * @param {string} propertyName - CSS custom property name (with or without --)
 * @returns {string} The computed property value
 */
/**
 * Get CSS custom property value with proper inheritance handling
 * Checks both the element and its computed style to get the effective value
 * @param {HTMLElement} element - Element to check (defaults to a test div in body)
 * @param {string} propertyName - CSS custom property name
 * @returns {string} The computed property value
 */
export function getCSSCustomProperty(element = null, propertyName) {
  const propName = propertyName.startsWith('--') ? propertyName : `--${propertyName}`;

  // If no element provided, create a test div inside body to get inherited values
  // This ensures dark mode values from body.dark are properly inherited
  if (!element) {
    const testDiv = document.createElement('div');
    document.body.appendChild(testDiv);
    const value = getCSSCustomProperty(testDiv, propertyName);
    document.body.removeChild(testDiv);
    return value;
  }

  // Get computed style from element (which will include inheritance from body.dark)
  const computedStyle = window.getComputedStyle(element);
  const elementValue = computedStyle.getPropertyValue(propName).trim();

  // If element has the property, return it
  if (elementValue) {
    return elementValue;
  }

  // Fallback to documentElement only if no inherited value found
  const rootValue = window.getComputedStyle(document.documentElement).getPropertyValue(propName).trim();
  return rootValue;
}

/**
 * Alias for getCSSCustomProperty for backward compatibility
 * @param {HTMLElement} element - Element to check
 * @param {string} propertyName - CSS custom property name or regular CSS property
 * @returns {string} The computed property value
 */
export function getCSSProperty(element, propertyName) {
  if (propertyName.startsWith('--')) {
    return getCSSCustomProperty(element, propertyName);
  } else {
    const computedStyle = window.getComputedStyle(element);
    return computedStyle.getPropertyValue(propertyName).trim();
  }
}

/**
 * Set CSS custom property on element
 * @param {HTMLElement} element - Element to modify
 * @param {string} propertyName - CSS custom property name
 * @param {string} value - Property value
 */
export function setCSSCustomProperty(element, propertyName, value) {
  const propName = propertyName.startsWith('--') ? propertyName : `--${propertyName}`;
  element.style.setProperty(propName, value);
}

/**
 * Helper function to normalize color values for comparison
 * Converts RGB/RGBA to hex format for consistent comparison
 * @param {string} value - Color value to normalize
 * @returns {string} Normalized color value (hex format)
 */
export function normalizeColor(value) {
  if (!value) {return value;}

  // If it's already a hex color, return as-is
  if (typeof value === 'string' && value.startsWith('#')) {
    return value.toLowerCase();
  }

  // Convert rgb() to hex
  if (typeof value === 'string' && value.startsWith('rgb(')) {
    const match = value.match(/rgb\(([^)]+)\)/);
    if (match) {
      const [r, g, b] = match[1].split(',').map(p => parseInt(p.trim(), 10));
      return `#${((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1)}`;
    }
  }

  // Convert rgba() to hex (ignore alpha)
  if (typeof value === 'string' && value.startsWith('rgba(')) {
    const match = value.match(/rgba?\(([^)]+)\)/);
    if (match) {
      const parts = match[1].split(',').map(p => p.trim());
      const [r, g, b] = parts.map(p => parseInt(p, 10));
      return `#${((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1)}`;
    }
  }

  return value;
}

/**
 * Simulate media query for responsive testing
 * Note: This is a basic simulation that sets CSS classes
 * @param {string} mediaQuery - Media query string
 */
export function simulateMediaQuery(mediaQuery) {
  // Remove existing media query classes
  document.body.classList.remove('media-mobile', 'media-tablet', 'media-desktop', 'media-print');

  // Add appropriate class based on media query
  if (mediaQuery.includes('max-width: 768px') || mediaQuery.includes('max-width: 767px')) {
    document.body.classList.add('media-mobile');
  } else if (mediaQuery.includes('max-width: 1024px') || mediaQuery.includes('max-width: 1023px')) {
    document.body.classList.add('media-tablet');
  } else if (mediaQuery === 'print') {
    document.body.classList.add('media-print');
  } else {
    document.body.classList.add('media-desktop');
  }
}

/**
 * Toggle dark mode on document body
 * @param {boolean} isDark - Whether to enable dark mode
 */
export function toggleDarkMode(isDark = true) {
  if (isDark) {
    document.body.classList.add('dark');
  } else {
    document.body.classList.remove('dark');
  }
}

/**
 * Create a test container with specified classes and content
 * @param {Object} options - Container options
 * @param {string} options.className - CSS classes to apply
 * @param {string} options.innerHTML - HTML content
 * @param {string} options.id - Element ID
 * @returns {HTMLElement} The created container
 */
export function createTestContainer({ className = '', innerHTML = '', id = 'test-container' } = {}) {
  const container = document.createElement('div');
  container.id = id;
  container.className = className;
  container.innerHTML = innerHTML;
  container.setAttribute('data-test', 'true');
  document.body.appendChild(container);
  return container;
}

/**
 * Simulate viewport size change
 * @param {number} width - Viewport width
 * @param {number} height - Viewport height
 */
export function setViewportSize(width, height) {
  // Mock window dimensions
  Object.defineProperty(window, 'innerWidth', {
    writable: true,
    configurable: true,
    value: width
  });

  Object.defineProperty(window, 'innerHeight', {
    writable: true,
    configurable: true,
    value: height
  });

  // Trigger resize event
  window.dispatchEvent(new Event('resize'));
}

/**
 * Check if element matches expected CSS properties
 * Handles conversion between hex colors and computed RGB values
 * @param {HTMLElement} element - Element to inspect
 * @param {Object} expectedStyles - Object with CSS property/value pairs
 * @returns {Object} Results with matches and mismatches
 */
export function validateElementStyles(element, expectedStyles) {
  const computedStyle = window.getComputedStyle(element);
  const results = {
    matches: {},
    mismatches: {},
    allMatch: true
  };

  // Helper function to convert hex to rgb format for comparison
  const hexToRgb = (hex) => {
    if (!hex || !hex.startsWith('#')) {return hex;}
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgb(${r}, ${g}, ${b})`;
  };

  // Helper function to normalize color values for comparison
  const normalizeColorLocal = (value) => {
    if (!value) {return value;}

    // Convert RGB to hex for consistent comparison
    if (typeof value === 'string' && value.startsWith('rgb(')) {
      const match = value.match(/rgb\(([^)]+)\)/);
      if (match) {
        const [r, g, b] = match[1].split(',').map(p => parseInt(p.trim(), 10));
        return `#${((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1)}`;
      }
    }

    // Convert RGBA to hex (ignore alpha)
    if (typeof value === 'string' && value.startsWith('rgba(')) {
      const match = value.match(/rgba?\(([^)]+)\)/);
      if (match) {
        const parts = match[1].split(',').map(p => p.trim());
        const [r, g, b] = parts.map(p => parseInt(p, 10));
        return `#${((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1)}`;
      }
    }

    // If it's already hex, normalize to lowercase
    if (typeof value === 'string' && value.startsWith('#')) {
      return value.toLowerCase();
    }

    return value;
  };

  for (const [property, expectedValue] of Object.entries(expectedStyles)) {
    const actualValue = computedStyle.getPropertyValue(property).trim();

    // Normalize both values for comparison
    const normalizedExpected = normalizeColorLocal(expectedValue);
    const normalizedActual = normalizeColorLocal(actualValue);

    if (normalizedActual === normalizedExpected) {
      results.matches[property] = actualValue;
    } else {
      results.mismatches[property] = {
        expected: expectedValue,
        actual: actualValue,
        normalizedExpected,
        normalizedActual
      };
      results.allMatch = false;
    }
  }

  return results;
}

/**
 * Wait for CSS to fully load and apply
 * @param {number} timeout - Maximum wait time in ms (reduced default)
 * @returns {Promise<void>}
 */
export async function waitForCSS(timeout = 1000) {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();

    function checkCSS() {
      // Check if all stylesheets are loaded
      const stylesheets = Array.from(document.styleSheets);
      const allLoaded = stylesheets.every(sheet => {
        try {
          // Accessing cssRules triggers loading completion
          return sheet.cssRules !== null;
        } catch (_e) {
          // Cross-origin sheets might throw, consider them loaded
          return true;
        }
      });

      if (allLoaded) {
        resolve();
      } else if (Date.now() - startTime > timeout) {
        // Don't reject in test environment, just resolve to prevent hanging
        resolve();
      } else {
        setTimeout(checkCSS, 10); // Reduced check interval
      }
    }

    checkCSS();
  });
}

/**
 * Test responsive behavior at different breakpoints
 * @param {HTMLElement} element - Element to test
 * @param {Array} breakpoints - Array of {width, height, name} objects
 * @param {Function} testCallback - Function to run at each breakpoint
 * @returns {Array} Array of test results
 */
export async function testResponsiveBehavior(element, breakpoints, testCallback) {
  const results = [];

  for (const breakpoint of breakpoints) {
    setViewportSize(breakpoint.width, breakpoint.height);

    // Removed setTimeout to prevent hanging - styles apply synchronously in test environment
    // await new Promise(resolve => setTimeout(resolve, 100));

    const result = await testCallback(element, breakpoint);
    results.push({
      breakpoint: breakpoint.name,
      width: breakpoint.width,
      height: breakpoint.height,
      result
    });
  }

  return results;
}

/**
 * Clean up all test CSS and DOM elements
 */
export function cleanupCSSTesting() {
  // Remove test stylesheets
  const testStyles = document.querySelectorAll('style[data-test], link[data-test]');
  testStyles.forEach(style => style.remove());

  // Remove test elements
  const testElements = document.querySelectorAll('[data-test]');
  testElements.forEach(element => element.remove());

  // Reset dark mode
  document.body.classList.remove('dark');

  // Reset viewport
  if (window.innerWidth !== 1024 || window.innerHeight !== 768) {
    setViewportSize(1024, 768);
  }
}

/**
 * Check if a CSS property is valid and has a value
 * @param {HTMLElement} element - Element to inspect
 * @param {string} property - CSS property name
 * @returns {boolean} True if property exists and has a non-empty value
 */
export function isValidCSSProperty(element, property) {
  const value = getCSSProperty(element, property);
  return value !== '' && value !== 'initial' && value !== 'inherit';
}
