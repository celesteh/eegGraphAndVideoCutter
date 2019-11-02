import java.io.File;
import java.util.Properties;
import java.awt.*;
import java.util.*;
import java.util.Enumeration;
import java.util.Iterator;
import java.util.Arrays;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JPasswordField;
import javax.swing.JTextField;
import javax.swing.SwingUtilities;
import javax.swing.UIManager;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;


public class BiometricController {

  Properties prop;
  String path;
  eegvisualisation app;
  //Vector breakPoints;
  BreakPointWrangler probabilities, pauses;
  ControllerPanel gui;

  public BiometricController(eegvisualisation owner) {
    app = owner;
    prop = new Properties();
    //breakcounter = 0;
    //breakPoints = new Vector(2);
    probabilities = new BreakPointWrangler("prob", this);
    pauses = new BreakPointWrangler("pause", this);
    gui = new ControllerPanel(this);
  }

  public BiometricController(eegvisualisation owner, String filePath) {
    this(owner);

    //InputStream inputStream;
    FileInputStream inputStream;

    path = filePath;
    //String propFileName = "config.properties";
    System.out.println(path);

    try {
      //ClassLoader loader = Thread.currentThread().getContextClassLoader();        
      //System.out.println("loader "+loader);
      //inputStream = getClass().getClassLoader().getResourceAsStream(path);
      //inputStream = loader.getResourceAsStream(path);

      inputStream = new FileInputStream(path);
      System.out.println("stream "+inputStream);

      if (inputStream != null) {
        System.out.println("Got stream");
        prop.load(inputStream);
      }
    }
    catch (Exception e)
    {
      //If the file ins't found, that's ok
      System.out.println("File exception: "+e);
    }
    //Date time = new Date(System.currentTimeMillis());

    //breakPoints = new Vector(Arrays.asList(loadBreakPoints()));
    loadBreakPoints();

    probabilities.audit();
    pauses.audit();
  }

  public void write() {
    // output to file
  }

  /*
  public void read() {
   // reads from file
   }
   */

  public String getSetting(String name) {
    return prop.getProperty(name);
  }

  public void setSetting(String name, String value) {
    prop.setProperty(name, value);
  }


  public void start() {

    app.fadeIn();
  }

  public void stop() {
    app.fadeOut();
  }

  public void ready() {

    gui.ready();
  }

  public /*BreakPoint[]*/ void loadBreakPoints() {
    String tag;
    Enumeration allNames;
    Vector keys = new Vector(2);
    //String[] keyarr;
    boolean newpoints;
    //BreakPoint[] pointarr;
    BreakPoint point;

    allNames = prop.propertyNames();
    while (allNames.hasMoreElements()) {
      tag = (String) allNames.nextElement();
      System.out.println(tag + " " + prop.getProperty(tag));
      if (tag.startsWith("bp")) {
        //keys.add(tag);
        point = new BreakPoint(prop.getProperty(tag));
        System.out.println("new point " + prop.getProperty(tag) + " " + tag + " point " + point);
        probabilities.addBreakPoint(point, tag);
        pauses.addBreakPoint(point, tag);
      }
    }

    prop.list(System.out);

    /*
    newpoints = false;
     if (breakPoints == null) { 
     newpoints = true;
     } else { 
     if (breakPoints.size() == 0) {
     newpoints = true;
     }
     }
     if (newpoints) {
     breakPoints = new Vector(keys.size()+2);
     }
     
     pointarr = new BreakPoint[keys.size()];
     
     
     //if(keys.size() > 0){
     //keyarr = new String[keys.size()];
     
     for (int i =0; i < keys.size(); i++) {
     pointarr[i] = new BreakPoint(prop.getProperty((String) keys.elementAt(i)));
     }
     
     Arrays.sort(pointarr);
     
     return pointarr;
     */    /*
    for (int i =0; i < keys.size(); i++) {
     tag = (String) keys.elementAt(i);
     point = new BreakPoint(prop.getProperty(tag));
     System.out.println("new point " + prop.getProperty(tag) + " " + tag + " point " + point);
     probabilities.addBreakPoint(point, tag);
     pauses.addBreakPoint(point, tag);
     }*/
  }
  /*
  public void addBreakPoint(BreakPoint point) {
   String key;
   int size = breakPoints.size();
   
   breakPoints.add(point);
   Collections.sort(breakPoints);
   
   key = "break"+size;
   this.setSetting(key, point.toString());
   }
   */

  public BreakPointWrangler getPausePoints() {
    return pauses;
  }

  public BreakPointWrangler getprobabilityPoints() {
    return probabilities;
  }

  public double getPauseAt(double time) {
    return pauses.valueAt(time);
  }

  public float getProbabilityAt(double time) {
    return probabilities.valueAt(time);
  }

  public void setStart(double time) {
    // probably not needed
  }
}

public class BreakPointWrangler {
  String key;
  Vector breakPoints;
  BiometricController parent;
  BreakPoint last, next;

  public BreakPointWrangler(String name_match, BiometricController controller) {
    key = name_match;
    breakPoints = new Vector();
    parent = controller;
  }

  public String getKey() {
    return key;
  }

  public void addBreakPoint(BreakPoint point) {
    String tag;
    int size = breakPoints.size();

    breakPoints.add(point);
    Collections.sort(breakPoints);

    tag = "break/"+key+ "/" +size;
    parent.setSetting(tag, point.toString());
    last = null;
    next = null;
  }

