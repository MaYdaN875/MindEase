import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'auth_service.dart';

class VideoService {
  static bool _opening = false;
  static bool get supported => !kIsWeb && [TargetPlatform.android, TargetPlatform.iOS].contains(defaultTargetPlatform);

  static Future<void> join(BuildContext context, String appointmentId) async {
    if (_opening) return;
    if (!supported) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La videollamada integrada está disponible en Android e iOS.')));
      return;
    }
    _opening = true;
    try {
      final auth = AuthService();
      final token = await auth.getToken();
      if (token == null) throw Exception('Inicia sesión para entrar a la consulta.');
      final response = await http.post(Uri.parse('${auth.baseUrl}/api/consultations/$appointmentId/video-session'), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: '{}').timeout(const Duration(seconds: 20));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) throw Exception(body['message'] is String ? body['message'] : 'No se pudo autorizar la videollamada.');
      final session = body['data']['session'] as Map<String, dynamic>;
      validateSession(session);
      if (!context.mounted) return;
      final result = await JitsiMeet().join(JitsiMeetConferenceOptions(
        serverURL: session['serverUrl'] as String, room: session['room'] as String, token: session['token'] as String,
        userInfo: JitsiMeetUserInfo(displayName: session['displayName'] as String),
        configOverrides: {'startWithAudioMuted': true, 'startWithVideoMuted': true, 'subject': 'Consulta MindEase'},
        featureFlags: {'recording.enabled': false, 'live-streaming.enabled': false, 'invite.enabled': false, 'add-people.enabled': false, 'meeting-password.enabled': false, 'help.enabled': false, 'welcomepage.enabled': false},
      ), JitsiMeetEventListener(conferenceTerminated: (_, error) {
        if (error != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La videollamada se interrumpió. Puedes volver a entrar mientras la consulta esté vigente.')));
        }
      }));
      if (!result.isSuccess) throw Exception('No se pudo iniciar Jitsi. Revisa los permisos y vuelve a intentarlo.');
    } catch (error) {
      if (context.mounted) {
        // Never log SDK errors or session payloads: they can contain bearer tokens.
        final message = error is Exception && error.toString().startsWith('Exception: ') ? error.toString().substring(11) : 'No se pudo abrir la videollamada. Revisa permisos, conexión y vuelve a intentarlo.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally { _opening = false; }
  }

  static void validateSession(Map<String, dynamic> session) {
    if (session['serverUrl'] != 'https://8x8.vc' || session['room'] is! String ||
        !RegExp(r'^vpaas-magic-cookie-[a-f0-9]+/mindease[a-f0-9]{64}$').hasMatch(session['room'] as String) ||
        session['token'] is! String || (session['token'] as String).isEmpty ||
        session['displayName'] is! String || session['expiresAt'] is! String ||
        !(DateTime.tryParse(session['expiresAt'])?.isAfter(DateTime.now()) ?? false)) {
      throw Exception('La autorización de videollamada no es válida o ha caducado.');
    }
  }
}
