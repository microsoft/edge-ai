import Ajv from 'ajv';
import addFormats from 'ajv-formats';
import path from 'path';
import fs from 'fs/promises';
import { fileURLToPath } from 'url';

// Get current directory for ES6 modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize AJV with strict mode and formats
const ajv = new Ajv({
  allErrors: true,
  verbose: true,
  strict: true,
  strictTypes: true,
  strictTuples: true,
  allowUnionTypes: false,
  validateFormats: true,
  removeAdditional: false,
  strictSchema: false, // Allow schema keywords like "example"
  formats: {
    'date-time': true,
    'email': true,
    'uri': true,
    'uuid': true
  }
});

// Add format validation
addFormats(ajv);

// Schema cache for performance
const schemaCache = new Map();

// Schema file paths
const SCHEMA_PATHS = {
  'self-assessment': path.join(__dirname, 'self-assessment-schema.json'),
  'kata-progress': path.join(__dirname, 'kata-progress-schema.json'),
  'lab-progress': path.join(__dirname, 'lab-progress-schema.json'),
  'learning-path-save-request': path.join(__dirname, 'learning-path-save-request-schema.json'),
  'learning-path-manifest': path.join(__dirname, 'learning-path-manifest-schema.json')
};

// Progress type detection patterns
const PROGRESS_TYPE_PATTERNS = {
  'self-assessment': {
    requiredFields: ['metadata', 'assessment', 'timestamp'],
    metadataIdField: 'assessmentId',
    idPattern: /^[a-z0-9-]+$/
  },
  'kata-progress': {
    requiredFields: ['metadata', 'progress', 'timestamp'],
    metadataIdField: 'kataId',
    idPattern: /^[a-z0-9-]+$/
  },
  'lab-progress': {
    requiredFields: ['metadata', 'progress', 'timestamp'],
    metadataIdField: 'labId',
    idPattern: /^[a-z0-9-]+-[a-z0-9-]+$/
  }
};

/**
 * Load and compile a schema by type
 * @param {string} schemaType - Type of schema ('self-assessment', 'kata-progress', 'lab-progress')
 * @returns {Promise<Object>} Compiled AJV validator
 */
async function loadSchema(schemaType) {
  if (schemaCache.has(schemaType)) {
    return schemaCache.get(schemaType);
  }

  const schemaPath = SCHEMA_PATHS[schemaType];
  if (!schemaPath) {
    throw new Error(`Unknown schema type: ${schemaType}`);
  }

  try {
    // Check if file exists asynchronously
    await fs.access(schemaPath);
  } catch {
    throw new Error(`Schema file not found: ${schemaPath}`);
  }

  try {
    const schemaContent = await fs.readFile(schemaPath, 'utf8');
    const schema = JSON.parse(schemaContent);

    // Remove the $id from the schema to avoid conflicts during concurrent tests
    const schemaForCompilation = { ...schema };
    delete schemaForCompilation.$id;

    // Compile the schema
    const validate = ajv.compile(schemaForCompilation);

    // Cache the compiled validator
    schemaCache.set(schemaType, validate);

    return validate;
  } catch (error) {
    // If it's a "schema already exists" error, try to get the existing schema
    if (error.message.includes('already exists')) {
      // Clear the cache for this type and try again with a new AJV instance
      schemaCache.delete(schemaType);

      try {
        const schemaContent = await fs.readFile(schemaPath, 'utf8');
        const schema = JSON.parse(schemaContent);

        // Create a fresh schema without $id
        const schemaForCompilation = { ...schema };
        delete schemaForCompilation.$id;

        // Create a new AJV instance for this schema
        const freshAjv = new Ajv({
          allErrors: true,
          verbose: true,
          strict: true,
          strictTypes: true,
          strictTuples: true,
          allowUnionTypes: false,
          validateFormats: true,
          removeAdditional: false,
          strictSchema: false
        });
        addFormats(freshAjv);

        const validate = freshAjv.compile(schemaForCompilation);
        schemaCache.set(schemaType, validate);
        return validate;
      } catch (retryError) {
        throw new Error(`Failed to load schema ${schemaType} after retry: ${retryError.message}`);
      }
    }
    throw new Error(`Failed to load schema ${schemaType}: ${error.message}`);
  }
}

/**
 * Detect the progress type from data structure
 * @param {Object} data - Progress data to analyze
 * @returns {string|null} Detected progress type or null
 */
