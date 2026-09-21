import 'package:flutter/material.dart';
import '../../services/support_service.dart';
import '../../theme/app_theme.dart';

class ReportUserDialog extends StatefulWidget {
  final String reportedUserId;
  final String reportedUserName;
  final String? appointmentId;
  final SupportService? service;

  const ReportUserDialog({
    super.key,
    required this.reportedUserId,
    required this.reportedUserName,
    this.appointmentId,
    this.service,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String reportedUserId,
    required String reportedUserName,
    String? appointmentId,
    SupportService? service,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportUserDialog(
        reportedUserId: reportedUserId,
        reportedUserName: reportedUserName,
        appointmentId: appointmentId,
        service: service,
      ),
    );
  }

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  late final SupportService _service;
  final _descriptionCtrl = TextEditingController();
  String _selectedReason = 'UNPROFESSIONAL_CONDUCT';
  bool _isLoading = false;
  String? _error;

  static const _reasons = [
    {'code': 'UNPROFESSIONAL_CONDUCT', 'label': 'Conducta poco profesional'},
    {'code': 'HARASSMENT', 'label': 'Acoso o lenguaje ofensivo'},
    {'code': 'NO_SHOW_DISPUTE', 'label': 'No asistió a la consulta (No-show)'},
    {'code': 'FRAUD_OR_SCAM', 'label': 'Cobro indebido o intento de fraude'},
    {'code': 'IMPERSONATION', 'label': 'Suplantación de identidad'},
    {'code': 'OTHER', 'label': 'Otro motivo'},
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? SupportService();
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final desc = _descriptionCtrl.text.trim();
    if (desc.length < 10) {
      setState(() => _error = 'Por favor describe lo sucedido con al menos 10 caracteres.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _service.createUserReport(
        reportedUserId: widget.reportedUserId,
        appointmentId: widget.appointmentId,
        reason: _selectedReason,
        description: desc,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte enviado. El equipo de soporte y moderación lo revisará.'),
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag_outlined, color: AppTheme.error, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reportar conducta',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Usuario: ${widget.reportedUserName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Motivo del reporte',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                borderRadius: BorderRadius.circular(12),
                color: isDark ? AppTheme.bgDark.withValues(alpha: 0.5) : AppTheme.surfaceContainerLow,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  dropdownColor: isDark ? AppTheme.cardDark : Colors.white,
                  items: _reasons.map((r) {
                    return DropdownMenuItem(
                      value: r['code'],
                      child: Text(r['label']!),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedReason = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Descripción de los hechos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Explica con detalle lo sucedido para que el equipo pueda evaluar el caso...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? AppTheme.bgDark.withValues(alpha: 0.5) : AppTheme.surfaceContainerLow,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Enviar reporte para revisión', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