  public boolean addBreakPoint(BreakPoint point, String name) {
    String bp, type;
    int num;
    boolean match;
    String[] parts = name.split("/");
    bp = parts[0];
    type = parts[1];
    match = type.equals(key);
    num = Integer.parseInt(parts[2]);

    if (match) {
      System.out.println("bp " + name + " " + parts[1] /*+ " - " + parts[1]*/);
      addBreakPoint(point);
    }

    return match;
  }

  public void audit() {
    for (int i = 0; i < breakPoints.size(); i++) {
      System.out.println(""+ i + " " + (BreakPoint) breakPoints.elementAt(i));
    }
  }

  public BreakPoint getNextBreakPoint(double time) throws noFutureBreakPointsException {
    /*
    boolean found;
     BreakPoint point = null;
     double pointTime;
     found = false;
     
     for (int i = 0; (i < breakPoints.size()) && (! found); i++) {
     point = (BreakPoint) breakPoints.elementAt(i);
     pointTime = point.getTime();
     found = (pointTime > time);
     }
     
     if (! found) {
     point = null;
     throw new noFutureBreakPointsException();
     }
     return point;
     */
    return getPointsAround(time)[1];
  }

  public BreakPoint getFirstBreakPoint() {
    BreakPoint point=null;

    if (breakPoints.size() > 0) {
      point = (BreakPoint) breakPoints.elementAt(0);
    }

    //if ( point != null) {
    //  System.out.println(point.getTime());
    //}
    return point;
  }

  public BreakPoint getLastBreakPoint() {
    BreakPoint point = null;
    int size;

    size = breakPoints.size();
    if (size > 0) {
      point = (BreakPoint) breakPoints.elementAt(size - 1);
    }

    return point;
  }

  public BreakPoint[] getPointsAround(double time) throws noFutureBreakPointsException {
    boolean found;
    BreakPoint prev = null;
    BreakPoint point = null;
    double pointTime;
    found = false;
    BreakPoint[] arr;
    int index=0;

    for (int i = 0; (i < breakPoints.size()) && (! found); i++) {
      index = 1;
      prev = point;
      point = (BreakPoint) breakPoints.elementAt(i);
      pointTime = point.getTime();
      System.out.println("Searching " + pointTime);
      found = (pointTime > time);
    }

    if (! found) {
      point = null;
      System.out.println("Not found");
      throw new noFutureBreakPointsException();
    } else if (prev == null) {
      prev = point;
    } else if (prev.getTime() == point.getTime()) {
      if (index >= 1) {
        prev = (BreakPoint) breakPoints.elementAt(index -1);
      }
    }

    arr = new BreakPoint[2];
    arr[0] = prev;
    arr[1] = point;
    return arr; //new BreakPoint[]{last, point};
  }

  public float valueAt(double time) {
    BreakPoint[] arr;
    //BreakPoint first, second;
    float value=0;
    boolean getPoints = false;
    boolean calcValue = true;

    if (last == null || next ==null) {
      getPoints = true;
    } else if (time > next.getTime()) {
      getPoints = true;
    }

    if (getPoints) {
      System.out.println("Recalculating points");
      try {
        arr = this.getPointsAround(time);
        last = arr[0]; 
        next = arr[1];
      } 
      catch (noFutureBreakPointsException e) {
        last = getLastBreakPoint();
        calcValue = false;
        if ( last != null) {
          value = last.getValue();
        } else {
          value = 0;
        }
      }
    }
    if (calcValue) {
      //System.out.println(" last, next " + last + " " + next);
      value = last.valueAt(next, time);
    }

    //System.out.println("time is " + time);

    return value;
  }
}


public class ControllerPanel extends JFrame implements ActionListener{

  BiometricController parent;
  JButton startbutton;
  JButton stopbutton;

  public ControllerPanel(BiometricController controller) {

    System.out.println("gui constructor");
    parent = controller;
    startbutton = new JButton("Start");
    startbutton.setActionCommand("start");
    startbutton.setEnabled(false);
    startbutton.addActionListener(this);
    stopbutton = new JButton("Stop");
    stopbutton.setActionCommand("stop");
    stopbutton.setEnabled(false);
    stopbutton.addActionListener(this);

    JPanel newPanel = new JPanel(new GridBagLayout());

    GridBagConstraints constraints = new GridBagConstraints();
    constraints.anchor = GridBagConstraints.WEST;
    constraints.insets = new Insets(10, 10, 10, 10);

    // add components to the panel
    constraints.gridx = 0;
    constraints.gridy = 0;   
    newPanel.add(startbutton, constraints);

    constraints.gridx = 1;
    newPanel.add(stopbutton, constraints);

    // set border for the panel
    newPanel.setBorder(BorderFactory.createTitledBorder(
      BorderFactory.createEtchedBorder(), "Biometric Player"));

    // add the panel to this frame
    add(newPanel);

    pack();
    setLocationRelativeTo(null);
    this.setVisible(true);
  }

  public void play() {
    startbutton.setEnabled(false);
    stopbutton.setEnabled(true);
  }

  public void stop() {
    startbutton.setEnabled(true);
    stopbutton.setEnabled(false);
  }

  public void ready() {
    stop();
  }

  public void actionPerformed(ActionEvent e) {
    System.out.println("Action! " + e.getActionCommand());
    if ("start".equals(e.getActionCommand())) {
      parent.start();
      play();
    } else {
      if ("stop".equals(e.getActionCommand())) {
        parent.stop();
        stop();
      }
    }
  }
}


public class noFutureBreakPointsException extends Exception {
}
