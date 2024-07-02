set dir ./

# --- Signal current data from the transient simulation
set signaldata [load_file Signal_sample_@plot@]
create_plot -1d -name SignalPlot
select_plots {SignalPlot}

# --- Set the end of simulation time as a variable
set vare [create_variable -name "endTimeVar" -dataset $signaldata -function "vecmax(<time:$signaldata>)"]
set end_time [lindex [get_variable_data $vare -dataset $signaldata] 1]
set end_time_ns [expr $end_time*1e9]
puts "end_time: $end_time"

# --- Plot the charge collection curve. The plotted curve has the unit of Coulomb The
create_curve -name N1Curr -plot SignalPlot -dataset $signaldata -axisX "time" -axisY "N1 TotalCurrent"
set_curve_prop N1Curr -plot SignalPlot -integ
set N1Char [expr [probe_curve {N1Curr} -valueX $end_time -plot SignalPlot]/(1.602e-19)]

create_curve -name N2Curr -plot SignalPlot -dataset $signaldata -axisX "time" -axisY "N2 TotalCurrent"
set_curve_prop N2Curr -plot SignalPlot -integ
set N2Char [expr [probe_curve {N2Curr} -valueX $end_time -plot SignalPlot]/(1.602e-19)]

create_curve -name N3Curr -plot SignalPlot -dataset $signaldata -axisX "time" -axisY "N3 TotalCurrent"
set_curve_prop N3Curr -plot SignalPlot -integ
set N3Char [expr [probe_curve {N3Curr} -valueX $end_time -plot SignalPlot]/(1.602e-19)]

create_curve -name N4Curr -plot SignalPlot -dataset $signaldata -axisX "time" -axisY "N4 TotalCurrent"
set_curve_prop N4Curr -plot SignalPlot -integ
set N4Char [expr [probe_curve {N4Curr} -valueX $end_time -plot SignalPlot]/(1.602e-19)]


# --- Leakage current data from the DC simulation
set leakagedata [load_file Bias_sample_@plot@]
create_plot -1d -name DCPlot
select_plots {DCPlot}

# --- Get the leakage current at the operating bias voltage
create_curve -name N1LeakCurr -plot DCPlot -dataset $leakagedata -axisX "time" -axisY "N1 TotalCurrent"
set N1leak [probe_curve {N1LeakCurr} -valueX 0.99999999 -plot DCPlot]													; # the 1 can't be probed for some data with numerical issues
create_curve -name N2LeakCurr -plot DCPlot -dataset $leakagedata -axisX "time" -axisY "N2 TotalCurrent"
set N2leak [probe_curve {N2LeakCurr} -valueX 0.99999999 -plot DCPlot]
create_curve -name N3LeakCurr -plot DCPlot -dataset $leakagedata -axisX "time" -axisY "N3 TotalCurrent"
set N3leak [probe_curve {N3LeakCurr} -valueX 0.99999999 -plot DCPlot]
create_curve -name N4LeakCurr -plot DCPlot -dataset $leakagedata -axisX "time" -axisY "N4 TotalCurrent"
set N4leak [probe_curve {N4LeakCurr} -valueX 0.99999999 -plot DCPlot]
# --> Total leakage current at the end of the bias rampm, and integrated charge after the full transient simulation
set Totleak [expr $N1leak + $N2leak + $N3leak + $N4leak]
set TotleakCharge [expr $end_time*$Totleak/(1.602e-19)]


# --- Creat CCE plot
set cc_plot [create_plot -1d -name "Charge Collection"]														;# the cce plot should be no problem
select_plots $cc_plot	
# set_axis_prop -plot $cce_plot -axis x -type log

# --- Create variables for the CCE plot
	# -> leakage current created extra charge (with the unit of the number of electrons) in parallel with the signal 
create_variable -name "LeakChar" -dataset $signaldata -function "($Totleak*<time:$signaldata>)/(1.602e-19)"
	# -> total signal current converted to the number of electrons per time
create_variable -name "SigCurr" -dataset $signaldata -function "(<N1 TotalCurrent:$signaldata> + <N2 TotalCurrent:$signaldata> + <N3 TotalCurrent:$signaldata> + <N4 TotalCurrent:$signaldata>)/(1.602e-19)"
	# -> convert the unit of time from sec to nanosecond
