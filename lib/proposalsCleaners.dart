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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
        ),
      ),
      home: const ProposalsCleaners(),
    );
  }
}

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
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      setState(() => isLoading = false);
      return;
    }
    final url = Uri.parse('https://apifixya.onrender.com/proposals/for-cleaner');
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          proposals = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  /// Actualiza el estado de la propuesta (ej. "accepted" o "rejected")
  Future<void> _updateProposalStatus(int proposalId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final url = Uri.parse('https://apifixya.onrender.com/proposals/$proposalId');
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
        _fetchProposals();
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

  /// Marca que el cleaner ha iniciado la limpieza
  Future<void> _markCleanerStarted(int proposalId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final url = Uri.parse('https://apifixya.onrender.com/proposals/$proposalId');
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
              content: Text("Limpieza iniciada, esperando confirmación del usuario")),
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

  Widget _buildProposalCard(dynamic proposal) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text("Propuesta #${proposal['id']}",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text("Dirección: ${proposal['direccion'] ?? ''}"),
            const SizedBox(height: 4),
            Text("Fecha: ${proposal['date'] ?? ''}"),
            const SizedBox(height: 4),
            Text("Estado: ${statusLabels[proposal['status']] ?? proposal['status']}"),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Propuestas del Limpiador"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: statuses.map((status) => Tab(text: statusLabels[status])).toList(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: statuses.map((status) {
                final filteredProposals = _filterProposalsByStatus(status);
                if (filteredProposals.isEmpty) {
                  return const Center(child: Text("No hay propuestas"));
                }
                return RefreshIndicator(
                  onRefresh: _fetchProposals,
                  child: ListView.builder(
                    itemCount: filteredProposals.length,
                    itemBuilder: (context, index) {
                      return _buildProposalCard(filteredProposals[index]);
                    },
                  ),
                );
              }).toList(),
            ),
    );
  }
}

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
  List<String> _uploadedImageUrls = [];
  bool _isFinalized = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isFinalized = widget.proposal['cleaner_finished'] == true;
    if (widget.proposal['imagen_antes'] != null &&
        widget.proposal['imagen_antes'] is List) {
      _uploadedImageUrls = List<String>.from(widget.proposal['imagen_antes']);
    }
  }

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
        return data['data']['link'];
      }
    }
    return null;
  }

  Future<void> _pickAndUploadImageBefore() async {
    if (_isFinalized) return;
    if (_uploadedImageUrls.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solo puedes seleccionar hasta 3 imágenes")),
      );
      return;
    }
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Selecciona origen de la imagen"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text("Cámara"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text("Galería"),
          ),
        ],
      ),
    );
    if (source == null) return;
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => isUploadingImage = true);
      final File imageFile = File(pickedFile.path);
      String? uploadedUrl = await _uploadImage(imageFile);
      if (uploadedUrl != null) {
        setState(() {
          _uploadedImageUrls.add(uploadedUrl);
        });
        await _updateImagenAntes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al subir la imagen")),
        );
      }
      setState(() => isUploadingImage = false);
    }
  }

  Future<void> _updateImagenAntes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final proposalId = widget.proposal['id'];
    final url = Uri.parse('https://apifixya.onrender.com/proposals/$proposalId/upload-imagen-antes');
    final body = json.encode({"imagen_antes": _uploadedImageUrls});
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
        const SnackBar(content: Text("Imagen(s) actualizada(s) correctamente")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar imagen_antes")),
      );
    }
  }

  Future<void> _finalizeCleaning() async {
    if (_uploadedImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debe subir al menos una imagen antes de finalizar")),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final proposalId = widget.proposal['id'];
    final url = Uri.parse('https://apifixya.onrender.com/proposals/$proposalId/update-cleaner-finished');
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
        widget.proposal['cleaner_finished'] = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solicitud de finalizar hecha correctamente")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al finalizar la limpieza")),
      );
    }
  }

  Widget _buildImagePreview() {
    if (_uploadedImageUrls.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Text("No hay imágenes subidas"),
      );
    } else {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _uploadedImageUrls.map((url) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              url,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildActionButtons() {
    if (widget.proposal['status'] == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text("Aceptar"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              widget.onStatusChange(widget.proposal['id'], "accepted");
              Navigator.pop(context);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.close),
            label: const Text("Rechazar"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              widget.onStatusChange(widget.proposal['id'], "rejected");
              Navigator.pop(context);
            },
          ),
        ],
      );
    } else if (widget.proposal['status'] == 'accepted') {
      bool cleanerStarted = widget.proposal['cleanerStarted'] ?? false;
      if (!cleanerStarted) {
        return Center(
          child: ElevatedButton(
            onPressed: () {
              widget.onCleanerStart(widget.proposal['id']);
            },
            child: const Text("Comenzar"),
          ),
        );
      } else {
        return const Center(child: Text("Esperando confirmación del usuario"));
      }
    } else if (widget.proposal['status'] == 'in_progress') {
      if (widget.proposal['cleaner_finished'] == true) {
        return const Center(child: Text("Limpieza finalizada"));
      } else {
        return Column(
          children: [
            _buildImagePreview(),
            const SizedBox(height: 16),
            if (_uploadedImageUrls.length < 3)
              ElevatedButton(
                onPressed: isUploadingImage ? null : _pickAndUploadImageBefore,
                child: isUploadingImage
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Agregar imagen"),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _finalizeCleaning,
              child: const Text("Finalizar"),
            ),
          ],
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Propuesta #${widget.proposal['id']}"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dirección: ${widget.proposal['direccion'] ?? ''}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text("Fecha: ${widget.proposal['date'] ?? ''}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text("Estado: ${widget.proposal['status'] ?? ''}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Regresar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
