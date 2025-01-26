declare name        "sfTrashShift";
declare version     "1.1";
declare author      "Christophe Lebreton";
declare license     "BSD";
declare copyright   "SmartFaust - GRAME(c)2013-2018";

import("stdfaust.lib");

//-------------------- MAIN -------------------------------
process = pitchshifter_drywet;

//--------------------------------------------------------------------------------------------------
// from FAUST example and adapted by Christophe Lebreton
// very simple real time pitch shifter
transpose (w, x, s, sig) = de.fdelay1s(d,sig)* ma.fmin(d/x,1) + de.fdelay1s(d+w,sig)*(1- ma.fmin(d/x,1))
with {
    i = 1 - pow(2, s/12);
    d = i : (+ : +(w) : fmod(_,w)) ~ _;
};

pitchshifter =  transpose(w,x,s)
with {
    //w = hslider("window [units (ms)]", 75, 10, 1000, 1)*SR*0.001;
    w = (75)* ma.SR*(0.001);
    //x = hslider("xfade [units (ms)]", 10, 1, 500, 1)*SR*0.001 : smooth (0.99);
    x = w * 0.5;
    s = (hslider("v:sfTrashShift parameter(s)/shift [units (cents)][acc:0 1 -10 0 10][color: 255 0 0 ][hidden:1]", 0, -3600, 3600, 0.1))*0.01 : si.smooth (0.998);
};

dry_wet(x,y) = (1-c)*x + c*y
with {
    c = hslider("v:sfTrashShift parameter(s)/dry_wet [acc:1 1 -10 0 10][color: 255 255 0][hidden:1]",100,0,100,0.01):*(0.01):fi.lowpass(1,1):max(0):min(1);
};

pitchshifter_drywet = _<: _ , pitchshifter : dry_wet:*(volume) : *(gain) : *(out)
with {
    volume = vslider("h:sfTrashShift/Volume",1,0,2,0.001) : si.smooth(0.998) : max(0) : min(2);
    gain = hslider("v:sfTrashShift parameter(s)/gain[acc:2 1 -10 0 10][color:255 255 0][hidden:1]",0.2,0,1,0.001) : fi.lowpass(1,1) : max(0) : min(1);
    out = checkbox("h:sfTrashShift/ON/OFF") : si.smooth(0.998);
};
