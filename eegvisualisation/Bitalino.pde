import  com.bitalino.comm.*;
import java.util.Vector;
import javax.bluetooth.*;
import processing.serial.*;
import java.io.*;
import java.nio.channels.ClosedChannelException;
import com.bitalino.comm.BITalinoDevice;
import com.bitalino.comm.BITalinoFrame;
import java.util.Enumeration;
import java.util.Vector;
import javax.bluetooth.DeviceClass;
import javax.bluetooth.DiscoveryAgent;
import javax.bluetooth.DiscoveryListener;
import javax.bluetooth.LocalDevice;
import javax.bluetooth.RemoteDevice;
import javax.bluetooth.ServiceRecord;

public class RemoteDeviceDiscovery {

  String address;
  boolean found;

  public RemoteDeviceDiscovery() {
    found = false;
  }

  String getAddress() {
    return address;
  }

  boolean isFound() {
    return found;
  }

  public Vector getDevices() {
    /* Create Vector variable */
    final Vector devicesDiscovered = new Vector();
    try {
      final Object inquiryCompletedEvent = new Object();
      /* Clear Vector variable */
      devicesDiscovered.clear();

      /* Create an object of DiscoveryListener */
      DiscoveryListener listener = new DiscoveryListener() {

        public void deviceDiscovered(RemoteDevice btDevice, DeviceClass cod) {
          /* Get devices paired with system or in range(Without Pair) */
          devicesDiscovered.addElement(btDevice);
          try {
            String friendly;
            friendly = btDevice.getFriendlyName(true);
            System.out.println(friendly);
            if (friendly.contains("BITalino")) {
              found = true;
              address = btDevice.getBluetoothAddress();
              System.out.println(address);
            }
          } 
          catch (Exception e) {
          };
        }

        public void inquiryCompleted(int discType) {
          /* Notify thread when inquiry completed */
          synchronized (inquiryCompletedEvent) {
            inquiryCompletedEvent.notifyAll();
          }
        }

        /* To find service on bluetooth */
        public void serviceSearchCompleted(int transID, int respCode) {
        }

        /* To find service on bluetooth */
        public void servicesDiscovered(int transID, ServiceRecord[] servRecord) {
        }
      };

      synchronized (inquiryCompletedEvent) {
        /* Start device discovery */
        boolean started = LocalDevice.getLocalDevice().getDiscoveryAgent().startInquiry(DiscoveryAgent.GIAC, listener);
        if (started) {
          System.out.println("wait for device inquiry to complete...");
          inquiryCompletedEvent.wait();
        }
      }
    } 
    catch (Exception e) {
      e.printStackTrace();
    }
    /* Return list of devices */
    return devicesDiscovered;
  }
}

public class BitListener {
 
  public void newInput(float data){
  }
  
  public void caughtError(Exception e) {
  }
  
  
}

public class BitReader  extends Thread {

  RemoteDeviceDiscovery systembt;
  String MAC;
  boolean paired;
  boolean open;
  BITalinoDevice device;
  BITalinoFrame[] lastread;
  BitListener eegListener;
  boolean keepGoing;
  int rate;
  float ecg;
  float emg;
  float eeg;

  public BitReader () {
    this(100);
    //final int samplerate = 100;
  }  

  public BitReader (int sampleRate) {
    rate = sampleRate;
    paired = false;
    open = false;
    this.discover();
  }

  private void discover() {

    systembt = new RemoteDeviceDiscovery();
    systembt.getDevices();
  }

  public void pair () throws Exception {
    if (! paired) {
      if (MAC == null) {
        if (systembt == null) {
          this.discover();
          throw new BitalinoUnreadyException();
        }
        if (systembt.isFound()) {
          MAC = systembt.getAddress();
        } else {
          throw new BitalinoNotFoundException();
        }
        systembt = null; // clear up old data
      }

      //final int samplerate = 100;
      int samplerate = rate;
      //final int [] analogs = new int[]{4}; // 0 is EMG, 1 is ECG, 2 is EDA, 3 is EEG, 4 is ACC
      int [] analogs = new int []{0,1,2,3,4,5};
      device = new BITalinoDevice(samplerate, analogs);

      // connect to BITalino device
      final StreamConnection conn = (StreamConnection) Connector.open("btspp://"
        + MAC + ":1", Connector.READ_WRITE);
      device.open(conn.openInputStream(), conn.openOutputStream());

      paired = true;

      // get BITalino version
      ///*logger.info*/System.out.println("Firmware Version: " + device.version());

      // start acquisition on predefined analog channels
      //device.start();
    }
  }

