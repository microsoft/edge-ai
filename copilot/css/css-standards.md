# CSS Coding Standards

## Context-Aware Application

These CSS coding standards apply to the Edge AI Platform documentation system, which uses a sophisticated modular CSS architecture built on Docsify. The standards address both current practices and industry best practices for modern CSS development.

## Architecture Patterns

### Modular CSS Architecture

The Edge AI Platform implements a hierarchical modular CSS system optimized for maintainability and performance:

```css
/* File: main.css - Import orchestration with performance optimization */
/* CRITICAL PATH - Essential Foundation */
@import './theme/variables.css';       /* Design system tokens */
@import './theme/dark-mode.css';       /* Theme variants */

/* LAYOUT FOUNDATION - Core Structure */
@import './layout/containers.css';     /* Grid and container systems */
@import './layout/responsive.css';     /* Responsive behavior */
@import './layout/content.css';        /* Content area layouts */

/* UI COMPONENTS - Modular Components */
@import './components/buttons.css';    /* Button variants and states */
@import './components/forms.css';      /* Form controls and validation */
@import './components/notifications.css'; /* Alert and notification systems */

/* FEATURES - Functional Enhancements */
@import './features/breadcrumbs.css';  /* Navigation features */
@import './features/interactive-progress.css'; /* Progress tracking */

/* PLUGIN INTEGRATIONS - Third-party Extensions */
@import './plugins/page-toc.css';      /* Table of contents styling */
@import './plugins/search.css';        /* Search functionality styling */

/* OVERRIDES - Framework Compatibility */
@import './overrides/docsify-aggressive-overrides.css'; /* Framework integration */
```

**Architectural Principles:**

- **Separation of Concerns**: Each directory serves a specific architectural purpose
- **Loading Order Optimization**: Critical path loading followed by progressive enhancement
- **Dependency Management**: Clear import hierarchy prevents circular dependencies
- **Framework Integration**: Dedicated override system for third-party framework compatibility

### CSS Custom Properties (Design System)

All design tokens are centralized in `theme/variables.css` creating a robust design system:

```css
/* File: theme/variables.css - Design system foundation */
:root {
  /* Color System */
  --theme-color: #0078d4;              /* Primary brand color */
  --theme-color-light: #40a9ff;        /* Light variant */
  --theme-color-dark: #0056b3;         /* Dark variant */

  /* Spacing System - Consistent rhythm */
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
  --spacing-xl: 32px;
  --spacing-xxl: 48px;

  /* Typography Scale */
  --font-size-base: 16px;
  --font-size-sm: 14px;
  --font-size-lg: 18px;
  --line-height-base: 1.6;
  --font-weight-normal: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;

  /* Layout Dimensions */
  --sidebar-width: 280px;
  --toc-width: 280px;
  --navbar-height: 65px;
  --content-margin-inline: 32px;

  /* Animation System */
  --transition-fast: 150ms ease;
  --transition-medium: 250ms ease;
  --transition-slow: 500ms ease;

  /* Z-Index Layers - Organized stacking context */
  --z-sidebar: 60;
  --z-sidebar-toggle: 50;
  --z-main-overlay: 40;
  --z-github-corner: 30;
  --z-app-nav: 20;
  --z-toc-nav: 15;
  --z-cover: 10;
  --z-content: 1;
}

/* Dark Mode Variants */
body.dark {
  --bg-primary: #1a1a1a;
  --bg-secondary: #2d2d2d;
  --text-primary: rgba(255, 255, 255, 0.9);
  --text-secondary: rgba(255, 255, 255, 0.7);
  --border-color: rgba(255, 255, 255, 0.1);
}
```

**Design System Benefits:**

- **Consistency**: All components use the same design tokens
- **Maintainability**: Single source of truth for design decisions
- **Theming**: Automatic dark mode support through variable switching
- **Scalability**: Easy to add new variants and themes

## Code Quality Standards

