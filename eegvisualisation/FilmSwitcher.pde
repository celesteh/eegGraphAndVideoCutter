import processing.video.*;
import javax.bluetooth.*;
import java.util.Enumeration;
import java.util.Vector;
import java.util.concurrent.*;
import java.io.File;

public class FilmSwitcher /*extends PApplet*/ {

  //BitReader bit;
  //FilmClip mainFilm;
  Movie mainFilm;
  Vector allClips;
  Vector allClipsAndMain;
  PApplet parent;
  //FilmClip active;
  Movie active;
  Movie lastClip;
  Enumeration clips;
  Enumeration clipsAndMain;
  boolean playing;
  int count;
  double last_change;

  public FilmSwitcher(PApplet app, String path/*, BitReader bitalino*/) {

    parent = app;
    mainFilm = 
      //new FilmClip(new Movie(parent, path), app.width, app.height);
      new Movie(parent, path);
    //new FilmClip(new Movie(parent, path), app.width, app.height);
    //bit = bitalino;
    active = mainFilm;
    //mainFilm.loop();
    playing = false;
    count = 0;
    allClips = new Vector();
    allClipsAndMain = new Vector();
    allClipsAndMain.addElement(mainFilm);
  }

  public void addClip(Movie newClip) {
    allClips.addElement(newClip);
    allClipsAndMain.addElement(newClip);
  }

  public void addClip(String path) {
    addClip(new Movie(parent, path));
  }

  public void loadClips(String directory) {

    System.out.println(directory);

    File folder = new File(directory);

    //Implementing FilenameFilter to retrieve only txt files

    FilenameFilter filmFileFilter = new FilenameFilter()
    {    
      @Override
        public boolean accept(File dir, String name)
      {
        if (name.endsWith(".mp4"))
        {
          return true;
        } else
        {
          return false;
        }
      }
    };

    //Passing txtFileFilter to listFiles() method to retrieve only txt files

    String[] list = folder.list(filmFileFilter);

    for (int i =0; i <list.length; i++) {
      addClip(directory+"/"+list[i]);
    }
  }

  public void resumeMain() {
    active =mainFilm;
    active.loop();
  }

  public Movie getActive() {
    active.speed(1.0);
    //return active.getFilm();
    return active;
  }

  public PImage getImage() {
    //System.out.println("Switcher getImage()");
    //return active.getImage();
    return (PImage) active;
  }

  public void read() {

    //System.out.println("switcher read");
    /*
    if (count == 0) {
     try {
     final BITalinoFrame[] frames = bit.read();
     //System.out.println(frames[0]);
     } 
     catch (Exception e) {
     System.out.print("Exception " + e);
     }
     }
     count = (count + 1) % 5;
     */

    /* should we go back to the main film ? */
    if (active != mainFilm) {
      double time_now = System.currentTimeMillis();
      double elapsed = time_now - last_change;
      if ((elapsed / 1000) > active.duration()) { // switch back
        Movie previous = active;
        last_change = time_now;
        active = mainFilm;
        previous.pause();
      }
    }

    if (active.available()) {
      //System.out.println("Available");
      active.read();
    } else { // check if we've run over time
      if (active.time() >= active.duration()) {
        active = mainFilm;
        if (active.available()) {
          active.read();
        } else {
          if (active.time() >= active.duration()) {
            // we're done
            playing = false;
            System.out.println("Done?");
          }
        }
      }
    }
  }

  private Movie getNextClip() {
    Movie clip;

    if (active == mainFilm) { // only pick from clips
      if (clips == null) {
        Collections.shuffle(allClips);
        clips = allClips.elements();
      }
      if (! clips.hasMoreElements()) {
        Collections.shuffle(allClips);
        clips = allClips.elements();
      }
      clip = (Movie) clips.nextElement();
    } else { // could go back to main
      if (clipsAndMain == null) {

        Collections.shuffle(allClipsAndMain);
        clipsAndMain = allClipsAndMain.elements();
      }
      if (! clipsAndMain.hasMoreElements()) {
        Collections.shuffle(allClipsAndMain);
        clipsAndMain = allClipsAndMain.elements();
      }
      clip = (Movie) clipsAndMain.nextElement();
    }
    if (((clip == lastClip) || (clip == active)) && (allClips.size() > 1)) {
      clip = getNextClip();
    }

    return clip;
  }

