import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/private_chat_service.dart';
import '../../widgets/person_avatar.dart';

String _errorText(Object error) => error is Exception
    ? error.toString().replaceFirst('Exception: ', '')
    : 'No se pudo conectar. Inténtalo de nuevo.';

class _ChatList extends StatefulWidget {
  const _ChatList({required this.preBooking});
  final bool preBooking;
  @override
  State<_ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<_ChatList> with WidgetsBindingObserver {
  late final _service = PrivateChatService(preBooking: widget.preBooking);
  final List<Map<String, dynamic>> _chats = [];
  Timer? _timer;
  String? _before, _error;
  bool _busy = false, _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_foreground && TickerMode.valuesOf(context).enabled && (ModalRoute.of(context)?.isCurrent ?? false) && _chats.length <= 30) _load();
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
  }
  Future<void> _load({bool more = false}) async {
    if (_busy || (more && _before == null)) return;
    setState(() => _busy = true);
    try {
      final data = await _service.request(more ? '?before=$_before' : '');
      if (!mounted) return;
      setState(() {
        if (!more) _chats.clear();
        _chats.addAll((data['chats'] as List).cast<Map<String, dynamic>>());
        _before = data['nextBefore'] as String?;
        _error = null;
      });
    } catch (error) { if (mounted) setState(() => _error = _errorText(error)); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _service.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: RefreshIndicator(onRefresh: _load, child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (_busy) const LinearProgressIndicator(),
        Padding(padding: const EdgeInsets.all(16), child: Text(widget.preBooking
          ? 'Dudas generales antes de reservar. No es terapia ni atención de emergencias.'
          : 'Historial separado por cita. Las sesiones completadas o canceladas son de solo lectura.')),
        if (_error != null) ListTile(title: Text(_error!), trailing: IconButton(
          icon: const Icon(Icons.refresh), onPressed: _load)),
        if (!_busy && _chats.isEmpty && _error == null)
          Padding(padding: const EdgeInsets.all(24), child: Text(widget.preBooking ? 'Contacta un profesional desde Explore para iniciar una conversación.' : 'Aquí aparecerán los chats de tus citas confirmadas.')),
        ..._chats.map((chat) => ListTile(
          leading: PersonAvatar(name: chat['peerName'] as String, photoUrl: chat['peerPhotoUrl']),
          title: Text(chat['peerName'] as String),
          subtitle: Text('${DateTime.parse(chat['startAt'] ?? chat['createdAt']).toLocal().toString().substring(0, 16)} · ${chat['canSend'] == true ? 'Disponible' : 'Solo lectura'}'),
          trailing: (chat['unreadCount'] as int) > 0 ? CircleAvatar(
            radius: 15, child: Text('${chat['unreadCount']}')) : null,
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => PrivateChatScreen(
              appointmentId: (chat['appointmentId'] ?? chat['conversationId']) as String, peerName: chat['peerName'] as String, preBooking: widget.preBooking)));
            if (mounted) _load();
          },
        )),
        if (_before != null) TextButton(onPressed: _busy ? null : () => _load(more: true), child: const Text('Cargar más conversaciones')),
      ],
    )),
  );
}

