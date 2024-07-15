declare name        "Capture";
declare version     "1.4";
declare author      "Christophe Lebreton";
declare license     "BSD";
declare copyright   "SmartFaust - GRAME(c)2013-2018";

import("stdfaust.lib");

//-------------------- MAIN -------------------------------
process =_,(fade_lin) : * : wr_index:idelay_drywet : *(volume)
with {
    volume = hslider("v:sfCapture parameter(s)/volume [acc:2 1 -10 -0.8 10][color:0 255 0][hidden:1]",1,-0.1,1,0.001) : max(0) : min(1) : fi.lowpass(1,1);
};

//--------------------- INTERFACE ---------------------------
record = checkbox("v:sfCapture/RECORD [color: 255 0 0 ]");
play = checkbox("v:sfCapture/PLAY [color: 0 255 0 ]");

//-----------------------------------------------------------
// max size of buffer to be record
size = 441000;

// COUNTER LOOP //////////////////////////////////////////
// sah is like latch but reverse input for a expression
sah(x,c) = x * s : + ~ *(1-s) with { s = ((c'<=0)&(c>0)); };

speed = hslider("v:sfCapture parameter(s)/speed [acc:0 0 -10 0 10][color: 0 255 0 ][hidden:1]",1,0.25,2,0.001):fi.lowpass(1,1):max(0.25):min(2);

id_count_rec = (0):+~(+(1): * ((fade_lin)>0)) : min(size+1); // recording if fade > O
// this code acuumulates a large number which makes you lose precision, it is a musical choice ;)
id_count_play = (0):+~(+(speed): * (play)) : fmod(_,fin_rec:int);
// this code is the correct version to solve the accumulation problem in the loop
//id_count_play = fmod(_,max(1,int(fin_rec)))~(+(speed): *(play));

fin_rec = sah(id_count_rec:mem,fade_lin==0);// end of record if fade == O

// START STOP RECORD /////////////////////////////////////////////
init_rec = select2(record,size+1,_);

// FADER IN & OUT ////////////////////////////////////////////////
// define the level of each step increase or decrease to create fade in/out
time_fade = 0.1; // sec
state = record;

// version of linear fade
base_amp = 1,(ma.SR)*(time_fade):/;
fade_lin = select2(state,(-1)*(base_amp),base_amp):+~(min((1)-base_amp):max(base_amp));

// BUFFER SEQUENCER //////////////////////////////////////////
wr_index = rwtable(size+1, 0., windex,_, rindex)
with {
    rindex = id_count_play:int;
    windex = id_count_rec:int;
};

//-------------------------------------------------------------
// A stereo smooth delay with a feedback control
idelay = ((+ : de.sdelay(N, interp, dtime)) ~ *(fback))
with {
    N = int(2^19); // => max delay = number of sample
    //interp = hslider("interpolation[unit:ms][style:knob]",75,1,100,0.1)*SR/1000.0;
    interp = (75)*ma.SR*(0.001);
    dtime = hslider("v:sfCapture parameter(s)/delay[unit:ms] [acc:2 1 -10 0.8 10][color:255 0 0][hidden:1]", 250, 0, 10000, 0.01)*ma.SR/1000.0;
    fback = hslider("v:sfCapture parameter(s)/feedback [acc:0 0 -10 -0.5 10][color:255 255 0][hidden:1] ",50,0,100,0.1)/100.0;
};

dry_wet(x,y) = (1-c)*x + c*y
with {
    c = hslider("v:sfCapture parameter(s)/dry_wet [acc:1 0 -10 0 10][color:255 255 0][hidden:1] ",0,0,100,0.01):*(0.01) : si.smooth(0.998);
};

idelay_drywet = _<: _,idelay : dry_wet;
