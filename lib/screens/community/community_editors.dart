import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import 'community_widgets.dart';

class ChannelEditor extends StatefulWidget {
  final CommunityService service;
  final List<CommunityCategory> categories;
  final CommunityChannel? channel;
  const ChannelEditor({
    super.key,
    required this.service,
    required this.categories,
    this.channel,
  });
  @override
  State<ChannelEditor> createState() => _ChannelEditorState();
}

class _ChannelEditorState extends State<ChannelEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.channel?.name);
  late final _description = TextEditingController(
    text: widget.channel?.description,
  );
  late final _specialties = TextEditingController(
    text: widget.channel?.specialties,
  );
  late String? _category =
      widget.categories.any((c) => c.id == widget.channel?.category.id)
      ? widget.channel!.category.id
      : null;
  late String? _cover = widget.channel?.coverImageUrl;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _specialties.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    setState(() => _busy = true);
    try {
      final files = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        withData: true,
      );
      if (files == null || !mounted) return;
      final file = files.files.single;
      if (file.bytes == null) {
        throw const CommunityException(
          'No se pudo leer el archivo seleccionado.',
        );
      }
      final media = await widget.service.upload(file.name, file.bytes!);
      if (mounted) setState(() => _cover = media.url);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.saveChannel({
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'categoryId': _category,
        'specialties': _specialties.text.trim(),
        'coverImageUrl': _cover,
      }, id: widget.channel?.id);
      if (mounted) {
        setState(() => _busy = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.channel == null ? 'Crear canal' : 'Editar canal'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              enabled: !_busy,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Nombre del canal'),
              validator: (v) => (v ?? '').trim().length < 3
                  ? 'Escribe al menos 3 caracteres'
                  : null,
            ),
            TextFormField(
              controller: _description,
              enabled: !_busy,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              decoration: const InputDecoration(labelText: 'Descripción'),
              validator: (v) => (v ?? '').trim().length < 10
                  ? 'Escribe al menos 10 caracteres'
                  : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: widget.categories
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: _busy ? null : (v) => setState(() => _category = v),
              validator: (v) =>
                  v == null ? 'Selecciona una categoría activa' : null,
            ),
            TextFormField(
              controller: _specialties,
              enabled: !_busy,
              maxLength: 255,
              decoration: const InputDecoration(
                labelText: 'Especialidades (opcional)',
              ),
            ),
            const Text(
              'La portada será pública. No subas información de pacientes.',
            ),
            if (_cover != null)
              CommunityMediaTile(
                media: PostMedia(type: 'IMAGE', url: _cover!),
                service: widget.service,
              ),
            Wrap(
              children: [
                TextButton.icon(
                  onPressed: _busy ? null : _upload,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Subir portada pública'),
                ),
                if (_cover != null)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _cover = null),
                    child: const Text('Quitar portada'),
                  ),
              ],
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Guardando…' : 'Guardar canal'),
            ),
          ],
        ),
      ),
    ),
  );
}

class CommunityPostEditor extends StatefulWidget {
  final CommunityService service;
  final CommunityChannel channel;
  final CommunityPost? post;
  const CommunityPostEditor({
    super.key,
    required this.service,
    required this.channel,
    this.post,
  });
  @override
  State<CommunityPostEditor> createState() => _CommunityPostEditorState();
}

