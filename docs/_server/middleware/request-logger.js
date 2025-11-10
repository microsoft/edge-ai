/**
 * @fileoverview Request Logger Middleware
 * Structured logging middleware for HTTP requests
 */

import { v4 as uuidv4 } from 'uuid';

/**
 * Request logging configuration
 */
const DEFAULT_CONFIG = {
  enabled: true,
  logLevel: 'info',
  includeBody: false,
  includeHeaders: false,
  excludePaths: ['/health', '/metrics'],
  sensitiveHeaders: ['authorization', 'cookie', 'x-api-key'],
  maxBodyLength: 1024
};

/**
 * Logger instance (would be Winston in production)
 */
const logger = {
  info: (message, meta) => console.log(JSON.stringify({ level: 'info', message, ...meta, timestamp: new Date().toISOString() })),
  warn: (message, meta) => console.warn(JSON.stringify({ level: 'warn', message, ...meta, timestamp: new Date().toISOString() })),
  error: (message, meta) => console.error(JSON.stringify({ level: 'error', message, ...meta, timestamp: new Date().toISOString() }))
};

/**
 * Create request logger middleware
 * @param {Object|Function} configOrLogger - Configuration options or logger instance
 * @param {Object} config - Configuration options (if first param is logger)
 * @returns {Function} Express middleware function
 */
export function createRequestLogger(configOrLogger = {}, config = {}) {
  // Handle both (config) and (logger, config) parameter patterns
  let options, loggerInstance;

  if (typeof configOrLogger === 'function' || (configOrLogger && typeof configOrLogger.info === 'function')) {
    // First parameter is a logger
    loggerInstance = configOrLogger;
    options = { ...DEFAULT_CONFIG, ...config };
  } else {
    // First parameter is config
    loggerInstance = logger;
    options = { ...DEFAULT_CONFIG, ...configOrLogger };
  }

  return (req, res, next) => {
    if (!options.enabled) {
      return next();
    }

    // Skip excluded paths (handle undefined req.path)
    const requestPath = req.path || req.url || '';
    if (options.excludePaths.some(path => requestPath.startsWith(path))) {
      return next();
    }

    // Generate unique request ID
    const requestId = uuidv4();
    req.requestId = requestId;

    // Start timing (using performance.now() for higher precision)
    const startTime = performance.now();

    // Extract client info
    const clientInfo = {
      ip: req.ip || req.socket?.remoteAddress || req.connection?.remoteAddress || 'unknown',
      userAgent: (req.get && req.get('User-Agent')) || req.headers?.['user-agent'] || 'unknown'
    };

    // Prepare basic request data
    const requestData = {
      requestId,
      method: req.method,
      url: requestPath,
      userAgent: clientInfo.userAgent,
      ip: clientInfo.ip,
      timestamp: new Date().toISOString()
    };

    // Include headers if configured
    if (options.includeHeaders) {
      requestData.headers = sanitizeHeaders(req.headers, options.sensitiveHeaders);
    }

    // Include body if configured
    if (options.includeBody && req.body) {
      requestData.body = sanitizeBody(req.body, options.maxBodyLength);
    }

    // Don't log incoming request, only log when complete

    // Capture original res.end to log response
    const originalEnd = res.end;
    if (originalEnd) {
      res.end = function(chunk, encoding) {
        const endTime = performance.now();
        const responseTime = Math.round((endTime - startTime) * 100) / 100; // Round to 2 decimal places

        // Determine log level based on status code
        let logLevel = 'info';
        if (res.statusCode >= 400 && res.statusCode < 500) {
          logLevel = 'warn';
        } else if (res.statusCode >= 500) {
          logLevel = 'error';
        }

        // Log completed request with all data
        loggerInstance[logLevel]('HTTP Request', {
          ...requestData,
          status: res.statusCode,
          responseTime,
          isApi: requestPath.startsWith('/api/'),
          apiEndpoint: requestPath.startsWith('/api/') ? requestPath : undefined,
          contentLength: parseInt((res.get && res.get('Content-Length')) || res.getHeader?.('Content-Length') || '0', 10)
        });

        // Set response time header
        if (res.set) {
          res.set('X-Response-Time', `${responseTime}ms`);
        }

        // Call original end
        originalEnd.call(this, chunk, encoding);
      };
    }

    next();
  };
}

/**
 * Sanitize headers by removing sensitive information
 * @param {Object} headers - Request headers
 * @param {Array} sensitiveHeaders - List of sensitive header names
 * @returns {Object} Sanitized headers
 */
function sanitizeHeaders(headers, sensitiveHeaders = []) {
  const sanitized = { ...headers };

  sensitiveHeaders.forEach(header => {
    const key = Object.keys(sanitized).find(k => k.toLowerCase() === header.toLowerCase());
    if (key) {
      sanitized[key] = '[REDACTED]';
    }
  });

  return sanitized;
}

/**
 * Sanitize request body by truncating if too large
 * @param {*} body - Request body
 * @param {number} maxLength - Maximum length to log
 * @returns {*} Sanitized body
 */
function sanitizeBody(body, maxLength = 1024) {
  if (!body) {return body;}

  const bodyString = typeof body === 'string' ? body : JSON.stringify(body);

  if (bodyString.length > maxLength) {
    return `${bodyString.substring(0, maxLength) }... [TRUNCATED]`;
  }

  return body;
}

/**
 * Request logger middleware that can be used as both factory and direct middleware
 * @param {Object|Function} configOrLogger - Configuration options or logger instance
 * @param {Object} config - Configuration options (if first param is logger)
 * @returns {Function} Express middleware function
 */
export function requestLogger(configOrLogger = {}, config = {}) {
  return createRequestLogger(configOrLogger, config);
}

/**
 * Get logger configuration for different environments
 * @param {string} environment - Environment (development, production, test)
 * @returns {Object} Logger configuration
 */
export function getLoggerConfig(environment = 'development') {
  const configs = {
    development: {
      level: 'debug',
      format: 'combined',
      transports: [
        { type: 'console', level: 'debug' }
      ]
    },
    production: {
      level: 'info',
      format: 'json',
      transports: [
        { type: 'console', level: 'info' },
        { type: 'file', level: 'info', filename: 'app.log' }
      ]
    },
    test: {
      level: 'error',
      silent: true,
      format: 'simple',
      transports: [
        { type: 'console', level: 'error' }
      ]
    }
  };

  return configs[environment] || configs.development;
}

/**
 * Update logger configuration
 * @param {Object} updates - Configuration updates
 */
export function updateLoggerConfig(updates) {
  Object.assign(DEFAULT_CONFIG, updates);
}
