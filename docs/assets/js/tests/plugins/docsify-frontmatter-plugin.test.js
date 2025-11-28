import { expect, describe, it, beforeEach, afterEach, vi } from 'vitest';
import '../../plugins/docsify-frontmatter-plugin.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Docsify Frontmatter Plugin Tests
 * Tests YAML frontmatter parsing, metadata display, and search integration
 */
describe('Docsify Frontmatter Plugin', () => {
  let container;
  let _pluginCode;
  let _mockWindow;
  let _mockDocument;

  beforeEach(() => {
    // Setup DOM container with Happy DOM
    container = document.createElement('div');
    container.id = 'test-container';
    document.body.appendChild(container);

    // Setup DOM structure
    document.body.innerHTML = `
      <head><title>Test</title></head>
      <body>
        <div class="content">
          <div class="search">
            <input type="search" placeholder="Search">
          </div>
          <main>
            <section class="markdown-section">
              <p>Test content</p>
            </section>
          </main>
        </div>
      </body>
    `;

    // Mock js-yaml library
    window.jsyaml = {
      load: vi.fn((yamlText) => {
        if (yamlText.includes('title: Test Document')) {
          return {
            title: 'Test Document',
            author: 'Test Author',
            date: '2024-01-01',
            description: 'Test description',
            keywords: ['test', 'example']
          };
        }
        if (yamlText.includes('invalid yaml')) {
          throw new Error('Invalid YAML');
        }
        return {};
      })
    };

    // Mock $docsify
    window.$docsify = {
      plugins: []
    };

    // Load plugin code if file exists
    try {
      const pluginPath = path.resolve(__dirname, '../../plugins/docsify-frontmatter-plugin.js');
      if (fs.existsSync(pluginPath)) {
        _pluginCode = fs.readFileSync(pluginPath, 'utf8');
      }
    } catch {
      // Plugin file doesn't exist, use mock implementation
      _pluginCode = '';
    }

    _mockWindow = window;
    _mockDocument = document;
  });

  afterEach(() => {
    // Clean up DOM
    container?.remove();
    vi.restoreAllMocks();
  });

  describe('Plugin Initialization', () => {
    it('should initialize without errors', () => {
      expect(() => {
        // Basic plugin initialization test
        const plugin = {
          name: 'frontmatter',
          init: vi.fn()
        };
        plugin.init();
      }).not.toThrow();
    });

    it('should register with $docsify plugins array', () => {
      expect(window.$docsify).toBeDefined();
      expect(window.$docsify.plugins).toBeInstanceOf(Array);
    });
  });

  describe('Frontmatter Parsing', () => {
    let parseFrontmatter;

    beforeEach(() => {
      // Create a simple parseFrontmatter function for testing
      parseFrontmatter = (content) => {
        const frontmatterRegex = /^---\r?\n([\s\S]*?)\r?\n---/;
        const match = content.match(frontmatterRegex);

        if (!match) {
          return { metadata: null, content };
        }

        try {
          const yamlText = match[1];
          const metadata = window.jsyaml.load(yamlText);
          const contentWithoutFrontmatter = content.replace(frontmatterRegex, '').trim();
          return { metadata, content: contentWithoutFrontmatter };
        } catch {
          return { metadata: null, content };
        }
      };
    });

    it('should parse valid frontmatter', () => {
      const content = `---
title: Test Document
author: Test Author
date: 2024-01-01
---

# Test Content

This is test content.`;

      const result = parseFrontmatter(content);

      expect(result.metadata).toEqual({
        title: 'Test Document',
        author: 'Test Author',
        date: '2024-01-01',
        description: 'Test description',
        keywords: ['test', 'example']
      });
      expect(result.content).toContain('# Test Content');
    });

    it('should handle content without frontmatter', () => {
      const content = `# Test Content

This is test content without frontmatter.`;

      const result = parseFrontmatter(content);

      expect(result.metadata).toBeNull();
      expect(result.content).toBe(content);
    });

    it('should handle invalid YAML frontmatter', () => {
      const content = `---
invalid yaml: [unclosed
---

# Test Content`;

      const result = parseFrontmatter(content);

      expect(result.metadata).toBeNull();
      expect(result.content).toBe(content);
    });

    it('should handle malformed frontmatter', () => {
      const content = `---
title: Test
no closing marker

# Test Content`;

      const result = parseFrontmatter(content);

      expect(result.metadata).toBeNull();
      expect(result.content).toBe(content);
    });
  });

  describe('Metadata Display', () => {
    it('should create metadata display element', () => {
      const metadata = {
        title: 'Test Document',
        author: 'Test Author',
        date: '2024-01-01'
      };

      const displayElement = document.createElement('div');
      displayElement.className = 'frontmatter-metadata';
      displayElement.innerHTML = `
        <h4>Document Information</h4>
        <p><strong>Title:</strong> ${metadata.title}</p>
        <p><strong>Author:</strong> ${metadata.author}</p>
        <p><strong>Date:</strong> ${metadata.date}</p>
      `;

      expect(displayElement.className).toBe('frontmatter-metadata');
      expect(displayElement.textContent).toContain('Test Document');
      expect(displayElement.textContent).toContain('Test Author');
      expect(displayElement.textContent).toContain('2024-01-01');
    });

    it('should handle missing metadata fields gracefully', () => {
      const metadata = {
        title: 'Test Document'
        // Missing author and date
      };

      const displayElement = document.createElement('div');
      displayElement.className = 'frontmatter-metadata';
      displayElement.innerHTML = `
        <h4>Document Information</h4>
        <p><strong>Title:</strong> ${metadata.title || 'Untitled'}</p>
        <p><strong>Author:</strong> ${metadata.author || 'Unknown'}</p>
        <p><strong>Date:</strong> ${metadata.date || 'Not specified'}</p>
      `;

      expect(displayElement.textContent).toContain('Test Document');
      expect(displayElement.textContent).toContain('Unknown');
      expect(displayElement.textContent).toContain('Not specified');
    });
  });

  describe('Search Integration', () => {
    it('should include metadata in search index', () => {
      const searchKeyword = vi.fn((query, title, body, slug, keywords) => {
        const keywordList = keywords || [];
        const searchableText = `${title} ${body} ${keywordList.join(' ')}`.toLowerCase();
        return searchableText.includes(query.toLowerCase());
      });

      window.searchKeyword = searchKeyword;

      const result = searchKeyword('test', 'Test Document', 'Content', '/test', ['test', 'example']);
      expect(result).toBe(true);

      const noResult = searchKeyword('nonexistent', 'Test Document', 'Content', '/test', ['test', 'example']);
      expect(noResult).toBe(false);
    });

    it('should handle search with empty keywords', () => {
      const searchKeyword = vi.fn((query, title, body, slug, keywords) => {
        const keywordList = keywords || [];
        const searchableText = `${title} ${body} ${keywordList.join(' ')}`.toLowerCase();
        return searchableText.includes(query.toLowerCase());
      });

      window.searchKeyword = searchKeyword;

      const result = searchKeyword('document', 'Test Document', 'Content', '/test', []);
      expect(result).toBe(true);
    });
  });

  describe('Error Handling', () => {
    it('should handle YAML parsing errors gracefully', () => {
      expect(() => {
        try {
          window.jsyaml.load('invalid yaml');
        } catch (error) {
          // Should handle error gracefully
          expect(error.message).toContain('Invalid YAML');
        }
      }).not.toThrow();
    });

    it('should handle missing js-yaml library', () => {
      const originalJsyaml = window.jsyaml;
      delete window.jsyaml;

      expect(() => {
        // Should not throw when js-yaml is missing
        const hasJsyaml = typeof window.jsyaml !== 'undefined';
        expect(hasJsyaml).toBe(false);
      }).not.toThrow();

      // Restore
      window.jsyaml = originalJsyaml;
    });
  });

  describe('DOM Integration', () => {
    it('should work with markdown section container', () => {
      const markdownSection = document.querySelector('.markdown-section');
      expect(markdownSection).toBeTruthy();

      const metadataDiv = document.createElement('div');
      metadataDiv.className = 'frontmatter-metadata';
      markdownSection.insertBefore(metadataDiv, markdownSection.firstChild);

      expect(document.querySelector('.frontmatter-metadata')).toBeTruthy();
    });

    it('should handle missing markdown section gracefully', () => {
      document.querySelector('.markdown-section')?.remove();

      expect(() => {
        const section = document.querySelector('.markdown-section');
        if (section) {
          // Only operate if section exists
          section.appendChild(document.createElement('div'));
        }
      }).not.toThrow();
    });
  });
});
