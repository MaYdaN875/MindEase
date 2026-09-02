import 'package:flutter/material.dart';
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
  String _selectedFilter = 'Próximas';
  final List<String> _filters = ['Próximas', 'En curso', 'Finalizadas', 'Canceladas'];

  void _showConsultationDetails(String patientName, String time, String type, String status) {
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
                  child: Text(patientName.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Horario: $time • Modalidad: $type'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Motivo de consulta:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Seguimiento semanal de manejo de estrés laboral y técnicas de respiración profunda.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 20),
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page Header & Filtering
              Text(
                'Gestión de Consultas',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),

              // Filter Tabs Scrollable
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
              const SizedBox(height: 16),

              // Consultations List
              if (_selectedFilter == 'Próximas' || _selectedFilter == 'En curso') ...[
                // Card 1: Today, Upcoming
                _buildConsultationCard(
                  patientName: 'Robert Smith',
                  time: 'Hoy 11:30 AM',
                  type: 'Chat Privado',
                  status: 'Confirmada',
                  statusColor: AppTheme.primary,
                  isToday: true,
                  isDark: isDark,
                  onEnter: () => _enterConsultation('Robert Smith'),
                  onViewDetails: () => _showConsultationDetails('Robert Smith', 'Hoy 11:30 AM', 'Chat Privado', 'Confirmada'),
                ),
                const SizedBox(height: 14),

                // Card 2: Tomorrow
                _buildConsultationCard(
                  patientName: 'Sarah Connor',
                  time: 'Mañana 09:00 AM',
                  type: 'Videollamada',
                  status: 'Pendiente',
                  statusColor: AppTheme.tertiaryFixedDim,
                  isToday: false,
                  isDark: isDark,
                  onEnter: () => _enterConsultation('Sarah Connor'),
                  onViewDetails: () => _showConsultationDetails('Sarah Connor', 'Mañana 09:00 AM', 'Videollamada', 'Pendiente'),
                ),
              ] else if (_selectedFilter == 'Finalizadas') ...[
                _buildConsultationCard(
                  patientName: 'David Wilson',
                  time: 'Ayer 04:00 PM',
                  type: 'Videollamada',
                  status: 'Completada',
                  statusColor: Colors.green,
                  isToday: false,
                  isDark: isDark,
                  onEnter: () {},
                  onViewDetails: () => _showConsultationDetails('David Wilson', 'Ayer 04:00 PM', 'Videollamada', 'Completada'),
                ),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No hay consultas en esta sección',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsultationCard({
    required String patientName,
    required String time,
    required String type,
    required String status,
    required Color statusColor,
    required bool isToday,
    required bool isDark,
    required VoidCallback onEnter,
    required VoidCallback onViewDetails,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
          top: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
          right: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
          bottom: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paciente'.toUpperCase(),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Icon(
                          type == 'Videollamada' ? Icons.videocam : Icons.chat_bubble_outline,
                          size: 14,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
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
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Consulta cancelada'), behavior: SnackBarBehavior.floating),
                    );
                  },
                  child: const Text('Cancelar', style: TextStyle(color: AppTheme.error, fontSize: 12)),
                ),
                TextButton(
                  onPressed: onViewDetails,
                  child: const Text('Ver detalles', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onEnter,
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
  }
}
