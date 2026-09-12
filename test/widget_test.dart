import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/appointment_service.dart';
import 'package:flutter_application_1/screens/psychologist/clinical_notes_screen.dart';
import 'package:flutter_application_1/models/appointment_status.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Una sesión iniciada se muestra en curso sin modificar el estado de la cita', () {
    final appointment = {'status': 'CONFIRMED', 'consultation': {'status': 'IN_PROGRESS'}};
    expect(appointmentDisplayStatus(appointment), 'IN_PROGRESS');
    expect(appointment['status'], 'CONFIRMED');
    expect(appointmentDisplayStatus({'status': 'COMPLETED', 'consultation': {'status': 'COMPLETED'}}), 'COMPLETED');
    expect(appointmentDisplayStatus({'status': 'CANCELLED', 'consultation': {'status': 'IN_PROGRESS'}}), 'CANCELLED');
  });

  testWidgets('Las notas se cargan del servidor y se guardan mediante PATCH', (tester) async {
    String? saved;
    final service = AppointmentService(client: MockClient((request) async {
      if (request.method == 'PATCH') {
        saved = jsonDecode(request.body)['clinicalNotes'];
        expect(request.url.path, '/api/consultations/test-id/notes');
        return http.Response(jsonEncode({'status': 'success', 'message': 'Notas guardadas'}), 200);
      }
      expect(request.url.path, '/api/consultations/test-id');
      return http.Response(jsonEncode({'status': 'success', 'data': {'consultation': {'clinicalNotes': 'Nota anterior'}}}), 200);
    }));
    await tester.pumpWidget(MaterialApp(home: ClinicalNotesScreen(appointmentId: 'test-id', service: service)));
    await tester.pumpAndSettle();
    expect(find.text('Nota anterior'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Nota actualizada');
    await tester.tap(find.text('Guardar notas'));
    await tester.pumpAndSettle();
    expect(saved, 'Nota actualizada');
    expect(find.text('Notas guardadas'), findsOneWidget);
  });

  testWidgets('Un error de carga impide sobrescribir notas existentes', (tester) async {
    final service = AppointmentService(client: MockClient((_) async => http.Response(jsonEncode({'status': 'error', 'message': 'Acceso denegado'}), 403)));
    await tester.pumpWidget(MaterialApp(home: ClinicalNotesScreen(appointmentId: 'test-id', service: service)));
    await tester.pumpAndSettle();
    expect(find.text('Acceso denegado'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Guardar notas'), findsNothing);
  });

  testWidgets('Un fallo de guardado conserva el texto para reintentar', (tester) async {
    final service = AppointmentService(client: MockClient((request) async {
      if (request.method == 'PATCH') return http.Response(jsonEncode({'status': 'error', 'message': 'No se pudo guardar'}), 500);
      return http.Response(jsonEncode({'status': 'success', 'data': {'consultation': {'clinicalNotes': ''}}}), 200);
    }));
    await tester.pumpWidget(MaterialApp(home: ClinicalNotesScreen(appointmentId: 'test-id', service: service)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Conservar este texto');
    await tester.tap(find.text('Guardar notas'));
    await tester.pumpAndSettle();
    expect(find.text('Conservar este texto'), findsOneWidget);
    expect(find.text('No se pudo guardar'), findsOneWidget);
  });
}
