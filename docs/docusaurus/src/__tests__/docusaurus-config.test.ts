import config from '../../docusaurus.config';

describe('Docusaurus configuration', () => {
  it('sets correct site metadata', () => {
    expect(config.title).toBe('Edge AI Platform');
    expect(config.url).toBe('https://microsoft.github.io');
    expect(config.baseUrl).toBe('/edge-ai/');
    expect(config.organizationName).toBe('microsoft');
    expect(config.projectName).toBe('edge-ai');
  });

  it('configures broken link handling', () => {
    // TODO: Restore to 'throw' once legitimate repo-file references (originally
    // resolved by docsify-url-config.js) are converted to absolute GitHub blob
    // URLs and remaining broken anchors are cleaned up. Tracked as follow-up
    // from the Docsify-to-Docusaurus migration PR.
    expect(config.onBrokenLinks).toBe('warn');
    expect(config.onBrokenMarkdownLinks).toBe('warn');
  });

  it('disables the blog', () => {
    const presets = config.presets as Array<[string, Record<string, unknown>]>;
    const classicOptions = presets[0][1];
    expect(classicOptions.blog).toBe(false);
  });

  it('serves docs from the parent directory', () => {
    const presets = config.presets as Array<[string, Record<string, unknown>]>;
    const docsOptions = presets[0][1].docs as Record<string, unknown>;
    expect(docsOptions.path).toBe('../');
    expect(docsOptions.routeBasePath).toBe('/');
  });

  it('includes the client redirect plugin', () => {
    const plugins = config.plugins as Array<unknown>;
    const redirectPlugin = plugins.find(
      (p) => Array.isArray(p) && p[0] === '@docusaurus/plugin-client-redirects',
    );
    expect(redirectPlugin).toBeDefined();
  });

  it('includes the search plugin', () => {
    const themes = config.themes as Array<unknown>;
    const searchTheme = themes?.find(
      (t) => Array.isArray(t) && t[0] === '@easyops-cn/docusaurus-search-local',
    );
    expect(searchTheme).toBeDefined();
  });

  it('respects color scheme preference', () => {
    const themeConfig = config.themeConfig as Record<string, unknown>;
    const colorMode = themeConfig.colorMode as Record<string, unknown>;
    expect(colorMode.respectPrefersColorScheme).toBe(true);
  });
});
