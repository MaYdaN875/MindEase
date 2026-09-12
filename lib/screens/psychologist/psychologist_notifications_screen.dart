import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class PsychologistNotificationsScreen extends StatefulWidget {
  const PsychologistNotificationsScreen({super.key});

  @override
  State<PsychologistNotificationsScreen> createState() => _PsychologistNotificationsScreenState();
}

class _PsychologistNotificationsScreenState extends State<PsychologistNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  String _selectedFilter = 'Todos';
  final List<String> _filters = ['Todos', 'No leídas', 'Citas', 'Consultas', 'Sistema'];

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
          content: Text('Todas las notificaciones marcadas como leídas.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _markSingleRead(Map<String, dynamic> notif) async {
    final id = notif['id'];
    if (notif['isRead'] != true && id != null) {
      setState(() {
        notif['isRead'] = true;
        if (_unreadCount > 0) _unreadCount--;
      });
      await _notificationService.markAsRead(id);
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

  String _getCategoryForType(String? type) {
    if (type == 'APPOINTMENT_REQUEST' || type == 'APPOINTMENT_CONFIRMED' || type == 'APPOINTMENT_CANCELLED') {
      return 'Citas';
    }
    if (type == 'CONSULTATION_STARTED') {
      return 'Consultas';
    }
    return 'Sistema';
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'APPOINTMENT_REQUEST':
        return Icons.event_available;
      case 'APPOINTMENT_CONFIRMED':
        return Icons.check_circle_outline;
      case 'APPOINTMENT_CANCELLED':
        return Icons.event_busy;
      case 'CONSULTATION_STARTED':
        return Icons.videocam_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredList = _notifications.where((n) {
      if (_selectedFilter == 'Todos') return true;
      if (_selectedFilter == 'No leídas') return n['isRead'] != true;
      final cat = _getCategoryForType(n['type']);
      return cat == _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Marcar leídas', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchNotifications,
          child: Column(
            children: [
              // Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                          color: isSelected ? AppTheme.primary : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // Notification List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none_outlined,
                                  size: 48,
                                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No hay notificaciones en esta sección',
                                  style: TextStyle(
                                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final item = filteredList[index];
                              final isUnread = item['isRead'] != true;
                              final type = item['type'] as String?;
                              final title = item['title'] as String? ?? 'Notificación';
                              final body = item['content'] as String? ?? '';
                              final createdAt = item['createdAt'] as String?;
                              final timeStr = _formatTime(createdAt);
                              final icon = _getIconForType(type);

                              return GestureDetector(
                                onTap: () => _markSingleRead(item),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isUnread
                                        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4))
                                        : (isDark ? AppTheme.cardDark : Colors.white),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isUnread
                                          ? AppTheme.primary.withValues(alpha: 0.4)
                                          : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                                      width: isUnread ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (isUnread) ...[
                                        Container(
                                          width: 4,
                                          height: 40,
                                          margin: const EdgeInsets.only(right: 10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ],
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isUnread
                                              ? AppTheme.primary.withValues(alpha: 0.15)
                                              : (isDark ? AppTheme.bgDark : AppTheme.surfaceContainerLow),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          icon,
                                          color: isUnread
                                              ? AppTheme.primaryDark
                                              : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              body,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              timeStr,
                                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
