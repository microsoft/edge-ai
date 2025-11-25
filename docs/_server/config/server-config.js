/**
 * Server Configuration
 * Central configuration for the Express.js progress server
 */

// Environment detection function
function detectEnvironment() {
  // Check for container indicators
  const isContainer = !!(
    process.env.CONTAINER ||
    process.env.DOCKER ||
    process.env.KUBERNETES_SERVICE_HOST ||
    process.env.CODESPACES ||
    process.env.REMOTE_CONTAINERS ||
    process.env.VSCODE_REMOTE_CONTAINERS_SESSION ||
    process.env.DEVCONTAINER
  );

  // Check for Windows
  const isWindows = process.platform === 'win32';

  // Check if running in dev container specifically
  const isDevContainer = !!(
    process.env.REMOTE_CONTAINERS ||
    process.env.VSCODE_REMOTE_CONTAINERS_SESSION ||
    process.env.DEVCONTAINER
  );

  return {
    isContainer,
    isWindows,
    isMacOS: process.platform === 'darwin',
    isLinux: process.platform === 'linux',
    isDevContainer,
    platform: process.platform
  };
}

const environment = detectEnvironment();

// Determine appropriate host binding based on environment
function getServerHost() {
  if (process.env.HOST) {
    return process.env.HOST; // Explicit override
  }

  if (environment.isContainer || environment.isDevContainer) {
    return '0.0.0.0'; // Container needs to bind to all interfaces
  }

  // Platform-specific local development settings
  switch (environment.platform) {
    case 'win32':
      return 'localhost'; // Windows local development
    case 'darwin':
      return 'localhost'; // macOS local development
    case 'linux':
      return 'localhost'; // Linux local development
    default:
      return '0.0.0.0'; // Fallback for unknown platforms
  }
}

const config = {
  // Server settings
  server: {
    port: process.env.PORT || 3002,
    host: getServerHost(),
    environment: process.env.NODE_ENV || 'development'
  },

  // Environment detection results
  runtime: {
    ...environment,
    detectedHost: getServerHost()
  },

  // CORS settings
  cors: {
    origin: process.env.NODE_ENV === 'test'
      ? '*' // Allow all origins in test mode
      : process.env.NODE_ENV === 'production'
      ? ['https://your-production-domain.com']
      : ['http://localhost:8080', 'http://127.0.0.1:8080', 'http://0.0.0.0:8080'],
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: process.env.NODE_ENV !== 'test', // Credentials can't be true with wildcard origin
    maxAge: 86400 // 24 hours preflight cache
  },

  // Rate limiting
  rateLimit: {
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: process.env.NODE_ENV === 'test' ? 1000 : 100, // Higher limit for testing
    message: 'Too many requests from this IP, please try again later.'
  },

  // File system settings
  fileSystem: {
    progressDir: process.env.PROGRESS_DIR || 'progress',
    backupDir: process.env.BACKUP_DIR || 'backup',
    maxFilesPerProgress: parseInt(process.env.MAX_FILES_PER_PROGRESS) || 5,
    cleanupInterval: parseInt(process.env.CLEANUP_INTERVAL) || 24 * 60 * 60 * 1000 // 24 hours
  },

  // Schema validation
  validation: {
    strict: process.env.NODE_ENV === 'production',
    removeAdditional: true,
    useDefaults: true
  },

  // SSE settings
  sse: {
    heartbeatInterval: parseInt(process.env.SSE_HEARTBEAT_INTERVAL) || 30000, // 30 seconds
    connectionTimeout: parseInt(process.env.SSE_CONNECTION_TIMEOUT) || 60000, // 60 seconds
    maxConnections: parseInt(process.env.SSE_MAX_CONNECTIONS) || 100
  },

  // Logging
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    format: process.env.LOG_FORMAT || 'combined',
    enableAccessLog: process.env.ENABLE_ACCESS_LOG !== 'false'
  },

  // File watcher settings
  fileWatcher: {
    ignored: /[/\\]\./,
    persistent: true,
    ignoreInitial: true,
    followSymlinks: false,
    usePolling: process.env.USE_POLLING === 'true',
    interval: parseInt(process.env.WATCH_INTERVAL) || 5000
  }
};

export default config;
