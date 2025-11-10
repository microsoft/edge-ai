/**
 * File Watcher Configuration Optimization
 * Environment-specific and performance-optimized configurations
 */

/**
 * Get configuration optimized for specific environment
 * @param {string} environment - Environment type (development, production, test)
 * @returns {Object} Environment-optimized configuration
 */
export function getConfigForEnvironment(environment) {
  const baseConfig = {
    persistent: true,
    ignoreInitial: true,
    followSymlinks: false,
    depth: 1,
    usePolling: false, // Always prefer native events
    useFsEvents: true, // Enable native file system events on supported platforms
    awaitWriteFinish: {
      stabilityThreshold: 100,
      pollInterval: 5000
    }
  };

  switch (environment) {
    case 'development':
      return {
        ...baseConfig,
        debounceDelay: 200, // Fast feedback for development
        awaitWriteFinish: {
          stabilityThreshold: 100, // Quick response
          pollInterval: 3000
        }
      };

    case 'production':
      return {
        ...baseConfig,
        debounceDelay: 500, // More stable for production
        awaitWriteFinish: {
          stabilityThreshold: 200, // More stable
          pollInterval: 5000
        }
      };

    case 'test':
      return {
        ...baseConfig,
        persistent: false, // Don't persist in tests
        debounceDelay: 50, // Fast tests
        awaitWriteFinish: {
          stabilityThreshold: 50, // Quick for tests
          pollInterval: 1000
        }
      };

    default:
      return baseConfig;
  }
}

/**
 * Get optimized configuration for performance
 * @returns {Object} Performance-optimized configuration
 */
export function getOptimizedConfig() {
  return {
    persistent: true,
    ignoreInitial: true,
    followSymlinks: false,
    depth: 1, // Limit directory traversal depth
    usePolling: false, // Native file system events
    ignored: /[/\\]\./, // Ignore hidden files/directories
    awaitWriteFinish: {
      stabilityThreshold: 100,
      pollInterval: 5000 // Infrequent polling for stability check only
    }
  };
}

/**
 * Get configuration for specific file types
 * @param {string} fileExtension - File extension (e.g., '.json', '.log')
 * @returns {Object} File type-specific configuration
 */
export function getFileTypeConfig(fileExtension) {
  const baseConfig = getOptimizedConfig();

  switch (fileExtension) {
    case '.json':
      return {
        ...baseConfig,
        debounceDelay: 200 // Fast response for progress files
      };

    case '.log':
      return {
        ...baseConfig,
        debounceDelay: 1000 // Slower for log files (less critical)
      };

    default:
      return {
        ...baseConfig,
        debounceDelay: 300
      };
  }
}

/**
 * Get platform-specific optimized configuration
 * @returns {Object} Platform-optimized configuration
 */
export function getPlatformConfig() {
  const baseConfig = getOptimizedConfig();

  switch (process.platform) {
    case 'win32':
      return {
        ...baseConfig,
        awaitWriteFinish: {
          stabilityThreshold: 150, // Windows may need more stability time
          pollInterval: 5000
        }
      };

    case 'linux':
      return {
        ...baseConfig,
        awaitWriteFinish: {
          stabilityThreshold: 100, // Linux is generally faster
          pollInterval: 4000
        }
      };

    case 'darwin':
      return {
        ...baseConfig,
        awaitWriteFinish: {
          stabilityThreshold: 100, // macOS FSEvents are efficient
          pollInterval: 4000
        }
      };

    default:
      return baseConfig;
  }
}

/**
 * Get memory-optimized configuration
 * @returns {Object} Memory-optimized configuration
 */
export function getMemoryOptimizedConfig() {
  return {
    maxEventHistory: 100, // Limit event history to prevent memory bloat
    cleanupInterval: 60000, // Cleanup every minute
    maxClientConnections: 50, // Limit client connections
    eventRetentionTime: 3600000 // Keep events for 1 hour max
  };
}

/**
 * Get file filters for performance
 * @returns {Object} File inclusion/exclusion filters
 */
export function getFileFilters() {
  return {
    include: [
      '*.json', // Progress files
      '*.md' // Documentation files
    ],
    exclude: [
      '**/tmp/**',
      '**/temp/**',
      '**/node_modules/**',
      '**/.git/**',
      '**/logs/**',
      '**/*.log',
      '**/*.tmp'
    ]
  };
}

/**
 * Get default optimized configuration combining all optimizations
 * @param {string} environment - Optional environment override
 * @returns {Object} Complete optimized configuration
 */
export function getDefaultConfig(environment = process.env.NODE_ENV || 'development') {
  const envConfig = getConfigForEnvironment(environment);
  const platformConfig = getPlatformConfig();
  const memoryConfig = getMemoryOptimizedConfig();
  const fileFilters = getFileFilters();

  return {
    ...envConfig,
    ...platformConfig,
    ...memoryConfig,
    ...fileFilters
  };
}
