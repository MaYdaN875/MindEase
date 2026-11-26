import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

bool shouldAutomaticallyOpenInitialInterview(String? status) =>
    ['PENDING', 'IN_PROGRESS', 'ESCALATED'].contains(status);

class InitialInterviewService {
  InitialInterviewService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  final AuthService _auth = AuthService();

  String get _baseUrl => _auth.baseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _parse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Return the server status without exposing response bodies or tokens.
    }
    return {
      'status': 'error',
      'message':
          'No se pudo procesar la respuesta del servidor (HTTP ${response.statusCode}).',
    };
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl$path'),
        headers: await _headers(),
      );
      final data = _parse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data['data']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'No se pudo consultar la entrevista.',
      };
    } catch (_) {
      return {
        'success': false,
        'message':
            'No se pudo conectar con MindEase. Comprueba tu conexión e inténtalo de nuevo.',
      };
    }
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final headers = await _headers();
      final encoded = jsonEncode(body);
      final response = switch (method) {
        'PUT' => await _client.put(uri, headers: headers, body: encoded),
        _ => await _client.post(uri, headers: headers, body: encoded),
      };
      final data = _parse(response);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['status'] == 'success') {
        return {'success': true, 'data': data['data']};
      }
      return {
        'success': false,
        'code': data['code'],
        'message': data['message'] ?? 'No se pudo guardar la entrevista.',
      };
    } catch (_) {
      return {
        'success': false,
        'message':
            'No se pudo conectar con MindEase. Tus respuestas guardadas se conservaron.',
      };
    }
  }

  Future<Map<String, dynamic>> getStatus() => _get('/api/interview/status');

  Future<Map<String, dynamic>> getProgress() => _get('/api/interview/progress');

  Future<Map<String, dynamic>> getReview() => _get('/api/interview/review');

  Future<Map<String, dynamic>> start({
    required String consentVersion,
    required bool adultConfirmed,
  }) => _send('POST', '/api/interview/start', {
    'consentVersion': consentVersion,
    'adultConfirmed': adultConfirmed,
  });

  Future<Map<String, dynamic>> answer({
    required String questionId,
    required String value,
  }) => _send('POST', '/api/interview/answer', {
    'questionId': questionId,
    'answer': value,
  });

  Future<Map<String, dynamic>> revise({
    required String questionId,
    required String value,
  }) => _send('PUT', '/api/interview/review', {
    'questionId': questionId,
    'answer': value,
  });

  Future<Map<String, dynamic>> complete() =>
      _send('POST', '/api/interview/complete', {'confirmed': true});

  Future<Map<String, dynamic>> getProfessionalReport({
    required String patientId,
    required String appointmentId,
  }) => _get(
    '/api/interview/professional/patients/${Uri.encodeComponent(patientId)}/initial-report'
    '?appointmentId=${Uri.encodeQueryComponent(appointmentId)}',
  );

  Future<Map<String, dynamic>> resumeProfessionalInterview({
    required String patientId,
    required String appointmentId,
  }) => _send(
    'POST',
    '/api/interview/professional/patients/${Uri.encodeComponent(patientId)}/resume'
        '?appointmentId=${Uri.encodeQueryComponent(appointmentId)}',
    {},
  );

  Future<Uint8List> downloadProfessionalPdf({
    required String patientId,
    required String appointmentId,
  }) async {
    final headers = await _headers();
    final uri = Uri.parse(
      '$_baseUrl/api/interview/professional/patients/${Uri.encodeComponent(patientId)}/initial-report.pdf',
    ).replace(queryParameters: {'appointmentId': appointmentId});
    final response = await _client.get(uri, headers: headers);
    if (response.statusCode != 200 ||
        response.headers['content-type']?.contains('application/pdf') != true) {
      final error = _parse(response);
      throw Exception(error['message'] ?? 'No se pudo descargar el informe.');
    }
    return response.bodyBytes;
  }
}
