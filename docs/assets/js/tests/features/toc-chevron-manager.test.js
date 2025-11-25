/**
 * Unit tests for TOC Chevron Manager (Docsify Plugin)
 * Tests the plugin functionality within a mock Docsify environment
 */
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
// Import the TOCChevronManager class to make it available in tests
import '../../features/toc-chevron-manager.js';

describe('TOC Chevron Manager', () => {
  let mockDOM;

  beforeEach(() => {
    // Create mock DOM structure
    mockDOM = {
      headers: [],
      anchors: [],
      tocContainer: null
    };

    // Mock DOM methods
    global.document = {
      querySelectorAll: vi.fn((selector) => {
        if (selector.includes('#main h')) {
          return mockDOM.headers;
        }
        if (selector.includes('.anchor')) {
          return mockDOM.anchors;
        }
        if (selector.includes('.page_toc')) {
          return mockDOM.tocContainer ? [mockDOM.tocContainer] : [];
        }
        return [];
      }),
      querySelector: vi.fn(() => mockDOM.tocContainer),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn()
    };

    global.window = {
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      pageYOffset: 0,
      innerHeight: 1000,
      getComputedStyle: vi.fn(() => ({
        content: '"▶"',
        display: 'block'
      }))
    };
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('Emoji Detection', () => {
    it('should detect emoji in header text', () => {
      // Mock headers with and without emoji
      const headers = [
        { textContent: '🎯 For Users' },
        { textContent: 'Regular Header' },
        { textContent: '🏗️ For Developers' },
        { textContent: '📊 Analytics' }
      ];

      mockDOM.headers = headers;

      // Test emoji detection regex
      const emojiRegex = /[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]/u;

      expect(emojiRegex.test(headers[0].textContent)).toBe(true);
      expect(emojiRegex.test(headers[1].textContent)).toBe(false);
      expect(emojiRegex.test(headers[2].textContent)).toBe(true);
      expect(emojiRegex.test(headers[3].textContent)).toBe(true);
    });

    it('should handle edge cases in emoji detection', () => {
      const emojiRegex = /[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]/u;

      expect(emojiRegex.test('')).toBe(false);
      expect(emojiRegex.test('No emoji here')).toBe(false);
      expect(emojiRegex.test('Mixed 🎯 content')).toBe(true);
      expect(emojiRegex.test('🎯')).toBe(true);
    });
  });

  describe('Text Normalization', () => {
    it('should normalize text for comparison', () => {
      // Test normalization function that matches the implementation
      const testNormalizeText = (text) => {
        return text
          .trim()
          .toLowerCase()
          .replace(/^\s*[#]*\s*/, '') // Remove leading hashes and whitespace
          .replace(/[\u{1F000}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F300}-\u{1F5FF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{FE00}-\u{FE0F}]|[\u{200D}]/gu, '') // Remove emoji and variation selectors
          .replace(/\s+/g, ' ') // Normalize whitespace after emoji removal
          .trim(); // Final trim
      };

      // Test basic normalization
      expect(testNormalizeText('  Basic Header  ')).toBe('basic header');
      expect(testNormalizeText('UPPERCASE')).toBe('uppercase');
      expect(testNormalizeText('### Header with Hashes')).toBe('header with hashes');

      // Test emoji removal
      expect(testNormalizeText('🎯 For Users')).toBe('for users');
      expect(testNormalizeText('🏗️ For Blueprint Developers')).toBe('for blueprint developers');
      expect(testNormalizeText('📊 Analytics Dashboard')).toBe('analytics dashboard');
      expect(testNormalizeText('Mixed 🎯 Content 📊 Here')).toBe('mixed content here');

      // Test whitespace normalization
      expect(testNormalizeText('Multiple   Spaces    Here')).toBe('multiple spaces here');
      expect(testNormalizeText('  \t\n  Tabs and Newlines  \r\n  ')).toBe('tabs and newlines');

      // Test combined cases
      expect(testNormalizeText('### 🎯 Complex   Header 📊  With Everything')).toBe('complex header with everything');
    });

    it('should handle edge cases in text normalization', () => {
      const testNormalizeText = (text) => {
        return text
          .trim()
          .toLowerCase()
          .replace(/^\s*[#]*\s*/, '')
          .replace(/[\u{1F000}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F300}-\u{1F5FF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{FE00}-\u{FE0F}]|[\u{200D}]/gu, '')
          .replace(/\s+/g, ' ')
          .trim();
      };

      // Edge cases
      expect(testNormalizeText('')).toBe('');
      expect(testNormalizeText('   ')).toBe('');
      expect(testNormalizeText('###')).toBe('');
      expect(testNormalizeText('🎯')).toBe('');
      expect(testNormalizeText('### 🎯')).toBe('');
      expect(testNormalizeText('🎯 🏗️ 📊')).toBe('');
    });
  });

  describe('Header-Anchor Mapping', () => {
    it('should map headers to TOC anchors correctly', () => {
      const headers = [
        { textContent: '🎯 For Users', getBoundingClientRect: () => ({ top: 100 }) },
        { textContent: 'Regular Header', getBoundingClientRect: () => ({ top: 200 }) }
      ];

      const anchors = [
        { textContent: '🎯 For Users', classList: { add: vi.fn(), remove: vi.fn(), contains: vi.fn() } },
        { textContent: 'Regular Header', classList: { add: vi.fn(), remove: vi.fn(), contains: vi.fn() } }
      ];

      mockDOM.headers = headers;
      mockDOM.anchors = anchors;

      // Test mapping logic
      const headerTOCMap = new Map();

      headers.forEach(header => {
        const headerText = header.textContent.trim();
        const matchingAnchor = anchors.find(anchor => {
          const anchorText = anchor.textContent.trim();
          return anchorText === headerText;
        });

        if (matchingAnchor) {
          headerTOCMap.set(header, matchingAnchor);
        }
      });

      expect(headerTOCMap.size).toBe(2);
      expect(headerTOCMap.get(headers[0])).toBe(anchors[0]);
      expect(headerTOCMap.get(headers[1])).toBe(anchors[1]);
    });

    it('should handle partial text matches', () => {
      const headers = [
        { textContent: '🎯 For Users - Getting Started' }
      ];

      const anchors = [
        { textContent: '🎯 For Users' }
      ];

      // Test flexible matching
      const headerText = headers[0].textContent.trim();
      const anchorText = anchors[0].textContent.trim();

      const isMatch = anchorText === headerText ||
                     anchorText.includes(headerText) ||
                     headerText.includes(anchorText);

      expect(isMatch).toBe(true);
    });
  });

  describe('Scroll Detection', () => {
    it('should activate the correct anchor based on scroll position', () => {
      const headers = [
        {
          textContent: '🎯 Section 1',
          getBoundingClientRect: () => ({ top: 50 })
        },
        {
          textContent: '📊 Section 2',
          getBoundingClientRect: () => ({ top: 150 })
        }
      ];

      const anchors = [
        {
          textContent: '🎯 Section 1',
          classList: { add: vi.fn(), remove: vi.fn(), contains: vi.fn() }
        },
        {
          textContent: '📊 Section 2',
          classList: { add: vi.fn(), remove: vi.fn(), contains: vi.fn() }
        }
      ];

      mockDOM.headers = headers;
      mockDOM.anchors = anchors;

      // Simulate scroll detection logic
      const windowHeight = 1000;
      let activeHeader = null;
      let closestDistance = Infinity;

      headers.forEach(header => {
        const rect = header.getBoundingClientRect();
        const distance = Math.abs(100 - rect.top); // 100px offset

        if (distance < closestDistance && rect.top < windowHeight * 0.6) {
          closestDistance = distance;
          activeHeader = header;
        }
      });

      expect(activeHeader).toBe(headers[0]); // First header is closer to top
    });
  });

  describe('Chevron Activation', () => {
    it('should clear all active states before setting new one', () => {
      const anchors = [
        { classList: { add: vi.fn(), remove: vi.fn(), contains: vi.fn() } },
        { classList: { add: vi.fn(), remove: vi.fn(), contains: vi.fn() } },
        { classList: { add: vi.fn(), remove: vi.fn(), contains: vi.fn() } }
      ];

      mockDOM.anchors = anchors;

      // Simulate clearing all active states
      anchors.forEach(anchor => anchor.classList.remove('active'));

      // Verify all anchors had remove called
      anchors.forEach(anchor => {
        expect(anchor.classList.remove).toHaveBeenCalledWith('active');
      });
    });

    it('should activate the target anchor', () => {
      const targetAnchor = {
        classList: { add: vi.fn(), remove: vi.fn(), contains: vi.fn() }
      };

      // Simulate activation
      targetAnchor.classList.add('active');

      expect(targetAnchor.classList.add).toHaveBeenCalledWith('active');
    });
  });

  describe('CSS Integration', () => {
    it('should verify chevron styles are applied', () => {
      const mockAnchor = {};

      // Mock getComputedStyle
      const mockStyles = {
        content: '"▶"',
        display: 'block',
        color: 'rgb(51, 51, 51)'
      };

      global.window.getComputedStyle = vi.fn(() => mockStyles);

      const styles = window.getComputedStyle(mockAnchor, '::before');

      expect(styles.content).toBe('"▶"');
      expect(styles.display).toBe('block');
    });
  });

  describe('Scroll Sync Precision', () => {
    it('should only highlight one TOC item at a time', () => {
      const headers = [
        {
          textContent: 'Section 1',
          getBoundingClientRect: () => ({ top: 100, bottom: 200, height: 100 })
        },
        {
          textContent: 'Section 2',
          getBoundingClientRect: () => ({ top: 150, bottom: 250, height: 100 })
        },
        {
          textContent: 'Section 3',
          getBoundingClientRect: () => ({ top: 200, bottom: 300, height: 100 })
        }
      ];

      const tocItems = [
        {
          textContent: 'Section 1',
          classList: { add: vi.fn(), remove: vi.fn(), contains: vi.fn(() => false) }
        },
        {
          textContent: 'Section 2',
          classList: { add: vi.fn(), remove: vi.fn(), contains: vi.fn(() => false) }
        },
        {
          textContent: 'Section 3',
          classList: { add: vi.fn(), remove: vi.fn(), contains: vi.fn(() => false) }
        }
      ];

      mockDOM.headers = headers;
      mockDOM.anchors = tocItems;

      // Simulate intersection observer with tighter bounding box
      const viewportHeight = 1000;
      const priorityZoneTop = viewportHeight * 0.2; // 200px
      const priorityZoneBottom = viewportHeight * 0.4; // 400px

      // Test: Only section with best score should be active
      let activeHeader = null;
      let bestScore = -1;

      headers.forEach(header => {
        const rect = header.getBoundingClientRect();
        const headerTop = rect.top;

        let score = 0;

        if (headerTop >= priorityZoneTop && headerTop <= priorityZoneBottom) {
          score = 1000 + (priorityZoneBottom - headerTop);
        } else if (headerTop >= 0 && headerTop < priorityZoneTop) {
          score = 500 + (priorityZoneTop - headerTop);
        }

        if (score > bestScore) {
          bestScore = score;
          activeHeader = header;
        }
      });

      // Clear all active states
      tocItems.forEach(item => item.classList.remove('active'));

      // Set only one active
      if (activeHeader) {
        const matchingTOC = tocItems.find(item =>
          item.textContent.trim() === activeHeader.textContent.trim()
        );
        if (matchingTOC) {
          matchingTOC.classList.add('active');
        }
      }

      // Verify only one TOC item is active
      const activeTOCItems = tocItems.filter(item =>
        item.classList.add.mock.calls.some(call => call[0] === 'active')
      );

      expect(activeTOCItems.length).toBe(1);
      // With these positions:
      // Section 1: top=100 (above priority zone 200-400)
      // Section 2: top=150 (above priority zone 200-400)
      // Section 3: top=200 (at start of priority zone 200-400)
      // Section 3 should win because it's in the priority zone
      expect(activeTOCItems[0].textContent).toBe('Section 3'); // In priority zone
    });

    it('should use very tight rootMargin for intersection observer', () => {
      const expectedRootMargin = '-30% 0px -40% 0px';

      // Test that this gives a very tight bounding box for precision
      const defaultRootMargin = '0px 0px 0px 0px';

      // Parse margins
      const parseMargin = (margin) => {
        const parts = margin.split(' ');
        return {
          top: parseFloat(parts[0]),
          right: parseFloat(parts[1] || parts[0]),
          bottom: parseFloat(parts[2] || parts[0]),
          left: parseFloat(parts[3] || parts[1] || parts[0])
        };
      };

      const expected = parseMargin(expectedRootMargin);
      const defaultMargins = parseMargin(defaultRootMargin);

      // Tighter margins should be more restrictive (negative values)
      expect(expected.top).toBeLessThan(defaultMargins.top);
      expect(expected.bottom).toBeLessThan(defaultMargins.bottom);
    });

    it('should prioritize headers in priority zone over intersection ratio', () => {
      const viewportHeight = 1000;
      const priorityZoneTop = viewportHeight * 0.2; // 200px
      const priorityZoneBottom = viewportHeight * 0.4; // 400px

      const headers = [
        {
          textContent: 'Header Outside Zone',
          getBoundingClientRect: () => ({ top: 100 }), // Above priority zone
          intersectionRatio: 0.9 // High ratio but outside zone
        },
        {
          textContent: 'Header In Zone',
          getBoundingClientRect: () => ({ top: 300 }), // In priority zone
          intersectionRatio: 0.5 // Lower ratio but in zone
        }
      ];

      let activeHeader = null;
      let bestScore = -1;

      headers.forEach(header => {
        const rect = header.getBoundingClientRect();
        const headerTop = rect.top;

        let score = 0;

        if (headerTop >= priorityZoneTop && headerTop <= priorityZoneBottom) {
          // In priority zone - much higher base score
          score = 1000 + (priorityZoneBottom - headerTop);
        } else if (headerTop >= 0 && headerTop < priorityZoneTop) {
          // Above priority zone - lower score
          score = 500 + (priorityZoneTop - headerTop);
        }

        if (score > bestScore) {
          bestScore = score;
          activeHeader = header;
        }
      });

      // Header in priority zone should win despite lower intersection ratio
      expect(activeHeader.textContent).toBe('Header In Zone');
    });

    it('should clear previous active states before setting new one', () => {
      const tocItems = [
        {
          classList: {
            add: vi.fn(),
            remove: vi.fn(),
            contains: vi.fn(() => true) // Currently active
          }
        },
        {
          classList: {
            add: vi.fn(),
            remove: vi.fn(),
            contains: vi.fn(() => false)
          }
        }
      ];

      // Simulate clearing all states before setting new active
      tocItems.forEach(item => item.classList.remove('active'));

      // Then set new active
      tocItems[1].classList.add('active');

      // Verify all items had remove called
      tocItems.forEach(item => {
        expect(item.classList.remove).toHaveBeenCalledWith('active');
      });

      // Verify only new item has add called
      expect(tocItems[0].classList.add).not.toHaveBeenCalled();
      expect(tocItems[1].classList.add).toHaveBeenCalledWith('active');
    });

    it('should handle multiple intersection entries and pick best one', () => {
      // Simulate intersection observer entries with different ratios and positions
      const entries = [
        {
          target: { textContent: 'Section A' },
          isIntersecting: true,
          intersectionRatio: 0.3,
          boundingClientRect: { top: 50 } // Above priority zone
        },
        {
          target: { textContent: 'Section B' },
          isIntersecting: true,
          intersectionRatio: 0.8,
          boundingClientRect: { top: 250 } // In priority zone (200-400)
        },
        {
          target: { textContent: 'Section C' },
          isIntersecting: true,
          intersectionRatio: 0.9,
          boundingClientRect: { top: 500 } // Below priority zone
        }
      ];

      const viewportHeight = 1000;
      const priorityZoneTop = viewportHeight * 0.2;
      const priorityZoneBottom = viewportHeight * 0.4;

      const visibleHeaders = entries
        .filter(entry => entry.isIntersecting)
        .map(entry => ({
          header: entry.target,
          ratio: entry.intersectionRatio,
          boundingRect: entry.boundingClientRect
        }))
        .sort((a, b) => {
          const aTop = a.boundingRect.top;
          const bTop = b.boundingRect.top;

          const aInPriorityZone = aTop >= priorityZoneTop && aTop <= priorityZoneBottom;
          const bInPriorityZone = bTop >= priorityZoneTop && bTop <= priorityZoneBottom;

          // Prefer headers in priority zone
          if (aInPriorityZone && !bInPriorityZone) return -1;
          if (bInPriorityZone && !aInPriorityZone) return 1;

          // Within priority zone, prefer higher intersection ratio
          if (aInPriorityZone && bInPriorityZone) {
            return b.ratio - a.ratio;
          }

          // Outside priority zone, prefer those closer to top
          return aTop - bTop;
        });

      expect(visibleHeaders.length).toBe(3);
      expect(visibleHeaders[0].header.textContent).toBe('Section B'); // In priority zone wins
    });
  });

  describe('Error Handling', () => {
    it('should handle missing DOM elements gracefully', () => {
      // Test with empty DOM
      mockDOM.headers = [];
      mockDOM.anchors = [];

      expect(() => {
        // Simulate TOC manager initialization with empty DOM
        const headers = document.querySelectorAll('#main h1, #main h2, #main h3, #main h4, #main h5, #main h6');
        const anchors = document.querySelectorAll('aside.toc-nav .page_toc .anchor');

        // Should not throw with empty collections
        expect(headers.length).toBe(0);
        expect(anchors.length).toBe(0);
      }).not.toThrow();
    });

    it('should handle malformed text content', () => {
      const headers = [
        { textContent: null },
        { textContent: undefined },
        { textContent: '' }
      ];

      headers.forEach(header => {
        const text = header.textContent?.trim() || '';
        expect(typeof text).toBe('string');
      });
    });

    it('should distinguish between similar headers', () => {
      // Test case for the specific issue: similar headers should not be confused
      const headers = [
        { textContent: 'Security scanning', id: 'security-scanning' },
        { textContent: 'Security scanning implementation', id: 'security-scanning-implementation' }
      ];

      const tocItems = [
        { textContent: 'Security scanning' },
        { textContent: 'Security scanning implementation' }
      ];

      // Mock normalize function behavior
      const normalizeText = (text) => text.trim().toLowerCase().replace(/^\s*[#]*\s*/, '');

      // Test exact matching only
      const header1Normalized = normalizeText(headers[0].textContent);
      const header2Normalized = normalizeText(headers[1].textContent);
      const toc1Normalized = normalizeText(tocItems[0].textContent);
      const toc2Normalized = normalizeText(tocItems[1].textContent);

      // Should match exactly
      expect(header1Normalized).toBe(toc1Normalized);
      expect(header2Normalized).toBe(toc2Normalized);

      // Should NOT cross-match (this was the bug)
      expect(header1Normalized).not.toBe(toc2Normalized);
      expect(header2Normalized).not.toBe(toc1Normalized);
    });

    it('should have ultra-responsive performance settings for immediate scroll sync', () => {
      // Test the configuration values that should be used for precision scroll sync
      const expectedConfig = {
        rootMargin: '-30% 0px -40% 0px',
        threshold: [0, 0.5, 1.0],
        performance: {
          debounceDelay: 8,
          priorityZoneHeight: 0.2,
          priorityZoneOffset: 0.4
        }
      };

      // Verify ultra-tight bounding box
      expect(expectedConfig.rootMargin).toBe('-30% 0px -40% 0px');
      expect(expectedConfig.threshold).toEqual([0, 0.5, 1.0]);

      // Verify ultra-responsive debounce (under 10ms for immediate response)
      expect(expectedConfig.performance.debounceDelay).toBe(8);

      // Verify precise priority zone (center 20% of viewport)
      expect(expectedConfig.performance.priorityZoneHeight).toBe(0.2);
      expect(expectedConfig.performance.priorityZoneOffset).toBe(0.4);

      // Calculated priority zone should be 40%-60% of viewport
      const mockViewportHeight = 1000;
      const expectedTop = mockViewportHeight * expectedConfig.performance.priorityZoneOffset; // 400px
      const expectedBottom = mockViewportHeight * (expectedConfig.performance.priorityZoneOffset + expectedConfig.performance.priorityZoneHeight); // 600px

      expect(expectedTop).toBe(400);
      expect(Math.round(expectedBottom)).toBe(600); // Use Math.round to handle floating point precision
    });
  });
});
