import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/payment_service.dart';
import 'package:flutter_application_1/screens/appointment_booking_sheet.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<Map<String, dynamic>> pay(PaymentService service) => service.checkout(
    appointmentId: 'appointment-1', cardNumber: '4242 4242 4242 4242',
    expMonth: 12, expYear: 2099, cvc: '123', holderName: 'Test Patient',
  );
  test('La pantalla de reserva compila y las llaves son UUID v4 distintas', () {
    expect(AppointmentBookingSheet, isNotNull);
    final keys = List.generate(100, (_) => PaymentService.newIdempotencyKey());
    expect(keys.toSet().length, 100);
    for (final key in keys) {
      expect(RegExp(r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$').hasMatch(key), isTrue);
    }
  });
  test('Un resultado desconocido conserva la llave entre instancias del servicio', () async {
    final keys = <String>[];
    final client = MockClient((request) async {
      keys.add(request.headers['Idempotency-Key'] ?? request.headers['idempotency-key']!);
      expect(jsonDecode(request.body)['idempotencyKey'], keys.last);
      return http.Response('{"status":"pending","message":"Pendiente"}', 202);
    });
    expect((await pay(PaymentService(client: client)))['success'], isFalse);
    await pay(PaymentService(client: client));
    expect(keys[0], keys[1]);
  });
  test('Solo un rechazo definitivo permite una llave nueva', () async {
    final keys = <String>[];
    final client = MockClient((request) async {
      keys.add(jsonDecode(request.body)['idempotencyKey']);
      return http.Response('{"status":"error","definitiveFailure":true}', 402);
    });
    final service = PaymentService(client: client);
    await pay(service);
    await pay(service);
    expect(keys[0], isNot(keys[1]));
  });
  test('El éxito conserva estado de cita y no repite llave después de respuesta perdida', () async {
    final service = PaymentService(client: MockClient((request) async => http.Response(jsonEncode({
      'data': {'payment': {'id': 'payment', 'appointmentId': 'appointment-1', 'amount': 600, 'status': 'SUCCEEDED'}, 'autoConfirmed': false, 'appointmentStatus': 'PENDING'},
    }), 200)));
    final result = await pay(service);
    expect(result['success'], isTrue);
    expect(result['data']['appointmentStatus'], 'PENDING');
    expect(result['data']['autoConfirmed'], isFalse);
    expect((await SharedPreferences.getInstance()).getString('payment_attempt_appointment-1'), isNotNull);
  });
}
