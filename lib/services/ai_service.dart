import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final AuthService _authService = AuthService();

  String get baseUrl => _authService.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final body = response.body.trim();
      if (body.startsWith('<!DOCTYPE') || body.startsWith('<html') || body.startsWith('<pre')) {
        return {
          'success': false,
          'message':
              'El servidor backend devolvió una página HTML en lugar de JSON (HTTP ${response.statusCode}).',
        };
      }
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'success': false, 'message': 'Respuesta no válida del servidor'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al procesar respuesta del servidor (HTTP ${response.statusCode}): $e',
      };
    }
  }

  // GET /api/ai/orientation/consent
  Future<Map<String, dynamic>> getConsentStatus() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/ai/orientation/consent'),
        headers: headers,
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'hasConsent': data['data']?['hasConsent'] == true,
        };
      }
      return {
        'success': false,
        'hasConsent': false,
        'message': data['message'] ?? 'Error al consultar consentimiento',
      };
    } catch (e) {
      return {'success': false, 'hasConsent': false, 'message': 'Error de conexión: $e'};
    }
  }

  // POST /api/ai/orientation/consent
  Future<Map<String, dynamic>> registerConsent() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/orientation/consent'),
        headers: headers,
      );

      final data = _parseResponse(response);
      if ((response.statusCode == 200 || response.statusCode == 201) && data['status'] == 'success') {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Error al registrar consentimiento'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // POST /api/ai/orientation/sessions
  Future<Map<String, dynamic>> createOrGetSession() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/orientation/sessions'),
        headers: headers,
      );

      final data = _parseResponse(response);
      if (response.statusCode == 201 && data['status'] == 'success') {
        return {
          'success': true,
          'session': data['data']?['session'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Error al iniciar sesión de orientación',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // GET /api/ai/orientation/sessions/active
  Future<Map<String, dynamic>> getActiveSession() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/ai/orientation/sessions/active'),
        headers: headers,
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'session': data['data']?['session'],
        };
      }
      return {'success': false, 'session': null};
    } catch (e) {
      return {'success': false, 'session': null, 'message': 'Error de conexión: $e'};
    }
  }

  // GET /api/ai/orientation/sessions/:id
  Future<Map<String, dynamic>> getSessionById(String sessionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/ai/orientation/sessions/$sessionId'),
        headers: headers,
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'session': data['data']?['session'],
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Error al obtener sesión'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // POST /api/ai/orientation/sessions/:id/messages
  Future<Map<String, dynamic>> sendMessage(String sessionId, String message) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/orientation/sessions/$sessionId/messages'),
        headers: headers,
        body: jsonEncode({'message': message}),
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Error al enviar mensaje',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // POST /api/ai/orientation/sessions/:id/complete
  Future<Map<String, dynamic>> completeSession(String sessionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/orientation/sessions/$sessionId/complete'),
        headers: headers,
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'recommendations': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Error al completar la orientación',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // GET /api/ai/orientation/sessions/:id/recommendations
  Future<Map<String, dynamic>> getRecommendations(String sessionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/ai/orientation/sessions/$sessionId/recommendations'),
        headers: headers,
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'recommendations': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Error al obtener recomendaciones',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
