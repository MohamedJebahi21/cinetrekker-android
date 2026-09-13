import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_messages.dart';
import '../data/social_repository.dart';

class CommentsState {
  const CommentsState({
    required this.comments,
    required this.isLoading,
    required this.error,
  });

  factory CommentsState.initial() {
    return const CommentsState(
      comments: <SocialComment>[],
      isLoading: false,
      error: null,
    );
  }

  final List<SocialComment> comments;
  final bool isLoading;
  final String? error;

  CommentsState copyWith({
    List<SocialComment>? comments,
    bool? isLoading,
    String? error,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final commentsControllerProvider =
    NotifierProvider<CommentsController, CommentsState>(CommentsController.new);

class CommentsController extends Notifier<CommentsState> {
  @override
  CommentsState build() {
    return CommentsState.initial();
  }

  Future<void> load({required int mediaId, required String mediaType}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(socialRepositoryProvider);
      final comments = await repository.getComments(
        mediaId: mediaId,
        mediaType: mediaType,
      );
      state = state.copyWith(comments: comments, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: describeAppError(error));
    }
  }

  Future<void> addComment({
    required int mediaId,
    required String mediaType,
    required String content,
    bool containsSpoiler = false,
    double? rating,
  }) async {
    state = state.copyWith(error: null);
    try {
      final repository = ref.read(socialRepositoryProvider);
      await repository.addComment(
        mediaId: mediaId,
        mediaType: mediaType,
        content: content,
        containsSpoiler: containsSpoiler,
      );
      await load(mediaId: mediaId, mediaType: mediaType);
    } catch (error) {
      state = state.copyWith(error: describeAppError(error));
    }
  }

  Future<void> likeComment({
    required int mediaId,
    required String mediaType,
    required String commentId,
  }) async {
    state = state.copyWith(error: null);
    try {
      final repository = ref.read(socialRepositoryProvider);
      await repository.likeComment(commentId);
      await load(mediaId: mediaId, mediaType: mediaType);
    } catch (error) {
      state = state.copyWith(error: describeAppError(error));
    }
  }
}
