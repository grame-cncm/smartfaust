//declare name        "WindyMoog --> hell";
declare version     "1.01"; // new mapping to android

declare author 		"SmartFaust (c) GRAME";
declare license     "BSD";
declare copyright   "(c) GRAME 2011";

import("math.lib"); 
import("maxmsp.lib"); 
import("music.lib"); 
import("oscillator.lib"); 
import("reduce.lib"); 
import("filter.lib"); 
import("effect.lib"); 


//////////////////////////////
// MOOG_VCF //////////////////
//////////////////////////////
// from effect.lib of Julius Smith
// this adapted for this project, read moog_vcf_demo for more information

moog_vcf_wind = vcfarch :*(5)
	with {
   		//freq = hslider("h:Moogfilter/Frequency [1]  [unit:PK] [style:knob]",25, 1, 88, 0.01) : pianokey2hz : smooth(0.999);
		freq = (Maccel*87)+1: pianokey2hz : smooth(0.999);
		//res = hslider("h:Moogfilter/Resonance [2] ", 0.9, 0, 1, 0.01));
		res = Maccel;
		vcfbq =  _ <: select2(1, moog_vcf_2b(res,freq), moog_vcf_2bn(res,freq)); // fix select 2biquad
   		vcfarch =  _ <: select2(1, moog_vcf(res^4,freq), vcfbq); // fix select normalized
	};


fb=hslider("v:sfWindy parameter(s)/low_cut[freq DC filter] [hidden:1]",12,0.,15,0.01);

offset = hslider ("v:sfWindy parameter(s)/threshold [hidden:1]",06,0,100,0.1);
   
dc(x)=x:dcblockerat(fb);
 
quad(x)=dc(x)*dc(x);


// offset pour eliminer le bruit du geste via les accelero -0.02
// je n'ai pas reussi a faire une expression plus style faust...:(

//Pitagora(x,y,z)=(( quad(x),quad(y),quad(z):> sqrt)-0.02):max(0.):min(1.);

accel_x = hslider("v:sfWindy parameter(s)/acc_x [acc:0 0 -10 10 0 0][color: 0 255 0 ][hidden:1]",0,-100,100,1); //[accx:1 0 0 0]
accel_y = hslider("v:sfWindy parameter(s)/acc_y [acc:1 0 -10 10 0 0][color: 0 255 0 ][hidden:1]",0,-100,100,1); //[accy:1 0 0 0]
accel_z = hslider("v:sfWindy parameter(s)/acc_z [acc:2 0 -10 10 0 0][color: 0 255 0 ][hidden:1]",0,-100,100,1); //[accz:1 0 0 0]

Accel = quad(accel_x),quad(accel_y),quad(accel_z):> sqrt:-(offset):max(0.):min(1.);

// dcblockerat from Julius Smith filter lib


lowpassfilter = lowpass(N,fc)
			with {
				fc=hslider("v:sfWindy parameter(s)/high_cut [hidden:1]",0.5,0.001,10,0.1);
				N= 1;	// order of filter
			};

//Maccel = Accel:lowpassfilter;
Maccel = Accel:amp_follower_ud (env_up,env_down)
			with {
				env_up = hslider ( "v:sfWindy parameter(s)/[1]envup [hidden:1][acc:0 0 -10 10 0 670][color: 0 255 0 ]", 500,0,1300,1)*0.001:lowpass(1,0.5); //[accx:1 0 670 0]
				env_down = hslider ( "v:sfWindy parameter(s)/[2]envdown [hidden:1][acc:1 0 -10 10 0 0][color: 0 255 0 ]", 0,0,500,1)*0.001;
			}; //[accy:1 0 0 0]

process= pink_noise :*(Maccel):moog_vcf_wind :max(-0.99):min(0.99):*(out)
		with {
				out = checkbox ("v:sfWindy/ON/OFF"):smooth(0.998);
		};
