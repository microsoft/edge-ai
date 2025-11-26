/**
 * Selection/Progress Independence Tests
 *
 * Tests that verify selection state (selectedLearningPaths) and completion state
 * (kata-* localStorage keys) are completely independent:
 * - Selecting a kata does NOT mark it complete
 * - Completing a kata does NOT automatically select it
 * - Progress calculation ONLY reads from kata-* keys, never from selection state
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import {
  testSelectionProgressScenarios,
  testStorageKeys,
  setupTestStorage,
  clearTestStorage
} from '../fixtures/learning-data.js';
import { progressMixin } from '../../plugins/learning-path-dashboard/progress.js';

describe('Selection/Progress Independence', () => {
  beforeEach(() => {
    clearTestStorage();
    document.body.innerHTML = '<div id="app"></div>';
  });

  afterEach(() => {
    clearTestStorage();
    document.body.innerHTML = '';
  });

  describe('Selection State Does Not Affect Progress', () => {
    it('should show 0% progress for selected kata with no completion data', () => {
      // Setup: Kata selected but no progress saved
      const scenario = testSelectionProgressScenarios.selectedNoProgress;
      setupTestStorage(scenario);

      // Verify: selectedLearningPaths has kata
      const selections = JSON.parse(localStorage.getItem(testStorageKeys.selections) || '[]');
      expect(selections).toContain('ai-assisted-engineering-100');

      // Verify: No kata completion data
      const kata1Key = testStorageKeys.kata('ai-assisted-engineering-110');
      const kataData = localStorage.getItem(kata1Key);
      expect(kataData).toBeNull();

      // Verify: Progress calculation returns false (not complete) despite selection
      const progressInstance = Object.create(progressMixin);
      const isComplete = progressInstance.isStepCompleted('ai-assisted-engineering-100', 'ai-assisted-engineering-110');
      expect(isComplete).toBe(false);
      // Expected: Progress calculation should return 0%, not read checkbox state
    });

    it('should show actual progress for unselected kata with completion data', () => {
      // Setup: Kata NOT selected but has 50% progress saved
      const scenario = testSelectionProgressScenarios.unselectedWithProgress;
      setupTestStorage(scenario);

      // Verify: selectedLearningPaths is empty
      const selections = JSON.parse(localStorage.getItem(testStorageKeys.selections) || '[]');
      expect(selections).toEqual([]);

      // Verify: Kata has 50% completion
      const kataKey = testStorageKeys.kata('ai-assisted-engineering-110');
      const kataData = JSON.parse(localStorage.getItem(kataKey));
      expect(kataData.completionPercentage).toBe(50);
      expect(kataData.completedPhases).toEqual(['phase-1', 'phase-2']);

      // TODO: Import getPathProgressPercentage and verify it returns 50
      // Expected: Progress calculation should return 50%, ignoring selection state
    });

    it('should show 100% only when kata completion data says so', () => {
      // Setup: Kata selected AND has 100% progress saved
      const scenario = testSelectionProgressScenarios.selectedAndComplete;
      setupTestStorage(scenario);

      // Verify: Kata has 100% completion
      const kataKey = testStorageKeys.kata('ai-assisted-engineering-110');
      const kataData = JSON.parse(localStorage.getItem(kataKey));
      expect(kataData.completionPercentage).toBe(100);

      // TODO: Import getPathProgressPercentage and verify it returns 100
      // Expected: Progress calculation should return 100% based on kata data
    });
  });

  describe('Path Selection Does Not Affect Progress', () => {
    it('should show 0% progress for selected path with no kata completions', () => {
      // Setup: Path selected (auto-selects katas) but no progress on any kata
      const scenario = testSelectionProgressScenarios.pathSelectedNoProgress;
      setupTestStorage(scenario);

      // Verify: Path is selected
      const selections = JSON.parse(localStorage.getItem(testStorageKeys.selections) || '[]');
      expect(selections).toContain('ai-assisted-engineering-100');

      // Verify: No kata completion data
      const kata1Key = testStorageKeys.kata('ai-assisted-engineering-110');
      const kata2Key = testStorageKeys.kata('ai-assisted-engineering-120');
      expect(localStorage.getItem(kata1Key)).toBeNull();
      expect(localStorage.getItem(kata2Key)).toBeNull();

      // Verify: Progress calculation returns false (not complete) for both selected katas
      const progressInstance = Object.create(progressMixin);
      const isComplete1 = progressInstance.isStepCompleted('ai-assisted-engineering-100', 'ai-assisted-engineering-110');
      const isComplete2 = progressInstance.isStepCompleted('ai-assisted-engineering-100', 'ai-assisted-engineering-120');
      expect(isComplete1).toBe(false);
      expect(isComplete2).toBe(false);
      // Expected: Progress should be 0% even though path is selected
    });
  });

  describe('Checkbox State vs Completion Data', () => {
    it('should ignore checkbox.checked when calculating progress', () => {
      // This test validates the bug fix: progress calculation must NOT
      // read checkbox.checked state, only kata-* localStorage data

      // Setup: Create checkboxes in selected state
      document.body.innerHTML = `
        <div id="app">
          <input type="checkbox" id="kata-1" checked>
          <input type="checkbox" id="kata-2" checked>
          <input type="checkbox" id="kata-3">
        </div>
      `;

      // Setup: No kata completion data at all
      clearTestStorage();
      localStorage.setItem(testStorageKeys.selections, JSON.stringify(['ai-assisted-engineering-100']));

      // Verify: Checkboxes are checked
      const checkboxes = document.querySelectorAll('input[type="checkbox"]');
      const checkedCount = Array.from(checkboxes).filter(cb => cb.checked).length;
      expect(checkedCount).toBe(2);

      // Verify: Progress calculation ignores checkbox state, reads only kata storage
      const progressInstance = Object.create(progressMixin);
      const isComplete1 = progressInstance.isStepCompleted('ai-assisted-engineering-100', 'kata-1');
      const isComplete2 = progressInstance.isStepCompleted('ai-assisted-engineering-100', 'kata-2');
      const isComplete3 = progressInstance.isStepCompleted('ai-assisted-engineering-100', 'kata-3');
      expect(isComplete1).toBe(false);
      expect(isComplete2).toBe(false);
      expect(isComplete3).toBe(false);
      // Expected: Despite 2 checkboxes being checked, progress should be 0%
      // because no kata-* completion data exists
    });

    it('should return true only when kata storage shows 100% completion', () => {
      // This test verifies the fix: isStepCompleted reads kata-* storage

      // Setup: Kata with 50% completion
      localStorage.setItem('kata-test-1', JSON.stringify({
        completionPercentage: 50,
        completedPhases: [1]
      }));

      // Setup: Kata with 100% completion
      localStorage.setItem('kata-test-2', JSON.stringify({
        completionPercentage: 100,
        completedPhases: [1, 2, 3]
      }));

      // Verify: Only 100% complete kata returns true
      const progressInstance = Object.create(progressMixin);
      expect(progressInstance.isStepCompleted('path-1', 'test-1')).toBe(false);
      expect(progressInstance.isStepCompleted('path-1', 'test-2')).toBe(true);
    });

    it('should never call querySelector for checkbox.checked in isStepCompleted', () => {
      // Regression test: Verify the bug fix - no DOM queries for checkbox state

      // Setup: Spy on querySelector to catch any calls
      const querySelectorSpy = vi.spyOn(document, 'querySelector');

      // Setup: Kata with completion data
      localStorage.setItem('kata-test-3', JSON.stringify({
        completionPercentage: 100,
        completedPhases: [1, 2, 3]
      }));

      // Act: Check if step is completed
      const progressInstance = Object.create(progressMixin);
      progressInstance.isStepCompleted('path-1', 'test-3');

      // Assert: querySelector should NOT be called with checkbox selectors
      const checkboxQueries = querySelectorSpy.mock.calls.filter(call => {
        const selector = call[0];
        return selector && (
          selector.includes('[data-path-id=') ||
          selector.includes('[data-step-id=') ||
          selector.includes('input[type="checkbox"]')
        );
      });

      expect(checkboxQueries).toHaveLength(0);
      querySelectorSpy.mockRestore();
    });
  });
});
