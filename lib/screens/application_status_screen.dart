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
  String _status = 'REGISTRO_INCOMPLETO';
  List<dynamic> _history = [];

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

    final result = await AuthService().getPsychologistReviewStatus();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        setState(() {
          _status = result['data']['currentStatus'] ?? 'REGISTRO_INCOMPLETO';
          _history = result['data']['history'] ?? [];
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Error al obtener estado';
        });
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de Solicitud'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _handleLogout(context),
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Dynamic Status Card
                _buildStatusCard(isDark),
                const SizedBox(height: 28),

                // History Timeline Section
                const Text(
                  'Historial de Solicitudes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _history.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'No hay registros en el historial todavía.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _buildHistoryTimeline(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    Color cardColor;
    Color textColor;
    String statusTitle;
    String statusDesc;
    IconData icon;
    bool showActionBtn = false;

    switch (_status) {
      case 'VERIFICADO':
        cardColor = Colors.green;
        textColor = Colors.green;
        statusTitle = 'Perfil Verificado';
        statusDesc = '¡Felicidades! Tu perfil profesional ha sido validado correctamente. Ya apareces en el directorio y puedes agendar consultas.';
        icon = Icons.verified_user_outlined;
        break;
      case 'REQUIERE_CAMBIOS':
        cardColor = Colors.amber;
        textColor = Colors.amber;
        statusTitle = 'Correcciones Requeridas';
        statusDesc = 'El administrador ha revisado tu perfil y solicitó cambios. Por favor revisa los comentarios del historial abajo y vuelve a subir los documentos.';
        icon = Icons.edit_attributes_outlined;
        showActionBtn = true;
        break;
      case 'RECHAZADO':
        cardColor = Colors.redAccent;
        textColor = Colors.redAccent;
        statusTitle = 'Solicitud Rechazada';
        statusDesc = 'Lamentamos informarte que tu solicitud fue rechazada debido a inconsistencias en tus documentos de cédula o título.';
        icon = Icons.cancel_outlined;
        break;
      case 'PENDIENTE_REVISION':
      case 'EN_REVISION':
        cardColor = Colors.amber;
        textColor = Colors.amber;
        statusTitle = 'En Revisión';
        statusDesc = 'Tu expediente profesional se encuentra en proceso de validación. La revisión manual toma habitualmente entre 24 y 48 horas hábiles.';
        icon = Icons.hourglass_empty;
        break;
      case 'SUSPENDIDO':
        cardColor = Colors.red;
        textColor = Colors.red;
        statusTitle = 'Perfil Suspendido';
        statusDesc = 'Tu cuenta profesional se encuentra temporalmente suspendida debido a políticas del servicio.';
        icon = Icons.block;
        break;
      case 'REGISTRO_INCOMPLETO':
      default:
        cardColor = Colors.grey;
        textColor = Colors.grey;
        statusTitle = 'Registro Incompleto';
        statusDesc = 'Aún no completas tu captura de información y carga de documentos de identidad.';
        icon = Icons.edit_note_outlined;
        showActionBtn = true;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            statusTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            statusDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (showActionBtn) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PsychologistProfileFormScreen(
                      onFormSubmitted: _fetchStatus,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.bgDark,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _status == 'REGISTRO_INCOMPLETO' ? 'Completar Perfil' : 'Corregir Documentos',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTimeline(bool isDark) {
    return Column(
      children: _history.map((log) {
        final toStatus = log['toStatus'];
        final dateStr = DateTime.parse(log['changedAt']).toLocal().toString().substring(0, 16);
        final comment = log['comment'] ?? 'Sin observaciones escritas';
        final revisorName = log['changedBy']?['name'] ?? 'Sistema';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4, right: 12),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppTheme.borderSubtleDark : AppTheme.borderSubtleLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            toStatus,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        comment,
                        style: const TextStyle(fontSize: 12, height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Revisado por: $revisorName',
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