### Specificity Management

Maintain low specificity to prevent cascade conflicts and ensure maintainable code:

```css
/* EXCELLENT: Low specificity using semantic classes (0-1-0) */
.sidebar-nav-item {
  color: var(--sidebar-text-primary);
  padding: var(--spacing-sm) var(--spacing-md);
  border-radius: var(--border-radius);
  transition: var(--transition-fast);
}

.sidebar-nav-item--active {
  color: var(--theme-color);
  background: var(--sidebar-nav-active-bg);
  font-weight: var(--font-weight-medium);
}

/* GOOD: Moderate specificity when contextually necessary (0-2-1) */
.sidebar .nav-item.active {
  color: var(--theme-color);
  background: var(--sidebar-nav-active-bg);
}

/* ACCEPTABLE: Higher specificity for framework overrides (1-1-1) */
#app .sidebar-nav .active {
  /* Framework integration necessity */
  color: var(--theme-color);
}

/* AVOID: Unnecessarily high specificity (1-3-3) */
#sidebar .sidebar-nav ul li.nav-item.active a.link {
  /* Overly specific - refactor to use classes */
  color: var(--theme-color);
}
```

**Specificity Guidelines:**

- **Target Range**: Keep most selectors under 0-3-0 specificity
- **Use Classes**: Prefer `.class` over `#id` for styling
- **Semantic Naming**: Use descriptive class names that indicate function
- **Context-Aware**: Higher specificity acceptable for framework integration

### `!important` Declaration Policy

Use `!important` sparingly and **ALWAYS** with comprehensive documentation:

```css
/* REQUIRED: Framework override with detailed justification */
.sidebar-nav li.active > a,
.sidebar ul li.active a {
  /* !important required: Docsify framework uses inline styles and
     high-specificity selectors that cannot be overridden through
     normal cascade. This override ensures brand consistency. */
  color: var(--theme-color) !important;
  background: rgba(0, 120, 212, 0.08) !important;
  font-weight: 500 !important;
  border-radius: 4px !important;
}

/* ACCEPTABLE: Utility class system */
.u-hidden {
  /* !important justified: Utility classes must override component styles */
  display: none !important;
}

/* GOOD: Documented animation override */
.no-motion {
  /* !important required: Overrides animation preferences for accessibility */
  animation: none !important;
  transition: none !important;
}

/* AVOID: Unnecessary important without justification */
.my-component {
  margin: 20px !important; /* Remove - no framework conflict exists */
  padding: 10px !important; /* Bad - can be achieved with proper specificity */
}
```

**`!important` Usage Rules:**

1. **Documentation Required**: Every `!important` must include a comment explaining necessity
2. **Specific Justifications**: Framework overrides, utility classes, accessibility requirements
3. **Alternatives First**: Explore cascade layers, specificity management, and architectural solutions
4. **Regular Review**: Audit `!important` declarations during refactoring cycles

### Dark Mode Implementation

**MANDATORY** dark mode support for all components using the CSS custom property system:

```css
/* EXCELLENT: Automatic dark mode through design system */
.notification {
  /* Colors automatically switch based on body.dark class */
  background: var(--bg-primary);
  color: var(--text-primary);
  border: 1px solid var(--border-color);
  box-shadow: var(--shadow-md);
}

.notification--error {
  /* Error states work in both themes */
  background: var(--color-error-bg);
  color: var(--color-error-text);
  border-color: var(--color-error-border);
}

/* GOOD: Component-specific dark mode adjustments */
.code-block {
  background: var(--bg-secondary);
  color: var(--text-primary);
}

body.dark .code-block {
  /* Additional dark mode specific adjustments if needed */
  background: var(--code-bg-dark, #2d2d2d);
}

/* AVOID: Hardcoded colors that ignore theming */
.notification {
  background: #ffffff;  /* Breaks dark mode */
  color: #000000;       /* No theme awareness */
  border: 1px solid #cccccc;
}
```

