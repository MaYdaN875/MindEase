import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/initial_interview_service.dart';
import '../../theme/app_theme.dart';

class InitialInterviewReportScreen extends StatefulWidget {
  const InitialInterviewReportScreen({
    super.key,
    required this.patientId,
    required this.appointmentId,
  });

  final String patientId;
  final String appointmentId;

  @override
  State<InitialInterviewReportScreen> createState() =>
      _InitialInterviewReportScreenState();
}

class _InitialInterviewReportScreenState
    extends State<InitialInterviewReportScreen> {
  final InitialInterviewService _service = InitialInterviewService();
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _service.getProfessionalReport(
      patientId: widget.patientId,
      appointmentId: widget.appointmentId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _data = Map<String, dynamic>.from(result['data'] as Map);
      } else {
        _error =
            result['message']?.toString() ?? 'No se pudo cargar el informe.';
      }
    });
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final bytes = await _service.downloadProfessionalPdf(
        patientId: widget.patientId,
        appointmentId: widget.appointmentId,
      );
      final path = await FilePicker.platform.saveFile(
        fileName: 'informe-entrevista-${_data?['recordId'] ?? 'paciente'}.pdf',
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        bytes: bytes,
      );
      if (path == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe guardado en la ubicación seleccionada.'),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrevista inicial del paciente'),
        actions: [
          if (_data != null)
            IconButton(
              tooltip: 'Descargar PDF',
              onPressed: _downloading ? null : _download,
              icon: _downloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : _reportBody(),
    );
  }

  Widget _reportBody() {
    final data = _data ?? const <String, dynamic>{};
    final report = Map<String, dynamic>.from(data['report'] as Map);
    final answers = Map<String, dynamic>.from(data['answers'] as Map);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.tertiaryContainer.withValues(alpha: 0.3),
            border: Border.all(color: AppTheme.tertiaryFixedDim),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            data['disclaimer']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Expediente ${data['recordId']}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text('Entrevista: ${_formatDate(data['interviewDate']?.toString())}'),
        const SizedBox(height: 16),
        if (report['generalData'] is Map)
          _section('Datos generales mínimos', report['generalData']),
        _section('Motivo principal de consulta', report['mainConcern']),
        _section('Situación actual', report['currentSituation']),
        _section(
          'Síntomas y manifestaciones referidas',
          report['reportedSymptoms'],
        ),
        _section('Duración y evolución', report['durationAndCourse']),
        _section('Antecedentes personales', report['personalHistory']),
        _section('Antecedentes familiares', report['familyHistory']),
        _section('Red de apoyo', report['supportNetwork']),
        _section(
          'Seguridad y factores de riesgo referidos',
          report['safetyInformation'],
        ),
        _section('Factores protectores referidos', report['protectiveFactors']),
        _section('Objetivos y expectativas', report['patientObjectives']),
        _section(
          'Áreas de exploración clínica',
          report['clinicalAreasToExplore'],
        ),
        _section(
          'Hipótesis preliminares orientativas',
          report['preliminaryHypotheses'],
        ),
        _section(
          'Información contradictoria o por aclarar',
          report['inconsistenciesToClarify'],
        ),
        _section('Información faltante', report['missingInformation']),
        _section(
          'Sugerencias para evaluación profesional',
          report['professionalRecommendations'],
        ),
        const SizedBox(height: 12),
        Text(
          'Respuestas originales',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...answers.entries.map(
          (entry) => Card(
            child: ListTile(
              title: Text(_questionLabel(entry.key)),
              subtitle: Text(entry.value.toString()),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _downloading ? null : _download,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(
            _downloading ? 'Preparando PDF…' : 'Descargar informe PDF',
          ),
        ),
      ],
    );
  }

  Widget _section(String title, dynamic value) {
    final text = value is List
        ? value.map(_formatListItem).join('\n')
        : value is Map
        ? value.values.map(_formatListItem).join('\n')
        : value?.toString() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              text.isEmpty ? 'No referido.' : text,
              style: const TextStyle(height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  String _formatListItem(dynamic item) {
    if (item is Map) {
      return item.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(' · ');
    }
    return '• $item';
  }

  String _questionLabel(String id) {
    final normalized = id.replaceAll('_', ' ');
    return normalized.isEmpty
        ? id
        : '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  String _formatDate(String? value) {
    final date = DateTime.tryParse(value ?? '');
    if (date == null) return 'No disponible';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
