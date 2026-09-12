import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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
          'message': 'El servidor backend devolvió una respuesta no válida (HTTP ${response.statusCode}).',
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
        'message': 'Error al procesar respuesta del servidor: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getMyNotifications({int limit = 50, bool? isRead}) async {
    try {
      final headers = await _getHeaders();
      String url = '$baseUrl/api/notifications?limit=$limit';
      if (isRead != null) {
        url += '&isRead=$isRead';
      }

      final response = await http.get(Uri.parse(url), headers: headers);
      final data = _parseResponse(response);

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {
          'success': true,
          'unreadCount': data['unreadCount'] ?? 0,
          'data': data['data'] ?? [],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Error al obtener notificaciones',
        'unreadCount': 0,
        'data': [],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'unreadCount': 0,
        'data': [],
      };
    }
  }

  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
        headers: headers,
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data['data']};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Error al marcar notificación',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/api/notifications/read-all'),
        headers: headers,
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['message']};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Error al marcar todas las notificaciones',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
