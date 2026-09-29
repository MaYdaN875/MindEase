import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/config/api_config.dart';
import '../lib/services/private_chat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({'jwt_token:${ApiConfig.baseUrl}': 'test-session'}));
  test('requests use current session and preserve retry identifiers', () async {
    final key = PrivateChatService.clientId();
    final client = PrivateChatService(client: MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer test-session');
      expect(request.url.path, '/api/chats/test/messages');
      expect(jsonDecode(request.body)['clientId'], key);
      return http.Response('{"status":"success","data":{"message":{"id":"saved"}}}', 200);
    }));
    expect((await client.request('/test/messages', body: {'clientId': key, 'content': 'hello'}))['message']['id'], 'saved');
    client.dispose();
  });
  test('internal server errors do not expose details', () async {
    final client = PrivateChatService(client: MockClient((_) async => http.Response('{"message":"SECRET SQL DATA"}', 500)));
    await expectLater(client.request(''), throwsA(predicate((e) => !e.toString().contains('SECRET'))));
    client.dispose();
  });
  test('missing authentication does not send a request', () async {
    SharedPreferences.setMockInitialValues({});
    var called = false;
    final client = PrivateChatService(client: MockClient((_) async { called = true; return http.Response('{}', 200); }));
    await expectLater(client.request(''), throwsException);
    expect(called, isFalse);
    client.dispose();
  });
  test('message retry identifiers are distinct UUID v4 values', () {
    final ids = List.generate(100, (_) => PrivateChatService.clientId());
    final pattern = RegExp(r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$');
    expect(ids.every(pattern.hasMatch), isTrue);
    expect(ids.toSet().length, 100);
  });
}
