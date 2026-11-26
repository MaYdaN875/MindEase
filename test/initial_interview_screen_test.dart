import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/initial_interview_screen.dart';
import 'package:flutter_application_1/services/initial_interview_service.dart';

class _InterviewServiceFake extends InitialInterviewService {
  @override
  Future<Map<String, dynamic>> getStatus() async => {
    'success': true,
    'data': {
      'status': 'PENDING',
      'hasConsent': false,
      'privacyNotice': {'version': 'v-test', 'text': 'Aviso de privacidad de prueba.'},
    },
  };

  @override
  Future<Map<String, dynamic>> getProgress() async => {
    'success': true,
    'data': {
      'status': 'PENDING',
      'question': null,
      'progress': {'current': 0, 'total': 1, 'percent': 0},
    },
  };

  @override
  Future<Map<String, dynamic>> start({required String consentVersion, required bool adultConfirmed}) async => {
    'success': true,
    'data': {
      'status': 'IN_PROGRESS',
      'question': {
        'id': 'reason_for_support',
        'module': 'Motivo de consulta',
        'prompt': '¿Qué te ha motivado a buscar apoyo?',
        'answerType': 'text',
      },
      'progress': {'current': 1, 'total': 1, 'percent': 0},
    },
  };

  @override
  Future<Map<String, dynamic>> answer({required String questionId, required String value}) async => {
    'success': true,
    'data': {
      'status': 'IN_PROGRESS',
      'question': null,
      'progress': {'current': 1, 'total': 1, 'percent': 100},
      'needsImmediateHelp': false,
    },
  };

  @override
  Future<Map<String, dynamic>> getReview() async => {
    'success': true,
    'data': {
      'answers': [{
        'questionId': 'reason_for_support',
        'prompt': '¿Qué te ha motivado a buscar apoyo?',
        'answer': 'Quiero sentirme mejor.',
      }],
    },
  };

  @override
  Future<Map<String, dynamic>> complete() async => {
    'success': true,
    'data': {'status': 'COMPLETED'},
  };
}

void main() {
  test('automatic interview launch resumes incomplete status but not completed status', () {
    expect(shouldAutomaticallyOpenInitialInterview('PENDING'), isTrue);
    expect(shouldAutomaticallyOpenInitialInterview('IN_PROGRESS'), isTrue);
    expect(shouldAutomaticallyOpenInitialInterview('ESCALATED'), isTrue);
    expect(shouldAutomaticallyOpenInitialInterview('COMPLETED'), isFalse);
    expect(shouldAutomaticallyOpenInitialInterview('UNAVAILABLE'), isFalse);
    expect(shouldAutomaticallyOpenInitialInterview(null), isFalse);
  });

  testWidgets('the guided interview requires consent and adult confirmation before starting', (tester) async {
    var completed = false;
    await tester.pumpWidget(MaterialApp(
      home: InitialInterviewScreen(
        service: _InterviewServiceFake(),
        onFinished: () async => completed = true,
        onPaused: () async {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Conozcámonos mejor'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Confirmo que tengo 18 años o más.'));
    await tester.tap(find.text('He leído y acepto el consentimiento informado para esta entrevista.'));
    await tester.tap(find.text('Comenzar entrevista'));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué te ha motivado a buscar apoyo?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Quiero sentirme mejor.');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Revisa tus respuestas'), findsOneWidget);
    expect(find.text('Quiero sentirme mejor.'), findsOneWidget);
    await tester.tap(find.text('Confirmar y finalizar'));
    await tester.pumpAndSettle();
    expect(find.text('¡Gracias por compartir esta información con nosotros!'), findsOneWidget);
    await tester.tap(find.text('Continuar a MindEase'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
  });
}
