import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import LearningPathDashboard from '../../../plugins/learning-path-dashboard.js';
import { createMockContainer, createMockPaths, mockConsole, cleanupDOM } from './test-helpers.js';

describe('State Persistence', () => {
  let container, dashboard;

  beforeEach(() => {
    mockConsole();
    localStorage.clear();
    container = createMockContainer('state-persistence');
    dashboard = new LearningPathDashboard(container, createMockPaths());
  });

  afterEach(() => {
    dashboard?.destroy();
    cleanupDOM();
    localStorage.clear();
    vi.restoreAllMocks();
  });

  // All tests removed - localStorage persistence removed from learning-path-dashboard/storage.js
  // Dashboard now uses API-only persistence with server-side storage

  it('should have tests removed due to architectural changes', () => {
    // This is a placeholder test since all localStorage persistence was removed
    // The dashboard now uses API-only persistence with server-side storage
    expect(true).toBe(true);
  });
});
