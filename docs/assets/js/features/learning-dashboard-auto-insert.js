/**
 * Learning Dashboard Auto-Insert Feature
 *
 * Automatically inserts learning path dashboard containers into pages
 * based on frontmatter metadata (ms.topic: learning-path or learning-paths).
 *
 * @class LearningDashboardAutoInsert
 */
class LearningDashboardAutoInsert {
    constructor() {
        this.initialized = false;
        this.debugMode = window.debugInteractiveProgress || false;
    }

    /**
     * Initialize the auto-insert feature
     * Called after page content is rendered
     */
    initialize() {
        // Reset initialization flag on each call to allow re-insertion on navigation
        this.initialized = false;

        const shouldInsert = this.shouldInsertDashboard();

        if (shouldInsert) {
            this.log('Frontmatter indicates learning path page, inserting dashboard container');
            this.insertDashboard();
        } else {
            this.log('Page does not require dashboard auto-insertion');
        }

        this.initialized = true;
    }

    /**
     * Check if dashboard should be inserted based on frontmatter
     * @returns {boolean}
     */
    shouldInsertDashboard() {
        const frontmatterData = window.frontmatterData || {};
        const topic = frontmatterData.frontmatter?.['ms.topic'];

        if (!topic) {
            return false;
        }

        // Only insert on learning paths directory page (plural 'learning-paths')
        const isPathsDirectory = topic === 'learning-paths';

        this.log(`Frontmatter ms.topic: ${topic}, isPathsDirectory: ${isPathsDirectory}`);

        return isPathsDirectory;
    }

    /**
     * Insert dashboard container into the page
     */
    insertDashboard() {
        const contentArea = document.querySelector('.markdown-section') || document.querySelector('.content');

        if (!contentArea) {
            this.log('Content area not found, cannot insert dashboard', 'warn');
            return;
        }

        // Check if dashboard already exists (manual insertion)
        if (document.querySelector('.learning-dashboard, [data-need-progress]')) {
            this.log('Dashboard container already exists, skipping auto-insertion');
            return;
        }

        const insertionPoint = this.findInsertionPoint(contentArea);

        if (!insertionPoint) {
            this.log('Could not find appropriate insertion point', 'warn');
            return;
        }

        const dashboardContainer = this.createDashboardContainer();

        // Insert before the insertion point
        insertionPoint.parentNode.insertBefore(dashboardContainer, insertionPoint);

        this.log('Dashboard container inserted successfully');

        // Dispatch event to notify integration plugin
        window.dispatchEvent(new CustomEvent('learning-dashboard-inserted', {
            detail: { container: dashboardContainer }
        }));
    }

    /**
     * Find the appropriate insertion point for the dashboard
     * Insert after the first paragraph or before the first h2
     * @param {HTMLElement} contentArea
     * @returns {HTMLElement|null}
     */
    findInsertionPoint(contentArea) {
        // Strategy 1: Find first h2 (section heading) - insert before it
        const firstH2 = contentArea.querySelector('h2');
        if (firstH2) {
            return firstH2;
        }

        // Strategy 2: Find first paragraph after h1, then insert after it
        const h1 = contentArea.querySelector('h1');
        if (h1) {
            let sibling = h1.nextElementSibling;
            while (sibling) {
                if (sibling.tagName === 'P' || sibling.tagName === 'BLOCKQUOTE') {
                    // Insert after this element
                    return sibling.nextElementSibling || sibling;
                }
                if (sibling.tagName === 'H2') {
                    // Hit another heading, insert before it
                    return sibling;
                }
                sibling = sibling.nextElementSibling;
            }
        }

        // Strategy 3: Insert at beginning of content (after h1 if exists)
        const firstChild = h1 ? h1.nextElementSibling : contentArea.firstElementChild;
        return firstChild;
    }

    /**
     * Create the dashboard container element
     * @returns {HTMLElement}
     */
    createDashboardContainer() {
        const wrapper = document.createElement('div');
        wrapper.className = 'learning-dashboard-wrapper';
        wrapper.innerHTML = `
            <h2>📊 Your Learning Progress</h2>
            <div class="learning-dashboard learning-path-cards" id="personalized-dashboard" data-need-progress></div>
            <hr>
        `.trim();

        return wrapper;
    }

    /**
     * Log messages (respects debug mode)
     * @param {string} message
     * @param {string} level
     */
    log(message, level = 'log') {
        if (this.debugMode) {
            console[level](`[LearningDashboardAutoInsert] ${message}`);
        }
    }

    /**
     * Reset initialization state (for testing/debugging)
     */
    reset() {
        this.initialized = false;
    }
}

// Export for use in integration plugin
if (typeof window !== 'undefined') {
    window.LearningDashboardAutoInsert = LearningDashboardAutoInsert;
}
