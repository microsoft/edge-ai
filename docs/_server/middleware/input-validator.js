/**
 * Input Validation Middleware
 * Provides comprehensive input validation and sanitization
 */

import Ajv from 'ajv';
import addFormats from 'ajv-formats';
import {
  progressDataSchema,
  parameterSchemas,
  querySchemas,
  securityPatterns,
  fieldLimits
} from '../schemas/request-schemas.js';

const ajv = new Ajv({ allErrors: true, removeAdditional: true });
addFormats(ajv);

// Compile schemas for better performance
const progressValidator = ajv.compile(progressDataSchema);

/**
 * Sanitize input string by removing dangerous content
 */
export function sanitizeInput(input, maxLength = fieldLimits.mediumString) {
  if (input === null || input === undefined) {
    return '';
  }

  // Convert to string
  let sanitized = String(input);

  // Remove dangerous patterns
  sanitized = sanitized.replace(securityPatterns.scriptTags, '');
  sanitized = sanitized.replace(securityPatterns.htmlTags, '');
  sanitized = sanitized.replace(securityPatterns.nullBytes, '');
  sanitized = sanitized.replace(securityPatterns.controlChars, '');

  // Trim whitespace
  sanitized = sanitized.trim();

  // Limit length
  if (sanitized.length > maxLength) {
    sanitized = sanitized.substring(0, maxLength);
  }

  return sanitized;
}

/**
 * Check for dangerous patterns in input
 */
function containsDangerousPatterns(input) {
  if (typeof input !== 'string') {
    return false;
  }

  return (
    securityPatterns.sqlInjection.test(input) ||
    securityPatterns.commandInjection.test(input) ||
    securityPatterns.pathTraversal.test(input) ||
    securityPatterns.nullBytes.test(input)
  );
}

/**
 * Validate and sanitize object recursively
 */
function sanitizeObject(obj, depth = 0) {
  if (depth > 10) { // Prevent deep recursion attacks
    throw new Error('Object nesting too deep');
  }

  if (obj === null || obj === undefined) {
    return obj;
  }

  if (Array.isArray(obj)) {
    if (obj.length > fieldLimits.largeArray) {
      throw new Error(`Array exceeds maximum length of ${fieldLimits.largeArray}`);
    }
    return obj.map(item => sanitizeObject(item, depth + 1));
  }

  if (typeof obj === 'object') {
    const sanitized = {};
    for (const [key, value] of Object.entries(obj)) {
      const sanitizedKey = sanitizeInput(key, fieldLimits.shortString);

      if (containsDangerousPatterns(sanitizedKey)) {
        throw new Error(`Invalid characters detected in key: ${key}`);
      }

      sanitized[sanitizedKey] = sanitizeObject(value, depth + 1);
    }
    return sanitized;
  }

  if (typeof obj === 'string') {
    if (containsDangerousPatterns(obj)) {
      throw new Error(`Invalid characters detected in value: ${obj.substring(0, 50)}...`);
    }
    return sanitizeInput(obj);
  }

  return obj;
}

/**
 * Validate parameter against schema
 */
function validateParameter(value, schema) {
  const validator = ajv.compile(schema);
  return validator(value);
}

/**
 * General input validation middleware
 */
