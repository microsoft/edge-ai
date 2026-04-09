/**
 * Docsify Frontmatter Display Plugin
 * Parses YAML frontmatter and displays metadata at the top of documentation pages
 */

// Simple YAML parser for frontmatter (using js-yaml from CDN)
(function () {
  'use strict';

  function parseFrontmatter(content) {
    const frontmatterRegex = /^---\r?\n([\s\S]*?)\r?\n---/;
    const match = content.match(frontmatterRegex);

    if (!match) {
      return { frontmatter: null, content: content };
    }

    try {
      // Use js-yaml to parse the frontmatter (try both possible global names)
      const jsyaml = window.jsyaml || window.jsYaml || window.YAML;

      const frontmatter = jsyaml ? jsyaml.load(match[1]) : null;
      const cleanContent = content.replace(frontmatterRegex, '').trim();

      return { frontmatter, content: cleanContent };
    } catch (error) {
      console.error('❌ Frontmatter parsing error:', error);
      return { frontmatter: null, content: content };
    }
  }

  function createFrontmatterDisplay(frontmatter) {
    // Exclude technical fields that shouldn't be displayed to users
    const _excludeFields = [
      'layout', 'permalink', 'redirect_from', 'sidebar', 'variant', 'template',
      'link', 'icon', 'hero', 'ms.service', 'ms.subservice', 'ms.technology',
      'ms.topic', 'ms.reviewer', 'ms.author', 'manager', 'ms.custom',
      'uid', 'zone_pivot_groups', 'recommendations', 'helpviewer_keywords'
    ];

    let html = '<div class="frontmatter-display">';

    // Title display
    if (frontmatter.title) {
      // Remove numbering pattern (e.g., "02 - " or "001 - ") from title
      const cleanTitle = frontmatter.title.replace(/^\d+\s*-\s*/, '');
      html += `<div class="frontmatter-title">${cleanTitle}</div>`;
    }

    // Header metadata (author and reading time only)
    const headerItems = [];

    if (frontmatter.author) {
      headerItems.push(`<span class="header-meta-author">By ${frontmatter.author}</span>`);
    }

    // Priority: Display kata time estimate first, fall back to reading time
    if (frontmatter.estimated_time_minutes) {
      headerItems.push(`<span class="header-meta-reading-time">${frontmatter.estimated_time_minutes} min kata</span>`);
    } else if (frontmatter.estimated_reading_time) {
      headerItems.push(`<span class="header-meta-reading-time">${frontmatter.estimated_reading_time} min read</span>`);
    }

    if (headerItems.length > 0) {
      html += `<div class="frontmatter-header-meta">${headerItems.join('')}</div>`;
    }

    // Main metadata (only essential fields)
    const metadata = [];

    // Date
    if (frontmatter['ms.date'] || frontmatter.date) {
      const dateStr = frontmatter['ms.date'] || frontmatter.date;
      const formattedDate = formatDate(dateStr);
      metadata.push({ label: 'Date', value: formattedDate });
    }

    // Keywords (if present)
    if (frontmatter.keywords && Array.isArray(frontmatter.keywords)) {
      const clickableKeywords = frontmatter.keywords.map(keyword =>
        `<span class="keyword-tag" onclick="searchKeyword('${keyword}')">${keyword}</span>`
      ).join(' ');
      metadata.push({
        label: 'Keywords',
        value: clickableKeywords
      });
    }

    // Only show metadata if we have any
    if (metadata.length > 0) {
      html += '<div class="frontmatter-metadata">';
      metadata.forEach(item => {
        html += `<div class="metadata-item"><span class="metadata-label">${item.label}:</span> <span class="metadata-value">${item.value}</span></div>`;
      });
      html += '</div>';
    }

    // Description display - moved to appear after keywords
    if (frontmatter.description) {
      html += `<div class="frontmatter-description">${frontmatter.description}</div>`;
    }

    html += '</div>';

    return html;
  }

  function formatDate(dateStr) {
    try {
      // Handle both ISO format (YYYY-MM-DD) and legacy formats
      let date;

      // ISO 8601 format (YYYY-MM-DD) - preferred
      if (/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
        date = new Date(dateStr + 'T00:00:00');
      }
      // Legacy MM/DD/YYYY format
      else if (/^\d{1,2}\/\d{1,2}\/\d{4}$/.test(dateStr)) {
        date = new Date(dateStr);
      }
      // Try parsing any other format
      else {
        date = new Date(dateStr);
      }

      if (isNaN(date.getTime())) {
        return dateStr; // Return original if can't parse
      }

      const options = {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      };

      return date.toLocaleDateString('en-US', options);
    } catch {
      return dateStr; // Return original if any error
    }
  }

  function searchKeyword(keyword) {
    try {
      // Validate keyword input
      if (!keyword || (typeof keyword === 'string' && keyword.trim() === '')) {
        return {
          success: false,
          error: 'Invalid keyword',
          keyword: keyword
        };
      }

      // Set flag to prevent search clearing
      window.searchKeywordActive = true;

      // Use the global search function if available (from search-integration.js)
      if (window.doSearch) {
        window.doSearch(keyword);
        return {
          success: true,
          method: 'doSearch',
          keyword: keyword
        };
      }

      // Fallback to direct search implementation
      const searchInput = document.querySelector('.search input[type="search"]') ||
                         document.querySelector('input[type="search"]');

      if (searchInput) {
        // Set the search input value synchronously for better testability
        searchInput.value = keyword;

        // Focus the input
        searchInput.focus();

        // Trigger events to ensure compatibility
        const inputEvent = new Event('input', {
          bubbles: true,
          cancelable: true
        });

        const keyupEvent = new Event('keyup', {
          bubbles: true,
          cancelable: true
        });

        const changeEvent = new Event('change', {
          bubbles: true,
          cancelable: true
        });

        // Dispatch events
        searchInput.dispatchEvent(inputEvent);
        searchInput.dispatchEvent(keyupEvent);
        searchInput.dispatchEvent(changeEvent);

        // Try to manually trigger docsify search if available
        if (window.Docsify && window.Docsify.search) {
          try {
            window.Docsify.search.performSearch(keyword);
          } catch {
            // Silent failure - search will work via events
          }
        }

        return {
          success: true,
          method: 'directSearch',
          keyword: keyword
        };
      } else {
        window.searchKeywordActive = false;
        return {
          success: false,
          error: 'No search method available',
          keyword: keyword
        };
      }
    } catch (error) {
      window.searchKeywordActive = false;
      return {
        success: false,
        error: error.message,
        keyword: keyword
      };
    }
  }

  // Make searchKeyword globally available
  if (typeof window !== 'undefined') {
    window.searchKeyword = searchKeyword;
  }

  // Expose plugin API globally for testing and integration
  const DocsifyFrontmatterPlugin = {
    parseFrontmatter,
    createFrontmatterDisplay,
    formatDate,
    searchKeyword,
    plugin: frontmatterPlugin
  };

  // Global exposure
  if (typeof window !== 'undefined') {
    window.DocsifyFrontmatterPlugin = DocsifyFrontmatterPlugin;
  }

  // For testing environments
  if (typeof globalThis !== 'undefined' && typeof globalThis.window !== 'undefined') {
    globalThis.window.DocsifyFrontmatterPlugin = DocsifyFrontmatterPlugin;
  }

  // Module exports for testing
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = DocsifyFrontmatterPlugin;
  }

  // CSS styles are now handled by /docs/assets/css/components/metadata.css
  // No dynamic style injection needed - all styles moved to proper CSS architecture

  // Docsify plugin
  function frontmatterPlugin(hook, vm) {
    hook.beforeEach((content) => {
      // Parse frontmatter and remove it from content
      const { frontmatter, content: cleanContent } = parseFrontmatter(content);

      if (frontmatter) {
        // Store frontmatter for later use in vm and globally for other plugins
        vm.frontmatter = frontmatter;
        window.frontmatterData = { frontmatter, content: cleanContent };

        return cleanContent;
      }

      vm.frontmatter = null;
      return content;
    });

    hook.afterEach((html, next) => {
      // Add frontmatter display if we have frontmatter
      if (vm.frontmatter) {
        const frontmatterHtml = createFrontmatterDisplay(vm.frontmatter);

        // Remove any raw frontmatter that made it through to HTML (backup cleanup)
        // Handle multiple possible HTML rendering formats
        const frontmatterPatterns = [
          // Pattern 1: <p>---<br>content<br>---</p>
          /^<p>---<br>\s*([\s\S]*?)<br>---<\/p>\s*/,
          // Pattern 2: <p>---</p> content <p>---</p>
          /^<p>---<\/p>\s*<p>([\s\S]*?)<\/p>\s*<p>---<\/p>\s*/,
          // Pattern 3: Multiple <p> tags with line breaks
          /^<p>---<\/p>\s*((?:<p>[\s\S]*?<\/p>\s*)*)<p>---<\/p>\s*/,
          // Pattern 4: Pre-formatted block
          /^<pre><code>---\r?\n([\s\S]*?)\r?\n---<\/code><\/pre>\s*/,
          // Pattern 5: Plain paragraph blocks (most common in Docsify)
          /^(?:<p>---<\/p>\s*)?(?:<p>[^<]*?title:[^<]*?<\/p>\s*)+(?:<p>---<\/p>\s*)?/i
        ];

        let cleaned = false;
        for (const pattern of frontmatterPatterns) {
          if (pattern.test(html)) {
            console.warn('⚠️ HTML contains raw frontmatter! Removing with pattern:', pattern.source);
            html = html.replace(pattern, '');
            cleaned = true;
            break;
          }
        }

        // Additional check for any remaining frontmatter markers
        if (!cleaned && (html.includes('title:') || html.includes('description:') || html.includes('ms.date:'))) {
          // More aggressive cleanup - remove everything between --- markers if they exist in HTML
          html = html.replace(/^(?:<[^>]+>)*---(?:<[^>]+>)*[\s\S]*?(?:<[^>]+>)*---(?:<[^>]+>)*\s*/m, '');
        }

        html = frontmatterHtml + html;
      }
      next(html);
    });    hook.doneEach(() => {
      // Styles are now handled by CSS files - no dynamic injection needed
    });
  }

  // Register the plugin
  if (typeof window !== 'undefined') {
    window.$docsify = window.$docsify || {};
    window.$docsify.plugins = window.$docsify.plugins || [];
    window.$docsify.plugins.push(frontmatterPlugin);
  }
})();
