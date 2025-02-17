import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Para detectar SocketException (sin conexión)
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? userToken; // Variable para almacenar el token

  // Variable para controlar si la contraseña se muestra u oculta
  bool obscurePassword = true;

  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Intentar login en el endpoint de usuarios
      final userUrl = Uri.parse('https://apifixya.onrender.com/users/login');
      final userResponse = await http.post(
        userUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      if (userResponse.statusCode == 200) {
        // Login exitoso para usuarios
        final data = json.decode(userResponse.body);
        userToken = data['token'];

        // Obtener datos del usuario
        final meResponse = await http.get(
          Uri.parse('https://apifixya.onrender.com/users/me'),
          headers: {'Authorization': 'Bearer $userToken'},
        );

        if (meResponse.statusCode == 200) {
          final userData = json.decode(meResponse.body);

          // Guardar token y datos en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', userToken!);
          await prefs.setInt('userId', userData['id']);
          await prefs.setString('userName', userData['name']);

          Navigator.pop(context); // Cierra el diálogo de carga
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inicio de sesión exitoso')),
          );

          // Redirige a la pantalla de usuario
          Navigator.pushReplacementNamed(context, '/home');
          return;
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al obtener los datos del usuario')),
          );
          return;
        }
      } else if (userResponse.statusCode == 401) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña incorrecta')),
        );
        return;
      } else {
        // Si falla el login como usuario (por ejemplo, no se encuentra), se intenta login como cleaner
        final cleanerUrl = Uri.parse('https://apifixya.onrender.com/cleaners/login');
        final cleanerResponse = await http.post(
          cleanerUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': emailController.text,
            'password': passwordController.text,
          }),
        );

        if (cleanerResponse.statusCode == 200) {
          // Login exitoso para cleaners
          final dataCleaner = json.decode(cleanerResponse.body);
          userToken = dataCleaner['token'];

          // Obtener datos del cleaner
          final meCleanerResponse = await http.get(
            Uri.parse('https://apifixya.onrender.com/cleaners/me'),
            headers: {'Authorization': 'Bearer $userToken'},
          );

          if (meCleanerResponse.statusCode == 200) {
            final cleanerData = json.decode(meCleanerResponse.body);

            // Guardar token y datos en SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', userToken!);
            await prefs.setInt('cleanerId', cleanerData['id']);
            await prefs.setString('cleanerName', cleanerData['name']);

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Inicio de sesión exitoso')),
            );

            // Redirige a la pantalla de cleaners
            Navigator.pushReplacementNamed(context, '/cleanershome');
            return;
          } else {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al obtener los datos del cleaner')),
            );
            return;
          }
        } else if (cleanerResponse.statusCode == 404) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Limpiador no encontrado')),
          );
          return;
        } else if (cleanerResponse.statusCode == 401) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contraseña incorrecta')),
          );
          return;
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${cleanerResponse.body}')),
          );
          return;
        }
      }
    } on SocketException {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin conexión a internet')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Encabezado con logo y nombre de la app
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFe3f2fd),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'What clean',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 148, 214, 255),
                    ),
                  ),
                  SizedBox(height: 10),
                  Image(
                    image: AssetImage('assets/cleaning.png'),
                    height: 80,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Formulario de inicio de sesión
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inicia sesión en What clean',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'What clean quiere tener una mayor seguridad para sus usuarios, por eso queremos que crees una cuenta para disfrutar los beneficios.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  // Campo de correo electrónico
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Ingresa tu correo electrónico',
                      labelStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 148, 214, 255),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Campo de contraseña con icono para ver/ocultar contraseña
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Ingresa tu contraseña',
                      labelStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 148, 214, 255),
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Botón de inicio de sesión
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 184, 255),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: isLoading ? null : login,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Entrar',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Enlace para ir a la pantalla de registro (usuarios)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text(
                        '¿No tienes cuenta? Regístrate aquí',
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 184, 255),
                        ),
                      ),
                    ),
                  ),
                  // Botón para registro de cleaners
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/registercleaner');
                      },
                      child: const Text(
                        '¿Eres un limpiador? Regístrate aquí',
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 184, 255),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
