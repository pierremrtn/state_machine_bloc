// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_list_state_machine/posts/posts.dart';

void main() {
  group('PostState', () {
    test('supports value comparison', () {
      expect(PostInitial(), PostInitial());
      expect(
        PostError(posts: [], error: 'e'),
        PostError(posts: [], error: 'e'),
      );
      expect(PostSuccess(posts: []), PostSuccess(posts: []));
    });
  });
}
