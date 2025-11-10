/**
 * Docsify Integration Module Tests
 * Tests the actual DocsifyIntegration class implementation
 */
import { expect, describe, it, beforeEach, afterEach, vi } from 'vitest';
import { DocsifyIntegration } from '../../../core/docsify-integration.js';

// Mock the DOM and global objects
global.window = global.window || {};
global.document = global.document || {};

describe('DocsifyIntegration', () => {
  let docsifyIntegration;
  let mockWindow;
  let mockDocument;

  beforeEach(() => {
    // Setup window mock
    mockWindow = {
      location: { hash: '#/', pathname: '/' },
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      $docsify: {
        hooks: {
          init: vi.fn(),
          beforeEach: vi.fn(),
          afterEach: vi.fn(),
          doneEach: vi.fn(),
          mounted: vi.fn(),
          ready: vi.fn()
        }
      },
      Docsify: { dom: {} },
      DocumentationSystem: undefined,
      dispatchEvent: vi.fn()
    };

    // Setup document mock
    mockDocument = {
      querySelector: vi.fn(),
      querySelectorAll: vi.fn(() => []),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      dispatchEvent: vi.fn()
    };

    // Mock MutationObserver
    global.MutationObserver = vi.fn().mockImplementation((_callback) => ({
      observe: vi.fn(),
      disconnect: vi.fn(),
      takeRecords: vi.fn()
    }));

    // Mock clearTimeout and setTimeout
    vi.useFakeTimers();

    // Apply mocks to global
    global.window = mockWindow;
    global.document = mockDocument;

    docsifyIntegration = new DocsifyIntegration();
  });

  afterEach(() => {
    if (docsifyIntegration && typeof docsifyIntegration.destroy === 'function') {
      docsifyIntegration.destroy();
    }

    vi.useRealTimers();
    vi.clearAllMocks();
  });

  describe('initialization', () => {
    it('should initialize with default properties', () => {
      expect(docsifyIntegration.errorHandler).toBeDefined();
      expect(docsifyIntegration.components).toBeInstanceOf(Map);
      expect(docsifyIntegration.isInitialized).toBe(false);
      expect(docsifyIntegration.currentRoute).toBeNull();
      expect(docsifyIntegration.contentObserver).toBeNull();
      expect(docsifyIntegration.routeChangeHandlers).toBeInstanceOf(Set);
      expect(docsifyIntegration.hooks).toBeDefined();
    });

    it('should have the expected hooks structure', () => {
      expect(docsifyIntegration.hooks).toHaveProperty('beforeEach');
      expect(docsifyIntegration.hooks).toHaveProperty('afterEach');
      expect(docsifyIntegration.hooks).toHaveProperty('doneEach');
      expect(docsifyIntegration.hooks).toHaveProperty('mounted');
      expect(docsifyIntegration.hooks.beforeEach instanceof Set).toBe(true);
      expect(docsifyIntegration.hooks.afterEach instanceof Set).toBe(true);
      expect(docsifyIntegration.hooks.doneEach instanceof Set).toBe(true);
      expect(docsifyIntegration.hooks.mounted instanceof Set).toBe(true);
    });
  });

  describe('waitForDocsify', () => {
    it('should resolve true when Docsify is available', async () => {
      const result = await docsifyIntegration.waitForDocsify(100);
      expect(result).toBe(true);
    });

    it('should resolve false when Docsify is not available within timeout', async () => {
      vi.useFakeTimers();

      global.window.$docsify = undefined;
      global.window.Docsify = undefined;

      const waitPromise = docsifyIntegration.waitForDocsify(50);

      // Fast-forward time to trigger timeout
      vi.advanceTimersByTime(100);

      const result = await waitPromise;
      expect(result).toBe(false);

      vi.useRealTimers();
    });
  });

  describe('component management', () => {
    it('should register a component', () => {
      const mockComponent = {
        name: 'TestComponent',
        init: vi.fn(),
        destroy: vi.fn()
      };

      const result = docsifyIntegration.registerComponent('test', mockComponent);

      expect(result).toBe(true);
      expect(docsifyIntegration.components.has('test')).toBe(true);
      expect(docsifyIntegration.getComponent('test')).toBe(mockComponent);
    });

    it('should not register a component with invalid name', () => {
      const mockComponent = { init: vi.fn() };

      const result = docsifyIntegration.registerComponent('', mockComponent);
      expect(result).toBe(false);

      const result2 = docsifyIntegration.registerComponent(null, mockComponent);
      expect(result2).toBe(false);
    });

    it('should unregister a component', () => {
      const mockComponent = {
        name: 'TestComponent',
        destroy: vi.fn()
      };

      docsifyIntegration.registerComponent('test', mockComponent);
      const result = docsifyIntegration.unregisterComponent('test');

      expect(result).toBe(true);
      expect(docsifyIntegration.components.has('test')).toBe(false);
      expect(mockComponent.destroy).toHaveBeenCalled();
    });

    it('should get all components', () => {
      const mockComponent1 = { name: 'Component1' };
      const mockComponent2 = { name: 'Component2' };

      docsifyIntegration.registerComponent('comp1', mockComponent1);
      docsifyIntegration.registerComponent('comp2', mockComponent2);

      const allComponents = docsifyIntegration.getAllComponents();
      expect(allComponents).toBeInstanceOf(Map);
      expect(allComponents.size).toBe(2);
      expect(allComponents.get('comp1')).toBe(mockComponent1);
      expect(allComponents.get('comp2')).toBe(mockComponent2);
    });
  });

  describe('route management', () => {
    it('should get current route from hash', () => {
      global.window.location.hash = '#/test/path';

      const route = docsifyIntegration.getCurrentRoute();
      expect(route).toBe('/test/path');
    });

    it('should detect learning paths page', () => {
      expect(docsifyIntegration.isLearningPathsPage('/learning/')).toBe(true);
      expect(docsifyIntegration.isLearningPathsPage('/learning/test')).toBe(true);
      expect(docsifyIntegration.isLearningPathsPage('/docs/test')).toBe(false);
      expect(docsifyIntegration.isLearningPathsPage('')).toBe(false);
    });

    it('should handle route change events', () => {
      const handler = vi.fn();
      docsifyIntegration.addRouteChangeHandler(handler);

      docsifyIntegration.handleRouteChange('/old', '/new');

      expect(handler).toHaveBeenCalledWith('/old', '/new', false);
    });

    it('should remove route change handlers', () => {
      const handler = vi.fn();
      docsifyIntegration.addRouteChangeHandler(handler);
      docsifyIntegration.removeRouteChangeHandler(handler);

      docsifyIntegration.handleRouteChange('/old', '/new');

      expect(handler).not.toHaveBeenCalled();
    });
  });

  describe('hook management', () => {
    it('should add hook handlers', () => {
      const handler = vi.fn();

      const result = docsifyIntegration.addHook('beforeEach', handler);
      expect(result).toBe(true);
      expect(docsifyIntegration.hooks.beforeEach).toContain(handler);
    });

    it('should remove hook handlers', () => {
      const handler = vi.fn();
      docsifyIntegration.addHook('beforeEach', handler);

      const result = docsifyIntegration.removeHook('beforeEach', handler);
      expect(result).toBe(true);
      expect(docsifyIntegration.hooks.beforeEach).not.toContain(handler);
    });

    it('should not add handler to invalid hook', () => {
      const handler = vi.fn();

      const result = docsifyIntegration.addHook('invalidHook', handler);
      expect(result).toBe(false);
    });
  });

  describe('event emission', () => {
    it('should emit custom events', () => {
      const mockDispatchEvent = vi.spyOn(global.document, 'dispatchEvent');

      docsifyIntegration.emitEvent('test-event', { data: 'test' });

      expect(mockDispatchEvent).toHaveBeenCalled();
      const call = mockDispatchEvent.mock.calls[0][0];
      expect(call.type).toBe('test-event');
      expect(call.detail).toEqual({ data: 'test' });
    });

    it('should handle event emission when document is not available', () => {
      const originalDocument = global.document;

      // Set up environment where document is undefined
      delete global.document;

      let result;
      expect(() => {
        result = docsifyIntegration.emitEvent('test-event');
      }).not.toThrow();

      // Should not crash and should return undefined (no event emitted)
      expect(result).toBeUndefined();

      // Restore document
      global.document = originalDocument;
    });
  });

  describe('global interface', () => {
    it('should register global interface', () => {
      docsifyIntegration.registerGlobalInterface();

      expect(global.window.DocumentationSystem).toBeDefined();
      expect(global.window.DocumentationSystem.docsifyIntegration).toBe(docsifyIntegration);
    });

    it('should preserve existing DocumentationSystem properties', () => {
      global.window.DocumentationSystem = { existingProp: 'test' };

      docsifyIntegration.registerGlobalInterface();

      expect(global.window.DocumentationSystem.existingProp).toBe('test');
      expect(global.window.DocumentationSystem.docsifyIntegration).toBe(docsifyIntegration);
    });
  });

  describe('lifecycle hooks', () => {
    it('should handle beforeEach hook', async () => {
      const mockVm = { route: { path: '/test' } };
      const result = await docsifyIntegration.handleBeforeEach('<h1>Test</h1>', mockVm);

      expect(result).toBe('<h1>Test</h1>');
    });

    it('should handle afterEach hook', async () => {
      const mockVm = { route: { path: '/test' } };
      const result = await docsifyIntegration.handleAfterEach('<h1>Test</h1>', mockVm);

      expect(result).toBe('<h1>Test</h1>');
    });

    it('should handle doneEach hook', () => {
      const mockVm = { route: { path: '/test' } };

      expect(() => {
        docsifyIntegration.handleDoneEach(mockVm);
      }).not.toThrow();
    });

    it('should handle mounted hook', () => {
      const mockVm = { route: { path: '/test' } };

      expect(() => {
        docsifyIntegration.handleMounted(mockVm);
      }).not.toThrow();
    });
  });

  describe('initialization process', () => {
    it('should initialize successfully when Docsify is available', async () => {
      const result = await docsifyIntegration.initialize();

      expect(result).toBe(true);
      expect(docsifyIntegration.isInitialized).toBe(true);
    });

    it('should setup fallback integration when Docsify is not immediately available', async () => {
      // Store original values
      const original$docsify = global.window.$docsify;
      const originalDocsify = global.window.Docsify;

      // Remove Docsify from global scope
      global.window.$docsify = undefined;
      global.window.Docsify = undefined;

      // Create a new instance for this test to avoid state pollution
      const fallbackIntegration = new DocsifyIntegration();

      // Mock waitForDocsify to resolve immediately with false (no Docsify)
      const waitForDocsifySpy = vi.spyOn(fallbackIntegration, 'waitForDocsify').mockResolvedValue(false);

      const result = await fallbackIntegration.initialize();

      // Should still succeed with fallback
      expect(result).toBe(true);
      expect(waitForDocsifySpy).toHaveBeenCalled();

      // Clean up the test instance
      fallbackIntegration.destroy();

      // Restore original values
      global.window.$docsify = original$docsify;
      global.window.Docsify = originalDocsify;
    });
  });

  describe('destruction', () => {
    it('should clean up resources on destroy', () => {
      const mockComponent = { destroy: vi.fn() };
      docsifyIntegration.registerComponent('test', mockComponent);

      // Mock the contentObserver
      const mockObserver = { disconnect: vi.fn() };
      docsifyIntegration.contentObserver = mockObserver;

      docsifyIntegration.destroy();

      expect(mockComponent.destroy).toHaveBeenCalled();
      expect(mockObserver.disconnect).toHaveBeenCalled();
      expect(docsifyIntegration.components.size).toBe(0);
      expect(docsifyIntegration.routeChangeHandlers.size).toBe(0);
    });

    it('should handle destroy when resources are already cleaned up', () => {
      docsifyIntegration.destroy();

      expect(() => {
        docsifyIntegration.destroy();
      }).not.toThrow();
    });
  });
});
