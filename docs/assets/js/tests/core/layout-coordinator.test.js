import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { LayoutCoordinator } from '../../core/layout-coordinator.js';

describe('LayoutCoordinator', () => {
  let layoutCoordinator;
  let mockErrorHandler;
  let mockDomUtils;
  let mockDebugHelper;

  beforeEach(() => {
    // Mock error handler
    mockErrorHandler = {
      recordError: vi.fn(),
      log: vi.fn(),
      safeExecute: vi.fn().mockImplementation((fn, operation, defaultValue = null) => {
        try {
          return fn();
        } catch (_error) {
          mockErrorHandler.recordError(_error, operation);
          return defaultValue;
        }
      })
    };

    // Mock DOM utilities
    mockDomUtils = {
      querySelector: vi.fn().mockImplementation((selector) => {
        return document.querySelector(selector) || document.createElement('div');
      }),
      querySelectorAll: vi.fn().mockImplementation((selector) => {
        return Array.from(document.querySelectorAll(selector));
      }),
      createElement: vi.fn().mockImplementation((tagName) => {
        return document.createElement(tagName);
      }),
      addClass: vi.fn().mockReturnValue(true),
      removeClass: vi.fn().mockReturnValue(true)
    };

    mockDebugHelper = {
      log: vi.fn(),
      error: vi.fn(),
    };

    // Create LayoutCoordinator instance with mocked dependencies
    layoutCoordinator = new LayoutCoordinator({
      errorHandler: mockErrorHandler,
      domUtils: mockDomUtils,
      debugHelper: mockDebugHelper
    });
  });

  afterEach(() => {
    // Reset error handler mock to normal behavior for cleanup
    if (typeof window !== 'undefined' && window.ResizeObserver) {
      vi.restoreAllMocks();
    }
  });

  describe('initialization', () => {
    it('should initialize with default settings', () => {
      expect(layoutCoordinator.isInitialized).toBe(false);
      expect(layoutCoordinator.config).toBeDefined();
    });

    it('should accept custom configuration', () => {
      const customConfig = {
        sidebarWidth: 300,
        contentPadding: 20
      };

      const customCoordinator = new LayoutCoordinator({
        errorHandler: mockErrorHandler,
        domUtils: mockDomUtils,
        debugHelper: mockDebugHelper,
        config: customConfig
      });

      expect(customCoordinator.config.sidebarWidth).toBe(300);
      expect(customCoordinator.config.contentPadding).toBe(20);
    });
  });

  describe('layout management', () => {
    beforeEach(() => {
      layoutCoordinator.init();
    });

    it('should initialize layout coordination', () => {
      expect(layoutCoordinator.isInitialized).toBe(true);
    });

    it('should update layout on window resize', async () => {
      const updateLayoutSpy = vi.spyOn(layoutCoordinator, 'updateLayout');

      // Simulate window resize
      window.dispatchEvent(new Event('resize'));

      // Wait a tick for event handling to complete
      await new Promise(resolve => setTimeout(resolve, 0));

      expect(updateLayoutSpy).toHaveBeenCalled();
    });

    it('should handle mobile layout changes', () => {
      const originalMatchMedia = window.matchMedia;

      // Mock mobile media query
      const mockMobileQuery = {
        matches: true,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      };

      const mockDesktopQuery = {
        matches: false,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      };

      window.matchMedia = vi.fn()
        .mockReturnValueOnce(mockMobileQuery)
        .mockReturnValueOnce(mockDesktopQuery);

      layoutCoordinator.handleResponsiveLayout();

      expect(window.matchMedia).toHaveBeenCalledWith('(max-width: 768px)');

      // Restore matchMedia
      window.matchMedia = originalMatchMedia;
    });

    it('should handle desktop layout changes', () => {
      const originalMatchMedia = window.matchMedia;

      // Mock desktop media query
      const mockDesktopQuery = {
        matches: true,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
      };

      window.matchMedia = vi.fn().mockReturnValue(mockDesktopQuery);

      layoutCoordinator.handleResponsiveLayout();

      expect(window.matchMedia).toHaveBeenCalledWith('(max-width: 768px)');

      // Restore matchMedia
      window.matchMedia = originalMatchMedia;
    });
  });

  describe('content coordination', () => {
    it('should coordinate content with sidebar', () => {
      const mockContent = document.createElement('div');
      const mockSidebar = document.createElement('div');

      mockDomUtils.querySelector.mockImplementation((selector) => {
        if (selector.includes('content')) {return mockContent;}
        if (selector.includes('sidebar')) {return mockSidebar;}
        return document.createElement('div');
      });

      layoutCoordinator.coordinateContent();

      expect(mockDomUtils.querySelector).toHaveBeenCalled();
    });

    it('should handle missing content elements gracefully', () => {
      mockDomUtils.querySelector.mockReturnValue(null);

      expect(() => {
        layoutCoordinator.coordinateContent();
      }).not.toThrow();

      expect(mockErrorHandler.recordError).not.toHaveBeenCalled();
    });
  });

  describe('responsive behavior', () => {
    it('should register resize observers', () => {
      const mockObserver = {
        observe: vi.fn(),
        disconnect: vi.fn()
      };

      global.ResizeObserver = vi.fn().mockImplementation(() => mockObserver);

      layoutCoordinator.init();
      layoutCoordinator.isInitialized = true;

      expect(global.ResizeObserver).toHaveBeenCalled();
    });

    it('should clean up observers on destroy', () => {
      const mockObserver = { disconnect: vi.fn() };

      // Add the mock observer to the cleanup array like the real implementation does
      layoutCoordinator.cleanup.observers.push(mockObserver);

      layoutCoordinator.destroy();

      expect(mockObserver.disconnect).toHaveBeenCalled();
    });
  });

  describe('error handling', () => {
    it('should handle initialization errors gracefully', () => {
      mockDomUtils.querySelector.mockImplementation(() => {
        throw new Error('DOM error');
      });

      expect(() => {
        layoutCoordinator.init();
      }).not.toThrow();

      // Verify that error handler was called with errors during initialization
      expect(mockErrorHandler.recordError).toHaveBeenCalled();
      expect(mockErrorHandler.recordError).toHaveBeenCalledWith(
        expect.any(Error),
        expect.any(String)
      );
    });

    it('should handle layout update errors', () => {
      // Make sure the coordinator is initialized first
      layoutCoordinator.init();

      // Force an error by making domUtils.querySelector throw
      mockDomUtils.querySelector.mockImplementation(() => {
        throw new Error('DOM error');
      });

      expect(() => {
        layoutCoordinator.updateLayout();
      }).not.toThrow();

      expect(mockErrorHandler.recordError).toHaveBeenCalled();
    });
  });

  describe('configuration management', () => {
    it('should allow runtime configuration updates', () => {
      const newConfig = {
        sidebarWidth: 350,
        contentPadding: 25
      };

      layoutCoordinator.updateConfig(newConfig);

      expect(layoutCoordinator.config.sidebarWidth).toBe(350);
      expect(layoutCoordinator.config.contentPadding).toBe(25);
    });

    it('should merge configuration updates with existing config', () => {
      const originalWidth = layoutCoordinator.config.sidebarWidth;

      layoutCoordinator.updateConfig({
        contentPadding: 30
      });

      expect(layoutCoordinator.config.sidebarWidth).toBe(originalWidth);
      expect(layoutCoordinator.config.contentPadding).toBe(30);
    });
  });

  describe('cleanup', () => {
    it('should remove event listeners on destroy', () => {
      const removeEventListenerSpy = vi.spyOn(window, 'removeEventListener');

      layoutCoordinator.init();
      layoutCoordinator.destroy();

      expect(removeEventListenerSpy).toHaveBeenCalled();
    });

    it('should reset initialization state on destroy', () => {
      layoutCoordinator.init();
      expect(layoutCoordinator.isInitialized).toBe(true);

      layoutCoordinator.destroy();
      expect(layoutCoordinator.isInitialized).toBe(false);
    });
  });
});
