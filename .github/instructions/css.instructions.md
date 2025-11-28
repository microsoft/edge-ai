# CSS Implementation Instructions

## File Patterns

This instruction applies to:

- `**/*.css`
- `**/assets/css/**/*.css`
- All CSS files within the Edge AI Platform documentation system

## Architecture Overview

The Edge AI Platform uses a sophisticated modular CSS architecture designed for maintainability, performance, and scalability. Follow these implementation requirements for all CSS development.

## Core Implementation Requirements

### 1. Modular Structure Compliance

**ALWAYS** follow the established modular CSS architecture:

```text
docs/assets/css/
├── main.css                 # Import orchestration only
├── theme/                   # Design system foundation
│   ├── variables.css       # CSS custom properties
│   └── dark-mode.css       # Dark mode variables
├── layout/                  # Layout systems
├── components/              # UI components
├── features/                # Feature-specific styles
├── plugins/                 # Third-party integrations
└── overrides/               # Framework overrides
```

**Required Actions:**

- Place new styles in the appropriate directory based on function
- **NEVER** embed CSS directly in JavaScript or HTML
- **ALWAYS** use the `@import` system in `main.css` for loading order control
- Follow the established loading order: theme → layout → components → features → plugins → overrides

### 2. CSS Custom Properties (Variables)

**MANDATORY** use of CSS custom properties defined in `theme/variables.css`:

```css
/* Good: Use existing variables */
.component {
  color: var(--theme-color);
  background: var(--bg-secondary);
  border-radius: var(--border-radius);
  transition: var(--transition-medium);
}

/* Bad: Hardcoded values */
.component {
  color: #0078d4;
  background: #f8f9fa;
  border-radius: 4px;
  transition: 250ms ease;
}
```

**Required Actions:**

- **ALWAYS** use existing custom properties from `theme/variables.css`
- Add new custom properties to `theme/variables.css` when introducing new design tokens
- Include dark mode variants for all new custom properties
- Use fallback values: `var(--property-name, fallback-value)`

### 3. Specificity Management

**CRITICAL** specificity control to minimize cascade conflicts:

```css
/* Good: Low specificity, use CSS classes */
.sidebar-nav-item {
  color: var(--sidebar-text-primary);
}

.sidebar-nav-item--active {
  color: var(--theme-color);
  background: var(--sidebar-nav-active-bg);
}

/* Acceptable: Moderate specificity when needed */
.sidebar .nav-item.active {
  color: var(--theme-color);
}

/* Bad: High specificity unnecessarily */
#sidebar .sidebar-nav ul li.nav-item.active a {
  color: var(--theme-color);
}
```

**Required Actions:**

- Keep specificity as low as possible while achieving the desired outcome
- Use CSS classes over ID selectors for styling
- Prefer structural organization over specificity hacks
- Document any necessary high-specificity selectors with comments

### 4. `!important` Usage Policy

**CONTROLLED** use of `!important` with mandatory documentation:

```css
/* Good: Documented override with specific justification */
.docsify-override {
  /* !important required to override Docsify's inline styles */
  background: var(--sidebar-gradient) !important;
}

/* Acceptable: Framework integration necessity */
.app-nav a.active {
  /* !important needed for third-party framework override */
  color: var(--theme-color) !important;
}

/* Bad: Unnecessary !important */
.my-component {
  margin: 16px !important; /* Remove - no framework conflict */
}
```

**Required Actions:**

- **ALWAYS** document every `!important` usage with a comment explaining why it's necessary
- Use `!important` ONLY for framework overrides, third-party CSS conflicts, or utility classes
- Prefer specificity management and cascade layers over `!important`
- Review and eliminate unnecessary `!important` declarations during refactoring

### 5. Dark Mode Implementation

**MANDATORY** dark mode support for all new components:

```css
/* Good: Component with dark mode support */
.notification {
  background: var(--bg-primary);
  color: var(--text-primary);
  border: 1px solid var(--border-color);
}

/* Variables automatically handle dark mode via theme/variables.css */
/* body.dark class triggers alternative custom property values */

/* Bad: Missing dark mode consideration */
.notification {
  background: #ffffff;
  color: #000000;
  border: 1px solid #cccccc;
}
```

**Required Actions:**

- **ALWAYS** use custom properties that include dark mode variants
- Test all new components in both light and dark modes
- Follow the `body.dark` class pattern for dark mode activation
- Ensure sufficient contrast ratios in both themes

### 6. Performance Optimization

**REQUIRED** performance considerations for CSS architecture:

