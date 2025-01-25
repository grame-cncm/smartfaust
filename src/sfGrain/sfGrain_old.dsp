declare name         "sfGrain";
declare version      "1.04";
declare author       "Christophe Lebreton, Stéphane Letz";
declare license      "BSD";
declare copyright    "SmartFaust - GRAME(c)2013-2025";

declare soundfiles "https://raw.githubusercontent.com/grame-cncm/smartfaust/master/src/sfGrain";

import("stdfaust.lib");

//-------------------- MAIN -------------------------------
process = component("grain_out_v0.6.dsp") : component("grain_pitch_shifter2_v0.2.dsp") : max(-0.99) : min(0.99) : *(volume) : *(out)
with {
    volume = hslider("grain_volume [acc:1 0 -10 0 10][color:0 255 0][hidden:1]",1,-0.1,1,0.001) : max(0) : min(1) : fi.lowpass(1,1);
    out = checkbox("v:sfGrain/[1]ON/OFF") : si.smooth(0.998);
};
