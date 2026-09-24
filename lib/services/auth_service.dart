import 'dart:convert';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Keep local and hosted sessions isolated. Switching servers requires login.
  static final String _tokenKey = 'jwt_token:${ApiConfig.baseUrl}';

  String get baseUrl => ApiConfig.baseUrl;

  // Check if token exists
  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  // Get token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Save token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Remove token
  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final body = response.body.trim();
      if (body.startsWith('<!DOCTYPE') || body.startsWith('<html') || body.startsWith('<pre')) {
        return {
          'status': 'error',
          'message': 'El servidor backend devolvió una página HTML en lugar de JSON (HTTP ${response.statusCode}).',
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

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        final token = data['data']['token'];
        await saveToken(token);
        return {'success': true, 'data': data['data']['user']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Authentication failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Register
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password, {
    String role = 'USER',
    String? phone,
    bool acceptedPrivacy = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'acceptedPrivacy': acceptedPrivacy,
        }),
      );

      final data = _parseResponse(response);
      if (response.statusCode == 201 && data['status'] == 'success') {
        final token = data['data']['token'];
        await saveToken(token);
        return {'success': true, 'data': data['data']['user']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Get User Profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data['data']['user']};
      } else {
        if (response.statusCode == 401) {
          await deleteToken();
        }
        return {'success': false, 'message': data['message'] ?? 'Failed to get profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await deleteToken();
  }

  // ================= PSYCHOLOGIST API METHODS =================

  // Get Psychologist Profile
  Future<Map<String, dynamic>> getPsychologistProfile() async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No token'};

      final response = await http.get(
        Uri.parse('$baseUrl/api/psychologists/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data['data']['profile']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to load profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Update Psychologist Profile
  Future<Map<String, dynamic>> updatePsychologistProfile(Map<String, dynamic> fields) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No token'};

      final response = await http.put(
        Uri.parse('$baseUrl/api/psychologists/me/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(fields),
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data['data']['profile']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Upload Psychologist Document
  Future<Map<String, dynamic>> uploadPsychologistDocument(
    String filePath,
    String documentType,
  ) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No token'};

      final uri = Uri.parse('$baseUrl/api/psychologists/me/documents');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['documentType'] = documentType
        ..files.add(await http.MultipartFile.fromPath('document', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = _parseResponse(response);
      if (response.statusCode == 201 && data['status'] == 'success') {
        return {'success': true, 'data': data['data']['document']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Upload failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Delete Psychologist Document
  Future<Map<String, dynamic>> deletePsychologistDocument(String documentId) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No token'};

      final response = await http.delete(
        Uri.parse('$baseUrl/api/psychologists/me/documents/$documentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Deletion failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Submit Psychologist Profile For Review
  Future<Map<String, dynamic>> submitPsychologistReview() async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No token'};

      final response = await http.post(
        Uri.parse('$baseUrl/api/psychologists/me/submit-review'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to submit review'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Get Psychologist Review Status / History
  Future<Map<String, dynamic>> getPsychologistReviewStatus() async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'No token'};

      final response = await http.get(
        Uri.parse('$baseUrl/api/psychologists/me/review-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = _parseResponse(response);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to load status'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }
}
