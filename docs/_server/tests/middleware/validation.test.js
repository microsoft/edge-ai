import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import {
  validateProgressData,
  validateSpecificProgressType,
  validationErrorHandler
} from '../../middleware/validation.js';

describe('Validation Middleware', () => {
  let req, res, next, jsonSpy;

  beforeEach(() => {
    req = {
      body: {},
      validatedProgress: {}
    };
    res = {
      status: vi.fn().mockReturnThis(),
      json: vi.fn()
    };
    next = vi.fn();
    jsonSpy = res.json;
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('validateProgressData', () => {
    it('should validate valid self-assessment data', async () => {
      req.body = {
        metadata: {
          version: '1.0.0',
          assessmentId: 'learning-skill-assessment',
          source: 'ui',
          fileType: 'self-assessment',
          sessionId: 'test-session',
          userId: 'test-user',
          lastUpdated: '2025-08-02T12:00:00.000Z'
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
        timestamp: '2025-08-02T12:00:00.000Z'
      };

      const middleware = validateProgressData();
      await middleware(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
      expect(req.validatedProgress.type).toBe('self-assessment');
    });

    it('should validate valid kata-progress data', async () => {
      req.body = {
        metadata: {
          kataId: 'test-kata',
          kataTitle: 'Test Kata',
          version: '1.0.0',
          source: 'ui',
          fileType: 'kata-progress',
          sessionId: 'test-session',
          userId: 'test-user',
          lastUpdated: '2025-08-02T12:00:00.000Z'
        },
        progress: {
          checkboxStates: {
            'task-1': true,
            'task-2': false
          }
        },
        timestamp: '2025-08-02T12:00:00.000Z'
      };

      const middleware = validateProgressData();
      await middleware(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
      expect(req.validatedProgress.type).toBe('kata-progress');
    });

    it('should return 400 for invalid data', async () => {
      req.body = {
        invalid: 'data'
      };

      const middleware = validateProgressData();
      await middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(jsonSpy).toHaveBeenCalledTimes(1);
      expect(jsonSpy.mock.calls[0][0]).toHaveProperty('error', 'Progress data validation failed');
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('validateSpecificProgressType', () => {
    it('should validate matching progress type', async () => {
      req.body = {
        metadata: {
          version: '1.0.0',
          assessmentId: 'learning-skill-assessment',
          source: 'ui',
          fileType: 'self-assessment',
          sessionId: 'test-session',
          userId: 'test-user',
          lastUpdated: '2025-08-02T12:00:00.000Z'
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
        timestamp: '2025-08-02T12:00:00.000Z'
      };

      const middleware = validateSpecificProgressType('self-assessment');
      await middleware(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
      expect(req.validatedProgress.type).toBe('self-assessment');
    });

    it('should return 400 for non-matching progress type', async () => {
      req.body = {
        metadata: {
          kataId: 'test-kata',
          kataTitle: 'Test Kata',
          version: '1.0.0',
          source: 'ui',
          fileType: 'kata-progress',
          sessionId: 'test-session',
          userId: 'test-user',
          lastUpdated: '2025-08-02T12:00:00.000Z'
        },
        progress: {
          checkboxStates: {
            'task-1': true,
            'task-2': false
          }
        },
        timestamp: '2025-08-02T12:00:00.000Z'
      };

      const middleware = validateSpecificProgressType('self-assessment');
      await middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(jsonSpy).toHaveBeenCalledTimes(1);
      expect(jsonSpy.mock.calls[0][0]).toHaveProperty('error', 'self-assessment validation failed');
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('validationErrorHandler', () => {
    let err;

    beforeEach(() => {
      err = new Error('Test error');
    });

    it('should handle validation errors', () => {
      err.name = 'ValidationError';

      validationErrorHandler(err, req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(jsonSpy).toHaveBeenCalledTimes(1);
      expect(jsonSpy.mock.calls[0][0]).toHaveProperty('error', 'Validation error');
      expect(next).not.toHaveBeenCalled();
    });

    it('should pass non-validation errors to next', () => {
      err.name = 'SomeOtherError';

      validationErrorHandler(err, req, res, next);

      expect(res.status).not.toHaveBeenCalled();
      expect(next).toHaveBeenCalledTimes(1);
      expect(next.mock.calls[0][0]).toBe(err);
    });
  });
});