  public boolean isPaired() {

    return paired;
  }

  public boolean isOpen() {
    return open;
  }

  public void open() throws Exception {
    if (! open) {
      if (! paired) {
        this.pair();
      }
      try {
        device.start();
        open = true;
        keepGoing = true;
        start();
      } 
      catch (Exception e) {
        open = false;
        keepGoing = false;
        if (eegListener != null) {
          eegListener.caughtError(e);
        }

        throw e;
      }
    }
  }

  public BITalinoFrame[] read() throws Exception {
    return this.read(1);
  }

  public BITalinoFrame[] read(int num) throws Exception {
    if (open) {
      final BITalinoFrame[] frames = device.read(num);
      return frames;
    } else {
      throw new BitalinoUnreadyException();
    }
  }

  public void shouldStop () {
    keepGoing = false;
  }

  public void run () {
    BITalinoFrame[] framearr;
    
    long sleepDur = (long) (1 / rate) * 1000;

    try {
      sleep(500);
      while (keepGoing)
      {
        framearr = bit.read();
        if (framearr[0].getAnalog(0) != 0) {
          emg = (((float) framearr[0].getAnalog(0)) / 1023);
        }

        if (framearr[0].getAnalog(1) != 0) {
          ecg = (((float) framearr[0].getAnalog(1)) / 1023);
        }
        
        if (framearr[0].getAnalog(3) != 0) {
          eeg = (((float) framearr[0].getAnalog(3)) / 1023);
          if (eegListener != null) {
            eegListener.newInput(eeg);
          }
        }

        lastread = framearr;

        System.out.println("lastread " + lastread[0]);
        sleep(sleepDur);
        
      }

      wait();
    }
    catch (Exception e)
    {
      System.out.println("couldn't read");
      if (eegListener != null) {
        eegListener.caughtError(e);
      }
    }
  }

  public float getECG() throws BitalinoUnreadyException { //range 0-1 // this is a shitty way to scale this
    // check the documentation for the API to find better ways to get this
    float result;

    if (lastread == null) {
      System.out.println("ECG null");
      start();
      /*
      try {
       lastread = read();
       } 
       catch (Exception e) {
       }
       */
      throw new BitalinoUnreadyException();
    }

    if (lastread.length < 1) {
      System.out.println("No ECG frames");
      throw new BitalinoUnreadyException();
    }

    return ecg;
  }

  public float getEMG() throws BitalinoUnreadyException { //range 0-1 // this is a shitty way to scale this
    // check the documentation for the API to find better ways to get this
    float result;

    if (lastread == null) {
      throw new BitalinoUnreadyException();
    }

    if (lastread.length < 1) {
      throw new BitalinoUnreadyException();
    }

    result = lastread[0].getAnalog(0) / 1023;
    return emg;
  }

 public float getEEG() throws BitalinoUnreadyException { //range 0-1 // this is a shitty way to scale this
    // check the documentation for the API to find better ways to get this
    float result;

    if (lastread == null) {
      System.out.println("EEG null");
      start();

      throw new BitalinoUnreadyException();
    }

    if (lastread.length < 1) {
      throw new BitalinoUnreadyException();
    }

    result = lastread[0].getAnalog(0) / 1023;
    return eeg;
  }

  public void addEEGListener(BitListener bl) {
    
    eegListener = bl;
  }

