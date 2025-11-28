import { describe, it, expect, afterEach, beforeAll, afterAll, vi } from 'vitest';
import fileWatcher from '../../utils/file-watcher.js';
import fs from 'fs/promises';
import path from 'path';

describe('File Watcher Utilities', () => {
  let tempDir;
  let originalEnv;

  beforeAll(async () => {
    // Create temp directory for testing
    tempDir = path.join(process.cwd(), 'test-temp');
    try {
      await fs.mkdir(tempDir, { recursive: true });
    } catch {
      // Directory might already exist
    }

    // Store original environment
    originalEnv = process.env.NODE_ENV;
  });

  afterEach(() => {
    // Stop watcher and reset state before each test
    fileWatcher.stop();
    vi.restoreAllMocks();

    // Reset environment
    process.env.NODE_ENV = originalEnv;
  });

  afterAll(async () => {
    // Clean up temporary files and directory
    fileWatcher.stop();
    try {
      await fs.rmdir(tempDir, { recursive: true });
    } catch {
      // Directory might not exist or might have files
    }

    // Restore original environment
    process.env.NODE_ENV = originalEnv;
  });

  describe('start (disabled in test mode)', () => {
    it('should handle being disabled in test mode', () => {
      const result = fileWatcher.start();

      // In test mode, file watcher is disabled and returns undefined
      expect(result).toBeUndefined();
    });

    it('should handle multiple start calls when disabled', () => {
      fileWatcher.start();
      const result = fileWatcher.start();

      expect(result).toBeUndefined();
    });
  });

  describe('stop (disabled in test mode)', () => {
    it('should handle stop when disabled', () => {
      fileWatcher.start();

      const result = fileWatcher.stop();

      // stop() doesn't return a value when disabled
      expect(result).toBeUndefined();
    });

    it('should handle stopping when not started', () => {
      const result = fileWatcher.stop();

      expect(result).toBeUndefined();
    });
  });

  describe('service interface', () => {
    it('should have required methods', () => {
      expect(fileWatcher).toBeDefined();
      expect(typeof fileWatcher.start).toBe('function');
      expect(typeof fileWatcher.stop).toBe('function');
      expect(typeof fileWatcher.getStatus).toBe('function');
      expect(typeof fileWatcher.triggerSync).toBe('function');
      expect(typeof fileWatcher.getWatchedFiles).toBe('function');
      expect(typeof fileWatcher.isWatching).toBe('function');
      expect(typeof fileWatcher.stopWatching).toBe('function');
      expect(typeof fileWatcher.watchFile).toBe('function');
    });

    it('should return status when disabled', () => {
      const status = fileWatcher.getStatus();

      expect(status).toBeDefined();
      expect(status.isEnabled).toBe(false);
      expect(status.isRunning).toBe(false);
      expect(typeof status.watchPath).toBe('string');
    });

    it('should return empty array for watched files when disabled', () => {
      const watchedFiles = fileWatcher.getWatchedFiles();

      expect(Array.isArray(watchedFiles)).toBe(true);
      expect(watchedFiles).toHaveLength(0);
    });

    it('should return false when checking if watching files while disabled', () => {
      const isWatching = fileWatcher.isWatching('/some/file.json');

      expect(isWatching).toBe(false);
    });
  });
});
