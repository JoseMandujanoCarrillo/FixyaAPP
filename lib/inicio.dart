import 'package:flutter/material.dart';
// Asegúrate de que los archivos de Login y Registro correspondan a las rutas definidas en main.dart
// Por ejemplo, si LoginScreen y RegisterScreen están en login.dart y register.dart respectivamente,
// puedes actualizar las importaciones o poder utilizar rutas nombradas.

class Inicio extends StatelessWidget {
  const Inicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF94D6FF), // Fondo azul claro para el inicio de sesi{on}
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          // Texto de bienvenida inicial
          const Text(
            "Bienvenido a",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          const Text(
            "CleanYa",
            style: TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              shadows: [
                Shadow(
                  offset: Offset(1.5, 1.5),
                  blurRadius: 2.0,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Botón de Iniciar Sesión.
          ElevatedButton(
            onPressed: () {
              // Navegar a la pantalla de inicio de sesión usando ruta nombrada
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 85, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 5,
            ),
            child: const Text(
              'Iniciar sesión',
              style: TextStyle(
                color: Colors.black,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Botón de Registro
          ElevatedButton(
            onPressed: () {
              // Navegar a la pantalla de registro usando ruta nombrada
              Navigator.pushNamed(context, '/register');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 5,
            ),
            child: const Text(
              'Regístrate',
              style: TextStyle(
                color: Colors.black,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Imágenes decorativas
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  top: -150,
                  right: -60,
                  child: Image.asset(
                    '/assets/iconos/icono2.png',
                    width: 300,
                  ),
                ),
                Positioned(
                  bottom: 100,
                  left: 100,
                  child: Image.asset(
                    'assets/iconos/icono1.png',
                    width: 300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
