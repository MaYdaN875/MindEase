import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_application_1/services/support_service.dart';
import 'package:flutter_application_1/screens/support/help_support_screen.dart';
import 'package:flutter_application_1/screens/support/ticket_create_screen.dart';
import 'package:flutter_application_1/screens/support/ticket_detail_screen.dart';
import 'package:flutter_application_1/screens/support/report_user_dialog.dart';

const ticketJson = {
  'id': 'tick-123',
  'ticketNumber': 1001,
  'subject': 'Falla con pago de cita',
  'category': 'PAYMENT',
  'priority': 'HIGH',
  'status': 'OPEN',
  'source': 'USER',
  'createdAt': '2026-09-20T18:00:00.000Z',
  'updatedAt': '2026-09-20T18:05:00.000Z',
  'user': {'name': 'Paciente Test', 'email': 'paciente@test.com'},
  'assignedTo': {'name': 'Agente Soporte', 'email': 'soporte@test.com'},
  'lastMessage': {'content': 'Hola, necesito ayuda con mi pago'},
  'messagesCount': 2,
  'messages': [
    {
      'id': 'msg-1',
      'content': 'Hola, necesito ayuda con mi pago',
      'isInternalNote': false,
      'attachments': [],
      'createdAt': '2026-09-20T18:00:00.000Z',
      'sender': {'id': 'u1', 'name': 'Paciente Test', 'isStaff': false},
      'isMine': true,
    },
    {
      'id': 'msg-2',
      'content': 'Nota interna: revisando transacción en pasarela',
      'isInternalNote': true,
      'attachments': [],
      'createdAt': '2026-09-20T18:03:00.000Z',
      'sender': {'id': 'u2', 'name': 'Agente Soporte', 'isStaff': true},
      'isMine': false,
    },
  ],
  'isOwner': true,
};

