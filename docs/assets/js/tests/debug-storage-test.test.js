
import { describe, it, expect, beforeEach, vi } from 'vitest';
import LearningPathDashboard from '../plugins/learning-path-dashboard.js';

describe('Debug localStorage error', () => {
  it('should trace localStorage error flow', () => {
    // Setup container and mock paths
    document.body.innerHTML = `
      <div class='learning-dashboard-container'>
        <div class='learning-dashboard-status' aria-live='polite'></div>
        <div class='learning-paths-grid'>
          <div class='learning-path-card' data-path-id='test-path-1'>
            <input type='checkbox' class='path-checkbox' data-path-id='test-path-1'>
          </div>
        </div>
      </div>`;

    const container = document.querySelector('.learning-dashboard-container');
    const mockPaths = [{ id: 'test-path-1', title: 'Test Path', category: 'test' }];

    const dashboard = new LearningPathDashboard(container, mockPaths);
    dashboard.bindCardEvents(container);

    // Mock localStorage.setItem to throw error
    const originalSetItem = localStorage.setItem;
    localStorage.setItem = vi.fn(() => {
      console.log('localStorage.setItem called - throwing error');
      throw new Error('Storage unavailable');
    });

    // Listen for storage error event
    let eventReceived = false;
    container.addEventListener('storage-error', (event) => {
      console.log('Storage error event received:', event.detail);
      eventReceived = true;
    });

    // Trigger the error
    const checkbox = container.querySelector('.path-checkbox');
    checkbox.checked = true;
    console.log('Dispatching change event...');
    checkbox.dispatchEvent(new Event('change'));

    console.log('Event received:', eventReceived);

    localStorage.setItem = originalSetItem;
  });
});

