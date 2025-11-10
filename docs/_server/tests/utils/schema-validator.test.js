/**
 * Schema Validator Utility Tests
 * Tests for schema validation utility functions
 */

import { describe, it, expect } from 'vitest';
import {
  validateAndSanitizeProgress,
  extractMetadataSummary,
  getSupportedSchemaTypes
} from '../../utils/schema-validator.js';

describe('Schema Validator Utilities', () => {
  describe('validateAndSanitizeProgress', () => {
    it('should validate and sanitize correct self-assessment data', async () => {
      const validData = {
        metadata: {
          version: '1.0.0',
          assessmentId: 'test-assessment',
          assessmentTitle: 'Test Assessment',
          assessmentType: 'skill-assessment',
          source: 'ui',
          fileType: 'self-assessment',
          sessionId: 'test-session',
          userId: 'test-user',
          pageUrl: '/learning/skill-assessment.md',
          coachMode: 'self-directed',
          lastUpdated: '2025-08-02T12:00:00.000Z'
        },
        timestamp: '2025-08-02T12:00:00.000Z',
        assessment: {
          questions: [
            {
              id: 'q1',
              question: 'Test question',
              category: 'ai-assisted-engineering',
              response: 4,
              responseText: 'Advanced',
              timestamp: '2025-08-02T12:00:00.000Z'
            }
          ],
          results: {
            categoryScores: {
              'ai-assisted-engineering': {
                score: 4.0,
                level: 'advanced',
                questionsCount: 1,
                totalPoints: 4,
                maxPoints: 5
              },
              'prompt-engineering': {
                score: 3.5,
                level: 'intermediate',
                questionsCount: 1,
                totalPoints: 3,
                maxPoints: 5
              },
              'edge-deployment': {
                score: 4.0,
                level: 'advanced',
                questionsCount: 1,
                totalPoints: 4,
                maxPoints: 5
              },
              'system-troubleshooting': {
                score: 3.0,
                level: 'intermediate',
                questionsCount: 1,
                totalPoints: 3,
                maxPoints: 5
              },
              'project-planning': {
                score: 4.5,
                level: 'advanced',
                questionsCount: 1,
                totalPoints: 4,
                maxPoints: 5
              },
              'data-analytics': {
                score: 4.0,
                level: 'advanced',
                questionsCount: 1,
                totalPoints: 4,
                maxPoints: 5
              }
            },
            overallScore: 4.0,
            overallLevel: 'advanced'
          },
          completionData: {
            isComplete: true,
            completedAt: '2025-08-02T12:00:00.000Z',
            duration: 300,
            questionsAnswered: 1,
            totalQuestions: 1
          }
        }
      };

      const result = await validateAndSanitizeProgress(validData);

      expect(result).toHaveProperty('data');
      expect(result).toHaveProperty('type');
      expect(result).toHaveProperty('validation');
      expect(result.type).toBe('self-assessment');
    });

    it('should throw error for invalid data', async () => {
      const invalidData = {
        metadata: {
          version: '1.0.0'
          // Missing required fields
        },
        timestamp: 'invalid-timestamp'
      };

      await expect(validateAndSanitizeProgress(invalidData)).rejects.toThrow();
    });

    it('should add timestamp when missing', async () => {
      const testData = {
        metadata: {
          version: '1.0.0',
          assessmentId: 'learning-skill-assessment',
          source: 'ui',
          fileType: 'self-assessment'
        },
        assessment: {
          questions: [
            {
              id: 'q1-test',
              question: 'Test question',
              category: 'ai-assisted-engineering',
              response: 3
            }
          ],
          results: {
            categoryScores: {
              'ai-assisted-engineering': { score: 3, level: 'intermediate', questionsCount: 1 },
              'prompt-engineering': { score: 3, level: 'intermediate', questionsCount: 1 },
              'edge-deployment': { score: 3, level: 'intermediate', questionsCount: 1 },
              'system-troubleshooting': { score: 3, level: 'intermediate', questionsCount: 1 },
              'project-planning': { score: 3, level: 'intermediate', questionsCount: 1 },
              'data-analytics': { score: 3, level: 'intermediate', questionsCount: 1 }
            },
            overallScore: 3
          }
        },
        timestamp: '2025-01-10T16:43:10.000Z' // Valid timestamp
      };

      // Remove timestamp to test adding it
      delete testData.timestamp;

      // Use addTimestamp to add it during sanitization
      const result = await validateAndSanitizeProgress(testData, { addTimestamp: true });

      expect(result.data).toHaveProperty('timestamp');
      expect(result.data.timestamp).toBeDefined();
      expect(typeof result.data.timestamp).toBe('string');
      expect(result.type).toBe('self-assessment');
    });
  });

  describe('extractMetadataSummary', () => {
    it('should extract metadata summary for self-assessment', () => {
      const data = {
        metadata: {
          assessmentId: 'skill-assessment',
          assessmentTitle: 'AI Skills Assessment',
          assessmentType: 'skill-assessment'
        },
        assessment: {
          results: {
            overallLevel: 'intermediate'
          }
        }
      };

      const result = extractMetadataSummary(data, 'self-assessment');

      expect(result.type).toBe('self-assessment');
      expect(result.id).toBe('skill-assessment');
      expect(result.title).toBe('AI Skills Assessment');
      expect(result.category).toBe('skill-assessment');
    });

    it('should extract metadata summary for kata-progress', () => {
      const data = {
        metadata: {
          kataId: 'docker-kata',
          kataTitle: 'Docker Fundamentals'
        },
        progress: {
          completionPercentage: 75
        }
      };

      const result = extractMetadataSummary(data, 'kata-progress');

      expect(result.type).toBe('kata-progress');
      expect(result.id).toBe('docker-kata');
      expect(result.title).toBe('Docker Fundamentals');
      expect(result.category).toBe('general');
    });

    it('should handle missing metadata gracefully', () => {
      const data = {};

      const result = extractMetadataSummary(data, 'self-assessment');

      expect(result.type).toBe('self-assessment');
      expect(result.id).toBe('unknown');
      expect(result.title).toBe('Self Assessment');
    });
  });

  describe('getSupportedSchemaTypes', () => {
    it('should return array of supported schema types', () => {
      const types = getSupportedSchemaTypes();

      expect(Array.isArray(types)).toBe(true);
      expect(types.length).toBeGreaterThan(0);

      types.forEach(typeInfo => {
        expect(typeInfo).toHaveProperty('type');
        expect(typeInfo).toHaveProperty('description');
        expect(typeInfo).toHaveProperty('patterns');
      });
    });

    it('should include common progress types', () => {
      const types = getSupportedSchemaTypes();
      const typeNames = types.map(t => t.type);

      expect(typeNames).toContain('self-assessment');
      expect(typeNames).toContain('kata-progress');
      expect(typeNames).toContain('lab-progress');
    });
  });
});
