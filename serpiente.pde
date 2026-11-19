class Serpiente {
  // 🎯 REFACTORIZADO: ArrayList dinámica + PVector
  ArrayList<PVector> cuerpo;
  PVector direccion;
  PVector nextDireccion;
  boolean hayCambioDir;
  PVector posicion;   // atajo a la cabeza
  int puntos;
  boolean muerta;
  color colorCabeza;
  color colorCuerpo;
  int tam;

  // Buffs
  int tsRapidez      = -999999;
  int tsTransparente = -999999;
  int tsDoble        = -999999;
  int tsIman         = -999999;
  final int DUR_RAPIDEZ      = 4000;
  final int DUR_TRANSPARENTE = 4000;
  final int DUR_DOBLE        = 10000;
  final int DUR_IMAN         = 8000;

  Serpiente(float xIni, float yIni, int dX, int dY,
            color cCab, color cCuer, int tamano) {
    cuerpo = new ArrayList<PVector>();
    direccion     = new PVector(dX, dY);
    nextDireccion = new PVector(dX, dY);
    tam = tamano;
    colorCabeza = cCab;
    colorCuerpo = cCuer;
    reset(xIni, yIni, dX, dY);
  }

  void reset(float xIni, float yIni, int dX, int dY) {
    cuerpo.clear();
    puntos = 0;
    muerta = false;
    direccion.set(dX, dY);
    nextDireccion.set(dX, dY);
    hayCambioDir = false;
    tsRapidez = tsTransparente = tsDoble = tsIman = -999999;

    // Segmentos iniciales
    for (int i = 0; i < 3; i++) {
      cuerpo.add(new PVector(xIni - i * dX * tam,
                             yIni - i * dY * tam));
    }
    posicion = cuerpo.get(0);
  }

  boolean buffActivo(int ts, int dur) {
    return (millis() - ts) < dur;
  }

  boolean esTransparente() {
    return buffActivo(tsTransparente, DUR_TRANSPARENTE);
  }

  void actualizar(Comida comida) {
    if (muerta) return;

    int pasos = buffActivo(tsRapidez, DUR_RAPIDEZ) ? 2 : 1;
    for (int s = 0; s < pasos && !muerta; s++) {
      if (s == 0 && hayCambioDir) {
        direccion.set(nextDireccion);
        hayCambioDir = false;
      }

      // 🎯 Movimiento con PVector
      PVector cabeza = cuerpo.get(0).copy();
      cabeza.add(direccion.x * tam, direccion.y * tam, 0);

      cuerpo.add(0, cabeza.copy());
      PVector colaAnterior = cuerpo.remove(cuerpo.size() - 1);
      posicion = cuerpo.get(0);

      // Colisión con bordes
      if (cabeza.x < 0 || cabeza.x >= MUNDO_ANCHO ||
          cabeza.y < 0 || cabeza.y >= MUNDO_ALTO) {
        muerta = true;
        reproducirSonido(soundMorir);
        emitirParticulas(cabeza.x, cabeza.y, color(255, 60, 60), 60);
        return;
      }

      // Colisión con uno mismo
      if (!esTransparente()) {
        for (int i = 1; i < cuerpo.size(); i++) {
          PVector seg = cuerpo.get(i);
          if (cabeza.x == seg.x && cabeza.y == seg.y) {
            muerta = true;
            reproducirSonido(soundMorir);
            emitirParticulas(cabeza.x, cabeza.y, color(255, 60, 60), 60);
            return;
          }
        }
      }

      // ¿Comió?
      if (cabeza.x == comida.x && cabeza.y == comida.y) {
        consumirComida(comida);
        cuerpo.set(cuerpo.size()-1, colaAnterior);
      }
      comprobarObstaculos(this);
    }
  }

  void consumirComida(Comida comida) {
    int puntosBase = buffActivo(tsDoble, DUR_DOBLE) ? 20 : 10;

    // 🎯 Al comer, NO removemos la cola → la serpiente crece
    cuerpo.add(cuerpo.get(cuerpo.size() - 1).copy());

    switch (comida.tipo) {
      case TIPO_NORMAL:
        puntos += puntosBase;
        break;
      case TIPO_RAPIDEZ:
        tsRapidez = millis();
        puntos += puntosBase / 2;
        break;
      case TIPO_TRANSPARENTE:
        tsTransparente = millis();
        puntos += puntosBase / 2;
        break;
      case TIPO_DOBLE:
        tsDoble = millis();
        puntos += puntosBase / 2;
        break;
      case TIPO_IMAN:
        tsIman = millis();
        puntos += puntosBase / 2;
        break;
    }

    // 🎯 Partículas al comer
    emitirParticulas(comida.x + tam/2, comida.y + tam/2,
                     comida.colorDelTipo(), 20);

    reproducirSonido(soundComer);
    comida.generarNueva();
  }

  void aplicarIman(Comida comida) {
    if (!buffActivo(tsIman, DUR_IMAN)) return;
    float dx = posicion.x - comida.x;
    float dy = posicion.y - comida.y;
    float d = sqrt(dx*dx + dy*dy);
    float radio = 375;
    if (d < radio && d > 5) {
      if (abs(dx) >= abs(dy)) comida.x += dx > 0 ? tam : -tam;
      else comida.y += dy > 0 ? tam : -tam;
      comida.x = constrain(comida.x, 0, MUNDO_ANCHO - tam);
      comida.y = constrain(comida.y, 0, MUNDO_ALTO - tam);
      if (comida.x == posicion.x && comida.y == posicion.y) consumirComida(comida);
    }
  }

    void verificarColisionCon(Serpiente otra) {
    if (muerta || otra.muerta) return;
    if (esTransparente() || otra.esTransparente()) return;
    
    PVector cabeza = cuerpo.get(0);
    for (int i = 0; i < otra.cuerpo.size(); i++) {
      PVector seg = otra.cuerpo.get(i);
      if (cabeza.x == seg.x && cabeza.y == seg.y) {
        
        this.morir();          // La que chocó muere
        otra.puntos += 20;     // 🆕 La que sobrevivió (la otra) gana 20 puntos
        
        break;
      }
    }
  }
  void morir() {
    if (muerta) return;
    muerta = true;
    reproducirSonido(soundMorir);
    emitirParticulas(posicion.x, posicion.y, color(255,60,60),60);
  }

  void reproducirSonido(AudioPlayer sonido) {
    if (sonido != null) {
      sonido.rewind();
      sonido.play();
    }
  }

  void cambiarDireccion(int dX, int dY) {
    if (hayCambioDir) return;
    if (direccion.x + dX == 0 && direccion.y + dY == 0) return;
    if (dX == direccion.x && dY == direccion.y) return;
    nextDireccion.set(dX, dY);
    hayCambioDir = true;
  }

  void dibujar() {
    if (muerta) return;
    boolean transparente = esTransparente();
    for (int i = 0; i < cuerpo.size(); i++) {
      PVector seg = cuerpo.get(i);
      color base = (i == 0) ? colorCabeza : colorCuerpo;
      if (transparente) {
        float alpha = 100 + sin(millis() * 0.01) * 50;
        base = color(red(base), green(base), blue(base), alpha);
      }
      fill(base);
      stroke(15);
      rect(seg.x, seg.y, tam, tam, 5);
    }
    noStroke();
    if (buffActivo(tsIman, DUR_IMAN)) {
      noFill();
      stroke(200, 100, 255, 90);
      strokeWeight(2);
      float r = 375 * 2;
      ellipse(posicion.x + tam/2, posicion.y + tam/2, r, r);
      noStroke();
    }
  }
}
