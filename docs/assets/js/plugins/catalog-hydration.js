/**
 * Catalog Hydration Plugin for Docsify
 *
 * Enhances the learning catalog page with interactive features:
 * - Displays user selections and progress for katas
 * - Integrates with learning progress tracker API
 * - Provides visual indicators for completed/in-progress items
 *
 * @version 1.0.0
 * @author Edge AI Team
 */

/**
 * CatalogHydration class - Main plugin logic
 *
 * Responsibilities:
 * - Detect catalog page activation
 * - Fetch user selections and progress from API
 * - Decorate DOM with progress indicators and selection controls
 * - Handle user interactions and persist selections
 *
 * @class
 */
class CatalogHydration {
    /**
     * Create a new CatalogHydration instance
     * @constructor
     */
    constructor() {
        // Configuration
        this.API_BASE = 'http://localhost:3002/api';
        this.CACHE_TTL = 5 * 60 * 1000; // 5 minutes cache TTL
        this.FETCH_TIMEOUT = 5000; // 5 second timeout
        this.SAVE_DEBOUNCE_DELAY = 500; // 500ms debounce for save operations

        // State
        this.selections = new Set();
        this.progressData = {};
        this.recommendations = []; // Assessment recommendations array
        this.saveTimer = null; // Debounce timer for save operations
        this.isSaving = false; // Track save state for UI feedback

        // SSE state
        this.eventSource = null;
        this.sseReconnectAttempts = 0;
        this.sseMaxReconnectAttempts = 5;
        this.sseReconnectDelay = 1000; // Start with 1 second

        // Path to kata mappings for auto-selection
        // Maps path IDs (with 'path-' prefix) to arrays of kata item IDs
        this.pathMappings = {
            'path-foundation-ai-first-engineering': [
                'ai-assisted-engineering-100-inline-suggestions-basics',
                'ai-assisted-engineering-100-inline-chat-quick-edits',
                'ai-assisted-engineering-100-ai-development-fundamentals',
                'ai-assisted-engineering-100-copilot-modes',
                'adr-creation-100-basic-messaging-architecture',
                'project-planning-100-basic-prompt-usage',
                'ai-assisted-engineering-200-copilot-edit-agent-basics',
                'ai-assisted-engineering-200-copilot-edit-agent-iac-patterns',
                'adr-creation-200-advanced-observability-stack',
                'adr-creation-400-service-mesh-selection',
                'project-planning-300-comprehensive-two-scenario',
                'prompt-engineering-300-context-optimization',
                'ai-assisted-engineering-300-getting-started-advanced',
                'task-planning-100-edge-documentation-planning',
                'task-planning-300-repository-analysis-planning',
                'product-requirements-100-basic-prd-creation',
                'project-planning-400-advanced-strategic-planning',
                'task-planning-400-advanced-capability-integration'
            ],
            'path-intermediate-devops-excellence': [
                'edge-deployment-100-deployment-basics',
                'edge-deployment-200-resource-management',
                'edge-deployment-300-multi-blueprint-coordination',
                'edge-deployment-400-enterprise-compliance-validation',
                'prompt-engineering-300-prompt-creation-and-refactoring-workflow',
                'troubleshooting-300-ai-assisted-diagnostics',
                'troubleshooting-400-multi-component-debugging',
                'troubleshooting-400-performance-optimization',
                'edge-deployment-500-deployment-expert',
                'project-planning-400-stakeholder-alignment-strategies'
            ],
            'path-intermediate-infrastructure-architect': [
                'adr-creation-100-basic-messaging-architecture',
                'adr-creation-200-advanced-observability-stack',
                'adr-creation-400-service-mesh-selection',
                'edge-deployment-100-deployment-basics',
                'edge-deployment-200-resource-management',
                'edge-deployment-300-multi-blueprint-coordination',
                'project-planning-400-enterprise-architecture-planning',
                'adr-creation-500-edge-ai-inference-platform-selection',
                'adr-creation-500-cross-site-industrial-data-architecture',
                'edge-deployment-400-enterprise-compliance-validation',
                'edge-deployment-500-deployment-expert'
            ],
            'path-expert-data-analytics-integration': [
                'fabric-integration-200-prerequisite-full-deployment',
                'fabric-integration-200-fabric-workspace-configuration',
                'fabric-integration-100-fabric-rti-blueprint-deployment',
                'fabric-integration-300-edge-to-cloud-data-pipeline',
                'fabric-integration-400-fabric-analytics-dashboards',
                'troubleshooting-400-multi-component-debugging',
                'troubleshooting-300-performance-optimization',
                'task-planning-500-learning-platform-extraction',
                'task-planning-400-ai-asset-extraction',
                'task-planning-400-pr-generation'
            ],
            'path-expert-enterprise-integration': [
                'task-planning-100-edge-documentation-planning',
                'task-planning-300-repository-analysis-planning',
                'fabric-integration-100-fabric-rti-blueprint-deployment',
                'project-planning-400-advanced-strategic-planning',
                'project-planning-400-enterprise-architecture-planning',
                'fabric-integration-300-edge-to-cloud-data-pipeline',
                'fabric-integration-400-fabric-analytics-dashboards',
                'product-requirements-100-basic-prd-creation',
                'task-planning-400-advanced-capability-integration',
                'adr-creation-500-cross-site-industrial-data-architecture',
                'task-planning-500-learning-platform-extraction',
                'edge-deployment-500-deployment-expert',
                'project-planning-400-stakeholder-alignment-strategies'
            ]
        };
    }

