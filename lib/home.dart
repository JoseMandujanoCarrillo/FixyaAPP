import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> services = [];
  List<dynamic> searchResults = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getServices();
  }

  // Obtiene servicios de la API
  Future<void> _getServices() async {
    try {
      final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/services?page=1&size=5'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          services = data['data'] ?? [];
        });
      } else {
        _showSnackBar('Error al cargar los servicios');
      }
    } catch (e) {
      _showSnackBar('Ocurrió un error: $e');
    }
  }

  // Busca servicios en la API
  Future<void> _searchServices(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults.clear();
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/services/search?query=$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          searchResults = data['data'] ?? [];
        });
      } else {
        _showSnackBar('No se encontraron resultados');
      }
    } catch (e) {
      _showSnackBar('Ocurrió un error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hola, User!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              onChanged: (value) => _searchServices(value),
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
            if (searchResults.isNotEmpty)
              _buildSearchResults()
            else
              _buildServices(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resultados de búsqueda',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildHorizontalList(searchResults),
        ],
      ),
    );
  }

  Widget _buildServices() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Servicios de emergencia',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          services.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _buildHorizontalList(services),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(List<dynamic> items) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final service = items[index];
          return _buildServiceCard(service);
        },
      ),
    );
  }

  Widget _buildServiceCard(dynamic service) {
    final String name = service['name'] ?? 'NoName';
    final String imageUrl = service['image'] ?? '';
    final String description = service['description'] ?? 'No description available';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del servicio
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset('assets/no_image.png', height: 100, fit: BoxFit.cover),
                    )
                  : Image.asset('assets/no_image.png', height: 100, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _truncateText(description, 50),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Solicitar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncateText(String text, int length) {
    return text.length > length ? '${text.substring(0, length)}...' : text;
  }
}
