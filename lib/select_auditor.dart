import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    // Ajusta la URL y parámetros según tu API.
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selecciona un auditor"),
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: auditors.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < auditors.length) {
              final auditor = auditors[index];
              return ListTile(
                title: Text(auditor['name'] ?? 'Sin nombre'),
                subtitle: Text(auditor['email'] ?? ''),
                onTap: () {
                  // Devuelve el ID del auditor seleccionado y cierra la pantalla.
                  Navigator.pop(context, auditor['auditor_id']);
                },
              );
            } else {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
