import 'package:flutter/material.dart';
import 'actividad.dart';
import 'principal.dart';
import 'chats.dart';
import 'tu.dart';

class ChatListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(160.0),
        child: Column(
          children: [
            Container(
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
                automaticallyImplyLeading: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[350],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          Image.asset("assets/iconos/icono5.png", width: 28, height: 28, color: Colors.black.withOpacity(0.5)),
                          SizedBox(width: 12),
                          Text("Buscar", style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 18))
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: AssetImage("assets/image/image6.png"),
                  ),
                  SizedBox(width: 12),
                  Image.asset("assets/iconos/icono4.png", width: 32, height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage("assets/image/image7.png"),
              radius: 32,
            ),
            title: Text(
              "Mariana Canche",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Tú: Entonces serían...",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black.withOpacity(0.6)),
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "12:30 PM",
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                SizedBox(height: 2),
                Text(
                  "20/02/2025",
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(chatPartnerName: "Mariana Canche"),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
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
              Text("ACTIVIDAD", style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14)),
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