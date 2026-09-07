import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AppointmentService {
  static final AppointmentService _instance = AppointmentService._internal();
  factory AppointmentService() => _instance;
  AppointmentService._internal();

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
          'message': 'El servidor backend devolvió una página HTML en lugar de JSON (HTTP ${response.statusCode}). Verifica que el servidor esté iniciado en el puerto 3000.',
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

  // POST /api/appointments
  // Reserva de cita (con validación de colisiones en el backend)
  Future<Map<String, dynamic>> createAppointment({
    required String psychologistId,
    required String startAt,
    required String endAt,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/appointments'),
        headers: headers,
        body: jsonEncode({
          'psychologistId': psychologistId,
          'startAt': startAt,
          'endAt': endAt,
        }),
      );

      final data = _parseResponse(response);
      if (response.statusCode == 201 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'Cita reservada exitosamente',
          'data': data['data']['appointment'],
        };
      }

      // Handle 409 Conflict specifically
      if (response.statusCode == 409) {
        return {
          'success': false,
          'isCollision': true,
          'message': data['message'] ?? 'El horario seleccionado ya no se encuentra disponible. Por favor elige otro.',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Error al agendar la cita',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // GET /api/appointments?as=patient|psychologist&status=...
  Future<Map<String, dynamic>> getMyAppointments({
    String? asRole, // 'patient' or 'psychologist'
    String? status, // 'PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED'
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{};
      if (asRole != null) queryParams['as'] = asRole;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$baseUrl/api/appointments').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await http.get(uri, headers: headers);
      final data = _parseResponse(response);

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'data': data['data']['appointments'] as List<dynamic>,
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Error al cargar citas',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // GET /api/appointments/:id
  Future<Map<String, dynamic>> getAppointmentById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/appointments/$id'),
        headers: headers,
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'data': data['data']['appointment'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Cita no encontrada',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // PATCH /api/appointments/:id/status
  Future<Map<String, dynamic>> updateAppointmentStatus(
    String id,
    String status, {
    String? cancellationReason,
  }) async {
    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> body = {'status': status};
      if (cancellationReason != null) {
        body['cancellationReason'] = cancellationReason;
      }
      final response = await http.patch(
        Uri.parse('$baseUrl/api/appointments/$id/status'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'] ?? 'Estado actualizado',
          'data': data['data']['appointment'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Error al actualizar estado',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
