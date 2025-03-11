import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'Userchat_page.dart'; // Asegúrate de tener este archivo

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> messages = [];
  Map<String, dynamic>? user;
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  String? token; // Se obtiene desde SharedPreferences

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

    final url = 'https://apifixya.onrender.com/chats?page=$currentPage';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Se asume que la respuesta tiene la estructura: { "user": { ... }, "messages": [ ... ] }
      if (user == null && data['user'] != null) {
        user = data['user'];
      }
      List<dynamic> newMessages = data['messages'];
      if (newMessages.isEmpty) {
        hasMore = false; // No hay más mensajes
      } else {
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Widget para construir cada elemento de chat (se asume que cada mensaje incluye un objeto "cleaner")
  Widget _buildMessageItem(dynamic message) {
    var cleaner = message['cleaner'];
    return ListTile(
      leading: cleaner != null && cleaner['imageUrl'] != null
          ? CircleAvatar(
              backgroundImage: NetworkImage(cleaner['imageUrl']),
            )
          : const CircleAvatar(child: Icon(Icons.person)),
      title: Text(cleaner != null
          ? '${cleaner['name']} (ID: ${cleaner['id']})'
          : 'Sin cleaner'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message['message'] ?? ''),
          Text(message['createdAt'] ?? ''),
        ],
      ),
      onTap: () {
        // Al presionar un chat, navegamos a ChatDetailPage
        if (cleaner != null && cleaner['id'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailPage(
                cleanerId: cleaner['id'],
                cleanerName: cleaner['name'] ?? 'Sin nombre',
                cleanerImage: cleaner['imageUrl'] ?? '',
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
        title: const Text('Chat List'),
      ),
      body: Column(
        children: [
          // Información del usuario (por ejemplo, el cliente o quien inició el chat)
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
    );
  }
}