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
  late TabController _mainTabController;

  // Pestañas principales: Pendiente, Aceptado y Rechazado.
  final List<String> mainStatuses = [
    "pending",
    "accepted",
    "rejected",
  ];

  final Map<String, String> mainStatusLabels = {
    "pending": "Pendiente",
    "accepted": "Aceptado",
    "rejected": "Rechazado",
  };

  // Dentro de "Aceptado", tres subpestañas: Pendiente (in_progress), Aceptado (accepted) y Finalizado (finished).
  final List<String> acceptedSubStatuses = [
    "in_progress",
    "accepted",
    "finished",
  ];

  final Map<String, String> acceptedSubStatusLabels = {
    "in_progress": "en progreso",
    "accepted": "Aceptado",
    "finished": "Finalizado",
  };

  @override
  void initState() {
    super.initState();
    _mainTabController =
        TabController(length: mainStatuses.length, vsync: this);
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
    // Se usa un size muy grande para obtener todas las propuestas
    final Uri url =
        Uri.parse('https://apifixya.onrender.com/proposals/my?size=40000000000');
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

  // Filtra según pestaña principal:
  // - "pending": propuestas con status "pending"
  // - "rejected": propuestas con status "rejected"
  // - "accepted": aquellas con status "accepted", "in_progress" o "finished"
  List<dynamic> _filterProposalsByMainStatus(String status) {
    return proposals.where((proposal) {
      String proposalStatus = (proposal['status'] ?? '').toString().trim();
      if (status == "pending") {
        return proposalStatus == "pending";
      } else if (status == "rejected") {
        return proposalStatus == "rejected";
      } else if (status == "accepted") {
        return proposalStatus == "accepted" ||
            proposalStatus == "in_progress" ||
            proposalStatus == "finished";
      }
      return false;
    }).toList();
  }

  // Vista para pestañas "Pendiente" y "Rechazado"
  Widget _buildTabView(String status) {
    List<dynamic> filteredProposals = _filterProposalsByMainStatus(status);
    if (filteredProposals.isEmpty) {
      return Center(
        child: Text(
            "No hay propuestas ${mainStatusLabels[status]?.toLowerCase()}"),
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

  // Vista para la pestaña "Aceptado", con subpestañas: Pendiente (in_progress), Aceptado y Finalizado.
  Widget _buildAcceptedTabView() {
    // Filtra todas las propuestas pertenecientes a "accepted"
    List<dynamic> acceptedProposals = _filterProposalsByMainStatus("accepted");
    return DefaultTabController(
      length: acceptedSubStatuses.length,
      child: Column(
        children: [
          Container(
            color: Colors.white, // fondo blanco
            child: TabBar(
              labelColor: Colors.blue, // texto azul cuando está seleccionado
              unselectedLabelColor: Colors.black, // texto negro cuando no está seleccionado
              indicatorColor: Colors.blue, // indicador en azul
              tabs: acceptedSubStatuses
                  .map((s) => Tab(text: acceptedSubStatusLabels[s]))
                  .toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: acceptedSubStatuses.map((subStatus) {
                // Para subpestaña "pending": mostrar solo propuestas con estado "in_progress"
                // Para subpestaña "accepted": mostrar solo propuestas con estado "accepted"
                // Para subpestaña "finished": mostrar solo propuestas con estado "finished"
                List<dynamic> filtered = acceptedProposals.where((proposal) {
                  String proposalStatus =
                      (proposal['status'] ?? '').toString().trim();
                  if (subStatus == "pending") {
                    return proposalStatus == "in_progress";
                  } else if (subStatus == "accepted") {
                    return proposalStatus == "accepted";
                  } else if (subStatus == "finished") {
                    return proposalStatus == "finished";
                  }
                  return false;
                }).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text("No hay propuestas ${acceptedSubStatusLabels[subStatus]?.toLowerCase()}"),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _fetchProposals,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildProposalItem(filtered[index]);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Construye cada card de propuesta con el color de fondo solicitado.
  Widget _buildProposalItem(dynamic proposal) {
    Color cardColor = const Color(0xFFC5E7F2);
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
        break;
      default:
        statusColor = Colors.black;
    }
    // Mostrar botón "Confirmar" si es "accepted" y el cleaner ya inició.
    bool showConfirm = proposal['status'] == 'accepted' &&
        (proposal['cleaner_started'] ?? false) == true;
    // Mostrar botón "Subir y finalizar" si el cleaner terminó y aún no se ha finalizado.
    bool showFinish = (proposal['cleaner_finished'] ?? false) == true &&
        proposal['status'] != 'finished';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
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
              'Estado: ${proposal['status']}',
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
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FinishProposalPage(proposal: proposal),
                      ),
                    );
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

  String formatDateTime(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  Future<void> _confirmProposal(int proposalId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final url = Uri.parse(
        'https://apifixya.onrender.com/proposals/$proposalId/confirm');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de servicio"),
        bottom: TabBar(
          controller: _mainTabController,
          tabs: mainStatuses
              .map((status) => Tab(text: mainStatusLabels[status]))
              .toList(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _mainTabController,
              children: [
                _buildTabView("pending"),
                _buildAcceptedTabView(),
                _buildTabView("rejected"),
              ],
            ),
    );
  }
}

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
  List<String> _uploadedImageUrls = [];
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickAndUploadImage() async {
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
      setState(() {
        isUploadingImage = true;
      });
      final File imageFile = File(pickedFile.path);
      String? uploadedUrl = await _uploadImage(imageFile);
      if (uploadedUrl != null) {
        setState(() {
          _uploadedImageUrls.add(uploadedUrl);
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

  Future<void> _uploadAndFinishProposal() async {
    if (_uploadedImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text("Por favor, selecciona y sube al menos una imagen")));
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
    // Primer endpoint: subir las imágenes "después"
    final uploadUrl = Uri.parse(
        'https://apifixya.onrender.com/proposals/${widget.proposal['id']}/upload-imagen-despues');
    final uploadBody = jsonEncode({
      'imagen_despues': _uploadedImageUrls,
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
          const SnackBar(content: Text("Error al subir las imágenes")),
        );
        setState(() {
          isSubmitting = false;
        });
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión al subir imágenes")),
      );
      setState(() {
        isSubmitting = false;
      });
      return;
    }
    // Segundo endpoint: actualizar la propuesta a "finished"
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mostrar miniaturas de las imágenes subidas
              if (_uploadedImageUrls.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _uploadedImageUrls
                      .map((url) => Image.network(
                            url,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ))
                      .toList(),
                )
              else
                Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: const Text("No hay imágenes seleccionadas"),
                ),
              const SizedBox(height: 16),
              if (_uploadedImageUrls.length < 3)
                ElevatedButton(
                  onPressed: isUploadingImage ? null : _pickAndUploadImage,
                  child: isUploadingImage
                      ? const CircularProgressIndicator()
                      : const Text("Agregar imagen"),
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
      ),
    );
  }
}
