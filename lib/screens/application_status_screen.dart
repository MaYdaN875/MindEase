import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'psychologist_profile_form_screen.dart';

class ApplicationStatusScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ApplicationStatusScreen({super.key, required this.onLogout});

  @override
  State<ApplicationStatusScreen> createState() => _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String _status = 'PENDIENTE_REVISION';
  List<dynamic> _history = [];
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final profileRes = await AuthService().getProfile();
    if (profileRes['success'] == true) {
      _userProfile = profileRes['user'];
    }

    final result = await AuthService().getPsychologistReviewStatus();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        setState(() {
          _status = result['data']['currentStatus'] ?? 'PENDIENTE_REVISION';
          _history = result['data']['history'] ?? [];
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Error al obtener estado';
        });
      }
    }
  }

  void _showSupportDialog() {
    final msgController = TextEditingController();
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
              Text('Contactar Soporte'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Escribe tu consulta y un agente revisará tu cuenta.'),
              const SizedBox(height: 12),
              TextField(
                controller: msgController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mensaje',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                    content: Text('Mensaje de soporte enviado exitosamente.'),
                    backgroundColor: AppTheme.primaryDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.textDark,
              ),
              child: const Text('Enviar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avatarUrl = _userProfile?['avatarUrl'] ??
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBrEb52c2ga1R7fwtmJ7uJd9yS9PH5Tsap_JfEj0dsur64-OC1T6ta1TEt4WQuWm3TNdpsmuNJ_ZoyGZwKa0cNPu705cOQGewftc1OFpixgmyUaGR3M6EJj5ASx0yuqY8rdXzqvNy1K2A7aZ0tbleng9LDVkLrP5nay5-8b4eds3GUUnzIiuko1EaMsvpavG31f_M_OY2j8pNSwaV_35EgwrMx7x2uiZtyz7o988s8GSiIjRvvQe0e7jQ';

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estados de Perfil'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary, width: 1.5),
              image: DecorationImage(
                image: NetworkImage(avatarUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.error),
            onPressed: widget.onLogout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchStatus,
          color: AppTheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.onErrorContainer, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Text(
                  'Estado Actual de Verificación',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 12),

                // Card 1: Verificación en Proceso (Pending)
                _buildVerificationCard(
                  borderColor: AppTheme.tertiaryFixedDim,
                  iconBg: AppTheme.tertiaryFixedDim.withValues(alpha: 0.15),
                  iconColor: AppTheme.tertiaryFixedDim,
                  icon: Icons.schedule,
                  title: 'Verificación en Proceso',
                  description:
                      'Tu perfil está siendo revisado por nuestro equipo de validación clínica. Te notificaremos una vez que la verificación esté completa.',
                  actionText: 'Ver detalles de verificación',
                  actionIcon: Icons.chevron_right,
                  isActive: _status == 'PENDIENTE_REVISION' || _status == 'EN_REVISION',
                  isDark: isDark,
                  onAction: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tu expediente está en la cola de revisión.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Card 2: Acción Requerida (Requires changes)
                _buildVerificationCard(
                  borderColor: AppTheme.primary,
                  iconBg: AppTheme.primary.withValues(alpha: 0.15),
                  iconColor: AppTheme.primary,
                  icon: Icons.error_outline,
                  title: 'Acción Requerida',
                  description:
                      'Necesitamos información adicional o corregir documentos para completar tu verificación profesional. Por favor, revisa los documentos solicitados.',
                  actionText: 'Subir documentos',
                  actionIcon: Icons.upload_file,
                  isActive: _status == 'REQUIERE_CAMBIOS' || _status == 'REGISTRO_INCOMPLETO',
                  isDark: isDark,
                  onAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PsychologistProfileFormScreen(
                          onFormSubmitted: _fetchStatus,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Card 3: Cuenta Suspendida (Suspended)
                _buildVerificationCard(
                  borderColor: AppTheme.error,
                  iconBg: AppTheme.error.withValues(alpha: 0.15),
                  iconColor: AppTheme.error,
                  icon: Icons.block,
                  title: 'Cuenta Suspendida',
                  description:
                      'Tu cuenta profesional se encuentra temporalmente suspendida. Contacta a soporte para más información y resolución del estado.',
                  actionText: 'Contactar soporte',
                  actionIcon: Icons.support_agent,
                  isActive: _status == 'SUSPENDIDO',
                  isDark: isDark,
                  onAction: _showSupportDialog,
                ),
                const SizedBox(height: 24),

                // Historial Timeline Section
                if (_history.isNotEmpty) ...[
                  Text(
                    'Historial de Auditoría',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._history.map((log) {
                    final toStatus = log['toStatus'] ?? 'ESTADO';
                    final dateStr = log['changedAt'] != null
                        ? DateTime.parse(log['changedAt']).toLocal().toString().substring(0, 16)
                        : '';
                    final comment = log['comment'] ?? 'Sin observaciones';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(toStatus, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(comment, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight)),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationCard({
    required Color borderColor,
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String description,
    required String actionText,
    required IconData actionIcon,
    required bool isActive,
    required bool isDark,
    required VoidCallback onAction,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? borderColor : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isActive) ...[
              Container(
                width: 4,
                height: 44,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.textLight : AppTheme.textDark,
                          ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: borderColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ACTUAL',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: borderColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: onAction,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            actionText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: borderColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(actionIcon, size: 16, color: borderColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
