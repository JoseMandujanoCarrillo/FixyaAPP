import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'service_detail_screen.dart'; // Importar la pantalla de detalles
import 'package:convert/convert.dart';
import 'dart:typed_data'; // Para Uint8List

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> allServices = [];
  List<dynamic> filteredServices = [];
  bool _isLoading = true;
  int _page = 1;
  final int _pageSize = 10;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
    searchController.addListener(_onSearchChanged); // Escuchar cambios en el campo de búsqueda
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged); // Dejar de escuchar cambios
    searchController.dispose();
    super.dispose();
  }

  // Cargar servicios
  Future<void> _loadServices() async {
    try {
      final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/services?page=$_page&size=$_pageSize'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          allServices.addAll(data['data']);
          filteredServices = List.from(allServices); // Inicialmente, mostrar todos los servicios
          _isLoading = false;
          _hasMore = data['data'].length == _pageSize;
        });
      } else {
        throw Exception('Error al cargar los servicios: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Filtrar servicios según el texto de búsqueda
  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        // Si no hay texto de búsqueda, mostrar todos los servicios
        filteredServices = List.from(allServices);
      } else {
        // Filtrar servicios por nombre o descripción
        filteredServices = allServices
            .where((service) =>
                (service['name']?.toLowerCase().contains(query) ?? false) ||
                (service['description']?.toLowerCase().contains(query) ?? false))
            .toList();
      }
    });
  }

  // Cargar más servicios para el scroll infinito
  Future<void> _loadMoreServices() async {
    if (!_hasMore) return;

    setState(() {
      _page++;
    });

    await _loadServices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Servicios'),
        backgroundColor: Color.fromARGB(255, 148, 214, 255),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar servicios...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                // Llamar al filtrado cada vez que el texto cambie
                _onSearchChanged();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredServices.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron servicios',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels ==
                                  scrollInfo.metrics.maxScrollExtent &&
                              _hasMore) {
                            _loadMoreServices();
                          }
                          return true;
                        },
                        child: ListView.builder(
                          itemCount: filteredServices.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredServices.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final service = filteredServices[index];
                            return _buildServiceCard(service);
                          },
                        ),
                      ),
          ),
        ],
      ),
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                          'https://i.imgur.com/FlcmJ1h.jpg',
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : imageBytea != null && imageBytea.isNotEmpty
                      ? Image.memory(
                          Uint8List.fromList(hex.decode(imageBytea)),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          'https://i.imgur.com/FlcmJ1h.jpg',
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['name'] ?? 'Sin nombre',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service['description'] ?? 'Sin descripción',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service['price'] != null
                        ? '\$${service['price']}'
                        : 'Consultar',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
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