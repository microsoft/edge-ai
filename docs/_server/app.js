/**
 * Express.js Progress Server
 * Unified server for progress tracking with SSE and schema validation
 * Version: 2.0.0
 */

import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import compression from 'compression';
import path from 'path';
import fs from 'fs/promises';
import { fileURLToPath } from 'url';

import config from './config/server-config.js';
import { setupErrorHandler } from './middleware/index.js';
import createSecurityMiddleware from './middleware/security.js';
import { createDynamicCorsConfig } from './middleware/cors-config.js';
import sseManager from './utils/sse-manager.js';
import { PerformanceMonitor } from './utils/performance-monitor.js';

// Get current directory for ES6 modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Create Express app
const app = express();

// Create global performance monitor
const performanceMonitor = new PerformanceMonitor();

// Security middleware - environment-aware helmet configuration
app.use(createSecurityMiddleware());

// CORS middleware - environment-aware configuration
app.use(cors(createDynamicCorsConfig()));

// Compression middleware
app.use(compression());

// Rate limiting middleware
const limiter = rateLimit(config.rateLimit);
app.use(limiter);

// HTTP request tracking middleware
app.use((req, res, next) => {
  const start = Date.now();

  // Override res.end to capture response data
  const originalEnd = res.end;
  res.end = function(...args) {
    const duration = Date.now() - start;

    // Track HTTP request metrics
    performanceMonitor.trackHttpRequest(req.method, req.path, res.statusCode, duration);

    // Set response time header
    res.set('x-response-time', `${duration}ms`);

    // Call original end
    originalEnd.apply(res, args);
  };

  next();
});

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
if (config.logging.enableAccessLog) {
  app.use(morgan(config.logging.format));
}

// Health check endpoint
app.get('/health', (req, res) => {
  // Set cache control headers
  res.set('cache-control', 'no-cache, no-store, must-revalidate');
  res.set('pragma', 'no-cache');
  res.set('expires', '0');

  const response = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '2.0.0',
    environment: config.server.environment
  };

  res.json(response);
});

// Enhanced health monitoring endpoints
app.get('/health/detailed', (req, res) => {
  const memUsage = process.memoryUsage();
  const totalMem = memUsage.heapTotal;
  const usedMem = memUsage.heapUsed;
  const memoryPercentage = Math.round((usedMem / totalMem) * 100);

  // Check for unhealthy conditions
  const issues = [];
  let status = 'healthy';

  if (memoryPercentage > 90) {
    issues.push({
      type: 'high_memory_usage',
      severity: 'critical',
      description: `Memory usage at ${memoryPercentage}%`
    });
    status = 'unhealthy';
  }

  const healthData = {
    status,
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: '2.0.0',
    system: {
      memory: {
        used: Math.round(usedMem / 1024 / 1024),
        total: Math.round(totalMem / 1024 / 1024),
        percentage: memoryPercentage
      },
      cpu: {
        usage: 0 // Simplified for now
      },
      eventLoop: {
        lag: 0 // Simplified for now
      }
    },
    application: {
      requests: {
        total: 0, // Would track actual request counts
        active: 0
      },
      errors: {
        total: 0, // Would track actual error counts
        rate: 0
      }
    }
  };

  if (issues.length > 0) {
    healthData.issues = issues;
    res.status(503);
  }

  res.json(healthData);
});

app.get('/health/ready', (req, res) => {
  res.json({
    status: 'ready',
    timestamp: new Date().toISOString(),
    checks: {
      filesystem: 'ok',
      memory: 'ok',
      dependencies: 'ok'
    }
  });
});

app.get('/health/live', (req, res) => {
  res.json({
    status: 'alive',
    timestamp: new Date().toISOString(),
    pid: process.pid
  });
});

// Metrics endpoints
app.get('/metrics', (req, res) => {
  // Add CORS headers for metrics endpoints
  res.set('access-control-allow-origin', '*');
  res.set('access-control-allow-methods', 'GET, OPTIONS');

  // Get actual metrics from performance monitor
  const metrics = performanceMonitor.exportJSON();
  res.json(JSON.parse(metrics));
});

app.get('/metrics/prometheus', (req, res) => {
  // Add CORS headers for metrics endpoints
  res.set('access-control-allow-origin', '*');
  res.set('access-control-allow-methods', 'GET, OPTIONS');
  res.set('content-type', 'text/plain');

  // Get actual prometheus metrics from performance monitor
  const prometheusMetrics = performanceMonitor.exportPrometheus();
  res.send(prometheusMetrics);
});

// API routes
import routes from './routes/index.js';
app.use('/api', routes);

// Error handling middleware
setupErrorHandler(app);

// Ensure progress directory exists
const progressDir = path.join(__dirname, '..', '..', '.copilot-tracking', 'learning');

async function ensureProgressDirectory() {
  try {
    await fs.access(progressDir);
    console.log('Progress directory exists:', progressDir);
  } catch {
    await fs.mkdir(progressDir, { recursive: true });
    console.log('Created progress directory:', progressDir);
  }
}

// Initialize directories and server
let fileWatcher, server;

// Initialize function for startup
async function initialize() {
  // Initialize directories
  await ensureProgressDirectory();

  // Initialize learning path parser
  const learningPathParser = await import('./utils/learning-path-parser.js').then(m => m.default);
  await learningPathParser.initialize();

  // Only start file watcher and server in non-test environment
  if (process.env.NODE_ENV !== 'test') {
    // Import and start file watcher if not disabled
    if (!process.env.SKIP_FILE_WATCHER) {
      import('./utils/file-watcher.js').then(({ default: FileWatcherModule }) => {
        fileWatcher = FileWatcherModule;
        fileWatcher.start();
      }).catch(error => {
        console.error('Error starting file watcher:', error);
      });
    }

    // Start server
    server = app.listen(config.server.port, config.server.host, () => {
      console.log(`Express progress server running on http://${config.server.host}:${config.server.port}`);
      console.log(`Environment: ${config.server.environment}`);
      console.log(`Runtime Detection:`, JSON.stringify(config.runtime, null, 2));
      console.log(`Progress directory: ${progressDir}`);
    });
  }
}

// Auto-initialize only if not in test environment or if SKIP_SERVER_START is not set
if (process.env.NODE_ENV !== 'test' && !process.env.SKIP_SERVER_START) {
  initialize().catch(error => {
    console.error('Error initializing server:', error);
    process.exit(1);
  });

  // Add uncaught exception handler to prevent silent crashes
  process.on('uncaughtException', (error) => {
    console.error('Uncaught exception:', error);
    // Don't exit, attempt to continue
  });

  process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled rejection at:', promise, 'reason:', reason);
    // Don't exit, attempt to continue
  });
}

// Graceful shutdown handling (only in non-test environment)
if (process.env.NODE_ENV !== 'test') {
  process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully...');

    // Cleanup SSE connections
    sseManager.cleanup();

    // Stop file watcher if it was started
    if (fileWatcher) {
      fileWatcher.stop();
    }

    if (server) {
      server.close(() => {
        console.log('Server closed');
        process.exit(0);
      });
    } else {
      process.exit(0);
    }
  });

  process.on('SIGINT', () => {
    console.log('SIGINT received, shutting down gracefully...');

    // Cleanup SSE connections
    sseManager.cleanup();

    // Stop file watcher if it was started
    if (fileWatcher) {
      fileWatcher.stop();
    }

    if (server) {
      server.close(() => {
        console.log('Server closed');
        process.exit(0);
      });
    } else {
      process.exit(0);
    }
  });
}

export default app;
export { initialize };
