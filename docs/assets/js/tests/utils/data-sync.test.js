/**
 * Data Synchronization Tests
 * Tests for better API and localStorage synchronization
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { DataSync } from '../../utils/data-sync.js';

describe('DataSync', () => {
  let dataSync;
  let mockApiClient;
  let mockLocalStorage;
  let mockEventBus;

  beforeEach(() => {
    // Mock API client
    mockApiClient = {
      sync: vi.fn(),
      getLastModified: vi.fn(),
      batchSync: vi.fn()
    };

    // Mock localStorage
    mockLocalStorage = {
      getItem: vi.fn(),
      setItem: vi.fn(),
      removeItem: vi.fn(),
      clear: vi.fn()
    };

    // Mock event bus
    mockEventBus = {
      emit: vi.fn(),
      on: vi.fn(),
      off: vi.fn()
    };

    global.localStorage = mockLocalStorage;

    dataSync = new DataSync({
      apiClient: mockApiClient,
      eventBus: mockEventBus,
      syncInterval: 5000
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
    dataSync?.destroy();
  });

  describe('Intelligent Synchronization', () => {
    it('should detect when synchronization is needed', async () => {
      const localLastModified = new Date('2024-01-01T10:00:00Z');
      const remoteLastModified = new Date('2024-01-01T11:00:00Z');

      mockLocalStorage.getItem.mockReturnValue(localLastModified.toISOString());
      mockApiClient.getLastModified.mockResolvedValue(remoteLastModified);

      const needsSync = await dataSync.checkSyncNeeded();

      expect(needsSync).toBe(true);
    });

    it('should skip sync when local data is up-to-date', async () => {
      const lastModified = new Date('2024-01-01T10:00:00Z');

      mockLocalStorage.getItem.mockReturnValue(lastModified.toISOString());
      mockApiClient.getLastModified.mockResolvedValue(lastModified);

      const needsSync = await dataSync.checkSyncNeeded();

      expect(needsSync).toBe(false);
    });

    it('should perform full sync when needed', async () => {
      const remoteData = [
        { taskId: 'task1', completed: true, lastModified: new Date() },
        { taskId: 'task2', completed: false, lastModified: new Date() }
      ];

      mockApiClient.sync.mockResolvedValue({
        success: true,
        data: remoteData,
        lastModified: new Date()
      });

      const result = await dataSync.performFullSync();

      expect(result.success).toBe(true);
      expect(result.itemsSynced).toBe(2);
      expect(mockLocalStorage.setItem).toHaveBeenCalled();
    });
  });

  describe('Conflict Detection and Resolution', () => {
    it('should detect data conflicts during sync', async () => {
      const localData = { taskId: 'task1', completed: true, lastModified: new Date('2024-01-01T10:00:00Z') };
      const remoteData = { taskId: 'task1', completed: false, lastModified: new Date('2024-01-01T11:00:00Z') };

      mockLocalStorage.getItem.mockReturnValue(JSON.stringify([localData]));
      mockApiClient.sync.mockResolvedValue({
        success: true,
        data: [remoteData],
        lastModified: new Date('2024-01-01T12:00:00Z'),
        conflicts: [{ taskId: 'task1', local: localData, remote: remoteData }]
      });

      const result = await dataSync.performFullSync();

      expect(result.conflicts).toHaveLength(1);
      expect(result.conflicts[0].taskId).toBe('task1');
    });

    it('should resolve conflicts using merge strategy', async () => {
      const localData = { taskId: 'task1', completed: true, notes: 'local notes', lastModified: new Date('2024-01-01T10:00:00Z') };
      const remoteData = { taskId: 'task1', completed: true, progress: 75, lastModified: new Date('2024-01-01T11:00:00Z') };

      const conflictResolver = vi.fn().mockReturnValue({
        taskId: 'task1',
        completed: true,
        notes: 'local notes',
        progress: 75,
        lastModified: remoteData.lastModified
      });

      dataSync.setConflictResolver(conflictResolver);

      const resolvedData = await dataSync.resolveConflict(localData, remoteData);

      expect(conflictResolver).toHaveBeenCalledWith(localData, remoteData);
      expect(resolvedData.notes).toBe('local notes');
      expect(resolvedData.progress).toBe(75);
    });

    it('should use timestamp-based resolution as fallback', async () => {
      const localData = { taskId: 'task1', completed: true, lastModified: new Date('2024-01-01T12:00:00Z') };
      const remoteData = { taskId: 'task1', completed: false, lastModified: new Date('2024-01-01T11:00:00Z') };

      const resolvedData = await dataSync.resolveConflict(localData, remoteData);

      expect(resolvedData.completed).toBe(true); // Local is newer
    });
  });

  describe('Partial Synchronization', () => {
    it('should sync only changed items', async () => {
      const lastSyncTime = new Date('2024-01-01T10:00:00Z');
      const changedItems = [
        { taskId: 'task1', completed: true, lastModified: new Date('2024-01-01T11:00:00Z') }
      ];

      mockLocalStorage.getItem.mockReturnValue(lastSyncTime.toISOString());
      mockApiClient.sync.mockResolvedValue({
        success: true,
        data: changedItems,
        lastModified: new Date('2024-01-01T11:00:00Z')
      });

      const result = await dataSync.performPartialSync();

      expect(mockApiClient.sync).toHaveBeenCalledWith({
        since: lastSyncTime,
        type: 'partial'
      });
      expect(result.itemsSynced).toBe(1);
    });

    it('should merge partial sync results with local data', async () => {
      const existingLocalData = [
        { taskId: 'task1', completed: false, lastModified: new Date('2024-01-01T09:00:00Z') },
        { taskId: 'task2', completed: true, lastModified: new Date('2024-01-01T09:00:00Z') }
      ];

      const updatedData = [
        { taskId: 'task1', completed: true, lastModified: new Date('2024-01-01T11:00:00Z') }
      ];

      mockLocalStorage.getItem.mockReturnValue(JSON.stringify(existingLocalData));
      mockApiClient.sync.mockResolvedValue({
        success: true,
        data: updatedData,
        lastModified: new Date('2024-01-01T11:00:00Z')
      });

      const result = await dataSync.performPartialSync();

      const savedDataWrapper = JSON.parse(mockLocalStorage.setItem.mock.calls[0][1]);
      const mergedData = savedDataWrapper.data;
      expect(mergedData).toHaveLength(2);
      expect(mergedData.find(item => item.taskId === 'task1').completed).toBe(true);
      expect(mergedData.find(item => item.taskId === 'task2').completed).toBe(true);
    });
  });

  describe('Batch Operations', () => {
    it('should perform batch synchronization efficiently', async () => {
      const batchData = [
        { taskId: 'task1', completed: true },
        { taskId: 'task2', completed: false },
        { taskId: 'task3', completed: true }
      ];

      mockApiClient.batchSync.mockResolvedValue({
        success: true,
        processed: 3,
        failed: 0
      });

      const result = await dataSync.performBatchSync(batchData);

      expect(result.success).toBe(true);
      expect(result.processed).toBe(3);
      expect(mockApiClient.batchSync).toHaveBeenCalledWith(batchData);
    });

    it('should handle partial batch failures gracefully', async () => {
      const batchData = [
        { taskId: 'task1', completed: true },
        { taskId: 'task2', completed: false },
        { taskId: 'task3', completed: true }
      ];

      mockApiClient.batchSync.mockResolvedValue({
        success: true,
        processed: 2,
        failed: 1,
        failures: [{ taskId: 'task2', error: 'Validation error' }]
      });

      const result = await dataSync.performBatchSync(batchData);

      expect(result.processed).toBe(2);
      expect(result.failed).toBe(1);
      expect(result.failures).toHaveLength(1);
    });

    it('should chunk large batch operations', async () => {
      const largeDataSet = Array.from({ length: 150 }, (_, i) => ({
        taskId: `task${i}`,
        completed: i % 2 === 0
      }));

      mockApiClient.batchSync.mockResolvedValue({
        success: true,
        processed: 100,
        failed: 0
      });

      const result = await dataSync.performBatchSync(largeDataSet, { chunkSize: 100 });

      expect(mockApiClient.batchSync).toHaveBeenCalledTimes(2);
      expect(result.totalProcessed).toBe(200); // Should be 200 (100 + 100) based on mock response
    });
  });

  describe('Real-time Synchronization', () => {
    it('should enable real-time sync mode', () => {
      const syncSpy = vi.fn();
      dataSync.onRealTimeSync(syncSpy);

      dataSync.enableRealTimeSync();

      expect(dataSync.isRealTimeSyncEnabled()).toBe(true);
    });

    it('should automatically sync on data changes', async () => {
      dataSync.enableRealTimeSync();

      const autoSyncSpy = vi.fn();
      dataSync.onAutoSync(autoSyncSpy);

      await dataSync.handleDataChange({ taskId: 'task1', completed: true });

      expect(autoSyncSpy).toHaveBeenCalledWith({ taskId: 'task1', completed: true });
    });

    it('should debounce rapid real-time sync requests', async () => {
      vi.useFakeTimers();
      dataSync.enableRealTimeSync();

      const debouncedSyncSpy = vi.fn();
      dataSync.onDebouncedSync(debouncedSyncSpy);

      // Trigger multiple rapid changes
      await dataSync.handleDataChange({ taskId: 'task1', completed: true });
      await dataSync.handleDataChange({ taskId: 'task1', completed: false });
      await dataSync.handleDataChange({ taskId: 'task1', completed: true });

      // Fast-forward debounce time
      vi.advanceTimersByTime(500);

      expect(debouncedSyncSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe('Data Validation and Integrity', () => {
    it('should validate data before synchronization', async () => {
      const invalidData = { taskId: null, completed: 'invalid' };

      const validationResult = await dataSync.validateData(invalidData);

      expect(validationResult.isValid).toBe(false);
      expect(validationResult.errors).toContain('taskId is required');
      expect(validationResult.errors).toContain('completed must be boolean');
    });

    it('should reject sync with invalid data', async () => {
      const invalidData = [
        { taskId: 'task1', completed: true },
        { taskId: null, completed: 'invalid' }
      ];

      mockApiClient.batchSync.mockRejectedValue(new Error('Validation failed'));

      const result = await dataSync.performBatchSync(invalidData);

      expect(result.success).toBe(false);
      expect(result.error).toContain('Validation failed');
    });

    it('should generate data checksums for integrity verification', () => {
      const data = { taskId: 'task1', completed: true, timestamp: 12345 };

      const checksum = dataSync.generateChecksum(data);

      expect(checksum).toBeDefined();
      expect(typeof checksum).toBe('string');
      expect(checksum.length).toBeGreaterThan(0);
    });

    it('should verify data integrity on load', async () => {
      const data = [{ taskId: 'task1', completed: true }];
      const checksum = dataSync.generateChecksum(data);

      mockLocalStorage.getItem.mockReturnValue(JSON.stringify({
        data: data,
        checksum: checksum
      }));

      const loadResult = await dataSync.loadLocalData();

      expect(loadResult.isValid).toBe(true);
      expect(loadResult.data).toEqual(data);
    });
  });

  describe('Performance Optimization', () => {
    it('should cache frequently accessed data', async () => {
      const data = [{ taskId: 'task1', completed: true }];

      mockLocalStorage.getItem.mockReturnValue(JSON.stringify(data));

      // First load
      await dataSync.loadLocalData();
      expect(mockLocalStorage.getItem).toHaveBeenCalledTimes(1);

      // Second load should use cache
      await dataSync.loadLocalData();
      expect(mockLocalStorage.getItem).toHaveBeenCalledTimes(1);
    });

    it('should invalidate cache on data updates', async () => {
      const originalData = [{ taskId: 'task1', completed: false }];
      const updatedData = [{ taskId: 'task1', completed: true }];

      mockLocalStorage.getItem.mockReturnValue(JSON.stringify(originalData));

      // Load and cache data
      await dataSync.loadLocalData();

      // Update data
      await dataSync.saveLocalData(updatedData);

      // Next load should reload from storage
      mockLocalStorage.getItem.mockReturnValue(JSON.stringify(updatedData));
      const result = await dataSync.loadLocalData();

      expect(result.data[0].completed).toBe(true);
    });

    it('should compress large datasets for storage', async () => {
      const largeDataSet = Array.from({ length: 1000 }, (_, i) => ({
        taskId: `task${i}`,
        completed: i % 2 === 0,
        metadata: `Large metadata string for task ${i}`.repeat(10)
      }));

      await dataSync.saveLocalData(largeDataSet, { compress: true });

      const savedData = mockLocalStorage.setItem.mock.calls[0][1];
      const uncompressedSize = JSON.stringify(largeDataSet).length;

      expect(savedData.length).toBeLessThan(uncompressedSize);
    });
  });
});