class PrivateChatScreen extends StatefulWidget {
  const PrivateChatScreen({super.key, required this.appointmentId, required this.peerName, this.preBooking = false, this.service});
  final PrivateChatService? service;
  final bool preBooking;
  final String appointmentId, peerName;
  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> with WidgetsBindingObserver {
  late final _service = widget.service ?? PrivateChatService(preBooking: widget.preBooking);
  final _input = TextEditingController();
  final Map<int, Map<String, dynamic>> _messages = {};
  Timer? _timer;
  int? _before;
  String? _viewer, _error, _retryId, _retryContent, _peerPhoto;
  bool _blockedByMe = false;
  bool _busy = false, _sending = false, _canSend = false, _foreground = true;
  bool get _visible => _foreground && (ModalRoute.of(context)?.isCurrent ?? false);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) { if (_visible) _load(); });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && _visible) _load();
  }
  Future<void> _load({bool older = false}) async {
    if (_busy || (older && _before == null)) return;
    setState(() => _busy = true);
    try {
      final data = await _service.request('/${widget.appointmentId}/messages${older ? '?before=$_before' : ''}');
      if (!mounted || !_visible) return;
      final rows = (data['messages'] as List).cast<Map<String, dynamic>>();
      setState(() {
        final overlaps = rows.any((m) => _messages.containsKey(m['sequence']));
        if (!older && _messages.isNotEmpty && rows.length == 50 && !overlaps) _messages.clear();
        final firstPage = _messages.isEmpty;
        for (final row in rows) { _messages[row['sequence'] as int] = row; }
        if (older || firstPage) _before = data['nextBefore'] as int?;
        _viewer = data['viewerId'] as String;
        _canSend = data['canSend'] == true;
        _blockedByMe = data['blockedByMe'] == true;
        _peerPhoto = data['peerPhotoUrl'];
        _error = null;
      });
      if (rows.isNotEmpty && _visible) {
        await _service.request('/${widget.appointmentId}/read', body: {'through': rows.last['sequence']});
      }
    } catch (error) {
      if (mounted) setState(() { _error = _errorText(error); _canSend = false; });
    } finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _send() async {
    final content = _input.text.trim();
    if (_sending || !_canSend || content.isEmpty) return;
    if (_retryContent != content) {
      _retryId = PrivateChatService.clientId();
      _retryContent = content;
    }
    setState(() => _sending = true);
    try {
      final data = await _service.request('/${widget.appointmentId}/messages', body: {'clientId': _retryId, 'content': content});
      if (!mounted) return;
      final row = data['message'] as Map<String, dynamic>;
      setState(() {
        _messages[row['sequence'] as int] = row;
        _input.clear(); _retryContent = null; _retryId = null; _error = null;
      });
    } catch (error) { if (mounted) setState(() => _error = '${_errorText(error)} Tu texto se conserva; puedes reintentar.'); }
    finally { if (mounted) setState(() => _sending = false); }
  }
  @override
  void dispose() {
    _timer?.cancel(); WidgetsBinding.instance.removeObserver(this);
    _input.dispose(); _service.dispose(); super.dispose();
  }

  Future<void> _action(String action) async {
    if (action == 'block') {
      final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: Text(_blockedByMe ? 'Desbloquear contacto' : 'Bloquear contacto'),
        content: const Text('El bloqueo impide nuevos mensajes en esta conversación. El historial y las citas se conservan.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar'))]));
      if (confirmed != true || !mounted) return;
      try { await _service.request('/${widget.appointmentId}/block', body: {'blocked': !_blockedByMe}); if (mounted) await _load(); }
      catch (e) { if (mounted) setState(() => _error = _errorText(e)); }
    } else {
      final controller = TextEditingController();
      final description = await showDialog<String>(context: context, builder: (context) => AlertDialog(
        title: const Text('Reportar contacto'),
        content: TextField(controller: controller, maxLength: 2000, minLines: 3, maxLines: 6,
          decoration: const InputDecoration(hintText: 'Describe lo ocurrido (mínimo 10 caracteres). No incluyas información clínica innecesaria.')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () { if (controller.text.trim().length >= 10) Navigator.pop(context, controller.text.trim()); },
            child: const Text('Enviar reporte'))]));
      // Let the dialog finish its closing animation before disposing its controller.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      controller.dispose();
      if (description == null || !mounted) return;
      try {
        await _service.request('/${widget.appointmentId}/report', body: {'description': description});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte enviado al equipo de soporte.')));
      } catch (e) { if (mounted) setState(() => _error = _errorText(e)); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _messages.values.toList()..sort((a, b) => (b['sequence'] as int).compareTo(a['sequence'] as int));
    final dark = Theme.of(context).brightness == Brightness.dark;
    const turquoise = Color(0xFF09D5DC);
    final surface = dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF112121) : Colors.white,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.peerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(widget.preBooking ? 'Consulta previa' : 'Chat de sesión', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
        actions: [
          IconButton(tooltip: 'Actualizar', onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh)),
          if (widget.preBooking) PopupMenuButton<String>(onSelected: _action, itemBuilder: (_) => [
            PopupMenuItem(value: 'block', child: Text(_blockedByMe ? 'Desbloquear' : 'Bloquear contacto')),
            const PopupMenuItem(value: 'report', child: Text('Reportar contacto')),
          ]),
        ]),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Chip(
          avatar: const Icon(Icons.lock_outline, size: 16), label: Text(widget.preBooking ? 'CONTACTO PRIVADO' : 'CHAT DE SESIÓN'))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Text(
          widget.preBooking
            ? 'Solo dudas generales del servicio. No sustituye una consulta psicológica ni es atención de emergencias. La respuesta puede no ser inmediata.'
            : 'Mensajes asociados a esta cita. No es atención de emergencias.',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey))),
        if (_busy) const LinearProgressIndicator(minHeight: 2),
        if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        Expanded(child: rows.isEmpty && !_busy
          ? const Center(child: Text('Aún no hay mensajes.'))
          : ListView.builder(reverse: true, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: rows.length + (_before != null ? 1 : 0), itemBuilder: (context, index) {
              if (index == rows.length) return TextButton(onPressed: _busy ? null : () => _load(older: true), child: const Text('Mensajes anteriores'));
              final row = rows[index], mine = row['senderId'] == _viewer;
              final date = DateTime.parse(row['createdAt']).toLocal();
              final label = '${date.day}/${date.month}/${date.year}';
              final previous = index + 1 < rows.length ? DateTime.parse(rows[index + 1]['createdAt']).toLocal() : null;
              final showDate = previous == null || previous.year != date.year || previous.month != date.month || previous.day != date.day;
              return Column(children: [
                if (showDate) Padding(padding: const EdgeInsets.all(16), child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))),
                Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(
                  mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end, children: [
                    if (!mine) ...[PersonAvatar(name: widget.peerName, photoUrl: _peerPhoto, size: 32), const SizedBox(width: 8)],
                    Flexible(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .72),
                      child: Column(crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                        Padding(padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4), child: Text(mine ? 'Tú' : widget.peerName,
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600))),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(color: mine ? turquoise : surface, borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(22), topRight: const Radius.circular(22),
                            bottomLeft: Radius.circular(mine ? 22 : 3), bottomRight: Radius.circular(mine ? 3 : 22))),
                          child: SelectableText(row['content'] as String, style: TextStyle(fontSize: 15, height: 1.45,
                            color: mine ? const Color(0xFF0F172A) : (dark ? Colors.white : const Color(0xFF0F172A))))),
                        const SizedBox(height: 5),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          if (mine) ...[const SizedBox(width: 5), Icon(row['readAt'] == null ? Icons.done : Icons.done_all,
                            size: 15, color: row['readAt'] == null ? Colors.grey : turquoise)],
                        ]),
                      ]))),
                  ])),
              ]);
            })),
        if (!_canSend && _error == null && !_busy) Padding(padding: const EdgeInsets.all(12), child: Text(
          widget.preBooking ? 'Solo lectura: contacto bloqueado o cuenta no habilitada.'
            : 'Solo lectura: la cita terminó, fue cancelada o no está habilitada.', style: const TextStyle(fontSize: 12))),
        Container(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), decoration: BoxDecoration(border: Border(top: BorderSide(color: surface))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: TextField(controller: _input, enabled: !_sending && _canSend, minLines: 1, maxLines: 4, maxLength: 4000,
              decoration: InputDecoration(hintText: 'Escribe un mensaje…', filled: true, fillColor: surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13)))),
            const SizedBox(width: 10),
            Padding(padding: const EdgeInsets.only(bottom: 24), child: IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: turquoise, foregroundColor: const Color(0xFF0F172A), padding: const EdgeInsets.all(14)),
              tooltip: 'Enviar mensaje', onPressed: _sending || !_canSend ? null : _send,
              icon: _sending ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator()) : const Icon(Icons.send))),
          ])),
      ])),
    );
  }
}

class PrivateChatInbox extends StatelessWidget {
  const PrivateChatInbox({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(length: 2, child: Scaffold(
    appBar: AppBar(title: const Text('Mensajes'), bottom: const TabBar(tabs: [
      Tab(text: 'Consultas previas'), Tab(text: 'Sesiones'),
    ])),
    body: const TabBarView(children: [_ChatList(preBooking: true), _ChatList(preBooking: false)]),
  ));
}

Future<void> openPreBookingChat(BuildContext context, {required String psychologistId, required String name}) async {
  final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
    title: Text('Contactar a $name'),
    content: const Text('Este chat es para preguntar por modalidades, horarios y servicios antes de reservar. No es terapia ni atención de emergencias.'),
    actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Abrir conversación'))]));
  if (confirmed != true || !context.mounted) return;
  final service = PrivateChatService(preBooking: true);
  try {
    final data = await service.request('/pre-booking/$psychologistId', body: {});
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PrivateChatScreen(
      appointmentId: data['conversationId'], peerName: data['peerName'], preBooking: true)));
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorText(e))));
  } finally { service.dispose(); }
}
