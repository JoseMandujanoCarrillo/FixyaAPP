import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'payment_methods_screen.dart'; // Asegúrate de tener esta pantalla

// ====================== Pantalla de Perfil del Cleaner ======================
class CleanersProfile extends StatefulWidget {
  const CleanersProfile({Key? key}) : super(key: key);

  @override
  _CleanersProfileState createState() => _CleanersProfileState();
}

class _CleanersProfileState extends State<CleanersProfile> {
  int? userId; // Se guardará el id del cleaner obtenido desde /cleaners/me
  String userName = "Cargando...";
  String userEmail = "Cargando...";
  String userImageUrl = "";
  String latitude = "";
  String longitude = "";
  bool isLoading = true;

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
          // Si la API no retorna imagen, se usará una cadena vacía
          userImageUrl = data['image_url'] ?? "";
          // Extraemos la latitud y longitud, en caso de que existan
          latitude = data['latitude'] != null ? data['latitude'].toString() : '';
          longitude = data['longitude'] != null ? data['longitude'].toString() : '';
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
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener el id del cleaner')));
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
        Uri.parse('https://apifixya.onrender.com/cleaners/$userId'),
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

  /// Navega a la pantalla de edición, actualiza el dato local y llama a la función
  /// para actualizar en la API.
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
        } else if (label == 'Imagen') {
          userImageUrl = updatedValue;
          fieldToUpdate = "image_url";
        } else if (label == 'Latitud') {
          latitude = updatedValue;
          fieldToUpdate = "latitude";
        } else if (label == 'Longitud') {
          longitude = updatedValue;
          fieldToUpdate = "longitude";
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

  /// Función para cerrar sesión: elimina datos del cleaner y redirige a Login.
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    // Redirige a la pantalla de login. Asegúrate de tener definida la ruta '/login'
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
                            // Avatar con botón para editar la imagen (usa placeholder si no hay imagen)
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
                                    onPressed: () =>
                                        _editField('Imagen', userImageUrl),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Se muestran los campos editables
                            _buildEditableRow('Nombre', userName),
                            _buildEditableRow('Correo Electrónico', userEmail),
                            _buildEditableRow('Latitud', latitude),
                            _buildEditableRow('Longitud', longitude),
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
