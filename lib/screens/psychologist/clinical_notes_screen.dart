import 'package:flutter/material.dart';
import '../../services/appointment_service.dart';

class ClinicalNotesScreen extends StatefulWidget {
  final String appointmentId;
  final AppointmentService? service;
  const ClinicalNotesScreen({super.key, required this.appointmentId, this.service});

  @override
  State<ClinicalNotesScreen> createState() => _ClinicalNotesScreenState();
}

class _ClinicalNotesScreenState extends State<ClinicalNotesScreen> {
  final _controller = TextEditingController();
  late final AppointmentService _service;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AppointmentService();
    _load();
  }

  Future<void> _load() async {
    final result = await _service.getConsultation(widget.appointmentId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _controller.text = result['data']?['clinicalNotes'] ?? '';
        _error = null;
      } else {
        _error = result['message'] ?? 'No se pudo cargar el expediente';
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await _service.updateClinicalNotes(widget.appointmentId, _controller.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (result['success'] == true) _dirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Operación completada')));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _saving) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cambios sin guardar'),
            content: const Text('¿Salir y descartar los cambios de las notas?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Continuar editando')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Descartar')),
            ],
          ),
        );
        if (discard == true && mounted) {
          setState(() => _dirty = false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Notas clínicas privadas')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), TextButton(onPressed: _load, child: const Text('Reintentar'))]))
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Text('Estas notas solo son visibles para el profesional tratante.'),
                      const SizedBox(height: 16),
                      Expanded(child: TextField(
                        controller: _controller,
                        enabled: !_saving,
                        onChanged: (_) => setState(() => _dirty = true),
                        expands: true, maxLines: null, minLines: null, maxLength: 50000,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Escribe las notas de la consulta'),
                      )),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Guardando…' : 'Guardar notas')),
                    ]),
                  ),
      ),
    );
  }
}
