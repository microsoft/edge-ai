/**
 * @file existing-progress-bar-integration.test.js
 * @description Tests for existing progress bar integration
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ExistingProgressBarIntegration } from '../existing-progress-bar-integration.js';

// Mock the managers
vi.mock('../progress-export-manager.js', () => ({
  ProgressExportManager: vi.fn().mockImplementation(() => ({
    handleSaveProgress: vi.fn().mockResolvedValue({
      success: true,
      message: 'Progress saved successfully'
    })
  }))
}));

vi.mock('../progress-clear-manager.js', () => ({
  ProgressClearManager: vi.fn().mockImplementation(() => ({
    handleClearProgress: vi.fn().mockResolvedValue({
      success: true,
      message: 'Progress cleared successfully'
    })
  }))
}));

describe('ExistingProgressBarIntegration', () => {
  let integration;
  let mockSaveButton;
  let mockResetButton;
  let mockProgressBar;

  beforeEach(() => {
    // Clear DOM
    document.body.innerHTML = '';

    // Create mock progress bar elements
    mockProgressBar = document.createElement('div');
    mockProgressBar.className = 'kata-progress-bar-container';

    const progressFill = document.createElement('div');
    progressFill.className = 'kata-progress-bar-fill';
    progressFill.style.width = '50%';

    const progressText = document.createElement('div');
    progressText.className = 'kata-progress-percentage';
    progressText.textContent = '50% Complete (5/10)';

    const progressLabel = document.createElement('div');
    progressLabel.className = 'kata-progress-label';
    progressLabel.textContent = 'Kata Progress: Ai Assisted Engineering';

    mockSaveButton = document.createElement('button');
    mockSaveButton.className = 'kata-progress-btn-save';
    mockSaveButton.textContent = '💾 Save';

    mockResetButton = document.createElement('button');
    mockResetButton.className = 'kata-progress-btn-reset';
    mockResetButton.textContent = '🔄 Reset';

    mockProgressBar.appendChild(progressFill);
    mockProgressBar.appendChild(progressText);
    mockProgressBar.appendChild(progressLabel);
    mockProgressBar.appendChild(mockSaveButton);
    mockProgressBar.appendChild(mockResetButton);

    document.body.appendChild(mockProgressBar);

    // Clear all mocks
    vi.clearAllMocks();

    // Mock window.prompt
    global.prompt = vi.fn().mockReturnValue('1'); // JSON format

    // Mock window.alert
    global.alert = vi.fn();
  });

  describe('Initialization', () => {
    it('should initialize and find existing buttons', async () => {
      integration = new ExistingProgressBarIntegration();

      // Wait for initialization
      await new Promise(resolve => setTimeout(resolve, 100));

      expect(integration.initialized).toBe(true);
      expect(integration.exportManager).toBeDefined();
      expect(integration.clearManager).toBeDefined();
    });

    it('should handle missing buttons gracefully', async () => {
      // Remove buttons
      mockSaveButton.remove();
      mockResetButton.remove();

      const consoleSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});

      integration = new ExistingProgressBarIntegration();
      await new Promise(resolve => setTimeout(resolve, 100));

      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('Save button not found')
      );
      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('Reset button not found')
      );

      consoleSpy.mockRestore();
    });
  });

  describe('Progress Data Extraction', () => {
    it('should extract current progress data correctly', async () => {
      integration = new ExistingProgressBarIntegration();
      await new Promise(resolve => setTimeout(resolve, 100));

      const progressData = integration.getCurrentProgressData();

      expect(progressData).toEqual({
        kataId: 'ai-assisted-engineering',
        completedTasks: 5,
        totalTasks: 10,
        completionPercentage: 50,
        lastUpdated: expect.any(String)
      });
    });

    it('should handle missing progress elements gracefully', async () => {
      // Remove progress elements
      document.querySelector('.kata-progress-bar-fill').remove();
      document.querySelector('.kata-progress-percentage').remove();
      document.querySelector('.kata-progress-label').remove();

      integration = new ExistingProgressBarIntegration();
      await new Promise(resolve => setTimeout(resolve, 100));

      const progressData = integration.getCurrentProgressData();

      expect(progressData).toEqual({
        kataId: 'unknown-kata',
        completedTasks: 0,
        totalTasks: 0,
        completionPercentage: 0,
        lastUpdated: expect.any(String)
      });
    });
  });

  describe('Save Button Integration', () => {
    it('should handle save button click', async () => {
      integration = new ExistingProgressBarIntegration();
      await new Promise(resolve => setTimeout(resolve, 100));

      // Mock the format selection to return JSON
      global.prompt = vi.fn().mockReturnValue('1');

      // Click save button
      mockSaveButton.click();

      // Wait for async operations
      await new Promise(resolve => setTimeout(resolve, 100));

      expect(integration.exportManager.handleSaveProgress).toHaveBeenCalledWith(
        expect.objectContaining({
          format: 'json',
          includeTimestamp: true,
          includeMetadata: true,
          progressData: expect.any(Object)
        })
      );

      expect(global.alert).toHaveBeenCalledWith('✅ Progress saved successfully!');
    });

    it('should handle save cancellation', async () => {
      integration = new ExistingProgressBarIntegration();
      await new Promise(resolve => setTimeout(resolve, 100));

      // Mock cancelled prompt
      global.prompt = vi.fn().mockReturnValue(null);

      // Click save button
      mockSaveButton.click();

      // Wait for async operations
      await new Promise(resolve => setTimeout(resolve, 100));

      expect(integration.exportManager.handleSaveProgress).not.toHaveBeenCalled();
    });
  });

  describe('Reset Button Integration', () => {
    it('should handle reset button click', async () => {
      integration = new ExistingProgressBarIntegration();
      await new Promise(resolve => setTimeout(resolve, 100));

      // Click reset button
      mockResetButton.click();

      // Wait for async operations
      await new Promise(resolve => setTimeout(resolve, 100));

      expect(integration.clearManager.handleClearProgress).toHaveBeenCalled();
      expect(global.alert).toHaveBeenCalledWith('✅ Progress cleared successfully!');
    });

    it('should handle reset cancellation', async () => {
      // Mock cancelled clear operation
      integration = new ExistingProgressBarIntegration();
      integration.clearManager.handleClearProgress = vi.fn().mockResolvedValue({
        success: false,
        cancelled: true
      });

      await new Promise(resolve => setTimeout(resolve, 100));

      // Click reset button
      mockResetButton.click();

      // Wait for async operations
      await new Promise(resolve => setTimeout(resolve, 100));

      expect(integration.clearManager.handleClearProgress).toHaveBeenCalled();
      // Should not show success message when cancelled
      expect(global.alert).not.toHaveBeenCalledWith(
        expect.stringContaining('Progress cleared successfully')
      );
    });
  });

  describe('UI Updates', () => {
    it('should update progress bar UI correctly', async () => {
      integration = new ExistingProgressBarIntegration();
      await new Promise(resolve => setTimeout(resolve, 100));

      integration.updateProgressBarUI(75);

      const progressFill = document.querySelector('.kata-progress-bar-fill');
      const progressText = document.querySelector('.kata-progress-percentage');

      expect(progressFill.style.width).toBe('75%');
      expect(progressText.textContent).toBe('75% Complete (0/0)');
    });
  });

  describe('Format Selection', () => {
    it('should show format selection dialog', async () => {
      integration = new ExistingProgressBarIntegration();
      await new Promise(resolve => setTimeout(resolve, 100));

      global.prompt = vi.fn().mockReturnValue('2'); // CSV

      const format = await integration.showFormatSelectionDialog();

      expect(format).toBe('csv');
      expect(global.prompt).toHaveBeenCalledWith(
        expect.stringContaining('Select export format'),
        '1'
      );
    });

    it('should handle invalid format selection', async () => {
      integration = new ExistingProgressBarIntegration();
      await new Promise(resolve => setTimeout(resolve, 100));

      global.prompt = vi.fn().mockReturnValue('99'); // Invalid

      const format = await integration.showFormatSelectionDialog();

      expect(format).toBe(null);
    });
  });

  describe('Cleanup', () => {
    it('should clean up properly when destroyed', async () => {
      integration = new ExistingProgressBarIntegration();
      await new Promise(resolve => setTimeout(resolve, 100));

      integration.destroy();

      expect(integration.exportManager).toBe(null);
      expect(integration.clearManager).toBe(null);
      expect(integration.initialized).toBe(false);
    });
  });
});
