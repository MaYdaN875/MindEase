import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/community_service.dart';

void communityMessage(BuildContext context, Object error) =>
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));

class PagedCommunityList<T> extends StatefulWidget {
  final Future<CommunityPage<T>> Function(String? cursor) load;
  final Widget Function(T item) itemBuilder;
  final String Function(T item) identity;
  final String emptyMessage;
  const PagedCommunityList({
    super.key,
    required this.load,
    required this.itemBuilder,
    required this.identity,
    this.emptyMessage = 'Todavía no hay contenido aquí.',
  });
  @override
  State<PagedCommunityList<T>> createState() => _PagedCommunityListState<T>();
}

class _PagedCommunityListState<T> extends State<PagedCommunityList<T>> {
  List<T> _items = [];
  String? _cursor, _error;
  bool _busy = false, _hasMore = false;
  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = await widget.load(reset ? null : _cursor);
      if (!mounted) return;
      setState(() {
        final merged = <String, T>{
          for (final item in reset ? <T>[] : _items)
            widget.identity(item): item,
        };
        for (final item in page.items) {
          merged[widget.identity(item)] = item;
        }
        _items = merged.values.toList();
        _hasMore = page.hasMore && (reset || page.nextCursor != _cursor);
        _cursor = page.nextCursor;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () => _load(reset: true),
    child: ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _items.length + 1,
      itemBuilder: (context, index) {
        if (index < _items.length) return widget.itemBuilder(_items[index]);
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (_busy) const CircularProgressIndicator(),
              if (!_busy && _error != null) ...[
                Text(_error!, textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => _load(reset: _items.isEmpty),
                  child: const Text('Reintentar'),
                ),
              ],
              if (!_busy && _error == null && _items.isEmpty)
                Text(widget.emptyMessage, textAlign: TextAlign.center),
              if (!_busy && _error == null && _hasMore)
                OutlinedButton(
                  onPressed: _load,
                  child: const Text('Cargar más'),
                ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> openCommunityMedia(
  BuildContext context,
  CommunityService service,
  PostMedia media,
) async {
  final uri = service.mediaUri(media.url);
  if (uri == null) {
    communityMessage(context, 'Este recurso no tiene una URL segura.');
    return;
  }
  if (media.type == 'IMAGE') {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(media.caption ?? 'Imagen')),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Image.network(
                uri.toString(),
                errorBuilder: (_, _, _) =>
                    const Text('No se pudo cargar la imagen.'),
              ),
            ),
          ),
        ),
      ),
    );
  } else {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          media.type == 'DOCUMENT' ? 'Abrir documento' : 'Abrir enlace',
        ),
        content: Text(
          'Se abrirá un recurso externo de ${uri.host}. No compartas información clínica o personal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
        communityMessage(
          context,
          'No se encontró una aplicación para abrir el recurso.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        communityMessage(context, 'No se pudo abrir el recurso.');
      }
    }
  }
}

class CommunityMediaTile extends StatelessWidget {
  final PostMedia media;
  final CommunityService service;
  const CommunityMediaTile({
    super.key,
    required this.media,
    required this.service,
  });
  @override
  Widget build(BuildContext context) {
    final uri = service.mediaUri(media.url);
    return Card(
      child: InkWell(
        onTap: () => openCommunityMedia(context, service, media),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (media.type == 'IMAGE' && uri != null)
              Image.network(
                uri.toString(),
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 100,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ListTile(
              leading: Icon(
                media.type == 'IMAGE'
                    ? Icons.zoom_in
                    : media.type == 'DOCUMENT'
                    ? Icons.picture_as_pdf
                    : Icons.link,
              ),
              title: Text(
                media.caption ??
                    (media.type == 'IMAGE' ? 'Ver imagen' : 'Abrir recurso'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.open_in_new),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> reportCommunityContent(
  BuildContext context,
  CommunityService service,
  String targetType,
  String id,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      _ReportDialog(service: service, targetType: targetType, id: id),
);

class _ReportDialog extends StatefulWidget {
  final CommunityService service;
  final String targetType, id;
  const _ReportDialog({
    required this.service,
    required this.targetType,
    required this.id,
  });
  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _details = TextEditingController();
  String _reason = 'MEDICAL_MISINFORMATION';
  String? _error;
  bool _busy = false;
  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.report(
        targetType: widget.targetType,
        id: widget.id,
        reason: _reason,
        details: _details.text,
      );
      if (!mounted) return;
      communityMessage(context, 'Reporte enviado a moderación.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Reportar contenido'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _reason,
              isExpanded: true,
              items:
                  const {
                        'MEDICAL_MISINFORMATION': 'Información engañosa',
                        'HARASSMENT': 'Acoso',
                        'SPAM': 'Spam',
                        'INAPPROPRIATE_CONTENT': 'Contenido inapropiado',
                        'OTHER': 'Otro',
                      }.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _reason = value!),
            ),
            TextField(
              controller: _details,
              maxLength: 1000,
              maxLines: 3,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Detalles (sin datos sensibles)',
              ),
            ),
            if (_error != null) Text(_error!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Enviando…' : 'Enviar reporte'),
        ),
      ],
    ),
  );
}
