import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'ai_pending_message.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();
  final AuthService _authService = AuthService();
  final AIPendingMessages _pending = AIPendingMessages();
  String? _lastToken;
  String get baseUrl => _authService.baseUrl;

  String? pendingDraft(String sessionId) => _pending.get(sessionId)?.text;

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool inference = false,
  }) async {
    try {
      final token = await _authService.getToken();
      if (_lastToken != token) {
        _pending.clear();
        _lastToken = token;
      }
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final uri = Uri.parse('$baseUrl/api/ai/orientation$path');
      final Future<http.Response> call = switch (method) {
        'GET' => http.get(uri, headers: headers),
        'DELETE' => http.delete(uri, headers: headers),
        _ => http.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
      };
      final response = await call.timeout(
        Duration(seconds: inference ? 75 : 20),
      );
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return {
        ...decoded,
        'success':
            response.statusCode >= 200 &&
            response.statusCode < 300 &&
            decoded['status'] == 'success',
        'statusCode': response.statusCode,
      };
    } on TimeoutException {
      return {
        'success': false,
        'code': 'AI_CLIENT_TIMEOUT',
        'retryable': true,
        'message':
            'La respuesta está tardando. Tu texto se conserva; reintentar el mismo envío no lo duplicará.',
      };
    } on FormatException {
      return {
        'success': false,
        'code': 'AI_INVALID_SERVER_RESPONSE',
        'retryable': true,
        'message':
            'El servidor no devolvió una respuesta válida. Conservamos tu texto.',
      };
    } catch (_) {
      return {
        'success': false,
        'code': 'AI_CONNECTION_ERROR',
        'retryable': true,
        'message':
            'No se pudo conectar. Revisa tu conexión; tu texto no se perdió.',
      };
    }
  }

  Future<Map<String, dynamic>> getConsentStatus() async {
    final result = await _request('GET', '/consent');
    final data = result['data'] as Map<String, dynamic>? ?? {};
    return {
      ...result,
      'hasConsent': data['hasConsent'] == true,
      'version': data['version'],
      'notice': data['text'],
    };
  }

  Future<Map<String, dynamic>> registerConsent(String version) => _request(
    'POST',
    '/consent',
    body: {'version': version, 'adultConfirmed': true},
  );

  Future<bool> deleteHistoryAndConsent() async {
    final result = await _request('DELETE', '/history');
    if (result['success'] == true) _pending.clear();
    return result['success'] == true;
  }

  Future<Map<String, dynamic>> _session(String method, String path) async {
    final result = await _request(method, path);
    return {...result, 'session': result['data']?['session']};
  }

  Future<Map<String, dynamic>> createOrGetSession() =>
      _session('POST', '/sessions');
  Future<Map<String, dynamic>> getActiveSession() =>
      _session('GET', '/sessions/active');
  Future<Map<String, dynamic>> getSessionById(String sessionId) =>
      _session('GET', '/sessions/$sessionId');

  Future<Map<String, dynamic>> sendMessage(
    String sessionId,
    String message,
  ) async {
    // Synchronize account before allocating the stable key (also clears drafts after logout).
    final token = await _authService.getToken();
    if (_lastToken != token) {
      _pending.clear();
      _lastToken = token;
    }
    final pending = _pending.forSend(sessionId, message);
    final result = await _request(
      'POST',
      '/sessions/$sessionId/messages',
      inference: true,
      body: {'message': pending.text, 'requestKey': pending.requestKey},
    );
    if (result['success'] == true) {
      _pending.acknowledge(sessionId, pending.requestKey);
    }
    return result;
  }

  Future<Map<String, dynamic>> _recommendations(
    String method,
    String path,
  ) async {
    final result = await _request(method, path);
    return {...result, 'recommendations': result['data']};
  }

  Future<Map<String, dynamic>> completeSession(String sessionId) =>
      _recommendations('POST', '/sessions/$sessionId/complete');
  Future<Map<String, dynamic>> getRecommendations(String sessionId) =>
      _recommendations('GET', '/sessions/$sessionId/recommendations');
}
