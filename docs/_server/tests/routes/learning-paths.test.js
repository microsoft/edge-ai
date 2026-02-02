/**
 * Learning Paths API Tests
 * Tests for learning path saving, validation, and retrieval endpoints
 */

import request from 'supertest';
import { vi } from 'vitest';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Mock the app before importing
const mockApp = {
  use: vi.fn(),
  get: vi.fn(),
  post: vi.fn(),
  patch: vi.fn(),
  listen: vi.fn()
};

// Create a test server setup
let app;
let learningPathsRouter;

beforeAll(async () => {
  // Set PROGRESS_DIR to the correct learning directory for these tests
  // This prevents pollution from other test files (progress.test.js, cors-integration.test.js)
  const testDir = path.join(__dirname, '..', '..', '..', '..', '.copilot-tracking', 'learning');
  process.env.PROGRESS_DIR = testDir;

  // Import the learning paths router
  const { default: router } = await import('../../routes/learning-paths.js');
  learningPathsRouter = router;

  // Create a minimal express app for testing
  const express = await import('express');
  app = express.default();
  app.use(express.default.json());
  app.use('/api/learning', learningPathsRouter);

  // Clean up any leftover test files from previous runs
  try {
    const files = await fs.readdir(testDir);
    const testFiles = files.filter(file =>
      file.includes('test-user') ||
      file.includes('test-file-creation') ||
      file.includes('test-timestamp') ||
      file.includes('test-no-recommendations') ||
      file.includes('test-invalid') ||
      file.includes('default-user')
    );
    for (const file of testFiles) {
      await fs.unlink(path.join(testDir, file));
    }
  } catch (error) {
    // Directory might not exist, that's fine
  }
});

afterEach(async () => {
  // Clean up test files after each test
  const testDir = path.join(__dirname, '..', '..', '..', '..', '.copilot-tracking', 'learning');
  try {
    const files = await fs.readdir(testDir);
    // Remove all test files (anything with 'test-' prefix)
    const testFiles = files.filter(file =>
      file.includes('test-user') ||
      file.includes('test-file-creation') ||
      file.includes('test-timestamp') ||
      file.includes('test-no-recommendations') ||
      file.includes('test-invalid') ||
      file.includes('default-user')
    );
    for (const file of testFiles) {
      await fs.unlink(path.join(testDir, file));
    }
  } catch (error) {
    // Directory might not exist, that's fine
  }
});

afterAll(async () => {
  // Final cleanup of all test files from production directory
  const testDir = path.join(__dirname, '..', '..', '..', '..', '.copilot-tracking', 'learning');
  try {
    const files = await fs.readdir(testDir);
    const testFiles = files.filter(file =>
      file.includes('test-user') ||
      file.includes('test-file-creation') ||
      file.includes('test-timestamp') ||
      file.includes('test-no-recommendations') ||
      file.includes('test-invalid') ||
      file.includes('default-user')
    );
    for (const file of testFiles) {
      await fs.unlink(path.join(testDir, file));
    }
  } catch (error) {
    // Directory might not exist, that's fine
  }
});

