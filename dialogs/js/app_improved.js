/**
 * Oob Layouts Extension - Enhanced JavaScript
 * Improved dialog functionality with better error handling and user experience
 * Version: 7.0 Enhanced
 */

// Configuration
const OobConfig = {
    throttleDelay: 350,
    menuSpeed: 235,
    navbarHeight: 49,
    enableDebug: false
};

// Global variables
let oobDialog = {
    computationDone: false,
    currentPreset: null,
    validationErrors: []
};

// Utility functions
const OobUtils = {
    
    /**
     * Log messages to console and optionally to Ruby
     * @param {string} message - Message to log
     * @param {string} level - Log level (info, warn, error)
     */
    log: function(message, level = 'info') {
        if (OobConfig.enableDebug) {
            console[level](message);
        }
        
        // Send to Ruby if available
        if (typeof window.location !== 'undefined') {
            try {
                this.callRuby('log_message', `${level.toUpperCase()}: ${message}`);
            } catch (e) {
                // Silently fail if Ruby callback not available
            }
        }
    },
    
    /**
     * Call Ruby function safely
     * @param {string} functionName - Ruby function name
     * @param {string} message - Message to send
     */
    callRuby: function(functionName, message) {
        try {
            const url = `skp:${functionName}@${encodeURIComponent(message)}`;
            window.location.href = url;
        } catch (e) {
            this.log(`Error calling Ruby function ${functionName}: ${e.message}`, 'error');
        }
    },
    
    /**
     * Validate numeric input
     * @param {string} value - Value to validate
     * @param {number} min - Minimum value
     * @param {number} max - Maximum value
     * @return {boolean} - Is valid
     */
    validateNumber: function(value, min = 0, max = Infinity) {
        const num = parseFloat(value);
        return !isNaN(num) && num >= min && num <= max;
    },
    
    /**
     * Parse multi-value string (semicolon separated)
     * @param {string} value - Input string
     * @return {Array} - Array of numbers
     */
    parseMultiValue: function(value) {
        if (!value || typeof value !== 'string') return [];
        
        return value.split(';')
            .map(v => v.trim())
            .filter(v => v !== '' && v !== '0' && v !== '0.0')
            .map(v => parseFloat(v))
            .filter(v => !isNaN(v) && v > 0);
    },
    
    /**
     * Format number for display
     * @param {number} value - Number to format
     * @param {number} decimals - Number of decimal places
     * @return {string} - Formatted number
     */
    formatNumber: function(value, decimals = 2) {
        return parseFloat(value).toFixed(decimals);
    },
    
    /**
     * Debounce function calls
     * @param {Function} func - Function to debounce
     * @param {number} wait - Wait time in ms
     * @return {Function} - Debounced function
     */
    debounce: function(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }
};

// Input validation and synchronization
const OobValidation = {
    
    /**
     * Validation rules for inputs
     */
    rules: {
        'input2': { min: 0.01, max: 1000, name: 'Length' },
        'input3': { min: 0.01, max: 1000, name: 'Height' },
        'input4': { min: 0.001, max: 100, name: 'Thickness' },
        'input5': { min: 0, max: 100, name: 'Joint Length' },
        'input6': { min: 0, max: 100, name: 'Joint Width' },
        'input7': { min: 0, max: 100, name: 'Joint Depth' },
        'input8': { min: 0, max: 1000, name: 'Row Offset' },
        'inputrand2': { min: 0, max: 1, name: 'Length Random' },
        'inputrand3': { min: 0, max: 1, name: 'Height Random' },
        'inputrand4': { min: 0, max: 1, name: 'Thickness Random' },
        'inputrand5': { min: 0, max: 20, name: 'Color Random' }
    },
    
    /**
     * Validate single input
     * @param {string} inputId - Input element ID
     * @param {string} value - Value to validate
     * @return {Object} - Validation result
     */
    validateInput: function(inputId, value) {
        const rule = this.rules[inputId];
        if (!rule) return { valid: true };
        
        // Handle multi-value inputs
        if (inputId === 'input2' || inputId === 'input3') {
            const values = OobUtils.parseMultiValue(value);
            if (values.length === 0) {
                return {
                    valid: false,
                    message: `${rule.name} must have at least one valid value`
                };
            }
            
            for (let val of values) {
                if (!OobUtils.validateNumber(val, rule.min, rule.max)) {
                    return {
                        valid: false,
                        message: `${rule.name} values must be between ${rule.min} and ${rule.max}`
                    };
                }
            }
            return { valid: true };
        }
        
        // Single value validation
        if (!OobUtils.validateNumber(value, rule.min, rule.max)) {
            return {
                valid: false,
                message: `${rule.name} must be between ${rule.min} and ${rule.max}`
            };
        }
        
        return { valid: true };
    },
    
    /**
     * Validate all inputs
     * @return {Array} - Array of validation errors
     */
    validateAll: function() {
        const errors = [];
        
        Object.keys(this.rules).forEach(inputId => {
            const element = document.getElementById(inputId);
            if (element) {
                const result = this.validateInput(inputId, element.value);
                if (!result.valid) {
                    errors.push(result.message);
                }
            }
        });
        
        return errors;
    },
    
    /**
     * Show validation error
     * @param {string} inputId - Input element ID
     * @param {string} message - Error message
     */
    showError: function(inputId, message) {
        const element = document.getElementById(inputId);
        if (element) {
            element.classList.add('error');
            element.title = message;
            
            // Remove error after 3 seconds
            setTimeout(() => {
                element.classList.remove('error');
                element.title = '';
            }, 3000);
        }
    },
    
    /**
     * Clear all validation errors
     */
    clearErrors: function() {
        Object.keys(this.rules).forEach(inputId => {
            const element = document.getElementById(inputId);
            if (element) {
                element.classList.remove('error');
                element.title = '';
            }
        });
    }
};

