import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'happy-dom',
    globals: true,
    include: [
      '**/integration/**/*.test.js'
    ],
    setupFiles: ['./integration-test-setup.js']
  }
});
