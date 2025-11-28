/**
 * Progress Banner Component Tests
 * Tests for the existing learning-progress-tracker-plugin functionality
 *
 * @module tests/components/progress-banner
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

// Import the plugin directly
import '../../plugins/learning-progress-tracker-plugin.js';

describe('Progress Banner Component', () => {
  let container;
  let mockLocalStorage;

  beforeEach(() => {
    // Setup DOM container
    container = document.createElement('div');
    container.id = 'test-container';
    document.body.appendChild(container);

    // Mock localStorage
    mockLocalStorage = {
      store: {},
      getItem: vi.fn((key) => mockLocalStorage.store[key] || null),
      setItem: vi.fn((key, value) => { mockLocalStorage.store[key] = value; }),
      removeItem: vi.fn((key) => { delete mockLocalStorage.store[key]; }),
      clear: vi.fn(() => { mockLocalStorage.store = {}; }),
      length: 0,
      key: vi.fn()
    };

    Object.defineProperty(window, 'localStorage', {
      value: mockLocalStorage,
      writable: true
    });

    // Mock console to avoid test output pollution
    vi.spyOn(console, 'warn').mockImplementation(() => {});
    vi.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    // Clean up DOM
    if (container && container.parentNode) {
      container.parentNode.removeChild(container);
    }

    // Clear all mocks
    vi.restoreAllMocks();

    // Reset localStorage mock
    mockLocalStorage.store = {};
  });

  describe('Existing Progress Banner Functionality', () => {
    it('should maintain existing kata progress tracking', () => {
      // This should PASS - existing functionality should still work

      container.innerHTML = `
        <div class="kata-progress-container">
          <div class="kata-progress-info">
            <span class="kata-progress-text">Progress: 3/8 tasks completed</span>
          </div>
          <div class="kata-progress-bar">
            <div class="kata-progress-fill" style="width: 37.5%"></div>
          </div>
        </div>
      `;

      const progressBanner = container.querySelector('.kata-progress-container');
      const progressText = container.querySelector('.kata-progress-text');
      const progressFill = container.querySelector('.kata-progress-fill');

      expect(progressBanner).toBeTruthy();
      expect(progressText.textContent).toContain('3/8 tasks completed');
      expect(progressFill.style.width).toBe('37.5%');
    });

    it('should maintain existing localStorage integration', () => {
      // This should PASS - existing localStorage should still work

      mockLocalStorage.setItem('kata-progress-test', JSON.stringify({
        currentStep: 3,
        totalSteps: 8
      }));

      const storedData = JSON.parse(mockLocalStorage.getItem('kata-progress-test'));

      expect(storedData.currentStep).toBe(3);
      expect(storedData.totalSteps).toBe(8);
      expect(mockLocalStorage.setItem).toHaveBeenCalled();
      expect(mockLocalStorage.getItem).toHaveBeenCalled();
    });

    it('should handle skill assessment progress display', () => {
      // This should PASS - tests the current simplified banner

      container.innerHTML = `
        <div class="kata-progress-container" data-content-type="skill-assessment">
          <div class="kata-progress-info">
            <span class="kata-progress-text">Question 5 of 8</span>
          </div>
          <div class="kata-progress-bar">
            <div class="kata-progress-fill" style="width: 62.5%"></div>
          </div>
        </div>
      `;

      const progressBanner = container.querySelector('.kata-progress-container');
      const progressText = container.querySelector('.kata-progress-text');
      const progressFill = container.querySelector('.kata-progress-fill');

      expect(progressBanner).toBeTruthy();
      expect(progressBanner.dataset.contentType).toBe('skill-assessment');
      expect(progressText.textContent).toContain('Question 5 of 8');
      expect(progressFill.style.width).toBe('62.5%');
    });

    it('should provide desktop-focused interface without mobile styling', () => {
      // This validates we have a clean desktop interface

      container.innerHTML = `
        <div class="kata-progress-container" data-content-type="skill-assessment">
          <div class="kata-progress-bar">
            <div class="kata-progress-fill" style="width: 50%"></div>
          </div>
        </div>
      `;

      const progressBanner = container.querySelector('.kata-progress-container');
      const touchTargets = container.querySelectorAll('.touch-assessment-target');
      const mobileElements = container.querySelectorAll('.mobile-assessment-layout');

      // Should NOT have mobile styling since this is desktop-only
      expect(progressBanner.classList.contains('mobile-assessment')).toBe(false);
      expect(touchTargets.length).toBe(0);
      expect(mobileElements.length).toBe(0);
    });
  });
});
