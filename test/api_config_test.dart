import 'package:flutter_test/flutter_test.dart';
import '../lib/config/api_config.dart';

void main() {
  test('Railway is the default origin', () {
    expect(ApiConfig.baseUrl, 'https://mindease-backend-production-3a83.up.railway.app');
  });
  test('normalizes origins and supports local development', () {
    expect(ApiConfig.normalize('https://example.com/'), 'https://example.com');
    expect(ApiConfig.normalize('http://10.0.2.2:3000'), 'http://10.0.2.2:3000');
  });
  test('rejects credentials and API paths', () {
    for (final value in ['https://user:secret@example.com', 'https://example.com/api', 'file:///tmp', 'https://example.com?token=secret']) {
      expect(() => ApiConfig.normalize(value), throwsArgumentError);
    }
  });
}
