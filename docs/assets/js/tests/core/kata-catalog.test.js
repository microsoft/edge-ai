import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import KataCatalog from '../../core/kata-catalog.js';

describe('KataCatalog', () => {
  let kataCatalog;
  let mockLocalStorage;
  let mockErrorHandler;
  let mockDebugHelper;
  let mockStorageManager;

  beforeEach(() => {
    // Mock localStorage
    mockLocalStorage = {
      getItem: vi.fn(),
      setItem: vi.fn(),
      removeItem: vi.fn()
    };

    // Store original localStorage if it exists
    const __originalLocalStorage = global.localStorage;

    // Set up localStorage for this test only
    global.localStorage = mockLocalStorage;

    // Mock error handler
    mockErrorHandler = {
      safeExecute: vi.fn().mockImplementation((fn, context, defaultValue) => {
        try {
          return fn();
        } catch {
          return defaultValue;
        }
      }),
      recordError: vi.fn(),
      log: vi.fn()
    };

    // Mock debug helper
    mockDebugHelper = {
      log: vi.fn(),
      warn: vi.fn(),
      error: vi.fn()
    };

    // Mock storage manager
    mockStorageManager = {
      safeGetLocalStorage: vi.fn().mockReturnValue({}),
      safeSetLocalStorage: vi.fn().mockReturnValue(true)
    };

    // Create KataCatalog instance
    kataCatalog = new KataCatalog({
      errorHandler: mockErrorHandler,
      debugHelper: mockDebugHelper,
      storageManager: mockStorageManager
    });
  });

  afterEach(() => {
    // Restore original localStorage
    if (global.localStorage === mockLocalStorage) {
      delete global.localStorage;
    }

    // Cleanup Vitest mocks
    vi.clearAllMocks();
  });

  describe('Constructor', () => {
    it('should initialize with default settings', async () => {
      expect(kataCatalog.isInitialized).toBe(false);
      expect(kataCatalog.config).toBeDefined();
    });

    it('should accept custom configuration', async () => {
      const customConfig = {
        cacheExpiry: 3600000,
        maxRetries: 5
      };

      const customCatalog = new KataCatalog({
        errorHandler: mockErrorHandler,
        debugHelper: mockDebugHelper,
        config: customConfig
      });

      expect(customCatalog.config.cacheExpiry).toBe(3600000);
      expect(customCatalog.config.maxRetries).toBe(5);
    });
  });

  describe('Kata Loading', () => {
    beforeEach(async () => {
      await kataCatalog.initialize();
    });

    it('should initialize kata catalog', async () => {
      expect(kataCatalog.isInitialized).toBe(true);
    });

    it('should load katas from local storage', async () => {
      const mockKatas = [
        {
          id: 'kata-1',
          title: 'Basic Algorithm',
          difficulty: 'beginner',
          tags: ['algorithm', 'basics']
        }
      ];

      mockLocalStorage.getItem.mockReturnValue(JSON.stringify(mockKatas));

      const katas = kataCatalog.loadKatas();

      expect(mockLocalStorage.getItem).toHaveBeenCalledWith('kata-catalog');
      expect(katas).toEqual(mockKatas);
    });

    it('should handle empty storage gracefully', async () => {
      mockLocalStorage.getItem.mockReturnValue(null);

      const katas = kataCatalog.loadKatas();

      expect(katas).toEqual([]);
    });

    it('should handle corrupted storage data', async () => {
      mockLocalStorage.getItem.mockReturnValue('invalid-json');

      const katas = kataCatalog.loadKatas();

      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
      expect(katas).toEqual([]);
    });
  });

  describe('Kata Management', () => {
    const sampleKata = {
      id: 'test-kata',
      title: 'Test Kata',
      difficulty: 'intermediate',
      description: 'A test kata for unit testing',
      tags: ['test', 'example'],
      estimatedTime: '30 minutes'
    };

    it('should add new katas to the catalog', async () => {
      await kataCatalog.initialize();

      kataCatalog.addKata(sampleKata);

      expect(mockLocalStorage.setItem).toHaveBeenCalled();
      expect(kataCatalog.getKataById('test-kata')).toEqual(sampleKata);
    });

    it('should update existing katas', async () => {
      await kataCatalog.initialize();
      kataCatalog.addKata(sampleKata);

      const updatedKata = { ...sampleKata, title: 'Updated Test Kata' };
      kataCatalog.updateKata('test-kata', updatedKata);

      expect(kataCatalog.getKataById('test-kata').title).toBe('Updated Test Kata');
    });

    it('should remove katas from the catalog', async () => {
      await kataCatalog.initialize();
      kataCatalog.addKata(sampleKata);

      kataCatalog.removeKata('test-kata');

      expect(kataCatalog.getKataById('test-kata')).toBeNull();
    });

    it('should validate kata structure before adding', async () => {
      const invalidKata = { title: 'Invalid Kata' }; // Missing required fields

      const result = kataCatalog.addKata(invalidKata);

      expect(result).toBe(false);
      expect(mockErrorHandler.recordError).toHaveBeenCalled();
    });
  });

  describe('Search and Filtering', () => {
    const testKatas = [
      {
        id: 'kata-1',
        title: 'Basic Sorting',
        difficulty: 'beginner',
        tags: ['sorting', 'algorithm']
      },
      {
        id: 'kata-2',
        title: 'Advanced Graph Theory',
        difficulty: 'advanced',
        tags: ['graph', 'algorithm']
      },
      {
        id: 'kata-3',
        title: 'String Manipulation',
        difficulty: 'intermediate',
        tags: ['string', 'manipulation']
      }
    ];

    beforeEach(async () => {
      await kataCatalog.initialize();
      kataCatalog.clearKatas(); // Clear built-in katas to start fresh
      testKatas.forEach(kata => kataCatalog.addKata(kata));
    });

    it('should search katas by title', async () => {
      const results = kataCatalog.searchKatas('sorting');

      expect(results).toHaveLength(1);
      expect(results[0].id).toBe('kata-1');
    });

    it('should filter katas by difficulty', async () => {
      const beginnerKatas = kataCatalog.filterByDifficulty('beginner');

      expect(beginnerKatas).toHaveLength(1);
      expect(beginnerKatas[0].difficulty).toBe('beginner');
    });

    it('should filter katas by tags', async () => {
      const algorithmKatas = kataCatalog.filterByTag('algorithm');

      expect(algorithmKatas).toHaveLength(2);
      expect(algorithmKatas.every(kata => kata.tags.includes('algorithm'))).toBe(true);
    });

    it('should perform complex searches with multiple criteria', async () => {
      const results = kataCatalog.searchKatas('algorithm', {
        difficulty: 'beginner',
        tags: ['sorting']
      });

      expect(results).toHaveLength(1);
      expect(results[0].id).toBe('kata-1');
    });

    it('should return empty array for no matches', async () => {
      const results = kataCatalog.searchKatas('nonexistent');

      expect(results).toEqual([]);
    });
  });

  describe('Kata Categories', () => {
    it('should get all available categories', async () => {
      await kataCatalog.initialize();

      const categories = kataCatalog.getCategories();

      expect(Array.isArray(categories)).toBe(true);
    });

    it('should get katas by category', async () => {
      await kataCatalog.initialize();

      const algorithmKatas = kataCatalog.getKatasByCategory('algorithm');

      expect(Array.isArray(algorithmKatas)).toBe(true);
    });
  });

  describe('Statistics', () => {
    it('should provide catalog statistics', async () => {
      await kataCatalog.initialize();

      const stats = kataCatalog.getStatistics();

      expect(stats).toHaveProperty('totalKatas');
      expect(stats).toHaveProperty('difficulties');
      expect(stats).toHaveProperty('categories');
    });

    it('should track most popular katas', async () => {
      await kataCatalog.initialize();

      const popular = kataCatalog.getMostPopular(5);

      expect(Array.isArray(popular)).toBe(true);
      expect(popular.length).toBeLessThanOrEqual(5);
    });
  });

  describe('Error Handling', () => {
    it('should handle initialization errors gracefully', async () => {
      mockLocalStorage.getItem.mockImplementation(() => {
        throw new Error('Storage access denied');
      });

      await expect(async () => {
        await kataCatalog.initialize();
      }).not.toThrow();

      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });

    it('should handle save errors gracefully', async () => {
      mockLocalStorage.setItem.mockImplementation(() => {
        throw new Error('Storage quota exceeded');
      });

      const kata = { id: 'test', title: 'Test' };

      expect(() => {
        kataCatalog.addKata(kata);
      }).not.toThrow();

      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });
  });

  describe('Configuration', () => {
    it('should allow runtime configuration updates', async () => {
      const newConfig = {
        cacheExpiry: 7200000,
        maxRetries: 10
      };

      kataCatalog.updateConfig(newConfig);

      expect(kataCatalog.config.cacheExpiry).toBe(7200000);
      expect(kataCatalog.config.maxRetries).toBe(10);
    });

    it('should merge configuration updates with existing config', async () => {
      const originalExpiry = kataCatalog.config.cacheExpiry;

      kataCatalog.updateConfig({
        maxRetries: 15
      });

      expect(kataCatalog.config.cacheExpiry).toBe(originalExpiry);
      expect(kataCatalog.config.maxRetries).toBe(15);
    });
  });

  describe('Cleanup', () => {
    it('should clean up resources on destroy', async () => {
      await kataCatalog.initialize();
      expect(kataCatalog.isInitialized).toBe(true);

      kataCatalog.destroy();

      expect(kataCatalog.isInitialized).toBe(false);
    });

    it('should handle cleanup errors gracefully', async () => {
      mockLocalStorage.removeItem.mockImplementation(() => {
        throw new Error('Cleanup error');
      });

      expect(() => {
        kataCatalog.destroy();
      }).not.toThrow();

      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });
  });
});
