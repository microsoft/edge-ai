/**
 * ErrorHandler Test Suite
 * Comprehensive tests for error handling and debugging capabilities
 * @module tests/core/error-handler
 */

import { vi, describe, it, beforeEach, afterEach, expect } from 'vitest';
import '../helpers/test-setup.js';
import { testPresets } from '../helpers/focused/preset-compositions.js';
import { ErrorHandler, defaultErrorHandler, safeExecute, recordError, getHealthStatus } from '../../core/error-handler.js';

/**
 * ErrorHandler Test Suite
 * Tests error handling and system health monitoring (performance monitoring moved to separate module)
 */
describe('ErrorHandler', () => {

  let testHelper;
  let errorHandler;

  beforeEach(() => {
    // Initialize helpers first
    testHelper = testPresets.integrationModule();
    // Clear any existing state
    testHelper.storage.clear();

    // Clear the default error handler state to prevent test interference
    defaultErrorHandler.errors.length = 0;
    defaultErrorHandler.debugMode = false;

    // Initialize ErrorHandler
    errorHandler = new ErrorHandler('interactive-progress');

    // Clear this specific instance as well
    errorHandler.errors.length = 0;

    // Ensure container is ready before accessing it
    const existingContent = (testHelper.container || testHelper.dom?.container)?.querySelector('.content');

    if (existingContent) {
      existingContent.remove();
    }
  });

  afterEach(() => {
    if (testHelper.afterEach) {
      testHelper.afterEach();
    }
    vi.clearAllMocks();
  });

  describe('element validation', () => {
    beforeEach(() => {
      // Create test content for validation tests
      const content = document.createElement('div');
      content.className = 'content';
      document.body.appendChild(content);
    });

    it('should record error for missing elements', () => {
      const element = errorHandler.validateElement('.nonexistent', 'test context');

      expect(element).toBeNull();
      expect(errorHandler.errors).toHaveLength(1);
      expect(errorHandler.errors[0].operation).toBe('validateElement');
      expect(errorHandler.errors[0].context.selector).toBe('.nonexistent');
    });
  });

  describe('error summary', () => {
    beforeEach(() => {
      // Reset helpers
      testHelper.cleanup();

      // Re-initialize testHelper since we cleaned up
      testHelper = testPresets.integrationModule();

      // Ensure container is ready before accessing it
      const existingContent = (testHelper.container || testHelper.dom?.container)?.querySelector('.content');
      if (existingContent) {
        existingContent.remove();
      }
    });

    it('should report healthy system', () => {
      // Setup healthy environment - make sure ErrorHandler uses the test environment
      Object.defineProperty(document, 'readyState', { value: 'complete', configurable: true });
      window.$docsify = { plugins: [] };

      // Create the required .content element for health check
      const contentElement = document.createElement('div');
      contentElement.className = 'content';
      document.body.appendChild(contentElement);

      // Make sure global references point to our test environment
      global.document = document;
      global.window = window;
      globalThis.document = document;
      globalThis.window = window;

      const health = errorHandler.checkSystemHealth();

      expect(health.domReady).toBe(true);
      expect(health.docsifyPresent).toBe(true);
      expect(health.contentContainer).toBe(true);
      expect(health.errorCount).toBe(0);
      expect(health.healthy).toBe(true);
    });

    it('should report unhealthy system with many errors', () => {
      // Create the required .content element to avoid health check error
      const contentElement = document.createElement('div');
      contentElement.className = 'content';
      document.body.appendChild(contentElement);

      // Record many errors
      for (let i = 0; i < 15; i++) {
        errorHandler.recordError('test', new Error(`Error ${i}`));
      }

      const health = errorHandler.checkSystemHealth();

      expect(health.errorCount).toBe(15);
      expect(health.healthy).toBe(false);
    });

    it('should report unhealthy system when Docsify missing', () => {
      // Remove Docsify from the test window
      delete window.$docsify;

      const health = errorHandler.checkSystemHealth();

      expect(health.docsifyPresent).toBe(false);
      expect(health.healthy).toBe(false);
    });
  });

  describe('global error handling', () => {
    beforeEach(() => {
      errorHandler.init();
    });

    it('should capture console.error calls for plugin errors', () => {
      // Don't override console.error since ErrorHandler.init() already did
      // Just trigger an error that should be captured (using plugin name to trigger capture)
      console.error('interactive-progress error occurred');

      expect(errorHandler.errors).toHaveLength(1);
      expect(errorHandler.errors[0].operation).toBe('console.error');
      expect(errorHandler.errors[0].context.args).toEqual(['interactive-progress error occurred']);
    });
  });

  describe('debug logging', () => {
    beforeEach(() => {
      errorHandler.init();
    });

    it('should log when debug mode enabled', () => {
      const logSpy = vi.spyOn(console, "log").mockImplementation(() => {});

      // Ensure KataProgressConfig exists
      window.KataProgressConfig = {};
      window.KataProgressConfig.debugMode = true;

      errorHandler.log('Test message', 'extra', 'args');

      expect(logSpy).toHaveBeenCalledWith('[interactive-progress] Test message', 'extra', 'args');
    });

    it('should not log when debug mode disabled', () => {
      const logSpy = vi.spyOn(console, "log").mockImplementation(() => {});

      // Ensure KataProgressConfig exists
      window.KataProgressConfig = {};
      window.KataProgressConfig.debugMode = false;

      errorHandler.log('Test message');

      expect(logSpy).not.toHaveBeenCalled();
    });
  });

  describe('exported convenience functions', () => {
    it('should export default instance', () => {
      expect(defaultErrorHandler).toBeInstanceOf(ErrorHandler);
    });

    it('should export safeExecute function', () => {
      const result = safeExecute(() => 'test', 'operation');
      expect(result).toBe('test');
    });

    it('should export recordError function', () => {
      recordError('test', new Error('Test error'));
      expect(defaultErrorHandler.errors).toHaveLength(1);
    });

    it('should export getHealthStatus function', () => {
      const health = getHealthStatus();
      expect(health).toHaveProperty('healthy');
    });
  });
});
