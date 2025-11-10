import { vi } from 'vitest';

export function createMockContainer(id = 'test-container') {
  const container = document.createElement('div');
  container.id = id;
  container.className = 'dashboard-container';
  document.body.appendChild(container);
  return container;
}

export function createMockPaths() {
  return [
    {
      id: 'path-1',
      title: 'JavaScript Fundamentals',
      description: 'Learn the basics of JavaScript programming',
      category: 'Frontend',
      steps: [
        { id: 'step-1', title: 'Variables and Types', completed: true },
        { id: 'step-2', title: 'Functions', completed: false },
        { id: 'step-3', title: 'Objects', completed: false }
      ],
      badge: {
        icon: '🏆',
        title: 'JS Champion',
        unlocked: false
      }
    },
    {
      id: 'path-2',
      title: 'React Development',
      description: 'Build modern web applications with React',
      category: 'Frontend',
      steps: [
        { id: 'step-4', title: 'Components', completed: true },
        { id: 'step-5', title: 'State Management', completed: true },
        { id: 'step-6', title: 'Hooks', completed: false }
      ],
      badge: {
        icon: '⚛️',
        title: 'React Pro',
        unlocked: true
      }
    }
  ];
}

export function mockConsole() {
  vi.spyOn(console, 'error').mockImplementation(() => {});
  vi.spyOn(console, 'warn').mockImplementation(() => {});
}

export function cleanupDashboard(dashboard, container) {
  if (dashboard) {
    dashboard.destroy();
  }
  if (container && container.parentNode) {
    container.remove();
  }
}

export function cleanupDOM() {
  // Remove all test containers and their children efficiently
  const testContainers = document.querySelectorAll('[id*="test-container"], [id*="dashboard-container"], .dashboard-container');
  testContainers.forEach(container => {
    // Clear innerHTML first for faster cleanup of large DOMs
    container.innerHTML = '';
    container.remove();
  });

  // Remove any orphaned elements from body
  while (document.body.firstChild) {
    document.body.removeChild(document.body.firstChild);
  }
}

export function setupLocalStorageMock() {
  const localStorageMock = {
    getItem: vi.fn(),
    setItem: vi.fn(),
    removeItem: vi.fn(),
    clear: vi.fn()
  };
  Object.defineProperty(window, 'localStorage', {
    value: localStorageMock,
    writable: true
  });
  return localStorageMock;
}

export function createMockFetch() {
  const mockFetch = vi.fn();
  global.fetch = mockFetch;
  return mockFetch;
}
