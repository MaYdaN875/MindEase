import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Pide el código de 6 dígitos enviado al correo. Devuelve `true` al cerrarse
/// (con Navigator.pop) únicamente si el correo quedó verificado.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Ingresa el código de 6 dígitos.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final res = await AuthService().verifyEmail(code);
    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = res['message']?.toString() ?? 'No se pudo verificar el código.';
      });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final res = await AuthService().resendVerification();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res['success'] == true) {
        _info = res['message']?.toString() ?? 'Te enviamos un nuevo código.';
      } else {
        _error = res['message']?.toString() ?? 'No se pudo reenviar el código.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifica tu correo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Te enviamos un código de 6 dígitos a tu correo electrónico. '
                'Ingresa el código para confirmar que la cuenta es tuya. Vence en 15 minutos.',
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 8),
                decoration: const InputDecoration(counterText: '', hintText: '000000'),
                onSubmitted: (_) => _verify(),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              if (_info != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_info!),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _busy ? null : _verify,
                child: _busy
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Verificar'),
              ),
              TextButton(
                onPressed: _busy ? null : _resend,
                child: const Text('Reenviar código'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Más tarde'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
