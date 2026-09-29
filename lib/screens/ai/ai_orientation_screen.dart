import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/ai_orientation.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import 'ai_recommendations_screen.dart';
import '../../widgets/ai_crisis_contact.dart';

class AIOrientationScreen extends StatefulWidget {
  const AIOrientationScreen({super.key});

  @override
  State<AIOrientationScreen> createState() => _AIOrientationScreenState();
}

class _AIOrientationScreenState extends State<AIOrientationScreen> {
  final AIService _aiService = AIService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSending = false;
  AIOrientationSession? _currentSession;
  List<CrisisResource> _crisisResources = [];
  String? _errorMessage;
  String? _consentVersion;
  String _consentNotice = '';
  Map<String, dynamic>? _quota;
  String? _sendError;
  String? _nonRetryableText;
  bool get _sameNonRetryableText =>
      _nonRetryableText != null &&
      _messageController.text.trim() == _nonRetryableText;
  DateTime? _retryAt;
  Timer? _retryTimer;
  int get _retrySeconds => _retryAt == null
      ? 0
      : (_retryAt!.difference(DateTime.now()).inMilliseconds / 1000)
            .ceil()
            .clamp(0, 86400);
  bool get _needsHumanSupport =>
      _currentSession?.isEscalated == true ||
      _currentSession?.riskLevel == 'HIGH' ||
      _currentSession?.riskLevel == 'EMERGENCY';

