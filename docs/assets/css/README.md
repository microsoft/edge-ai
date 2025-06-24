# CSS Organization Documentation

## Structure Overview

This directory contains the modular CSS architecture for the Edge AI Platform documentation site.

```text
docs/assets/css/
├── main.css                 # Main entry point (imports all modules)
├── critical.css             # Critical above-the-fold styles
├── README.md               # This documentation
├── theme/
│   ├── variables.css       # CSS custom properties and brand colors
│   └── base.css            # Typography, reset, and base styles
├── layout/
│   ├── sidebar.css         # Sidebar navigation and structure
│   ├── content.css         # Main content area and article layout
│   └── header.css          # Header and top navigation
├── components/
│   ├── buttons.css         # Button styles and states
│   ├── forms.css           # Form controls and inputs
│   ├── metadata.css        # Page metadata and information display
│   └── footer.css          # Footer component styling
├── plugins/
│   └── toc.css             # Table of contents plugin styling
└── features/
    ├── breadcrumbs.css     # Breadcrumb navigation
    ├── responsive.css      # Mobile and responsive adaptations
    └── interactive-progress.css # Progress tracking functionality
```

## Loading Order

The CSS files are loaded in the following order via `main.css`:

1. **Theme Foundation** - Variables and base styles
2. **Layout Structure** - Sidebar, content area, header
3. **UI Components** - Buttons, forms, metadata, footer
4. **Plugin Integration** - TOC and other docsify plugins
5. **Features** - Breadcrumbs, responsive design, interactive features

## Development Guidelines

### Adding New Styles

1. **Theme-related changes**: Add to `theme/variables.css` or `theme/base.css`
2. **Layout modifications**: Use appropriate file in `layout/`
3. **New components**: Create new file in `components/`
4. **Plugin customizations**: Add to `plugins/`
5. **Feature additions**: Create new file in `features/`

### CSS Variables

All CSS custom properties are defined in `theme/variables.css`. Use these variables throughout the codebase for consistency:

- `--theme-color` - Primary brand color
- `--theme-color-secondary` - Secondary brand color
- `--sidebar-width` - Sidebar width
- Dark mode variables are also available

### Dark Mode

Dark mode styles are integrated throughout the component files using CSS variables. The dark mode implementation follows the pattern:

```css
body.dark .component {
  property: var(--theme-variable-name, fallback-value);
}
```

### Performance Considerations

- `critical.css` contains essential above-the-fold styles
- `main.css` imports all modules in optimal loading order
- CSS is organized to minimize specificity conflicts
- Browser caching is optimized through modular structure

## Migration from Inline Styles

This modular structure replaces the previous inline CSS in `index.html`. The migration provides:

- **Better organization** - Logical separation of concerns
- **Improved maintainability** - Easy to find and modify specific styles
- **Enhanced performance** - Optimized loading and caching
- **Developer experience** - Clear structure for contributions

## Contributing

When contributing new CSS:

1. Follow the existing organization structure
2. Use CSS variables from `theme/variables.css`
3. Include dark mode variants where applicable
4. Update this README if adding new files or categories
5. Test across different screen sizes and browsers
