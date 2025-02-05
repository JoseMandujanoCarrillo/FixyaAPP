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
  int? _userId; // Variable para almacenar el ID del usuario logueado

  // NUEVA lista para almacenar las propuestas específicas del usuario
  List<dynamic> _userProposals = [];

  @override
  void initState() {
    super.initState();
    _loadProposals();
  }

  // Cargar todas las propuestas y el ID del usuario
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
      // Obtener los datos del usuario logueado
      final userResponse = await http.get(
        Uri.parse('https://apifixya.onrender.com/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        setState(() {
          _userId = userData['id']; // Guardar el ID del usuario
        });

        // Cargar todas las propuestas sin filtrar por user_id
        final response = await http.get(
          Uri.parse('https://apifixya.onrender.com/proposals'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _events = _groupProposalsByDate(data['proposals']);

            // Guardamos solo las propuestas cuyo user_id coincida con el ID del usuario
            _userProposals = data['proposals']
                .where((proposal) => proposal['user_id'] == _userId)
                .toList();
          });
        } else {
          throw Exception('Error al cargar las propuestas: ${response.body}');
        }
      } else {
        throw Exception('Error al obtener los datos del usuario: ${userResponse.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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

  // MÉTODO NUEVO: Navegar a la pantalla de historial (propuestas del usuario)
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
        // NUEVO: Botón en la AppBar para ver propuestas del usuario
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
                      eventLoader: (day) => _events[day] ?? [],
                      onFormatChanged: (format) => setState(() => _calendarFormat = format),
                      onPageChanged: (focusedDay) => _focusedDay = focusedDay,
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
                  child: _selectedDay != null && _events[_selectedDay] != null
                      ? ListView.builder(
                          itemCount: _events[_selectedDay]!.length,
                          itemBuilder: (context, index) {
                            final proposal = _events[_selectedDay]![index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                subtitle: Text('Estado: ${proposal['status'] ?? 'Desconocido'}'),
                                trailing: const Icon(Icons.arrow_forward, color: Colors.blue),
                                onTap: () {
                                  // Navegar a la pantalla de detalles de la propuesta
                                },
                              ),
                            );
                          },
                        )
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

// NUEVA PANTALLA: Historial de servicio (lista de propuestas del usuario)
class UserProposalsScreen extends StatelessWidget {
  final List<dynamic> proposals;

  const UserProposalsScreen({Key? key, required this.proposals}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Agrupamos las propuestas por fecha para mostrarlas como en el ejemplo
    final proposalsByDate = _groupProposalsByDate(proposals);
    // Ordenamos las fechas de manera ascendente (o desc) según necesites
    final sortedDates = proposalsByDate.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de servicio'),
        // Ícono de ejemplo (papelera) como en la imagen
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Acción para borrar o limpiar, si lo necesitas
            },
          ),
        ],
      ),
      body: proposals.isEmpty
          ? const Center(
              child: Text('No tienes propuestas disponibles'),
            )
          : ListView.builder(
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final dayProposals = proposalsByDate[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado de fecha (ej. 'Recientes hoy' o 'Miércoles, 4 de diciembre...')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        _getDateTitle(date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // Lista de propuestas de ese día
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dayProposals.length,
                      itemBuilder: (context, i) {
                        final proposal = dayProposals[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              proposal['service']['name'] ?? 'Sin nombre',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Estado: ${proposal['status'] ?? 'Desconocido'}'),
                                // Ejemplo de hora fija. Ajusta según tus campos:
                                const Text('Hora: 12:30 p.m. - 2:10 p.m.'),
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

  // Reutilizamos la misma lógica de agrupar propuestas por fecha
  Map<DateTime, List<dynamic>> _groupProposalsByDate(List<dynamic> proposals) {
    final Map<DateTime, List<dynamic>> events = {};
    for (final proposal in proposals) {
      final date = DateTime.parse(proposal['date']).toLocal();
      final dateOnly = DateTime(date.year, date.month, date.day);
      events[dateOnly] = (events[dateOnly] ?? [])..add(proposal);
    }
    return events;
  }

  // Formato de fecha para los encabezados
  String _getDateTitle(DateTime date) {
    final now = DateTime.now();
    // Si es la fecha de hoy, mostrar 'Recientes hoy'
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Recientes hoy';
    }

    // Si no, mostrar con formato estilo 'Miércoles, 4 de diciembre de 2024'
    // (Se hace manualmente para no requerir paquete intl, puedes adaptarlo)
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
