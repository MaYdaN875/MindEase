import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_orientation.dart';
import 'auth_service.dart';

class CrisisSupportService {
  CrisisSupportService({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;

  Future<List<CrisisResource>> getResources() async {
    final auth = AuthService();
    final token = await auth.getToken();
    final headers = token == null
        ? <String, String>{}
        : {'Authorization': 'Bearer $token'};
    final response = await _client
        .get(
          Uri.parse('${auth.baseUrl}/api/crisis/resources?country=MX'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar los recursos de ayuda.');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ((data['resources'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CrisisResource.fromJson)
        .toList();
  }

  void dispose() => _client.close();
}
