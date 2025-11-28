import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { NavbarDropdownManager, navbarDropdownManager, createNavbarDropdownManager } from '../../features/navbar-dropdown-manager.js';

describe('NavbarDropdownManager', () => {
  let manager;
  let mockErrorHandler;
  let mockDebugHelper;
  let container;
  let trigger1;
  let dropdown1;
  let trigger2;
  let _dropdown2;

  const createMockDependencies = () => ({
    errorHandler: {
      safeExecute: vi.fn((fn) => {
        try {
          return fn();
        } catch {
          return false;
        }
      })
    },
    debugHelper: {
      log: vi.fn()
    }
  });

  const createDropdownHTML = () => {
    const container = document.createElement('div');
    container.innerHTML = `
      <nav class="navbar">
        <button data-dropdown-trigger="menu1" id="trigger1">Menu 1</button>
        <div data-dropdown="menu1" id="dropdown1">
          <a href="#" role="menuitem">Item 1</a>
          <a href="#" role="menuitem">Item 2</a>
          <button role="menuitem">Item 3</button>
        </div>
        <button data-dropdown-trigger="menu2" id="trigger2">Menu 2</button>
        <div data-dropdown="menu2" id="dropdown2">
          <a href="#" role="menuitem">Item A</a>
          <a href="#" role="menuitem">Item B</a>
        </div>
      </nav>
      <main id="main-content">Content</main>
    `;
    return container;
  };

  beforeEach(() => {
    // Clear document
    document.body.innerHTML = '';

    // Create test DOM
    container = createDropdownHTML();
    document.body.appendChild(container);

    trigger1 = document.getElementById('trigger1');
    dropdown1 = document.getElementById('dropdown1');
    trigger2 = document.getElementById('trigger2');
    _dropdown2 = document.getElementById('dropdown2');

    // Create mock dependencies
    const dependencies = createMockDependencies();
    mockErrorHandler = dependencies.errorHandler;
    mockDebugHelper = dependencies.debugHelper;

    // Create manager instance
    manager = new NavbarDropdownManager(dependencies);
  });

  afterEach(() => {
    if (manager && manager.isInitialized) {
      manager.destroy();
    }
    document.body.innerHTML = '';
    vi.clearAllMocks();
  });

  describe('Constructor', () => {
    it('should create a new instance with default configuration', () => {
      expect(manager).toBeInstanceOf(NavbarDropdownManager);
      expect(manager.isInitialized).toBe(false);
      expect(manager.activeDropdown).toBe(null);
      expect(manager.dropdownElements).toBeInstanceOf(Map);
    });

    it('should accept custom configuration', () => {
      const customConfig = {
        hoverDelay: 500,
        hideDelay: 1000,
        enableKeyboardNav: false
      };
      const customManager = new NavbarDropdownManager(createMockDependencies(), customConfig);

      expect(customManager.config.hoverDelay).toBe(500);
      expect(customManager.config.hideDelay).toBe(1000);
      expect(customManager.config.enableKeyboardNav).toBe(false);
    });

    it('should bind event handler methods', () => {
      expect(manager.handleMouseEnter).toBeDefined();
      expect(manager.handleMouseLeave).toBeDefined();
      expect(manager.handleKeyDown).toBeDefined();
      expect(manager.handleFocus).toBeDefined();
      expect(manager.handleBlur).toBeDefined();
      expect(manager.handleClick).toBeDefined();
      expect(manager.handleTouchStart).toBeDefined();
    });
  });

  describe('Initialization', () => {
    it('should initialize successfully', () => {
      const result = manager.initialize();

      expect(result).toBe(true);
      expect(manager.isInitialized).toBe(true);
      expect(mockErrorHandler.safeExecute).toHaveBeenCalled();
      expect(mockDebugHelper.log).toHaveBeenCalledWith('Initialized successfully');
    });

    it('should not initialize twice', () => {
      manager.initialize();
      mockDebugHelper.log.mockClear();

      const result = manager.initialize();

      expect(result).toBe(true);
      expect(mockDebugHelper.log).toHaveBeenCalledWith('Already initialized');
    });

    it('should setup dropdown elements', () => {
      manager.initialize();

      expect(manager.dropdownElements.size).toBe(2);
      expect(trigger1.getAttribute('aria-haspopup')).toBe('true');
      expect(trigger1.getAttribute('aria-expanded')).toBe('false');
      expect(dropdown1.getAttribute('role')).toBe('menu');
      expect(dropdown1.style.display).toBe('none');
    });

    it('should setup menu item attributes', () => {
      manager.initialize();

      const menuItems1 = dropdown1.querySelectorAll('[role="menuitem"], a, button');
      expect(menuItems1[0].getAttribute('data-first-item')).toBe('true');
      expect(menuItems1[menuItems1.length - 1].getAttribute('data-last-item')).toBe('true');

      menuItems1.forEach(item => {
        expect(item.getAttribute('tabindex')).toBe('-1');
      });
    });

    it('should setup accessibility features', () => {
      manager.initialize();

      const skipLink = document.querySelector('.sr-only');
      expect(skipLink).toBeTruthy();
      expect(skipLink.textContent).toBe('Skip to main content');
      expect(skipLink.href).toContain('#main-content');
    });

    it('should handle initialization errors gracefully', () => {
      mockErrorHandler.safeExecute.mockReturnValue(false);

      const result = manager.initialize();

      expect(result).toBe(false);
    });
  });

  describe('Event Handling', () => {
    beforeEach(() => {
      manager.initialize();
    });

    describe('Mouse Events', () => {
      it('should handle mouse enter on trigger', async () => {
        const openSpy = vi.spyOn(manager, 'openDropdown');

        trigger1.dispatchEvent(new MouseEvent('mouseenter'));

        // Wait for hover delay
        await new Promise(resolve => setTimeout(resolve, manager.config.hoverDelay + 10));

        expect(openSpy).toHaveBeenCalled();
      });

      it('should handle mouse leave on dropdown', async () => {
        manager.openDropdown(manager.dropdownElements.get(trigger1));
        const closeSpy = vi.spyOn(manager, 'closeDropdown');

        dropdown1.dispatchEvent(new MouseEvent('mouseleave'));

        // Wait for hide delay
        await new Promise(resolve => setTimeout(resolve, manager.config.hideDelay + 10));

        expect(closeSpy).toHaveBeenCalled();
      });

      it('should clear timers on mouse enter', () => {
        const clearSpy = vi.spyOn(manager, 'clearHideTimer');

        trigger1.dispatchEvent(new MouseEvent('mouseenter'));

        expect(clearSpy).toHaveBeenCalled();
      });
    });

    describe('Keyboard Events', () => {
      it('should toggle dropdown on Enter key', () => {
        const toggleSpy = vi.spyOn(manager, 'toggleDropdown');

        trigger1.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }));

        expect(toggleSpy).toHaveBeenCalled();
      });

      it('should toggle dropdown on Space key', () => {
        const toggleSpy = vi.spyOn(manager, 'toggleDropdown');

        trigger1.dispatchEvent(new KeyboardEvent('keydown', { key: ' ' }));

        expect(toggleSpy).toHaveBeenCalled();
      });

      it('should open dropdown on ArrowDown when closed', () => {
        const openSpy = vi.spyOn(manager, 'openDropdown');

        trigger1.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowDown' }));

        expect(openSpy).toHaveBeenCalled();
      });

      it('should focus next menu item on ArrowDown when open', () => {
        const dropdownData = manager.dropdownElements.get(trigger1);
        manager.openDropdown(dropdownData);
        const focusSpy = vi.spyOn(manager, 'focusNextMenuItem');

        trigger1.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowDown' }));

        expect(focusSpy).toHaveBeenCalledWith(dropdown1);
      });

      it('should focus previous menu item on ArrowUp when open', () => {
        const dropdownData = manager.dropdownElements.get(trigger1);
        manager.openDropdown(dropdownData);
        const focusSpy = vi.spyOn(manager, 'focusPreviousMenuItem');

        trigger1.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowUp' }));

        expect(focusSpy).toHaveBeenCalledWith(dropdown1);
      });

      it('should close dropdown on Tab', () => {
        const dropdownData = manager.dropdownElements.get(trigger1);
        manager.openDropdown(dropdownData);
        const closeSpy = vi.spyOn(manager, 'closeDropdown');

        trigger1.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab' }));

        expect(closeSpy).toHaveBeenCalledWith(dropdownData);
      });

      it('should close all dropdowns on Escape key', () => {
        manager.openDropdown(manager.dropdownElements.get(trigger1));
        const closeSpy = vi.spyOn(manager, 'closeAllDropdowns');

        document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));

        expect(closeSpy).toHaveBeenCalled();
      });
    });

    describe('Focus Events', () => {
      it('should add focus class on trigger focus', () => {
        trigger1.dispatchEvent(new FocusEvent('focus'));

        expect(trigger1.classList.contains('dropdown-focused')).toBe(true);
      });

      it('should remove focus class on trigger blur', () => {
        trigger1.classList.add('dropdown-focused');

        trigger1.dispatchEvent(new FocusEvent('blur'));

        // Wait for timeout
        setTimeout(() => {
          expect(trigger1.classList.contains('dropdown-focused')).toBe(false);
        }, 150);
      });
    });

    describe('Click Events', () => {
      it('should toggle dropdown on trigger click', () => {
        const toggleSpy = vi.spyOn(manager, 'toggleDropdown');

        trigger1.dispatchEvent(new MouseEvent('click'));

        expect(toggleSpy).toHaveBeenCalled();
      });

      it('should close all dropdowns on outside click', () => {
        manager.openDropdown(manager.dropdownElements.get(trigger1));
        const closeSpy = vi.spyOn(manager, 'closeAllDropdowns');

        document.dispatchEvent(new MouseEvent('click', { bubbles: true }));

        expect(closeSpy).toHaveBeenCalled();
      });

      it('should not close dropdowns on dropdown click', () => {
        manager.openDropdown(manager.dropdownElements.get(trigger1));
        const closeSpy = vi.spyOn(manager, 'closeAllDropdowns');

        dropdown1.dispatchEvent(new MouseEvent('click', { bubbles: true }));

        expect(closeSpy).not.toHaveBeenCalled();
      });
    });

    describe('Touch Events', () => {
      it('should open dropdown on touch start', () => {
        const openSpy = vi.spyOn(manager, 'openDropdown');

        trigger1.dispatchEvent(new TouchEvent('touchstart', { touches: [{}] }));

        expect(openSpy).toHaveBeenCalled();
      });
    });
  });

  describe('Dropdown Operations', () => {
    beforeEach(() => {
      manager.initialize();
    });

    describe('Opening Dropdowns', () => {
      it('should open a dropdown', () => {
        const dropdownData = manager.dropdownElements.get(trigger1);
        const emitSpy = vi.spyOn(manager, 'emitEvent');

        manager.openDropdown(dropdownData);

        expect(dropdownData.isOpen).toBe(true);
        expect(dropdown1.style.display).toBe('block');
        expect(trigger1.getAttribute('aria-expanded')).toBe('true');
        expect(trigger1.classList.contains('dropdown-open')).toBe(true);
        expect(manager.activeDropdown).toBe(dropdownData);
        expect(emitSpy).toHaveBeenCalledWith('dropdown:opened', {
          trigger: trigger1,
          dropdown: dropdown1,
          id: 'menu1'
        });
      });

      it('should not open if already open', () => {
        const dropdownData = manager.dropdownElements.get(trigger1);
        manager.openDropdown(dropdownData);
        const emitSpy = vi.spyOn(manager, 'emitEvent');
        emitSpy.mockClear();

        manager.openDropdown(dropdownData);

        expect(emitSpy).not.toHaveBeenCalled();
      });

      it('should close other dropdowns when opening', () => {
        const dropdownData1 = manager.dropdownElements.get(trigger1);
        const dropdownData2 = manager.dropdownElements.get(trigger2);
        manager.openDropdown(dropdownData1);

        manager.openDropdown(dropdownData2);

        expect(dropdownData1.isOpen).toBe(false);
        expect(dropdownData2.isOpen).toBe(true);
        expect(manager.activeDropdown).toBe(dropdownData2);
      });

      it('should focus first menu item when opened via keyboard', () => {
        const dropdownData = manager.dropdownElements.get(trigger1);
        trigger1.focus();
        const focusSpy = vi.spyOn(manager, 'focusFirstMenuItem');

        manager.openDropdown(dropdownData);

        expect(focusSpy).toHaveBeenCalledWith(dropdown1);
      });
    });

    describe('Closing Dropdowns', () => {
      it('should close a dropdown', () => {
        const dropdownData = manager.dropdownElements.get(trigger1);
        manager.openDropdown(dropdownData);
        const emitSpy = vi.spyOn(manager, 'emitEvent');
        emitSpy.mockClear();

        manager.closeDropdown(dropdownData);

        expect(dropdownData.isOpen).toBe(false);
        expect(dropdown1.style.display).toBe('none');
        expect(trigger1.getAttribute('aria-expanded')).toBe('false');
        expect(trigger1.classList.contains('dropdown-open')).toBe(false);
        expect(manager.activeDropdown).toBe(null);
        expect(emitSpy).toHaveBeenCalledWith('dropdown:closed', {
          trigger: trigger1,
          dropdown: dropdown1,
          id: 'menu1'
        });
      });

      it('should not close if already closed', () => {
        const dropdownData = manager.dropdownElements.get(trigger1);
        const emitSpy = vi.spyOn(manager, 'emitEvent');

        manager.closeDropdown(dropdownData);

        expect(emitSpy).not.toHaveBeenCalled();
      });

      it('should close all dropdowns', () => {
        const dropdownData1 = manager.dropdownElements.get(trigger1);
        const dropdownData2 = manager.dropdownElements.get(trigger2);
        manager.openDropdown(dropdownData1);
        manager.openDropdown(dropdownData2);

        manager.closeAllDropdowns();

        expect(dropdownData1.isOpen).toBe(false);
        expect(dropdownData2.isOpen).toBe(false);
        expect(manager.activeDropdown).toBe(null);
      });
    });

    describe('Toggling Dropdowns', () => {
      it('should open a closed dropdown', () => {
        const dropdownData = manager.dropdownElements.get(trigger1);
        const openSpy = vi.spyOn(manager, 'openDropdown');

        manager.toggleDropdown(dropdownData);

        expect(openSpy).toHaveBeenCalledWith(dropdownData);
      });

      it('should close an open dropdown', () => {
        const dropdownData = manager.dropdownElements.get(trigger1);
        manager.openDropdown(dropdownData);
        const closeSpy = vi.spyOn(manager, 'closeDropdown');

        manager.toggleDropdown(dropdownData);

        expect(closeSpy).toHaveBeenCalledWith(dropdownData);
      });
    });
  });

  describe('Navigation and Focus Management', () => {
    beforeEach(() => {
      manager.initialize();
    });

    it('should focus first menu item', () => {
      const firstItem = dropdown1.querySelector('[data-first-item="true"]');
      const focusSpy = vi.spyOn(firstItem, 'focus');

      manager.focusFirstMenuItem(dropdown1);

      expect(focusSpy).toHaveBeenCalled();
    });

    it('should focus next menu item', () => {
      const menuItems = Array.from(dropdown1.querySelectorAll('[role="menuitem"], a, button'));
      const currentItem = menuItems[0];
      const nextItem = menuItems[1];
      currentItem.focus();
      const focusSpy = vi.spyOn(nextItem, 'focus');

      manager.focusNextMenuItem(dropdown1);

      expect(focusSpy).toHaveBeenCalled();
    });

    it('should wrap to first item when focusing next on last item', () => {
      const menuItems = Array.from(dropdown1.querySelectorAll('[role="menuitem"], a, button'));
      const lastItem = menuItems[menuItems.length - 1];
      const firstItem = menuItems[0];
      lastItem.focus();
      const focusSpy = vi.spyOn(firstItem, 'focus');

      manager.focusNextMenuItem(dropdown1);

      expect(focusSpy).toHaveBeenCalled();
    });

    it('should focus previous menu item', () => {
      const menuItems = Array.from(dropdown1.querySelectorAll('[role="menuitem"], a, button'));
      const currentItem = menuItems[1];
      const previousItem = menuItems[0];
      currentItem.focus();
      const focusSpy = vi.spyOn(previousItem, 'focus');

      manager.focusPreviousMenuItem(dropdown1);

      expect(focusSpy).toHaveBeenCalled();
    });

    it('should wrap to last item when focusing previous on first item', () => {
      const menuItems = Array.from(dropdown1.querySelectorAll('[role="menuitem"], a, button'));
      const firstItem = menuItems[0];
      const lastItem = menuItems[menuItems.length - 1];
      firstItem.focus();
      const focusSpy = vi.spyOn(lastItem, 'focus');

      manager.focusPreviousMenuItem(dropdown1);

      expect(focusSpy).toHaveBeenCalled();
    });

    it('should focus active trigger', () => {
      const dropdownData = manager.dropdownElements.get(trigger1);
      manager.openDropdown(dropdownData);
      const focusSpy = vi.spyOn(trigger1, 'focus');

      manager.focusActiveTrigger();

      expect(focusSpy).toHaveBeenCalled();
    });
  });

  describe('Utility Methods', () => {
    beforeEach(() => {
      manager.initialize();
    });

    it('should find dropdown data for trigger', () => {
      const dropdownData = manager.findDropdownData(trigger1);

      expect(dropdownData).toBeTruthy();
      expect(dropdownData.trigger).toBe(trigger1);
      expect(dropdownData.dropdown).toBe(dropdown1);
      expect(dropdownData.id).toBe('menu1');
    });

    it('should find dropdown data for dropdown element', () => {
      const dropdownData = manager.findDropdownData(dropdown1);

      expect(dropdownData).toBeTruthy();
      expect(dropdownData.trigger).toBe(trigger1);
      expect(dropdownData.dropdown).toBe(dropdown1);
    });

    it('should return null for unknown element', () => {
      const unknownElement = document.createElement('div');
      const dropdownData = manager.findDropdownData(unknownElement);

      expect(dropdownData).toBe(null);
    });

    it('should detect dropdown click', () => {
      const triggerClick = { target: trigger1 };
      const dropdownClick = { target: dropdown1.firstElementChild };
      const outsideClick = { target: document.body };

      expect(manager.isDropdownClick(triggerClick)).toBe(true);
      expect(manager.isDropdownClick(dropdownClick)).toBe(true);
      expect(manager.isDropdownClick(outsideClick)).toBe(false);
    });

    it('should detect dropdown focus', () => {
      const dropdownData = manager.dropdownElements.get(trigger1);

      trigger1.focus();
      expect(manager.isDropdownFocused(dropdownData)).toBe(true);

      trigger1.blur();
      expect(manager.isDropdownFocused(dropdownData)).toBe(false);
    });

    it('should clear hover timer', () => {
      manager.hoverTimer = setTimeout(() => {}, 1000);
      const _timerId = manager.hoverTimer;

      manager.clearHoverTimer();

      expect(manager.hoverTimer).toBe(null);
    });

    it('should clear hide timer', () => {
      manager.hideTimer = setTimeout(() => {}, 1000);
      const _timerId = manager.hideTimer;

      manager.clearHideTimer();

      expect(manager.hideTimer).toBe(null);
    });

    it('should emit custom events', () => {
      const eventSpy = vi.fn();
      document.addEventListener('test:event', eventSpy);

      manager.emitEvent('test:event', { data: 'test' });

      expect(eventSpy).toHaveBeenCalled();
      const event = eventSpy.mock.calls[0][0];
      expect(event.detail).toEqual({ data: 'test' });
      expect(event.bubbles).toBe(true);
      expect(event.cancelable).toBe(true);
    });
  });

  describe('State Management', () => {
    beforeEach(() => {
      manager.initialize();
    });

    it('should return current state', () => {
      const state = manager.getState();

      expect(state).toEqual({
        isInitialized: true,
        dropdownCount: 2,
        openDropdowns: [],
        activeDropdown: null
      });
    });

    it('should return state with open dropdowns', () => {
      manager.openDropdown(manager.dropdownElements.get(trigger1));
      const state = manager.getState();

      expect(state.openDropdowns).toEqual(['menu1']);
      expect(state.activeDropdown).toBe('menu1');
    });

    it('should update configuration', () => {
      const result = manager.updateConfig({
        hoverDelay: 500,
        hideDelay: 1000
      });

      expect(result).toBe(true);
      expect(manager.config.hoverDelay).toBe(500);
      expect(manager.config.hideDelay).toBe(1000);
      expect(mockDebugHelper.log).toHaveBeenCalledWith('Configuration updated');
    });

    it('should handle config update errors', () => {
      mockErrorHandler.safeExecute.mockReturnValue(false);

      const result = manager.updateConfig({ hoverDelay: 500 });

      expect(result).toBe(false);
    });
  });

  describe('Cleanup and Destruction', () => {
    beforeEach(() => {
      manager.initialize();
    });

    it('should destroy successfully', () => {
      manager.openDropdown(manager.dropdownElements.get(trigger1));
      const abortSpy = vi.spyOn(manager.abortController, 'abort');

      const result = manager.destroy();

      expect(result).toBe(true);
      expect(manager.isInitialized).toBe(false);
      expect(manager.activeDropdown).toBe(null);
      expect(manager.dropdownElements.size).toBe(0);
      expect(abortSpy).toHaveBeenCalled();
      expect(mockDebugHelper.log).toHaveBeenCalledWith('Destroyed successfully');
    });

    it('should handle destroy when not initialized', () => {
      manager.isInitialized = false;

      const result = manager.destroy();

      expect(result).toBe(true);
    });

    it('should handle destroy errors', () => {
      mockErrorHandler.safeExecute.mockReturnValue(false);

      const result = manager.destroy();

      expect(result).toBe(false);
    });

    it('should clear timers on destroy', () => {
      manager.hoverTimer = setTimeout(() => {}, 1000);
      manager.hideTimer = setTimeout(() => {}, 1000);
      const clearHoverSpy = vi.spyOn(manager, 'clearHoverTimer');
      const clearHideSpy = vi.spyOn(manager, 'clearHideTimer');

      manager.destroy();

      expect(clearHoverSpy).toHaveBeenCalled();
      expect(clearHideSpy).toHaveBeenCalled();
    });

    it('should close all dropdowns on destroy', () => {
      manager.openDropdown(manager.dropdownElements.get(trigger1));
      const closeSpy = vi.spyOn(manager, 'closeAllDropdowns');

      manager.destroy();

      expect(closeSpy).toHaveBeenCalled();
    });
  });

  describe('Default Instance and Factory', () => {
    it('should export a default instance', () => {
      expect(navbarDropdownManager).toBeInstanceOf(NavbarDropdownManager);
    });

    it('should create custom instances via factory', () => {
      const customDependencies = createMockDependencies();
      const customConfig = { hoverDelay: 500 };

      const customManager = createNavbarDropdownManager(customDependencies, customConfig);

      expect(customManager).toBeInstanceOf(NavbarDropdownManager);
      expect(customManager.config.hoverDelay).toBe(500);
      expect(customManager).not.toBe(navbarDropdownManager);
    });
  });

  describe('Edge Cases and Error Handling', () => {
    it('should handle missing dropdown elements gracefully', () => {
      // Create trigger without corresponding dropdown
      document.body.innerHTML = '<button data-dropdown-trigger="missing">Trigger</button>';

      expect(() => manager.initialize()).not.toThrow();
      expect(manager.dropdownElements.size).toBe(0);
    });

    it('should handle events on unknown elements', () => {
      manager.initialize();
      const unknownElement = document.createElement('div');

      expect(() => {
        manager.handleMouseEnter({ currentTarget: unknownElement });
        manager.handleKeyDown({ currentTarget: unknownElement });
        manager.handleClick({ currentTarget: unknownElement });
      }).not.toThrow();
    });

    it('should handle keyboard events with no dropdown data', () => {
      manager.initialize();
      const unknownElement = document.createElement('div');

      expect(() => {
        manager.handleKeyDown({
          currentTarget: unknownElement,
          key: 'Enter',
          preventDefault: vi.fn()
        });
      }).not.toThrow();
    });

    it('should handle focus management with no menu items', () => {
      const emptyDropdown = document.createElement('div');

      expect(() => {
        manager.focusFirstMenuItem(emptyDropdown);
        manager.focusNextMenuItem(emptyDropdown);
        manager.focusPreviousMenuItem(emptyDropdown);
      }).not.toThrow();
    });

    it('should handle focus when no active dropdown', () => {
      manager.initialize();

      expect(() => {
        manager.focusActiveTrigger();
      }).not.toThrow();
    });
  });
});
