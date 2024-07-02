Device dev {
    Electrode {
        { name="N1" Voltage=0 }
        { name="N2" Voltage=0 }
        { name="N3" Voltage=0 }
        { name="N4" Voltage=0 }
        
        #if @PWBIAS@ == 1
        { name="P1" Voltage=0 }
        { name="P2" Voltage=0 }
        { name="P3" Voltage=0 }
        #endif
 
        #if @BVBIAS@ == 1
        { name="BV" Voltage=0 }
        #endif
    }

    File {
        Grid = "@tdr@"
        Plot = "@tdrdat@"
        Current = "@plot@"
    }

    Physics{
         	Fermi 
        	EffectiveIntrinsicDensity (BandGapNarrowining(Slotboom))

        	Mobility (    
         	DopingDependence(Masetti)
            HighFieldSaturation
            CarrierCarrierScattering (ConwellWeisskopf)
            Enormal
        	)

        	Recombination(
            SRH( DopingDependence TempDependence Tunneling(Hurkx) ElectricField (Lifetime=Hurkx DensityCorrection = None))
             Auger
             #if "@AVA@" != "None" 
             Avalanche(@AVA@)
             #else
             #endif
             
             Band2Band(Hurkx)
        	)
   
        #if "@InjPos@" == "centre"
        	#set injhor @<1.5*pitch>@
        #else
        	#set injhor @InjPos@
        #endif
	
       # #if "@InjType@" == "MIP"
        	* Reference: ~1.282E-5 pC/um represents 80eh/um
		#	#set ChargeCount 80  
	#	#else 
			#set ChargeCount @NCharge@
	#	#endif        
        #set let_f @<ChargeCount*(1.602e-19)*(1e12)>@

        
       	 HeavyIon (
       	 	#if "@InjType@" != "Point"
       	 	# one should use rad as the unit for trigometric functions here
            Direction=(@<cos(2*3.14159265*InjAng/360)>@, @<sin(2*3.14159265*InjAng/360)>@)
            #else
            Direction = (1,0)
            #endif
            Location=(0,@injhor@)
            Time=1e-9
            #if "@InjType@" == "MIP"
            	Length = [0 0.00001 @<Thickness/cos(2*3.14159265*InjAng/360)>@ @<Thickness/cos(2*3.14159265*InjAng/360)+0.00001>@ ]
            #elif "@InjType@" == "Test"
            	Length = [@<CStart-0.00001>@ @CStart@ @<CStart+CLength>@ @<CStart+CLength+0.00001>@]
            #elif "@InjType@" == "Point"
            	Length = [@<CStart-0.5-0.00001>@ @<CStart-0.5>@ @<CStart+0.5>@ @<CStart+0.5+0.00001>@]
            #endif
            wt_hi = [0.1 0.1 0.1 0.1]
            * 80eh/um, can change this
            LET_f = [0 @let_f@ @let_f@ 0]
            Gaussian
            Picocoulomb
         )   

    }


    # perugia
    
    #if @model@==1
    Physics (Material="Silicon") {
        Traps (
            ( Acceptor Level fromCondBand Conc=@<dose*1.613>@ EnergyMid=0.42 eXsection=1E-15 hXsection=1E-14 )
            ( Acceptor Level fromCondBand Conc=@<dose*0.9>@ EnergyMid=0.46 eXsection=7E-15 hXsection=7E-14 )
            ( Donor Level fromValBand Conc=@<dose*0.9>@ EnergyMid=0.36 eXsection=3.23E-13 hXsection=3.23E-14 )
        )
    }
    
    # 3D model
    
    #elif @model@==2
    Physics (Material="Silicon") {
        Traps (
            ( Acceptor Level fromCondBand Conc=@<dose*1.613>@ EnergyMid=0.42 eXsection=9.5E-15 hXsection=9.5E-14 )
            ( Acceptor Level fromCondBand Conc=@<dose*0.9>@ EnergyMid=0.46 eXsection=5E-15 hXsection=5E-14 )
            ( Donor Level fromValBand Conc=@<dose*0.9>@ EnergyMid=0.36 eXsection=3.23E-13 hXsection=3.23E-14 )
        )
    }
    
    # Hamburg Penta Model
    
     #elif @model@==3
	Physics (Material="Silicon") {
	Traps (
		* ===E30K===
		( Donor Level fromCondBand Conc=@<dose*0.0497>@ EnergyMid=0.1 eXsection=2.3E-14 hXsection=2.92E-16 )
		* ====V3======         		
		( Acceptor Level fromCondBand Conc=@<dose*0.6447>@ EnergyMid=0.458 eXsection=2.551E-14 hXsection=1.511E-13 )
		* =====Ip======
		( Acceptor Level fromCondBand Conc=@<dose*0.4335>@ EnergyMid=0.545 eXsection=4.478E-15 hXsection=6.709E-15 )
		* ======H220=====
		( Donor Level fromValBand Conc=@<dose*0.5978>@ EnergyMid=0.48 eXsection=4.166E-15 hXsection=1.965E-16)
		* ======CiOi======
		( Donor Level fromValBand Conc=@<dose*0.3780>@ EnergyMid=0.36 eXsection=3.23E-17 hXsection=2.036E-14)
	)
	}
	#else
    #endif
 


#if "@TIDMrad@" != "None"
*Dose of the TID in unit of Mrad
	#set TID 		[format %.2f @TIDMrad@] 
* Initial total conctration of the oxide charge before irradiation
* since we don't know it for LF, we use a dummy value
	#set Qoxpre 	[format %.2e 1.0e+10]		
* Initial total acceptor concentration at the interface before irradiation
* since we don't know it for LF, we use a dummy value
	#set Nitaccpre 	[format %.2e 1.0e+9]	
* Initial total donor concentration at the interface before irradiation
* since we don't know it for LF, we use a dummy value
	#set Nitdonpre 	[format %.2e 1.0e+9]		

* Case selection: before TID
	#if "@TIDMrad@" == 0						
	# due to TID introduced total damage concentration (for traps indicated with "N" [cm^-2]) are set to 0
		#set DeltaQox 		[format %.2e 0]
		#set DeltaNitacc 	[format %.2e 0]
		#set DeltaNitdon 	[format %.2e 0]
	# the energy concentration of the traps labelled with "D" [eV^-1 cm^-2].
	# As we see also later by specifying the traps, this concentration is used for the uniform distribution of the trap energies
	#	therefore this value represents the height of the distribution.
	# Converting the "D" to "N" requires an integration of "D" over the energy. since it's a uniform distribution, a simple
	# 	conversion function is: N=D*width(eV) and D=N/width(eV).
	# Hence the definition and conversion beneath.
	* [SNOW: for Dit_acc, the original "/0.3" is replaced by "0.56", s.u.]
		#set Dit_acc 		[format %.2e @<Nitaccpre/0.56>@]		
		#set Dit_don		[format %.2e @<Nitdonpre/0.3>@] 
		#set Qox 			[format %.2e @Qoxpre@]
	#else						
* Case seletion: after TID
	# due to TID introduced trap ("N") and oxide charge concentration are added according to fitting the data from measurements
		#set DeltaQox 		[format %.2e [expr @<3.74E+11 + 6.20E+10 * log(TID)>@]] 
		#set DeltaNitacc 	[format %.2e [expr @<6.35E+11 + 1.50e+11 * log(TID)>@]] 
		#set DeltaNitdon 	[format %.2e [expr @<1.07E+12 + 2.90e+11 * log(TID)>@]]

	# The total damage parameters (the "EsA" is probably a typo, SNOW: I suggest this should be 0.56)
		#set Dit_acc [format %.2e @<(DeltaNitacc+Nitaccpre)/0.56>@] 
		#set Dit_don [format %.2e @<(DeltaNitdon+Nitdonpre)/0.3>@] 
		#set Qox [format %.2e @<Qoxpre+DeltaQox>@]
	#endif


	Physics (MaterialInterface= "Oxide/Silicon") {
	Traps(
		(FixedCharge Conc=@Qox@)
		#if "@TIDMrad@" != "None"
		(Acceptor Conc=@Dit_acc@ Uniform EnergyMid=0.84 EnergySig=0.56 fromValBand eXsection=1e-16 hXsection=1e-15 Add2TotalDoping)
		(Donor Conc=@Dit_don@ Uniform EnergyMid=0.60 EnergySig=0.30 fromValBand eXsection=1e-15 hXsection=1e-16 Add2TotalDoping)
		#endif
	)
	}
#endif

     Plot{
        eDensity hDensity eMobility hMobility
        eVelocity hVelocity
        ElectricField/Vector Potential SpaceCharge
        eCurrent/Vector hCurrent/Vector
    *--Generation/Recombination 
        SRH Band2Band Auger SurfaceRecombination
        eLifetime hLifetime
    * -Driving forces
        eEparallel hEparallel eENormal hENormal
        BandGap BandGapNarrowing
        HeavyIonChargeDensity
        Doping
        ConductionBand ValenceBand
        eQuasiFermi hQuasiFermi
        eTemperature Temperature hTemperature
        eIonIntegral hIonIntegral MeanIonIntegral
        AvalancheGeneration eAvalancheGeneration hAvalancheGeneration
    }
}