```css
/* Good: Efficient selectors and imports */
@import './theme/variables.css';        /* Critical path first */
@import './layout/containers.css';      /* Layout foundation */
@import './components/buttons.css';     /* Components as needed */

.button {
  /* Hardware acceleration for animations */
  transform: translateZ(0);
  will-change: transform;
}

/* Bad: Inefficient loading and selectors */
* + * + * + .deeply-nested .complex .selector {
  /* Avoid overly complex selectors */
}
```

**Required Actions:**

- Follow the established `@import` order in `main.css`
- Use hardware acceleration hints for animated elements
- Minimize deeply nested selectors (max 3-4 levels)
- Group related properties together for better compression

### 7. Responsive Design Implementation

**MANDATORY** mobile-first responsive approach:

```css
/* Good: Mobile-first with progressive enhancement */
.component {
  /* Mobile styles (default) */
  padding: var(--spacing-sm);
  font-size: var(--font-size-sm);
}

@media (min-width: 768px) {
  .component {
    /* Tablet and up */
    padding: var(--spacing-md);
    font-size: var(--font-size-base);
  }
}

@media (min-width: 1024px) {
  .component {
    /* Desktop and up */
    padding: var(--spacing-lg);
    font-size: var(--font-size-lg);
  }
}
```

**Required Actions:**

- **ALWAYS** start with mobile styles as the base
- Use the established breakpoints defined in CSS custom properties
- Test across multiple device sizes and orientations
- Ensure touch-friendly interaction targets (minimum 44px)

## Error Prevention

### Common Anti-Patterns to Avoid

```css
/* AVOID: Inline styles in HTML */
<div style="color: red; margin: 10px;">

/* AVOID: Styles embedded in JavaScript */
element.style.backgroundColor = '#ff0000';

/* AVOID: Overly specific selectors */
#main .sidebar ul.nav li.item a.link.active {

/* AVOID: Magic numbers without custom properties */
.component {
  width: 284px; /* Why 284px? Use semantic variables */
}

/* AVOID: !important without documentation */
.component {
  margin: 20px !important; /* Why important? Document reason */
}
```

### Required Code Quality Standards

1. **Semantic Naming**: Use descriptive, component-based class names
2. **Consistent Formatting**: Follow the established code style from existing files
3. **Logical Grouping**: Group related properties together (box model, typography, visual effects)
4. **Comment Documentation**: Document complex selectors, calculations, and overrides

## Integration with Build System

### CSS Loading Strategy

**REQUIRED** adherence to the established CSS loading architecture:

1. **Critical CSS**: Essential above-the-fold styles loaded first
2. **Main CSS**: Full component system loaded via `@import` chain
3. **Progressive Enhancement**: Feature-specific CSS loaded as needed

### Validation Requirements

- **CSS Validation**: All CSS must pass W3C CSS validation
- **Performance Budget**: Monitor CSS bundle size and loading performance
- **Cross-Browser Testing**: Verify functionality across supported browsers
- **Accessibility Compliance**: Ensure WCAG 2.1 AA compliance for all visual elements

## Documentation Requirements

### File Header Comments

```css
/**
 * Component: Navigation Sidebar
 * Purpose: Primary navigation for documentation site
 * Dependencies: theme/variables.css, layout/containers.css
 * Dark Mode: Full support via CSS custom properties
 * Performance: Critical path - loaded in main.css foundation
 */
```

### Complex Selector Documentation

```css
/* Override Docsify's deeply nested navigation structure */
/* Specificity required to compete with framework defaults */
.sidebar-nav li.active > a,
.sidebar ul li.active a {
  color: var(--theme-color) !important; /* Framework override necessity */
  background: rgba(0, 120, 212, 0.08) !important;
}
```

## Testing and Validation

### Required Testing Checklist

- [ ] Component renders correctly in light and dark modes
- [ ] Responsive behavior verified across breakpoints
- [ ] CSS validates without errors
- [ ] No specificity conflicts with existing components
- [ ] Performance impact assessed and documented
- [ ] Cross-browser compatibility verified
- [ ] Accessibility features maintained or enhanced

### Performance Monitoring

Monitor and optimize:

- CSS bundle size and loading performance
- Specificity conflicts and cascade efficiency
- Custom property usage vs. hardcoded values
- `!important` declaration frequency and justification

## Version Control and Maintenance

### Change Management

- Document architectural decisions in CSS file comments
- Update `docs/assets/css/README.md` when adding new patterns or components
- Maintain backward compatibility unless explicitly migrating legacy code
- Follow semantic versioning principles for significant architectural changes

This implementation ensures maintainable, performant, and scalable CSS development while preserving the sophisticated architecture already established in the Edge AI Platform documentation system.
