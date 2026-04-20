import type { Config } from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Edge AI Platform',
  tagline: 'Enterprise-grade edge AI infrastructure',
  favicon: 'assets/logo.png',

  url: 'https://microsoft.github.io',
  baseUrl: '/edge-ai/',

  organizationName: 'microsoft',
  projectName: 'edge-ai',
  trailingSlash: false,

  onBrokenLinks: 'warn',
  onDuplicateRoutes: 'throw',

  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },



  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          path: '../',
          routeBasePath: '/',
          sidebarPath: './sidebars.js',
          exclude: [
            'docusaurus/**',
            'images/**',
            '**/node_modules/**',
            'assets/**',
            '_parts/**',
            '_server/**',
          ],
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themes: [
    [
      '@easyops-cn/docusaurus-search-local',
      {
        hashed: true,
        docsDir: '../',
        docsRouteBasePath: '/',
        indexBlog: false,
      },
    ],
  ],

  plugins: [
    [
      '@docusaurus/plugin-client-redirects',
      {
        redirects: [
          { from: '/docs/getting-started', to: '/getting-started/' },
          { from: '/docs/contributing', to: '/contributing/' },
          { from: '/docs/observability', to: '/observability/' },
          { from: '/docs/build-cicd', to: '/build-cicd/' },
          { from: '/docs/project-planning', to: '/project-planning/' },
          { from: '/docs/solution-adr-library', to: '/solution-adr-library/' },
          {
            from: '/docs/solution-security-plan-library',
            to: '/solution-security-plan-library/',
          },
          {
            from: '/docs/solution-technology-paper-library',
            to: '/solution-technology-paper-library/',
          },
        ],
      },
    ],
    'docusaurus-plugin-image-zoom',
  ],

  themeConfig: {
    image: 'assets/logo.png',
    zoom: {
      selector: '.markdown :not(em) > img',
      background: {
        light: 'rgb(255, 255, 255)',
        dark: 'rgb(50, 50, 50)',
      },
    },
    colorMode: {
      defaultMode: 'light',
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Edge AI Platform',
      logo: {
        alt: 'Edge AI Logo',
        src: 'assets/logo.png',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Documentation',
        },
        {
          href: 'https://github.com/microsoft/edge-ai',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            { label: 'Getting Started', to: '/getting-started/' },
            { label: 'Contributing', to: '/contributing/' },
          ],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/microsoft/edge-ai',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Microsoft Corporation.`,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
