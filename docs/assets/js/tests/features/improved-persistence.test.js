/**
 * Enhanced Progress Persistence Tests
 * Tests for improved save/load functionality with advanced features
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { ImprovedPersistence } from '../../features/improved-persistence.js';

describe('ImprovedPersistence', () => {
  let persistence;
  let mockApiClient;
  let mockLocalStorage;

  beforeEach(() => {
    // Mock API client
    mockApiClient = {
      save: vi.fn(),
      load: vi.fn(),
      batchSync: vi.fn()
    };

    // Mock localStorage
    mockLocalStorage = {
      getItem: vi.fn(),
      setItem: vi.fn(),
      removeItem: vi.fn()
    };

    global.localStorage = mockLocalStorage;

    persistence = new ImprovedPersistence({
      apiClient: mockApiClient,
      autoSaveInterval: 1000
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
    persistence?.destroy();
  });

  describe('Optimistic UI Updates', () => {
    it('should immediately update UI before API call', async () => {
      const progressData = { taskId: 'task1', completed: true };

      const uiUpdateSpy = vi.fn();
      persistence.onUIUpdate(uiUpdateSpy);

      persistence.saveProgress(progressData);

      expect(uiUpdateSpy).toHaveBeenCalledWith(progressData);
    });

    it('should revert UI update if API call fails', async () => {
      vi.useFakeTimers();
      mockApiClient.save.mockRejectedValue(new Error('API Error'));

      const progressData = { taskId: 'task1', completed: true };
      const uiRevertSpy = vi.fn();
      persistence.onUIRevert(uiRevertSpy);

      const savePromise = persistence.saveProgress(progressData);

      // Fast-forward the debounce timer and flush promises
      vi.advanceTimersByTime(300);
      await vi.runAllTimersAsync();

      try {
        await savePromise;
      } catch {
        // Expected to fail
      }

      expect(uiRevertSpy).toHaveBeenCalledWith(progressData);
      vi.useRealTimers();
    });

    it('should confirm UI update if API call succeeds', async () => {
      vi.useFakeTimers();
      mockApiClient.save.mockResolvedValue({ success: true });

      const progressData = { taskId: 'task1', completed: true };
      const uiConfirmSpy = vi.fn();
      persistence.onUIConfirm(uiConfirmSpy);

      const savePromise = persistence.saveProgress(progressData);

      // Fast-forward the debounce timer and flush promises
      vi.advanceTimersByTime(300);
      await vi.runAllTimersAsync();
      await savePromise;

      expect(uiConfirmSpy).toHaveBeenCalledWith(progressData);
      vi.useRealTimers();
    });
  });

  describe('Data Integrity with Checksums', () => {
    it('should generate checksum for progress data', () => {
      const progressData = { taskId: 'task1', completed: true, timestamp: 12345 };

      const checksum = persistence.generateChecksum(progressData);

      expect(checksum).toBeDefined();
      expect(typeof checksum).toBe('string');
      expect(checksum.length).toBeGreaterThan(0);
    });

    it('should validate checksum on data load', () => {
      const progressData = { taskId: 'task1', completed: true, timestamp: 12345 };
      const checksum = persistence.generateChecksum(progressData);

      const isValid = persistence.validateChecksum(progressData, checksum);

      expect(isValid).toBe(true);
    });

    it('should detect corrupted data with invalid checksum', () => {
      const progressData = { taskId: 'task1', completed: true };
      const invalidChecksum = 'invalid_checksum';

      const isValid = persistence.validateChecksum(progressData, invalidChecksum);

      expect(isValid).toBe(false);
    });

    it('should recover from corrupted data by refetching from API', async () => {
      mockApiClient.load.mockResolvedValue({ taskId: 'task1', completed: false });
      mockLocalStorage.getItem.mockReturnValue(JSON.stringify({
        data: { taskId: 'task1', completed: true },
        checksum: 'invalid_checksum'
      }));

      const result = await persistence.loadProgress('task1');

      expect(mockApiClient.load).toHaveBeenCalledWith('task1');
      expect(result.completed).toBe(false); // From API, not corrupted local
    });
  });

  describe('Auto-save Functionality', () => {
    it('should auto-save at configured intervals', async () => {
      vi.useFakeTimers();
      const autoSaveSpy = vi.fn();
      persistence.onAutoSave(autoSaveSpy);

      persistence.enableAutoSave();
      persistence.markDirty('task1', { completed: true });

      // Fast-forward time
      vi.advanceTimersByTime(1000);

      expect(autoSaveSpy).toHaveBeenCalled();
    });

    it('should not auto-save if no changes are dirty', async () => {
      vi.useFakeTimers();
      mockApiClient.save = vi.fn();

      persistence.enableAutoSave();

      // Fast-forward time
      vi.advanceTimersByTime(1000);

      expect(mockApiClient.save).not.toHaveBeenCalled();
    });

    it('should batch multiple dirty changes in auto-save', async () => {
      vi.useFakeTimers();
      const batchSaveSpy = vi.fn();
      persistence.onBatchSave(batchSaveSpy);

      persistence.enableAutoSave();
      persistence.markDirty('task1', { completed: true });
      persistence.markDirty('task2', { completed: false });

      // Fast-forward time
      vi.advanceTimersByTime(1000);

      expect(batchSaveSpy).toHaveBeenCalledWith([
        { taskId: 'task1', data: { completed: true } },
        { taskId: 'task2', data: { completed: false } }
      ]);
    });

    it('should stop auto-save when disabled', () => {
      vi.useFakeTimers();
      persistence.enableAutoSave();
      persistence.disableAutoSave();

      const autoSaveSpy = vi.fn();
      persistence.onAutoSave(autoSaveSpy);
      persistence.markDirty('task1', { completed: true });

      // Fast-forward time
      vi.advanceTimersByTime(1000);

      expect(autoSaveSpy).not.toHaveBeenCalled();
    });
  });

  describe('Enhanced Conflict Resolution', () => {
    it('should detect conflicts when local and remote data differ', async () => {
      const localData = { taskId: 'task1', completed: true, lastModified: 1000 };
      const remoteData = { taskId: 'task1', completed: false, lastModified: 2000 };

      mockLocalStorage.getItem.mockReturnValue(JSON.stringify({
        data: localData,
        checksum: persistence.generateChecksum(localData)
      }));
      mockApiClient.load.mockResolvedValue(remoteData);

      const result = await persistence.loadProgress('task1');

      expect(result.hasConflict).toBe(true);
      expect(result.localData).toEqual(localData);
      expect(result.remoteData).toEqual(remoteData);
    });

    it('should auto-resolve conflicts using last-modified timestamp', async () => {
      const localData = { taskId: 'task1', completed: true, lastModified: 2000 };
      const remoteData = { taskId: 'task1', completed: false, lastModified: 1000 };

      mockLocalStorage.getItem.mockReturnValue(JSON.stringify({
        data: localData,
        checksum: persistence.generateChecksum(localData)
      }));
      mockApiClient.load.mockResolvedValue(remoteData);

      const result = await persistence.loadProgress('task1', { autoResolve: true });

      expect(result.completed).toBe(true); // Local data is newer
      expect(result.hasConflict).toBe(false);
    });

    it('should provide conflict resolution options to user', async () => {
      const localData = { taskId: 'task1', completed: true, lastModified: 1000 };
      const remoteData = { taskId: 'task1', completed: false, lastModified: 2000 };

      const conflictResolver = vi.fn().mockResolvedValue('remote');
      persistence.setConflictResolver(conflictResolver);

      mockLocalStorage.getItem.mockReturnValue(JSON.stringify({
        data: localData,
        checksum: persistence.generateChecksum(localData)
      }));
      mockApiClient.load.mockResolvedValue(remoteData);

      const result = await persistence.loadProgress('task1');

      expect(conflictResolver).toHaveBeenCalledWith(localData, remoteData);
      expect(result.completed).toBe(false); // User chose remote
    });
  });

  describe('Performance Optimization', () => {
    it('should debounce rapid save operations', async () => {
      vi.useFakeTimers();
      const debouncedSave = vi.fn();
      persistence.onDebouncedSave(debouncedSave);

      persistence.save('task1', { completed: true });
      persistence.save('task1', { completed: false });
      persistence.save('task1', { completed: true });

      // Fast-forward debounce time
      vi.advanceTimersByTime(300);

      expect(debouncedSave).toHaveBeenCalledTimes(1);
    });

    it('should cache frequently accessed data', async () => {
      const progressData = { taskId: 'task1', completed: true };
      mockApiClient.load.mockResolvedValue(progressData);

      // First load - should hit API
      await persistence.loadProgress('task1');
      expect(mockApiClient.load).toHaveBeenCalledTimes(1);

      // Second load - should use cache
      await persistence.loadProgress('task1');
      expect(mockApiClient.load).toHaveBeenCalledTimes(1);
    });

    it('should invalidate cache when data is updated', async () => {
      vi.useFakeTimers();
      const originalData = { taskId: 'task1', completed: false };
      const updatedData = { taskId: 'task1', completed: true };

      mockApiClient.load.mockResolvedValue(originalData);
      mockApiClient.save.mockResolvedValue({ success: true });

      // Load and cache data
      await persistence.loadProgress('task1');

      // Update data - should invalidate cache
      const savePromise = persistence.saveProgress(updatedData);

      // Fast-forward the debounce timer
      await vi.advanceTimersByTimeAsync(300);
      await savePromise;

      // Next load should hit API again
      mockApiClient.load.mockResolvedValue(updatedData);
      const result = await persistence.loadProgress('task1');

      expect(mockApiClient.load).toHaveBeenCalledTimes(2);
      expect(result.completed).toBe(true);
      vi.useRealTimers();
    });
  });

  describe('Error Handling and Recovery', () => {
    it('should handle network failures gracefully', async () => {
      vi.useFakeTimers();
      mockApiClient.save.mockRejectedValue(new Error('Network Error'));

      const errorHandler = vi.fn();
      persistence.onError(errorHandler);

      const savePromise = persistence.saveProgress({ taskId: 'task1', completed: true });

      // Fast-forward the debounce timer and flush promises
      vi.advanceTimersByTime(300);
      await vi.runAllTimersAsync();

      try {
        await savePromise;
      } catch {
        // Expected to fail
      }

      expect(errorHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'NETWORK_ERROR',
          message: 'Network Error'
        })
      );
      vi.useRealTimers();
    });

    it('should retry failed operations with exponential backoff', async () => {
      vi.useFakeTimers();
      mockApiClient.save
        .mockRejectedValueOnce(new Error('Network Error'))
        .mockRejectedValueOnce(new Error('Network Error'))
        .mockResolvedValue({ success: true });

      const savePromise = persistence.saveProgress({ taskId: 'task1', completed: true });

      // Fast-forward the debounce timer and retry delays
      await vi.advanceTimersByTimeAsync(300); // Initial debounce
      await vi.advanceTimersByTimeAsync(1000); // First retry
      await vi.advanceTimersByTimeAsync(2000); // Second retry
      const result = await savePromise;

      expect(mockApiClient.save).toHaveBeenCalledTimes(3);
      expect(result.success).toBe(true);
      vi.useRealTimers();
    });

    it('should queue operations when offline', async () => {
      persistence.setOfflineMode(true);

      await persistence.saveProgress({ taskId: 'task1', completed: true });
      await persistence.saveProgress({ taskId: 'task2', completed: false });

      expect(mockApiClient.save).not.toHaveBeenCalled();
      expect(persistence.getOfflineQueue()).toHaveLength(2);
    });

    it('should sync queued operations when back online', async () => {
      persistence.setOfflineMode(true);
      await persistence.saveProgress({ taskId: 'task1', completed: true });
      await persistence.saveProgress({ taskId: 'task2', completed: false });

      mockApiClient.batchSync.mockResolvedValue({ success: true, synced: 2 });

      persistence.setOfflineMode(false);
      await persistence.syncOfflineQueue();

      expect(mockApiClient.batchSync).toHaveBeenCalledWith([
        { taskId: 'task1', completed: true },
        { taskId: 'task2', completed: false }
      ]);
      expect(persistence.getOfflineQueue()).toHaveLength(0);
    });
  });
});
