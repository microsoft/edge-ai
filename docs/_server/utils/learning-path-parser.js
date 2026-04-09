import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class LearningPathParser {
  constructor() {
    this.manifest = new Map();
    this.initialized = false;
  }

  async initialize(pathsDirectory = path.join(__dirname, '../../../learning/paths')) {
    if (this.initialized) {
      return this.manifest;
    }

    try {
      const files = await fs.readdir(pathsDirectory);
      const mdFiles = files.filter(f => f.endsWith('.md'));

      for (const file of mdFiles) {
        const filePath = path.join(pathsDirectory, file);
        const content = await fs.readFile(filePath, 'utf-8');
        const pathData = this.parsePathMarkdown(content, file);

        if (pathData) {
          this.manifest.set(pathData.pathId, pathData);
        }
      }

      this.initialized = true;
      console.log(`Initialized learning path manifest with ${this.manifest.size} paths`);
      return this.manifest;
    } catch (error) {
      console.error('Error initializing learning path parser:', error);
      throw error;
    }
  }

  parsePathMarkdown(markdownContent, fileName) {
    const kataLinkRegex = /\[.*?\]\(\.\.\/katas\/([^/]+)\/([^)\.]+)\.md\)/g;
    const kataIds = [];
    const seenIds = new Set();

    let match;
    while ((match = kataLinkRegex.exec(markdownContent)) !== null) {
      const category = match[1];
      const kataSlug = match[2];
      const kataId = `${category}-${kataSlug}`;

      if (!seenIds.has(kataId)) {
        kataIds.push(kataId);
        seenIds.add(kataId);
      }
    }

    const titleMatch = markdownContent.match(/^#\s+(.+)$/m);
    const title = titleMatch ? titleMatch[1] : fileName.replace('.md', '');
    const pathId = fileName.replace('.md', '');

    return {
      pathId,
      title,
      kataIds,
      totalKatas: kataIds.length
    };
  }

  getPathKatas(pathId) {
    return this.manifest.get(pathId)?.kataIds || [];
  }

  getAllPaths() {
    return Array.from(this.manifest.values());
  }

  getPathData(pathId) {
    return this.manifest.get(pathId);
  }
}

export default new LearningPathParser();
