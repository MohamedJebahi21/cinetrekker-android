import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/supabase_rest_api.dart';
import '../../../core/auth/auth_controller.dart';

class SocialComment {
  const SocialComment({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.content,
    required this.createdAt,
    required this.containsSpoiler,
    this.likesCount = 0,
    this.isLiked = false,
  });

  final String id;
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final String content;
  final String createdAt;
  final bool containsSpoiler;
  final int likesCount;
  final bool isLiked;

  factory SocialComment.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] is Map
        ? (json['profiles'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    return SocialComment(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] as String? ?? '',
      displayName: (json['display_name'] ?? profile['display_name']) as String?,
      avatarUrl: (json['avatar_url'] ?? profile['avatar_url']) as String?,
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      containsSpoiler: json['contains_spoiler'] as bool? ?? false,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
    );
  }
}

class SocialNotification {
  const SocialNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.mediaId,
    this.mediaType,
  });

  final String id;
  final String type;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final int? mediaId;
  final String? mediaType;

  int? get movieId => mediaId;

  factory SocialNotification.fromJson(Map<String, dynamic> json) {
    return SocialNotification(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? 'activity',
      message: json['message'] as String? ?? 'New activity',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isRead: json['is_read'] as bool? ?? false,
      mediaId: (json['media_id'] as num?)?.toInt(),
      mediaType: json['media_type'] as String?,
    );
  }
}

class SocialUserSummary {
  const SocialUserSummary({
    required this.userId,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? bio;
  final String? avatarUrl;

  factory SocialUserSummary.fromJson(Map<String, dynamic> json) {
    return SocialUserSummary(
      userId: (json['user_id'] ?? json['id']) as String? ?? '',
      displayName: (json['display_name'] as String?)?.trim().isNotEmpty == true
          ? (json['display_name'] as String)
          : 'CineTrekker user',
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class SocialRepository {
  SocialRepository({required this.api, required this.userId});

  final SupabaseRestApi api;
  final String? userId;

  bool get isSignedIn => userId != null && userId!.isNotEmpty;

  Future<List<SocialComment>> getComments({
    required int mediaId,
    required String mediaType,
  }) async {
    final rows = await api.selectRows(
      'comments',
      equals: <String, dynamic>{'media_id': mediaId, 'media_type': mediaType},
      orderBy: 'created_at',
      descending: true,
    );
    return rows.map(SocialComment.fromJson).toList(growable: false);
  }

  Future<void> addComment({
    required int mediaId,
    required String mediaType,
    required String content,
    bool containsSpoiler = false,
  }) async {
    if (!isSignedIn) throw StateError('Sign in to comment.');
    await api.upsertRow('comments', <String, dynamic>{
      'user_id': userId,
      'media_id': mediaId,
      'media_type': mediaType,
      'content': content.trim(),
      'contains_spoiler': containsSpoiler,
    });
  }

  Future<void> likeComment(String commentId) async {
    if (!isSignedIn) throw StateError('Sign in to like comments.');
    await api.upsertRow('comment_likes', <String, dynamic>{
      'comment_id': commentId,
      'user_id': userId,
    }, onConflict: 'comment_id,user_id');
  }

  Future<List<SocialNotification>> getNotifications() async {
    if (!isSignedIn) return const <SocialNotification>[];
    final rows = await api.selectRows(
      'notifications',
      equals: <String, dynamic>{'user_id': userId},
      orderBy: 'created_at',
      descending: true,
    );
    return rows.map(SocialNotification.fromJson).toList(growable: false);
  }

  Future<void> markAllNotificationsRead() async {
    if (!isSignedIn) return;
    final rows = await api.selectRows(
      'notifications',
      equals: <String, dynamic>{'user_id': userId, 'is_read': false},
    );
    for (final row in rows) {
      final id = row['id'];
      if (id == null) continue;
      await api.upsertRow('notifications', <String, dynamic>{
        'id': id,
        'user_id': userId,
        'is_read': true,
      }, onConflict: 'id');
    }
  }

  Future<List<SocialUserSummary>> getPublicProfilesPage({
    required int limit,
    required int offset,
  }) async {
    final rows = await api.selectRows('profiles', orderBy: 'display_name');
    final filtered = rows
        .where((row) => row['is_public'] as bool? ?? false)
        .where((row) => row['user_id'] != userId)
        .skip(offset)
        .take(limit)
        .map(SocialUserSummary.fromJson)
        .toList(growable: false);
    return filtered;
  }

  Future<List<String>> getFollowingIds() async {
    if (!isSignedIn) return const <String>[];
    final rows = await api.selectRows(
      'user_follows',
      equals: <String, dynamic>{'follower_id': userId},
    );
    return rows
        .map((row) => row['following_id'] as String?)
        .whereType<String>()
        .toList(growable: false);
  }

  Future<List<String>> getFollowerIds() async {
    if (!isSignedIn) return const <String>[];
    final rows = await api.selectRows(
      'user_follows',
      equals: <String, dynamic>{'following_id': userId},
    );
    return rows
        .map((row) => row['follower_id'] as String?)
        .whereType<String>()
        .toList(growable: false);
  }

  Future<void> followUser(String followingId) async {
    if (!isSignedIn) throw StateError('Sign in to follow people.');
    await api.upsertRow('user_follows', <String, dynamic>{
      'follower_id': userId,
      'following_id': followingId,
    }, onConflict: 'follower_id,following_id');
  }

  Future<void> unfollowUser(String followingId) async {
    if (!isSignedIn) throw StateError('Sign in to unfollow people.');
    await api.deleteRows(
      'user_follows',
      equals: <String, dynamic>{
        'follower_id': userId,
        'following_id': followingId,
      },
    );
  }

  Future<void> deleteAccountData() async {
    if (!isSignedIn) return;
    for (final table in const <String>[
      'comments',
      'comment_likes',
      'notifications',
      'user_follows',
    ]) {
      await api.deleteRows(table, equals: <String, dynamic>{'user_id': userId});
    }
  }
}

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;
  return SocialRepository(
    api: ref.watch(supabaseRestApiProvider),
    userId: session?.user.id,
  );
});