http.Response ok(Map<String, dynamic> data, [int status = 200]) => http.Response(
      jsonEncode({'status': 'success', 'data': data}),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

SupportService createMockService(Future<http.Response> Function(http.Request) handler) {
  return SupportService(
    client: MockClient(handler),
    baseUrl: 'http://10.0.2.2:3000',
    tokenProvider: () async => 'mock-jwt-token',
  );
}

void main() {
  test('Support models deserialize properly from JSON', () {
    final ticket = SupportTicket.fromJson(ticketJson);
    expect(ticket.id, 'tick-123');
    expect(ticket.ticketNumber, 1001);
    expect(ticket.category, 'PAYMENT');
    expect(ticket.priority, 'HIGH');
    expect(ticket.status, 'OPEN');
    expect(ticket.messages.length, 2);
    expect(ticket.messages[0].isInternalNote, false);
    expect(ticket.messages[1].isInternalNote, true);

    final metrics = SupportMetrics.fromJson({
      'totalTickets': 10,
      'openCount': 3,
      'inProgressCount': 2,
      'waitingUserCount': 1,
      'resolvedCount': 2,
      'closedCount': 2,
      'activeTicketsCount': 6,
      'urgentOpenCount': 1,
      'unassignedCount': 2,
      'avgFirstResponseMinutes': 45,
    });
    expect(metrics.totalTickets, 10);
    expect(metrics.avgFirstResponseMinutes, 45);

    final report = UserReport.fromJson({
      'id': 'rep-1',
      'reason': 'UNPROFESSIONAL_CONDUCT',
      'description': 'Llegó tarde a la sesión',
      'status': 'PENDING',
      'reportedUser': {'name': 'Dr. Test'},
      'reporter': {'name': 'Paciente A'},
    });
    expect(report.id, 'rep-1');
    expect(report.reportedUserName, 'Dr. Test');
  });

  test('SupportService creates and lists tickets', () async {
    final service = createMockService((req) async {
      if (req.method == 'POST' && req.url.path == '/api/support/tickets') {
        final body = jsonDecode(req.body);
        expect(body['subject'], 'Problema con cita');
        expect(body['category'], 'APPOINTMENT');
        return ok({'ticket': ticketJson}, 201);
      }
      if (req.method == 'GET' && req.url.path == '/api/support/tickets') {
        return ok({
          'items': [ticketJson],
          'hasMore': false,
          'nextCursor': null,
        });
      }
      return http.Response('Not found', 404);
    });

    final created = await service.createTicket(
      subject: 'Problema con cita',
      category: 'APPOINTMENT',
      content: 'No pude conectarme al enlace de la sesión.',
    );
    expect(created.id, 'tick-123');

    final page = await service.getMyTickets();
    expect(page.items.length, 1);
    expect(page.items[0].ticketNumber, 1001);
  });

  test('SupportService staff actions and reports', () async {
    final service = createMockService((req) async {
      if (req.method == 'GET' && req.url.path == '/api/users/profile') {
        return ok({
          'user': {
            'roles': ['SUPPORT'],
          }
        });
      }
      if (req.method == 'PUT' && req.url.path == '/api/support/agent/tickets/tick-123/assign') {
        return ok({'ticket': ticketJson});
      }
      if (req.method == 'POST' && req.url.path == '/api/support/user-reports') {
        return ok({
          'report': {
            'id': 'rep-99',
            'reason': 'HARASSMENT',
            'description': 'Lenguaje inapropiado',
            'status': 'PENDING',
          }
        }, 201);
      }
      return http.Response('Not found', 404);
    });

    final isStaff = await service.isSupportStaff();
    expect(isStaff, true);

    final assigned = await service.assignTicket('tick-123', 'me');
    expect(assigned.id, 'tick-123');

    final rep = await service.createUserReport(
      reportedUserId: 'u-target',
      reason: 'HARASSMENT',
      description: 'Lenguaje inapropiado durante la sesión.',
    );
    expect(rep.id, 'rep-99');
  });

  testWidgets('HelpSupportScreen renders ticket list and empty state', (tester) async {
    final service = createMockService((req) async {
      if (req.url.path == '/api/users/profile') {
        return ok({'user': {'roles': ['USER']}});
      }
      if (req.url.path == '/api/support/tickets') {
        return ok({
          'items': [ticketJson],
          'hasMore': false,
        });
      }
      return http.Response('Not found', 404);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HelpSupportScreen(service: service),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Centro de Ayuda y Soporte'), findsOneWidget);
    expect(find.text('Falla con pago de cita'), findsOneWidget);
    expect(find.text('#1001'), findsOneWidget);
    expect(find.text('Nuevo Ticket'), findsOneWidget);
  });

  testWidgets('TicketCreateScreen validates minimum length inputs', (tester) async {
    final service = createMockService((req) async {
      return ok({'ticket': ticketJson}, 201);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: TicketCreateScreen(service: service),
      ),
    );

    await tester.pumpAndSettle();

    final submitBtn = find.text('Enviar ticket de soporte');
    await tester.ensureVisible(submitBtn);

    // Tap submit without typing
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.text('El asunto debe tener al menos 5 caracteres.'), findsOneWidget);

    // Enter short subject, empty description
    await tester.enterText(find.byType(TextField).first, 'Asunto válido de prueba');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.text('La descripción debe tener al menos 10 caracteres.'), findsOneWidget);
  });


  testWidgets('TicketDetailScreen shows messages and internal note badge', (tester) async {
    final service = createMockService((req) async {
      if (req.method == 'GET' && req.url.path == '/api/support/tickets/tick-123') {
        return ok({'ticket': ticketJson});
      }
      return http.Response('Not found', 404);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: TicketDetailScreen(ticketId: 'tick-123', service: service, isStaff: true),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ticket #1001'), findsOneWidget);
    expect(find.text('Falla con pago de cita'), findsOneWidget);
    expect(find.text('Hola, necesito ayuda con mi pago'), findsOneWidget);
    // Internal note visible because isStaff: true
    expect(find.textContaining('Nota Interna'), findsOneWidget);
  });

  testWidgets('ReportUserDialog validates description and submits', (tester) async {
    final service = createMockService((req) async {
      if (req.method == 'POST' && req.url.path == '/api/support/user-reports') {
        return ok({
          'report': {
            'id': 'rep-1',
            'reason': 'UNPROFESSIONAL_CONDUCT',
            'description': 'Descripción de prueba detallada',
            'status': 'PENDING',
          }
        }, 201);
      }
      return http.Response('Not found', 404);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportUserDialog(
            reportedUserId: 'u-123',
            reportedUserName: 'Dr. López',
            service: service,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Reportar conducta'), findsOneWidget);
    expect(find.text('Usuario: Dr. López'), findsOneWidget);

    // Try submit without description
    await tester.tap(find.text('Enviar reporte para revisión'));
    await tester.pumpAndSettle();

    expect(find.textContaining('al menos 10 caracteres'), findsOneWidget);

    // Enter valid description and submit
    await tester.enterText(find.byType(TextField), 'El profesional canceló repetidas veces sin previo aviso.');
    await tester.tap(find.text('Enviar reporte para revisión'));
    await tester.pumpAndSettle();
  });
}
