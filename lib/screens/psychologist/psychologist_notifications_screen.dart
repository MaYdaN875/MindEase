import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PsychologistNotificationsScreen extends StatefulWidget {
  const PsychologistNotificationsScreen({super.key});

  @override
  State<PsychologistNotificationsScreen> createState() => _PsychologistNotificationsScreenState();
}

class _PsychologistNotificationsScreenState extends State<PsychologistNotificationsScreen> {
  String _selectedFilter = 'Todos';
  final List<String> _filters = ['Todos', 'Consultas', 'Community', 'Sistema', 'Administración'];

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Nueva consulta de Juan P.',
      'body': 'Juan P. ha solicitado una nueva consulta para el día 15 de Octubre a las 10:00 AM.',
      'time': 'Hace 5 min',
      'category': 'Consultas',
      'icon': Icons.person,
      'isUnread': true,
    },
    {
      'title': 'Recordatorio de sesión en 15 min',
      'body': 'Tu sesión de terapia online con María G. está por comenzar.',
      'time': 'Hace 10 min',
      'category': 'Sistema',
      'icon': Icons.alarm,
      'isUnread': true,
    },
    {
      'title': 'Tu publicación ha sido aprobada',
      'body': 'El artículo "Manejo de la ansiedad en entornos laborales" ya está visible en la comunidad.',
      'time': 'Ayer, 14:30',
      'category': 'Community',
      'icon': Icons.forum,
      'isUnread': false,
    },
    {
      'title': 'Resumen de facturación mensual disponible',
      'body': 'Ya puedes descargar el reporte de facturación correspondiente al mes de Septiembre.',
      'time': '01 Oct, 09:00',
      'category': 'Administración',
      'icon': Icons.description,
      'isUnread': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredList = _selectedFilter == 'Todos'
        ? _notifications
        : _notifications.where((n) => n['category'] == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  n['isUnread'] = false;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Todas las notificaciones marcadas como leídas.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Marcar leídas', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
          ),
        ],
      ),
      body: SafeArea(
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
              child: filteredList.isEmpty
                  ? Center(
                      child: Text(
                        'No hay notificaciones en esta categoría',
                        style: TextStyle(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        final isUnread = item['isUnread'] as bool;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border(
                              left: BorderSide(
                                color: isUnread ? AppTheme.primary : Colors.transparent,
                                width: 4,
                              ),
                              top: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                              right: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                              bottom: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                  item['icon'] as IconData,
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
                                      item['title'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                        color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['body'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item['time'] as String,
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
