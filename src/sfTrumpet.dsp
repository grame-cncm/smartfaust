//declare name 		"Trumpet #7 v1.0";
declare version 		"0.2"; // new mapping to android

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

import("music.lib");
import("instrument.lib");

// Definition of bsmooth added by YO 2020/03/20
// was not defined in the original file, but it is missing

bsmooth(c) = +(i) ~ _
with {
	i = (c-c@n)/n;
	n = min(4096, max(1, BS));
};

//==================== GUI SPECIFICATION ================
//[accx:1 0. 165 0]
freq = hslider ( "v:sfTrumpet parameter(s)/freq [1] [acc:0 0 -10 10 0 165][color:255 0 0][hidden:1]",117,117,290,1):lowpass(1,0.5);
//gain = nentry("h:Basic_Parameters/gain [1][hidden:1][tooltip:Gain (value between 0 and 1)]",1,0,1,0.01):smooth(0.998);
gain = 1; 
gate = checkbox("v:sfTrumpet/[1]ON/OFF");
//[accy:1 0 0.095 0]
pressure = hslider("v:sfTrumpet parameter(s)/Pressure[2][tooltip:A value between 0 and 1][color:255 255 0][acc:1 0 -10 10 0 0.095][hidden:1]",0.01,0.001,0.198,0.001) : bsmooth;
//[accx:1 0 0.688 0]
lipTension = hslider("v:sfTrumpet parameter(s)/Lip_Tension[2][tooltip:A value between 0 and 1][color:255 0 0][acc:0 0 -10 10 0 0.688][hidden:1]",0.626,0.626,0.751,0.001);
//slideLength = hslider("h:Physical_and_Nonlinearity/v:Physical_Parameters/Slide_Length[2][tooltip:A value between 0 and 1]",0.326,0.01,1,0.001);
slideLength = 0.01;

/*typeModulation = nentry("h:Physical_and_Nonlinearity/v:Nonlinear_Filter_Parameters/Modulation_Type [3][tooltip: 0=theta is modulated by the incoming signal; 1=theta is modulated by the averaged incoming signal;
2=theta is modulated by the squared incoming signal; 
3=theta is modulated by a sine wave of frequency freqMod;
4=theta is modulated by a sine wave of frequency freq;]",0,0,4,1);
*/
typeModulation = 1;
//nonLinearity = hslider("h:Physical_and_Nonlinearity/v:Nonlinear_Filter_Parameters/Nonlinearity [3][tooltip:Nonlinearity factor (value between 0 and 1)]",0,0,1,0.01);
nonLinearity = 0.1;
//frequencyMod = hslider("h:Physical_and_Nonlinearity/v:Nonlinear_Filter_Parameters/Mod_Freq [3][unit:Hz][tooltip:Frequency of the sine wave for the modulation of theta (works if Modulation Type=3)]",329.7,20,1000,0.1);
frequencyMod = 204.8;
//nonLinAttack = hslider("h:Physical_and_Nonlinearity/v:Nonlinear_Filter_Parameters/NL_Attack[3][unit:s][Attack duration of the nonlinearity]",0.1,0,2,0.01);
nonLinAttack = 0;

