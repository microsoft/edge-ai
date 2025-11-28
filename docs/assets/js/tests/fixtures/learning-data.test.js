/**
 * Learning Data Fixtures Validation Tests
 * Ensures test fixtures have correct structure and data types
 */

import { describe, it, expect } from 'vitest';
import {
  testPathMappings,
  testSelections,
  testKataCompletion,
  testSelectionProgressScenarios,
  testStorageKeys,
  createTestData,
  clearTestStorage,
  setupTestStorage,
  setupTestStorageWithDefaults
} from './learning-data.js';

describe('Learning Data Fixtures - Structure Validation', () => {
  it('should have valid testPathMappings structure', () => {
    expect(testPathMappings).toBeDefined();
    expect(typeof testPathMappings).toBe('object');
    expect(Object.keys(testPathMappings).length).toBeGreaterThan(0);

    // Verify each path maps to an array of kata IDs
    Object.entries(testPathMappings).forEach(([pathId, kataIds]) => {
      expect(Array.isArray(kataIds)).toBe(true);
      expect(kataIds.length).toBeGreaterThan(0);
    });
  });

  it('should have valid testSelections array', () => {
    expect(Array.isArray(testSelections)).toBe(true);
    expect(testSelections.length).toBeGreaterThan(0);
    testSelections.forEach(selection => {
      expect(typeof selection).toBe('string');
    });
  });

  it('should have valid testKataCompletion structure', () => {
    expect(testKataCompletion).toBeDefined();
    expect(typeof testKataCompletion).toBe('object');

    Object.entries(testKataCompletion).forEach(([key, value]) => {
      expect(key).toMatch(/^kata-/);
      expect(value).toHaveProperty('completionPercentage');
      expect(value).toHaveProperty('completedPhases');
      expect(value).toHaveProperty('lastUpdated');
      expect(typeof value.completionPercentage).toBe('number');
      expect(Array.isArray(value.completedPhases)).toBe(true);
    });
  });
});

describe('Learning Data Fixtures - Selection/Progress Scenarios', () => {
  it('should have valid selectedNoProgress scenario', () => {
    const scenario = testSelectionProgressScenarios.selectedNoProgress;
    expect(scenario).toBeDefined();
    expect(Array.isArray(scenario.selectedLearningPaths)).toBe(true);
    expect(scenario.selectedLearningPaths.length).toBeGreaterThan(0);
    expect(Object.keys(scenario.kataCompletion).length).toBe(0);
  });

  it('should have valid unselectedWithProgress scenario', () => {
    const scenario = testSelectionProgressScenarios.unselectedWithProgress;
    expect(scenario).toBeDefined();
    expect(Array.isArray(scenario.selectedLearningPaths)).toBe(true);
    expect(scenario.selectedLearningPaths.length).toBe(0);
    expect(Object.keys(scenario.kataCompletion).length).toBeGreaterThan(0);
  });

  it('should have valid selectedAndComplete scenario', () => {
    const scenario = testSelectionProgressScenarios.selectedAndComplete;
    expect(scenario).toBeDefined();
    expect(scenario.selectedLearningPaths.length).toBeGreaterThan(0);
    expect(Object.keys(scenario.kataCompletion).length).toBeGreaterThan(0);
  });

  it('should have valid pathSelectedNoProgress scenario', () => {
    const scenario = testSelectionProgressScenarios.pathSelectedNoProgress;
    expect(scenario).toBeDefined();
    expect(scenario.selectedLearningPaths.length).toBeGreaterThan(0);
    expect(Object.keys(scenario.kataCompletion).length).toBe(0);
  });
});

describe('Learning Data Fixtures - Storage Keys', () => {
  it('should have correct storage key patterns', () => {
    expect(testStorageKeys.selections).toBe('selectedLearningPaths');
  });

  it('should generate correct kata keys', () => {
    const kataId = 'ai-assisted-engineering-100';
    expect(testStorageKeys.kata(kataId)).toBe('kata-ai-assisted-engineering-100');
  });
});

describe('Learning Data Fixtures - Helper Functions', () => {
  it('should create deep clones with createTestData', () => {
    const data1 = createTestData();
    const data2 = createTestData();

    expect(data1).toEqual(data2);
    expect(data1.selections).not.toBe(data2.selections);
    expect(data1.pathMappings).not.toBe(data2.pathMappings);
  });

  it('should clear test storage', () => {
    localStorage.setItem('selectedLearningPaths', JSON.stringify(['test']));
    localStorage.setItem('kata-test', JSON.stringify({ test: true }));

    clearTestStorage();

    expect(localStorage.getItem('selectedLearningPaths')).toBeNull();
    expect(localStorage.getItem('kata-test')).toBeNull();
  });

  it('should setup test storage with all data', () => {
    clearTestStorage();
    setupTestStorageWithDefaults();

    expect(localStorage.getItem('selectedLearningPaths')).toBeTruthy();
    expect(localStorage.getItem('kata-ai-assisted-engineering-100')).toBeTruthy();

    clearTestStorage();
  });

  it('should setup test storage with selective data', () => {
    clearTestStorage();
    setupTestStorageWithDefaults({
      includeSelections: true,
      includeKataCompletion: false
    });

    expect(localStorage.getItem('selectedLearningPaths')).toBeTruthy();
    expect(localStorage.getItem('kata-ai-assisted-engineering-100')).toBeNull();

    clearTestStorage();
  });
});
