import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'service_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> allServices = [];
  List<dynamic> filteredServices = [];
  bool _isLoading = true;
  int _page = 1;
  final int _pageSize = 10;
  bool _hasMore = true;

  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void initState() {
    super.initState();
    _loadServices();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Cargar servicios (paginación)
  Future<void> _loadServices() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://apifixya.onrender.com/services?page=$_page&size=$_pageSize'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          allServices.addAll(data['data']);
          // Si la búsqueda está vacía, mostramos todos
          filteredServices = searchController.text.isEmpty
              ? List.from(allServices)
              : _filterServicesByQuery(searchController.text);
          _isLoading = false;
          _hasMore = data['data'].length == _pageSize;
        });
        _fadeController.forward(from: 0.0);
      } else {
        throw Exception('Error al cargar los servicios: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Filtrar servicios según el texto de búsqueda
  List<dynamic> _filterServicesByQuery(String query) {
    final q = query.toLowerCase();
    return allServices.where((service) {
      final name = (service['name'] ?? '').toLowerCase();
      final description = (service['description'] ?? '').toLowerCase();
      return name.contains(q) || description.contains(q);
    }).toList();
  }

  void _onSearchChanged() {
    final query = searchController.text;
    setState(() {
      filteredServices = query.isEmpty
          ? List.from(allServices)
          : _filterServicesByQuery(query);
    });
  }

  // Cargar más servicios para scroll infinito o si la búsqueda no tuvo resultados
  Future<void> _loadMoreServices() async {
    if (!_hasMore) return;
    setState(() {
      _page++;
    });
    await _loadServices();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos el color primario del tema para la AppBar
    final appBarColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Servicios'),
        backgroundColor: appBarColor,
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
              onChanged: (value) => _onSearchChanged(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: filteredServices.isEmpty
                        ? Column(
                            key: const ValueKey('empty'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'No se encontraron servicios',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              if (_hasMore)
                                ElevatedButton(
                                  onPressed: _loadMoreServices,
                                  child: const Text('Cargar más'),
                                ),
                            ],
                          )
                        : NotificationListener<ScrollNotification>(
                            key: const ValueKey('list'),
                            onNotification: (ScrollNotification scrollInfo) {
                              if (scrollInfo.metrics.pixels ==
                                      scrollInfo.metrics.maxScrollExtent &&
                                  _hasMore) {
                                _loadMoreServices();
                              }
                              return true;
                            },
                            child: ListView.builder(
                              itemCount: filteredServices.length +
                                  (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == filteredServices.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                final service = filteredServices[index];
                                return FadeTransition(
                                  opacity: _fadeController,
                                  child: _buildServiceCard(service),
                                );
                              },
                            ),
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
                ServiceDetailScreen(service: service),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agregamos un Hero para transiciones entre la lista y el detalle
            Hero(
              tag: 'serviceImage_${service['id']}',
              child: ClipRRect(
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
