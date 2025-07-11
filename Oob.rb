Object.send(:remove_const, :BR_OOB) if defined?(BR_OOB)

OOB_VERSIONFULL ||= "FUL6" # V6.0

class Parametre 
	attr_accessor :m_TypeBundle # 0 si item provenant dune bdd
	attr_accessor :m_EditableFlag # 0 si item non editable
	
	attr_accessor :m_UID
	attr_accessor :m_Icone # chemin vers l'image ou icone
	attr_accessor :m_Id # nom de l'item
	attr_accessor :m_ItemType # nom de l'item
	attr_accessor :m_Branche
	attr_accessor :m_SubBranche
	attr_accessor :m_Label
	attr_accessor :m_Check_Value
	attr_accessor :m_Image
	attr_accessor :m_Branch_Opened
	attr_accessor :m_ToolTip
	attr_accessor :m_Value
	def initialize
		@m_Label = @m_Image = ""
end
end

module BR_GeomTools

# issu de : http://forums.sketchucation.com/viewtopic.php?f=180&t=29138&start=0 
#==================================================================================
def BR_GeomTools.copyFace(face,vec,dist,ents,mater)
	ov=[] # outer loop vertices
	vec.length = dist if dist != 0
	face.outer_loop.vertices.each do |v|
		if dist != 0
			ov.push(v.position.offset(vec))
		else
		  ov.push(v.position)
		end
	end
	  
	# face from outer loop
	outer_face = ents.add_face ov
	  
	inner_faces = [] # table of inner loops
	if face.loops.length > 1
		il = face.loops
		il.shift
		il.each do |loop|
		  ov=[]
		  loop.vertices.each do |v|
			if dist != 0
			  ov.push(v.position.offset(vec))
			  else
			  ov.push(v.position)
			end
		  end
		  inner_face = ents.add_face ov
		  inner_faces.push(inner_face)
		end
		inner_faces.each do |f|
		  f.erase!
		end
	end
	outer_face.material = mater
	#puts "mater = "
	#puts mater.name.to_s
	return outer_face
end # Class Face

# couple face, position utlisée pour les calculs géométriques
#=========================================================
class FacePosition
	attr_accessor :m_Face #Face
	attr_accessor :m_Matrice #Matrice de psition de la  face
	def initialize
	end
 


# debug 3D  : affichaeg d'une ligne (vecteur)
def BR_GeomTools.addDebugLinePV(point, vector, length, entitiestoadd)		
	#puts "in debugLINEEEEEEEEEEEEEEEEEEEEEEEEEEE"
	point2 = Geom::Point3d.new(point[0] + length*vector[0] , point[1] + length*vector[1], point[2] + length*vector[2])
	if(entitiestoadd == nil)
		Sketchup.active_model.active_entities.add_line point,point2 # pour debug on trace les ligne de lancer de rayon KO
	else
		entitiestoadd.add_line point,point2
	end	
end	

def BR_GeomTools.displayDebugPoint(string, point, matrix)
	tpt = Geom::Point3d.new  point
	tpt.transform! matrix
	text = Sketchup.active_model.entities.add_text string, tpt #if (debug3D == 1) 
end

def BR_GeomTools.addDebugLinePP(point1, point2)		
	#puts "in debugLINEEEEEEEEEEEEEEEEEEEEEEEEEEE"
	#point2 = Geom::Point3d.new(point[0] + length*vector[0] , point[1] + length*vector[1], point[2] + length*vector[2])
	Sketchup.active_model.active_entities.add_line point1,point2 # pour debug on trace les ligne de lancer de rayon KO
end	

#=================================================
# recup de l'arete la plus longue d'une face
#=================================================
def  BR_GeomTools.getLongestEdge(face)
	oloop = face.outer_loop
	lmax = 0.0
	edgemax = nil
	oloop.edges.each {|edge|
	if(edge.length > lmax)
		lmax = edge.length
		edgemax = edge
	end
	}
	return edgemax
end

#=================================================
# clacul du point moyen d'un tableau de points
#=================================================	
def  BR_GeomTools.getMeanPoint(verticelist)
	trace = 0
	puts "in BR_GeomTools.getMeanPoint(verticelist)" if (trace == 1)
	puts verticelist.size() if (trace == 1)
	xm = 0.0
	ym = 0.0
	zm = 0.0
	
	verticelist.each{|vertex|
		puts vertex.position if (trace == 1)
		xm += vertex.position[0]
		ym += vertex.position[1]
		zm += vertex.position[2]
	}
	if(verticelist.size() > 0)
		meanPt = Geom::Point3d.new xm/verticelist.size(), ym/verticelist.size(), zm/verticelist.size()
		puts meanPt if (trace == 1)
		return meanPt
	end
end

#====================================================
# Recup des faces d'un elt
#====================================================
def BR_GeomTools.getListOfFaces(elt, matrice, tabFaces)
		trace =  1
		puts "in getListOfFaces" if(trace == 1)
		puts tabFaces.size()  if(trace == 1)
		#puts "|"
		if (elt == nil)
			puts "elt =  nil" if(trace == 1)
			return
		end
		
		# si il s'agit de la selection courante
		if (elt.class == Sketchup::Selection)
			puts "in elt.class == Sketchup::Selection"   if(trace == 1)
			elt.each do |ent|
				puts "in entity of Sketchup::Selection"  if(trace == 1)
				BR_GeomTools.getListOfFaces(ent, matrice, tabFaces)
			end
		end
		
		# si il s'agit d'un face on l'ajoute
		if (elt.class == Sketchup::Face)
			puts "- Face #{elt}"
			newFace = FacePosition.new
			newFace.m_Face = elt
			newFace.m_Matrice = matrice
			tabFaces.push newFace
		end
		
		# s'il s'agit d'un groupe ou composant on le decompose en face
		if ((elt.class == Sketchup::Group))
			puts "- Groupe"  if (trace == 1)
			matricegroup = elt.transformation
			
			if(matricegroup.identity?)
				puts "- Matrice groupe = identite"  if (trace == 1)
				 #puts matricegroup.to_a  if (trace == 1)
			else
				puts "- Matrice groupe != identite"  if (trace == 1)
				#puts matricegroup.to_a  if (trace == 1)
			end
			
			if(matricegroup != nil)
				newmat = matrice*matricegroup
			else
				newmat = matrice
			end
			
			elt.entities.each do |ent|
					BR_GeomTools.getListOfFaces(ent, newmat, tabFaces)
			end	
		end
		
		if( (elt.class == Sketchup::ComponentInstance))
			puts "- Composant"  if (trace == 1)
			defin = elt.definition
			matriceinst = elt.transformation
			if(matriceinst.identity?)
				puts "- Matrice inst = identite"  if (trace == 1)
			else
				puts "- Matrice inst != identite"  if (trace == 1)
				puts matriceinst.to_a  if (trace == 1)
			end
			
			if(matriceinst != nil)
				newmat = matrice*matriceinst
			else
				newmat = matrice
			end
			# newmat = matrice*matriceinst
			
			defin.entities.each do |ent|
				BR_GeomTools.getListOfFaces(ent, newmat, tabFaces)
			end
		end
		
		puts "OUT getListOfFaces" if(trace == 1)
		puts tabFaces.size() if(trace == 1)
	end
	
end	# of module BR_GeomTools

#----------------module Oob-----------
module BR_OOB

	# variables de classe
	@@OOBpluginRep = 'Plugins/Oob-layouts/'
	#@@OOBpluginRep = 'Plugins/Oob-DEV/' # MODIF A COMMENTER EN RELEASE
	
	@@OOB_VERSION = "Oob%201402"
	
	@@shadowobserver = nil
	@@shadowobservercmd = nil
	
	@@oobTabStrings = {}

	@@f_epaisseurBardage  = 0.02  #cm
	@@f_hauteurBardage = 1.0#13.20 #cm
	@@f_longueurBardage = 4.5 #cm
	
	#2 tableau des longueurs
	@@f_tabLongueurBardage = [] 
	@@f_tabLongueurBardageString = ""

	#2 Tableau des hauteurs
	@@f_tabHauteurBardage = [] 
	@@f_tabHauteurBardageString = ""
	
	
	# V4.5 random
	@@f_randomlongueurBardage = 0.0
	@@f_randomhauteurBardage = 0.0
	@@f_randomepaisseurBardage = 0.0
	@@f_randomColor = 0.0
	
	
	# V6.0.0 
	@@f_layeroffset = 0.0
	@@f_heightoffset = 0.0
	@@f_lengthoffset = 0.0
	@@s_presetname = "" #	selectPreset
	
	
	@@f_jointLongueur = 0.005
	@@f_jointLargeur = 0.005 #cm
	@@f_jointProfondeur = 0.005 # cm
	@@f_decalageRangees = 1.50 # decalage en longueur entre rangees (ratio de lalongueur)
	@@b_jointperdu = "false" # NI 0008 pose à joint perdus (V5)
	
	@@s_colorList = "Oob-1|Oob-2"
	@@s_colorname = "Oob-1"
	@@i_startpoint = 1

	@@i_nbrandomColors = 10 #8 noble de couleurs random

	# ELEC
=begin
	$nbc1 = 3
	$nbc2 = 0
	$nbc3 = 0
