import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openSessionLink(BuildContext context, String? link) async {
  final uri = Uri.tryParse(link ?? '');
  String? error;
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    error = 'El profesional todavía no ha compartido un enlace HTTPS válido.';
  } else {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        error = 'No se pudo abrir el enlace de la sesión.';
      }
    } catch (_) {
      error = 'No se pudo abrir el enlace de la sesión.';
    }
  }
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}
