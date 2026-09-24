import 'package:flutter_test/flutter_test.dart';
import '../lib/models/appointment_status.dart';

void main() {
  test('Ongoing consultation remains visible without changing appointment state', () {
    final appointment = {
      'status': 'CONFIRMED',
      'consultation': {'status': 'IN_PROGRESS'},
    };
    expect(appointmentMatchesFilter(appointment, 'Todas'), isTrue);
    expect(appointmentMatchesFilter(appointment, 'En curso'), isTrue);
    expect(appointmentMatchesFilter(appointment, 'Próximas'), isFalse);
    expect(appointment['status'], 'CONFIRMED');
  });

  test('Scheduled and terminal appointments retain their filters', () {
    expect(appointmentMatchesFilter({'status': 'CONFIRMED'}, 'Próximas'), isTrue);
    expect(appointmentMatchesFilter({'status': 'PENDING'}, 'Solicitudes'), isTrue);
    expect(appointmentMatchesFilter({'status': 'COMPLETED'}, 'En curso'), isFalse);
    expect(appointmentMatchesFilter({'status': 'COMPLETED'}, 'Finalizadas'), isTrue);
    expect(appointmentMatchesFilter({'status': 'CANCELLED'}, 'Canceladas'), isTrue);
  });
}
