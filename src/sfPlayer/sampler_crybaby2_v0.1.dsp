declare name 				"sfCrybaby"; 
declare version 		"1.4";
declare author 			"Christophe Lebreton";
declare license 		"BSD & STK-4.3";
declare copyright 	"SmartFaust - GRAME(c)2013-2018";

import("stdfaust.lib");

//-------------------- MAIN -------------------------------
process = _<:_,crybaby_ios:dry_wet_mono;

//-------------------- PARAMETERS -------------------------------
lowpassmotion = fi.lowpass(N,fc)
			with {
				//fc= hslider("h:motion filter/high_cut [hidden:1]",10,0.01,10,0.01);
				fc=10;
				N= 1;	// order of filter
			};

// direct from effect.lib ( "Julius O. Smith ") and adapted by Christophe Lebreton for ios
crybaby_ios = ve.crybaby(wah)
			with {
   				wah =  hslider("v:sfPlayer parameter(s)/[1] Wah parameter[acc:0 0 -10 0 10][color: 255 0 0 ][hidden:1]",0,0,1,0.01):fi.lowpass(1,1); //[accx:1 0 0. 0]
			};

// Dry Wet avec expression en % ////////////////////////////////////////
drywet = hslider ("v:sfPlayer parameter(s)/ DryWet [acc:1 0 -10 0 10][color: 255 255 0 ] [hidden:1]", 0, 0, 100, 1):*(0.02):-(1): fi.lowpass(1,1); //[accy:1 0 0 0]


dry_wet_mono(x) = *(wet) + dry*x
			with {
    			wet = 0.5*(drywet+1.0);
    			dry = 1.0-wet;
  			};
