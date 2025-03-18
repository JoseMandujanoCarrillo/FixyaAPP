import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class CleanerChatDetailPage extends StatefulWidget {
  final int cleanerId; // Se usa como userId en el endpoint
  final String cleanerName;
  final String cleanerImage;
  final String token;

  const CleanerChatDetailPage({
    Key? key,
    required this.cleanerId,
    required this.cleanerName,
    required this.cleanerImage,
    required this.token,
  }) : super(key: key);

  @override
  _CleanerChatDetailPageState createState() => _CleanerChatDetailPageState();
}

class _CleanerChatDetailPageState extends State<CleanerChatDetailPage> {
  late Future<List<dynamic>> _futureMessages;
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  Timer? _timer; // Timer para refrescar mensajes en segundo plano
  int _displayedMessageCount = 0; // Número de mensajes actualmente mostrados
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Obtención inicial de mensajes y actualización del contador
    _futureMessages = fetchMessages();
    _futureMessages.then((messages) {
      _displayedMessageCount = messages.length;
    });

    // Timer que consulta el endpoint cada 3 segundos de forma oculta
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer t) async {
      try {
        List<dynamic> hiddenMessages = await fetchMessages();
        // Solo actualizamos la UI si el número de mensajes ha cambiado
        if (hiddenMessages.length != _displayedMessageCount && mounted) {
          setState(() {
            _futureMessages = Future.value(hiddenMessages);
            _displayedMessageCount = hiddenMessages.length;
          });
        }
      } catch (e) {
        // Manejo opcional de errores
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> fetchMessages() async {
    final String url =
        'https://apifixya.onrender.com/chats/cleaner/chats/${widget.cleanerId}?page=1&limit=99999';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      // Se extraen los mensajes del objeto "messages"
      List<dynamic> messages = jsonResponse['messages']['data'];
      return messages;
    } else {
      throw Exception('Error al cargar los mensajes');
    }
  }

  Future<void> sendMessage(String messageText) async {
    setState(() {
      _isSending = true;
    });
    final String url =
        'https://apifixya.onrender.com/chats/cleaner/chats/${widget.cleanerId}/messages';
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
      // Mensaje enviado correctamente, se limpia el input y se actualiza la lista visible
      _messageController.clear();
      List<dynamic> updatedMessages = await fetchMessages();
      setState(() {
        _futureMessages = Future.value(updatedMessages);
        _displayedMessageCount = updatedMessages.length;
      });
      // Desplaza hacia abajo después de renderizar el nuevo mensaje
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } else {
      throw Exception('Error al enviar el mensaje');
    }
    setState(() {
      _isSending = false;
    });
  }

  /// Desplaza la lista hacia abajo
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Crea la burbuja de chat con animación de fade-in.
  Widget buildChatBubble(dynamic message) {
    bool isCleaner = message['sender'] == 'cleaner';
    Color bubbleColor = isCleaner ? Colors.blue : Colors.white;
    Color textColor = isCleaner ? Colors.white : Colors.black;
    Alignment alignment =
        isCleaner ? Alignment.centerRight : Alignment.centerLeft;
    BorderRadius borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft:
          isCleaner ? const Radius.circular(12) : const Radius.circular(0),
      bottomRight:
          isCleaner ? const Radius.circular(0) : const Radius.circular(12),
    );

    Widget bubble = Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
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
            color: textColor,
            fontSize: 16,
          ),
        ),
      ),
    );

    // Se añade una animación de aparición (fade-in)
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: bubble,
    );
  }

  /// Widget para el input de mensaje y botón de envío.
  Widget buildMessageInput() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
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
        backgroundColor: Colors.blue,
        title: Text(
          widget.cleanerName,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: widget.cleanerImage.isNotEmpty
              ? CircleAvatar(
                  backgroundImage: NetworkImage(widget.cleanerImage),
                )
              : const Icon(Icons.person, size: 28, color: Colors.white),
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
                  if (messages.isEmpty) {
                    return const Center(child: Text('No hay mensajes.'));
                  }
                  // Desplaza la vista hasta el final después de renderizar los mensajes
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return buildChatBubble(message);
                    },
                  );
                }
                return const Center(child: Text('No se encontraron datos.'));
              },
            ),
          ),
          buildMessageInput(),
        ],
      ),
    );
  }
}
