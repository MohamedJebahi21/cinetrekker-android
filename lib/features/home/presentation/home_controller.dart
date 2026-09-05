import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../../tv_tracking/presentation/tv_tracking_controller.dart';
import '../../watchlist/presentation/watchlist_controller.dart';

import '../data/home_repository.dart';

final homeControllerProvider =
    AsyncNotifierProvider<HomeController, HomeFeedData>(HomeController.new);

class HomeController extends AsyncNotifier<HomeFeedData> {
  @override
  Future<HomeFeedData> build() {
    final repository = ref.read(homeRepositoryProvider);
    final language = ref.watch(tmdbLanguageProvider);
    // Listen to TV tracking & watchlist changes to reactively update Continue Watching & Watchlist preview
    ref.watch(tvTrackingControllerProvider);
    ref.watch(watchlistControllerProvider);
    return repository.load(language: language);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(homeRepositoryProvider)
          .load(language: ref.read(tmdbLanguageProvider));
    });
  }
}
