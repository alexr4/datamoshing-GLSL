import processing.video.*;
import fpstracker.core.*;

PerfTracker pt;

Capture cam;
PGraphics current, previous;
boolean type;
String file1 = "datamosh-1";
String file2 = "datamosh3x3-5x5";
PShader datamosh;
PGraphics datamoshBuffer;

int camwidth = 1280;
int camheight = 720;
void settings() {
  size(camwidth, camheight, P3D);
}

void setup() {
  cam = new Capture(this, 1280, 720, "Logitech B910 HD Webcam", 30);
  // Start capturing the images from the camera
  cam.start();

  datamosh = loadShader(file2+".glsl");
  datamosh.set("resolution", (float)camwidth, (float)camheight);

  current = createGraphics(camwidth, camheight, P2D);
  previous = createGraphics(camwidth, camheight, P2D);
  datamoshBuffer = createGraphics(camwidth, camheight, P2D);

  pt = new PerfTracker(this, 100);

  frameRate(30);
}

void draw() {

  if (cam.available()) {
    cam.read(); // Read the new frame from the camera

    current.beginDraw();
    current.image(cam, 0.0, 0.0, current.width, current.height);
    current.endDraw();
  }

  if (current != null) {
    try {
      float threshold = noise(millis() * 0.0001, frameCount * 0.01) * 0.5 + 0.5;
      float offsetRGB = noise(frameCount * 0.0125, millis() * 0.005) * 0.005;

      datamosh.set("previous", datamoshBuffer);
      datamosh.set("threshold", threshold);
      datamosh.set("offsetRGB", offsetRGB);

      datamoshBuffer.beginDraw();
      datamoshBuffer.shader(datamosh);
      datamoshBuffer.image(current, 0, 0);
      datamoshBuffer.endDraw();

      image(datamoshBuffer, 0, 0);
    }
    catch(Exception e) {
      e.printStackTrace();
    }

    previous.beginDraw();
    previous.image(datamoshBuffer, 0, 0, previous.width, previous.height);
    //previous.image(current, 0, 0, previous.width, previous.height);
    previous.endDraw();
    pt.display(0, 0);
  }
}

void keyPressed() {
  if (key == 'r') {
    type = !type;
    try {
      if (type) {
        datamosh = loadShader(file2+".glsl");
      } else {
        datamosh = loadShader(file1+".glsl");
      }
      datamosh.set("resolution", (float)width, (float)height);
      println("shader reload");
    }
    catch(Exception e) {
      e.printStackTrace();
    }
  }
}
