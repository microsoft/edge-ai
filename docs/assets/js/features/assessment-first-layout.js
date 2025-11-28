/**
 * Assessment-First Layout Manager
 * Handles the visual hierarchy that promotes skill assessment as primary entry point
 *
 * Features:
 * - Dynamic hero section with assessment CTA
 * - Visual hierarchy enhancement
 * - Assessment benefits showcase
 * - Path recommendation based on assessment completion
 *
 * @class AssessmentFirstLayout
 * @version 1.0.0
 * @since 2025-01-01
 */

export class AssessmentFirstLayout {
  /**
   * Create an AssessmentFirstLayout instance
   * @param {Object} options - Configuration options
   * @param {boolean} [options.debug=false] - Enable debug logging
   */
  constructor(options = {}) {
    this.debug = options.debug || false;
    this.isInitialized = false;
    this.hasCompletedAssessment = false;

    // Configuration
    this.cssPath = '/docs/assets/css/components/assessment-first-layout.css';
    this.singleActionCssPath = '/docs/assets/css/components/single-action-interface.css';
    this.learningPathsCardsCssPath = '/docs/assets/css/components/learning-paths-cards.css';
    this.storageKey = 'assessment-first-layout';

    // Element references
    this.heroSection = null;
    this.pathsSection = null;
    this.benefitsSection = null;
  }

  /**
   * Initialize the assessment-first layout
   * @returns {Promise<boolean>} Success status
   */
  async init() {
    try {
      this.log('Initializing assessment-first layout');

      // Load CSS styles
      this.loadStyles();

      // Check assessment completion status
      this.checkAssessmentStatus();

      // Apply layout modifications
      await this.applyAssessmentFirstLayout();

      // Set up event listeners
      this.setupEventListeners();

      this.isInitialized = true;
      this.log('Assessment-first layout initialized successfully');
      return true;
    } catch (error) {
      this.handleError('Failed to initialize assessment-first layout', error);
      return false;
    }
  }

  /**
   * Load CSS styles for assessment-first layout
   */
  loadStyles() {
    try {
      // Load single-action interface styles first
      if (!document.getElementById('single-action-interface-styles')) {
        const singleActionLink = document.createElement('link');
        singleActionLink.id = 'single-action-interface-styles';
        singleActionLink.rel = 'stylesheet';
        singleActionLink.href = this.singleActionCssPath;
        document.head.appendChild(singleActionLink);
      }

      // Load learning paths cards styles
      if (!document.getElementById('learning-paths-cards-styles')) {
        const cardsLink = document.createElement('link');
        cardsLink.id = 'learning-paths-cards-styles';
        cardsLink.rel = 'stylesheet';
        cardsLink.href = this.learningPathsCardsCssPath;
        document.head.appendChild(cardsLink);
      }

      // Load assessment-first layout styles
      if (!document.getElementById('assessment-first-layout-styles')) {
        const link = document.createElement('link');
        link.id = 'assessment-first-layout-styles';
        link.rel = 'stylesheet';
        link.href = this.cssPath;
        document.head.appendChild(link);
      }

      this.log('Assessment-first layout styles loaded');
    } catch (error) {
      this.handleError('Failed to load assessment-first styles', error);
    }
  }

  /**
   * Check if user has completed skill assessment
   */
  checkAssessmentStatus() {
    try {
      // Check localStorage for assessment completion
      const assessmentData = localStorage.getItem('skill-assessment-results');
      this.hasCompletedAssessment = !!(assessmentData && JSON.parse(assessmentData));

      this.log(`Assessment status: ${this.hasCompletedAssessment ? 'completed' : 'not completed'}`);
    } catch (error) {
      this.log('Could not determine assessment status, assuming not completed');
      this.hasCompletedAssessment = false;
    }
  }

