import 'dart:convert'; // Importa la librería para convertir JSON.
import 'package:flutter/material.dart'; // Importa los widgets principales de Flutter.
import 'package:http/http.dart' as http; // Importa la librería para hacer peticiones HTTP.
import 'package:shared_preferences/shared_preferences.dart'; // Permite manejar almacenamiento local de datos.

// Pantalla para la selección de auditores.
class AuditorSelectionScreen extends StatefulWidget {
  const AuditorSelectionScreen({Key? key}) : super(key: key);

  @override
  _AuditorSelectionScreenState createState() => _AuditorSelectionScreenState();
}

class _AuditorSelectionScreenState extends State<AuditorSelectionScreen> {
  List<dynamic> auditors = []; // Lista que almacenará los auditores obtenidos de la API.
  int page = 1; // Página actual para la paginación de datos.
  bool isLoading = false; // Indica si se está cargando información.
  bool hasMore = true; // Controla si hay más auditores por cargar.
  final ScrollController _scrollController = ScrollController(); // Controlador para la detección del desplazamiento.

  @override
  void initState() {
    super.initState();
    _fetchAuditors(); // Cargar la primera página de auditores al iniciar.
    
    // Agrega un listener al controlador de desplazamiento para cargar más auditores al llegar al final.
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 && // Detecta si está cerca del final de la lista.
          !isLoading && // Verifica que no se esté cargando previamente.
          hasMore) { // Confirma que aún haya más auditores por cargar.
        _fetchAuditors();
      }
    });
  }

  // Método para obtener la lista de auditores desde la API.
  Future<void> _fetchAuditors() async {
    setState(() {
      isLoading = true; // Indica que se está realizando una solicitud.
    });
    
    final prefs = await SharedPreferences.getInstance(); // Obtiene las preferencias compartidas.
    final token = prefs.getString('token'); // Obtiene el token almacenado.
    
    // Realiza la solicitud GET a la API con la página actual.
    final response = await http.get(
      Uri.parse('https://apifixya.onrender.com/auditors/all?page=$page'),
      headers: {'Authorization': 'Bearer $token'}, // Envía el token de autenticación.
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> fetchedAuditors = json.decode(response.body); // Decodifica la respuesta JSON.
      setState(() {
        page++; // Incrementa el número de página para futuras solicitudes.
        isLoading = false; // Finaliza el estado de carga.
        
        if (fetchedAuditors.isEmpty) {
          hasMore = false; // Si no hay más auditores, desactiva la carga adicional.
        } else {
          auditors.addAll(fetchedAuditors); // Agrega los nuevos auditores a la lista.
        }
      });
    } else {
      setState(() {
        isLoading = false; // Finaliza el estado de carga en caso de error.
      });
      print("Error al obtener auditores: ${response.statusCode}"); // Muestra el código de error en la consola.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selecciona un auditor"), // Título de la pantalla.
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0), // Aplica un padding uniforme.
        child: ListView.builder(
          controller: _scrollController, // Asigna el controlador de desplazamiento.
          itemCount: auditors.length + (hasMore ? 1 : 0), // Agrega un elemento extra si hay más auditores por cargar.
          itemBuilder: (context, index) {
            if (index < auditors.length) {
              final auditor = auditors[index]; // Obtiene el auditor actual.
              return ListTile(
                title: Text(auditor['name'] ?? 'Sin nombre'), // Muestra el nombre del auditor o un mensaje por defecto.
                subtitle: Text(auditor['email'] ?? ''), // Muestra el correo electrónico del auditor.
                onTap: () {
                  // Devuelve el ID del auditor seleccionado y cierra la pantalla.
                  Navigator.pop(context, auditor['auditor_id']);
                },
              );
            } else {
              // Muestra un indicador de carga al final de la lista mientras se obtienen más datos.
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Libera los recursos del controlador de desplazamiento.
    super.dispose();
  }
}
