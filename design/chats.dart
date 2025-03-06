import 'package:flutter/material.dart';
import 'actividad.dart';
import 'principal.dart';
import 'chat.dart';
import 'tu.dart';

class ChatScreen extends StatefulWidget {
  final String chatPartnerName;

  ChatScreen({required this.chatPartnerName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> messages = [];
  TextEditingController _messageController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  bool _showIcons = false;

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        messages.add({"text": _messageController.text.trim(), "isMe": true});
      });
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildUserInfo(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(messages[index]["text"], messages[index]["isMe"]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF94D6FF), Color(0xFF94D6FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
      ),
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundImage: AssetImage("assets/image/image7.png"),
            radius: 25,
          ),
          SizedBox(width: 10),
          Text(
            widget.chatPartnerName,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: isMe ? Radius.circular(15) : Radius.circular(0),
            bottomRight: isMe ? Radius.circular(0) : Radius.circular(15),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: EdgeInsets.only(left: 15, right: 15, bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showIcons = !_showIcons;
              });
            },
            child: Image.asset(
              "assets/iconos/icono19.png",
              width: 32,
              height: 32,
              color: Colors.black,
            ),
          ),
          if (_showIcons) ...[
            SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _iconButton("assets/iconos/icono17.png", () {}), // Teléfono
                SizedBox(height: 10),
                _iconButton("assets/iconos/icono18.png", () {}), // Imagen
                SizedBox(height: 10),
                _iconButton("assets/iconos/icono16.png", () {}), // Ubicación
              ],
            ),
          ],
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Escribe un mensaje...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(String assetPath, VoidCallback onPressed) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(10),
      ),
      child: GestureDetector(
        onTap: onPressed,
        child: Image.asset(
          assetPath,
          width: 32,
          height: 32,
          color: Colors.white,
        ),
      ),
    );
  }

   Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono6.png"), size: 30, color: Color(0xFF9E9E9E)),
              Text("INICIO", style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14)),
            ],
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono23.png"), size: 30, color: Color(0xFF9E9E9E)),
              Text("Actividad", style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14)),
            ],
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono8.png"), size: 30, color: Color(0xFF9E9E9E)),
              Text("CHAT", style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14)),
            ],
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono9.png"), size: 30, color: Color(0xFF9E9E9E)),
              Text("TÚ", style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14)),
            ],
          ),
          label: '',
        ),
      ],
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Color(0xFF9E9E9E),
      showUnselectedLabels: true,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaPrincipal()));
            break;
          case 1:
            Navigator.push(context, MaterialPageRoute(builder: (context) => HistorialSoliScreen()));
            break;
          case 2:
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatListScreen()));
            break;
            case 3: 
              Navigator.push( context,
                MaterialPageRoute( builder: (context) => TuScreen ()), // Navega a la pantalla de perfil
              );
              break;
            // Aquí puedes agregar la navegación a la pantalla de perfil
            break;
          default:
            break;
        }
      },
    );
  }
}
