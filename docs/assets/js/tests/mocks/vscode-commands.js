/**
 * Mock VS Code Commands for Testing
 * Provides mock implementations of VS Code command execution and integration APIs
 *
 * @module VSCodeCommandsMock
 * @author Edge AI Team
 * @version 1.0.0
 */

import { vi } from 'vitest';

/**
 * Create mock VS Code commands API for testing
 * @returns {Object} Mock VS Code commands object
 */
export function createMockVSCodeCommands() {
  const mockCommands = {
    // Command execution tracking
    executedCommands: [],
    commandResults: new Map(),

    /**
     * Mock VS Code command execution
     * @param {string} command - Command to execute
     * @param {...any} args - Command arguments
     * @returns {Promise<any>} Mock command result
     */
    executeCommand: vi.fn(async (command, ...args) => {
      mockCommands.executedCommands.push({ command, args, timestamp: Date.now() });

      // Return predefined results for specific commands
      if (mockCommands.commandResults.has(command)) {
        return mockCommands.commandResults.get(command);
      }

      // Default behavior for common VS Code commands
      switch (command) {
        case 'ms-vscode.vscode-copilot-chat/openChatPanel':
          return { success: true, panelOpened: true };

        case 'workbench.action.openSettings':
          return { success: true, settingsOpened: true };

        case 'workbench.action.showCommands':
          return { success: true, commandPaletteOpened: true };

        case 'editor.action.formatDocument':
          return { success: true, documentFormatted: true };

        default:
          return { success: true, command, args };
      }
    }),

    /**
     * Set predefined result for a command
     * @param {string} command - Command name
     * @param {any} result - Result to return
     */
    setCommandResult: (command, result) => {
      mockCommands.commandResults.set(command, result);
    },

    /**
     * Get execution history for a specific command
     * @param {string} command - Command name
     * @returns {Array} Execution history
     */
    getCommandHistory: (command) => {
      return mockCommands.executedCommands.filter(exec => exec.command === command);
    },

    /**
     * Clear command execution history
     */
    clearHistory: () => {
      mockCommands.executedCommands = [];
    },

    /**
     * Check if VS Code environment is available
     * @returns {boolean} True if VS Code environment detected
     */
    isVSCodeEnvironment: vi.fn(() => {
      return typeof window !== 'undefined' &&
             (window.location?.protocol === 'vscode-file:' ||
              navigator?.userAgent?.includes('Code') ||
              typeof global?.vscode !== 'undefined');
    }),

    /**
     * Build VS Code command URI
     * @param {string} command - Command identifier
     * @param {Object} args - Command arguments
     * @returns {string} VS Code command URI
     */
    buildCommandUri: vi.fn((command, args) => {
      if (!command) {
        throw new Error('Command is required');
      }

      const baseUri = `vscode://${command}`;

      if (!args) {
        return baseUri;
      }

      try {
        const argsString = encodeURIComponent(JSON.stringify(args));
        return `${baseUri}?${argsString}`;
      } catch {
        return baseUri;
      }
    }),

    /**
     * Open chat panel with context
     * @param {Object} context - Chat context
     * @returns {boolean} Success status
     */
    openChatWithContext: vi.fn((context) => {
      try {
        const uri = mockCommands.buildCommandUri(
          'ms-vscode.vscode-copilot-chat/openChatPanel',
          context
        );

        // Mock window.open call
        if (typeof window !== 'undefined' && window.open) {
          window.open(uri, '_self');
          return true;
        }

        // Mock direct command execution
        return mockCommands.executeCommand(
          'ms-vscode.vscode-copilot-chat/openChatPanel',
          context
        );
      } catch {
        return false;
      }
    }),

    /**
     * Activate specific coach mode
     * @param {string} mode - Coach mode to activate
     * @param {Object} context - Learning context
     * @returns {boolean} Success status
     */
    activateCoachMode: vi.fn((mode = 'learning-kata-coach', context = {}) => {
      const coachContext = {
        mode,
        context,
        timestamp: new Date().toISOString()
      };

      return mockCommands.openChatWithContext(coachContext);
    }),

    /**
     * Mock VS Code environment detection based on various signals
     * @returns {Object} Environment detection details
     */
    detectEnvironment: vi.fn(() => {
      const signals = {
        protocol: typeof window !== 'undefined' ? window.location?.protocol : null,
        userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : null,
        vscodeGlobal: typeof global?.vscode !== 'undefined',
        electronApp: typeof process !== 'undefined' && process.versions?.electron
      };

      const isVSCode = signals.protocol === 'vscode-file:' ||
                      (signals.userAgent && signals.userAgent.includes('Code')) ||
                      signals.vscodeGlobal ||
                      signals.electronApp;

      return {
        isVSCode,
        signals,
        confidence: isVSCode ? 'high' : 'low'
      };
    }),

    /**
     * Generate contextual starter message for coach
     * @param {Object} learningContext - Current learning context
     * @returns {string} Contextual starter message
     */
    generateStarterMessage: vi.fn((learningContext) => {
      if (!learningContext) {
        return 'I need help with my learning journey.';
      }

      const { currentPath, currentKata, progressData } = learningContext;
      let message = 'I\'m working on ';

      if (currentKata) {
        message += `the "${currentKata}" kata`;
        if (currentPath) {
          message += ` in the ${currentPath} learning path`;
        }
      } else if (currentPath) {
        message += `the ${currentPath} learning path`;
      } else {
        message += 'a learning exercise';
      }

      if (progressData && progressData.completed && progressData.total) {
        const percentage = Math.round((progressData.completed / progressData.total) * 100);
        message += ` (${percentage}% complete)`;
      }

      message += ' and would like interactive coaching with progress tracking.';

      return message;
    }),

    /**
     * Simulate command execution with realistic delays and errors
     * @param {string} command - Command to execute
     * @param {Object} args - Command arguments
     * @param {Object} options - Execution options
     * @returns {Promise} Command execution promise
     */
    simulateCommandExecution: vi.fn(async (command, args, options = {}) => {
      const {
        delay = 100,
        errorRate = 0,
        timeout = 5000
      } = options;

      // Simulate network delay
      await new Promise(resolve => setTimeout(resolve, delay));

      // Simulate random errors
      if (Math.random() < errorRate) {
        throw new Error(`Simulated error executing command: ${command}`);
      }

      // Simulate timeout
      if (delay > timeout) {
        throw new Error(`Command execution timeout: ${command}`);
      }

      return mockCommands.executeCommand(command, args);
    }),

    /**
     * Mock file system access for VS Code extensions
     * @param {string} operation - File operation type
     * @param {string} path - File path
     * @param {any} data - Operation data
     * @returns {Promise<any>} Operation result
     */
    mockFileSystem: vi.fn(async (operation, path, data) => {
      const operations = {
        read: () => `Mock content for ${path}`,
        write: () => ({ success: true, bytesWritten: data?.length || 0 }),
        exists: () => true,
        list: () => ['file1.md', 'file2.md', 'file3.md'],
        stat: () => ({
          size: 1024,
          modified: new Date().toISOString(),
          isFile: true
        })
      };

      if (operations[operation]) {
        return operations[operation]();
      }

      throw new Error(`Unsupported file operation: ${operation}`);
    }),

    /**
     * Mock VS Code workspace API
     */
    workspace: {
      workspaceFolders: [
        {
          uri: { fsPath: '/mock/workspace/path' },
          name: 'edge-ai',
          index: 0
        }
      ],

      findFiles: vi.fn(async (pattern) => {
        const mockFiles = [
          'learning/paths/README.md',
          'learning/katas/ai-assisted-engineering/01-ai-development-fundamentals.md',
          'docs/assets/js/features/coach-button.js'
        ].filter(file => file.includes(pattern.replace('**/', '').replace('*', '')));

        return mockFiles.map(file => ({
          fsPath: `/mock/workspace/path/${file}`,
          path: `/${file}`
        }));
      }),

      openTextDocument: vi.fn(async (uri) => ({
        uri,
        getText: () => `Mock content for ${uri}`,
        lineCount: 100,
        languageId: 'markdown'
      }))
    },

    /**
     * Mock VS Code window API
     */
    window: {
      showInformationMessage: vi.fn(async (_message) => {
        return 'OK';
      }),

      showWarningMessage: vi.fn(async () => {
        return 'OK';
      }),

      showErrorMessage: vi.fn(async () => {
        return 'OK';
      }),

      createStatusBarItem: vi.fn(() => ({
        text: '',
        show: vi.fn(),
        hide: vi.fn(),
        dispose: vi.fn()
      })),

      activeTextEditor: {
        document: {
          uri: { fsPath: '/mock/current/file.md' },
          getText: () => 'Mock document content'
        },
        selection: {
          start: { line: 0, character: 0 },
          end: { line: 0, character: 10 }
        }
      }
    },

    /**
     * Mock extension context
     */
    extensionContext: {
      subscriptions: [],
      workspaceState: {
        get: vi.fn((key, defaultValue) => defaultValue),
        update: vi.fn(async (key, value) => true)
      },
      globalState: {
        get: vi.fn((key, defaultValue) => defaultValue),
        update: vi.fn(async (key, value) => true)
      },
      extensionPath: '/mock/extension/path'
    }
  };

  return mockCommands;
}

