module OobLayoutsModule # one module wrapper



OOB_VERSIONFULL = "FUL6" # V6.0



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

attr_accessor :m_Matrice #Matrice de psition de la  face

def initialize

    end

end





# debug 3D  : affichaeg d'une ligne (vecteur)

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

tpt = Geom::Point3d.new  point

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

def  BR_GeomTools.getLongestEdge(face)

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

def  BR_GeomTools.getMeanPoint(verticelist)

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

trace =  1

puts "in getListOfFaces" if(trace == 1)

puts tabFaces.size()  if(trace == 1)

#puts "|"

if (elt == nil)

puts "elt =  nil" if(trace == 1)

return

end


# si il s'agit de la selection courante

if (elt.class == Sketchup::Selection)

puts "in elt.class == Sketchup::Selection"   if(trace == 1)

elt.each do |ent|

puts "in entity of Sketchup::Selection"  if(trace == 1)

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

puts "- Groupe"  if (trace == 1)

matricegroup = elt.transformation


if(matricegroup.identity?)

puts "- Matrice groupe = identite"  if (trace == 1)

#puts matricegroup.to_a  if (trace == 1)

else

puts "- Matrice groupe != identite"  if (trace == 1)

#puts matricegroup.to_a  if (trace == 1)

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

puts "- Composant"  if (trace == 1)

defin = elt.definition

matriceinst = elt.transformation

if(matriceinst.identity?)

puts "- Matrice inst = identite"  if (trace == 1)

else

puts "- Matrice inst != identite"  if (trace == 1)

puts matriceinst.to_a  if (trace == 1)

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


end # of module BR_GeomTools



#----------------module Oob-----------

module BR_OOB



# variables de classe

@@OOBpluginRep = 'Plugins/Oob-layouts/'

#@@OOBpluginRep = 'Plugins/Oob-DEV/' # MODIF A COMMENTER EN RELEASE


@@OOB_VERSION = "Oob%201402"


@@shadowobserver = nil

@@shadowobservercmd = nil


@@oobTabStrings = {}



@@f_epaisseurBardage  = 0.02  #cm

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

@@s_presetname = "" # selectPreset



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

# $tabParamsCmds = [ ['images/24/120.png', $OOB1SETTINGS, "OOB1", "Paramétrage Oob1","Oob&: paramètres","OOB1"] ];

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

newOOBlayer.visible = true

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

puts "in LoadStrings"  if(trace ==1)

stringsfile = Sketchup.find_support_file('files/Strings.arp', @@OOBpluginRep) # NI 0009 MAC le \ ne passe pas on remplace par  /

puts "stringsfile" if(trace ==1)

puts stringsfile  if(trace ==1)


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

puts line  if(trace == 1)

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

trace =  0

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

face.loops.each{|loop|gents.add_face(loop.vertices)}   # ajout de toutes les loops de la face 

oface=gents.add_face(face.outer_loop.vertices)        # oface = copie de la loop


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

#  procedure booleenne 2D : selection contre model

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


if faces.empty?       # 1.1 selection trap si aucune face selectionnée on recupere les faces sur lesquelles sont gluees les composants

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

gp2=entitiesForResult.add_group();  # nouveau groupe gp2, groupe des résultats

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

e.erase! ### remove original groups  ##

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

face.loops.each{|loop|gents.add_face(loop.vertices)}   # make innerfaces and all faces

oface=gents.add_face(face.outer_loop.vertices)        # make outer faces again to be sure


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

model.commit_operation   ###############################################

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

green =  122

blue = 122

alpha = 255


# V4.6 color sous la forme 122,250,0

splittab = colorName.split(',')

if(splittab.size >= 3)

red   = splittab[0].to_i

green = splittab[1].to_i

blue  = splittab[2].to_i

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

initColor =  m.color

initR = initColor.red

initG = initColor.green

initB = initColor.blue

initAlpha  = initColor.alpha

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

#     start_operation blocks - as operations cannot be nested.

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

#puts "newm texture  #{newm.texture.filename}"

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

# f_epaisseurBardage  = 2.0  if not defined?(f_epaisseurBardage)#cm

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

@dialogOobOne.set_file( pathname  )

@dialogOobOne.set_size(490,600)

@dialogOobOne.set_background_color("ECE9D8");


# TRAITEMENT DES CALL BACK

#==========================


# V5.0 DELETE du preset  courant

#==================================

@dialogOobOne.add_action_callback("deletepreset") do |js_wd, message|

rep = UI.messagebox(BR_OOB.getString("Delete preset")+" : " + message+ " ?",MB_YESNO)

