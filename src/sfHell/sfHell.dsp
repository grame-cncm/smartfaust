declare name       "sfHell";
declare version    "1.1";
declare author     "Christophe Lebreton";
declare license    "BSD";
declare copyright  "SmartFaust - GRAME(c)2013-2018";

import("stdfaust.lib");

//-------------------- MAIN -------------------------------
process = Hell_EKS2 : Hell_comb2 : Hell_Verb2 : *(out) : max(-0.99) : min(0.99)
with {
    out = checkbox("v:sfHell/ON/OFF") : si.smooth(0.998);
};

//-------------------- PARAMETERS -------------------------------
freq = hslider("v:sfHell parameter(s)/freq [acc:2 1 -10 0 10][color:0 255 0][hidden:1]",3570,120,7040,1);

//gain = vgroup("EKS:source", hslider("gain", 1, 0, 10, 0.01));// 0 to 1
gain = 1;

//gate = button("gate");// 0 or 1
gate = phasor_bin(1) : -(0.001) : pulsar;

// Pick angle in [0,0.9]:
//pickangle = vgroup("EKS:source", 0.9 * hslider("pick_angle",0.9,0,0.9,0.01));
pickangle = 0.9;

// Normalized pick-position in [0,0.5]:
//beta = vgroup("EKS:source", hslider("pick_position [midi: ctrl 0x81]", 0.334, 0.02, 0.5, 0.001));
beta = 0.334;

// String decay time in seconds:
//t60 = vgroup("EKS:source", hslider("decaytime_T60", 8.615, 0, 10, 0.01)); // -60db decay time (sec)
t60 = 8;

// Normalized brightness in [0,1]:
B = hslider("v:sfHell parameter(s)/brightness [midi:ctrl 0x74][acc:0 0 -10 0 10][color:255 0 0][hidden:1]", 0, 0, 1, 0.01);// 0-1

// Dynamic level specified as dB level desired at Nyquist limit:
//L = vgroup("EKS:source", hslider("dynamic_level", -60, -60, 0, 1) : db2linear);
L = -60 : ba.db2linear;

