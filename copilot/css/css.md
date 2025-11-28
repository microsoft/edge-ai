# CSS Instructions

## Overview

CSS development for the Edge AI Platform documentation site follows a sophisticated modular architecture designed for maintainability, performance, and scalability. These instructions ensure consistent implementation across all CSS development.

## Core Principles

### 1. Modular Architecture

The CSS system uses a hierarchical modular structure that separates concerns and optimizes loading performance:

```text
docs/assets/css/
├── main.css                 # Import orchestration
├── theme/                   # Design system foundation
├── layout/                  # Layout systems
├── components/              # UI components
├── features/                # Feature-specific styles
├── plugins/                 # Third-party integrations
└── overrides/               # Framework overrides
```

**Key Requirements:**

- Place new styles in the appropriate directory based on function
- Use the `@import` system in `main.css` for loading order control
- Follow established loading order: theme → layout → components → features → plugins → overrides
- **NEVER** embed CSS directly in JavaScript or HTML files

### 2. CSS Custom Properties (Variables)

All design tokens are centralized in `theme/variables.css` to ensure consistency and maintainability:

```css
/* Good: Use established design system */
.component {
  color: var(--theme-color);
  background: var(--bg-secondary);
  border-radius: var(--border-radius);
  spacing: var(--spacing-md);
}

/* Bad: Hardcoded values bypass design system */
.component {
  color: #0078d4;
  background: #f8f9fa;
  border-radius: 4px;
  spacing: 16px;
}
```

**Implementation Standards:**

- **ALWAYS** use existing custom properties from `theme/variables.css`
- Add new custom properties to the theme when introducing new design tokens
- Include dark mode variants for all visual properties
- Use fallback values: `var(--property-name, fallback-value)`

### 3. Dark Mode Support

Full dark mode support is **MANDATORY** for all components using the CSS custom property system:

```css
/* Automatic dark mode via custom properties */
.notification {
  background: var(--bg-primary);     /* Switches automatically */
  color: var(--text-primary);       /* Based on body.dark class */
  border: 1px solid var(--border-color);
}

/* Custom properties handle theme switching in variables.css */
:root { --bg-primary: #ffffff; }
body.dark { --bg-primary: #1a1a1a; }
```

**Requirements:**

- Test all components in both light and dark modes
- Use custom properties that include dark mode variants
- Follow the `body.dark` class pattern for theme activation
- Ensure sufficient contrast ratios in both themes

### 4. Specificity Management

Maintain low specificity to prevent cascade conflicts and ensure maintainable code:

```css
/* Good: Low specificity using semantic classes */
.sidebar-nav-item {
  color: var(--sidebar-text-primary);
}

.sidebar-nav-item--active {
  color: var(--theme-color);
  background: var(--sidebar-nav-active-bg);
}

/* Acceptable: Moderate specificity when contextually necessary */
.sidebar .nav-item.active {
  color: var(--theme-color);
}

/* Avoid: Unnecessarily high specificity */
#sidebar .sidebar-nav ul li.nav-item.active a {
  color: var(--theme-color);
}
```

**Best Practices:**

- Keep specificity as low as possible while achieving desired outcomes
- Use CSS classes over ID selectors for styling
- Prefer structural organization over specificity escalation
- Document any necessary high-specificity selectors

### 5. `!important` Usage Policy

Use `!important` sparingly and **ALWAYS** with documentation explaining the necessity:

```css
/* Required: Framework override with documentation */
.docsify-override {
  /* !important required to override Docsify's inline styles */
  background: var(--sidebar-gradient) !important;
}

/* Acceptable: Third-party integration necessity */
.app-nav a.active {
  /* !important needed for framework compatibility */
  color: var(--theme-color) !important;
}

/* Avoid: Unnecessary important declarations */
.my-component {
  margin: 16px !important; /* Remove - no justification */
}
```

**Usage Guidelines:**

- Document every `!important` with a comment explaining why it's necessary
- Use ONLY for framework overrides, third-party conflicts, or utility classes
- Prefer cascade layers and specificity management over `!important`
- Review and eliminate unnecessary declarations during code reviews

