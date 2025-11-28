/**
 * Unified Progress Schema Validator
 * Centralized validation for all progress file types
 * Version: 2.0.0
 */

/**
 * Unified Progress Schema Validator
 * Provides consistent validation across all progress tracking systems
 * @class UnifiedProgressSchemaValidator
 */
class UnifiedProgressSchemaValidator {
  /**
   * Constructor with dependency injection
   * @param {Object} [dependencies={}] - Injected dependencies
   * @param {Object} [dependencies.errorHandler] - Error handling service
   * @param {Object} [dependencies.debugHelp// ES6 Module Export
export default UnifiedProgressSchemaValidator;logging service
   */
  constructor(dependencies = {}) {
    try {
      // Dependency injection
      this.errorHandler = dependencies.errorHandler || null;
      this.debugHelper = dependencies.debugHelper || null;

      // Core state
      this.schemas = new Map();

      // Initialize
      this.loadBuiltInSchemas();

      this.logDebug('UnifiedProgressSchemaValidator initialized successfully');
    } catch (error) {
      this.handleError('Failed to initialize UnifiedProgressSchemaValidator', error);
      throw error;
    }
  }

  /**
   * Log debug message if debug helper is available
   * @param {string} message - Debug message
   * @param {*} [data] - Optional data to log
   * @private
   */
  logDebug(message, data = null) {
    if (this.debugHelper && typeof this.debugHelper.log === 'function') {
      this.debugHelper?.log?.(message, data);
    }
  }

  /**
   * Handle error with error handler if available
   * @param {string} message - Error message
   * @param {Error} error - Error object
   * @private
   */
  handleError(message, error) {
    if (this.errorHandler && typeof this.errorHandler.handleError === 'function') {
      this.errorHandler.handleError(error, {
        context: 'UnifiedProgressSchemaValidator',
        operation: message
      });
    }
  }