**Dark Mode Best Practices:**

- **Design System First**: Use custom properties from `theme/variables.css`
- **Contrast Ratios**: Ensure WCAG 2.1 AA compliance in both themes
- **Testing Required**: Validate all components in both light and dark modes
- **Semantic Naming**: Use semantic color names rather than literal colors

## Performance Guidelines

### CSS Loading Optimization

Strategic import ordering optimizes loading performance and prevents render blocking:

```css
/* CRITICAL PATH: Essential styles loaded first */
@import './theme/variables.css';       /* 0ms blocking - CSS variables */
@import './theme/dark-mode.css';       /* 0ms blocking - theme variants */

/* LAYOUT FOUNDATION: Core structure */
@import './layout/containers.css';     /* Above-fold layout critical */
@import './layout/responsive.css';     /* Responsive behavior essential */

/* PROGRESSIVE ENHANCEMENT: Load by priority */
@import './components/sidebar-branding.css';  /* Visible branding first */
@import './components/notifications.css';     /* Interactive feedback */
@import './features/micro-animations.css';    /* Enhancement features */

/* DEFERRED: Non-critical enhancements */
@import './plugins/search.css';        /* Search functionality */
@import './features/interactive-progress.css'; /* Advanced features */
```

**Performance Optimization Techniques:**

```css
/* Hardware acceleration for animations */
.animated-element {
  transform: translateZ(0);     /* Create compositing layer */
  will-change: transform;       /* Hint browser optimization */
  backface-visibility: hidden;  /* Prevent flicker */
}

/* Efficient selector patterns */
.component {
  /* Good: Single class selector (fast) */
}

.component .child {
  /* Good: Shallow nesting (acceptable) */
}

/* Avoid: Deep nesting and complex selectors */
.container .wrapper .content .item .text .link {
  /* Slow: Excessive descendant selectors */
}
```

### Critical CSS Strategy

Implement critical CSS for above-the-fold performance:

```css
/* File: critical.css - Above-the-fold essentials */
/* Load inline in <head> for immediate rendering */

/* Essential layout structure */
.app-container {
  display: flex;
  min-height: 100vh;
}

.sidebar {
  width: var(--sidebar-width);
  background: var(--sidebar-gradient);
  border-right: 1px solid var(--sidebar-border-color);
}

.main-content {
  flex: 1;
  min-width: 0; /* Prevent flex item overflow */
}

/* Critical typography */
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  font-size: var(--font-size-base);
  line-height: var(--line-height-base);
  color: var(--text-primary);
}
```

## Responsive Design Standards

### Mobile-First Progressive Enhancement

Implement responsive design using established breakpoints and mobile-first methodology:

```css
/* EXCELLENT: Mobile-first with semantic breakpoints */
.navigation {
  /* Mobile styles (default - 320px+) */
  display: block;
  padding: var(--spacing-sm);
  font-size: var(--font-size-sm);
}

@media (min-width: 768px) {
  .navigation {
    /* Tablet styles (768px+) */
    display: flex;
    padding: var(--spacing-md);
    font-size: var(--font-size-base);
  }
}

@media (min-width: 1024px) {
  .navigation {
    /* Desktop styles (1024px+) */
    padding: var(--spacing-lg);
    font-size: var(--font-size-lg);
  }
}

@media (min-width: 1440px) {
  .navigation {
    /* Large desktop styles (1440px+) */
    padding: var(--spacing-xl);
  }
}

/* GOOD: Container query for component-based responsiveness */
.card-container {
  container-type: inline-size;
}

@container (min-width: 400px) {
  .card {
    display: grid;
    grid-template-columns: 1fr 2fr;
    gap: var(--spacing-md);
  }
}
```

**Responsive Design Principles:**

