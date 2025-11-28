/**
 * Integration tests for enhanced progress persistence functionality
 * Validates data flow between ProgressDataModel, ProgressPersistence, and UI components
 *
 * Tests the complete pipeline:
 * 1. User actions (checkbox clicks, path completions)
 * 2. Data model updates
 * 3. Persistence layer storage/retrieval
 * 4. UI state synchronization
 * 5. Error handling and fallbacks
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { EnhancedProgressPersistence } from '../../features/enhanced-progress-persistence.js';

describe('Enhanced Progress Persistence Integration', () => {
  let localStorage;
  let enhancedProgressSystem;

  // Mock test data for learning path items
  const mockLearningPathHTML = `
    <div class="learning-path-items">
      <!-- AI Fundamentals item -->
      <div class="learning-item" data-item-id="ai-fundamentals">
        <div class="item-metadata" data-estimated-minutes="30" data-difficulty="beginner">
          <h3>AI Fundamentals</h3>
          <p>Basic introduction to artificial intelligence concepts</p>
        </div>
        <div class="item-controls">
          <label>
            <input type="checkbox" data-action="add-to-path" data-item-id="ai-fundamentals">
            Add to Learning Path
          </label>
          <label>
            <input type="checkbox" data-action="mark-completed" data-item-id="ai-fundamentals">
            Mark Completed
          </label>
        </div>
      </div>

      <!-- Machine Learning Basics item -->
      <div class="learning-item" data-item-id="ml-basics">
        <div class="item-metadata" data-estimated-minutes="45" data-difficulty="intermediate">
          <h3>Machine Learning Basics</h3>
          <p>Introduction to machine learning algorithms and techniques</p>
        </div>
        <div class="item-controls">
          <label>
            <input type="checkbox" data-action="add-to-path" data-item-id="ml-basics">
            Add to Learning Path
          </label>
          <label>
            <input type="checkbox" data-action="mark-completed" data-item-id="ml-basics">
            Mark Completed
          </label>
        </div>
      </div>

      <!-- Deep Learning item -->
      <div class="learning-item" data-item-id="deep-learning">
        <div class="item-metadata" data-estimated-minutes="60" data-difficulty="advanced">
          <h3>Deep Learning</h3>
          <p>Advanced neural networks and deep learning concepts</p>
        </div>
        <div class="item-controls">
          <label>
            <input type="checkbox" data-action="add-to-path" data-item-id="deep-learning">
            Add to Learning Path
          </label>
          <label>
            <input type="checkbox" data-action="mark-completed" data-item-id="deep-learning">
            Mark Completed
          </label>
        </div>
      </div>
    </div>

    <!-- Progress display elements -->
    <div class="progress-stats">
      <div id="items-in-path">
        <span>Items in Path:</span>
        <span class="value">0</span>
      </div>
      <div id="items-completed">
        <span>Completed:</span>
        <span class="value">0</span>
      </div>
      <div id="estimated-time">
        <span>Estimated Time:</span>
        <span class="value">0 min</span>
      </div>
    </div>

    <!-- Progress bar -->
    <div class="progress-bar">
      <div class="progress-fill" style="width: 0%;"></div>
    </div>

    <!-- Connection status indicator -->
    <div id="connection-status" class="online">Online</div>
  `;

  beforeEach(() => {
    // Setup DOM environment using happy-dom (already configured in vitest)
    // The document and window are provided by happy-dom environment
    document.body.innerHTML = mockLearningPathHTML;

    // Mock localStorage
    localStorage = {
      getItem: vi.fn(),
      setItem: vi.fn(),
      removeItem: vi.fn(),
      clear: vi.fn()
    };
    global.localStorage = localStorage;

    // Mock fetch for API calls
    global.fetch = vi.fn();

    // Reset system instance
    enhancedProgressSystem = null;
  });

  afterEach(() => {
    // Cleanup
    if (enhancedProgressSystem) {
      enhancedProgressSystem.destroy();
    }
    vi.clearAllMocks();

    // Clear DOM
    document.body.innerHTML = '';
  });

  describe('End-to-End Dual Checkbox Interactions', () => {
    it('should handle complete user workflow: add to path → mark completed → sync', async () => {
      // RED PHASE: This test should FAIL - enhanced system doesn't exist yet

      enhancedProgressSystem = new EnhancedProgressPersistence();

      // Mock API calls - load first, then save
      global.fetch.mockImplementation((url, _options) => {
        if (url === '/api/progress/load') {
          return Promise.resolve({
            ok: true,
            json: () => Promise.resolve({
              success: true,
              data: { version: '2.0', items: [], metadata: { lastUpdated: new Date().toISOString() } }
            })
          });
        } else if (url === '/api/progress/save') {
          return Promise.resolve({
            ok: true,
            json: () => Promise.resolve({
              success: true,
              data: { synced: true, timestamp: new Date().toISOString() }
            })
          });
        }
        return Promise.reject(new Error(`Unexpected URL: ${ url}`));
      });

      // Initialize system
      await enhancedProgressSystem.initialize();

      // Verify initial load call
      expect(fetch).toHaveBeenCalledWith('/api/progress/load', {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' }
      });

      // Reset fetch mock call count to focus on save operations
      vi.clearAllMocks();
      global.fetch.mockImplementation((url, _options) => {
        if (url === '/api/progress/save') {
          return Promise.resolve({
            ok: true,
            json: () => Promise.resolve({
              success: true,
              data: { synced: true, timestamp: new Date().toISOString() }
            })
          });
        }
        return Promise.reject(new Error(`Unexpected URL: ${ url}`));
      });

      // Step 1: User adds AI Fundamentals to learning path
      const pathCheckbox = document.querySelector('[data-item-id="ai-fundamentals"][data-action="add-to-path"]');
      pathCheckbox.checked = true;
      pathCheckbox.dispatchEvent(new Event('change', { bubbles: true }));

      // Should immediately update UI and trigger persistence
      const pathStat = document.querySelector('#items-in-path .value');
      expect(pathStat.textContent).toBe('1');

      // Wait for debounced save operation to complete (200ms debounce + buffer)
      await new Promise(resolve => setTimeout(resolve, 250));

      // Should trigger API sync
      expect(fetch).toHaveBeenCalledWith('/api/progress/save', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: expect.stringContaining('"ai-fundamentals"')
      });

      // Step 2: User marks AI Fundamentals as completed (wait to ensure separate API call)
      await new Promise(resolve => setTimeout(resolve, 250)); // Wait for first debounce to complete
      const completionCheckbox = document.querySelector('[data-item-id="ai-fundamentals"][data-action="mark-completed"]');
      completionCheckbox.checked = true;
      completionCheckbox.dispatchEvent(new Event('change', { bubbles: true }));

      // Should update completion stats
      const completedStat = document.querySelector('#items-completed .value');
      expect(completedStat.textContent).toBe('1');

      // Should update progress bar
      const progressFill = document.querySelector('.progress-fill');
      expect(progressFill.style.width).toBe('100.00%'); // 1/1 completed

      // Wait for debounced save operation to complete (200ms debounce + buffer)
      await new Promise(resolve => setTimeout(resolve, 250));

      // Should trigger API sync (with both operations batched due to debouncing)
      expect(fetch).toHaveBeenCalledTimes(2); // 1 load + 1 batched save

      // Verify final state
      const currentData = enhancedProgressSystem.getCurrentData();
      expect(currentData.items).toHaveLength(1);
      expect(currentData.items[0]).toMatchObject({
        id: 'ai-fundamentals',
        addedToPath: true,
        completed: true
      });
    });

    it.skip('should prevent completion without adding to path (business rule)', async () => {
      // RED PHASE: This test should FAIL - business rule validation doesn't exist yet

      // Mock successful server load
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ items: [] })
      });

      enhancedProgressSystem = new EnhancedProgressPersistence({
        requirePathForCompletion: true // Business rule: must add to path before completing
      });

      await enhancedProgressSystem.initialize();

      // Try to mark as completed without adding to path first
      const completionCheckbox = document.querySelector('[data-item-id="ai-fundamentals"][data-action="mark-completed"]');
      completionCheckbox.checked = true;
      completionCheckbox.dispatchEvent(new Event('change', { bubbles: true }));

      // Wait for async operation to complete
      await new Promise(resolve => setTimeout(resolve, 10));

      // Checkbox should be unchecked (business rule prevents this)
      expect(completionCheckbox.checked).toBe(false);

      // Should show warning notification
      const notification = document.querySelector('.notification.warning');
      expect(notification).toBeTruthy();
      expect(notification.textContent).toBe('Add to learning path first');

      // Should not update completion stats
      const completedStat = document.querySelector('#items-completed .value');
      expect(completedStat.textContent).toBe('0');
    });

    it.skip('should handle API errors gracefully and show user feedback', async () => {
      // RED PHASE: This test should FAIL - error handling doesn't exist yet

      // Set up fake timers for debouncing and retry logic
      vi.useFakeTimers();

      enhancedProgressSystem = new EnhancedProgressPersistence();

      // Mock successful initial load, then failures for saves
      global.fetch
        .mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve({ items: [] })
        })
        .mockRejectedValue(new Error('Network error'));

      await enhancedProgressSystem.initialize();

      // Trigger save that will fail
      const pathCheckbox = document.querySelector('[data-item-id="ai-fundamentals"][data-action="add-to-path"]');
      pathCheckbox.checked = true;
      pathCheckbox.dispatchEvent(new Event('change', { bubbles: true }));

      // Advance timers to trigger debouncing and retry attempts
      await vi.runAllTimersAsync();

      // Should still update UI optimistically
      const pathStat = document.querySelector('#items-in-path .value');
      expect(pathStat.textContent).toBe('1');

      // Should show offline status
      const connectionStatus = document.querySelector('#connection-status');
      expect(connectionStatus.className).toBe('offline');
      expect(connectionStatus.textContent).toBe('Offline - Changes saved locally');

      // Should queue the update for later sync
      expect(enhancedProgressSystem.getQueuedUpdates()).toHaveLength(1);

      // Clean up fake timers
      vi.useRealTimers();
    });

    it.skip('should retry failed requests with exponential backoff', async () => {
      // RED PHASE: This test should FAIL - retry logic doesn't exist yet

      // Set up fake timers for retry delays
      vi.useFakeTimers();

      enhancedProgressSystem = new EnhancedProgressPersistence();

      // Mock successful initial load, then fail saves, finally succeed
      global.fetch
        .mockResolvedValueOnce({ // loadFromServer during init - success
          ok: true,
          json: () => Promise.resolve({ items: [] })
        })
        .mockRejectedValueOnce(new Error('Server error')) // first save attempt
        .mockRejectedValueOnce(new Error('Server error')) // second save attempt (retry 1)
        .mockRejectedValueOnce(new Error('Server error')) // third save attempt (retry 2)
        .mockResolvedValueOnce({ // fourth save attempt (retry 3) - success
          ok: true,
          json: () => Promise.resolve({ success: true })
        });

      await enhancedProgressSystem.initialize();

      // Trigger save
      const pathCheckbox = document.querySelector('[data-item-id="ai-fundamentals"][data-action="add-to-path"]');
      pathCheckbox.checked = true;
      pathCheckbox.dispatchEvent(new Event('change', { bubbles: true }));

      // Advance timers to complete all retry attempts
      await vi.runAllTimersAsync();

      // Should have attempted 5 times total (1 load + 4 save attempts)
      expect(fetch).toHaveBeenCalledTimes(5);

      // Should eventually succeed and stay online
      const connectionStatus = document.querySelector('#connection-status');
      expect(connectionStatus.className).toBe('online');

      // Should use exponential backoff delays
      const retryDelays = enhancedProgressSystem.getRetryDelays();
      expect(retryDelays).toEqual([1000, 2000, 4000, 8000, 16000]);

      // Clean up fake timers
      vi.useRealTimers();
    });

    it('should queue updates when offline and sync when back online', async () => {
      // RED PHASE: This test should FAIL - offline queuing doesn't exist yet

      // Set up fake timers for debouncing
      vi.useFakeTimers();

      enhancedProgressSystem = new EnhancedProgressPersistence();

      // Force offline mode BEFORE initialization to prevent any API calls
      enhancedProgressSystem.setOfflineMode(true);
      await enhancedProgressSystem.initialize();

      // Make changes while offline
      const pathCheckbox = document.querySelector('[data-item-id="ai-fundamentals"][data-action="add-to-path"]');
      pathCheckbox.checked = true;
      pathCheckbox.dispatchEvent(new Event('change', { bubbles: true }));

      const completionCheckbox = document.querySelector('[data-item-id="ai-fundamentals"][data-action="mark-completed"]');
      completionCheckbox.checked = true;
      completionCheckbox.dispatchEvent(new Event('change', { bubbles: true }));

      // Wait a moment for DOM events to complete, then advance timers for debouncing
      await vi.runOnlyPendingTimersAsync(); // Run any immediate timers
      vi.advanceTimersByTime(300); // Advance past the 200ms debounce delay

      // Add some debug logging
      console.log('Queue length after timer advancement:', enhancedProgressSystem.getQueuedUpdates().length);
      console.log('Queue contents:', enhancedProgressSystem.getQueuedUpdates());

      // Should queue updates
      expect(enhancedProgressSystem.getQueuedUpdates()).toHaveLength(2); // Should not have called API
      expect(fetch).not.toHaveBeenCalled();

      // Mock successful API response for sync
      global.fetch.mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ success: true })
      });

      // Go back online
      await enhancedProgressSystem.setOnlineMode();

      // Should sync queued updates
      expect(fetch).toHaveBeenCalledWith('/api/progress/batch-sync', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: expect.stringContaining('"updates"')
      });

      // Queue should be cleared after successful sync
      expect(enhancedProgressSystem.getQueuedUpdates()).toHaveLength(0);

      // Restore real timers
      vi.useRealTimers();
    });

    it('should handle periodic background sync', async () => {
      // RED PHASE: This test should FAIL - sync mechanism doesn't exist yet

      // Mock successful initial load
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ items: [] })
      });

      enhancedProgressSystem = new EnhancedProgressPersistence();
      await enhancedProgressSystem.initialize();

      // Mock successful sync response
      global.fetch.mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ success: true })
      });

      // Queue some updates offline
      enhancedProgressSystem.setOfflineMode(true);
      enhancedProgressSystem.queueUpdate({
        action: 'ADD_TO_PATH',
        itemId: 'ai-fundamentals',
        timestamp: new Date().toISOString()
      });

      // Go back online (should start periodic sync)
      await enhancedProgressSystem.setOnlineMode();

      // Should have started background sync for queued items
      expect(fetch).toHaveBeenCalled();
    });

    it.skip('should handle cross-tab synchronization via localStorage events', async () => {
      // RED PHASE: This test should FAIL - cross-tab sync doesn't exist yet

      // Mock successful initial load
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ items: [] })
      });

      enhancedProgressSystem = new EnhancedProgressPersistence();
      await enhancedProgressSystem.initialize();

      // Simulate storage event from another tab
      const newProgressData = {
        version: '2.0.0',
        items: [{
          id: 'ml-basics',
          addedToPath: true,
          completed: false,
          timestamp: new Date().toISOString()
        }],
        metadata: {
          timestamp: new Date().toISOString(),
          source: 'other-tab'
        }
      };

      // Trigger storage event
      const storageEvent = new StorageEvent('storage', {
        key: 'learning-paths-progress-v2',
        newValue: JSON.stringify(newProgressData),
        oldValue: null
      });

      globalThis.dispatchEvent(storageEvent);

      // Should update UI to reflect changes from other tab
      const mlCheckbox = document.querySelector('[data-item-id="ml-basics"][data-action="add-to-path"]');
      expect(mlCheckbox.checked).toBe(true);

      // Should show sync notification
      const notification = document.querySelector('.notification.info');
      expect(notification).toBeTruthy();
      expect(notification.textContent).toBe('Progress updated from another tab');
    });



    it('should handle batch sync of multiple updates', async () => {
      // RED PHASE: This test should FAIL - batch sync doesn't exist yet

      // Mock successful initial load
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ items: [] })
      });

      enhancedProgressSystem = new EnhancedProgressPersistence();
      await enhancedProgressSystem.initialize();

      // Queue multiple updates
      enhancedProgressSystem.queueUpdate({
        action: 'ADD_TO_PATH',
        itemId: 'ai-fundamentals',
        timestamp: new Date().toISOString()
      });
      enhancedProgressSystem.queueUpdate({
        action: 'MARK_COMPLETED',
        itemId: 'ai-fundamentals',
        timestamp: new Date().toISOString()
      });
      enhancedProgressSystem.queueUpdate({
        action: 'ADD_TO_PATH',
        itemId: 'ml-basics',
        timestamp: new Date().toISOString()
      });

      // Mock API success
      global.fetch.mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ success: true })
      });

      // Trigger batch sync
      await enhancedProgressSystem.setOnlineMode();

      // Should send all updates in single batch request
      expect(fetch).toHaveBeenCalledWith('/api/progress/batch-sync', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: expect.stringContaining('"updates"')
      });

      // Find the batch-sync call
      const batchSyncCall = fetch.mock.calls.find(call => call[0] === '/api/progress/batch-sync');
      const callBody = JSON.parse(batchSyncCall[1].body);
      expect(callBody.updates).toHaveLength(3);
    });

    it.skip('should resolve data conflicts using last-write-wins strategy', async () => {
      // RED PHASE: This test should FAIL - conflict resolution doesn't exist yet

      // Mock successful initial load
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ items: [] })
      });

      enhancedProgressSystem = new EnhancedProgressPersistence();
      await enhancedProgressSystem.initialize();

      // Set current data with recent timestamp
      const currentTime = new Date();
      enhancedProgressSystem.updateItem('ai-fundamentals', {
        addedToPath: true,
        completed: false
      });

      // Simulate conflicting data from storage with older timestamp
      const olderTime = new Date(currentTime.getTime() - 5000); // 5 seconds ago
      const conflictingData = {
        version: '2.0.0',
        items: [{
          id: 'ai-fundamentals',
          addedToPath: false,
          completed: true,
          timestamp: olderTime.toISOString()
        }],
        metadata: {
          timestamp: olderTime.toISOString(),
          source: 'conflicting-tab'
        }
      };

      // Trigger storage event with conflicting data
      const storageEvent = new StorageEvent('storage', {
        key: 'learning-paths-progress-v2',
        newValue: JSON.stringify(conflictingData),
        oldValue: null
      });

      globalThis.dispatchEvent(storageEvent);

      // Should keep current data (newer timestamp wins)
      const currentData = enhancedProgressSystem.getCurrentData();
      const item = currentData.items.find(i => i.id === 'ai-fundamentals');
      expect(item.addedToPath).toBe(true);
      expect(item.completed).toBe(false);

      // Should show conflict resolution notification
      const notification = document.querySelector('.notification.warning');
      expect(notification).toBeTruthy();
      expect(notification.textContent).toBe('Sync conflict resolved');
    });
  });
});
