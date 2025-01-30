import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month; // Formato del calendario
  DateTime _focusedDay = DateTime.now(); // Día enfocado
  DateTime? _selectedDay; // Día seleccionado
  Map<DateTime, List<dynamic>> _events = {}; // Eventos (propuestas) por fecha
  List<dynamic> _proposals = []; // Lista de propuestas
  bool _isLoading = false; // Estado de carga

  @override
  void initState() {
    super.initState();
    _loadProposals(); // Cargar las propuestas al iniciar la pantalla
  }

  // Función para cargar las propuestas del usuario logueado
  Future<void> _loadProposals() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId'); // Obtener el ID del usuario logueado

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no logueado')),
      );
      return;
    }

    try {
      final proposals = await _getProposals(userId); // Obtener las propuestas
      setState(() {
        _proposals = proposals;
        _events = _groupProposalsByDate(proposals); // Agrupar propuestas por fecha
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Función para obtener las propuestas del backend
  Future<List<dynamic>> _getProposals(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Obtener el token de autenticación

    final response = await http.get(
      Uri.parse('https://apifixya.onrender.com/proposals?user_id=$userId'),
      headers: {
        'Authorization': 'Bearer $token', // Enviar el token en la cabecera
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['proposals']; // Asegúrate de que el backend devuelva las propuestas en este formato
    } else {
      throw Exception('Error al cargar las propuestas');
    }
  }

  // Función para agrupar las propuestas por fecha
  Map<DateTime, List<dynamic>> _groupProposalsByDate(List<dynamic> proposals) {
    final Map<DateTime, List<dynamic>> events = {};

    for (final proposal in proposals) {
      final date = DateTime.parse(proposal['date']).toLocal(); // Convertir la fecha
      final dateOnly = DateTime(date.year, date.month, date.day); // Ignorar la hora

      if (events[dateOnly] == null) {
        events[dateOnly] = [];
      }
      events[dateOnly]!.add(proposal); // Agregar la propuesta a la fecha correspondiente
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de Propuestas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Mostrar carga
          : Column(
              children: [
                // Calendario
                TableCalendar(
                  calendarFormat: _calendarFormat,
                  focusedDay: _focusedDay,
                  firstDay: DateTime(2000),
                  lastDay: DateTime(2050),
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day); // Resaltar el día seleccionado
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: (day) {
                    return _events[day] ?? []; // Mostrar eventos (propuestas) para el día
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format; // Cambiar el formato del calendario
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay; // Actualizar el día enfocado
                  },
                ),
                const SizedBox(height: 16),
                // Lista de propuestas para el día seleccionado
                Expanded(
                  child: _selectedDay != null
                      ? ListView(
                          children: _events[_selectedDay]?.map((proposal) {
                                return ListTile(
                                  title: Text(proposal['service']['name']),
                                  subtitle: Text('Estado: ${proposal['status']}'),
                                );
                              }).toList() ??
                              [],
                        )
                      : const Center(child: Text('Selecciona una fecha')),
                ),
              ],
            ),
    );
  }
}