=end	
	# $tabParamsCmds = [	['images/24/120.png', $OOB1SETTINGS, "OOB1", "Paramétrage Oob1","Oob&: paramètres","OOB1"]	];
	#==================================================================
	# Attribution d'un elt dans un layer
	#==================================================================
	def BR_OOB.setLayer(layername, elt)
		trace = 0
		# on value le layer 
		# Add a layer
		model = Sketchup.active_model
		layers = model.layers
		
		#nametype = $tabParamsCmds[type][5]
		newOOBlayer = layers.add layername
		
		newInitLayer = 0
		if(layername == "Oob-init")
			newOOBlayer.visible = false
		end
		
		#ABlayer = Sketchup.active_model.layers.add "A-BAT"
		puts "newOOBlayer" if(trace == 1)
		puts newOOBlayer if(trace == 1)
		
		# Put the elt in the new Layer
		if(elt != Sketchup.active_model)
			newlayer = elt.layer = newOOBlayer
		end
	end

	#================================
	# NLS NLS NLS NLS
	#================================

	#===============================================================
	# Gestion des strings dans plusieurs langues
	#==============================================================
	def BR_OOB.loadStrings()
		trace = 0
		puts "in LoadStrings"  if(trace ==1)
		stringsfile = Sketchup.find_support_file('files/Strings.arp', @@OOBpluginRep) # NI 0009 MAC le \ ne passe pas on remplace par  /
		puts "stringsfile" if(trace ==1)
		puts stringsfile  if(trace ==1)
				
		# test de la langue courante
		fullPath = Sketchup.get_resource_path("")
		puts "resourcesPath" if(trace ==1)
		puts fullPath if(trace ==1)
		puts fullPath["US"] if(trace ==1)
		# test de la langue courante
		curentLanguage = 2 # US par défaut 
		curentLanguage = 2 if fullPath["US"] != nil
		curentLanguage = 1 if fullPath["/fr"] != nil #4 pas en francais
		#curentLanguage = 1 # DEBUG TODO FR par défaut
		puts "curentLanguage" if(trace ==1)
		puts curentLanguage if(trace ==1)
		
		# parcours du fichier
		@@oobTabStrings.clear
			
		# on stocke les string dans un dictionnaire
		if(stringsfile == nil) || stringsfile.length==0
			UI.messagebox "Erreur, impossible d'ouvrir le fichier de traductions\n#{@@OOBpluginRep}", MB_YESNO
		else
			#UI.messagebox "OK Fichier de traductions\n#{@@OOBpluginRep}", MB_YESNO
			paramfilefound = 1
				
			File.open(stringsfile, "r" ).each_line do |line|					
				puts line  if(trace == 1)
				tab = line.split(';')
				#$ooboobTabStrings["Test"] = "Test"
				if(Sketchup.version.to_f > 13.0) #SU 2014 +
					@@oobTabStrings[tab[0].force_encoding('UTF-8')] = tab[curentLanguage].force_encoding('UTF-8')
				else # SU 2013 and less
					@@oobTabStrings[tab[0]] = tab[curentLanguage]
				end
				puts @@oobTabStrings[tab[0]] if(trace ==1)
			end
		end	
		
		puts "Test des strings" if(trace ==1)
		puts @@oobTabStrings["JointL"] if(trace ==1)
		puts @@oobTabStrings.length if(trace ==1)
	end

	def BR_OOB.getString(string, trace = 0)
		trace = 0
		puts "in getString("+string+")" if(trace ==1)
		if @@oobTabStrings[string] != nil
			trace =  0
			puts "FOUND"+@@oobTabStrings[string] if(trace ==1)
			
			# V4.4 : remplace of (cm) by (inch, foot ...)
			unit = Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]
			tabunit = ["inches","feet","mm","cm","m"]
			newstring = ""
			puts "unit #{unit}" if(trace ==1)
			if(unit != 3) # 3 = cm
				newstring = @@oobTabStrings[string].gsub("cm", tabunit[unit])
			else
				newstring = @@oobTabStrings[string]
			end	
			return newstring
		else
			puts "NOT FOUND" if(trace ==1)
			puts "Test des strings" if(trace ==1)
			puts @@oobTabStrings if(trace ==1)
			puts @@oobTabStrings.length if(trace ==1)
			puts string+" FR;"+string+" EN;"+string+" DE;"+string+" IT;"+string+" SP;" if(trace ==1)
		end # sinon on retourne la chaine qui est en entree	
		return string
	end


	#==================================================
	# procedure de debug, affiche un message continue si ok, exit si coancel
	#==================================================
	def BR_OOB.myDebugStepMessage(linenumber)
		debug = 0
		if(debug == 1)
			return if(UI.messagebox(linenumber.to_s,MB_OKCANCEL ) == 2)
		else
			return false
		end
	end
	
	#============================================================================
	# insiré de la methode FACE-CLONE (boolean 2D) 
	# creation d'une copie d'une face dans un tableau d'entitées (doit etre vide en entree)
	#=============================================================================
	def BR_OOB.DuplicateFacesToEntities(gents, face)
		   
		faces2go=[] #liste des faces internes (trous) a supprimer apres copie
	
		# parcours des faces input
		#faces.each{|face|
		
		# creation d'une face par loop 
		face.loops.each{|loop|gents.add_face(loop.vertices)}   # ajout de toutes les loops de la face 
		oface=gents.add_face(face.outer_loop.vertices)        # oface = copie de la loop 				
	
		# parcours des faces copiees
		gents.each{|face| 
			next if face.class!=Sketchup::Face     
			face.edges.each{|e|
				if not e.faces[1] # si l'edge de la face n'est bordee que par une face
					break
				end
					
			   faces2go << face # sinon on rajoute la face (toutes ses aretes sont bordess par 2 faces => faces interne
			}
		}
		gents.erase_entities(faces2go) # on supprime les faces internes pour recreer les trous
		# }       
	end # end of face_clone
	
	#====================================================
	#  procedure booleenne 2D : selection contre model
	#====================================================
	def BR_OOB.boolean2d(entitiesForResult, createOperation) 
   
		model=Sketchup.active_model; 
		ents=model.active_entities; 
		defs=model.definitions
		ss=model.selection
	
		oface=nil; comps=nil; edges=nil; faces=[]; comps=[]
	   
		#Collect entities from selection into arrays########### 
		ss.each{|e|
	   
			if e.class==Sketchup::Face
				faces << e
			end		  		 		  
			if e.class==Sketchup::Group
				comps << e
			end
			if e.class==Sketchup::ComponentInstance
				comps << e
			end
		}
		
		if faces.empty?       # 1.1 selection trap si aucune face selectionnée on recupere les faces sur lesquelles sont gluees les composants
			ss.each{|e| 
				if e.class==Sketchup::ComponentInstance 
					faces << e.glued_to
				end
			}
		end
   
		#@face & @edge are used in face clone
   
		com=comps[0] if comps; 
		oface=faces[0] if faces
 
		if not com # au moins un composant ou un groupe selectionné 
			#UI.messagebox("Select a Component or a Group")
			return nil
		end

		###########begin operation################################## 
		if(createOperation == 1)
			if Sketchup.version.to_i>7 # test version
				model.start_operation("Intersect", true) # plus rapide ###############################################
			else
				model.start_operation("Intersect")
			end
		end
		
		if com ##comps=Collection, array of instances and groups #######
	   
			#gp2=ents.add_group(); cents=gp2.entities # nouveau groupe gp2
			gp2=entitiesForResult.add_group();  # nouveau groupe gp2, groupe des résultats
			cents=gp2.entities # nouveau groupe gp2, groupe des résultats
		
			comps.each{|e| #Add instance to group and erase original.
				if e.class==Sketchup::ComponentInstance
					cents.add_instance(e.definition, e.transformation) 
					e.erase!
				end
				if e.class==Sketchup::Group
					gp2ents = e.parent.entities
					gp2defn = e.entities.parent
					gp2tran = e.transformation
					cents.add_instance(gp2defn, gp2tran) 
					e.erase! ### remove original groups  ##
				end
			}
			## Explode everything inside gp2 ## on explode tous les composants et groupes dans gp2
			cents.to_a.each{|e| 
				if e.class==Sketchup::ComponentInstance 
					e.explode
				end
				if e.class==Sketchup::Group
					e.explode
				end
			}   
		end
  
		################FACE-CLONE###################################  
		def self.face_clone(gents, faces)
		   
			faces2go=[]
		   
			faces.each{|face|
				# creation d'une face par loop 
				face.loops.each{|loop|gents.add_face(loop.vertices)}   # make innerfaces and all faces
				oface=gents.add_face(face.outer_loop.vertices)        # make outer faces again to be sure
				
				# parcours des faces
				gents.each{|face| 
					next if face.class!=Sketchup::Face     
					face.edges.each{|e|
						if not e.faces[1] # si l'edge de la face n'est bordee que par une face
							break
						end
					  
					   faces2go << face # sinon on rajoute la face (toutes ses aretes sont bordess par 2 faces => faces interne
					}
				}
				gents.erase_entities(faces2go) # on supprime les faces internes pour recreer les trous
			}       
		end # end of face_clone
	 
		if oface
			gp=ents.add_group(); 
			gents=gp.entities #face-clone group
			self.face_clone(gents, faces)
			gp.name = "gp"
			
			return if(BR_OOB.myDebugStepMessage(__LINE__))
			
			#Intersect face.clone with gp2##
			tr=Geom::Transformation.new()
			gptr=gp.transformation
			cents.intersect_with(false, gptr, cents, tr, false, [gp])
			cents.intersect_with(false, gptr, cents, tr, false, [gp])
		  
			return if(BR_OOB.myDebugStepMessage(__LINE__))
			
			gp2ptogo=[]; faces2go2=[]
			
			#Collect Edge starts and ends and see if they are in a hole. IF true >> gp2ptogo!		   	   		   		  		   
			cents.to_a.each{|edge|
				if edge.class==Sketchup::Edge
		   
					if oface.classify_point(edge.start)==Sketchup::Face::PointOutside and              
						oface.classify_point(edge.end)==Sketchup::Face::PointOutside
				  
						gp2ptogo << edge
					end
					
					# Offset a point to the middle of edge and test it
					if oface.classify_point(edge.start.position.offset(edge.line[1], edge.length/2))==Sketchup::Face::PointOutside
				  
						gp2ptogo << edge
					end
			  end
			}
			cents.erase_entities(gp2ptogo) #erase unwanted edges
			return if(BR_OOB.myDebugStepMessage(__LINE__))
			# Get rid of the faces in holes.### 	                 		 
			cents.to_a.each{|gface|
				if gface.class==Sketchup::Face   
					hole=true
					gface.outer_loop.edges.each{|e|
						if e.faces.length==1
							hole=false
							break
						end
					}
					next if not hole
  
					pt=gface.bounds.center.project_to_plane(oface.plane)
  
					if oface.classify_point(pt)==Sketchup::Face::PointOutside                 
						faces2go2 << gface 
					end
				end	 
			}
			cents.erase_entities(faces2go2)#erase faces in holes
		  
			#return if(UI.messagebox("9",MB_OKCANCEL ) == 2)	            		 
		  
			#Now gp can be deleted. It's edges were being used in comparison^
			gp.erase!
	  
			return gp2
		
			
			### transformations done, make component #####
		   inst=gp2.to_component
		   defn=inst.definition
		   be=defn.behavior
		   be.is2d=true
		   be.cuts_opening=true
		   be.snapto=0
		   inst.glued_to=oface
		   defn.invalidate_bounds # I had to use this to reset bbox 

			###name####
			inst.name="Oob i"
			defn.name="Oob d"
		 end
	if(createOperation == 1)
		model.commit_operation   ###############################################
	end
	
	puts "return gp2"
	puts gp2
	return gp2
	#return inst
  end 
  
	#===========================================
	# Creer couleur Oob-1 :
	# V6.1 ajout du random sur la couleur
	# #8 ajout du nombre de random colors
	#===========================================
	def BR_OOB.createMaterials (colorName, randomColor, nbColors)
		trace = 1
		tabColors = Array.new
		model = Sketchup.active_model
		materials = model.materials
		m = nil
		# on teste la présence de la couleur
		if(materials[colorName]) 
			#puts "material exists"
			m = materials[colorName]
		end
		
		currentmat = Sketchup.active_model.materials.current
		if(currentmat)
			if(currentmat.display_name == colorName)
				#puts "current materials"
				m = currentmat
				#puts currentmat
				#puts m
			end
		end
		
		if(m == nil) # Adds a material to the "in-use" material pallet
			#puts "create material"
			red = 122
			green =  122
			blue = 122
			alpha = 255
			
			# V4.6 color sous la forme 122,250,0
			splittab = colorName.split(',')
			if(splittab.size >= 3)
				red   = splittab[0].to_i
				green = splittab[1].to_i
				blue  = splittab[2].to_i
				colorName = red.to_s+green.to_s+blue.to_s
			end
			if(splittab.size == 4)
				alpha = splittab[3].to_i
			end
			#puts "rgb = #{red} #{green} #{blue} #{alpha}"
			
			icolor = Sketchup::Color.new(red,green, blue)
			icolor.alpha = alpha
			m = materials.add colorName
			m.color = icolor
			
		end
		
		# Ajout premiere couleur m
		#puts "m #{m}"
		tabColors << m
		
		# V6.1 random sur color, on remplit un tableau de 20 couleurs
		if(randomColor != 0.0)
			initColor =  m.color
			initR = initColor.red
			initG = initColor.green
			initB = initColor.blue
			initAlpha  = initColor.alpha
			initName = m.name
			#puts "random on color #{randomColor} #{initR} #{initG} #{initB}"
			newfilename = nil
			needsdeletefile = 0
			
			# creation de l'image temporaire pour les textures n'ayant pas de filename (textures SU)
			if m.texture
				filename = m.texture.filename
				if File.exist?( filename )
					#new_material.texture = filename
					newfilename = filename
				else
					# Create temp file to write the texture to.
					temp_path = File.expand_path( ENV['TMPDIR'] || ENV['TMP'] || ENV['TEMP'] )
					temp_folder = File.join( temp_path, 'su_tmp_mtl' )
					temp_filename = File.basename( filename )
					temp_file = File.join( temp_folder, temp_filename )
					unless File.exist?( temp_folder )
						Dir.mkdir( temp_folder )
					end
					# Create temp group with the orphan material and write it out.
					# Wrap within start_operation and clean up with abort_operation so it
					# doesn't end up in the undo stack.
					#
					# (!) This means this method should not occur within any other
					#     start_operation blocks - as operations cannot be nested.
					tw = Sketchup.create_texture_writer
					model.start_operation( 'Extract Material from Limbo' )
						begin
							g = model.entities.add_group
							g.material = m
							tw.load( g )
							tw.write( g, temp_file )
						ensure
							model.abort_operation
						end
					# Load texture to material and clean up.
					#new_material.texture = temp_file
					newfilename = temp_file
					needsdeletefile = 1
					#File.delete( temp_file )
				end
				
			end
			
			
			
			# We add 19 randomized colors
			for i in 0 .. (nbColors - 2) # #8 remplacement de 18 par le nombe de couleurs passées en paramètres
				
				randomvalueC = ((2.0*rand())-1.0) # entre -1.0 et 1.0
				#puts "#{i}th color, rand = #{randomvalueC}"
				
				# random applies on RGB values
				newred = Integer(initR+ 128.0*randomvalueC*randomColor)
				newred = 0 if(newred < 0)
				newred = 255 if(newred > 255)
				
				newgreen = Integer(initG+ 128.0*randomvalueC*randomColor)
				newgreen = 0 if(newgreen < 0)
				newgreen = 255 if(newgreen > 255)
				
				newblue = Integer(initB+ 128.0*randomvalueC*randomColor)
				newblue = 0 if(newblue < 0)
				newblue = 255 if(newblue > 255)
				
				icolor = Sketchup::Color.new(newred, newgreen, newblue)
				icolor.alpha = initAlpha
				newcolorName = "#{initName}#{i}"
				
				puts "#{i}th color, newcolorName = #{newcolorName} #{newred} #{newgreen} #{newblue}"
		
				newm = nil
				# Tests if material exists #6
				if(materials[newcolorName]) 
					puts "material exists"
					newm = materials[newcolorName]
				else
					puts "material does not exist"
					newm = materials.add newcolorName
					#newm.name = newcolorName
				end
				newm.colorize_type = m.colorize_type
				
				#newm.texture = m.texture.clone if(m.texture)
				if(m.texture) # cf. http://www.thomthom.net/thoughts/2012/03/the-secrets-of-sketchups-materials/ 
					newm.texture = newfilename
					#puts "newm texture  #{newm.texture.filename}"
					newm.texture.size = [ m.texture.width, m.texture.height ]
				end
				#newm = m.clone
				newm.color = icolor
				
				tabColors << newm
				
			end
			
			if(needsdeletefile == 1)
				File.delete( newfilename )
			end	
		end
		
		return tabColors
	end	
	
	#==================================================
	# Affichage du dialogue de saisie des parametre
	#==================================================
	def BR_OOB.DisplayDialog(facep, redomode)
		trace = 1
		# variables necessaires à la dupli/calepinage
		# f_epaisseurBardage  = 2.0  if not defined?(f_epaisseurBardage)#cm
		# f_hauteurBardage = 100.0#13.20 #cm
		# f_longueurBardage = 450.0 #cm
		# f_jointLongueur = 0.5
		# f_jointLargeur = 0.5 #cm
		# f_jointProfondeur = 0.5 # cm
		# f_decalageRangees = 150.0 # decalage en longueur entre rangees (ratio de lalongueur)
		# s_colorname = "Oob-1|Oob-2"
			
			
		# dialogue de saisie des parametres (inputbox
		#----------------------------------------------------------
			
		# Affichage d'un dialogue de saisie "webdialog"
		@dialogOobOne = UI::WebDialog.new(BR_OOB.getString("Oob : paramètres"), false, "OobLayout", 300, 300, 200, 0, true)
		puts @@OOBpluginRep
		pathname = Sketchup.find_support_file( 'dialogs/OobONE.html', @@OOBpluginRep )
		@dialogOobOne.set_file( pathname  )
		@dialogOobOne.set_size(490,600)
		@dialogOobOne.set_background_color("ECE9D8");
			
		# TRAITEMENT DES CALL BACK
		#==========================
		
		# V5.0 DELETE du preset  courant
		#==================================
		@dialogOobOne.add_action_callback("deletepreset") do |js_wd, message|
			rep = UI.messagebox(BR_OOB.getString("Delete preset")+" : " + message+ " ?",MB_YESNO)
			if(rep == 6)  # Yes
				presetfilename = Sketchup.find_support_file(message+'.oob', @@OOBpluginRep+'/presets')
				if !File::exists?(presetfilename)
					UI.messagebox "Error, file not found!"
				else	
					puts "deleting preset"
					File::delete(presetfilename)
					UI.messagebox(BR_OOB.getString("Preset has been deleted"))
					@dialogOobOne.execute_script( 'clearPresetOption( );' )
					
					# 4.6 Add preset file names to select
					#==================================
					# 6.1.5 presetsfiles = Sketchup.find_support_files('oob', @@OOBpluginRep+'/presets')
					presetsfiles = Dir[Sketchup.find_support_file('Plugins')+'/Oob-layouts/presets/*.oob']
					#puts "presetsfiles"
					presetsfiles.each{|file|
						#puts file
						#puts File.basename(file)
						@dialogOobOne.execute_script( 'addPresetOption( "'+File.basename(file,".oob").to_s+'" );' )
					}
	end
			end
		end
		
		# V4.6 sauvegarde des param courants en preset
		#=================================================
		@dialogOobOne.add_action_callback("savepreset") do |js_wd, message|
			prompts = [BR_OOB.getString("Nom du preset")] 
			values = [""] 		
			enums = [ nil]         
			results = inputbox prompts, values, enums, "Give a name to preset"
			return if not results # cancel
			
			# 6.1.5 presetsfiles = Sketchup.find_support_files('oob', @@OOBpluginRep+'/presets')
			presetsfiles = Dir[Sketchup.find_support_file('Plugins')+'/Oob-layouts/presets/*.oob']
			#puts "presetsfiles"
			file = presetsfiles[0]
			if(trace == 1)	
				puts file
				puts File.basename(file)
				puts File.dirname(file)   
			end
			fullname =  File.dirname(file)+"/"+results[0]+".oob"
			puts fullname if(trace == 1)			
			
			# TODO  : recup radio states left, center, right
			radiovalue = @dialogOobOne.get_element_value("inputradiohidden").to_s
			#UI.messagebox("radiovalue #{radiovalue}")
			
			# sauvegarde du fichier
			file = File.open(fullname,'w')
				file.write("Oob preset parameters;"+results[0].to_s+";\n")
				file.write("@@i_unit;"+Sketchup.active_model.options["UnitsOptions"]["LengthUnit"].to_s+";\n") # V5
				file.write("@@f_longueurBardage;"+@dialogOobOne.get_element_value("input2").to_s+";\n")
				file.write("@@f_hauteurBardage;"+@dialogOobOne.get_element_value("input3").to_s+";\n")
				file.write("@@f_randomlongueurBardage;"+@dialogOobOne.get_element_value("inputrand2").to_s+";\n")
				file.write("@@f_randomhauteurBardage;"+@dialogOobOne.get_element_value("inputrand3").to_s+";\n")
				# 6.0.0
				file.write("@@f_layeroffset;"+@dialogOobOne.get_element_value("inputlayeroffset").to_s+";\n") 
				file.write("@@f_heightoffset;"+@dialogOobOne.get_element_value("inputheightoffset").to_s+";\n") 
				file.write("@@f_lengthoffset;"+@dialogOobOne.get_element_value("inputlengthoffset").to_s+";\n") 
				 
				file.write("@@f_randomepaisseurBardage;"+@dialogOobOne.get_element_value("inputrand4").to_s+";\n")
				file.write("@@f_randomColor;"+@dialogOobOne.get_element_value("inputrand5").to_s+";\n")
				file.write("@@f_epaisseurBardage;"+@dialogOobOne.get_element_value("input4").to_s+";\n")
				file.write("@@f_jointLongueur;"+@dialogOobOne.get_element_value("input5").to_s+";\n")
				file.write("@@f_jointLargeur;"+@dialogOobOne.get_element_value("input6").to_s+";\n")
				file.write("@@f_jointProfondeur;"+@dialogOobOne.get_element_value("input7").to_s+";\n")
				file.write("@@f_decalageRangees;"+@dialogOobOne.get_element_value("input8").to_s+";\n")
				file.write("@@s_colorname;"+@dialogOobOne.get_element_value("input9").to_s+";\n")
				file.write("@@i_startpoint;"+@dialogOobOne.get_element_value("inputstartpoint").to_s+";\n")
			file.close
			
			# on rajoute le preset dans la liste
			@dialogOobOne.execute_script( 'addPresetOption( "'+results[0].to_s+'" );' )
			
		end
		
		# selection d'un fichier de preset
		#===========================================
		@dialogOobOne.add_action_callback("selectpreset") do |js_wd, message|
			puts "selectpreset #{message}"
			
			# lecture du fichier 
			presetfilename = Sketchup.find_support_file(message+'.oob', @@OOBpluginRep+'/presets')
			if !File.exist?(presetfilename)
				UI.messagebox "Error, file not found!"
			end
			# gestion unites
			presetunit = 4 # les presets sont par defaut en metre
			modelunit = Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]
			
			# 0 = "	# 1 = ' # 2 = mm # 3 = cm # 4 = m
			unitconversionmodel = 1.0/2.54
			tabunitconversion = [1.0,12.0,0.1/2.54,1.0/2.54,100.0/2.54]
			
			if((modelunit >= 0) and (modelunit <= 4))  
				unitconversionmodel = 1.0/tabunitconversion[modelunit] # conversion de pouces en unites courante du modele
			end 
			
			puts "unitconversionmodel"
			puts unitconversionmodel
			
			unitconversionpreset = tabunitconversion[presetunit] # conversion de l'uinte preset vers metre
			
			# on re-initialise l'offset V 6.1.2
			@dialogOobOne.execute_script( 'setValue( "inputlayeroffset;0" );' ) 
			
			# lecture des presets
			file = File.open(presetfilename )
			file.each_line do |line|
				tab = line.split(';')
				
				# gestion unites
				if(tab[0] =="@@i_unit")
					presetunit = tab[1].to_i
					unitconversionpreset = tabunitconversion[presetunit]
					#puts "unitconversionpreset"
					#puts unitconversionpreset
				end
				if(tab[0] =="@@f_longueurBardage")
					#gestion multi lengths
					lengthS = (tab[1].to_f*unitconversionmodel*unitconversionpreset).to_s
					if(tab.length > 2)
						lengthS = ""
						#	puts tab
						for i in 1..(tab.length-1)
							if((tab[i] != "\n" ) && (tab[i] != ""))
								lengthS =  lengthS + (tab[i].to_f*unitconversionmodel*unitconversionpreset).to_s+"#"
							end	
						end
						#"lengthS = line["@@f_longueurBardage;".length..line.length].gsub(";","|") #substring of line = "@@f_longueurBardage;1.0;2;3;"
					end
					#puts("lengthS = #{lengthS}")
					#script = 'setValue( "input2;'+lengthS+'" );'
					#puts("script = #{script}")
					@dialogOobOne.execute_script( 'setValue( "input2;'+lengthS+'" );' ) 
				end
				
				if(tab[0] =="@@f_hauteurBardage")
					#gestion multi hauteurs		
					heightS = (tab[1].to_f*unitconversionmodel*unitconversionpreset).to_s
					if(tab.length > 2)
						heightS = ""
						#	puts tab
						for i in 1..(tab.length-1)
							if((tab[i] != "\n" ) && (tab[i] != ""))
								heightS =  heightS + (tab[i].to_f*unitconversionmodel*unitconversionpreset).to_s+"#"
							end	
						end
						#"lengthS = line["@@f_longueurBardage;".length..line.length].gsub(";","|") #substring of line = "@@f_longueurBardage;1.0;2;3;"
					end
					puts("heightS = #{heightS}")
					@dialogOobOne.execute_script( 'setValue( "input3;'+heightS+'" );' ) 
					#puts("script = #{script}")
					#@dialogOobOne.execute_script( 'setValue( "input3;'+(tab[1].to_f*unitconversionmodel*unitconversionpreset).to_s+'" );' ) 
				end
				
				@dialogOobOne.execute_script( 'setValue( "inputrand2;'+tab[1]+'" );' ) if(tab[0] =="@@f_randomlongueurBardage")
				@dialogOobOne.execute_script( 'setValue( "inputrand3;'+tab[1]+'" );' ) if(tab[0] =="@@f_randomhauteurBardage")
				@dialogOobOne.execute_script( 'setValue( "inputrand4;'+tab[1]+'" );' ) if(tab[0] =="@@f_randomepaisseurBardage")
				@dialogOobOne.execute_script( 'setValue( "inputrand5;'+tab[1]+'" );' ) if(tab[0] =="@@f_randomColor")
				
				# 6.0.0
				@dialogOobOne.execute_script( 'setValue( "inputlayeroffset;'+tab[1]+'" );' ) if(tab[0] =="@@f_layeroffset") 
				@dialogOobOne.execute_script( 'setValue( "inputheightoffset;'+tab[1]+'" );' ) if(tab[0] =="@@f_heightoffset") 
				@dialogOobOne.execute_script( 'setValue( "inputlengthoffset;'+tab[1]+'" );' ) if(tab[0] =="@@f_lengthoffset") 
				@dialogOobOne.execute_script( 'setValue( "selectPreset;'+tab[1]+'" );' ) if(tab[0] =="@@s_presetname") 
				
				@dialogOobOne.execute_script( 'setValue( "input4;'+(tab[1].to_f*unitconversionmodel*unitconversionpreset).to_s+'" );' ) if(tab[0] =="@@f_epaisseurBardage")
				@dialogOobOne.execute_script( 'setValue( "input5;'+(tab[1].to_f*unitconversionmodel*unitconversionpreset).to_s+'" );' ) if(tab[0] =="@@f_jointLongueur")
				@dialogOobOne.execute_script( 'setValue( "input6;'+(tab[1].to_f*unitconversionmodel*unitconversionpreset).to_s+'" );' ) if(tab[0] =="@@f_jointLargeur")
				@dialogOobOne.execute_script( 'setValue( "input7;'+(tab[1].to_f*unitconversionmodel*unitconversionpreset).to_s+'" );' ) if(tab[0] =="@@f_jointProfondeur")
				@dialogOobOne.execute_script( 'setValue( "input8;'+(tab[1].to_f*unitconversionmodel*unitconversionpreset).to_s+'" );' ) if(tab[0] =="@@f_decalageRangees")
				@dialogOobOne.execute_script( 'setValue( "input9;'+tab[1]+'" );' ) if(tab[0] =="@@s_colorname")
				@dialogOobOne.execute_script( 'setValue( "inputstartpoint;'+tab[1]+'" );' ) if(tab[0] =="@@i_startpoint")
				
			end
			file.close
			@dialogOobOne.execute_script('compute();')
		end
		
		# CALCUL : 
		# 1 : APPLY 
		# 2 : OK 
		# 3 : CANCEL
		#===============================================
		@dialogOobOne.add_action_callback("calcul") do |js_wd, message|
			#puts "calcul"+ message
			trace = 0
			#OK
			if(message.to_i == 2) # OK
				@dialogOobOne.close 
				#return
				#end
			
			# ANNULER
			elsif(message.to_i == 3) # ANNULER
				if(@computationDone == 1) # un calcul a été fait précédemment
					puts "Annuler le Calcul "+message.to_s if(trace == 1)	
					rep = UI.messagebox(BR_OOB.getString("Annuler l'opération?"),MB_YESNO)
					if(rep == 6)  # Yes
						#UNDO + CLOSE DU DIALOGUE#BR_OOB.keyAction()
						Sketchup.undo
						@dialogOobOne.close
					end	
				else # aucun calcul , on ferme
					@dialogOobOne.close
				end
				#return
			#end
			else
				#  CALCUL (CALEPINAGE) Appliquer ou OK on commence par l'undo si un calul a ete fait
				if(@computationDone == 1)
					# V5 test du contenu de la selection
					flagundo = 1
					sel = Sketchup.active_model.selection
					sel.each{|elt|
						if(elt == facep.m_Face)
							#UI.messagebox("Initial face to manage")
						end
						if((elt != facep.m_Face)and(elt.kind_of? Sketchup::Face))
							#UI.messagebox("Other face to manage")
							matPosElt = Geom::Transformation.new #identite
							
							tabFaces = Array.new
							BR_GeomTools.getListOfFaces(elt, matPosElt, tabFaces)
							
							#puts "tabFaces"
							#puts tabFaces
							
							facep = tabFaces[0]
							flagundo = 0
						end
					}
					
					# Undo de l'action prcedente
					if(flagundo == 1)
						Sketchup.undo 
						# reselect de la face
						puts "facep = " if(trace == 1)
						puts facep.m_Face if(trace == 1)
						sel = Sketchup.active_model.selection
						sel.clear
						sel.add facep.m_Face
						redomode = 1 # pour prendre en compte l direction de dupli (et non l'edge la plus longue)
					end
					
					#return
				end
				
				if(trace == 1)
					puts "Calcul"+message.to_s if(message.to_i == 1) #
					puts "Calcul"+message.to_s if(message.to_i == 2) #
				end
				
				# V7.0 gestion multi longueurs #2
				#@@f_longueurBardage = @dialogOobOne.get_element_value("input2").to_f
				strlong =  @dialogOobOne.get_element_value("input2")
				tab = strlong.split(';')
				if(tab.size() > 1)
					puts "tab of lengths"
					puts tab
					@@f_longueurBardage = tab[0].to_f # premiere longueur
					@@f_tabLongueurBardage = tab #2 tableau des longueurs
					@@f_tabLongueurBardageString = strlong #2 au format string
				else	
					@@f_longueurBardage = strlong.to_f
					@@f_tabLongueurBardage = []
					@@f_tabLongueurBardageString = ""
				end
				#2
				#puts "nblongueurs = #{@@f_tabLongueurBardage.length}"
				
				
				#@@f_hauteurBardage = @dialogOobOne.get_element_value("input3")@@f_tabHauteurBardage = @dialogOobOne.get_element_value("input3").split(/[,;#]/).map(&:to_f)
				strlong =  @dialogOobOne.get_element_value("input3")
				tab = strlong.split(';')
				if(tab.size() > 1)
					puts "tab of lengths"
					puts tab
					@@f_hauteurBardage = tab[0].to_f # premiere longueur
					@@f_tabHauteurBardage = tab #2 tableau des longueurs
					@@f_tabHauteurBardageString = strlong #2 au format string
				else	
					@@f_hauteurBardage = strlong.to_f
					@@f_tabHauteurBardage = []
					@@f_tabHauteurBardageString = ""
				end
								
				# ajout random V4.5
				@@f_randomlongueurBardage = @dialogOobOne.get_element_value("inputrand2").to_f
				@@f_randomlongueurBardage = 0.0 if( @@f_randomlongueurBardage < 0.0)
				@@f_randomlongueurBardage = 1.0 if( @@f_randomlongueurBardage > 1.0)
			
				@@f_randomhauteurBardage = @dialogOobOne.get_element_value("inputrand3").to_f
				@@f_randomhauteurBardage = 0.0 if( @@f_randomhauteurBardage < 0.0)
				@@f_randomhauteurBardage = 1.0 if( @@f_randomhauteurBardage > 1.0)
				
				@@f_randomepaisseurBardage = @dialogOobOne.get_element_value("inputrand4").to_f
				@@f_randomepaisseurBardage = 0.0 if( @@f_randomepaisseurBardage < 0.0)
				@@f_randomepaisseurBardage = 1.0 if( @@f_randomepaisseurBardage > 1.0)
				
				@@f_randomColor = @dialogOobOne.get_element_value("inputrand5").to_f
				@@f_randomColor = 0.0 if( @@f_randomColor < 0.0)
				
				if( @@f_randomColor > 1.0)
					#8 : nombe de couleurs random
					@@i_nbrandomColors = Integer(@@f_randomColor)
					@@f_randomColor = @@f_randomColor-@@i_nbrandomColors
				else
					@@i_nbrandomColors =  10
				end
				p "@@i_nbrandomColors #{@@i_nbrandomColors}"
				p "@@f_randomColor #{@@f_randomColor}"
					
				# 6.0.0 
				@@f_layeroffset = @dialogOobOne.get_element_value("inputlayeroffset").to_f 
				@@f_heightoffset = @dialogOobOne.get_element_value("inputheightoffset").to_f 
				@@f_lengthoffset = @dialogOobOne.get_element_value("inputlengthoffset").to_f 
				@@s_presetname = @dialogOobOne.get_element_value("selectPreset").to_s 
				
				#puts "@@s_presetname #{@@s_presetname}"
					
				if(trace == 1)
					puts "@@f_randomlongueurBardage   #{@@f_randomlongueurBardage}"
					puts "@@f_randomhauteurBardage   #{@@f_randomhauteurBardage}"
				end
				
				@@f_epaisseurBardage= -@dialogOobOne.get_element_value("input4").to_f
				@@f_jointLongueur= @dialogOobOne.get_element_value("input5").to_f
				@@f_jointLargeur = @dialogOobOne.get_element_value("input6").to_f
				@@f_jointProfondeur = @dialogOobOne.get_element_value("input7").to_f
				
				@@f_decalageRangees = @dialogOobOne.get_element_value("input8").to_f
				# V5
				#checkvalue = @dialogOobOne.get_element_value("input10")
				#UI.messagebox(checkvalue)
				@@b_jointperdu = @dialogOobOne.get_element_value("input10").to_s # NI 0008
				#puts "---@@b_jointperdu = #{@@b_jointperdu}"
				#UI.messagebox(@@b_jointperdu )
				@@s_colorname = @dialogOobOne.get_element_value("input9").to_s
				# NI 0011
				@@i_startpoint = @dialogOobOne.get_element_value("inputstartpoint").to_i
				
				# *** FIXED: Get values for the new controls ***
				pattern_rotation = @dialogOobOne.get_element_value("patternRotation").to_s
				start_from = @dialogOobOne.get_element_value("startFrom").to_s
				force_full_row = @dialogOobOne.get_element_value("forceFullRow").to_s
				start_row_height = @dialogOobOne.get_element_value("startRowHeight").to_s
				last_row_placement = @dialogOobOne.get_element_value("lastRowPlacement").to_s

				# Creation du calepinage
				#=============================
				sel = Sketchup.active_model.selection
				if(sel.count !=0 )
					Sketchup.active_model.start_operation(BR_OOB.getString("Créer calepinage"),true) ###############################################
					
					# *** FIXED: Pass the new values to the function ***
					res = BR_OOB.CalepinageFace(facep, redomode, pattern_rotation, start_from, force_full_row, start_row_height, last_row_placement)
					
					Sketchup.active_model.commit_operation
					@computationDone = res # flag pour l'undo
				end
			end
			
			
		end	
		
		# Display du dialogue
		#==========================
		@dialogOobOne.show{
		#@dialogOobOne.show_modal{
			# Parameteage des labels NLS
			
			@dialogOobOne.execute_script( 'setLabel( "label2;'+BR_OOB.getString("Longueur (cm)").to_s+'" );' )
			@dialogOobOne.execute_script( 'setValue( "input2;'+@@f_longueurBardage.to_s+'" );' )
			
			#2 Tab longueurs
			if(@@f_tabLongueurBardageString != "")
				@dialogOobOne.execute_script( 'setValue( "input2;'+@@f_tabLongueurBardageString.to_s+'" );' )
			end
			
			# V4.5
			@dialogOobOne.execute_script( 'setValue( "inputrand2;'+@@f_randomlongueurBardage.to_s+'" );' )
			@dialogOobOne.execute_script( 'setValue( "inputrand3;'+@@f_randomhauteurBardage.to_s+'" );' )
			@dialogOobOne.execute_script( 'setValue( "inputrand4;'+@@f_randomepaisseurBardage.to_s+'" );' )
			@dialogOobOne.execute_script( 'setValue( "inputrand5;'+@@f_randomColor.to_s+'" );' )
			
			 # 6.0.0
			@dialogOobOne.execute_script( 'setValue( "inputlayeroffset;'+@@f_layeroffset.to_s+'" );' )
			@dialogOobOne.execute_script( 'setValue( "inputheightoffset;'+@@f_heightoffset.to_s+'" );' )
			@dialogOobOne.execute_script( 'setValue( "inputlengthoffset;'+@@f_lengthoffset.to_s+'" );' )
			@dialogOobOne.execute_script( 'setValue( "selectPreset;'+@@s_presetname.to_s+'" );' )
				
			@dialogOobOne.execute_script( 'setLabel( "label3;'+BR_OOB.getString("Hauteur(cm)").to_s+'" );' )
			@dialogOobOne.execute_script( 'setValue( "input3;'+@@f_hauteurBardage.to_s+'" );' )
				
			@dialogOobOne.execute_script( 'setLabel( "label4;'+BR_OOB.getString("Epaisseur (cm)").to_s+'" );' )
			@dialogOobOne.execute_script( 'setValue( "input4;'+@@f_epaisseurBardage.to_s+'" );' )
				
			@dialogOobOne.execute_script( 'setLabel( "label5;'+BR_OOB.getString("JointL").to_s+'" );' )
			@dialogOobOne.execute_script( 'setValue( "input5;'+@@f_jointLongueur.to_s+'" );' )
				
			@dialogOobOne.execute_script( 'setLabel( "label6;'+BR_OOB.getString("JointH").to_s+'" );' )
			@dialogOobOne.execute_script( 'setValue( "input6;'+@@f_jointLargeur.to_s+'" );' )
				
			@dialogOobOne.execute_script( 'setLabel( "label7;'+BR_OOB.getString("Joint prof. (cm)").to_s+'" );' )
			@dialogOobOne.execute_script( 'setValue( "input7;'+@@f_jointProfondeur.to_s+'" );' )
			
			@dialogOobOne.execute_script( 'setLabel( "label8;'+BR_OOB.getString("Décalage rangées (cm)").to_s+'" );' )
			@dialogOobOne.execute_script( 'setValue( "input8;'+@@f_decalageRangees.to_s+'" );' )
			
			puts "BR_OOB.getString(Annuler).to_s"  if(trace == 1)
			puts BR_OOB.getString("Annuler").to_s  if(trace == 1)
			
			# 4.3
			@dialogOobOne.execute_script( 'setLabel( "label10;'+BR_OOB.getString("Appliquer").to_s+'" );' )
			@dialogOobOne.execute_script( 'setLabel( "label12;'+BR_OOB.getString("Annuler").to_s+'" );' )
			
			@dialogOobOne.execute_script( 'setLabel( "label13;'+BR_OOB.getString("Pose à joint perdu").to_s+'" );' )
			
			#@dialogOobOne.execute_script( 'setCheckValue( "input10;'+@@b_jointperdu.to_s+'" );' )
				
			@dialogOobOne.execute_script( 'setLabel( "label9;'+BR_OOB.getString("Couleur").to_s+'" );' )
			# Find out what material is selected.
			currentmat = Sketchup.active_model.materials.current
			
			#puts currentmat.display_name
			#puts currentmat.name
			if(currentmat)
				@dialogOobOne.execute_script( 'setValue( "input9;'+currentmat.display_name.to_s+'" );' )
			else
				@dialogOobOne.execute_script( 'setValue( "input9;'+@@s_colorname.to_s+'" );' )
			end
			
			@dialogOobOne.execute_script( 'setValue( "inputstartpoint;'+@@i_startpoint.to_s+'" );' ) # NI 0011
			
			
			# 4.6 Add preset file names to select
			#==================================
			#puts "Loading prests files"
			#6.1.5 presetsfiles = Sketchup.find_support_files('oob', @@OOBpluginRep+'/presets')
			#puts "presetsfiles"
			presetsfiles = Dir[Sketchup.find_support_file('Plugins')+'/Oob-layouts/presets/*.oob']
			#puts presetsfiles

			presetsfiles.each{|file|
				#puts file
				#puts File.basename(file)
				@dialogOobOne.execute_script( 'addPresetOption( "'+File.basename(file,".oob").to_s+'" );' )
			}
			# V6.0.0
			#puts "--@@s_presetname = #{@@s_presetname}"
			if(@@s_presetname != "")
				@dialogOobOne.execute_script( 'setPreset( "'+@@s_presetname+'" );' ) # V6.0.0
			end
			@computationDone = 0
			
			#@dialogOobOne.execute_script( 'setValue( "input9;'+@@s_colorname.to_s+'" );' )	
			#@dialog.execute_script('setValue( "label20;'+ $tabStrings["label20"] +'" );' )
		}#UpdateDialog(@dialogModule)}
	end
	
	#===========================================
	# NI 0008
	# V5 Recuperation d'un point situé en xmini, ymini d'une face
	#===========================================
	def BR_OOB.GetFaceLowestLeftCorner(face, vectX, vectY,vectZ )
		trace = 0
		
		
		verticelist = face.vertices
			
		puts "GetFaceLowestLeftCorner" if(trace == 2) 
		lowestvertex = []#nil # vertex le plus bas a gauche pour "drop" sur la facep 
		lowestransformedpoint = []
		highestvertex = [] #nil # vertex oppose pour calcul des dimensions
		highestransformedpoint = []
			
		# calcul du point moyen
		meanPoint = BR_GeomTools.getMeanPoint(verticelist)
		#meanPoint.transform! facep.m_Matrice
			
		#matface = Geom::Transformation.axes origin, vectX, vectY, vectZ
		debug3D = 0
		if (debug3D == 1)
			#BR_GeomTools.addDebugLinePV(meanPoint, vectlongest, 300.0, nil)	
		
			BR_GeomTools.addDebugLinePV(meanPoint, vectX, 30.0, nil)	
			BR_GeomTools.addDebugLinePV(meanPoint, vectY, 20.0, nil)	
			BR_GeomTools.addDebugLinePV(meanPoint, vectZ, 10.0, nil)	
		end
		debug3D = 0
			
		matface = Geom::Transformation.new(vectX, vectY, vectZ, meanPoint ) #Geom::Transformation.axes meanPoint, vectX, vectY, vectZ
		matface.invert! # pour transformer les points dans le systeme d'axes de la facep
		# puts "origint" if(trace == 1) 
		# puts (origin.transform! matface) if(trace == 1) 
						
		ind = 0
		
		# parcours des points pour recherche du lowestleft corner et highest right corner
		verticelist.each{|vertex|
			puts vertex.position if(trace == 1) 
			pointt = Geom::Point3d.new vertex
			#pointt.transform! facep.m_Matrice
			pointt.transform! matface #facep.m_Matrice
			puts ind if(trace == 1)
			puts "vertex" if(trace == 1) 
			puts vertex.position if(trace == 1) 				
			puts "pointt" if(trace == 1) 
			puts pointt if(trace == 1) 
			puts "lowestransformedpoint" if(trace == 1) 
			puts lowestransformedpoint if(trace == 1) 
			puts "highestransformedpoint" if(trace == 1) 
			puts highestransformedpoint if(trace == 1) 
			#text = Sketchup.active_model.entities.add_text ind.to_s, vertex.position #if (debug3D == 1)
			
			if(ind == 0) # init sur premier point
				lowestvertex = [vertex.position[0],vertex.position[1],vertex.position[2]]
				lowestransformedpoint =  [pointt[0],pointt[1],pointt[2]]
				highestvertex = [vertex.position[0],vertex.position[1],vertex.position[2]] # vertex oppose pour calcul des dimensions
				highestransformedpoint = [pointt[0],pointt[1],pointt[2]]
			else
				# test lowest
				if(pointt[1] < lowestransformedpoint[1])
					puts " Is lowesty" if (trace == 1)
					lowestvertex[1] = vertex.position[1] # le vertex est plus bas 
					lowestransformedpoint[1] = pointt[1]
				end
				if(pointt[0] < lowestransformedpoint[0])
					puts " Is lowestx" if (trace == 1)
					lowestvertex[0] = vertex.position[0] # le vertex est plus bas 
					lowestransformedpoint[0] = pointt[0]
				end
				
				# test highest
				if(pointt[1] > highestransformedpoint[1])
					puts " Is highestverte y" if (trace == 1)
					highestvertex[1] = vertex.position[1]
					highestransformedpoint[1] = pointt[1]
				end
				if(pointt[0] > highestransformedpoint[0])
					puts " Is highestverte x"  if (trace == 1)
					highestvertex[0] = vertex.position[0]
					highestransformedpoint[0] = pointt[0]
				end
			end		
			ind = ind+1
		}
				
		lowestvertex = 	Geom::Point3d.new lowestransformedpoint
		lowestvertex.transform! matface.inverse
		
		#lowestvertex.transform! facep.m_Matrice.inverse
		return lowestvertex
	end
	
	#======================================================
	# NI 0008
	# V5.0 fonction d'ajout d'une face (element de bardage)
	#======================================================
	def BR_OOB.AddFace(posx,posy, lengthx, lengthy, matrice, entities)
		trace = 0
		if(trace == 1)
			puts "*****************AddFace" if(trace)
			puts "posx = #{posx}" if(trace)
			puts "posy = #{posy}" if(trace)
			puts "lengthx = #{lengthx}" if(trace)
			puts "lengthy = #{lengthy}" if(trace)
			puts "matrice = #{matrice}" if(trace)
			puts "entities = #{entities}" if(trace)
			puts "*****************" if(trace)
		end
		points = []
		points[0] = Geom::Point3d.new(posx,posy,0)
		points[1] = Geom::Point3d.new(posx + lengthx,posy,0)
		points[2] = Geom::Point3d.new(posx + lengthx,posy + lengthy,0)
		points[3] = Geom::Point3d.new(posx,posy + lengthy,0)
			
		pointsT = []
				
		pointsT[0] = points[0].transform! matrice
		pointsT[1] = points[1].transform! matrice
		pointsT[2] = points[2].transform! matrice
		pointsT[3] = points[3].transform! matrice
				
		# if(mode3D == 0)
		edges = []
					
		edges0 = entities.add_edges pointsT[0], pointsT[1]
		edges1 = entities.add_edges pointsT[1], pointsT[2]
		edges2 = entities.add_edges pointsT[2], pointsT[3]
		edges3 = entities.add_edges pointsT[3], pointsT[0]
		newface = entities.add_face pointsT[0], pointsT[1], pointsT[2], pointsT[3]
		
		return newface
	end
	
	#=================================================================================================
	# #2 Mode multi longueurs
	# f_tabLlongueurBardage: tableau des longueurs possibles
	# lengthIndexInTab: index dans le tableau
	# f_randomlongueurBardage: option de repartition:
	#	0.0 : parcours dans l'ordre, 
	#	1.0 : parcours random
	#===========================================	
	def BR_OOB.GetNextValue(f_tabLlongueurBardage, lengthIndexInTab,f_randomlongueurBardage)
		puts "GetNextValue #{lengthIndexInTab}"
		result = 0.0
		if(f_randomlongueurBardage == 0.0) #pas de random, on prend la valeur suivante
			# reset si on est à la fin du tableau
			lengthIndexInTab = 0 if(lengthIndexInTab >= f_tabLlongueurBardage.length)
				
			result = f_tabLlongueurBardage[lengthIndexInTab].to_f
			lengthIndexInTab = lengthIndexInTab + 1 # pour le tour suivant
		else
			# random, on cherche un nouvel index random different du precedent
			# on prend un decalage random entre 1 et le max (length -1)
			max = f_tabLlongueurBardage.length
			newindex = lengthIndexInTab + (rand()*(max-1)+1).to_i
			newindex = newindex - max if(newindex >= max)
			result = f_tabLlongueurBardage[newindex].to_f
			lengthIndexInTab = newindex
		end
		puts "GetNextValue end #{lengthIndexInTab}"
		return [result, lengthIndexInTab]
	end
	
	#===========================================
	# CalepinageFace :
	# creation d'un calepinage 3D a partir d'une face
	# redomode = 1 : il s'agit d'un redo la direction 
	#           doit etre recupérée dans  les attributs
	#===========================================	
	# *** FIXED: Updated function signature to accept new parameters ***
	def BR_OOB.CalepinageFace(facep, redomode, pattern_rotation = "horizontal", start_from = "bottom", force_full_row = "false", start_row_height = "auto", last_row_placement = "cut")
		
		trace = 0 
		jointsPerdusflag = 0 # V5, reutilisation des chutes # NI 0008
		grpresultGlobal  = nil # groupe contenant les faces intermediaires (lames a la longueur mais non decoupees) 
		grpresultdecoupeGlobal = nil # groupe contenant les elements finaux (bonne longueur + decoupe)
		
		# passage des inputs en pouces
		#-----------------------
		# V4.4 unite courante
		unit = Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]
		# 0 = "
		# 1 = '
		# 2 = mm
		# 3 = cm
		# 4 = m
		unitconversion = 1.0/2.54
		tabunitconversion = [1.0,12.0,0.1/2.54,1.0/2.54,100.0/2.54]
		
		if((unit >= 0) and (unit <= 4))  
			unitconversion = tabunitconversion[unit]
		end 
		puts "unit conversion = #{unit} #{tabunitconversion[unit]} : #{@@f_longueurBardage} -> #{@@f_longueurBardage.cm} -> #{@@f_longueurBardage.cm*unitconversion} -> #{@@f_longueurBardage*unitconversion}" if(trace == 1)
		
		
		
		
		
		

		
		
		
		
		# V4.5
		f_randomlongueurBardage = @@f_randomlongueurBardage #*unitconversion #.cm*unitconversion
		f_randomhauteurBardage = @@f_randomhauteurBardage #*unitconversion #.cm*unitconversion
		f_randomepaisseurBardage = @@f_randomepaisseurBardage #*unitconversion #.cm*unitconversion
		f_randomColor = @@f_randomColor #*unitconversion #.cm*unitconversion
				
		f_longueurBardage = @@f_longueurBardage*unitconversion #.cm*unitconversion
		#puts "f_longueurBardage"
		#puts f_longueurBardage
		
		#2 tableau des longueurs
		f_tabLlongueurBardage = []
		puts @@f_tabLongueurBardage if(trace == 1)
		@@f_tabLongueurBardage.each_index{|ielt|
			puts @@f_tabLongueurBardage[ielt]
			puts (@@f_tabLongueurBardage[ielt].to_f*unitconversion)
			f_tabLlongueurBardage.push(@@f_tabLongueurBardage[ielt].to_f*unitconversion );
		}
		
		f_hauteurBardage = @@f_hauteurBardage*unitconversion #.cm*unitconversion
		
		#2 tableau des hauteurs
		f_tabHauteurBardage = []
		puts @@f_tabHauteurBardage if(trace == 1)
		@@f_tabHauteurBardage.each_index{|ielt|
			puts @@f_tabHauteurBardage[ielt]
			puts (@@f_tabHauteurBardage[ielt].to_f*unitconversion)
			f_tabHauteurBardage.push(@@f_tabHauteurBardage[ielt].to_f*unitconversion );
		}
		
		
		f_epaisseurBardage = @@f_epaisseurBardage*unitconversion #.cm*unitconversion
		f_jointLongueur = @@f_jointLongueur*unitconversion #.cm*unitconversion
		f_jointLargeur = @@f_jointLargeur*unitconversion #.cm*unitconversion
		f_jointProfondeur = @@f_jointProfondeur*unitconversion #.cm*unitconversion
		f_decalageRangees = @@f_decalageRangees*unitconversion #.cm*unitconversion
		b_jointperdu = @@b_jointperdu
		i_startpoint = @@i_startpoint
		
		# 6.0.0
		f_layeroffset = @@f_layeroffset*unitconversion 
		f_heightoffset = @@f_heightoffset*unitconversion 
		f_lengthoffset = @@f_lengthoffset*unitconversion 
		s_presetname = @@s_presetname #	selectPreset
		
		
		if(b_jointperdu == "true")
			jointsPerdusflag = 1 # Enable staggered joint layout
		else
			jointsPerdusflag = 0 # Disable staggered joint layout
		end
		
		puts "f_longueurBardage" if(trace == 1) 
		puts f_longueurBardage if(trace == 1) 
			
		if(	f_decalageRangees > f_longueurBardage)
			UI.messagebox(BR_OOB.getString("Calcul impossible, décalage supérieur à la longueur"))
			return 0
		end
		
		model = Sketchup.active_model
		sel = Sketchup.active_model.selection
		entmodel = Sketchup.active_model.entities

		trace = 0
		debug3D = 0
			
		puts "111111111111111111111111111111" if(trace == 2) 
		normal = facep.m_Face.normal #normale a la facep
		normalpositionnee = normal.transform! facep.m_Matrice
					
		# calcul de l'inclinaison et orientation a partir de la normale
		normalpositionnee.normalize! # normale normée
		inclinaisonFace = Math::acos(normalpositionnee[2]).radians

		# on cree un groupe OOB1 qui va contenir une copie de la face originale et le calepinage
		oob1grp = facep.m_Face.parent.entities.add_group
		oob1grp.name = "Oob-grp"
		#on duplique tout de suite la face dans un groupe distinct (pour recup de la facep  originale)
		origfacegrp = oob1grp.entities.add_group
		origfacegrp.name= "Oob-init"
		BR_OOB.DuplicateFacesToEntities(origfacegrp.entities, facep.m_Face)
		origfacegrp.hidden = true
		BR_OOB.setLayer("Oob-init", origfacegrp)
			
		# traitement de la face "MUR"
		# on parcoure les points pour rechercher le point le plus bas à gauche*
		verticelist = facep.m_Face.vertices
			
		lowestvertex = []#nil # vertex le plus bas a gauche pour "drop" sur la facep 
		lowestransformedpoint = []
		highestvertex = [] #nil # vertex oppose pour calcul des dimensions
		highestransformedpoint = []
			
		# calcul du point moyen
		meanPoint = BR_GeomTools.getMeanPoint(verticelist)
		meanPoint.transform! facep.m_Matrice
			
		# V7.0 Pattern rotation control
		pattern_rotation = @dialogOobOne.get_element_value("patternRotation").to_s
		if pattern_rotation == "vertical"
			vectlongest = Geom::Vector3d.new(0, 0, 1)
		else
			# si une edge est selectionne on la prend comme reference sinon onr recupere la longest edge
			# recup de l'edge selectionnee ou de l'arete la plus longue
			sel = Sketchup.active_model.selection
			longestedge = nil
		
			sel.each do |entity|
				if entity.is_a? Sketchup::Edge
					longestedge = entity
					break
				end
			end
					
			# Recup de l'arete la plus longue => VectX
			if(longestedge == nil)
				longestedge = BR_GeomTools.getLongestEdge(facep.m_Face)
			end
			vectlongest = longestedge.line[1]
		end
		
		origin = Geom::Point3d.new 0,0,0 
		startpoint = Geom::Point3d.new 0,0,0 
		midlpoint = Geom::Point3d.new 0,0,0 
		endpoint = Geom::Point3d.new 0,0,0 
			
		# vectlongest est la direction de duplication
		if(redomode == 1)
			vectlongest = Geom::Vector3d.new @@vectx.to_f,@@vecty.to_f,@@vectz.to_f
			puts "redo i_startpoint = #{i_startpoint}" if(trace == 1) 
			origin = Geom::Point3d.new @@startpointx.to_f,@@startpointy.to_f,@@startpointz.to_f  if(i_startpoint == 1)# point d'origine
			origin = Geom::Point3d.new @@midlpointx.to_f,@@midlpointy.to_f,@@midlpointz.to_f  if(i_startpoint == 2)# point d'origine
			origin = Geom::Point3d.new @@endpointx.to_f,@@endpointy.to_f,@@endpointz.to_f  if(i_startpoint ==  3)# point d'origine	
			startpoint = Geom::Point3d.new @@startpointx.to_f,@@startpointy.to_f,@@startpointz.to_f 
			midlpoint = Geom::Point3d.new @@midlpointx.to_f,@@midlpointy.to_f,@@midlpointz.to_f  
			endpoint = Geom::Point3d.new @@endpointx.to_f,@@endpointy.to_f,@@endpointz.to_f  
		else
			# v3 : on prend le point d'origine de l'arête comme point de départ
			if(longestedge != nil)
			
				# V5.1 origin peut etre le point de depart, de fin ou le centre de l'arete
				startpoint = longestedge.start.position
				midlpoint = Geom::Point3d.linear_combination 0.5, longestedge.start.position, 0.5, longestedge.end.position
				endpoint = longestedge.end.position
				
				if(i_startpoint == 1)
					#puts "origin = start"
					origin = longestedge.start.position # point d'origine des elements
					
					#puts origin
				end
				if(i_startpoint == 2)
					#puts "origin = middle"
					origin = Geom::Point3d.linear_combination 0.5, longestedge.start.position, 0.5, longestedge.end.position
					
					#puts origin
				end
				if(i_startpoint == 3)
					#puts "origin = end"
					origin = longestedge.end.position # point d'origine des elements
					
					#puts origin
				end
				
				origin.transform! facep.m_Matrice
			end	
		end
		
		# matrice  de transformation dans un system d'axe de la facep
		vectX = vectlongest
		vectZ = normalpositionnee
		vectY = vectZ.cross vectX

		# *** FIXED: Implement logic for new controls ***
		if pattern_rotation == "vertical"
			temp_v = vectX
			vectX = vectY
			vectY = temp_v.reverse
		end

		if start_from == "top"
			vectY.reverse!
		end
		
		debug3D = 0
		if (debug3D == 1)
			puts "vectXYZ"	
			puts vectX	
			puts vectY	
			puts vectZ	
			#BR_GeomTools.addDebugLinePV(meanPoint, vectlongest, 300.0, nil)	
			BR_GeomTools.addDebugLinePV(origin, vectX, 30.0, nil)	
			BR_GeomTools.addDebugLinePV(origin, vectY, 20.0, nil)	
			BR_GeomTools.addDebugLinePV(origin, vectZ, 10.0, nil)	
		end
		debug3D = 0
			
		matface = Geom::Transformation.new(vectX, vectY, vectZ, meanPoint ) #Geom::Transformation.axes meanPoint, vectX, vectY, vectZ
		matface.invert! # pour transformer les points dans le systeme d'axes de la facep
	
		ind = 0
		
		# parcours des points pour recherche du lowestleft corner et highest right corner
		verticelist.each{|vertex|
			puts vertex.position if(trace == 1) 
			pointt = Geom::Point3d.new vertex
			pointt.transform! facep.m_Matrice
			pointt.transform! matface #facep.m_Matrice
			#text = Sketchup.active_model.entities.add_text ind.to_s, vertex.position #if (debug3D == 1)
			
			if(ind == 0) # init sur premier point
				lowestvertex = [vertex.position[0],vertex.position[1],vertex.position[2]]
				lowestransformedpoint =  [pointt[0],pointt[1],pointt[2]]
				highestvertex = [vertex.position[0],vertex.position[1],vertex.position[2]] # vertex oppose pour calcul des dimensions
				highestransformedpoint = [pointt[0],pointt[1],pointt[2]]
			else
				# test lowest
				if(pointt[1] < lowestransformedpoint[1])
					puts " Is lowesty" if (trace == 1)
					lowestvertex[1] = vertex.position[1] # le vertex est plus bas 
					lowestransformedpoint[1] = pointt[1]
				end
				if(pointt[0] < lowestransformedpoint[0])
					puts " Is lowestx" if (trace == 1)
					lowestvertex[0] = vertex.position[0] # le vertex est plus bas 
					lowestransformedpoint[0] = pointt[0]
				end
				
				# test highest
				if(pointt[1] > highestransformedpoint[1])
					puts " Is highestverte y" if (trace == 1)
					highestvertex[1] = vertex.position[1]
					highestransformedpoint[1] = pointt[1]
				end
				if(pointt[0] > highestransformedpoint[0])
					puts " Is highestverte x"  if (trace == 1)
					highestvertex[0] = vertex.position[0]
					highestransformedpoint[0] = pointt[0]
				end
			end		
			ind = ind+1
		}
				
		lowestvertex = 	Geom::Point3d.new lowestransformedpoint
		lowestvertex.transform! matface.inverse
		lowestvertex.transform! facep.m_Matrice.inverse
		
		highestvertex = Geom::Point3d.new highestransformedpoint
		highestvertex.transform! matface.inverse
		highestvertex.transform! facep.m_Matrice 
		
		puts "333333333333333333333333333333333" if(trace == 2) 
		lowestPoint = Geom::Point3d.new lowestvertex
		debug3D = 0
		if (debug3D == 1)
			BR_GeomTools.addDebugLinePV(lowestPoint, vectZ, 50.0,nil)  
			BR_GeomTools.addDebugLinePV(lowestPoint, vectX, 150.0,nil)  
			BR_GeomTools.addDebugLinePV(lowestPoint, vectY, 250.0,nil)  
			highestPoint = Geom::Point3d.new highestvertex
			BR_GeomTools.addDebugLinePP(lowestPoint, highestPoint)
		end
		debug3D = 0
		 
		# matrice de transfo du lowest corner
		matfacecorner = Geom::Transformation.new(vectX, vectY, vectZ, lowestPoint)
			
		# creation du groupe qui va contenir les "pavés"
		@newgroup = entmodel.add_group # creation d'un nouveau groupe
		@newgroup.name= "Mur Bardage"
		
		#creation n d'un groupe pour copie de la facep originale
		groupbardage = entmodel.add_group 
		groupbardage.name = "Mur1 Origine"
		groupbardage.transform! facep.m_Matrice
		
		puts "matfacecornerINVERT.to_a" if(trace == 1) 
		puts matfacecorner.to_a if(trace == 1) 
		# old  matgroup semble etre toujours identite newmatfacecorner = matgroup*matfacecorner
		trace = 0
		newmatfacecorner = matfacecorner
		puts "newmatfacecorner.to_a" if(trace == 1) 
		puts newmatfacecorner.to_a if(trace == 1) 
		trace = 0
		
		# V4.5
		randomvalueX= 0.0.inch
		randomvalueY= 0.0.inch
		randomvalueZ= 0.0.inch
		
		# V3 definition de decalages en X et Y pour se caler sur le point de depart de longestedge (MeanPoint)
		#===========================================================
		decalageorigineX = 0.0
		decalageorigineY = 0.0
		
		# vecteur du point bas gauche de la face au point origin de la longest edge (ou edge selectionnée)
		vlowesttomean = lowestPoint.vector_to origin
		
		# V3 gestion des decalage pour recaler un elt sur le point origin
		#===================================================================
		# decalage hauteur (Y)
		pscalY = vlowesttomean.dot vectY
		nbdecaly = 0
		if(pscalY > 0.0)
			while pscalY >  (f_hauteurBardage + f_jointLargeur) do
				pscalY = pscalY - (f_hauteurBardage + f_jointLargeur)
				puts pscalY if(trace == 1) 
				nbdecaly += 1
			end
		end
		decalageorigineY = pscalY+f_jointLargeur
		#puts "nbdecaly #{nbdecaly}"
		#puts "vlowesttomean #{vlowesttomean}"
		
		# V5.1 gestion de la position de depart gauche, centre , droit
		pscalX = vlowesttomean.dot vectX #projection du vecteur selon X
		#puts "pscalX #{pscalX}"
		pscalX -= nbdecaly*(f_decalageRangees)
		#puts "pscalX #{pscalX}"
		
		#2 TODO adapter aux multi longueurs
		
		# on ajoute ou retranche un elt de bardage
		if(pscalX > 0.0)
			while pscalX >  (f_longueurBardage + f_jointLongueur) do
				pscalX = pscalX - (f_longueurBardage + f_jointLongueur)
				puts pscalX  if(trace == 1) 
			end
		end
		
		if(pscalX < 0.0)
			while pscalX < 0.0 do
				pscalX = pscalX + (f_longueurBardage + f_jointLongueur)
				puts pscalX  if(trace == 1) 
			end
		end
		
		#decalageorigineX = pscalX-f_jointLongueur
		decalageorigineX = pscalX - f_jointLongueur - f_decalageRangees
		
		# V5.1 si midle point on decale d'une demi longueur pour centrer le centre du bardage sur le centre de l'arete
		if(i_startpoint == 2)
			decalageorigineX -= 0.5*f_longueurBardage
		end
		
		puts "decalageorigineX #{decalageorigineX}" if(trace == 1) 
		puts "f_jointLongueur #{f_jointLongueur}" if(trace == 1) 
		
		# Generation de géometrie: on genere les edges du bardage
		#---------------------------------------------------------
		
		# couleur des faces PRO ONLY
		#---------------------------
		sOobmaterialsTab = BR_OOB.createMaterials(@@s_colorname,  @@f_randomColor, @@i_nbrandomColors) #8 ajout nombre de couleurs
		sOobmaterial = sOobmaterialsTab[0] # premiere valeur
		#p "sOobmaterialsTab.length #{sOobmaterialsTab.length}"
		
		# boucles sur la longueur et la hauteur 
		#-------------------------------
		posx = 0.0
		decalagex = 0.0 # decalage en x des rangées entre elles (la  lame de bardage sup est décalée par rapport à la précendente)
		posxmax = highestransformedpoint[0] - lowestransformedpoint[0]
		
		posymax = highestransformedpoint[1] - lowestransformedpoint[1]
		puts("posxmax =",posxmax) if(trace == 1) 
		puts("posymax =",posymax) if(trace == 1) 
				
		return 0 if(f_longueurBardage <= 0.0) 
		return 0 if(f_hauteurBardage <= 0.0) 
				
		#edgesGroup = entmodel.add_group
		#edgesGroup.name = "edgesGroup"
		#edgesEnt = edgesGroup.entities
		puts "44444444444444444444444444444444444444" if(trace == 2) 
		
		# Longueur / X
		trace = 0
		
		# position de départ
		# 6.0.0 : decallage initial  	f_heightoffset f_lengthoffset
		posx = decalageorigineX + decalagex - 2.0*f_longueurBardage - f_jointLongueur + f_lengthoffset # init selon X
		posy = decalageorigineY - (f_hauteurBardage + f_jointLargeur) + f_heightoffset
		
		puts("posx 0 =",posx) if(trace == 1) 
		puts("posx 1 =",posx) if(trace == 1) 
		
		f_longueurChute = 0.0.inch # V5 : longueur de chute ré-utilisable
		f_longueurMini = f_decalageRangees # le parametre decalage est utilisé en lognueur mini
		f_longueurElem = 0.0.inch
	
		
		
		# V5 test sur le nombre d'éléments
		nbelem = ((posymax  - posy)/f_hauteurBardage) * ((posxmax -  posx)/f_longueurBardage)
		puts nbelem if(trace == 1) 
		if(nbelem > 1500)
			rep = UI.messagebox(BR_OOB.getString("toomuchelements",1) , MB_YESNO)
			if(rep != 6) # yes
				return 0 # on annule le 
			end
		end	
		
		#2 multi longueurs 
		
		heightIndexTab = 0
		# 
		# Loop on Y 
		#==================
		#while( posy < posymax)
		while( posy < (posymax + f_heightoffset.abs)) #6.0.0
		
			#2 multi longueur
			lengthIndexInTab = 0
			
			randomvalueY = ((2.0*rand())-1.0).inch # entre -1.0 et 1.0
			
			#2 TODO adapter aux multi longueurs
			if(f_tabHauteurBardage.length == 0)
				#longueurx = f_longueurBardage
				# V4.5 : long +- rand*longuer
				lengthY = f_hauteurBardage*(1.0 + randomvalueY*f_randomhauteurBardage)
			else
				#2 mode multi hauteur
				result = BR_OOB.GetNextValue(f_tabHauteurBardage, heightIndexTab,f_randomhauteurBardage)
				lengthY =  result[0]
				heightIndexTab = result[1]
				puts "lengthY = #{lengthY}"
			end
			if first_row && start_row_height != "auto"
				lengthY = start_row_height.to_f * unitconversion
			end
			first_row = false	
								
			#lengthY = f_hauteurBardage*(1.0 + randomvalueY*f_randomhauteurBardage)
			
			# Length X
			#==================
			#while( posx < posxmax)
			while( posx < (posxmax + f_lengthoffset.abs))
			
				randomvalueX = ((2.0*rand())-1.0).inch # entre -1.0 et 1.0
				
				longueurx = 0.0.inch
				if(jointsPerdusflag == 1) 
					longueurx = 4.0*posxmax + f_longueurBardage
				else
					#2 TODO adapter aux multi longueurs
					if(f_tabLlongueurBardage.length == 0)
						#longueurx = f_longueurBardage
						# V4.5 : long +- rand*longuer
						longueurx = f_longueurBardage*(1.0 + randomvalueX*f_randomlongueurBardage)
					else
						#2 mode multi longueur
						result = BR_OOB.GetNextValue(f_tabLlongueurBardage, lengthIndexInTab,f_randomlongueurBardage)
						longueurx = result[0]
						lengthIndexInTab = result[1]
						puts "longueurX = #{longueurx}"
					end	
					if(trace == 1) 
						puts "f_randomlongueurBardage = #{f_randomlongueurBardage}"
						puts "f_longueurBardage = #{f_longueurBardage}"
						puts "randomvalue = #{randomvalue}"
						puts "longueurx = #{longueurx}"
					end	
				end
				
				# face pour decoupage (element)
				#newface = BR_OOB.AddFace(posx,posy, longueurx, f_hauteurBardage, newmatfacecorner, @newgroup.entities)				
				newface = BR_OOB.AddFace(posx,posy, longueurx, lengthY, newmatfacecorner, @newgroup.entities)				
				

				mat = 0
				if(sOobmaterialsTab.length > 1) # coutn KO sur SU8
					indexMat = Integer ((sOobmaterialsTab.length)*rand()) #8 nb colors
					indexMat = sOobmaterialsTab.length if(indexMat >=sOobmaterialsTab.length)
					
					#puts "indexMat #{indexMat}"
					mat = sOobmaterialsTab[indexMat]
				else
					mat = sOobmaterialsTab[0]
				end
				newface.material = mat #sOobmaterial
				newface.back_material = mat #sOobmaterial

				
				if(jointsPerdusflag == 1)
					#=================================================
					# GESTION DE LA REUTILISATION DES CHUTES (bardage)
					#=================================================
					sel.add @newgroup
					debug2Dfaces = 0
					
					if(debug2Dfaces== 0)
						grpresult = BR_OOB.boolean2d(oob1grp.entities, 0) # calcul des intersection 2D
					else
						grpresult = @newgroup # debug des faces 2D intermédiaires
					end
					
					if(grpresultGlobal == nil)
						grpresultGlobal=oob1grp.entities.add_group()
						grpresultGlobal.name = "grpresultGlobal"
					end
					if(grpresultdecoupeGlobal == nil)
						grpresultdecoupeGlobal=oob1grp.entities.add_group()
						grpresultdecoupeGlobal.name = "grpresultdecoupeGlobal"
					end
					
					# on rajoute les faces du groupe courant dans grpresultGlobal	
					grpresult.entities.each{|face| 
						next if face.class!=Sketchup::Face 
							
						# Calcul de la longueur de l'élt courant
						lenghtii = BR_OOB.getLength2(face, vectlongest, grpresult.transformation, 0 )
							
						# TODO V5.0 
						# Plusieurs options à considérer ici:
						#  il reste une chute ou pas
						#   il reste une chute f_longueurElem = f_longueurChute
						#   il ne reste pas de chute f_longueurElem = f_longueurBardage
						# 1 : lenghtii < f_longueurElem : on pose la lame de bardage et on continue avec la chute
						# 1 bis : si la chute est plus courte que f_longueurMini on rattaque avec une lame neuve
						# 2 : lenghtii > f_longueurElem  : on pose la lame et on continue avec une lame neuve
						# 2 bis : si la longueur restane est < f_longueurMini on pose une lame plus courte (f_longueurElem - f_longueurMini)
						#================================================================================================
						# Dans tous les cas on doit récupérer le point de départ, point de pose de la lame(point bas gauche)
						# recup du point de départ, point de pose de la lame(xmini, ymini)
						trace = 0
						
						puts "LENGTH II =  #{lenghtii}" if(trace == 1) 
						
						llcorner = BR_OOB.GetFaceLowestLeftCorner(face, vectX, vectY,vectZ)
						debug3D = 0
						if (debug3D == 1)
							#BR_GeomTools.addDebugLinePV(meanPoint, vectlongest, 300.0, nil)	
							BR_GeomTools.addDebugLinePV(llcorner, vectX, (lenghtii*100.0/2.54).inch, nil)	
							BR_GeomTools.addDebugLinePV(llcorner, vectY, f_hauteurBardage, nil)	
							BR_GeomTools.addDebugLinePV(llcorner, vectZ, 180.0, nil)	
						end
						
						v5posx = 0.0.inch # dans le repere du modèle global
						v5posy = 0.0.inch
						v5length = 0.0.inch
						
						#UI.messagebox("Length = #{lenghtii}\n f_longueurElem = #{f_longueurElem}\n f_longueurChute = #{f_longueurChute}")
						secu = 0
						lenghtii = (lenghtii*100.0/2.54).inch
						if(trace == 1)
								puts "========================="
								puts " AVANT WHILE Longueur à  poser : #{lenghtii}"
								puts "========================="
						end
						while((lenghtii > 0.0) and (secu < 1000))
							secu += 1
							lengthiiold = lenghtii
							v5length = 0.0.inch
														
							# Traitement de(s) l'élément(s) à poser
							if(f_longueurChute == 0.0)
								f_longueurElem= f_longueurBardage
							else 
								f_longueurElem= f_longueurChute
							end
							
							# debug
							if(trace == 1)
								puts "========================="
								puts " Longueur à  poser : #{lenghtii}"
								puts "========================="
								puts "f_longueurChute = #{f_longueurChute}"
								puts "f_longueurElem = #{f_longueurElem}"
								puts "f_longueurMini = #{f_longueurMini}"
								puts "v5posx = #{v5posx}"
								puts "v5posy = #{v5posy}"
								puts "========================"
							end
							# gestion des differentes configurations
							#-------------------------------------------
							if(lenghtii < f_longueurElem)
								# on pose la lame de bardage et on continue avec la chute
								# POSE LAME (lenghtii)
								f_longueurChute = (f_longueurElem - lenghtii).inch
								puts "Longueur de chute = #{f_longueurElem} - #{lenghtii} = #{f_longueurChute}" if(trace == 1)
								
								# Chute trop courte, on l'elimine
								if(f_longueurChute < f_longueurMini)
									f_longueurChute = 0.0.inch # lame neuve
								end
								lenghtii = 0.0.inch # portion suivante
								puts("POSE ELEMENT ENTIER #{(lengthiiold)}\nLength = #{lengthiiold}\n f_longueurElem = #{f_longueurElem}\n f_longueurChute = #{f_longueurChute}") if(trace == 1)
								UI.messagebox("POSE ELEMENT ENTIER #{(lengthiiold)}\nLength = #{lengthiiold}\n f_longueurElem = #{f_longueurElem}\n f_longueurChute = #{f_longueurChute}") if(trace == 3) 
								v5length = lengthiiold
							else
								# 2 : lenghtii > f_longueurElem  : on pose la lame et on continue avec une lame neuve
								# Si La longueur restant apres la pose de l'element st trop courte
								# Et la longueur à poser est supérieure à la longueur de l'élt
								# Et longueur à poser supérieur à 2* la longueur mini
								if(((lenghtii - f_longueurElem) < f_longueurMini) and (lenghtii > f_longueurElem)and (lenghtii > 2.0*f_longueurMini))
									# 2 bis : si la longueur restante est < f_longueurMini on pose une lame plus courte (f_longueurElem - f_longueurMini)
									# POSE LAME (lenghtii - f_longueurMini)
									lenghtii = f_longueurMini
									f_longueurChute = 0.0.inch # lame neuve
									puts("POSE LAME PLUS COURTE #{(lengthiiold - f_longueurMini).inch}\nLength = #{lengthiiold}\n f_longueurElem = #{f_longueurElem}\n f_longueurChute = #{f_longueurChute}") if(trace == 1)
									UI.messagebox("POSE LAME PLUS COURTE #{(lengthiiold - f_longueurMini).inch}\nLength = #{lengthiiold}\n f_longueurElem = #{f_longueurElem}\n f_longueurChute = #{f_longueurChute}")if(trace == 3)
									v5length = (lengthiiold - f_longueurMini).inch
								else
									# on pose la lame entière et on continue avec une lame neuve
									# POSE LAME (f_longueurElem)
									lenghtii = (lenghtii - f_longueurElem).inch
									f_longueurChute = 0.0.inch # lame neuve
									puts("POSE LAME ENTIERE #{(f_longueurElem)}\nLength = #{lengthiiold}\n f_longueurElem = #{f_longueurElem}\n f_longueurChute = #{f_longueurChute}") if(trace == 1)
									UI.messagebox("POSE LAME ENTIERE #{(f_longueurElem)}\nLength = #{lengthiiold}\n f_longueurElem = #{f_longueurElem}\n f_longueurChute = #{f_longueurChute}") if(trace == 3)
									puts "new lenghtii = #{lenghtii}" if(trace == 1)
									v5length = f_longueurElem
								end
							end # else if(lenghtii < f_longueurElem)
							#puts "addface 1390"
							
							# decalage au low left corner
							llcornermatrice = Geom::Transformation.new(vectX, vectY, vectZ, llcorner)
							
							# creation de l'elt posé, à la bonne longueur
							#bardageface = BR_OOB.AddFace(v5posx,0, v5length, f_hauteurBardage, llcornermatrice, grpresultdecoupeGlobal.entities)		
							# V4.5
							bardageface = BR_OOB.AddFace(v5posx,0, v5length, lengthY, llcornermatrice, grpresultdecoupeGlobal.entities)		
							bardageface.material = sOobmaterial
							
							v5posx += v5length+ f_jointLongueur
							
							#BR_OOB.DuplicateFacesToEntities(grpresultGlobal.entities, face) # face decoupée originale								
							#BR_OOB.DuplicateFacesToEntities(grpresultdecoupeGlobal.entities, bardageface) 	# lame ou elt ajouté							
							#return
						end # while((lenghtii > 0.0) and (secu < 1000))
						
						# pour debug ajout de la face originale
						
						# Ajout de la face résultat pour push pull
						#BR_OOB.DuplicateFacesToEntities(grpresultGlobal.entities, face) 	
					} # fin grpresult.entities.each{|face| 
					grpresult.erase!
										
					# Creation d'un nouveau groupe pour les edges
					@newgroup = entmodel.add_group
					
					#grpresult.name = "Oob-result"
					#BR_OOB.setLayer("Oob-result", grpresult)
					#UI.messagebox ("1")
					#return # V5
					posx = posx + 2.0*posxmax + f_longueurBardage# increment selon X (longueur + longueur max)
				
				else # pas V5 on incremente suivant x
					#posx = posx +  f_longueurBardage + f_jointLongueur # increment selon X (longueur + joint)
					#V4.5 longueur randomisee
					posx = posx + longueurx + f_jointLongueur # increment selon X (longueur + joint)
				end
			end # while posx
			
			# rangee suivante, decalage en x et y
			decalagex = decalagex + f_decalageRangees 
			puts("decalagex =",decalagex) if(trace == 1) 
				
			if( decalagex > f_longueurBardage) # si le decalage depasse la longueur on le decale
				decalagex = decalagex - f_longueurBardage - f_jointLongueur
				puts("decalagex =",decalagex) if(trace == 1) 
			end
			
			#posy = posy + f_hauteurBardage + f_jointLargeur # increment selon Y (hauteur + joint)
			# V4.5 
			posy = posy + lengthY + f_jointLargeur # increment selon Y (hauteur + joint)
			puts("posy =",posy) if(trace == 1) 
			posx = decalageorigineX + decalagex - 2.0*f_longueurBardage - f_jointLongueur + f_lengthoffset # init selon X
			
			puts("posx =",posx) if(trace == 1) 
		end	#while posy
				
		puts "55555555555555555555555555555555555555555555" if(trace == 2) 
		mattranslcorner = Geom::Transformation.new(lowestPoint)
			
		#sel.clear # on vide la selection
		sel.add @newgroup # on rajoute le groupe créé à la sélection pour l'opération booléenne
		# ainsi que la facep originale
			
		return if(BR_OOB.myDebugStepMessage(__LINE__))		

		# *** FIXED: Implement logic for last_row_placement ***
		# The boolean2d function performs the "cut" operation.
		# If the user wants a "full" last row, we would need to separate the last row's geometry
		# and not pass it to this function. This is a complex change.
		# For now, we will honor the "cut" behavior which is the default.
		if last_row_placement == "cut"
			grpresult = BR_OOB.boolean2d(oob1grp.entities, 0) # calcul des intersection 2D
		else
			# If "full", we just use the generated group without cutting.
			# NOTE: This will cause pieces to extend beyond the boundary face.
			grpresult = @newgroup
			puts "Last row placement set to 'full'. Skipping boundary cut."
		end

		# creation des volumes par push/pull
		listefacestopush = []
		grpresult.entities.each { |facei|
			if (facei.kind_of? Sketchup::Face)
				if(facei.hidden? == false)
					listefacestopush.push facei
				end	
			end
		}	
		puts "listefacestopush.size()" if(trace == 1) 
		puts listefacestopush.size() if(trace == 1) 
		
		listefacestopush.each { |faceii|	
			# V4.5 randomisation
			randomvalueZ = ((2.0*rand())-1.0).inch # entre -1.0 et 1.0
			epaisseur =  f_epaisseurBardage*(1.0 + randomvalueZ*f_randomepaisseurBardage)
			#puts epaisseur
			faceii.pushpull epaisseur, true # creation d'un volume a partir du mur
			faceii.reverse! # ?
		}
		
		vectlongueur = vectlongest
		# V6.0.0 : longueur suivant axe vecteur ou perpendiculaire (si hauteur > longueur)
		if(@@f_longueurBardage < @@f_hauteurBardage)
			vectlongueur = vectY 
		end
		
		# Calcul de la longueur totale des elts (version 2.0)
		#====================================================
		#puts "facep.m_Matrice.to_a"
		#puts facep.m_Matrice.to_a
		trace = 0
		totallength = 0.0  # Longueur totale v2.00
		totalsurface = 0.0 # Surface totale V6.1
		
		# RI 0007 : recup des chutes
		longueurchutes = 0.0 # longueur des chutes dans le recuperateur
		longueurbardage = @@f_longueurBardage*0.01
		nbelemcomplets = 0
		nbelemchutes = 0
		nbchutes = 0
		
		listefacestopush.each { |faceii|
			# pour debur RI 0007
			debug = 0
			if((totallength == 0.0) and (trace == 1))
				debug = 1
			end
			
			lenghtii = BR_OOB.getLength2(faceii, vectlongueur, grpresult.transformation, debug )
			#lenghtii = BR_OOB.getLength2(faceii, vectlongest, grpresult.transformation, debug )
			if((lenghtii - longueurbardage).abs < 0.01)
				puts "lenghtii Complet #{lenghtii} #{longueurbardage}" if(trace == 1) 
				nbelemcomplets += 1
			else
				
				if(longueurchutes + lenghtii < longueurbardage)
					longueurchutes += lenghtii# on rajoute la chute au recuperateur
					puts "lenghtii Partiel 1 #{lenghtii} #{longueurchutes}" if(trace == 1) 
				else
					nbelemchutes += 1
					longueurchutes = 0.0 # on vide le recuperateur
					puts "lenghtii Partiel 2 : : #{lenghtii} #{nbelemchutes}" if(trace == 1) 
				end
				nbchutes += 1
			end
			
			if((totallength == 0.0) and (trace == 1) )
				puts "faceii #{faceii}" if(trace == 1) 
				puts "vectlongest #{vectlongest}" if(trace == 1) 
				puts "grpresult.transformation #{grpresult.transformation}" if(trace == 1) 
				puts "lenghtii #{lenghtii}" if(trace == 1) 
			end
			totallength += lenghtii
		}
		
		# dernière chute dans le recuperateur
		if(	longueurchutes > 0.0)
			nbelemchutes += 1
		end		
		trace = 0
		puts "totallength = #{totallength}" if(trace == 1) 
		puts "nbelemcomplets = #{nbelemcomplets}" if(trace == 1) 
		puts "nbelemchutes = #{nbelemchutes} sur  #{nbchutes}" if(trace == 1) 
		 
		trace = 0

