(

var names = ["theta", "alpha", "beta", "gamma"];
var processing;

processing = NetAddr("127.0.0.1", 8085);// what port??;
p = processing;
n = names;


s.waitForBoot({
	var bus;

	SynthDef(\analyse, {|val, busnum=0,real =1|
		var noise, sig, lag;
		lag = Lag.kr(real);
		noise = BrownNoise.kr;
		sig = (val * lag) + (noise * (lag -1).abs);
		Out.kr(busnum, sig)
	}).add;


	SynthDef(\bpf, {|in=0, theta=6, alpha=10, beta=25, gamma=70, gate = 1|

		var arate, bpf, env, rmswindow, amp, trig, rms, freqs;

		rmswindow = SampleRate.ir/10;
		arate = K2A.ar(In.kr(in));
		trig = Impulse.kr(20);
		freqs = [theta, alpha, beta, gamma];

		EnvGen.kr(Env.asr(releaseTime:0.1), gate, doneAction:2);

		freqs.do({arg freq, id;

			bpf = BPF.ar(arate, freq);
			SendPeakRMS.ar(bpf, cmdName:'peak'++id);

			rms = (RunningSum.ar(bpf.squared, rmswindow)/rmswindow).sqrt;
			amp = A2K.kr(rms);
			SendTrig.kr(trig, id, amp);
		});
	}).add;

	bus = Bus.control(s);

	s.sync;

	//Synth(\analyse, [\val, 0, \busnum, 0, \real, 0]);
	a = Synth(\bpf, [\in, 0, \theta, 6, \alpha, 10, \beta, 25, \gamma, 70, \gate, 1],
		RootNode(s), 'addToTail');


	OSCdef(\theta, { arg msg; //sendTrig

		var id, amp, key;

		id = msg[2];
		amp = msg[3];
		key = n[id];
		(id == 0).if({
			//[key, amp].postln;
			//[id, amp].postln;
		});
		p.sendMsg("/amp", id, amp);
	},'/tr', s.addr);




})
)