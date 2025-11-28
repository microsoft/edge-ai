/**
 * Progress Operations Utilities
 * Simple functions for progress data operations without HTTP concerns
 */

import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { validateAndSanitizeProgress, generateProgressFilename } from './schema-validator.js';

/**
 * Normalize progress type from short form to long form
 * @param {string} type - Progress type (short or long form)
 * @returns {string} Normalized progress type (long form)
 */
function normalizeProgressType(type) {
  const typeMapping = {
    'kata': 'kata-progress',
    'path': 'path-progress',
    'lab': 'lab-progress',
    'self-assessment': 'self-assessment',
    'kata-progress': 'kata-progress',
    'lab-progress': 'lab-progress',
    'path-progress': 'path-progress'
  };
  return typeMapping[type] || type;
}

/**
 * Get progress directory
 * @returns {string} Progress directory path
 */
export function getProgressDir() {
  // Use environment variable if set, otherwise calculate from workspace root
  if (process.env.PROGRESS_DIR) {
    console.log('[getProgressDir] Using environment variable:', process.env.PROGRESS_DIR);
    return process.env.PROGRESS_DIR;
  }

  // Calculate workspace root from server location
  // __dirname equivalent for ES modules: path.dirname(fileURLToPath(import.meta.url))
  const __filename = fileURLToPath(import.meta.url);
  const __dirname = path.dirname(__filename);

  // From docs/_server/utils/ go up to workspace root (3 levels up: utils -> _server -> docs -> workspace)
  const workspaceRoot = path.resolve(__dirname, '..', '..', '..');
  const progressDir = path.join(workspaceRoot, '.copilot-tracking', 'learning');

  console.log('[getProgressDir] Calculated paths:', {
    __filename,
    __dirname,
    workspaceRoot,
    progressDir
  });

  return progressDir;
}

/**
 * Save progress data to file
 * @param {Object} progressData - Progress data to save
 * @param {string} progressType - Type of progress
 * @returns {Promise<Object>} Save result
 */
export async function saveProgressData(progressData, progressType) {
  // Validate and sanitize progress data
  const result = await validateAndSanitizeProgress(progressData, {
    forceType: progressType,
    sanitize: true,
    addTimestamp: true
  });
  const sanitizedData = result.data;

  // Generate filename and path
  const filename = generateProgressFilename(sanitizedData, progressType);
  const progressDir = getProgressDir();
  const filepath = path.join(progressDir, filename);

  // Ensure directory exists
  await fs.mkdir(progressDir, { recursive: true });

  // Write file
  await fs.writeFile(filepath, JSON.stringify(sanitizedData, null, 2));

  return {
    filename,
    filepath,
    type: progressType,
    data: sanitizedData
  };
}

/**
 * Load progress data by type and ID
 * @param {string} type - Progress type
 * @param {string} id - Progress ID
 * @returns {Promise<Object>} Load result
 */
export async function loadProgressData(type, id) {
  const normalizedType = normalizeProgressType(type);
  const validTypes = ['self-assessment', 'kata-progress', 'lab-progress', 'path-progress'];
  if (!validTypes.includes(normalizedType)) {
    throw new Error(`Invalid progress type: ${type}. Valid types: ${validTypes.join(', ')}`);
  }

  const progressDir = getProgressDir();
  const files = await fs.readdir(progressDir);
  const matchingFiles = files.filter(file =>
    file.startsWith(id) && file.endsWith('.json')
  );

  if (matchingFiles.length === 0) {
    throw new Error(`Progress not found: ${id}`);
  }

  // Get the most recent file
  const latestFile = matchingFiles.sort().pop();
  const filepath = path.join(progressDir, latestFile);

  // Read and parse file
  const fileContent = await fs.readFile(filepath, 'utf8');
  const progressData = JSON.parse(fileContent);

  // Validate loaded data
  const { data: validatedData, validation } = await validateAndSanitizeProgress(progressData, {
    forceType: normalizedType,
    sanitize: false
  });

  return {
    progress: validatedData,
    filename: latestFile,
    type: normalizedType,
    id,
    validation: validation.valid
  };
}

/**
 * Get progress sync status
 * @param {string} [type] - Optional progress type filter
 * @returns {Promise<Object>} Sync status
 */
