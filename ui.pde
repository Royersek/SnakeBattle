//=VARIABLES UI 
float triAnimY = 250;

//== MINIMAPA 

void dibujarMinimapa() {
  int mw = 210, mh = 158; // 🆕 Tamaño x1.5 (antes 140x105)
  
  int margenX = (int)(width * 0.02);
  int margenY = (int)(height * 0.04);
  
  int mx = width - mw - margenX;
  int my = height - mh - margenY;

  // Fondo del minimapa
  noStroke();
  fill(0, 0, 0, 180);
  rect(mx, my, mw, mh, 6);

  // Borde
  stroke(255, 255, 255, 80);
  strokeWeight(1);
  noFill();
  rect(mx, my, mw, mh, 6);
  noStroke();

  // Escala (se recalcula sola con el nuevo tamaño)
  float sx = mw / (float)MUNDO_ANCHO;
  float sy = mh / (float)MUNDO_ALTO;

 
  fill(comida.colorDelTipo());
  ellipse(mx + comida.x * sx, my + comida.y * sy, 6, 6);

  // Jugador 1 (verde)
  fill(0, 255, 150);
  ellipse(mx + p1.posicion.x * sx, my + p1.posicion.y * sy, 7, 7);

  // Jugador 2 (azul)
  if (dosJugadores() && !p2.muerta) {
    fill(0, 150, 255);
    ellipse(mx + p2.posicion.x * sx, my + p2.posicion.y * sy, 7, 7);
  }
}

//==HUD 
void dibujarHUD() {
  fill(255);
  textSize(20);
  textAlign(LEFT, TOP);

  text("P1: " + p1.puntos, 20, 20);
  dibujarBuffs(p1, 20, 48, LEFT);

  if (dosJugadores()) {
    textAlign(RIGHT, TOP);
    text("P2: " + p2.puntos, width - 20, 20);
    dibujarBuffs(p2, width - 20, 48, RIGHT);
  }

  if (modo == MODO_ONLINE) {
    fill(200);
    textAlign(CENTER, TOP);
    textSize(14);
    text(
      red != null && red.host
      ? "Vos: P1 (verde)"
      : "Vos: P2 (azul)",
      width/2, 12
    );
  }

  textAlign(CENTER, CENTER);
}

//==BUFFS 
void dibujarBuffs(Serpiente s, float x, float y, int alineacion) {
  float by = y;
  float iconSize = 20;

  if (s.buffActivo(s.tsRapidez, s.DUR_RAPIDEZ)) {
    dibujarFilaBuff(
      imgVelocidad, s, x, by,
      color(255, 220, 0),
      s.tsRapidez, s.DUR_RAPIDEZ,
      alineacion, iconSize
    );
    by += 24;
  }

  if (s.buffActivo(s.tsTransparente, s.DUR_TRANSPARENTE)) {
    dibujarFilaBuff(
      imgTransparencia, s, x, by,
      color(100, 200, 255),
      s.tsTransparente, s.DUR_TRANSPARENTE,
      alineacion, iconSize
    );
    by += 24;
  }

  if (s.buffActivo(s.tsDoble, s.DUR_DOBLE)) {
    dibujarFilaBuff(
      imgDoblePuntos, s, x, by,
      color(255, 180, 0),
      s.tsDoble, s.DUR_DOBLE,
      alineacion, iconSize
    );
    by += 24;
  }

  if (s.buffActivo(s.tsIman, s.DUR_IMAN)) {
    dibujarFilaBuff(
      imgIman, s, x, by,
      color(200, 100, 255),
      s.tsIman, s.DUR_IMAN,
      alineacion, iconSize
    );
    by += 24;
  }
}

