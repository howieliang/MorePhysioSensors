//*********************************************
// Time-Series Physiological Signal Processing
// e7_TimeSeriesData_HRVLIveDraw
// Rong-Hao Liang: r.liang@tue.nl
//*********************************************
//Before use, please make sure your Arduino has 1 sensor connected
//to the analog input, and SerialTx_A0D2.ino was uploaded.

import processing.serial.*;
Serial port; 

int dataNum = 500; //number of data to show
int rawData = 0; //raw data from serial port

float[] ppgHist = new float[dataNum]; //history data to show

int beatData = 0; //raw data from serial port
float[] beatHist = new float[dataNum]; //history data to show

boolean beatDetected = false;

int ts = 0; //global timestamp (updated by the incoming data)
float[] IBIHist   = new float[dataNum];  //history interbeat intervals (IBI)
int currIBI = 0;
int lastBeatTime = 0;

ArrayList<Float> IBIList;
int maxFileSize = 1000;
int lastCapture = 0;
boolean bClear = false;
boolean bDrawOnly = false;
boolean bPictureIt = false;

ArrayList<Float> HRList;
float currHR = 0;
ArrayList<Float> SDNNList;
float currSDNN = 0;

int ppg2 = 0;
float[] ppgHist2 = new float[dataNum]; 
float[] beatHist2 = new float[dataNum];
float[] IBIHist2 = new float[dataNum];

boolean beatDetected2 = false;
ArrayList<Float> IBIList2;
ArrayList<Float> HRList2;
ArrayList<Float> SDNNList2;
int currIBI2 = 0;
float currHR2 = 0;
float currSDNN2 = 0;
int lastBeatTime2 = 0;

//Filtering
int lastIBI = 0;
int lastIBI2 = 0;
float ratio = 0.25;
float IBI_UB = 1500; //40 bpm
float IBI_LB = 400; //150 bpm

void setup() {
  size(500, 500);

  //Initiate the serial port
  for (int i = 0; i < Serial.list().length; i++) println("[", i, "]:", Serial.list()[i]);
  String portName = Serial.list()[Serial.list().length-1];//check the printed list
  //String portName = Serial.list()[0]; //For windows PC
  port = new Serial(this, portName, 115200);
  port.bufferUntil('\n'); // arduino ends each data packet with a carriage return 
  port.clear();           // flush the Serial buffer

  //IBIList for LiveDrawing
  IBIList = new ArrayList<Float>();
  HRList = new ArrayList<Float>();
  SDNNList = new ArrayList<Float>();

  IBIList2 = new ArrayList<Float>();
  HRList2 = new ArrayList<Float>();
  SDNNList2 = new ArrayList<Float>();
}

void draw() {
  background(255);
  //set styles
  fill(255, 0, 0);
  //visualize the serial data
  float h = height/5;
  float scale = 1. * (float)round((map(mouseX, 0, width, 1, 5)));
  if (!bDrawOnly) {
    lineGraph(ppgHist, 0, 1023, 0, 0*h, width, h, color(255, 0, 0));
    lineGraph(beatHist, 0, 1, 0, 0*h, width, h, color(0, 0, 255));
    lineGraph(ppgHist2, 0, 1023, 0, 3*h, width, h, color(255, 0, 0));
    lineGraph(beatHist2, 0, 1, 0, 3*h, width, h, color(0, 0, 255));
    drawInfo(scale, h);
  }
  
  pushMatrix();
  translate(0, 2*h);
  drawLiveList(scale, h, IBIList, HRList, SDNNList);
  popMatrix();
  
  pushMatrix();
  translate(0, 3*h);
  drawLiveList(scale, h, IBIList2, HRList2, SDNNList2);
  popMatrix();

  if (bClear) {
    IBIList.clear();
    HRList.clear();
    SDNNList.clear();
    IBIList2.clear();
    HRList2.clear();
    SDNNList2.clear();
    lastCapture = ts;
    bClear = false;
  }
}

void drawLiveList(float scale, float h, ArrayList<Float> IBIList, ArrayList<Float> HRList, ArrayList<Float> SDNNList) {
  if (IBIList!=null) {
    float lastX = 0;
    float lastY = 0;
    int visLength = min(IBIList.size(), min(HRList.size(), SDNNList.size()));
    for (int i = 0; i < visLength; i++) {
      float ibi = IBIList.get(i);
      float hr =  HRList.get(i);
      float sdnn = SDNNList.get(i);
      float x = map(ibi, 0, 60000*scale, 0, width); //60000ms = 1 min;
      float yIBI = map(ibi, 0, 1500, 0, h);
      float yHR = map(hr, 0, 120, 0, h);
      float ySDNN = map(sdnn, 0, 100, 0, h);

      if (ibi > 0) {
        stroke(0, 255, 255);
      } else {
        stroke(255, 0, 255);
        x = map(-ibi, 0, 60000*scale, 0, width); //60000ms = 1 min;
        yIBI = map(-ibi, 0, 1500, 0, h);
      }

      noStroke();
      if (ibi > 0) {
        fill(0, 255, 255);
      } else {
        fill(255, 0, 255);
      }
      ellipse(lastX, -yHR, 10/scale, 10/scale);

      noStroke();
      if (ibi > 0) {
        fill(0, 255, 0);
      } else {
        fill(255, 0, 255);
      }
      ellipse(lastX, -ySDNN, 10/scale, 10/scale);

      stroke(255, 0, 0);
      noFill();
      line(lastX, 0, lastX, -yIBI); 
      lastX+=x;
      lastY=yIBI;
    }
  }
}

