declare name 	"Crybaby";
declare version 	"1.34";// new mapping to android
//declare author 	"Julius O. Smith ";
declare author 	"GRAME";
declare license 	"STK-4.3";

import("math.lib"); 
import("maxmsp.lib"); 
import("music.lib"); 
import("oscillator.lib"); 
import("reduce.lib"); 
import("filter.lib"); 
import("effect.lib"); 

lowpassmotion = lowpass(N,fc)
			with {
				//fc= hslider("h:motion filter/high_cut [hidden:1]",10,0.01,10,0.01);
				fc=10;
				N= 1;	// order of filter
			};

// direct from effect.lib and adapted by Christophe Lebreton for ios

crybaby_ios = crybaby(wah) 
			with {
   				wah =  hslider("v:sfPlayer parameter(s)/[1] Wah parameter[acc:0 0 -10 10 0 0][color: 255 0 0 ][hidden:1]",0.8,0,1,0.01):lowpass(1,1); //[accx:1 0 0. 0]
			};

// Dry Wet avec expression en % ////////////////////////////////////////
drywet = hslider ("v:sfPlayer parameter(s)/ DryWet [acc:1 0 -10 10 0 0][color: 255 255 0 ] [hidden:1]", 0, 0, 100, 1):*(0.02):-(1): lowpass(1,1); //[accy:1 0 0 0]


dry_wet_mono(x) = *(wet) + dry*x
			with {
    			wet = 0.5*(drywet+1.0);
    			dry = 1.0-wet;
  			};

process = _<:_,crybaby_ios:dry_wet_mono;