System {
#if @PWBIAS@ == 1
  #if @PWSPLIT@ == 1
    dev sample (N1=nw N2=nw N3=nw N4=nw P1=pw P2=pw P3=pw BV=pbv)
  #else
    #if @BVBIAS@ == 1
      dev sample (N1=nw N2=nw N3=nw N4=nw P1=pw P2=pw P3=pw BV=pw)
    #else
      dev sample (N1=nw N2=nw N3=nw N4=nw P1=pw P2=pw P3=pw)
    #endif
  #endif
#else 
   dev sample (N1=nw N2=nw N3=nw N4=nw BV=pbv)
#endif
    Vsource_pset vn (nw 0) {dc=0}
    #if @PWBIAS@ == 1
    Vsource_pset vp (pw 0) {dc=0}
    #endif
    #if @BVBIAS@ == 1
        Vsource_pset vbv (pbv 0) {dc=0}
    #endif
}


Solve {
	NewCurrentPrefix = "Bias_"
 Poisson 
 Coupled(Iterations=100){ Poisson Electron Hole  } 
 	#if @VNW@>0
    Quasistationary(
    InitialStep=0.5e-5 MaxStep=0.05 Minstep=1.0e-12 Increment=4.0 Decrement=2.0
    Goal {Parameter=vn.dc voltage=@VNW@}
    )
    { 
        Coupled { Poisson Electron Hole  } 
      #  Plot ( Time = (Range = (0.0 1.0) Intervals=5) NoOverwrite)
    }
    #endif
    #if @VPW@ != 0
    Quasistationary(
    InitialStep=0.5e-5 MaxStep=0.05 Minstep=1.0e-12 Increment=4.0 Decrement=2.0
    Goal {Parameter=vp.dc voltage=@VPW@}
    )
    { 
        Coupled { Poisson Electron Hole  } 
        # Plot ( Time = (Range = (0.0 1.0) Intervals=5) NoOverwrite)
    }
    #endif
    
#if @PWSPLIT@ == 1 & @VBV@ != 0  
    Quasistationary(
    InitialStep=0.5e-5 MaxStep=0.05 Minstep=1.0e-12 Increment=4.0 Decrement=2.0
    Goal {Parameter=vbv.dc voltage=@VBV@}
    )
    { 
        Coupled { Poisson Electron Hole  } 
        #Plot ( Time = (Range = (0.0 1.0) Intervals=5) NoOverwrite)
    }
#endif
      
    NewCurrentPrefix = "Signal_"
    Transient( 
        InitialTime = 0.0
        FinalTime=@<CollectionTime+(1e-9)>@
        InitialStep=0.1E-11
        MaxStep=0.5e-10
        Increment=2.0
        Decrement=1.5 
        )
        {
            Coupled (Iterations=10 NotDamped=100) { Poisson Electron Hole } 
            # Plot ( FilePrefix = "n@node@_Signal_time" Time = (Range = (0e-9 10e-9) Intervals=10) NoOverwrite)
            # Plot ( FilePrefix = "n@node@_Signal_time" Time = (Range = (0e-9 20e-9) Intervals=20;Range = (20e-9 100e-9) Intervals=40; Range = (100e-9 200e-9) Intervals=10) NoOverwrite)
        }
}

Math {
   #  Many of these options are now default in Synopsys. The examples in the SDevice manual are a good guide.
    Digits=6
    # "Iterations" means that unless we tell the solver otherwise, it's attempt up to 1000 iterations when solving (this is very high)
    Iterations=10
    NotDamped=100
    # Choose the method used to solve the differential equations
    Method=Blocked
    Submethod=Pardiso
    Transient = BE
    # A few standard options to control solving method - for example, "Extrapolate" means
    Extrapolate
    Derivatives
    RelErrControl
    # Originally listed as erreff in this file, but the Dessis manual says it should be ErrRef. See if this works
    RhsMin= 1e-10
    ErrRef(electron)=1e8   
    ErrRef(hole)=1e8
    Number_of_Threads = 4
    NoSRHperPotential
    # eliminate the source of numeric error of the HeavyIon Method
    RecBoxIntegr
}
