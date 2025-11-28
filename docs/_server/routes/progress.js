/**
 * Progress Routes
 * Express routes for progress data handling with SSE integration
 */

import express from 'express';
import { promises as fs } from 'fs';
import path from 'path';
import { progressTypeDetector, validateSpecificProgressType as _validateSpecificProgressType, dataTransformer, validateProgressData } from '../middleware/index.js';
import { inputValidator } from '../middleware/input-validator.js';
import sseManager from '../utils/sse-manager.js';
import {
  saveProgressData,
  loadProgressData,
  getProgressSyncStatus,
  getLatestProgressFile,
  listProgressFiles,
  getProgressDir
} from '../utils/progress-operations.js';
import learningPathParser from '../utils/learning-path-parser.js';
import pathProgressCalculator from '../utils/path-progress-calculator.js';
import { rebuildManifest } from '../services/learning-path-manifest.js';
import { calculateCompletion } from '../utils/completion-calculator.js';

const router = express.Router();

/**
 * Build paths array with progress calculations
 * @param {Array} descriptors - Path descriptors from manifest
 * @param {Object} kataProgressMap - Map of kata IDs to progress data
 * @returns {Array} Array of path objects with calculated progress
 */
function buildPathsArray(descriptors, kataProgressMap) {
  return descriptors.map(descriptor => {
    const kataIds = descriptor.steps
      .filter(step => step.type === 'kata')
      .map(step => step.id);

    let pathProgress;
    try {
      pathProgress = pathProgressCalculator.calculatePathProgress(
        kataIds,
        kataProgressMap
      );
    } catch (calcError) {
      console.warn(`Error calculating progress for path ${descriptor.id}:`, calcError.message);
      // Return safe defaults on error
      pathProgress = { percentage: 0, completed: 0, total: kataIds.length };
    }

    return {
      id: descriptor.id,
      title: descriptor.title,
      progress: {
        percentage: pathProgress.percentage,
        completed: pathProgress.completed,
        total: pathProgress.total
      }
    };
  });
}

/**
 * Get aggregated progress data for all katas and paths
 * GET /api/progress
 * Used by catalog-hydration.js to display progress badges
 * @returns {Object} Response with progressData array
 * @returns {Array<Object>} progressData - Array of progress items
 * @returns {string} progressData[].type - 'kata' or 'path'
 * @returns {string} progressData[].pageId - Unique identifier for the kata or path
 * @returns {number} progressData[].completionPercentage - Completion percentage (0-100)
 * @returns {Array<Object>} progressData[].items - Array of completion items
 */
router.get('/',
  inputValidator(),
  async (req, res) => {
    try {
      const progressDir = getProgressDir();
      const fileList = await listProgressFiles();

      // Filter to only kata and path progress (exclude self-assessments)
      const relevantFiles = fileList.filter(file =>
        file.type === 'kata-progress' || file.type === 'lab-progress'
      );

      // Read and aggregate all kata progress data
      const kataProgressPromises = relevantFiles.map(async (fileInfo) => {
        try {
          const filePath = path.join(progressDir, fileInfo.filename);
          const content = await fs.readFile(filePath, 'utf-8');
          const progressData = JSON.parse(content);

          // Extract kata/lab ID from metadata
          const id = progressData.metadata?.kataId || progressData.metadata?.labId || fileInfo.id || '';

          // Calculate progress from checkboxStates
          const checkboxStates = progressData.progress?.checkboxStates || {};
          const { percentage: completionPercentage } = calculateCompletion(checkboxStates);

          return {
            id,
            completionPercentage
          };
        } catch (fileError) {
          console.warn(`Error reading progress file ${fileInfo.filename}:`, fileError.message);
          return null;
        }
      });

      const kataProgressArray = await Promise.all(kataProgressPromises);
      const katas = kataProgressArray.filter(data => data !== null);

      // Build kata progress map for path calculation
      const kataProgressMap = {};
      katas.forEach(kata => {
        kataProgressMap[kata.id] = {
          completionPercentage: kata.completionPercentage
        };
      });

      // Get learning path manifest and build paths array
      let manifest;
      try {
        manifest = await rebuildManifest({ validate: false });
      } catch (manifestError) {
        console.error('Error loading learning path manifest:', manifestError.message);
        return res.status(500).json({
          success: false,
          error: 'Failed to load learning path manifest',
          details: process.env.NODE_ENV === 'development' ? manifestError.message : undefined
        });
      }
      const paths = buildPathsArray(manifest.descriptors, kataProgressMap);

      // Transform into progressData array format expected by frontend
      const progressData = [
        ...katas.map(kata => ({
          type: 'kata',
          pageId: kata.id,
          completionPercentage: kata.completionPercentage,
          items: [] // Frontend calculates items from checkboxStates
        })),
        ...paths.map(pathInfo => ({
          type: 'path',
          pageId: pathInfo.id.replace(/^paths-/, 'path-'), // Convert paths- to path- for frontend
          completionPercentage: pathInfo.progress.percentage,
          items: Array(pathInfo.progress.total).fill(null).map((_, idx) => ({
            completed: idx < pathInfo.progress.completed
          }))
        }))
      ];

      res.json({
        progressData
      });
    } catch (error) {
      console.error('Error aggregating progress data:', error);

      res.status(500).json({
        success: false,
        error: 'Failed to aggregate progress data',
        details: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
      });
    }
  }
);

