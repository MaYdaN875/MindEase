import 'package:flutter/material.dart';
import '../../services/support_service.dart';
import '../../theme/app_theme.dart';

class TicketCreateScreen extends StatefulWidget {
  final SupportService? service;
  final String? initialCategory;
  final String? referenceType;
  final String? referenceId;

  const TicketCreateScreen({
    super.key,
    this.service,
    this.initialCategory,
    this.referenceType,
    this.referenceId,
  });

  @override
  State<TicketCreateScreen> createState() => _TicketCreateScreenState();
}

class _TicketCreateScreenState extends State<TicketCreateScreen> {
  late final SupportService _service;
  final _subjectCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  String _category = 'TECHNICAL';
  String _priority = 'MEDIUM';
  final List<String> _attachments = [];
  bool _isLoading = false;
  String? _error;

  static const _categories = [
    {'code': 'ACCOUNT', 'label': 'Cuenta y Perfil'},
    {'code': 'APPOINTMENT', 'label': 'Citas y Consultas'},
    {'code': 'PAYMENT', 'label': 'Pagos y Facturación'},
    {'code': 'PSYCHOLOGIST', 'label': 'Atención Profesional'},
    {'code': 'TECHNICAL', 'label': 'Falla Técnica en la App'},
    {'code': 'REPORT', 'label': 'Seguimiento de Reporte'},
    {'code': 'OTHER', 'label': 'Consulta General'},
  ];

  static const _priorities = [
    {'code': 'LOW', 'label': 'Baja'},
    {'code': 'MEDIUM', 'label': 'Media'},
    {'code': 'HIGH', 'label': 'Alta'},
    {'code': 'URGENT', 'label': 'Urgente'},
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? SupportService();
    if (widget.initialCategory != null) {
      _category = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subjectCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (subject.length < 5) {
      setState(() => _error = 'El asunto debe tener al menos 5 caracteres.');
      return;
    }
    if (content.length < 10) {
      setState(() => _error = 'La descripción debe tener al menos 10 caracteres.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ticket = await _service.createTicket(
        subject: subject,
        category: _category,
        priority: _priority,
        content: content,
        attachments: _attachments,
        referenceType: widget.referenceType,
        referenceId: widget.referenceId,
      );

      if (!mounted) return;
      Navigator.of(context).pop(ticket);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket #${ticket.ticketNumber} creado exitosamente.'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Ticket de Ayuda'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category & Priority
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? AppTheme.cardDark : Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _category,
                            isExpanded: true,
                            dropdownColor: isDark ? AppTheme.cardDark : Colors.white,
                            items: _categories.map((c) => DropdownMenuItem(value: c['code'], child: Text(c['label']!, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (v) => setState(() => _category = v ?? _category),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Prioridad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? AppTheme.cardDark : Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _priority,
                            isExpanded: true,
                            dropdownColor: isDark ? AppTheme.cardDark : Colors.white,
                            items: _priorities.map((p) => DropdownMenuItem(value: p['code'], child: Text(p['label']!, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (v) => setState(() => _priority = v ?? _priority),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Subject
            const Text('Asunto o Título', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectCtrl,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: 'Ej. No se completó la videollamada',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? AppTheme.cardDark : Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Detailed Description
            const Text('Describe tu situación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _contentCtrl,
              maxLines: 6,
              maxLength: 3000,
              decoration: InputDecoration(
                hintText: 'Explica qué ocurrió, qué esperabas y cualquier detalle relevante para que el equipo pueda ayudarte con rapidez...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? AppTheme.cardDark : Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Error notice
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: const Text('Enviar ticket de soporte', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
