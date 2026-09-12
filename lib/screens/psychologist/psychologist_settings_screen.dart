import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'psychologist_earnings_screen.dart';
import 'psychologist_notifications_screen.dart';
import '../psychologist_profile_form_screen.dart';

class PsychologistSettingsScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const PsychologistSettingsScreen({super.key, required this.onLogout});

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Centro de Ayuda'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Preguntas Frecuentes para Profesionales:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              _buildFaqItem('¿Cómo se programan los pagos?', 'Los ingresos se transfieren quincenalmente a tu cuenta registrada.'),
              const SizedBox(height: 8),
              _buildFaqItem('¿Cómo funciona la sala de consulta?', 'Nuestras videollamadas cuentan con cifrado de extremo a extremo.'),
              const SizedBox(height: 8),
              _buildFaqItem('¿Puedo modificar mis tarifas?', 'Sí, desde la sección de edición de perfil profesional.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildFaqItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        Text(answer, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  void _showSupportDialog(BuildContext context) {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.support_agent, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Soporte Técnico'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Tienes alguna duda o incidencia con tu cuenta? Escríbenos y te responderemos en breve.'),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Descripción del problema',
                  hintText: 'Explica lo ocurrido...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
                    content: Text('Mensaje de soporte enviado. Nos comunicaremos contigo vía correo.'),
                    backgroundColor: AppTheme.primaryDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.textDark,
              ),
              child: const Text('Enviar Mensaje', style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: const Text('Configuración Profesional'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              // Settings Container
              Material(
                color: isDark ? AppTheme.cardDark : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.person_outline,
                      title: 'Datos personales',
                      subtitle: 'Nombre, correo, teléfono',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PsychologistProfileFormScreen()),
                        );
                      },
                      isDark: isDark,
                    ),
                    Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    _buildSettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Seguridad y Privacidad',
                      subtitle: 'Contraseña, 2FA, sesiones',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ajustes de seguridad y contraseña'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      isDark: isDark,
                    ),
                    Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    _buildSettingsTile(
                      icon: Icons.badge_outlined,
                      title: 'Información profesional',
                      subtitle: 'Diplomas, credenciales, especialidades',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PsychologistProfileFormScreen()),
                        );
                      },
                      isDark: isDark,
                    ),
                    Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    _buildSettingsTile(
                      icon: Icons.account_balance_outlined,
                      title: 'Métodos de pago y finanzas',
                      subtitle: 'Cuenta bancaria, facturación, retiros',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PsychologistEarningsScreen()),
                        );
                      },
                      isDark: isDark,
                    ),
                    Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    _buildSettingsTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Notificaciones',
                      subtitle: 'Ajustes de alertas y correos',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PsychologistNotificationsScreen()),
                        );
                      },
                      isDark: isDark,
                    ),
                    Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    _buildSettingsTile(
                      icon: Icons.help_outline,
                      title: 'Ayuda',
                      subtitle: 'Centro de ayuda, preguntas frecuentes',
                      onTap: () => _showHelpDialog(context),
                      isDark: isDark,
                    ),
                    Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    _buildSettingsTile(
                      icon: Icons.support_agent,
                      title: 'Soporte',
                      subtitle: 'Contacto y atención técnica',
                      onTap: () => _showSupportDialog(context),
                      isDark: isDark,
                    ),
                    Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    _buildSettingsTile(
                      icon: Icons.description_outlined,
                      title: 'Términos y Condiciones',
                      subtitle: 'Legal y políticas de la plataforma',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Términos de servicio SereneMind'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Logout button
              Material(
                color: isDark ? AppTheme.error.withValues(alpha: 0.15) : AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  leading: const Icon(Icons.logout, color: AppTheme.error),
                  title: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                  onTap: onLogout,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryDark, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppTheme.textLight : AppTheme.textDark)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
