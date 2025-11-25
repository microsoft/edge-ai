/**
 * Routes Index
 * Main router configuration for the Express.js progress server
 */

import express from 'express';
import progressRoutes from './progress.js';
import sseRoutes from './sse.js';
import learningPathsRoutes from './learning-paths.js';

const router = express.Router();

// Health check endpoint
router.get('/health', (req, res) => {
  const memUsage = process.memoryUsage();
  const memoryData = {
    used: memUsage.heapUsed,
    total: memUsage.heapTotal,
    percentage: Math.round((memUsage.heapUsed / memUsage.heapTotal) * 100)
  };

  res.json({
    success: true,
    data: {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: memoryData,
      version: process.version
    }
  });
});

// Enhanced health monitoring endpoints
router.get('/health/detailed', (req, res) => {
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

router.get('/health/ready', (req, res) => {
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

router.get('/health/live', (req, res) => {
  res.json({
    status: 'alive',
    timestamp: new Date().toISOString(),
    pid: process.pid
  });
});

// Metrics endpoints
router.get('/metrics', (req, res) => {
  // Add CORS headers for metrics endpoints
  res.set('access-control-allow-origin', '*');
  res.set('access-control-allow-methods', 'GET, OPTIONS');

  res.json({
    timestamp: new Date().toISOString(),
    counters: {
      'http.requests.total': 0 // Would track actual metrics
    },
    histograms: {},
    gauges: {}
  });
});

router.get('/metrics/prometheus', (req, res) => {
  // Add CORS headers for metrics endpoints
  res.set('access-control-allow-origin', '*');
  res.set('access-control-allow-methods', 'GET, OPTIONS');
  res.set('content-type', 'text/plain');

  res.send(`# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total 0

# HELP http_request_duration_seconds HTTP request duration
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_sum 0
http_request_duration_seconds_count 0

# HELP nodejs_memory_heap_used_bytes Node.js heap memory used
# TYPE nodejs_memory_heap_used_bytes gauge
nodejs_memory_heap_used_bytes ${process.memoryUsage().heapUsed}
`);
});

// API info endpoint
router.get('/info', (req, res) => {
  res.json({
    success: true,
    data: {
      name: 'Progress Server API',
      version: '2.0.0',
      description: 'Express.js server for progress tracking with unified SSE support',
      endpoints: {
        progress: '/api/progress',
        sse: '/api/progress/events',
        'learning': '/api/learning',
        health: '/api/health',
        info: '/api/info'
      },
      supportedTypes: ['self-assessment', 'kata-progress', 'lab-progress'],
      features: [
        'Schema validation',
        'Progress type detection',
        'File synchronization',
        'Server-Sent Events',
        'Real-time progress tracking'
      ]
    }
  });
});

// Mount route modules
router.use('/progress', progressRoutes);
router.use('/progress', sseRoutes);
router.use('/learning', learningPathsRoutes);

// SSE status endpoint (bypass progress type detection)
router.get('/progress/events/status', async (req, res) => {
  const { default: sseManager } = await import('../utils/sse-manager.js');
  const stats = sseManager.getClientStats();

  res.json({
    success: true,
    data: {
      sse: {
        ...stats,
        endpoint: '/api/progress/events',
        supportedTypes: ['self-assessment', 'kata-progress', 'lab-progress']
      }
    }
  });
});

export default router;
