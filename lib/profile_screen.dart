import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'payment_methods_screen.dart'; // Asegúrate de tener esta pantalla
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? userId; // Se guardará el id del usuario obtenido desde /users/me
  String userName = "Cargando...";
  String userEmail = "Cargando...";
  String userImageUrl = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  /// Obtiene los datos actuales del usuario desde la API y guarda el id.
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
        Uri.parse('https://apifixya.onrender.com/users/me'),
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
          // En la API se usa "image_url"
          userImageUrl = data['image_url'] ?? "";
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al obtener los datos del usuario')),
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
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener el id del usuario')));
      return;
    }

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
        Uri.parse('https://apifixya.onrender.com/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario actualizado')),
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

  /// Función para seleccionar una imagen de la galería, subirla a Imgur y actualizar la imagen de perfil.
  Future<void> _pickAndUploadProfileImage() async {
    // Se utiliza solo la galería
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return; // Si se cancela, no hacer nada.

    File imageFile = File(pickedFile.path);
    String? uploadedUrl = await _uploadImage(imageFile);
    if (uploadedUrl != null) {
      setState(() {
        userImageUrl = uploadedUrl;
      });
      await _updateUserFieldOnApi('image_url', uploadedUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen actualizada exitosamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al subir la imagen')),
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

  /// Navega a la pantalla de edición para otros campos y actualiza en la API.
  Future<void> _editField(String label, String currentValue) async {
    // Para otros campos, se navega a la pantalla de edición.
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

  /// Función para cerrar sesión: elimina datos del usuario y redirige a Login.
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    // Agrega aquí la eliminación de cualquier otro dato de sesión si es necesario.
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  color: const Color.fromARGB(255, 148, 214, 255),
                  height: 150,
                ),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar con botón para editar la imagen usando Imgur
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: userImageUrl.isNotEmpty
                                      ? NetworkImage(userImageUrl)
                                      : const NetworkImage(
                                          'https://via.placeholder.com/150'),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.white, size: 20),
                                    // Al presionar se selecciona una imagen de la galería y se sube a Imgur.
                                    onPressed: _pickAndUploadProfileImage,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Se muestran los campos editables
                            _buildEditableRow('Nombre', userName),
                            _buildEditableRow('Correo Electrónico', userEmail),
                            const SizedBox(height: 10),
                            // Botón para métodos de pago:
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentMethodsScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 0, 184, 255),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Método de Pago',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(height: 10),
                            // Botón para cerrar sesión:
                            ElevatedButton(
                              onPressed: _logout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 0, 184, 255),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Cerrar sesión',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ],
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
              child: const Text('Guardar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
