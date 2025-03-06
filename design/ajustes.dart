import 'package:flutter/material.dart';
import 'inisesión.dart'; 
import 'principal.dart'; 
import 'chat.dart';
import 'actividad.dart';
import 'tu.dart';

class Ajustes extends StatefulWidget {
  const Ajustes({super.key});

  @override
  _AjustesState createState() => _AjustesState();
}

class _AjustesState extends State<Ajustes> {
  int _selectedMenuIndex = 1; // Variable de estado para el índice del menú seleccionado
  bool _isLoading = false; // Estado para la animación de carga

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(65.0),
            child: Container(
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
              ),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Menú horizontal (ahora está arriba de "Configuraciones")
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _menuButton("Perfil", 0), // Índice 0 para Perfil
                    _menuButton("Ajustes", 1), // Índice 1 para Ajustes
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20, top: 20),
                child: Text(
                  'Configuraciones',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              // Aquí puedes continuar con el resto de tu diseño
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildSectionTitle('General'),
                      _buildSettingsCard([ // Ajustes generales
                        _buildOptionRow('Notificaciones', 'assets/iconos/icono10.png'),
                        _buildOptionRow('Privacidad', 'assets/iconos/icono11.png'),
                        _buildOptionRow('Términos y Condiciones', 'assets/iconos/icono12.png'),
                      ]),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Opciones de sesión'),
                      _buildSettingsCard([ // Opciones de sesión
                        _buildOptionRow('Perfil', 'assets/iconos/icono13.png'),
                        _buildOptionRow('Cerrar sesión', 'assets/iconos/icono14.png', onTap: _confirmLogOut),
                        _buildOptionRow('Borrar cuenta', 'assets/iconos/icono15.png', onTap: _confirmDeleteAccount),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavBar(),
        ),
        if (_isLoading) _buildLoadingOverlay(), // Asegura que la animación cubra TODO
      ],
    );
  }

  // Método para actualizar el estado seleccionado del menú
 Widget _menuButton(String text, int index) {
  bool isSelected = _selectedMenuIndex == index;
  return GestureDetector(
    onTap: () {
      setState(() {
        _selectedMenuIndex = index; // Cambiar el índice seleccionado
      });
      if (text == "Perfil") {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TuScreen()));
      } else if (text == "Ajustes" && _selectedMenuIndex != 1) { // Evitar recursión
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Ajustes()));
      }
    },
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: isSelected ? Color(0xFF9747FF) : Colors.black, // Cambia el color según el estado
        ),
      ),
    ),
  );
}


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildOptionRow(String text, String iconPath, {Function? onTap}) {
    return ListTile(
      leading: Image.asset(
        iconPath,
        width: 25,
        height: 25,
        color: Colors.black,
      ),
      title: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      onTap: onTap != null ? () => onTap() : null,
    );
  }

  void _confirmLogOut() {
    _showConfirmationDialog(
      title: 'Cerrar sesión',
      content: 'Solo se saldrá de tu cuenta, pero tus datos se mantendrán guardados.',
      confirmText: 'Aceptar',
      confirmAction: _logOut,
    );
  }

  void _confirmDeleteAccount() {
    _showConfirmationDialog(
      title: 'Eliminar cuenta',
      content: 'Eliminar tu cuenta puede causar una baja permanente de tus datos como:\n'
          '• Historial de servicios realizados\n'
          '• Métodos de pago vinculados\n'
          '• Recibos y facturas guardadas\n'
          '• Inicio de sesión en la app\n'
          '• Datos personalizados\n\n'
          '¿Estás seguro de eliminar tu cuenta permanentemente?',
      confirmText: 'Eliminar',
      confirmAction: _deleteAccount,
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback confirmAction,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                confirmAction();
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  void _logOut() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      });
    }
  }

  void _deleteAccount() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      });
    }
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: AbsorbPointer( // Evita interacción del usuario
        child: Container(
          color: Colors.black.withOpacity(0.7), // Fondo oscuro para bloqueo visual
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono6.png"),
                  color: Color(0xFF9E9E9E)),
              Text("INICIO", style: TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono23.png"),
                  color: Color(0xFF9E9E9E)),
              Text("Actividad", style: TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono8.png"),
                  color: Color(0xFF9E9E9E)),
              Text("CHAT", style: TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono9.png"),
                  color: Color(0xFF9E9E9E)),
              Text("TÚ", style: TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          label: '',
        ),
      ],
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue, // Seleccionado con color azul
      unselectedItemColor:
          Color(0xFF9E9E9E), // No seleccionado con color gris
      showUnselectedLabels: true, // Para que se muestren las etiquetas
      onTap: (index) {
        switch (index) {
          case 1: // Índice de la opción "Actividad"
            Navigator.push( context,
              MaterialPageRoute( builder: (context) => HistorialSoliScreen()), // Navega a la pantalla actividad
            );
            break;
          case 2: 
            Navigator.push( context,
              MaterialPageRoute( builder: (context) => ChatListScreen ()), // Navega a la pantalla chat
            );
            break;
          case 0: 
            Navigator.push( context,
              MaterialPageRoute( builder: (context) => PantallaPrincipal ()), // Navega a la pantalla principal
            );
            break;
        }
      },
    );
  }
}
