#!/usr/bin/env node

import http from 'http';
import fs from 'fs/promises';
import fsSync from 'fs'; // Keep for file watching
import path from 'path';
import { fileURLToPath } from 'url';
import {
  fileExists,
  readJsonFile,
  writeJsonFile,
  listFiles,
  getFileStats,
  ensureDirectory,
  readMultipleJsonFiles as _readMultipleJsonFiles,
  getFilesWithMetadata as _getFilesWithMetadata,
  withRetry as _withRetry,
  batchOperation as _batchOperation
} from './utils/async-file-utils.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PORT = 3002;
const PROGRESS_DIR = path.join(__dirname, '..', '..', '.copilot-tracking', 'learning');

// Load schemas for validation - now async
const SCHEMAS = {};

async function loadSchema(filename) {
  try {
    const schemaPath = path.join(__dirname, 'schemas', filename);
    if (await fileExists(schemaPath)) {
      return await readJsonFile(schemaPath);
    }
    console.warn(`Schema file not found: ${schemaPath}`);
    return null;
  } catch(_error) {
    console.error(`Error loading schema ${filename}:`, _error);
    return null;
  }
}

// Initialize schemas asynchronously
async function initializeSchemas() {
  SCHEMAS['self-assessment'] = await loadSchema('self-assessment-schema.json');
  SCHEMAS['kata-progress'] = null; // Add if needed later
}

// Configuration for save strategy
const SAVE_CONFIG = {
  strategy: 'update-per-kata', // 'update-per-kata' | 'snapshot-always' | 'timed-snapshots'
  snapshotInterval: 30 * 60 * 1000, // 30 minutes for timed snapshots
  maxFilesPerKata: 5 // Keep max 5 files per kata for history
};

// Validation function using JSON schema
function validateData(data, schemaType) {
  const schema = SCHEMAS[schemaType];
  if (!schema) {
    console.warn(`No schema available for type: ${schemaType}`);
    return { isValid: true, error: null }; // Allow if no schema
  }

  // Basic validation - check required fields
  if (schemaType === 'self-assessment') {
    if (!data.metadata || !data.assessment || !data.timestamp) {
      return {
        isValid: false,
        error: 'Missing required fields: metadata, assessment, timestamp'
      };
    }

    // Validate metadata fields
    if (!data.metadata.version || !data.metadata.assessmentId || !data.metadata.source || !data.metadata.fileType) {
      return {
        isValid: false,
        error: 'Missing required metadata fields'
      };
    }

    // Validate assessment structure
    if (!data.assessment.responses && !data.assessment.questions) {
      return {
        isValid: false,
        error: 'Assessment must have responses or questions'
      };
    }
  }

  return { isValid: true, error: null };
}

// Determine file type from data
function getFileType(data) {
  if (data.metadata?.fileType) {
    return data.metadata.fileType;
  }
  if (data.metadata?.type === 'self-assessment') {
    return 'self-assessment';
  }
  if (data.metadata?.kataId || data.kataId) {
    return 'kata-progress';
  }
  return 'unknown';
}

// Generate filename based on file type
function generateFilename(data, fileType) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

  switch (fileType) {
    case 'self-assessment': {
      const assessmentId = data.metadata?.assessmentId || 'skill-assessment';
      const userId = data.metadata?.userId || 'user';
      return `self-assessment-${assessmentId}-${userId}-${timestamp}.json`;
    }

    case 'kata-progress': {
      const rawKataId = data.metadata?.kataId || data.kataId || 'unknown-kata';
      const kataId = rawKataId.replace(/\//g, '_');
      return `kata-progress-${kataId}-${timestamp}.json`;
    }

    default:
      return `progress-${timestamp}.json`;
  }
}

// Find existing files for update strategy - now async
async function findExistingFiles(identifier, fileType) {
  const files = await listFiles(PROGRESS_DIR, file => file.endsWith('.json'));

  switch (fileType) {
    case 'self-assessment':
      return files.filter(file =>
        file.startsWith('self-assessment-') && file.includes(identifier)
      );

    case 'kata-progress':
      return files.filter(file =>
        file.startsWith('kata-progress-') && file.includes(identifier)
      );

    default:
      return [];
  }
}

