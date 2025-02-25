import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Método de registro
  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator()),
    );

    try {
      // Verificar si ya existe un cleaner con ese email
      final email = emailController.text.trim();
      final existsUrl = Uri.parse(
          'https://apifixya.onrender.com/cleaners/exists?email=$email');
      final existsResponse = await http.get(existsUrl);

      if (existsResponse.statusCode == 200) {
        final existsData = json.decode(existsResponse.body);
        if (existsData['exists'] == true) {
          Navigator.pop(context); // Cerrar el diálogo de carga
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('El correo ya está registrado como cleaner.')),
          );
          setState(() {
            isLoading = false;
          });
          return;
        }
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Fallo en la API al verificar el correo: ${existsResponse.body}')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Paso 1: Registrar el usuario
      final registerUrl =
          Uri.parse('https://apifixya.onrender.com/users/register');
      final registerResponse = await http.post(
        registerUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': nameController.text,
          'email': email,
          'password': passwordController.text,
        }),
      );

      // Cerrar el diálogo de carga
      Navigator.pop(context);

      if (registerResponse.statusCode == 201) {
        // Registro exitoso, se agrega un pequeño retraso si se requiere
        await Future.delayed(const Duration(seconds: 2));

        // Paso 2: Iniciar sesión para obtener el token
        final loginUrl =
            Uri.parse('https://apifixya.onrender.com/users/login');
        final loginResponse = await http.post(
          loginUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': email,
            'password': passwordController.text,
          }),
        );

        if (loginResponse.statusCode == 200) {
          final loginData = json.decode(loginResponse.body);
          final String userToken = loginData['token'];

          // Paso 3: Obtener los datos del usuario
          final userUrl =
              Uri.parse('https://apifixya.onrender.com/users/me');
          final userResponse = await http.get(
            userUrl,
            headers: {'Authorization': 'Bearer $userToken'},
          );

          if (userResponse.statusCode == 200) {
            final userData = json.decode(userResponse.body);

            // Guardar el token y los datos del usuario en SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', userToken);
            await prefs.setInt('userId', userData['id']);
            await prefs.setString('userName', userData['name']);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registro y login exitosos')),
            );
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Fallo en la API al obtener datos del usuario: ${userResponse.body}')),
            );
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Fallo en la API al iniciar sesión: ${loginResponse.body}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Fallo en la API al registrar: ${registerResponse.body}')),
        );
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

  // Decoración común para los campos de entrada, con opción de suffixIcon
  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
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
      suffixIcon: suffixIcon,
    );
  }

  // Validator para el correo electrónico
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu correo electrónico';
    }
    final RegExp emailRegex =
        RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Por favor ingresa un correo válido';
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
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.trim().length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            // Formulario de registro con validadores
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Regístrate en cleanYa',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'cleanYA quiere tener una mayor seguridad para sus usuarios, por eso queremos que crees una cuenta para disfrutar los beneficios.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    // Campo de correo electrónico
                    TextFormField(
                      controller: emailController,
                      decoration:
                          _inputDecoration('Ingresa tu correo electrónico'),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),
                    // Campo de nombre de usuario
                    TextFormField(
                      controller: nameController,
                      decoration:
                          _inputDecoration('Ingresa tu nombre de usuario'),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 20),
                    // Campo de contraseña
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        'Ingresa tu contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 20),
                    // Campo de confirmar contraseña
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: _inputDecoration(
                        'Confirma tu contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: _validatePassword,
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: isLoading ? null : register,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Registrarse',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Enlace para redirigir a la pantalla de inicio de sesión
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