void drawInfo(float scale, float h) {
  fill(0);
  textAlign(RIGHT, CENTER);
  text("Press 'c' to restart capturing", width, 0.1*h);
  text("Press 'd' to hide the raw data", width, 0.2*h);
  text("Move 'MouseX' to change time scale", width, 0.3*h);
  stroke(0);
  fill(0);
  textAlign(LEFT, CENTER);
  text("PPG1 and HeartBeat", 0, .1*h);
  line(0, 1*h, width, 1*h);
  //lineGraph(IBIHist, 0, 1500, 0, 1*h, width, h/2, color(255, 0, 255));//History of sensor data
  
  fill(0);
  textAlign(LEFT, CENTER);
  text("PPG1 Legend", 0, 1.1*h);
  textAlign(RIGHT, CENTER);
  text("Last IBI: "+currIBI+" ms", width, 1.1*h);
  text("IBI collected: "+IBIList.size()+"/"+maxFileSize, width, 1.2*h);
  text("Time Lapsed: "+nf((float)(ts-lastCapture)/1000., 0, 1)+" (s)", width, 1.3*h);
  if (HRList.size()<HR_WINDOW) text("Calculating Heart Rate: "+HRList.size()+"/"+HR_WINDOW, width, 1.4*h);
  else text("Heart Rate: "+nf(currHR, 0, 1)+" bpm", width, 1.4*h);
  if (SDNNList.size()<SDNN_WINDOW) text("Calculating SDNN: "+SDNNList.size()+"/"+SDNN_WINDOW, width, 1.5*h);
  else text("SDNN: "+nf(currSDNN, 0, 1)+" ms", width, 1.5*h);
  textAlign(LEFT, CENTER);
  text(0+"s", 0, 1.9*h);
  textAlign(RIGHT, CENTER);
  text(60*scale+"s", width, 1.9*h);
  stroke(0);
  line(0, 2*h, width, 2*h);
  
  fill(0);
  textAlign(LEFT, CENTER);
  text("PPG2 Legend", 0, 2.1*h);
  textAlign(RIGHT, CENTER);
  text("Last IBI: "+currIBI2+" ms", width, 2.1*h);
  text("IBI collected: "+IBIList2.size()+"/"+maxFileSize, width, 2.2*h);
  text("Time Lapsed: "+nf((float)(ts-lastCapture)/1000., 0, 1)+" (s)", width, 2.3*h);
  if (HRList2.size()<HR_WINDOW) text("Calculating Heart Rate: "+HRList2.size()+"/"+HR_WINDOW, width, 2.4*h);
  else text("Heart Rate: "+nf(currHR2, 0, 1)+" bpm", width, 2.4*h);
  if (SDNNList2.size()<SDNN_WINDOW) text("Calculating SDNN: "+SDNNList2.size()+"/"+SDNN_WINDOW, width, 2.5*h);
  else text("SDNN: "+nf(currSDNN2, 0, 1)+" ms", width, 2.5*h);
  textAlign(LEFT, CENTER);
  text(0+"s", 0, 2.9*h);
  textAlign(RIGHT, CENTER);
  text(60*scale+"s", width, 2.9*h);
  stroke(0);
  line(0, 3*h, width, 3*h);
  
  fill(0);
  textAlign(LEFT, CENTER);
  text("PPG2 and HeartBeat", 0, 3.1*h);
  line(0, 4*h, width, 4*h);
}

