import oscP5.*;
import netP5.*;
import supercollider.*;

public class BioDSP extends BitListener {
  
  Synth analysis;
  OscP5 oscP5;
  AnalysedChannel[] channels;
  float latestEEG;
  Filter theta;
 
  public BioDSP (BitReader bitalino) {
    
    latestEEG = 0;
    
    analysis = new Synth ("analyse");
    analysis.set("val", 0);
    analysis.set("busnum", 0);
    analysis.create();
    
    oscP5 = new OscP5(this,8085);
    
    channels = new AnalysedChannel[4];
    for(int i = 0; i < 4; i++)
      channels[i] = new AnalysedChannel();
      
   /*
   a0 = 0.000003609051216708953
a1 = 0
a2 = -0.000003609051216708953
b1 = -1.8595462605545876
b2 = 0.9999927818975666
*/
    theta = new Filter(0.000003609051216708953, 0,  -0.000003609051216708953, -1.8595462605545876, 0.9999927818975666);
    bitalino.addEEGListener(this);
  }
  
  public AnalysedChannel[] getChannels(){
    
    return channels;
  }
  
  public float getTheta() {
    return channels[0].getLatest();
    //return theta.getLatest();
  }
  
  public float getEEG() {
    
    return latestEEG;
  }
  
  public float getLatestAt(int channel) {
    return channels[channel].getLatest();
  }
  
  
  public void newInput (float dataPoint) {
    println(dataPoint);
    latestEEG = dataPoint;
    analysis.set("real", 1);
    analysis.set("val", dataPoint);
    //theta.setSample(dataPoint);
    
  }
  
  public void caughtError(Exception e) {
     analysis.set("real", 0); 
    
  }
  
  public void setEmergency(boolean uhoh) {
    if(uhoh)
      analysis.set("real", 0);
    else
      analysis.set("real", 1);
  }
  
  void oscEvent(OscMessage theOscMessage) {
  /* check if theOscMessage has the address pattern we are looking for. */
  
  if(theOscMessage.checkAddrPattern("/amp")==true) {
    //println("oscmessage /amp");
    /* check if the typetag is the right one. */
    //println("typetag " + theOscMessage.typeTag());
    //if(theOscMessage.checkTypetag("sf")) {
      /* parse theOscMessage and extract the values from the osc message arguments. */
      int id = theOscMessage.get(0).intValue();  
      float amp = theOscMessage.get(1).floatValue();
      //print("### received an osc message /test with typetag if.");
      //println(" values: "+id+", "+amp);
      
      channels[id].setAmp(amp);
      return;
    //}  
  } 
  //println("### received an osc message. with address pattern "+theOscMessage.addrPattern());
}

  
  
}

public class Filter {

    float latest;
    float [] latest100;
    float n1, n2;
    //float n1, n2;
    float a0, a1, a2, b1, b2;

  public Filter(float a0, float a1, float a2, float b1, float b2) {
    n1=0; n2=0;
    this.a0 = a0;
    this.a1 = a1;
    this.a2 = a2;
    this.b1 = b1;
    this.b2 = b2;
    
    latest100 = new float[100];
   }
   
   
   public void setSample(float samp){
     //latest = samp;
      //int i;
      float a, in, s0, out;
      //word s0;
      //for (i=0; i<NTICK; i++) {
          //A = samp;
          //A = A- (a1 * n1);
          samp = samp - (a1 * n1);          
          //A -= a->a1 * a->s1;
          
          //A -= a->a2 * a->s2;
          samp = samp - (a2 * n2);
          
          s0 = samp;
          
          //A += a->b1 * a->s1;
          samp = samp + (b1 * n1);
          
          //a->output[i] = a->b2 * a->s2 + A;
          out = (b2 * n2) + samp;
          
          n2 = n1;
          n1 = s0;
      //}
      
      latest = out;
      
      for(int i = 0; i < (latest100.length-1); i++) {
        latest100[i] = latest100[i+1];
      }
      latest100[latest100.length -1] = latest;
  }
  
  public float getRMS () {
    
     float sum = 0;
     for(int i = 0; i < (latest100.length); i++) {
        sum = sum + (latest100[i] * latest100[i]);
     }
     
     sum = sum / latest100.length;
     
     
     return sqrt(sum);   
    
  }
  
  
  public float getLatest() {
    
    return this.getRMS();
  }


}
 
public class AnalysedChannel {
 
  int id;
  String rmsKey;
  String peak;
  float latest;
  OscP5 oscP5;

  
  
  public AnalysedChannel() { }
   
  public void setAmp(float amp) {
      
      latest = amp;
    }
  
  public float getLatest() {
    
    return latest;
  }
  
  
}