// Store active SSE connections for file change notifications
const sseConnections = new Set();

// File change notification function
function notifyFileChange(filename, eventType, source) {
  const timestamp = new Date().toISOString();

  // Notify all SSE connections
  sseConnections.forEach(connection => {
    if (connection.readyState === connection.OPEN) {
      try {
        connection.write(`data: ${JSON.stringify({
          type: 'file-change',
          filename: filename,
          eventType: eventType,
          source: source,
          timestamp: timestamp
        })}\n\n`);
      } catch(_error) {
        console.error('Error sending SSE notification:', _error);
        sseConnections.delete(connection);
      }
    } else {
      sseConnections.delete(connection);
    }
  });
}

// Enhanced file synchronization function - now async
async function syncFileChange(filename, eventType) {
  try {
    const filePath = path.join(PROGRESS_DIR, filename);

    // Only process JSON files
    if (!filename.endsWith('.json')) {
      return;
    }

    if (eventType === 'change' && await fileExists(filePath)) {
      const data = await readJsonFile(filePath);
      if (!data) {return;} // Failed to read file

      // Update sync metadata
      if (!data.integrationData) {
        data.integrationData = {};
      }
      if (!data.integrationData.syncMetadata) {
        data.integrationData.syncMetadata = {};
      }
      data.integrationData.syncMetadata.lastSync = new Date().toISOString();
      data.integrationData.syncMetadata.syncSource = 'file-watcher';

      // Write back with updated sync metadata
      await writeJsonFile(filePath, data);

    }
  } catch(_error) {
    console.error(`Error synchronizing file ${filename}:`, _error);
  }
}

// File watcher for the progress directory
let fileWatcher = null;

// Setup file watcher for the progress directory
function setupFileWatcher() {
  if (fileWatcher) {
    fileWatcher.close();
  }

  // Method 1: Try fs.watch (may not work reliably in containers)
  try {
    fileWatcher = fsSync.watch(PROGRESS_DIR, (eventType, filename) => {
      if (filename && filename.endsWith('.json')) {
        notifyFileChange(filename, eventType, 'fs.watch');
        // Call async function but don't await (fire and forget)
        syncFileChange(filename, eventType).catch(error => {
          console.error('Error in async syncFileChange:', error);
        });
      }
    });
  } catch(_error) {
    console.warn('fs.watch failed, using polling only:', _error.message);
  }

  // Method 2: Backup polling mechanism for container environments
  setInterval(() => {
    checkForNewFiles().catch(error => {
      console.error('Error in checkForNewFiles:', error);
    });
  }, 5000); // Check every 5 seconds

}

// Track last check time for polling
let lastFileCheckTime = Date.now();

async function checkForNewFiles() {
  try {
    const files = await listFiles(PROGRESS_DIR);

    await Promise.all(
      files
        .filter(file => file.endsWith('.json'))
        .map(async (file) => {
          const filePath = path.join(PROGRESS_DIR, file);
          const stats = await getFileStats(filePath);

          if (stats && stats.mtime.getTime() > lastFileCheckTime) {
            notifyFileChange(file, 'change', 'polling');
            // Fire and forget async sync
            syncFileChange(file, 'change').catch(error => {
              console.error(`Error syncing file ${file}:`, error);
            });
          }
        })
    );

    lastFileCheckTime = Date.now();
  } catch(_error) {
    console.error('Error during file polling check:', _error);
  }
}

