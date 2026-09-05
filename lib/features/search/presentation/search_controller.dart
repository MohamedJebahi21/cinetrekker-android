import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api_service.dart';
import '../../../core/errors/app_error_messages.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/models/media_models.dart';
import '../../../core/utils/validation.dart';

class SearchState {
  const SearchState({
    required this.query,
    required this.type,
    required this.page,
    required this.results,
    required this.totalPages,
    required this.isLoading,
    required this.error,
  });

  factory SearchState.initial() {
    return const SearchState(
      query: '',
      type: 'all',
      page: 1,
      results: <TmdbMedia>[],
      totalPages: 0,
      isLoading: false,
      error: null,
    );
  }

  final String query;
  final String type;
  final int page;
  final List<TmdbMedia> results;
  final int totalPages;
  final bool isLoading;
  final String? error;

  bool get hasMore => totalPages > 0 && page < totalPages;

  SearchState copyWith({
    String? query,
    String? type,
    int? page,
    List<TmdbMedia>? results,
    int? totalPages,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      type: type ?? this.type,
      page: page ?? this.page,
      results: results ?? this.results,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchState>(SearchController.new);

class SearchController extends Notifier<SearchState> {
  @override
  SearchState build() {
    return SearchState.initial();
  }

  Future<void> search({
    required String query,
    required String type,
    int page = 1,
    String? language,
  }) async {
    final sanitized = sanitizeSearchQuery(query);
    if (sanitized.isEmpty) {
      state = SearchState.initial();
      return;
    }

    final String selectedLanguage = language ?? ref.read(tmdbLanguageProvider);

    state = state.copyWith(
      query: sanitized,
      type: type,
      page: page,
      isLoading: true,
      error: null,
    );

    try {
      final response = await ref
          .read(tmdbApiServiceProvider)
          .search(
            query: sanitized,
            type: type,
            language: selectedLanguage,
            page: page,
          );
      state = state.copyWith(
        results: page == 1
            ? response.results
            : [...state.results, ...response.results],
        totalPages: response.totalPages,
        page: page,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: describeAppError(error));
    }
  }

  void clear() {
    state = SearchState.initial();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.query.isEmpty) {
      return;
    }
    await search(
      query: state.query,
      type: state.type,
      page: state.page + 1,
      language: ref.read(tmdbLanguageProvider),
    );
  }
}
