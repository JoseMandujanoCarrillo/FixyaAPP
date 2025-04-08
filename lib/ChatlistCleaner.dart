import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'Cleanerchat_page.dart'; // Asegúrate de tener definido CleanerChatDetailPage en este archivo

class Chat {
  final int id;
  final String name;
  final String imageUrl;

  const Chat({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
    );
  }
}

class CleanerChatListPage extends StatefulWidget {
  const CleanerChatListPage({Key? key}) : super(key: key);

  @override
  _CleanerChatListPageState createState() => _CleanerChatListPageState();
}

class _CleanerChatListPageState extends State<CleanerChatListPage> {
  String? userToken;
  late Future<List<Chat>> _futureChats;

  @override
  void initState() {
    super.initState();
    _loadTokenAndChats();
  }

  Future<void> _loadTokenAndChats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      setState(() {
        userToken = token;
        _futureChats = fetchChats();
      });
    } else {
      // Manejo si no se encuentra el token.
      setState(() {
        _futureChats = Future.error('Token no encontrado. Por favor, inicia sesión.');
      });
    }
  }

  Future<List<Chat>> fetchChats() async {
    final response = await http.get(
      Uri.parse('https://apifixya.onrender.com/chats/cleaner/chats?page=1&limit=9999'),
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer $userToken',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      List<dynamic> data = jsonData['data'];
      return data.map((chat) => Chat.fromJson(chat)).toList();
    } else {
      throw Exception('Error al cargar los chats');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: userToken == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Chat>>(
              future: _futureChats,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No se encontraron chats.'));
                }

                final chats = snapshot.data!;
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(chat.imageUrl),
                        ),
                        title: Text(chat.name),
                        subtitle: Text('ID: ${chat.id}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CleanerChatDetailPage(
                                cleanerId: chat.id,
                                cleanerName: chat.name,
                                cleanerImage: chat.imageUrl,
                                token: userToken!,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
