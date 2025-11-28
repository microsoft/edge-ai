/**
 * Learning Paths API Routes
 * Handles saving and managing user learning paths from assessments
 */

import express from 'express';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import { validateProgress } from '../schemas/index.js';
import { rebuildManifest } from '../services/learning-path-manifest.js';
import Ajv from 'ajv';
import addFormats from 'ajv-formats';

const router = express.Router();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Learning paths storage directory - use PROGRESS_DIR env var if set (for testing)
const LEARNING_PATHS_DIR = process.env.PROGRESS_DIR || path.join(__dirname, '..', '..', '..', '.copilot-tracking', 'learning');

// Path ID prefix for identifying learning path items
const PATH_PREFIX = 'path';

// Initialize schema validator
const ajv = new Ajv({ allErrors: true, verbose: true });
addFormats(ajv);

// Load schema for learning path save requests
let saveRequestSchema = null;
async function loadSaveRequestSchema() {
  if (!saveRequestSchema) {
    try {
      const schemaPath = path.join(__dirname, '..', 'schemas', 'learning-path-save-request-schema.json');
      const schemaContent = await fs.readFile(schemaPath, 'utf8');
      const schema = JSON.parse(schemaContent);
      saveRequestSchema = ajv.compile(schema);
    } catch (error) {
      console.warn('Failed to load learning path save request schema:', error.message);
      saveRequestSchema = () => ({ valid: true }); // Fallback
    }
  }
  return saveRequestSchema;
}

/**
 * Ensure learning paths directory exists
 */
async function ensureLearningPathsDirectory() {
  try {
    await fs.access(LEARNING_PATHS_DIR);
  } catch {
    await fs.mkdir(LEARNING_PATHS_DIR, { recursive: true });
  }
}

/**
 * Build file path for learning catalog selections
 * @param {string} userId - User identifier
 * @returns {string} Absolute file path
 */
function getSelectionsFilePath(userId) {
  const filename = `learning-catalog-selections-${userId}.json`;
  return path.join(LEARNING_PATHS_DIR, filename);
}

/**
 * Validate selectedItems array
 * @param {*} selectedItems - Value to validate
 * @returns {{ valid: boolean, error?: string }} Validation result
 */
function validateSelectedItems(selectedItems) {
  if (selectedItems === undefined) {
    return { valid: false, error: 'selectedItems field is required' };
  }
  if (!Array.isArray(selectedItems)) {
    return { valid: false, error: 'selectedItems must be an array' };
  }
  return { valid: true };
}

/**
 * Build selections data structure for storage
 * @param {Array} selectedItems - Array of selected item IDs
 * @param {string} userId - User identifier
 * @param {string} timestamp - ISO timestamp
 * @returns {Object} Selections data structure
 */
function buildSelectionsData(selectedItems, userId, timestamp) {
  return {
    metadata: {
      version: '1.0.0',
      fileType: 'learning-catalog-selections',
      userId,
      lastUpdated: timestamp
    },
    selections: {
      selectedItems,
      selectionCount: selectedItems.length
    },
    timestamp,
    integrationData: {
      syncMetadata: {
        lastSync: timestamp,
        syncSource: 'progress-server'
      }
    }
  };
}

/**
 * Build API response for POST selections (save operation)
 * @param {Array} selectedItems - Array of selected item IDs
 * @param {string} userId - User identifier
 * @param {string} timestamp - ISO timestamp
 * @returns {Object} API response data
 */
function buildSaveSelectionsResponse(selectedItems, userId, timestamp) {
  return {
    success: true,
    data: {
      selectionCount: selectedItems.length,
      selections: {
        selectedItems
      },
      userId,
      timestamp
    }
  };
}

/**
 * Build API response for GET selections (retrieve operation)
 * @param {Array} selectedItems - Array of selected item IDs
 * @param {string} userId - User identifier
 * @param {string} lastUpdated - ISO timestamp
 * @returns {Object} API response data
 */
