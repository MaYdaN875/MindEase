import 'package:flutter/material.dart';
import '../models/ai_orientation.dart';
import '../services/crisis_support_service.dart';
import 'ai_crisis_contact.dart';

Future<void> showCrisisSupportSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CrisisSupportSheet(),
    );

class CrisisHelpButton extends StatelessWidget {
  const CrisisHelpButton({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Ayuda urgente',
    icon: const Icon(Icons.emergency_outlined),
    onPressed: () => showCrisisSupportSheet(context),
  );
}

class CrisisSupportSheet extends StatefulWidget {
  const CrisisSupportSheet({super.key});
  @override
  State<CrisisSupportSheet> createState() => _CrisisSupportSheetState();
}

class _CrisisSupportSheetState extends State<CrisisSupportSheet> {
  late final CrisisSupportService _service;
  late final Future<List<CrisisResource>> _resources;
  @override
  void initState() {
    super.initState();
    _service = CrisisSupportService();
    _resources = _service.getResources();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    child: FutureBuilder<List<CrisisResource>>(
      future: _resources,
      builder: (context, snapshot) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Ayuda urgente',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'MindEase no es un servicio de emergencias ni monitorea conversaciones en tiempo real. Si existe peligro inmediato, busca apoyo humano o servicios de emergencia locales.',
            ),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (snapshot.hasError)
              const Text(
                'No pudimos cargar los recursos ahora. Contacta a los servicios de emergencia locales o a una persona de confianza.',
              )
            else
              ...snapshot.data!.map(
                (resource) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AICrisisContact(
                    name: resource.name,
                    phone: resource.phone,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