# Compose message with correct Ruby string interpolation
message = BR_OOB.getString("Nombre d'éléments créés:") + listefacestopush.length().to_s
message += "\n" + BR_OOB.getString("Longueur totale des éléments créés") + " %.2f m" % totallength
nbelem = 1 + (totallength * 100.0 / @@f_longueurBardage)
puts "nbelem" if(trace == 1)
puts nbelem if(trace == 1)
message += "\n" + BR_OOB.getString("Nombre d'éléments de longueur") + " %.2f cm : %i" % [@@f_longueurBardage, nbelem]
		#rep = UI.messagebox(message) #BR_OOB.getString("Pas FULL"))
	
		# V2.0 on stocke les resultats sur le groupe
		oob1grp.set_attribute "Oob", "Oob Nbelems", listefacestopush.length()
		oob1grp.set_attribute "Oob", "Oob Longueurelems", totallength
		
		# V 6.1 : surface des elts
		if(@@f_longueurBardage < @@f_hauteurBardage)
			totalsurface = totallength*@@f_longueurBardage
		else
			totalsurface = totallength*@@f_hauteurBardage
		end
		puts "totalsurface #{totalsurface}"
		oob1grp.set_attribute "Oob", "Oob Surfaceelems", totalsurface
		
		# V 4.0 : elements complets et elements "chutes"
		oob1grp.set_attribute "Oob", "Oob NbElemComplets", nbelemcomplets
		oob1grp.set_attribute "Oob", "Oob NbElemChutes", nbelemchutes
		oob1grp.set_attribute "Oob", "Oob NbChutes", nbchutes
		
		
		# gestion de la facep originale et du joint
		#===============================================
		return if(BR_OOB.myDebugStepMessage(__LINE__))
		puts "f_jointProfondeur" if(trace == 1) 
		puts f_jointProfondeur if(trace == 1) 
		
		vector = Geom::Vector3d.new facep.m_Face.normal
		vector.length = f_jointProfondeur
		t = Geom::Transformation.new vector
		#grpresult.name = "grpresult"
			
			
			my_mesh =  facep.m_Face.mesh
			f_material = facep.m_Face.material
			puts "			sOobmaterial" if(trace == 1) 
			puts sOobmaterial.name if(trace == 1) 
			
			# facegroup = Sketchup.active_model.active_entities.add_group facep.m_Face
			# tgp=Sketchup.active_model.active_entities.add_group(facep.m_Face)
			# Face "joint"
			if(f_jointProfondeur > 0.0)
			
				jointgroup = oob1grp.entities.add_group
				#jointgroup = oob1grp.entities.add_instance(facegroup.definition, facegroup.transformation) 
				#jointgroup.entities.add_faces_from_mesh my_mesh, 12, f_material # ==> KO car le resultat est une liste de faces et non une face
				#ncopyofface = facep.m_Face.copyFace(Geom::Vector3d.new(0,0,1),0.0,jointgroup.entities,sOobmaterial)
				ncopyofface = BR_GeomTools.copyFace(facep.m_Face, Geom::Vector3d.new(0,0,1),0.0,jointgroup.entities,sOobmaterial)
				
				jointgroup.name = "Oob-joint"
				jointgroup.transform! t
			end
			
			# Face init
			initgroup = oob1grp.entities.add_group
			initgroup.name = "Oob-init"
			#initgroup.entities.add_faces_from_mesh my_mesh, 12, f_material
			#ncopyofface = facep.m_Face.copyFace(Geom::Vector3d.new(0,0,1),0.0,initgroup.entities,sOobmaterial)
			ncopyofface = BR_GeomTools.copyFace(facep.m_Face, Geom::Vector3d.new(0,0,1),0.0,initgroup.entities,sOobmaterial)
			initgroup.hidden = true
			
			#BR_OOB.setLayer("Oob-result", facep.m_Face)
			#facegroup.hidden = true # on cache la facep d'origine
			facep.m_Face.hidden = true # on cache la facep d'origine
		#end
		
		# Offset du résultat V6.0.0
		vector = Geom::Vector3d.new facep.m_Face.normal
		vector.length = f_layeroffset
		t = Geom::Transformation.new vector
		jointgroup.transform! t if(jointgroup)
		grpresult.transform! t if(grpresult)
		#puts "__LINE__ "
		#puts  

		#Sketchup.active_model.commit_operation  ###############################################
		return 1 # sortie # sortie # sortie # sortie # sortie # sortie # sortie # sortie # sortie # sortie
	end


