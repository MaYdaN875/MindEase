import 'package:flutter/material.dart';
import '../services/initial_interview_service.dart';
import '../theme/app_theme.dart';

class InitialInterviewScreen extends StatefulWidget {
  const InitialInterviewScreen({
    super.key,
    required this.onFinished,
    required this.onPaused,
    this.service,
  });

  final Future<void> Function() onFinished;
  final Future<void> Function() onPaused;
  final InitialInterviewService? service;

  @override
  State<InitialInterviewScreen> createState() => _InitialInterviewScreenState();
}

class _InitialInterviewScreenState extends State<InitialInterviewScreen> {
  late final InitialInterviewService _service =
      widget.service ?? InitialInterviewService();
  final TextEditingController _answerController = TextEditingController();
  Map<String, dynamic>? _privacyNotice;
  Map<String, dynamic>? _question;
  Map<String, dynamic>? _progress;
  List<dynamic> _reviewAnswers = [];
  List<dynamic> _resources = [];
  String? _selectedAnswer;
  String? _error;
  String? _boundaryMessage;
  String? _safetyMessage;
  String? _screen;
  bool _adultConfirmed = false;
  bool _consentAccepted = false;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final status = await _service.getStatus();
    if (!mounted) return;
    if (status['success'] != true) {
      setState(() {
        _loading = false;
        _error =
            status['message']?.toString() ??
            'No se pudo consultar el estado de la entrevista.';
      });
      return;
    }
    final statusData = Map<String, dynamic>.from(status['data'] as Map);
    _privacyNotice = Map<String, dynamic>.from(
      statusData['privacyNotice'] as Map,
    );
    _consentAccepted = statusData['hasConsent'] == true;
    if (statusData['status'] == 'COMPLETED') {
      await widget.onFinished();
      return;
    }
    final progressResult = await _service.getProgress();
    if (!mounted) return;
    if (progressResult['success'] != true) {
      setState(() {
        _loading = false;
        _error =
            progressResult['message']?.toString() ??
            'No se pudo cargar el progreso.';
      });
      return;
    }
    final progressData = Map<String, dynamic>.from(
      progressResult['data'] as Map,
    );
    setState(() {
      _progress = progressData['progress'] as Map<String, dynamic>?;
      _question = progressData['question'] as Map<String, dynamic>?;
      _safetyMessage = progressData['safetyMessage']?.toString();
      _resources = List<dynamic>.from(progressData['resources'] ?? const []);
      if (progressData['status'] == 'ESCALATED') {
        _screen = 'safety';
      } else if (progressData['status'] == 'IN_PROGRESS') {
        _screen = progressData['question'] == null ? 'review' : 'question';
      } else {
        _screen = 'welcome';
      }
      _loading = false;
    });
    if (_screen == 'review') await _loadReview();
  }

  Future<void> _start() async {
    if (!_consentAccepted && !_consentAcceptedForSession) {
      setState(() => _error = 'Acepta el aviso de privacidad para continuar.');
      return;
    }
    if (!_adultConfirmed) {
      setState(() => _error = 'Confirma que tienes 18 años o más.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await _service.start(
      consentVersion: _privacyNotice?['version']?.toString() ?? '',
      adultConfirmed: _adultConfirmed,
    );
    if (!mounted) return;
    if (result['success'] != true) {
      setState(() {
        _busy = false;
        _error =
            result['message']?.toString() ??
            'No se pudo iniciar la entrevista.';
      });
      return;
    }
    final data = Map<String, dynamic>.from(result['data'] as Map);
    setState(() {
      _progress = data['progress'] as Map<String, dynamic>?;
      _question = data['question'] as Map<String, dynamic>?;
      _screen = _question == null ? 'review' : 'question';
      _busy = false;
      _consentAccepted = true;
    });
    if (_screen == 'review') await _loadReview();
  }

  bool get _consentAcceptedForSession => _acceptedThisVisit;
  bool _acceptedThisVisit = false;

  Future<void> _submitAnswer() async {
    final value = _question?['answerType'] == 'choice'
        ? _selectedAnswer
        : _question?['answerType'] == 'date'
        ? _selectedAnswer
        : _answerController.text.trim();
    if (value == null || value.trim().isEmpty) {
      setState(
        () => _error =
            'Completa tu respuesta o elige “Prefiero no responder” cuando esté disponible.',
      );
      return;
    }
    await _saveAnswer(_question?['id']?.toString() ?? '', value);
  }

  Future<void> _saveAnswer(String questionId, String value) async {
    setState(() {
      _busy = true;
      _error = null;
      _boundaryMessage = null;
    });
    final result = await _service.answer(questionId: questionId, value: value);
    if (!mounted) return;
    if (result['success'] != true) {
      setState(() {
        _busy = false;
        _error =
            result['message']?.toString() ?? 'No se pudo guardar tu respuesta.';
      });
      return;
    }
    final data = Map<String, dynamic>.from(result['data'] as Map);
    if (data['needsImmediateHelp'] == true || data['status'] == 'ESCALATED') {
      setState(() {
        _busy = false;
        _safetyMessage = data['safetyMessage']?.toString();
        _resources = List<dynamic>.from(data['resources'] ?? const []);
        _screen = 'safety';
      });
      return;
    }
    setState(() {
      _busy = false;
      _progress = data['progress'] as Map<String, dynamic>?;
      _question = data['question'] as Map<String, dynamic>?;
      _selectedAnswer = null;
      _answerController.clear();
      if (data['boundaryMessage'] != null) {
        _boundaryMessage = data['boundaryMessage'].toString();
      } else {
        _screen = _question == null ? 'review' : 'question';
      }
    });
    if (_screen == 'review') await _loadReview();
  }

  Future<void> _loadReview() async {
    final result = await _service.getReview();
    if (!mounted) return;
    if (result['success'] != true) {
      setState(
        () => _error =
            result['message']?.toString() ??
            'No se pudieron cargar tus respuestas.',
      );
      return;
    }
    setState(
      () => _reviewAnswers = List<dynamic>.from(
        result['data']['answers'] as List,
      ),
    );
  }

  Future<void> _editAnswer(Map<String, dynamic> entry) async {
    final controller = TextEditingController(
      text: entry['answer']?.toString() ?? '',
    );
    final answerType =
        entry['answerType']?.toString() ??
        _questionType(entry['questionId']?.toString() ?? '');
    final options = entry['options'] is List
        ? List<String>.from(entry['options'] as List)
        : _questionOptions(entry['questionId']?.toString() ?? '');
    String? selected = answerType == 'choice' ? controller.text : null;
    String? error;
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Corregir respuesta'),
          content: answerType == 'choice'
              ? DropdownButtonFormField<String>(
                  initialValue: selected,
                  items: options
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => selected = value),
                )
              : TextField(
                  controller: controller,
                  maxLength: 300,
                  maxLines: 4,
                  decoration: InputDecoration(
                    errorText: error,
                    border: const OutlineInputBorder(),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = answerType == 'choice'
                    ? selected
                    : controller.text.trim();
                if (value == null || value.isEmpty) {
                  setDialogState(
                    () => error = 'Escribe o selecciona una respuesta.',
                  );
                  return;
                }
                Navigator.pop(context, value);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (updated == null) return;
    setState(() => _busy = true);
    final result = await _service.revise(
      questionId: entry['questionId'].toString(),
      value: updated,
    );
    if (!mounted) return;
    if (result['success'] != true) {
      setState(() {
        _busy = false;
        _error =
            result['message']?.toString() ??
            'No se pudo corregir la respuesta.';
      });
      return;
    }
    final data = Map<String, dynamic>.from(result['data'] as Map);
    if (data['needsImmediateHelp'] == true) {
      setState(() {
        _busy = false;
        _safetyMessage = data['safetyMessage']?.toString();
        _resources = List<dynamic>.from(data['resources'] ?? const []);
        _screen = 'safety';
      });
      return;
    }
    setState(() => _busy = false);
    await _loadReview();
  }

  String _questionType(String id) {
    if (id == 'prior_help' ||
        id == 'prior_treatment' ||
        id == 'family_history' ||
        id == 'self_harm_thoughts' ||
        id == 'suicide_thoughts' ||
        id == 'immediate_plan_or_means' ||
        id == 'danger_from_others' ||
        id == 'danger_to_others' ||
        id == 'care_preference' ||
        id == 'care_modality') {
      return 'choice';
    }
    return 'text';
  }

  List<String> _questionOptions(String id) {
    if (id == 'care_preference')
      return [
        'Psicología',
        'Psiquiatría',
        'No estoy seguro/a',
        'Prefiero no responder',
      ];
    if (id == 'care_modality')
      return ['En línea', 'Presencial', 'Cualquiera', 'Prefiero no responder'];
    return ['Sí', 'No', 'Prefiero no responder'];
  }

  Future<void> _complete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await _service.complete();
    if (!mounted) return;
    if (result['success'] != true) {
      setState(() {
        _busy = false;
        _error =
            result['message']?.toString() ??
            'No se pudo finalizar. Tus respuestas se conservaron.';
      });
      return;
    }
    setState(() {
      _busy = false;
      _screen = 'complete';
    });
  }

  Future<void> _continueAfterCompletion() async {
    await widget.onFinished();
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  Future<void> _exitAfterSafetyNotice() async {
    await widget.onFinished();
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  Future<void> _pauseInterview() async {
    await widget.onPaused();
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Selecciona tu fecha de nacimiento',
    );
    if (date != null)
      setState(
        () => _selectedAnswer =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const Icon(Icons.spa_outlined, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text('Entrevista inicial', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _busy ? null : _pauseInterview,
              child: const Text('Salir'),
            ),
          ],
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _screen == null
              ? _errorScreen()
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: switch (_screen) {
                    'welcome' => _welcomeScreen(),
                    'question' => _questionScreen(),
                    'review' => _reviewScreen(),
                    'safety' => _safetyScreen(),
                    'complete' => _completeScreen(),
                    _ => _errorScreen(),
                  },
                ),
        ),
      ),
    );
  }

  Widget _errorScreen() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 44,
            color: AppTheme.primaryDark,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'No se pudo cargar la entrevista.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
        ],
      ),
    ),
  );

  Widget _welcomeScreen() => _page(
    key: const ValueKey('welcome'),
    children: [
      const Icon(Icons.favorite_outline, size: 42, color: AppTheme.primaryDark),
      const SizedBox(height: 16),
      Text(
        'Conozcámonos mejor',
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      const Text(
        'Esta entrevista es voluntaria y no ofrece atención de emergencia ni diagnóstico. No hay supervisión humana ni seguimiento automático de alertas.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 22),
      _privacyCard(),
      const SizedBox(height: 16),
      CheckboxListTile(
        value: _adultConfirmed,
        onChanged: _busy
            ? null
            : (value) => setState(() => _adultConfirmed = value ?? false),
        contentPadding: EdgeInsets.zero,
        title: const Text('Confirmo que tengo 18 años o más.'),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      CheckboxListTile(
        value: _consentAccepted || _acceptedThisVisit,
        onChanged: _busy || _consentAccepted
            ? null
            : (value) => setState(() => _acceptedThisVisit = value ?? false),
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'He leído y acepto el consentimiento informado para esta entrevista.',
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      if (_error != null) _errorText(_error!),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _busy ? null : _start,
          child: _busy
              ? const CircularProgressIndicator()
              : const Text('Comenzar entrevista'),
        ),
      ),
    ],
  );

  Widget _privacyCard() {
    final notice = _privacyNotice;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline, color: AppTheme.primaryDark),
              SizedBox(width: 8),
              Text(
                'Privacidad y uso de tus datos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            (notice?['text'] ?? '').toString(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _questionScreen() {
    final question = _question ?? const <String, dynamic>{};
    final progress = _progress ?? const <String, dynamic>{};
    final type = question['answerType']?.toString();
    final options = List<String>.from(question['options'] ?? const []);
    return _page(
      key: ValueKey(question['id']),
      children: [
        Text(
          '${progress['current'] ?? 1} de ${progress['total'] ?? 1}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: ((progress['percent'] ?? 0) as num).toDouble() / 100,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: _moduleTag(question['module']?.toString() ?? 'Entrevista'),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            question['prompt']?.toString() ?? '',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(height: 1.35),
          ),
        ),
        const SizedBox(height: 20),
        if (type == 'choice')
          ...options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _choice(option),
            ),
          )
        else if (type == 'date')
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickBirthDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(_selectedAnswer ?? 'Elegir fecha'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(
                        () => _selectedAnswer = 'Prefiero no responder',
                      ),
                child: const Text('Prefiero no responder'),
              ),
            ],
          )
        else
          TextField(
            controller: _answerController,
            enabled: !_busy,
            minLines: 3,
            maxLines: 6,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Escribe tu respuesta aquí…',
              helperText:
                  'Evita compartir nombres, teléfonos, direcciones o datos de otras personas. Tu respuesta se guarda de forma protegida.',
              border: OutlineInputBorder(),
            ),
          ),
        if (_boundaryMessage != null) _infoText(_boundaryMessage!),
        if (_error != null) _errorText(_error!),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _busy ? null : _submitAnswer,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continuar'),
          ),
        ),
      ],
    );
  }

  Widget _choice(String option) => RadioListTile<String>(
    value: option,
    groupValue: _selectedAnswer,
    onChanged: _busy
        ? null
        : (value) => setState(() => _selectedAnswer = value),
    title: Text(option),
    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  Widget _reviewScreen() => _page(
    key: const ValueKey('review'),
    children: [
      const Icon(
        Icons.fact_check_outlined,
        size: 42,
        color: AppTheme.primaryDark,
      ),
      const SizedBox(height: 12),
      Text(
        'Revisa tus respuestas',
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      const Text(
        'Puedes corregir cualquier respuesta antes de finalizar. El informe generado se comparte solo con un profesional autorizado.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 18),
      ..._reviewAnswers.map((item) {
        final entry = Map<String, dynamic>.from(item as Map);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(entry['prompt']?.toString() ?? ''),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(entry['answer']?.toString() ?? 'Sin respuesta'),
            ),
            trailing: IconButton(
              tooltip: 'Corregir respuesta',
              onPressed: _busy ? null : () => _editAnswer(entry),
              icon: const Icon(Icons.edit_outlined),
            ),
          ),
        );
      }),
      if (_error != null) _errorText(_error!),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _busy ? null : _complete,
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirmar y finalizar'),
        ),
      ),
    ],
  );

  Widget _safetyScreen() => _page(
    key: const ValueKey('safety'),
    children: [
      const Icon(
        Icons.health_and_safety_outlined,
        size: 46,
        color: AppTheme.error,
      ),
      const SizedBox(height: 14),
      Text(
        'Tu seguridad es lo primero',
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 10),
      Text(
        _safetyMessage ?? 'La entrevista se pausó para priorizar tu seguridad.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      const Text(
        'MindEase no es un servicio de emergencias. Si existe peligro inmediato, contacta a emergencias o a una persona de confianza.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 18),
      ..._resources.map((item) {
        final resource = Map<String, dynamic>.from(item as Map);
        return Card(
          child: ListTile(
            leading: const Icon(Icons.call_outlined, color: AppTheme.error),
            title: Text(resource['name']?.toString() ?? 'Recurso de ayuda'),
            subtitle: Text(
              [
                if (resource['phone'] != null) resource['phone'].toString(),
                if (resource['description'] != null)
                  resource['description'].toString(),
              ].join('\n'),
            ),
          ),
        );
      }),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: _exitAfterSafetyNotice,
        child: const Text('Volver a MindEase'),
      ),
    ],
  );

  Widget _completeScreen() => _page(
    key: const ValueKey('complete'),
    children: [
      const Icon(
        Icons.check_circle_outline,
        size: 54,
        color: AppTheme.primaryDark,
      ),
      const SizedBox(height: 16),
      Text(
        '¡Gracias por compartir esta información con nosotros!',
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      const Text(
        'Hemos registrado tus respuestas para facilitar tu futura atención profesional. Cuando agendes tu primera consulta, tu especialista podrá revisar la información necesaria para preparar una atención más personalizada.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _continueAfterCompletion,
          child: const Text('Continuar a MindEase'),
        ),
      ),
    ],
  );

  Widget _page({required Key key, required List<Widget> children}) =>
      SingleChildScrollView(
        key: key,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      );

  Widget _moduleTag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.primary.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppTheme.primaryDark,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );

  Widget _errorText(String message) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      message,
      style: const TextStyle(color: AppTheme.error),
      textAlign: TextAlign.center,
    ),
  );

  Widget _infoText(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.primary),
      textAlign: TextAlign.center,
    ),
  );
}