function buildGetSelectionsResponse(selectedItems, userId, lastUpdated) {
  return {
    success: true,
    data: {
      selections: {
        selectedItems,
        selectionCount: selectedItems.length
      },
      userId,
      lastUpdated
    }
  };
}

/**
 * Expand path IDs to include their constituent kata IDs
 *
 * Takes an array of selected item IDs (which may include paths, katas, labs)
 * and expands any path IDs to include all their constituent kata IDs.
 * Non-path items and non-kata steps (labs, challenges) are preserved as-is.
 * Deduplicates kata IDs using Set.
 *
 * @param {Array<string>} selectedItems - Array with path and/or kata IDs
 * @returns {Array<string>} Expanded array with katas from paths (deduplicated)
 */
async function expandPathsToKatas(selectedItems) {
  try {
    const manifest = await rebuildManifest(false);

    if (!manifest?.descriptors) {
      console.warn('[expandPathsToKatas] Manifest has no descriptors, returning items as-is');
      return selectedItems;
    }

    const pathDescriptors = new Map(
      manifest.descriptors.map(d => [d.id, d])
    );
    const expandedSet = new Set(selectedItems);

    for (const itemId of selectedItems) {
      if (itemId.startsWith(PATH_PREFIX)) {
        const descriptor = pathDescriptors.get(itemId);
        if (descriptor?.steps) {
          descriptor.steps
            .filter(step => step.type === 'kata')
            .forEach(step => expandedSet.add(step.id));
        }
      }
    }

    return Array.from(expandedSet);
  } catch (error) {
    console.error('[expandPathsToKatas] Error during expansion:', error);
    return selectedItems;
  }
}

/**
 * Save learning path from assessment
 * POST /api/learning/save
 */
router.post('/save', async (req, res) => {
  try {
    await ensureLearningPathsDirectory();

    // Validate request against schema
    const validator = await loadSaveRequestSchema();
    const isValid = validator(req.body);

    if (!isValid && validator.errors) {
      return res.status(400).json({
        success: false,
        error: 'Invalid request data',
        validationErrors: validator.errors.map(err => ({
          field: err.instancePath || err.dataPath,
          message: err.message,
          value: err.data
        }))
      });
    }

    const {
      userId = 'default-user',
      pathType = 'assessment-recommended',
      assessmentResults,
      recommendations,
      timestamp = new Date().toISOString(),
      metadata
    } = req.body;

    // Validate required data (additional check)
    if (!assessmentResults) {
      return res.status(400).json({
        success: false,
        error: 'Assessment results are required'
      });
    }

    // Create learning path data
    const learningPath = {
      id: `learning-path-${Date.now()}`,
      userId,
      pathType,
      assessmentResults,
      recommendations,
      timestamp,
      metadata: metadata || {},
      status: 'active',
      progress: {
        completed: 0,
        total: 0,
        lastUpdated: timestamp
      },
      validatedAt: new Date().toISOString(),
      schemaVersion: '1.0.0'
    };

    // Save to file
    const filename = `${userId}-${pathType}-${Date.now()}.json`;
    const filepath = path.join(LEARNING_PATHS_DIR, filename);

    await fs.writeFile(filepath, JSON.stringify(learningPath, null, 2));

    // Also maintain a latest file for easy access
    const latestFilepath = path.join(LEARNING_PATHS_DIR, `${userId}-latest.json`);
    await fs.writeFile(latestFilepath, JSON.stringify(learningPath, null, 2));

    console.log(`Learning path saved: ${filename}`);

    res.json({
      success: true,
      data: {
        id: learningPath.id,
        pathType: learningPath.pathType,
        savedAt: timestamp,
        filepath: filename
      }
    });

  } catch (error) {
    console.error('Error saving learning path:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to save learning path',
      details: error.message
    });
  }
});

/**
 * Manifest Route
 * Serves the latest learning path manifest JSON.
 * If manifest doesn't exist, triggers rebuild.
 */
