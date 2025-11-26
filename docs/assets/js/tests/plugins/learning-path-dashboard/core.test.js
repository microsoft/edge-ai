import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import LearningPathDashboard from '../../../plugins/learning-path-dashboard.js';
import { createMockContainer, createMockPaths, cleanupDashboard } from './test-helpers.js';

let dashboard, container, mockPaths;

describe('LearningPathDashboard Core', () => {
  beforeEach(() => {
    container = createMockContainer();
    mockPaths = createMockPaths();
    dashboard = new LearningPathDashboard(container, mockPaths);
  });

  afterEach(() => {
    cleanupDashboard(dashboard, container);
  });

  it('should initialize with provided container and paths', () => {
    expect(dashboard).toBeDefined();
    expect(dashboard.containers.length).toBeGreaterThan(0);
    expect(dashboard.learningPaths.length).toBeGreaterThan(0);
    expect(dashboard.initialPaths).toEqual(mockPaths);
  });

  it('should accept configuration objects as second argument', () => {
    const configContainer = createMockContainer();
    const configPaths = createMockPaths();
    const configDashboard = new LearningPathDashboard(configContainer, {
      debug: true,
      initialPaths: configPaths
    });

    expect(configDashboard.config.debug).toBe(true);
    expect(configDashboard.learningPaths.length).toBe(configPaths.length);

    cleanupDashboard(configDashboard, configContainer);
  });

  it('should merge config overrides when paths array provided', () => {
    const overrideContainer = createMockContainer();
    const overridePaths = createMockPaths();
    const overrideDashboard = new LearningPathDashboard(overrideContainer, overridePaths, {
      debug: true,
      enableAutoSelection: false
    });

    expect(overrideDashboard.config.debug).toBe(true);
    expect(overrideDashboard.config.enableAutoSelection).toBe(false);
    expect(overrideDashboard.learningPaths.length).toBe(overridePaths.length);

    cleanupDashboard(overrideDashboard, overrideContainer);
  });

  it('should destroy and cleanup DOM', () => {
    dashboard.destroy();
    // The container should still exist but dashboard-specific elements should be removed
    expect(document.body.contains(container)).toBe(true);
    expect(container.querySelector('.learning-dashboard-error')).toBeNull();
    expect(container.querySelector('.learning-dashboard-status')).toBeNull();
    expect(container.querySelector('.learning-dashboard-aria-live')).toBeNull();
    expect(dashboard.isDestroyed).toBe(true);
  });

  // ...existing core lifecycle tests...
});
