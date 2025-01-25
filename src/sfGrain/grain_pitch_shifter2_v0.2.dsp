declare name "sfPitchShifter";
declare version "1.02";
declare author "Christophe Lebreton";
declare license "BSD";
declare copyright "SmartFaust - GRAME(c)2013-2025";

import("stdfaust.lib");

//-------------------- MAIN -------------------------------
process = pitchshifter;

// from FAUST example and adapted by Christophe Lebreton
//----------------------------
// very simple real time pitch shifter
//----------------------------
transpose (w, x, s, sig) = de.fdelay1s(d,sig)*ma.fmin(d/x,1) + de.fdelay1s(d+w,sig)*(1-ma.fmin(d/x,1))
with {
    i = 1 - pow(2, s/12);
    d = i : (+ : +(w) : fmod(_,w)) ~ _;
};

pitchshifter = transpose(w,x,s)
with {
    //w = hslider("window [units (ms)]", 75, 10, 1000, 1)*SR*0.001;
    w = (75)*ma.SR*(0.001);
    //x = hslider("xfade [units (ms)]", 10, 1, 500, 1)*SR*0.001 : smooth (0.99);
    x = w * 0.5;
    s = (hslider("v:sfGrain parameter(s)/shift [units (cents)] [acc:0 0 -10 0 10][color: 255 0 0 ][hidden:1] ", 0, -600, 200, 0.1))*0.01 : fi.lowpass(1,1);
};

dry_wet(x,y) = (1-c)*x + c*y
with {
    c = hslider("v:sfGrain parameter(s)/dry_wet  [acc:2 0 -10 0 10][color: 0 255 0 ][hidden:1] ", 100, 0, 100, 0.01):*(0.01) : fi.lowpass(1,1);
};

pitchshifter_drywet = _<: _,pitchshifter : dry_wet;
