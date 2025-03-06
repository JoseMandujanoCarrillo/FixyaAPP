import 'package:flutter/material.dart';
import 'principal.dart';  // Asegúrate de importar los servicios CleanFast desde el archivo principal
import 'solicitud.dart';  // Importa la pantalla de solicitud
import 'ajustes.dart';
import 'chat.dart';
import 'tu.dart';

class ServicioEmergencia extends StatefulWidget {
  const ServicioEmergencia({super.key});

  @override
  _ServicioEmergenciaState createState() => _ServicioEmergenciaState();
}

class _ServicioEmergenciaState extends State<ServicioEmergencia> {
  int _selectedIndex = 1;  // Asumimos que 'Emergencia' es la opción seleccionada

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios de Emergencia'),
        backgroundColor: const Color(0xFF94D6FF),
      ),
      body: SingleChildScrollView(  // Envuelve el cuerpo con SingleChildScrollView
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Agrega los servicios de emergencia
            for (var service in cleanFastServices) 
              _buildServiceCard(service),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),  // Asegúrate de que el menú de barra esté aquí
    );
  }

  Widget _buildServiceCard(Service service) {
    return Container(
      width: double.infinity,  // Ahora ocupa todo el ancho disponible
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFC5E7F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Image.asset(service.image, width: 130, height: 120),  // Aumento de tamaño de la imagen
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  service.description,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            service.price,
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                // Navegar a la pantalla de Solicitud
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SolicitarServicio()),  // Aquí rediriges
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF01497C),
              ),
              child: const Text("SOLICITAR", style: TextStyle(color: Colors.white)),
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
              ImageIcon(AssetImage("assets/iconos/icono6.png"), color: Color(0xFF9E9E9E)),
              Text("INICIO", style: TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono7.png"), color: Color(0xFF9E9E9E)),
              Text("AJUSTES", style: TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono8.png"), color: Color(0xFF9E9E9E)),
              Text("CHAT", style: TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono9.png"), color: Color(0xFF9E9E9E)),
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
            case 1: // Índice de la opción "AJUSTES"
              Navigator.push( context,
                MaterialPageRoute( builder: (context) => Ajustes()), // Navega a la pantalla Ajustes
              );
              break;
            case 2: 
              Navigator.push( context,
                MaterialPageRoute( builder: (context) => ChatListScreen ()), // Navega a la pantalla chat
              );
              break;
              case 3: 
              Navigator.push( context,
                MaterialPageRoute( builder: (context) => TuScreen ()), // Navega a la pantalla de perfil
              );
              break;
         }
       }
    );
  }
}
