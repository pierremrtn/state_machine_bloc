import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_list_state_machine/posts/posts.dart';
import 'package:state_machine_bloc/state_machine_bloc.dart';

part 'post_event.dart';
part 'post_state.dart';

const _postLimit = 20;
const throttleDuration = Duration(milliseconds: 100);

// EventTransformer<E> throttleDroppable<E>(Duration duration) {
//   return (events, mapper) {
//     return droppable<E>().call(events.throttle(duration), mapper);
//   };
// }

class PostBloc extends StateMachine<PostEvent, PostState> {
  PostBloc({required this.httpClient}) : super(const PostInitial()) {
    define<PostInitial>((b) => b
      ..on<PostFetchRequested>(
        _transitToFetchInProgress,
      ));

    define<PostSuccess>((b) => b
      ..on<PostFetchRequested>(
        _transitToFetchInProgress,
      ));

    define<PostFetchInProgress>(
      (b) => b
        ..onEnter(_fetchPosts)
        ..on<PostFetchSuccess>(_onPostFetchSuccess)
        ..on<PostFetchError>(_onPostFetchError),
    );

    define<PostError>();

    define<PostEndReached>();
  }

  final http.Client httpClient;

  PostFetchInProgress _transitToFetchInProgress(
    PostFetchRequested event,
    PostState state,
  ) =>
      PostFetchInProgress(posts: state.posts);

  PostState _onPostFetchSuccess(
    PostFetchSuccess event,
    PostFetchInProgress state,
  ) {
    if (event.posts.isNotEmpty) {
      return PostSuccess(posts: List.of(state.posts)..addAll(event.posts));
    } else {
      return PostEndReached(posts: state.posts);
    }
  }

  PostError _onPostFetchError(
    PostFetchError event,
    PostFetchInProgress state,
  ) =>
      PostError(
        posts: state.posts,
        error: event.error,
      );

  Future<void> _fetchPosts(PostFetchInProgress state) async {
    final startIndex = state.posts.length;
    try {
      final response = await httpClient.get(
        Uri.https(
          'jsonplaceholder.typicode.com',
          '/posts',
          <String, String>{'_start': '$startIndex', '_limit': '$_postLimit'},
        ),
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as List;
        final posts = body
            .map((dynamic json) => Post(
                  id: json['id'] as int,
                  title: json['title'] as String,
                  body: json['body'] as String,
                ))
            .toList();
        add(PostFetchSuccess(posts: posts));
      }
      add(PostFetchError(error: response.statusCode.toString()));
    } catch (e) {
      add(PostFetchError(error: e.toString()));
    }
  }
}
