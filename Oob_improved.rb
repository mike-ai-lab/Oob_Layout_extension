# Oob Layouts Extension - Improved Version
# A SketchUp extension for creating parametric cladding layouts
# Author: Improved by AI Assistant
# Version: 7.0 Enhanced

# Remove existing constant if defined
Object.send(:remove_const, :BR_OOB) if defined?(BR_OOB)

# Version information
OOB_VERSION_FULL ||= "ENH7.0" # Enhanced Version 7.0

# Configuration constants
module OobConfig
  PLUGIN_DIR = 'Plugins/Oob-layouts/'
  VERSION = "Oob Enhanced 7.0"
  
  # Default values (in cm, will be converted based on model units)
  DEFAULT_THICKNESS = 0.02
  DEFAULT_HEIGHT = 1.0
  DEFAULT_LENGTH = 4.5
  DEFAULT_JOINT_LENGTH = 0.005
  DEFAULT_JOINT_WIDTH = 0.005
  DEFAULT_JOINT_DEPTH = 0.005
  DEFAULT_ROW_OFFSET = 1.50
  
  # Limits for safety
  MAX_ELEMENTS = 1500
  MAX_RANDOM_COLORS = 20
end

# Parameter class for storing element properties
class LayoutParameter
  attr_accessor :type_bundle, :editable_flag, :uid, :icon, :id, :item_type
  attr_accessor :branch, :sub_branch, :label, :check_value, :image
  attr_accessor :branch_opened, :tooltip, :value

  def initialize
    @label = @image = ""
  end
end

# Geometry utilities module
module GeometryUtils
  
  # Copy a face with optional offset
  # @param face [Sketchup::Face] The face to copy
  # @param vector [Geom::Vector3d] Direction vector
  # @param distance [Float] Distance to offset
  # @param entities [Sketchup::Entities] Target entities collection
  # @param material [Sketchup::Material] Material to apply
  # @return [Sketchup::Face] The new face
  def self.copy_face(face, vector, distance, entities, material)
    return nil unless face && entities
    
    outer_vertices = []
    vector.length = distance if distance != 0
    
    face.outer_loop.vertices.each do |vertex|
      if distance != 0
        outer_vertices.push(vertex.position.offset(vector))
      else
        outer_vertices.push(vertex.position)
      end
    end
    
    # Create face from outer loop
    outer_face = entities.add_face(outer_vertices)
    return nil unless outer_face
    
    # Handle inner loops (holes)
    if face.loops.length > 1
      inner_faces = []
      inner_loops = face.loops.dup
      inner_loops.shift # Remove outer loop
      
      inner_loops.each do |loop|
        inner_vertices = []
        loop.vertices.each do |vertex|
          if distance != 0
            inner_vertices.push(vertex.position.offset(vector))
          else
            inner_vertices.push(vertex.position)
          end
        end
        
        inner_face = entities.add_face(inner_vertices)
        inner_faces.push(inner_face) if inner_face
      end
      
      # Remove inner faces to create holes
      inner_faces.each(&:erase!)
    end
    
    outer_face.material = material if material
    outer_face
  rescue => e
    puts "Error in copy_face: #{e.message}"
    nil
  end
  
  # Get the longest edge of a face
  # @param face [Sketchup::Face] The face to analyze
  # @return [Sketchup::Edge] The longest edge
  def self.get_longest_edge(face)
    return nil unless face
    
    max_length = 0.0
    longest_edge = nil
    
    face.outer_loop.edges.each do |edge|
      if edge.length > max_length
        max_length = edge.length
        longest_edge = edge
      end
    end
    
    longest_edge
  end
  
  # Calculate mean point of vertices
  # @param vertices [Array<Sketchup::Vertex>] Array of vertices
  # @return [Geom::Point3d] Mean point
  def self.get_mean_point(vertices)
    return nil if vertices.empty?
    
    x_sum = y_sum = z_sum = 0.0
    
    vertices.each do |vertex|
      pos = vertex.position
      x_sum += pos.x
      y_sum += pos.y
      z_sum += pos.z
    end
    
    count = vertices.size
    Geom::Point3d.new(x_sum / count, y_sum / count, z_sum / count)
  end
  
  # Add debug line for visualization
  # @param point [Geom::Point3d] Start point
  # @param vector [Geom::Vector3d] Direction vector
  # @param length [Float] Line length
  # @param entities [Sketchup::Entities] Target entities (nil for model entities)
  def self.add_debug_line(point, vector, length, entities = nil)
    end_point = Geom::Point3d.new(
      point.x + length * vector.x,
      point.y + length * vector.y,
      point.z + length * vector.z
    )
    
    target_entities = entities || Sketchup.active_model.active_entities
    target_entities.add_line(point, end_point)
  end
  
  # Get faces from various entity types
  # @param entity [Object] Entity to process
  # @param matrix [Geom::Transformation] Transformation matrix
  # @param face_list [Array] Array to store face positions
  def self.collect_faces(entity, matrix, face_list)
    return unless entity && face_list
    
    case entity
    when Sketchup::Selection
      entity.each { |ent| collect_faces(ent, matrix, face_list) }
      
    when Sketchup::Face
      face_pos = FacePosition.new
      face_pos.face = entity
      face_pos.matrix = matrix
      face_list.push(face_pos)
      
    when Sketchup::Group
      group_matrix = entity.transformation
      new_matrix = matrix * group_matrix
      entity.entities.each { |ent| collect_faces(ent, new_matrix, face_list) }
      
    when Sketchup::ComponentInstance
      instance_matrix = entity.transformation
      new_matrix = matrix * instance_matrix
      entity.definition.entities.each { |ent| collect_faces(ent, new_matrix, face_list) }
    end
  end
