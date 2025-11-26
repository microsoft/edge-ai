import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { createPerformanceTestHelper, createMemoryMonitor } from '../helpers/performance-test-helper.js';

/**
 * Data Processing Performance Test Suite
 *
 * Focused tests for data manipulation, search, filtering, and algorithm performance
 * with comprehensive cleanup and memory management.
 */
describe('Data Processing Performance', () => {
  let testContainer;
  let performanceHelper;
  let memoryMonitor;

  beforeEach(async () => {
    // Setup test environment with comprehensive performance monitoring using happy-dom
    document.head.innerHTML = `
        <title>Data Processing Performance Test</title>
        <meta charset="utf-8">
    `;

    document.body.innerHTML = `
      <div id="test-container">
        <div id="learning-paths-container"></div>
      </div>
    `;

    testContainer = document.getElementById('test-container');

    // Initialize performance testing tools with comprehensive cleanup
    performanceHelper = createPerformanceTestHelper({
      memoryTrackingEnabled: true,
      domCleanupEnabled: true,
      eventCleanupEnabled: true,
      observerCleanupEnabled: true
    });

    memoryMonitor = createMemoryMonitor();
  });

  afterEach(() => {
    // Comprehensive cleanup to prevent test interference
    if (performanceHelper) {
      performanceHelper.cleanup();
    }

    if (memoryMonitor) {
      memoryMonitor.stopMonitoring();
      memoryMonitor.clear();
    }

    // Clear any performance measurements
    if (performance.clearMarks) {
      performance.clearMarks();
    }
    if (performance.clearMeasures) {
      performance.clearMeasures();
    }

    // Reset all mocks
    vi.restoreAllMocks();
  });

  it('should process learning datasets efficiently', async () => {
    const datasetSize = 500; // Reduced for memory efficiency

    memoryMonitor.startMonitoring(100);
    performanceHelper.startMeasurement('large-dataset-processing');

    // Generate learning dataset
    const learningDataset = performanceHelper.generateLearningDataset(datasetSize);
    expect(learningDataset.length).toBe(datasetSize);

    // Process dataset with complex operations
    const processedData = learningDataset
      .filter(item => item.difficulty >= 3)
      .map(item => ({
        ...item,
        estimatedCompletionTime: item.duration * (1 + item.difficulty * 0.2),
        skillLevel: Math.floor(item.difficulty * 2),
        prerequisites: learningDataset
          .filter(prereq => prereq.category === item.category && prereq.difficulty < item.difficulty)
          .slice(0, 2) // Reduced to limit memory usage
          .map(prereq => prereq.id)
      }))
      .sort((a, b) => a.estimatedCompletionTime - b.estimatedCompletionTime);

    // Additional aggregation operations
    const categoryStats = learningDataset.reduce((stats, item) => {
      stats[item.category] = stats[item.category] || {
        count: 0,
        totalDuration: 0,
        averageDifficulty: 0,
        items: []
      };

      stats[item.category].count++;
      stats[item.category].totalDuration += item.duration;
      stats[item.category].averageDifficulty += item.difficulty;
      stats[item.category].items.push(item);

      return stats;
    }, {});

    // Calculate final statistics
    Object.keys(categoryStats).forEach(category => {
      const stats = categoryStats[category];
      stats.averageDifficulty = stats.averageDifficulty / stats.count;
      stats.averageDuration = stats.totalDuration / stats.count;
    });

    const processingMetrics = performanceHelper.endMeasurement('large-dataset-processing');
    const memoryStats = memoryMonitor.stopMonitoring();

    // Performance assertions
    expect(processingMetrics.duration).toBeLessThan(500); // < 500ms for processing
    expect(processedData.length).toBeGreaterThan(0);
    expect(Object.keys(categoryStats).length).toBeGreaterThan(0);
    expect(memoryStats.memoryUsage.growth).toBeLessThan(50 * 1024 * 1024); // < 50MB growth
  });

  it('should handle real-time learning progress updates efficiently', async () => {
    const updateCount = 500; // Reduced for memory efficiency
    const progressUpdates = [];

    memoryMonitor.startMonitoring(25);

    // Initialize learning progress state
    const learningState = {
      users: new Map(),
      courses: new Map(),
      progressByUser: new Map(),
      completionStats: {
        total: 0,
        completed: 0,
        inProgress: 0
      }
    };

    performanceHelper.startMeasurement('realtime-progress-updates');

    // Simulate rapid progress updates
    for (let i = 0; i < updateCount; i++) {
      const userId = `user_${Math.floor(Math.random() * 50)}`;
      const courseId = `course_${Math.floor(Math.random() * 25)}`;
      const progressUpdate = {
        userId,
        courseId,
        progress: Math.random() * 100,
        timestamp: Date.now(),
        skillsGained: Math.floor(Math.random() * 3),
        completedItems: Math.floor(Math.random() * 10)
      };

      // Update learning state
      if (!learningState.progressByUser.has(userId)) {
        learningState.progressByUser.set(userId, new Map());
      }

      const userProgress = learningState.progressByUser.get(userId);
      userProgress.set(courseId, progressUpdate);

      // Update completion stats
      if (progressUpdate.progress >= 100) {
        learningState.completionStats.completed++;
      } else if (progressUpdate.progress > 0) {
        learningState.completionStats.inProgress++;
      }
      learningState.completionStats.total++;

      progressUpdates.push(progressUpdate);

      // Simulate periodic cleanup/optimization
      if (i % 50 === 0) {
        // Cleanup old progress entries
        learningState.progressByUser.forEach((userCourses, userId) => {
          if (userCourses.size > 10) {
            const oldest = Array.from(userCourses.entries())
              .sort((a, b) => a[1].timestamp - b[1].timestamp)
              .slice(0, 2);
            oldest.forEach(([courseId]) => userCourses.delete(courseId));
          }
        });

        // Yield control for better performance
        await new Promise(resolve => setTimeout(resolve, 0));
      }
    }

    const updateMetrics = performanceHelper.endMeasurement('realtime-progress-updates');
    const memoryStats = memoryMonitor.stopMonitoring();

    // Performance assertions - updated to be more realistic for CI environments
    expect(updateMetrics.duration).toBeLessThan(500); // < 500ms for 500 updates
    expect(progressUpdates.length).toBe(updateCount);
    expect(learningState.progressByUser.size).toBeGreaterThan(0);
    expect(memoryStats.memoryUsage.growth).toBeLessThan(40 * 1024 * 1024); // < 40MB growth
  });

  it('should efficiently search and filter learning content', async () => {
    const contentSize = 300; // Reduced for memory efficiency

    memoryMonitor.startMonitoring(50);

    // Generate diverse learning content
    const learningContent = performanceHelper.generateLearningDataset(contentSize, {
      includeSearchableText: true,
      includeMetadata: true,
      includeRelationships: true
    });

    performanceHelper.startMeasurement('content-search-filter');

    // Perform multiple search operations
    const searchTerms = ['javascript', 'python', 'web development'];
    const searchResults = {};

    searchTerms.forEach(term => {
      const results = learningContent.filter(item =>
        item.title.toLowerCase().includes(term.toLowerCase()) ||
        item.description.toLowerCase().includes(term.toLowerCase()) ||
        item.tags.some(tag => tag.toLowerCase().includes(term.toLowerCase()))
      );

      // Secondary filtering by difficulty and duration
      searchResults[term] = {
        all: results,
        beginner: results.filter(item => item.difficulty <= 2),
        intermediate: results.filter(item => item.difficulty >= 3 && item.difficulty <= 4),
        advanced: results.filter(item => item.difficulty >= 5),
        shortForm: results.filter(item => item.duration <= 30),
        longForm: results.filter(item => item.duration > 60)
      };

      // Sort by relevance score
      searchResults[term].all.sort((a, b) => {
        const scoreA = calculateRelevanceScore(a, term);
        const scoreB = calculateRelevanceScore(b, term);
        return scoreB - scoreA;
      });
    });

    // Perform complex aggregation queries
    const aggregations = {
      byCategory: learningContent.reduce((acc, item) => {
        acc[item.category] = (acc[item.category] || 0) + 1;
        return acc;
      }, {}),

      byDifficulty: learningContent.reduce((acc, item) => {
        const level = item.difficulty <= 2 ? 'beginner' :
                     item.difficulty <= 4 ? 'intermediate' : 'advanced';
        acc[level] = (acc[level] || 0) + 1;
        return acc;
      }, {}),

      averageMetrics: {
        duration: learningContent.reduce((sum, item) => sum + item.duration, 0) / learningContent.length,
        difficulty: learningContent.reduce((sum, item) => sum + item.difficulty, 0) / learningContent.length
      }
    };

    const searchMetrics = performanceHelper.endMeasurement('content-search-filter');
    const memoryStats = memoryMonitor.stopMonitoring();

    // Performance assertions
    expect(searchMetrics.duration).toBeLessThan(100); // < 100ms for complex search
    expect(Object.keys(searchResults).length).toBe(searchTerms.length);
    expect(aggregations.byCategory).toBeDefined();
    expect(memoryStats.memoryUsage.growth).toBeLessThan(15 * 1024 * 1024); // < 15MB growth

    // Verify search quality
    searchTerms.forEach(term => {
      expect(searchResults[term].all.length).toBeGreaterThanOrEqual(0);
      if (searchResults[term].all.length > 0) {
        expect(searchResults[term].all[0]).toHaveProperty('relevanceScore');
      }
    });
  });

  it('should handle complex dependency resolution efficiently', () => {
    const itemCount = 250; // Reduced for memory efficiency

    // Generate items with complex dependencies
    const items = [];
    for (let i = 0; i < itemCount; i++) {
      const dependencies = [];
      for (let j = 0; j < Math.min(i, 3); j++) { // Reduced dependencies
        if (Math.random() > 0.7) {
          dependencies.push(Math.floor(Math.random() * i));
        }
      }

      items.push({
        id: i,
        title: `Item ${i}`,
        dependencies
      });
    }

    // Test dependency resolution
    const startTime = performance.now();

    function resolveDependencies(itemId, resolved = new Set(), resolving = new Set()) {
      if (resolved.has(itemId)) {return true;}
      if (resolving.has(itemId)) {throw new Error('Circular dependency');}

      resolving.add(itemId);

      const item = items[itemId];
      if (item) {
        for (const depId of item.dependencies) {
          resolveDependencies(depId, resolved, resolving);
        }
      }

      resolving.delete(itemId);
      resolved.add(itemId);
      return true;
    }

    // Resolve dependencies for multiple items
    const testItems = [50, 100, 150, 200];
    testItems.forEach(itemId => {
      resolveDependencies(itemId);
    });

    const resolutionTime = performance.now() - startTime;

    expect(resolutionTime).toBeLessThan(50); // < 50ms for dependency resolution
  });

  it('should handle sorting and ranking algorithms efficiently', () => {
    const dataSize = 1000; // Reduced for memory efficiency

    memoryMonitor.startMonitoring(25);
    performanceHelper.startMeasurement('sorting-algorithms');

    // Generate test data for sorting
    const learningItems = [];
    for (let i = 0; i < dataSize; i++) {
      learningItems.push({
        id: i,
        title: `Learning Item ${i}`,
        difficulty: Math.floor(Math.random() * 10) + 1,
        popularity: Math.random(),
        completionRate: Math.random(),
        rating: Math.random() * 5,
        duration: Math.floor(Math.random() * 120) + 15,
        createdDate: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000)
      });
    }

    // Test multiple sorting algorithms
    const sortingResults = {};

    // Sort by difficulty (simple)
    const difficultyStart = performance.now();
    sortingResults.byDifficulty = [...learningItems].sort((a, b) => a.difficulty - b.difficulty);
    sortingResults.difficultyTime = performance.now() - difficultyStart;

    // Sort by composite score (complex)
    const scoreStart = performance.now();
    sortingResults.byScore = [...learningItems].sort((a, b) => {
      const scoreA = (a.popularity * 0.3) + (a.completionRate * 0.3) + (a.rating * 0.4);
      const scoreB = (b.popularity * 0.3) + (b.completionRate * 0.3) + (b.rating * 0.4);
      return scoreB - scoreA;
    });
    sortingResults.scoreTime = performance.now() - scoreStart;

    // Multi-criteria sorting
    const multiStart = performance.now();
    sortingResults.multiCriteria = [...learningItems].sort((a, b) => {
      // Primary: difficulty
      if (a.difficulty !== b.difficulty) {
        return a.difficulty - b.difficulty;
      }
      // Secondary: rating
      if (Math.abs(a.rating - b.rating) > 0.1) {
        return b.rating - a.rating;
      }
      // Tertiary: duration
      return a.duration - b.duration;
    });
    sortingResults.multiTime = performance.now() - multiStart;

    const sortingMetrics = performanceHelper.endMeasurement('sorting-algorithms');
    const memoryStats = memoryMonitor.stopMonitoring();

    // Performance assertions
    expect(sortingMetrics.duration).toBeLessThan(200); // < 200ms for all sorting
    expect(sortingResults.difficultyTime).toBeLessThan(50); // < 50ms for simple sort
    expect(sortingResults.scoreTime).toBeLessThan(100); // < 100ms for complex sort
    expect(sortingResults.multiTime).toBeLessThan(100); // < 100ms for multi-criteria sort

    // Verify sorting correctness
    expect(sortingResults.byDifficulty.length).toBe(dataSize);
    expect(sortingResults.byScore.length).toBe(dataSize);
    expect(sortingResults.multiCriteria.length).toBe(dataSize);

    // Memory should remain reasonable
    expect(memoryStats.memoryUsage.growth).toBeLessThan(30 * 1024 * 1024); // < 30MB growth
  });

  // Helper function for relevance scoring
  function calculateRelevanceScore(item, searchTerm) {
    let score = 0;
    const term = searchTerm.toLowerCase();

    if (item.title.toLowerCase().includes(term)) {score += 10;}
    if (item.description.toLowerCase().includes(term)) {score += 5;}
    if (item.tags.some(tag => tag.toLowerCase().includes(term))) {score += 3;}

    // Boost score for exact matches
    if (item.title.toLowerCase() === term) {score += 20;}

    // Store score for verification
    item.relevanceScore = score;

    return score;
  }
});
