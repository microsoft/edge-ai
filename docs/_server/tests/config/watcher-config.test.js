/**
 * File Watcher Configuration Optimization Tests
 * Tests environment-specific and performance-optimized configurations
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';

describe('File Watcher Configuration Optimization', () => {
  let originalEnv;

  beforeEach(() => {
    originalEnv = { ...process.env };
  });

  afterEach(() => {
    // Restore environment
    process.env = originalEnv;
  });

  describe('Environment-Specific Configuration', () => {
    it('should provide development-optimized configuration', async () => {
      process.env.NODE_ENV = 'development';

      const { getConfigForEnvironment } = await import('../../config/watcher-config.js');
      const config = getConfigForEnvironment('development');

      expect(config).toEqual(expect.objectContaining({
        // Development should prioritize responsiveness
        debounceDelay: expect.any(Number),
        usePolling: false,
        persistent: true,
        ignoreInitial: true,
        awaitWriteFinish: expect.objectContaining({
          stabilityThreshold: expect.any(Number)
        })
      }));

      // Development should have shorter delays for faster feedback
      expect(config.debounceDelay).toBeLessThan(500);
      expect(config.awaitWriteFinish.stabilityThreshold).toBeLessThan(200);
    });

    it('should provide production-optimized configuration', async () => {
      process.env.NODE_ENV = 'production';

      const { getConfigForEnvironment } = await import('../../config/watcher-config.js');
      const config = getConfigForEnvironment('production');

      expect(config).toEqual(expect.objectContaining({
        // Production should prioritize stability and efficiency
        debounceDelay: expect.any(Number),
        usePolling: false,
        persistent: true,
        ignoreInitial: true,
        awaitWriteFinish: expect.objectContaining({
          stabilityThreshold: expect.any(Number)
        })
      }));

      // Production should have longer delays for stability
      expect(config.debounceDelay).toBeGreaterThan(200);
      expect(config.awaitWriteFinish.stabilityThreshold).toBeGreaterThan(100);
    });

    it('should provide test-optimized configuration', async () => {
      process.env.NODE_ENV = 'test';

      const { getConfigForEnvironment } = await import('../../config/watcher-config.js');
      const config = getConfigForEnvironment('test');

      expect(config).toEqual(expect.objectContaining({
        // Test should be fast and deterministic
        debounceDelay: expect.any(Number),
        usePolling: false,
        persistent: false, // Don't persist in tests
        ignoreInitial: true,
        awaitWriteFinish: expect.objectContaining({
          stabilityThreshold: expect.any(Number)
        })
      }));

      // Test should have minimal delays
      expect(config.debounceDelay).toBeLessThan(100);
      expect(config.awaitWriteFinish.stabilityThreshold).toBeLessThan(100);
    });
  });

  describe('Performance Configuration', () => {
    it('should disable polling by default for optimal performance', async () => {
      const { getOptimizedConfig } = await import('../../config/watcher-config.js');
      const config = getOptimizedConfig();

      expect(config.usePolling).toBe(false);
      expect(config.interval).toBeUndefined(); // No polling interval needed
    });

    it('should configure optimal debouncing for different file types', async () => {
      const { getFileTypeConfig } = await import('../../config/watcher-config.js');

      const jsonConfig = getFileTypeConfig('.json');
      const logConfig = getFileTypeConfig('.log');

      // JSON files (progress files) should have shorter debounce
      expect(jsonConfig.debounceDelay).toBeLessThan(300);

      // Log files should have longer debounce (less critical)
      expect(logConfig.debounceDelay).toBeGreaterThan(jsonConfig.debounceDelay);
    });

    it('should configure write stability thresholds appropriately', async () => {
      const { getOptimizedConfig } = await import('../../config/watcher-config.js');
      const config = getOptimizedConfig();

      expect(config.awaitWriteFinish).toBeDefined();
      expect(config.awaitWriteFinish.stabilityThreshold).toBeGreaterThan(50);
      expect(config.awaitWriteFinish.stabilityThreshold).toBeLessThan(500);
      expect(config.awaitWriteFinish.pollInterval).toBeGreaterThan(1000); // Infrequent polling for stability check
    });
  });

  describe('Resource Optimization', () => {
    it('should limit watch depth to prevent excessive monitoring', async () => {
      const { getOptimizedConfig } = await import('../../config/watcher-config.js');
      const config = getOptimizedConfig();

      expect(config.depth).toBeDefined();
      expect(config.depth).toBeLessThanOrEqual(2); // Limit directory traversal
    });

    it('should ignore hidden files and directories for performance', async () => {
      const { getOptimizedConfig } = await import('../../config/watcher-config.js');
      const config = getOptimizedConfig();

      expect(config.ignored).toBeDefined();
      // Should ignore hidden files and common non-essential directories
      expect(config.ignored).toEqual(expect.any(RegExp));
    });

    it('should configure optimal file filters', async () => {
      const { getFileFilters } = await import('../../config/watcher-config.js');
      const filters = getFileFilters();

      expect(filters.include).toBeDefined();
      expect(filters.exclude).toBeDefined();

      // Should include progress-related files
      expect(filters.include).toContain('*.json');

      // Should exclude temporary and system files
      expect(filters.exclude).toEqual(expect.arrayContaining([
        expect.stringMatching(/tmp/),
        expect.stringMatching(/temp/),
        expect.stringMatching(/node_modules/)
      ]));
    });
  });

  describe('Platform-Specific Optimizations', () => {
    it('should provide Windows-optimized configuration', async () => {
      // Mock Windows platform
      const originalPlatform = process.platform;
      Object.defineProperty(process, 'platform', { value: 'win32' });

      const { getPlatformConfig } = await import('../../config/watcher-config.js');
      const config = getPlatformConfig();

      expect(config.usePolling).toBe(false); // Windows supports native events
      expect(config.awaitWriteFinish.stabilityThreshold).toBeGreaterThan(100); // Windows may need more stability time

      // Restore platform
      Object.defineProperty(process, 'platform', { value: originalPlatform });
    });

    it('should provide Linux-optimized configuration', async () => {
      // Mock Linux platform
      const originalPlatform = process.platform;
      Object.defineProperty(process, 'platform', { value: 'linux' });

      const { getPlatformConfig } = await import('../../config/watcher-config.js');
      const config = getPlatformConfig();

      expect(config.usePolling).toBe(false); // Linux supports inotify
      expect(config.awaitWriteFinish.stabilityThreshold).toBeLessThan(200); // Linux is generally faster

      // Restore platform
      Object.defineProperty(process, 'platform', { value: originalPlatform });
    });

    it('should provide macOS-optimized configuration', async () => {
      // Mock macOS platform
      const originalPlatform = process.platform;
      Object.defineProperty(process, 'platform', { value: 'darwin' });

      const { getPlatformConfig } = await import('../../config/watcher-config.js');
      const config = getPlatformConfig();

      expect(config.usePolling).toBe(false); // macOS supports FSEvents
      expect(config.persistent).toBe(true);

      // Restore platform
      Object.defineProperty(process, 'platform', { value: originalPlatform });
    });
  });

  describe('Memory Optimization', () => {
    it('should configure event history limits', async () => {
      const { getMemoryOptimizedConfig } = await import('../../config/watcher-config.js');
      const config = getMemoryOptimizedConfig();

      expect(config.maxEventHistory).toBeDefined();
      expect(config.maxEventHistory).toBeGreaterThan(10);
      expect(config.maxEventHistory).toBeLessThan(1000); // Prevent memory bloat
    });

    it('should configure cleanup intervals', async () => {
      const { getMemoryOptimizedConfig } = await import('../../config/watcher-config.js');
      const config = getMemoryOptimizedConfig();

      expect(config.cleanupInterval).toBeDefined();
      expect(config.cleanupInterval).toBeGreaterThan(30000); // At least 30 seconds
      expect(config.cleanupInterval).toBeLessThan(300000); // At most 5 minutes
    });
  });
});
