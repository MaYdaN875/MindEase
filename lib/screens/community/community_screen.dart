import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import 'community_widgets.dart';
import 'community_post_screen.dart';
import 'community_editors.dart';

class CommunityScreen extends StatefulWidget {
  final CommunityService? service;
  final bool management;
  final VoidCallback? onToggleTheme, onOpenNotifications;
  const CommunityScreen({
    super.key,
    this.service,
    this.management = false,
    this.onToggleTheme,
    this.onOpenNotifications,
  });
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late final _service = widget.service ?? CommunityService();
  final _search = TextEditingController();
  List<CommunityCategory>? _categories;
  String? _category, _error;
  bool _following = false, _posts = false, _allowed = false;
  String _query = '';
  int _revision = 0;
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _search.dispose();
    if (widget.service == null) _service.close();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _error = null);
    try {
      final allowed = !widget.management || await _service.canManage();
      final categories = await _service.categories();
      if (mounted) {
        setState(() {
          _allowed = allowed;
          _categories = categories;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _create() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChannelEditor(service: _service, categories: _categories!),
      ),
    );
    if (changed == true && mounted) setState(() => _revision++);
  }

  Future<void> _open(CommunityChannel channel) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityChannelScreen(
          channelId: channel.id,
          service: _service,
          categories: _categories!,
          management: widget.management && _allowed,
        ),
      ),
    );
    if (mounted) setState(() => _revision++);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.management ? 'Community profesional' : 'Community'),
      actions: [
        if (widget.onOpenNotifications != null)
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: widget.onOpenNotifications,
            icon: const Icon(Icons.notifications_outlined),
          ),
        if (widget.onToggleTheme != null)
          IconButton(
            tooltip: 'Cambiar tema',
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.brightness_6_outlined),
          ),
      ],
    ),
    floatingActionButton: widget.management && _allowed && _categories != null
        ? FloatingActionButton.extended(
            onPressed: _categories!.isEmpty ? null : _create,
            icon: const Icon(Icons.add),
            label: const Text('Crear canal'),
          )
        : null,
    body: _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                TextButton(
                  onPressed: _initialize,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          )
        : _categories == null
        ? const Center(child: CircularProgressIndicator())
        : !_allowed
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Necesitas una cuenta activa con rol y acreditación profesional verificados para gestionar Community.',
              ),
            ),
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  widget.management
                      ? 'Tus canales y publicaciones educativas. Selecciona un canal para publicar o gestionar sus borradores.'
                      : 'Aprende con canales profesionales. Contenido educativo, no consultas individuales ni chat de urgencias.',
                ),
              ),
              if (!widget.management)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('Canales'),
                              icon: Icon(Icons.campaign_outlined),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('Feed'),
                              icon: Icon(Icons.dynamic_feed),
                            ),
                          ],
                          selected: {_posts},
                          onSelectionChanged: (v) =>
                              setState(() => _posts = v.first),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _category ?? '',
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Todas las categorías'),
                          ),
                          ..._categories!.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _category = v == '' ? null : v),
                      ),
                    ),
                    if (!widget.management)
                      FilterChip(
                        label: const Text('Siguiendo'),
                        selected: _following,
                        onSelected: (v) => setState(() => _following = v),
                      ),
                  ],
                ),
              ),
              if (!_posts)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      labelText: 'Buscar canales',
                      suffixIcon: IconButton(
                        tooltip: 'Buscar',
                        onPressed: () => setState(() => _query = _search.text),
                        icon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: _posts && !widget.management
                    ? PagedCommunityList<CommunityPost>(
                        key: ValueKey(
                          'posts-$_category-$_following-$_revision',
                        ),
                        identity: (p) => p.id,
                        load: (cursor) => _service.posts(
                          cursor: cursor,
                          category: _category,
                          following: _following,
                        ),
                        itemBuilder: (p) => CommunityPostCard(
                          key: ValueKey(p.id),
                          post: p,
                          service: _service,
                        ),
                        emptyMessage: _following
                            ? 'Sigue canales para ver sus publicaciones aquí.'
                            : 'Aún no hay publicaciones en esta categoría.',
                      )
                    : PagedCommunityList<CommunityChannel>(
                        key: ValueKey(
                          'channels-$_category-$_following-$_query-$_revision',
                        ),
                        identity: (c) => c.id,
                        load: (cursor) => _service.channels(
                          cursor: cursor,
                          category: _category,
                          search: _query,
                          following: _following,
                          mine: widget.management,
                        ),
                        emptyMessage: widget.management
                            ? 'Todavía no tienes canales. Crea uno para comenzar.'
                            : 'No se encontraron canales con estos filtros.',
                        itemBuilder: (c) => Card(
                          child: ListTile(
                            leading:
                                c.coverImageUrl != null &&
                                    _service.mediaUri(c.coverImageUrl!) != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _service
                                          .mediaUri(c.coverImageUrl!)!
                                          .toString(),
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          const Icon(Icons.campaign),
                                    ),
                                  )
                                : const Icon(Icons.campaign_outlined),
                            title: Text(c.name),
                            subtitle: Text(
                              '${c.psychologistName}\n${c.category.name} · ${c.followersCount} seguidores · ${c.postsCount} publicaciones',
                            ),
                            trailing: Icon(
                              c.isFollowing
                                  ? Icons.check_circle_outline
                                  : Icons.chevron_right,
                            ),
                            onTap: () => _open(c),
                          ),
                        ),
                      ),
              ),
            ],
          ),
  );
}

