import 'package:flutter/material.dart';
import '../../services/support_service.dart';
import '../../theme/app_theme.dart';
import 'ticket_create_screen.dart';
import 'ticket_detail_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  final SupportService? service;

  const HelpSupportScreen({super.key, this.service});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> with SingleTickerProviderStateMixin {
  late final SupportService _service;
  TabController? _tabController;

  List<SupportTicket> _myTickets = [];
  List<SupportTicket> _allTickets = [];
  SupportMetrics? _metrics;

  bool _isLoading = true;
  bool _isStaff = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? SupportService();
    _checkStaffAndLoad();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _checkStaffAndLoad() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final staff = await _service.isSupportStaff();
      if (!mounted) return;
      _isStaff = staff;
      if (staff) {
        _tabController = TabController(length: 2, vsync: this);
      }

      await _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final myPage = await _service.getMyTickets();
      SupportPage<SupportTicket>? allPage;
      SupportMetrics? metrics;

      if (_isStaff) {
        allPage = await _service.getAllTickets();
        metrics = await _service.getSupportMetrics();
      }

      if (!mounted) return;
      setState(() {
        _myTickets = myPage.items;
        if (allPage != null) _allTickets = allPage.items;
        _metrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
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

  Widget _buildTicketCard(SupportTicket ticket, {bool asStaff = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      color: isDark ? AppTheme.cardDark : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TicketDetailScreen(
                ticketId: ticket.id,
                service: _service,
                isStaff: asStaff,
              ),
            ),
          );
          _loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${ticket.ticketNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusLabel(ticket.status),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: _getStatusColor(ticket.status),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${ticket.updatedAt.day}/${ticket.updatedAt.month}/${ticket.updatedAt.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ticket.subject,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (ticket.lastMessageSnippet != null) ...[
                const SizedBox(height: 4),
                Text(
                  ticket.lastMessageSnippet!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.category_outlined, size: 14, color: isDark ? Colors.grey : Colors.black54),
                  const SizedBox(width: 4),
                  Text(ticket.category, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  if (asStaff && ticket.userName != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.person_outline, size: 14, color: isDark ? Colors.grey : Colors.black54),
                    const SizedBox(width: 4),
                    Text(ticket.userName!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${ticket.messagesCount}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_outlined, size: 48, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Todo en orden',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffConsole() {
    final m = _metrics;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        children: [
          if (m != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Abiertos', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                          Text('${m.openCount}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('En Atención', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                          Text('${m.inProgressCount}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Urgentes', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                          Text('${m.urgentOpenCount}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Bandeja de Tickets Global',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          if (_allTickets.isEmpty)
            _buildEmptyState('No hay tickets en la bandeja de soporte.')
          else
            ..._allTickets.map((t) => _buildTicketCard(t, asStaff: true)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Centro de Ayuda')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Ayuda y Soporte'),
        centerTitle: true,
        bottom: _isStaff && _tabController != null
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.person), text: 'Mis Tickets'),
                  Tab(icon: Icon(Icons.admin_panel_settings), text: 'Consola Staff'),
                ],
              )
            : null,
      ),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 44),
                  const SizedBox(height: 8),
                  Text(_error!),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _loadData, child: const Text('Reintentar')),
                ],
              ),
            )
          : _isStaff && _tabController != null
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      onRefresh: _loadData,
                      child: _myTickets.isEmpty
                          ? _buildEmptyState('No tienes tickets de soporte activos.\nPuedes abrir uno con el botón inferior.')
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.only(top: 12, bottom: 80),
                              itemCount: _myTickets.length,
                              itemBuilder: (ctx, i) => _buildTicketCard(_myTickets[i]),
                            ),
                    ),
                    _buildStaffConsole(),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _myTickets.isEmpty
                      ? _buildEmptyState('No tienes tickets de soporte activos.\nPuedes abrir uno con el botón inferior.')
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.only(top: 12, bottom: 80),
                          itemCount: _myTickets.length,
                          itemBuilder: (ctx, i) => _buildTicketCard(_myTickets[i]),
                        ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TicketCreateScreen(service: _service),
            ),
          );
          if (created != null) {
            _loadData();
          }
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text('Nuevo Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