class _CommunityPostEditorState extends State<CommunityPostEditor> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.post?.title);
  late final _content = TextEditingController(text: widget.post?.content);
  late final _tags = TextEditingController(text: widget.post?.tags.join(', '));
  final _link = TextEditingController();
  late final List<PostMedia> _media = [...?widget.post?.media];
  bool _busy = false, _dirty = false, _saved = false;
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _tags.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_busy) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambios sin guardar'),
        content: const Text(
          'Puedes volver al editor para guardar un borrador. ¿Descartar los cambios locales?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> _upload() async {
    if (_media.length >= 5 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final files = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf'],
        withData: true,
      );
      if (files == null || !mounted) return;
      final file = files.files.single;
      if (file.bytes == null) {
        throw const CommunityException('No se pudo leer el archivo.');
      }
      final media = await widget.service.upload(file.name, file.bytes!);
      if (mounted) {
        setState(() {
          _media.add(media);
          _dirty = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addLink() {
    if (_media.length >= 5) return;
    final uri = widget.service.mediaUri(_link.text);
    if (uri == null || !uri.isAbsolute) {
      setState(() => _error = 'Introduce un enlace HTTP o HTTPS válido.');
      return;
    }
    setState(() {
      _media.add(
        PostMedia(type: 'LINK', url: uri.toString(), caption: uri.host),
      );
      _dirty = true;
      _error = null;
    });
    _link.clear();
  }

  Future<void> _save(String status) async {
    if (_busy || !_form.currentState!.validate()) return;
    final tags = _tags.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    if (tags.length > 10) {
      setState(() => _error = 'Puedes añadir hasta 10 etiquetas.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.savePost({
        if (widget.post == null) 'channelId': widget.channel.id,
        'title': _title.text.trim(),
        'content': _content.text.trim(),
        'tags': tags,
        'media': _media.map((m) => m.toJson()).toList(),
        'status': status,
      }, id: widget.post?.id);
      if (!mounted) return;
      setState(() {
        _saved = true;
        _busy = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy && (!_dirty || _saved),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !_busy) _leave();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.post == null ? 'Nueva publicación' : 'Editar publicación',
        ),
      ),
      body: Form(
        key: _form,
        onChanged: () {
          if (!_dirty) setState(() => _dirty = true);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.channel.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Contenido psicoeducativo, no consultas individuales. Los adjuntos tienen URL pública incluso en borradores. No subas expedientes, datos personales ni información clínica.',
                ),
              ),
            ),
            TextFormField(
              controller: _title,
              enabled: !_busy,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) => (v ?? '').trim().length < 3
                  ? 'Escribe al menos 3 caracteres'
                  : null,
            ),
            TextFormField(
              controller: _content,
              enabled: !_busy,
              minLines: 6,
              maxLines: 18,
              decoration: const InputDecoration(
                labelText: 'Contenido educativo',
              ),
              validator: (v) => (v ?? '').trim().length < 10
                  ? 'Escribe al menos 10 caracteres'
                  : null,
            ),
            TextFormField(
              controller: _tags,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Etiquetas separadas por comas (máximo 10)',
              ),
            ),
            for (var i = 0; i < _media.length; i++)
              ListTile(
                leading: Icon(
                  _media[i].type == 'DOCUMENT'
                      ? Icons.picture_as_pdf
                      : _media[i].type == 'LINK'
                      ? Icons.link
                      : Icons.image,
                ),
                title: Text(
                  _media[i].caption ?? 'Adjunto ${i + 1}',
                  maxLines: 2,
                ),
                onTap: () =>
                    openCommunityMedia(context, widget.service, _media[i]),
                trailing: IconButton(
                  tooltip: 'Quitar adjunto de esta publicación',
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _media.removeAt(i);
                          _dirty = true;
                        }),
                  icon: const Icon(Icons.close),
                ),
              ),
            const Text(
              'Quitar un adjunto de la publicación no elimina el archivo público del servidor.',
            ),
            OutlinedButton.icon(
              onPressed: _busy || _media.length >= 5 ? null : _upload,
              icon: const Icon(Icons.attach_file),
              label: Text(
                'Subir adjunto público (${_media.length}/5, hasta 10 MB)',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _link,
                    enabled: !_busy && _media.length < 5,
                    decoration: const InputDecoration(
                      labelText: 'Enlace educativo https://',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Añadir enlace',
                  onPressed: _busy || _media.length >= 5 ? null : _addLink,
                  icon: const Icon(Icons.add_link),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              children: [
                OutlinedButton(
                  onPressed: _busy ? null : () => _save('DRAFT'),
                  child: const Text('Guardar borrador'),
                ),
                FilledButton(
                  onPressed: _busy ? null : () => _save('PUBLISHED'),
                  child: Text(_busy ? 'Guardando…' : 'Publicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
