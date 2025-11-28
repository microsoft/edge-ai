/**
 * Integration tests for path-to-kata expansion feature
 *
 * When a user selects a learning path, the system should automatically
 * expand it to include all constituent kata IDs in the saved selections.
 */

import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import request from 'supertest';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

describe('Path-to-Kata Expansion', () => {
  let app;
  let testProgressDir;

  beforeAll(async () => {
    process.env.NODE_ENV = 'test';
    process.env.SKIP_FILE_WATCHER = 'true';

    testProgressDir = path.join(__dirname, '../../test-expansion');
    process.env.PROGRESS_DIR = testProgressDir;

    await fs.mkdir(testProgressDir, { recursive: true });

    const appModule = await import('../../app.js');
    app = appModule.default;
  });

  afterAll(async () => {
    await fs.rm(testProgressDir, { recursive: true, force: true });
  });

  beforeEach(async () => {
    const filepath = path.join(testProgressDir, 'learning-catalog-selections-test-user.json');
    try {
      await fs.unlink(filepath);
    } catch {
      // Ignore if file doesn't exist
    }
  });

  describe('Single Path Expansion', () => {
    it('should expand Foundation path to include all its katas', async () => {
      const response = await request(app)
        .post('/api/learning/selections')
        .send({
          userId: 'test-user',
          selectedItems: ['paths-foundation-ai-first-engineering']
        })
        .expect(200);

      expect(response.body.success).toBe(true);

      const selectedItems = response.body.data.selections.selectedItems;

      // Should include the path itself
      expect(selectedItems).toContain('paths-foundation-ai-first-engineering');

      // Should include katas from Foundation path
      const kataIds = selectedItems.filter(id =>
        !id.startsWith('path') && !id.startsWith('lab')
      );
      expect(kataIds.length).toBeGreaterThan(0);
      expect(response.body.data.selectionCount).toBeGreaterThan(1);

      // Verify at least one known kata from Foundation path
      expect(selectedItems).toContain('ai-assisted-engineering-100-inline-suggestions-basics');
    });

    it('should expand Intermediate Infrastructure Architect path', async () => {
      const response = await request(app)
        .post('/api/learning/selections')
        .send({
          userId: 'test-user',
          selectedItems: ['paths-intermediate-infrastructure-architect']
        })
        .expect(200);

      const selectedItems = response.body.data.selections.selectedItems;

      expect(selectedItems).toContain('paths-intermediate-infrastructure-architect');
      expect(response.body.data.selectionCount).toBeGreaterThan(1);

      // Verify file was saved with expanded items
      const filepath = path.join(testProgressDir, 'learning-catalog-selections-test-user.json');
      const savedData = JSON.parse(await fs.readFile(filepath, 'utf-8'));
      expect(savedData.selections.selectedItems.length).toBeGreaterThan(1);
    });
  });

  describe('Multiple Paths Expansion', () => {
    it('should expand multiple paths without duplicating katas', async () => {
      const response = await request(app)
        .post('/api/learning/selections')
        .send({
          userId: 'test-user',
          selectedItems: [
            'paths-foundation-ai-first-engineering',
            'paths-intermediate-devops-excellence'
          ]
        })
        .expect(200);

      const selectedItems = response.body.data.selections.selectedItems;

      // Should have both paths
      expect(selectedItems).toContain('paths-foundation-ai-first-engineering');
      expect(selectedItems).toContain('paths-intermediate-devops-excellence');

      // Should have katas from both paths
      expect(selectedItems.length).toBeGreaterThan(2);

      // Should not have duplicate IDs
      const uniqueIds = new Set(selectedItems);
      expect(uniqueIds.size).toBe(selectedItems.length);
    });
  });

  describe('Mixed Selections (Paths + Standalone Katas)', () => {
    it('should preserve standalone kata selections alongside path expansions', async () => {
      const standaloneKata = 'custom-kata-001';

      const response = await request(app)
        .post('/api/learning/selections')
        .send({
          userId: 'test-user',
          selectedItems: [
            'paths-foundation-ai-first-engineering',
            standaloneKata
          ]
        })
        .expect(200);

      const selectedItems = response.body.data.selections.selectedItems;

      // Should include the standalone kata
      expect(selectedItems).toContain(standaloneKata);

      // Should include the path
      expect(selectedItems).toContain('paths-foundation-ai-first-engineering');

      // Should include katas from the path
      expect(selectedItems.length).toBeGreaterThan(2);
    });
  });

  describe('Invalid Path Handling', () => {
    it('should handle non-existent path IDs gracefully', async () => {
      const response = await request(app)
        .post('/api/learning/selections')
        .send({
          userId: 'test-user',
          selectedItems: ['paths-nonexistent-path', 'valid-kata-001']
        })
        .expect(200);

      expect(response.body.success).toBe(true);

      const selectedItems = response.body.data.selections.selectedItems;

      // Should preserve the invalid path ID (no expansion)
      expect(selectedItems).toContain('paths-nonexistent-path');
      expect(selectedItems).toContain('valid-kata-001');

      // Count should match input (no expansion for invalid path)
      expect(selectedItems.length).toBe(2);
    });
  });

  describe('Deduplication', () => {
    it('should deduplicate katas that appear in multiple selected paths', async () => {
      const response = await request(app)
        .post('/api/learning/selections')
        .send({
          userId: 'test-user',
          selectedItems: [
            'paths-foundation-ai-first-engineering',
            'paths-intermediate-infrastructure-architect',
            'paths-expert-enterprise-integration'
          ]
        })
        .expect(200);

      const selectedItems = response.body.data.selections.selectedItems;

      // Check for duplicates
      const uniqueIds = new Set(selectedItems);
      expect(uniqueIds.size).toBe(selectedItems.length);
    });
  });

  describe('Empty and Edge Cases', () => {
    it('should handle empty selections array', async () => {
      const response = await request(app)
        .post('/api/learning/selections')
        .send({ userId: 'test-user', selectedItems: [] })
        .expect(200);

      expect(response.body.data.selectionCount).toBe(0);
      expect(response.body.data.selections.selectedItems).toEqual([]);
    });

    it('should handle selections with only non-path items', async () => {
      const response = await request(app)
        .post('/api/learning/selections')
        .send({
          userId: 'test-user',
          selectedItems: ['kata-001', 'lab-002', 'assessment-003']
        })
        .expect(200);

      // No expansion should occur
      expect(response.body.data.selections.selectedItems).toHaveLength(3);
      expect(response.body.data.selections.selectedItems).toEqual(['kata-001', 'lab-002', 'assessment-003']);
    });

    it('should handle path-only selection', async () => {
      const response = await request(app)
        .post('/api/learning/selections')
        .send({
          userId: 'test-user',
          selectedItems: ['paths-foundation-ai-first-engineering']
        })
        .expect(200);

      const selectedItems = response.body.data.selections.selectedItems;

      // Should have path plus expanded katas
      expect(selectedItems).toContain('paths-foundation-ai-first-engineering');
      expect(selectedItems.length).toBeGreaterThan(1);
    });

    it('should update selectionCount to include expanded katas', async () => {
      const response = await request(app)
        .post('/api/learning/selections')
        .send({
          userId: 'test-user',
          selectedItems: ['paths-foundation-ai-first-engineering']
        })
        .expect(200);

      // Selection count should reflect expanded items (path + katas)
      expect(response.body.data.selectionCount).toBeGreaterThan(1);

      // Verify saved file has correct count
      const filepath = path.join(testProgressDir, 'learning-catalog-selections-test-user.json');
      const savedData = JSON.parse(await fs.readFile(filepath, 'utf-8'));
      expect(savedData.selections.selectionCount).toBe(response.body.data.selectionCount);
      expect(savedData.selections.selectionCount).toBeGreaterThan(1);
    });
  });
});