class CommunityChannelScreen extends StatefulWidget {
  final String channelId;
  final CommunityService service;
  final List<CommunityCategory> categories;
  final bool management;
  const CommunityChannelScreen({
    super.key,
    required this.channelId,
    required this.service,
    required this.categories,
    this.management = false,
  });
  @override
  State<CommunityChannelScreen> createState() => _CommunityChannelScreenState();
}

class _CommunityChannelScreenState extends State<CommunityChannelScreen> {
  CommunityChannel? _channel;
  String? _error;
  bool _busy = false;
  String _status = 'PUBLISHED';
  int _revision = 0;
  bool get _manage => widget.management && _channel?.isOwner == true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await widget.service.channel(widget.channelId);
      if (mounted) {
        setState(() {
          _channel = c;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _channel = null;
        });
      }
    }
  }

  Future<void> _follow() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.service.follow(widget.channelId);
    } catch (e) {
      if (mounted) communityMessage(context, e);
    } finally {
      await _load();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editChannel() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChannelEditor(
          service: widget.service,
          categories: widget.categories,
          channel: _channel,
        ),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _editPost([CommunityPost? post]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityPostEditor(
          service: widget.service,
          channel: _channel!,
          post: post,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _revision++);
      await _load();
    }
  }

  Future<void> _archive(CommunityPost post) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Archivar publicación?'),
        content: const Text(
          'Dejará de mostrarse a los pacientes. Puedes recuperarla desde Archivados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await widget.service.archivePost(post.id);
      if (mounted) setState(() => _revision++);
    } catch (e) {
      if (mounted) communityMessage(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_channel?.name ?? 'Canal'),
      actions: [
        if (_manage)
          IconButton(
            tooltip: 'Editar canal',
            onPressed: _editChannel,
            icon: const Icon(Icons.edit_outlined),
          ),
        if (_channel != null)
          IconButton(
            tooltip: 'Reportar canal',
            onPressed: () => reportCommunityContent(
              context,
              widget.service,
              'channelId',
              widget.channelId,
            ),
            icon: const Icon(Icons.flag_outlined),
          ),
      ],
    ),
    floatingActionButton: _manage
        ? FloatingActionButton.extended(
            onPressed: _editPost,
            icon: const Icon(Icons.add),
            label: const Text('Publicar'),
          )
        : null,
    body: _channel == null
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
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .32,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_channel!.psychologistName} · ${_channel!.category.name}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(_channel!.description),
                        const SizedBox(height: 8),
                        Text('${_channel!.followersCount} seguidores'),
                        if (!_manage)
                          FilledButton.icon(
                            onPressed: _busy ? null : _follow,
                            icon: Icon(
                              _channel!.isFollowing ? Icons.check : Icons.add,
                            ),
                            label: Text(
                              _channel!.isFollowing
                                  ? 'Dejar de seguir'
                                  : 'Seguir canal',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_manage)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _status,
                    items:
                        const {
                              'PUBLISHED': 'Publicados',
                              'DRAFT': 'Borradores',
                              'ARCHIVED': 'Archivados',
                            }.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
              Expanded(
                child: PagedCommunityList<CommunityPost>(
                  key: ValueKey('$_status-$_revision'),
                  identity: (p) => p.id,
                  load: (cursor) => widget.service.posts(
                    channelId: widget.channelId,
                    status: _manage ? _status : 'PUBLISHED',
                    mine: _manage,
                    cursor: cursor,
                  ),
                  emptyMessage: 'Todavía no hay publicaciones en esta sección.',
                  itemBuilder: (p) => CommunityPostCard(
                    key: ValueKey(p.id),
                    post: p,
                    service: widget.service,
                    onEdit: _manage ? () => _editPost(p) : null,
                    onArchive: _manage && p.status != 'ARCHIVED'
                        ? () => _archive(p)
                        : null,
                  ),
                ),
              ),
            ],
          ),
  );
}
