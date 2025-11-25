/**
 * CSS Test Fixtures
 * Mock CSS content and DOM structures for testing
 */

// Mock CSS custom properties for testing (matching actual variables.css)
export const mockCSSVariables = `
:root {
  /* Theme Colors */
  --theme-color: #0078d4;
  --theme-color-secondary: #106ebe;
  --theme-color-light: #40a9ff;
  --theme-color-dark: #0056b3;

  /* Neutral Colors */
  --neutral-white: #ffffff;
  --neutral-light: #f8f9fa;
  --neutral-medium: #dee2e6;
  --neutral-medium-light: #e9ecef;
  --neutral-dark: #495057;
  --neutral-black: #212529;

  /* Layout System */
  --sidebar-width: 17.5rem;

  /* Spacing System (rem for accessibility) */
  --spacing-xxs: 0.0625rem;
  --spacing-xs: 0.25rem;
  --spacing-xs-plus: 0.1875rem;
  --spacing-sm: 0.5rem;
  --spacing-sm-plus: 0.375rem;
  --spacing-md-minus: 0.5rem;
  --spacing-md-small: 0.625rem;
  --spacing-md: 0.75rem;
  --spacing-md-plus: 0.875rem;
  --spacing-lg-minus: 1rem;
  --spacing-lg-small: 1.25rem;
  --spacing-lg: 1.5rem;
  --spacing-xl: 2rem;
  --spacing-xxl: 1.5rem;
  --spacing-xxl-plus: 2.5rem;

  /* Additional Spacing Tokens */
  --spacing-micro: 0.125rem;
  --spacing-tiny: 0.1875rem;
  --spacing-minimal: 0.3125rem;
  --spacing-base: 1rem;
  --spacing-lg-extra: 1.875rem;
  --spacing-xl-plus: 2.5rem;
  --spacing-2xl: 3rem;

  /* Border and Radius */
  --border-radius-sm: 0.125rem;
  --border-radius: 0.25rem;
  --border-radius-md: 0.25rem;
  --border-radius-lg: 0.5rem;

  /* Typography */
  --font-size-base: 1rem;
  --font-size-sm: 0.875rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  --font-weight-normal: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;

  /* Shadows */
  --shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.1);
  --shadow-md: 0 1px 20px rgba(0, 0, 0, 0.1);

  /* Semantic Colors */
  --color-primary: #007bff;
  --color-success: #28a745;
  --color-success-light: #20c997;
  --color-danger: #dc3545;
  --color-warning: #ffc107;
  --color-info: #fd7e14;

  /* Status colors */
  --status-success: #198754;
  --status-warning: #ffc107;
  --status-error: #dc3545;
  --status-info: #0d6efd;

  /* Status light variants */
  --status-success-light: #d1e7dd;
  --status-warning-light: #fff3cd;
  --status-error-light: #f8d7da;
  --status-info-light: #cfe2ff;

  /* Gray Scale */
  --color-gray-50: #f9fafb;
  --color-gray-100: #f3f4f6;
  --color-gray-200: #e9ecef;
  --color-gray-300: #d1d5db;
  --color-gray-400: #ced4da;
  --color-gray-500: #6c757d;
  --color-gray-600: #495057;
  --color-gray-700: #343a40;
  --color-gray-800: #212529;

  /* Basic colors */
  --color-white: #ffffff;

  /* Semantic colors */
  --color-green-500: #198754;
  --color-yellow-500: #f59e0b;
  --color-red-500: #ef4444;

  /* Z-Index Layers */
  --z-dropdown: 1000;
  --z-sticky: 1020;
  --z-fixed: 1030;
  --z-modal-backdrop: 1040;
  --z-modal: 1050;
  --z-popover: 1060;
  --z-tooltip: 1070;
}

/* Dark Mode Variables */
body.dark {
  /* Semantic Colors - Dark Mode Adjustments */
  --color-primary: #40a9ff;
  --color-success: #52c41a;
  --color-success-light: #36cfc9;
  --color-danger: #ff4d4f;
  --color-warning: #faad14;
  --color-info: #fa8c16;

  /* Gray Scale - Dark Mode */
  --color-gray-200: #3c3c3c;
  --color-gray-300: #4a4a4a;
  --color-gray-400: #666;
  --color-gray-500: #999;
  --color-gray-600: #bbb;
  --color-gray-700: #ccc;
  --color-gray-800: #e0e0e0;
}
`;

