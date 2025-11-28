import fs from 'fs/promises';
import path from 'path';

/**
 * Async File Operations Utility Module
 * Provides async replacements for synchronous file operations
 */

/**
 * Check if a file or directory exists
 * @param {string} filePath - Path to check
 * @returns {Promise<boolean>} - True if exists, false otherwise
 */
export async function fileExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

/**
 * Read and parse JSON file asynchronously
 * @param {string} filePath - Path to JSON file
 * @returns {Promise<object|null>} - Parsed JSON or null if error
 */
export async function readJsonFile(filePath) {
  try {
    const content = await fs.readFile(filePath, 'utf8');
    return JSON.parse(content);
  } catch (error) {
    console.error(`Error reading JSON file ${filePath}:`, error);
    return null;
  }
}

/**
 * Write JSON data to file asynchronously
 * @param {string} filePath - Path to write to
 * @param {object} data - Data to write
 * @returns {Promise<boolean>} - True if successful, false otherwise
 */
export async function writeJsonFile(filePath, data) {
  try {
    const content = JSON.stringify(data, null, 2);
    await fs.writeFile(filePath, content);
    return true;
  } catch (error) {
    console.error(`Error writing JSON file ${filePath}:`, error);
    return false;
  }
}

/**
 * List files in directory with optional filter
 * @param {string} dirPath - Directory path
 * @param {function} filter - Optional filter function
 * @returns {Promise<string[]>} - Array of filenames
 */
export async function listFiles(dirPath, filter = null) {
  try {
    const files = await fs.readdir(dirPath);
    return filter ? files.filter(filter) : files;
  } catch (error) {
    console.error(`Error listing files in ${dirPath}:`, error);
    return [];
  }
}

/**
 * Get file statistics asynchronously
 * @param {string} filePath - Path to file
 * @returns {Promise<object|null>} - File stats or null if error
 */
export async function getFileStats(filePath) {
  try {
    return await fs.stat(filePath);
  } catch (error) {
    console.error(`Error getting stats for ${filePath}:`, error);
    return null;
  }
}

/**
 * Ensure directory exists, create if it doesn't
 * @param {string} dirPath - Directory path
 * @returns {Promise<boolean>} - True if exists/created, false otherwise
 */
export async function ensureDirectory(dirPath) {
  try {
    await fs.mkdir(dirPath, { recursive: true });
    return true;
  } catch (error) {
    console.error(`Error creating directory ${dirPath}:`, error);
    return false;
  }
}

/**
 * Read multiple JSON files concurrently
 * @param {string[]} filePaths - Array of file paths
 * @returns {Promise<object[]>} - Array of parsed JSON objects
 */
export async function readMultipleJsonFiles(filePaths) {
  try {
    const results = await Promise.allSettled(
      filePaths.map(filePath => readJsonFile(filePath))
    );

    return results
      .filter(result => result.status === 'fulfilled' && result.value !== null)
      .map(result => result.value);
  } catch (error) {
    console.error('Error reading multiple JSON files:', error);
    return [];
  }
}

/**
 * Get files with their metadata (stats + content) asynchronously
 * @param {string} dirPath - Directory path
 * @param {function} filter - Optional filter function for filenames
 * @returns {Promise<object[]>} - Array of {filename, stats, data} objects
 */
export async function getFilesWithMetadata(dirPath, filter = null) {
  try {
    const files = await listFiles(dirPath, filter);

    const results = await Promise.allSettled(
      files.map(async (file) => {
        const filePath = path.join(dirPath, file);
        const [stats, data] = await Promise.all([
          getFileStats(filePath),
          file.endsWith('.json') ? readJsonFile(filePath) : null
        ]);

        return {
          filename: file,
          path: filePath,
          stats,
          data
        };
      })
    );

    return results
      .filter(result => result.status === 'fulfilled' && result.value.stats)
      .map(result => result.value);
  } catch (error) {
    console.error(`Error getting files with metadata from ${dirPath}:`, error);
    return [];
  }
}

/**
 * Safe async file operation with retry logic
 * @param {function} operation - Async operation to perform
 * @param {number} maxRetries - Maximum number of retries
 * @param {number} delay - Delay between retries in ms
 * @returns {Promise<any>} - Result of the operation
 */
export async function withRetry(operation, maxRetries = 3, delay = 100) {
  let lastError;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error;

      if (attempt < maxRetries) {
        console.warn(`Operation failed (attempt ${attempt + 1}/${maxRetries + 1}), retrying in ${delay}ms:`, error.message);
        await new Promise(resolve => setTimeout(resolve, delay));
        delay *= 2; // Exponential backoff
      }
    }
  }

  throw lastError;
}

/**
 * Batch file operations with concurrency limit
 * @param {Array} items - Items to process
 * @param {function} operation - Async operation for each item
 * @param {number} concurrencyLimit - Maximum concurrent operations
 * @returns {Promise<Array>} - Results array
 */
export async function batchOperation(items, operation, concurrencyLimit = 10) {
  const results = [];

  for (let i = 0; i < items.length; i += concurrencyLimit) {
    const batch = items.slice(i, i + concurrencyLimit);
    const batchResults = await Promise.allSettled(
      batch.map(item => operation(item))
    );

    results.push(...batchResults);
  }

  return results;
}
