part of 'post_bloc.dart';

abstract class PostEvent extends Equatable {
  const PostEvent();
  @override
  List<Object> get props => [];
}

class PostFetchRequested extends PostEvent {}

class PostFetchSuccess extends PostEvent {
  const PostFetchSuccess({
    required this.posts,
  });

  final List<Post> posts;

  @override
  List<Object> get props => [posts];
}

class PostFetchError extends PostEvent {
  const PostFetchError({
    required this.error,
  });

  final String error;

  @override
  List<Object> get props => [error];
}
