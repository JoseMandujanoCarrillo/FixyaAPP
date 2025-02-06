import 'package:flutter/material.dart';
import 'package:convert/convert.dart';
import 'dart:typed_data';
import 'service_detail_screen.dart';

class ServiceCard extends StatelessWidget {
  final dynamic service;

  const ServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final imageUrl = service['imageUrl'];
    final imageBytea = service['imagebyte'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(service: service),
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
                child: _buildImageWidget(imageUrl, imageBytea),
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

  Widget _buildImageWidget(String? imageUrl, String? imageBytea) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
      );
    } else if (imageBytea != null && imageBytea.isNotEmpty) {
      return Image.memory(
        Uint8List.fromList(hex.decode(imageBytea)),
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Image.network(
      'https://i.imgur.com/FlcmJ1h.jpg',
      height: 120,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}