  /**
   * Apply assessment-first layout modifications to the page
   */
  async applyAssessmentFirstLayout() {
    try {
      // Only apply on learning paths dashboard page
      if (!this.isLearningPathsPage()) {
        this.log('Not on learning paths page, skipping layout modifications');
        return;
      }

      // Create assessment hero section
      this.createAssessmentHero();

      // Create benefits section
      this.createBenefitsSection();

      // Enhance existing path cards
      this.enhancePathCards();

      // Add navigation enhancement
      this.addNavigationEnhancement();

      this.log('Assessment-first layout applied successfully');
    } catch (error) {
      this.handleError('Failed to apply assessment-first layout', error);
    }
  }

  /**
   * Check if current page is the learning paths dashboard
   * @returns {boolean} True if on learning paths page
   */
  isLearningPathsPage() {
    const path = window.location.pathname;
    const hash = window.location.hash;

    return path.includes('learning-paths') ||
           path.includes('learning/paths') ||
           path.includes('learning/README') ||
           hash.includes('learning-paths') ||
           hash.includes('learning/paths') ||
           hash.includes('learning/README') ||
           document.title.includes('Learning Paths Dashboard');
  }

  /**
   * Create and insert assessment hero section
   */
  createAssessmentHero() {
    try {
      // Find the main content area
      const contentArea = document.querySelector('.markdown-section') || document.querySelector('.content');
      if (!contentArea) {
        this.log('Could not find content area for hero section');
        return;
      }

      // Check if hero already exists
      if (document.querySelector('.assessment-hero')) {
        return;
      }

      // Find the best insertion point after the main header but before main content
      const insertionPoint = this.findHeroInsertionPoint(contentArea);

      // Create hero section
      const heroHTML = this.getAssessmentHeroHTML();
      const heroElement = document.createElement('div');
      heroElement.innerHTML = heroHTML;

      // Insert at the appropriate location
      if (insertionPoint) {
        insertionPoint.parentNode.insertBefore(heroElement.firstElementChild, insertionPoint);
      } else {
        // Fallback: insert at the beginning of content
        const firstChild = contentArea.firstElementChild;
        if (firstChild) {
          contentArea.insertBefore(heroElement.firstElementChild, firstChild);
        } else {
          contentArea.appendChild(heroElement.firstElementChild);
        }
      }

      this.heroSection = contentArea.querySelector('.assessment-hero');
      this.log('Assessment hero section created');
    } catch (error) {
      this.handleError('Failed to create assessment hero section', error);
    }
  }

  /**
   * Find the optimal insertion point for the hero section
   * @param {Element} contentArea - Main content area
   * @returns {Element|null} Element to insert before
   */
  findHeroInsertionPoint(contentArea) {
    try {
      // First, look for the main h1 title and find content after it
      const mainTitle = contentArea.querySelector('h1');
      if (mainTitle) {
        // Find the next h2 after the main title - this is where main content typically starts
        let currentElement = mainTitle.nextElementSibling;
        let introContentFound = false;

        while (currentElement) {
          // Skip any intro paragraphs or content immediately after h1
          if (currentElement.tagName === 'P') {
            const pText = currentElement.textContent.toLowerCase();
            if (pText.includes('welcome to') ||
                pText.includes('transform your') ||
                pText.includes('personalized learning') ||
                pText.length > 30) {
              introContentFound = true;
              this.log(`Found intro paragraph: ${pText.substring(0, 50)}...`);
            }
          }

          // If we find an h2 and we've seen intro content, insert before this h2
          if (currentElement.tagName === 'H2' && introContentFound) {
            const headingText = currentElement.textContent.toLowerCase();
            this.log(`Found insertion point before h2: ${currentElement.textContent.trim()}`);
            return currentElement;
          }

          // If we find an h2 without intro content, this is probably the right place
          if (currentElement.tagName === 'H2') {
            this.log(`Found insertion point before first h2: ${currentElement.textContent.trim()}`);
            return currentElement;
          }

          currentElement = currentElement.nextElementSibling;
        }
      }

      // Fallback: Look for specific section headings
      const headings = contentArea.querySelectorAll('h2, h3');
      for (const heading of headings) {
        const headingText = heading.textContent.toLowerCase();

        // Insert before sections that clearly start main content
        if (headingText.includes('start your journey') ||
            headingText.includes('learning paths by experience') ||
            headingText.includes('foundation builder') ||
            headingText.includes('skill developer') ||
            headingText.includes('choose your learning')) {
          this.log(`Found fallback insertion point before: ${heading.textContent.trim()}`);
          return heading;
        }
      }

      // Final fallback: insert before first h2
      const firstH2 = contentArea.querySelector('h2');
      if (firstH2) {
        this.log(`Using final fallback: first h2 - ${firstH2.textContent.trim()}`);
        return firstH2;
      }

      this.log('No insertion point found');
      return null;
    } catch (error) {
      this.handleError('Failed to find hero insertion point', error);
      return null;
    }
  }

