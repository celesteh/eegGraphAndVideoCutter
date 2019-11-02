public class BreakPoint implements Comparable<BreakPoint> {


  double time, start_time;
  float value;

  public BreakPoint (double when, double what) {
    this(when, (float)what);
  }
  public BreakPoint (double when, float what) {
    time = when;
    value = what;
  }

  public BreakPoint(String parse) {

    String[] parts = parse.split(":");
    System.out.println("bp " + parse + " " + parts[0] /*+ " - " + parts[1]*/);
    time = Double.parseDouble(parts[0]);
    value = Float.parseFloat(parts[1]);
  }

  public double getTime() {
    return time;
  }

  public float getValue() {
    return value;
  }

  public void setStart(double startTime) {
    start_time = startTime;
  }

  public boolean isFuture(double now) {
    boolean answer = false;
    if (time > now) {
      answer = true;
    }
    return answer;
  }


  public boolean isFuture() {
    return isFuture(currentTime());
  }


  public double currentTime(double startTime) {
    start_time = startTime;
    return currentTime();
  }

  public double currentTime() {
    double now = System.currentTimeMillis();
    return now - start_time;
  }


  public int compareTo(BreakPoint comparePoint) {

    int result;
    double compareTime = ((BreakPoint) comparePoint).getTime(); 

    if (time > compareTime) {
      result = 1;
    } else { 
      if (time < compareTime) {
        result = -1;
      } else {
        result = 0;
      }
    }
    //ascending order
    //return ((int) this.getTime() - compareTime);

    //descending order
    //return compareQuantity - this.quantity;

    return result;
  }

  public double timeDistance(BreakPoint comparePoint) {
    return Math.abs(time - comparePoint.getTime());
  }

  public float valueDistance(BreakPoint secondPoint) {
    return secondPoint.getValue() - value;
  }

  public float currentValue(BreakPoint secondPoint) {

    float current, numerator, ratio, result=value;
    current = ((float)currentTime() );
    /*
    numerator = ((float)(current - time));
     if ( numerator <= 0) {
     //ratio = 0;
     result = getValue();
     } else {
     if (current >= secondPoint.getTime()) {
     //ratio =1;
     result = secondPoint.getValue();
     } else {
     ratio = (float) (numerator / timeDistance(secondPoint)); 
     result = lerp(value, secondPoint.getValue(), ratio);
     }
     */
    return valueAt(secondPoint, current);
  }

  public float valueAt(BreakPoint secondPoint, double when) {

    float current, numerator, ratio, result=value;
    //current = time;//((float)currentTime() );
    //numerator = ((float)(current - time));
    ratio = -1;
    numerator = (float) (when - time);
    if ( when <= time) {
      //ratio = 0;
      result = getValue();
    } else {
      if (when >= secondPoint.getTime()) {
        //ratio =1;
        result = secondPoint.getValue();
      } else {
        ratio = (float) (numerator / timeDistance(secondPoint)); 
        result = lerp(value, secondPoint.getValue(), ratio);
      }
    }
    //System.out.println("when " + when + " time " + time + " second " + secondPoint.getTime());
    //System.out.println("ratio " + ratio + " result " + result);

    return result;
  }


  public String toString() {
    return (""+time+":"+value);
  }
}
