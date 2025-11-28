/**
 * Frontend Schema Validator
 * Validates payloads before sending to server to catch issues early
 * @module SchemaValidator
 */

/**
 * Schema Validator for client-side validation
 */
export class SchemaValidator {
  /**
   * Validate self-assessment payload against expected schema
   * @param {Object} payload - Self-assessment payload to validate
   * @returns {Object} Validation result with valid flag and errors array
   */
  static validateSelfAssessment(payload) {
    const errors = [];

    // Check top-level structure
    if (!payload.metadata) {
      errors.push('Missing metadata');
    }
    if (!payload.assessment) {
      errors.push('Missing assessment');
    }
    if (!payload.timestamp) {
      errors.push('Missing timestamp');
    }

    // Check metadata required fields
    if (payload.metadata) {
      if (!payload.metadata.version) {
        errors.push('Missing metadata.version');
      } else if (!/^\d+\.\d+\.\d+$/.test(payload.metadata.version)) {
        errors.push('Invalid metadata.version format (expected: X.Y.Z)');
      }

      if (!payload.metadata.source) {
        errors.push('Missing metadata.source');
      } else if (!['ui', 'coach', 'file-watcher', 'server', 'import', 'manual'].includes(payload.metadata.source)) {
        errors.push('Invalid metadata.source (expected: ui, coach, file-watcher, server, import, or manual)');
      }

      if (!payload.metadata.fileType) {
        errors.push('Missing metadata.fileType');
      } else if (payload.metadata.fileType !== 'self-assessment') {
        errors.push('Invalid metadata.fileType (expected: self-assessment)');
      }

      if (!payload.metadata.assessmentId) {
        errors.push('Missing metadata.assessmentId');
      }
    }

    // Check assessment structure
    if (payload.assessment) {
      if (!payload.assessment.questions) {
        errors.push('Missing assessment.questions');
      } else if (!Array.isArray(payload.assessment.questions)) {
        errors.push('assessment.questions must be an array');
      } else {
        payload.assessment.questions.forEach((q, i) => {
          if (!q.question) {
            errors.push(`Question ${i}: missing 'question' field`);
          }
          if (!q.category) {
            errors.push(`Question ${i}: missing 'category' field`);
          } else {
            const validCategories = [
              'ai-assisted-engineering',
              'prompt-engineering',
              'edge-deployment',
              'system-troubleshooting',
              'project-planning',
              'data-analytics'
            ];
            if (!validCategories.includes(q.category)) {
              errors.push(`Question ${i}: invalid category '${q.category}'`);
            }
          }
          if (q.response === undefined || q.response === null) {
            errors.push(`Question ${i}: missing 'response'`);
          }
        });
      }

      if (!payload.assessment.results) {
        errors.push('Missing assessment.results');
      } else {
        if (!payload.assessment.results.categoryScores) {
          errors.push('Missing assessment.results.categoryScores');
        } else if (typeof payload.assessment.results.categoryScores !== 'object') {
          errors.push('assessment.results.categoryScores must be an object');
        }

        if (payload.assessment.results.overallScore === undefined) {
          errors.push('Missing assessment.results.overallScore');
        }

        if (!payload.assessment.results.overallLevel) {
          errors.push('Missing assessment.results.overallLevel');
        }
      }
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }

  /**
   * Validate kata progress payload
   * @param {Object} payload - Kata progress payload to validate
   * @returns {Object} Validation result
   */
  static validateKataProgress(payload) {
    const errors = [];

    if (!payload.metadata) {
      errors.push('Missing metadata');
    }
    if (!payload.progress) {
      errors.push('Missing progress');
    }

    if (payload.metadata) {
      if (!payload.metadata.kataId) {
        errors.push('Missing metadata.kataId');
      }
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }

  /**
   * Validate any progress payload by detecting its type
   * @param {Object} payload - Progress payload to validate
   * @returns {Object} Validation result
   */
  static validate(payload) {
    if (!payload) {
      return {
        valid: false,
        errors: ['Payload is null or undefined']
      };
    }

    // Detect payload type
    if (payload.metadata?.fileType === 'self-assessment' || payload.type === 'self-assessment') {
      return this.validateSelfAssessment(payload);
    }

    if (payload.metadata?.kataId || payload.kataId) {
      return this.validateKataProgress(payload);
    }

    return {
      valid: false,
      errors: ['Unable to determine payload type']
    };
  }
}
