import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import 'community_widgets.dart';

class CommunityPostCard extends StatefulWidget {
  final CommunityPost post;
  final CommunityService service;
  final VoidCallback? onEdit, onArchive;
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.service,
    this.onEdit,
    this.onArchive,
  });
  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard> {
  late CommunityPost _post = widget.post;
  bool _busy = false;
  @override
  void didUpdateWidget(covariant CommunityPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) _post = widget.post;
  }

  Future<void> _like() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.service.like(_post.id);
      final post = await widget.service.post(_post.id);
      if (mounted) setState(() => _post = post);
    } catch (e) {
      if (mounted) communityMessage(context, e);
      // Reconcile an ambiguous toggle, never send it twice automatically.
      try {
        final post = await widget.service.post(_post.id);
        if (mounted) setState(() => _post = post);
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CommunityPostScreen(postId: _post.id, service: widget.service),
      ),
    );
    if (!mounted) return;
    try {
      final post = await widget.service.post(_post.id);
      if (mounted) setState(() => _post = post);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_post.channelName} · ${_post.authorName}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (_post.status != 'PUBLISHED')
            Chip(
              label: Text(
                {
                      'DRAFT': 'Borrador',
                      'ARCHIVED': 'Archivado',
                      'HIDDEN': 'Oculto por moderación',
                    }[_post.status] ??
                    _post.status,
              ),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _post.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              _post.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: _open,
          ),
          if (_post.media.isNotEmpty)
            CommunityMediaTile(
              media: _post.media.first,
              service: widget.service,
            ),
          if (_post.media.length > 1)
            Text('+${_post.media.length - 1} adjuntos en la publicación'),
          if (_post.tags.isNotEmpty)
            Text(_post.tags.map((t) => '#$t').join(' ')),
          Wrap(
            spacing: 8,
            children: [
              if (_post.status == 'PUBLISHED')
                TextButton.icon(
                  onPressed: _busy ? null : _like,
                  icon: Icon(
                    _post.isLiked ? Icons.favorite : Icons.favorite_border,
                  ),
                  label: Text('${_post.likesCount} Me gusta'),
                ),
              TextButton.icon(
                onPressed: _open,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text('${_post.commentsCount} Comentarios'),
              ),
              if (widget.onEdit != null)
                TextButton.icon(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              if (widget.onArchive != null)
                TextButton(
                  onPressed: widget.onArchive,
                  child: const Text('Archivar'),
                ),
              if (_post.status == 'PUBLISHED')
                IconButton(
                  tooltip: 'Reportar publicación',
                  onPressed: () => reportCommunityContent(
                    context,
                    widget.service,
                    'postId',
                    _post.id,
                  ),
                  icon: const Icon(Icons.flag_outlined),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class CommunityPostScreen extends StatefulWidget {
  final String postId;
  final CommunityService service;
  const CommunityPostScreen({
    super.key,
    required this.postId,
    required this.service,
  });
  @override
  State<CommunityPostScreen> createState() => _CommunityPostScreenState();
}

class _CommunityPostScreenState extends State<CommunityPostScreen> {
  final _comment = TextEditingController();
  CommunityPost? _post;
  String? _error;
  bool _busy = false, _isChannelOwner = false;
  int _revision = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final post = await widget.service.post(widget.postId);
      final channel = await widget.service.channel(post.channelId);
      if (mounted) {
        setState(() {
          _post = post;
          _isChannelOwner = channel.isOwner;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _post = null;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _send() async {
    if (_busy || _comment.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.service.addComment(widget.postId, _comment.text);
      if (!mounted) return;
      _comment.clear();
      setState(() => _revision++);
    } catch (e) {
      if (mounted) communityMessage(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(PostComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar comentario?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.service.deleteComment(comment.id);
      if (mounted) setState(() => _revision++);
    } catch (e) {
      if (mounted) communityMessage(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Publicación'),
      actions: [
        IconButton(
          onPressed: _load,
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _post == null
        ? Center(
            child: _error == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
          )
        : Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _post!.channelName,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              _post!.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(_post!.authorName),
                            const SizedBox(height: 12),
                            SelectableText(_post!.content),
                            for (final media in _post!.media)
                              CommunityMediaTile(
                                media: media,
                                service: widget.service,
                              ),
                            const SizedBox(height: 16),
                            const Text(
                              'Preguntas y comentarios',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Conversación pública de un solo nivel. No compartas datos personales ni historias clínicas.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    // A bounded comments list maintains independent cursor pagination without nested unbounded lists.
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.sizeOf(context).height * .5,
                        child: PagedCommunityList<PostComment>(
                          key: ValueKey(_revision),
                          identity: (c) => c.id,
                          load: (cursor) => widget.service.comments(
                            widget.postId,
                            cursor: cursor,
                          ),
                          emptyMessage: 'Aún no hay comentarios.',
                          itemBuilder: (comment) => Card(
                            child: ListTile(
                              title: Text(comment.authorName),
                              subtitle: Text(comment.content),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'delete') {
                                    _remove(comment);
                                  } else {
                                    reportCommunityContent(
                                      context,
                                      widget.service,
                                      'commentId',
                                      comment.id,
                                    );
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'report',
                                    child: Text('Reportar'),
                                  ),
                                  if (comment.isOwner || _isChannelOwner)
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Eliminar'),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_post!.status == 'PUBLISHED')
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _comment,
                            enabled: !_busy,
                            maxLength: 1000,
                            minLines: 1,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Escribe una pregunta o comentario',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Enviar comentario',
                          onPressed: _busy ? null : _send,
                          icon: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(),
                                )
                              : const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
  );
}