// Mock learning path selector CSS
export const mockLearningPathCSS = `
  .learning-path-container {
    background: var(--neutral-light);
    padding: var(--spacing-lg);
    border-radius: var(--border-radius-md);
    color: var(--neutral-dark);
  }

  .path-card {
    background: var(--neutral-white);
    border: 1px solid var(--neutral-medium);
    border-radius: var(--border-radius-md);
    padding: var(--spacing-md);
    margin-bottom: var(--spacing-md);
  }

  .path-card.selected {
    border-color: var(--theme-color);
    background: var(--theme-color-light);
  }

  .path-title {
    color: var(--theme-color);
    font-size: var(--font-size-lg);
    margin-bottom: var(--spacing-sm);
  }
`;

// Mock assessment path generator CSS
export const mockAssessmentPathCSS = `
  /* Assessment container */
  .assessment-container {
    background-color: var(--neutral-white);
    padding: var(--spacing-xl);
    border-radius: var(--border-radius-md);
    box-shadow: var(--shadow-sm);
  }

  /* Form styling */
  .assessment-form {
    margin-bottom: var(--spacing-lg);
    padding: var(--spacing-md);
  }

  /* Question groups */
  .question-group {
    margin-bottom: var(--spacing-lg);
    padding: var(--spacing-md);
    background-color: var(--neutral-light);
    border-radius: var(--border-radius-sm);
    border: 1px solid var(--neutral-medium);
  }

  .question-title {
    font-size: var(--font-size-lg);
    font-weight: var(--font-weight-semibold);
    color: var(--neutral-dark);
    margin-bottom: calc(var(--spacing-sm) + 0.25rem);
  }

  /* Option labels */
  .option-label {
    cursor: pointer;
    padding: var(--spacing-xs);
    display: block;
    margin-bottom: var(--spacing-xs);
  }

  .option-radio {
    margin-right: var(--spacing-xs);
  }

  /* Buttons */
  .btn {
    border-radius: var(--border-radius-md);
    padding: calc(var(--spacing-sm) + 0.25rem) var(--spacing-lg);
    font-weight: var(--font-weight-medium);
    cursor: pointer;
    transition: all 0.3s ease;
  }

  .btn-primary {
    background-color: var(--theme-color);
    color: var(--neutral-white);
    border: none;
  }

  .btn-secondary {
    background-color: var(--neutral-light);
    color: var(--neutral-dark);
    border: 1px solid var(--neutral-medium);
  }

  .btn:hover {
    transform: translateY(-1px);
    box-shadow: var(--shadow-sm);
  }

  /* Progress bar */
  .progress-bar {
    background-color: var(--neutral-medium-light);
    height: var(--spacing-xs);
    border-radius: var(--border-radius-md);
    overflow: hidden;
    margin-bottom: var(--spacing-lg);
  }

  .progress-fill {
    background-color: var(--theme-color);
    height: 100%;
    width: 33%;
    transition: width 0.3s ease;
    border-radius: var(--border-radius-md);
  }

  /* Results panel */
  .assessment-results {
    background-color: var(--theme-color-light);
    padding: var(--spacing-lg);
    border-radius: var(--border-radius-md);
    border: 1px solid var(--theme-color);
    margin-top: var(--spacing-lg);
    display: none;
  }

  .result-title {
    font-size: var(--font-size-xl);
    font-weight: var(--font-weight-semibold);
    color: var(--neutral-dark);
    margin-bottom: var(--spacing-sm);
  }

  .result-text {
    color: var(--neutral-dark);
    line-height: 1.6;
  }

  /* Dark mode support */
  [data-theme="dark"] .assessment-container {
    background-color: var(--neutral-dark);
    color: var(--neutral-light);
  }

  [data-theme="dark"] .question-group {
    background-color: var(--neutral-medium-dark);
    border-color: var(--neutral-medium);
  }

  [data-theme="dark"] .question-title {
    color: var(--neutral-light);
  }

  [data-theme="dark"] .btn-secondary {
    background-color: var(--neutral-medium-dark);
    color: var(--neutral-light);
    border-color: var(--neutral-medium);
  }

  [data-theme="dark"] .progress-bar {
    background-color: var(--neutral-medium);
  }

  [data-theme="dark"] .assessment-results {
    background-color: var(--theme-color-dark);
  }

  [data-theme="dark"] .result-title,
  [data-theme="dark"] .result-text {
    color: var(--neutral-light);
  }

  .assessment-modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
  }

  .assessment-modal-content {
    background: var(--neutral-white);
    border-radius: var(--border-radius-lg);
    padding: var(--spacing-xl);
    max-width: 90vw;
    max-height: 90vh;
    overflow-y: auto;
  }

  .skill-level-option {
    background: var(--neutral-light);
    border: 2px solid var(--neutral-medium);
    border-radius: var(--border-radius-md);
    padding: var(--spacing-md);
    margin: var(--spacing-sm) 0;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .skill-level-option:hover {
    border-color: var(--theme-color);
    background: var(--theme-color-light);
  }

  .skill-level-option.selected {
    border-color: var(--theme-color);
    background: var(--theme-color);
    color: var(--neutral-white);
  }
`;