  /**
   * Load built-in schemas
   */
  loadBuiltInSchemas() {
    try {
    // Kata Progress Schema
    this.schemas.set('kata-progress', {
      type: 'object',
      required: ['timestamp', 'progress', 'metadata'],
      properties: {
        timestamp: { type: 'string', format: 'date-time' },
        progress: {
          type: 'object',
          required: ['kataId', 'completedTasks', 'totalTasks'],
          properties: {
            kataId: { type: 'string' },
            completedTasks: { type: 'number', minimum: 0 },
            totalTasks: { type: 'number', minimum: 0 },
            completionPercentage: { type: 'number', minimum: 0, maximum: 100 },
            sections: { type: 'object' }
          }
        },
        metadata: {
          type: 'object',
          required: ['fileType', 'lastUpdateSource'],
          properties: {
            fileType: { type: 'string', enum: ['kata-progress'] },
            lastUpdateSource: { type: 'string' },
            lastUpdateTimestamp: { type: 'string', format: 'date-time' },
            version: { type: 'string' }
          }
        }
      }
    });

    // Lab Progress Schema
    this.schemas.set('lab-progress', {
      type: 'object',
      required: ['timestamp', 'progress', 'metadata'],
      properties: {
        timestamp: { type: 'string', format: 'date-time' },
        progress: {
          type: 'object',
          required: ['labId', 'completedTasks', 'totalTasks'],
          properties: {
            labId: { type: 'string' },
            completedTasks: { type: 'number', minimum: 0 },
            totalTasks: { type: 'number', minimum: 0 },
            completionPercentage: { type: 'number', minimum: 0, maximum: 100 },
            sections: { type: 'object' }
          }
        },
        metadata: {
          type: 'object',
          required: ['fileType', 'lastUpdateSource'],
          properties: {
            fileType: { type: 'string', enum: ['lab-progress'] },
            lastUpdateSource: { type: 'string' },
            lastUpdateTimestamp: { type: 'string', format: 'date-time' },
            version: { type: 'string' }
          }
        }
      }
    });

    // Self-Assessment Schema
    this.schemas.set('self-assessment', {
      type: 'object',
      required: ['timestamp', 'assessment', 'metadata'],
      properties: {
        timestamp: { type: 'string', format: 'date-time' },
        assessment: {
          type: 'object',
          required: ['responses', 'categories', 'completionStatus'],
          properties: {
            responses: { type: 'object' },
            categories: {
              type: 'object',
              properties: {
                'ai-tools': { type: 'object' },
                'coding-practices': { type: 'object' },
                'testing-debugging': { type: 'object' },
                'learning-growth': { type: 'object' }
              }
            },
            completionStatus: {
              type: 'object',
              required: ['totalQuestions', 'answeredQuestions', 'completionPercentage'],
              properties: {
                totalQuestions: { type: 'number', minimum: 0 },
                answeredQuestions: { type: 'number', minimum: 0 },
                completionPercentage: { type: 'number', minimum: 0, maximum: 100 }
              }
            }
          }
        },
        metadata: {
          type: 'object',
          required: ['fileType', 'lastUpdateSource'],
          properties: {
            fileType: { type: 'string', enum: ['self-assessment'] },
            lastUpdateSource: { type: 'string' },
            lastUpdateTimestamp: { type: 'string', format: 'date-time' },
            version: { type: 'string' }
          }
        }
      }
    });

    // Form Progress Schema
    this.schemas.set('form-progress', {
      type: 'object',
      required: ['timestamp', 'formData', 'progressStats', 'metadata'],
      properties: {
        timestamp: { type: 'string', format: 'date-time' },
        formData: { type: 'object' },
        progressStats: {
          type: 'object',
          required: ['totalQuestions', 'answeredQuestions', 'completionPercentage'],
          properties: {
            totalQuestions: { type: 'number', minimum: 0 },
            answeredQuestions: { type: 'number', minimum: 0 },
            requiredQuestions: { type: 'number', minimum: 0 },
            answeredRequired: { type: 'number', minimum: 0 },
            completionPercentage: { type: 'number', minimum: 0, maximum: 100 },
            requiredCompletionPercentage: { type: 'number', minimum: 0, maximum: 100 }
          }
        },
        sectionProgress: { type: 'object' },
        metadata: {
          type: 'object',
          required: ['fileType', 'lastUpdateSource'],
          properties: {
            fileType: { type: 'string', enum: ['form-progress'] },
            lastUpdateSource: { type: 'string' },
            lastUpdateTimestamp: { type: 'string', format: 'date-time' },
            version: { type: 'string' },
            formId: { type: 'string' },
            formType: { type: 'string' }
          }
        }
      }
    });
  } catch (error) {
    this.handleError('Failed to load built-in schemas', error);
    throw error;
  }
}

  /**
   * Register a custom schema
   * @param {string} type - Schema type identifier
   * @param {Object} schema - Schema definition
   */
  registerSchema(type, schema) {
    try {
      if (!type || typeof type !== 'string') {
        throw new Error('Schema type must be a non-empty string');
      }
      if (!schema || typeof schema !== 'object') {
        throw new Error('Schema must be a valid object');
      }

      this.schemas.set(type, schema);
      this.logDebug(`Schema registered: ${type}`);
    } catch (error) {
      this.handleError('Failed to register schema', error);
      throw error;
    }
  }

  /**
   * Get schema by type
   * @param {string} type - Schema type identifier
   * @returns {Object|undefined} Schema definition
   */
  getSchema(type) {
    try {
      return this.schemas.get(type);
    } catch (error) {
      this.handleError('Failed to get schema', error);
      return undefined;
    }
  }

  /**
   * Validate data against schema
   * @param {*} data - Data to validate
   * @param {string} schemaType - Schema type identifier
   * @returns {Object} Validation result
   */
  validate(data, schemaType) {
    try {
      const schema = this.getSchema(schemaType);
      if (!schema) {
        return { valid: false, error: `Unknown schema type: ${schemaType}` };
      }

      return this.validateAgainstSchema(data, schema);
    } catch (error) {
      this.handleError('Failed to validate data', error);
      return { valid: false, error: error.message };
    }
  }

