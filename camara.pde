//==================== VARIABLES DE CÁMARA ====================
float camX, camY;
float camZoom = 1.0;
float camZoomTarget = 1.0;

// 
final float CAM_ZOOM_MAX = 1.60;   // Inicio (0 pts): Zoom ACERCADO. Ves poco mapa, serpiente grande.
final float CAM_ZOOM_MIN = 0.60;   // Final (500+ pts): Zoom ALEJADO. Ves mucho más mapa.
final float CAM_ZOOM_MIN_VERSUS = 0.45; // Versus: permite alejarse más para ver a ambos jugadores.

final float CAM_LERP = 0.12;       // Suavizado del movimiento de cámara (un poco más lento para que se note el crecimiento)
final float CAM_ZOOM_LERP = 0.04;  // Suavizado del zoom (cambio gradual y elegante)
final float CAM_VERSUS_MARGEN = 350;

void resetCamara() {
  if (dosJugadores()) {
    camX = (p1.posicion.x + p2.posicion.x) / 2.0 + tam/2.0;
    camY = (p1.posicion.y + p2.posicion.y) / 2.0 + tam/2.0;
    camZoom = 0.80; 
  } else {
    camX = p1.posicion.x + tam/2.0;
    camY = p1.posicion.y + tam/2.0;
    camZoom = CAM_ZOOM_MAX; 
  }
  camZoomTarget = camZoom;
}

void actualizarCamara() {
  if (dosJugadores() && !p1.muerta && !p2.muerta) {
    actualizarCamaraVersus();
  } else {
    Serpiente foco = p1;
    if (dosJugadores() && p1.muerta && !p2.muerta) foco = p2;
    actualizarCamaraFoco(foco);
  }
}

void aplicarClampCamara(float targetX, float targetY) {
  float visW = width / camZoom;
  float visH = height / camZoom;
  float minCamX = visW / 2;
  float maxCamX = MUNDO_ANCHO - visW / 2;
  if (minCamX > maxCamX) {
    camX = lerp(camX, MUNDO_ANCHO/2.0, CAM_LERP);
  } else {
    camX = lerp(camX, targetX, CAM_LERP);
    camX = constrain(camX, minCamX, maxCamX);
  }
  float minCamY = visH / 2;
  float maxCamY = MUNDO_ALTO - visH / 2;
  if (minCamY > maxCamY) {
    camY = lerp(camY, MUNDO_ALTO/2.0, CAM_LERP);
  } else {
    camY = lerp(camY, targetY, CAM_LERP);
    camY = constrain(camY, minCamY, maxCamY);
  }
}

void actualizarCamaraFoco(Serpiente foco) {
  float targetX = foco.posicion.x + tam/2.0;
  float targetY = foco.posicion.y + tam/2.0;
  
  // 🆕 A medida que suben los puntos (0 a 500), el zoom baja de 1.35 a 0.60 (se aleja)
  camZoomTarget = map(foco.puntos, 0, 500, CAM_ZOOM_MAX, CAM_ZOOM_MIN);
  camZoomTarget = constrain(camZoomTarget, CAM_ZOOM_MIN, CAM_ZOOM_MAX);
  
  camZoom = lerp(camZoom, camZoomTarget, CAM_ZOOM_LERP);
  aplicarClampCamara(targetX, targetY);
}

void actualizarCamaraVersus() {
  float midX = (p1.posicion.x + p2.posicion.x) / 2.0 + tam/2.0;
  float midY = (p1.posicion.y + p2.posicion.y) / 2.0 + tam/2.0;
  float dx = abs(p1.posicion.x - p2.posicion.x);
  float dy = abs(p1.posicion.y - p2.posicion.y);
  float necesarioW = dx + CAM_VERSUS_MARGEN * 2;
  float necesarioH = dy + CAM_VERSUS_MARGEN * 2;
  float targetZoom = min(width / necesarioW, height / necesarioH);
  targetZoom = constrain(targetZoom, CAM_ZOOM_MIN_VERSUS, CAM_ZOOM_MAX);
  camZoomTarget = targetZoom;
  camZoom = lerp(camZoom, camZoomTarget, CAM_ZOOM_LERP);
  aplicarClampCamara(midX, midY);
}

void aplicarCamara() {
  translate(width/2, height/2);
  scale(camZoom);
  translate(-camX, -camY);
}

//==FONDO NEÓN
void dibujarGrid() {
  float visW = width / camZoom;
  float visH = height / camZoom;
  float startX = max(camX - visW/2, 0);
  float endX   = min(camX + visW/2, MUNDO_ANCHO);
  float startY = max(camY - visH/2, 0);
  float endY   = min(camY + visH/2, MUNDO_ALTO);
  if (startX >= endX || startY >= endY) return;

  int step = 90;
  float gx0 = ceil(startX/step) * step;
  float gy0 = ceil(startY/step) * step;

  stroke(0, 200, 255, 10); strokeWeight(7);
  for (float x = gx0; x <= endX; x += step) line(x, startY, x, endY);
  for (float y = gy0; y <= endY; y += step) line(startX, y, endX, y);

  stroke(120, 220, 255, 55); strokeWeight(1.5);
  for (float x = gx0; x <= endX; x += step) line(x, startY, x, endY);
  for (float y = gy0; y <= endY; y += step) line(startX, y, endX, y);

  noStroke(); fill(180, 240, 255, 110);
  for (float x = gx0; x <= endX; x += step) {
    for (float y = gy0; y <= endY; y += step) {
      ellipse(x, y, 3.5, 3.5);
    }
  }
}

void dibujarLimitesMundo() {
  noFill();
  stroke(80, 140, 220, 160); strokeWeight(5);
  rect(0, 0, MUNDO_ANCHO, MUNDO_ALTO);
  noStroke();
}

void dibujarVignette() {
  noStroke();
  int bands = 16;
  float depth = 150;
  float bandH = depth / bands;
  for (int i = 0; i < bands; i++) {
    float a = map(i, 0, bands, 110, 0);
    fill(0, 0, 12, a);
    float y = i * bandH;
    rect(0, y, width, bandH + 1);
    rect(0, height - y - bandH, width, bandH + 1);
    rect(y, 0, bandH + 1, height);
    rect(width - y - bandH, 0, bandH + 1, height);
  }
}
