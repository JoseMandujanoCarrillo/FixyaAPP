import 'package:flutter/material.dart';
import 'service_form.dart';

class ServiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  _ServiceDetailScreenState createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Después de que se haya renderizado la pantalla, se verifica el horario.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.service['schedule'] != null &&
          widget.service['schedule'] is Map) {
        final schedule = widget.service['schedule'];
        final List<dynamic> allowedDays = schedule['days'] ?? [];
        final String allowedStartStr = schedule['startTime'] ?? "00:00";
        final String allowedEndStr = schedule['endTime'] ?? "23:59";

        // Se asume formato "HH:mm"
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
        final allowedStartMinutes =
            allowedStartTime.hour * 60 + allowedStartTime.minute;
        final allowedEndMinutes =
            allowedEndTime.hour * 60 + allowedEndTime.minute;

        // Mapeo para obtener el nombre del día en español
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

        // Si el día actual no está permitido o la hora no se encuentra en el rango permitido:
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Row(
                children: [
                  const Icon(Icons.cleaning_services,
                      size: 30, color: Color.fromARGB(255, 0, 184, 255)),
                  const SizedBox(width: 10),
                  Text(
                    "WC",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 148, 214, 255),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Servicio a solicitar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          widget.service['imageUrl'] ?? '',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.service['name'] ?? 'Limpieza',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.service['description'] ??
                                  'Descripción del servicio',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ..._buildDetailSection("Realización del servicio", "12/09/2024"),
              ..._buildDetailSection(
                  "Hora",
                  widget.service['schedule'] != null &&
                          widget.service['schedule'] is Map
                      ? "${widget.service['schedule']['startTime']} - ${widget.service['schedule']['endTime']}"
                      : '8:00am - 6:00pm'),
              ..._buildDetailSection("Precio Total",
                  '${widget.service['price'] ?? 'Null MXM'}'),
              ..._buildDetailSection("Descripción",
                  '${widget.service['description'] ?? 'Descripción del servicio'}'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('CANCELAR',
                        style: TextStyle(color: Colors.black)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ServiceFormScreen(service: widget.service),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(255, 0, 184, 255),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('CONFIRMAR',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
}
