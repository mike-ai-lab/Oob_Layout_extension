# Oob Layouts - Enhanced SketchUp Extension

A powerful SketchUp extension for creating parametric cladding and tiling layouts with advanced pattern controls and material management.

## Features

### Core Functionality
- **Parametric Layout Generation**: Create complex cladding patterns with precise control
- **Multi-Value Support**: Use multiple dimensions for varied, realistic layouts
- **Advanced Pattern Controls**: Horizontal/vertical orientation, start direction, row controls
- **Material Management**: Support for multiple materials with randomization
- **Preset System**: Save and load frequently used configurations

### Enhanced User Interface
- **Responsive Design**: Works on different screen sizes
- **Real-Time Validation**: Immediate feedback on input errors
- **Field Synchronization**: Automatic coordination between related inputs
- **Accessibility Support**: Screen reader compatible with keyboard navigation
- **Contextual Help**: Built-in help text for all parameters

### Advanced Controls
- **Pattern Rotation**: Switch between horizontal and vertical layouts
- **Start Direction**: Control layout starting point (top/bottom, left/right)
- **Row Height Control**: Specify custom heights for the first row
- **Staggered Joints**: Create realistic offset patterns
- **Last Row Handling**: Options for incomplete rows at boundaries

## Installation

1. **Download Files**: Copy the improved files to your SketchUp Plugins directory:
   - `Oob_improved.rb`
   - `dialogs/OobONE_improved.html`
   - `dialogs/js/app_improved.js`

2. **Restart SketchUp**: Close and reopen SketchUp to load the extension

3. **Access Plugin**: Find "Oob Layouts Enhanced" in the Plugins menu

## Quick Start Guide

### Basic Layout Creation

1. **Select a Face**: Choose the face where you want to apply the cladding layout
2. **Open Dialog**: Go to Plugins > Oob Layouts Enhanced
3. **Set Dimensions**:
   - **Length**: Width of individual elements (e.g., 4.5)
   - **Height**: Height of individual elements (e.g., 1.0)
   - **Thickness**: Depth of the cladding (e.g., 0.02)
4. **Configure Joints**:
   - **Joint Length**: Horizontal spacing between elements
   - **Joint Height**: Vertical spacing between rows
   - **Row Offset**: Stagger amount between rows
5. **Click Apply**: Generate the layout

### Multi-Value Inputs

Create varied layouts by entering multiple values separated by semicolons:

```
Length: 4.5;3.0;5.5;4.0
Height: 1.0;0.8;1.2
```

This creates layouts with mixed element sizes for more realistic appearance.

### Advanced Pattern Controls

#### Pattern Rotation
- **Horizontal**: Traditional horizontal cladding (default)
- **Vertical**: Vertical board pattern

#### Start Direction
- **Bottom**: Start layout from bottom edge (horizontal patterns)
- **Top**: Start layout from top edge (horizontal patterns)
- **Left**: Start layout from left edge (vertical patterns)
- **Right**: Start layout from right edge (vertical patterns)

#### Row Controls
- **Starting Row Height**: Override the height of the first row
- **Force Full Row**: Ensure first row uses complete elements
- **Last Row Placement**: 
  - **Cut**: Trim last row to face bounds
  - **Full**: Allow last row to extend beyond bounds

## Parameter Reference

### Dimensions
| Parameter | Description | Example | Range |
|-----------|-------------|---------|-------|
| Length | Element width | 4.5 cm | 0.01 - 1000 |
| Height | Element height | 1.0 cm | 0.01 - 1000 |
| Thickness | Element depth | 0.02 cm | 0.001 - 100 |

### Joints & Spacing
| Parameter | Description | Example | Range |
|-----------|-------------|---------|-------|
| Joint Length | Horizontal gap | 0.005 cm | 0 - 100 |
| Joint Height | Vertical gap | 0.005 cm | 0 - 100 |
| Joint Depth | Gap depth | 0.005 cm | 0 - 100 |
| Row Offset | Stagger amount | 1.5 cm | 0 - 1000 |

