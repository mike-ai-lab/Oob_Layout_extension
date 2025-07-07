# Copyright (c) 2015 Oob
# Load the scrambled file

# File my_licensedrubyextension/loader.rb:
# ----------------------------------------
module OobLayoutsModule
	
	def self.execute
		UI.toolbar("Oob").show
	end

	version = Sketchup.version
	UI.menu('Extensions').add_item('Oob layouts licensed') { self.execute() }
end # module MyModule::MyLicensedRubyExtension

Sketchup.require("Oob-layouts/Oob")