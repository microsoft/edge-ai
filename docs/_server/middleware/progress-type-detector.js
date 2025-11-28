import { detectProgressType } from '../schemas/index.js';
import { extractMetadataSummary } from '../utils/schema-validator.js';

/**
 * Middleware to detect progress type from request data
 * @param {Object} options - Detection options
 * @param {boolean} [options.required] - Whether progress type detection is required
 * @param {boolean} [options.attachMetadata] - Whether to attach metadata summary
 * @param {Array<string>} [options.allowedTypes] - Allowed progress types
 * @returns {Function} Express middleware function
 */
function progressTypeDetector(options = {}) {
  const {
    required = true,
    attachMetadata = true,
    allowedTypes = ['self-assessment', 'kata-progress', 'lab-progress']
  } = options;

  return (req, res, next) => {
    const progressData = req.body;

    // Skip if no data and not required
    if (!progressData) {
      if (required) {
        return res.status(400).json({
          success: false,
          error: 'No progress data provided',
          details: 'Request body is required for progress type detection'
        });
      }
      return next();
    }

    // Detect progress type
    const progressType = detectProgressType(progressData);

    if (!progressType) {
      if (required) {
        return res.status(400).json({
          success: false,
          error: 'Unable to determine progress type',
          details: {
            message: 'Progress data does not match any known schema patterns',
            allowedTypes,
            receivedData: {
              hasMetadata: !!(progressData.metadata),
              topLevelKeys: Object.keys(progressData),
              metadataKeys: progressData.metadata ? Object.keys(progressData.metadata) : []
            }
          }
        });
      }
    }

    // Check if type is allowed
    if (progressType && !allowedTypes.includes(progressType)) {
      return res.status(400).json({
        success: false,
        error: 'Progress type not allowed',
        details: {
          detectedType: progressType,
          allowedTypes,
          message: `Progress type '${progressType}' is not allowed for this endpoint`
        }
      });
    }

    // Attach progress type to request
    req.progressType = progressType;

    // Attach metadata summary if requested
    if (attachMetadata && progressType) {
      try {
        req.progressMetadata = extractMetadataSummary(progressData, progressType);
      } catch (error) {
        // Log error but don't fail the request
        console.warn('Failed to extract metadata summary:', error.message);
        req.progressMetadata = {
          type: progressType,
          title: 'Unknown',
          id: 'unknown',
          category: 'unknown'
        };
      }
    }

    next();
  };
}

/**
 * Middleware to enforce specific progress type
 * @param {string} expectedType - Expected progress type
 * @param {Object} options - Enforcement options
 * @returns {Function} Express middleware function
 */
function enforceProgressType(expectedType, options = {}) {
  const { strict = true } = options;

  return (req, res, next) => {
    const progressData = req.body;

    if (!progressData) {
      return res.status(400).json({
        success: false,
        error: 'No progress data provided',
        details: `Request body is required for ${expectedType} processing`
      });
    }

    const detectedType = detectProgressType(progressData);

    if (!detectedType) {
      return res.status(400).json({
        success: false,
        error: 'Unable to determine progress type',
        details: {
          expected: expectedType,
          message: 'Progress data does not match any known schema patterns'
        }
      });
    }

    if (detectedType !== expectedType) {
      const statusCode = strict ? 400 : 422;

      return res.status(statusCode).json({
        success: false,
        error: 'Progress type mismatch',
        details: {
          expected: expectedType,
          detected: detectedType,
          message: `Expected ${expectedType} but received ${detectedType}`
        }
      });
    }

    // Attach confirmed type to request
    req.progressType = detectedType;
    req.confirmedType = expectedType;

    next();
  };
}

/**
 * Middleware to handle progress type routing
 * @param {Object} typeHandlers - Map of progress types to handler functions
 * @param {Object} options - Routing options
 * @returns {Function} Express middleware function
 */
function routeByProgressType(typeHandlers, options = {}) {
  const { defaultHandler = null, strict = true } = options;

  return (req, res, next) => {
    const progressType = req.progressType;

    if (!progressType) {
      if (strict) {
        return res.status(400).json({
          success: false,
          error: 'No progress type detected',
          details: 'Progress type must be detected before routing'
        });
      }

      if (defaultHandler) {
        return defaultHandler(req, res, next);
      }

      return next();
    }

    const handler = typeHandlers[progressType];

    if (!handler) {
      if (strict) {
        return res.status(400).json({
          success: false,
          error: 'No handler for progress type',
          details: {
            type: progressType,
            availableTypes: Object.keys(typeHandlers)
          }
        });
      }

      if (defaultHandler) {
        return defaultHandler(req, res, next);
      }

      return next();
    }

    // Call the specific handler
    handler(req, res, next);
  };
}

/**
 * Middleware to add progress type information to response
 * @param {Object} options - Response options
 * @returns {Function} Express middleware function
 */
function addProgressTypeInfo(options = {}) {
  const { includePatterns = false, includeSchema = false } = options;

  return async (req, res, next) => {
    const progressType = req.progressType;
    const progressMetadata = req.progressMetadata;

    if (progressType) {
      // Add type information to response locals
      res.locals.progressType = progressType;
      res.locals.progressMetadata = progressMetadata;

      if (includePatterns) {
        const { PROGRESS_TYPE_PATTERNS } = await import('../schemas/index.js');
        res.locals.progressPatterns = PROGRESS_TYPE_PATTERNS[progressType];
      }

      if (includeSchema) {
        const { getSchemaPath } = await import('../schemas/index.js');
        res.locals.schemaPath = getSchemaPath(progressType);
      }
    }

    next();
  };
}

export {
  progressTypeDetector,
  enforceProgressType,
  routeByProgressType,
  addProgressTypeInfo
};
