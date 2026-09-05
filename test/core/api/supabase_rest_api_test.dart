import 'package:cinetrekker_android/core/api/supabase_rest_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupabaseRestApi.eqFilter', () {
    test('formats primitive values without quotes', () {
      expect(SupabaseRestApi.eqFilter(42), 'eq.42');
      expect(SupabaseRestApi.eqFilter(true), 'eq.true');
      expect(SupabaseRestApi.eqFilter('abc-123'), 'eq.abc-123');
    });

    test('quotes values with reserved PostgREST characters', () {
      expect(SupabaseRestApi.eqFilter('hello world'), 'eq."hello world"');
      expect(SupabaseRestApi.eqFilter('a,b'), 'eq."a,b"');
      expect(SupabaseRestApi.eqFilter('x(y)'), 'eq."x(y)"');
    });

    test('escapes embedded quotes', () {
      expect(SupabaseRestApi.eqFilter('say "hi"'), r'eq."say \"hi\""');
    });
  });
}
