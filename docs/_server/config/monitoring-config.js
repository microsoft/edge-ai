/**
 * @fileoverview Monitoring Configuration
 * Configuration management for monitoring and logging
 */

/**
 * Default monitoring configuration
 */
const DEFAULT_CONFIG = {
  enabled: true,
  logLevel: 'info',
  metricsInterval: 5000, // 5 seconds
  retentionPeriod: 86400000, // 24 hours in ms
  thresholds: {
    responseTime: 1000, // ms
    memoryUsage: 80, // percentage
    cpuUsage: 80, // percentage
    errorRate: 5 // percentage
  },
  features: {
    requestLogging: true,
    performanceMonitoring: true,
    healthChecks: true
  },
  export: {
    formats: ['json', 'prometheus'],
    endpoint: '/metrics'
  }
};

/**
 * Current configuration (mutable)
 */
let currentConfig = { ...DEFAULT_CONFIG };

/**
 * Valid log levels
 */
const VALID_LOG_LEVELS = ['error', 'warn', 'info', 'debug'];

/**
 * Valid export formats
 */
const VALID_EXPORT_FORMATS = ['json', 'prometheus'];

/**
 * MonitoringConfig class for object-oriented configuration management
 */
export class MonitoringConfig {
  /**
   * Create a new MonitoringConfig instance
   * @param {Object} config - Initial configuration
   */
  constructor(config = {}) {
    const mergedConfig = { ...DEFAULT_CONFIG, ...config };

    // Validate configuration
    const validation = validateConfig(mergedConfig);
    if (!validation.valid) {
      throw new Error(`Invalid configuration: ${validation.errors.join(', ')}`);
    }

    // Apply configuration
    Object.assign(this, mergedConfig);
  }

  /**
   * Convert configuration to JSON
   * @returns {Object} Configuration as plain object
   */
  toJSON() {
    return {
      enabled: this.enabled,
      logLevel: this.logLevel,
      metricsInterval: this.metricsInterval,
      retentionPeriod: this.retentionPeriod,
      thresholds: { ...this.thresholds },
      features: { ...this.features },
      export: { ...this.export }
    };
  }
}

/**
 * Get current monitoring configuration
 * @returns {Object} Current configuration
 */
export function getConfig() {
  // Load from environment variables if available
  const envConfig = loadFromEnvironment();
  return { ...currentConfig, ...envConfig };
}

/**
 * Update monitoring configuration
 * @param {Object} updates - Configuration updates
 */
export function updateConfig(updates) {
  // Validate updates
  const validation = validateConfig(updates);
  if (!validation.valid) {
    throw new Error(`Invalid configuration updates: ${validation.errors.join(', ')}`);
  }

  // Apply updates
  currentConfig = { ...currentConfig, ...updates };
}

/**
 * Validate configuration object
 * @param {Object} config - Configuration to validate
 * @returns {Object} Validation result with valid flag and errors array
 */
