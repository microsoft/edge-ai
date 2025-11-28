/**
 * Schema Validator Tests
 * Tests for client-side schema validation
 */

import { SchemaValidator } from '../../../assets/js/utils/schema-validator.js';

describe('SchemaValidator', () => {
  describe('validateSelfAssessment', () => {
    const validPayload = {
      type: 'self-assessment',
      metadata: {
        version: '1.0.0',
        assessmentId: 'test-assessment-123',
        source: 'ui',
        fileType: 'self-assessment'
      },
      assessment: {
        questions: [
          {
            id: 'q1',
            question: 'How experienced are you with AI-assisted development?',
            category: 'ai-assisted-engineering',
            response: 3
          },
          {
            id: 'q2',
            question: 'How comfortable are you writing effective prompts?',
            category: 'prompt-engineering',
            response: 4
          }
        ],
        results: {
          categoryScores: {
            'ai-assisted-engineering': {
              score: 3.0,
              level: 'intermediate',
              questionCount: 1
            },
            'prompt-engineering': {
              score: 4.0,
              level: 'advanced',
              questionCount: 1
            }
          },
          overallScore: 3.5,
          overallLevel: 'intermediate',
          strengthCategories: ['prompt-engineering'],
          growthCategories: []
        }
      },
      timestamp: new Date().toISOString()
    };

    it('should validate a complete valid payload', () => {
      const result = SchemaValidator.validateSelfAssessment(validPayload);
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should reject payload missing metadata', () => {
      const payload = { ...validPayload };
      delete payload.metadata;
      const result = SchemaValidator.validateSelfAssessment(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Missing metadata');
    });

    it('should reject payload missing metadata.version', () => {
      const payload = JSON.parse(JSON.stringify(validPayload));
      delete payload.metadata.version;
      const result = SchemaValidator.validateSelfAssessment(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Missing metadata.version');
    });

    it('should reject invalid version format', () => {
      const payload = JSON.parse(JSON.stringify(validPayload));
      payload.metadata.version = '1.0';
      const result = SchemaValidator.validateSelfAssessment(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Invalid metadata.version format (expected: X.Y.Z)');
    });

    it('should reject payload missing metadata.source', () => {
      const payload = JSON.parse(JSON.stringify(validPayload));
      delete payload.metadata.source;
      const result = SchemaValidator.validateSelfAssessment(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Missing metadata.source');
    });

    it('should reject invalid source value', () => {
      const payload = JSON.parse(JSON.stringify(validPayload));
      payload.metadata.source = 'invalid-source';
      const result = SchemaValidator.validateSelfAssessment(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Invalid metadata.source (expected: ui, coach, file-watcher, server, import, or manual)');
    });

    it('should reject payload missing metadata.fileType', () => {
      const payload = JSON.parse(JSON.stringify(validPayload));
      delete payload.metadata.fileType;
      const result = SchemaValidator.validateSelfAssessment(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Missing metadata.fileType');
    });

    it('should reject invalid fileType value', () => {
      const payload = JSON.parse(JSON.stringify(validPayload));
      payload.metadata.fileType = 'wrong-type';
      const result = SchemaValidator.validateSelfAssessment(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Invalid metadata.fileType (expected: self-assessment)');
    });

    it('should reject payload missing assessment', () => {
      const payload = { ...validPayload };
      delete payload.assessment;
      const result = SchemaValidator.validateSelfAssessment(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Missing assessment');
    });

    it('should reject payload missing assessment.questions', () => {
      const payload = JSON.parse(JSON.stringify(validPayload));
      delete payload.assessment.questions;
      const result = SchemaValidator.validateSelfAssessment(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Missing assessment.questions');
    });

    it('should reject questions missing question text', () => {
      const payload = JSON.parse(JSON.stringify(validPayload));
      delete payload.assessment.questions[0].question;
      const result = SchemaValidator.validateSelfAssessment(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain("Question 0: missing 'question' field");
    });

    it('should reject questions missing category', () => {
      const payload = JSON.parse(JSON.stringify(validPayload));
      delete payload.assessment.questions[1].category;
      const result = SchemaValidator.validateSelfAssessment(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain("Question 1: missing 'category' field");
    });

    it('should reject questions with invalid category', () => {
      const payload = JSON.parse(JSON.stringify(validPayload));
      payload.assessment.questions[0].category = 'invalid-category';
      const result = SchemaValidator.validateSelfAssessment(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain("Question 0: invalid category 'invalid-category'");
    });

    it('should accept all valid categories', () => {
      const validCategories = [
        'ai-assisted-engineering',
        'prompt-engineering',
        'edge-deployment',
        'system-troubleshooting',
        'project-planning',
        'data-analytics'
      ];

      validCategories.forEach(category => {
        const payload = JSON.parse(JSON.stringify(validPayload));
        payload.assessment.questions[0].category = category;
        const result = SchemaValidator.validateSelfAssessment(payload);
        expect(result.valid).toBe(true);
      });
    });

    it('should reject payload missing assessment.results', () => {
      const payload = JSON.parse(JSON.stringify(validPayload));
      delete payload.assessment.results;
      const result = SchemaValidator.validateSelfAssessment(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Missing assessment.results');
    });

    it('should reject payload missing categoryScores', () => {
      const payload = JSON.parse(JSON.stringify(validPayload));
      delete payload.assessment.results.categoryScores;
      const result = SchemaValidator.validateSelfAssessment(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Missing assessment.results.categoryScores');
    });

    it('should reject payload missing overallScore', () => {
      const payload = JSON.parse(JSON.stringify(validPayload));
      delete payload.assessment.results.overallScore;
      const result = SchemaValidator.validateSelfAssessment(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Missing assessment.results.overallScore');
    });

    it('should reject payload missing timestamp', () => {
      const payload = { ...validPayload };
      delete payload.timestamp;
      const result = SchemaValidator.validateSelfAssessment(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Missing timestamp');
    });
  });

  describe('validate (auto-detect)', () => {
    it('should auto-detect self-assessment type', () => {
      const payload = {
        type: 'self-assessment',
        metadata: {
          version: '1.0.0',
          assessmentId: 'test-123',
          source: 'ui',
          fileType: 'self-assessment'
        },
        assessment: {
          questions: [],
          results: {
            categoryScores: {},
            overallScore: 0,
            overallLevel: 'beginner'
          }
        },
        timestamp: new Date().toISOString()
      };

      const result = SchemaValidator.validate(payload);
      expect(result.valid).toBe(true);
    });

    it('should reject null payload', () => {
      const result = SchemaValidator.validate(null);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Payload is null or undefined');
    });

    it('should reject unrecognized payload type', () => {
      const payload = {
        unknownField: 'value'
      };
      const result = SchemaValidator.validate(payload);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Unable to determine payload type');
    });
  });
});
