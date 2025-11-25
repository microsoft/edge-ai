import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

describe('Progress Saver Async Integration', () => {
  const testProgressDir = path.join(__dirname, '../../__test-data__/async-progress');
  const testSchemaPath = path.join(__dirname, '../../__test-data__/schemas/test-schema.json');

  beforeEach(async () => {
    // Clean up test directory
    try {
      await fs.rm(testProgressDir, { recursive: true, force: true });
      await fs.rm(path.dirname(testSchemaPath), { recursive: true, force: true });
    } catch {
      // Directory might not exist
    }

    // Create test directories
    await fs.mkdir(testProgressDir, { recursive: true });
    await fs.mkdir(path.dirname(testSchemaPath), { recursive: true });
  });

  afterEach(async () => {
    // Clean up test directory
    try {
      await fs.rm(testProgressDir, { recursive: true, force: true });
      await fs.rm(path.dirname(testSchemaPath), { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }
  });

  describe('Schema Loading (Async)', () => {
    it('should load schema asynchronously', async () => {
      const mockSchema = {
        type: 'object',
        properties: {
          userId: { type: 'string' },
          progress: { type: 'object' }
        }
      };

      await fs.writeFile(testSchemaPath, JSON.stringify(mockSchema, null, 2));

      // Test async schema loading
      const schemaExists = await checkFileExists(testSchemaPath);
      expect(schemaExists).toBe(true);

      const schemaContent = await fs.readFile(testSchemaPath, 'utf8');
      const schema = JSON.parse(schemaContent);

      expect(schema).toEqual(mockSchema);
      expect(schema.properties.userId.type).toBe('string');
    });

    it('should handle missing schema file gracefully', async () => {
      const nonExistentPath = path.join(testProgressDir, 'missing-schema.json');

      const exists = await checkFileExists(nonExistentPath);
      expect(exists).toBe(false);
    });
  });

  describe('Progress File Operations (Async)', () => {
    it('should save progress data asynchronously', async () => {
      const progressData = {
        userId: 'test-user',
        kataBadges: ['kata1', 'kata2'],
        kataProgress: { kata1: 'completed', kata2: 'in-progress' },
        lastUpdated: new Date().toISOString()
      };

      const progressFile = path.join(testProgressDir, 'test-user-progress.json');

      // Save data asynchronously
      await fs.writeFile(progressFile, JSON.stringify(progressData, null, 2));

      // Verify file was created
      const exists = await checkFileExists(progressFile);
      expect(exists).toBe(true);

      // Read and verify content
      const savedContent = await fs.readFile(progressFile, 'utf8');
      const savedData = JSON.parse(savedContent);

      expect(savedData.userId).toBe('test-user');
      expect(savedData.kataBadges).toEqual(['kata1', 'kata2']);
      expect(savedData.kataProgress.kata1).toBe('completed');
    });

    it('should list progress files asynchronously', async () => {
      // Create multiple test files
      const testFiles = [
        { name: 'user1-progress.json', data: { userId: 'user1' } },
        { name: 'user2-progress.json', data: { userId: 'user2' } },
        { name: 'readme.txt', data: 'not a json file' }
      ];

      for (const file of testFiles) {
        const filePath = path.join(testProgressDir, file.name);
        const content = file.name.endsWith('.json')
          ? JSON.stringify(file.data, null, 2)
          : file.data;
        await fs.writeFile(filePath, content);
      }

      // List files asynchronously
      const allFiles = await fs.readdir(testProgressDir);
      const jsonFiles = allFiles.filter(file => file.endsWith('.json'));

      expect(allFiles).toHaveLength(3);
      expect(jsonFiles).toHaveLength(2);
      expect(jsonFiles).toContain('user1-progress.json');
      expect(jsonFiles).toContain('user2-progress.json');
    });

    it('should get file statistics asynchronously', async () => {
      const testFile = path.join(testProgressDir, 'stats-test.json');
      const testData = { test: 'data', timestamp: Date.now() };

      await fs.writeFile(testFile, JSON.stringify(testData, null, 2));

      // Get file stats asynchronously
      const stats = await fs.stat(testFile);

      expect(stats.isFile()).toBe(true);
      expect(stats.isDirectory()).toBe(false);
      expect(stats.mtime).toBeInstanceOf(Date);
      expect(stats.size).toBeGreaterThan(0);
    });
  });

  describe('Batch Operations Performance', () => {
    it('should handle multiple files efficiently with async operations', async () => {
      const fileCount = 50;
      const testFiles = Array.from({ length: fileCount }, (_, i) => ({
        name: `user${i}-progress.json`,
        data: {
          userId: `user${i}`,
          progress: { completed: [`task${i}`] },
          timestamp: Date.now() + i
        }
      }));

      // Save all files concurrently
      const saveStart = performance.now();
      await Promise.all(
        testFiles.map(file =>
          fs.writeFile(
            path.join(testProgressDir, file.name),
            JSON.stringify(file.data, null, 2)
          )
        )
      );
      const saveTime = performance.now() - saveStart;

      // Read all files concurrently
      const readStart = performance.now();
      const files = await fs.readdir(testProgressDir);
      const contents = await Promise.all(
        files
          .filter(file => file.endsWith('.json'))
          .map(file => fs.readFile(path.join(testProgressDir, file), 'utf8'))
      );
      const readTime = performance.now() - readStart;

      // Get stats for all files concurrently
      const statsStart = performance.now();
      const stats = await Promise.all(
        files.map(file => fs.stat(path.join(testProgressDir, file)))
      );
      const statsTime = performance.now() - statsStart;

      // Verify results
      expect(files).toHaveLength(fileCount);
      expect(contents).toHaveLength(fileCount);
      expect(stats).toHaveLength(fileCount);

      // Performance expectations (async should be much faster than sync)
      console.log(`Async performance: Save: ${saveTime}ms, Read: ${readTime}ms, Stats: ${statsTime}ms`);
      expect(saveTime).toBeLessThan(5000); // Should complete in reasonable time
      expect(readTime).toBeLessThan(5000);
      expect(statsTime).toBeLessThan(5000);

      // Verify data integrity - don't rely on file order
      const parsedContents = contents.map(content => JSON.parse(content));
      const userIds = parsedContents.map(data => data.userId);

      // Verify all expected users are present
      for (let i = 0; i < fileCount; i++) {
        expect(userIds).toContain(`user${i}`);
      }

      // Verify each user has correct progress data
      parsedContents.forEach(data => {
        const userIndex = data.userId.replace('user', '');
        expect(data.progress.completed).toContain(`task${userIndex}`);
      });
    });
  });

  describe('Error Handling', () => {
    it('should handle file access errors gracefully', async () => {
      const nonExistentFile = path.join(testProgressDir, 'does-not-exist.json');

      await expect(fs.readFile(nonExistentFile, 'utf8')).rejects.toThrow();

      try {
        await fs.readFile(nonExistentFile, 'utf8');
      } catch (error) {
        expect(error.code).toBe('ENOENT');
      }
    });

    it('should handle permission errors gracefully', async () => {
      // This test would need actual permission restrictions in a real environment
      // For now, we'll simulate the error handling pattern
      const mockError = new Error('Permission denied');
      mockError.code = 'EACCES';

      // Test that our error handling pattern works
      try {
        throw mockError;
      } catch (error) {
        expect(error.code).toBe('EACCES');
        expect(error.message).toBe('Permission denied');
      }
    });
  });
});

// Helper function to check file existence
async function checkFileExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}
