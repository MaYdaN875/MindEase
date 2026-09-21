import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../psychologist_profile_form_screen.dart';
import '../support/help_support_screen.dart';


class PsychologistProfileScreen extends StatefulWidget {
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenSettings;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final Map<String, dynamic>? userProfile;

  const PsychologistProfileScreen({
    super.key,
    required this.onOpenNotifications,
    required this.onOpenSettings,
    required this.onLogout,
    required this.onToggleTheme,
    required this.isDarkMode,
    this.userProfile,
  });

  @override
  State<PsychologistProfileScreen> createState() => _PsychologistProfileScreenState();
}

class _PsychologistProfileScreenState extends State<PsychologistProfileScreen> {
  final AuthService _authService = AuthService();
  bool _autoConfirm = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _autoConfirm = widget.userProfile?['psychologistProfile']?['autoConfirmAppointments'] == true;
  }

  Future<void> _toggleAutoConfirm(bool value) async {
    setState(() {
      _autoConfirm = value;
      _isUpdating = true;
    });

    final res = await _authService.updatePsychologistProfile({'autoConfirmAppointments': value});
    if (mounted) {
      setState(() {
        _isUpdating = false;
        if (res['success'] != true) {
          _autoConfirm = !value;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Confirmación automática activada: Las citas se confirmarán de inmediato.'
                : 'Confirmación manual activada: Las citas requerirán tu aprobación.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: value ? AppTheme.primaryDark : Colors.grey.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doctorName = widget.userProfile?['name'] ?? 'Dr. Alejandro Torres';
    final avatarUrl = widget.userProfile?['avatarUrl'] ??
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBVs8tIfuOwuiiM-Jm-RNLgqdr8y0XfiRuGHeVo2ftxGEBO3ELLyb399uhfqzzNCY6cFQbCw6_XflUCBZQxmXV9XUuQuFlNJRv4G930tsKTwqHY9YhTaBxMCgjwlpZnX0vn3JxLr0W8eRACOBZZCnyM9qyHdeZ4hrKp38VF7ezCzcfqITwxmviFLDSnDMDfaXPu_cMZ7EQYa5r1TDfPPLjGUN8wcewpo7vnMM-EuiyfrvReGwfyR-AWmw';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil Profesional'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: widget.onToggleTheme,
            tooltip: 'Cambiar tema',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: widget.onOpenSettings,
            tooltip: 'Configuración',
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
              // Profile Header Area
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 4),
                            image: DecorationImage(
                              image: NetworkImage(avatarUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? AppTheme.cardDark : Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.verified, color: AppTheme.textDark, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      doctorName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.textLight : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user, size: 16, color: AppTheme.primary),
                        SizedBox(width: 4),
                        Text(
                          'Psicólogo verificado',
                          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sobre mí
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_outline, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Sobre mí', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Especialista en terapia cognitivo-conductual con más de 10 años de experiencia. Mi enfoque se centra en proporcionar un espacio seguro y empático para ayudarte a gestionar la ansiedad, la depresión y las transiciones vitales.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Especialidades
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.psychology_outlined, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Especialidades', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Ansiedad', 'Depresión', 'Gestión del estrés', 'Terapia de pareja'].map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryDark),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Trayectoria
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.school_outlined, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Trayectoria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTrajectoryItem(
                      icon: Icons.history_edu,
                      title: 'Doctorado en Psicología Clínica',
                      subtitle: 'Universidad Nacional • 2012 - 2016',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildTrajectoryItem(
                      icon: Icons.work_outline,
                      title: 'Psicólogo Clínico Senior',
                      subtitle: 'Hospital Central • 2017 - Presente',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Detalles de Consulta
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Detalles de Consulta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.bgDark.withValues(alpha: 0.5) : AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                              border: const Border(left: BorderSide(color: AppTheme.primary, width: 3)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('MODALIDAD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.videocam, size: 16, color: AppTheme.primary),
                                    SizedBox(width: 4),
                                    Text('Online', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.bgDark.withValues(alpha: 0.5) : AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                              border: const Border(left: BorderSide(color: AppTheme.primary, width: 3)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PRECIO / SESIÓN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.payments_outlined, size: 16, color: AppTheme.primary),
                                    SizedBox(width: 4),
                                    Text('\$60 / 50m', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Preferencia de Aprobación de Citas
              Material(
                color: isDark ? AppTheme.cardDark : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Confirmación automática',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                    ),
                  ),
                  subtitle: Text(
                    _autoConfirm
                        ? 'Las citas se confirman al instante sin requerir tu aprobación previa.'
                        : 'Las citas entran como solicitudes pendientes y tú decides aceptarlas.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                  value: _autoConfirm,
                  onChanged: _isUpdating ? null : _toggleAutoConfirm,
                  activeThumbColor: AppTheme.primary,
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_mode, color: AppTheme.primary, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botón Editar Perfil
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PsychologistProfileFormScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Editar perfil profesional', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.textDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              // Centro de Ayuda y Soporte
              Material(
                color: isDark ? AppTheme.cardDark : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: ListTile(
                  leading: const Icon(Icons.help_outline, color: AppTheme.primary),
                  title: const Text('Centro de Ayuda y Soporte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Tickets de soporte, disputas y asistencia técnica', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Cerrar sesión
              TextButton.icon(

                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout, color: AppTheme.error),
                label: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrajectoryItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
