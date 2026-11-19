import ddf.minim.*;
import java.io.*; //Incorpora herramientas de entrada y salida de datos (Input/Output).
import java.nio.charset.StandardCharsets; //Permite utilizar codificaciones de caracteres estándar, como UTF-8.
import java.util.concurrent.atomic.AtomicReference;
import processing.data.*;
import java.net.*;

// CONSTANTES DE PANTALLA 
final int PANTALLA_PORTADA  = -1;
final int PANTALLA_MENU     =  0;
final int PANTALLA_JUEGO    =  1;
final int PANTALLA_GAMEOVER =  2;

// MODOS DE JUEGO 
final int MODO_SOLO    = 1;
final int MODO_VERSUS  = 2;
final int MODO_ONLINE  = 3;

// TAMAÑO DEL MUNDO 
final int MUNDO_ANCHO = 2400;
final int MUNDO_ALTO  = 1800;

// ESTADO GLOBAL 
int pantalla = PANTALLA_PORTADA;
int modo = MODO_SOLO;

int tam = 30;
int velocidad = 8;
int velocidadMax = 20;
int opcionMenu = 0;
float[] animBoton = new float[3];

//= ENTIDADES 
Serpiente p1;
Serpiente p2;
Comida comida;

// Colecciones dinámicas
ArrayList<Obstaculo> obstaculos = new ArrayList<Obstaculo>();
ArrayList<Particula> particulas = new ArrayList<Particula>();

// AGUJEROS DE GUSANO
ArrayList<AgujeroGusano> agujeros = new ArrayList<AgujeroGusano>();
final int COOLDOWN_TELEPORT = 1500;
int ultimoTeleportP1 = -999999;
int ultimoTeleportP2 = -999999;

// Control de generación dinámica
final int TOTAL_AGUJEROS_TEMPORALES = 11;
final int TOTAL_AGUJEROS_PERMANENTES = 4;
int ultimoSpawnAgujero = 0;
final int SPAWN_INTERVAL = 2000;

//RECURSOS 
Minim minim;
AudioPlayer soundIntro, soundComer, soundMorir;
PImage imgPortada;
PImage imgMenu;
PImage imgGameOver;
PImage imgComida, imgVelocidad, imgTransparencia, imgDoblePuntos, imgIman;

//==================== SETUP ====================
void setup() {
    
  fullScreen(JAVA2D); 
  textAlign(CENTER, CENTER);
  frameRate(velocidad);

  imgPortada      = loadImage("data/portada.png");
  imgMenu         = loadImage("data/menu.png");
  imgGameOver     = loadImage("data/gameover.png");
  imgComida       = loadImage("data/comida.png");
  imgVelocidad    = loadImage("data/velocidad.png");
  imgTransparencia= loadImage("data/transparencia.png");
  imgDoblePuntos  = loadImage("data/doblepuntos.png");
  imgIman         = loadImage("data/iman.png");

  minim       = new Minim(this);
  soundIntro  = minim.loadFile("data/sound/intro.mp3", 1024);
  soundComer  = minim.loadFile("data/sound/comer.mp3", 512);
  soundMorir  = minim.loadFile("data/sound/morir.mp3", 512);

  if (soundIntro != null) {
    soundIntro.setGain(0.0);
    soundIntro.loop();
  }

  p1 = new Serpiente(MUNDO_ANCHO/2 - (10*tam), MUNDO_ALTO/2,  1, 0,
                     color(0, 255, 100), color(0, 180, 80), tam);
  p2 = new Serpiente(MUNDO_ANCHO/2 + (10*tam), MUNDO_ALTO/2, -1, 0,
                     color(0, 150, 255), color(0, 100, 200), tam);
  comida = new Comida(tam);
  comida.generarNueva();

  generarObstaculos();
  generarAgujeros();
  resetCamara();
}

void generarObstaculos() {
  obstaculos.clear();
  for (int i = 0; i < 4; i++) {
    float x = random(100, MUNDO_ANCHO - 100);
    float y = random(100, MUNDO_ALTO - 100);
    if (abs(x - MUNDO_ANCHO/2) < 300 && abs(y - MUNDO_ALTO/2) < 200) {
      x += 400;
    }
    float vx = random(1) < 0.5 ? -2 : 2;
    float vy = random(1) < 0.5 ? -2 : 2;
    obstaculos.add(new Obstaculo(x, y, vx, vy));
  }
}

