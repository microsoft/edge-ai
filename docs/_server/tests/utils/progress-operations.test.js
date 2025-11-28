/**
 * Progress Operations Tests
 * Tests for the simple progress utility functions
 */

import { vi, describe, test, expect, beforeEach, afterEach } from 'vitest';
import { promises as fs } from 'fs';
import {
  getProgressDir,
  saveProgressData,
  loadProgressData,
  getProgressSyncStatus,
  getLatestProgressFile,
  listProgressFiles
} from '../../utils/progress-operations.js';

// Mock file system operations
vi.mock('fs', () => ({
  promises: {
    mkdir: vi.fn(),
    writeFile: vi.fn(),
    readdir: vi.fn(),
    readFile: vi.fn(),
    stat: vi.fn()
  }
}));

// Mock schema validator
vi.mock('../../utils/schema-validator.js', () => ({
  validateAndSanitizeProgress: vi.fn(),
  generateProgressFilename: vi.fn()
}));

describe('Progress Operations', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    // Set test environment
    process.env.PROGRESS_DIR = '/test/progress';
  });

  afterEach(() => {
    delete process.env.PROGRESS_DIR;
  });

  describe('getProgressDir', () => {
    test('should return environment variable path when set', () => {
      expect(getProgressDir()).toBe('/test/progress');
    });

    test('should return default path when environment variable not set', () => {
      delete process.env.PROGRESS_DIR;
      const result = getProgressDir();
      // Cross-platform path check - normalize separators and check end path
      const normalizedResult = result.replace(/\\/g, '/');
      expect(normalizedResult).toContain('.copilot-tracking/learning');
    });
  });

  describe('saveProgressData', () => {
    test('should save progress data successfully', async () => {
      const { validateAndSanitizeProgress, generateProgressFilename } = await import('../../utils/schema-validator.js');

      validateAndSanitizeProgress.mockResolvedValue({
        data: { test: 'data', timestamp: '2025-01-01T00:00:00.000Z' }
      });
      generateProgressFilename.mockReturnValue('test-file.json');
      fs.mkdir.mockResolvedValue();
      fs.writeFile.mockResolvedValue();

      const result = await saveProgressData({ test: 'data' }, 'self-assessment');

      expect(result.filename).toBe('test-file.json');
      expect(result.type).toBe('self-assessment');
      expect(fs.mkdir).toHaveBeenCalledWith('/test/progress', { recursive: true });
      expect(fs.writeFile).toHaveBeenCalled();
    });
  });

  describe('loadProgressData', () => {
    test('should load progress data successfully', async () => {
      const { validateAndSanitizeProgress } = await import('../../utils/schema-validator.js');

      fs.readdir.mockResolvedValue(['test-123.json', 'other-456.json']);
      fs.readFile.mockResolvedValue('{"test": "data"}');
      validateAndSanitizeProgress.mockResolvedValue({
        data: { test: 'data' },
        validation: { valid: true }
      });

      const result = await loadProgressData('self-assessment', 'test');

      expect(result.progress).toEqual({ test: 'data' });
      expect(result.filename).toBe('test-123.json');
      expect(result.type).toBe('self-assessment');
      expect(result.id).toBe('test');
    });

    test('should throw error for invalid progress type', async () => {
      await expect(loadProgressData('invalid-type', 'test'))
        .rejects.toThrow('Invalid progress type: invalid-type');
    });

    test('should throw error when no files found', async () => {
      fs.readdir.mockResolvedValue(['other-456.json']);

      await expect(loadProgressData('self-assessment', 'test'))
        .rejects.toThrow('Progress not found: test');
    });
  });

  describe('getProgressSyncStatus', () => {
    test('should return sync status', async () => {
      fs.readdir.mockResolvedValue(['file1.json', 'file2.json', 'readme.txt']);

      const result = await getProgressSyncStatus();

      expect(result.totalFiles).toBe(2);
    });

    test('should return type-specific stats when type provided', async () => {
      fs.readdir.mockResolvedValue(['assessment-123.json', 'kata-456.json']);

      const result = await getProgressSyncStatus('self-assessment');

      expect(result.typeStats.type).toBe('self-assessment');
      expect(result.typeStats.files).toBe(1);
    });
  });

  describe('getLatestProgressFile', () => {
    test('should return latest progress file', async () => {
      fs.readdir.mockResolvedValue(['file1.json', 'file2.json']);
      fs.stat.mockResolvedValue({ mtime: new Date('2025-01-01') });
      fs.readFile.mockResolvedValue('{"metadata": {"test": "data"}, "timestamp": "2025-01-01T00:00:00.000Z"}');

      const result = await getLatestProgressFile();

      expect(result.filename).toBe('file2.json');
      expect(result.metadata).toEqual({ test: 'data' });
    });

    test('should throw error when no files found', async () => {
      fs.readdir.mockResolvedValue([]);

      await expect(getLatestProgressFile())
        .rejects.toThrow('No progress files found');
    });
  });

  describe('listProgressFiles', () => {
    test('should list all progress files with metadata', async () => {
      fs.readdir.mockResolvedValue(['file1.json', 'file2.json']);

      // Mock different modification times - file2 is newer so should be first
      fs.stat.mockResolvedValueOnce({
        mtime: new Date('2025-01-01T00:00:00Z'), // older
        size: 1024
      }).mockResolvedValueOnce({
        mtime: new Date('2025-01-01T01:00:00Z'), // newer
        size: 2048
      });

      fs.readFile.mockResolvedValueOnce('{"metadata": {"fileType": "self-assessment", "assessmentId": "test1"}, "assessment": {"status": "completed"}, "timestamp": "2025-01-01T00:00:00.000Z"}')
                   .mockResolvedValueOnce('{"metadata": {"fileType": "kata-progress", "kataId": "test2"}, "progress": {"completed": 5}, "timestamp": "2025-01-01T01:00:00.000Z"}');

      const result = await listProgressFiles();

      expect(result).toHaveLength(2);
      // file2.json should be first because it's newer (sorted by mtime desc)
      expect(result[0].filename).toBe('file2.json');
      expect(result[0].type).toBe('kata-progress');
      expect(result[1].filename).toBe('file1.json');
      expect(result[1].type).toBe('self-assessment');
    });

    test('should handle corrupted files gracefully', async () => {
      fs.readdir.mockResolvedValue(['file1.json', 'corrupted.json']);
      fs.stat.mockResolvedValue({
        mtime: new Date('2025-01-01'),
        size: 1024
      });
      fs.readFile.mockResolvedValueOnce('{"metadata": {"fileType": "self-assessment", "assessmentId": "test3"}, "assessment": {"status": "in-progress"}, "timestamp": "2025-01-01T00:00:00.000Z"}')
                   .mockRejectedValueOnce(new Error('File corrupted'));

      const result = await listProgressFiles();

      expect(result).toHaveLength(1);
      expect(result[0].filename).toBe('file1.json');
    });
  });
});
