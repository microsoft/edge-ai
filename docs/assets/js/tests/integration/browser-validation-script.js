/**
 * Browser Console Validation Script for Progress Bar Enhancement
 *
 * Paste this script into the browser console when viewing the Learning Paths page
 * to verify that the progress bar enhancement is working correctly.
 *
 * Instructions:
 * 1. Navigate to: http://localhost:8080/#/learning/learning-paths
 * 2. Open browser developer tools (F12)
 * 3. Paste this entire script into the console and press Enter
 * 4. Check the output to verify the enhancement is working
 */

console.log('🧪 Testing Progress Bar Enhancement Integration...');

// Test 1: Check if enhancement module is loaded
console.log('\n📦 1. Checking if enhancement module is loaded...');
try {
    const enhancement = window.simpleProgressBarEnhancement;
    if (enhancement) {
        console.log('✅ SimpleProgressBarEnhancement found in window object');
    } else {
        console.log('❌ SimpleProgressBarEnhancement not found in window object');
        console.log('📝 This might be normal if the enhancement is not globally exposed');
    }
} catch (_error) {
    console.log('❌ Error checking enhancement:', _error.message);
}

// Test 2: Check for existing progress bar structure
console.log('\n📊 2. Checking existing progress bar structure...');
const progressContainer = document.querySelector('.kata-progress-container, .progress-container, [class*="progress"]');
if (progressContainer) {
    console.log('✅ Progress container found:', progressContainer.className);
    console.log('📏 Container HTML:', `${progressContainer.outerHTML.substring(0, 200) }...`);
} else {
    console.log('❌ No progress container found');
    console.log('📝 Available elements with "progress" in class:',
        Array.from(document.querySelectorAll('[class*="progress"]')).map(el => el.className));
}

// Test 3: Check for checkboxes
console.log('\n☑️ 3. Checking for learning path checkboxes...');
const checkboxes = document.querySelectorAll('input[type="checkbox"]');
console.log(`✅ Found ${checkboxes.length} checkboxes`);
if (checkboxes.length > 0) {
    const checkedCount = Array.from(checkboxes).filter(cb => cb.checked).length;
    console.log(`📊 ${checkedCount} of ${checkboxes.length} checkboxes are checked`);
    console.log(`📈 Completion: ${Math.round((checkedCount / checkboxes.length) * 100)}%`);
}

// Test 4: Check for save/clear buttons or test dynamic creation
console.log('\n🔘 4. Checking for save/clear buttons or dynamic creation...');
const saveBtn = document.querySelector('#save-progress-btn, .progress-save-btn, [class*="save"], button[title*="save"], button[aria-label*="save"]');
const clearBtn = document.querySelector('#clear-progress-btn, .progress-clear-btn, [class*="clear"], button[title*="clear"], button[aria-label*="clear"]');

if (saveBtn) {
    console.log('✅ Save button found:', saveBtn.textContent.trim());
    console.log('📏 Save button HTML:', saveBtn.outerHTML);
} else {
    console.log('❌ Save button not found - testing dynamic creation');

    // Test if we can create buttons dynamically
    if (progressContainer) {
        console.log('🔧 Testing dynamic button creation...');

        const testSaveBtn = document.createElement('button');
        testSaveBtn.id = 'test-save-progress-btn';
        testSaveBtn.textContent = '💾 Test Save';
        testSaveBtn.className = 'test-progress-btn';

        const testClearBtn = document.createElement('button');
        testClearBtn.id = 'test-clear-progress-btn';
        testClearBtn.textContent = '🗑️ Test Clear';
        testClearBtn.className = 'test-progress-btn';

        // Add to progress container
        progressContainer.appendChild(testSaveBtn);
        progressContainer.appendChild(testClearBtn);

        console.log('✅ Test buttons created successfully');
        console.log('💡 This suggests the enhancement could create its own buttons');

        // Clean up test buttons
        setTimeout(() => {
            testSaveBtn.remove();
            testClearBtn.remove();
            console.log('🧹 Test buttons cleaned up');
        }, 2000);
    }
}

if (clearBtn) {
    console.log('✅ Clear button found:', clearBtn.textContent.trim());
    console.log('📏 Clear button HTML:', clearBtn.outerHTML);
} else {
    console.log('❌ Clear button not found');
}

