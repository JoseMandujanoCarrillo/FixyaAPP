import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatDetailPage extends StatefulWidget {
  final int cleanerId;
  final String cleanerName;
  final String cleanerImage;
  final String token; // Se pasa desde ChatListPage

  const ChatDetailPage({
    Key? key,
    required this.cleanerId,
    required this.cleanerName,
    required this.cleanerImage,
    required this.token,
  }) : super(key: key);

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  List<dynamic> messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchChatMessages();
  }

  Future<void> fetchChatMessages() async {
    setState(() {
      isLoading = true;
    });
    // Se usa el endpoint GET para obtener los mensajes con el cleaner
    final url = 'https://apifixya.onrender.com/chats/${widget.cleanerId}';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer ${widget.token}'
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Se asume que la respuesta contiene: { "cleaner": {...}, "messages": [ ... ] }
      setState(() {
        messages = data['messages'];
      });
    } else {
      // Manejo básico de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar mensajes: ${response.statusCode}')),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final url = 'https://apifixya.onrender.com/chats/${widget.cleanerId}/messages';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}'
      },
      body: json.encode({'message': messageText}),
    );

    if (response.statusCode == 201) {
      _messageController.clear();
      fetchChatMessages(); // Recargar mensajes tras enviar
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje: ${response.statusCode}')),
      );
    }
  }

  Widget _buildMessageItem(dynamic message) {
    return ListTile(
      title: Text(message['message'] ?? ''),
      subtitle: Text(message['createdAt'] ?? ''),
      // Puedes personalizar el estilo dependiendo del remitente (por ejemplo, 'user' o 'cleaner')
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            widget.cleanerImage.isNotEmpty
                ? CircleAvatar(
                    backgroundImage: NetworkImage(widget.cleanerImage),
                  )
                : const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 8),
            Text(widget.cleanerName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: fetchChatMessages,
                    child: ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageItem(messages[index]);
                      },
                    ),
                  ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
