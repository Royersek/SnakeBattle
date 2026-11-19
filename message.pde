// Snapshots del mundo: posiciones, cuerpo completo, puntos y poderes, comida,
// obstáculos y portales. Los tiempos se transmiten como duración restante.
int restante(int inicio,int duracion) { return max(0,duracion-(millis()-inicio)); }
String estadoSerpiente(Serpiente s) {
  StringBuilder b=new StringBuilder();
  b.append(s.puntos).append(',').append(s.muerta?1:0).append(',').append(s.direccion.x).append(',').append(s.direccion.y);
  b.append(',').append(restante(s.tsRapidez,s.DUR_RAPIDEZ)).append(',').append(restante(s.tsTransparente,s.DUR_TRANSPARENTE)).append(',').append(restante(s.tsDoble,s.DUR_DOBLE)).append(',').append(restante(s.tsIman,s.DUR_IMAN));
  for(PVector v:s.cuerpo) b.append(',').append(v.x).append(',').append(v.y);
  return b.toString();
}
String crearEstado() {
  StringBuilder b=new StringBuilder("S;");
  b.append(pantalla).append(';').append(estadoSerpiente(p1)).append(';').append(estadoSerpiente(p2)).append(';');
  b.append(comida.x).append(',').append(comida.y).append(',').append(comida.tipo).append(';');
  for(Obstaculo o:obstaculos) b.append(o.posicion.x).append(',').append(o.posicion.y).append(',').append(o.velocidad.x).append(',').append(o.velocidad.y).append('|');
  b.append(';');
  for(AgujeroGusano a:agujeros) {
    b.append(a.posicion.x).append(',').append(a.posicion.y).append(',').append(a.radio).append(',').append(a.colorA).append(',').append(a.colorB).append(',').append(a.permanente?1:0).append(',').append(a.permanente?-1:restante(a.tiempoCreacion,a.tiempoVida)).append(',').append(a.rotacion).append(',').append(a.pulso).append(',').append(a.alpha).append('|');
  }
  return b.toString();
}
int entero(String v) { return Integer.parseInt(v); }
float decimal(String v) { return Float.parseFloat(v); }
int desdeRestante(int t,int dur) { return t>0 ? millis()-dur+t : -999999; }
void leerSerpiente(String texto,Serpiente s) {
  String[] a=texto.split(",");
  int puntosAntes=s.puntos; boolean muertaAntes=s.muerta;
  s.puntos=entero(a[0]); s.muerta=entero(a[1])==1;
  s.direccion.set(decimal(a[2]),decimal(a[3]));
  s.tsRapidez=desdeRestante(entero(a[4]),s.DUR_RAPIDEZ);
  s.tsTransparente=desdeRestante(entero(a[5]),s.DUR_TRANSPARENTE);
  s.tsDoble=desdeRestante(entero(a[6]),s.DUR_DOBLE);
  s.tsIman=desdeRestante(entero(a[7]),s.DUR_IMAN);
  s.cuerpo.clear();
  for(int i=8;i+1<a.length;i+=2) s.cuerpo.add(new PVector(decimal(a[i]),decimal(a[i+1])));
  s.posicion=s.cuerpo.get(0);
  if (!muertaAntes && s.muerta) { s.reproducirSonido(soundMorir); emitirParticulas(s.posicion.x,s.posicion.y,color(255,60,60),60); }
  else if(s.puntos>puntosAntes) { s.reproducirSonido(soundComer); emitirParticulas(s.posicion.x,s.posicion.y,s.colorCabeza,20); }
}
void aplicarEstado(String texto) {
  String[] a=texto.split(";",-1);
  if(a.length!=7 || !a[0].equals("S")) throw new IllegalArgumentException("Snapshot inválido");
  leerSerpiente(a[2],p1); leerSerpiente(a[3],p2);
  String[] c=a[4].split(","); comida.x=entero(c[0]); comida.y=entero(c[1]); comida.tipo=entero(c[2]);
  obstaculos.clear();
  for(String fila:a[5].split("\\|")) if(!fila.isEmpty()) {
    String[] v=fila.split(","); obstaculos.add(new Obstaculo(decimal(v[0]),decimal(v[1]),decimal(v[2]),decimal(v[3])));
  }
  agujeros.clear();
  for(String fila:a[6].split("\\|")) if(!fila.isEmpty()) {
    String[] v=fila.split(",");
    AgujeroGusano g=new AgujeroGusano(decimal(v[0]),decimal(v[1]),decimal(v[2]),entero(v[3]),entero(v[4]),entero(v[5])==1);
    if(!g.permanente) g.tiempoCreacion=desdeRestante(entero(v[6]),g.tiempoVida);
    g.rotacion=decimal(v[7]); g.pulso=decimal(v[8]); g.alpha=decimal(v[9]); agujeros.add(g);
  }
  pantalla=entero(a[1]);
  actualizarVelocidad();
}
