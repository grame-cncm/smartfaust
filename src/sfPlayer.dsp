//declare name "Sampler v0.1";
declare author 		"SmartFaust (c) GRAME";
declare version "1.01"; // new mapping to android
declare licence "BSD";
declare copyright 	"(c)GRAME 2013";
 

import("math.lib"); 
import("maxmsp.lib"); 
import("music.lib"); 
import("oscillator.lib"); 
import("reduce.lib"); 
import("filter.lib"); 
import("effect.lib");

// juste comme le v1b mais avec les modif corriger pour iOS7 edition et scaling pitch offset

process = component ("sample_player_v0.1a.dsp"):*(0.5):component ("sampler_crybaby2_v0.1.dsp"):component ("sampler_pitch_shifter2_v0.1.dsp"):*(volume):component ("sampler_Zverb4_2_v0.2.dsp"):max(-0.99):min(0.99):*(out)
		with {
				volume = hslider("v:sfPlayer parameter(s)/volume [acc:1 0 -10 10 0 1][color:0 255 0][hidden:1]",1,-0.3,1,0.0001):max(0):min(1):lowpass(1,1); //[accy:1 0 1 0]
				out = checkbox ("v:sfPlayer/ON/OFF"):smooth(0.998);
		};
