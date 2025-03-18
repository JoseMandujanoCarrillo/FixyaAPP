import 'dart:convert';
import 'dart:io';
import 'dart:async';
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
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
          elevation: 1,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
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
  Timer? _pollingTimer; // Actualización visible cada 30 segundos
  Timer? _hiddenPollingTimer; // Timer oculto cada 3 segundos

  // Se agregan dos estados: "finalized" se utiliza para propuestas finalizadas y se separa "in_progress"
  final List<String> statuses = [
    "in_progress",
    "pending",
    "accepted",
    "rejected",
    "finalized"
    
  ];
  final Map<String, String> statusLabels = {
    "in_progress": "En proceso",
    "pending": "Pendiente",
    "accepted": "Aceptada",
    "rejected": "Rechazada",
    "finalized": "Finalizada",
    
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: statuses.length, vsync: this);
    // Listener para reconstruir la vista al cambiar de pestaña
    _tabController.addListener(() {
      setState(() {});
    });
    _fetchProposals();
    // Timer visible que refresca las propuestas cada 30 segundos
    _pollingTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _fetchProposals());
    // Timer oculto que consulta cada 3 segundos usando el mismo endpoint
    _hiddenPollingTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _checkProposalsCount());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollingTimer?.cancel();
    _hiddenPollingTimer?.cancel();
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
    final url = Uri.parse('https://apifixya.onrender.com/proposals/for-cleaner');
    try {
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión")),
      );
    }
  }

  // Función que consulta el mismo endpoint para comparar la cantidad de propuestas
  Future<void> _checkProposalsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final url = Uri.parse('https://apifixya.onrender.com/proposals/for-cleaner');
    try {
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        int newCount = (data is List) ? data.length : 0;
        if (newCount != proposals.length) {
          _fetchProposals();
        }
      }
    } catch (e) {
      debugPrint('Error en _checkProposalsCount: $e');
    }
  }

  // Función para filtrar las propuestas según el estado seleccionado.
  List<dynamic> _filterProposalsByStatus(String status) {
    if (status == "finalized") {
      // Propuestas finalizadas: estado in_progress y cleaner_finished true
      return proposals.where((proposal) =>
          proposal['status'] == "in_progress" &&
          (proposal['cleaner_finished'] == true)).toList();
    } else if (status == "in_progress") {
      // En proceso: estado in_progress pero aún no finalizadas
      return proposals.where((proposal) =>
          proposal['status'] == "in_progress" &&
          (proposal['cleaner_finished'] != true)).toList();
    } else {
      return proposals
          .where((proposal) => proposal['status'] == status)
          .toList();
    }
  }

  // Construye las pestañas personalizadas de selección
  List<Widget> _buildCustomTabs() {
    return statuses.asMap().entries.map((entry) {
      int index = entry.key;
      String status = entry.value;
      bool isSelected = _tabController.index == index;
      return Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          border: Border.all(color: isSelected ? Colors.blue : Colors.black),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          statusLabels[status] ?? status,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }).toList();
  }

  // Animación de entrada para cada Card usando AnimatedScale.
  Widget _buildProposalCard(dynamic proposal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 500),
        scale: 1.0,
        child: Card(
          color: const Color(0xFFC5E7F2),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            title: Text("Propuesta #${proposal['id']}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text("Dirección: ${proposal['direccion'] ?? ''}",
                    style: const TextStyle(color: Colors.black)),
                const SizedBox(height: 4),
                Text("Fecha: ${proposal['date'] ?? ''}",
                    style: const TextStyle(color: Colors.black)),
                const SizedBox(height: 4),
                Text(
                    "Estado: ${statusLabels[proposal['status']] ?? proposal['status']}",
                    style: const TextStyle(color: Colors.black)),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.black),
            onTap: () {
              Navigator.of(context).push(_createRoute(ProposalDetailScreen(
                proposal: proposal,
                onStatusChange: _updateProposalStatus,
                onCleanerStart: _markCleanerStarted,
              )));
            },
          ),
        ),
      ),
    );
  }

  // Transición customizada para la navegación.
  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _updateProposalStatus(int proposalId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final url = Uri.parse('https://apifixya.onrender.com/proposals/$proposalId');
    final body = json.encode({"status": newStatus});
    try {
      final response = await http.put(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: body);
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

  Future<void> _markCleanerStarted(int proposalId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final url = Uri.parse('https://apifixya.onrender.com/proposals/$proposalId');
    final body = json.encode({"cleanerStarted": true});
    try {
      final response = await http.put(url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: body);
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: statuses.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Propuestas del Limpiador"),
          bottom: TabBar(
            isScrollable: true, // Permite desplazar horizontalmente las pestañas
            controller: _tabController,
            indicatorColor: Colors.transparent,
            tabs: _buildCustomTabs(),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: statuses.map((status) {
                  final filteredProposals = _filterProposalsByStatus(status);
                  return RefreshIndicator(
                    onRefresh: _fetchProposals,
                    child: filteredProposals.isEmpty
                        ? Center(
                            child: Text(
                              "No hay propuestas",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredProposals.length,
                            itemBuilder: (context, index) {
                              return _buildProposalCard(
                                  filteredProposals[index]);
                            },
                          ),
                  );
                }).toList(),
              ),
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

class _ProposalDetailScreenState extends State<ProposalDetailScreen>
    with SingleTickerProviderStateMixin {
  bool isUploadingImage = false;
  List<String> _uploadedImageUrls = [];
  bool _isFinalized = false;
  final ImagePicker _picker = ImagePicker();
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _isFinalized = widget.proposal['cleaner_finished'] == true;
    if (widget.proposal['imagen_antes'] != null &&
        widget.proposal['imagen_antes'] is List) {
      _uploadedImageUrls = List<String>.from(widget.proposal['imagen_antes']);
    }
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Función corregida: se obtiene el cleanerId desde SharedPreferences en lugar de usar el userId
  Future<void> _sendMessageToUser(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final cleanerId = prefs.getInt('cleanerId');
    if (token == null || cleanerId == null) return;
    final url = Uri.parse(
        'https://apifixya.onrender.com/chats/cleaner/chats/$cleanerId/messages');
    final body = json.encode({"message": message});
    try {
      final response = await http.post(url,
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body);
      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al enviar el mensaje")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error de conexión")));
    }
  }

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
      setState(() {
        isUploadingImage = true;
      });
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
      setState(() {
        isUploadingImage = false;
      });
    }
  }

  Future<void> _updateImagenAntes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final proposalId = widget.proposal['id'];
    final url = Uri.parse(
        'https://apifixya.onrender.com/proposals/$proposalId/upload-imagen-antes');
    final body = json.encode({"imagen_antes": _uploadedImageUrls});
    final response = await http.put(url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Imagen(s) actualizada(s) correctamente")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error al actualizar imagen_antes")));
    }
  }

  Future<void> _finalizeCleaning() async {
    if (_uploadedImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Debe subir al menos una imagen antes de finalizar")),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final proposalId = widget.proposal['id'];
    final url = Uri.parse(
        'https://apifixya.onrender.com/proposals/$proposalId/update-cleaner-finished');
    final body = json.encode({"cleaner_finished": true});
    final response = await http.put(url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body);
    if (response.statusCode == 200) {
      setState(() {
        widget.proposal['cleaner_finished'] = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Solicitud de finalizar hecha correctamente")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al finalizar la limpieza")));
    }
  }

  Widget _buildImagePreview() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _uploadedImageUrls.isEmpty
          ? Container(
              key: const ValueKey("empty"),
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Text("No hay imágenes subidas"),
            )
          : Wrap(
              key: const ValueKey("images"),
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
            ),
    );
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
            onPressed: () async {
              final messageController =
                  TextEditingController(text: "propuesta aceptada");
              final result = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Enviar mensaje al usuario"),
                  content: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(labelText: "Mensaje"),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar"),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, messageController.text),
                      child: const Text("Enviar"),
                    ),
                  ],
                ),
              );
              if (result != null && result.isNotEmpty) {
                await _sendMessageToUser(result);
              }
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
        return const Center(
            child: Text("Esperando confirmación del usuario"));
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
                onPressed:
                    isUploadingImage ? null : _pickAndUploadImageBefore,
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Dirección: ${widget.proposal['direccion'] ?? ''}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text("Fecha: ${widget.proposal['date'] ?? ''}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text("Estado: ${widget.proposal['status'] ?? ''}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500)),
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
      ),
    );
  }
}
