/**
 * Input Validator Middleware Tests
 * Test comprehensive input validation and security protection
 */

import { vi, describe, test, expect, beforeEach } from 'vitest';
import { inputValidator, validateProgressData, sanitizeInput } from '../../middleware/input-validator.js';

describe('Input Validator Middleware', () => {
  let req, res, next;

  beforeEach(() => {
    req = {
      body: {},
      params: {},
      query: {},
      headers: {},
      is: vi.fn().mockReturnValue(true) // Mock content-type check
    };
    res = {
      status: vi.fn().mockReturnThis(),
      json: vi.fn()
    };
    next = vi.fn();
  });

  describe('validateProgressData', () => {
    test('should validate valid self-assessment data', () => {
      req.body = {
        type: 'self-assessment',
        metadata: {
          assessmentId: 'valid-assessment-id',
          title: 'Test Assessment'
        },
        assessment: {
          categories: ['category1'],
          completedTasks: ['task1']
        },
        timestamp: new Date().toISOString()
      };

      const validator = validateProgressData();
      validator(req, res, next);

      expect(next).toHaveBeenCalledWith();
      expect(res.status).not.toHaveBeenCalled();
    });

    test('should validate valid kata-progress data', () => {
      req.body = {
        type: 'kata-progress',
        metadata: {
          kataId: 'valid-kata-id',
          title: 'Test Kata'
        },
        progress: {
          currentStep: 1,
          completedSteps: [0]
        },
        timestamp: new Date().toISOString()
      };

      const validator = validateProgressData();
      validator(req, res, next);

      expect(next).toHaveBeenCalledWith();
      expect(res.status).not.toHaveBeenCalled();
    });

    test('should reject data with missing required fields', () => {
      req.body = {
        type: 'self-assessment'
        // Missing metadata, assessment, timestamp
      };

      const validator = validateProgressData();
      validator(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: 'Validation failed',
        message: 'Request data does not match required schema',
        details: expect.any(Array),
        success: false
      });
      expect(next).not.toHaveBeenCalled();
    });

    test('should reject data with invalid type', () => {
      req.body = {
        type: 'invalid-type',
        metadata: {},
        assessment: {},
        timestamp: new Date().toISOString()
      };

      const validator = validateProgressData();
      validator(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: 'Validation failed',
        message: 'Request data does not match required schema',
        details: expect.any(Array),
        success: false
      });
      expect(next).not.toHaveBeenCalled();
    });

    test('should reject data with dangerous patterns', () => {
      req.body = {
        type: 'self-assessment',
        metadata: {
          assessmentId: 'test<script>alert("xss")</script>',
          title: 'Test & Assessment'
        },
        assessment: {
          categories: ['category1'],
          completedTasks: ['task1']
        },
        timestamp: new Date().toISOString()
      };

      const validator = validateProgressData();
      validator(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: 'Validation failed',
        message: expect.stringContaining('Invalid characters detected'),
        success: false
      });
      expect(next).not.toHaveBeenCalled();
    });

    test('should sanitize benign input data', () => {
      req.body = {
        type: 'self-assessment',
        metadata: {
          assessmentId: '  test-assessment-123  ',
          title: '  Test Assessment  '
        },
        assessment: {
          categories: ['category1'],
          completedTasks: ['task1']
        },
        timestamp: new Date().toISOString()
      };

      const validator = validateProgressData();
      validator(req, res, next);

      expect(req.body.metadata.assessmentId).toBe('test-assessment-123');
      expect(req.body.metadata.title).toBe('Test Assessment');
      expect(next).toHaveBeenCalledWith();
      expect(res.status).not.toHaveBeenCalled();
    });
  });

  describe('sanitizeInput', () => {
    test('should remove script tags', () => {
      const input = 'Hello <script>alert("xss")</script> World';
      const result = sanitizeInput(input);
      expect(result).toBe('Hello  World');
    });

    test('should remove HTML tags', () => {
      const input = 'Hello <div>test</div> World';
      const result = sanitizeInput(input);
      expect(result).toBe('Hello test World');
    });

    test('should handle null and undefined', () => {
      expect(sanitizeInput(null)).toBe('');
      expect(sanitizeInput(undefined)).toBe('');
    });

    test('should handle non-string values', () => {
      expect(sanitizeInput(123)).toBe('123');
      expect(sanitizeInput(true)).toBe('true');
    });

    test('should trim whitespace', () => {
      const input = '  Hello World  ';
      const result = sanitizeInput(input);
      expect(result).toBe('Hello World');
    });
  });

  describe('inputValidator middleware', () => {
    test('should validate and sanitize request body', () => {
      req.body = {
        title: '  Test Title  ',
        description: 'Valid description'
      };

      const validator = inputValidator({
        bodyFields: ['title', 'description']
      });
      validator(req, res, next);

      expect(req.body.title).toBe('Test Title');
      expect(req.body.description).toBe('Valid description');
      expect(next).toHaveBeenCalledWith();
      expect(res.status).not.toHaveBeenCalled();
    });

    test('should validate request parameters', () => {
      req.params = {
        id: 'valid-id-123',
        type: 'self-assessment'
      };

      const validator = inputValidator({
        paramFields: ['id', 'type']
      });
      validator(req, res, next);

      expect(next).toHaveBeenCalledWith();
      expect(res.status).not.toHaveBeenCalled();
    });

    test('should reject invalid parameter patterns', () => {
      req.params = {
        id: '../../../etc/passwd',
        type: 'invalid<script>'
      };

      const validator = inputValidator({
        paramFields: ['id', 'type']
      });
      validator(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: 'Invalid input',
        message: 'Parameter validation failed',
        success: false
      });
      expect(next).not.toHaveBeenCalled();
    });

    test('should limit string lengths', () => {
      req.body = {
        title: 'a'.repeat(1000),
        description: 'Valid description'
      };

      const validator = inputValidator({
        bodyFields: ['title', 'description'],
        maxLength: 100
      });
      validator(req, res, next);

      expect(req.body.title).toHaveLength(100);
      expect(next).toHaveBeenCalledWith();
    });
  });
});