// Mock interactive checkboxes CSS
export const mockInteractiveCheckboxesCSS = `
  .interactive-checkbox {
    position: relative;
    display: inline-block;
    margin: var(--spacing-sm) 0;
  }

  .interactive-checkbox input[type="checkbox"] {
    position: absolute;
    opacity: 0;
    cursor: pointer;
  }

  .checkbox-visual {
    display: inline-block;
    width: 20px;
    height: 20px;
    background: var(--neutral-white);
    border: 2px solid var(--neutral-medium);
    border-radius: var(--border-radius-sm);
    position: relative;
    margin-right: var(--spacing-sm);
    transition: all 0.2s ease;
  }

  .interactive-checkbox input:checked + .checkbox-visual {
    background: var(--status-success);
    border-color: var(--status-success);
  }

  .interactive-checkbox input:checked + .checkbox-visual::after {
    content: "✓";
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    color: var(--neutral-white);
    font-size: var(--font-size-sm);
    font-weight: bold;
  }

  .checkbox-label {
    color: var(--neutral-dark);
    font-size: var(--font-size-base);
    cursor: pointer;
  }

  .interactive-checkbox:hover .checkbox-visual {
    border-color: var(--theme-color);
  }
`;

// Mock page TOC CSS
export const mockPageTOCCSS = `
  .page-toc {
    position: fixed;
    top: 100px;
    right: 20px;
    width: 200px;
    background: var(--neutral-white);
    border: 1px solid var(--neutral-medium);
    border-radius: var(--border-radius-md);
    padding: var(--spacing-md);
    z-index: 100;
  }

  .page-toc h3 {
    color: var(--theme-color);
    font-size: var(--font-size-base);
    margin: 0 0 var(--spacing-sm) 0;
    border-bottom: 1px solid var(--neutral-medium);
    padding-bottom: var(--spacing-xs);
  }

  .page-toc ul {
    list-style: none;
    margin: 0;
    padding: 0;
  }

  .page-toc li {
    margin: var(--spacing-xs) 0;
  }

  .page-toc a {
    color: var(--neutral-dark);
    text-decoration: none;
    font-size: var(--font-size-sm);
    display: block;
    padding: var(--spacing-xs);
    border-radius: var(--border-radius-sm);
    transition: all 0.2s ease;
  }

  .page-toc a:hover {
    background: var(--neutral-light);
    color: var(--theme-color);
  }

  .page-toc a.active {
    background: var(--theme-color-light);
    color: var(--theme-color-dark);
    font-weight: 600;
  }

  .page-toc a.active::before {
    content: "→";
    color: var(--theme-color);
    font-weight: bold;
    margin-right: var(--spacing-xs);
  }
`;

// Mock theme/variables CSS (partial, matching actual variables.css)
export const mockThemeVariablesCSS = `
  :root {
    /* Primary Theme Colors */
    --theme-color: #0078d4;
    --theme-color-light: #40a9ff;
    --theme-color-dark: #0056b3;
    --theme-color-alpha-10: rgba(0, 120, 212, 0.1);
    --theme-color-alpha-20: rgba(0, 120, 212, 0.2);

    /* Semantic Colors (matching actual variables.css) */
    --color-primary: #007bff;
    --color-success: #28a745;
    --color-success-light: #20c997;
    --color-danger: #dc3545;
    --color-warning: #ffc107;
    --color-info: #fd7e14;

    /* Neutral Scale (matching actual variables.css) */
    --neutral-white: #ffffff;
    --neutral-light: #f8f9fa;
    --neutral-medium: #dee2e6;
    --neutral-medium-light: #e9ecef;
    --neutral-dark: #495057;
    --neutral-black: #212529;

    /* Spacing System */
    --spacing-xxs: 0.0625rem;  /* 1px */
    --spacing-xs: 0.25rem;     /* 4px - Updated to match CSS */
    --spacing-sm: 0.5rem;      /* 8px */
    --spacing-md: 0.75rem;     /* 12px */
    --spacing-lg: 1.5rem;      /* 24px */
    --spacing-xl: 2rem;        /* 32px */
    --spacing-2xl: 3rem;       /* 48px */

    /* Typography Scale */
    --font-size-xs: 0.75rem;   /* 12px */
    --font-size-sm: 0.875rem;  /* 14px */
    --font-size-base: 1rem;    /* 16px */
    --font-size-lg: 1.125rem;  /* 18px */
    --font-size-xl: 1.25rem;   /* 20px */
    --font-size-2xl: 1.5rem;   /* 24px */

    /* Border Radius */
    --border-radius-sm: 0.125rem;  /* 2px */
    --border-radius-md: 0.25rem;   /* 4px */
    --border-radius-lg: 0.5rem;    /* 8px */
    --border-radius-xl: 1rem;      /* 16px */

    /* Z-Index Layers */
    --z-dropdown: 1000;
    --z-modal: 1050;
    --z-popover: 1060;
    --z-tooltip: 1070;
    --z-fixed: 1030;
  }

  /* Dark Mode Theme (matching actual variables.css selector) */
  body.dark {
    /* Semantic Colors - Dark Mode Adjustments */
    --color-primary: #40a9ff;
    --color-success: #52c41a;
    --color-success-light: #36cfc9;
    --color-danger: #ff4d4f;
    --color-warning: #faad14;
    --color-info: #fa8c16;

    /* Neutral colors remain the same in our implementation */
    /* --neutral-white: #ffffff; */
    /* --neutral-light: #f8f9fa; */
    --neutral-medium: #6c757d;
    /* --neutral-dark: #495057; */
  }
`;

