/**
 * Learning Paths Component Visual Tests
 * Tests specific visual consistency for learning paths components
 *
 * @fileoverview Component-specific visual design tests
 * @author Edge AI Team
 * @since 2025-09-14
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

describe('Learning Paths Component Visuals', () => {
  let container;

  beforeEach(() => {
    // Use the global document from vitest environment setup (Happy DOM)
    document.head.innerHTML = '';
    document.body.innerHTML = '<div id="test-container"></div>';
    container = document.getElementById('test-container');

    // Load CSS variables for component tests
    const variablesStyle = document.createElement('style');
    variablesStyle.textContent = `
      :root {
        --primary-color: #0078d4;
        --accent-color: #107c10;
        --background-color: #ffffff;
        --surface-color: #f5f5f5;
        --text-primary: #323130;
        --text-secondary: #605e5c;
        --border-color: #e1dfdd;
        --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
        --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
        --spacing-xs: 0.25rem;
        --spacing-sm: 0.5rem;
        --spacing-md: 1rem;
        --spacing-lg: 1.5rem;
        --spacing-xl: 2rem;
        --spacing-2xl: 3rem;
        --font-size-sm: 0.875rem;
        --font-size-md: 1rem;
        --font-size-lg: 1.125rem;
        --font-size-xl: 1.25rem;
        --font-size-2xl: 1.5rem;
        --font-weight-normal: 400;
        --font-weight-medium: 500;
        --font-weight-semibold: 600;
        --font-weight-bold: 700;
        --border-radius-sm: 0.25rem;
        --border-radius-md: 0.375rem;
        --border-radius-lg: 0.5rem;
        --success-color: #107c10;
        --warning-color: #ff8c00;
        --error-color: #d83b01;
      }
    `;
    document.head.appendChild(variablesStyle);
  });

  afterEach(() => {
    container.innerHTML = '';
  });

  describe('Assessment First Layout', () => {
    it('should apply assessment-first visual hierarchy', async () => {
      container.innerHTML = `
        <div class="assessment-first-container">
          <section class="assessment-primary-section">
            <div class="assessment-hero">
              <h1>Skill Assessment</h1>
              <p class="assessment-description">Discover your learning path with our comprehensive assessment</p>
              <button class="assessment-cta">Take Assessment Now</button>
            </div>
          </section>
          <section class="learning-paths-secondary">
            <h2>Available Learning Paths</h2>
            <div class="paths-preview">
              <div class="path-preview-card">Path 1</div>
              <div class="path-preview-card">Path 2</div>
            </div>
          </section>
        </div>
      `;

      const style = document.createElement('style');
      style.textContent = `
        .assessment-first-container {
          display: grid;
          grid-template-rows: auto 1fr;
          min-height: 100vh;
          gap: var(--spacing-3xl);
        }

        .assessment-primary-section {
          background: linear-gradient(135deg, var(--primary-color) 0%, var(--focus-color) 100%);
          color: white;
          padding: var(--spacing-3xl) var(--spacing-xl);
          text-align: center;
          border-radius: var(--border-radius-xl);
        }

        .assessment-hero h1 {
          font-size: var(--font-size-4xl);
          font-weight: var(--font-weight-bold);
          margin-bottom: var(--spacing-lg);
          line-height: var(--line-height-tight);
        }

        .assessment-description {
          font-size: var(--font-size-lg);
          margin-bottom: var(--spacing-2xl);
          opacity: 0.9;
          max-width: 600px;
          margin-left: auto;
          margin-right: auto;
        }

        .assessment-cta {
          background: white;
          color: var(--primary-color);
          border: none;
          padding: var(--spacing-md) var(--spacing-2xl);
          font-size: var(--font-size-lg);
          font-weight: var(--font-weight-semibold);
          border-radius: var(--border-radius-lg);
          box-shadow: var(--shadow-lg);
          transition: transform 0.2s ease, box-shadow 0.2s ease;
        }

        .assessment-cta:hover {
          transform: translateY(-2px);
          box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
        }

        .learning-paths-secondary {
          padding: 0 var(--spacing-xl);
        }

        .learning-paths-secondary h2 {
          font-size: var(--font-size-2xl);
          color: var(--text-secondary);
          text-align: center;
          margin-bottom: var(--spacing-xl);
        }

        .paths-preview {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
          gap: var(--spacing-lg);
        }

        .path-preview-card {
          background: var(--surface-color);
          padding: var(--spacing-lg);
          border-radius: var(--border-radius-lg);
          border: 1px solid var(--border-color);
          opacity: 0.7;
          transition: opacity 0.3s ease;
        }

        .path-preview-card:hover {
          opacity: 1;
        }
      `;
      document.head.appendChild(style);

      const assessmentSection = container.querySelector('.assessment-primary-section');
      const learningPathsSection = container.querySelector('.learning-paths-secondary');
      const assessmentCTA = container.querySelector('.assessment-cta');
      const pathCards = container.querySelectorAll('.path-preview-card');

      const assessmentStyle = window.getComputedStyle(assessmentSection);
      const pathsStyle = window.getComputedStyle(learningPathsSection);
      const ctaStyle = window.getComputedStyle(assessmentCTA);
      const cardStyle = window.getComputedStyle(pathCards[0]);

      // Assessment section should be prominent
      expect(assessmentStyle.background).toContain('linear-gradient');
      expect(assessmentStyle.color).toBe('white'); // Happy DOM returns keyword format
      expect(assessmentStyle.textAlign).toBe('center');

      // CTA button should be prominent
      expect(ctaStyle.backgroundColor).toBe('white'); // Happy DOM returns keyword format
      expect(ctaStyle.color).toBe('#0078d4'); // Happy DOM returns hex format
      expect(ctaStyle.fontWeight).toBe('600');

      // Learning paths should be secondary
      expect(cardStyle.opacity).toBe('0.7');
      expect(pathsStyle.color).not.toBe('rgb(255, 255, 255)');
    });

    it('should maintain visual focus hierarchy in assessment-first layout', async () => {
      container.innerHTML = `
        <div class="assessment-layout">
          <div class="primary-focus assessment-card">
            <h2>Take Your Assessment</h2>
            <p>Primary action</p>
          </div>
          <div class="secondary-focus path-card">
            <h3>Browse Paths</h3>
            <p>Secondary action</p>
          </div>
          <div class="tertiary-focus resource-card">
            <h4>Additional Resources</h4>
            <p>Tertiary action</p>
          </div>
        </div>
      `;

      const style = document.createElement('style');
      style.textContent = `
        .assessment-layout {
          display: flex;
          flex-direction: column;
          gap: var(--spacing-lg);
        }

        .primary-focus {
          background: var(--primary-color);
          color: white;
          padding: var(--spacing-2xl);
          border-radius: var(--border-radius-xl);
          box-shadow: var(--shadow-lg);
          transform: scale(1.02);
        }

        .secondary-focus {
          background: var(--surface-color);
          border: 2px solid var(--border-color);
          padding: var(--spacing-xl);
          border-radius: var(--border-radius-lg);
          box-shadow: var(--shadow-md);
        }

        .tertiary-focus {
          background: var(--background-color);
          border: 1px solid var(--border-color);
          padding: var(--spacing-md);
          border-radius: var(--border-radius-md);
          box-shadow: var(--shadow-sm);
          opacity: 0.8;
        }

        .primary-focus h2 {
          font-size: var(--font-size-2xl);
          font-weight: var(--font-weight-bold);
        }

        .secondary-focus h3 {
          font-size: var(--font-size-xl);
          font-weight: var(--font-weight-semibold);
          color: var(--text-primary);
        }

        .tertiary-focus h4 {
          font-size: var(--font-size-lg);
          font-weight: var(--font-weight-medium);
          color: var(--text-secondary);
        }
      `;
      document.head.appendChild(style);

      const primaryCard = container.querySelector('.primary-focus');
      const secondaryCard = container.querySelector('.secondary-focus');
      const tertiaryCard = container.querySelector('.tertiary-focus');

      const primaryStyle = window.getComputedStyle(primaryCard);
      const secondaryStyle = window.getComputedStyle(secondaryCard);
      const tertiaryStyle = window.getComputedStyle(tertiaryCard);

      // Primary should be most prominent
      expect(primaryStyle.backgroundColor).toBe('#0078d4'); // Happy DOM returns hex format
      expect(primaryStyle.color).toBe('white'); // Happy DOM returns keyword format
      expect(primaryStyle.transform).toBe('scale(1.02)'); // Happy DOM returns scale format

      // Secondary should be less prominent
      expect(secondaryStyle.backgroundColor).not.toBe('rgb(0, 120, 212)');
      expect(secondaryStyle.borderWidth).toBe('2px');

      // Tertiary should be least prominent
      expect(tertiaryStyle.opacity).toBe('0.8');
      expect(tertiaryStyle.borderWidth).toBe('1px');
    });
  });

  describe('Dashboard Component Visuals', () => {
    it('should apply consistent dashboard card styling', async () => {
      container.innerHTML = `
        <div class="learning-paths-dashboard">
          <div class="dashboard-header">
            <h1>Your Learning Journey</h1>
            <div class="progress-summary">
              <span class="progress-stat">3 Completed</span>
              <span class="progress-stat">2 In Progress</span>
            </div>
          </div>
          <div class="dashboard-grid">
            <div class="path-card completed">
              <h3>Azure Fundamentals</h3>
              <div class="progress-bar">
                <div class="progress-fill" style="width: 100%"></div>
              </div>
              <span class="status-badge">Completed</span>
            </div>
            <div class="path-card in-progress">
              <h3>Edge Computing</h3>
              <div class="progress-bar">
                <div class="progress-fill" style="width: 60%"></div>
              </div>
              <span class="status-badge">60% Complete</span>
            </div>
          </div>
        </div>
      `;

      const style = document.createElement('style');
      style.textContent = `
        .learning-paths-dashboard {
          max-width: 1200px;
          margin: 0 auto;
          padding: var(--spacing-xl);
        }

        .dashboard-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: var(--spacing-2xl);
          padding-bottom: var(--spacing-lg);
          border-bottom: 2px solid var(--border-color);
        }

        .dashboard-header h1 {
          font-size: var(--font-size-3xl);
          font-weight: var(--font-weight-bold);
          color: var(--text-primary);
        }

        .progress-summary {
          display: flex;
          gap: var(--spacing-lg);
        }

        .progress-stat {
          background: var(--surface-color);
          padding: var(--spacing-sm) var(--spacing-md);
          border-radius: var(--border-radius-lg);
          font-weight: var(--font-weight-medium);
          color: var(--text-secondary);
        }

        .dashboard-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
          gap: var(--spacing-xl);
        }

        .path-card {
          background: var(--background-color);
          border: 1px solid var(--border-color);
          border-radius: var(--border-radius-lg);
          padding: var(--spacing-xl);
          box-shadow: var(--shadow-sm);
          transition: transform 0.2s ease, box-shadow 0.2s ease;
        }

        .path-card:hover {
          transform: translateY(-4px);
          box-shadow: var(--shadow-lg);
        }

        .path-card h3 {
          font-size: var(--font-size-xl);
          font-weight: var(--font-weight-semibold);
          margin-bottom: var(--spacing-md);
          color: var(--text-primary);
        }

        .progress-bar {
          width: 100%;
          height: 8px;
          background: var(--border-color);
          border-radius: var(--border-radius-lg);
          margin: var(--spacing-md) 0;
          overflow: hidden;
        }

        .progress-fill {
          height: 100%;
          background: var(--primary-color);
          border-radius: var(--border-radius-lg);
          transition: width 0.3s ease;
        }

        .path-card.completed .progress-fill {
          background: var(--success-color);
        }

        .status-badge {
          display: inline-block;
          padding: var(--spacing-xs) var(--spacing-sm);
          border-radius: var(--border-radius-md);
          font-size: var(--font-size-sm);
          font-weight: var(--font-weight-medium);
          background: var(--primary-color);
          color: white;
        }

        .path-card.completed .status-badge {
          background: var(--success-color);
        }
      `;
      document.head.appendChild(style);

      const dashboard = container.querySelector('.learning-paths-dashboard');
      const pathCards = container.querySelectorAll('.path-card');
      const progressBars = container.querySelectorAll('.progress-bar');
      const statusBadges = container.querySelectorAll('.status-badge');

      const dashboardStyle = window.getComputedStyle(dashboard);
      const cardStyle = window.getComputedStyle(pathCards[0]);
      const progressBarStyle = window.getComputedStyle(progressBars[0]);

      // Dashboard should be properly centered and spaced
      expect(dashboardStyle.maxWidth).toBe('1200px');
      expect(dashboardStyle.margin).toBe('0px auto');
      expect(dashboardStyle.padding).toBe('32px'); // Happy DOM returns px format for this property

      // Cards should have consistent styling
      expect(cardStyle.backgroundColor).toBe('#ffffff'); // Happy DOM returns hex format
      expect(cardStyle.borderRadius).toBe('8px');
      expect(cardStyle.padding).toBe('32px');

      // Progress bars should be consistent
      expect(progressBarStyle.height).toBe('8px');
      expect(progressBarStyle.borderRadius).toBe('8px');
    });

    it('should maintain consistent interactive states for dashboard elements', async () => {
      container.innerHTML = `
        <div class="dashboard-actions">
          <button class="action-btn primary">Start New Path</button>
          <button class="action-btn secondary">View All Paths</button>
          <div class="filter-chips">
            <button class="chip active">All</button>
            <button class="chip">In Progress</button>
            <button class="chip">Completed</button>
          </div>
        </div>
      `;

      const style = document.createElement('style');
      style.textContent = `
        .dashboard-actions {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: var(--spacing-xl);
          flex-wrap: wrap;
          gap: var(--spacing-md);
        }

        .action-btn {
          padding: var(--spacing-sm) var(--spacing-lg);
          border-radius: var(--border-radius-md);
          font-size: var(--font-size-base);
          font-weight: var(--font-weight-medium);
          border: none;
          cursor: pointer;
          transition: all 0.2s ease;
        }

        .action-btn.primary {
          background: var(--primary-color);
          color: white;
        }

        .action-btn.primary:hover {
          background: var(--focus-color);
          transform: translateY(-1px);
        }

        .action-btn.secondary {
          background: transparent;
          color: var(--primary-color);
          border: 1px solid var(--primary-color);
        }

        .action-btn.secondary:hover {
          background: var(--primary-color);
          color: white;
        }

        .filter-chips {
          display: flex;
          gap: var(--spacing-sm);
        }

        .chip {
          padding: var(--spacing-xs) var(--spacing-md);
          border: 1px solid var(--border-color);
          background: var(--background-color);
          color: var(--text-secondary);
          border-radius: var(--border-radius-lg);
          font-size: var(--font-size-sm);
          cursor: pointer;
          transition: all 0.2s ease;
        }

        .chip:hover {
          border-color: var(--primary-color);
          color: var(--primary-color);
        }

        .chip.active {
          background: var(--primary-color);
          color: white;
          border-color: var(--primary-color);
        }
      `;
      document.head.appendChild(style);

      const primaryBtn = container.querySelector('.action-btn.primary');
      const secondaryBtn = container.querySelector('.action-btn.secondary');
      const activeChip = container.querySelector('.chip.active');
      const inactiveChip = container.querySelector('.chip:not(.active)');

      const primaryStyle = window.getComputedStyle(primaryBtn);
      const secondaryStyle = window.getComputedStyle(secondaryBtn);
      const activeChipStyle = window.getComputedStyle(activeChip);
      const inactiveChipStyle = window.getComputedStyle(inactiveChip);

      // Primary button should use primary color
      expect(primaryStyle.backgroundColor).toBe('#0078d4'); // Happy DOM returns hex format
      expect(primaryStyle.color).toBe('white'); // Happy DOM returns keyword format

      // Secondary button should be outline style
      expect(secondaryStyle.backgroundColor).toBe('transparent'); // Happy DOM returns keyword format
      expect(secondaryStyle.color).toBe('#0078d4'); // Happy DOM returns hex format
      expect(secondaryStyle.borderColor).toBe('#0078d4'); // Happy DOM returns hex format

      // Active chip should be highlighted
      expect(activeChipStyle.backgroundColor).toBe('#0078d4'); // Happy DOM returns hex format
      expect(activeChipStyle.color).toBe('white'); // Happy DOM returns keyword format

      // Inactive chip should be muted
      expect(inactiveChipStyle.backgroundColor).toBe('#ffffff');
      expect(inactiveChipStyle.color).toBe('#605e5c'); // text-secondary
    });
  });

  describe('Notification System Visuals', () => {
    it('should apply consistent notification styling and animations', async () => {
      container.innerHTML = `
        <div class="notification-container">
          <div class="notification success show">
            <div class="notification-icon">✓</div>
            <div class="notification-content">
              <h4>Success!</h4>
              <p>Assessment completed successfully</p>
            </div>
            <button class="notification-close">×</button>
          </div>
          <div class="notification warning show">
            <div class="notification-icon">⚠</div>
            <div class="notification-content">
              <h4>Warning</h4>
              <p>Please complete the prerequisites</p>
            </div>
            <button class="notification-close">×</button>
          </div>
        </div>
      `;

      const style = document.createElement('style');
      style.textContent = `
        .notification-container {
          position: fixed;
          top: var(--spacing-lg);
          right: var(--spacing-lg);
          z-index: 1000;
          max-width: 400px;
        }

        .notification {
          display: flex;
          align-items: flex-start;
          gap: var(--spacing-md);
          padding: var(--spacing-md);
          margin-bottom: var(--spacing-sm);
          border-radius: var(--border-radius-lg);
          box-shadow: var(--shadow-lg);
          border-left: 4px solid;
          background: var(--background-color);
          transform: translateX(100%);
          opacity: 0;
          transition: all 0.3s ease;
        }

        .notification.show {
          transform: translateX(0);
          opacity: 1;
        }

        .notification.success {
          border-left-color: var(--success-color);
          background: #f6ffed;
        }

        .notification.warning {
          border-left-color: var(--warning-color);
          background: #fffbe6;
        }

        .notification.error {
          border-left-color: var(--error-color);
          background: #fff2f0;
        }

        .notification-icon {
          font-size: var(--font-size-lg);
          font-weight: var(--font-weight-bold);
          min-width: 24px;
          text-align: center;
        }

        .notification.success .notification-icon {
          color: var(--success-color);
        }

        .notification.warning .notification-icon {
          color: var(--warning-color);
        }

        .notification.error .notification-icon {
          color: var(--error-color);
        }

        .notification-content h4 {
          font-size: var(--font-size-base);
          font-weight: var(--font-weight-semibold);
          margin-bottom: var(--spacing-xs);
          color: var(--text-primary);
        }

        .notification-content p {
          font-size: var(--font-size-sm);
          color: var(--text-secondary);
          margin: 0;
          line-height: var(--line-height-normal);
        }

        .notification-close {
          background: none;
          border: none;
          font-size: var(--font-size-lg);
          color: var(--text-muted);
          cursor: pointer;
          padding: 0;
          min-width: 20px;
          line-height: 1;
        }

        .notification-close:hover {
          color: var(--text-primary);
        }
      `;
      document.head.appendChild(style);

      const notifications = container.querySelectorAll('.notification');
      const successNotification = container.querySelector('.notification.success');
      const warningNotification = container.querySelector('.notification.warning');
      const notificationIcons = container.querySelectorAll('.notification-icon');

      const successStyle = window.getComputedStyle(successNotification);
      const warningStyle = window.getComputedStyle(warningNotification);
      const iconStyle = window.getComputedStyle(notificationIcons[0]);

      // Notifications should have consistent base styling
      expect(successStyle.borderRadius).toBe('8px'); // Happy DOM returns px format
      expect(successStyle.padding).toBe('16px'); // Happy DOM returns px format
      expect(successStyle.marginBottom).toBe('8px'); // Happy DOM returns px format

      // Success notification should use success colors
      expect(successStyle.borderLeftColor).toBe('#107c10'); // Happy DOM returns hex format
      expect(successStyle.backgroundColor).toBe('#f6ffed'); // Happy DOM returns hex format

      // Warning notification should use warning colors
      expect(warningStyle.borderLeftColor).toBe('#ff8c00');
      expect(warningStyle.backgroundColor).toBe('#fffbe6');

      // Icons should be properly sized
      expect(iconStyle.fontSize).toBe('18px');
      expect(iconStyle.minWidth).toBe('24px');
    });
  });
});
