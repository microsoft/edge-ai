import { validateProgress, detectProgressType } from '../schemas/index.js';

/**
 * Middleware to validate progress data against appropriate JSON schema
 * @param {Object} options - Validation options
 * @param {string} [options.forceType] - Force a specific progress type
 * @param {boolean} [options.allowPartial] - Allow partial data validation
 * @param {boolean} [options.strict] - Enable strict validation mode
 * @returns {Function} Express middleware function
 */
function validateProgressData(options = {}) {
  const { forceType, strict = true } = options;

  return async (req, res, _next) => {
    // Extract progress data from request body
    const progressData = req.body;

    // Skip validation if no data provided
    if (!progressData) {
      return res.status(400).json({
        success: false,
        error: 'No progress data provided',
        details: 'Request body is required for progress validation'
      });
    }

    try {
      // Validate the progress data (async)
      const validationResult = await validateProgress(progressData, forceType);

      if (!validationResult.valid) {
        const statusCode = strict ? 400 : 422;

        return res.status(statusCode).json({
          success: false,
          error: 'Progress data validation failed',
          details: {
            type: validationResult.type,
            errors: validationResult.errors,
            timestamp: new Date().toISOString()
          },
          validationErrors: validationResult.errors // Add this for easier debugging
        });
      }

      // Attach validation results to request for downstream use
      req.validatedProgress = {
        data: progressData,
        type: validationResult.type,
        validation: validationResult
      };

      _next();
    } catch(_error) {
      return res.status(500).json({
        success: false,
        error: 'Validation error',
        details: {
          message: _error.message,
          timestamp: new Date().toISOString()
        }
      });
    }
  };
}

/**
 * Middleware to detect and attach progress type to request
 * @param {Object} options - Detection options
 * @param {boolean} [options.required] - Whether progress type detection is required
 * @returns {Function} Express middleware function
 */
function detectProgressTypeMiddleware(options = {}) {
  const { required = true } = options;

  return (req, res, _next) => {
    const progressData = req.body;

    if (!progressData) {
      if (required) {
        return res.status(400).json({
          success: false,
          error: 'No progress data provided for type detection',
          details: 'Request body is required for progress type detection'
        });
      }
      return _next();
    }

    const progressType = detectProgressType(progressData);

    if (!progressType) {
      if (required) {
        return res.status(400).json({
          success: false,
          error: 'Unable to determine progress type',
          details: 'Progress data does not match any known schema patterns'
        });
      }
    }

    // Attach progress type to request
    req.progressType = progressType;
    _next();
  };
}

/**
 * Middleware to validate specific progress type
 * @param {string} expectedType - Expected progress type
 * @param {Object} options - Validation options
 * @returns {Function} Express middleware function
 */
function validateSpecificProgressType(expectedType, options = {}) {
  const { strict = true } = options;

  return async (req, res, _next) => {
    const progressData = req.body;

    if (!progressData) {
      return res.status(400).json({
        success: false,
        error: 'No progress data provided',
        details: `Request body is required for ${expectedType} validation`
      });
    }

    try {
      // Validate against specific type (async)
      const validationResult = await validateProgress(progressData, expectedType);

      if (!validationResult.valid) {
        const statusCode = strict ? 400 : 422;

        return res.status(statusCode).json({
          success: false,
          error: `${expectedType} validation failed`,
          details: {
            type: validationResult.type,
            errors: validationResult.errors,
            timestamp: new Date().toISOString()
          }
        });
      }

      // Ensure type matches expected
      if (validationResult.type !== expectedType) {
        return res.status(400).json({
          success: false,
          error: 'Progress type mismatch',
          details: {
            expected: expectedType,
            detected: validationResult.type,
            timestamp: new Date().toISOString()
          }
        });
      }

      // Attach validation results to request
      req.validatedProgress = {
        data: progressData,
        type: validationResult.type,
        validation: validationResult
      };

      _next();
    } catch(_error) {
      return res.status(500).json({
        success: false,
        error: 'Validation error',
        details: {
          message: _error.message,
          timestamp: new Date().toISOString()
        }
      });
    }
  };
}

/**
 * Error handler for validation middleware
 * @param {Error} err - Error object
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Next middleware function
 */
function validationErrorHandler(err, req, res, next) {
  // Handle validation-specific errors
  if (err.name === 'ValidationError' || err.type === 'validation') {
    return res.status(400).json({
      success: false,
      error: 'Validation error',
      details: {
        message: err.message,
        stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
        timestamp: new Date().toISOString()
      }
    });
  }

  // Handle schema loading errors
  if (err.message && err.message.includes('schema')) {
    return res.status(500).json({
      success: false,
      error: 'Schema error',
      details: {
        message: err.message,
        timestamp: new Date().toISOString()
      }
    });
  }

  // Pass to next error handler
  next(err);
}

export {
  validateProgressData,
  detectProgressTypeMiddleware,
  validateSpecificProgressType,
  validationErrorHandler
};
