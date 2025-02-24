import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
  ];

  // Etiquetas para mostrar en las pestañas
  final Map<String, String> statusLabels = {
    "pending": "Pendiente",
    "accepted": "Aceptada",
    "in_progress": "En progreso",
    "rejected": "Rechazada",
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
    final Uri url = Uri.parse('https://apifixya.onrender.com/proposals/my?size=999999999');
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
    
    final url = Uri.parse('https://apifixya.onrender.com/proposals/$proposalId/confirm');
    
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
          const SnackBar(content: Text("Servicio confirmado"))
        );
        _fetchProposals();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al confirmar el servicio"))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión"))
      );
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
      default:
        statusColor = Colors.black;
    }

    // Condición para mostrar el botón de confirmar:
    // La propuesta debe estar en estado "accepted" y además debe haberse
    // indicado (por un flag, por ejemplo 'cleanerStarted') que el cleaner presionó "Comenzar"
    bool showConfirm = proposal['status'] == 'accepted' &&
        (proposal['cleanerStarted'] ?? false) == true;

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
            // Si se cumple la condición, se muestra un botón para confirmar
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
          tabs: statuses.map((status) => Tab(text: statusLabels[status])).toList(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: statuses.map((status) => _buildTabView(status)).toList(),
            ),
    );
  }
}
