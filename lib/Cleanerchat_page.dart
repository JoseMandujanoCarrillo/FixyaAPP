import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatDetailPage extends StatefulWidget {
  final int chatId;
  final String cleanerName; // Nombre del interlocutor
  final String cleanerImage; // Imagen del interlocutor
  final String token;

  const ChatDetailPage({
    Key? key,
    required this.chatId,
    required this.cleanerName,
    required this.cleanerImage,
    required this.token,
  }) : super(key: key);

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  List<dynamic> messages = [];
  bool isLoading = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  /// Obtiene los mensajes desde el endpoint GET
  Future<void> fetchMessages() async {
    setState(() {
      isLoading = true;
    });
    final url = 'https://apifixya.onrender.com/chats/${widget.chatId}';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Se asume que la respuesta tiene la estructura: { "messages": [ ... ] }
        setState(() {
          messages = data['messages'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al obtener los mensajes")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión")),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  /// Envía un mensaje usando el endpoint POST
  Future<void> sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;
    final url =
        'https://apifixya.onrender.com/chats/cleaner/chats/${widget.chatId}/messages';
    final body = json.encode({"message": messageText});
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Se agrega el mensaje a la lista y se limpia el TextField
        setState(() {
          messages.add({
            'message': messageText,
            'createdAt': DateTime.now().toString(),
            'sender': 'cleaner', // Suponiendo que este mensaje es del cleaner
          });
        });
        _messageController.clear();
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al enviar el mensaje")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión")),
      );
    }
  }

  /// Construye cada elemento de mensaje
  Widget _buildMessageItem(dynamic message) {
    // Determina si el mensaje fue enviado por el cleaner o no, usando la propiedad 'sender'
    bool isCleaner = message['sender'] == 'cleaner';
    return Align(
      alignment: isCleaner ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: isCleaner ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment:
              isCleaner ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message['message'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              message['createdAt'] ?? '',
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshMessages() async {
    await fetchMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cleanerName),
        leading: widget.cleanerImage.isNotEmpty
            ? CircleAvatar(
                backgroundImage: NetworkImage(widget.cleanerImage),
              )
            : const Icon(Icons.person),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshMessages,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageItem(messages[index]);
                      },
                    ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu mensaje',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