async function cleanupOldFiles(identifier, fileType) {
  try {
    if (SAVE_CONFIG.strategy === 'snapshot-always') {
      return; // Don't cleanup if always creating snapshots
    }

    const existingFiles = await findExistingFiles(identifier, fileType);

    // Get file stats for all existing files
    const filesWithStats = await Promise.all(
      existingFiles.map(async (file) => {
        const filePath = path.join(PROGRESS_DIR, file);
        const stats = await getFileStats(filePath);
        return {
          name: file,
          path: filePath,
          mtime: stats ? stats.mtime : new Date(0)
        };
      })
    );

    // Sort by modification time, most recent first
    const sortedFiles = filesWithStats
      .filter(file => file.mtime)
      .sort((a, b) => b.mtime - a.mtime);

    // Keep only the most recent files
    if (sortedFiles.length > SAVE_CONFIG.maxFilesPerKata) {
      const filesToDelete = sortedFiles.slice(SAVE_CONFIG.maxFilesPerKata);

      await Promise.all(
        filesToDelete.map(async (file) => {
          try {
            await fs.unlink(file.path);
          } catch (deleteError) {
            console.error(`Error deleting file ${file.name}:`, deleteError);
          }
        })
      );
    }
  } catch(_error) {
    console.error(`Error during cleanup for ${fileType}:`, _error);
  }
}

// Ensure progress directory exists
async function ensureProgressDirectory() {
  await ensureDirectory(PROGRESS_DIR);
}

// Initialize application
async function initializeApp() {
  await initializeSchemas();
  await ensureProgressDirectory();
  setupFileWatcher();
  startServer();
}

