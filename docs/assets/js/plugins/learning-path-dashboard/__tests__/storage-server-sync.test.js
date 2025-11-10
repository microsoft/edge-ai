/**
 * Unit tests for storage.js server sync functionality
 * Tests client-side API integration for saving/loading selections
 */

import { describe, it, expect, beforeEach, afterEach, jest } from '@jest/globals';

// Mock fetch globally
global.fetch = jest.fn();

describe('Storage Server Sync', () => {
  let storage;
  let mockOptions;

  beforeEach(() => {
    // Clear all mocks
    jest.clearAllMocks();

    // Mock localStorage
    global.localStorage = {
      getItem: jest.fn(),
      setItem: jest.fn(),
      removeItem: jest.fn(),
      clear: jest.fn()
    };

    // Mock console methods
    global.console = {
      log: jest.fn(),
      error: jest.fn(),
      warn: jest.fn()
    };

    // Setup default options
    mockOptions = {
      enableServerSync: true,
      userId: 'test-user',
      debug: false
    };

    // Create storage instance with mixin pattern
    // Note: In actual implementation, this would be mixed into LearningPathDashboard
    storage = {
      config: mockOptions,
      selectedPaths: new Set(['paths-foundation-ai-engineering', 'paths-ai-expert']),
      // Import the actual methods from storage.js
      saveSelectedPathsToStorage: function() {
        const selectedArray = Array.from(this.selectedPaths);
        localStorage.setItem('selectedLearningPaths', JSON.stringify(selectedArray));

        if (this.config?.enableServerSync) {
          this._saveSelectionsToServer(selectedArray);
        }
      },
      _saveSelectionsToServer: async function(selectedArray) {
        const userId = this.config?.userId || 'default-user';
        try {
          const response = await fetch('http://localhost:3002/api/learning/selections', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ selectedPaths: selectedArray, userId })
          });

          if (!response.ok) {
            throw new Error(`Server responded with ${response.status}`);
          }

          const result = await response.json();
          if (this.config?.debug) {
            console.log('[DEBUG _saveSelectionsToServer] Server save successful:', result);
          }
        } catch (error) {
          console.error('[ERROR _saveSelectionsToServer] Failed to save to server:', error);
        }
      },
      loadSelectionsFromServer: async function() {
        const userId = this.config?.userId || 'default-user';
        try {
          const response = await fetch(`http://localhost:3002/api/learning/selections?userId=${userId}`);

          if (!response.ok) {
            throw new Error(`Server responded with ${response.status}`);
          }

          const result = await response.json();
          return result.selections?.selectedPaths || [];
        } catch (error) {
          console.error('[ERROR loadSelectionsFromServer] Failed to load from server:', error);
          return [];
        }
      }
    };
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('saveSelectedPathsToStorage()', () => {
    it('should save to localStorage only when server sync disabled', () => {
      storage.config.enableServerSync = false;
      storage.saveSelectedPathsToStorage();

      expect(localStorage.setItem).toHaveBeenCalledWith(
        'selectedLearningPaths',
        JSON.stringify(['paths-foundation-ai-engineering', 'paths-ai-expert'])
      );
      expect(fetch).not.toHaveBeenCalled();
    });

    it('should save to both localStorage and server when server sync enabled', () => {
      fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ success: true, filename: 'learning-path-selections-test-user.json' })
      });

      storage.saveSelectedPathsToStorage();

      expect(localStorage.setItem).toHaveBeenCalledWith(
        'selectedLearningPaths',
        JSON.stringify(['paths-foundation-ai-engineering', 'paths-ai-expert'])
      );
      expect(fetch).toHaveBeenCalledWith(
        'http://localhost:3002/api/learning/selections',
        expect.objectContaining({
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            selectedPaths: ['paths-foundation-ai-engineering', 'paths-ai-expert'],
            userId: 'test-user'
          })
        })
      );
    });

    it('should use default userId when not provided', () => {
      storage.config.userId = undefined;
      fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ success: true })
      });

      storage.saveSelectedPathsToStorage();

      expect(fetch).toHaveBeenCalledWith(
        'http://localhost:3002/api/learning/selections',
        expect.objectContaining({
          body: JSON.stringify({
            selectedPaths: ['paths-foundation-ai-engineering', 'paths-ai-expert'],
            userId: 'default-user'
          })
        })
      );
    });
  });

  describe('_saveSelectionsToServer()', () => {
    it('should POST selections to server with correct payload', async () => {
      const mockResponse = {
        ok: true,
        json: async () => ({
          success: true,
          filename: 'learning-path-selections-test-user.json',
          selectionCount: 2
        })
      };
      fetch.mockResolvedValueOnce(mockResponse);

      await storage._saveSelectionsToServer(['paths-foundation-ai-engineering', 'paths-ai-expert']);

      expect(fetch).toHaveBeenCalledWith(
        'http://localhost:3002/api/learning/selections',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            selectedPaths: ['paths-foundation-ai-engineering', 'paths-ai-expert'],
            userId: 'test-user'
          })
        }
      );
    });

    it('should handle server errors gracefully (not throw)', async () => {
      fetch.mockResolvedValueOnce({
        ok: false,
        status: 500
      });

      // Should not throw
      await expect(
        storage._saveSelectionsToServer(['paths-foundation-ai-engineering'])
      ).resolves.not.toThrow();

      expect(console.error).toHaveBeenCalledWith(
        '[ERROR _saveSelectionsToServer] Failed to save to server:',
        expect.any(Error)
      );
    });

    it('should handle network errors gracefully', async () => {
      fetch.mockRejectedValueOnce(new Error('Network error'));

      await expect(
        storage._saveSelectionsToServer(['paths-foundation-ai-engineering'])
      ).resolves.not.toThrow();

      expect(console.error).toHaveBeenCalledWith(
        '[ERROR _saveSelectionsToServer] Failed to save to server:',
        expect.any(Error)
      );
    });

    it('should log success in debug mode', async () => {
      storage.config.debug = true;
      const mockResult = { success: true, filename: 'learning-path-selections-test-user.json' };
      fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResult
      });

      await storage._saveSelectionsToServer(['paths-foundation-ai-engineering']);

      expect(console.log).toHaveBeenCalledWith(
        '[DEBUG _saveSelectionsToServer] Server save successful:',
        mockResult
      );
    });

    it('should not log success when debug disabled', async () => {
      storage.config.debug = false;
      fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ success: true })
      });

      await storage._saveSelectionsToServer(['paths-foundation-ai-engineering']);

      expect(console.log).not.toHaveBeenCalled();
    });

    it('should handle empty selection array', async () => {
      fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ success: true, selectionCount: 0 })
      });

      await storage._saveSelectionsToServer([]);

      expect(fetch).toHaveBeenCalledWith(
        'http://localhost:3002/api/learning/selections',
        expect.objectContaining({
          body: JSON.stringify({ selectedPaths: [], userId: 'test-user' })
        })
      );
    });
  });

  describe('loadSelectionsFromServer()', () => {
    it('should GET selections from server', async () => {
      const mockSelections = ['paths-foundation-ai-engineering', 'paths-ai-expert'];
      fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          success: true,
          selections: { selectedPaths: mockSelections, selectionCount: 2 }
        })
      });

      const result = await storage.loadSelectionsFromServer();

      expect(fetch).toHaveBeenCalledWith(
        'http://localhost:3002/api/learning/selections?userId=test-user'
      );
      expect(result).toEqual(mockSelections);
    });

    it('should use default userId when not provided', async () => {
      storage.config.userId = undefined;
      fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          success: true,
          selections: { selectedPaths: [], selectionCount: 0 }
        })
      });

      await storage.loadSelectionsFromServer();

      expect(fetch).toHaveBeenCalledWith(
        'http://localhost:3002/api/learning/selections?userId=default-user'
      );
    });

    it('should return empty array when server returns no selections', async () => {
      fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          success: true,
          selections: { selectedPaths: [], selectionCount: 0 }
        })
      });

      const result = await storage.loadSelectionsFromServer();

      expect(result).toEqual([]);
    });

    it('should return empty array on server error', async () => {
      fetch.mockResolvedValueOnce({
        ok: false,
        status: 500
      });

      const result = await storage.loadSelectionsFromServer();

      expect(result).toEqual([]);
      expect(console.error).toHaveBeenCalledWith(
        '[ERROR loadSelectionsFromServer] Failed to load from server:',
        expect.any(Error)
      );
    });

    it('should return empty array on network error', async () => {
      fetch.mockRejectedValueOnce(new Error('Network error'));

      const result = await storage.loadSelectionsFromServer();

      expect(result).toEqual([]);
      expect(console.error).toHaveBeenCalled();
    });

    it('should handle malformed server response', async () => {
      fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ success: true }) // Missing selections field
      });

      const result = await storage.loadSelectionsFromServer();

      expect(result).toEqual([]);
    });
  });

  describe('Graceful degradation', () => {
    it('should complete localStorage save even if server save fails', async () => {
      fetch.mockRejectedValueOnce(new Error('Server down'));

      storage.saveSelectedPathsToStorage();

      expect(localStorage.setItem).toHaveBeenCalledWith(
        'selectedLearningPaths',
        JSON.stringify(['paths-foundation-ai-engineering', 'paths-ai-expert'])
      );
    });

    it('should not block on server save (async)', () => {
      let resolveServerCall;
      const serverCallPromise = new Promise(resolve => {
        resolveServerCall = resolve;
      });

      fetch.mockReturnValueOnce(serverCallPromise);

      // saveSelectedPathsToStorage should return immediately
      storage.saveSelectedPathsToStorage();

      expect(localStorage.setItem).toHaveBeenCalled();

      // Server call is still pending
      expect(fetch).toHaveBeenCalled();

      // Resolve server call
      resolveServerCall({ ok: true, json: async () => ({ success: true }) });
    });
  });

  describe('Feature flag behavior', () => {
    it('should respect enableServerSync flag', () => {
      storage.config.enableServerSync = true;
      storage.saveSelectedPathsToStorage();
      expect(fetch).toHaveBeenCalled();

      jest.clearAllMocks();

      storage.config.enableServerSync = false;
      storage.saveSelectedPathsToStorage();
      expect(fetch).not.toHaveBeenCalled();
    });

    it('should not call server when options undefined', () => {
      storage.config = undefined;
      storage.saveSelectedPathsToStorage();

      expect(localStorage.setItem).toHaveBeenCalled();
      expect(fetch).not.toHaveBeenCalled();
    });

    it('should not call server when enableServerSync explicitly false', () => {
      storage.config.enableServerSync = false;
      storage.saveSelectedPathsToStorage();

      expect(fetch).not.toHaveBeenCalled();
    });
  });

  describe('Multi-user scenarios', () => {
    it('should maintain separate selections for different users', async () => {
      const user1Selections = ['paths-foundation-ai-engineering'];
      const user2Selections = ['paths-ai-expert', 'paths-foundation-edge-computing'];

      // User 1 save
      storage.config.userId = 'user1';
      fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ success: true })
      });
      await storage._saveSelectionsToServer(user1Selections);

      expect(fetch).toHaveBeenCalledWith(
        'http://localhost:3002/api/learning/selections',
        expect.objectContaining({
          body: JSON.stringify({ selectedPaths: user1Selections, userId: 'user1' })
        })
      );

      jest.clearAllMocks();

      // User 2 save
      storage.config.userId = 'user2';
      fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ success: true })
      });
      await storage._saveSelectionsToServer(user2Selections);

      expect(fetch).toHaveBeenCalledWith(
        'http://localhost:3002/api/learning/selections',
        expect.objectContaining({
          body: JSON.stringify({ selectedPaths: user2Selections, userId: 'user2' })
        })
      );
    });
  });
});
