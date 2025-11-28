import { validateProgress, detectProgressType, getAvailableSchemaTypes, PROGRESS_TYPE_PATTERNS } from '../schemas/index.js';

/**
 * Utility functions for schema validation and progress data processing
 */

/**
 * Validate and sanitize progress data
 * @param {Object} data - Progress data to validate
 * @param {Object} options - Validation options
 * @returns {Object} Sanitized and validated data
 */
async function validateAndSanitizeProgress(data, options = {}) {
  const {
    forceType,
    allowPartial = false,
    sanitize = true,
    addTimestamp = true
  } = options;

  // Clone the data to avoid mutation
  const sanitizedData = JSON.parse(JSON.stringify(data));

  if (sanitize) {
    // Remove the type field as it's not part of the file schema
    if (sanitizedData.type) {
      delete sanitizedData.type;
    }

    // Transform progress structure for file storage
    if (sanitizedData.progress) {
      // Convert currentStep from integer to string if needed
      if (typeof sanitizedData.progress.currentStep === 'number') {
        sanitizedData.progress.currentStep = `task-${sanitizedData.progress.currentStep}`;
      }

      // Ensure checkboxStates exists for kata-progress
      if (!sanitizedData.progress.checkboxStates && sanitizedData.metadata && sanitizedData.metadata.fileType === 'kata-progress') {
        sanitizedData.progress.checkboxStates = {};
      }
    }

    // Preserve assessment data for self-assessment types
    // Assessment data should not be modified during sanitization

    // Add timestamp if not present and requested (do this BEFORE validation)
    if (addTimestamp && !sanitizedData.timestamp) {
      sanitizedData.timestamp = new Date().toISOString();
    }

    // Ensure metadata has required fields
    if (!sanitizedData.metadata) {
      sanitizedData.metadata = {};
    }

    // Transform metadata from input format to file format
    if (sanitizedData.metadata.title && !sanitizedData.metadata.kataTitle) {
      sanitizedData.metadata.kataTitle = sanitizedData.metadata.title;
      delete sanitizedData.metadata.title;
    }

    // Add schema version if not present
    if (!sanitizedData.metadata.version) {
      sanitizedData.metadata.version = '1.0.0';
    }

    // Add file type if not present (detect it first)
    if (!sanitizedData.metadata.fileType) {
      const detectedType = detectProgressType(sanitizedData);
      sanitizedData.metadata.fileType = detectedType || 'self-assessment';
    }

    // Add source if not present
    if (!sanitizedData.metadata.source) {
      sanitizedData.metadata.source = 'server';
    }
  }

  // Validate the sanitized data
  const validationResult = await validateProgress(sanitizedData, forceType);

  if (!validationResult.valid && !allowPartial) {
    // Log detailed validation errors for debugging
    console.error('Validation failed for type:', validationResult.type);
    console.error('Input data:', JSON.stringify(sanitizedData, null, 2));
    console.error('Validation errors:', JSON.stringify(validationResult.errors, null, 2));

    const error = new Error('Progress data validation failed');
    error.type = 'validation';
    error.details = {
      type: validationResult.type,
      errors: validationResult.errors
    };
    throw error;
  }

  return {
    data: sanitizedData,
    type: validationResult.type,
    validation: validationResult
  };
}

/**
 * Generate filename for progress data
 * @param {Object} data - Progress data
 * @param {string} type - Progress type
 * @returns {string} Generated filename
 */
function generateProgressFilename(data, type) {
  if (!data || !data.metadata) {
    throw new Error('Progress data must have metadata for filename generation');
  }

  const metadata = data.metadata;

  let identifier;

  switch (type) {
    case 'self-assessment':
      identifier = metadata.assessmentId || 'unknown-assessment';
      break;
    case 'kata':
    case 'kata-progress':
      identifier = metadata.kataId || 'unknown-kata';
      break;
    case 'lab':
    case 'lab-progress':
      identifier = metadata.labId || 'unknown-lab';
      break;
    case 'path':
    case 'path-progress':
      identifier = metadata.pathId || 'unknown-path';
      break;
    default:
      identifier = 'unknown-progress';
  }

  return `${identifier}.json`;
}

/**
 * Extract metadata summary from progress data
 * @param {Object} data - Progress data
 * @param {string} type - Progress type
 * @returns {Object} Metadata summary
 */
