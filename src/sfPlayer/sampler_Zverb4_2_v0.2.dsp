declare name      "sfZverb";
declare version   "1.4";
declare author    "Christophe Lebreton, Stéphane Letz";
declare license   "BSD";
declare copyright "SmartFaust - GRAME(c)2013-2015";

import("stdfaust.lib");

//-------------------- MAIN -------------------------------
process = _ <: zita_rev3 :> _;

//-------------------- PARAMETERS -------------------------------
lowpassmotion = fi.lowpass(N,fc)
with {
    // fc= hslider("h:motion filter/high_cut [hidden:1]",10,0.01,10,0.01);
    fc = 10;
    N = 1;// order of filter
};

// from effect.lib but with only N=4 for mobilephone application
zita_rev_fdn4(f1,f2,t60dc,t60m,fsmax) =
  (( si.bus(2*N) :> allpass_combs(N) : feedbackmatrix(N)) ~
   (delayfilters(N,freqs,durs) : fbdelaylines(N)))
with {
    N = 4;

    // Delay-line lengths in seconds:
    apdelays = (0.020346, 0.024421, 0.031604, 0.027333, 0.022904,
              0.029291, 0.013458, 0.019123); // feedforward delays in seconds
    tdelays = (0.153129, 0.210389, 0.127837, 0.256891, 0.174713,
              0.192303, 0.125000, 0.219991); // total delays in seconds
    tdelay(i) = floor(0.5 + ma.SR * ba.take(i+1,tdelays)); // samples
    apdelay(i) = floor(0.5 + ma.SR * ba.take(i+1,apdelays));
    fbdelay(i) = tdelay(i) - apdelay(i);
    // NOTE: Since SR is not bounded at compile time, we can't use it to
    // allocate delay lines; hence, the fsmax parameter:
    tdelaymaxfs(i) = floor(0.5 + fsmax * ba.take(i+1,tdelays));
    apdelaymaxfs(i) = floor(0.5 + fsmax * ba.take(i+1,apdelays));
    fbdelaymaxfs(i) = tdelaymaxfs(i) - apdelaymaxfs(i);
    nextpow2(x) = ceil(log(x)/log(2.0));
    maxapdelay(i) = int(2.0^max(1.0,nextpow2(apdelaymaxfs(i))));
    maxfbdelay(i) = int(2.0^max(1.0,nextpow2(fbdelaymaxfs(i))));

    apcoeff(i) = select2(i&1,0.6,-0.6);  // allpass comb-filter coefficient
    allpass_combs(N) = par(i,N,(fi.allpass_comb(maxapdelay(i),apdelay(i),apcoeff(i)))); // filter.lib
    fbdelaylines(N) = par(i,N,(de.delay(maxfbdelay(i),(fbdelay(i)))));
    freqs = (f1,f2); durs = (t60dc,t60m);
    delayfilters(N,freqs,durs) = par(i,N,filter(i,freqs,durs));
    feedbackmatrix(N) = ro.hadamard(N); // math.lib

    staynormal = 10.0^(-20); // let signals decay well below LSB, but not to zero

    special_lowpass(g,f) = si.smooth(p) with {
        // unity-dc-gain lowpass needs gain g at frequency f => quadratic formula:
        p = mbo2 - sqrt(max(0,mbo2*mbo2 - 1.0)); // other solution is unstable
        mbo2 = (1.0 - gs*c)/(1.0 - gs); // NOTE: must ensure |g|<1 (t60m finite)
        gs = g*g;
        c = cos(2.0*ma.PI*f/float(ma.SR));
    };

    filter(i,freqs,durs) = lowshelf_lowpass(i)/sqrt(float(N))+staynormal
    with {
        lowshelf_lowpass(i) = gM*low_shelf1_l(g0/gM,f(1)):special_lowpass(gM,f(2));
        low_shelf1_l(G0,fx,x) = x + (G0-1)* fi.lowpass(1,fx,x); // filter.lib
        g0 = g(0,i);
        gM = g(1,i);
        f(k) = ba.ba.take(k,freqs);
        dur(j) = ba.ba.take(j+1,durs);
        n60(j) = dur(j)* ma.SR; // decay time in samples
        g(j,i) = exp(-3.0*log(10.0)*tdelay(i)/n60(j));
    };
};

zita_rev1_stereo4(rdel,f1,f2,t60dc,t60m,fsmax) =
   re.zita_in_delay(rdel)
 : re.zita_distrib2(N)
 : zita_rev_fdn4(f1,f2,t60dc,t60m,fsmax)
 : output2(N)
with {
    N = 4;
    output2(N) = outmix(N) : *(t1),*(t1);
    t1 = 0.37; // zita-rev1 linearly ramps from 0 to t1 over one buffer
    outmix(4) = !,ro.butterfly(2),!; // probably the result of some experimenting!
    outmix(N) = outmix(N/2),par(i,N/2,!);
};

