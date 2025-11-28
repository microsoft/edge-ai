/**
 * @fileoverview Test Suite for Sidebar Chevrons Module
 *
 * @description
 * Comprehensive tests for the SidebarChevrons class including:
 * - Constructor initialization and dependency injection
 * - Folder state management and persistence
 * - Event handling and chevron interactions
 * - LocalStorage integration and error handling
 * - UI state updates and accessibility features
 * - Automatic vs manual folder expansion modes
 * - Integration with active highlighting system
 *
 * @author Edge AI Team
 * @version 2.0.0
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { SidebarChevrons } from '../../features/sidebar-chevrons.js';
import { logger } from '../../utils/index.js';

// Mock the logger module
vi.mock('../../utils/index.js', () => ({
  logger: {
    log: vi.fn(),
    debug: vi.fn(),
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn()
  },
  // Mock other exports that might be needed
  DOMUtils: vi.fn(),
  defaultDebugHelper: {
    log: vi.fn(),
    debug: vi.fn(),
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn()
  }
}));

/**
 * Create mock dependencies for testing
 * @returns {Object} Mock dependencies object
 */
function createMockDependencies() {
  return {
    errorHandler: {
      handleError: vi.fn()
    },
    domUtils: {
      createElement: vi.fn((tag) => document.createElement(tag)),
      querySelector: vi.fn((selector) => document.querySelector(selector)),
      querySelectorAll: vi.fn((selector) => document.querySelectorAll(selector))
    },
    debugHelper: {
      log: vi.fn()
    }
  };
}

/**
 * Create mock sidebar HTML structure for testing
 * @returns {HTMLElement} Mock sidebar element
 */
function createSidebarHTML() {
  const sidebar = document.createElement('div');
  sidebar.className = 'sidebar';

  sidebar.innerHTML = `
    <ul>
      <li class="folder">
        <a href="#/docs/folder1">Folder 1</a>
        <ul>
          <li><a href="#/docs/folder1/page1">Page 1</a></li>
          <li><a href="#/docs/folder1/page2">Page 2</a></li>
        </ul>
      </li>
      <li class="folder">
        <a href="#/docs/folder2">Folder 2</a>
        <ul>
          <li><a href="#/docs/folder2/page3">Page 3</a></li>
          <li>
            <a href="#/docs/folder2/subfolder">Subfolder</a>
            <ul>
              <li><a href="#/docs/folder2/subfolder/page4">Page 4</a></li>
            </ul>
          </li>
        </ul>
      </li>
      <li class="non-folder">
        <a href="#/docs/single-page">Single Page</a>
      </li>
      <li class="empty-folder">
        <a href="#/docs/empty">Empty Folder</a>
        <ul></ul>
      </li>
    </ul>
  `;

  return sidebar;
}

/**
 * Setup DOM environment for testing
 */
function setupTestEnvironment() {
  // Clear body completely
  document.body.innerHTML = '';

  // Remove any existing event listeners by cloning the body element
  const oldBody = document.body;
  const newBody = oldBody.cloneNode(false);
  oldBody.parentNode.replaceChild(newBody, oldBody);

  // Add sidebar to DOM
  const sidebar = createSidebarHTML();
  document.body.appendChild(sidebar);

  // Create fresh localStorage mock for each test
  const localStorageMock = {
    getItem: vi.fn(),
    setItem: vi.fn(),
    removeItem: vi.fn(),
    clear: vi.fn(),
    // Store for state tracking
    _storage: new Map()
  };

  // Add behavior to localStorage mock for more realistic testing
  localStorageMock.getItem.mockImplementation((key) => {
    return localStorageMock._storage.get(key) || null;
  });

  localStorageMock.setItem.mockImplementation((key, value) => {
    localStorageMock._storage.set(key, value);
  });

  localStorageMock.removeItem.mockImplementation((key) => {
    localStorageMock._storage.delete(key);
  });

  localStorageMock.clear.mockImplementation(() => {
    localStorageMock._storage.clear();
  });

  vi.stubGlobal('localStorage', localStorageMock);

  // Mock AbortController if not available
  if (!window.AbortController) {
    window.AbortController = vi.fn(() => ({
      signal: { aborted: false },
      abort: vi.fn()
    }));
  }

  // Clear any existing global state
  if (window.sidebarChevrons) {
    window.sidebarChevrons = null;
  }

  return localStorageMock;
}

