import 'package:flutter/material.dart';
import 'actividad.dart';
import 'ajustes.dart';
import 'chat.dart';
import 'principal.dart';

class TuScreen extends StatefulWidget {
  @override
  _TuScreenState createState() => _TuScreenState();
}

class _TuScreenState extends State<TuScreen> {
  bool mostrarContrasena = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF94D6FF),
      ),
      body: Column(
        children: [
          // Menú horizontal
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _menuButton("Perfil", true),
                _menuButton("Ajustes", false),
              ],
            ),
          ),

          // Contenido del perfil
          Expanded(
            child: Column(
              children: [
                SizedBox(height: 20),

                // Recuadro de la foto de perfil
                Container(
                  width: 300,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Color(0xC5E7F2).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage("assets/image/image6.png"),
                      ),
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () {
                            // Función para cambiar la foto de perfil
                          },
                          child: Image.asset(
                            "assets/iconos/icono20.png",
                            width: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Campos del usuario
                _inputField("NOMBRE", "Alice Walton", false),
                _inputField("CORREO ELECTRÓNICO", "AliceSabritas123@gmail.com", false),
                _inputField("CONTRASEÑA", mostrarContrasena ? "Alice123?" : "********", true),
                _inputField("MÉTODO DE PAGO", "Efectivo", false),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(), // ← Aquí agregamos la barra de navegación
    );
  }

  // Widget para crear botones del menú horizontal
  Widget _menuButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (text == "Ajustes") {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Ajustes()));
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isSelected ? Color(0xFF9747FF) : Colors.black,
          ),
        ),
      ),
    );
  }

  // Widget para crear los campos del usuario
  Widget _inputField(String label, String value, bool isPassword) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), // Aumento el padding para separar más
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black)),
          SizedBox(height: 5),
          Container(
            width: 300,
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.5),
              borderRadius: BorderRadius.circular(7), // Borde circular más pronunciado
              border: Border.all(color: Colors.black, width: 1), // Borde negro
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(value, style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0), fontSize: 14)),
                  ),
                ),
                if (isPassword)
                  IconButton(
                    icon: Image.asset("assets/iconos/icono22.png", width: 20),
                    onPressed: () {
                      setState(() {
                        mostrarContrasena = !mostrarContrasena;
                      });
                    },
                  ),
                IconButton(
                  icon: Image.asset("assets/iconos/icono21.png", width: 20),
                  onPressed: () {
                    // Función para editar datos
                  },
                ),
              ],
            ),
          ),
        ],
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
      unselectedItemColor:
          Color(0xFF9E9E9E), // No seleccionado con color gris
      showUnselectedLabels: true, // Para que se muestren las etiquetas
      onTap: (index) {
        switch (index) {
          case 1: // Índice de la opción "AJUSTES"
            Navigator.push( context,
              MaterialPageRoute( builder: (context) => HistorialSoliScreen()), // Navega a la pantalla Ajustes
            );
            break;
          case 2: 
            Navigator.push( context,
              MaterialPageRoute( builder: (context) => ChatListScreen ()), // Navega a la pantalla chat
            );
            break;
          case 0: 
            Navigator.push( context,
              MaterialPageRoute( builder: (context) => PantallaPrincipal ()), // Navega a la pantalla principal
            );
            break;
        }
      },
    );
  }
}