/**
 * Debug endpoint to check path calculation
 * GET /api/progress/debug-path
 */
router.get('/debug-path', (req, res) => {
  try {
    const progressDir = getProgressDir();
    res.json({
      success: true,
      data: {
        progressDir,
        processEnv: process.env.PROGRESS_DIR || 'not set',
        cwd: process.cwd(),
        moduleUrl: import.meta.url
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Save progress data
 * POST /api/progress/save
 */
router.post('/save',
  dataTransformer({ autoTransform: true }),
  validateProgressData(),
  progressTypeDetector({ required: true, attachMetadata: true }),
  async (req, res) => {
    try {
      const progressData = req.body;
      const progressType = req.progressType;
      const progressMetadata = req.progressMetadata;

      console.log(`[Express] Save endpoint - received data:`, {
        type: progressType,
        originalKeys: Object.keys(req.body),
        transformedKeys: Object.keys(progressData),
        hasMetadata: !!progressData.metadata,
        hasAssessment: !!progressData.assessment
      });

      // Save progress data using utility function
      const result = await saveProgressData(progressData, progressType);

      // Broadcast save event via SSE
      sseManager.broadcastToProgressType(progressType, {
        type: 'progress-saved',
        data: {
          filename: result.filename,
          type: progressType,
          metadata: progressMetadata,
          timestamp: new Date().toISOString()
        }
      });

      res.json({
        success: true,
        data: {
          filename: result.filename,
          type: progressType,
          metadata: progressMetadata,
          message: 'Progress saved successfully'
        }
      });
    } catch(_error) {
      console.error('Error saving progress:', _error);

      // Broadcast error event via SSE
      sseManager.broadcastToProgressType(req.progressType || 'unknown', {
        type: 'progress-error',
        data: {
          error: _error.message,
          action: 'save',
          timestamp: new Date().toISOString()
        }
      });

      // Return appropriate status code based on error type
      const statusCode = _error.type === 'validation' ? 400 : 500;
      const errorMessage = _error.type === 'validation' ? 'Invalid progress data' : 'Failed to save progress';

      res.status(statusCode).json({
        success: false,
        error: errorMessage,
        details: _error.message,
        validationErrors: _error.type === 'validation' ? _error.details : undefined
      });
    }
  }
);

/**
 * Load progress data by type and ID
 * GET /api/progress/load/:type/:id
 */
/**
 * Load progress data by type and ID
 * GET /api/progress/load/:type/:id
 */
router.get('/load/:type/:id',
  inputValidator({ sanitizeParams: true }),
  progressTypeDetector({ required: false }),
  async (req, res) => {
  try {
    const { type, id } = req.params;

    // Load progress data using utility function
    const result = await loadProgressData(type, id);

    // Broadcast load event via SSE
    sseManager.broadcastToProgressType(type, {
      type: 'progress-loaded',
      data: {
        filename: result.filename,
        type,
        id,
        timestamp: new Date().toISOString()
      }
    });

    // Return appropriate progress structure based on type
    // For kata/lab: nested progress.progress contains the actual progress data
    // For self-assessment: assessment is at root level
    const progressData = (result.type === 'self-assessment' || result.type === 'path-progress')
      ? result.progress
      : result.progress.progress;

    res.json({
      success: true,
      data: {
        progress: progressData,
        metadata: {
          ...result.progress.metadata,
          filename: result.filename,
          type: result.type,
          id: result.id,
          loadedAt: new Date().toISOString(),
          validation: result.validation
        }
      }
    });
  } catch(_error) {
    console.error('Error loading progress:', _error);

    // Handle specific error types
    if (_error.message.includes('Invalid progress type')) {
      return res.status(400).json({
        success: false,
        error: 'Invalid progress type',
        details: _error.message
      });
    }

    if (_error.message.includes('Progress not found')) {
      return res.status(404).json({
        success: false,
        error: 'Progress not found',
        details: _error.message
      });
    }

    res.status(500).json({
      success: false,
      error: 'Failed to load progress',
      details: process.env.NODE_ENV === 'development' ? _error.message : 'Internal server error'
    });
  }
});

/**
 * Get progress sync status
 * GET /api/progress/sync-status
 */
router.get('/sync-status',
  inputValidator({ sanitizeQuery: true }),
  async (req, res) => {
  try {
    const { type } = req.query;

    // Get SSE client stats
    const sseStats = sseManager.getClientStats();

    // Get progress sync status using utility function
    const progressStatus = await getProgressSyncStatus(type);

    res.json({
      success: true,
      data: {
        sync: {
          totalFiles: progressStatus.totalFiles,
          totalClients: sseStats.totalClients,
          clientsByType: sseStats.clientsByType,
          uptime: sseStats.uptime
        },
        ...(progressStatus.typeStats && { typeStats: {
          ...progressStatus.typeStats,
          clients: sseManager.getClientCountByType(type)
        }})
      }
    });
  } catch(_error) {
    console.error('Error getting sync status:', _error);

    res.status(500).json({
      success: false,
      error: 'Failed to get sync status',
      details: process.env.NODE_ENV === 'development' ? _error.message : 'Internal server error'
    });
  }
});

/**
 * Sync progress data (manual sync trigger)
 * POST /api/progress/sync
 */
router.post('/sync',
  inputValidator({ sanitizeBody: true }),
  async (req, res) => {
  try {
    const { type } = req.body;

    // Broadcast sync event
    const syncEvent = {
      type: 'sync-triggered',
      data: {
        progressType: type || 'all',
        timestamp: new Date().toISOString(),
        trigger: 'manual'
      }
    };

    if (type) {
      sseManager.broadcastToProgressType(type, syncEvent);
    } else {
      sseManager.broadcastToAll(syncEvent);
    }

    res.json({
      success: true,
      data: {
        message: 'Sync triggered',
        type: type || 'all',
        clients: type ? sseManager.getClientCountByType(type) : sseManager.getActiveClientCount()
      }
    });
  } catch(_error) {
    console._error('_error triggering sync:', _error);

    res.status(500).json({
      success: false,
      _error: 'Failed to trigger sync',
      details: process.env.NODE_ENV === 'development' ? _error.message : 'Internal server _error'
    });
  }
});

/**
 * Get latest progress file (for polling compatibility)
 * GET /api/progress/latest
 */
router.get('/latest',
  inputValidator({ sanitizeQuery: true }),
  async (req, res) => {
  try {
    const result = await getLatestProgressFile();

    res.json({
      success: true,
      filename: result.filename,
      data: {
        metadata: result.metadata,
        timestamp: result.timestamp,
        modified: result.modified
      }
    });
  } catch(_error) {
    console._error('_error getting latest progress:', _error);

    if (_error.message.includes('No progress files found')) {
      return res.status(404).json({
        success: false,
        _error: 'No progress files found'
      });
    }

    res.status(500).json({
      success: false,
      _error: 'Failed to get latest progress',
      details: process.env.NODE_ENV === 'development' ? _error.message : 'Internal server _error'
    });
  }
});

/**
 * List all progress files (for compatibility)
 * GET /api/progress/list
 */
router.get('/list',
  inputValidator({ sanitizeQuery: true }),
  async (req, res) => {
  try {
    const fileList = await listProgressFiles();

    res.json({
      success: true,
      files: fileList,
      total: fileList.length
    });
  } catch(_error) {
    console._error('_error listing progress files:', _error);

    res.status(500).json({
      success: false,
      _error: 'Failed to list progress files',
      details: process.env.NODE_ENV === 'development' ? _error.message : 'Internal server _error'
    });
  }
});

export default router;
