import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

describe('Progress API Integration Tests', () => {
  let app;
  let testProgressDir;

  beforeAll(async () => {
    // Set up test environment BEFORE any imports
    process.env.NODE_ENV = 'test';
    process.env.SKIP_FILE_WATCHER = 'true';

    // Set up test progress directory
    testProgressDir = path.join(__dirname, '../../test-progress-api');
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
  const createProgressData = (id = 'test-progress') => ({
    type: 'self-assessment',
    metadata: {
      version: '1.0.0',
      assessmentId: id,
      assessmentTitle: `Test Assessment ${id}`,
      source: 'ui',
      fileType: 'self-assessment',
      category: 'ai-assisted-engineering',
      lastUpdated: new Date().toISOString()
    },
    assessment: {
      questions: [
        {
          id: 'q1',
          question: 'Test question 1',
          category: 'ai-assisted-engineering',
          response: 3,
          responseText: 'Test response',
          timestamp: new Date().toISOString()
        }
      ],
      results: {
        categoryScores: {
          'ai-assisted-engineering': {
            score: 3,
            level: 'intermediate',
            questionsCount: 1,
            totalPoints: 3,
            maxPoints: 5
          },
          'prompt-engineering': {
            score: 3,
            level: 'intermediate',
            questionsCount: 1,
            totalPoints: 3,
            maxPoints: 5
          },
          'edge-deployment': {
            score: 3,
            level: 'intermediate',
            questionsCount: 1,
            totalPoints: 3,
            maxPoints: 5
          },
          'system-troubleshooting': {
            score: 3,
            level: 'intermediate',
            questionsCount: 1,
            totalPoints: 3,
            maxPoints: 5
          },
          'project-planning': {
            score: 3,
            level: 'intermediate',
            questionsCount: 1,
            totalPoints: 3,
            maxPoints: 5
          },
          'data-analytics': {
            score: 3,
            level: 'intermediate',
            questionsCount: 1,
            totalPoints: 3,
            maxPoints: 5
          }
        },
        overallScore: 3,
        overallLevel: 'intermediate',
        recommendedPath: 'intermediate'
      }
    },
    timestamp: new Date().toISOString()
  });

  describe('Progress Data Workflow', () => {
    it('should handle complete progress submission workflow', async () => {
      const progressData = createProgressData('workflow-test');

      // Submit progress
      const response = await request(app)
        .post('/api/progress/save')
        .send(progressData)
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('filename');
      expect(response.body.data).toHaveProperty('type', 'self-assessment');

      // Load progress
      const loadResponse = await request(app)
        .get('/api/progress/load/self-assessment/workflow-test')
        .expect(200);

      expect(loadResponse.body.success).toBe(true);
      expect(loadResponse.body.data.metadata.assessmentId).toBe('workflow-test');
    });

    it('should handle multiple progress submissions for same assessment', async () => {
      const progressData1 = createProgressData('multi-test');
      const progressData2 = createProgressData('multi-test');

      // Modify second submission
      progressData2.assessment.questions[0].response = 4;

      // Submit first progress
      const response1 = await request(app)
        .post('/api/progress/save')
        .send(progressData1)
        .expect(200);

      expect(response1.body.success).toBe(true);

      // Submit second progress (same ID)
      const response2 = await request(app)
        .post('/api/progress/save')
        .send(progressData2)
        .expect(200);

      expect(response2.body.success).toBe(true);

      // Load should return the most recent
      const loadResponse = await request(app)
        .get('/api/progress/load/self-assessment/multi-test')
        .expect(200);

      expect(loadResponse.body.success).toBe(true);
      // Should have the updated response value
      expect(loadResponse.body.data.progress.assessment.questions[0].response).toBe(4);
    });

    it('should handle progress updates (overwriting existing data)', async () => {
      const initialData = createProgressData('update-test');
      const updatedData = createProgressData('update-test');

      // Modify updated data
      updatedData.assessment.questions[0].responseText = 'Updated response';

      // Submit initial data
      await request(app)
        .post('/api/progress/save')
        .send(initialData)
        .expect(200);

      // Submit updated data
      await request(app)
        .post('/api/progress/save')
        .send(updatedData)
        .expect(200);

      // Load and verify update
      const loadResponse = await request(app)
        .get('/api/progress/load/self-assessment/update-test')
        .expect(200);

      expect(loadResponse.body.data.progress.assessment.questions[0].responseText).toBe('Updated response');
    });
  });

  describe('Progress Data Validation Integration', () => {
    it('should reject progress data with missing required fields', async () => {
      const invalidData = {
        // Missing metadata and assessment
        timestamp: new Date().toISOString()
      };

      const response = await request(app)
        .post('/api/progress/save')
        .send(invalidData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should reject progress data with invalid category structure', async () => {
      const invalidData = createProgressData('invalid-category');
      invalidData.assessment.results.categoryScores = {
        'invalid-category': { // Invalid category
          score: 3,
          level: 'intermediate',
          questionsCount: 1
        }
      };

      const response = await request(app)
        .post('/api/progress/save')
        .send(invalidData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Progress data validation failed');
    });

    it('should reject progress data with invalid task status', async () => {
      const invalidData = createProgressData('invalid-status');
      invalidData.assessment.questions[0].response = 'invalid'; // Should be number

      const response = await request(app)
        .post('/api/progress/save')
        .send(invalidData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Progress data validation failed');
    });
  });

  describe('Progress Data Transformation Integration', () => {
    it('should properly transform and save progress data with assessment suffix', async () => {
      const progressData = createProgressData('transform-test');

      const response = await request(app)
        .post('/api/progress/save')
        .send(progressData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.filename).toContain('transform-test');
      expect(response.body.data.filename).toMatch(/\.json$/);
    });

    it('should handle concurrent progress submissions without data corruption', async () => {
      const promises = Array(5).fill(null).map((_, index) =>
        request(app)
          .post('/api/progress/save')
          .send(createProgressData(`concurrent-task-${index}`))
          .expect(200)
      );

      const responses = await Promise.all(promises);

      responses.forEach((response, index) => {
        expect(response.body.success).toBe(true);
        expect(response.body.data.filename).toContain(`concurrent-task-${index}`);
      });
    });
  });
});
