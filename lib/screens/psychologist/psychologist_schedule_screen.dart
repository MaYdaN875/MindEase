import 'package:flutter/material.dart';
import '../../services/psychologist_service.dart';
import '../../services/appointment_service.dart';
import '../../theme/app_theme.dart';

class PsychologistScheduleScreen extends StatefulWidget {
  final VoidCallback onOpenNotifications;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const PsychologistScheduleScreen({
    super.key,
    required this.onOpenNotifications,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<PsychologistScheduleScreen> createState() => _PsychologistScheduleScreenState();
}

class _PsychologistScheduleScreenState extends State<PsychologistScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PsychologistService _psychologistService = PsychologistService();
  final AppointmentService _appointmentService = AppointmentService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String _timeZone = 'America/Mexico_City';

  // Day mapping for backend DayOfWeek enum
  final List<Map<String, String>> _daysConfig = [
    {'enum': 'MONDAY', 'name': 'Lunes'},
    {'enum': 'TUESDAY', 'name': 'Martes'},
    {'enum': 'WEDNESDAY', 'name': 'Miércoles'},
    {'enum': 'THURSDAY', 'name': 'Jueves'},
    {'enum': 'FRIDAY', 'name': 'Viernes'},
    {'enum': 'SATURDAY', 'name': 'Sábado'},
    {'enum': 'SUNDAY', 'name': 'Domingo'},
  ];

  // State of weekly schedule
  // dayOfWeek -> List of {startTime: '09:00', endTime: '14:00', slotDuration: 50, isActive: true}
  Map<String, List<Map<String, dynamic>>> _weeklySchedule = {};
  int _globalSlotDuration = 50;

  // Appointments state
  List<dynamic> _appointments = [];
  bool _isLoadingAppointments = false;
  String? _appointmentsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _initializeSchedule();
    _fetchAvailability();
    _fetchAppointments();
  }

  void _handleTabChange() {
    if (_tabController.index == 1) {
      _fetchAppointments();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _initializeSchedule() {
    _weeklySchedule = {};
    for (var day in _daysConfig) {
      final dayKey = day['enum']!;
      // Default initial dummy state for week days
      if (dayKey == 'MONDAY' || dayKey == 'TUESDAY') {
        _weeklySchedule[dayKey] = [
          {
            'startTime': '09:00',
            'endTime': '14:00',
            'slotDuration': 50,
            'isActive': true,
          }
        ];
      } else if (dayKey == 'THURSDAY') {
        _weeklySchedule[dayKey] = [
          {
            'startTime': '16:00',
            'endTime': '20:00',
            'slotDuration': 50,
            'isActive': true,
          }
        ];
      } else {
        _weeklySchedule[dayKey] = [];
      }
    }
  }

  Future<void> _fetchAvailability() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _psychologistService.getMyAvailability();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (res['success'] == true) {
        _timeZone = res['timeZone'] ?? 'America/Mexico_City';
        final List<dynamic> list = res['data'];
        final Map<String, List<Map<String, dynamic>>> mapped = {};
        for (var day in _daysConfig) {
          mapped[day['enum']!] = [];
        }

        for (var item in list) {
          final day = item['dayOfWeek'] as String;
          if (mapped.containsKey(day)) {
            mapped[day]!.add({
              'startTime': item['startTime'] ?? '09:00',
              'endTime': item['endTime'] ?? '14:00',
              'slotDuration': item['slotDuration'] ?? 50,
              'isActive': item['isActive'] ?? true,
            });
          }
        }

        setState(() {
          _weeklySchedule = mapped;
        });
      }
    }
  }

