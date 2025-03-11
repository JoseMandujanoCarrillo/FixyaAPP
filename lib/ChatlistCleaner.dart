import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'Cleanerchat_page.dart'; // Asegúrate de tener este archivo, que debe contener ChatDetailPage
import 'package:flutter/foundation.dart'; // Para usar compute

// Función para parsear el JSON en un isolate
Map<String, dynamic> parseJson(String responseBody) {
  return json.decode(responseBody);
}

class ChatCleanerListPage extends StatefulWidget {
  const ChatCleanerListPage({Key? key}) : super(key: key);

  @override
  _ChatCleanerListPageState createState() => _ChatCleanerListPageState();
}

class _ChatCleanerListPageState extends State<ChatCleanerListPage> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> messages = [];
  Map<String, dynamic>? user;
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  String? token; // Se obtiene desde SharedPreferences
  final int pageSize = 10; // Número de chats por página

  @override
  void initState() {
    super.initState();
    _loadToken().then((_) {
      fetchChatPage(); // Cargar la primera página de mensajes
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        // Cuando nos acerquemos al final, cargamos la siguiente página
        fetchChatPage();
      }
    });
  }

  // Carga el token desde SharedPreferences
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
    });
  }

  Future<void> fetchChatPage() async {
    if (token == null) return; // Si no se ha obtenido el token, no se realiza la petición
    setState(() {
      isLoading = true;
    });

    // Se agrega el parámetro "limit" para controlar el número de chats por página
    final url =
        'https://apifixya.onrender.com/chats/cleaner/chats?page=$currentPage&limit=$pageSize';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      // Parseo en background usando compute para evitar bloquear la UI
      final data = await compute(parseJson, response.body);
      // Se asume que la respuesta tiene la estructura: { "user": { ... }, "messages": [ ... ] }
      if (user == null && data['user'] != null) {
        user = data['user'];
      }
      List<dynamic> newMessages = data['messages'];
      // Si la cantidad recibida es menor que pageSize, ya no hay más mensajes
      if (newMessages.length < pageSize) {
        hasMore = false;
      }
      if (newMessages.isNotEmpty) {
        currentPage++;
        messages.addAll(newMessages);
      }
    } else {
      // Manejo básico de error
      hasMore = false;
    }
    setState(() {
      isLoading = false;
    });
  }

  // Permitir refrescar la lista manualmente
  Future<void> _refreshChats() async {
    setState(() {
      messages.clear();
      currentPage = 1;
      hasMore = true;
      user = null;
    });
    await fetchChatPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Widget para construir cada elemento de chat
  Widget _buildMessageItem(dynamic message) {
    // Se asume que cada mensaje contiene un objeto "user" con los datos del usuario con el que se conversa
    var chatUser = message['user'];
    return ListTile(
      leading: chatUser != null && chatUser['imageUrl'] != null
          ? CircleAvatar(
              backgroundImage: NetworkImage(chatUser['imageUrl']),
            )
          : const CircleAvatar(child: Icon(Icons.person)),
      title: Text(chatUser != null
          ? '${chatUser['name']} (ID: ${chatUser['id']})'
          : 'Sin usuario'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message['message'] ?? ''),
          Text(message['createdAt'] ?? ''),
        ],
      ),
      onTap: () {
        // Al presionar un chat, navegamos a ChatDetailPage usando el chatId (campo "id" del mensaje)
        if (message['id'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailPage(
                chatId: message['id'], // Se usa el id del chat
                cleanerName: chatUser != null
                    ? chatUser['name'] ?? 'Sin nombre'
                    : '',
                cleanerImage: chatUser != null ? chatUser['imageUrl'] ?? '' : '',
                token: token!, // Pasamos el token obtenido
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats del Cleaner'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshChats,
        child: Column(
          children: [
            // Información del usuario (por ejemplo, el cleaner o el usuario con quien se conversa)
            if (user != null)
              ListTile(
                leading: user!['imageUrl'] != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(user!['imageUrl']),
                      )
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(user!['name'] ?? ''),
              ),
            const Divider(),
            // Lista infinita de chats
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < messages.length) {
                    var message = messages[index];
                    return _buildMessageItem(message);
                  } else {
                    // Indicador de carga al final de la lista
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