describe('Learning Paths API', () => {
  describe('POST /api/learning/save', () => {
    const validRequest = {
      userId: 'test-user',
      pathType: 'assessment-recommended',
      assessmentResults: {
        skillLevel: 'Skill Developer',
        score: 85,
        totalQuestions: 20,
        responses: [
          { category: 'AI-Assisted Engineering', score: 12, total: 15 },
          { category: 'Prompt Engineering', score: 10, total: 15 },
          { category: 'Edge Deployment', score: 11, total: 15 },
          { category: 'System Troubleshooting', score: 13, total: 15 },
          { category: 'Project Planning', score: 9, total: 15 }
        ]
      },
      recommendations: {
        customagentRecommendation: 'Focus on IoT Edge deployment scenarios and troubleshooting',
        learningPath: 'intermediate-edge-development'
      },
      timestamp: '2025-09-21T16:43:10.000Z'
    };

    test('should save valid learning path', async () => {
      const response = await request(app)
        .post('/api/learning/save')
        .send(validRequest)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('id');
      expect(response.body.data).toHaveProperty('pathType', 'assessment-recommended');
      expect(response.body.data).toHaveProperty('savedAt');
      expect(response.body.data).toHaveProperty('filepath');
    });

    test('should reject request without assessment results', async () => {
      const invalidRequest = { ...validRequest };
      delete invalidRequest.assessmentResults;

      const response = await request(app)
        .post('/api/learning/save')
        .send(invalidRequest)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Invalid request data');
      expect(response.body.validationErrors).toBeDefined();
      expect(Array.isArray(response.body.validationErrors)).toBe(true);
    });

    test('should reject request with invalid skill level', async () => {
      const invalidRequest = {
        ...validRequest,
        assessmentResults: {
          ...validRequest.assessmentResults,
          skillLevel: 'Invalid Level'
        }
      };

      const response = await request(app)
        .post('/api/learning/save')
        .send(invalidRequest)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Invalid request data');
      expect(response.body.validationErrors).toBeDefined();
    });

    test('should reject request with invalid score range', async () => {
      const invalidRequest = {
        ...validRequest,
        assessmentResults: {
          ...validRequest.assessmentResults,
          score: 150 // Invalid score > 100
        }
      };

      const response = await request(app)
        .post('/api/learning/save')
        .send(invalidRequest)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.validationErrors).toBeDefined();
    });

    test('should handle missing optional fields with defaults', async () => {
      const minimalRequest = {
        assessmentResults: validRequest.assessmentResults
      };

      const response = await request(app)
        .post('/api/learning/save')
        .send(minimalRequest)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.pathType).toBe('assessment-recommended');
    });

    test.skip('should include metadata in saved learning path', async () => {
      const requestWithMetadata = {
        ...validRequest,
        metadata: {
          assessmentVersion: '1.0.0',
          sourceUrl: 'https://localhost:8080/learning/skill-assessment.html',
          sessionId: 'test-session-123'
        }
      };

      const response = await request(app)
        .post('/api/learning/save')
        .send(requestWithMetadata)
        .expect(200);

      expect(response.body.success).toBe(true);

      // Verify the file was created with metadata
      const testDir = path.join(__dirname, '..', '..', '..', '..', '.copilot-tracking', 'learning');
      const latestFile = path.join(testDir, 'test-user-latest.json');
      const savedData = JSON.parse(await fs.readFile(latestFile, 'utf8'));

      expect(savedData.metadata).toBeDefined();
      expect(savedData.metadata.assessmentVersion).toBe('1.0.0');
      expect(savedData.schemaVersion).toBe('1.0.0');
      expect(savedData.validatedAt).toBeDefined();
    });
  });

  describe('GET /api/learning/:userId', () => {
    beforeEach(async () => {
      // Create test data
      const validRequest = {
        userId: 'test-user-retrieve',
        pathType: 'assessment-recommended',
        assessmentResults: {
          skillLevel: 'Skill Developer',
          score: 85,
          totalQuestions: 20,
          responses: [
            { category: 'AI-Assisted Engineering', score: 12, total: 15 }
          ]
        },
        recommendations: {
          customagentRecommendation: 'Test recommendation',
          learningPath: 'test-path'
        }
      };

      await request(app)
        .post('/api/learning/save')
        .send(validRequest);
    });

    test('should retrieve learning paths for user', async () => {
      const response = await request(app)
        .get('/api/learning/test-user-retrieve')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.userId).toBe('test-user-retrieve');
      expect(response.body.data.learningPaths).toBeDefined();
      expect(Array.isArray(response.body.data.learningPaths)).toBe(true);
      expect(response.body.data.count).toBeGreaterThan(0);
    });

    test('should return empty array for non-existent user', async () => {
      const response = await request(app)
        .get('/api/learning/non-existent-user')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.learningPaths).toEqual([]);
      expect(response.body.data.count).toBe(0);
    });
  });

  describe('GET /api/learning/:userId/latest', () => {
    beforeEach(async () => {
      // Create test data
      const validRequest = {
        userId: 'test-user-latest',
        pathType: 'assessment-recommended',
        assessmentResults: {
          skillLevel: 'Expert Practitioner',
          score: 95,
          totalQuestions: 20,
          responses: [
            { category: 'AI-Assisted Engineering', score: 9, total: 15 },
            { category: 'Prompt Engineering', score: 12, total: 15 },
            { category: 'Edge Deployment', score: 8, total: 15 }
          ]
        }
      };

      await request(app)
        .post('/api/learning/save')
        .send(validRequest);
    });

    test('should retrieve latest learning path for user', async () => {
      const response = await request(app)
        .get('/api/learning/test-user-latest/latest')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeDefined();
      expect(response.body.data.userId).toBe('test-user-latest');
      expect(response.body.data.assessmentResults.skillLevel).toBe('Expert Practitioner');
    });

    test('should return 404 for user with no learning paths', async () => {
      const response = await request(app)
        .get('/api/learning/no-paths-user/latest')
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('No learning paths found');
    });
  });

  describe('PATCH /api/learning/:id/progress', () => {
    let learningPathId;

    beforeEach(async () => {
      // Create test data and get the ID
      const validRequest = {
        userId: 'test-user-progress',
        pathType: 'assessment-recommended',
        assessmentResults: {
          skillLevel: 'Foundation Builder',
          score: 65,
          totalQuestions: 20,
          responses: [
            { category: 'AI-Assisted Engineering', score: 6, total: 15 },
            { category: 'Prompt Engineering', score: 7, total: 15 }
          ]
        }
      };

      const saveResponse = await request(app)
        .post('/api/learning/save')
        .send(validRequest)
        .expect(200);

      // Get the learning path ID from the response
      expect(saveResponse.body.success).toBe(true);
      learningPathId = saveResponse.body.data.id;
    });

    test('should update learning path progress', async () => {
      const progressUpdate = {
        completed: 5,
        total: 10,
        notes: 'Making good progress on IoT Edge fundamentals'
      };

      const response = await request(app)
        .patch(`/api/learning/${learningPathId}/progress`)
        .send(progressUpdate)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.completed).toBe(5);
      expect(response.body.data.total).toBe(10);
      expect(response.body.data.notes).toBe(progressUpdate.notes);
      expect(response.body.data.lastUpdated).toBeDefined();
    });

    test('should return 404 for non-existent learning path', async () => {
      const progressUpdate = {
        completed: 1,
        total: 10
      };

      const response = await request(app)
        .patch('/api/learning/non-existent-id/progress')
        .send(progressUpdate)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('Learning path not found');
    });

    test('should handle partial progress updates', async () => {
      const progressUpdate = {
        completed: 3
        // total and notes omitted
      };

      const response = await request(app)
        .patch(`/api/learning/${learningPathId}/progress`)
        .send(progressUpdate)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.completed).toBe(3);
      expect(response.body.data.total).toBe(0); // Should keep existing value
    });
  });

  describe('Schema Validation', () => {
    test('should validate against learning-path-save-request schema', async () => {
      // Test with completely invalid data structure
      const invalidRequest = {
        invalidField: 'invalid',
        assessmentResults: 'should be object'
      };

      const response = await request(app)
        .post('/api/learning/save')
        .send(invalidRequest)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Invalid request data');
      expect(response.body.validationErrors).toBeDefined();
      expect(Array.isArray(response.body.validationErrors)).toBe(true);
    });

    test('should validate assessment results structure', async () => {
      const invalidRequest = {
        assessmentResults: {
          skillLevel: 'Skill Developer',
          score: 'invalid', // Should be number
          responses: 'invalid' // Should be array
        }
      };

      const response = await request(app)
        .post('/api/learning/save')
        .send(invalidRequest)
        .expect(400);

      expect(response.body.validationErrors).toBeDefined();
      expect(response.body.validationErrors.length).toBeGreaterThan(0);
    });

    test('should validate userId pattern', async () => {
      const invalidRequest = {
        userId: 'invalid user id!', // Contains spaces and special chars
        assessmentResults: {
          skillLevel: 'Skill Developer',
          score: 85,
          responses: [
            { category: 'AI-Assisted Engineering', score: 12, total: 15 }
          ]
        }
      };

      const response = await request(app)
        .post('/api/learning/save')
        .send(invalidRequest)
        .expect(400);

      expect(response.body.validationErrors).toBeDefined();
      const userIdError = response.body.validationErrors.find(
        err => err.field?.includes('userId') || err.message?.includes('pattern')
      );
      expect(userIdError).toBeDefined();
    });
  });

  describe('Error Handling', () => {
    let originalWriteFile;

    afterEach(() => {
      // Always restore the original function
      if (originalWriteFile) {
        fs.writeFile = originalWriteFile;
        originalWriteFile = null;
      }
    });

    test('should handle file system errors gracefully', async () => {
      // Mock fs.writeFile to throw an error
      originalWriteFile = fs.writeFile;
      fs.writeFile = vi.fn().mockRejectedValue(new Error('Disk full'));

      const validRequest = {
        assessmentResults: {
          skillLevel: 'Skill Developer',
          score: 85,
          responses: [
            { category: 'AI-Assisted Engineering', score: 12, total: 15 }
          ]
        }
      };

      const response = await request(app)
        .post('/api/learning/save')
        .send(validRequest)
        .expect(500);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Failed to save learning path');
      expect(response.body.details).toBeDefined();
    });
  });
});

