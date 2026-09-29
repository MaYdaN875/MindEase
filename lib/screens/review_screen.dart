import 'package:flutter/material.dart';
import '../services/review_service.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.appointmentId});
  final String appointmentId;
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}
class _ReviewScreenState extends State<ReviewScreen> {
  final _service = ReviewService();
  final _comment = TextEditingController();
  bool _loading = true, _saving = false, _canReview = false;
  int _rating = 0;
  String? _error;
  Map<String, dynamic>? _review;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.request('/appointments/${widget.appointmentId}');
      if (!mounted) return;
      setState(() {
        _review = data['review']; _canReview = data['canReview'] == true;
        if (_review != null) { _rating = _review!['rating']; _comment.text = _review!['comment'] ?? ''; }
      });
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _send() async {
    setState(() { _saving = true; _error = null; });
    try {
      await _service.request('/appointments/${widget.appointmentId}', body: {'rating': _rating, 'comment': _comment.text.trim()});
      if (mounted) await _load();
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _saving = false); }
  }
  @override
  void dispose() { _service.dispose(); _comment.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Calificar consulta')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Tu opinión es voluntaria y no afecta tu atención.'),
      const SizedBox(height: 16),
      Wrap(children: List.generate(5, (index) => IconButton(
        tooltip: '${index + 1} estrellas', onPressed: _canReview && !_saving ? () => setState(() => _rating = index + 1) : null,
        icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 36)))),
      TextField(controller: _comment, enabled: _canReview && !_saving, maxLength: 1000, minLines: 3, maxLines: 6,
        decoration: const InputDecoration(labelText: 'Reseña opcional', border: OutlineInputBorder())),
      const Text('Tu calificación contribuye al promedio. El comentario se publicará sin tu nombre solo después de moderación. No incluyas datos personales, diagnósticos ni detalles de la sesión.'),
      if (_review != null) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(
        'Calificación guardada. Comentario: ${switch (_review!['status']) { 'APPROVED' => 'aprobado', 'REJECTED' => 'no publicado', _ => 'pendiente de moderación' }}.')),
      if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      if (_canReview) FilledButton(onPressed: _rating > 0 && !_saving ? _send : null,
        child: Text(_saving ? 'Guardando…' : 'Enviar calificación')),
      if (!_canReview && _review == null && _error == null) const Text('Disponible cuando el profesional complete la consulta.'),
      TextButton(onPressed: _saving ? null : _load, child: const Text('Actualizar')),
    ]));
}

class PublicReviews extends StatefulWidget {
  const PublicReviews({super.key, required this.psychologistId});
  final String psychologistId;
  @override
  State<PublicReviews> createState() => _PublicReviewsState();
}
class _PublicReviewsState extends State<PublicReviews> {
  final _service = ReviewService();
  final List<dynamic> _reviews = [];
  int _page = 1, _count = 0;
  num? _rating;
  bool _loading = false, _hasMore = true;
  String? _error;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.request('/psychologists/${widget.psychologistId}?page=$_page', public: true);
      if (!mounted) return;
      setState(() { _reviews.addAll(data['reviews']); _rating = data['rating']; _count = data['reviewsCount']; _hasMore = data['hasMore'] == true; _page++; });
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  @override
  void dispose() { _service.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(_rating == null ? 'Sin calificaciones' : '${_rating!.toStringAsFixed(1)} ★ · $_count calificaciones'),
    const Text('Opiniones de consultas completadas. Identidad del paciente protegida.'),
    for (final review in _reviews) Card(child: ListTile(title: Text('Paciente · ${review['rating']} ★'), subtitle: Text(review['comment'] ?? ''))),
    if (_reviews.isEmpty && !_loading && _error == null) const Text('Aún no hay comentarios publicados.'),
    if (_error != null) Text(_error!),
    if (_hasMore || _error != null) TextButton(onPressed: _loading ? null : _load, child: Text(_loading ? 'Cargando…' : 'Cargar reseñas')),
  ]);
}