void generarAgujeros() {
  agujeros.clear();
  float radio = tam * 1.2;
  float margen = 210;
  AgujeroGusano perm1 = new AgujeroGusano(margen, margen, radio,
                                           color(0, 255, 255), color(150, 100, 255), true);
  AgujeroGusano perm2 = new AgujeroGusano(MUNDO_ANCHO - margen - radio*2, margen, radio,
                                           color(255, 50, 200), color(255, 150, 50), true);
  AgujeroGusano perm3 = new AgujeroGusano(margen, MUNDO_ALTO - margen - radio*2, radio,
                                           color(255, 220, 0), color(255, 100, 0), true);
  AgujeroGusano perm4 = new AgujeroGusano(MUNDO_ANCHO - margen - radio*2, MUNDO_ALTO - margen - radio*2, radio,
                                           color(100, 255, 100), color(0, 200, 0), true);

  perm1.pareja = perm2; perm2.pareja = perm1;
  perm3.pareja = perm4; perm4.pareja = perm3;

  agujeros.add(perm1); agujeros.add(perm2); agujeros.add(perm3); agujeros.add(perm4);

  for (int i = 0; i < TOTAL_AGUJEROS_TEMPORALES; i++) {
    generarAgujeroTemporal();
  }
  ultimoSpawnAgujero = millis();
}

void generarAgujeroTemporal() {
  float radio = tam * 1.2;
  for (int intento = 0; intento < 100; intento++) {
    float x = random(radio * 2, MUNDO_ANCHO - radio * 2);
    float y = random(radio * 2, MUNDO_ALTO - radio * 2);
    x = (int)(x / tam) * tam;
    y = (int)(y / tam) * tam;

    if (abs(x - MUNDO_ANCHO/2) < 400 && abs(y - MUNDO_ALTO/2) < 300) continue;

    boolean muyCerca = false;
    for (AgujeroGusano a : agujeros) {
      if (a.activo && dist(x, y, a.posicion.x, a.posicion.y) < 300) {
        muyCerca = true;
        break;
      }
    }
    if (muyCerca) continue;

    color[] colores = {
      color(0, 255, 255), color(255, 50, 200), color(255, 220, 0),
      color(100, 255, 100), color(255, 100, 255), color(150, 200, 255)
    };
    color cA = colores[(int)random(colores.length)];
    color cB = colores[(int)random(colores.length)];

    AgujeroGusano nuevo = new AgujeroGusano(x, y, radio, cA, cB, false);
    AgujeroGusano parejaEncontrada = null;
    for (AgujeroGusano a : agujeros) {
      if (!a.permanente && a.activo && a.pareja == null) {
        parejaEncontrada = a;
        break;
      }
    }

    if (parejaEncontrada != null) {
      nuevo.pareja = parejaEncontrada;
      parejaEncontrada.pareja = nuevo;
    } else {
      ArrayList<AgujeroGusano> permanentes = new ArrayList<AgujeroGusano>();
      for (AgujeroGusano a : agujeros) {
        if (a.permanente) permanentes.add(a);
      }
      if (permanentes.size() > 0) {
        AgujeroGusano permAleatorio = permanentes.get((int)random(permanentes.size()));
        nuevo.pareja = permAleatorio;
      }
    }
    agujeros.add(nuevo);
    return;
  }
}

//==================== LOOP PRINCIPAL 
void draw() {
  background(15);
  switch (pantalla) {
    case PANTALLA_PORTADA:  portada();   break;
    case PANTALLA_MENU:     menu();      break;
    case PANTALLA_JUEGO:    juego();     break;
    case PANTALLA_GAMEOVER: gameOver();  break;
  }
}

void controlarMusica() {
  if (soundIntro == null) return;
  if (pantalla == PANTALLA_GAMEOVER && soundIntro.isPlaying()) {
    soundIntro.pause();
  }
}

void stop() {
  desconectarOnline();
  if (soundIntro != null) soundIntro.close();
  if (soundComer  != null) soundComer.close();
  if (soundMorir  != null) soundMorir.close();
  if (minim != null) minim.stop();
  super.stop();
}

boolean dosJugadores() { return modo != MODO_SOLO; }
boolean partidaLista() { return modo != MODO_ONLINE || (red != null && red.conectado && (red.host || red.recibioEstado)); }

void juego() {
  if (modo == MODO_ONLINE) procesarRed();
  if (partidaLista() && (modo != MODO_ONLINE || red.host)) {
    simularPartida();
    if (modo == MODO_ONLINE) enviarEstadoRed();
  }
  background(20, 25, 30);
  actualizarCamara();
  pushMatrix();
  aplicarCamara();
  dibujarGrid(); dibujarLimitesMundo();
  comida.actualizar(); comida.dibujar();
  for (Obstaculo o : obstaculos) o.dibujar();
  for (AgujeroGusano a : agujeros) a.dibujar();
  p1.dibujar();
  if (dosJugadores()) p2.dibujar();
  actualizarParticulas();
  popMatrix();
  dibujarVignette(); dibujarHUD(); dibujarMinimapa();
  if (!partidaLista()) {
    fill(0,0,0,180); rect(0,0,width,height);
    fill(255,220,0); textAlign(CENTER,CENTER); textSize(25);
    text(red == null ? "Sin conexión" : red.estado, width/2, height/2-20);
    fill(220); textSize(16); text("Misma red local • R para volver al menú",width/2,height/2+25);
  }
  if (pantalla == PANTALLA_GAMEOVER) controlarMusica();
}

