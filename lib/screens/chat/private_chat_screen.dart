import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/private_chat_service.dart';

String _errorText(Object error) => error is Exception
    ? error.toString().replaceFirst('Exception: ', '')
    : 'No se pudo conectar. Inténtalo de nuevo.';

class PrivateChatInbox extends StatefulWidget {
  const PrivateChatInbox({super.key});
  @override
  State<PrivateChatInbox> createState() => _PrivateChatInboxState();
}

class _PrivateChatInboxState extends State<PrivateChatInbox> with WidgetsBindingObserver {
  final _service = PrivateChatService();
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
      if (_foreground && (ModalRoute.of(context)?.isCurrent ?? false) && _chats.length <= 30) _load();
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
    appBar: AppBar(title: const Text('Mensajes privados')),
    body: RefreshIndicator(onRefresh: _load, child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (_busy) const LinearProgressIndicator(),
        const Padding(padding: EdgeInsets.all(16), child: Text(
          'Conversaciones por cita. No es un servicio de emergencias ni garantiza respuesta inmediata.')),
        if (_error != null) ListTile(title: Text(_error!), trailing: IconButton(
          icon: const Icon(Icons.refresh), onPressed: _load)),
        if (!_busy && _chats.isEmpty && _error == null)
          const Padding(padding: EdgeInsets.all(24), child: Text('El chat estará disponible cuando tengas una cita confirmada.')),
        ..._chats.map((chat) => ListTile(
          leading: const Icon(Icons.chat_bubble_outline),
          title: Text(chat['peerName'] as String),
          subtitle: Text('${DateTime.parse(chat['startAt']).toLocal().toString().substring(0, 16)} · ${chat['canSend'] == true ? 'Disponible' : 'Solo lectura'}'),
          trailing: (chat['unreadCount'] as int) > 0 ? CircleAvatar(
            radius: 15, child: Text('${chat['unreadCount']}')) : null,
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => PrivateChatScreen(
              appointmentId: chat['appointmentId'] as String, peerName: chat['peerName'] as String)));
            if (mounted) _load();
          },
        )),
        if (_before != null) TextButton(onPressed: _busy ? null : () => _load(more: true), child: const Text('Cargar más conversaciones')),
      ],
    )),
  );
}

class PrivateChatScreen extends StatefulWidget {
  const PrivateChatScreen({super.key, required this.appointmentId, required this.peerName});
  final String appointmentId, peerName;
  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> with WidgetsBindingObserver {
  final _service = PrivateChatService();
  final _input = TextEditingController();
  final Map<int, Map<String, dynamic>> _messages = {};
  Timer? _timer;
  int? _before;
  String? _viewer, _error, _retryId, _retryContent;
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
  @override
  Widget build(BuildContext context) {
    final rows = _messages.values.toList()..sort((a, b) => (b['sequence'] as int).compareTo(a['sequence'] as int));
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName), actions: [IconButton(
        tooltip: 'Actualizar', onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Column(children: [
        const Padding(padding: EdgeInsets.all(12), child: Text(
          'No es atención de emergencias. La respuesta puede no ser inmediata.', style: TextStyle(fontSize: 12))),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        Expanded(child: ListView.builder(reverse: true, padding: const EdgeInsets.all(12),
          itemCount: rows.length + (_before != null ? 1 : 0), itemBuilder: (context, index) {
            if (index == rows.length) return TextButton(onPressed: _busy ? null : () => _load(older: true), child: const Text('Mensajes anteriores'));
            final row = rows[index];
            final mine = row['senderId'] == _viewer;
            return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(constraints: const BoxConstraints(maxWidth: 330), margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12), decoration: BoxDecoration(
                  color: mine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SelectableText(row['content'] as String),
                  const SizedBox(height: 4),
                  Text('${DateTime.parse(row['createdAt']).toLocal().toString().substring(0, 16)}${mine ? (row['readAt'] == null ? ' · Enviado' : ' · Leído') : ''}', style: const TextStyle(fontSize: 10)),
                ])));
          })),
        if (!_canSend && _error == null && !_busy)
          const Padding(padding: EdgeInsets.all(12), child: Text('Conversación en modo lectura. El envío requiere una cita habilitada y termina 7 días después de su horario de fin.')),
        Padding(padding: const EdgeInsets.all(8), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: TextField(controller: _input, enabled: !_sending && _canSend, minLines: 1, maxLines: 4,
            maxLength: 4000, decoration: const InputDecoration(hintText: 'Escribe un mensaje', border: OutlineInputBorder()))),
          IconButton(tooltip: 'Enviar mensaje', onPressed: _sending || !_canSend ? null : _send,
            icon: _sending ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator()) : const Icon(Icons.send)),
        ])),
      ])),
    );
  }
}
