#header
# Load files
source ./GeneralSettings.fps		;# The setting files
source ./ProcessData.fps 			;# The process data

set AutoRefine 0

# Use Calibration
AdvancedCalibration

# ----------------------
# --- Form Substrate ---
# ----------------------
fset sub_doping 1e18
fset epi_doping @BulkConc@ 
fset sub_height 20
fset epi_height 18 
fset Xmax @<pitch/2>@
fset node @node@
# ==Boron Doping Table==
# - 13 Ohm		: 1.00e15
# - 100 Ohm		: 0.12e15 
# - 1k Ohm		: 1.32e13
# - 1.5k Ohm	: 8.85e12
# - 2k Ohm		: 6.64e12
# - 2.5k Ohm	: 5.31e12
# - 3k Ohm		: 4.42e12
# - 3.5k Ohm	: 3.79e12

#endheader

# setup the simulation domain by initialsing the mesh grid
line y location= 0.0			spacing= 0.2 tag= left
line y location= $Xmax			spacing= 0.2 tag= right

line x location= 0.0			spacing= 0.1 tag= top
line x location= 4.0			spacing= 0.2
line x location= $sub_height  	spacing= 0.5 tag= bottom

# initialise the simulation domain (Wafer)
region Silicon substrate xlo= top xhi= bottom ylo= left yhi= right 
init concentration= $sub_doping field= Boron wafer.orient= 100  

# Create epitaxial layer 
etch silicon type= cmp coord= $epi_height<um> 
deposit material= {Silicon} type= isotropic rate= {$epi_height} time= 1.0 temperature= 500<C> Boron concentration= $epi_doping

# Establish finer mesh grid for implantation at the silicon surface
refinebox clear.interface.mats
refinebox min= {0.0 0.0} max= {6.0 $Xmax} xrefine= {0.1 0.1 0.1} yrefine= {0.1 0.1 0.1}


# Formation of the inserted N-layer. Four variations are available
# specify "0" for @nlayer@, the structure will be the unmodified version ALPIDE
fset nlayer @nlayer@

if {$nlayer==1} {
# Uniform n layer
	implant Phosphorus dose= @NDose@ energy= 3000 tilt= 7.0 rotation=-90.0
}
if {$nlayer == 2} {
# extended DPW
	implant Phosphorus dose= @NDose@ energy= 3000 tilt= 7.0 rotation=-90.0
	mask name=pextend segments= {0 $Xmax-2} negative
	photo mask= pextend thickness= 10.0
	implant Boron dose= 1e13 energy= 750	tilt= 7 rotation= -90.0
	implant Boron dose= 3e13 energy= 1000	tilt= 7 rotation= -90.0
	strip Photoresist
}
if {$nlayer == 3} {
# gap in n layer
	mask name=ncut segments= {0 $Xmax-2}
	photo mask= ncut thickness= 6.0
	implant Phosphorus dose= @NDose@ energy= 3000 tilt= 7.0 rotation= -90.0
	strip Photoresist
}
if {$nlayer == 4} {
# extended DPW and gap in N layer
	photo mask= ncut thickness= 6.0
	implant Phosphorus dose= @NDose@ energy= 3000 tilt= 7.0 rotation= -90.0
	strip Photoresist
	
	photo mask= pextend thickness= 10.0
	implant Boron dose= 1e13 energy= 750 	tilt= 7 rotation=-90.0
	implant Boron dose= 3e13 energy= 1000 	tilt= 7 rotation=-90.0
	strip Photoresist
}

# -------------------
# --- Form Pixels ---
# -------------------
fset np_spec @spacing@							;# spacing between NW and PW
set nw_width	@<NW/2>@							;# Width of NW
set sti_stop	[expr $nw_width-0.5]			;# position of STI for mask
set sti_start	[expr $nw_width+$np_spec+0.5]	;# position of STI for mask
set pw_start	[expr $nw_width+$np_spec]		;# position of PW for mask

# --- STI ---
#	Form STI
mask name=STI           segments = {0 $sti_stop $sti_start $Xmax}   !negative 
FormSTIandSCR

# Implantation for PW
mask name=PW            segments = {$pw_start $Xmax}   !negative
photo mask= PW thickness= 5.0
ImpPW
# Implantation for P+
ImpPPLUS
strip Photoresist

# Implantation for NW
mask name=NW            segments = {0 $nw_width}   !negative 
photo mask= NW thickness= 5.0
ImpNW
# Implantation for N+
ImpNPLUS
strip Photoresist
 

# ---Annealing---
Annealing


# ------------------
# ---Planarisation---
# ------------------
strip Oxide 
deposit oxide fill coord= 0

#split @Thickness@
transform reflect right
grid merge
transform reflect right
grid merge
transform reflect right
grid merge
transform cut location=[expr 6*$Xmax] right
grid merge

#if @EPI@ <= 0
transform stretch down location= 13 length= @Thickness@-$epi_height
#else
transform stretch down location= 19 length= @<Thickness-EPI>@-($sub_height-$epi_height)
transform stretch down location= 13 length= @EPI@-$epi_height
#endif
grid merge

# WriteBND "TRANSFORM"

# ===================== Remeshing =======================

refinebox clear
refinebox clear.interface.mats
# refinebox !keep.lines
line clear

refinebox interface.mat.pairs= {Silicon Oxide}\
	min.normal.size= 0.01 normal.growth.ratio= 1.3
refinebox Silicon refine.fields= {NetActive} max.asinhdiff= {NetActive=1.2}\
	refine.min.edge= {0.01 0.01} refine.max.edge= {0.5 0.5}
refinebox remesh
grid remesh

#WriteBND "REMESH"
# =======================================================

# -- contacts
contact add bottom name= BV

contact box xlo=-1 xhi= 1 ylo= -0.1			yhi= 0.1 			name= N1  	 	Silicon
contact box xlo=-1 xhi= 1 ylo= 2*$Xmax-0.1 	yhi= 2*$Xmax+0.1 	name= N2   		Silicon
contact box xlo=-1 xhi= 1 ylo= 4*$Xmax-0.1 	yhi= 4*$Xmax+0.1 	name= N3   		Silicon
contact box xlo=-1 xhi= 1 ylo= 6*$Xmax-0.1 	yhi= 6*$Xmax+0.1 	name= N4   		Silicon

contact box xlo=-1 xhi= 1 ylo= 1*$Xmax-0.5	yhi= 1*$Xmax+0.5 	name= P1   		Silicon
contact box xlo=-1 xhi= 1 ylo= 3*$Xmax-0.5 	yhi= 3*$Xmax+0.5 	name= P2 		Silicon
contact box xlo=-1 xhi= 1 ylo= 5*$Xmax-0.5 	yhi= 5*$Xmax+0.5 	name= P3		Silicon


struct tdr=n@node@

exit 0