export async function getProgressSyncStatus(type = null) {
  const progressDir = getProgressDir();

  let files;
  try {
    files = await fs.readdir(progressDir);
  } catch (error) {
    // Directory doesn't exist or can't be read
    if (error.code === 'ENOENT') {
      files = [];
    } else {
      throw error;
    }
  }

  const progressFiles = files.filter(file => file.endsWith('.json'));

  const result = {
    totalFiles: progressFiles.length
  };

  if (type) {
    const typeFiles = filterFilesByType(progressFiles, type);
    result.typeStats = {
      type,
      files: typeFiles.length,
      lastModified: typeFiles.length > 0 ? new Date().toISOString() : null
    };
  }

  return result;
}

/**
 * Get latest progress file info
 * @returns {Promise<Object>} Latest progress file info
 */
export async function getLatestProgressFile() {
  const progressDir = getProgressDir();

  let files;
  try {
    files = await fs.readdir(progressDir);
  } catch (error) {
    // Directory doesn't exist or can't be read
    if (error.code === 'ENOENT') {
      throw new Error('No progress files found');
    } else {
      throw error;
    }
  }

  const progressFiles = files.filter(file => file.endsWith('.json'));

  if (progressFiles.length === 0) {
    throw new Error('No progress files found');
  }

  // Get the most recent file
  const latestFile = progressFiles.sort().pop();
  const filepath = path.join(progressDir, latestFile);

  // Read file metadata
  const stats = await fs.stat(filepath);
  const fileContent = await fs.readFile(filepath, 'utf8');
  const progressData = JSON.parse(fileContent);

  return {
    filename: latestFile,
    metadata: progressData.metadata,
    timestamp: progressData.timestamp,
    modified: stats.mtime.toISOString()
  };
}

/**
 * List all progress files in the directory (optimized for performance)
 * @returns {Promise<Array>} Array of file information
 */
export async function listProgressFiles() {
  const progressDir = getProgressDir();

  let files;
  try {
    files = await fs.readdir(progressDir);
  } catch (error) {
    // Directory doesn't exist or can't be read
    if (error.code === 'ENOENT') {
      return [];
    } else {
      throw error;
    }
  }

  const progressFiles = files.filter(file => file.endsWith('.json'));

  // Use Promise.all for parallel file operations
  const fileInfoPromises = progressFiles.map(async (file) => {
    try {
      const filepath = path.join(progressDir, file);
      const stats = await fs.stat(filepath);

      // Read file content to determine actual type
      let type = 'unknown';
      let id = 'unknown';
      let timestamp = stats.mtime.toISOString();

      try {
        const content = await fs.readFile(filepath, 'utf8');
        const data = JSON.parse(content);

        // Import and use the type detection logic
        const { detectProgressType } = await import('../schemas/index.js');
        type = detectProgressType(data) || 'unknown';

        // Extract ID based on type
        if (data.metadata) {
          if (type === 'self-assessment' && data.metadata.assessmentId) {
            id = data.metadata.assessmentId;
          } else if (type === 'kata-progress' && data.metadata.kataId) {
            id = data.metadata.kataId;
          } else if (type === 'lab-progress' && data.metadata.labId) {
            id = data.metadata.labId;
          }
        }

        // Use timestamp from file content if available
        if (data.timestamp) {
          timestamp = data.timestamp;
        }
      } catch (readError) {
        console.warn(`Error reading file content for ${file}:`, readError.message);
        // If we can't read the file content, exclude it from results
        return null;
      }

      return {
        filename: file,
        type,
        id,
        timestamp,
        modified: stats.mtime.toISOString(),
        size: stats.size
      };
    } catch (fileError) {
      console.warn(`Error processing file ${file}:`, fileError.message);
      return null; // Skip corrupted files
    }
  });

  const results = await Promise.all(fileInfoPromises);
  const fileList = results.filter(result => result !== null);

  // Sort by modification time (newest first)
  fileList.sort((a, b) => new Date(b.modified) - new Date(a.modified));

  return fileList;
}

/**
 * Filter files by progress type
 * @param {Array} files - File list
 * @param {string} type - Progress type
 * @returns {Array} Filtered files
 */
function filterFilesByType(files, type) {
  return files.filter(file => {
    switch (type) {
      case 'self-assessment':
        return file.includes('assessment');
      case 'kata-progress':
        return file.includes('kata') || /\d{2}-/.test(file);
      case 'lab-progress':
        return file.includes('lab');
      default:
        return false;
    }
  });
}
