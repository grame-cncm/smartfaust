declare name        "sfTrashRing";
declare version 		"0.4";
declare author 			"Christophe Lebreton";
declare license 		"BSD";
declare copyright 	"SmartFaust - GRAME(c)2013-2018";

import("stdfaust.lib");

//-------------------- MAIN -------------------------------
process = ringmod_drywet:*(gain):*(volume)*(out)
		with {
				gain = hslider ("v:sfTrashRing parameter(s)/gain[acc:2 1 -10 0 10][color:255 255 0][hidden:1]",0.2,0,1,0.001):fi.lowpass(1,1):max(0):min(1);
				volume = vslider ("h:sfTrashRing/Volume",1,0,2,0.001):si.smooth(0.998):max(0):min(2);
				out = checkbox ("h:sfTrashRing/ON/OFF"):si.smooth(0.998);
				};

//-----------------------------------------------------------
/////////////////////
// RING MODULATOR ///
ringmod = os.oscs(freq),_:*
		with {
				freq = hslider ( "v:sfTrashRing parameter(s)/freq [acc:0 0 -10 0 10][color:255 0 0][hidden:1]",1000,0,2000,1):si.smooth(0.998);
			};

dry_wet(x,y) 	= (1-c)*x + c*y
				with {
					c = hslider("v:sfTrashRing parameter(s)/dry_wet  [acc:1 0 -10 0 10][color:255 255 0][hidden:1] ",50,0,100,0.01):*(0.01):fi.lowpass(1,1):max(0):min(1); 
					};

ringmod_drywet = _<: _ , ringmod: dry_wet;
