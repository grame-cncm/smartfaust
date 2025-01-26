declare name       "sfGretchenCat";
declare version    "0.3";
declare author     "Christophe Lebreton";
declare license    "BSD";
declare copyright  "SmartFaust - GRAME(c)2013-2018";

import("stdfaust.lib");

//-------------------- MAIN -------------------------------
process = FM_synth : *(out) : max(-0.99) : min(0.99)
with {
    out = checkbox("v:sfGretchenCat/ON/OFF") : si.smooth(0.998);
};

//-----------------------------------------------------------
// Defined Chroma Table of carrier FM synthesis
chroma = waveform {130.81, 138.59, 146.83, 155.56, 164.81, 174.61, 184.99,
195.99, 207.65, 220.00, 233.08, 246.94, 261.62, 277.18,
293.66, 311.12, 329.62, 349.22, 369.99, 391.99, 415.30,
440.00, 466.16, 493.88, 523.25, 554.36, 587.32, 622.25,
659.25, 698.45, 739.98, 783.99, 830.60, 880.00, 932.32,
987.76, 1046.50, 1108.73, 1174.65, 1244.50, 1318.51, 1396.91,
1479.97, 1567.98, 1661.21, 1760.00, 1864.65, 1975.53 };

readSoundFileChroma = int:rdtable(chroma);
//-----------------------------------------------------------
lowpassfilter = fi.lowpass(N,fc)
with {
    fc = hslider("v:sfGretchenCat parameter(s)/high_cut [hidden:1] [acc:2 1 -10 0 10][color:0 255 0]",0.5,0.01,10,0.01):fi.lowpass(1,0.5);
    N = 1;// order of filter
};

//-----------------------------------------------------------
// simple FM synthesis /////////////////////////////////
FM_synth = carrier_freq <: (*(harmonicity_ratio) <: os.osci,*(modulation_index):*),_ : + : os.osci : *(vol)
with {
    carrier_freq = hslider("v:sfGretchenCat parameter(s)/freq [acc:0 0 -10 0 10][color:255 0 0][hidden:1]",0,0,47,1) : lowpassfilter : readSoundFileChroma;
    harmonicity_ratio = hslider("v:sfGretchenCat parameter(s)/harmoni [acc:0 1 -10 0 10][color:255 0 0][hidden:1]",0.437,0.,10,0.001) : lowpassfilter;
    modulation_index = hslider("v:sfGretchenCat parameter(s)/freqmod [acc:1 0 -10 0 10][color:255 255 0][hidden:1]", 0.6,0.,10,0.001) : si.smooth(0.998);
    vol = hslider("v:sfGretchenCat parameter(s)/vol [acc:0 0 -10 0 10][color:255 0 0][hidden:1]",0.6,0,1,0.0001) : lowpassfilter;
};