    // ============================================================================
    // Public API - Initialization
    // ============================================================================

    /**
     * Initialize plugin and set up page detection
     * Only activates on the catalog page (#/learning/catalog)
     *
     * @async
     * @returns {Promise<void>}
     */
    async init() {
        try {
            if (this._isCatalogPage()) {
                await this._waitForDOM('.task-list-item, .markdown-section li input[type="checkbox"]');

                // Fetch assessment recommendations FIRST (before selections)
                await this.fetchAssessmentRecommendations();

                await this.fetchSelections();
                await this.fetchProgress();
                await this.decorateEntries();

                // Expand any path selections to include their katas
                this._expandPathSelections();

                this.attachEventListeners();

                // Connect to SSE for real-time progress updates
                this.connectToSSE();
            }
        } catch (error) {
            // Silently fail initialization errors
        }
    }

    // ============================================================================
    // Public API - Data Fetching
    // ============================================================================

    /**
     * Fetch user selections from API
     * Falls back to localStorage on failure
     *
     * @async
     * @returns {Promise<void>}
     */
    async fetchSelections() {
        const cacheKey = 'selectedLearningPaths';

        try {
            const response = await this._fetchWithTimeout(`${this.API_BASE}/learning/selections?userId=default-user`);
            if (!response.ok) throw new Error(`API error: ${response.status}`);

            const { data } = await response.json();
            this.selections = new Set(data?.selections?.selectedItems || []);

            this._setCached(cacheKey, [...this.selections]);
        } catch (err) {
            // Fallback to cache
            const cached = this._getCached(cacheKey) || JSON.parse(localStorage.getItem(cacheKey) || '[]');
            this.selections = new Set(cached);
        }
    }

    /**
     * Fetch user progress data from API
     *
     * @async
     * @returns {Promise<void>}
     */
    async fetchProgress() {
        try {
            const response = await this._fetchWithTimeout(`${this.API_BASE}/progress`);
            if (!response.ok) throw new Error(`API error: ${response.status}`);

            const responseData = await response.json();
            const { progressData } = responseData;

            // Validate progressData structure
            if (!Array.isArray(progressData)) {
                console.error('Invalid API response: progressData is not an array', responseData);
                return;
            }

            // Process both kata and path progress
            progressData.forEach(item => {
                if (!item || !item.type || !item.pageId) {
                    console.warn('Invalid progress item:', item);
                    return;
                }

                if (item.type === 'kata') {
                    const completed = Array.isArray(item.items) ? item.items.filter(i => i.completed).length : 0;
                    const total = Array.isArray(item.items) ? item.items.length : 0;
                    const percentage = total > 0 ? Math.round((completed / total) * 100) : item.completionPercentage || 0;

                    this.progressData[item.pageId] = { percentage, completed, total };
                } else if (item.type === 'path') {
                    const total = Array.isArray(item.items) ? item.items.length : 0;
                    const completed = Array.isArray(item.items) ? item.items.filter(i => i.completed).length : 0;

                    this.progressData[item.pageId] = {
                        percentage: item.completionPercentage || 0,
                        completed,
                        total
                    };
                }
            });

        } catch (err) {
            console.error('Failed to fetch progress:', err);
        }
    }

