import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo para representar una notificación.
class NotificationItem {
  final int proposalId;
  final String message;
  final String tipodeservicio;
  final String status;
  final DateTime updatedAt;

  NotificationItem({
    required this.proposalId,
    required this.message,
    required this.tipodeservicio,
    required this.status,
    required this.updatedAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      proposalId: json['proposalId'],
      message: json['message'],
      tipodeservicio: json['tipodeservicio'],
      status: json['status'],
      // Se asume que updatedAt viene en formato ISO 8601
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

/// Página que muestra las notificaciones en una lista con carga incremental
/// y permite eliminarlas (individual o todas a la vez).
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationItem> _allNotifications = [];
  List<NotificationItem> _displayedNotifications = [];
  int _itemsPerPage = 10;
  bool _isLoading = false;
  bool _hasMore = true;
  late ScrollController _scrollController;
  String? _token;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    _loadTokenAndNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Obtiene el token almacenado y luego carga las notificaciones.
  Future<void> _loadTokenAndNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    await _fetchNotifications();
  }

  /// Consulta el endpoint de notificaciones y actualiza la lista.
  Future<void> _fetchNotifications() async {
    if (_token == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/users/notifications'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<NotificationItem> notifications = data
            .map((jsonItem) => NotificationItem.fromJson(jsonItem))
            .toList();

        // Ordenamos de forma descendente según updatedAt
        notifications.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        setState(() {
          _allNotifications = notifications;
          _displayedNotifications = [];
          _hasMore = true;
        });
        _loadMoreItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar notificaciones: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar notificaciones: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Carga de forma incremental más notificaciones en la lista visible.
  void _loadMoreItems() {
    final nextItems = _allNotifications
        .skip(_displayedNotifications.length)
        .take(_itemsPerPage)
        .toList();
    setState(() {
      _displayedNotifications.addAll(nextItems);
      if (_displayedNotifications.length >= _allNotifications.length) {
        _hasMore = false;
      }
    });
  }

  /// Escucha el scroll para detectar cuando se alcanza el final y cargar más.
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreItems();
    }
  }

  /// Envía la solicitud para eliminar una notificación (se asume endpoint DELETE).
  Future<void> _deleteNotification(int proposalId) async {
    if (_token == null) return;
    final url = Uri.parse('https://apifixya.onrender.com/users/notifications/$proposalId');
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _allNotifications.removeWhere((n) => n.proposalId == proposalId);
          _displayedNotifications.removeWhere((n) => n.proposalId == proposalId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificación eliminada')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar notificación: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar notificación: $e')),
      );
    }
  }

  /// Envía la solicitud para eliminar TODAS las notificaciones (se asume endpoint DELETE).
  Future<void> _deleteAllNotifications() async {
    if (_token == null) return;
    final url = Uri.parse('https://apifixya.onrender.com/users/notifications');
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _allNotifications.clear();
          _displayedNotifications.clear();
          _hasMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todas las notificaciones eliminadas')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar notificaciones: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar notificaciones: $e')),
      );
    }
  }

  /// Permite actualizar la lista mediante pull-to-refresh.
  Future<void> _refreshNotifications() async {
    await _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _allNotifications.isEmpty ? null : _deleteAllNotifications,
            tooltip: 'Eliminar todas las notificaciones',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        child: _isLoading && _displayedNotifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                controller: _scrollController,
                itemCount: _displayedNotifications.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _displayedNotifications.length) {
                    // Indicador de carga al final de la lista
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final notification = _displayedNotifications[index];
                  return Dismissible(
                    key: Key(notification.proposalId.toString()),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      _deleteNotification(notification.proposalId);
                    },
                    child: ListTile(
                      title: Text(notification.message),
                      subtitle: Text('Actualizado: ${notification.updatedAt}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _deleteNotification(notification.proposalId);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
