import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:convert/convert.dart'; // Para manejar la conversión de hexadecimal a bytes

class ServiceDetailScreen extends StatelessWidget {
  final dynamic service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(service['name'] ?? 'Detalles del servicio'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del servicio
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: service['imageUrl'] != null && service['imageUrl'].isNotEmpty
                  ? Image.network(
                      service['imageUrl'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                          'https://i.imgur.com/FlcmJ1h.jpg',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : service['imagebyte'] != null && service['imagebyte'].isNotEmpty
                      ? Image.memory(
                          Uint8List.fromList(hex.decode(service['imagebyte'])),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          'https://i.imgur.com/FlcmJ1h.jpg',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
            ),
            const SizedBox(height: 16),

            // Título del servicio
            Text(
              service['name'] ?? 'Sin nombre',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Precio del servicio
            Text(
              service['price'] != null ? '\$${service['price']}' : 'Consultar',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Descripción del servicio
            const Text(
              '¿Tu habitación necesita una limpieza urgente? ¡No te preocupes! Estoy aquí para ofrecerte una solución rápida y efectiva.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            // Horario del servicio
            const Text(
              'Horario:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lunes a Viernes: 7:00 a.m - 7:30 p.m\nSábado y Domingo: 9:00 a.m - 8:30 p.m',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            // Calificaciones de otros usuarios
            const Text(
              'Calificación por otros usuarios:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildUserReview('User1', 'El servicio fue de la mejor y la persona fue muy amable.'),
            _buildUserReview('User2', 'No fue del todo satisfactorio, el personal llegó tarde y no hizo bien el trabajo.'),
            const SizedBox(height: 16),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Acción para cancelar
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Acción para solicitar
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    'SOLICITAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar una reseña de usuario
  Widget _buildUserReview(String user, String review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            review,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}