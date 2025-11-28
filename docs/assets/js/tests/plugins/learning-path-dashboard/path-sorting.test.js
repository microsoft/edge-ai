import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import LearningPathDashboard from '../../../plugins/learning-path-dashboard.js';
import { createMockContainer, createMockPaths, mockConsole, cleanupDOM } from './test-helpers.js';

describe('Path Sorting', () => {
  let container;
  let dashboard;

  beforeEach(() => {
    mockConsole();
    container = createMockContainer('path-sorting');
    dashboard = new LearningPathDashboard(container, createMockPaths());

    const unsortedPaths = [
      { id: 'path3', title: 'C Path', category: 'Category B', createdAt: '2023-01-03' },
      { id: 'path1', title: 'A Path', category: 'Category A', createdAt: '2023-01-01' },
      { id: 'path2', title: 'B Path', category: 'Category C', createdAt: '2023-01-02' }
    ];
    dashboard.updatePaths(unsortedPaths);
  });

  afterEach(() => {
    dashboard?.destroy();
    cleanupDOM();
    vi.restoreAllMocks();
  });

  it('should sort paths by title', () => {
    const sorted = dashboard.sortPaths('title', 'asc');

    expect(sorted[0].title).toBe('A Path');
    expect(sorted[1].title).toBe('B Path');
    expect(sorted[2].title).toBe('C Path');
  });

  it('should sort paths by category', () => {
    const sorted = dashboard.sortPaths('category', 'asc');

    expect(sorted[0].category).toBe('Category A');
    expect(sorted[1].category).toBe('Category B');
    expect(sorted[2].category).toBe('Category C');
  });

  it('should sort paths by date', () => {
    const sorted = dashboard.sortPaths('createdAt', 'desc');

    expect(sorted[0].createdAt).toBe('2023-01-03');
    expect(sorted[1].createdAt).toBe('2023-01-02');
    expect(sorted[2].createdAt).toBe('2023-01-01');
  });

  it('should maintain stable sort order', () => {
    const pathsWithSameTitle = [
      { id: 'path1', title: 'Same Title', order: 1 },
      { id: 'path2', title: 'Same Title', order: 2 },
      { id: 'path3', title: 'Same Title', order: 3 }
    ];
    dashboard.updatePaths(pathsWithSameTitle);

    const sorted = dashboard.sortPaths('title', 'asc');

    expect(sorted[0].order).toBe(1);
    expect(sorted[1].order).toBe(2);
    expect(sorted[2].order).toBe(3);
  });
});