  @override
  void initState() {
    super.initState();
    _initializeFlow();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeFlow() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final consentRes = await _aiService.getConsentStatus();
    if (!mounted) return;

    if (consentRes['success'] != true) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'No se pudo cargar el aviso de privacidad. Intenta de nuevo.';
      });
      return;
    }
    _consentVersion = consentRes['version']?.toString();
    _consentNotice = consentRes['notice']?.toString() ?? '';
    if (consentRes['hasConsent'] == true) {
      await _loadOrCreateSession();
    } else {
      setState(() {
        _isLoading = false;
      });
      // Mostrar sheet de consentimiento
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConsentDialog();
      });
    }
  }

  Future<void> _loadOrCreateSession() async {
    final sessionRes = await _aiService.createOrGetSession();
    if (!mounted) return;

    if (sessionRes['success'] == true && sessionRes['session'] != null) {
      final session = AIOrientationSession.fromJson(
        sessionRes['session'] as Map<String, dynamic>,
      );
      setState(() {
        _currentSession = session;
        _quota = (sessionRes['session']['quota'] as Map?)
            ?.cast<String, dynamic>();
        final draft = _aiService.pendingDraft(session.id);
        if (draft != null && _messageController.text.isEmpty) {
          _messageController.text = draft;
        }
        _crisisResources =
            ((sessionRes['session']['crisisResources'] as List?) ?? [])
                .map(
                  (r) => CrisisResource.fromJson(
                    Map<String, dynamic>.from(r as Map),
                  ),
                )
                .toList();
        _isLoading = false;
      });
      _scrollToBottom();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage =
            sessionRes['message'] ?? 'No se pudo iniciar la orientación.';
      });
    }
  }

  void _showConsentDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 24.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Orientación Inicial con IA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Antes de comenzar, por favor lee las siguientes condiciones de uso:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                _buildConsentItem(
                  'La IA NO es un psicólogo ni un terapeuta clínico.',
                ),
                _buildConsentItem(
                  'Esta herramienta NO emite diagnósticos médicos ni psicológicos.',
                ),
                _buildConsentItem(
                  'No sustituye una consulta, evaluación o tratamiento profesional.',
                ),
                _buildConsentItem(
                  'Su función es únicamente orientarte y ayudarte a encontrar áreas y especialistas idóneos en MindEase.',
                ),
                _buildConsentItem(
                  'Puedes abandonar esta conversación en cualquier momento.',
                ),
                Text(
                  _consentNotice,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _consentVersion == null || _consentNotice.isEmpty
                            ? null
                            : () async {
                                Navigator.of(ctx).pop();
                                setState(() => _isLoading = true);
                                final res = await _aiService.registerConsent(
                                  _consentVersion!,
                                );
                                if (res['success'] == true && mounted) {
                                  await _loadOrCreateSession();
                                } else if (mounted) {
                                  setState(() {
                                    _isLoading = false;
                                    _errorMessage =
                                        res['message'] ??
                                        'Error al registrar consentimiento.';
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.textDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Soy mayor de 18 y acepto'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConsentItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppTheme.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty ||
        _isSending ||
        _currentSession == null ||
        _needsHumanSupport ||
        _sameNonRetryableText ||
        _retrySeconds > 0) {
      return;
    }

    setState(() {
      _isSending = true;
      _sendError = null;
    });

    final res = await _aiService.sendMessage(_currentSession!.id, text);
    if (!mounted) return;

    setState(() {
      _isSending = false;
    });

    if (res['success'] == true && res['data'] != null) {
      _nonRetryableText = null;
      final data = res['data'];
      final userMsg = AIMessage.fromJson(
        data['userMessage'] as Map<String, dynamic>,
      );
      final assistantMsg = AIMessage.fromJson(
        data['assistantMessage'] as Map<String, dynamic>,
      );

      final byId = {
        for (final m in _currentSession!.messages) m.id: m,
        userMsg.id: userMsg,
        assistantMsg.id: assistantMsg,
      };
      final updatedMessages = byId.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final isComplete = data['isComplete'] == true;
      final riskLevel = data['riskLevel']?.toString() ?? 'LOW';

      // Si se devuelven recursos de crisis
      List<CrisisResource> crisis = [];
      if (data['crisisResources'] != null) {
        final rawCrisis = data['crisisResources'] as List<dynamic>;
        crisis = rawCrisis
            .map((c) => CrisisResource.fromJson(c as Map<String, dynamic>))
            .toList();
      }

      setState(() {
        if (_messageController.text.trim() == text) _messageController.clear();
        _quota = (data['quota'] as Map?)?.cast<String, dynamic>() ?? _quota;
        _currentSession = AIOrientationSession(
          id: _currentSession!.id,
          status:
              data['status']?.toString() ??
              (isComplete ? 'COMPLETED' : _currentSession!.status),
          riskLevel: riskLevel,
          summary: _currentSession!.summary,
          startedAt: _currentSession!.startedAt,
          completedAt: data['status'] == 'COMPLETED' ? DateTime.now() : null,
          messages: updatedMessages,
        );
        _crisisResources = crisis;
      });

      _scrollToBottom();

      // Si se completó de forma natural por la IA, dar la opción de ver recomendaciones
      if (isComplete && riskLevel != 'EMERGENCY' && riskLevel != 'HIGH') {
        _showCompletionBanner();
      }
    } else {
      final retry = (res['retryAfterSeconds'] as num?)?.toInt() ?? 0;
      _retryTimer?.cancel();
      setState(() {
        _nonRetryableText = res['retryable'] == false ? text : null;
        _sendError =
            res['message']?.toString() ??
            'No se pudo enviar. Tu texto se conserva.';
        _retryAt = retry > 0
            ? DateTime.now().add(Duration(seconds: retry))
            : null;
      });
      if (retry > 0) {
        _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted || _retrySeconds == 0) timer.cancel();
          if (mounted) setState(() {});
        });
      }
      if (res['code'] == 'AI_SESSION_CLOSED' ||
          res['code'] == 'AI_SESSION_LIMIT') {
        final refreshed = await _aiService.getSessionById(_currentSession!.id);
        if (!mounted) return;
        if (refreshed['success'] == true) {
          final raw = refreshed['session'] as Map<String, dynamic>;
          setState(() {
            _currentSession = AIOrientationSession.fromJson(raw);
            _quota = (raw['quota'] as Map?)?.cast<String, dynamic>();
            _crisisResources = ((raw['crisisResources'] as List?) ?? [])
                .map(
                  (r) => CrisisResource.fromJson(
                    Map<String, dynamic>.from(r as Map),
                  ),
                )
                .toList();
          });
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Error al enviar mensaje.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleCompleteSession() async {
    if (_currentSession == null || _needsHumanSupport || _isSending) return;

    setState(() => _isSending = true);
    final res = await _aiService.completeSession(_currentSession!.id);
    if (!mounted) return;

    setState(() => _isSending = false);

    if (res['success'] == true && res['recommendations'] != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AIRecommendationsScreen(
            recommendationsData: res['recommendations'] as Map<String, dynamic>,
            onFinish: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Error al completar orientación.'),
        ),
      );
    }
  }

  void _showCompletionBanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '¡Orientación lista! Puedes ver tus profesionales recomendados.',
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Ver resultados',
          textColor: AppTheme.primary,
          onPressed: _handleCompleteSession,
        ),
      ),
    );
  }

  Future<void> _deleteHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar historial de IA'),
        content: const Text(
          'Se eliminarán tus conversaciones y recomendaciones de IA en MindEase y se retirará tu consentimiento. No se borrarán citas ni chats con profesionales. Esta acción no se puede deshacer y no elimina copias del proveedor o respaldos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar y retirar consentimiento'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSending = true);
    final deleted = await _aiService.deleteHistoryAndConsent();
    if (!mounted) return;
    setState(() => _isSending = false);
    if (deleted) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar. Intenta de nuevo.')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Orientación con IA'),
        actions: [
          IconButton(
            onPressed: _isSending ? null : _deleteHistory,
            tooltip: 'Eliminar historial y retirar consentimiento',
            icon: const Icon(Icons.delete_outline),
          ),
          if (_currentSession != null && !_needsHumanSupport)
            TextButton(
              onPressed: _isSending ? null : _handleCompleteSession,
              child: const Text(
                'Finalizar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Aviso persistente: Triaje no diagnóstico
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Orientación inicial no diagnóstica. No sustituye evaluación clínica.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Alerta si el estado es crítico o de emergencia
            if (_crisisResources.isNotEmpty ||
                _currentSession?.isEscalated == true)
              _buildCrisisAlert(isDark),

            // Contenido principal
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _initializeFlow,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildMessageList(isDark),
            ),

            // Indicador de escritura
            if (_isSending)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Esperando respuesta de la IA…',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

            // Campo de texto de envío
            if (_quota != null &&
                !_needsHumanSupport &&
                _currentSession?.status == 'ACTIVE' &&
                (_quota!['remaining'] as num) <= 3)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  (_quota!['remaining'] as num) == 0
                      ? 'Alcanzaste el límite de mensajes respondidos. Pulsa Finalizar para ver tus resultados.'
                      : 'Te quedan ${_quota!['remaining']} mensajes respondidos de ${_quota!['limit']}. Puedes finalizar cuando quieras.',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (_sendError != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_sendError!, style: const TextStyle(fontSize: 12)),
                    if (_currentSession?.status == 'ACTIVE' &&
                        !_needsHumanSupport &&
                        !_sameNonRetryableText)
                      TextButton(
                        onPressed: _isSending || _retrySeconds > 0
                            ? null
                            : _handleSendMessage,
                        child: Text(
                          _retrySeconds > 0
                              ? 'Reintentar en ${_retrySeconds}s'
                              : 'Reintentar envío',
                        ),
                      ),
                  ],
                ),
              ),
            if (_currentSession?.status == 'ACTIVE' && !_needsHumanSupport)
              _buildInputArea(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCrisisAlert(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Líneas de Ayuda Inmediata',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Si estás viviendo una situación de riesgo, busca apoyo humano. Estos son recursos de México. Al pulsar un teléfono se abrirá el marcador; tú decides si realizas la llamada.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          ..._crisisResources.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: AICrisisContact(name: r.name, phone: r.phone),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    final messages = _currentSession?.messages ?? [];

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return _buildMessageBubble(msg, isDark);
      },
    );
  }

  Widget _buildMessageBubble(AIMessage msg, bool isDark) {
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primary
              : (isDark ? AppTheme.cardDark : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              msg.content,
              style: TextStyle(
                fontSize: 14,
                color: isUser
                    ? AppTheme.textDark
                    : (isDark ? AppTheme.textLight : Colors.black87),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              // New text may contain a safety signal: keep the local safety path available.
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              maxLength: 2000,
              enabled: !_isSending,
              decoration: InputDecoration(
                hintText: 'Cuéntame qué estás sintiendo...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send_rounded,
              color: _isSending ? Colors.grey : AppTheme.primary,
            ),
            onPressed: _isSending || _retrySeconds > 0 || _sameNonRetryableText
                ? null
                : _handleSendMessage,
          ),
        ],
      ),
    );
  }
}
