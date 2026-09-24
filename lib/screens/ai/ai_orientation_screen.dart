import 'package:flutter/material.dart';
import '../../models/ai_orientation.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import 'ai_recommendations_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeFlow();
  }

  @override
  void dispose() {
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
        _isLoading = false;
      });
      _scrollToBottom();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = sessionRes['message'] ?? 'No se pudo iniciar la orientación.';
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
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
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
                    child: const Icon(Icons.info_outline, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Orientación Inicial con IA',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Antes de comenzar, por favor lee las siguientes condiciones de uso:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildConsentItem('La IA NO es un psicólogo ni un terapeuta clínico.'),
              _buildConsentItem('Esta herramienta NO emite diagnósticos médicos ni psicológicos.'),
              _buildConsentItem('No sustituye una consulta, evaluación o tratamiento profesional.'),
              _buildConsentItem('Su función es únicamente orientarte y ayudarte a encontrar áreas y especialistas idóneos en MindEase.'),
              _buildConsentItem('Puedes abandonar esta conversación en cualquier momento.'),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        setState(() => _isLoading = true);
                        final res = await _aiService.registerConsent();
                        if (res['success'] == true && mounted) {
                          await _loadOrCreateSession();
                        } else if (mounted) {
                          setState(() {
                            _isLoading = false;
                            _errorMessage = res['message'] ?? 'Error al registrar consentimiento.';
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.textDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Acepto y continúo'),
                    ),
                  ),
                ],
              ),
            ],
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
          const Icon(Icons.check_circle_outline, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1.3)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending || _currentSession == null) return;

    _messageController.clear();
    setState(() {
      _isSending = true;
    });

    final res = await _aiService.sendMessage(_currentSession!.id, text);
    if (!mounted) return;

    setState(() {
      _isSending = false;
    });

    if (res['success'] == true && res['data'] != null) {
      final data = res['data'];
      final userMsg = AIMessage.fromJson(data['userMessage'] as Map<String, dynamic>);
      final assistantMsg = AIMessage.fromJson(data['assistantMessage'] as Map<String, dynamic>);

      final updatedMessages = List<AIMessage>.from(_currentSession!.messages)
        ..add(userMsg)
        ..add(assistantMsg);

      final isComplete = data['isComplete'] == true;
      final riskLevel = data['riskLevel']?.toString() ?? 'LOW';

      // Si se devuelven recursos de crisis
      List<CrisisResource> crisis = [];
      if (data['crisisResources'] != null) {
        final rawCrisis = data['crisisResources'] as List<dynamic>;
        crisis = rawCrisis.map((c) => CrisisResource.fromJson(c as Map<String, dynamic>)).toList();
      }

      setState(() {
        _currentSession = AIOrientationSession(
          id: _currentSession!.id,
          status: isComplete ? 'COMPLETED' : _currentSession!.status,
          riskLevel: riskLevel,
          summary: _currentSession!.summary,
          startedAt: _currentSession!.startedAt,
          completedAt: isComplete ? DateTime.now() : _currentSession!.completedAt,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Error al enviar mensaje.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleCompleteSession() async {
    if (_currentSession == null) return;

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
        SnackBar(content: Text(res['message'] ?? 'Error al completar orientación.')),
      );
    }
  }

  void _showCompletionBanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('¡Orientación lista! Puedes ver tus profesionales recomendados.'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Ver resultados',
          textColor: AppTheme.primary,
          onPressed: _handleCompleteSession,
        ),
      ),
    );
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
          if (_currentSession != null)
            TextButton(
              onPressed: _handleCompleteSession,
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
                      style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // Alerta si el estado es crítico o de emergencia
            if (_crisisResources.isNotEmpty || _currentSession?.isEscalated == true)
              _buildCrisisAlert(isDark),

            // Contenido principal
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 48),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MindEase AI está escribiendo...',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

            // Campo de texto de envío
            if (_currentSession?.status != 'COMPLETED') _buildInputArea(isDark),
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
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
              SizedBox(width: 8),
              Text(
                'Líneas de Ayuda Inmediata',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Si estás viviendo una situación de riesgo o angustia extrema, por favor comunícate directamente con estos recursos gratuitos y confidenciales 24/7:',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          ..._crisisResources.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Text('${r.name}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(r.phone, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14)),
                ],
              ),
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
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              enabled: !_isSending,
              decoration: InputDecoration(
                hintText: 'Cuéntame qué estás sintiendo...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send_rounded,
              color: _isSending ? Colors.grey : AppTheme.primary,
            ),
            onPressed: _isSending ? null : _handleSendMessage,
          ),
        ],
      ),
    );
  }
}
