import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api_service.dart';
import '../../../core/errors/app_error_messages.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/models/media_models.dart';

class DiscoverState {
  const DiscoverState({
    required this.mediaType,
    required this.page,
    required this.totalPages,
    required this.items,
    required this.isLoading,
    required this.error,
  });

  factory DiscoverState.initial() {
    return const DiscoverState(
      mediaType: 'movie',
      page: 1,
      totalPages: 0,
      items: <TmdbMedia>[],
      isLoading: false,
      error: null,
    );
  }

  final String mediaType;
  final int page;
  final int totalPages;
  final List<TmdbMedia> items;
  final bool isLoading;
  final String? error;

  bool get hasMore => totalPages > 0 && page < totalPages;

  DiscoverState copyWith({
    String? mediaType,
    int? page,
    int? totalPages,
    List<TmdbMedia>? items,
    bool? isLoading,
    String? error,
  }) {
    return DiscoverState(
      mediaType: mediaType ?? this.mediaType,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final discoverControllerProvider =
    NotifierProvider<DiscoverController, DiscoverState>(DiscoverController.new);

class DiscoverController extends Notifier<DiscoverState> {
  @override
  DiscoverState build() {
    return DiscoverState.initial();
  }

  Future<void> load({
    required String mediaType,
    String? language,
    int page = 1,
    bool append = false,
  }) async {
    final String selectedLanguage = language ?? ref.read(tmdbLanguageProvider);
    state = state.copyWith(mediaType: mediaType, isLoading: true, error: null);
    try {
      final response = await ref
          .read(tmdbApiServiceProvider)
          .discover(
            mediaType: mediaType,
            language: selectedLanguage,
            params: const <String, String>{'sort_by': 'popularity.desc'},
            page: page,
          );
      state = state.copyWith(
        items: append
            ? [...state.items, ...response.results]
            : response.results,
        page: page,
        totalPages: response.totalPages,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: describeAppError(error));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) {
      return;
    }

    await load(
      mediaType: state.mediaType,
      page: state.page + 1,
      append: true,
      language: ref.read(tmdbLanguageProvider),
    );
  }
}