// from effect.lib and adapted by Christophe Lebreton with EQ and some parameters ranges changed .... no level out sliders
//---------------------------------- zita_rev1 ------------------------------
// Example GUI for zita_rev1_stereo (mostly following the Linux zita-rev1 GUI).
//
// Only the dry/wet and output level parameters are "dezippered" here.  If
// parameters are to be varied in real time, use "smooth(0.999)" or the like
// in the same way.
//
// REFERENCE:
//   http://www.kokkinizita.net/linuxaudio/zita-rev1-doc/quickguide.html
//
// DEPENDENCIES:
//   filter.lib (peak_eq_rm)

zita_rev3(x,y) = zita_rev1_stereo4(rdel,f1,f2,t60dc,t60m,fsmax,x,y)
  : out_eq : dry_wet(x,y)
with {

    fsmax = 48000.0;  // highest sampling rate that will be used

    // rdel = vslider("[1] Pre_Delay [hidden:1]", 50,1,100,1);
    rdel = 50;

    // f1 = vslider("[1] LF X [hidden:1]", 500, 50, 1000, 1);
    f1 = 500;

    t60dc = hslider("v:sfPlayer parameter(s)/[2] Low RT60 [acc:1 1 -10 0 10][color:255 255 0][hidden:1]", 5, 1, 7, 0.1);
    //[accy:-1 0 5 0]
    t60m = hslider("v:sfPlayer parameter(s)/[3] Mid RT60 [acc:1 1 -10 0 10][color:255 255 0][hidden:1]", 5, 1, 7, 0.1);

    // f2 = vslider("[4] HF Damping [hidden:1]", 13340, 1500, 0.49*fsmax, 1);
    f2 = 13340;

    out_eq = pareq_stereo(eq1f,eq1l,eq1q) : pareq_stereo(eq2f,eq2l,eq2q);// Zolzer style peaking eq (not used in zita-rev1) (filter.lib):
    // pareq_stereo(eqf,eql,Q) = peak_eq(eql,eqf,eqf/Q), peak_eq(eql,eqf,eqf/Q);
    // Regalia-Mitra peaking eq with "Q" hard-wired near sqrt(g)/2 (filter.lib):
    //pareq_stereo(eqf,eql,Q) = peak_eq_rm(eql,eqf,tpbt), peak_eq_rm(eql,eqf,tpbt)
    //  with {
    //  tpbt = wcT/sqrt(g); // tan(PI*B/SR) where B bandwidth in Hz (Q^2 ~ g/4)
    //  wcT = 2*PI*eqf/SR;  // peak frequency in rad/sample
    //g = db2linear(eql); // peak gain
    //  };

    // pareq use directly peak_eq_cp from filter.lib
    pareq_stereo (eqf,eql,Q) = fi.peak_eq_cq (eql,eqf,Q) , fi.peak_eq_cq (eql,eqf,Q) ;

    // eq1f = vslider("[1] F1[hidden:1] [unit:Hz] [style:knob] [tooltip: Center-frequency of second-order Regalia-Mitra peaking equalizer section 1]", 315, 40, 10000, 1);
    eq1f = 315;

    // eq1l = vslider("[2] L1 [hidden:1][unit:dB] [style:knob] [tooltip: Peak level in dB of second-order Regalia-Mitra peaking equalizer section 1]", 0, -15, 15, 0.1);
    eq1l = 0;

    // eq1q = vslider("[3] Q1[hidden:1] [style:knob] [tooltip: Q = centerFrequency/bandwidth of second-order peaking equalizer section 1]", 3, 0.1, 10, 0.1);
    eq1q = 3;

    // eq2f = vslider("[1] F2[hidden:1] [unit:Hz] [style:knob][tooltip: Center-frequency of second-order Regalia-Mitra peaking equalizer section 2]", 3000, 40, 10000, 1);
    eq2f = 3000;

    // eq2l = vslider("[2] L2 [hidden:1][unit:dB] [style:knob] [tooltip: Peak level in dB of second-order Regalia-Mitra peaking equalizer section 2]", 0, -15, 15, 0.1);
    eq2l = 0;

    // eq2q = vslider("[3] Q2 [hidden:1][style:knob] [tooltip: Q = centerFrequency/bandwidth of second-order peaking equalizer section 2]", 3, 0.1, 10, 0.1);
    eq2q = 3;

    dry_wet(x,y) = *(wet) + dry*x, *(wet) + dry*y
    with {
        wet = 0.5*(drywet+1.0);
        dry = 1.0-wet;
    };

    drywet = (hslider("v:sfPlayer parameter(s)/[1] Dry/Wet Mix  [tooltip: -1 = dry, 1 = wet] [acc:1 1 -10 5 10][color:255 255 0][hidden:1]", 5, 0, 17, 0.1)*0.02)-1:fi.lowpass(1,1):max(-1):min(1);

    //out_level = *(gain),*(gain);
    //gain = out_group(vslider("[2] Level [unit:dB] [style:knob] [tooltip: Output scale factor]", -0, -70, 40, 0.1)) : db2linear;
};