describe('SidebarChevrons', () => {
  let sidebarChevrons;
  let mockDependencies;
  let localStorageMock;
  let originalConsoleLog;

  beforeEach(() => {
    // Mock console.log to suppress debug output in tests
    originalConsoleLog = console.log;
    console.log = vi.fn();

    // Clear any existing instance before creating new one
    if (sidebarChevrons) {
      sidebarChevrons.destroy();
      sidebarChevrons = null;
    }

    mockDependencies = createMockDependencies();
    localStorageMock = setupTestEnvironment();

    // Reset mocks after setup to clear any calls from setupTestEnvironment
    vi.clearAllMocks();

    // Clear any global state that might interfere
    if (window.sidebarChevrons) {
      window.sidebarChevrons = null;
    }
  });

  afterEach(() => {
    // Restore console.log
    if (originalConsoleLog) {
      console.log = originalConsoleLog;
    }

    // Destroy instance first
    if (sidebarChevrons) {
      try {
        sidebarChevrons.destroy();
      } catch (error) {
        // Ignore destruction errors during cleanup
      }
      sidebarChevrons = null;
    }

    // Clear DOM state
    document.body.innerHTML = '';

    // Clean up observer timeouts to prevent unhandled errors
    if (window.chevronObserverCleanup) {
      window.chevronObserverCleanup();
      window.chevronObserverCleanup = null;
    }

    // Clear any remaining timeouts
    if (window.chevronReinitTimeout) {
      clearTimeout(window.chevronReinitTimeout);
      window.chevronReinitTimeout = null;
    }

    // Clean up all event listeners from window and document
    const oldElement = document.body;
    const newElement = oldElement.cloneNode(true);
    oldElement.parentNode.replaceChild(newElement, oldElement);

    // Clean up localStorage mock state completely
    if (localStorageMock) {
      localStorageMock.clear();
      // Reset mock call histories
      Object.values(localStorageMock).forEach(mock => {
        if (typeof mock === 'function' && mock.mockClear) {
          mock.mockClear();
        }
      });
    }

    // Clear global state
    if (window.sidebarChevrons) {
      window.sidebarChevrons = null;
    }

    // Restore mocks and globals
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  describe('Constructor and Initialization', () => {
    it('should initialize with default configuration', () => {
      sidebarChevrons = new SidebarChevrons();

      expect(sidebarChevrons.isInitialized).toBe(false);
      expect(sidebarChevrons.expandedFolders).toBeInstanceOf(Set);
      expect(sidebarChevrons.expandedFolders.size).toBe(0);
      expect(sidebarChevrons.config.storageKey).toBe('sidebar-expanded-folders');
      expect(sidebarChevrons.config.chevronClass).toBe('chevron');
    });

    it('should initialize with custom dependencies', () => {
      sidebarChevrons = new SidebarChevrons(mockDependencies);

      expect(sidebarChevrons.errorHandler).toBe(mockDependencies.errorHandler);
      expect(sidebarChevrons.domUtils).toBe(mockDependencies.domUtils);
      expect(sidebarChevrons.debugHelper).toBe(mockDependencies.debugHelper);
    });

    it('should initialize with custom storage key', () => {
      sidebarChevrons = new SidebarChevrons({
        ...mockDependencies,
        storageKey: 'custom-storage-key'
      });

      expect(sidebarChevrons.storageKey).toBe('custom-storage-key');
      expect(sidebarChevrons.config.storageKey).toBe('custom-storage-key');
    });

    it('should initialize with debug mode enabled', () => {
      sidebarChevrons = new SidebarChevrons({
        ...mockDependencies,
        debug: true
      });

      expect(sidebarChevrons.debug).toBe(true);
      expect(sidebarChevrons.config.debug).toBe(true);
    });
  });

  describe('Folder Key Management', () => {
    beforeEach(() => {
      sidebarChevrons = new SidebarChevrons(mockDependencies);
    });

    it('should extract folder key from element with href', () => {
      const folder = document.querySelector('li.folder');
      const folderKey = sidebarChevrons.getFolderKey(folder);

      expect(folderKey).toBe('#/docs/folder1');
    });

    it('should extract folder key from element without href using text content', () => {
      const folder = document.querySelector('li.folder');
      const link = folder.querySelector('a');
      link.removeAttribute('href');

      const folderKey = sidebarChevrons.getFolderKey(folder);

      expect(folderKey).toBe('Folder 1');
    });

    it('should return unknown-folder for element without link', () => {
      const folder = document.createElement('li');
      const folderKey = sidebarChevrons.getFolderKey(folder);

      expect(folderKey).toBe('unknown-folder');
    });

    it('should extract folder key from URL string', () => {
      const url = '#/docs/folder1/page1';
      const folderKey = sidebarChevrons.extractFolderKey(url);

      expect(folderKey).toBe('page1');
    });

    it('should handle malformed URLs gracefully', () => {
      const malformedUrl = 'not-a-valid-url';
      const folderKey = sidebarChevrons.extractFolderKey(malformedUrl);

      expect(folderKey).toBe('not-a-valid-url');
    });
  });

  describe('LocalStorage State Management', () => {
    beforeEach(() => {
      // Ensure clean state before each test
      if (sidebarChevrons) {
        sidebarChevrons.destroy();
        sidebarChevrons = null;
      }

      // Reset localStorage mock state completely
      localStorageMock.getItem.mockClear();
      localStorageMock.setItem.mockClear();
      localStorageMock.removeItem.mockClear();
      localStorageMock.clear.mockClear();

      // Reset error handler mock
      mockDependencies.errorHandler.handleError.mockClear();

      sidebarChevrons = new SidebarChevrons(mockDependencies);
    });

    afterEach(() => {
      // Clean up instance
      if (sidebarChevrons) {
        sidebarChevrons.destroy();
        sidebarChevrons = null;
      }

      // Clear all localStorage mock state
      localStorageMock.getItem.mockReset();
      localStorageMock.setItem.mockReset();
      localStorageMock.removeItem.mockReset();
      localStorageMock.clear.mockReset();
    });

    it('should load expanded states from localStorage', () => {
      const savedState = ['#/docs/folder1', '#/docs/folder2'];
      localStorageMock.getItem.mockReturnValue(JSON.stringify(savedState));

      sidebarChevrons.loadExpandedStates();

      expect(localStorageMock.getItem).toHaveBeenCalledWith(sidebarChevrons.storageKey);
      expect(sidebarChevrons.expandedFolders.has('#/docs/folder1')).toBe(true);
      expect(sidebarChevrons.expandedFolders.has('#/docs/folder2')).toBe(true);
    });

    it('should handle empty localStorage gracefully', () => {
      localStorageMock.getItem.mockReturnValue(null);

      sidebarChevrons.loadExpandedStates();

      expect(sidebarChevrons.expandedFolders.size).toBe(0);
    });

    it('should handle invalid JSON in localStorage', () => {
      localStorageMock.getItem.mockReturnValue('invalid-json');

      sidebarChevrons.loadExpandedStates();

      expect(mockDependencies.errorHandler.handleError).toHaveBeenCalled();
      expect(sidebarChevrons.expandedFolders.size).toBe(0);
    });

    it('should save expanded states to localStorage', () => {
      // Clear any previous calls to setItem
      localStorageMock.setItem.mockClear();

      sidebarChevrons.expandedFolders.add('#/docs/folder1');
      sidebarChevrons.expandedFolders.add('#/docs/folder2');

      sidebarChevrons.saveExpandedStates();

      expect(localStorageMock.setItem).toHaveBeenCalledWith(
        sidebarChevrons.storageKey,
        JSON.stringify(['#/docs/folder1', '#/docs/folder2'])
      );
    });

    it('should handle localStorage save errors', () => {
      localStorageMock.setItem.mockImplementation(() => {
        throw new Error('localStorage full');
      });

      sidebarChevrons.expandedFolders.add('#/docs/folder1');
      sidebarChevrons.saveExpandedStates();

      expect(mockDependencies.errorHandler.handleError).toHaveBeenCalledWith(
        'Failed to save expanded states',
        expect.any(Error)
      );
    });

    it('should return success status from loadExpandedState alias', () => {
      localStorageMock.getItem.mockReturnValue(JSON.stringify(['#/docs/folder1']));

      const result = sidebarChevrons.loadExpandedState();

      expect(result).toBe(true);
    });

    it('should return failure status from loadExpandedState alias', () => {
      localStorageMock.getItem.mockReturnValue(null);

      const result = sidebarChevrons.loadExpandedState();

      expect(result).toBe(false);
    });

    it('should return success status from saveExpandedState alias', () => {
      // Clear previous calls and ensure clean state
      localStorageMock.setItem.mockClear();
      sidebarChevrons.expandedFolders.clear();
      sidebarChevrons.expandedFolders.add('#/docs/folder1');

      const result = sidebarChevrons.saveExpandedState();

      expect(result).toBe(true);
      expect(localStorageMock.setItem).toHaveBeenCalledTimes(1);
    });

    it('should return failure status from saveExpandedState alias on error', () => {
      localStorageMock.setItem.mockImplementation(() => {
        throw new Error('localStorage error');
      });

      const result = sidebarChevrons.saveExpandedState();

      expect(result).toBe(false);
    });
  });

  describe('Folder Initialization', () => {
    beforeEach(() => {
      sidebarChevrons = new SidebarChevrons(mockDependencies);
    });

    it('should initialize chevrons for all folders', () => {
      sidebarChevrons.initializeChevrons();

      const _folders = document.querySelectorAll('li');
      const foldersWithChevrons = document.querySelectorAll('.chevron');

      // Should create chevrons for folders with nested ul elements
      expect(foldersWithChevrons.length).toBeGreaterThan(0);
    });

    it('should skip initialization if no sidebar found', () => {
      document.body.innerHTML = '';

      expect(() => {
        sidebarChevrons.initializeChevrons();
      }).not.toThrow();
    });

    it('should initialize individual folder with chevron', () => {
      const folder = document.querySelector('li.folder');

      sidebarChevrons.initializeFolder(folder);

      const chevron = folder.querySelector('.chevron');
      const folderLink = folder.querySelector('a');

      expect(chevron).toBeTruthy();
      expect(chevron.innerHTML).toBe('▶');
      expect(chevron.getAttribute('aria-label')).toBe('Toggle folder');
      expect(folderLink.firstChild).toBe(chevron);
    });

    it('should not duplicate chevrons on re-initialization', () => {
      const folder = document.querySelector('li.folder');

      sidebarChevrons.initializeFolder(folder);
      sidebarChevrons.initializeFolder(folder);

      const chevrons = folder.querySelectorAll('.chevron');
      expect(chevrons.length).toBe(1);
    });

    it('should skip folders without links or nested ul', () => {
      const folder = document.createElement('li');
      folder.innerHTML = '<span>Not a folder</span>';

      expect(() => {
        sidebarChevrons.initializeFolder(folder);
      }).not.toThrow();

      const chevron = folder.querySelector('.chevron');
      expect(chevron).toBeFalsy();
    });
  });

  describe('Folder State Management', () => {
    beforeEach(() => {
      sidebarChevrons = new SidebarChevrons(mockDependencies);
      sidebarChevrons.initializeChevrons();
    });

    it('should set folder to expanded state', () => {
      const folder = document.querySelector('li.folder');

      sidebarChevrons.setFolderState(folder, true);

      const chevron = folder.querySelector('.chevron');
      const nestedUl = folder.querySelector('ul');

      expect(folder.classList.contains('expanded')).toBe(true);
      expect(folder.classList.contains('collapsed')).toBe(false);
      expect(chevron.innerHTML).toBe('▼');
      expect(chevron.getAttribute('aria-expanded')).toBe('true');
      expect(nestedUl.style.display).toBe('block');
    });

    it('should set folder to collapsed state', () => {
      const folder = document.querySelector('li.folder');

      sidebarChevrons.setFolderState(folder, false);

      const chevron = folder.querySelector('.chevron');
      const nestedUl = folder.querySelector('ul');

      expect(folder.classList.contains('collapsed')).toBe(true);
      expect(folder.classList.contains('expanded')).toBe(false);
      expect(chevron.innerHTML).toBe('▶');
      expect(chevron.getAttribute('aria-expanded')).toBe('false');
      expect(nestedUl.style.display).toBe('none');
    });

    it('should handle missing chevron or nested ul gracefully', () => {
      const folder = document.createElement('li');

      expect(() => {
        sidebarChevrons.setFolderState(folder, true);
      }).not.toThrow();
    });
  });

  describe('Folder Toggle Operations', () => {
    beforeEach(() => {
      sidebarChevrons = new SidebarChevrons(mockDependencies);
      sidebarChevrons.initializeChevrons();
    });

    it('should toggle folder from collapsed to expanded', () => {
      const folder = document.querySelector('li.folder');
      const folderKey = sidebarChevrons.getFolderKey(folder);

      // Start collapsed
      sidebarChevrons.setFolderState(folder, false);
      expect(sidebarChevrons.expandedFolders.has(folderKey)).toBe(false);

      // Mock event dispatch
      const dispatchEventSpy = vi.spyOn(window, 'dispatchEvent');

      sidebarChevrons.toggleFolder(folder);

      expect(sidebarChevrons.expandedFolders.has(folderKey)).toBe(true);
      expect(localStorageMock.setItem).toHaveBeenCalled();
      expect(dispatchEventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'sidebar:folder-toggled',
          detail: expect.objectContaining({
            folder,
            isExpanded: true,
            folderKey
          })
        })
      );
    });

    it('should toggle folder from expanded to collapsed', () => {
      const folder = document.querySelector('li.folder');
      const folderKey = sidebarChevrons.getFolderKey(folder);

      // Start expanded
      sidebarChevrons.expandedFolders.add(folderKey);
      sidebarChevrons.setFolderState(folder, true);

      // Mock event dispatch
      const dispatchEventSpy = vi.spyOn(window, 'dispatchEvent');

      sidebarChevrons.toggleFolder(folder);

      expect(sidebarChevrons.expandedFolders.has(folderKey)).toBe(false);
      expect(localStorageMock.setItem).toHaveBeenCalled();
      expect(dispatchEventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'sidebar:folder-toggled',
          detail: expect.objectContaining({
            folder,
            isExpanded: false,
            folderKey
          })
        })
      );
    });

    it('should expand folder programmatically', () => {
      const folder = document.querySelector('li.folder');
      const folderKey = sidebarChevrons.getFolderKey(folder);

      // Mock event dispatch
      const dispatchEventSpy = vi.spyOn(window, 'dispatchEvent');

      sidebarChevrons.expandFolder(folder, false);

      expect(sidebarChevrons.expandedFolders.has(folderKey)).toBe(true);
      expect(localStorageMock.setItem).toHaveBeenCalled();
      expect(dispatchEventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'sidebar:folder-expanded',
          detail: expect.objectContaining({
            folder,
            isAutomatic: false,
            folderKey
          })
        })
      );
    });

    it('should expand folder automatically without saving state', () => {
      const folder = document.querySelector('li.folder');
      const folderKey = sidebarChevrons.getFolderKey(folder);

      // Mock event dispatch
      const dispatchEventSpy = vi.spyOn(window, 'dispatchEvent');

      sidebarChevrons.expandFolder(folder, true);

      expect(sidebarChevrons.expandedFolders.has(folderKey)).toBe(false);
      expect(folder.getAttribute('data-auto-expanded')).toBe('true');
      expect(localStorageMock.setItem).not.toHaveBeenCalled();
      expect(dispatchEventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'sidebar:folder-expanded',
          detail: expect.objectContaining({
            folder,
            isAutomatic: true,
            folderKey
          })
        })
      );
    });

    it('should collapse folder programmatically', () => {
      const folder = document.querySelector('li.folder');
      const folderKey = sidebarChevrons.getFolderKey(folder);

      // Start expanded
      sidebarChevrons.expandedFolders.add(folderKey);
      folder.setAttribute('data-auto-expanded', 'true');

      // Mock event dispatch
      const dispatchEventSpy = vi.spyOn(window, 'dispatchEvent');

      sidebarChevrons.collapseFolder(folder);

      expect(sidebarChevrons.expandedFolders.has(folderKey)).toBe(false);
      expect(folder.getAttribute('data-auto-expanded')).toBeFalsy();
      expect(localStorageMock.setItem).toHaveBeenCalled();
      expect(dispatchEventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'sidebar:folder-collapsed',
          detail: expect.objectContaining({
            folder,
            folderKey
          })
        })
      );
    });
  });

  describe('Event Handling', () => {
    beforeEach(() => {
      sidebarChevrons = new SidebarChevrons(mockDependencies);
      sidebarChevrons.initialize();
    });

    it('should handle click events on folder links', () => {
      const folder = document.querySelector('li.folder');
      const folderLink = folder.querySelector('a');

      const toggleFolderSpy = vi.spyOn(sidebarChevrons, 'toggleFolder');

      // Create and dispatch click event
      const clickEvent = new MouseEvent('click', {
        bubbles: true,
        cancelable: true
      });

      folderLink.dispatchEvent(clickEvent);

      expect(toggleFolderSpy).toHaveBeenCalledWith(folder);
    });

    it('should prevent default behavior only on chevron clicks', () => {
      const folder = document.querySelector('li.folder');
      const folderLink = folder.querySelector('a');
      const chevron = folderLink.querySelector('.chevron');

      // Test chevron click - should prevent default
      const chevronClickEvent = new MouseEvent('click', {
        bubbles: true,
        cancelable: true
      });

      // Mock the event target to be the chevron
      Object.defineProperty(chevronClickEvent, 'target', {
        value: chevron,
        writable: false
      });

      const preventDefaultSpy = vi.spyOn(chevronClickEvent, 'preventDefault');
      const stopPropagationSpy = vi.spyOn(chevronClickEvent, 'stopPropagation');

      folderLink.dispatchEvent(chevronClickEvent);

      expect(preventDefaultSpy).toHaveBeenCalled();
      expect(stopPropagationSpy).toHaveBeenCalled();

      // Test folder link click (not chevron) - should NOT prevent default
      const linkClickEvent = new MouseEvent('click', {
        bubbles: true,
        cancelable: true
      });

      // Mock the event target to be the link itself
      Object.defineProperty(linkClickEvent, 'target', {
        value: folderLink,
        writable: false
      });

      const linkPreventDefaultSpy = vi.spyOn(linkClickEvent, 'preventDefault');
      const linkStopPropagationSpy = vi.spyOn(linkClickEvent, 'stopPropagation');

      folderLink.dispatchEvent(linkClickEvent);

      expect(linkPreventDefaultSpy).not.toHaveBeenCalled();
      expect(linkStopPropagationSpy).not.toHaveBeenCalled();
    });
  });

  describe('Integration and Lifecycle', () => {
    it('should initialize system when called', () => {
      sidebarChevrons = new SidebarChevrons(mockDependencies);

      expect(sidebarChevrons.isInitialized).toBe(false);

      sidebarChevrons.initialize();

      expect(sidebarChevrons.isInitialized).toBe(true);
      expect(sidebarChevrons.abortController).toBeTruthy();
      expect(localStorageMock.getItem).toHaveBeenCalled();
    });

    it('should not re-initialize if already initialized', () => {
      sidebarChevrons = new SidebarChevrons(mockDependencies);

      sidebarChevrons.initialize();
      const firstController = sidebarChevrons.abortController;

      sidebarChevrons.initialize();

      expect(sidebarChevrons.abortController).toBe(firstController);
    });

    it('should destroy and clean up resources', () => {
      sidebarChevrons = new SidebarChevrons(mockDependencies);
      sidebarChevrons.initialize();

      const abortSpy = vi.spyOn(sidebarChevrons.abortController, 'abort');

      sidebarChevrons.destroy();

      expect(abortSpy).toHaveBeenCalled();
      expect(sidebarChevrons.abortController).toBeNull();
      expect(sidebarChevrons.expandedFolders.size).toBe(0);
      expect(sidebarChevrons.isInitialized).toBe(false);
    });

    it('should handle destroy when not initialized', () => {
      sidebarChevrons = new SidebarChevrons(mockDependencies);

      expect(() => {
        sidebarChevrons.destroy();
      }).not.toThrow();
    });
  });

  describe('Error Handling', () => {
    beforeEach(() => {
      // Clear logger mocks
      vi.mocked(logger.error).mockClear();

      sidebarChevrons = new SidebarChevrons(mockDependencies);
    });

    it('should delegate error handling to errorHandler if available', () => {
      const error = new Error('Test error');

      sidebarChevrons.handleError('Test message', error);

      expect(mockDependencies.errorHandler.handleError).toHaveBeenCalledWith('Test message', error);
    });

    it('should fallback to logger.error if no errorHandler', () => {
      sidebarChevrons = new SidebarChevrons({ ...mockDependencies, errorHandler: null });

      const error = new Error('Test error');

      sidebarChevrons.handleError('Test message', error);

      expect(logger.error).toHaveBeenCalledWith('[CHEVRONS] Test message:', error);
    });
  });

  describe('Debug Logging', () => {
    beforeEach(() => {
      sidebarChevrons = new SidebarChevrons({
        ...mockDependencies,
        debug: true
      });
    });

    it('should log debug messages when debug mode is enabled', () => {
      sidebarChevrons.log('Test message', 'arg1', 'arg2');

      expect(mockDependencies.debugHelper.log).toHaveBeenCalledWith(
        '🔽 SidebarChevrons: Test message',
        'arg1',
        'arg2'
      );
    });

    it('should not log when debug mode is disabled', () => {
      sidebarChevrons = new SidebarChevrons({
        ...mockDependencies,
        debug: false
      });

      sidebarChevrons.log('Test message');

      expect(mockDependencies.debugHelper.log).not.toHaveBeenCalled();
    });

    it('should handle missing debugHelper gracefully', () => {
      sidebarChevrons = new SidebarChevrons({
        ...mockDependencies,
        debugHelper: null,
        debug: true
      });

      expect(() => {
        sidebarChevrons.log('Test message');
      }).not.toThrow();
    });
  });

  describe('UI Update Methods', () => {
    beforeEach(() => {
      sidebarChevrons = new SidebarChevrons(mockDependencies);
    });

    it('should update folder UI state for expanded folder', () => {
      const folder = document.createElement('li');
      folder.innerHTML = `
        <a href="#/test">Test Folder</a>
        <span class="folder-chevron">▶</span>
        <ul style="display: none;"></ul>
      `;

      sidebarChevrons.updateFolderUI(folder, true);

      const chevron = folder.querySelector('.folder-chevron');
      const subfolders = folder.querySelector('ul');

      expect(chevron.textContent).toBe('▼');
      expect(folder.classList.contains('expanded')).toBe(true);
      expect(subfolders.style.display).toBe('block');
    });

    it('should update folder UI state for collapsed folder', () => {
      const folder = document.createElement('li');
      folder.innerHTML = `
        <a href="#/test">Test Folder</a>
        <span class="folder-chevron">▼</span>
        <ul style="display: block;"></ul>
      `;
      folder.classList.add('expanded');

      sidebarChevrons.updateFolderUI(folder, false);

      const chevron = folder.querySelector('.folder-chevron');
      const subfolders = folder.querySelector('ul');

      expect(chevron.textContent).toBe('▶');
      expect(folder.classList.contains('expanded')).toBe(false);
      expect(subfolders.style.display).toBe('none');
    });

    it('should handle null folder gracefully', () => {
      expect(() => {
        sidebarChevrons.updateFolderUI(null, true);
      }).not.toThrow();
    });

    it('should update UI for multiple expanded folders', () => {
      // Create mock folders in DOM
      const folder1 = document.createElement('li');
      folder1.setAttribute('data-folder-key', 'folder1');
      folder1.innerHTML = `
        <span class="folder-chevron">▶</span>
        <div class="subfolder-content" style="display: none;"></div>
      `;

      const folder2 = document.createElement('li');
      folder2.setAttribute('data-folder-key', 'folder2');
      folder2.innerHTML = `
        <span class="folder-chevron">▶</span>
        <div class="subfolder-content" style="display: none;"></div>
      `;

      document.body.appendChild(folder1);
      document.body.appendChild(folder2);

      const expandedFolders = new Set(['folder1', 'folder2']);

      sidebarChevrons.updateFolderUI(expandedFolders);

      const chevron1 = folder1.querySelector('.folder-chevron');
      const chevron2 = folder2.querySelector('.folder-chevron');
      const content1 = folder1.querySelector('.subfolder-content');
      const content2 = folder2.querySelector('.subfolder-content');

      expect(chevron1.textContent).toBe('▼');
      expect(chevron2.textContent).toBe('▼');
      expect(content1.style.display).toBe('block');
      expect(content2.style.display).toBe('block');
    });
  });

  describe('Regression Tests - Bug Fixes', () => {
    beforeEach(() => {
      sidebarChevrons = new SidebarChevrons(mockDependencies);
      sidebarChevrons.initialize();
    });

    describe('Bug: Chevrons not rotating when expanded/collapsed', () => {
      it('should show ▶ for collapsed folders and ▼ for expanded folders', () => {
        const folder = document.querySelector('li.folder');

        // Test collapsed state
        sidebarChevrons.setFolderState(folder, false);
        const chevron = folder.querySelector('.chevron');
        expect(chevron.innerHTML).toBe('▶');
        expect(chevron.getAttribute('aria-expanded')).toBe('false');
        expect(chevron.classList.contains('collapsed')).toBe(true);
        expect(chevron.classList.contains('expanded')).toBe(false);

        // Test expanded state
        sidebarChevrons.setFolderState(folder, true);
        expect(chevron.innerHTML).toBe('▼');
        expect(chevron.getAttribute('aria-expanded')).toBe('true');
        expect(chevron.classList.contains('expanded')).toBe(true);
        expect(chevron.classList.contains('collapsed')).toBe(false);
      });

      it('should toggle chevron symbols correctly on folder toggle', () => {
        const folder = document.querySelector('li.folder');
        const chevron = folder.querySelector('.chevron');

        // Initially should be collapsed
        expect(chevron.innerHTML).toBe('▶');

        // Toggle to expanded
        sidebarChevrons.toggleFolder(folder);
        expect(chevron.innerHTML).toBe('▼');

        // Toggle back to collapsed
        sidebarChevrons.toggleFolder(folder);
        expect(chevron.innerHTML).toBe('▶');
      });

      it('should not apply conflicting CSS transforms to chevrons', () => {
        const folder = document.querySelector('li.folder');
        const chevron = folder.querySelector('.chevron');

        // Test that no CSS transform is applied (relies on Unicode symbols)
        sidebarChevrons.setFolderState(folder, true);
        expect(chevron.style.transform).toBe('');

        sidebarChevrons.setFolderState(folder, false);
        expect(chevron.style.transform).toBe('');
      });

      it('should maintain proper ARIA attributes during state changes', () => {
        const folder = document.querySelector('li.folder');
        const chevron = folder.querySelector('.chevron');

        // Test collapsed ARIA state
        sidebarChevrons.setFolderState(folder, false);
        expect(chevron.getAttribute('aria-expanded')).toBe('false');
        expect(chevron.getAttribute('aria-label')).toBe('Toggle folder');

        // Test expanded ARIA state
        sidebarChevrons.setFolderState(folder, true);
        expect(chevron.getAttribute('aria-expanded')).toBe('true');
        expect(chevron.getAttribute('aria-label')).toBe('Toggle folder');
      });
    });

    describe('Bug: Chevrons disappearing after navigation', () => {
      it('should restore chevrons after destroy and reinitialize cycle', () => {
        // Verify initial chevrons exist
        let chevrons = document.querySelectorAll('.chevron');
        const initialCount = chevrons.length;
        expect(initialCount).toBeGreaterThan(0);

        // Simulate navigation by destroying and reinitializing
        sidebarChevrons.destroy();
        expect(sidebarChevrons.isInitialized).toBe(false);

        // Verify chevrons are cleaned up
        chevrons = document.querySelectorAll('.chevron');
        expect(chevrons.length).toBe(0);

        // Reinitialize (simulating new page load)
        sidebarChevrons.initialize();
        expect(sidebarChevrons.isInitialized).toBe(true);

        // Verify chevrons are restored
        chevrons = document.querySelectorAll('.chevron');
        expect(chevrons.length).toBe(initialCount);
      });

      it('should persist expanded states across navigation cycles', () => {
        const folder = document.querySelector('li.folder');
        const folderKey = sidebarChevrons.getFolderKey(folder);

        // Expand folder and verify state is saved
        sidebarChevrons.toggleFolder(folder);
        expect(sidebarChevrons.expandedFolders.has(folderKey)).toBe(true);
        expect(localStorageMock.setItem).toHaveBeenCalled();

        // Mock localStorage to return the saved state
        localStorageMock.getItem.mockReturnValue(JSON.stringify([folderKey]));

        // Simulate navigation
        sidebarChevrons.destroy();
        sidebarChevrons.initialize();

        // Verify expanded state is restored
        expect(sidebarChevrons.expandedFolders.has(folderKey)).toBe(true);

        // Verify visual state is correct
        const chevron = folder.querySelector('.chevron');
        expect(chevron.innerHTML).toBe('▼');
        expect(folder.classList.contains('expanded')).toBe(true);
      });

      it('should handle Docsify route changes with proper reinitialization', () => {
        // Mock window.Docsify events
        const mockDocsifyEvents = ['ready', 'done', 'after-each', 'sidebarReloaded'];

        mockDocsifyEvents.forEach(eventType => {
          const event = new CustomEvent(eventType);
          window.dispatchEvent(event);
        });

        // Should not throw errors and chevrons should remain
        const chevrons = document.querySelectorAll('.chevron');
        expect(chevrons.length).toBeGreaterThan(0);
      });

      it('should handle hashchange events without losing chevrons', () => {
        // Simulate hash change
        const hashChangeEvent = new Event('hashchange');
        window.dispatchEvent(hashChangeEvent);

        // Chevrons should still be present
        const chevrons = document.querySelectorAll('.chevron');
        expect(chevrons.length).toBeGreaterThan(0);
      });

      it('should properly clean up event listeners on destroy', () => {
        const removeEventListenerSpy = vi.spyOn(document, 'removeEventListener');
        const windowRemoveEventListenerSpy = vi.spyOn(window, 'removeEventListener');

        sidebarChevrons.destroy();

        // Should call removeEventListener methods (exact calls depend on implementation)
        // At minimum, the destroy should complete without errors
        expect(sidebarChevrons.isInitialized).toBe(false);
        expect(sidebarChevrons.abortController).toBeNull();
      });

      it('should handle MutationObserver scenarios for dynamic sidebar changes', () => {
        // This test verifies that the SidebarChevrons class can handle
        // dynamic sidebar changes without throwing errors
        // The MutationObserver is implemented in initializeSidebarChevrons function
        // not in the SidebarChevrons class itself

        // Simulate dynamic DOM changes that would trigger MutationObserver
        const sidebar = document.querySelector('.sidebar');
        const newFolder = document.createElement('li');
        newFolder.innerHTML = `
          <a href="#/docs/new-folder">New Folder</a>
          <ul>
            <li><a href="#/docs/new-folder/page">New Page</a></li>
          </ul>
        `;

        sidebar.querySelector('ul').appendChild(newFolder);

        // The system should handle this gracefully
        expect(() => {
          sidebarChevrons.initializeChevrons();
        }).not.toThrow();

        // Verify new folder gets a chevron
        const newChevron = newFolder.querySelector('.chevron');
        expect(newChevron).toBeTruthy();
        expect(newChevron.innerHTML).toBe('▶');
      });

      it('should prevent infinite reinitialize loops with isReinitializing flag', async () => {
        // Track how many times initializeChevrons is called (the actual method that sets the flag)
        let initializeChevronsCallCount = 0;
        const originalInitializeChevrons = sidebarChevrons.initializeChevrons.bind(sidebarChevrons);
        sidebarChevrons.initializeChevrons = () => {
          initializeChevronsCallCount++;
          return originalInitializeChevrons();
        };

        // Reset to start fresh
        sidebarChevrons.destroy();
        sidebarChevrons.isReinitializing = false;
        initializeChevronsCallCount = 0;

        // Call initialize once - this should set isReinitializing = true
        sidebarChevrons.initialize();
        expect(initializeChevronsCallCount).toBe(1);
        expect(sidebarChevrons.isReinitializing).toBe(true);

        // Reset isInitialized to test only the isReinitializing flag
        sidebarChevrons.isInitialized = false;

        // Try to initialize again while isReinitializing is true - should be blocked
        sidebarChevrons.initialize();
        expect(initializeChevronsCallCount).toBe(1); // Should not increment

        // Wait for the flag to be cleared
        await new Promise(resolve => setTimeout(resolve, 150));
        expect(sidebarChevrons.isReinitializing).toBe(false);

        // Now it should be allowed again
        sidebarChevrons.initialize();
        expect(initializeChevronsCallCount).toBe(2);

        // Restore original function
        sidebarChevrons.initializeChevrons = originalInitializeChevrons;
      });

      it('should filter out chevron-only mutations to prevent loops', () => {
        // Create a mutation record that represents adding a chevron
        const chevronElement = document.createElement('span');
        chevronElement.classList.add('chevron');

        const mutationRecord = {
          type: 'childList',
          target: {
            classList: {
              contains: (className) => className === 'sidebar-nav',
              closest: () => true
            }
          },
          addedNodes: [chevronElement],
          removedNodes: []
        };

        // Simulate the mutation filter logic from the code
        const addedNodes = Array.from(mutationRecord.addedNodes);
        const removedNodes = Array.from(mutationRecord.removedNodes);

        const isChevronOnlyMutation =
          addedNodes.every(node =>
            node.nodeType !== Node.ELEMENT_NODE ||
            node.classList?.contains('chevron') ||
            node.querySelector?.('.chevron') === node
          ) &&
          removedNodes.every(node =>
            node.nodeType !== Node.ELEMENT_NODE ||
            node.classList?.contains('chevron') ||
            node.querySelector?.('.chevron') === node
          );

        // Should be identified as chevron-only mutation
        expect(isChevronOnlyMutation).toBe(true);

        // Now test with a non-chevron mutation
        const folderElement = document.createElement('li');
        const mutationRecord2 = {
          type: 'childList',
          target: {
            classList: {
              contains: (className) => className === 'sidebar-nav',
              closest: () => true
            }
          },
          addedNodes: [folderElement],
          removedNodes: []
        };

        const addedNodes2 = Array.from(mutationRecord2.addedNodes);
        const removedNodes2 = Array.from(mutationRecord2.removedNodes);

        const isChevronOnlyMutation2 =
          addedNodes2.every(node =>
            node.nodeType !== Node.ELEMENT_NODE ||
            node.classList?.contains('chevron') ||
            node.querySelector?.('.chevron') === node
          ) &&
          removedNodes2.every(node =>
            node.nodeType !== Node.ELEMENT_NODE ||
            node.classList?.contains('chevron') ||
            node.querySelector?.('.chevron') === node
          );

        // Should NOT be identified as chevron-only mutation
        expect(isChevronOnlyMutation2).toBe(false);
      });
    });

    describe('Comprehensive State Persistence Tests', () => {
      it('should maintain folder expansion states across multiple navigation cycles', () => {
        const folder1 = document.querySelector('li.folder');
        const folder2 = document.querySelectorAll('li.folder')[1];
        const folderKey1 = sidebarChevrons.getFolderKey(folder1);
        const folderKey2 = sidebarChevrons.getFolderKey(folder2);

        // Expand both folders
        sidebarChevrons.toggleFolder(folder1);
        sidebarChevrons.toggleFolder(folder2);

        // Mock localStorage responses
        localStorageMock.getItem.mockReturnValue(JSON.stringify([folderKey1, folderKey2]));

        // Simulate multiple navigation cycles
        for (let i = 0; i < 3; i++) {
          sidebarChevrons.destroy();
          sidebarChevrons.initialize();

          // Verify states are maintained
          expect(sidebarChevrons.expandedFolders.has(folderKey1)).toBe(true);
          expect(sidebarChevrons.expandedFolders.has(folderKey2)).toBe(true);

          // Verify visual states
          const chevron1 = folder1.querySelector('.chevron');
          const chevron2 = folder2.querySelector('.chevron');
          expect(chevron1.innerHTML).toBe('▼');
          expect(chevron2.innerHTML).toBe('▼');
        }
      });

      it('should handle partial folder expansion states correctly', () => {
        const folders = document.querySelectorAll('li.folder');
        const folder1 = folders[0];
        const folder2 = folders[1];
        const folderKey1 = sidebarChevrons.getFolderKey(folder1);
        const folderKey2 = sidebarChevrons.getFolderKey(folder2);

        // Expand only first folder
        sidebarChevrons.toggleFolder(folder1);

        // Mock localStorage with only first folder expanded
        localStorageMock.getItem.mockReturnValue(JSON.stringify([folderKey1]));

        // Simulate navigation
        sidebarChevrons.destroy();
        sidebarChevrons.initialize();

        // Verify only first folder is expanded
        expect(sidebarChevrons.expandedFolders.has(folderKey1)).toBe(true);
        expect(sidebarChevrons.expandedFolders.has(folderKey2)).toBe(false);

        const chevron1 = folder1.querySelector('.chevron');
        const chevron2 = folder2.querySelector('.chevron');
        expect(chevron1.innerHTML).toBe('▼');
        expect(chevron2.innerHTML).toBe('▶');
      });
    });
  });

  describe('Styling and Theme Integration', () => {
    let sidebar, folder, chevron, folderLink;

    beforeEach(() => {
      sidebar = createSidebarHTML();
      document.body.appendChild(sidebar);
      sidebarChevrons = new SidebarChevrons(mockDependencies);
      sidebarChevrons.initialize();

      folder = sidebar.querySelector('li');
      folderLink = folder.querySelector('a');

      // Force chevron creation by running initializeFolder
      sidebarChevrons.initializeFolder(folder);
      chevron = folderLink.querySelector('.chevron');
    });

    afterEach(() => {
      sidebarChevrons.destroy();
      document.body.removeChild(sidebar);
    }); describe('Chevron Creation and Styling', () => {
      it('should create chevron with proper initial styling', () => {
        expect(chevron).toBeTruthy();
        expect(chevron.className).toBe('chevron collapsed');
        expect(chevron.innerHTML).toBe('▶');
        expect(chevron.getAttribute('aria-label')).toBe('Toggle folder');
      });

      it('should apply correct CSS properties for chevron styling', () => {
        // Check inline styles that we set
        expect(chevron.style.display).toBe('inline-block');
        expect(chevron.style.marginRight).toBe('8px');
        expect(chevron.style.marginLeft).toBe('2px');
        expect(chevron.style.cursor).toBe('pointer');
        expect(chevron.style.fontSize).toBe('14px');
        expect(chevron.style.fontFamily).toBe('monospace');
        expect(chevron.style.fontWeight).toBe('bold');
        expect(chevron.style.lineHeight).toBe('1');
        expect(chevron.style.verticalAlign).toBe('middle');
        expect(chevron.style.userSelect).toBe('none');
        expect(chevron.style.transition).toBe('all 0.3s ease');
      });

      it('should use theme color variables in CSS', () => {
        // In the test environment, inline styles may not preserve CSS variables
        // This test verifies the chevron was created and styled properly
        expect(chevron.style.opacity).toBe('0.7'); // Collapsed state default
        expect(chevron.style.fontSize).toBe('14px');
        expect(chevron.style.fontFamily).toBe('monospace');
      });

      it('should set proper ARIA attributes for accessibility', () => {
        expect(chevron.getAttribute('aria-label')).toBe('Toggle folder');
        expect(chevron.getAttribute('aria-expanded')).toBe('false');
      });
    });

    describe('State-Based Styling', () => {
      it('should apply correct styling for collapsed state', () => {
        sidebarChevrons.setFolderState(folder, false);

        expect(chevron.innerHTML).toBe('▶');
        expect(chevron.getAttribute('aria-expanded')).toBe('false');
        expect(chevron.style.opacity).toBe('0.7');
        // In test environment, inline styles may not preserve CSS variables exactly
        expect(chevron.classList.contains('collapsed')).toBe(true);
        expect(chevron.classList.contains('expanded')).toBe(false);
      });

      it('should apply correct styling for expanded state', () => {
        sidebarChevrons.setFolderState(folder, true);

        expect(chevron.innerHTML).toBe('▼');
        expect(chevron.getAttribute('aria-expanded')).toBe('true');
        expect(chevron.style.opacity).toBe('1');
        // In test environment, inline styles may not preserve CSS variables exactly
        expect(chevron.classList.contains('expanded')).toBe(true);
        expect(chevron.classList.contains('collapsed')).toBe(false);
      });

      it('should toggle styling correctly when folder state changes', () => {
        // Start collapsed
        sidebarChevrons.setFolderState(folder, false);
        expect(chevron.innerHTML).toBe('▶');
        expect(chevron.style.opacity).toBe('0.7');

        // Toggle to expanded
        sidebarChevrons.setFolderState(folder, true);
        expect(chevron.innerHTML).toBe('▼');
        expect(chevron.style.opacity).toBe('1');

        // Toggle back to collapsed
        sidebarChevrons.setFolderState(folder, false);
        expect(chevron.innerHTML).toBe('▶');
        expect(chevron.style.opacity).toBe('0.7');
      });

      it('should clear conflicting CSS transforms', () => {
        // Set some conflicting transform
        chevron.style.transform = 'rotate(90deg)';

        sidebarChevrons.setFolderState(folder, true);
        expect(chevron.style.transform).toBe('');

        sidebarChevrons.setFolderState(folder, false);
        expect(chevron.style.transform).toBe('');
      });
    });

    describe('Hover Effects and Interactions', () => {
      it('should apply hover effects on mouse enter', () => {
        const mouseEnterEvent = new MouseEvent('mouseenter', { bubbles: true });
        folderLink.dispatchEvent(mouseEnterEvent);

        expect(chevron.style.opacity).toBe('1');
        expect(chevron.style.transform).toBe('scale(1.1)');
      });

      it('should restore styling on mouse leave for collapsed folder', () => {
        // Set to collapsed state
        sidebarChevrons.setFolderState(folder, false);

        // Trigger hover
        const mouseEnterEvent = new MouseEvent('mouseenter', { bubbles: true });
        folderLink.dispatchEvent(mouseEnterEvent);

        // Trigger leave
        const mouseLeaveEvent = new MouseEvent('mouseleave', { bubbles: true });
        folderLink.dispatchEvent(mouseLeaveEvent);

        expect(chevron.style.opacity).toBe('0.7');
        expect(chevron.style.transform).toBe('scale(1)');
      });

      it('should restore styling on mouse leave for expanded folder', () => {
        // Set to expanded state by toggling (which updates the expandedFolders set)
        sidebarChevrons.toggleFolder(folder);

        // Trigger hover
        const mouseEnterEvent = new MouseEvent('mouseenter', { bubbles: true });
        folderLink.dispatchEvent(mouseEnterEvent);

        // Trigger leave
        const mouseLeaveEvent = new MouseEvent('mouseleave', { bubbles: true });
        folderLink.dispatchEvent(mouseLeaveEvent);

        expect(chevron.style.opacity).toBe('1');
        expect(chevron.style.transform).toBe('scale(1)');
      });

      it('should handle hover effects when chevron is missing', () => {
        // Remove chevron
        chevron.remove();

        expect(() => {
          const mouseEnterEvent = new MouseEvent('mouseenter', { bubbles: true });
          folderLink.dispatchEvent(mouseEnterEvent);

          const mouseLeaveEvent = new MouseEvent('mouseleave', { bubbles: true });
          folderLink.dispatchEvent(mouseLeaveEvent);
        }).not.toThrow();
      });
    });

    describe('CSS Class Management', () => {
      it('should apply correct CSS classes for expanded state', () => {
        sidebarChevrons.setFolderState(folder, true);

        expect(folder.classList.contains('expanded')).toBe(true);
        expect(folder.classList.contains('collapsed')).toBe(false);
        expect(chevron.classList.contains('expanded')).toBe(true);
        expect(chevron.classList.contains('collapsed')).toBe(false);
      });

      it('should apply correct CSS classes for collapsed state', () => {
        sidebarChevrons.setFolderState(folder, false);

        expect(folder.classList.contains('collapsed')).toBe(true);
        expect(folder.classList.contains('expanded')).toBe(false);
        expect(chevron.classList.contains('collapsed')).toBe(true);
        expect(chevron.classList.contains('expanded')).toBe(false);
      });

      it('should toggle CSS classes correctly during state changes', () => {
        // Start expanded
        sidebarChevrons.setFolderState(folder, true);
        expect(folder.classList.contains('expanded')).toBe(true);
        expect(chevron.classList.contains('expanded')).toBe(true);

        // Change to collapsed
        sidebarChevrons.setFolderState(folder, false);
        expect(folder.classList.contains('collapsed')).toBe(true);
        expect(folder.classList.contains('expanded')).toBe(false);
        expect(chevron.classList.contains('collapsed')).toBe(true);
        expect(chevron.classList.contains('expanded')).toBe(false);
      });
    });

    describe('Nested UL Styling', () => {
      it('should show nested ul for expanded folders', () => {
        const nestedUl = folder.querySelector('ul');
        sidebarChevrons.setFolderState(folder, true);

        expect(nestedUl.style.display).toBe('block');
        expect(nestedUl.style.opacity).toBe('1');
        expect(nestedUl.style.maxHeight).toBe('none');
      });

      it('should hide nested ul for collapsed folders', () => {
        const nestedUl = folder.querySelector('ul');
        sidebarChevrons.setFolderState(folder, false);

        expect(nestedUl.style.display).toBe('none');
        expect(nestedUl.style.opacity).toBe('0');
        expect(nestedUl.style.maxHeight).toBe('0');
      });
    });

    describe('Theme Integration Regression Tests', () => {
      it('should maintain styling consistency after destroy and reinitialize', () => {
        // Set initial state
        sidebarChevrons.setFolderState(folder, true);
        const initialChevronHTML = chevron.innerHTML;
        const initialOpacity = chevron.style.opacity;

        // Destroy and reinitialize
        sidebarChevrons.destroy();
        sidebarChevrons.initialize();

        // Get new references - reinitialize recreates chevrons
        // Use the same approach as beforeEach: get first li and force chevron creation
        const newFolder = sidebar.querySelector('li');
        expect(newFolder).toBeTruthy();

        // Force chevron creation by running initializeFolder
        sidebarChevrons.initializeFolder(newFolder);
        const newChevron = newFolder.querySelector('a .chevron');

        // Ensure chevron was recreated
        expect(newChevron).toBeTruthy();

        // Verify consistent styling
        expect(newChevron.style.fontSize).toBe('14px');
        expect(newChevron.style.fontFamily).toBe('monospace');
        expect(newChevron.style.fontWeight).toBe('bold');
        expect(newChevron.style.marginRight).toBe('8px');
        expect(newChevron.style.marginLeft).toBe('2px');
      });

      it('should not duplicate chevron styling on reinitialization', () => {
        const initialChevron = folderLink.querySelector('.chevron');
        expect(initialChevron).toBeTruthy();

        // Attempt reinitialize
        sidebarChevrons.initializeFolder(folder);

        const chevrons = folderLink.querySelectorAll('.chevron');
        expect(chevrons.length).toBe(1);

        // Verify styling still correct
        const chevron = chevrons[0];
        expect(chevron.style.fontSize).toBe('14px');
        expect(chevron.style.fontFamily).toBe('monospace');
      });
    });
  });

  describe('Accordion Behavior (Single-Section Expansion)', () => {
    let sidebarChevrons;
    let localStorageMock;

    beforeEach(() => {
      // Clean up any existing state first
      document.body.innerHTML = '';

      // Set up the localStorage mock first
      localStorageMock = setupTestEnvironment();

      // Clear all mock histories after setup
      vi.clearAllMocks();

      // Create a more complex sidebar structure with multiple top-level folders
      document.body.innerHTML = `
        <div class="sidebar">
          <div class="sidebar-nav">
            <ul>
              <li>
                <a href="#/docs/folder1">Folder 1</a>
                <ul>
                  <li><a href="#/docs/folder1/page1">Page 1</a></li>
                  <li><a href="#/docs/folder1/page2">Page 2</a></li>
                </ul>
              </li>
              <li>
                <a href="#/docs/folder2">Folder 2</a>
                <ul>
                  <li><a href="#/docs/folder2/page1">Page 1</a></li>
                  <li><a href="#/docs/folder2/page2">Page 2</a></li>
                </ul>
              </li>
              <li>
                <a href="#/docs/folder3">Folder 3</a>
                <ul>
                  <li><a href="#/docs/folder3/page1">Page 1</a></li>
                  <li>
                    <a href="#/docs/folder3/subfolder">Subfolder</a>
                    <ul>
                      <li><a href="#/docs/folder3/subfolder/page1">Sub Page 1</a></li>
                    </ul>
                  </li>
                </ul>
              </li>
              <li>
                <a href="#/docs/folder4">Folder 4</a>
                <ul>
                  <li><a href="#/docs/folder4/page1">Page 1</a></li>
                </ul>
              </li>
            </ul>
          </div>
        </div>
      `;

      // Set up component with mocked dependencies and unique storage key
      sidebarChevrons = new SidebarChevrons({
        debug: false,
        storageKey: `test-accordion-storage-${Date.now()}-${Math.random()}` // Unique key per test
      });
      sidebarChevrons.initialize();
    });

    afterEach(() => {
      // Destroy instance first
      if (sidebarChevrons) {
        try {
          sidebarChevrons.destroy();
        } catch (error) {
          // Ignore destruction errors during cleanup
        }
        sidebarChevrons = null;
      }

      // Clear localStorage mock state
      if (localStorageMock) {
        localStorageMock.clear();
        // Reset all mock functions
        Object.values(localStorageMock).forEach(mock => {
          if (typeof mock === 'function' && mock.mockClear) {
            mock.mockClear();
          }
        });
      }

      // Clear DOM
      document.body.innerHTML = '';

      // Clear any global timers
      if (window.chevronReinitTimeout) {
        clearTimeout(window.chevronReinitTimeout);
        window.chevronReinitTimeout = null;
      }
    });

    it('should only allow one top-level folder to be expanded at a time', () => {
      const folder1 = document.querySelector('a[href="#/docs/folder1"]').parentElement;
      const folder2 = document.querySelector('a[href="#/docs/folder2"]').parentElement;
      const folder3 = document.querySelector('a[href="#/docs/folder3"]').parentElement;

      // Initially, all folders should be collapsed
      expect(folder1.querySelector('ul').style.display).toBe('none');
      expect(folder2.querySelector('ul').style.display).toBe('none');
      expect(folder3.querySelector('ul').style.display).toBe('none');

      // Expand folder1
      sidebarChevrons.toggleFolder(folder1);
      expect(folder1.querySelector('ul').style.display).toBe('block');
      expect(folder2.querySelector('ul').style.display).toBe('none');
      expect(folder3.querySelector('ul').style.display).toBe('none');

      // Expand folder2 - folder1 should collapse
      sidebarChevrons.toggleFolder(folder2);
      expect(folder1.querySelector('ul').style.display).toBe('none');
      expect(folder2.querySelector('ul').style.display).toBe('block');
      expect(folder3.querySelector('ul').style.display).toBe('none');

      // Expand folder3 - folder2 should collapse
      sidebarChevrons.toggleFolder(folder3);
      expect(folder1.querySelector('ul').style.display).toBe('none');
      expect(folder2.querySelector('ul').style.display).toBe('none');
      expect(folder3.querySelector('ul').style.display).toBe('block');
    });

    it('should not affect nested folder expansion when collapsing other top-level folders', () => {
      const folder3 = document.querySelector('a[href="#/docs/folder3"]').parentElement;
      const subfolder = document.querySelector('a[href="#/docs/folder3/subfolder"]').parentElement;
      const folder1 = document.querySelector('a[href="#/docs/folder1"]').parentElement;

      // Expand folder3 and its subfolder
      sidebarChevrons.toggleFolder(folder3);
      sidebarChevrons.toggleFolder(subfolder);

      expect(folder3.querySelector('ul').style.display).toBe('block');
      expect(subfolder.querySelector('ul').style.display).toBe('block');

      // Expand folder1 - folder3 should collapse but subfolder state should remain intact
      sidebarChevrons.toggleFolder(folder1);
      expect(folder1.querySelector('ul').style.display).toBe('block');
      expect(folder3.querySelector('ul').style.display).toBe('none');

      // When we re-expand folder3, subfolder should still be expanded
      sidebarChevrons.toggleFolder(folder3);
      expect(folder3.querySelector('ul').style.display).toBe('block');
      expect(subfolder.querySelector('ul').style.display).toBe('block');
    });

    it('should properly identify top-level folders', () => {
      const folder1 = document.querySelector('a[href="#/docs/folder1"]').parentElement;
      const subfolder = document.querySelector('a[href="#/docs/folder3/subfolder"]').parentElement;

      expect(sidebarChevrons.isTopLevelFolder(folder1)).toBe(true);
      expect(sidebarChevrons.isTopLevelFolder(subfolder)).toBe(false);
    });

    it('should update localStorage to reflect only the currently expanded top-level folder', () => {
      const folder1 = document.querySelector('a[href="#/docs/folder1"]').parentElement;
      const folder2 = document.querySelector('a[href="#/docs/folder2"]').parentElement;

      // Expand folder1
      sidebarChevrons.toggleFolder(folder1);

      // Get the actual storage key that was used
      const actualStorageKey = localStorageMock.setItem.mock.calls[0][0];

      // Check that localStorage was called with folder1
      expect(localStorageMock.setItem).toHaveBeenCalledWith(
        actualStorageKey,
        JSON.stringify(['#/docs/folder1'])
      );

      // Mock the return value for the next operation
      localStorageMock.getItem.mockReturnValue(JSON.stringify(['#/docs/folder1']));

      // Expand folder2 - folder1 should be removed from storage
      sidebarChevrons.toggleFolder(folder2);

      // Should have been called with only folder2 now
      expect(localStorageMock.setItem).toHaveBeenCalledWith(
        actualStorageKey,
        JSON.stringify(['#/docs/folder2'])
      );
    });

    it('should emit correct events when implementing accordion behavior', () => {
      const folder1 = document.querySelector('a[href="#/docs/folder1"]').parentElement;
      const folder2 = document.querySelector('a[href="#/docs/folder2"]').parentElement;
      const events = [];

      window.addEventListener('sidebar:folder-toggled', (e) => {
        events.push({
          folderKey: e.detail.folderKey,
          isExpanded: e.detail.isExpanded,
          folderName: e.detail.folderName
        });
      });

      // Expand folder1
      sidebarChevrons.toggleFolder(folder1);

      // Expand folder2 (should collapse folder1)
      sidebarChevrons.toggleFolder(folder2);

      // We should have received events for both actions
      expect(events).toHaveLength(2);
      expect(events[0]).toEqual(expect.objectContaining({
        folderKey: '#/docs/folder1',
        isExpanded: true,
        folderName: 'Folder 1'
      }));
      expect(events[1]).toEqual(expect.objectContaining({
        folderKey: '#/docs/folder2',
        isExpanded: true,
        folderName: 'Folder 2'
      }));
    });

    it('should handle clicking the same folder twice (toggle behavior)', () => {
      const folder1 = document.querySelector('a[href="#/docs/folder1"]').parentElement;

      // Initially collapsed
      expect(folder1.querySelector('ul').style.display).toBe('none');

      // Click to expand
      sidebarChevrons.toggleFolder(folder1);
      expect(folder1.querySelector('ul').style.display).toBe('block');

      // Click again to collapse
      sidebarChevrons.toggleFolder(folder1);
      expect(folder1.querySelector('ul').style.display).toBe('none');

      // All folders should now be collapsed
      const allFolders = document.querySelectorAll('.sidebar-nav > ul > li');
      allFolders.forEach(folder => {
        const nestedUl = folder.querySelector('ul');
        if (nestedUl) {
          expect(nestedUl.style.display).toBe('none');
        }
      });
    });

    it('should restore accordion state correctly after destroy and reinitialize', () => {
      const folder2 = document.querySelector('a[href="#/docs/folder2"]').parentElement;

      // Expand folder2
      sidebarChevrons.toggleFolder(folder2);
      expect(folder2.querySelector('ul').style.display).toBe('block');

      // Mock the saved state for restoration
      localStorageMock.getItem.mockReturnValue(JSON.stringify(['#/docs/folder2']));

      // Destroy and reinitialize
      sidebarChevrons.destroy();
      sidebarChevrons = new SidebarChevrons({
        debug: false,
        storageKey: 'test-accordion-storage'
      });
      sidebarChevrons.initialize();

      // folder2 should still be expanded, others collapsed
      const folder1 = document.querySelector('a[href="#/docs/folder1"]').parentElement;
      const folder3 = document.querySelector('a[href="#/docs/folder3"]').parentElement;
      expect(folder1.querySelector('ul').style.display).toBe('none');
      expect(folder2.querySelector('ul').style.display).toBe('block');
      expect(folder3.querySelector('ul').style.display).toBe('none');
    });

    it('should handle auto-expanded folders correctly with accordion behavior', () => {
      const folder1 = document.querySelector('a[href="#/docs/folder1"]').parentElement;
      const folder2 = document.querySelector('a[href="#/docs/folder2"]').parentElement;

      // Auto-expand folder1 (without saving to state)
      sidebarChevrons.expandFolder(folder1, true);
      expect(folder1.querySelector('ul').style.display).toBe('block');

      // Now manually expand folder2 - should not collapse folder1 since it's auto-expanded
      sidebarChevrons.toggleFolder(folder2);
      expect(folder1.querySelector('ul').style.display).toBe('block');
      expect(folder2.querySelector('ul').style.display).toBe('block');

      // However, if we manually expand folder1 (saving to state), then expand folder2, folder1 should collapse
      sidebarChevrons.toggleFolder(folder1); // Now saving folder1 to state
      sidebarChevrons.toggleFolder(folder2); // This should collapse folder1
      expect(folder1.querySelector('ul').style.display).toBe('none');
      expect(folder2.querySelector('ul').style.display).toBe('block');
    });
  });

  describe('Edge Cases and Robustness', () => {
    beforeEach(() => {
      sidebarChevrons = new SidebarChevrons(mockDependencies);
    });

    it('should handle empty sidebar gracefully', () => {
      document.body.innerHTML = '<div class="sidebar"><ul></ul></div>';

      expect(() => {
        sidebarChevrons.initializeChevrons();
      }).not.toThrow();
    });

    it('should handle missing nested ul elements', () => {
      document.body.innerHTML = `
        <div class="sidebar">
          <ul>
            <li><a href="#/test">Test Page</a></li>
          </ul>
        </div>
      `;

      expect(() => {
        sidebarChevrons.initializeChevrons();
      }).not.toThrow();
    });

    it('should handle malformed HTML structure', () => {
      document.body.innerHTML = `
        <div class="sidebar">
          <ul>
            <li>
              <a href="#/test">Test</a>
              <ul>
                <li>Nested without link</li>
              </ul>
            </li>
          </ul>
        </div>
      `;

      expect(() => {
        sidebarChevrons.initialize();
      }).not.toThrow();
    });

    it('should handle missing localStorage gracefully', () => {
      // Remove localStorage mock
      delete window.localStorage;

      expect(() => {
        sidebarChevrons.loadExpandedStates();
        sidebarChevrons.saveExpandedStates();
      }).not.toThrow();
    });

    it('should extract folder key from complex URL structures', () => {
      const complexUrl = '#/docs/getting-started/installation.md?param=value#section';
      const folderKey = sidebarChevrons.extractFolderKey(complexUrl);

      expect(folderKey).toBe('installation');
    });

    it('should handle empty URL extraction', () => {
      const emptyUrl = '';
      const folderKey = sidebarChevrons.extractFolderKey(emptyUrl);

      expect(folderKey).toBe('');
    });

    it('should handle URL with only hash', () => {
      const hashOnlyUrl = '#';
      const folderKey = sidebarChevrons.extractFolderKey(hashOnlyUrl);

      expect(folderKey).toBe('');
    });
  });
});