describe('Learning Path File Creation', () => {
  test('should create learning path files in correct directory', async () => {
    const validRequest = {
      userId: 'test-file-creation',
      assessmentResults: {
        skillLevel: 'Skill Developer',
        score: 85,
        responses: [
          { category: 'AI-Assisted Engineering', score: 12, total: 15 }
        ]
      }
    };

    const response = await request(app)
      .post('/api/learning/save')
      .send(validRequest)
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(response.body.data.filepath).toBeDefined();

    // Check that files were created
    const testDir = path.join(__dirname, '..', '..', '..', '..', '.copilot-tracking', 'learning');

    // Try to read the specific file that was created
    const createdFilePath = path.join(testDir, response.body.data.filepath);
    const latestFilePath = path.join(testDir, `${validRequest.userId}-latest.json`);

    // Verify the timestamped file exists
    const createdFileContent = await fs.readFile(createdFilePath, 'utf8');
    expect(createdFileContent).toBeDefined();
    const createdData = JSON.parse(createdFileContent);
    expect(createdData.userId).toBe(validRequest.userId);

    // Verify the latest file exists
    const latestFileContent = await fs.readFile(latestFilePath, 'utf8');
    expect(latestFileContent).toBeDefined();
    const latestData = JSON.parse(latestFileContent);
    expect(latestData.userId).toBe(validRequest.userId);
  });

  test('should create timestamped learning path files', async () => {
    const validRequest = {
      userId: 'test-timestamp',
      assessmentResults: {
        skillLevel: 'Expert Practitioner',
        score: 95,
        responses: [
          { category: 'AI-Assisted Engineering', score: 15, total: 15 }
        ]
      }
    };

    await request(app)
      .post('/api/learning/save')
      .send(validRequest)
      .expect(200);

    // Allow time for file to be written to disk
    await new Promise(resolve => setTimeout(resolve, 500));

    const testDir = path.join(__dirname, '..', '..', '..', '..', '.copilot-tracking', 'learning');
    const files = await fs.readdir(testDir);

    const timestampedFile = files.find(file =>
      file.includes('test-timestamp-assessment-recommended-') &&
      file.endsWith('.json') &&
      file !== 'test-timestamp-latest.json'
    );
    expect(timestampedFile).toBeDefined();
  });

  /**
   * Task 2.1: RED - Create failing tests for selectedItems schema
   * Tests for new catalog item selections API
   */
  describe('POST /api/learning/selections with selectedItems', () => {
    test('should save selectedItems array', async () => {
      const response = await request(app)
        .post('/api/learning/selections')
        .send({
          selectedItems: ['ai-assisted-engineering-01', 'foundation-ai-first-engineering'],
          userId: 'test-user'
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('selectionCount', 2);
      expect(response.body.data.selections).toHaveProperty('selectedItems');
      expect(Array.isArray(response.body.data.selections.selectedItems)).toBe(true);
      expect(response.body.data.selections.selectedItems).toHaveLength(2);
    });

    test('should reject invalid selectedItems format (not an array)', async () => {
      const response = await request(app)
        .post('/api/learning/selections')
        .send({ selectedItems: 'not-an-array', userId: 'test-user' })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBeDefined();
    });

    test('should reject request without selectedItems field', async () => {
      const response = await request(app)
        .post('/api/learning/selections')
        .send({ userId: 'test-user' })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBeDefined();
    });

    test('should accept selectedItems with item IDs from different types', async () => {
      const response = await request(app)
        .post('/api/learning/selections')
        .send({
          selectedItems: [
            'ai-assisted-engineering-01',  // kata
            'foundation-ai-first-engineering',   // path
            'lab-ai-deployment-01'         // lab
          ],
          userId: 'test-user'
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.selections.selectedItems).toHaveLength(3);
    });
  });

  describe('GET /api/learning/selections', () => {
    test('should retrieve selectedItems from saved selections', async () => {
      // First save selections
      await request(app)
        .post('/api/learning/selections')
        .send({
          selectedItems: ['kata-01', 'path-02'],
          userId: 'test-user-get'
        })
        .expect(200);

      // Then retrieve
      const response = await request(app)
        .get('/api/learning/selections')
        .query({ userId: 'test-user-get' })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.selections).toHaveProperty('selectedItems');
      expect(Array.isArray(response.body.data.selections.selectedItems)).toBe(true);
      expect(response.body.data.selections.selectedItems).toEqual(['kata-01', 'path-02']);
    });

    test('should return empty selectedItems for new user', async () => {
      const response = await request(app)
        .get('/api/learning/selections')
        .query({ userId: 'test-user-new' })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.selections.selectedItems).toEqual([]);
      expect(response.body.data.selections.selectionCount).toBe(0);
    });
  });
});
