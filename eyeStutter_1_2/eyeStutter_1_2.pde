/*
----------------------EYE STUTTER-------------------------------
Eye Stutter is a simple VJ app that takes the first camera feed 
coming off a laptop and applies brightness filter that changes
the colour of the image triggered by an audio threshold. 
Play around with the different parameters live to change the 
image, you can change the brightness threshold, mic threshold 
and the opacity of various filtered parts to see how it works.
Its controls and effects are a bit esoteric but that is the point 
: ).

This version is built to work with 32-bit Processing 1.2.1 with
controlP5 version 0.5.0 and JMyron 0025 porting to Processing 2.0
with modern libraries is possible but non trivial because of mayor 
changes on how video and drawing in general work. The reason for 
me use this version is because of the lovely grainy glitchy quality 
it has, it looks very different in Processing 2.0 much too clean. 

Feel free to use this code and hack around with it, but please do
not claim you wrote the original source code.
Simon Sarginson
*/

/*
----------------------INITIAL SETUP----------------------------- 
*/
import controlP5.*; // import slider, sound and video library
import ddf.minim.*;
import JMyron.*;

Minim minim;
ControlP5 controlP5;

Slider slider;
Slider slider2;
Slider slider3;
Slider slider4;
Slider slider5;

AudioInput in;     // the mic
Timer attackTimer; // timer for fading images over time
Timer colourTimer; // timer for randomising colours
JMyron m;          // camera object
/* 
---------------------VARIABLES-----------------------------------
*/
int captureWidth = 640;
int captureHeight = 480;

int sliderLength = captureWidth- 140;
int sliderHeight = 10;
int allSliderXOffset = 10;                 
int perSliderYOffset = sliderHeight+sliderHeight / 2;
int sliderGuiSize = (5 + 1) * perSliderYOffset; // extension amount of the video window for sliders 5 is number of sliders

float attackLength = 500.0;                     // fade duration for filter effect
 
float colourFadeFactor = 255.0 / attackLength;  // stores how fast the the filter should fade base on attack time and colour difference
float colourFade;                               // stores the colour of the fading effect

float colourRandomInterval = 200.0; 

float rFactor = 1;          //
float gFactor = 1;          // RGB modifiers for the above threshold part of filtered image
float bFactor = 1;          //

//             CONTROLLABLE VALUE'S
float brightnessThreshold = 30;           // threshold for brightness filter
float micSensitivity = 0.05;              // threshold for mic to trigger filter
float opacityAboveThreshold = 50.0;       // opacity for above threshold part of filtered image
float opacityBelowThreshold = 50.0;       // opacity for below threshold part of filterd image
float opacityNormalImage = 255;           // opacity for normal camera image


void setup(){
  size(640,480 + sliderGuiSize); // size capture + room  for sliders
  
  attackTimer = new Timer();
  colourTimer = new Timer();
  
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 512);
  
  video = new JMyron();
  video.start(captureWidth,captureHeight);//start a capture at width height minus slider area
  video.findGlobs(0);//disable the glob tracking to speed up frame rate
 
  controlP5 = new ControlP5(this);
  
  slider  = controlP5.addSlider("micSensitivity"         ,0,1  ,micSensitivity        ,allSliderXOffset ,captureHeight + perSliderYOffset * 1,sliderLength  ,sliderHeight);
  slider2 = controlP5.addSlider("brightnessThreshold"    ,0,255,brightnessThreshold   ,allSliderXOffset ,captureHeight + perSliderYOffset * 2,sliderLength  ,sliderHeight);
  slider3 = controlP5.addSlider("opacityAboveThreshold"  ,0,255,opacityAboveThreshold ,allSliderXOffset ,captureHeight + perSliderYOffset * 3,sliderLength  ,sliderHeight);
  slider4 = controlP5.addSlider("opacityBelowThreshold"  ,0,255,opacityBelowThreshold ,allSliderXOffset ,captureHeight + perSliderYOffset * 4,sliderLength  ,sliderHeight);
  slider5 = controlP5.addSlider("opacityNormalImage"     ,0,255,opacityNormalImage    ,allSliderXOffset ,captureHeight + perSliderYOffset * 5,sliderLength  ,sliderHeight);
}

void draw(){
  video.update();
  background(125);
  
  int[] img = video.image();
  float r,g,b,a;
  loadPixels();
  
  for(int i = 0; i < in.bufferSize() - 1; i++) // triggers the filter effect if the mic threshold is reached
  {
    if (in.left.get(i) > micSensitivity)
    {
      attackTimer.startTimer(attackLength);
      colourTimer.startTimer(colourRandomInterval);
    } 
  }
  
  /*
    The drawing part.
    If the values of R,G,B are all higher than the threshold value
    it will fill in those pixels with colour over time based on the
    attackLength with colourDif intensity modified by the r g b modifiers
  */
  
  if (attackTimer.getTimerOn())
  { 
    attackTimer.update();
    colourFade = colourFadeFactor * attackTimer.getMillisToInterval();
    
    colourTimer.update();
    if (!colourTimer.getTimerOn())
    {
      rFactor = random(.1,1.0);
      gFactor = random(.1,1.0);
      bFactor = random(.1,1.0);
    }
    
    for(int i = 0; i < captureWidth * captureHeight; i++){ //loop through all the pixels
        if (red(img[i]) > brightnessThreshold && green(img[i]) > brightnessThreshold && blue(img[i]) > brightnessThreshold)
        {
          r = colourFade * rFactor;
          g = colourFade * gFactor;
          b = colourFade * bFactor;
          a = opacityAboveThreshold;
        } else {
        r = red(img[i]);
        g = green(img[i]);
        b = blue(img[i]);
        a = opacityBelowThreshold;
        }
      pixels[i] = color(r,g,b,a); //draw each pixel to the screen
    }
  } else {
     for(int i = 0 ; i < captureWidth * captureHeight; i++){
        r = red(img[i]);
        g = green(img[i]);
        b = blue(img[i]);
        a = opacityNormalImage;
        pixels[i] = color(r,g,b,a);
     }
  }
  updatePixels();
}

class Timer{
  boolean timerOn = false;
  float endTime; 
  void startTimer(float interval)
  {
    endTime = millis() + interval;
    timerOn = true;
  }
  void update(){
    if (timerOn)
    {
      if (millis() > endTime){
        timerOn = false;
      }
    }
  }
  boolean getTimerOn()
  {
    return timerOn;
  }
  float getMillisToInterval()
  {
    return endTime - millis();
  }
}

/*
----------------------CLEAN-UP-------------------
*/
public void stop(){ // both JMyron and minim need to be stopped manually
  m.stop();
  in.close();
  minim.stop();
  super.stop();
}