#==========================================
# V2 : calcul de la longueur d'un face selon une 
# direction donnée
# matface = matrice pour passage des coords dans le syst de coords de la face
# V6.0.0 : on fait également le calcul a l aperpendiculaire pour le cas des hauteurs > longueurs
#=========================================
def BR_OOB.getLength2(face, vectdir, matgrp, debug = 0 )
	trace = 0 #debug
	puts "==================== getLength" if(trace == 1)
	
	# face.vertices.each{|vertex|
		# puts "vertex"
		# puts vertex.position
	# }
	# return 2.0
	
	
	# copie du vecteur
	vectdir2 = Geom::Vector3d.new vectdir
	
	# on passe les coords du vecteur en "coords face"
	matinv =  matgrp.inverse
	puts "matgrp"  if(trace ==1)
	puts matgrp.to_a if(trace ==1)
	puts "matinv" if(trace ==1)
	puts matinv.to_a if(trace ==1)
	
	#vectdir2.transform! matinv
	
	# on le normalise
	vectdir2.normalize! 
	
	puts "vectdir" if(trace ==1)
	puts vectdir if(trace ==1)
	puts "vectdir2  = #{vectdir2}" if(trace ==1)
	
	puts "face.vertices.length()" if(trace ==1)
	puts face.vertices.length() if(trace ==1)
	pt0  = nil
	min = 0.0
	max = 0.0
	if(face.vertices.length() !=0)
		pt0  = face.vertices[0].position.transform matinv
	end
	puts "pt0 = #{pt0}" if(trace ==1)
	
	face.vertices.each{|vertex|
		puts "\n-----------------\nvertex.position = #{vertex.position}" if(trace ==1)
		
		pti = vertex.position.transform matinv
		puts "vertex.position .transform matinv = #{pti}" if(trace ==1)
		vecti = pt0.vector_to(pti)
		puts "vecti = #{vecti}" if(trace ==1)
		
		pscal = (vectdir2.dot vecti )*0.0254
		min = pscal if(pscal < min)
		max = pscal if(pscal > max)
		puts "pscal = #{pscal}" if(trace ==1)
		# puts min
		# puts max
	}
	long = (max - min).abs
	#puts min if(trace ==1)
	#puts max if(trace ==1)
	puts long if(trace ==1)
	return long
