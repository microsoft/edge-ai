/**
 * @fileoverview Environment Detector
 * Runtime environment detection and environment-specific configuration
 */

/**
 * Environment detection error
 */
export class EnvironmentError extends Error {
  constructor(message) {
    super(message);
    this.name = 'EnvironmentError';
  }
}

/**
 * Valid environment names
 */
const VALID_ENVIRONMENTS = ['development', 'test', 'production'];

/**
 * Environment-specific configuration
 */
const ENVIRONMENT_CONFIGS = {
  development: {
    environment: 'development',
    debug: true,
    logLevel: 'debug',
    cors: {
      enabled: true,
      credentials: true
    },
    security: {
      strictMode: false,
      requireHttps: false
    },
    performance: {
      enableMetrics: true,
      enableProfiling: true
    },
    features: {
      hotReload: true,
      debugEndpoints: true,
      verboseLogging: true,
      errorDetails: true
    }
  },
  test: {
    environment: 'test',
    debug: false,
    logLevel: 'error',
    cors: {
      enabled: true,
      credentials: false
    },
    security: {
      strictMode: false,
      requireHttps: false
    },
    performance: {
      enableMetrics: false,
      enableProfiling: false
    },
    features: {
      hotReload: false,
      debugEndpoints: true,
      verboseLogging: false,
      errorDetails: true
    }
  },
  production: {
    environment: 'production',
    debug: false,
    logLevel: 'warn',
    cors: {
      enabled: false,
      credentials: false
    },
    security: {
      strictMode: true,
      requireHttps: true
    },
    performance: {
      enableMetrics: true,
      enableProfiling: false
    },
    features: {
      hotReload: false,
      debugEndpoints: false,
      verboseLogging: false,
      errorDetails: false
    }
  }
};

/**
 * Detect current environment
 * @returns {string} Environment name
 */
export function detectEnvironment() {
  const nodeEnv = process.env.NODE_ENV;

  if (!nodeEnv) {
    return 'development';
  }

  return nodeEnv.toLowerCase().trim();
}

/**
 * Check if running in production
 * @returns {boolean} True if production environment
 */
export function isProduction() {
  return detectEnvironment() === 'production';
}

/**
 * Check if running in development
 * @returns {boolean} True if development environment
 */
export function isDevelopment() {
  return detectEnvironment() === 'development';
}

/**
 * Check if running in test
 * @returns {boolean} True if test environment
 */
export function isTest() {
  return detectEnvironment() === 'test';
}

/**
 * Validate environment
 * @throws {EnvironmentError} If environment is invalid
 */
export function validateEnvironment() {
  const environment = detectEnvironment();

  // Check if environment is valid
  if (!VALID_ENVIRONMENTS.includes(environment)) {
    throw new EnvironmentError(
      `Unknown environment: ${environment}. Valid environments are: ${VALID_ENVIRONMENTS.join(', ')}`
    );
  }

  // Environment-specific validation
  if (environment === 'production') {
    // Production security checks
    if (process.env.DEBUG === 'true') {
      throw new EnvironmentError(
        'Invalid configuration: DEBUG should not be enabled in production'
      );
    }

    if (process.env.HTTPS_DISABLED === 'true') {
      throw new EnvironmentError(
        'HTTPS is required in production environment'
      );
    }
  }

  if (environment === 'test') {
    // Test environment isolation checks
    if (process.env.PRODUCTION_DB === 'true') {
      throw new EnvironmentError(
        'Test environment should not connect to production resources'
      );
    }
  }
}

/**
 * Detect runtime environment details
 * @returns {Object} Runtime environment information
 */
function detectRuntimeEnvironment() {
  return {
    isCI: process.env.CI === 'true',
    isContinuousIntegration: process.env.CI === 'true',
    isDocker: process.env.DOCKER === 'true',
    isContainerized: process.env.DOCKER === 'true',
    cloudPlatform: process.env.CLOUD_PLATFORM || null,
    isCloud: !!process.env.CLOUD_PLATFORM
  };
}

/**
 * Get environment-specific configuration
 * @param {Object} overrides - Configuration overrides
 * @returns {Object} Environment configuration
 */
export function getEnvironmentConfig(overrides = {}) {
  const environment = detectEnvironment();
  const baseConfig = ENVIRONMENT_CONFIGS[environment];
  const runtimeConfig = detectRuntimeEnvironment();

  if (!baseConfig) {
    throw new EnvironmentError(`No configuration found for environment: ${environment}`);
  }

  // Deep merge configuration
  const config = {
    ...baseConfig,
    runtime: runtimeConfig
  };

  // Apply overrides with deep merge for nested objects
  return deepMerge(config, overrides);
}

/**
 * Deep merge two objects
 * @param {Object} target - Target object
 * @param {Object} source - Source object
 * @returns {Object} Merged object
 */
function deepMerge(target, source) {
  const result = { ...target };

  for (const [key, value] of Object.entries(source)) {
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      result[key] = deepMerge(result[key] || {}, value);
    } else {
      result[key] = value;
    }
  }

  return result;
}