- **Mobile-First**: Start with mobile styles as the foundation
- **Progressive Enhancement**: Add complexity for larger screens
- **Flexible Units**: Use relative units (rem, em, %, vw, vh) over fixed pixels
- **Touch-Friendly**: Ensure minimum 44px touch targets for interactive elements

### Advanced Responsive Patterns

```css
/* EXCELLENT: Intrinsic web design patterns */
.responsive-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(300px, 100%), 1fr));
  gap: var(--spacing-lg);
}

/* GOOD: Responsive typography using clamp() */
.heading {
  font-size: clamp(
    var(--font-size-lg),     /* Minimum size */
    4vw,                     /* Preferred size */
    var(--font-size-xxl)     /* Maximum size */
  );
  line-height: clamp(1.2, 1.2 + 0.5vw, 1.6);
}

/* EXCELLENT: Responsive spacing */
.section {
  padding: clamp(
    var(--spacing-md),       /* Minimum padding */
    5vw,                     /* Responsive scaling */
    var(--spacing-xxl)       /* Maximum padding */
  );
}
```

## Advanced CSS Features

### CSS Grid and Flexbox Best Practices

```css
/* EXCELLENT: Modern CSS Grid layout */
.documentation-layout {
  display: grid;
  grid-template-areas:
    "sidebar header header"
    "sidebar content toc"
    "sidebar footer footer";
  grid-template-columns: var(--sidebar-width) 1fr var(--toc-width);
  grid-template-rows: var(--navbar-height) 1fr auto;
  min-height: 100vh;
}

.sidebar { grid-area: sidebar; }
.header { grid-area: header; }
.content { grid-area: content; }
.toc { grid-area: toc; }
.footer { grid-area: footer; }

/* GOOD: Flexbox for component layouts */
.card {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
}

.card__header {
  flex: 0 0 auto; /* Don't grow or shrink */
}

.card__content {
  flex: 1 1 auto; /* Grow and shrink as needed */
}

.card__footer {
  flex: 0 0 auto; /* Don't grow or shrink */
}
```

### Modern CSS Features Implementation

```css
/* EXCELLENT: CSS Custom Properties with calculations */
.dynamic-component {
  --base-size: 16px;
  --scale-factor: 1.25;
  --dynamic-size: calc(var(--base-size) * var(--scale-factor));

  font-size: var(--dynamic-size);
  padding: calc(var(--dynamic-size) * 0.5);
  margin: calc(var(--dynamic-size) * 0.25);
}

/* GOOD: Modern color functions */
.theme-aware-component {
  background: color-mix(in srgb, var(--theme-color) 10%, transparent);
  border: 1px solid color-mix(in srgb, var(--theme-color) 30%, transparent);
}

/* EXCELLENT: Container queries for true component responsiveness */
.sidebar {
  container-type: inline-size;
  container-name: sidebar;
}

@container sidebar (max-width: 200px) {
  .nav-item__text {
    display: none; /* Hide text in narrow sidebar */
  }

  .nav-item__icon {
    margin: 0 auto; /* Center icons */
  }
}
```

## Error Prevention and Debugging

### Common CSS Anti-Patterns to Avoid

```css
/* AVOID: Inline styles in HTML */
<!-- Bad: Breaks separation of concerns -->
<div style="color: red; margin: 10px; background: #fff;">

/* AVOID: Styles embedded in JavaScript */
// Bad: Violates CSS separation principle
element.style.backgroundColor = '#ff0000';
element.style.margin = '20px';

/* AVOID: Magic numbers without context */
.component {
  width: 284px;        /* Why 284px? Use semantic variables */
  height: 47px;        /* Why 47px? Document rationale */
  top: -23px;          /* Why -23px? Use logical positioning */
}

/* GOOD: Semantic variables with clear purpose */
.component {
  width: calc(var(--sidebar-width) + var(--spacing-sm));
  height: var(--touch-target-min); /* 44px minimum for accessibility */
  top: calc(var(--header-height) * -0.5); /* Half header overlap */
}

/* AVOID: Overly complex selectors */
#main .content .wrapper .section .article .paragraph .text .link.active {
  /* 1-7-1 specificity - unmaintainable */
  color: var(--theme-color);
}

/* GOOD: Component-based approach */
.article-link--active {
  /* 0-1-0 specificity - maintainable */
  color: var(--theme-color);
}
```

