import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/widgets/ai_crisis_contact.dart';

void main() {
  test('accepts formatted phone numbers and rejects commands and schemes', () {
    expect(crisisPhoneUri('800 911 2000')?.toString(), 'tel:8009112000');
    expect(crisisPhoneUri('911')?.toString(), 'tel:911');
    expect(crisisPhoneUri('+52 (55) 5259-8121')?.path, '+525552598121');
    for (final value in [
      '*123#',
      'tel:911',
      'https://example.com',
      '911;123',
      '',
      '11',
    ]) {
      expect(crisisPhoneUri(value), isNull);
    }
  });
  testWidgets('opens dialer only after a tap', (tester) async {
    Uri? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AICrisisContact(
            name: 'Recurso de prueba',
            phone: '911',
            openDialer: (uri) async {
              opened = uri;
              return true;
            },
          ),
        ),
      ),
    );
    expect(opened, isNull);
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    expect(opened?.scheme, 'tel');
    expect(opened?.path, '911');
  });
  testWidgets('unavailable dialer keeps manual dialing instructions visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AICrisisContact(
            name: 'Recurso de prueba',
            phone: '911',
            openDialer: (_) async => false,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudo abrir el marcador. Puedes marcar manualmente: 911'),
      findsOneWidget,
    );
  });
}
