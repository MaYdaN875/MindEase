import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/support.dart';
import 'auth_service.dart';

export '../models/support.dart';

class SupportException implements Exception {
  final String message;
  final int? statusCode;
  const SupportException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class SupportService {
  final http.Client _client;
  final bool _ownsClient;
  final String baseUrl;
  final Future<String?> Function() _token;

  SupportService({
    http.Client? client,
    String? baseUrl,
    Future<String?> Function()? tokenProvider,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        baseUrl = baseUrl ?? AuthService().baseUrl,
        _token = tokenProvider ?? AuthService().getToken;

  void close() {
    if (_ownsClient) _client.close();
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

    try {
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 25)),
      ).timeout(const Duration(seconds: 25));
      return _decode(response);
    } on TimeoutException {
      throw const SupportException(
        'La solicitud tardó demasiado. Por favor revisa tu conexión e inténtalo de nuevo.',
      );
    } on http.ClientException {
      throw const SupportException(
        'No se pudo conectar con el servicio de soporte. Revisa tu conexión a internet.',
      );
    }
  }

  JsonMap _decode(http.Response response) {
    JsonMap envelope;
    try {
      envelope = objectMap(jsonDecode(utf8.decode(response.bodyBytes)));
    } catch (_) {
      throw SupportException(
        'El servidor devolvió una respuesta no válida.',
        response.statusCode,
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        envelope['status'] == 'error') {
      throw SupportException(
        response.statusCode == 401
            ? 'Tu sesión expiró. Inicia sesión nuevamente.'
            : envelope['message']?.toString() ??
                'No se pudo completar la operación de soporte.',
        response.statusCode,
      );
    }
    return objectMap(envelope['data']);
  }

  // Check if current authenticated user has support agent privileges
  Future<bool> isSupportStaff() async {
    try {
      final data = await _request('GET', 'users/profile');
      final user = objectMap(data['user']);
      final roles = (user['roles'] as List? ?? []).map((e) => e.toString()).toList();
      return roles.any((r) => ['SUPPORT', 'ADMIN', 'SUPERADMIN'].contains(r));
    } catch (_) {
      return false;
    }
  }

  // ========================
  // USER TICKETS API
  // ========================

  Future<SupportTicket> createTicket({
    required String subject,
    required String category,
    String priority = 'MEDIUM',
    required String content,
    List<String> attachments = const [],
    String? referenceType,
    String? referenceId,
  }) async {
    final res = await _request(
      'POST',
      'support/tickets',
      body: {
        'subject': subject.trim(),
        'category': category,
        'priority': priority,
        'content': content.trim(),
        'attachments': attachments,
        'referenceType': ?referenceType,
        'referenceId': ?referenceId,
      },

    );
    return SupportTicket.fromJson(objectMap(res['ticket']));
  }

  Future<SupportPage<SupportTicket>> getMyTickets({
    String? status,
    String? category,
    String? cursor,
  }) async {
    final res = await _request(
      'GET',
      'support/tickets',
      query: {
        'limit': '20',
        if (status != null && status.isNotEmpty) 'status': status,
        if (category != null && category.isNotEmpty) 'category': category,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return SupportPage.fromJson(res, SupportTicket.fromJson);
  }

  Future<SupportTicket> getTicketById(String id) async {
    final res = await _request('GET', 'support/tickets/$id');
    return SupportTicket.fromJson(objectMap(res['ticket']));
  }

  Future<TicketMessage> addMessage(
    String ticketId, {
    required String content,
    List<String> attachments = const [],
  }) async {
    final res = await _request(
      'POST',
      'support/tickets/$ticketId/messages',
      body: {
        'content': content.trim(),
        'attachments': attachments,
      },
    );
    return TicketMessage.fromJson(objectMap(res['message']));
  }

  Future<SupportTicket> closeTicket(String ticketId) async {
    final res = await _request('PUT', 'support/tickets/$ticketId/close');
    return SupportTicket.fromJson(objectMap(res['ticket']));
  }

  // ========================
  // SUPPORT AGENT CONSOLE API
  // ========================

  Future<SupportPage<SupportTicket>> getAllTickets({
    String? status,
    String? priority,
    String? category,
    String? source,
    String? assigned,
    String? search,
    String? cursor,
  }) async {
    final res = await _request(
      'GET',
      'support/agent/tickets',
      query: {
        'limit': '20',
        if (status != null && status.isNotEmpty) 'status': status,
        if (priority != null && priority.isNotEmpty) 'priority': priority,
        if (category != null && category.isNotEmpty) 'category': category,
        if (source != null && source.isNotEmpty) 'source': source,
        if (assigned != null && assigned.isNotEmpty) 'assigned': assigned,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return SupportPage.fromJson(res, SupportTicket.fromJson);
  }

  Future<SupportTicket> assignTicket(String ticketId, String? agentId) async {
    final res = await _request(
      'PUT',
      'support/agent/tickets/$ticketId/assign',
      body: {'agentId': agentId},
    );
    return SupportTicket.fromJson(objectMap(res['ticket']));
  }

  Future<SupportTicket> updateTicketStatus(
    String ticketId, {
    required String status,
    String? priority,
  }) async {
    final res = await _request(
      'PUT',
      'support/agent/tickets/$ticketId/status',
      body: {
        'status': status,
        'priority': ?priority,
      },
    );
    return SupportTicket.fromJson(objectMap(res['ticket']));
  }

  Future<TicketMessage> addAgentMessage(
    String ticketId, {
    required String content,
    bool isInternalNote = false,
    List<String> attachments = const [],
  }) async {
    final res = await _request(
      'POST',
      'support/agent/tickets/$ticketId/messages',
      body: {
        'content': content.trim(),
        'isInternalNote': isInternalNote,
        'attachments': attachments,
      },
    );
    return TicketMessage.fromJson(objectMap(res['message']));
  }

  Future<SupportMetrics> getSupportMetrics() async {
    final res = await _request('GET', 'support/agent/metrics');
    return SupportMetrics.fromJson(res);
  }

  // ========================
  // USER CONDUCT REPORTS API
  // ========================

  Future<UserReport> createUserReport({
    required String reportedUserId,
    String? appointmentId,
    required String reason,
    required String description,
    List<String> evidenceUrls = const [],
  }) async {
    final res = await _request(
      'POST',
      'support/user-reports',
      body: {
        'reportedUserId': reportedUserId,
        'appointmentId': ?appointmentId,
        'reason': reason,
        'description': description.trim(),
        'evidenceUrls': evidenceUrls,
      },

    );
    return UserReport.fromJson(objectMap(res['report']));
  }

  Future<SupportPage<UserReport>> getUserReports({
    String? status,
    String? reason,
    String? cursor,
  }) async {
    final res = await _request(
      'GET',
      'support/user-reports',
      query: {
        'limit': '20',
        if (status != null && status.isNotEmpty) 'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return SupportPage.fromJson(res, UserReport.fromJson);
  }

  Future<UserReport> investigateUserReport(
    String reportId, {
    required String status,
    String? moderatorNotes,
    bool escalateToTicket = false,
  }) async {
    final res = await _request(
      'PUT',
      'support/user-reports/$reportId/investigate',
      body: {
        'status': status,
        if (moderatorNotes != null) 'moderatorNotes': moderatorNotes.trim(),
        'escalateToTicket': escalateToTicket,
      },
    );
    return UserReport.fromJson(objectMap(res['report']));
  }

  // Upload attachment file (screenshot, receipt, document)
  Future<String> uploadAttachment(String name, Uint8List bytes) async {
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
      throw const SupportException(
        'Selecciona una imagen o PDF de hasta 10 MB.',
      );
    }
    final token = await _token();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/support/upload'),
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
        await _client.send(request).timeout(const Duration(seconds: 40)),
      ).timeout(const Duration(seconds: 25));
      final data = _decode(response);
      return data['url']?.toString() ?? '';
    } on TimeoutException {
      throw const SupportException(
        'La carga tardó demasiado tiempo. Por favor inténtalo de nuevo.',
      );
    } on http.ClientException {
      throw const SupportException('No se pudo subir el archivo adjunto.');
    }
  }
}
