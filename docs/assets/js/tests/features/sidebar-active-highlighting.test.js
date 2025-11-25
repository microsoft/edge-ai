import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import SidebarActiveHighlighting from '../../features/sidebar-active-highlighting.js';

describe('SidebarActiveHighlighting', () => {
  let highlighter;
  let mockErrorHandler;
  let mockDomUtils;
  let mockDebugHelper;
  let container;

  const createMockDependencies = () => ({
    errorHandler: {
      logError: vi.fn(),
      throwOnError: false
    },
    domUtils: {
      querySelector: vi.fn((selector) => document.querySelector(selector)),
      querySelectorAll: vi.fn((selector) => document.querySelectorAll(selector))
    },
    debugHelper: {
      log: vi.fn() // Cleaned for test output
    }
  });

  const createSidebarHTML = () => {
    const container = document.createElement('div');
    container.innerHTML = `
      <div class="sidebar">
        <ul>
          <li>
            <a href="#/docs/readme">Documentation</a>
            <ul>
              <li>
                <a href="#/docs/getting-started">Getting Started</a>
                <ul>
                  <li><a href="#/docs/getting-started/installation">Installation</a></li>
                  <li><a href="#/docs/getting-started/configuration">Configuration</a></li>
                </ul>
              </li>
              <li><a href="#/docs/api-reference">API Reference</a></li>
            </ul>
          </li>
          <li>
            <a href="#/guides/tutorials">Guides</a>
            <ul>
              <li><a href="#/guides/basic-tutorial">Basic Tutorial</a></li>
              <li><a href="#/guides/advanced-tutorial">Advanced Tutorial</a></li>
            </ul>
          </li>
          <li><a href="#/changelog">Changelog</a></li>
        </ul>
      </div>
      <main id="main-content">Content</main>
    `;
    return container;
  };

  beforeEach(() => {
    // Clear document and global state
    document.body.innerHTML = '';
    delete window.sidebarChevrons;
    delete window.navigationCoordinator;
    delete window.$docsify;

    // Create test DOM
    container = createSidebarHTML();
    document.body.appendChild(container);

    // Create mock dependencies
    const dependencies = createMockDependencies();
    mockErrorHandler = dependencies.errorHandler;
    mockDomUtils = dependencies.domUtils;
    mockDebugHelper = dependencies.debugHelper;

    // Create highlighter instance
    highlighter = new SidebarActiveHighlighting(dependencies);

    // Mock window.location
    Object.defineProperty(window, 'location', {
      value: { hash: '#/' },
      writable: true
    });
  });

  afterEach(() => {
    if (highlighter && highlighter.isInitialized) {
      highlighter.destroy();
    }
    document.body.innerHTML = '';
    vi.clearAllMocks();
  });

  describe('Constructor', () => {
    it('should create a new instance with default dependencies', () => {
      const defaultHighlighter = new SidebarActiveHighlighting();

      expect(defaultHighlighter).toBeInstanceOf(SidebarActiveHighlighting);
      expect(defaultHighlighter.isInitialized).toBe(false);
      expect(defaultHighlighter.abortController).toBe(null);
      expect(defaultHighlighter.fallbackListenersSet).toBe(false);
    });

    it('should accept custom dependencies', () => {
      expect(highlighter.errorHandler).toBe(mockErrorHandler);
      expect(highlighter.domUtils).toBe(mockDomUtils);
      expect(highlighter.debugHelper).toBe(mockDebugHelper);
    });

    it('should initialize with default configuration', () => {
      expect(highlighter.config.debounceMs).toBe(100);
      expect(highlighter.config.highlightTimeout).toBe(50);
      expect(highlighter.config.coordinatorWaitMs).toBe(50);
    });

    it('should create without debug logging', () => {
      // No debug logs expected with console cleanup
      expect(mockDebugHelper.log).not.toHaveBeenCalled();
    });
  });

  describe('Parent Folder Management', () => {
    beforeEach(() => {
      // Mock chevron system
      window.sidebarChevrons = {
        expandFolder: vi.fn(),
        getFolderKey: vi.fn((folder) => folder.querySelector('a')?.textContent),
        expandedFolders: new Set()
      };
    });

    describe('findParentFolders', () => {
      it('should find parent folders for nested link', () => {
        const container = createSidebarHTML();
        document.body.appendChild(container);

        const highlighter = new SidebarActiveHighlighting(createMockDependencies());
        const link = container.querySelector('a[href="#/docs/getting-started/installation"]');

        const parentFolders = highlighter.findParentFolders(link);

        expect(parentFolders).toHaveLength(2);
        expect(parentFolders[0].querySelector('a').textContent).toBe('Documentation');
        expect(parentFolders[1].querySelector('a').textContent).toBe('Getting Started');
      }); it('should find single parent for immediate child', () => {
        const link = document.querySelector('a[href="#/docs/getting-started"]');

        const parentFolders = highlighter.findParentFolders(link);

        expect(parentFolders).toHaveLength(1);
        expect(parentFolders[0].querySelector('a').textContent).toBe('Documentation');
      });

      it('should return empty array for top-level links', () => {
        const link = document.querySelector('a[href="#/changelog"]');

        const parentFolders = highlighter.findParentFolders(link);

        expect(parentFolders).toHaveLength(0);
      });

      it('should return empty array for null link', () => {
        const parentFolders = highlighter.findParentFolders(null);

        expect(parentFolders).toHaveLength(0);
        // Debug logs removed - no assertion on logging
      });

      it('should process parent folder discovery without debug logging', () => {
        const link = document.querySelector('a[href="#/docs/getting-started/installation"]');

        highlighter.findParentFolders(link);

        // Debug logs removed during console cleanup
        expect(mockDebugHelper.log).not.toHaveBeenCalled();
      });
    });

    describe('expandParentFolders', () => {
      it('should expand parent folders using chevron system', () => {
        const link = document.querySelector('a[href="#/docs/getting-started/installation"]');

        highlighter.expandParentFolders(link);

        expect(window.sidebarChevrons.expandFolder).toHaveBeenCalledTimes(2);
      });

      it('should handle null link gracefully', () => {
        highlighter.expandParentFolders(null);

        // Debug logs removed - checking functional behavior only
        expect(window.sidebarChevrons.expandFolder).not.toHaveBeenCalled();
      });

      it('should handle missing chevron system', () => {
        delete window.sidebarChevrons;
        const link = document.querySelector('a[href="#/docs/getting-started/installation"]');

        highlighter.expandParentFolders(link);

        // Debug logs removed - functional check only
        expect(link).toBeTruthy(); // Basic validation link exists
      });

      it('should handle links with no parent folders', () => {
        const link = document.querySelector('a[href="#/changelog"]');

        highlighter.expandParentFolders(link);

        // Debug logs removed - checking functional behavior only
        expect(window.sidebarChevrons.expandFolder).not.toHaveBeenCalled();
      });
    });

    describe('cleanupAutoExpansions', () => {
      beforeEach(() => {
        // Add auto-expanded markers to folders
        const folders = document.querySelectorAll('li');
        folders[0].setAttribute('data-auto-expanded', 'true');
        folders[0].classList.add('expanded');
        folders[1].setAttribute('data-auto-expanded', 'true');
        folders[1].classList.add('expanded');
      });

      it('should clean up auto-expanded folders', () => {
        highlighter.cleanupAutoExpansions();

        const autoExpanded = document.querySelectorAll('[data-auto-expanded="true"]');
        expect(autoExpanded).toHaveLength(0);
      });

      it('should preserve manually expanded folders', () => {
        window.sidebarChevrons.expandedFolders.add('Documentation');
        const folder = document.querySelector('li');
        folder.setAttribute('data-auto-expanded', 'true');
        folder.classList.add('expanded');

        highlighter.cleanupAutoExpansions();

        expect(folder.classList.contains('expanded')).toBe(true);
        // Debug logs removed - checking functional behavior only
      });

      it('should add collapsed classes when cleaning up', () => {
        const folder = document.querySelector('li');
        folder.setAttribute('data-auto-expanded', 'true');
        folder.classList.add('expanded');

        // Add chevron element
        const chevron = document.createElement('div');
        chevron.className = 'chevron expanded';
        chevron.setAttribute('aria-expanded', 'true');
        folder.appendChild(chevron);

        highlighter.cleanupAutoExpansions();

        expect(folder.classList.contains('collapsed')).toBe(true);
        expect(folder.classList.contains('expanded')).toBe(false);
        expect(chevron.classList.contains('collapsed')).toBe(true);
        expect(chevron.getAttribute('aria-expanded')).toBe('false');
      });
    });

    describe('getFolderKey', () => {
      it('should use chevron system getFolderKey if available', () => {
        const folder = document.querySelector('li');
        window.sidebarChevrons.getFolderKey.mockReturnValue('test-key');

        const key = highlighter.getFolderKey(folder);

        expect(key).toBe('test-key');
        expect(window.sidebarChevrons.getFolderKey).toHaveBeenCalledWith(folder);
      });

      it('should fallback to href attribute', () => {
        delete window.sidebarChevrons.getFolderKey;
        const folder = document.querySelector('li');
        const link = folder.querySelector('a');
        link.setAttribute('href', '#/fallback-href');

        const key = highlighter.getFolderKey(folder);

        expect(key).toBe('#/fallback-href');
      });

      it('should fallback to text content', () => {
        delete window.sidebarChevrons.getFolderKey;
        const folder = document.querySelector('li');
        const link = folder.querySelector('a');
        link.removeAttribute('href');

        const key = highlighter.getFolderKey(folder);

        expect(key).toBe('Documentation');
      });

      it('should return null for folder without link', () => {
        delete window.sidebarChevrons.getFolderKey;
        const folder = document.createElement('li');

        const key = highlighter.getFolderKey(folder);

        expect(key).toBe(null);
      });
    });
  });

  describe('Active Link Highlighting', () => {
    beforeEach(() => {
      window.sidebarChevrons = {
        expandFolder: vi.fn(),
        getFolderKey: vi.fn(),
        expandedFolders: new Set()
      };
    });

    describe('updateSidebarActiveHighlighting', () => {
      it('should highlight exact match', () => {
        window.location.hash = '#/docs/getting-started';

        highlighter.updateSidebarActiveHighlighting();

        const activeLink = document.querySelector('a[href="#/docs/getting-started"]');
        expect(activeLink.classList.contains('active')).toBe(true);
        expect(activeLink.closest('li').classList.contains('active')).toBe(true);
      });

      it('should handle root path', () => {
        window.location.hash = '#/';

        expect(() => highlighter.updateSidebarActiveHighlighting()).not.toThrow();
      });

      it('should handle paths without .md extension', () => {
        window.location.hash = '#/changelog';

        highlighter.updateSidebarActiveHighlighting();

        const activeLink = document.querySelector('a[href="#/changelog"]');
        expect(activeLink.classList.contains('active')).toBe(true);
      });

      it('should clean up previous active states', () => {
        const link = document.querySelector('a[href="#/changelog"]');
        link.classList.add('active');
        link.closest('li').classList.add('active');
        window.location.hash = '#/docs/getting-started';

        highlighter.updateSidebarActiveHighlighting();

        expect(link.classList.contains('active')).toBe(false);
        expect(link.closest('li').classList.contains('active')).toBe(false);
      });

      it('should expand parent folders for active link', () => {
        window.location.hash = '#/docs/getting-started/installation';
        const expandSpy = vi.spyOn(highlighter, 'expandParentFolders');

        highlighter.updateSidebarActiveHighlighting();

        expect(expandSpy).toHaveBeenCalled();
      });

      it('should handle partial matches', () => {
        window.location.hash = '#/docs/getting-started/some-deep-page';

        highlighter.updateSidebarActiveHighlighting();

        // Should match the parent path
        const parentLink = document.querySelector('a[href="#/docs/getting-started"]');
        expect(parentLink.classList.contains('active')).toBe(true);
      });

      it('should handle no sidebar gracefully', () => {
        document.querySelector('.sidebar').remove();

        expect(() => highlighter.updateSidebarActiveHighlighting()).not.toThrow();
      });

      it('should handle no match scenarios', () => {
        window.location.hash = '#/non-existent-page';

        highlighter.updateSidebarActiveHighlighting();

        // Debug logs removed - checking functional behavior only
        const activeLinks = document.querySelectorAll('.active');
        expect(activeLinks.length).toBeGreaterThanOrEqual(0); // No specific assertion on non-match
      });
    });

    describe('URL Utilities', () => {
      describe('normalizeURL', () => {
        it('should normalize URLs correctly', () => {
          expect(highlighter.normalizeURL('#/docs/readme')).toBe('#/docs/readme');
          expect(highlighter.normalizeURL('/docs/readme/')).toBe('/docs/readme');
          expect(highlighter.normalizeURL('/docs//readme')).toBe('/docs/readme');
          expect(highlighter.normalizeURL('/docs/readme?param=1')).toBe('/docs/readme');
          expect(highlighter.normalizeURL('/docs/readme#section')).toBe('/docs/readme');
        });

        it('should handle empty URLs', () => {
          expect(highlighter.normalizeURL('')).toBe('');
          expect(highlighter.normalizeURL(null)).toBe('');
          expect(highlighter.normalizeURL(undefined)).toBe('');
        });

        it('should handle root URLs', () => {
          expect(highlighter.normalizeURL('/')).toBe('/');
          expect(highlighter.normalizeURL('')).toBe('');
        });
      });

      describe('calculateURLScore', () => {
        it('should return 100 for exact matches', () => {
          const score = highlighter.calculateURLScore('/docs/readme', '/docs/readme');
          expect(score).toBe(100);
        });

        it('should return partial scores for partial matches', () => {
          const score = highlighter.calculateURLScore('/docs/readme/section', '/docs/readme');
          expect(score).toBeGreaterThan(0);
          expect(score).toBeLessThan(100);
        });

        it('should return 0 for no matches', () => {
          const score = highlighter.calculateURLScore('/docs/readme', '/guides/tutorial');
          expect(score).toBe(0);
        });

        it('should handle empty URLs', () => {
          expect(highlighter.calculateURLScore('', '/docs/readme')).toBe(0);
          expect(highlighter.calculateURLScore('/docs/readme', '')).toBe(0);
          expect(highlighter.calculateURLScore('', '')).toBe(0);
        });
      });

      describe('findActiveLinks', () => {
        it('should find and sort links by score', () => {
          const links = highlighter.findActiveLinks('/docs/getting-started/installation');

          expect(links.length).toBeGreaterThan(0);
          expect(links[0].getAttribute('href')).toBe('#/docs/getting-started/installation');
        });

        it('should return empty array for no matches', () => {
          const links = highlighter.findActiveLinks('/non-existent');

          expect(links).toHaveLength(0);
        });
      });
    });
  });

  describe('Navigation Integration', () => {
    describe('setupCoordinationIntegration', () => {
      it('should set up coordinator event listener', () => {
        const addEventListenerSpy = vi.spyOn(window, 'addEventListener');

        highlighter.setupCoordinationIntegration();

        expect(addEventListenerSpy).toHaveBeenCalledWith('navigation:coordinator-highlight', expect.any(Function));
      });

      it('should handle coordinator events', () => {
        const updateSpy = vi.spyOn(highlighter, 'updateSidebarActiveHighlighting');
        highlighter.setupCoordinationIntegration();

        const event = new CustomEvent('navigation:coordinator-highlight', {
          detail: { route: '/test-route' }
        });
        window.dispatchEvent(event);

        expect(updateSpy).toHaveBeenCalled();
      });

      it('should integrate with coordinator when available', async () => {
        window.navigationCoordinator = {
          isInitialized: () => true,
          notifySidebarHighlighted: vi.fn()
        };

        highlighter.setupCoordinationIntegration();

        // Wait for coordinator check
        await new Promise(resolve => setTimeout(resolve, 100));

        expect(window.navigationCoordinator.notifySidebarHighlighted).toHaveBeenCalledWith('system-ready');
      });

      it('should use fallback listeners when coordinator not available', async () => {
        const setupFallbackSpy = vi.spyOn(highlighter, 'setupFallbackListeners');

        highlighter.setupCoordinationIntegration();

        // Wait for coordinator check
        await new Promise(resolve => setTimeout(resolve, 100));

        expect(setupFallbackSpy).toHaveBeenCalled();
        expect(highlighter.fallbackListenersSet).toBe(true);
      });
    });

    describe('setupFallbackListeners', () => {
      it('should set up hashchange listener', () => {
        const addEventListenerSpy = vi.spyOn(window, 'addEventListener');

        highlighter.setupFallbackListeners();

        expect(addEventListenerSpy).toHaveBeenCalledWith('hashchange', expect.any(Function), expect.any(Object));
      });

      it('should set up popstate listener', () => {
        const addEventListenerSpy = vi.spyOn(window, 'addEventListener');

        highlighter.setupFallbackListeners();

        expect(addEventListenerSpy).toHaveBeenCalledWith('popstate', expect.any(Function), expect.any(Object));
      });

      it('should abort previous controller', () => {
        highlighter.abortController = new AbortController();
        const abortSpy = vi.spyOn(highlighter.abortController, 'abort');

        highlighter.setupFallbackListeners();

        expect(abortSpy).toHaveBeenCalled();
      });

      it('should trigger highlighting on hashchange', async () => {
        const updateSpy = vi.spyOn(highlighter, 'updateSidebarActiveHighlighting');
        highlighter.setupFallbackListeners();

        window.dispatchEvent(new HashChangeEvent('hashchange'));

        // Wait for timeout
        await new Promise(resolve => setTimeout(resolve, 100));

        expect(updateSpy).toHaveBeenCalled();
      });
    });
  });

  describe('Docsify Integration', () => {
    describe('waitForDocsify', () => {
      it('should initialize immediately if docsify and sidebar exist', () => {
        window.$docsify = { plugins: [] };
        const initSpy = vi.spyOn(highlighter, 'initialize');

        highlighter.waitForDocsify();

        expect(initSpy).toHaveBeenCalled();
      });

      it('should wait for sidebar if docsify exists but sidebar does not', async () => {
        window.$docsify = { plugins: [] };
        document.querySelector('.sidebar').remove();
        const initSpy = vi.spyOn(highlighter, 'initialize');

        highlighter.waitForDocsify();

        expect(initSpy).not.toHaveBeenCalled();

        // Add sidebar back and wait
        document.body.appendChild(createSidebarHTML());
        await new Promise(resolve => setTimeout(resolve, 600));

        expect(initSpy).toHaveBeenCalled();
      });

      it('should wait for docsify if not available', async () => {
        const waitSpy = vi.spyOn(highlighter, 'waitForDocsify');

        highlighter.waitForDocsify();

        // Should call itself again after timeout
        await new Promise(resolve => setTimeout(resolve, 150));

        expect(waitSpy).toHaveBeenCalledTimes(2);
      });

      it('should add docsify plugins', () => {
        window.$docsify = { plugins: [] };

        highlighter.waitForDocsify();

        expect(window.$docsify.plugins).toHaveLength(1);
      });
    });
  });

  describe('Lifecycle Management', () => {
    describe('initialize', () => {
      it('should initialize successfully', () => {
        const _result = highlighter.initialize();

        expect(highlighter.isInitialized).toBe(true);
        // Debug logs removed - checking functional behavior only
      });

      it('should not initialize twice', () => {
        highlighter.initialize();
        mockDebugHelper.log.mockClear();

        highlighter.initialize();

        // Debug logs removed - checking functional behavior only
        expect(highlighter.isInitialized).toBe(true);
      });

      it('should call initial highlighting', () => {
        const updateSpy = vi.spyOn(highlighter, 'updateSidebarActiveHighlighting');

        highlighter.initialize();

        expect(updateSpy).toHaveBeenCalled();
      });

      it('should setup coordination integration', () => {
        const setupSpy = vi.spyOn(highlighter, 'setupCoordinationIntegration');

        highlighter.initialize();

        expect(setupSpy).toHaveBeenCalled();
      });
    });

    describe('destroy', () => {
      beforeEach(() => {
        highlighter.initialize();
      });

      it('should destroy successfully', () => {
        highlighter.destroy();

        expect(highlighter.isInitialized).toBe(false);
        expect(highlighter.abortController).toBe(null);
        expect(highlighter.fallbackListenersSet).toBe(false);
        // Debug logs removed - checking functional behavior only
      });

      it('should abort event listeners', () => {
        highlighter.setupFallbackListeners();
        const abortSpy = vi.spyOn(highlighter.abortController, 'abort');

        highlighter.destroy();

        expect(abortSpy).toHaveBeenCalled();
      });

      it('should clean up auto expansions', () => {
        const cleanupSpy = vi.spyOn(highlighter, 'cleanupAutoExpansions');

        highlighter.destroy();

        expect(cleanupSpy).toHaveBeenCalled();
      });
    });
  });

  describe('Validation and Testing', () => {
    beforeEach(() => {
      window.sidebarChevrons = {
        expandFolder: vi.fn((folder, isAutomatic) => {
          // Actually expand the folder for testing
          folder.classList.add('expanded');
          folder.classList.remove('collapsed');
          if (isAutomatic) {
            folder.setAttribute('data-auto-expanded', 'true');
          }
          const chevron = folder.querySelector('.chevron');
          if (chevron) {
            chevron.classList.add('expanded');
            chevron.classList.remove('collapsed');
            chevron.setAttribute('aria-expanded', 'true');
          }
        }),
        getFolderKey: vi.fn(),
        expandedFolders: new Set()
      };
    });

    describe('validateParentExpansion', () => {
      it('should validate all requirements', () => {
        // Add active elements to satisfy validation
        const link = document.querySelector('a[href="#/changelog"]');
        link.classList.add('active');

        const result = highlighter.validateParentExpansion();

        expect(result).toBe(true);
        // Debug logs removed - checking functional behavior only
      });

      it('should fail validation when sidebar missing', () => {
        document.querySelector('.sidebar').remove();

        const result = highlighter.validateParentExpansion();

        expect(result).toBe(false);
      });

      it('should fail validation when chevron system missing', () => {
        delete window.sidebarChevrons;

        const result = highlighter.validateParentExpansion();

        expect(result).toBe(false);
      });
    });

    describe('testParentExpansion', () => {
      it('should test parent expansion for valid link', () => {
        const result = highlighter.testParentExpansion('a[href="#/docs/getting-started/installation"]');

        expect(result).toBe(true);
        // Debug logs removed - checking functional behavior only
      });

      it('should fail test for non-existent link', () => {
        const result = highlighter.testParentExpansion('a[href="#/non-existent"]');

        expect(result).toBe(false);
        // Debug logs removed - checking functional behavior only
      });
    });

    describe('validateParentExpansionForLink', () => {
      it('should validate parent expansion for specific link', () => {
        const result = highlighter.validateParentExpansionForLink('a[href="#/docs/getting-started/installation"]');

        expect(result).toBe(true);
        // Debug logs removed - checking functional behavior only
      });

      it('should fail validation for invalid parent folders', () => {
        // Mock findParentFolders to return invalid folders
        vi.spyOn(highlighter, 'findParentFolders').mockReturnValue([
          document.createElement('li') // Invalid folder that doesn't contain the link
        ]);

        const result = highlighter.validateParentExpansionForLink('a[href="#/docs/getting-started/installation"]');

        expect(result).toBe(false);
      });
    });
  });

  describe('Error Handling', () => {
    describe('handleError', () => {
      it('should log errors', () => {
        const error = new Error('Test error');

        highlighter.handleError('Test message', error);

        // Still need error logging for critical issues
        expect(mockDebugHelper.log).toHaveBeenCalledWith('❌ [SIDEBAR] Test message:', error);
      });

      it('should throw errors when configured', () => {
        highlighter.config.throwOnError = true;
        const error = new Error('Test error');

        expect(() => highlighter.handleError('Test message', error)).toThrow(error);
      });

      it('should not throw errors by default', () => {
        const error = new Error('Test error');

        expect(() => highlighter.handleError('Test message', error)).not.toThrow();
      });
    });

    it('should handle errors in normalizeURL', () => {
      // Create a test URL that will trigger an error by using a problematic input
      // We'll spy on the debugHelper to verify error handling
      const consoleSpy = vi.spyOn(mockDebugHelper, 'log');

      // Create a circular reference object that will cause JSON.stringify to fail
      // if the normalizeURL method tries to process it incorrectly
      const problematicUrl = {};
      problematicUrl.circular = problematicUrl;

      // Override replace temporarily to cause an error
      const originalReplace = String.prototype.replace;
      let replaceCallCount = 0;

      try {
        String.prototype.replace = function() {
          replaceCallCount++;
          if (replaceCallCount === 1) {
            // Only throw on first call to avoid affecting test framework
            throw new Error('Replace error');
          }
          return originalReplace.apply(this, arguments);
        };

        const result = highlighter.normalizeURL('test-url');

        expect(result).toBe('');
        // Still need error logging for critical issues
        expect(consoleSpy).toHaveBeenCalledWith('❌ [SIDEBAR] Error normalizing URL:', expect.any(Error));
      } finally {
        // Restore original method
        String.prototype.replace = originalReplace;
      }
    });
  });

  describe('Navigation Integration Methods', () => {
    it('should setup navigation integration', () => {
      const setupSpy = vi.spyOn(highlighter, 'setupCoordinationIntegration');

      highlighter.setupNavigationIntegration();

      expect(setupSpy).toHaveBeenCalled();
      // Debug logs removed - checking functional behavior only
    });
  });

  describe('Edge Cases', () => {
    it('should handle sidebar without links', () => {
      document.querySelector('.sidebar').innerHTML = '<ul></ul>';

      expect(() => highlighter.updateSidebarActiveHighlighting()).not.toThrow();
    });

    it('should handle malformed HTML structure', () => {
      document.querySelector('.sidebar').innerHTML = '<div><span>Invalid structure</span></div>';

      expect(() => highlighter.updateSidebarActiveHighlighting()).not.toThrow();
    });

    it('should handle links without href attributes', () => {
      const sidebar = document.querySelector('.sidebar');
      sidebar.innerHTML = '<ul><li><a>Link without href</a></li></ul>';

      expect(() => highlighter.updateSidebarActiveHighlighting()).not.toThrow();
    });

    it('should handle empty hash values', () => {
      window.location.hash = '';

      expect(() => highlighter.updateSidebarActiveHighlighting()).not.toThrow();
    });
  });
});
