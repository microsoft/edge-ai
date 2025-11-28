import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import LearningPathDashboard from '../../../plugins/learning-path-dashboard.js';
import { createMockContainer, createMockPaths, cleanupDashboard } from './test-helpers.js';

let dashboard, container;

describe('Container Management', () => {
  beforeEach(() => {
    container = createMockContainer('container-mgmt');
    dashboard = new LearningPathDashboard(container, createMockPaths());
  });

  afterEach(() => {
    cleanupDashboard(dashboard, container);
  });

  it('should normalize and validate containers', () => {
    expect(dashboard.containers).toBeDefined();
    expect(Array.isArray(dashboard.containers)).toBe(true);
    expect(dashboard.containers[0]).toBe(container);
  });

  it('should support multiple containers', () => {
    const container2 = createMockContainer('container2');
    const dashboard2 = new LearningPathDashboard([container, container2], createMockPaths());
    expect(dashboard2.containers.length).toBe(2);
    cleanupDashboard(dashboard2, container2);
  });

  // ...existing container management tests...
});
