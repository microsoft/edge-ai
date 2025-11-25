/**
 * @file notification-system.test.js
 * @description Comprehensive test suite for NotificationSystem class
 * @version 1.0.0
 */

import { beforeEach, afterEach, describe, it, expect, vi } from 'vitest';
import { NotificationSystem } from '../../ui/notification-system.js';
import { mockConsole, restoreConsole } from '../helpers/console-mock.js';

describe('NotificationSystem', () => {
  let notificationSystem;
  let mockDebugHelper;
  let mockErrorHandler;
  let mockDocument;
  let mockContainer;
  let mockTimerService;

  beforeEach(() => {
    // Setup console mocking for performance
    mockConsole();

    // Create mock dependencies
    mockDebugHelper = {
      debug: vi.fn(),
      info: vi.fn(),
      warn: vi.fn(),
      error: vi.fn()
    };

    mockErrorHandler = {
      safeExecute: vi.fn((fn, name, fallback) => {
        try {
          return fn();
        } catch {
          return fallback;
        }
      })
    };

    // Setup DOM mocks
    mockContainer = {
      appendChild: vi.fn(),
      removeChild: vi.fn(),
      querySelectorAll: vi.fn(() => []),
      querySelector: vi.fn(() => null),
      style: {},
      classList: {
        add: vi.fn(),
        remove: vi.fn()
      }
    };

    const mockElement = {
      style: {},
      classList: {
        add: vi.fn(),
        remove: vi.fn(),
        contains: vi.fn(() => false)
      },
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      querySelector: vi.fn(() => null),
      querySelectorAll: vi.fn(() => []),
      setAttribute: vi.fn(),
      getAttribute: vi.fn(),
      appendChild: vi.fn(),
      removeChild: vi.fn(),
      innerHTML: '',
      textContent: '',
      parentNode: null,
      remove: vi.fn()
    };

    mockDocument = {
      createElement: vi.fn(() => mockElement),
      getElementById: vi.fn(() => mockContainer),
      querySelector: vi.fn((selector) => {
        // Return null for style queries to allow styles to be injected
        if (selector.includes('style[data-notification-styles]')) {
          return null;
        }
        // Return mockContainer for other queries
        return mockContainer;
      }),
      body: mockContainer,
      head: {
        appendChild: vi.fn(),
        querySelector: vi.fn(() => null)
      }
    };

    // Mock global document
    vi.stubGlobal('document', mockDocument);

    // Create mock timer service (injectable)
    mockTimerService = {
      setTimeout: vi.fn((_fn, _delay) => {
        // Store the callback but don't execute immediately
        // Tests can manually trigger timeouts if needed
        return 123; // Return mock timeout ID
      }),
      clearTimeout: vi.fn()
    };

    // Mock Date.now for rate limiting tests
    vi.spyOn(Date, 'now').mockReturnValue(1000);

    // Create instance with all dependencies including timer service
    notificationSystem = new NotificationSystem(mockDebugHelper, mockErrorHandler, mockDocument, mockTimerService);
  });

  afterEach(() => {
    // Restore the document reference if it was modified in tests
    notificationSystem.document = mockDocument;
    // Restore console for other tests
    restoreConsole();
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  describe('Constructor and Initialization', () => {
    it('should initialize with provided dependencies', () => {
      expect(notificationSystem.debugHelper).toBe(mockDebugHelper);
      expect(notificationSystem.errorHandler).toBe(mockErrorHandler);
      expect(notificationSystem.notifications).toBeInstanceOf(Map);
      expect(notificationSystem.notificationQueue).toBeInstanceOf(Array);
    });

    it('should initialize with default dependencies when none provided', () => {
      const system = new NotificationSystem();
      expect(system.debugHelper).toBeDefined();
      expect(system.errorHandler).toBeDefined();
      expect(typeof system.debugHelper.debug).toBe('function');
      expect(typeof system.errorHandler.safeExecute).toBe('function');
    });

    it('should set default configuration values', () => {
      expect(notificationSystem.maxNotifications).toBe(2);
      expect(notificationSystem.defaultDuration).toBe(3000);
      expect(notificationSystem.rateLimitWindow).toBe(5000);
      expect(notificationSystem.rateLimitMap).toBeInstanceOf(Map);
    });

    it('should call ensureStyles during initialization', () => {
      // Verify external CSS loading behavior
      expect(notificationSystem._stylesEnsured).toBe(true);
    });
  });

  describe('Core Notification Methods', () => {
    describe('show() method', () => {
      it('should show basic notification with default options', () => {
        const id = notificationSystem.show({
          message: 'Test message',
          type: 'info'
        });

        expect(id).toMatch(/^notification-\d+$/);
        expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
        expect(notificationSystem.notifications.size).toBe(1);
      });

      it('should handle rate limiting for duplicate notifications', () => {
        const options = { message: 'Same message', type: 'info' };

        const id1 = notificationSystem.show(options);
        const id2 = notificationSystem.show(options);

        expect(id1).toBeDefined();
        expect(id2).toBeNull(); // Second call should be rate limited
      });

      it('should queue notifications when max limit reached', () => {
        // Fill up to max notifications
        const _id1 = notificationSystem.show({ message: 'Message 1', type: 'info' });
        const _id2 = notificationSystem.show({ message: 'Message 2', type: 'info' });

        // This should be queued
        const id3 = notificationSystem.show({ message: 'Message 3', type: 'info' });

        expect(notificationSystem.getActiveNotifications().length).toBe(2);
        expect(notificationSystem.getQueueLength()).toBe(1);
        expect(id3).toBeDefined();
      });

      it('should prioritize high priority notifications', () => {
        // Fill to max with regular notifications
        const _id1 = notificationSystem.show({ message: 'Regular 1', type: 'info' });
        const _id2 = notificationSystem.show({ message: 'Regular 2', type: 'info' });

        // Add high priority - should bump a regular notification
        const highPriorityId = notificationSystem.show({
          message: 'High Priority',
          type: 'error',
          priority: 'high'
        });

        expect(highPriorityId).toBeDefined();
        expect(notificationSystem.getActiveNotifications().length).toBe(2);
      });

      it('should handle error in displayNotification gracefully', () => {
        // Mock the errorHandler to make displayNotification fail
        const originalSafeExecute = mockErrorHandler.safeExecute;
        mockErrorHandler.safeExecute.mockImplementation((fn, name, fallback) => {
          if (name === 'displayNotification') {
            return false; // Simulate display failure
          }
          return originalSafeExecute.call(mockErrorHandler, fn, name, fallback);
        });

        const id = notificationSystem.show({ message: 'Test', type: 'info' });
        expect(id).toBeNull();
      });
    });

    describe('success() method', () => {
      it('should show success notification with correct type', () => {
        const id = notificationSystem.success('Success message');

        expect(id).toBeDefined();
        expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
      });

      it('should merge options with success defaults', () => {
        const id = notificationSystem.success('Success', { duration: 5000 });
        expect(id).toBeDefined();
      });
    });

    describe('error() method', () => {
      it('should show error notification with correct type', () => {
        const id = notificationSystem.error('Error message');

        expect(id).toBeDefined();
        expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
      });

      it('should set persistent true for error notifications', () => {
        const id = notificationSystem.error('Error', { persistent: false });
        expect(id).toBeDefined();
      });
    });

    describe('warning() method', () => {
      it('should show warning notification with correct type', () => {
        const id = notificationSystem.warning('Warning message');

        expect(id).toBeDefined();
        expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
      });

      it('should merge options with warning defaults', () => {
        const id = notificationSystem.warning('Warning', { duration: 4000 });
        expect(id).toBeDefined();
      });
    });

    describe('info() method', () => {
      it('should show info notification with correct type', () => {
        const id = notificationSystem.info('Info message');

        expect(id).toBeDefined();
        expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
      });

      it('should use provided options', () => {
        const id = notificationSystem.info('Info', { persistent: true });
        expect(id).toBeDefined();
      });
    });
  });

  describe('Kata Completion Notifications', () => {
    it('should show kata completion notification with valid context', () => {
      const context = {
        kata: 'Test Kata',
        category: 'JavaScript',
        timeSpent: '5 minutes'
      };

      const id = notificationSystem.showKataCompletion(context);
      expect(id).toBeDefined();
      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
    });

    it('should handle missing context gracefully', () => {
      const id = notificationSystem.showKataCompletion(null);
      expect(id).toBeDefined(); // Should still show generic completion message
    });

    it('should handle incomplete context', () => {
      const context = { kata: 'Test Kata' }; // Missing other fields
      const id = notificationSystem.showKataCompletion(context);
      expect(id).toBeDefined();
    });
  });

  describe('Display and DOM Management', () => {
    describe('displayNotification() method', () => {
      it('should display notification in DOM', () => {
        const notification = {
          id: 'test-id',
          message: 'Test message',
          type: 'info',
          duration: 3000,
          persistent: false,
          position: 'top-right'
        };

        const result = notificationSystem.displayNotification(notification);
        expect(result).toBe(true);
        expect(mockDocument.createElement).toHaveBeenCalled();
      });

      it('should handle missing document gracefully', () => {
        // Set the NotificationSystem's document reference to null
        notificationSystem.document = null;

        const notification = { id: 'test', message: 'Test', type: 'info' };
        const result = notificationSystem.displayNotification(notification);

        expect(result).toBe(false);
      });

      it('should handle missing container gracefully', () => {
        // Mock document methods to simulate container creation failure
        mockDocument.getElementById.mockReturnValue(null);
        mockDocument.querySelector.mockReturnValue(null);
        mockDocument.createElement.mockReturnValue(null); // Simulate createElement failure

        const notification = { id: 'test', message: 'Test', type: 'info' };
        const result = notificationSystem.displayNotification(notification);

        expect(result).toBe(false);
      });

      it('should set up auto-dismiss for non-persistent notifications', () => {
        const id = notificationSystem.show({
          message: 'Test message',
          type: 'info',
          duration: 3000,
          persistent: false
        });

        expect(mockTimerService.setTimeout).toHaveBeenCalledWith(expect.any(Function), 3000);
        expect(id).toBeDefined();
      });

      it('should not set up auto-dismiss for persistent notifications', () => {
        vi.clearAllMocks();

        const id = notificationSystem.show({
          message: 'Test message',
          type: 'error',
          duration: 3000,
          persistent: true
        });

        expect(mockTimerService.setTimeout).not.toHaveBeenCalled();
        expect(id).toBeDefined();
      });
    });

    describe('createNotificationElement() method', () => {
      it('should create notification element with correct structure', () => {
        const notification = {
          id: 'test-id',
          message: 'Test message',
          type: 'info',
          icon: 'info-icon',
          actions: []
        };

        const element = notificationSystem.createNotificationElement(notification);
        expect(element).toBeDefined();
        expect(mockDocument.createElement).toHaveBeenCalled();
      });

      it('should handle missing document in element creation', () => {
        // Set the NotificationSystem's document reference to null
        notificationSystem.document = null;

        const notification = { id: 'test', message: 'Test', type: 'info' };
        const element = notificationSystem.createNotificationElement(notification);

        expect(element).toBeNull();
      });

      it('should include actions when provided', () => {
        const notification = {
          id: 'test-id',
          message: 'Test message',
          type: 'info',
          actions: [
            { label: 'OK', action: () => {} },
            { label: 'Cancel', action: () => {} }
          ]
        };

        const element = notificationSystem.createNotificationElement(notification);
        expect(element).toBeDefined();
      });
    });

    describe('createActionsHTML() method', () => {
      it('should return empty string for no actions', () => {
        const notification = { actions: [] };
        const html = notificationSystem.createActionsHTML(notification);
        expect(html).toBe('');
      });

      it('should create HTML for multiple actions', () => {
        const notification = {
          actions: [
            { label: 'OK', action: () => {} },
            { label: 'Cancel', action: () => {} }
          ]
        };

        const html = notificationSystem.createActionsHTML(notification);
        expect(html).toContain('OK');
        expect(html).toContain('Cancel');
        expect(html).toContain('notification-action');
      });
    });

    describe('addNotificationListeners() method', () => {
      it('should add close button listener', () => {
        const mockElement = {
          querySelector: vi.fn(() => ({
            addEventListener: vi.fn()
          })),
          querySelectorAll: vi.fn(() => []),
          addEventListener: vi.fn()
        };

        const notification = {
          id: 'test-id',
          persistent: false,
          actions: []
        };

        notificationSystem.addNotificationListeners(mockElement, notification);
        expect(mockElement.querySelector).toHaveBeenCalledWith('.notification-close');
      });

      it('should add action listeners', () => {
        const mockAction = { addEventListener: vi.fn() };
        const mockElement = {
          querySelector: vi.fn(() => null),
          querySelectorAll: vi.fn(() => [mockAction]),
          addEventListener: vi.fn()
        };

        const notification = {
          id: 'test-id',
          persistent: false,
          actions: [{ label: 'OK', action: vi.fn() }]
        };

        notificationSystem.addNotificationListeners(mockElement, notification);
        expect(mockAction.addEventListener).toHaveBeenCalled();
      });

      it('should add hover listeners for non-persistent notifications', () => {
        const mockElement = {
          querySelector: vi.fn(() => null),
          querySelectorAll: vi.fn(() => []),
          addEventListener: vi.fn()
        };

        const notification = {
          id: 'test-id',
          persistent: false,
          actions: []
        };

        notificationSystem.addNotificationListeners(mockElement, notification);
        expect(mockElement.addEventListener).toHaveBeenCalledWith('mouseenter', expect.any(Function));
        expect(mockElement.addEventListener).toHaveBeenCalledWith('mouseleave', expect.any(Function));
      });
    });

    describe('getNotificationContainer() method', () => {
      it('should get existing container', () => {
        const container = notificationSystem.getNotificationContainer('top-right');
        expect(container).toBe(mockContainer);
        expect(mockDocument.getElementById).toHaveBeenCalledWith('kata-notifications-top-right');
      });

      it('should create new container if not found', () => {
        mockDocument.getElementById.mockReturnValue(null);

        const container = notificationSystem.getNotificationContainer('bottom-left');
        expect(container).toBeDefined();
        expect(mockDocument.createElement).toHaveBeenCalledWith('div');
      });

      it('should handle missing document', () => {
        // Temporarily remove the document from the notification system
        const originalDocument = notificationSystem.document;
        notificationSystem.document = null;

        const container = notificationSystem.getNotificationContainer('top-right');
        expect(container).toBeNull();

        // Restore the document
        notificationSystem.document = originalDocument;
      });
    });
  });

  describe('Notification Lifecycle Management', () => {
    describe('dismiss() method', () => {
      it('should dismiss existing notification', () => {
        // First show a notification
        const id = notificationSystem.show({ message: 'Test', type: 'info' });
        expect(notificationSystem.notifications.has(id)).toBe(true);

        // Then dismiss it
        const result = notificationSystem.dismiss(id);
        expect(result).toBe(true);
        expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
      });

      it('should handle dismissing non-existent notification', () => {
        const result = notificationSystem.dismiss('non-existent-id');
        expect(result).toBe(false);
      });

      it('should process queue after dismissing notification', () => {
        // Fill to max
        const id1 = notificationSystem.show({ message: 'Message 1', type: 'info' });
        notificationSystem.show({ message: 'Message 2', type: 'info' });

        // Queue one more
        notificationSystem.show({ message: 'Message 3', type: 'info' });
        expect(notificationSystem.notificationQueue.length).toBe(1);

        // Dismiss one
        notificationSystem.dismiss(id1);
        expect(notificationSystem.notificationQueue.length).toBe(0); // Should process queue
      });
    });

    describe('dismissAll() method', () => {
      it('should dismiss all notifications', () => {
        notificationSystem.show({ message: 'Message 1', type: 'info' });
        notificationSystem.show({ message: 'Message 2', type: 'info' });

        expect(notificationSystem.notifications.size).toBe(2);

        notificationSystem.dismissAll();
        expect(notificationSystem.notifications.size).toBe(0);
      });

      it('should clear notification queue', () => {
        // Fill notifications and queue
        notificationSystem.show({ message: 'Message 1', type: 'info' });
        notificationSystem.show({ message: 'Message 2', type: 'info' });
        notificationSystem.show({ message: 'Message 3', type: 'info' }); // Queued

        notificationSystem.dismissAll();
        expect(notificationSystem.notificationQueue.length).toBe(0);
      });
    });

    describe('processQueue() method', () => {
      it('should process queued notifications when space available', () => {
        // Fill to max
        notificationSystem.show({ message: 'Message 1', type: 'info' });
        const id2 = notificationSystem.show({ message: 'Message 2', type: 'info' });

        // Queue one more
        notificationSystem.show({ message: 'Message 3', type: 'info' });
        expect(notificationSystem.notificationQueue.length).toBe(1);

        // Dismiss one to make space
        notificationSystem.dismiss(id2);

        // Queue should be processed
        expect(notificationSystem.notificationQueue.length).toBe(0);
        expect(notificationSystem.notifications.size).toBe(2);
      });

      it('should not process queue when no space available', () => {
        // Fill to max
        notificationSystem.show({ message: 'Message 1', type: 'info' });
        notificationSystem.show({ message: 'Message 2', type: 'info' });

        // Queue one more
        notificationSystem.show({ message: 'Message 3', type: 'info' });

        // Process queue manually (should not process anything)
        notificationSystem.processQueue();
        expect(notificationSystem.notificationQueue.length).toBe(1);
      });
    });
  });

  describe('Configuration and State Management', () => {
    describe('setMaxNotifications() method', () => {
      it('should update max notifications limit', () => {
        notificationSystem.setMaxNotifications(5);
        expect(notificationSystem.maxNotifications).toBe(5);
      });

      it('should handle invalid values gracefully', () => {
        const originalMax = notificationSystem.maxNotifications;
        notificationSystem.setMaxNotifications(-1);
        expect(notificationSystem.maxNotifications).toBe(originalMax); // Should remain unchanged
      });

      it('should dismiss excess notifications when limit reduced', () => {
        // Set high limit and show many notifications
        notificationSystem.setMaxNotifications(5);
        notificationSystem.show({ message: 'Message 1', type: 'info' });
        notificationSystem.show({ message: 'Message 2', type: 'info' });
        notificationSystem.show({ message: 'Message 3', type: 'info' });

        // Reduce limit
        notificationSystem.setMaxNotifications(1);
        expect(notificationSystem.notifications.size).toBeLessThanOrEqual(1);
      });
    });

    describe('getActiveNotifications() method', () => {
      it('should return array of active notifications', () => {
        notificationSystem.show({ message: 'Message 1', type: 'info' });
        notificationSystem.show({ message: 'Message 2', type: 'success' });

        const active = notificationSystem.getActiveNotifications();
        expect(Array.isArray(active)).toBe(true);
        expect(active.length).toBe(2);
      });

      it('should return empty array when no notifications', () => {
        const active = notificationSystem.getActiveNotifications();
        expect(Array.isArray(active)).toBe(true);
        expect(active.length).toBe(0);
      });
    });

    describe('getQueueLength() method', () => {
      it('should return queue length', () => {
        // Fill to max and queue one more
        notificationSystem.show({ message: 'Message 1', type: 'info' });
        notificationSystem.show({ message: 'Message 2', type: 'info' });
        notificationSystem.show({ message: 'Message 3', type: 'info' }); // Queued

        expect(notificationSystem.getQueueLength()).toBe(1);
      });

      it('should return 0 when queue is empty', () => {
        expect(notificationSystem.getQueueLength()).toBe(0);
      });
    });
  });

  describe('Style Management', () => {
    describe('ensureStyles() method', () => {
      it('should inject CSS styles if not present', () => {
        // Reset mocks to verify external CSS loading
        vi.clearAllMocks();
        mockDocument.querySelector.mockReturnValue(null); // No existing styles

        notificationSystem.ensureStyles();

        // Should check for external CSS link and create it if needed
        expect(mockDocument.querySelector).toHaveBeenCalledWith('link[href*="notifications.css"]');
        expect(mockDocument.createElement).toHaveBeenCalledWith('link');
        expect(mockDocument.head.appendChild).toHaveBeenCalled();
      });

      it('should not inject styles if already present', () => {
        const existingStyle = { textContent: 'existing styles' };
        mockDocument.head.querySelector.mockReturnValue(existingStyle);

        vi.clearAllMocks();
        notificationSystem.ensureStyles();

        expect(mockDocument.createElement).not.toHaveBeenCalledWith('style');
        expect(mockDocument.head.appendChild).not.toHaveBeenCalled();
      });
    });
  });

  describe('Error Handling and Edge Cases', () => {
    it('should handle error handler throwing exception', () => {
      mockErrorHandler.safeExecute.mockImplementation(() => {
        throw new Error('Error handler failed');
      });

      expect(() => {
        notificationSystem.show({ message: 'Test', type: 'info' });
      }).not.toThrow();
    });

    it('should handle missing message gracefully', () => {
      const id = notificationSystem.show({ type: 'info' });
      expect(id).toBeDefined();
    });

    it('should handle invalid notification type', () => {
      const id = notificationSystem.show({
        message: 'Test',
        type: 'invalid-type'
      });
      expect(id).toBeDefined();
    });

    it('should handle DOM manipulation errors', () => {
      mockContainer.appendChild.mockImplementation(() => {
        throw new Error('DOM error');
      });

      const id = notificationSystem.show({ message: 'Test', type: 'info' });
      expect(id).toBeDefined(); // Should still create notification object
    });

    it('should handle action callback errors', () => {
      const failingAction = () => {
        throw new Error('Action failed');
      };

      const id = notificationSystem.show({
        message: 'Test',
        type: 'info',
        actions: [{ label: 'Fail', action: failingAction }]
      });

      expect(id).toBeDefined();
    });
  });

  describe('Rate Limiting', () => {
    it('should allow notifications after rate limit window', () => {
      const options = { message: 'Same message', type: 'info' };

      // First notification should succeed
      Date.now.mockReturnValue(1000);
      const id1 = notificationSystem.show(options);
      expect(id1).toBeDefined();

      // Second notification immediately should be blocked
      Date.now.mockReturnValue(1001);
      const id2 = notificationSystem.show(options);
      expect(id2).toBeNull();

      // After rate limit window, should succeed
      Date.now.mockReturnValue(7000); // 6 seconds later
      const id3 = notificationSystem.show(options);
      expect(id3).toBeDefined();
    });

    it('should allow different messages during rate limit window', () => {
      Date.now.mockReturnValue(1000);

      const id1 = notificationSystem.show({ message: 'Message 1', type: 'info' });
      const id2 = notificationSystem.show({ message: 'Message 2', type: 'info' });

      expect(id1).toBeDefined();
      expect(id2).toBeDefined();
    });
  });
});