//vibratoFreq = hslider("h:Envelopes_and_Vibrato/v:Vibrato_Parameters/V_Freq [4][unit:Hz][color:255 0 0][accx:-1.3 0 7.5 0]",6,1,15,0.1);
vibratoFreq = 0;
//vibratoGain = hslider("h:Envelopes_and_Vibrato/v:Vibrato_Parameters/V_Gain[4][tooltip:A value between 0 and 1][color:255 255 0][accy:1 0 0.5 0]",0.05,0,1,0.01);
vibratoGain = 0;
//vibratoBegin = hslider("h:Envelopes_and_Vibrato/v:Vibrato_Parameters/V_Begin[4][unit:s][tooltip:Vibrato silence duration before attack]",1.954,0,2,0.01);
vibratoBegin = 0;
//vibratoAttack = hslider("h:Envelopes_and_Vibrato/v:Vibrato_Parameters/V_Attack [4][unit:s][tooltip:Vibrato attack duration]",0,0,2,0.01);
vibratoAttack = 0;
//vibratoRelease = hslider("h:Envelopes_and_Vibrato/v:Vibrato_Parameters/V_Release [4][unit:s][tooltip:Vibrato release duration]",0,0,2,0.01);
vibratoRelease = 0;
//envelopeAttack = hslider("h:Envelopes_and_Vibrato/v:Envelope_Parameters/E_Attack [5][unit:s][tooltip:Envelope attack duration]",0.005,0,2,0.01);
envelopeAttack = 0.005;
//envelopeDecay = hslider("h:Envelopes_and_Vibrato/v:Envelope_Parameters/E_Decay [5][unit:s][tooltip:Envelope decay duration]",0.001,0,2,0.01);
envelopeDecay = 0.001;
//envelopeRelease = hslider("h:Envelopes_and_Vibrato/v:Envelope_Parameters/E_Release [5][unit:s][tooltip:Envelope release duration]",0,0,2,0.01);
envelopeRelease = 0;

//==================== SIGNAL PROCESSING ================

//----------------------- Nonlinear filter ----------------------------
//nonlinearities are created by the nonlinear passive allpass ladder filter declared in filter.lib

//nonlinear filter order
nlfOrder = 6; 

//attack - sustain - release envelope for nonlinearity (declared in instrument.lib)
envelopeMod = asr(nonLinAttack,100,envelopeRelease,gate);

//nonLinearModultor is declared in instrument.lib, it adapts allpassnn from filter.lib 
//for using it with waveguide instruments
NLFM =  nonLinearModulator((nonLinearity : smooth(0.999)),envelopeMod,freq,
     typeModulation,(frequencyMod : smooth(0.999)),nlfOrder);

//----------------------- Synthesis parameters computing and functions declaration ----------------------------

//lips are simulated by a biquad filter whose output is squared and hard-clipped, bandPassH and saturationPos are declared in instrument.lib
lipFilterFrequency = freq*pow(4,(2*lipTension)-1);
lipFilter = *(0.03) : bandPassH(lipFilterFrequency,0.997) <: * : saturationPos;

//stereoizer is declared in instrument.lib and implement a stereo spacialisation in function of 
//the frequency period in number of samples 
stereo = stereoizer(SR/freq);

//delay times in number of samples
slideTarget = ((SR/freq)*2 + 3)*(0.5 + slideLength);
boreDelay = fdelay(4096,slideTarget);

//----------------------- Algorithm implementation ----------------------------

//vibrato
vibrato = vibratoGain*osc(vibratoFreq)*envVibrato(vibratoBegin,vibratoAttack,100,vibratoRelease,gate);

//envelope (Attack / Decay / Sustain / Release), breath pressure and vibrato
breathPressure = pressure*adsr(envelopeAttack,envelopeDecay,100,envelopeRelease,gate) + vibrato;
mouthPressure = 0.3*breathPressure;

//scale the delay feedback
borePressure = *(0.85);

//differencial presure
deltaPressure = mouthPressure - _;

trumpet = (borePressure <: deltaPressure,_ : 
	  (lipFilter <: *(mouthPressure),(1-_)),_ : _, * :> + :
	  dcblocker) ~ (boreDelay : NLFM) :
	  *(gain)*4;
	  

////////////////////////////////////////
// ZITA VERB 4 /////////////////////////
////////////////////////////////////////

lowpassmotion = lowpass(N,fc)
			with {
				//fc= hslider("high_cut [hidden:1]",10,0.01,10,0.01);
				fc=10;
				N= 1;	// order of filter
			};

// from effect.lib but with only N=4 for mobilephone application

zita_rev_fdn4(f1,f2,t60dc,t60m,fsmax) =
  ((bus(2*N) :> allpass_combs(N) : feedbackmatrix(N)) ~
   (delayfilters(N,freqs,durs) : fbdelaylines(N)))