// Input synchronization
const OobSync = {
    
    /**
     * Synchronized input pairs
     */
    syncPairs: {
        'input2': 'input5', // Length <-> Joint Length
        'input5': 'input2',
        'input3': 'input6', // Height <-> Joint Width  
        'input6': 'input3'
    },
    
    /**
     * Initialize input synchronization
     */
    init: function() {
        Object.keys(this.syncPairs).forEach(sourceId => {
            const sourceElement = document.getElementById(sourceId);
            const targetId = this.syncPairs[sourceId];
            
            if (sourceElement) {
                sourceElement.addEventListener('input', 
                    OobUtils.debounce((e) => this.syncInputs(sourceId, targetId, e.target.value), 300)
                );
            }
        });
    },
    
    /**
     * Synchronize two inputs
     * @param {string} sourceId - Source input ID
     * @param {string} targetId - Target input ID
     * @param {string} value - Value to sync
     */
    syncInputs: function(sourceId, targetId, value) {
        const targetElement = document.getElementById(targetId);
        if (targetElement && targetElement.value !== value) {
            targetElement.value = value;
            OobUtils.log(`Synchronized ${targetId} with ${sourceId}: ${value}`);
            
            // Trigger change event
            targetElement.dispatchEvent(new Event('input', { bubbles: true }));
        }
    }
};

// Preset management
const OobPresets = {
    
    /**
     * Save current settings as preset
     */
    save: function() {
        // Validate inputs first
        const errors = OobValidation.validateAll();
        if (errors.length > 0) {
            alert('Please fix validation errors before saving preset:\n' + errors.join('\n'));
            return;
        }
        
        OobUtils.callRuby('savepreset', 'true');
    },
    
    /**
     * Delete current preset
     */
    delete: function() {
        const selectElement = document.getElementById('selectPreset');
        if (!selectElement || !selectElement.value) {
            alert('Please select a preset to delete');
            return;
        }
        
        if (confirm(`Delete preset "${selectElement.value}"?`)) {
            OobUtils.callRuby('deletepreset', selectElement.value);
        }
    },
    
    /**
     * Load selected preset
     * @param {string} presetName - Name of preset to load
     */
    load: function(presetName) {
        if (!presetName) return;
        
        OobValidation.clearErrors();
        OobUtils.callRuby('selectpreset', presetName);
        oobDialog.currentPreset = presetName;
    },
    
    /**
     * Add preset option to dropdown
     * @param {string} presetName - Preset name
     */
    addOption: function(presetName) {
        const selectElement = document.getElementById('selectPreset');
        if (selectElement) {
            const option = new Option(presetName, presetName);
            selectElement.add(option);
        }
    },
    
    /**
     * Clear all preset options
     */
    clearOptions: function() {
        const selectElement = document.getElementById('selectPreset');
        if (selectElement) {
            selectElement.innerHTML = '<option>Select a preset</option>';
        }
    }
};

