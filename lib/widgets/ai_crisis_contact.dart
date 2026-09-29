import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Uri? crisisPhoneUri(String phone) {
  // Allow phone formatting, but never USSD, extension commands or arbitrary URI schemes.
  final value = phone.trim();
  if (!RegExp(r'^\+?[0-9 ()\-.]+$').hasMatch(value)) return null;
  final number = value.replaceAll(RegExp(r'[ ()\-.]'), '');
  if (!RegExp(r'^\+?\d{3,15}$').hasMatch(number)) return null;
  return Uri(scheme: 'tel', path: number);
}

class AICrisisContact extends StatelessWidget {
  final String name;
  final String phone;
  final Future<bool> Function(Uri)? openDialer;
  const AICrisisContact({
    super.key,
    required this.name,
    required this.phone,
    this.openDialer,
  });

  Future<void> _open(BuildContext context, Uri uri) async {
    bool opened;
    try {
      opened =
          await (openDialer?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo abrir el marcador. Puedes marcar manualmente: $phone',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri = crisisPhoneUri(phone);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: uri == null ? null : () => _open(context, uri),
        icon: const Icon(Icons.phone_outlined),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '$name\n$phone · Abrir marcador',
            textAlign: TextAlign.start,
          ),
        ),
        style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
      ),
    );
  }
}
