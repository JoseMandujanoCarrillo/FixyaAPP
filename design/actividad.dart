import 'package:flutter/material.dart';
import 'chats.dart';
import 'principal.dart';
import 'tu.dart';
import 'chat.dart';
import 'evidencia.dart'; // Asegúrate de que la ruta esté correcta

class HistorialSoliScreen extends StatefulWidget {
  @override
  _HistorialSoliScreenState createState() => _HistorialSoliScreenState();
}

class _HistorialSoliScreenState extends State<HistorialSoliScreen> {
  String estadoSeleccionado = "Pendiente";
  bool _isDetailsVisible = false; // Variable para manejar el despliegue del recuadro

  final Map<String, List<Map<String, String>>> servicios = {
    "Pendiente": [
      {"titulo": "Limpieza de piscina", "ubicacion": "Calle 24 #232-A x 60 y 63 Col. Centro", "precio": "\$1,500", "fecha": "Hoy, 22/Feb/2025"},
      {"titulo": "Limpieza de cocina", "ubicacion": "Calle 12 #344 x 92 y 33 Col. Madero", "precio": "\$1,900", "fecha": "Martes, 20/Feb/2025"},
    ],
    "Aceptada": [
      {"titulo": "Limpieza de oficina", "ubicacion": "Calle 23 #345-b x 23 y 133 Col. América", "precio": "\$3,000", "fecha": "Hoy, 22/Feb/2025", "aclaracion": "Ver más"},
      {"titulo": "Limpieza de sala", "ubicacion": "Calle 13 #333 x 78 y 89 Col. Reyes", "precio": "\$1,456", "fecha": "Martes, 11/Feb/2025", "aclaracion": "Ver más"},
    ],
    "En progreso": [
      {"titulo": "Limpieza de jardín", "ubicacion": "Calle 24 #232-A x 60 y 63 Col. Centro", "precio": "\$1,500", "fecha": "Ayer, 21/Feb/2025"},
      {"titulo": "Limpieza de cochera", "ubicacion": "Calle 12 #344 x 92 y 33 Col. Madero", "precio": "\$1,900", "fecha": "Martes, 20/Feb/2025"},
    ],
    "Rechazada": [
      {"titulo": "Limpieza de jardín", "ubicacion": "Calle 24 #232-A x 60 y 63 Col. Centro", "precio": "\$1,500", "fecha": "Ayer, 21/Feb/2025"},
      {"titulo": "Limpieza de cochera", "ubicacion": "Calle 12 #344 x 92 y 33 Col. Madero", "precio": "\$1,900", "fecha": "Martes, 20/Feb/2025"},
    ],
    "Finalizada": [
      {"titulo": "Limpieza de cocina", "ubicacion": "Calle 24 #232-A x 60 y 63 Col. Centro", "precio": "\$1,800", "fecha": "Ayer, 21/Feb/2025"},
      {"titulo": "Limpieza de cuarto", "ubicacion": "Calle 12 #344 x 92 y 33 Col. Madero", "precio": "\$1,202", "fecha": "Martes, 20/Feb/2025"},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF94D6FF),
      ),
      body: Column(
        children: [
          SizedBox(height: 25),
          Text("Historial de solicitudes", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ["Pendiente", "Aceptada", "En progreso", "Rechazada", "Finalizada"].map((estado) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    estadoSeleccionado = estado;
                  });
                },
                child: Text(
                  estado,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: estadoSeleccionado == estado ? Color(0xFF9747FF) : Colors.black,
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 15),
          Expanded(
            child: ListView(
              children: servicios[estadoSeleccionado]!.map((servicio) {
                return _servicio(servicio);
              }).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _servicio(Map<String, String> servicio) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Creado: ${servicio["fecha"]}", style: TextStyle(fontWeight: FontWeight.bold)),
          Container(
            margin: EdgeInsets.symmetric(vertical: 5),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFFF4F4F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(servicio["titulo"]!, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text(servicio["ubicacion"]!),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Precio: ${servicio["precio"]}"),
                    Text("Estado: $estadoSeleccionado", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (estadoSeleccionado == "Finalizada") // Verifica si el estado es Finalizada
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EvidenciaScreen()), // Navega a la pantalla de evidencia
                        );
                      },
                      child: Text(
                        "¿Desea agregar un comentario o evidencia?",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ),
                if (_isDetailsVisible) _detallesLimpiador(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detallesLimpiador() {
    return Center(
      child: Container(
        width: 300,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Image.asset("assets/image/image7.png", height: 80, width: 80),
            SizedBox(height: 10),
            Text("Mariana Canche", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Lunes a viernes", style: TextStyle(fontSize: 14)),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("8:00 a.m - 5:30 p.m", style: TextStyle(fontSize: 14)),
                Text("9999090501", style: TextStyle(fontSize: 14)),
              ],
            ),
            SizedBox(height: 10),
            Text("¿Tiene alguna aclaración?", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.black)),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(chatPartnerName: "Mariana Canche"), // Pasar el nombre aquí
                  ),
                );
              },
              child: Text("Contáctame", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono6.png"),
                  color: Color(0xFF9E9E9E)),
              Text("INICIO", style: TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono23.png"),
                  color: Color(0xFF9E9E9E)),
              Text("Actividad", style: TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono8.png"),
                  color: Color(0xFF9E9E9E)),
              Text("CHAT", style: TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono9.png"),
                  color: Color(0xFF9E9E9E)),
              Text("TÚ", style: TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          label: '',
        ),
      ],
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue, // Seleccionado con color azul
      unselectedItemColor: Color(0xFF9E9E9E), // No seleccionado con color gris
      showUnselectedLabels: true, // Para que se muestren las etiquetas
      onTap: (index) {
        switch (index) {
          case 0: // Índice de la opción "INICIO"
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PantallaPrincipal()), // Navega a la pantalla principal
            );
            break;
          case 2: // Índice de la opción "CHAT"
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatListScreen()), // Navega a la pantalla de chat
            );
            break;
          case 3: // Índice de la opción "TÚ"
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TuScreen()), // Navega a la pantalla de perfil
            );
            break;
        }
      },
    );
  }
}