### Randomization
| Parameter | Description | Range | Effect |
|-----------|-------------|-------|--------|
| Length Random | Size variation | 0.0 - 1.0 | 0=uniform, 1=max variation |
| Height Random | Height variation | 0.0 - 1.0 | 0=uniform, 1=max variation |
| Thickness Random | Depth variation | 0.0 - 1.0 | 0=uniform, 1=max variation |
| Color Random | Material variation | 0.0 - 20.0 | Number of color variants |

### Materials
- **Material Name**: SketchUp material name or RGB values
- **RGB Format**: Use comma-separated values: `122,250,0`
- **Alpha Support**: Add alpha channel: `122,250,0,128`

## Preset Management

### Saving Presets
1. Configure your desired parameters
2. Click the **+** button next to the preset dropdown
3. Enter a name for your preset
4. Click OK to save

### Loading Presets
1. Select a preset from the dropdown
2. Parameters will automatically update
3. Units are automatically converted to match your model

### Deleting Presets
1. Select the preset to delete
2. Click the **trash** button
3. Confirm deletion

## Tips and Best Practices

### Performance Optimization
- **Element Limits**: The extension warns when creating >1500 elements
- **Test Small**: Start with small areas to test parameters
- **Use Presets**: Save working configurations for reuse

### Realistic Layouts
- **Multi-Values**: Use varied dimensions for natural appearance
- **Randomization**: Add 10-20% randomization for organic feel
- **Staggered Joints**: Enable for traditional masonry patterns

### Material Setup
- **Prepare Materials**: Create materials in SketchUp before using
- **Color Variations**: Use random colors for weathered appearance
- **Texture Support**: The extension preserves material textures

### Common Patterns

#### Traditional Brick
```
Length: 21.0;10.5
Height: 6.5
Joint Length: 1.0
Joint Height: 1.0
Row Offset: 10.5
Staggered Joints: Enabled
```

#### Wood Cladding
```
Length: 120.0;90.0;150.0
Height: 15.0
Thickness: 2.0
Joint Length: 0.5
Joint Height: 0.5
Row Offset: 30.0
Length Random: 0.1
```

#### Tile Pattern
```
Length: 30.0
Height: 30.0
Joint Length: 0.2
Joint Height: 0.2
Row Offset: 15.0
Pattern: Horizontal
Start From: Bottom
```

## Troubleshooting

### Common Issues

#### "No face selected"
- **Solution**: Select a face before running the plugin
- **Check**: Ensure you've selected a face, not an edge or vertex

#### "Invalid dimensions"
- **Solution**: Check that all dimensions are positive numbers
- **Check**: Length and height must be greater than 0

#### "Too many elements"
- **Solution**: Reduce face size or increase element dimensions
- **Check**: Consider breaking large faces into smaller sections

#### Layout doesn't appear
- **Solution**: Check that thickness isn't zero
- **Check**: Verify the face normal direction
- **Check**: Look for elements on different layers

### Performance Issues

#### Slow generation
- **Reduce Elements**: Use larger element sizes
- **Simplify Pattern**: Reduce randomization factors
- **Check Hardware**: Ensure adequate system resources

#### Memory warnings
- **Break Up Work**: Process large areas in sections
- **Reduce Complexity**: Limit multi-value arrays
- **Close Other Applications**: Free up system memory

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Enter | Apply layout |
| Ctrl+S | Save preset |
| Ctrl+Enter | Apply and close |
| Escape | Cancel |

## Version History

### Version 7.0 Enhanced
- Complete code refactoring for better maintainability
- Enhanced user interface with validation
- Advanced pattern controls
- Improved error handling and performance
- Better accessibility support

### Previous Versions
- See original documentation for legacy version history

## Support and Contributing

### Getting Help
- Check this documentation first
- Review the troubleshooting section
- Test with simple parameters before complex layouts

### Reporting Issues
When reporting problems, include:
- SketchUp version
- Operating system
- Parameter values used
- Error messages (if any)
- Steps to reproduce

### Contributing
The improved codebase is designed for easy extension:
- Modular architecture allows easy feature addition
- Comprehensive documentation aids development
- Clear separation of concerns simplifies maintenance

## License

This enhanced version maintains compatibility with the original license terms while adding significant improvements to functionality, usability, and maintainability.

## Acknowledgments

- Original Oob extension developers
- SketchUp community for feedback and testing
- Contributors to the enhancement project