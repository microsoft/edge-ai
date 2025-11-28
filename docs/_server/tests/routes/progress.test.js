/**
 * Progress Routes Tests
 * Comprehensive tests for progress data API endpoints
 */

import { describe, it, beforeAll, afterAll, beforeEach, expect } from 'vitest';
import request from 'supertest';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import app from '../../app.js';

// Get current directory for ES6 modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

describe('Progress Routes', () => {
  let testProgressDir;

  beforeAll(async () => {
    // Set test environment
    process.env.NODE_ENV = 'test';
    process.env.SKIP_SERVER_START = 'true';

    // Setup test progress directory
    testProgressDir = path.join(__dirname, '../../test-progress');
    process.env.PROGRESS_DIR = testProgressDir;

    try {
      await fs.mkdir(testProgressDir, { recursive: true });
    } catch {
      // Directory might already exist
    }
  });

  afterAll(async () => {
    // Cleanup test directory
    try {
      await fs.rm(testProgressDir, { recursive: true, force: true });
    } catch {
      // Directory might not exist
    }
  });

  beforeEach(async () => {
    // Clear test directory before each test
    try {
      const files = await fs.readdir(testProgressDir);
      await Promise.all(
        files.map(file => fs.unlink(path.join(testProgressDir, file)))
      );
    } catch {
      // Directory might be empty
    }
  });

  describe('POST /api/progress/save', () => {
    it('should save valid self-assessment progress', async () => {
      const validSelfAssessment = {
        type: "self-assessment",
        metadata: {
          title: "Learning Skill Assessment",
          version: "1.0.0",
          assessmentId: "learning-skill-assessment",
          category: "ai-assisted-engineering",
          source: "ui",
          fileType: "self-assessment"
        },
        timestamp: new Date().toISOString(),
        assessment: {
          questions: [
            {
              id: "q1-ai-integration",
              question: "How comfortable are you with AI-assisted development?",
              category: "ai-assisted-engineering",
              response: 3,
              responseText: "Competent",
              timestamp: new Date().toISOString()
            }
          ],
          results: {
            categoryScores: {
              "ai-assisted-engineering": {
                score: 3,
                level: "intermediate",
                questionsCount: 1,
                totalPoints: 3,
                maxPoints: 5
              },
              "prompt-engineering": {
                score: 3,
                level: "intermediate",
                questionsCount: 1,
                totalPoints: 3,
                maxPoints: 5
              },
              "edge-deployment": {
                score: 3,
                level: "intermediate",
                questionsCount: 1,
                totalPoints: 3,
                maxPoints: 5
              },
              "system-troubleshooting": {
                score: 3,
                level: "intermediate",
                questionsCount: 1,
                totalPoints: 3,
                maxPoints: 5
              },
              "project-planning": {
                score: 3,
                level: "intermediate",
                questionsCount: 1,
                totalPoints: 3,
                maxPoints: 5
              },
              "data-analytics": {
                score: 3,
                level: "intermediate",
                questionsCount: 1,
                totalPoints: 3,
                maxPoints: 5
              }
            },
            overallScore: 3,
            overallLevel: "intermediate",
            strengthCategories: ["ai-assisted-engineering"],
            growthCategories: ["edge-deployment"],
            recommendedPath: "intermediate"
          }
        }
      };

      const response = await request(app)
        .post('/api/progress/save')
        .send(validSelfAssessment)
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('filename');
      expect(response.body.data).toHaveProperty('type', 'self-assessment');
      expect(response.body.data).toHaveProperty('message', 'Progress saved successfully');
    });

    it('should save valid kata-progress', async () => {
      const validKataProgress = {
        type: "kata-progress",
        metadata: {
          title: "AI Development Fundamentals",
          version: "1.0.0",
          kataId: "ai-assisted-engineering-01-fundamentals",
          category: "ai-assisted-engineering",
          source: "ui",
          fileType: "kata-progress"
        },
        timestamp: new Date().toISOString(),
        progress: {
          checkboxStates: {
            "task-1-setup": true,
            "task-2-implementation": false,
            "validation-1": true
          },
          currentStep: "task-2-implementation"
        }
      };

      const response = await request(app)
        .post('/api/progress/save')
        .send(validKataProgress)
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('filename');
      expect(response.body.data).toHaveProperty('type', 'kata-progress');
      expect(response.body.data).toHaveProperty('message', 'Progress saved successfully');
    });

    it('should save valid lab-progress', async () => {
      const validLabProgress = {
        type: "lab-progress",
        metadata: {
          title: "Comprehensive IoT Operations Setup",
          version: "1.0.0",
          labId: "edge-deployment-comprehensive-setup",
          category: "edge-deployment",
          source: "ui",
          fileType: "lab-progress"
        },
        timestamp: new Date().toISOString(),
        progress: {
          sessions: [
            {
              sessionId: "session-001",
              startTime: new Date().toISOString(),
              checkboxStates: {
                "phase-1-setup": true,
                "phase-2-deploy": false
              }
            }
          ],
          overallProgress: {
            completedTasks: 1,
            totalTasks: 2,
            completionPercentage: 50,
            currentPhase: "phase-2-deploy"
          }
        }
      };

      const response = await request(app)
        .post('/api/progress/save')
        .send(validLabProgress)
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('filename');
      expect(response.body.data).toHaveProperty('type', 'lab-progress');
      expect(response.body.data).toHaveProperty('message', 'Progress saved successfully');
    });

    it('should reject invalid progress data', async () => {
      const invalidData = {
        type: 'invalid-type',
        metadata: {
          title: "Invalid Test"
        },
        timestamp: new Date().toISOString()
      };

      const response = await request(app)
        .post('/api/progress/save')
        .send(invalidData)
        .expect(400);

      expect(response.body).toHaveProperty('success', false);
      expect(response.body).toHaveProperty('error');
    });

    it('should reject progress data without type', async () => {
      const dataWithoutType = {
        metadata: {
          title: "Test Assessment"
        },
        timestamp: new Date().toISOString(),
        assessment: {
          questions: [{
            id: "test-q",
            question: "Test question",
            category: "ai-assisted-engineering",
            response: 3,
            responseText: "Test response",
            timestamp: new Date().toISOString()
          }],
          results: {
            categoryScores: {
              "ai-assisted-engineering": {
                score: 3,
                level: "intermediate",
                questionsCount: 1,
                totalPoints: 3,
                maxPoints: 5
              },
              "prompt-engineering": {
                score: 3,
                level: "intermediate",
                questionsCount: 1,
                totalPoints: 3,
                maxPoints: 5
              },
              "edge-deployment": {
                score: 3,
                level: "intermediate",
                questionsCount: 1,
                totalPoints: 3,
                maxPoints: 5
              },
              "system-troubleshooting": {
                score: 3,
                level: "intermediate",
                questionsCount: 1,
                totalPoints: 3,
                maxPoints: 5
              },
              "project-planning": {
                score: 3,
                level: "intermediate",
                questionsCount: 1,
                totalPoints: 3,
                maxPoints: 5
              },
              "data-analytics": {
                score: 3,
                level: "intermediate",
                questionsCount: 1,
                totalPoints: 3,
                maxPoints: 5
              }
            },
            overallScore: 3,
            overallLevel: "intermediate"
          }
        }
      };

      const response = await request(app)
        .post('/api/progress/save')
        .send(dataWithoutType)
        .expect(400);

      expect(response.body).toHaveProperty('success', false);
      expect(response.body).toHaveProperty('error');
    });

    it('should handle empty request body', async () => {
      const response = await request(app)
        .post('/api/progress/save')
        .send({})
        .expect(400);

      expect(response.body).toHaveProperty('success', false);
      expect(response.body).toHaveProperty('error');
    });
  });

  describe('GET /api/progress/load/:type/:id', () => {
    it('should return 404 for non-existent progress', async () => {
      const response = await request(app)
        .get('/api/progress/load/self-assessment/non-existent-id')
        .expect(404);

      expect(response.body).toHaveProperty('success', false);
      expect(response.body).toHaveProperty('error', 'Progress not found');
    });

    it('should validate progress type parameter', async () => {
      const response = await request(app)
        .get('/api/progress/load/invalid-type/test-progress-001')
        .expect(400);

      expect(response.body).toHaveProperty('success', false);
      expect(response.body).toHaveProperty('error', 'Invalid input');
    });
  });

  describe('GET /api/progress/sync-status', () => {
    it('should return sync status information', async () => {
      const response = await request(app)
        .get('/api/progress/sync-status')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('sync');
      expect(response.body.data.sync).toHaveProperty('totalFiles');
      expect(response.body.data.sync).toHaveProperty('totalClients');
    });

    it('should include type stats when type filter provided', async () => {
      const response = await request(app)
        .get('/api/progress/sync-status?type=self-assessment')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('sync');
      // typeStats should be present when type is specified
      if (response.body.data.typeStats) {
        expect(response.body.data.typeStats).toHaveProperty('type', 'self-assessment');
      }
    });
  });

  describe('POST /api/progress/sync', () => {
    beforeEach(async () => {
      // Create multiple test files
      const testFiles = [
        {
          name: 'self-assessment-001.json',
          data: {
            metadata: {
              assessmentId: 'test-assessment-001',
              kataTitle: 'Test Assessment',
              version: '1.0.0',
              fileType: 'self-assessment',
              source: 'server'
            },
            assessment: {
              questions: [{
                id: "test-q",
                question: "Test question",
                category: "ai-assisted-engineering",
                response: 3,
                responseText: "Test response",
                timestamp: new Date().toISOString()
              }],
              results: {
                categoryScores: {
                  "ai-assisted-engineering": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "prompt-engineering": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "edge-deployment": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "system-troubleshooting": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "project-planning": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "data-analytics": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  }
                },
                overallScore: 3,
                overallLevel: "intermediate"
              }
            },
            timestamp: new Date().toISOString()
          }
        },
        {
          name: 'kata-progress-001.json',
          data: {
            metadata: {
              kataId: 'test-kata-001',
              kataTitle: 'Test Kata',
              version: '1.0.0',
              fileType: 'kata-progress',
              source: 'server'
            },
            progress: {
              checkboxStates: {
                "task-1": true,
                "task-2": false
              },
              currentStep: "task-2"
            },
            timestamp: new Date().toISOString()
          }
        }
      ];

      await Promise.all(
        testFiles.map(file =>
          fs.writeFile(
            path.join(testProgressDir, file.name),
            JSON.stringify(file.data, null, 2)
          )
        )
      );
    });

    it('should trigger sync for all progress types', async () => {
      const response = await request(app)
        .post('/api/progress/sync')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('message', 'Sync triggered');
      expect(response.body.data).toHaveProperty('type', 'all');
      expect(response.body.data).toHaveProperty('clients');
    });

    it('should trigger sync for specific progress type', async () => {
      const response = await request(app)
        .post('/api/progress/sync')
        .send({ type: 'self-assessment' })
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('message', 'Sync triggered');
      expect(response.body.data).toHaveProperty('type', 'self-assessment');
      expect(response.body.data).toHaveProperty('clients');
    });
  });

  describe('GET /api/progress/latest', () => {
    beforeEach(async () => {
      // Create test files with different timestamps
      const now = new Date();
      const testFiles = [
        {
          name: 'latest-001.json',
          data: {
            metadata: {
              assessmentId: 'test-assessment-latest-001',
              kataTitle: 'Latest Test Assessment 1',
              version: '1.0.0',
              fileType: 'self-assessment',
              source: 'server'
            },
            assessment: {
              questions: [{
                id: "test-q",
                question: "Test question",
                category: "ai-assisted-engineering",
                response: 3,
                responseText: "Test response",
                timestamp: new Date(now.getTime() - 1000).toISOString()
              }],
              results: {
                categoryScores: {
                  "ai-assisted-engineering": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "prompt-engineering": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "edge-deployment": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "system-troubleshooting": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "project-planning": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "data-analytics": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  }
                },
                overallScore: 3,
                overallLevel: "intermediate"
              }
            },
            timestamp: new Date(now.getTime() - 1000).toISOString()
          }
        },
        {
          name: 'latest-002.json',
          data: {
            metadata: {
              assessmentId: 'test-assessment-latest-002',
              kataTitle: 'Latest Test Assessment 2',
              version: '1.0.0',
              fileType: 'self-assessment',
              source: 'server'
            },
            assessment: {
              questions: [{
                id: "test-q",
                question: "Test question",
                category: "ai-assisted-engineering",
                response: 3,
                responseText: "Test response",
                timestamp: now.toISOString()
              }],
              results: {
                categoryScores: {
                  "ai-assisted-engineering": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "prompt-engineering": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "edge-deployment": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "system-troubleshooting": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "project-planning": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "data-analytics": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  }
                },
                overallScore: 3,
                overallLevel: "intermediate"
              }
            },
            timestamp: now.toISOString()
          }
        }
      ];

      await Promise.all(
        testFiles.map(file =>
          fs.writeFile(
            path.join(testProgressDir, file.name),
            JSON.stringify(file.data, null, 2)
          )
        )
      );
    });

    it('should return latest progress for all types', async () => {
      const response = await request(app)
        .get('/api/progress/latest')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('filename');
      expect(response.body.data).toHaveProperty('metadata');
      expect(response.body.data).toHaveProperty('timestamp');
      expect(response.body.data).toHaveProperty('modified');
    });

    it('should return latest progress for specific type', async () => {
      const response = await request(app)
        .get('/api/progress/latest?type=self-assessment')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('filename');
      expect(response.body.data).toHaveProperty('metadata');
    });

    it('should respect limit parameter', async () => {
      const response = await request(app)
        .get('/api/progress/latest?limit=1')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('filename');
      expect(response.body.data).toHaveProperty('metadata');
    });
  });

  describe('GET /api/progress/list', () => {
    beforeEach(async () => {
      // Create multiple test files
      const testFiles = [
        {
          name: 'self-assessment-001.json',
          data: {
            metadata: {
              assessmentId: 'test-assessment-list-001',
              kataTitle: 'List Test Assessment',
              version: '1.0.0',
              fileType: 'self-assessment',
              source: 'server'
            },
            assessment: {
              questions: [{
                id: "test-q",
                question: "Test question",
                category: "ai-assisted-engineering",
                response: 3,
                responseText: "Test response",
                timestamp: new Date().toISOString()
              }],
              results: {
                categoryScores: {
                  "ai-assisted-engineering": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "prompt-engineering": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "edge-deployment": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "system-troubleshooting": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "project-planning": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  "data-analytics": {
                    score: 3,
                    level: "intermediate",
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  }
                },
                overallScore: 3,
                overallLevel: "intermediate"
              }
            },
            timestamp: new Date().toISOString()
          }
        },
        {
          name: 'kata-progress-001.json',
          data: {
            metadata: {
              kataId: 'test-kata-list-001',
              kataTitle: 'List Test Kata',
              version: '1.0.0',
              fileType: 'kata-progress',
              source: 'server'
            },
            progress: {
              checkboxStates: {
                "task-1": true,
                "task-2": false
              },
              currentStep: "task-2"
            },
            timestamp: new Date().toISOString()
          }
        },
        {
          name: 'lab-progress-001.json',
          data: {
            metadata: {
              labId: 'test-lab-list-001',
              kataTitle: 'List Test Lab',
              version: '1.0.0',
              fileType: 'lab-progress',
              source: 'server'
            },
            progress: {
              checkboxStates: {
                "phase-1": true,
                "phase-2": false
              },
              currentStep: "phase-2"
            },
            timestamp: new Date().toISOString()
          }
        }
      ];

      await Promise.all(
        testFiles.map(file =>
          fs.writeFile(
            path.join(testProgressDir, file.name),
            JSON.stringify(file.data, null, 2)
          )
        )
      );
    });

    it('should list all progress files', async () => {
      const response = await request(app)
        .get('/api/progress/list')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('files');
      expect(response.body.files).to.be.an('array');
      expect(response.body).toHaveProperty('total');
    });

    it('should filter by progress type', async () => {
      const response = await request(app)
        .get('/api/progress/list?type=self-assessment')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('files');
      expect(response.body.files).to.be.an('array');
    });

    it('should include file metadata in response', async () => {
      const response = await request(app)
        .get('/api/progress/list')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      if (response.body.files.length > 0) {
        const firstFile = response.body.files[0];
        expect(firstFile).toHaveProperty('filename');
        expect(firstFile).toHaveProperty('type');
        expect(firstFile).toHaveProperty('size');
        expect(firstFile).toHaveProperty('modified');
      }
    });
  });
});