export function validateConfig(config) {
  const errors = [];

  // Validate log level
  if (config.logLevel && !VALID_LOG_LEVELS.includes(config.logLevel)) {
    errors.push(`Invalid log level: ${config.logLevel}`);
  }

  // Validate metrics interval
  if (config.metricsInterval !== undefined) {
    if (!Number.isInteger(config.metricsInterval) || config.metricsInterval <= 0) {
      errors.push('Metrics interval must be positive');
    }
  }

  // Validate retention period
  if (config.retentionPeriod !== undefined) {
    if (!Number.isInteger(config.retentionPeriod) || config.retentionPeriod <= 0) {
      errors.push('Retention period must be positive');
    }
  }

  // Validate thresholds
  if (config.thresholds) {
    const { thresholds } = config;

    if (thresholds.responseTime !== undefined) {
      if (!Number.isFinite(thresholds.responseTime) || thresholds.responseTime <= 0) {
        errors.push('Response time threshold must be positive');
      }
    }

    if (thresholds.memoryUsage !== undefined) {
      if (!Number.isFinite(thresholds.memoryUsage) || thresholds.memoryUsage <= 0 || thresholds.memoryUsage > 100) {
        errors.push('Memory usage threshold must be between 0 and 100');
      }
    }

    if (thresholds.cpuUsage !== undefined) {
      if (!Number.isFinite(thresholds.cpuUsage) || thresholds.cpuUsage <= 0 || thresholds.cpuUsage > 100) {
        errors.push('CPU usage threshold must be between 0 and 100');
      }
    }

    if (thresholds.errorRate !== undefined) {
      if (!Number.isFinite(thresholds.errorRate) || thresholds.errorRate < 0 || thresholds.errorRate > 100) {
        errors.push('Error rate threshold must be between 0 and 100');
      }
    }
  }

  // Validate export formats
  if (config.export && config.export.formats) {
    const invalidFormats = config.export.formats.filter(format => !VALID_EXPORT_FORMATS.includes(format));
    if (invalidFormats.length > 0) {
      errors.push(`Invalid export formats: ${invalidFormats.join(', ')}`);
    }
  }

  return {
    valid: errors.length === 0,
    errors
  };
}

/**
 * Get performance thresholds
 * @returns {Object} Performance thresholds
 */
export function getThresholds() {
  const config = getConfig();
  return { ...config.thresholds };
}

/**
 * Get current log level
 * @returns {string} Current log level
 */
export function getLogLevel() {
  const config = getConfig();
  return config.logLevel;
}

/**
 * Load configuration from environment variables
 * @returns {Object} Configuration from environment
 */
function loadFromEnvironment() {
  const envConfig = {};

  // Load boolean values
  if (process.env.MONITORING_ENABLED === 'true' || process.env.MONITORING_ENABLED === 'false') {
    envConfig.enabled = process.env.MONITORING_ENABLED === 'true';
  }

  // Load string values
  if (process.env.LOG_LEVEL && VALID_LOG_LEVELS.includes(process.env.LOG_LEVEL)) {
    envConfig.logLevel = process.env.LOG_LEVEL;
  }

  // Load numeric values
  if (process.env.METRICS_INTERVAL) {
    const interval = parseInt(process.env.METRICS_INTERVAL, 10);
    if (!isNaN(interval) && interval > 0) {
      envConfig.metricsInterval = interval;
    }
  }

  if (process.env.RETENTION_PERIOD) {
    const period = parseInt(process.env.RETENTION_PERIOD, 10);
    if (!isNaN(period) && period > 0) {
      envConfig.retentionPeriod = period;
    }
  }

  // Load threshold values
  const thresholds = {};
  if (process.env.RESPONSE_TIME_THRESHOLD) {
    const threshold = parseFloat(process.env.RESPONSE_TIME_THRESHOLD);
    if (!isNaN(threshold) && threshold > 0) {
      thresholds.responseTime = threshold;
    }
  }

  if (process.env.MEMORY_USAGE_THRESHOLD) {
    const threshold = parseFloat(process.env.MEMORY_USAGE_THRESHOLD);
    if (!isNaN(threshold) && threshold > 0 && threshold <= 100) {
      thresholds.memoryUsage = threshold;
    }
  }

  if (process.env.CPU_USAGE_THRESHOLD) {
    const threshold = parseFloat(process.env.CPU_USAGE_THRESHOLD);
    if (!isNaN(threshold) && threshold > 0 && threshold <= 100) {
      thresholds.cpuUsage = threshold;
    }
  }

  if (process.env.ERROR_RATE_THRESHOLD) {
    const threshold = parseFloat(process.env.ERROR_RATE_THRESHOLD);
    if (!isNaN(threshold) && threshold >= 0 && threshold <= 100) {
      thresholds.errorRate = threshold;
    }
  }

  if (Object.keys(thresholds).length > 0) {
    envConfig.thresholds = { ...DEFAULT_CONFIG.thresholds, ...thresholds };
  }

  return envConfig;
}
