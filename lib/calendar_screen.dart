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
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = false;
  int? _userId; // ID del usuario logueado

  // Lista para almacenar las propuestas específicas del usuario
  List<dynamic> _userProposals = [];

  @override
  void initState() {
    super.initState();
    _loadProposals();
  }

  // Cargar el usuario y sus propuestas utilizando la ruta /proposals/my
  Future<void> _loadProposals() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no logueado')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Obtener datos del usuario logueado
      final userResponse = await http.get(
        Uri.parse('https://apifixya.onrender.com/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        setState(() {
          _userId = userData['id'];
        });

        // Usar la ruta /proposals/my que devuelve solo las propuestas del usuario
        final response = await http.get(
          Uri.parse('https://apifixya.onrender.com/proposals/my'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            // Agrupar propuestas por fecha (normalizando la fecha)
            _events = _groupProposalsByDate(data['proposals']);
            // Almacenar propuestas para historial
            _userProposals = data['proposals'];
          });
        } else {
          throw Exception('Error al cargar propuestas: ${response.body}');
        }
      } else {
        throw Exception('Error al obtener datos del usuario: ${userResponse.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Función para agrupar propuestas por fecha (solo fecha)
  Map<DateTime, List<dynamic>> _groupProposalsByDate(List<dynamic> proposals) {
    final Map<DateTime, List<dynamic>> events = {};
    for (final proposal in proposals) {
      final date = DateTime.parse(proposal['date']).toLocal();
      // Normalizar la fecha (solo año, mes y día)
      final dateOnly = DateTime(date.year, date.month, date.day);
      events[dateOnly] = (events[dateOnly] ?? [])..add(proposal);
    }
    return events;
  }

  // Navegar a la pantalla de historial (propuestas del usuario)
  void _goToUserProposals() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProposalsScreen(proposals: _userProposals),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de Propuestas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _goToUserProposals,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Mostrar el ID del usuario logueado
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'ID del usuario logueado: ${_userId ?? "No disponible"}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Calendario
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TableCalendar(
                      calendarFormat: _calendarFormat,
                      focusedDay: _focusedDay,
                      firstDay: DateTime(2000),
                      lastDay: DateTime(2050),
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      // Normalizamos la fecha recibida para buscar en el mapa
                      eventLoader: (day) {
                        final normalizedDay = DateTime(day.year, day.month, day.day);
                        return _events[normalizedDay] ?? [];
                      },
                      onFormatChanged: (format) =>
                          setState(() => _calendarFormat = format),
                      onPageChanged: (focusedDay) =>
                          _focusedDay = focusedDay,
                      calendarStyle: CalendarStyle(
                        markersAlignment: Alignment.bottomCenter,
                        markersAutoAligned: true,
                        markerDecoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        markerSize: 8,
                        markerMargin: const EdgeInsets.symmetric(horizontal: 2),
                        todayDecoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Lista de propuestas para la fecha seleccionada
                Expanded(
                  child: _selectedDay != null
                      ? Builder(builder: (context) {
                          final normalizedSelectedDay = DateTime(
                            _selectedDay!.year,
                            _selectedDay!.month,
                            _selectedDay!.day,
                          );
                          final proposalsForDay =
                              _events[normalizedSelectedDay] ?? [];
                          return proposalsForDay.isNotEmpty
                              ? ListView.builder(
                                  itemCount: proposalsForDay.length,
                                  itemBuilder: (context, index) {
                                    final proposal = proposalsForDay[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          proposal['service']['name'] ?? 'Sin nombre',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Estado: ${proposal['status'] ?? 'Desconocido'}',
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward,
                                          color: Colors.blue,
                                        ),
                                        onTap: () {
                                          // Navegar a la pantalla de detalles de la propuesta
                                        },
                                      ),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Text(
                                    'No hay propuestas para esta fecha',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                        })
                      : const Center(
                          child: Text(
                            'Selecciona una fecha para ver propuestas',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

// Pantalla de Historial de Servicio: Lista de propuestas del usuario
class UserProposalsScreen extends StatelessWidget {
  final List<dynamic> proposals;

  const UserProposalsScreen({Key? key, required this.proposals})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Agrupar las propuestas por fecha
    final proposalsByDate = _groupProposalsByDate(proposals);
    // Ordenar las fechas de manera ascendente
    final sortedDates = proposalsByDate.keys.toList()..sort();

    return Scaffold(
      // FONDO: si deseas un fondo claro o gradiente, ajusta aquí
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Historial de servicio',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.black),
            onPressed: () {
              // Acción para borrar o limpiar, si es necesario
            },
          ),
        ],
      ),
      body: proposals.isEmpty
          ? const Center(
              child: Text('No tienes propuestas disponibles'),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final dayProposals = proposalsByDate[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado de fecha (ej: "Recientes hoy" o "Miércoles, 4 de diciembre de 2024")
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _getDateTitle(date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Lista de propuestas del día
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dayProposals.length,
                      itemBuilder: (context, i) {
                        final proposal = dayProposals[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nombre del servicio
                                Text(
                                  proposal['service']['name'] ?? 'Sin nombre',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Estado de la propuesta
                                Text(
                                  'Estado: ${proposal['status'] ?? 'Desconocido'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Hora (fija a modo de ejemplo)
                                const Text(
                                  'Hora: 12:30 p.m. - 2:10 p.m.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }

  // Agrupar propuestas por fecha
  Map<DateTime, List<dynamic>> _groupProposalsByDate(List<dynamic> proposals) {
    final Map<DateTime, List<dynamic>> events = {};
    for (final proposal in proposals) {
      final date = DateTime.parse(proposal['date']).toLocal();
      final dateOnly = DateTime(date.year, date.month, date.day);
      events[dateOnly] = (events[dateOnly] ?? [])..add(proposal);
    }
    return events;
  }

  // Formatear la fecha para el encabezado
  String _getDateTitle(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Recientes hoy';
    }

    final daysOfWeek = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];

    final dayOfWeek = daysOfWeek[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    return '$dayOfWeek, $day de $month de $year';
  }
}