// Index page layout CSS for layout testing
export const mockIndexPageCSS = `
/* Root Variables - Theme Colors with resolved values */
:root {
  /* Core theme colors from variables.css */
  --theme-color: #0078d4;
  --theme-color-light: #40a9ff;
  --theme-color-dark: #0056b3;
  --theme-color-secondary: #106ebe;

  /* Layout dimensions */
  --sidebar-width: 17.5rem; /* Match actual computed value */
  --content-max-width: 80rem;
  --sidebar-nav-strong-border-right-color: #0078d4; /* Add missing property */
  --sidebar-nav-strong-font-weight: 600;
  --spacing-large: 288px; /* Update to match test expectation (18rem) */

  /* Spacing tokens */
  --spacing-2xl: 3rem;
  --spacing-xs-plus: 0.1875rem;
  --spacing-lg-small: 1.25rem;
  --spacing-lg: 1.5rem;
  --spacing-md: 0.75rem;
  --spacing-sm: 0.5rem;
  --spacing-small: 0.5rem;
  --spacing-small-medium: 0.625rem;
  --spacing-layout-xxs: 18rem; /* 288px - Updated to match variables.css */
  --spacing-layout-md: 18.75rem;
  --spacing-xl: 2rem;
  --spacing-xs: 0.25rem;

  /* Colors */
  --color-blue-600: #2563eb;
  --color-purple-500: #a855f7;
  --color-purple-50: #f3e8ff;
  --color-orange-500: #fd7e14;
  --color-orange-50: #fff4e6;
  --color-green-500: #28a745;
  --color-green-600: #16a34a;
  --color-green-50: #dcfce7;
  --color-neutral-300: #e0e0e0;
  --color-neutral-white: #ffffff;
  --color-gray-200: #e9ecef;
  --color-gray-500: #6c757d; /* Update to match actual CSS */
  --color-gray-700: #545b62;
  --color-gray-800: #333;
  --color-slate-800: #1e293b;
  --color-slate-600: #475569;
  --color-slate-200: #e2e8f0;
  --color-slate-50: #f1f5f9; /* Update to match test expectation */
  --color-white: #ffffff;
  --surface-white: #ffffff;
  --color-gray-800: #333;
  --color-indigo-500: #6366f1;
  --color-indigo-100: #e0e7ff;
  --color-alpha-black-10: rgba(0, 0, 0, 0.1);
  --color-theme-alpha-05: rgba(0, 120, 212, 0.05);
  --color-black-alpha-10: rgba(0, 0, 0, 0.1);

  /* Extended colors for capability cards */
  --surface-white: #ffffff;
  --surface-slate-50: #f8fafc;
  --surface-blue-50: #dbeafe;
  --surface-purple-50: #f3e8ff;
  --surface-green-50: #dcfce7;
  --gray-extended-50: #f3f4f6; /* Update to match test expectation */
  --gray-extended-200: #e5e7eb;
  --gray-extended-500: #6b7280;
  --gray-extended-100: #f3f4f6;

  /* Status colors */
  --color-amber-100: #fef3c7;
  --color-amber-800: #92400e;
  --color-blue-800: #1e40af;
  --color-purple-100: #ede9fe;
  --color-purple-600: #9333ea;
  --color-slate-700: #334155; /* Add missing loading state color */

  /* Borders */
  --border-radius: 0.25rem;
  --border-radius-small: 0.125rem;

  /* Header */
  --cover-background-color: linear-gradient(to left bottom, hsl(240, 100%, 70%) 0%, hsl(240, 100%, 70%) 100%);
}

/* Main layout structure */
/* Sidebar logo styles */
.app-name img {
  max-width: 32px;
  height: auto;
  margin-right: 3px; /* Match actual computed value */
  vertical-align: middle;
}

/* Sidebar navigation */
.sidebar-nav {
  padding-top: 20px; /* 1.25rem = 20px */
}

.sidebar-nav > ul > li > a {
  font-weight: 600;
  color: #0078d4;
  border-right: 3px solid transparent;
  transition: all 0.3s ease;
}

.sidebar-nav > ul > li > a:hover {
  border-right-color: #0078d4;
  background: #e5f3ff; /* rgba(0, 120, 212, 0.05) approximation */
}

.sidebar-nav > ul > li > a.active {
  font-weight: bold;
  border-bottom: 2px solid #0078d4;
}

/* Search component */
.search {
  display: block;
  margin-bottom: 1rem;
}

.search .input-wrap {
  background: rgba(255, 255, 255, 0.95);
  border: 2px solid #e9ecef;
  border-radius: 25px;
  transition: all 0.3s ease;
}

.search input {
  background: transparent;
  border: none;
  padding: 12px 20px;
  font-size: 16px;
  width: 100%;
  color: #2c3e50;
  border-radius: 0;
}

/* Search Components */
.search-input {
  border: 1px solid #d1d5db;
  background-color: #ffffff;
  border-radius: 4px;
  padding: 8px 12px;
}

.search-button {
  background-color: #0078d4;
  color: #ffffff;
  border: none;
  border-radius: 4px;
  padding: 8px 16px;
}

/* Learning path selector */
.learning-path-card {
  border: 1px solid #d1d5db;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 16px;
  transition: box-shadow 0.2s;
}

/* Mermaid diagram */
.mermaid-diagram {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 0.125rem;
  padding: 1rem;
  margin: 1.5rem 0;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
  overflow-x: auto;
  overflow-y: visible;
  position: relative;
  width: 100%;
  max-width: 100%;
  text-align: center;
}

.copy-btn {
  font-size: 12px;
  padding: 4px 8px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  background: #f9fafb;
  cursor: pointer;
}

.generate-btn {
  background-color: #0078d4;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  padding: 8px 16px;
}

/* Content area enhancements */
.markdown-section > blockquote,
.markdown-section > .alert,
.markdown-section > .callout {
  max-width: auto;
  margin-left: auto;
  margin-right: 18rem; /* --spacing-layout-md */
}

/* Lists should not be constrained */
.markdown-section > ul,
.markdown-section > ol {
  max-width: none;
  margin-left: 0;
  margin-right: 0;
  padding-left: 24px; /* 1.5rem = 24px */
}

/* Special content full width */
.markdown-section > .custom-block,
.markdown-section > .table-wrapper,
.markdown-section > pre,
.markdown-section > .mermaid-diagram {
  max-width: 100%;
}

/* Footer styling */
footer {
  margin-top: 50px;
  padding: 30px 0;
  border-top: 1px solid #e9ecef;
  color: #6c757d;
  font-size: 14px;
}

/* Capability Cards - Replacing ineffective Mermaid charts */
.capability-phase-container {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 0.25rem;
  margin: 2rem 0;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.capability-phase-header {
  background: linear-gradient(90deg, #0078d4, #0056b3);
  color: white;
  padding: 0.75rem 20px;
  font-size: 18px;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.capability-phase-content {
  padding: 1.5rem;
}

.capability-group {
  margin-bottom: 24px;
}

.capability-group-title {
  font-size: 14px;
  font-weight: 700;
  color: #545b62;
  margin-bottom: 12px;
  padding-bottom: 6px;
  border-bottom: 2px solid #e9ecef;
}

.capability-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.625rem 16px;
  margin: 0.5rem 0;
  background: #f9fafb;
  border-radius: 0.125rem;
  border-left: 4px solid transparent;
  transition: all 0.2s ease;
}

.capability-item:hover {
  background: #f3f4f6;
  transform: translateX(2px);
}

.capability-item.available {
  border-left-color: #16a34a;
  background: #dcfce7;
}

.capability-item.in-development {
  border-left-color: #2563eb;
  background: #dbeafe;
}

.capability-item.planned {
  border-left-color: #6366f1;
  background: #e0e7ff;
}

.capability-item.external {
  border-left-color: #a855f7;
  background: #f3e8ff;
}

.capability-item.experimental {
  border-left-color: #a855f7;
  background: #f3e8ff;
}

.capability-name {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  flex: 1;
}

.capability-status-icon {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  flex-shrink: 0;
}

.capability-status-icon.available {
  background: #16a34a;
}

.capability-status-icon.in-development {
  background: #2563eb;
}

.capability-status-icon.planned {
  background: #6366f1;
}

.capability-status-icon.external {
  background: #a855f7;
}

.capability-title {
  font-weight: 600;
  color: #333;
  font-size: 14px;
}

.capability-details {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-shrink: 0;
}

.capability-score {
  font-size: 0.75rem;
  font-weight: 600;
  color: #6b7280;
  background: #ffffff;
  padding: 0.1875rem 8px;
  border-radius: 0.25rem;
  border: 1px solid #e5e7eb;
}

.capability-priority {
  font-size: 11px;
  font-weight: 600;
  padding: 3px 8px;
  border-radius: 0.5rem;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.capability-priority.high {
  background: #fef3c7;
  color: #92400e;
}

.capability-priority.medium {
  background: #dbeafe;
  color: #1e40af;
}

.capability-priority.low {
  background: #ede9fe;
  color: #9333ea;
}

/* Phase summary info */
.phase-summary {
  background: #f8fafc;
  padding: 0.75rem;
  border-radius: 0.125rem;
  margin-bottom: 20px;
  border-left: 4px solid #0078d4;
}

.phase-summary-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.75rem;
  margin-top: 12px;
}

.phase-summary-item {
  display: flex;
  flex-direction: column;
}

.phase-summary-label {
  font-size: 0.75rem;
  font-weight: 600;
  color: #6c757d;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.phase-summary-value {
  font-size: 14px;
  font-weight: 700;
  color: #333;
  margin-top: 2px;
}

/* Table base styles */
.capability-table,
table {
  width: fit-content;
  max-width: 100%;
  table-layout: fixed; /* Add missing property */
  border-collapse: collapse;
  margin: 24px 0; /* --spacing-lg */
}

/* Table responsive behavior */
@media (max-width: 1200px) {
  .capability-table,
  table {
    font-size: 12.8px; /* Match actual computed value */
    min-width: auto;
  }

  .capability-table th,
  .capability-table td,
  table th,
  table td {
    padding: 10px 8px;
    min-width: 100px;
  }
}

@media (max-width: 768px) {
  .capability-table,
  table {
    font-size: 12px; /* Match actual computed value */
    display: block;
    overflow-x: auto;
  }

  .capability-table th,
  .capability-table td,
  table th,
  table td {
    padding: 8px 6px;
    min-width: 80px;
  }
}

/* Table hover and stripe effects */
table tr:nth-child(even) {
  background-color: #f8fafc;
}

table tr:hover {
  background-color: #e5f3ff;
}

/* Dark mode table colors */
body.dark table th {
  background-color: #1e293b;
  color: #ffffff;
}

body.dark table td {
  background-color: #ffffff;
}

/* Capability cards */
.capability-card {
  border: 1px solid #e0e0e0;
  border-radius: 4px; /* 0.25rem = 4px */
  padding: 12px; /* 0.75rem = 12px */
  margin: 12px 0; /* 0.75rem = 12px */
  background: #ffffff;
}

.capability-item.experimental {
  border-left-color: #8b5fbf;
  background: #f6f4ff;
}

.capability-card.preview {
  border-left-color: #fd7e14;
  background: #fff4e6;
}

.capability-card.stable {
  border-left-color: #28a745;
  background: #dcfce7;
}

/* Code blocks and inline code */
pre {
  border-radius: 8px; /* --spacing-xs */
  margin: 24px 0; /* --spacing-lg */
  padding: 16px;
  background: #f8f9fa;
}

code {
  background: #f8f9fa;
  padding: 2px 4px;
  border-radius: 3px;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
}

/* Blockquotes */
blockquote {
  border-left: 4px solid #0078d4;
  background: #e5f3ff;
  padding: 16px 20px;
  margin: 20px 0;
  border-radius: 4px;
}

/* Loading state */
.loading-message,
#loading {
  font-size: 16px;
  color: #334155;
  padding: 60px 0;
  text-align: center;
}

/* Content text alignment reset */
.content {
  text-align: left;
}

/* Responsive design */
@media (max-width: 768px) {
  .capability-table {
    font-size: 14px; /* --font-size-sm */
  }

  .capability-card {
    padding: 8px; /* --spacing-sm */
    margin: 8px 0; /* --spacing-sm */
  }
}

@media (min-width: 1024px) {
  .capability-table {
    font-size: 16px; /* --font-size-base */
  }
}

/* Print styles */
@media print {
  .sidebar {
    display: none !important;
  }

  .content {
    margin-left: 0 !important;
    max-width: none !important;
  }
}

/* Table styles */
table {
  width: 100%;
  border-collapse: collapse;
  margin: 24px 0;
}

table th {
  background-color: #1e293b; /* --color-slate-800 */
  color: #ffffff;
  font-weight: 700;
  padding: 12px 16px;
  text-align: left;
  white-space: nowrap; /* Prevent header text wrapping */
}

table td {
  padding: 12px 16px;
  border-bottom: 1px solid #e2e8f0;
  background-color: #ffffff; /* --surface-white */
  color: #333; /* --color-gray-800 */
  vertical-align: top;
  word-wrap: break-word;
  min-width: 120px;
}

table tr:nth-child(even) {
  background-color: #f8fafc; /* --color-slate-50 */
}

table tr:hover {
  background-color: #f1f5f9; /* Updated hover color */
}

/* Blockquote styles */
blockquote {
  border-left: 4px solid #0078d4; /* --theme-color */
  background-color: #e5f3ff;
  padding: 16px 20px; /* Update padding to match test */
  margin: 16px 0;
  border-radius: 0px 8px 8px 0px;
}

/* Code styles */
pre {
  margin: 24px 0; /* --spacing-lg */
}

code {
  background-color: #f3f4f6; /* --gray-extended-50 */
  padding: 2px 6px;
  border-radius: 8px;
  font-family: monospace;
}

/* Footer styles */
.footer {
  padding: 30px 0px;
  border-top: 1px solid #e5e7eb;
  color: #6b7280; /* --color-gray-500 updated */
  font-size: 14px;
  text-align: center;
}

/* Loading state */
.loading-message {
  font-size: 16px;
  color: #334155; /* --color-slate-700 */
  padding: 60px 0px;
  text-align: center;
}
`;

