import java.util.Random;

BitReader bit;
double start_time;
float alpha;
boolean alive;
double fadeTime;
double jumpPause;
int fadeDelta = 3;
boolean runFullScreen;
BioDSP dsp;
Grapher graph;
boolean emergency;

FilmSwitcher myMovie;
double last_change;
float jumpProbability;
//BreakPoint[] breakpoints;
BiometricController controller;
BreakPoint last, next;

Random rand;
int w, h;

void settings() {
  //fullScreen(3);
}

void setup() {

  background(0);

  // The grapher runs as a second full screen applet
  String[] args = {"TwoFrameTest"};
  graph = new Grapher();
  PApplet.runSketch(args, graph);

  emergency = false;
  
  this.setupBitalino();
  dsp = new BioDSP(bit);
  dsp.setEmergency(emergency);
  
  graph.setBit(dsp);
  

  last_change = 0;

  //breakpoints = new BreakPoint[0];

  controller = new BiometricController(this, dataPath("")+"/biometric.properties");
  jumpProbability = 0;

  rand = new Random();



  w = width;
  h = height;
  System.out.println(w);
  System.out.println(h);

  alpha = 0;
  alive = false;
  try {
    fadeTime = Double.parseDouble(controller.getSetting("fadeTime"));
  } 
  catch (Exception e) {
    fadeTime = 5;
    controller.setSetting("fadeTime", ""+fadeTime);
  }
  try {
    jumpPause = Double.parseDouble(controller.getSetting("jumpPause"));
  } 
  catch (Exception e) {
    jumpPause = 4000;
    controller.setSetting("jumpPause", ""+jumpPause);
  }
  try {
    runFullScreen = Boolean.parseBoolean(controller.getSetting("runFullScreen"));
  } 
  catch (Exception e) {
    runFullScreen = true;
    controller.setSetting("runFullScreen", ""+runFullScreen);
  }
  String film;
  try {
    film = controller.getSetting("film");
  } 
  catch (Exception e) {
    film = "DRAFT_JERWOOD_04.09.18.mp4";
  }

  System.out.println(film);

  myMovie = new FilmSwitcher(this, film/*, bit*/);
  myMovie.loadClips(dataPath("")+"/clips");

  frameRate(24); // was 24


  start_time = System.currentTimeMillis(); // duplicated later because
  
  


}


void setupBitalino() {

  bit = new BitReader(/*this*/);

  delay(7 * 1000); // 15 seconds

  for (int i=0; (i<4 && (! bit.isPaired())); i++) {
    try {
      bit.pair();
    } 
    catch (Exception e) {
      System.out.println("waiting...");
      delay(7 * 1000);
    }
  }
  delay(5);
  //bit.getPorts();

  try {
    bit.open();
    System.out.println("Success!");
    //controller.ready();
  } 
  catch (Exception e) {
    System.out.println("Failure!");
    emergency = true;
  }
  graph.start();
}


void draw() {
 
  //background(0);
  update();
  tint(alpha);
  /*
  try {
    if (alpha > 0) {
      if (myMovie.isPlaying()) {
        myMovie.read();
        if (runFullScreen) {
          //fullscreen(3);
          image(myMovie.getImage(), 0, 0, width, height);
          //image(myMovie.getImage(), 0, 0, w, h);
          //System.out.println("fullscreen");
          //System.out.println(alpha);
        } else {
          image(myMovie.getImage(), 0, 0);
          //System.out.println("not fullscreen");
        }
        //image(myMovie.getImage(), 0, 0, w, h);
      }
    }
  } 
  catch (Exception e) {
    System.out.println(e);
    e.printStackTrace();
  }
  */
  
  //tint(255, alpha);
  //tint(alpha);  
}


void update() {

  // do fade
  doFade();
  try {
    if (alpha >= 1) {
      if (shouldChange()) {
        myMovie.change();
      }
    }
  } catch (Exception e) {
    System.out.println("Caught exception on change " + e);
    myMovie.resumeMain();
  }
}

boolean shouldChange() {

  boolean doIt = false;
  double time;
  float theta, probability;


  try {
    theta = dsp.getTheta();
    theta = max(theta, 0.5);
    theta = min(theta, 1);
  } 
  catch (Exception e) {
    System.out.println("bit failed");
    theta = 1;
  }

  if (alive) {
 
    time = getElapsedTime();
    //System.out.println("time " + time + " start_time " + start_time);
    jumpProbability = controller.getProbabilityAt(time);

    if ( (time - last_change) > controller.getPauseAt(time)) {
      probability = theta * jumpProbability;
      //System.out.println("probability " + probability+ " " + ecg + " " + emg + " time " + time);
      if (rand.nextFloat() <= (probability/48)) { // 2 second window size
        System.out.println("Switch!");
        last_change = time;//getElapsedTime();
        doIt = true;
      }
    }
  }

  return doIt;

  //return rand.nextBoolean();
}

void doFade() {
  if (alive && alpha < 255) {
    //alpha += fadeDelta;
    lerp(1, 2, 3);
    alpha = lerp(0, 256, (float) (getElapsedTime() / (fadeTime * 1000)));
    //System.out.println("alpha "+ alpha);
    if (alpha > 255) alpha = 255;
  } else if (!alive && alpha > 0) {
    alpha -= fadeDelta;
    //alpha = lerp(255.0, 0.0, ((float) getElapsedTime() / fadeTime));
    if (alpha < 0) alpha = 0;
    graph.setAlpha(alpha);
    System.out.println("alpha "+ alpha);
  }
}





void fadeIn() {

  start_time = System.currentTimeMillis();
  System.out.println("star_time " + start_time);

  myMovie.play();
  alive = true;
  graph.startGraphing();
}

void fadeOut() {
  alive = false;
  graph.stopGraphing();
  try {
    bit.shouldStop();
  } 
  catch (Exception e) {
    System.out.println("fade out " + e);
  }
}



void keyPressed() {

  if (alive) {
    fadeOut();
  } else {
    fadeIn();
  }
}

public double getElapsedTime() {

  return System.currentTimeMillis() - start_time;
}

public void setJumpProbability(float probability) {
  jumpProbability = probability;
}


public void setJumpProbabilityBreakpoint(double target, double when) {
}

/*
void setupBitalino() {

  bit = new BitReader(/*this*//*);

  delay(7 * 1000); // 15 seconds

  for (int i=0; (i<4 && (! bit.isPaired())); i++) {
    try {
      bit.pair();
    } 
    catch (Exception e) {
      System.out.println("waiting...");
      delay(7 * 1000);
    }
  }
  delay(5);
  //bit.getPorts();

  try {
    bit.open();
    System.out.println("Success!");
    controller.ready();
  } 
  catch (Exception e) {
    System.out.println("Failure!");
  }
} */
