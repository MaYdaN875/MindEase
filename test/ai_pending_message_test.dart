import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/ai_pending_message.dart';

void main() {
  test(
    'same message retry reuses its UUID, different content uses a new one',
    () {
      final pending = AIPendingMessages();
      final first = pending.forSend('session', ' Hola ');
      expect(pending.forSend('session', 'Hola').requestKey, first.requestKey);
      expect(
        first.requestKey,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      final edited = pending.forSend('session', 'Otro texto');
      expect(edited.requestKey, isNot(first.requestKey));
      pending.acknowledge('session', first.requestKey);
      expect(pending.get('session')?.text, 'Otro texto');
      pending.acknowledge('session', edited.requestKey);
      expect(pending.get('session'), isNull);
    },
  );
  test('sessions are isolated and clearing removes sensitive drafts', () {
    final pending = AIPendingMessages();
    expect(
      pending.forSend('a', 'Hola').requestKey,
      isNot(pending.forSend('b', 'Hola').requestKey),
    );
    pending.clear();
    expect(pending.get('a'), isNull);
    expect(pending.get('b'), isNull);
  });
}
