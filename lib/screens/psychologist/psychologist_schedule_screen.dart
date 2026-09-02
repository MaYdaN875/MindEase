import 'package:flutter/material.dart';
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

class _PsychologistScheduleScreenState extends State<PsychologistScheduleScreen> {
  String _viewMode = 'Semana'; // 'Día', 'Semana', 'Mes'
  int _selectedDayIndex = 1; // LUN 16

  final List<Map<String, String>> _weekDays = [
    {'day': 'DOM', 'num': '15'},
    {'day': 'LUN', 'num': '16'},
    {'day': 'MAR', 'num': '17'},
    {'day': 'MIE', 'num': '18'},
    {'day': 'JUE', 'num': '19'},
    {'day': 'VIE', 'num': '20'},
    {'day': 'SAB', 'num': '21'},
  ];

  void _showAddSlotDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        String startHour = '09:00 AM';
        String endHour = '14:00 PM';
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.more_time, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Añadir Disponibilidad'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Configura tu horario disponible para citas:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: startHour,
                decoration: InputDecoration(
                  labelText: 'Hora de inicio',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: ['08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM']
                    .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                    .toList(),
                onChanged: (v) => startHour = v!,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: endHour,
                decoration: InputDecoration(
                  labelText: 'Hora de término',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: ['01:00 PM', '02:00 PM', '04:00 PM', '06:00 PM', '08:00 PM']
                    .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                    .toList(),
                onChanged: (v) => endHour = v!,
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
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bloque de disponibilidad guardado correctamente.'),
                    backgroundColor: AppTheme.primaryDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.textDark,
              ),
              child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSlotDialog,
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textDark,
        tooltip: 'Añadir horario disponible',
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & View Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Octubre 2023',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : AppTheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: ['Día', 'Semana', 'Mes'].map((mode) {
                        final isSelected = _viewMode == mode;
                        return GestureDetector(
                          onTap: () => setState(() => _viewMode = mode),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? AppTheme.borderDark : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              mode,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? AppTheme.primary
                                    : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Week Navigation Slider
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_weekDays.length, (index) {
                    final item = _weekDays[index];
                    final isSelected = _selectedDayIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDayIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(color: AppTheme.primary, width: 1.5)
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              item['day']!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppTheme.primary
                                    : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['num']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.primary
                                    : (isDark ? AppTheme.textLight : AppTheme.textDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // Settings Quick Access Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duración de sesión',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.textLight : AppTheme.textDark,
                          ),
                        ),
                        Text(
                          '50 min • 10 min margen',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: AppTheme.primary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ajustes de duración y margen de sesión'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Calendar Timeline
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    // Timeline Item: Available Block
                    _buildTimelineSlot(
                      hour: '09:00',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          border: const Border(left: BorderSide(color: AppTheme.primary, width: 4)),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Disponible',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            Text(
                              '09:00 - 14:00',
                              style: TextStyle(fontSize: 11, color: AppTheme.primaryDark),
                            ),
                          ],
                        ),
                      ),
                      isDark: isDark,
                    ),
                    Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),

                    // Timeline Item: Occupied Block
                    _buildTimelineSlot(
                      hour: '10:30',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.secondary.withValues(alpha: 0.25)
                              : AppTheme.secondaryContainer,
                          border: const Border(left: BorderSide(color: AppTheme.secondary, width: 4)),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Consulta Confirmada',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onSecondaryContainer,
                                  ),
                                ),
                                Text(
                                  'Sarah J. • 50 min',
                                  style: TextStyle(fontSize: 11, color: AppTheme.secondary),
                                ),
                              ],
                            ),
                            Icon(Icons.videocam, size: 18, color: AppTheme.onSecondaryContainer),
                          ],
                        ),
                      ),
                      isDark: isDark,
                    ),
                    Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),

                    // Timeline Item: Empty Space with config
                    _buildTimelineSlot(
                      hour: '11:30',
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _showAddSlotDialog,
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('Configurar horario', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                      isDark: isDark,
                    ),
                    Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),

                    // Timeline Item: Afternoon Available Block
                    _buildTimelineSlot(
                      hour: '16:00',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          border: const Border(left: BorderSide(color: AppTheme.primary, width: 4)),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Disponible',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            Text(
                              '16:00 - 20:00',
                              style: TextStyle(fontSize: 11, color: AppTheme.primaryDark),
                            ),
                          ],
                        ),
                      ),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineSlot({
    required String hour,
    required Widget child,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            child: Text(
              hour,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