// 
void simularPartida() {
  if (!p1.muerta && p1.buffActivo(p1.tsIman,p1.DUR_IMAN)) p1.aplicarIman(comida);
  else if (dosJugadores() && !p2.muerta) p2.aplicarIman(comida);
  for (Obstaculo o : obstaculos) o.actualizar();
  for (AgujeroGusano a : agujeros) a.actualizar();
  for (int i=agujeros.size()-1; i>=0; i--) if (agujeros.get(i).expiro()) agujeros.remove(i);
  if (millis()-ultimoSpawnAgujero > SPAWN_INTERVAL && agujeros.size() < TOTAL_AGUJEROS_TEMPORALES+TOTAL_AGUJEROS_PERMANENTES) {
    generarAgujeroTemporal(); ultimoSpawnAgujero=millis();
  }
  p1.actualizar(comida);
  if (dosJugadores()) p2.actualizar(comida);
  if (!p1.muerta) verificarTeleport(p1,1);
  if (dosJugadores() && !p2.muerta) verificarTeleport(p2,2);
  comprobarObstaculos(p1);
  if (dosJugadores()) {
    comprobarObstaculos(p2);
    // Choque frontal de cabezas: ambos mueren, NINGUNO gana +20
    if (!p1.muerta && !p2.muerta && !p1.esTransparente() && !p2.esTransparente() && p1.posicion.x==p2.posicion.x && p1.posicion.y==p2.posicion.y) {
      p1.morir(); p2.morir();
    } else {
      // Choque contra el cuerpo: el que sobrevive gana +20 (dentro de verificarColisionCon)
      p1.verificarColisionCon(p2); p2.verificarColisionCon(p1);
    }
  }
  actualizarVelocidad();
  if (p1.muerta && (!dosJugadores() || p2.muerta)) pantalla=PANTALLA_GAMEOVER;
}

void comprobarObstaculos(Serpiente s) {
  if (!s.muerta) for (Obstaculo o : obstaculos) if (o.colisionaCon(s)) { s.morir(); break; }
}

void verificarTeleport(Serpiente s, int jugador) {
  int ultimoTeleport = (jugador == 1) ? ultimoTeleportP1 : ultimoTeleportP2;
  if (millis() - ultimoTeleport < COOLDOWN_TELEPORT) return;

  PVector cabeza = s.cuerpo.get(0);
  for (AgujeroGusano entrada : agujeros) {
    if (entrada.cabezaDentro(cabeza, s.tam) && entrada.pareja != null && entrada.pareja.activo && !entrada.pareja.expiro()) {
      AgujeroGusano salida = entrada.pareja;

      float nuevaX = round((salida.posicion.x + salida.radio - s.tam/2.0)/s.tam)*s.tam;
      float nuevaY = round((salida.posicion.y + salida.radio - s.tam/2.0)/s.tam)*s.tam;

      float dx = nuevaX - cabeza.x;
      float dy = nuevaY - cabeza.y;
      boolean destinoValido = true;
      for (PVector seg : s.cuerpo) {
        if (seg.x+dx < 0 || seg.x+dx >= MUNDO_ANCHO || seg.y+dy < 0 || seg.y+dy >= MUNDO_ALTO) destinoValido = false;
      }
      if (!destinoValido) continue;
      for (PVector seg : s.cuerpo) {
        seg.x += dx;
        seg.y += dy;
      }
      s.posicion = s.cuerpo.get(0);

      emitirParticulas(entrada.posicion.x + entrada.radio,
                       entrada.posicion.y + entrada.radio,
                       entrada.colorA, 30);
      emitirParticulas(salida.posicion.x + salida.radio,
                       salida.posicion.y + salida.radio,
                       salida.colorA, 30);

      if (jugador == 1) ultimoTeleportP1 = millis();
      else              ultimoTeleportP2 = millis();

      break;
    }
  }
}

void actualizarVelocidad() {
  int puntajeTotal = p1.puntos;
  if (dosJugadores()) puntajeTotal += p2.puntos;

  int nuevaVelocidad = velocidad + (puntajeTotal / 30);
  nuevaVelocidad = min(nuevaVelocidad, velocidadMax);
  frameRate(nuevaVelocidad);
}

void emitirParticulas(float x, float y, color c, int cantidad) {
  for (int i = 0; i < cantidad; i++) {
    PVector vel = PVector.random2D().mult(random(1, 4));
    particulas.add(new Particula(
      new PVector(x, y),
      vel,
      c,
      random(20, 40),
      random(3, 8)
    ));
  }
}

void actualizarParticulas() {
  for (int i = particulas.size() - 1; i >= 0; i--) {
    Particula p = particulas.get(i);
    p.actualizar();
    p.dibujar();
    if (p.murio()) particulas.remove(i);
  }
}