if(rep == 6)  # Yes

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



  presetsfiles = Dir[Sketchup.find_support_file('Plugins') + '/Oob-layouts/presets/*.oob']

  file = presetsfiles[0]

  if trace == 1

    puts file

    puts File.basename(file)

    puts File.dirname(file)   

  end

  fullname = File.dirname(file) + "/" + results[0] + ".oob"

  puts fullname if trace == 1



  radiovalue = @dialogOobOne.get_element_value("inputradiohidden").to_s



  file = File.open(fullname, 'w')

    file.write("Oob preset parameters;" + results[0].to_s + ";\n")

    file.write("@@i_unit;" + Sketchup.active_model.options["UnitsOptions"]["LengthUnit"].to_s + ";\n") # V5

    file.write("@@f_longueurBardage;" + @dialogOobOne.get_element_value("input2").to_s + ";\n")

    file.write("@@f_hauteurBardage;" + @dialogOobOne.get_element_value("input3").to_s + ";\n")

    file.write("@@f_randomlongueurBardage;" + @dialogOobOne.get_element_value("inputrand2").to_s + ";\n")

    file.write("@@f_randomhauteurBardage;" + @dialogOobOne.get_element_value("inputrand3").to_s + ";\n")

    file.write("@@f_layeroffset;" + @dialogOobOne.get_element_value("inputlayeroffset").to_s + ";\n") 

    file.write("@@f_heightoffset;" + @dialogOobOne.get_element_value("inputheightoffset").to_s + ";\n") 

    file.write("@@f_lengthoffset;" + @dialogOobOne.get_element_value("inputlengthoffset").to_s + ";\n") 

    file.write("@@f_randomepaisseurBardage;" + @dialogOobOne.get_element_value("inputrand4").to_s + ";\n")

    file.write("@@f_randomColor;" + @dialogOobOne.get_element_value("inputrand5").to_s + ";\n")

    file.write("@@f_epaisseurBardage;" + @dialogOobOne.get_element_value("input4").to_s + ";\n")

    file.write("@@f_jointLongueur;" + @dialogOobOne.get_element_value("input5").to_s + ";\n")

    file.write("@@f_jointLargeur;" + @dialogOobOne.get_element_value("input6").to_s + ";\n")

    file.write("@@f_jointProfondeur;" + @dialogOobOne.get_element_value("input7").to_s + ";\n")

    file.write("@@f_decalageRangees;" + @dialogOobOne.get_element_value("input8").to_s + ";\n")

    file.write("@@s_colorname;" + @dialogOobOne.get_element_value("input9").to_s + ";\n")

    file.write("@@i_startpoint;" + @dialogOobOne.get_element_value("inputstartpoint").to_s + ";\n")

  file.close



  @dialogOobOne.execute_script('addPresetOption("' + results[0].to_s + '");')

end



@dialogOobOne.add_action_callback("selectpreset") do |js_wd, message|

  presetfilename = Sketchup.find_support_file(message + '.oob', @@OOBpluginRep + '/presets')

  unless File.exist?(presetfilename)

    puts "Preset file not found: #{presetfilename}"

    next

  end



  presetunit = 4

  modelunit = Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]

  tabunitconversion = [1.0, 12.0, 0.1 / 2.54, 1.0 / 2.54, 100.0 / 2.54]

  unitconversionmodel = 1.0 / tabunitconversion[modelunit]

  unitconversionpreset = tabunitconversion[presetunit]



  File.open(presetfilename).each_line do |line|

    line = line.strip

    puts "LINE: #{line}"

    tab = line.split(';')

    next if tab.empty?



    case tab[0]

    when "@@i_unit"

      presetunit = tab[1].to_i

      unitconversionpreset = tabunitconversion[presetunit]

      puts "Preset unit: #{presetunit}, Conversion ratio: #{unitconversionpreset}"

    when "@@f_longueurBardage"

      val = (tab[1].to_f * unitconversionmodel * unitconversionpreset).round(6).to_s

      puts "Setting input2 to #{val}"

      @dialogOobOne.execute_script("setValue('input2;#{val}');")

    when "@@f_hauteurBardage"

      val = (tab[1].to_f * unitconversionmodel * unitconversionpreset).round(6).to_s

      puts "Setting input3 to #{val}"

      @dialogOobOne.execute_script("setValue('input3;#{val}');")

    else

      if tab[0].start_with?("@@f_") || tab[0].start_with?("@@s_") || tab[0].start_with?("@@i_")

        key = tab[0].sub('@@', '')

        value = tab[1].to_s.strip rescue ''

        unless value.empty?

          puts "Setting #{key} to #{value}"

          @dialogOobOne.execute_script("setValue('#{key};#{value}');")

        end

      end

    end

  end



  @dialogOobOne.execute_script("compute();")

end


# selection d'un fichier de preset

#===========================================

@dialogOobOne.add_action_callback("selectpreset") do |js_wd, message|

puts "selectpreset #{message}"


# lecture du fichier 

presetfilename = Sketchup.find_support_file(message + '.oob', @@OOBpluginRep + '/presets')

if !File.exist?(presetfilename)

UI.messagebox "Error, file not found!"

else

# Continue reading file if it exists

File.open(presetfilename).each_line do |line|

# your existing parsing logic here

end

end



# gestion unites

presetunit = 4 # les presets sont par defaut en metre

modelunit = Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]


# 0 = " # 1 = ' # 2 = mm # 3 = cm # 4 = m

unitconversionmodel = 1.0/2.54

tabunitconversion = [1.0,12.0,0.1/2.54,1.0/2.54,100.0/2.54]


if((modelunit >= 0) and (modelunit <= 4))  

unitconversionmodel = 1.0/tabunitconversion[modelunit] # conversion de pouces en unites courante du modele

end 


puts "unitconversionmodel"

puts unitconversionmodel


unitconversi