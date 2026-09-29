import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';

/// Missing photos never display another person's face.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.name, this.photoUrl, this.size = 44});
  final String name;
  final String? photoUrl;
  final double size;
  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty)
        .take(2).map((s) => s.characters.first.toUpperCase()).join();
    final fallback = CircleAvatar(radius: size / 2,
        child: Text(initials.isEmpty ? '?' : initials, style: TextStyle(fontSize: size * .32)));
    final raw = photoUrl?.trim() ?? '';
    final uri = Uri.tryParse(raw);
    final url = raw.startsWith('/') ? '${ApiConfig.baseUrl}$raw' : raw;
    if (raw.isEmpty || uri == null || (!raw.startsWith('/') && uri.scheme != 'https')) return fallback;
    return ClipOval(child: Image.network(url, width: size, height: size, fit: BoxFit.cover,
      errorBuilder: (_, error, stack) => fallback));
  }
}

class AccountAvatar extends StatefulWidget {
  const AccountAvatar({super.key, this.size = 44});
  final double size;
  @override
  State<AccountAvatar> createState() => _AccountAvatarState();
}
class _AccountAvatarState extends State<AccountAvatar> {
  Map<String, dynamic>? _user;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final result = await AuthService().getProfile();
    if (mounted && result['success'] == true) setState(() => _user = result['data']);
  }
  @override
  Widget build(BuildContext context) => PersonAvatar(name: _user?['name'] ?? '',
      photoUrl: _user?['photoUrl'] ?? _user?['psychologistProfile']?['photoUrl'], size: widget.size);
}
