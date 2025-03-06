import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'service_form.dart';
import 'payment_failure_screen.dart';
import 'cleanershome.dart';
import 'select_auditor.dart';
import 'main.dart'; // Para acceder al navigatorKey global

class DeepLinkHandler extends StatefulWidget {
  final Widget child;
  const DeepLinkHandler({Key? key, required this.child}) : super(key: key);

  @override
  _DeepLinkHandlerState createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  late final AppLinks appLinks;

  @override
  void initState() {
    super.initState();
    // Se crea la instancia de AppLinks sin parámetros
    appLinks = AppLinks();

    // Suscríbete al stream de enlaces entrantes
    appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    _initDeepLinkListener();
  }

  Future<void> _initDeepLinkListener() async {
    // Manejo del deep link al iniciar la app (cold start)
    try {
      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      print("Error al obtener el enlace inicial: $e");
    }
  }

  void _handleDeepLink(Uri uri) {
    // Verifica que el esquema sea el configurado para la app
    if (uri.scheme == 'cleanya') {
      if (uri.host == 'serviceForm') {
        // Si el pago fue exitoso, redirige a ServiceFormScreen.
        // Aquí se extraen los parámetros desde el URI si fuera necesario.
        final Map<String, dynamic> defaultService = {
          'id': 1,
          'name': 'Servicio de limpieza',
          'price': 100.0,
          'address': 'C. 111 315, Santa Rosa, Mérida, Yuc.',
          'schedule': {
            'days': ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'],
            'startTime': '08:00',
            'endTime': '18:00'
          }
        };

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ServiceFormScreen(service: defaultService),
          ),
        );
      } else if (uri.host == 'failure') {
        // Si el pago falla, redirige a PaymentFailureScreen.
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const PaymentFailureScreen(),
          ),
        );
      } else if (uri.host == 'cleanersuccess') {
        // Si la operación fue exitosa en el flujo Cleaners, redirige a la pantalla para seleccionar auditor.
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const AuditorSelectionScreen(),
          ),
        );
      } else if (uri.host == 'cleanerfailure') {
        // Si la operación falla en Cleaners, regresa a CleanersHome.
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const CleanersHome(),
          ),
        );
      }
      // Puedes agregar más condiciones para otros tipos de deep links si es necesario.
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
