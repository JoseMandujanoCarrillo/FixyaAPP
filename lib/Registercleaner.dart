import 'dart:convert';
import 'dart:io'; // Para manejar excepciones de conexión
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RegisterCleanerScreen extends StatefulWidget {
  const RegisterCleanerScreen({Key? key}) : super(key: key);

  @override
  _RegisterCleanerScreenState createState() => _RegisterCleanerScreenState();
}

class _RegisterCleanerScreenState extends State<RegisterCleanerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;

  Future<void> registerCleaner() async {
    // Valida el formulario
    if (!_formKey.currentState!.validate()) return;

    // Validar que ambas contraseñas coincidan (además de lo que valida el validator)
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Mostrar un diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Registrar al cleaner
      final registerUrl =
          Uri.parse('https://apifixya.onrender.com/cleaners/register');
      final registerResponse = await http.post(
        registerUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': nameController.text,
          'email': emailController.text.trim(),
          'password': passwordController.text,
          'latitude': 0.0,
          'longitude': 0.0,
        }),
      );

      Navigator.pop(context); // Cerrar el diálogo de carga

      if (registerResponse.statusCode == 201) {
        // Registro exitoso, proceder a loguearse como cleaner
        final loginUrl =
            Uri.parse('https://apifixya.onrender.com/cleaners/login');
        final loginResponse = await http.post(
          loginUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': emailController.text.trim(),
            'password': passwordController.text,
          }),
        );

        if (loginResponse.statusCode == 200) {
          final loginData = json.decode(loginResponse.body);
          final String cleanerToken = loginData['token'];

          // Obtener datos del cleaner
          final meUrl = Uri.parse('https://apifixya.onrender.com/cleaners/me');
          final meResponse = await http.get(
            meUrl,
            headers: {'Authorization': 'Bearer $cleanerToken'},
          );

          if (meResponse.statusCode == 200) {
            final cleanerData = json.decode(meResponse.body);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', cleanerToken);
            await prefs.setInt('cleanerId', cleanerData['id']);
            await prefs.setString('cleanerName', cleanerData['name']);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registro e inicio de sesión como cleaner exitoso'),
              ),
            );
            Navigator.pushReplacementNamed(context, '/cleanershome');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Fallo en la API al obtener datos del cleaner: ${meResponse.body}'),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Fallo en la API al iniciar sesión como cleaner: ${loginResponse.body}'),
            ),
          );
        }
      } else if (registerResponse.statusCode == 409) {
        // Asumimos que el 409 indica que el usuario ya está registrado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario ya registrado')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Fallo en la API al registrar: ${registerResponse.body}'),
          ),
        );
      }
    } on SocketException {
      Navigator.pop(context); // Cerrar el diálogo de carga en caso de error
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: Color.fromARGB(255, 148, 214, 255)),
      ),
    );
  }

  // Validator para el correo electrónico
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa un correo electrónico';
    }
    final RegExp emailRegex =
        RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Por favor ingresa un correo electrónico válido';
    }
    return null;
  }

  // Validator para el nombre de usuario
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu nombre';
    }
    return null;
  }

  // Validator para la contraseña
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa una contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  // Validator para confirmar la contraseña
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu contraseña';
    }
    if (value != passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Encabezado con logo y nombre de la aplicación
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFe3f2fd),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'cleanYa',
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
            // Formulario de registro de cleaner con validadores
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Regístrate como Cleaner',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailController,
                      decoration: _inputDecoration('Correo electrónico'),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      decoration: _inputDecoration('Nombre de usuario'),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: passwordController,
                      decoration: _inputDecoration('Contraseña'),
                      obscureText: true,
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: confirmPasswordController,
                      decoration: _inputDecoration('Confirmar contraseña'),
                      obscureText: true,
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 30),
                    // Botón de registro
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 0, 184, 255),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: isLoading ? null : registerCleaner,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Registrarse',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text(
                          '¿Ya tienes una cuenta? Inicia sesión aquí',
                          style: TextStyle(
                              color: Color.fromARGB(255, 0, 184, 255)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
