//declare name 		"Trash shift v1.0";
declare version 		"1.01"; // new mapping to android
declare author 		"SmartFaust (c) GRAME";
declare license 		"BSD";
declare copyright 	"(c)GRAME 2006";

import("music.lib");
import("math.lib");
import("effect.lib");
import("oscillator.lib");
import("filter.lib");

// from FAUST example and adapted by Christophe Lebreton

//----------------------------
// very simple real time pitch shifter
//----------------------------



transpose (w, x, s, sig)  =
	fdelay1s(d,sig)*fmin(d/x,1) + fdelay1s(d+w,sig)*(1-fmin(d/x,1))
	   	with {
			i = 1 - pow(2, s/12);
			d = i : (+ : +(w) : fmod(_,w)) ~ _;
	        };
// faire une version en remplacent les xfade par des buffers plus "doux"

pitchshifter =  transpose(w,x,s)
		with {
			//w = hslider("window [units (ms)]", 75, 10, 1000, 1)*SR*0.001;
			w = (75)*SR*(0.001);
			//x = hslider("xfade [units (ms)]", 10, 1, 500, 1)*SR*0.001 : smooth (0.99);
			x = w * 0.5;
			s = (hslider("v:sfTrashShift parameter(s)/shift [units (cents)] [acc:0 1 -10 10 0 0][color: 255 0 0 ][hidden:1]", 0, -3600, 3600, 0.1))*0.01 : smooth (0.998); //[accx:-1 0 0 0]
			};

dry_wet(x,y) 	= (1-c)*x + c*y
				with {
					c = hslider("v:sfTrashShift parameter(s)/dry_wet  [acc:1 1 -10 10 0 100][color: 255 255 0 ][hidden:1] ",0,0,100,0.01):*(0.01):lowpass(1,1):max(0):min(1); //[accy:-1 0 100 0]
					};

pitchshifter_drywet = _<: _ , pitchshifter: dry_wet:*(volume):*(gain):*(out)
		with {
				volume = vslider ("h:sfTrashShift/Volume",1,0,2,0.001):smooth(0.998):max(0):min(2);
				gain = hslider ("v:sfTrashShift parameter(s)/gain[acc:2 1 -10 10 0 0.2][color:255 255 0][hidden:1]",1,0,1,0.001):lowpass(1,1):max(0):min(1);	//[accz:-1 0 0.2 0]
				out = checkbox ("h:sfTrashShift/ON/OFF"):smooth(0.998);
				};

process = pitchshifter_drywet;
		
