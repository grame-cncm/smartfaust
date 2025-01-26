declare name      "sfPlayer";
declare version   "1.01";
declare author    "Christophe Lebreton, Stéphane Letz";
declare license   "BSD";
declare copyright "SmartFaust - GRAME(c)2013-2025";

import("stdfaust.lib");

//-------------------- MAIN -------------------------------
process = component("sample_player_v0.1a.dsp") : *(0.5)
: component("sampler_crybaby2_v0.1.dsp")
: component("sampler_pitch_shifter2_v0.1.dsp") : *(volume)
: component("sampler_Zverb4_2_v0.2.dsp") : max(-0.99) : min(0.99) : *(out)
with {
    volume = hslider("v:sfPlayer parameter(s)/volume [acc:1 0 -10 10 0 1][color:0 255 0][hidden:1]",1,-0.3,1,0.0001) : max(0) : min(1) : fi.lowpass(1,1);
    out = checkbox("v:sfPlayer/ON/OFF") : si.smooth(0.998);
};
