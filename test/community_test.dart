import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_application_1/services/community_service.dart';
import 'package:flutter_application_1/screens/community/community_screen.dart';
import 'package:flutter_application_1/screens/community/community_editors.dart';
import 'package:flutter_application_1/screens/community/community_widgets.dart';
import 'package:flutter_application_1/screens/community/community_post_screen.dart';

const categoryJson = {
  'id': 'cat',
  'name': 'Mindfulness',
  'slug': 'mindfulness',
};
Map<String, dynamic> channelJson({
  bool following = false,
  bool owner = false,
}) => {
  'id': 'channel',
  'name': 'Bienestar emocional',
  'description': 'Recursos de bienestar emocional',
  'category': categoryJson,
  'psychologist': {'id': 'doctor', 'name': 'Dra. Ana'},
  'followersCount': following ? 1 : 0,
  'postsCount': 0,
  'isFollowing': following,
  'isOwner': owner,
};
http.Response ok(Map<String, dynamic> data, [int status = 200]) =>
    http.Response(
      jsonEncode({'status': 'success', 'data': data}),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
http.Response page([List<dynamic> items = const [], String? cursor]) =>
    ok({'items': items, 'hasMore': cursor != null, 'nextCursor': cursor});
CommunityService service(Future<http.Response> Function(http.Request) handle) =>
    CommunityService(
      client: MockClient(handle),
      baseUrl: 'http://10.0.2.2:3000',
      tokenProvider: () async => 'test-token',
    );

void main() {
  test('Private media requests a scoped download URL', () async {
    const path = '/uploads/community/00000000-0000-0000-0000-000000000000.png';
    final api = service((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/media/access');
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(jsonDecode(request.body), {'url': path});
      return ok({'url': '$path?access=download-ticket'});
    });
    final uri = await api.mediaAccessUri(path);
    expect(uri.toString(), 'http://10.0.2.2:3000$path?access=download-ticket');
  });

  test('External media never receives the session token', () async {
    final api = service((_) async => throw StateError('Unexpected API call'));
    expect((await api.mediaAccessUri('https://example.test/image.png')).toString(),
        'https://example.test/image.png');
  });

  test('Download responses cannot redirect to another origin', () async {
    final api = service((_) async => ok({'url': 'https://example.test/file.png'}));
    await expectLater(api.mediaAccessUri('/uploads/community/file.png'),
        throwsA(isA<CommunityException>()));
  });

  test('Models handle list and mutation envelopes', () {
    expect(CommunityCategory.fromJson(categoryJson).slug, 'mindfulness');
    expect(
      CommunityChannel.fromJson(channelJson()).psychologistName,
      'Dra. Ana',
    );
    expect(
      CommunityChannel.fromJson({
        ...channelJson(),
        'psychologist': {
          'user': {'name': 'Dra. Ana'},
        },
      }).psychologistName,
      'Dra. Ana',
    );
    final post = CommunityPost.fromJson({
      'id': 'post',
      'status': 'PUBLISHED',
      'isAuthor': true,
      'isLiked': true,
      'media': [
        {'type': 'DOCUMENT', 'url': '/uploads/community/a.pdf', 'sizeBytes': 2},
      ],
    });
    expect(post.isAuthor, isTrue);
    expect(post.isLiked, isTrue);
    expect(post.media.single.toJson()['sizeBytes'], 2);
    expect(PostComment.fromJson({'id': 'c', 'isOwner': true}).isOwner, isTrue);
  });
  test('Media resolves emulator uploads and rejects dangerous schemes', () {
    final api = service((_) async => page());
    expect(api.mediaUri('/uploads/community/a.pdf')!.host, '10.0.2.2');
    for (final url in [
      'javascript:alert(1)',
      'file:///secret',
      'data:text/html,x',
      '//evil.test/file',
      '/private/file',
      'https://user:password@example.org',
    ]) {
      expect(api.mediaUri(url), isNull, reason: url);
    }
  });
  test('Token, cursor and channel filters match backend contract', () async {
    final api = service((request) async {
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(request.url.queryParameters['cursor'], 'a+/?&');
      expect(request.url.queryParameters['category'], 'cat');
      expect(request.url.queryParameters['following'], 'true');
      return page([channelJson()]);
    });
    expect(
      (await api.channels(
        cursor: 'a+/?&',
        category: 'cat',
        following: true,
      )).items.single.name,
      'Bienestar emocional',
    );
  });
  test('Professional draft queries are explicitly scoped', () async {
    final api = service((request) async {
      expect(request.url.queryParameters['status'], 'DRAFT');
      expect(request.url.queryParameters['mine'], 'true');
      expect(request.url.queryParameters['channelId'], 'channel');
      return page();
    });
    await api.posts(status: 'DRAFT', mine: true, channelId: 'channel');
  });
  test('Comments have exactly one level', () async {
    final api = service((request) async {
      expect(request.url.path, '/api/community/posts/post/comments');
      expect(jsonDecode(request.body), {'content': 'Una pregunta'});
      return ok({
        'comment': {'id': 'comment', 'isOwner': true},
      }, 201);
    });
    expect((await api.addComment('post', ' Una pregunta ')).isOwner, isTrue);
  });
  test('Report payload has one resource and reason', () async {
    final api = service((request) async {
      expect(jsonDecode(request.body), {
        'commentId': 'comment',
        'reason': 'HARASSMENT',
        'details': 'Detalle',
      });
      return ok({}, 201);
    });
    await api.report(
      targetType: 'commentId',
      id: 'comment',
      reason: 'HARASSMENT',
      details: 'Detalle',
    );
    await expectLater(
      api.report(targetType: 'wrong', id: 'post', reason: 'SPAM'),
      throwsA(isA<CommunityException>()),
    );
  });
  test('Upload uses correct multipart field and MIME', () async {
    final api = service((request) async {
      expect(request.headers['content-type'], contains('multipart/form-data'));
      expect(request.body, contains('name="file"'));
      expect(request.body, contains('image/png'));
      return ok({
        'url': '/uploads/community/a.png',
        'type': 'IMAGE',
        'originalName': 'a.png',
      });
    });
    expect(
      (await api.upload('a.png', Uint8List.fromList([1, 2, 3, 4]))).caption,
      'a.png',
    );
  });
  test('Invalid and oversized files never reach server', () async {
    var calls = 0;
    final api = service((_) async {
      calls++;
      return ok({});
    });
    await expectLater(
      api.upload('a.exe', Uint8List(1)),
      throwsA(isA<CommunityException>()),
    );
    await expectLater(
      api.upload('a.pdf', Uint8List(10 * 1024 * 1024 + 1)),
      throwsA(isA<CommunityException>()),
    );
    expect(calls, 0);
  });
  test(
    'Errors are readable and toggles are not automatically retried',
    () async {
      var calls = 0;
      final api = service((_) async {
        calls++;
        return http.Response('{"status":"error"}', 401);
      });
      await expectLater(
        api.follow('channel'),
        throwsA(
          isA<CommunityException>().having(
            (e) => e.message,
            'message',
            contains('sesión'),
          ),
        ),
      );
      expect(calls, 1);
      await expectLater(
        service(
          (_) async => http.Response('<html>error</html>', 502),
        ).categories(),
        throwsA(isA<CommunityException>()),
      );
    },
  );
  testWidgets('Patients explore channels and only published feed', (
    tester,
  ) async {
    final api = service((r) async {
      if (r.url.path.endsWith('/categories')) {
        return ok({
          'categories': [categoryJson],
        });
      }
      if (r.url.path.endsWith('/channels')) return page([channelJson()]);
      expect(r.url.queryParameters['status'], 'PUBLISHED');
      return page();
    });
    await tester.pumpWidget(MaterialApp(home: CommunityScreen(service: api)));
    await tester.pumpAndSettle();
    expect(find.text('Bienestar emocional'), findsOneWidget);
    await tester.tap(find.text('Feed'));
    await tester.pumpAndSettle();
    expect(
      find.text('Aún no hay publicaciones en esta categoría.'),
      findsOneWidget,
    );
    expect(find.text('Crear canal'), findsNothing);
  });
  testWidgets('Follow reconciles server state and count', (tester) async {
    var following = false;
    final api = service((r) async {
      if (r.url.path.endsWith('/follow')) {
        following = !following;
        return ok({'isFollowing': following});
      }
      if (r.url.path.contains('/channels/')) {
        return ok({'channel': channelJson(following: following)});
      }
      return page();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: CommunityChannelScreen(
          channelId: 'channel',
          service: api,
          categories: const [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguir canal'));
    await tester.pumpAndSettle();
    expect(find.text('Dejar de seguir'), findsOneWidget);
    expect(find.text('1 seguidores'), findsOneWidget);
  });
  testWidgets('Unverified professional has no management actions', (
    tester,
  ) async {
    final api = service(
      (r) async => r.url.path.endsWith('/profile')
          ? ok({
              'user': {
                'roles': ['PSYCHOLOGIST_VERIFIED'],
                'psychologistProfile': {'status': 'SUSPENDIDO'},
              },
            })
          : ok({
              'categories': [categoryJson],
            }),
    );
    await tester.pumpWidget(
      MaterialApp(home: CommunityScreen(service: api, management: true)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Necesitas una cuenta activa'), findsOneWidget);
    expect(find.text('Crear canal'), findsNothing);
  });
  testWidgets('Pagination deduplicates and refresh keeps load-more', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PagedCommunityList<String>(
            identity: (s) => s,
            load: (cursor) async => cursor == null
                ? const CommunityPage(
                    items: ['one'],
                    nextCursor: 'next',
                    hasMore: true,
                  )
                : const CommunityPage(items: ['one', 'two']),
            itemBuilder: (s) => ListTile(title: Text(s)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(find.text('Cargar más'), findsOneWidget);
    await tester.tap(find.text('Cargar más'));
    await tester.pumpAndSettle();
    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
  });
  testWidgets('Failed draft save retains text', (tester) async {
    final api = service((r) async {
      expect(r.method, 'POST');
      expect(jsonDecode(r.body)['status'], 'DRAFT');
      return http.Response(
        '{"status":"error","message":"No se pudo guardar"}',
        503,
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        home: CommunityPostEditor(
          service: api,
          channel: CommunityChannel.fromJson(channelJson(owner: true)),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'Mi publicación');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Texto educativo que no debe perderse.',
    );
    final contentController = tester
        .widget<TextFormField>(find.byType(TextFormField).at(1))
        .controller!;
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Guardar borrador'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Guardar borrador'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo guardar'), findsOneWidget);
    expect(contentController.text, 'Texto educativo que no debe perderse.');
  });

  testWidgets('Like button blocks overlapping toggles and uses server counts', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    var toggles = 0;
    final api = service((r) async {
      if (r.url.path.endsWith('/like')) {
        toggles++;
        return pending.future;
      }
      return ok({
        'post': {
          'id': 'post',
          'title': 'Aprende',
          'content': 'Contenido educativo',
          'status': 'PUBLISHED',
          'likesCount': 1,
          'isLiked': true,
        },
      });
    });
    final post = CommunityPost.fromJson({
      'id': 'post',
      'title': 'Aprende',
      'content': 'Contenido educativo',
      'status': 'PUBLISHED',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommunityPostCard(post: post, service: api),
        ),
      ),
    );
    await tester.tap(find.text('0 Me gusta'));
    await tester.pump();
    await tester.tap(find.text('0 Me gusta'));
    await tester.pump();
    expect(toggles, 1);
    pending.complete(ok({'isLiked': true, 'likesCount': 1}));
    await tester.pumpAndSettle();
    expect(find.text('1 Me gusta'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('An existing draft publishes with PUT and returns success', (
    tester,
  ) async {
    var saves = 0;
    bool? saved;
    final api = service((r) async {
      saves++;
      expect(r.method, 'PUT');
      expect(r.url.path, '/api/community/posts/post');
      expect(jsonDecode(r.body)['status'], 'PUBLISHED');
      return ok({
        'post': {'id': 'post', 'status': 'PUBLISHED'},
      });
    });
    final post = CommunityPost.fromJson({
      'id': 'post',
      'title': 'Título existente',
      'content': 'Un borrador educativo existente',
      'status': 'DRAFT',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CommunityPostEditor(
                      service: api,
                      channel: CommunityChannel.fromJson(
                        channelJson(owner: true),
                      ),
                      post: post,
                    ),
                  ),
                );
              },
              child: const Text('Abrir editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir editor'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Publicar'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(saved, isTrue);
    expect(find.text('Abrir editor'), findsOneWidget);
  });

  testWidgets('Report modal submits and closes with acknowledgement', (
    tester,
  ) async {
    var reports = 0;
    final api = service((r) async {
      reports++;
      expect(r.url.path, '/api/community/reports');
      expect(jsonDecode(r.body)['postId'], 'post');
      return ok({}, 201);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  reportCommunityContent(context, api, 'postId', 'post'),
              child: const Text('Reportar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Reportar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar reporte'));
    await tester.pumpAndSettle();
    expect(reports, 1);
    expect(find.text('Reporte enviado a moderación.'), findsOneWidget);
  });
}