  Future<void> _fetchAppointments() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAppointments = true;
      _appointmentsError = null;
    });

    final res = await _appointmentService.getMyAppointments(asRole: 'psychologist');

    if (!mounted) return;
    setState(() {
      _isLoadingAppointments = false;
      if (res['success'] == true) {
        _appointments = res['data'] ?? [];
      } else {
        _appointmentsError = res['message'] ?? 'Error al cargar citas';
      }
    });
  }

  Future<void> _saveAvailability() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final List<Map<String, dynamic>> payload = [];

    _weeklySchedule.forEach((day, slots) {
      for (var slot in slots) {
        if (slot['isActive'] == true) {
          payload.add({
            'dayOfWeek': day,
            'startTime': slot['startTime'],
            'endTime': slot['endTime'],
            'slotDuration': slot['slotDuration'] ?? _globalSlotDuration,
            'isActive': true,
          });
        }
      }
    });

    final res = await _psychologistService.updateMyAvailability(payload);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disponibilidad semanal guardada exitosamente en el servidor.'),
            backgroundColor: AppTheme.primaryDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Error al guardar disponibilidad';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddTimeSlotDialog(String? preselectedDay) {
    String selectedDay = preselectedDay ?? 'MONDAY';
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 14, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            String formatTime(TimeOfDay t) {
              final h = t.hour.toString().padLeft(2, '0');
              final m = t.minute.toString().padLeft(2, '0');
              return '$h:$m';
            }

            return AlertDialog(
              backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.more_time, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text('Añadir Horario'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selecciona el día y rango horario disponible:', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDay,
                    decoration: InputDecoration(
                      labelText: 'Día de la semana',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: _daysConfig.map((d) {
                      return DropdownMenuItem(value: d['enum'], child: Text(d['name']!));
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedDay = val!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: startTime);
                            if (picked != null) {
                              setModalState(() => startTime = picked);
                            }
                          },
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text('Inicio: ${formatTime(startTime)}', style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: endTime);
                            if (picked != null) {
                              setModalState(() => endTime = picked);
                            }
                          },
                          icon: const Icon(Icons.access_time_filled, size: 16),
                          label: Text('Fin: ${formatTime(endTime)}', style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final startStr = formatTime(startTime);
                    final endStr = formatTime(endTime);

                    if (startTime.hour > endTime.hour || (startTime.hour == endTime.hour && startTime.minute >= endTime.minute)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('La hora de inicio debe ser anterior a la hora de fin.'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                      return;
                    }

                    final existingSlots = _weeklySchedule[selectedDay] ?? [];
                    final isDuplicate = existingSlots.any((s) =>
                        s['startTime'] == startStr &&
                        s['endTime'] == endStr &&
                        s['isActive'] == true);

                    if (isDuplicate) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ya existe este rango de horario para este día.'),
                          backgroundColor: AppTheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _weeklySchedule[selectedDay] ??= [];
                      _weeklySchedule[selectedDay]!.add({
                        'startTime': startStr,
                        'endTime': endStr,
                        'slotDuration': _globalSlotDuration,
                        'isActive': true,
                      });
                    });

                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.textDark,
                  ),
                  child: const Text('Añadir', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda Profesional'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: widget.onToggleTheme,
            tooltip: 'Cambiar tema',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: widget.onOpenNotifications,
            tooltip: 'Notificaciones',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (idx) {
            if (idx == 1) {
              _fetchAppointments();
            }
          },
          labelColor: AppTheme.primary,
          unselectedLabelColor: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'Disponibilidad semanal'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Citas agendadas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailabilityTab(isDark),
          _buildAppointmentsTab(isDark),
        ],
      ),
    );
  }

  Widget _buildAvailabilityTab(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header info
          Text(
            'Disponibilidad semanal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textLight : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Define tus días, horarios y duración de sesión. Zona horaria de la agenda: $_timeZone.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),

          // Duration Configuration Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 20, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('Duración de cada sesión:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                DropdownButton<int>(
                  value: _globalSlotDuration,
                  underline: const SizedBox(),
                  items: [30, 45, 50, 60].map((d) {
                    return DropdownMenuItem(value: d, child: Text('$d min', style: const TextStyle(fontWeight: FontWeight.bold)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _globalSlotDuration = val;
                        // update existing slots
                        _weeklySchedule.forEach((k, list) {
                          for (var s in list) {
                            s['slotDuration'] = val;
                          }
                        });
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weekly days list
          ..._daysConfig.map((day) {
            final dayKey = day['enum']!;
            final dayName = day['name']!;
            final slots = _weeklySchedule[dayKey] ?? [];
            final hasSlots = slots.any((s) => s['isActive'] == true);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: hasSlots ? AppTheme.primary : (isDark ? AppTheme.borderDark : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      if (!hasSlots)
                        const Text(
                          'No disponible',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.primary),
                        tooltip: 'Agregar horario a $dayName',
                        onPressed: () => _showAddTimeSlotDialog(dayKey),
                      ),
                    ],
                  ),
                  if (hasSlots) ...[
                    const SizedBox(height: 8),
                    ...slots.where((s) => s['isActive'] == true).map((slot) {
                      return Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.bgDark.withValues(alpha: 0.5) : AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              slot['startTime'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryDark),
                            ),
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Divider(thickness: 1.5, color: AppTheme.primary),
                              ),
                            ),
                            Text(
                              slot['endTime'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryDark),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle, size: 16, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  slots.remove(slot);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 12),

          // Button "+ Agregar horario"
          OutlinedButton.icon(
            onPressed: () => _showAddTimeSlotDialog(null),
            icon: const Icon(Icons.add, color: AppTheme.primary),
            label: const Text('+ Agregar horario', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // Button "[Guardar disponibilidad]"
          ElevatedButton(
            onPressed: _isSaving ? null : _saveAvailability,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.textDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textDark),
                  )
                : const Text(
                    'Guardar disponibilidad',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab(bool isDark) {
    if (_isLoadingAppointments) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_appointmentsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 64, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(
                _appointmentsError!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchAppointments,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_available, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'No tienes consultas agendadas por el momento.',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchAppointments,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: AppTheme.textDark),
                child: const Text('Actualizar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAppointments,
      color: AppTheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        itemBuilder: (ctx, index) {
          final appt = _appointments[index];
          final patientName = appt['user']?['name'] ?? 'Paciente';
          final startAtStr = appt['startAt'];
          final startAt = startAtStr != null ? DateTime.parse(startAtStr).toLocal() : null;
          final status = appt['status'] ?? 'CONFIRMED';
          final price = appt['price'] ?? 0;

          final formattedDate = startAt != null
              ? '${startAt.day}/${startAt.month}/${startAt.year} - ${startAt.hour.toString().padLeft(2, '0')}:${startAt.minute.toString().padLeft(2, '0')}'
              : 'Sin fecha';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    patientName.isNotEmpty ? patientName.substring(0, 1).toUpperCase() : 'P',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Costo: \$$price MXN • 50 min',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.primary : AppTheme.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.primary : AppTheme.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
