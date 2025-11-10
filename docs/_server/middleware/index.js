/**
 * Middleware Index
 * Exports all custom middleware for the Express.js progress server
 */

// Import validation middleware
import {
  validateProgressData,
  detectProgressTypeMiddleware,
  validateSpecificProgressType,
  validationErrorHandler
} from './validation.js';

// Import progress type detection middleware
import {
  progressTypeDetector,
  enforceProgressType,
  routeByProgressType,
  addProgressTypeInfo
} from './progress-type-detector.js';

// Import data transformation middleware
import { dataTransformer } from './data-transformer.js';

/**
 * Error handling middleware
 * Provides consistent error responses and logging
 */
function setupErrorHandler(app) {
  // 404 handler
  app.use((req, res, _next) => {
    res.status(404).json({
      success: false,
      error: `Cannot ${req.method} ${req.path}`,
      timestamp: new Date().toISOString()
    });
  });

  // Global error handler
  app.use((err, req, res, _next) => {
    console.error('Error:', err);

    // Default error response
    const statusCode = err.statusCode || err.status || 500;
    let message = err.message || 'Internal Server Error';

    // Don't leak error details in production
    if (process.env.NODE_ENV === 'production' && statusCode === 500) {
      message = 'Internal Server Error';
    }

    res.status(statusCode).json({
      success: false,
      error: message,
      timestamp: new Date().toISOString(),
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
  });
}

export {
  // Core middleware
  setupErrorHandler,

  // Validation middleware
  validateProgressData,
  detectProgressTypeMiddleware,
  validateSpecificProgressType,
  validationErrorHandler,

  // Progress type detection middleware
  progressTypeDetector,
  enforceProgressType,
  routeByProgressType,
  addProgressTypeInfo,

  // Data transformation middleware
  dataTransformer
};
