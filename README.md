# biometricvidplayer
Bitalino Controlled video player for performance

This version extracts theta waves and uses those to cut video.
The original brainwaves and several bands (alpha, btea, gamma and theta) are graphed. Theta is in red, the rest are in grey.

## Dependencies
To add dependencies, drag and drop the jar files on top of the Processing sketch in the app or else put them in a folder called "code".  Add both Bluecove jars and both jars from the bitalino downloads.

* Bitalino https://jar-download.com/artifacts/com.bitalino/bitalino-java-sdk/1.1.0/source-code
* Bluecove Mac and Win https://sourceforge.net/projects/bluecove/
* Bluecove Linux http://www.bluecove.org/bluecove-gpl/

If the bitalino jar link isn't working, you can also build the files from source via maven. See the [repository](https://github.com/BITalinoWorld/java-sdk) for more information.


### Linux
* Linux users also have system dependencies: `sudo apt-get install libbluetooth-dev`.

## Set-up
The bitalino is a bluetooth device that must be paired with the computer before it can be used. Do this the normal way for your operating system. The pin is 1234

A long video must be placed in the Data folder.
Shorter videos must be placed in a folder called `clips` within the Data folder

## Usage
The file Data/biometric.properties configures the player.
These are what the liens mean:

* `fadeTime` - how many seconds to fade in and out
* `jumpPause` (I don't remember)
* `runFullScreen` - this is read by the program, but I don't think it's actually used
* `film` - the file name of the film, which you must put in the Data folder. There are some limitations around the film resolution and sample rate,  which are imposed by the Processing classes used for video
* `randWindowSize` (I don't remember)
* `bp/prob/0=0:0` - A breakpoint. See below
* `bp/pause/0=0:4000` - A breakpoint. See below. However, I don't remember exactly what this kind of point does.

### Breakpoints

The programme uses theta waves to inform when it should cut the video to play the short clips instead of it, making quick jump cuts. However, the probability of this happened is also scored over the duartion of the projection. Every change in probability is notated with a break point, The program scales the probability according to how far between breakpoints it is.

Breakpoints are in the biometric.properties file.

Probability breakpoints look like: `bp/prob/2=1320000:0.8` In this example: 
* `bp/prob/` says that it's a probability breakpoint, setting the overall probability of a cut. 
* `2` is the number of breakpoint. Numbering starts with 0.
* `=1320000` is the number of miliseconds from the start at which this breakpoint is set.
* `:0.8` is the probability. If the theta wave data is over the cutting threshold, there is an 80% probability that a cut will occur.

