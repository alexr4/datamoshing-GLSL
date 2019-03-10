import processing.video.*;

Movie movie;
PGraphics current, previous;
boolean type;
String file1 = "datamosh-1";
String file2 = "datamosh3x3-5x5";
PShader datamosh;
PGraphics datamoshBuffer;

void settings() {
  size(1920, 752, P3D);
}

void setup() {
  movie = new Movie(this, "movieFromCoverr.mp4");
  movie.loop();

  datamosh = loadShader(file1+".glsl");
  datamosh.set("resolution", (float)width, (float)height);

  current = createGraphics(width, height, P2D);
  previous = createGraphics(width, height, P2D);
  datamoshBuffer = createGraphics(width, height, P2D);

  frameRate(30);
}

void draw() {

  if (movie.available()) {
    movie.read(); // Read the new frame from the camera
    current.beginDraw();
    current.image(movie, 0.0, 0.0, width, height);
    current.endDraw();
  }

  if (current != null) {
    try {
      float threshold = noise(millis() * 0.0001, frameCount * 0.01) * 0.15;
      float offsetRGB = noise(frameCount * 0.0125, millis() * 0.005) * 0.005;

      datamosh.set("previous", previous);
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
