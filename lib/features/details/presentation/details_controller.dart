import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api_service.dart';
import '../../../core/errors/app_error_messages.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/models/media_models.dart';

class DetailsState {
  const DetailsState({
    required this.details,
    required this.similar,
    required this.recommendations,
    required this.isLoading,
    required this.error,
  });

  factory DetailsState.initial() {
    return const DetailsState(
      details: null,
      similar: <TmdbMedia>[],
      recommendations: <TmdbMedia>[],
      isLoading: false,
      error: null,
    );
  }

  final TmdbMediaDetails? details;
  final List<TmdbMedia> similar;
  final List<TmdbMedia> recommendations;
  final bool isLoading;
  final String? error;

  DetailsState copyWith({
    TmdbMediaDetails? details,
    List<TmdbMedia>? similar,
    List<TmdbMedia>? recommendations,
    bool? isLoading,
    String? error,
  }) {
    return DetailsState(
      details: details ?? this.details,
      similar: similar ?? this.similar,
      recommendations: recommendations ?? this.recommendations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final detailsControllerProvider =
    NotifierProvider<DetailsController, DetailsState>(DetailsController.new);

class DetailsController extends Notifier<DetailsState> {
  @override
  DetailsState build() {
    return DetailsState.initial();
  }

  Future<void> load({
    required String mediaType,
    required int mediaId,
    String? language,
  }) async {
    final String selectedLanguage = language ?? ref.read(tmdbLanguageProvider);
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(tmdbApiServiceProvider);
      final details = await api.details(
        mediaType: mediaType,
        mediaId: mediaId,
        language: selectedLanguage,
      );
      final similar = await api.similar(
        mediaType: mediaType,
        mediaId: mediaId,
        language: selectedLanguage,
      );
      final recommendations = await api.recommendations(
        mediaType: mediaType,
        mediaId: mediaId,
        language: selectedLanguage,
      );

      state = DetailsState(
        details: details,
        similar: similar.results,
        recommendations: recommendations.results,
        isLoading: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: describeAppError(error));
    }
  }

  Future<void> refresh({
    required String mediaType,
    required int mediaId,
    String? language,
  }) {
    return load(mediaType: mediaType, mediaId: mediaId, language: language);
  }
}