function extractMetadataSummary(data, type) {
  if (!data || !data.metadata) {
    return {
      type,
      title: type === 'self-assessment' ? 'Self Assessment' : 'Unknown',
      id: 'unknown'
    };
  }

  const metadata = data.metadata;

  switch (type) {
    case 'self-assessment':
      return {
        type: 'self-assessment',
        title: metadata.assessmentTitle || 'Self Assessment',
        id: metadata.assessmentId || 'unknown-assessment',
        category: metadata.assessmentType || 'general'
      };
    case 'kata-progress':
      return {
        type: 'kata-progress',
        title: metadata.kataTitle || 'Kata Progress',
        id: metadata.kataId || 'unknown-kata',
        category: metadata.category || 'general'
      };
    case 'lab-progress':
      return {
        type: 'lab-progress',
        title: metadata.labTitle || 'Lab Progress',
        id: metadata.labId || 'unknown-lab',
        category: metadata.category || 'general'
      };
    default:
      return {
        type: 'unknown',
        title: 'Unknown Progress',
        id: 'unknown',
        category: 'unknown'
      };
  }
}

/**
 * Validate progress data completion
 * @param {Object} data - Progress data
 * @param {string} type - Progress type
 * @returns {Object} Completion status
 */
function validateProgressCompletion(data, type) {
  if (!data) {
    return { complete: false, percentage: 0, missing: ['data'] };
  }

  const missing = [];
  let totalFields = 0;
  let completedFields = 0;

  switch (type) {
    case 'self-assessment':
      if (!data.assessment) {
        missing.push('assessment');
      } else {
        totalFields = Object.keys(data.assessment.responses || {}).length;
        completedFields = Object.values(data.assessment.responses || {}).filter(v => v !== null && v !== undefined).length;
      }
      break;
    case 'kata-progress':
      if (!data.progress) {
        missing.push('progress');
      } else {
        totalFields = Object.keys(data.progress.checkpoints || {}).length;
        completedFields = Object.values(data.progress.checkpoints || {}).filter(v => v === true).length;
      }
      break;
    case 'lab-progress':
      if (!data.progress) {
        missing.push('progress');
      } else {
        totalFields = Object.keys(data.progress.steps || {}).length;
        completedFields = Object.values(data.progress.steps || {}).filter(v => v === true).length;
      }
      break;
    default:
      return { complete: false, percentage: 0, missing: ['unknown-type'] };
  }

  const percentage = totalFields > 0 ? Math.round((completedFields / totalFields) * 100) : 0;
  const complete = percentage === 100 && missing.length === 0;

  return {
    complete,
    percentage,
    missing,
    totalFields,
    completedFields
  };
}

/**
 * Create validation summary for multiple progress files
 * @param {Array} progressFiles - Array of progress file data
 * @returns {Object} Validation summary
 */
function createValidationSummary(progressFiles) {
  const summary = {
    total: progressFiles.length,
    valid: 0,
    invalid: 0,
    types: {},
    errors: []
  };

  progressFiles.forEach((file, index) => {
    try {
      const validationResult = validateProgress(file);

      if (validationResult.valid) {
        summary.valid++;

        if (!summary.types[validationResult.type]) {
          summary.types[validationResult.type] = 0;
        }
        summary.types[validationResult.type]++;
      } else {
        summary.invalid++;
        summary.errors.push({
          index,
          type: validationResult.type,
          errors: validationResult.errors
        });
      }
    } catch (error) {
      summary.invalid++;
      summary.errors.push({
        index,
        type: 'unknown',
        errors: [`Validation error: ${error.message}`]
      });
    }
  });

  return summary;
}

/**
 * Get supported schema types with descriptions
 * @returns {Array} Array of schema type information
 */
function getSupportedSchemaTypes() {
  const types = getAvailableSchemaTypes();

  return types.map(type => ({
    type,
    description: getSchemaDescription(type),
    patterns: getSchemaPatterns(type)
  }));
}

/**
 * Get description for a schema type
 * @param {string} type - Schema type
 * @returns {string} Description
 */
function getSchemaDescription(type) {
  const descriptions = {
    'self-assessment': 'Self-assessment progress tracking for skill evaluations',
    'kata-progress': 'Kata progress tracking for coding exercises and challenges',
    'lab-progress': 'Lab progress tracking for hands-on training exercises'
  };

  return descriptions[type] || 'Unknown progress type';
}

/**
 * Get schema patterns for a type
 * @param {string} type - Schema type
 * @returns {Object} Schema patterns
 */
function getSchemaPatterns(type) {
  return PROGRESS_TYPE_PATTERNS[type] || {};
}

export {
  validateAndSanitizeProgress,
  generateProgressFilename,
  extractMetadataSummary,
  validateProgressCompletion,
  createValidationSummary,
  getSupportedSchemaTypes,
  getSchemaDescription,
  getSchemaPatterns
};
