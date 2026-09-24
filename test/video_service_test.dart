import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import '../lib/services/video_service.dart';

void main() {
  Map<String, dynamic> session() => {'serverUrl': 'https://8x8.vc', 'room': 'vpaas-magic-cookie-abcdef/mindease${'a' * 64}', 'token': 'fixture', 'displayName': 'Paciente', 'expiresAt': DateTime.now().add(const Duration(minutes: 4)).toIso8601String()};
  test('accepts scoped JaaS response', () => VideoService.validateSession(session()));
  test('rejects external domains, wildcard rooms and expired access', () {
    for (final change in [{'serverUrl': 'https://evil.invalid'}, {'room': '*'}, {'token': ''}, {'expiresAt': '2020-01-01T00:00:00Z'}]) {
      expect(() => VideoService.validateSession({...session(), ...change}), throwsException);
    }
  });
  test('desktop does not attempt to launch mobile SDK', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(VideoService.supported, false);
    debugDefaultTargetPlatformOverride = null;
  });
}