/**
 * Create mock global vscode object for testing
 * @returns {Object} Mock vscode global object
 */
export function createMockVSCodeGlobal() {
  const mockVSCode = createMockVSCodeCommands();

  return {
    commands: {
      executeCommand: mockVSCode.executeCommand,
      registerCommand: vi.fn()
    },
    window: mockVSCode.window,
    workspace: mockVSCode.workspace,
    env: {
      appName: 'Visual Studio Code',
      language: 'en-US',
      machineId: 'mock-machine-id'
    },
    version: '1.74.0',
    Uri: {
      file: (path) => ({ fsPath: path, scheme: 'file' }),
      parse: (uri) => ({ fsPath: uri, scheme: 'vscode' })
    }
  };
}

/**
 * Set up VS Code testing environment
 * @param {Object} options - Setup options
 */
export function setupVSCodeTestEnvironment(options = {}) {
  const {
    includeGlobalVSCode = true,
    mockFileSystem = true,
    mockCommands = true
  } = options;

  if (includeGlobalVSCode) {
    global.vscode = createMockVSCodeGlobal();
  }

  if (typeof window !== 'undefined') {
    // Mock VS Code protocol
    Object.defineProperty(window, 'location', {
      value: {
        protocol: 'vscode-file:',
        href: 'vscode-file://vscode-app/learning/paths/README.md'
      },
      writable: true
    });

    // Mock window.open for command URI testing
    window.open = vi.fn();
  }

  if (typeof navigator !== 'undefined') {
    Object.defineProperty(navigator, 'userAgent', {
      value: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Code/1.74.0',
      writable: true
    });
  }

  return createMockVSCodeCommands();
}

