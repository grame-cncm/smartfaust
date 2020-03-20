//declare name        	"Capture v1.0";
declare version 		"1.30"; // new mapping to android
declare author 			"SmartFaust (c) GRAME";
declare license 		"BSD";

import("math.lib"); 
import("maxmsp.lib"); 
import("music.lib"); 
import("oscillator.lib"); 
import("reduce.lib"); 
import("filter.lib"); 
import("effect.lib"); 

record = checkbox ("v:sfCapture/RECORD [color: 255 0 0 ]");
play = checkbox ("v:sfCapture/PLAY [color: 0 255 0 ]");


// max size of buffer to be record
size = 441000;


// COUNTER LOOP //////////////////////////////////////////
// sah is like latch but reverse input for a expression
sah(x,c) = x * s : + ~ *(1-s) with { s = ((c'<=0)&(c>0)); };
//[accx:1 0 1 0]
speed = hslider ("v:sfCapture parameter(s)/speed [acc:0 0 -10 10 0 1][color: 0 255 0 ][hidden:1]",1,0.25,2,0.001):lowpass(1,1):max(0.25):min(2);

id_count_rec = (0):+~(+(1): * ((fade_lin)>0)): min(size+1); // record si le fade est > O
id_count_play = (0):+~(+(speed): * (play)): fmod(_,fin_rec:int); // ce code acuumule un grand nombre qui fait perdre de la précision, mais c'est ce qui est interessant d'un point de vue musicale... a terme remplacer ce mauvais code par un code qui gere ce comportement ....etc
//id_count_play = _~(+(speed): * (play)): fmod(_,fin_rec:int);
//id_count_play =  fmod(_,fin_rec)~(+(speed): * (play)): int;
//id_count_play =  fmod(_,max(1,int(fin_rec)))~(+(speed): *(play)); // ce code est la bonne version pour resoudre le problème d'accumulation dans la boucle

fin_rec = sah(id_count_rec:mem,fade_lin==0);// fin record si le fade est == O
			

// START STOP RECORD /////////////////////////////////////////////
init_rec = select2(record,size+1,_);

// FADER IN & OUT ////////////////////////////////////////////////
// define the level of each step increase or decrease to create fade in/out

time_fade = 0.1;
state = record;

// version linear fade
base_amp = 1,(SR)*(time_fade):/;
fade_lin = select2(state,(-1)*(base_amp),base_amp):+~(min((1)-base_amp):max(base_amp));



// 0.00313 is about -50db to get transition with previous technologie of rythm developped for "thread" piece
// this point will be change as soon as env_ud will be change to generate enveloppe of pulse

// BUFFER SEQUENCER //////////////////////////////////////////
wr_index = rwtable(size+1, 0., windex,_, rindex) // le 0. dans rwtable est la valeur de l'init et son type défini le type de la table
	with {
			
			rindex = id_count_play:int;
			windex = id_count_rec:int;
		};

//--------------------------process----------------------------
//
// 	A stereo smooth delay with a feedback control
//  
//	This example shows how to use sdelay, a delay that doesn't
//  click and doesn't transpose when the delay time is changed
//-------------------------------------------------------------


idelay 	= ((+ : sdelay(N, interp, dtime)) ~ *(fback))
	with	{
				N 		= int(2^19); // => max delay = number of sample
				//interp 	= hslider("interpolation[unit:ms][style:knob]",75,1,100,0.1)*SR/1000.0; 
				interp = (75)*SR*(0.001);
				//[accz:-1 0.8 250 1]
				dtime	= hslider("v:sfCapture parameter(s)/delay[unit:ms] [acc:2 1 -10 10 0.8 250][color:255 0 0][hidden:1]", 0, 0, 10000, 0.01)*SR/1000.0;
				//[accx:1 -0.5 50 1]
				fback 	= hslider("v:sfCapture parameter(s)/feedback [acc:0 0 -10 10 -0.5 50][color:255 255 0][hidden:1] ",0,0,100,0.1)/100.0; 
			};

dry_wet(x,y) 	= (1-c)*x + c*y
				with {
					//[accy:1 0 0 1]
					c = hslider("v:sfCapture parameter(s)/dry_wet  [acc:1 0 -10 10 0 0][color:255 255 0][hidden:1] ",0,0,100,0.01):*(0.01):smooth(0.998);
					};

idelay_drywet =  _<: _ , idelay : dry_wet;



process =_,(fade_lin):*:wr_index:idelay_drywet:*(volume)
			with {
				//[accz:-1 -0.8 1 0]
				volume = hslider("v:sfCapture parameter(s)/volume [acc:2 1 -10 10 -0.8 1][color:0 255 0][hidden:1]",1,-0.1,1,0.001):max(0):min(1):lowpass(1,1);
				};
			
			
			