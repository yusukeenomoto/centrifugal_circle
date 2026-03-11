int numParticles = 15000; // 円を小さくする代わりに数を大幅に増やす
Particle[] particles;
float time = 0;

void settings() {
  // 1280x1920 の画面サイズ
  size(1280, 1920, P2D);
}

void setup() {
  background(0);
  particles = new Particle[numParticles];
  for (int i = 0; i < numParticles; i++) {
    particles[i] = new Particle();
    // 初期状態から画面内に煙が存在するよう、時間を進めておく
    for(int j = 0; j < random(100, 500); j++) {
      particles[i].update();
    }
  }
}

void draw() {
  // 軌跡を残すための半透明の黒。値が小さいほど長く残る
  // 今回は「もや」の質感を出すため、少し濃いめにして軌跡より「塊」を強調する
  fill(0, 6); 
  noStroke();
  rect(0, 0, width, height);

  for (Particle p : particles) {
    p.update();
    p.show();
  }
  
  time += 0.001; // 流体の流れが変化する速度
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    time = 0;
    setup();
  }
}

class Particle {
  PVector pos;
  PVector vel;
  float life;
  float maxLife;
  float size;
  float maxSpeed;

  Particle() {
    pos = new PVector();
    vel = new PVector();
    reset();
  }

  void reset() {
    // 画面下部の中央付近から、もやのようにランダムに発生させる
    float r = random(0, 300);
    float t = random(TWO_PI);
    pos.x = width / 2 + r * cos(t);
    pos.y = height + random(50, 400); // 画面の少し下から発生
    
    // 初期は上に向かって進む
    vel.set(0, random(-3.0, -1.0));
    
    maxLife = random(400, 1200);
    life = maxLife;
    size = random(5, 25); // 円のサイズを小さくして、数を増やすことで滑らかにする
    maxSpeed = random(0.8, 2.5);
  }

  void update() {
    // 【流体のような大きなうねり】
    // パーリンノイズを使って、空間全体に流れる「風の向き」を計算する
    float nX = noise(pos.x * 0.0015, pos.y * 0.0015, time);
    float nY = noise(pos.x * 0.0015 + 1000, pos.y * 0.0015 + 1000, time);
    
    // ノイズから角度を作り、うねる力を計算
    float angle = nX * TWO_PI * 4;
    PVector force = PVector.fromAngle(angle);
    force.mult(0.04); // 乱気流の強さ
    
    // 常に上に向かう浮力（熱で昇る表現）
    force.y -= 0.02;
    
    // 煙が画面端に散りすぎないよう、中央へ向かうかすかな引力を足す
    float centerDist = width / 2 - pos.x;
    force.x += centerDist * 0.00003;

    boolean interacted = false;

    // ---【アイデア1: インタラクション（煙をかき混ぜる）】---
    if (mousePressed) {
      // マウスとパーティクルの距離を計算
      float d = dist(mouseX, mouseY, pos.x, pos.y);
      float effectRadius = 150; // かき混ぜる影響範囲
      
      if (d < effectRadius) {
        interacted = true;
        
        // マウスの移動量（ベクトル）を大きく取る
        PVector mouseVel = new PVector(mouseX - pmouseX, mouseY - pmouseY);
        mouseVel.limit(30); // 制限を大幅に緩和して激しい動きを許可
        
        // 距離が近いほど強く影響を受ける（力を大幅に強化）
        float dragForce = map(d, 0, effectRadius, 0.4, 0); 
        mouseVel.mult(dragForce);
        
        // 周囲をぐるっと回る「渦（スワール）」の力も強化
        PVector swirl = new PVector(-(pos.y - mouseY), pos.x - mouseX);
        swirl.normalize();
        float swirlForce = map(d, 0, effectRadius, 0.8, 0); // 渦を強力に
        swirl.mult(swirlForce);
        
        // 外側に押し出す弾きの力
        // ドラッグ時に煙がついてきやすくなるよう、弾く力を少し弱めに調整
        PVector push = PVector.sub(pos, new PVector(mouseX, mouseY));
        push.normalize();
        push.mult(dragForce * 0.5); 
        
        // 算出された複数の力を合成して加算
        force.add(mouseVel);
        force.add(swirl);
        force.add(push);
      }
    }
    // -----------------------------------------------------------

    vel.add(force);
    
    // 【修正点】厳格な速度制限を緩和し、ドラッグ時の勢いを残す
    if (interacted) {
      // インタラクション中は上限を開放し、マウスについてこれるようにする
      vel.limit(30);
    } else {
      // インタラクション後は慣性を残しつつ、空気抵抗のように徐々に元の速度上限(maxSpeed)へ戻す
      if (vel.magSq() > maxSpeed * maxSpeed) {
        vel.mult(0.92); // 慣性による滑らかな減速
      } else {
        vel.limit(maxSpeed);
      }
    }
    
    pos.add(vel);
    
    life--;
    
    // 煙が空気に溶け込んでいくように、徐々にサイズを膨張させる
    size += 0.05;
    
    // 寿命が尽きるか、完全に画面から消えたらリセット
    if (life <= 0 || pos.y < -200 || pos.x < -300 || pos.x > width + 300) {
      reset();
      // 連続して煙が出るように、画面下部から再スタート
      pos.y = height + random(10, 100);
    }
  }

  void show() {
    // 発生時は透明から始まり、ふんわりと現れて、最後は再び透明になって消える
    // ( sin の 0〜PI カーブを利用して滑らかにフェードイン・フェードアウト )
    float fade = sin(map(life, 0, maxLife, 0, PI));
    
    // 非常に低い透明度の小さな円をさらに無数に重ねることで、モクモクとした立体感を出す
    float alpha = fade * 2.5; 
    
    noStroke();
    fill(255, alpha);
    ellipse(pos.x, pos.y, size, size);
  }
}
