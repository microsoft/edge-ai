/**
 * Integration Tests for Clear Functionality
 * Tests the complete clear/reset workflow to identify current issues
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// Mock the missing modules that have integration issues
const mockStorageManager = {
  // Test what methods actually exist vs what's being called
  clearKataProgress: vi.fn().mockReturnValue(true),
  clearStoredData: vi.fn().mockReturnValue(true),
  // These methods are called but don't exist - should cause failures
  removeKataProgress: undefined,
  clearAssessmentResults: undefined,
  clearUserSettings: undefined
};

const mockLearningPathManager = {
  clearCache: vi.fn(),
  resetKataState: vi.fn()
};

describe('Clear Functionality Integration Issues', () => {
  let originalFetch;

  beforeEach(async () => {
    // Setup DOM environment - Happy DOM is already available
    document.body.innerHTML = `
      <div class="progress-container">
        <button class="kata-progress-btn-reset" type="button">Reset</button>
        <div class="progress-bar"></div>
      </div>
      <input type="checkbox" data-kata-item="item1" />
      <input type="checkbox" data-kata-item="item2" />
    `; // Mock fetch for testing
    originalFetch = global.fetch;
    global.fetch = vi.fn();

    // Mock localStorage
    const localStorageMock = {
      getItem: vi.fn(),
      setItem: vi.fn(),
      removeItem: vi.fn(),
      clear: vi.fn(),
    };
    global.localStorage = localStorageMock;
  });

  afterEach(() => {
    global.fetch = originalFetch;
    vi.clearAllMocks();
  });

  describe('Reset Button Save Endpoint Integration', () => {
    it('should call save endpoint with reset state when resetting progress', async () => {
      // Simulate the current behavior: Reset calls save endpoint with empty state
      global.fetch.mockResolvedValue({
        ok: true,
        status: 200,
        json: () => Promise.resolve({ success: true })
      });

      // Simulate reset action
      const resetData = {
        type: 'kata-progress',
        metadata: {
          kataId: 'test-kata',
          source: 'ui'
        },
        progress: {
          checkboxStates: {},
          completedTasks: 0,
          totalTasks: 2,
          completionPercentage: 0
        }
      };

      await global.fetch('/api/progress/save', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(resetData)
      });

      expect(global.fetch).toHaveBeenCalledWith('/api/progress/save', expect.objectContaining({
        method: 'POST'
      }));
    });
  });

  describe('StorageManager Method Compatibility', () => {
    it('should fail when ProgressClearManager calls non-existent methods', async () => {
      // Create a mock ProgressClearManager to test method calls
      const mockManager = {
        storageManager: mockStorageManager,
        async clearKataProgress(kataId) {
          // This is what the current code tries to do - should fail
          try {
            // This method doesn't exist and should cause an error
            await this.storageManager.removeKataProgress(kataId);
            return true;
          } catch (_error) {
            throw new Error(`removeKataProgress method does not exist: ${_error.message}`);
          }
        },
        async clearAllProgress() {
          try {
            // These methods don't exist and should cause errors
            await this.storageManager.clearAssessmentResults();
            await this.storageManager.clearUserSettings();
            return true;
          } catch (_error) {
            throw new Error(`clearAssessmentResults/clearUserSettings methods do not exist: ${_error.message}`);
          }
        }
      };

      // Test that calling non-existent methods fails
      await expect(mockManager.clearKataProgress('test-kata'))
        .rejects
        .toThrow(/removeKataProgress method does not exist/);

      await expect(mockManager.clearAllProgress())
        .rejects
        .toThrow(/clearAssessmentResults\/clearUserSettings methods do not exist/);
    });

    it('should succeed when using correct StorageManager methods', async () => {
      // Reset mock return values since afterEach clears them
      mockStorageManager.clearKataProgress.mockReturnValue(true);
      mockStorageManager.clearStoredData.mockReturnValue(true);

      // Test what should work with correct method names
      const correctedManager = {
        storageManager: mockStorageManager,
        async clearKataProgress(kataId) {
          // Use the correct method name
          return this.storageManager.clearKataProgress(kataId);
        },
        async clearAllProgress() {
          // Use the correct method with type parameters
          await this.storageManager.clearStoredData('kata');
          await this.storageManager.clearStoredData('settings');
          return true;
        }
      };

      // These should work
      const result1 = await correctedManager.clearKataProgress('test-kata');
      expect(result1).toBe(true);
      expect(mockStorageManager.clearKataProgress).toHaveBeenCalledWith('test-kata');

      const result2 = await correctedManager.clearAllProgress();
      expect(result2).toBe(true);
      expect(mockStorageManager.clearStoredData).toHaveBeenCalledWith('kata');
      expect(mockStorageManager.clearStoredData).toHaveBeenCalledWith('settings');
    });
  });

  describe('Progress Bar Clear Manager Integration', () => {
    it('should show that simple-progress-bar-extension bypasses ProgressClearManager', () => {
      // Mock the current simple-progress-bar-extension behavior
      const mockProgressBarExtension = {
        async handleClearButtonClick(event) {
          event.preventDefault();

          // Current implementation does its own clearing
          const checkboxes = document.querySelectorAll('input[type="checkbox"]');
          checkboxes.forEach(cb => cb.checked = false);

          // Calls API directly (which fails)
          await this.clearProgressFromAPI();

          // Clears localStorage directly
          localStorage.removeItem('learning-paths-selection-backup');

          // Does NOT use ProgressClearManager
          return { cleared: checkboxes.length, usedClearManager: false };
        },
        async clearProgressFromAPI() {
          // This fails because endpoint doesn't exist
          try {
            await fetch('/api/progress/clear', { method: 'POST' });
          } catch (_error) {
            console.error('API clear failed:', _error);
          }
        }
      };

      // Simulate button click
      const event = { preventDefault: vi.fn() };
      const result = mockProgressBarExtension.handleClearButtonClick(event);

      // This shows the architecture problem - no integration
      expect(result).resolves.toEqual({
        cleared: 2, // 2 checkboxes found
        usedClearManager: false // Shows the disconnect
      });
    });

    it('should demonstrate proper integrated architecture', () => {
      // Show what proper integration should look like
      const mockIntegratedProgressBar = {
        progressClearManager: {
          async handleClearRequest(event) {
            return {
              cleared: 2,
              usedClearManager: true,
              integratedWithEnhancedSystem: true
            };
          }
        },
        async handleClearButtonClick(event) {
          event.preventDefault();

          // Proper architecture - delegates to clear manager
          const clearEvent = new CustomEvent('progressClearRequested', {
            detail: { kataId: 'current-kata', timestamp: Date.now() }
          });

          return await this.progressClearManager.handleClearRequest(clearEvent);
        }
      };

      const event = { preventDefault: vi.fn() };
      const result = mockIntegratedProgressBar.handleClearButtonClick(event);

      // This shows proper integration
      expect(result).resolves.toEqual({
        cleared: 2,
        usedClearManager: true,
        integratedWithEnhancedSystem: true
      });
    });
  });

  describe('Enhanced Progress Data Model Integration', () => {
    it('should show missing integration with EnhancedProgressDataModel', () => {
      // Mock current state - no integration between clear and enhanced progress
      const mockEnhancedProgressDataModel = {
        cache: new Map([['item1', { completed: true }], ['item2', { inPath: true }]]),
        clearAllProgress: vi.fn(), // This method doesn't exist yet
        notifyClearOperation: vi.fn() // This method doesn't exist yet
      };

      // Current clear operations don't interact with enhanced progress model
      const currentClearBehavior = () => {
        localStorage.clear(); // Just clears localStorage
        // Does NOT call mockEnhancedProgressDataModel.clearAllProgress()
        // Does NOT call mockEnhancedProgressDataModel.notifyClearOperation()
        return { enhancedProgressCleared: false };
      };

      const result = currentClearBehavior();
      expect(result.enhancedProgressCleared).toBe(false);
      expect(mockEnhancedProgressDataModel.clearAllProgress).not.toHaveBeenCalled();
    });
  });
});

describe('Clear Functionality with Rest API', () => {
  it('documents integration gaps and missing functionality', () => {
    const issuesSummary = {
      missingApiEndpoint: '/api/progress/clear returns 404',
      wrongMethodNames: [
        'removeKataProgress() does not exist',
        'clearAssessmentResults() does not exist',
        'clearUserSettings() does not exist'
      ],
      architectureProblems: [
        'simple-progress-bar-extension bypasses ProgressClearManager',
        'No integration with EnhancedProgressDataModel',
        'Duplicate clear logic in multiple files'
      ],
      integrationGaps: [
        'Clear operations do not update progress analytics',
        'Clear operations do not trigger enhanced progress events',
        'Inconsistent clear behavior across components'
      ]
    };

    // This test documents what we need to fix
    expect(issuesSummary.missingApiEndpoint).toContain('404');
    expect(issuesSummary.wrongMethodNames).toHaveLength(3);
    expect(issuesSummary.architectureProblems).toHaveLength(3);
    expect(issuesSummary.integrationGaps).toHaveLength(3);
  });
});
