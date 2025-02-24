import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({Key? key}) : super(key: key);

  @override
  _AddServiceScreenState createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  File? _selectedImage; // Almacenará la imagen seleccionada
  bool _isLoading = false;

  // Variables para el schedule
  List<String> _selectedDays = [];
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Permite al usuario seleccionar una imagen de la galería.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  /// Sube la imagen a Imgur y retorna la URL resultante.
  /// Recuerda reemplazar "YOUR_IMGUR_CLIENT_ID" por tu Client-ID real.
  Future<String?> _uploadImage(File imageFile) async {
    final uri = Uri.parse('https://api.imgur.com/3/upload');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    request.headers['Authorization'] = 'Client-ID 32794ee601322f0';

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);
      if (data['success'] == true) {
        // Se asume que la respuesta de Imgur contiene la URL en data.link
        return data['data']['link'];
      }
    }
    return null;
  }

  /// Helper para formatear un TimeOfDay a "HH:mm"
  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Construye la sección para seleccionar el schedule.
  Widget _buildSchedulePicker() {
    final List<String> daysOfWeek = [
      "Lunes",
      "Martes",
      "Miércoles",
      "Jueves",
      "Viernes",
      "Sábado",
      "Domingo"
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Selecciona los días del servicio:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          children: daysOfWeek.map((day) {
            return FilterChip(
              label: Text(day),
              selected: _selectedDays.contains(day),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(day);
                  } else {
                    _selectedDays.remove(day);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16.0),
        const Text(
          "Selecciona la hora de inicio:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ElevatedButton(
          onPressed: () async {
            final TimeOfDay? pickedTime = await showTimePicker(
              context: context,
              initialTime: _startTime ?? const TimeOfDay(hour: 6, minute: 0),
            );
            if (pickedTime != null) {
              setState(() {
                _startTime = pickedTime;
              });
            }
          },
          child: Text(
            _startTime != null
                ? "Inicio: ${_startTime!.format(context)}"
                : "Seleccionar hora de inicio",
          ),
        ),
        const SizedBox(height: 16.0),
        const Text(
          "Selecciona la hora de finalización:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ElevatedButton(
          onPressed: () async {
            final TimeOfDay? pickedTime = await showTimePicker(
              context: context,
              initialTime: _endTime ?? const TimeOfDay(hour: 19, minute: 0),
            );
            if (pickedTime != null) {
              setState(() {
                _endTime = pickedTime;
              });
            }
          },
          child: Text(
            _endTime != null
                ? "Fin: ${_endTime!.format(context)}"
                : "Seleccionar hora de finalización",
          ),
        ),
      ],
    );
  }

  Future<void> _submitService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        Navigator.pop(context); // Cerrar el diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token no encontrado. Por favor inicie sesión.')),
        );
        return;
      }

      // Obtener los datos del cleaner para conseguir su ID
      final cleanerResponse = await http.get(
        Uri.parse('https://apifixya.onrender.com/cleaners/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': '*/*',
        },
      );
      if (cleanerResponse.statusCode != 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron obtener los datos del cleaner.')),
        );
        return;
      }
      final cleanerData = json.decode(cleanerResponse.body);
      // Se intenta obtener el ID del cleaner: puede venir como "cleaner_id" o "id"
      final cleanerId = cleanerData['cleaner_id'] ?? cleanerData['id'];
      if (cleanerId == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El cleanerId no puede ser nulo.')),
        );
        return;
      }

      final url = Uri.parse('https://apifixya.onrender.com/services');
      final double? price = double.tryParse(_priceController.text.trim());
      if (price == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingrese un precio válido.')),
        );
        return;
      }

      // Subir la imagen si se seleccionó; de lo contrario, usar imagen por defecto.
      String imageUrl;
      if (_selectedImage != null) {
        final uploadedUrl = await _uploadImage(_selectedImage!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al cargar la imagen.')),
          );
          return;
        }
      } else {
        imageUrl = 'https://i.imgur.com/X7YGq1a.jpg';
      }

      // Construir el objeto schedule
      final Map<String, dynamic> scheduleData = {
        'days': _selectedDays,
        'startTime': _startTime != null ? _formatTime(_startTime!) : "",
        'endTime': _endTime != null ? _formatTime(_endTime!) : "",
      };

      // Construir el cuerpo de la petición.
      final Map<String, dynamic> bodyData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'cleanerId': cleanerId,
        'imagebyte': '', // Si no se utiliza, se puede dejar vacío
        'imageUrl': imageUrl,
        'schedule': scheduleData,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bodyData),
      );

      Navigator.pop(context); // Cerrar el diálogo de carga

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servicio creado exitosamente')),
        );
        // Regresa a la pantalla anterior
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode} ${response.body}')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Método para construir un campo de texto. El parámetro [requiredField] indica si es obligatorio.
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) {
          if (requiredField) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingrese $label';
            }
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey.shade200,
        ),
      ),
    );
  }

  /// Widget para mostrar la imagen seleccionada y un botón para elegirla.
  Widget _buildImagePicker() {
    return Column(
      children: [
        _selectedImage != null
            ? Image.file(
                _selectedImage!,
                height: 200,
              )
            : const Text('No se ha seleccionado imagen'),
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image),
          label: const Text('Seleccionar Imagen'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Servicio'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(label: 'Nombre del Servicio', controller: _nameController),
              _buildTextField(
                label: 'Descripción',
                controller: _descriptionController,
                hint: 'Descripción del servicio',
              ),
              _buildTextField(
                label: 'Precio',
                controller: _priceController,
                keyboardType: TextInputType.number,
              ),
              _buildImagePicker(),
              const SizedBox(height: 20),
              // Sección para el schedule
              _buildSchedulePicker(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 148, 214, 255),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Crear Servicio', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
