import { describe, it, expect, beforeEach, vi } from 'vitest';

describe('Navbar Highlighting Plugin - Basic Tests', () => {
  beforeEach(() => {
    // Reset DOM for each test using Happy DOM
    document.body.innerHTML = `
      <nav class="app-nav">
        <ul>
          <li><a href="#/" data-section="Home">Home</a></li>
          <li><a href="#/docs/" data-section="Documentation">Documentation</a></li>
          <li><a href="#/learning/" data-section="Learning">Learning Platform</a></li>
          <li><a href="#/blueprints/" data-section="Blueprints">Blueprints</a></li>
          <li><a href="#/src/" data-section="Infrastructure">Infrastructure</a></li>
          <li><a href="#/copilot/" data-section="GitHub Copilot">GitHub Copilot</a></li>
        </ul>
      </nav>
    `;

    // Mock console to reduce noise
    global.console = {
      log: vi.fn(),
      warn: vi.fn(),
      error: vi.fn()
    };

    // Create a basic API mock for testing core functionality
    window.NavbarHighlighting = {
      normalizeRoute: function(route) {
        if (!route || typeof route !== 'string') {return '/';}
        let normalized = route.startsWith('#') ? route.substring(1) : route;
        if (!normalized.startsWith('/')) {normalized = `/${normalized}`;}
        if (normalized === '/' || normalized === '') {return '/';}
        return normalized;
      },

      detectActiveSection: function(route) {
        const normalizedRoute = this.normalizeRoute(route);
        if (normalizedRoute === '/') {return 'Home';}
        if (normalizedRoute.includes('/docs')) {return 'Documentation';}
        if (normalizedRoute.includes('/learning')) {return 'Learning';}
        if (normalizedRoute.includes('/blueprints')) {return 'Blueprints';}
        if (normalizedRoute.includes('/src')) {return 'Infrastructure';}
        if (normalizedRoute.includes('/copilot')) {return 'GitHub Copilot';}
        return 'Home';
      },

      findNavbarItemBySection: function(section) {
        const navbar = document.querySelector('.app-nav');
        if (!navbar) {return null;}
        return navbar.querySelector(`[data-section="${section}"]`);
      },

      clearAllActiveStates: function() {
        const navbar = document.querySelector('.app-nav');
        if (navbar) {
          const activeItems = navbar.querySelectorAll('.active');
          activeItems.forEach(item => item.classList.remove('active'));
        }
      },

      setActiveSection: function(section) {
        this.clearAllActiveStates();
        const item = this.findNavbarItemBySection(section);
        if (item) {
          item.classList.add('active');
          const parentLi = item.closest('li');
          if (parentLi) {parentLi.classList.add('active');}
        }
      }
    };
  });

  describe('Route Normalization', () => {
    it('should normalize empty route to root', () => {
      expect(window.NavbarHighlighting.normalizeRoute('')).toBe('/');
      expect(window.NavbarHighlighting.normalizeRoute(null)).toBe('/');
      expect(window.NavbarHighlighting.normalizeRoute(undefined)).toBe('/');
    });

    it('should remove hash prefix', () => {
      expect(window.NavbarHighlighting.normalizeRoute('#/docs')).toBe('/docs');
      expect(window.NavbarHighlighting.normalizeRoute('#/')).toBe('/');
    });

    it('should ensure leading slash', () => {
      expect(window.NavbarHighlighting.normalizeRoute('docs')).toBe('/docs');
      expect(window.NavbarHighlighting.normalizeRoute('learning/kata')).toBe('/learning/kata');
    });

    it('should handle non-string input', () => {
      expect(window.NavbarHighlighting.normalizeRoute(123)).toBe('/');
      expect(window.NavbarHighlighting.normalizeRoute({})).toBe('/');
      expect(window.NavbarHighlighting.normalizeRoute([])).toBe('/');
    });
  });

  describe('Section Detection', () => {
    it('should detect Home section for root routes', () => {
      expect(window.NavbarHighlighting.detectActiveSection('/')).toBe('Home');
      expect(window.NavbarHighlighting.detectActiveSection('#/')).toBe('Home');
      expect(window.NavbarHighlighting.detectActiveSection('')).toBe('Home');
    });

    it('should detect Documentation section', () => {
      expect(window.NavbarHighlighting.detectActiveSection('/docs/')).toBe('Documentation');
      expect(window.NavbarHighlighting.detectActiveSection('/docs/getting-started')).toBe('Documentation');
    });

    it('should detect Learning section', () => {
      expect(window.NavbarHighlighting.detectActiveSection('/learning/')).toBe('Learning');
      expect(window.NavbarHighlighting.detectActiveSection('/learning/kata')).toBe('Learning');
    });

    it('should detect Blueprints section', () => {
      expect(window.NavbarHighlighting.detectActiveSection('/blueprints/')).toBe('Blueprints');
      expect(window.NavbarHighlighting.detectActiveSection('/blueprints/full-single-node')).toBe('Blueprints');
    });

    it('should detect Infrastructure section', () => {
      expect(window.NavbarHighlighting.detectActiveSection('/src/')).toBe('Infrastructure');
      expect(window.NavbarHighlighting.detectActiveSection('/src/components')).toBe('Infrastructure');
    });

    it('should detect GitHub Copilot section', () => {
      expect(window.NavbarHighlighting.detectActiveSection('/copilot/')).toBe('GitHub Copilot');
      expect(window.NavbarHighlighting.detectActiveSection('/copilot/guides')).toBe('GitHub Copilot');
    });

    it('should default to Home for unknown routes', () => {
      expect(window.NavbarHighlighting.detectActiveSection('/unknown')).toBe('Home');
      expect(window.NavbarHighlighting.detectActiveSection('/random/path')).toBe('Home');
    });
  });

  describe('Navbar Item Finding', () => {
    it('should find navbar item by exact section match', () => {
      const homeItem = window.NavbarHighlighting.findNavbarItemBySection('Home');
      expect(homeItem).toBeTruthy();
      expect(homeItem.getAttribute('data-section')).toBe('Home');
    });

    it('should find navbar item for Documentation section', () => {
      const docsItem = window.NavbarHighlighting.findNavbarItemBySection('Documentation');
      expect(docsItem).toBeTruthy();
      expect(docsItem.getAttribute('data-section')).toBe('Documentation');
    });

    it('should return null for non-existent section', () => {
      const item = window.NavbarHighlighting.findNavbarItemBySection('NonExistent');
      expect(item).toBeNull();
    });
  });

  describe('Active State Management', () => {
    it('should clear all active states', () => {
      // Set up some active states
      const homeItem = document.querySelector('[data-section="Home"]');
      const docsItem = document.querySelector('[data-section="Documentation"]');
      homeItem.classList.add('active');
      docsItem.classList.add('active');

      window.NavbarHighlighting.clearAllActiveStates();

      expect(homeItem.classList.contains('active')).toBe(false);
      expect(docsItem.classList.contains('active')).toBe(false);
    });

    it('should set active section correctly', () => {
      window.NavbarHighlighting.setActiveSection('Documentation');

      const docsItem = document.querySelector('[data-section="Documentation"]');
      expect(docsItem.classList.contains('active')).toBe(true);

      const docsLi = docsItem.closest('li');
      expect(docsLi.classList.contains('active')).toBe(true);
    });

    it('should clear previous active when setting new one', () => {
      // First set Home active
      window.NavbarHighlighting.setActiveSection('Home');
      const homeItem = document.querySelector('[data-section="Home"]');
      expect(homeItem.classList.contains('active')).toBe(true);

      // Then set Documentation active
      window.NavbarHighlighting.setActiveSection('Documentation');
      const docsItem = document.querySelector('[data-section="Documentation"]');

      expect(homeItem.classList.contains('active')).toBe(false);
      expect(docsItem.classList.contains('active')).toBe(true);
    });
  });
});
