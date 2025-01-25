declare name         "sfGrain_out";
declare version      "1.02";
declare author       "Christophe Lebreton";
declare license      "BSD";
declare copyright    "SmartFaust - GRAME(c)2013-2025";

import("stdfaust.lib");
import("grain_v0.1.lib");

//-------------------- MAIN -------------------------------
process = vgroup("select your sample 1 to 7",(player_A, player_B, player_C, player_D, player_E, player_F, player_G)
            : multiselect(7, select_sample));

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Accelerometer Part ///////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Usage: _:*(Maccel):_ // this function is useful for smooth control from accelerometers
accel_x = hslider("v:sfGrain parameter(s)/acc_x [acc:0 0 -10 0 10][color: 0 255 0 ][hidden:1]", 0, -100, 100, 1);
accel_y = hslider("v:sfGrain parameter(s)/acc_y [acc:1 0 -10 0 10][color: 0 255 0 ][hidden:1]", 0, -100, 100, 1);
accel_z = hslider("v:sfGrain parameter(s)/acc_z [acc:2 0 -10 0 10][color: 0 255 0 ][hidden:1]", 0, -100, 100, 1);

lowpassfilter = fi.lowpass(N,fc)
with {
    //fc = hslider("high_cut [hidden:0]",0.5,0.001,10,0.1);
    fc = 0.5;
    N = 1; // order of filter
};

lowpassmotion = fi.lowpass(N,fc)
with {
    //f c= hslider("h:motion filter/high_cut [hidden:1]",10,0.01,10,0.01);
    fc = 10;
    N = 1;    // order of filter
};

//fb = hslider("low_cut [hidden:1]",15,0.1,15,0.01);
fb = 15;
dc(x) = x:fi.dcblockerat(fb);

//offset = hslider ("thr_accel [hidden:1]",9.99,0,9.99,0.01);
offset = 9.99;

quad(x) = dc(x)*dc(x);
Accel = quad(accel_x),quad(accel_y),quad(accel_z):> sqrt:-(offset):/((10)-(offset)):max(0.):min(1.);

// Maccel mean Motion with accelerometer
// Maccel = Accel:lowpassfilter:min(1.);
Maccel = Accel:an.amp_follower_ud(env_up,env_down)
with {
    env_up = hslider("v:sfGrain parameter(s)/fade_in [acc:1 0 -10 0 10][color: 255 255 0 ]", 130,0,1000,1)*0.001 : fi.lowpass(1,1); //[accy:1 0 130 0]
    env_down = hslider("v:sfGrain parameter(s)/fade_out[acc:1 0 -10 0 10][color: 255 255 0 ]", 130,0,1000,1)*0.001 : fi.lowpass(1,1); //[accy:1 0 130 0]
};

//------------------
// Taccel mean Trigger from accelerometer alike a shock detection to start (send 1) and from end of motion from Maccel (send 0)
// it is necessary here to set to 1 when there is choc via accelero
// the sound is playing in loop and stops from a level : Maccel < specific level.
// the volume associated with the sound via Maccel must also be at 0 from this threshold

// Trig_up and trig_donw detect a transition up and down from each thresholds
trig_up(c) = s
with {
    //threshold_up = hslider ("thr_up",0.99,0.5,1,0.001);
    threshold_up = 0.999;
    s = ((c'<= threshold_up)&(c > threshold_up));
};

trig_down(c) = (-1) * s
with {
    //threshold_down = hslider ("thr_down",0.1,0.,8,0.01);
    threshold_down = 0.0001;
    s = ((c'>= threshold_down)&(c < threshold_down));
};

Taccel = ((Accel:trig_up),(Maccel:trig_down) : +) : ( + : max(0) : min(1))~_;

/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////
// Play buffer ///////

select_sample = int(nentry("v:sfGrain/Select Sample[style:menu{'1':1;'2':2;'3':3;'4':4;'5':5;'6':6;'7':7}]", 1, 1, 7, 1)):-(1);

multiselect(n,s) = par(i,n, *(i==int(s))) :> _;

//speed = hslider("speed playback [accy:1 0 0 0][color: 255 100 255 ]",0,-10,10,0.01): lowpass(1,1);
speed = 1;
//speed = hslider("speed [color: 0 255 0 ]",1,-1,1,0.001):smooth(0.998);

///////////////////////////////////////
// granular part //////////////////////

// sfGrain_v1 : the sizes of the samples are all 12s
// the expression is a coef given in percentage (facilitates editing on ios & co)
gran_size = hslider("v:sfGrain parameter(s)/gran_size[acc:1 1 -10 0 10][color:255 255 0][hidden:1]", 1,0.0001,1,0.0001) : fi.lowpass(1,freq_for_smooth) : min(1) : max(0.0001)
with {
    // this parameter is there to make grain variations smoother on small sizes
    freq_for_smooth = hslider("v:sfGrain parameter(s)/gransmooth [acc:1 1 -10 0 10][color:0 255 255][hidden:1]",50,0.1,50,0.01):fi.lowpass(1,1);
};

//gran_position = hslider ("gran_pos",10,0.1,100,0.1):*(0.01):min(1):max(0);// coeff version --> no use for sfgran_v1
gran_position = 0.1;

//fade_time = hslider ("fade[ms]",1,1,10000,1):*(0.001):*(SR);
fade_time = 0.001;

fade_in(x,soundFileSize) = (x-(fade_in_start))/(fade_time):max(0):min(1)
with {
    fade_in_start = ((soundFileSize)*(gran_position))+(fade_time);
};

fade_out(x,soundFileSize) = 1,((x-(fade_out_start))/(fade_time):max(0):min(1)):-
with {
    //fade_out_start = ((soundFileSize)*(gran_position))+((soundFileSize)*(gran_size)):-(fade_time);
    fade_out_start = soundFileSize*gran_size : -(fade_time);
};

player(soundFileSize) = fmod(_,max(1,int(soundFileSize*gran_size)))~(+(speed));

player_A = player(soundFileSize_sampleA) <: readSoundFileA , fade_out(_,soundFileSize_sampleA) : *;
player_B = player(soundFileSize_sampleB) <: readSoundFileB , fade_out(_,soundFileSize_sampleB) : *;
player_C = player(soundFileSize_sampleC) <: readSoundFileC , fade_out(_,soundFileSize_sampleC) : *;
player_D = player(soundFileSize_sampleD) <: readSoundFileD , fade_out(_,soundFileSize_sampleD) : *;
player_E = player(soundFileSize_sampleE) <: readSoundFileE , fade_out(_,soundFileSize_sampleE) : *;
player_F = player(soundFileSize_sampleF) <: readSoundFileF , fade_out(_,soundFileSize_sampleF) : *;
player_G = player(soundFileSize_sampleG) <: readSoundFileG , fade_out(_,soundFileSize_sampleG) : *;
