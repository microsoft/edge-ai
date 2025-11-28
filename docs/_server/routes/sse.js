/**
 * SSE Routes
 * Express routes for Server-Sent Events functionality
 */

import express from 'express';
import sseManager from '../utils/sse-manager.js';

const router = express.Router();

/**
 * SSE status endpoint - must be before parameterized routes
 * GET /api/progress/events/status
 */
router.get('/events/status', (req, res) => {
  const stats = sseManager.getClientStats();

  res.json({
    success: true,
    data: {
      sse: {
        ...stats,
        endpoint: '/api/progress/events',
        supportedTypes: ['self-assessment', 'kata-progress', 'lab-progress', 'kata', 'path', 'lab']
      }
    }
  });
});

/**
 * SSE endpoint for all progress types
 * GET /api/progress/events
 */
router.get('/events', (req, res) => {
  const progressType = req.query.type || 'self-assessment';
  const sendHistory = req.query.history !== 'false';
  const heartbeat = req.query.heartbeat !== 'false';

  // Validate progress type
  const validTypes = ['self-assessment', 'kata-progress', 'lab-progress', 'kata', 'path', 'lab'];
  if (!validTypes.includes(progressType)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid progress type',
      details: {
        provided: progressType,
        valid: validTypes
      }
    });
  }

  // Add client to SSE manager
  const clientId = sseManager.addClient(res, progressType, {
    sendHistory,
    heartbeat
  });

  console.log(`SSE client connected: ${clientId} (type: ${progressType})`);
});

/**
 * SSE endpoint for specific progress type
 * GET /api/progress/events/:type
 */
router.get('/events/:type', (req, res) => {
  const progressType = req.params.type;
  const sendHistory = req.query.history !== 'false';
  const heartbeat = req.query.heartbeat !== 'false';

  // Validate progress type
  const validTypes = ['self-assessment', 'kata-progress', 'lab-progress', 'kata', 'path', 'lab'];
  if (!validTypes.includes(progressType)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid progress type',
      details: {
        provided: progressType,
        valid: validTypes
      }
    });
  }

  // Add client to SSE manager
  const clientId = sseManager.addClient(res, progressType, {
    sendHistory,
    heartbeat
  });

  console.log(`SSE client connected: ${clientId} (type: ${progressType})`);
});

export default router;
