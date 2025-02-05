import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'service_detail_screen.dart'; // Importar la pantalla de detalles
import 'calendar_screen.dart';
import 'package:convert/convert.dart';
import 'dart:typed_data'; // Para Uint8List
import 'profile_screen.dart';
import 'search_screen.dart'; // Importar la pantalla de búsqueda

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> services = [];
  String userName = "Usuario";
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _getUserData();
    await _getServices();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no logueado')),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userName = data['name'] ?? 'Usuario';
          // Guardar los valores en varias variables
          final int userId = data['id'];
          final String userEmail = data['email'];
          final double userLatitude = data['latitude'];
          final double userLongitude = data['longitude'];
          final String userCreatedAt = data['created_at'];
          final String userUpdatedAt = data['updated_at'];

          // Puedes usar estas variables como necesites
          print('User ID: $userId');
          print('User Email: $userEmail');
          print('User Latitude: $userLatitude');
          print('User Longitude: $userLongitude');
          print('User Created At: $userCreatedAt');
          print('User Updated At: $userUpdatedAt');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error al obtener los datos del usuario')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _getServices() async {
    try {
      final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/services?page=1&size=10'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          services = data['data'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar los servicios')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.notifications, color: Colors.black),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // Navegar a la pantalla de búsqueda
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPageContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home, color: Colors.black), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today, color: Colors.black), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu, color: Colors.black), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.person, color: Colors.black), label: ''),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_selectedIndex) {
      case 1:
        return const CalendarScreen();
      case 2:
        return const Center(child: Text('Menú'));
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    // Filtrar servicios con imágenes propias
    final servicesWithImage = services.where((s) => _hasImage(s)).toList();
    // Filtrar servicios sin imágenes
    final servicesWithoutImage = services.where((s) => !_hasImage(s)).toList();

    // Combinar las listas, priorizando los servicios con imágenes
    final popularServices = [
      ...servicesWithImage.take(5), // Tomar hasta 5 servicios con imágenes
      ...servicesWithoutImage.take(5 - servicesWithImage.length), // Completar con servicios sin imágenes si es necesario
    ].take(5).toList(); // Limitar a 5 servicios en total

    // Filtrar servicios para "Clean Flash" (sin imágenes)
    final cleanFlashServices = services.where((s) => !_hasImage(s)).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, $userName!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildServiceList('Servicios populares', popularServices),
            const SizedBox(height: 24),
            _buildServiceList('Clean Flash', cleanFlashServices),
          ],
        ),
      ),
    );
  }

  bool _hasImage(dynamic service) {
    return (service['imageUrl'] != null && service['imageUrl'].isNotEmpty) ||
        (service['imagebyte'] != null && service['imagebyte'].isNotEmpty);
  }

  Widget _buildServiceList(String title, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: items.isEmpty
              ? const Center(child: Text('No hay servicios disponibles'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildServiceCard(items[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(dynamic service) {
    final imageUrl = service['imageUrl'];
    final imageBytea = service['imagebyte'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ServiceDetailScreen(service: service), // Uso correcto
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SizedBox(
          width: 160,
          height: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            'https://i.imgur.com/FlcmJ1h.jpg',
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : imageBytea != null && imageBytea.isNotEmpty
                        ? Image.memory(
                            Uint8List.fromList(hex.decode(imageBytea)),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            'https://i.imgur.com/FlcmJ1h.jpg',
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['name'] ?? 'Sin nombre',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service['price'] != null
                          ? '\$${service['price']}'
                          : 'Consultar',
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}