// Advanced controls management
const OobAdvanced = {
    
    /**
     * Initialize advanced controls
     */
    init: function() {
        this.setupStartRowHeightControl();
        this.setupPatternRotationControl();
        this.setupValidationListeners();
    },
    
    /**
     * Setup start row height dropdown
     */
    setupStartRowHeightControl: function() {
        const heightInput = document.getElementById('input3');
        const dropdown = document.getElementById('startRowHeight');
        
        if (!heightInput || !dropdown) return;
        
        const updateDropdown = OobUtils.debounce(() => {
            const heightValue = heightInput.value;
            const values = OobUtils.parseMultiValue(heightValue);
            
            // Clear dropdown
            dropdown.innerHTML = '<option value="auto">Auto</option>';
            
            // Add height values as options
            values.forEach(value => {
                const option = new Option(OobUtils.formatNumber(value), value);
                dropdown.add(option);
            });
            
            OobUtils.log(`Updated start row height dropdown with ${values.length} options`);
        }, 200);
        
        // Update dropdown when height input changes
        heightInput.addEventListener('input', updateDropdown);
        heightInput.addEventListener('change', updateDropdown);
        
        // Handle dropdown selection
        dropdown.addEventListener('change', (e) => {
            const selectedValue = e.target.value;
            if (selectedValue === 'auto') return;
            
            // Move selected value to front of height list
            const currentValues = OobUtils.parseMultiValue(heightInput.value);
            const filteredValues = currentValues.filter(v => v != selectedValue);
            const newValues = [parseFloat(selectedValue), ...filteredValues];
            
            heightInput.value = newValues.join(';');
            updateDropdown();
            
            OobUtils.log(`Reordered height values, ${selectedValue} moved to front`);
        });
        
        // Initial update
        setTimeout(updateDropdown, 100);
    },
    
    /**
     * Setup pattern rotation control
     */
    setupPatternRotationControl: function() {
        const rotationSelect = document.getElementById('patternRotation');
        const startFromSelect = document.getElementById('startFrom');
        
        if (rotationSelect) {
            rotationSelect.addEventListener('change', (e) => {
                OobUtils.log(`Pattern rotation changed to: ${e.target.value}`);
                
                // Update start from options based on rotation
                if (startFromSelect) {
                    if (e.target.value === 'vertical') {
                        startFromSelect.innerHTML = `
                            <option value="left">Left</option>
                            <option value="right">Right</option>
                        `;
                    } else {
                        startFromSelect.innerHTML = `
                            <option value="bottom">Bottom</option>
                            <option value="top">Top</option>
                        `;
                    }
                }
            });
        }
    },
    
    /**
     * Setup validation listeners for all inputs
     */
    setupValidationListeners: function() {
        Object.keys(OobValidation.rules).forEach(inputId => {
            const element = document.getElementById(inputId);
            if (element) {
                element.addEventListener('blur', (e) => {
                    const result = OobValidation.validateInput(inputId, e.target.value);
                    if (!result.valid) {
                        OobValidation.showError(inputId, result.message);
                    }
                });
            }
        });
    },
    
    /**
     * Get all advanced control values
     * @return {Object} - Advanced control values
     */
    getValues: function() {
        return {
            patternRotation: this.getElementValue('patternRotation', 'horizontal'),
            startFrom: this.getElementValue('startFrom', 'bottom'),
            forceFullRow: this.getElementValue('forceFullRow', false, 'checkbox'),
            startRowHeight: this.getElementValue('startRowHeight', 'auto'),
            lastRowPlacement: this.getElementValue('lastRowPlacement', 'cut')
        };
    },
    
    /**
     * Get element value safely
     * @param {string} id - Element ID
     * @param {*} defaultValue - Default value
     * @param {string} type - Element type
     * @return {*} - Element value
     */
    getElementValue: function(id, defaultValue, type = 'input') {
        const element = document.getElementById(id);
        if (!element) return defaultValue;
        
        if (type === 'checkbox') {
            return element.checked;
        }
        
        return element.value || defaultValue;
    }
};

// Main dialog functions
const OobDialog = {
    
    /**
     * Initialize dialog
     */
    init: function() {
        OobSync.init();
        OobAdvanced.init();
        this.setupEventListeners();
        this.setupKeyboardShortcuts();
        
        OobUtils.log('Oob dialog initialized');
    },
    
    /**
     * Setup event listeners
     */
    setupEventListeners: function() {
        // Preset dropdown
        const presetSelect = document.getElementById('selectPreset');
        if (presetSelect) {
            presetSelect.addEventListener('change', (e) => {
                if (e.target.value && e.target.value !== 'Select a preset') {
                    OobPresets.load(e.target.value);
                }
            });
        }
        
        // Enter key handling
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' && e.target.tagName === 'INPUT') {
                e.preventDefault();
                this.apply();
            }
        });
        
        // Form validation on submit
        document.addEventListener('submit', (e) => {
            e.preventDefault();
            this.apply();
        });
    },
    
    /**
     * Setup keyboard shortcuts
     */
    setupKeyboardShortcuts: function() {
        document.addEventListener('keydown', (e) => {
            if (e.ctrlKey || e.metaKey) {
                switch (e.key) {
                    case 's':
                        e.preventDefault();
                        OobPresets.save();
                        break;
                    case 'Enter':
                        e.preventDefault();
                        this.apply();
                        break;
                    case 'Escape':
                        e.preventDefault();
                        this.cancel();
                        break;
                }
            }
        });
    },
    
    /**
     * Apply layout
     */
    apply: function() {
        // Validate inputs
        const errors = OobValidation.validateAll();
        if (errors.length > 0) {
            alert('Please fix the following errors:\n' + errors.join('\n'));
            return;
        }
        
        // Clear any existing errors
        OobValidation.clearErrors();
        
        // Get advanced values
        const advancedValues = OobAdvanced.getValues();
        OobUtils.log('Applying layout with advanced options:', 'info');
        OobUtils.log(JSON.stringify(advancedValues), 'info');
        
        // Call Ruby
        OobUtils.callRuby('calcul', '1'); // 1 = Apply
        oobDialog.computationDone = true;
    },
    
    /**
     * OK button (apply and close)
     */
    ok: function() {
        this.apply();
        // Ruby will handle closing the dialog
        OobUtils.callRuby('calcul', '2'); // 2 = OK
    },
    
    /**
     * Cancel button
     */
    cancel: function() {
        if (oobDialog.computationDone) {
            if (confirm('Cancel the operation and undo changes?')) {
                OobUtils.callRuby('calcul', '3'); // 3 = Cancel
            }
        } else {
            OobUtils.callRuby('calcul', '3'); // 3 = Cancel
        }
    }
};

