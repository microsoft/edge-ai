import fg from 'fast-glob';
import fs from 'fs/promises';
import matter from 'gray-matter';
import path from 'path';
import { fileURLToPath } from 'url';
import crypto from 'crypto';
import { validateManifest } from '../schemas/index.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Constants
const LEARNING_PATHS_GLOB = '../../../learning/paths/**/*.md';
const LEARNING_DIR = path.resolve(__dirname, '../../../learning');

// Signature paths whitelist - exactly 5 paths to include in manifest
const SIGNATURE_PATHS = [
  'paths-foundation-ai-first-engineering',
  'paths-intermediate-infrastructure-architect',
  'paths-intermediate-devops-excellence',
  'paths-expert-enterprise-integration',
  'paths-expert-data-analytics-integration'
];

/**
 * Calculate SHA-256 checksum of data
 * @param {any} data - Data to checksum
 * @returns {string} Hex checksum
 */
function calculateChecksum(data) {
  const content = JSON.stringify(data, null, 0);
  return crypto.createHash('sha256').update(content, 'utf8').digest('hex');
}

/**
 * Parse markdown content to extract activity steps (katas/labs)
 * @param {string} content - Markdown content
 * @returns {Array<Object>} Array of step objects with id, title, type, time, difficulty
 */
function parseStepsFromMarkdown(content) {
  const steps = [];

  // Pattern 1: Full format with checkboxes and metadata
  // - [ ] 📚 [ ] [Title](path) <time>duration</time> <difficulty>level</difficulty>
  const fullFormatRegex = /- \[ \] 📚 \[ \] \[([^\]]+)\]\(([^)]+)\)(?:\s*<time>([^<]+)<\/time>)?(?:\s*<difficulty>([^<]+)<\/difficulty>)?/g;

  let match;
  let stepIndex = 0;
  while ((match = fullFormatRegex.exec(content)) !== null) {
    const [, title, pathRef, time, difficulty] = match;

    // Generate step ID from path or title
    const stepId = pathRef
      .replace(/^\.\.\/\.\.\//, '') // Remove ../../ prefix
      .replace(/\.md$/, '') // Remove .md extension
      .replace(/\//g, '-'); // Replace slashes with hyphens

    steps.push({
      id: stepId || `step-${stepIndex}`,
      title: title.trim(),
      path: pathRef,
      type: pathRef.includes('/katas/') ? 'kata' : pathRef.includes('/training-labs/') ? 'lab' : 'activity',
      estimatedTime: time?.trim() || '30 min',
      difficulty: difficulty?.trim() || 'Foundation'
    });

    stepIndex++;
  }

  // Pattern 2: Simple format (for AI paths)
  // - [ ] [Title](../../katas/path.md)
  //   *Difficulty | Time* • Description text
  // Captures title, path, and description from next line
  const simpleFormatRegex = /^- \[ \] \[([^\]]+)\]\((\.\.\/(?:\.\.\/)?(?:katas|training-labs)\/[^)]+\.md)\)\s*\n\s+\*[^*]+\*\s+•\s+([^\n]+)/gm;

  while ((match = simpleFormatRegex.exec(content)) !== null) {
    const [, title, pathRef, description] = match;

    // Generate step ID from path
    const stepId = pathRef
      .replace(/^\.\.\/(?:\.\.\/)?/, '') // Remove ../ or ../../ prefix
      .replace(/^(?:katas|training-labs)\//, '') // Remove katas/ or training-labs/ prefix
      .replace(/\.md$/, '') // Remove .md extension
      .replace(/\//g, '-'); // Replace slashes with hyphens

    // Don't add duplicates (in case both patterns match)
    if (!steps.some(s => s.id === stepId)) {
      steps.push({
        id: stepId,
        title: title.trim(),
        path: pathRef,
        type: pathRef.includes('/katas/') ? 'kata' : pathRef.includes('/training-labs/') ? 'lab' : 'activity',
        estimatedTime: '45 min', // Default for simple format
        difficulty: 'Foundation', // Default for simple format
        description: description?.trim() || title.trim()
      });

      stepIndex++;
    }
  }

  return steps;
}

/**
 * Extract learning path descriptor from markdown file
 * @param {string} filePath - Absolute path to markdown file
 * @returns {Promise<Object|null>} Descriptor object or null if invalid
 */
async function extractDescriptor(filePath) {
  try {
    const content = await fs.readFile(filePath, 'utf8');
    const { data: frontmatter, content: markdownContent } = matter(content);

    // Skip README files
    if (path.basename(filePath) === 'README.md') {
      return null;
    }

    // Validate minimum required fields (flexible schema)
    if (!frontmatter.title || !frontmatter.description) {
      console.warn(`[ExtractDescriptor] Missing title or description in ${filePath}`);
      return null;
    }

    // Get relative path from learning directory
    const relativePath = path.relative(LEARNING_DIR, filePath).replace(/\\/g, '/');

    // Generate ID from file path if not provided
    const id = frontmatter.id || relativePath.replace(/\.md$/, '').replace(/\//g, '-');

    // Normalize difficulty
    const difficultyMap = {
      'foundation': 'Beginner',
      'beginner': 'Beginner',
      'ai-foundation': 'Beginner',
      'intermediate': 'Intermediate',
      'ai-intermediate': 'Intermediate',
      'advanced': 'Advanced',
      'ai-advanced': 'Advanced',
      'expert': 'Expert',
      'ai-expert': 'Expert'
    };
    const difficulty = difficultyMap[frontmatter.difficulty?.toLowerCase()] || 'Beginner';

    // Extract category from keywords or path
    const category = frontmatter.category ||
                    (Array.isArray(frontmatter.keywords) ? frontmatter.keywords[0] : undefined) ||
                    'General';

    // Extract tags from keywords
    const tags = frontmatter.tags || frontmatter.keywords || [];

    // Get file stats for lastUpdated
    const stats = await fs.stat(filePath);

    // Estimate time (convert estimated_reading_time to minutes)
    const estimatedTime = frontmatter.estimatedTime ||
                         (frontmatter.estimated_reading_time ? `${frontmatter.estimated_reading_time}h` : '1h');

    // Parse steps from markdown content (katas and labs)
    const steps = frontmatter.steps || parseStepsFromMarkdown(markdownContent);

    return {
      id,
      title: frontmatter.title,
      description: frontmatter.description,
      category,
      difficulty,
      tags,
      estimatedTime,
      prerequisites: frontmatter.prerequisites || [],
      steps,
      outcomes: frontmatter.outcomes || [],
      path: relativePath,
      author: frontmatter.author || undefined,
      lastUpdated: stats.mtime.toISOString()
    };
  } catch (error) {
    console.error(`[ExtractDescriptor] Error processing ${filePath}:`, error.message);
    return null;
  }
}

/**
 * Rebuild the learning path manifest from markdown files
 * @param {Object} [options] - Options
 * @param {boolean} [options.validate=true] - Validate manifest against schema
 * @returns {Promise<Object>} Manifest object { descriptors, checksum, generatedAt, version }
 */
async function rebuildManifest(options = {}) {
  const { validate = true } = options;

  try {
    // Find all learning path markdown files
    const globPattern = path.resolve(__dirname, LEARNING_PATHS_GLOB).replace(/\\/g, '/');
    const files = await fg(globPattern, {
      absolute: true,
      onlyFiles: true
    });

    console.log(`[RebuildManifest] Found ${files.length} learning path files`);

    // Extract descriptors from each file
    const descriptorPromises = files.map(file => extractDescriptor(file));
    const results = await Promise.all(descriptorPromises);

    // Filter out null results (invalid files)
    let descriptors = results.filter(d => d !== null);

    // Filter to only signature paths (exactly 5)
    descriptors = descriptors.filter(d => SIGNATURE_PATHS.includes(d.id));

    console.log(`[RebuildManifest] Extracted ${descriptors.length} valid descriptors`);

    // Calculate checksum of descriptors
    const checksum = calculateChecksum(descriptors);

    // Build manifest
    const manifest = {
      descriptors,
      checksum,
      generatedAt: new Date().toISOString(),
      version: '1.0.0'
    };

    // Validate manifest if requested
    if (validate) {
      const validation = await validateManifest(manifest);
      if (!validation.valid) {
        console.error('[RebuildManifest] Manifest validation failed:', validation.errors);
        throw new Error(`Manifest validation failed: ${JSON.stringify(validation.errors, null, 2)}`);
      }
      console.log('[RebuildManifest] Manifest validation passed');
    }

    return manifest;
  } catch (error) {
    console.error('[RebuildManifest] Error rebuilding manifest:', error);
    throw error;
  }
}

/**
 * Compare two manifests for changes
 * @param {Object} oldManifest - Previous manifest
 * @param {Object} newManifest - New manifest
 * @returns {boolean} True if manifests differ
 */
function hasManifestChanged(oldManifest, newManifest) {
  if (!oldManifest || !newManifest) {
    return true;
  }
  return oldManifest.checksum !== newManifest.checksum;
}

export {
  rebuildManifest,
  extractDescriptor,
  calculateChecksum,
  hasManifestChanged,
  validateManifest
};
