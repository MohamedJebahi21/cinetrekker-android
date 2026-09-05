import 'package:flutter_test/flutter_test.dart';
import 'package:cinetrekker_android/core/auth/auth_session.dart';

void main() {
  test('parses a Supabase password session', () {
    final session = CineTrekkerAuthSession.fromJson(<String, dynamic>{
      'access_token': 'access',
      'refresh_token': 'refresh',
      'expires_in': 3600,
      'expires_at': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
      'user': <String, dynamic>{
        'id': 'user-1',
        'email': 'user@example.com',
        'user_metadata': <String, dynamic>{'full_name': 'Test User'},
      },
    });
    expect(session.user.id, 'user-1');
    expect(session.user.displayName, 'Test User');
    expect(session.isExpired, isFalse);
  });

  test('redacts access tokens in toString', () {
    final session = CineTrekkerAuthSession.fromJson(<String, dynamic>{
      'access_token': 'secret-access',
      'refresh_token': 'secret-refresh',
      'expires_in': 3600,
      'user': <String, dynamic>{'id': 'user-1'},
    });
    expect(session.toString(), isNot(contains('secret-access')));
    expect(session.toString(), contains('user-1'));
  });
}
