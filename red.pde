// Red local: un servidor simula la partida y envía el estado completo al cliente.
final int PUERTO_TCP=5204, PUERTO_UDP=8888;
SesionRed red;

void conectarOnline() {
  desconectarOnline();
  red=new SesionRed();
  final SesionRed sesion=red;
  new Thread(() -> sesion.iniciar(), "snake-conexion").start();
}
void desconectarOnline() {
  if (red!=null) { red.cerrar(); red=null; }
}
void entradaDireccion(int x,int y) {
  if (modo!=MODO_ONLINE) p1.cambiarDireccion(x,y);
  else if (red!=null && red.conectado) {
    if (red.host) p1.cambiarDireccion(x,y);
    else red.enviar("D;"+x+";"+y);
  }
}
void procesarRed() {
  if (red==null) return;
  if (red.host) {
    String comando=red.entrada.getAndSet(null);
    if (comando!=null) {
      String[] d=comando.split(";");
      try {
        int x=Integer.parseInt(d[1]), y=Integer.parseInt(d[2]);
        if (abs(x)+abs(y)==1) p2.cambiarDireccion(x,y);
      } catch (Exception e) { println("Dirección inválida"); }
    }
  } else {
    String estado=red.entrada.getAndSet(null);
    if (estado!=null) {
      try { aplicarEstado(estado); red.recibioEstado=true; }
      catch (Exception e) { red.estado="Estado de red inválido"; }
    }
  }
}
void enviarEstadoRed() { if (red!=null && red.host && red.conectado) red.enviar(crearEstado()); }

class SesionRed {
  volatile boolean activa=true, host=false, conectado=false, recibioEstado=false;
  volatile String estado="Buscando servidor...";
  volatile Socket socket;
  volatile ServerSocket servidor;
  volatile DatagramSocket udp;
  volatile PrintWriter salida;
  AtomicReference<String> entrada=new AtomicReference<String>();

  void iniciar() {
    try {
      String ip=buscarServidor();
      if (!activa) return;
      if (ip!=null) conectar(ip);
      else {
        try {
          servidor=new ServerSocket(); servidor.setReuseAddress(true);
          servidor.bind(new InetSocketAddress(PUERTO_TCP));
        } catch (BindException e) {
          cerrarServidor(); conectar("127.0.0.1"); leer(); return;
        }
        host=true;
        estado="Esperando al jugador 2...";
        new Thread(() -> responderUDP(),"snake-udp").start();
        Socket s=servidor.accept();
        if (!activa) { s.close(); return; }
        socket=s;
        prepararSocket();
      }
      leer();
    } catch (Exception e) {
      if (activa) { estado="No se pudo conectar: volvé al menú"; println(e); }
    } finally {
      conectado=false;
      if (activa && salida!=null) estado="El otro jugador se desconectó";
      cerrar();
    }
  }
  String buscarServidor() {
    try (DatagramSocket d=new DatagramSocket()) {
      d.setBroadcast(true); d.setSoTimeout(1300);
      byte[] msg="SNAKE_BATTLE_V2?".getBytes(StandardCharsets.UTF_8);
      d.send(new DatagramPacket(msg,msg.length,InetAddress.getByName("127.0.0.1"),PUERTO_UDP));
      d.send(new DatagramPacket(msg,msg.length,InetAddress.getByName("255.255.255.255"),PUERTO_UDP));
      long fin=System.currentTimeMillis()+1300;
      while (activa && System.currentTimeMillis()<fin) {
        byte[] b=new byte[64]; DatagramPacket respuesta=new DatagramPacket(b,b.length); d.receive(respuesta);
        if (new String(b,0,respuesta.getLength(),StandardCharsets.UTF_8).equals("SNAKE_BATTLE_V2!")) return respuesta.getAddress().getHostAddress();
      }
    } catch (IOException e) { /* No se encontró servidor. */ }
    return null;
  }
  void responderUDP() {
    try (DatagramSocket d=new DatagramSocket(PUERTO_UDP)) {
      udp=d; d.setSoTimeout(500);
      while (activa && !conectado) {
        byte[] b=new byte[64]; DatagramPacket paquete=new DatagramPacket(b,b.length);
        try { d.receive(paquete); } catch (SocketTimeoutException e) { continue; }
        if (new String(b,0,paquete.getLength(),StandardCharsets.UTF_8).equals("SNAKE_BATTLE_V2?")) {
          byte[] r="SNAKE_BATTLE_V2!".getBytes(StandardCharsets.UTF_8);
          d.send(new DatagramPacket(r,r.length,paquete.getAddress(),paquete.getPort()));
        }
      }
    } catch (IOException e) { if (activa && !conectado) println("UDP: "+e); }
  }
  void conectar(String ip) throws IOException {
    socket=new Socket(); socket.connect(new InetSocketAddress(ip,PUERTO_TCP),2500); prepararSocket();
  }
  void prepararSocket() throws IOException {
    if (!activa) throw new IOException("Cancelado");
    socket.setTcpNoDelay(true);
    salida=new PrintWriter(new OutputStreamWriter(socket.getOutputStream(),StandardCharsets.UTF_8),true);
    conectado=true; estado="Conectado";
  }
  void leer() throws IOException {
    BufferedReader lector=new BufferedReader(new InputStreamReader(socket.getInputStream(),StandardCharsets.UTF_8));
    String linea;
    while (activa && (linea=lector.readLine())!=null) {
      if (host && linea.startsWith("D;") || !host && linea.startsWith("S;")) entrada.set(linea);
    }
  }
  void enviar(String texto) {
    PrintWriter w=salida;
    if (conectado && w!=null) { w.println(texto); if (w.checkError()) cerrar(); }
  }
  void cerrarServidor() { try { if(servidor!=null) servidor.close(); } catch(IOException e){} }
  void cerrar() {
    activa=false; conectado=false;
    try { if(socket!=null) socket.close(); } catch(IOException e){}
    cerrarServidor(); if(udp!=null) udp.close();
  }
}