export function inputValidator(options = {}) {
  const {
    sanitizeBody = false,
    sanitizeParams = false,
    sanitizeQuery = false,
    bodyFields = [],
    paramFields = [],
    queryFields = [],
    maxLength = fieldLimits.mediumString
  } = options;

  return (req, res, next) => {
    try {
      // Sanitize entire request body if requested
      if (sanitizeBody && req.body) {
        req.body = sanitizeObject(req.body);
      }

      // Sanitize specific body fields if specified
      if (bodyFields.length > 0 && req.body) {
        for (const field of bodyFields) {
          if (req.body[field] !== undefined) {
            if (typeof req.body[field] === 'string' && req.body[field].length > maxLength) {
              req.body[field] = req.body[field].substring(0, maxLength);
            }
            req.body[field] = sanitizeInput(req.body[field], maxLength);
          }
        }
      }

      // Sanitize all parameters if requested
      if (sanitizeParams && req.params) {
        for (const [param, value] of Object.entries(req.params)) {
          // Check for dangerous patterns
          if (containsDangerousPatterns(value)) {
            return res.status(400).json({
              success: false,
              error: 'Invalid input',
              message: 'Parameter validation failed'
            });
          }

          // Validate against appropriate schema
          let schema = parameterSchemas.genericId;
          if (param === 'type') {
            schema = parameterSchemas.progressType;
          } else if (param === 'id') {
            schema = parameterSchemas.progressId;
          }

          if (!validateParameter(value, schema)) {
            return res.status(400).json({
              success: false,
              error: 'Invalid input',
              message: 'Parameter validation failed'
            });
          }

          req.params[param] = sanitizeInput(value, fieldLimits.shortString);
        }
      }

      // Sanitize specific parameter fields if specified
      if (paramFields.length > 0 && req.params) {
        for (const param of paramFields) {
          if (req.params[param] !== undefined) {
            const value = req.params[param];

            // Check for path traversal and dangerous patterns
            if (containsDangerousPatterns(value)) {
              return res.status(400).json({
                success: false,
                error: 'Invalid input',
                message: 'Parameter validation failed'
              });
            }

            // Validate against appropriate schema
            let schema = parameterSchemas.genericId;
            if (param === 'type') {
              schema = parameterSchemas.progressType;
            } else if (param === 'id') {
              schema = parameterSchemas.progressId;
            }

            if (!validateParameter(value, schema)) {
              return res.status(400).json({
                success: false,
                error: 'Invalid input',
                message: 'Parameter validation failed'
              });
            }

            req.params[param] = sanitizeInput(value, fieldLimits.shortString);
          }
        }
      }

      // Sanitize all query parameters if requested
      if (sanitizeQuery && req.query) {
        for (const [queryParam, value] of Object.entries(req.query)) {
          if (containsDangerousPatterns(value)) {
            return res.status(400).json({
              success: false,
              error: 'Invalid input',
              message: 'Query parameter validation failed'
            });
          }

          // Validate against schema if available
          if (querySchemas[queryParam]) {
            if (!validateParameter(value, querySchemas[queryParam])) {
              return res.status(400).json({
                success: false,
                error: 'Invalid input',
                message: `Invalid query parameter: ${queryParam}`
              });
            }
          }

          req.query[queryParam] = sanitizeInput(value, fieldLimits.shortString);
        }
      }

      // Sanitize specific query fields if specified
      if (queryFields.length > 0 && req.query) {
        for (const queryParam of queryFields) {
          if (req.query[queryParam] !== undefined) {
            const value = req.query[queryParam];

            if (containsDangerousPatterns(value)) {
              return res.status(400).json({
                success: false,
                error: 'Invalid input',
                message: 'Query parameter validation failed'
              });
            }

            // Validate against schema if available
            if (querySchemas[queryParam]) {
              if (!validateParameter(value, querySchemas[queryParam])) {
                return res.status(400).json({
                  success: false,
                  error: 'Invalid input',
                  message: `Invalid query parameter: ${queryParam}`
                });
              }
            }

            req.query[queryParam] = sanitizeInput(value, fieldLimits.shortString);
          }
        }
      }

      next();
    } catch (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        message: error.message
      });
    }
  };
}

/**
 * Specific middleware for progress data validation
 */
export function validateProgressData() {
  return (req, res, next) => {
    try {
      // Check content type
      if (!req.is('application/json')) {
        return res.status(400).json({
          success: false,
          error: 'Invalid content type',
          message: 'Content-Type must be application/json'
        });
      }

      // Check payload size (rough estimate)
      const payloadSize = JSON.stringify(req.body).length;
      if (payloadSize > 50000) { // 50KB limit
        return res.status(400).json({
          success: false,
          error: 'Validation failed',
          message: 'Payload exceeds maximum size limit'
        });
      }

      // Sanitize the entire request body
      req.body = sanitizeObject(req.body);

      // Validate against schema
      const isValid = progressValidator(req.body);
      if (!isValid) {
        const errors = progressValidator.errors.map(error => ({
          field: error.instancePath || error.schemaPath,
          message: error.message,
          value: error.data
        }));

        return res.status(400).json({
          success: false,
          error: 'Validation failed',
          message: 'Request data does not match required schema',
          details: errors
        });
      }

      // Type-specific validation happens later in the middleware chain
      // after transformation (via validation.js using file schemas)

      next();
    } catch (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        message: error.message
      });
    }
  };
}

/**
 * Rate limiting validation (placeholder for future implementation)
 */
export function rateLimitValidator() {
  return (req, res, next) => {
    // For now, just pass through
    // In production, this would implement actual rate limiting
    next();
  };
}