// Global functions for Ruby callbacks
window.setValue = function(pair) {
    const [id, value] = pair.split(';');
    const element = document.getElementById(id);
    
    if (element) {
        // Handle special formatting for multi-values
        const formattedValue = value.replace(/#/g, ';');
        element.value = formattedValue;
        
        // Handle radio buttons
        if (id === 'inputstartpoint') {
            const radioValue = parseInt(value);
            ['labeloption1', 'labeloption2', 'labeloption3'].forEach((labelId, index) => {
                const label = document.getElementById(labelId);
                if (label) {
                    if (index + 1 === radioValue) {
                        label.classList.add('active');
                    } else {
                        label.classList.remove('active');
                    }
                }
            });
        }
        
        // Trigger input event for synchronization
        element.dispatchEvent(new Event('input', { bubbles: true }));
        
        OobUtils.log(`Set ${id} to ${formattedValue}`);
    } else {
        OobUtils.log(`Element ${id} not found`, 'warn');
    }
};

window.setLabel = function(pair) {
    const [id, text] = pair.split(';');
    const element = document.getElementById(id);
    
    if (element) {
        element.innerHTML = text;
        OobUtils.log(`Set label ${id} to ${text}`);
    }
};

window.setCheckValue = function(pair) {
    const [id, value] = pair.split(';');
    const element = document.getElementById(id);
    
    if (element) {
        element.checked = value === 'true';
        element.value = value;
        OobUtils.log(`Set checkbox ${id} to ${value}`);
    }
};

window.addPresetOption = function(presetName) {
    OobPresets.addOption(presetName);
};

window.clearPresetOption = function() {
    OobPresets.clearOptions();
};

window.setPreset = function(presetName) {
    const selectElement = document.getElementById('selectPreset');
    if (selectElement) {
        selectElement.value = presetName;
        oobDialog.currentPreset = presetName;
    }
};

window.compute = function() {
    // Trigger recalculation if needed
    OobUtils.log('Compute triggered from Ruby');
};

// Button click handlers
window.button_clicked = function(flag) {
    switch (flag) {
        case 1: // Apply
            OobDialog.apply();
            break;
        case 2: // OK
            OobDialog.ok();
            break;
        case 3: // Cancel
            OobDialog.cancel();
            break;
    }
};

window.saveCurrentPreset = function() {
    OobPresets.save();
};

window.deleteCurrentPreset = function() {
    OobPresets.delete();
};

window.setRadioValue = function(value) {
    const hiddenInput = document.getElementById('inputstartpoint');
    if (hiddenInput) {
        hiddenInput.value = value;
        OobUtils.log(`Set radio value to ${value}`);
    }
};

// Enter key handler
window.submitenter = function(field, event) {
    if (event.keyCode === 13) {
        event.preventDefault();
        OobDialog.apply();
        return false;
    }
    return true;
};

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    OobDialog.init();
    
    // Add CSS for validation errors
    const style = document.createElement('style');
    style.textContent = `
        .error {
            border-color: #dc3545 !important;
            box-shadow: 0 0 0 0.2rem rgba(220, 53, 69, 0.25) !important;
        }
        
        .form-control:focus {
            border-color: #80bdff;
            box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
        }
        
        .btn:focus {
            box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
        }
        
        .validation-message {
            color: #dc3545;
            font-size: 0.875em;
            margin-top: 0.25rem;
        }
    `;
    document.head.appendChild(style);
});

// Export for testing
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        OobUtils,
        OobValidation,
        OobSync,
        OobPresets,
        OobAdvanced,
        OobDialog
    };
}