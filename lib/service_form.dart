import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'location_selection_screen.dart';

/// Credenciales de Mercado Pago (Sandbox)
const String mercadoPagoAccessToken =
    'TEST-4550829005870809-022619-790e71ca5222fe1f9614e137d9ff2cc8-1155815200';

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
  DateTime? _selectedDate;

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se usa Material3 para alinearse a los lineamientos actuales
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Servicio'),
        elevation: 4,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Se utiliza Hero para animar la transición de la tarjeta de servicio
            Hero(
              tag: 'serviceCard_${widget.service['id']}',
              child: _buildServiceCard(),
            ),
            const SizedBox(height: 15),
            Form(key: _formKey, child: _buildForm()),
            const SizedBox(height: 20),
            _buildNextButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard() {
    return Card(
      color: const Color(0xFF94D6FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(widget.service['id']),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.service['name'] ?? 'Servicio limpieza',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 5),
              Text(
                widget.service['address'] ??
                    'C. 111 315, Santa Rosa, 97279 Mérida, Yuc.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('\$${widget.service['price'] ?? 'XXXXX'}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
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
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Datos del servicio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(widget.service['name'] ?? 'Servicio sin nombre',
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
              _buildDateField(),
              _buildTimeField(),
              _buildAddressField(),
            ],
          ),
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
          suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF01497C)),
        ),
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Selecciona una fecha' : null,
        onTap: () async {
          final today = DateTime.now();
          final firstDate = DateTime(today.year, today.month, today.day);
          final weekDays = {
            1: "Lunes",
            2: "Martes",
            3: "Miércoles",
            4: "Jueves",
            5: "Viernes",
            6: "Sábado",
            7: "Domingo"
          };
          final allowedDays = widget.service['schedule']?['days'] ?? [];
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: today,
            firstDate: firstDate,
            lastDate: DateTime(2030),
            selectableDayPredicate: (date) =>
                allowedDays.contains(weekDays[date.weekday]),
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
          suffixIcon: const Icon(Icons.access_time, color: Color(0xFF01497C)),
        ),
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Selecciona una hora' : null,
        onTap: () async {
          if (_selectedDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Selecciona primero una fecha")));
            return;
          }
          TimeOfDay? pickedTime =
              await showTimePicker(context: context, initialTime: TimeOfDay.now());
          if (pickedTime != null) {
            final allowedStartStr =
                widget.service['schedule']?['startTime'] ?? "00:00";
            final allowedEndStr =
                widget.service['schedule']?['endTime'] ?? "23:59";
            final allowedStartParts = allowedStartStr.split(":");
            final allowedEndParts = allowedEndStr.split(":");
            final allowedStartTime = TimeOfDay(
                hour: int.parse(allowedStartParts[0]),
                minute: int.parse(allowedStartParts[1]));
            final allowedEndTime = TimeOfDay(
                hour: int.parse(allowedEndParts[0]),
                minute: int.parse(allowedEndParts[1]));
            int toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;
            if (toMinutes(pickedTime) < toMinutes(allowedStartTime) ||
                toMinutes(pickedTime) > toMinutes(allowedEndTime)) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      "La hora seleccionada no está dentro del horario permitido")));
              return;
            }
            final now = DateTime.now();
            if (_selectedDate!.year == now.year &&
                _selectedDate!.month == now.month &&
                _selectedDate!.day == now.day) {
              final selectedDateTime = DateTime(
                  _selectedDate!.year,
                  _selectedDate!.month,
                  _selectedDate!.day,
                  pickedTime.hour,
                  pickedTime.minute);
              if (selectedDateTime.isBefore(now)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("La hora seleccionada ya pasó")));
                return;
              }
            }
            setState(() {
              _timeController.text =
                  "${pickedTime.hour}:${pickedTime.minute.toString().padLeft(2, '0')}:00";
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
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Selecciona una ubicación' : null,
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdditionalQuestionsScreen(
                    service: widget.service,
                    date: _selectedDate != null ? _selectedDate!.toIso8601String() : '',
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

/// Pantalla para completar los últimos pasos y seleccionar el método de pago (Mercado Pago).
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
  String? _paymentMethod; // "mercadopago"
  String? _paymentReferenceId;
  final TextEditingController _additionalDescriptionController =
      TextEditingController();

  @override
  void dispose() {
    _additionalDescriptionController.dispose();
    super.dispose();
  }

  /// Combina la fecha y la hora en un objeto DateTime.
  DateTime _combineDateAndTime() {
    DateTime datePart = DateTime.parse(widget.date);
    List<String> timeParts = widget.time.split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    int second = int.parse(timeParts[2]);
    return DateTime(datePart.year, datePart.month, datePart.day, hour, minute, second);
  }

  /// Valida que no exista ya una propuesta para el mismo servicio con fecha y hora
  /// en una franja menor a 2 horas.
  Future<String?> _validateProposalTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/proposals/my?size=9999999999999'),
        headers: {
          "accept": "*/*",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final proposals = jsonResponse['proposals'] as List<dynamic>;
        DateTime newProposalDateTime = _combineDateAndTime();

        for (var proposal in proposals) {
          if (proposal['serviceId'] == widget.service['id']) {
            DateTime existingProposalDateTime = DateTime.parse(proposal['datetime']);
            if (existingProposalDateTime.year == newProposalDateTime.year &&
                existingProposalDateTime.month == newProposalDateTime.month &&
                existingProposalDateTime.day == newProposalDateTime.day) {
              int diffMinutes = newProposalDateTime.difference(existingProposalDateTime).inMinutes.abs();
              if (diffMinutes < 120) {
                return "Ya existe una propuesta para este servicio con diferencia de menos de 2 horas. La propuesta existente es a las ${existingProposalDateTime.hour}:${existingProposalDateTime.minute.toString().padLeft(2, '0')}.";
              }
            }
          }
        }
        return null;
      } else {
        return "Error en la validación de tiempo: no se pudo obtener las propuestas.";
      }
    } catch (e) {
      print('Error en validación de tiempo: $e');
      return "Error en la validación de tiempo: $e";
    }
  }

  /// Función para lanzar el Checkout de Mercado Pago.
  Future<void> _launchMercadopagoCheckout() async {
    final preferenceBody = jsonEncode({
      "items": [
        {
          "title": widget.service['name'] ?? "Servicio",
          "quantity": 1,
          "currency_id": "MXN",
          "unit_price": widget.service['price'] != null
              ? double.tryParse(widget.service['price'].toString()) ?? 10.00
              : 10.00,
        }
      ],
      "back_urls": {
        "success": "cleanya://serviceForm",
        "failure": "cleanya://failure",
        "pending": "https://apifixya.onrender.com/mercadopago/pending",
      },
      "auto_return": "approved"
    });

    final response = await http.post(
      Uri.parse("https://api.mercadopago.com/checkout/preferences?access_token=$mercadoPagoAccessToken"),
      headers: {"Content-Type": "application/json"},
      body: preferenceBody,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseJson = jsonDecode(response.body);
      setState(() {
        _paymentMethod = "mercadopago";
        _paymentReferenceId = responseJson['id'].toString();
      });

      final initPoint = responseJson['init_point'];
      final Uri checkoutUri = Uri.parse(initPoint);
      if (await canLaunchUrl(checkoutUri)) {
        await launchUrl(checkoutUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No se pudo abrir el Checkout de Mercado Pago")));
      }
    } else {
      print("Error: ${response.statusCode}");
      print("Detalle: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          "Error al crear preferencia de Mercado Pago: ${response.statusCode}\nDetalle: ${response.body}",
          textAlign: TextAlign.center,
        ),
      ));
    }
  }

  Widget _buildPaymentOptionsSection() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Column(
        key: ValueKey(_paymentReferenceId),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Seleccione el método de pago:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _launchMercadopagoCheckout,
              child: const Text('Pagar con Mercado Pago',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
          if (_paymentReferenceId != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10)),
              child: Text("Método: $_paymentMethod\nReferencia: $_paymentReferenceId",
                  style: const TextStyle(fontSize: 16)),
            ),
        ],
      ),
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
        validator: (value) =>
            (value == null || value.trim().isEmpty)
                ? 'Este campo es obligatorio'
                : null,
      ),
    );
  }

  /// Envía la propuesta incluyendo la combinación de fecha y hora.
  Future<void> _submitProposal() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _usuarioEnCasa == null ||
        _servicioConstante == null ||
        _paymentReferenceId == null ||
        _paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Todos los campos son obligatorios")));
      return;
    }

    String? errorMessage = await _validateProposalTime();
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId') ?? 0;

      DateTime proposalDateTime = _combineDateAndTime();

      final proposalData = {
        "serviceId": widget.service['id'] ?? 0,
        "userId": userId,
        "datetime": proposalDateTime.toIso8601String(),
        "status": "pending",
        "direccion": widget.direccion,
        "Descripcion": _additionalDescriptionController.text,
        "UsuarioEnCasa": _usuarioEnCasa,
        "servicioConstante": _servicioConstante,
        "tipodeservicio": widget.tipodeservicio,
        "paymentMethod": _paymentMethod,
        "paymentReferenceId": _paymentReferenceId,
      };

      final response = await http.post(
        Uri.parse('https://apifixya.onrender.com/proposals'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(proposalData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Propuesta creada correctamente')));
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else if (response.statusCode == 400) {
        // Se parsea el error para mostrar su contenido
        final errorJson = jsonDecode(response.body);
        final errorMsg = errorJson['error'] ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error ${response.statusCode}: $errorMsg')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Últimos pasos'),
        elevation: 4,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      const Text('Últimos pasos',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
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
                      _buildPaymentOptionsSection(),
                      _buildTextField(_additionalDescriptionController,
                          'Describe algo adicional al formulario'),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF01497C),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _submitProposal,
                          child: const Text('Solicitar',
                              style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