  public void change() {

    Movie clip;
    Movie previous;

    //System.out.println("in change");

    clip = getNextClip();
    if (clip != null) {

      last_change = System.currentTimeMillis();
      previous = active;
      active = clip;
      //active.speed(1.0);
      //active.play();
      if (playing) {
        if ( active != mainFilm) {
          lastClip = active;
          play();
        }
        if (previous != mainFilm) {
          System.out.println("Should stop");
          //previous.stop();
          previous.pause();
        }
      }
    }
  }

  public void play() {
    //System.out.println("switcher play");
    playing = true;
    //active.play();
    active.loop();
    active.speed(1.0);
  }

  public boolean isPlaying() {
    return playing;
  }
}


public class FilmClip extends PApplet {

  Movie film;
  PImage lastImage;
  Vector queue;
  int readIndex, writeIndex;
  int w;
  int h;

  public FilmClip (Movie myFilm, int width, int height) {

    film = myFilm;
    queue = new Vector(7);
    readIndex = 0;
    writeIndex = 0;
    w = width;
    h = height;
    lastImage =  createImage(w, h, RGB);
    for (int i = 0; i< (queue.capacity()-1); i++) {
      queue.addElement(new Resizer(w, h, lastImage));
      System.out.println("Queue size" + queue.size());
    }
    queue.addElement(new Resizer(w, h));
    writeIndex = queue.size()-1;
  }

  public void play() {
    film.play();
  }

  public void speed(float rate) {
    film.speed(rate);
  }

  public Movie getFilm() {
    return film;
  }

  public boolean available() {
    return film.available();
  }

  public synchronized void read() {
    Resizer thread;
    int index;
    PImage image;

    //System.out.println("FilmClip read");

    if (film.available()) {
      //System.out.println("available");
      film.read();
      image = film;
      index = getWriteIndex();
      try {
        thread = (Resizer) queue.get(index);
        thread.queueResize(image);
      } 
      catch (PreviousImageUnreadException e) {
        queue.insertElementAt(new Resizer(w, h, image), index+1);
        getWriteIndex();
      }
    }
    /*
    System.out.println("reaD");
     
     //if (film.available()) {
     System.out.println("available");
     //  film.read();
     index = getWriteIndex();
     thread =   queue[index];
     if (thread == null) {
     thread = new FilmThread(film, w, h);
     queue[index] = thread;
     } else {
     thread.next();
     }
     //}
     */
  }

  private int getReadIndex() {
    int index;
    index = readIndex;
    if (readIndex != writeIndex) {
      readIndex = (readIndex + 1) % queue.size();
    }
    return index;
  }

  private void readFailed() {
    System.out.println("Read failed");
    readIndex = (readIndex - 1) % queue.size();
    if (readIndex < 0) { 
      readIndex = 0;
    }
  }

  private int getWriteIndex() {
    int index;
    index = writeIndex;
    writeIndex = (writeIndex + 1) % queue.size();
    return index;
  }

  public synchronized PImage getImage() {
    int index;
    PImage ret;
    boolean success = false;
    Resizer thread;

    ret = lastImage;

    //noLoop();

    //System.out.println("getImage");
    index = getReadIndex();
    thread = (Resizer) queue.get(index);//queue[index];
    if ( thread != null) {
      try {
        //System.out.println("index, thread" + index+ thread);
        ret = thread.getImage(); 
        //System.out.println("ret" + ret);
        if (ret != null) {
          //lastImage = ret;  
          success = true;
        }
      } 
      catch (ImageNotReadyException e) {
        success = false;
      }
    } else {
      System.out.println("Thread was null");
    }
    if (! success) {
      readFailed();
      ret = lastImage;
    } else {
      lastImage = ret;
    }
    return ret;
  }
}

