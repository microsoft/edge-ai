/**
 * @fileoverview Configuration Validator
 * Environment variable validation and configuration management
 */

/**
 * Configuration validation error
 */
export class ConfigValidationError extends Error {
  constructor(errors) {
    const message = `Configuration validation failed:\n${errors.map(e => `  - ${e}`).join('\n')}`;
    super(message);
    this.name = 'ConfigValidationError';
    this.errors = errors;
  }
}

/**
 * Configuration schema definition
 */
const CONFIG_SCHEMA = {
  NODE_ENV: {
    type: 'enum',
    required: true,
    allowedValues: ['development', 'test', 'production'],
    transform: (value) => value?.toLowerCase().trim()
  },
  PORT: {
    type: 'number',
    required: true,
    min: 1000,
    max: 65535,
    transform: (value) => parseInt(value?.toString().trim(), 10)
  },
  ENABLE_CORS: {
    type: 'boolean',
    required: false,
    default: true,
    transform: (value) => {
      const str = value?.toString().toLowerCase();
      if (str === 'true') {return true;}
      if (str === 'false') {return false;}
      return value; // Return original value for validation to catch
    }
  },
  LOG_LEVEL: {
    type: 'enum',
    required: false,
    default: 'info',
    allowedValues: ['error', 'warn', 'info', 'debug'],
    transform: (value) => value?.toLowerCase().trim()
  },
  REQUEST_TIMEOUT: {
    type: 'number',
    required: false,
    default: 30000,
    min: 1,
    transform: (value) => parseInt(value?.toString().trim(), 10)
  },
  MAX_FILE_SIZE: {
    type: 'number',
    required: false,
    default: 1048576, // 1MB
    min: 1,
    transform: (value) => parseInt(value?.toString().trim(), 10)
  }
};

/**
 * Validate environment variable
 * @param {*} value - The value to validate
 * @param {string} type - The expected type
 * @param {Object} options - Validation options
 * @returns {Object} Validation result
 */
export function validateEnvVar(value, type, options = {}) {
  const { required = false, min, max, allowedValues, default: defaultValue } = options;

  // Handle undefined/null values
  if (value === undefined || value === null) {
    if (required) {
      return { valid: false, error: 'is required' };
    }
    return { valid: true, value: defaultValue };
  }

  // Handle empty strings
  if (typeof value === 'string' && value.trim() === '') {
    if (required) {
      return { valid: false, error: 'cannot be empty' };
    }
    return { valid: true, value: defaultValue };
  }

  // Type-specific validation
  switch (type) {
    case 'string':
      return { valid: true, value: value.toString() };

    case 'number': {
      const numValue = typeof value === 'number' ? value : parseFloat(value);
      if (isNaN(numValue)) {
        return { valid: false, error: 'must be a valid number' };
      }
      if (min !== undefined && numValue < min) {
        return { valid: false, error: `must be greater than or equal to ${min}` };
      }
      if (max !== undefined && numValue > max) {
        if (min !== undefined) {
          return { valid: false, error: `must be between ${min} and ${max}` };
        }
        return { valid: false, error: `must be less than or equal to ${max}` };
      }
      return { valid: true, value: numValue };
    }

    case 'boolean': {
      const strValue = value.toString().toLowerCase();
      if (strValue === 'true') {
        return { valid: true, value: true };
      }
      if (strValue === 'false') {
        return { valid: true, value: false };
      }
      return { valid: false, error: 'must be true or false' };
    }

    case 'enum': {
      if (!allowedValues || !Array.isArray(allowedValues)) {
        return { valid: false, error: 'no allowed values specified' };
      }
      const strValue = value.toString().toLowerCase().trim();
      if (allowedValues.map(v => v.toLowerCase()).includes(strValue)) {
        return { valid: true, value: strValue };
      }
      return { valid: false, error: `must be one of: ${allowedValues.join(', ')}` };
    }

    default:
      return { valid: false, error: `unknown validation type: ${type}` };
  }
}

/**
 * Validate configuration
 * @returns {Object} Validation result with config and errors
 */
export function validateConfig() {
  const errors = [];
  const config = {};

  // Validate each configuration item
  for (const [envVar, schema] of Object.entries(CONFIG_SCHEMA)) {
    let value = process.env[envVar];

    // Apply transformation if specified
    if (schema.transform && value !== undefined) {
      try {
        value = schema.transform(value);
      } catch (error) {
        errors.push(`${envVar} transformation failed: ${error.message}`);
        continue;
      }
    }

    // Validate the value
    const validation = validateEnvVar(value, schema.type, {
      required: schema.required,
      min: schema.min,
      max: schema.max,
      allowedValues: schema.allowedValues,
      default: schema.default
    });

    if (!validation.valid) {
      errors.push(`${envVar} ${validation.error}`);
    } else {
      // Convert environment variable name to camelCase for config object
      const configKey = envVar.toLowerCase()
        .split('_')
        .map((part, index) => index === 0 ? part : part.charAt(0).toUpperCase() + part.slice(1))
        .join('');

      config[configKey] = validation.value;
    }
  }

  return {
    valid: errors.length === 0,
    errors,
    config
  };
}

/**
 * Get list of required environment variables
 * @param {string} environment - Optional environment filter
 * @returns {Array} List of required environment variable names
 */
export function getRequiredEnvVars(environment = null) {
  const required = Object.entries(CONFIG_SCHEMA)
    .filter(([, schema]) => schema.required)
    .map(([envVar]) => envVar);

  // Add environment-specific requirements
  if (environment === 'production') {
    // Production might have additional requirements
    // Add them here as needed
  }

  return required;
}
