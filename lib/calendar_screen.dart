import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class ProposalsPage extends StatefulWidget {
  const ProposalsPage({Key? key}) : super(key: key);

  @override
  _ProposalsPageState createState() => _ProposalsPageState();
}

class _ProposalsPageState extends State<ProposalsPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> proposals = [];
  bool isLoading = true;
  late TabController _tabController;

  // Lista de estados en el orden deseado: pendiente, aceptada, en progreso, rechazada.
  final List<String> statuses = [
    "pending",
    "accepted",
    "in_progress",
    "rejected",
    "finished",
  ];

  // Etiquetas para mostrar en las pestañas
  final Map<String, String> statusLabels = {
    "pending": "Pendiente",
    "accepted": "Aceptada",
    "in_progress": "En progreso",
    "rejected": "Rechazada",
    "finished" : "Finalizada"
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
    // Se usa el endpoint con size muy grande para obtener todas las propuestas
    final Uri url = Uri.parse('https://apifixya.onrender.com/proposals/my?size=40000000000');
    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Si la API devuelve directamente una lista, se usa esa lista;
        // de lo contrario, se busca en data['proposals'].
        List<dynamic> fetchedProposals =
            data is List ? data : (data['proposals'] ?? []);
        // Ordena las propuestas por fecha (descendente)
        fetchedProposals.sort((a, b) {
          final DateTime dateA = DateTime.parse(a['createdAt']);
          final DateTime dateB = DateTime.parse(b['createdAt']);
          return dateB.compareTo(dateA);
        });
        setState(() {
          proposals = fetchedProposals;
          isLoading = false;
        });
      } else {
        debugPrint('Error al cargar propuestas: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Función para confirmar la propuesta (llama al endpoint /confirm)
  Future<void> _confirmProposal(int proposalId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final url =
        Uri.parse('https://apifixya.onrender.com/proposals/$proposalId/confirm');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Servicio confirmado")));
        _fetchProposals();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al confirmar el servicio")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error de conexión")));
    }
  }

  // Función para formatear la fecha
  String formatDateTime(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  // Filtra las propuestas según el estado recibido, eliminando espacios y forzando String.
  List<dynamic> _filterProposalsByStatus(String status) {
    return proposals.where((proposal) {
      final currentStatus = (proposal['status'] ?? '').toString().trim();
      return currentStatus == status;
    }).toList();
  }

  // Construye el widget para cada propuesta
  Widget _buildProposalItem(dynamic proposal) {
    // Se asigna un color según el estado
    Color statusColor;
    switch (proposal['status']) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'accepted':
        statusColor = Colors.green;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'finished':
        statusColor = Colors.purple;
        break
      default:
        statusColor = Colors.black;
    }

    // Condición para mostrar el botón de confirmar:
    // La propuesta debe estar en estado "accepted" y además debe haberse
    // indicado que el cleaner presionó "Comenzar"
    bool showConfirm = proposal['status'] == 'accepted' &&
        (proposal['cleanerStarted'] ?? false) == true;

    // Si "cleaner_finished" es true y el estado aún no es "finished", se muestra el botón para finalizar
    bool showFinish = (proposal['cleaner_finished'] ?? false) == true &&
        proposal['status'] != 'finished';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${proposal['tipodeservicio']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Estado: ${statusLabels[proposal['status']] ?? proposal['status']}',
              style: TextStyle(
                fontSize: 14,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Creado: ${formatDateTime(proposal['createdAt'])}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            if (showConfirm)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () async {
                    await _confirmProposal(proposal['id']);
                  },
                  child: const Text("Confirmar"),
                ),
              ),
            if (showFinish)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () async {
                    // Navega a la pantalla para subir imagen y finalizar
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FinishProposalPage(proposal: proposal),
                      ),
                    );
                    // Si se finalizó correctamente, se refrescan las propuestas
                    if (result == true) {
                      _fetchProposals();
                    }
                  },
                  child: const Text("Subir y finalizar"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Construye la vista para cada pestaña según el estado
  Widget _buildTabView(String status) {
    List<dynamic> filteredProposals = _filterProposalsByStatus(status);
    if (filteredProposals.isEmpty) {
      return Center(
        child: Text("No hay propuestas ${statusLabels[status]?.toLowerCase()}"),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchProposals,
      child: ListView.builder(
        itemCount: filteredProposals.length,
        itemBuilder: (context, index) {
          return _buildProposalItem(filteredProposals[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de servicio"),
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
              children:
                  statuses.map((status) => _buildTabView(status)).toList(),
            ),
    );
  }
}

// Nueva pantalla para subir la imagen 'después' y finalizar la propuesta
class FinishProposalPage extends StatefulWidget {
  final dynamic proposal;
  const FinishProposalPage({Key? key, required this.proposal})
      : super(key: key);

  @override
  _FinishProposalPageState createState() => _FinishProposalPageState();
}

class _FinishProposalPageState extends State<FinishProposalPage> {
  bool isSubmitting = false;
  bool isUploadingImage = false;
  String? _uploadedImageUrl;

  final ImagePicker _picker = ImagePicker();

  /// Función para subir la imagen a Imgur y obtener la URL resultante.
  Future<String?> _uploadImage(File imageFile) async {
    final uri = Uri.parse('https://api.imgur.com/3/upload');
    final request = http.MultipartRequest('POST', uri);
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));
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

  /// Permite al usuario seleccionar una imagen (de cámara o galería) y la sube a Imgur.
  Future<void> _pickAndUploadImage() async {
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

    if (source == null) return; // Se canceló la selección.

    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        isUploadingImage = true;
      });
      final File imageFile = File(pickedFile.path);
      String? uploadedUrl = await _uploadImage(imageFile);
      if (uploadedUrl != null) {
        setState(() {
          _uploadedImageUrl = uploadedUrl;
        });
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

  /// Envía la propuesta finalizada usando la URL de la imagen subida.
  /// Primero se actualiza la imagen (endpoint: upload-imagen-despues)
  /// y luego se finaliza la propuesta actualizando solo "status" a "finished".
  Future<void> _uploadAndFinishProposal() async {
    if (_uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Por favor, selecciona y sube una imagen primero")));
      return;
    }
    setState(() {
      isSubmitting = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      setState(() {
        isSubmitting = false;
      });
      return;
    }

    // Primer endpoint: subir la imagen "después"
    final uploadUrl = Uri.parse(
        'https://apifixya.onrender.com/proposals/${widget.proposal['id']}/upload-imagen-despues');
    final uploadBody = jsonEncode({
      'imagen_despues': _uploadedImageUrl,
    });
    try {
      final uploadResponse = await http.put(
        uploadUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: uploadBody,
      );
      if (uploadResponse.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al subir la imagen")),
        );
        setState(() {
          isSubmitting = false;
        });
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión al subir imagen")),
      );
      setState(() {
        isSubmitting = false;
      });
      return;
    }

    // Segundo endpoint: actualizar la propuesta para finalizar (solo actualizando "status")
    final finishUrl = Uri.parse(
        'https://apifixya.onrender.com/proposals/${widget.proposal['id']}');
    final finishBody = jsonEncode({
      'status': 'finished',
    });
    try {
      final finishResponse = await http.put(
        finishUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: finishBody,
      );
      if (finishResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Servicio finalizado")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al finalizar el servicio")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión al finalizar")),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Finalizar Servicio")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mostrar imagen seleccionada o botón para elegir imagen
            if (_uploadedImageUrl != null)
              Image.network(
                _uploadedImageUrl!,
                height: 200,
                fit: BoxFit.cover,
              )
            else
              ElevatedButton(
                onPressed: isUploadingImage ? null : _pickAndUploadImage,
                child: isUploadingImage
                    ? const CircularProgressIndicator()
                    : const Text("Seleccionar imagen"),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isSubmitting ? null : _uploadAndFinishProposal,
              child: isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text("Subir y finalizar"),
            )
          ],
        ),
      ),
    );
  }
}
