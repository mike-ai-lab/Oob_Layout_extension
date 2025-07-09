# Oob Layouts Dialog Loader

module OobLayoutsModule

  def self.execute
    # Load dialog
    html_path = File.join(__dir__, "dialogs", "OobONE.html")
    unless File.exist?(html_path)
      UI.messagebox("❌ Missing: dialogs/OobONE.html")
      return
    end

    @dialogOobOne = UI::HtmlDialog.new({
      :dialog_title => "Oob Layouts",
      :preferences_key => "com.oob.layouts",
      :scrollable => true,
      :resizable => true,
      :width => 600,
      :height => 850,
      :style => UI::HtmlDialog::STYLE_DIALOG
    })

    @dialogOobOne.set_file("C:/Users/mshke/AppData/Roaming/SketchUp/SketchUp 2025/SketchUp/Plugins/Oob-layouts/dialogs/OobONE.html")
(html_path)

    # === Callback: deletepreset ===
    @dialogOobOne.add_action_callback("deletepreset") do |js_wd, message|
      rep = UI.messagebox(BR_OOB.getString("Delete preset") + " : " + message + " ?", MB_YESNO)
      if rep == 6
        presetfilename = Sketchup.find_support_file(message + '.oob', @@OOBpluginRep + '/presets')
        if !File.exist?(presetfilename)
          UI.messagebox("Error, file not found!")
        else
          puts "deleting preset"
          File.delete(presetfilename)
          UI.messagebox(BR_OOB.getString("Preset has been deleted"))
          @dialogOobOne.execute_script('clearPresetOption();')
          presetsfiles = Dir[Sketchup.find_support_file('Plugins') + '/Oob-layouts/presets/*.oob']
          presetsfiles.each do |file|
            @dialogOobOne.execute_script('addPresetOption("' + File.basename(file, ".oob") + '");')
          end
        end
      end
    end

    # === Callback: savepreset ===
    @dialogOobOne.add_action_callback("savepreset") do |js_wd, message|
      prompts = [BR_OOB.getString("Nom du preset")]
      values = [""]
      enums = [nil]
      results = inputbox(prompts, values, enums, "Give a name to preset")
      next unless results

      presetsfiles = Dir[Sketchup.find_support_file('Plugins') + '/Oob-layouts/presets/*.oob']
      fullname = File.dirname(presetsfiles[0]) + "/" + results[0] + ".oob"

      radiovalue = @dialogOobOne.get_element_value("inputradiohidden").to_s

      File.open(fullname, 'w') do |file|
        # TODO: write parameters here
      end

      @dialogOobOne.execute_script('addPresetOption("' + results[0].to_s + '");')
    end

    # === Callback: selectpreset ===
    @dialogOobOne.add_action_callback("selectpreset") do |js_wd, message|
      puts "selectpreset #{message}"
      presetfilename = Sketchup.find_support_file(message + '.oob', @@OOBpluginRep + '/presets')
      if File.exist?(presetfilename)
        UI.messagebox("Error, file not found!")
      end
      @dialogOobOne.execute_script('compute();')
    end

    # === Callback: calcul ===
    @dialogOobOne.add_action_callback("calcul") do |js_wd, message|
      if message.to_i == 2
        @dialogOobOne.close
      elsif message.to_i == 3
        if @computationDone == 1
          rep = UI.messagebox(BR_OOB.getString("Annuler l'opération?"), MB_YESNO)
          Sketchup.undo if rep == 6
        end
        @dialogOobOne.close
      else
        # Main calculation logic would go here
      end
    end

    # === Callback: applybardage ===
    @dialogOobOne.add_action_callback("applybardage") do |js_wd, message|
      @layout_direction = message
      puts "[OOB] Layout direction set to: #{@layout_direction}"
    end

    @dialogOobOne.show
  end

  version = Sketchup.version
  UI.menu('Extensions').add_item('Oob Layouts Licensed') { self.execute }

end

load File.join(__dir__, "Oob.rb")