## Performance and Optimization

### Loading Strategy

The CSS loading system is optimized for performance through strategic import ordering:

```css
/* main.css - Performance-optimized loading order */
@import './theme/variables.css';      /* Critical foundation */
@import './layout/containers.css';    /* Layout structure */
@import './components/buttons.css';   /* UI components */
@import './features/responsive.css';  /* Progressive enhancement */
```

**Performance Requirements:**

- Follow the established `@import` order in `main.css`
- Use hardware acceleration hints for animated elements
- Minimize deeply nested selectors (maximum 3-4 levels)
- Group related properties for better compression

### Responsive Design

Implement mobile-first responsive design using established breakpoints:

```css
/* Mobile-first progressive enhancement */
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

## Code Quality Standards

### Naming Conventions

Use semantic, component-based naming that describes function rather than appearance:

```css
/* Good: Semantic naming */
.sidebar-nav-item
.sidebar-nav-item--active
.sidebar-nav-item__icon

/* Good: BEM methodology */
.component-name
.component-name--modifier
.component-name__element

/* Avoid: Appearance-based naming */
.blue-button
.large-text
.top-margin
```

### Code Organization

Structure CSS properties in logical groups for readability and maintainability:

```css
.component {
  /* Box Model */
  display: flex;
  width: 100%;
  padding: var(--spacing-md);
  margin: var(--spacing-sm) 0;

  /* Typography */
  font-size: var(--font-size-base);
  line-height: var(--line-height-base);
  color: var(--text-primary);

  /* Visual */
  background: var(--bg-secondary);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);

  /* Animation */
  transition: var(--transition-medium);
  transform: translateZ(0); /* Hardware acceleration */
}
```

### Documentation Standards

Provide comprehensive documentation for complex components and overrides:

```css
/**
 * Component: Navigation Sidebar
 * Purpose: Primary navigation for documentation site
 * Dependencies: theme/variables.css, layout/containers.css
 * Dark Mode: Full support via CSS custom properties
 * Performance: Critical path - loaded in main.css foundation
 */

.sidebar-nav {
  /* Component implementation */
}

/* Complex override documentation */
/* Override Docsify's navigation specificity */
/* Required for framework compatibility */
.sidebar-nav li.active > a {
  color: var(--theme-color) !important; /* Framework override */
}
```

## Error Prevention

### Common Anti-Patterns to Avoid

1. **Inline Styles**: Never use `style` attributes in HTML
2. **JavaScript Styling**: Never manipulate styles directly in JavaScript
3. **Magic Numbers**: Always use semantic custom properties instead of hardcoded values
4. **Specificity Wars**: Avoid escalating specificity to override styles
5. **Undocumented Overrides**: Always document `!important` and complex selectors

### Code Review Checklist

- [ ] Uses appropriate custom properties from the design system
- [ ] Includes dark mode support through CSS variables
- [ ] Maintains low specificity while achieving design goals
- [ ] Documents any `!important` declarations with justification
- [ ] Follows established naming conventions and code organization
- [ ] Includes responsive behavior for mobile devices
- [ ] Validates without CSS errors
- [ ] Integrates properly with existing component architecture

## Integration Guidelines

### Working with Existing Code

When modifying existing CSS:

1. **Understand the Context**: Review the component's role in the overall architecture
2. **Maintain Patterns**: Follow established patterns within the component
3. **Test Thoroughly**: Verify changes don't break existing functionality
4. **Update Documentation**: Update component documentation and architectural notes

### Adding New Components

When creating new CSS components:

1. **Choose Appropriate Location**: Place in the correct architectural directory
2. **Follow Naming Conventions**: Use semantic, BEM-style naming
3. **Include Full Theme Support**: Implement light and dark mode variants
4. **Document Dependencies**: Note any requirements or architectural decisions
5. **Update Main Import**: Add to the appropriate section of `main.css`

This CSS instruction system ensures maintainable, performant, and scalable stylesheets that integrate seamlessly with the Edge AI Platform's sophisticated modular architecture.