with {
  N = 4;

  // Delay-line lengths in seconds:
  apdelays = (0.020346, 0.024421, 0.031604, 0.027333, 0.022904,
              0.029291, 0.013458, 0.019123); // feedforward delays in seconds
  tdelays = ( 0.153129, 0.210389, 0.127837, 0.256891, 0.174713,
              0.192303, 0.125000, 0.219991); // total delays in seconds
  tdelay(i) = floor(0.5 + SR*take(i+1,tdelays)); // samples
  apdelay(i) = floor(0.5 + SR*take(i+1,apdelays));
  fbdelay(i) = tdelay(i) - apdelay(i);
  // NOTE: Since SR is not bounded at compile time, we can't use it to
  // allocate delay lines; hence, the fsmax parameter:
  tdelaymaxfs(i) = floor(0.5 + fsmax*take(i+1,tdelays));
  apdelaymaxfs(i) = floor(0.5 + fsmax*take(i+1,apdelays));
  fbdelaymaxfs(i) = tdelaymaxfs(i) - apdelaymaxfs(i);
  nextpow2(x) = ceil(log(x)/log(2.0));
  maxapdelay(i) = int(2.0^max(1.0,nextpow2(apdelaymaxfs(i))));
  maxfbdelay(i) = int(2.0^max(1.0,nextpow2(fbdelaymaxfs(i))));

  apcoeff(i) = select2(i&1,0.6,-0.6);  // allpass comb-filter coefficient
  allpass_combs(N) =
    par(i,N,(allpass_comb(maxapdelay(i),apdelay(i),apcoeff(i)))); // filter.lib
  fbdelaylines(N) = par(i,N,(delay(maxfbdelay(i),(fbdelay(i)))));
  freqs = (f1,f2); durs = (t60dc,t60m);
  delayfilters(N,freqs,durs) = par(i,N,filter(i,freqs,durs));
  feedbackmatrix(N) = hadamard(N); // math.lib

  staynormal = 10.0^(-20); // let signals decay well below LSB, but not to zero

  special_lowpass(g,f) = smooth(p) with {
    // unity-dc-gain lowpass needs gain g at frequency f => quadratic formula:
    p = mbo2 - sqrt(max(0,mbo2*mbo2 - 1.0)); // other solution is unstable
    mbo2 = (1.0 - gs*c)/(1.0 - gs); // NOTE: must ensure |g|<1 (t60m finite)
    gs = g*g;
    c = cos(2.0*PI*f/float(SR));
  };

  filter(i,freqs,durs) = lowshelf_lowpass(i)/sqrt(float(N))+staynormal
  with {
    lowshelf_lowpass(i) = gM*low_shelf1_l(g0/gM,f(1)):special_lowpass(gM,f(2));
    low_shelf1_l(G0,fx,x) = x + (G0-1)*lowpass(1,fx,x); // filter.lib
    g0 = g(0,i);
    gM = g(1,i);
    f(k) = take(k,freqs);
    dur(j) = take(j+1,durs);
    n60(j) = dur(j)*SR; // decay time in samples
    g(j,i) = exp(-3.0*log(10.0)*tdelay(i)/n60(j));
  };
};


zita_rev1_stereo4(rdel,f1,f2,t60dc,t60m,fsmax) =
   zita_in_delay(rdel)
 : zita_distrib2(N)
 : zita_rev_fdn4(f1,f2,t60dc,t60m,fsmax)
 : output2(N)
with {
 N = 4;
 output2(N) = outmix(N) : *(t1),*(t1);
 t1 = 0.37; // zita-rev1 linearly ramps from 0 to t1 over one buffer
 outmix(4) = !,butterfly(2),!; // probably the result of some experimenting!
 outmix(N) = outmix(N/2),par(i,N/2,!);
};


// direct from effect.lib and adapted by Christophe Lebreton with EQ and some parameters ranges changed .... no level out sliders

//---------------------------------- zita_rev1 ------------------------------
// Example GUI for zita_rev1_stereo (mostly following the Linux zita-rev1 GUI).
//
// Only the dry/wet and output level parameters are "dezippered" here.  If
// parameters are to be varied in real time, use "smooth(0.999)" or the like
// in the same way.
//
// REFERENCE:
//   http://www.kokkinizita.net/linuxaudio/zita-rev1-doc/quickguide.html
//
// DEPENDENCIES:
//   filter.lib (peak_eq_rm)