router.get('/manifest', async (req, res) => {
  try {
    // Import dependencies dynamically
    const { rebuildManifest } = await import('../services/learning-path-manifest.js');
    const { broadcastManifestUpdate } = await import('../utils/sse-manager.js');

    // Rebuild manifest (no parameters needed - service handles paths internally)
    const manifest = await rebuildManifest({ validate: false });

    // Broadcast update to connected clients
    broadcastManifestUpdate({ reason: 'manifest-rebuilt' });

    // Return with no-cache headers
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.json({
      success: true,
      ...manifest,
      errors: manifest.errors || []
    });
  } catch (err) {
    console.error('Error serving manifest:', err);
    res.status(500).json({
      success: false,
      error: 'Failed to generate manifest',
      details: err.message
    });
  }
});

/**
 * Save selected catalog items for unified learning catalog
 *
 * Accepts an array of item IDs from the learning catalog (katas, paths, labs)
 * and persists them to a per-user JSON file. Overwrites previous selections.
 *
 * @route POST /api/learning/selections
 * @param {string} req.body.userId - User identifier (defaults to 'default-user')
 * @param {Array<string>} req.body.selectedItems - Array of selected item IDs
 * @returns {Object} 200 - Selection saved successfully with metadata
 * @returns {Object} 400 - Invalid request (missing or non-array selectedItems)
 * @returns {Object} 500 - Server error during file operation
 *
 * @example Request body:
 * {
 *   "userId": "user-123",
 *   "selectedItems": ["kata-01", "path-02", "lab-03"]
 * }
 *
 * IMPORTANT: This route must come BEFORE /:userId to avoid conflict
 */
router.post('/selections', async (req, res) => {
  try {
    await ensureLearningPathsDirectory();

    const { selectedItems, userId = 'default-user' } = req.body;

    const validation = validateSelectedItems(selectedItems);
    if (!validation.valid) {
      return res.status(400).json({
        success: false,
        error: validation.error
      });
    }

    const timestamp = new Date().toISOString();
    const expandedItems = await expandPathsToKatas(selectedItems);
    const selectionsData = buildSelectionsData(expandedItems, userId, timestamp);
    const filepath = getSelectionsFilePath(userId);

    await fs.writeFile(filepath, JSON.stringify(selectionsData, null, 2));

    console.log(`Learning catalog selections saved: ${path.basename(filepath)}`);

    res.json(buildSaveSelectionsResponse(expandedItems, userId, timestamp));

  } catch (error) {
    console.error('Error saving learning catalog selections:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to save learning catalog selections',
      details: error.message
    });
  }
});

/**
 * Get selected catalog items for user
 *
 * Retrieves the user's saved learning catalog selections. Returns an empty
 * array if no selections exist for the user.
 *
 * @route GET /api/learning/selections
 * @queryparam {string} userId - User identifier (defaults to 'default-user')
 * @returns {Object} 200 - User selections with metadata (or empty array if none)
 * @returns {Object} 500 - Server error during file operation
 *
 * @example Response for existing selections:
 * {
 *   "success": true,
 *   "data": {
 *     "selections": {
 *       "selectedItems": ["kata-01", "path-02"],
 *       "selectionCount": 2
 *     },
 *     "userId": "user-123",
 *     "lastUpdated": "2025-10-21T15:30:00.000Z"
 *   }
 * }
 *
 * IMPORTANT: This route must come BEFORE /:userId to avoid conflict
 */
router.get('/selections', async (req, res) => {
  try {
    await ensureLearningPathsDirectory();

    const { userId = 'default-user' } = req.query;
    const filepath = getSelectionsFilePath(userId);

    try {
      const content = await fs.readFile(filepath, 'utf8');
      const selectionsData = JSON.parse(content);

      res.json(
        buildGetSelectionsResponse(
          selectionsData.selections.selectedItems,
          selectionsData.metadata.userId,
          selectionsData.metadata.lastUpdated
        )
      );
    } catch (error) {
      res.json(buildGetSelectionsResponse([], userId, null));
    }

  } catch (error) {
    console.error('Error retrieving learning catalog selections:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to retrieve learning catalog selections',
      details: error.message
    });
  }
});

