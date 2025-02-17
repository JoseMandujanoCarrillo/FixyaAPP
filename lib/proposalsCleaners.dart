import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  final List<String> statuses = ["pending", "accepted", "rejected"];
  final Map<String, String> statusLabels = {
    "pending": "Pendiente",
    "accepted": "Aceptada",
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
    final url = Uri.parse('https://apifixya.onrender.com/proposals/for-cleaner');
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
        _fetchProposals(); // Update proposals list after status change
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
          tabs: statuses.map((status) => Tab(text: statusLabels[status])).toList(),
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
                              Text("Estado: ${statusLabels[proposal['status']] ?? proposal['status']}"),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProposalDetailScreen(
                                  proposal: proposal,
                                  onStatusChange: _updateProposalStatus,
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

class ProposalDetailScreen extends StatelessWidget {
  final dynamic proposal;
  final Function(int, String) onStatusChange;

  const ProposalDetailScreen({
    Key? key,
    required this.proposal,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Propuesta #${proposal['id']}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dirección: ${proposal['direccion'] ?? ''}", style: const TextStyle(fontSize: 18)),
            Text("Fecha: ${proposal['date'] ?? ''}", style: const TextStyle(fontSize: 18)),
            Text("Estado: ${proposal['status'] ?? ''}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    onStatusChange(proposal['id'], "accepted");
                    Navigator.pop(context);
                  },
                  child: const Text("Aceptar", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    onStatusChange(proposal['id'], "rejected");
                    Navigator.pop(context);
                  },
                  child: const Text("Rechazar", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
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
