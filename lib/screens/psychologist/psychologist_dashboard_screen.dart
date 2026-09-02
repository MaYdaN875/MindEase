import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PsychologistDashboardScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doctorName = userProfile?['name'] ?? 'Dr. Aris';
    final avatarUrl = userProfile?['avatarUrl'] ??
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDe8aEnYEe0WkRD0hX2zIU3SqmhO0aIVPGKUcNIFi9kkdObEmglpr4-2LkhXTxd55O7ZItBatuFjfkDn8oxq0b4uKi2uSlIJZftT68sDwYbHM73zXDmi_t_EvePkMS8MqkPb0BqU1gdiROK4NCLm7xRVKvXZFruCG2pLGEeJQel4VWtvtx2JUhH0notJAq3U-ssAR0Hb_8Tg-LTdiFYUxAD94fvn8DPN6sqre-t4AINClnPHqqZO55UXA';

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
                    'Buenos días, $doctorName',
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
            icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: onToggleTheme,
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
            onPressed: onOpenNotifications,
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
              // Acciones Rápidas (Bento style)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickAction(
                      icon: Icons.edit_square,
                      label: 'Nueva\npublicación',
                      onTap: onCreatePost,
                      isDark: isDark,
                    ),
                    _buildQuickAction(
                      icon: Icons.schedule,
                      label: 'Configurar\ndispon.',
                      onTap: () => onNavigateTab(1), // Go to Agenda
                      isDark: isDark,
                    ),
                    _buildQuickAction(
                      icon: Icons.calendar_month,
                      label: 'Ver\nagenda',
                      onTap: () => onNavigateTab(1), // Go to Agenda
                      isDark: isDark,
                    ),
                    _buildQuickAction(
                      icon: Icons.person_outline,
                      label: 'Ver\nperfil',
                      onTap: () => onNavigateTab(4), // Go to Profile
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
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border(
                    left: const BorderSide(color: AppTheme.primary, width: 4),
                    top: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    right: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    bottom: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  ),
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
                        child: const Text(
                          'En 15 min',
                          style: TextStyle(
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
                                  color: isDark
                                      ? AppTheme.secondary.withValues(alpha: 0.3)
                                      : AppTheme.secondaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    'JD',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppTheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'John Doe',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                    ),
                                  ),
                                  Text(
                                    'Paciente regular',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                    ),
                                  ),
                                ],
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
                                _buildInfoChip(Icons.calendar_today, 'Hoy', isDark),
                                _buildInfoChip(Icons.schedule, '10:30 AM', isDark),
                                _buildInfoChip(Icons.videocam, 'Videollamada', isDark),
                                _buildInfoChip(Icons.timer, '50 min', isDark),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          ElevatedButton.icon(
                            onPressed: () => onNavigateTab(2), // Go to Consultas
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
              ),
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
                    onTap: onOpenEarnings,
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
                              const Text(
                                '\$1,240',
                                style: TextStyle(
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
                          number: '4',
                          label: 'Próximas',
                          onTap: () => onNavigateTab(2),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildBentoStatCard(
                          icon: Icons.pending_actions,
                          iconColor: AppTheme.tertiaryFixedDim,
                          number: '2',
                          label: 'Pendientes',
                          onTap: () => onNavigateTab(2),
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
                          icon: Icons.group_add_outlined,
                          iconColor: AppTheme.secondary,
                          number: '12',
                          label: 'Nuevos seguidores',
                          onTap: onOpenStats,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildBentoStatCard(
                          icon: Icons.article_outlined,
                          iconColor: AppTheme.secondary,
                          number: '8',
                          label: 'Publicaciones',
                          onTap: () => onNavigateTab(3),
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
                    onPressed: () => onNavigateTab(2),
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
                child: Column(
                  children: [
                    _buildActivityItem(
                      icon: Icons.book_online,
                      iconBg: AppTheme.primary.withValues(alpha: 0.1),
                      iconColor: AppTheme.primary,
                      title: 'Nueva reserva de María G.',
                      time: 'Hace 2 horas',
                      isDark: isDark,
                    ),
                    Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    _buildActivityItem(
                      icon: Icons.chat_bubble_outline,
                      iconBg: AppTheme.secondaryContainer,
                      iconColor: AppTheme.onSecondaryContainer,
                      title: 'Comentario en publicación Ansiedad',
                      time: 'Hace 5 horas',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