    /**
     * Connect to SSE stream for real-time progress updates
     *
     * @returns {void}
     */
    connectToSSE() {
        // Prevent duplicate connections
        if (this.eventSource) {
            return;
        }

        try {
            // Connect to SSE endpoint
            this.eventSource = new EventSource(`${this.API_BASE}/progress/events`);

            // Connection opened
            this.eventSource.addEventListener('open', () => {
                this.sseReconnectAttempts = 0;
            });

            // Listen for file-change events (kata progress updates)
            this.eventSource.addEventListener('file-change', async (_event) => {
                try {
                    // Refetch progress data when kata files change
                    await this.fetchProgress();
                    // Re-decorate entries with updated progress
                    await this.decorateEntries();
                } catch(_error) {
                    // Silently handle errors
                }
            });

            // Connection error - attempt reconnection
            this.eventSource.addEventListener('error', () => {
                this.disconnectFromSSE();
                this._handleSSEReconnect();
            });

        } catch(_error) {
            // Silently fail SSE connection errors
        }
    }

    /**
     * Handle SSE reconnection with exponential backoff
     *
     * @private
     * @returns {void}
     */
    _handleSSEReconnect() {
        if (this.sseReconnectAttempts >= this.sseMaxReconnectAttempts) {
            return;
        }

        this.sseReconnectAttempts++;
        const delay = this.sseReconnectDelay * Math.pow(2, this.sseReconnectAttempts - 1);

        setTimeout(() => {
            this.connectToSSE();
        }, delay);
    }

    /**
     * Disconnect from SSE stream
     *
     * @returns {void}
     */
    disconnectFromSSE() {
        if (this.eventSource) {
            this.eventSource.close();
            this.eventSource = null;
        }
    }

    // ============================================================================
    // Public API - DOM Manipulation (to be implemented in Task 3.8)
    // ============================================================================

    /**
     * Decorate catalog entries with progress and selections
     *
     * @async
     * @returns {Promise<void>}
     */
    async decorateEntries() {
        // Find all list items containing checkboxes within the catalog content
        // Use .task-list-item class for compatibility with test environment
        const taskItems = document.querySelectorAll('.task-list-item, .markdown-section li');
        const filteredItems = Array.from(taskItems).filter(item =>
            item.querySelector('input[type="checkbox"]')
        );

        filteredItems.forEach((item) => {
            const checkbox = item.querySelector('input[type="checkbox"]');
            const link = item.querySelector('a');

            if (!checkbox || !link) return;

            const itemId = this.extractItemIdFromLink(link.href);
            if (!itemId) return;

            // Skip prerequisite checkboxes on learning path pages - they should remain static
            // But DON'T skip on the catalog page itself where paths are selectable
            const pathLink = item.querySelector('a[href*="/paths/"]');
            if (pathLink && !this._isOnCatalogPageOnly()) {
                // Walk backwards through siblings (checking both item siblings and parent siblings)
                let foundPrerequisites = false;

                // First check siblings of the current item
                let currentElement = item.previousElementSibling;
                while (currentElement && !foundPrerequisites) {
                    if (currentElement.tagName && /^H[1-6]$/.test(currentElement.tagName)) {
                        if (/prerequisite/i.test(currentElement.textContent)) {
                            foundPrerequisites = true;
                        }
                        break;
                    }
                    currentElement = currentElement.previousElementSibling;
                }

                // If not found, check siblings of the parent element (e.g., heading before <ul>)
                if (!foundPrerequisites && item.parentElement) {
                    currentElement = item.parentElement.previousElementSibling;
                    while (currentElement && !foundPrerequisites) {
                        if (currentElement.tagName && /^H[1-6]$/.test(currentElement.tagName)) {
                            if (/prerequisite/i.test(currentElement.textContent)) {
                                foundPrerequisites = true;
                            }
                            break;
                        }
                        currentElement = currentElement.previousElementSibling;
                    }
                }

                // Skip prerequisite checkboxes - leave them as static informational elements
                if (foundPrerequisites) {
                    console.log(`[CATALOG-HYDRATION] Skipping prerequisite checkbox - no completion tracking available`);
                    return;
                }
            }

            // Add data-item-id attribute for event handling
            checkbox.dataset.itemId = itemId;

            // Pre-check checkbox if item is selected
            console.log(`[CATALOG-HYDRATION] Checking item: ${itemId}, in selections? ${this.selections.has(itemId)}, selections:`, Array.from(this.selections));
            if (this.selections.has(itemId)) {
                checkbox.disabled = false;
                checkbox.checked = true;
                checkbox.setAttribute('checked', 'checked');
                console.log(`[CATALOG-HYDRATION] ✓ Checked checkbox for: ${itemId}`);
            } else {
                console.log(`[CATALOG-HYDRATION] ✗ Item NOT in selections: ${itemId}`);
            }

            // Add progress bar - use existing progress or default to 0%
            // Early return if progress already exists anywhere in item (prevents duplicates in nested structures)
            if (item.querySelector('.learning-progress-container')) {
                return;
            }

            const progress = this.progressData[itemId] || { percentage: 0, completed: 0, total: 0 };
            const progressHTML = this.createProgressBar(progress.percentage);
            const label = item.querySelector('label');
            const paragraph = item.querySelector('p');
            const wrapper = label || paragraph;
            if (wrapper && link.parentElement) {
                const progressContainer = document.createElement('span');
                progressContainer.className = 'learning-progress-container';
                progressContainer.innerHTML = `<strong>Progress: ${progressHTML}</strong>`;
                progressContainer.style.marginRight = '8px';
                // Insert into the actual parent of the link, not necessarily the wrapper
                link.parentElement.insertBefore(progressContainer, link);
            }
        });

        // Apply recommendation visual indicators after all items are decorated
        this.decorateRecommendations();
    }

