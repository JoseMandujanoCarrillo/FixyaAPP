import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Función auxiliar para formatear un DateTime e incluir el offset de la zona horaria.
String formatDateTimeWithTimezone(DateTime dateTime) {
  final offset = dateTime.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  return '${dateTime.toIso8601String()}$sign$hours:$minutes';
}

/// Pantalla para llenar los datos iniciales del servicio.
class ServiceFormScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceFormScreen({Key? key, required this.service}) : super(key: key);

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _tipoServicioController = TextEditingController();

  DateTime? _selectedDate; // Guarda la fecha seleccionada

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _addressController.dispose();
    _tipoServicioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildServiceCard(),
            const SizedBox(height: 15),
            _buildForm(),
            const SizedBox(height: 20),
            _buildNextButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.service['name'] ?? 'Servicio limpieza',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 5),
            Text(
              widget.service['address'] ?? 'C. 111 315, Santa Rosa, 97279 Mérida, Yuc.',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '\$${widget.service['price'] ?? 'XXXXX'}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const Text(' aprox', style: TextStyle(fontSize: 14, color: Colors.green)),
                const Spacer(),
                const CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 25,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos del servicio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Campo para el tipo de servicio.
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: TextField(
                controller: _tipoServicioController,
                decoration: InputDecoration(
                  hintText: 'Selecciona un tipo de servicio',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                ),
              ),
            ),
            _buildDateField(),
            _buildTimeField(),
            _buildAddressField(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: _dateController,
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'DD/MM/AA',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade200,
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
        ),
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2022),
            lastDate: DateTime(2030),
          );
          if (pickedDate != null) {
            setState(() {
              _selectedDate = pickedDate;
              // Formateamos la fecha en formato dd/MM/yyyy para mostrarla.
              _dateController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
            });
          }
        },
      ),
    );
  }

  Widget _buildTimeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: _timeController,
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'HH/MM/SS',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade200,
          suffixIcon: const Icon(Icons.access_time, color: Colors.blue),
        ),
        onTap: () async {
          TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (pickedTime != null) {
            setState(() {
              // Formateamos la hora en formato "HH:MM:SS"
              _timeController.text = "${pickedTime.hour}:${pickedTime.minute}:00";
            });
          }
        },
      ),
    );
  }

  Widget _buildAddressField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: _addressController,
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'Ubicación (toca para seleccionar)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade200,
          suffixIcon: const Icon(Icons.map, color: Colors.blue),
        ),
        onTap: () async {
          // Navegar a la pantalla de selección de ubicación.
          final selectedAddress = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapSelectionScreen()),
          );
          if (selectedAddress != null) {
            setState(() {
              _addressController.text = selectedAddress;
            });
          }
        },
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            // Validamos que se haya seleccionado fecha y hora
            if (_selectedDate != null && _timeController.text.isNotEmpty) {
              // Separamos las partes de la hora (se asume formato "HH:MM:SS")
              final timeParts = _timeController.text.split(':');
              final hour = int.tryParse(timeParts[0]) ?? 0;
              final minute = int.tryParse(timeParts[1]) ?? 0;
              final second = timeParts.length > 2 ? int.tryParse(timeParts[2]) ?? 0 : 0;
              
              // Combinamos la fecha y la hora en un único objeto DateTime en hora local.
              final combinedDateTime = DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                hour,
                minute,
                second,
              );
              
              // Formateamos el DateTime incluyendo la zona horaria.
              final formattedDateTime = formatDateTimeWithTimezone(combinedDateTime);
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdditionalQuestionsScreen(
                    service: widget.service,
                    date: formattedDateTime,
                    time: _timeController.text,
                    direccion: _addressController.text,
                    tipodeservicio: _tipoServicioController.text,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Debes seleccionar fecha y hora')),
              );
            }
          },
          child: const Text('Siguiente', style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }
}

/// Pantalla para completar los últimos pasos y crear la propuesta.
class AdditionalQuestionsScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final String date;
  final String time;
  final String direccion;
  final String tipodeservicio;

  const AdditionalQuestionsScreen({
    Key? key,
    required this.service,
    required this.date,
    required this.time,
    required this.direccion,
    required this.tipodeservicio,
  }) : super(key: key);

  @override
  State<AdditionalQuestionsScreen> createState() => _AdditionalQuestionsScreenState();
}

class _AdditionalQuestionsScreenState extends State<AdditionalQuestionsScreen> {
  bool? _usuarioEnCasa;
  List<dynamic> _creditCards = [];
  dynamic _selectedCreditCard; // Puede ser el Map completo o solo el id, según convenga.
  final TextEditingController _additionalDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCreditCards();
  }

  @override
  void dispose() {
    _additionalDescriptionController.dispose();
    super.dispose();
  }

  /// Recupera las tarjetas del usuario logueado usando el token almacenado.
  Future<void> _fetchCreditCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/creditcards/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _creditCards = jsonDecode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener las tarjetas: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// Envía la propuesta usando el token y el userId real almacenado en SharedPreferences.
  Future<void> _submitProposal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      // Se asume que el endpoint de login guardó el userId en SharedPreferences.
      final userId = prefs.getInt('userId') ?? 0;
      
      final proposalData = {
        "serviceId": widget.service['id'] ?? 0,
        "userId": userId,
        // Usamos la fecha que se envió desde ServiceFormScreen.
        "date": widget.date.isNotEmpty ? widget.date : DateTime.now().toIso8601String(),
        "status": "pending", // Siempre pendiente al crear la propuesta.
        "direccion": widget.direccion,
        "cardId": _selectedCreditCard != null ? _selectedCreditCard['id'] : null,
        "Descripcion": _additionalDescriptionController.text,
        "UsuarioEnCasa": _usuarioEnCasa,
        "tipodeservicio": widget.tipodeservicio,
      };

      final response = await http.post(
        Uri.parse('https://apifixya.onrender.com/proposals'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(proposalData),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Propuesta creada correctamente')),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildCreditCardDropdown() {
    if (_creditCards.isEmpty) {
      return const Text('Cargando tarjetas...');
    }

    return DropdownButtonFormField<dynamic>(
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade200,
      ),
      value: _selectedCreditCard,
      hint: const Text('Seleccione el método de pago'),
      items: _creditCards.map<DropdownMenuItem<dynamic>>((card) {
        return DropdownMenuItem<dynamic>(
          value: card,
          child: Text(card['cardNumber'] ?? 'Tarjeta ${card['id']}'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCreditCard = value;
        });
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade200,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text('Últimos pasos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Al momento de realizar el servicio, ¿se encontrará en la ubicación?'),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      value: true,
                      groupValue: _usuarioEnCasa,
                      onChanged: (bool? value) {
                        setState(() {
                          _usuarioEnCasa = value;
                        });
                      },
                      title: const Text("Sí"),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      value: false,
                      groupValue: _usuarioEnCasa,
                      onChanged: (bool? value) {
                        setState(() {
                          _usuarioEnCasa = value;
                        });
                      },
                      title: const Text("No"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildCreditCardDropdown(),
              const SizedBox(height: 10),
              _buildTextField(_additionalDescriptionController, 'Describe algo adicional al formulario'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitProposal,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900),
                child: const Text('Solicitar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pantalla dummy para seleccionar una ubicación.
/// Reemplaza esta pantalla con la implementación real de selección de mapas.
class MapSelectionScreen extends StatelessWidget {
  const MapSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Retorna una ubicación de ejemplo.
            Navigator.pop(context, 'Ubicación Seleccionada');
          },
          child: const Text('Seleccionar Ubicación'),
        ),
      ),
    );
  }
}
