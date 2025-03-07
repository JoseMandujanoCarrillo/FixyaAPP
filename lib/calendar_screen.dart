import 'dart:async';
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
  Timer? _pollingTimer;

  // Pestañas principales
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

  // Subpestañas para "Aceptado"
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
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchProposals();
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchProposals() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      setState(() => isLoading = false);
      return;
    }
    final Uri url = Uri.parse(
        'https://apifixya.onrender.com/proposals/my?size=40000000000');
    try {
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> fetchedProposals =
            data is List ? data : (data['proposals'] ?? []);
        // Ordenar por fecha descendente
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
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => isLoading = false);
    }
  }

  List<dynamic> _filterProposalsByMainStatus(String status) {
    return proposals.where((proposal) {
      final String proposalStatus =
          (proposal['status'] ?? '').toString().trim();
      if (status == "pending") {
        return proposalStatus == "pending";
      } else if (status == "rejected") {
        return proposalStatus == "rejected";
      } else if (status == "accepted") {
        return ["accepted", "in_progress", "finished"].contains(proposalStatus);
      }
      return false;
    }).toList();
  }

  Widget _buildTabView(String status) {
    final filteredProposals = _filterProposalsByMainStatus(status);
    if (filteredProposals.isEmpty) {
      return Center(
        child: Text(
          "No hay propuestas ${mainStatusLabels[status]?.toLowerCase()}",
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchProposals,
      child: ListView.builder(
        itemCount: filteredProposals.length,
        itemBuilder: (context, index) => ProposalCard(
          proposal: filteredProposals[index],
          onConfirm: _confirmProposal,
          onRefresh: _fetchProposals,
        ),
      ),
    );
  }

  Widget _buildAcceptedTabView() {
    final acceptedProposals = _filterProposalsByMainStatus("accepted");
    return DefaultTabController(
      length: acceptedSubStatuses.length,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black,
              indicatorColor: Colors.blue,
              tabs: acceptedSubStatuses
                  .map((s) => Tab(text: acceptedSubStatusLabels[s]))
                  .toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: acceptedSubStatuses.map((subStatus) {
                final filtered = acceptedProposals.where((proposal) {
                  final String proposalStatus =
                      (proposal['status'] ?? '').toString().trim();
                  return proposalStatus == subStatus;
                }).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      "No hay propuestas ${acceptedSubStatusLabels[subStatus]?.toLowerCase()}",
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _fetchProposals,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => ProposalCard(
                      proposal: filtered[index],
                      onConfirm: _confirmProposal,
                      onRefresh: _fetchProposals,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Servicio confirmado")));
        _fetchProposals();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al confirmar el servicio")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error de conexión")));
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

class ProposalCard extends StatelessWidget {
  final dynamic proposal;
  final Future<void> Function(int) onConfirm;
  final Future<void> Function() onRefresh;

  const ProposalCard({
    Key? key,
    required this.proposal,
    required this.onConfirm,
    required this.onRefresh,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'finished':
        return Colors.purple;
      default:
        return Colors.black;
    }
  }

  String _formatDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFFC5E7F2);
    final String status = (proposal['status'] ?? '').toString().trim();
    final Color statusColor = _getStatusColor(status);
    final bool showConfirm =
        status == 'accepted' && (proposal['cleanerStarted'] ?? false) == true;
    final bool showFinish = (proposal['cleaner_finished'] ?? false) == true &&
        status != 'finished';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                proposal['tipodeservicio'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Estado: $status',
                style: TextStyle(fontSize: 14, color: statusColor),
              ),
              const SizedBox(height: 4),
              Text(
                'Creado: ${_formatDateTime(proposal['createdAt'])}',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              if (showConfirm)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () async {
                      await onConfirm(proposal['id']);
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
                        onRefresh();
                      }
                    },
                    child: const Text("Subir y finalizar"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FinishProposalPage extends StatefulWidget {
  final dynamic proposal;
  const FinishProposalPage({Key? key, required this.proposal}) : super(key: key);

  @override
  _FinishProposalPageState createState() => _FinishProposalPageState();
}

class _FinishProposalPageState extends State<FinishProposalPage> {
  bool isSubmitting = false;
  bool isUploadingImage = false;
  final List<String> _uploadedImageUrls = [];
  final ImagePicker _picker = ImagePicker();

  Future<String?> _uploadImage(File imageFile) async {
    final uri = Uri.parse('https://api.imgur.com/3/upload');
    final request = http.MultipartRequest('POST', uri);
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));
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
        const SnackBar(
            content: Text("Solo puedes seleccionar hasta 3 imágenes")),
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
      final uploadedUrl = await _uploadImage(imageFile);
      if (uploadedUrl != null) {
        setState(() => _uploadedImageUrls.add(uploadedUrl));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al subir la imagen")),
        );
      }
      setState(() => isUploadingImage = false);
    }
  }

  Future<void> _uploadAndFinishProposal() async {
    if (_uploadedImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Por favor, selecciona y sube al menos una imagen")),
      );
      return;
    }
    setState(() => isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      setState(() => isSubmitting = false);
      return;
    }
    // Primer endpoint: subir imágenes
    final uploadUrl = Uri.parse(
        'https://apifixya.onrender.com/proposals/${widget.proposal['id']}/upload-imagen-despues');
    final uploadBody =
        jsonEncode({'imagen_despues': _uploadedImageUrls});
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
        setState(() => isSubmitting = false);
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Error de conexión al subir imágenes")),
      );
      setState(() => isSubmitting = false);
      return;
    }
    // Segundo endpoint: actualizar el estado a "finished"
    final finishUrl = Uri.parse(
        'https://apifixya.onrender.com/proposals/${widget.proposal['id']}');
    final finishBody = jsonEncode({'status': 'finished'});
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
          const SnackBar(
              content: Text("Error al finalizar el servicio")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Error de conexión al finalizar")),
      );
    } finally {
      setState(() => isSubmitting = false);
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
              _uploadedImageUrls.isNotEmpty
                  ? Wrap(
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
                  : Container(
                      height: 120,
                      alignment: Alignment.center,
                      child: const Text("No hay imágenes seleccionadas"),
                    ),
              const SizedBox(height: 16),
              if (_uploadedImageUrls.length < 3)
                ElevatedButton(
                  onPressed:
                      isUploadingImage ? null : _pickAndUploadImage,
                  child: isUploadingImage
                      ? const CircularProgressIndicator()
                      : const Text("Agregar imagen"),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    isSubmitting ? null : _uploadAndFinishProposal,
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
