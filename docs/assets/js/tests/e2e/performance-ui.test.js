import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { createPerformanceTestHelper, createMemoryMonitor } from '../helpers/performance-test-helper.js';

/**
 * UI Responsiveness Performance Test Suite
 *
 * Focused tests for UI responsiveness during heavy operations
 * with enhanced cleanup and memory monitoring.
 */
describe('UI Responsiveness Performance', () => {
  let testContainer;
  let performanceHelper;
  let memoryMonitor;

  beforeEach(async () => {
    // Setup test environment with comprehensive performance monitoring using happy-dom
    document.head.innerHTML = `
        <title>UI Responsiveness Test</title>
        <meta charset="utf-8">
        <style>
          .learning-path { margin: 10px; padding: 10px; border: 1px solid #ccc; }
          .path-item { display: block; margin: 5px 0; }
          .learning-interface { padding: 20px; }
          .learning-section { padding: 10px; margin: 10px 0; }
          .progress-bar { width: 100%; height: 20px; background: #f0f0f0; }
          .progress-fill { height: 100%; background: #4caf50; transition: width 0.3s ease; }
        </style>
    `;

    document.body.innerHTML = `
      <div id="test-container">
        <div id="learning-paths-container"></div>
        <button id="coach-button">Coach Button</button>
      </div>
    `;

    testContainer = document.getElementById('test-container');

    // Initialize performance testing tools with comprehensive cleanup
    performanceHelper = createPerformanceTestHelper({
      memoryTrackingEnabled: true,
      domCleanupEnabled: true,
      eventCleanupEnabled: true,
      observerCleanupEnabled: true
    });

    memoryMonitor = createMemoryMonitor();
  });

  afterEach(() => {
    // Comprehensive cleanup to prevent test interference
    if (performanceHelper) {
      performanceHelper.cleanup();
    }

    if (memoryMonitor) {
      memoryMonitor.stopMonitoring();
      memoryMonitor.clear();
    }

    // Clean up any remaining DOM elements
    const testElements = document.querySelectorAll('[data-test-structure="true"]');
    testElements.forEach(element => {
      if (element.parentNode) {
        element.parentNode.removeChild(element);
      }
    });

    // Reset document body content
    const container = document.getElementById('learning-paths-container');
    if (container) {
      container.innerHTML = '';
    }

    // Clear any performance measurements
    if (performance.clearMarks) {
      performance.clearMarks();
    }
    if (performance.clearMeasures) {
      performance.clearMeasures();
    }

    // Reset all mocks
    vi.restoreAllMocks();
  });

  it('should maintain responsiveness during heavy DOM manipulation with learning content', async () => {
    const container = document.getElementById('learning-paths-container');
    const interactionResponses = [];

    // Setup interaction tracking
    const button = document.getElementById('coach-button');
    const interactionHandler = () => {
      const responseTime = performance.now();
      interactionResponses.push(responseTime);
    };

    button.addEventListener('click', interactionHandler);
    performanceHelper.trackEventListener(button, 'click', interactionHandler);

    memoryMonitor.startMonitoring(25);
    performanceHelper.startMeasurement('heavy-dom-operations');

    // Start heavy DOM operation with learning content
    const heavyOperation = async () => {
      for (let i = 0; i < 50; i++) { // Reduced for better memory management
        const learningPathElement = document.createElement('div');
        learningPathElement.className = 'learning-path';
        learningPathElement.setAttribute('data-test-structure', 'true');

        learningPathElement.innerHTML = `
          <h3>Learning Path ${i}</h3>
          <div class="path-metadata">
            <span class="difficulty">Level ${(i % 5) + 1}</span>
            <span class="duration">${Math.floor(Math.random() * 120) + 30}min</span>
            <span class="category">Category ${i % 10}</span>
          </div>
          <div class="items">
            ${Array(10).fill(0).map((_, j) => `
              <label class="path-item">
                <input type="checkbox" data-id="${i}-${j}" />
                <span>Learning Item ${i}-${j}</span>
                <div class="item-progress">
                  <div class="progress-bar">
                    <div class="progress-fill" style="width: ${Math.random() * 100}%"></div>
                  </div>
                </div>
              </label>
            `).join('')}
          </div>
        `;

        container.appendChild(learningPathElement);
        performanceHelper.createdElements.add(learningPathElement);

        // Yield control periodically to maintain responsiveness
        if (i % 25 === 0) {
          await new Promise(resolve => setTimeout(resolve, 0));
        }
      }
    };

    // Start heavy operation
    const operationPromise = heavyOperation();

    // Simulate user interactions during operation
    const interactionPromises = [];
    for (let i = 0; i < 5; i++) {
      const interactionPromise = new Promise((resolve) => {
        setTimeout(() => {
          const clickTime = performance.now();
          button.click();
          const responseTime = performance.now() - clickTime;
          expect(responseTime).toBeLessThan(50); // < 50ms response
          resolve();
        }, i * 100);
      });
      interactionPromises.push(interactionPromise);
    }

    await Promise.all([operationPromise, ...interactionPromises]);

    const operationMetrics = performanceHelper.endMeasurement('heavy-dom-operations');
    const memoryStats = memoryMonitor.stopMonitoring();

    // Verify responsiveness maintained
    expect(interactionResponses.length).toBeGreaterThan(0);
    expect(operationMetrics.duration).toBeLessThan(8000); // < 8 seconds for heavy operation
    expect(memoryStats.memoryUsage.growth).toBeLessThan(100 * 1024 * 1024); // < 100MB growth
  });

  it('should handle rapid successive interactions efficiently in learning interface', async () => {
    const interactionCount = 50; // Reduced for memory efficiency
    const responses = [];

    // Create learning interface element
    const learningInterface = document.createElement('div');
    learningInterface.className = 'learning-interface';
    learningInterface.setAttribute('data-test-structure', 'true');

    const progressCheckbox = document.createElement('input');
    progressCheckbox.type = 'checkbox';
    progressCheckbox.id = 'progress-checkbox';

    const progressHandler = (e) => {
      const startTime = performance.now();

      // Simulate learning progress processing
      const learningData = {
        itemId: 'test-item',
        completed: e.target.checked,
        timestamp: new Date(),
        score: Math.random() * 100
      };

      // Simulate storage operation
      window.localStorage.setItem(`progress-${Date.now()}`, JSON.stringify(learningData));

      // Simulate UI update
      for (let i = 0; i < 500; i++) { // Reduced computation
        Math.random();
      }

      const endTime = performance.now();
      responses.push(endTime - startTime);
    };

    progressCheckbox.addEventListener('change', progressHandler);
    performanceHelper.trackEventListener(progressCheckbox, 'change', progressHandler);

    learningInterface.appendChild(progressCheckbox);
    document.body.appendChild(learningInterface);
    performanceHelper.createdElements.add(learningInterface);

    // Mock localStorage
    const localStorageMock = {
      getItem: vi.fn(),
      setItem: vi.fn(),
      removeItem: vi.fn(),
      clear: vi.fn()
    };

    Object.defineProperty(window, 'localStorage', {
      value: localStorageMock,
      writable: true
    });

    memoryMonitor.startMonitoring(10);
    performanceHelper.startMeasurement('rapid-interactions');

    // Fire rapid interactions
    for (let i = 0; i < interactionCount; i++) {
      progressCheckbox.checked = !progressCheckbox.checked;
      progressCheckbox.dispatchEvent(new window.Event('change', { bubbles: true }));

      // Yield control every 10 interactions
      if (i % 10 === 0) {
        await new Promise(resolve => setTimeout(resolve, 0));
      }
    }

    const interactionMetrics = performanceHelper.endMeasurement('rapid-interactions');
    const memoryStats = memoryMonitor.stopMonitoring();

    // Performance assertions
    expect(interactionMetrics.duration).toBeLessThan(1000); // < 1 second for 50 interactions
    expect(responses.length).toBe(interactionCount);

    const averageResponse = responses.reduce((sum, time) => sum + time, 0) / responses.length;
    expect(averageResponse).toBeLessThan(20); // < 20ms average response

    // Memory should remain stable during interactions
    expect(memoryStats.memoryUsage.growth).toBeLessThan(10 * 1024 * 1024); // < 10MB growth
  });

  it('should handle scroll performance with large learning content', async () => {
    const container = document.getElementById('learning-paths-container');

    memoryMonitor.startMonitoring(50);
    performanceHelper.startMeasurement('large-content-creation');

    // Create scrollable learning content
    for (let i = 0; i < 25; i++) { // Reduced for memory efficiency
      const learningSection = document.createElement('div');
      learningSection.className = 'learning-section';
      learningSection.setAttribute('data-test-structure', 'true');
      learningSection.style.height = '100px';
      learningSection.style.marginBottom = '10px';

      learningSection.innerHTML = `
        <h3>Learning Section ${i}</h3>
        <div class="section-content">
          <p>Content for learning section ${i} with detailed explanations and examples.</p>
          <div class="learning-objectives">
            ${Array.from({ length: 2 }, (_, j) => `
              <div class="objective">Objective ${j + 1} for section ${i}</div>
            `).join('')}
          </div>
          <div class="section-progress">
            <div class="progress-bar">
              <div class="progress-fill" style="width: ${Math.random() * 100}%"></div>
            </div>
          </div>
        </div>
      `;

      container.appendChild(learningSection);
      performanceHelper.createdElements.add(learningSection);
    }

    const creationMetrics = performanceHelper.endMeasurement('large-content-creation');

    // Test scroll performance
    performanceHelper.startMeasurement('scroll-performance');
    const scrollTimes = [];

    for (let i = 0; i < 5; i++) {
      const startTime = performance.now();

      window.scrollTo(0, i * 500);

      const endTime = performance.now();
      scrollTimes.push(endTime - startTime);

      await new Promise(resolve => setTimeout(resolve, 10));
    }

    const scrollMetrics = performanceHelper.endMeasurement('scroll-performance');
    const memoryStats = memoryMonitor.stopMonitoring();

    // Performance assertions
    expect(creationMetrics.duration).toBeLessThan(2000); // < 2 seconds for creation
    expect(scrollMetrics.duration).toBeLessThan(250); // < 250ms for scroll operations

    const averageScrollTime = scrollTimes.reduce((sum, time) => sum + time, 0) / scrollTimes.length;
    expect(averageScrollTime).toBeLessThan(15); // < 15ms average scroll time

    // Memory usage should be reasonable for content
    expect(memoryStats.memoryUsage.peak.used).toBeLessThan(150 * 1024 * 1024); // < 150MB peak
  });

  it('should handle form interactions with learning progress efficiently', async () => {
    const container = document.getElementById('learning-paths-container');
    const formResponses = [];

    memoryMonitor.startMonitoring(25);

    // Create learning progress form
    const progressForm = document.createElement('form');
    progressForm.className = 'learning-progress-form';
    progressForm.setAttribute('data-test-structure', 'true');

    const formFields = [];
    for (let i = 0; i < 20; i++) {
      const fieldGroup = document.createElement('div');
      fieldGroup.className = 'field-group';

      fieldGroup.innerHTML = `
        <label for="skill-${i}">Skill Assessment ${i + 1}</label>
        <select id="skill-${i}" name="skill-${i}">
          <option value="">Select Level</option>
          <option value="1">Beginner</option>
          <option value="2">Intermediate</option>
          <option value="3">Advanced</option>
          <option value="4">Expert</option>
        </select>
        <input type="range" id="confidence-${i}" name="confidence-${i}" min="1" max="10" value="5">
        <label for="confidence-${i}">Confidence Level</label>
      `;

      progressForm.appendChild(fieldGroup);
      formFields.push(fieldGroup);
    }

    container.appendChild(progressForm);
    performanceHelper.createdElements.add(progressForm);

    // Add form interaction handlers
    const formHandler = (e) => {
      const startTime = performance.now();

      // Simulate form validation and processing
      const formData = new FormData(progressForm);
      const data = Object.fromEntries(formData);

      // Simulate some processing
      for (let i = 0; i < 100; i++) {
        Math.random();
      }

      const endTime = performance.now();
      formResponses.push(endTime - startTime);
    };

    progressForm.addEventListener('change', formHandler);
    performanceHelper.trackEventListener(progressForm, 'change', formHandler);

    performanceHelper.startMeasurement('form-interactions');

    // Simulate rapid form interactions
    const selects = progressForm.querySelectorAll('select');
    const ranges = progressForm.querySelectorAll('input[type="range"]');

    for (let i = 0; i < selects.length; i++) {
      // Change select values
      selects[i].value = String(Math.floor(Math.random() * 4) + 1);
      selects[i].dispatchEvent(new window.Event('change', { bubbles: true }));

      // Change range values
      ranges[i].value = String(Math.floor(Math.random() * 10) + 1);
      ranges[i].dispatchEvent(new window.Event('change', { bubbles: true }));

      // Yield control periodically
      if (i % 5 === 0) {
        await new Promise(resolve => setTimeout(resolve, 0));
      }
    }

    const formMetrics = performanceHelper.endMeasurement('form-interactions');
    const memoryStats = memoryMonitor.stopMonitoring();

    // Performance assertions
    expect(formMetrics.duration).toBeLessThan(1000); // < 1 second for form interactions
    expect(formResponses.length).toBeGreaterThan(0);

    const averageFormResponse = formResponses.reduce((sum, time) => sum + time, 0) / formResponses.length;
    expect(averageFormResponse).toBeLessThan(10); // < 10ms average form response

    // Memory should remain stable during form interactions
    expect(memoryStats.memoryUsage.growth).toBeLessThan(35 * 1024 * 1024); // < 35MB growth
  });
});
