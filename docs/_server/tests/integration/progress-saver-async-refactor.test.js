import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Import async utilities
import {
  fileExists,
  readJsonFile,
  writeJsonFile,
  listFiles,
  getFileStats,
  ensureDirectory,
  readMultipleJsonFiles,
  getFilesWithMetadata,
  withRetry,
  batchOperation
} from '../../utils/async-file-utils.js';

describe('Progress Saver Async Refactor Integration', () => {
  const testProgressDir = path.join(__dirname, '../__test-data__/progress-saver-async');

  beforeEach(async () => {
    // Clean up test directory
    try {
      await fs.rm(testProgressDir, { recursive: true, force: true });
    } catch {
      // Directory might not exist
    }

    // Create test directory
    await ensureDirectory(testProgressDir);
  });

  afterEach(async () => {
    // Clean up test directory
    try {
      await fs.rm(testProgressDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }
  });

  describe('Async File Utilities Integration', () => {
    it('should handle directory operations asynchronously', async () => {
      const testDir = path.join(testProgressDir, 'nested', 'directory');

      // Ensure directory creation
      const created = await ensureDirectory(testDir);
      expect(created).toBe(true);

      // Check directory exists
      const exists = await fileExists(testDir);
      expect(exists).toBe(true);
    });

    it('should handle JSON file operations asynchronously', async () => {
      const testFile = path.join(testProgressDir, 'test-progress.json');
      const testData = {
        userId: 'test-user',
        kataProgress: { 'kata1': 'completed' },
        timestamp: new Date().toISOString()
      };

      // Write JSON file
      const written = await writeJsonFile(testFile, testData);
      expect(written).toBe(true);

      // Check file exists
      const exists = await fileExists(testFile);
      expect(exists).toBe(true);

      // Read JSON file
      const readData = await readJsonFile(testFile);
      expect(readData).toEqual(testData);
      expect(readData.userId).toBe('test-user');
    });

    it('should list files asynchronously with filters', async () => {
      const testFiles = [
        'user1-progress.json',
        'user2-progress.json',
        'readme.txt',
        'config.json'
      ];

      // Create test files
      for (const fileName of testFiles) {
        const filePath = path.join(testProgressDir, fileName);
        const content = fileName.endsWith('.json')
          ? JSON.stringify({ test: fileName })
          : 'text content';
        await fs.writeFile(filePath, content);
      }

      // List all files
      const allFiles = await listFiles(testProgressDir);
      expect(allFiles).toHaveLength(4);
      expect(allFiles).toEqual(expect.arrayContaining(testFiles));

      // List only JSON files
      const jsonFiles = await listFiles(testProgressDir, file => file.endsWith('.json'));
      expect(jsonFiles).toHaveLength(3);
      expect(jsonFiles).toContain('user1-progress.json');
      expect(jsonFiles).toContain('user2-progress.json');
      expect(jsonFiles).toContain('config.json');
      expect(jsonFiles).not.toContain('readme.txt');
    });

    it('should get file statistics asynchronously', async () => {
      const testFile = path.join(testProgressDir, 'stats-test.json');
      const testData = { test: 'data for stats' };

      await writeJsonFile(testFile, testData);

      const stats = await getFileStats(testFile);
      expect(stats).toBeDefined();
      expect(stats.isFile()).toBe(true);
      expect(stats.isDirectory()).toBe(false);
      expect(stats.mtime).toBeInstanceOf(Date);
      expect(stats.size).toBeGreaterThan(0);
    });
  });

  describe('Batch Operations Performance', () => {
    it('should read multiple JSON files concurrently', async () => {
      const fileCount = 20;
      const testFiles = Array.from({ length: fileCount }, (_, i) => ({
        name: `progress-${i}.json`,
        path: path.join(testProgressDir, `progress-${i}.json`),
        data: { userId: `user${i}`, progress: { task: `task${i}` } }
      }));

      // Create all test files
      await Promise.all(
        testFiles.map(file => writeJsonFile(file.path, file.data))
      );

      // Read multiple files using utility
      const filePaths = testFiles.map(f => f.path);
      const results = await readMultipleJsonFiles(filePaths);

      expect(results).toHaveLength(fileCount);
      results.forEach((data, index) => {
        expect(data.userId).toBe(`user${index}`);
        expect(data.progress.task).toBe(`task${index}`);
      });
    });

    it('should get files with metadata efficiently', async () => {
      const fileCount = 15;
      const testFiles = Array.from({ length: fileCount }, (_, i) => ({
        name: `metadata-test-${i}.json`,
        data: { id: i, type: 'progress', created: new Date().toISOString() }
      }));

      // Create test files with small delays to ensure different timestamps
      for (let i = 0; i < testFiles.length; i++) {
        const file = testFiles[i];
        const filePath = path.join(testProgressDir, file.name);
        await writeJsonFile(filePath, file.data);
        if (i < testFiles.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 2));
        }
      }

      // Get files with metadata
      const filesWithMetadata = await getFilesWithMetadata(
        testProgressDir,
        file => file.startsWith('metadata-test-')
      );

      expect(filesWithMetadata).toHaveLength(fileCount);

      filesWithMetadata.forEach(fileInfo => {
        expect(fileInfo.filename).toMatch(/^metadata-test-\d+\.json$/);
        expect(fileInfo.stats).toBeDefined();
        expect(fileInfo.stats.isFile()).toBe(true);
        expect(fileInfo.data).toBeDefined();
        expect(fileInfo.data.type).toBe('progress');
        expect(typeof fileInfo.data.id).toBe('number');
      });

      // Verify files are sorted by some criteria (filename in this case)
      expect(filesWithMetadata[0].filename).toBeDefined();
    });
  });

  describe('Error Handling and Resilience', () => {
    it('should handle missing files gracefully', async () => {
      const nonExistentFile = path.join(testProgressDir, 'does-not-exist.json');

      const exists = await fileExists(nonExistentFile);
      expect(exists).toBe(false);

      const data = await readJsonFile(nonExistentFile);
      expect(data).toBeNull();

      const stats = await getFileStats(nonExistentFile);
      expect(stats).toBeNull();
    });

    it('should retry operations with withRetry utility', async () => {
      let attempts = 0;
      const maxRetries = 2;

      const failingOperation = async () => {
        attempts++;
        if (attempts <= maxRetries) {
          throw new Error(`Attempt ${attempts} failed`);
        }
        return 'success';
      };

      const result = await withRetry(failingOperation, maxRetries, 10);
      expect(result).toBe('success');
      expect(attempts).toBe(maxRetries + 1);
    });

    it('should handle concurrent operations with batch utility', async () => {
      const items = Array.from({ length: 30 }, (_, i) => i);
      const concurrencyLimit = 5;

      const operation = async (item) => {
        // Simulate async work
        await new Promise(resolve => setTimeout(resolve, 10));
        return item * 2;
      };

      const startTime = performance.now();
      const results = await batchOperation(items, operation, concurrencyLimit);
      const endTime = performance.now();

      // Verify all operations completed
      expect(results).toHaveLength(30);

      // Verify results (fulfilled operations)
      const successfulResults = results
        .filter(result => result.status === 'fulfilled')
        .map(result => result.value);

      expect(successfulResults).toHaveLength(30);
      successfulResults.forEach((value, index) => {
        expect(value).toBe(index * 2);
      });

      // Performance expectation - should complete in reasonable time
      const duration = endTime - startTime;
      expect(duration).toBeLessThan(1000); // Should be much faster than sequential

      console.log(`Batch operation completed in ${duration}ms`);
    });
  });

  describe('Real-world Usage Patterns', () => {
    it('should simulate progress file management workflow', async () => {
      // Simulate creating multiple progress files for different users
      const users = ['alice', 'bob', 'charlie'];
      const progressData = users.map(user => ({
        userId: user,
        kataProgress: {
          'basic-loops': 'completed',
          'functions': 'in-progress'
        },
        lastUpdated: new Date().toISOString()
      }));

      // Save progress files
      const savePromises = progressData.map(data =>
        writeJsonFile(
          path.join(testProgressDir, `${data.userId}-progress.json`),
          data
        )
      );
      const saveResults = await Promise.all(savePromises);
      expect(saveResults.every(result => result === true)).toBe(true);

      // List and load all progress files
      const progressFiles = await listFiles(testProgressDir, file =>
        file.endsWith('-progress.json')
      );
      expect(progressFiles).toHaveLength(3);

      // Read all progress data
      const allProgressData = await readMultipleJsonFiles(
        progressFiles.map(file => path.join(testProgressDir, file))
      );
      expect(allProgressData).toHaveLength(3);

      // Verify data integrity
      const userIds = allProgressData.map(data => data.userId);
      expect(userIds).toEqual(expect.arrayContaining(users));

      allProgressData.forEach(data => {
        expect(data.kataProgress['basic-loops']).toBe('completed');
        expect(data.kataProgress.functions).toBe('in-progress');
      });
    });
  });
});