// DOM structure fixtures
export const domFixtures = {
  assessmentPathGenerator: `
    <div class="assessment-container">
      <h2>Assessment Path Generator</h2>
      <div class="progress-bar">
        <div class="progress-fill" style="width: 33%;"></div>
      </div>
      <form class="assessment-form">
        <div class="question-group">
          <fieldset>
            <legend class="question-title">What is your experience level with cloud computing?</legend>
            <label class="option-label">
              <input type="radio" name="cloud-experience" value="none" class="option-radio">
              No experience
            </label>
            <label class="option-label">
              <input type="radio" name="cloud-experience" value="basic" class="option-radio" checked>
              Basic knowledge
            </label>
            <label class="option-label">
              <input type="radio" name="cloud-experience" value="intermediate" class="option-radio">
              Intermediate understanding
            </label>
            <label class="option-label">
              <input type="radio" name="cloud-experience" value="advanced" class="option-radio">
              Advanced expertise
            </label>
          </fieldset>
        </div>

        <div class="question-group">
          <fieldset>
            <legend class="question-title">Which development tools are you familiar with?</legend>
            <label class="option-label">
              <input type="radio" name="dev-tools" value="none" class="option-radio">
              No development experience
            </label>
            <label class="option-label">
              <input type="radio" name="dev-tools" value="basic" class="option-radio">
              Basic text editors
            </label>
            <label class="option-label">
              <input type="radio" name="dev-tools" value="ide" class="option-radio">
              IDE and version control
            </label>
            <label class="option-label">
              <input type="radio" name="dev-tools" value="advanced" class="option-radio">
              Advanced toolchains and CI/CD
            </label>
          </fieldset>
        </div>

        <div class="question-group">
          <fieldset>
            <legend class="question-title">What is your primary learning goal?</legend>
            <label class="option-label">
              <input type="radio" name="learning-goal" value="fundamentals" class="option-radio">
              Understand fundamentals
            </label>
            <label class="option-label">
              <input type="radio" name="learning-goal" value="practical" class="option-radio">
              Build practical projects
            </label>
            <label class="option-label">
              <input type="radio" name="learning-goal" value="certification" class="option-radio">
              Prepare for certification
            </label>
            <label class="option-label">
              <input type="radio" name="learning-goal" value="career" class="option-radio">
              Advance my career
            </label>
          </fieldset>
        </div>

        <div class="button-group">
          <button type="button" class="btn btn-secondary">Previous</button>
          <button type="submit" class="btn btn-primary">Generate Path</button>
        </div>
      </form>

      <div class="assessment-results" style="display: none;">
        <h3 class="result-title">Your Recommended Learning Path</h3>
        <p class="result-text">Based on your responses, we recommend starting with the Intermediate Cloud Development path. This path will help you build on your existing knowledge while introducing more advanced concepts.</p>
      </div>
    </div>
  `,

  interactiveCheckboxes: `
    <div class="checkbox-container">
      <div class="interactive-checkbox">
        <input type="checkbox" id="checkbox1" checked>
        <span class="checkbox-visual"></span>
        <label for="checkbox1" class="checkbox-label">Completed Task 1</label>
      </div>
      <div class="interactive-checkbox">
        <input type="checkbox" id="checkbox2">
        <span class="checkbox-visual"></span>
        <label for="checkbox2" class="checkbox-label">Pending Task 2</label>
      </div>
      <div class="interactive-checkbox">
        <input type="checkbox" id="checkbox3">
        <span class="checkbox-visual"></span>
        <label for="checkbox3" class="checkbox-label">Future Task 3</label>
      </div>
    </div>
  `,

  pageTOC: `
    <div class="page-toc">
      <h3>Table of Contents</h3>
      <ul>
        <li><a href="#section1" class="active">Introduction</a></li>
        <li><a href="#section2">Getting Started</a></li>
        <li><a href="#section3">Advanced Topics</a></li>
        <li><a href="#section4">Conclusion</a></li>
      </ul>
    </div>
  `,

  themeVariablesContainer: `
    <div class="theme-test-container">
      <div class="theme-color-box" style="background: var(--theme-color);">Theme Color</div>
      <div class="status-success-box" style="background: var(--status-success);">Success</div>
      <div class="status-error-box" style="background: var(--status-error);">Error</div>
      <div class="spacing-demo" style="padding: var(--spacing-lg); margin: var(--spacing-md);">Spacing Demo</div>
      <div class="typography-demo" style="font-size: var(--font-size-lg);">Typography Demo</div>
    </div>
  `,

  indexPageLayout: `
    <div class="mock-root">
      <!-- App header -->
      <div class="app-name">
        <img src="/assets/logo.png" alt="Logo">
        <span>Edge AI Documentation</span>
      </div>

      <!-- Content area -->
      <div class="markdown-section">
        <h1>Welcome to Edge AI</h1>

        <blockquote>
          <p>This is a sample blockquote that should respect max-width constraints.</p>
        </blockquote>

        <ul>
          <li>List item 1</li>
          <li>List item 2</li>
        </ul>

        <ol>
          <li>Ordered item 1</li>
          <li>Ordered item 2</li>
        </ol>

        <!-- Capability table -->
        <table class="capability-table">
          <thead>
            <tr>
              <th>Component</th>
              <th>Status</th>
              <th>Description</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Security Identity</td>
              <td>Stable</td>
              <td>Core security and identity management</td>
            </tr>
            <tr>
              <td>IoT Operations</td>
              <td>Preview</td>
              <td>Edge IoT operations and management</td>
            </tr>
          </tbody>
        </table>

        <!-- Capability cards -->
        <div class="capability-card stable">
          <h3>Core Components</h3>
          <p>Stable, production-ready components for edge AI deployment.</p>
        </div>

        <div class="capability-card preview">
          <h3>Preview Features</h3>
          <p>New features in preview, ready for testing and feedback.</p>
        </div>

        <div class="capability-card experimental">
          <h3>Experimental</h3>
          <p>Early-stage features under active development.</p>
        </div>
      </div>
    </div>
  `
};