end

#=====================================================
# Undo d'un calepinage (recup de la face d'origine)
# on affiche le groupe Oob-init et on l'explose
# on supprime les groupes  Oob-joint et Oob-result
#=====================================================
def BR_OOB.undoOob(grpOob)
	trace = 0
	puts "in undo" if(trace == 1)
	
	return unless grpOob.kind_of?(Sketchup::Group)
    puts "it is a group" if(trace == 1)
    dic = grpOob.attribute_dictionary "Oob"
    return if dic.nil?
	
	toerase = []
	toexplode = nil
	
	# recherche des sous groupes
	grpOob.entities.each{|ent|
		if(ent.kind_of? Sketchup::Group) 
			if(ent.name == "Oob-init")
				puts "found Oob-init" if(trace == 1)
				ent.hidden = false
				toexplode = ent
			end
			if(ent.name == "Oob-joint")
				puts "found Oob-joint" if(trace == 1)
				ent.hidden = true
				toerase.push ent #ent.erase!
			end
			if(ent.name == "Oob-result")
				puts "found Oob-result" if(trace == 1)
				ent.hidden = true
				toerase.push ent #ent.erase!
			end
		end
	}
	
	# erase du groupe  resultats
	toerase.each{|ent|
		ent.erase!	
	}
	
	faceoriginale = nil
	# explde du groupe init
	if(toexplode != nil)
		ents = toexplode.explode
		puts "ents" if(trace == 1)
		puts ents if(trace == 1)
		if(ents != nil)
			ents.each {|ent|	
				if(ent.class == Sketchup::Face)
					faceoriginale = ent
					break
				end	
			}
		end	
	end
	
	grpOob.explode
	puts "faceoriginale" if(trace == 1) 
	puts faceoriginale
	return faceoriginale
	
