# Configuration and Bugs

## Bluetooth

Bluetooth is extremely flaky on my version of Ubuntu. This is the protocol I use to get a good connection:

1. Forget the device if it's already been paired.
2. Turn the Device off
3. Turn the computer off
4. Turn the device on. Give it a few minutes before doing anything with it.
5. Turn the computer back on.
6. Pair the computer and the device. The PIN is 1234
7. Wait at least minute for the computer and the device to finish talking to each other
8. After the bluetooth icon has vanished from the task bar and the devices have ceased communicating, then it's safe to hit play on the sketch.

## Jack Audio

The video won't play while Jack is running. SuperCollider won't process the brainwaves without Jack. I'm investigating some solutions.

## Bugs

1. The most recent long video won't play, I suspect because it's higher res than Processing can deal with.
2. I have not tested if the emergency fake data generator ever gets accidentally engaged. I suspect it might be.
3. The graphics are incmplete, boring, unlabelled and incomprehensible. The original waves are too light grey. The other lines should be a cool medical blue. All of them should probably be labelled. There is spossed to also be a polar graph.
4. The breakpoints are in milliseconds.
5. The weird jack bug would go away if filtering happened in Processing. This would also give better results, because, knowing the sample rate, we could just run it over the received samples without worrying about inexact timings. There is a stub os a biquad filter that is incomplete in the DSP file. It is correctly tuned for theta waves, but it might not be correctly implemented as I ran out of time to test it.