create_variable -name "Time_ns" -dataset $signaldata -function "<time:$signaldata>*1e9"
	# -> collected charge in the unit of the electron quantity, via integrating the current over the simulation time
create_variable -name "SigChar" -dataset $signaldata -function "integr(<SigCurr:$signaldata>,<time:$signaldata>)"
	# -> the net signal charge in the unit of electrons
create_variable -name "NetSigChar" -dataset $signaldata -function "(<SigChar:$signaldata>-<LeakChar:$signaldata>)"

# --- plot the charge collection curve
set CC_Curve [create_curve -name NetCollectedCharge -plot $cc_plot -dataset $signaldata -axisX "Time_ns" -axisY "NetSigChar"]
# set_curve_prop $CC_Curve -plot $cc_plot -label "process=@nlayer@, pitch=@pitch@, dose=@dose@, VNW=@VNW@"
set_legend_prop -plot $cc_plot -location bottom_right
set CollectedCharge [probe_curve $CC_Curve -valueX $end_time_ns -plot $cc_plot]
puts "CC: $CollectedCharge"
	# -> the gross collected charge (signal + leakage)
create_curve -name GrossCollectedCharge -plot $cc_plot -dataset $signaldata -axisX "Time_ns" -axisY "SigChar"
set gCC [probe_curve GrossCollectedCharge -valueX $end_time_ns -plot $cc_plot]
	# -> the leakage current created charge
create_curve -name LeakageCharge -plot $cc_plot -dataset $signaldata -axisX "Time_ns" -axisY "LeakChar"
set qleak [probe_curve LeakageCharge -valueX $end_time_ns -plot $cc_plot]

set_axis_prop -plot $cc_plot -axis y -title "Charge \[e-\]"
set_axis_prop -plot $cc_plot -axis x -title "Time \[ns\]"

# -- Charge collection rise-time (as a reference of collection time). The time from the injection time to 90% of the charge at the end time
#	This methode has a limitation that the values are not comparable between the experiments with different total simulation time
set cct [expr [probe_curve $CC_Curve -valueY [expr $CollectedCharge*0.9] -plot $cc_plot]-1 ]

# -- Collected charge within 10ns. This can be used as a reference for charge collection speed
#	Although the bunch-crossing time is 25ns at the LHC, the total available time for charge colletion is probably just ~10ns
#	as the electronics requires some ns to process the signal and prepare for the next bunch-crossing.
set CollectedCharge10ns [probe_curve $CC_Curve -valueX 11 -plot $cc_plot]

# --- output values ---
# puts "DOE: MOD @nlayer@"
# puts "DOE: DOSE @dose@"
# puts "DOE: VNW @VNW@"
puts "DOE: CCT [format %.2f $cct]"
puts "DOE: G-Q1-e [format %.0f $N1Char]"
puts "DOE: G-Q2-e [format %.0f $N2Char]"
puts "DOE: G-Q3-e [format %.0f $N3Char]"
puts "DOE: G-Q4-e [format %.0f $N4Char]"
puts "DOE: G-Q-e [format %.0f $gCC]"
puts "DOE: QLeak-e [format %.0f $qleak]"
puts "DOE: N-Q-e [format %.0f $CollectedCharge]"
puts "DOE: N-Q10ns-e [format %.0f $CollectedCharge10ns]"


#if "@InjType@" == "MIP"
	
	set xm @<3 * pitch>@
	
	#if @EPI@ > 0
		set dAct @EPI@ 	
	#else	
		set dAct @Thickness@
	#endif
	
	set xori [expr $dAct * tan(2*3.14159265*@InjAng@/360)]
	
	#if "@InjPos@" == "centre"
		set xi @<1.5 * pitch>@
	#else
		set xi @InjPos@
	#endif
	
	set HoriDiff [expr $xori-($xm-$xi)]
	
	if {$HoriDiff > 0.0} {
		set actCLength [expr $xori/sin(2*3.14159265*@InjAng@/360)]
	} else {
		set actCLength [expr $dAct/cos(2*3.14159265*@InjAng@/360)]
	}
	set TheoCharge [expr $actCLength * @NCharge@]
	
 #elif "@InjType@" == "Test"
	set TheoCharge @<CLength * NCharge>@
 #elif "@InjType@" =="Point"
	set TheoCharge @NCharge@
 #endif

