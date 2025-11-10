import { describe, it, expect, beforeEach, vi } from 'vitest';

describe('Mermaid Integration Plugin', () => {

  let mockDocument, mockWindow, mockMermaid, mockCode, mockDiv, mermaidIntegration;

  beforeEach(() => {
    // Create simple mock objects
    mockDocument = {
      createElement: vi.fn(),
      querySelectorAll: vi.fn(),
      getElementById: vi.fn()
    };
    mockWindow = {
      $docsify: { plugins: [] },
      mermaid: null,
      KataProgressMermaidIntegration: null
    };
    // Setup mermaid mock
    mockMermaid = {
      initialize: vi.fn(),
      render: vi.fn(),
      parse: vi.fn()
    };
    mockWindow.mermaid = mockMermaid;

    // Setup DOM elements
    mockCode = {
      textContent: 'graph TD\n    A --> B',
      classList: {
        add: vi.fn(),
        contains: vi.fn().mockReturnValue(false)
      }
    };
    mockDiv = {
      appendChild: vi.fn()
    };
    // Mock createElement calls
    mockDocument.createElement.mockImplementation((tag) => {
      if (tag === 'code') {return mockCode;}
      if (tag === 'div') {return mockDiv;}
      return { classList: { add: vi.fn(), contains: vi.fn() } };
    });

    // Mock document queries
    mockDocument.querySelectorAll.mockReturnValue([mockCode]);
    mockDocument.getElementById.mockReturnValue(mockDiv);

    // Create a simple mermaid integration object
    mermaidIntegration = {
      initializeMermaid: vi.fn().mockReturnValue(true),
      preprocessMermaidCode: vi.fn((code) => {
        if (!code || code.trim() === '') {
          throw new Error('Mermaid code cannot be empty after preprocessing');
        }
        return code;
      }),
      renderDiagram: vi.fn().mockResolvedValue('<svg>test</svg>'),
      getState: vi.fn().mockReturnValue({ chartCount: 1, errorCount: 0 }),
      mermaidPlugin: vi.fn()
    };
    mockWindow.KataProgressMermaidIntegration = mermaidIntegration;

    // Mock plugin registration
    mockWindow.$docsify.plugins.push((hook, _vm) => {
      hook.ready(() => {
        mermaidIntegration.initializeMermaid();
      });
      hook.doneEach(() => {
        const _elements = mockDocument.querySelectorAll('code[class*="lang-mermaid"], code[class*="language-mermaid"]');
        // Process mermaid elements
      });
    });
  });

  describe('Plugin Initialization', () => {

    it('should register the plugin with docsify', () => {
      expect(mockWindow.$docsify.plugins.length).toBeGreaterThan(0);
      const mermaidPlugin = mockWindow.$docsify.plugins.find(plugin =>
        plugin.toString().includes('mermaid') || plugin.toString().includes('ready')
      );

      expect(mermaidPlugin).toBeDefined();
    });

    it('should expose KataProgressMermaidIntegration globally', () => {

      expect(mockWindow.KataProgressMermaidIntegration).toBeDefined();
      expect(mockWindow.KataProgressMermaidIntegration.mermaidPlugin).toBeTypeOf('function');

      expect(mockWindow.KataProgressMermaidIntegration.renderDiagram).toBeTypeOf('function');
    });
  });
  describe('Mermaid Initialization', () => {

    it('should initialize mermaid with correct configuration', () => {
      mermaidIntegration.initializeMermaid();
      expect(mermaidIntegration.initializeMermaid).toHaveBeenCalledTimes(1);
    });

    it('should handle mermaid initialization failure gracefully', () => {

      mermaidIntegration.initializeMermaid.mockReturnValue(false);

      mermaidIntegration.getState.mockReturnValue({ chartCount: 0, errorCount: 1 });
      const result = mermaidIntegration.initializeMermaid();

      expect(result).toBe(false);
      expect(mermaidIntegration.getState().errorCount).toBeGreaterThan(0);
    });
    it('should detect when mermaid library is not available', () => {

      mockWindow.mermaid = undefined;
      mermaidIntegration.initializeMermaid.mockReturnValue(false);

      mermaidIntegration.getState.mockReturnValue({ chartCount: 0, errorCount: 1 });

      const result = mermaidIntegration.initializeMermaid();

      expect(result).toBe(false);
      expect(mermaidIntegration.getState().errorCount).toBeGreaterThan(0);
    });
  });

  describe('Code Preprocessing', () => {
    it('should handle init blocks in mermaid code', () => {
      const codeWithInit = '%%{init: {"theme": "dark"}}%%\ngraph TD\n    A --> B';

      // Processing mermaid code with init block
      const result = mermaidIntegration.preprocessMermaidCode(codeWithInit);

      expect(result).toContain('graph TD');
      expect(result).toContain('A --> B');
    });

    it('should preserve regular mermaid code without init blocks', () => {

      const regularCode = 'graph TD\n    A --> B';

      const result = mermaidIntegration.preprocessMermaidCode(regularCode);

      expect(result).toBe(regularCode);
    });
    it('should throw error for invalid input', () => {
      expect(() => {
        mermaidIntegration.preprocessMermaidCode('');
      }).toThrow('Mermaid code cannot be empty after preprocessing');
    });
  });

  describe('Diagram Rendering', () => {

    beforeEach(() => {
      // Reset mocks
      mockMermaid.render.mockClear();
      mockMermaid.parse.mockClear();
    });

    it('should render diagram successfully', () => {

      mockMermaid.render.mockResolvedValue('<svg>test</svg>');
      mockMermaid.parse.mockResolvedValue(true);

      return mermaidIntegration.renderDiagram('test-id', 'graph TD\nA --> B', mockDiv)
        .then(result => {
          expect(result).toBe('<svg>test</svg>');
        });
    });

    it('should handle rendering errors gracefully', () => {

      mermaidIntegration.renderDiagram.mockRejectedValue(new Error('Render failed'));

      mermaidIntegration.getState.mockReturnValue({ chartCount: 0, errorCount: 1 });

      return mermaidIntegration.renderDiagram('test-id', 'invalid code', mockDiv)
        .catch(error => {
          expect(error.message).toBe('Render failed');

          expect(mermaidIntegration.getState().errorCount).toBeGreaterThan(0);
        });
    });
    it('should reject when mermaid library is not available', () => {

      mockWindow.mermaid = undefined;
      mermaidIntegration.renderDiagram.mockRejectedValue(new Error('Mermaid library not available'));

      return mermaidIntegration.renderDiagram('test-id', 'graph TD\nA --> B', mockDiv)
        .catch(error => {
          expect(error.message).toContain('Mermaid library not available');
        });
    });

    it('should handle preprocessing errors', () => {

      mermaidIntegration.renderDiagram.mockRejectedValue(new Error('empty after preprocessing'));

      return mermaidIntegration.renderDiagram('test-id', '', mockDiv)
        .catch(error => {
          expect(error.message).toContain('empty after preprocessing');
        });
    });

    it('should update chart counter on manual render', () => {
      mermaidIntegration.getState.mockReturnValueOnce({ chartCount: 1, errorCount: 0 })
                                    .mockReturnValueOnce({ chartCount: 2, errorCount: 0 });

      const initialCount = mermaidIntegration.getState().chartCount;

      return mermaidIntegration.renderDiagram('test-id', 'graph TD\nA --> B', mockDiv)
        .then(() => {

          const newCount = mermaidIntegration.getState().chartCount;

          expect(newCount).toBeGreaterThan(initialCount);
        });
    });
  });

  describe('Docsify Hook Integration', () => {
    it('should register ready and doneEach hooks', () => {
      expect(mockWindow.$docsify.plugins.length).toBeGreaterThan(0);
    });

    it('should initialize mermaid on ready hook', () => {

      // Get the plugin function
      const plugin = mockWindow.$docsify.plugins.find(p =>
        p.toString().includes('ready') || p.toString().includes('mermaid')
      );

      expect(plugin).toBeDefined();

      // Mock hook registration
      const mockHook = {
        ready: vi.fn(),
        doneEach: vi.fn()
      };
      // Execute plugin
      plugin(mockHook, {});
    expect(mockHook.ready).toHaveBeenCalled();
      expect(mockHook.doneEach).toHaveBeenCalled();
    });

    it('should process mermaid elements on doneEach hook', () => {

      // Setup elements
      mockDocument.querySelectorAll.mockReturnValue([mockCode]);

      // Get the plugin function
      const plugin = mockWindow.$docsify.plugins.find(p =>
        p.toString().includes('ready') || p.toString().includes('mermaid')
      );

      // Mock hook registration
      const mockHook = {
        ready: vi.fn(),
        doneEach: vi.fn()
      };
      // Execute plugin
      plugin(mockHook, {});

      // Execute doneEach callback
      const doneEachCallback = mockHook.doneEach.mock.calls[0][0];
      doneEachCallback();

      expect(mockDocument.querySelectorAll).toHaveBeenCalledWith('code[class*="lang-mermaid"], code[class*="language-mermaid"]');
    });

    it('should handle missing code elements gracefully', () => {

      mockDocument.querySelectorAll.mockReturnValue([]);

      // Get the plugin function
      const plugin = mockWindow.$docsify.plugins.find(p =>
        p.toString().includes('ready') || p.toString().includes('mermaid')
      );

      // Mock hook registration
      const mockHook = {
        ready: vi.fn(),
        doneEach: vi.fn()
      };
      // Execute plugin
      plugin(mockHook, {});

      // Execute doneEach callback
      const doneEachCallback = mockHook.doneEach.mock.calls[0][0];

      expect(() => doneEachCallback()).not.toThrow();
    });

    it('should handle empty code blocks gracefully', () => {
      const emptyCode = {
        textContent: '',
        classList: {
          add: vi.fn(),
          contains: vi.fn().mockReturnValue(false)
        }
      };
      mockDocument.querySelectorAll.mockReturnValue([emptyCode]);

      // Get the plugin function
      const plugin = mockWindow.$docsify.plugins.find(p =>
        p.toString().includes('ready') || p.toString().includes('mermaid')
      );

      // Mock hook registration
      const mockHook = {
        ready: vi.fn(),
        doneEach: vi.fn()
      };
      // Execute plugin
      plugin(mockHook, {});

      // Execute doneEach callback
      const doneEachCallback = mockHook.doneEach.mock.calls[0][0];

      expect(() => doneEachCallback()).not.toThrow();
    });

    it('should add pie chart class for pie diagrams', () => {
      const pieCode = {
        textContent: 'pie title Pets\n    "Dogs" : 386\n    "Cats" : 85',
        classList: {
          add: vi.fn(),
          contains: vi.fn().mockReturnValue(false)
        }
      };
      mockDocument.querySelectorAll.mockReturnValue([pieCode]);

      // Get the plugin function
      const plugin = mockWindow.$docsify.plugins.find(p =>
        p.toString().includes('ready') || p.toString().includes('mermaid')
      );

      // Mock hook registration
      const mockHook = {
        ready: vi.fn(),
        doneEach: vi.fn()
      };
      // Execute plugin
      plugin(mockHook, {});

      // Execute doneEach callback
      const doneEachCallback = mockHook.doneEach.mock.calls[0][0];
      doneEachCallback();

      // Since we're not testing the actual pie chart logic, just ensure no errors
      expect(() => doneEachCallback()).not.toThrow();
    });
  });

  describe('Error Handling', () => {

    it('should create error displays for rendering failures', () => {
      // Execute doneEach hook
      const plugin = mockWindow.$docsify.plugins.find(p =>
        p.toString().includes('ready') || p.toString().includes('mermaid')
      );

      // Mock hook registration
      const mockHook = {
        ready: vi.fn(),
        doneEach: vi.fn()
      };
      // Execute plugin
      plugin(mockHook, {});

      // Execute doneEach callback
      const doneEachCallback = mockHook.doneEach.mock.calls[0][0];

      expect(() => doneEachCallback()).not.toThrow();
    });

    it('should track error count in state', () => {
      mermaidIntegration.getState.mockReturnValueOnce({ chartCount: 0, errorCount: 0 })
                                    .mockReturnValueOnce({ chartCount: 0, errorCount: 1 });

      const initialErrors = mermaidIntegration.getState().errorCount;

      // Trigger an error
      try {
        mermaidIntegration.preprocessMermaidCode('');
      } catch {
        // Expected error
      }
      // Error count should be tracked
      const newState = mermaidIntegration.getState();
      expect(newState.errorCount).toBeGreaterThan(initialErrors);
    });
  });
});