//==================== FILA DE BUFF ====================
void dibujarFilaBuff(
  PImage icono,
  Serpiente s,
  float x,
  float y,
  color c,
  int ts,
  int dur,
  int alineacion,
  float iconSize
) {
  float progreso = 1.0 - (millis() - ts) / (float)dur;
  progreso = constrain(progreso, 0, 1);

  float bw = 80;
  float bh = 6;

  imageMode(CORNER);

  if (alineacion == LEFT) {
    if (icono != null) {
      image(icono, x, y, iconSize, iconSize);
    }
    noStroke();
    fill(red(c), green(c), blue(c), 60);
    rect(
      x + iconSize + 5,
      y + iconSize/2 - bh/2,
      bw, bh, 2
    );
    fill(c);
    rect(
      x + iconSize + 5,
      y + iconSize/2 - bh/2,
      bw * progreso, bh, 2
    );
  } else {
    if (icono != null) {
      image(icono, x - iconSize, y, iconSize, iconSize);
    }
    noStroke();
    fill(red(c), green(c), blue(c), 60);
    rect(
      x - iconSize - 5 - bw,
      y + iconSize/2 - bh/2,
      bw, bh, 2
    );
    fill(c);
    rect(
      x - iconSize - 5 - bw * progreso,
      y + iconSize/2 - bh/2,
      bw * progreso, bh, 2
    );
  }
}

//==================== GAME OVER ====================
void gameOver() {
  if (imgGameOver != null) {
    imageMode(CORNER);
    image(imgGameOver, 0, 0, width, height);
  } else {
    background(10, 10, 15);
    fill(255, 60, 60);
    textSize(55);
    textAlign(CENTER, CENTER);
    text("GAME OVER", width/2, 120);
  }

  // 2. TAMAÑO ADAPTABLE
  int tam = constrain(width / 40, 15, 21);

  // 🆕 COLOR VERDE UNIFICADO PARA TODO EL TEXTO
  color verdeUnico = color(0, 255, 150);

  // 3. MODO UN JUGADOR
  if (modo == MODO_SOLO) {
    textoNeon("PUNTAJE FINAL: " + p1.puntos + " pts", width/2, height * 0.75, verdeUnico, tam);
  } 
  // 4. MODO VERSUS
  else {
    // GANA JUGADOR 1
    if (p1.puntos > p2.puntos) {
      textoNeon("GANADOR: JUGADOR 1 - " + p1.puntos + " pts", width/2, height * 0.70, verdeUnico, tam);
      textoNeon("JUGADOR 2 - " + p2.puntos + " pts", width/2, height * 0.76, verdeUnico, tam);
    }
    // GANA JUGADOR 2
    else if (p2.puntos > p1.puntos) {
      textoNeon("GANADOR: JUGADOR 2 - " + p2.puntos + " pts", width/2, height * 0.70, verdeUnico, tam);
      textoNeon("JUGADOR 1 - " + p1.puntos + " pts", width/2, height * 0.76, verdeUnico, tam);
    }
    // EMPATE
    else {
      textoNeon("¡EMPATE!", width/2, height * 0.67, verdeUnico, tam);
      textoNeon("JUGADOR 1: " + p1.puntos + " pts", width/2, height * 0.72, verdeUnico, tam);
      textoNeon("JUGADOR 2: " + p2.puntos + " pts", width/2, height * 0.77, verdeUnico, tam);
    }
  }
}

//==================== TEXTO NEÓN (LIMPIO, SIN SOMBREADO) ====================
void textoNeon(String txt, float x, float y, color c, int s) {
  pushStyle();
  textAlign(CENTER, CENTER);
  noStroke();
  
  textSize(s);
  fill(c);
  text(txt, x, y);
  
  popStyle();
}

//=== MENÚ
void menu() {
  if (imgMenu != null) {
    imageMode(CORNER);
    image(imgMenu, 0, 0, width, height);
  } else {
    background(15, 18, 25);
  }

 
  float objetivoY = 460 + opcionMenu * 156;
  triAnimY = lerp(triAnimY, objetivoY, 0.25);


  dibujarTriangulo(380, triAnimY);
}

