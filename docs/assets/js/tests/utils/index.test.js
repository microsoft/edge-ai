/**
 * @fileoverview Tests for Utils Index Module
 * Tests centralized utility exports, convenience functions, and module integration
 * @version 1.0.0
 */

import { describe, it, expect, beforeEach as _beforeEach, afterEach as _afterEach, vi as _vi } from 'vitest';

// Import all exports from the utils index
import {
  // Class exports
  DOMUtils,
  KataDetection,

  // Function exports from kata-detection
  defaultKataDetection,
  isKataPage,
  isLabPage,
  getCurrentLearningContext,
  getContentType,
  extractKataId,

  // Convenience instances
  domUtils,

  // Metadata exports
  UTILS_VERSION,
  AVAILABLE_UTILITIES,
  getUtilityInfo
} from '../../utils/index.js';

describe('Utils Index Module', () => {

  describe('Module Exports', () => {

    describe('Class Exports', () => {
      it('should export DOMUtils class', () => {
        expect(DOMUtils).toBeDefined();
        expect(typeof DOMUtils).toBe('function');
        expect(DOMUtils.name).toBe('DOMUtils');
      });

      it('should export KataDetection class', () => {
        expect(KataDetection).toBeDefined();
        expect(typeof KataDetection).toBe('function');
        expect(KataDetection.name).toBe('KataDetection');
      });

      it('should allow creating instances of exported classes', () => {
        const domUtilsInstance = new DOMUtils();
        expect(domUtilsInstance).toBeInstanceOf(DOMUtils);

        const kataDetectionInstance = new KataDetection();
        expect(kataDetectionInstance).toBeInstanceOf(KataDetection);
      });
    });

    describe('Function Exports from KataDetection', () => {
      it('should export kata detection functions', () => {
        expect(typeof isKataPage).toBe('function');
        expect(typeof isLabPage).toBe('function');
        expect(typeof getCurrentLearningContext).toBe('function');
        expect(typeof getContentType).toBe('function');
        expect(typeof extractKataId).toBe('function');
      });

      it('should export defaultKataDetection instance', () => {
        expect(defaultKataDetection).toBeDefined();
        expect(defaultKataDetection).toBeInstanceOf(KataDetection);
      });

      it('should have working kata detection functions', () => {
        // These functions should not throw when called with basic parameters
        expect(() => isKataPage('/learn/kata/intro')).not.toThrow();
        expect(() => isLabPage('/learn/lab/setup')).not.toThrow();
        expect(() => getCurrentLearningContext()).not.toThrow();
        expect(() => getContentType('/some/path')).not.toThrow();
        expect(() => extractKataId('/learn/kata/intro-123')).not.toThrow();
      });
    });

    describe('Convenience Instance Exports', () => {
      it('should export domUtils instance', () => {
        expect(domUtils).toBeDefined();
        expect(domUtils).toBeInstanceOf(DOMUtils);
      });

      it('should provide ready-to-use domUtils methods', () => {
        expect(typeof domUtils.querySelector).toBe('function');
        expect(typeof domUtils.querySelectorAll).toBe('function');
        expect(typeof domUtils.createElement).toBe('function');
      });

      it('should use the same domUtils instance across imports', () => {
        // Import again to test singleton behavior
        import('../../utils/index.js').then(module => {
          expect(module.domUtils).toBe(domUtils);
        });
      });
    });
  });

  describe('Metadata and Versioning', () => {

    describe('Version Information', () => {
      it('should export UTILS_VERSION', () => {
        expect(UTILS_VERSION).toBeDefined();
        expect(typeof UTILS_VERSION).toBe('string');
        expect(UTILS_VERSION).toBe('1.0.0');
      });

      it('should have valid semantic version format', () => {
        const semverPattern = /^\d+\.\d+\.\d+$/;
        expect(UTILS_VERSION).toMatch(semverPattern);
      });
    });

    describe('Available Utilities Metadata', () => {
      it('should export AVAILABLE_UTILITIES object', () => {
        expect(AVAILABLE_UTILITIES).toBeDefined();
        expect(typeof AVAILABLE_UTILITIES).toBe('object');
        expect(AVAILABLE_UTILITIES).not.toBeNull();
      });

      it('should contain DOMUtils metadata', () => {
        expect(AVAILABLE_UTILITIES.DOMUtils).toBeDefined();
        expect(AVAILABLE_UTILITIES.DOMUtils.description).toContain('DOM manipulation');
        expect(AVAILABLE_UTILITIES.DOMUtils.type).toBe('class');
        expect(AVAILABLE_UTILITIES.DOMUtils.instance).toBe('domUtils');
      });

      it('should contain KataDetection metadata', () => {
        expect(AVAILABLE_UTILITIES.KataDetection).toBeDefined();
        expect(AVAILABLE_UTILITIES.KataDetection.description).toContain('Learning content detection');
        expect(AVAILABLE_UTILITIES.KataDetection.type).toBe('class');
        expect(AVAILABLE_UTILITIES.KataDetection.instance).toBe('defaultKataDetection');
      });

      it('should have consistent metadata structure', () => {
        Object.values(AVAILABLE_UTILITIES).forEach(utility => {
          expect(utility).toHaveProperty('description');
          expect(utility).toHaveProperty('type');
          expect(utility).toHaveProperty('instance');
          expect(typeof utility.description).toBe('string');
          expect(typeof utility.type).toBe('string');
          expect(typeof utility.instance).toBe('string');
        });
      });
    });

    describe('getUtilityInfo Function', () => {
      it('should export getUtilityInfo function', () => {
        expect(getUtilityInfo).toBeDefined();
        expect(typeof getUtilityInfo).toBe('function');
      });

      it('should return comprehensive utility information', () => {
        const info = getUtilityInfo();

        expect(info).toHaveProperty('version');
        expect(info).toHaveProperty('utilities');
        expect(info).toHaveProperty('count');

        expect(info.version).toBe(UTILS_VERSION);
        expect(info.utilities).toBe(AVAILABLE_UTILITIES);
        expect(typeof info.count).toBe('number');
      });

      it('should return correct utility count', () => {
        const info = getUtilityInfo();
        const expectedCount = Object.keys(AVAILABLE_UTILITIES).length;
        expect(info.count).toBe(expectedCount);
      });

      it('should return consistent information on multiple calls', () => {
        const info1 = getUtilityInfo();
        const info2 = getUtilityInfo();

        expect(info1).toEqual(info2);
        expect(info1.version).toBe(info2.version);
        expect(info1.count).toBe(info2.count);
      });
    });
  });

  describe('Integration and Cross-Module Compatibility', () => {

    describe('Export Consistency', () => {
      it('should export all documented utilities', () => {
        const exports = {
          DOMUtils,
          KataDetection,
          defaultKataDetection,
          isKataPage,
          isLabPage,
          getCurrentLearningContext,
          getContentType,
          extractKataId,
          domUtils,
          UTILS_VERSION,
          AVAILABLE_UTILITIES,
          getUtilityInfo
        };

        Object.entries(exports).forEach(([_name, value]) => {
          expect(value).toBeDefined();
        });
      });

      it('should maintain expected export types', () => {
        // Classes
        expect(typeof DOMUtils).toBe('function');
        expect(typeof KataDetection).toBe('function');

        // Functions
        expect(typeof isKataPage).toBe('function');
        expect(typeof isLabPage).toBe('function');
        expect(typeof getCurrentLearningContext).toBe('function');
        expect(typeof getContentType).toBe('function');
        expect(typeof extractKataId).toBe('function');
        expect(typeof getUtilityInfo).toBe('function');

        // Instances
        expect(typeof domUtils).toBe('object');
        expect(typeof defaultKataDetection).toBe('object');

        // Constants
        expect(typeof UTILS_VERSION).toBe('string');
        expect(typeof AVAILABLE_UTILITIES).toBe('object');
      });
    });

    describe('Module Import Patterns', () => {
      it('should support named imports', async () => {
        const { DOMUtils: ImportedDOMUtils, domUtils: importedDomUtils } =
          await import('../../utils/index.js');

        expect(ImportedDOMUtils).toBe(DOMUtils);
        expect(importedDomUtils).toBe(domUtils);
      });

      it('should support namespace imports', async () => {
        const Utils = await import('../../utils/index.js');

        expect(Utils.DOMUtils).toBe(DOMUtils);
        expect(Utils.domUtils).toBe(domUtils);
        expect(Utils.UTILS_VERSION).toBe(UTILS_VERSION);
        expect(Utils.getUtilityInfo).toBe(getUtilityInfo);
      });
    });

    describe('Real-world Usage Scenarios', () => {
      it('should enable quick DOM utility access', () => {
        // Simulate common usage pattern
        expect(domUtils.querySelector).toBeDefined();
        expect(() => domUtils.createElement('div')).not.toThrow();
      });

      it('should enable kata detection without instantiation', () => {
        // Simulate common usage pattern
        expect(() => isKataPage('/kata/intro')).not.toThrow();
        expect(() => getCurrentLearningContext()).not.toThrow();
      });

      it('should provide debugging information', () => {
        const info = getUtilityInfo();
        expect(info.version).toBeTruthy();
        expect(info.count).toBeGreaterThan(0);
        expect(Object.keys(info.utilities).length).toBeGreaterThan(0);
      });
    });
  });

  describe('Error Handling and Edge Cases', () => {

    describe('Module Loading Resilience', () => {
      it('should handle missing dependencies gracefully', () => {
        // getUtilityInfo should work even if some utilities fail
        expect(() => getUtilityInfo()).not.toThrow();
      });

      it('should provide consistent metadata even with partial failures', () => {
        const info = getUtilityInfo();
        expect(info).toHaveProperty('version');
        expect(info).toHaveProperty('utilities');
        expect(info).toHaveProperty('count');
      });
    });

    describe('Utility Instance Stability', () => {
      it('should maintain domUtils instance integrity', () => {
        const originalMethods = Object.getOwnPropertyNames(Object.getPrototypeOf(domUtils));

        // Ensure core methods are preserved
        expect(originalMethods).toContain('constructor');
        expect(domUtils.querySelector).toBeDefined();
      });

      it('should handle multiple utility info requests', () => {
        // Stress test the utility info function
        const results = Array.from({ length: 10 }, () => getUtilityInfo());

        results.forEach(result => {
          expect(result.version).toBe(UTILS_VERSION);
          expect(result.count).toBe(Object.keys(AVAILABLE_UTILITIES).length);
        });
      });
    });
  });
});
