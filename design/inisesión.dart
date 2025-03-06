import 'package:flutter/material.dart';
import 'principal.dart'; // Importa la pantalla principal

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fondo degradado con título
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 25, top: 40, bottom: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF94D6FF), Color(0xFF94D6FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Text(
                "WhatClean",
                style: TextStyle(
                  fontSize: 40,
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
            ),
            const SizedBox(height: 10),
            // Imagen centrada
            Center(
              child: Image.asset(
                'assets/image/image1.png',
                width: 352,
                height: 212,
              ),
            ),
            const SizedBox(height: 25),
            // Título del formulario
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 34),
                child: Text(
                  "Inicia sesión en WhatClean",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    shadows: [
                      Shadow(
                        offset: Offset(1.5, 1.5),
                        blurRadius: 3.0,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Campos de formulario
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField("Ingresa tu correo electrónico", "Correo electrónico"),
                  _buildTextField("Ingresa tu contraseña", "Contraseña", isPassword: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Botón de inicio de sesión
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const PantallaPrincipal()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4269),
                  padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Iniciar sesión",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}