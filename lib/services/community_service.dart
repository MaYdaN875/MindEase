import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/community.dart';
import 'auth_service.dart';

export '../models/community.dart';

class CommunityException implements Exception {
  final String message;
  final int? statusCode;
  const CommunityException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class CommunityService {
  final http.Client _client;
  final bool _ownsClient;
  final String baseUrl;
  final Future<String?> Function() _token;
  CommunityService({
    http.Client? client,
    String? baseUrl,
    Future<String?> Function()? tokenProvider,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       baseUrl = baseUrl ?? AuthService().baseUrl,
       _token = tokenProvider ?? AuthService().getToken;
  void close() {
    if (_ownsClient) _client.close();
  }

  // Only public web resources may be opened. Relative upload URLs use the API origin,
  // including Android's emulator host, never an unrelated local file or executable scheme.
  Uri? mediaUri(String value) {
    final parsed = Uri.tryParse(value.trim());
    if (parsed == null) return null;
    final uri = parsed.hasScheme
        ? parsed
        : value.startsWith('/uploads/community/')
        ? Uri.parse(baseUrl).resolveUri(parsed)
        : null;
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }

  Future<Uri?> mediaAccessUri(String value) async {
    final uri = mediaUri(value);
    if (uri == null) return null;
    final origin = Uri.parse(baseUrl);
    if (uri.origin != origin.origin ||
        !uri.path.startsWith('/uploads/community/')) {
      return uri;
    }
    final token = await _token();
    if (token == null) {
      return uri; // Published files remain accessible to visitors.
    }
    final data = await _request(
      'POST',
      'media/access',
      body: {'url': uri.path},
    );
    final signed = origin.resolve(data['url'] as String);
    if (signed.origin != origin.origin || signed.path != uri.path) {
      throw const CommunityException('Respuesta de archivo invalida.');
    }
    return signed;
  }

  Future<JsonMap> _request(
    String method,
    String path, {
    JsonMap? body,
    Map<String, String>? query,
  }) async {
    final request = http.Request(
      method,
      Uri.parse('$baseUrl/api/$path').replace(queryParameters: query),
    );
    final token = await _token();
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    // Do not automatically retry mutations: likes and follows are toggles.
    try {
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 25)),
      ).timeout(const Duration(seconds: 25));
      return _decode(response);
    } on TimeoutException {
      throw const CommunityException(
        'La solicitud tardó demasiado. Actualiza para comprobar su resultado antes de repetirla.',
      );
    } on http.ClientException {
      throw const CommunityException(
        'No se pudo conectar. Revisa tu conexión y vuelve a cargar.',
      );
    }
  }

  JsonMap _decode(http.Response response) {
    JsonMap envelope;
    try {
      envelope = objectMap(jsonDecode(utf8.decode(response.bodyBytes)));
    } catch (_) {
      throw CommunityException(
        'El servidor devolvió una respuesta no válida.',
        response.statusCode,
      );
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        envelope['status'] == 'error') {
      throw CommunityException(
        response.statusCode == 401
            ? 'Tu sesión expiró. Inicia sesión nuevamente.'
            : envelope['message']?.toString() ??
                  'No se pudo completar la operación.',
        response.statusCode,
      );
    }
    return objectMap(envelope['data']);
  }

  Future<bool> canManage() async {
    final data = await _request('GET', 'users/profile');
    final user = objectMap(data['user']);
    return (user['roles'] as List? ?? []).contains('PSYCHOLOGIST_VERIFIED') &&
        objectMap(user['psychologistProfile'])['status'] == 'VERIFICADO';
  }