/*
public class FilmThread extends Thread {
 
 Movie film;
 PImage image;
 int w;
 int h;
 
 public FilmThread(Movie myFilm, int width, int height) {
 film = myFilm;
 w = width;
 h = height;
 start();
 }
 
 public void run() {
 boolean doResize = false;
 while (true) {
 synchronized(this) {
 if (image == null) {
 if (film.available()) {
 film.read();
 image = film;
 doResize = true;
 }
 }
 }
 if (doResize) {
 image.resize(w, h);//image(film, 0, 0, w, h); // nope. Need to read it to a PImage somehow and then resize
 doResize = false;
 }
 try {
 wait();
 } 
 catch (Exception e) {
 }
 }
 }
 
 public void next() {
 synchronized(this) {
 if (image == null) {  
 notify();
 }
 }
 }
 
 public synchronized PImage getImage() throws ImageNotReadyException {
 PImage ret;
 System.out.println("Thread getImage()");
 if (image == null) {
 throw new ImageNotReadyException();
 }
 ret = image;
 image = null;
 return ret;
 }
 }
 */

// Dummy class

public class Resizer extends Thread {
  PImage image;
  PImage input;
  boolean shouldConvert;
  int w, h;

  public Resizer(int width, int height, PImage img) {
    this(width, height);
    //input = img;
    try {
      queueResize(img);
    } 
    catch (Exception e) {
    }
  }

  public Resizer(int width, int height) {
    w = width;
    h = height;
    start();
  }

  public PImage getImage() throws ImageNotReadyException {
    if (shouldConvert == true) {
      throw new ImageNotReadyException();
    }
    return image;
  }

  public synchronized void queueResize(PImage img) throws PreviousImageUnreadException {
    input = img;
    shouldConvert = true;
    try {
      notify();
    } 
    catch (Exception e) {
    }
  }

  public void run () {

    int size;

    while (true) {

      try {
        wait();
      } 
      catch (Exception e) {
      }

      synchronized(this) {
        if (shouldConvert) {
          //image = img;
          image = new PImage(input.width, input.height);
          input.loadPixels();
          size = input.pixels.length;

          for (int i = 0; i<size; i++) {
            image.pixels[i] = input.pixels[i];
          }
          image.resize(w, h);

          shouldConvert = false;
        }
      }
    }
  }
}
/*
public class Resizer extends Thread {
 
 int h, w;
 PImage image;
 boolean isResized, isRead;
 
 public Resizer(int width, int height, PImage img) {
 this(width, height);
 try {
 this.queueResize(img);
 } 
 catch (Exception e) {
 }
 }
 
 public Resizer(int width, int height) {
 h = height;
 w = width;
 isResized = false;
 isRead = true;
 start();
 }
 
 public  synchronized PImage getImage() throws ImageNotReadyException {
 PImage ret;
 if ( ! isResized) {
 System.out.println("Resized is null");
 throw new ImageNotReadyException();
 }
 ret = image.copy();
 
 //image = null;
 isResized = false;
 isRead = true;
 System.out.println("Returning image " + ret);
 return ret;
 }
 
 public synchronized void queueResize(PImage img) throws PreviousImageUnreadException {
 
 int size;
 
 if ( image != null) {
 throw new PreviousImageUnreadException();
 }
 //image = img.copy();
 image = new PImage(img.width, img.height);
 img.loadPixels();
 size = img.pixels.length;
 
 for (int i = 0; i<size; i++) {
 image.pixels[i] = img.pixels[i];
 }
 
 isResized = false;
 
 try {
 notify();
 } 
 catch (Exception e) {
 System.out.println("Couldn't notify");
 }
 }
 
 public void run() {
 boolean errorFree = true;
 boolean didAction = false;
 int count = 0;
 while (errorFree) {
 synchronized(this) {
 System.out.println("loop");
 if ((isResized == false) &&(isRead == true)) {  
 System.out.println("Doing the resize");
 image.updatePixels();
 //resized = (PImage) image.copy();
 System.out.println("resized (before)" + image);
 image.resize(w, h);
 isResized = true;
 isRead = false;
 //System.out.println("image" + image);
 //resized = image;
 //image = null;
 System.out.println("resized " + image);
 //image = null;
 didAction = true;
 } else {
 didAction = false;
 }
 }
 System.out.println("did it: " + didAction);
 try {
 wait();
 } 
 catch (Exception e) {
 errorFree=  false;
 }
 System.out.println("Still in this fucking loop " + count);
 count++;
 }
 }
 }
 */
public class ImageNotReadyException extends Exception {
}

public class PreviousImageUnreadException extends Exception {
}
