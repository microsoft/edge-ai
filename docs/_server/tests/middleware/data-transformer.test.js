/**
 * Data Transformer Middleware
 * Tests for data transformation middleware functions
 */

import { describe, it, beforeEach, afterEach, expect, vi } from 'vitest';
import {
  transformSimpleApiFormat,
  transformSelfAssessmentData,
  transformKataProgressData,
  transformLabProgressData,
  dataTransformer
} from '../../middleware/data-transformer.js';

describe('Data Transformer Middleware', () => {
  describe('transformSimpleApiFormat', () => {
    it('should transform simple API format for self-assessment', () => {
      const simpleData = {
        type: 'self-assessment',
        data: {
          assessmentId: 'test-assessment',
          assessmentTitle: 'Test Assessment',
          responses: {
            'q1': 4,
            'q2': 3
          },
          completed: true,
          timestamp: '2025-08-02T12:00:00.000Z'
        }
      };

      const result = transformSimpleApiFormat(simpleData);

      expect(result).toHaveProperty('metadata');
      expect(result).toHaveProperty('timestamp');
      expect(result).toHaveProperty('assessment');
      expect(result.metadata.fileType).toBe('self-assessment');
      expect(result.metadata.assessmentId).toBe('test-assessment');
      expect(result.assessment.questions).toBeInstanceOf(Array);
      expect(result.assessment.results).toBeInstanceOf(Object);
    });

    it('should transform simple API format for kata-progress', () => {
      const simpleData = {
        type: 'kata-progress',
        data: {
          kataId: 'test-kata',
          kataTitle: 'Test Kata',
          progress: {
            checkboxStates: {
              'task1': true,
              'task2': false
            },
            completed: 1,
            total: 2,
            percentage: 50
          },
          timestamp: '2025-08-02T12:00:00.000Z'
        }
      };

      const result = transformSimpleApiFormat(simpleData);

      expect(result).toHaveProperty('metadata');
      expect(result).toHaveProperty('timestamp');
      expect(result).toHaveProperty('progress');
      expect(result.metadata.fileType).toBe('kata-progress');
      expect(result.metadata.kataId).toBe('test-kata');
      expect(result.progress.checkboxStates).to.deep.equal({
        'task1': true,
        'task2': false
      });
    });

    it('should transform simple API format for lab-progress', () => {
      const simpleData = {
        type: 'lab-progress',
        data: {
          labId: 'test-lab',
          labTitle: 'Test Lab',
          currentStep: 2,
          totalSteps: 5,
          completed: false,
          timestamp: '2025-08-02T12:00:00.000Z'
        }
      };

      const result = transformSimpleApiFormat(simpleData);

      expect(result).toHaveProperty('metadata');
      expect(result).toHaveProperty('timestamp');
      expect(result).toHaveProperty('progress');
      expect(result.metadata.fileType).toBe('lab-progress');
      expect(result.metadata.labId).toBe('test-lab');
      expect(result.progress.currentStep).toBe(2);
    });

    it('should handle kata UI format', () => {
      const uiData = {
        kataId: 'test-kata',
        progress: {
          checkboxStates: {
            'task1': true,
            'task2': false
          },
          completed: 1,
          total: 2,
          percentage: 50
        },
        timestamp: '2025-08-02T12:00:00.000Z'
      };

      const result = transformSimpleApiFormat(uiData);

      expect(result).toHaveProperty('metadata');
      expect(result).toHaveProperty('progress');
      expect(result.metadata.kataId).toBe('test-kata');
      expect(result.progress.completedTasks).toBe(1);
      expect(result.progress.totalTasks).toBe(2);
    });

    it('should return data as-is if already in full format', () => {
      const fullFormatData = {
        metadata: {
          version: '1.0.0',
          fileType: 'self-assessment',
          assessmentId: 'test-assessment'
        },
        timestamp: '2025-08-02T12:00:00.000Z',
        assessment: {
          questions: [],
          results: {}
        }
      };

      const result = transformSimpleApiFormat(fullFormatData);

      expect(result).toEqual(fullFormatData);
    });

    it('should throw error for unsupported progress type', () => {
      const simpleData = {
        type: 'unsupported-type',
        data: {
          someField: 'value'
        }
      };

      expect(() => transformSimpleApiFormat(simpleData)).to.throw('Unsupported progress type: unsupported-type');
    });
  });

  describe('transformSelfAssessmentData', () => {
    it('should transform self-assessment data with all fields', () => {
      const payload = {
        assessmentId: 'skill-assessment',
        assessmentTitle: 'Skill Assessment',
        responses: {
          'q1': 4,
          'q2': 3,
          'q3': 5
        },
        completed: true,
        duration: 300,
        timestamp: '2025-08-02T12:00:00.000Z',
        sessionId: 'test-session',
        userId: 'test-user',
        pageUrl: '/learning/skill-assessment.md',
        coachMode: 'self-directed'
      };

      const result = transformSelfAssessmentData(payload);

      expect(result.metadata.assessmentId).toBe('skill-assessment');
      expect(result.metadata.assessmentTitle).toBe('Skill Assessment');
      expect(result.metadata.sessionId).toBe('test-session');
      expect(result.metadata.userId).toBe('test-user');
      expect(result.assessment.questions).to.have.length(3);
      expect(result.assessment.results.overallScore).to.be.a('number');
      expect(result.assessment.completionData.isComplete).toBe(true);
      expect(result.assessment.completionData.duration).toBe(300);
    });

    it('should handle missing optional fields with defaults', () => {
      const payload = {
        responses: {
          'q1': 3
        }
      };

      const result = transformSelfAssessmentData(payload);

      expect(result.metadata.assessmentId).toBe('skill-assessment');
      expect(result.metadata.assessmentTitle).toBe('Skill Assessment');
      expect(result.metadata.sessionId).to.include('assessment-session-');
      expect(result.metadata.userId).toBe('anonymous');
      expect(result.metadata.pageUrl).toBe('/learning/skill-assessment.md');
      expect(result.metadata.coachMode).toBe('self-directed');
    });

    it('should ensure assessmentId ends with -assessment', () => {
      const payload = {
        assessmentId: 'my-custom-test',
        responses: { 'q1': 3 }
      };

      const result = transformSelfAssessmentData(payload);

      expect(result.metadata.assessmentId).toBe('my-custom-test-assessment');
    });

    it('should not double-append -assessment', () => {
      const payload = {
        assessmentId: 'skill-assessment',
        responses: { 'q1': 3 }
      };

      const result = transformSelfAssessmentData(payload);

      expect(result.metadata.assessmentId).toBe('skill-assessment');
    });
  });

  describe('transformKataProgressData', () => {
    it('should transform kata progress data with all fields', () => {
      const payload = {
        kataId: 'test-kata',
        kataTitle: 'Test Kata',
        progress: {
          checkboxStates: {
            'task1': true,
            'task2': false,
            'task3': true
          },
          completed: 2,
          total: 3,
          percentage: 67
        },
        currentStep: 'task2',
        timestamp: '2025-08-02T12:00:00.000Z',
        sessionId: 'kata-session',
        userId: 'test-user'
      };

      const result = transformKataProgressData(payload);

      expect(result.metadata.kataId).toBe('test-kata');
      expect(result.metadata.kataTitle).toBe('Test Kata');
      expect(result.metadata.sessionId).toBe('kata-session');
      expect(result.metadata.userId).toBe('test-user');
      expect(result.progress.checkboxStates).toEqual(payload.progress.checkboxStates);
      expect(result.progress.completedTasks).toBe(2);
      expect(result.progress.totalTasks).toBe(3);
      expect(result.progress.completionPercentage).toBe(67);
      expect(result.progress.currentStep).toBe('task2');
    });

    it('should handle missing optional fields with defaults', () => {
      const payload = {
        kataId: 'minimal-kata'
      };

      const result = transformKataProgressData(payload);

      expect(result.metadata.kataId).toBe('minimal-kata');
      expect(result.metadata.kataTitle).toBe('Unknown Kata');
      expect(result.metadata.sessionId).to.include('kata-session-');
      expect(result.metadata.userId).toBe('anonymous');
      expect(result.progress.checkboxStates).toEqual({});
      expect(result.progress.completedTasks).toBe(0);
      expect(result.progress.totalTasks).toBe(0);
      expect(result.progress.completionPercentage).toBe(0);
    });

    it('should calculate currentStep from unchecked tasks', () => {
      const payload = {
        kataId: 'test-kata',
        progress: {
          checkboxStates: {
            'task1': true,
            'task2': false,
            'task3': false
          }
        }
      };

      const result = transformKataProgressData(payload);

      expect(result.progress.currentStep).toBe('task2');
    });
  });

  describe('transformLabProgressData', () => {
    it('should transform lab progress data with all fields', () => {
      const payload = {
        labId: 'test-lab',
        labTitle: 'Test Lab',
        currentStep: 3,
        totalSteps: 5,
        completed: false,
        timestamp: '2025-08-02T12:00:00.000Z',
        sessionId: 'lab-session',
        userId: 'test-user'
      };

      const result = transformLabProgressData(payload);

      expect(result.metadata.labId).toBe('test-lab');
      expect(result.metadata.labTitle).toBe('Test Lab');
      expect(result.metadata.sessionId).toBe('lab-session');
      expect(result.metadata.userId).toBe('test-user');
      expect(result.progress.currentStep).toBe(3);
      expect(result.progress.totalSteps).toBe(5);
      expect(result.progress.completed).to.be.false;
      expect(result.progress.completedAt).to.be.null;
    });

    it('should handle completion timestamp', () => {
      const payload = {
        labId: 'test-lab',
        completed: true,
        timestamp: '2025-08-02T12:00:00.000Z'
      };

      const result = transformLabProgressData(payload);

      expect(result.progress.completed).toBe(true);
      expect(result.progress.completedAt).toBe('2025-08-02T12:00:00.000Z');
    });

    it('should handle missing optional fields with defaults', () => {
      const payload = {
        labId: 'minimal-lab'
      };

      const result = transformLabProgressData(payload);

      expect(result.metadata.labId).toBe('minimal-lab');
      expect(result.metadata.labTitle).toBe('Unknown Lab');
      expect(result.metadata.sessionId).to.include('lab-session-');
      expect(result.metadata.userId).toBe('anonymous');
      expect(result.progress.currentStep).toBe(0);
      expect(result.progress.totalSteps).toBe(0);
      expect(result.progress.completed).to.be.false;
    });
  });

  describe('dataTransformer middleware', () => {
    let req, res, next, jsonSpy;

    beforeEach(() => {
      req = {
        body: {}
      };
      jsonSpy = vi.fn();
      res = {
        status: vi.fn().mockReturnValue({ json: jsonSpy }),
        json: jsonSpy
      };
      next = vi.fn();
    });

    afterEach(() => {
      vi.restoreAllMocks();
    });

    it('should transform simple API format when autoTransform is enabled', () => {
      req.body = {
        type: 'self-assessment',
        data: {
          assessmentId: 'test-assessment',
          responses: { 'q1': 3 },
          completed: true
        }
      };

      const middleware = dataTransformer({ autoTransform: true });
      middleware(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
      expect(req.body).toHaveProperty('metadata');
      expect(req.body).toHaveProperty('assessment');
      expect(req.body.metadata.fileType).toBe('self-assessment');
    });

    it('should not transform when autoTransform is disabled', () => {
      const originalBody = {
        type: 'self-assessment',
        data: {
          assessmentId: 'test-assessment',
          responses: { 'q1': 3 }
        }
      };
      req.body = { ...originalBody };

      const middleware = dataTransformer({ autoTransform: false });
      middleware(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
      expect(req.body).toEqual(originalBody);
    });

    it('should handle transformation errors', () => {
      req.body = {
        type: 'unsupported-type',
        data: {
          someField: 'value'
        }
      };

      const middleware = dataTransformer({ autoTransform: true });
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(jsonSpy).toHaveBeenCalledTimes(1);
      expect(jsonSpy.mock.calls[0][0]).toHaveProperty('error', 'Data transformation failed');
      expect(next).not.toHaveBeenCalled();
    });

    it('should continue normally when no body provided', () => {
      req.body = null;

      const middleware = dataTransformer({ autoTransform: true });
      middleware(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
    });
  });
});