function startServer() {
  console.log('Creating server...');

const server = http.createServer(async (req, res) => {
  console.log(`${req.method} ${req.url}`);

  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  if (req.url === '/api/progress/save' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', async () => {
      try {
        console.log('Received POST body:', body);
        const data = JSON.parse(body);
        console.log('Parsed data:', JSON.stringify(data, null, 2));

        // Determine file type
        const fileType = getFileType(data);
        console.log('Detected file type:', fileType);

        // Validate data based on type
        const validation = validateData(data, fileType);
        if (!validation.isValid) {
          console.error('Validation failed:', validation.error);
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            success: false,
            error: `Validation failed: ${validation.error}`
          }));
          return;
        }

        let filename;
        let filepath;
        let identifier;

        // Extract identifier based on file type
        if (fileType === 'self-assessment') {
          identifier = data.metadata?.assessmentId || 'skill-assessment';
        } else if (fileType === 'kata-progress') {
          const rawKataId = data.metadata?.kataId || data.kataId || 'unknown-kata';
          identifier = rawKataId.replace(/\//g, '_');
        } else {
          identifier = 'unknown';
        }

        console.log('Extracted identifier:', identifier);

        if (SAVE_CONFIG.strategy === 'update-per-kata') {
          // Strategy 1: Update same file for same identifier
          const existingFiles = await findExistingFiles(identifier, fileType);

          const sortedFiles = await Promise.all(
            existingFiles.map(async (file) => {
              const stats = await getFileStats(path.join(PROGRESS_DIR, file));
              return { file, mtime: stats.mtime };
            })
          ); const sortedFileNames = sortedFiles
            .sort((a, b) => b.mtime - a.mtime) // Most recent first
            .map(item => item.file);

          if (sortedFileNames.length > 0) {
            filename = sortedFileNames[0];
            filepath = path.join(PROGRESS_DIR, filename);
            console.log(`Updating existing ${fileType} file: ${filename}`);
          } else {
            filename = generateFilename(data, fileType);
            filepath = path.join(PROGRESS_DIR, filename);
            console.log(`Creating new ${fileType} file: ${filename}`);
          }

        } else if (SAVE_CONFIG.strategy === 'timed-snapshots') {
          // Strategy 2: Create snapshots only at intervals
          const existingFiles = await findExistingFiles(identifier, fileType);

          if (existingFiles.length > 0) {
            const filesWithStats = await Promise.all(
              existingFiles.map(async (file) => ({
                name: file,
                mtime: (await getFileStats(path.join(PROGRESS_DIR, file))).mtime
              }))
            );

            const latestFile = filesWithStats.sort((a, b) => b.mtime - a.mtime)[0];

            const timeSinceLastSnapshot = Date.now() - latestFile.mtime.getTime();

            if (timeSinceLastSnapshot < SAVE_CONFIG.snapshotInterval) {
              // Update existing file
              filename = latestFile.name;
              filepath = path.join(PROGRESS_DIR, filename);
              console.log(`Updating recent ${fileType} file: ${filename}`);
            } else {
              // Create new snapshot
              filename = generateFilename(data, fileType);
              filepath = path.join(PROGRESS_DIR, filename);
              console.log(`Creating timed ${fileType} snapshot: ${filename}`);
            }
          } else {
            filename = generateFilename(data, fileType);
            filepath = path.join(PROGRESS_DIR, filename);
            console.log(`Creating initial ${fileType} file: ${filename}`);
          }

        } else {
          // Strategy 3: Always create new files (original behavior)
          filename = generateFilename(data, fileType);
          filepath = path.join(PROGRESS_DIR, filename);
          console.log(`Creating timestamped ${fileType} file: ${filename}`);
        }

        // Update metadata timestamp for tracking
        if (data.metadata) {
          data.metadata.lastUpdated = new Date().toISOString();
        }

        // Add file synchronization metadata
        if (!data.integrationData) {
          data.integrationData = {};
        }
        if (!data.integrationData.syncMetadata) {
          data.integrationData.syncMetadata = {};
        }
        data.integrationData.syncMetadata.lastSync = new Date().toISOString();
        data.integrationData.syncMetadata.syncSource = 'progress-server';

        await writeJsonFile(filepath, data);

        // Cleanup old files if needed
        await cleanupOldFiles(identifier, fileType);

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          message: `${fileType} progress saved successfully`,
          filename: filename,
          timestamp: new Date().toISOString(),
          fileType: fileType
        }));
      } catch(_error) {
        console.error('Error saving progress:', _error);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: false, error: _error.message }));
      }
    });

  } else if (req.method === 'GET' && req.url === '/api/progress/events') {
    // Server-Sent Events endpoint for file change notifications
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Cache-Control'
    });

    // Send initial connection message
    res.write(`data: ${JSON.stringify({
      type: 'connected',
      message: 'File synchronization connected',
      timestamp: new Date().toISOString()
    })}\n\n`);

    // Add connection to the set
    sseConnections.add(res);

    // Handle client disconnect
    req.on('close', () => {
      sseConnections.delete(res);
      console.log('SSE connection closed');
    });

    req.on('aborted', () => {
      sseConnections.delete(res);
      console.log('SSE connection aborted');
    });

    // Keep connection alive with periodic heartbeat
    const heartbeat = setInterval(() => {
      try {
        res.write(`data: ${JSON.stringify({
          type: 'heartbeat',
          timestamp: new Date().toISOString()
        })}\n\n`);
      } catch {
        clearInterval(heartbeat);
        sseConnections.delete(res);
      }
    }, 30000); // 30 second heartbeat

  } else if (req.method === 'GET' && req.url.startsWith('/api/progress/load/kata/')) {
    // Load kata progress by ID
    const kataId = req.url.split('/').pop();
    const sanitizedKataId = kataId.replace(/\//g, '_');

    try {
      const files = await listFiles(PROGRESS_DIR);
      const kataFiles = [];

      for (const file of files.filter(f => f.endsWith('.json') && f.includes(sanitizedKataId))) {
        try {
          const stats = await getFileStats(path.join(PROGRESS_DIR, file));
          kataFiles.push({
            name: file,
            path: path.join(PROGRESS_DIR, file),
            mtime: stats.mtime
          });
        } catch(_error) {
          console.error(`Error getting stats for ${file}:`, _error.message);
        }
      }

      kataFiles.sort((a, b) => b.mtime - a.mtime); // Most recent first

      if (kataFiles.length === 0) {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: false, error: 'No progress found for this kata' }));
        return;
      }

      const latestFile = kataFiles[0];
      const data = await readJsonFile(latestFile.path);

      console.log(`Loaded progress from: ${latestFile.name}`);

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        success: true,
        data: data,
        filename: latestFile.name,
        lastModified: latestFile.mtime
      }));
    } catch(_error) {
      console.error('Error loading kata progress:', _error);
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: false, error: _error.message }));
    }

  } else if (req.method === 'GET' && req.url.startsWith('/api/progress/load/self-assessment/')) {
    // Load self-assessment progress by ID
    const assessmentId = req.url.split('/').pop();
    const sanitizedAssessmentId = assessmentId.replace(/[^a-zA-Z0-9-_]/g, '_');

    try {
      const files = await listFiles(PROGRESS_DIR);
      const assessmentFiles = [];

      for (const file of files.filter(f => f.endsWith('.json') && f.includes(sanitizedAssessmentId) && f.startsWith('self-assessment-'))) {
        try {
          const stats = await getFileStats(path.join(PROGRESS_DIR, file));
          assessmentFiles.push({
            name: file,
            path: path.join(PROGRESS_DIR, file),
            mtime: stats.mtime
          });
        } catch(_error) {
          console.error(`Error getting stats for ${file}:`, _error.message);
        }
      }

      assessmentFiles.sort((a, b) => b.mtime - a.mtime); // Most recent first

      if (assessmentFiles.length === 0) {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: false, error: 'No self-assessment progress found' }));
        return;
      }

      const latestFile = assessmentFiles[0];
      const data = await readJsonFile(latestFile.path);

      console.log(`Loaded self-assessment progress from: ${latestFile.name}`);

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        success: true,
        data: data,
        filename: latestFile.name,
        lastModified: latestFile.mtime
      }));
    } catch(_error) {
      console.error('Error loading self-assessment progress:', _error);
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: false, error: _error.message }));
    }

  } else if (req.method === 'GET' && req.url === '/api/progress/list') {
    // List available progress files
    try {
      const allFiles = await listFiles(PROGRESS_DIR);
      const jsonFiles = allFiles.filter(file => file.endsWith('.json'));

      const filesWithDetails = await Promise.all(
        jsonFiles.map(async (file) => {
          const filePath = path.join(PROGRESS_DIR, file);
          const stats = await getFileStats(filePath);
          const data = await readJsonFile(filePath);
          const fileType = getFileType(data);

          return {
            filename: file,
            fileType: fileType,
            created: stats.birthtime,
            modified: stats.mtime,
            size: stats.size,
            metadata: data.metadata || {}
          };
        })
      );

      const files = filesWithDetails.sort((a, b) => b.modified - a.modified); // Most recent first

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, files }));
    } catch(_error) {
      console.error('Error listing progress files:', _error);
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: false, error: _error.message }));
    }

  } else if (req.method === 'GET' && req.url.startsWith('/api/progress/load/')) {
    // Load specific progress file
    const filename = req.url.split('/').pop();
    const filePath = path.join(PROGRESS_DIR, filename);

    try {
      if (!(await fileExists(filePath))) {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: false, error: 'File not found' }));
        return;
      }

      const data = await readJsonFile(filePath);
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, data: data }));
    } catch(_error) {
      console.error('Error loading progress file:', _error);
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: false, error: _error.message }));
    }

  } else if (req.method === 'GET' && req.url === '/api/progress/sync-status') {
    // Get file synchronization status
    try {
      const allFiles = await listFiles(PROGRESS_DIR);
      const jsonFiles = allFiles.filter(file => file.endsWith('.json'));

      const filesWithDetails = await Promise.all(
        jsonFiles.map(async (file) => {
          const filePath = path.join(PROGRESS_DIR, file);
          const stats = await getFileStats(filePath);
          const data = await readJsonFile(filePath);
          const fileType = getFileType(data);

          return {
            filename: file,
            fileType: fileType,
            lastModified: stats.mtime,
            syncMetadata: data.integrationData?.syncMetadata || {},
            hasSync: !!(data.integrationData?.syncMetadata?.lastSync)
          };
        })
      );

      const files = filesWithDetails.sort((a, b) => b.lastModified - a.lastModified);

      const syncStats = {
        totalFiles: files.length,
        syncedFiles: files.filter(f => f.hasSync).length,
        unsyncedFiles: files.filter(f => !f.hasSync).length,
        watcherActive: fileWatcher !== null,
        lastPollTime: lastFileCheckTime,
        files: files
      };

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, syncStatus: syncStats }));
    } catch(_error) {
      console.error('Error getting sync status:', _error);
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: false, error: _error.message }));
    }

  } else if (req.method === 'POST' && req.url === '/api/progress/sync') {
    // Manually trigger file synchronization
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', async () => {
      try {
        const requestData = JSON.parse(body || '{}');
        const filename = requestData.filename;

        if (filename) {
          // Sync specific file
          const filePath = path.join(PROGRESS_DIR, filename);
          if (await fileExists(filePath)) {
            await syncFileChange(filename, 'change');
            notifyFileChange(filename, 'sync', 'manual-trigger');
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({
              success: true,
              message: `File ${filename} synchronized successfully`
            }));
          } else {
            res.writeHead(404, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ success: false, error: 'File not found' }));
          }
        } else {
          // Sync all files
          const allFiles = await listFiles(PROGRESS_DIR);
          const files = allFiles.filter(file => file.endsWith('.json'));
          let syncedCount = 0;

          await Promise.all(files.map(async (file) => {
            try {
              await syncFileChange(file, 'change');
              notifyFileChange(file, 'sync', 'manual-trigger-all');
              syncedCount++;
            } catch(_error) {
              console.error(`Error syncing file ${file}:`, _error);
            }
          }));

          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            success: true,
            message: `${syncedCount} files synchronized successfully`,
            syncedCount: syncedCount,
            totalFiles: files.length
          }));
        }
      } catch(_error) {
        console.error('Error during manual sync:', _error);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: false, error: _error.message }));
      }
    });

  } else if (req.method === 'POST' && req.url === '/api/progress/clear') {
    // Clear progress data endpoint - handles different clear types
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', async () => {
      try {
        const requestData = JSON.parse(body || '{}');
        const { type, kataId, assessmentId } = requestData;

        const deletedFiles = [];
        const allFiles = await listFiles(PROGRESS_DIR);
        const jsonFiles = allFiles.filter(file => file.endsWith('.json'));

        if (type === 'kata' && kataId) {
          // Clear specific kata progress
          const sanitizedKataId = kataId.replace(/\//g, '_');
          const kataFiles = jsonFiles.filter(file =>
            file.startsWith('kata-progress-') && file.includes(sanitizedKataId)
          );

          await Promise.all(kataFiles.map(async (file) => {
            try {
              const filePath = path.join(PROGRESS_DIR, file);
              await fs.unlink(filePath);
              deletedFiles.push(file);
              notifyFileChange(file, 'delete', 'clear-operation');
            } catch (deleteError) {
              console.error(`Error deleting kata file ${file}:`, deleteError);
            }
          }));

        } else if (type === 'assessment' && assessmentId) {
          // Clear specific assessment progress
          const sanitizedAssessmentId = assessmentId.replace(/[^a-zA-Z0-9-_]/g, '_');
          const assessmentFiles = jsonFiles.filter(file =>
            file.startsWith('self-assessment-') && file.includes(sanitizedAssessmentId)
          );

          await Promise.all(assessmentFiles.map(async (file) => {
            try {
              const filePath = path.join(PROGRESS_DIR, file);
              await fs.unlink(filePath);
              deletedFiles.push(file);
              notifyFileChange(file, 'delete', 'clear-operation');
            } catch (deleteError) {
              console.error(`Error deleting assessment file ${file}:`, deleteError);
            }
          }));

        } else if (type === 'all') {
          // Clear all progress data
          await Promise.all(jsonFiles.map(async (file) => {
            try {
              const filePath = path.join(PROGRESS_DIR, file);
              await fs.unlink(filePath);
              deletedFiles.push(file);
              notifyFileChange(file, 'delete', 'clear-all-operation');
            } catch (deleteError) {
              console.error(`Error deleting file ${file}:`, deleteError);
            }
          }));

        } else {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            success: false,
            error: 'Invalid clear request. Must specify type (kata, assessment, or all) and appropriate identifiers'
          }));
          return;
        }

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          message: `Cleared ${deletedFiles.length} progress files`,
          deletedFiles: deletedFiles,
          clearType: type,
          timestamp: new Date().toISOString()
        }));

      } catch (error) {
        console.error('Error during clear operation:', error);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: false, error: error.message }));
      }
    });

  } else if (req.method === 'POST' && req.url === '/api/learning/selections') {
    // Save selected learning paths
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', async () => {
      try {
        const requestData = JSON.parse(body);
        const { selectedPaths, userId = 'default-user' } = requestData;

        if (!Array.isArray(selectedPaths)) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            success: false,
            error: 'selectedPaths must be an array'
          }));
          return;
        }

        // Create selections data structure
        const selectionsData = {
          metadata: {
            version: '1.0.0',
            fileType: 'learning-path-selections',
            userId: userId,
            lastUpdated: new Date().toISOString()
          },
          selections: {
            selectedPaths: selectedPaths,
            selectionCount: selectedPaths.length
          },
          timestamp: new Date().toISOString(),
          integrationData: {
            syncMetadata: {
              lastSync: new Date().toISOString(),
              syncSource: 'progress-server'
            }
          }
        };

        // Use update-per-user strategy (one file per user)
        const filename = `learning-path-selections-${userId}.json`;
        const filepath = path.join(PROGRESS_DIR, filename);

        console.log(`Saving learning path selections for user ${userId}: ${selectedPaths.length} paths selected`);
        await writeJsonFile(filepath, selectionsData);

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          message: 'Learning path selections saved successfully',
          filename: filename,
          selectionCount: selectedPaths.length,
          timestamp: new Date().toISOString()
        }));

      } catch (error) {
        console.error('Error saving learning path selections:', error);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: false, error: error.message }));
      }
    });

  } else if (req.method === 'GET' && req.url.startsWith('/api/learning/selections')) {
    // Load selected learning paths
    try {
      // Extract userId from query string if provided
      const url = new URL(req.url, `http://${req.headers.host}`);
      const userId = url.searchParams.get('userId') || 'default-user';

      const filename = `learning-path-selections-${userId}.json`;
      const filepath = path.join(PROGRESS_DIR, filename);

      if (await fileExists(filepath)) {
        const data = await readJsonFile(filepath);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          selections: data.selections,
          metadata: data.metadata
        }));
      } else {
        // No selections file found, return empty array
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          selections: {
            selectedPaths: [],
            selectionCount: 0
          },
          metadata: {
            userId: userId,
            fileType: 'learning-path-selections'
          }
        }));
      }

    } catch (error) {
      console.error('Error loading learning path selections:', error);
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: false, error: error.message }));
    }

  } else if (req.method === 'GET' && req.url === '/api/progress/latest') {
    // Load the most recent progress file
    try {
      const allFiles = await listFiles(PROGRESS_DIR);
      const jsonFiles = allFiles.filter(file => file.endsWith('.json'));

      const filesWithStats = await Promise.all(
        jsonFiles.map(async (file) => {
          const filePath = path.join(PROGRESS_DIR, file);
          const stats = await getFileStats(filePath);
          return { filename: file, modified: stats.mtime };
        })
      );

      const files = filesWithStats.sort((a, b) => b.modified - a.modified);

      if (files.length === 0) {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: false, error: 'No progress files found' }));
        return;
      }

      const latestFile = files[0];
      const filePath = path.join(PROGRESS_DIR, latestFile.filename);
      const data = await readJsonFile(filePath);

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        success: true,
        filename: latestFile.filename,
        data: data
      }));
    } catch(_error) {
      console.error('Error loading latest progress file:', _error);
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: false, error: _error.message }));
    }

  } else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ success: false, error: 'Not found' }));
  }
});

server.listen(PORT, () => {
  console.log(`Progress Saver Server running on http://localhost:${PORT}`);
  console.log(`Progress files will be saved to: ${PROGRESS_DIR}`);
});

process.on('SIGINT', () => {
  console.log('\nServer shutting down...');

  // Close file watcher
  if (fileWatcher) {
    fileWatcher.close();
  }

  // Close all SSE connections
  sseConnections.forEach(connection => {
    try {
      connection.end();
    } catch(_error) {
      console.error('Error closing SSE connection:', _error);
    }
  });

  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
}

// Start the application
initializeApp().catch(error => {
  console.error('Failed to initialize application:', error);
  process.exit(1);
});
