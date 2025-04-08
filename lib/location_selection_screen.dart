import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Pantalla de selección de ubicación usando Google Maps con buscador y persistencia de ubicaciones anteriores.
class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({Key? key}) : super(key: key);

  @override
  _LocationSelectionScreenState createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;
  final TextEditingController _searchController = TextEditingController();

  // Lista para almacenar ubicaciones anteriores confirmadas.
  final List<Map<String, dynamic>> _previousLocations = [];

  // Controlador de animación para el search bar.
  double _searchOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _loadPreviousLocations();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  /// Busca una dirección y actualiza la ubicación seleccionada.
  Future<void> _searchAddress(String query) async {
    // Reemplaza con tu API key de Google Maps
    const String apiKey = 'AIzaSyBzCGzBz5OJc_GSnL3AkaWPVMEpxWHgRxY';
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['results'].isNotEmpty) {
        final location = jsonResponse['results'][0]['geometry']['location'];
        final double lat = location['lat'];
        final double lng = location['lng'];
        setState(() {
          _selectedLocation = LatLng(lat, lng);
          _searchOpacity = 0.8;
        });
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se encontró la dirección.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al buscar la dirección.")),
      );
    }
  }

  /// Realiza una consulta de geocodificación inversa para obtener la dirección a partir de las coordenadas.
  Future<String> _getAddressFromLatLng(LatLng location) async {
    // Reemplaza con tu API key de Google Maps
    const String apiKey = 'AIzaSyBzCGzBz5OJc_GSnL3AkaWPVMEpxWHgRxY';
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['results'].isNotEmpty) {
        return jsonResponse['results'][0]['formatted_address'];
      }
    }
    // En caso de error, se retorna una cadena con las coordenadas.
    return "Ubicación: ${location.latitude}, ${location.longitude}";
  }

  /// Confirma la ubicación seleccionada, la guarda en la lista y persiste en el almacenamiento local.
  Future<void> _confirmLocation() async {
    if (_selectedLocation != null) {
      // Se obtiene la dirección usando geocodificación inversa.
      String address = await _getAddressFromLatLng(_selectedLocation!);
      setState(() {
        _previousLocations.add({
          'address': address,
          'lat': _selectedLocation!.latitude,
          'lng': _selectedLocation!.longitude,
        });
      });
      _savePreviousLocations();
      Navigator.pop(context, address);
    }
  }

  /// Muestra un modal con las ubicaciones anteriores guardadas.
  void _showPreviousLocations() {
    if (_previousLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay ubicaciones anteriores.")),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            itemCount: _previousLocations.length,
            itemBuilder: (context, index) {
              final location = _previousLocations[index];
              return ListTile(
                leading: const Icon(Icons.place),
                title: Text(location['address']),
                subtitle: Text('Lat: ${location['lat']}, Lng: ${location['lng']}'),
                onTap: () {
                  final lat = location['lat'];
                  final lng = location['lng'];
                  setState(() {
                    _selectedLocation = LatLng(lat, lng);
                  });
                  _mapController.animateCamera(
                    CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
                  );
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Guarda la lista de ubicaciones anteriores en SharedPreferences.
  Future<void> _savePreviousLocations() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> locationsJson =
        _previousLocations.map((loc) => jsonEncode(loc)).toList();
    await prefs.setStringList('previous_locations', locationsJson);
  }

  /// Carga las ubicaciones anteriores desde SharedPreferences.
  Future<void> _loadPreviousLocations() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? locationsJson = prefs.getStringList('previous_locations');
    if (locationsJson != null) {
      setState(() {
        _previousLocations.clear();
        _previousLocations.addAll(
          locationsJson.map((item) => jsonDecode(item) as Map<String, dynamic>).toList(),
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se envuelve GoogleMap en un ClipRRect para darle bordes redondeados sutiles.
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selecciona tu ubicación"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showPreviousLocations,
          ),
        ],
      ),
      body: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(20.9671, -89.6237), // Mérida, Yucatán
                zoom: 15,
              ),
              onTap: _onTap,
              markers: _selectedLocation != null
                  ? {
                      Marker(
                        markerId: const MarkerId("selected"),
                        position: _selectedLocation!,
                      )
                    }
                  : {},
            ),
          ),
          // Buscador de dirección en la parte superior.
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _searchOpacity,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Buscar dirección",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _searchAddress(_searchController.text),
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: _searchAddress,
                ),
              ),
            ),
          ),
          // Botón para confirmar la ubicación en la parte inferior.
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _confirmLocation,
              icon: const Icon(Icons.check),
              label: const Text("Confirmar ubicación"),
            ),
          ),
        ],
      ),
    );
  }
}
