//declare name 		"Trash Ring v0.2";
declare version 		"0.3"; // new mapping to android
//declare author 	"Christophe Lebreton";
declare author 		"SmartFaust (c) GRAME";
declare license 		"BSD";
declare copyright 	"(c)GRAME 2013";

import("math.lib"); 
import("maxmsp.lib"); 
import("music.lib"); 
import("oscillator.lib"); 
import("reduce.lib"); 
import("filter.lib"); 
import("effect.lib");

/////////////////////
// RING MODULATOR ///

ringmod = oscs(freq),_:*
		with {
				freq = hslider ( "v:sfTrashRing parameter(s)/freq [acc:0 0 -10 10 0 1000][color:255 0 0][hidden:1]",6,0,2000,1):smooth(0.998); //[accx:1 0 1000 0]
			};

dry_wet(x,y) 	= (1-c)*x + c*y
				with {
					c = hslider("v:sfTrashRing parameter(s)/dry_wet  [acc:1 0 -10 10 0 50][color:255 255 0][hidden:1] ",0,0,100,0.01):*(0.01):lowpass(1,1):max(0):min(1); //[accy:1 0 50 1]
					};

ringmod_drywet = _<: _ , ringmod: dry_wet;




process = ringmod_drywet:*(gain):*(volume)*(out)
		with {
				gain = hslider ("v:sfTrashRing parameter(s)/gain[acc:2 1 -10 10 0 0.2][color:255 255 0][hidden:1]",1,0,1,0.001):lowpass(1,1):max(0):min(1); //[accz:-1 0 0.2 0]
				volume = vslider ("h:sfTrashRing/Volume",1,0,2,0.001):smooth(0.998):max(0):min(2);	
				out = checkbox ("h:sfTrashRing/ON/OFF"):smooth(0.998);
				}
;