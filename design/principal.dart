import 'package:flutter/material.dart';
import 'serviemergencia.dart';
import 'sevipopular.dart';
import 'actividad.dart';
import 'chat.dart';
import 'tu.dart';
import 'notificacion.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  _PantallaPrincipalState createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _selectedIndex = 0; // Para rastrear la opción seleccionada

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearchBarWithIcons(),
          _buildMenuOptions(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                      "CleanFast (Todos los servicios CleanFast llegan el mismo día que los solicitas)"),
                  _buildHorizontalScroll(cleanFastServices),
                  _buildSectionTitle("Servicios más populares"),
                  _buildHorizontalScroll(popularServices, isPopular: true),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF94D6FF), Color(0xFF94D6FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Text(
        "Hola, User",
        style: TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

Widget _buildSearchBarWithIcons() {
  return Padding(
    padding: const EdgeInsets.all(17),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: "Buscar un servicio, categoría...",
              hintStyle: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black38),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset("assets/iconos/icono5.png"),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificacionesScreen(),
              ),
            );
          },
          child: Image.asset("assets/iconos/icono3.png", width: 27, height: 27),
        ),
        const SizedBox(width: 10),
        Image.asset("assets/iconos/icono4.png", width: 27, height: 27),
      ],
    ),
  );
}

  Widget _buildMenuOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _menuOption("Todos", 0),
          _menuOption("Emergencia", 1),
          _menuOption("Más populares", 2),
        ],
      ),
    );
  }

  Widget _menuOption(String label, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          if (label == "Emergencia") {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ServicioEmergencia()),
            );
          } else if (label == "Más populares") {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ServicioPopulares()),
            );
          }
        });
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _selectedIndex == index
                  ? const Color(0xFF9747FF)
                  : Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          if (_selectedIndex == index)
            Container(
              height: 2,
              width: 30,
              color: const Color(0xFF9747FF),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(27),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

    Widget _buildHorizontalScroll(List<Service> services,
        {bool isPopular = false}) {
      return SizedBox(
        height: isPopular ? 250 : 210,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: services.length,
          itemBuilder: (context, index) {
            return _buildServiceCard(services[index], isPopular);
          },
        ),
      );
    }

    Widget _buildServiceCard(Service service, bool isPopular) {
      return Container(
        width: isPopular ? 345 : 300,
        margin: const EdgeInsets.only(left: 21),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFC5E7F2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Image.asset(service.image,
                    width: isPopular ? 109 : 55, height: isPopular ? 73 : 84),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    service.description,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(service.price,
                style: const TextStyle(fontSize: 14, color: Colors.red)),
            const SizedBox(height: 5),
            if (isPopular) ...[
              const Text(
                "Para poder solicitar un servicio debe de pagar un anticipo de la mitad del precio y cuando se termine de hacer el servicio se paga la otra mitad",
                style: TextStyle(fontSize: 12),
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF01497C)),
                child: const Text("SOLICITAR",
                    style: TextStyle(color: Colors.white, fontSize: 11)),
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
        showUnselectedLabels: true, // Para que se muestren las etiquetas}
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

class Service {
  final String title;
  final String image;
  final String price;
  final String description;

  Service(this.title, this.image, this.price, this.description);
}

final List<Service> cleanFastServices = [
  Service("Limpieza de comedor", "assets/image/image2.png", "\$100",
      "Limpieza rápida del área del comedor, garantizando un ambiente libre de polvo y residuos."),
  Service("Limpieza de baño", "assets/image/image3.png", "\$120",
      "Limpieza profunda de todos los componentes del baño, incluyendo inodoro y lavabo."),
  Service("Limpieza de cocina", "assets/image/image4.png", "\$130",
      "Limpieza profunda en la cocina, incluyendo superficies, fregaderos y electrodomésticos."),
];

final List<Service> popularServices = [
  Service("Limpieza profunda", "assets/image/image5.png", "\$200",
      "Servicio intensivo de limpieza profunda para toda la casa, incluyendo áreas difíciles."),
  Service("Limpieza exprés", "assets/image/image2.png", "\$150",
      "Servicio rápido para una limpieza básica en pocas horas."),
  Service("Limpieza completa", "assets/image/image3.png", "\$250",
      "Limpieza total de la vivienda, cubriendo todas las habitaciones y zonas comunes."),
];
