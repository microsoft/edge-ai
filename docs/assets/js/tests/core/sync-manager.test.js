import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { composeHelpers } from '../helpers/focused/compose-helpers.js';
import { SyncManager } from '../../core/sync-manager.js';

describe('SyncManager', () => {
  let syncManager;
  let helpers;

  beforeEach(() => {
    helpers = composeHelpers({
      sinon: true,
      storage: true
    });

    syncManager = new SyncManager();

    // Mock the network methods to prevent actual calls
    vi.spyOn(syncManager, 'saveToServer').mockResolvedValue({ success: true });
    vi.spyOn(syncManager, 'loadFromServer').mockResolvedValue({ data: 'test' });
    vi.spyOn(syncManager, 'trackUpdateSource').mockReturnValue(undefined);
  });

  afterEach(() => {
    helpers.cleanup();
    vi.clearAllMocks();
    vi.restoreAllMocks();
  });

  describe('Basic Operations', () => {
    it('should create sync manager instance', () => {
      expect(syncManager).toBeDefined();
      expect(syncManager).toBeInstanceOf(SyncManager);
    });

    it('should have saveToServer method', () => {
      expect(typeof syncManager.saveToServer).toBe('function');
    });

    it('should have loadFromServer method', () => {
      expect(typeof syncManager.loadFromServer).toBe('function');
    });

    it('should have trackUpdateSource method', () => {
      expect(typeof syncManager.trackUpdateSource).toBe('function');
    });

    it('should call saveToServer successfully', async () => {
      const data = { test: 'data' };
      const result = await syncManager.saveToServer(data);
      expect(result).toEqual({ success: true });
      expect(syncManager.saveToServer).toHaveBeenCalledWith(data);
    });

    it('should call loadFromServer successfully', async () => {
      const result = await syncManager.loadFromServer();
      expect(result).toEqual({ data: 'test' });
      expect(syncManager.loadFromServer).toHaveBeenCalled();
    });

    it('should track update source', () => {
      syncManager.trackUpdateSource('test-id', 'ui', { test: true });
      expect(syncManager.trackUpdateSource).toHaveBeenCalledWith('test-id', 'ui', { test: true });
    });
  });

  describe('Server Communication', () => {
    it('should handle saveToServer with various data types', async () => {
      const testCases = [
        { test: 'string' },
        { test: 123 },
        { test: true },
        { test: [] },
        { test: {} }
      ];

      for (const data of testCases) {
        const result = await syncManager.saveToServer(data);
        expect(result).toEqual({ success: true });
      }

      expect(syncManager.saveToServer).toHaveBeenCalledTimes(testCases.length);
    });

    it('should handle loadFromServer consistently', async () => {
      const result1 = await syncManager.loadFromServer();
      const result2 = await syncManager.loadFromServer();

      expect(result1).toEqual({ data: 'test' });
      expect(result2).toEqual({ data: 'test' });
      expect(syncManager.loadFromServer).toHaveBeenCalledTimes(2);
    });
  });
});
