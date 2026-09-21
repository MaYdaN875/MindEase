import 'package:flutter/material.dart';
import '../../services/support_service.dart';
import '../../theme/app_theme.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  final SupportService? service;
  final bool isStaff;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    this.service,
    this.isStaff = false,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late final SupportService _service;
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  SupportTicket? _ticket;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isInternalNote = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? SupportService();
    _loadTicket();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTicket() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ticket = await _service.getTicketById(widget.ticketId);
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _ticket == null) return;

    setState(() => _isSending = true);

    try {
      if (widget.isStaff) {
        await _service.addAgentMessage(
          _ticket!.id,
          content: text,
          isInternalNote: _isInternalNote,
        );
      } else {
        await _service.addMessage(_ticket!.id, content: text);
      }

      _messageCtrl.clear();
      _isInternalNote = false;
      await _loadTicket();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _closeTicket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar este ticket?'),
        content: const Text('El ticket pasará a estado cerrado. Podrás abrir un nuevo ticket si necesitas más ayuda.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('Cerrar ticket'),
          ),
        ],
      ),
    );

    if (confirmed != true || _ticket == null) return;

    try {
      final updated = await _service.closeTicket(_ticket!.id);
      if (!mounted) return;
      setState(() => _ticket = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket cerrado correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'WAITING_USER':
        return Colors.purple;
      case 'RESOLVED':
        return Colors.green;
      case 'CLOSED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'OPEN':
        return 'Abierto';
      case 'IN_PROGRESS':
        return 'En atención';
      case 'WAITING_USER':
        return 'Esperando respuesta';
      case 'RESOLVED':
        return 'Resuelto';
      case 'CLOSED':
        return 'Cerrado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando ticket...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                const SizedBox(height: 12),
                Text(_error ?? 'No se pudo cargar el ticket'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadTicket, child: const Text('Reintentar')),
              ],
            ),
          ),
        ),
      );
    }

    final ticket = _ticket!;
    final isClosed = ticket.status == 'CLOSED';

    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #${ticket.ticketNumber}'),
        centerTitle: true,
        actions: [
          if (!isClosed)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Cerrar ticket',
              onPressed: _closeTicket,
            ),
        ],
      ),
      body: Column(
        children: [
          // Header summary card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.subject,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(ticket.status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusLabel(ticket.status),
                        style: TextStyle(
                          color: _getStatusColor(ticket.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Categoría: ${ticket.category}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Prioridad: ${ticket.priority}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                    if (ticket.assignedToName != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        'Agente: ${ticket.assignedToName}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Messages conversation list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTicket,
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: ticket.messages.length,
                itemBuilder: (context, index) {
                  final msg = ticket.messages[index];
                  final isMe = msg.isMine;
                  final isInternal = msg.isInternalNote;

                  if (isInternal) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lock_outline, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                'Nota Interna • ${msg.senderName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(msg.content, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AppTheme.primary
                            : (isDark ? AppTheme.cardDark : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(
                              msg.senderName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          Text(
                            msg.content,
                            style: TextStyle(
                              color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Message input bar
          if (!isClosed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                border: Border(top: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isStaff)
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Respuesta pública', style: TextStyle(fontSize: 12)),
                            selected: !_isInternalNote,
                            onSelected: (s) => setState(() => _isInternalNote = !s),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline, size: 14),
                                SizedBox(width: 4),
                                Text('Nota interna', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            selected: _isInternalNote,
                            selectedColor: Colors.amber.withValues(alpha: 0.3),
                            onSelected: (s) => setState(() => _isInternalNote = s),
                          ),
                        ],
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageCtrl,
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: _isInternalNote ? 'Escribe una nota interna para el staff...' : 'Escribe tu respuesta...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: isDark ? AppTheme.bgDark : const Color(0xFFF1F5F9),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isSending ? null : _sendMessage,
                          icon: _isSending
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(Icons.send, color: _isInternalNote ? Colors.amber : AppTheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? AppTheme.cardDark : const Color(0xFFF8FAFC),
              child: const SafeArea(
                child: Center(
                  child: Text(
                    'Este ticket está cerrado. Para nueva asistencia, abre un nuevo ticket.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
