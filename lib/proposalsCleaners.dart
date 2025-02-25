import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Propuestas del Limpiador',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ProposalsCleaners(),
    );
  }
}

/// Widget principal para listar las propuestas del cleaner con tabs por estado.
class ProposalsCleaners extends StatefulWidget {
  const ProposalsCleaners({Key? key}) : super(key: key);

  @override
  _ProposalsCleanersState createState() => _ProposalsCleanersState();
}

class _ProposalsCleanersState extends State<ProposalsCleaners>
    with SingleTickerProviderStateMixin {
  List<dynamic> proposals = [];
  bool isLoading = true;
  late TabController _tabController;

  final List<String> statuses = [
    "pending",
    "accepted",
    "rejected",
    "in_progress"
  ];
  final Map<String, String> statusLabels = {
    "pending": "Pendiente",
    "accepted": "Aceptada",
    "rejected": "Rechazada",
    "in_progress": "En progreso",
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: statuses.length, vsync: this);
    _fetchProposals();
  }

  Future<void> _fetchProposals() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    final url =
        Uri.parse('https://apifixya.onrender.com/proposals/for-cleaner');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          proposals = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Función para actualizar el estado de la propuesta (ej: "accepted" o "rejected")
  Future<void> _updateProposalStatus(int proposalId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final url =
        Uri.parse('https://apifixya.onrender.com/proposals/$proposalId');
    final body = json.encode({"status": newStatus});

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        _fetchProposals(); // Actualiza la lista tras el cambio de estado
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al actualizar la propuesta")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión")),
      );
    }
  }

  /// Función para marcar que el cleaner ha presionado "Comenzar"
  /// Actualiza la propuesta para guardar "cleanerStarted": true.
  Future<void> _markCleanerStarted(int proposalId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final url =
        Uri.parse('https://apifixya.onrender.com/proposals/$proposalId');
    final body = json.encode({"cleanerStarted": true});

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Limpieza iniciada, esperando confirmación del usuario")),
        );
        _fetchProposals();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al iniciar la limpieza")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión")),
      );
    }
  }

  List<dynamic> _filterProposalsByStatus(String status) {
    return proposals.where((proposal) => proposal['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Propuestas del Limpiador"),
        bottom: TabBar(
          controller: _tabController,
          tabs: statuses
              .map((status) => Tab(text: statusLabels[status]))
              .toList(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: statuses.map((status) {
                List<dynamic> filteredProposals = _filterProposalsByStatus(status);
                if (filteredProposals.isEmpty) {
                  return const Center(child: Text("No hay propuestas"));
                }
                return RefreshIndicator(
                  onRefresh: _fetchProposals,
                  child: ListView.builder(
                    itemCount: filteredProposals.length,
                    itemBuilder: (context, index) {
                      final proposal = filteredProposals[index];
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text("Propuesta #${proposal['id']}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Dirección: ${proposal['direccion'] ?? ''}"),
                              Text("Fecha: ${proposal['date'] ?? ''}"),
                              Text(
                                  "Estado: ${statusLabels[proposal['status']] ?? proposal['status']}"),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProposalDetailScreen(
                                  proposal: proposal,
                                  onStatusChange: _updateProposalStatus,
                                  onCleanerStart: _markCleanerStarted,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
    );
  }
}

/// Pantalla de detalle para la propuesta (versión para cleaners)
/// Se convierte en StatefulWidget para manejar la subida de imagen y finalización.
class ProposalDetailScreen extends StatefulWidget {
  final dynamic proposal;
  final Function(int, String) onStatusChange;
  final Function(int) onCleanerStart;

  const ProposalDetailScreen({
    Key? key,
    required this.proposal,
    required this.onStatusChange,
    required this.onCleanerStart,
  }) : super(key: key);

  @override
  _ProposalDetailScreenState createState() => _ProposalDetailScreenState();
}

class _ProposalDetailScreenState extends State<ProposalDetailScreen> {
  bool isUploadingImage = false;
  String? imageBeforeUrl;
  bool _isFinalized = false; // Variable para controlar si se finalizó la limpieza.
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Inicializamos _isFinalized en función de la propuesta.
    _isFinalized = widget.proposal['cleaner_finished'] == true;
  }

  /// Función para subir imagen a Imgur y obtener la URL resultante.
  Future<String?> _uploadImage(File imageFile) async {
    final uri = Uri.parse('https://api.imgur.com/3/upload');
    final request = http.MultipartRequest('POST', uri);
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));
    // Reemplaza con tu Client-ID real
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

  /// Permite al cleaner seleccionar y subir la imagen "antes".
  Future<void> _pickAndUploadImageBefore() async {
    // Si ya se finalizó, no permitimos subir imagen nuevamente.
    if (_isFinalized) return;

    // Mostrar diálogo para elegir la fuente de la imagen.
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Selecciona origen de la imagen"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, ImageSource.camera);
            },
            child: const Text("Cámara"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, ImageSource.gallery);
            },
            child: const Text("Galería"),
          ),
        ],
      ),
    );

    if (source == null) return; // Se canceló la selección.

    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        isUploadingImage = true;
      });
      File imageFile = File(pickedFile.path);
      String? uploadedUrl = await _uploadImage(imageFile);
      if (uploadedUrl != null) {
        await _updateImagenAntes(uploadedUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al subir la imagen")),
        );
      }
      setState(() {
        isUploadingImage = false;
      });
    }
  }

  /// Llama al endpoint para actualizar "imagen_antes" en la propuesta.
  Future<void> _updateImagenAntes(String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final proposalId = widget.proposal['id'];
    final url = Uri.parse(
        'https://apifixya.onrender.com/proposals/$proposalId/upload-imagen-antes');
    final body = json.encode({"imagen_antes": imageUrl});
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );
    if (response.statusCode == 200) {
      setState(() {
        imageBeforeUrl = imageUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Imagen subida correctamente")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar imagen_antes")),
      );
    }
  }

  /// Llama al endpoint para actualizar "cleaner_finished" a true.
  Future<void> _finalizeCleaning() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final proposalId = widget.proposal['id'];
    final url = Uri.parse(
        'https://apifixya.onrender.com/proposals/$proposalId/update-cleaner-finished');
    final body = json.encode({"cleaner_finished": true});
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );
    if (response.statusCode == 200) {
      setState(() {
        _isFinalized = true; // Marcamos que ya se finalizó.
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Solicitud de finalizar hecha correctamente")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al finalizar la limpieza")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget actionButtons;
    // Acciones según el estado de la propuesta.
    if (widget.proposal['status'] == 'pending') {
      actionButtons = Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 184, 255)),
            onPressed: () {
              widget.onStatusChange(widget.proposal['id'], "accepted");
              Navigator.pop(context);
            },
            child:
                const Text("Aceptar", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              widget.onStatusChange(widget.proposal['id'], "rejected");
              Navigator.pop(context);
            },
            child: const Text("Rechazar", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    } else if (widget.proposal['status'] == 'accepted') {
      bool cleanerStarted = widget.proposal['cleanerStarted'] ?? false;
      if (!cleanerStarted) {
        actionButtons = Center(
          child: ElevatedButton(
            onPressed: () {
              widget.onCleanerStart(widget.proposal['id']);
            },
            child: const Text("Comenzar"),
          ),
        );
      } else {
        actionButtons = const Center(
          child: Text("Esperando confirmación del usuario"),
        );
      }
    } else if (widget.proposal['status'] == 'in_progress') {
      // Si ya se finalizó, no mostramos el menú para subir imagen ni el botón de finalizar.
      if (_isFinalized) {
        actionButtons = const Center(child: Text("Limpieza finalizada"));
      } else {
        // En estado in_progress, mostramos el menú para subir "imagen antes" y finalizar.
        actionButtons = Column(
          children: [
            if ((widget.proposal['imagen_antes'] == null ||
                    widget.proposal['imagen_antes'] == "") &&
                imageBeforeUrl == null)
              ElevatedButton(
                onPressed:
                    isUploadingImage ? null : _pickAndUploadImageBefore,
                child: isUploadingImage
                    ? const CircularProgressIndicator()
                    : const Text("Subir Imagen Antes"),
              )
            else
              Column(
                children: [
                  // En lugar de mostrar la URL, se muestra la imagen.
                  Image.network(
                    imageBeforeUrl ?? widget.proposal['imagen_antes'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _finalizeCleaning,
                    child: const Text("Finalizar"),
                  ),
                ],
              )
          ],
        );
      }
    } else {
      actionButtons = Container();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Propuesta #${widget.proposal['id']}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dirección: ${widget.proposal['direccion'] ?? ''}",
                style: const TextStyle(fontSize: 18)),
            Text("Fecha: ${widget.proposal['date'] ?? ''}",
                style: const TextStyle(fontSize: 18)),
            Text("Estado: ${widget.proposal['status'] ?? ''}",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            actionButtons,
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Regresar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
