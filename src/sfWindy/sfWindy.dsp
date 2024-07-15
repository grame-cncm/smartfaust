declare name        "sfWindy";
declare version     "1.1";
declare author      "Christophe Lebreton";
declare license     "BSD";
declare copyright   "SmartFaust - GRAME(c)2013-2018";

import("stdfaust.lib");

//--------------------------------------------------------------------------------------------------
// MAIN PROCESS
process = no.pink_noise : *(Motion) : moog_vcf_wind : *(out)
with {
    out = checkbox("v:sfWindy/ON/OFF") : si.smooth(0.998);
};

// Motion = hslider("Motion",0,0,1,0.001);

//--------------------------------------------------------------------------------------------------
// MOTION ANALYSE  accelerometers
// defined a mapping from smartphones accelerometers
// accelerometer units: m/s2 ( 10 m/s2 == 1 g )
accel_x = vslider("v:sfWindy parameter(s)/acc_x [acc:0 0 -10 0 10][color: 0 255 0][hidden:1]",0,-100,100,1);
accel_y = vslider("v:sfWindy parameter(s)/acc_y [acc:1 0 -10 0 10][color: 0 255 0][hidden:1]",0,-100,100,1);
accel_z = vslider("v:sfWindy parameter(s)/acc_z [acc:2 0 -10 0 10][color: 0 255 0][hidden:1]",0,-100,100,1);

// normalize 0 to 1 of 3 axes accelerometers ( pythagoria )
Motion = quad(accel_x),quad(accel_y),quad(accel_z) :> sqrt : -(offset) : max(0.) : min(1.) : an.amp_follower_ud (env_up,env_down)
with {
    // DC filter to cancel low frequency from acceleromters ( inclinometers )
    dc(x) = x : fi.dcblockerat(fb);
    fb = hslider("v:sfWindy parameter(s)/low_cut[freq DC filter] [hidden:1]",12,0.,15,0.01);
    // square function with DC filter integrated
    quad(x) = dc(x)*dc(x);
    // offset to cancel unstable motion (stress motion;))
    offset = hslider("v:sfWindy parameter(s)/threshold [hidden:1]",6,0,100,0.1);
    // envelop follower to create smooth motion from acceleration
    env_up = hslider("v:sfWindy parameter(s)/[1]envup [hidden:1][acc:0 0 -10 0 10][color: 0 255 0]", 670,0,1300,1)*0.001 : fi.lowpass(1,0.5);
    env_down = hslider("v:sfWindy parameter(s)/[2]envdown [hidden:1][acc:1 0 -10 0 10][color: 0 255 0]", 0,0,500,1)*0.001;
};

//--------------------------------------------------------------------------------------------------
// MOOG_VCF
// from demo.lib of Julius Smith
// this adapted for this project, read moog_vcf_demo for more information
moog_vcf_wind = vcfarch :*(5)
with {
    //freq = hslider("h:Moogfilter/Frequency [1] [unit:PK] [style:knob]",25, 1, 88, 0.01) : ba.pianokey2hz : si.smooth(0.999);
    freq = (Motion*87)+1: ba.pianokey2hz : si.smooth(0.999);
    //res = hslider("h:Moogfilter/Resonance [2]", 0.9, 0, 1, 0.01));
    res = Motion;
    vcfbq = _ <: select2(1, ve.moog_vcf_2b(res,freq), ve.moog_vcf_2bn(res,freq)); // fix select 2biquad
    vcfarch = _ <: select2(1, ve.moog_vcf(res^4,freq), vcfbq); // fix select normalized
};
