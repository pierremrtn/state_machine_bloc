import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_list_state_machine/posts/posts.dart';
import 'package:mocktail/mocktail.dart';

class MockPostBloc extends MockBloc<PostEvent, PostState> implements PostBloc {}

extension on WidgetTester {
  Future<void> pumpPostsList(PostBloc postBloc) {
    return pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: postBloc,
          child: PostsList(),
        ),
      ),
    );
  }
}

void main() {
  final mockPosts = List.generate(
    5,
    (i) => Post(id: i, title: 'post title', body: 'post body'),
  );

  late PostBloc postBloc;

  setUp(() {
    postBloc = MockPostBloc();
  });

  group('PostsList', () {
    testWidgets(
        'renders CircularProgressIndicator '
        'when post status is initial', (tester) async {
      when(() => postBloc.state).thenReturn(const PostInitial());
      await tester.pumpPostsList(postBloc);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'renders no posts text '
        'when post status is success but with 0 posts', (tester) async {
      when(() => postBloc.state).thenReturn(const PostSuccess(
        posts: [],
      ));
      await tester.pumpPostsList(postBloc);
      expect(find.text('no posts'), findsOneWidget);
    });

    testWidgets(
        'renders 5 posts and a bottom loader when post max is not reached yet',
        (tester) async {
      when(() => postBloc.state).thenReturn(PostSuccess(
        posts: mockPosts,
      ));
      await tester.pumpPostsList(postBloc);
      expect(find.byType(PostListItem), findsNWidgets(5));
      expect(find.byType(BottomLoader), findsOneWidget);
    });

    testWidgets('does not render bottom loader when post max is reached',
        (tester) async {
      when(() => postBloc.state).thenReturn(PostEndReached(
        posts: mockPosts,
      ));
      await tester.pumpPostsList(postBloc);
      expect(find.byType(BottomLoader), findsNothing);
    });

    testWidgets('fetches more posts when scrolled to the bottom',
        (tester) async {
      when(() => postBloc.state).thenReturn(
        PostSuccess(
          posts: List.generate(
            10,
            (i) => Post(id: i, title: 'post title', body: 'post body'),
          ),
        ),
      );
      await tester.pumpPostsList(postBloc);
      await tester.drag(find.byType(PostsList), const Offset(0, -500));
      verify(() => postBloc.add(PostFetchRequested())).called(1);
    });
  });
}
