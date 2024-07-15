declare name       "sfSiren";
declare version    "0.3";
declare author     "Christophe Lebreton";
declare license    "BSD";
declare copyright  "SmartFaust - GRAME(c)2013-2018";

import("stdfaust.lib");

//-------------------- MAIN -------------------------------
process = FM_synth : *(out) : max(-0.99) : min(0.99)
with {
    out = checkbox ("v:sfSiren/ON/OFF") : si.smooth(0.998);
};

//-------------------- PARAMETERS -------------------------------
// to be compatible with android smartphone
lowpassfilter = fi.lowpass(N,fc)
with {
    fc = hslider("v:sfSiren parameter(s)/high_cut [hidden:1][acc:2 0 -10 0 10][color:0 255 0]",0.01,0.01,10,0.01) : fi.lowpass(1,1);
    N = 1;// order of filter
};

// simple FM synthesis /////////////////////////////////
FM_synth = carrier_freq <: (*(harmonicity_ratio) <: os.osci,*(modulation_index):*),_ : + : os.osci : *(vol)
with {
    carrier_freq = hslider("v:sfSiren parameter(s)/freq [acc:0 0 -10 0 10][color:255 0 0][hidden:1]",300,100,2000,1) : lowpassfilter;
    harmonicity_ratio = hslider("v:sfSiren parameter(s)/harmoni [acc:0 1 -10 0 10][color:255 0 0][hidden:1]",0,0,10,0.001) : lowpassfilter;
    modulation_index = hslider("v:sfSiren parameter(s)/freqmod [acc:1 1 -10 0 10][color:255 255 0][hidden:1]", 2.5,0.,10,0.001) : lowpassfilter;
    vol = hslider("v:sfSiren parameter(s)/vol [acc:0 1 -10 0 10] [color:255 0 0][hidden:1]",0.6,0,1,0.0001) : lowpassfilter;
};