/**
 * Get selected learning paths for a user
 * GET /api/learning/selections?userId=<userId>
 *
 * IMPORTANT: This route must come BEFORE /:userId to avoid conflict
 */
/**
 * Get user's learning paths
 * GET /api/learning/:userId
 */
router.get('/:userId', async (req, res) => {
  try {
    await ensureLearningPathsDirectory();

    const { userId } = req.params;

    // Get all files for this user
    const files = await fs.readdir(LEARNING_PATHS_DIR);
    const userFiles = files.filter(file => file.startsWith(`${userId}-`) && file.endsWith('.json'));

    const learningPaths = [];

    for (const file of userFiles) {
      try {
        const content = await fs.readFile(path.join(LEARNING_PATHS_DIR, file), 'utf8');
        const learningPath = JSON.parse(content);
        learningPaths.push(learningPath);
      } catch (error) {
        console.warn(`Error reading learning path file ${file}:`, error);
      }
    }

    // Sort by timestamp (newest first)
    learningPaths.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    res.json({
      success: true,
      data: {
        userId,
        learningPaths,
        count: learningPaths.length
      }
    });

  } catch (error) {
    console.error('Error retrieving learning paths:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to retrieve learning paths',
      details: error.message
    });
  }
});

/**
 * Get latest learning path for user
 * GET /api/learning/:userId/latest
 */
router.get('/:userId/latest', async (req, res) => {
  try {
    await ensureLearningPathsDirectory();

    const { userId } = req.params;
    const latestFilepath = path.join(LEARNING_PATHS_DIR, `${userId}-latest.json`);

    try {
      const content = await fs.readFile(latestFilepath, 'utf8');
      const learningPath = JSON.parse(content);

      res.json({
        success: true,
        data: learningPath
      });
    } catch (error) {
      res.status(404).json({
        success: false,
        error: 'No learning paths found for user',
        userId
      });
    }

  } catch (error) {
    console.error('Error retrieving latest learning path:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to retrieve latest learning path',
      details: error.message
    });
  }
});

/**
 * Update learning path progress
 * PATCH /api/learning/:id/progress
 */
router.patch('/:id/progress', async (req, res) => {
  try {
    await ensureLearningPathsDirectory();

    const { id } = req.params;
    const { completed, total, notes } = req.body;

    // Find the learning path file
    const files = await fs.readdir(LEARNING_PATHS_DIR);
    let foundFile = null;

    for (const file of files) {
      try {
        const content = await fs.readFile(path.join(LEARNING_PATHS_DIR, file), 'utf8');
        const learningPath = JSON.parse(content);
        if (learningPath.id === id) {
          foundFile = file;
          break;
        }
      } catch (error) {
        console.warn(`Error reading file ${file}:`, error);
      }
    }

    if (!foundFile) {
      return res.status(404).json({
        success: false,
        error: 'Learning path not found',
        id
      });
    }

    // Update the learning path
    const filepath = path.join(LEARNING_PATHS_DIR, foundFile);
    const content = await fs.readFile(filepath, 'utf8');
    const learningPath = JSON.parse(content);

    learningPath.progress = {
      completed: completed ?? learningPath.progress.completed,
      total: total ?? learningPath.progress.total,
      lastUpdated: new Date().toISOString(),
      notes: notes || learningPath.progress.notes
    };

    await fs.writeFile(filepath, JSON.stringify(learningPath, null, 2));

    res.json({
      success: true,
      data: learningPath.progress
    });

  } catch (error) {
    console.error('Error updating learning path progress:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update learning path progress',
      details: error.message
    });
  }
});

export default router;
