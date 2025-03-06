import 'package:flutter/material.dart';
import 'principal.dart'; // Asegúrate de importar la pantalla principal
import 'ajustes.dart';
import 'chat.dart';
import 'tu.dart';

class SolicitarServicio extends StatefulWidget {
  const SolicitarServicio({super.key});

  @override
  _SolicitarServicioState createState() => _SolicitarServicioState();
}

class _SolicitarServicioState extends State<SolicitarServicio> {
  double _progress = 0.0;
  int _step = 1;
  String? _selectedDate;
  String? _selectedTime;
  String? _selectedLocation;
  bool _isToday = false;
  String? _paymentMethod;
  bool _isLoading = false;

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFF94D6FF),
    ),
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título "Solicitud"
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: Text(
              "Solicitud",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Barra de progreso
          Padding(
            padding: const EdgeInsets.all(20),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              color: const Color(0xFF01497C),
            ),
          ),
          _buildServiceCard(),
          _step == 1 ? _buildFormCard() : _buildSecondFormCard(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ElevatedButton(
              onPressed: _onNextPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4269),
                padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _step == 1 ? "Siguiente" : "Confirmar",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: _buildBottomNavBar(),
    floatingActionButton: _isLoading
        ? Container(
            color: Colors.black54, // Fondo semitransparente
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue), // Color de la animación
              ),
            ),
          )
        : null, // Si no está cargando, no mostrar el overlay
  );
}

  Widget _buildServiceCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Servicio seleccionado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Limpieza rápida del área del comedor, garantizando un ambiente libre de polvo y residuos.\n'
              'De Lunes a viernes de 8:00 a.m - 8:00 p.m',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Costo: \$1500',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildForm(),
      ),
    );
  }

  Widget _buildSecondFormCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Últimos Pasos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "¿Al momento de realizar el servicio se encontrará en la ubicación?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Column(
              children: [
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _isToday,
                      onChanged: (value) {
                        setState(() {
                          _isToday = value!;
                        });
                      },
                    ),
                    const Text("Sí"),
                  ],
                ),
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: _isToday,
                      onChanged: (value) {
                        setState(() {
                          _isToday = value!;
                        });
                      },
                    ),
                    const Text("No"),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Método de pago",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () => _showPaymentMethodDialog(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _paymentMethod ?? "Seleccione el método de pago",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Datos adicionales",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Escribe cualquier detalle adicional...",
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Seleccione el método de pago"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Pago en efectivo"),
                onTap: () {
                  setState(() {
                    _paymentMethod = "Pago en efectivo";
                    _progress = 0.9; // Incrementar la barra al 90% al seleccionar el pago
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Pago con tarjeta"),
                onTap: () {
                  setState(() {
                    _paymentMethod = "Pago con tarjeta";
                    _progress = 0.9; // Incrementar la barra al 90% al seleccionar el pago
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Datos del servicio"),
        const Text(
          "¿Desea solicitar el servicio para hoy?",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Column(
          children: [
            Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: _isToday,
                  onChanged: (value) {
                    setState(() {
                      _isToday = value!;
                    });
                  },
                ),
                const Text("Sí"),
              ],
            ),
            Row(
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: _isToday,
                  onChanged: (value) {
                    setState(() {
                      _isToday = value!;
                    });
                  },
                ),
                const Text("No"),
              ],
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildInputField("Fecha:", _selectedDate ?? "DD/MM/AA", () => _selectDate(context)),
        _buildInputField("Hora:", _selectedTime ?? "HH:MM", () => _selectTime(context)),
        _buildInputField("Ubicación:", _selectedLocation ?? "Ingresa tu ubicación", null, isTextField: true),
      ],
    );
  }

  Widget _buildInputField(String label, String hint, VoidCallback? onTap, {bool isTextField = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isTextField
                  ? TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Ingresa tu ubicación",
                      ),
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value;
                        });
                      },
                    )
                  : Text(
                      hint,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = "${picked.hour}:${picked.minute}";
      });
    }
  }

  void _onNextPressed() {
    setState(() {
      if (_step == 1) {
        _progress = 0.5;
        _step = 2;
      } else {
        _startLoading();
      }
    });
  }

  // Animación de carga y redirección
  void _startLoading() async {
    setState(() {
      _isLoading = true;
      _progress = 0.95; // Aumenta la barra al 95% cuando se hace clic en "Confirmar"
    });

    await Future.delayed(const Duration(seconds: 3)); // Espera 3 segundos

    setState(() {
      _isLoading = false;
      _progress = 1.0; // Barra completa
    });

    // Mostrar mensaje y redirigir a la pantalla principal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Servicio solicitado correctamente")),
    );

    // Navegar a la pantalla principal
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PantallaPrincipal()), // Reemplaza 'Principal' con la ruta adecuada
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono6.png"), color: Color(0xFF9E9E9E)),
              Text("INICIO", style: TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono7.png"), color: Color(0xFF9E9E9E)),
              Text("AJUSTES", style: TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono8.png"), color: Color(0xFF9E9E9E)),
              Text("CHAT", style: TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Column(
            children: [
              ImageIcon(AssetImage("assets/iconos/icono9.png"), color: Color(0xFF9E9E9E)),
              Text("TÚ", style: TextStyle(color: Color(0xFF9E9E9E))),
            ],
          ),
          label: '',
        ),
      ],
      selectedItemColor: const Color(0xFF9E9E9E),
      unselectedItemColor: const Color(0xFF9E9E9E),
      currentIndex: 0,
           onTap: (index) {
          switch (index) {
            case 1: // Índice de la opción "AJUSTES"
              Navigator.push( context,
                MaterialPageRoute( builder: (context) => Ajustes()), // Navega a la pantalla Ajustes
              );
              break;
            case 2: 
              Navigator.push( context,
                MaterialPageRoute( builder: (context) => ChatListScreen ()), // Navega a la pantalla chat
              );
              break;
              case 3: 
              Navigator.push( context,
                MaterialPageRoute( builder: (context) => TuScreen ()), // Navega a la pantalla de perfil
              );
              break;
         }
       }
    );
  }
}
