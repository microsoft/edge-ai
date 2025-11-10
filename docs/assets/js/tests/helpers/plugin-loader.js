/**
 * Plugin Loader for Test Environment
 * Loads all interactive progress plugins into the global test environment
 */

// Load plugins directly by requiring them
// This ensures they register themselves on the global object

// Import plugin files - they will register themselves on globalThis
import '../../plugins/learning-progress-tracker-plugin.js';
import '../../plugins/skill-assessment-plugin.js';
import '../../plugins/learning-path-card-plugin.js';
import '../../plugins/interactive-progress-docsify-integration.js';

// Wait a short time for plugins to register
await new Promise(resolve => setTimeout(resolve, 10));

// Verify plugins are loaded and log for debugging
console.log('Plugin loading debug:');
console.log('LearningProgressTracker:', typeof globalThis.LearningProgressTracker);
console.log('SkillAssessmentPlugin:', typeof globalThis.SkillAssessmentPlugin);
console.log('LearningPathCard:', typeof globalThis.LearningPathCard);
console.log('InteractiveProgressDocsifyIntegration:', typeof globalThis.InteractiveProgressDocsifyIntegration);

if (typeof globalThis.LearningProgressTracker === 'undefined') {
  console.warn('LearningProgressTracker plugin not loaded');
}

if (typeof globalThis.SkillAssessmentPlugin === 'undefined') {
  console.warn('SkillAssessmentPlugin plugin not loaded');
}

if (typeof globalThis.LearningPathCard === 'undefined') {
  console.warn('LearningPathCard plugin not loaded');
}

if (typeof globalThis.InteractiveProgressDocsifyIntegration === 'undefined') {
  console.warn('InteractiveProgressDocsifyIntegration plugin not loaded');
}

// Also ensure window has the plugins (for tests that expect window.SkillAssessmentPlugin)
if (typeof window !== 'undefined') {
  window.LearningProgressTracker = globalThis.LearningProgressTracker;
  window.SkillAssessmentPlugin = globalThis.SkillAssessmentPlugin;
  window.LearningPathCard = globalThis.LearningPathCard;
  window.InteractiveProgressDocsifyIntegration = globalThis.InteractiveProgressDocsifyIntegration;

  console.log('Window plugin assignments:');
  console.log('window.LearningProgressTracker:', typeof window.LearningProgressTracker);
  console.log('window.SkillAssessmentPlugin:', typeof window.SkillAssessmentPlugin);
  console.log('window.LearningPathCard:', typeof window.LearningPathCard);
  console.log('window.InteractiveProgressDocsifyIntegration:', typeof window.InteractiveProgressDocsifyIntegration);
}