    /**
     * Add visual indicators to recommended items
     * Applies star icon and CSS class for styling
     *
     * @returns {void}
     */
    decorateRecommendations() {
        if (!Array.isArray(this.recommendations) || this.recommendations.length === 0) {
            return;
        }

        this.recommendations.forEach(itemId => {
            const checkbox = document.querySelector(`input[data-item-id="${itemId}"]`);
            if (!checkbox) return;

            const item = checkbox.closest('.task-list-item') || checkbox.closest('li');
            const link = item?.querySelector('a');

            if (!item || !link) return;

            // Add star icon (before pin icon if both exist)
            const existingStar = link.querySelector('.recommendation-star');
            if (!existingStar) {
                const starSpan = document.createElement('span');
                starSpan.className = 'recommendation-star';
                starSpan.textContent = ' ⭐';
                starSpan.setAttribute('aria-label', 'Recommended based on assessment');
                link.appendChild(starSpan);
            }

            // Add CSS class for styling
            item.classList.add('recommended-item');
        });
    }

    /**
     * Find all catalog task list items in the DOM
     *
     * @private
     * @returns {Element[]} Array of task list item elements
     */
    _findCatalogItems() {
        // Find list items containing checkboxes within the catalog content only
        return Array.from(document.querySelectorAll('.markdown-section li:has(input[type="checkbox"])'));
    }

    /**
     * Extract checkbox, link, and item ID from a task list item
     *
     * @private
     * @param {Element} item - Task list item element
     * @returns {{checkbox: HTMLInputElement|null, link: HTMLAnchorElement|null, itemId: string|null}} Extracted elements and ID
     */
    _extractItemElements(item) {
        const checkbox = item.querySelector('input[type="checkbox"]');
        const link = item.querySelector('a');
        const itemId = link ? this.extractItemIdFromLink(link.href) : null;
        return { checkbox, link, itemId };
    }

    /**
     * Add pin icon to a link's text content
     *
     * @private
     * @param {HTMLAnchorElement} link - Link element to modify
     * @returns {void}
     */
    _addPinIcon(link) {
        if (!link.textContent.includes('📌')) {
            link.textContent = `📌 ${link.textContent}`;
        }
    }

    /**
     * Inject progress bar HTML into a task list item
     *
     * @private
     * @param {Element} item - Task list item element
     * @param {number} percentage - Progress percentage (0-100)
     * @returns {void}
     */
    _injectProgressBar(item, percentage) {
        const progressHTML = this.createProgressBar(percentage);
        const metaLine = item.querySelector('p');
        if (metaLine) {
            metaLine.innerHTML += ` • <strong>Progress: ${progressHTML}</strong>`;
        }
    }

    /**
     * Create progress bar HTML with visual representation
     *
     * @param {number} percentage - Progress percentage (0-100)
     * @returns {string} HTML string for progress bar
     */
    createProgressBar(percentage) {
        if (percentage === 0) {
            return `
                <span class="catalog-progress-badge not-started">
                    <span class="catalog-progress-text">Not Started</span>
                </span>
            `;
        }

        return `
            <span class="catalog-progress-badge">
                <span class="catalog-progress-track">
                    <span class="catalog-progress-fill" style="width: ${percentage}%"></span>
                </span>
                <span class="catalog-progress-text">${percentage}%</span>
            </span>
        `;
    }

