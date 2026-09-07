import 'package:flutter/material.dart';
import '../../services/psychologist_service.dart';
import '../../theme/app_theme.dart';

class PsychologistDashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenEarnings;
  final VoidCallback onOpenStats;
  final VoidCallback onCreatePost;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final Map<String, dynamic>? userProfile;

  const PsychologistDashboardScreen({
    super.key,
    required this.onNavigateTab,
    required this.onOpenNotifications,
    required this.onOpenEarnings,
    required this.onOpenStats,
    required this.onCreatePost,
    required this.onToggleTheme,
    required this.isDarkMode,
    this.userProfile,
  });

  @override
  State<PsychologistDashboardScreen> createState() => _PsychologistDashboardScreenState();
}

class _PsychologistDashboardScreenState extends State<PsychologistDashboardScreen> {
  final PsychologistService _psychologistService = PsychologistService();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _psychologistService.getDashboardData();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _dashboardData = res['data'];
        } else {
          _errorMessage = res['message'] ?? 'Error al cargar datos del dashboard';
        }
      });
    }
  }

  String _formatRelativeTime(String? isoTimestamp) {
    if (isoTimestamp == null) return 'Reciente';
    try {
      final dt = DateTime.parse(isoTimestamp).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) {
        final m = diff.inMinutes;
        return m <= 1 ? 'Hace un momento' : 'Hace $m minutos';
      } else if (diff.inHours < 24) {
        final h = diff.inHours;
        return h == 1 ? 'Hace 1 hora' : 'Hace $h horas';
      } else if (diff.inDays < 7) {
        final d = diff.inDays;
        return d == 1 ? 'Ayer' : 'Hace $d días';
      } else {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {
      return 'Reciente';
    }
  }

  String _formatDateShort(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Hoy';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day) {
      return 'Mañana';
    }
    return '${dt.day}/${dt.month}';
  }

  String _formatTimeHM(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m hrs';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doctorName = _dashboardData?['doctor']?['name'] ?? widget.userProfile?['name'] ?? 'Dr. Aris';
    final avatarUrl = widget.userProfile?['avatarUrl'] ??
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDe8aEnYEe0WkRD0hX2zIU3SqmhO0aIVPGKUcNIFi9kkdObEmglpr4-2LkhXTxd55O7ZItBatuFjfkDn8oxq0b4uKi2uSlIJZftT68sDwYbHM73zXDmi_t_EvePkMS8MqkPb0BqU1gdiROK4NCLm7xRVKvXZFruCG2pLGEeJQel4VWtvtx2JUhH0notJAq3U-ssAR0Hb_8Tg-LTdiFYUxAD94fvn8DPN6sqre-t4AINClnPHqqZO55UXA';

    final stats = _dashboardData?['stats'] as Map<String, dynamic>?;
    final upcomingCount = stats?['upcomingCount']?.toString() ?? '0';
    final pendingCount = stats?['pendingCount']?.toString() ?? '0';
    final completedCount = stats?['completedCount']?.toString() ?? '0';
    final totalPatients = stats?['totalPatientsCount']?.toString() ?? '0';
    final monthlyEarnings = (stats?['monthlyEarnings'] as num?)?.toDouble() ?? 0.0;

    final nextAppt = _dashboardData?['nextAppointment'] as Map<String, dynamic>?;
    final recentActivity = (_dashboardData?['recentActivity'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary, width: 2),
                image: DecorationImage(
                  image: NetworkImage(avatarUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hola, $doctorName',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.verified, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Psicólogo verificado',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: widget.onToggleTheme,
            tooltip: 'Cambiar tema',
          ),
          IconButton(
            icon: const Stack(
              children: [
                Icon(Icons.notifications_none_outlined),
                Positioned(
                  right: 0,
                  top: 0,
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: AppTheme.error,
                  ),
                ),
              ],
            ),
            onPressed: widget.onOpenNotifications,
            tooltip: 'Notificaciones',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchDashboard,
          color: AppTheme.primary,
          child: _isLoading && _dashboardData == null
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _errorMessage != null && _dashboardData == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off_outlined, size: 64, color: AppTheme.error),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _fetchDashboard,
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
                    )
                  : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Acciones Rápidas (Bento style)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildQuickAction(
                              icon: Icons.edit_square,
                              label: 'Nueva\npublicación',
                              onTap: widget.onCreatePost,
                              isDark: isDark,
                            ),
                            _buildQuickAction(
                              icon: Icons.schedule,
                              label: 'Configurar\ndispon.',
                              onTap: () => widget.onNavigateTab(1), // Agenda
                              isDark: isDark,
                            ),
                            _buildQuickAction(
                              icon: Icons.calendar_month,
                              label: 'Ver\nagenda',
                              onTap: () => widget.onNavigateTab(1), // Agenda
                              isDark: isDark,
                            ),
                            _buildQuickAction(
                              icon: Icons.person_outline,
                              label: 'Ver\nperfil',
                              onTap: () => widget.onNavigateTab(4), // Perfil
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Próxima Consulta Destacada
                      Text(
                        'Próxima consulta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (nextAppt != null)
                        _buildNextAppointmentCard(nextAppt, isDark)
                      else
                        _buildEmptyAppointmentCard(isDark),

                      const SizedBox(height: 24),

                      // Resumen (Bento Grid)
                      Text(
                        'Resumen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          // Hero Card: Ingresos del mes
                          InkWell(
                            onTap: widget.onOpenEarnings,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.primary, AppTheme.primaryDark],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ingresos del mes',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textDark.withValues(alpha: 0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${monthlyEarnings.toStringAsFixed(0)} MXN',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.trending_up, color: AppTheme.textDark),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 2x2 Grid Stats
                          Row(
                            children: [
                              Expanded(
                                child: _buildBentoStatCard(
                                  icon: Icons.calendar_today_outlined,
                                  iconColor: AppTheme.primary,
                                  number: upcomingCount,
                                  label: 'Próximas',
                                  onTap: () => widget.onNavigateTab(2), // Consultas
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildBentoStatCard(
                                  icon: Icons.pending_actions,
                                  iconColor: AppTheme.tertiaryFixedDim,
                                  number: pendingCount,
                                  label: 'Pendientes',
                                  onTap: () => widget.onNavigateTab(2),
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildBentoStatCard(
                                  icon: Icons.people_outline,
                                  iconColor: AppTheme.secondary,
                                  number: totalPatients,
                                  label: 'Pacientes',
                                  onTap: () => widget.onNavigateTab(2),
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildBentoStatCard(
                                  icon: Icons.check_circle_outline,
                                  iconColor: Colors.green,
                                  number: completedCount,
                                  label: 'Completadas',
                                  onTap: () => widget.onNavigateTab(2),
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Actividad Reciente
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Actividad reciente',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                            ),
                          ),
                          TextButton(
                            onPressed: () => widget.onNavigateTab(2),
                            child: const Text('Ver todo', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                        ),
                        child: recentActivity.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Center(
                                  child: Text(
                                    'No hay actividad reciente aún.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (int i = 0; i < recentActivity.length; i++) ...[
                                    _buildActivityItem(
                                      icon: _getActivityIcon(recentActivity[i]['status']),
                                      iconBg: AppTheme.primary.withValues(alpha: 0.1),
                                      iconColor: AppTheme.primary,
                                      title: recentActivity[i]['title'] ?? 'Cita actualizada',
                                      time: _formatRelativeTime(recentActivity[i]['timestamp']),
                                      isDark: isDark,
                                    ),
                                    if (i < recentActivity.length - 1)
                                      Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                                  ],
                                ],
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  IconData _getActivityIcon(String? status) {
    if (status == 'CONFIRMED') return Icons.event_available;
    if (status == 'COMPLETED') return Icons.check_circle_outline;
    if (status == 'CANCELLED') return Icons.cancel_outlined;
    return Icons.book_online;
  }

  Widget _buildNextAppointmentCard(Map<String, dynamic> appt, bool isDark) {
    final patientName = appt['user']?['name'] ?? 'Paciente';
    final startAtStr = appt['startAt'];
    final startAt = startAtStr != null ? DateTime.parse(startAtStr).toLocal() : DateTime.now();
    final dateStr = _formatDateShort(startAt);
    final timeStr = _formatTimeHM(startAt);
    final status = appt['status'] ?? 'CONFIRMED';

    final initials = patientName.trim().isNotEmpty
        ? patientName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'P';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.secondary.withValues(alpha: 0.3) : AppTheme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.onSecondaryContainer,
                          ),
                        ),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                            ),
                          ),
                          Text(
                            'Consulta individual',
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
                const SizedBox(height: 14),

                // Metadata Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgDark.withValues(alpha: 0.5) : AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoChip(Icons.calendar_today, dateStr, isDark),
                      _buildInfoChip(Icons.schedule, timeStr, isDark),
                      _buildInfoChip(Icons.videocam, 'Videollamada', isDark),
                      _buildInfoChip(Icons.timer, '50 min', isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                ElevatedButton.icon(
                  onPressed: () => widget.onNavigateTab(2), // Go to Consultas
                  icon: const Icon(Icons.video_camera_front, size: 18),
                  label: const Text('Ver consulta', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAppointmentCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available, size: 48, color: AppTheme.primary.withValues(alpha: 0.8)),
          const SizedBox(height: 10),
          Text(
            'Sin consultas pendientes hoy',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textLight : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tu agenda está al día. Puedes configurar tus horarios de atención para recibir nuevas citas.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => widget.onNavigateTab(1), // Go to Agenda
            icon: const Icon(Icons.schedule, size: 16),
            label: const Text('Gestionar disponibilidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.textMediumDark : AppTheme.textMediumLight,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? AppTheme.textMediumDark : AppTheme.textMediumLight,
          ),
        ),
      ],
    );
  }

  Widget _buildBentoStatCard({
    required IconData icon,
    required Color iconColor,
    required String number,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 8),
            Text(
              number,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textLight : AppTheme.textDark,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String time,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
