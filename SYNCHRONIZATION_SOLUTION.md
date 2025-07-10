# SketchUp Dialog Input Field Synchronization Solution

## Problem
The synchronization of two input fields within the SketchUp dialog box works normally outside SketchUp but fails inside the SketchUp environment due to how JavaScript events are handled in SketchUp's embedded browser.

## Root Cause
The issue occurs because:
1. Standard browser events (`input`, `change`) are not firing consistently in SketchUp's embedded browser
2. Programmatic value changes from Ruby code don't trigger event listeners reliably
3. The `dispatchEvent` method for synthetic events has limitations in older embedded browser engines

## Solution Implemented

### 1. Enhanced JavaScript Synchronization (app.js)

#### A. Robust Client-Side Event Listeners
Added to the `$(document).ready()` function:

```javascript
// Synchronization for Length fields (input2 and input5)
$('#input2').on('input', function() {
    const currentValue = $(this).val();
    $('#input5').val(currentValue);
    logToRuby('User input synchronized input5 with input2: ' + currentValue);
});

$('#input5').on('input', function() {
    const currentValue = $(this).val();
    $('#input2').val(currentValue);
    logToRuby('User input synchronized input2 with input5: ' + currentValue);
});

// Synchronization for Height fields (input3 and input6)
$('#input3').on('input', function() {
    const currentValue = $(this).val();
    $('#input6').val(currentValue);
    logToRuby('User input synchronized input6 with input3: ' + currentValue);
});

$('#input6').on('input', function() {
    const currentValue = $(this).val();
    $('#input3').val(currentValue);
    logToRuby('User input synchronized input3 with input6: ' + currentValue);
});
```

#### B. Enhanced setValue Function
Modified the `setValue` function to include direct synchronization:

```javascript
function setValue(pair) {
    const [id, value] = pair.split(';');
    console.log("Setting", id, "to", value);

    const el = document.getElementById(id);
    if (el) {
        el.value = value;

        // Enhanced synchronization for specific paired fields
        if (id === 'input2') { // Length field
            const otherEl = document.getElementById('input5'); // Space length field
            if (otherEl) {
                otherEl.value = value;
                logToRuby('Synchronized input5 with input2: ' + value);
            }
        } else if (id === 'input5') { // Space length field
            const otherEl = document.getElementById('input2'); // Length field
            if (otherEl) {
                otherEl.value = value;
                logToRuby('Synchronized input2 with input5: ' + value);
            }
        } else if (id === 'input3') { // Height field
            const otherEl = document.getElementById('input6'); // Space height field
            if (otherEl) {
                otherEl.value = value;
                logToRuby('Synchronized input6 with input3: ' + value);
            }
        } else if (id === 'input6') { // Space height field
            const otherEl = document.getElementById('input3'); // Height field
            if (otherEl) {
                otherEl.value = value;
                logToRuby('Synchronized input3 with input6: ' + value);
            }
        }

        // Keep the original dispatchEvent for other potential listeners
        if (el.dispatchEvent) {
            el.dispatchEvent(new Event('input'));
        }
    } else {
        console.warn("Field not found:", id);
    }
}
```

#### C. Debug Function for Ruby Console
Added debugging capability:

```javascript
function logToRuby(message) {
    if (typeof Sketchup !== 'undefined' && Sketchup.callback) {
        Sketchup.callback('log_message', message);
    } else {
        console.log("Not in SketchUp or callback not available:", message);
    }
}
```

### 2. Ruby Debug Callback (Oob.rb)

Add this callback to the Ruby file in the callback section:

```ruby
# Debug callback for JavaScript messages
#========================================
@dialogOobOne.add_action_callback("log_message") do |action_context, message|
    puts "JS Debug: #{message}"
end
```

## Field Pairs Currently Synchronized

1. **Length Fields**: `input2` (Length) ↔ `input5` (Space length)
2. **Height Fields**: `input3` (Height) ↔ `input6` (Space height)

## How to Customize for Different Field Pairs

To synchronize different input fields, modify the field IDs in both the event listeners and the setValue function:

1. Replace `'input2'` and `'input5'` with your actual field IDs
2. Replace `'input3'` and `'input6'` with your actual field IDs
3. Update the comments to reflect the actual field purposes

## Benefits of This Solution

1. **Dual Synchronization**: Works for both user input and programmatic value changes
2. **Direct Value Setting**: Bypasses event propagation issues by directly setting values
3. **Debugging Capability**: Provides visibility into synchronization actions via Ruby Console
4. **SketchUp Compatibility**: Designed specifically for SketchUp's embedded browser limitations
5. **Fallback Support**: Maintains original event dispatching for other listeners

## Testing the Solution

1. Open the SketchUp dialog
2. Type in one of the synchronized fields
3. Verify the paired field updates automatically
4. Check the Ruby Console (`Window > Ruby Console`) for debug messages
5. Test with preset loading to ensure programmatic synchronization works

## Troubleshooting

If synchronization doesn't work:

1. Check the Ruby Console for debug messages
2. Verify the field IDs match your actual HTML input elements
3. Ensure the debug callback is properly added to the Ruby file
4. Test outside SketchUp first to verify basic functionality

## Files Modified

- `dialogs/js/app.js` - Enhanced with synchronization logic and debugging
- `Oob.rb` - Add debug callback (manual step required)

This solution provides robust input field synchronization that works reliably within SketchUp's embedded browser environment.