  Future<List<CommunityCategory>> categories() async =>
      ((await _request('GET', 'community/categories'))['categories'] as List? ??
              [])
          .map((e) => CommunityCategory.fromJson(objectMap(e)))
          .toList();
  Future<CommunityPage<CommunityChannel>> channels({
    String? cursor,
    String? category,
    String? search,
    bool following = false,
    bool mine = false,
  }) async => CommunityPage.fromJson(
    await _request(
      'GET',
      'community/channels',
      query: {
        'limit': '20',
        'cursor': ?cursor,
        'category': ?category,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (following) 'following': 'true',
        if (mine) 'mine': 'true',
      },
    ),
    CommunityChannel.fromJson,
  );
  Future<CommunityChannel> channel(String id) async =>
      CommunityChannel.fromJson(
        objectMap((await _request('GET', 'community/channels/$id'))['channel']),
      );
  Future<CommunityChannel> saveChannel(JsonMap values, {String? id}) async =>
      CommunityChannel.fromJson(
        objectMap(
          (await _request(
            id == null ? 'POST' : 'PUT',
            'community/channels${id == null ? '' : '/$id'}',
            body: values,
          ))['channel'],
        ),
      );
  Future<JsonMap> follow(String id) =>
      _request('POST', 'community/channels/$id/follow');
  Future<CommunityPage<CommunityPost>> posts({
    String? cursor,
    String? channelId,
    String? category,
    bool following = false,
    bool mine = false,
    String status = 'PUBLISHED',
  }) async => CommunityPage.fromJson(
    await _request(
      'GET',
      'community/posts',
      query: {
        'limit': '20',
        'status': status,
        'cursor': ?cursor,
        'channelId': ?channelId,
        'category': ?category,
        if (following) 'following': 'true',
        if (mine) 'mine': 'true',
      },
    ),
    CommunityPost.fromJson,
  );
  Future<CommunityPost> post(String id) async => CommunityPost.fromJson(
    objectMap((await _request('GET', 'community/posts/$id'))['post']),
  );
  Future<CommunityPost> savePost(JsonMap values, {String? id}) async =>
      CommunityPost.fromJson(
        objectMap(
          (await _request(
            id == null ? 'POST' : 'PUT',
            'community/posts${id == null ? '' : '/$id'}',
            body: values,
          ))['post'],
        ),
      );
  Future<void> archivePost(String id) async {
    await _request('PUT', 'community/posts/$id', body: {'status': 'ARCHIVED'});
  }

  Future<JsonMap> like(String id) =>
      _request('POST', 'community/posts/$id/like');
  Future<CommunityPage<PostComment>> comments(
    String id, {
    String? cursor,
  }) async => CommunityPage.fromJson(
    await _request(
      'GET',
      'community/posts/$id/comments',
      query: {'limit': '30', 'cursor': ?cursor},
    ),
    PostComment.fromJson,
  );
  Future<PostComment> addComment(String id, String content) async =>
      PostComment.fromJson(
        objectMap(
          (await _request(
            'POST',
            'community/posts/$id/comments',
            body: {'content': content.trim()},
          ))['comment'],
        ),
      );
  Future<void> deleteComment(String id) async {
    await _request('DELETE', 'community/comments/$id');
  }

  Future<void> report({
    required String targetType,
    required String id,
    required String reason,
    String? details,
  }) async {
    if (!['postId', 'channelId', 'commentId'].contains(targetType)) {
      throw const CommunityException('Tipo de reporte inválido');
    }
    await _request(
      'POST',
      'community/reports',
      body: {
        targetType: id,
        'reason': reason,
        if (details != null) 'details': details.trim(),
      },
    );
  }

  Future<PostMedia> upload(String name, Uint8List bytes) async {
    const types = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
      'gif': 'image/gif',
      'pdf': 'application/pdf',
    };
    final mime = types[name.split('.').last.toLowerCase()];
    if (mime == null || bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const CommunityException(
        'Selecciona una imagen o PDF de hasta 10 MB.',
      );
    }
    final token = await _token();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/community/upload'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: name,
        contentType: MediaType.parse(mime),
      ),
    );
    try {
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 60)),
      ).timeout(const Duration(seconds: 25));
      return PostMedia.fromJson(_decode(response));
    } on TimeoutException {
      throw const CommunityException(
        'La carga tardó demasiado. El archivo podría haberse recibido.',
      );
    } on http.ClientException {
      throw const CommunityException('No se pudo subir el archivo.');
    }
  }
}
