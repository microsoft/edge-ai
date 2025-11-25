/**
 * Environment-aware Security Middleware
 * Provides different security configurations based on environment
 */

import helmet from 'helmet';

/**
 * Detect the current environment and platform
 * @returns {Object} Environment detection result
 */
export function detectEnvironment() {
  const nodeEnv = process.env.NODE_ENV || 'development';
  const isCodespaces = !!process.env.CODESPACES;
  const isGitpod = !!process.env.GITPOD_WORKSPACE_ID;
  const isDevContainer = isCodespaces || isGitpod;

  return {
    nodeEnv,
    isProduction: nodeEnv === 'production',
    isDevelopment: nodeEnv === 'development',
    isTest: nodeEnv === 'test',
    isCodespaces,
    isGitpod,
    isDevContainer
  };
}

/**
 * Generate Content Security Policy based on environment
 * @param {Object} env - Environment detection result
 * @returns {Object} CSP configuration
 */
export function generateCSPConfig(env) {
  // Base secure configuration
  const baseConfig = {
    defaultSrc: ["'self'"],
    imgSrc: ["'self'", "data:", "https:"],
    fontSrc: ["'self'", "https:", "data:"],
    objectSrc: ["'none'"],
    baseUri: ["'self'"],
    formAction: ["'self'"],
    frameAncestors: ["'none'"],
    upgradeInsecureRequests: env.isProduction ? [] : null
  };

  // Production: Strict security
  if (env.isProduction) {
    return {
      ...baseConfig,
      styleSrc: ["'self'"], // No unsafe-inline in production
      scriptSrc: ["'self'"],
      connectSrc: ["'self'"],
      upgradeInsecureRequests: []
    };
  }

  // Test environment: Permissive for testing frameworks
  if (env.isTest) {
    return {
      ...baseConfig,
      styleSrc: ["'self'", "'unsafe-inline'"], // Allow inline styles for testing
      scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'"],
      connectSrc: ["'self'", "http://localhost:*", "ws://localhost:*"],
      upgradeInsecureRequests: null
    };
  }

  // Development: Allow hot reload and dev tools
  const devConfig = {
    ...baseConfig,
    styleSrc: ["'self'", "'unsafe-inline'"], // Allow inline styles for development
    scriptSrc: ["'self'", "'unsafe-inline'"],
    connectSrc: ["'self'", "http://localhost:*", "ws://localhost:*"],
    upgradeInsecureRequests: null
  };

  // DevContainer-specific adjustments
  if (env.isCodespaces) {
    devConfig.connectSrc.push(
      'https://*.github.dev',
      'https://*.githubusercontent.com',
      'wss://*.github.dev'
    );
    devConfig.scriptSrc.push('https://*.github.dev');
  }

  if (env.isGitpod) {
    devConfig.connectSrc.push(
      'https://*.gitpod.io',
      'wss://*.gitpod.io'
    );
    devConfig.scriptSrc.push('https://*.gitpod.io');
  }

  return devConfig;
}

/**
 * Generate Helmet configuration based on environment
 * @param {Object} env - Environment detection result
 * @returns {Object} Helmet configuration
 */
export function generateHelmetConfig(env) {
  const cspConfig = generateCSPConfig(env);

  const baseConfig = {
    contentSecurityPolicy: {
      directives: cspConfig
    },
    crossOriginEmbedderPolicy: env.isProduction,
    crossOriginOpenerPolicy: { policy: "same-origin" },
    crossOriginResourcePolicy: { policy: "cross-origin" },
    dnsPrefetchControl: true,
    frameguard: { action: 'deny' },
    hidePoweredBy: true,
    hsts: env.isProduction ? {
      maxAge: 31536000,
      includeSubDomains: true,
      preload: true
    } : false,
    ieNoOpen: true,
    noSniff: true,
    originAgentCluster: true,
    permittedCrossDomainPolicies: false,
    referrerPolicy: { policy: "strict-origin-when-cross-origin" },
    xssFilter: true
  };

  return baseConfig;
}

/**
 * Create environment-aware security middleware
 * @returns {Function} Express middleware function
 */
export function createSecurityMiddleware() {
  const env = detectEnvironment();
  const helmetConfig = generateHelmetConfig(env);

  // Log security configuration in development
  if (env.isDevelopment || env.isTest) {
    console.log(`🛡️  Security middleware configured for ${env.nodeEnv} environment`);
    if (env.isDevContainer) {
      console.log(`📦 DevContainer detected: ${env.isCodespaces ? 'Codespaces' : 'Gitpod'}`);
    }
  }

  return helmet(helmetConfig);
}

export default createSecurityMiddleware;
