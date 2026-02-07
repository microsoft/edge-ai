/**
 * @vitest-environment happy-dom
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { VSCodeIntegration } from '../../features/coach-button.js';

describe('VSCodeIntegration', () => {
  let vscodeIntegration;
  let mockWindow;
  let mockLocation;

  beforeEach(() => {
    // Mock window and location objects for VS Code environment detection
    mockLocation = {
      protocol: 'vscode-file:',
      href: 'vscode-file://vscode-app/learning/paths/README.md',
      pathname: '/learning/paths/README.md'
    };

    mockWindow = {
      location: mockLocation,
      open: vi.fn(),
      postMessage: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn()
    };

    Object.defineProperty(global, 'window', {
      value: mockWindow,
      writable: true
    });

    vscodeIntegration = new VSCodeIntegration();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('Environment Detection', () => {
    it('should detect VS Code environment correctly', () => {
      const isVSCode = vscodeIntegration.isVSCodeEnvironment();

      expect(isVSCode).toBe(true);
    });

    it('should detect non-VS Code environment', () => {
      mockWindow.location.protocol = 'https:';
      mockWindow.location.href = 'https://example.com/learning/paths';

      const isVSCode = vscodeIntegration.isVSCodeEnvironment();

      expect(isVSCode).toBe(false);
    });

    it('should handle missing window object gracefully', () => {
      Object.defineProperty(global, 'window', {
        value: undefined,
        writable: true
      });

      const isVSCode = vscodeIntegration.isVSCodeEnvironment();

      expect(isVSCode).toBe(false);
    });

    it('should detect VS Code based on user agent', () => {
      Object.defineProperty(navigator, 'userAgent', {
        value: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.74.0 Chrome/108.0.5359.215 Electron/22.3.2 Safari/537.36',
        writable: true
      });

      const isVSCode = vscodeIntegration.isVSCodeEnvironment();

      expect(isVSCode).toBe(true);
    });

    it('should detect VS Code based on global vscode object', () => {
      global.vscode = {
        commands: { executeCommand: vi.fn() },
        env: { appName: 'Visual Studio Code' }
      };

      const isVSCode = vscodeIntegration.isVSCodeEnvironment();

      expect(isVSCode).toBe(true);

      delete global.vscode;
    });
  });

  describe('Command URI Building', () => {
    it('should build correct VS Code command URI for chat panel', () => {
      const command = 'ms-vscode.vscode-copilot-chat/openChatPanel';
      const args = {
        mode: 'learning-kata-coach',
        context: {
          currentPath: 'ai-assisted-engineering',
          currentKata: '01-ai-development-fundamentals'
        }
      };

      const uri = vscodeIntegration.buildCommandUri(command, args);

      expect(uri).toBe(`vscode://${command}?${encodeURIComponent(JSON.stringify(args))}`);
    });

    it('should handle command URI without arguments', () => {
      const command = 'workbench.action.openSettings';

      const uri = vscodeIntegration.buildCommandUri(command);

      expect(uri).toBe(`vscode://${command}`);
    });

    it('should handle complex context objects in URI', () => {
      const command = 'extension.customCommand';
      const complexArgs = {
        learningPath: {
          id: 'ai-assisted-engineering',
          title: 'AI-Assisted Engineering',
          progress: {
            completed: [1, 2, 3],
            total: 10,
            percentage: 30
          }
        },
        userProfile: {
          role: 'developer',
          skillLevel: 'intermediate',
          preferences: ['hands-on', 'visual']
        },
        sessionData: {
          startTime: new Date().toISOString(),
          activities: ['kata-1', 'kata-2']
        }
      };

      const uri = vscodeIntegration.buildCommandUri(command, complexArgs);

      expect(uri).toContain('vscode://extension.customCommand?');
      expect(uri).toContain(encodeURIComponent(JSON.stringify(complexArgs)));
    });

    it('should handle special characters in command arguments', () => {
      const command = 'test.command';
      const args = {
        message: 'Hello, World! 测试 & <test>',
        path: '/path/with spaces/file.md'
      };

      const uri = vscodeIntegration.buildCommandUri(command, args);

      expect(uri).toContain('vscode://test.command?');
      expect(decodeURIComponent(uri.split('?')[1])).toBe(JSON.stringify(args));
    });
  });

  describe('Chat Panel Integration', () => {
    it('should open chat panel with learning coach mode', () => {
      const coachContext = {
        mode: 'learning-kata-coach',
        context: {
          currentPath: 'ai-assisted-engineering',
          currentKata: '01-ai-development-fundamentals',
          progressData: { completed: 3, total: 10 }
        }
      };

      vscodeIntegration.openChatWithContext(coachContext);

      expect(mockWindow.open).toHaveBeenCalledWith(
        expect.stringContaining('vscode://ms-vscode.vscode-copilot-chat/openChatPanel'),
        '_self'
      );
    });

    it('should include all coaching context in chat panel request', () => {
      const fullCoachContext = {
        mode: 'learning-kata-coach',
        context: {
          currentPath: 'ai-assisted-engineering',
          currentKata: '01-ai-development-fundamentals',
          progressData: { completed: 5, total: 12 },
          userProfile: { role: 'architect', skillLevel: 'advanced' },
          coachingHints: ['async-patterns', 'error-handling'],
          sessionId: 'session-123',
          timestamp: '2025-08-18T10:30:00Z'
        },
        preferences: {
          interactionStyle: 'socratic',
          detailLevel: 'comprehensive',
          feedbackType: 'progressive'
        }
      };

      vscodeIntegration.openChatWithContext(fullCoachContext);

      const expectedUri = vscodeIntegration.buildCommandUri(
        'ms-vscode.vscode-copilot-chat/openChatPanel',
        fullCoachContext
      );

      expect(mockWindow.open).toHaveBeenCalledWith(expectedUri, '_self');
    });

    it('should handle chat panel opening errors gracefully', () => {
      mockWindow.open.mockImplementation(() => {
        throw new Error('Failed to open VS Code command');
      });

      const coachContext = {
        mode: 'learning-kata-coach',
        context: { currentPath: 'test-path' }
      };

      expect(() => vscodeIntegration.openChatWithContext(coachContext)).not.toThrow();
    });

    it('should provide fallback when window.open is not available', () => {
      delete mockWindow.open;

      const coachContext = {
        mode: 'learning-kata-coach',
        context: { currentPath: 'test-path' }
      };

      const result = vscodeIntegration.openChatWithContext(coachContext);

      expect(result).toBe(false);
    });

    it('should support custom agents', () => {
      const customCoachContext = {
        mode: 'custom-coach-mode',
        context: {
          customData: 'test',
          specialInstructions: 'Focus on debugging'
        }
      };

      vscodeIntegration.openChatWithContext(customCoachContext);

      expect(mockWindow.open).toHaveBeenCalledWith(
        expect.stringContaining('custom-coach-mode'),
        '_self'
      );
    });
  });

  describe('Command Execution', () => {
    beforeEach(() => {
      global.vscode = {
        commands: {
          executeCommand: vi.fn()
        }
      };
    });

    afterEach(() => {
      delete global.vscode;
    });

    it('should execute VS Code commands directly when available', () => {
      const command = 'workbench.action.openSettings';
      const args = { query: 'editor.fontSize' };

      vscodeIntegration.executeCommand(command, args);

      expect(global.vscode.commands.executeCommand).toHaveBeenCalledWith(command, args);
    });

    it('should fall back to command URI when direct execution unavailable', () => {
      delete global.vscode;

      const command = 'workbench.action.openSettings';
      const args = { query: 'editor.fontSize' };

      vscodeIntegration.executeCommand(command, args);

      expect(mockWindow.open).toHaveBeenCalledWith(
        expect.stringContaining('vscode://workbench.action.openSettings'),
        '_self'
      );
    });

    it('should handle command execution errors', () => {
      global.vscode.commands.executeCommand.mockImplementation(() => {
        throw new Error('Command failed');
      });

      const command = 'test.command';

      expect(() => vscodeIntegration.executeCommand(command)).not.toThrow();
    });

    it('should support asynchronous command execution', async () => {
      global.vscode.commands.executeCommand.mockResolvedValue('command result');

      const command = 'async.command';
      const result = await vscodeIntegration.executeCommand(command);

      expect(result).toBe('command result');
      expect(global.vscode.commands.executeCommand).toHaveBeenCalledWith(command, undefined);
    });

    it('should handle command execution timeout', async () => {
      global.vscode.commands.executeCommand.mockImplementation(() => {
        return new Promise(() => {}); // Never resolves
      });

      const command = 'slow.command';
      const timeoutPromise = vscodeIntegration.executeCommandWithTimeout(command, undefined, 100);

      await expect(timeoutPromise).rejects.toThrow('Command execution timeout');
    });
  });

  describe('Coach Mode Activation', () => {
    it('should activate learning kata coach mode with correct parameters', () => {
      const learningContext = {
        currentPath: 'ai-assisted-engineering',
        currentKata: '01-ai-development-fundamentals',
        progressData: { completed: 3, total: 10 },
        userProfile: { role: 'developer', skillLevel: 'beginner' }
      };

      vscodeIntegration.activateCoachMode(learningContext);

      expect(mockWindow.open).toHaveBeenCalledWith(
        expect.stringContaining('learning-kata-coach'),
        '_self'
      );
    });

    it('should include starter message for coach activation', () => {
      const learningContext = {
        currentPath: 'ai-assisted-engineering',
        currentKata: '01-ai-development-fundamentals'
      };

      const starterMessage = 'I need help with AI development fundamentals';

      vscodeIntegration.activateCoachMode(learningContext, starterMessage);

      const calledUri = mockWindow.open.mock.calls[0][0];
      expect(calledUri).toContain(encodeURIComponent(starterMessage));
    });

    it('should handle different coach mode types', () => {
      const coachModes = [
        'learning-kata-coach',
        'project-planning-coach',
        'troubleshooting-coach'
      ];

      coachModes.forEach(mode => {
        const context = { currentPath: 'test' };
        vscodeIntegration.activateCoachMode(context, null, mode);

        expect(mockWindow.open).toHaveBeenCalledWith(
          expect.stringContaining(mode),
          '_self'
        );
      });
    });

    it('should provide context-aware starter messages', () => {
      const contexts = [
        {
          currentPath: 'ai-assisted-engineering',
          expectedMessage: expect.stringContaining('AI-assisted engineering')
        },
        {
          currentPath: 'project-planning',
          expectedMessage: expect.stringContaining('project planning')
        },
        {
          currentKata: '01-basic-prompts',
          expectedMessage: expect.stringContaining('basic prompts')
        }
      ];

      contexts.forEach(({ currentPath, currentKata, expectedMessage }) => {
        const context = { currentPath, currentKata };
        const message = vscodeIntegration.generateContextualStarterMessage(context);

        expect(message).toEqual(expectedMessage);
      });
    });

    it('should handle activation without learning context', () => {
      vscodeIntegration.activateCoachMode();

      expect(mockWindow.open).toHaveBeenCalledWith(
        expect.stringContaining('learning-kata-coach'),
        '_self'
      );
    });
  });

  describe('Context Information Passing', () => {
    it('should pass comprehensive learning path information', () => {
      const comprehensiveContext = {
        learningPath: {
          id: 'ai-assisted-engineering',
          title: 'AI-Assisted Engineering',
          description: 'Master AI-assisted development',
          estimatedDuration: '4 hours',
          difficulty: 'intermediate'
        },
        currentKata: {
          id: '01-ai-development-fundamentals',
          title: 'AI Development Fundamentals',
          progress: 60,
          timeSpent: 45,
          completedTasks: ['task1', 'task2', 'task3']
        },
        userProgress: {
          overallCompletion: 30,
          katasCompleted: 3,
          totalKatas: 10,
          skillAssessments: {
            'prompt-engineering': 'intermediate',
            'code-review': 'beginner'
          }
        },
        sessionInfo: {
          startTime: '2025-08-18T10:00:00Z',
          lastActivity: '2025-08-18T10:45:00Z',
          interactionCount: 15
        }
      };

      vscodeIntegration.openChatWithContext({
        mode: 'learning-kata-coach',
        context: comprehensiveContext
      });

      const calledUri = mockWindow.open.mock.calls[0][0];
      const decodedContext = JSON.parse(
        decodeURIComponent(calledUri.split('?')[1])
      );

      expect(decodedContext.context).toEqual(comprehensiveContext);
    });

    it('should include performance and analytics data', () => {
      const analyticsContext = {
        currentPath: 'ai-assisted-engineering',
        analytics: {
          timeSpentByKata: {
            'kata-1': 300, // 5 minutes
            'kata-2': 600 // 10 minutes
          },
          difficultyRatings: {
            'kata-1': 3,
            'kata-2': 4
          },
          helpRequestsCount: 2,
          commonStuckPoints: ['async-patterns', 'error-handling'],
          learningVelocity: 'fast'
        }
      };

      vscodeIntegration.openChatWithContext({
        mode: 'learning-kata-coach',
        context: analyticsContext
      });

      const calledUri = mockWindow.open.mock.calls[0][0];
      expect(calledUri).toContain(encodeURIComponent('analytics'));
    });

    it('should handle context data sanitization', () => {
      const contextWithSensitiveData = {
        currentPath: 'test-path',
        userInfo: {
          email: 'user@example.com',
          apiKey: 'secret-key-123',
          password: 'password123'
        },
        safeData: {
          role: 'developer',
          skillLevel: 'intermediate'
        }
      };

      const sanitizedContext = vscodeIntegration.sanitizeContext(contextWithSensitiveData);

      expect(sanitizedContext).not.toHaveProperty('userInfo.email');
      expect(sanitizedContext).not.toHaveProperty('userInfo.apiKey');
      expect(sanitizedContext).not.toHaveProperty('userInfo.password');
      expect(sanitizedContext.safeData).toEqual(contextWithSensitiveData.safeData);
    });

    it('should handle large context objects efficiently', () => {
      const largeContext = {
        currentPath: 'test-path',
        detailedHistory: Array.from({ length: 1000 }, (_, i) => ({
          id: i,
          action: `action-${i}`,
          timestamp: new Date().toISOString(),
          data: `data-${i}`.repeat(100)
        }))
      };

      const optimizedContext = vscodeIntegration.optimizeContextForTransfer(largeContext);

      expect(JSON.stringify(optimizedContext).length).toBeLessThan(
        JSON.stringify(largeContext).length
      );
      expect(optimizedContext.currentPath).toBe('test-path');
    });
  });

  describe('Error Handling and Fallbacks', () => {
    it('should handle VS Code command URI scheme errors', () => {
      mockWindow.open.mockImplementation(() => {
        throw new Error('Protocol not supported');
      });

      const result = vscodeIntegration.openChatWithContext({
        mode: 'learning-kata-coach',
        context: { currentPath: 'test' }
      });

      expect(result).toBe(false);
    });

    it('should provide graceful degradation when VS Code unavailable', () => {
      mockWindow.location.protocol = 'https:';

      const result = vscodeIntegration.activateCoachMode({
        currentPath: 'test-path'
      });

      expect(result).toEqual({
        success: false,
        reason: 'VS Code environment not detected',
        fallbackSuggestion: 'Open this content in VS Code for full coach integration'
      });
    });

    it('should handle JSON serialization errors', () => {
      const circularContext = {};
      circularContext.self = circularContext; // Creates circular reference

      const result = vscodeIntegration.openChatWithContext({
        mode: 'learning-kata-coach',
        context: circularContext
      });

      expect(result).toBe(false);
    });

    it('should validate command parameters before execution', () => {
      const invalidCommands = [
        null,
        undefined,
        '',
        'invalid/command/with/too/many/slashes',
        'command with spaces'
      ];

      invalidCommands.forEach(command => {
        const result = vscodeIntegration.executeCommand(command);
        expect(result).toBe(false);
      });
    });

    it('should handle network timeouts gracefully', async () => {
      // Mock a network timeout scenario
      mockWindow.open.mockImplementation(() => {
        return new Promise((resolve, reject) => {
          setTimeout(() => reject(new Error('Network timeout')), 100);
        });
      });

      const result = await vscodeIntegration.executeCommandWithTimeout(
        'slow.network.command',
        {},
        50
      );

      expect(result).toBe(false);
    });
  });

  describe('Integration Testing Scenarios', () => {
    it('should support end-to-end coach activation workflow', () => {
      // Simulate complete workflow: detection -> context gathering -> activation
      expect(vscodeIntegration.isVSCodeEnvironment()).toBe(true);

      const learningContext = {
        currentPath: 'ai-assisted-engineering',
        currentKata: '01-ai-development-fundamentals',
        progressData: { completed: 3, total: 10 }
      };

      const starterMessage = vscodeIntegration.generateContextualStarterMessage(learningContext);
      expect(starterMessage).toContain('AI development fundamentals');

      vscodeIntegration.activateCoachMode(learningContext, starterMessage);
      expect(mockWindow.open).toHaveBeenCalled();
    });

    it('should handle multiple coach sessions', () => {
      const sessions = [
        { path: 'ai-assisted-engineering', kata: '01-fundamentals' },
        { path: 'project-planning', kata: '02-advanced-planning' },
        { path: 'troubleshooting', kata: '03-debugging' }
      ];

      sessions.forEach(session => {
        vscodeIntegration.activateCoachMode({
          currentPath: session.path,
          currentKata: session.kata
        });
      });

      expect(mockWindow.open).toHaveBeenCalledTimes(sessions.length);
    });

    it('should maintain session state across interactions', () => {
      const sessionId = 'session-123';

      vscodeIntegration.setSessionId(sessionId);

      vscodeIntegration.activateCoachMode({
        currentPath: 'test-path'
      });

      const calledUri = mockWindow.open.mock.calls[0][0];
      expect(calledUri).toContain(sessionId);
    });

    it('should support batch context updates', () => {
      const contextUpdates = [
        { type: 'progress', data: { completed: 4, total: 10 } },
        { type: 'skill', data: { level: 'intermediate' } },
        { type: 'preference', data: { style: 'visual' } }
      ];

      const batchContext = vscodeIntegration.buildBatchContext(contextUpdates);

      expect(batchContext).toEqual(expect.objectContaining({
        progress: { completed: 4, total: 10 },
        skill: { level: 'intermediate' },
        preference: { style: 'visual' }
      }));
    });
  });
});
