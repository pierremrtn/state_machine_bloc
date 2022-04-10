part of 'post_bloc.dart';

abstract class PostState extends Equatable {
  const PostState({required this.posts});

  final List<Post> posts;

  @override
  List<Object> get props => [posts];
}

class PostInitial extends PostState {
  const PostInitial() : super(posts: const []);
}

class PostSuccess extends PostState {
  const PostSuccess({required List<Post> posts}) : super(posts: posts);
}

class PostError extends PostState {
  const PostError({required List<Post> posts, required this.error})
      : super(posts: posts);

  final String error;

  @override
  List<Object> get props => [posts, error];
}

class PostFetchInProgress extends PostState {
  const PostFetchInProgress({required List<Post> posts}) : super(posts: posts);
}

class PostEndReached extends PostState {
  const PostEndReached({required List<Post> posts}) : super(posts: posts);
}
