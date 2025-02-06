import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSelectionScreen extends StatefulWidget {
  @override
  _LocationSelectionScreenState createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      // Simulamos obtener la dirección a partir de la latitud y longitud
      String address = "Ubicación: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}";
      Navigator.pop(context, address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Selecciona tu ubicación")),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(20.9671, -89.6237), // Mérida, Yucatán (puedes cambiarlo)
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
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _confirmLocation,
              child: const Text("Confirmar ubicación"),
            ),
          ),
        ],
      ),
    );
  }
}
