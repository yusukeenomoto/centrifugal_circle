int numParticles = 10000;
Particle[] particles;
float centerX, centerY;
float baseRadius = 600;
float time = 0;
float globalRotation = 0;

// --- Display Size ---
int displayW = 1080; 
int displayH = 1920;
// -----------------------------

boolean isInverted = false; // false: Black on White, true: White on Black

void settings() {
  size(displayW, displayH, P2D);
}

void setup() {
  centerX = width / 2;
  centerY = height / 2;
  background(isInverted ? 0 : 255);
  initParticles(numParticles);
}

void initParticles(int count) {
  particles = new Particle[count];
  for (int i = 0; i < count; i++) {
    float angle = random(TWO_PI);
    float r = pow(random(1), 0.7) * baseRadius;
    particles[i] = new Particle(r, angle);
  }
}

void draw() {
  // 背景色とフェードの設定
  fill(isInverted ? 0 : 255, 30); 
  noStroke();
  rect(0, 0, width, height);

  float mouseNoiseScale = map(mouseX, 0, width, 0.001, 0.02);
  float mouseForceLimit = map(mouseY, 0, height, 3, 15);

  for (Particle p : particles) {
    p.update(mouseNoiseScale, mouseForceLimit, mousePressed);
    p.show();
  }

  globalRotation += 0.008;
  time += 0.01;
}

void keyPressed() {
  if (key == 'i' || key == 'I') {
    isInverted = !isInverted;
    // invert background color
    background(isInverted ? 0 : 255);
  }
}

void mousePressed() {
  // Logic handled in draw() and Particle.update()
}


class Particle {
  PVector pos;
  PVector prevPos;
  PVector vel;
  PVector acc;
  float alpha = 250;
  float initialR, initialAngle;
  float individualOrbitSpeed;

  Particle(float r, float a) {
    this.initialR = r;
    this.initialAngle = a;
    this.individualOrbitSpeed = random(0.005, 0.015);
    
    // Calculate initial position based on global rotation
    float x = centerX + initialR * cos(initialAngle + globalRotation);
    float y = centerY + initialR * sin(initialAngle + globalRotation);
    pos = new PVector(x, y);
    prevPos = pos.copy();
    
    vel = new PVector(0, 0);
    acc = new PVector(0, 0);
  }

  void update(float noiseScale, float speedLimit, boolean isImploding) {
    prevPos.set(pos);
    
    // Always calculate target orbit position
    initialAngle += individualOrbitSpeed;
    float targetX = centerX + initialR * cos(initialAngle + globalRotation);
    float targetY = centerY + initialR * sin(initialAngle + globalRotation);
    PVector target = new PVector(targetX, targetY);

    if (isImploding) {
      PVector center = new PVector(centerX, centerY);
      
      // 1. Centripetal Force
      PVector centripetal = PVector.sub(center, pos);
      float d = centripetal.mag();
      centripetal.normalize();
      float pullMag = map(d, 0, width, 4.0, 1.0);
      centripetal.mult(pullMag);
      
      // 2. Strong Orbital Force
      PVector orbit = new PVector(-(pos.y - centerY), pos.x - centerX);
      orbit.normalize();
      float orbitMag = map(speedLimit, 3, 15, 2.0, 7.0);
      orbit.mult(orbitMag);
      
      // 3. Subtle Jitter
      float n = noise(pos.x * noiseScale, pos.y * noiseScale, time);
      PVector jitter = PVector.random2D();
      jitter.mult(n * 2.0);
      
      acc.add(centripetal);
      acc.add(orbit);
      acc.add(jitter);
      
      vel.add(acc);
      vel.limit(speedLimit);
      
      // Fade out at center
      if (d < 15) alpha -= 10;
      else alpha -= 0.5;
    } else {
      // GRADUAL RETURN: Stealth to target orbit
      PVector returnForce = PVector.sub(target, pos);
      float d = returnForce.mag();
      returnForce.normalize();
      
      float steerMag = map(min(d, 200), 0, 200, 0, 1.5);
      returnForce.mult(steerMag);
      acc.add(returnForce);
      
      vel.add(acc);
      vel.mult(0.92); // Damping to prevent orbiting forever
      vel.limit(speedLimit * 1.5);
      
      // Fade back in
      alpha += 5;
    }
    
    pos.add(vel);
    acc.mult(0);
    alpha = constrain(alpha, 0, 250);
  }

  void show() {
    if (alpha > 0) {
      // isInvertedがtrueなら白(255)、falseなら黒(0)で描画
      stroke(isInverted ? 255 : 0, alpha);
      // Use point instead of line to maintain 'particle' look during high speed
      strokeWeight(1.0); 
      point(pos.x, pos.y);
    }
  }
}
