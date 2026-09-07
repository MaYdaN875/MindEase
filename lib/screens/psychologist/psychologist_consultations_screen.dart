import 'package:flutter/material.dart';
import '../../services/appointment_service.dart';
import '../../theme/app_theme.dart';

class PsychologistConsultationsScreen extends StatefulWidget {
  final VoidCallback onOpenNotifications;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const PsychologistConsultationsScreen({
    super.key,
    required this.onOpenNotifications,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<PsychologistConsultationsScreen> createState() => _PsychologistConsultationsScreenState();
}

class _PsychologistConsultationsScreenState extends State<PsychologistConsultationsScreen> {
  final AppointmentService _appointmentService = AppointmentService();

  String _selectedFilter = 'Próximas';
  final List<String> _filters = ['Próximas', 'En curso', 'Finalizadas', 'Canceladas'];

  bool _isLoading = true;
  List<dynamic> _appointments = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
    });

    final res = await _appointmentService.getMyAppointments(asRole: 'psychologist');

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _appointments = res['data'] ?? [];
        }
      });
    }
  }

  Future<void> _updateStatus(String appointmentId, String newStatus, {String? reason}) async {
    final res = await _appointmentService.updateAppointmentStatus(
      appointmentId,
      newStatus,
      cancellationReason: reason,
    );

    if (mounted) {
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Estado de la cita actualizado.'),
            backgroundColor: AppTheme.primaryDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchAppointments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Error al actualizar estado.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showConsultationDetails(dynamic appt) {
    final patientName = appt['user']?['name'] ?? 'Paciente';
    final startAtStr = appt['startAt'];
    final startAt = startAtStr != null ? DateTime.parse(startAtStr).toLocal() : null;
    final timeFormatted = startAt != null
        ? '${startAt.day}/${startAt.month}/${startAt.year} a las ${startAt.hour.toString().padLeft(2, '0')}:${startAt.minute.toString().padLeft(2, '0')}'
        : 'Sin fecha';
    final status = appt['status'] ?? 'CONFIRMED';
    final apptId = appt['id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detalle de Consulta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  child: Text(patientName.substring(0, 1).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Horario: $timeFormatted • Videollamada'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Motivo de consulta:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Seguimiento y apoyo psicológico personalizado.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 20),
              if (status == 'CONFIRMED' || status == 'PENDING') ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _enterConsultation(patientName);
                  },
                  icon: const Icon(Icons.video_call),
                  label: const Text('Entrar a Sala de Consulta', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _updateStatus(apptId, 'CANCELLED', reason: 'Cancelada por el profesional');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                  ),
                  child: const Text('Cancelar Cita'),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _enterConsultation(String patientName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando sesión segura con $patientName...'),
        backgroundColor: AppTheme.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredAppointments = _appointments.where((appt) {
      final status = (appt['status'] as String?)?.toUpperCase() ?? 'CONFIRMED';
      if (_selectedFilter == 'Próximas') {
        return status == 'CONFIRMED' || status == 'PENDING';
      } else if (_selectedFilter == 'En curso') {
        return status == 'IN_PROGRESS' || status == 'CONFIRMED';
      } else if (_selectedFilter == 'Finalizadas') {
        return status == 'COMPLETED';
      } else if (_selectedFilter == 'Canceladas') {
        return status == 'CANCELLED';
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultas Clínicas'),
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
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestión de Consultas',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppTheme.textDark
                                    : (isDark ? AppTheme.textSecondaryDark : AppTheme.textMediumLight),
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedFilter = filter);
                            },
                            selectedColor: AppTheme.primary,
                            backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.primary
                                  : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : RefreshIndicator(
                      onRefresh: _fetchAppointments,
                      color: AppTheme.primary,
                      child: filteredAppointments.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 60.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.event_busy, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No hay consultas en la categoría "$_selectedFilter"',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              itemCount: filteredAppointments.length,
                              itemBuilder: (context, index) {
                                final appt = filteredAppointments[index];
                                final patientName = appt['user']?['name'] ?? 'Paciente';
                                final startAtStr = appt['startAt'];
                                final startAt = startAtStr != null ? DateTime.parse(startAtStr).toLocal() : null;
                                final timeStr = startAt != null
                                    ? '${startAt.day}/${startAt.month}/${startAt.year} • ${startAt.hour.toString().padLeft(2, '0')}:${startAt.minute.toString().padLeft(2, '0')} hrs'
                                    : 'Sin fecha';
                                final status = appt['status'] ?? 'CONFIRMED';
                                final apptId = appt['id'];

                                Color statusColor = AppTheme.primary;
                                if (status == 'CANCELLED') {
                                  statusColor = AppTheme.error;
                                } else if (status == 'COMPLETED') {
                                  statusColor = Colors.green;
                                } else if (status == 'PENDING') {
                                  statusColor = AppTheme.tertiaryFixedDim;
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.cardDark : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 4,
                                                        height: 36,
                                                        margin: const EdgeInsets.only(right: 10),
                                                        decoration: BoxDecoration(
                                                          color: statusColor,
                                                          borderRadius: BorderRadius.circular(2),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            const Text(
                                                              'PACIENTE',
                                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              patientName,
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    status,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: statusColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today, size: 14, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                                                const SizedBox(width: 4),
                                                Text(timeStr, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight)),
                                                const SizedBox(width: 14),
                                                Icon(Icons.videocam, size: 14, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                                                const SizedBox(width: 4),
                                                Text('Videollamada', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (status == 'CONFIRMED' || status == 'PENDING') ...[
                                              TextButton(
                                                onPressed: () => _updateStatus(apptId, 'CANCELLED', reason: 'Cancelada por el profesional'),
                                                child: const Text('Cancelar', style: TextStyle(color: AppTheme.error, fontSize: 12)),
                                              ),
                                            ],
                                            TextButton(
                                              onPressed: () => _showConsultationDetails(appt),
                                              child: const Text('Ver detalles', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                            if (status == 'CONFIRMED') ...[
                                              const SizedBox(width: 8),
                                              ElevatedButton.icon(
                                                onPressed: () => _enterConsultation(patientName),
                                                icon: const Icon(Icons.arrow_forward, size: 14),
                                                label: const Text('Entrar a consulta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.primary,
                                                  foregroundColor: AppTheme.textDark,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
