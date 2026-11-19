class Particula {
  PVector posicion;
  PVector velocidad;
  float vida;
  float vidaMax;
  color c;
  float tam;

  Particula(PVector pos, PVector vel, color c, float vida, float tam) {
    this.posicion = pos.copy();
    this.velocidad = vel.copy();
    this.c = c;
    this.vida = vida;
    this.vidaMax = vida;
    this.tam = tam;
  }

  void actualizar() {
    posicion.add(velocidad);
    velocidad.mult(0.95);  // fricción
    vida--;
  }

  void dibujar() {
    float alpha = map(vida, 0, vidaMax, 0, 255);
    noStroke();
    fill(red(c), green(c), blue(c), alpha);
    ellipse(posicion.x, posicion.y, tam, tam);
  }

  boolean murio() {
    return vida <= 0;
  }
}