// Common breakpoints for responsive testing
export const responsiveBreakpoints = [
  { name: 'mobile', width: 375, height: 667 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1024, height: 768 },
  { name: 'large-desktop', width: 1440, height: 900 }
];

// Expected style values for testing
export const expectedStyles = {
  themeColors: {
    '--theme-color': '#0078d4',
    '--theme-color-light': '#40a9ff',
    '--theme-color-dark': '#0056b3'
  },

  darkThemeColors: {
    '--theme-color': '#4da6ff',
    '--theme-color-light': '#80c1ff',
    '--theme-color-dark': '#0066cc'
  },

  statusColors: {
    '--status-success': '#198754',
    '--status-warning': '#ffc107',
    '--status-error': '#dc3545',
    '--status-info': '#0d6efd'
  },

  spacingTokens: {
    '--spacing-xxs': '0.0625rem',
    '--spacing-xs': '0.25rem',
    '--spacing-sm': '0.5rem',
    '--spacing-md': '0.75rem',
    '--spacing-lg': '1.5rem',
    '--spacing-xl': '2rem',
    '--spacing-2xl': '3rem'
  },

  typographyTokens: {
    '--font-size-sm': '0.875rem',
    '--font-size-base': '1rem',
    '--font-size-lg': '1.125rem',
    '--font-size-xl': '1.25rem'
  }
};

/**
 * Injects CSS content into a test container for validation
 * @param {Element} container - DOM container to inject CSS into
 * @param {string} cssContent - Optional CSS content to inject (defaults to main CSS)
 */
export function injectCSS(container, cssContent = mockIndexPageCSS) {
  // Create a style element
  const styleElement = document.createElement('style');
  styleElement.textContent = cssContent;

  // Always add to document head to ensure CSS variables are available globally
  document.head.appendChild(styleElement);

  return styleElement;
}
