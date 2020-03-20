//declare name        	"Trash Comb v1.0";
declare version 		"1.30"; //// new mapping to android
//declare author 		"Julius O. Smith ";
declare author 		"SmartFaust (c) GRAME";
declare license 		"STK-4.3";

import("math.lib");
import("music.lib");
import("filter.lib");

// direct from Julius Smith filter lib and adapted by Christophe Lebreton
// https://ccrma.stanford.edu/~jos/pasp/Feedback_Comb_Filters.html


process = fb_fcomb(maxdel,del,b0,aN):*(volume):*(out)
			with {
				maxdel = 1<<16;  // 2 exposant 16 soit 65536 samples  1<<16
				freq = 1/(vslider("h:sfTrashComb parameter(s)/freq [acc:0 0 -10 10 0 2300][color:255 0 0][hidden:1]",500,100,20000,0.001)):smooth(0.99); //[accx:1 0 2300 0]
				del = freq *SR:smooth(0.99);
				b0 = vslider("h:sfTrashComb parameter(s)/gain [acc:2 1 -10 10 0 0.5][color:0 255 0][hidden:1]",1,0,10,0.001):smooth(0.99); //[accz:-1 0 0.5 0]
				aN = vslider("h:sfTrashComb parameter(s)/feedback[acc:1 0 -10 10 0 50][color:255 255 0][hidden:1]",80,0,100,0.01)*(0.01):smooth(0.99); //[accy:1 0 50 0]
				volume = vslider ("h:sfTrashComb/Volume",1,0,2,0.001):smooth(0.998):max(0):min(2);
				out = checkbox ("h:sfTrashComb/ON/OFF"):smooth(0.998);
			};