end

# Face position class for geometric calculations
class FacePosition
  attr_accessor :face, :matrix
  
  def initialize
    @face = nil
    @matrix = Geom::Transformation.new
  end
end

# Main module for the Oob extension
module BR_OOB
  
  # Class variables
  @@plugin_dir = OobConfig::PLUGIN_DIR
  @@version = OobConfig::VERSION
  @@strings_table = {}
  
  # Layout parameters
  @@thickness = OobConfig::DEFAULT_THICKNESS
  @@height = OobConfig::DEFAULT_HEIGHT
  @@length = OobConfig::DEFAULT_LENGTH
  @@joint_length = OobConfig::DEFAULT_JOINT_LENGTH
  @@joint_width = OobConfig::DEFAULT_JOINT_WIDTH
  @@joint_depth = OobConfig::DEFAULT_JOINT_DEPTH
  @@row_offset = OobConfig::DEFAULT_ROW_OFFSET
  
  # Multi-value arrays
  @@length_array = []
  @@height_array = []
  @@length_string = ""
  @@height_string = ""
  
  # Random factors
  @@random_length = 0.0
  @@random_height = 0.0
  @@random_thickness = 0.0
  @@random_color = 0.0
  
  # Offsets
  @@layer_offset = 0.0
  @@height_offset = 0.0
  @@length_offset = 0.0
  
  # Other settings
  @@color_list = "Oob-1|Oob-2"
  @@color_name = "Oob-1"
  @@start_point = 1
  @@staggered_joints = false
  @@preset_name = ""
  @@num_random_colors = 10
  
  # Unit conversion utilities
  def self.get_unit_conversion
    unit = Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]
    # 0 = inches, 1 = feet, 2 = mm, 3 = cm, 4 = m
    conversions = [1.0, 12.0, 0.1/2.54, 1.0/2.54, 100.0/2.54]
    return conversions[unit] if unit >= 0 && unit <= 4
    1.0/2.54 # Default to cm
  end
  
  # Set layer for entity
  # @param layer_name [String] Name of the layer
  # @param entity [Object] Entity to assign to layer
  def self.set_layer(layer_name, entity)
    return unless entity && layer_name
    
    model = Sketchup.active_model
    layers = model.layers
    
    new_layer = layers.add(layer_name)
    new_layer.visible = false if layer_name == "Oob-init"
    
    entity.layer = new_layer if entity != model
  rescue => e
    puts "Error setting layer: #{e.message}"
  end
  
  # Load localized strings
  def self.load_strings
    strings_file = Sketchup.find_support_file('files/Strings.arp', @@plugin_dir)
    return unless strings_file && File.exist?(strings_file)
    
    # Determine current language
    resource_path = Sketchup.get_resource_path("")
    current_language = 2 # Default to English
    current_language = 1 if resource_path.include?("/fr")
    
    @@strings_table.clear
    
    File.open(strings_file, "r").each_line do |line|
      parts = line.split(';')
      next if parts.size < 3
      
      key = parts[0]
      value = parts[current_language]
      
      if Sketchup.version.to_f > 13.0
        @@strings_table[key.force_encoding('UTF-8')] = value.force_encoding('UTF-8')
      else
        @@strings_table[key] = value
      end
    end
  rescue => e
    puts "Error loading strings: #{e.message}"
  end
  
  # Get localized string
  # @param key [String] String key
  # @return [String] Localized string or key if not found
  def self.get_string(key)
    return key unless @@strings_table[key]
    
    result = @@strings_table[key]
    
    # Replace unit placeholders
    unit = Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]
    unit_names = ["inches", "feet", "mm", "cm", "m"]
    
    if unit != 3 && unit >= 0 && unit < unit_names.size
      result = result.gsub("cm", unit_names[unit])
    end
    
    result
  end
  
  # Create materials with optional randomization
  # @param color_name [String] Base color name
  # @param random_factor [Float] Randomization factor (0.0-1.0)
  # @param num_colors [Integer] Number of color variations
  # @return [Array<Sketchup::Material>] Array of materials
  def self.create_materials(color_name, random_factor, num_colors)
    materials_array = []
    model = Sketchup.active_model
    materials = model.materials
    
    # Get or create base material
    base_material = materials[color_name]
    
    unless base_material
      # Parse RGB values if color_name is in format "r,g,b" or "r,g,b,a"
      rgb_parts = color_name.split(',')
      if rgb_parts.size >= 3
        red = rgb_parts[0].to_i
        green = rgb_parts[1].to_i
        blue = rgb_parts[2].to_i
        alpha = rgb_parts.size >= 4 ? rgb_parts[3].to_i : 255
        
        color = Sketchup::Color.new(red, green, blue)
        color.alpha = alpha
        
        base_material = materials.add(color_name)
        base_material.color = color
      else
        # Create default gray material
        base_material = materials.add(color_name)
        base_material.color = Sketchup::Color.new(122, 122, 122)
      end
    end
    
    materials_array << base_material
    
    # Create random variations if requested
    if random_factor > 0.0 && num_colors > 1
      base_color = base_material.color
      
      (num_colors - 1).times do |i|
        random_value = (2.0 * rand() - 1.0) # -1.0 to 1.0
        
        new_red = [0, [255, (base_color.red + 128.0 * random_value * random_factor).to_i].min].max
        new_green = [0, [255, (base_color.green + 128.0 * random_value * random_factor).to_i].min].max
        new_blue = [0, [255, (base_color.blue + 128.0 * random_value * random_factor).to_i].min].max
        
        new_color = Sketchup::Color.new(new_red, new_green, new_blue)
        new_color.alpha = base_color.alpha
        
        material_name = "#{color_name}_#{i}"
        new_material = materials[material_name] || materials.add(material_name)
        new_material.color = new_color
        
        # Copy texture if present
        if base_material.texture
          new_material.texture = base_material.texture.filename
          new_material.texture.size = [base_material.texture.width, base_material.texture.height]
        end
        
        materials_array << new_material
      end
    end
    
    materials_array
  rescue => e
    puts "Error creating materials: #{e.message}"
    [base_material].compact
  end
  
  # Get next value from array (supports random selection)
  # @param value_array [Array] Array of values
  # @param index [Integer] Current index
  # @param random_factor [Float] Random factor (0.0 = sequential, 1.0 = random)
  # @return [Array] [value, new_index]
  def self.get_next_value(value_array, index, random_factor)
    return [0.0, 0] if value_array.empty?
    
    if random_factor == 0.0
      # Sequential selection
      index = 0 if index >= value_array.size
      value = value_array[index].to_f
      new_index = index + 1
    else
      # Random selection with bias away from previous
      max_size = value_array.size
      offset = (rand() * (max_size - 1) + 1).to_i
      new_index = (index + offset) % max_size
      value = value_array[new_index].to_f
    end
    
    [value, new_index]
  end
  
  # Add a rectangular face
  # @param pos_x [Float] X position
  # @param pos_y [Float] Y position
  # @param length_x [Float] Width
  # @param length_y [Float] Height
  # @param matrix [Geom::Transformation] Transformation matrix
  # @param entities [Sketchup::Entities] Target entities
  # @return [Sketchup::Face] Created face
  def self.add_face(pos_x, pos_y, length_x, length_y, matrix, entities)
    points = [
      Geom::Point3d.new(pos_x, pos_y, 0),
      Geom::Point3d.new(pos_x + length_x, pos_y, 0),
      Geom::Point3d.new(pos_x + length_x, pos_y + length_y, 0),
      Geom::Point3d.new(pos_x, pos_y + length_y, 0)
    ]
    
    # Transform points
    transformed_points = points.map { |pt| pt.transform(matrix) }
    
    # Create face
    entities.add_face(transformed_points)
  rescue => e
    puts "Error adding face: #{e.message}"
    nil
  end
  
  # Main layout creation function
  # @param face_position [FacePosition] Face and transformation data
  # @param redo_mode [Integer] Whether this is a redo operation
  # @param options [Hash] Layout options
  # @return [Integer] Success flag
  def self.create_layout(face_position, redo_mode = 0, options = {})
    return 0 unless face_position && face_position.face
    
    # Set default options
    options = {
      pattern_rotation: 'horizontal',
      start_from: 'bottom',
      force_full_row: false,
      start_row_height: 'auto',
      last_row_placement: 'cut'
    }.merge(options)
    
    begin
      model = Sketchup.active_model
      
      # Start operation
      model.start_operation(get_string("Create Layout"), true)
      
      # Convert units
      unit_conversion = get_unit_conversion
      
      # Apply unit conversion to parameters
      length = @@length * unit_conversion
      height = @@height * unit_conversion
      thickness = @@thickness * unit_conversion
      joint_length = @@joint_length * unit_conversion
      joint_width = @@joint_width * unit_conversion
      joint_depth = @@joint_depth * unit_conversion
      row_offset = @@row_offset * unit_conversion
      
      # Validate parameters
      if length <= 0 || height <= 0
        UI.messagebox("Invalid dimensions: length and height must be positive")
        model.abort_operation
        return 0
      end
      
      if row_offset > length
        UI.messagebox("Row offset cannot be greater than element length")
        model.abort_operation
        return 0
      end
      
      # Get face properties
      face = face_position.face
      normal = face.normal.transform(face_position.matrix)
      normal.normalize!
      
      # Calculate face bounds and orientation
      vertices = face.vertices
      mean_point = GeometryUtils.get_mean_point(vertices)
      mean_point.transform!(face_position.matrix)
      
      # Determine layout direction
      longest_edge = GeometryUtils.get_longest_edge(face)
      direction_vector = longest_edge ? longest_edge.line[1] : Geom::Vector3d.new(1, 0, 0)
      
      # Handle pattern rotation
      if options[:pattern_rotation] == 'vertical'
        # Rotate direction 90 degrees
        temp_vector = direction_vector.dup
        direction_vector = normal.cross(temp_vector)
      end
      
      # Create coordinate system
      vector_x = direction_vector
      vector_z = normal
      vector_y = vector_z.cross(vector_x)
      
      # Handle start direction
      if options[:start_from] == 'top'
        vector_y.reverse!
      end
      
      # Create transformation matrix
      face_matrix = Geom::Transformation.new(vector_x, vector_y, vector_z, mean_point)
      
      # Calculate layout bounds
      bounds = calculate_layout_bounds(face, face_matrix)
      
      # Estimate element count for safety check
      estimated_count = (bounds[:width] / length) * (bounds[:height] / height)
      if estimated_count > OobConfig::MAX_ELEMENTS
        result = UI.messagebox(
          "Large number of elements (#{estimated_count.to_i}). Continue?",
          MB_YESNO
        )
        if result != 6 # Not Yes
          model.abort_operation
          return 0
        end
      end
      
      # Create materials
      materials = create_materials(@@color_name, @@random_color, @@num_random_colors)
      
      # Create main group
      main_group = model.entities.add_group
      main_group.name = "Oob Layout"
      
      # Generate layout
      success = generate_layout_elements(
        main_group.entities,
        face_matrix,
        bounds,
        length,
        height,
        joint_length,
        joint_width,
        row_offset,
        materials,
        options
      )
      
      if success
        model.commit_operation
        return 1
      else
        model.abort_operation
        return 0
      end
      
    rescue => e
      puts "Error in create_layout: #{e.message}"
      puts e.backtrace
      model.abort_operation if model
      return 0
    end
  end
  
  private
  
  # Calculate layout bounds in face coordinate system
  def self.calculate_layout_bounds(face, face_matrix)
    vertices = face.vertices
    inverse_matrix = face_matrix.inverse
    
    min_x = min_y = Float::INFINITY
    max_x = max_y = -Float::INFINITY
    
    vertices.each do |vertex|
      transformed_point = vertex.position.transform(inverse_matrix)
      
      min_x = [min_x, transformed_point.x].min
      max_x = [max_x, transformed_point.x].max
      min_y = [min_y, transformed_point.y].min
      max_y = [max_y, transformed_point.y].max
    end
    
    {
      min_x: min_x,
      min_y: min_y,
      max_x: max_x,
      max_y: max_y,
      width: max_x - min_x,
      height: max_y - min_y
    }
  end
  
  # Generate the actual layout elements
  def self.generate_layout_elements(entities, face_matrix, bounds, length, height, 
                                   joint_length, joint_width, row_offset, materials, options)
    
    pos_y = bounds[:min_y]
    row_index = 0
    height_index = 0
    first_row = true
    
    # Main layout loop
    while pos_y < bounds[:max_y]
      # Determine row height
      current_height = height
      
      # Handle multi-height arrays
      if !@@height_array.empty?
        current_height, height_index = get_next_value(@@height_array, height_index, @@random_height)
        current_height *= get_unit_conversion
      end
      
      # Apply randomization
      if @@random_height > 0
        random_factor = (2.0 * rand() - 1.0)
        current_height *= (1.0 + random_factor * @@random_height)
      end
      
      # Override height for first row if specified
      if first_row && options[:start_row_height] != 'auto' && !options[:start_row_height].empty?
        current_height = options[:start_row_height].to_f * get_unit_conversion
      end
      first_row = false
      
      # Calculate row offset
      current_offset = (row_index * row_offset) % (length + joint_length)
      pos_x = bounds[:min_x] + current_offset
      length_index = 0
      
      # Generate row elements
      while pos_x < bounds[:max_x]
        # Determine element length
        current_length = length
        
        if !@@length_array.empty?
          current_length, length_index = get_next_value(@@length_array, length_index, @@random_length)
          current_length *= get_unit_conversion
        end
        
        # Apply randomization
        if @@random_length > 0
          random_factor = (2.0 * rand() - 1.0)
          current_length *= (1.0 + random_factor * @@random_length)
        end
        
        # Create element
        face = add_face(pos_x, pos_y, current_length, current_height, face_matrix, entities)
        
        if face
          # Apply material
          material = materials[rand(materials.size)] if materials.size > 1
          material ||= materials.first
          
          face.material = material
          face.back_material = material
        end
        
        pos_x += current_length + joint_length
      end
      
      pos_y += current_height + joint_width
      row_index += 1
    end
    
    true
  rescue => e
    puts "Error generating layout: #{e.message}"
    false
  end
  
  # Display the parameter dialog
  def self.display_dialog(face_position, redo_mode = 0)
    # Load strings first
    load_strings
    
    # Create web dialog
    dialog = UI::WebDialog.new(get_string("Oob : parameters"), false, "OobLayout", 490, 600, 200, 0, true)
    
    # Set dialog file
    html_path = Sketchup.find_support_file('dialogs/OobONE.html', @@plugin_dir)
    dialog.set_file(html_path)
    dialog.set_background_color("ECE9D8")
    
    # Setup callbacks
    setup_dialog_callbacks(dialog, face_position, redo_mode)
    
    # Show dialog
    dialog.show do
      initialize_dialog_values(dialog)
    end
  end
  
  # Setup dialog callbacks
  def self.setup_dialog_callbacks(dialog, face_position, redo_mode)
    # Apply/OK/Cancel callback
    dialog.add_action_callback("calcul") do |web_dialog, message|
      action = message.to_i
      
      case action
      when 1 # Apply
        apply_layout(web_dialog, face_position, redo_mode)
      when 2 # OK
        apply_layout(web_dialog, face_position, redo_mode)
        web_dialog.close
      when 3 # Cancel
        web_dialog.close
      end
    end
    
    # Add other callbacks for presets, etc.
    setup_preset_callbacks(dialog)
  end
  
  # Setup preset-related callbacks
  def self.setup_preset_callbacks(dialog)
    # Save preset callback
    dialog.add_action_callback("savepreset") do |web_dialog, message|
      save_current_preset(web_dialog)
    end
    
    # Load preset callback
    dialog.add_action_callback("selectpreset") do |web_dialog, message|
      load_preset(web_dialog, message)
    end
    
    # Delete preset callback
    dialog.add_action_callback("deletepreset") do |web_dialog, message|
      delete_preset(web_dialog, message)
    end
  end
  
  # Apply layout with current parameters
  def self.apply_layout(dialog, face_position, redo_mode)
    # Get values from dialog
    get_dialog_values(dialog)
    
    # Get advanced options
    options = {
      pattern_rotation: dialog.get_element_value("patternRotation") || 'horizontal',
      start_from: dialog.get_element_value("startFrom") || 'bottom',
      force_full_row: dialog.get_element_value("forceFullRow") == 'true',
      start_row_height: dialog.get_element_value("startRowHeight") || 'auto',
      last_row_placement: dialog.get_element_value("lastRowPlacement") || 'cut'
    }
    
    # Create layout
    result = create_layout(face_position, redo_mode, options)
    
    if result == 0
      UI.messagebox("Layout creation failed. Please check your parameters.")
    end
  end
  
  # Get values from dialog
  def self.get_dialog_values(dialog)
    @@length = dialog.get_element_value("input2").to_f
    @@height = dialog.get_element_value("input3").to_f
    @@thickness = -dialog.get_element_value("input4").to_f
    @@joint_length = dialog.get_element_value("input5").to_f
    @@joint_width = dialog.get_element_value("input6").to_f
    @@joint_depth = dialog.get_element_value("input7").to_f
    @@row_offset = dialog.get_element_value("input8").to_f
    @@color_name = dialog.get_element_value("input9").to_s
    
    # Random factors
    @@random_length = [0.0, [1.0, dialog.get_element_value("inputrand2").to_f].min].max
    @@random_height = [0.0, [1.0, dialog.get_element_value("inputrand3").to_f].min].max
    @@random_thickness = [0.0, [1.0, dialog.get_element_value("inputrand4").to_f].min].max
    @@random_color = [0.0, [1.0, dialog.get_element_value("inputrand5").to_f].min].max
    
    # Offsets
    @@layer_offset = dialog.get_element_value("inputlayeroffset").to_f
    @@height_offset = dialog.get_element_value("inputheightoffset").to_f
    @@length_offset = dialog.get_element_value("inputlengthoffset").to_f
    
    # Other settings
    @@start_point = dialog.get_element_value("inputstartpoint").to_i
    @@staggered_joints = dialog.get_element_value("input10").to_s == "true"
    
    # Handle multi-value arrays
    parse_multi_values(dialog)
  end
  
  # Parse multi-value strings into arrays
  def self.parse_multi_values(dialog)
    # Length values
    length_string = dialog.get_element_value("input2").to_s
    if length_string.include?(';')
      @@length_array = length_string.split(';').map(&:to_f)
      @@length = @@length_array.first
    else
      @@length_array = []
    end
    
    # Height values
    height_string = dialog.get_element_value("input3").to_s
    if height_string.include?(';')
      @@height_array = height_string.split(';').map(&:to_f)
      @@height = @@height_array.first
    else
      @@height_array = []
    end
  end
  
  # Initialize dialog with current values
  def self.initialize_dialog_values(dialog)
    # Set labels
    dialog.execute_script("setLabel('label2;#{get_string("Length (cm)")}')")
    dialog.execute_script("setLabel('label3;#{get_string("Height(cm)")}')")
    dialog.execute_script("setLabel('label4;#{get_string("Thickness (cm)")}')")
    
    # Set values
    dialog.execute_script("setValue('input2;#{@@length}')")
    dialog.execute_script("setValue('input3;#{@@height}')")
    dialog.execute_script("setValue('input4;#{@@thickness}')")
    dialog.execute_script("setValue('input5;#{@@joint_length}')")
    dialog.execute_script("setValue('input6;#{@@joint_width}')")
    dialog.execute_script("setValue('input7;#{@@joint_depth}')")
    dialog.execute_script("setValue('input8;#{@@row_offset}')")
    dialog.execute_script("setValue('input9;#{@@color_name}')")
    
    # Load presets
    load_preset_list(dialog)
  end
  
  # Load preset list into dialog
  def self.load_preset_list(dialog)
    preset_dir = File.join(Sketchup.find_support_file('Plugins'), 'Oob-layouts', 'presets')
    return unless File.directory?(preset_dir)
    
    Dir.glob(File.join(preset_dir, '*.oob')).each do |file|
      preset_name = File.basename(file, '.oob')
      dialog.execute_script("addPresetOption('#{preset_name}')")
    end
  end
  
  # Save current settings as preset
  def self.save_current_preset(dialog)
    result = UI.inputbox(["Preset name:"], [""], "Save Preset")
    return unless result
    
    preset_name = result[0]
    return if preset_name.empty?
    
    preset_dir = File.join(Sketchup.find_support_file('Plugins'), 'Oob-layouts', 'presets')
    Dir.mkdir(preset_dir) unless File.directory?(preset_dir)
    
    preset_file = File.join(preset_dir, "#{preset_name}.oob")
    
    File.open(preset_file, 'w') do |file|
      file.puts "Oob preset parameters;#{preset_name};"
      file.puts "@@length;#{dialog.get_element_value('input2')};"
      file.puts "@@height;#{dialog.get_element_value('input3')};"
      file.puts "@@thickness;#{dialog.get_element_value('input4')};"
      file.puts "@@joint_length;#{dialog.get_element_value('input5')};"
      file.puts "@@joint_width;#{dialog.get_element_value('input6')};"
      file.puts "@@joint_depth;#{dialog.get_element_value('input7')};"
      file.puts "@@row_offset;#{dialog.get_element_value('input8')};"
      file.puts "@@color_name;#{dialog.get_element_value('input9')};"
      file.puts "@@random_length;#{dialog.get_element_value('inputrand2')};"
      file.puts "@@random_height;#{dialog.get_element_value('inputrand3')};"
      file.puts "@@random_thickness;#{dialog.get_element_value('inputrand4')};"
      file.puts "@@random_color;#{dialog.get_element_value('inputrand5')};"
    end
    
    dialog.execute_script("addPresetOption('#{preset_name}')")
    UI.messagebox("Preset '#{preset_name}' saved successfully!")
  end
  
  # Load preset from file
  def self.load_preset(dialog, preset_name)
    preset_file = File.join(
      Sketchup.find_support_file('Plugins'), 
      'Oob-layouts', 
      'presets', 
      "#{preset_name}.oob"
    )
    
    return unless File.exist?(preset_file)
    
    unit_conversion = get_unit_conversion
    
    File.open(preset_file, 'r').each_line do |line|
      parts = line.split(';')
      next if parts.size < 2
      
      key = parts[0]
      value = parts[1]
      
      case key
      when "@@length"
        dialog.execute_script("setValue('input2;#{value.to_f * unit_conversion}')")
      when "@@height"
        dialog.execute_script("setValue('input3;#{value.to_f * unit_conversion}')")
      when "@@thickness"
        dialog.execute_script("setValue('input4;#{value.to_f * unit_conversion}')")
      when "@@joint_length"
        dialog.execute_script("setValue('input5;#{value.to_f * unit_conversion}')")
      when "@@joint_width"
        dialog.execute_script("setValue('input6;#{value.to_f * unit_conversion}')")
      when "@@joint_depth"
        dialog.execute_script("setValue('input7;#{value.to_f * unit_conversion}')")
      when "@@row_offset"
        dialog.execute_script("setValue('input8;#{value.to_f * unit_conversion}')")
      when "@@color_name"
        dialog.execute_script("setValue('input9;#{value}')")
      when "@@random_length"
        dialog.execute_script("setValue('inputrand2;#{value}')")
      when "@@random_height"
        dialog.execute_script("setValue('inputrand3;#{value}')")
      when "@@random_thickness"
        dialog.execute_script("setValue('inputrand4;#{value}')")
      when "@@random_color"
        dialog.execute_script("setValue('inputrand5;#{value}')")
      end
    end
    
    dialog.execute_script("compute()")
  end
  
  # Delete preset
  def self.delete_preset(dialog, preset_name)
    result = UI.messagebox("Delete preset '#{preset_name}'?", MB_YESNO)
    return unless result == 6 # Yes
    
    preset_file = File.join(
      Sketchup.find_support_file('Plugins'), 
      'Oob-layouts', 
      'presets', 
      "#{preset_name}.oob"
    )
    
    if File.exist?(preset_file)
      File.delete(preset_file)
      dialog.execute_script("clearPresetOption()")
      load_preset_list(dialog)
      UI.messagebox("Preset deleted successfully!")
    else
      UI.messagebox("Preset file not found!")
    end
  end
  
end # module BR_OOB

# Initialize the extension
if defined?(Sketchup)
  # Load strings on startup
  BR_OOB.load_strings
  
  # Add menu items
  unless file_loaded?(__FILE__)
    menu = UI.menu("Plugins")
    menu.add_item("Oob Layouts Enhanced") {
      selection = Sketchup.active_model.selection
      
      if selection.empty?
        UI.messagebox("Please select a face to apply the layout to.")
        return
      end
      
      # Find first face in selection
      face = nil
      matrix = Geom::Transformation.new
      
      selection.each do |entity|
        if entity.is_a?(Sketchup::Face)
          face = entity
          break
        end
      end
      
      unless face
        UI.messagebox("Please select a face to apply the layout to.")
        return
      end
      
      # Create face position object
      face_position = FacePosition.new
      face_position.face = face
      face_position.matrix = matrix
      
      # Display dialog
      BR_OOB.display_dialog(face_position)
    }
    
    file_loaded(__FILE__)
  end
end