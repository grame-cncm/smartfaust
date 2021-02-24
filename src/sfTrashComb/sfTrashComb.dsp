declare name        "sfTrashComb";
declare version 		"1.4";
declare author 			"Christophe Lebreton";
declare license 		"BSD & STK-4.3";
declare copyright 	"SmartFaust - GRAME(c)2013-2018";

import("stdfaust.lib");

//-------------------- MAIN -------------------------------
// fb_fcomb from Julius Smith filter lib and adapted by Christophe Lebreton to SmartFaust project
// https://ccrma.stanford.edu/~jos/pasp/Feedback_Comb_Filters.html
process = fi.fb_fcomb(maxdel,del,b0,aN):*(volume):*(out)
			with {
				maxdel = 1<<16;  // 2 exposant 16 soit 65536 samples  1<<16
				freq = 1/(vslider("h:sfTrashComb parameter(s)/freq [acc:0 0 -10 0 10][color:255 0 0][hidden:1]",2300,100,20000,0.001)):si.smooth(0.99); //[accx:1 0 2300 0]
				del = freq * ma.SR:si.smooth(0.99);
				b0 = vslider("h:sfTrashComb parameter(s)/gain [acc:2 1 -10 0 10][color:0 255 0][hidden:1]",0.5,0,10,0.001):si.smooth(0.99); //[accz:-1 0 0.5 0]
				aN = vslider("h:sfTrashComb parameter(s)/feedback[acc:1 0 -10 0 10][color:255 255 0][hidden:1]",50,0,100,0.01)*(0.01):si.smooth(0.99); //[accy:1 0 50 0]
				volume = vslider ("h:sfTrashComb/Volume",1,0,2,0.001):si.smooth(0.998):max(0):min(2);
				out = checkbox ("h:sfTrashComb/ON/OFF"):si.smooth(0.998);
			};
