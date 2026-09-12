import 'package:flutter/material.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';

class PsychologistEarningsScreen extends StatefulWidget {
  const PsychologistEarningsScreen({super.key});

  @override
  State<PsychologistEarningsScreen> createState() => _PsychologistEarningsScreenState();
}

class _PsychologistEarningsScreenState extends State<PsychologistEarningsScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = true;
  String? _errorMessage;
  EarningsSummary? _financials;

  @override
  void initState() {
    super.initState();
    _loadFinancials();
  }

  Future<void> _loadFinancials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _paymentService.getPsychologistEarnings();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _financials = res['financials'];
        } else {
          _errorMessage = res['message'] ?? 'Error al cargar información financiera';
        }
      });
    }
  }

  void _showPayoutModal() {
    if (_financials == null) return;
    final available = _financials!.availableBalance;

    if (available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes saldo disponible para retiro actualmente. Las consultas deben estar concluidas.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final amountController = TextEditingController(text: available.toStringAsFixed(2));
    final bankController = TextEditingController(text: 'BBVA México');
    final clabeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.account_balance_wallet, color: AppTheme.primaryDark),
                SizedBox(width: 8),
                Text('Solicitar Retiro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo disponible: \$${available.toStringAsFixed(2)} MXN',
                      style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Monto a retirar (MXN)',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Ingresa un monto';
                        final numVal = double.tryParse(val.trim());
                        if (numVal == null || numVal <= 0) return 'Monto inválido';
                        if (numVal > available) return 'Supera el saldo disponible';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: bankController,
                      decoration: InputDecoration(
                        labelText: 'Institución Bancaria',
                        hintText: 'Ej. BBVA, Santander, Banamex',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el nombre del banco' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: clabeController,
                      keyboardType: TextInputType.number,
                      maxLength: 18,
                      decoration: InputDecoration(
                        labelText: 'CLABE Interbancaria (18 dígitos)',
                        hintText: '012180015487965213',
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Ingresa la cuenta CLABE';
                        if (val.trim().length != 18 || !RegExp(r'^\d{18}$').hasMatch(val.trim())) {
                          return 'Debe contener exactamente 18 dígitos';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setModalState(() => isSubmitting = true);

                        final amount = double.parse(amountController.text.trim());
                        final res = await _paymentService.requestPayout(
                          amount: amount,
                          bankName: bankController.text.trim(),
                          accountClabe: clabeController.text.trim(),
                        );

                        if (!mounted) return;
                        if (dialogCtx.mounted) {
                          Navigator.of(dialogCtx).pop();
                        }

                        if (res['success'] == true) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Solicitud de retiro registrada.'),
                              backgroundColor: AppTheme.primaryDark,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          _loadFinancials();
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Error al solicitar retiro.'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.textDark,
                ),
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Confirmar Retiro', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      final m = months[dt.month - 1];
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$day $m, $hour:$min';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Ingresos'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFinancials,
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
                            ElevatedButton(onPressed: _loadFinancials, child: const Text('Reintentar')),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ingresos',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                ),
                              ),
                              Text(
                                'Actualizado en tiempo real',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Saldo disponible (Hero card)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'SALDO DISPONIBLE PARA RETIRO',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                                    ),
                                    Icon(Icons.verified, size: 16, color: Colors.green),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$${_financials!.availableBalance.toStringAsFixed(2)} ${_financials!.currency}',
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _showPayoutModal,
                                  icon: const Icon(Icons.account_balance_wallet, size: 18),
                                  label: const Text('Solicitar retiro de fondos', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: AppTheme.textDark,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    minimumSize: const Size(double.infinity, 44),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // KPI Cards: Fondos en Custodia & Retiros en Proceso
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.cardDark : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(Icons.lock_clock_outlined, color: Colors.orange, size: 20),
                                          Text('Custodia', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('Saldo en custodia', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '\$${_financials!.heldBalance.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.cardDark : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(Icons.hourglass_top, color: AppTheme.primaryDark, size: 20),
                                          Text('En Proceso', style: TextStyle(fontSize: 10, color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('Retiros solicitados', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '\$${_financials!.pendingPayoutBalance.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Platform fee notice
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.bgDark.withValues(alpha: 0.5) : AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Comisiones de plataforma (15%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Total retenido por plataforma: \$${_financials!.lifetimePlatformFees.toStringAsFixed(2)} MXN. Las comisiones sostienen la infraestructura médica y pasarelas de pago seguras.',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Monthly Breakdown if available
                          if (_financials!.monthlyBreakdown.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.cardDark : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Resumen Mensual Concluido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  ..._financials!.monthlyBreakdown.map((m) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(m.monthName, style: const TextStyle(fontSize: 13)),
                                            Text(
                                              '\$${m.netAmount.toStringAsFixed(2)} (${m.consultationCount} sesiones)',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryDark),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Historial reciente
                          const Text('Historial de Consultas y Pagos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                            ),
                            child: _financials!.recentTransactions.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: Center(
                                      child: Text('No hay transacciones registradas aún', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _financials!.recentTransactions.length,
                                    separatorBuilder: (_, _) => Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                                    itemBuilder: (context, idx) {
                                      final item = _financials!.recentTransactions[idx];
                                      final isAvailable = item.fundStatus == 'AVAILABLE';

                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: isAvailable
                                              ? Colors.green.withValues(alpha: 0.15)
                                              : Colors.orange.withValues(alpha: 0.15),
                                          child: Icon(
                                            isAvailable ? Icons.check_circle_outline : Icons.lock_clock_outlined,
                                            size: 20,
                                            color: isAvailable ? Colors.green.shade700 : Colors.orange.shade800,
                                          ),
                                        ),
                                        title: Text('Consulta - ${item.patientName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        subtitle: Text(
                                          '${_formatDate(item.createdAt)} • ${isAvailable ? 'Disponible' : 'En custodia'}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '+\$${item.netAmount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isAvailable ? AppTheme.primaryDark : Colors.orange.shade800,
                                              ),
                                            ),
                                            Text(
                                              'Comisión: \$${item.platformFee.toStringAsFixed(2)}',
                                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
