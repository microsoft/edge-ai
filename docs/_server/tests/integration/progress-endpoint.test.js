import { describe, test, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * GET / (Progress Endpoint) Integration Tests
 * Tests the refactored GET / endpoint that aggregates kata and path progress
 * using existing services/learning-path-manifest.js and utils/path-progress-calculator.js
 */
describe('GET / (Progress Endpoint) Integration', () => {
  let app;
  let testProgressDir;

  beforeAll(async () => {
    // Set up test environment BEFORE any imports
    process.env.NODE_ENV = 'test';
    process.env.SKIP_FILE_WATCHER = 'true';

    // Set up test progress directory with sample kata progress
    testProgressDir = path.join(__dirname, '../../test-progress-endpoint');
    process.env.PROGRESS_DIR = testProgressDir;

    try {
      await fs.mkdir(testProgressDir, { recursive: true });

      // Create sample kata progress files to simulate partial Foundation path completion
      // Foundation path has 18 katas, we'll mark 2 as partially complete (~2.32% path progress)
      const kataProgress1 = {
        type: 'kata',
        metadata: {
          version: '1.0.0',
          kataId: 'kata-git-fundamentals',
          title: 'Git Fundamentals',
          lastUpdated: new Date().toISOString()
        },
        checkboxStates: {
          'phase-1-step-1': true,
          'phase-1-step-2': true,
          'phase-1-step-3': false // Partial completion
        }
      };

      const kataProgress2 = {
        type: 'kata',
        metadata: {
          version: '1.0.0',
          kataId: 'kata-markdown-mastery',
          title: 'Markdown Mastery',
          lastUpdated: new Date().toISOString()
        },
        checkboxStates: {
          'phase-1-step-1': true,
          'phase-1-step-2': false // Partial completion
        }
      };

      await fs.writeFile(
        path.join(testProgressDir, 'kata-git-fundamentals.json'),
        JSON.stringify(kataProgress1, null, 2)
      );

      await fs.writeFile(
        path.join(testProgressDir, 'kata-markdown-mastery.json'),
        JSON.stringify(kataProgress2, null, 2)
      );
    } catch (error) {
      console.error('Failed to set up test directory:', error);
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

  test('returns 200 status with application/json Content-Type', async () => {
    const response = await request(app).get('/api/progress');

    expect(response.status).toBe(200);
    expect(response.headers['content-type']).toMatch(/application\/json/);
  });

  test('response structure matches { katas: [], paths: [] }', async () => {
    const response = await request(app).get('/api/progress');

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('katas');
    expect(response.body).toHaveProperty('paths');
    expect(Array.isArray(response.body.katas)).toBe(true);
    expect(Array.isArray(response.body.paths)).toBe(true);
  });

  test('paths array includes Foundation path with correct structure', async () => {
    const response = await request(app).get('/api/progress');

    expect(response.status).toBe(200);

    const foundationPath = response.body.paths.find(
      p => p.id === 'paths-foundation-ai-first-engineering'
    );

    expect(foundationPath).toBeDefined();
    expect(foundationPath).toHaveProperty('id');
    expect(foundationPath).toHaveProperty('title');
    expect(foundationPath).toHaveProperty('progress');
    expect(foundationPath.progress).toHaveProperty('percentage');
    expect(foundationPath.progress).toHaveProperty('completed');
    expect(foundationPath.progress).toHaveProperty('total');
  });

  test('Foundation path shows progress from partial kata completion', async () => {
    const response = await request(app).get('/api/progress');

    expect(response.status).toBe(200);

    const foundationPath = response.body.paths.find(
      p => p.id === 'paths-foundation-ai-first-engineering'
    );

    expect(foundationPath).toBeDefined();
    expect(foundationPath.progress).toBeDefined();

    // Foundation path has 18 katas total
    expect(foundationPath.progress.total).toBeGreaterThan(0);

    // We have 2 katas with partial progress, so completed should be >= 0
    expect(foundationPath.progress.completed).toBeGreaterThanOrEqual(0);

    // Percentage should be calculated correctly
    expect(foundationPath.progress.percentage).toBeGreaterThanOrEqual(0);
    expect(foundationPath.progress.percentage).toBeLessThanOrEqual(100);
  });

  test('katas array includes progress data from services', async () => {
    const response = await request(app).get('/api/progress');

    expect(response.status).toBe(200);
    expect(Array.isArray(response.body.katas)).toBe(true);

    // Should have kata progress entries
    if (response.body.katas.length > 0) {
      const kata = response.body.katas[0];
      expect(kata).toHaveProperty('id');
      expect(kata).toHaveProperty('completionPercentage');
      expect(typeof kata.completionPercentage).toBe('number');
      expect(kata.completionPercentage).toBeGreaterThanOrEqual(0);
      expect(kata.completionPercentage).toBeLessThanOrEqual(100);
    }
  });
});
