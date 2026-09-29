import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/config/api_config.dart';
import '../lib/services/review_service.dart';
import '../lib/widgets/person_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({'jwt_token:${ApiConfig.baseUrl}': 'session'}));
  test('review sends authenticated rating and optional text', () async {
    final service = ReviewService(client: MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer session');
      expect(request.url.path, '/api/reviews/appointments/id');
      expect(jsonDecode(request.body), {'rating': 4, 'comment': 'Gracias'});
      return http.Response('{"data":{"review":{"rating":4}}}', 200);
    }));
    expect((await service.request('/appointments/id', body: {'rating': 4, 'comment': 'Gracias'}))['review']['rating'], 4);
    service.dispose();
  });
  test('public reviews do not transmit session', () async {
    final service = ReviewService(client: MockClient((request) async {
      expect(request.headers.containsKey('Authorization'), false);
      return http.Response('{"data":{"rating":null,"reviewsCount":0,"reviews":[]}}', 200);
    }));
    expect((await service.request('/psychologists/id', public: true))['rating'], isNull);
    service.dispose();
  });
  test('server failures hide internal details', () async {
    final service = ReviewService(client: MockClient((_) async => http.Response('SECRET SQL', 500)));
    await expectLater(service.request('/appointments/id'), throwsA(predicate((e) => !e.toString().contains('SECRET'))));
    service.dispose();
  });
  test('no session means no private request', () async {
    SharedPreferences.setMockInitialValues({});
    var called = false;
    final service = ReviewService(client: MockClient((_) async { called = true; return http.Response('{}', 200); }));
    await expectLater(service.request('/appointments/id'), throwsException);
    expect(called, false);
    service.dispose();
  });
  testWidgets('missing photo uses actual account initials, not a stock image', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PersonAvatar(name: 'Nicolas Scherzer'))));
    expect(find.text('NS'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PersonAvatar(name: '  Daniela   López  '))));
    expect(find.text('DL'), findsOneWidget);
    expect(find.text('NS'), findsNothing);
  });
  testWidgets('unknown identity does not invent a name', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PersonAvatar(name: '', photoUrl: 'javascript:invalid'))));
    expect(find.text('?'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