  /**
   * Get HTML for assessment hero section
   * @returns {string} Hero section HTML
   */
  getAssessmentHeroHTML() {
    const title = this.hasCompletedAssessment
      ? 'Continue Your Learning Journey'
      : 'Start Your AI-Assisted Engineering Journey';

    const subtitle = this.hasCompletedAssessment
      ? 'Based on your assessment results, here are your personalized learning paths'
      : 'Discover your perfect learning path with our personalized skill assessment';

    const ctaText = this.hasCompletedAssessment
      ? 'View My Recommendations'
      : 'Take 5-Minute Assessment';

    const ctaIcon = this.hasCompletedAssessment ? '🎯' : '📊';

    return `
      <section class="assessment-hero">
        <div class="assessment-hero-content">
          <h1>${title}</h1>
          <p>${subtitle}</p>
          <a href="#/learning/skill-assessment" class="assessment-cta">
            <span class="assessment-cta-icon">${ctaIcon}</span>
            ${ctaText}
          </a>
        </div>
      </section>
    `;
  }

  /**
   * Create benefits section showcasing assessment advantages
   */
  createBenefitsSection() {
    try {
      if (this.hasCompletedAssessment) {
        this.log('User has completed assessment, skipping benefits section');
        return;
      }

      // Find insertion point (after hero, before paths)
      const heroSection = document.querySelector('.assessment-hero');
      if (!heroSection) {
        this.log('Hero section not found, cannot insert benefits section');
        return;
      }

      // Check if benefits already exist
      if (document.querySelector('.assessment-benefits')) {
        return;
      }

      const benefitsHTML = this.getAssessmentBenefitsHTML();
      const benefitsElement = document.createElement('div');
      benefitsElement.innerHTML = benefitsHTML;

      // Insert after hero section
      heroSection.parentNode.insertBefore(benefitsElement.firstElementChild, heroSection.nextSibling);

      this.benefitsSection = document.querySelector('.assessment-benefits');
      this.log('Assessment benefits section created');
    } catch (error) {
      this.handleError('Failed to create benefits section', error);
    }
  }

  /**
   * Get HTML for assessment benefits section
   * @returns {string} Benefits section HTML
   */
  getAssessmentBenefitsHTML() {
    return `
      <div class="assessment-benefits">
        <div class="benefit-card">
          <span class="benefit-icon">🎯</span>
          <h3 class="benefit-title">Personalized Recommendations</h3>
          <p class="benefit-description">Get matched with learning paths that fit your experience level and goals.</p>
        </div>
        <div class="benefit-card">
          <span class="benefit-icon">⚡</span>
          <h3 class="benefit-title">Skip What You Know</h3>
          <p class="benefit-description">Avoid wasting time on content you've already mastered.</p>
        </div>
        <div class="benefit-card">
          <span class="benefit-icon">🤖</span>
          <h3 class="benefit-title">AI Coach Guidance</h3>
          <p class="benefit-description">Receive ongoing support from our intelligent learning coach.</p>
        </div>
        <div class="benefit-card">
          <span class="benefit-icon">📈</span>
          <h3 class="benefit-title">Track Your Progress</h3>
          <p class="benefit-description">Monitor your learning journey with detailed progress analytics.</p>
        </div>
      </div>
    `;
  }

