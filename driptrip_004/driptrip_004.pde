float camT = 0;
boolean isDrawing = false;
int startTime = 0; // 描画開始時間を記録する変数
float currentSpeed = 20; // カメラの移動スピード

void setup() {
  size(1280, 1920);
  background(0);
  frameRate(60);
}

void draw() {
  // 毎フレーム背景をクリア
  background(0);
  
  if (!isDrawing) {
    return; // 初期画面は真っ黒のままにする
  }
  
  if (isDrawing) {
    // 45秒（45000ミリ秒）経過したかチェック
    if (millis() - startTime >= 45000) {
      isDrawing = false;
      camT = 0;             // 位置を初期化
      currentSpeed = 20;    // スピードを初期化
      return;               // 描画せずに終了して黒画面に戻す
    }
    camT += currentSpeed; // トンネルを前進・後退する
  }
  
  // カメラの現在の理論上の位置
  float camX = getPathX(camT);
  float camY = getPathY(camT);
  
  // ジェットコースターの傾きをシミュレートするためのカメラの回転を計算
  float turn = getPathX(camT + 10) - getPathX(camT);
  float camTilt = turn * 0.04;
  
  pushMatrix();
  // 全体のビューを回転させて頭の傾きをシミュレート
  translate(width/2, height/2);
  rotate(-camTilt);
  translate(-width/2, -height/2);
  
  // カメラの位置に合わせて動的にリングを生成し、奥から手前へ描画
  float startT = floor(camT / 20.0f) * 20.0f;
  for (float t = startT + 2500; t >= startT; t -= 20) {
    Ring r = new Ring(t);
    r.display(camX, camY, camT);
  }
  
  popMatrix();
}

void mouseMoved() {
  if (!isDrawing) {
    isDrawing = true;
    startTime = millis(); // 描画開始時に時間を記録
  }
}

void mousePressed() {
  if (!isDrawing) return;
  
  // 画面の中心を基準としたクリック位置の相対座標
  float dx = mouseX - width / 2.0;
  float dy = mouseY - height / 2.0;
  
  // 対角線を境界として画面を4分割し、クリック位置を判定する
  if (abs(dx) > abs(dy)) {
    if (dx < 0) {
      // 左部をクリック：スピードアップ
      changeSpeed(10);
    } else {
      // 右部をクリック：スピードダウン
      changeSpeed(-10);
    }
  } else {
    if (dy < 0) {
      // 上部をクリック：上矢印キーと同様にスピードアップ
      changeSpeed(10);
    } else {
      // 下部をクリック：下矢印キーと同様にスピードダウン
      changeSpeed(-10);
    }
  }
}

// 蛇行するXの軌道を生成する関数
float getPathX(float t) {
  return sin(t * 0.001) * 400 + sin(t * 0.002) * 200 + sin(t * 0.0005) * 300;
}

// 波打つYの軌道を生成する関数
float getPathY(float t) {
  return cos(t * 0.0008) * 300 + sin(t * 0.0016) * 150 + cos(t * 0.0004) * 200;
}

// スピードを変更する関数を追加
void changeSpeed(float delta) {
  currentSpeed += delta;
  println("Speed: " + currentSpeed);
}

class Ring {
  float t;
  
  Ring(float _t) {
    t = _t;
  }
  
  void display(float camX, float camY, float camT) {
    // 相対距離の計算
    float z = t - camT;
    
    // カメラの背後にある場合は描画しない
    if (z <= 1) return;
    
    float pathX = getPathX(t);
    float pathY = getPathY(t);
    
    // 基本的な遠近法のための深度スケーリング係数
    float scale = 800.0 / z;
    
    // 実際の空間からパースペクティブな画面座標への変換
    float px = (pathX - camX) * scale + width/2;
    float py = (pathY - camY) * scale + height/2;
    float pd = 400 * scale; 
    
    noFill();
    stroke(100);
    strokeWeight(1);
    circle(px, py, pd);
    
    // 一定間隔で外側のフレームを追加
    if (Math.round(t) % 100 == 0) {
      circle(px, py, pd * 1.2);
    }
    
    // トラックの細部がカーブに沿ってきれいに回り込むようにするための局所的な傾き
    float localTurn = getPathX(t + 10) - getPathX(t);
    float ringTilt = localTurn * 0.04;
    
    // 小さな円を装飾（レールやライトのようなもの）として追加し、リング上に完全にマッピングする
    float r = pd / 2;
    for (int i = 0; i < 6; i++) {
        float angle = ringTilt + i * TWO_PI / 6.0;
        float cx = px + cos(angle) * r;
        float cy = py + sin(angle) * r;
        float railD = 15 * scale; 
        circle(cx, cy, railD); // 小さな円だけで表現される詳細構造
    }
  }
  
  boolean isDone(float camT) {
    // リングがカメラの背後にあるかどうかを確認
    return t < camT;
  }
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    // タイムスタンプを使ってユニークなファイル名で保存
    String filename = "capture_" + year() + nf(month(), 2) + nf(day(), 2) + "_" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2) + ".png";
    save(filename);
    println("Saved capture: " + filename);
  } else if (keyCode == UP) {
    // 上矢印キーでスピードアップ
    changeSpeed(10);
  } else if (keyCode == DOWN) {
    // 下矢印キーでスピードダウン
    changeSpeed(-10);
  }
}