### CSS Validation and Debugging

```css
/* EXCELLENT: Self-documenting CSS with validation hints */
.component {
  /* Box Model - ordered by visual impact */
  display: flex;
  position: relative;
  width: 100%;
  max-width: var(--content-max-width);
  padding: var(--spacing-md);
  margin: 0 auto;

  /* Typography - grouped for readability */
  font-family: var(--font-family-base);
  font-size: var(--font-size-base);
  line-height: var(--line-height-base);
  color: var(--text-primary);

  /* Visual Design - appearance properties */
  background: var(--bg-primary);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);

  /* Animation - performance-optimized */
  transition: var(--transition-medium);
  will-change: transform; /* Hint for GPU acceleration */
}

/* GOOD: Debugging utilities for development */
.debug-grid {
  background-image:
    linear-gradient(rgba(255, 0, 0, 0.1) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255, 0, 0, 0.1) 1px, transparent 1px);
  background-size: var(--spacing-md) var(--spacing-md);
}

.debug-outline * {
  outline: 1px solid rgba(255, 0, 0, 0.3);
}
```

## Code Documentation Standards

### Component Documentation Template

```css
/**
 * Component: Sidebar Navigation
 * Purpose: Primary navigation for documentation site with collapsible sections
 *
 * Dependencies:
 *   - theme/variables.css (design tokens)
 *   - layout/containers.css (grid system)
 *   - features/accessibility.css (focus management)
 *
 * Architecture:
 *   - Uses CSS Grid for layout structure
 *   - Implements progressive enhancement for mobile
 *   - Supports keyboard navigation and screen readers
 *
 * Dark Mode: Full support via CSS custom properties
 * Performance: Critical path - loaded in main.css foundation
 * Browser Support: Modern browsers with CSS Grid support
 *
 * @example
 * <nav class="sidebar-nav">
 *   <ul class="sidebar-nav__list">
 *     <li class="sidebar-nav__item">
 *       <a href="#" class="sidebar-nav__link sidebar-nav__link--active">
 *         Active Link
 *       </a>
 *     </li>
 *   </ul>
 * </nav>
 */

.sidebar-nav {
  /* Implementation follows */
}
```

### Complex Selector Documentation

```css
/* Complex Override: Docsify Framework Integration */
/*
 * Specificity: 0-2-1 (required to override framework defaults)
 * Context: Docsify uses high-specificity selectors and inline styles
 * Solution: Targeted override with !important only where necessary
 * Alternative: Would require modifying Docsify core (not maintainable)
 */
.sidebar-nav li.active > a,
.sidebar ul li.active a {
  color: var(--theme-color) !important; /* Framework override necessity */
  background: rgba(0, 120, 212, 0.08) !important;
  font-weight: 500 !important;
  border-radius: 4px !important;
  margin: 1px 0 !important;
}

/* Performance Critical: Hardware Acceleration */
/*
 * Purpose: Optimize animation performance for sidebar collapse
 * Technique: Force GPU layer creation for smooth 60fps animation
 * Browser Support: Modern browsers with hardware acceleration
 * Fallback: Graceful degradation to CPU-based animation
 */
.sidebar--animating {
  transform: translateZ(0); /* Force hardware layer */
  will-change: transform;   /* Browser optimization hint */
  backface-visibility: hidden; /* Prevent rendering artifacts */
}
```

This comprehensive CSS coding standards document ensures maintainable, performant, and scalable stylesheet development while preserving and enhancing the sophisticated modular architecture of the Edge AI Platform documentation system.
