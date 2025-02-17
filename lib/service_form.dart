import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'location_selection_screen.dart';
import 'add_card_screen.dart'; // Asegúrate de que la ruta sea la correcta

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate; // Guarda la fecha seleccionada

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar con flecha para volver a la pantalla anterior
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Servicio'),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildServiceCard(),
            const SizedBox(height: 15),
            Form(
              key: _formKey,
              child: _buildForm(),
            ),
            const SizedBox(height: 20),
            _buildNextButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard() {
    return Card(
      color: const Color(0xFF94D6FF), // Azul insignia
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
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 5),
            Text(
              widget.service['address'] ??
                  'C. 111 315, Santa Rosa, 97279 Mérida, Yuc.',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '\$${widget.service['price'] ?? 'XXXXX'}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
                const Text(' aprox',
                    style: TextStyle(fontSize: 14, color: Colors.green)),
                const Spacer(),
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 25,
                  child: Icon(Icons.person,
                      color: Color(0xFF94D6FF), size: 30),
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
      color: Colors.white,
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
            // Muestra el nombre del servicio (no editable)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.service['name'] ?? 'Servicio sin nombre',
                  style: const TextStyle(fontSize: 16),
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
      child: TextFormField(
        controller: _dateController,
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'DD/MM/AA',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade200,
          suffixIcon:
              const Icon(Icons.calendar_today, color: Color(0xFF01497C)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Selecciona una fecha';
          }
          return null;
        },
        onTap: () async {
          final today = DateTime.now();
          final firstDate = DateTime(today.year, today.month, today.day);
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: today,
            firstDate: firstDate,
            lastDate: DateTime(2030),
          );
          if (pickedDate != null) {
            setState(() {
              _selectedDate = pickedDate;
              _dateController.text =
                  "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
              _timeController.clear();
            });
          }
        },
      ),
    );
  }

  Widget _buildTimeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: _timeController,
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'HH:MM:SS',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade200,
          suffixIcon:
              const Icon(Icons.access_time, color: Color(0xFF01497C)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Selecciona una hora';
          }
          return null;
        },
        onTap: () async {
          if (_selectedDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Selecciona primero una fecha")),
            );
            return;
          }
          TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (pickedTime != null) {
            final now = DateTime.now();
            if (_selectedDate!.year == now.year &&
                _selectedDate!.month == now.month &&
                _selectedDate!.day == now.day) {
              final selectedDateTime = DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                pickedTime.hour,
                pickedTime.minute,
              );
              if (selectedDateTime.isBefore(now)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("La hora seleccionada ya pasó")),
                );
                return;
              }
            }
            setState(() {
              _timeController.text =
                  "${pickedTime.hour}:${pickedTime.minute}:00";
            });
          }
        },
      ),
    );
  }

  Widget _buildAddressField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: _addressController,
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'Ubicación (toca para seleccionar)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade200,
          suffixIcon: const Icon(Icons.map, color: Color(0xFF01497C)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Selecciona una ubicación';
          }
          return null;
        },
        onTap: () async {
          final selectedAddress = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const LocationSelectionScreen()),
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
            backgroundColor: const Color(0xFF01497C),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdditionalQuestionsScreen(
                    service: widget.service,
                    date: _selectedDate != null
                        ? _selectedDate!.toIso8601String()
                        : '',
                    time: _timeController.text,
                    direccion: _addressController.text,
                    tipodeservicio: widget.service['name'],
                  ),
                ),
              );
            }
          },
          child: const Text('Siguiente',
              style: TextStyle(fontSize: 16, color: Colors.white)),
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
  State<AdditionalQuestionsScreen> createState() =>
      _AdditionalQuestionsScreenState();
}

class _AdditionalQuestionsScreenState extends State<AdditionalQuestionsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool? _usuarioEnCasa;
  bool? _servicioConstante;
  List<dynamic> _creditCards = [];
  dynamic _selectedCreditCard;
  final TextEditingController _additionalDescriptionController =
      TextEditingController();

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
          SnackBar(
              content:
                  Text('Error al obtener las tarjetas: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// Envía la propuesta usando el token y la id del usuario actualmente logueado.
  Future<void> _submitProposal() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _usuarioEnCasa == null ||
        _servicioConstante == null ||
        _selectedCreditCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Todos los campos son obligatorios")),
      );
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      // Se asume que el endpoint de login guardó la id del usuario actual en SharedPreferences.
      final userId = prefs.getInt('userId') ?? 0;

      final proposalData = {
        "serviceId": widget.service['id'] ?? 0,
        "userId": userId,
        "date": widget.date,
        "status": "pending",
        "direccion": widget.direccion,
        "cardId": _selectedCreditCard['id'],
        "Descripcion": _additionalDescriptionController.text,
        "UsuarioEnCasa": _usuarioEnCasa,
        "servicioConstante": _servicioConstante,
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
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('No tienes tarjetas guardadas.'),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF01497C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddCardScreen()),
              );
              _fetchCreditCards();
            },
            child: const Text('Agregar Tarjeta',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      );
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
          child: Text(card['nickname'] ?? 'Tarjeta ${card['id']}'),
        );
      }).toList(),
      validator: (value) {
        if (value == null) {
          return 'Seleccione un método de pago';
        }
        return null;
      },
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
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade200,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Este campo es obligatorio';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar con flecha para volver a la pantalla anterior
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Últimos pasos'),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    const Text('Últimos pasos',
                        style:
                            TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text(
                        'Al momento de realizar el servicio, ¿se encontrará en la ubicación?'),
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
                    const Text('¿Será un servicio constante?'),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            value: true,
                            groupValue: _servicioConstante,
                            onChanged: (bool? value) {
                              setState(() {
                                _servicioConstante = value;
                              });
                            },
                            title: const Text("Sí"),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            value: false,
                            groupValue: _servicioConstante,
                            onChanged: (bool? value) {
                              setState(() {
                                _servicioConstante = value;
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
                    _buildTextField(_additionalDescriptionController,
                        'Describe algo adicional al formulario'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF01497C),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _submitProposal,
                      child: const Text('Solicitar',
                          style:
                              TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