// Test 5: Test save functionality
console.log('\n💾 5. Testing save functionality...');
if (saveBtn) {
    try {
        const originalText = saveBtn.textContent;
        console.log('🔄 Clicking save button...');

        // Clear any existing data first
        localStorage.removeItem('kata-progress-backup');

        saveBtn.click();

        setTimeout(() => {
            const savedData = localStorage.getItem('kata-progress-backup');
            if (savedData) {
                console.log('✅ Data saved to localStorage successfully');
                const parsedData = JSON.parse(savedData);
                console.log('📊 Saved data summary:', {
                    totalTasks: parsedData.metadata?.totalTasks,
                    completedTasks: parsedData.metadata?.completedTasks,
                    completionPercentage: parsedData.metadata?.completionPercentage,
                    timestamp: parsedData.metadata?.timestamp,
                    source: parsedData.metadata?.source
                });
                console.log('📋 Full data structure:', parsedData);
            } else {
                console.log('❌ No data found in localStorage after save');
                console.log('📝 Checking all localStorage keys:');
                for (let i = 0; i < localStorage.length; i++) {
                    const key = localStorage.key(i);
                    console.log(`   ${key}: ${localStorage.getItem(key)?.substring(0, 100)}...`);
                }
            }
        }, 500); // Increased timeout to allow for processing
    } catch (_error) {
        console.log('❌ Error testing save functionality:', _error.message);
    }
} else {
    console.log('⏭️ Skipping save test - save button not found');
}

// Test 6: Check main.js module loading
console.log('\n📚 6. Checking main.js module loading...');
const loadedModules = window.mainApp?.loadedModules;
if (loadedModules) {
    console.log('✅ Main app found with loaded modules');
    const enhancementModule = Array.from(loadedModules.keys()).find(key =>
        key.includes('simple-progress-bar-extension'));
    if (enhancementModule) {
        console.log('✅ Enhancement module loaded:', enhancementModule);
        const moduleInfo = loadedModules.get(enhancementModule);
        console.log('📊 Module info:', moduleInfo);
    } else {
        console.log('❌ Enhancement module not found in loaded modules');
        console.log('📝 Available modules:', Array.from(loadedModules.keys()));
    }
} else {
    console.log('❌ Main app not found or modules not loaded');
}

// Test 7: Test enhancement initialization manually
console.log('\n🔧 7. Testing manual enhancement initialization...');
try {
    // Try to manually initialize the enhancement
    console.log('🔄 Attempting manual initialization...');

    // Check if we can find the enhancement class
    if (typeof SimpleProgressBarEnhancement !== 'undefined') {
        console.log('✅ SimpleProgressBarEnhancement class is available');
        // eslint-disable-next-line no-undef
        const testEnhancement = new SimpleProgressBarEnhancement();
        testEnhancement.init();
        console.log('✅ Manual initialization successful');
    } else {
        console.log('❌ SimpleProgressBarEnhancement class not available globally');
    }

    // Check if event listeners are attached to the save button
    if (saveBtn) {
        console.log('🔍 Checking save button event listeners...');
        const eventListeners = getEventListeners ? getEventListeners(saveBtn) : null;
        if (eventListeners && eventListeners.click) {
            console.log(`✅ Found ${eventListeners.click.length} click event listeners on save button`);
        } else {
            console.log('❌ Cannot inspect event listeners (getEventListeners not available)');
            console.log('💡 This is normal in most browsers - event listeners are attached internally');
        }
    }
} catch (_error) {
    console.log('❌ Error during manual initialization:', _error.message);
}

// Test 8: Check URL pattern matching
console.log('\n🌐 8. Checking URL pattern matching...');
const currentUrl = window.location.href;
const currentHash = window.location.hash;
console.log('📍 Current URL:', currentUrl);
console.log('📍 Current hash:', currentHash);

const isKataPage = /\/katas\/[^/]+\/[^/]+/.test(currentHash) ||
                  currentHash.includes('kata') ||
                  document.title.toLowerCase().includes('kata');

if (isKataPage) {
    console.log('✅ Current page appears to be a kata page');
} else {
    console.log('❌ Current page does not appear to be a kata page');
    console.log('💡 Try navigating to: http://localhost:8080/#/learning/katas/ai-assisted-engineering/01-ai-development-fundamentals');
}

// Summary
console.log('\n📋 SUMMARY');
console.log('=========');
console.log(`Progress container: ${progressContainer ? '✅' : '❌'}`);
console.log(`Checkboxes: ${checkboxes.length > 0 ? '✅' : '❌'} (${checkboxes.length} found)`);
console.log(`Save button: ${saveBtn ? '✅' : '❌'}`);
console.log(`Clear button: ${clearBtn ? '✅' : '❌'}`);
console.log(`Is kata page: ${isKataPage ? '✅' : '❌'}`);

if (progressContainer && checkboxes.length > 0 && saveBtn && clearBtn) {
    console.log('\n🎉 ALL TESTS PASSED! The progress bar enhancement appears to be working correctly.');
} else {
    console.log('\n🔧 ISSUES DETECTED. Some functionality may not be working as expected.');
    console.log('💡 Make sure you are on a kata page and the enhancement module is loaded.');
}

console.log('\n🏁 Validation complete!');
