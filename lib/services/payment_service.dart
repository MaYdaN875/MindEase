import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/payment.dart';
export '../models/payment.dart';

class PaymentService {
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
      final headers = await _getHeaders(idempotencyKey: idempotencyKey);
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
      if (idempotencyKey != null) {
        payload['idempotencyKey'] = idempotencyKey;
      }

      final response = await _client.post(
        Uri.parse('$baseUrl/api/payments/checkout'),
        headers: headers,
        body: jsonEncode(payload),
      );

      final data = _parseResponse(response);
      final isSuccess = response.statusCode == 200 || response.statusCode == 201;

      if (isSuccess && data['data'] != null && data['data']['payment'] != null) {
        return {
          'success': true,
          'message': data['message'] ?? 'Pago realizado con éxito',
          'payment': PaymentRecord.fromJson(data['data']['payment']),
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
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.post(
        Uri.parse('$baseUrl/api/psychologists/me/payouts'),
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'bankName': bankName.trim(),
          'accountClabe': accountClabe.trim(),
          if (notes != null && notes.isNotEmpty) 'notes': notes.trim(),
        }),
      );

      final data = _parseResponse(response);
      final isSuccess = response.statusCode == 201;

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