  /*
  BluetoothDeviceDiscovery bluetoothDeviceDiscovery=new BluetoothDeviceDiscovery();
   //display local device address and name
   LocalDevice localDevice = LocalDevice.getLocalDevice();
   System.out.println("Address: "+localDevice.getBluetoothAddress());
   System.out.println("Name: "+localDevice.getFriendlyName());
   //find devices
   DiscoveryAgent agent = localDevice.getDiscoveryAgent();
   */


  /*
     * TODO change to your device's MAC address
   */
  //private static final String MAC = "20:13:08:08:15:83";
}



/*

 The user runing this class must be a memvber of the group dialup.
 Connect to the bitalino using the bluetooth GUI for your system
 Make a note of what /dev port it attached to
 
 from https://makezine.com/projects/use-bitalino-graph-biosignals-play-pong/
 edwindertien.nl
 */
/*
public class Bitalino {
 
 int PORTNUMBER;
 Serial port;
 int lines;
 int value[];
 char buffer[];
 int counter;
 PApplet parent;
 
 
 public Bitalino(PApplet app) {
 
 PORTNUMBER = 0;
 lines = 6;
 value= new int[lines];
 buffer = new char[8];
 counter = 0;
 parent = app;
 }
 
 public Bitalino(PApplet app, int portnum) {
 this(app);
 this.setPort(portnum);
 }
 
 public Bitalino(PApplet app, int portnum, int rate) {
 this(app);
 this.setPort(portnum, rate);
 }
 
 
 String[] getPorts () {
 
 String[] ports;
 int len;
 
 len = Serial.list().length;
 
 ports = new String[len];
 
 println("Available serial ports:");
 for (int i = 0; i<len; i++) {
 print("[" + i + "] ");
 println(Serial.list()[i]);
 ports[i] = Serial.list()[i];
 }
 
 return ports;
 }
 
 void setPort(int num, int rate) {
 PORTNUMBER = num;
 
 port = new Serial(parent, Serial.list()[PORTNUMBER], 115200);
 this.setRate(rate);
 }
 
 void setPort(int num) {
 
 this.setPort(num, 1);
 }
 
 void setRate( int rate) {
 
 int cmd = rate;  // 0 for 1 sample/sec, 1 for 10 samples/sec, 2 for 100 samples/sec, 3 for 1000 samples/sec
 port.write((cmd << 6) | 0x03); // 10 samples/sec
 delay(50);
 int channelmask = 0x3F;
 port.write(channelmask<<2 | 0x01);
 }
 
 int[] read() throws BitalinoUnreadyException {
 
 if (port.available () <= 0) {
 throw new BitalinoUnreadyException();
 }
 
 while (port.available () > 0) {
 serialEvent(port.read()); // read data
 }
 
 return value;
 }
 
 void serialEvent(int serialdata) {
 if (counter<7) {
 print(serialdata);
 print(',');
 buffer[counter] = (char)serialdata;
 counter++;
 } else {
 print(serialdata);
 buffer[counter] = (char)serialdata;
 counter = 0;
 // check CRC
 int crc = buffer[7] & 0x0F;
 buffer[7] &= 0xF0;  // clear CRC bits in frame
 int x = 0;
 for (int i = 0; i < 8; i++) {
 for (int bit = 7; bit >= 0; bit--) {
 x <<= 1;
 if ((x & 0x10) > 0)  x = x ^ 0x03;
 x ^= ((buffer[i] >> bit) & 0x01);
 }
 }
 if (crc != (x & 0x0F))  println(" - crc mismatch");
 else {
 println(" - crc ok");
 value[0] = ((buffer[6] & 0x0F) << 6) | (buffer[5] >> 2);
 value[1] = ((buffer[5] & 0x03) << 8) | (buffer[4]);
 value[2] = ((buffer[3]       ) << 2) | (buffer[2] >> 6);
 value[3] = ((buffer[2] & 0x3F) << 4) | (buffer[1] >> 4);
 value[4] = ((buffer[1] & 0x0F) << 2) | (buffer[0] >> 6);
 value[5] = ((buffer[0] & 0x3F));
 }
 }
 }
 }
 */

public class BitalinoUnreadyException extends IOException {
}
public class BitalinoNotFoundException extends IOException {
}
