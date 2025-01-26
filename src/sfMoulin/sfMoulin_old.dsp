declare name        "sfMoulin";
declare version     "1.02";
declare author      "Christophe Lebreton, Stéphane Letz";
declare license     "BSD & STK-4.3";
declare copyright   "SmartFaust - GRAME(c)2013-2025";

import("stdfaust.lib");
import("moulin_v0.1.lib");

//-------------------- MAIN -------------------------------
process = vgroup("select your sample 1 to 8",(player_A, player_B, player_C, player_D, player_E, player_F, player_G, player_H)
:multiselect(8, select_sample) : fi.dcblockerat(50) : *(Maccel)) : *(out)
with {
    out = checkbox("v:sfMoulin/ON/OFF") : si.smooth(0.998);
};

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Accelerometer Part ///////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Usage: _:*(Maccel):_ // this function is useful for smooth control from accelerometers

accel_x = hslider("v:sfMoulin parameter(s)/acc_x [acc:0 0 -10 0 10][color: 0 255 0][hidden:1]",0,-100,100,1); //[accx:1 0 0 0]
accel_y = hslider("v:sfMoulin parameter(s)/acc_y [acc:1 0 -10 0 10][color: 0 255 0][hidden:1]",0,-100,100,1); //[accy:1 0 0 0]
accel_z = hslider("v:sfMoulin parameter(s)/acc_z [acc:2 0 -10 0 10][color: 0 255 0][hidden:1]",0,-100,100,1); //[accz:1 0 0 0]

lowpassfilter = fi.lowpass(N,fc)
with {
    // fc=hslider("high_cut [hidden:1]",0.5,0.001,10,0.1);
    fc = 0.5;
    N = 1; // order of filter
};

lowpassmotion = fi.lowpass(N,fc)
with {
    // fc = hslider("high_cut [hidden:1]",10,0.01,10,0.01);
    fc = 10;
    N = 1; // order of filter
};

//fb=hslider("low_cut [hidden:1]",15,0.1,15,0.01);
fb = 15;
dc(x) = x : fi.dcblockerat(fb);

//offset = hslider ("thr_accel [hidden:1]",9.99,0,9.99,0.01);
offset = 9.99;

quad(x) = dc(x)*dc(x);
Accel = quad(accel_x),quad(accel_y),quad(accel_z) :> sqrt:-(offset):/((10)-(offset)) : max(0.) : min(1.);

// Maccel mean Motion with accelerometer
//Maccel = Accel:lowpassfilter:min(1.);
Maccel = Accel:an.amp_follower_ud (env_up,env_down)
with {
    env_up = 0;
    env_down = hslider("v:sfMoulin parameter(s)/fade_out [acc:1 0 -10 0 10][color: 255 255 0][hidden:1]",130,0,1000,1)*0.001 : fi.lowpass(1,1);
};

// Taccel mean Trigger from accelerometer alike a choc detection to start (send 1) and from end of motion from Maccel (send 0)
// it is necessary here to set to 1 when there is a shock via accelero
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

Taccel = ((Accel:trig_up),(Maccel:trig_down):+) : (+ : max(0) : min(1)) ~ _;

/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////
// Play buffer ///////

select_sample = int(nentry("v:sfMoulin/Select Sample[style:menu{'1':1;'2':2;'3':3;'4':4;'5':5;'6':6;'7':7;'8':8}]", 1, 1, 8, 1)):-(1);

multiselect(n,s) = par(i,n, *(i==int(s))) :> _;

//speed = hslider("speed playback [accy:1 0 0 0][color: 255 100 255 ]",0,-10,10,0.01): lowpass(1,1);
//speed = 1;
// version with gyro
//speed = vslider ("speed [gyroy:1 0 0 0][color: 0 255 0 ][hidden:1]",1,-3,3,0.001):smooth(0.998):max(-1):min(1);
// version with accelero
speed = Maccel:max(-1):min(1);

player(size) = (int)((0):+~(+(speed): * (Taccel): fmod(_,max(1,size)))) : abs : int;

player_A = player( soundFileSize_sampleA) : readSoundFileA;
player_B = player( soundFileSize_sampleB) : readSoundFileB;
player_C = player( soundFileSize_sampleC) : readSoundFileC;
player_D = player( soundFileSize_sampleD) : readSoundFileD;
player_E = player( soundFileSize_sampleE) : readSoundFileE;
player_F = player( soundFileSize_sampleF) : readSoundFileF;
player_G = player( soundFileSize_sampleG) : readSoundFileG;
player_H = player( soundFileSize_sampleH) : readSoundFileH;

////////////////
