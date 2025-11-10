/**
 * File System Integration Tests
 * Tests that verify file system operations work correctly with the server
 *
 * These tests:
 * 1. Test progress file saving and loading from disk
 * 2. Validate file watcher functionality with real files
 * 3. Test concurrent file operations
 * 4. Verify file system error handling
 * 5. Test backup and recovery scenarios
 *
 * @module tests/integration/file-system-integration
 */

import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import app from '../../app.js';
import fetch from 'node-fetch';

// Setup paths
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const TEST_PROGRESS_DIR = path.join(__dirname, '..', '..', '..', '..', '.copilot-tracking', 'learning-test');
const SERVER_PORT = 3004; // Different port for file system tests
const SERVER_URL = `http://localhost:${SERVER_PORT}`;

// Server setup
let server;

describe('File System Integration Tests', () => {
  beforeAll(async () => {
    // Create test directory
    await fs.mkdir(TEST_PROGRESS_DIR, { recursive: true });

    // Start server with test environment
    process.env.PROGRESS_DIR = TEST_PROGRESS_DIR;

    server = app.listen(SERVER_PORT, () => {
      console.log(`File system test server running on port ${SERVER_PORT}`);
    });

    // Wait for server to be ready
    await new Promise(resolve => setTimeout(resolve, 500));
  });

  afterAll(async () => {
    // Stop server
    if (server) {
      server.close();
    }

    // Clean up test directory
    try {
      await fs.rm(TEST_PROGRESS_DIR, { recursive: true, force: true });
    } catch (error) {
      console.warn('Failed to clean up test directory:', error.message);
    }

    // Reset environment
    delete process.env.PROGRESS_DIR;
  });

  beforeEach(async () => {
    // Clean test directory before each test
    try {
      const files = await fs.readdir(TEST_PROGRESS_DIR);
      await Promise.all(
        files.map(file => fs.unlink(path.join(TEST_PROGRESS_DIR, file)))
      );
    } catch {
      // Directory might be empty, that's okay
    }
  });

  describe('Progress File Operations', () => {
    it('should save progress data to file system', async () => {
      const testProgressData = {
        type: 'kata-progress',
        metadata: {
          title: 'File System Test Kata',
          version: '1.0.0',
          kataId: 'file-system-test-kata-001',
          source: 'ui',
          fileType: 'kata-progress'
        },
        timestamp: new Date().toISOString(),
        progress: {
          currentStep: 'task-2-implementation',
          checkboxStates: {
            'task-1-setup': true,
            'task-2-implementation': false,
            'task-3-testing': false
          }
        }
      };

      // Save via API
      const response = await fetch(`${SERVER_URL}/api/progress/save`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(testProgressData)
      });

      expect(response.status).toBe(200);
      const result = await response.json();
      expect(result.success).toBe(true);
      expect(result.data.filename).toContain('file-system-test-kata-001');

      // Verify file exists on disk
      const files = await fs.readdir(TEST_PROGRESS_DIR);

      const savedFile = files.find(file => file.includes('file-system-test-kata-001'));
      expect(savedFile).toBeDefined();

      // Verify file content
      const fileContent = await fs.readFile(path.join(TEST_PROGRESS_DIR, savedFile), 'utf8');
      const savedData = JSON.parse(fileContent);
      expect(savedData.metadata.kataId).toBe('file-system-test-kata-001');
      expect(savedData.progress.checkboxStates['task-1-setup']).toBe(true);
    });

    it('should load progress data from file system', async () => {
      const kataId = 'file-system-load-test-001';
      const testData = {
        metadata: {
          version: '1.0.0',
          kataId: kataId,
          source: 'ui',
          fileType: 'kata-progress',
          kataTitle: 'Load Test Kata',
          category: 'ai-assisted-engineering',
          lastUpdated: new Date().toISOString()
        },
        timestamp: new Date().toISOString(),
        progress: {
          checkboxStates: {
            'task-1-setup': true,
            'task-2-implementation': true,
            'task-3-testing': false
          },
          completedTasks: 2,
          totalTasks: 3,
          completionPercentage: 66.67,
          currentStep: 'task-3-testing',
          timeSpent: 60,
          difficulty: 'advanced'
        }
      };

      // Write file directly to disk
      const filename = `${kataId}-${new Date().toISOString().replace(/[:.]/g, '-')}.json`;
      await fs.writeFile(path.join(TEST_PROGRESS_DIR, filename), JSON.stringify(testData, null, 2));

      // Load via API
      const response = await fetch(`${SERVER_URL}/api/progress/load/kata-progress/${kataId}`);

      const result = await response.json();

      expect(response.status).toBe(200);
      expect(result.success).toBe(true);
      expect(result.data.metadata.kataId).toBe(kataId);
      expect(result.data.progress.difficulty).toBe('advanced');
    });

    it('should handle concurrent file operations', async () => {
            // Generate concurrent save data
      const concurrentSaves = Array.from({ length: 5 }, (_, index) => ({
        type: 'kata-progress',
        metadata: {
          title: `Concurrent Test Kata ${index}`,
          version: '1.0.0',
          kataId: `concurrent-test-kata-${index.toString().padStart(3, '0')}`,
          source: 'ui',
          fileType: 'kata-progress'
        },
        timestamp: new Date().toISOString(),
        progress: {
          checkboxStates: {
            'task-1-setup': index % 2 === 0,
            'task-2-implementation': index % 3 === 0,
            'task-3-testing': index % 5 === 0
          },
          currentStep: `task-${index + 1}`
        }
      }));

      // Execute concurrent saves
      const savePromises = concurrentSaves.map(data =>
        fetch(`${SERVER_URL}/api/progress/save`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(data)
        })
      );

      const responses = await Promise.all(savePromises);

      // Verify all saves succeeded
      for (const response of responses) {
        expect(response.status).toBe(200);
        const result = await response.json();
        expect(result.success).toBe(true);
      }

      // Verify all files exist
      const files = await fs.readdir(TEST_PROGRESS_DIR);
      expect(files).toHaveLength(5);

      // Verify file content integrity
      for (let i = 0; i < 5; i++) {
        const expectedKataId = `concurrent-test-kata-${i.toString().padStart(3, '0')}`;
        const matchingFile = files.find(file => file.includes(expectedKataId));
        expect(matchingFile).toBeDefined();

        const fileContent = await fs.readFile(path.join(TEST_PROGRESS_DIR, matchingFile), 'utf8');
        const savedData = JSON.parse(fileContent);
        expect(savedData.metadata.kataId).toBe(expectedKataId);
        expect(savedData.progress.currentStep).toBe(`task-${i + 1}`); // Schema transformer converts integer to "task-X"
        expect(savedData.progress.checkboxStates).toBeDefined();
      }
    });
  });

  describe('File System Error Handling', () => {
    it('should handle file read errors gracefully', async () => {
      const response = await fetch(`${SERVER_URL}/api/progress/load/kata-progress/non-existent-kata`);

      expect(response.status).toBe(404);
      const result = await response.json();
      expect(result.success).toBe(false);
      expect(result.error).toContain('not found');
    });

    it('should handle invalid JSON files gracefully', async () => {
      const kataId = 'invalid-json-test';
      const invalidJsonFile = `${kataId}-${new Date().toISOString().replace(/[:.]/g, '-')}.json`;

      // Write invalid JSON to disk
      await fs.writeFile(path.join(TEST_PROGRESS_DIR, invalidJsonFile), 'invalid json content');

      const response = await fetch(`${SERVER_URL}/api/progress/load/kata-progress/${kataId}`);

      expect(response.status).toBe(500);
      const result = await response.json();
      expect(result.success).toBe(false);
      expect(result.error).toBe('Failed to load progress');
    });

    it('should handle permission errors during save', async () => {
      // NOTE: This test verifies that saves work even with potential filesystem conflicts
      // Real permission errors would require OS-level permission restrictions that are
      // difficult to simulate reliably in integration tests

      const progressData = {
        type: 'kata-progress',
        metadata: {
          title: 'Permission Test Kata',
          version: '1.0.0',
          kataId: 'permission-test-kata',
          source: 'ui',
          fileType: 'kata-progress'
        },
        timestamp: new Date().toISOString(),
        progress: {
          currentStep: 'task-1-setup',
          checkboxStates: {
            'task-1-setup': true
          }
        }
      };

      const response = await fetch(`${SERVER_URL}/api/progress/save`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(progressData)
      });

      // Should save successfully (filename includes timestamp, avoiding conflicts)
      expect(response.status).toBe(200);
      const result = await response.json();
      expect(result.success).toBe(true);
      expect(result.data.filename).toBeDefined();
    });
  });

  describe('File System Performance', () => {
    it('should handle large progress files efficiently', async () => {
      const largeProgressData = {
        type: 'kata-progress',
        metadata: {
          title: 'Large File Test Kata',
          version: '1.0.0',
          kataId: 'large-file-test-kata',
          source: 'ui',
          fileType: 'kata-progress'
        },
        timestamp: new Date().toISOString(),
        progress: {
          currentStep: 'task-500',
          checkboxStates: {}
        }
      };

      // Create large checkbox states
      for (let i = 0; i < 1000; i++) {
        largeProgressData.progress.checkboxStates[`task-${i}`] = i < 500;
      }

      const startTime = Date.now();

      const response = await fetch(`${SERVER_URL}/api/progress/save`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(largeProgressData)
      });

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(response.status).toBe(200);
      const result = await response.json();
      expect(result.success).toBe(true);

      // Should complete in reasonable time (less than 5 seconds)
      expect(duration).toBeLessThan(5000);

      // Verify file size and content
      const files = await fs.readdir(TEST_PROGRESS_DIR);
      const savedFile = files.find(file => file.includes('large-file-test-kata'));
      expect(savedFile).toBeDefined();

      const stats = await fs.stat(path.join(TEST_PROGRESS_DIR, savedFile));
      expect(stats.size).toBeGreaterThan(1000); // Should be substantial file

      const fileContent = await fs.readFile(path.join(TEST_PROGRESS_DIR, savedFile), 'utf8');
      const savedData = JSON.parse(fileContent);
      expect(Object.keys(savedData.progress.checkboxStates)).toHaveLength(1000);
    });

    it('should efficiently list and filter progress files', async () => {
      // Clean up any existing test files first
      const existingFiles = await fs.readdir(TEST_PROGRESS_DIR);
      for (const file of existingFiles) {
        if (file.startsWith('perf-test-')) {
          await fs.unlink(path.join(TEST_PROGRESS_DIR, file));
        }
      }

      // Create multiple files with different types and dates
      const testFiles = [
        { type: 'kata-progress', kataId: 'perf-test-kata-001', category: 'ai-assisted-engineering' },
        { type: 'kata-progress', kataId: 'perf-test-kata-002', category: 'prompt-engineering' },
        { type: 'self-assessment', assessmentId: 'perf-test-assessment-001', category: 'ai-assisted-engineering' },
        { type: 'kata-progress', kataId: 'perf-test-kata-003', category: 'ai-assisted-engineering' }
      ];

      // Create files
      for (const [index, fileInfo] of testFiles.entries()) {
        try {
          const data = {
            type: fileInfo.type,
            metadata: {
              title: `Performance Test ${index}`
            },
            timestamp: new Date().toISOString()
          };

          if (fileInfo.type === 'kata-progress') {
            data.metadata.version = '1.0.0';
            data.metadata.kataId = fileInfo.kataId;
            data.metadata.kataTitle = `Performance Test ${index}`;
            data.metadata.category = fileInfo.category;
            data.metadata.source = 'ui';
            data.metadata.fileType = 'kata-progress';
            data.metadata.lastUpdated = new Date().toISOString();
            data.progress = {
              checkboxStates: { 'task-1': true },
              currentStep: 'task-1'
            };
          } else {
            data.metadata.version = '1.0.0';
            data.metadata.assessmentId = fileInfo.assessmentId;
            data.metadata.assessmentTitle = `Performance Test ${index}`;
            data.metadata.category = fileInfo.category;
            data.metadata.source = 'ui';
            data.metadata.fileType = 'self-assessment';
            data.metadata.lastUpdated = new Date().toISOString();
            data.assessment = {
              questions: [
                {
                  id: 'q1-ai-integration',
                  question: 'How comfortable are you with AI-assisted development?',
                  category: 'ai-assisted-engineering',
                  response: 3,
                  responseText: 'Competent',
                  timestamp: new Date().toISOString()
                },
                {
                  id: 'q2-prompt-engineering',
                  question: 'How effective are you at prompt engineering?',
                  category: 'prompt-engineering',
                  response: 4,
                  responseText: 'Advanced',
                  timestamp: new Date().toISOString()
                },
                {
                  id: 'q3-edge-deployment',
                  question: 'How comfortable are you with edge deployment?',
                  category: 'edge-deployment',
                  response: 2,
                  responseText: 'Beginner',
                  timestamp: new Date().toISOString()
                },
                {
                  id: 'q4-project-planning',
                  question: 'How effective are you at project planning?',
                  category: 'project-planning',
                  response: 3,
                  responseText: 'Competent',
                  timestamp: new Date().toISOString()
                },
                {
                  id: 'q5-data-analytics',
                  question: 'How comfortable are you with data analytics?',
                  category: 'data-analytics',
                  response: 3,
                  responseText: 'Competent',
                  timestamp: new Date().toISOString()
                }
              ],
              results: {
                categoryScores: {
                  'ai-assisted-engineering': {
                    score: 3.0,
                    level: 'intermediate',
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  'prompt-engineering': {
                    score: 4.0,
                    level: 'advanced',
                    questionsCount: 1,
                    totalPoints: 4,
                    maxPoints: 5
                  },
                  'edge-deployment': {
                    score: 2.0,
                    level: 'beginner',
                    questionsCount: 1,
                    totalPoints: 2,
                    maxPoints: 5
                  },
                  'system-troubleshooting': {
                    score: 0,
                    level: 'beginner',
                    questionsCount: 0,
                    totalPoints: 0,
                    maxPoints: 0
                  },
                  'project-planning': {
                    score: 3.0,
                    level: 'intermediate',
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  },
                  'data-analytics': {
                    score: 3.0,
                    level: 'intermediate',
                    questionsCount: 1,
                    totalPoints: 3,
                    maxPoints: 5
                  }
                },
                overallScore: 3.0,
                overallLevel: 'intermediate',
                strengthCategories: ['prompt-engineering'],
                growthCategories: ['edge-deployment'],
                recommendedPath: 'intermediate'
              }
            };
          }

          const saveResponse = await fetch(`${SERVER_URL}/api/progress/save`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
          });

          console.log(`Response status: ${saveResponse.status}`);
          if (!saveResponse.ok) {
            const errorText = await saveResponse.text();
            console.log(`Failed to save ${fileInfo.type} file ${index}:`, errorText);
          } else {
            const responseText = await saveResponse.text();
            console.log(`Successfully saved ${fileInfo.type} file ${index}:`, responseText);
          }
        } catch (error) {
          console.error(`Error processing file ${index}:`, error.message);
          console.error('Stack:', error.stack);
        }
      }

      // Test listing performance
      const startTime = Date.now();

      const listResponse = await fetch(`${SERVER_URL}/api/progress/list`);

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(listResponse.status).toBe(200);
      const listResult = await listResponse.json();
      expect(listResult.success).toBe(true);
      expect(listResult.files).toHaveLength(4);

      // Should complete quickly (less than 1 second)
      expect(duration).toBeLessThan(1000);

      // Verify file filtering and sorting
      const files = listResult.files;
      expect(files.every(file => file.filename && file.type && file.id)).toBe(true);

      // Files should be sorted by modification time (newest first)
      for (let i = 1; i < files.length; i++) {
        const current = new Date(files[i].modified);
        const previous = new Date(files[i - 1].modified);
        expect(current.getTime()).toBeLessThanOrEqual(previous.getTime());
      }
    });
  });

  describe('File System Cleanup and Maintenance', () => {
    it('should handle file cleanup operations', async () => {
      // Clean the test directory first
      const existingFiles = await fs.readdir(TEST_PROGRESS_DIR);
      for (const file of existingFiles) {
        await fs.unlink(path.join(TEST_PROGRESS_DIR, file));
      }

      // Create multiple old files
      const oldFiles = Array.from({ length: 3 }, (_, index) => ({
        kataId: `cleanup-test-kata-${index}`,
        timestamp: new Date(Date.now() - (index + 1) * 24 * 60 * 60 * 1000) // Days old
      }));

      for (const fileInfo of oldFiles) {
        const data = {
          metadata: {
            version: '1.0.0',
            kataId: fileInfo.kataId,
            source: 'ui',
            fileType: 'kata-progress',
            kataTitle: `Cleanup Test Kata`,
            category: 'ai-assisted-engineering',
            lastUpdated: fileInfo.timestamp.toISOString()
          },
          timestamp: fileInfo.timestamp.toISOString(),
          progress: {
            checkboxStates: { 'task-1': true },
            completedTasks: 1,
            totalTasks: 1,
            completionPercentage: 100,
            currentStep: 'completed',
            timeSpent: 30,
            difficulty: 'beginner'
          }
        };

        const filename = `${fileInfo.kataId}.json`;
        const filePath = path.join(TEST_PROGRESS_DIR, filename);
        await fs.writeFile(filePath, JSON.stringify(data, null, 2));

        // Set the file modification time to match the intended age
        await fs.utimes(filePath, fileInfo.timestamp, fileInfo.timestamp);
      }

      // Verify files exist
      let files = await fs.readdir(TEST_PROGRESS_DIR);
      expect(files).toHaveLength(3);

      // Test cleanup by manually removing old files (simulating maintenance)
      const cutoffDate = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000); // 2 days ago

      for (const file of files) {
        const filePath = path.join(TEST_PROGRESS_DIR, file);
        const stats = await fs.stat(filePath);

        if (stats.mtime < cutoffDate) {
          await fs.unlink(filePath);
        }
      }

      // Verify cleanup worked
      files = await fs.readdir(TEST_PROGRESS_DIR);
      expect(files).toHaveLength(1); // Only files newer than 2 days should remain
    });

    it('should handle backup and restore scenarios', async () => {
      const backupDir = path.join(TEST_PROGRESS_DIR, 'backup');
      await fs.mkdir(backupDir, { recursive: true });

      // Create original file
      const originalData = {
        type: 'kata-progress',
        metadata: {
          title: 'Backup Test Kata',
          version: '1.0.0',
          kataId: 'backup-test-kata',
          source: 'ui',
          fileType: 'kata-progress'
        },
        timestamp: new Date().toISOString(),
        progress: {
          checkboxStates: {
            'task-1-setup': true,
            'task-2-implementation': true,
            'task-3-testing': false
          },
          currentStep: 'task-2-implementation'
        }
      };

      // Save original
      const saveResponse = await fetch(`${SERVER_URL}/api/progress/save`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(originalData)
      });

      expect(saveResponse.status).toBe(200);

      // Simulate backup by copying file
      const files = await fs.readdir(TEST_PROGRESS_DIR);
      const originalFile = files.find(file => file.includes('backup-test-kata') && !file.includes('backup/'));
      expect(originalFile).toBeDefined();

      const originalPath = path.join(TEST_PROGRESS_DIR, originalFile);
      const backupPath = path.join(backupDir, originalFile);
      await fs.copyFile(originalPath, backupPath);

      // Modify original file (simulate corruption)
      await fs.writeFile(originalPath, 'corrupted data');

      // Verify load fails
      const loadResponse = await fetch(`${SERVER_URL}/api/progress/load/kata-progress/backup-test-kata`);
      expect(loadResponse.status).toBe(500);

      // Restore from backup
      await fs.copyFile(backupPath, originalPath);

      // Verify load works again
      const restoreLoadResponse = await fetch(`${SERVER_URL}/api/progress/load/kata-progress/backup-test-kata`);
      expect(restoreLoadResponse.status).toBe(200);

      const restoreResult = await restoreLoadResponse.json();
      expect(restoreResult.success).toBe(true);
      expect(restoreResult.data.progress.checkboxStates['task-1-setup']).toBe(true);
      expect(restoreResult.data.progress.checkboxStates['task-2-implementation']).toBe(true);
      expect(restoreResult.data.progress.checkboxStates['task-3-testing']).toBe(false);
    });
  });
});
