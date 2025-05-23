import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'payment_methods_screen.dart'; // Asegúrate de tener esta pantalla

// ====================== Pantalla de Perfil del Cleaner ======================
class CleanersProfile extends StatefulWidget {
  const CleanersProfile({Key? key}) : super(key: key);

  @override
  _CleanersProfileState createState() => _CleanersProfileState();
}

class _CleanersProfileState extends State<CleanersProfile> {
  int? userId; // Se guarda el id obtenido desde /cleaners/me (aunque ya no se usa para actualizar)
  String userName = "Cargando...";
  String userEmail = "Cargando...";
  String userImageUrl = "";
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker(); // Para seleccionar imagen

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  /// Obtiene los datos actuales del cleaner desde la API y guarda el id.
  Future<void> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Usuario no logueado')));
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('https://apifixya.onrender.com/cleaners/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': '*/*',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userId = data['id'];
          userName = data['name'] ?? 'Usuario';
          userEmail = data['email'] ?? 'Sin correo';
          userImageUrl = data['imageurl'] ?? "";
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al obtener los datos del cleaner')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Envía a la API únicamente el campo que se actualizó.
  Future<void> _updateUserFieldOnApi(String field, String newValue) async {
    // Ya no se requiere userId para la actualización ya que se usa /cleaners/me
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Usuario no logueado')));
      return;
    }
    final payload = { field: newValue };
    try {
      final response = await http.put(
        Uri.parse('https://apifixya.onrender.com/cleaners/me'),
        headers: {
          'Content-Type': 'application/json',
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cleaner actualizado')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  /// Método para editar campos de texto (excepto la imagen)
  Future<void> _editField(String label, String currentValue) async {
    final updatedValue = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFieldScreen(
          label: label,
          initialValue: currentValue,
        ),
      ),
    );
    if (updatedValue != null) {
      String fieldToUpdate = "";
      setState(() {
        if (label == 'Nombre') {
          userName = updatedValue;
          fieldToUpdate = "name";
        } else if (label == 'Correo Electrónico') {
          userEmail = updatedValue;
          fieldToUpdate = "email";
        }
      });
      // Actualiza en la API solo el campo modificado.
      await _updateUserFieldOnApi(fieldToUpdate, updatedValue);
    }
  }

  /// Método para seleccionar y subir la imagen de perfil a Imgur (solo usando la galería).
  Future<void> _pickAndUploadFinalImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return; // Se canceló la selección
    final File imageFile = File(pickedFile.path);
    final String? uploadedUrl = await _uploadImage(imageFile);
    if (uploadedUrl != null) {
      setState(() {
        userImageUrl = uploadedUrl;
      });
      await _updateUserFieldOnApi("imageurl", uploadedUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Imagen actualizada exitosamente")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al subir la imagen")),
      );
    }
  }

  /// Función para subir la imagen a Imgur y obtener la URL resultante.
  Future<String?> _uploadImage(File imageFile) async {
    final uri = Uri.parse('https://api.imgur.com/3/upload');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    // Reemplaza con tu Client-ID real de Imgur
    request.headers['Authorization'] = 'Client-ID 32794ee601322f0';
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);
      if (data['success'] == true) {
        return data['data']['link'];
      }
    }
    return null;
  }

  /// Widget que muestra la información con un botón de edición.
  Widget _buildEditableRow(String label, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit, color: Colors.grey),
        onPressed: () => _editField(label, value),
      ),
    );
  }

  /// Función para cerrar sesión: elimina datos del cleaner y redirige a Login.
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Extendemos el cuerpo detrás del AppBar para resaltar el header
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Perfil del Cleaner', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Header con el color primario
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 148, 214, 255),
                  ),
                ),
                // Contenido principal en un Card central
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 120, left: 16, right: 16, bottom: 16),
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Avatar con botón para editar la imagen
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: userImageUrl.isNotEmpty
                                      ? NetworkImage(userImageUrl)
                                      : const NetworkImage('https://via.placeholder.com/150'),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color.fromARGB(255, 0, 184, 255),
                                    child: IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                                      onPressed: _pickAndUploadFinalImage,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Muestra la URL de la imagen (opcional)
                            Text(
                              'URL de la imagen:',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              userImageUrl,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            // Campos editables: Nombre y Correo Electrónico
                            _buildEditableRow('Nombre', userName),
                            const Divider(),
                            _buildEditableRow('Correo Electrónico', userEmail),
                            const SizedBox(height: 20),
                            // Botón de Cerrar sesión
                            ElevatedButton(
                              onPressed: _logout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 0, 184, 255),
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ====================== Pantalla de Edición ======================
class EditFieldScreen extends StatefulWidget {
  final String label;
  final String initialValue;

  const EditFieldScreen({
    Key? key,
    required this.label,
    required this.initialValue,
  }) : super(key: key);

  @override
  _EditFieldScreenState createState() => _EditFieldScreenState();
}

class _EditFieldScreenState extends State<EditFieldScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Al pulsar "Guardar", se retorna el valor actualizado
  void _save() {
    Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar ${widget.label}'),
        backgroundColor: const Color.fromARGB(255, 0, 184, 255),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: widget.label,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 184, 255),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