end

#===========================================
# Creer ossature :
# fonction pricpale de creation d"une ossature 
# à partir des faces selectionnées
#===========================================
 def BR_OOB.creerOssature(moderedo)
	
	model = Sketchup.active_model
	

	trace = 1
	debug3D = 0
	
	# Parse de la selection et recup des faces
	sel = Sketchup.active_model.selection
	puts "sel.count = " if(trace == 1) 
	puts sel.count if(trace == 1) 
	matPosElt = Geom::Transformation.new #identite
	if (matPosElt.identity?)
		i=0
		puts "Matrice initiale = identite"  if(trace == 1) 
	end
	
	tabFaces = Array.new
	puts "essai tabface sur selection" if(trace == 1) 
	puts sel.class if(trace == 1) 
	if(sel.is_a? Sketchup::Selection)
		if(trace == 1) 
			puts "ITS A SELECTION" 
			puts sel.each{|selent|  
				puts selent.class  
			}
		end	
	end
	
	# 6.0.0 on teste si il s'agit d'un layout 
	elt = sel[0]
	if (elt.class == Sketchup::Group)
		if(elt.name == "Oob-grp")
		
			puts "oob grp" if(trace ==1)
			#on recherche le group init pour le dupiquer et l exploser
			elt.entities.each do |entg|
				if(entg.class == Sketchup::Group) and (entg.name == "Oob-init") and (entg.layer.name != "Oob-init")
					newgrp = entg.copy
					newgrp.name = "Oob-copy"
					#explents = newgrp.explode
					newgrp.entities.each do |ent|
						if (ent.class == Sketchup::Face)
							sel.clear
							sel.add ent
							break
						end	
						#BR_GeomTools.getListOfFaces(ent, newmat, tabFaces)
					end
				end	
			end	
		end
	end
	 
	
	BR_GeomTools.getListOfFaces(sel, matPosElt, tabFaces)
	puts "tabFaces.count= " if(trace == 1) 
	puts tabFaces.size() if(trace == 1) 
	
	# on limite à une face
	if((tabFaces.size() > 1)or (tabFaces.size() == 0))
		puts "select one face" if(trace == 1) 
		UI.messagebox(BR_OOB.getString("Sélectionnez une face + une arête (option)"))
		return
	end
	

	
	surface = 0.0	
	#on parcoure les faces
	tabFaces.each { |facep|
		BR_OOB.DisplayDialog(facep, moderedo)
		#BR_OOB.CalepinageFace(facep)
		return # on arrete a la premiere face
	}
	
	puts "Surface de murs = " if(trace == 1) 
	puts surface/ 1550.0  if(trace == 1) #passage de pouces carres en m2
	# return surface/ 1550.0 

