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
          // Se asume que cada propuesta tiene un 'id'
          final int proposalId = proposal['id'];
          if (!_notifiedProposalIds.contains(proposalId)) {
            _notifiedProposalIds.add(proposalId);
            // Agrega la notificación a la lista local
            setState(() {
              notifications.add({
                'id': proposalId,
                'title': 'Nueva propuesta',
                'body': 'Tienes una nueva propuesta: ${proposal['description'] ?? ''}',
                'timestamp': DateTime.now().toIso8601String(),
              });
            });
            // Muestra la notificación en el dispositivo
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navega a la pantalla para añadir servicio y, si se añade uno nuevo, actualiza la lista.
          final result = await Navigator.pushNamed(context, '/addService');
          if (result == true) {
            await _getServices();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
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
