import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'payment_service.dart';

/// Only opaque payment references leave this service; card data goes to Stripe.
class StripePaymentService {
  StripePaymentService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  final _auth = AuthService();

  Future<Map<String, String>> _headers() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await _auth.getToken()}',
  };

  Future<Map<String, dynamic>> checkout(String appointmentId) async {
    try {
      if (kIsWeb || ![TargetPlatform.android, TargetPlatform.iOS].contains(defaultTargetPlatform)) {
        return {'success': false, 'message': 'El pago con Stripe requiere la app Android o iOS.'};
      }
      final configResponse = await _client.get(Uri.parse('${_auth.baseUrl}/api/payments/config'), headers: await _headers()).timeout(const Duration(seconds: 20));
      final config = jsonDecode(configResponse.body) as Map<String, dynamic>;
      if (configResponse.statusCode != 200 || config['data']?['provider'] != 'STRIPE') {
        return {'success': false, 'message': config['message'] ?? 'Stripe no esta configurado en el servidor.'};
      }
      final prefs = await SharedPreferences.getInstance();
      final storageKey = 'stripe_attempt_$appointmentId';
      final key = prefs.getString(storageKey) ?? PaymentService.newIdempotencyKey();
      await prefs.setString(storageKey, key);

      Future<Map<String, dynamic>> reconcile() async {
        final response = await _client.post(Uri.parse('${_auth.baseUrl}/api/payments/intent'),
          headers: await _headers(), body: jsonEncode({'appointmentId': appointmentId, 'idempotencyKey': key})).timeout(const Duration(seconds: 45));
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['definitiveFailure'] == true || body['data']?['definitiveFailure'] == true) {
          await prefs.remove(storageKey);
        }
        return body;
      }

      Map<String, dynamic> outcome(Map<String, dynamic> body) {
        final data = body['data'];
        final payment = data?['payment'];
        if (payment?['status'] == 'SUCCEEDED') {
          return {'success': true, 'payment': PaymentRecord.fromJson(Map<String, dynamic>.from(payment)), 'data': data};
        }
        final refunding = ['REFUND_PENDING', 'REFUNDED'].contains(payment?['status']);
        return {'success': false, 'message': body['message'] ?? (refunding
          ? 'La reserva fue cancelada. Consulta el reembolso en tu historial.'
          : 'Pago sin confirmar. Puedes reintentar esta misma reserva o consultar tu historial.')};
      }

      final initial = await reconcile();
      final secret = initial['data']?['clientSecret'];
      if (secret == null) return outcome(initial);
      Stripe.publishableKey = config['data']['publishableKey'] as String;
      Stripe.urlScheme = 'mindease';
      await Stripe.instance.applySettings();
      await Stripe.instance.initPaymentSheet(paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: secret as String,
        merchantDisplayName: 'MindEase (pruebas)',
        returnURL: 'mindease://stripe-redirect',
        allowsDelayedPaymentMethods: false,
      ));
      try {
        await Stripe.instance.presentPaymentSheet();
      } on StripeException {
        // Closing the sheet is not proof of a failed payment. Reconcile the same intent.
        return outcome(await reconcile());
      }
      return outcome(await reconcile());
    } catch (_) {
      return {'success': false, 'message': 'No pudimos confirmar el pago. Reintenta la misma reserva; no se generara otro cobro por ese intento.'};
    }
  }
}
