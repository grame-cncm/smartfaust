declare name 		"PitchShifter";
declare version 		"1.01";// new mapping to android
declare author 		"GRAME";
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

lowpassmotion = lowpass(N,fc)
			with {
				//fc= hslider("h:motion filter/high_cut [hidden:1]",10,0.01,10,0.01);
				fc=10;
				N= 1;	// order of filter
			};

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
			s = (hslider("v:sfPlayer parameter(s)/shift [units (cents)] [acc:0 0 -10 10 0 0][color: 255 0 0 ][hidden:1] ", 0, -200, 200, 0.1))*0.01 :lowpass(1,1); //[accx:1 0 0 1]
			};

dry_wet(x,y) 	= (1-c)*x + c*y
				with {
					c = hslider("v:sfPlayer parameter(s)/dry_wet  [acc:2 0 -10 10 0 100][color: 0 255 0 ][hidden:1] ",0,0,100,0.01):*(0.01):lowpass(1,1); //[accz:1 0 100 0]
					};

pitchshifter_drywet =  _<: _ , pitchshifter: dry_wet;

process = pitchshifter_drywet;
		
