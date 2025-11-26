import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import LearningPathDashboard from '../../../plugins/learning-path-dashboard.js';
import { createMockContainer, createMockPaths, cleanupDashboard, mockConsole } from './test-helpers.js';

let dashboard, container;

describe('Error Handling', () => {
  beforeEach(() => {
    mockConsole();
    container = createMockContainer('error-handling');
    dashboard = new LearningPathDashboard(container, createMockPaths());
  });

  afterEach(() => {
    cleanupDashboard(dashboard, container);
  });

  it('should log errors to console', () => {
    expect(() => dashboard.logError('Test error')).not.toThrow();
  });

  it('should emit error events on failure', () => {
    const handler = vi.fn();
    dashboard.on('error', handler);
    dashboard.emit('error', { message: 'fail' });
    expect(handler).toHaveBeenCalledWith({ message: 'fail' });
  });

  // ...existing error handling tests...
});
