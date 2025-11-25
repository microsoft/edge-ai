import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Mock fs.promises to control file operations during testing
vi.mock('fs/promises');

describe('Async File Operations', () => {
  const mockProgressDir = path.join(__dirname, '../../__test-data__/progress');
  const testFile = path.join(mockProgressDir, 'test-progress.json');
  const testData = {
    userId: 'test-user',
    progress: { completed: ['task1'], current: 'task2' }
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('Directory Operations', () => {
    it('should check directory existence asynchronously', async () => {
      // Mock fs.access for directory existence check
      fs.access = vi.fn().mockResolvedValue(undefined);

      try {
        await fs.access(mockProgressDir);
        expect(fs.access).toHaveBeenCalledWith(mockProgressDir);
      } catch (error) {
        // Directory doesn't exist - expected in some cases
        expect(error.code).toBe('ENOENT');
      }
    });

    it('should create directory asynchronously', async () => {
      fs.mkdir = vi.fn().mockResolvedValue(undefined);

      await fs.mkdir(mockProgressDir, { recursive: true });

      expect(fs.mkdir).toHaveBeenCalledWith(mockProgressDir, { recursive: true });
    });

    it('should read directory contents asynchronously', async () => {
      const mockFiles = ['file1.json', 'file2.json', 'file3.txt'];
      fs.readdir = vi.fn().mockResolvedValue(mockFiles);

      const files = await fs.readdir(mockProgressDir);

      expect(fs.readdir).toHaveBeenCalledWith(mockProgressDir);
      expect(files).toEqual(mockFiles);
    });
  });

  describe('File Operations', () => {
    it('should read file asynchronously', async () => {
      const mockContent = JSON.stringify(testData);
      fs.readFile = vi.fn().mockResolvedValue(mockContent);

      const content = await fs.readFile(testFile, 'utf8');
      const data = JSON.parse(content);

      expect(fs.readFile).toHaveBeenCalledWith(testFile, 'utf8');
      expect(data).toEqual(testData);
    });

    it('should write file asynchronously', async () => {
      fs.writeFile = vi.fn().mockResolvedValue(undefined);
      const content = JSON.stringify(testData, null, 2);

      await fs.writeFile(testFile, content);

      expect(fs.writeFile).toHaveBeenCalledWith(testFile, content);
    });

    it('should get file stats asynchronously', async () => {
      const mockStats = {
        mtime: new Date(),
        isFile: () => true,
        isDirectory: () => false
      };
      fs.stat = vi.fn().mockResolvedValue(mockStats);

      const stats = await fs.stat(testFile);

      expect(fs.stat).toHaveBeenCalledWith(testFile);
      expect(stats.isFile()).toBe(true);
      expect(stats.mtime).toBeInstanceOf(Date);
    });

    it('should handle file not found errors gracefully', async () => {
      const error = new Error('File not found');
      error.code = 'ENOENT';
      fs.readFile = vi.fn().mockRejectedValue(error);

      await expect(fs.readFile(testFile, 'utf8')).rejects.toThrow('File not found');
      expect(fs.readFile).toHaveBeenCalledWith(testFile, 'utf8');
    });
  });

  describe('Batch Operations', () => {
    it('should process multiple files asynchronously', async () => {
      const mockFiles = ['file1.json', 'file2.json'];
      const mockContents = [
        JSON.stringify({ id: 1, data: 'test1' }),
        JSON.stringify({ id: 2, data: 'test2' })
      ];

      fs.readdir = vi.fn().mockResolvedValue(mockFiles);
      fs.readFile = vi.fn()
        .mockResolvedValueOnce(mockContents[0])
        .mockResolvedValueOnce(mockContents[1]);

      const files = await fs.readdir(mockProgressDir);
      const contents = await Promise.all(
        files.map(file => fs.readFile(path.join(mockProgressDir, file), 'utf8'))
      );

      expect(fs.readdir).toHaveBeenCalledWith(mockProgressDir);
      expect(fs.readFile).toHaveBeenCalledTimes(2);
      expect(contents).toHaveLength(2);

      const parsedContents = contents.map(content => JSON.parse(content));
      expect(parsedContents[0].id).toBe(1);
      expect(parsedContents[1].id).toBe(2);
    });

    it('should handle mixed success/failure in batch operations', async () => {
      const mockFiles = ['file1.json', 'missing.json', 'file3.json'];
      const error = new Error('File not found');
      error.code = 'ENOENT';

      fs.readdir = vi.fn().mockResolvedValue(mockFiles);
      fs.readFile = vi.fn()
        .mockResolvedValueOnce('{"id": 1}')
        .mockRejectedValueOnce(error)
        .mockResolvedValueOnce('{"id": 3}');

      const files = await fs.readdir(mockProgressDir);

      // Use Promise.allSettled to handle mixed results
      const results = await Promise.allSettled(
        files.map(file => fs.readFile(path.join(mockProgressDir, file), 'utf8'))
      );

      expect(results).toHaveLength(3);
      expect(results[0].status).toBe('fulfilled');
      expect(results[1].status).toBe('rejected');
      expect(results[2].status).toBe('fulfilled');

      const successfulResults = results
        .filter(result => result.status === 'fulfilled')
        .map(result => JSON.parse(result.value));

      expect(successfulResults).toHaveLength(2);
      expect(successfulResults[0].id).toBe(1);
      expect(successfulResults[1].id).toBe(3);
    });
  });

  describe('Performance Considerations', () => {
    it('should use concurrent operations for better performance', async () => {
      const mockFiles = Array.from({ length: 10 }, (_, i) => `file${i}.json`);
      const _startTime = Date.now();

      fs.readdir = vi.fn().mockResolvedValue(mockFiles);
      fs.readFile = vi.fn().mockImplementation(() =>
        new Promise(resolve => setTimeout(() => resolve('{"test": true}'), 10))
      );

      await fs.readdir(mockProgressDir);

      // Concurrent processing
      const concurrentStart = Date.now();
      await Promise.all(
        mockFiles.map(file => fs.readFile(path.join(mockProgressDir, file), 'utf8'))
      );
      const concurrentTime = Date.now() - concurrentStart;

      // Sequential processing for comparison
      const sequentialStart = Date.now();
      for (const file of mockFiles) {
        await fs.readFile(path.join(mockProgressDir, file), 'utf8');
      }
      const sequentialTime = Date.now() - sequentialStart;

      // Concurrent should be significantly faster
      expect(concurrentTime).toBeLessThan(sequentialTime * 0.8);
    });
  });
});