  /**
   * Enhance existing path cards with improved styling
   */
  enhancePathCards() {
    try {
      // Find all path-related tables and sections
      const pathTables = document.querySelectorAll('table');
      const pathSections = document.querySelectorAll('h3, h4');

      // Add enhanced classes to path sections
      pathSections.forEach(section => {
        if (this.isPathSection(section)) {
          section.classList.add('enhanced-path-section');
        }
      });

      // Convert tables to enhanced card layout if they contain paths
      pathTables.forEach(table => {
        if (this.isPathTable(table)) {
          this.convertTableToCards(table);
        }
      });

      this.log('Path cards enhanced');
    } catch (error) {
      this.handleError('Failed to enhance path cards', error);
    }
  }

  /**
   * Check if a section is a path-related section
   * @param {Element} section - Section element to check
   * @returns {boolean} True if path section
   */
  isPathSection(section) {
    const text = section.textContent.toLowerCase();
    return text.includes('path') ||
           text.includes('foundation builder') ||
           text.includes('skill developer') ||
           text.includes('expert practitioner');
  }

  /**
   * Check if a table contains path information
   * @param {Element} table - Table element to check
   * @returns {boolean} True if path table
   */
  isPathTable(table) {
    const headers = table.querySelectorAll('th');
    const firstRow = table.querySelector('tr:first-child');

    if (!firstRow) {return false;}

    const headerText = firstRow.textContent.toLowerCase();
    return headerText.includes('path') ||
           headerText.includes('focus') ||
           headerText.includes('duration');
  }

  /**
   * Convert table layout to enhanced card layout
   * @param {Element} table - Table to convert
   */
  convertTableToCards(table) {
    try {
      // Create paths grid container
      const pathsGrid = document.createElement('div');
      pathsGrid.className = 'paths-grid';

      // Process table rows (skip header)
      const rows = table.querySelectorAll('tr');
      for (let i = 1; i < rows.length; i++) {
        const row = rows[i];
        const cells = row.querySelectorAll('td');

        if (cells.length >= 3) {
          const pathCard = this.createPathCardFromRow(cells);
          pathsGrid.appendChild(pathCard);
        }
      }

      // Replace table with cards
      if (pathsGrid.children.length > 0) {
        table.parentNode.replaceChild(pathsGrid, table);
        this.log('Table converted to enhanced path cards');
      }
    } catch (error) {
      this.handleError('Failed to convert table to cards', error);
    }
  }

  /**
   * Create path card from table row cells
   * @param {NodeList} cells - Table cells
   * @returns {Element} Path card element
   */
  createPathCardFromRow(cells) {
    const pathCard = document.createElement('div');
    pathCard.className = 'path-card';

    // Extract information from cells
    const pathInfo = this.extractPathInfo(cells);

    pathCard.innerHTML = `
      <div class="path-header">
        <span class="path-icon">${pathInfo.icon}</span>
        <div class="path-info">
          <h3 class="path-title">${pathInfo.title}</h3>
          <div class="path-meta">
            <span class="meta-item">
              <span>⏱️</span>
              <span>${pathInfo.duration}</span>
            </span>
            <span class="meta-item">
              <span>🎯</span>
              <span>${pathInfo.focus}</span>
            </span>
          </div>
        </div>
      </div>
      <p class="path-description">${pathInfo.description}</p>
      <div class="path-actions">
        <div class="checkbox-group">
          <label class="checkbox-wrapper">
            <input type="checkbox" />
            <span>📚 Add to Path</span>
          </label>
          <label class="checkbox-wrapper">
            <input type="checkbox" />
            <span>✅ Completed</span>
          </label>
        </div>
        <a href="${pathInfo.link}" class="path-link">
          Start Learning
          <span>→</span>
        </a>
      </div>
    `;

    return pathCard;
  }

