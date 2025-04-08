import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

/// Página principal que muestra las propuestas con barra de selección tipo filtro
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
  Timer? _pollingTimer; // Actualización visible cada 30 segundos
  Timer? _hiddenPollingTimer; // Temporizador oculto cada 3 segundos

  // Estados y sus etiquetas
  final List<String> statuses = [
    "in_progress",
    "pending",
    "accepted",
    "rejected",
    "finished",
  ];
  final Map<String, String> statusLabels = {
    "in_progress": "En proceso",
    "pending": "Pendiente",
    "accepted": "Aceptada",
    "rejected": "Rechazada",
    "finished": "Finalizada",
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: statuses.length, vsync: this);
    // Listener para reconstruir la vista cuando se cambia de pestaña
    _tabController.addListener(() {
      setState(() {});
    });
    _fetchProposals();

    // Inicia el polling cada 30 segundos para refrescar las propuestas automáticamente
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchProposals();
    });
    // Temporizador oculto que consulta cada 3 segundos usando el mismo endpoint
    _hiddenPollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkProposalsCount();
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _pollingTimer?.cancel(); // Cancelar el timer para evitar fugas de memoria
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

  // Función que consulta el mismo endpoint para comparar la cantidad de propuestas
  Future<void> _checkProposalsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
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
        // Si el número de propuestas es diferente, se actualiza el listado visible
        if (fetchedProposals.length != proposals.length) {
          _fetchProposals();
        }
      }
    } catch (e) {
      debugPrint('Error en _checkProposalsCount: $e');
    }
  }

  // Filtra las propuestas según el estado exacto
  List<dynamic> _filterProposalsByStatus(String status) {
    return proposals.where((proposal) {
      final String proposalStatus =
          (proposal['status'] ?? '').toString().trim();
      return proposalStatus == status;
    }).toList();
  }

  Widget _buildTabViewForStatus(String status) {
    final filteredProposals = _filterProposalsByStatus(status);
    if (filteredProposals.isEmpty) {
      return Center(
        child: Text(
          "No hay propuestas ${statusLabels[status]?.toLowerCase()}",
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchProposals,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: ListView.builder(
          key: ValueKey(filteredProposals.length),
          itemCount: filteredProposals.length,
          itemBuilder: (context, index) => ProposalCard(
            proposal: filteredProposals[index],
            onConfirm: _confirmProposal,
            onRefresh: _fetchProposals,
          ),
        ),
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
          controller: _tabController,
          isScrollable: true,
          // Deshabilitamos el indicador por defecto
          indicator: const BoxDecoration(),
          tabs: List.generate(statuses.length, (index) {
            final bool isSelected = _tabController.index == index;
            return Tab(
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.white,
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  statusLabels[statuses[index]]!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: statuses
                  .map((status) => _buildTabViewForStatus(status))
                  .toList(),
            ),
    );
  }
}

/// Tarjeta animada para cada propuesta
class ProposalCard extends StatefulWidget {
  final dynamic proposal;
  final Future<void> Function(int) onConfirm;
  final Future<void> Function() onRefresh;

  const ProposalCard({
    Key? key,
    required this.proposal,
    required this.onConfirm,
    required this.onRefresh,
  }) : super(key: key);

  @override
  _ProposalCardState createState() => _ProposalCardState();
}

class _ProposalCardState extends State<ProposalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    final String status =
        (widget.proposal['status'] ?? '').toString().trim();
    final Color statusColor = _getStatusColor(status);
    // Mostrar botón de confirmación solo si el estado es "accepted" y se inició el servicio
    final bool showConfirm = status == 'accepted' &&
        (widget.proposal['cleanerStarted'] ?? false) == true;
    // Mostrar botón para finalizar solo si se terminó de limpiar y el estado no es "finished"
    final bool showFinish = (widget.proposal['cleaner_finished'] ?? false) ==
            true &&
        status != 'finished';

    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            color: const Color(0xFFC5E7F2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.proposal['tipodeservicio'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Estado: ',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 14,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Creado: ${_formatDateTime(widget.proposal['createdAt'])}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  if (showConfirm)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          await widget.onConfirm(widget.proposal['id']);
                        },
                        child: const Text("Confirmar"),
                      ),
                    ),
                  if (showFinish)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Hero(
                        tag: "finish_${widget.proposal['id']}",
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FinishProposalPage(proposal: widget.proposal),
                              ),
                            );
                            if (result == true) {
                              widget.onRefresh();
                            }
                          },
                          child: const Text("Subir y finalizar"),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pantalla para finalizar el servicio con subida de imágenes y calificación
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

  // Variables para la calificación
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();

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

  // Función para enviar la calificación al endpoint
  Future<void> _submitRating() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final ratingUrl = Uri.parse('https://apifixya.onrender.com/ratings/create');
    final ratingBody = jsonEncode({
      'serviceId': widget.proposal['serviceId'],
      'rating': _rating.toInt(), // valor de 1 a 5
      'comment': _commentController.text,
    });

    try {
      final ratingResponse = await http.post(
        ratingUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: ratingBody,
      );
      if (ratingResponse.statusCode == 200 || ratingResponse.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Calificación enviada exitosamente")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al enviar la calificación")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión al enviar la calificación")),
      );
    }
  }

  Future<void> _uploadAndFinishProposal() async {
    if (_uploadedImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, selecciona y sube al menos una imagen")),
      );
      return;
    }
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, selecciona una calificación")),
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
    // Subir imágenes al endpoint
    final uploadUrl = Uri.parse(
        'https://apifixya.onrender.com/proposals/${widget.proposal['id']}/upload-imagen-despues');
    final uploadBody = jsonEncode({'imagen_despues': _uploadedImageUrls});
    try {
      final uploadResponse = await http.put(
        uploadUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
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
        const SnackBar(content: Text("Error de conexión al subir imágenes")),
      );
      setState(() => isSubmitting = false);
      return;
    }
    // Actualizar el estado a "finished"
    final finishUrl = Uri.parse(
        'https://apifixya.onrender.com/proposals/${widget.proposal['id']}');
    final finishBody = jsonEncode({'status': 'finished'});
    try {
      final finishResponse = await http.put(
        finishUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: finishBody,
      );
      if (finishResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Servicio finalizado")),
        );
        // Enviar la calificación una vez finalizado el servicio
        await _submitRating();
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
      setState(() => isSubmitting = false);
    }
  }

  // Widget para mostrar las estrellas de calificación
  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: () {
            setState(() {
              _rating = index + 1.0;
            });
          },
        );
      }),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Finalizar y Calificar Servicio"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título con animación Hero para transición fluida
              Hero(
                tag: "finish_${widget.proposal['id']}",
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    widget.proposal['tipodeservicio'] ?? '',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sección de imágenes subidas
              _uploadedImageUrls.isNotEmpty
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _uploadedImageUrls
                          .map((url) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blueAccent),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    url,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
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
                ElevatedButton.icon(
                  icon: isUploadingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_a_photo),
                  label: const Text("Agregar imagen"),
                  onPressed: isUploadingImage ? null : _pickAndUploadImage,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Sección para calificar el servicio
              const Text(
                "Califica el servicio",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              _buildRatingStars(),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: "Comentario",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload),
                label: const Text("Subir y finalizar"),
                onPressed: isSubmitting ? null : _uploadAndFinishProposal,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
