/**
 * Minimal CORS Test - Debug Version
 */
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';

describe('Minimal CORS Test', () => {
  let app;

  beforeAll(async () => {
    console.log('Setting up minimal CORS test...');

    // Set up test environment
    process.env.NODE_ENV = 'test';
    process.env.SKIP_FILE_WATCHER = 'true';

    // Import the app
    const appModule = await import('../../app.js');
    app = appModule.default;

    console.log('App imported successfully');
  }, 30000);

  afterAll(async () => {
    console.log('Cleaning up minimal CORS test...');
    // Basic cleanup
    await new Promise(resolve => setTimeout(resolve, 100));
  }, 10000);

  it('should respond to basic health check', async () => {
    console.log('Running basic health check...');

    const res = await request(app)
      .get('/health')
      .expect(200);

    expect(res.body).toHaveProperty('status', 'healthy');
    console.log('Health check passed');
  });

  it('should handle CORS on health endpoint', async () => {
    console.log('Testing CORS on health endpoint...');

    const res = await request(app)
      .get('/health')
      .set('Origin', 'https://test.example.com')
      .expect(200);

    expect(res.headers).toHaveProperty('access-control-allow-origin');
    console.log('CORS test passed');
  });
});