set cce [expr ($CollectedCharge/$TheoCharge)*100]
set cce10 [expr ($CollectedCharge10ns/$TheoCharge)*100]

puts "DOE: TheoC [format %.0f $TheoCharge]"
puts "DOE: CCE [format %.0f $cce]"
puts "DOE: CCE10ns [format %.0f $cce10]"

exit 0


if 0 {

set qptot [expr ($qtot/1490)*100]
puts "DOE: QPTOT $qptot"

set qtot10ns [expr ([probe_curve $cce_c -valueX 11 -plot $cce_plot]/1490)*100]
puts "DOE: QTOT10NS $qtot10ns"



exec mkdir -p plots

exec mkdir -p plots/cce
exec rm -rf "./plots/cce/n@node@_cce.png"
export_view "./plots/cce/n@node@_cce.png" -plots $cce_plot -format PNG -resolution 1280x720


#Velocity/Mobility
exec mkdir -p plots/Velocity

set ivfile sample_n@previous@_des
set ivdata [load_file $dir/$ivfile.tdr]
set ivplot [create_plot -dataset $ivdata]
select_plots $ivplot

set_field_prop eVelocity -geom $ivdata -show_bands -range {100000 1.5e+07} -levels 64

set ivexport "./plots/Velocity/n@node@_eVelocity.png"
exec rm -rf $ivexport

export_view $ivexport -plots $ivplot -format PNG  -resolution 1280x720

remove_plots $ivplot
puts "Velocity finished"





# charge collectionp

exec mkdir -p plots/eDensity

start_movie -resolution 678x525

for { set i 0 } { $i <= 20 } { incr i } {

    set file [format "n@node|-1@_tran_time_%04d_sample_des" $i]
    set trandata [load_file $dir/$file.tdr]
    set myplot2D [create_plot -dataset $trandata]

    puts $myplot2D

    set title [format "Electron Density (Time=%dns)" [expr ($i-1)] ]
    
    set_material_prop {Gas} -geom $trandata -hide_border
    set_field_prop eDensity -geom $trandata -levels 64 -show_bands -range {1e+7 1e+13}
    ## set_field_prop eDensity -geom $trandata -custom_levels {10 13.5723 18.4207 25.0011 33.9322 46.0538 62.5055 84.8343 115.14 156.271 212.095 287.862 390.694 530.261 719.686 976.778 1325.71 1799.29 2442.05 3314.42 4498.43 6105.4 8286.43 11246.6 15264.2 20717 28117.7 38162.1 51794.7 70297.3 95409.5 129493 175751 238534 323746 439397 596362 809400 1.09854e+06 1.49097e+06 2.02359e+06 2.74647e+06 3.72759e+06 5.0592e+06 6.86649e+06 9.3194e+06 1.26486e+07 1.7167e+07 2.32995e+07 3.16228e+07 4.29193e+07 5.82514e+07 7.90604e+07 1.07303e+08 1.45635e+08 1.9766e+08 2.6827e+08 3.64103e+08 4.94171e+08 6.70704e+08 9.10298e+08 1.23548e+09 1.67683e+09 2.27585e+09 3.08884e+09 4.19227e+09 5.68987e+09 7.72245e+09 1.04811e+10 1.42253e+10 1.9307e+10 2.6204e+10 3.55648e+10 4.82696e+10 6.55129e+10 8.89159e+10 1.20679e+11 1.63789e+11 2.223e+11 3.01711e+11 4.09492e+11 5.55774e+11 7.54312e+11 1.02377e+12 1.3895e+12 1.88586e+12 2.55955e+12 3.47389e+12 4.71487e+12 6.39915e+12 8.68511e+12 1.17877e+13 1.59986e+13 2.17137e+13 2.94705e+13 3.99982e+13 5.42868e+13 7.36795e+13 1e+14} 
    
    
    set_plot_prop -plot $myplot2D -hide_legend -title_font_factor 2 -title $title
    #set_plot_prop -plot $myplot2D 
    #set_plot_prop -plot $myplot2D 
    
    select_plots $myplot2D
    add_frame
    ##export_view ed_$file.png -plots $myplot2D -format PNG -resolution 736x604
    remove_plots $myplot2D
}
exec rm -rf "./plots/eDensity/n@node@_eDensity.gif"
export_movie -filename "./plots/eDensity/n@node@_eDensity.gif" -frame_duration 50
stop_movie


}

