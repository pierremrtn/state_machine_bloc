import 'package:bloc_test/bloc_test.dart';
import 'package:infinite_list_state_machine/posts/bloc/post_bloc.dart';
import 'package:infinite_list_state_machine/posts/models/post.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockClient extends Mock implements http.Client {}

Uri _postsUrl({required int start}) {
  return Uri.https(
    'jsonplaceholder.typicode.com',
    '/posts',
    <String, String>{'_start': '$start', '_limit': '20'},
  );
}

void main() {
  group('PostBloc', () {
    const mockPosts = [Post(id: 1, title: 'post title', body: 'post body')];
    const extraMockPosts = [
      Post(id: 2, title: 'post title', body: 'post body')
    ];

    late http.Client httpClient;

    setUpAll(() {
      registerFallbackValue(Uri());
    });

    setUp(() {
      httpClient = MockClient();
    });

    test('initial state is PostInitial()', () {
      expect(PostBloc(httpClient: httpClient).state, const PostInitial());
    });

    group('PostFetched', () {
      blocTest<PostBloc, PostState>(
        'emits nothing when posts has reached maximum amount',
        build: () => PostBloc(httpClient: httpClient),
        seed: () => const PostEndReached(posts: []),
        act: (bloc) => bloc.add(PostFetchRequested()),
        expect: () => <PostState>[],
      );

      blocTest<PostBloc, PostState>(
        'emits successful status when http fetches initial posts',
        setUp: () {
          when(() => httpClient.get(any())).thenAnswer((_) async {
            return http.Response(
              '[{ "id": 1, "title": "post title", "body": "post body" }]',
              200,
            );
          });
        },
        build: () => PostBloc(httpClient: httpClient),
        act: (bloc) => bloc.add(PostFetchRequested()),
        expect: () => const <PostState>[
          PostFetchInProgress(
            posts: [],
          ),
          PostSuccess(
            posts: mockPosts,
          )
        ],
        verify: (_) {
          verify(() => httpClient.get(_postsUrl(start: 0))).called(1);
        },
      );

      blocTest<PostBloc, PostState>(
        'drops new events when processing current event',
        setUp: () {
          when(() => httpClient.get(any())).thenAnswer((_) async {
            return http.Response(
              '[{ "id": 1, "title": "post title", "body": "post body" }]',
              200,
            );
          });
        },
        build: () => PostBloc(httpClient: httpClient),
        act: (bloc) => bloc
          ..add(PostFetchRequested())
          ..add(PostFetchRequested()),
        expect: () => const <PostState>[
          PostFetchInProgress(
            posts: [],
          ),
          PostSuccess(
            posts: mockPosts,
          )
        ],
        verify: (_) {
          verify(() => httpClient.get(any())).called(1);
        },
      );

      blocTest<PostBloc, PostState>(
        'throttles events',
        setUp: () {
          when(() => httpClient.get(any())).thenAnswer((_) async {
            await Future<void>.delayed(Duration.zero);
            return http.Response(
              '[{ "id": 1, "title": "post title", "body": "post body" }]',
              200,
            );
          });
        },
        build: () => PostBloc(httpClient: httpClient),
        act: (bloc) async {
          bloc.add(PostFetchRequested());
          await Future<void>.delayed(Duration.zero);
          bloc.add(PostFetchRequested());
        },
        expect: () => const <PostState>[
          PostFetchInProgress(
            posts: [],
          ),
          PostSuccess(
            posts: mockPosts,
          )
        ],
        verify: (_) {
          verify(() => httpClient.get(any())).called(1);
        },
      );

      blocTest<PostBloc, PostState>(
        'emits failure status when http fetches posts and throw exception',
        setUp: () {
          when(() => httpClient.get(any())).thenAnswer(
            (_) async => http.Response('', 500),
          );
        },
        build: () => PostBloc(httpClient: httpClient),
        act: (bloc) => bloc.add(PostFetchRequested()),
        expect: () => const <PostState>[
          PostFetchInProgress(
            posts: [],
          ),
          PostError(posts: [], error: "500"),
        ],
        verify: (_) {
          verify(() => httpClient.get(_postsUrl(start: 0))).called(1);
        },
      );

      blocTest<PostBloc, PostState>(
        'emits successful status and reaches max posts when '
        '0 additional posts are fetched',
        setUp: () {
          when(() => httpClient.get(any())).thenAnswer(
            (_) async => http.Response('[]', 200),
          );
        },
        build: () => PostBloc(httpClient: httpClient),
        seed: () => const PostSuccess(
          posts: mockPosts,
        ),
        act: (bloc) => bloc.add(PostFetchRequested()),
        expect: () => const <PostState>[
          PostFetchInProgress(
            posts: mockPosts,
          ),
          PostEndReached(
            posts: mockPosts,
          )
        ],
        verify: (_) {
          verify(() => httpClient.get(_postsUrl(start: 1))).called(1);
        },
      );

      blocTest<PostBloc, PostState>(
        'emits successful status and does not reach max posts'
        'when additional posts are fetched',
        setUp: () {
          when(() => httpClient.get(any())).thenAnswer((_) async {
            return http.Response(
              '[{ "id": 2, "title": "post title", "body": "post body" }]',
              200,
            );
          });
        },
        build: () => PostBloc(httpClient: httpClient),
        seed: () => const PostSuccess(
          posts: mockPosts,
        ),
        act: (bloc) => bloc.add(PostFetchRequested()),
        expect: () => const <PostState>[
          PostFetchInProgress(
            posts: mockPosts,
          ),
          PostSuccess(
            posts: [...mockPosts, ...extraMockPosts],
          )
        ],
        verify: (_) {
          verify(() => httpClient.get(_postsUrl(start: 1))).called(1);
        },
      );
    });
  });
}
