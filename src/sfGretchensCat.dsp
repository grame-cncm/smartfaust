//declare name 		"Gretchen's cat v1.0";
declare version 	"0.2"; // new mapping to android
declare author 		"SmartFaust (c) GRAME";
declare license 	"BSD";
declare copyright "(c)GRAME 2013";

import("math.lib"); 
import("maxmsp.lib"); 
import("music.lib"); 
import("oscillator.lib"); 
import("reduce.lib"); 
import("filter.lib"); 
import("effect.lib");

import("chroma.lib");

// cette version est un test pour suprimer les filtres d'accéléro de l'ios afin d'être compatible avec Android

lowpassfilter = lowpass(N,fc)
			with {
				fc= hslider("v:sfGretchen's Cat parameter(s)/high_cut [hidden:1] [acc:2 1 -10 10 0 0.5][color:0 255 0]",0.01,0.01,10,0.01):lowpass(1,0.5); //[accz:-1. 0. 0.5 0]
				N= 1;	// order of filter
			};

// simple FM synthesis /////////////////////////////////

FM_synth = carrier_freq <: (*(harmonicity_ratio)<: osci,*(modulation_index):*),_:+:osci:*(vol)
		with {
				carrier_freq = hslider ( "v:sfGretchen's Cat parameter(s)/freq [acc:0 0 -10 10 0 0][color:255 0 0][hidden:1]",0,0,47,1):lowpassfilter:readSoundFileChroma; //[accx:1. 0. 0 0]
				harmonicity_ratio = hslider ( "v:sfGretchen's Cat parameter(s)/harmoni [color:255 0 0][acc:0 1 -10 10 0 0.437][hidden:1]",1,0.,10,0.001):lowpassfilter; //[accx:-1. 0. 0.437 0]
				modulation_index = hslider ("v:sfGretchen's Cat parameter(s)/freqmod [acc:1 0 -10 10 0 0.6][color:255 255 0][hidden:1]", 1.4,0.,10,0.001):smooth(0.998); //[accy:1 0. 0.6 0]
				vol = hslider ( "v:sfGretchen's Cat parameter(s)/vol [acc:0 0 -10 10 0 0.6] [color:255 0 0][hidden:1]",0,0,1,0.0001):lowpassfilter; //[accx:1 0 0.6 0 ]
			}
;

process = FM_synth:*(out):max(-0.99):min(0.99)
		with {
				out = checkbox ("v:sfGretchen's Cat/ON/OFF"):smooth(0.998);
		};