function detectProgressType(data) {
  if (!data || typeof data !== 'object') {
    console.log(`[DetectProgressType] Invalid data type:`, typeof data);
    return null;
  }

  console.log(`[DetectProgressType] Analyzing data:`, {
    topLevelKeys: Object.keys(data),
    hasMetadata: !!data.metadata,
    metadataKeys: data.metadata ? Object.keys(data.metadata) : []
  });

  // Check for required top-level fields and metadata structure
  for (const [type, pattern] of Object.entries(PROGRESS_TYPE_PATTERNS)) {
    const { requiredFields, metadataIdField, idPattern } = pattern;

    console.log(`[DetectProgressType] Checking type: ${type}`, {
      requiredFields,
      metadataIdField,
      pattern: idPattern.toString()
    });

    // Check if all required fields are present
    const hasRequiredFields = requiredFields.every(field =>
      Object.prototype.hasOwnProperty.call(data, field) && data[field] !== null && data[field] !== undefined
    );

    console.log(`[DetectProgressType] Required fields check for ${type}:`, {
      hasRequiredFields,
      fieldChecks: requiredFields.map(field => ({
        field,
        exists: Object.prototype.hasOwnProperty.call(data, field),
        notNull: data[field] !== null,
        notUndefined: data[field] !== undefined
      }))
    });

    if (!hasRequiredFields) {
      continue;
    }

    // Check metadata structure
    const metadata = data.metadata;
    if (!metadata || typeof metadata !== 'object') {
      console.log(`[DetectProgressType] Invalid metadata for ${type}:`, {
        hasMetadata: !!metadata,
        metadataType: typeof metadata
      });
      continue;
    }

    // Check if the metadata ID field exists and matches the pattern
    const idValue = metadata[metadataIdField];
    console.log(`[DetectProgressType] ID field check for ${type}:`, {
      metadataIdField,
      idValue,
      idValueType: typeof idValue,
      patternMatch: idValue && typeof idValue === 'string' ? idPattern.test(idValue) : false
    });

    if (idValue && typeof idValue === 'string' && idPattern.test(idValue)) {
      console.log(`[DetectProgressType] Successfully detected type: ${type}`);
      return type;
    }
  }

  console.log(`[DetectProgressType] No type detected, returning null`);
  return null;
}

/**
 * Validate progress data against its schema
 * @param {Object} data - Progress data to validate
 * @param {string} [forceType] - Force a specific progress type instead of auto-detection
 * @returns {Promise<Object>} Validation result { valid: boolean, errors: Array, type: string }
 */
async function validateProgress(data, forceType = null) {
  try {
    // Determine progress type
    const progressType = forceType || detectProgressType(data);

    if (!progressType) {
      return {
        valid: false,
        errors: ['Unable to determine progress type from data structure'],
        type: null
      };
    }

    // Load appropriate schema validator
    const validate = await loadSchema(progressType);

    // Validate the data
    const valid = validate(data);

    return {
      valid,
      errors: valid ? [] : validate.errors.map(err => ({
        instancePath: err.instancePath,
        schemaPath: err.schemaPath,
        keyword: err.keyword,
        message: err.message,
        params: err.params
      })),
      type: progressType
    };
  } catch (error) {
    return {
      valid: false,
      errors: [`Schema validation error: ${error.message}`],
      type: null
    };
  }
}

/**
 * Get all available schema types
 * @returns {Array<string>} Array of supported schema types
 */
function getAvailableSchemaTypes() {
  return Object.keys(SCHEMA_PATHS);
}

/**
 * Clear schema cache (useful for testing or schema updates)
 */
function clearSchemaCache() {
  schemaCache.clear();
}

/**
 * Get schema file path for a given type
 * @param {string} schemaType - Type of schema
 * @returns {string} Path to schema file
 */
function getSchemaPath(schemaType) {
  return SCHEMA_PATHS[schemaType] || null;
}

/**
 * Validate learning path manifest data
 * @param {Object} data - Manifest data to validate
 * @returns {Promise<Object>} Validation result { valid: boolean, errors: Array }
 */
async function validateManifest(data) {
  try {
    const validate = await loadSchema('learning-path-manifest');
    const valid = validate(data);

    return {
      valid,
      errors: valid ? [] : validate.errors.map(err => ({
        instancePath: err.instancePath,
        schemaPath: err.schemaPath,
        keyword: err.keyword,
        message: err.message,
        params: err.params
      }))
    };
  } catch (error) {
    return {
      valid: false,
      errors: [`Manifest validation error: ${error.message}`]
    };
  }
}

export {
  loadSchema,
  detectProgressType,
  validateProgress,
  validateManifest,
  getAvailableSchemaTypes,
  clearSchemaCache,
  getSchemaPath,
  PROGRESS_TYPE_PATTERNS
};
