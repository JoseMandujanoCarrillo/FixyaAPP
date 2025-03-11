import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'Userchat_page.dart'; // Asegúrate de tener este archivo en tu proyecto

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<dynamic> chats = [];
  bool isLoading = false;
  String errorMessage = '';
  String? userToken;

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  Future<void> fetchChats() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Obtén el token almacenado en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          errorMessage = 'Token no encontrado, por favor inicia sesión.';
        });
        return;
      }
      // Guarda el token en el estado para usarlo al navegar
      setState(() {
        userToken = token;
      });

      final url = Uri.parse('https://apifixya.onrender.com/chats?page=1&limit=999');
      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          chats = data['data'];
        });
      } else {
        setState(() {
          errorMessage = 'Error en la respuesta del servidor: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al obtener los chats: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildChatCard(Map<String, dynamic> chat) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      child: ListTile(
        onTap: () {
          // Al pulsar la card, se navega a ChatDetailPage pasando el id (por ejemplo, 10499), nombre, imagen y token.
          if (userToken != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailPage(
                  cleanerId: chat['id'], // 'id' es el identificador del chat/cleaner (ej: 10499)
                  cleanerName: chat['name'],
                  cleanerImage: chat['imageurl'],
                  token: userToken!,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Token no disponible')),
            );
          }
        },
        leading: CircleAvatar(
          backgroundImage: NetworkImage(chat['imageurl']),
          radius: 25,
        ),
        title: Text(
          chat['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('ID: ${chat['id']}'),
        trailing: const Icon(Icons.message, color: Colors.green),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return _buildChatCard(chat);
                  },
                ),
    );
  }
}