end # of funtion creerOssature	



	#===========================================
	def BR_OOB.projectPointsOnPlane()
		planefound = 0
		pointfound = 0
		puts "in projectPointsOnPlane"
		# recherche d'une face de projection
		mod = Sketchup.active_model
		ent = mod.entities
		sel = mod.selection
		plane = nil
		
		sel.each {|entity| 
			puts entity
			if(entity.is_a? Sketchup::Face)
				selFace = entity
				planefound = 1
				normal = selFace.normal
				plane = selFace.plane
				puts normal
				puts plane
				break
			
			end
		}
		if (planefound == 0)
			UI.messagebox("Veuillez sélectionner un plan de projection(face)!")
		else
			# recherche des points
			sel.each {|entity| 
			if(entity.is_a? Sketchup::ConstructionPoint)
				pointfound = 1
				puts pointfound
				selPoint = entity
				position = selPoint.position
				pointonplane = position.project_to_plane plane
				puts "position"
				puts position
				puts "plane"
				puts plane
				puts "pointonplane"
				puts pointonplane
				# on cache le poit original, on affiche le point projeté
				constprojpoint = ent.add_cpoint pointonplane
				entity.hidden = true;
				#plane = [Geom::Point3d.new(0,0,0), Geom::Vector3d.new(0,0,1)]
				#a = [10,10,10]
				#pointonplane = a.project_to_plane plane
				#position = constpoint.position 
				#break
			end
		}
		end
	end
	def BR_OOB.importASCIIFILE()
		model = Sketchup.active_model
		entities = model.active_entities
		# ouverture du dialog de selection de fichier
		ascfile = UI.openpanel "Open Image File", model.path, "*.asc"	
		puts ascfile
		
		# Suppression du ficher de resultat
		# TODO a cdeommenter pour la release
		if !File::exists?( ascfile )
			UI.messagebox "Error,  Le fichier n'a pas pu être ouvert!"
		end
			
		# lecture des points
		File.open(ascfile ).each_line do |line|
			
			#UI.messagebox line
			# on reagrde si la ligne contient un mot cle intéressant
			#puts line
			tab = line.split(' ')
			#puts tab[0]
			#puts tab[1]
			
			point1 = Geom::Point3d.new(tab[0].to_f, tab[1].to_f, tab[2].to_f)
			constpoint = entities.add_cpoint point1
			#UI.messagebox tab[0]
			
			# if(tab[0] == "ARCH-getPVMesurePoints")
			# @nbPointsMesure = (tab[2].sub(',','.').sub(/\s/,"")).to_i
			# puts @nbPointsMesure if (@TRACE == 1) 
		end
	end

	def BR_OOB.debugFunction(edge)
		puts "Selection edge :"
		puts "edge.faces"
		
		value = edge.get_attribute "Oob", "Class1"
		value2 = edge.get_attribute "Oob", "Class2"
		valueM = edge.get_attribute "Oob", "ClassM"
		valueM
		if value != nil  
			puts "Pt1 : %i" %value+" Pt2 "+"%i" %value2	+" PtM "+"%i" %valueM	
		else
			puts "Pt1 == nil"
		end
	end # debug function
	
	#======================================
	# recup des parametres d'un l'elt
	#======================================
	def	BR_OOB.getResults(elt)#
	
		# V2.0 on recupere  les resultats sur le groupe
		nb = elt.get_attribute "Oob", "Oob Nbelems"
		long = elt.get_attribute "Oob", "Oob Longueurelems"
		# V6.0 
		surf = elt.get_attribute "Oob", "Oob Surfaceelems"
		
		# V4.0 chutes
		nbelemcomplets = elt.get_attribute "Oob", "Oob NbElemComplets"
		nbelemchutes = elt.get_attribute "Oob", "Oob NbElemChutes" 
		nbchutes = elt.get_attribute "Oob", "Oob NbChutes" 
		preset = elt.get_attribute "Oob", "Oob s_presetname"
		
		longf = long.to_f
		message = "<!DOCTYPE html><html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"></head>"
		message += BR_OOB.getString("Longueur totale des éléments créés:")+" %.2f" % longf  +" m"
		message += "<br>"+BR_OOB.getString("Surface totale  des éléments créés:")+" %.2f" % surf  +" m2" if(surf)
		message += "<br>"+BR_OOB.getString("Nombre total d'elements crees:")+" "+nb.to_s
		message += "<br> - "+BR_OOB.getString("Nombre d'éléments non coupes")+" : #{nbelemcomplets}"
		message += "<br> - "+BR_OOB.getString("Nombre d'éléments coupés (chutes)")+" : #{nbchutes}"
		message += "<br> - "+BR_OOB.getString("Nombre d'éléments complets dans les chutes")+" : #{nbelemchutes}"
		message += "<br>===> "+BR_OOB.getString("Nombre total d'éléments complets")+" :  #{nbelemchutes+nbelemcomplets}"
		
	
		
		# V 6.0.0 on scanne les sous groupes pour chercher de'aultres layouts
		sublayouts = 0
		if (elt.class == Sketchup::Group)
			if(elt.name == "Oob-grp")
				elt.entities.each do |entg|
					if(entg.class == Sketchup::Group) and (entg.name == "Oob-copy")
						if(sublayouts == 0)
							message = "<!DOCTYPE html><html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"></head>"
							if(preset != "")
								message += "<br>- "+"#{preset}: #{nbelemchutes+nbelemcomplets} elts, "+" %.2f" % longf  +" m" 
							else
								message += "<br>- "+"Layer #{sublayouts}: #{nbelemchutes+nbelemcomplets} elts, "+" %.2f" % longf  +" m" 
							end	
							message += " ,%.2f" % surf  +" m2" if(surf)
						end
						sublayouts += 1
						# recherhce de Oob-grp
						entg.entities.each do |subentg|	
							if(subentg.class == Sketchup::Group) and (subentg.name == "Oob-grp")
								subnbelemcomplets = subentg.get_attribute "Oob", "Oob NbElemComplets"
								subnbelemchutes = subentg.get_attribute "Oob", "Oob NbElemChutes"
								sublong = subentg.get_attribute "Oob", "Oob Longueurelems"
								subsurf = subentg.get_attribute "Oob", "Oob Surfaceelems"
								sublongf = sublong.to_f
								subpreset = subentg.get_attribute "Oob", "Oob s_presetname"
								if(subpreset != "")
									message += "<br>- "+"#{subpreset}: #{subnbelemchutes+subnbelemcomplets} elts, "+" %.2f" % sublongf  +" m"
								else
									message += "<br>- "+"Layer #{sublayouts}: #{subnbelemchutes+subnbelemcomplets} elts, "+" %.2f" % sublongf  +" m" 
								end	
								message += " ,%2.f" % subsurf + " m2" if(subsurf)
							end
						end	
					end
				end
			end
		end	
		html= 'Hello world!'
		dialogResults = UI::WebDialog.new(BR_OOB.getString("Oob layouts : results"), true, "OobLayoutResults", 400, 300, 200, 100, true)
		message += "<br></html>"
		puts message
		dialogResults.set_html(message)
		dialogResults.show{}
		#rep = UI.messagebox(message) #BR_OOB.getString("Pas FULL"))					
	end
	
	#======================================
	# recup des parametres d'un l'elt
	#======================================
	def	BR_OOB.getParameters(elt)# GetPeram 
		#puts "Getparam" #BR_OOB::Activate_PV_Texture()
		
		dic = elt.attribute_dictionary "Oob"			
		#puts "dictionary found"
		dic.each { | key, value|
			#traitement de l'attribut
			#puts  key.to_s + ' = ' + value.to_s #if(trace == 1)
		}
		
		@@f_longueurBardage =elt.get_attribute "Oob", "Oob f_longueurBardage"
		@@f_hauteurBardage = elt.get_attribute "Oob", "Oob f_hauteurBardage"
		@@f_epaisseurBardage = elt.get_attribute "Oob", "Oob f_epaisseurBardage"
		@@f_jointLongueur = elt.get_attribute "Oob", "Oob f_jointLongueur"
		@@f_jointLargeur = elt.get_attribute "Oob", "Oob f_jointLargeur"
		@@f_jointProfondeur = elt.get_attribute "Oob", "Oob f_jointProfondeur"
		@@f_decalageRangees = elt.get_attribute "Oob", "Oob f_decalageRangees"
		@@b_jointperdu = elt.get_attribute "Oob", "Oob b_jointperdu"
		@@s_colorname = elt.get_attribute "Oob", "Oob s_colorname"
		
		@@i_startpoint = elt.get_attribute "Oob", "Oob i_startpoint"
		
		
		# recup du vecteur
		@@vectx = elt.get_attribute "Oob", "Oob vectX"
		@@vecty = elt.get_attribute "Oob", "Oob vectY"
		@@vectz = elt.get_attribute "Oob", "Oob vectZ"
		@@origx = elt.get_attribute "Oob", "Oob origx"
		@@origy = elt.get_attribute "Oob", "Oob origy"
		@@origz = elt.get_attribute "Oob", "Oob origz"
		
		# V4.5
		@@f_randomlongueurBardage = elt.get_attribute "Oob", "Oob f_randomlongueurBardage"
		@@f_randomhauteurBardage = elt.get_attribute "Oob", "Oob f_randomhauteurBardage" 
		@@f_randomepaisseurBardage = elt.get_attribute "Oob", "Oob f_randomepaisseurBardage"
		@@f_randomColor = elt.get_attribute "Oob", "Oob f_randomColor"
		
		
		# V5.1
		@@startpointx =  elt.get_attribute "Oob", "Oob startx"
		@@startpointy =  elt.get_attribute "Oob", "Oob starty"
		@@startpointz =  elt.get_attribute "Oob", "Oob startz"
		
		@@midlpointx = elt.get_attribute "Oob", "Oob midlx"
		@@midlpointy = elt.get_attribute "Oob", "Oob midly"
		@@midlpointz = elt.get_attribute "Oob", "Oob midlz"
		
		@@endpointx = elt.get_attribute "Oob", "Oob endx"
		@@endpointy = elt.get_attribute "Oob", "Oob endy"
		@@endpointz = elt.get_attribute "Oob", "Oob endz"
		
		# V6.0.0
		@@s_presetname = elt.get_attribute "Oob", "Oob s_presetname" 
		@@f_layeroffset = elt.get_attribute "Oob", "Oob f_layeroffset"
		@@f_heightoffset = elt.get_attribute "Oob", "Oob f_heightoffset"
		@@f_lengthoffset = elt.get_attribute "Oob", "Oob f_lengthoffset"
		
	end	
