import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';

class PatientPaymentHistoryScreen extends StatefulWidget {
  const PatientPaymentHistoryScreen({super.key});

  @override
  State<PatientPaymentHistoryScreen> createState() => _PatientPaymentHistoryScreenState();
}

class _PatientPaymentHistoryScreenState extends State<PatientPaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = true;
  String? _errorMessage;
  List<PaymentRecord> _payments = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _paymentService.getPatientPaymentHistory();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _payments = res['payments'] ?? [];
        } else {
          _errorMessage = res['message'] ?? 'Error al cargar el historial de pagos';
        }
      });
    }
  }

  void _showReceiptModal(String paymentId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReceiptSheet(paymentId: paymentId),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$min';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pagos y Recibos'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _fetchHistory, child: const Text('Reintentar')),
                        ],
                      ),
                    ),
                  )
                : _payments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            const Text(
                              'Aún no tienes pagos registrados',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Aquí verás los recibos y cargos de tus consultas.',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        itemCount: _payments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final p = _payments[index];
                          final isSucceeded = p.status == 'SUCCEEDED';
                          final isRefunded = p.status == 'REFUNDED';

                          Color badgeColor = Colors.grey;
                          Color badgeTextColor = Colors.white;
                          String badgeLabel = p.status;

                          if (isSucceeded) {
                            badgeColor = Colors.green.withValues(alpha: 0.15);
                            badgeTextColor = Colors.green.shade700;
                            badgeLabel = 'Pagado';
                          } else if (isRefunded) {
                            badgeColor = Colors.orange.withValues(alpha: 0.15);
                            badgeTextColor = Colors.orange.shade800;
                            badgeLabel = 'Reembolsado';
                          } else if (p.status == 'REFUND_PENDING') {
                            badgeColor = Colors.orange;
                            badgeLabel = 'Reembolso pendiente';
                          } else if (p.status == 'PROCESSING' || p.status == 'PENDING') {
                            badgeColor = Colors.blueGrey;
                            badgeLabel = 'Pago pendiente';
                          } else if (p.status == 'FAILED') {
                            badgeColor = Colors.red.withValues(alpha: 0.15);
                            badgeTextColor = Colors.red.shade700;
                            badgeLabel = 'Declinado';
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.psychologistName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: badgeColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        badgeLabel,
                                        style: TextStyle(
                                          color: badgeTextColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 14, color: isDark ? Colors.grey : Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatDate(p.createdAt),
                                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          p.cardBrand == 'MASTERCARD' ? Icons.credit_card : Icons.payment,
                                          size: 18,
                                          color: AppTheme.primaryDark,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          p.cardLast4 != null ? '${p.cardBrand ?? 'Tarjeta'} •••• ${p.cardLast4}' : 'Tarjeta digital',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '\$${p.amount.toStringAsFixed(2)} ${p.currency}',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showReceiptModal(p.id),
                                    icon: const Icon(Icons.receipt_outlined, size: 16),
                                    label: const Text('Ver Recibo Digital'),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _ReceiptSheet extends StatefulWidget {
  final String paymentId;
  const _ReceiptSheet({required this.paymentId});

  @override
  State<_ReceiptSheet> createState() => _ReceiptSheetState();
}

class _ReceiptSheetState extends State<_ReceiptSheet> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = true;
  String? _error;
  DigitalReceipt? _receipt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _paymentService.getPaymentReceipt(widget.paymentId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _receipt = res['receipt'];
        } else {
          _error = res['message'] ?? 'No se pudo obtener el recibo';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _isLoading
          ? const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recibo de Pago', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildRow('Folio:', _receipt!.receiptNumber, isBold: true),
                    const SizedBox(height: 10),
                    _buildRow('Fecha:', _receipt!.date.sliceSafe(0, 10)),
                    const SizedBox(height: 10),
                    _buildRow('Profesional:', _receipt!.psychologistName),
                    const SizedBox(height: 10),
                    _buildRow('Paciente:', _receipt!.patientName),
                    const SizedBox(height: 10),
                    _buildRow('Método de pago:', '${_receipt!.cardBrand ?? 'Tarjeta'} •••• ${_receipt!.cardLast4 ?? '****'}'),
                    const Divider(height: 24),
                    _buildRow('Tarifa de consulta:', '\$${_receipt!.amount.toStringAsFixed(2)} ${_receipt!.currency}'),
                    const SizedBox(height: 10),
                    _buildRow('Total pagado:', '\$${_receipt!.amount.toStringAsFixed(2)} ${_receipt!.currency}',
                        isBold: true, color: AppTheme.primaryDark),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Cerrar Recibo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}

extension StringSlice on String {
  String sliceSafe(int start, int end) {
    if (length <= start) return this;
    if (length < end) return substring(start);
    return substring(start, end);
  }
}