    /**
     * Extract item ID from catalog link href
     *
     * Kata format: learning/katas/ai/01-ai-fundamentals → ai-01-ai-fundamentals
     * Path format: learning/paths/foundation → path-foundation
     * Lab format: learning/training-labs/azure-iot-lab → lab-azure-iot-lab
     *
     * @param {string} href - Link href attribute
     * @returns {string|null} Item ID or null if invalid
     */
    extractItemIdFromLink(href) {
        // Extract hash portion from full URL or use as-is if already just a hash
        // http://localhost:8080/#/learning/katas/... → #/learning/katas/...
        const hashMatch = href.match(/#(.+)$/);
        const hashPart = hashMatch ? hashMatch[1] : href;

        // Strip leading slash if present
        const cleanHref = hashPart.startsWith('/') ? hashPart.substring(1) : hashPart;

        // Kata: katas/ai/01-ai-fundamentals(.md) → ai-01-ai-fundamentals
        const kataMatch = cleanHref.match(/katas\/([^\/]+)\/([^\/\.#]+)/);
        if (kataMatch) {
            const itemId = `${kataMatch[1]}-${kataMatch[2]}`;
            return itemId;
        }

        // Path: paths/foundation(.md) → path-foundation
        const pathMatch = cleanHref.match(/paths\/([^\/\.#]+)/);
        if (pathMatch) {
            const itemId = `path-${pathMatch[1]}`;
            return itemId;
        }

        // Lab: training-labs/azure-iot-lab(.md) → lab-azure-iot-lab
        const labMatch = cleanHref.match(/training-labs\/([^\/\.#]+)/);
        if (labMatch) {
            const itemId = `lab-${labMatch[1]}`;
            return itemId;
        }

        return null;
    }


    // ============================================================================
    // Public API - Event Handling (to be implemented in Task 3.11)
    // ============================================================================

    /**
     * Attach event listeners for user interactions
     * Uses event delegation on document for checkbox changes
     *
     * @returns {void}
     */
    attachEventListeners() {
        document.addEventListener('change', (e) => {
            // Only handle checkboxes with data-item-id
            if (e.target.type !== 'checkbox' || !e.target.dataset.itemId) {
                return;
            }

            const itemId = e.target.dataset.itemId;
            // Find link in parent list item (works with or without .task-list-item class)
            const link = e.target.closest('li')?.querySelector('a');

            // Update selections set immediately (optimistic update)
            this._updateSelectionState(itemId, e.target.checked, link);

            // If this is a learning path being checked, auto-select related katas
            if (itemId.startsWith('path-') && e.target.checked) {
                this._autoSelectPathKatas(itemId);
            }

            // If this is a learning path being unchecked, auto-deselect related katas
            if (itemId.startsWith('path-') && !e.target.checked) {
                this._autoDeselectPathKatas(itemId);
            }

            // Persist changes with debounce (avoid rapid API calls)
            this._debouncedSave();
        });
    }

    /**
     * Update selection state immediately (optimistic update)
     * @private
     * @param {string} itemId - Item identifier
     * @param {boolean} isChecked - Whether checkbox is checked
     * @param {HTMLAnchorElement|null} link - Link element to update with pin icon
     * @returns {void}
     */
    _updateSelectionState(itemId, isChecked, link) {
        if (isChecked) {
            this.selections.add(itemId);
            if (link) this._addPinIcon(link);
        } else {
            this.selections.delete(itemId);
            if (link) this._removePinIcon(link);
        }
    }

    /**
     * Remove pin icon from a link's text content
     * @private
     * @param {HTMLAnchorElement} link - Link element to modify
     * @returns {void}
     */
    _removePinIcon(link) {
        if (link.textContent.includes('📌')) {
            link.textContent = link.textContent.replace('📌 ', '');
        }
    }

    /**
     * Auto-select related katas when a learning path is selected
     * @private
     * @param {string} pathId - Learning path ID (e.g., 'path-foundation-ai-engineering')
     * @returns {void}
     */
    _autoSelectPathKatas(pathId) {
        // Get related kata IDs from path mappings
        const kataIds = this.pathMappings[pathId] || [];

        // Select each related kata
        kataIds.forEach(kataId => {
            // Find the checkbox for this kata
            const checkbox = document.querySelector(`input[data-item-id="${kataId}"]`);
            if (!checkbox) return;

            // Only auto-select if not already checked
            if (!checkbox.checked) {
                checkbox.disabled = false;
                checkbox.checked = true;
                checkbox.setAttribute('checked', 'checked');

                // Find the link to add pin icon
                const link = checkbox.closest('li')?.querySelector('a');
                if (link) {
                    this._addPinIcon(link);
                }

                // Add to selections set
                this.selections.add(kataId);
            }
        });
    }

    /**
     * Auto-deselect related katas when a learning path is deselected
     * @private
     * @param {string} pathId - Learning path ID (e.g., 'path-foundation-ai-engineering')
     * @returns {void}
     */
    _autoDeselectPathKatas(pathId) {
        // Get related kata IDs from path mappings
        const kataIds = this.pathMappings[pathId] || [];

        // Deselect each related kata
        kataIds.forEach(kataId => {
            // Find the checkbox for this kata
            const checkbox = document.querySelector(`input[data-item-id="${kataId}"]`);
            if (!checkbox) return;

            // Only auto-deselect if currently checked
            if (checkbox.checked) {
                checkbox.checked = false;
                checkbox.removeAttribute('checked');
                checkbox.style.background = '';
                checkbox.style.borderColor = '';
                checkbox.style.color = '';

                // Find the link to remove pin icon
                const link = checkbox.closest('li')?.querySelector('a');
                if (link) {
                    this._removePinIcon(link);
                }

                // Remove from selections set
                this.selections.delete(kataId);
            }
        });
    }

    /**
     * Expand existing path selections to include their katas
     * Called once during initialization after DOM decoration
     * Ensures saved path selections auto-select their associated katas
     *
     * @private
     * @returns {void}
     */
    _expandPathSelections() {
        // Skip expansion on catalog page - only expand on individual path pages
        // Catalog page only has path checkboxes, not individual kata checkboxes
        if (this._isOnCatalogPageOnly()) {
            console.log('[CATALOG-EXPAND] Skipping expansion on catalog page');
            return;
        }

        console.log('[CATALOG-EXPAND] Starting path expansion...');
        console.log('[CATALOG-EXPAND] Current selections before expansion:', Array.from(this.selections));

        const pathSelections = Array.from(this.selections).filter(id => id.startsWith('path-'));
        console.log('[CATALOG-EXPAND] Found path selections:', pathSelections);

        if (pathSelections.length === 0) {
            console.log('[CATALOG-EXPAND] No path selections to expand');
            return;
        }

        pathSelections.forEach(pathId => {
            const kataIds = this.pathMappings[pathId] || [];
            console.log(`[CATALOG-EXPAND] Path "${pathId}" maps to ${kataIds.length} katas:`, kataIds);

            if (kataIds.length === 0) {
                console.warn(`[CATALOG-EXPAND] No kata mapping found for path: ${pathId}`);
                return;
            }

            let foundCount = 0;
            let checkedCount = 0;

            kataIds.forEach(kataId => {
                const checkbox = document.querySelector(`input[data-item-id="${kataId}"]`);

                if (!checkbox) {
                    console.warn(`[CATALOG-EXPAND] Checkbox not found for kata: ${kataId}`);
                    return;
                }

                foundCount++;

                // Check the checkbox if not already checked
                if (!checkbox.checked) {
                    checkbox.disabled = false;
                    checkbox.checked = true;
                    checkbox.setAttribute('checked', 'checked');
                    checkedCount++;
                    const link = checkbox.closest('li')?.querySelector('a');
                    if (link) {
                        this._addPinIcon(link);
                    }
                }

                // Add to selections set
                this.selections.add(kataId);
            });

            console.log(`[CATALOG-EXPAND] Path "${pathId}": Found ${foundCount}/${kataIds.length} checkboxes, checked ${checkedCount} new ones`);
        });

        console.log('[CATALOG-EXPAND] Final selections after expansion:', Array.from(this.selections));
        console.log(`[CATALOG-EXPAND] Total items selected: ${this.selections.size}`);

        // Save expanded selections to persist kata selections
        this.saveSelections();
        console.log('[CATALOG-EXPAND] Saved expanded selections');
    }

    /**
     * Debounced save wrapper - prevents rapid API calls
     * @private
     * @returns {void}
     */
    _debouncedSave() {
        // Clear existing timer
        if (this.saveTimer) {
            clearTimeout(this.saveTimer);
        }

        // Set new timer
        this.saveTimer = setTimeout(() => {
            this.saveSelections();
        }, this.SAVE_DEBOUNCE_DELAY);
    }

    /**
     * Save user selections to API and localStorage
     * Handles errors gracefully with user-friendly messages
     *
     * @async
     * @returns {Promise<void>}
     */
    async saveSelections() {
        // Prevent concurrent saves
        if (this.isSaving) {
            return;
        }

        this.isSaving = true;
        const selectionsArray = [...this.selections];

        try {
            const response = await this._fetchWithTimeout(`${this.API_BASE}/learning/selections`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    userId: 'default-user',
                    selectedItems: selectionsArray
                })
            });

            if (!response.ok) {
                throw new Error(`Server returned ${response.status}: ${response.statusText}`);
            }

            // Update localStorage after successful API save
            this._setCached('selectedLearningPaths', selectionsArray);
        } catch (err) {
            // User-friendly error messages
            const errorMsg = err.name === 'AbortError'
                ? 'Save timed out - please check your connection'
                : `Failed to save selections: ${err.message}`;

            console.error('❌', errorMsg);

            // Still update localStorage for offline resilience
            this._setCached('selectedLearningPaths', selectionsArray);
            console.log('💾 Selections saved locally (will sync when online)');
        } finally {
            this.isSaving = false;
        }
    }

    // ============================================================================
    // Private Helpers
    // ============================================================================

    /**
     * Wait for DOM elements to be available
     * @private
     * @param {string} selector - CSS selector to wait for
     * @param {number} timeout - Maximum wait time in milliseconds
     * @returns {Promise<NodeList>}
     */
    async _waitForDOM(selector, timeout = 2000) {
        const startTime = Date.now();
        const pollInterval = 50;

        while (Date.now() - startTime < timeout) {
            const elements = document.querySelectorAll(selector);
            if (elements.length > 0) {
                return elements;
            }
            await new Promise(resolve => setTimeout(resolve, pollInterval));
        }

        return document.querySelectorAll(selector); // Return empty NodeList
    }

    /**
     * Fetch with timeout using AbortController
     * @private
     * @param {string} url - URL to fetch
     * @param {Object} options - Fetch options (method, headers, body, etc.)
     * @param {number} timeout - Timeout in milliseconds
     * @returns {Promise<Response>}
     */
    async _fetchWithTimeout(url, options = {}, timeout = this.FETCH_TIMEOUT) {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), timeout);

        try {
            const response = await fetch(url, {
                ...options,
                signal: controller.signal
            });
            clearTimeout(timeoutId);
            return response;
        } catch (err) {
            clearTimeout(timeoutId);
            throw err;
        }
    }

    /**
     * Get cached data from localStorage with timestamp validation
     * @private
     * @param {string} key - localStorage key
     * @returns {*} Cached data or null if invalid/expired
     */
    _getCached(key) {
        try {
            const cached = localStorage.getItem(key);
            if (!cached) return null;

            const parsed = JSON.parse(cached);

            // Handle both new format (with timestamp) and legacy format (raw array)
            if (Array.isArray(parsed)) {
                return parsed;
            }

            const { data, timestamp } = parsed;
            if (Date.now() - timestamp > this.CACHE_TTL) {
                localStorage.removeItem(key);
                return null;
            }
            return data;
        } catch {
            return null;
        }
    }

    /**
     * Set cached data in localStorage with timestamp
     * Maintains backward compatibility with legacy array format for tests
     * @private
     * @param {string} key - localStorage key
     * @param {*} data - Data to cache
     */
    _setCached(key, data) {
        try {
            // For selections, maintain legacy format for backward compatibility
            if (key === 'selectedLearningPaths') {
                localStorage.setItem(key, JSON.stringify(data));
            } else {
                localStorage.setItem(key, JSON.stringify({
                    data,
                    timestamp: Date.now()
                }));
            }
        } catch (err) {
            // Silently fail caching errors
        }
    }

    /**
     * Check if current page is a tracked learning page (catalog or signature path)
     *
     * @private
     * @returns {boolean} True if on catalog page or one of 5 signature learning paths
     */
    _isCatalogPage() {
        const hash = window.location.hash;
        // Match catalog page
        if (hash === '#/learning/catalog') return true;
        // Match learning paths main README
        if (hash === '#/learning/paths/README' || hash === '#/learning/paths/') return true;
        // Match any of the 5 signature learning path pages
        return /^#\/learning\/paths\/(foundation-ai-first-engineering|intermediate-devops-excellence|intermediate-infrastructure-architect|expert-data-analytics-integration|expert-enterprise-integration)$/.test(hash);
    }

    /**
     * Check if current page is specifically a catalog/hub page (not an individual learning path page)
     *
     * @private
     * @returns {boolean} True if on catalog or paths hub page (pages with only path checkboxes)
     */
    _isOnCatalogPageOnly() {
        const hash = window.location.hash;
        // Catalog page and paths hub both have ONLY path checkboxes (no kata checkboxes)
        return hash === '#/learning/catalog' ||
               hash === '#/learning/paths/' ||
               hash === '#/learning/paths/README' ||
               hash.includes('/learning/catalog');
    }

    /**
     * Extract kata ID from pageId format
     * Converts "learning/katas/ai-assisted-engineering/01.md" to "ai-assisted-engineering-01"
     *
     * @param {string} pageId - The page ID from progress data
     * @returns {string|null} Extracted kata ID or null if no match
     */
    extractKataId(pageId) {
        const match = pageId.match(/learning\/katas\/([^\/]+)\/([^\/]+)\.md/);
        return match ? `${match[1]}-${match[2]}` : null;
    }

    // ============================================================================
    // Public API - Assessment Recommendations Integration
    // ============================================================================

    /**
     * Fetch assessment recommendations from API
     * Validates source, timestamp, and staleness
     * Falls back to localStorage on API failure
     *
     * @async
     * @returns {Promise<void>}
     */
    async fetchAssessmentRecommendations() {
        try {
            const response = await fetch('http://localhost:3002/api/learning/selections?userId=default-user');
            if (!response.ok) throw new Error(`API error: ${response.status}`);

            const data = await response.json();

            // Validate source field exists and equals 'assessment'
            if (!data.source || data.source !== 'assessment') {
                return;
            }

            // Validate timestamp exists and is a number
            if (!data.timestamp || typeof data.timestamp !== 'number') {
                return;
            }

            // Check staleness (5 minutes = 300000ms)
            const age = Date.now() - data.timestamp;
            if (age > 300000) {
                return;
            }

            // Populate recommendations array
            // Prefer selectedItems over skillLevel
            if (data.selectedItems && data.selectedItems.length > 0) {
                this.recommendations = data.selectedItems;
            } else if (data.skillLevel) {
                this.recommendations = this.getPathsForSkillLevel(data.skillLevel);
            }

        } catch (error) {
            // Fall back to localStorage on network/API errors
            try {
                const cached = localStorage.getItem('catalog-selections-cache');
                if (cached) {
                    const data = JSON.parse(cached);

                    // Apply same validation to cached data
                    if (data.source === 'assessment' &&
                        data.timestamp &&
                        typeof data.timestamp === 'number' &&
                        Date.now() - data.timestamp <= 300000) {

                        if (data.selectedItems && data.selectedItems.length > 0) {
                            this.recommendations = data.selectedItems;
                        } else if (data.skillLevel) {
                            this.recommendations = this.getPathsForSkillLevel(data.skillLevel);
                        }
                    }
                }
            } catch (cacheError) {
                // Silently fail - no recommendations available
            }
        }
    }

    /**
     * Get recommended learning paths based on skill level
     * Maps skill assessment results to signature learning paths
     *
     * @param {string} skillLevel - Skill level from assessment ('beginner', 'intermediate', 'advanced')
     * @returns {string[]} Array of path IDs recommended for the skill level
     */
    getPathsForSkillLevel(skillLevel) {
        const pathMapping = {
            'beginner': ['path-foundation-ai-engineering'],
            'intermediate': [
                'path-foundation-ai-engineering',
                'path-skill-prompt-engineering',
                'path-skill-edge-to-cloud-integration'
            ],
            'advanced': [
                'path-expert-edge-ai-systems',
                'path-expert-full-stack-ai-integration'
            ]
        };

        return pathMapping[skillLevel] || [];
    }

    /**
     * Apply assessment recommendations to user selections
     * Uses the recommendations property and adds paths to selections
     * Persists to API only if recommendations array is not empty
     *
     * @async
     * @returns {Promise<void>}
     */
    async applyRecommendations() {
        if (!Array.isArray(this.recommendations) || this.recommendations.length === 0) {
            return;
        }

        // Add recommendations to selections Set
        this.recommendations.forEach(pathId => this.selections.add(pathId));

        // Persist to API
        await this.saveSelections();

        // Update UI - always call decorateEntries after applying recommendations
        // This ensures immediate visual feedback when recommendations are accepted
        await this.decorateEntries();
    }

    /**
     * Render filter toggle button for showing/hiding selected items
     * Creates button, attaches event handler, restores saved filter state
     *
     * @returns {void}
     */
}

// Install Docsify plugin (when running in browser)
if (typeof window !== 'undefined' && typeof window.$docsify !== 'undefined') {
    window.$docsify.plugins = window.$docsify.plugins || [];

    // Create singleton instance to prevent memory leaks
    let catalogHydrationInstance = null;

    window.$docsify.plugins.push(function(hook) {
        hook.doneEach(async function() {
            // Reuse existing instance or create new one
            if (!catalogHydrationInstance) {
                catalogHydrationInstance = new CatalogHydration();
            }

            // Only initialize on catalog or learning paths pages
            if (!catalogHydrationInstance._isCatalogPage()) {
                return;
            }

            await catalogHydrationInstance.init();
        });
    });

    // Expose instance getter globally for debugging
    // Use getter to always return current instance value from closure
    if (typeof window !== 'undefined') {
        Object.defineProperty(window, 'catalogHydrationInstance', {
            get: () => catalogHydrationInstance,
            configurable: true
        });
    }
}

// Conditional export for testing environments
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { CatalogHydration };
}