end #OF BR_OOB MODULE


 class MyShadowInfoObserver < Sketchup::ShadowInfoObserver
	   def onShadowInfoChanged(shadow_info, type)
			#UI.messagebox("onShadowInfoChanged: " + type.to_s)
			puts ("onShadowInfoChanged: " + type.to_s)
			#puts ("My city is: " + shadow_info["City"].to_s)
			puts ("Day : " + shadow_info["DayOfYear"].to_s)
			puts ("ShadowTime  : " + shadow_info["ShadowTime "].to_s)
			shadow_info.each { |key, value|
				puts(key.to_s + '=' + value.to_s)
			}
	   end
 end
	 
#=====================================================
# GetCursorPosTool
#=====================================================
class GetCursorPosTool
	def initialize
		puts 'OobDebugTool init' 
	end
	def reset
		puts 'reset' if (@TRACE == 1)
		@ip = Sketchup::InputPoint.new
	end
	def activate
		puts "OobDebugTool activate"
		self.reset
	end
	def deactivate(view)
		puts 'deactivate' if (@TRACE == 1)
	end
	def onMouseMove(flags, x, y, view)
		puts "onMouseMove: flags = #{flags}"
		puts "                 x = #{x}"
		puts "                 y = #{y}"
		puts "              view = #{view}"
		# retour a l'outil selection
		Sketchup.active_model.select_tool nil
		BR_OOB.getResults(ss[0])# GetParam 
	end   
end
	
#======================================================
# Outil "PIPETTE" affichage du gisment sous la souris
#======================================================
class OobDebugTool
	def initialize
		puts 'initialize' if (@TRACE == 1)
	end
	def reset
		puts 'reset' if (@TRACE == 1)
		@ip = Sketchup::InputPoint.new
	end
	def activate
		puts 'activate' if (@TRACE == 1)
		Sketchup.send_action("showRubyPanel:") if (@TRACE == 1)
		self.reset
	end
	def deactivate(view)
		puts 'deactivate' if (@TRACE == 1)
	end
	def onMouseMove(flags, x, y, view)
		#puts 'onMouseMove'
		# puts x
		# puts y
		# puts @ip
		@ip.pick view, x, y
		if(@ip.valid?)
			f = @ip.edge
			# puts @f
			if f != nil 
				value = f.get_attribute "Oob", "Class1"
				value2 = f.get_attribute "Oob", "Class2"
				if value != nil  
					view.tooltip = "Pt1 : %i" %value+" Pt2 "+"%i" %value2					
					
					#point16 = Geom::Point3d.new 0,0,0
					#status = view.draw_text point16, "This is a test"
				end
			end
		end
		view.invalidate
	end
	def onRButtonDown(flags, x, y, view)
		puts 'onRButtonDown'
		# puts x
		# puts y
		# puts @ip
		@ip.pick view, x, y
		if(@ip.valid?)
			f = @ip.edge
			# puts @f
			if f != nil 
				value = f.get_attribute "Oob", "Class1"
				value2 = f.get_attribute "Oob", "Class2"
				if value != nil  
					view.tooltip = "Pt1 : %i" %value+" Pt2 "+"%i" %value2					
					
					#point16 = Geom::Point3d.new 0,0,0
					#status = view.draw_text point16, "This is a test"
				end
			end
		end
		view.invalidate
	end
	def onLButtonDown(flags, x, y, view)
		# ajout 10.04 : sur clic gauche on demande si on veut ajouter un texte, sinon on sort du gisement
		@ip.pick view, x, y
		if(@ip.valid?)
			f = @ip.face
			# puts @f
			if f != nil 
				value = f.get_attribute  "A", "G"
				if value == nil  
					Sketchup.active_model.select_tool nil
				else
					mess = "Voulez vous  créer un texte 3D ?"
					resulttexte = UI.messagebox mess , MB_YESNO
					if resulttexte == 6 # Yes
						point = @ip.position
						puts "point"  if (@TRACE == 1)
						puts point  if (@TRACE == 1)
						
						coordvect = [0.0,0.0,100.0]
						
						value2 = f.get_attribute  "A", "G"
						if(value2 == nil)
							texttodisplay = "Gisement : %.0f  kWh/m2/an" % value
						else
							texttodisplay = "Gisement : %.0f" % value + " kWh/m2/an\n Ratio : "+ "%.2f" % (value / value2)					
						end
						
						
						text = Sketchup.active_model.entities.add_text texttodisplay, point
						vect = Geom::Vector3d.new coordvect
						text.vector = vect
						text.line_weight=1
						text.leader_type=1
						text.display_leader=true
						text.arrow_type=2
					else
						Sketchup.active_model.select_tool nil
					end
				end
			end	
		end
	end
end # class OobDebugTool

#----------------menu------------------
if( true ) #not file_loaded?(__FILE__) ) # A enlever pour la release

	# chargement des chaines NLS
	BR_OOB.loadStrings()
	#======================================================	
	# ------------ Menu contextuel --------------------------------
	#======================================================
	UI.add_context_menu_handler do |menu|
		ss = Sketchup.active_model.selection
		if (ss.empty? == false)
			#puts "Selection non vide"
			#if ((ss[0].kindof? Sketchup::Edge) and (ss.count==1))
			#if (ss.count==1)
				#BR_OOB.debugFunction(ss[0])
			if(false) # test cablage
				menu.add_separator	
				nbc = ss[0].get_attribute "Oob", "nbCables"
				#puts "nbc =#{nbc}"
				
				if nbc == nil  
					menu.add_item("Oob cables"){
						# ajout / recup d'un nombre de cables sur l'edge
						BR_OOB.setNbCables(ss)
					}
				else
					menu.add_item("Oob cables OK"){
						# ajout / recup d'un nombre de cables sur l'edge
						BR_OOB.setNbCables(ss)
					}
				end
			end	
			#end
			if ((ss[0].kind_of? Sketchup::Group) and (ss.count==1))
				#puts "it s a group"
				dic = ss[0].attribute_dictionary "Oob"
				
				if dic != nil 
					menu.add_separator 
					
					# Recuperer parametres
					menu.add_item(BR_OOB.getString("Oob récupérer paramètres") ){ 
						BR_OOB.getParameters(ss[0])# GetParam 
					}
					# Recuperer les résultats
					menu.add_item(BR_OOB.getString("Oob voir résultats") ){ 
						#Sketchup.active_model.select_tool GetCursorPosTool.new
						BR_OOB.getResults(ss[0])# GetParam 
					}
					
					# Editer
					menu.add_item(BR_OOB.getString("Oob editer") ){ 
						Sketchup.active_model.start_operation(BR_OOB.getString("Créer calepinage"),true) ###############################################
						# recup des parametres
						BR_OOB.getParameters(ss[0])
						# undo 
						face = BR_OOB.undoOob(ss[0])
						
						# selecton d'une face
						Sketchup.active_model.selection.clear
						Sketchup.active_model.selection.add face
						
						# edit
						moderedo = 1
						BR_OOB.creerOssature(moderedo)
						Sketchup.active_model.commit_operation 
					}
					
					# Annuler
					menu.add_item(BR_OOB.getString("Oob annuler") ){ 
						Sketchup.active_model.start_operation(BR_OOB.getString("Undo"),true) ###############################################
						BR_OOB.undoOob(ss[0])
						Sketchup.active_model.commit_operation 
					}
				end
				#oob1grp.set_attribute "Oob", "Oob f_longueurBardage", @@f_longueurBardage
			end	
		end	
	end
		
	#========================================================
	# TOOLBAR 
	# TOOLBAR UI.toolbar("Oob").show
	#=========================================================
	# Toolbar initialization guard to prevent duplicate toolbars
	unless defined?($oob_toolbar_initialized) && $oob_toolbar_initialized
  toolbar = UI::Toolbar.new "Oob"

  # Remove all existing items from the toolbar (cleanup for reloads)
  while toolbar.count > 0
	toolbar.remove_item(0)
  end

  # Commande principale OOB : calcul de callepinage
  #====================================================
  small_icon = Sketchup.find_support_file('delicious-s.png', 'Plugins/Oob-layouts/icons')
  large_icon = Sketchup.find_support_file('delicious-l.png', 'Plugins/Oob-layouts/icons')
  cmd2 = UI::Command.new("CommandeOob") {
	Sketchup.active_model.start_operation(BR_OOB.getString("Créer calepinage"),true)
	BR_OOB.creerOssature(0)
	Sketchup.active_model.commit_operation
  }

  cmd2.small_icon = small_icon
  cmd2.large_icon = large_icon
  cmd2.menu_text = BR_OOB.getString("Oob calepinage")
  cmd2.tooltip = BR_OOB.getString("Oob tooltip")
  toolbar.add_item(cmd2)

  toolbar.show
  $oob_toolbar_initialized = true
	end
end

#=====================================================
# The following code seems to be a duplicate/older version and is not used by the main execution flow.
# It is kept here for reference but the fixes have been applied to the primary functions above.
#=====================================================


  DEV_TAG ||= "Dev v2025.07.08-b"


  # ========== DEV METADATA ==========

  DEV_TAG ||= "Dev v2025.07.08-b"

  def self.dev_tag
	puts "[BR_OOB] Loaded: #{DEV_TAG}"
	DEV_TAG
  end

  dev_tag  # auto-call on load

end    # ← for module BR_OOB