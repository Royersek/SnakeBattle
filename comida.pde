//==================== TIPOS DE COMIDA ====================
final int TIPO_NORMAL      = 0;
final int TIPO_RAPIDEZ     = 1;
final int TIPO_TRANSPARENTE= 2;
final int TIPO_DOBLE       = 3;
final int TIPO_IMAN        = 4;

class Comida {
  int x, y;
  int tam;
  int tipo = TIPO_NORMAL;
  float pulso = 0;

  int contadorComidas = 0;
  final float PROB_POWERUP = 0.35;
  final int MAX_COMIDAS_SEGUIDAS = 2;

  Comida(int tamano) {
    tam = tamano;
  }

  void generarNueva() {
    boolean forzarPowerup = (contadorComidas >= MAX_COMIDAS_SEGUIDAS);
    if (forzarPowerup || random(1) < PROB_POWERUP) {
      tipo = tipoPowerUpAleatorio();
      contadorComidas = 0;
    } else {
      tipo = TIPO_NORMAL;
      contadorComidas++;
    }

    // Buscar posición válida (no sobre las serpientes ni obstáculos)
    for (int intento = 0; intento < 100; intento++) {
      int nx = (int)random(0, MUNDO_ANCHO/tam) * tam;
      int ny = (int)random(0, MUNDO_ALTO/tam) * tam;
      boolean choca = false;

      for (PVector seg : p1.cuerpo) {
        if (seg.x == nx && seg.y == ny) { choca = true; break; }
      }
      if (!choca && dosJugadores()) {
        for (PVector seg : p2.cuerpo) {
          if (seg.x == nx && seg.y == ny) { choca = true; break; }
        }
      }
      if (!choca) {
        for (Obstaculo o : obstaculos) {
          if (abs(o.posicion.x - nx) < tam && abs(o.posicion.y - ny) < tam) {
            choca = true; break;
          }
        }
      }
      if (!choca) {
        x = nx; y = ny;
        return;
      }
    }
    // Fallback
    x = (int)random(0, MUNDO_ANCHO/tam) * tam;
    y = (int)random(0, MUNDO_ALTO/tam) * tam;
  }

  int tipoPowerUpAleatorio() {
    int[] t = { TIPO_RAPIDEZ, TIPO_TRANSPARENTE, TIPO_DOBLE, TIPO_IMAN };
    return t[(int)random(t.length)];
  }

  void actualizar() {
    pulso += 0.15;
  }

  void dibujar() {
    imageMode(CORNER);
    if (tipo == TIPO_NORMAL) {
      if (imgComida != null) {
        image(imgComida, x, y, tam, tam);
      } else {
        fill(255, 60, 60); noStroke();
        ellipse(x + tam/2, y + tam/2, tam, tam);
      }
    } else {

      float r = tam * 1.7 + sin(pulso) * 6;
      float offset = (tam - r) / 2.0;

      PImage img = null;
      if (tipo == TIPO_RAPIDEZ)      img = imgVelocidad;
      if (tipo == TIPO_TRANSPARENTE) img = imgTransparencia;
      if (tipo == TIPO_DOBLE)        img = imgDoblePuntos;
      if (tipo == TIPO_IMAN)         img = imgIman;

      
      noStroke();
      fill(red(colorDelTipo()), green(colorDelTipo()), blue(colorDelTipo()), 35);
      ellipse(x + tam/2, y + tam/2, r * 1.4, r * 1.4);

      if (img != null) {
        image(img, x + offset, y + offset, r, r);
      } else {
        fill(colorDelTipo()); noStroke();
        ellipse(x + tam/2, y + tam/2, r, r);
      }
    }
  }

  color colorDelTipo() {
    switch (tipo) {
      case TIPO_RAPIDEZ:      return color(255, 220, 0);
      case TIPO_TRANSPARENTE: return color(100, 200, 255);
      case TIPO_DOBLE:        return color(255, 180, 0);
      case TIPO_IMAN:         return color(200, 100, 255);
      default:                return color(255, 60, 60);
    }
  }
}