/**
 * Clean up VS Code testing environment
 */
export function cleanupVSCodeTestEnvironment() {
  if (typeof global !== 'undefined' && global.vscode) {
    delete global.vscode;
  }

  if (typeof window !== 'undefined' && window.open) {
    window.open = undefined;
  }
}

/**
 * Assert VS Code command was executed with expected parameters
 * @param {Object} mockCommands - Mock commands object
 * @param {string} expectedCommand - Expected command name
 * @param {Object} expectedArgs - Expected command arguments
 */
export function assertCommandExecuted(mockCommands, expectedCommand, expectedArgs) {
  const history = mockCommands.getCommandHistory(expectedCommand);

  if (history.length === 0) {
    throw new Error(`Command "${expectedCommand}" was not executed`);
  }

  if (expectedArgs) {
    const lastExecution = history[history.length - 1];
    if (!lastExecution.args || !deepEqual(lastExecution.args[0], expectedArgs)) {
      throw new Error(
        `Command "${expectedCommand}" was executed with unexpected arguments.\n` +
        `Expected: ${JSON.stringify(expectedArgs)}\n` +
        `Actual: ${JSON.stringify(lastExecution.args)}`
      );
    }
  }
}

/**
 * Deep equality check for objects
 * @param {any} a - First value
 * @param {any} b - Second value
 * @returns {boolean} True if deeply equal
 */
function deepEqual(a, b) {
  if (a === b) {return true;}
  if (a === null || b === null) {return false;}
  if (typeof a !== typeof b) {return false;}

  if (typeof a === 'object') {
    const keysA = Object.keys(a);
    const keysB = Object.keys(b);

    if (keysA.length !== keysB.length) {return false;}

    for (const key of keysA) {
      if (!keysB.includes(key) || !deepEqual(a[key], b[key])) {
        return false;
      }
    }

    return true;
  }

  return false;
}

export default {
  createMockVSCodeCommands,
  createMockVSCodeGlobal,
  setupVSCodeTestEnvironment,
  cleanupVSCodeTestEnvironment,
  assertCommandExecuted
};
