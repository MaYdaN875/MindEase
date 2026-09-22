import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/stripe_payment_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  http.Response config() => http.Response(jsonEncode({'data': {'provider': 'STRIPE', 'publishableKey': 'pk_test_fake'}}), 200);

  test('Stripe only sends reservation and stable idempotency key, never card fields', () async {
    final keys = <String>[];
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/config')) return config();
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload.keys.toSet(), {'appointmentId', 'idempotencyKey'});
      keys.add(payload['idempotencyKey']);
      return http.Response('{"data":{"payment":{"status":"PROCESSING"},"clientSecret":null}}', 200);
    });
    expect((await StripePaymentService(client: client).checkout('a'))['success'], false);
    await StripePaymentService(client: client).checkout('a');
    expect(keys.toSet().length, 1);
  });

  test('Server success preserves manual approval without opening another sheet', () async {
    final service = StripePaymentService(client: MockClient((request) async {
      if (request.url.path.endsWith('/config')) return config();
      return http.Response(jsonEncode({'data': {'payment': {'id': 'p', 'appointmentId': 'a', 'amount': 600, 'status': 'SUCCEEDED'},
        'appointmentStatus': 'PENDING', 'autoConfirmed': false, 'clientSecret': null}}), 200);
    }));
    final result = await service.checkout('a');
    expect(result['success'], true);
    expect(result['data']['appointmentStatus'], 'PENDING');
  });

  test('Only provider cancellation rotates Stripe attempt key', () async {
    final keys = <String>[];
    final service = StripePaymentService(client: MockClient((request) async {
      if (request.url.path.endsWith('/config')) return config();
      keys.add(jsonDecode(request.body)['idempotencyKey']);
      return http.Response('{"definitiveFailure":true,"message":"Cancelado"}', 409);
    }));
    await service.checkout('a'); await service.checkout('a');
    expect(keys[0], isNot(keys[1]));
  });

  test('Desktop rejects native PaymentSheet before making requests', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final service = StripePaymentService(client: MockClient((_) async => throw StateError('Unexpected request')));
    final result = await service.checkout('a');
    expect(result['success'], false);
    expect(result['message'], contains('Android o iOS'));
  });
}