void serialEvent(Serial port) {   
  String inData = port.readStringUntil('\n');  // read the serial string until seeing a carriage return
  int dataIndex = -1;
  if (inData.charAt(0) == 'A') {  
    dataIndex = 0;
  }
  if (inData.charAt(0) == 'B') {  
    dataIndex = 1;
  }
  if (inData.charAt(0) == 'C') {  
    dataIndex = 5;
  }
  if (inData.charAt(0) == 'D') {  
    dataIndex = 6;
  }
  //data processing
  if (dataIndex==0) {
    rawData = int(trim(inData.substring(1))); //store the value
    appendArray(ppgHist, rawData); //store the data to history (for visualization)
    ts+=2; //update the timestamp
    return;
  }
  if (dataIndex==1) {
    beatData = int(trim(inData.substring(1))); //store the value
    if (!beatDetected) {
      if (beatData==1) { 
        beatDetected = true; 
        appendArray(beatHist, 1); //store the data to history (for visualization)
        if (lastBeatTime>0) {
          currIBI = ts-lastBeatTime;
          if (IBIList.size() < maxFileSize) {
            boolean flagAB = false; // abnormal beat
            //check ther filter
            float diff = (float)abs(currIBI-lastIBI);
            float diffRatio = (lastIBI == 0 ? 1: diff/(float)lastIBI);
            if (diffRatio>ratio && IBIList.size()>0) {
              flagAB = true;
            }
            if (!flagAB) {
              IBIList.add((float)currIBI); //add the currIBI to the IBIList
              currHR = nextValueHR((float)currIBI, dataIBI);
              if (HRList.size()<HR_WINDOW) {
                HRList.add((float)0);
              } else {
                HRList.add(currHR);
              }
              currSDNN = nextValueSDNN((float)currIBI, dataSDNN);
              if (SDNNList.size()<SDNN_WINDOW) {
                SDNNList.add((float)0);
              } else {
                SDNNList.add(currSDNN);
              }
            } else {
              IBIList.add((float)-currIBI); //add the currIBI to the IBIList
              SDNNList.add(currSDNN);
              HRList.add(currHR);
            }
            lastIBI = currIBI;
          }
        } 
        lastBeatTime = ts;
      } else {
        appendArray(beatHist, 0); //store the data to history (for visualization)
      }
    } else {
      if (beatData==0) beatDetected = false;
      appendArray(beatHist, 0); //store the data to history (for visualization)
    }
    appendArray(IBIHist, currIBI); //store the data to history (for visualization)
    return;
  }
  if (dataIndex==5) {
    ppg2 = int(trim(inData.substring(1))); //store the value
    appendArray(ppgHist2, ppg2); //store the data to history (for visualization)
    return;
  }
  if (dataIndex==6) {
    float beatPulse = int(trim(inData.substring(1))); //store the value
    appendArray(beatHist2, beatPulse); //store the data to history (for visualization)
    if (!beatDetected2) {
      if (beatPulse==1) { 
        beatDetected2 = true; 
        if (lastBeatTime2>0) {
          currIBI2 = ts-lastBeatTime2;
          if (IBIList2.size() < maxFileSize) {
            boolean flagAB = false; // abnormal beat
            float diff = (float)abs(currIBI2-lastIBI2);
            float diffRatio = (lastIBI2 == 0 ? 1: diff/(float)lastIBI2);
            if (diffRatio>ratio && IBIList2.size()>0) {
              flagAB = true;
            }
            if (!flagAB) {
              IBIList2.add((float)currIBI2); //add the currIBI to the IBIList
              currHR2 = nextValueHR((float)currIBI2, dataIBI2);
              if (HRList2.size()<HR_WINDOW) {
                HRList2.add((float)0);
              } else {
                HRList2.add(currHR2);
              }
              currSDNN2 = nextValueSDNN((float)currIBI2, dataSDNN2);
              if (SDNNList2.size()<SDNN_WINDOW) {
                SDNNList2.add((float)0);
              } else {
                SDNNList2.add(currSDNN2);
              }
            } else {
              IBIList2.add((float)-currIBI2); //add the currIBI to the IBIList
              if (HRList2.size()<HR_WINDOW) {
                HRList2.add((float)0);
              } else {
                HRList2.add(currHR2);
              }
              if (SDNNList2.size()<SDNN_WINDOW) {
                SDNNList2.add((float)0);
              } else {
                SDNNList2.add(currSDNN2);
              }
            }
            lastIBI2 = currIBI2;
          }
        } 
        lastBeatTime2 = ts;
      }
    } else {
      if (beatPulse==0) beatDetected2 = false;
    }
    return;
  }
}

//Append a value to a float[] array.
float[] appendArray (float[] _array, float _val) {
  float[] array = _array;
  float[] tempArray = new float[_array.length-1];
  arrayCopy(array, 1, tempArray, 0, tempArray.length);
  array[array.length-1] = _val;
  arrayCopy(tempArray, 0, array, 0, tempArray.length);
  return array;
}

//Append a value to a float[] array.
PVector[] appendArray (PVector[] _array, PVector _val) {
  PVector[] array = _array;
  PVector[] tempArray = new PVector[_array.length-1];
  arrayCopy(array, 1, tempArray, 0, tempArray.length);
  array[array.length-1] = _val;
  arrayCopy(tempArray, 0, array, 0, tempArray.length);
  return array;
}

//Draw a line graph to visualize the sensor stream
//lineGraph(float[] data, float lowerbound, float upperbound, float x, float y, float width, float height, color c)
void lineGraph(float[] data, float _l, float _u, float _x, float _y, float _w, float _h, color _c) {
  pushStyle();
  noFill();
  stroke(_c);
  float delta = _w/data.length;
  beginShape();
  for (float i : data) {
    float y = map(i, _l, _u, 0, _h);
    vertex(_x, _y+(_h-y));
    _x = _x + delta;
  }
  endShape();
  popStyle();
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    ts = 0;
    lastBeatTime = 0;
    currIBI = 0;
  }
  if (key == 'c' || key == 'C') {
    bClear = true;
  }
  if (key == 'd' || key == 'D') {
    bDrawOnly = (bDrawOnly? false: true);
  }
}
