import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_notification_service.dart'; // Asegúrate de tener este archivo creado
import 'home.dart';
import 'login.dart';
import 'register.dart';
import 'Registercleaner.dart';
import 'cleanershome.dart';
import 'addService.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forzar solo orientaciones verticales
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Inicializa el servicio de notificaciones locales
  await LocalNotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'What Clean',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Se inicia la app con la pantalla splash
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/registercleaner': (context) => const RegisterCleanerScreen(),
        '/home': (context) => const HomeScreen(),
        '/cleanershome': (context) => const CleanersHome(),
        '/addService': (context) => const AddServiceScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    // Opcional: agregar retardo para mostrar el splash
    await Future.delayed(const Duration(seconds: 2));

    if (token != null) {
      // Si existe el token, se determina si es usuario o cleaner
      if (prefs.containsKey('userId')) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (prefs.containsKey('cleanerId')) {
        Navigator.pushReplacementNamed(context, '/cleanershome');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
