import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuditorSelectionScreen extends StatefulWidget {
  const AuditorSelectionScreen({Key? key}) : super(key: key);

  @override
  _AuditorSelectionScreenState createState() => _AuditorSelectionScreenState();
}

class _AuditorSelectionScreenState extends State<AuditorSelectionScreen> {
  List<dynamic> auditors = [];
  int page = 1;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAuditors();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        _fetchAuditors();
      }
    });
  }

  Future<void> _fetchAuditors() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    // Ajusta la URL y parámetros según tu API (se agregó paginación con page).
    final response = await http.get(
      Uri.parse('https://apifixya.onrender.com/auditors/all?page=$page'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> fetchedAuditors = json.decode(response.body);
      setState(() {
        page++;
        isLoading = false;
        if (fetchedAuditors.isEmpty) {
          hasMore = false;
        } else {
          auditors.addAll(fetchedAuditors);
        }
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print("Error al obtener auditores: ${response.statusCode}");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectAuditor(dynamic auditor) {
    final auditorId = auditor['auditor_id'];
    // Retornamos el auditor seleccionado a la pantalla que llamó
    Navigator.pop(context, auditorId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona un Auditor'),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: auditors.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < auditors.length) {
            final auditor = auditors[index];
            return ListTile(
              title: Text(auditor['name'] ?? 'Sin nombre'),
              subtitle: Text(auditor['email'] ?? ''),
              onTap: () => _selectAuditor(auditor),
            );
          } else {
            // Indicador de carga al final de la lista
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}
