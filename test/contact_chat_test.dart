import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/services/private_chat_service.dart';
import 'package:flutter_application_1/screens/chat/private_chat_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    var directory = File(Platform.resolvedExecutable).parent;
    for (var i = 0; i < 8; i++) {
      final fonts = Directory('${directory.path}/bin/cache/artifacts/material_fonts');
      if (fonts.existsSync()) {
        for (final pair in [['Roboto', 'roboto-regular.ttf'], ['MaterialIcons', 'materialicons-regular.otf']]) {
          final loader = FontLoader(pair[0])..addFont(File('${fonts.path}/${pair[1]}').readAsBytes().then(ByteData.sublistView));
          await loader.load();
        }
        return;
      }
      directory = directory.parent;
    }
    throw StateError('Flutter SDK fonts not found');
  });
  setUp(() => SharedPreferences.setMockInitialValues({'jwt_token:${ApiConfig.baseUrl}': 'session'}));
  test('contact uses separate endpoint', () async {
    final service = PrivateChatService(preBooking: true, client: MockClient((request) async {
      expect(request.url.path, '/api/conversations/pre-booking/profile');
      expect(request.headers['Authorization'], 'Bearer session');
      return http.Response('{"data":{"conversationId":"contact"}}', 200);
    }));
    expect((await service.request('/pre-booking/profile', body: {}))['conversationId'], 'contact');
    service.dispose();
  });
  testWidgets('contact design and scope are explicit', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = PrivateChatService(preBooking: true, client: MockClient((request) async {
      if (request.method == 'POST') return http.Response('{"data":{}}', 200);
      return http.Response(jsonEncode({'data': {'viewerId': 'patient', 'canSend': true, 'blockedByMe': false, 'nextBefore': null, 'messages': [
        {'sequence': 1, 'senderId': 'doctor', 'content': 'Hola, ofrezco sesiones en línea. ¿Qué duda tienes sobre el servicio?', 'createdAt': '2026-09-25T10:30:00', 'readAt': null},
        {'sequence': 2, 'senderId': 'patient', 'content': 'Gracias. ¿Qué horarios tienes disponibles?', 'createdAt': '2026-09-25T10:32:00', 'readAt': '2026-09-25T16:33:00Z'},
      ]}}), 200);
    }));
    await tester.pumpWidget(MaterialApp(theme: ThemeData(fontFamily: 'Roboto', colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF09D5DC))), home: PrivateChatScreen(appointmentId: 'contact', peerName: 'Nicolas Scherzer', preBooking: true, service: service)));
    await tester.pumpAndSettle();
    expect(find.text('Consulta previa'), findsOneWidget);
    expect(find.textContaining('No sustituye una consulta'), findsOneWidget);
    expect(find.textContaining('Gracias. ¿Qué horarios'), findsOneWidget);
    expect(find.byIcon(Icons.done_all), findsOneWidget);
    expect(find.byIcon(Icons.videocam), findsNothing);
    expect(find.textContaining('END-TO-END'), findsNothing);
    await expectLater(find.byType(PrivateChatScreen), matchesGoldenFile('goldens/contact_chat.png'));
    await tester.pumpWidget(MaterialApp(theme: ThemeData.dark().copyWith(textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto')),
      home: PrivateChatScreen(appointmentId: 'contact', peerName: 'Nicolas Scherzer', preBooking: true, service: service)));
    await tester.pumpAndSettle();
    await expectLater(find.byType(PrivateChatScreen), matchesGoldenFile('goldens/contact_chat_dark.png'));
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Bloquear contacto'), findsOneWidget);
    expect(find.text('Reportar contacto'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
