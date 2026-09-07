import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PsychologistService {
  static final PsychologistService _instance = PsychologistService._internal();
  factory PsychologistService() => _instance;
  PsychologistService._internal();

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
          'message': 'El servidor backend devolvió una página HTML en lugar de JSON (HTTP ${response.statusCode}). Verifica que el servidor de Node/Express esté iniciado en el puerto 3000.',
        };
      }
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'status': 'error', 'message': 'Respuesta no válida del servidor'};
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Error al procesar respuesta del servidor (HTTP ${response.statusCode}): $e',
      };
    }
  }

  // GET /api/psychologists/me/availability
  Future<Map<String, dynamic>> getMyAvailability() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/psychologists/me/availability'),
        headers: headers,
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'data': data['data']['availabilities'] as List<dynamic>,
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Error al obtener disponibilidad',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // PUT /api/psychologists/me/availability
  Future<Map<String, dynamic>> updateMyAvailability(List<Map<String, dynamic>> availabilities) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/psychologists/me/availability'),
        headers: headers,
        body: jsonEncode({'availabilities': availabilities}),
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'Disponibilidad guardada',
          'data': data['data']['availabilities'] as List<dynamic>,
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Error al guardar disponibilidad',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // GET /api/psychologists/{id}/available-slots?date=YYYY-MM-DD
  // IMPORTANTE: El backend calcula los slots, restando citas existentes y colisiones
  Future<Map<String, dynamic>> getAvailableSlots(String psychologistId, String date) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/psychologists/$psychologistId/available-slots?date=$date'),
        headers: headers,
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
        'message': data['message'] ?? 'No fue posible obtener los horarios disponibles',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // GET /api/psychologists
  Future<Map<String, dynamic>> getVerifiedPsychologists({String? specialty, String? search}) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{};
      if (specialty != null && specialty.isNotEmpty && specialty != 'All') {
        queryParams['specialty'] = specialty;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('$baseUrl/api/psychologists').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final response = await http.get(uri, headers: headers);

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'data': data['data']['psychologists'] as List<dynamic>,
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Error al obtener psicólogos',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // GET /api/psychologists/{id}/public
  Future<Map<String, dynamic>> getPublicProfile(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/psychologists/$id/public'),
        headers: headers,
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'data': data['data']['profile'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Error al obtener perfil',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
