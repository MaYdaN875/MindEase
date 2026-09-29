import 'dart:math';

/// In-memory only: never persist sensitive drafts to unencrypted preferences.
class AIPendingMessage {
  final String text;
  final String requestKey;
  AIPendingMessage(this.text) : requestKey = _uuid();

  static String _uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

class AIPendingMessages {
  final Map<String, AIPendingMessage> _pending = {};
  AIPendingMessage forSend(String sessionId, String text) {
    final current = _pending[sessionId];
    if (current != null && current.text == text.trim()) return current;
    return _pending[sessionId] = AIPendingMessage(text.trim());
  }

  AIPendingMessage? get(String sessionId) => _pending[sessionId];
  void acknowledge(String sessionId, String requestKey) {
    if (_pending[sessionId]?.requestKey == requestKey) {
      _pending.remove(sessionId);
    }
  }

  void clear() => _pending.clear();
}
