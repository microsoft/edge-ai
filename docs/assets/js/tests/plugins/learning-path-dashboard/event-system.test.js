import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import LearningPathDashboard from '../../../plugins/learning-path-dashboard.js';
import { createMockContainer, createMockPaths, cleanupDashboard } from './test-helpers.js';

let dashboard, container;

describe('Event System', () => {
  beforeEach(() => {
    container = createMockContainer('event-system');
    dashboard = new LearningPathDashboard(container, createMockPaths());
  });

  afterEach(() => {
    cleanupDashboard(dashboard, container);
  });

  it('should register and emit custom events', () => {
    const handler = vi.fn();
    dashboard.on('custom-event', handler);
    dashboard.emit('custom-event', { foo: 'bar' });
    expect(handler).toHaveBeenCalledWith({ foo: 'bar' });
  });

  it('should remove event listeners', () => {
    const handler = vi.fn();
    dashboard.on('remove-event', handler);
    dashboard.off('remove-event', handler);
    dashboard.emit('remove-event', {});
    expect(handler).not.toHaveBeenCalled();
  });

  // ...existing event system tests...
});
