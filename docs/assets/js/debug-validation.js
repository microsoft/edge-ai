// Debug script to test validation
import LearningPathDashboard from './plugins/learning-path-dashboard.js';

// Create test container
const container = document.createElement('div');
document.body.appendChild(container);

// Create dashboard with debug enabled
const dashboard = new LearningPathDashboard(container, { debug: true });

const invalidPaths = [
  { id: '', title: 'Invalid Path' }, // Invalid: empty id
  { id: 'valid', title: '', steps: [] }, // Invalid: empty title
  { id: 'valid-2', title: 'Valid Path' }, // Invalid: missing steps
  null, // Invalid: null path
  { id: 'valid-3', title: 'Valid Path', steps: [] } // Valid
];

console.log('Testing validation...');
invalidPaths.forEach((path, index) => {
  const isValid = dashboard.validatePath(path);
  console.log(`Path ${index}:`, path, '-> Valid:', isValid);
});

dashboard.loadPaths(invalidPaths);
console.log('Final dashboard.paths:', dashboard.paths);
