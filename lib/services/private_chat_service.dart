import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PrivateChatService {
  PrivateChatService({http.Client? client, this.preBooking = false}) : _client = client ?? http.Client();
  final http.Client _client;
  final bool preBooking;
  void dispose() => _client.close();

  static String clientId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<Map<String, dynamic>> request(String path, {Map<String, dynamic>? body}) async {
    final auth = AuthService();
    final token = await auth.getToken();
    if (token == null) throw Exception('Inicia sesión para acceder al chat.');
    final uri = Uri.parse('${auth.baseUrl}/api/${preBooking ? 'conversations' : 'chats'}$path');
    final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
    final response = await (body == null
        ? _client.get(uri, headers: headers)
        : _client.post(uri, headers: headers, body: jsonEncode(body)))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Tu sesión no permite acceder al chat. Vuelve a iniciar sesión.');
    }
    Map<String, dynamic> data;
    try { data = jsonDecode(response.body) as Map<String, dynamic>; }
    catch (_) { throw Exception('El chat no está disponible temporalmente.'); }
    if (response.statusCode != 200) {
      throw Exception(response.statusCode < 500 && data['message'] is String
          ? data['message'] : 'El chat no está disponible temporalmente.');
    }
    return (data['data'] as Map<String, dynamic>?) ?? {};
  }
}
