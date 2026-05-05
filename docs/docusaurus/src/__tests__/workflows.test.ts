/** @jest-environment node */
import fs from 'node:fs';
import path from 'node:path';
import yaml from 'js-yaml';

const repoRoot = path.resolve(__dirname, '..', '..', '..', '..');

describe('CI/CD workflow files', () => {
  it('pages-deploy.yml references docs/docusaurus/ for build paths', () => {
    const content = fs.readFileSync(
      path.join(repoRoot, '.github', 'workflows', 'pages-deploy.yml'),
      'utf8',
    );
    const parsed = yaml.load(content);
    const text = JSON.stringify(parsed);
    expect(text).toContain('docs/docusaurus');
  });

  it('pages-deploy.yml preserves the ATTEST-DOCUMENTATION job', () => {
    const content = fs.readFileSync(
      path.join(repoRoot, '.github', 'workflows', 'pages-deploy.yml'),
      'utf8',
    );
    const parsed = yaml.load(content) as Record<string, unknown>;
    const jobs = parsed.jobs as Record<string, unknown>;
    const attestJob = Object.keys(jobs).find((key) => key.includes('attest'));
    expect(attestJob).toBeDefined();

    const jobText = JSON.stringify(jobs[attestJob!]);
    expect(jobText).toContain('documentation-build-');
  });

  it('docusaurus-tests.yml uses Node.js 24', () => {
    const content = fs.readFileSync(
      path.join(repoRoot, '.github', 'workflows', 'docusaurus-tests.yml'),
      'utf8',
    );
    const parsed = yaml.load(content);
    const text = JSON.stringify(parsed);
    expect(text).toMatch(/node-version.*24/);
  });

  it('workflow files are valid YAML', () => {
    const pagesContent = fs.readFileSync(
      path.join(repoRoot, '.github', 'workflows', 'pages-deploy.yml'),
      'utf8',
    );
    const testsContent = fs.readFileSync(
      path.join(repoRoot, '.github', 'workflows', 'docusaurus-tests.yml'),
      'utf8',
    );

    const pagesParsed = yaml.load(pagesContent);
    const testsParsed = yaml.load(testsContent);

    expect(pagesParsed).toBeTruthy();
    expect(testsParsed).toBeTruthy();
  });
});
