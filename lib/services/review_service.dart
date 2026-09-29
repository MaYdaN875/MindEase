import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ReviewService {
  ReviewService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  void dispose() => _client.close();
  Future<Map<String, dynamic>> request(String path, {Map<String, dynamic>? body, bool public = false}) async {
    final auth = AuthService();
    final token = public ? null : await auth.getToken();
    if (!public && token == null) throw Exception('Inicia sesión para calificar.');
    final headers = {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'};
    final uri = Uri.parse('${auth.baseUrl}/api/reviews$path');
    final response = await (body == null ? _client.get(uri, headers: headers)
      : _client.post(uri, headers: headers, body: jsonEncode(body))).timeout(const Duration(seconds: 20));
    if (response.statusCode >= 500) throw Exception('Reseñas no disponibles. Intenta nuevamente.');
    Map<String, dynamic> decoded;
    try { decoded = jsonDecode(response.body) as Map<String, dynamic>; }
    catch (_) { throw Exception('Respuesta de reseñas no disponible.'); }
    if (response.statusCode != 200) throw Exception(decoded['message'] ?? 'No fue posible cargar las reseñas.');
    return decoded['data'] as Map<String, dynamic>;
  }
}