//==================== TRIÁNGULO NEÓN ====================
void dibujarTriangulo(float x, float y) {
  pushMatrix();
  translate(x, y);

 
  noStroke();
  fill(0, 255, 120, 50);
  triangle(-14, -20, -14, 20, 24, 0);


  fill(30, 230, 100);
  stroke(255);
  strokeWeight(2);
  triangle(-8, -12, -8, 12, 16, 0);

  popMatrix();
}

//==================== PORTADA ====================
void portada() {
  if (imgPortada != null) {
    imageMode(CENTER);
    image(imgPortada, width/2, height/2, width, height);
    imageMode(CORNER);
  } else {
    background(10, 20, 40);
    fill(255, 215, 0);
    textSize(70);
    textAlign(CENTER, CENTER);
    text("SNAKE", width/2, 105);
    fill(255);
    textSize(24);
    text("BATTLE", width/2, 155);
  }
}

//==================== INICIAR JUEGO ====================
void iniciarJuego(int nuevoModo) {
  desconectarOnline();
  particulas.clear();
  comida.contadorComidas = 0;

  modo = nuevoModo;
  pantalla = PANTALLA_JUEGO;

  p1.reset(MUNDO_ANCHO/2 - (10*tam), MUNDO_ALTO/2, 1, 0);
  p2.reset(MUNDO_ANCHO/2 + (10*tam), MUNDO_ALTO/2, -1, 0);

  generarObstaculos();
  comida.generarNueva();
  generarAgujeros();

  ultimoTeleportP1 = -999999;
  ultimoTeleportP2 = -999999;

  frameRate(velocidad);
  resetCamara();

  if (nuevoModo == MODO_ONLINE) {
    conectarOnline();
  }

  if (soundIntro != null && !soundIntro.isPlaying()) {
    soundIntro.rewind();
    soundIntro.loop();
  }
}

//==================== CONTROLES DEL TECLADO ====================
void keyPressed() {
  // PORTADA
  if (pantalla == PANTALLA_PORTADA) {
    if (keyCode == ENTER || keyCode == RETURN) {
      pantalla = PANTALLA_MENU;
      opcionMenu = 0;
    }
    return;
  }

  // MENÚ
  if (pantalla == PANTALLA_MENU) {
    if (keyCode == UP || key == 'w' || key == 'W') {
      opcionMenu = (opcionMenu + 2) % 3;
    }
    if (keyCode == DOWN || key == 's' || key == 'S') {
      opcionMenu = (opcionMenu + 1) % 3;
    }
    if (keyCode == ENTER || keyCode == RETURN) {
      if (opcionMenu == 0) {
        iniciarJuego(MODO_SOLO);
      }
      if (opcionMenu == 1) {
        iniciarJuego(MODO_VERSUS);
      }
      if (opcionMenu == 2) {
        iniciarJuego(MODO_ONLINE);
      }
    }
    return;
  }

  // EN JUEGO
  if (pantalla == PANTALLA_JUEGO) {
    if (modo == MODO_ONLINE && (key == 'r' || key == 'R')) {
      desconectarOnline();
      pantalla = PANTALLA_MENU;
      return;
    }

    // Jugador 1: flechas
    if (keyCode == UP)    entradaDireccion(0, -1);
    if (keyCode == DOWN)  entradaDireccion(0, 1);
    if (keyCode == LEFT)  entradaDireccion(-1, 0);
    if (keyCode == RIGHT) entradaDireccion(1, 0);

    // Jugador 2: WASD
    if (modo == MODO_VERSUS) {
      if (key == 'w' || key == 'W') p2.cambiarDireccion(0, -1);
      if (key == 's' || key == 'S') p2.cambiarDireccion(0,  1);
      if (key == 'a' || key == 'A') p2.cambiarDireccion(-1, 0);
      if (key == 'd' || key == 'D') p2.cambiarDireccion( 1, 0);
    }
    return;
  }

  // GAME OVER
  if (pantalla == PANTALLA_GAMEOVER && (key == 'r' || key == 'R')) {
    if (modo == MODO_ONLINE) {
      desconectarOnline();
    }
    pantalla = PANTALLA_MENU;
    opcionMenu = 0;
  }
}
