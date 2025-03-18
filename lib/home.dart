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
import 'package:connectivity_plus/connectivity_plus.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'service_detail_screen.dart';
import 'users_notifications.dart';
import 'Userchat.dart';

// Instancia global del plugin de notificaciones
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
int _notificationCounter = 0; // Contador para IDs de notificación

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> services1 = [];
  List<dynamic> services2 = [];
  String userName = "Usuario";
  bool _isLoading = true;
  int _selectedIndex = 0;
  Timer? _notificationTimer; // Timer para comprobar notificaciones

  // Mapa persistente para estados notificados (clave: id propuesta, valor: estado)
  final Map<int, String> _notifiedProposalStatuses = {};

  @override
  void initState() {
    super.initState();
    // Verificar conectividad y redirigir al login si no hay internet
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool isConnected = await _checkInternetConnectivity();
      if (!isConnected) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _checkLogin();
        _loadData();
      }
    });
    _loadNotifiedStatuses();
    startCheckingNotifications();
  }

  @override
  void dispose() {
    cancelCheckingNotifications();
    super.dispose();
  }

  // Verifica si hay conexión a Internet
  Future<bool> _checkInternetConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Función auxiliar para manejar token expirado o errores de usuario
  Future<void> _handleUnauthorized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _loadData() async {
    await _getUserData();
    await _getServices();
    setState(() {
      _isLoading = false;
    });
  }

  // Modificación: Redirige al login si ocurre algún error o los datos del usuario son inválidos
  Future<void> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      await _handleUnauthorized();
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 401) {
        await _handleUnauthorized();
        return;
      }
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Verifica que los datos del usuario sean válidos
        if (data == null || data['name'] == null) {
          await _handleUnauthorized();
          return;
        }
        setState(() {
          userName = data['name'];
        });
      } else {
        await _handleUnauthorized();
      }
    } catch (e) {
      // Si ocurre cualquier error al obtener los datos, redirige al login
      await _handleUnauthorized();
    }
  }

  // Método para obtener las calificaciones y calcular el promedio por servicio
  Future<Map<int, double>> _getRatings() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return {};

    try {
      final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/ratings'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ratingsList = List<dynamic>.from(data['ratings']);
        // Agrupar las calificaciones por serviceId
        Map<int, List<double>> ratingsGrouped = {};
        for (var item in ratingsList) {
          final int serviceId = item['serviceId'];
          final double ratingValue = (item['rating'] as num).toDouble();
          ratingsGrouped.putIfAbsent(serviceId, () => []).add(ratingValue);
        }
        // Calcular el promedio de calificación para cada servicio
        Map<int, double> averageRatings = {};
        ratingsGrouped.forEach((serviceId, ratings) {
          final avg = ratings.reduce((a, b) => a + b) / ratings.length;
          averageRatings[serviceId] = avg;
        });
        return averageRatings;
      }
    } catch (e) {
      print("Error fetching ratings: $e");
    }
    return {};
  }

  // Modificar _getServices para ordenar los servicios "Populares" por calificación
  Future<void> _getServices() async {
    try {
      final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/services?page=1&size=99990'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final allServices = List<dynamic>.from(data['data']);
        final half = allServices.length ~/ 2;
        final cleanFastServices = allServices.sublist(0, half);
        var popularServices = allServices.sublist(half);
        
        // Obtener el mapa de calificaciones (serviceId -> promedio)
        Map<int, double> ratingsMap = await _getRatings();
        
        // Ordenar los servicios populares de mayor a menor según la calificación
        popularServices.sort((a, b) {
          final double ratingA = ratingsMap[a['id']] ?? 0;
          final double ratingB = ratingsMap[b['id']] ?? 0;
          return ratingB.compareTo(ratingA);
        });

        setState(() {
          services1 = cleanFastServices;
          services2 = popularServices;
        });
      }
    } catch (e) {
      print("Error fetching services: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Define _buildPageContent solo una vez y envuélvelo en AnimatedSwitcher para transiciones suaves
  Widget _buildPageContent() {
    Widget page;
    switch (_selectedIndex) {
      case 1:
        page = const ProposalsPage();
        break;
      case 2:
        page = const ChatListPage();
        break;
      case 3:
        page = const ProfileScreen();
        break;
      default:
        page = _buildHomeContent();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: page,
    );
  }

  Widget _buildHomeContent() {
    // Filtrar los servicios para la sección Clean Fast
    final cleanFastServices = services1
        .where((service) => service['isCleanFast'] == true)
        .toList();

    return SingleChildScrollView(
      key: const ValueKey('homeContent'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hola, $userName!",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            "Clean Fast",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          _buildHorizontalList(cleanFastServices),
          const SizedBox(height: 20),
          const Text(
            "Populares",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          _buildHorizontalList(services2),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(List<dynamic> services) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        itemBuilder: (context, index) {
          return _buildServiceCard(services[index]);
        },
      ),
    );
  }

  Widget _buildServiceCard(dynamic service) {
    final imageUrl = service['imageUrl'];
    final imageBytea = service['imagebyte'];
    final name = service['name'] ?? 'Sin nombre';
    final description = service['description'] ?? 'Sin descripción';

    String priceText;
    if (service['price'] is num) {
      final double price = (service['price'] as num).toDouble();
      final locale = Localizations.localeOf(context).toString();
      priceText = NumberFormat.simpleCurrency(locale: locale).format(price);
    } else {
      priceText = service['price']?.toString() ?? 'Precio no disponible';
    }

    // Animación de aparición y efecto de pulsación usando TweenAnimationBuilder e InkWell
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailScreen(service: service),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 200,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Card(
            color: const Color(0xFFC5E7F2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  // Se añade Hero para animar la transición de la imagen
                  child: Hero(
                    tag: 'serviceImage_${service["id"]}',
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.broken_image, size: 120),
                          )
                        : imageBytea != null && imageBytea.isNotEmpty
                            ? Image.memory(
                                Uint8List.fromList(hex.decode(imageBytea)),
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image, size: 120),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priceText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Métodos para notificaciones persistentes ---

  Future<void> _loadNotifiedStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('notifiedProposalStatuses');
    if (jsonString != null) {
      final Map<String, dynamic> map = jsonDecode(jsonString);
      _notifiedProposalStatuses.clear();
      map.forEach((key, value) {
        _notifiedProposalStatuses[int.parse(key)] = value.toString();
      });
    }
  }

  Future<void> _saveNotifiedStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> mapToSave = _notifiedProposalStatuses
        .map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString('notifiedProposalStatuses', jsonEncode(mapToSave));
  }

  Future<void> showStatusNotification(String message) async {
    final int notificationId = _notificationCounter++;
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'status_channel',
      'Status Notifications',
      channelDescription: 'Notificaciones para cambios de estado',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'Cambio de Estado',
      message,
      platformChannelSpecifics,
      payload: 'status_payload',
    );
  }

  Future<void> checkNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      print("No hay token disponible");
      return;
    }

    final url = Uri.parse('https://apifixya.onrender.com/proposals/my');
    final response = await http.get(
      url,
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      await _handleUnauthorized();
      return;
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final proposals = data['proposals'] as List<dynamic>;
      for (final proposal in proposals) {
        final int proposalId = proposal['id'];
        final String status = proposal['status'];

        if (status != 'pending') {
          if (_notifiedProposalStatuses[proposalId] != status) {
            print("Nuevo estado en propuesta $proposalId: $status");
            await showStatusNotification(
                "La propuesta de ${proposal['tipodeservicio'] ?? 'servicio'} ha sido: $status");
            _notifiedProposalStatuses[proposalId] = status;
            await _saveNotifiedStatuses();
          }
        }
      }
    } else {
      print("Error: ${response.statusCode}");
    }
  }

  void startCheckingNotifications() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      checkNotifications();
    });
  }

  void cancelCheckingNotifications() {
    _notificationTimer?.cancel();
  }
  // --- Fin métodos de notificaciones persistentes ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Se quita la flecha de retroceso
        backgroundColor:
            const Color.fromARGB(255, 0, 184, 255), // Color modificado de la barra superior
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
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
              icon: Icon(Icons.calendar_today), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
