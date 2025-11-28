/**
 * Integration tests for learning path selections API endpoints
 * Tests saving and loading selected learning paths to/from server
 */

import { describe, it, expect, beforeAll, afterAll, beforeEach, afterEach } from 'vitest';
import request from 'supertest';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

describe('Learning Path Selections API', () => {
  let app;
  let testProgressDir;

  beforeAll(async () => {
    // Set up test environment BEFORE any imports
    process.env.NODE_ENV = 'test';
    process.env.SKIP_FILE_WATCHER = 'true';

    // Set up test progress directory
    testProgressDir = path.join(__dirname, '../../test-selections');
    process.env.PROGRESS_DIR = testProgressDir;

    try {
      await fs.mkdir(testProgressDir, { recursive: true });
    } catch {
      // Directory might already exist
    }

    // Import the app
    const appModule = await import('../../app.js');
    app = appModule.default;
  }, 30000);

  afterAll(async () => {
    // Clean up test directory
    try {
      await fs.rm(testProgressDir, { recursive: true, force: true });
    } catch {
      // Directory might not exist
    }
  });

  beforeEach(async () => {
    // Clean up test files between tests
    const testFiles = ['learning-catalog-selections-test-user.json', 'learning-catalog-selections-default-user.json'];
    for (const file of testFiles) {
      const filepath = path.join(testProgressDir, file);
      try {
        await fs.unlink(filepath);
      } catch (error) {
        // Ignore if file doesn't exist
      }
    }
  });

  afterEach(async () => {
    // Cleanup test files after each test
    try {
      const files = await fs.readdir(testProgressDir);
      // Remove test files and any perf-* files from other tests
      const testFiles = files.filter(file =>
        file.startsWith('learning-catalog-selections-') ||
        file.startsWith('perf-')
      );
      for (const file of testFiles) {
        const filepath = path.join(testProgressDir, file);
        try {
          await fs.unlink(filepath);
        } catch (error) {
          // Ignore if file doesn't exist
        }
      }
    } catch (error) {
      // Directory might not exist
    }
  });

  describe('POST /api/learning/selections', () => {
    it('should save selected learning paths for default user', async () => {
      const selectedItems = ['paths-foundation-ai-first-engineering', 'paths-expert-enterprise-integration', 'paths-intermediate-devops-excellence'];

      const response = await request(app)
        .post('/api/learning/selections')
        .send({ selectedItems })
        .expect(200)
        .expect('Content-Type', /json/);

      expect(response.body.success).toBe(true);
      expect(response.body.data.selectionCount).toBeGreaterThan(3);
      expect(response.body.data.timestamp).toBeDefined();

      // Verify file was created
      const filepath = path.join(testProgressDir, 'learning-catalog-selections-default-user.json');
      const fileExists = await fs.access(filepath).then(() => true).catch(() => false);
      expect(fileExists).toBe(true);

      // Verify file contents
      const savedData = JSON.parse(await fs.readFile(filepath, 'utf-8'));
      expect(savedData.metadata.fileType).toBe('learning-catalog-selections');
      expect(savedData.metadata.userId).toBe('default-user');
      expect(savedData.selections.selectedItems.length).toBeGreaterThan(selectedItems.length);
      expect(savedData.selections.selectedItems).toEqual(expect.arrayContaining(selectedItems));
      expect(savedData.selections.selectionCount).toBeGreaterThan(3);
      expect(savedData.integrationData.syncMetadata.syncSource).toBe('progress-server');
    });

    it('should save selected learning paths for specific user', async () => {
      const selectedItems = ['paths-intermediate-infrastructure-architect', 'paths-expert-data-analytics-integration'];
      const userId = 'test-user';

      const response = await request(app)
        .post('/api/learning/selections')
        .send({ selectedItems, userId })
        .expect(200)
        .expect('Content-Type', /json/);

      expect(response.body.success).toBe(true);
      expect(response.body.data.selectionCount).toBeGreaterThanOrEqual(2);

      // Verify file contents
      const filepath = path.join(testProgressDir, 'learning-catalog-selections-test-user.json');
      const savedData = JSON.parse(await fs.readFile(filepath, 'utf-8'));
      expect(savedData.metadata.userId).toBe('test-user');
      expect(savedData.selections.selectedItems).toEqual(expect.arrayContaining(selectedItems));
      expect(savedData.selections.selectedItems.length).toBeGreaterThan(selectedItems.length);
    });

    it('should update existing selections file (not create new one)', async () => {
      const initialItems = ['paths-foundation-ai-first-engineering'];
      const updatedItems = ['paths-foundation-ai-first-engineering', 'paths-expert-enterprise-integration', 'paths-intermediate-devops-excellence'];

      // First save
      await request(app)
        .post('/api/learning/selections')
        .send({ selectedItems: initialItems })
        .expect(200);

      const filepath = path.join(testProgressDir, 'learning-catalog-selections-default-user.json');
      const firstSave = JSON.parse(await fs.readFile(filepath, 'utf-8'));
      const firstTimestamp = firstSave.timestamp;

      // Wait a bit to ensure different timestamp
      await new Promise(resolve => setTimeout(resolve, 10));

      // Second save (update)
      await request(app)
        .post('/api/learning/selections')
        .send({ selectedItems: updatedItems })
        .expect(200);

      const secondSave = JSON.parse(await fs.readFile(filepath, 'utf-8'));
      expect(secondSave.selections.selectedItems).toHaveLength(secondSave.selections.selectionCount);
      expect(secondSave.selections.selectionCount).toBeGreaterThan(2);
      expect(secondSave.timestamp).not.toBe(firstTimestamp);

      // Verify only one file exists (no duplicates)
      const files = await fs.readdir(testProgressDir);
      const selectionFiles = files.filter(f => f.startsWith('learning-catalog-selections-default-user'));
      expect(selectionFiles.length).toBe(1);
    });

    it('should handle empty selection array', async () => {
      const response = await request(app)
        .post('/api/learning/selections')
        .send({ selectedItems: [] })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.selectionCount).toBe(0);

      const filepath = path.join(testProgressDir, 'learning-catalog-selections-default-user.json');
      const savedData = JSON.parse(await fs.readFile(filepath, 'utf-8'));
      expect(savedData.selections.selectedItems).toEqual([]);
    });

    it('should reject invalid request (selectedItems not an array)', async () => {
      const response = await request(app)
        .post('/api/learning/selections')
        .send({ selectedItems: 'not-an-array' })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('must be an array');
    });

    it('should reject malformed JSON', async () => {
      const response = await request(app)
        .post('/api/learning/selections')
        .send('malformed json')
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBeDefined();
    });

    it('should handle large selection arrays', async () => {
      // Create array with all 5 signature learning paths
      const allPaths = [
        'paths-foundation-ai-first-engineering',
        'paths-intermediate-infrastructure-architect',
        'paths-intermediate-devops-excellence',
        'paths-expert-enterprise-integration',
        'paths-expert-data-analytics-integration'
      ];

      const response = await request(app)
        .post('/api/learning/selections')
        .send({ selectedItems: allPaths })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.selectionCount).toBeGreaterThanOrEqual(5);

      const filepath = path.join(testProgressDir, 'learning-catalog-selections-default-user.json');
      const savedData = JSON.parse(await fs.readFile(filepath, 'utf-8'));
      expect(savedData.selections.selectedItems).toHaveLength(savedData.selections.selectionCount);
    });
  });

  describe('GET /api/learning/selections', () => {
    it('should load saved selections for default user', async () => {
      const selectedItems = ['paths-foundation-ai-first-engineering', 'paths-expert-enterprise-integration'];

      // First save selections
      await request(app)
        .post('/api/learning/selections')
        .send({ selectedItems })
        .expect(200);

      // Then load them
      const response = await request(app)
        .get('/api/learning/selections')
        .expect(200)
        .expect('Content-Type', /json/);

      expect(response.body.success).toBe(true);
      expect(response.body.data.selections.selectedItems).toHaveLength(response.body.data.selections.selectionCount);
      expect(response.body.data.selections.selectionCount).toBeGreaterThanOrEqual(2);
      expect(response.body.data.userId).toBe('default-user');
    });

    it('should load selections for specific user', async () => {
      const selectedItems = ['paths-intermediate-devops-excellence'];
      const userId = 'test-user';

      // Save selections for test-user
      await request(app)
        .post('/api/learning/selections')
        .send({ selectedItems, userId })
        .expect(200);

      // Load selections for test-user
      const response = await request(app)
        .get(`/api/learning/selections?userId=${userId}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.selections.selectedItems).toEqual(expect.arrayContaining(selectedItems));
      expect(response.body.data.selections.selectedItems.length).toBeGreaterThan(selectedItems.length);
      expect(response.body.data.userId).toBe('test-user');
    });

    it('should return empty array when no selections file exists', async () => {
      const response = await request(app)
        .get('/api/learning/selections?userId=nonexistent-user')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.selections.selectedItems).toEqual([]);
      expect(response.body.data.selections.selectionCount).toBe(0);
      expect(response.body.data.userId).toBe('nonexistent-user');
    });

    it('should return empty array for default user with no selections', async () => {
      const response = await request(app)
        .get('/api/learning/selections')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.selections.selectedItems).toEqual([]);
      expect(response.body.data.selections.selectionCount).toBe(0);
    });

    it('should load most recent selections after multiple saves', async () => {
      const firstSave = ['paths-foundation-ai-first-engineering'];
      const secondSave = ['paths-foundation-ai-first-engineering', 'paths-expert-enterprise-integration'];
      const thirdSave = ['paths-expert-enterprise-integration', 'paths-intermediate-devops-excellence', 'paths-foundation-ai-first-engineering'];

      await request(app).post('/api/learning/selections').send({ selectedItems: firstSave });
      await request(app).post('/api/learning/selections').send({ selectedItems: secondSave });
      await request(app).post('/api/learning/selections').send({ selectedItems: thirdSave });

      const response = await request(app)
        .get('/api/learning/selections')
        .expect(200);

      expect(response.body.data.selections.selectedItems).toHaveLength(response.body.data.selections.selectionCount);
      expect(response.body.data.selections.selectionCount).toBeGreaterThan(2);
    });
  });

  describe('Cross-user isolation', () => {
    it('should maintain separate selections for different users', async () => {
      const user1Paths = ['paths-foundation-ai-first-engineering'];
      const user2Paths = ['paths-expert-enterprise-integration', 'paths-intermediate-infrastructure-architect'];

      // Save for user1
      await request(app)
        .post('/api/learning/selections')
        .send({ selectedItems: user1Paths, userId: 'user1' })
        .expect(200);

      // Save for user2
      await request(app)
        .post('/api/learning/selections')
        .send({ selectedItems: user2Paths, userId: 'user2' })
        .expect(200);

      // Load user1 selections
      const user1Response = await request(app)
        .get('/api/learning/selections?userId=user1')
        .expect(200);

      expect(user1Response.body.data.selections.selectedItems).toEqual(expect.arrayContaining(user1Paths));
      expect(user1Response.body.data.selections.selectedItems.length).toBeGreaterThan(user1Paths.length);

      // Load user2 selections
      const user2Response = await request(app)
        .get('/api/learning/selections?userId=user2')
        .expect(200);

      expect(user2Response.body.data.selections.selectedItems).toEqual(expect.arrayContaining(user2Paths));
      expect(user2Response.body.data.selections.selectedItems.length).toBeGreaterThan(user2Paths.length);

      // Verify they're different
      expect(user1Response.body.data.selections.selectedItems).not.toEqual(user2Response.body.data.selections.selectedItems);

      // Cleanup
      await fs.unlink(path.join(testProgressDir, 'learning-catalog-selections-user1.json'));
      await fs.unlink(path.join(testProgressDir, 'learning-catalog-selections-user2.json'));
    });
  });

  describe('Metadata validation', () => {
    it('should include all required metadata fields', async () => {
      await request(app)
        .post('/api/learning/selections')
        .send({ selectedItems: ['paths-foundation-ai-first-engineering'] })
        .expect(200);

      const filepath = path.join(testProgressDir, 'learning-catalog-selections-default-user.json');
      const savedData = JSON.parse(await fs.readFile(filepath, 'utf-8'));

      // Check metadata
      expect(savedData.metadata).toBeDefined();
      expect(savedData.metadata.version).toBe('1.0.0');
      expect(savedData.metadata.fileType).toBe('learning-catalog-selections');
      expect(savedData.metadata.userId).toBeDefined();
      expect(savedData.metadata.lastUpdated).toBeDefined();

      // Check selections
      expect(savedData.selections).toBeDefined();
      expect(savedData.selections.selectedItems).toBeDefined();
      expect(savedData.selections.selectionCount).toBeDefined();

      // Check timestamp
      expect(savedData.timestamp).toBeDefined();

      // Check integration data
      expect(savedData.integrationData).toBeDefined();
      expect(savedData.integrationData.syncMetadata).toBeDefined();
      expect(savedData.integrationData.syncMetadata.lastSync).toBeDefined();
      expect(savedData.integrationData.syncMetadata.syncSource).toBe('progress-server');
    });
  });
});
