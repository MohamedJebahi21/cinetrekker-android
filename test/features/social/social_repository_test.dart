import 'package:cinetrekker_android/features/social/data/social_repository.dart';
import 'package:cinetrekker_android/core/api/supabase_rest_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSupabaseRestApi extends SupabaseRestApi {
  _FakeSupabaseRestApi() : super(accessToken: 'test-token');

  final List<Map<String, dynamic>> deletes = <Map<String, dynamic>>[];

  @override
  Future<void> deleteRows(
    String table, {
    Map<String, dynamic> equals = const <String, dynamic>{},
  }) async {
    deletes.add(<String, dynamic>{
      'table': table,
      'equals': Map<String, dynamic>.from(equals),
    });
  }
}

void main() {
  group('SocialRepository.deleteAccountData', () {
    test('deletes follow edges by follower_id and following_id', () async {
      final api = _FakeSupabaseRestApi();
      final repo = SocialRepository(api: api, userId: 'user-1');

      await repo.deleteAccountData();

      expect(
        api.deletes.where((d) => d['table'] == 'user_follows').toList(),
        <Map<String, dynamic>>[
          <String, dynamic>{
            'table': 'user_follows',
            'equals': <String, dynamic>{'follower_id': 'user-1'},
          },
          <String, dynamic>{
            'table': 'user_follows',
            'equals': <String, dynamic>{'following_id': 'user-1'},
          },
        ],
      );

      expect(
        api.deletes.singleWhere((d) => d['table'] == 'comments')['equals'],
        <String, dynamic>{'user_id': 'user-1'},
      );
      expect(
        api.deletes.singleWhere((d) => d['table'] == 'comment_likes')['equals'],
        <String, dynamic>{'user_id': 'user-1'},
      );
      expect(
        api.deletes.singleWhere((d) => d['table'] == 'notifications')['equals'],
        <String, dynamic>{'user_id': 'user-1'},
      );

      expect(
        api.deletes.any(
          (d) =>
              d['table'] == 'user_follows' &&
              (d['equals'] as Map).containsKey('user_id'),
        ),
        isFalse,
      );
    });

    test('is a no-op when signed out', () async {
      final api = _FakeSupabaseRestApi();
      final repo = SocialRepository(api: api, userId: null);

      await repo.deleteAccountData();

      expect(api.deletes, isEmpty);
    });
  });
}
