import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import LearningPathDashboard from '../../../plugins/learning-path-dashboard.js';
import { createMockContainer, createMockPaths, mockConsole, cleanupDOM } from './test-helpers.js';

describe('Path Filtering and Search', () => {
  let container;
  let dashboard;

  beforeEach(() => {
    mockConsole();
    container = createMockContainer('path-filtering');
    dashboard = new LearningPathDashboard(container, createMockPaths());

    const diversePaths = [
      { id: 'js1', title: 'JavaScript Basics', category: 'JavaScript', difficulty: 'beginner' },
      { id: 'js2', title: 'Advanced JavaScript', category: 'JavaScript', difficulty: 'advanced' },
      { id: 'py1', title: 'Python Fundamentals', category: 'Python', difficulty: 'beginner' },
      { id: 'py2', title: 'Python Web Development', category: 'Python', difficulty: 'intermediate' },
      { id: 'react1', title: 'React Components', category: 'React', difficulty: 'intermediate' }
    ];
    dashboard.updatePaths(diversePaths);
  });

  afterEach(() => {
    dashboard?.destroy();
    cleanupDOM();
    vi.restoreAllMocks();
  });

  it('should filter paths by category', () => {
    const filtered = dashboard.filterPaths({ category: 'JavaScript' });

    expect(filtered.length).toBe(2);
    expect(filtered.every(p => p.category === 'JavaScript')).toBe(true);
  });

  it('should filter paths by difficulty', () => {
    const filtered = dashboard.filterPaths({ difficulty: 'beginner' });

    expect(filtered.length).toBe(2);
    expect(filtered.every(p => p.difficulty === 'beginner')).toBe(true);
  });

  it('should filter paths by multiple criteria', () => {
    const filtered = dashboard.filterPaths({
      category: 'Python',
      difficulty: 'intermediate'
    });

    expect(filtered.length).toBe(1);
    expect(filtered[0].id).toBe('py2');
  });

  it('should search paths by title', () => {
    const results = dashboard.searchPaths('React');

    expect(results.length).toBe(1);
    expect(results[0].id).toBe('react1');
  });

  it('should search paths case-insensitively', () => {
    const results = dashboard.searchPaths('javascript');

    expect(results.length).toBe(2);
    expect(results.every(p => p.category === 'JavaScript')).toBe(true);
  });

  it('should search across multiple fields', () => {
    const results = dashboard.searchPaths('web');

    expect(results.length).toBe(1);
    expect(results[0].id).toBe('py2');
  });
});
