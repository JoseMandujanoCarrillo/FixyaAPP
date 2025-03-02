import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cleaners_profile.dart';
import 'proposalsCleaners.dart';

class CleanersHome extends StatefulWidget {
  const CleanersHome({Key? key}) : super(key: key);

  @override
  _CleanersHomeState createState() => _CleanersHomeState();
}

class _CleanersHomeState extends State<CleanersHome> {
  List<dynamic> services = [];
  String userName = "Usuario";
  String userEmail = "";
  double? latitude;
  double? longitude;
  int? auditorId; // FK del auditor asignado (null si no asignado)
  bool isVerifiqued = false;
  bool _isLoading = true;
  int _selectedIndex = 0;

  // Lista de notificaciones locales (para la pantalla de notificaciones)
  List<dynamic> notifications = [];

  // Plugin para notificaciones locales
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Timer para chequear nuevas propuestas periódicamente
  Timer? _proposalsTimer;

  // Set para almacenar los IDs de propuestas ya notificadas y evitar duplicados
  Set<int> _notifiedProposalIds = {};

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadNotifiedProposalIds(); // Carga los IDs notificados persistentes
    _loadData();

    // Inicia el timer para chequear propuestas cada 30 segundos
    _proposalsTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _checkForNewProposals());
  }

  @override
  void dispose() {
    _proposalsTimer?.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // Configuración para iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    // Configuración general
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Cargar los IDs notificados de SharedPreferences
  Future<void> _loadNotifiedProposalIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? storedIds = prefs.getStringList('notifiedProposalIds');
    if (storedIds != null) {
      _notifiedProposalIds = storedIds.map((id) => int.parse(id)).toSet();
    }
  }

  // Guardar los IDs notificados en SharedPreferences
  Future<void> _saveNotifiedProposalIds() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      'notifiedProposalIds',
      _notifiedProposalIds.map((id) => id.toString()).toList(),
    );
  }

  Future<void> _loadData() async {
    await _getUserData();
    await _getServices();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/cleaners/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userName = data['name'] ?? 'Usuario';
          userEmail = data['email'] ?? '';
          // Se asume que el endpoint devuelve 'auditor_id' e 'is_verifiqued'
          auditorId = data['auditor_id'];
          isVerifiqued = data['is_verifiqued'] ?? false;
          latitude = data['latitude'];
          longitude = data['longitude'];
        });
      }
    } catch (e) {
      print("Error al obtener datos del cleaner: $e");
    }
  }

  Future<void> _getServices() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/cleaners/me/services'),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json'
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          services = List<dynamic>.from(data);
        });
      } else {
        print("Error al obtener servicios: ${response.statusCode}");
      }
    } catch (e) {
      print("Error al obtener servicios: $e");
    }
  }

  // Chequea periódicamente si hay nuevas propuestas
  Future<void> _checkForNewProposals() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/proposals/for-cleaner'),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json'
        },
      );
      if (response.statusCode == 200) {
        final proposals = json.decode(response.body) as List;
        for (var proposal in proposals) {
          final int proposalId = proposal['id'];
          if (!_notifiedProposalIds.contains(proposalId)) {
            _notifiedProposalIds.add(proposalId);
            await _saveNotifiedProposalIds(); // Guarda el ID notificado

            setState(() {
              notifications.add({
                'id': proposalId,
                'title': 'Nueva propuesta',
                'body': 'Tienes una nueva propuesta: ${proposal['description'] ?? ''}',
                'timestamp': DateTime.now().toIso8601String(),
              });
            });
            _showLocalNotification(
              proposalId,
              'Nueva propuesta',
              'Tienes una nueva propuesta.',
            );
          }
        }
      } else {
        print("Error al obtener propuestas: ${response.statusCode}");
      }
    } catch (e) {
      print("Error al chequear nuevas propuestas: $e");
    }
  }

  Future<void> _showLocalNotification(int id, String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'proposal_channel_id',
      'Propuestas',
      channelDescription: 'Notificaciones de nuevas propuestas',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: 'propuesta_$id',
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Muestra el diálogo de selección de auditor con infinite scroll
  Future<void> _showAuditorSelectionDialog() async {
    final selectedAuditorId = await showDialog<int>(
      context: context,
      builder: (context) => const AuditorSelectionDialog(),
    );
    if (selectedAuditorId != null) {
      _requestVerification(selectedAuditorId);
    }
  }

  /// Envía la solicitud de verificación actualizando el cleaner sin modificar la contraseña
  Future<void> _requestVerification(int selectedAuditorId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final Map<String, dynamic> body = {
      "name": userName,
      "email": userEmail,
      "latitude": latitude ?? 0,
      "longitude": longitude ?? 0,
      // Aquí se supone que la verificación se realiza en otro lugar,
      // por lo que se mantiene is_verifiqued como false hasta que sea true externamente.
      "is_verifiqued": false,
      "auditor_id": selectedAuditorId,
    };

    try {
      final response = await http.put(
        Uri.parse('https://apifixya.onrender.com/cleaners/me'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        // Actualizamos el estado local luego de seleccionar el auditor.
        // El botón "Solicitar verificación" desaparecerá porque auditorId ya no es null.
        setState(() {
          auditorId = selectedAuditorId;
          // isVerifiqued se mantiene en false hasta que se actualice en otro proceso.
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Auditor seleccionado. Verificación pendiente.")),
        );
      } else {
        print("Error en la solicitud de verificación: ${response.statusCode}");
      }
    } catch (e) {
      print("Error en la solicitud de verificación: $e");
    }
  }

  /// Construye el contenido principal (lista de servicios)
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hola, $userName!",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Tus Servicios",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          services.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    return _buildServiceCard(services[index]);
                  },
                )
              : const Text("No tienes servicios asignados."),
        ],
      ),
    );
  }

  Widget _buildServiceCard(dynamic service) {
    final imageUrl = service['imageUrl'];
    final imageBytea = service['imagebyte'];
    final name = service['name'] ?? 'Sin nombre';
    final description = service['description'] ?? 'Sin descripción';

    // Formatea el precio según la localidad.
    String priceText;
    if (service['price'] is num) {
      final double price = (service['price'] as num).toDouble();
      final locale = Localizations.localeOf(context).toString();
      priceText = NumberFormat.simpleCurrency(locale: locale).format(price);
    } else {
      priceText = service['price']?.toString() ?? 'Precio no disponible';
    }

    return GestureDetector(
      onTap: () {
        // Navegar a la pantalla de detalle del servicio si se desea.
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : imageBytea != null && imageBytea.isNotEmpty
                        ? Image.memory(
                            Uint8List.fromList(hex.decode(imageBytea)),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.grey,
                            child: const Icon(Icons.image, size: 60),
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      priceText,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.grey),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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

  /// Construye el contenido según el índice seleccionado en el BottomNavigationBar
  Widget _buildPageContent() {
    switch (_selectedIndex) {
      case 1:
        return const ProposalsCleaners(); // Pantalla de propuestas para el cleaner.
      case 2:
        return const Center(child: Text('Menú'));
      case 3:
        return const CleanersProfile();
      default:
        return _buildHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.black),
            onPressed: () {},
          ),
          // Botón de notificaciones (campanita)
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsScreen(
                    notifications: notifications,
                    onNotificationsUpdated: (updatedNotifications) {
                      setState(() {
                        notifications = updatedNotifications;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPageContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color.fromARGB(255, 148, 214, 255),
        unselectedItemColor: const Color.fromARGB(153, 153, 153, 153),
        backgroundColor: Colors.white,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Propuestas'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menú'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
      // Lógica del botón flotante:
      // - Si auditorId es null, se muestra el botón "Solicitar verificación".
      // - Si auditorId no es null y isVerifiqued es true, se muestra el botón para agregar servicio.
      // - Si auditorId no es null y isVerifiqued es false, no se muestra ningún botón.
      floatingActionButton: (auditorId == null)
          ? FloatingActionButton.extended(
              onPressed: _showAuditorSelectionDialog,
              label: const Text("Solicitar verificación"),
              icon: const Icon(Icons.verified_user),
            )
          : (isVerifiqued
              ? FloatingActionButton(
                  onPressed: () async {
                    // Navega a la pantalla para añadir servicio y, si se añade uno nuevo, actualiza la lista.
                    final result = await Navigator.pushNamed(context, '/addService');
                    if (result == true) {
                      await _getServices();
                    }
                  },
                  child: const Icon(Icons.add),
                )
              : null),
    );
  }
}

/// Widget para mostrar un diálogo con infinite scrolling de auditores
class AuditorSelectionDialog extends StatefulWidget {
  const AuditorSelectionDialog({Key? key}) : super(key: key);

  @override
  _AuditorSelectionDialogState createState() => _AuditorSelectionDialogState();
}

class _AuditorSelectionDialogState extends State<AuditorSelectionDialog> {
  List<dynamic> auditors = [];
  int page = 1;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAuditors();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        _fetchAuditors();
      }
    });
  }

  Future<void> _fetchAuditors() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    // Ajusta la URL y parámetros según tu API.
    final response = await http.get(
      Uri.parse('https://apifixya.onrender.com/auditors/all'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> fetchedAuditors = json.decode(response.body);
      setState(() {
        page++;
        isLoading = false;
        if (fetchedAuditors.isEmpty) {
          hasMore = false;
        } else {
          auditors.addAll(fetchedAuditors);
        }
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print("Error al obtener auditores: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Selecciona un auditor"),
      content: Container(
        width: double.maxFinite,
        height: 400, // Altura fija para el diálogo
        child: ListView.builder(
          controller: _scrollController,
          itemCount: auditors.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < auditors.length) {
              final auditor = auditors[index];
              return ListTile(
                title: Text(auditor['name'] ?? 'Sin nombre'),
                subtitle: Text(auditor['email'] ?? ''),
                onTap: () {
                  Navigator.pop(context, auditor['auditor_id']);
                },
              );
            } else {
              // Indicador de carga al final de la lista
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
    _scrollController.dispose();
    super.dispose();
  }
}

/// Pantalla de notificaciones donde se muestran todas las notificaciones locales.
class NotificationsScreen extends StatefulWidget {
  final List<dynamic> notifications;
  final Function(List<dynamic>) onNotificationsUpdated;

  const NotificationsScreen({
    Key? key,
    required this.notifications,
    required this.onNotificationsUpdated,
  }) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<dynamic> _notifications;

  @override
  void initState() {
    super.initState();
    // Clona la lista para trabajar localmente
    _notifications = List.from(widget.notifications);
  }

  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
    widget.onNotificationsUpdated(_notifications);
  }

  void _clearNotifications() {
    setState(() {
      _notifications.clear();
    });
    widget.onNotificationsUpdated(_notifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearNotifications,
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(child: Text('No hay notificaciones'))
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return ListTile(
                  title: Text(notification['title']),
                  subtitle: Text(notification['body']),
                  trailing: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _deleteNotification(index),
                  ),
                );
              },
            ),
    );
  }
}