  /**
   * Validate data against a specific schema
   * @param {*} data - Data to validate
   * @param {Object} schema - Schema definition
   * @returns {Object} Validation result
   */
  validateAgainstSchema(data, schema) {
    try {
      // Basic validation implementation
      const result = this.validateObject(data, schema);
      return result.valid ? { valid: true } : result;
    } catch (error) {
      this.handleError('Failed to validate against schema', error);
      return { valid: false, error: error.message };
    }
  }

  /**
   * Validate object against schema
   * @param {*} obj - Object to validate
   * @param {Object} schema - Schema definition
   * @returns {Object} Validation result
   */
  validateObject(obj, schema) {
    try {
      if (schema.type === 'object') {
        if (!obj || typeof obj !== 'object' || Array.isArray(obj)) {
          return { valid: false, error: 'Expected object' };
        }

        // Check required properties
        if (schema.required) {
          for (const prop of schema.required) {
            if (!(prop in obj)) {
              return { valid: false, error: `Missing required property: ${prop}` };
            }
          }
        }

        // Validate properties
        if (schema.properties) {
          for (const [prop, propSchema] of Object.entries(schema.properties)) {
            if (prop in obj) {
              const result = this.validateProperty(obj[prop], propSchema);
              if (!result.valid) {
                return { valid: false, error: `Property '${prop}': ${result.error}` };
              }
            }
          }
        }

        return { valid: true };
      }

      return this.validateProperty(obj, schema);
    } catch (error) {
      this.handleError('Failed to validate object', error);
      return { valid: false, error: error.message };
    }
  }

  /**
   * Validate property against schema
   * @param {*} value - Value to validate
   * @param {Object} schema - Schema definition
   * @returns {Object} Validation result
   */
  validateProperty(value, schema) {
    try {
      // Type validation
      if (schema.type) {
        const actualType = Array.isArray(value) ? 'array' : typeof value;
        if (actualType !== schema.type) {
          return { valid: false, error: `Expected ${schema.type}, got ${actualType}` };
        }
      }

      // String format validation
      if (schema.type === 'string' && schema.format) {
        if (schema.format === 'date-time') {
          const date = new Date(value);
          if (isNaN(date.getTime())) {
            return { valid: false, error: 'Invalid date-time format' };
          }
        }
      }

      // Enum validation
      if (schema.enum && !schema.enum.includes(value)) {
        return { valid: false, error: `Value must be one of: ${schema.enum.join(', ')}` };
      }

      // Number validation
      if (schema.type === 'number') {
        if (typeof schema.minimum !== 'undefined' && value < schema.minimum) {
          return { valid: false, error: `Value must be >= ${schema.minimum}` };
        }
        if (typeof schema.maximum !== 'undefined' && value > schema.maximum) {
          return { valid: false, error: `Value must be <= ${schema.maximum}` };
        }
      }

      // Object validation
      if (schema.type === 'object') {
        return this.validateObject(value, schema);
      }

      return { valid: true };
    } catch (error) {
      this.handleError('Failed to validate property', error);
      return { valid: false, error: error.message };
    }
  }

  /**
   * Auto-detect schema type from data
   * @param {*} data - Data to analyze
   * @returns {string|null} Detected schema type or null
   */
  detectSchemaType(data) {
    try {
      if (!data || !data.metadata || !data.metadata.fileType) {
        return null;
      }

      const fileType = data.metadata.fileType;
      if (this.schemas.has(fileType)) {
        return fileType;
      }

      // Try to guess from structure
      if (data.progress && data.progress.kataId) {
        return 'kata-progress';
      }
      if (data.progress && data.progress.labId) {
        return 'lab-progress';
      }
      if (data.assessment && data.assessment.responses) {
        return 'self-assessment';
      }
      if (data.formData && data.progressStats) {
        return 'form-progress';
      }

      return null;
    } catch (error) {
      this.handleError('Failed to detect schema type', error);
      return null;
    }
  }

