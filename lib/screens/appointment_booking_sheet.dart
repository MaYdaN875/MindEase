import 'package:flutter/material.dart';
import '../models/psychologist.dart';
import '../services/psychologist_service.dart';
import '../services/appointment_service.dart';
import '../theme/app_theme.dart';

class AppointmentBookingSheet extends StatefulWidget {
  final Psychologist psychologist;
  final VoidCallback? onBookingSuccess;

  const AppointmentBookingSheet({
    super.key,
    required this.psychologist,
    this.onBookingSuccess,
  });

  static Future<void> show(BuildContext context, Psychologist psychologist, {VoidCallback? onBookingSuccess}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppointmentBookingSheet(
        psychologist: psychologist,
        onBookingSuccess: onBookingSuccess,
      ),
    );
  }

  @override
  State<AppointmentBookingSheet> createState() => _AppointmentBookingSheetState();
}

class _AppointmentBookingSheetState extends State<AppointmentBookingSheet> {
  final PsychologistService _psychologistService = PsychologistService();
  final AppointmentService _appointmentService = AppointmentService();

  int _currentStep = 1; // 1 = Slot Selector, 2 = Confirm Reservation
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  
  bool _isLoadingSlots = false;
  String? _slotsError;
  List<dynamic> _availableSlots = [];
  Map<String, dynamic>? _selectedSlot;

  bool _isBooking = false;
  String? _bookingError;

  @override
  void initState() {
    super.initState();
    _fetchSlotsForDate(_selectedDate);
  }

  String _formatDateYMD(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDateSpanish(DateTime date) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    const weekdays = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday ${date.day} de $month';
  }

  String _formatTimeHM(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return isoTime;
    }
  }

  Future<void> _fetchSlotsForDate(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _isLoadingSlots = true;
      _slotsError = null;
      _selectedSlot = null;
    });

    final dateStr = _formatDateYMD(date);
    final res = await _psychologistService.getAvailableSlots(widget.psychologist.id, dateStr);

    if (mounted) {
      setState(() {
        _isLoadingSlots = false;
      });

      if (res['success'] == true) {
        final data = res['data'];
        setState(() {
          _availableSlots = data['slots'] ?? [];
        });
      } else {
        setState(() {
          _slotsError = res['message'] ?? 'No hay horarios configurados para este día';
          _availableSlots = [];
        });
      }
    }
  }

  Future<void> _handleConfirmBooking() async {
    if (_selectedSlot == null) return;

    setState(() {
      _isBooking = true;
      _bookingError = null;
    });

    final res = await _appointmentService.createAppointment(
      psychologistId: widget.psychologist.id,
      startAt: _selectedSlot!['startAt'],
      endAt: _selectedSlot!['endAt'],
    );

    if (mounted) {
      setState(() {
        _isBooking = false;
      });

      if (res['success'] == true) {
        _showSuccessDialog();
      } else {
        setState(() {
          _bookingError = res['message'] ?? 'Ocurrió un error al agendar la cita.';
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.cardDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: AppTheme.primary, size: 56),
              ),
              const SizedBox(height: 16),
              const Text('¡Cita Confirmada!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Tu consulta con ${widget.psychologist.name} ha sido reservada con éxito.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Close bottom sheet
                  widget.onBookingSuccess?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.textDark,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentStep == 1 ? 'Seleccionar Horario' : 'Confirmar Consulta',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Expanded(
            child: _currentStep == 1 ? _buildStep1Slots(isDark) : _buildStep2Confirmation(isDark),
          ),
        ],
      ),
    );
  }

  // Step 1: Slot Selector
  Widget _buildStep1Slots(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Doctor banner summary
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(widget.psychologist.imageUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.psychologist.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(widget.psychologist.title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text(
                '\$${widget.psychologist.pricePerSession} MXN',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Date Selection Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Selecciona una fecha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    _fetchSlotsForDate(picked);
                  }
                },
                icon: const Icon(Icons.calendar_month, size: 16, color: AppTheme.primary),
                label: const Text('Cambiar', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Week horizontal selector (next 7 days)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(7, (i) {
                final date = DateTime.now().add(Duration(days: i + 1));
                final isSelected = date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;

                const daysShort = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                final dayLetter = daysShort[date.weekday - 1];

                return GestureDetector(
                  onTap: () => _fetchSlotsForDate(date),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.2)
                          : (isDark ? AppTheme.bgDark : AppTheme.surfaceContainerLow),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(dayLetter, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? AppTheme.primary : Colors.grey)),
                        const SizedBox(height: 4),
                        Text('${date.day}', style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // Slots calculated by Backend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Horarios disponibles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              if (_isLoadingSlots)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 12),

          if (_slotsError != null && !_isLoadingSlots)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgDark : AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _slotsError!,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          else if (_availableSlots.isEmpty && !_isLoadingSlots)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgDark : AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No hay citas disponibles para la fecha seleccionada. Por favor elige otro día.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _availableSlots.map((slot) {
                final isAvailable = slot['available'] == true;
                final isSelected = _selectedSlot == slot;
                final timeLabel = _formatTimeHM(slot['startAt']);

                return InkWell(
                  onTap: isAvailable
                      ? () {
                          setState(() {
                            _selectedSlot = slot;
                          });
                        }
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : (isAvailable
                              ? (isDark ? AppTheme.bgDark : AppTheme.surfaceContainerLow)
                              : Colors.grey.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : (isAvailable ? AppTheme.borderLight : Colors.transparent),
                      ),
                    ),
                    child: Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppTheme.textDark
                            : (isAvailable
                                ? (isDark ? AppTheme.textLight : AppTheme.textDark)
                                : Colors.grey),
                        decoration: isAvailable ? TextDecoration.none : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 30),

          // Continue Button
          ElevatedButton(
            onPressed: _selectedSlot != null
                ? () {
                    setState(() {
                      _currentStep = 2;
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.textDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
            ),
            child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // Step 2: Confirmation Screen
  Widget _buildStep2Confirmation(bool isDark) {
    final startTimeFormatted = _selectedSlot != null ? _formatTimeHM(_selectedSlot!['startAt']) : '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_bookingError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.onErrorContainer, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _bookingError!,
                      style: const TextStyle(color: AppTheme.onErrorContainer, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgDark : AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfirmRow('Psicólogo(a):', widget.psychologist.name, isBold: true),
                const Divider(height: 20),
                _buildConfirmRow('Fecha:', _formatDateSpanish(_selectedDate)),
                const Divider(height: 20),
                _buildConfirmRow('Hora:', '$startTimeFormatted hrs'),
                const Divider(height: 20),
                _buildConfirmRow('Duración:', '${widget.psychologist.durationMinutes} minutos'),
                const Divider(height: 20),
                _buildConfirmRow(
                  'Costo:',
                  '\$${widget.psychologist.pricePerSession} MXN',
                  isBold: true,
                  color: AppTheme.primaryDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppTheme.primary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tu sesión cuenta con cifrado de extremo a extremo y garantía de confidencialidad.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Volver'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isBooking ? null : _handleConfirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isBooking
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textDark))
                      : const Text('Confirmar consulta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
