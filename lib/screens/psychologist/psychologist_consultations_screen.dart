import 'package:flutter/material.dart';
import '../../services/appointment_service.dart';
import '../../models/appointment_status.dart';
import '../../services/video_service.dart';
import 'clinical_notes_screen.dart';
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
  final List<String> _filters = ['Solicitudes', 'Próximas', 'En curso', 'Finalizadas', 'Canceladas'];

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

  void _showRejectDialog(String apptId) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar / Cancelar Solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indica el motivo para notificar al paciente:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Ej. Fuera de horario, especialista no disponible...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = textController.text.trim().isEmpty
                  ? 'Especialista no disponible en este horario'
                  : textController.text.trim();
              Navigator.pop(ctx);
              _updateStatus(apptId, 'CANCELLED', reason: reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showConsultationDetails(dynamic appt) {
    final patientName = appt['user']?['name'] ?? 'Paciente';
    final startAtStr = appt['startAt'];
    final startAt = startAtStr != null ? DateTime.parse(startAtStr).toLocal() : null;
    final timeFormatted = startAt != null
        ? '${startAt.day}/${startAt.month}/${startAt.year} a las ${startAt.hour.toString().padLeft(2, '0')}:${startAt.minute.toString().padLeft(2, '0')}'
        : 'Sin fecha';
    final status = appointmentDisplayStatus(appt);
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
              if (status == 'IN_PROGRESS' || status == 'COMPLETED')
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ClinicalNotesScreen(appointmentId: apptId)));
                  },
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Notas clínicas privadas'),
                ),
              if (status == 'IN_PROGRESS')
                OutlinedButton.icon(
                  onPressed: () => VideoService.join(context, apptId),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir sesión virtual'),
                ),
              if (status == 'CONFIRMED' || status == 'IN_PROGRESS') ...[
                if (status == 'CONFIRMED')
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _startConsultation(apptId, patientName);
                    },
                    icon: const Icon(Icons.video_call),
                    label: const Text('Iniciar Consulta Clínica', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.textDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                if (status == 'IN_PROGRESS') ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showCompleteDialog(apptId, patientName);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Finalizar Consulta', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (status != 'IN_PROGRESS') OutlinedButton(
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

  Future<void> _startConsultation(String apptId, String patientName) async {
    if (!VideoService.supported) {
      await VideoService.join(context, apptId);
      return;
    }
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Iniciar consulta'),
      content: const Text('Se iniciará la consulta clínica y podrás entrar a Jitsi. Al salir de la llamada, finaliza la consulta aquí cuando corresponda.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Iniciar'))],
    ));
    if (confirmed != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando sesión con $patientName...'),
        backgroundColor: AppTheme.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );

    final res = await _appointmentService.startConsultation(apptId);
    if (mounted) {
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consulta con $patientName iniciada (En curso).'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _selectedFilter = 'En curso';
        });
        _fetchAppointments();
        await VideoService.join(context, apptId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Error al iniciar consulta.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCompleteDialog(String apptId, String patientName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar Consulta'),
        content: Text('¿Deseas dar por concluida la sesión clínica con $patientName? Se registrará como completada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar sesión'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await _appointmentService.completeConsultation(apptId);
              if (mounted) {
                if (res['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Consulta con $patientName finalizada con éxito.'),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  setState(() {
                    _selectedFilter = 'Finalizadas';
                  });
                  _fetchAppointments();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Error al concluir consulta.'),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Finalizar Consulta'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredAppointments = _appointments.where((appt) {
      final status = appointmentDisplayStatus(appt);
      if (_selectedFilter == 'Solicitudes') {
        return status == 'PENDING';
      } else if (_selectedFilter == 'Próximas') {
        return status == 'CONFIRMED';
      } else if (_selectedFilter == 'En curso') {
        return status == 'IN_PROGRESS';
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
                        int count = 0;
                        if (filter == 'Solicitudes') {
                          count = _appointments.where((a) => (a['status'] as String?)?.toUpperCase() == 'PENDING').length;
                        } else if (filter == 'Próximas') {
                          count = _appointments.where((a) => (a['status'] as String?)?.toUpperCase() == 'CONFIRMED').length;
                        } else if (filter == 'En curso') {
                          count = _appointments.where((a) => (a['status'] as String?)?.toUpperCase() == 'IN_PROGRESS').length;
                        } else if (filter == 'Finalizadas') {
                          count = _appointments.where((a) => (a['status'] as String?)?.toUpperCase() == 'COMPLETED').length;
                        } else if (filter == 'Canceladas') {
                          count = _appointments.where((a) => (a['status'] as String?)?.toUpperCase() == 'CANCELLED').length;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  filter,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppTheme.textDark
                                        : (isDark ? AppTheme.textSecondaryDark : AppTheme.textMediumLight),
                                  ),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.textDark.withValues(alpha: 0.2)
                                          : (filter == 'Solicitudes'
                                              ? AppTheme.tertiaryFixedDim
                                              : AppTheme.primary.withValues(alpha: 0.2)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppTheme.textDark
                                            : (filter == 'Solicitudes' ? Colors.black : AppTheme.primaryDark),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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
                                final status = appointmentDisplayStatus(appt);
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
                                            if (status == 'PENDING') ...[
                                              TextButton(
                                                onPressed: () => _showRejectDialog(apptId),
                                                child: const Text('Rechazar', style: TextStyle(color: AppTheme.error, fontSize: 12)),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton.icon(
                                                onPressed: () => _updateStatus(apptId, 'CONFIRMED'),
                                                icon: const Icon(Icons.check, size: 14),
                                                label: const Text('Aceptar Cita', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF10B981),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                            ] else if (status == 'CONFIRMED') ...[
                                              TextButton(
                                                onPressed: () => _showRejectDialog(apptId),
                                                child: const Text('Cancelar', style: TextStyle(color: AppTheme.error, fontSize: 12)),
                                              ),
                                              TextButton(
                                                onPressed: () => _showConsultationDetails(appt),
                                                child: const Text('Ver detalles', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton.icon(
                                                onPressed: () => _startConsultation(apptId, patientName),
                                                icon: const Icon(Icons.arrow_forward, size: 14),
                                                label: const Text('Iniciar consulta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.primary,
                                                  foregroundColor: AppTheme.textDark,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                            ] else if (status == 'IN_PROGRESS') ...[
                                              TextButton(
                                                onPressed: () => _showConsultationDetails(appt),
                                                child: const Text('Ver detalles', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton.icon(
                                                onPressed: () => _showCompleteDialog(apptId, patientName),
                                                icon: const Icon(Icons.check_circle_outline, size: 14),
                                                label: const Text('Finalizar consulta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF10B981),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                            ] else ...[
                                              TextButton(
                                                onPressed: () => _showConsultationDetails(appt),
                                                child: const Text('Ver detalles', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
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
