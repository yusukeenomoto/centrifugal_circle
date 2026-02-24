/**
 * ephemeral_bubbles.pde - "Ephemeral Bubbles"
 * Motif: Small Bubbles
 * A generative art piece featuring rising, glowing bubbles that respond to flow fields and mouse interaction.
 */

int numBubbles = 600;
ArrayList<Bubble> bubbles;
float noiseOffset = 0;

// Color Palette
color bgColor = color(0); // Monochrome background

void setup() {
  size(1080, 1920, P2D);
  smooth(8);
  bubbles = new ArrayList<Bubble>();
  for (int i = 0; i < numBubbles; i++) {
    float a = random(TWO_PI);
    float r = random(max(width, height));
    bubbles.add(new Bubble(width/2 + r * cos(a), height/2 + r * sin(a)));
  }
}

void draw() {
  // Deep underwater gradient/fade
  noStroke();
  fill(red(bgColor), green(bgColor), blue(bgColor), 25);
  rect(0, 0, width, height);

  // Update and show bubbles
  for (int i = bubbles.size() - 1; i >= 0; i--) {
    Bubble b = bubbles.get(i);
    b.update();
    b.display();
    
    // Reset bubble if it goes off screen
    if (b.pos.x < -100 || b.pos.x > width + 100 || b.pos.y < -100 || b.pos.y > height + 100) {
      bubbles.remove(i);
      bubbles.add(new Bubble(width/2 + random(-20, 20), height/2 + random(-20, 20)));
    }
  }

  noiseOffset += 0.005;
}

// Light rays removed as per instruction

class Bubble {
  PVector pos;
  PVector vel;
  float size;
  float originalSize;
  color c;
  float alpha;
  float noiseShift;
  float wobble;

  Bubble(float x, float y) {
    pos = new PVector(x, y);
    originalSize = random(2, 60); // Increased size variation
    size = originalSize;
    
    // Calculate outward velocity from center
    PVector center = new PVector(width/2, height/2);
    PVector dir = PVector.sub(pos, center);
    if (dir.mag() == 0) {
      dir = PVector.random2D();
    }
    dir.normalize();
    vel = dir.mult(random(0.5, 3.5));
    
    c = color(255); // Monochrome (white)
    alpha = random(50, 255); // Vary alpha for depth
    noiseShift = random(1000);
    wobble = random(TWO_PI);
  }

  void update() {
    // Outward motion with noise drift
    float driftX = map(noise(pos.x * 0.005, noiseOffset + noiseShift), 0, 1, -1, 1);
    float driftY = map(noise(pos.y * 0.005, noiseOffset + noiseShift + 100), 0, 1, -1, 1);
    pos.x += driftX + vel.x;
    pos.y += driftY + vel.y;

    // Mouse interaction - repel
    float d = dist(mouseX, mouseY, pos.x, pos.y);
    if (d < 150) {
      PVector repel = PVector.sub(pos, new PVector(mouseX, mouseY));
      repel.normalize();
      float force = map(d, 0, 150, 3, 0);
      pos.add(PVector.mult(repel, force));
    }

    // Gentle size pulsing (breathing)
    wobble += 0.05;
    size = originalSize + sin(wobble) * 2;
  }

  void display() {
    // Hide circles within 150px of mouse when mouse is pressed
    if (mousePressed && dist(mouseX, mouseY, pos.x, pos.y) < 150) {
      return;
    }

    pushMatrix();
    translate(pos.x, pos.y);
    
    // Simple circle
    noFill();
    stroke(c, alpha);
    strokeWeight(1.5);
    ellipse(0, 0, size, size);

    popMatrix();
  }
}

// Mouse click handler removed in favor of dynamic hiding in display()