//----------------------- noiseburst -------------------------
// White noise burst (adapted from Faust karplus.dsp example)
noiseburst(gate,P) = no.noise : *(gate : trigger(P))
with {
    diffgtz(x) = (x-x') > 0;
    decay(n,x) = x - (x>0)/n;
    release(n) = + ~ decay(n);
    trigger(n) = diffgtz : release(n) : > (0.0);
};

P = ma.SR/freq; // fundamental period in samples
Pmax = 4096; // maximum P (for delay-line allocation)

ppdel = beta*P; // pick position delay
pickposfilter = fi.ffcombfilter(Pmax,ppdel,-1); // defined in filter.lib

excitation = noiseburst(gate,P) : *(gain); // defined in signal.lib
rho = pow(0.001,1.0/(freq*t60)); // multiplies loop-gain

// Original EKS damping filter:
b1 = 0.5*B; b0 = 1.0-b1; // S and 1-S
dampingfilter1(x) = rho * ((b0 * x) + (b1 * x'));

// Linear phase FIR3 damping filter:
h0 = (1.0 + B)/2; h1 = (1.0 - B)/4;
dampingfilter2(x) = rho * (h0 * x' + h1*(x+x''));

loopfilter = dampingfilter2; // or dampingfilter1

filtered_excitation = excitation : si.smooth(pickangle) : pickposfilter : fi.levelfilter(L,freq); // see filter.lib
stringloop = (+ : de.fdelay4(Pmax, P-2)) ~ (loopfilter);

//Adequate when when brightness or dynamic level are sufficiently low:
//stringloop = (+ : fdelay1(Pmax, P-2)) ~ (loopfilter);

// Second output decorrelated somewhat for spatial diversity over imaging:
//widthdelay = delay(Pmax,W*P/2);

// Assumes an optionally spatialized mono signal, centrally panned:
//stereopanner(A) = _,_ : *(1.0-A), *(A);

//ratio_env = hgroup("rythm",vslider ("ratio_env",0.5,0.,0.5,0.0001)); // ratio de l'enveloppe au niveau haut par rapport au tempo.
ratio_env = (0.5);
fade = (0.5); // min > 0 pour eviter division par 0

speed = hslider ("v:sfHell parameter(s)/speed [acc:0 0 -10 0 10][color:255 0 0][hidden:1]",10,0.001,40,0.0001):fi.lowpass(1,1); // in hz
proba = hslider ("v:sfHell parameter(s)/proba [acc:1 0 -10 0 10][color:255 255 0][hidden:1]",0.32,0.,1.,0.01):fi.lowpass(1,1);

// PHASOR_BIN //////////////////////////////
//phasor_bin (speed, init) =  (+(float(speed)/float(SR)) : fmod(_,1.0)) ~ *(init); // version with freq controled by singal
phasor_bin (init) =  (+(float(speed)/float(ma.SR)) : fmod(_,1.0)) ~ *(init);

// PULSAR //////////////////////////////
//pulsar = ((_)<(_))*((_)>((_:-(0.001),(noise:abs):latch)); // version with signal input
//pulsar = _<:((_)<(ratio_env))*((proba)>((_),(noise:abs):latch)); // this version have a artefact of synchro
pulsar = _<:(((_)<(ratio_env)):@(100))*((proba)>((_),(no.noise:abs):ba.latch)); //this version introduce a delay of 100 samples to resynchronize prob to output without artefact

//=============================================================

//process = filtered_excitation : stringloop <: _,_ : widthdelay,_ : stereopanner(A);
Hell_EKS2 = filtered_excitation : stringloop ;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Hell_comb2 ///
Hell_comb2 = fi.fb_fcomb(maxdel,del,b0,aN)
with {
    maxdel = 1<<16;  // 2 exposant 16 soit 65536 samples  1<<16
    freq = 1/(hslider("v:sfHell parameter(s)/freqcomb [acc:0 0 -10 0 10][color:255 0 0][hidden:1]",10000,100,20000,0.001)); //[accx:1 0 10000 0]
    del = freq * ma.SR: si.si.smooth(0.99);
    //b0 = vslider("gain ",10,0,10,0.001):si.smooth(0.99);
    b0 =10;
    //aN = vslider("feedback",100,0,100,0.01)*(0.01):si.smooth(0.99);
    aN =1;
};

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Hell_Verb2
Hell_Verb2 =_<:zita_rev3:>_;

// from effect.lib but with only N=4 for mobilephone applications (C.Lebreton)
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

    special_lowpass(g,f) = si.smooth(p)
    with {
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
// parameters are to be varied in real time, use "si.smooth(0.999)" or the like
// in the same way.
//
// REFERENCE:
//   http://www.kokkinizita.net/linuxaudio/zita-rev1-doc/quickguide.html
//
// DEPENDENCIES:
//   filter.lib (peak_eq_rm)

zita_rev3(x,y) = zita_rev1_stereo4(rdel,f1,f2,t60dc,t60m,fsmax,x,y) : out_eq : dry_wet(x,y)
with {
    fsmax = 48000.0;  // highest sampling rate that will be used
    //rdel = in_group(vslider("[1] Pre_Delay [hidden:1] [unit:ms] [style:knob][tooltip: Delay in ms before reverberation begins]", 50,1,100,1));
    rdel = 50;

    //f1 = freq_group(vslider("[1] LF X [hidden:1][unit:Hz] [style:knob] [tooltip: Crossover frequency (Hz) separating low and middle frequencies]", 500, 50, 1000, 1));
    f1 = 500;
    //[accy:-1 0 6.5 0]
    t60dc = hslider("v:sfHell parameter(s)/[2] LowRT60 [unit:s] [tooltip: T60 = time (in seconds) to decay 60dB in low-frequency band] [acc:1 1 -10 0 10][color:255 255 0][hidden:1]", 6.5, 1, 10, 0.1);
    //[accy:-1 0 6.5 0]
    t60m = hslider("v:sfHell parameter(s)/[3] MidRT60 [unit:s] [tooltip: T60 = time (in seconds) to decay 60dB in middle band] [acc:1 1 -10 0 10][color:255 255 0][hidden:1]", 6.5, 1, 10, 0.1);

    //f2 = freq_group(vslider("[4] HF Damping [hidden:1][unit:Hz] [style:knob] [tooltip: Frequency (Hz) at which the high-frequency T60 is half the middle-band's T60]", 8000, 1500, 0.49*fsmax, 1));
    f2 = 8000;

    out_eq = pareq_stereo(eq1f,eq1l,eq1q) : pareq_stereo(eq2f,eq2l,eq2q);

    // Zolzer style peaking eq (not used in zita-rev1) (filter.lib):
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

    //eq1_group(x) = fdn_group(hgroup("[3] RM Peaking Equalizer 1[hidden:1]", x));

    //eq1f = eq1_group (vslider("[1] F1[hidden:1] [unit:Hz] [style:knob] [tooltip: Center-frequency of second-order Regalia-Mitra peaking equalizer section 1]", 315, 40, 10000, 1));
    eq1f = 315;

    //eq1l = eq1_group(vslider("[2] L1 [hidden:1][unit:dB] [style:knob] [tooltip: Peak level in dB of second-order Regalia-Mitra peaking equalizer section 1]", 0, -15, 15, 0.1));
    eq1l = 0;

    //eq1q = eq1_group(vslider("[3] Q1[hidden:1] [style:knob] [tooltip: Q = centerFrequency/bandwidth of second-order peaking equalizer section 1]", 3, 0.1, 10, 0.1));
    eq1q = 3;

    //eq2_group(x) = fdn_group(hgroup("[4] RM Peaking Equalizer 2[hidden:1]", x));

    //eq2f = eq2_group(vslider("[1] F2[hidden:1] [unit:Hz] [style:knob][tooltip: Center-frequency of second-order Regalia-Mitra peaking equalizer section 2]", 3000, 40, 10000, 1));
    eq2f = 3000;

    //eq2l = eq2_group(vslider("[2] L2 [hidden:1][unit:dB] [style:knob] [tooltip: Peak level in dB of second-order Regalia-Mitra peaking equalizer section 2]", 0, -15, 15, 0.1));
    eq2l = 0;

    //eq2q = eq2_group(vslider("[3] Q2 [hidden:1][style:knob] [tooltip: Q = centerFrequency/bandwidth of second-order peaking equalizer section 2]", 3, 0.1, 10, 0.1));
    eq2q =3;

    dry_wet(x,y) = *(wet) + dry*x, *(wet) + dry*y
    with {
        wet = 0.5*(drywet+1.0);
        dry = 1.0-wet;
    };

    drywet = (hslider("v:sfHell parameter(s)/[1] DryWetMix [tooltip: -1 = dry, 1 = wet] [acc:1 1 -10 0 10][color:255 255 0][hidden:1]", 5, 0, 20, 0.1)*0.02)-1 : si.smooth(0.99) : max(-1) : min(1);

    // out_level = *(gain),*(gain);
    // gain = out_group(vslider("[2] Level [unit:dB] [style:knob] [tooltip: Output scale factor]", -0, -70, 40, 0.1)) : db2linear;
};