zita_rev3(x,y) = zita_rev1_stereo4(rdel,f1,f2,t60dc,t60m,fsmax,x,y)
	  : out_eq : dry_wet(x,y)
with {

  fsmax = 48000.0;  // highest sampling rate that will be used

  



//  rdel = vslider(" Pre_Delay [hidden:1]", 50,1,100,1);
rdel=50;


//  f1 = vslider("LF X [hidden:1]", 500, 50, 1000, 1);
f1=500;
//[accy:-1 0 7 0]
  t60dc = hslider("v:sfTrumpet parameter(s)/Low RT60 [acc:1 1 -10 10 0 7][color:255 255 0][hidden:1]", 2, 1, 16, 0.1):lowpass(1,1):max(1):min(16);
//[accy:-1 0 7 0]
  t60m = hslider("v:sfTrumpet parameter(s)/Mid RT60 [acc:1 1 -10 10 0 7][color:255 255 0][hidden:1]", 3, 1, 16, 0.1):lowpass(1,1):max(1):min(16);

  f2 = hslider("v:sfTrumpet parameter(s)/HF Damping[hidden:1]", 13340, 1500, 0.49*fsmax, 1);

out_eq = pareq_stereo(eq1f,eq1l,eq1q) : pareq_stereo(eq2f,eq2l,eq2q);// Zolzer style peaking eq (not used in zita-rev1) (filter.lib):
// pareq_stereo(eqf,eql,Q) = peak_eq(eql,eqf,eqf/Q), peak_eq(eql,eqf,eqf/Q);
// Regalia-Mitra peaking eq with "Q" hard-wired near sqrt(g)/2 (filter.lib):
//pareq_stereo(eqf,eql,Q) = peak_eq_rm(eql,eqf,tpbt), peak_eq_rm(eql,eqf,tpbt)
//  with {
//  tpbt = wcT/sqrt(g); // tan(PI*B/SR) where B bandwidth in Hz (Q^2 ~ g/4)
//  wcT = 2*PI*eqf/SR;  // peak frequency in rad/sample
//g = db2linear(eql); // peak gain
//  };

// pareq use directly peak_eq_cp from filter.lib

pareq_stereo (eqf,eql,Q) = peak_eq_cq (eql,eqf,Q) , peak_eq_cq (eql,eqf,Q) ;

  

//  eq1f = vslider("F1 [hidden:1]", 315, 40, 10000, 1);
eq1f=315;
  
//  eq1l = vslider("L1 [hidden:1]", 0, -15, 15, 0.1);
eq1l=0;
  
//  eq1q = vslider("Q1 [hidden:1]", 3, 0.1, 10, 0.1);
eq1q=3;
  
  

//  eq2f = vslider("F2 [hidden:1]", 3000, 40, 10000, 1);
eq2f=3000;
  
//  eq2l = vslider("L2 [hidden:1]", 0, -15, 15, 0.1);
eq2l=0;

//  eq2q = vslider("Q2 [hidden:1]", 3, 0.1, 10, 0.1);
eq2q=3;
  

  dry_wet(x,y) = *(wet) + dry*x, *(wet) + dry*y 
		with { 
    		wet = 0.5*(drywet+1.0);
    		dry = 1.0-wet; 
  		};
//[accy:-1. 0. 20 0]
  drywet = (hslider("v:sfTrumpet parameter(s)/Dry/Wet Mix [acc:1 1 -10 10 0 20][color:255 255 0][hidden:1]", 0, 0, 55, 0.1)*0.02)-1:lowpass(1,1):max(-1):min(1);

 // out_level = *(gain),*(gain);

//  gain = out_group(vslider("[2] Level [unit:dB] [style:knob] [tooltip: Output scale factor]", -0, -70, 40, 0.1)) : db2linear; 

};


Zverb4 = _<:zita_rev3:>_;

process = trumpet : Zverb4 :max(-0.99):min(0.99);
		