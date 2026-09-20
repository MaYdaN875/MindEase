import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/payment.dart';
export '../models/payment.dart';

class PaymentService {
  static String newIdempotencyKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService({http.Client? client}) =>
      client == null ? _instance : PaymentService._internal(client: client);
  PaymentService._internal({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  final AuthService _authService = AuthService();

  String get baseUrl => _authService.baseUrl;

  Future<Map<String, String>> _getHeaders({String? idempotencyKey}) async {
    final token = await _authService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    return headers;
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final body = response.body.trim();
      if (body.startsWith('<!DOCTYPE') || body.startsWith('<html') || body.startsWith('<pre')) {
        return {
          'success': false,
          'message': 'Error en la respuesta del servidor (HTTP ${response.statusCode})',
        };
      }
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'status': 'error', 'message': 'Formato de respuesta inválido'};
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Error al procesar respuesta (HTTP ${response.statusCode}): $e',
      };
    }
  }

  // POST /api/payments/checkout
  Future<Map<String, dynamic>> checkout({
    required String appointmentId,
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String holderName,
    String paymentMethod = 'CREDIT_CARD',
    String? idempotencyKey,
  }) async {
    try {
      const testCards = ['4242424242424242', '4000000000000002', '4000000000000005', '5555555555554444', '378282246310005'];
      if (!testCards.contains(cardNumber.replaceAll(RegExp(r'\s+'), ''))) {
        return {'success': false, 'message': 'Utiliza únicamente tarjetas de prueba. No ingreses datos bancarios reales.'};
      }
      final prefs = await SharedPreferences.getInstance();
      final storageKey = 'payment_attempt_$appointmentId';
      final attemptKey = idempotencyKey ?? prefs.getString(storageKey) ?? newIdempotencyKey();
      await prefs.setString(storageKey, attemptKey);
      final headers = await _getHeaders(idempotencyKey: attemptKey);
      final payload = <String, dynamic>{
        'appointmentId': appointmentId,
        'paymentMethod': paymentMethod,
        'card': {
          'number': cardNumber.replaceAll(RegExp(r'\s+'), ''),
          'expMonth': expMonth,
          'expYear': expYear,
          'cvc': cvc.trim(),
          'holderName': holderName.trim(),
        },
      };
      payload['idempotencyKey'] = attemptKey;

      final response = await _client.post(
        Uri.parse('$baseUrl/api/payments/checkout'),
        headers: headers,
        body: jsonEncode(payload),
      );

      final data = _parseResponse(response);
      final isSuccess = (response.statusCode == 200 || response.statusCode == 201) && data['data']?['payment']?['status'] == 'SUCCEEDED';
      if (response.statusCode == 402 && data['definitiveFailure'] == true) {
        await prefs.remove(storageKey);
      }

      if (isSuccess && data['data'] != null && data['data']['payment'] != null) {
        return {
          'success': true,
          'message': data['message'] ?? 'Pago realizado con éxito',
          'payment': PaymentRecord.fromJson(data['data']['payment']),
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'No se pudo completar el pago',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // GET /api/payments/history
  Future<Map<String, dynamic>> getPatientPaymentHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse('$baseUrl/api/payments/history'),
        headers: headers,
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['data'] != null && data['data']['payments'] != null) {
        final list = (data['data']['payments'] as List<dynamic>)
            .map((item) => PaymentRecord.fromJson(item as Map<String, dynamic>))
            .toList();
        return {'success': true, 'payments': list};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Error al obtener historial',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // GET /api/payments/:id/receipt
  Future<Map<String, dynamic>> getPaymentReceipt(String paymentId) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse('$baseUrl/api/payments/$paymentId/receipt'),
        headers: headers,
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['data'] != null && data['data']['receipt'] != null) {
        return {
          'success': true,
          'receipt': DigitalReceipt.fromJson(data['data']['receipt']),
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Error al obtener recibo',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // GET /api/psychologists/me/earnings
  Future<Map<String, dynamic>> getPsychologistEarnings() async {
    try {
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse('$baseUrl/api/psychologists/me/earnings'),
        headers: headers,
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['data'] != null && data['data']['financials'] != null) {
        return {
          'success': true,
          'financials': EarningsSummary.fromJson(data['data']['financials']),
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Error al obtener métricas financieras',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // POST /api/psychologists/me/payouts
  Future<Map<String, dynamic>> requestPayout({
    required double amount,
    required String bankName,
    required String accountClabe,
    required String idempotencyKey,
    String? notes,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return {'success': false, 'message': 'Inicia sesión para solicitar un retiro'};
      // JWT payload is used only to namespace local retry keys, never for authorization.
      final subject = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))))['userId'];
      final prefs = await SharedPreferences.getInstance();
      final storageKey = 'payout_attempt_${subject}_${amount.toStringAsFixed(2)}_${bankName.trim()}_${accountClabe.trim().substring(14)}';
      final attemptKey = prefs.getString(storageKey) ?? idempotencyKey;
      await prefs.setString(storageKey, attemptKey);
      final headers = await _getHeaders();
      final response = await _client.post(
        Uri.parse('$baseUrl/api/psychologists/me/payouts'),
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'bankName': bankName.trim(),
          'accountClabe': accountClabe.trim(),
          'idempotencyKey': attemptKey,
          if (notes != null && notes.isNotEmpty) 'notes': notes.trim(),
        }),
      );

      final data = _parseResponse(response);
      final isSuccess = response.statusCode == 201;
      if (isSuccess || response.statusCode == 400 || response.statusCode == 403 || response.statusCode == 409) await prefs.remove(storageKey);

      if (isSuccess && data['data'] != null && data['data']['payout'] != null) {
        return {
          'success': true,
          'message': data['message'] ?? 'Solicitud de retiro enviada',
          'payout': PayoutItem.fromJson(data['data']['payout']),
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'No se pudo procesar la solicitud de retiro',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // GET /api/psychologists/me/payouts
  Future<Map<String, dynamic>> getMyPayouts() async {
    try {
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse('$baseUrl/api/psychologists/me/payouts'),
        headers: headers,
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['data'] != null && data['data']['payouts'] != null) {
        final list = (data['data']['payouts'] as List<dynamic>)
            .map((item) => PayoutItem.fromJson(item as Map<String, dynamic>))
            .toList();
        return {'success': true, 'payouts': list};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Error al consultar retiros',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
