import java.util.*;

public class Grapher extends PApplet {


  
  //BitReader bit;
  BioDSP bit;
  float eeg;
  float [] history;
  Synth [] filter;
  AnalysedChannel[] channels;
  DataChannel[] toDraw;
  boolean shouldGraph;
  boolean shouldUpdate;
  float alpha;
 
  
  public void settings() {
    //size(200, 100);
    
    shouldGraph = false;
    shouldUpdate = true;
    
    fullScreen(2);
    //w = width;
    //h = height;
    System.out.println(width);
    System.out.println(height);
    
    toDraw = new DataChannel[5];
    for(int i=0; i< 5; i++) {
      toDraw[i] = new DataChannel(width+1);
      toDraw[i].setMap(0, 1, (height/6) * i, (height/6) * (i +1));
      println (""+i +"map" + 0 + " " + 1 + " " + ((height/6) * i )+ " "  + ((height/6) * (i +1)));
    }
    
    //history =  new float[width];
    //  history[width -2] = 0.5;
    //  history[width -1] = 0.5;
    
    //stroke(200,200,200);  // stroke will be red on dots plotted
    //fill(200,200,200);  // fill will be red on dots plotted

    alpha = 255;

  }
  
  public void setBit (BioDSP bitalino) {
    bit = bitalino;
    channels = bit.getChannels();
  }


  public void startGraphing() {
    for(int i=0; i<toDraw.length; i++) {
      toDraw[i].zeroOut();
    }
    shouldGraph = true;
    shouldUpdate = true;
  }
  
  public void stopGraphing() {
    shouldUpdate = false;
  }
  
  public void setAlpha(float input) {
    alpha = input;
  }
  
  public void draw() {
    background(0);
    
    if (shouldGraph) {
    for(int i=0; i<toDraw.length; i++) {
      if(toDraw[i].checkLength(width+1)) {
        //toDraw[i].setMap(0, 1, (height/6) * i, (height/6) * (i +1));
        toDraw[i].setMap(0, 1, (height/6) * (i+ 1), (height/6) * (i +0));
        //println (""+i +"map" + 0 + " " + 1 + " " + ((height/6) * i )+ " "  + ((height/6) * (i +1)));
      }
      history = toDraw[i].getHistory();
      
      if(i == 1) { //theta
        stroke(255, 0, 0, alpha);
        fill(255, 0, 0, alpha);
        strokeWeight(4);
      } else {
        stroke(150,150,150, alpha);
        fill(150,150,150, alpha);
        strokeWeight(3);
      }
      for (int x = 0; x < (width); x++) {
        //line(x, history[x], x+1, history[x+1]);
        //ellipse(x, height - history[x], 3, 3);
        if (!((history[x]) == 0 && (history[x+1] == 0)))
          line(x, toDraw[i].mapAt(x), x+1, toDraw[i].mapAt(x+1));
        //println(history[x]);
      }
     
      if( shouldUpdate) {
        if ( bit != null ) {
          if(i == 0){ // raw data
            float eeg = bit.getEEG();
            //println(eeg);
            toDraw[0].append(eeg);
           } else {
             toDraw[i].append(bit.getLatestAt(i-1));
           }
        }
      } else {
        toDraw[i].append(0);
      }
      
    } // end main for loop
      //toDraw[i].getRow();
      //while(toDraw.hasNext())
      
    /*
    if( history.length != width) {
      history =  new float[width];
      history[width -2] = 0.5;
      history[width -1] = 0.5;
    }
    
    try {
      history[width-1] = bit.getEEG();

    } catch (Exception e) {
      double random = (Math.random() * 2) -1;
      float prev = map(history[width-2], 0, height/6, 0, 1);
      
      history [width -1] = prev + (float) random  / 200; 
      //System.out.println(history [width -1]);
      history [width -1] = Float.min(history [width -1], 0.65);
      history [width -1] = Float.max(history [width -1], 0.35);
    }
    history[width - 1] = map(history[width - 1], 0, 1, 0, height/6);
   // Plot all the points
     stroke(200,200,200);  // stroke will be red on dots plotted
    fill(200,200,200);  // fill will be red on dots plotted

    for (int i = 0; i < (width - 1); i++)
    {
      if (history[i] != 0) // Don't plot anything at zero, as that's the default value in the array
      {
        ellipse(i, height - history[i], 3, 3);
      }
      history[i] = history[i + 1]; // Shift the readings to the left so can put the newest reading in
    }  
    */
  }
      //tint(255, alpha);

  }
}

public class DataChannel implements Iterator<Float> {
  
  float [] history;
  float inputMin, inputMax, outputMin, outputMax;
  int index;
  
  
  public DataChannel() {
    this.setLength(1);
  }
  
  public DataChannel(int length) {
    
    this.setLength(length);
  }
  
  public boolean checkLength(int length){
    boolean changed;
    changed = false;
    if (history.length != length) {
      this.setLength(length);
      changed = true;
    }
    return changed;
  }
  
  public void zeroOut() {
    int length = history.length;
    history = new float[length];
    
  }
  
  public void setLength( int length) {
    if(history == null || history.length != length) {
       history = new float[length];
    }
  }
  
  public float[] getHistory() {
    return history;
  }
  
  public float mapAt(int index, float inMin, float inMax, float outMin, float outMax){
   
    return map(history[index], inMin, inMax, outMin, outMax);
    
  }
  
  public float mapAt(int index) {
    return mapAt(index, inputMin, inputMax, outputMin, outputMax);
  }
  
  public void setMap(float inMin, float inMax, float outMin, float outMax) {
    inputMin = inMin;
    inputMax = inMax;
    outputMin = outMin;
    outputMax = outMax;
  }
  
  public Iterator getRow(){
    int index = 0;
    return this;
  }
  
  public boolean hasNext() {
    return (index < history.length);
  }
  
  public Float next() {
    
    Float retValue;
    if ((inputMin != inputMax) && (outputMin != outputMax)) {
      retValue = mapAt(index, inputMin, inputMax, outputMin, outputMax);
    } else {
      retValue = history[index];
    }
    
    index = index +1;
    return retValue;  
    
  }
  
  public void append (float data) {
     for (int i = 0; i < (history.length - 1); i++)
       history[i] = history[i+1];
       
     history[history.length -1] = data;
     index = index+1;
    
  }
  
    
}