  /**
   * Convert markdown link to docsify hash navigation
   * @param {string} link - Original link
   * @returns {string} Docsify-compatible hash link
   */
  convertToDocsifyLink(link) {
    try {
      // If it's already a hash link or external, return as-is
      if (!link || link === '#' || link.startsWith('#') || link.startsWith('http')) {
        return link;
      }

      // Remove file extension and leading slash
      let docsifyLink = link.replace(/\.md$/, '').replace(/^\//, '');

      // Handle README.md files - convert to folder path
      docsifyLink = docsifyLink.replace(/\/README$/, '/');

      // Ensure it starts with #/
      if (!docsifyLink.startsWith('#/')) {
        docsifyLink = '#/' + docsifyLink;
      }

      this.log(`Converted link: ${link} -> ${docsifyLink}`);
      return docsifyLink;
    } catch (error) {
      this.handleError('Failed to convert link', error);
      return link;
    }
  }

  /**
   * Extract path information from table cells
   * @param {NodeList} cells - Table cells
   * @returns {Object} Extracted path information
   */
  extractPathInfo(cells) {
    const firstCell = cells[0];
    const titleElement = firstCell.querySelector('a') || firstCell;
    const title = titleElement.textContent.trim();
    const originalLink = firstCell.querySelector('a')?.href || '#';
    const link = this.convertToDocsifyLink(originalLink);

    // Determine icon based on title
    let icon = '📚';
    if (title.toLowerCase().includes('ai')) {icon = '🤖';}
    else if (title.toLowerCase().includes('edge')) {icon = '☁️';}
    else if (title.toLowerCase().includes('security')) {icon = '🛡️';}
    else if (title.toLowerCase().includes('data')) {icon = '📊';}
    else if (title.toLowerCase().includes('ux')) {icon = '🎨';}

    return {
      title: title,
      link: link,
      icon: icon,
      focus: cells[1]?.textContent.trim() || 'General',
      duration: cells[2]?.textContent.trim() || 'Variable',
      description: cells[3]?.textContent.trim() || 'Comprehensive learning path'
    };
  }

  /**
   * Add navigation enhancement section
   */
  addNavigationEnhancement() {
    try {
      // Find the content area
      const contentArea = document.querySelector('.markdown-section') || document.querySelector('.content');
      if (!contentArea) {return;}

      // Check if nav already exists
      if (document.querySelector('.learning-nav')) {
        return;
      }

      const navHTML = this.getNavigationEnhancementHTML();
      const navElement = document.createElement('div');
      navElement.innerHTML = navHTML;

      // Insert at the end of content
      contentArea.appendChild(navElement.firstElementChild);

      this.log('Navigation enhancement added');
    } catch (error) {
      this.handleError('Failed to add navigation enhancement', error);
    }
  }

  /**
   * Get HTML for navigation enhancement
   * @returns {string} Navigation HTML
   */
  getNavigationEnhancementHTML() {
    return `
      <nav class="learning-nav">
        <a href="#/learning/skill-assessment" class="nav-item primary">
          <span class="nav-icon">📊</span>
          <span class="nav-label">Skill Assessment</span>
        </a>
        <a href="#/learning/katas/" class="nav-item">
          <span class="nav-icon">🥋</span>
          <span class="nav-label">Practice Katas</span>
        </a>
        <a href="#/learning/training-labs/" class="nav-item">
          <span class="nav-icon">🧪</span>
          <span class="nav-label">Training Labs</span>
        </a>
        <a href="#/learning/getting-started" class="nav-item">
          <span class="nav-icon">🚀</span>
          <span class="nav-label">Getting Started</span>
        </a>
      </nav>
    `;
  }

  /**
   * Set up event listeners for interactive elements
   */
  setupEventListeners() {
    try {
      // Assessment CTA click tracking
      const assessmentCTA = document.querySelector('.assessment-cta');
      if (assessmentCTA) {
        assessmentCTA.addEventListener('click', () => {
          this.trackEvent('assessment_cta_clicked');
        });
      }

      // Path card interactions
      const pathCards = document.querySelectorAll('.path-card');
      pathCards.forEach(card => {
        card.addEventListener('mouseenter', () => {
          this.trackEvent('path_card_hover');
        });
      });

      // Checkbox interactions
      const checkboxes = document.querySelectorAll('.checkbox-wrapper input[type="checkbox"]');
      checkboxes.forEach(checkbox => {
        checkbox.addEventListener('change', (e) => {
          this.handleCheckboxChange(e);
        });
      });

      this.log('Event listeners set up');
    } catch (error) {
      this.handleError('Failed to set up event listeners', error);
    }
  }

  /**
   * Handle checkbox state changes
   * @param {Event} event - Checkbox change event
   */
  handleCheckboxChange(event) {
    try {
      const checkbox = event.target;
      const wrapper = checkbox.closest('.checkbox-wrapper');
      const card = checkbox.closest('.path-card');

      if (!wrapper || !card) {return;}

      const isAddToPath = wrapper.textContent.includes('Add to Path');
      const isCompleted = wrapper.textContent.includes('Completed');

      // Track the interaction
      this.trackEvent('checkbox_changed', {
        type: isAddToPath ? 'add_to_path' : 'completed',
        checked: checkbox.checked
      });

      // Save state to localStorage
      this.saveCheckboxState(card, isAddToPath ? 'add_to_path' : 'completed', checkbox.checked);

      this.log(`Checkbox changed: ${isAddToPath ? 'add_to_path' : 'completed'} = ${checkbox.checked}`);
    } catch (error) {
      this.handleError('Failed to handle checkbox change', error);
    }
  }

  /**
   * Save checkbox state to localStorage
   * @param {Element} card - Path card element
   * @param {string} type - Checkbox type
   * @param {boolean} checked - Checked state
   */
  saveCheckboxState(card, type, checked) {
    try {
      const pathTitle = card.querySelector('.path-title')?.textContent.trim();
      if (!pathTitle) {return;}

      const stateKey = `${this.storageKey}-checkboxes`;
      const existingState = JSON.parse(localStorage.getItem(stateKey) || '{}');

      if (!existingState[pathTitle]) {
        existingState[pathTitle] = {};
      }

      existingState[pathTitle][type] = checked;

      localStorage.setItem(stateKey, JSON.stringify(existingState));
      this.log(`Checkbox state saved for ${pathTitle}: ${type} = ${checked}`);
    } catch (error) {
      this.handleError('Failed to save checkbox state', error);
    }
  }

  /**
   * Track user events for analytics
   * @param {string} eventName - Event name
   * @param {Object} data - Event data
   */
  trackEvent(eventName, data = {}) {
    try {
      // Store events in localStorage for potential analytics
      const eventsKey = `${this.storageKey}-events`;
      const events = JSON.parse(localStorage.getItem(eventsKey) || '[]');

      events.push({
        event: eventName,
        data: data,
        timestamp: new Date().toISOString(),
        page: window.location.pathname
      });

      // Keep only last 100 events
      if (events.length > 100) {
        events.splice(0, events.length - 100);
      }

      localStorage.setItem(eventsKey, JSON.stringify(events));
      this.log(`Event tracked: ${eventName}`, data);
    } catch (error) {
      this.log(`Failed to track event: ${eventName}`);
    }
  }

  /**
   * Clean up resources and remove event listeners
   */
  destroy() {
    try {
      // Remove CSS
      const styles = document.getElementById('assessment-first-layout-styles');
      if (styles) {
        styles.remove();
      }

      // Reset state
      this.heroSection = null;
      this.pathsSection = null;
      this.benefitsSection = null;
      this.isInitialized = false;

      this.log('Assessment-first layout destroyed');
    } catch (error) {
      this.handleError('Error destroying assessment-first layout', error);
    }
  }

  /**
   * Log debug messages
   * @param {string} message - Debug message
   * @param {...any} args - Additional arguments
   * @private
   */
  log(message, ...args) {
    if (this.debug) {
      console.log(`[AssessmentFirstLayout] ${message}`, ...args);
    }
  }

  /**
   * Handle errors with logging
   * @param {string} message - Error message
   * @param {Error} error - Error object
   * @private
   */
  handleError(message, error) {
    console.error(`[AssessmentFirstLayout] ${message}`, error);
  }
}

// ES6 Module Export
export default AssessmentFirstLayout;
