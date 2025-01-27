import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> cleaners = [
    {'name': 'John Doe', 'email': 'john@example.com'},
    {'name': 'Jane Smith', 'email': 'jane@example.com'},
    {'name': 'Michael Johnson', 'email': 'michael@example.com'},
  ];

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cleaners')),
      body: _selectedIndex == 0
          ? ListView.builder(
              itemCount: cleaners.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(cleaners[index]['name']),
                  subtitle: Text(cleaners[index]['email']),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Aquí puedes manejar el botón de más información.
                    },
                    child: Text('Más información'),
                  ),
                );
              },
            )
          : Center(child: Text('Pestaña no disponible aún.')),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),
            label: 'Sin Icono',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Usuario',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
