import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Importa dart:async para usar Timer

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
  Timer? _timer; // Variable para el Timer
  int _displayedMessageCount = 0; // Cantidad de mensajes actualmente mostrados

  @override
  void initState() {
    super.initState();
    // Obtención inicial de mensajes y actualización del contador
    _futureMessages = fetchMessages();
    _futureMessages.then((messages) {
      _displayedMessageCount = messages.length;
    });

    // Configura un Timer.periodic para refrescar mensajes cada 3 segundos de forma oculta
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        List<dynamic> newMessages = await fetchMessages();
        // Solo actualizamos la UI si el número de mensajes ha cambiado
        if (newMessages.length != _displayedMessageCount && mounted) {
          setState(() {
            _futureMessages = Future.value(newMessages);
            _displayedMessageCount = newMessages.length;
          });
        }
      } catch (e) {
        // Manejo opcional de errores
      }
    });
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
      List<dynamic> updatedMessages = await fetchMessages();
      setState(() {
        _futureMessages = Future.value(updatedMessages);
        _displayedMessageCount = updatedMessages.length;
      });
    } else {
      throw Exception('Error al enviar el mensaje');
    }
    setState(() {
      _isSending = false;
    });
  }

  /// Widget para dibujar cada burbuja de chat con animación
  Widget buildChatBubble(dynamic message, int index) {
    // Se asume que cada mensaje tiene 'message' (texto) y 'sender'
    bool isUser = message['sender'] == 'user';

    Widget bubble = Align(
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

    // Se anima la burbuja con un fade y un pequeño deslizamiento vertical
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + index * 100),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: bubble,
    );
  }

  Widget buildMessageInput() {
    return Container(
      margin: const EdgeInsets.all(12), // Se añade margen para alejar del borde
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          _isSending
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
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
  void dispose() {
    _timer?.cancel(); // Cancela el Timer para evitar fugas de memoria
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue, // Barra superior azul
        automaticallyImplyLeading: false,
        title: Text(widget.cleanerName),
        // Se aumenta el padding para que la foto no quede tan al borde
        leading: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CircleAvatar(
            backgroundImage: NetworkImage(widget.cleanerImage),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _futureMessages,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text(
                      'Error: ${snapshot.error}',
                      style:
                          const TextStyle(fontSize: 18, color: Colors.red),
                    ));
                  } else if (snapshot.hasData) {
                    final messages = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return buildChatBubble(message, index);
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
      ),
    );
  }
}
