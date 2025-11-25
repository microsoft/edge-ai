/**
 * @file progress-ui.test.js
 * @description Comprehensive test suite for ProgressUI class
 * @version 1.0.0
 * @author Test Suite Generator
 * @created 2025-01-08
 */

import { beforeEach, afterEach, describe, it, expect, vi } from 'vitest';
import { ProgressUI } from '../../ui/progress-ui.js';
import { logger } from '../../utils/index.js';

// Mock the logger module
vi.mock('../../utils/index.js', () => ({
  logger: {
    log: vi.fn(),
    debug: vi.fn(),
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn()
  }
}));

describe('ProgressUI', () => {
  let progressUI;
  let mockProgressCore;
  let mockErrorHandler;
  let mockDomUtils;
  let mockKataCatalog;
  let mockLearningPathManager;
  let mockDocument;
  let mockWindow;

  beforeEach(() => {
    // Create comprehensive mocks
    mockProgressCore = {
      getAllProgress: vi.fn(() => new Map()),
      getProgress: vi.fn(() => ({})),
      setProgress: vi.fn(),
      updateProgress: vi.fn()
    };

    mockErrorHandler = {
      handleError: vi.fn(),
      safeExecute: vi.fn((fn) => {
        try {
          return fn();
        } catch (error) {
          mockErrorHandler.handleError(error);
          return null;
        }
      })
    };

    const mockElement = {
      style: {},
      classList: {
        add: vi.fn(),
        remove: vi.fn(),
        contains: vi.fn(() => false)
      },
      appendChild: vi.fn(),
      querySelector: vi.fn(() => null),
      querySelectorAll: vi.fn(() => []),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      setAttribute: vi.fn(),
      getAttribute: vi.fn(() => 'test-id'),
      textContent: '',
      innerHTML: '',
      id: '',
      className: ''
    };

    const mockBody = {
      ...mockElement,
      appendChild: vi.fn()
    };

    mockDocument = {
      createElement: vi.fn(() => ({ ...mockElement })),
      querySelector: vi.fn(() => null),
      querySelectorAll: vi.fn(() => []),
      getElementById: vi.fn(() => null),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      body: mockBody
    };

    mockDomUtils = {
      createElement: vi.fn((tag) => mockDocument.createElement(tag)),
      querySelector: vi.fn((selector) => mockDocument.querySelector(selector)),
      querySelectorAll: vi.fn((selector) => mockDocument.querySelectorAll(selector))
    };

    mockKataCatalog = {
      getKata: vi.fn(),
      getAllKatas: vi.fn(() => [])
    };

    mockLearningPathManager = {
      getActivePaths: vi.fn(() => []),
      getPath: vi.fn()
    };

    mockWindow = {
      progressUI: null
    };

    // Stub global objects
    vi.stubGlobal('document', mockDocument);
    vi.stubGlobal('window', mockWindow);

    // Mock logger instead of console
    vi.mocked(logger.warn);
    vi.mocked(logger.error);
    vi.mocked(logger.debug);

    // Mock logger methods for testing
    vi.mocked(logger.warn).mockClear();
    vi.mocked(logger.error).mockClear();
    vi.mocked(logger.debug).mockClear();

    // Create ProgressUI instance with all dependencies
    progressUI = new ProgressUI({
      progressCore: mockProgressCore,
      errorHandler: mockErrorHandler,
      domUtils: mockDomUtils,
      kataCatalog: mockKataCatalog,
      learningPathManager: mockLearningPathManager
    });
  });

  afterEach(() => {
    if (progressUI) {
      progressUI.destroy();
    }
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  describe('Constructor and Initialization', () => {
    it('should initialize with required dependencies', () => {
      expect(progressUI.progressCore).toBe(mockProgressCore);
      expect(progressUI.errorHandler).toBe(mockErrorHandler);
      expect(progressUI.domUtils).toBe(mockDomUtils);
      expect(progressUI.kataCatalog).toBe(mockKataCatalog);
      expect(progressUI.learningPathManager).toBe(mockLearningPathManager);
    });

    it('should throw error when required dependencies are missing', () => {
      expect(() => {
        new ProgressUI({});
      }).toThrow('ProgressUI requires progressCore dependency');

      expect(() => {
        new ProgressUI({ progressCore: mockProgressCore });
      }).toThrow('ProgressUI requires errorHandler dependency');

      expect(() => {
        new ProgressUI({
          progressCore: mockProgressCore,
          errorHandler: mockErrorHandler
        });
      }).toThrow('ProgressUI requires domUtils dependency');
    });

    it('should initialize with default configuration', () => {
      expect(progressUI.config.animationDuration).toBe(300);
      expect(progressUI.config.updateInterval).toBe(1000);
      expect(progressUI.config.progressBarHeight).toBe(6);
      expect(progressUI.config.showAnimations).toBe(true);
      expect(progressUI.config.enableTooltips).toBe(true);
      expect(progressUI.config.chartColors).toEqual({
        primary: '#007acc',
        secondary: '#28a745',
        warning: '#ffc107',
        danger: '#dc3545',
        info: '#17a2b8'
      });
    });

    it('should override default configuration with provided config', () => {
      const customConfig = {
        animationDuration: 500,
        updateInterval: 2000,
        showAnimations: false,
        chartColors: { primary: '#ff0000' }
      };

      const customProgressUI = new ProgressUI({
        progressCore: mockProgressCore,
        errorHandler: mockErrorHandler,
        domUtils: mockDomUtils
      }, customConfig);

      expect(customProgressUI.config.animationDuration).toBe(500);
      expect(customProgressUI.config.updateInterval).toBe(2000);
      expect(customProgressUI.config.showAnimations).toBe(false);
      expect(customProgressUI.config.chartColors.primary).toBe('#ff0000');
    });

    it('should initialize state management properties', () => {
      expect(progressUI.activeComponents).toBeInstanceOf(Map);
      expect(progressUI.eventListeners).toBeInstanceOf(Map);
      expect(progressUI.updateIntervals).toBeInstanceOf(Map);
      expect(progressUI.progressBars).toBeInstanceOf(Map);
      expect(progressUI.progressContainers).toBeInstanceOf(Map);
      expect(progressUI.charts).toBeInstanceOf(Map);
      expect(progressUI.visualizers).toBeInstanceOf(Map);
      expect(progressUI.isInitialized).toBe(false);
      expect(progressUI.dashboardVisible).toBe(false);
    });

    it('should set global window reference', () => {
      expect(mockWindow.progressUI).toBe(progressUI);
    });
  });

  describe('Initialization System', () => {
    it('should initialize successfully when all systems work', async () => {
      // Mock successful setup methods
      vi.spyOn(progressUI, 'setupProgressBars').mockResolvedValue();
      vi.spyOn(progressUI, 'setupDashboard').mockResolvedValue();
      vi.spyOn(progressUI, 'setupVisualizers').mockResolvedValue();
      vi.spyOn(progressUI, 'setupEventListeners').mockImplementation(() => {});

      const result = await progressUI.init();

      expect(result).toBe(true);
      expect(progressUI.isInitialized).toBe(true);
      expect(progressUI.setupProgressBars).toHaveBeenCalled();
      expect(progressUI.setupDashboard).toHaveBeenCalled();
      expect(progressUI.setupVisualizers).toHaveBeenCalled();
      expect(progressUI.setupEventListeners).toHaveBeenCalled();
    });

    it('should return true if already initialized', async () => {
      progressUI.isInitialized = true;
      vi.spyOn(progressUI, 'setupProgressBars');

      const result = await progressUI.init();

      expect(result).toBe(true);
      expect(progressUI.setupProgressBars).not.toHaveBeenCalled();
    });

    it('should handle initialization failure gracefully', async () => {
      vi.spyOn(progressUI, 'setupProgressBars').mockRejectedValue(new Error('Setup failed'));
      vi.spyOn(progressUI, 'handleError').mockImplementation(() => {});

      const result = await progressUI.init();

      expect(result).toBe(false);
      expect(progressUI.isInitialized).toBe(false);
      expect(progressUI.handleError).toHaveBeenCalledWith(
        'Initialization failed',
        expect.any(Error)
      );
    });
  });

  describe('Progress Bar Management', () => {
    beforeEach(() => {
      // Mock container with progress bar attribute
      const mockContainer = {
        ...mockDocument.createElement(),
        getAttribute: vi.fn(() => 'test-progress')
      };
      mockDomUtils.querySelectorAll.mockReturnValue([mockContainer]);
    });

    it('should setup progress bars from existing containers', async () => {
      vi.spyOn(progressUI, 'createProgressBar').mockImplementation(() => {});

      await progressUI.setupProgressBars();

      expect(mockDomUtils.querySelectorAll).toHaveBeenCalledWith('[data-progress-container]');
      expect(progressUI.createProgressBar).toHaveBeenCalledWith('test-progress', expect.any(Object));
    });

    it('should create progress bar structure correctly', () => {
      const mockContainer = mockDocument.createElement();

      progressUI.createProgressBar('test-bar', mockContainer);

      expect(mockDomUtils.createElement).toHaveBeenCalledWith('div');
      expect(mockContainer.appendChild).toHaveBeenCalled();
      expect(progressUI.progressBars.has('test-bar')).toBe(true);

      const progressBar = progressUI.progressBars.get('test-bar');
      expect(progressBar.container).toBe(mockContainer);
      expect(progressBar.value).toBe(0);
      expect(progressBar.max).toBe(100);
      expect(progressBar.visible).toBe(true);
    });

    it('should handle progress bar creation error gracefully', () => {
      vi.spyOn(progressUI, 'handleError').mockImplementation(() => {});
      mockDomUtils.createElement.mockImplementation(() => {
        throw new Error('Creation failed');
      });

      progressUI.createProgressBar('error-bar', mockDocument.createElement());

      expect(progressUI.handleError).toHaveBeenCalledWith(
        'Failed to create progress bar error-bar',
        expect.any(Error)
      );
    });

    it('should update progress bar value correctly', () => {
      const mockProgressBar = {
        container: mockDocument.createElement(),
        wrapper: mockDocument.createElement(),
        bar: mockDocument.createElement(),
        fill: { style: {} },
        text: { style: {}, textContent: '' },
        value: 0,
        max: 100,
        visible: true
      };

      progressUI.progressBars.set('test-bar', mockProgressBar);

      const result = progressUI.updateProgressBar('test-bar', 75);

      expect(result).toBe(true);
      expect(mockProgressBar.fill.style.width).toBe('75%');
      expect(mockProgressBar.value).toBe(75);
    });

    it('should clamp progress bar values to valid range', () => {
      const mockProgressBar = {
        fill: { style: {} },
        text: { style: {}, textContent: '' },
        value: 0,
        max: 100,
        visible: true
      };

      progressUI.progressBars.set('test-bar', mockProgressBar);

      // Test over max
      progressUI.updateProgressBar('test-bar', 150);
      expect(mockProgressBar.fill.style.width).toBe('100%');
      expect(mockProgressBar.value).toBe(100);

      // Test under min
      progressUI.updateProgressBar('test-bar', -50);
      expect(mockProgressBar.fill.style.width).toBe('0%');
      expect(mockProgressBar.value).toBe(0);
    });

    it('should handle progress bar update options', () => {
      const mockProgressBar = {
        fill: { style: {} },
        text: { style: {}, textContent: '' },
        value: 0,
        max: 100,
        visible: true
      };

      progressUI.progressBars.set('test-bar', mockProgressBar);

      progressUI.updateProgressBar('test-bar', 50, {
        text: 'Custom text',
        color: '#ff0000',
        autoColor: false
      });

      expect(mockProgressBar.text.textContent).toBe('Custom text');
      expect(mockProgressBar.text.style.display).toBe('block');
      expect(mockProgressBar.fill.style.backgroundColor).toBe('#ff0000');
    });

    it('should show percentage when showPercentage option is true', () => {
      const mockProgressBar = {
        fill: { style: {} },
        text: { style: {}, textContent: '' },
        value: 0,
        max: 100,
        visible: true
      };

      progressUI.progressBars.set('test-bar', mockProgressBar);

      progressUI.updateProgressBar('test-bar', 75, { showPercentage: true });

      expect(mockProgressBar.text.textContent).toBe('75%');
      expect(mockProgressBar.text.style.display).toBe('block');
    });

    it('should return false for non-existent progress bar', () => {
      const result = progressUI.updateProgressBar('non-existent', 50);

      expect(result).toBe(false);
      expect(logger.warn).toHaveBeenCalledWith('[ProgressUI] Progress bar not found: non-existent');
    });

    it('should handle progress bar update error gracefully', () => {
      const mockProgressBar = {
        fill: {
          style: {
            set width(value) { throw new Error('Update failed'); }
          }
        },
        text: { style: {}, textContent: '' },
        value: 0,
        max: 100,
        visible: true
      };

      progressUI.progressBars.set('error-bar', mockProgressBar);
      vi.spyOn(progressUI, 'handleError').mockImplementation(() => {});

      const result = progressUI.updateProgressBar('error-bar', 50);

      expect(result).toBe(false);
      expect(progressUI.handleError).toHaveBeenCalledWith(
        'Failed to update progress bar error-bar',
        expect.any(Error)
      );
    });
  });

  describe('Progress Color System', () => {
    it('should return danger color for low progress', () => {
      const color = progressUI.getProgressColor(20);
      expect(color).toBe(progressUI.config.chartColors.danger);
    });

    it('should return warning color for medium-low progress', () => {
      const color = progressUI.getProgressColor(40);
      expect(color).toBe(progressUI.config.chartColors.warning);
    });

    it('should return info color for medium-high progress', () => {
      const color = progressUI.getProgressColor(60);
      expect(color).toBe(progressUI.config.chartColors.info);
    });

    it('should return secondary color for high progress', () => {
      const color = progressUI.getProgressColor(90);
      expect(color).toBe(progressUI.config.chartColors.secondary);
    });

    it('should handle edge cases correctly', () => {
      expect(progressUI.getProgressColor(0)).toBe(progressUI.config.chartColors.danger);
      expect(progressUI.getProgressColor(25)).toBe(progressUI.config.chartColors.warning);
      expect(progressUI.getProgressColor(50)).toBe(progressUI.config.chartColors.info);
      expect(progressUI.getProgressColor(75)).toBe(progressUI.config.chartColors.secondary);
      expect(progressUI.getProgressColor(100)).toBe(progressUI.config.chartColors.secondary);
    });
  });

  describe('Dashboard System', () => {
    it('should setup dashboard with correct HTML structure', async () => {
      await progressUI.setupDashboard();

      expect(mockDomUtils.createElement).toHaveBeenCalledWith('div');
      expect(mockDocument.body.appendChild).toHaveBeenCalled();
      expect(progressUI.activeComponents.has('dashboard')).toBe(true);
    });

    it('should use existing dashboard container if found', async () => {
      const existingDashboard = mockDocument.createElement();
      mockDomUtils.querySelector.mockReturnValue(existingDashboard);

      await progressUI.setupDashboard();

      expect(progressUI.activeComponents.get('dashboard')).toBe(existingDashboard);
      expect(mockDocument.body.appendChild).not.toHaveBeenCalled();
    });

    it('should show dashboard successfully', async () => {
      const mockDashboard = mockDocument.createElement();
      progressUI.activeComponents.set('dashboard', mockDashboard);
      vi.spyOn(progressUI, 'updateDashboardData').mockResolvedValue();
      vi.spyOn(progressUI, 'setupDashboardEvents').mockImplementation(() => {});

      const result = await progressUI.showDashboard();

      expect(result).toBe(true);
      expect(progressUI.dashboardVisible).toBe(true);
      expect(mockDashboard.classList.remove).toHaveBeenCalledWith('hidden');
      expect(progressUI.updateDashboardData).toHaveBeenCalled();
    });

    it('should return false when dashboard not initialized', async () => {
      const result = await progressUI.showDashboard();

      expect(result).toBe(false);
      expect(logger.warn).toHaveBeenCalledWith('[ProgressUI] Dashboard not initialized');
    });

    it('should hide dashboard successfully', () => {
      const mockDashboard = mockDocument.createElement();
      progressUI.activeComponents.set('dashboard', mockDashboard);
      progressUI.dashboardVisible = true;

      const result = progressUI.hideDashboard();

      expect(result).toBe(true);
      expect(progressUI.dashboardVisible).toBe(false);
      expect(mockDashboard.classList.add).toHaveBeenCalledWith('hidden');
    });

    it('should return false when hiding non-existent dashboard', () => {
      const result = progressUI.hideDashboard();

      expect(result).toBe(false);
    });

    it('should handle dashboard show error gracefully', async () => {
      const mockDashboard = mockDocument.createElement();
      progressUI.activeComponents.set('dashboard', mockDashboard);
      vi.spyOn(progressUI, 'updateDashboardData').mockRejectedValue(new Error('Update failed'));
      vi.spyOn(progressUI, 'handleError').mockImplementation(() => {});

      const result = await progressUI.showDashboard();

      expect(result).toBe(false);
      expect(progressUI.handleError).toHaveBeenCalledWith(
        'Failed to show dashboard',
        expect.any(Error)
      );
    });

    it('should handle dashboard hide error gracefully', () => {
      const mockDashboard = {
        classList: {
          add: vi.fn(() => { throw new Error('Hide failed'); })
        }
      };
      progressUI.activeComponents.set('dashboard', mockDashboard);
      vi.spyOn(progressUI, 'handleError').mockImplementation(() => {});

      const result = progressUI.hideDashboard();

      expect(result).toBe(false);
      expect(progressUI.handleError).toHaveBeenCalledWith(
        'Failed to hide dashboard',
        expect.any(Error)
      );
    });
  });

  describe('Dashboard Data Management', () => {
    beforeEach(() => {
      // Mock progress data
      const mockProgressData = new Map([
        ['module1', {
          data: {
            checkboxes: { kata1: true, kata2: false, kata3: true },
            activePaths: { path1: {}, path2: {} },
            timeSpent: 7200 // 2 hours in seconds
          },
          timestamp: '2025-01-08T10:00:00.000Z'
        }],
        ['module2', {
          data: {
            checkboxes: { kata4: true, kata5: true },
            activePaths: { path3: {} },
            timeSpent: 3600 // 1 hour in seconds
          },
          timestamp: '2025-01-08T11:00:00.000Z'
        }]
      ]);

      mockProgressCore.getAllProgress.mockReturnValue(mockProgressData);
    });

    it('should update dashboard data successfully', async () => {
      vi.spyOn(progressUI, 'calculateProgressStats').mockReturnValue({
        overallProgress: 60,
        totalKatas: 5,
        completedKatas: 3,
        activePaths: 3,
        timeSpent: 3
      });
      vi.spyOn(progressUI, 'updateStatCards').mockImplementation(() => {});
      vi.spyOn(progressUI, 'updateActivityFeed').mockImplementation(() => {});
      vi.spyOn(progressUI, 'updateRecommendations').mockImplementation(() => {});

      await progressUI.updateDashboardData();

      expect(progressUI.currentDashboardData).toBeDefined();
      expect(progressUI.currentDashboardData.stats.overallProgress).toBe(60);
      expect(progressUI.updateStatCards).toHaveBeenCalled();
      expect(progressUI.updateActivityFeed).toHaveBeenCalled();
      expect(progressUI.updateRecommendations).toHaveBeenCalled();
    });

    it('should calculate progress statistics correctly', () => {
      const stats = progressUI.calculateProgressStats(mockProgressCore.getAllProgress());

      expect(stats.totalKatas).toBe(5);
      expect(stats.completedKatas).toBe(4); // kata1, kata3, kata4, kata5 are true
      expect(stats.activePaths).toBe(3);
      expect(stats.timeSpent).toBe(3); // 3 hours total
      expect(stats.overallProgress).toBe(80); // 4/5 * 100
    });

    it('should handle empty progress data', () => {
      mockProgressCore.getAllProgress.mockReturnValue(new Map());

      const stats = progressUI.calculateProgressStats(new Map());

      expect(stats.totalKatas).toBe(0);
      expect(stats.completedKatas).toBe(0);
      expect(stats.activePaths).toBe(0);
      expect(stats.timeSpent).toBe(0);
      expect(stats.overallProgress).toBe(0);
    });

    it('should update stat cards with calculated statistics', () => {
      const mockStatCards = {
        'total-progress': {
          querySelector: vi.fn((selector) => {
            if (selector === '.stat-value') {return { textContent: '' };}
            if (selector === '.stat-bar') {return { style: {} };}
            return null;
          })
        },
        'completed-katas': {
          querySelector: vi.fn((selector) => {
            if (selector === '.stat-value') {return { textContent: '' };}
            return null;
          })
        },
        'active-paths': {
          querySelector: vi.fn((selector) => {
            if (selector === '.stat-value') {return { textContent: '' };}
            return null;
          })
        },
        'time-spent': {
          querySelector: vi.fn((selector) => {
            if (selector === '.stat-value') {return { textContent: '' };}
            return null;
          })
        }
      };

      mockDomUtils.querySelector.mockImplementation((selector) => {
        const statKey = selector.match(/data-stat="([^"]+)"/)?.[1];
        return mockStatCards[statKey] || null;
      });

      const stats = {
        overallProgress: 75,
        totalKatas: 10,
        completedKatas: 7,
        activePaths: 2,
        timeSpent: 5
      };

      progressUI.updateStatCards(stats);

      expect(mockDomUtils.querySelector).toHaveBeenCalledWith('[data-stat="total-progress"]');
      expect(mockDomUtils.querySelector).toHaveBeenCalledWith('[data-stat="completed-katas"]');
      expect(mockDomUtils.querySelector).toHaveBeenCalledWith('[data-stat="active-paths"]');
      expect(mockDomUtils.querySelector).toHaveBeenCalledWith('[data-stat="time-spent"]');
    });

    it('should handle dashboard data update error gracefully', async () => {
      mockProgressCore.getAllProgress.mockImplementation(() => {
        throw new Error('Data fetch failed');
      });
      vi.spyOn(progressUI, 'handleError').mockImplementation(() => {});

      await progressUI.updateDashboardData();

      expect(progressUI.handleError).toHaveBeenCalledWith(
        'Failed to update dashboard data',
        expect.any(Error)
      );
    });
  });

  describe('Activity Feed and Recommendations', () => {
    it('should update activity feed with recent activities', () => {
      const mockActivityList = mockDocument.createElement();
      mockDomUtils.querySelector.mockReturnValue(mockActivityList);

      const mockProgressData = new Map([
        ['module1', { timestamp: '2025-01-08T10:00:00.000Z' }],
        ['module2', { timestamp: '2025-01-08T09:00:00.000Z' }]
      ]);

      progressUI.updateActivityFeed(mockProgressData);

      expect(mockDomUtils.querySelector).toHaveBeenCalledWith('.activity-list');
      expect(mockActivityList.innerHTML).toContain('Updated progress in module1');
      expect(mockActivityList.innerHTML).toContain('Updated progress in module2');
    });

    it('should handle missing activity list gracefully', () => {
      mockDomUtils.querySelector.mockReturnValue(null);

      expect(() => {
        progressUI.updateActivityFeed(new Map());
      }).not.toThrow();
    });

    it('should generate appropriate recommendations based on progress', () => {
      const mockRecommendationsList = mockDocument.createElement();
      mockDomUtils.querySelector.mockReturnValue(mockRecommendationsList);

      // Test low progress recommendations
      progressUI.updateRecommendations({ overallProgress: 20, activePaths: 0, timeSpent: 5 });
      expect(mockRecommendationsList.innerHTML).toContain('Start with foundational katas');
      expect(mockRecommendationsList.innerHTML).toContain('Choose a learning path');

      // Test medium progress recommendations
      progressUI.updateRecommendations({ overallProgress: 40, activePaths: 2, timeSpent: 5 });
      expect(mockRecommendationsList.innerHTML).toContain('Focus on completing current learning paths');

      // Test high progress recommendations
      progressUI.updateRecommendations({ overallProgress: 80, activePaths: 1, timeSpent: 15 });
      expect(mockRecommendationsList.innerHTML).toContain('Consider mentoring others');
    });

    it('should recommend study time for low time investment', () => {
      const mockRecommendationsList = mockDocument.createElement();
      mockDomUtils.querySelector.mockReturnValue(mockRecommendationsList);

      progressUI.updateRecommendations({ overallProgress: 50, activePaths: 1, timeSpent: 5 });
      expect(mockRecommendationsList.innerHTML).toContain('Set aside regular study time');
    });
  });

  describe('Timestamp Formatting', () => {
    beforeEach(() => {
      // Mock current time for consistent testing
      vi.spyOn(Date, 'now').mockReturnValue(new Date('2025-08-07T12:00:00.000Z').getTime());
    });

    it('should format recent timestamps correctly', () => {
      expect(progressUI.formatTimestamp('2025-08-07T11:59:30.000Z')).toBe('Just now');
      expect(progressUI.formatTimestamp('2025-08-07T11:55:00.000Z')).toBe('5m ago');
      expect(progressUI.formatTimestamp('2025-08-07T10:00:00.000Z')).toBe('2h ago');
      expect(progressUI.formatTimestamp('2025-08-06T12:00:00.000Z')).toBe('1d ago');
    });

    it('should handle invalid timestamps gracefully', () => {
      expect(progressUI.formatTimestamp('invalid-date')).toBe('Unknown');
      expect(progressUI.formatTimestamp(null)).toBe('Unknown');
      expect(progressUI.formatTimestamp(undefined)).toBe('Unknown');
    });
  });

  describe('Event Handling', () => {
    it('should setup dashboard event listeners correctly', () => {
      const mockDashboard = mockDocument.createElement();
      const mockCloseButton = mockDocument.createElement();
      mockDashboard.querySelector.mockReturnValue(mockCloseButton);

      progressUI.setupDashboardEvents(mockDashboard);

      expect(mockCloseButton.addEventListener).toHaveBeenCalledWith('click', expect.any(Function));
      expect(mockDocument.addEventListener).toHaveBeenCalledWith('keydown', expect.any(Function));
      expect(progressUI.eventListeners.has('dashboard')).toBe(true);
    });

    it('should handle close button click', () => {
      const mockDashboard = mockDocument.createElement();
      const mockCloseButton = mockDocument.createElement();
      mockDashboard.querySelector.mockReturnValue(mockCloseButton);
      vi.spyOn(progressUI, 'hideDashboard').mockImplementation(() => {});

      progressUI.setupDashboardEvents(mockDashboard);

      // Get the click handler and call it
      const clickHandler = mockCloseButton.addEventListener.mock.calls[0][1];
      clickHandler();

      expect(progressUI.hideDashboard).toHaveBeenCalled();
    });

    it('should handle escape key press', () => {
      const mockDashboard = mockDocument.createElement();
      const mockCloseButton = mockDocument.createElement();
      mockDashboard.querySelector.mockReturnValue(mockCloseButton);
      progressUI.dashboardVisible = true;
      vi.spyOn(progressUI, 'hideDashboard').mockImplementation(() => {});

      progressUI.setupDashboardEvents(mockDashboard);

      // Get the keydown handler and call it with escape key
      const keydownHandler = mockDocument.addEventListener.mock.calls[0][1];
      keydownHandler({ key: 'Escape' });

      expect(progressUI.hideDashboard).toHaveBeenCalled();
    });

    it('should not hide dashboard on escape when not visible', () => {
      const mockDashboard = mockDocument.createElement();
      const mockCloseButton = mockDocument.createElement();
      mockDashboard.querySelector.mockReturnValue(mockCloseButton);
      progressUI.dashboardVisible = false;
      vi.spyOn(progressUI, 'hideDashboard').mockImplementation(() => {});

      progressUI.setupDashboardEvents(mockDashboard);

      const keydownHandler = mockDocument.addEventListener.mock.calls[0][1];
      keydownHandler({ key: 'Escape' });

      expect(progressUI.hideDashboard).not.toHaveBeenCalled();
    });

    it('should setup global event listeners with update intervals', () => {
      vi.spyOn(global, 'setInterval').mockReturnValue('interval-id');
      progressUI.dashboardVisible = true;
      vi.spyOn(progressUI, 'updateDashboardData').mockImplementation(() => {});

      progressUI.setupEventListeners();

      expect(setInterval).toHaveBeenCalledWith(expect.any(Function), 1000);
      expect(progressUI.updateIntervals.has('dashboard')).toBe(true);

      // Test the interval callback
      const intervalCallback = setInterval.mock.calls[0][0];
      intervalCallback();

      expect(progressUI.updateDashboardData).toHaveBeenCalled();
    });

    it('should not setup intervals when updateInterval is 0', () => {
      progressUI.config.updateInterval = 0;
      vi.spyOn(global, 'setInterval');

      progressUI.setupEventListeners();

      expect(setInterval).not.toHaveBeenCalled();
    });
  });

  describe('Error Handling', () => {
    it('should use errorHandler when available', () => {
      const error = new Error('Test error');
      const message = 'Test message';

      progressUI.handleError(message, error);

      expect(mockErrorHandler.handleError).toHaveBeenCalledWith(error, message);
    });

    it('should fallback to logger.error when errorHandler unavailable', () => {
      progressUI.errorHandler = null;
      const error = new Error('Test error');
      const message = 'Test message';

      progressUI.handleError(message, error);

      expect(logger.error).toHaveBeenCalledWith('[ProgressUI] Test message:', error);
    });

    it('should handle invalid errorHandler gracefully', () => {
      progressUI.errorHandler = { invalidMethod: vi.fn() };
      const error = new Error('Test error');
      const message = 'Test message';

      progressUI.handleError(message, error);

      expect(logger.error).toHaveBeenCalledWith('[ProgressUI] Test message:', error);
    });
  });

  describe('Cleanup and Destruction', () => {
    it('should clear all intervals on destroy', () => {
      const mockInterval1 = 'interval-1';
      const mockInterval2 = 'interval-2';
      progressUI.updateIntervals.set('test1', mockInterval1);
      progressUI.updateIntervals.set('test2', mockInterval2);
      vi.spyOn(global, 'clearInterval');

      progressUI.destroy();

      expect(clearInterval).toHaveBeenCalledWith(mockInterval1);
      expect(clearInterval).toHaveBeenCalledWith(mockInterval2);
      expect(progressUI.updateIntervals.size).toBe(0);
    });

    it('should remove all event listeners on destroy', () => {
      const mockEscapeHandler = vi.fn();
      progressUI.eventListeners.set('dashboard', {
        escapeHandler: mockEscapeHandler
      });

      progressUI.destroy();

      expect(mockDocument.removeEventListener).toHaveBeenCalledWith('keydown', mockEscapeHandler);
      expect(progressUI.eventListeners.size).toBe(0);
    });

    it('should clear global window reference on destroy', () => {
      mockWindow.progressUI = progressUI;

      progressUI.destroy();

      expect(mockWindow.progressUI).toBeNull();
    });

    it('should not clear global reference if it is not this instance', () => {
      const otherInstance = {};
      mockWindow.progressUI = otherInstance;

      progressUI.destroy();

      expect(mockWindow.progressUI).toBe(otherInstance);
    });

    it('should handle destroy when window is undefined', () => {
      vi.stubGlobal('window', undefined);

      expect(() => {
        progressUI.destroy();
      }).not.toThrow();
    });
  });

  describe('Integration Scenarios', () => {
    it('should handle complete workflow: init -> show dashboard -> update -> hide -> destroy', async () => {
      // Setup spies
      vi.spyOn(progressUI, 'setupProgressBars').mockResolvedValue();
      vi.spyOn(progressUI, 'setupDashboard').mockResolvedValue();
      vi.spyOn(progressUI, 'setupVisualizers').mockResolvedValue();
      vi.spyOn(progressUI, 'setupEventListeners').mockImplementation(() => {});
      vi.spyOn(progressUI, 'updateDashboardData').mockResolvedValue();

      const mockDashboard = mockDocument.createElement();
      progressUI.activeComponents.set('dashboard', mockDashboard);

      // Execute workflow
      const initResult = await progressUI.init();
      expect(initResult).toBe(true);
      expect(progressUI.isInitialized).toBe(true);

      const showResult = await progressUI.showDashboard();
      expect(showResult).toBe(true);
      expect(progressUI.dashboardVisible).toBe(true);

      await progressUI.updateDashboardData();
      expect(progressUI.currentDashboardData).toBeDefined();

      const hideResult = progressUI.hideDashboard();
      expect(hideResult).toBe(true);
      expect(progressUI.dashboardVisible).toBe(false);

      progressUI.destroy();
      expect(progressUI.eventListeners.size).toBe(0);
    });

    it('should handle progress tracking workflow', () => {
      // Create and update progress bars
      const container = mockDocument.createElement();
      progressUI.createProgressBar('test-workflow', container);

      expect(progressUI.progressBars.has('test-workflow')).toBe(true);

      // Update progress through various stages
      progressUI.updateProgressBar('test-workflow', 25, { showPercentage: true });
      progressUI.updateProgressBar('test-workflow', 50, { text: 'Halfway there!' });
      progressUI.updateProgressBar('test-workflow', 100, { color: '#00ff00' });

      const progressBar = progressUI.progressBars.get('test-workflow');
      expect(progressBar.value).toBe(100);
    });

    it('should handle error recovery scenarios', async () => {
      // Test initialization with partial failures
      vi.spyOn(progressUI, 'setupProgressBars').mockResolvedValue();
      vi.spyOn(progressUI, 'setupDashboard').mockRejectedValue(new Error('Dashboard failed'));
      vi.spyOn(progressUI, 'handleError').mockImplementation(() => {});

      const result = await progressUI.init();

      expect(result).toBe(false);
      expect(progressUI.handleError).toHaveBeenCalled();
      expect(progressUI.isInitialized).toBe(false);
    });
  });

  describe('Configuration Edge Cases', () => {
    it('should handle null/undefined optional dependencies', () => {
      const limitedProgressUI = new ProgressUI({
        progressCore: mockProgressCore,
        errorHandler: mockErrorHandler,
        domUtils: mockDomUtils
      });

      expect(limitedProgressUI.kataCatalog).toBeNull();
      expect(limitedProgressUI.learningPathManager).toBeNull();
    });

    it('should handle empty configuration object', () => {
      const defaultProgressUI = new ProgressUI({
        progressCore: mockProgressCore,
        errorHandler: mockErrorHandler,
        domUtils: mockDomUtils
      }, {});

      expect(defaultProgressUI.config.animationDuration).toBe(300);
      expect(defaultProgressUI.config.showAnimations).toBe(true);
    });

    it('should handle partial configuration override', () => {
      const partialConfigProgressUI = new ProgressUI({
        progressCore: mockProgressCore,
        errorHandler: mockErrorHandler,
        domUtils: mockDomUtils
      }, {
        animationDuration: 500,
        chartColors: { primary: '#ff0000' }
      });

      expect(partialConfigProgressUI.config.animationDuration).toBe(500);
      expect(partialConfigProgressUI.config.updateInterval).toBe(1000); // Default
      expect(partialConfigProgressUI.config.chartColors.primary).toBe('#ff0000');
      expect(partialConfigProgressUI.config.chartColors.secondary).toBe('#28a745'); // Default
    });
  });
});
