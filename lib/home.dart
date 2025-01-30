import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'calendar_screen.dart'; // Ajusta la ruta según tu estructura

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> services = [];
  String userName = "Usuario";
  int _selectedIndex = 0;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserData();
    _getServices();
  }

  Future<void> _getUserData() async {
    final response = await http.get(
      Uri.parse('https://apifixya.onrender.com/user/profile'),
      headers: {
        'Authorization': 'Bearer TU_TOKEN_AQUI',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        userName = data['name'] ?? 'Usuario';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al obtener los datos del usuario')),
      );
    }
  }

  Future<void> _getServices() async {
    final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/services?page=1&size=10'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        services = _prioritizeWithImages(data['data']);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar los servicios')),
      );
    }
  }

  List<dynamic> _prioritizeWithImages(List<dynamic> items) {
    return List.from(items)
      ..sort((a, b) {
        final aHasImage =
            (a['imageUrl'] != null && a['imageUrl'].isNotEmpty) ? 1 : 0;
        final bHasImage =
            (b['imageUrl'] != null && b['imageUrl'].isNotEmpty) ? 1 : 0;
        return bHasImage.compareTo(aHasImage);
      });
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
            icon: const Icon(Icons.filter_alt, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildPageContent(),
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
        return const CalendarScreen(); // Aquí cargamos la pantalla del calendario
      case 2:
        return const Center(child: Text('Menú'));
      case 3:
        return const Center(child: Text('Perfil'));
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    final popularServices = services.take(5).toList();
    final cleanFlashServices = services.skip(5).toList();

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
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar un servicio, categoría...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildServiceList('Servicios populares', popularServices),
            const SizedBox(height: 24),
            _buildServiceList('Clean Flash', cleanFlashServices),
          ],
        ),
      ),
    );
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
              ? const Center(child: CircularProgressIndicator())
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
    return Card(
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
              child: Image.network(
                service['imageUrl'] ?? 'https://imgur.com/GbCHvXU.png',
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
    );
  }
}
