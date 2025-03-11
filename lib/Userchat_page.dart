import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatDetailPage extends StatefulWidget {
  final dynamic cleanerId;
  final String cleanerName;
  final String cleanerImage;
  final String token;

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
  late Future<List<dynamic>> _futureMessages;
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _futureMessages = fetchMessages();
  }

  Future<List<dynamic>> fetchMessages() async {
    final String url =
        'https://apifixya.onrender.com/chats/${widget.cleanerId}?page=1&limit=9999';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      // Extraemos la lista de mensajes que se encuentra en jsonResponse['messages']['data']
      final List<dynamic> messages = jsonResponse['messages']['data'];
      return messages;
    } else {
      throw Exception('Error al cargar los mensajes del chat');
    }
  }

  Future<void> sendMessage(String messageText) async {
    setState(() {
      _isSending = true;
    });
    final String url =
        'https://apifixya.onrender.com/chats/${widget.cleanerId}/messages';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: json.encode({'message': messageText}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Si el mensaje se envía correctamente, refrescamos la lista de mensajes
      _messageController.clear();
      setState(() {
        _futureMessages = fetchMessages();
      });
    } else {
      throw Exception('Error al enviar el mensaje');
    }
    setState(() {
      _isSending = false;
    });
  }

  /// Widget para dibujar cada burbuja de chat
  Widget buildChatBubble(dynamic message) {
    // Se asume que cada mensaje tiene 'message' (texto) y 'sender'
    bool isUser = message['sender'] == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft:
                isUser ? const Radius.circular(12) : const Radius.circular(0),
            bottomRight:
                isUser ? const Radius.circular(0) : const Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              offset: const Offset(0, 2),
              blurRadius: 5,
            ),
          ],
        ),
        child: Text(
          message['message'] ?? '',
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.grey[200],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: InputBorder.none,
              ),
            ),
          ),
          _isSending
              ? const CircularProgressIndicator()
              : IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    final text = _messageController.text.trim();
                    if (text.isNotEmpty) {
                      sendMessage(text);
                    }
                  },
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cleanerName),
        leading: CircleAvatar(
          backgroundImage: NetworkImage(widget.cleanerImage),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _futureMessages,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final messages = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return buildChatBubble(message);
                    },
                  );
                }
                return const Center(child: Text('No hay datos'));
              },
            ),
          ),
          buildMessageInput(),
        ],
      ),
    );
  }
}
