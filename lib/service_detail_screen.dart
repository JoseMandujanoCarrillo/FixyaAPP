import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'service_form.dart';

class ServiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceDetailScreen({Key? key, required this.service}) : super(key: key);

  @override
  _ServiceDetailScreenState createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  Map<String, dynamic>? cleaner; // Datos del cleaner asociado
  Map<String, dynamic>? ratingData; // Datos de calificaciones y comentarios

  @override
  void initState() {
    super.initState();
    _fetchCleaner();
    _fetchRatings();
    // Verifica el horario después de renderizar la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.service['schedule'] != null && widget.service['schedule'] is Map) {
        final schedule = widget.service['schedule'];
        final List<dynamic> allowedDays = schedule['days'] ?? [];
        final String allowedStartStr = schedule['startTime'] ?? "00:00";
        final String allowedEndStr = schedule['endTime'] ?? "23:59";

        final allowedStartParts = allowedStartStr.split(":");
        final allowedEndParts = allowedEndStr.split(":");
        final TimeOfDay allowedStartTime = TimeOfDay(
          hour: int.parse(allowedStartParts[0]),
          minute: int.parse(allowedStartParts[1]),
        );
        final TimeOfDay allowedEndTime = TimeOfDay(
          hour: int.parse(allowedEndParts[0]),
          minute: int.parse(allowedEndParts[1]),
        );

        final now = DateTime.now();
        final currentMinutes = now.hour * 60 + now.minute;
        final allowedStartMinutes = allowedStartTime.hour * 60 + allowedStartTime.minute;
        final allowedEndMinutes = allowedEndTime.hour * 60 + allowedEndTime.minute;

        // Mapeo para obtener el nombre del día en español.
        final weekDays = {
          1: "Lunes",
          2: "Martes",
          3: "Miércoles",
          4: "Jueves",
          5: "Viernes",
          6: "Sábado",
          7: "Domingo"
        };
        final currentDayName = weekDays[now.weekday] ?? "";

        if (!allowedDays.contains(currentDayName) ||
            currentMinutes < allowedStartMinutes ||
            currentMinutes > allowedEndMinutes) {
          final allowedDaysStr = allowedDays.join(", ");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Atención: Este servicio solo se presta de $allowedStartStr a $allowedEndStr, los días: $allowedDaysStr"),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    });
  }

  /// Consulta la ruta pública del cleaner para obtener su nombre y foto.
  Future<void> _fetchCleaner() async {
    final cleanerId = widget.service['cleanerId'];
    if (cleanerId == null) return;
    final url = 'https://apifixya.onrender.com/cleaners/$cleanerId/public';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cleaner = data;
        });
      }
    } catch (e) {
      // Manejo de errores según sea necesario.
    }
  }

  /// Consulta la calificación y comentarios del servicio.
  Future<void> _fetchRatings() async {
    final serviceId = widget.service['id'];
    if (serviceId == null) return;
    final url = 'https://apifixya.onrender.com/ratings/service/$serviceId/ratings';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          ratingData = data;
        });
      }
    } catch (e) {
      // Manejo de errores según sea necesario.
    }
  }

  /// Construye los íconos de estrellas según la calificación promedio.
  Widget _buildRatingStars(double rating) {
    int fullStars = rating.floor();
    bool hasHalf = (rating - fullStars) >= 0.5;
    int emptyStars = 5 - fullStars - (hasHalf ? 1 : 0);
    List<Widget> stars = [];
    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, color: Colors.amber, size: 20));
    }
    if (hasHalf) {
      stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 20));
    }
    for (int i = 0; i < emptyStars; i++) {
      stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 20));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }

  /// Sección que muestra las calificaciones y comentarios.
  Widget _buildRatingsSection() {
    if (ratingData == null) return const SizedBox();

    double averageRating = ratingData!['averageRating'] != null
        ? (ratingData!['averageRating'] as num).toDouble()
        : 0.0;
    int ratingsCount = ratingData!['ratingsCount'] ?? 0;
    List<dynamic> comments = ratingData!['comments'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calificaciones y Comentarios',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildRatingStars(averageRating),
                    const SizedBox(width: 10),
                    Text(
                      '$averageRating ($ratingsCount valoraciones)',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (comments.isNotEmpty) ...[
                  const Text(
                    'Comentarios:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: comments
                        .map(
                          (comment) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              comment.toString(),
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        )
                        .toList(),
                  )
                ]
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Sección genérica para mostrar un título y su valor.
  List<Widget> _buildDetailSection(String title, String value) {
    return [
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 5),
      Text(
        value,
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      ),
      const SizedBox(height: 15),
    ];
  }

  /// Sección que muestra los datos del cleaner.
  Widget _buildCleanerSection() {
    if (cleaner == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Limpieza a cargo de:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: (cleaner!['imageurl'] != null && cleaner!['imageurl'] != '')
                      ? NetworkImage(cleaner!['imageurl'])
                      : const AssetImage('assets/default_cleaner.png') as ImageProvider,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cleaner!['name'] ?? 'Sin nombre',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extraer los días de trabajo desde el schedule.
    String daysWorked = 'No especificado';
    if (widget.service['schedule'] != null &&
        widget.service['schedule'] is Map &&
        widget.service['schedule']['days'] != null) {
      final List<dynamic> days = widget.service['schedule']['days'];
      daysWorked = days.join(", ");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service['name'] ?? 'Detalle del Servicio'),
        backgroundColor: const Color.fromARGB(255, 0, 184, 255),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del servicio como banner.
            if (widget.service['imageUrl'] != null && widget.service['imageUrl'] != '')
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                child: Image.network(
                  widget.service['imageUrl'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.network(
                      'https://i.imgur.com/HbMMBc9.jpeg',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título del servicio.
                  Text(
                    widget.service['name'] ?? 'Servicio',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Secciones de detalle.
                  ..._buildDetailSection("Días de trabajo", daysWorked),
                  ..._buildDetailSection(
                    "Horario de servicio",
                    widget.service['schedule'] != null && widget.service['schedule'] is Map
                        ? "${widget.service['schedule']['startTime']} - ${widget.service['schedule']['endTime']}"
                        : '8:00am - 6:00pm',
                  ),
                  ..._buildDetailSection("Precio Total", '${widget.service['price'] ?? 'Null MXM'}'),
                  const SizedBox(height: 20),
                  // Sección del cleaner.
                  _buildCleanerSection(),
                  // Sección de calificaciones y comentarios.
                  _buildRatingsSection(),
                  // Sección de descripción.
                  const Text(
                    'Descripción',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.service['description'] ?? 'Descripción del servicio',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  // Mostrar mensaje en rojo si es CleanFast
                  if (widget.service['isCleanFast'] == true)
                    Text(
                      "El servicio es CleanFast",
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Botones de acción.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('CANCELAR', style: TextStyle(color: Colors.black)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ServiceFormScreen(service: widget.service),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 0, 184, 255),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('CONFIRMAR', style: TextStyle(color: Colors.white)),
                      ),
                    ],
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
