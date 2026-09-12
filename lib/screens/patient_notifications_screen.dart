import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'patient_appointments_screen.dart';

class PatientNotificationsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDirectory;

  const PatientNotificationsScreen({
    super.key,
    this.onNavigateToDirectory,
  });

  @override
  State<PatientNotificationsScreen> createState() => _PatientNotificationsScreenState();
}

class _PatientNotificationsScreenState extends State<PatientNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  String _currentFilter = 'Todas'; // 'Todas' | 'No leídas'

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    final res = await _notificationService.getMyNotifications();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _notifications = res['data'] ?? [];
          _unreadCount = res['unreadCount'] ?? 0;
        }
      });
    }
  }

  Future<void> _markAllRead() async {
    final res = await _notificationService.markAllAsRead();
    if (mounted && res['success'] == true) {
      setState(() {
        for (var n in _notifications) {
          if (n is Map<String, dynamic>) {
            n['isRead'] = true;
          }
        }
        _unreadCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas las notificaciones marcadas como leídas'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onTapNotification(Map<String, dynamic> notif) async {
    final notifId = notif['id'];
    if (notif['isRead'] != true && notifId != null) {
      setState(() {
        notif['isRead'] = true;
        if (_unreadCount > 0) _unreadCount--;
      });
      _notificationService.markAsRead(notifId);
    }

    final type = notif['type'];
    final referenceId = notif['referenceId'];

    if (referenceId != null &&
        (type == 'APPOINTMENT_REQUEST' ||
         type == 'APPOINTMENT_CONFIRMED' ||
         type == 'APPOINTMENT_CANCELLED' ||
         type == 'CONSULTATION_STARTED')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PatientAppointmentsScreen(
            onNavigateToDirectory: widget.onNavigateToDirectory ?? () {},
          ),
        ),
      ).then((_) => _fetchNotifications());
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Justo ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';

    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'APPOINTMENT_REQUEST':
        return Icons.calendar_today_outlined;
      case 'APPOINTMENT_CONFIRMED':
        return Icons.check_circle_outline;
      case 'APPOINTMENT_CANCELLED':
        return Icons.cancel_outlined;
      case 'CONSULTATION_STARTED':
        return Icons.videocam_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getColorForType(String? type, bool isDark) {
    switch (type) {
      case 'APPOINTMENT_REQUEST':
        return Colors.orangeAccent;
      case 'APPOINTMENT_CONFIRMED':
        return const Color(0xFF10B981); // Emerald green
      case 'APPOINTMENT_CANCELLED':
        return const Color(0xFFEF4444); // Rose red
      case 'CONSULTATION_STARTED':
        return AppTheme.primary;
      default:
        return isDark ? Colors.white70 : Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayedNotifications = _currentFilter == 'No leídas'
        ? _notifications.where((n) => n['isRead'] != true).toList()
        : _notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
              ),
              child: const Text(
                'Marcar leídas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: Column(
          children: [
            // Filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  _buildFilterChip('Todas', _notifications.length, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('No leídas', _unreadCount, isDark),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayedNotifications.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.all(16.0),
                          itemCount: displayedNotifications.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final notif = displayedNotifications[index];
                            return _buildNotificationCard(notif, isDark);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, bool isDark) {
    final isSelected = _currentFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : (isDark ? AppTheme.cardDark : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : (isDark ? AppTheme.borderSubtleDark : AppTheme.borderSubtleLight),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.textLight : AppTheme.textDark),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif, bool isDark) {
    final isRead = notif['isRead'] == true;
    final type = notif['type'] as String?;
    final title = notif['title'] ?? 'Notificación';
    final content = notif['content'] ?? '';
    final createdAt = notif['createdAt'] as String?;
    final timeStr = _formatTime(createdAt);

    final icon = _getIconForType(type);
    final accentColor = _getColorForType(type, isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTapNotification(notif),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: isRead
                ? (isDark ? AppTheme.cardDark : Colors.white)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F9FF)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRead
                  ? (isDark ? AppTheme.borderSubtleDark : AppTheme.borderSubtleLight)
                  : AppTheme.primary.withValues(alpha: 0.4),
              width: isRead ? 1 : 1.5,
            ),
          ),
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? (isRead ? AppTheme.textSecondaryDark : Colors.white70)
                            : (isRead ? AppTheme.textSecondaryLight : Colors.black87),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread indicator dot
              if (!isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 56,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _currentFilter == 'No leídas'
                  ? 'No tienes notificaciones pendientes'
                  : 'Bandeja de notificaciones vacía',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textLight : AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Te avisaremos cuando haya actualizaciones sobre tus citas, solicitudes o consultas.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
