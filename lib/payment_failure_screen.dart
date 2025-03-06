import 'package:flutter/material.dart'; // Importa la biblioteca principal de Flutter para UI.

// Pantalla que muestra un mensaje cuando el pago ha fallado.
class PaymentFailureScreen extends StatelessWidget {
  const PaymentFailureScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago Fallido'), // Título en la barra de navegación.
        automaticallyImplyLeading: false, // Evita que aparezca el botón de retroceso.
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // Aplica un margen interno al contenido.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centra los elementos en la pantalla.
            children: [
              Icon(
                Icons.error_outline, // Ícono de advertencia.
                size: 100,
                color: Colors.red[400], // Color rojo para indicar error.
              ),
              const SizedBox(height: 20), // Espaciado entre elementos.
              const Text(
                'El pago ha fallado', // Mensaje principal.
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Hubo un problema al procesar su pago. Por favor, intente nuevamente o comuníquese con soporte.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Regresa a la pantalla principal y elimina las pantallas anteriores de la pila.
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF01497C), // Color de fondo del botón.
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25), // Botón con bordes redondeados.
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32), // Ajusta el tamaño del botón.
                ),
                child: const Text(
                  'Volver al inicio', // Texto dentro del botón.
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
