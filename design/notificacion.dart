import 'package:flutter/material.dart';
import 'actividad.dart';

class NotificacionesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> notificaciones = [
    {
      "fecha": "23/Feb/2025",
      "titulo": "¡En hora buena!, Tu solicitud del día 12 de febrero ha sido ",
      "estado": "aceptada",
      "color": Colors.green,
    },
    {
      "fecha": "23/Feb/2025",
      "titulo": "Lo sentimos, su solicitud del día 14 de febrero ha sido ",
      "estado": "rechazada",
      "color": Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  ListView.builder(
                    itemCount: notificaciones.length,
                    itemBuilder: (context, index) {
                      return _buildNotificacionCard(context, notificaciones[index]);
                    },
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        // Aquí puedes agregar la funcionalidad para eliminar notificaciones
                      },
                      child: Image.asset("assets/iconos/icono15.png", width: 31, height: 31),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 100,
      color: Color(0xFF94D6FF),
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, size: 30, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          Spacer(),
        ],
      ),
    );
  }

  Widget _buildNotificacionCard(BuildContext context, Map<String, dynamic> notificacion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notificacion["fecha"],
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => HistorialSoliScreen()));
          },
          child: Card(
            color: Colors.grey[300],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: 16),
                  children: [
                    TextSpan(text: notificacion["titulo"]),
                    TextSpan(
                      text: notificacion["estado"],
                      style: TextStyle(color: notificacion["color"], fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
