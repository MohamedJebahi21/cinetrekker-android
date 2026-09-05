import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_messages.dart';
import '../data/social_repository.dart';

class PeopleState {
  const PeopleState({
    required this.people,
    required this.followingIds,
    required this.followerIds,
    required this.page,
    required this.hasMore,
    required this.isLoading,
    required this.error,
  });

  factory PeopleState.initial() {
    return const PeopleState(
      people: <SocialUserSummary>[],
      followingIds: <String>{},
      followerIds: <String>{},
      page: 0,
      hasMore: true,
      isLoading: false,
      error: null,
    );
  }

  final List<SocialUserSummary> people;
  final Set<String> followingIds;
  final Set<String> followerIds;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final String? error;

  PeopleState copyWith({
    List<SocialUserSummary>? people,
    Set<String>? followingIds,
    Set<String>? followerIds,
    int? page,
    bool? hasMore,
    bool? isLoading,
    String? error,
  }) {
    return PeopleState(
      people: people ?? this.people,
      followingIds: followingIds ?? this.followingIds,
      followerIds: followerIds ?? this.followerIds,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final peopleControllerProvider =
    NotifierProvider<PeopleController, PeopleState>(PeopleController.new);

class PeopleController extends Notifier<PeopleState> {
  @override
  PeopleState build() {
    return PeopleState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(socialRepositoryProvider);
      const limit = 24;
      // The directory must remain available to guests. Follow data is an
      // enhancement for signed-in users and must not block the public list.
      final people = await repository.getPublicProfilesPage(
        limit: limit,
        offset: 0,
      );
      var followingIds = <String>{};
      var followerIds = <String>{};
      if (repository.isSignedIn) {
        try {
          final results = await Future.wait([
            repository.getFollowingIds(),
            repository.getFollowerIds(),
          ]);
          followingIds = results[0].toSet();
          followerIds = results[1].toSet();
        } catch (_) {
          // A restrictive follow-table policy should not hide public profiles.
        }
      }

      state = PeopleState(
        people: people,
        followingIds: followingIds,
        followerIds: followerIds,
        page: 1,
        hasMore: people.length == limit,
        isLoading: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: describeAppError(error));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(socialRepositoryProvider);

      const limit = 24;
      final nextPage = state.page + 1;
      final nextPeople = await repository.getPublicProfilesPage(
        limit: limit,
        offset: state.people.length,
      );
      state = state.copyWith(
        people: <SocialUserSummary>[...state.people, ...nextPeople],
        page: nextPage,
        hasMore: nextPeople.length == limit,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: describeAppError(error));
    }
  }

  Future<void> followUser(String followingId) async {
    final repository = ref.read(socialRepositoryProvider);
    await repository.followUser(followingId);
    await load();
  }

  Future<void> unfollowUser(String followingId) async {
    final repository = ref.read(socialRepositoryProvider);
    await repository.unfollowUser(followingId);
    await load();
  }
}
