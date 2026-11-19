class AgujeroGusano {
  PVector posicion;
  float radio;
  float rotacion;          // animación de giro
  float pulso;             // animación de "respiración"
  color colorA;            // color del anillo exterior
  color colorB;            // color del anillo interior
  AgujeroGusano pareja;    // el otro extremo al que teletransporta
  boolean activo;

  // tiempo de vida
  int tiempoCreacion;
  int tiempoVida;          // en milisegundos (-1 = permanente)
  boolean permanente;
  float alpha;             // para efecto de desvanecimiento

  AgujeroGusano(float x, float y, float radio, color cA, color cB, boolean permanente) {
    posicion = new PVector(x, y);
    this.radio = radio;
    this.colorA = cA;
    this.colorB = cB;
    this.permanente = permanente;
    rotacion = random(TWO_PI);
    pulso = random(TWO_PI);
    activo = true;
    tiempoCreacion = millis();
    tiempoVida = permanente ? -1 : 3000;  // 3 segundos si no es permanente
    alpha = 255;
  }

  void actualizar() {
    if (!activo) return;

    rotacion += 0.05;
    pulso += 0.08;

    // 🆕 Verificar si debe desaparecer
    if (!permanente && tiempoVida > 0) {
      int tiempoTranscurrido = millis() - tiempoCreacion;
      if (tiempoTranscurrido >= tiempoVida) {
        activo = false;
      } else if (tiempoTranscurrido >= tiempoVida - 1000) {
        // Último segundo: parpadeo de desvanecimiento
        alpha = map(tiempoTranscurrido, tiempoVida - 1000, tiempoVida, 255, 50);
      }
    }
  }

  void dibujar() {
    if (!activo) return;

    pushMatrix();
    translate(posicion.x + radio, posicion.y + radio);

    // Halo exterior difuso
    noStroke();
    fill(red(colorA), green(colorA), blue(colorA), 25 * (alpha/255));
    ellipse(0, 0, radio * 3.2, radio * 3.2);

    rotate(rotacion);

    // Anillo exterior (neón)
    noFill();
    stroke(red(colorA), green(colorA), blue(colorA), 200 * (alpha/255));
    strokeWeight(4);
    ellipse(0, 0, radio * 2, radio * 2);

    // Anillo interior (otro color)
    stroke(red(colorB), green(colorB), blue(colorB), 220 * (alpha/255));
    strokeWeight(2);
    ellipse(0, 0, radio * 1.4, radio * 1.4);

    // Espiral interior (efecto vórtice)
    stroke(255, 255, 255, 180 * (alpha/255));
    strokeWeight(1.5);
    noFill();
    beginShape();
    for (float a = 0; a < TWO_PI * 2; a += 0.2) {
      float r = map(a, 0, TWO_PI * 2, radio * 0.9, 2);
      float px = cos(a + pulso) * r;
      float py = sin(a + pulso) * r;
      vertex(px, py);
    }
    endShape();

    // Centro brillante
    noStroke();
    fill(255, 255, 255, (180 + sin(pulso) * 60) * (alpha/255));
    ellipse(0, 0, 8, 8);

    popMatrix();

    // 🆕 Indicador de tiempo restante (solo para temporales)
    if (!permanente && tiempoVida > 0) {
      int tiempoRestante = tiempoVida - (millis() - tiempoCreacion);
      if (tiempoRestante > 0) {
        float progreso = (float)tiempoRestante / tiempoVida;
        noFill();
        stroke(255, 255, 0, 150);
        strokeWeight(2);
        arc(posicion.x + radio, posicion.y + radio,
            radio * 2.5, radio * 2.5,
            -HALF_PI, -HALF_PI + TWO_PI * progreso);
        noStroke();
      }
    }
  }

  boolean cabezaDentro(PVector cabeza, int tam) {
    if (!activo) return false;
    float cx = cabeza.x + tam / 2.0;
    float cy = cabeza.y + tam / 2.0;
    float dx = cx - (posicion.x + radio);
    float dy = cy - (posicion.y + radio);
    return sqrt(dx * dx + dy * dy) < radio * 0.7;
  }

  boolean expiro() {
    return !activo && !permanente;
  }
}
