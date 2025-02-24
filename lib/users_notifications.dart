import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Modelo de propuesta
class Proposal {
  final int id;
  final int serviceId;
  final int userId;
  final DateTime date;
  final String status;
  final String direccion;
  final String descripcion;
  final bool usuarioEnCasa;
  final String tipoDeServicio;
  final bool servicioConstante;
  final DateTime createdAt;
  final DateTime updatedAt;

  Proposal({
    required this.id,
    required this.serviceId,
    required this.userId,
    required this.date,
    required this.status,
    required this.direccion,
    required this.descripcion,
    required this.usuarioEnCasa,
    required this.tipoDeServicio,
    required this.servicioConstante,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      id: json['id'],
      serviceId: json['serviceId'],
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      status: json['status'],
      direccion: json['direccion'],
      // En el JSON la propiedad se llama "Descripcion" (con D mayúscula)
      descripcion: json['Descripcion'],
      usuarioEnCasa: json['UsuarioEnCasa'],
      tipoDeServicio: json['tipodeservicio'],
      servicioConstante: json['servicioConstante'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Proposal> proposals = [];
  bool isLoading = true;
  String? token; // El token se cargará desde SharedPreferences

  @override
  void initState() {
    super.initState();
    loadTokenAndFetchProposals();
  }

  // Recupera el token desde SharedPreferences y, si existe, obtiene las propuestas.
  Future<void> loadTokenAndFetchProposals() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    if (token != null) {
      fetchProposals();
    } else {
      // En caso de no tener token, podrías redirigir al login o mostrar un mensaje.
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró token. Por favor, inicia sesión.')),
      );
    }
  }

  // Función para obtener las propuestas desde la API utilizando el token obtenido.
  Future<void> fetchProposals() async {
    final url = 'https://apifixya.onrender.com/proposals/my?size=40';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> proposalsJson = data['proposals'];
        List<Proposal> fetchedProposals = proposalsJson
            .map((json) => Proposal.fromJson(json))
            .toList();

        // Filtrar las propuestas que NO estén en "pending"
        fetchedProposals = fetchedProposals
            .where((proposal) => proposal.status.toLowerCase() != 'pending')
            .toList();

        // Ordenar por updatedAt (más reciente primero)
        fetchedProposals.sort(
          (a, b) => b.updatedAt.compareTo(a.updatedAt),
        );

        setState(() {
          proposals = fetchedProposals;
          isLoading = false;
        });
      } else {
        print('Error al obtener las propuestas: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Lógica para archivar una propuesta
  void archiveProposal(Proposal proposal) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notificación archivada', style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
      ),
    );
  }

  // Lógica para eliminar una propuesta
  void deleteProposal(Proposal proposal) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notificación eliminada', style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Notificaciones', style: TextStyle(color: Colors.black)),
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : proposals.isEmpty
              ? const Center(child: Text('No hay notificaciones', style: TextStyle(color: Colors.black)))
              : ListView.builder(
                  itemCount: proposals.length,
                  itemBuilder: (context, index) {
                    final proposal = proposals[index];
                    return Dismissible(
                      key: Key(proposal.id.toString()),
                      // Permitir deslizar en ambas direcciones
                      direction: DismissDirection.horizontal,
                      // Fondo para swipe right (inicio → fin): eliminar
                      background: Container(
                        color: const Color.fromARGB(255, 255, 0, 0), // Tonalidad Rojo
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(Icons.delete, color: Colors.black),
                      ),
                      // Fondo para swipe left (fin → inicio): archivar
                      secondaryBackground: Container(
                        color: Colors.lightBlueAccent, // Tonalidad azul claro
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.archive, color: Colors.black),
                      ),
                      // Confirmamos la acción según la dirección del swipe
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          // Deslizado a la derecha → eliminar (se pide confirmación)
                          final bool? confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.white,
                              title: const Text('Confirmar eliminación', style: TextStyle(color: Colors.black)),
                              content: const Text(
                                '¿Deseas eliminar esta notificación? Esta acción es irreversible.',
                                style: TextStyle(color: Colors.black),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancelar', style: TextStyle(color: Colors.black)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Eliminar', style: TextStyle(color: Colors.black)),
                                ),
                              ],
                            ),
                          );
                          return confirm == true;
                        } else if (direction == DismissDirection.endToStart) {
                          // Deslizado a la izquierda → archivar (no se pide confirmación)
                          return true;
                        }
                        return false;
                      },
                      onDismissed: (direction) {
                        // Eliminamos el item de la lista para que no vuelva a aparecer
                        setState(() {
                          proposals.removeAt(index);
                        });
                        if (direction == DismissDirection.startToEnd) {
                          // Acción de eliminación
                          deleteProposal(proposal);
                        } else if (direction == DismissDirection.endToStart) {
                          // Acción de archivado
                          archiveProposal(proposal);
                        }
                      },
                      child: ListTile(
                        title: Text(proposal.descripcion, style: const TextStyle(color: Colors.black)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(proposal.direccion, style: const TextStyle(color: Colors.black)),
                            Text('Actualizado: ${proposal.updatedAt}', style: const TextStyle(color: Colors.black)),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
