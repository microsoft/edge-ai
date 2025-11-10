/**
 * CORS Configuration Middleware
 * Environment-aware CORS configuration with DevContainer support
 */

/**
 * Creates a CORS configuration object based on the current environment
 * @returns {Object} CORS configuration object
 */
export function createCorsConfig() {
  const env = process.env.NODE_ENV || 'development';
  const isCodespaces = process.env.CODESPACES === 'true';
  const isGitpod = !!process.env.GITPOD_WORKSPACE_ID;

  console.log(`🌐 Configuring CORS for ${env} environment`);

  if (isCodespaces) {
    console.log('📦 DevContainer detected: Codespaces');
  } else if (isGitpod) {
    console.log('📦 DevContainer detected: Gitpod');
  }

  const baseConfig = {
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    exposedHeaders: ['X-Total-Count', 'X-Filtered-Count'],
    maxAge: 86400, // 24 hours preflight cache
    optionsSuccessStatus: 204 // Standard CORS preflight response
  };

  if (env === 'production') {
    return {
      ...baseConfig,
      origin: createOriginFunction(getProductionOrigins()),
      credentials: true
    };
  }

  if (env === 'test') {
    return {
      ...baseConfig,
      origin: createOriginFunction(getTestOrigins()),
      credentials: false // Never use credentials in test environment
    };
  }

  // Development environment
  return {
    ...baseConfig,
    origin: createOriginFunction(getDevelopmentOrigins()),
    credentials: true
  };
}

/**
 * Creates an origin function for CORS that validates against allowed origins
 * @param {Array<string>} allowedOrigins - Array of allowed origins
 * @returns {Function} Origin validation function
 */
function createOriginFunction(allowedOrigins) {
  return (origin, callback) => {
    // Allow requests with no origin (mobile apps, etc.) - return wildcard
    if (!origin) {
      return callback(null, '*');
    }

    // Allow requests with string "null" (file:// origins) - echo back "null"
    if (origin === 'null') {
      return callback(null, 'null');
    }

    // Check if origin is in allowed list
    const isAllowed = allowedOrigins.some(allowedOrigin => {
      if (allowedOrigin === origin) {
        return true;
      }

      // Handle wildcard patterns
      if (allowedOrigin.includes('*')) {
        const pattern = allowedOrigin.replace(/\*/g, '.*');
        const regex = new RegExp(`^${pattern}$`);
        return regex.test(origin);
      }

      return false;
    });

    if (isAllowed) {
      callback(null, origin); // Echo back the specific origin for security
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  };
}

/**
 * Gets allowed origins for production environment
 * @returns {Array<string>} Array of allowed production origins
 */
function getProductionOrigins() {
  const envOrigins = process.env.PRODUCTION_ORIGINS;

  if (envOrigins) {
    return envOrigins.split(',').map(origin => origin.trim());
  }

  // Default production origins (should be overridden via environment variables)
  return ['https://your-production-domain.com'];
}

/**
 * Gets allowed origins for test environment
 * @returns {Array<string>} Array of allowed test origins
 */
function getTestOrigins() {
  // Test origins - includes specific test domains for integration testing
  return [
    'http://localhost:8080',
    'http://localhost:3000',
    'http://127.0.0.1:8080',
    'http://127.0.0.1:3000',
    // Integration test origins
    'https://example.com',
    'https://docs.mysite.com',
    'https://test.example.com',
    'https://cors-test.com',
    'https://monitoring.example.com',
    'https://app0.example.com',
    'https://app1.example.com',
    'https://app2.example.com',
    'https://app3.example.com',
    'https://app4.example.com',
    'https://production.example.com',
    'https://staging.example.com',
    'https://dev.example.com',
    'http://test-site.com', // Error handling test origin
    'file://',
    'chrome-extension://abcdefg'
  ];
}

/**
 * Gets allowed origins for development environment
 * Includes DevContainer-specific origins when detected
 * @returns {Array<string>} Array of allowed development origins
 */
function getDevelopmentOrigins() {
  const origins = [
    // Local development origins
    'http://localhost:8080',
    'http://localhost:3000',
    'http://localhost:4000',
    'http://127.0.0.1:8080',
    'http://127.0.0.1:3000',
    'http://127.0.0.1:4000',
    'http://0.0.0.0:8080'
  ];

  // Add Codespaces origins if in Codespaces
  if (process.env.CODESPACES === 'true') {
    const codespaceName = process.env.CODESPACE_NAME;

    if (codespaceName) {
      origins.push(
        `https://${codespaceName}-8080.app.github.dev`,
        `https://${codespaceName}-3000.app.github.dev`,
        `https://${codespaceName}-4000.app.github.dev`
      );
    }
  }

  // Always add general GitHub Codespaces patterns in development
  origins.push('https://*.github.dev');

  // Add Gitpod origins if in Gitpod
  if (process.env.GITPOD_WORKSPACE_ID) {
    const workspaceId = process.env.GITPOD_WORKSPACE_ID;
    const workspaceUrl = process.env.GITPOD_WORKSPACE_URL;

    if (workspaceId && workspaceUrl) {
      // Extract the base domain from workspace URL
      const urlMatch = workspaceUrl.match(/https:\/\/([^.]+)\.(.+)/);
      if (urlMatch) {
        const baseDomain = urlMatch[2];
        origins.push(
          `https://8080-${workspaceId}.${baseDomain}`,
          `https://3000-${workspaceId}.${baseDomain}`,
          `https://4000-${workspaceId}.${baseDomain}`
        );
      }
    }
  }

  // Always add general Gitpod patterns in development
  origins.push('https://*.gitpod.io');

  return origins;
}

/**
 * Creates a dynamic CORS configuration function
 * This allows CORS to be evaluated per request for more complex logic
 * @returns {Function} CORS configuration function
 */
export function createDynamicCorsConfig() {
  return (req, callback) => {
    // Create fresh config for each request to pick up environment changes
    const corsOptions = createCorsConfig();

    // Additional dynamic logic can be added here
    // For example, request-specific origin validation

    if (corsOptions.origin === '*') {
      // Should never happen with our configuration, but extra safety
      if (corsOptions.credentials) {
        console.warn('⚠️  CORS Security Warning: Wildcard origin with credentials disabled');
        corsOptions.credentials = false;
      }
    }

    callback(null, corsOptions);
  };
}

export default createCorsConfig;
