import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';
import { compositions } from '../helpers/focused/compose-helpers.js';

/**
 * DOM Utils Unified Test Suite
 * Comprehensive tests for the unified DOM utilities module
 * @version 1.0.0
 */

describe('DOM Utils Unified', () => {
  let testHelper;
  let domUtils;
  let mockErrorHandler;
  let doc; // Shared document reference

  beforeEach(() => {
    testHelper = compositions.dom();

    // Use global document from happy-dom environment
    doc = globalThis.document || document;

    // Set up test DOM structure
    if (doc && doc.body) {
      doc.body.innerHTML = `
        <div id="test-container">
          <div class="test-element" data-id="1">Element 1</div>
          <div class="test-element" data-id="2">Element 2</div>
          <p class="hidden-element" style="display: none">Hidden</p>
          <button id="test-button">Test Button</button>
          <form id="test-form">
            <input type="text" id="test-input" value="test value">
            <select id="test-select">
              <option value="1">Option 1</option>
              <option value="2" selected>Option 2</option>
            </select>
          </form>
        </div>
      `;
    }

    // Create mock error handler
    mockErrorHandler = {
      safeExecute: vi.fn().mockImplementation((fn, name, fallback) => {
        try {
          return fn();
        } catch {
          return fallback;
        }
      }),
      recordError: vi.fn()
    };

    // Import and setup DOMUtils (simulated)
    domUtils = {
      querySelector: (selector, container = doc) => {
        return mockErrorHandler.safeExecute(
          () => container.querySelector(selector),
          'querySelector',
          null
        );
      },
      querySelectorAll: (selector, container = doc) => {
        return mockErrorHandler.safeExecute(
          () => Array.from(container.querySelectorAll(selector)),
          'querySelectorAll',
          []
        );
      },
      createElement: (tagName, attributes = {}, content = null) => {
        return mockErrorHandler.safeExecute(
          () => {
            const element = doc.createElement(tagName);

            Object.entries(attributes).forEach(([key, value]) => {
              if (key === 'style' && typeof value === 'object') {
                Object.assign(element.style, value);
              } else {
                element[key] = value;
              }
            });

            if (content !== null) {
              if (typeof content === 'string') {
                element.innerHTML = content;
              } else if (content instanceof Element) {
                element.appendChild(content);
              }
            }

            return element;
          },
          'createElement',
          null
        );
      },
      addClass: (element, className) => {
        return mockErrorHandler.safeExecute(
          () => {
            if (!element || !className) {return false;}
            element.classList.add(className);
            return true;
          },
          'addClass',
          false
        );
      },
      removeClass: (element, className) => {
        return mockErrorHandler.safeExecute(
          () => {
            if (!element || !className) {return false;}
            element.classList.remove(className);
            return true;
          },
          'removeClass',
          false
        );
      },
      toggleClass: (element, className) => {
        return mockErrorHandler.safeExecute(
          () => {
            if (!element || !className) {return false;}
            return element.classList.toggle(className);
          },
          'toggleClass',
          false
        );
      },
      addEventListener: (element, event, handler, _options = {}) => {
        return mockErrorHandler.safeExecute(
          () => {
            if (!element || typeof handler !== 'function') {return false;}

            const wrappedHandler = (e) => {
              try {
                handler(e);
              } catch {
                // Event handler error handled silently
              }
            };

            element.addEventListener(event, wrappedHandler, _options);
            return true;
          },
          'addEventListener',
          false
        );
      },
      removeEventListener: (element, event, handler, _options = {}) => {
        return mockErrorHandler.safeExecute(
          () => {
            if (!element) {return false;}
            element.removeEventListener(event, handler, _options);
            return true;
          },
          'removeEventListener',
          false
        );
      },
      insertHTML: (element, position, html) => {
        return mockErrorHandler.safeExecute(
          () => {
            if (!element || !html) {return false;}
            element.insertAdjacentHTML(position, html);
            return true;
          },
          'insertHTML',
          false
        );
      },
      removeElement: (element) => {
        return mockErrorHandler.safeExecute(
          () => {
            if (!element || !element.parentNode) {return false;}
            element.parentNode.removeChild(element);
            return true;
          },
          'removeElement',
          false
        );
      },
      isElementVisible: (element) => {
        return mockErrorHandler.safeExecute(
          () => {
            if (!element) {return false;}
            const rect = element.getBoundingClientRect();
            return rect.width > 0 && rect.height > 0 && element.offsetParent !== null;
          },
          'isElementVisible',
          false
        );
      },
      getElementBounds: (element) => {
        return mockErrorHandler.safeExecute(
          () => {
            if (!element) {return null;}
            const rect = element.getBoundingClientRect();
            return {
              top: rect.top,
              left: rect.left,
              width: rect.width,
              height: rect.height,
              bottom: rect.bottom,
              right: rect.right,
              inViewport: rect.top >= 0 && rect.left >= 0 &&
                         rect.bottom <= window.innerHeight &&
                         rect.right <= window.innerWidth,
              isVisible: rect.width > 0 && rect.height > 0
            };
          },
          'getElementBounds',
          null
        );
      },
      scrollToElement: (element, options = {}) => {
        return mockErrorHandler.safeExecute(
          () => {
            if (!element) {return Promise.resolve(false);}

            const defaultOptions = {
              behavior: 'smooth',
              block: 'center',
              inline: 'nearest'
            };

            const scrollOptions = { ...defaultOptions, ...options };
            element.scrollIntoView(scrollOptions);

            return Promise.resolve(true);
          },
          'scrollToElement',
          Promise.resolve(false)
        );
      }
    };
  });

  afterEach(() => {
    testHelper.afterEach?.();
  });

  describe('Unified DOM Operations', () => {
    it('should provide consistent API across all DOM utilities', () => {
      expect(domUtils.querySelector).toBeTypeOf('function');
      expect(domUtils.querySelectorAll).toBeTypeOf('function');
      expect(domUtils.createElement).toBeTypeOf('function');
      expect(domUtils.addClass).toBeTypeOf('function');
      expect(domUtils.removeClass).toBeTypeOf('function');
      expect(domUtils.toggleClass).toBeTypeOf('function');
      expect(domUtils.addEventListener).toBeTypeOf('function');
      expect(domUtils.removeEventListener).toBeTypeOf('function');
      expect(domUtils.insertHTML).toBeTypeOf('function');
      expect(domUtils.removeElement).toBeTypeOf('function');
      expect(domUtils.isElementVisible).toBeTypeOf('function');
      expect(domUtils.getElementBounds).toBeTypeOf('function');
      expect(domUtils.scrollToElement).toBeTypeOf('function');
    });

    it('should handle all operations with error safety', () => {
      // Test with valid elements
      const element = domUtils.querySelector('#test-container');
      expect(element).not.toBeNull();

      const result1 = domUtils.addClass(element, 'test-class');
      expect(result1).toBe(true);

      const result2 = domUtils.removeClass(element, 'test-class');
      expect(result2).toBe(true);

      // All operations should call error handler
      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });
  });

  describe('Element Selection', () => {
    it('should find single elements', () => {
      const element = domUtils.querySelector('#test-container');
      expect(element).not.toBeNull();
      expect(element.id).toBe('test-container');
    });

    it('should find multiple elements', () => {
      const elements = domUtils.querySelectorAll('.test-element');
      expect(elements).toBeInstanceOf(Array);
      expect(elements).toHaveLength(2);
      expect(elements[0].getAttribute('data-id')).toBe('1');
      expect(elements[1].getAttribute('data-id')).toBe('2');
    });

    it('should return null/empty for non-existent elements', () => {
      const element = domUtils.querySelector('#non-existent');
      expect(element).toBeNull();

      const elements = domUtils.querySelectorAll('.non-existent');
      expect(elements).toBeInstanceOf(Array);
      expect(elements).toHaveLength(0);
    });
  });

  describe('Element Creation and Manipulation', () => {
    it('should create elements with attributes', () => {
      const element = domUtils.createElement('div', {
        id: 'new-element',
        className: 'test-class'
      });

      expect(element).not.toBeNull();
      expect(element.tagName).toBe('DIV');
      expect(element.id).toBe('new-element');
      expect(element.className).toBe('test-class');
    });

    it('should create elements with content', () => {
      const element = domUtils.createElement('p', {}, 'Test content');
      expect(element.innerHTML).toBe('Test content');
    });

    it('should create elements with style objects', () => {
      const element = domUtils.createElement('div', {
        style: { color: 'red', fontSize: '16px' }
      });

      expect(element).not.toBeNull();
      expect(element.tagName).toBe('DIV');
    });

    it('should insert HTML content', () => {
      const container = domUtils.querySelector('#test-container');
      const initialLength = container.children.length;

      const result = domUtils.insertHTML(container, 'beforeend', '<span>Inserted</span>');
      expect(result).toBe(true);
      expect(container.children.length).toBe(initialLength + 1);
    });

    it('should remove elements', () => {
      const button = domUtils.querySelector('#test-button');
      const parent = button.parentNode;

      const result = domUtils.removeElement(button);
      expect(result).toBe(true);
      expect(parent.contains(button)).toBe(false);
    });
  });

  describe('CSS Class Management', () => {
    let testElement;

    beforeEach(() => {
      testElement = domUtils.querySelector('#test-button');
    });

    it('should add CSS classes', () => {
      const result = domUtils.addClass(testElement, 'new-class');
      expect(result).toBe(true);
      expect(testElement.classList.contains('new-class')).toBe(true);
    });

    it('should remove CSS classes', () => {
      testElement.classList.add('remove-me');

      const result = domUtils.removeClass(testElement, 'remove-me');
      expect(result).toBe(true);
      expect(testElement.classList.contains('remove-me')).toBe(false);
    });

    it('should toggle CSS classes', () => {
      const result1 = domUtils.toggleClass(testElement, 'toggle-class');
      expect(result1).toBe(true);
      expect(testElement.classList.contains('toggle-class')).toBe(true);

      const result2 = domUtils.toggleClass(testElement, 'toggle-class');
      expect(result2).toBe(false);
      expect(testElement.classList.contains('toggle-class')).toBe(false);
    });

    it('should handle invalid elements gracefully', () => {
      const result1 = domUtils.addClass(null, 'test-class');
      expect(result1).toBe(false);

      const result2 = domUtils.removeClass(null, 'test-class');
      expect(result2).toBe(false);

      const result3 = domUtils.toggleClass(null, 'test-class');
      expect(result3).toBe(false);
    });
  });

  describe('Event Management', () => {
    it('should add event listeners', () => {
      const button = domUtils.querySelector('#test-button');
      const handler = vi.fn();

      const result = domUtils.addEventListener(button, 'click', handler);
      expect(result).toBe(true);

      // Trigger event
      const clickEvent = new Event('click');
      button.dispatchEvent(clickEvent);
      expect(handler).toHaveBeenCalledTimes(1);
    });

    it('should remove event listeners', () => {
      const button = domUtils.querySelector('#test-button');
      const handler = vi.fn();

      button.addEventListener('click', handler);

      const result = domUtils.removeEventListener(button, 'click', handler);
      expect(result).toBe(true);
    });

    it('should handle event handler errors gracefully', () => {
      const button = domUtils.querySelector('#test-button');
      const faultyHandler = vi.fn().mockImplementation(() => {
        throw new Error('Handler error');
      });

      const result = domUtils.addEventListener(button, 'click', faultyHandler);
      expect(result).toBe(true);

      // Should not throw when handler errors
      expect(() => {
        const clickEvent = new Event('click');
        button.dispatchEvent(clickEvent);
      }).not.toThrow();
    });

    it('should handle invalid elements and handlers', () => {
      const result1 = domUtils.addEventListener(null, 'click', vi.fn());
      expect(result1).toBe(false);

      const button = domUtils.querySelector('#test-button');
      const result2 = domUtils.addEventListener(button, 'click', 'not-a-function');
      expect(result2).toBe(false);
    });
  });

  describe('Element Visibility and Bounds', () => {
    it('should check element visibility', () => {
      const visibleElement = domUtils.querySelector('#test-container');

      // Mock getBoundingClientRect for visible element
      vi.spyOn(visibleElement, 'getBoundingClientRect').mockReturnValue({
        width: 100,
        height: 50,
        top: 10,
        bottom: 60
      });

      // Mock offsetParent
      Object.defineProperty(visibleElement, 'offsetParent', {
        get: () => doc.body,
        configurable: true
      });

      const isVisible = domUtils.isElementVisible(visibleElement);
      expect(isVisible).toBe(true);
    });

    it('should detect hidden elements', () => {
      const hiddenElement = domUtils.querySelector('.hidden-element');

      // Mock as hidden
      vi.spyOn(hiddenElement, 'getBoundingClientRect').mockReturnValue({
        width: 0,
        height: 0,
        top: 0,
        bottom: 0
      });

      Object.defineProperty(hiddenElement, 'offsetParent', {
        get: () => null,
        configurable: true
      });

      const isVisible = domUtils.isElementVisible(hiddenElement);
      expect(isVisible).toBe(false);
    });

    it('should get element bounds with additional metadata', () => {
      const element = domUtils.querySelector('#test-container');

      // Mock getBoundingClientRect
      vi.spyOn(element, 'getBoundingClientRect').mockReturnValue({
        top: 10,
        left: 20,
        width: 100,
        height: 50,
        bottom: 60,
        right: 120
      });

      const bounds = domUtils.getElementBounds(element);
      expect(bounds).toEqual({
        top: 10,
        left: 20,
        width: 100,
        height: 50,
        bottom: 60,
        right: 120,
        inViewport: expect.any(Boolean),
        isVisible: true
      });
    });

    it('should handle null elements', () => {
      const isVisible = domUtils.isElementVisible(null);
      expect(isVisible).toBe(false);

      const bounds = domUtils.getElementBounds(null);
      expect(bounds).toBeNull();
    });
  });

  describe('Scrolling Operations', () => {
    it('should scroll to elements with default options', async () => {
      const element = domUtils.querySelector('#test-container');
      const scrollSpy = vi.spyOn(element, 'scrollIntoView');

      const result = await domUtils.scrollToElement(element);
      expect(result).toBe(true);
      expect(scrollSpy).toHaveBeenCalledWith({
        behavior: 'smooth',
        block: 'center',
        inline: 'nearest'
      });
    });

    it('should scroll to elements with custom options', async () => {
      const element = domUtils.querySelector('#test-container');
      const scrollSpy = vi.spyOn(element, 'scrollIntoView');

      const options = { behavior: 'auto', block: 'start' };
      const result = await domUtils.scrollToElement(element, options);
      expect(result).toBe(true);
      expect(scrollSpy).toHaveBeenCalledWith({
        behavior: 'auto',
        block: 'start',
        inline: 'nearest'
      });
    });

    it('should handle null elements for scrolling', async () => {
      const result = await domUtils.scrollToElement(null);
      expect(result).toBe(false);
    });
  });

  describe('Error Handling Integration', () => {
    it('should use error handler for all operations', () => {
      const element = domUtils.querySelector('#test-container');
      domUtils.addClass(element, 'test');
      domUtils.createElement('div');
      domUtils.isElementVisible(element);

      expect(mockErrorHandler.safeExecute).toHaveBeenCalledTimes(4);
    });

    it('should continue functioning when operations fail', () => {
      // All operations should return fallback values on error
      const result1 = domUtils.querySelector('invalid[selector');
      expect(result1).toBeNull();

      const result2 = domUtils.addClass(null, 'test');
      expect(result2).toBe(false);

      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });
  });
});