  /**
   * Validate with auto-detection
   * @param {*} data - Data to validate
   * @returns {Object} Validation result
   */
  validateAuto(data) {
    try {
      const schemaType = this.detectSchemaType(data);
      if (!schemaType) {
        return { valid: false, error: 'Unable to detect schema type' };
      }

      return this.validate(data, schemaType);
    } catch (error) {
      this.handleError('Failed to auto-validate data', error);
      return { valid: false, error: error.message };
    }
  }

  /**
   * Get validation summary for all schemas
   * @returns {Object} Summary of all schemas
   */
  getValidationSummary() {
    try {
      const summary = {};
      for (const [type, schema] of this.schemas) {
        summary[type] = {
          required: schema.required || [],
          properties: Object.keys(schema.properties || {}),
          description: this.getSchemaDescription(type)
        };
      }
      return summary;
    } catch (error) {
      this.handleError('Failed to get validation summary', error);
      return {};
    }
  }

  /**
   * Get schema description
   * @param {string} type - Schema type identifier
   * @returns {string} Schema description
   */
  getSchemaDescription(type) {
    try {
      const descriptions = {
        'kata-progress': 'Progress tracking for individual kata exercises',
        'lab-progress': 'Progress tracking for training lab exercises',
        'self-assessment': 'Self-assessment questionnaire responses and analysis',
        'form-progress': 'General form completion progress tracking'
      };

      return descriptions[type] || 'Custom schema';
    } catch (error) {
      this.handleError('Failed to get schema description', error);
      return 'Unknown schema';
    }
  }

  /**
   * Normalize data to match schema requirements
   * @param {*} data - Data to normalize
   * @param {string} schemaType - Schema type identifier
   * @returns {*} Normalized data
   */
  normalizeData(data, schemaType) {
    try {
      const schema = this.getSchema(schemaType);
      if (!schema) {
        return data;
      }

      const normalized = { ...data };

      // Ensure required fields exist
      if (schema.required) {
        for (const field of schema.required) {
          if (!(field in normalized)) {
            if (field === 'timestamp') {
              normalized[field] = new Date().toISOString();
            } else if (field === 'metadata') {
              normalized[field] = {
                fileType: schemaType,
                lastUpdateSource: 'system',
                version: '1.0.0'
              };
            }
          }
        }
      }

      // Normalize metadata
      if (normalized.metadata) {
        normalized.metadata.fileType = schemaType;
        if (!normalized.metadata.lastUpdateTimestamp) {
          normalized.metadata.lastUpdateTimestamp = new Date().toISOString();
        }
        if (!normalized.metadata.version) {
          normalized.metadata.version = '1.0.0';
        }
      }

      this.logDebug(`Data normalized for schema type: ${schemaType}`);
      return normalized;
    } catch (error) {
      this.handleError('Failed to normalize data', error);
      return data;
    }
  }

  /**
   * Get available schema types
   * @returns {string[]} Array of schema type identifiers
   */
  getSchemaTypes() {
    try {
      return Array.from(this.schemas.keys());
    } catch (error) {
      this.handleError('Failed to get schema types', error);
      return [];
    }
  }

  /**
   * Check if schema type is supported
   * @param {string} type - Schema type identifier
   * @returns {boolean} True if schema exists
   */
  hasSchema(type) {
    try {
      return this.schemas.has(type);
    } catch (error) {
      this.handleError('Failed to check schema existence', error);
      return false;
    }
  }
}

// Browser Global Export
if (typeof window !== 'undefined') {
  window.UnifiedProgressSchemaValidator = UnifiedProgressSchemaValidator;
}

// Module export for testing environments
if (typeof module !== 'undefined' && module.exports) {
  module.exports = UnifiedProgressSchemaValidator;
}
