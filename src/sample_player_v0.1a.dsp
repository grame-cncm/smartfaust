declare name "Sample_player_v0.1";
declare author 		"Christophe Lebreton / GRAME";
declare version "1.01";// new mapping to android
declare licence "BSD";
 

import("math.lib"); 
import("maxmsp.lib"); 
import("music.lib"); 
import("oscillator.lib"); 
import("reduce.lib"); 
import("filter.lib"); 
import("effect.lib");

import("sample_v0.1.lib");


/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Accelerometer Part ///////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Usage: 	_:*(Maccel):_ // this function is useful for smooth control from accelerometers
// 			_:	

accel_x = hgroup ("v:sfPlayer parameter(s)/accel [hidden:1]", vslider("acc_x [acc:0 0 -10 10 0 0][color: 0 255 0 ][hidden:1]",0,-100,100,1)); //[accx:1 0 0 0]
accel_y = hgroup ("v:sfPlayer parameter(s)/accel [hidden:1]", vslider("acc_y [acc:1 0 -10 10 0 0][color: 0 255 0 ][hidden:1]",0,-100,100,1)); //[accy:1 0 0 0]
accel_z = hgroup ("v:sfPlayer parameter(s)/accel [hidden:1]", vslider("acc_z [acc:2 0 -10 10 0 0][color: 0 255 0 ][hidden:1]",0,-100,100,1)); //[accz:1 0 0 0]

lowpassfilter = lowpass(N,fc)
			with {
				//fc=hslider("high_cut [hidden:1]",0.5,0.001,10,0.1);
				fc=0.5;
				N= 1;	// order of filter
			};
			
lowpassmotion = lowpass(N,fc)
			with {
				//fc= hslider("h:motion filter/high_cut [hidden:1]",10,0.01,10,0.01);
				fc=10;
				N= 1;	// order of filter
			};
			
//fb=hslider("low_cut [hidden:1]",15,0.1,15,0.01);
fb=15;			
dc(x)=x:dcblockerat(fb);


//offset = hslider ("thr_accel [hidden:1]",9.99,0,9.99,0.01);
offset=9.99;


quad(x)=dc(x)*dc(x);
Accel = quad(accel_x),quad(accel_y),quad(accel_z):> sqrt:-(offset):/((10)-(offset)):max(0.):min(1.);

// Maccel mean Motion with accelerometer
//Maccel = Accel:lowpassfilter:min(1.);
Maccel = Accel:amp_follower_ud (env_up,env_down)
			with {
				env_up = hslider ( "v :sfPlayer parameter(s)/fade_in [acc:1 0 -10 10 0 130][color: 255 255 0 ][hidden:1]", 130,0,1000,1)*0.001:lowpass(1,1); //[accy:1 0 130 0]
				env_down = hslider ( "v:sfPlayer parameter(s)/fade_out[acc:1 0 -10 10 0 130][color: 255 255 0 ][hidden:1]", 130,0,1000,1)*0.001:lowpass(1,1); //[accy:1 0 130 0]
			};

// Taccel mean Trigger from accelerometer alike a shock detection to start ( send 1 )and from end of motion from Maccel ( send 0 )

// il faut ici mettre à 1 lorsque qu'il y a un shock via accelero
// le son est jouer en loop et s'arrête à partir d'un  niveau Maccel < à un certain niveau. 
// le volume associé au son via Maccel devra être à 0 à partir de ce seuil egalement

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

Taccel = ((Accel:trig_up),(Maccel:trig_down):+):(+:max(0):min(1))~_;

/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////
// Play buffer ///////

select_sample = int (nentry("v:sfPlayer parameter(s)/Select Sample[style:menu{'1':0;'2':1;'3':2;'4':3;'5':4;'6':5;'7':6;'8':7;'9':8;'10':9}]", 0, 0, 9, 0.1));

multiselect(n,s) = par(i,n, *(i==int(s))) :> _;

//proposition de Yann pas testé --> pas de retour en debut de buffer dans ce cas
/*
player(speed, size) = speed : (+ : fmod(_,size)) ~ _  :  int ;

player_A = player(Taccel, 529201)  : readSoundFileA;
player_B = player(Taccel, 860245)  : readSoundFileB;
player_C = player(Taccel, 703837)  : readSoundFileC;
player_D = player(Taccel, 953002)  : readSoundFileD;
player_E = player(Taccel, 272980)  : readSoundFileE;
player_F = player(Taccel, 307599)  : readSoundFileF;
player_G = player(Taccel, 957045)  : readSoundFileG;
player_H = player(Taccel, 1408776)  : readSoundFileH;
player_I = player(Taccel, 305026)  : readSoundFileI;
player_J = player(Taccel, 616078)  : readSoundFileJ;
*/			

// proposition initial avec speed concstant mais il vaut mieux mettre la taille du buffer dans la recursion
/*			
player_A = 	(int)((0):+~(+(1): * (Taccel))): %(529201): int :readSoundFileA;
player_B = 	(int)((0):+~(+(1): * (Taccel))): %(860245): int :readSoundFileB;
player_C = 	(int)((0):+~(+(1): * (Taccel))): %(703837): int :readSoundFileC;
player_D = 	(int)((0):+~(+(1): * (Taccel))): %(953002): int :readSoundFileD;
player_E = 	(int)((0):+~(+(1): * (Taccel))): %(272980): int :readSoundFileE;
player_F = 	(int)((0):+~(+(1): * (Taccel))): %(307599): int :readSoundFileF;
player_G = 	(int)((0):+~(+(1): * (Taccel))): %(957045): int :readSoundFileG;
player_H = 	(int)((0):+~(+(1): * (Taccel))): %(1408776): int :readSoundFileH;
player_I = 	(int)((0):+~(+(1): * (Taccel))): %(305026): int :readSoundFileI;
player_J = 	(int)((0):+~(+(1): * (Taccel))): %(616078): int :readSoundFileJ;	
*/

// proposition avec comme initial avec taille buffer dans recusrion et variation du speed vi un slider

//speed = hslider ("speed playback [accy:1 0 0 0][color: 255 100 255 ]",0,-10,10,0.01): lowpass(1,1);
speed = 1;

player(size)= (int)((0):+~(+(speed): * (Taccel): fmod(_,max(1,size)))):abs: int;

player_A = player( soundFileSize_sampleA)  : readSoundFileA;
player_B = player( soundFileSize_sampleB)  : readSoundFileB;
player_C = player( soundFileSize_sampleC)  : readSoundFileC;
player_D = player( soundFileSize_sampleD)  : readSoundFileD;
player_E = player( soundFileSize_sampleE)  : readSoundFileE;
player_F = player( soundFileSize_sampleF)  : readSoundFileF;
player_G = player( soundFileSize_sampleG)  : readSoundFileG;
player_H = player( soundFileSize_sampleH)  : readSoundFileH;
player_I = player( soundFileSize_sampleI)  : readSoundFileI;
player_J = player( soundFileSize_sampleJ)  : readSoundFileJ;

			
////////////////
		
process = vgroup( "select your sample 1 to 10",(player_A, player_B, player_C, player_D, player_E, player_F, player_G, player_H, player_I, player_J)
:multiselect(10, select_sample):dcblockerat(50):*(Maccel));
