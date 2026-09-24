import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import '../models/appointment_status.dart';
import '../services/video_service.dart';
import 'patient_payment_history_screen.dart';
import '../theme/app_theme.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  final VoidCallback onNavigateToDirectory;

  const PatientAppointmentsScreen({
    super.key,
    required this.onNavigateToDirectory,
  });

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();

  String _selectedFilter = 'Todas';
  final List<String> _filters = ['Todas', 'Próximas', 'Completadas', 'Canceladas'];

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _appointments = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _appointmentService.getMyAppointments(asRole: 'patient');

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _appointments = res['data'] ?? [];
        } else {
          _errorMessage = res['message'] ?? 'Error al cargar tus consultas';
        }
      });
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cancelar Consulta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Estás seguro de que deseas cancelar esta cita? Esta acción no se puede deshacer.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Motivo de la cancelación (opcional)',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Confirmar cancelación'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final res = await _appointmentService.updateAppointmentStatus(
        appointmentId,
        'CANCELLED',
        cancellationReason: reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : null,
      );
      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Consulta cancelada con éxito.'),
              backgroundColor: AppTheme.primaryDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _fetchAppointments();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'No se pudo cancelar la consulta.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  List<dynamic> get _filteredAppointments {
    final now = DateTime.now();
    if (_selectedFilter == 'Próximas') {
      return _appointments.where((a) {
        final status = a['status'];
        final startAtStr = a['startAt'];
        final startAt = startAtStr != null ? DateTime.parse(startAtStr).toLocal() : null;
        return (status == 'CONFIRMED' || status == 'PENDING' || status == 'IN_PROGRESS') &&
            (startAt == null || startAt.isAfter(now.subtract(const Duration(hours: 1))));
      }).toList();
    } else if (_selectedFilter == 'Completadas') {
      return _appointments.where((a) => a['status'] == 'COMPLETED').toList();
    } else if (_selectedFilter == 'Canceladas') {
      return _appointments.where((a) => a['status'] == 'CANCELLED').toList();
    }
    return _appointments;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = _filteredAppointments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Consultas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Mis Recibos y Pagos',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PatientPaymentHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: SingleChildScrollView(
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
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_off_outlined, size: 56, color: AppTheme.error),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(fontSize: 14, color: AppTheme.error, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _fetchAppointments,
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Reintentar'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: AppTheme.textDark),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchAppointments,
                          color: AppTheme.primary,
                          child: list.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                                          const SizedBox(height: 14),
                                          Text(
                                            _selectedFilter == 'Todas'
                                                ? 'Aún no tienes consultas agendadas'
                                                : 'No hay consultas en la categoría "$_selectedFilter"',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Encuentra al profesional ideal y agenda tu sesión en minutos.',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 20),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              widget.onNavigateToDirectory();
                                            },
                                            icon: const Icon(Icons.search, size: 18),
                                            label: const Text('Explorar especialistas', style: TextStyle(fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primary,
                                              foregroundColor: AppTheme.textDark,
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  itemCount: list.length,
                                  itemBuilder: (context, index) {
                                    final appt = list[index];
                                    return _buildAppointmentCard(appt, isDark);
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt, bool isDark) {
    final apptId = appt['id'];
    final doctorName = appt['psychologist']?['user']?['name'] ?? 'Especialista';
    final startAtStr = appt['startAt'];
    final startAt = startAtStr != null ? DateTime.parse(startAtStr).toLocal() : null;
    final status = appointmentDisplayStatus(appt);
    final price = appt['price'] ?? 0;


    final formattedDate = startAt != null
        ? '${startAt.day}/${startAt.month}/${startAt.year} • ${startAt.hour.toString().padLeft(2, '0')}:${startAt.minute.toString().padLeft(2, '0')} hrs'
        : 'Fecha por definir';

    Color statusColor = AppTheme.primary;
    String statusLabel = 'CONFIRMADA';
    if (status == 'CANCELLED') {
      statusColor = AppTheme.error;
      statusLabel = 'CANCELADA';
    } else if (status == 'COMPLETED') {
      statusColor = Colors.green;
      statusLabel = 'COMPLETADA';
    } else if (status == 'PENDING') {
      statusColor = AppTheme.tertiaryFixedDim;
      statusLabel = 'PENDIENTE';
    } else if (status == 'IN_PROGRESS') {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'EN CURSO';
    }

    final initials = doctorName.trim().isNotEmpty
        ? doctorName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'DR';

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
                            height: 38,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                            child: Text(
                              initials,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctorName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Psicoterapia Individual',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
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
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Date and details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgDark.withValues(alpha: 0.5) : AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                          const SizedBox(width: 6),
                          Text(
                            formattedDate,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? AppTheme.textLight : AppTheme.textDark),
                          ),
                        ],
                      ),
                      Text(
                        '\$$price MXN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.primary : AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (status == 'IN_PROGRESS') ...[
            Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.fiber_manual_record, color: Color(0xFF10B981), size: 12),
                      SizedBox(width: 6),
                      Text('Sesión en curso', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => VideoService.join(context, apptId),
                    icon: const Icon(Icons.videocam, size: 16),
                    label: const Text('Unirse a consulta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (status == 'CONFIRMED' || status == 'PENDING') ...[
            Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _cancelAppointment(apptId),
                    child: const Text('Cancelar cita', style: TextStyle(color: AppTheme.error, fontSize: 13)),
                  ),
                  if (status == 'CONFIRMED') ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => VideoService.join(context, apptId),
                      icon: const Icon(Icons.videocam, size: 16),
                      label: const Text('Entrar a sesión', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.textDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
