/**
 * Mermaid Diagrams Integration
 * Custom mermaid integration for docsify with automatic diagram rendering
 * Version: 2.1.0
 *
 * @fileoverview Provides Mermaid diagram rendering integration for Docsify
 * @version 2.1.0
 * @author Edge AI Team
 */

(function() {
  'use strict';

  /**
   * State management for mermaid integration
   * @type {Object}
   */
  const state = {
    /** @type {number} Chart counter for unique IDs */
    mermaidChart: 0,
    /** @type {Set<number>} Active timers for cleanup */
    activeTimers: new Set(),
    /** @type {boolean} Initialization status */
    isInitialized: false,
    /** @type {Object} Error tracking */
    errorCount: 0
  };

  /**
   * Preprocesses mermaid code to handle %%{init: {...}}%% syntax
   * @param {string} code - The original mermaid code
   * @returns {string} - The processed mermaid code
   * @throws {Error} When code is invalid or empty
   */
  function preprocessMermaidCode(code) {
    if (!code || typeof code !== 'string') {
      throw new Error('Invalid mermaid code: code must be a non-empty string');
    }

    const processedCode = code.trim();

    // Basic validation - ensure it's not just whitespace
    if (!processedCode) {
      throw new Error('Mermaid code cannot be empty after preprocessing');
    }

    return processedCode;
  }

  /**
   * Cleanup function for timers and resources
   */
  function cleanup() {
    // Clear all active timers
    state.activeTimers.forEach(timerId => {
      clearTimeout(timerId);
    });
    state.activeTimers.clear();

    // Reset state
    state.isInitialized = false;
    state.errorCount = 0;
  }

  /**
   * Initialize Mermaid with error handling and configuration
   * @returns {boolean} True if initialization successful
   */
  function initializeMermaid() {
    if (state.isInitialized) {
      return true;
    }

    if (typeof window.mermaid === 'undefined') {
      return false;
    }

    try {
      window.mermaid.initialize({
        startOnLoad: false,
        theme: 'default',
        securityLevel: 'loose',
        themeVariables: {
          fontFamily: 'Segoe UI, Tahoma, Geneva, Verdana, sans-serif',
          fontSize: '14px',
          primaryColor: '#4285F4',
          primaryTextColor: '#fff',
          primaryBorderColor: '#0D47A1',
          lineColor: '#666',
          sectionBkgColor: '#f8f9fa',
          altSectionBkgColor: '#ffffff',
          gridColor: '#e1e8ed',
          secondaryColor: '#1976D2',
          tertiaryColor: '#f3e5f5',
          textColor: '#333',
          background: '#ffffff'
        },
        flowchart: {
          useMaxWidth: true,
          htmlLabels: true,
          curve: 'basis',
          padding: 20,
          nodeSpacing: 60,
          rankSpacing: 80,
          diagramPadding: 30
        },
        sequence: {
          useMaxWidth: false,
          diagramMarginX: 50,
          diagramMarginY: 10,
          actorMargin: 50,
          width: 180,
          height: 75,
          boxMargin: 15,
          boxTextMargin: 8,
          noteMargin: 10,
          messageMargin: 35,
          wrap: true
        },
        maxTextSize: 90000,
        maxEdges: 2000,
        maxNodes: 1000,
        deterministicIds: true,
        deterministicIDSeed: 'mermaid-docsify',
        suppressErrorRendering: false,
        logLevel: 'error'
      });

      state.isInitialized = true;
      // Verbose logging disabled for tests
      return true;
    } catch {
      state.errorCount++;
      return false;
    }
  }

  /**
   * Mermaid plugin for docsify
   * @param {Object} hook - Docsify hook object
   * @param {Object} vm - Docsify vm object
   */
  const mermaidPlugin = function(hook, _vm) {
    // Initialize mermaid when docsify is ready
    hook.ready(() => {
      initializeMermaid();
    });

    // Process mermaid diagrams after each page load
    hook.doneEach(() => {
      console.log('[Mermaid] doneEach hook called');

      // Try to initialize if not already done
      if (!state.isInitialized) {
        console.log('[Mermaid] Not initialized, attempting initialization...');
        if (!initializeMermaid()) {
          console.log('[Mermaid] Initialization failed, skipping');
          return;
        }
        console.log('[Mermaid] Successfully initialized');
      }

      // Use setTimeout to ensure DOM is fully updated after markdown processing
      setTimeout(() => {
        // Find all code blocks with mermaid language
        // Try multiple selectors to find mermaid blocks
        let mermaidElements = document.querySelectorAll('pre.mermaid');
        console.log('[Mermaid] Found pre.mermaid:', mermaidElements.length);

        // If not found, try alternative selector
        if (mermaidElements.length === 0) {
          mermaidElements = document.querySelectorAll('pre[data-lang="mermaid"]');
          console.log('[Mermaid] Found pre[data-lang="mermaid"]:', mermaidElements.length);
        }

        // Also try code blocks
        if (mermaidElements.length === 0) {
          mermaidElements = document.querySelectorAll('code.lang-mermaid');
          console.log('[Mermaid] Found code.lang-mermaid:', mermaidElements.length);
        }

        console.log('[Mermaid] Final element count:', mermaidElements.length);

      mermaidElements.forEach((element) => {
        try {
          // Get the code content - handle both pre>code and direct pre elements
          let codeElement = element;
          if (element.tagName === 'PRE') {
            const code = element.querySelector('code');
            if (code) {
              codeElement = code;
            }
          }

          const mermaidCode = codeElement.textContent.trim();
          if (!mermaidCode) {
            return;
          }

          // Pre-process the mermaid code
          const processedCode = preprocessMermaidCode(mermaidCode);

          // Create a unique ID for this diagram
          const diagramId = `mermaid-diagram-${++state.mermaidChart}`;

          // Create container for the diagram
          const diagramContainer = document.createElement('div');
          diagramContainer.id = diagramId;
          diagramContainer.className = 'mermaid-diagram';

          // Render the diagram with enhanced error handling
          window.mermaid.render(diagramId, processedCode).then((result) => {
            try {
              diagramContainer.innerHTML = result.svg || result;

              // Apply styling to the SVG
              const svg = diagramContainer.querySelector('svg');
              if (svg) {
                // SVG styling is now handled by CSS classes

                // Add specific class for pie charts
                if (processedCode.includes('pie ') || processedCode.includes('pie\n') || processedCode.includes('pie title')) {
                  diagramContainer.classList.add('mermaid-pie-chart');
                }
              }

              // Replace the original element with the diagram
              // If element is a code tag, replace its parent pre tag
              const elementToReplace = element.tagName === 'CODE' ? element.parentNode : element;
              elementToReplace.parentNode.replaceChild(diagramContainer, elementToReplace);
            } catch (error) {
              // Error processing rendered diagram - create error display
              createErrorDisplay(element, error, processedCode);
            }
          }).catch((error) => {
            state.errorCount++;
            createErrorDisplay(element, error, processedCode);
          });

        } catch (error) {
          state.errorCount++;
          createErrorDisplay(element, error, element.querySelector('code')?.textContent || 'Unknown code');
        }
      });
      }, 250); // Increased timeout to 250ms for more reliable DOM rendering
    });
  };

  /**
   * Creates an error display for failed mermaid diagrams
   * @param {HTMLElement} element - Original element to replace
   * @param {Error} error - The error that occurred
   * @param {string} code - The mermaid code that failed
   */
  function createErrorDisplay(element, error, code) {
    const errorContainer = document.createElement('div');
    errorContainer.className = 'mermaid-error';
    errorContainer.innerHTML = `
      <strong>Mermaid Diagram Error:</strong><br>
      <code>${error.message || 'Unknown error'}</code><br>
      <details style="margin-top: 10px;">
        <summary>Debug Information</summary>
        <pre style="margin: 5px 0; font-size: 12px;">${code}</pre>
      </details>
    `;

    try {
      element.parentNode.replaceChild(errorContainer, element);
    } catch {
      // Error replacing element - silently continue
    }
  }

  // Add the plugin to docsify
  if (typeof window !== 'undefined') {
    window.$docsify = window.$docsify || {};
    window.$docsify.plugins = (window.$docsify.plugins || []).concat(mermaidPlugin);

    // Export for external access
    window.KataProgressMermaidIntegration = {
      mermaidPlugin,
      cleanup,
      preprocessMermaidCode,
      initializeMermaid,
      renderDiagram: function(element, code) {
        if (!state.isInitialized && !initializeMermaid()) {
          return Promise.reject(new Error('Mermaid library not available'));
        }

        try {
          const diagramId = `mermaid-manual-${++state.mermaidChart}`;
          const processedCode = preprocessMermaidCode(code);
          return window.mermaid.render(diagramId, processedCode).then((result) => {
            element.innerHTML = result.svg || result;
            return true;
          }).catch((error) => {
            state.errorCount++;
            createErrorDisplay(element, error, code);
            return false;
          });
        } catch (error) {
          state.errorCount++;
          return Promise.reject(error);
        }
      },
      getState: function() {
        return {
          isInitialized: state.isInitialized,
          chartCount: state.mermaidChart,
          errorCount: state.errorCount,
          activeTimers: state.activeTimers.size
        };
      }
    };
  }
})();
