class Obstaculo {
  PVector posicion;
  PVector velocidad;
  float tam;
  color c;
  float pulso = 0;

  Obstaculo(float x, float y, float vx, float vy) {
    posicion = new PVector(x, y);
    velocidad = new PVector(vx, vy);
    tam = 30;
    c = color(255, 60, 100);
  }

  void actualizar() {
    posicion.add(velocidad);
    // Rebota en las paredes del mundo
    if (posicion.x < 0) { posicion.x = 0; velocidad.x *= -1; }
    if (posicion.x > MUNDO_ANCHO - tam) { posicion.x = MUNDO_ANCHO - tam; velocidad.x *= -1; }
    if (posicion.y < 0) { posicion.y = 0; velocidad.y *= -1; }
    if (posicion.y > MUNDO_ALTO - tam) { posicion.y = MUNDO_ALTO - tam; velocidad.y *= -1; }
    pulso += 0.1;
  }

  void dibujar() {
    float glow = 8 + sin(pulso) * 3;
    // Aura neón
    noStroke();
    fill(255, 60, 100, 40);
    rect(posicion.x - glow, posicion.y - glow, tam + glow*2, tam + glow*2, 6);
    // Cuerpo
    fill(c);
    stroke(255, 150, 180);
    strokeWeight(2);
    rect(posicion.x, posicion.y, tam, tam, 4);
    noStroke();
  }

  boolean colisionaCon(Serpiente s) {
    if (s.esTransparente()) return false;
    PVector cabeza = s.cuerpo.get(0);
    return cabeza.x < posicion.x + tam && cabeza.x + s.tam > posicion.x &&
           cabeza.y < posicion.y + tam && cabeza.y + s.tam > posicion.y;
  }
}
